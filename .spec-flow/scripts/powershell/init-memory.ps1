#!/usr/bin/env pwsh
<#
.SYNOPSIS
Initialize Spec-Flow memory files from templates.

.DESCRIPTION
Creates base memory files (constitution.md, roadmap.md, design-inspirations.md)
if they don't exist. Non-destructive by default.

.PARAMETER TargetDir
Target directory (defaults to current directory)

.PARAMETER Force
Overwrite existing memory files (use with caution)

.PARAMETER Json
Output results in JSON format for Claude parsing

.EXAMPLE
./init-memory.ps1
Initialize memory files in current directory (skip existing)

.EXAMPLE
./init-memory.ps1 -TargetDir /path/to/project
Initialize memory files in specified directory

.EXAMPLE
./init-memory.ps1 -Force
Initialize and overwrite all memory files

.EXAMPLE
./init-memory.ps1 -Json
Output results as JSON
#>

[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$Force,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found at $commonPath"
    exit 1
}
. $commonPath

# --- Configuration ----------------------------------------------------------
$memoryFiles = @(
    @{
        Name        = 'constitution.md'
        Template    = 'constitution-template.md'
        Description = 'Engineering principles'
    },
    @{
        Name        = 'roadmap.md'
        Template    = 'roadmap-template.md'
        Description = 'Product roadmap'
    },
    @{
        Name        = 'design-inspirations.md'
        Template    = 'design-inspirations-template.md'
        Description = 'Design references'
    }
)

# --- Main -------------------------------------------------------------------
# Determine base directory
if ($TargetDir) {
    $baseDir = if ([System.IO.Path]::IsPathRooted($TargetDir)) {
        $TargetDir
    }
    else {
        Join-Path -Path (Get-Location) -ChildPath $TargetDir | Resolve-Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
    }
    if (-not $baseDir) {
        if ($Json) {
            Write-Output '{"error": "Target directory not found", "success": false}'
        }
        else {
            Write-Error "Target directory not found: $TargetDir"
        }
        exit 1
    }
}
else {
    $baseDir = Get-Location | Select-Object -ExpandProperty Path
}

$memoryDir = Join-Path -Path $baseDir -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory'
$templatesDir = Join-Path -Path $baseDir -ChildPath '.spec-flow' | Join-Path -ChildPath 'templates'

# Create memory directory if missing
if (-not (Test-Path -LiteralPath $memoryDir -PathType Container)) {
    New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
}

$results = @{
    created = @()
    skipped = @()
    errors  = @()
}

# Process each memory file
foreach ($file in $memoryFiles) {
    $memoryPath = Join-Path -Path $memoryDir -ChildPath $file.Name
    $templatePath = Join-Path -Path $templatesDir -ChildPath $file.Template

    # Check if template exists
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        $errorMsg = "Template not found: .spec-flow/templates/$($file.Template)"
        $results.errors += @{
            file  = $file.Name
            error = $errorMsg
        }
        if (-not $Json) {
            Write-Warning $errorMsg
        }
        continue
    }

    # Check if memory file exists
    $fileExists = Test-Path -LiteralPath $memoryPath -PathType Leaf

    if ($fileExists -and -not $Force) {
        $results.skipped += @{
            file   = $file.Name
            path   = ".spec-flow/memory/$($file.Name)"
            reason = 'already exists'
        }
        continue
    }

    # Copy template to memory
    try {
        Copy-Item -LiteralPath $templatePath -Destination $memoryPath -Force

        # Update timestamp in file if it has [ISO timestamp] or [YYYY-MM-DD]
        $content = Get-Content -LiteralPath $memoryPath -Raw
        $timestamp = Get-Date -Format 'yyyy-MM-dd'
        $content = $content -replace '\[ISO timestamp\]', $timestamp
        $content = $content -replace '\[YYYY-MM-DD\]', $timestamp
        $content = $content -replace '\[auto-generated on save\]', $timestamp
        Set-Content -LiteralPath $memoryPath -Value $content -NoNewline

        $results.created += @{
            file        = $file.Name
            path        = ".spec-flow/memory/$($file.Name)"
            description = $file.Description
            action      = if ($fileExists) { 'overwritten' } else { 'created' }
        }
    }
    catch {
        $results.errors += @{
            file  = $file.Name
            error = $_.Exception.Message
        }
        if (-not $Json) {
            Write-Warning "Failed to create $($file.Name): $($_.Exception.Message)"
        }
    }
}

# --- Output Results ---------------------------------------------------------
if ($Json) {
    $jsonOutput = @{
        success = ($results.errors.Count -eq 0)
        created = $results.created
        skipped = $results.skipped
        errors  = $results.errors
    } | ConvertTo-Json -Depth 10 -Compress
    Write-Output $jsonOutput
}
else {
    Write-Host ""
    Write-Host "Spec-Flow Memory Initialization" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""

    if ($results.created.Count -gt 0) {
        Write-Host "Created:" -ForegroundColor Green
        foreach ($item in $results.created) {
            $action = if ($item.action -eq 'overwritten') { '[OVERWRITTEN]' } else { '[NEW]' }
            Write-Host "  $action $($item.path) - $($item.description)" -ForegroundColor Green
        }
        Write-Host ""
    }

    if ($results.skipped.Count -gt 0) {
        Write-Host "Skipped (already exist):" -ForegroundColor Yellow
        foreach ($item in $results.skipped) {
            Write-Host "  [SKIP] $($item.path)" -ForegroundColor Yellow
        }
        Write-Host ""
        if (-not $Force) {
            Write-Host "  Tip: Use -Force to overwrite existing files" -ForegroundColor DarkGray
            Write-Host ""
        }
    }

    if ($results.errors.Count -gt 0) {
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($item in $results.errors) {
            Write-Host "  [ERROR] $($item.file): $($item.error)" -ForegroundColor Red
        }
        Write-Host ""
    }

    if ($results.created.Count -gt 0 -and $results.errors.Count -eq 0) {
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Review and customize .spec-flow/memory/constitution.md" -ForegroundColor White
        Write-Host "2. Run /roadmap in Claude Code to start planning features" -ForegroundColor White
        Write-Host "3. Add design inspirations to design-inspirations.md" -ForegroundColor White
        Write-Host ""
    }
}

# Exit with error if any errors occurred
if ($results.errors.Count -gt 0) {
    exit 1
}

exit 0


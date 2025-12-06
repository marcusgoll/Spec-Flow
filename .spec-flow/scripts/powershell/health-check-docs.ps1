#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Health check for living documentation - detect stale CLAUDE.md files

.DESCRIPTION
    Scans for CLAUDE.md files and reports files older than threshold.

.PARAMETER MaxAgeDays
    Maximum age in days before file is considered stale (default: 7)

.PARAMETER Json
    Output results in JSON format

.EXAMPLE
    .\health-check-docs.ps1 -MaxAgeDays 7

.EXAMPLE
    .\health-check-docs.ps1 -MaxAgeDays 3 -Json
#>

param(
    [int]$MaxAgeDays = 7,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent

# Find all CLAUDE.md files
$claudeFiles = Get-ChildItem -Path $repoRoot -Filter "CLAUDE.md" -File -Recurse -ErrorAction SilentlyContinue

if (-not $claudeFiles) {
    if ($Json) {
        @{ total = 0; stale = @(); fresh = @(); warnings = @() } | ConvertTo-Json -Compress
    }
    else {
        Write-Host "[spec-flow] No CLAUDE.md files found" -ForegroundColor Cyan
    }
    exit 0
}

# Calculate cutoff date
$cutoffDate = (Get-Date).AddDays(-$MaxAgeDays)

# Check each file
$staleFiles = @()
$freshFiles = @()
$warnings = @()

foreach ($file in $claudeFiles) {
    $mtime = $file.LastWriteTime
    $ageDays = [math]::Floor(((Get-Date) - $mtime).TotalDays)

    # Extract "Last Updated" timestamp from file
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    $lastUpdated = $null
    if ($content -match 'Last Updated.*?:\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})') {
        $lastUpdated = $matches[1]
    }

    # Check if stale
    if ($mtime -lt $cutoffDate) {
        $staleFiles += @{ file = $file.FullName; age_days = $ageDays }
    }
    else {
        $freshFiles += @{ file = $file.FullName; age_days = $ageDays }
    }

    # Check for timestamp
    if (-not $lastUpdated) {
        $warnings += @{ file = $file.FullName; message = "No 'Last Updated' timestamp found" }
    }
}

# Output results
if ($Json) {
    @{
        total    = $claudeFiles.Count
        stale    = $staleFiles
        fresh    = $freshFiles
        warnings = $warnings
    } | ConvertTo-Json -Compress
}
else {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📊 Living Documentation Health Check" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total CLAUDE.md files: $($claudeFiles.Count)"
    Write-Host "Freshness threshold: $MaxAgeDays days"
    Write-Host ""

    if ($staleFiles.Count -eq 0) {
        Write-Host "[spec-flow] ✅ All CLAUDE.md files are fresh (updated within $MaxAgeDays days)" -ForegroundColor Green
    }
    else {
        Write-Host "[spec-flow][warn] ⚠️  Found $($staleFiles.Count) stale CLAUDE.md file(s):" -ForegroundColor Yellow
        Write-Host ""
        foreach ($item in $staleFiles) {
            $relPath = $item.file -replace [regex]::Escape($repoRoot + [IO.Path]::DirectorySeparatorChar), ''
            Write-Host "  ❌ $relPath ($($item.age_days)d old)" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Run regeneration scripts to update:"
        Write-Host "  - Feature CLAUDE.md: .spec-flow/scripts/powershell/generate-feature-claude-md.ps1 -FeatureDir <feature-dir>"
        Write-Host "  - Project CLAUDE.md: .spec-flow/scripts/powershell/generate-project-claude-md.ps1"
        Write-Host ""
    }

    if ($warnings.Count -gt 0) {
        Write-Host "[spec-flow][warn] ⚠️  Found $($warnings.Count) warning(s):" -ForegroundColor Yellow
        Write-Host ""
        foreach ($warning in $warnings) {
            $relPath = $warning.file -replace [regex]::Escape($repoRoot + [IO.Path]::DirectorySeparatorChar), ''
            Write-Host "  ⚠️  ${relPath}: $($warning.message)" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Host "Fresh files: $($freshFiles.Count)"
    if ($freshFiles.Count -gt 0 -and $freshFiles.Count -le 5) {
        foreach ($item in $freshFiles) {
            $relPath = $item.file -replace [regex]::Escape($repoRoot + [IO.Path]::DirectorySeparatorChar), ''
            Write-Host "  ✅ $relPath ($($item.age_days)d old)" -ForegroundColor Green
        }
    }
    Write-Host ""
}

# Exit with error if stale files found
if ($staleFiles.Count -gt 0) {
    exit 1
}


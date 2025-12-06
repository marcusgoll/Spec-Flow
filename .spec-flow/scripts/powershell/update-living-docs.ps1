#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Central orchestrator for updating living documentation (CLAUDE.md files)

.DESCRIPTION
    Updates CLAUDE.md files at various levels of the hierarchy:
    - Feature-level: specs/NNN-slug/CLAUDE.md
    - Project-level: docs/project/CLAUDE.md
    - Domain-level: backend/CLAUDE.md, frontend/CLAUDE.md, etc.

.PARAMETER Scope
    Scope of updates: feature, project, domain, all (default: feature)

.PARAMETER FeatureDir
    Path to feature directory (required for feature scope)

.PARAMETER Json
    Output result in JSON format

.EXAMPLE
    .\update-living-docs.ps1 -Scope feature -FeatureDir "specs/001-auth-flow"

.EXAMPLE
    .\update-living-docs.ps1 -Scope project

.EXAMPLE
    .\update-living-docs.ps1 -Scope all -FeatureDir "specs/001-auth-flow"
#>

param(
    [Parameter()]
    [ValidateSet("feature", "project", "domain", "all")]
    [string]$Scope = "feature",

    [string]$FeatureDir = "",
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot

# Validate feature directory for feature scope
if ($Scope -in @("feature", "all") -and -not $FeatureDir) {
    throw "Feature directory required for scope: $Scope"
}

if ($FeatureDir -and -not (Test-Path $FeatureDir)) {
    throw "Feature directory not found: $FeatureDir"
}

# Track results
$updatedFiles = @()
$errors = @()

# Update feature-level CLAUDE.md
function Update-FeatureDocs {
    param([string]$FeatureDir)

    Write-Host "[spec-flow] Updating feature CLAUDE.md: $FeatureDir" -ForegroundColor Cyan

    try {
        $generateScript = Join-Path $scriptDir "generate-feature-claude-md.ps1"
        & $generateScript -FeatureDir $FeatureDir | Out-Null
        $updatedFiles += "$FeatureDir/CLAUDE.md"
    }
    catch {
        $errors += "Failed to update $FeatureDir/CLAUDE.md: $_"
    }
}

# Update project-level CLAUDE.md
function Update-ProjectDocs {
    Write-Host "[spec-flow] Updating project CLAUDE.md (not yet implemented in Phase 1)" -ForegroundColor Yellow
    # Will be implemented in Phase 3
}

# Update domain-level CLAUDE.md files
function Update-DomainDocs {
    Write-Host "[spec-flow] Updating domain CLAUDE.md files (not yet implemented in Phase 1)" -ForegroundColor Yellow
    # Will be implemented in Phase 4
}

# Execute updates based on scope
switch ($Scope) {
    "feature" {
        Update-FeatureDocs $FeatureDir
    }
    "project" {
        Update-ProjectDocs
    }
    "domain" {
        Update-DomainDocs
    }
    "all" {
        Update-FeatureDocs $FeatureDir
        Update-ProjectDocs
        Update-DomainDocs
    }
}

# Output results
if ($Json) {
    @{
        scope   = $Scope
        updated = $updatedFiles
        errors  = $errors
    } | ConvertTo-Json -Compress
}
else {
    if ($updatedFiles.Count -gt 0) {
        Write-Host "[spec-flow] Updated $($updatedFiles.Count) file(s):" -ForegroundColor Green
        foreach ($file in $updatedFiles) {
            Write-Host "  ✓ $file" -ForegroundColor Green
        }
    }

    if ($errors.Count -gt 0) {
        Write-Host "[spec-flow][warn] Encountered $($errors.Count) error(s):" -ForegroundColor Yellow
        foreach ($error in $errors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }
        exit 1
    }
}


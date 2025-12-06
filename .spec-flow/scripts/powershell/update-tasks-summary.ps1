#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update Progress Summary section in tasks.md

.DESCRIPTION
    Regenerates the Progress Summary section with latest velocity metrics.

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.EXAMPLE
    .\update-tasks-summary.ps1 -FeatureDir "specs/001-auth-flow"
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$tasksFile = Join-Path $FeatureDir "tasks.md"

if (-not (Test-Path $tasksFile)) {
    throw "No tasks.md found in $FeatureDir"
}

# Generate new Progress Summary
$velocityScript = Join-Path $PSScriptRoot "calculate-task-velocity.ps1"
$newSummary = & $velocityScript -FeatureDir $FeatureDir

# Read current tasks.md
$content = Get-Content $tasksFile -Raw

# Replace Progress Summary section
# Find section between "## Progress Summary" and next "##" or "---"
$pattern = '(?s)(## Progress Summary.*?)(?=\n##|\n---|$)'

if ($content -match $pattern) {
    $content = $content -replace $pattern, $newSummary
    Set-Content $tasksFile $content -NoNewline
    Write-Host "[spec-flow] Updated Progress Summary in tasks.md" -ForegroundColor Green
}
else {
    # Section doesn't exist, prepend it
    $content = "$newSummary`n`n---`n`n$content"
    Set-Content $tasksFile $content -NoNewline
    Write-Host "[spec-flow] Added Progress Summary to tasks.md" -ForegroundColor Green
}


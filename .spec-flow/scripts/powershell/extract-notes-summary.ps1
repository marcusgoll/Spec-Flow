#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extract recent task completions from NOTES.md for feature CLAUDE.md

.DESCRIPTION
    Parses NOTES.md to extract the last N completed tasks with timestamps,
    duration, and descriptions for inclusion in feature CLAUDE.md files.

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.PARAMETER Count
    Number of recent tasks to extract (default: 3)

.PARAMETER Json
    Output in JSON format for AI parsing

.EXAMPLE
    .\extract-notes-summary.ps1 -FeatureDir "specs/001-auth-flow" -Count 3

.EXAMPLE
    .\extract-notes-summary.ps1 -FeatureDir "specs/001-auth-flow" -Json
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir,

    [int]$Count = 3,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$notesFile = Join-Path $FeatureDir "NOTES.md"

if (-not (Test-Path $notesFile)) {
    Write-Warning "No NOTES.md found in $FeatureDir"
    if ($Json) {
        @{ tasks = @(); count = 0 } | ConvertTo-Json -Compress
    }
    exit 0
}

# Parse NOTES.md for completion markers
# Format: ✅ T001: Description - duration (timestamp)
# Example: ✅ T018: JWT refresh token rotation - 20min (2025-11-08 16:45)

$completionPattern = '^\s*✅\s+(T\d+):\s+(.+?)\s+-\s+(\d+min)\s+\((\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\)'

$content = Get-Content $notesFile -Raw
$matches = [regex]::Matches($content, $completionPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

# Get last N completions
$recentCompletions = $matches |
    Select-Object -Last $Count |
    ForEach-Object {
        @{
            taskId      = $_.Groups[1].Value
            description = $_.Groups[2].Value
            duration    = $_.Groups[3].Value
            timestamp   = $_.Groups[4].Value
        }
    }

if ($Json) {
    @{
        tasks = $recentCompletions
        count = $recentCompletions.Count
    } | ConvertTo-Json -Compress
}
else {
    foreach ($completion in $recentCompletions) {
        Write-Output "- ✅ $($completion.taskId): $($completion.description) - $($completion.duration) ($($completion.timestamp))"
    }
}


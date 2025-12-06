#!/usr/bin/env pwsh
<#
Initialize Spec-Flow roadmap from template.
Creates .spec-flow/memory/roadmap.md if it doesn't exist.

Usage:
  ./roadmap-init.ps1 [-Json]

Examples:
  ./roadmap-init.ps1          # Human-readable output
  ./roadmap-init.ps1 -Json    # JSON output for Claude parsing
#>

[CmdletBinding()]
param(
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

# --- Main -------------------------------------------------------------------
$repoRoot = Get-RepoRoot
$memoryDir = Join-Path -Path $repoRoot -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory'
$roadmapPath = Join-Path -Path $memoryDir -ChildPath 'roadmap.md'
$templatePath = Join-Path -Path $repoRoot -ChildPath '.spec-flow' | Join-Path -ChildPath 'templates' | Join-Path -ChildPath 'roadmap-template.md'

# Create memory directory if missing
if (-not (Test-Path -LiteralPath $memoryDir -PathType Container)) {
    New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
}

# Check if roadmap already exists
$roadmapExists = Test-Path -LiteralPath $roadmapPath -PathType Leaf
if ($roadmapExists) {
    if ($Json) {
        Write-Output '{"exists": true, "path": ".spec-flow/memory/roadmap.md", "created": false}'
    }
    else {
        Write-Information " Roadmap already exists at: .spec-flow/memory/roadmap.md" -InformationAction Continue
    }
    exit 0
}

# Check if template exists
$templateExists = Test-Path -LiteralPath $templatePath -PathType Leaf
if (-not $templateExists) {
    $errorMsg = "Template not found at: .spec-flow/templates/roadmap-template.md"
    if ($Json) {
        $errorJson = $errorMsg -replace '"', '\"'
        Write-Output "{`"error`": `"$errorJson`", `"created`": false}"
    }
    else {
        Write-Error $errorMsg
    }
    exit 1
}

# Copy template to roadmap location
Copy-Item -LiteralPath $templatePath -Destination $roadmapPath -Force

# Update timestamp in roadmap
$content = Get-Content -LiteralPath $roadmapPath -Raw
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$content = $content -replace '\[auto-generated on save\]', $timestamp
Set-Content -LiteralPath $roadmapPath -Value $content -NoNewline

if ($Json) {
    Write-Output '{"exists": false, "path": ".spec-flow/memory/roadmap.md", "created": true}'
}
else {
    Write-Information " Created roadmap at: .spec-flow/memory/roadmap.md" -InformationAction Continue
    Write-Information "  Use /roadmap to add features" -InformationAction Continue
}

exit 0



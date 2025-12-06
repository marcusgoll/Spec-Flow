#!/usr/bin/env pwsh
# Setup implementation plan for a feature (Spec-Driven Development)

<#!
Usage:
  ./setup-plan.ps1 [-Json] [-Help]

Options:
  -Json   Output results in JSON
  -Help   Show this help message

Notes:
  - Requires common.ps1 next to this script.
  - Creates/overwrites the feature's plan.md from a template if available.
  - Fills simple placeholders in the template: [FEATURE], [DATE], [link].
#>

[CmdletBinding()] param(
    [switch]$Json,
    [Alias('h')][switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
    @"
Usage: ./setup-plan.ps1 [-Json] [-Help]
  -Json   Output results in JSON
  -Help   Show this help message
"@ | Write-Output
    exit 0
}

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found next to this script: $commonPath"; exit 1
}
. $commonPath

# --- Resolve feature environment -------------------------------------------
$paths = Get-FeaturePathsEnv
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { exit 1 }

# Ensure feature directory exists
New-DirectoryIfMissing -Path $paths.FEATURE_DIR | Out-Null

# Candidate templates (first match wins)
$templateCandidates = @(
    (Join-Path -Path $paths.REPO_ROOT -ChildPath '.spec-flow/templates/plan-template.md'),
    (Join-Path -Path $paths.REPO_ROOT -ChildPath 'templates/plan-template.md')
)

$templateUsed = $null
foreach ($tpl in $templateCandidates) {
    if (Test-Path -LiteralPath $tpl -PathType Leaf) { $templateUsed = $tpl; break }
}

# Helper: title-case a slug
function Convert-SlugToTitle {
    param([Parameter(Mandatory = $true)][string]$Slug)
    $text = ($Slug -replace '^[0-9]{3}-', '') -replace '-', ' '
    $ti = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo
    return $ti.ToTitleCase($text.ToLowerInvariant())
}

$featureTitle = Convert-SlugToTitle -Slug $paths.CURRENT_BRANCH
$today = Get-Date -Format 'yyyy-MM-dd'
$placeholdersFilled = $false

# Write plan.md
try {
    if ($templateUsed) {
        $content = Get-Content -LiteralPath $templateUsed -Raw -Encoding UTF8
        $content = $content.Replace('[FEATURE]', $featureTitle)
        $content = $content.Replace('[DATE]', $today)
        $content = $content.Replace('[link]', './spec.md')
        $placeholdersFilled = $true
        $content | Set-Content -LiteralPath $paths.IMPL_PLAN -Encoding UTF8
        if (-not $Json) { Write-Information "Copied plan template: $templateUsed  $($paths.IMPL_PLAN)" -InformationAction Continue }
    }
    else {
        @"
# Implementation Plan: $featureTitle

**Branch**: `$($paths.CURRENT_BRANCH)` | **Date**: $today | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/$($paths.CURRENT_BRANCH)/spec.md`

## Execution Flow (/plan command scope)
(Describe your execution flow here or paste the standard flow.)

## Summary
[Extract from feature spec: primary requirement + technical approach from research]

## Visual References (optional)
[Link screenshots or mockups stored in `./visuals/`. Remove if not provided.]

## Technical Context
[Language/Version, Dependencies, Storage, Testing, Target Platform, Project Type, Performance Goals, Constraints, Scale/Scope]

## Constitution Check
[Map your feature against the current constitution. Mark N/A with justification.]

## Project Structure
[Docs and source code skeleton]

## Phase 0/1/2
[Research, Design & Contracts, Tasks planning]

## Complexity & Progress Tracking
[Tables as required]
"@ | Set-Content -LiteralPath $paths.IMPL_PLAN -Encoding UTF8
        if (-not $Json) { Write-Warning "Plan template not found; wrote a minimal plan to $($paths.IMPL_PLAN)" }
    }
}
catch {
    Write-Error "Failed to write plan.md: $($_.Exception.Message)"; exit 1
}

# Ensure visuals directory exists for optional assets
$visualsPath = Join-Path -Path $paths.FEATURE_DIR -ChildPath 'visuals'
New-DirectoryIfMissing -Path $visualsPath | Out-Null

# --- Output -----------------------------------------------------------------
if ($Json) {
    [PSCustomObject]@{
        FEATURE_SPEC        = $paths.FEATURE_SPEC
        IMPL_PLAN           = $paths.IMPL_PLAN
        SPECS_DIR           = $paths.FEATURE_DIR
        BRANCH              = $paths.CURRENT_BRANCH
        HAS_GIT             = $paths.HAS_GIT
        TEMPLATE_USED       = $templateUsed
        PLACEHOLDERS_FILLED = $placeholdersFilled
    } | ConvertTo-Json -Compress | Write-Output
}
else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
    if ($templateUsed) { Write-Output "TEMPLATE_USED: $templateUsed" }
}



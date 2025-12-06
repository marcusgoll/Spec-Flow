#!/usr/bin/env pwsh
<#!
Create a new feature scaffold under ./specs and (optionally) create/switch to a git branch.

Usage:
  ./create-new-feature.ps1 [-Json] <feature description>

Examples:
  ./create-new-feature.ps1 "Frontend Experience Build"
  ./create-new-feature.ps1 -Json "Batch upload for CFIs"
#>

[CmdletBinding()]
param(
    [switch]$Json,
    [ValidateSet('feat', 'fix', 'chore', 'docs', 'test', 'refactor', 'ci', 'build')]
    [string]$Type = 'feat',
    [Parameter(ValueFromRemainingArguments = $true, Mandatory = $true)]
    [string[]]$FeatureDescription
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found next to this script ($commonPath)."; exit 1
}
. $commonPath

# --- Utilities --------------------------------------------------------------
function New-Slug {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Text)
    $slug = $Text.ToLowerInvariant()
    $slug = ($slug -replace '[^a-z0-9]+', '-').Trim('-')
    # Condense multiple hyphens (already handled by regex), keep as-is
    return $slug
}

function Truncate-String {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$MaxLength
    )
    if ($Text.Length -le $MaxLength) { return $Text }
    return $Text.Substring(0, $MaxLength).Trim('-')
}

function Get-NextFeatureNumber {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$SpecsDir)
    $max = 0
    if (Test-Path -LiteralPath $SpecsDir -PathType Container) {
        Get-ChildItem -LiteralPath $SpecsDir -Directory | ForEach-Object {
            $m = [regex]::Match($_.Name, '^(\d{3})-')
            if ($m.Success) {
                $n = [int]$m.Groups[1].Value
                if ($n -gt $max) { $max = $n }
            }
        }
    }
    return ('{0:000}' -f ($max + 1))
}

function Test-BranchExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Test-HasGit)) { return $false }
    try {
        git rev-parse --verify --quiet $Name 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}

# --- Main -------------------------------------------------------------------
$desc = ($FeatureDescription -join ' ').Trim()
if (-not $desc) { Write-Error 'Provide a feature description.'; exit 1 }

$repoRoot = Get-RepoRoot
$hasGit = Test-HasGit
$specsDir = New-DirectoryIfMissing -Path (Join-Path -Path $repoRoot -ChildPath 'specs')

$featureNum = Get-NextFeatureNumber -SpecsDir $specsDir

# Build slug (use first 6 words, then cap total length to 40)
$slugFull = New-Slug -Text $desc
$words = ($slugFull -split '-') | Where-Object { $_ } | Select-Object -First 6
$slug = [string]::Join('-', $words)
$slug = Truncate-String -Text $slug -MaxLength 40
if (-not $slug) { $slug = 'feature' }

# Base names for directory and branch
$baseName = "$featureNum-$slug"
$dirName = $baseName
$branchName = "$Type/$baseName"
$counter = 2
while ((Test-Path -LiteralPath (Join-Path -Path $specsDir -ChildPath $dirName) -PathType Container) -or (Test-BranchExists -Name $branchName)) {
    $dirName = "$baseName-$counter"
    $branchName = "$Type/$dirName"
    $counter++
}

# Create branch if git is present
if ($hasGit) {
    try {
        if (Test-BranchExists -Name $branchName) {
            git checkout $branchName | Out-Null
        }
        else {
            git checkout -b $branchName | Out-Null
        }
    }
    catch {
        Write-Warning "Failed to switch/create git branch '$branchName'"
    }
}
else {
    Write-Warning "[spec-flow] Git not detected; skipping branch creation (planned: $branchName)"
}

# Create feature directory and initial spec file (directory does not include the type prefix)
$featureDir = New-DirectoryIfMissing -Path (Join-Path -Path $specsDir -ChildPath $dirName)
# Candidate spec templates (prefer .spec-flow override)
$specTemplateCandidates = @(
    (Join-Path -Path $repoRoot -ChildPath '.spec-flow/templates/spec-template.md'),
    (Join-Path -Path $repoRoot -ChildPath 'templates/spec-template.md')
)

$specFile = Join-Path -Path $featureDir -ChildPath 'spec.md'
$specTemplateUsed = $null
foreach ($tpl in $specTemplateCandidates) {
    if (Test-Path -LiteralPath $tpl -PathType Leaf) {
        Copy-Item -LiteralPath $tpl -Destination $specFile -Force
        $specTemplateUsed = $tpl
        break
    }
}

if (-not $specTemplateUsed) {
    @"
# Feature Specification: $desc

**Feature Branch**: `$branchName`
**Created**: $(Get-Date -Format 'yyyy-MM-dd')
**Status**: Draft

## Summary
[One-paragraph summary of the user problem and desired outcome.]

## User Scenarios & Testing *(mandatory)*
- [ ] Primary flow
- [ ] Edge cases

## Visual References (optional)
- [ ] `./visuals/<filename>.png` - description
- [ ] External reference (optional): https://...

## Requirements *(mandatory)*
- **FR-001** ...
- **NFR-001** ...

## Notes
- Created by create-new-feature.ps1
"@ | Set-Content -LiteralPath $specFile -Encoding UTF8
}

# Ensure visuals directory scaffold exists
$visualsDir = Join-Path -Path $featureDir -ChildPath 'visuals'
New-DirectoryIfMissing -Path $visualsDir | Out-Null

# Set SPEC_FLOW_FEATURE for current session
$env:SPEC_FLOW_FEATURE = $branchName

# Output
if ($Json) {
    [PSCustomObject]@{
        BRANCH_NAME = $branchName
        FEATURE_DIR = $featureDir
        SPEC_FILE   = $specFile
        FEATURE_NUM = $featureNum
        HAS_GIT     = $hasGit
    } | ConvertTo-Json -Compress | Write-Output
}
else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "FEATURE_DIR: $featureDir"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPEC_FLOW_FEATURE environment variable set to: $branchName"
}


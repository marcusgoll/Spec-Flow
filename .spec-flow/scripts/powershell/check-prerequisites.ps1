#!/usr/bin/env pwsh

<#!
Consolidated prerequisite checking for Spec-Driven Development workflow.
Usage: ./check-prerequisites.ps1 [OPTIONS]

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
  -IncludeMemories    Include memory files (constitution, roadmap, design-inspirations) in output
  -PathsOnly          Only output path variables (no validation)
  -Help, -h           Show help message
#>

[CmdletBinding()] param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$IncludeTasks,
    [switch]$IncludeMemories,
    [switch]$PathsOnly,
    [Alias('h')][switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
    @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
  -IncludeMemories    Include memory files (constitution, roadmap, design-inspirations) in output
  -PathsOnly          Only output path variables (no prerequisite validation)
  -Help, -h           Show this help message

EXAMPLES:
  # Check task prerequisites (plan.md required)
  .\check-prerequisites.ps1 -Json

  # Check implementation prerequisites (plan.md + tasks.md required)
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks

  # Check with memory files included
  .\check-prerequisites.ps1 -Json -IncludeMemories

  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly
"@ | Write-Output
    exit 0
}

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found at $commonPath. Ensure it exists next to this script."; exit 1
}
. $commonPath

# --- Resolve environment & branch ------------------------------------------
$paths = Get-FeaturePathsEnv
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) { exit 1 }

# --- Paths-only mode --------------------------------------------------------
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{ PATHS = $paths } | ConvertTo-Json -Compress | Write-Output
    }
    else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
        Write-Output "RESEARCH: $($paths.RESEARCH)"
        Write-Output "DATA_MODEL: $($paths.DATA_MODEL)"
        Write-Output "QUICKSTART: $($paths.QUICKSTART)"
        Write-Output "CONTRACTS_DIR: $($paths.CONTRACTS_DIR)"
        Write-Output "NOTES: $($paths.NOTES)"
        Write-Output "ERROR_LOG: $($paths.ERROR_LOG)"
        Write-Output "VISUALS_DIR: $($paths.VISUALS_DIR)"
        Write-Output "VISUALS_README: $($paths.VISUALS_README)"
        Write-Output "ARTIFACTS_DIR: $($paths.ARTIFACTS_DIR)"
        if ($IncludeMemories) {
            Write-Output "MEMORY_DIR: $($paths.MEMORY_DIR)"
            Write-Output "CONSTITUTION: $($paths.CONSTITUTION)"
            Write-Output "ROADMAP: $($paths.ROADMAP)"
            Write-Output "DESIGN_INSPIRATIONS: $($paths.DESIGN_INSPIRATIONS)"
        }
    }
    exit 0
}

# --- Validate feature directory & plan -------------------------------------
if (-not (Test-Path -LiteralPath $paths.FEATURE_DIR -PathType Container)) {
    Write-Error "Feature directory not found: $($paths.FEATURE_DIR). Run /spec-flow first to create the feature structure."; exit 1
}
if (-not (Test-Path -LiteralPath $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Error "plan.md not found in $($paths.FEATURE_DIR). Run /plan first to create the implementation plan."; exit 1
}

# --- Optional: tasks.md gate for implementation phase ----------------------
if ($RequireTasks -and -not (Test-Path -LiteralPath $paths.TASKS -PathType Leaf)) {
    Write-Error "tasks.md not found in $($paths.FEATURE_DIR). Run /tasks first to create the task list."; exit 1
}

# --- Build AVAILABLE_DOCS list ---------------------------------------------
$docs = New-Object System.Collections.Generic.List[string]
if (Test-Path -LiteralPath $paths.RESEARCH -PathType Leaf) { [void]$docs.Add('research.md') }
if (Test-Path -LiteralPath $paths.DATA_MODEL -PathType Leaf) { [void]$docs.Add('data-model.md') }
if ((Test-Path -LiteralPath $paths.CONTRACTS_DIR -PathType Container) -and (Get-ChildItem -LiteralPath $paths.CONTRACTS_DIR -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    [void]$docs.Add('contracts/')
}
if (Test-Path -LiteralPath $paths.QUICKSTART -PathType Leaf) { [void]$docs.Add('quickstart.md') }
if (Test-Path -LiteralPath $paths.NOTES -PathType Leaf) { [void]$docs.Add('NOTES.md') }
if (Test-Path -LiteralPath $paths.ERROR_LOG -PathType Leaf) { [void]$docs.Add('error-log.md') }
if (Test-Path -LiteralPath $paths.VISUALS_README -PathType Leaf) { [void]$docs.Add('visuals/README.md') }
if ((Test-Path -LiteralPath $paths.ARTIFACTS_DIR -PathType Container) -and (Get-ChildItem -LiteralPath $paths.ARTIFACTS_DIR -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    [void]$docs.Add('artifacts/')
}
if ($IncludeTasks -and (Test-Path -LiteralPath $paths.TASKS -PathType Leaf)) { [void]$docs.Add('tasks.md') }

# --- Build MEMORY_DOCS list (global) ----------------------------------------
$memoryDocs = New-Object System.Collections.Generic.List[string]
if ($IncludeMemories) {
    if (Test-Path -LiteralPath $paths.CONSTITUTION -PathType Leaf) { [void]$memoryDocs.Add('constitution.md') }
    if (Test-Path -LiteralPath $paths.ROADMAP -PathType Leaf) { [void]$memoryDocs.Add('roadmap.md') }
    if (Test-Path -LiteralPath $paths.DESIGN_INSPIRATIONS -PathType Leaf) { [void]$memoryDocs.Add('design-inspirations.md') }
}

# --- Output -----------------------------------------------------------------
if ($Json) {
    $output = [PSCustomObject]@{
        FEATURE_DIR    = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs
    }
    if ($IncludeMemories) {
        $output | Add-Member -MemberType NoteProperty -Name 'MEMORY_DOCS' -Value $memoryDocs
    }
    $output | ConvertTo-Json -Compress | Write-Output
}
else {
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output 'AVAILABLE_DOCS:'

    # Status lines for each potential document (pretty with Write-Status)
    Test-FileExists -Path $paths.RESEARCH       -Description 'research.md'   | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL     -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/'    | Out-Null
    Test-FileExists -Path $paths.QUICKSTART     -Description 'quickstart.md' | Out-Null
    Test-FileExists -Path $paths.NOTES          -Description 'NOTES.md'      | Out-Null
    Test-FileExists -Path $paths.ERROR_LOG      -Description 'error-log.md'  | Out-Null
    Test-FileExists -Path $paths.VISUALS_README -Description 'visuals/README.md' | Out-Null
    Test-DirHasFiles -Path $paths.ARTIFACTS_DIR -Description 'artifacts/'    | Out-Null
    if ($IncludeTasks) { Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null }

    if ($IncludeMemories) {
        Write-Output ''
        Write-Output 'MEMORY_DOCS:'
        Test-FileExists -Path $paths.CONSTITUTION        -Description 'constitution.md'        | Out-Null
        Test-FileExists -Path $paths.ROADMAP             -Description 'roadmap.md'             | Out-Null
        Test-FileExists -Path $paths.DESIGN_INSPIRATIONS -Description 'design-inspirations.md' | Out-Null
    }
}


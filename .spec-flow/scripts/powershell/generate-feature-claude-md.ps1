#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate feature-level CLAUDE.md with context, progress, and relevant agents

.DESCRIPTION
    Generates or updates a feature-level CLAUDE.md file that includes:
    - Current workflow phase and status
    - Task completion progress
    - Recent progress from NOTES.md
    - Relevant specialist agents for the current phase
    - Quick navigation links

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.PARAMETER Json
    Output result in JSON format

.EXAMPLE
    .\generate-feature-claude-md.ps1 -FeatureDir "specs/001-auth-flow"

.EXAMPLE
    .\generate-feature-claude-md.ps1 -FeatureDir "specs/001-auth-flow" -Json
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir,

    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$claudeMdFile = Join-Path $FeatureDir "CLAUDE.md"
$stateFile = Join-Path $FeatureDir "state.yaml"
$specFile = Join-Path $FeatureDir "spec.md"
$tasksFile = Join-Path $FeatureDir "tasks.md"
$notesFile = Join-Path $FeatureDir "NOTES.md"

if (-not (Test-Path $stateFile)) {
    throw "No state.yaml found in $FeatureDir"
}

# Extract feature name from directory
$featureSlug = Split-Path $FeatureDir -Leaf
$featureName = ($featureSlug -replace '^\d+-', '') -replace '-', ' ' | ForEach-Object {
    (Get-Culture).TextInfo.ToTitleCase($_)
}

# Read workflow state using yq (if available) or fallback to regex
function Read-YamlValue {
    param(
        [string]$File,
        [string]$Key
    )

    if (Get-Command yq -ErrorAction SilentlyContinue) {
        $value = & yq eval $Key $File 2>$null
        if ($value -eq "null") { return "" }
        return $value
    }
    else {
        # Fallback: simple regex parsing
        $content = Get-Content $File -Raw
        $keyName = $Key -replace '.*\.', ''
        if ($content -match "(?m)^\s*${keyName}:\s*(.+)$") {
            return $matches[1].Trim()
        }
        return ""
    }
}

$currentPhase = Read-YamlValue $stateFile ".workflow.phase"
$status = Read-YamlValue $stateFile ".workflow.status"

# Extract GitHub issue number
$githubIssue = ""
if (Test-Path $specFile) {
    $specContent = Get-Content $specFile -Raw
    if ($specContent -match 'GitHub Issue.*#(\d+)') {
        $githubIssue = $matches[1]
    }
}

# Calculate task completion
$taskProgress = "0/0 (0%)"
if (Test-Path $tasksFile) {
    $content = Get-Content $tasksFile -Raw
    $allTasks = [regex]::Matches($content, '^\s*-\s*\[.?\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $completedTasks = [regex]::Matches($content, '^\s*-\s*\[[Xx]\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)

    $totalCount = $allTasks.Count
    $completedCount = $completedTasks.Count

    if ($totalCount -gt 0) {
        $percentage = [math]::Floor(($completedCount / $totalCount) * 100)
        $taskProgress = "$completedCount/$totalCount ($percentage%)"
    }
}

# Extract recent progress from NOTES.md
$recentProgress = ""
if (Test-Path $notesFile) {
    $scriptPath = Join-Path $PSScriptRoot "extract-notes-summary.ps1"
    try {
        $recentProgress = & $scriptPath -FeatureDir $FeatureDir -Count 3 2>$null
    }
    catch {
        $recentProgress = ""
    }
}

# Determine next task
$nextTask = "Check tasks.md"
if (Test-Path $tasksFile) {
    $content = Get-Content $tasksFile
    $nextTaskLine = $content | Where-Object { $_ -match '^\s*-\s*\[\s\]\s*T\d+' } | Select-Object -First 1
    if ($nextTaskLine) {
        $nextTask = $nextTaskLine -replace '^\s*-\s*\[\s\]\s*', ''
    }
}

# Determine relevant agents based on current phase
function Get-RelevantAgents {
    param([string]$Phase)

    switch -Regex ($Phase) {
        'spec|clarify' {
            @"
### Specification Agents (Current Phase)
- ``spec-phase-agent`` - Generate comprehensive feature specifications
- ``clarify-phase-agent`` - Reduce ambiguity via targeted questions

### Support Agents
- ``/spec`` - Create feature specification
- ``/clarify`` - Ask clarifying questions
"@
        }
        'plan' {
            @"
### Planning Agents (Current Phase)
- ``plan-phase-agent`` - Research + design + architecture planning
- ``Explore`` - Fast codebase exploration for reuse patterns

### Support Agents
- ``/plan`` - Generate design artifacts
"@
        }
        'tasks' {
            @"
### Task Breakdown Agents (Current Phase)
- ``tasks-phase-agent`` - Generate concrete TDD tasks with acceptance criteria

### Support Agents
- ``/tasks`` - Generate task breakdown
"@
        }
        'validate' {
            @"
### Validation Agents (Current Phase)
- ``analyze-phase-agent`` - Cross-artifact consistency validation

### Support Agents
- ``/validate`` - Analyze spec/plan/tasks consistency
"@
        }
        'implement' {
            @"
### Implementation Commands & Agents (Current Phase)
- ``/implement`` - Orchestrates parallel specialist execution
- ``backend-dev`` - Backend/API implementation
- ``frontend-dev`` - Frontend/UI implementation
- ``database-architect`` - Schema design and migrations
- ``contracts-sdk`` - API contract management

### Support Agents (As Needed)
- ``debugger`` - Error investigation
- ``/debug`` - Debug errors
"@
        }
        'optimize' {
            @"
### Optimization Agents (Current Phase)
- ``optimize-phase-agent`` - Performance, security, accessibility review
- ``senior-code-reviewer`` - Code quality and KISS/DRY enforcement
- ``qa-test`` - Test coverage and quality assurance

### Support Agents
- ``/optimize`` - Production readiness validation
"@
        }
        'preview' {
            @"
### Preview Agents (Current Phase)
- ``preview-phase-agent`` - Manual UI/UX testing orchestration

### Support Agents
- ``/preview`` - Start local dev server for manual testing
"@
        }
        'ship' {
            @"
### Deployment Agents (Current Phase)
- ``ship-staging-phase-agent`` - Deploy to staging environment
- ``ship-prod-phase-agent`` - Promote to production
- ``ci-cd-release`` - CI/CD and release management

### Support Agents
- ``/ship`` - Unified deployment orchestrator
- ``/ship-staging`` - Deploy to staging
- ``/ship-prod`` - Promote to production
"@
        }
        default {
            @"
### Available Agents
- See ``.claude/agents/`` for full specialist catalog
"@
        }
    }
}

$relevantAgents = Get-RelevantAgents $currentPhase

# Determine related features
$relatedFeatures = ""
if (Test-Path $specFile) {
    $specContent = Get-Content $specFile
    $relatedLines = $specContent | Where-Object { $_ -match '(Depends on|Builds on|Blocks|Related)' } | Select-Object -First 3
    if ($relatedLines) {
        $relatedFeatures = $relatedLines -join "`n"
    }
}

# Generate CLAUDE.md
$lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$githubIssueSection = if ($githubIssue) {
    "`n**GitHub Issue**: #$githubIssue"
}
else { "" }

$relatedFeaturesSection = if ($relatedFeatures) {
    @"

## Related Features
$relatedFeatures
"@
}
else { "" }

$content = @"
# Feature Context: $featureName

**Last Updated**: $lastUpdated

## Current Phase
**Phase**: $currentPhase
**Status**: $status
**Progress**: $taskProgress

## Recent Progress (from NOTES.md)
$recentProgress

**Next**: $nextTask

## Key Artifacts
- ``spec.md`` - Feature requirements and acceptance criteria
- ``plan.md`` - Technical design and architecture approach
- ``tasks.md`` - Task breakdown with progress tracking
- ``NOTES.md`` - Complete implementation journal with detailed notes
- ``state.yaml`` - Machine-readable workflow state
$githubIssueSection

## Relevant Specialists for This Feature

$relevantAgents

## Quick Commands
- **Resume work**: ``/feature continue``
- **Check status**: ``/help``
- **Deploy**: ``/ship``
- **Health check**: Run health-check script to detect stale docs
$relatedFeaturesSection

## Navigation
- Project overview: ``docs/project/CLAUDE.md`` (if exists)
- Root workflow guide: ``CLAUDE.md``
- Architecture docs: ``docs/project/system-architecture.md``

---

*This file is auto-generated. Do not edit manually. Regenerate with:*
``````powershell
.spec-flow/scripts/powershell/generate-feature-claude-md.ps1 -FeatureDir "$FeatureDir"
``````
"@

Set-Content -Path $claudeMdFile -Value $content -Encoding UTF8

if (-not $Json) {
    Write-Host "[spec-flow] Generated $claudeMdFile" -ForegroundColor Green
    Write-Host "[spec-flow] Phase: $currentPhase | Progress: $taskProgress" -ForegroundColor Cyan
}

if ($Json) {
    @{
        success  = $true
        file     = $claudeMdFile
        phase    = $currentPhase
        progress = $taskProgress
    } | ConvertTo-Json -Compress
}


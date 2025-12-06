#!/usr/bin/env pwsh
<#
.SYNOPSIS
Learning Collector - Passive observation and metrics collection

.DESCRIPTION
Runs in background after phase completion, never blocks workflow.
Collects metrics for pattern detection and workflow improvement.

.PARAMETER Command
The command to execute: phase, task, tool, gate, agent, failure

.PARAMETER Arguments
Command-specific arguments

.EXAMPLE
.\learning-collector.ps1 phase implement specs/001-feature

.EXAMPLE
.\learning-collector.ps1 task T001 120 true

.EXAMPLE
.\learning-collector.ps1 tool Grep search 1500 true
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('phase', 'task', 'tool', 'gate', 'agent', 'failure')]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Load common helpers
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found at $commonPath"
    exit 1
}
. $commonPath

# ============================================================================
# Configuration
# ============================================================================

$repoRoot = Get-RepoRoot
$learningsDir = Join-Path -Path $repoRoot -ChildPath '.spec-flow' | Join-Path -ChildPath 'learnings'
$observationsDir = Join-Path -Path $learningsDir -ChildPath 'observations'
$metadataFile = Join-Path -Path $learningsDir -ChildPath 'learning-metadata.yaml'

# Ensure directories exist
$null = New-DirectoryIfMissing -Path $learningsDir
$null = New-DirectoryIfMissing -Path $observationsDir

# ============================================================================
# Helper Functions
# ============================================================================

function Get-Timestamp {
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Test-LearningEnabled {
    $enabled = $false
    $prefFile = Join-Path -Path $repoRoot -ChildPath '.spec-flow' | Join-Path -ChildPath 'config' | Join-Path -ChildPath 'user-preferences.yaml'

    if (Test-Path -LiteralPath $prefFile -PathType Leaf) {
        $content = Get-Content $prefFile -Raw
        if ($content -match 'learning:\s+enabled:\s+true') {
            $enabled = $true
        }
    }

    return $enabled
}

# ============================================================================
# Observation Collection
# ============================================================================

function Add-TaskObservation {
    param(
        [string]$TaskId,
        [int]$DurationSeconds,
        [bool]$Success,
        [string]$ToolsUsed = '',
        [int]$Retries = 0,
        [string]$Blocker = 'none'
    )

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "task-observations-${dateStr}.yaml"

    $content = @"
- timestamp: "$timestamp"
  task_id: "$TaskId"
  duration_seconds: $DurationSeconds
  success: $($Success.ToString().ToLower())
  tools_used: [$ToolsUsed]
  retries: $Retries
  blocker: "$Blocker"
"@

    Add-Content -Path $obsFile -Value $content
    Write-Host "✓ Task observation recorded: $TaskId (${DurationSeconds}s)" -ForegroundColor Cyan
}

function Add-ToolObservation {
    param(
        [string]$ToolName,
        [string]$Operation,
        [int]$DurationMs,
        [bool]$Success,
        [string]$Context = 'general'
    )

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "tool-observations-${dateStr}.yaml"

    $content = @"
- timestamp: "$timestamp"
  tool: "$ToolName"
  operation: "$Operation"
  duration_ms: $DurationMs
  success: $($Success.ToString().ToLower())
  context: "$Context"
"@

    Add-Content -Path $obsFile -Value $content
}

function Add-QualityGateObservation {
    param(
        [string]$GateName,
        [string]$Result,
        [int]$IssuesFound,
        [int]$DurationSeconds,
        [int]$FalsePositives = 0
    )

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "quality-gate-${dateStr}.yaml"

    $content = @"
- timestamp: "$timestamp"
  gate: "$GateName"
  result: "$Result"
  issues_found: $IssuesFound
  duration_seconds: $DurationSeconds
  false_positives: $FalsePositives
"@

    Add-Content -Path $obsFile -Value $content
}

function Add-AgentObservation {
    param(
        [string]$AgentType,
        [string]$TaskType,
        [int]$DurationSeconds,
        [bool]$Success,
        [string]$Complexity = 'medium'
    )

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "agent-observations-${dateStr}.yaml"

    $content = @"
- timestamp: "$timestamp"
  agent_type: "$AgentType"
  task_type: "$TaskType"
  duration_seconds: $DurationSeconds
  success: $($Success.ToString().ToLower())
  complexity: "$Complexity"
"@

    Add-Content -Path $obsFile -Value $content
}

function Add-FailureObservation {
    param(
        [string]$FailureType,
        [string]$Severity,
        [string]$Description,
        [string]$Context = 'general'
    )

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "failure-observations-${dateStr}.yaml"

    $content = @"
- timestamp: "$timestamp"
  failure_type: "$FailureType"
  severity: "$Severity"
  description: "$Description"
  context: "$Context"
"@

    Add-Content -Path $obsFile -Value $content
}

# ============================================================================
# Phase-Specific Collection
# ============================================================================

function Add-PhaseMetrics {
    param(
        [string]$Phase,
        [string]$FeatureDir
    )

    $stateFile = Join-Path -Path $FeatureDir -ChildPath 'state.yaml'
    if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
        Write-Warning "Workflow state not found: $stateFile"
        return
    }

    # Read phase timestamps (simplified - would need YAML parser)
    # For now, just record that phase completed
    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'

    switch ($Phase) {
        'implement' {
            Add-ImplementationMetrics -FeatureDir $FeatureDir
        }
        'optimize' {
            Add-OptimizationMetrics -FeatureDir $FeatureDir
        }
        { $_ -in 'ship-staging', 'ship-prod' } {
            Add-DeploymentMetrics -FeatureDir $FeatureDir
        }
    }
}

function Add-ImplementationMetrics {
    param([string]$FeatureDir)

    $tasksFile = Join-Path -Path $FeatureDir -ChildPath 'tasks.md'
    if (Test-Path -LiteralPath $tasksFile -PathType Leaf) {
        $content = Get-Content $tasksFile -Raw
        $completedCount = ([regex]::Matches($content, '^\- \[x\]', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

        $timestamp = Get-Timestamp
        $dateStr = Get-Date -Format 'yyyyMMdd'
        $obsFile = Join-Path -Path $observationsDir -ChildPath "phase-implementation-${dateStr}.yaml"

        $observation = @"
- timestamp: "$timestamp"
  feature_dir: "$FeatureDir"
  tasks_completed: $completedCount
"@

        Add-Content -Path $obsFile -Value $observation
    }
}

function Add-OptimizationMetrics {
    param([string]$FeatureDir)

    $optReport = Join-Path -Path $FeatureDir -ChildPath 'optimization-report.md'
    if (Test-Path -LiteralPath $optReport -PathType Leaf) {
        $content = Get-Content $optReport -Raw
        $gatesPassed = ([regex]::Matches($content, '✅')).Count
        $gatesFailed = ([regex]::Matches($content, '❌')).Count

        $timestamp = Get-Timestamp
        $dateStr = Get-Date -Format 'yyyyMMdd'
        $obsFile = Join-Path -Path $observationsDir -ChildPath "phase-optimization-${dateStr}.yaml"

        $observation = @"
- timestamp: "$timestamp"
  feature_dir: "$FeatureDir"
  gates_passed: $gatesPassed
  gates_failed: $gatesFailed
"@

        Add-Content -Path $obsFile -Value $observation
    }
}

function Add-DeploymentMetrics {
    param([string]$FeatureDir)

    $timestamp = Get-Timestamp
    $dateStr = Get-Date -Format 'yyyyMMdd'
    $obsFile = Join-Path -Path $observationsDir -ChildPath "phase-deployment-${dateStr}.yaml"

    $observation = @"
- timestamp: "$timestamp"
  feature_dir: "$FeatureDir"
  deployment_status: "completed"
"@

    Add-Content -Path $obsFile -Value $observation
}

# ============================================================================
# Automatic Collection Hooks
# ============================================================================

function Invoke-AfterPhase {
    param(
        [string]$Phase,
        [string]$FeatureDir
    )

    # Check if learning is enabled
    if (-not (Test-LearningEnabled)) {
        return
    }

    # Collect in background job to not block workflow
    Start-Job -ScriptBlock {
        param($p, $f, $script)
        . $script
        Add-PhaseMetrics -Phase $p -FeatureDir $f

        # Update metadata
        $metaFile = Join-Path -Path $f -ChildPath '..\.spec-flow\learnings\learning-metadata.yaml'
        if (Test-Path -LiteralPath $metaFile -PathType Leaf) {
            $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
            # Would update YAML here with proper parser
        }
    } -ArgumentList $Phase, $FeatureDir, $PSCommandPath | Out-Null
}

# ============================================================================
# Main Command Router
# ============================================================================

switch ($Command) {
    'phase' {
        if ($Arguments.Count -lt 2) {
            Write-Error "Usage: learning-collector.ps1 phase <name> <feature-dir>"
            exit 1
        }
        Invoke-AfterPhase -Phase $Arguments[0] -FeatureDir $Arguments[1]
    }

    'task' {
        if ($Arguments.Count -lt 3) {
            Write-Error "Usage: learning-collector.ps1 task <id> <duration> <success> [tools] [retries] [blocker]"
            exit 1
        }
        Add-TaskObservation `
            -TaskId $Arguments[0] `
            -DurationSeconds ([int]$Arguments[1]) `
            -Success ([bool]::Parse($Arguments[2])) `
            -ToolsUsed ($Arguments[3] ?? '') `
            -Retries (if ($Arguments.Count -gt 4) { [int]$Arguments[4] } else { 0 }) `
            -Blocker ($Arguments[5] ?? 'none')
    }

    'tool' {
        if ($Arguments.Count -lt 4) {
            Write-Error "Usage: learning-collector.ps1 tool <name> <operation> <duration_ms> <success> [context]"
            exit 1
        }
        Add-ToolObservation `
            -ToolName $Arguments[0] `
            -Operation $Arguments[1] `
            -DurationMs ([int]$Arguments[2]) `
            -Success ([bool]::Parse($Arguments[3])) `
            -Context ($Arguments[4] ?? 'general')
    }

    'gate' {
        if ($Arguments.Count -lt 4) {
            Write-Error "Usage: learning-collector.ps1 gate <name> <result> <issues> <duration> [false_positives]"
            exit 1
        }
        Add-QualityGateObservation `
            -GateName $Arguments[0] `
            -Result $Arguments[1] `
            -IssuesFound ([int]$Arguments[2]) `
            -DurationSeconds ([int]$Arguments[3]) `
            -FalsePositives (if ($Arguments.Count -gt 4) { [int]$Arguments[4] } else { 0 })
    }

    'agent' {
        if ($Arguments.Count -lt 4) {
            Write-Error "Usage: learning-collector.ps1 agent <type> <task_type> <duration> <success> [complexity]"
            exit 1
        }
        Add-AgentObservation `
            -AgentType $Arguments[0] `
            -TaskType $Arguments[1] `
            -DurationSeconds ([int]$Arguments[2]) `
            -Success ([bool]::Parse($Arguments[3])) `
            -Complexity ($Arguments[4] ?? 'medium')
    }

    'failure' {
        if ($Arguments.Count -lt 3) {
            Write-Error "Usage: learning-collector.ps1 failure <type> <severity> <description> [context]"
            exit 1
        }
        Add-FailureObservation `
            -FailureType $Arguments[0] `
            -Severity $Arguments[1] `
            -Description $Arguments[2] `
            -Context ($Arguments[3] ?? 'general')
    }
}

Write-Host "✓ Learning observation recorded" -ForegroundColor Green


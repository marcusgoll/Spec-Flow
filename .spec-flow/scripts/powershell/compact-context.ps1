#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Compacts feature context when token budget exceeds threshold.

.DESCRIPTION
    Summarizes verbose artifacts (research, tasks, notes) to reduce context size
    while preserving critical decisions, architecture, and error logs.

    Implements phase-aware compression strategies:
    - Planning (Phase 0-2): Aggressive (90% reduction, keep decisions only)
    - Implementation (Phase 3-4): Moderate (60% reduction, keep 20 checkpoints)
    - Optimization (Phase 5-7): Minimal (30% reduction, preserve review context)

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/015-student-dashboard)

.PARAMETER Phase
    Workflow phase: planning | implementation | optimization | auto
    Default: auto (detects from NOTES.md)

.PARAMETER OutputFile
    Optional output file for context delta. Defaults to FeatureDir/context-delta.md

.PARAMETER Json
    Output summary as JSON for machine parsing

.EXAMPLE
    .\compact-context.ps1 -FeatureDir specs/015-student-dashboard

    Compacts context for feature 015, writes to specs/015-student-dashboard/context-delta.md

.EXAMPLE
    .\compact-context.ps1 -FeatureDir specs/015-student-dashboard -Json

    Returns JSON with token counts before/after compaction
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Feature directory path")]
    [string]$FeatureDir,

    [Parameter(Mandatory = $false, HelpMessage = "Workflow phase (auto-detected if omitted)")]
    [ValidateSet("planning", "implementation", "optimization", "auto")]
    [string]$Phase = "auto",

    [Parameter(Mandatory = $false, HelpMessage = "Output file for context delta")]
    [string]$OutputFile,

    [Parameter(Mandatory = $false, HelpMessage = "Output JSON for machine parsing")]
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Validate feature directory ------------------------------------------
if (-not (Test-Path -LiteralPath $FeatureDir -PathType Container)) {
    Write-Error "Feature directory not found: $FeatureDir"
    exit 1
}

# --- Resolve output file -------------------------------------------------
if (-not $OutputFile) {
    $OutputFile = Join-Path -Path $FeatureDir -ChildPath "context-delta.md"
}

# --- Helper: Estimate token count ---------------------------------------
function Get-TokenCount {
    param([string]$Text)

    # Rough estimate: 1 token  4 characters (OpenAI guideline)
    # More accurate would use tiktoken, but this is good enough for compaction decisions
    $charCount = $Text.Length
    return [math]::Ceiling($charCount / 4)
}

# --- Helper: Extract headings only ---------------------------------------
function Get-HeadingsOnly {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return ""
    }

    $content = Get-Content -LiteralPath $FilePath -Raw
    $headings = $content -split "`n" | Where-Object { $_ -match "^##?\s+" }
    return ($headings -join "`n")
}

# --- Helper: Extract decisions only -------------------------------------
function Get-DecisionsOnly {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return ""
    }

    $content = Get-Content -LiteralPath $FilePath -Raw
    $decisions = $content -split "`n" | Where-Object { $_ -match "Decision:" -or $_ -match "^##\s+Decision:" }
    return ($decisions -join "`n")
}

# --- Helper: Extract recent checkpoints ----------------------------------
function Get-RecentCheckpoints {
    param([string]$FilePath, [int]$Count = 10)

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return ""
    }

    $content = Get-Content -LiteralPath $FilePath -Raw
    $checkpointLines = $content -split "`n" | Where-Object { $_ -match "^- \s+T\d+" }
    $recent = $checkpointLines | Select-Object -Last $Count
    return ($recent -join "`n")
}

# --- Helper: Detect current phase from NOTES.md -------------------------
function Get-CurrentPhase {
    param([string]$NotesPath)

    if (-not (Test-Path -LiteralPath $NotesPath -PathType Leaf)) {
        return "planning"  # Default if no NOTES.md
    }

    $content = Get-Content -LiteralPath $NotesPath -Raw

    # Check last completed phase checkpoint
    if ($content -match "Phase 5.*Completed" -or $content -match "Phase 6.*Completed" -or $content -match "Phase 7.*Completed") {
        return "optimization"
    }
    elseif ($content -match "Phase 3.*Completed" -or $content -match "Phase 4.*Completed") {
        return "implementation"
    }
    else {
        return "planning"
    }
}

# --- Helper: Get compaction strategy based on phase --------------------
function Get-CompactionStrategy {
    param([string]$Phase)

    switch ($Phase) {
        "planning" {
            return @{
                ReductionTarget  = 0.90      # Keep only 10% (aggressive)
                CheckpointCount  = 5         # Last 5 checkpoints only
                KeepFullErrorLog = $true
                KeepCodeReview   = $false
                Description      = "Aggressive (keep decisions only)"
            }
        }
        "implementation" {
            return @{
                ReductionTarget  = 0.60      # Keep 40% (moderate)
                CheckpointCount  = 20        # Last 20 tasks
                KeepFullErrorLog = $true
                KeepCodeReview   = $false
                Description      = "Moderate (keep 20 checkpoints)"
            }
        }
        "optimization" {
            return @{
                ReductionTarget  = 0.30      # Keep 70% (minimal compaction)
                CheckpointCount  = 999       # All checkpoints
                KeepFullErrorLog = $true
                KeepCodeReview   = $true
                Description      = "Minimal (preserve review context)"
            }
        }
        default {
            # Fallback to moderate strategy
            return @{
                ReductionTarget  = 0.60
                CheckpointCount  = 20
                KeepFullErrorLog = $true
                KeepCodeReview   = $false
                Description      = "Moderate (default)"
            }
        }
    }
}

# --- Detect phase and get compaction strategy ----------------------------
$researchPath = Join-Path -Path $FeatureDir -ChildPath "research.md"
$notesPath = Join-Path -Path $FeatureDir -ChildPath "NOTES.md"
$tasksPath = Join-Path -Path $FeatureDir -ChildPath "tasks.md"
$errorLogPath = Join-Path -Path $FeatureDir -ChildPath "error-log.md"
$codeReviewPath = Join-Path -Path $FeatureDir -ChildPath "artifacts/code-review-report.md"

# Auto-detect phase if needed
if ($Phase -eq "auto") {
    $Phase = Get-CurrentPhase -NotesPath $notesPath
}

# Get compaction strategy for this phase
$strategy = Get-CompactionStrategy -Phase $Phase

# --- Calculate current context size --------------------------------------
$beforeTokens = 0
if (Test-Path -LiteralPath $researchPath -PathType Leaf) {
    $researchContent = Get-Content -LiteralPath $researchPath -Raw
    $beforeTokens += Get-TokenCount $researchContent
}
if (Test-Path -LiteralPath $notesPath -PathType Leaf) {
    $notesContent = Get-Content -LiteralPath $notesPath -Raw
    $beforeTokens += Get-TokenCount $notesContent
}
if (Test-Path -LiteralPath $tasksPath -PathType Leaf) {
    $tasksContent = Get-Content -LiteralPath $tasksPath -Raw
    $beforeTokens += Get-TokenCount $tasksContent
}

# --- Generate compacted context (phase-aware) ----------------------------
$planPath = Join-Path -Path $FeatureDir -ChildPath "plan.md"

# Build compacted output based on strategy
$compacted = @"
# Context Delta (Compacted - $Phase Phase)

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Feature**: $(Split-Path -Leaf $FeatureDir)
**Phase**: $Phase
**Strategy**: $($strategy.Description)
**Original context**: $beforeTokens tokens

---

## Research Summary (Decisions Only)

$(Get-DecisionsOnly $researchPath)

---

## Architecture Headings

$(Get-HeadingsOnly $planPath)

---

## Recent Task Checkpoints (Last $($strategy.CheckpointCount))

$(Get-RecentCheckpoints -FilePath $notesPath -Count $strategy.CheckpointCount)

---

## Error Log (Full - preserved)

$(if (Test-Path -LiteralPath $errorLogPath -PathType Leaf) { Get-Content -LiteralPath $errorLogPath -Raw } else { "No errors logged" })

---
$(if ($strategy.KeepCodeReview -and (Test-Path -LiteralPath $codeReviewPath -PathType Leaf)) {
@"

## Code Review Report (Optimization Phase - Full Preservation)

$(Get-Content -LiteralPath $codeReviewPath -Raw)

---
"@
} else { "" })

## What Was Compacted ($Phase Phase)

**Strategy**: $($strategy.Description)
**Reduction target**: $($strategy.ReductionTarget * 100)%

**Removed:**
-  Detailed research notes (kept decisions only)
-  Full task descriptions (kept last $($strategy.CheckpointCount) checkpoints)
-  Intermediate implementation notes

**Preserved:**
-  All decisions and rationale
-  Architecture headings
-  Recent task progress (last $($strategy.CheckpointCount))
-  Full error log (all failures learned)
$(if ($strategy.KeepCodeReview) { "-  Code review report (optimization phase)" } else { "" })

**Original files remain unchanged** - this is a summary for context efficiency.

"@

# --- Calculate compacted context size ------------------------------------
$afterTokens = Get-TokenCount $compacted

# --- Write compacted context to file -------------------------------------
Set-Content -LiteralPath $OutputFile -Value $compacted -NoNewline

# --- Update NOTES.md with compaction checkpoint --------------------------
if (Test-Path -LiteralPath $notesPath -PathType Leaf) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $checkpoint = "`n-  Context compacted ($Phase phase): $beforeTokens  $afterTokens tokens ($timestamp)"
    Add-Content -LiteralPath $notesPath -Value $checkpoint
}

# --- Output summary ------------------------------------------------------
$reductionPct = [math]::Round((1 - ($afterTokens / $beforeTokens)) * 100, 1)

if ($Json) {
    $result = @{
        success          = $true
        featureDir       = $FeatureDir
        outputFile       = $OutputFile
        tokensBefor      = $beforeTokens
        tokensAfter      = $afterTokens
        reductionPercent = $reductionPct
        timestamp        = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    $result | ConvertTo-Json -Compress | Write-Output
}
else {
    Write-Output ""
    Write-Output " CONTEXT COMPACTION COMPLETE"
    Write-Output ""
    Write-Output ""
    Write-Output "Feature: $(Split-Path -Leaf $FeatureDir)"
    Write-Output "Output: $OutputFile"
    Write-Output ""
    Write-Output "Context reduction:"
    Write-Output "  Before: $beforeTokens tokens"
    Write-Output "  After:  $afterTokens tokens"
    Write-Output "  Saved:  $(($beforeTokens - $afterTokens)) tokens ($reductionPct% reduction)"
    Write-Output ""
    Write-Output "Checkpoint added to NOTES.md"
}

exit 0



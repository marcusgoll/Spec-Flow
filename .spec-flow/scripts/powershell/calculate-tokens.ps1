#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Calculate token count for feature artifacts with phase-aware budgets.

.DESCRIPTION
    Estimates token count using 4-char-per-token heuristic (OpenAI guideline).
    Tracks cumulative tokens across all artifacts.
    Determines if compaction is needed based on phase-specific thresholds.

    Phase budgets (80% compaction trigger):
    - Planning (Phase 0-2): 75k tokens  compact at 60k
    - Implementation (Phase 3-4): 100k tokens  compact at 80k
    - Optimization (Phase 5-7): 125k tokens  compact at 100k

.PARAMETER FeatureDir
    Feature directory path (e.g., specs/015-student-dashboard)

.PARAMETER Phase
    Current workflow phase: planning | implementation | optimization | auto
    Default: auto (detects from NOTES.md)

.PARAMETER Json
    Output results as JSON for machine parsing

.PARAMETER ShowBreakdown
    Show per-file token breakdown

.EXAMPLE
    .\calculate-tokens.ps1 -FeatureDir specs/015-feature -Phase planning

    Tokens: 45,234 / 75,000 (60.3%)
    Should compact: false

.EXAMPLE
    .\calculate-tokens.ps1 -FeatureDir specs/015-feature -Phase implementation -Json

    {"totalTokens":82145,"budget":100000,"shouldCompact":true,...}

.EXAMPLE
    .\calculate-tokens.ps1 -FeatureDir specs/015-feature -Phase auto -ShowBreakdown

    Tokens per file:
      spec.md: 8,234
      plan.md: 24,567
      research.md: 18,902
      ...
    Total: 65,123 / 100,000 (65.1%)
#>

param(
    [Parameter(Mandatory = $true, HelpMessage = "Feature directory path")]
    [string]$FeatureDir,

    [Parameter(Mandatory = $false, HelpMessage = "Workflow phase (auto-detected if omitted)")]
    [ValidateSet("planning", "implementation", "optimization", "auto")]
    [string]$Phase = "auto",

    [Parameter(Mandatory = $false, HelpMessage = "Output JSON for machine parsing")]
    [switch]$Json,

    [Parameter(Mandatory = $false, HelpMessage = "Show per-file token breakdown")]
    [switch]$ShowBreakdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Validate feature directory ------------------------------------------
if (-not (Test-Path -LiteralPath $FeatureDir -PathType Container)) {
    Write-Error "Feature directory not found: $FeatureDir"
    exit 1
}

# --- Helper: Estimate token count ---------------------------------------
function Get-TokenCount {
    param([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return 0
    }

    # Rough estimate: 1 token  4 characters (OpenAI guideline)
    $content = Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return 0 }

    $charCount = $content.Length
    return [math]::Ceiling($charCount / 4)
}

# --- Helper: Detect current phase from NOTES.md -------------------------
function Get-CurrentPhase {
    param([string]$FeatureDir)

    $notesPath = Join-Path -Path $FeatureDir -ChildPath "NOTES.md"
    if (-not (Test-Path -LiteralPath $notesPath -PathType Leaf)) {
        return "planning"  # Default if no NOTES.md
    }

    $content = Get-Content -LiteralPath $notesPath -Raw

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

# --- Phase budget configuration ------------------------------------------
$phaseBudgets = @{
    planning       = 75000   # Phase 0-2: Spec, Plan, Tasks
    implementation = 100000  # Phase 3-4: Analyze, Implement
    optimization   = 125000  # Phase 5-7: Optimize, Ship, Validate
}

$compactionThresholds = @{
    planning       = 60000   # 80% of 75k
    implementation = 80000   # 80% of 100k
    optimization   = 100000  # 80% of 125k
}

# --- Auto-detect phase if needed -----------------------------------------
if ($Phase -eq "auto") {
    $Phase = Get-CurrentPhase -FeatureDir $FeatureDir
}

# --- Calculate tokens for all artifacts ----------------------------------
$artifacts = @(
    "spec.md",
    "plan.md",
    "research.md",
    "tasks.md",
    "NOTES.md",
    "error-log.md",
    "data-model.md",
    "quickstart.md",
    "visuals/README.md"
)

$totalTokens = 0
$breakdown = @{}

foreach ($artifact in $artifacts) {
    $path = Join-Path -Path $FeatureDir -ChildPath $artifact
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $tokens = Get-TokenCount -FilePath $path
        $totalTokens += $tokens
        $breakdown[$artifact] = $tokens
    }
}

# Add artifacts directory files (if exists)
$artifactsDir = Join-Path -Path $FeatureDir -ChildPath "artifacts"
if (Test-Path -LiteralPath $artifactsDir -PathType Container) {
    $artifactFiles = Get-ChildItem -LiteralPath $artifactsDir -File -ErrorAction SilentlyContinue
    foreach ($file in $artifactFiles) {
        $tokens = Get-TokenCount -FilePath $file.FullName
        $totalTokens += $tokens
        $breakdown["artifacts/$($file.Name)"] = $tokens
    }
}

# --- Determine budget and thresholds -------------------------------------
$currentBudget = $phaseBudgets[$Phase]
$compactionThreshold = $compactionThresholds[$Phase]
$remaining = $currentBudget - $totalTokens
$percentUsed = if ($currentBudget -gt 0) { [math]::Round(($totalTokens / $currentBudget) * 100, 1) } else { 0 }
$shouldCompact = $totalTokens -gt $compactionThreshold

# --- Build result object -------------------------------------------------
$result = [PSCustomObject]@{
    featureDir          = $FeatureDir
    phase               = $Phase
    totalTokens         = $totalTokens
    budget              = $currentBudget
    compactionThreshold = $compactionThreshold
    remaining           = $remaining
    percentUsed         = $percentUsed
    shouldCompact       = $shouldCompact
    breakdown           = $breakdown
}

# --- Output --------------------------------------------------------------
if ($Json) {
    $result | ConvertTo-Json -Depth 3 | Write-Output
}
else {
    # Human-readable output
    if ($ShowBreakdown) {
        Write-Output ""
        Write-Output " TOKEN BREAKDOWN"
        Write-Output ""
        Write-Output ""
        foreach ($file in $breakdown.Keys | Sort-Object) {
            $tokens = $breakdown[$file]
            Write-Output "  $file`: $($tokens.ToString('N0')) tokens"
        }
        Write-Output ""
        Write-Output ""
    }

    Write-Output "Tokens: $($totalTokens.ToString('N0')) / $($currentBudget.ToString('N0')) ($percentUsed%)"
    Write-Output "Phase: $Phase"
    Write-Output "Threshold: $($compactionThreshold.ToString('N0')) tokens (80%)"
    Write-Output "Remaining: $($remaining.ToString('N0')) tokens"
    Write-Output ""

    if ($shouldCompact) {
        Write-Output "  COMPACTION RECOMMENDED"
        Write-Output "   Exceeded $Phase threshold ($($compactionThreshold.ToString('N0')) tokens)"
        Write-Output ""
        Write-Output "   Run: compact-context.ps1 -FeatureDir '$FeatureDir' -Phase '$Phase'"
    }
    else {
        $marginTokens = $compactionThreshold - $totalTokens
        $marginPercent = [math]::Round(($marginTokens / $compactionThreshold) * 100, 1)
        Write-Output " Within budget ($marginPercent% margin until compaction)"
    }
}

exit 0



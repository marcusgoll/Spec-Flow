<#
.SYNOPSIS
    Generate dev docs (task-scoped persistence)

.DESCRIPTION
    Creates three files in dev/active/[task-name]/:
      - [task-name]-plan.md (strategic overview)
      - [task-name]-context.md (key files, decisions)
      - [task-name]-tasks.md (checklist format)

.PARAMETER TaskName
    Name of the task (used for directory and file naming)

.PARAMETER FeatureDir
    Path to feature directory (e.g., "specs/001-auth")

.EXAMPLE
    .\generate-dev-docs.ps1 -TaskName "database-migrations" -FeatureDir "specs/001-auth"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,

    [Parameter(Mandatory=$true)]
    [string]$FeatureDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Setup Paths ---
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path (Split-Path (Split-Path $ScriptDir -Parent) -Parent) -Parent

$DevDocsDir = Join-Path $ProjectRoot "dev\active\$TaskName"
$TemplatesDir = Join-Path $ProjectRoot ".spec-flow\templates\dev-docs"

$SpecFile = Join-Path $ProjectRoot "$FeatureDir\spec.md"
$PlanFile = Join-Path $ProjectRoot "$FeatureDir\plan.md"

# Extract feature name from spec.md
$FeatureSlug = Split-Path $FeatureDir -Leaf
$FeatureName = $FeatureSlug

if (Test-Path $SpecFile) {
    $firstLine = Get-Content $SpecFile -TotalCount 20 | Where-Object { $_ -match '^# ' } | Select-Object -First 1
    if ($firstLine) {
        $FeatureName = $firstLine -replace '^# ', ''
    }
}

# Current date and status
$Date = Get-Date -Format "yyyy-MM-dd"
$Status = "In Progress"

# --- Create Output Directory ---
if (-not (Test-Path $DevDocsDir)) {
    New-Item -ItemType Directory -Path $DevDocsDir -Force | Out-Null
}

Write-Host "📝 Generating dev docs for: $TaskName" -ForegroundColor Cyan
Write-Host "   Feature: $FeatureName" -ForegroundColor Gray
Write-Host "   Output: $DevDocsDir" -ForegroundColor Gray
Write-Host ""

# --- Generate plan.md ---
$PlanOutput = Join-Path $DevDocsDir "${TaskName}-plan.md"

if (-not (Test-Path $PlanOutput)) {
    $planTemplate = Get-Content (Join-Path $TemplatesDir "plan-template.md") -Raw
    $planContent = $planTemplate `
        -replace '\{\{TASK_NAME\}\}', $TaskName `
        -replace '\{\{DATE\}\}', $Date `
        -replace '\{\{FEATURE_NAME\}\}', $FeatureName `
        -replace '\{\{STATUS\}\}', $Status

    Set-Content -Path $PlanOutput -Value $planContent -NoNewline
    Write-Host "✅ Created: ${TaskName}-plan.md" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped: ${TaskName}-plan.md (already exists)" -ForegroundColor Yellow
}

# --- Generate context.md ---
$ContextOutput = Join-Path $DevDocsDir "${TaskName}-context.md"

if (-not (Test-Path $ContextOutput)) {
    $contextTemplate = Get-Content (Join-Path $TemplatesDir "context-template.md") -Raw
    $contextContent = $contextTemplate `
        -replace '\{\{TASK_NAME\}\}', $TaskName `
        -replace '\{\{DATE\}\}', $Date `
        -replace '\{\{FEATURE_NAME\}\}', $FeatureName `
        -replace '\{\{FEATURE_SLUG\}\}', $FeatureSlug `
        -replace '\{\{FILE_PATH_1\}\}', '[Specify file path]' `
        -replace '\{\{FILE_PATH_2\}\}', '[Specify file path]' `
        -replace '\{\{FILE_PATH_3\}\}', '[Specify file path]' `
        -replace '\{\{FILE_PATH_4\}\}', '[Specify file path]' `
        -replace '\{\{FILE_PATH_5\}\}', '[Specify file path]' `
        -replace '\{\{DOC_NAME\}\}', 'tech-stack'

    Set-Content -Path $ContextOutput -Value $contextContent -NoNewline
    Write-Host "✅ Created: ${TaskName}-context.md" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped: ${TaskName}-context.md (already exists)" -ForegroundColor Yellow
}

# --- Generate tasks.md ---
$TasksOutput = Join-Path $DevDocsDir "${TaskName}-tasks.md"

if (-not (Test-Path $TasksOutput)) {
    $tasksTemplate = Get-Content (Join-Path $TemplatesDir "tasks-template.md") -Raw
    $tasksContent = $tasksTemplate `
        -replace '\{\{TASK_NAME\}\}', $TaskName `
        -replace '\{\{DATE\}\}', $Date `
        -replace '\{\{FEATURE_NAME\}\}', $FeatureName `
        -replace '\{\{TOTAL_TASKS\}\}', '0' `
        -replace '\{\{COMPLETED_TASKS\}\}', '0' `
        -replace '\{\{PROGRESS_PERCENTAGE\}\}', '0' `
        -replace '\{\{IN_PROGRESS_TASKS\}\}', '0' `
        -replace '\{\{BLOCKED_TASKS\}\}', '0' `
        -replace '\{\{ETA\}\}', 'TBD' `
        -replace '\{\{COMPLETION_DATE\}\}', $Date `
        -replace '\{\{START_DATE\}\}', $Date `
        -replace '\{\{BLOCK_DATE\}\}', $Date `
        -replace '\{\{DATE_1\}\}', $Date `
        -replace '\{\{DATE_2\}\}', $Date `
        -replace '\{\{AVG_TASKS_PER_DAY\}\}', '0' `
        -replace '\{\{REMAINING_TIME\}\}', 'TBD'

    Set-Content -Path $TasksOutput -Value $tasksContent -NoNewline
    Write-Host "✅ Created: ${TaskName}-tasks.md" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped: ${TaskName}-tasks.md (already exists)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ Dev docs generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit ${TaskName}-plan.md with strategic overview" -ForegroundColor Gray
Write-Host "  2. Edit ${TaskName}-context.md with key files and decisions" -ForegroundColor Gray
Write-Host "  3. Edit ${TaskName}-tasks.md with concrete tasks" -ForegroundColor Gray
Write-Host ""
Write-Host "Resume work:" -ForegroundColor Cyan
Write-Host "  Read dev/active/${TaskName}/*.md for full context" -ForegroundColor Gray

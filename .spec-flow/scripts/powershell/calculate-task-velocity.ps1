#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Calculate task velocity and generate Progress Summary for tasks.md

.DESCRIPTION
    Analyzes tasks.md and NOTES.md to calculate:
    - Overall progress (completed/total)
    - Average time per task
    - Completion rate (tasks/day)
    - Estimated remaining time and ETA
    - Bottlenecks (tasks taking longer than estimated)

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.PARAMETER Json
    Output in JSON format

.EXAMPLE
    .\calculate-task-velocity.ps1 -FeatureDir "specs/001-auth-flow"

.EXAMPLE
    .\calculate-task-velocity.ps1 -FeatureDir "specs/001-auth-flow" -Json
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir,

    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$tasksFile = Join-Path $FeatureDir "tasks.md"
$notesFile = Join-Path $FeatureDir "NOTES.md"

if (-not (Test-Path $tasksFile)) {
    throw "No tasks.md found in $FeatureDir"
}

# Parse tasks.md for overall counts
$tasksContent = Get-Content $tasksFile -Raw
$allTasks = [regex]::Matches($tasksContent, '^\s*-\s*\[.?\]\s*T\d+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
$completedTasks = [regex]::Matches($tasksContent, '^\s*-\s*\[[Xx]\]\s*T\d+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
$inProgressTasks = [regex]::Matches($tasksContent, '^\s*-\s*\[~P\]\s*T\d+', [System.Text.RegularExpressions.RegexOptions]::Multiline)

$totalTasks = $allTasks.Count
$completedCount = $completedTasks.Count
$inProgressCount = $inProgressTasks.Count
$remainingCount = $totalTasks - $completedCount - $inProgressCount
$percentageComplete = if ($totalTasks -gt 0) { [math]::Floor(($completedCount / $totalTasks) * 100) } else { 0 }

# Parse NOTES.md for timing data
$completions = @()
if (Test-Path $notesFile) {
    $notesContent = Get-Content $notesFile -Raw
    $completionPattern = '✅\s+(T\d+)[^:]*:\s+(.+?)\s+-\s+(\d+)min\s+\((\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\)'
    $matches = [regex]::Matches($notesContent, $completionPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

    foreach ($match in $matches) {
        $completions += @{
            taskId      = $match.Groups[1].Value
            description = $match.Groups[2].Value
            duration    = [int]$match.Groups[3].Value
            timestamp   = [datetime]::ParseExact($match.Groups[4].Value, "yyyy-MM-dd HH:mm", $null)
        }
    }
}

# Calculate velocity metrics
$avgTimePerTask = if ($completions.Count -gt 0) {
    ($completions | Measure-Object -Property duration -Average).Average
}
else { 0 }

# Calculate completion rate (tasks/day) from last 2 days
$twoDaysAgo = (Get-Date).AddDays(-2)
$recentCompletions = $completions | Where-Object { $_.timestamp -gt $twoDaysAgo }
$completionRate = if ($recentCompletions.Count -gt 0) {
    $daySpan = ((Get-Date) - ($recentCompletions | Sort-Object timestamp | Select-Object -First 1).timestamp).TotalDays
    if ($daySpan -gt 0) {
        [math]::Round($recentCompletions.Count / $daySpan, 1)
    }
    else { $recentCompletions.Count }
}
else { 0 }

# Estimate remaining time and ETA
$estRemainingHours = if ($avgTimePerTask -gt 0 -and $remainingCount -gt 0) {
    [math]::Round(($remainingCount * $avgTimePerTask) / 60, 1)
}
else { 0 }

$eta = if ($completionRate -gt 0 -and $remainingCount -gt 0) {
    $daysRemaining = [math]::Ceiling($remainingCount / $completionRate)
    (Get-Date).AddDays($daysRemaining).ToString("yyyy-MM-dd HH:mm")
}
else { "N/A" }

# Get last 3 completions
$recentCompletionsList = $completions | Sort-Object timestamp -Descending | Select-Object -First 3

# Identify bottlenecks (tasks >1.5x average time)
$bottlenecks = @()
if ($avgTimePerTask -gt 0) {
    $threshold = $avgTimePerTask * 1.5
    $bottlenecks = $completions | Where-Object { $_.duration -gt $threshold } | ForEach-Object {
        @{
            taskId      = $_.taskId
            description = $_.description
            actual      = $_.duration
            average     = [math]::Round($avgTimePerTask, 0)
            impact      = [math]::Round(($_.duration - $avgTimePerTask) / 60, 1)
        }
    }
}

# Current sprint status (today's goal)
$today = Get-Date -Format "yyyy-MM-dd"
$todayCompletions = $completions | Where-Object { $_.timestamp.ToString("yyyy-MM-dd") -eq $today }
$todayCount = $todayCompletions.Count

# Determine if on track
$onTrack = if ($completionRate -gt 0 -and $remainingCount -gt 0) {
    $daysToDeadline = 7 # Assume 1-week sprint
    $requiredRate = $remainingCount / $daysToDeadline
    $completionRate -ge $requiredRate
}
else { $true }

# Generate output
if ($Json) {
    @{
        total              = $totalTasks
        completed          = $completedCount
        inProgress         = $inProgressCount
        remaining          = $remainingCount
        percentageComplete = $percentageComplete
        avgTimePerTask     = [math]::Round($avgTimePerTask, 0)
        completionRate     = $completionRate
        estRemainingHours  = $estRemainingHours
        eta                = $eta
        recentCompletions  = $recentCompletionsList
        bottlenecks        = $bottlenecks
        todayCount         = $todayCount
        onTrack            = $onTrack
    } | ConvertTo-Json -Depth 3
}
else {
    # Generate markdown for Progress Summary section
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

    $summary = @"
## Progress Summary

> **Purpose**: Track task completion velocity, ETA, and identify bottlenecks
> **Updated by**: Task tracker after each task completion
> **Last Updated**: $timestamp

### Overall Progress

- **Total Tasks**: $totalTasks
- **Completed**: $completedCount ($percentageComplete%)
- **In Progress**: $inProgressCount
- **Blocked**: 0
- **Remaining**: $remainingCount

### Velocity Metrics

- **Average Time per Task**: $([math]::Round($avgTimePerTask, 0)) minutes
- **Completion Rate**: $completionRate tasks/day (last 2 days)
- **Estimated Remaining Time**: $estRemainingHours hours
- **ETA**: $eta

### Recent Completions

"@

    foreach ($completion in $recentCompletionsList) {
        $summary += "`n- ✅ $($completion.taskId): $($completion.description) - $($completion.duration)min ($($completion.timestamp.ToString('yyyy-MM-dd HH:mm')))"
    }

    if ($bottlenecks.Count -gt 0) {
        $summary += "`n`n### Bottlenecks`n`n**Tasks Taking Longer Than Estimated**:`n"
        foreach ($bottleneck in $bottlenecks) {
            $summary += "`n- **$($bottleneck.taskId)**: Took $($bottleneck.actual)min vs average $($bottleneck.average)min"
            $summary += "`n  - **Impact**: +$($bottleneck.impact) hours overall delay"
        }
    }
    else {
        $summary += "`n`n### Bottlenecks`n`nNo significant bottlenecks detected."
    }

    $onTrackText = if ($onTrack) { "Yes" } else { "No" }
    $summary += @"


### Current Sprint Status

**Today's Goal**: Complete remaining tasks
**Progress**: $todayCount tasks completed today
**On Track**: $onTrackText
"@

    Write-Output $summary
}


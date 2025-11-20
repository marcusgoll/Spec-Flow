<#
.SYNOPSIS
    Track command usage to build learning system

.DESCRIPTION
    Records command mode selection in command-history.yaml to learn user preferences.
    Updates usage counts and timestamps for intelligent mode suggestions.

.PARAMETER Command
    Command name (epic, tasks, init-project, run-prompt)

.PARAMETER Mode
    Selected mode (e.g., "auto", "interactive", "ui-first", etc.)

.PARAMETER HistoryPath
    Optional path to command-history.yaml (defaults to .spec-flow/memory/command-history.yaml)

.EXAMPLE
    & .\.spec-flow\scripts\utils\track-command-usage.ps1 -Command "epic" -Mode "auto"
    # Records that user selected auto mode for /epic command

.NOTES
    Updates:
    - last_used_mode: Most recent mode selection
    - usage_count: Increments counter for selected mode
    - last_updated: ISO 8601 timestamp
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [Parameter(Mandatory=$true)]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$HistoryPath = ".spec-flow/memory/command-history.yaml"
)

# Ensure history file exists
if (-not (Test-Path $HistoryPath)) {
    Write-Warning "Command history file not found at $HistoryPath"
    return
}

try {
    # Read existing history
    $historyContent = Get-Content -Path $HistoryPath -Raw

    # Get current timestamp in ISO 8601 format
    $timestamp = Get-Date -Format "o"

    # Parse current command section
    $commandKey = $Command -replace '-', '-'
    $pattern = "(?s)$commandKey:\s*\n(.*?)(?=\n\w+:|$)"

    if ($historyContent -match $pattern) {
        $commandSection = $matches[1]

        # Extract current usage count for the mode
        $modePattern = "$Mode:\s+(\d+)"
        $currentCount = 0
        if ($commandSection -match $modePattern) {
            $currentCount = [int]$matches[1]
        }
        $newCount = $currentCount + 1

        # Update the command section
        # 1. Update last_used_mode
        $historyContent = $historyContent -replace "($commandKey:\s*\n\s+last_used_mode:\s+)\S+", "`${1}$Mode"

        # 2. Update or add usage_count for the mode
        if ($commandSection -match $modePattern) {
            $historyContent = $historyContent -replace "($commandKey:[\s\S]*?$Mode:\s+)\d+", "`${1}$newCount"
        }

        # 3. Update last_updated timestamp
        $historyContent = $historyContent -replace "($commandKey:[\s\S]*?last_updated:\s+)[\S\s]*?(?=\n\w+:|$)", "`${1}$timestamp`n"

        # Write updated content back to file
        Set-Content -Path $HistoryPath -Value $historyContent -NoNewline

        Write-Verbose "Updated command history: $Command -> $Mode (count: $newCount)"

    } else {
        Write-Warning "Could not find command '$Command' in history file"
    }

} catch {
    Write-Warning "Failed to track command usage: $($_.Exception.Message)"
}

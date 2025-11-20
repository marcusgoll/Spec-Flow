<#
.SYNOPSIS
    Load command usage history for learning system

.DESCRIPTION
    Reads command-history.yaml to get last used mode and usage statistics.
    Used to show intelligent suggestions in AskUserQuestion prompts.

.PARAMETER Command
    Command name to load history for (epic, tasks, init-project, run-prompt)

.PARAMETER HistoryPath
    Optional path to command-history.yaml (defaults to .spec-flow/memory/command-history.yaml)

.EXAMPLE
    $history = & .\.spec-flow\scripts\utils\load-command-history.ps1 -Command "epic"
    $history.last_used_mode      # Returns: "auto" or "interactive"
    $history.usage_count.auto    # Returns: 12
    $history.usage_count.interactive  # Returns: 3

.NOTES
    Returns hashtable with:
    - last_used_mode: Most recent mode selection (string or null)
    - usage_count: Hashtable of mode -> count
    - last_updated: ISO 8601 timestamp (string or null)
    - total_uses: Sum of all mode counts (int)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$HistoryPath = ".spec-flow/memory/command-history.yaml"
)

# Default empty history
$emptyHistory = @{
    last_used_mode = $null
    usage_count = @{}
    last_updated = $null
    total_uses = 0
}

# Check if history file exists
if (-not (Test-Path $HistoryPath)) {
    Write-Verbose "Command history file not found at $HistoryPath"
    return $emptyHistory
}

try {
    # Read history file
    $historyContent = Get-Content -Path $HistoryPath -Raw

    # Normalize command name (replace hyphens)
    $commandKey = $Command -replace '-', '-'

    # Extract command section
    $pattern = "(?s)$commandKey:\s*\n(.*?)(?=\n\w+:|$)"

    if ($historyContent -notmatch $pattern) {
        Write-Verbose "Command '$Command' not found in history"
        return $emptyHistory
    }

    $commandSection = $matches[1]

    # Parse last_used_mode
    $lastUsedMode = $null
    if ($commandSection -match 'last_used_mode:\s+(\S+)') {
        $lastUsedMode = $matches[1]
        if ($lastUsedMode -eq 'null') {
            $lastUsedMode = $null
        }
    }

    # Parse usage_count
    $usageCount = @{}
    $totalUses = 0

    if ($commandSection -match '(?s)usage_count:\s*\n(.*?)(?=\n  \w+:|$)') {
        $usageCountSection = $matches[1]

        # Extract each mode and count
        $usageCountSection -split "`n" | ForEach-Object {
            if ($_ -match '^\s+(\S+):\s+(\d+)') {
                $mode = $matches[1]
                $count = [int]$matches[2]
                $usageCount[$mode] = $count
                $totalUses += $count
            }
        }
    }

    # Parse last_updated
    $lastUpdated = $null
    if ($commandSection -match 'last_updated:\s+(.+)') {
        $lastUpdated = $matches[1].Trim()
        if ($lastUpdated -eq 'null') {
            $lastUpdated = $null
        }
    }

    # Return history object
    return @{
        last_used_mode = $lastUsedMode
        usage_count = $usageCount
        last_updated = $lastUpdated
        total_uses = $totalUses
    }

} catch {
    Write-Warning "Failed to load command history: $($_.Exception.Message)"
    return $emptyHistory
}

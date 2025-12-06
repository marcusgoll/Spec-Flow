#Requires -Version 5.1
<#
.SYNOPSIS
    Token-efficient CI waiting script for GitHub PRs.

.DESCRIPTION
    Polls GitHub API every 30 seconds to check PR status and CI checks.
    Returns when CI completes (success or failure) or PR is merged.

    Used by /phase-1-ship and /phase-2-ship commands to wait for CI
    without consuming Claude Code tokens during the wait.

.PARAMETER PrNumber
    The pull request number to monitor.

.PARAMETER Json
    Output results as JSON for machine parsing.

.PARAMETER PollInterval
    Seconds between API polls (default: 30).

.PARAMETER MaxWaitMinutes
    Maximum minutes to wait before timeout (default: 60).

.EXAMPLE
    .\wait-for-ci.ps1 -PrNumber 123

    Waits for PR #123 CI checks to complete, outputs human-readable status.

.EXAMPLE
    .\wait-for-ci.ps1 -PrNumber 123 -Json

    Waits for PR #123, outputs JSON result for machine parsing.

.EXAMPLE
    .\wait-for-ci.ps1 -PrNumber 123 -PollInterval 15 -MaxWaitMinutes 30

    Custom polling: check every 15 seconds, timeout after 30 minutes.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Pull request number")]
    [int]$PrNumber,

    [Parameter(Mandatory = $false, HelpMessage = "Output JSON for machine parsing")]
    [switch]$Json,

    [Parameter(Mandatory = $false, HelpMessage = "Seconds between API polls")]
    [int]$PollInterval = 30,

    [Parameter(Mandatory = $false, HelpMessage = "Maximum minutes to wait")]
    [int]$MaxWaitMinutes = 60
)

# Import common utilities
$commonPath = Join-Path $PSScriptRoot "common.ps1"
if (Test-Path $commonPath) {
    . $commonPath
}

# Validate GitHub CLI is available
function Test-GitHubCLI {
    try {
        $null = gh --version
        return $true
    }
    catch {
        Write-Error "GitHub CLI (gh) not found. Install from: https://cli.github.com/"
        return $false
    }
}

# Get PR status and checks from GitHub API
function Get-PRStatus {
    param([int]$PrNumber)

    try {
        # Get PR details (state, merged, mergeable)
        $prJson = gh pr view $PrNumber --json state, merged, mergedAt, mergeable, statusCheckRollup 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to fetch PR #$PrNumber"
        }

        $pr = $prJson | ConvertFrom-Json

        # Parse status checks
        $checks = @()
        $allSuccess = $true
        $anyPending = $false

        if ($pr.statusCheckRollup) {
            foreach ($context in $pr.statusCheckRollup) {
                $status = "unknown"

                # Map GitHub check states to our status
                if ($context.state -eq "SUCCESS" -or $context.conclusion -eq "success") {
                    $status = "success"
                }
                elseif ($context.state -eq "PENDING" -or $context.status -eq "in_progress" -or $context.status -eq "queued") {
                    $status = "pending"
                    $anyPending = $true
                    $allSuccess = $false
                }
                elseif ($context.state -eq "FAILURE" -or $context.conclusion -eq "failure") {
                    $status = "failure"
                    $allSuccess = $false
                }
                elseif ($context.state -eq "ERROR" -or $context.conclusion -eq "cancelled") {
                    $status = "error"
                    $allSuccess = $false
                }

                $checks += @{
                    name    = $context.name
                    status  = $status
                    context = $context.context
                }
            }
        }

        # Determine overall status
        $overallStatus = "pending"
        if ($pr.merged) {
            $overallStatus = "merged"
        }
        elseif ($allSuccess -and $checks.Count -gt 0) {
            $overallStatus = "success"
        }
        elseif ($anyPending) {
            $overallStatus = "pending"
        }
        elseif (-not $allSuccess) {
            $overallStatus = "failure"
        }

        return @{
            status    = $overallStatus
            prState   = $pr.state
            merged    = $pr.merged
            mergedAt  = $pr.mergedAt
            mergeable = $pr.mergeable
            checks    = $checks
            prNumber  = $PrNumber
        }

    }
    catch {
        Write-Error "Error fetching PR status: $_"
        return $null
    }
}

# Format check status with emoji
function Format-CheckStatus {
    param([string]$Status)

    switch ($Status) {
        "success" { return "" }
        "failure" { return "" }
        "error" { return "" }
        "pending" { return "" }
        default { return "" }
    }
}

# Main execution
function Wait-ForCI {
    # Validate prerequisites
    if (-not (Test-GitHubCLI)) {
        exit 1
    }

    # Calculate timeout
    $startTime = Get-Date
    $timeoutMinutes = $MaxWaitMinutes
    $timeoutTime = $startTime.AddMinutes($timeoutMinutes)

    if (-not $Json) {
        Write-Host " Waiting for CI checks on PR #$PrNumber..." -ForegroundColor Cyan
        Write-Host "   Polling every $PollInterval seconds (timeout: $timeoutMinutes minutes)" -ForegroundColor Gray
        Write-Host ""
    }

    $iteration = 0

    while ($true) {
        $iteration++

        # Fetch current status
        $result = Get-PRStatus -PrNumber $PrNumber

        if ($null -eq $result) {
            Write-Error "Failed to fetch PR status. Exiting."
            exit 1
        }

        # Check for completion
        $isComplete = $result.status -in @("success", "failure", "error", "merged")

        # Human-readable output (unless -Json)
        if (-not $Json) {
            $elapsed = (Get-Date) - $startTime
            $elapsedStr = "{0:mm}:{0:ss}" -f $elapsed

            Write-Host "[$elapsedStr] Status: $($result.status)" -ForegroundColor $(
                if ($result.status -eq "success" -or $result.status -eq "merged") { "Green" }
                elseif ($result.status -eq "failure" -or $result.status -eq "error") { "Red" }
                else { "Yellow" }
            )

            if ($result.checks.Count -gt 0) {
                foreach ($check in $result.checks) {
                    $emoji = Format-CheckStatus -Status $check.status
                    Write-Host "   $emoji $($check.name)" -ForegroundColor Gray
                }
            }
            else {
                Write-Host "   (No status checks found)" -ForegroundColor Gray
            }

            Write-Host ""
        }

        # If complete, output result and exit
        if ($isComplete) {
            if ($Json) {
                # JSON output for machine parsing
                $result | ConvertTo-Json -Depth 10
            }
            else {
                # Human-readable completion message
                $elapsed = (Get-Date) - $startTime
                $elapsedStr = "{0:mm}:{0:ss}" -f $elapsed

                Write-Host "" -ForegroundColor Gray

                if ($result.status -eq "success") {
                    Write-Host " CI checks passed! ($elapsedStr elapsed)" -ForegroundColor Green

                    if ($result.merged) {
                        Write-Host "   PR #$PrNumber automatically merged at $($result.mergedAt)" -ForegroundColor Green
                    }
                    else {
                        Write-Host "   PR #$PrNumber ready to merge" -ForegroundColor Green
                    }
                }
                elseif ($result.status -eq "merged") {
                    Write-Host " PR #$PrNumber merged at $($result.mergedAt)" -ForegroundColor Green
                }
                elseif ($result.status -eq "failure") {
                    Write-Host " CI checks failed ($elapsedStr elapsed)" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "Failed checks:" -ForegroundColor Red
                    foreach ($check in $result.checks | Where-Object { $_.status -eq "failure" }) {
                        Write-Host "    $($check.name)" -ForegroundColor Red
                    }
                }
                elseif ($result.status -eq "error") {
                    Write-Host " CI checks encountered errors ($elapsedStr elapsed)" -ForegroundColor Red
                }

                Write-Host "" -ForegroundColor Gray
            }

            # Exit with appropriate code
            exit $(if ($result.status -in @("success", "merged")) { 0 } else { 1 })
        }

        # Check timeout
        if ((Get-Date) -gt $timeoutTime) {
            if ($Json) {
                @{
                    status   = "timeout"
                    prNumber = $PrNumber
                    checks   = $result.checks
                    error    = "Timeout after $timeoutMinutes minutes"
                } | ConvertTo-Json -Depth 10
            }
            else {
                Write-Host " Timeout: CI checks still pending after $timeoutMinutes minutes" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Current status:" -ForegroundColor Yellow
                foreach ($check in $result.checks) {
                    $emoji = Format-CheckStatus -Status $check.status
                    Write-Host "   $emoji $($check.name)" -ForegroundColor Gray
                }
                Write-Host ""
                Write-Host "Continue waiting manually or check PR: gh pr view $PrNumber" -ForegroundColor Yellow
            }
            exit 2
        }

        # Wait before next poll
        Start-Sleep -Seconds $PollInterval
    }
}

# Run main function
Wait-ForCI



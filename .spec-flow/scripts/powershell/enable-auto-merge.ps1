#Requires -Version 5.1
<#
.SYNOPSIS
    Enable auto-merge on a GitHub pull request.

.DESCRIPTION
    Uses GitHub CLI to enable auto-merge on a pull request with Specified merge method.
    Validates that PR exists, is open, and has required branch protection configured.

    Auto-merge automatically merges the PR when all required checks pass, eliminating
    the need for manual merge step.

.PARAMETER PrNumber
    The pull request number to enable auto-merge on.

.PARAMETER MergeMethod
    The merge method to use when auto-merging (default: squash).
    Options: merge, squash, rebase

.PARAMETER Json
    Output results as JSON for machine parsing.

.EXAMPLE
    .\enable-auto-merge.ps1 -PrNumber 123

    Enable auto-merge on PR #123 with squash merge method.

.EXAMPLE
    .\enable-auto-merge.ps1 -PrNumber 123 -MergeMethod merge

    Enable auto-merge on PR #123 with regular merge commit.

.EXAMPLE
    .\enable-auto-merge.ps1 -PrNumber 123 -Json

    Enable auto-merge and output JSON result for machine parsing.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Pull request number")]
    [int]$PrNumber,

    [Parameter(Mandatory = $false, HelpMessage = "Merge method (merge, squash, rebase)")]
    [ValidateSet("merge", "squash", "rebase")]
    [string]$MergeMethod = "squash",

    [Parameter(Mandatory = $false, HelpMessage = "Output JSON for machine parsing")]
    [switch]$Json
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

# Get PR details
function Get-PRDetails {
    param([int]$PrNumber)

    try {
        $prJson = gh pr view $PrNumber --json number, state, title, baseRefName, headRefName, autoMergeRequest 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "PR #$PrNumber not found"
        }

        return $prJson | ConvertFrom-Json

    }
    catch {
        Write-Error "Error fetching PR #${PrNumber}: $_"
        return $null
    }
}

# Check if branch protection is configured
function Test-BranchProtection {
    param([string]$Branch)

    try {
        # Try to get branch protection rules
        $protection = gh api "repos/:owner/:repo/branches/$Branch/protection" 2>$null | ConvertFrom-Json

        if ($null -eq $protection) {
            return $false
        }

        # Check if required status checks are configured
        if ($protection.required_status_checks -and $protection.required_status_checks.contexts.Count -gt 0) {
            return $true
        }

        # Check if required reviews are configured
        if ($protection.required_pull_request_reviews) {
            return $true
        }

        # Has some protection, but no required checks
        return $false

    }
    catch {
        # No branch protection configured
        return $false
    }
}

# Enable auto-merge on PR
function Enable-AutoMerge {
    param(
        [int]$PrNumber,
        [string]$MergeMethod
    )

    try {
        # Use GitHub GraphQL API to enable auto-merge
        # GitHub CLI doesn't have a direct command for this, so we use GraphQL

        # First, get PR node ID
        $prJson = gh pr view $PrNumber --json id 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get PR ID"
        }

        $pr = $prJson | ConvertFrom-Json
        $prNodeId = $pr.id

        # Map merge method to GraphQL enum
        $mergeMethodEnum = switch ($MergeMethod) {
            "merge" { "MERGE" }
            "squash" { "SQUASH" }
            "rebase" { "REBASE" }
        }

        # GraphQL mutation to enable auto-merge
        $mutation = @{
            query     = "mutation(`$pullRequestId: ID!, `$mergeMethod: PullRequestMergeMethod!) { enablePullRequestAutoMerge(input: {pullRequestId: `$pullRequestId, mergeMethod: `$mergeMethod}) { pullRequest { autoMergeRequest { enabledAt enabledBy { login } mergeMethod } } } }"
            variables = @{
                pullRequestId = $prNodeId
                mergeMethod   = $mergeMethodEnum
            }
        } | ConvertTo-Json -Depth 10 -Compress

        # Execute mutation
        $result = gh api graphql -f query="$mutation" 2>$null | ConvertFrom-Json

        if ($null -eq $result) {
            throw "GraphQL mutation returned null"
        }

        if ($result.errors) {
            $errorMsg = ($result.errors | ForEach-Object { $_.message }) -join ", "
            throw "GraphQL error: $errorMsg"
        }

        # Success
        return @{
            success     = $true
            enabledAt   = $result.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.enabledAt
            enabledBy   = $result.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.enabledBy.login
            mergeMethod = $result.data.enablePullRequestAutoMerge.pullRequest.autoMergeRequest.mergeMethod
        }

    }
    catch {
        Write-Error "Error enabling auto-merge: $_"
        return @{
            success = $false
            error   = $_.Exception.Message
        }
    }
}

# Main execution
function Main {
    # Validate prerequisites
    if (-not (Test-GitHubCLI)) {
        exit 1
    }

    # Get PR details
    $pr = Get-PRDetails -PrNumber $PrNumber
    if ($null -eq $pr) {
        if ($Json) {
            @{
                success  = $false
                error    = "PR #$PrNumber not found"
                prNumber = $PrNumber
            } | ConvertTo-Json
        }
        exit 1
    }

    # Check if PR is open
    if ($pr.state -ne "OPEN") {
        $errorMsg = "PR #$PrNumber is not open (state: $($pr.state))"
        if ($Json) {
            @{
                success  = $false
                error    = $errorMsg
                prNumber = $PrNumber
                prState  = $pr.state
            } | ConvertTo-Json
        }
        else {
            Write-Error $errorMsg
        }
        exit 1
    }

    # Check if auto-merge is already enabled
    if ($pr.autoMergeRequest) {
        $message = "Auto-merge already enabled on PR #$PrNumber (method: $($pr.autoMergeRequest.mergeMethod))"
        if ($Json) {
            @{
                success        = $true
                alreadyEnabled = $true
                message        = $message
                prNumber       = $PrNumber
                mergeMethod    = $pr.autoMergeRequest.mergeMethod
            } | ConvertTo-Json
        }
        else {
            Write-Host " $message" -ForegroundColor Green
        }
        exit 0
    }

    # Check branch protection
    $hasProtection = Test-BranchProtection -Branch $pr.baseRefName
    if (-not $hasProtection) {
        $errorMsg = "Branch protection not configured on '$($pr.baseRefName)'. Auto-merge requires branch protection with required status checks."
        if ($Json) {
            @{
                success    = $false
                error      = $errorMsg
                prNumber   = $PrNumber
                baseBranch = $pr.baseRefName
                suggestion = "Configure branch protection: Settings > Branches > Add rule for '$($pr.baseRefName)'"
            } | ConvertTo-Json
        }
        else {
            Write-Warning $errorMsg
            Write-Host ""
            Write-Host "To configure branch protection:" -ForegroundColor Yellow
            Write-Host "  1. Go to: Settings > Branches" -ForegroundColor Yellow
            Write-Host "  2. Add protection rule for '$($pr.baseRefName)'" -ForegroundColor Yellow
            Write-Host "  3. Enable 'Require status checks to pass before merging'" -ForegroundColor Yellow
            Write-Host "  4. Select required checks (ci, deploy, smoke-tests, etc.)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Continuing without auto-merge (manual merge required)..." -ForegroundColor Yellow
        }
        exit 2
    }

    # Enable auto-merge
    if (-not $Json) {
        Write-Host "  Enabling auto-merge on PR #$PrNumber..." -ForegroundColor Cyan
        Write-Host "   Method: $MergeMethod" -ForegroundColor Gray
        Write-Host "   Base: $($pr.baseRefName)" -ForegroundColor Gray
        Write-Host "   Head: $($pr.headRefName)" -ForegroundColor Gray
        Write-Host ""
    }

    $result = Enable-AutoMerge -PrNumber $PrNumber -MergeMethod $MergeMethod

    if ($result.success) {
        if ($Json) {
            @{
                success     = $true
                prNumber    = $PrNumber
                mergeMethod = $result.mergeMethod
                enabledAt   = $result.enabledAt
                enabledBy   = $result.enabledBy
                message     = "Auto-merge enabled successfully"
            } | ConvertTo-Json
        }
        else {
            Write-Host " Auto-merge enabled successfully!" -ForegroundColor Green
            Write-Host "   PR #$PrNumber will automatically merge when all checks pass" -ForegroundColor Green
            Write-Host "   Merge method: $($result.mergeMethod)" -ForegroundColor Gray
            Write-Host "   Enabled by: $($result.enabledBy) at $($result.enabledAt)" -ForegroundColor Gray
        }
        exit 0
    }
    else {
        if ($Json) {
            @{
                success  = $false
                prNumber = $PrNumber
                error    = $result.error
            } | ConvertTo-Json
        }
        else {
            Write-Error "Failed to enable auto-merge: $($result.error)"
        }
        exit 1
    }
}

# Run main function
Main



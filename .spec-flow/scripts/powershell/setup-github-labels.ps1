<#
.SYNOPSIS
    Create GitHub labels for roadmap management

.DESCRIPTION
    Creates a comprehensive label schema for managing features.
    Supports both gh CLI and GitHub API authentication.

.PARAMETER DryRun
    Show what labels would be created without actually creating them

.EXAMPLE
    .\setup-github-labels.ps1

.EXAMPLE
    .\setup-github-labels.ps1 -DryRun

.NOTES
    Version: 1.0.0
    Requires: gh CLI authenticated OR $env:GITHUB_TOKEN set
#>

param(
    [switch]$DryRun
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Helper function for colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    Write-Host $Message -ForegroundColor $Color
}

# Check DryRun mode
if ($DryRun) {
    Write-ColorOutput "DRY RUN MODE - No labels will be created" -Color Yellow
    Write-Host ""
}

# Check authentication
$UseGhCli = $false
try {
    $null = gh auth status 2>&1
    Write-ColorOutput "✓ GitHub CLI authenticated" -Color Green
    $UseGhCli = $true
}
catch {
    if ($env:GITHUB_TOKEN) {
        Write-ColorOutput "✓ GITHUB_TOKEN found" -Color Green
        $UseGhCli = $false
    }
    else {
        Write-ColorOutput "✗ No GitHub authentication found" -Color Red
        Write-Host ""
        Write-Host "Please authenticate with GitHub:"
        Write-Host "  Option 1: gh auth login"
        Write-Host "  Option 2: `$env:GITHUB_TOKEN = 'your_token'"
        exit 1
    }
}

# Get repository info
$Repo = ""
if ($UseGhCli) {
    try {
        $Repo = (gh repo view --json nameWithOwner -q .nameWithOwner 2>&1)

        if ([string]::IsNullOrEmpty($Repo)) {
            Write-ColorOutput "✗ Not in a GitHub repository or no remote configured" -Color Red
            Write-Host ""
            Write-Host "Please run this script from a repository with a GitHub remote"
            exit 1
        }

        Write-ColorOutput "✓ Repository: $Repo" -Color Green
    }
    catch {
        Write-ColorOutput "✗ Failed to get repository info" -Color Red
        exit 1
    }
}
else {
    # Extract repo from git remote URL
    try {
        $RemoteUrl = git config --get remote.origin.url 2>&1

        if ([string]::IsNullOrEmpty($RemoteUrl)) {
            Write-ColorOutput "✗ No git remote found" -Color Red
            exit 1
        }

        # Parse owner/repo from URL
        if ($RemoteUrl -match 'github\.com[:/](.+?)(\.git)?$') {
            $Repo = $Matches[1] -replace '\.git$', ''
            Write-ColorOutput "✓ Repository: $Repo" -Color Green
        }
        else {
            Write-ColorOutput "✗ Could not parse repository from remote URL" -Color Red
            exit 1
        }
    }
    catch {
        Write-ColorOutput "✗ Failed to get git remote" -Color Red
        exit 1
    }
}

Write-Host ""

# Function to create a label
function New-GitHubLabel {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Color,
        [string]$Repository,
        [bool]$UseCli,
        [bool]$IsDryRun
    )

    if ($IsDryRun) {
        Write-ColorOutput "[DRY RUN] Would create: $Name ($Color) - $Description" -Color Blue
        return $true
    }

    if ($UseCli) {
        # Use gh CLI
        try {
            $null = gh label create $Name --description $Description --color $Color --repo $Repository 2>&1
            Write-ColorOutput "✓ Created: $Name" -Color Green
            return $true
        }
        catch {
            # Try to update existing label
            try {
                $null = gh label edit $Name --description $Description --color $Color --repo $Repository 2>&1
                Write-ColorOutput "↻ Updated: $Name" -Color Yellow
                return $true
            }
            catch {
                Write-ColorOutput "✗ Failed: $Name" -Color Red
                return $false
            }
        }
    }
    else {
        # Use GitHub API
        $ApiUrl = "https://api.github.com/repos/$Repository/labels"
        $Headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $Body = @{
            name        = $Name
            description = $Description
            color       = $Color
        } | ConvertTo-Json

        try {
            # Try to create label
            $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Body -ErrorAction Stop
            Write-ColorOutput "✓ Created: $Name" -Color Green
            return $true
        }
        catch {
            # Try to update existing label
            try {
                $UpdateUrl = "$ApiUrl/$([System.Uri]::EscapeDataString($Name))"
                $UpdateBody = @{
                    description = $Description
                    color       = $Color
                } | ConvertTo-Json

                $Response = Invoke-RestMethod -Uri $UpdateUrl -Method Patch -Headers $Headers -Body $UpdateBody -ErrorAction Stop
                Write-ColorOutput "↻ Updated: $Name" -Color Yellow
                return $true
            }
            catch {
                Write-ColorOutput "✗ Failed: $Name" -Color Red
                return $false
            }
        }
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "Creating GitHub Labels"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

# Priority Labels (optional - for manual prioritization only)
Write-Host "Priority Labels (manual use):"
New-GitHubLabel -Name "priority:high" -Description "High priority - manual override" -Color "d73a4a" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "priority:medium" -Description "Medium priority - manual override" -Color "fb8c00" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "priority:low" -Description "Low priority - manual override" -Color "fef2c0" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Type Labels
Write-Host "Type Labels:"
New-GitHubLabel -Name "type:feature" -Description "New feature or functionality" -Color "1d76db" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "type:enhancement" -Description "Enhancement to existing feature" -Color "5319e7" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "type:bug" -Description "Bug or defect" -Color "d73a4a" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "type:task" -Description "Task or chore" -Color "0e8a16" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Area Labels
Write-Host "Area Labels:"
New-GitHubLabel -Name "area:backend" -Description "Backend/API code" -Color "0e8a16" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "area:frontend" -Description "Frontend/UI code" -Color "1d76db" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "area:api" -Description "API endpoints and contracts" -Color "006b75" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "area:infra" -Description "Infrastructure and DevOps" -Color "5319e7" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "area:design" -Description "Design and UX" -Color "e99695" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "area:marketing" -Description "Marketing pages and content" -Color "fbca04" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Role Labels
Write-Host "Role Labels:"
New-GitHubLabel -Name "role:all" -Description "All users" -Color "fb8c00" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "role:free" -Description "Free tier users" -Color "fef2c0" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "role:student" -Description "Student users" -Color "fbca04" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "role:cfi" -Description "CFI (instructor) users" -Color "d4c5f9" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "role:school" -Description "School/organization users" -Color "c2e0c6" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Status Labels
Write-Host "Status Labels:"
New-GitHubLabel -Name "status:backlog" -Description "Backlog - not yet prioritized" -Color "ededed" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "status:next" -Description "Next - queued for implementation" -Color "c2e0c6" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "status:later" -Description "Later - future consideration" -Color "fef2c0" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "status:in-progress" -Description "In Progress - actively being worked on" -Color "1d76db" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "status:shipped" -Description "Shipped - deployed to production" -Color "0e8a16" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "status:blocked" -Description "Blocked - waiting on dependency" -Color "d73a4a" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Size Labels
Write-Host "Size Labels:"
New-GitHubLabel -Name "size:small" -Description "Small - < 1 day" -Color "c2e0c6" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "size:medium" -Description "Medium - 1-2 weeks" -Color "fbca04" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "size:large" -Description "Large - 2-4 weeks" -Color "fb8c00" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "size:xl" -Description "Extra Large - 4+ weeks (consider splitting)" -Color "d73a4a" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

# Special Labels
Write-Host "Special Labels:"
New-GitHubLabel -Name "blocked" -Description "Blocked by dependency or external factor" -Color "d73a4a" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "good-first-issue" -Description "Good for newcomers" -Color "7057ff" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "help-wanted" -Description "Extra attention needed" -Color "008672" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "wont-fix" -Description "Will not be implemented" -Color "ffffff" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "duplicate" -Description "Duplicate of another issue" -Color "cfd3d7" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
New-GitHubLabel -Name "needs-clarification" -Description "Needs more information or clarification" -Color "d876e3" -Repository $Repo -UseCli $UseGhCli -IsDryRun $DryRun
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ($DryRun) {
    Write-ColorOutput "DRY RUN COMPLETE" -Color Yellow
    Write-Host ""
    Write-Host "Run without -DryRun to create labels"
}
else {
    Write-ColorOutput "LABELS CREATED SUCCESSFULLY" -Color Green
    Write-Host ""
    Write-Host "You can now:"
    Write-Host "  1. View labels: gh label list --repo $Repo"
    Write-Host "  2. Create issues with these labels"
    Write-Host "  3. Run migration script to import existing roadmap"
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


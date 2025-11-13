<#
.SYNOPSIS
    GitHub Issues roadmap management functions

.DESCRIPTION
    Provides functions to manage roadmap via GitHub Issues.
    Supports both gh CLI and GitHub API authentication.

.NOTES
    Version: 2.0.0
    Requires: gh CLI OR $env:GITHUB_TOKEN
#>

# ============================================================================
# AUTHENTICATION & CONFIGURATION
# ============================================================================

function Test-GitHubAuth {
    <#
    .SYNOPSIS
        Check if GitHub authentication is available
    .OUTPUTS
        String - "gh_cli", "api", or "none"
    #>

    try {
        $null = gh auth status 2>&1
        return "gh_cli"
    }
    catch {
        if ($env:GITHUB_TOKEN) {
            return "api"
        }
        return "none"
    }
}

function Get-RepositoryInfo {
    <#
    .SYNOPSIS
        Get repository owner/name
    .OUTPUTS
        String - "owner/repo" or empty string
    #>

    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        try {
            return (gh repo view --json nameWithOwner -q .nameWithOwner 2>&1)
        }
        catch {
            return ""
        }
    }
    elseif ($authMethod -eq "api") {
        try {
            $remoteUrl = git config --get remote.origin.url 2>&1

            if ($remoteUrl -match 'github\.com[:/](.+?)(\.git)?$') {
                return $Matches[1] -replace '\.git$', ''
            }

            return ""
        }
        catch {
            return ""
        }
    }

    return ""
}

# ============================================================================
# METADATA FUNCTIONS
# ============================================================================

function Get-MetadataFromBody {
    <#
    .SYNOPSIS
        Parse metadata frontmatter from issue body
    .PARAMETER Body
        Issue body text
    .OUTPUTS
        PSCustomObject - Metadata
    #>
    param(
        [string]$Body
    )

    # Extract YAML frontmatter between --- delimiters
    if ($Body -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $Matches[1]

        # Parse metadata values (NO ICE scores)
        $area = if ($frontmatter -match 'area:\s*(\w+)') { $Matches[1] } else { "app" }
        $role = if ($frontmatter -match 'role:\s*(\w+)') { $Matches[1] } else { "all" }
        $slug = if ($frontmatter -match 'slug:\s*(.+)') { $Matches[1].Trim() } else { "unknown" }

        return [PSCustomObject]@{
            Area = $area
            Role = $role
            Slug = $slug
        }
    }

    return [PSCustomObject]@{
        Area = "app"
        Role = "all"
        Slug = "unknown"
    }
}

function New-MetadataFrontmatter {
    <#
    .SYNOPSIS
        Generate metadata frontmatter for issue body
    #>
    param(
        [string]$Area = "app",
        [string]$Role = "all",
        [string]$Slug,
        [string]$Epic,
        [string]$Sprint
    )

    $metadata = @"
---
metadata:
  area: $Area
  role: $Role
  slug: $Slug
"@

    if ($Epic) {
        $metadata += "`n  epic: $Epic"
    }

    if ($Sprint) {
        $metadata += "`n  sprint: $Sprint"
    }

    $metadata += "`n---"
    return $metadata
}

# ============================================================================
# ISSUE OPERATIONS
# ============================================================================

function New-RoadmapIssue {
    <#
    .SYNOPSIS
        Create a roadmap issue with metadata frontmatter
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$Body,

        [string]$Area = "app",
        [string]$Role = "all",

        [Parameter(Mandatory=$true)]
        [string]$Slug,

        [string]$Labels = "type:feature,status:backlog",
        [string]$Epic,
        [string]$Sprint
    )

    $repo = Get-RepositoryInfo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    # Generate frontmatter (NO ICE scores)
    $frontmatter = New-MetadataFrontmatter -Area $Area -Role $Role -Slug $Slug -Epic $Epic -Sprint $Sprint

    # Combine frontmatter with body
    $fullBody = "$frontmatter`n`n$Body"

    # Build labels
    $allLabels = "$Labels,area:$Area,role:$Role"

    # Add epic and sprint labels if provided
    if ($Epic) {
        $allLabels += ",epic:$Epic"
    }

    if ($Sprint) {
        $allLabels += ",sprint:$Sprint"
    }

    # Create issue
    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        gh issue create `
            --repo $repo `
            --title $Title `
            --body $fullBody `
            --label $allLabels
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        }

        $labelArray = $allLabels -split ',' | ForEach-Object { $_.Trim() }

        $jsonBody = @{
            title = $Title
            body = $fullBody
            labels = $labelArray
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonBody
    }
    else {
        Write-Error "No GitHub authentication available"
    }
}

function Get-IssueBySlug {
    <#
    .SYNOPSIS
        Get issue by slug (searches in frontmatter)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Slug
    )

    $repo = Get-RepositoryInfo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        $result = gh issue list `
            --repo $repo `
            --search "slug: $Slug in:body" `
            --json number,title,body,state,labels `
            --limit 1 | ConvertFrom-Json

        return $result[0]
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/search/issues"
        $query = "repo:$repo slug: $Slug in:body"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        }

        $uri = "$apiUrl?q=$([System.Uri]::EscapeDataString($query))&per_page=1"
        $result = Invoke-RestMethod -Uri $uri -Headers $headers

        return $result.items[0]
    }
    else {
        Write-Error "No GitHub authentication available"
    }
}

function Set-IssueInProgress {
    <#
    .SYNOPSIS
        Mark issue as in progress
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Slug
    )

    $repo = Get-RepositoryInfo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    # Find issue
    $issue = Get-IssueBySlug -Slug $Slug

    if (-not $issue) {
        Write-Warning "Issue with slug '$Slug' not found in roadmap"
        return
    }

    $issueNumber = $issue.number
    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        gh issue edit $issueNumber `
            --repo $repo `
            --remove-label "status:backlog,status:next,status:later" `
            --add-label "status:in-progress"
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues/$issueNumber"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        }

        # Get current labels
        $currentIssue = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $newLabels = $currentIssue.labels | Where-Object { $_.name -notmatch '^status:' } | Select-Object -ExpandProperty name
        $newLabels += "status:in-progress"

        $jsonBody = @{ labels = $newLabels } | ConvertTo-Json
        Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body $jsonBody
    }

    Write-Host "✅ Marked issue #$issueNumber as In Progress in roadmap" -ForegroundColor Green
}

function Set-IssueShipped {
    <#
    .SYNOPSIS
        Mark issue as shipped
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Slug,

        [Parameter(Mandatory=$true)]
        [string]$Version,

        [string]$Date = (Get-Date -Format "yyyy-MM-dd"),

        [string]$ProductionUrl
    )

    $repo = Get-RepositoryInfo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    # Find issue
    $issue = Get-IssueBySlug -Slug $Slug

    if (-not $issue) {
        Write-Warning "Issue with slug '$Slug' not found in roadmap"
        return
    }

    $issueNumber = $issue.number
    $authMethod = Test-GitHubAuth

    # Prepare comment
    $comment = "🚀 **Shipped in v$Version**`n`n**Date**: $Date`n"
    if ($ProductionUrl) {
        $comment += "**Production URL**: $ProductionUrl`n"
    }

    if ($authMethod -eq "gh_cli") {
        # Update labels
        gh issue edit $issueNumber `
            --repo $repo `
            --remove-label "status:in-progress,status:next,status:backlog,status:later" `
            --add-label "status:shipped"

        # Add comment
        gh issue comment $issueNumber --repo $repo --body $comment

        # Close issue
        gh issue close $issueNumber --repo $repo --reason "completed"
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues/$issueNumber"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        }

        # Get current labels
        $currentIssue = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $newLabels = $currentIssue.labels | Where-Object { $_.name -notmatch '^status:' } | Select-Object -ExpandProperty name
        $newLabels += "status:shipped"

        # Update and close
        $jsonBody = @{
            state = "closed"
            labels = $newLabels
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body $jsonBody

        # Add comment
        $commentUrl = "$apiUrl/comments"
        $commentBody = @{ body = $comment } | ConvertTo-Json
        Invoke-RestMethod -Uri $commentUrl -Method Post -Headers $headers -Body $commentBody
    }

    Write-Host "✅ Marked issue #$issueNumber as Shipped (v$Version) in roadmap" -ForegroundColor Green
}

function Get-IssuesByStatus {
    <#
    .SYNOPSIS
        List issues by status label
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("backlog", "next", "later", "in-progress", "shipped")]
        [string]$Status
    )

    $repo = Get-RepositoryInfo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth
    $label = "status:$Status"

    if ($authMethod -eq "gh_cli") {
        gh issue list `
            --repo $repo `
            --label $label `
            --json number,title,body,labels,state `
            --limit 100 | ConvertFrom-Json
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept" = "application/vnd.github.v3+json"
        }

        $uri = "$apiUrl?labels=$label&per_page=100&state=all"
        Invoke-RestMethod -Uri $uri -Headers $headers
    }
}

function Add-DiscoveredFeature {
    <#
    .SYNOPSIS
        Suggest adding a discovered feature (create draft issue)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description,

        [string]$Context = "unknown"
    )

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "💡 Discovered Potential Feature" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Context: $Context" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Description:" -ForegroundColor White
    Write-Host "  $Description" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $response = Read-Host "Create GitHub issue for this feature? (yes/no/later)"

    switch ($response.ToLower()) {
        { $_ -in @("yes", "y") } {
            Write-Host ""
            Write-Host "Creating GitHub issue..." -ForegroundColor Cyan

            # Generate slug
            $slug = $Description -replace '[^a-z0-9-]', '-' -replace '--+', '-' |
                    Select-Object -First 1 | ForEach-Object { $_.Substring(0, [Math]::Min(30, $_.Length)) }

            # Create issue
            $title = $Description
            $body = "## Problem`n`nDiscovered during: $Context`n`n## Proposed Solution`n`nTo be determined`n`n## Requirements`n`n- [ ] To be defined"

            New-RoadmapIssue -Title $title -Body $body `
                -Area "app" -Role "all" -Slug $slug -Labels "type:feature,status:backlog,needs-clarification"

            Write-Host "✅ Created GitHub issue for: $Description" -ForegroundColor Green
        }
        { $_ -in @("later", "l") } {
            # Save to markdown
            $discoveredFile = ".spec-flow/memory/discovered-features.md"

            if (-not (Test-Path $discoveredFile)) {
                $dir = Split-Path $discoveredFile -Parent
                New-Item -ItemType Directory -Path $dir -Force | Out-Null

                @"
# Discovered Features

Features discovered during development. Review and create GitHub issues as needed.

---

"@ | Set-Content -Path $discoveredFile -Encoding UTF8
            }

            $entry = @"

## $(Get-Date -Format 'yyyy-MM-dd') - Discovered in: $Context

**Description**: $Description

**Action**: Create GitHub issue or run: ``/roadmap add "$Description"``

---

"@

            Add-Content -Path $discoveredFile -Value $entry -Encoding UTF8
            Write-Host "📝 Saved to discovered features. Review later in: $discoveredFile" -ForegroundColor Yellow
        }
        default {
            Write-Host "⏭️  Skipped" -ForegroundColor Gray
        }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Test-GitHubAuth',
    'Get-RepositoryInfo',
    'Get-MetadataFromBody',
    'New-MetadataFrontmatter',
    'New-RoadmapIssue',
    'Get-IssueBySlug',
    'Set-IssueInProgress',
    'Set-IssueShipped',
    'Get-IssuesByStatus',
    'Add-DiscoveredFeature'
)

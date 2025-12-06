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
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [string]$Area = "app",
        [string]$Role = "all",

        [Parameter(Mandatory = $true)]
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
            "Accept"        = "application/vnd.github.v3+json"
        }

        $labelArray = $allLabels -split ',' | ForEach-Object { $_.Trim() }

        $jsonBody = @{
            title  = $Title
            body   = $fullBody
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
        [Parameter(Mandatory = $true)]
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
            --json number, title, body, state, labels `
            --limit 1 | ConvertFrom-Json

        return $result[0]
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/search/issues"
        $query = "repo:$repo slug: $Slug in:body"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
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
        [Parameter(Mandatory = $true)]
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
            "Accept"        = "application/vnd.github.v3+json"
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
        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
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
            "Accept"        = "application/vnd.github.v3+json"
        }

        # Get current labels
        $currentIssue = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $newLabels = $currentIssue.labels | Where-Object { $_.name -notmatch '^status:' } | Select-Object -ExpandProperty name
        $newLabels += "status:shipped"

        # Update and close
        $jsonBody = @{
            state  = "closed"
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
        [Parameter(Mandatory = $true)]
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
            --json number, title, body, labels, state `
            --limit 100 | ConvertFrom-Json
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
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
        [Parameter(Mandatory = $true)]
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

# ============================================================================
# VISION ALIGNMENT VALIDATION
# ============================================================================

function Test-VisionAlignment {
    <#
    .SYNOPSIS
        Validate feature against project vision (docs/project/overview.md)
    .OUTPUTS
        String - "aligned", "misaligned", "skip", "revise", or "needs_override:<justification>"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDescription
    )

    $overviewFile = "docs/project/overview.md"

    # Check if overview.md exists
    if (-not (Test-Path $overviewFile)) {
        Write-Host "⚠️  No docs/project/overview.md found - skipping vision validation" -ForegroundColor Yellow
        Write-Host "   Run /init-project for vision-aligned roadmap" -ForegroundColor Gray
        return "aligned"
    }

    $overviewContent = Get-Content $overviewFile -Raw

    # Extract Out-of-Scope section
    $outOfScope = ""
    if ($overviewContent -match '(?ms)## Out.of.Scope(.+?)(?=^## |\z)') {
        $outOfScope = $Matches[1]
    }

    $validationResult = "aligned"
    $alignmentNotes = ""

    # Check against Out-of-Scope
    if ($outOfScope) {
        $oosLines = $outOfScope -split "`n" | Where-Object { $_ -match '^\s*[-*]\s+' }
        $featureLower = $FeatureDescription.ToLower()

        foreach ($line in $oosLines) {
            $oosItem = ($line -replace '^\s*[-*]\s+', '').ToLower().Trim()
            if ($oosItem -and $featureLower -match [regex]::Escape($oosItem)) {
                $validationResult = "misaligned"
                $alignmentNotes = "Potential conflict with Out-of-Scope: '$oosItem'"
                break
            }
        }
    }

    # Output validation result
    if ($validationResult -eq "misaligned") {
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host "⚠️  VISION ALIGNMENT WARNING" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Feature: $FeatureDescription" -ForegroundColor White
        Write-Host ""
        Write-Host "Issue: $alignmentNotes" -ForegroundColor Red
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""

        $overrideChoice = Read-Host "Override and add anyway? (yes/revise/skip)"

        switch ($overrideChoice.ToLower()) {
            { $_ -in @("yes", "y") } {
                $justification = Read-Host "Enter justification for override"
                return "needs_override:$justification"
            }
            { $_ -in @("revise", "r") } {
                return "revise"
            }
            default {
                return "skip"
            }
        }
    }

    return "aligned"
}

# ============================================================================
# BRAINSTORM FEATURES
# ============================================================================

function Invoke-BrainstormFeatures {
    <#
    .SYNOPSIS
        Process brainstormed feature ideas (called after Claude performs WebSearch)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Topic,

        [string]$IdeasJson
    )

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "💡 BRAINSTORM: $Topic" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # If no ideas JSON provided, prompt Claude to do web search
    if ([string]::IsNullOrEmpty($IdeasJson) -or $IdeasJson -eq "[]") {
        Write-Host "BRAINSTORM_SEARCH_NEEDED" -ForegroundColor Yellow
        Write-Host "topic: $Topic"
        Write-Host ""
        Write-Host "Claude should perform:"
        Write-Host "  1. WebSearch: `"$Topic best practices 2025`""
        Write-Host "  2. WebSearch: `"$Topic user pain points`""
        Write-Host "  3. Extract feature ideas from results"
        Write-Host "  4. Call Invoke-BrainstormFeatures with ideas JSON"
        return
    }

    $ideas = $IdeasJson | ConvertFrom-Json
    $ideaCount = $ideas.Count

    if ($ideaCount -eq 0) {
        Write-Host "No ideas provided for brainstorming" -ForegroundColor Yellow
        return
    }

    Write-Host "Found $ideaCount feature ideas to evaluate:" -ForegroundColor White
    Write-Host ""

    # Validate each idea against vision
    $validatedIdeas = @()

    for ($idx = 0; $idx -lt $ideaCount; $idx++) {
        $idea = $ideas[$idx]
        $title = $idea.title

        Write-Host "[$($idx + 1)/$ideaCount] $title" -ForegroundColor White

        # Run vision validation
        if (Test-Path "docs/project/overview.md") {
            $overviewContent = Get-Content "docs/project/overview.md" -Raw
            $outOfScope = ""
            if ($overviewContent -match '(?ms)## Out.of.Scope(.+?)(?=^## |\z)') {
                $outOfScope = $Matches[1]
            }

            $isAligned = $true
            $titleLower = $title.ToLower()

            $oosLines = $outOfScope -split "`n" | Where-Object { $_ -match '^\s*[-*]\s+' }
            foreach ($line in $oosLines) {
                $oosItem = ($line -replace '^\s*[-*]\s+', '').ToLower().Trim()
                if ($oosItem -and $titleLower -match [regex]::Escape($oosItem)) {
                    $isAligned = $false
                    Write-Host "   ⚠️  Potential conflict with Out-of-Scope" -ForegroundColor Yellow
                    break
                }
            }

            if ($isAligned) {
                Write-Host "   ✅ Aligned with project vision" -ForegroundColor Green
                $validatedIdeas += $idx
            }
        }
        else {
            Write-Host "   ℹ️  No vision file - skipping validation" -ForegroundColor Gray
            $validatedIdeas += $idx
        }
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Validated $($validatedIdeas.Count) of $ideaCount ideas" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Output validated ideas
    Write-Host "VALIDATED_IDEAS_FOR_SELECTION"
    $output = @()
    foreach ($vidx in $validatedIdeas) {
        $idea = $ideas[$vidx]
        $output += [PSCustomObject]@{
            index       = $vidx
            title       = $idea.title
            description = if ($idea.description) { $idea.description } else { "" }
        }
    }
    $output | ConvertTo-Json
}

function New-BrainstormedIssues {
    <#
    .SYNOPSIS
        Create issues for selected brainstormed ideas
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$IdeasJson,

        [Parameter(Mandatory = $true)]
        [string]$SelectedIndices  # Comma-separated: "0,2,4"
    )

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $ideas = $IdeasJson | ConvertFrom-Json

    Write-Host ""
    Write-Host "Creating GitHub issues for selected ideas..." -ForegroundColor Cyan
    Write-Host ""

    $createdCount = 0
    $indices = $SelectedIndices -split ',' | ForEach-Object { [int]$_.Trim() }

    foreach ($idx in $indices) {
        $idea = $ideas[$idx]
        $title = $idea.title
        $description = if ($idea.description) { $idea.description } else { "" }

        # Generate slug
        $slug = ($title -replace '[^a-z0-9-]', '-' -replace '--+', '-').ToLower()
        if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40) }

        # Create issue body
        $body = @"
## Problem

Discovered during brainstorming session.

## Description

$description

## Proposed Solution

To be determined during specification phase.

## Requirements

- [ ] To be defined

---
*Created via /roadmap brainstorm*
"@

        # Create the issue
        New-RoadmapIssue -Title $title -Body $body -Area "app" -Role "all" -Slug $slug -Labels "type:feature,status:backlog,brainstorm"

        $createdCount++
        Write-Host "  ✅ Created: $title" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Created $createdCount issues from brainstorm" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

# ============================================================================
# ROADMAP MANAGEMENT FUNCTIONS
# ============================================================================

function Move-IssueToStatus {
    <#
    .SYNOPSIS
        Move issue to different status section
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [ValidateSet("backlog", "next", "later", "in-progress", "blocked", "shipped")]
        [string]$TargetStatus
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
        # Get current labels
        $currentLabels = gh issue view $issueNumber --repo $repo --json labels --jq '.labels[].name' 2>&1

        # Remove ALL status:* labels
        $labelsToRemove = ($currentLabels | Where-Object { $_ -match '^status:' }) -join ','

        if ($labelsToRemove) {
            gh issue edit $issueNumber --repo $repo --remove-label $labelsToRemove 2>&1 | Out-Null
        }

        # Add new status label
        gh issue edit $issueNumber --repo $repo --add-label "status:$TargetStatus" 2>&1 | Out-Null

        # If moving to in-progress, check milestone
        if ($TargetStatus -eq "in-progress") {
            $milestone = gh issue view $issueNumber --repo $repo --json milestone --jq '.milestone.title // empty' 2>&1

            if ([string]::IsNullOrEmpty($milestone)) {
                Write-Host ""
                Write-Host "⚠️  Issue #$issueNumber has no milestone assigned" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Available milestones:" -ForegroundColor White
                Get-Milestones
                Write-Host ""

                $milestoneName = Read-Host "Assign milestone (leave blank to skip)"
                if ($milestoneName) {
                    gh issue edit $issueNumber --repo $repo --milestone $milestoneName
                    Write-Host "✅ Assigned milestone: $milestoneName" -ForegroundColor Green
                }
            }
        }

        # If moving to shipped, close the issue
        if ($TargetStatus -eq "shipped") {
            gh issue close $issueNumber --repo $repo --reason "completed" 2>&1 | Out-Null
        }
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues/$issueNumber"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        # Get current labels
        $currentIssue = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $newLabels = $currentIssue.labels | Where-Object { $_.name -notmatch '^status:' } | Select-Object -ExpandProperty name
        $newLabels += "status:$TargetStatus"

        $jsonBody = if ($TargetStatus -eq "shipped") {
            @{ state = "closed"; labels = $newLabels } | ConvertTo-Json
        }
        else {
            @{ labels = $newLabels } | ConvertTo-Json
        }

        Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body $jsonBody | Out-Null
    }

    Write-Host "✅ Moved issue #$issueNumber ($Slug) to status:$TargetStatus" -ForegroundColor Green
}

function Search-Roadmap {
    <#
    .SYNOPSIS
        Search roadmap issues by keyword, label, or milestone
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    # Parse filter syntax
    $labelFilters = @()
    $milestoneFilter = ""
    $keywordQuery = ""

    $Query -split '\s+' | ForEach-Object {
        if ($_ -match '^label:(.+)$') {
            $labelFilters += $Matches[1]
        }
        elseif ($_ -match '^milestone:(.+)$') {
            $milestoneFilter = $Matches[1]
        }
        else {
            $keywordQuery += " $_"
        }
    }
    $keywordQuery = $keywordQuery.Trim()

    if ($authMethod -eq "gh_cli") {
        $searchQuery = "repo:$repo"
        if ($keywordQuery) { $searchQuery += " $keywordQuery" }
        if ($milestoneFilter) { $searchQuery += " milestone:`"$milestoneFilter`"" }

        $ghCmd = "gh issue list --repo $repo --search `"$searchQuery`""
        foreach ($label in $labelFilters) {
            $ghCmd += " --label `"$label`""
        }
        $ghCmd += " --json number,title,labels,milestone,state --limit 50"

        Invoke-Expression $ghCmd | ConvertFrom-Json
    }
    elseif ($authMethod -eq "api") {
        $apiSearchUrl = "https://api.github.com/search/issues"
        $searchTerms = "repo:$repo"
        if ($keywordQuery) { $searchTerms += " $keywordQuery" }
        foreach ($label in $labelFilters) { $searchTerms += " label:$label" }
        if ($milestoneFilter) { $searchTerms += " milestone:`"$milestoneFilter`"" }

        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $uri = "$apiSearchUrl?q=$([System.Uri]::EscapeDataString($searchTerms))&per_page=50"
        $result = Invoke-RestMethod -Uri $uri -Headers $headers
        return $result.items
    }
}

function Get-RoadmapSummary {
    <#
    .SYNOPSIS
        Show roadmap summary with counts by status and milestone
    #>

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📊 ROADMAP SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    if ($authMethod -eq "gh_cli") {
        # Count by status
        Write-Host "By Status:" -ForegroundColor White

        $backlogCount = (gh issue list --repo $repo --label "status:backlog" --json number --jq 'length' 2>&1)
        $nextCount = (gh issue list --repo $repo --label "status:next" --json number --jq 'length' 2>&1)
        $laterCount = (gh issue list --repo $repo --label "status:later" --json number --jq 'length' 2>&1)
        $inProgressCount = (gh issue list --repo $repo --label "status:in-progress" --json number --jq 'length' 2>&1)
        $blockedCount = (gh issue list --repo $repo --label "status:blocked" --json number --jq 'length' 2>&1)
        $shippedCount = (gh issue list --repo $repo --label "status:shipped" --state closed --json number --jq 'length' 2>&1)

        Write-Host "  Backlog: $backlogCount"
        Write-Host "  Next: $nextCount"
        Write-Host "  Later: $laterCount"
        Write-Host "  In Progress: $inProgressCount"
        Write-Host "  Blocked: $blockedCount"
        Write-Host "  Shipped: $shippedCount"
        Write-Host ""

        # Count by milestone
        Write-Host "By Milestone:" -ForegroundColor White
        $milestones = gh api "repos/$repo/milestones?state=all&per_page=100" --jq '.[] | "\(.title)|\(.open_issues)|\(.closed_issues)"' 2>&1

        if ([string]::IsNullOrEmpty($milestones)) {
            Write-Host "  (No milestones defined)" -ForegroundColor Gray
        }
        else {
            $milestones -split "`n" | ForEach-Object {
                if ($_) {
                    $parts = $_ -split '\|'
                    $title = $parts[0]
                    $open = $parts[1]
                    $closed = $parts[2]
                    $total = [int]$open + [int]$closed
                    Write-Host "  $title`: $total issues ($open open, $closed closed)"
                }
            }
        }
        Write-Host ""

        # Show top 5 in Backlog
        Write-Host "Top 5 in Backlog (creation order priority):" -ForegroundColor White
        $topBacklog = gh issue list --repo $repo --label "status:backlog" --json number, title, createdAt --limit 5 --jq '.[] | "#\(.number) \(.title) (Created: \(.createdAt[0:10]))"' 2>&1

        if ([string]::IsNullOrEmpty($topBacklog)) {
            Write-Host "  (Empty)" -ForegroundColor Gray
        }
        else {
            $idx = 1
            $topBacklog -split "`n" | ForEach-Object {
                if ($_) {
                    Write-Host "  $idx. $_"
                    $idx++
                }
            }
        }
        Write-Host ""

        # Show issues in Next
        Write-Host "In Next (ready to start):" -ForegroundColor White
        $nextIssues = gh issue list --repo $repo --label "status:next" --json number, title --jq '.[] | "#\(.number) \(.title)"' 2>&1

        if ([string]::IsNullOrEmpty($nextIssues)) {
            Write-Host "  (Empty)" -ForegroundColor Gray
        }
        else {
            $idx = 1
            $nextIssues -split "`n" | ForEach-Object {
                if ($_) {
                    Write-Host "  $idx. $_"
                    $idx++
                }
            }
        }
        Write-Host ""

        # Show in progress
        Write-Host "In Progress:" -ForegroundColor White
        $inProgressIssues = gh issue list --repo $repo --label "status:in-progress" --json number, title, milestone --jq '.[] | "#\(.number) \(.title) [Milestone: \(.milestone.title // "None")]"' 2>&1

        if ([string]::IsNullOrEmpty($inProgressIssues)) {
            Write-Host "  (None)" -ForegroundColor Gray
        }
        else {
            $idx = 1
            $inProgressIssues -split "`n" | ForEach-Object {
                if ($_) {
                    Write-Host "  $idx. $_"
                    $idx++
                }
            }
        }
    }
    elseif ($authMethod -eq "api") {
        Write-Host "  (API summary limited - use gh CLI for full details)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Remove-RoadmapIssue {
    <#
    .SYNOPSIS
        Delete roadmap issue (close with wont-fix label)
    #>
    param(
        [Parameter(Mandatory = $true)]
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
    $issueTitle = $issue.title

    Write-Host ""
    Write-Host "⚠️  About to delete roadmap issue:" -ForegroundColor Yellow
    Write-Host "  #$issueNumber`: $issueTitle" -ForegroundColor White
    Write-Host ""

    $confirm = Read-Host "Are you sure? (yes/no)"

    if ($confirm.ToLower() -ne "yes") {
        Write-Host "❌ Cancelled" -ForegroundColor Red
        return
    }

    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        gh issue edit $issueNumber --repo $repo --add-label "wont-fix" 2>&1 | Out-Null
        gh issue close $issueNumber --repo $repo --reason "not planned" 2>&1 | Out-Null
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/issues/$issueNumber"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        # Get current labels and add wont-fix
        $currentIssue = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $newLabels = ($currentIssue.labels | Select-Object -ExpandProperty name) + "wont-fix"

        $jsonBody = @{
            state  = "closed"
            labels = $newLabels
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body $jsonBody | Out-Null
    }

    Write-Host "✅ Deleted issue #$issueNumber from roadmap (closed with wont-fix)" -ForegroundColor Green
}

# ============================================================================
# MILESTONE MANAGEMENT FUNCTIONS
# ============================================================================

function Get-Milestones {
    <#
    .SYNOPSIS
        List all milestones
    #>

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        gh api "repos/$repo/milestones?state=all&per_page=100" --jq '.[] | "  \(.title) - \(.open_issues) open, \(.closed_issues) closed (Due: \(.due_on // "No due date"))"' 2>&1
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/milestones?state=all&per_page=100"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $milestones = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $milestones | ForEach-Object {
            $dueOn = if ($_.due_on) { $_.due_on } else { "No due date" }
            Write-Host "  $($_.title) - $($_.open_issues) open, $($_.closed_issues) closed (Due: $dueOn)"
        }
    }
}

function New-Milestone {
    <#
    .SYNOPSIS
        Create a new milestone
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [string]$DueDate,  # YYYY-MM-DD format (optional)

        [string]$Description
    )

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    if ($authMethod -eq "gh_cli") {
        $ghCmd = "gh api repos/$repo/milestones -f title=`"$Title`""

        if ($DueDate) {
            $dueIso = "${DueDate}T23:59:59Z"
            $ghCmd += " -f due_on=`"$dueIso`""
        }

        if ($Description) {
            $ghCmd += " -f description=`"$Description`""
        }

        Invoke-Expression $ghCmd | Out-Null
        Write-Host "✅ Created milestone: $Title" -ForegroundColor Green
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/milestones"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $body = @{ title = $Title }
        if ($Description) { $body.description = $Description }
        if ($DueDate) { $body.due_on = "${DueDate}T23:59:59Z" }

        $jsonBody = $body | ConvertTo-Json
        Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonBody | Out-Null

        Write-Host "✅ Created milestone: $Title" -ForegroundColor Green
    }
}

function Set-MilestonePlan {
    <#
    .SYNOPSIS
        Plan milestone by assigning backlog issues to it
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$MilestoneName
    )

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    # Check if milestone exists
    if ($authMethod -eq "gh_cli") {
        $milestoneExists = gh api "repos/$repo/milestones" --jq ".[] | select(.title == `"$MilestoneName`") | .title" 2>&1
    }
    else {
        $apiUrl = "https://api.github.com/repos/$repo/milestones"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }
        $milestones = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $milestoneExists = ($milestones | Where-Object { $_.title -eq $MilestoneName }).title
    }

    if ([string]::IsNullOrEmpty($milestoneExists)) {
        Write-Host "❌ Milestone '$MilestoneName' does not exist" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available milestones:" -ForegroundColor White
        Get-Milestones
        return
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📋 MILESTONE PLANNING: $MilestoneName" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backlog issues (creation order = priority):" -ForegroundColor White
    Write-Host ""

    if ($authMethod -eq "gh_cli") {
        $backlogIssues = gh issue list --repo $repo --label "status:backlog" --json number, title, createdAt --limit 20 2>&1 | ConvertFrom-Json

        if (-not $backlogIssues -or $backlogIssues.Count -eq 0) {
            Write-Host "  (No backlog issues)" -ForegroundColor Gray
            return
        }

        $idx = 1
        $backlogIssues | ForEach-Object {
            Write-Host "$idx. #$($_.number) $($_.title) (Created: $($_.createdAt.Substring(0,10)))"
            $idx++
        }
        Write-Host ""

        # Interactive assignment
        Write-Host "Enter issue numbers to assign to '$MilestoneName' (space-separated, or 'done'):" -ForegroundColor Yellow
        $issueNumbers = Read-Host ">"

        if ($issueNumbers -eq "done" -or [string]::IsNullOrEmpty($issueNumbers)) {
            Write-Host "✅ Milestone planning complete" -ForegroundColor Green
            return
        }

        # Assign issues
        $issueNumbers -split '\s+' | ForEach-Object {
            $num = $_ -replace '#', ''
            if ($num) {
                gh issue edit $num --repo $repo --milestone $MilestoneName 2>&1 | Out-Null
                Write-Host "  ✅ Assigned #$num to $MilestoneName" -ForegroundColor Green
            }
        }

        Write-Host ""
        Write-Host "✅ Milestone planning complete" -ForegroundColor Green
    }
    else {
        Write-Host "  (API milestone planning not fully implemented - use gh CLI)" -ForegroundColor Gray
    }
}

# ============================================================================
# EPIC LABEL MANAGEMENT
# ============================================================================

function New-EpicLabel {
    <#
    .SYNOPSIS
        Create epic label dynamically
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$EpicName,

        [string]$Description,

        [string]$Color = "8B5CF6"  # Default: purple (epic color)
    )

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $labelName = "epic:$EpicName"
    $authMethod = Test-GitHubAuth

    # Check if label already exists
    if ($authMethod -eq "gh_cli") {
        $labelExists = gh label list --repo $repo --json name --jq ".[] | select(.name == `"$labelName`") | .name" 2>&1
    }
    else {
        $apiUrl = "https://api.github.com/repos/$repo/labels/$labelName"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }
        try {
            $labelExists = (Invoke-RestMethod -Uri $apiUrl -Headers $headers).name
        }
        catch {
            $labelExists = $null
        }
    }

    if ($labelExists) {
        Write-Host "ℹ️  Epic label '$labelName' already exists" -ForegroundColor Cyan
        return
    }

    # Create the label
    $labelDescription = if ($Description) { $Description } else { "Epic: $EpicName" }

    if ($authMethod -eq "gh_cli") {
        gh label create $labelName --repo $repo --color $Color --description $labelDescription 2>&1 | Out-Null
        Write-Host "✅ Created epic label: $labelName" -ForegroundColor Green
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/labels"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $jsonBody = @{
            name        = $labelName
            description = $labelDescription
            color       = $Color
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonBody | Out-Null
        Write-Host "✅ Created epic label: $labelName" -ForegroundColor Green
    }
}

function Get-EpicLabels {
    <#
    .SYNOPSIS
        List all epic labels
    #>

    $repo = Get-RepositoryInfo
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Error "Could not determine repository"
        return
    }

    $authMethod = Test-GitHubAuth

    Write-Host ""
    Write-Host "Epic Labels:" -ForegroundColor White
    Write-Host ""

    if ($authMethod -eq "gh_cli") {
        gh label list --repo $repo --json name, description --jq '.[] | select(.name | startswith("epic:")) | "  \(.name) - \(.description // "No description")"' 2>&1
    }
    elseif ($authMethod -eq "api") {
        $apiUrl = "https://api.github.com/repos/$repo/labels?per_page=100"
        $headers = @{
            "Authorization" = "token $env:GITHUB_TOKEN"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $labels = Invoke-RestMethod -Uri $apiUrl -Headers $headers
        $labels | Where-Object { $_.name -match '^epic:' } | ForEach-Object {
            $desc = if ($_.description) { $_.description } else { "No description" }
            Write-Host "  $($_.name) - $desc"
        }
    }

    Write-Host ""
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
    'Add-DiscoveredFeature',
    'Test-VisionAlignment',
    'Invoke-BrainstormFeatures',
    'New-BrainstormedIssues',
    'Move-IssueToStatus',
    'Search-Roadmap',
    'Get-RoadmapSummary',
    'Remove-RoadmapIssue',
    'Get-Milestones',
    'New-Milestone',
    'Set-MilestonePlan',
    'New-EpicLabel',
    'Get-EpicLabels'
)


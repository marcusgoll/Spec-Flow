<#
.SYNOPSIS
    Roadmap management functions for Spec-Flow

.DESCRIPTION
    Provides functions to manage roadmap status throughout the feature lifecycle:
    - Mark features as in-progress when starting
    - Mark features as shipped when deploying
    - Suggest adding discovered features
    - Query feature status in roadmap

.NOTES
    Version: 1.0.0
    Author: Spec-Flow Workflow Kit
#>

$RoadmapFile = ".spec-flow/memory/roadmap.md"

function Get-FeatureStatus {
    <#
    .SYNOPSIS
        Check if feature exists in roadmap and return its status

    .PARAMETER Slug
        Feature slug (e.g., "001-login")

    .EXAMPLE
        $status = Get-FeatureStatus -Slug "001-login"
        # Returns: shipped, in_progress, next, later, backlog, or not_found

    .OUTPUTS
        String - Feature status or "not_found"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    if (-not (Test-Path $RoadmapFile)) {
        return "not_found"
    }

    $content = Get-Content $RoadmapFile -Raw

    # Search for feature in different sections
    if ($content -match "### $Slug") {
        # Found the feature, determine which section
        $lines = Get-Content $RoadmapFile
        $featureLine = -1

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^### $Slug$") {
                $featureLine = $i
                break
            }
        }

        if ($featureLine -eq -1) {
            return "unknown"
        }

        # Find the section header above this line
        $sectionLine = -1
        for ($i = $featureLine; $i -ge 0; $i--) {
            if ($lines[$i] -match "^## (.+)$") {
                $section = $Matches[1].Trim()
                break
            }
        }

        if ([string]::IsNullOrEmpty($section)) {
            return "unknown"
        }

        # Map section to status
        switch ($section) {
            "Shipped" { return "shipped" }
            "In Progress" { return "in_progress" }
            "Next" { return "next" }
            "Later" { return "later" }
            "Backlog" { return "backlog" }
            default { return "unknown" }
        }
    }
    else {
        return "not_found"
    }
}

function Set-FeatureInProgress {
    <#
    .SYNOPSIS
        Mark feature as in progress (move from Backlog/Next to In Progress)

    .PARAMETER Slug
        Feature slug

    .EXAMPLE
        Set-FeatureInProgress -Slug "001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    if (-not (Test-Path $RoadmapFile)) {
        Write-Error "Roadmap not found: $RoadmapFile"
        return
    }

    $status = Get-FeatureStatus -Slug $Slug

    if ($status -eq "not_found") {
        Write-Warning "⚠️  Feature '$Slug' not found in roadmap"
        return
    }

    if ($status -eq "in_progress") {
        # Already in progress
        return
    }

    if ($status -eq "shipped") {
        Write-Warning "⚠️  Feature '$Slug' already shipped"
        return
    }

    # Extract the feature block
    $featureBlock = Get-FeatureBlock -Slug $Slug

    if ([string]::IsNullOrEmpty($featureBlock)) {
        Write-Error "Could not extract feature block for $Slug"
        return
    }

    # Remove from current location
    Remove-FeatureFromSection -Slug $Slug

    # Add to In Progress section
    Add-FeatureToSection -Section "In Progress" -FeatureBlock $featureBlock -Slug $Slug

    Write-Host "✅ Marked '$Slug' as In Progress in roadmap" -ForegroundColor Green
}

function Set-FeatureShipped {
    <#
    .SYNOPSIS
        Mark feature as shipped (move to Shipped section with metadata)

    .PARAMETER Slug
        Feature slug

    .PARAMETER Version
        Release version (e.g., "1.2.0")

    .PARAMETER Date
        Deployment date (default: today)

    .PARAMETER ProductionUrl
        Production URL (optional)

    .EXAMPLE
        Set-FeatureShipped -Slug "001-login" -Version "1.2.0"

    .EXAMPLE
        Set-FeatureShipped -Slug "001-login" -Version "1.2.0" -ProductionUrl "https://app.example.com"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [string]$Date = (Get-Date -Format "yyyy-MM-dd"),

        [Parameter(Mandatory = $false)]
        [string]$ProductionUrl
    )

    if (-not (Test-Path $RoadmapFile)) {
        Write-Error "Roadmap not found: $RoadmapFile"
        return
    }

    $status = Get-FeatureStatus -Slug $Slug

    if ($status -eq "not_found") {
        Write-Warning "⚠️  Feature '$Slug' not found in roadmap"
        return
    }

    if ($status -eq "shipped") {
        Write-Host "Feature already shipped, updating metadata..." -ForegroundColor Yellow
    }

    # Extract feature title and basic info
    $featureInfo = Get-FeatureBasicInfo -Slug $Slug

    # Remove from current location
    Remove-FeatureFromSection -Slug $Slug

    # Create shipped entry (without ICE scores)
    $shippedBlock = @"
### $Slug
$featureInfo
- **Date**: $Date
- **Release**: v$Version
"@

    if (-not [string]::IsNullOrEmpty($ProductionUrl)) {
        $shippedBlock += "`n- **URL**: $ProductionUrl"
    }

    # Add to Shipped section (at the top, newest first)
    Add-FeatureToSectionStart -Section "Shipped" -FeatureBlock $shippedBlock

    Write-Host "✅ Marked '$Slug' as Shipped (v$Version) in roadmap" -ForegroundColor Green
}

function Show-FeatureDiscovery {
    <#
    .SYNOPSIS
        Suggest adding a discovered feature to the roadmap

    .PARAMETER Description
        Feature description

    .PARAMETER Context
        Context where feature was discovered (default: "unknown")

    .EXAMPLE
        Show-FeatureDiscovery -Description "Add OAuth login" -Context "implement-phase"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
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

    $response = Read-Host "Add to roadmap? (yes/no/later)"

    switch ($response.ToLower()) {
        { $_ -in @("yes", "y") } {
            Write-Host ""
            Write-Host "Adding to roadmap using /roadmap command..." -ForegroundColor Cyan
            Write-Host ""
            Save-DiscoveredFeature -Description $Description -Context $Context
            Write-Host "💡 Tip: Run: /roadmap add `"$Description`"" -ForegroundColor Yellow
        }
        { $_ -in @("later", "l") } {
            Save-DiscoveredFeature -Description $Description -Context $Context
            Write-Host "📝 Saved to discovered features. Review later with:" -ForegroundColor Yellow
            Write-Host "   cat .spec-flow/memory/discovered-features.md" -ForegroundColor Cyan
        }
        default {
            Write-Host "⏭️  Skipped" -ForegroundColor Gray
        }
    }
}

function Save-DiscoveredFeature {
    <#
    .SYNOPSIS
        Save discovered feature for later review

    .PARAMETER Description
        Feature description

    .PARAMETER Context
        Context where feature was discovered

    .EXAMPLE
        Save-DiscoveredFeature -Description "Add OAuth login" -Context "implement-phase"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    $discoveredFile = ".spec-flow/memory/discovered-features.md"

    # Create file if doesn't exist
    if (-not (Test-Path $discoveredFile)) {
        $dir = Split-Path $discoveredFile -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $header = @"
# Discovered Features

Features discovered during development that could be added to the roadmap.

---

"@
        $header | Set-Content -Path $discoveredFile -Encoding UTF8
    }

    # Append discovered feature
    $date = Get-Date -Format "yyyy-MM-dd"
    $entry = @"

## $date - Discovered in: $Context

**Description**: $Description

**Action**: Review and add to roadmap with: ``/roadmap add "$Description"``

---

"@

    Add-Content -Path $discoveredFile -Value $entry -Encoding UTF8
    Write-Host "✅ Saved to: $discoveredFile" -ForegroundColor Green
}

# ============================================================================
# Helper Functions
# ============================================================================

function Get-FeatureBlock {
    <#
    .SYNOPSIS
        Extract full feature block from roadmap

    .PARAMETER Slug
        Feature slug

    .OUTPUTS
        String - Feature content block
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    $lines = Get-Content $RoadmapFile
    $startIndex = -1
    $endIndex = -1

    # Find feature header
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^### $Slug$") {
            $startIndex = $i + 1
            break
        }
    }

    if ($startIndex -eq -1) {
        return ""
    }

    # Find end of feature block (next ### or ##)
    for ($i = $startIndex; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^###|^##") {
            $endIndex = $i - 1
            break
        }
    }

    if ($endIndex -eq -1) {
        $endIndex = $lines.Count - 1
    }

    # Extract feature block
    $featureLines = $lines[$startIndex..$endIndex]
    return ($featureLines -join "`n").Trim()
}

function Get-FeatureBasicInfo {
    <#
    .SYNOPSIS
        Extract basic feature info (title, area, role)

    .PARAMETER Slug
        Feature slug

    .OUTPUTS
        String - Basic feature info
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    $featureBlock = Get-FeatureBlock -Slug $Slug
    if ([string]::IsNullOrEmpty($featureBlock)) {
        return ""
    }

    # Extract only title, area, role lines
    $basicInfo = $featureBlock -split "`n" | Where-Object {
        $_ -match "^- \*\*(Title|Area|Role):"
    }

    return ($basicInfo -join "`n")
}

function Remove-FeatureFromSection {
    <#
    .SYNOPSIS
        Remove feature from its current section

    .PARAMETER Slug
        Feature slug
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    $lines = Get-Content $RoadmapFile
    $newLines = @()
    $skipMode = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Start skipping when we find the feature header
        if ($line -match "^### $Slug$") {
            $skipMode = $true
            continue
        }

        # Stop skipping when we hit next feature or section
        if ($skipMode -and ($line -match "^###|^##")) {
            $skipMode = $false
        }

        # Add line if not in skip mode
        if (-not $skipMode) {
            $newLines += $line
        }
    }

    $newLines | Set-Content -Path $RoadmapFile -Encoding UTF8
}

function Add-FeatureToSection {
    <#
    .SYNOPSIS
        Add feature to a specific section (at the end)

    .PARAMETER Section
        Section name (e.g., "In Progress")

    .PARAMETER FeatureBlock
        Feature content block

    .PARAMETER Slug
        Feature slug
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$FeatureBlock,

        [Parameter(Mandatory = $true)]
        [string]$Slug
    )

    $lines = Get-Content $RoadmapFile
    $newLines = @()
    $sectionFound = $false
    $inserted = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Found our section
        if ($line -match "^## $Section$") {
            $sectionFound = $true
            $newLines += $line
            continue
        }

        # If in our section and hit next section, insert before it
        if ($sectionFound -and ($line -match "^##") -and -not $inserted) {
            $newLines += ""
            $newLines += "### $Slug"
            $newLines += $FeatureBlock
            $newLines += ""
            $inserted = $true
        }

        $newLines += $line
    }

    # If section was last, append feature
    if ($sectionFound -and -not $inserted) {
        $newLines += ""
        $newLines += "### $Slug"
        $newLines += $FeatureBlock
        $newLines += ""
    }

    $newLines | Set-Content -Path $RoadmapFile -Encoding UTF8
}

function Add-FeatureToSectionStart {
    <#
    .SYNOPSIS
        Insert feature at start of section (for Shipped - newest first)

    .PARAMETER Section
        Section name

    .PARAMETER FeatureBlock
        Feature content block (including ### header)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$FeatureBlock
    )

    $lines = Get-Content $RoadmapFile
    $newLines = @()
    $inserted = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        $newLines += $line

        # Found our section, insert feature right after
        if (($line -match "^## $Section$") -and -not $inserted) {
            $newLines += ""
            $newLines += $FeatureBlock
            $newLines += ""
            $inserted = $true
        }
    }

    $newLines | Set-Content -Path $RoadmapFile -Encoding UTF8
}

# Export functions
# NOTE: Export-ModuleMember only works in .psm1 modules, not .ps1 scripts
# Commented out to prevent errors when running as a script
# Export-ModuleMember -Function @(
#     'Get-FeatureStatus',
#     'Set-FeatureInProgress',
#     'Set-FeatureShipped',
#     'Show-FeatureDiscovery',
#     'Save-DiscoveredFeature'
# )


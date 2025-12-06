<#
.SYNOPSIS
    Semantic version management for Spec-Flow

.DESCRIPTION
    Provides functions to manage semantic versioning throughout the feature lifecycle:
    - Read current version from package.json
    - Suggest version bumps based on feature analysis
    - Update package.json with new version
    - Create git tags for releases
    - Generate release notes from ship reports

.NOTES
    Version: 1.0.0
    Author: Spec-Flow Workflow Kit
#>

$PackageJsonPath = "package.json"

function Get-CurrentVersion {
    <#
    .SYNOPSIS
        Get current version from package.json

    .EXAMPLE
        $version = Get-CurrentVersion
        # Returns: "1.2.3"

    .OUTPUTS
        String - Current version
    #>

    if (-not (Test-Path $PackageJsonPath)) {
        Write-Error "package.json not found"
        return $null
    }

    try {
        $packageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json

        if ([string]::IsNullOrEmpty($packageJson.version)) {
            Write-Error "version not found in package.json"
            return $null
        }

        return $packageJson.version
    }
    catch {
        Write-Error "Failed to read package.json: $($_.Exception.Message)"
        return $null
    }
}

function ConvertFrom-SemanticVersion {
    <#
    .SYNOPSIS
        Parse semantic version into MAJOR.MINOR.PATCH components

    .PARAMETER Version
        Version string (e.g., "1.2.3" or "v1.2.3")

    .EXAMPLE
        $parts = ConvertFrom-SemanticVersion -Version "1.2.3"
        # Returns: @{Major=1; Minor=2; Patch=3}

    .OUTPUTS
        Hashtable with Major, Minor, Patch properties
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    # Remove leading 'v' if present
    $Version = $Version -replace '^v', ''

    # Extract MAJOR.MINOR.PATCH
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)') {
        return @{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
        }
    }
    else {
        Write-Error "Invalid version format: $Version (expected: MAJOR.MINOR.PATCH)"
        return $null
    }
}

function Get-VersionBumpSuggestion {
    <#
    .SYNOPSIS
        Suggest version bump based on feature analysis

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        $bumpType = Get-VersionBumpSuggestion -FeatureDir "specs/001-login"
        # Returns: "major", "minor", or "patch"

    .OUTPUTS
        String - Suggested bump type
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    $specFile = Join-Path $FeatureDir "spec.md"

    if (-not (Test-Path $specFile)) {
        Write-Error "Spec not found: $specFile"
        return $null
    }

    $specContent = Get-Content $specFile -Raw

    # Check for breaking changes
    $hasBreaking = $false
    if ($specContent -match "breaking change") {
        $hasBreaking = $true
    }

    # Check ship report for breaking changes
    $shipReport = Get-ChildItem -Path $FeatureDir -Filter "*-ship-report.md" -File | Select-Object -First 1
    if ($shipReport) {
        $shipContent = Get-Content $shipReport.FullName -Raw
        if ($shipContent -match "breaking change") {
            $hasBreaking = $true
        }
    }

    # Check for bug fixes
    $isBugFix = $false
    if ($specContent -match "(fix|bug|patch|hotfix)") {
        $isBugFix = $true
    }

    # Determine bump type
    if ($hasBreaking) {
        return "major"
    }
    elseif ($isBugFix) {
        return "patch"
    }
    else {
        # Default to minor for new features
        return "minor"
    }
}

function New-BumpedVersion {
    <#
    .SYNOPSIS
        Calculate new version based on bump type

    .PARAMETER BumpType
        Type of version bump: major, minor, or patch

    .EXAMPLE
        $newVersion = New-BumpedVersion -BumpType "minor"
        # If current is 1.2.3, returns "1.3.0"

    .OUTPUTS
        String - New version
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("major", "minor", "patch")]
        [string]$BumpType
    )

    $currentVersion = Get-CurrentVersion
    if ($null -eq $currentVersion) {
        return $null
    }

    $parts = ConvertFrom-SemanticVersion -Version $currentVersion
    if ($null -eq $parts) {
        return $null
    }

    # Bump based on type
    switch ($BumpType) {
        "major" {
            $parts.Major++
            $parts.Minor = 0
            $parts.Patch = 0
        }
        "minor" {
            $parts.Minor++
            $parts.Patch = 0
        }
        "patch" {
            $parts.Patch++
        }
    }

    return "$($parts.Major).$($parts.Minor).$($parts.Patch)"
}

function Update-PackageVersion {
    <#
    .SYNOPSIS
        Update package.json with new version

    .PARAMETER NewVersion
        New version string (e.g., "1.3.0")

    .EXAMPLE
        Update-PackageVersion -NewVersion "1.3.0"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewVersion
    )

    if (-not (Test-Path $PackageJsonPath)) {
        Write-Error "package.json not found"
        return
    }

    try {
        # Read, update, and write package.json
        $packageJson = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
        $packageJson.version = $NewVersion
        $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $PackageJsonPath -Encoding UTF8

        Write-Host "✅ Updated package.json to version $NewVersion" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update package.json: $($_.Exception.Message)"
    }
}

function New-ReleaseTag {
    <#
    .SYNOPSIS
        Create git tag for release

    .PARAMETER Version
        Version string (e.g., "1.3.0")

    .PARAMETER Message
        Tag annotation message (default: "Release version X.Y.Z")

    .EXAMPLE
        New-ReleaseTag -Version "1.3.0"

    .EXAMPLE
        New-ReleaseTag -Version "1.3.0" -Message "Major release with breaking changes"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [string]$Message = "Release version $Version"
    )

    # Check if tag already exists
    $tagExists = git rev-parse "v$Version" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "⚠️  Tag v$Version already exists"
        return
    }

    # Create annotated tag
    git tag -a "v$Version" -m $Message

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Created git tag: v$Version" -ForegroundColor Green
    }
    else {
        Write-Error "Failed to create git tag"
    }
}

function Publish-ReleaseTag {
    <#
    .SYNOPSIS
        Push tag to remote

    .PARAMETER Version
        Version string

    .EXAMPLE
        Publish-ReleaseTag -Version "1.3.0"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    # Check if remote exists
    $hasRemote = git remote -v 2>$null | Select-String "origin"
    if (-not $hasRemote) {
        Write-Warning "⚠️  No git remote configured, skipping tag push"
        return
    }

    # Push tag
    git push origin "v$Version"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Pushed tag v$Version to remote" -ForegroundColor Green
    }
    else {
        Write-Error "Failed to push tag to remote"
    }
}

function New-ReleaseNotes {
    <#
    .SYNOPSIS
        Generate release notes from ship report

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Version
        Release version

    .PARAMETER OutputFile
        Output file path (default: RELEASE_NOTES.md)

    .EXAMPLE
        New-ReleaseNotes -FeatureDir "specs/001-login" -Version "1.3.0"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "RELEASE_NOTES.md"
    )

    $shipReport = Get-ChildItem -Path $FeatureDir -Filter "*-ship-report.md" -File | Select-Object -First 1

    if (-not $shipReport) {
        Write-Warning "⚠️  Ship report not found in $FeatureDir"
        return
    }

    $slug = Split-Path $FeatureDir -Leaf
    $content = Get-Content $shipReport.FullName -Raw

    # Extract title
    $title = "Feature Release"
    if ($content -match "^# (.+)") {
        $title = $Matches[1]
    }

    # Extract summary
    $summary = ""
    if ($content -match "(?s)## Summary\s*\n\n(.+?)(?=\n##|\z)") {
        $summary = $Matches[1].Trim()
    }

    # Extract changes
    $changes = ""
    if ($content -match "(?s)## Changes\s*\n\n(.+?)(?=\n##|\z)") {
        $changes = $Matches[1].Trim()
    }

    # Extract production URL
    $prodUrl = ""
    if ($content -match "Production URL:\s*(.+)") {
        $prodUrl = $Matches[1].Trim()
    }

    # Generate release notes
    $date = Get-Date -Format "yyyy-MM-dd"
    $releaseNotes = @"
# Release v$Version

**Date**: $date

## Features

### $title

$summary

## Changes

$changes

## Deployment

- **Production URL**: $prodUrl
- **Release Tag**: v$Version
- **Feature Spec**: specs/$slug/spec.md

---

_Generated by Spec-Flow version-manager.ps1_
"@

    $releaseNotes | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Host "✅ Generated release notes: $OutputFile" -ForegroundColor Green
}

function Invoke-InteractiveVersionBump {
    <#
    .SYNOPSIS
        Interactive version bump workflow

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        Invoke-InteractiveVersionBump -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "📦 Version Management" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host ""

    # Get current version
    $currentVersion = Get-CurrentVersion
    Write-Host "Current version: v$currentVersion" -ForegroundColor Cyan
    Write-Host ""

    # Suggest bump type
    $suggestedBump = Get-VersionBumpSuggestion -FeatureDir $FeatureDir
    Write-Host "Suggested bump: $suggestedBump" -ForegroundColor Yellow
    Write-Host ""

    # Calculate new version
    $newVersion = New-BumpedVersion -BumpType $suggestedBump
    Write-Host "New version: v$newVersion" -ForegroundColor Green
    Write-Host ""

    # Prompt for confirmation
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host ""
    $response = Read-Host "Proceed with version bump? (yes/no/custom)"

    switch ($response.ToLower()) {
        { $_ -in @("yes", "y") } {
            # Proceed with suggested version
            Update-PackageVersion -NewVersion $newVersion
            New-ReleaseTag -Version $newVersion -Message "Release v$newVersion"

            # Ask about pushing tag
            Write-Host ""
            $pushResponse = Read-Host "Push tag to remote? (yes/no)"
            if ($pushResponse -in @("yes", "y")) {
                Publish-ReleaseTag -Version $newVersion
            }

            # Generate release notes
            Write-Host ""
            $notesResponse = Read-Host "Generate release notes? (yes/no)"
            if ($notesResponse -in @("yes", "y")) {
                New-ReleaseNotes -FeatureDir $FeatureDir -Version $newVersion
            }
        }

        { $_ -in @("custom", "c") } {
            # Allow custom version input
            Write-Host ""
            $customVersion = Read-Host "Enter custom version (e.g., 2.1.0)"

            # Validate format
            if ($customVersion -notmatch '^\d+\.\d+\.\d+$') {
                Write-Error "❌ Invalid version format. Expected: MAJOR.MINOR.PATCH"
                return
            }

            Update-PackageVersion -NewVersion $customVersion
            New-ReleaseTag -Version $customVersion -Message "Release v$customVersion"

            # Ask about pushing tag
            Write-Host ""
            $pushResponse = Read-Host "Push tag to remote? (yes/no)"
            if ($pushResponse -in @("yes", "y")) {
                Publish-ReleaseTag -Version $customVersion
            }
        }

        default {
            Write-Host "⏭️  Skipped version bump" -ForegroundColor Gray
            return
        }
    }

    Write-Host ""
    Write-Host "✅ Version management complete" -ForegroundColor Green
}

function Invoke-AutoVersionBump {
    <#
    .SYNOPSIS
        Non-interactive version bump (for automation)

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER BumpType
        Type of bump (major, minor, patch, or "auto" to detect)

    .EXAMPLE
        $newVersion = Invoke-AutoVersionBump -FeatureDir "specs/001-login"

    .EXAMPLE
        $newVersion = Invoke-AutoVersionBump -FeatureDir "specs/001-login" -BumpType "minor"

    .OUTPUTS
        String - New version
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "major", "minor", "patch")]
        [string]$BumpType = "auto"
    )

    # Auto-detect bump type if not specified
    if ($BumpType -eq "auto") {
        $BumpType = Get-VersionBumpSuggestion -FeatureDir $FeatureDir
    }

    # Calculate new version
    $newVersion = New-BumpedVersion -BumpType $BumpType

    # Update package.json
    Update-PackageVersion -NewVersion $newVersion

    # Create tag
    New-ReleaseTag -Version $newVersion -Message "Release v$newVersion - Auto-bumped ($BumpType)"

    # Return new version for use by caller
    return $newVersion
}

function Test-VersionFormat {
    <#
    .SYNOPSIS
        Validate version format

    .PARAMETER Version
        Version string to validate

    .EXAMPLE
        Test-VersionFormat -Version "1.2.3"
        # Returns: $true

    .OUTPUTS
        Boolean - True if valid, False otherwise
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    if ($Version -match '^\d+\.\d+\.\d+$') {
        return $true
    }
    else {
        Write-Error "Invalid version format: $Version (expected: MAJOR.MINOR.PATCH)"
        return $false
    }
}

function Get-VersionTags {
    <#
    .SYNOPSIS
        Get list of all version tags

    .EXAMPLE
        $tags = Get-VersionTags

    .OUTPUTS
        Array of version tag strings
    #>

    $tags = git tag -l "v*" 2>$null | Sort-Object { [version]($_ -replace '^v', '') }
    return $tags
}

function Get-LatestVersionTag {
    <#
    .SYNOPSIS
        Get latest version tag

    .EXAMPLE
        $latestTag = Get-LatestVersionTag

    .OUTPUTS
        String - Latest version tag
    #>

    $tags = Get-VersionTags
    if ($tags.Count -gt 0) {
        return $tags[-1]
    }
    return $null
}

function Compare-Versions {
    <#
    .SYNOPSIS
        Compare two versions

    .PARAMETER Version1
        First version

    .PARAMETER Version2
        Second version

    .EXAMPLE
        Compare-Versions -Version1 "1.2.0" -Version2 "1.3.0"
        # Returns: -1 (Version1 < Version2)

    .OUTPUTS
        Int - -1 if Version1 < Version2, 0 if equal, 1 if Version1 > Version2
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version1,

        [Parameter(Mandatory = $true)]
        [string]$Version2
    )

    # Remove leading 'v'
    $Version1 = $Version1 -replace '^v', ''
    $Version2 = $Version2 -replace '^v', ''

    # Parse versions
    $v1 = ConvertFrom-SemanticVersion -Version $Version1
    $v2 = ConvertFrom-SemanticVersion -Version $Version2

    # Compare major
    if ($v1.Major -gt $v2.Major) { return 1 }
    if ($v1.Major -lt $v2.Major) { return -1 }

    # Compare minor
    if ($v1.Minor -gt $v2.Minor) { return 1 }
    if ($v1.Minor -lt $v2.Minor) { return -1 }

    # Compare patch
    if ($v1.Patch -gt $v2.Patch) { return 1 }
    if ($v1.Patch -lt $v2.Patch) { return -1 }

    return 0
}

# Export functions
Export-ModuleMember -Function @(
    'Get-CurrentVersion',
    'ConvertFrom-SemanticVersion',
    'Get-VersionBumpSuggestion',
    'New-BumpedVersion',
    'Update-PackageVersion',
    'New-ReleaseTag',
    'Publish-ReleaseTag',
    'New-ReleaseNotes',
    'Invoke-InteractiveVersionBump',
    'Invoke-AutoVersionBump',
    'Test-VersionFormat',
    'Get-VersionTags',
    'Get-LatestVersionTag',
    'Compare-Versions'
)


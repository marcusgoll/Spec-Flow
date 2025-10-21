<#
.SYNOPSIS
    Internal Release Script for Spec-Flow Workflow

.DESCRIPTION
    DO NOT SHIP: This is for workflow development only

    Automates the release process:
    1. Validates clean working tree
    2. Bumps version in package.json
    3. Updates CHANGELOG.md
    4. Updates README.md version references
    5. Git commits changes
    6. Creates git tag
    7. Optionally publishes to npm

.PARAMETER BumpType
    Version bump type: patch, minor, or major (default: patch)

.PARAMETER DryRun
    Preview changes without making them

.PARAMETER SkipNpm
    Skip npm publish step

.EXAMPLE
    pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType patch

.EXAMPLE
    pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType minor -DryRun

.EXAMPLE
    pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType major -SkipNpm
#>

param(
    [Parameter(Position=0)]
    [ValidateSet('patch', 'minor', 'major')]
    [string]$BumpType = 'patch',

    [switch]$DryRun,
    [switch]$SkipNpm
)

# Error handling
$ErrorActionPreference = 'Stop'

# Helper function for colored output
function Write-Step {
    param(
        [int]$Step,
        [string]$Message
    )
    Write-Host "[" -NoNewline
    Write-Host "$Step/9" -ForegroundColor Blue -NoNewline
    Write-Host "] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

# Header
Write-Host ""
Write-Host "======================================" -ForegroundColor Blue
Write-Host "  Spec-Flow Workflow Release Script" -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Bump type: " -NoNewline
Write-Host $BumpType -ForegroundColor Green
Write-Host "Dry run:   " -NoNewline
Write-Host $DryRun -ForegroundColor Green
Write-Host "Skip npm:  " -NoNewline
Write-Host $SkipNpm -ForegroundColor Green
Write-Host ""

# Step 1: Verify clean working tree
Write-Step -Step 1 -Message "Checking git working tree..."
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Warning-Custom "Working tree has uncommitted changes"
    Write-Host ""
    git status --short
    Write-Host ""
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Aborted" -ForegroundColor Red
        exit 1
    }
}
Write-Success "Working tree checked"

# Step 2: Get current version
Write-Step -Step 2 -Message "Reading current version..."
$packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
$currentVersion = $packageJson.version
Write-Success "Current version: $currentVersion"

# Step 3: Calculate new version
Write-Step -Step 3 -Message "Calculating new version..."
$versionParts = $currentVersion.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

switch ($BumpType) {
    'major' {
        $newVersion = "$($major + 1).0.0"
    }
    'minor' {
        $newVersion = "$major.$($minor + 1).0"
    }
    'patch' {
        $newVersion = "$major.$minor.$($patch + 1)"
    }
}

Write-Success "New version: $newVersion ($currentVersion → $newVersion)"

# Step 4: Update package.json
Write-Step -Step 4 -Message "Updating package.json..."
if (-not $DryRun) {
    $packageJson.version = $newVersion
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path "package.json"
    Write-Success "package.json updated to $newVersion"
} else {
    Write-Host "[DRY RUN] Would update package.json to $newVersion" -ForegroundColor Yellow
}

# Step 5: Update CHANGELOG.md
Write-Step -Step 5 -Message "Updating CHANGELOG.md..."
$releaseDate = Get-Date -Format "yyyy-MM-dd"

if (-not $DryRun) {
    $changelogEntry = @"
## [$newVersion] - $releaseDate

### Changed
- Version bump to $newVersion

<!-- Add release notes here -->


"@

    if (Test-Path "CHANGELOG.md") {
        $changelog = Get-Content -Path "CHANGELOG.md" -Raw
        $firstLine = ($changelog -split "`n")[0]
        $restOfChangelog = ($changelog -split "`n", 2)[1]

        $newChangelog = "$firstLine`n`n$changelogEntry$restOfChangelog"
        Set-Content -Path "CHANGELOG.md" -Value $newChangelog -NoNewline
        Write-Success "CHANGELOG.md updated"
    } else {
        Write-Warning-Custom "CHANGELOG.md not found, creating new one"
        $newChangelog = @"
# Changelog

$changelogEntry
"@
        Set-Content -Path "CHANGELOG.md" -Value $newChangelog -NoNewline
        Write-Success "CHANGELOG.md created"
    }
} else {
    Write-Host "[DRY RUN] Would add entry to CHANGELOG.md for $newVersion" -ForegroundColor Yellow
}

# Step 6: Update README.md
Write-Step -Step 6 -Message "Checking README.md for version references..."
if (Test-Path "README.md") {
    $readme = Get-Content -Path "README.md" -Raw
    if ($readme -match "version-[\d.]+-blue") {
        if (-not $DryRun) {
            $readme = $readme -replace "version-[\d.]+-blue", "version-$newVersion-blue"
            Set-Content -Path "README.md" -Value $readme -NoNewline
            Write-Success "README.md version badge updated"
        } else {
            Write-Host "[DRY RUN] Would update README.md version badge" -ForegroundColor Yellow
        }
    } else {
        Write-Info "No version badge found in README.md"
    }
} else {
    Write-Warning-Custom "README.md not found"
}

# Step 7: Git add and commit
Write-Step -Step 7 -Message "Staging changes..."
if (-not $DryRun) {
    git add package.json CHANGELOG.md README.md 2>$null

    $commitMessage = @"
chore: release v$newVersion

- Bump version to $newVersion
- Update CHANGELOG.md with release notes
- Update version references

Release: v$newVersion
"@

    git commit -m $commitMessage
    Write-Success "Changes committed"
} else {
    Write-Host "[DRY RUN] Would commit: package.json, CHANGELOG.md, README.md" -ForegroundColor Yellow
}

# Step 8: Create git tag
Write-Step -Step 8 -Message "Creating git tag..."
if (-not $DryRun) {
    # Extract changelog entry for tag message
    $changelogContent = Get-Content -Path "CHANGELOG.md" -Raw
    $changelogMatch = $changelogContent -match "\[$newVersion\][^\n]*\n((?:.|\n)*?)(?=\n## \[|$)"
    $changelogNotes = if ($changelogMatch) { $Matches[1].Trim() } else { "Release v$newVersion" }

    $tagMessage = @"
Release v$newVersion

$changelogNotes
"@

    git tag -a "v$newVersion" -m $tagMessage
    Write-Success "Tag v$newVersion created"
} else {
    Write-Host "[DRY RUN] Would create tag v$newVersion" -ForegroundColor Yellow
}

# Step 9: NPM package
Write-Step -Step 9 -Message "NPM package..."
if ($SkipNpm) {
    Write-Info "Skipping npm publish (--skip-npm)"
} elseif (-not $DryRun) {
    Write-Host ""
    Write-Host "Ready to publish to npm registry?" -ForegroundColor Yellow
    Write-Host "  npm publish"
    Write-Host ""
    $response = Read-Host "Publish now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        npm publish
        Write-Success "Published to npm registry"
    } else {
        Write-Info "Skipped npm publish"
        Write-Host ""
        Write-Host "To publish later, run:" -ForegroundColor Blue
        Write-Host "  npm publish"
    }
} else {
    Write-Host "[DRY RUN] Would prompt for npm publish" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Release Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Version:  " -NoNewline
Write-Host "$currentVersion → $newVersion" -ForegroundColor Green
Write-Host "Tag:      " -NoNewline
Write-Host "v$newVersion" -ForegroundColor Green
Write-Host ""

if (-not $DryRun) {
    Write-Host "Next steps:" -ForegroundColor Blue
    Write-Host "  1. Review CHANGELOG.md and add detailed release notes"
    Write-Host "  2. Push to remote:"
    Write-Host "     git push origin main"
    Write-Host "     git push origin v$newVersion"
    if ($SkipNpm) {
        Write-Host "  3. Publish to npm:"
        Write-Host "     npm publish"
    }
} else {
    Write-Host "This was a dry run - no changes made" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To actually release, run:" -ForegroundColor Blue
    Write-Host "  pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType $BumpType"
}

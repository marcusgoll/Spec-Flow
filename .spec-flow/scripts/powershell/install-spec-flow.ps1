#!/usr/bin/env pwsh
<#
.SYNOPSIS
Install Spec-Flow workflow kit to a target project directory.

.DESCRIPTION
Copies .claude/, .spec-flow/, and CLAUDE.md to a target project, then
initializes memory files and validates prerequisites.

.PARAMETER TargetDir
Target project directory (absolute or relative path)

.PARAMETER Force
Overwrite existing files without prompting

.PARAMETER SkipInit
Skip memory file initialization

.PARAMETER SkipChecks
Skip prerequisite checks

.PARAMETER Json
Output results in JSON format

.EXAMPLE
./install-spec-flow.ps1 -TargetDir ./my-project
Install Spec-Flow to my-project (prompt before overwriting)

.EXAMPLE
./install-spec-flow.ps1 -TargetDir ../other-project -Force
Install and overwrite existing files

.EXAMPLE
./install-spec-flow.ps1 -TargetDir ./my-project -SkipInit -SkipChecks
Install files only (no initialization or validation)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [switch]$Force,
    [switch]$SkipInit,
    [switch]$SkipChecks,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found at $commonPath"
    exit 1
}
. $commonPath

# --- Helper Functions -------------------------------------------------------
function Get-PowerShellCommand {
    # Prefer pwsh (PowerShell 7+) but fall back to powershell (5.1)
    if (Get-Command -Name 'pwsh' -ErrorAction SilentlyContinue) {
        return 'pwsh'
    }
    elseif (Get-Command -Name 'powershell' -ErrorAction SilentlyContinue) {
        return 'powershell'
    }
    else {
        throw "No PowerShell executable found (pwsh or powershell)"
    }
}

function Write-Step {
    param([string]$Message)
    if (-not $Json) {
        Write-Host "  $Message" -ForegroundColor Cyan
    }
}

function Write-Success {
    param([string]$Message)
    if (-not $Json) {
        Write-Host "  $Message" -ForegroundColor Green
    }
}

function Write-Warn {
    param([string]$Message)
    if (-not $Json) {
        Write-Host "  $Message" -ForegroundColor Yellow
    }
}

function Confirm-Overwrite {
    param([string]$Path)
    if ($Force) {
        return $true
    }
    $relativePath = $Path -replace [regex]::Escape($targetAbsolute), '.'
    $response = Read-Host "Overwrite existing file: $relativePath? (y/N)"
    return $response -eq 'y' -or $response -eq 'Y'
}

# --- Validate Source Directory ----------------------------------------------
$sourceRoot = Get-RepoRoot
$claudeSourceDir = Join-Path -Path $sourceRoot -ChildPath '.claude'
$specFlowSourceDir = Join-Path -Path $sourceRoot -ChildPath '.spec-flow'
$claudeMdSource = Join-Path -Path $sourceRoot -ChildPath 'CLAUDE.md'

if (-not (Test-Path -LiteralPath $claudeSourceDir -PathType Container)) {
    Write-Error "Source .claude/ directory not found. Are you running this from the Spec-Flow repo?"
    exit 1
}

if (-not (Test-Path -LiteralPath $specFlowSourceDir -PathType Container)) {
    Write-Error "Source .spec-flow/ directory not found. Are you running this from the Spec-Flow repo?"
    exit 1
}

# --- Validate/Create Target Directory ---------------------------------------
$targetAbsolute = if ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
}
else {
    Join-Path -Path (Get-Location) -ChildPath $TargetDir | Resolve-Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
}

if (-not $targetAbsolute) {
    # Target doesn't exist, create it
    Write-Step "Creating target directory: $TargetDir"
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    $targetAbsolute = Resolve-Path -Path $TargetDir | Select-Object -ExpandProperty Path
}

if (-not (Test-Path -LiteralPath $targetAbsolute -PathType Container)) {
    Write-Error "Target directory is not a valid directory: $targetAbsolute"
    exit 1
}

$results = @{
    targetDir   = $targetAbsolute
    copied      = @()
    skipped     = @()
    errors      = @()
    initialized = $false
    checksPass  = $false
}

if (-not $Json) {
    Write-Host ""
    Write-Host "Spec-Flow Installation" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Source: $sourceRoot" -ForegroundColor White
    Write-Host "Target: $targetAbsolute" -ForegroundColor White
    Write-Host ""
}

# --- Copy .claude/ Directory ------------------------------------------------
Write-Step "Copying .claude/ directory..."
$claudeTargetDir = Join-Path -Path $targetAbsolute -ChildPath '.claude'

try {
    if (Test-Path -LiteralPath $claudeTargetDir) {
        if (-not $Force) {
            Write-Warn ".claude/ directory already exists in target"
            $response = Read-Host "Overwrite .claude/ directory? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                $results.skipped += '.claude/'
                Write-Warn "Skipped .claude/ (already exists)"
            }
            else {
                Copy-Item -Path $claudeSourceDir -Destination $targetAbsolute -Recurse -Force
                $results.copied += '.claude/'
                Write-Success "Copied .claude/"
            }
        }
        else {
            Copy-Item -Path $claudeSourceDir -Destination $targetAbsolute -Recurse -Force
            $results.copied += '.claude/'
            Write-Success "Copied .claude/ (overwritten)"
        }
    }
    else {
        Copy-Item -Path $claudeSourceDir -Destination $targetAbsolute -Recurse -Force
        $results.copied += '.claude/'
        Write-Success "Copied .claude/"
    }
}
catch {
    $results.errors += @{ item = '.claude/'; error = $_.Exception.Message }
    Write-Error "Failed to copy .claude/: $($_.Exception.Message)"
}

# --- Copy .spec-flow/ Directory ---------------------------------------------
Write-Step "Copying .spec-flow/ directory..."
$specFlowTargetDir = Join-Path -Path $targetAbsolute -ChildPath '.spec-flow'

try {
    if (Test-Path -LiteralPath $specFlowTargetDir) {
        if (-not $Force) {
            Write-Warn ".spec-flow/ directory already exists in target"
            $response = Read-Host "Overwrite .spec-flow/ directory? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                $results.skipped += '.spec-flow/'
                Write-Warn "Skipped .spec-flow/ (already exists)"
            }
            else {
                Copy-Item -Path $specFlowSourceDir -Destination $targetAbsolute -Recurse -Force
                $results.copied += '.spec-flow/'
                Write-Success "Copied .spec-flow/"
            }
        }
        else {
            Copy-Item -Path $specFlowSourceDir -Destination $targetAbsolute -Recurse -Force
            $results.copied += '.spec-flow/'
            Write-Success "Copied .spec-flow/ (overwritten)"
        }
    }
    else {
        Copy-Item -Path $specFlowSourceDir -Destination $targetAbsolute -Recurse -Force
        $results.copied += '.spec-flow/'
        Write-Success "Copied .spec-flow/"
    }
}
catch {
    $results.errors += @{ item = '.spec-flow/'; error = $_.Exception.Message }
    Write-Error "Failed to copy .spec-flow/: $($_.Exception.Message)"
}

# --- Copy CLAUDE.md (Optional) ----------------------------------------------
if (Test-Path -LiteralPath $claudeMdSource -PathType Leaf) {
    Write-Step "Copying CLAUDE.md..."
    $claudeMdTarget = Join-Path -Path $targetAbsolute -ChildPath 'CLAUDE.md'

    try {
        if (Test-Path -LiteralPath $claudeMdTarget -PathType Leaf) {
            if (Confirm-Overwrite -Path $claudeMdTarget) {
                Copy-Item -LiteralPath $claudeMdSource -Destination $claudeMdTarget -Force
                $results.copied += 'CLAUDE.md'
                Write-Success "Copied CLAUDE.md (overwritten)"
            }
            else {
                $results.skipped += 'CLAUDE.md'
                Write-Warn "Skipped CLAUDE.md (already exists)"
            }
        }
        else {
            Copy-Item -LiteralPath $claudeMdSource -Destination $claudeMdTarget -Force
            $results.copied += 'CLAUDE.md'
            Write-Success "Copied CLAUDE.md"
        }
    }
    catch {
        $results.errors += @{ item = 'CLAUDE.md'; error = $_.Exception.Message }
        if (-not $Json) {
            Write-Warning "Failed to copy CLAUDE.md: $($_.Exception.Message)"
        }
    }
}

# --- Copy QUICKSTART.md (Optional) -----------------------------------------
$quickstartSource = Join-Path -Path $sourceRoot -ChildPath 'QUICKSTART.md'
if (Test-Path -LiteralPath $quickstartSource -PathType Leaf) {
    Write-Step "Copying QUICKSTART.md..."
    $quickstartTarget = Join-Path -Path $targetAbsolute -ChildPath 'QUICKSTART.md'

    try {
        if (Test-Path -LiteralPath $quickstartTarget -PathType Leaf) {
            if (Confirm-Overwrite -Path $quickstartTarget) {
                Copy-Item -LiteralPath $quickstartSource -Destination $quickstartTarget -Force
                $results.copied += 'QUICKSTART.md'
                Write-Success "Copied QUICKSTART.md (overwritten)"
            }
            else {
                $results.skipped += 'QUICKSTART.md'
                Write-Warn "Skipped QUICKSTART.md (already exists)"
            }
        }
        else {
            Copy-Item -LiteralPath $quickstartSource -Destination $quickstartTarget -Force
            $results.copied += 'QUICKSTART.md'
            Write-Success "Copied QUICKSTART.md"
        }
    }
    catch {
        $results.errors += @{ item = 'QUICKSTART.md'; error = $_.Exception.Message }
        if (-not $Json) {
            Write-Warning "Failed to copy QUICKSTART.md: $($_.Exception.Message)"
        }
    }
}

# --- Auto-create settings.local.json from example ----------------------------
Write-Step "Checking settings configuration..."
$settingsExample = Join-Path -Path $claudeTargetDir -ChildPath 'settings.example.json'
$settingsLocal = Join-Path -Path $claudeTargetDir -ChildPath 'settings.local.json'

if ((Test-Path -LiteralPath $settingsExample) -and (-not (Test-Path -LiteralPath $settingsLocal))) {
    # New install: create from example
    try {
        Copy-Item -LiteralPath $settingsExample -Destination $settingsLocal
        $results.copied += 'settings.local.json'
        Write-Success "Created settings.local.json from example"
    }
    catch {
        $results.errors += @{ item = 'settings.local.json'; error = $_.Exception.Message }
        Write-Warn "Failed to create settings.local.json: $($_.Exception.Message)"
    }
}
elseif ((Test-Path -LiteralPath $settingsLocal) -and (Test-Path -LiteralPath $settingsExample)) {
    # Upgrade: check if hooks need to be merged
    try {
        $localSettings = Get-Content -LiteralPath $settingsLocal -Raw | ConvertFrom-Json
        $exampleSettings = Get-Content -LiteralPath $settingsExample -Raw | ConvertFrom-Json

        $needsUpdate = $false
        $updatedFields = @()

        # Check if hooks section is missing or empty
        if (-not $localSettings.hooks -or ($localSettings.hooks.PSObject.Properties.Count -eq 0)) {
            if ($exampleSettings.hooks) {
                $localSettings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $exampleSettings.hooks -Force
                $needsUpdate = $true
                $updatedFields += 'hooks'
            }
        }

        # Check if disableAllHooks needs to be set to false
        if ($localSettings.disableAllHooks -eq $true -and $exampleSettings.disableAllHooks -eq $false) {
            Write-Warn "disableAllHooks is true - hooks won't run. Set to false to enable."
        }
        elseif ($null -eq $localSettings.disableAllHooks -and $null -ne $exampleSettings.disableAllHooks) {
            $localSettings | Add-Member -NotePropertyName 'disableAllHooks' -NotePropertyValue $exampleSettings.disableAllHooks -Force
            $needsUpdate = $true
            $updatedFields += 'disableAllHooks'
        }

        if ($needsUpdate) {
            $localSettings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsLocal -Encoding UTF8
            Write-Success "Updated settings.local.json with: $($updatedFields -join ', ')"
            $results.copied += 'settings.local.json (merged)'
        }
        else {
            Write-Step "settings.local.json already has hooks configuration"
        }
    }
    catch {
        Write-Warn "Could not check/merge settings: $($_.Exception.Message)"
        Write-Step "settings.local.json kept as-is"
    }
}
else {
    Write-Warn "settings.example.json not found - settings.local.json not created"
}

# --- Initialize Memory Files ------------------------------------------------
if (-not $SkipInit) {
    Write-Step "Initializing memory files..."
    $initMemoryScript = Join-Path -Path $PSScriptRoot -ChildPath 'init-memory.ps1'

    try {
        $psCmd = Get-PowerShellCommand
        $initResult = & $psCmd -NoLogo -NoProfile -File $initMemoryScript -TargetDir $targetAbsolute -Json 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            $results.initialized = $true
            Write-Success "Memory files initialized"
        }
        else {
            Write-Warn "Memory initialization had issues (check .spec-flow/memory/)"
        }
    }
    catch {
        $results.errors += @{ item = 'init-memory'; error = $_.Exception.Message }
        Write-Warn "Failed to initialize memory files: $($_.Exception.Message)"
    }
}
else {
    Write-Step "Skipping memory initialization (use -SkipInit=`$false to enable)"
}

# --- Install Git Hooks -------------------------------------------------------
$gitDir = Join-Path -Path $targetAbsolute -ChildPath '.git'
if (Test-Path -LiteralPath $gitDir -PathType Container) {
    Write-Step "Installing git hooks..."
    $gitHooksScript = Join-Path -Path $targetAbsolute -ChildPath '.spec-flow/scripts/bash/install-git-hooks.sh'

    if (Test-Path -LiteralPath $gitHooksScript) {
        try {
            $origLocation = Get-Location
            Set-Location -Path $targetAbsolute

            # Try to run bash script (works on Windows with Git Bash)
            $bashCmd = Get-Command -Name 'bash' -ErrorAction SilentlyContinue
            if ($bashCmd) {
                $null = & bash '.spec-flow/scripts/bash/install-git-hooks.sh' --force 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Git hooks installed"
                }
                else {
                    Write-Warn "Git hooks installation had issues (non-critical)"
                }
            }
            else {
                Write-Warn "Bash not found - skipping git hooks installation"
                Write-Step "  Run manually: bash .spec-flow/scripts/bash/install-git-hooks.sh"
            }

            Set-Location -Path $origLocation
        }
        catch {
            Set-Location -Path $origLocation
            Write-Warn "Could not install git hooks: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warn "Git hooks script not found at $gitHooksScript"
    }
}
else {
    Write-Step "Skipping git hooks (not a git repository)"
}

# --- Run Prerequisite Checks ------------------------------------------------
if (-not $SkipChecks) {
    Write-Step "Running prerequisite checks..."
    $checkPrereqScript = Join-Path -Path $PSScriptRoot -ChildPath 'check-prerequisites.ps1'

    try {
        $psCmd = Get-PowerShellCommand
        # Change to target directory for check-prerequisites
        $origLocation = Get-Location
        Set-Location -Path $targetAbsolute
        $checkResult = & $psCmd -NoLogo -NoProfile -File $checkPrereqScript -Json 2>&1 | Out-String
        Set-Location -Path $origLocation

        $checkData = $checkResult | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($checkData.status -eq 'ready') {
            $results.checksPass = $true
            Write-Success "All prerequisite checks passed"
        }
        else {
            Write-Warn "Some prerequisite checks failed (run check-prerequisites.ps1 for details)"
        }
    }
    catch {
        Set-Location -Path $origLocation
        Write-Warn "Could not run prerequisite checks: $($_.Exception.Message)"
    }
}
else {
    Write-Step "Skipping prerequisite checks (use -SkipChecks=`$false to enable)"
}

# --- Output Results ---------------------------------------------------------
if ($Json) {
    $results | ConvertTo-Json -Depth 10 -Compress | Write-Output
}
else {
    Write-Host ""
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "======================" -ForegroundColor Green
    Write-Host ""

    if ($results.copied.Count -gt 0) {
        Write-Host "Installed:" -ForegroundColor Green
        foreach ($item in $results.copied) {
            Write-Host "  $item" -ForegroundColor Green
        }
        Write-Host ""
    }

    if ($results.skipped.Count -gt 0) {
        Write-Host "Skipped (already exist):" -ForegroundColor Yellow
        foreach ($item in $results.skipped) {
            Write-Host "  $item" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Configure Claude Code settings:" -ForegroundColor White
    Write-Host "   cd $targetAbsolute" -ForegroundColor DarkGray
    Write-Host "   # Edit .claude/settings.local.json and add your project paths to 'allow'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "2. Customize your engineering principles:" -ForegroundColor White
    Write-Host "   # Edit .spec-flow/memory/constitution.md" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "3. In Claude Code, navigate to your project and run:" -ForegroundColor White
    Write-Host "   /roadmap" -ForegroundColor Green
    Write-Host ""
    Write-Host "4. Read the getting started guide:" -ForegroundColor White
    Write-Host "   https://github.com/marcusgoll/Spec-Flow/blob/main/docs/getting-started.md" -ForegroundColor DarkGray
    Write-Host ""
}

exit 0


#!/usr/bin/env pwsh
<#
.SYNOPSIS
Interactive wizard to install and configure Spec-Flow for your project.

.DESCRIPTION
Guides you through:
- Project discovery and configuration
- Engineering standards setup
- Initial roadmap creation
- Design inspiration collection
- Complete Spec-Flow installation

.PARAMETER TargetDir
Target project directory (will prompt if not provided)

.PARAMETER NonInteractive
Skip prompts and use defaults (for CI/scripted installs)

.EXAMPLE
./install-wizard.ps1
Run interactive wizard

.EXAMPLE
./install-wizard.ps1 -TargetDir ../my-project
Install to specific directory with guided setup

.EXAMPLE
./install-wizard.ps1 -TargetDir ../my-project -NonInteractive
Install with defaults, no prompts
#>

[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$NonInteractive
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
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "===================================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "===================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor Yellow
}

function Prompt-Required {
    param(
        [string]$Question,
        [string]$Default = ""
    )
    do {
        if ($Default) {
            $response = Read-Host "$Question [$Default]"
            if (-not $response) { return $Default }
        } else {
            $response = Read-Host "$Question"
        }
    } while (-not $response)
    return $response
}

function Prompt-Optional {
    param(
        [string]$Question,
        [string]$Default = ""
    )
    if ($Default) {
        $response = Read-Host "$Question [$Default]"
        if (-not $response) { return $Default }
        return $response
    } else {
        return Read-Host "$Question (press Enter to skip)"
    }
}

function Prompt-Choice {
    param(
        [string]$Question,
        [string[]]$Options,
        [int]$Default = 0
    )
    Write-Host ""
    Write-Host $Question -ForegroundColor Yellow
    for ($i = 0; $i -lt $Options.Length; $i++) {
        $marker = if ($i -eq $Default) { ">" } else { " " }
        Write-Host "  $marker [$($i + 1)] $($Options[$i])" -ForegroundColor White
    }

    do {
        $response = Read-Host "Enter choice [1-$($Options.Length)] (default: $($Default + 1))"
        if (-not $response) { return $Default }
        [int]$choice = 0
        if ([int]::TryParse($response, [ref]$choice) -and $choice -ge 1 -and $choice -le $Options.Length) {
            return $choice - 1
        }
        Write-Host "  Invalid choice. Please enter a number between 1 and $($Options.Length)" -ForegroundColor Red
    } while ($true)
}

function Detect-ProjectType {
    param([string]$ProjectPath)

    $indicators = @{
        'Next.js' = @('next.config.js', 'next.config.mjs', 'next.config.ts')
        'React' = @('package.json')  # Will check for react in dependencies
        'Vue' = @('vue.config.js', 'vite.config.js')
        'Angular' = @('angular.json')
        'Node.js API' = @('package.json')  # Will check for express/fastify
        'Python' = @('requirements.txt', 'pyproject.toml', 'setup.py')
        'Django' = @('manage.py')
        'FastAPI' = @('main.py')  # Common convention
        '.NET' = @('*.csproj', '*.sln')
        'Go' = @('go.mod')
        'Rust' = @('Cargo.toml')
    }

    $detected = @()

    foreach ($type in $indicators.Keys) {
        foreach ($file in $indicators[$type]) {
            $pattern = Join-Path -Path $ProjectPath -ChildPath $file
            if (Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue) {
                $detected += $type
                break
            }
        }
    }

    # Check package.json for more specific detection
    $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath 'package.json'
    if (Test-Path -LiteralPath $packageJsonPath) {
        $packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($packageJson.dependencies) {
            if ($packageJson.dependencies.'next') { $detected = @('Next.js') + $detected }
            elseif ($packageJson.dependencies.'react') { $detected = @('React') + $detected }
            elseif ($packageJson.dependencies.'vue') { $detected = @('Vue') + $detected }
            elseif ($packageJson.dependencies.'express' -or $packageJson.dependencies.'fastify') {
                $detected = @('Node.js API') + $detected
            }
        }
    }

    return @($detected | Select-Object -Unique)
}

# --- Main Wizard Flow -------------------------------------------------------
Clear-Host

Write-Header "Spec-Flow Installation Wizard"

Write-Host "  Welcome! This wizard will help you:" -ForegroundColor White
Write-Host "  * Install Spec-Flow to your project" -ForegroundColor White
Write-Host "  * Customize engineering standards" -ForegroundColor White
Write-Host "  * Create your initial roadmap" -ForegroundColor White
Write-Host "  * Set up design inspirations" -ForegroundColor White
Write-Host ""

if (-not $NonInteractive) {
    $continue = Read-Host "Ready to begin? (Y/n)"
    if ($continue -eq 'n' -or $continue -eq 'N') {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# --- Step 1: Target Directory -----------------------------------------------
Write-Header "Step 1: Project Location"

if (-not $TargetDir -and -not $NonInteractive) {
    Write-Host "  Enter the path to your project directory." -ForegroundColor White
    Write-Host "  Examples: ../my-app, C:\Projects\my-app, ~/projects/my-app" -ForegroundColor DarkGray
    Write-Host ""
    $TargetDir = Prompt-Required "Project directory"
}

if (-not $TargetDir) {
    Write-Error "Target directory is required. Use -TargetDir parameter or run interactively."
    exit 1
}

# Resolve absolute path
$targetAbsolute = if ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
} else {
    Join-Path -Path (Get-Location) -ChildPath $TargetDir
}

if (-not (Test-Path -LiteralPath $targetAbsolute -PathType Container)) {
    if ($NonInteractive) {
        Write-Error "Target directory does not exist: $targetAbsolute"
        exit 1
    }

    $create = Read-Host "Directory doesn't exist. Create it? (Y/n)"
    if ($create -ne 'n' -and $create -ne 'N') {
        New-Item -ItemType Directory -Path $targetAbsolute -Force | Out-Null
        Write-Host "  [OK] Created directory: $targetAbsolute" -ForegroundColor Green
    } else {
        Write-Error "Installation cancelled."
        exit 1
    }
}

Write-Host "  [OK] Target: $targetAbsolute" -ForegroundColor Green

# --- Step 2: Detect Project Type -------------------------------------------
Write-Header "Step 2: Detecting Project"

$detectedTypes = Detect-ProjectType -ProjectPath $targetAbsolute
if (-not $detectedTypes) { $detectedTypes = @() }
$projectType = if ($detectedTypes.Count -gt 0) { $detectedTypes[0] } else { "Unknown" }

Write-Host "  Project type: $projectType" -ForegroundColor White
Write-Host ""

# --- Step 3: Run Installation -----------------------------------------------
Write-Header "Step 3: Installing Spec-Flow"

Write-Host "  Running installer..." -ForegroundColor White
Write-Host ""

$installScript = Join-Path -Path $PSScriptRoot -ChildPath 'install-spec-flow.ps1'
& powershell -NoLogo -NoProfile -File $installScript -TargetDir $targetAbsolute

if ($LASTEXITCODE -ne 0) {
    Write-Error "Installation failed. See errors above."
    exit 1
}

# --- Step 4: Initialize Base Files -------------------------------------------
Write-Header "Step 4: Initializing Memory Files"

$constitutionPath = Join-Path -Path $targetAbsolute -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory' | Join-Path -ChildPath 'constitution.md'
$roadmapPath = Join-Path -Path $targetAbsolute -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory' | Join-Path -ChildPath 'roadmap.md'
$designPath = Join-Path -Path $targetAbsolute -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory' | Join-Path -ChildPath 'design-inspirations.md'

if ((Test-Path -LiteralPath $constitutionPath) -and (Test-Path -LiteralPath $roadmapPath) -and (Test-Path -LiteralPath $designPath)) {
    Write-Host "  [OK] Constitution initialized with defaults (80% coverage, <200ms API, <2s page load)" -ForegroundColor Green
    Write-Host "  [OK] Roadmap initialized (empty)" -ForegroundColor Green
    Write-Host "  [OK] Design inspirations initialized (empty)" -ForegroundColor Green
} else {
    Write-Warning "Some memory files may not have been created. Check installation output above."
}

# Roadmap is initialized empty - use /roadmap command in Claude Code to add features

# --- Final Steps ------------------------------------------------------------
Write-Header "Installation Complete!"

Write-Host "  What was installed:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  * Project type detected: $projectType" -ForegroundColor White
Write-Host "  * .claude/ directory (agents, commands, settings)" -ForegroundColor White
Write-Host "  * .spec-flow/ directory (scripts, templates, memory)" -ForegroundColor White
Write-Host "  * CLAUDE.md (workflow documentation)" -ForegroundColor White
Write-Host ""
Write-Host "  Initialized memory files with defaults:" -ForegroundColor Cyan
Write-Host "  * .spec-flow/memory/constitution.md (80% test coverage, standard performance targets)" -ForegroundColor DarkGray
Write-Host "  * .spec-flow/memory/roadmap.md (empty - ready for your features)" -ForegroundColor DarkGray
Write-Host "  * .spec-flow/memory/design-inspirations.md (empty - ready for your references)" -ForegroundColor DarkGray

Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Open your project in Claude Code:" -ForegroundColor White
Write-Host "     cd $targetAbsolute" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  2. Customize your engineering principles:" -ForegroundColor White
Write-Host "     /constitution" -ForegroundColor Green
Write-Host "     (Interactive wizard to set test coverage, performance targets, etc.)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  3. Build your feature roadmap:" -ForegroundColor White
Write-Host "     /roadmap" -ForegroundColor Green
Write-Host "     (Add features, prioritize with ICE scoring)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  4. Add design inspirations:" -ForegroundColor White
Write-Host "     /design-inspiration" -ForegroundColor Green
Write-Host "     (Reference sites/apps for visual consistency)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  5. Start building your first feature:" -ForegroundColor White
Write-Host "     /spec-flow \"feature-name\"" -ForegroundColor Green
Write-Host "     (Creates spec from roadmap and kicks off workflow)" -ForegroundColor DarkGray

Write-Host ""
Write-Host "  Full guide: https://github.com/marcusgoll/Spec-Flow/blob/main/QUICKSTART.md" -ForegroundColor DarkGray
Write-Host ""

exit 0

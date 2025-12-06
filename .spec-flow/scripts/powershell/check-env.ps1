#!/usr/bin/env pwsh

<#!
/check-env [staging|production]

Validate environment variables before deployment. Prevents "missing env var" deployment failures.

USAGE:
  pwsh -File check-env.ps1 [staging|production]
  pwsh -File check-env.ps1 -Environment staging
  pwsh -File check-env.ps1  # Interactive prompt

OPTIONS:
  -Environment    Target environment (staging or production)
  -Project        Doppler project name (default: cfipros)
  -Help           Show this help message

PHASES:
  1. Environment selection (interactive if not specified)
  2. Doppler CLI validation (installed and authenticated)
  3. Config existence (marketing, app, api configs)
  4. Secret presence (all required secrets per surface)
  5. Environment-specific validation (ENVIRONMENT var, URL sanity)
  6. Platform sync verification (GitHub, Vercel, Railway)
  7. Final report (JSON + console output)

OUTPUT:
  - Human-readable summary to console
  - JSON report at specs/<feature>/reports/check-env.json
  - Exit code 0 (success) or 1 (missing secrets)

SECURITY:
  - Never prints secret values
  - Domain-only URL validation
  - Read-only platform probes
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('staging', 'production')]
    [string]$Environment,

    [string]$Project = 'cfipros',

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 0
}

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

function Write-Bold {
    param([string]$Message)
    Write-Host -ForegroundColor White -Object "`n$Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host -ForegroundColor Green -Object "✅ $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host -ForegroundColor Yellow -Object "⚠️  $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host -ForegroundColor Red -Object "❌ $Message"
}

function Write-Separator {
    Write-Host ('━' * 80)
}

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) {
    $RepoRoot = $PWD.Path
}

$FeatureDir = $env:FEATURE_DIR
if (-not $FeatureDir) {
    $SpecDirs = Get-ChildItem -Path "$RepoRoot/specs" -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($SpecDirs) {
        $FeatureDir = $SpecDirs.FullName
    }
}

$ReportDir = "$FeatureDir/reports"
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

$JsonReport = "$ReportDir/check-env.json"
$Services = @('marketing', 'app', 'api')

# -----------------------------------------------------------------------------
# Phase 1: Environment Selection
# -----------------------------------------------------------------------------

Write-Bold "Environment Variable Check"

if (-not $Environment) {
    Write-Host "Select environment:"
    Write-Host "  1) staging"
    Write-Host "  2) production"
    $choice = Read-Host "Choose (1-2)"

    switch ($choice) {
        '1' { $Environment = 'staging' }
        '2' { $Environment = 'production' }
        default {
            Write-Error "Invalid choice"
            exit 1
        }
    }
}

Write-Host "Environment: $Environment"

# -----------------------------------------------------------------------------
# Phase 2: Doppler CLI Validation
# -----------------------------------------------------------------------------

Write-Bold "Phase 2: Doppler CLI Validation"

if (-not (Get-Command doppler -ErrorAction SilentlyContinue)) {
    Write-Error "Doppler CLI not installed"
    Write-Host "`nInstall:"
    Write-Host "  Windows:  winget install doppler.doppler  or  scoop install doppler"
    Write-Host "  macOS:    brew install dopplerhq/cli/doppler"
    Write-Host "  Linux:    curl -Ls https://cli.doppler.com/install.sh | sh"
    Write-Host "`nDocs: https://docs.doppler.com/docs/install-cli"
    exit 1
}
Write-Success "Doppler CLI installed"

# Quick auth probe
try {
    doppler me 2>&1 | Out-Null
    Write-Success "Doppler authenticated"
}
catch {
    Write-Error "Not authenticated with Doppler. Run: doppler login"
    exit 1
}

# -----------------------------------------------------------------------------
# Phase 3: Config Existence
# -----------------------------------------------------------------------------

Write-Bold "Phase 3: Doppler Config Validation"

$MissingConfigs = @()

foreach ($svc in $Services) {
    $cfg = "${Environment}_${svc}"
    Write-Host "Config: $cfg"

    try {
        $configList = doppler configs list --project $Project --json 2>&1 | ConvertFrom-Json
        $configExists = $configList | Where-Object { $_.name -eq $cfg }

        if ($configExists) {
            Write-Host "  ✅ Exists"
        }
        else {
            Write-Host "  ❌ Missing"
            $MissingConfigs += $cfg
        }
    }
    catch {
        Write-Host "  ❌ Missing"
        $MissingConfigs += $cfg
    }
}

if ($MissingConfigs.Count -gt 0) {
    Write-Error "Missing Doppler configs: $($MissingConfigs -join ', ')"
    Write-Host "`nRun setup to create configs: .spec-flow/scripts/powershell/setup-doppler.ps1"
    exit 1
}
Write-Success "All Doppler configs exist"

# -----------------------------------------------------------------------------
# Phase 4: Required Secrets
# -----------------------------------------------------------------------------

Write-Bold "Phase 4: Required Secrets Validation"

$FrontendSecrets = @(
    'NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY',
    'CLERK_SECRET_KEY',
    'NEXT_PUBLIC_API_URL',
    'BACKEND_API_URL',
    'NEXT_PUBLIC_APP_URL',
    'NEXT_PUBLIC_MARKETING_URL',
    'UPSTASH_REDIS_REST_URL',
    'UPSTASH_REDIS_REST_TOKEN',
    'NEXT_PUBLIC_HCAPTCHA_SITE_KEY',
    'HCAPTCHA_SECRET_KEY',
    'JWT_SECRET',
    'NEXT_PUBLIC_POSTHOG_KEY',
    'NEXT_PUBLIC_POSTHOG_HOST'
)

$BackendSecrets = @(
    'DATABASE_URL',
    'DIRECT_URL',
    'OPENAI_API_KEY',
    'VISION_MODEL',
    'SECRET_KEY',
    'ENVIRONMENT',
    'ALLOWED_ORIGINS',
    'REDIS_URL'
)

$Missing = @()
$Present = @()

function Test-Secret {
    param(
        [string]$Config,
        [string[]]$Secrets
    )

    Write-Host "${Config}:"
    foreach ($key in $Secrets) {
        try {
            doppler secrets get $key --project $Project --config $Config --plain 2>&1 | Out-Null
            Write-Host "  ✅ $key"
            $script:Present += "${Config}:${key}"
        }
        catch {
            Write-Host "  ❌ $key (missing)"
            $script:Missing += "${Config}:${key}"
        }
    }
    Write-Host ""
}

Test-Secret -Config "${Environment}_marketing" -Secrets $FrontendSecrets
Test-Secret -Config "${Environment}_app" -Secrets $FrontendSecrets
Test-Secret -Config "${Environment}_api" -Secrets $BackendSecrets

# Check .env.example for drift
$EnvExample = "$RepoRoot/.env.example"
if (Test-Path $EnvExample) {
    Write-Host "Δ From .env.example (informational):"
    $ExampleKeys = Get-Content $EnvExample |
        Where-Object { $_ -match '^[A-Z0-9_]+=|^[A-Z0-9_]+:' } |
        ForEach-Object { ($_ -split '[=:]')[0].Trim() } |
        Sort-Object -Unique

    $AllCuratedKeys = $FrontendSecrets + $BackendSecrets
    foreach ($k in $ExampleKeys) {
        if ($k -notin $AllCuratedKeys) {
            Write-Host "  • $k (not in curated lists)"
        }
    }
    Write-Host ""
}

# -----------------------------------------------------------------------------
# Phase 5: Environment-Specific Validation
# -----------------------------------------------------------------------------

Write-Bold "Phase 5: Environment-Specific Validation"

# ENVIRONMENT variable match
$ApiCfg = "${Environment}_api"
try {
    $ApiEnv = doppler secrets get ENVIRONMENT --project $Project --config $ApiCfg --plain 2>&1
    if ($ApiEnv -ne $Environment) {
        Write-Warning "ENVIRONMENT mismatch in API config: expected '$Environment', got '$ApiEnv'"
    }
    else {
        Write-Success "ENVIRONMENT variable correct: $Environment"
    }
}
catch {
    Write-Warning "ENVIRONMENT variable not set (already flagged above if missing)"
}

# URL sanity checks (domain-only)
$AppCfg = "${Environment}_app"
try {
    $ApiUrl = doppler secrets get NEXT_PUBLIC_API_URL --project $Project --config $AppCfg --plain 2>&1
    $Domain = ([uri]$ApiUrl).Host

    if ($Environment -eq 'staging') {
        if ($Domain -match 'staging|railway\.app') {
            Write-Success "NEXT_PUBLIC_API_URL points to staging-like domain: $Domain"
        }
        else {
            Write-Warning "NEXT_PUBLIC_API_URL domain '$Domain' doesn't look like staging"
        }
    }
    else {
        if ($Domain -eq 'api.cfipros.com') {
            Write-Success "NEXT_PUBLIC_API_URL points to production: $Domain"
        }
        else {
            Write-Warning "NEXT_PUBLIC_API_URL domain '$Domain' should be 'api.cfipros.com'"
        }
    }
}
catch {
    Write-Warning "NEXT_PUBLIC_API_URL not set (already flagged above if missing)"
}

# -----------------------------------------------------------------------------
# Phase 6: Platform Sync Verification
# -----------------------------------------------------------------------------

Write-Bold "Phase 6: Platform Sync Verification (Optional)"

# GitHub CLI
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        gh auth status 2>&1 | Out-Null
        Write-Host "GitHub Secrets (org/repo scope as configured by gh):"
        gh secret list 2>&1 | Out-Null
        Write-Success "gh secret list available"
    }
    catch {
        Write-Warning "gh not authenticated"
    }
}

# Vercel CLI
if (Get-Command vercel -ErrorAction SilentlyContinue) {
    try {
        vercel --version 2>&1 | Out-Null
        Write-Success "Vercel CLI available"
    }
    catch {
        Write-Warning "Vercel CLI not working"
    }
}

# Railway CLI
if (Get-Command railway -ErrorAction SilentlyContinue) {
    try {
        railway whoami 2>&1 | Out-Null
        Write-Host "Railway: checking DOPPLER_TOKEN presence is project-specific; verify in deployment env UI/CLI."
    }
    catch {
        Write-Warning "Railway CLI not authenticated"
    }
}

Write-Success "Platform sync checks complete"

# -----------------------------------------------------------------------------
# Phase 7: Final Report
# -----------------------------------------------------------------------------

$Status = if ($Missing.Count -gt 0) { 1 } else { 0 }

# Write JSON report
$Report = @{
    environment = $Environment
    project     = $Project
    summary     = @{
        missing = $Missing.Count
        present = $Present.Count
    }
    details     = @{
        missing = $Missing
        present = $Present
    }
}

$Report | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonReport -Encoding UTF8

Write-Separator

if ($Status -ne 0) {
    Write-Error "MISSING SECRETS IN DOPPLER"
    Write-Host ""
    Write-Host "Fix with Doppler CLI (examples):"
    Write-Host "  doppler secrets set VAR=value --project $Project --config ${Environment}_app"
    Write-Host "  doppler secrets set VAR=value --project $Project --config ${Environment}_api"
    Write-Host ""
    Write-Host "See JSON report: $JsonReport"
    exit 1
}
else {
    Write-Success "ALL SECRETS CONFIGURED IN DOPPLER"
    Write-Host "Environment: $Environment"
    Write-Host "Safe to deploy"
    Write-Host "Report: $JsonReport"
    exit 0
}


<#
.SYNOPSIS
    Initialize project design documentation

.DESCRIPTION
    Idempotent project documentation generator with multiple operation modes.
    Supports interactive and non-interactive modes with environment variables
    and config file loading.

.PARAMETER ProjectName
    Optional project name (will prompt if not provided in interactive mode)

.PARAMETER Force
    Overwrite all existing docs (destructive)

.PARAMETER Update
    Only update [NEEDS CLARIFICATION] sections in existing docs

.PARAMETER WriteMissingOnly
    Only create missing docs, preserve existing files

.PARAMETER CI
    CI mode: non-interactive, exit 1 if questions unanswered

.PARAMETER NonInteractive
    Use environment variables or config file only, no prompts

.PARAMETER ConfigFile
    Load answers from YAML/JSON config file

.EXAMPLE
    .\init-project.ps1 "MyProject"
    Initialize with interactive questionnaire

.EXAMPLE
    .\init-project.ps1 -Force
    Force overwrite all existing documentation

.EXAMPLE
    .\init-project.ps1 -Update
    Only update [NEEDS CLARIFICATION] sections

.EXAMPLE
    .\init-project.ps1 -ConfigFile "project-config.json" -NonInteractive
    Load config from JSON file, no interactive prompts

.EXAMPLE
    $env:INIT_NAME="MyProject"; $env:INIT_VISION="A great app"; .\init-project.ps1 -CI
    CI mode with environment variables

.EXAMPLE
    .\init-project.ps1 "MyProject" -WithDesign
    Initialize with interactive questionnaire and generate design system docs

.NOTES
    Environment Variables (used in non-interactive mode):
    INIT_NAME, INIT_VISION, INIT_USERS, INIT_SCALE, INIT_TEAM_SIZE
    INIT_ARCHITECTURE, INIT_DATABASE, INIT_DEPLOY_PLATFORM, INIT_API_STYLE
    INIT_AUTH_PROVIDER, INIT_BUDGET_MVP, INIT_PRIVACY, INIT_GIT_WORKFLOW
    INIT_DEPLOY_MODEL, INIT_FRONTEND, INIT_COMPONENT_LIBRARY

    With --WithDesign:
    - Generates 4 design documents in docs/design/
    - Creates tokens.css and tokens.json in design/systems/
    - Sets up OKLCH color system with design tokens
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectName = "",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Update,

    [Parameter()]
    [switch]$WriteMissingOnly,

    [Parameter()]
    [switch]$CI,

    [Parameter()]
    [switch]$NonInteractive,

    [Parameter()]
    [string]$ConfigFile = "",

    [Parameter()]
    [switch]$WithDesign
)

$ErrorActionPreference = "Stop"

# Script paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# ScriptDir is .spec-flow/scripts/powershell, so we need .Parent.Parent.Parent to reach project root
$ProjectRoot = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName

# Determine mode
$Mode = "default"
if ($Force) { $Mode = "force" }
elseif ($Update) { $Mode = "update" }
elseif ($WriteMissingOnly) { $Mode = "write-missing-only" }

# Determine interactive mode
$Interactive = -not ($NonInteractive -or $CI)

# Color output helpers
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    $missing = @()

    # Node.js required
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $missing += "node (Node.js)"
    }

    # jq for JSON parsing
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        $missing += "jq (JSON parser) - Install via: choco install jq"
    }

    if ($missing.Count -gt 0) {
        Write-Error-Custom "Missing required tools:"
        $missing | ForEach-Object { Write-Error-Custom "  - $_" }
        exit 1
    }
}

# Load config file
function Import-ConfigFile {
    param([string]$Path)

    if (-not $Path) { return }

    if (-not (Test-Path $Path)) {
        Write-Error-Custom "Config file not found: $Path"
        exit 1
    }

    Write-Info "Loading config from: $Path"

    $config = $null
    if ($Path -match '\.(yaml|yml)$') {
        # Load YAML (requires yq)
        if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
            Write-Error-Custom "yq required for YAML config. Install via: choco install yq"
            exit 1
        }
        # Parse YAML to JSON then to PowerShell object
        $json = & yq eval -o=json $Path | Out-String
        $config = $json | ConvertFrom-Json
    }
    elseif ($Path -match '\.json$') {
        $config = Get-Content $Path -Raw | ConvertFrom-Json
    }
    else {
        Write-Error-Custom "Config file must be .yaml, .yml, or .json"
        exit 1
    }

    # Set environment variables from config
    if ($config.project.name) { $env:INIT_NAME = $config.project.name }
    if ($config.project.vision) { $env:INIT_VISION = $config.project.vision }
    if ($config.project.users) { $env:INIT_USERS = $config.project.users }
    if ($config.project.scale) { $env:INIT_SCALE = $config.project.scale }
    if ($config.project.team_size) { $env:INIT_TEAM_SIZE = $config.project.team_size }
    if ($config.project.architecture) { $env:INIT_ARCHITECTURE = $config.project.architecture }
    if ($config.project.database) { $env:INIT_DATABASE = $config.project.database }
    if ($config.project.deploy_platform) { $env:INIT_DEPLOY_PLATFORM = $config.project.deploy_platform }
    if ($config.project.api_style) { $env:INIT_API_STYLE = $config.project.api_style }
    if ($config.project.auth_provider) { $env:INIT_AUTH_PROVIDER = $config.project.auth_provider }
    if ($config.project.budget_mvp) { $env:INIT_BUDGET_MVP = $config.project.budget_mvp }
    if ($config.project.privacy) { $env:INIT_PRIVACY = $config.project.privacy }
    if ($config.project.git_workflow) { $env:INIT_GIT_WORKFLOW = $config.project.git_workflow }
    if ($config.project.deploy_model) { $env:INIT_DEPLOY_MODEL = $config.project.deploy_model }
    if ($config.project.frontend) { $env:INIT_FRONTEND = $config.project.frontend }

    Write-Success "Config loaded"
}

# Detect project type
function Get-ProjectType {
    if ((Test-Path "package.json") -or (Test-Path "requirements.txt") -or
        (Test-Path "Cargo.toml") -or (Test-Path "go.mod")) {
        return "brownfield"
    }
    return "greenfield"
}

# Scan brownfield codebase
function Invoke-BrownfieldScan {
    Write-Info "Scanning existing codebase..."

    # Detect database from package.json
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" -Raw

        if ($packageJson -match '"pg"') {
            if (-not $env:INIT_DATABASE) { $env:INIT_DATABASE = "PostgreSQL" }
        }
        elseif ($packageJson -match '"mysql') {
            if (-not $env:INIT_DATABASE) { $env:INIT_DATABASE = "MySQL" }
        }
        elseif ($packageJson -match '"mongoose"') {
            if (-not $env:INIT_DATABASE) { $env:INIT_DATABASE = "MongoDB" }
        }

        # Detect frontend
        if ($packageJson -match '"next"') {
            if (-not $env:INIT_FRONTEND) { $env:INIT_FRONTEND = "Next.js" }
        }
        elseif (($packageJson -match '"react"') -and ($packageJson -match '"vite"')) {
            if (-not $env:INIT_FRONTEND) { $env:INIT_FRONTEND = "Vite + React" }
        }
    }

    # Detect deployment platform
    if (Test-Path "vercel.json") {
        if (-not $env:INIT_DEPLOY_PLATFORM) { $env:INIT_DEPLOY_PLATFORM = "Vercel" }
    }
    elseif (Test-Path "railway.json") {
        if (-not $env:INIT_DEPLOY_PLATFORM) { $env:INIT_DEPLOY_PLATFORM = "Railway" }
    }

    # Detect architecture
    if (Test-Path "docker-compose.yml") {
        $composeContent = Get-Content "docker-compose.yml" -Raw
        $serviceMatches = [regex]::Matches($composeContent, '^\s+[a-z]', 'Multiline')
        if ($serviceMatches.Count -gt 2) {
            if (-not $env:INIT_ARCHITECTURE) { $env:INIT_ARCHITECTURE = "microservices" }
        }
        else {
            if (-not $env:INIT_ARCHITECTURE) { $env:INIT_ARCHITECTURE = "monolith" }
        }
    }
    else {
        if (-not $env:INIT_ARCHITECTURE) { $env:INIT_ARCHITECTURE = "monolith" }
    }

    Write-Success "Brownfield scan complete"
}

# Interactive questionnaire
function Invoke-Questionnaire {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "📋 PROJECT INFORMATION"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    # Q1: Project Name
    if (-not $env:INIT_NAME) {
        if ($ProjectName) {
            $env:INIT_NAME = $ProjectName
            Write-Host "Q1. Project name: $($env:INIT_NAME) (from argument)"
        }
        else {
            $env:INIT_NAME = Read-Host "Q1. Project name (e.g., 'FlightPro', 'AcmeApp')"
        }
    }

    # Q2: Vision
    if (-not $env:INIT_VISION) {
        $env:INIT_VISION = Read-Host "Q2. What does this project do? (1 sentence)"
    }

    # Q3: Target Users
    if (-not $env:INIT_USERS) {
        $env:INIT_USERS = Read-Host "Q3. Who are the primary users? (e.g., 'Flight instructors')"
    }

    # Q4: Scale
    if (-not $env:INIT_SCALE) {
        Write-Host ""
        Write-Host "Q4. Expected initial scale?"
        Write-Host "  1. Micro (< 100 users)"
        Write-Host "  2. Small (100-1K users)"
        Write-Host "  3. Medium (1K-10K users)"
        Write-Host "  4. Large (10K+ users)"
        $scaleChoice = Read-Host "Choice (1-4)"
        $env:INIT_SCALE = switch ($scaleChoice) {
            "1" { "micro" }
            "2" { "small" }
            "3" { "medium" }
            "4" { "large" }
            default { "micro" }
        }
    }

    # Q5: Team Size
    if (-not $env:INIT_TEAM_SIZE) {
        Write-Host ""
        Write-Host "Q5. Current team size?"
        Write-Host "  1. Solo (1 developer)"
        Write-Host "  2. Small (2-5 developers)"
        Write-Host "  3. Medium (5-15 developers)"
        Write-Host "  4. Large (15+ developers)"
        $teamChoice = Read-Host "Choice (1-4)"
        $env:INIT_TEAM_SIZE = switch ($teamChoice) {
            "1" { "solo" }
            "2" { "small" }
            "3" { "medium" }
            "4" { "large" }
            default { "solo" }
        }
    }

    # Q6: Architecture
    if (-not $env:INIT_ARCHITECTURE) {
        Write-Host ""
        Write-Host "Q6. System architecture pattern?"
        Write-Host "  1. Monolith (single deployable unit)"
        Write-Host "  2. Modular Monolith (domain boundaries)"
        Write-Host "  3. Microservices (distributed system)"
        Write-Host "  4. Serverless (functions as a service)"
        $archChoice = Read-Host "Choice (1-4)"
        $env:INIT_ARCHITECTURE = switch ($archChoice) {
            "1" { "monolith" }
            "2" { "modular-monolith" }
            "3" { "microservices" }
            "4" { "serverless" }
            default { "monolith" }
        }
    }

    # Q7: Database
    if (-not $env:INIT_DATABASE) {
        Write-Host ""
        Write-Host "Q7. Primary database?"
        Write-Host "  1. PostgreSQL"
        Write-Host "  2. MySQL"
        Write-Host "  3. MongoDB"
        Write-Host "  4. SQLite"
        Write-Host "  5. Supabase (PostgreSQL + Auth)"
        Write-Host "  6. PlanetScale (MySQL + Edge)"
        Write-Host "  7. Other"
        $dbChoice = Read-Host "Choice (1-7)"
        $env:INIT_DATABASE = switch ($dbChoice) {
            "1" { "PostgreSQL" }
            "2" { "MySQL" }
            "3" { "MongoDB" }
            "4" { "SQLite" }
            "5" { "Supabase" }
            "6" { "PlanetScale" }
            "7" { Read-Host "Enter database name" }
            default { "PostgreSQL" }
        }
    }

    # Q8: Deploy Platform
    if (-not $env:INIT_DEPLOY_PLATFORM) {
        Write-Host ""
        Write-Host "Q8. Deployment platform?"
        Write-Host "  1. Vercel (frontend + serverless)"
        Write-Host "  2. Railway (containers + databases)"
        Write-Host "  3. AWS (full cloud suite)"
        Write-Host "  4. GCP (full cloud suite)"
        Write-Host "  5. Azure (full cloud suite)"
        Write-Host "  6. Self-hosted (VPS/dedicated)"
        Write-Host "  7. Hybrid (multiple platforms)"
        $deployChoice = Read-Host "Choice (1-7)"
        $env:INIT_DEPLOY_PLATFORM = switch ($deployChoice) {
            "1" { "Vercel" }
            "2" { "Railway" }
            "3" { "AWS" }
            "4" { "GCP" }
            "5" { "Azure" }
            "6" { "Self-hosted" }
            "7" { "Hybrid" }
            default { "Vercel" }
        }
    }

    # Q9: API Style
    if (-not $env:INIT_API_STYLE) {
        Write-Host ""
        Write-Host "Q9. API style?"
        Write-Host "  1. REST (resource-based)"
        Write-Host "  2. GraphQL (flexible queries)"
        Write-Host "  3. tRPC (type-safe, TypeScript)"
        Write-Host "  4. gRPC (high-performance RPC)"
        Write-Host "  5. Hybrid (multiple styles)"
        $apiChoice = Read-Host "Choice (1-5)"
        $env:INIT_API_STYLE = switch ($apiChoice) {
            "1" { "REST" }
            "2" { "GraphQL" }
            "3" { "tRPC" }
            "4" { "gRPC" }
            "5" { "Hybrid" }
            default { "REST" }
        }
    }

    # Q10: Auth Provider
    if (-not $env:INIT_AUTH_PROVIDER) {
        Write-Host ""
        Write-Host "Q10. Authentication provider?"
        Write-Host "  1. Clerk (hosted + components)"
        Write-Host "  2. NextAuth.js (open-source)"
        Write-Host "  3. Auth0 (enterprise)"
        Write-Host "  4. Supabase Auth (with Supabase)"
        Write-Host "  5. Firebase Auth (with Firebase)"
        Write-Host "  6. Custom (roll your own)"
        Write-Host "  7. None (no auth needed)"
        $authChoice = Read-Host "Choice (1-7)"
        $env:INIT_AUTH_PROVIDER = switch ($authChoice) {
            "1" { "Clerk" }
            "2" { "NextAuth.js" }
            "3" { "Auth0" }
            "4" { "Supabase" }
            "5" { "Firebase" }
            "6" { "Custom" }
            "7" { "None" }
            default { "Clerk" }
        }
    }

    # Q11: Budget for MVP
    if (-not $env:INIT_BUDGET_MVP) {
        Write-Host ""
        Write-Host "Q11. Monthly infrastructure budget for MVP?"
        Write-Host "  1. `$0 (free tier only)"
        Write-Host "  2. `$50 or less"
        Write-Host "  3. `$50-200"
        Write-Host "  4. `$200-500"
        Write-Host "  5. `$500+"
        $budgetChoice = Read-Host "Choice (1-5)"
        $env:INIT_BUDGET_MVP = switch ($budgetChoice) {
            "1" { "0" }
            "2" { "50" }
            "3" { "200" }
            "4" { "500" }
            "5" { "500+" }
            default { "50" }
        }
    }

    # Q12: Privacy Requirements
    if (-not $env:INIT_PRIVACY) {
        Write-Host ""
        Write-Host "Q12. Privacy/compliance requirements?"
        Write-Host "  1. Basic (standard web app)"
        Write-Host "  2. PII handling (user data)"
        Write-Host "  3. GDPR compliant (EU users)"
        Write-Host "  4. HIPAA (healthcare data)"
        Write-Host "  5. SOC2 (enterprise security)"
        Write-Host "  6. Multiple standards"
        $privacyChoice = Read-Host "Choice (1-6)"
        $env:INIT_PRIVACY = switch ($privacyChoice) {
            "1" { "Basic" }
            "2" { "PII" }
            "3" { "GDPR" }
            "4" { "HIPAA" }
            "5" { "SOC2" }
            "6" { "Multiple" }
            default { "PII" }
        }
    }

    # Q13: Git Workflow
    if (-not $env:INIT_GIT_WORKFLOW) {
        Write-Host ""
        Write-Host "Q13. Git branching strategy?"
        Write-Host "  1. GitHub Flow (simple feature branches)"
        Write-Host "  2. GitFlow (develop + release branches)"
        Write-Host "  3. Trunk-based (main only)"
        Write-Host "  4. Ship/Show/Ask (async)"
        $gitChoice = Read-Host "Choice (1-4)"
        $env:INIT_GIT_WORKFLOW = switch ($gitChoice) {
            "1" { "GitHub Flow" }
            "2" { "GitFlow" }
            "3" { "Trunk-based" }
            "4" { "Ship/Show/Ask" }
            default { "GitHub Flow" }
        }
    }

    # Q14: Deployment Model
    if (-not $env:INIT_DEPLOY_MODEL) {
        Write-Host ""
        Write-Host "Q14. Deployment model?"
        Write-Host "  1. staging-prod (staging preview before production)"
        Write-Host "  2. direct-prod (deploy directly to production)"
        Write-Host "  3. local-only (no remote deployment)"
        $deployModelChoice = Read-Host "Choice (1-3)"
        $env:INIT_DEPLOY_MODEL = switch ($deployModelChoice) {
            "1" { "staging-prod" }
            "2" { "direct-prod" }
            "3" { "local-only" }
            default { "staging-prod" }
        }
    }

    # Q15: Frontend Framework
    if (-not $env:INIT_FRONTEND) {
        Write-Host ""
        Write-Host "Q15. Frontend framework?"
        Write-Host "  1. Next.js (React + SSR)"
        Write-Host "  2. Remix (React + Web standards)"
        Write-Host "  3. Vite + React (SPA)"
        Write-Host "  4. Vue.js / Nuxt"
        Write-Host "  5. Svelte / SvelteKit"
        Write-Host "  6. Astro (content-focused)"
        Write-Host "  7. None (API only)"
        $frontendChoice = Read-Host "Choice (1-7)"
        $env:INIT_FRONTEND = switch ($frontendChoice) {
            "1" { "Next.js" }
            "2" { "Remix" }
            "3" { "Vite + React" }
            "4" { "Vue.js" }
            "5" { "Svelte" }
            "6" { "Astro" }
            "7" { "None" }
            default { "Next.js" }
        }
    }

    Write-Success "Questionnaire complete"
}

# Detect component library from package.json
function Get-ComponentLibrary {
    if (-not (Test-Path "package.json")) {
        return
    }

    $packageJson = Get-Content "package.json" -Raw

    # shadcn/ui detection (Radix + custom components in src/components/ui)
    if (($packageJson -match '@radix-ui/') -and
        ((Test-Path "src/components/ui") -or (Test-Path "components/ui"))) {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "shadcn/ui"
            Write-Success "Detected component library: shadcn/ui (Radix + custom components)"
        }
        return
    }

    # Chakra UI
    if ($packageJson -match '@chakra-ui/react') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "Chakra UI"
            Write-Success "Detected component library: Chakra UI"
        }
        return
    }

    # Material UI (MUI)
    if ($packageJson -match '@mui/material') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "MUI"
            Write-Success "Detected component library: Material UI (MUI)"
        }
        return
    }

    # HeroUI
    if ($packageJson -match '@heroui/') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "HeroUI"
            Write-Success "Detected component library: HeroUI"
        }
        return
    }

    # Ant Design
    if ($packageJson -match '"antd"') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "Ant Design"
            Write-Success "Detected component library: Ant Design"
        }
        return
    }

    # Mantine
    if ($packageJson -match '@mantine/core') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "Mantine"
            Write-Success "Detected component library: Mantine"
        }
        return
    }

    # Radix UI (standalone, not shadcn)
    if ($packageJson -match '@radix-ui/') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "Radix UI"
            Write-Success "Detected component library: Radix UI"
        }
        return
    }

    # Headless UI
    if ($packageJson -match '@headlessui/') {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "Headless UI"
            Write-Success "Detected component library: Headless UI"
        }
        return
    }

    # DaisyUI (requires tailwindcss)
    if (($packageJson -match '"daisyui"') -and ($packageJson -match '"tailwindcss"')) {
        if (-not $env:INIT_COMPONENT_LIBRARY) {
            $env:INIT_COMPONENT_LIBRARY = "DaisyUI"
            Write-Success "Detected component library: DaisyUI"
        }
        return
    }
}

# Generate project CLAUDE.md
function New-ProjectClaudeMd {
    Write-Info "Generating project CLAUDE.md..."

    $claudeMdPath = Join-Path $ProjectRoot "docs\project\CLAUDE.md"
    $docsDir = Join-Path $ProjectRoot "docs\project"

    # Ensure docs directory exists
    if (-not (Test-Path $docsDir)) {
        New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
    }

    # Try using the bash script if available
    $bashScript = Join-Path $ProjectRoot ".spec-flow\scripts\bash\generate-project-claude-md.sh"
    if ((Get-Command bash -ErrorAction SilentlyContinue) -and (Test-Path $bashScript)) {
        Push-Location $ProjectRoot
        & bash $bashScript
        Pop-Location
        return
    }

    # Fallback: Generate simple CLAUDE.md inline
    $content = @"
# Project: $($env:INIT_NAME)

## Overview
$($env:INIT_VISION)

## Technical Stack
- **Frontend**: $($env:INIT_FRONTEND)
- **Database**: $($env:INIT_DATABASE)
- **Authentication**: $($env:INIT_AUTH_PROVIDER)
- **Deployment**: $($env:INIT_DEPLOY_PLATFORM) ($($env:INIT_DEPLOY_MODEL))

## Architecture
- **Pattern**: $($env:INIT_ARCHITECTURE)
- **API Style**: $($env:INIT_API_STYLE)
- **Scale Tier**: $($env:INIT_SCALE)

## Documentation Index
- [Overview](overview.md) - Project vision and scope
- [System Architecture](system-architecture.md) - C4 model diagrams
- [Tech Stack](tech-stack.md) - Technology choices
- [Data Architecture](data-architecture.md) - Database schema
- [API Strategy](api-strategy.md) - API design
- [Capacity Planning](capacity-planning.md) - Scale requirements
- [Deployment Strategy](deployment-strategy.md) - CI/CD pipeline
- [Development Workflow](development-workflow.md) - Team processes

## Quick Commands
- ``/feature "name"`` - Start a new feature
- ``/roadmap`` - Manage product roadmap
- ``/help`` - Get context-aware guidance
"@

    Set-Content -Path $claudeMdPath -Value $content
    Write-Success "Generated project CLAUDE.md"
}

# Create foundation issue for greenfield projects
function New-FoundationIssue {
    param([string]$ProjectType)

    # Only create for greenfield projects
    if ($ProjectType -ne "greenfield") {
        return
    }

    # Check if gh CLI available
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Info "GitHub CLI not found, skipping foundation issue creation"
        return
    }

    # Check if authenticated
    try {
        $authStatus = & gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Info "GitHub CLI not authenticated, skipping foundation issue creation"
            return
        }
    }
    catch {
        return
    }

    Write-Info "Creating foundation issue for greenfield project..."

    $issueBody = @"
<!-- roadmap-metadata
feature_slug: foundation-setup
area: infrastructure
role: fullstack
priority: P0
complexity: M
status: next
-->

## Overview

Foundation setup for **$($env:INIT_NAME)** - initial project scaffolding based on architecture decisions.

## Acceptance Criteria

### Core Setup
- [ ] Frontend framework initialized ($($env:INIT_FRONTEND))
- [ ] Backend API scaffolding ($($env:INIT_API_STYLE))
- [ ] Database connection configured ($($env:INIT_DATABASE))
- [ ] Authentication provider integrated ($($env:INIT_AUTH_PROVIDER))

### Infrastructure
- [ ] Deployment pipeline ($($env:INIT_DEPLOY_PLATFORM))
- [ ] Environment configuration (dev, staging, prod)
- [ ] CI/CD workflows (GitHub Actions)

### Developer Experience
- [ ] TypeScript strict mode
- [ ] ESLint + Prettier configured
- [ ] Husky pre-commit hooks
- [ ] Testing framework (Jest/Vitest + Playwright)

## Technical Notes

Generated from ``/init-project`` questionnaire responses.

---
Generated by Spec-Flow
"@

    try {
        $result = & gh issue create --title "[Foundation] Initial project scaffolding for $($env:INIT_NAME)" --body $issueBody --label "foundation,status:next,area:infrastructure,priority:P0"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Created foundation issue"
        }
    }
    catch {
        Write-Warning-Custom "Failed to create foundation issue: $_"
    }
}

# Render design documentation (when --WithDesign is specified)
function Invoke-DesignDocumentRender {
    param([string]$AnswersFile)

    Write-Info "Generating design documentation..."

    $designDocs = @(
        "brand-guidelines",
        "style-guide",
        "wireframe-library",
        "motion-design"
    )

    $designDir = Join-Path $ProjectRoot "docs\design"
    if (-not (Test-Path $designDir)) {
        New-Item -ItemType Directory -Path $designDir -Force | Out-Null
    }

    foreach ($doc in $designDocs) {
        $template = Join-Path $ProjectRoot ".spec-flow\templates\design\$doc.md"
        $output = Join-Path $designDir "$doc.md"

        if (-not (Test-Path $template)) {
            Write-Warning-Custom "Template not found: $doc.md"
            continue
        }

        # Skip if write-missing-only and file exists
        if (($Mode -eq "write-missing-only") -and (Test-Path $output)) {
            Write-Info "Skipping existing: $doc.md"
            continue
        }

        # Render with Node.js
        $renderScript = Join-Path $ProjectRoot ".spec-flow\scripts\node\render.js"
        & node $renderScript --template $template --output $output --answers $AnswersFile
    }

    # Copy tokens templates
    $tokensDir = Join-Path $ProjectRoot "design\systems"
    if (-not (Test-Path $tokensDir)) {
        New-Item -ItemType Directory -Path $tokensDir -Force | Out-Null
    }

    $tokensCss = Join-Path $ProjectRoot ".spec-flow\templates\design\tokens.css"
    $tokensJson = Join-Path $ProjectRoot ".spec-flow\templates\design\tokens.json"

    if (Test-Path $tokensCss) {
        Copy-Item $tokensCss (Join-Path $tokensDir "tokens.css") -Force
        Write-Success "Created design/systems/tokens.css"
    }

    if (Test-Path $tokensJson) {
        Copy-Item $tokensJson (Join-Path $tokensDir "tokens.json") -Force
        Write-Success "Created design/systems/tokens.json"
    }

    Write-Success "Design documentation generated"
}

# Generate answers JSON
function New-AnswersJson {
    param([string]$OutputPath)

    $answers = @{
        PROJECT_NAME    = if ($env:INIT_NAME) { $env:INIT_NAME } else { "[NEEDS CLARIFICATION]" }
        VISION          = if ($env:INIT_VISION) { $env:INIT_VISION } else { "[NEEDS CLARIFICATION]" }
        PRIMARY_USERS   = if ($env:INIT_USERS) { $env:INIT_USERS } else { "[NEEDS CLARIFICATION]" }
        SCALE           = if ($env:INIT_SCALE) { $env:INIT_SCALE } else { "micro" }
        TEAM_SIZE       = if ($env:INIT_TEAM_SIZE) { $env:INIT_TEAM_SIZE } else { "solo" }
        ARCHITECTURE    = if ($env:INIT_ARCHITECTURE) { $env:INIT_ARCHITECTURE } else { "monolith" }
        DATABASE        = if ($env:INIT_DATABASE) { $env:INIT_DATABASE } else { "PostgreSQL" }
        DEPLOY_PLATFORM = if ($env:INIT_DEPLOY_PLATFORM) { $env:INIT_DEPLOY_PLATFORM } else { "Vercel" }
        API_STYLE       = if ($env:INIT_API_STYLE) { $env:INIT_API_STYLE } else { "REST" }
        AUTH_PROVIDER   = if ($env:INIT_AUTH_PROVIDER) { $env:INIT_AUTH_PROVIDER } else { "Clerk" }
        BUDGET_MVP      = if ($env:INIT_BUDGET_MVP) { $env:INIT_BUDGET_MVP } else { "50" }
        PRIVACY         = if ($env:INIT_PRIVACY) { $env:INIT_PRIVACY } else { "PII" }
        GIT_WORKFLOW    = if ($env:INIT_GIT_WORKFLOW) { $env:INIT_GIT_WORKFLOW } else { "GitHub Flow" }
        DEPLOY_MODEL    = if ($env:INIT_DEPLOY_MODEL) { $env:INIT_DEPLOY_MODEL } else { "staging-prod" }
        FRONTEND        = if ($env:INIT_FRONTEND) { $env:INIT_FRONTEND } else { "Next.js" }
        DATE            = Get-Date -Format "yyyy-MM-dd"
    }

    $answers | ConvertTo-Json | Set-Content $OutputPath
}

# Render documentation
function Invoke-DocumentationRender {
    param(
        [string]$AnswersFile,
        [string]$RenderMode
    )

    Write-Info "Generating project documentation..."

    $docs = @(
        "overview",
        "system-architecture",
        "tech-stack",
        "data-architecture",
        "api-strategy",
        "capacity-planning",
        "deployment-strategy",
        "development-workflow"
    )

    foreach ($doc in $docs) {
        $template = Join-Path $ProjectRoot ".spec-flow\templates\project\$doc.md"
        $output = Join-Path $ProjectRoot "docs\project\$doc.md"

        # Skip if write-missing-only and file exists
        if (($Mode -eq "write-missing-only") -and (Test-Path $output)) {
            Write-Info "Skipping existing: $doc.md"
            continue
        }

        # Render with Node.js
        $renderScript = Join-Path $ProjectRoot ".spec-flow\scripts\node\render.js"
        if ($RenderMode -eq "update") {
            & node $renderScript --template $template --output $output --answers $AnswersFile --mode update
        }
        else {
            & node $renderScript --template $template --output $output --answers $AnswersFile
        }
    }

    Write-Success "Documentation generated"
}

# Create ADR baseline
function New-ADRBaseline {
    $adrDir = Join-Path $ProjectRoot "docs\adr"
    if (-not (Test-Path $adrDir)) {
        New-Item -ItemType Directory -Path $adrDir | Out-Null
    }

    $adrFile = Join-Path $adrDir "0001-project-architecture-baseline.md"

    if ((Test-Path $adrFile) -and ($Mode -ne "force")) {
        Write-Info "ADR-0001 already exists, skipping"
        return
    }

    $adrContent = @"
# ADR-0001: Project Architecture Baseline

**Status**: Accepted
**Date**: $(Get-Date -Format "yyyy-MM-dd")
**Deciders**: Engineering Team

## Context

This is the initial architectural decision record documenting the baseline technology choices and architectural patterns for the $($env:INIT_NAME) project.

These decisions were made during project initialization and establish the foundation for all future architectural decisions.

## Decision

We have decided to build $($env:INIT_NAME) with the following architecture:

### Technology Stack

- **Frontend**: $($env:INIT_FRONTEND)
- **Backend**: [Based on API style: $($env:INIT_API_STYLE)]
- **Database**: $($env:INIT_DATABASE)
- **Authentication**: $($env:INIT_AUTH_PROVIDER)
- **Deployment**: $($env:INIT_DEPLOY_PLATFORM)

### Architectural Style

- **Pattern**: $($env:INIT_ARCHITECTURE)
- **API Style**: $($env:INIT_API_STYLE)
- **Scale Tier**: $($env:INIT_SCALE)

### Development Workflow

- **Git Workflow**: $($env:INIT_GIT_WORKFLOW)
- **Deployment Model**: $($env:INIT_DEPLOY_MODEL)
- **Team Size**: $($env:INIT_TEAM_SIZE)

## Consequences

### Positive

- Clear technology baseline for all engineers
- Consistent patterns across the codebase
- Documented rationale for technology choices

### Negative

- Technology choices constrain future flexibility
- Migration to different stack requires new ADR and significant effort

### Risks

- Technology may become outdated over time
- Team expertise may not align with chosen stack

## References

- [Tech Stack Documentation](../project/tech-stack.md)
- [System Architecture](../project/system-architecture.md)
- [Deployment Strategy](../project/deployment-strategy.md)

## Notes

This ADR serves as the baseline. All future architectural changes should reference this decision and explain deviations.
"@

    Set-Content -Path $adrFile -Value $adrContent
    Write-Success "Created ADR-0001"
}

# Run quality gates
function Invoke-QualityGates {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "🔍 QUALITY GATES"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    $exitCode = 0
    $docsDir = Join-Path $ProjectRoot "docs\project"

    # Gate 1: Check for [NEEDS CLARIFICATION]
    $needsClarification = Select-String -Path "$docsDir\*.md" -Pattern "NEEDS CLARIFICATION" -ErrorAction SilentlyContinue
    if ($needsClarification) {
        Write-Warning-Custom "Found [NEEDS CLARIFICATION] tokens in documentation"
        Write-Warning-Custom "Review and fill missing information"

        if ($CI) {
            Write-Error-Custom "CI mode: Unanswered questions not allowed"
            $exitCode = 2
        }
    }
    else {
        Write-Success "No missing information"
    }

    # Gate 2: Markdown linting (if available)
    if (Get-Command markdownlint -ErrorAction SilentlyContinue) {
        Write-Info "Running markdownlint..."
        $lintResult = & markdownlint $docsDir 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Markdown linting passed"
        }
        else {
            Write-Warning-Custom "Markdown linting failed (non-blocking)"
        }
    }

    # Gate 3: Validate C4 model sections
    $archFile = Join-Path $docsDir "system-architecture.md"
    if (Test-Path $archFile) {
        $requiredSections = @("Context", "Containers", "Components")
        foreach ($section in $requiredSections) {
            $hasSection = Select-String -Path $archFile -Pattern "^## $section" -Quiet
            if ($hasSection) {
                Write-Success "C4 section found: $section"
            }
            else {
                Write-Warning-Custom "Missing C4 section: $section"
                if ($CI) { $exitCode = 2 }
            }
        }
    }

    Write-Host ""

    if ($exitCode -ne 0) {
        Write-Error-Custom "Quality gates failed"
        return $exitCode
    }

    Write-Success "All quality gates passed"
    return 0
}

# Commit documentation
function Invoke-DocumentationCommit {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "📦 COMMITTING DOCUMENTATION"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    Push-Location $ProjectRoot

    git add docs/project/
    git add docs/adr/
    git add CLAUDE.md 2>$null

    $commitMsg = @"
docs: initialize project design documentation

Project: $($env:INIT_NAME)
Architecture: $($env:INIT_ARCHITECTURE)
Database: $($env:INIT_DATABASE)
Deployment: $($env:INIT_DEPLOY_PLATFORM) ($($env:INIT_DEPLOY_MODEL))
Scale: $($env:INIT_SCALE)

Generated comprehensive documentation:
- 8 project docs (overview, architecture, tech stack, data, API, capacity, deployment, workflow)
- ADR-0001 (architecture baseline)
- Project CLAUDE.md (AI context navigation)

Mode: $Mode

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
"@

    git commit -m $commitMsg 2>$null
    if ($LASTEXITCODE -eq 0) {
        $commitHash = git rev-parse --short HEAD
        Write-Success "Documentation committed: $commitHash"
    }
    else {
        Write-Warning-Custom "No changes to commit (docs may be up to date)"
    }

    Pop-Location
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "🏗️  PROJECT INITIALIZATION"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    # Check prerequisites
    Test-Prerequisites

    # Load config if provided
    if ($ConfigFile) {
        Import-ConfigFile $ConfigFile
    }

    # Detect project type
    $projectType = Get-ProjectType
    Write-Info "Project type: $projectType"

    # Scan brownfield codebase
    if ($projectType -eq "brownfield") {
        Invoke-BrownfieldScan
    }

    # Detect component library
    Get-ComponentLibrary

    # Run questionnaire if interactive
    if ($Interactive) {
        Invoke-Questionnaire
    }
    elseif ($CI) {
        # CI mode: validate required vars
        $requiredVars = @("INIT_NAME", "INIT_VISION", "INIT_USERS")
        $missing = $requiredVars | Where-Object { -not (Get-Item "env:$_" -ErrorAction SilentlyContinue) }

        if ($missing) {
            Write-Error-Custom "CI mode: Missing required environment variables:"
            $missing | ForEach-Object { Write-Error-Custom "  - $_" }
            exit 1
        }
    }

    # Generate answers JSON
    $answersFile = Join-Path $env:TEMP "init-project-answers-$PID.json"
    New-AnswersJson $answersFile

    # Render documentation
    $renderMode = if ($Mode -eq "update") { "update" } else { "default" }
    Invoke-DocumentationRender $answersFile $renderMode

    # Render design documentation if --WithDesign
    if ($WithDesign) {
        Invoke-DesignDocumentRender $answersFile
    }

    # Generate project CLAUDE.md
    New-ProjectClaudeMd

    # Create ADR baseline
    New-ADRBaseline

    # Run quality gates
    $gateResult = Invoke-QualityGates
    if ($gateResult -ne 0) {
        Remove-Item $answersFile -ErrorAction SilentlyContinue
        exit $gateResult
    }

    # Create foundation issue for greenfield projects
    New-FoundationIssue $projectType

    # Commit documentation
    Invoke-DocumentationCommit

    # Cleanup
    Remove-Item $answersFile -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "✅ PROJECT INITIALIZATION COMPLETE"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""
    Write-Host "Project: $($env:INIT_NAME)"
    Write-Host "Mode: $Mode"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review docs/project/"
    Write-Host "  2. Fill any [NEEDS CLARIFICATION] sections"
    Write-Host "  3. Start building: /roadmap or /feature"
    Write-Host ""
}

# Run main function
Main


#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate project-level CLAUDE.md aggregation

.DESCRIPTION
    Aggregates active features, tech stack, common patterns into single
    2k-token file (vs 12k tokens for reading 10 separate project docs)

.PARAMETER OutputFile
    Output file path (default: CLAUDE.md in repo root)

.PARAMETER Json
    Output JSON instead of markdown

.EXAMPLE
    .\generate-project-claude-md.ps1

.EXAMPLE
    .\generate-project-claude-md.ps1 -OutputFile "project-context.md"

.EXAMPLE
    .\generate-project-claude-md.ps1 -Json
#>

param(
    [string]$OutputFile,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent

# Default output file
if (-not $OutputFile) {
    $OutputFile = Join-Path $repoRoot "CLAUDE.md"
}

# Check prerequisites
if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
    Write-Error "[spec-flow][error] yq not found. Install with: choco install yq (Windows) or brew install yq (macOS)"
    exit 1
}

# Function: Find all active features
function Find-ActiveFeatures {
    $features = @()
    $specsDir = Join-Path $repoRoot "specs"

    if (-not (Test-Path $specsDir)) {
        return @()
    }

    $stateFiles = Get-ChildItem -Path $specsDir -Filter "state.yaml" -Recurse -File

    foreach ($stateFile in $stateFiles) {
        $featureDir = $stateFile.Directory
        $featureName = $featureDir.Name

        # Extract current phase and status
        try {
            $phase = & yq eval '.workflow.phase // "unknown"' $stateFile.FullName 2>$null
            $status = & yq eval '.workflow.status // "unknown"' $stateFile.FullName 2>$null

            if (-not $phase) { $phase = "unknown" }
            if (-not $status) { $status = "unknown" }

            # Only include active features (not completed or failed)
            if ($status -ne "completed" -and $status -ne "failed") {
                $features += @{
                    name   = $featureName
                    phase  = $phase
                    status = $status
                }
            }
        }
        catch {
            Write-Warning "Could not parse $($stateFile.FullName): $_"
        }
    }

    return $features
}

# Function: Extract tech stack summary
function Get-TechStackSummary {
    $techStackFile = Join-Path $repoRoot "docs\project\tech-stack.md"

    if (-not (Test-Path $techStackFile)) {
        return @{
            frontend   = ""
            backend    = ""
            database   = ""
            deployment = ""
        }
    }

    $content = Get-Content $techStackFile -Raw

    # Helper function to extract section
    function Extract-Section {
        param([string]$Content, [string]$Header)

        $pattern = "(?s)## $Header.*?(?=\n##|\z)"
        if ($Content -match $pattern) {
            $section = $Matches[0]
            # Extract bullet points with ** markers
            $bullets = [regex]::Matches($section, '\*\*([^*]+)\*\*([^\n]+)')
            $result = @()
            foreach ($match in $bullets | Select-Object -First 5) {
                $result += "  - $($match.Groups[1].Value):$($match.Groups[2].Value)"
            }
            return $result -join "`n"
        }
        return ""
    }

    return @{
        frontend   = Extract-Section -Content $content -Header "Frontend"
        backend    = Extract-Section -Content $content -Header "Backend"
        database   = Extract-Section -Content $content -Header "Database"
        deployment = Extract-Section -Content $content -Header "Deployment"
    }
}

# Function: Extract common patterns from all plan.md files
function Get-CommonPatterns {
    $patterns = @{}
    $specsDir = Join-Path $repoRoot "specs"

    if (-not (Test-Path $specsDir)) {
        return @()
    }

    $planFiles = Get-ChildItem -Path $specsDir -Filter "plan.md" -Recurse -File

    foreach ($planFile in $planFiles) {
        $content = Get-Content $planFile.FullName -Raw

        # Extract Reuse Additions section
        $reusePattern = '(?s)###\s+Reuse\s+Additions.*?(?=\n###|\z)'
        if ($content -match $reusePattern) {
            $reuseSection = $Matches[0]

            # Extract patterns (- ✅ **PatternName** ...)
            $patternMatches = [regex]::Matches($reuseSection, '-\s+✅\s+\*\*([^*]+)\*\*')

            foreach ($match in $patternMatches) {
                $patternName = $match.Groups[1].Value

                # Try to extract path from same or next line
                $startIndex = $match.Index + $match.Length
                $remainingText = $reuseSection.Substring($startIndex, [Math]::Min(200, $reuseSection.Length - $startIndex))

                $path = ""
                if ($remainingText -match '`([^`]+)`') {
                    $path = $Matches[1]
                }

                # Use pattern name as key to deduplicate
                if (-not $patterns.ContainsKey($patternName)) {
                    $patterns[$patternName] = $path
                }
            }
        }
    }

    # Convert to array of objects
    $result = @()
    foreach ($key in $patterns.Keys) {
        $result += @{
            name = $key
            path = $patterns[$key]
        }
    }

    return $result
}

# Function: Generate markdown output
function New-MarkdownOutput {
    param(
        [array]$ActiveFeatures,
        [hashtable]$TechStack,
        [array]$Patterns
    )

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss" -AsUTC

    $markdown = @"
# Project Context

> **Purpose**: High-level project navigation and context aggregation
> **Token Cost**: ~2,000 tokens (vs 12,000 for reading all project docs)
> **Last Updated**: $timestamp

## Active Features

"@

    if ($ActiveFeatures.Count -eq 0) {
        $markdown += "No active features.`n"
    }
    else {
        foreach ($feature in $ActiveFeatures) {
            $markdown += "- **$($feature.name)**: Phase $($feature.phase) ($($feature.status))`n"
        }
    }

    $markdown += @"

## Tech Stack Summary

"@

    # Frontend
    if ($TechStack.frontend) {
        $markdown += "### Frontend`n"
        $markdown += "$($TechStack.frontend)`n`n"
    }

    # Backend
    if ($TechStack.backend) {
        $markdown += "### Backend`n"
        $markdown += "$($TechStack.backend)`n`n"
    }

    # Database
    if ($TechStack.database) {
        $markdown += "### Database`n"
        $markdown += "$($TechStack.database)`n`n"
    }

    # Deployment
    if ($TechStack.deployment) {
        $markdown += "### Deployment`n"
        $markdown += "$($TechStack.deployment)`n`n"
    }

    # If all empty
    if (-not $TechStack.frontend -and -not $TechStack.backend -and -not $TechStack.database -and -not $TechStack.deployment) {
        $markdown += "Tech stack not documented yet. Run `/init-project` to generate.`n`n"
    }

    $markdown += @"
## Common Patterns

"@

    if ($Patterns.Count -eq 0) {
        $markdown += "No common patterns discovered yet. Patterns are extracted during feature implementation.`n"
    }
    else {
        foreach ($pattern in $Patterns) {
            $markdown += "- **$($pattern.name)** - ``$($pattern.path)```n"
        }
    }

    $markdown += @"

## Quick Links

**Project Documentation**:
- [Overview](docs/project/overview.md) - Vision, users, scope
- [System Architecture](docs/project/system-architecture.md) - C4 diagrams, components
- [Tech Stack](docs/project/tech-stack.md) - Technology choices (full details)
- [Data Architecture](docs/project/data-architecture.md) - ERD, schemas
- [API Strategy](docs/project/api-strategy.md) - REST/GraphQL patterns
- [Capacity Planning](docs/project/capacity-planning.md) - Scaling tiers
- [Deployment Strategy](docs/project/deployment-strategy.md) - CI/CD pipeline
- [Development Workflow](docs/project/development-workflow.md) - Git flow, PR process
- [Engineering Principles](docs/project/engineering-principles.md) - 8 core standards
- [Project Configuration](docs/project/project-configuration.md) - Deployment model, scale tier

**Features**:
"@

    # List feature CLAUDE.md files
    $specsDir = Join-Path $repoRoot "specs"
    if (Test-Path $specsDir) {
        $featureDirs = Get-ChildItem -Path $specsDir -Directory

        foreach ($featureDir in $featureDirs) {
            $claudeFile = Join-Path $featureDir.FullName "CLAUDE.md"
            if (Test-Path $claudeFile) {
                $markdown += "- [$($featureDir.Name)](specs/$($featureDir.Name)/CLAUDE.md)`n"
            }
        }
    }

    $markdown += @"

---

*This file is auto-generated. Do not edit manually. Regenerate with:*
``````bash
.spec-flow/scripts/bash/generate-project-claude-md.sh
``````
"@

    return $markdown
}

# Main execution
Write-Host "[spec-flow] Generating project-level CLAUDE.md..." -ForegroundColor Cyan

# Gather data
$activeFeatures = Find-ActiveFeatures
$techStack = Get-TechStackSummary
$patterns = Get-CommonPatterns

# Generate output
if ($Json) {
    $output = @{
        active_features = $activeFeatures
        tech_stack      = $techStack
        common_patterns = $patterns
    }
    $output | ConvertTo-Json -Depth 5
}
else {
    $markdown = New-MarkdownOutput -ActiveFeatures $activeFeatures -TechStack $techStack -Patterns $patterns
    Set-Content -Path $OutputFile -Value $markdown -NoNewline
    Write-Host "[spec-flow] Generated project CLAUDE.md at $OutputFile" -ForegroundColor Green
}


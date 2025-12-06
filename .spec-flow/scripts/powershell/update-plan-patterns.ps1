#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update plan.md Discovered Patterns section

.DESCRIPTION
    Updates plan.md with reuse additions, architecture adjustments, or integration discoveries.

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.PARAMETER Type
    Type of update: reuse | architecture | integration

.PARAMETER Data
    Hashtable with update data

.EXAMPLE
    .\update-plan-patterns.ps1 -FeatureDir "specs/001-auth" -Type reuse -Data @{name="UserService.create_user()"; path="api/src/services/user.py:42-58"; task="T013"; purpose="User creation"; reusable="Any endpoint"; why="New code"}

.EXAMPLE
    .\update-plan-patterns.ps1 -FeatureDir "specs/001-auth" -Type architecture -Data @{change="Added last_login"; original="Basic fields"; actual="Added timestamp"; reason="Timeout tracking"; migration="005_add_last_login.py"; impact="Minor"}

.EXAMPLE
    .\update-plan-patterns.ps1 -FeatureDir "specs/001-auth" -Type integration -Data @{name="Email webhook"; component="Registration"; dependency="Clerk"; reason="Clerk handles it"; resolution="Added handler"}
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir,

    [Parameter(Mandatory)]
    [ValidateSet("reuse", "architecture", "integration")]
    [string]$Type,

    [Parameter(Mandatory)]
    [hashtable]$Data
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$planFile = Join-Path $FeatureDir "plan.md"

if (-not (Test-Path $planFile)) {
    throw "No plan.md found in $FeatureDir"
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$content = Get-Content $planFile -Raw

switch ($Type) {
    "reuse" {
        $name = $Data.name
        $path = $Data.path
        $task = $Data.task
        $purpose = $Data.purpose
        $reusable = $Data.reusable
        $why = $Data.why

        $entry = @"
- ✅ **$name** (``$path``)
  - **Discovered in**: $task
  - **Purpose**: $purpose
  - **Reusable for**: $reusable
  - **Why not in Phase 0**: $why
"@

        # Find Reuse Additions section and append
        if ($content -match "\*\*Format\*\*: Document patterns discovered during implementation") {
            $content = $content -replace "(\*\*Format\*\*: Document patterns discovered during implementation[^\n]*\r?\n)", "`$1`n$entry`n"
            Set-Content $planFile $content -NoNewline
            Write-Host "[spec-flow] Added reuse pattern $name to plan.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Reuse Additions' section found in plan.md"
        }
    }

    "architecture" {
        $change = $Data.change
        $original = $Data.original
        $actual = $Data.actual
        $reason = $Data.reason
        $migration = $Data.migration
        $impact = if ($Data.impact) { $Data.impact } else { "Minor" }

        $entry = @"
- **$change**: Architecture adjustment
  - **Original design**: $original
  - **Actual implementation**: $actual
  - **Reason**: $reason
"@

        if ($migration) {
            $entry += "`n  - **Migration**: ``$migration``"
        }

        $entry += "`n  - **Impact**: $impact"

        # Find Architecture Adjustments section and append
        if ($content -match "\*\*Format\*\*: Document when actual architecture differs") {
            $content = $content -replace "(\*\*Format\*\*: Document when actual architecture differs[^\n]*\r?\n)", "`$1`n$entry`n"
            Set-Content $planFile $content -NoNewline
            Write-Host "[spec-flow] Added architecture adjustment to plan.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Architecture Adjustments' section found in plan.md"
        }
    }

    "integration" {
        $name = $Data.name
        $component = $Data.component
        $dependency = $Data.dependency
        $reason = $Data.reason
        $resolution = $Data.resolution

        $entry = @"
- **$name**: Integration discovery
  - **Component**: $component
  - **Dependency**: $dependency
  - **Reason**: $reason
  - **Resolution**: $resolution
"@

        # Find Integration Discoveries section and append
        if ($content -match "\*\*Format\*\*: Document unexpected integrations") {
            $content = $content -replace "(\*\*Format\*\*: Document unexpected integrations[^\n]*\r?\n)", "`$1`n$entry`n"
            Set-Content $planFile $content -NoNewline
            Write-Host "[spec-flow] Added integration discovery to plan.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Integration Discoveries' section found in plan.md"
        }
    }
}

# Update Last Updated timestamp
$content = Get-Content $planFile -Raw
$content = $content -replace "> \*\*Last Updated\*\*:.*", "> **Last Updated**: $timestamp"
Set-Content $planFile $content -NoNewline

Write-Host "[spec-flow] Updated plan.md Discovered Patterns ($Type)" -ForegroundColor Cyan


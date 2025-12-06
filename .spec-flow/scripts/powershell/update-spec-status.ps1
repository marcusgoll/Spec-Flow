#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Update spec.md Implementation Status section

.DESCRIPTION
    Updates spec.md with requirements fulfillment, deviations, or performance actuals.

.PARAMETER FeatureDir
    Path to feature directory (e.g., specs/001-auth-flow)

.PARAMETER Type
    Type of update: requirement | deviation | performance

.PARAMETER Data
    Hashtable with update data

.EXAMPLE
    .\update-spec-status.ps1 -FeatureDir "specs/001-auth" -Type requirement -Data @{id="FR-001"; status="fulfilled"; tasks="T001-T003"}

.EXAMPLE
    .\update-spec-status.ps1 -FeatureDir "specs/001-auth" -Type deviation -Data @{id="FR-004"; name="Email verification"; original="Postmark"; actual="SendGrid"; reason="Cost"; impact="Minor"}

.EXAMPLE
    .\update-spec-status.ps1 -FeatureDir "specs/001-auth" -Type performance -Data @{metric="FCP"; target="<1.5s"; actual="1.2s"; status="pass"}
#>

param(
    [Parameter(Mandatory)]
    [string]$FeatureDir,

    [Parameter(Mandatory)]
    [ValidateSet("requirement", "deviation", "performance")]
    [string]$Type,

    [Parameter(Mandatory)]
    [hashtable]$Data
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$specFile = Join-Path $FeatureDir "spec.md"

if (-not (Test-Path $specFile)) {
    throw "No spec.md found in $FeatureDir"
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$content = Get-Content $specFile -Raw

switch ($Type) {
    "requirement" {
        $reqId = $Data.id
        $status = if ($Data.status) { $Data.status } else { "fulfilled" }
        $tasks = $Data.tasks
        $description = if ($Data.description) { $Data.description } else { $reqId }

        # Determine emoji
        $emoji = switch ($status) {
            "fulfilled" { "✅" }
            "deferred" { "⚠️" }
            "descoped" { "❌" }
            default { "⚠️" }
        }

        $entry = "- $emoji **$reqId**: $description - Implemented in tasks $tasks"

        # Find Requirements Fulfilled section and append
        if ($content -match "### Requirements Fulfilled") {
            $content = $content -replace "(### Requirements Fulfilled\r?\n)", "`$1`n$entry`n"
            Set-Content $specFile $content -NoNewline
            Write-Host "[spec-flow] Added requirement $reqId to spec.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Requirements Fulfilled' section found in spec.md"
        }
    }

    "deviation" {
        $reqId = $Data.id
        $name = $Data.name
        $original = $Data.original
        $actual = $Data.actual
        $reason = $Data.reason
        $impact = if ($Data.impact) { $Data.impact } else { "Minor" }

        $entry = @"
- **Requirement $reqId ($name)**: Changed from $original to $actual
  - **Original approach**: $original
  - **Actual implementation**: $actual
  - **Reason**: $reason
  - **Impact**: $impact
"@

        # Find Deviations section and append
        if ($content -match "\*\*Format\*\*: Document when implementation differs") {
            $content = $content -replace "(\*\*Format\*\*: Document when implementation differs[^\n]*\r?\n)", "`$1`n$entry`n"
            Set-Content $specFile $content -NoNewline
            Write-Host "[spec-flow] Added deviation for $reqId to spec.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Deviations from Spec' section found in spec.md"
        }
    }

    "performance" {
        $metric = $Data.metric
        $target = $Data.target
        $actual = $Data.actual
        $statusVal = if ($Data.status) { $Data.status } else { "pass" }
        $notes = if ($Data.notes) { $Data.notes } else { "-" }

        # Determine status emoji
        $statusEmoji = switch ($statusVal) {
            "pass" { "✅ Pass" }
            "warning" { "⚠️ Warning" }
            "fail" { "❌ Fail" }
            default { "⚠️ Warning" }
        }

        $row = "| $metric | $target | $actual | $statusEmoji | $notes |"

        # Find Performance Actuals table and append
        if ($content -match "\| Metric \| Target \| Actual \| Status \| Notes \|") {
            $content = $content -replace "(\| Metric \| Target \| Actual \| Status \| Notes \|\r?\n)", "`$1$row`n"
            Set-Content $specFile $content -NoNewline
            Write-Host "[spec-flow] Added performance metric $metric to spec.md" -ForegroundColor Green
        }
        else {
            Write-Warning "No 'Performance Actuals vs Targets' section found in spec.md"
        }
    }
}

# Update Last Updated timestamp
$content = Get-Content $specFile -Raw
$content = $content -replace "> \*\*Last Updated\*\*:.*", "> **Last Updated**: $timestamp"
Set-Content $specFile $content -NoNewline

Write-Host "[spec-flow] Updated spec.md Implementation Status ($Type)" -ForegroundColor Cyan


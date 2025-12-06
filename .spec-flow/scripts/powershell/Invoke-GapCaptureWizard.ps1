<#
.SYNOPSIS
    Interactive wizard for capturing discovered implementation gaps during validation phases.

.DESCRIPTION
    Guides users through gap discovery process with:
    1. Gap description collection
    2. Source/priority/subsystem prompts
    3. Automatic scope validation against spec
    4. gaps.md and scope-validation-report.md generation
    5. Supplemental task generation for in-scope gaps
    6. Workflow state updates

.PARAMETER FeatureSlug
    Feature or epic slug (e.g., "001-user-authentication")

.PARAMETER WorkflowType
    "epic" or "feature"

.PARAMETER CurrentIteration
    Current iteration number (default: 1)

.PARAMETER BatchMode
    Capture multiple gaps in one session

.EXAMPLE
    Invoke-GapCaptureWizard -FeatureSlug "001-auth" -WorkflowType "epic" -CurrentIteration 1

.OUTPUTS
    Generates:
    - gaps.md
    - scope-validation-report.md
    - Updates state.yaml
    - Appends supplemental tasks to tasks.md (if gaps are in-scope)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureSlug,

    [Parameter(Mandatory = $true)]
    [ValidateSet("epic", "feature")]
    [string]$WorkflowType,

    [Parameter(Mandatory = $false)]
    [int]$CurrentIteration = 1,

    [Parameter(Mandatory = $false)]
    [switch]$BatchMode
)

# Import validation script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\Invoke-ScopeValidation.ps1"

function Show-Banner {
    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "    Gap Discovery Wizard" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`n"
}

function Get-UserInput {
    param(
        [string]$Prompt,
        [string[]]$ValidOptions = $null,
        [bool]$Required = $true
    )

    do {
        Write-Host $Prompt -ForegroundColor Yellow -NoNewline
        if ($ValidOptions) {
            Write-Host " [$($ValidOptions -join '/')]" -ForegroundColor Gray -NoNewline
        }
        Write-Host ": " -NoNewline

        $input = Read-Host

        if ([string]::IsNullOrWhiteSpace($input) -and $Required) {
            Write-Host "  This field is required. Please provide a value." -ForegroundColor Red
            continue
        }

        if ($ValidOptions -and $input -notin $ValidOptions) {
            Write-Host "  Invalid option. Please choose from: $($ValidOptions -join ', ')" -ForegroundColor Red
            continue
        }

        return $input
    } while ($true)
}

function Get-MultiSelectInput {
    param(
        [string]$Prompt,
        [string[]]$Options
    )

    Write-Host "`n$Prompt" -ForegroundColor Yellow
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$i] $($Options[$i])"
    }
    Write-Host "`nEnter numbers separated by commas (e.g., 0,2,3): " -NoNewline -ForegroundColor Gray

    $input = Read-Host
    $selectedIndices = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }

    $selected = @()
    foreach ($index in $selectedIndices) {
        if ($index -lt $Options.Count) {
            $selected += $Options[$index]
        }
    }

    return $selected
}

function Capture-GapDetails {
    Write-Host "`nDescribe the discovered gap (be specific):" -ForegroundColor Yellow
    Write-Host "  Example: 'Missing /v1/auth/me endpoint for fetching current user profile'" -ForegroundColor Gray
    $description = Read-Host "  Gap"

    Write-Host "`nWhere was this requirement mentioned?" -ForegroundColor Yellow
    Write-Host "  Example: 'epic-spec.md:45-50' or 'implicit requirement'" -ForegroundColor Gray
    $source = Read-Host "  Source"

    $priority = Get-UserInput -Prompt "`nPriority" -ValidOptions @("P1", "P2", "P3")

    Write-Host "`nP1 = Blocking (prevents feature from working)" -ForegroundColor Gray
    Write-Host "P2 = Important (degrades UX but workaround exists)" -ForegroundColor Gray
    Write-Host "P3 = Nice to have (enhancement)" -ForegroundColor Gray

    $subsystems = Get-MultiSelectInput -Prompt "What subsystems does this affect?" -Options @(
        "Backend API",
        "Frontend UI",
        "Database",
        "Infrastructure",
        "Testing",
        "Documentation"
    )

    Write-Host "`nAdditional context (optional):" -ForegroundColor Yellow
    $context = Read-Host "  Context"

    return [PSCustomObject]@{
        Description = $description
        Source      = $source
        Priority    = $priority
        Subsystems  = $subsystems
        Context     = $context
    }
}

function Generate-GapId {
    param([int]$Index)
    return "GAP{0:D3}" -f $Index
}

try {
    Show-Banner

    # Determine base directory and spec path
    $baseDir = if ($WorkflowType -eq "epic") { "epics" } else { "specs" }
    $featureDir = Join-Path $baseDir $FeatureSlug
    $specPath = Join-Path $featureDir (if ($WorkflowType -eq "epic") { "epic-spec.md" } else { "spec.md" })

    if (-not (Test-Path $specPath)) {
        throw "Spec file not found: $specPath"
    }

    Write-Host "Epic/Feature: " -NoNewline -ForegroundColor Cyan
    Write-Host $FeatureSlug
    Write-Host "Iteration: " -NoNewline -ForegroundColor Cyan
    Write-Host ($CurrentIteration + 1)
    Write-Host "`n"

    # Collect gaps
    $gaps = @()
    $gapIndex = 1

    do {
        Write-Host "━━━ Gap $gapIndex ━━━" -ForegroundColor Cyan
        $gapDetails = Capture-GapDetails

        # Validate scope
        Write-Host "`nValidating scope..." -ForegroundColor Yellow
        $validation = Invoke-ScopeValidation -GapDescription $gapDetails.Description -SpecPath $specPath -VerboseOutput

        # Create gap object
        $gap = [PSCustomObject]@{
            Id             = Generate-GapId -Index $gapIndex
            Title          = $gapDetails.Description.Split('.')[0]  # First sentence as title
            Description    = $gapDetails.Description
            Source         = $gapDetails.Source
            Priority       = $gapDetails.Priority
            Subsystems     = $gapDetails.Subsystems
            Context        = $gapDetails.Context
            ScopeStatus    = $validation.Status
            Evidence       = $validation.Evidence
            Reason         = $validation.Reason
            Recommendation = $validation.Recommendation
            Checks         = $validation.Checks
            SpecExcerpts   = $validation.SpecExcerpts
        }

        $gaps += $gap
        $gapIndex++

        # Show result
        Write-Host "`n"
        switch ($gap.ScopeStatus) {
            "IN_SCOPE" {
                Write-Host "✅ IN SCOPE - Will generate supplemental tasks" -ForegroundColor Green
            }
            "OUT_OF_SCOPE" {
                Write-Host "❌ OUT OF SCOPE - Blocked as feature creep" -ForegroundColor Red
            }
            "AMBIGUOUS" {
                Write-Host "⚠️ AMBIGUOUS - User decision required" -ForegroundColor Yellow
            }
        }

        if ($BatchMode) {
            $continue = Get-UserInput -Prompt "`nCapture another gap?" -ValidOptions @("y", "n") -Required $true
            if ($continue -eq "n") {
                break
            }
        }
        else {
            break
        }
    } while ($true)

    # Generate summary
    $inScopeCount = ($gaps | Where-Object { $_.ScopeStatus -eq "IN_SCOPE" }).Count
    $outOfScopeCount = ($gaps | Where-Object { $_.ScopeStatus -eq "OUT_OF_SCOPE" }).Count
    $ambiguousCount = ($gaps | Where-Object { $_.ScopeStatus -eq "AMBIGUOUS" }).Count

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Summary" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Total Gaps: " -NoNewline
    Write-Host $gaps.Count
    Write-Host "In Scope: " -NoNewline -ForegroundColor Green
    Write-Host "$inScopeCount ✅"
    Write-Host "Out of Scope: " -NoNewline -ForegroundColor Red
    Write-Host "$outOfScopeCount ❌"
    Write-Host "Ambiguous: " -NoNewline -ForegroundColor Yellow
    Write-Host "$ambiguousCount ⚠️"
    Write-Host "`n"

    # Generate gaps.md
    Write-Host "Generating gaps.md..." -ForegroundColor Yellow
    $gapsPath = Join-Path $featureDir "gaps.md"
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $userName = $env:USERNAME

    $gapsContent = @"
# Implementation Gaps

**Epic/Feature**: $FeatureSlug
**Iteration**: $($CurrentIteration + 1)
**Discovered At**: validate-staging phase
**Discovered By**: $userName
**Timestamp**: $timestamp

---

"@

    foreach ($gap in $gaps) {
        $scopeIcon = switch ($gap.ScopeStatus) {
            "IN_SCOPE" { "✅" }
            "OUT_OF_SCOPE" { "❌" }
            "AMBIGUOUS" { "⚠️" }
        }

        $gapsContent += @"

## $($gap.Id): $($gap.Title)

**Source**: $($gap.Source)
**Priority**: $($gap.Priority)
**Scope Status**: $scopeIcon $($gap.ScopeStatus)
**Subsystems**: $($gap.Subsystems -join ', ')

### Description

$($gap.Description)

### Scope Validation

$($gap.Evidence -join "`n")

### Impact

$($gap.Context)

### Recommendation

$($gap.Recommendation)

---

"@
    }

    $gapsContent += @"

## Summary

- **Total Gaps**: $($gaps.Count)
- **In Scope**: $inScopeCount ✅
- **Out of Scope**: $outOfScopeCount ❌
- **Ambiguous**: $ambiguousCount ⚠️

"@

    if ($inScopeCount -gt 0) {
        $gapsContent += @"

### Next Steps

1. Review generated supplemental tasks in tasks.md
2. Run ``/$WorkflowType continue`` to execute iteration $($CurrentIteration + 1)
3. Re-validate after implementation completes

"@
    }

    Set-Content -Path $gapsPath -Value $gapsContent -Encoding UTF8
    Write-Host "✓ Created: $gapsPath" -ForegroundColor Green

    # Generate scope-validation-report.md
    Write-Host "Generating scope-validation-report.md..." -ForegroundColor Yellow
    $reportPath = Join-Path $featureDir "scope-validation-report.md"

    $reportContent = @"
# Scope Validation Report

**Epic/Feature**: $FeatureSlug
**Iteration**: $($CurrentIteration + 1)
**Validated At**: $timestamp
**Spec Source**: $specPath

---

## Validation Summary

- **Total Gaps Discovered**: $($gaps.Count)
- **In Scope**: $inScopeCount ✅
- **Out of Scope**: $outOfScopeCount ❌
- **Ambiguous**: $ambiguousCount ⚠️

---

"@

    foreach ($gap in $gaps) {
        $statusColor = switch ($gap.ScopeStatus) {
            "IN_SCOPE" { "✅" }
            "OUT_OF_SCOPE" { "❌" }
            "AMBIGUOUS" { "⚠️" }
        }

        $reportContent += @"

## $($gap.Id): $($gap.Title)

**Status**: $statusColor $($gap.ScopeStatus)

### Evidence Analysis

$($gap.Evidence -join "`n")

### Validation Result

$($gap.Reason)

### Recommendation

$($gap.Recommendation)

---

"@
    }

    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    Write-Host "✓ Created: $reportPath" -ForegroundColor Green

    # Return gap data for downstream processing
    return [PSCustomObject]@{
        Gaps            = $gaps
        InScopeCount    = $inScopeCount
        OutOfScopeCount = $outOfScopeCount
        AmbiguousCount  = $ambiguousCount
        GapsPath        = $gapsPath
        ReportPath      = $reportPath
    }
}
catch {
    Write-Error "Gap capture wizard failed: $_"
    throw
}


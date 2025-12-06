<#
.SYNOPSIS
    Validates if a discovered gap is within the original scope of an epic or feature.

.DESCRIPTION
    Analyzes a gap description against the original spec (epic-spec.md or spec.md) to determine
    if the gap represents in-scope work that was missed or out-of-scope feature creep.

    Validation Algorithm:
    1. Check if gap is mentioned in Objective/Requirements sections
    2. Check if gap is explicitly excluded in "Out of Scope" section
    3. Check if gap aligns with involved subsystems
    4. Check if gap relates to acceptance criteria

    Returns: IN_SCOPE | OUT_OF_SCOPE | AMBIGUOUS

.PARAMETER GapDescription
    Description of the discovered gap (e.g., "Missing /v1/auth/me endpoint")

.PARAMETER SpecPath
    Path to the spec file (epic-spec.md or spec.md)

.PARAMETER GapKeywords
    Array of keywords extracted from gap description for matching

.PARAMETER Verbose
    Show detailed validation reasoning

.EXAMPLE
    Invoke-ScopeValidation -GapDescription "Missing /v1/auth/me endpoint" -SpecPath "epics/001-auth/epic-spec.md"

.OUTPUTS
    PSCustomObject with properties:
    - Status: "IN_SCOPE" | "OUT_OF_SCOPE" | "AMBIGUOUS"
    - Reason: Explanation of validation result
    - Evidence: Array of evidence items
    - Recommendation: Suggested action
    - Checks: Results of each validation check
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GapDescription,

    [Parameter(Mandatory = $true)]
    [string]$SpecPath,

    [Parameter(Mandatory = $false)]
    [string[]]$GapKeywords,

    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

function Extract-Section {
    <#
    .SYNOPSIS
        Extracts a markdown section from spec file
    #>
    param(
        [string]$Content,
        [string]$SectionHeader
    )

    # Match section header and capture content until next header of same level
    $pattern = "(?ms)^#{1,3}\s+$SectionHeader\s*`$(.*?)(?=^#{1,3}\s+|\z)"

    if ($Content -match $pattern) {
        return $matches[1].Trim()
    }

    return ""
}

function Extract-Keywords {
    <#
    .SYNOPSIS
        Extracts meaningful keywords from gap description
    #>
    param([string]$Text)

    # Remove common words and extract technical terms
    $stopWords = @('the', 'a', 'an', 'is', 'was', 'are', 'were', 'for', 'to', 'in', 'on', 'at', 'of', 'with')

    $words = $Text -split '\s+|/' | Where-Object {
        $_.Length -gt 2 -and $_ -notin $stopWords
    }

    return $words
}

function Check-Mentioned {
    <#
    .SYNOPSIS
        Checks if gap keywords are mentioned in spec section
    #>
    param(
        [string]$SectionContent,
        [string[]]$Keywords
    )

    if ([string]::IsNullOrWhiteSpace($SectionContent)) {
        return $false
    }

    $matchCount = 0
    $totalKeywords = $Keywords.Count

    foreach ($keyword in $Keywords) {
        if ($SectionContent -match [regex]::Escape($keyword)) {
            $matchCount++
        }
    }

    # Require at least 30% keyword match
    $matchPercentage = if ($totalKeywords -gt 0) { ($matchCount / $totalKeywords) * 100 } else { 0 }

    return $matchPercentage -ge 30
}

# Main validation logic
try {
    Write-Verbose "Starting scope validation for gap: $GapDescription"
    Write-Verbose "Spec path: $SpecPath"

    # Read spec file
    if (-not (Test-Path $SpecPath)) {
        throw "Spec file not found: $SpecPath"
    }

    $specContent = Get-Content -Path $SpecPath -Raw

    # Extract keywords from gap description
    if (-not $GapKeywords) {
        $GapKeywords = Extract-Keywords -Text $GapDescription
    }
    Write-Verbose "Gap keywords: $($GapKeywords -join ', ')"

    # Extract spec sections
    $objective = Extract-Section -Content $specContent -SectionHeader "Objective"
    $outOfScope = Extract-Section -Content $specContent -SectionHeader "Out of Scope"
    $subsystems = Extract-Section -Content $specContent -SectionHeader "Subsystems"
    $acceptanceCriteria = Extract-Section -Content $specContent -SectionHeader "Acceptance Criteria"

    # If no "Objective" section, try "User Stories" or "Requirements"
    if ([string]::IsNullOrWhiteSpace($objective)) {
        $objective = Extract-Section -Content $specContent -SectionHeader "User Stories"
    }
    if ([string]::IsNullOrWhiteSpace($objective)) {
        $objective = Extract-Section -Content $specContent -SectionHeader "Requirements"
    }

    Write-Verbose "Extracted sections - Objective: $($objective.Length) chars, Out of Scope: $($outOfScope.Length) chars"

    # Initialize validation checks
    $checks = @{
        ObjectiveMentioned        = $false
        NotExcluded               = $true
        SubsystemAlignment        = $false
        AcceptanceCriteriaRelated = $false
    }

    $evidence = @()

    # Check 1: Mentioned in Objective/Requirements?
    $checks.ObjectiveMentioned = Check-Mentioned -SectionContent $objective -Keywords $GapKeywords
    if ($checks.ObjectiveMentioned) {
        $evidence += "✅ Gap mentioned in objective/requirements section"
    }
    else {
        $evidence += "❌ Gap not explicitly mentioned in objective/requirements"
    }

    # Check 2: Listed in "Out of Scope"?
    if (-not [string]::IsNullOrWhiteSpace($outOfScope)) {
        $isExcluded = Check-Mentioned -SectionContent $outOfScope -Keywords $GapKeywords
        $checks.NotExcluded = -not $isExcluded

        if ($checks.NotExcluded) {
            $evidence += "✅ NOT listed in 'Out of Scope' section"
        }
        else {
            $evidence += "❌ Explicitly excluded in 'Out of Scope' section"
        }
    }
    else {
        $evidence += "✅ No 'Out of Scope' section found (default: not excluded)"
    }

    # Check 3: Aligns with Subsystems?
    if (-not [string]::IsNullOrWhiteSpace($subsystems)) {
        $checks.SubsystemAlignment = Check-Mentioned -SectionContent $subsystems -Keywords $GapKeywords

        if ($checks.SubsystemAlignment) {
            $evidence += "✅ Aligns with involved subsystems"
        }
        else {
            $evidence += "⚠️ May not align with documented subsystems"
        }
    }
    else {
        # If no subsystems section, assume alignment (default for features)
        $checks.SubsystemAlignment = $true
        $evidence += "✅ No subsystems section (assuming alignment)"
    }

    # Check 4: Related to Acceptance Criteria?
    if (-not [string]::IsNullOrWhiteSpace($acceptanceCriteria)) {
        $checks.AcceptanceCriteriaRelated = Check-Mentioned -SectionContent $acceptanceCriteria -Keywords $GapKeywords

        if ($checks.AcceptanceCriteriaRelated) {
            $evidence += "✅ Related to acceptance criteria"
        }
        else {
            $evidence += "⚠️ Not directly related to acceptance criteria"
        }
    }
    else {
        $evidence += "⚠️ No acceptance criteria section found"
    }

    # Determine scope status
    $status = "AMBIGUOUS"
    $reason = ""
    $recommendation = ""

    # Rule 1: If explicitly excluded -> OUT OF SCOPE
    if (-not $checks.NotExcluded) {
        $status = "OUT_OF_SCOPE"
        $reason = "Gap is explicitly listed in 'Out of Scope' section. This represents feature creep and should be deferred to a new epic."
        $recommendation = "Create new epic/feature for this functionality after current work completes"
    }
    # Rule 2: If all checks pass -> IN SCOPE
    elseif ($checks.ObjectiveMentioned -and $checks.NotExcluded -and $checks.SubsystemAlignment -and $checks.AcceptanceCriteriaRelated) {
        $status = "IN_SCOPE"
        $reason = "All validation checks passed. Gap represents functionality defined in original spec but not implemented."
        $recommendation = "Generate supplemental tasks for implementation in current iteration"
    }
    # Rule 3: If checks 2, 3, 4 pass (implicit requirement) -> IN SCOPE
    elseif ($checks.NotExcluded -and $checks.SubsystemAlignment -and $checks.AcceptanceCriteriaRelated) {
        $status = "IN_SCOPE"
        $reason = "Gap passes subsystem and acceptance criteria checks. Likely an implicit requirement from the original spec."
        $recommendation = "Generate supplemental tasks for implementation in current iteration"
    }
    # Rule 4: If major misalignment -> OUT OF SCOPE
    elseif (-not $checks.SubsystemAlignment -and -not $checks.AcceptanceCriteriaRelated) {
        $status = "OUT_OF_SCOPE"
        $reason = "Gap does not align with documented subsystems or acceptance criteria. Represents new functionality beyond original scope."
        $recommendation = "Create new epic/feature for this functionality"
    }
    # Rule 5: Otherwise -> AMBIGUOUS
    else {
        $status = "AMBIGUOUS"
        $reason = "Mixed validation results. Gap not explicitly mentioned or excluded. User decision required."
        $recommendation = "User should decide based on project priorities and timeline constraints"
    }

    # Return validation result
    $result = [PSCustomObject]@{
        Status         = $status
        Reason         = $reason
        Evidence       = $evidence
        Recommendation = $recommendation
        Checks         = $checks
        SpecExcerpts   = @{
            Objective          = if ($objective.Length -gt 500) { $objective.Substring(0, 500) + "..." } else { $objective }
            OutOfScope         = if ($outOfScope.Length -gt 500) { $outOfScope.Substring(0, 500) + "..." } else { $outOfScope }
            Subsystems         = if ($subsystems.Length -gt 500) { $subsystems.Substring(0, 500) + "..." } else { $subsystems }
            AcceptanceCriteria = if ($acceptanceCriteria.Length -gt 500) { $acceptanceCriteria.Substring(0, 500) + "..." } else { $acceptanceCriteria }
        }
    }

    if ($VerboseOutput) {
        Write-Host "`n=== Scope Validation Result ===" -ForegroundColor Cyan
        Write-Host "Status: " -NoNewline
        switch ($result.Status) {
            "IN_SCOPE" { Write-Host $result.Status -ForegroundColor Green }
            "OUT_OF_SCOPE" { Write-Host $result.Status -ForegroundColor Red }
            "AMBIGUOUS" { Write-Host $result.Status -ForegroundColor Yellow }
        }
        Write-Host "`nReason: $($result.Reason)"
        Write-Host "`nEvidence:"
        $result.Evidence | ForEach-Object { Write-Host "  $_" }
        Write-Host "`nRecommendation: $($result.Recommendation)" -ForegroundColor Cyan
        Write-Host "==============================`n"
    }

    return $result
}
catch {
    Write-Error "Scope validation failed: $_"
    throw
}


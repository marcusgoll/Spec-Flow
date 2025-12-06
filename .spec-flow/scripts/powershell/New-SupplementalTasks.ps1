<#
.SYNOPSIS
    Generates supplemental tasks for in-scope gaps and appends them to tasks.md.

.DESCRIPTION
    Reads gaps.md to extract in-scope gaps and generates:
    1. Implementation tasks for each gap
    2. Test tasks (unit/integration) for each gap
    3. Documentation tasks (if applicable)

    Tasks are appended to existing tasks.md with iteration marker and smart dependency detection.

.PARAMETER FeatureSlug
    Feature or epic slug

.PARAMETER WorkflowType
    "epic" or "feature"

.PARAMETER Iteration
    Iteration number for supplemental tasks

.PARAMETER GapsPath
    Path to gaps.md file (optional, auto-detected if not provided)

.EXAMPLE
    New-SupplementalTasks -FeatureSlug "001-auth" -WorkflowType "epic" -Iteration 2

.OUTPUTS
    Returns PSCustomObject with:
    - TasksGenerated: Count of tasks created
    - TaskIds: Array of task IDs
    - TasksPath: Path to updated tasks.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FeatureSlug,

    [Parameter(Mandatory = $true)]
    [ValidateSet("epic", "feature")]
    [string]$WorkflowType,

    [Parameter(Mandatory = $true)]
    [int]$Iteration,

    [Parameter(Mandatory = $false)]
    [string]$GapsPath
)

function Get-NextTaskId {
    param([string]$TasksContent)

    # Extract all task IDs (format: T001, T002, etc.)
    $taskIds = [regex]::Matches($TasksContent, 'T(\d{3})') | ForEach-Object { [int]$_.Groups[1].Value }

    if ($taskIds.Count -eq 0) {
        return 1
    }

    $maxId = ($taskIds | Measure-Object -Maximum).Maximum
    return $maxId + 1
}

function Format-TaskId {
    param([int]$Id)
    return "T{0:D3}" -f $Id
}

function Parse-InScopeGaps {
    param([string]$GapsContent)

    $gaps = @()
    $gapPattern = '(?ms)^## (GAP\d{3}): (.+?)$.*?^\*\*Scope Status\*\*: ✅ IN SCOPE.*?^### Description\s*$(.+?)^### Scope Validation'

    $matches = [regex]::Matches($GapsContent, $gapPattern)

    foreach ($match in $matches) {
        $gapId = $match.Groups[1].Value
        $title = $match.Groups[2].Value.Trim()
        $description = $match.Groups[3].Value.Trim()

        # Extract source if available
        $sourcePattern = '\*\*Source\*\*: (.+)'
        $sourceMatch = [regex]::Match($match.Value, $sourcePattern)
        $source = if ($sourceMatch.Success) { $sourceMatch.Groups[1].Value.Trim() } else { "gaps.md" }

        # Extract priority
        $priorityPattern = '\*\*Priority\*\*: (P\d)'
        $priorityMatch = [regex]::Match($match.Value, $priorityPattern)
        $priority = if ($priorityMatch.Success) { $priorityMatch.Groups[1].Value } else { "P2" }

        $gaps += [PSCustomObject]@{
            Id          = $gapId
            Title       = $title
            Description = $description
            Source      = $source
            Priority    = $priority
        }
    }

    return $gaps
}

function Detect-TaskDependencies {
    <#
    .SYNOPSIS
        Smart dependency detection based on gap keywords and existing task titles
    #>
    param(
        [string]$GapDescription,
        [string]$TasksContent
    )

    $dependencies = @()

    # Extract keywords from gap
    $keywords = $GapDescription -split '\s+|/' |
        Where-Object { $_.Length -gt 3 } |
        ForEach-Object { $_.Trim().ToLower() }

    # Search for related tasks in existing tasks.md
    $taskPattern = '(?ms)^### (T\d{3}): (.+?)$'
    $taskMatches = [regex]::Matches($TasksContent, $taskPattern)

    foreach ($taskMatch in $taskMatches) {
        $taskId = $taskMatch.Groups[1].Value
        $taskTitle = $taskMatch.Groups[2].Value.ToLower()

        # Check if task title contains any gap keywords
        $matchCount = 0
        foreach ($keyword in $keywords) {
            if ($taskTitle.Contains($keyword)) {
                $matchCount++
            }
        }

        # If 30% or more keywords match, consider it a dependency
        if ($keywords.Count -gt 0 -and ($matchCount / $keywords.Count) -ge 0.3) {
            $dependencies += $taskId
        }
    }

    return $dependencies | Select-Object -Unique
}

function Requires-Tests {
    param([PSCustomObject]$Gap)

    # Gaps affecting Backend API, Database always require tests
    $requiresTests = $Gap.Description -match '(endpoint|API|database|auth|backend|service|query)'

    return $requiresTests
}

function Requires-Documentation {
    param([PSCustomObject]$Gap)

    # API endpoints and new features require documentation
    $requiresDocs = $Gap.Description -match '(endpoint|API|feature|integration)'

    return $requiresDocs
}

try {
    Write-Verbose "Generating supplemental tasks for iteration $Iteration"

    # Determine paths
    $baseDir = if ($WorkflowType -eq "epic") { "epics" } else { "specs" }
    $featureDir = Join-Path $baseDir $FeatureSlug

    if (-not $GapsPath) {
        $GapsPath = Join-Path $featureDir "gaps.md"
    }

    if (-not (Test-Path $GapsPath)) {
        throw "Gaps file not found: $GapsPath"
    }

    $tasksPath = Join-Path $featureDir "tasks.md"
    if (-not (Test-Path $tasksPath)) {
        throw "Tasks file not found: $tasksPath"
    }

    # Read gaps and tasks
    $gapsContent = Get-Content -Path $GapsPath -Raw
    $tasksContent = Get-Content -Path $tasksPath -Raw

    # Parse in-scope gaps
    $inScopeGaps = Parse-InScopeGaps -GapsContent $gapsContent
    Write-Host "Found $($inScopeGaps.Count) in-scope gaps" -ForegroundColor Cyan

    if ($inScopeGaps.Count -eq 0) {
        Write-Host "No in-scope gaps to generate tasks for" -ForegroundColor Yellow
        return [PSCustomObject]@{
            TasksGenerated = 0
            TaskIds        = @()
            TasksPath      = $tasksPath
        }
    }

    # Get next task ID
    $nextTaskId = Get-NextTaskId -TasksContent $tasksContent
    $allTaskIds = @()

    # Build supplemental tasks section
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $supplementalContent = @"

---

## Iteration ${Iteration}: Gap Closure

**Batch**: Implementation Gaps
**Source**: gaps.md (discovered during validate-staging)
**Status**: Pending
**Started**: $timestamp

---

"@

    foreach ($gap in $inScopeGaps) {
        Write-Host "  Generating tasks for $($gap.Id): $($gap.Title)" -ForegroundColor Gray

        # Detect dependencies
        $dependencies = Detect-TaskDependencies -GapDescription $gap.Description -TasksContent $tasksContent
        $dependsOnText = if ($dependencies.Count -gt 0) {
            "**Depends On**: $($dependencies -join ', ')"
        }
        else {
            "**Depends On**: None"
        }

        # Implementation task
        $implTaskId = Format-TaskId -Id $nextTaskId
        $allTaskIds += $implTaskId
        $nextTaskId++

        $supplementalContent += @"

### $implTaskId`: Implement $($gap.Title)

$dependsOnText
**Source**: $($gap.Source), gaps.md:$($gap.Id)
**Priority**: $($gap.Priority)
**Iteration**: $Iteration

**Description**:
$($gap.Description)

**Acceptance Criteria**:
- [ ] Implementation complete and working
- [ ] No regressions in existing functionality
- [ ] Code follows project conventions

**Implementation Notes**:
- This gap was discovered during validate-staging phase (iteration $($Iteration - 1))
- Validated as in-scope against original spec
- Reuse existing patterns and code where possible

---

"@

        # Test task (if applicable)
        if (Requires-Tests -Gap $gap) {
            $testTaskId = Format-TaskId -Id $nextTaskId
            $allTaskIds += $testTaskId
            $nextTaskId++

            $supplementalContent += @"

### $testTaskId`: Add Tests for $($gap.Title)

**Depends On**: $implTaskId
**Source**: gaps.md:$($gap.Id)
**Priority**: $($gap.Priority)
**Iteration**: $Iteration

**Acceptance Criteria**:
- [ ] Unit tests cover core functionality
- [ ] Integration tests validate end-to-end flow
- [ ] Test coverage \u2265 80%
- [ ] All tests pass

**Test Scenarios**:
- Happy path: Verify expected behavior
- Error cases: Validate error handling
- Edge cases: Test boundary conditions

---

"@
        }

        # Documentation task (if applicable)
        if (Requires-Documentation -Gap $gap) {
            $docTaskId = Format-TaskId -Id $nextTaskId
            $allTaskIds += $docTaskId
            $nextTaskId++

            $supplementalContent += @"

### $docTaskId`: Update Documentation for $($gap.Title)

**Depends On**: $implTaskId
**Source**: gaps.md:$($gap.Id)
**Priority**: P2
**Iteration**: $Iteration

**Acceptance Criteria**:
- [ ] API documentation updated (if applicable)
- [ ] README updated with new functionality
- [ ] Code comments added for complex logic
- [ ] Examples provided

---

"@
        }
    }

    # Append to tasks.md
    $updatedTasksContent = $tasksContent.TrimEnd() + "`n" + $supplementalContent
    Set-Content -Path $tasksPath -Value $updatedTasksContent -Encoding UTF8

    Write-Host "`n✓ Generated $($allTaskIds.Count) supplemental tasks" -ForegroundColor Green
    Write-Host "✓ Updated: $tasksPath" -ForegroundColor Green

    return [PSCustomObject]@{
        TasksGenerated = $allTaskIds.Count
        TaskIds        = $allTaskIds
        TasksPath      = $tasksPath
    }
}
catch {
    Write-Error "Supplemental task generation failed: $_"
    throw
}


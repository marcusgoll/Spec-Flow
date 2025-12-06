<#
.SYNOPSIS
    Workflow state management functions for Spec-Flow

.DESCRIPTION
    Provides functions to initialize, update, and query workflow state across
    the entire feature delivery lifecycle. State is stored in state.yaml
    within each feature directory.

    Auto-migrates from JSON to YAML format for backward compatibility.

.NOTES
    Version: 2.1.0 (Timing Functions)
    Author: Spec-Flow Workflow Kit
    Requires: powershell-yaml module (Install-Module -Name powershell-yaml)
#>

# Check for powershell-yaml module
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Warning "powershell-yaml module not found. Installing..."
    Write-Warning "Run: Install-Module -Name powershell-yaml -Scope CurrentUser"
    throw "powershell-yaml module required. Please install it first."
}

Import-Module powershell-yaml

function Test-MigrateJsonToYaml {
    <#
    .SYNOPSIS
        Auto-migrate workflow state from JSON to YAML if needed

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        Test-MigrateJsonToYaml -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    $jsonFile = Join-Path $FeatureDir "workflow-state.json"
    $yamlFile = Join-Path $FeatureDir "state.yaml"

    # If YAML exists, we're good
    if (Test-Path $yamlFile) {
        return $yamlFile
    }

    # If JSON exists, migrate it
    if (Test-Path $jsonFile) {
        Write-Host "🔄 Migrating workflow state from JSON to YAML..." -ForegroundColor Cyan

        $jsonContent = Get-Content $jsonFile -Raw | ConvertFrom-Json -AsHashtable
        $jsonContent | ConvertTo-Yaml | Set-Content -Path $yamlFile -Encoding UTF8

        Write-Host "✅ Migration complete: $yamlFile" -ForegroundColor Green
        Write-Host "📁 Backup preserved: $jsonFile" -ForegroundColor Gray

        return $yamlFile
    }

    # Neither exists - will be created as YAML
    return $yamlFile
}

function Initialize-WorkflowState {
    <#
    .SYNOPSIS
        Initialize workflow state for a new feature

    .PARAMETER FeatureDir
        Path to feature directory (e.g., specs/NNN-slug)

    .PARAMETER Slug
        Feature slug (e.g., NNN-slug)

    .PARAMETER Title
        Feature title

    .PARAMETER BranchName
        Git branch name for this feature

    .EXAMPLE
        Initialize-WorkflowState -FeatureDir "specs/001-login" -Slug "001-login" -Title "User Login" -BranchName "feat/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$BranchName = "local"
    )

    $stateFile = Join-Path $FeatureDir "state.yaml"

    # Detect deployment model
    $deploymentModel = Get-DeploymentModel

    $state = @{
        feature          = @{
            slug           = $Slug
            title          = $Title
            branch_name    = $BranchName
            created        = (Get-Date).ToUniversalTime().ToString("o")
            last_updated   = (Get-Date).ToUniversalTime().ToString("o")
            roadmap_status = "in_progress"  # Options: backlog, next, in_progress, shipped
        }
        deployment_model = $deploymentModel
        workflow         = @{
            phase            = "spec-flow"
            status           = "in_progress"
            completed_phases = @()
            failed_phases    = @()
            manual_gates     = @{}
            phase_timing     = @{}
            metrics          = @{}
        }
        context          = @{
            token_budget = @{
                phase             = "planning"
                budget            = 75000
                estimated_usage   = 0
                compaction_needed = $false
            }
        }
        deployment       = @{
            staging    = @{
                deployed       = $false
                url            = $null
                deployment_ids = @{}
                health_checks  = @{}
            }
            production = @{
                deployed       = $false
                version        = $null
                url            = $null
                deployment_ids = @{}
            }
        }
        artifacts        = @{
            spec                = "specs/$Slug/spec.md"
            plan                = $null
            tasks               = $null
            optimization_report = $null
            staging_validation  = $null
            ship_report         = $null
        }
        quality_gates    = @{}
        metadata         = @{
            schema_version   = "2.1.0"
            workflow_version = "2.1.0"
        }
    }

    # Add YAML comment header
    $yamlHeader = @"
# Spec-Flow Workflow State
# Schema version: 2.0.0
# Created: $((Get-Date).ToUniversalTime().ToString("o"))

"@

    $yamlContent = $yamlHeader + ($state | ConvertTo-Yaml)
    $yamlContent | Set-Content -Path $stateFile -Encoding UTF8
    Write-Host "✅ Workflow state initialized: $stateFile" -ForegroundColor Green
    return $state
}

function Update-WorkflowPhase {
    <#
    .SYNOPSIS
        Update current workflow phase

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Phase
        Phase name (e.g., "plan", "implement", "ship:optimize")

    .PARAMETER Status
        Phase status: in_progress, completed, failed

    .EXAMPLE
        Update-WorkflowPhase -FeatureDir "specs/001-login" -Phase "plan" -Status "completed"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Phase,

        [Parameter(Mandatory = $false)]
        [ValidateSet("in_progress", "completed", "failed")]
        [string]$Status = "completed"
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml

    # Update phase
    if ($Status -eq "completed" -and $state.workflow.completed_phases -notcontains $Phase) {
        $state.workflow.completed_phases += $Phase
    }
    elseif ($Status -eq "failed" -and $state.workflow.failed_phases -notcontains $Phase) {
        $state.workflow.failed_phases += $Phase
    }

    $state.workflow.phase = $Phase
    $state.workflow.status = $Status
    $state.feature.last_updated = (Get-Date).ToUniversalTime().ToString("o")

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Update-DeploymentState {
    <#
    .SYNOPSIS
        Update deployment state for staging or production

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Environment
        Environment name: staging or production

    .PARAMETER DeploymentData
        Hashtable containing deployment details

    .EXAMPLE
        $data = @{
            deployed = $true
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            commit_sha = "abc123"
            run_id = "123456789"
        }
        Update-DeploymentState -FeatureDir "specs/001-login" -Environment "staging" -DeploymentData $data
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [ValidateSet("staging", "production")]
        [string]$Environment,

        [Parameter(Mandatory = $true)]
        [hashtable]$DeploymentData
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml

    # Merge deployment data
    foreach ($key in $DeploymentData.Keys) {
        $state.deployment[$Environment][$key] = $DeploymentData[$key]
    }

    $state.feature.last_updated = (Get-Date).ToUniversalTime().ToString("o")

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Update-DeploymentIds {
    <#
    .SYNOPSIS
        Update deployment IDs for rollback capability

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Environment
        Environment name: staging or production

    .PARAMETER MarketingId
        Vercel deployment ID for marketing site

    .PARAMETER AppId
        Vercel deployment ID for app

    .PARAMETER ApiImage
        Docker image reference for API

    .EXAMPLE
        Update-DeploymentIds -FeatureDir "specs/001-login" -Environment "staging" `
            -MarketingId "marketing-abc123.vercel.app" `
            -AppId "app-def456.vercel.app" `
            -ApiImage "ghcr.io/org/api:sha789"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [ValidateSet("staging", "production")]
        [string]$Environment,

        [Parameter(Mandatory = $false)]
        [string]$MarketingId,

        [Parameter(Mandatory = $false)]
        [string]$AppId,

        [Parameter(Mandatory = $false)]
        [string]$ApiImage
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml

    if ($MarketingId) {
        $state.deployment[$Environment].deployment_ids.marketing = $MarketingId
    }
    if ($AppId) {
        $state.deployment[$Environment].deployment_ids.app = $AppId
    }
    if ($ApiImage) {
        $state.deployment[$Environment].deployment_ids.api = $ApiImage
    }

    $state.feature.last_updated = (Get-Date).ToUniversalTime().ToString("o")

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Update-QualityGate {
    <#
    .SYNOPSIS
        Update quality gate status

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER GateName
        Name of quality gate (e.g., "pre_flight", "code_review", "rollback_capability")

    .PARAMETER GateData
        Hashtable containing gate results

    .EXAMPLE
        $gateData = @{
            passed = $true
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            checks = @{
                build_validation = $true
                docker_image = $true
            }
        }
        Update-QualityGate -FeatureDir "specs/001-login" -GateName "pre_flight" -GateData $gateData
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$GateName,

        [Parameter(Mandatory = $true)]
        [hashtable]$GateData
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml

    $state.quality_gates[$GateName] = $GateData
    $state.feature.last_updated = (Get-Date).ToUniversalTime().ToString("o")

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Update-ManualGate {
    <#
    .SYNOPSIS
        Update manual gate status (preview, validate-staging)

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER GateName
        Name of manual gate (e.g., "preview", "validate-staging")

    .PARAMETER Status
        Gate status: pending, approved, rejected

    .PARAMETER ApprovedBy
        Who approved the gate

    .EXAMPLE
        Update-ManualGate -FeatureDir "specs/001-login" -GateName "preview" -Status "approved" -ApprovedBy "user"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$GateName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("pending", "approved", "rejected")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [string]$ApprovedBy
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml

    $gateData = @{
        status = $Status
    }

    switch ($Status) {
        "pending" {
            $gateData.started_at = (Get-Date).ToUniversalTime().ToString("o")
        }
        "approved" {
            $gateData.approved_at = (Get-Date).ToUniversalTime().ToString("o")
            if ($ApprovedBy) {
                $gateData.approved_by = $ApprovedBy
            }
        }
        "rejected" {
            $gateData.rejected_at = (Get-Date).ToUniversalTime().ToString("o")
        }
    }

    $state.workflow.manual_gates[$GateName] = $gateData
    $state.feature.last_updated = (Get-Date).ToUniversalTime().ToString("o")

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Get-WorkflowState {
    <#
    .SYNOPSIS
        Get current workflow state

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        $state = Get-WorkflowState -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    # Auto-migrate if needed
    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return $null
    }

    return Get-Content $stateFile -Raw | ConvertFrom-Yaml
}

function Test-PhaseCompleted {
    <#
    .SYNOPSIS
        Check if a phase has been completed

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Phase
        Phase name to check

    .EXAMPLE
        if (Test-PhaseCompleted -FeatureDir "specs/001-login" -Phase "plan") {
            Write-Host "Plan phase completed"
        }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $state = Get-WorkflowState -FeatureDir $FeatureDir
    if ($null -eq $state) {
        return $false
    }

    return $state.workflow.completed_phases -contains $Phase
}

function Get-NextPhase {
    <#
    .SYNOPSIS
        Determine next phase based on deployment model and current phase

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        $nextPhase = Get-NextPhase -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    $state = Get-WorkflowState -FeatureDir $FeatureDir
    if ($null -eq $state) {
        return $null
    }

    $model = $state.deployment_model
    $currentPhase = $state.workflow.phase

    # Define phase sequences
    $sequences = @{
        "staging-prod" = @(
            "spec-flow", "clarify", "plan", "tasks", "analyze", "implement",
            "ship:optimize", "ship:preview", "ship:phase-1-ship",
            "ship:validate-staging", "ship:phase-2-ship", "ship:finalize"
        )
        "direct-prod"  = @(
            "spec-flow", "clarify", "plan", "tasks", "analyze", "implement",
            "ship:optimize", "ship:preview", "ship:deploy-prod", "ship:finalize"
        )
        "local-only"   = @(
            "spec-flow", "clarify", "plan", "tasks", "analyze", "implement",
            "ship:optimize", "ship:preview", "ship:build-local", "ship:finalize"
        )
    }

    $sequence = $sequences[$model]
    $currentIndex = $sequence.IndexOf($currentPhase)

    if ($currentIndex -eq -1 -or $currentIndex -eq ($sequence.Count - 1)) {
        return $null  # No next phase
    }

    return $sequence[$currentIndex + 1]
}

function Get-DeploymentModel {
    <#
    .SYNOPSIS
        Auto-detect deployment model for current project

    .DESCRIPTION
        Checks constitution.md for explicit configuration, then auto-detects
        based on git configuration and workflow files.

    .EXAMPLE
        $model = Get-DeploymentModel
    #>

    # Check constitution.md first
    $constitutionPath = ".spec-flow/memory/constitution.md"
    if (Test-Path $constitutionPath) {
        $constitutionContent = Get-Content $constitutionPath -Raw
        if ($constitutionContent -match "Deployment Model:\s*(\S+)") {
            $model = $Matches[1]
            if ($model -in @("staging-prod", "direct-prod", "local-only")) {
                return $model
            }
        }
    }

    # Auto-detect
    $hasRemote = (git remote -v 2>$null) -match "origin"
    $hasStagingBranch = (git show-ref --verify refs/heads/staging 2>$null) -or
    (git show-ref --verify refs/remotes/origin/staging 2>$null)
    $hasStagingWorkflow = Test-Path ".github/workflows/deploy-staging.yml"

    if ($hasRemote -and $hasStagingBranch -and $hasStagingWorkflow) {
        return "staging-prod"
    }
    elseif ($hasRemote) {
        return "direct-prod"
    }
    else {
        return "local-only"
    }
}


# ============================================================================
# Timing Functions
# ============================================================================

function Start-PhaseTiming {
    <#
    .SYNOPSIS
        Mark the start of a workflow phase for timing tracking

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Phase
        Phase name (e.g., "spec-flow", "plan", "implement")

    .EXAMPLE
        Start-PhaseTiming -FeatureDir "specs/001-login" -Phase "implement"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Initialize phase timing entry
    if (-not $state.workflow.phase_timing) {
        $state.workflow.phase_timing = @{}
    }

    $state.workflow.phase_timing[$Phase] = @{
        started_at = $timestamp
        status     = "in_progress"
    }

    $state.feature.last_updated = $timestamp

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Complete-PhaseTiming {
    <#
    .SYNOPSIS
        Mark the completion of a workflow phase and calculate duration

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER Phase
        Phase name (e.g., "spec-flow", "plan", "implement")

    .EXAMPLE
        Complete-PhaseTiming -FeatureDir "specs/001-login" -Phase "implement"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Get started_at timestamp
    if (-not $state.workflow.phase_timing -or -not $state.workflow.phase_timing[$Phase]) {
        Write-Warning "Phase $Phase has no start time, skipping duration calculation"
        if (-not $state.workflow.phase_timing) {
            $state.workflow.phase_timing = @{}
        }
        $state.workflow.phase_timing[$Phase] = @{
            completed_at = $timestamp
            status       = "completed"
        }
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
        return
    }

    $startedAt = $state.workflow.phase_timing[$Phase].started_at

    if (-not $startedAt) {
        Write-Warning "Phase $Phase has no start time, skipping duration calculation"
        $state.workflow.phase_timing[$Phase].completed_at = $timestamp
        $state.workflow.phase_timing[$Phase].status = "completed"
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
        return
    }

    # Calculate duration
    try {
        $startedEpoch = [DateTimeOffset]::Parse($startedAt).ToUnixTimeSeconds()
        $completedEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $duration = $completedEpoch - $startedEpoch

        # Update phase timing
        $state.workflow.phase_timing[$Phase].completed_at = $timestamp
        $state.workflow.phase_timing[$Phase].duration_seconds = $duration
        $state.workflow.phase_timing[$Phase].status = "completed"
        $state.feature.last_updated = $timestamp

        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
    }
    catch {
        Write-Warning "Unable to parse date format, skipping duration calculation: $_"
        $state.workflow.phase_timing[$Phase].completed_at = $timestamp
        $state.workflow.phase_timing[$Phase].status = "completed"
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
    }
}

function Start-SubPhaseTiming {
    <#
    .SYNOPSIS
        Mark the start of a sub-phase within a parent phase

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER ParentPhase
        Parent phase name (e.g., "optimize")

    .PARAMETER SubPhase
        Sub-phase name (e.g., "performance", "security")

    .EXAMPLE
        Start-SubPhaseTiming -FeatureDir "specs/001-login" -ParentPhase "optimize" -SubPhase "performance"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$ParentPhase,

        [Parameter(Mandatory = $true)]
        [string]$SubPhase
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Initialize sub-phase timing entry
    if (-not $state.workflow.phase_timing) {
        $state.workflow.phase_timing = @{}
    }
    if (-not $state.workflow.phase_timing[$ParentPhase]) {
        $state.workflow.phase_timing[$ParentPhase] = @{}
    }
    if (-not $state.workflow.phase_timing[$ParentPhase].sub_phases) {
        $state.workflow.phase_timing[$ParentPhase].sub_phases = @{}
    }

    $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase] = @{
        started_at = $timestamp
    }

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
}

function Complete-SubPhaseTiming {
    <#
    .SYNOPSIS
        Mark the completion of a sub-phase and calculate duration

    .PARAMETER FeatureDir
        Path to feature directory

    .PARAMETER ParentPhase
        Parent phase name (e.g., "optimize")

    .PARAMETER SubPhase
        Sub-phase name (e.g., "performance", "security")

    .EXAMPLE
        Complete-SubPhaseTiming -FeatureDir "specs/001-login" -ParentPhase "optimize" -SubPhase "performance"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir,

        [Parameter(Mandatory = $true)]
        [string]$ParentPhase,

        [Parameter(Mandatory = $true)]
        [string]$SubPhase
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Get started_at timestamp
    if (-not $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase]) {
        Write-Warning "Sub-phase $SubPhase has no start time, skipping duration calculation"
        $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase] = @{
            completed_at = $timestamp
        }
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
        return
    }

    $startedAt = $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase].started_at

    if (-not $startedAt) {
        Write-Warning "Sub-phase $SubPhase has no start time, skipping duration calculation"
        $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase].completed_at = $timestamp
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
        return
    }

    # Calculate duration
    try {
        $startedEpoch = [DateTimeOffset]::Parse($startedAt).ToUnixTimeSeconds()
        $completedEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $duration = $completedEpoch - $startedEpoch

        $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase].completed_at = $timestamp
        $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase].duration_seconds = $duration

        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
    }
    catch {
        Write-Warning "Unable to parse date format, skipping duration calculation: $_"
        $state.workflow.phase_timing[$ParentPhase].sub_phases[$SubPhase].completed_at = $timestamp
        $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8
    }
}

function Get-WorkflowMetrics {
    <#
    .SYNOPSIS
        Calculate and update overall workflow metrics

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        Get-WorkflowMetrics -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered

    # Sum all phase durations
    $totalDuration = 0
    if ($state.workflow.phase_timing) {
        foreach ($phase in $state.workflow.phase_timing.Keys) {
            $duration = $state.workflow.phase_timing[$phase].duration_seconds
            if ($duration) {
                $totalDuration += $duration
            }
        }
    }

    # Calculate manual wait time
    $manualWait = 0
    if ($state.workflow.manual_gates) {
        foreach ($gate in $state.workflow.manual_gates.Keys) {
            $startedAt = $state.workflow.manual_gates[$gate].started_at
            $approvedAt = $state.workflow.manual_gates[$gate].approved_at

            if ($startedAt -and $approvedAt) {
                try {
                    $startedEpoch = [DateTimeOffset]::Parse($startedAt).ToUnixTimeSeconds()
                    $approvedEpoch = [DateTimeOffset]::Parse($approvedAt).ToUnixTimeSeconds()
                    $gateWait = $approvedEpoch - $startedEpoch
                    $manualWait += $gateWait

                    # Store wait duration in gate entry
                    $state.workflow.manual_gates[$gate].wait_duration_seconds = $gateWait
                }
                catch {
                    # Skip if unable to parse
                    continue
                }
            }
        }
    }

    # Calculate active work time
    $activeWork = $totalDuration - $manualWait

    # Count phases and gates
    $phasesCount = if ($state.workflow.phase_timing) { $state.workflow.phase_timing.Count } else { 0 }
    $gatesCount = if ($state.workflow.manual_gates) { $state.workflow.manual_gates.Count } else { 0 }

    # Update metrics
    if (-not $state.workflow.metrics) {
        $state.workflow.metrics = @{}
    }

    $state.workflow.metrics.total_duration_seconds = $totalDuration
    $state.workflow.metrics.active_work_seconds = $activeWork
    $state.workflow.metrics.manual_wait_seconds = $manualWait
    $state.workflow.metrics.phases_count = $phasesCount
    $state.workflow.metrics.manual_gates_count = $gatesCount

    $state | ConvertTo-Yaml | Set-Content -Path $stateFile -Encoding UTF8

    return $state.workflow.metrics
}

function Format-Duration {
    <#
    .SYNOPSIS
        Format seconds into human-readable duration

    .PARAMETER Seconds
        Duration in seconds

    .EXAMPLE
        Format-Duration -Seconds 3661
        # Returns "1h 1m"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int]$Seconds
    )

    if ($Seconds -lt 60) {
        return "${Seconds}s"
    }
    elseif ($Seconds -lt 3600) {
        $minutes = [Math]::Floor($Seconds / 60)
        $secs = $Seconds % 60
        return "${minutes}m ${secs}s"
    }
    else {
        $hours = [Math]::Floor($Seconds / 3600)
        $minutes = [Math]::Floor(($Seconds % 3600) / 60)
        return "${hours}h ${minutes}m"
    }
}

function Show-WorkflowSummary {
    <#
    .SYNOPSIS
        Display comprehensive workflow timing summary

    .PARAMETER FeatureDir
        Path to feature directory

    .EXAMPLE
        Show-WorkflowSummary -FeatureDir "specs/001-login"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureDir
    )

    $stateFile = Test-MigrateJsonToYaml -FeatureDir $FeatureDir

    if (-not (Test-Path $stateFile)) {
        Write-Error "Workflow state not found: $stateFile"
        return
    }

    # Calculate metrics first
    $metrics = Get-WorkflowMetrics -FeatureDir $FeatureDir

    $state = Get-Content $stateFile -Raw | ConvertFrom-Yaml -Ordered

    # Extract feature info
    $featureTitle = $state.feature.title
    $deploymentModel = $state.deployment_model

    # Extract metrics
    $totalDuration = $metrics.total_duration_seconds
    $activeWork = $metrics.active_work_seconds
    $manualWait = $metrics.manual_wait_seconds

    # Format durations
    $totalFmt = Format-Duration -Seconds $totalDuration
    $activeFmt = Format-Duration -Seconds $activeWork
    $manualFmt = Format-Duration -Seconds $manualWait

    # Extract deployment info
    $prodUrl = $state.deployment.production.url
    $prodVersion = $state.deployment.production.version

    # Display summary
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "✅ Feature Workflow Complete: $featureTitle" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 Workflow Timing Summary" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Total Duration:        $totalFmt ($totalDuration seconds)"
    Write-Host "Active Work:           $activeFmt ($activeWork seconds)"
    if ($manualWait -gt 0) {
        Write-Host "Manual Waiting:        $manualFmt ($manualWait seconds)"
    }
    Write-Host ""
    Write-Host "Phase Breakdown:"
    Write-Host "┌────────────────────────────┬──────────────────┬─────────────┬──────────┐"
    Write-Host "│ Phase                      │ Started (UTC)    │ Duration    │ Status   │"
    Write-Host "├────────────────────────────┼──────────────────┼─────────────┼──────────┤"

    # Display phases
    if ($state.workflow.phase_timing) {
        foreach ($phase in $state.workflow.phase_timing.Keys | Sort-Object) {
            $phaseData = $state.workflow.phase_timing[$phase]
            $startedAt = $phaseData.started_at
            $duration = $phaseData.duration_seconds
            $status = $phaseData.status

            # Format time
            $timePart = if ($startedAt) { $startedAt.Split('T')[1].Split('Z')[0] } else { "—" }

            # Format duration
            $durationFmt = if ($duration) { Format-Duration -Seconds $duration } else { "—" }

            # Status icon
            $statusIcon = switch ($status) {
                "completed" { "✅" }
                "in_progress" { "🔄" }
                "failed" { "❌" }
                default { "—" }
            }

            Write-Host ("│ {0,-26} │ {1,-16} │ {2,-11} │ {3,-8} │" -f $phase, $timePart, $durationFmt, $statusIcon)

            # Display sub-phases if present
            if ($phaseData.sub_phases) {
                foreach ($subPhase in $phaseData.sub_phases.Keys | Sort-Object) {
                    $subDuration = $phaseData.sub_phases[$subPhase].duration_seconds
                    if ($subDuration) {
                        $subDurationFmt = Format-Duration -Seconds $subDuration
                        Write-Host ("│   ├─ {0,-22} │                  │ {1,-11} │          │" -f $subPhase, $subDurationFmt)
                    }
                }
            }
        }
    }

    # Display manual gates
    if ($state.workflow.manual_gates) {
        foreach ($gate in $state.workflow.manual_gates.Keys | Sort-Object) {
            $gateData = $state.workflow.manual_gates[$gate]
            $gateStatus = $gateData.status
            $waitDuration = $gateData.wait_duration_seconds
            $startedAt = $gateData.started_at

            $timePart = if ($startedAt) { $startedAt.Split('T')[1].Split('Z')[0] } else { "—" }
            $waitFmt = if ($waitDuration) { Format-Duration -Seconds $waitDuration } else { "—" }

            $statusIcon = switch ($gateStatus) {
                "approved" { "✅" }
                "pending" { "⏳" }
                "rejected" { "❌" }
                default { "—" }
            }

            $gateLabel = "[Manual Gate: $gate]"
            Write-Host ("│ {0,-26} │ {1,-16} │ {2,-11} │ {3,-8} │" -f $gateLabel, $timePart, $waitFmt, $statusIcon)
        }
    }

    Write-Host "└────────────────────────────┴──────────────────┴─────────────┴──────────┘"
    Write-Host ""
    Write-Host "Deployment Model: $deploymentModel"

    if ($prodUrl) {
        Write-Host "Production URL: $prodUrl"
    }

    if ($prodVersion) {
        Write-Host "Version: $prodVersion"
    }

    Write-Host ""
    Write-Host "For detailed metrics: cat $stateFile"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-WorkflowState',
    'Update-WorkflowPhase',
    'Update-DeploymentState',
    'Update-DeploymentIds',
    'Update-QualityGate',
    'Update-ManualGate',
    'Get-WorkflowState',
    'Test-PhaseCompleted',
    'Get-NextPhase',
    'Get-DeploymentModel',
    'Test-MigrateJsonToYaml',
    'Start-PhaseTiming',
    'Complete-PhaseTiming',
    'Start-SubPhaseTiming',
    'Complete-SubPhaseTiming',
    'Get-WorkflowMetrics',
    'Format-Duration',
    'Show-WorkflowSummary'
)


<#
.SYNOPSIS
    Workflow state management functions for Spec-Flow

.DESCRIPTION
    Provides functions to initialize, update, and query workflow state across
    the entire feature delivery lifecycle. State is stored in workflow-state.yaml
    within each feature directory.

    Auto-migrates from JSON to YAML format for backward compatibility.

.NOTES
    Version: 2.0.0
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir
    )

    $jsonFile = Join-Path $FeatureDir "workflow-state.json"
    $yamlFile = Join-Path $FeatureDir "workflow-state.yaml"

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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [string]$Slug,

        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$false)]
        [string]$BranchName = "local"
    )

    $stateFile = Join-Path $FeatureDir "workflow-state.yaml"

    # Detect deployment model
    $deploymentModel = Get-DeploymentModel

    $state = @{
        feature = @{
            slug = $Slug
            title = $Title
            branch_name = $BranchName
            created = (Get-Date).ToUniversalTime().ToString("o")
            last_updated = (Get-Date).ToUniversalTime().ToString("o")
            roadmap_status = "in_progress"  # Options: backlog, next, in_progress, shipped
        }
        deployment_model = $deploymentModel
        workflow = @{
            phase = "spec-flow"
            status = "in_progress"
            completed_phases = @()
            failed_phases = @()
            manual_gates = @{}
        }
        context = @{
            token_budget = @{
                phase = "planning"
                budget = 75000
                estimated_usage = 0
                compaction_needed = $false
            }
        }
        deployment = @{
            staging = @{
                deployed = $false
                url = $null
                deployment_ids = @{}
                health_checks = @{}
            }
            production = @{
                deployed = $false
                version = $null
                url = $null
                deployment_ids = @{}
            }
        }
        artifacts = @{
            spec = "specs/$Slug/spec.md"
            plan = $null
            tasks = $null
            optimization_report = $null
            staging_validation = $null
            ship_report = $null
        }
        quality_gates = @{}
        metadata = @{
            schema_version = "2.0.0"
            workflow_version = "2.0.0"
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [string]$Phase,

        [Parameter(Mandatory=$false)]
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
    } elseif ($Status -eq "failed" -and $state.workflow.failed_phases -notcontains $Phase) {
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [ValidateSet("staging", "production")]
        [string]$Environment,

        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [ValidateSet("staging", "production")]
        [string]$Environment,

        [Parameter(Mandatory=$false)]
        [string]$MarketingId,

        [Parameter(Mandatory=$false)]
        [string]$AppId,

        [Parameter(Mandatory=$false)]
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [string]$GateName,

        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
        [string]$GateName,

        [Parameter(Mandatory=$true)]
        [ValidateSet("pending", "approved", "rejected")]
        [string]$Status,

        [Parameter(Mandatory=$false)]
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
        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [string]$FeatureDir,

        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
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
        "direct-prod" = @(
            "spec-flow", "clarify", "plan", "tasks", "analyze", "implement",
            "ship:optimize", "ship:preview", "ship:deploy-prod", "ship:finalize"
        )
        "local-only" = @(
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
    } elseif ($hasRemote) {
        return "direct-prod"
    } else {
        return "local-only"
    }
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
    'Test-MigrateJsonToYaml'
)

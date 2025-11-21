<#
.SYNOPSIS
Detects workflow type (epic vs feature) and returns base directory.

.DESCRIPTION
Detection priority (as per user preference):
1. Workspace files (epics/*/epic-spec.md OR specs/*/spec.md)
2. Git branch pattern (epic/* OR feature/*)
3. workflow-state.yaml (workflow_type field)
4. Return failure code for fallback to AskUserQuestion

.OUTPUTS
JSON object with workflow information

.EXAMPLE
.\detect-workflow-paths.ps1

.NOTES
Exit codes: 0=success, 1=detection failed
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Get-CurrentBranch {
    try {
        $branch = git branch --show-current 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
            return "unknown"
        }
        return $branch
    }
    catch {
        return "unknown"
    }
}

function Detect-FromFiles {
    # Check for epic workspace
    $epicSpecFiles = Get-ChildItem -Path "epics\*\epic-spec.md" -ErrorAction SilentlyContinue
    if ($epicSpecFiles) {
        $epicDir = Split-Path -Parent $epicSpecFiles[0].FullName
        $epicSlug = Split-Path -Leaf $epicDir
        $branch = Get-CurrentBranch
        $result = @{
            type = "epic"
            base_dir = "epics"
            slug = $epicSlug
            branch = $branch
            source = "files"
        }
        Write-Output ($result | ConvertTo-Json -Compress)
        return $true
    }

    # Check for feature workspace
    $featureSpecFiles = Get-ChildItem -Path "specs\*\spec.md" -ErrorAction SilentlyContinue
    if ($featureSpecFiles) {
        $featureDir = Split-Path -Parent $featureSpecFiles[0].FullName
        $featureSlug = Split-Path -Leaf $featureDir
        $branch = Get-CurrentBranch
        $result = @{
            type = "feature"
            base_dir = "specs"
            slug = $featureSlug
            branch = $branch
            source = "files"
        }
        Write-Output ($result | ConvertTo-Json -Compress)
        return $true
    }

    return $false
}

function Detect-FromBranch {
    $currentBranch = Get-CurrentBranch

    # Check for epic branch pattern (epic/NNN-slug or epic/slug)
    if ($currentBranch -match '^epic/(.+)$') {
        $slug = $Matches[1]
        $result = @{
            type = "epic"
            base_dir = "epics"
            slug = $slug
            branch = $currentBranch
            source = "branch"
        }
        Write-Output ($result | ConvertTo-Json -Compress)
        return $true
    }

    # Check for feature branch pattern (feature/NNN-slug or feature/slug)
    if ($currentBranch -match '^feature/(.+)$') {
        $slug = $Matches[1]
        $result = @{
            type = "feature"
            base_dir = "specs"
            slug = $slug
            branch = $currentBranch
            source = "branch"
        }
        Write-Output ($result | ConvertTo-Json -Compress)
        return $true
    }

    return $false
}

function Detect-FromState {
    # Check epic workflow-state.yaml
    $epicStateFiles = Get-ChildItem -Path "epics\*\workflow-state.yaml" -ErrorAction SilentlyContinue
    if ($epicStateFiles) {
        $stateFile = $epicStateFiles[0].FullName
        $content = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
        if ($content -match 'workflow_type:\s*["\']?epic["\']?') {
            $epicDir = Split-Path -Parent $stateFile
            $epicSlug = Split-Path -Leaf $epicDir
            $branch = Get-CurrentBranch
            $result = @{
                type = "epic"
                base_dir = "epics"
                slug = $epicSlug
                branch = $branch
                source = "state"
            }
            Write-Output ($result | ConvertTo-Json -Compress)
            return $true
        }
    }

    # Check feature workflow-state.yaml
    $featureStateFiles = Get-ChildItem -Path "specs\*\workflow-state.yaml" -ErrorAction SilentlyContinue
    if ($featureStateFiles) {
        $stateFile = $featureStateFiles[0].FullName
        $content = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
        if ($content -match 'workflow_type:\s*["\']?feature["\']?') {
            $featureDir = Split-Path -Parent $stateFile
            $featureSlug = Split-Path -Leaf $featureDir
            $branch = Get-CurrentBranch
            $result = @{
                type = "feature"
                base_dir = "specs"
                slug = $featureSlug
                branch = $branch
                source = "state"
            }
            Write-Output ($result | ConvertTo-Json -Compress)
            return $true
        }
    }

    return $false
}

# Main detection logic
try {
    # Try each detection method in priority order
    if (Detect-FromFiles) {
        exit 0
    }

    if (Detect-FromBranch) {
        exit 0
    }

    if (Detect-FromState) {
        exit 0
    }

    # All detection methods failed
    $branch = Get-CurrentBranch
    $error = @{
        type = "unknown"
        base_dir = "unknown"
        slug = "unknown"
        branch = $branch
        source = "none"
        error = "Could not detect workflow type"
    }
    Write-Error ($error | ConvertTo-Json -Compress)
    exit 1
}
catch {
    $branch = Get-CurrentBranch
    $error = @{
        type = "unknown"
        base_dir = "unknown"
        slug = "unknown"
        branch = $branch
        source = "none"
        error = "Detection script error: $_"
    }
    Write-Error ($error | ConvertTo-Json -Compress)
    exit 1
}

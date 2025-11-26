<#
.SYNOPSIS
Detects workflow type (epic vs feature) and returns base directory.

.DESCRIPTION
Detection priority (as per user preference):
1. Workspace files (epics/*/epic-spec.md OR specs/*/spec.md)
2. Git branch pattern (epic/* OR feature/*)
3. state.yaml (workflow_type field)
4. Return failure code for fallback to AskUserQuestion

.OUTPUTS
JSON object with workflow information including worktree detection

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

function Detect-Worktree {
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitDir)) {
            return @{ is_worktree = $false }
        }

        # In a worktree, git_dir is .git/worktrees/<name>
        # In main worktree, git_dir is .git
        if ($gitDir -match '[\\/]worktrees[\\/]') {
            # This is a worktree
            $worktreePath = git rev-parse --show-toplevel 2>$null
            if ($LASTEXITCODE -ne 0) {
                $worktreePath = (Get-Location).Path
            }

            # Check if this is a managed worktree (under worktrees/ directory)
            if ($worktreePath -match '[\\/]worktrees[\\/]') {
                # Extract type and slug from path
                # Path format: .../worktrees/{type}/{slug}
                if ($worktreePath -match '[\\/]worktrees[\\/]([^\\/]+)[\\/]([^\\/]+)$') {
                    $type = $Matches[1]
                    $slug = $Matches[2]

                    return @{
                        is_worktree   = $true
                        worktree_path = $worktreePath
                        worktree_type = $type
                        worktree_slug = $slug
                    }
                }
            }

            # Worktree but not managed by our system
            return @{
                is_worktree   = $true
                worktree_path = $worktreePath
                worktree_type = "unknown"
                worktree_slug = "unknown"
            }
        }

        # Not a worktree (main repository)
        return @{ is_worktree = $false }
    }
    catch {
        return @{ is_worktree = $false }
    }
}

function Merge-WorktreeInfo {
    param(
        [hashtable]$WorkflowInfo,
        [hashtable]$WorktreeInfo
    )

    # Merge the two hashtables
    $merged = $WorkflowInfo.Clone()
    $merged['is_worktree'] = $WorktreeInfo['is_worktree']

    if ($WorktreeInfo['is_worktree']) {
        $merged['worktree_path'] = $WorktreeInfo['worktree_path']
        $merged['worktree_type'] = $WorktreeInfo['worktree_type']
        $merged['worktree_slug'] = $WorktreeInfo['worktree_slug']
    }

    return $merged
}

function Detect-FromFiles {
    # Check for epic workspace
    $epicSpecFiles = Get-ChildItem -Path "epics\*\epic-spec.md" -ErrorAction SilentlyContinue
    if ($epicSpecFiles) {
        $epicDir = Split-Path -Parent $epicSpecFiles[0].FullName
        $epicSlug = Split-Path -Leaf $epicDir
        $branch = Get-CurrentBranch
        return @{
            type     = "epic"
            base_dir = "epics"
            slug     = $epicSlug
            branch   = $branch
            source   = "files"
        }
    }

    # Check for feature workspace
    $featureSpecFiles = Get-ChildItem -Path "specs\*\spec.md" -ErrorAction SilentlyContinue
    if ($featureSpecFiles) {
        $featureDir = Split-Path -Parent $featureSpecFiles[0].FullName
        $featureSlug = Split-Path -Leaf $featureDir
        $branch = Get-CurrentBranch
        return @{
            type     = "feature"
            base_dir = "specs"
            slug     = $featureSlug
            branch   = $branch
            source   = "files"
        }
    }

    return $null
}

function Detect-FromBranch {
    $currentBranch = Get-CurrentBranch

    # Check for epic branch pattern (epic/NNN-slug or epic/slug)
    if ($currentBranch -match '^epic/(.+)$') {
        $slug = $Matches[1]
        return @{
            type     = "epic"
            base_dir = "epics"
            slug     = $slug
            branch   = $currentBranch
            source   = "branch"
        }
    }

    # Check for feature branch pattern (feature/NNN-slug or feature/slug)
    if ($currentBranch -match '^feature/(.+)$') {
        $slug = $Matches[1]
        return @{
            type     = "feature"
            base_dir = "specs"
            slug     = $slug
            branch   = $currentBranch
            source   = "branch"
        }
    }

    return $null
}

function Detect-FromState {
    # Check epic state.yaml
    $epicStateFiles = Get-ChildItem -Path "epics\*\state.yaml" -ErrorAction SilentlyContinue
    if ($epicStateFiles) {
        $stateFile = $epicStateFiles[0].FullName
        $content = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
        if ($content -match 'workflow_type:\s*["\']?epic["\']?') {
            $epicDir = Split-Path -Parent $stateFile
            $epicSlug = Split-Path -Leaf $epicDir
            $branch = Get-CurrentBranch
            return @{
                type = "epic"
                base_dir = "epics"
                slug = $epicSlug
                branch = $branch
                source = "state"
            }
        }
    }

    # Check feature state.yaml
    $featureStateFiles = Get-ChildItem -Path "specs\*\state.yaml" -ErrorAction SilentlyContinue
    if ($featureStateFiles) {
        $stateFile = $featureStateFiles[0].FullName
        $content = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
        if ($content -match 'workflow_type:\s*["\']?feature["\']?') {
            $featureDir = Split-Path -Parent $stateFile
            $featureSlug = Split-Path -Leaf $featureDir
            $branch = Get-CurrentBranch
            return @{
                type = "feature"
                base_dir = "specs"
                slug = $featureSlug
                branch = $branch
                source = "state"
            }
        }
    }

    return $null
}

# Main detection logic
try {
    # Detect worktree status
    $worktreeInfo = Detect-Worktree

    # Try each detection method in priority order
    $workflowInfo = Detect-FromFiles
    if ($workflowInfo) {
        $merged = Merge-WorktreeInfo -WorkflowInfo $workflowInfo -WorktreeInfo $worktreeInfo
        Write-Output ($merged | ConvertTo-Json -Compress)
        exit 0
    }

    $workflowInfo = Detect-FromBranch
    if ($workflowInfo) {
        $merged = Merge-WorktreeInfo -WorkflowInfo $workflowInfo -WorktreeInfo $worktreeInfo
        Write-Output ($merged | ConvertTo-Json -Compress)
        exit 0
    }

    $workflowInfo = Detect-FromState
    if ($workflowInfo) {
        $merged = Merge-WorktreeInfo -WorkflowInfo $workflowInfo -WorktreeInfo $worktreeInfo
        Write-Output ($merged | ConvertTo-Json -Compress)
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
    $errorMerged = Merge-WorktreeInfo -WorkflowInfo $error -WorktreeInfo $worktreeInfo
    Write-Error ($errorMerged | ConvertTo-Json -Compress)
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
    $worktreeInfo = @{ is_worktree = $false }
    $errorMerged = Merge-WorktreeInfo -WorkflowInfo $error -WorktreeInfo $worktreeInfo
    Write-Error ($errorMerged | ConvertTo-Json -Compress)
    exit 1
}

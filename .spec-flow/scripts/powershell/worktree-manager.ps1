#!/usr/bin/env pwsh
<#
.SYNOPSIS
Git Worktree Manager for Spec-Flow Workflow

.DESCRIPTION
Manages worktree lifecycle for parallel epic/feature development.
Provides CRUD operations for worktrees, automatic cleanup, and memory linking.

.PARAMETER Command
The command to execute: create, list, remove, exists, get-path, cleanup, link-memory

.PARAMETER Type
Workflow type (epic or feature) - used with 'create' command

.PARAMETER Slug
Workflow slug (e.g., 001-auth-system) - used with most commands

.PARAMETER Branch
Git branch name (e.g., epic/001-auth-system) - used with 'create' command

.PARAMETER Json
Output results in JSON format

.PARAMETER DryRun
Show what would be done without making changes

.EXAMPLE
.\worktree-manager.ps1 create epic 001-auth-system epic/001-auth-system

.EXAMPLE
.\worktree-manager.ps1 list -Json

.EXAMPLE
.\worktree-manager.ps1 cleanup -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('create', 'list', 'remove', 'exists', 'get-path', 'cleanup', 'link-memory')]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Type,

    [Parameter(Position = 2)]
    [string]$Slug,

    [Parameter(Position = 3)]
    [string]$Branch,

    [switch]$Json,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Load common helpers ----------------------------------------------------
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'common.ps1'
if (-not (Test-Path -LiteralPath $commonPath -PathType Leaf)) {
    Write-Error "common.ps1 not found at $commonPath"
    exit 1
}
. $commonPath

# ============================================================================
# Configuration
# ============================================================================

$repoRoot = Get-RepoRoot
$worktreesDir = Join-Path -Path $repoRoot -ChildPath 'worktrees'
$memoryDir = Join-Path -Path $repoRoot -ChildPath '.spec-flow' | Join-Path -ChildPath 'memory'

# ============================================================================
# Helper Functions
# ============================================================================

function Test-GitRepo {
    try {
        git rev-parse --is-inside-work-tree 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Test-BranchExists {
    param([string]$BranchName)
    try {
        git rev-parse --verify --quiet $BranchName 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Test-WorktreeExists {
    param([string]$WorktreeSlug)

    $worktrees = git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }

    foreach ($line in $worktrees) {
        if ($line -match "^worktree (.+)$") {
            $path = $matches[1]
            if ($path -like "$worktreesDir*$WorktreeSlug") {
                return $true
            }
        }
    }
    return $false
}

function Get-WorktreePath {
    param([string]$WorktreeSlug)

    # Search in epic/ and feature/ subdirectories
    foreach ($typeDir in @('epic', 'feature')) {
        $candidate = Join-Path -Path $worktreesDir -ChildPath $typeDir | Join-Path -ChildPath $WorktreeSlug
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return $candidate
        }
    }
    return $null
}

function Test-WorktreeClean {
    param([string]$WorktreePath)

    Push-Location $WorktreePath
    try {
        git diff --quiet 2>$null
        $unstaged = ($LASTEXITCODE -eq 0)

        git diff --cached --quiet 2>$null
        $staged = ($LASTEXITCODE -eq 0)

        return ($unstaged -and $staged)
    }
    finally {
        Pop-Location
    }
}

function Get-WorktreeBranch {
    param([string]$WorktreePath)

    Push-Location $WorktreePath
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $branch
        }
        return $null
    }
    finally {
        Pop-Location
    }
}

function Test-BranchMerged {
    param(
        [string]$BranchName,
        [string]$BaseBranch = 'main'
    )

    # Check if branch exists in remote
    try {
        git rev-parse --verify --quiet "origin/$BranchName" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            return $false  # Local-only branch
        }
    }
    catch {
        return $false
    }

    # Check if merged
    try {
        $mergeBase = git merge-base $BaseBranch $BranchName 2>$null
        $branchHead = git rev-parse $BranchName 2>$null

        return ($mergeBase -eq $branchHead)
    }
    catch {
        return $false
    }
}

# ============================================================================
# Command: Create
# ============================================================================

function Invoke-CreateWorktree {
    param(
        [string]$Type,
        [string]$Slug,
        [string]$Branch
    )

    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    # Validate type
    if ($Type -notin @('epic', 'feature')) {
        Write-Error "Type must be 'epic' or 'feature', got: $Type"
        exit 1
    }

    # Check if worktree already exists
    if (Test-WorktreeExists -WorktreeSlug $Slug) {
        $existingPath = Get-WorktreePath -WorktreeSlug $Slug
        $existingBranch = Get-WorktreeBranch -WorktreePath $existingPath

        if ($Json) {
            @{
                status        = 'exists'
                worktree_path = $existingPath
                branch        = $existingBranch
                message       = 'Worktree already exists'
            } | ConvertTo-Json
        }
        else {
            Write-Host "✓ Worktree already exists: $existingPath" -ForegroundColor Green
            Write-Host "WORKTREE_PATH: $existingPath"
            Write-Host "BRANCH: $existingBranch"
        }
        return
    }

    # Create type directory
    $typeDir = Join-Path -Path $worktreesDir -ChildPath $Type
    $null = New-DirectoryIfMissing -Path $typeDir

    $worktreePath = Join-Path -Path $typeDir -ChildPath $Slug

    # Create or verify branch
    if (Test-BranchExists -BranchName $Branch) {
        Write-Host "✓ Branch '$Branch' already exists, will link to worktree" -ForegroundColor Cyan
    }
    else {
        Write-Host "✓ Creating new branch: $Branch" -ForegroundColor Cyan
        git branch $Branch 2>$null | Out-Null
    }

    # Create worktree
    Write-Host "✓ Creating worktree: $worktreePath" -ForegroundColor Cyan
    git worktree add $worktreePath $Branch 2>$null | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create worktree"
        exit 1
    }

    Write-Host "✓ Worktree created successfully" -ForegroundColor Green

    # Create symlinks to shared memory
    Invoke-LinkMemory -Slug $Slug

    if ($Json) {
        @{
            status        = 'created'
            worktree_path = $worktreePath
            branch        = $Branch
            type          = $Type
            slug          = $Slug
        } | ConvertTo-Json
    }
    else {
        Write-Host "WORKTREE_PATH: $worktreePath"
        Write-Host "BRANCH: $Branch"
        Write-Host "TYPE: $Type"
        Write-Host "SLUG: $Slug"
    }
}

# ============================================================================
# Command: List
# ============================================================================

function Invoke-ListWorktrees {
    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    $worktrees = @()
    $lines = git worktree list --porcelain 2>$null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^worktree (.+)$') {
            $path = $matches[1]

            # Only include managed worktrees
            if ($path -notlike "$worktreesDir*") {
                continue
            }

            $branch = ''
            $head = ''

            # Read next lines for branch and HEAD
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match '^branch refs/heads/(.+)$') {
                $branch = $matches[1]
            }
            if ($i + 2 -lt $lines.Count -and $lines[$i + 2] -match '^HEAD ([a-f0-9]+)$') {
                $head = $matches[1]
            }

            # Extract type and slug
            $relativePath = $path.Substring($worktreesDir.Length).TrimStart('\', '/')
            $parts = $relativePath -split '[/\\]'
            $type = $parts[0]
            $slug = $parts[1]

            $worktrees += @{
                path   = $path
                branch = $branch
                head   = $head
                type   = $type
                slug   = $slug
            }
        }
    }

    if ($Json) {
        $worktrees | ConvertTo-Json -AsArray
    }
    else {
        Write-Host "Managed Worktrees:" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan

        if ($worktrees.Count -eq 0) {
            Write-Host "  (none)"
        }
        else {
            foreach ($wt in $worktrees) {
                $relative = "$($wt.type)/$($wt.slug)"
                Write-Host "  • $relative → $($wt.branch)" -ForegroundColor White
            }
        }
    }
}

# ============================================================================
# Command: Remove
# ============================================================================

function Invoke-RemoveWorktree {
    param([string]$Slug)

    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    if (-not (Test-WorktreeExists -WorktreeSlug $Slug)) {
        Write-Error "Worktree not found: $Slug"
        exit 1
    }

    $worktreePath = Get-WorktreePath -WorktreeSlug $Slug

    # Check if worktree has uncommitted changes
    if (-not (Test-WorktreeClean -WorktreePath $worktreePath)) {
        Write-Warning "Worktree has uncommitted changes: $worktreePath"
        if (-not $DryRun) {
            Write-Error "Cannot remove worktree with uncommitted changes. Commit or stash first."
            exit 1
        }
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] Would remove worktree: $worktreePath" -ForegroundColor Yellow
    }
    else {
        Write-Host "Removing worktree: $worktreePath" -ForegroundColor Cyan
        git worktree remove $worktreePath 2>$null | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Worktree remove failed, forcing..."
            git worktree remove --force $worktreePath 2>$null | Out-Null
        }

        Write-Host "✓ Worktree removed: $Slug" -ForegroundColor Green
    }

    if ($Json) {
        @{
            status = if ($DryRun) { 'dry-run' } else { 'removed' }
            slug   = $Slug
            path   = $worktreePath
        } | ConvertTo-Json
    }
}

# ============================================================================
# Command: Exists
# ============================================================================

function Invoke-ExistsWorktree {
    param([string]$Slug)

    if (-not (Test-GitRepo)) {
        exit 1
    }

    if (Test-WorktreeExists -WorktreeSlug $Slug) {
        exit 0
    }
    else {
        exit 1
    }
}

# ============================================================================
# Command: Get-Path
# ============================================================================

function Invoke-GetWorktreePath {
    param([string]$Slug)

    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    if (Test-WorktreeExists -WorktreeSlug $Slug) {
        $path = Get-WorktreePath -WorktreeSlug $Slug
        Write-Output $path
    }
    else {
        Write-Error "Worktree not found: $Slug"
        exit 1
    }
}

# ============================================================================
# Command: Cleanup
# ============================================================================

function Invoke-CleanupWorktrees {
    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    Write-Host "Scanning for merged/stale worktrees..." -ForegroundColor Cyan

    $removedCount = 0
    $skippedCount = 0

    $lines = git worktree list --porcelain 2>$null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^worktree (.+)$') {
            $path = $matches[1]

            # Only process managed worktrees
            if ($path -notlike "$worktreesDir*") {
                continue
            }

            $branch = ''
            if ($i + 1 -lt $lines.Count -and $lines[$i + 1] -match '^branch refs/heads/(.+)$') {
                $branch = $matches[1]
            }

            if (-not $branch) {
                continue
            }

            # Check if branch is merged
            if (Test-BranchMerged -BranchName $branch) {
                $slug = Split-Path -Leaf $path

                if ($DryRun) {
                    Write-Host "[DRY-RUN] Would remove merged worktree: $slug (branch: $branch)" -ForegroundColor Yellow
                }
                else {
                    Write-Host "Removing merged worktree: $slug" -ForegroundColor Cyan
                    git worktree remove $path 2>$null | Out-Null
                    if ($LASTEXITCODE -ne 0) {
                        git worktree remove --force $path 2>$null | Out-Null
                    }
                }

                $removedCount++
            }
            else {
                $skippedCount++
            }
        }
    }

    if ($Json) {
        @{
            removed = $removedCount
            skipped = $skippedCount
            dry_run = $DryRun.IsPresent
        } | ConvertTo-Json
    }
    else {
        if ($removedCount -eq 0) {
            Write-Host "✓ No merged worktrees to clean up" -ForegroundColor Green
        }
        else {
            Write-Host "✓ Cleanup complete: $removedCount removed, $skippedCount kept" -ForegroundColor Green
        }
    }
}

# ============================================================================
# Command: Link-Memory
# ============================================================================

function Invoke-LinkMemory {
    param([string]$Slug)

    if (-not (Test-GitRepo)) {
        Write-Error "Not inside a git repository"
        exit 1
    }

    if (-not (Test-WorktreeExists -WorktreeSlug $Slug)) {
        Write-Error "Worktree not found: $Slug"
        exit 1
    }

    $worktreePath = Get-WorktreePath -WorktreeSlug $Slug
    $worktreeSpecFlow = Join-Path -Path $worktreePath -ChildPath '.spec-flow'
    $worktreeMemory = Join-Path -Path $worktreeSpecFlow -ChildPath 'memory'

    # Create .spec-flow directory in worktree
    $null = New-DirectoryIfMissing -Path $worktreeSpecFlow

    # Remove existing memory directory/link
    if (Test-Path -LiteralPath $worktreeMemory) {
        Remove-Item -LiteralPath $worktreeMemory -Recurse -Force
    }

    # Create junction/symlink to main memory directory
    # On Windows, use junction for directory linking
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        cmd /c mklink /J "$worktreeMemory" "$memoryDir" | Out-Null
    }
    else {
        New-Item -ItemType SymbolicLink -Path $worktreeMemory -Target $memoryDir -Force | Out-Null
    }

    Write-Host "✓ Linked memory for worktree: $Slug" -ForegroundColor Green
}

# ============================================================================
# Main Command Router
# ============================================================================

switch ($Command) {
    'create' {
        if (-not $Type -or -not $Slug -or -not $Branch) {
            Write-Error "Usage: worktree-manager.ps1 create <type> <slug> <branch>"
            exit 1
        }
        Invoke-CreateWorktree -Type $Type -Slug $Slug -Branch $Branch
    }
    'list' {
        Invoke-ListWorktrees
    }
    'remove' {
        if (-not $Slug) {
            Write-Error "Usage: worktree-manager.ps1 remove <slug>"
            exit 1
        }
        Invoke-RemoveWorktree -Slug $Slug
    }
    'exists' {
        if (-not $Slug) {
            Write-Error "Usage: worktree-manager.ps1 exists <slug>"
            exit 1
        }
        Invoke-ExistsWorktree -Slug $Slug
    }
    'get-path' {
        if (-not $Slug) {
            Write-Error "Usage: worktree-manager.ps1 get-path <slug>"
            exit 1
        }
        Invoke-GetWorktreePath -Slug $Slug
    }
    'cleanup' {
        Invoke-CleanupWorktrees
    }
    'link-memory' {
        if (-not $Slug) {
            Write-Error "Usage: worktree-manager.ps1 link-memory <slug>"
            exit 1
        }
        Invoke-LinkMemory -Slug $Slug
    }
}


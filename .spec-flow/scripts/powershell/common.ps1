#!/usr/bin/env pwsh
# Common PowerShell helpers for Spec Kit workflows
# Cross-platform, KISS, and CI-friendly.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Internal helpers -------------------------------------------------------
$script:IsCI = [bool]($env:CI)
$script:SupportsVT = (Get-Variable -Name 'PSStyle' -ErrorAction SilentlyContinue) -and ($null -ne $PSStyle) -and ($PSStyle.PsObject.Properties.Contains('ForegroundColor')) -and (-not $script:IsCI)

function Write-Status {
    param(
        [Parameter(Mandatory = $true)][bool]$Ok,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($script:SupportsVT) {
        if ($Ok) { Write-Information "`e[32m`e[0m $Message" -InformationAction Continue }
        else { Write-Information "`e[31m`e[0m $Message" -InformationAction Continue }
    }
    else {
        if ($Ok) { Write-Information "   $Message" -InformationAction Continue }
        else { Write-Information "   $Message" -InformationAction Continue }
    }
}

function Resolve-PathUpwards {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$StartPath,
        [Parameter(Mandatory = $true)][string[]]$Markers
    )
    $path = (Resolve-Path -LiteralPath $StartPath).Path
    while ($path -and (Test-Path -LiteralPath $path)) {
        foreach ($m in $Markers) {
            $candidate = Join-Path -Path $path -ChildPath $m
            if (Test-Path -LiteralPath $candidate) { return $path }
        }
        $parent = Split-Path -Path $path -Parent
        if (-not $parent -or $parent -eq $path) { break }
        $path = $parent
    }
    return ''
}

# --- Repo & branch discovery ------------------------------------------------
function Get-RepoRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    try {
        $top = (git rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -eq 0 -and $top) { return $top.Trim() }
    }
    catch {}

    $fromScript = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $found = Resolve-PathUpwards -StartPath $fromScript -Markers @('.git', 'specs')
    if ($found) { return $found }

    return (Get-Location).Path
}

function Test-HasGit {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    try {
        git rev-parse --is-inside-work-tree 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}

function Convert-ToFeatureNameSlug {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Name)

    # If it's just a number, pad to 3 and require suffix later
    if ($Name -match '^[0-9]{1,3}$') { return ($Name.PadLeft(3, '0') + '-feature') }

    # If it starts with number then hyphen, ensure 3 digits
    $m = [regex]::Match($Name, '^(\d{1,3})-(.+)$')
    if ($m.Success) {
        $num = $m.Groups[1].Value.PadLeft(3, '0')
        $slug = $m.Groups[2].Value.ToLowerInvariant()
        $slug = ($slug -replace '[^a-z0-9-]', '-').Trim('-')
        return "$num-$slug"
    }

    # Otherwise, generate a 000- slug
    $slug2 = ($Name.ToLowerInvariant() -replace '[^a-z0-9-]', '-').Trim('-')
    if (-not $slug2) { $slug2 = 'feature' }
    return "000-$slug2"
}

function Get-CurrentBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($env:SPEC_FLOW_FEATURE) {
        $nf = Convert-ToFeatureNameSlug -Name $env:SPEC_FLOW_FEATURE
        return $nf
    }

    if (Test-HasGit) {
        try {
            $sym = (git symbolic-ref --short HEAD 2>$null)
            if ($LASTEXITCODE -eq 0 -and $sym) { return $sym.Trim() }
        }
        catch {}
        try {
            $sha = (git rev-parse --short HEAD 2>$null)
            if ($LASTEXITCODE -eq 0 -and $sha) {
                Write-Warning "[spec-flow] Detached HEAD at $sha; using commit id as branch label"
                return $sha.Trim()
            }
        }
        catch {}
    }

    # No git: pick latest feature under specs
    $root = Get-RepoRoot
    $specsDir = Join-Path -Path $root -ChildPath 'specs'
    if (Test-Path -LiteralPath $specsDir) {
        $highest = -1
        Get-ChildItem -LiteralPath $specsDir -Directory | ForEach-Object {
            $mm = [regex]::Match($_.Name, '^(\d{3})-')
            if ($mm.Success) {
                $n = [int]$mm.Groups[1].Value
                if ($n -gt $highest) { $highest = $n }
            }
        }
        if ($highest -ne -1) { return ('{0:000}' -f ($highest + 1)) }
    }

    return 'main'
}

function Test-FeatureBranch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)][string]$Branch,
        [bool]$HasGit = $true
    )

    if (-not $HasGit) {
        Write-Warning "[spec-flow] Git not detected; skipping branch validation"
        return $true
    }

    # Strip type prefix (feat/, fix/, etc.) if present
    $branchName = $Branch -replace '^(feat|fix|chore|docs|test|refactor|ci|build)/', ''

    if ($branchName -notmatch '^[0-9]{3}-[a-z0-9-]+$') {
        Write-Error "ERROR: Not on a feature branch. Current: '$Branch'. Expected pattern: 'type/001-feature-name' or '001-feature-name'" | Out-Null
        $global:LASTEXITCODE = 1
        return $false
    }
    return $true
}

function Get-FeatureDir {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$RepoRoot, [Parameter(Mandatory = $true)][string]$Branch)
    # Strip type prefix (feat/, fix/, etc.) if present
    $branchName = $Branch -replace '^(feat|fix|chore|docs|test|refactor|ci|build)/', ''
    return (Join-Path -Path (Join-Path -Path $RepoRoot -ChildPath 'specs') -ChildPath $branchName)
}

function Get-FeatureNumber {
    [CmdletBinding()]
    [OutputType([int])]
    param([Parameter(Mandatory = $true)][string]$Branch)
    # Strip type prefix (feat/, fix/, etc.) if present
    $branchName = $Branch -replace '^(feat|fix|chore|docs|test|refactor|ci|build)/', ''
    $m = [regex]::Match($branchName, '^(\d{3})-')
    if ($m.Success) { return [int]$m.Groups[1].Value }
    return -1
}

function New-DirectoryIfMissing {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { New-Item -ItemType Directory -Path $Path | Out-Null }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-FeaturePathsEnv {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch

    [PSCustomObject]@{
        REPO_ROOT           = $repoRoot
        CURRENT_BRANCH      = $currentBranch
        HAS_GIT             = $hasGit
        FEATURE_DIR         = $featureDir
        FEATURE_SPEC        = Join-Path $featureDir 'spec.md'
        IMPL_PLAN           = Join-Path $featureDir 'plan.md'
        TASKS               = Join-Path $featureDir 'tasks.md'
        RESEARCH            = Join-Path $featureDir 'research.md'
        DATA_MODEL          = Join-Path $featureDir 'data-model.md'
        QUICKSTART          = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR       = Join-Path $featureDir 'contracts'
        NOTES               = Join-Path -Path $featureDir -ChildPath 'NOTES.md'
        ERROR_LOG           = Join-Path -Path $featureDir -ChildPath 'error-log.md'
        VISUALS_DIR         = Join-Path -Path $featureDir -ChildPath 'visuals'
        VISUALS_README      = Join-Path -Path $featureDir -ChildPath 'visuals\README.md'
        ARTIFACTS_DIR       = Join-Path -Path $featureDir -ChildPath 'artifacts'
        MEMORY_DIR          = Join-Path -Path $repoRoot -ChildPath '.spec-flow\memory'
        CONSTITUTION        = Join-Path -Path $repoRoot -ChildPath '.spec-flow\memory\constitution.md'
        ROADMAP             = Join-Path -Path $repoRoot -ChildPath '.spec-flow\memory\roadmap.md'
        DESIGN_INSPIRATIONS = Join-Path -Path $repoRoot -ChildPath '.spec-flow\memory\design-inspirations.md'
    }
}

function Test-FileExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Description)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            $fi = Get-Item -LiteralPath $Path -ErrorAction Stop
            $ok = ($fi.Length -ge 0)
        }
        catch { $ok = $true }
        Write-Status -Ok:$ok -Message $Description
        return $ok
    }
    else {
        Write-Status -Ok:$false -Message $Description
        return $false
    }
}

function Test-DirHasFiles {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Description)
    if ((Test-Path -LiteralPath $Path -PathType Container) -and (Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        Write-Status -Ok:$true -Message $Description
        return $true
    }
    else {
        Write-Status -Ok:$false -Message $Description
        return $false
    }
}

function Show-FeatureEnv {
    [CmdletBinding()]
    param()
    $envObj = Get-FeaturePathsEnv
    $envObj | Format-Table -AutoSize
}







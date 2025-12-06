<#
.SYNOPSIS
    Detect project deployment model for workflow adaptation.

.DESCRIPTION
    Determines whether the project is local-only, has remote with staging,
    or has remote without staging. Used to adapt workflow commands.

.OUTPUTS
    String: "local-only" | "remote-staging-prod" | "remote-direct"

.EXAMPLE
    $projectType = & .spec-flow/scripts/powershell/detect-project-type.ps1

.NOTES
    Returns:
    - local-only: No remote repo configured
    - remote-staging-prod: Remote repo with staging branch
    - remote-direct: Remote repo without staging branch
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

function Test-HasRemote {
    <#
    .SYNOPSIS
        Check if git remote 'origin' is configured
    #>
    $remotes = git remote -v 2>$null
    return ($remotes -match 'origin')
}

function Test-HasStagingBranch {
    <#
    .SYNOPSIS
        Check if staging branch exists (local or remote)
    #>
    $localStaging = git show-ref --verify --quiet refs/heads/staging 2>$null
    $remoteStaging = git show-ref --verify --quiet refs/remotes/origin/staging 2>$null

    return ($LASTEXITCODE -eq 0) -or ($localStaging -or $remoteStaging)
}

function Get-ProjectType {
    <#
    .SYNOPSIS
        Detect project type based on git configuration
    #>

    # Check for remote
    if (-not (Test-HasRemote)) {
        return 'local-only'
    }

    # Check for staging branch
    if (Test-HasStagingBranch) {
        return 'remote-staging-prod'
    }

    return 'remote-direct'
}

# Execute detection and output result
Get-ProjectType


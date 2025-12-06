#!/usr/bin/env pwsh
#
# plan-workflow.ps1 - PowerShell wrapper for plan-workflow.sh
#
# Purpose: Enable bash script to be called from Windows PowerShell
# Requirement: Git Bash must be installed and 'bash' must be in PATH
#
# This is an auto-generated wrapper. DO NOT EDIT.
# To regenerate: python generate-ps-wrappers.py

param()  # Accept all arguments via $args

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Path to the bash script (relative to this PowerShell script)
$bashScript = Join-Path $PSScriptRoot "..\bash\plan-workflow.sh"

# Verify bash is available
$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashCommand) {
    Write-Error @"
Error: 'bash' command not found.

This PowerShell wrapper requires Git Bash to be installed.
Install from: https://git-scm.com/download/win
"@
    exit 1
}

# Verify bash script exists
if (-not (Test-Path -LiteralPath $bashScript -PathType Leaf)) {
    Write-Error "Error: Bash script not found: $bashScript"
    exit 1
}

# Invoke bash script with all arguments
try {
    & bash $bashScript @args
    exit $LASTEXITCODE
}
catch {
    Write-Error "Error executing bash script: $_"
    exit 1
}


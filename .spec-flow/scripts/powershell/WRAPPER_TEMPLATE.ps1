#!/usr/bin/env pwsh
#
# WRAPPER_TEMPLATE.ps1 - Template for PowerShell wrappers around bash scripts
#
# Purpose: Enable bash-only scripts to be called from Windows PowerShell
# Strategy: Invoke bash with relative path to bash script, passing all args through
#
# Usage: Copy this template, rename to match bash script name, update $bashScript variable
#
# Requirements:
#   - Git Bash must be installed and 'bash' must be in PATH
#   - Bash script must exist in ../bash/ directory
#
# Example:
#   # For bash/clarify-workflow.sh, create powershell/clarify-workflow.ps1:
#   $bashScript = Join-Path $PSScriptRoot "..\bash\clarify-workflow.sh"
#   & bash $bashScript @args

param()  # Accept all arguments via $args

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Path to the bash script (relative to this PowerShell script)
# UPDATE THIS LINE when copying template:
$bashScript = Join-Path $PSScriptRoot "..\bash\SCRIPT_NAME.sh"

# Verify bash is available
$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashCommand) {
    Write-Error @"
Error: 'bash' command not found.

This PowerShell wrapper requires Git Bash to be installed and available in PATH.

Install Git Bash:
  Windows: Download from https://git-scm.com/download/win

After installation, restart your PowerShell session.
"@
    exit 1
}

# Verify bash script exists
if (-not (Test-Path -LiteralPath $bashScript -PathType Leaf)) {
    Write-Error "Error: Bash script not found: $bashScript"
    exit 1
}

# Invoke bash script with all arguments
# NOTE: $args contains all parameters passed to this PowerShell script
try {
    & bash $bashScript @args
    exit $LASTEXITCODE
}
catch {
    Write-Error "Error executing bash script: $_"
    exit 1
}


#!/usr/bin/env python3
"""
Generate PowerShell wrappers for bash-only scripts.

Usage: python generate-ps-wrappers.py
"""
import re
from pathlib import Path

WRAPPER_TEMPLATE = '''#!/usr/bin/env pwsh
#
# {script_name}.ps1 - PowerShell wrapper for {script_name}.sh
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
$bashScript = Join-Path $PSScriptRoot "..\\bash\\{script_name}.sh"

# Verify bash is available
$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bashCommand) {{
    Write-Error @"
Error: 'bash' command not found.

This PowerShell wrapper requires Git Bash to be installed.
Install from: https://git-scm.com/download/win
"@
    exit 1
}}

# Verify bash script exists
if (-not (Test-Path -LiteralPath $bashScript -PathType Leaf)) {{
    Write-Error "Error: Bash script not found: $bashScript"
    exit 1
}}

# Invoke bash script with all arguments
try {{
    & bash $bashScript @args
    exit $LASTEXITCODE
}} catch {{
    Write-Error "Error executing bash script: $_"
    exit 1
}}
'''

def discover_bash_only_scripts(script_dir: Path):
    """Discover bash-backed spec-cli commands that still need PowerShell wrappers."""
    spec_cli = script_dir / 'spec-cli.py'
    bash_dir = script_dir / 'bash'
    powershell_dir = script_dir / 'powershell'

    script_names = sorted(set(re.findall(r"run_script\('([^']+)'", spec_cli.read_text(encoding='utf-8'))))
    return [
        script_name
        for script_name in script_names
        if (bash_dir / f'{script_name}.sh').exists()
        and not (powershell_dir / f'{script_name}.ps1').exists()
    ]

def generate_wrappers():
    """Generate PowerShell wrappers for all bash-only scripts."""
    script_dir = Path(__file__).parent
    powershell_dir = script_dir / 'powershell'
    wrapper_targets = discover_bash_only_scripts(script_dir)

    print("Generating PowerShell wrappers for bash-backed spec-cli commands...")
    print()

    created = 0
    skipped = 0

    for script_name in wrapper_targets:
        ps_script = powershell_dir / f'{script_name}.ps1'

        # Check if PowerShell wrapper already exists
        if ps_script.exists():
            print(f"[EXISTS] {script_name}.ps1 (already has wrapper)")
            skipped += 1
            continue

        # Generate wrapper
        wrapper_content = WRAPPER_TEMPLATE.format(script_name=script_name)
        ps_script.write_text(wrapper_content, encoding='utf-8')
        print(f"[OK] CREATED: {script_name}.ps1")
        created += 1

    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Created: {created}")
    print(f"Skipped (already exists): {skipped}")
    print(f"Total candidates: {len(wrapper_targets)}")
    print()

    if created > 0:
        print(f"[SUCCESS] Generated {created} PowerShell wrappers successfully!")

if __name__ == '__main__':
    generate_wrappers()

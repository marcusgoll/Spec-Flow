#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/../powershell/install-wizard.ps1"

# Convert bash-style flags to PowerShell parameters
PWSH_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --target-dir)
            PWSH_ARGS+=("-TargetDir" "$2")
            shift 2
            ;;
        --non-interactive)
            PWSH_ARGS+=("-NonInteractive")
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--target-dir <path>] [--non-interactive]" >&2
            exit 1
            ;;
    esac
done

if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NoLogo -NoProfile -File "$PS_SCRIPT" "${PWSH_ARGS[@]}"
elif command -v powershell >/dev/null 2>&1; then
    exec powershell -NoLogo -NoProfile -File "$PS_SCRIPT" "${PWSH_ARGS[@]}"
else
    echo "PowerShell is required to run the installation wizard." >&2
    echo "Install from: https://github.com/PowerShell/PowerShell" >&2
    exit 1
fi

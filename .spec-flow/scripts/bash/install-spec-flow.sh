#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/../powershell/install-spec-flow.ps1"

# Convert bash-style flags to PowerShell parameters
PWSH_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --target-dir)
            PWSH_ARGS+=("-TargetDir" "$2")
            shift 2
            ;;
        --force)
            PWSH_ARGS+=("-Force")
            shift
            ;;
        --skip-init)
            PWSH_ARGS+=("-SkipInit")
            shift
            ;;
        --skip-checks)
            PWSH_ARGS+=("-SkipChecks")
            shift
            ;;
        --json)
            PWSH_ARGS+=("-Json")
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 --target-dir <path> [--force] [--skip-init] [--skip-checks] [--json]" >&2
            exit 1
            ;;
    esac
done

if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NoLogo -NoProfile -File "$PS_SCRIPT" "${PWSH_ARGS[@]}"
elif command -v powershell >/dev/null 2>&1; then
    exec powershell -NoLogo -NoProfile -File "$PS_SCRIPT" "${PWSH_ARGS[@]}"
else
    echo "PowerShell 7+ is required to run install-spec-flow." >&2
    echo "Install from: https://github.com/PowerShell/PowerShell" >&2
    exit 1
fi

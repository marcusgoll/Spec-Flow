#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/../powershell/enable-auto-merge.ps1"

if command -v pwsh >/dev/null 2>&1; then
    exec pwsh -NoLogo -NoProfile -File "$PS_SCRIPT" "$@"
elif command -v powershell >/dev/null 2>&1; then
    exec powershell -NoLogo -NoProfile -File "$PS_SCRIPT" "$@"
else
    echo "PowerShell 7+ is required to run enable-auto-merge." >&2
    exit 1
fi


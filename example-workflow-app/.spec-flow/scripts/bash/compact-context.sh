#!/usr/bin/env bash
# Cross-platform wrapper for context compaction.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/../python/spec_flow_context.py"
if [ ! -f "$PY_SCRIPT" ]; then
    echo "Python helper not found: $PY_SCRIPT" >&2
    exit 1
fi

exec "$PY_SCRIPT" "$@"


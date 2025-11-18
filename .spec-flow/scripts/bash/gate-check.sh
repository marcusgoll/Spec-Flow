#!/usr/bin/env bash
#
# gate-check.sh - Wrapper for quality gate checks
#
# Usage: gate-check.sh [GATE_TYPE] [OPTIONS]
#
# Gate Types:
#   ci      - CI/build quality gates (default: runs all gates)
#   sec     - Security quality gates
#   all     - Run all gates (default)
#
# Dispatches to gate-ci.sh and/or gate-sec.sh based on gate type

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get gate type (first argument, optional)
GATE_TYPE="${1:-all}"

# Shift if we got a gate type
if [[ "$GATE_TYPE" == "ci" ]] || [[ "$GATE_TYPE" == "sec" ]] || [[ "$GATE_TYPE" == "all" ]]; then
    shift
fi

# Track exit codes
EXIT_CODE=0

# Run gates based on type
case "$GATE_TYPE" in
    ci)
        "$SCRIPT_DIR/gate-ci.sh" "$@" || EXIT_CODE=$?
        ;;
    sec)
        "$SCRIPT_DIR/gate-sec.sh" "$@" || EXIT_CODE=$?
        ;;
    all)
        echo "Running all quality gates..."
        echo ""
        echo "=== CI/Build Gates ==="
        "$SCRIPT_DIR/gate-ci.sh" "$@" || EXIT_CODE=$?
        echo ""
        echo "=== Security Gates ==="
        "$SCRIPT_DIR/gate-sec.sh" "$@" || EXIT_CODE=$?
        ;;
    *)
        echo "Error: Unknown gate type '$GATE_TYPE'"
        echo ""
        echo "Usage: gate-check.sh [GATE_TYPE] [OPTIONS]"
        echo ""
        echo "Gate Types:"
        echo "  ci      - CI/build quality gates"
        echo "  sec     - Security quality gates"
        echo "  all     - Run all gates (default)"
        exit 1
        ;;
esac

exit $EXIT_CODE

#!/usr/bin/env bash
#
# schedule-manage.sh - Planned scheduler shim
#
# Usage: schedule-manage.sh <action> [OPTIONS]
#
# The scheduler runtime is referenced by internal roadmap docs and adapter
# inventories, but the shared implementation is not shipped in this checkout.
# Keep this shim explicit so users get a truthful message instead of a missing
# file error from nonexistent scheduler-assign/list/park scripts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action (first argument)
ACTION="${1:-}"

show_help() {
    echo "Usage: schedule-manage.sh <action> [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  assign    - Planned epic assignment surface"
    echo "  list      - Planned epic scheduler listing surface"
    echo "  park      - Planned epic parking surface"
    echo ""
    echo "Status:"
    echo "  The shared scheduler runtime is not shipped in this checkout."
    echo "  Internal roadmap docs still describe the design, but no shared"
    echo "  scheduler-assign.sh / scheduler-list.sh / scheduler-park.sh"
    echo "  implementation currently exists."
    echo ""
    echo "Use the current /epic adapter workflow for active epic orchestration."
}

if [[ -z "$ACTION" ]]; then
    echo "Error: No action specified"
    echo ""
    show_help
    exit 1
fi

case "$ACTION" in
    assign|list|park)
        echo "Error: Scheduler action '$ACTION' is planned but not implemented in the shared engine."
        echo ""
        show_help
        exit 1
        ;;
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        show_help
        exit 1
        ;;
esac

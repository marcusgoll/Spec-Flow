#!/usr/bin/env bash
#
# schedule-manage.sh - Wrapper for epic scheduler management
#
# Usage: schedule-manage.sh <action> [OPTIONS]
#
# Actions:
#   assign    - Assign epic to agent (scheduler-assign)
#   list      - List all epics with state (scheduler-list)
#   park      - Park blocked epic (scheduler-park)
#
# Dispatches to scheduler-assign.sh, scheduler-list.sh, or scheduler-park.sh based on action

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action (first argument)
ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
    echo "Error: No action specified"
    echo ""
    echo "Usage: schedule-manage.sh <action> [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  assign    - Assign epic to agent"
    echo "  list      - List all epics with state"
    echo "  park      - Park blocked epic"
    exit 1
fi

# Shift to remove action from arguments
shift

# Dispatch to appropriate script
case "$ACTION" in
    assign)
        exec "$SCRIPT_DIR/scheduler-assign.sh" "$@"
        ;;
    list)
        exec "$SCRIPT_DIR/scheduler-list.sh" "$@"
        ;;
    park)
        exec "$SCRIPT_DIR/scheduler-park.sh" "$@"
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Valid actions: assign, list, park"
        exit 1
        ;;
esac

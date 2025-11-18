#!/usr/bin/env bash
#
# sprint-manage.sh - Sprint cycle management (PLACEHOLDER)
#
# Usage: sprint-manage.sh <action> [OPTIONS]
#
# Actions:
#   start     - Start new sprint
#   end       - End current sprint
#   status    - Show sprint status
#
# NOTE: This is a placeholder. Sprint management functionality not yet implemented.
#       The epic-scheduler system handles WIP and epic assignment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action (first argument)
ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
    echo "Error: No action specified"
    echo ""
    echo "Usage: sprint-manage.sh <action> [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  start     - Start new sprint"
    echo "  end       - End current sprint"
    echo "  status    - Show sprint status"
    echo ""
    echo "NOTE: Sprint management is not yet fully implemented."
    echo "      Use epic-manager.sh and scheduler-*.sh for epic tracking."
    exit 1
fi

# Shift to remove action from arguments
shift

# All actions return not implemented
case "$ACTION" in
    start|end|status)
        echo "Error: Sprint management not yet implemented"
        echo ""
        echo "WORKAROUND: Use epic scheduler commands instead:"
        echo "  - scheduler-list.sh        # List epic state and WIP"
        echo "  - scheduler-assign.sh      # Assign epic to agent"
        echo "  - epic-manager.sh          # Manage epics"
        echo ""
        echo "TODO: Implement sprint cycle management functionality"
        exit 1
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Valid actions: start, end, status"
        exit 1
        ;;
esac

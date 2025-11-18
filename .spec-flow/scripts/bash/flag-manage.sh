#!/usr/bin/env bash
#
# flag-manage.sh - Wrapper for feature flag management
#
# Usage: flag-manage.sh <action> [OPTIONS]
#
# Actions:
#   add       - Add new feature flag
#   list      - List all feature flags
#   cleanup   - Remove expired flags
#
# Dispatches to flag-add.sh, flag-list.sh, or flag-cleanup.sh based on action

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action (first argument)
ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
    echo "Error: No action specified"
    echo ""
    echo "Usage: flag-manage.sh <action> [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  add       - Add new feature flag"
    echo "  list      - List all feature flags"
    echo "  cleanup   - Remove expired flags"
    exit 1
fi

# Shift to remove action from arguments
shift

# Dispatch to appropriate script
case "$ACTION" in
    add)
        exec "$SCRIPT_DIR/flag-add.sh" "$@"
        ;;
    list)
        exec "$SCRIPT_DIR/flag-list.sh" "$@"
        ;;
    cleanup)
        exec "$SCRIPT_DIR/flag-cleanup.sh" "$@"
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Valid actions: add, list, cleanup"
        exit 1
        ;;
esac

#!/usr/bin/env bash
#
# deps-manage.sh - Dependency management wrapper
#
# Usage: deps-manage.sh <action> [OPTIONS]
#
# Actions:
#   graph     - Generate dependency graph
#   update    - Update dependencies (not yet implemented)
#   audit     - Security audit (not yet implemented)
#
# Currently dispatches to dependency-graph-parser.sh for 'graph' action

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get action (first argument)
ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
    echo "Error: No action specified"
    echo ""
    echo "Usage: deps-manage.sh <action> [OPTIONS]"
    echo ""
    echo "Actions:"
    echo "  graph     - Generate dependency graph"
    echo "  update    - Update dependencies (not yet implemented)"
    echo "  audit     - Security audit (not yet implemented)"
    exit 1
fi

# Shift to remove action from arguments
shift

# Dispatch to appropriate script
case "$ACTION" in
    graph)
        exec "$SCRIPT_DIR/dependency-graph-parser.sh" "$@"
        ;;
    update)
        echo "Error: 'update' action not yet implemented"
        echo "TODO: Implement dependency update functionality"
        exit 1
        ;;
    audit)
        echo "Error: 'audit' action not yet implemented"
        echo "TODO: Implement dependency security audit"
        exit 1
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Valid actions: graph, update, audit"
        exit 1
        ;;
esac

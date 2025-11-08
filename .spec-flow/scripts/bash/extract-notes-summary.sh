#!/usr/bin/env bash
# Extract recent task completions from NOTES.md for feature CLAUDE.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: extract-notes-summary.sh [--json] [--count N] <feature-dir>

Extract the last N completed tasks from NOTES.md with timestamps and duration.

Options:
  --json          Output in JSON format
  --count N       Number of recent tasks to extract (default: 3)

Arguments:
  feature-dir     Path to feature directory (e.g., specs/001-auth-flow)

Example:
  extract-notes-summary.sh --count 3 specs/001-auth-flow
EOF
}

JSON_OUT=false
COUNT=3

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        --count)
            shift
            if [ $# -eq 0 ]; then
                log_error "--count requires a value"
                exit 1
            fi
            COUNT="$1"
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
    log_error "Provide a feature directory path."
    show_help
    exit 1
fi

FEATURE_DIR="$1"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

if [ ! -f "$NOTES_FILE" ]; then
    log_warn "No NOTES.md found in $FEATURE_DIR"
    if [ "$JSON_OUT" = true ]; then
        echo '{"tasks": [], "count": 0}'
    fi
    exit 0
fi

# Parse NOTES.md for completion markers
# Format:  T001: Description - duration (timestamp)
# Example:  T018: JWT refresh token rotation - 20min (2025-11-08 16:45)

extract_completions() {
    local file="$1"
    local count="$2"

    # Look for completion marker lines starting with ✅
    grep -E '^\s*✅\s+T[0-9]+:' "$file" 2>/dev/null | tail -n "$count" || true
}

parse_completion_line() {
    local line="$1"

    # Extract task ID, description, duration, timestamp
    # Pattern: ✅ T001: Description - duration (timestamp)
    if [[ "$line" =~ ✅[[:space:]]+([T0-9]+):[[:space:]]+(.+)[[:space:]]-[[:space:]]+([0-9]+min)[[:space:]]\(([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2})\) ]]; then
        task_id="${BASH_REMATCH[1]}"
        description="${BASH_REMATCH[2]}"
        duration="${BASH_REMATCH[3]}"
        timestamp="${BASH_REMATCH[4]}"

        if [ "$JSON_OUT" = true ]; then
            printf '{"taskId": "%s", "description": "%s", "duration": "%s", "timestamp": "%s"}' \
                "$task_id" "$description" "$duration" "$timestamp"
        else
            printf "- ✅ %s: %s - %s (%s)\n" "$task_id" "$description" "$duration" "$timestamp"
        fi
    fi
}

# Extract completions
completions=$(extract_completions "$NOTES_FILE" "$COUNT")

if [ -z "$completions" ]; then
    if [ "$JSON_OUT" = true ]; then
        echo '{"tasks": [], "count": 0}'
    fi
    exit 0
fi

# Parse and output
if [ "$JSON_OUT" = true ]; then
    echo -n '{"tasks": ['
    first=true
    while IFS= read -r line; do
        parsed=$(parse_completion_line "$line")
        if [ -n "$parsed" ]; then
            if [ "$first" = false ]; then
                echo -n ', '
            fi
            echo -n "$parsed"
            first=false
        fi
    done <<< "$completions"
    echo '], "count": '$(echo "$completions" | wc -l)'}'
else
    while IFS= read -r line; do
        parse_completion_line "$line"
    done <<< "$completions"
fi

#!/usr/bin/env bash

# Load command usage history for learning system
#
# Usage:
#   source .spec-flow/scripts/utils/load-command-history.sh
#   load_command_history "epic"
#   echo "$HIST_LAST_USED_MODE"     # Output: auto or interactive
#   echo "$HIST_USAGE_AUTO"         # Output: 12
#   echo "$HIST_TOTAL_USES"         # Output: 15
#
# Returns history as environment variables:
#   HIST_LAST_USED_MODE - Most recent mode selection
#   HIST_USAGE_<MODE> - Usage count for each mode (uppercase)
#   HIST_TOTAL_USES - Sum of all usage counts
#   HIST_LAST_UPDATED - ISO 8601 timestamp

set -e

# Load command history for a specific command
load_command_history() {
    local command="$1"
    local history_path="${2:-.spec-flow/memory/command-history.yaml}"

    # Initialize empty history
    HIST_LAST_USED_MODE=""
    HIST_TOTAL_USES=0
    HIST_LAST_UPDATED=""

    # Check if history file exists
    if [[ ! -f "$history_path" ]]; then
        echo "Command history file not found" >&2
        return 0
    fi

    # Read history file
    local history_content
    history_content=$(cat "$history_path")

    # Extract command section
    local command_section
    command_section=$(echo "$history_content" | sed -n "/$command:/,/^[a-z]/p")

    if [[ -z "$command_section" ]]; then
        echo "Command '$command' not found in history" >&2
        return 0
    fi

    # Parse last_used_mode
    HIST_LAST_USED_MODE=$(echo "$command_section" |
        grep "last_used_mode:" |
        sed 's/.*last_used_mode: *//' |
        tr -d '[:space:]')

    if [[ "$HIST_LAST_USED_MODE" == "null" ]]; then
        HIST_LAST_USED_MODE=""
    fi

    # Parse usage_count section
    local in_usage_count=0
    while IFS= read -r line; do
        # Detect usage_count section start
        if [[ "$line" =~ usage_count: ]]; then
            in_usage_count=1
            continue
        fi

        # End of usage_count section
        if [[ $in_usage_count -eq 1 ]] && [[ "$line" =~ ^[[:space:]]{2}[a-z] ]]; then
            in_usage_count=0
        fi

        # Parse mode counts
        if [[ $in_usage_count -eq 1 ]] && [[ "$line" =~ ^[[:space:]]{4}([a-z-]+):[[:space:]]*([0-9]+) ]]; then
            local mode="${BASH_REMATCH[1]}"
            local count="${BASH_REMATCH[2]}"

            # Convert mode to uppercase and replace hyphens with underscores
            local var_name="HIST_USAGE_${mode^^}"
            var_name="${var_name//-/_}"

            # Export as environment variable
            export "${var_name}=${count}"

            # Add to total
            HIST_TOTAL_USES=$((HIST_TOTAL_USES + count))
        fi
    done <<< "$command_section"

    # Parse last_updated
    HIST_LAST_UPDATED=$(echo "$command_section" |
        grep "last_updated:" |
        sed 's/.*last_updated: *//' |
        tr -d '[:space:]')

    if [[ "$HIST_LAST_UPDATED" == "null" ]]; then
        HIST_LAST_UPDATED=""
    fi

    # Export variables
    export HIST_LAST_USED_MODE
    export HIST_TOTAL_USES
    export HIST_LAST_UPDATED

    return 0
}

# Get usage percentage for a mode
get_usage_percentage() {
    local mode_count="$1"
    local total="$2"

    if [[ "$total" -eq 0 ]]; then
        echo "0"
        return
    fi

    local percentage=$((mode_count * 100 / total))
    echo "$percentage"
}

# If sourced, just define functions. If executed, run with args.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_command_history "$@"

    # Print results for testing
    echo "Last used mode: $HIST_LAST_USED_MODE"
    echo "Total uses: $HIST_TOTAL_USES"
    echo "Last updated: $HIST_LAST_UPDATED"

    # Print all HIST_USAGE_ variables
    while IFS='=' read -r name value; do
        if [[ "$name" =~ ^HIST_USAGE_ ]]; then
            echo "$name=$value"
        fi
    done < <(env | grep "^HIST_USAGE_")
fi

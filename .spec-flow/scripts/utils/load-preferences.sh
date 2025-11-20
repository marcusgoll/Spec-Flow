#!/usr/bin/env bash

# Load user preferences from config file with fallback to defaults
#
# Usage:
#   source .spec-flow/scripts/utils/load-preferences.sh
#   load_preferences "epic"
#   echo "$PREF_DEFAULT_MODE"  # Output: interactive or auto
#
# Returns preferences as environment variables:
#   PREF_DEFAULT_MODE - Command's default mode
#   PREF_INCLUDE_DESIGN - Include design system (init-project only)
#   PREF_DEFAULT_STRATEGY - Execution strategy (run-prompt only)
#   PREF_SHOW_USAGE_STATS - Show usage statistics
#   PREF_RECOMMEND_LAST_USED - Mark last-used with star
#   PREF_AUTO_APPROVE_MINOR - Auto-approve minor changes
#   PREF_CI_MODE_DEFAULT - Default to CI mode

set -e

# Default preferences (matches schema defaults)
declare -A DEFAULT_PREFS=(
    [epic_default_mode]="interactive"
    [tasks_default_mode]="standard"
    [init_project_default_mode]="interactive"
    [init_project_include_design]="false"
    [run_prompt_default_strategy]="auto-detect"
    [auto_approve_minor_changes]="false"
    [ci_mode_default]="false"
    [show_usage_stats]="true"
    [recommend_last_used]="true"
)

# Load preferences for a specific command
load_preferences() {
    local command="$1"
    local pref_path="${2:-.spec-flow/config/user-preferences.yaml}"

    # Check if file exists
    if [[ ! -f "$pref_path" ]]; then
        echo "Preferences file not found, using defaults" >&2
        _set_default_preferences "$command"
        return 0
    fi

    # Parse YAML file (simple grep-based parser)
    local yaml_content
    yaml_content=$(cat "$pref_path")

    # Parse command-specific preferences
    case "$command" in
        epic)
            PREF_DEFAULT_MODE=$(echo "$yaml_content" | grep -A 1 "^  epic:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]')
            ;;
        tasks)
            PREF_DEFAULT_MODE=$(echo "$yaml_content" | grep -A 1 "^  tasks:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]')
            ;;
        init-project)
            PREF_DEFAULT_MODE=$(echo "$yaml_content" | grep -A 2 "^  init-project:" | grep "default_mode:" | sed 's/.*default_mode: *//' | tr -d '[:space:]')
            PREF_INCLUDE_DESIGN=$(echo "$yaml_content" | grep -A 2 "^  init-project:" | grep "include_design:" | sed 's/.*include_design: *//' | tr -d '[:space:]')
            ;;
        run-prompt)
            PREF_DEFAULT_STRATEGY=$(echo "$yaml_content" | grep -A 1 "^  run-prompt:" | grep "default_strategy:" | sed 's/.*default_strategy: *//' | tr -d '[:space:]')
            ;;
    esac

    # Parse UI preferences
    PREF_SHOW_USAGE_STATS=$(echo "$yaml_content" | grep "show_usage_stats:" | sed 's/.*show_usage_stats: *//' | tr -d '[:space:]')
    PREF_RECOMMEND_LAST_USED=$(echo "$yaml_content" | grep "recommend_last_used:" | sed 's/.*recommend_last_used: *//' | tr -d '[:space:]')

    # Parse automation preferences
    PREF_AUTO_APPROVE_MINOR=$(echo "$yaml_content" | grep "auto_approve_minor_changes:" | sed 's/.*auto_approve_minor_changes: *//' | tr -d '[:space:]')
    PREF_CI_MODE_DEFAULT=$(echo "$yaml_content" | grep "ci_mode_default:" | sed 's/.*ci_mode_default: *//' | tr -d '[:space:]')

    # Fall back to defaults if any value is empty
    [[ -z "$PREF_DEFAULT_MODE" ]] && PREF_DEFAULT_MODE="${DEFAULT_PREFS[${command//-/_}_default_mode]}"
    [[ -z "$PREF_DEFAULT_STRATEGY" ]] && PREF_DEFAULT_STRATEGY="${DEFAULT_PREFS[${command//-/_}_default_strategy]}"
    [[ -z "$PREF_INCLUDE_DESIGN" ]] && PREF_INCLUDE_DESIGN="${DEFAULT_PREFS[${command//-/_}_include_design]}"
    [[ -z "$PREF_SHOW_USAGE_STATS" ]] && PREF_SHOW_USAGE_STATS="${DEFAULT_PREFS[show_usage_stats]}"
    [[ -z "$PREF_RECOMMEND_LAST_USED" ]] && PREF_RECOMMEND_LAST_USED="${DEFAULT_PREFS[recommend_last_used]}"
    [[ -z "$PREF_AUTO_APPROVE_MINOR" ]] && PREF_AUTO_APPROVE_MINOR="${DEFAULT_PREFS[auto_approve_minor_changes]}"
    [[ -z "$PREF_CI_MODE_DEFAULT" ]] && PREF_CI_MODE_DEFAULT="${DEFAULT_PREFS[ci_mode_default]}"

    # Export for use in calling scripts
    export PREF_DEFAULT_MODE
    export PREF_DEFAULT_STRATEGY
    export PREF_INCLUDE_DESIGN
    export PREF_SHOW_USAGE_STATS
    export PREF_RECOMMEND_LAST_USED
    export PREF_AUTO_APPROVE_MINOR
    export PREF_CI_MODE_DEFAULT

    return 0
}

# Set default preferences for command
_set_default_preferences() {
    local command="$1"

    PREF_DEFAULT_MODE="${DEFAULT_PREFS[${command//-/_}_default_mode]}"
    PREF_DEFAULT_STRATEGY="${DEFAULT_PREFS[${command//-/_}_default_strategy]}"
    PREF_INCLUDE_DESIGN="${DEFAULT_PREFS[${command//-/_}_include_design]}"
    PREF_SHOW_USAGE_STATS="${DEFAULT_PREFS[show_usage_stats]}"
    PREF_RECOMMEND_LAST_USED="${DEFAULT_PREFS[recommend_last_used]}"
    PREF_AUTO_APPROVE_MINOR="${DEFAULT_PREFS[auto_approve_minor_changes]}"
    PREF_CI_MODE_DEFAULT="${DEFAULT_PREFS[ci_mode_default]}"

    export PREF_DEFAULT_MODE
    export PREF_DEFAULT_STRATEGY
    export PREF_INCLUDE_DESIGN
    export PREF_SHOW_USAGE_STATS
    export PREF_RECOMMEND_LAST_USED
    export PREF_AUTO_APPROVE_MINOR
    export PREF_CI_MODE_DEFAULT
}

# If sourced, just define functions. If executed, run with args.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_preferences "$@"
fi

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
    [worktrees_auto_create]="true"
    [worktrees_cleanup_on_finalize]="true"
    [planning_auto_deep_mode]="false"
    [planning_trigger_epic_features]="true"
    [planning_trigger_complexity_threshold]="30"
    [planning_trigger_architecture_change]="true"
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

# Get a specific preference value by key path
# Usage: get_preference_value --key "worktrees.auto_create" --default "false"
get_preference_value() {
    local key=""
    local default_value=""
    local pref_path=".spec-flow/config/user-preferences.yaml"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --key)
                key="$2"
                shift 2
                ;;
            --default)
                default_value="$2"
                shift 2
                ;;
            --config)
                pref_path="$2"
                shift 2
                ;;
            *)
                echo "Unknown argument: $1" >&2
                return 1
                ;;
        esac
    done

    # Validate key is provided
    if [[ -z "$key" ]]; then
        echo "Error: --key argument is required" >&2
        return 1
    fi

    # Check if file exists
    if [[ ! -f "$pref_path" ]]; then
        echo "$default_value"
        return 0
    fi

    # Split key into parts (e.g., "worktrees.auto_create" -> ["worktrees", "auto_create"])
    IFS='.' read -ra KEY_PARTS <<< "$key"

    # Try to extract value using grep/sed
    local yaml_content
    yaml_content=$(cat "$pref_path")
    local value=""

    case "${#KEY_PARTS[@]}" in
        1)
            # Top-level key (e.g., "show_usage_stats")
            value=$(echo "$yaml_content" | grep "^${KEY_PARTS[0]}:" | head -1 | sed "s/.*${KEY_PARTS[0]}: *//" | tr -d '[:space:]')
            ;;
        2)
            # Nested key (e.g., "worktrees.auto_create")
            value=$(echo "$yaml_content" | grep -A 10 "^${KEY_PARTS[0]}:" | grep "  ${KEY_PARTS[1]}:" | head -1 | sed "s/.*${KEY_PARTS[1]}: *//" | tr -d '[:space:]')
            ;;
        3)
            # Double-nested key (e.g., "commands.epic.default_mode")
            # More precise extraction: find parent section, then child section, then specific key
            value=$(echo "$yaml_content" | awk "/^${KEY_PARTS[0]}:/{flag=1; next} flag && /^[a-z]/{exit} flag && /^  ${KEY_PARTS[1]}:/{subflag=1; next} subflag && /^  [a-z]/{exit} subflag && /    ${KEY_PARTS[2]}:/{print; exit}" | sed "s/.*${KEY_PARTS[2]}: *//" | tr -d '[:space:]')
            ;;
        *)
            echo "Error: Key path too deep (max 3 levels)" >&2
            echo "$default_value"
            return 0
            ;;
    esac

    # Return value or default
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default_value"
    fi

    return 0
}

# Load worktree-specific preferences
# Usage: load_worktree_preferences [config_path]
# Sets: PREF_WORKTREES_AUTO_CREATE, PREF_WORKTREES_CLEANUP_ON_FINALIZE
load_worktree_preferences() {
    local pref_path="${1:-.spec-flow/config/user-preferences.yaml}"

    PREF_WORKTREES_AUTO_CREATE=$(get_preference_value --key "worktrees.auto_create" --default "true" --config "$pref_path")
    PREF_WORKTREES_CLEANUP_ON_FINALIZE=$(get_preference_value --key "worktrees.cleanup_on_finalize" --default "true" --config "$pref_path")

    export PREF_WORKTREES_AUTO_CREATE
    export PREF_WORKTREES_CLEANUP_ON_FINALIZE

    return 0
}

# Load planning/ultrathink preferences
# Usage: load_planning_preferences [config_path]
# Sets: PREF_PLANNING_AUTO_DEEP_MODE, PREF_PLANNING_TRIGGER_*
load_planning_preferences() {
    local pref_path="${1:-.spec-flow/config/user-preferences.yaml}"

    # Master switch for auto deep mode
    PREF_PLANNING_AUTO_DEEP_MODE=$(get_preference_value --key "planning.auto_deep_mode" --default "false" --config "$pref_path")

    # Deep planning triggers
    PREF_PLANNING_TRIGGER_EPIC_FEATURES=$(get_preference_value --key "planning.deep_planning_triggers.epic_features" --default "true" --config "$pref_path")
    PREF_PLANNING_TRIGGER_COMPLEXITY_THRESHOLD=$(get_preference_value --key "planning.deep_planning_triggers.complexity_threshold" --default "30" --config "$pref_path")
    PREF_PLANNING_TRIGGER_ARCHITECTURE_CHANGE=$(get_preference_value --key "planning.deep_planning_triggers.architecture_change" --default "true" --config "$pref_path")

    export PREF_PLANNING_AUTO_DEEP_MODE
    export PREF_PLANNING_TRIGGER_EPIC_FEATURES
    export PREF_PLANNING_TRIGGER_COMPLEXITY_THRESHOLD
    export PREF_PLANNING_TRIGGER_ARCHITECTURE_CHANGE

    return 0
}

# Check if deep planning should be enabled for a given context
# Usage: should_enable_deep_planning [--is-epic] [--complexity N] [--is-new-pattern] [config_path]
# Returns: 0 (true) if deep planning should be enabled, 1 (false) otherwise
should_enable_deep_planning() {
    local is_epic="false"
    local complexity="0"
    local is_new_pattern="false"
    local pref_path=".spec-flow/config/user-preferences.yaml"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --is-epic)
                is_epic="true"
                shift
                ;;
            --complexity)
                complexity="$2"
                shift 2
                ;;
            --is-new-pattern)
                is_new_pattern="true"
                shift
                ;;
            --config)
                pref_path="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Load preferences
    load_planning_preferences "$pref_path"

    # Check master switch first
    if [[ "$PREF_PLANNING_AUTO_DEEP_MODE" == "true" ]]; then
        return 0
    fi

    # Check epic trigger
    if [[ "$is_epic" == "true" && "$PREF_PLANNING_TRIGGER_EPIC_FEATURES" == "true" ]]; then
        return 0
    fi

    # Check complexity threshold
    if [[ "$complexity" -gt 0 && "$complexity" -ge "$PREF_PLANNING_TRIGGER_COMPLEXITY_THRESHOLD" ]]; then
        return 0
    fi

    # Check architecture change trigger
    if [[ "$is_new_pattern" == "true" && "$PREF_PLANNING_TRIGGER_ARCHITECTURE_CHANGE" == "true" ]]; then
        return 0
    fi

    return 1
}

# If sourced, just define functions. If executed, run with args.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if --key flag is present (new mode)
    if [[ "$1" == "--key" ]]; then
        get_preference_value "$@"
    elif [[ "$1" == "--worktrees" ]]; then
        load_worktree_preferences "${2:-}"
        echo "PREF_WORKTREES_AUTO_CREATE=$PREF_WORKTREES_AUTO_CREATE"
        echo "PREF_WORKTREES_CLEANUP_ON_FINALIZE=$PREF_WORKTREES_CLEANUP_ON_FINALIZE"
    elif [[ "$1" == "--planning" ]]; then
        load_planning_preferences "${2:-}"
        echo "PREF_PLANNING_AUTO_DEEP_MODE=$PREF_PLANNING_AUTO_DEEP_MODE"
        echo "PREF_PLANNING_TRIGGER_EPIC_FEATURES=$PREF_PLANNING_TRIGGER_EPIC_FEATURES"
        echo "PREF_PLANNING_TRIGGER_COMPLEXITY_THRESHOLD=$PREF_PLANNING_TRIGGER_COMPLEXITY_THRESHOLD"
        echo "PREF_PLANNING_TRIGGER_ARCHITECTURE_CHANGE=$PREF_PLANNING_TRIGGER_ARCHITECTURE_CHANGE"
    elif [[ "$1" == "--should-deep-plan" ]]; then
        shift
        if should_enable_deep_planning "$@"; then
            echo "true"
        else
            echo "false"
        fi
    else
        load_preferences "$@"
    fi
fi

#!/usr/bin/env bash
# Auto-Apply Learnings - Automatically applies low-risk patterns
# Runs during workflow to apply performance patterns and abbreviations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
LEARNINGS_DIR="$REPO_ROOT/.spec-flow/learnings"
PERF_PATTERNS_FILE="$LEARNINGS_DIR/performance-patterns.yaml"
ANTI_PATTERNS_FILE="$LEARNINGS_DIR/anti-patterns.yaml"
ABBR_FILE="$LEARNINGS_DIR/custom-abbreviations.yaml"

# ============================================================================
# Helper Functions
# ============================================================================

check_learning_enabled() {
    local enabled="false"
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        enabled=$(grep "enabled:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null | grep -A 1 "learning:" | tail -1 | awk '{print $2}')
    fi
    [ "$enabled" = "true" ]
}

check_auto_apply_enabled() {
    local enabled="false"
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        enabled=$(grep "auto_apply_low_risk:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null | grep -A 1 "learning:" | tail -1 | awk '{print $2}')
    fi
    [ "$enabled" = "true" ]
}

# ============================================================================
# Performance Pattern Application
# ============================================================================

get_tool_recommendation() {
    local context="$1"

    if [ ! -f "$PERF_PATTERNS_FILE" ]; then
        return 1
    fi

    # Find applicable pattern for context
    local pattern
    pattern=$(yq eval ".patterns[] | select(.context == \"$context\" and .auto_applied == true) | .recommendation" "$PERF_PATTERNS_FILE" 2>/dev/null | head -1)

    if [ -n "$pattern" ]; then
        echo "$pattern"
        return 0
    fi

    return 1
}

suggest_tool_usage() {
    local operation="$1"
    local context="$2"

    # Check if there's a learned pattern for this operation
    local recommendation
    if recommendation=$(get_tool_recommendation "$context"); then
        log_info "💡 Learning suggestion: $recommendation"
        return 0
    fi

    return 1
}

# ============================================================================
# Anti-Pattern Checking
# ============================================================================

check_anti_pattern() {
    local operation="$1"
    local context="$2"

    if [ ! -f "$ANTI_PATTERNS_FILE" ]; then
        return 0
    fi

    # Check if operation matches known anti-pattern
    local matches
    matches=$(yq eval ".antipatterns[] | select(.context == \"$context\" and .auto_warn == true)" "$ANTI_PATTERNS_FILE" 2>/dev/null)

    if [ -n "$matches" ]; then
        local warning
        warning=$(echo "$matches" | yq eval '.warning_message' 2>/dev/null | head -1)

        local prevention
        prevention=$(echo "$matches" | yq eval '.prevention' 2>/dev/null | head -1)

        if [ -n "$warning" ]; then
            log_warn "$warning"
            if [ -n "$prevention" ]; then
                log_info "Prevention: $prevention"
            fi
            return 1
        fi
    fi

    return 0
}

# Check specific anti-patterns before operations
check_schema_edit() {
    local file="$1"

    # Check if editing schema file without migration
    if [[ "$file" =~ schema\.(prisma|sql|js|ts) ]]; then
        if ! check_anti_pattern "schema-edit" "schema changes"; then
            log_warn "⚠️  Detected schema file edit"
            log_info "💡 Tip: Create migration before editing schema"
            # Don't block, just warn
        fi
    fi
}

# ============================================================================
# Abbreviation Expansion
# ============================================================================

expand_abbreviation() {
    local text="$1"

    if [ ! -f "$ABBR_FILE" ]; then
        echo "$text"
        return
    fi

    local expanded="$text"

    # Get all auto-expand abbreviations
    local abbrs
    abbrs=$(yq eval '.abbreviations[] | select(.auto_expand == true) | "\(.abbr):\(.expansion)"' "$ABBR_FILE" 2>/dev/null)

    if [ -z "$abbrs" ]; then
        echo "$text"
        return
    fi

    # Expand each abbreviation found in text
    while IFS=: read -r abbr expansion; do
        if [[ "$text" =~ (^|[[:space:]])${abbr}([[:space:]]|$) ]]; then
            log_info "💡 Expanding abbreviation: '$abbr' → '$expansion'"
            expanded="${expanded//$abbr/$expansion}"
        fi
    done <<< "$abbrs"

    echo "$expanded"
}

# ============================================================================
# Workflow Integration Hooks
# ============================================================================

# Hook: Before tool usage
before_tool_use() {
    local tool="$1"
    local operation="$2"
    local context="${3:-general}"

    if ! check_learning_enabled || ! check_auto_apply_enabled; then
        return 0
    fi

    # Suggest alternative tools based on learned patterns
    suggest_tool_usage "$operation" "$context" || true

    # Check for anti-patterns
    check_anti_pattern "$operation" "$context" || true
}

# Hook: Before file edit
before_file_edit() {
    local file="$1"

    if ! check_learning_enabled || ! check_auto_apply_enabled; then
        return 0
    fi

    # Check schema edit anti-pattern
    check_schema_edit "$file" || true
}

# Hook: Expand text with abbreviations
expand_text() {
    local text="$1"

    if ! check_learning_enabled || ! check_auto_apply_enabled; then
        echo "$text"
        return
    fi

    expand_abbreviation "$text"
}

# ============================================================================
# Command Interface
# ============================================================================

show_help() {
    cat <<'EOF'
Usage: auto-apply-learnings.sh <command> [args]

Commands:
  before-tool <tool> <operation> [context]   Check before tool use
  before-edit <file>                          Check before file edit
  expand-text <text>                          Expand abbreviations
  suggest <operation> <context>               Get tool suggestions

Examples:
  # Before using Grep
  auto-apply-learnings.sh before-tool Grep search "large files"

  # Before editing schema file
  auto-apply-learnings.sh before-edit schema.prisma

  # Expand abbreviations in spec text
  auto-apply-learnings.sh expand-text "Add auth to dashboard"
EOF
}

# ============================================================================
# Main Command Router
# ============================================================================

main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        before-tool)
            if [ $# -lt 2 ]; then
                log_error "Usage: auto-apply-learnings.sh before-tool <tool> <operation> [context]"
                exit 1
            fi
            before_tool_use "$1" "$2" "${3:-general}"
            ;;

        before-edit)
            if [ $# -lt 1 ]; then
                log_error "Usage: auto-apply-learnings.sh before-edit <file>"
                exit 1
            fi
            before_file_edit "$1"
            ;;

        expand-text)
            if [ $# -lt 1 ]; then
                log_error "Usage: auto-apply-learnings.sh expand-text <text>"
                exit 1
            fi
            expand_text "$*"
            ;;

        suggest)
            if [ $# -lt 2 ]; then
                log_error "Usage: auto-apply-learnings.sh suggest <operation> <context>"
                exit 1
            fi
            suggest_tool_usage "$1" "$2"
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"

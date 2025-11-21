#!/usr/bin/env bash
# CLAUDE.md Optimization Engine
# Safely appends project-specific learnings to CLAUDE.md with approval

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
LEARNINGS_DIR="$REPO_ROOT/.spec-flow/learnings"
TWEAKS_FILE="$LEARNINGS_DIR/claude-md-tweaks.yaml"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
PROJECT_CLAUDE_MD="$REPO_ROOT/docs/project/CLAUDE.md"

LEARNING_SECTION="## Project-Specific Learnings (Auto-Generated)"
DRY_RUN=false

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    cat <<'EOF'
Usage: optimize-claude-md.sh [options]

Options:
  --apply <tweak-id>      Apply specific tweak by ID
  --dry-run               Show what would be applied without making changes
  --list-pending          List all pending tweaks
  --approve <tweak-id>    Mark tweak as approved (requires --apply)
  --reject <tweak-id>     Mark tweak as rejected
  -h, --help              Show this help

Description:
  Safely modifies CLAUDE.md by appending project-specific learnings.
  All modifications are append-only and clearly marked as auto-generated.

Examples:
  # List pending tweaks
  optimize-claude-md.sh --list-pending

  # Dry run to see what would be applied
  optimize-claude-md.sh --apply tweak-001 --dry-run

  # Apply approved tweak
  optimize-claude-md.sh --apply tweak-001 --approve

  # Reject a tweak
  optimize-claude-md.sh --reject tweak-001
EOF
}

check_optimization_enabled() {
    local enabled="false"
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        enabled=$(grep "claude_md_optimization:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null | grep -A 1 "learning:" | tail -1 | awk '{print $2}')
    fi
    [ "$enabled" = "true" ]
}

list_pending_tweaks() {
    if [ ! -f "$TWEAKS_FILE" ]; then
        log_info "No tweaks file found"
        return
    fi

    local pending_count
    pending_count=$(yq eval '.tweaks[] | select(.status == "pending") | .id' "$TWEAKS_FILE" 2>/dev/null | wc -l)

    if [ "$pending_count" -eq 0 ]; then
        log_info "No pending tweaks"
        return
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Pending CLAUDE.md Tweaks ($pending_count)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    yq eval '.tweaks[] | select(.status == "pending")' "$TWEAKS_FILE" 2>/dev/null | while IFS= read -r tweak; do
        if [ -z "$tweak" ]; then
            continue
        fi

        local id
        id=$(echo "$tweak" | yq eval '.id')

        local name
        name=$(echo "$tweak" | yq eval '.name')

        local impact
        impact=$(echo "$tweak" | yq eval '.impact')

        local confidence
        confidence=$(echo "$tweak" | yq eval '.confidence')

        echo "📝 $id"
        echo "   Name: $name"
        echo "   Impact: $impact | Confidence: $(printf "%.0f%%" "$((confidence * 100))")"
        echo ""
    done
}

get_tweak_details() {
    local tweak_id="$1"

    if [ ! -f "$TWEAKS_FILE" ]; then
        log_error "Tweaks file not found"
        return 1
    fi

    local tweak
    tweak=$(yq eval ".tweaks[] | select(.id == \"$tweak_id\")" "$TWEAKS_FILE" 2>/dev/null)

    if [ -z "$tweak" ]; then
        log_error "Tweak not found: $tweak_id"
        return 1
    fi

    echo "$tweak"
}

ensure_learning_section() {
    local target_file="$1"

    if [ ! -f "$target_file" ]; then
        log_error "CLAUDE.md not found: $target_file"
        return 1
    fi

    # Check if learning section already exists
    if ! grep -q "^$LEARNING_SECTION" "$target_file"; then
        # Append learning section at the end
        cat >> "$target_file" <<EOF

$LEARNING_SECTION

> **Note**: This section is automatically generated from project learnings.
> It contains optimizations specific to this project based on observed patterns.
> You can edit or remove entries manually if needed.

EOF
        log_success "Created learning section in CLAUDE.md"
    fi
}

apply_tweak() {
    local tweak_id="$1"
    local approve="${2:-false}"

    # Get tweak details
    local tweak
    tweak=$(get_tweak_details "$tweak_id")

    if [ $? -ne 0 ]; then
        return 1
    fi

    local name
    name=$(echo "$tweak" | yq eval '.name')

    local content
    content=$(echo "$tweak" | yq eval '.content')

    local status
    status=$(echo "$tweak" | yq eval '.status')

    # Check status
    if [ "$status" != "pending" ] && [ "$approve" != "true" ]; then
        log_error "Tweak is not pending: $status"
        return 1
    fi

    # Check if optimization is enabled
    if ! check_optimization_enabled; then
        log_error "CLAUDE.md optimization is disabled in preferences"
        log_info "Enable with: /init-preferences"
        return 1
    fi

    # Determine target file (project or root)
    local target_file="$PROJECT_CLAUDE_MD"
    if [ ! -f "$target_file" ]; then
        target_file="$CLAUDE_MD"
    fi

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would apply tweak: $name"
        log_info "[DRY-RUN] Target file: $target_file"
        log_info "[DRY-RUN] Content:"
        echo "$content"
        return 0
    fi

    # Ensure learning section exists
    ensure_learning_section "$target_file"

    # Append content to learning section
    {
        echo ""
        echo "### $name"
        echo ""
        echo "$content"
    } >> "$target_file"

    log_success "Applied tweak: $name"

    # Update tweak status
    if [ "$approve" = "true" ]; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        yq eval "(.tweaks[] | select(.id == \"$tweak_id\") | .status) = \"applied\"" -i "$TWEAKS_FILE" 2>/dev/null
        yq eval "(.tweaks[] | select(.id == \"$tweak_id\") | .applied) = \"$timestamp\"" -i "$TWEAKS_FILE" 2>/dev/null

        log_success "Marked tweak as applied"
    fi
}

reject_tweak() {
    local tweak_id="$1"

    if [ ! -f "$TWEAKS_FILE" ]; then
        log_error "Tweaks file not found"
        return 1
    fi

    # Update tweak status
    yq eval "(.tweaks[] | select(.id == \"$tweak_id\") | .status) = \"rejected\"" -i "$TWEAKS_FILE" 2>/dev/null

    log_success "Rejected tweak: $tweak_id"
}

# ============================================================================
# Main Command Router
# ============================================================================

main() {
    local tweak_id=""
    local approve=false
    local reject=false
    local list_pending=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply)
                shift
                tweak_id="$1"
                shift
                ;;
            --approve)
                shift
                tweak_id="$1"
                approve=true
                shift
                ;;
            --reject)
                shift
                tweak_id="$1"
                reject=true
                shift
                ;;
            --list-pending)
                list_pending=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Execute command
    if [ "$list_pending" = true ]; then
        list_pending_tweaks
    elif [ "$reject" = true ]; then
        if [ -z "$tweak_id" ]; then
            log_error "Tweak ID required for --reject"
            exit 1
        fi
        reject_tweak "$tweak_id"
    elif [ -n "$tweak_id" ]; then
        apply_tweak "$tweak_id" "$approve"
    else
        show_help
        exit 1
    fi
}

# Run main
main "$@"

#!/bin/bash
# session-manager.sh - CLI interface for Spec-Flow session management
#
# This script provides commands for managing sessions across context windows,
# generating handoffs, and tracking workflow progress through multiple sessions.
#
# Usage:
#   session-manager.sh start [--autopilot]
#   session-manager.sh end [--summary "summary text"]
#   session-manager.sh status
#   session-manager.sh handoff [--force]
#   session-manager.sh decision "decision text"
#   session-manager.sh autopilot [on|off|status]
#   session-manager.sh history
#
# Version: 1.0.0

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
# shellcheck source=/dev/null
source "$SCRIPT_DIR/shared-lib.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$SCRIPT_DIR/workflow-state.sh" 2>/dev/null || true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

detect_workflow_dir() {
    local detect_script="$SCRIPT_DIR/../utils/detect-workflow-paths.sh"

    if [ ! -f "$detect_script" ]; then
        echo ""
        return 1
    fi

    local workflow_info
    workflow_info=$("$detect_script" 2>/dev/null || echo "")

    if [ -z "$workflow_info" ]; then
        echo ""
        return 1
    fi

    local workflow_type base_dir slug
    workflow_type=$(echo "$workflow_info" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    base_dir=$(echo "$workflow_info" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    slug=$(echo "$workflow_info" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$workflow_type" ] || [ "$workflow_type" = "unknown" ]; then
        echo ""
        return 1
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

    echo "$repo_root/$base_dir/$slug"
}

show_usage() {
    cat <<EOF
Session Manager - Manage Spec-Flow sessions across context windows

Usage: session-manager.sh <command> [options]

Commands:
  start [--autopilot]         Start a new session (optionally enable autopilot)
  end [--summary "text"]      End the current session with optional summary
  status                      Show current session status
  handoff [--force]           Generate a handoff document for the current state
  decision "text"             Record a key decision made in this session
  autopilot [on|off|status]   Control autopilot mode for multi-context workflows
  history                     Show session history for current workflow

Options:
  -h, --help                  Show this help message

Examples:
  session-manager.sh start --autopilot
  session-manager.sh decision "Using Redis for token blacklist"
  session-manager.sh handoff
  session-manager.sh end --summary "Completed auth middleware implementation"

EOF
}

# ============================================================================
# COMMAND HANDLERS
# ============================================================================

cmd_start() {
    local autopilot=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --autopilot)
                autopilot=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        echo "Start a feature or epic first with /feature or /epic" >&2
        return 1
    fi

    # Start session
    start_session "$workflow_dir"

    # Enable autopilot if requested
    if [ "$autopilot" = true ]; then
        enable_autopilot "$workflow_dir"
    fi

    # Show initial status
    get_session_summary "$workflow_dir"
}

cmd_end() {
    local summary=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --summary)
                summary="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    # End session
    end_session "$workflow_dir" "$summary"

    # Show final summary
    get_session_summary "$workflow_dir"
}

cmd_status() {
    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    local state_file="$workflow_dir/state.yaml"

    if [ ! -f "$state_file" ]; then
        echo "Error: No workflow state found" >&2
        return 1
    fi

    # Display comprehensive status
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Session Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Workflow info
    local slug phase status
    slug=$(yq eval '.feature.slug // .epic.slug' "$state_file")
    phase=$(yq eval '.workflow.phase' "$state_file")
    status=$(yq eval '.workflow.status' "$state_file")

    echo ""
    echo "Workflow: $slug"
    echo "Phase:    $phase"
    echo "Status:   $status"
    echo ""

    # Session info
    get_session_summary "$workflow_dir"

    # Tasks progress
    local tasks_file="$workflow_dir/tasks.md"
    if [ -f "$tasks_file" ]; then
        local total completed remaining
        total=$(grep -c '^\- \[' "$tasks_file" 2>/dev/null || echo "0")
        completed=$(grep -c '^\- \[x\]' "$tasks_file" 2>/dev/null || echo "0")
        remaining=$((total - completed))

        echo "Task Progress"
        echo "============="
        echo "Total:     $total"
        echo "Completed: $completed"
        echo "Remaining: $remaining"
        echo ""
    fi

    # Autopilot status
    local autopilot
    autopilot=$(yq eval '.session.autopilot_enabled // false' "$state_file")
    echo "Autopilot: $autopilot"
    echo ""

    # Last handoff
    local last_handoff
    last_handoff=$(yq eval '.session.last_handoff_at // "none"' "$state_file")
    if [ "$last_handoff" != "none" ] && [ "$last_handoff" != "null" ]; then
        echo "Last Handoff: $last_handoff"
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

cmd_handoff() {
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    # Create sessions directory
    local sessions_dir="$workflow_dir/sessions"
    mkdir -p "$sessions_dir"

    # Generate handoff using the PreCompact hook logic
    local timestamp session_id
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    session_id=$(date +%Y%m%d-%H%M%S)

    local state_file="$workflow_dir/state.yaml"
    local phase status
    phase=$(yq eval '.workflow.phase' "$state_file" 2>/dev/null || echo "unknown")
    status=$(yq eval '.workflow.status' "$state_file" 2>/dev/null || echo "unknown")

    # Get workflow type
    local workflow_type="feature"
    if [ -f "$workflow_dir/epic-spec.md" ]; then
        workflow_type="epic"
    fi

    # Get task progress
    local tasks_file="$workflow_dir/tasks.md"
    local tasks_total=0 tasks_completed=0 current_task=""

    if [ -f "$tasks_file" ]; then
        tasks_total=$(grep -c '^\- \[' "$tasks_file" 2>/dev/null || echo "0")
        tasks_completed=$(grep -c '^\- \[x\]' "$tasks_file" 2>/dev/null || echo "0")
        current_task=$(grep -m1 '^\- \[ \]' "$tasks_file" 2>/dev/null | sed 's/^- \[ \] //' || echo "None pending")
    fi

    # Get recent decisions
    local decisions
    decisions=$(yq eval '.session.decisions_made | .[-3:]' "$state_file" 2>/dev/null || echo "")

    # Generate handoff document
    local handoff_file="$sessions_dir/handoff-$session_id.md"
    local latest_handoff="$sessions_dir/latest-handoff.md"

    cat > "$handoff_file" <<EOF
# Session Handoff: $(basename "$workflow_dir")

> Generated: $timestamp
> Trigger: Manual handoff generation
> Phase: $phase
> Status: $status

## Quick Resume

\`\`\`bash
# Continue this workflow:
/$workflow_type continue
\`\`\`

## Current State

| Metric | Value |
|--------|-------|
| Workflow Type | $workflow_type |
| Slug | $(basename "$workflow_dir") |
| Current Phase | $phase |
| Phase Status | $status |
| Tasks Progress | $tasks_completed / $tasks_total |

## Next Task

$current_task

## Recent Decisions

$decisions

## Key Artifacts

- State: \`state.yaml\`
- Tasks: \`tasks.md\`
- Notes: \`NOTES.md\`
EOF

    if [ -f "$workflow_dir/plan.md" ]; then
        echo "- Plan: \`plan.md\`" >> "$handoff_file"
    fi

    if [ -f "$workflow_dir/spec.md" ]; then
        echo "- Spec: \`spec.md\`" >> "$handoff_file"
    fi

    cat >> "$handoff_file" <<EOF

## Context for Next Session

1. Read state.yaml for complete workflow state
2. Check tasks.md for task completion status
3. Review NOTES.md for recent decisions and blockers
4. Use \`/context next\` for detailed next steps

---

*This handoff was manually generated.*
*Session ID: $session_id*
EOF

    # Update latest handoff
    cp "$handoff_file" "$latest_handoff"

    # Record in state
    record_session_handoff "$workflow_dir" "$session_id"

    echo ""
    echo "Handoff generated: sessions/handoff-$session_id.md"
    echo "Also available at: sessions/latest-handoff.md"
    echo ""
}

cmd_decision() {
    local decision="$1"

    if [ -z "$decision" ]; then
        echo "Error: Decision text required" >&2
        echo "Usage: session-manager.sh decision \"decision text\"" >&2
        return 1
    fi

    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    # Record decision
    record_session_decision "$workflow_dir" "$decision"

    # Also append to NOTES.md
    local notes_file="$workflow_dir/NOTES.md"
    if [ -f "$notes_file" ]; then
        local timestamp
        timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

        {
            echo ""
            echo "**Decision** ($timestamp): $decision"
        } >> "$notes_file"
    fi

    echo "Decision recorded: $decision"
}

cmd_autopilot() {
    local action="${1:-status}"

    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    case "$action" in
        on|enable)
            enable_autopilot "$workflow_dir"
            ;;
        off|disable)
            disable_autopilot "$workflow_dir"
            ;;
        status)
            local state_file="$workflow_dir/state.yaml"
            local enabled
            enabled=$(yq eval '.session.autopilot_enabled // false' "$state_file")
            echo "Autopilot mode: $enabled"
            ;;
        *)
            echo "Unknown action: $action" >&2
            echo "Usage: session-manager.sh autopilot [on|off|status]" >&2
            return 1
            ;;
    esac
}

cmd_history() {
    local workflow_dir
    workflow_dir=$(detect_workflow_dir)

    if [ -z "$workflow_dir" ]; then
        echo "Error: No active workflow detected" >&2
        return 1
    fi

    local sessions_dir="$workflow_dir/sessions"

    if [ ! -d "$sessions_dir" ]; then
        echo "No session history found"
        return 0
    fi

    echo ""
    echo "Session History"
    echo "==============="
    echo ""

    # List handoff files
    local handoff_files
    handoff_files=$(ls -1t "$sessions_dir"/handoff-*.md 2>/dev/null || echo "")

    if [ -z "$handoff_files" ]; then
        echo "No handoff documents found"
        return 0
    fi

    for file in $handoff_files; do
        local filename timestamp phase
        filename=$(basename "$file")
        timestamp=$(grep '^> Generated:' "$file" 2>/dev/null | sed 's/> Generated: //' || echo "Unknown")
        phase=$(grep '^> Phase:' "$file" 2>/dev/null | sed 's/> Phase: //' || echo "Unknown")

        echo "  $filename"
        echo "    Generated: $timestamp"
        echo "    Phase: $phase"
        echo ""
    done

    # Show count
    local count
    count=$(echo "$handoff_files" | wc -l | tr -d ' ')
    echo "Total handoffs: $count"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-}"

    case "$command" in
        start)
            shift
            cmd_start "$@"
            ;;
        end)
            shift
            cmd_end "$@"
            ;;
        status)
            cmd_status
            ;;
        handoff)
            shift
            cmd_handoff "$@"
            ;;
        decision)
            shift
            cmd_decision "$@"
            ;;
        autopilot)
            shift
            cmd_autopilot "$@"
            ;;
        history)
            cmd_history
            ;;
        -h|--help|help)
            show_usage
            ;;
        "")
            show_usage
            return 1
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_usage
            return 1
            ;;
    esac
}

# Run main if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

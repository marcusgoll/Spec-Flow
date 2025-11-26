#!/usr/bin/env bash
# Learning Collector - Passive observation and metrics collection
# Runs in background after phase completion, never blocks workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
LEARNINGS_DIR="$REPO_ROOT/.spec-flow/learnings"
OBSERVATIONS_DIR="$LEARNINGS_DIR/observations"
METADATA_FILE="$LEARNINGS_DIR/learning-metadata.yaml"

# Ensure directories exist
ensure_directory "$LEARNINGS_DIR"
ensure_directory "$OBSERVATIONS_DIR"

# ============================================================================
# Helper Functions
# ============================================================================

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

check_learning_enabled() {
    local enabled="false"
    if [ -f "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" ]; then
        enabled=$(grep "enabled:" "$REPO_ROOT/.spec-flow/config/user-preferences.yaml" 2>/dev/null | grep -A 1 "learning:" | tail -1 | awk '{print $2}')
    fi
    [ "$enabled" = "true" ]
}

# ============================================================================
# Observation Collection
# ============================================================================

# Collect task completion metrics
collect_task_observation() {
    local task_id="$1"
    local duration_seconds="$2"
    local success="$3"  # true/false
    local tools_used="$4"  # comma-separated
    local retries="${5:-0}"
    local blocker="${6:-none}"

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/task-observations-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  task_id: "$task_id"
  duration_seconds: $duration_seconds
  success: $success
  tools_used: [$tools_used]
  retries: $retries
  blocker: "$blocker"
EOF

    log_info "Task observation recorded: $task_id (${duration_seconds}s)"
}

# Collect tool usage patterns
collect_tool_observation() {
    local tool_name="$1"
    local operation="$2"  # e.g., "Read", "Grep", "Edit"
    local duration_ms="$3"
    local success="$4"  # true/false
    local context="${5:-general}"  # e.g., "large file", "search", etc.

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/tool-observations-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  tool: "$tool_name"
  operation: "$operation"
  duration_ms: $duration_ms
  success: $success
  context: "$context"
EOF
}

# Collect quality gate results
collect_quality_gate_observation() {
    local gate_name="$1"
    local result="$2"  # pass/fail/warn
    local issues_found="$3"
    local duration_seconds="$4"
    local false_positives="${5:-0}"

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/quality-gate-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  gate: "$gate_name"
  result: "$result"
  issues_found: $issues_found
  duration_seconds: $duration_seconds
  false_positives: $false_positives
EOF
}

# Collect agent usage patterns
collect_agent_observation() {
    local agent_type="$1"
    local task_type="$2"  # e.g., "backend", "frontend", "database"
    local duration_seconds="$3"
    local success="$4"  # true/false
    local task_complexity="${5:-medium}"  # low/medium/high

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/agent-observations-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  agent_type: "$agent_type"
  task_type: "$task_type"
  duration_seconds: $duration_seconds
  success: $success
  complexity: "$task_complexity"
EOF
}

# Collect abbreviation usage
collect_abbreviation_observation() {
    local abbr="$1"
    local expansion="$2"
    local context="$3"

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/abbreviation-observations-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  abbr: "$abbr"
  expansion: "$expansion"
  context: "$context"
EOF
}

# Collect error/failure patterns (potential anti-patterns)
collect_failure_observation() {
    local failure_type="$1"  # e.g., "schema-edit-without-migration"
    local severity="$2"  # low/medium/high/critical
    local description="$3"
    local context="$4"

    local timestamp
    timestamp=$(get_timestamp)

    local obs_file="$OBSERVATIONS_DIR/failure-observations-$(date +%Y%m%d).yaml"

    cat >> "$obs_file" <<EOF
- timestamp: "$timestamp"
  failure_type: "$failure_type"
  severity: "$severity"
  description: "$description"
  context: "$context"
EOF
}

# ============================================================================
# Phase-Specific Collection
# ============================================================================

# Collect from completed phase
collect_phase_metrics() {
    local phase="$1"
    local feature_dir="$2"

    # Read workflow state
    local state_file="$feature_dir/state.yaml"
    if [ ! -f "$state_file" ]; then
        log_warn "Workflow state not found: $state_file"
        return 1
    fi

    local phase_start
    phase_start=$(yq eval ".phases.${phase}.started" "$state_file" 2>/dev/null || echo "")

    local phase_end
    phase_end=$(yq eval ".phases.${phase}.completed" "$state_file" 2>/dev/null || echo "")

    if [ -z "$phase_start" ] || [ -z "$phase_end" ]; then
        log_warn "Phase timestamps not found for: $phase"
        return 1
    fi

    # Calculate duration (simplified - would need better date parsing)
    local duration_seconds=0
    # TODO: Implement proper timestamp diff calculation

    # Collect phase-specific observations
    case "$phase" in
        implement)
            collect_implementation_metrics "$feature_dir" "$duration_seconds"
            ;;
        optimize)
            collect_optimization_metrics "$feature_dir" "$duration_seconds"
            ;;
        ship-staging|ship-prod)
            collect_deployment_metrics "$feature_dir" "$duration_seconds"
            ;;
    esac
}

# Collect implementation phase metrics
collect_implementation_metrics() {
    local feature_dir="$1"
    local duration="$2"

    # Parse tasks.md for task completion data
    local tasks_file="$feature_dir/tasks.md"
    if [ -f "$tasks_file" ]; then
        # Extract completed tasks
        local completed_count
        completed_count=$(grep -c "^\- \[x\]" "$tasks_file" 2>/dev/null || echo "0")

        # Record observation
        local timestamp
        timestamp=$(get_timestamp)

        cat >> "$OBSERVATIONS_DIR/phase-implementation-$(date +%Y%m%d).yaml" <<EOF
- timestamp: "$timestamp"
  feature_dir: "$feature_dir"
  duration_seconds: $duration
  tasks_completed: $completed_count
EOF
    fi
}

# Collect optimization phase metrics
collect_optimization_metrics() {
    local feature_dir="$1"
    local duration="$2"

    # Parse optimization report
    local opt_report="$feature_dir/optimization-report.md"
    if [ -f "$opt_report" ]; then
        # Extract quality gate results
        local gates_passed
        gates_passed=$(grep -c "✅" "$opt_report" 2>/dev/null || echo "0")

        local gates_failed
        gates_failed=$(grep -c "❌" "$opt_report" 2>/dev/null || echo "0")

        local timestamp
        timestamp=$(get_timestamp)

        cat >> "$OBSERVATIONS_DIR/phase-optimization-$(date +%Y%m%d).yaml" <<EOF
- timestamp: "$timestamp"
  feature_dir: "$feature_dir"
  duration_seconds: $duration
  gates_passed: $gates_passed
  gates_failed: $gates_failed
EOF
    fi
}

# Collect deployment metrics
collect_deployment_metrics() {
    local feature_dir="$1"
    local duration="$2"

    local state_file="$feature_dir/state.yaml"

    # Extract deployment info
    local deployment_status
    deployment_status=$(yq eval ".deployment.production.status" "$state_file" 2>/dev/null || echo "unknown")

    local timestamp
    timestamp=$(get_timestamp)

    cat >> "$OBSERVATIONS_DIR/phase-deployment-$(date +%Y%m%d).yaml" <<EOF
- timestamp: "$timestamp"
  feature_dir: "$feature_dir"
  duration_seconds: $duration
  deployment_status: "$deployment_status"
EOF
}

# ============================================================================
# Automatic Collection Hooks
# ============================================================================

# Called after any phase completes
# Usage: learning-collector.sh phase <phase_name> <feature_dir>
collect_after_phase() {
    local phase="$1"
    local feature_dir="$2"

    # Check if learning is enabled
    if ! check_learning_enabled; then
        return 0
    fi

    # Collect in background to not block workflow
    (
        collect_phase_metrics "$phase" "$feature_dir"

        # Update metadata
        if [ -f "$METADATA_FILE" ]; then
            local timestamp
            timestamp=$(get_timestamp)
            yq eval ".last_updated = \"$timestamp\"" -i "$METADATA_FILE" 2>/dev/null || true
        fi
    ) &
}

# ============================================================================
# Command Interface
# ============================================================================

show_help() {
    cat <<'EOF'
Usage: learning-collector.sh <command> [options]

Commands:
  phase <name> <feature-dir>           Collect metrics after phase completion
  task <id> <duration> <success>       Record task completion
  tool <name> <op> <dur> <success>     Record tool usage
  gate <name> <result> <issues> <dur>  Record quality gate result
  agent <type> <task> <dur> <success>  Record agent usage
  failure <type> <severity> <desc>     Record failure pattern

Options:
  --help                               Show this help

Examples:
  # After phase completes
  learning-collector.sh phase implement specs/001-feature

  # Record task completion
  learning-collector.sh task T001 120 true

  # Record tool usage
  learning-collector.sh tool Grep search 1500 true
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
        phase)
            if [ $# -lt 2 ]; then
                log_error "Usage: learning-collector.sh phase <name> <feature-dir>"
                exit 1
            fi
            collect_after_phase "$1" "$2"
            ;;

        task)
            if [ $# -lt 3 ]; then
                log_error "Usage: learning-collector.sh task <id> <duration> <success> [tools] [retries] [blocker]"
                exit 1
            fi
            collect_task_observation "$1" "$2" "$3" "${4:-}" "${5:-0}" "${6:-none}"
            ;;

        tool)
            if [ $# -lt 4 ]; then
                log_error "Usage: learning-collector.sh tool <name> <operation> <duration_ms> <success> [context]"
                exit 1
            fi
            collect_tool_observation "$1" "$2" "$3" "$4" "${5:-general}"
            ;;

        gate)
            if [ $# -lt 4 ]; then
                log_error "Usage: learning-collector.sh gate <name> <result> <issues> <duration> [false_positives]"
                exit 1
            fi
            collect_quality_gate_observation "$1" "$2" "$3" "$4" "${5:-0}"
            ;;

        agent)
            if [ $# -lt 4 ]; then
                log_error "Usage: learning-collector.sh agent <type> <task_type> <duration> <success> [complexity]"
                exit 1
            fi
            collect_agent_observation "$1" "$2" "$3" "$4" "${5:-medium}"
            ;;

        failure)
            if [ $# -lt 3 ]; then
                log_error "Usage: learning-collector.sh failure <type> <severity> <description> [context]"
                exit 1
            fi
            collect_failure_observation "$1" "$2" "$3" "${4:-general}"
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

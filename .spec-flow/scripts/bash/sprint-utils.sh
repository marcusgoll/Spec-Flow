#!/usr/bin/env bash
# Sprint Utilities for Epic Workflow
# Extracted from implement-epic.md for reusability and maintainability
#
# Usage:
#   sprint-utils.sh validate <epic_dir>           - Validate sprint directories
#   sprint-utils.sh status <sprint_dir>           - Get sprint status
#   sprint-utils.sh consolidate <epic_dir> <layer> - Consolidate layer results
#   sprint-utils.sh check-contracts <epic_dir>    - Validate contract compliance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################
# Validate all sprint directories exist with required files
# Arguments:
#   $1 - Epic directory path
# Returns:
#   0 if all valid, 1 if any missing
#######################################
validate_sprint_dirs() {
    local epic_dir="$1"
    local sprint_plan="${epic_dir}/sprint-plan.md"
    local errors=0

    if [[ ! -f "$sprint_plan" ]]; then
        echo -e "${RED}ERROR: sprint-plan.md not found at ${sprint_plan}${NC}"
        return 1
    fi

    # Extract sprint IDs from sprint-plan.md
    local sprints=$(grep -oP 'S\d{2}' "$sprint_plan" | sort -u)

    for sprint_id in $sprints; do
        local sprint_dir="${epic_dir}/sprints/${sprint_id}"

        # Check directory exists
        if [[ ! -d "$sprint_dir" ]]; then
            echo -e "${RED}ERROR: Sprint directory missing: ${sprint_dir}${NC}"
            ((errors++))
            continue
        fi

        # Check tasks.md exists
        if [[ ! -f "${sprint_dir}/tasks.md" ]]; then
            echo -e "${YELLOW}WARNING: tasks.md missing for ${sprint_id}${NC}"
        fi

        # Check domain-memory.yaml exists (optional but recommended)
        if [[ ! -f "${sprint_dir}/domain-memory.yaml" ]]; then
            echo -e "${YELLOW}INFO: domain-memory.yaml not initialized for ${sprint_id}${NC}"
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo -e "${RED}Validation failed: ${errors} sprint(s) missing${NC}"
        return 1
    fi

    echo -e "${GREEN}All sprint directories validated${NC}"
    return 0
}

#######################################
# Get sprint status from state.yaml
# Arguments:
#   $1 - Sprint directory path
# Outputs:
#   JSON with sprint status
#######################################
get_sprint_status() {
    local sprint_dir="$1"
    local state_file="${sprint_dir}/state.yaml"

    if [[ ! -f "$state_file" ]]; then
        echo '{"status": "not_started", "error": "state.yaml not found"}'
        return 0
    fi

    # Extract key fields using yq if available, else grep
    if command -v yq &> /dev/null; then
        local status=$(yq eval '.sprint.status // "unknown"' "$state_file")
        local tasks_total=$(yq eval '.tasks.total // 0' "$state_file")
        local tasks_completed=$(yq eval '.tasks.completed // 0' "$state_file")
        local tests_passed=$(yq eval '.tests.passed // 0' "$state_file")
        local tests_failed=$(yq eval '.tests.failed // 0' "$state_file")
        local duration=$(yq eval '.sprint.duration_hours // "unknown"' "$state_file")

        echo "{\"status\": \"${status}\", \"tasks_total\": ${tasks_total}, \"tasks_completed\": ${tasks_completed}, \"tests_passed\": ${tests_passed}, \"tests_failed\": ${tests_failed}, \"duration_hours\": \"${duration}\"}"
    else
        # Fallback to grep-based extraction
        local status=$(grep "status:" "$state_file" | head -1 | awk '{print $2}')
        echo "{\"status\": \"${status:-unknown}\"}"
    fi
}

#######################################
# Check if sprint has critical failure
# Arguments:
#   $1 - Sprint directory path
# Returns:
#   0 if no critical failure, 1 if critical
#######################################
has_critical_failure() {
    local sprint_dir="$1"
    local state_file="${sprint_dir}/state.yaml"

    if [[ ! -f "$state_file" ]]; then
        return 1  # No state = no failure
    fi

    # Check for critical indicators
    if grep -q "ci_pipeline_failed: true" "$state_file" 2>/dev/null; then
        echo "CRITICAL: CI pipeline failed"
        return 0
    fi

    if grep -q "security_scan_failed: true" "$state_file" 2>/dev/null; then
        echo "CRITICAL: Security vulnerabilities detected"
        return 0
    fi

    if grep -q "deployment_failed: true" "$state_file" 2>/dev/null; then
        echo "CRITICAL: Deployment failed"
        return 0
    fi

    return 1  # No critical failure
}

#######################################
# Consolidate results for a layer of sprints
# Arguments:
#   $1 - Epic directory path
#   $2 - Layer number
# Outputs:
#   JSON with consolidated layer results
#######################################
consolidate_layer_results() {
    local epic_dir="$1"
    local layer_num="$2"
    local sprint_plan="${epic_dir}/sprint-plan.md"

    # Extract sprint IDs for this layer
    # Assumes format: | Layer N | S01, S02 | ... |
    local layer_line=$(grep -P "^\| Layer ${layer_num} \|" "$sprint_plan" 2>/dev/null || echo "")

    if [[ -z "$layer_line" ]]; then
        echo '{"error": "Layer not found in sprint-plan.md"}'
        return 1
    fi

    local sprint_ids=$(echo "$layer_line" | grep -oP 'S\d{2}' | tr '\n' ' ')

    local total_tasks=0
    local completed_tasks=0
    local total_tests=0
    local passed_tests=0
    local failed_sprints=""
    local total_duration=0

    for sprint_id in $sprint_ids; do
        local sprint_dir="${epic_dir}/sprints/${sprint_id}"
        local status_json=$(get_sprint_status "$sprint_dir")

        local status=$(echo "$status_json" | grep -oP '"status":\s*"\K[^"]+')

        if [[ "$status" == "failed" ]]; then
            failed_sprints="${failed_sprints}${sprint_id} "
        fi

        # Sum up metrics if yq available
        if command -v yq &> /dev/null && [[ -f "${sprint_dir}/state.yaml" ]]; then
            local t_total=$(yq eval '.tasks.total // 0' "${sprint_dir}/state.yaml")
            local t_completed=$(yq eval '.tasks.completed // 0' "${sprint_dir}/state.yaml")
            local tests=$(yq eval '.tests.passed // 0' "${sprint_dir}/state.yaml")
            local duration=$(yq eval '.sprint.duration_hours // 0' "${sprint_dir}/state.yaml")

            total_tasks=$((total_tasks + t_total))
            completed_tasks=$((completed_tasks + t_completed))
            passed_tests=$((passed_tests + tests))
            total_duration=$((total_duration + duration))
        fi
    done

    cat <<EOF
{
    "layer": ${layer_num},
    "sprints": "${sprint_ids}",
    "total_tasks": ${total_tasks},
    "completed_tasks": ${completed_tasks},
    "passed_tests": ${passed_tests},
    "total_duration_hours": ${total_duration},
    "failed_sprints": "${failed_sprints}",
    "all_succeeded": $([ -z "$failed_sprints" ] && echo "true" || echo "false")
}
EOF
}

#######################################
# Check contract compliance across sprints
# Arguments:
#   $1 - Epic directory path
# Returns:
#   0 if no violations, 1 if violations found
#######################################
check_contracts() {
    local epic_dir="$1"
    local contracts_dir="${epic_dir}/contracts"
    local violations=0

    if [[ ! -d "$contracts_dir" ]]; then
        echo -e "${YELLOW}No contracts directory found - skipping contract check${NC}"
        return 0
    fi

    # Check each sprint for contract violations
    for sprint_dir in "${epic_dir}/sprints"/*/; do
        local sprint_id=$(basename "$sprint_dir")
        local state_file="${sprint_dir}/state.yaml"

        if [[ -f "$state_file" ]]; then
            local violation_count=$(grep "contract_violations:" "$state_file" 2>/dev/null | awk '{print $2}' || echo "0")

            if [[ "$violation_count" != "0" && -n "$violation_count" ]]; then
                echo -e "${RED}Contract violations in ${sprint_id}: ${violation_count}${NC}"
                ((violations += violation_count))
            fi
        fi
    done

    if [[ $violations -gt 0 ]]; then
        echo -e "${RED}Total contract violations: ${violations}${NC}"
        return 1
    fi

    echo -e "${GREEN}Contract compliance: OK (0 violations)${NC}"
    return 0
}

#######################################
# Get execution layers from sprint-plan.md
# Arguments:
#   $1 - Epic directory path
# Outputs:
#   List of layers with sprint IDs
#######################################
get_execution_layers() {
    local epic_dir="$1"
    local sprint_plan="${epic_dir}/sprint-plan.md"

    if [[ ! -f "$sprint_plan" ]]; then
        echo '{"error": "sprint-plan.md not found"}'
        return 1
    fi

    # Extract layer table rows
    grep -P "^\| Layer \d+ \|" "$sprint_plan" | while read -r line; do
        local layer_num=$(echo "$line" | grep -oP 'Layer \K\d+')
        local sprint_ids=$(echo "$line" | grep -oP 'S\d{2}' | tr '\n' ',' | sed 's/,$//')
        local parallelizable=$(echo "$line" | grep -qi "parallel\|yes\|true" && echo "true" || echo "false")

        echo "{\"layer\": ${layer_num}, \"sprints\": \"${sprint_ids}\", \"parallelizable\": ${parallelizable}}"
    done
}

#######################################
# Main command dispatcher
#######################################
main() {
    local command="$1"
    shift

    case "$command" in
        validate)
            validate_sprint_dirs "$@"
            ;;
        status)
            get_sprint_status "$@"
            ;;
        consolidate)
            consolidate_layer_results "$@"
            ;;
        check-contracts)
            check_contracts "$@"
            ;;
        layers)
            get_execution_layers "$@"
            ;;
        has-critical)
            has_critical_failure "$@"
            ;;
        *)
            echo "Usage: sprint-utils.sh <command> [args]"
            echo ""
            echo "Commands:"
            echo "  validate <epic_dir>              Validate sprint directories"
            echo "  status <sprint_dir>              Get sprint status as JSON"
            echo "  consolidate <epic_dir> <layer>   Consolidate layer results"
            echo "  check-contracts <epic_dir>       Check contract compliance"
            echo "  layers <epic_dir>                Get execution layers"
            echo "  has-critical <sprint_dir>        Check for critical failures"
            exit 1
            ;;
    esac
}

# Only run main if script is executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

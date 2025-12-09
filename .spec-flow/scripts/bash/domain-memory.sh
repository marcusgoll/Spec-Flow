#!/usr/bin/env bash
# Domain Memory CLI - Manage persistent state for agent workflows
# Part of the Domain Memory pattern from Anthropic's agent architecture
#
# Usage: domain-memory.sh <command> [options]
#
# Commands:
#   init <feature-dir>                          Initialize domain memory from template
#   status <feature-dir>                        Show current state summary
#   pick <feature-dir>                          Get next feature to work on (JSON)
#   update <feature-dir> <feature-id> <status>  Update feature status
#   log <feature-dir> <agent> <action> <msg>    Add log entry
#   tried <feature-dir> <fid> <approach> <result> Record attempted approach
#   sync-tests <feature-dir>                    Sync status from test results
#   generate-from-tasks <feature-dir>           Generate from existing tasks.md
#   lock <feature-dir> <feature-id>             Lock feature for worker
#   unlock <feature-dir>                        Release lock
#   validate <feature-dir>                      Validate domain memory structure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/../../templates/domain-memory.template.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Get ISO8601 timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Check if yq is available
check_yq() {
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed. Install with: brew install yq"
        exit 1
    fi
}

# Get domain memory file path
get_memory_file() {
    local feature_dir="$1"
    echo "$feature_dir/domain-memory.yaml"
}

# Initialize domain memory from template
cmd_init() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ -f "$memory_file" ]]; then
        log_warn "Domain memory already exists at $memory_file"
        exit 0
    fi

    if [[ ! -f "$TEMPLATE_PATH" ]]; then
        log_error "Template not found at $TEMPLATE_PATH"
        exit 1
    fi

    mkdir -p "$feature_dir"

    # Copy template and substitute timestamp
    local timestamp
    timestamp=$(get_timestamp)
    sed "s/\${TIMESTAMP}/$timestamp/g" "$TEMPLATE_PATH" > "$memory_file"

    log_success "Initialized domain memory at $memory_file"
}

# Show current state summary
cmd_status() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    echo "=== Domain Memory Status ==="
    echo ""

    # Goal
    local goal
    goal=$(yq eval '.goal.original_prompt' "$memory_file")
    echo "Goal: $goal"
    echo ""

    # Feature counts by status
    echo "Features:"
    local total passing failing untested in_progress blocked
    total=$(yq eval '.features | length' "$memory_file")
    passing=$(yq eval '[.features[] | select(.status == "passing")] | length' "$memory_file")
    failing=$(yq eval '[.features[] | select(.status == "failing")] | length' "$memory_file")
    untested=$(yq eval '[.features[] | select(.status == "untested")] | length' "$memory_file")
    in_progress=$(yq eval '[.features[] | select(.status == "in_progress")] | length' "$memory_file")
    blocked=$(yq eval '[.features[] | select(.status == "blocked")] | length' "$memory_file")

    echo "  Total:       $total"
    echo -e "  ${GREEN}Passing:     $passing${NC}"
    echo -e "  ${RED}Failing:     $failing${NC}"
    echo -e "  ${YELLOW}Untested:    $untested${NC}"
    echo -e "  ${BLUE}In Progress: $in_progress${NC}"
    echo "  Blocked:     $blocked"
    echo ""

    # Current focus
    local current_feature current_status
    current_feature=$(yq eval '.current.feature_id' "$memory_file")
    current_status=$(yq eval '.current.status' "$memory_file")
    echo "Current Focus: $current_feature ($current_status)"
    echo ""

    # Test summary
    local test_passing test_failing
    test_passing=$(yq eval '.tests.passing' "$memory_file")
    test_failing=$(yq eval '.tests.failing' "$memory_file")
    echo "Tests: $test_passing passing, $test_failing failing"

    # Recent log entries
    echo ""
    echo "Recent Activity:"
    yq eval '.log[-3:] | .[] | "  - " + .timestamp + " [" + .agent + "] " + .action' "$memory_file" 2>/dev/null || echo "  (no log entries)"
}

# Pick next feature to work on (returns JSON)
cmd_pick() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    # Check if there's already a feature in progress
    local current_feature current_status
    current_feature=$(yq eval '.current.feature_id' "$memory_file")
    current_status=$(yq eval '.current.status' "$memory_file")

    if [[ "$current_status" == "working" && "$current_feature" != "null" ]]; then
        # Return the current in-progress feature
        yq eval -o=json ".features[] | select(.id == \"$current_feature\")" "$memory_file"
        exit 0
    fi

    # Find next feature: failing first (fix regressions), then untested
    # Sort by priority, filter out blocked and those with unmet dependencies
    local next_feature

    # First try failing features (fix regressions first)
    next_feature=$(yq eval -o=json '[.features[] | select(.status == "failing")] | sort_by(.priority) | .[0]' "$memory_file")

    if [[ "$next_feature" == "null" || -z "$next_feature" ]]; then
        # Then try untested features
        next_feature=$(yq eval -o=json '[.features[] | select(.status == "untested")] | sort_by(.priority) | .[0]' "$memory_file")
    fi

    if [[ "$next_feature" == "null" || -z "$next_feature" ]]; then
        echo '{"status": "complete", "message": "All features passing"}'
        exit 0
    fi

    echo "$next_feature"
}

# Update feature status
cmd_update() {
    local feature_dir="$1"
    local feature_id="$2"
    local new_status="$3"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    # Validate status
    case "$new_status" in
        untested|passing|failing|in_progress|blocked) ;;
        *)
            log_error "Invalid status: $new_status. Must be: untested|passing|failing|in_progress|blocked"
            exit 1
            ;;
    esac

    local timestamp
    timestamp=$(get_timestamp)

    # Update the feature status
    yq eval -i "(.features[] | select(.id == \"$feature_id\") | .status) = \"$new_status\"" "$memory_file"
    yq eval -i "(.features[] | select(.id == \"$feature_id\") | .last_attempt.timestamp) = \"$timestamp\"" "$memory_file"
    yq eval -i "(.features[] | select(.id == \"$feature_id\") | .last_attempt.result) = \"$new_status\"" "$memory_file"
    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_success "Updated $feature_id status to $new_status"
}

# Add log entry
cmd_log() {
    local feature_dir="$1"
    local agent="$2"
    local action="$3"
    local message="${4:-}"
    local feature_id="${5:-null}"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    local timestamp
    timestamp=$(get_timestamp)

    # Add log entry
    yq eval -i ".log += [{
        \"timestamp\": \"$timestamp\",
        \"agent\": \"$agent\",
        \"action\": \"$action\",
        \"result\": \"$message\",
        \"feature_id\": \"$feature_id\"
    }]" "$memory_file"

    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_info "Logged: [$agent] $action - $message"
}

# Record attempted approach
cmd_tried() {
    local feature_dir="$1"
    local feature_id="$2"
    local approach="$3"
    local result="$4"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    local timestamp
    timestamp=$(get_timestamp)

    # Add to tried approaches
    yq eval -i ".tried.\"$feature_id\" += [{
        \"approach\": \"$approach\",
        \"result\": \"$result\",
        \"timestamp\": \"$timestamp\"
    }]" "$memory_file"

    # Also add to feature's attempts array
    yq eval -i "(.features[] | select(.id == \"$feature_id\") | .attempts) += [{
        \"approach\": \"$approach\",
        \"result\": \"$result\",
        \"timestamp\": \"$timestamp\"
    }]" "$memory_file"

    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_info "Recorded tried approach for $feature_id"
}

# Sync status from test results
cmd_sync_tests() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    # Detect test framework and run tests
    local test_command=""
    local test_output=""
    local passing=0
    local failing=0
    local total=0

    if [[ -f "package.json" ]]; then
        test_command="npm test"
    elif [[ -f "pytest.ini" || -f "pyproject.toml" || -d "tests" ]]; then
        test_command="pytest --tb=no -q"
    elif [[ -f "Cargo.toml" ]]; then
        test_command="cargo test"
    fi

    if [[ -n "$test_command" ]]; then
        log_info "Running tests with: $test_command"

        # Run tests and capture output (don't fail on test failures)
        test_output=$($test_command 2>&1) || true

        # Parse test results (simplified - framework specific parsing needed)
        # This is a basic implementation - should be enhanced per framework

        local timestamp
        timestamp=$(get_timestamp)

        # Update test summary (basic implementation)
        yq eval -i ".tests.last_run = \"$timestamp\"" "$memory_file"
        yq eval -i ".tests.command = \"$test_command\"" "$memory_file"

        log_success "Test sync complete"
    else
        log_warn "No test framework detected"
    fi
}

# Generate domain memory from existing tasks.md
cmd_generate_from_tasks() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")
    local tasks_file="$feature_dir/tasks.md"
    local spec_file="$feature_dir/spec.md"

    if [[ ! -f "$tasks_file" ]]; then
        log_error "tasks.md not found at $tasks_file"
        exit 1
    fi

    if [[ -f "$memory_file" ]]; then
        log_warn "Domain memory already exists. Use 'init' to reset or manually edit."
        exit 1
    fi

    check_yq

    # Initialize from template first
    cmd_init "$feature_dir"

    local timestamp
    timestamp=$(get_timestamp)

    # Extract goal from spec.md if it exists
    if [[ -f "$spec_file" ]]; then
        local goal
        goal=$(head -5 "$spec_file" | grep -m1 "^# " | sed 's/^# //' || echo "Migrated from tasks.md")
        yq eval -i ".goal.original_prompt = \"$goal\"" "$memory_file"
    fi

    # Parse tasks.md and create features
    # Format expected: "- [ ] T001: Task description" or "- [x] T001: Task description"
    local feature_count=0

    while IFS= read -r line; do
        # Match task lines: - [ ] T001: description or - [x] T001: description
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[([[:space:]]|x|X|!)\][[:space:]]*(T[0-9]+):?[[:space:]]*(.+)$ ]]; then
            local checkbox="${BASH_REMATCH[1]}"
            local task_id="${BASH_REMATCH[2]}"
            local task_name="${BASH_REMATCH[3]}"

            # Map checkbox to status
            local status="untested"
            case "$checkbox" in
                "x"|"X") status="passing" ;;
                "!") status="failing" ;;
                *) status="untested" ;;
            esac

            # Convert task ID to feature ID (T001 -> F001)
            local feature_id="${task_id/T/F}"

            ((feature_count++))

            # Add feature entry
            yq eval -i ".features += [{
                \"id\": \"$feature_id\",
                \"name\": \"$task_name\",
                \"description\": \"Migrated from $task_id\",
                \"status\": \"$status\",
                \"test_file\": \"\",
                \"impl_file\": \"\",
                \"priority\": $feature_count,
                \"dependencies\": [],
                \"domain\": \"general\",
                \"last_attempt\": {\"timestamp\": null, \"agent\": null, \"result\": null, \"error\": null},
                \"attempts\": []
            }]" "$memory_file"
        fi
    done < "$tasks_file"

    # Add migration log entry
    yq eval -i ".log += [{
        \"timestamp\": \"$timestamp\",
        \"agent\": \"migration\",
        \"action\": \"migrated_from_tasks\",
        \"result\": \"Migrated $feature_count tasks from tasks.md\",
        \"feature_id\": null
    }]" "$memory_file"

    yq eval -i ".metadata.source = \"migrated_from_tasks\"" "$memory_file"
    yq eval -i ".metadata.migration_date = \"$timestamp\"" "$memory_file"

    log_success "Generated domain memory with $feature_count features from tasks.md"
}

# Lock feature for worker
cmd_lock() {
    local feature_dir="$1"
    local feature_id="$2"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    local current_status
    current_status=$(yq eval '.current.status' "$memory_file")

    if [[ "$current_status" == "working" ]]; then
        local current_feature
        current_feature=$(yq eval '.current.feature_id' "$memory_file")
        log_error "Already locked by feature $current_feature"
        exit 1
    fi

    local timestamp
    timestamp=$(get_timestamp)

    yq eval -i ".current.feature_id = \"$feature_id\"" "$memory_file"
    yq eval -i ".current.started_at = \"$timestamp\"" "$memory_file"
    yq eval -i ".current.status = \"working\"" "$memory_file"
    yq eval -i "(.features[] | select(.id == \"$feature_id\") | .status) = \"in_progress\"" "$memory_file"
    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_success "Locked $feature_id for worker"
}

# Unlock (release lock)
cmd_unlock() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    local timestamp
    timestamp=$(get_timestamp)

    yq eval -i ".current.feature_id = null" "$memory_file"
    yq eval -i ".current.started_at = null" "$memory_file"
    yq eval -i ".current.status = \"idle\"" "$memory_file"
    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_success "Released lock"
}

# Validate domain memory structure
cmd_validate() {
    local feature_dir="$1"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    local errors=0

    # Check required fields
    local version
    version=$(yq eval '.version' "$memory_file")
    if [[ "$version" == "null" || -z "$version" ]]; then
        log_error "Missing required field: version"
        ((errors++))
    fi

    # Check features have required fields
    local feature_count
    feature_count=$(yq eval '.features | length' "$memory_file")

    for ((i=0; i<feature_count; i++)); do
        local fid fstatus
        fid=$(yq eval ".features[$i].id" "$memory_file")
        fstatus=$(yq eval ".features[$i].status" "$memory_file")

        if [[ "$fid" == "null" || -z "$fid" ]]; then
            log_error "Feature at index $i missing id"
            ((errors++))
        fi

        if [[ ! "$fstatus" =~ ^(untested|passing|failing|in_progress|blocked)$ ]]; then
            log_error "Feature $fid has invalid status: $fstatus"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Domain memory validation passed"
        exit 0
    else
        log_error "Validation failed with $errors errors"
        exit 1
    fi
}

# Add feature to domain memory
cmd_add_feature() {
    local feature_dir="$1"
    local feature_id="$2"
    local feature_name="$3"
    local description="${4:-}"
    local domain="${5:-general}"
    local priority="${6:-99}"
    local memory_file
    memory_file=$(get_memory_file "$feature_dir")

    if [[ ! -f "$memory_file" ]]; then
        log_error "Domain memory not found at $memory_file"
        exit 1
    fi

    check_yq

    # Check if feature already exists
    local existing
    existing=$(yq eval ".features[] | select(.id == \"$feature_id\") | .id" "$memory_file")

    if [[ -n "$existing" && "$existing" != "null" ]]; then
        log_warn "Feature $feature_id already exists"
        exit 1
    fi

    local timestamp
    timestamp=$(get_timestamp)

    yq eval -i ".features += [{
        \"id\": \"$feature_id\",
        \"name\": \"$feature_name\",
        \"description\": \"$description\",
        \"status\": \"untested\",
        \"test_file\": \"\",
        \"impl_file\": \"\",
        \"priority\": $priority,
        \"dependencies\": [],
        \"domain\": \"$domain\",
        \"last_attempt\": {\"timestamp\": null, \"agent\": null, \"result\": null, \"error\": null},
        \"attempts\": []
    }]" "$memory_file"

    yq eval -i ".last_updated = \"$timestamp\"" "$memory_file"

    log_success "Added feature $feature_id: $feature_name"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh init <feature-dir>"; exit 1; }
            cmd_init "$1"
            ;;
        status)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh status <feature-dir>"; exit 1; }
            cmd_status "$1"
            ;;
        pick)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh pick <feature-dir>"; exit 1; }
            cmd_pick "$1"
            ;;
        update)
            [[ $# -lt 3 ]] && { log_error "Usage: domain-memory.sh update <feature-dir> <feature-id> <status>"; exit 1; }
            cmd_update "$1" "$2" "$3"
            ;;
        log)
            [[ $# -lt 4 ]] && { log_error "Usage: domain-memory.sh log <feature-dir> <agent> <action> <message> [feature-id]"; exit 1; }
            cmd_log "$1" "$2" "$3" "$4" "${5:-null}"
            ;;
        tried)
            [[ $# -lt 4 ]] && { log_error "Usage: domain-memory.sh tried <feature-dir> <feature-id> <approach> <result>"; exit 1; }
            cmd_tried "$1" "$2" "$3" "$4"
            ;;
        sync-tests)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh sync-tests <feature-dir>"; exit 1; }
            cmd_sync_tests "$1"
            ;;
        generate-from-tasks)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh generate-from-tasks <feature-dir>"; exit 1; }
            cmd_generate_from_tasks "$1"
            ;;
        lock)
            [[ $# -lt 2 ]] && { log_error "Usage: domain-memory.sh lock <feature-dir> <feature-id>"; exit 1; }
            cmd_lock "$1" "$2"
            ;;
        unlock)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh unlock <feature-dir>"; exit 1; }
            cmd_unlock "$1"
            ;;
        validate)
            [[ $# -lt 1 ]] && { log_error "Usage: domain-memory.sh validate <feature-dir>"; exit 1; }
            cmd_validate "$1"
            ;;
        add-feature)
            [[ $# -lt 3 ]] && { log_error "Usage: domain-memory.sh add-feature <feature-dir> <feature-id> <name> [description] [domain] [priority]"; exit 1; }
            cmd_add_feature "$1" "$2" "$3" "${4:-}" "${5:-general}" "${6:-99}"
            ;;
        help|--help|-h)
            echo "Domain Memory CLI - Manage persistent state for agent workflows"
            echo ""
            echo "Usage: domain-memory.sh <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init <feature-dir>                           Initialize domain memory from template"
            echo "  status <feature-dir>                         Show current state summary"
            echo "  pick <feature-dir>                           Get next feature to work on (JSON)"
            echo "  update <feature-dir> <fid> <status>          Update feature status"
            echo "  log <feature-dir> <agent> <action> <msg>     Add log entry"
            echo "  tried <feature-dir> <fid> <approach> <result> Record attempted approach"
            echo "  sync-tests <feature-dir>                     Sync status from test results"
            echo "  generate-from-tasks <feature-dir>            Generate from existing tasks.md"
            echo "  lock <feature-dir> <feature-id>              Lock feature for worker"
            echo "  unlock <feature-dir>                         Release lock"
            echo "  validate <feature-dir>                       Validate domain memory structure"
            echo "  add-feature <dir> <id> <name> [desc] [dom] [pri]  Add new feature"
            echo ""
            echo "Status values: untested | passing | failing | in_progress | blocked"
            echo ""
            echo "Examples:"
            echo "  domain-memory.sh init specs/001-auth"
            echo "  domain-memory.sh pick specs/001-auth"
            echo "  domain-memory.sh update specs/001-auth F001 passing"
            echo "  domain-memory.sh log specs/001-auth worker completed_feature \"Implemented login\""
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Run 'domain-memory.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"

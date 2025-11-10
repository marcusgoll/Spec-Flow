#!/usr/bin/env bash
#
# scheduler-assign.sh - Assign epic to agent with WIP enforcement
#
# Usage: scheduler-assign.sh <epic-name> [--agent AGENT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WIP_TRACKER="$PROJECT_ROOT/.spec-flow/memory/wip-tracker.yaml"
WORKFLOW_STATE="$PROJECT_ROOT/.spec-flow/memory/workflow-state.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parameters
EPIC_NAME=""
AGENT_NAME="${USER:-unknown}"

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") <epic-name> [OPTIONS]

Assign epic to agent with WIP enforcement (max 1 epic per agent).

Arguments:
  epic-name   Epic to assign (must be in ContractsLocked state)

Options:
  --agent AGENT   Agent name (default: current user)
  -h, --help      Show this help

Examples:
  $(basename "$0") epic-auth-api
  $(basename "$0") epic-search-api --agent backend-agent
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

#######################################
# Initialize WIP tracker if missing
#######################################
init_wip_tracker() {
  if [[ ! -f "$WIP_TRACKER" ]]; then
    mkdir -p "$(dirname "$WIP_TRACKER")"
    cat > "$WIP_TRACKER" <<'EOF'
# WIP Tracker
agents: []
parked_epics: []
queued_epics: []
limits:
  max_epics_per_agent: 1
  auto_park_after_hours: 4
EOF
    log_info "Initialized WIP tracker: $WIP_TRACKER"
  fi
}

#######################################
# Get epic state from workflow-state.yaml
#######################################
get_epic_state() {
  local epic_name=$1

  if [[ ! -f "$WORKFLOW_STATE" ]]; then
    echo "unknown"
    return
  fi

  if ! command -v yq &> /dev/null; then
    echo "unknown"
    return
  fi

  local state
  state=$(yq eval ".epics[] | select(.name == \"$epic_name\") | .state" "$WORKFLOW_STATE" 2>/dev/null || echo "")

  if [[ -z "$state" ]] || [[ "$state" == "null" ]]; then
    echo "unknown"
  else
    echo "$state"
  fi
}

#######################################
# Check if agent has WIP slot available
#######################################
has_wip_slot_available() {
  local agent=$1

  if ! command -v yq &> /dev/null; then
    return 0  # Assume available if can't check
  fi

  local current_epic
  current_epic=$(yq eval ".agents[] | select(.name == \"$agent\") | .current_epic" "$WIP_TRACKER" 2>/dev/null || echo "")

  if [[ -z "$current_epic" ]] || [[ "$current_epic" == "null" ]]; then
    return 0  # Slot available
  else
    return 1  # Slot occupied
  fi
}

#######################################
# Get agent's current epic
#######################################
get_agent_current_epic() {
  local agent=$1

  if ! command -v yq &> /dev/null; then
    echo ""
    return
  fi

  local current_epic
  current_epic=$(yq eval ".agents[] | select(.name == \"$agent\") | .current_epic" "$WIP_TRACKER" 2>/dev/null || echo "")

  echo "$current_epic"
}

#######################################
# Assign epic to agent
#######################################
assign_epic() {
  local epic=$1
  local agent=$2

  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || echo "2025-11-10T16:00:00Z")

  if ! command -v yq &> /dev/null; then
    log_error "yq not found - cannot update WIP tracker"
    echo ""
    echo "Install yq: https://github.com/mikefarah/yq"
    echo ""
    exit 1
  fi

  # Check if agent already exists
  local agent_exists
  agent_exists=$(yq eval ".agents[] | select(.name == \"$agent\") | .name" "$WIP_TRACKER" 2>/dev/null || echo "")

  if [[ -n "$agent_exists" ]] && [[ "$agent_exists" != "null" ]]; then
    # Update existing agent
    yq eval "(.agents[] | select(.name == \"$agent\") | .current_epic) = \"$epic\"" -i "$WIP_TRACKER"
    yq eval "(.agents[] | select(.name == \"$agent\") | .state) = \"Implementing\"" -i "$WIP_TRACKER"
    yq eval "(.agents[] | select(.name == \"$agent\") | .started) = \"$timestamp\"" -i "$WIP_TRACKER"
  else
    # Add new agent
    yq eval ".agents += [{
      \"name\": \"$agent\",
      \"current_epic\": \"$epic\",
      \"state\": \"Implementing\",
      \"started\": \"$timestamp\"
    }]" -i "$WIP_TRACKER"
  fi

  # Update epic state in workflow-state.yaml
  if [[ -f "$WORKFLOW_STATE" ]]; then
    # Check if epics array exists
    local epics_exists
    epics_exists=$(yq eval '.epics' "$WORKFLOW_STATE" 2>/dev/null || echo "null")

    if [[ "$epics_exists" == "null" ]]; then
      # Initialize epics array
      yq eval '.epics = []' -i "$WORKFLOW_STATE"
    fi

    # Check if epic already exists
    local epic_exists
    epic_exists=$(yq eval ".epics[] | select(.name == \"$epic\") | .name" "$WORKFLOW_STATE" 2>/dev/null || echo "")

    if [[ -n "$epic_exists" ]] && [[ "$epic_exists" != "null" ]]; then
      # Update existing epic
      yq eval "(.epics[] | select(.name == \"$epic\") | .state) = \"Implementing\"" -i "$WORKFLOW_STATE"
      yq eval "(.epics[] | select(.name == \"$epic\") | .agent) = \"$agent\"" -i "$WORKFLOW_STATE"
      yq eval "(.epics[] | select(.name == \"$epic\") | .started) = \"$timestamp\"" -i "$WORKFLOW_STATE"
    else
      # Add new epic
      yq eval ".epics += [{
        \"name\": \"$epic\",
        \"state\": \"Implementing\",
        \"agent\": \"$agent\",
        \"started\": \"$timestamp\"
      }]" -i "$WORKFLOW_STATE"
    fi
  fi

  log_success "Assigned $epic to $agent"
}

#######################################
# Queue epic
#######################################
queue_epic() {
  local epic=$1
  local agent=$2

  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || echo "2025-11-10T16:00:00Z")

  if ! command -v yq &> /dev/null; then
    log_error "yq not found - cannot queue epic"
    exit 1
  fi

  yq eval ".queued_epics += [{
    \"name\": \"$epic\",
    \"queued_at\": \"$timestamp\",
    \"waiting_for_agent\": \"$agent\"
  }]" -i "$WIP_TRACKER"

  log_info "Queued $epic (waiting for $agent to finish current epic)"
}

#######################################
# Count WIP slots
#######################################
count_wip_slots() {
  if ! command -v yq &> /dev/null; then
    echo "unknown"
    return
  fi

  local total_agents
  total_agents=$(yq eval '.agents | length' "$WIP_TRACKER" 2>/dev/null || echo 0)

  local occupied=0
  for ((i=0; i<total_agents; i++)); do
    local current_epic
    current_epic=$(yq eval ".agents[$i].current_epic" "$WIP_TRACKER" 2>/dev/null || echo "")

    if [[ -n "$current_epic" ]] && [[ "$current_epic" != "null" ]]; then
      ((occupied++))
    fi
  done

  echo "$occupied/$total_agents"
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  if [[ $# -eq 0 ]]; then
    usage
  fi

  EPIC_NAME="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)
        AGENT_NAME="$2"
        shift 2
        ;;
      -h|--help)
        usage
        ;;
      *)
        log_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Initialize tracker
  init_wip_tracker

  # Check epic state
  local epic_state
  epic_state=$(get_epic_state "$EPIC_NAME")

  if [[ "$epic_state" == "unknown" ]]; then
    log_error "Epic not found: $EPIC_NAME"
    echo ""
    echo "Epic must be in ContractsLocked state before assignment."
    echo ""
    echo "Add epic to workflow-state.yaml or run /plan first."
    echo ""
    exit 1
  fi

  if [[ "$epic_state" != "ContractsLocked" ]]; then
    log_error "Epic not ready for assignment: $EPIC_NAME"
    echo ""
    echo "  Current state: $epic_state"
    echo "  Required state: ContractsLocked"
    echo ""
    echo "Ensure contracts are locked and verified before assignment."
    echo ""
    exit 1
  fi

  # Check WIP slot availability
  if has_wip_slot_available "$AGENT_NAME"; then
    # Assign epic
    assign_epic "$EPIC_NAME" "$AGENT_NAME"

    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Epic assigned successfully"
    echo ""
    echo "  Epic: $EPIC_NAME"
    echo "  Agent: $AGENT_NAME"
    echo "  State: ContractsLocked → Implementing"
    echo ""

    local wip_count
    wip_count=$(count_wip_slots)
    echo "  WIP Slots: $wip_count occupied"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "  1. Register feature flag: /flag.add ${EPIC_NAME}_enabled --reason \"Epic in progress\""
    echo "  2. Start implementing tasks (max 24h branch lifetime)"
    echo "  3. Merge daily to main behind feature flag"
    echo ""
  else
    # Agent busy - queue epic
    local current_epic
    current_epic=$(get_agent_current_epic "$AGENT_NAME")

    log_warning "WIP slot occupied"
    echo ""
    echo "  Agent: $AGENT_NAME"
    echo "  Current epic: $current_epic"
    echo "  Max epics per agent: 1"
    echo ""

    queue_epic "$EPIC_NAME" "$AGENT_NAME"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Epic queued. Will auto-assign when $AGENT_NAME completes $current_epic."
    echo ""
    echo "Alternatives:"
    echo "  • Park current epic: /scheduler.park $current_epic --reason \"Switching priorities\""
    echo "  • Assign to different agent: /scheduler.assign $EPIC_NAME --agent <other-agent>"
    echo ""
    exit 0
  fi
}

main "$@"

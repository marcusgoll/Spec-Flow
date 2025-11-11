#!/usr/bin/env bash
#
# scheduler-park.sh - Park epic due to blocker, release WIP slot
#
# Usage: scheduler-park.sh <epic-name> --reason <text> [--blocked-by ENTITY]

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
REASON=""
BLOCKED_BY=""

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") <epic-name> --reason <text> [OPTIONS]

Park epic due to blocker, release WIP slot for other work.

Arguments:
  epic-name       Epic to park (must be in Implementing state)
  --reason TEXT   Why epic is blocked (required)

Options:
  --blocked-by ENTITY  Who/what is blocking (team, service, approval)
  -h, --help           Show this help

Examples:
  $(basename "$0") epic-payment-integration --reason "Waiting for Stripe API keys"
  $(basename "$0") epic-auth-api --reason "DBA approval needed" --blocked-by dba-team
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
# Get epic state
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
# Get agent for epic
#######################################
get_epic_agent() {
  local epic_name=$1

  if [[ ! -f "$WIP_TRACKER" ]]; then
    echo ""
    return
  fi

  if ! command -v yq &> /dev/null; then
    echo ""
    return
  fi

  local agent
  agent=$(yq eval ".agents[] | select(.current_epic == \"$epic_name\") | .name" "$WIP_TRACKER" 2>/dev/null || echo "")

  echo "$agent"
}

#######################################
# Park epic
#######################################
park_epic() {
  local epic=$1
  local reason=$2
  local blocked_by=$3
  local agent=$4

  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || echo "2025-11-10T16:00:00Z")

  if ! command -v yq &> /dev/null; then
    log_error "yq not found - cannot park epic"
    echo ""
    echo "Install yq: https://github.com/mikefarah/yq"
    echo ""
    exit 1
  fi

  # Add to parked_epics
  if [[ -n "$blocked_by" ]]; then
    yq eval ".parked_epics += [{
      \"name\": \"$epic\",
      \"reason\": \"$reason\",
      \"parked_at\": \"$timestamp\",
      \"blocked_by\": \"$blocked_by\",
      \"notify_when_resolved\": \"$agent\"
    }]" -i "$WIP_TRACKER"
  else
    yq eval ".parked_epics += [{
      \"name\": \"$epic\",
      \"reason\": \"$reason\",
      \"parked_at\": \"$timestamp\",
      \"notify_when_resolved\": \"$agent\"
    }]" -i "$WIP_TRACKER"
  fi

  # Remove from agent's current epic
  if [[ -n "$agent" ]]; then
    yq eval "(.agents[] | select(.name == \"$agent\") | .current_epic) = null" -i "$WIP_TRACKER"
    yq eval "(.agents[] | select(.name == \"$agent\") | .state) = \"Idle\"" -i "$WIP_TRACKER"
  fi

  # Update epic state in workflow-state.yaml
  if [[ -f "$WORKFLOW_STATE" ]]; then
    yq eval "(.epics[] | select(.name == \"$epic\") | .state) = \"Parked\"" -i "$WORKFLOW_STATE"
    yq eval "(.epics[] | select(.name == \"$epic\") | .parked_at) = \"$timestamp\"" -i "$WORKFLOW_STATE"
    yq eval "(.epics[] | select(.name == \"$epic\") | .parked_reason) = \"$reason\"" -i "$WORKFLOW_STATE"

    if [[ -n "$blocked_by" ]]; then
      yq eval "(.epics[] | select(.name == \"$epic\") | .blocked_by) = \"$blocked_by\"" -i "$WORKFLOW_STATE"
    fi
  fi

  log_warning "Parked $epic"
}

#######################################
# Check and assign next queued epic
#######################################
assign_next_queued() {
  local agent=$1

  if ! command -v yq &> /dev/null; then
    return
  fi

  # Check if agent has queued epics
  local queued_count
  queued_count=$(yq eval ".queued_epics | length" "$WIP_TRACKER" 2>/dev/null || echo 0)

  if [[ $queued_count -eq 0 ]]; then
    return
  fi

  # Find first queued epic for this agent
  for ((i=0; i<queued_count; i++)); do
    local waiting_agent
    waiting_agent=$(yq eval ".queued_epics[$i].waiting_for_agent" "$WIP_TRACKER" 2>/dev/null || echo "")

    if [[ "$waiting_agent" == "$agent" ]]; then
      local next_epic
      next_epic=$(yq eval ".queued_epics[$i].name" "$WIP_TRACKER" 2>/dev/null || echo "")

      if [[ -n "$next_epic" ]]; then
        # Remove from queue
        yq eval "del(.queued_epics[$i])" -i "$WIP_TRACKER"

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log_info "Auto-assigning next queued epic: $next_epic"
        echo ""

        # Assign via scheduler-assign.sh
        "$SCRIPT_DIR/scheduler-assign.sh" "$next_epic" --agent "$agent"
        return
      fi
    fi
  done
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
      --reason)
        REASON="$2"
        shift 2
        ;;
      --blocked-by)
        BLOCKED_BY="$2"
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

  # Validate inputs
  if [[ -z "$REASON" ]]; then
    log_error "Reason required"
    echo ""
    echo "Example:"
    echo "  /scheduler.park $EPIC_NAME --reason \"Waiting for DBA approval\""
    echo ""
    exit 1
  fi

  # Check epic state
  local epic_state
  epic_state=$(get_epic_state "$EPIC_NAME")

  if [[ "$epic_state" == "unknown" ]]; then
    log_error "Epic not found: $EPIC_NAME"
    echo ""
    echo "Check workflow-state.yaml for epic status."
    echo ""
    exit 1
  fi

  if [[ "$epic_state" != "Implementing" ]]; then
    log_error "Epic not in Implementing state: $EPIC_NAME"
    echo ""
    echo "  Current state: $epic_state"
    echo "  Required state: Implementing"
    echo ""
    echo "Only active epics can be parked."
    echo ""
    exit 1
  fi

  # Get agent
  local agent
  agent=$(get_epic_agent "$EPIC_NAME")

  if [[ -z "$agent" ]]; then
    log_error "Agent not found for epic: $EPIC_NAME"
    echo ""
    echo "WIP tracker may be out of sync."
    echo ""
    exit 1
  fi

  # Park epic
  park_epic "$EPIC_NAME" "$REASON" "$BLOCKED_BY" "$agent"

  # Print summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Epic parked"
  echo ""
  echo "  Epic: $EPIC_NAME"
  echo "  Agent: $agent (WIP slot released)"
  echo "  Reason: $REASON"
  if [[ -n "$BLOCKED_BY" ]]; then
    echo "  Blocked by: $BLOCKED_BY"
  fi
  echo "  State: Implementing → Parked"
  echo ""

  local wip_count
  wip_count=$(count_wip_slots)
  echo "  WIP Slots: $wip_count occupied"
  echo ""

  # Check for queued epics
  assign_next_queued "$agent"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "When blocker resolved:"
  echo "  /scheduler.assign $EPIC_NAME"
  echo ""
  echo "Or work on different epic:"
  echo "  /scheduler.list  # View available epics"
  echo ""
}

main "$@"

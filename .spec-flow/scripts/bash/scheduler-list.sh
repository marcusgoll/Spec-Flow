#!/usr/bin/env bash
#
# scheduler-list.sh - List all epics with WIP status
#
# Usage: scheduler-list.sh [--state STATE]

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
CYAN='\033[0;36m'
NC='\033[0m'

# Filters
FILTER_STATE=""

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

List all epics with current state and WIP status.

Options:
  --state STATE  Filter by state (Implementing, ContractsLocked, Parked, etc.)
  -h, --help     Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --state Implementing
  $(basename "$0") --state Parked
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
# Calculate time difference
#######################################
time_diff() {
  local start=$1
  local now
  now=$(date +%s 2>/dev/null || echo 0)

  local start_ts
  start_ts=$(date -d "$start" +%s 2>/dev/null || echo 0)

  local diff_seconds=$((now - start_ts))
  local hours=$((diff_seconds / 3600))
  local minutes=$(( (diff_seconds % 3600) / 60 ))

  if [[ $hours -gt 0 ]]; then
    echo "${hours}h ${minutes}m"
  else
    echo "${minutes}m"
  fi
}

#######################################
# Get all epics from workflow-state.yaml
#######################################
list_epics() {
  if [[ ! -f "$WORKFLOW_STATE" ]]; then
    return
  fi

  if ! command -v yq &> /dev/null; then
    log_warning "yq not found - limited output"
    cat "$WORKFLOW_STATE"
    return
  fi

  local epic_count
  epic_count=$(yq eval '.epics | length' "$WORKFLOW_STATE" 2>/dev/null || echo 0)

  if [[ $epic_count -eq 0 ]]; then
    return
  fi

  # Group epics by state
  local implementing=()
  local contracts_locked=()
  local parked=()
  local review=()
  local other=()

  for ((i=0; i<epic_count; i++)); do
    local name
    name=$(yq eval ".epics[$i].name" "$WORKFLOW_STATE" 2>/dev/null || echo "")

    local state
    state=$(yq eval ".epics[$i].state" "$WORKFLOW_STATE" 2>/dev/null || echo "")

    # Apply filter
    if [[ -n "$FILTER_STATE" ]] && [[ "$state" != "$FILTER_STATE" ]]; then
      continue
    fi

    case "$state" in
      Implementing)
        implementing+=("$i")
        ;;
      ContractsLocked)
        contracts_locked+=("$i")
        ;;
      Parked)
        parked+=("$i")
        ;;
      Review)
        review+=("$i")
        ;;
      *)
        other+=("$i")
        ;;
    esac
  done

  # Print Implementing
  if [[ ${#implementing[@]} -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}Implementing (${#implementing[@]}):${NC}"
    for idx in "${implementing[@]}"; do
      local name
      name=$(yq eval ".epics[$idx].name" "$WORKFLOW_STATE" 2>/dev/null)

      local agent
      agent=$(yq eval ".epics[$idx].agent" "$WORKFLOW_STATE" 2>/dev/null)

      local started
      started=$(yq eval ".epics[$idx].started" "$WORKFLOW_STATE" 2>/dev/null)

      local tasks_complete
      tasks_complete=$(yq eval ".epics[$idx].tasks_complete" "$WORKFLOW_STATE" 2>/dev/null || echo "0")

      local tasks_total
      tasks_total=$(yq eval ".epics[$idx].tasks_total" "$WORKFLOW_STATE" 2>/dev/null || echo "0")

      local time_elapsed=""
      if [[ -n "$started" ]] && [[ "$started" != "null" ]]; then
        time_elapsed=$(time_diff "$started")
      fi

      echo -e "  ${CYAN}•${NC} $name ${YELLOW}($agent)${NC}"
      if [[ "$tasks_total" != "0" ]]; then
        local progress=$((tasks_complete * 100 / tasks_total))
        echo "    Progress: $tasks_complete/$tasks_total tasks ($progress%)"
      fi
      if [[ -n "$time_elapsed" ]]; then
        echo "    Time: $time_elapsed"
      fi
    done
  fi

  # Print Contracts Locked
  if [[ ${#contracts_locked[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}Contracts Locked (${#contracts_locked[@]}):${NC}"
    for idx in "${contracts_locked[@]}"; do
      local name
      name=$(yq eval ".epics[$idx].name" "$WORKFLOW_STATE" 2>/dev/null)

      local locked_at
      locked_at=$(yq eval ".epics[$idx].contracts_locked_at" "$WORKFLOW_STATE" 2>/dev/null)

      local waiting
      waiting=$(yq eval ".epics[$idx].waiting_for_wip_slot" "$WORKFLOW_STATE" 2>/dev/null)

      local status="Ready"
      if [[ "$waiting" == "true" ]]; then
        status="Queued"
      fi

      echo -e "  ${CYAN}•${NC} $name ${YELLOW}($status)${NC}"
      if [[ -n "$locked_at" ]] && [[ "$locked_at" != "null" ]]; then
        local time_waiting
        time_waiting=$(time_diff "$locked_at")
        echo "    Waiting: $time_waiting"
      fi
    done
  fi

  # Print Parked
  if [[ ${#parked[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Parked (${#parked[@]}):${NC}"
    for idx in "${parked[@]}"; do
      local name
      name=$(yq eval ".epics[$idx].name" "$WORKFLOW_STATE" 2>/dev/null)

      local parked_reason
      parked_reason=$(yq eval ".epics[$idx].parked_reason" "$WORKFLOW_STATE" 2>/dev/null)

      local blocked_by
      blocked_by=$(yq eval ".epics[$idx].blocked_by" "$WORKFLOW_STATE" 2>/dev/null)

      local parked_at
      parked_at=$(yq eval ".epics[$idx].parked_at" "$WORKFLOW_STATE" 2>/dev/null)

      echo -e "  ${CYAN}•${NC} $name"
      if [[ -n "$parked_reason" ]] && [[ "$parked_reason" != "null" ]]; then
        echo "    Reason: $parked_reason"
      fi
      if [[ -n "$blocked_by" ]] && [[ "$blocked_by" != "null" ]]; then
        echo "    Blocked by: $blocked_by"
      fi
      if [[ -n "$parked_at" ]] && [[ "$parked_at" != "null" ]]; then
        local time_parked
        time_parked=$(time_diff "$parked_at")
        echo "    Parked: $time_parked"
      fi
    done
  fi

  # Print Review
  if [[ ${#review[@]} -gt 0 ]]; then
    echo ""
    echo -e "${CYAN}Review (${#review[@]}):${NC}"
    for idx in "${review[@]}"; do
      local name
      name=$(yq eval ".epics[$idx].name" "$WORKFLOW_STATE" 2>/dev/null)

      echo -e "  ${CYAN}•${NC} $name"
    done
  fi

  # Print Other states
  if [[ ${#other[@]} -gt 0 ]]; then
    echo ""
    echo "Other:"
    for idx in "${other[@]}"; do
      local name
      name=$(yq eval ".epics[$idx].name" "$WORKFLOW_STATE" 2>/dev/null)

      local state
      state=$(yq eval ".epics[$idx].state" "$WORKFLOW_STATE" 2>/dev/null)

      echo -e "  ${CYAN}•${NC} $name ${YELLOW}($state)${NC}"
    done
  fi
}

#######################################
# Print WIP status
#######################################
print_wip_status() {
  if [[ ! -f "$WIP_TRACKER" ]]; then
    return
  fi

  if ! command -v yq &> /dev/null; then
    return
  fi

  local agent_count
  agent_count=$(yq eval '.agents | length' "$WIP_TRACKER" 2>/dev/null || echo 0)

  if [[ $agent_count -eq 0 ]]; then
    return
  fi

  local occupied=0
  for ((i=0; i<agent_count; i++)); do
    local current_epic
    current_epic=$(yq eval ".agents[$i].current_epic" "$WIP_TRACKER" 2>/dev/null || echo "")

    if [[ -n "$current_epic" ]] && [[ "$current_epic" != "null" ]]; then
      ((occupied++))
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "WIP Status: $occupied/$agent_count slots occupied"

  # Check queued
  local queued_count
  queued_count=$(yq eval '.queued_epics | length' "$WIP_TRACKER" 2>/dev/null || echo 0)

  if [[ $queued_count -gt 0 ]]; then
    echo "Queued: $queued_count epics waiting for slots"
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --state)
        FILTER_STATE="$2"
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

  # Check files exist
  if [[ ! -f "$WORKFLOW_STATE" ]]; then
    log_info "No epics found"
    echo ""
    echo "Create epics with: /plan"
    echo "Assign epics with: /scheduler.assign <epic-name>"
    echo ""
    exit 0
  fi

  # Print header
  echo ""
  if [[ -n "$FILTER_STATE" ]]; then
    echo "Epic State Summary (Filter: $FILTER_STATE)"
  else
    echo "Epic State Summary"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # List epics
  list_epics

  # Print WIP status
  print_wip_status

  echo ""
}

main "$@"

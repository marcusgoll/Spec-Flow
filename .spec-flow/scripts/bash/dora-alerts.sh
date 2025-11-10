#!/usr/bin/env bash
#
# dora-alerts.sh - Monitor DORA metrics and alert on degradation
#
# Usage: dora-alerts.sh [--notify]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parameters
NOTIFY=false

# Alert thresholds
MAX_BRANCH_AGE_HOURS=18
MAX_CFR_PERCENT=15
MAX_FLAG_COUNT=5
MAX_EXPIRED_FLAGS=0
MAX_PARKED_HOURS=48

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitor DORA metrics and alert on degradation.

Options:
  --notify    Send notifications (GitHub issue comments)
  -h, --help  Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --notify
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
log_alert() { echo -e "${RED}🚨${NC} $*"; }

#######################################
# Check branch age violations
#######################################
check_branch_age() {
  log_info "Checking branch age violations..."

  local violations=0

  # Get all branches except main
  while read -r branch; do
    if [[ "$branch" == "main" ]] || [[ "$branch" == "master" ]]; then
      continue
    fi

    # Get last commit time
    local last_commit
    last_commit=$(git log -1 --format=%ct "$branch" 2>/dev/null || echo "0")

    if [[ $last_commit -eq 0 ]]; then
      continue
    fi

    local now
    now=$(date +%s)

    local age_hours=$(( (now - last_commit) / 3600 ))

    if [[ $age_hours -gt $MAX_BRANCH_AGE_HOURS ]]; then
      log_alert "Branch '$branch' is ${age_hours}h old (limit: ${MAX_BRANCH_AGE_HOURS}h)"
      ((violations++))
    fi
  done < <(git branch --format='%(refname:short)')

  if [[ $violations -eq 0 ]]; then
    log_success "No branch age violations"
    return 0
  else
    return 1
  fi
}

#######################################
# Check Change Failure Rate
#######################################
check_cfr() {
  log_info "Checking Change Failure Rate..."

  # Calculate current CFR
  local cfr_output
  cfr_output=$("$SCRIPT_DIR/dora-calculate.sh" --days 7 --format json 2>/dev/null || echo "{}")

  if ! command -v jq &> /dev/null; then
    log_warning "jq not found, skipping CFR check"
    return 0
  fi

  local cfr
  cfr=$(echo "$cfr_output" | jq -r '.change_failure_rate // 0' 2>/dev/null || echo "0")

  if (( $(echo "$cfr > $MAX_CFR_PERCENT" | bc -l) )); then
    log_alert "CFR is ${cfr}% (threshold: ${MAX_CFR_PERCENT}%)"
    echo "  Recent deployments are failing frequently"
    echo "  Action: Review failed CI runs, improve test coverage"
    return 1
  else
    log_success "CFR within limits: ${cfr}%"
    return 0
  fi
}

#######################################
# Check flag debt
#######################################
check_flag_debt() {
  log_info "Checking feature flag debt..."

  local flag_file="$PROJECT_ROOT/.spec-flow/memory/feature-flags.yaml"

  if [[ ! -f "$flag_file" ]]; then
    log_success "No flags (no debt)"
    return 0
  fi

  if ! command -v yq &> /dev/null; then
    log_warning "yq not found, skipping flag debt check"
    return 0
  fi

  # Count active flags
  local active_count
  active_count=$(yq eval '[.flags[] | select(.status == "active")] | length' "$flag_file" 2>/dev/null || echo "0")

  if [[ $active_count -gt $MAX_FLAG_COUNT ]]; then
    log_alert "Too many active flags: $active_count (limit: $MAX_FLAG_COUNT)"
    echo "  Action: Complete flagged work and retire flags"
    return 1
  fi

  # Count expired flags
  local now
  now=$(date -Iseconds 2>/dev/null || echo "2025-11-10T00:00:00Z")

  local expired_count=0
  local flag_count
  flag_count=$(yq eval '.flags | length' "$flag_file" 2>/dev/null || echo 0)

  for ((i=0; i<flag_count; i++)); do
    local status
    status=$(yq eval ".flags[$i].status" "$flag_file" 2>/dev/null)

    if [[ "$status" != "active" ]]; then
      continue
    fi

    local expires
    expires=$(yq eval ".flags[$i].expires" "$flag_file" 2>/dev/null)

    local expires_ts
    expires_ts=$(date -d "$expires" +%s 2>/dev/null || echo "0")

    local now_ts
    now_ts=$(date +%s 2>/dev/null || echo "0")

    if [[ $expires_ts -lt $now_ts ]]; then
      ((expired_count++))
    fi
  done

  if [[ $expired_count -gt $MAX_EXPIRED_FLAGS ]]; then
    log_alert "Expired flags detected: $expired_count"
    echo "  Action: Run /flag.list --expired and cleanup"
    return 1
  fi

  log_success "Flag debt within limits (active: $active_count, expired: $expired_count)"
  return 0
}

#######################################
# Check parking time
#######################################
check_parking_time() {
  log_info "Checking epic parking time..."

  local wip_tracker="$PROJECT_ROOT/.spec-flow/memory/wip-tracker.yaml"

  if [[ ! -f "$wip_tracker" ]]; then
    log_success "No parked epics"
    return 0
  fi

  if ! command -v yq &> /dev/null; then
    log_warning "yq not found, skipping parking check"
    return 0
  fi

  local parked_count
  parked_count=$(yq eval '.parked_epics | length' "$wip_tracker" 2>/dev/null || echo "0")

  if [[ $parked_count -eq 0 ]]; then
    log_success "No parked epics"
    return 0
  fi

  local violations=0

  for ((i=0; i<parked_count; i++)); do
    local epic_name
    epic_name=$(yq eval ".parked_epics[$i].name" "$wip_tracker" 2>/dev/null)

    local parked_at
    parked_at=$(yq eval ".parked_epics[$i].parked_at" "$wip_tracker" 2>/dev/null)

    local parked_ts
    parked_ts=$(date -d "$parked_at" +%s 2>/dev/null || echo "0")

    local now_ts
    now_ts=$(date +%s)

    local parked_hours=$(( (now_ts - parked_ts) / 3600 ))

    if [[ $parked_hours -gt $MAX_PARKED_HOURS ]]; then
      log_alert "Epic '$epic_name' parked for ${parked_hours}h (limit: ${MAX_PARKED_HOURS}h)"

      local reason
      reason=$(yq eval ".parked_epics[$i].reason" "$wip_tracker" 2>/dev/null)

      echo "  Reason: $reason"
      echo "  Action: Resolve blocker or deprioritize epic"
      ((violations++))
    fi
  done

  if [[ $violations -eq 0 ]]; then
    log_success "Parking time within limits"
    return 0
  else
    return 1
  fi
}

#######################################
# Send notification
#######################################
send_notification() {
  local message=$1

  if [[ "$NOTIFY" != true ]]; then
    return
  fi

  if ! command -v gh &> /dev/null; then
    log_warning "gh CLI not found, skipping notification"
    return
  fi

  # Check for open alert issue
  local issue_number
  issue_number=$(gh issue list --label "dora-alert" --state open --json number --jq '.[0].number' 2>/dev/null || echo "")

  if [[ -n "$issue_number" ]]; then
    # Comment on existing issue
    gh issue comment "$issue_number" --body "$message"
    log_info "Updated alert issue #$issue_number"
  else
    # Create new issue
    gh issue create \
      --title "🚨 DORA Metrics Alert" \
      --label "dora-alert" \
      --body "$message"
    log_info "Created new alert issue"
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --notify)
        NOTIFY=true
        shift
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

  # Print header
  echo ""
  echo "DORA Metrics Alerts"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Run checks
  local alerts_triggered=0

  if ! check_branch_age; then
    ((alerts_triggered++))
  fi
  echo ""

  if ! check_cfr; then
    ((alerts_triggered++))
  fi
  echo ""

  if ! check_flag_debt; then
    ((alerts_triggered++))
  fi
  echo ""

  if ! check_parking_time; then
    ((alerts_triggered++))
  fi

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ $alerts_triggered -eq 0 ]]; then
    log_success "All checks passed - No alerts"
    echo ""
    exit 0
  else
    log_alert "$alerts_triggered alert(s) triggered"
    echo ""

    # Build notification message
    local message
    message="## 🚨 DORA Metrics Alert\n\n"
    message+="$alerts_triggered metric(s) outside acceptable thresholds:\n\n"
    message+="### Alerts\n\n"

    if [[ $alerts_triggered -gt 0 ]]; then
      message+="- Branch age violations\n"
      message+="- Change Failure Rate spike\n"
      message+="- Feature flag debt\n"
      message+="- Epic parking time exceeded\n\n"
    fi

    message+="### Action Required\n\n"
    message+="Review the specific alerts above and take corrective action.\n\n"
    message+="Run \`/metrics.dora\` for detailed metrics."

    send_notification "$message"

    exit 1
  fi
}

main "$@"

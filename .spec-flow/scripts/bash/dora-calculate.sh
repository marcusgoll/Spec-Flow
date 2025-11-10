#!/usr/bin/env bash
#
# dora-calculate.sh - Calculate DORA metrics from git and GitHub API
#
# Usage: dora-calculate.sh [--days DAYS] [--format FORMAT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parameters
DAYS=30
OUTPUT_FORMAT="text"  # text, json, yaml

# Metrics
DEPLOYMENT_FREQUENCY=0
LEAD_TIME_HOURS=0
CHANGE_FAILURE_RATE=0
MTTR_HOURS=0

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Calculate DORA metrics from git history and GitHub API.

Options:
  --days DAYS      Number of days to analyze (default: 30)
  --format FORMAT  Output format (text, json, yaml) [default: text]
  -h, --help       Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --days 7
  $(basename "$0") --format json
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*" >&2; }
log_success() { echo -e "${GREEN}✅${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*" >&2; }
log_error() { echo -e "${RED}❌${NC} $*" >&2; }

#######################################
# Check if gh CLI installed
#######################################
check_gh_cli() {
  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) not installed"
    echo "" >&2
    echo "Install: https://cli.github.com/" >&2
    echo "" >&2
    return 1
  fi

  # Check if authenticated
  if ! gh auth status > /dev/null 2>&1; then
    log_error "Not authenticated with GitHub"
    echo "" >&2
    echo "Run: gh auth login" >&2
    echo "" >&2
    return 1
  fi

  return 0
}

#######################################
# Calculate deployment frequency
#######################################
calculate_deployment_frequency() {
  local days=$1

  log_info "Calculating deployment frequency (last ${days} days)..."

  # Count deployments from git tags or deployment commits
  local since_date
  since_date=$(date -d "$days days ago" -Iseconds 2>/dev/null || date -v-${days}d -Iseconds 2>/dev/null)

  local deploy_count=0

  # Method 1: Count git tags (releases)
  local tag_count
  tag_count=$(git tag --sort=-creatordate --format='%(creatordate:short)' | \
    awk -v since="$since_date" '$1 >= since' | wc -l)

  # Method 2: Count commits to main with "deploy" or "release" in message
  local commit_count
  commit_count=$(git log --since="$since_date" --grep="deploy\|release\|ship" --oneline --no-merges | wc -l || echo "0")

  # Use whichever is higher
  if [[ $tag_count -gt $commit_count ]]; then
    deploy_count=$tag_count
  else
    deploy_count=$commit_count
  fi

  # Calculate frequency (deploys per day)
  local freq
  if [[ $deploy_count -gt 0 ]]; then
    freq=$(echo "scale=2; $deploy_count / $days" | bc -l 2>/dev/null || echo "0")
  else
    freq=0
  fi

  DEPLOYMENT_FREQUENCY=$freq
  echo "$deploy_count deployments in $days days (${freq}/day)"
}

#######################################
# Calculate lead time
#######################################
calculate_lead_time() {
  local days=$1

  log_info "Calculating lead time for changes (last ${days} days)..."

  local since_date
  since_date=$(date -d "$days days ago" -Iseconds 2>/dev/null || date -v-${days}d -Iseconds 2>/dev/null)

  # Get all commits to main in the period
  local commits
  commits=$(git log --since="$since_date" --format="%H|%ct" --no-merges)

  if [[ -z "$commits" ]]; then
    log_warning "No commits found in the last $days days"
    LEAD_TIME_HOURS=0
    return
  fi

  local total_lead_time=0
  local commit_count=0

  while IFS='|' read -r commit_hash commit_time; do
    # Get first commit time in the branch (approximate)
    # For simplicity, assume branch started 1 day before merge
    local branch_start=$((commit_time - 86400))  # 1 day earlier
    local lead_time=$((commit_time - branch_start))
    total_lead_time=$((total_lead_time + lead_time))
    ((commit_count++))
  done <<< "$commits"

  if [[ $commit_count -gt 0 ]]; then
    local avg_lead_time=$((total_lead_time / commit_count))
    local avg_lead_time_hours=$((avg_lead_time / 3600))
    LEAD_TIME_HOURS=$avg_lead_time_hours
    echo "Average: ${avg_lead_time_hours}h (from $commit_count commits)"
  else
    LEAD_TIME_HOURS=0
  fi
}

#######################################
# Calculate Change Failure Rate
#######################################
calculate_change_failure_rate() {
  local days=$1

  log_info "Calculating Change Failure Rate (last ${days} days)..."

  if ! check_gh_cli; then
    log_warning "Skipping CFR calculation (gh CLI required)"
    CHANGE_FAILURE_RATE=0
    return
  fi

  # Get workflow runs from last N days
  local workflow_runs
  workflow_runs=$(gh run list --limit 100 --json conclusion,createdAt 2>/dev/null || echo "[]")

  if [[ "$workflow_runs" == "[]" ]]; then
    log_warning "No workflow runs found"
    CHANGE_FAILURE_RATE=0
    return
  fi

  local total_runs=0
  local failed_runs=0

  if command -v jq &> /dev/null; then
    # Filter runs from last N days
    local since_timestamp
    since_timestamp=$(date -d "$days days ago" +%s 2>/dev/null || date -v-${days}d +%s 2>/dev/null)

    total_runs=$(echo "$workflow_runs" | jq --arg since "$since_timestamp" '[.[] | select((.createdAt | fromdateiso8601) >= ($since | tonumber))] | length')
    failed_runs=$(echo "$workflow_runs" | jq --arg since "$since_timestamp" '[.[] | select((.createdAt | fromdateiso8601) >= ($since | tonumber)) | select(.conclusion == "failure")] | length')
  else
    log_warning "jq not found, using approximate CFR"
    total_runs=$(echo "$workflow_runs" | grep -c "conclusion" || echo "0")
    failed_runs=$(echo "$workflow_runs" | grep -c "failure" || echo "0")
  fi

  if [[ $total_runs -gt 0 ]]; then
    CHANGE_FAILURE_RATE=$(echo "scale=2; ($failed_runs * 100) / $total_runs" | bc -l 2>/dev/null || echo "0")
    echo "Failed: $failed_runs / $total_runs runs (${CHANGE_FAILURE_RATE}%)"
  else
    CHANGE_FAILURE_RATE=0
  fi
}

#######################################
# Calculate MTTR
#######################################
calculate_mttr() {
  local days=$1

  log_info "Calculating Mean Time to Restore (last ${days} days)..."

  if ! check_gh_cli; then
    log_warning "Skipping MTTR calculation (gh CLI required)"
    MTTR_HOURS=0
    return
  fi

  # Get incidents from GitHub issues labeled "incident" or "P0"
  local incidents
  incidents=$(gh issue list --state closed --label "incident,P0" --limit 50 --json number,createdAt,closedAt 2>/dev/null || echo "[]")

  if [[ "$incidents" == "[]" ]]; then
    log_info "No incidents found (good!)"
    MTTR_HOURS=0
    return
  fi

  local total_resolution_time=0
  local incident_count=0

  if command -v jq &> /dev/null; then
    local since_timestamp
    since_timestamp=$(date -d "$days days ago" +%s 2>/dev/null || date -v-${days}d +%s 2>/dev/null)

    # Calculate resolution time for each incident
    while read -r created closed; do
      if [[ -n "$created" ]] && [[ -n "$closed" ]]; then
        local created_ts=$(date -d "$created" +%s 2>/dev/null || echo "0")
        local closed_ts=$(date -d "$closed" +%s 2>/dev/null || echo "0")

        if [[ $created_ts -ge $since_timestamp ]]; then
          local resolution_time=$((closed_ts - created_ts))
          total_resolution_time=$((total_resolution_time + resolution_time))
          ((incident_count++))
        fi
      fi
    done < <(echo "$incidents" | jq -r '.[] | "\(.createdAt) \(.closedAt)"')
  fi

  if [[ $incident_count -gt 0 ]]; then
    local avg_resolution=$((total_resolution_time / incident_count))
    MTTR_HOURS=$((avg_resolution / 3600))
    echo "Average: ${MTTR_HOURS}h (from $incident_count incidents)"
  else
    MTTR_HOURS=0
  fi
}

#######################################
# Get DORA tier
#######################################
get_dora_tier() {
  # Elite: Deploy freq > 1/day, Lead time < 1 day, CFR < 15%, MTTR < 1h
  # High: Deploy freq 1/week-1/month, Lead time 1 day-1 week, CFR < 15%, MTTR < 1 day
  # Medium: Deploy freq 1/month-1/6months, Lead time 1 week-1 month, CFR < 15%, MTTR < 1 week
  # Low: Deploy freq < 1/6 months, Lead time > 1 month, CFR >= 15%, MTTR > 1 week

  local tier="Low"

  # Check elite criteria
  local elite=true
  if (( $(echo "$DEPLOYMENT_FREQUENCY < 1" | bc -l) )); then elite=false; fi
  if (( $(echo "$LEAD_TIME_HOURS > 24" | bc -l) )); then elite=false; fi
  if (( $(echo "$CHANGE_FAILURE_RATE > 15" | bc -l) )); then elite=false; fi
  if (( $(echo "$MTTR_HOURS > 1" | bc -l) )); then elite=false; fi

  if [[ "$elite" == true ]]; then
    tier="Elite"
    return
  fi

  # Check high criteria
  local high=true
  if (( $(echo "$DEPLOYMENT_FREQUENCY < 0.142" | bc -l) )); then high=false; fi  # 1/week
  if (( $(echo "$LEAD_TIME_HOURS > 168" | bc -l) )); then high=false; fi  # 1 week
  if (( $(echo "$CHANGE_FAILURE_RATE > 15" | bc -l) )); then high=false; fi
  if (( $(echo "$MTTR_HOURS > 24" | bc -l) )); then high=false; fi

  if [[ "$high" == true ]]; then
    tier="High"
    return
  fi

  # Check medium criteria
  local medium=true
  if (( $(echo "$DEPLOYMENT_FREQUENCY < 0.033" | bc -l) )); then medium=false; fi  # 1/month
  if (( $(echo "$LEAD_TIME_HOURS > 720" | bc -l) )); then medium=false; fi  # 1 month
  if (( $(echo "$CHANGE_FAILURE_RATE > 15" | bc -l) )); then medium=false; fi
  if (( $(echo "$MTTR_HOURS > 168" | bc -l) )); then medium=false; fi

  if [[ "$medium" == true ]]; then
    tier="Medium"
  fi

  echo "$tier"
}

#######################################
# Output: Text
#######################################
output_text() {
  local tier
  tier=$(get_dora_tier)

  echo ""
  echo "DORA Metrics (Last $DAYS Days)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Deployment Frequency: ${DEPLOYMENT_FREQUENCY}/day"
  echo "Lead Time for Changes: ${LEAD_TIME_HOURS}h"
  echo "Change Failure Rate: ${CHANGE_FAILURE_RATE}%"
  echo "Mean Time to Restore: ${MTTR_HOURS}h"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "DORA Performance Tier: $tier"
  echo ""

  # Show tier thresholds
  echo "Tier Thresholds:"
  echo "  Elite:  >1 deploy/day, <24h lead time, <15% CFR, <1h MTTR"
  echo "  High:   >1 deploy/week, <1 week lead time, <15% CFR, <24h MTTR"
  echo "  Medium: >1 deploy/month, <1 month lead time, <15% CFR, <1 week MTTR"
  echo "  Low:    Below medium thresholds"
  echo ""
}

#######################################
# Output: JSON
#######################################
output_json() {
  local tier
  tier=$(get_dora_tier)

  cat <<EOF
{
  "period_days": $DAYS,
  "deployment_frequency": $DEPLOYMENT_FREQUENCY,
  "lead_time_hours": $LEAD_TIME_HOURS,
  "change_failure_rate": $CHANGE_FAILURE_RATE,
  "mttr_hours": $MTTR_HOURS,
  "tier": "$tier"
}
EOF
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days)
        DAYS="$2"
        shift 2
        ;;
      --format)
        OUTPUT_FORMAT="$2"
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

  # Calculate metrics
  calculate_deployment_frequency "$DAYS"
  calculate_lead_time "$DAYS"
  calculate_change_failure_rate "$DAYS"
  calculate_mttr "$DAYS"

  # Output results
  case "$OUTPUT_FORMAT" in
    text)
      output_text
      ;;
    json)
      output_json
      ;;
    *)
      log_error "Unknown format: $OUTPUT_FORMAT"
      exit 1
      ;;
  esac
}

main "$@"

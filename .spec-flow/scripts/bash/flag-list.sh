#!/usr/bin/env bash
#
# flag-list.sh - List feature flags with status
#
# Usage: flag-list.sh [--expired] [--epic EPIC] [--status STATUS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FLAG_REGISTRY="$PROJECT_ROOT/.spec-flow/memory/feature-flags.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Filters
SHOW_EXPIRED_ONLY=false
FILTER_EPIC=""
FILTER_STATUS=""

# Counters
TOTAL_FLAGS=0
EXPIRED_COUNT=0
EXPIRING_SOON_COUNT=0

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

List feature flags with status and expiry information.

Options:
  --expired       Show only expired flags
  --epic EPIC     Filter by epic
  --status STATUS Filter by status (active|retired)
  -h, --help      Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --expired
  $(basename "$0") --epic acs-epic-a
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
# Calculate days between dates
#######################################
days_between() {
  local date1=$1
  local date2=$2

  local ts1=$(date -d "$date1" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$date1" +%s 2>/dev/null || echo 0)
  local ts2=$(date -d "$date2" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$date2" +%s 2>/dev/null || echo 0)

  local diff=$((ts2 - ts1))
  local days=$((diff / 86400))

  echo "$days"
}

#######################################
# Format flag display
#######################################
format_flag() {
  local name=$1
  local status=$2
  local created=$3
  local expires=$4
  local epic=$5
  local branch=$6
  local reason=$7

  local now
  now=$(date -Iseconds 2>/dev/null || echo "2025-11-10T00:00:00Z")

  local age_days
  age_days=$(days_between "$created" "$now")

  local days_until_expiry
  days_until_expiry=$(days_between "$now" "$expires")

  echo ""
  echo "$name"

  # Status indicator
  if [[ "$status" == "retired" ]]; then
    echo "  Status: ✔️  Retired"
  elif [[ $days_until_expiry -lt 0 ]]; then
    local days_expired=$((days_until_expiry * -1))
    echo "  Status: ❌ EXPIRED (${days_expired}d ago)"
    ((EXPIRED_COUNT++))
  elif [[ $days_until_expiry -lt 3 ]]; then
    echo "  Status: ⚠️  Active (expires in ${days_until_expiry}d)"
    ((EXPIRING_SOON_COUNT++))
  else
    echo "  Status: ✅ Active"
  fi

  echo "  Age: ${age_days}d (created $(date -d "$created" +%Y-%m-%d 2>/dev/null || echo "$created"))"

  if [[ "$status" == "retired" ]]; then
    echo "  Retired: $(date -d "$expires" +%Y-%m-%d 2>/dev/null || echo "$expires")"
  else
    echo "  Expires: $(date -d "$expires" +%Y-%m-%d 2>/dev/null || echo "$expires") (in ${days_until_expiry}d)"
  fi

  if [[ -n "$epic" ]] && [[ "$epic" != "null" ]]; then
    echo "  Epic: $epic"
  fi

  if [[ -n "$branch" ]] && [[ "$branch" != "null" ]]; then
    echo "  Branch: $branch"
  fi

  echo "  Reason: $reason"

  ((TOTAL_FLAGS++))
}

#######################################
# Parse flags from YAML
#######################################
parse_flags() {
  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    return
  fi

  # Check if yq available
  if ! command -v yq &> /dev/null; then
    log_warning "yq not found - limited flag parsing"
    cat "$FLAG_REGISTRY"
    return
  fi

  # Get all flags
  local flags
  flags=$(yq eval '.flags[]' "$FLAG_REGISTRY" 2>/dev/null || echo "")

  if [[ -z "$flags" ]]; then
    return
  fi

  # Process each flag
  local flag_count
  flag_count=$(yq eval '.flags | length' "$FLAG_REGISTRY" 2>/dev/null || echo 0)

  for ((i=0; i<flag_count; i++)); do
    local name
    name=$(yq eval ".flags[$i].name" "$FLAG_REGISTRY" 2>/dev/null)

    local status
    status=$(yq eval ".flags[$i].status" "$FLAG_REGISTRY" 2>/dev/null)

    local created
    created=$(yq eval ".flags[$i].created" "$FLAG_REGISTRY" 2>/dev/null)

    local expires
    expires=$(yq eval ".flags[$i].expires" "$FLAG_REGISTRY" 2>/dev/null)

    local epic
    epic=$(yq eval ".flags[$i].epic" "$FLAG_REGISTRY" 2>/dev/null)

    local branch
    branch=$(yq eval ".flags[$i].branch" "$FLAG_REGISTRY" 2>/dev/null)

    local reason
    reason=$(yq eval ".flags[$i].reason" "$FLAG_REGISTRY" 2>/dev/null)

    # Apply filters
    if [[ -n "$FILTER_EPIC" ]] && [[ "$epic" != "$FILTER_EPIC" ]]; then
      continue
    fi

    if [[ -n "$FILTER_STATUS" ]] && [[ "$status" != "$FILTER_STATUS" ]]; then
      continue
    fi

    # Check expiry filter
    if [[ "$SHOW_EXPIRED_ONLY" == true ]]; then
      local now
      now=$(date -Iseconds 2>/dev/null || echo "2025-11-10T00:00:00Z")

      local days_until_expiry
      days_until_expiry=$(days_between "$now" "$expires")

      if [[ $days_until_expiry -ge 0 ]]; then
        continue
      fi
    fi

    # Display flag
    format_flag "$name" "$status" "$created" "$expires" "$epic" "$branch" "$reason"
  done
}

#######################################
# Print summary
#######################################
print_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ "$SHOW_EXPIRED_ONLY" == true ]]; then
    if [[ $TOTAL_FLAGS -eq 0 ]]; then
      log_success "No expired flags"
      echo ""
      echo "All flags within expiry limits."
    else
      log_error "Expired flags: $TOTAL_FLAGS"
      echo ""
      echo "Clean up immediately:"
      echo "  /flag.cleanup <flag-name>"
    fi
  else
    if [[ $TOTAL_FLAGS -eq 0 ]]; then
      log_info "No active flags"
    else
      echo "Summary:"
      echo "  Total: $TOTAL_FLAGS flags"

      if [[ $EXPIRING_SOON_COUNT -gt 0 ]]; then
        echo "  Expiring soon (<3d): $EXPIRING_SOON_COUNT"
      fi

      if [[ $EXPIRED_COUNT -gt 0 ]]; then
        echo "  Expired: $EXPIRED_COUNT"
      fi
    fi
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ $EXPIRING_SOON_COUNT -gt 0 ]] || [[ $EXPIRED_COUNT -gt 0 ]]; then
    echo ""
    echo "Recommendations:"
    if [[ $EXPIRING_SOON_COUNT -gt 0 ]]; then
      echo "  - Complete work on expiring flags"
    fi
    if [[ $EXPIRED_COUNT -gt 0 ]]; then
      echo "  - Clean up expired flags: /flag.cleanup <name>"
    fi
    echo ""
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --expired)
        SHOW_EXPIRED_ONLY=true
        shift
        ;;
      --epic)
        FILTER_EPIC="$2"
        shift 2
        ;;
      --status)
        FILTER_STATUS="$2"
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

  # Check registry exists
  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    log_info "No flag registry found"
    echo ""
    echo "Create your first flag:"
    echo "  /flag.add <flag-name> --reason \"Why this flag exists\""
    echo ""
    exit 0
  fi

  # Print header
  echo ""
  if [[ "$SHOW_EXPIRED_ONLY" == true ]]; then
    echo "Expired Feature Flags"
  else
    echo "Feature Flags"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Parse and display flags
  parse_flags

  # Print summary
  print_summary

  echo ""

  # Exit with error if expired flags found
  if [[ "$SHOW_EXPIRED_ONLY" == true ]] && [[ $TOTAL_FLAGS -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

main "$@"

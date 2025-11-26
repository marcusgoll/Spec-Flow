#!/usr/bin/env bash
#
# branch-enforce.sh - Enforce trunk-based development branch age limits
#
# Usage: branch-enforce.sh [--fix] [--verbose] [--current-branch-only]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../.." && pwd)"
FLAG_REGISTRY="$REPO_ROOT/.spec-flow/memory/feature-flags.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Thresholds (hours)
WARN_THRESHOLD=18
BLOCK_THRESHOLD=24

# Flags
FIX_MODE=false
VERBOSE=false
CURRENT_BRANCH_ONLY=false

# Counters
HEALTHY_COUNT=0
WARNING_COUNT=0
VIOLATION_COUNT=0
FLAGGED_VIOLATION_COUNT=0

# Lists
HEALTHY_BRANCHES=()
WARNING_BRANCHES=()
VIOLATION_BRANCHES=()

#######################################
# Print usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audit all branches for age violations and enforce trunk-based development.

Options:
  --fix                 Auto-create feature flags for violations
  --verbose             Show detailed branch information
  --current-branch-only Only check current branch (used by git hook)
  -h, --help            Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --fix
  $(basename "$0") --verbose
  $(basename "$0") --current-branch-only  # Git hook usage
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
# Get all branches (excluding main/master)
#######################################
get_all_branches() {
  git branch --format='%(refname:short)' 2>/dev/null | grep -v '^main$' | grep -v '^master$' || true
}

#######################################
# Get current branch
#######################################
get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

#######################################
# Get branch age in hours
#######################################
get_branch_age() {
  local branch=$1

  # Get first commit on branch (not on main/master)
  local first_commit
  first_commit=$(git log --reverse --format=%ct "$branch" --not main master 2>/dev/null | head -1)

  if [[ -z "$first_commit" ]]; then
    # Fallback: get first commit on branch
    first_commit=$(git log --reverse --format=%ct "$branch" 2>/dev/null | head -1)
  fi

  if [[ -z "$first_commit" ]]; then
    echo "0"
    return
  fi

  local now
  now=$(date +%s)

  local age_seconds=$((now - first_commit))
  local age_hours=$((age_seconds / 3600))

  echo "$age_hours"
}

#######################################
# Get last commit info
#######################################
get_last_commit_time() {
  local branch=$1
  git log -1 --format=%ci "$branch" 2>/dev/null || echo "Unknown"
}

get_last_commit_author() {
  local branch=$1
  git log -1 --format='%an' "$branch" 2>/dev/null || echo "Unknown"
}

#######################################
# Check if feature flag exists for branch
#######################################
has_feature_flag() {
  local branch=$1

  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    return 1
  fi

  grep -q "branch: $branch" "$FLAG_REGISTRY" 2>/dev/null
}

#######################################
# Get feature flag name for branch
#######################################
get_flag_name() {
  local branch=$1

  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    echo ""
    return
  fi

  # Find flag associated with branch
  local flag_name
  flag_name=$(awk -v branch="$branch" '
    /^  - name:/ { flag = $NF }
    /branch:/ && $NF == branch { print flag; exit }
  ' "$FLAG_REGISTRY" 2>/dev/null || echo "")

  echo "$flag_name"
}

#######################################
# Classify branch status
#######################################
classify_branch() {
  local age=$1
  local has_flag=$2

  if [[ $age -lt $WARN_THRESHOLD ]]; then
    echo "healthy"
  elif [[ $age -lt $BLOCK_THRESHOLD ]]; then
    echo "warning"
  else
    if [[ "$has_flag" == "true" ]]; then
      echo "violation_flagged"
    else
      echo "violation"
    fi
  fi
}

#######################################
# Auto-create feature flag for branch
#######################################
create_flag_for_branch() {
  local branch=$1

  # Generate flag name from branch
  local flag_name
  flag_name=$(echo "$branch" | sed 's|feature/||' | sed 's|[^a-zA-Z0-9]|_|g')
  flag_name="${flag_name}_enabled"

  log_info "Creating feature flag: $flag_name"

  # Check if flag script exists
  local flag_script="$SCRIPT_DIR/flag-add.sh"

  if [[ -f "$flag_script" ]]; then
    "$flag_script" "$flag_name" --branch "$branch" --reason "Auto-generated: Branch age >24h" 2>/dev/null || true
  else
    log_warning "Flag script not found - manual flag creation required"
    echo "Run: /flag.add $flag_name --branch $branch"
  fi

  echo "$flag_name"
}

#######################################
# Format branch report
#######################################
format_branch_report() {
  local branch=$1
  local age=$2
  local status=$3
  local verbose=$4

  echo "$branch"
  echo "  Age: ${age}h"

  if [[ "$verbose" == "true" ]]; then
    local last_commit
    last_commit=$(get_last_commit_time "$branch")
    echo "  Last commit: $last_commit"

    local author
    author=$(get_last_commit_author "$branch")
    echo "  Author: $author"
  fi

  case "$status" in
    healthy)
      echo "  Status: ✅ Healthy"
      ;;
    warning)
      local remaining=$((BLOCK_THRESHOLD - age))
      echo "  Status: ⚠️  Warning (merge within ${remaining}h)"
      echo "  Recommendation: Merge or add feature flag"
      ;;
    violation)
      local overtime=$((age - BLOCK_THRESHOLD))
      echo "  Status: ❌ Violation (${overtime}h over limit)"
      echo "  Recommendation: Add feature flag immediately"
      echo "  Command: /flag.add <flag-name> --branch $branch"
      ;;
    violation_flagged)
      local overtime=$((age - BLOCK_THRESHOLD))
      local flag_name
      flag_name=$(get_flag_name "$branch")
      echo "  Status: ❌ Violation (${overtime}h over limit)"
      echo "  Feature flag: $flag_name ✅"
      echo "  Recommendation: Complete work and remove flag"
      ;;
  esac

  echo ""
}

#######################################
# Process single branch
#######################################
process_branch() {
  local branch=$1

  local age
  age=$(get_branch_age "$branch")

  local has_flag="false"
  if has_feature_flag "$branch"; then
    has_flag="true"
  fi

  local status
  status=$(classify_branch "$age" "$has_flag")

  # Categorize
  case "$status" in
    healthy)
      HEALTHY_BRANCHES+=("$branch (${age}h)")
      ((HEALTHY_COUNT++))
      ;;
    warning)
      WARNING_BRANCHES+=("$branch (${age}h)")
      ((WARNING_COUNT++))
      ;;
    violation)
      VIOLATION_BRANCHES+=("$branch (${age}h)")
      ((VIOLATION_COUNT++))

      # Auto-fix if requested
      if [[ "$FIX_MODE" == "true" ]]; then
        echo ""
        log_warning "Violation: $branch (${age}h old, no flag)"
        create_flag_for_branch "$branch"
        log_success "Flag created for $branch"
      fi
      ;;
    violation_flagged)
      ((FLAGGED_VIOLATION_COUNT++))
      ;;
  esac

  # Print if verbose or has issues
  if [[ "$VERBOSE" == "true" ]] || [[ "$status" != "healthy" ]]; then
    format_branch_report "$branch" "$age" "$status" "$VERBOSE"
  fi
}

#######################################
# Print summary report
#######################################
print_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Branch Health Report"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local total=$((HEALTHY_COUNT + WARNING_COUNT + VIOLATION_COUNT + FLAGGED_VIOLATION_COUNT))

  if [[ $HEALTHY_COUNT -gt 0 ]]; then
    log_success "Healthy: $HEALTHY_COUNT branches (<${WARN_THRESHOLD}h)"
  fi

  if [[ $WARNING_COUNT -gt 0 ]]; then
    log_warning "Warning: $WARNING_COUNT branches (${WARN_THRESHOLD}-${BLOCK_THRESHOLD}h)"
  fi

  if [[ $VIOLATION_COUNT -gt 0 ]]; then
    log_error "Violation: $VIOLATION_COUNT branches (>${BLOCK_THRESHOLD}h, no flag)"
  fi

  if [[ $FLAGGED_VIOLATION_COUNT -gt 0 ]]; then
    log_warning "Flagged violations: $FLAGGED_VIOLATION_COUNT branches (>${BLOCK_THRESHOLD}h with flag)"
  fi

  echo ""
  echo "Total: $total active branches"
  echo ""

  # List warning branches
  if [[ ${#WARNING_BRANCHES[@]} -gt 0 ]]; then
    echo "Warning branches:"
    for branch in "${WARNING_BRANCHES[@]}"; do
      echo "  - $branch"
    done
    echo ""
  fi

  # List violation branches
  if [[ ${#VIOLATION_BRANCHES[@]} -gt 0 ]]; then
    echo "Violation branches (action required):"
    for branch in "${VIOLATION_BRANCHES[@]}"; do
      echo "  - $branch"
    done
    echo ""
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ $VIOLATION_COUNT -gt 0 ]] || [[ $WARNING_COUNT -gt 0 ]]; then
    echo ""
    echo "Recommendations:"
    echo "  - Merge warning branches today"
    if [[ $VIOLATION_COUNT -gt 0 ]]; then
      echo "  - Add flags for violations: /flag.add <name>"
      echo "  - Or run: /branch.enforce --fix"
    fi
    echo "  - Consider splitting large features into smaller slices"
    echo ""
    echo "References:"
    echo "  - https://trunkbaseddevelopment.com/"
    echo "  - docs/trunk-based-development.md"
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
      --fix)
        FIX_MODE=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --current-branch-only)
        CURRENT_BRANCH_ONLY=true
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

  # Check git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not a git repository"
    exit 1
  fi

  # Get branches to check
  local branches

  if [[ "$CURRENT_BRANCH_ONLY" == "true" ]]; then
    branches=$(get_current_branch)

    if [[ "$branches" == "main" ]] || [[ "$branches" == "master" ]] || [[ -z "$branches" ]]; then
      # Skip main/master
      exit 0
    fi
  else
    log_info "Scanning branches..."
    echo ""
    branches=$(get_all_branches)
  fi

  if [[ -z "$branches" ]]; then
    log_success "No feature branches found"
    exit 0
  fi

  # Process each branch
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue
    process_branch "$branch"
  done <<< "$branches"

  # Print summary (skip for current-branch-only mode)
  if [[ "$CURRENT_BRANCH_ONLY" == "false" ]]; then
    print_summary
  fi

  # Exit with failure if violations found (without fix mode)
  if [[ $VIOLATION_COUNT -gt 0 ]] && [[ "$FIX_MODE" == "false" ]]; then
    exit 1
  fi

  exit 0
}

main "$@"

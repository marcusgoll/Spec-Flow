#!/usr/bin/env bash
#
# flag-cleanup.sh - Remove feature flag
#
# Usage: flag-cleanup.sh <flag-name> [--verify] [--force]

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

# Parameters
FLAG_NAME=""
VERIFY=true
FORCE=false

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") <flag-name> [OPTIONS]

Retire feature flag when work is complete.

Arguments:
  flag-name   Flag to retire

Options:
  --verify    Check for code references (default: true)
  --force     Skip verification (not recommended)
  -h, --help  Show this help

Examples:
  $(basename "$0") acs_sync_enabled --verify
  $(basename "$0") temp_flag --force
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
# Check if flag exists
#######################################
flag_exists() {
  local name=$1

  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    return 1
  fi

  if grep -q "name: $name" "$FLAG_REGISTRY" 2>/dev/null; then
    return 0
  fi

  return 1
}

#######################################
# Check if flag already retired
#######################################
is_flag_retired() {
  local name=$1

  if ! command -v yq &> /dev/null; then
    return 1
  fi

  local status
  status=$(yq eval ".flags[] | select(.name == \"$name\") | .status" "$FLAG_REGISTRY" 2>/dev/null || echo "")

  if [[ "$status" == "retired" ]]; then
    return 0
  fi

  return 1
}

#######################################
# Scan for code references
#######################################
scan_code_references() {
  local name=$1

  log_info "Scanning codebase for references to: $name"
  echo ""

  # Scan common source directories
  local references=""
  local search_paths=(
    "src"
    "api"
    "config"
    "tests"
    "lib"
  )

  for path in "${search_paths[@]}"; do
    if [[ -d "$PROJECT_ROOT/$path" ]]; then
      local found
      found=$(grep -r "$name" "$PROJECT_ROOT/$path" \
        --exclude-dir=node_modules \
        --exclude-dir=dist \
        --exclude-dir=build \
        --exclude-dir=.git \
        --include="*.ts" \
        --include="*.tsx" \
        --include="*.js" \
        --include="*.jsx" \
        --include="*.json" \
        2>/dev/null || true)

      if [[ -n "$found" ]]; then
        references+="$found"$'\n'
      fi
    fi
  done

  # Also check flag registry itself
  references=$(echo "$references" | grep -v "feature-flags.yaml" || true)

  if [[ -n "$references" ]]; then
    log_error "Found code references:"
    echo ""
    echo "$references"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Remove references first:"
    echo "  1. Delete flag checks from code"
    echo "  2. Test without flag"
    echo "  3. Re-run: /flag.cleanup $name --verify"
    echo ""
    echo "Or force cleanup (not recommended):"
    echo "  /flag.cleanup $name --force"
    echo ""
    return 1
  else
    log_success "No code references found"
    return 0
  fi
}

#######################################
# Retire flag
#######################################
retire_flag() {
  local name=$1

  local retired_date
  retired_date=$(date -Iseconds 2>/dev/null || echo "2025-11-10T16:00:00Z")

  if command -v yq &> /dev/null; then
    # Update status to retired
    yq eval "(.flags[] | select(.name == \"$name\") | .status) = \"retired\"" -i "$FLAG_REGISTRY"

    # Add retired timestamp
    yq eval "(.flags[] | select(.name == \"$name\") | .retired) = \"$retired_date\"" -i "$FLAG_REGISTRY"

    log_success "Flag retired: $name"
  else
    log_warning "yq not found - manual retirement required"
    echo ""
    echo "Edit $FLAG_REGISTRY manually:"
    echo "  1. Find flag: $name"
    echo "  2. Change status: active → retired"
    echo "  3. Add retired: $retired_date"
    echo ""
    return 1
  fi
}

#######################################
# Get flag details
#######################################
get_flag_details() {
  local name=$1

  if ! command -v yq &> /dev/null; then
    return
  fi

  local created
  created=$(yq eval ".flags[] | select(.name == \"$name\") | .created" "$FLAG_REGISTRY" 2>/dev/null || echo "")

  local retired
  retired=$(yq eval ".flags[] | select(.name == \"$name\") | .retired" "$FLAG_REGISTRY" 2>/dev/null || echo "")

  if [[ -n "$created" ]] && [[ -n "$retired" ]]; then
    local created_ts
    created_ts=$(date -d "$created" +%s 2>/dev/null || echo 0)

    local retired_ts
    retired_ts=$(date -d "$retired" +%s 2>/dev/null || echo 0)

    local lifetime_days=$(( (retired_ts - created_ts) / 86400 ))

    echo ""
    echo "  Created: $(date -d "$created" +%Y-%m-%d 2>/dev/null || echo "$created")"
    echo "  Retired: $(date -d "$retired" +%Y-%m-%d 2>/dev/null || echo "$retired")"
    echo "  Lifetime: ${lifetime_days} days"
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  if [[ $# -eq 0 ]]; then
    usage
  fi

  FLAG_NAME="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verify)
        VERIFY=true
        shift
        ;;
      --force)
        FORCE=true
        VERIFY=false
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

  # Check registry exists
  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    log_error "Flag registry not found: $FLAG_REGISTRY"
    exit 1
  fi

  # Check flag exists
  if ! flag_exists "$FLAG_NAME"; then
    log_error "Flag not found: $FLAG_NAME"
    echo ""
    echo "List active flags: /flag.list"
    echo ""
    exit 1
  fi

  # Check if already retired
  if is_flag_retired "$FLAG_NAME"; then
    log_info "Flag already retired: $FLAG_NAME"
    get_flag_details "$FLAG_NAME"
    echo ""
    echo "No action needed."
    echo ""
    exit 0
  fi

  # Verify no code references (unless force)
  if [[ "$VERIFY" == true ]]; then
    if ! scan_code_references "$FLAG_NAME"; then
      exit 1
    fi
    echo ""
  else
    log_warning "Skipping verification (--force)"
    echo ""
    echo "Note: Code may still reference this flag."
    echo "Search manually: grep -r \"$FLAG_NAME\" src/"
    echo ""
  fi

  # Retire flag
  retire_flag "$FLAG_NAME"

  # Print details
  get_flag_details "$FLAG_NAME"

  # Success message
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Registry updated."
  echo ""
  echo "Commit changes:"
  echo "  git add .spec-flow/memory/feature-flags.yaml"
  echo "  git commit -m \"refactor: remove $FLAG_NAME flag"
  echo ""
  echo "Feature complete and deployed."
  echo ""
  echo "🤖 Generated with [Claude Code](https://claude.com/claude-code)\""
  echo ""
}

main "$@"

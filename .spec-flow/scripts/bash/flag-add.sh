#!/usr/bin/env bash
#
# flag-add.sh - Add feature flag to registry
#
# Usage: flag-add.sh <flag-name> [--branch BRANCH] [--epic EPIC] [--reason TEXT] [--expires DATE]

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
BRANCH=""
EPIC=""
REASON=""
EXPIRES=""
OWNER="${USER:-unknown}"

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") <flag-name> [OPTIONS]

Add feature flag to enable merging incomplete work.

Arguments:
  flag-name   Unique flag identifier (snake_case, ends with _enabled)

Options:
  --branch BRANCH   Git branch (default: current branch)
  --epic EPIC       Epic this flag belongs to
  --reason TEXT     Why this flag exists (required)
  --expires DATE    Expiry date (default: 14 days from now)
  --owner NAME      Flag owner (default: current user)
  -h, --help        Show this help

Examples:
  $(basename "$0") acs_sync_enabled --reason "Large feature - daily merges"
  $(basename "$0") parser_enabled --epic acs-epic-b --reason "OCR integration"
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
# Validate flag name
#######################################
validate_flag_name() {
  local name=$1

  # Must be snake_case ending with _enabled
  if [[ ! "$name" =~ ^[a-z0-9_]+_enabled$ ]]; then
    log_error "Invalid flag name: $name"
    echo ""
    echo "Flag names must:"
    echo "  - Use snake_case"
    echo "  - End with _enabled"
    echo "  - Example: acs_sync_enabled"
    echo ""
    exit 1
  fi
}

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
# Get current branch
#######################################
get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

#######################################
# Get default expiry date (14 days)
#######################################
get_default_expiry() {
  date -d "+14 days" -Iseconds 2>/dev/null || date -v+14d -Iseconds 2>/dev/null || echo "2025-12-01T00:00:00Z"
}

#######################################
# Initialize registry if doesn't exist
#######################################
init_registry() {
  if [[ ! -f "$FLAG_REGISTRY" ]]; then
    mkdir -p "$(dirname "$FLAG_REGISTRY")"
    cat > "$FLAG_REGISTRY" <<'EOF'
# Feature Flag Registry
flags: []
EOF
    log_success "Initialized flag registry: $FLAG_REGISTRY"
  fi
}

#######################################
# Add flag to registry
#######################################
add_flag() {
  local name=$1
  local branch=$2
  local epic=$3
  local reason=$4
  local expires=$5
  local owner=$6

  local created
  created=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")

  # Use yq if available, otherwise manual append
  if command -v yq &> /dev/null; then
    yq eval ".flags += [{
      \"name\": \"$name\",
      \"owner\": \"$owner\",
      \"epic\": \"$epic\",
      \"branch\": \"$branch\",
      \"created\": \"$created\",
      \"expires\": \"$expires\",
      \"status\": \"active\",
      \"reason\": \"$reason\",
      \"code_locations\": []
    }]" -i "$FLAG_REGISTRY"
  else
    # Fallback: manual YAML append
    cat >> "$FLAG_REGISTRY" <<EOF
  - name: $name
    owner: $owner
    epic: $epic
    branch: $branch
    created: $created
    expires: $expires
    status: active
    reason: "$reason"
    code_locations: []
EOF
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
      --branch)
        BRANCH="$2"
        shift 2
        ;;
      --epic)
        EPIC="$2"
        shift 2
        ;;
      --reason)
        REASON="$2"
        shift 2
        ;;
      --expires)
        EXPIRES="$2"
        shift 2
        ;;
      --owner)
        OWNER="$2"
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

  # Validate flag name
  validate_flag_name "$FLAG_NAME"

  # Check for duplicates
  if flag_exists "$FLAG_NAME"; then
    log_error "Flag already exists: $FLAG_NAME"
    echo ""
    echo "List existing flags: /flag.list"
    echo "Or cleanup: /flag.cleanup $FLAG_NAME"
    echo ""
    exit 1
  fi

  # Require reason
  if [[ -z "$REASON" ]]; then
    log_error "Flag reason required"
    echo ""
    echo "Example:"
    echo "  /flag.add $FLAG_NAME --reason \"Work incomplete - merging daily\""
    echo ""
    exit 1
  fi

  # Set defaults
  if [[ -z "$BRANCH" ]]; then
    BRANCH=$(get_current_branch)
  fi

  if [[ -z "$EXPIRES" ]]; then
    EXPIRES=$(get_default_expiry)
  fi

  # Initialize registry if needed
  init_registry

  # Add flag
  add_flag "$FLAG_NAME" "$BRANCH" "$EPIC" "$REASON" "$EXPIRES" "$OWNER"

  # Success message
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "Flag created: $FLAG_NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Details:"
  echo "  Branch: $BRANCH"
  if [[ -n "$EPIC" ]]; then
    echo "  Epic: $EPIC"
  fi
  echo "  Expires: $EXPIRES"
  echo "  Reason: $REASON"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. Wrap incomplete code with flag:"
  echo "     if (featureFlags.${FLAG_NAME}) { ... }"
  echo ""
  echo "  2. Merge to main (branch age limit no longer blocks)"
  echo ""
  echo "  3. Remove flag when complete:"
  echo "     /flag.cleanup $FLAG_NAME"
  echo ""
}

main "$@"

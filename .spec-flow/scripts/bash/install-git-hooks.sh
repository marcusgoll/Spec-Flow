#!/usr/bin/env bash
#
# install-git-hooks.sh - Install git hooks for workflow enforcement
#
# Usage: install-git-hooks.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../.." && pwd)"
HOOKS_SOURCE="$SCRIPT_DIR/git-hooks"
HOOKS_TARGET="$REPO_ROOT/.git/hooks"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORCE=false

#######################################
# Print usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [--force]

Install git hooks for workflow enforcement.

Options:
  --force    Overwrite existing hooks
  -h, --help Show this help message

Hooks installed:
  - pre-push: Enforce branch age limits (24h max)
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*"; }

#######################################
# Install single hook
#######################################
install_hook() {
  local hook_name=$1
  local source_file="$HOOKS_SOURCE/$hook_name"
  local target_file="$HOOKS_TARGET/$hook_name"

  if [[ ! -f "$source_file" ]]; then
    log_warning "Hook source not found: $source_file"
    return 1
  fi

  # Check if hook already exists
  if [[ -f "$target_file" ]] && [[ "$FORCE" == false ]]; then
    log_warning "Hook already exists: $hook_name (use --force to overwrite)"
    return 0
  fi

  # Copy hook
  cp "$source_file" "$target_file"
  chmod +x "$target_file"

  log_success "Installed $hook_name"
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE=true
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        echo "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Check git repository
  if [[ ! -d "$REPO_ROOT/.git" ]]; then
    echo "Error: Not a git repository"
    exit 1
  fi

  # Create hooks directory if doesn't exist
  mkdir -p "$HOOKS_TARGET"

  log_info "Installing git hooks..."
  echo ""

  # Install hooks
  install_hook "pre-push"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "Git hooks installed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Hooks installed:"
  echo "  - pre-push: Enforces 24h branch age limit"
  echo ""
  echo "Behavior:"
  echo "  - Warns at 18h branch age"
  echo "  - Blocks at 24h branch age"
  echo "  - Exception: Feature flag exists for branch"
  echo ""
  echo "To bypass (not recommended):"
  echo "  git push --no-verify"
  echo ""
}

main "$@"

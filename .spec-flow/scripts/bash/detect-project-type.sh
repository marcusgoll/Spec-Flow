#!/bin/bash
#
# detect-project-type.sh
# Detect project deployment model for workflow adaptation
#
# Returns one of:
#   - local-only: No remote repo configured
#   - remote-staging-prod: Remote repo with staging branch
#   - remote-direct: Remote repo without staging branch
#
# Usage:
#   PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
#

set -e

# Detect if project has remote origin
has_remote() {
  git remote -v 2>/dev/null | grep -q "origin"
}

# Detect if staging branch exists (local or remote)
has_staging() {
  git show-ref --verify --quiet refs/heads/staging 2>/dev/null || \
  git show-ref --verify --quiet refs/remotes/origin/staging 2>/dev/null
}

# Main detection logic
detect_project_type() {
  if ! has_remote; then
    echo "local-only"
    return 0
  fi

  if has_staging; then
    echo "remote-staging-prod"
    return 0
  fi

  echo "remote-direct"
  return 0
}

# Execute detection
detect_project_type

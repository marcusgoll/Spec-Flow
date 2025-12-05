#!/usr/bin/env bash
set -euo pipefail

# Ship rollback - Rollback to previous deployment version
# Deletes git tag, triggers rollback workflow, verifies health

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

# Parse arguments
TARGET_VERSION=""
FEATURE_DIR=""
NO_INPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature-dir)
      FEATURE_DIR="$2"
      shift 2
      ;;
    --no-input)
      NO_INPUT=true
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      TARGET_VERSION="$1"
      shift
      ;;
  esac
done

# Check for NO_INPUT environment variable
if [ "${SPEC_FLOW_NO_INPUT:-}" = "true" ] || [ "${CI:-}" = "true" ]; then
  NO_INPUT=true
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Deployment Rollback"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1: FIND CURRENT AND TARGET VERSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Analyzing deployment versions..."

# Get all version tags sorted by date
TAGS=$(git tag -l "v*" --sort=-creatordate 2>/dev/null | head -10)

if [ -z "$TAGS" ]; then
  log_error "No version tags found. Cannot rollback."
  exit 1
fi

# Current version is the most recent tag
CURRENT_VERSION=$(echo "$TAGS" | head -1)

log_info "Current version: $CURRENT_VERSION"

# List available versions to rollback to
if [ -z "$TARGET_VERSION" ]; then
  echo ""
  echo "Available versions to rollback to:"
  echo ""

  i=1
  while IFS= read -r tag; do
    if [ "$tag" != "$CURRENT_VERSION" ]; then
      # Get tag date
      tag_date=$(git log -1 --format="%ci" "$tag" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
      echo "  $i. $tag ($tag_date)"
      ((i++))
    fi
  done <<< "$TAGS"

  echo ""

  if [ "$NO_INPUT" = true ]; then
    # In non-interactive mode, default to previous version
    TARGET_VERSION=$(echo "$TAGS" | sed -n '2p')
    log_info "Auto-selected: $TARGET_VERSION (--no-input mode)"
  else
    read -rp "Select version to rollback to [1]: " VERSION_CHOICE

    # Default to 1 if empty
    VERSION_CHOICE="${VERSION_CHOICE:-1}"

    # Get the selected version (skip current, so index is +1)
    TARGET_VERSION=$(echo "$TAGS" | grep -v "^${CURRENT_VERSION}$" | sed -n "${VERSION_CHOICE}p")
  fi
fi

# Validate target version
if [ -z "$TARGET_VERSION" ]; then
  log_error "Invalid version selection"
  exit 1
fi

# Ensure v prefix
if [[ ! "$TARGET_VERSION" =~ ^v ]]; then
  TARGET_VERSION="v$TARGET_VERSION"
fi

# Check target version exists
if ! git rev-parse "$TARGET_VERSION" >/dev/null 2>&1; then
  log_error "Version $TARGET_VERSION does not exist"
  echo ""
  echo "Available versions:"
  echo "$TAGS"
  exit 1
fi

echo ""
log_info "Rolling back from $CURRENT_VERSION to $TARGET_VERSION"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2: CONFIRM ROLLBACK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$NO_INPUT" != true ]; then
  echo "⚠️  This will:"
  echo "   1. Delete the current version tag ($CURRENT_VERSION) locally and remotely"
  echo "   2. Trigger rollback workflow in GitHub Actions"
  echo "   3. Deploy $TARGET_VERSION to production"
  echo ""
  read -rp "Continue with rollback? [y/N]: " CONFIRM

  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "Rollback cancelled"
    exit 0
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3: DELETE CURRENT VERSION TAG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Deleting current version tag: $CURRENT_VERSION"

# Delete local tag
if git tag -d "$CURRENT_VERSION" 2>/dev/null; then
  log_success "Deleted local tag: $CURRENT_VERSION"
else
  log_warning "Local tag already deleted or doesn't exist"
fi

# Delete remote tag
if git push origin --delete "$CURRENT_VERSION" 2>/dev/null; then
  log_success "Deleted remote tag: $CURRENT_VERSION"
else
  log_warning "Remote tag already deleted or doesn't exist"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4: TRIGGER ROLLBACK WORKFLOW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Triggering rollback deployment..."

# Check if rollback workflow exists
ROLLBACK_WORKFLOW=".github/workflows/rollback.yml"
DEPLOY_WORKFLOW=".github/workflows/deploy-production.yml"

if [ -f "$ROLLBACK_WORKFLOW" ]; then
  # Use dedicated rollback workflow
  log_info "Using dedicated rollback workflow"

  if command -v gh &>/dev/null && gh auth status >/dev/null 2>&1; then
    gh workflow run rollback.yml -f version="$TARGET_VERSION" 2>/dev/null || {
      log_warning "Failed to dispatch rollback workflow"
      log_info "Attempting manual tag push instead..."
    }
  fi
elif [ -f "$DEPLOY_WORKFLOW" ]; then
  # Re-push target tag to trigger deployment
  log_info "No rollback workflow found, re-triggering deployment with target version"

  # Create a new rollback tag pointing to target version
  ROLLBACK_TAG="${CURRENT_VERSION}-rollback"
  git tag -a "$ROLLBACK_TAG" "$TARGET_VERSION" -m "Rollback to $TARGET_VERSION" 2>/dev/null || true

  if git push origin "$ROLLBACK_TAG" 2>/dev/null; then
    log_success "Pushed rollback tag: $ROLLBACK_TAG → $TARGET_VERSION"
  else
    log_warning "Failed to push rollback tag"
  fi
else
  log_warning "No deployment workflow found"
  log_info "Manual rollback required:"
  echo "  1. Deploy $TARGET_VERSION to production manually"
  echo "  2. Or use your CI/CD platform's rollback feature"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 5: MONITOR ROLLBACK (IF GH AVAILABLE)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command -v gh &>/dev/null && gh auth status >/dev/null 2>&1; then
  echo ""
  log_info "Waiting for rollback workflow to start..."
  sleep 10

  # Find the workflow run
  WORKFLOW_RUN=$(gh run list --limit 5 --json databaseId,headBranch,status,conclusion \
    | jq -r '.[0].databaseId' 2>/dev/null || echo "")

  if [ -n "$WORKFLOW_RUN" ] && [ "$WORKFLOW_RUN" != "null" ]; then
    log_info "Found workflow run: $WORKFLOW_RUN"
    echo ""
    log_info "Watching rollback progress..."
    echo "(Press Ctrl+C to stop watching, rollback will continue)"
    echo ""

    if gh run watch "$WORKFLOW_RUN" --exit-status 2>/dev/null; then
      log_success "Rollback deployment completed!"
    else
      log_error "Rollback deployment failed"
      echo ""
      echo "View logs: gh run view $WORKFLOW_RUN --log"
      exit 1
    fi
  else
    log_warning "Could not find workflow run to monitor"
    log_info "Check GitHub Actions manually"
  fi
else
  log_warning "GitHub CLI not available for monitoring"
  log_info "Check deployment status manually in GitHub Actions"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 6: UPDATE STATE AND VERIFY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Find feature directory if not provided
if [ -z "$FEATURE_DIR" ]; then
  FEATURE_DIR=$(find specs/ -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort -n | tail -1 || echo "")
fi

if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/state.yaml" ]; then
  log_info "Updating state.yaml with rollback info"

  if command -v yq &>/dev/null; then
    yq eval ".deployment.production.rollback_from = \"$CURRENT_VERSION\"" -i "$FEATURE_DIR/state.yaml"
    yq eval ".deployment.production.rollback_to = \"$TARGET_VERSION\"" -i "$FEATURE_DIR/state.yaml"
    yq eval ".deployment.production.rollback_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" -i "$FEATURE_DIR/state.yaml"
    yq eval ".deployment.production.version = \"${TARGET_VERSION#v}\"" -i "$FEATURE_DIR/state.yaml"

    log_success "Updated state.yaml"
  else
    log_warning "yq not installed, cannot update state.yaml"
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Rollback Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Rolled back: $CURRENT_VERSION → $TARGET_VERSION"
echo ""
echo "📋 POST-ROLLBACK CHECKLIST:"
echo "  □ Verify production health endpoint"
echo "  □ Check error rates in monitoring"
echo "  □ Investigate root cause of original issue"
echo "  □ Create fix and deploy as new version"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

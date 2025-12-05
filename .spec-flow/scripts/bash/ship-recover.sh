#!/usr/bin/env bash
set -euo pipefail

# Ship state recovery - Recover corrupted state.yaml from git history
# Scans commits, deployment artifacts, and git tags to reconstruct state

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
FEATURE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature-dir)
      FEATURE_DIR="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      FEATURE_DIR="$1"
      shift
      ;;
  esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 State Recovery Tool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1: FIND FEATURE DIRECTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -z "$FEATURE_DIR" ]; then
  log_info "Scanning for feature directories..."

  # Find most recent feature directory
  FEATURE_DIR=$(find specs/ -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort -n | tail -1 || echo "")

  if [ -z "$FEATURE_DIR" ]; then
    log_error "No feature directory found in specs/"
    echo ""
    echo "Usage: ship-recover.sh [--feature-dir <path>]"
    exit 1
  fi
fi

FEATURE_SLUG=$(basename "$FEATURE_DIR")
STATE_FILE="$FEATURE_DIR/state.yaml"

log_info "Feature directory: $FEATURE_DIR"
log_info "Feature slug: $FEATURE_SLUG"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2: BACKUP EXISTING STATE (IF ANY)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f "$STATE_FILE" ]; then
  BACKUP_FILE="${STATE_FILE}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$STATE_FILE" "$BACKUP_FILE"
  log_info "Backed up existing state to: $BACKUP_FILE"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3: RECOVER FROM GIT HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Scanning git history for state.yaml versions..."

# Try to recover from git history
GIT_RECOVERED=false

if git log --oneline -- "$STATE_FILE" 2>/dev/null | head -1 | grep -q .; then
  # Find last good version in git
  LAST_COMMIT=$(git log --oneline -1 -- "$STATE_FILE" 2>/dev/null | awk '{print $1}')

  if [ -n "$LAST_COMMIT" ]; then
    log_info "Found state.yaml in git history (commit: $LAST_COMMIT)"

    # Try to restore from git
    if git show "$LAST_COMMIT:$STATE_FILE" > "${STATE_FILE}.git-recovered" 2>/dev/null; then
      log_success "Recovered state.yaml from git history"
      GIT_RECOVERED=true
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4: RECONSTRUCT FROM ARTIFACTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Reconstructing state from available artifacts..."

# Initialize recovered state
RECOVERED_STATE=""

# Extract feature info from spec.md
FEATURE_TITLE=""
if [ -f "$FEATURE_DIR/spec.md" ]; then
  FEATURE_TITLE=$(grep -E "^#\s+" "$FEATURE_DIR/spec.md" 2>/dev/null | head -1 | sed 's/^#\s*//' || echo "")
fi
FEATURE_TITLE="${FEATURE_TITLE:-$FEATURE_SLUG}"

# Extract version from CHANGELOG.md or git tags
VERSION=""
LATEST_TAG=$(git tag -l "v*" --sort=-creatordate 2>/dev/null | head -1 || echo "")
if [ -n "$LATEST_TAG" ]; then
  VERSION="${LATEST_TAG#v}"
fi
VERSION="${VERSION:-0.1.0}"

# Detect current phase from artifacts
CURRENT_PHASE="unknown"
PHASE_STATUS="unknown"

if [ -f "$FEATURE_DIR/completed/spec.md" ] || [ -f "$FEATURE_DIR/completed/plan.md" ]; then
  CURRENT_PHASE="finalize"
  PHASE_STATUS="completed"
elif [ -f "$FEATURE_DIR/staging-validation-report.md" ]; then
  CURRENT_PHASE="ship"
  PHASE_STATUS="staging-validated"
elif [ -f "$FEATURE_DIR/optimization-report.md" ]; then
  CURRENT_PHASE="optimize"
  PHASE_STATUS="completed"
elif [ -f "$FEATURE_DIR/tasks.md" ]; then
  # Check if all tasks are completed
  TOTAL_TASKS=$(grep -cE "^\s*-\s*\[" "$FEATURE_DIR/tasks.md" 2>/dev/null || echo 0)
  COMPLETED_TASKS=$(grep -cE "^\s*-\s*\[x\]" "$FEATURE_DIR/tasks.md" 2>/dev/null || echo 0)

  if [ "$TOTAL_TASKS" -gt 0 ] && [ "$TOTAL_TASKS" = "$COMPLETED_TASKS" ]; then
    CURRENT_PHASE="implement"
    PHASE_STATUS="completed"
  else
    CURRENT_PHASE="implement"
    PHASE_STATUS="in_progress"
  fi
elif [ -f "$FEATURE_DIR/plan.md" ]; then
  CURRENT_PHASE="plan"
  PHASE_STATUS="completed"
elif [ -f "$FEATURE_DIR/spec.md" ]; then
  CURRENT_PHASE="spec"
  PHASE_STATUS="completed"
fi

# Detect deployment info from git tags
PRODUCTION_URL=""
PRODUCTION_VERSION=""
PRODUCTION_DEPLOYED_AT=""

if [ -n "$LATEST_TAG" ]; then
  PRODUCTION_VERSION="${LATEST_TAG#v}"
  TAG_DATE=$(git log -1 --format="%ci" "$LATEST_TAG" 2>/dev/null | cut -d' ' -f1 || echo "")
  PRODUCTION_DEPLOYED_AT="$TAG_DATE"
fi

# Check for staging validation report
STAGING_URL=""
if [ -f "$FEATURE_DIR/staging-validation-report.md" ]; then
  STAGING_URL=$(grep -oE "https?://[a-zA-Z0-9.-]+\.vercel\.app" "$FEATURE_DIR/staging-validation-report.md" 2>/dev/null | head -1 || echo "")
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
FEATURE_BRANCH=""
if [[ "$CURRENT_BRANCH" =~ ^feature/ ]] || [[ "$CURRENT_BRANCH" =~ ^feat/ ]]; then
  FEATURE_BRANCH="$CURRENT_BRANCH"
fi

# Get start date from first commit in feature
START_DATE=""
if [ -n "$FEATURE_BRANCH" ]; then
  START_DATE=$(git log --oneline --reverse "$FEATURE_BRANCH" 2>/dev/null | head -1 | git log -1 --format="%ci" $(awk '{print $1}') 2>/dev/null | cut -d' ' -f1 || echo "")
fi
START_DATE="${START_DATE:-$(date +%F)}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 5: GENERATE RECOVERED STATE.YAML
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Generating recovered state.yaml..."

if [ "$GIT_RECOVERED" = true ] && [ -f "${STATE_FILE}.git-recovered" ]; then
  # Use git-recovered version as base, update with current info
  mv "${STATE_FILE}.git-recovered" "$STATE_FILE"
  log_info "Using git-recovered state as base"

  # Update with current info
  if command -v yq &>/dev/null; then
    yq eval ".recovery.recovered_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" -i "$STATE_FILE"
    yq eval ".recovery.method = \"git-history\"" -i "$STATE_FILE"
  fi
else
  # Generate fresh state from artifacts
  cat > "$STATE_FILE" <<EOF
# Recovered state.yaml - Generated by ship-recover.sh
# Review and correct any inaccurate values

feature:
  title: "$FEATURE_TITLE"
  slug: "$FEATURE_SLUG"
  started_at: "$START_DATE"

version: "$VERSION"
status: "$PHASE_STATUS"

phases:
  spec:
    status: $([ -f "$FEATURE_DIR/spec.md" ] && echo "completed" || echo "pending")
  clarify:
    status: unknown
  plan:
    status: $([ -f "$FEATURE_DIR/plan.md" ] && echo "completed" || echo "pending")
  tasks:
    status: $([ -f "$FEATURE_DIR/tasks.md" ] && echo "completed" || echo "pending")
  implement:
    status: "$PHASE_STATUS"
  optimize:
    status: $([ -f "$FEATURE_DIR/optimization-report.md" ] && echo "completed" || echo "pending")
  ship:
    status: $([ -n "$STAGING_URL" ] && echo "staging-deployed" || echo "pending")
  finalize:
    status: pending

workflow:
  type: feature
  current_phase: "$CURRENT_PHASE"
  git:
    feature_branch: "${FEATURE_BRANCH:-}"
    worktree_enabled: false
    worktree_path: ""

deployment:
  staging:
    url: "$STAGING_URL"
  production:
    url: "$PRODUCTION_URL"
    version: "$PRODUCTION_VERSION"
    deployed_at: "$PRODUCTION_DEPLOYED_AT"

recovery:
  recovered_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  method: "artifact-reconstruction"
  original_backup: "${BACKUP_FILE:-none}"
EOF

  log_success "Generated new state.yaml from artifacts"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 6: VALIDATE RECOVERED STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

log_info "Validating recovered state..."

VALIDATION_ERRORS=0

# Check required fields
if ! grep -q "feature:" "$STATE_FILE" 2>/dev/null; then
  log_warning "Missing 'feature' section"
  ((VALIDATION_ERRORS++))
fi

if ! grep -q "version:" "$STATE_FILE" 2>/dev/null; then
  log_warning "Missing 'version' field"
  ((VALIDATION_ERRORS++))
fi

if ! grep -q "phases:" "$STATE_FILE" 2>/dev/null; then
  log_warning "Missing 'phases' section"
  ((VALIDATION_ERRORS++))
fi

if [ $VALIDATION_ERRORS -eq 0 ]; then
  log_success "State validation passed"
else
  log_warning "State validation found $VALIDATION_ERRORS issues"
  log_info "Please review and correct $STATE_FILE manually"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ State Recovery Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Recovered state:"
echo "  Feature: $FEATURE_TITLE"
echo "  Slug: $FEATURE_SLUG"
echo "  Current Phase: $CURRENT_PHASE"
echo "  Phase Status: $PHASE_STATUS"
echo "  Version: $VERSION"
echo ""

if [ -n "${BACKUP_FILE:-}" ]; then
  echo "Original backup: $BACKUP_FILE"
  echo ""
fi

echo "📋 NEXT STEPS:"
echo "  1. Review recovered state: cat $STATE_FILE"
echo "  2. Correct any inaccurate values"
echo "  3. Resume workflow: /ship continue"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

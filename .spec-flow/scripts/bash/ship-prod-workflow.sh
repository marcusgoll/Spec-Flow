#!/usr/bin/env bash
set -euo pipefail

# Ship-prod workflow - Tagged promotion to production
# Creates semantic version tag, pushes to trigger GitHub Actions deployment

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

# Parse arguments
FEATURE_DIR=""
VERSION_ARG=""
NO_INPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION_ARG="${2:-patch}"
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
      FEATURE_DIR="$1"
      shift
      ;;
  esac
done

# Check for NO_INPUT environment variable (CI/CD mode)
if [ "${SPEC_FLOW_NO_INPUT:-}" = "true" ] || [ "${CI:-}" = "true" ]; then
  NO_INPUT=true
fi

if [ -z "$FEATURE_DIR" ]; then
  echo "Usage: ship-prod-workflow.sh <feature-dir> [--version major|minor|patch] [--no-input]"
  echo ""
  echo "Options:"
  echo "  --version TYPE   Version bump type: major, minor, or patch (default: patch)"
  echo "  --no-input       Non-interactive mode for CI/CD (uses patch if --version not specified)"
  echo ""
  echo "Environment variables:"
  echo "  SPEC_FLOW_NO_INPUT=true   Same as --no-input"
  echo "  CI=true                   Same as --no-input (auto-detected in CI environments)"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1: VALIDATE STAGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Production Deployment (Tagged Promotion)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if staging validation passed
VALIDATION_REPORT="$FEATURE_DIR/staging-validation-report.md"

if [ ! -f "$VALIDATION_REPORT" ]; then
  echo "❌ Staging validation report not found: $VALIDATION_REPORT"
  echo ""
  echo "Run /validate-staging first"
  exit 1
fi

# Check if validation passed
if ! grep -q "✅ All checks passed" "$VALIDATION_REPORT" 2>/dev/null; then
  echo "❌ Staging validation has not passed"
  echo ""
  echo "Fix blockers in staging-validation-report.md and re-run /validate-staging"
  exit 1
fi

echo "✅ Staging validation passed"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2: EXTRACT VERSION FROM CHANGELOG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Version Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if CHANGELOG.md exists
if [ ! -f "CHANGELOG.md" ]; then
  echo "⚠️  CHANGELOG.md not found, starting at v1.0.0"
  CURRENT_VERSION="v0.0.0"
else
  # Extract latest version from CHANGELOG
  CURRENT_VERSION=$(grep -E "^## \[?v?[0-9]+" CHANGELOG.md | head -1 | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+" | head -1 || echo "v0.0.0")

  # Ensure 'v' prefix
  if [[ ! "$CURRENT_VERSION" =~ ^v ]]; then
    CURRENT_VERSION="v$CURRENT_VERSION"
  fi
fi

# Remove 'v' prefix for parsing
VERSION_NUMS=${CURRENT_VERSION#v}

# Split into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NUMS"

echo "Current version: v$MAJOR.$MINOR.$PATCH"
echo ""

# Suggest next version
PATCH_VERSION="v$MAJOR.$MINOR.$((PATCH + 1))"
MINOR_VERSION="v$MAJOR.$((MINOR + 1)).0"
MAJOR_VERSION="v$((MAJOR + 1)).0.0"

# Handle non-interactive mode or --version argument
if [ -n "$VERSION_ARG" ] || [ "$NO_INPUT" = true ]; then
  # Use VERSION_ARG if provided, otherwise default to patch
  VERSION_TYPE="${VERSION_ARG:-patch}"

  case "$VERSION_TYPE" in
    major)
      NEXT_VERSION="$MAJOR_VERSION"
      ;;
    minor)
      NEXT_VERSION="$MINOR_VERSION"
      ;;
    patch)
      NEXT_VERSION="$PATCH_VERSION"
      ;;
    *)
      # Assume it's a custom version string (e.g., v1.2.3)
      if [[ ! "$VERSION_TYPE" =~ ^v ]]; then
        VERSION_TYPE="v$VERSION_TYPE"
      fi
      NEXT_VERSION="$VERSION_TYPE"
      VERSION_TYPE="custom"
      ;;
  esac

  echo "Version options:"
  echo "  - Patch: $PATCH_VERSION (bug fixes, minor changes)"
  echo "  - Minor: $MINOR_VERSION (new features, backwards compatible)"
  echo "  - Major: $MAJOR_VERSION (breaking changes)"
  echo ""
  echo "Auto-selected: $VERSION_TYPE (--no-input mode)"
else
  # Interactive mode
  echo "Version options:"
  echo "  1. Patch: $PATCH_VERSION (bug fixes, minor changes)"
  echo "  2. Minor: $MINOR_VERSION (new features, backwards compatible)"
  echo "  3. Major: $MAJOR_VERSION (breaking changes)"
  echo "  4. Custom"
  echo ""

  read -p "Select version [1]: " VERSION_CHOICE

  case "${VERSION_CHOICE:-1}" in
    1)
      NEXT_VERSION="$PATCH_VERSION"
      VERSION_TYPE="patch"
      ;;
    2)
      NEXT_VERSION="$MINOR_VERSION"
      VERSION_TYPE="minor"
      ;;
    3)
      NEXT_VERSION="$MAJOR_VERSION"
      VERSION_TYPE="major"
      ;;
    4)
      read -p "Enter custom version (e.g., v1.2.3): " CUSTOM_VERSION
      # Ensure 'v' prefix
      if [[ ! "$CUSTOM_VERSION" =~ ^v ]]; then
        CUSTOM_VERSION="v$CUSTOM_VERSION"
      fi
      NEXT_VERSION="$CUSTOM_VERSION"
      VERSION_TYPE="custom"
      ;;
    *)
      NEXT_VERSION="$PATCH_VERSION"
      VERSION_TYPE="patch"
      ;;
  esac
fi

echo ""
echo "Selected version: $NEXT_VERSION ($VERSION_TYPE)"
echo ""

# Validate semantic version format
if [[ ! "$NEXT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format: $NEXT_VERSION"
  echo "   Expected: vMAJOR.MINOR.PATCH (e.g., v1.2.3)"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3: CREATE GIT TAG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating Git Tag"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if tag already exists
if git rev-parse "$NEXT_VERSION" >/dev/null 2>&1; then
  echo "❌ Tag $NEXT_VERSION already exists"
  echo ""
  echo "Options:"
  echo "  1. Delete existing tag: git tag -d $NEXT_VERSION && git push origin :refs/tags/$NEXT_VERSION"
  echo "  2. Choose a different version"
  exit 1
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
  echo "⚠️  Working directory has uncommitted changes"
  echo ""
  git status --short
  echo ""

  if [ "$NO_INPUT" = true ]; then
    # In non-interactive mode, auto-commit changes
    echo "Auto-committing changes (--no-input mode)..."
    git add .
    git commit -m "chore: prepare release $NEXT_VERSION" --no-verify
    echo "✅ Changes committed"
  else
    read -p "Commit changes before tagging? [y/N]: " COMMIT_CHOICE

    if [[ "$COMMIT_CHOICE" =~ ^[Yy]$ ]]; then
      git add .
      git commit -m "chore: prepare release $NEXT_VERSION" --no-verify
      echo "✅ Changes committed"
    else
      echo "❌ Cannot create tag with uncommitted changes"
      exit 1
    fi
  fi
fi

# Extract feature slug for tag message
FEATURE_SLUG=$(basename "$FEATURE_DIR")

# Create annotated git tag
TAG_MESSAGE="Release $NEXT_VERSION

Feature: $FEATURE_SLUG

Deployed via tagged promotion workflow.

Generated by Spec-Flow /ship-prod"

if git tag -a "$NEXT_VERSION" -m "$TAG_MESSAGE"; then
  echo "✅ Created tag: $NEXT_VERSION"
else
  echo "❌ Failed to create tag"
  exit 1
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4: PUSH TAG TO TRIGGER DEPLOYMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pushing Tag to Trigger Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Push tag to origin
if git push origin "$NEXT_VERSION"; then
  echo "✅ Tag pushed to origin: $NEXT_VERSION"
else
  echo "❌ Failed to push tag"
  echo ""
  echo "Cleaning up local tag..."
  git tag -d "$NEXT_VERSION"
  exit 1
fi

echo ""
echo "GitHub Actions will now deploy to production automatically."
echo "Tag: $NEXT_VERSION"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 5: WAIT FOR GITHUB ACTIONS WORKFLOW
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Monitoring Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "⚠️  GitHub CLI (gh) not installed"
  echo ""
  echo "Cannot monitor workflow automatically."
  echo "Check deployment status manually:"
  echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions"
  echo ""
  echo "Run this script again after deployment completes to verify."
  exit 0
fi

# Check if authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "⚠️  GitHub CLI not authenticated"
  echo ""
  echo "Run: gh auth login"
  exit 1
fi

# Wait a few seconds for workflow to start
echo "Waiting for workflow to start..."
sleep 10

# Get workflow run ID for this tag
WORKFLOW_RUN=$(gh run list --workflow="deploy-production.yml" --limit 5 --json databaseId,headBranch,status \
  | jq -r --arg tag "$NEXT_VERSION" '.[] | select(.headBranch == $tag) | .databaseId' \
  | head -1)

if [ -z "$WORKFLOW_RUN" ] || [ "$WORKFLOW_RUN" = "null" ]; then
  echo "⚠️  Workflow run not found yet"
  echo ""
  echo "The deployment may take a minute to start."
  echo "Monitor manually:"
  echo "  gh run list --workflow=deploy-production.yml"
  echo "  gh run watch <run-id>"
  exit 0
fi

echo "✅ Found workflow run: $WORKFLOW_RUN"
echo ""

# Watch the workflow
echo "Watching deployment progress..."
echo "(Press Ctrl+C to stop watching, deployment will continue)"
echo ""

if gh run watch "$WORKFLOW_RUN" --exit-status; then
  echo ""
  echo "✅ Deployment succeeded!"
else
  echo ""
  echo "❌ Deployment failed"
  echo ""
  echo "View logs: gh run view $WORKFLOW_RUN"
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 6: UPDATE WORKFLOW STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Updating Workflow State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update state.yaml with production deployment info
if command -v yq &> /dev/null; then
  WORKFLOW_STATE="$FEATURE_DIR/state.yaml"

  if [ -f "$WORKFLOW_STATE" ]; then
    yq eval ".deployment.production.version = \"${NEXT_VERSION#v}\"" -i "$WORKFLOW_STATE"
    yq eval ".deployment.production.tag = \"$NEXT_VERSION\"" -i "$WORKFLOW_STATE"
    yq eval ".deployment.production.tag_created_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" -i "$WORKFLOW_STATE"
    yq eval ".deployment.production.deployed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" -i "$WORKFLOW_STATE"
    yq eval ".deployment.production.github_release_url = \"https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/releases/tag/$NEXT_VERSION\"" -i "$WORKFLOW_STATE"

    echo "✅ Updated state.yaml"
  else
    echo "⚠️  state.yaml not found, skipping update"
  fi
else
  echo "⚠️  yq not installed, cannot update state.yaml"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINAL SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REPO_URL=$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Production Deployment Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Version: $NEXT_VERSION"
echo "GitHub Release: https://github.com/$REPO_URL/releases/tag/$NEXT_VERSION"
echo "Workflow Run: https://github.com/$REPO_URL/actions/runs/$WORKFLOW_RUN"
echo ""
echo "Next: Full documentation finalization will run automatically via /ship workflow."
echo ""

exit 0

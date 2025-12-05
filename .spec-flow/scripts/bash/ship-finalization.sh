#!/usr/bin/env bash
set -Eeuo pipefail

# Ship finalization script - handles roadmap updates, branch cleanup, infrastructure checks
# Called after deployment completes (staging/prod/local)

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

# Parse arguments
ACTION="${1:-finalize}"
FEATURE_DIR="${2:-}"

if [ -z "$FEATURE_DIR" ]; then
  echo "Usage: ship-finalization.sh <action> <feature-dir>"
  echo ""
  echo "Actions:"
  echo "  preflight    - Run pre-flight validation checks"
  echo "  finalize     - Update roadmap, cleanup branch, check infrastructure"
  echo ""
  exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PRE-FLIGHT VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$ACTION" = "preflight" ]; then
  echo "Running pre-flight validation checks..."
  echo ""

  # Check if npm/yarn/pnpm is available
  if command -v pnpm >/dev/null 2>&1; then
    BUILD_CMD="pnpm run build"
  elif command -v yarn >/dev/null 2>&1; then
    BUILD_CMD="yarn build"
  elif command -v npm >/dev/null 2>&1; then
    BUILD_CMD="npm run build"
  else
    echo "⚠️  No package manager found (npm/yarn/pnpm), skipping build check"
    BUILD_CMD=""
  fi

  # Run build to catch errors early
  if [ -n "$BUILD_CMD" ]; then
    echo "Running build: $BUILD_CMD"
    if ! $BUILD_CMD; then
      echo "❌ Build failed"
      exit 1
    fi
    echo "✅ Build successful"
  fi

  # Check for missing environment variables (if gh CLI available)
  if command -v gh >/dev/null 2>&1; then
    echo ""
    echo "Checking GitHub secrets..."
    gh secret list 2>/dev/null || echo "⚠️  Cannot list GitHub secrets (permissions required)"
  fi

  # Validate CI workflows (if .github/workflows exists)
  if [ -d ".github/workflows" ]; then
    echo ""
    echo "Validating CI workflows..."
    if command -v yq >/dev/null 2>&1; then
      for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
          echo "  Checking $workflow..."
          yq eval '.' "$workflow" >/dev/null || echo "  ⚠️  Syntax error in $workflow"
        fi
      done
      echo "✅ CI workflows validated"
    else
      echo "⚠️  yq not installed, skipping workflow validation"
    fi
  fi

  echo ""
  echo "✅ Pre-flight validation complete"
  exit 0
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "$ACTION" != "finalize" ]; then
  echo "Unknown action: $ACTION"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ESSENTIAL FINALIZATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6.1: Update Roadmap Issue to 'Shipped'
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "Step 1: Updating roadmap issue..."
echo ""

# Check if gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
  echo "⚠️  GitHub CLI not installed, skipping roadmap update"
else
  # Check if authenticated
  if ! gh auth status >/dev/null 2>&1; then
    echo "⚠️  GitHub CLI not authenticated, skipping roadmap update"
  else
    # Get feature slug from state.yaml
    if command -v yq >/dev/null 2>&1; then
      FEATURE_SLUG=$(yq eval '.feature.slug' "$FEATURE_DIR/state.yaml" 2>/dev/null)
      GITHUB_ISSUE=$(yq eval '.feature.github_issue' "$FEATURE_DIR/state.yaml" 2>/dev/null)

      if [ -n "$GITHUB_ISSUE" ] && [ "$GITHUB_ISSUE" != "null" ]; then
        ISSUE_NUMBER="$GITHUB_ISSUE"
      else
        # Try to find issue by slug
        REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
        if [ -n "$REPO" ]; then
          ISSUE_JSON=$(gh issue list --repo "$REPO" --label type:feature --json number,body --limit 100 2>/dev/null | \
            jq -r --arg slug "$FEATURE_SLUG" 'map(select(.body | test("slug:\\s*\"" + $slug + "\""))) | first')

          if [ -n "$ISSUE_JSON" ] && [ "$ISSUE_JSON" != "null" ]; then
            ISSUE_NUMBER=$(echo "$ISSUE_JSON" | jq -r '.number')
          fi
        fi
      fi

      if [ -n "$ISSUE_NUMBER" ] && [ "$ISSUE_NUMBER" != "null" ]; then
        echo "Found issue #$ISSUE_NUMBER"

        # Update issue status to shipped
        gh issue edit "$ISSUE_NUMBER" \
          --add-label "status:shipped" \
          --remove-label "status:in-progress" 2>/dev/null || true

        # Get deployment details
        PROD_URL=$(yq eval '.deployment.production.url // "Not recorded"' "$FEATURE_DIR/state.yaml" 2>/dev/null)
        VERSION=$(yq eval '.deployment.version // "unknown"' "$FEATURE_DIR/state.yaml" 2>/dev/null)

        # Add shipped comment
        gh issue comment "$ISSUE_NUMBER" --body "🚀 Shipped in v$VERSION on $(date +%Y-%m-%d)

**Production URL**: $PROD_URL

Deployment complete!" 2>/dev/null || true

        # Close the issue
        gh issue close "$ISSUE_NUMBER" --comment "Closing as shipped." 2>/dev/null || true

        echo "✅ Issue #$ISSUE_NUMBER updated to 'shipped' and closed"
      else
        echo "⚠️  No GitHub issue found for feature: $FEATURE_SLUG"
      fi
    else
      echo "⚠️  yq not installed, skipping roadmap update"
    fi
  fi
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6.2: Clean Up Feature Branch
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "Step 2: Cleaning up feature branch..."
echo ""

# Get current branch
FEATURE_BRANCH=$(git branch --show-current 2>/dev/null)

# Detect main branch (main or master)
if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
  MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
  MAIN_BRANCH="master"
else
  echo "⚠️  Cannot detect main branch, skipping branch cleanup"
  MAIN_BRANCH=""
fi

if [ -n "$MAIN_BRANCH" ] && [ -n "$FEATURE_BRANCH" ]; then
  # Switch to main branch if not already on it
  if [ "$FEATURE_BRANCH" != "$MAIN_BRANCH" ]; then
    echo "Switching to $MAIN_BRANCH..."
    git checkout "$MAIN_BRANCH" 2>/dev/null || {
      echo "⚠️  Failed to switch to $MAIN_BRANCH, skipping branch cleanup"
      MAIN_BRANCH=""
    }
  else
    echo "Already on $MAIN_BRANCH"
  fi

  # Delete local feature branch
  if [ -n "$MAIN_BRANCH" ] && [ "$FEATURE_BRANCH" != "$MAIN_BRANCH" ]; then
    if git branch -d "$FEATURE_BRANCH" 2>/dev/null; then
      echo "✅ Deleted local branch: $FEATURE_BRANCH"
    else
      echo "⚠️  Cannot delete branch $FEATURE_BRANCH (may have unmerged changes)"
    fi

    # Delete remote feature branch (if exists)
    if git ls-remote --exit-code --heads origin "$FEATURE_BRANCH" >/dev/null 2>&1; then
      if git push origin --delete "$FEATURE_BRANCH" 2>/dev/null; then
        echo "✅ Deleted remote branch: origin/$FEATURE_BRANCH"
      else
        echo "⚠️  Failed to delete remote branch"
      fi
    else
      echo "⏭️  Remote branch doesn't exist, nothing to delete"
    fi
  fi
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6.3: Detect Feature Flags (v10.14+)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "Step 3: Detecting feature flags..."
echo ""

# Detect feature flag system in use
FLAG_SYSTEM=""
FLAG_FILES=()
FLAG_PATTERNS=()

# LaunchDarkly detection
if [ -f "ldconfig.json" ] || grep -rql "launchdarkly" package.json 2>/dev/null || \
   grep -rql "ld-" src/ 2>/dev/null; then
  FLAG_SYSTEM="LaunchDarkly"
  FLAG_PATTERNS+=("useFlags" "useLDClient" "ld-" "variation(" "ldclient")
fi

# Unleash detection
if [ -f "unleash-config.json" ] || grep -rql "unleash" package.json 2>/dev/null || \
   grep -rql "useUnleashContext" src/ 2>/dev/null; then
  FLAG_SYSTEM="${FLAG_SYSTEM:+$FLAG_SYSTEM, }Unleash"
  FLAG_PATTERNS+=("isEnabled(" "useUnleash" "unleash.isEnabled")
fi

# GrowthBook detection
if [ -f ".growthbook" ] || grep -rql "@growthbook" package.json 2>/dev/null; then
  FLAG_SYSTEM="${FLAG_SYSTEM:+$FLAG_SYSTEM, }GrowthBook"
  FLAG_PATTERNS+=("useFeature" "useFeatureIsOn" "gb.isOn")
fi

# Custom flag detection (common patterns)
CUSTOM_FLAGS=$(grep -rhlE "(FEATURE_FLAG_|ENABLE_|FF_|isFeatureEnabled|featureFlags)" src/ app/ lib/ 2>/dev/null | head -10)

if [ -n "$CUSTOM_FLAGS" ]; then
  FLAG_SYSTEM="${FLAG_SYSTEM:+$FLAG_SYSTEM, }Custom"
  FLAG_PATTERNS+=("FEATURE_FLAG_" "ENABLE_" "FF_" "isFeatureEnabled")
fi

if [ -n "$FLAG_SYSTEM" ]; then
  echo "Detected feature flag system(s): $FLAG_SYSTEM"
  echo ""

  # Search for active flags in codebase
  ACTIVE_FLAGS=""
  FLAG_COUNT=0

  for pattern in "${FLAG_PATTERNS[@]}"; do
    FOUND=$(grep -rhoE "${pattern}[A-Za-z0-9_-]+" src/ app/ lib/ 2>/dev/null | sort -u | head -20)
    if [ -n "$FOUND" ]; then
      ACTIVE_FLAGS+="$FOUND\n"
      FLAG_COUNT=$((FLAG_COUNT + $(echo "$FOUND" | wc -l)))
    fi
  done

  if [ "$FLAG_COUNT" -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚩 FEATURE FLAGS DETECTED ($FLAG_COUNT unique)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Active flags found:"
    echo -e "$ACTIVE_FLAGS" | sort -u | head -15 | while read -r flag; do
      [ -n "$flag" ] && echo "  • $flag"
    done
    echo ""
    echo "Recommendations:"
    echo "  1. Review flags related to this feature"
    echo "  2. Remove flags that are 100% rolled out"
    echo "  3. Update flag documentation"
    echo ""
    echo "Commands:"
    case "$FLAG_SYSTEM" in
      *LaunchDarkly*)
        echo "  ld flags list                   # List all flags"
        echo "  ld flags archive <flag-key>     # Archive obsolete flag"
        ;;
      *Unleash*)
        echo "  unleash flags list              # List all flags"
        echo "  unleash flags disable <name>    # Disable obsolete flag"
        ;;
      *)
        echo "  grep -r 'FEATURE_FLAG_' src/    # Find flag usages"
        echo "  # Remove flag checks after full rollout"
        ;;
    esac
    echo ""
    echo "Keeping stale flags increases tech debt."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo "✅ No active feature flags found in code"
  fi
else
  echo "⏭️  No feature flag system detected"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6.4: Check for Infrastructure Cleanup Needs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "Step 4: Checking infrastructure cleanup needs..."
echo ""

if [ -f .spec-flow/scripts/bash/detect-infrastructure-needs.sh ]; then
  FLAG_CLEANUP_NEEDED=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-cleanup 2>/dev/null | jq -r '.needed // false' 2>/dev/null)

  if [ "$FLAG_CLEANUP_NEEDED" = "true" ]; then
    ACTIVE_FLAGS=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-cleanup 2>/dev/null | jq -r '.active_flags[]' 2>/dev/null)
    FLAG_COUNT=$(echo "$ACTIVE_FLAGS" | wc -l)

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏗️  INFRASTRUCTURE CLEANUP NEEDED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Additional cleanup tasks:"
    echo ""

    while IFS= read -r flag; do
      if [ -n "$flag" ]; then
        echo "  /flag-cleanup $flag"
      fi
    done <<< "$ACTIVE_FLAGS"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo "✅ No additional infrastructure cleanup needed"
  fi
else
  echo "⏭️  Infrastructure detection script not found, skipping"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Final Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Essential Finalization Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: Full documentation finalization will run automatically."
echo ""

exit 0

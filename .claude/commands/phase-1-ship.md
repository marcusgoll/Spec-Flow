---
description: Ship feature to staging with auto-merge
---

Ship feature to staging.

## MENTAL MODEL

**Workflow**:\spec-flow → clarify → plan → tasks → analyze → implement → optimize → preview → **phase-1-ship** → validate-staging → phase-2-ship

**State machine:**
- Validate → Create PR → Enable auto-merge → Wait for CI → Report → Next

**Auto-suggest:**
- After auto-merge → `/validate-staging`
- If CI fails → `/checks pr [number]`

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
```

**Validate feature exists:**

```bash
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  exit 1
fi
```

**Validate on feature branch:**

```bash
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "staging" ]; then
  echo "❌ Cannot ship from $CURRENT_BRANCH branch"
  echo "phase-1-ship runs from feature branches only"
  echo ""
  echo "To promote staging → production: /phase-2-ship"
  exit 1
fi

echo "✅ Feature loaded: $SLUG"
echo "✅ Branch: $CURRENT_BRANCH"
echo ""
```

## PRE-FLIGHT VALIDATION

### Check Remote Repository

```bash
echo "Checking remote repository configuration..."
echo ""

# Check if remote origin exists
if ! git remote -v | grep -q "origin"; then
  echo "❌ No remote repository configured"
  echo ""
  echo "This command requires a remote repository with staging workflow."
  echo ""
  echo "Options:"
  echo "  1. Add remote repository:"
  echo "     git remote add origin <repository-url>"
  echo "     git push -u origin main"
  echo ""
  echo "  2. For local-only projects:"
  echo "     Use manual deployment (see /flow output for instructions)"
  echo ""
  echo "  3. Update project configuration:"
  echo "     See .spec-flow/memory/constitution.md"
  exit 1
fi

# Check if staging branch exists
if ! git show-ref --verify --quiet refs/heads/staging && \
   ! git show-ref --verify --quiet refs/remotes/origin/staging; then
  echo "❌ No 'staging' branch found"
  echo ""
  echo "Create staging branch for deployment workflow:"
  echo "  git checkout -b staging main"
  echo "  git push -u origin staging"
  echo ""
  echo "Or use direct-to-main workflow (skip staging):"
  echo "  git checkout main && git merge $SLUG"
  exit 1
fi

echo "✅ Remote repository configured"
echo "✅ Staging branch exists"
echo ""
```

### Check Clean Working Tree

```bash
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Uncommitted changes detected"
  echo "Commit or stash changes before shipping"
  exit 1
fi

echo "✅ Clean working tree"
echo ""
```

### Check Optimization Complete

```bash
echo "Validating optimization status..."
echo ""

# Check optimize ran
if ! grep -q "✅ Phase 5 (Optimize): Completed" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "❌ Optimization not complete"
  echo "Run /optimize before shipping"
  exit 1
fi

echo "✅ Optimization completed"

# Check for blockers in optimization report
if [ -f "$FEATURE_DIR/optimization-report.md" ]; then
  BLOCKERS=$(grep -c "❌ BLOCKER" "$FEATURE_DIR/optimization-report.md" || echo 0)
  CRITICAL=$(grep "Critical:" "$FEATURE_DIR/optimization-report.md" | grep -oE "[0-9]+" | head -1 || echo 0)

  if [ "$BLOCKERS" -gt 0 ]; then
    echo "❌ Found $BLOCKERS blocker(s) in optimization report"
    echo ""
    echo "Blockers:"
    grep "❌ BLOCKER" "$FEATURE_DIR/optimization-report.md" | sed 's/^/  /'
    echo ""
    echo "Fix blockers before shipping"
    exit 1
  fi

  if [ "$CRITICAL" -gt 0 ]; then
    echo "⚠️  Found $CRITICAL critical issue(s)"
    echo ""
    read -p "Ship with critical issues? (y/N): " SHIP_ANYWAY
    if [ "$SHIP_ANYWAY" != "y" ]; then
      echo "Cancelled. Fix issues first."
      exit 1
    fi
  fi

  echo "✅ No blocking issues"
else
  echo "⚠️  optimization-report.md not found"
  echo "Recommend running /optimize before shipping"
  echo ""
  read -p "Continue without optimization report? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    exit 1
  fi
fi

echo ""
```

### Run Pre-Flight Smoke Tests

```bash
echo "Running pre-flight smoke tests..."
echo ""

if [ -d "tests/smoke" ]; then
  # Frontend smoke tests
  if [ -d "apps/app" ]; then
    echo "Frontend smoke tests..."
    cd apps/app
    pnpm playwright test -g "@smoke" --headed=false
    FRONTEND_RESULT=$?
    cd ../..

    if [ $FRONTEND_RESULT -ne 0 ]; then
      echo "❌ Frontend smoke tests failed"
      echo ""
      read -p "Ship anyway? (y/N): " SHIP_ANYWAY
      if [ "$SHIP_ANYWAY" != "y" ]; then
        exit 1
      fi
    else
      echo "✅ Frontend smoke tests passed"
    fi
  fi

  # Backend smoke tests
  if [ -d "api" ]; then
    echo "Backend smoke tests..."
    cd api
    pytest -m smoke
    BACKEND_RESULT=$?
    cd ..

    if [ $BACKEND_RESULT -ne 0 ]; then
      echo "❌ Backend smoke tests failed"
      echo ""
      read -p "Ship anyway? (y/N): " SHIP_ANYWAY
      if [ "$SHIP_ANYWAY" != "y" ]; then
        exit 1
      fi
    else
      echo "✅ Backend smoke tests passed"
    fi
  fi

  echo ""
else
  echo "⚠️  No smoke tests found (tests/smoke/)"
  echo "Recommendation: Add smoke tests for critical flows"
  echo ""
fi
```

### Run Mandatory Preflight Check

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mandatory Pre-Flight Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Running preflight checks to catch deployment failures before CI..."
echo ""

# Check if preflight script exists
if [ ! -f ".spec-flow/scripts/bash/preflight-check.sh" ]; then
  echo "⚠️  Preflight script not found"
  echo "   Creating basic preflight check..."

  # Basic inline preflight for backward compatibility
  PREFLIGHT_FAILED=false

  # Check environment variables
  echo "Checking environment variables..."

  if [ -f ".env.example" ]; then
    REQUIRED_VARS=$(grep -v "^#" .env.example | grep "=" | cut -d= -f1)
    MISSING_COUNT=0

    for var in $REQUIRED_VARS; do
      if [ -z "${!var}" ] && [[ "$var" != *"PUBLIC"* ]]; then
        ((MISSING_COUNT++))
      fi
    done

    if [ "$MISSING_COUNT" -gt 0 ]; then
      echo "  ⚠️  $MISSING_COUNT environment variable(s) missing (will be set in CI)"
    else
      echo "  ✅ Environment variables present"
    fi
  fi

  echo ""
  echo "Testing production builds..."

  # Test marketing build
  if [ -d "apps/marketing" ]; then
    echo "Building marketing..."
    cd apps/marketing
    pnpm install --silent 2>/dev/null || true
    pnpm build >/tmp/preflight-marketing.log 2>&1
    MARKETING_BUILD=$?
    cd ../..

    if [ $MARKETING_BUILD -ne 0 ]; then
      echo "  ❌ Marketing build failed"
      tail -10 /tmp/preflight-marketing.log | grep -i "error" | head -5 | sed 's/^/    /'
      PREFLIGHT_FAILED=true
    else
      echo "  ✅ Marketing build succeeded"
    fi
  fi

  # Test app build
  if [ -d "apps/app" ]; then
    echo "Building app..."
    cd apps/app
    pnpm install --silent 2>/dev/null || true
    pnpm build >/tmp/preflight-app.log 2>&1
    APP_BUILD=$?
    cd ../..

    if [ $APP_BUILD -ne 0 ]; then
      echo "  ❌ App build failed"
      tail -10 /tmp/preflight-app.log | grep -i "error" | head -5 | sed 's/^/    /'
      PREFLIGHT_FAILED=true
    else
      echo "  ✅ App build succeeded"
    fi
  fi

  # Test API Docker build (if Dockerfile exists)
  if [ -f "api/Dockerfile" ] && command -v docker &>/dev/null; then
    echo "Testing API Docker build..."
    docker build -t api-preflight-test -f api/Dockerfile . >/tmp/preflight-docker.log 2>&1
    DOCKER_BUILD=$?

    if [ $DOCKER_BUILD -ne 0 ]; then
      echo "  ❌ Docker build failed"
      tail -10 /tmp/preflight-docker.log | sed 's/^/    /'
      PREFLIGHT_FAILED=true
    else
      echo "  ✅ Docker image builds"
      docker rmi api-preflight-test 2>/dev/null || true
    fi
  fi

  echo ""

  if [ "$PREFLIGHT_FAILED" = true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ PRE-FLIGHT FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Deployment blocked: Fix build errors before shipping"
    echo ""
    echo "Build logs:"
    echo "  - Marketing: /tmp/preflight-marketing.log"
    echo "  - App: /tmp/preflight-app.log"
    echo "  - Docker: /tmp/preflight-docker.log"
    echo ""
    echo "Fix issues and re-run /phase-1-ship"
    exit 1
  else
    echo "✅ Pre-flight checks passed"
  fi
else
  # Run full preflight script if available
  bash .spec-flow/scripts/bash/preflight-check.sh

  if [ $? -ne 0 ]; then
    echo "❌ Pre-flight validation failed"
    echo ""
    echo "Fix issues and re-run /phase-1-ship"
    exit 1
  fi

  echo "✅ Pre-flight checks passed"
fi

echo ""
```

### Check for Existing PR

```bash
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number,url -q '.[0]')

if [ -n "$EXISTING_PR" ]; then
  PR_NUMBER=$(echo "$EXISTING_PR" | yq eval '.number')
  PR_URL=$(echo "$EXISTING_PR" | yq eval '.url')

  echo "⚠️  PR already exists for this branch"
  echo "   #$PR_NUMBER: $PR_URL"
  echo ""
  echo "Options:"
  echo "  A) Use existing PR (skip to auto-merge)"
  echo "  B) Close and create new PR"
  echo "  C) Cancel"
  echo ""
  read -p "Choose (A/B/C): " OPTION

  case "$OPTION" in
    A|a)
      echo "Using existing PR #$PR_NUMBER"
      USE_EXISTING=true
      ;;
    B|b)
      echo "Closing PR #$PR_NUMBER..."
      gh pr close "$PR_NUMBER"
      echo "Creating new PR..."
      USE_EXISTING=false
      ;;
    *)
      echo "Cancelled"
      exit 0
      ;;
  esac

  echo ""
fi
```

## PRE-DEPLOYMENT CHECKS

### Check Deployment Budget

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pre-Deployment Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run deployment budget check
echo "Checking deployment quota..."
echo ""

# Count staging deployments (last 24 hours)
RECENT_DEPLOYS=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$(date -d '24 hours ago' -Iseconds 2>/dev/null || date -u -v-24H -Iseconds)" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)

QUOTA_REMAINING=$((100 - RECENT_DEPLOYS))

echo "Deployment quota (24h):"
echo "  Used: $RECENT_DEPLOYS / 100"
echo "  Remaining: $QUOTA_REMAINING"
echo ""

# Check if quota is critical
if [ "$QUOTA_REMAINING" -lt 5 ]; then
  echo "🚨 CRITICAL: Only $QUOTA_REMAINING deployments remaining"
  echo ""
  echo "Options:"
  echo "  A) Wait for quota reset (run /deployment-budget for details)"
  echo "  B) Use preview mode (doesn't count toward quota)"
  echo "  C) Continue with staging (not recommended)"
  echo ""
  read -p "Choose (A/B/C): " QUOTA_CHOICE

  case "$QUOTA_CHOICE" in
    A|a)
      echo "Cancelled. Run /deployment-budget for reset time."
      exit 0
      ;;
    B|b)
      echo "Forcing preview mode due to low quota"
      FORCE_PREVIEW=true
      ;;
    *)
      echo "⚠️  Proceeding with low quota (not recommended)"
      ;;
  esac

  echo ""
fi
```

---

### Run Environment Check

```bash
# Check environment variables for staging
echo "Validating environment variables..."
echo ""

if [ -f ".env.example" ]; then
  EXPECTED_VARS=$(grep -v "^#" .env.example | grep "=" | cut -d= -f1 | wc -l)
  echo "Expected variables: $EXPECTED_VARS"

  # Quick check for critical vars
  CRITICAL_VARS=(
    "NEXT_PUBLIC_API_URL"
    "DATABASE_URL"
    "CLERK_SECRET_KEY"
  )

  for var in "${CRITICAL_VARS[@]}"; do
    # Check if var exists in environment (will be set in CI)
    if [ -z "${!var}" ]; then
      echo "  ⚠️  $var not set locally (should be set in CI)"
    fi
  done

  echo ""
  echo "✅ Environment variables will be validated in CI"
  echo "   To validate now: /check-env staging"
  echo ""
else
  echo "⚠️  .env.example not found"
  echo ""
fi
```

---

## DEPLOYMENT MODE SELECTION

**Select deployment mode based on quota:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Mode Selection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determine default mode based on quota
if [ "$FORCE_PREVIEW" = true ]; then
  DEFAULT_MODE="preview"
  echo "Mode: preview (forced due to low quota)"
  echo ""
elif [ "$QUOTA_REMAINING" -lt 20 ]; then
  DEFAULT_MODE="preview"
  echo "⚠️  LOW QUOTA: $QUOTA_REMAINING deployments remaining"
  echo "   Defaulting to preview mode (unlimited)"
elif [ "$QUOTA_REMAINING" -lt 50 ]; then
  DEFAULT_MODE="preview"
  echo "⚠️  MEDIUM QUOTA: $QUOTA_REMAINING deployments remaining"
  echo "   Defaulting to preview mode (recommended)"
else
  DEFAULT_MODE="staging"
  echo "✅ NORMAL QUOTA: $QUOTA_REMAINING deployments remaining"
  echo "   Defaulting to staging mode"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Mode Options"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. preview"
echo "   - Tests deployment workflow"
echo "   - Does NOT update staging.cfipros.com"
echo "   - Unlimited quota (doesn't count toward 100/day)"
echo "   - Use for: CI testing, workflow debugging"
echo ""
echo "2. staging"
echo "   - Updates staging.cfipros.com"
echo "   - Uses production quota (counts toward 100/day)"
echo "   - Use for: Actual staging deployment"
echo ""
echo "3. skip"
echo "   - Creates PR without triggering any deployment"
echo "   - Manual workflow trigger required"
echo "   - Use for: Draft PRs, work in progress"
echo ""

read -p "Select mode [$DEFAULT_MODE]: " SELECTED_MODE
DEPLOYMENT_MODE="${SELECTED_MODE:-$DEFAULT_MODE}"

echo ""

case "$DEPLOYMENT_MODE" in
  preview)
    echo "✅ Preview mode selected"
    echo "   - CI testing only"
    echo "   - No staging domain update"
    echo "   - Quota: Unlimited"
    ;;
  staging)
    echo "✅ Staging mode selected"
    echo "   - Will update staging.cfipros.com"
    echo "   - Uses 2 deployments (marketing + app)"
    echo "   - Remaining after: $((QUOTA_REMAINING - 2))"
    ;;
  skip)
    echo "✅ Skip mode selected"
    echo "   - PR created without deployment"
    ;;
  *)
    echo "❌ Invalid mode: $DEPLOYMENT_MODE"
    exit 1
    ;;
esac

echo ""
```

**Rate limit prevention checklist:**

- [ ] Run `pnpm run ci:validate` locally before shipping (0 deployments)
- [ ] Use preview mode for CI testing and workflow debugging
- [ ] Reserve staging mode for actual staging deployment
- [ ] Reference: `docs/CI-CD-GUIDE.md` (CI Debugging Without Burning Deployments)

## LOAD METADATA

```bash
if [ "$USE_EXISTING" != true ]; then
  # Extract feature info from spec.md
  TITLE=$(grep "^# " "$FEATURE_DIR/spec.md" | head -1 | sed 's/^# //')
  SUMMARY=$(sed -n '/## Summary/,/^## /p' "$FEATURE_DIR/spec.md" | grep -v "^## ")

  # Load optimization results
  if [ -f "$FEATURE_DIR/optimization-report.md" ]; then
    OPT_PERF=$(grep "Backend p95:" "$FEATURE_DIR/optimization-report.md" | head -1)
    OPT_SECURITY=$(grep "Critical vulnerabilities:" "$FEATURE_DIR/optimization-report.md" | head -1)
    OPT_A11Y=$(grep "WCAG level:" "$FEATURE_DIR/optimization-report.md" | head -1)
  else
    OPT_PERF="Performance: Not validated"
    OPT_SECURITY="Security: Not validated"
    OPT_A11Y="A11y: Not validated"
  fi
fi
```

## CREATE PULL REQUEST

**Generate PR body:**

```bash
if [ "$USE_EXISTING" != true ]; then
  cat > /tmp/pr-body-$SLUG.md <<EOF
## 🚀 Phase 1: Merge to Main (Deploy to Staging)

**Feature**: $TITLE

### Summary

$SUMMARY

### Optimization Results

- $OPT_PERF
- $OPT_SECURITY
- $OPT_A11Y

### Deployment Mode

**Mode**: $DEPLOYMENT_MODE

$(if [ "$DEPLOYMENT_MODE" = "staging" ]; then
  echo "After merge to **main**, automatically deploys to **staging environment**:"
  echo "- Marketing: https://staging.cfipros.com"
  echo "- App: https://app.staging.cfipros.com"
  echo "- API: https://api.staging.cfipros.com"
elif [ "$DEPLOYMENT_MODE" = "preview" ]; then
  echo "Preview mode: Tests deployment workflow without updating staging domain"
  echo "- CI testing only"
  echo "- Does not count toward production quota"
else
  echo "Skip mode: PR created without triggering deployment"
fi)

### CI/CD Checks

Auto-merge enabled. PR merges automatically when:
- ✅ Deploy to staging succeeds (if staging mode)
- ✅ Smoke tests pass
- ✅ Lighthouse CI passes (Performance ≥90, A11y ≥95)
- ✅ E2E tests pass

### Next Steps

1. ✅ Auto-merge to main when checks pass
2. Manual validation: \`/validate-staging\`
3. Production: \`/phase-2-ship\`

---
🤖 Generated with [Claude Code](https://claude.ai/claude-code)
EOF
fi
```

**Push branch and create PR:**

```bash
if [ "$USE_EXISTING" != true ]; then
  # Push branch
  echo "Pushing branch to origin..."
  git push -u origin "$CURRENT_BRANCH"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to push branch"
    exit 1
  fi

  echo "✅ Branch pushed"
  echo ""

  # Create PR
  echo "Creating pull request..."

  gh pr create \
    --title "feat: $TITLE" \
    --body-file /tmp/pr-body-$SLUG.md \
    --base main \
    --head "$CURRENT_BRANCH"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to create PR"
    echo ""
    echo "Branch pushed but PR creation failed"
    echo "Options:"
    echo "  A) Retry PR creation: gh pr create --base main --head $CURRENT_BRANCH"
    echo "  B) Create manually: https://github.com/cfipros/monorepo/compare/main...$CURRENT_BRANCH"
    echo "  C) Delete remote branch: git push origin --delete $CURRENT_BRANCH"
    exit 1
  fi

  # Get PR details
  PR_NUMBER=$(gh pr view --json number -q .number)
  PR_URL=$(gh pr view --json url -q .url)

  echo "✅ PR created: #$PR_NUMBER"
  echo "   URL: $PR_URL"
  echo ""

  # Cleanup
  rm /tmp/pr-body-$SLUG.md
fi
```

**Set deployment mode via PR label:**

```bash
case "$DEPLOYMENT_MODE" in
  preview)
    gh pr edit "$PR_NUMBER" --add-label "deploy:preview" 2>/dev/null || true
    ;;
  staging)
    gh pr edit "$PR_NUMBER" --add-label "deploy:staging" 2>/dev/null || true
    ;;
  skip)
    gh pr edit "$PR_NUMBER" --add-label "deploy:skip" 2>/dev/null || true
    ;;
esac

echo "✅ Deployment mode set: $DEPLOYMENT_MODE"
echo ""
```

## WAIT FOR REQUIRED CHECKS TO REGISTER

**Ensure all critical checks are registered before enabling auto-merge:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Waiting for Required CI Checks to Register"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Ensuring all critical checks start before enabling auto-merge..."
echo "This prevents race conditions where auto-merge triggers before checks complete."
echo ""

# Define required checks based on deployment mode
REQUIRED_CHECKS=()

# Common checks for all modes
REQUIRED_CHECKS+=("Lint")
REQUIRED_CHECKS+=("Type Check")
REQUIRED_CHECKS+=("Test")

# Deployment-specific checks
if [ "$DEPLOYMENT_MODE" = "staging" ] || [ "$DEPLOYMENT_MODE" = "preview" ]; then
  REQUIRED_CHECKS+=("Build")
  REQUIRED_CHECKS+=("Verify Build Artifacts")
  REQUIRED_CHECKS+=("Deploy to Staging")
fi

echo "Required checks (${#REQUIRED_CHECKS[@]} total):"
for check in "${REQUIRED_CHECKS[@]}"; do
  echo "  - $check"
done
echo ""

# Poll for checks to register
REGISTRATION_TIMEOUT=300  # 5 minutes
REGISTRATION_ELAPSED=0
POLL_INTERVAL=10
ALL_REGISTERED=false

echo "Polling for check registration..."
echo ""

while [ $REGISTRATION_ELAPSED -lt $REGISTRATION_TIMEOUT ]; do
  # Get current checks
  CURRENT_CHECKS=$(gh pr checks "$PR_NUMBER" --json name -q '.[].name' 2>/dev/null || echo "")

  if [ -z "$CURRENT_CHECKS" ]; then
    echo "[$(date +%H:%M:%S)] No checks registered yet. Waiting..."
  else
    # Count how many required checks are registered
    REGISTERED_COUNT=0

    for required in "${REQUIRED_CHECKS[@]}"; do
      if echo "$CURRENT_CHECKS" | grep -qi "$required"; then
        ((REGISTERED_COUNT++))
      fi
    done

    echo "[$(date +%H:%M:%S)] Registered: $REGISTERED_COUNT / ${#REQUIRED_CHECKS[@]}"

    # Check if all required checks are registered
    if [ "$REGISTERED_COUNT" -eq "${#REQUIRED_CHECKS[@]}" ]; then
      echo ""
      echo "✅ All required checks registered!"
      echo ""

      # Show registered checks
      echo "Registered checks:"
      echo "$CURRENT_CHECKS" | sed 's/^/  - /'
      echo ""

      ALL_REGISTERED=true
      break
    fi
  fi

  # Wait before next poll
  sleep $POLL_INTERVAL
  REGISTRATION_ELAPSED=$((REGISTRATION_ELAPSED + POLL_INTERVAL))
done

if [ "$ALL_REGISTERED" != true ]; then
  echo ""
  echo "⏱️  Timeout: Required checks did not register within 5 minutes"
  echo ""

  if [ -n "$CURRENT_CHECKS" ]; then
    echo "Checks that registered:"
    echo "$CURRENT_CHECKS" | sed 's/^/  - /'
    echo ""
  fi

  echo "This may indicate:"
  echo "  - CI workflow configuration issues"
  echo "  - GitHub Actions not triggering"
  echo "  - Branch protection rules missing"
  echo ""
  echo "Check CI configuration and try again"

  read -p "Continue anyway? (y/N): " FORCE_CONTINUE
  if [ "$FORCE_CONTINUE" != "y" ]; then
    exit 1
  fi

  echo ""
  echo "⚠️  Proceeding without full check registration (not recommended)"
else
  echo "Safe to enable auto-merge (all checks running)"
fi

echo ""
```

## ENABLE AUTO-MERGE

**Enable auto-merge via GitHub CLI:**

```bash
echo "Enabling auto-merge on PR #$PR_NUMBER..."

gh pr merge "$PR_NUMBER" \
  --auto \
  --squash \
  --delete-branch

if [ $? -eq 0 ]; then
  echo "✅ Auto-merge enabled"
  echo "   PR will merge automatically when all checks pass"
  echo ""
else
  echo "⚠️  Auto-merge failed"
  echo "   PR will require manual merge"
  echo ""
fi
```

## WAIT FOR CI CHECKS

**Poll for CI completion:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Waiting for CI checks to complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "PR: $PR_URL"
echo ""
echo "Polling every 30s (max 20 minutes)..."
echo ""

TIMEOUT=1200  # 20 minutes
ELAPSED=0
POLL_INTERVAL=30
CI_PASSED=false

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Get check status
  CHECK_STATUS=$(gh pr checks "$PR_NUMBER" --json state -q '.[].state' | sort -u)

  # Count status types
  PENDING=$(echo "$CHECK_STATUS" | grep -c "PENDING" || echo 0)
  SUCCESS=$(echo "$CHECK_STATUS" | grep -c "SUCCESS" || echo 0)
  FAILURE=$(echo "$CHECK_STATUS" | grep -c "FAILURE" || echo 0)

  TOTAL_CHECKS=$(echo "$CHECK_STATUS" | wc -l)

  echo "[$(date +%H:%M:%S)] Status: $SUCCESS/$TOTAL_CHECKS passed, $PENDING pending, $FAILURE failed"

  # Check if all passed
  if [ "$PENDING" -eq 0 ] && [ "$FAILURE" -eq 0 ] && [ "$SUCCESS" -gt 0 ]; then
    echo ""
    echo "✅ All CI checks passed!"
    echo ""

    # Check if auto-merge completed
    PR_STATE=$(gh pr view "$PR_NUMBER" --json state -q .state)

    if [ "$PR_STATE" = "MERGED" ]; then
      echo "✅ PR auto-merged to main"
      echo ""
      CI_PASSED=true
      break
    else
      echo "⏳ Waiting for auto-merge..."
    fi
  fi

  # Check if any failed
  if [ "$FAILURE" -gt 0 ]; then
    echo ""
    echo "❌ CI checks failed"
    echo ""

    # Show failed checks
    gh pr checks "$PR_NUMBER" --json name,state -q '.[] | select(.state=="FAILURE") | .name' | \
      sed 's/^/  ❌ /'

    echo ""
    echo "Next: /checks pr $PR_NUMBER (debug failures)"
    exit 1
  fi

  # Wait before next poll
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

if [ "$CI_PASSED" != true ]; then
  echo ""
  echo "⏱️  Timeout: CI checks taking >20 minutes"
  echo "Check manually: $PR_URL"
  exit 1
fi
```

## VERIFY BUILD ARTIFACTS

**Verify that builds actually succeeded and artifacts were created:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verifying Build Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Ensuring builds succeeded and artifacts were created..."
echo ""

ARTIFACTS_VALID=true

# Find the workflow run for the merged commit
MERGE_COMMIT=$(git rev-parse origin/main)
echo "Merged commit: $(git rev-parse --short $MERGE_COMMIT)"
echo ""

# Get the "Verify Build Artifacts" check specifically
echo "Checking 'Verify Build Artifacts' status..."
VERIFY_CHECK=$(gh pr checks "$PR_NUMBER" --json name,conclusion -q '.[] | select(.name | test("Verify.*Build.*Artifacts"; "i"))' 2>/dev/null)

if [ -n "$VERIFY_CHECK" ]; then
  VERIFY_CONCLUSION=$(echo "$VERIFY_CHECK" | jq -r '.conclusion')

  if [ "$VERIFY_CONCLUSION" = "SUCCESS" ]; then
    echo "  ✅ Verify Build Artifacts: PASSED"
  else
    echo "  ❌ Verify Build Artifacts: $VERIFY_CONCLUSION"
    ARTIFACTS_VALID=false
  fi
else
  echo "  ⚠️  Verify Build Artifacts check not found"
  echo "     This check should validate:"
  echo "       - Build outputs exist"
  echo "       - No build warnings"
  echo "       - Bundle sizes acceptable"
  echo ""

  # Fallback: Check if Build check passed
  BUILD_CHECK=$(gh pr checks "$PR_NUMBER" --json name,conclusion -q '.[] | select(.name | test("Build"; "i"))' | head -1 2>/dev/null)

  if [ -n "$BUILD_CHECK" ]; then
    BUILD_CONCLUSION=$(echo "$BUILD_CHECK" | jq -r '.conclusion')

    if [ "$BUILD_CONCLUSION" = "SUCCESS" ]; then
      echo "  ✅ Build check: PASSED (artifact validation unavailable)"
    else
      echo "  ❌ Build check: $BUILD_CONCLUSION"
      ARTIFACTS_VALID=false
    fi
  else
    echo "  ⚠️  No build validation checks found"
    ARTIFACTS_VALID=false
  fi
fi

echo ""

# Additional validation: Check for deployment artifacts in workflow logs if in staging/preview mode
if [ "$DEPLOYMENT_MODE" = "staging" ] || [ "$DEPLOYMENT_MODE" = "preview" ]; then
  echo "Checking deployment workflow..."

  # Find deploy workflow run
  DEPLOY_RUN=$(gh run list \
    --workflow=deploy-staging.yml \
    --branch=main \
    --limit=5 \
    --json databaseId,headSha,conclusion \
    --jq ".[] | select(.headSha==\"$MERGE_COMMIT\") | .databaseId" 2>/dev/null | head -1)

  if [ -n "$DEPLOY_RUN" ]; then
    echo "  Found deployment run: #$DEPLOY_RUN"

    # Get workflow conclusion
    DEPLOY_CONCLUSION=$(gh run view "$DEPLOY_RUN" --json conclusion -q '.conclusion' 2>/dev/null)

    if [ "$DEPLOY_CONCLUSION" = "success" ]; then
      echo "  ✅ Deployment workflow: SUCCESS"

      # Quick scan of logs for error indicators
      echo "  Scanning logs for errors..."
      DEPLOY_LOGS=$(gh run view "$DEPLOY_RUN" --log 2>/dev/null || echo "")

      ERROR_COUNT=$(echo "$DEPLOY_LOGS" | grep -ci "error\|failed\|fatal" || echo 0)

      if [ "$ERROR_COUNT" -gt 10 ]; then
        echo "  ⚠️  Found $ERROR_COUNT error mentions in logs (may be normal)"
      else
        echo "  ✅ No major errors in deployment logs"
      fi
    elif [ "$DEPLOY_CONCLUSION" = "failure" ]; then
      echo "  ❌ Deployment workflow: FAILED"
      ARTIFACTS_VALID=false

      # Get failure details
      echo ""
      echo "Failed jobs:"
      gh run view "$DEPLOY_RUN" --json jobs -q '.jobs[] | select(.conclusion=="failure") | "  - \(.name)"' 2>/dev/null
      echo ""
    else
      echo "  ⏳ Deployment workflow: $DEPLOY_CONCLUSION"
    fi
  else
    echo "  ⚠️  Deployment workflow not found yet"
    echo "     Deployments may still be in progress"
  fi

  echo ""
fi

if [ "$ARTIFACTS_VALID" != true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ ARTIFACT VERIFICATION FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Build artifacts are missing or invalid!"
  echo ""
  echo "This indicates:"
  echo "  - Builds may have reported success but produced no output"
  echo "  - Artifact validation check failed"
  echo "  - Deployment workflow failed"
  echo ""
  echo "⚠️  CRITICAL: This PR merged but may not be deployable!"
  echo ""
  echo "Recommended actions:"
  echo "  1. Check workflow logs: gh run view $DEPLOY_RUN --log"
  echo "  2. Verify build outputs exist in deployment"
  echo "  3. Consider reverting merge if artifacts invalid:"
  echo "     git revert -m 1 $MERGE_COMMIT"
  echo "     git push origin main"
  echo ""

  read -p "Continue despite artifact validation failure? (y/N): " CONTINUE_ANYWAY
  if [ "$CONTINUE_ANYWAY" != "y" ]; then
    echo ""
    echo "Stopping. Fix build artifacts before proceeding to validation."
    exit 1
  fi

  echo ""
  echo "⚠️  Proceeding with unverified artifacts (HIGH RISK)"
else
  echo "✅ Build artifacts verified"
fi

echo ""
```

## EXTRACT DEPLOYMENT IDS (FIX #3: Deployment ID Verification)

**Parse workflow logs to extract deployment IDs for rollback:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Extracting Deployment IDs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find the staging deployment workflow run
STAGING_RUN=$(gh run list \
  --workflow=deploy-staging.yml \
  --branch=main \
  --limit=5 \
  --json databaseId,headSha,conclusion \
  --jq ".[] | select(.headSha==\"$(git rev-parse origin/main)\") | .databaseId" | head -1)

if [ -z "$STAGING_RUN" ]; then
  echo "⚠️  Could not find staging deployment run"
  echo "   Deployment IDs will need to be extracted manually"
  echo ""

  MARKETING_ID=""
  APP_ID=""
  API_IMAGE=""
else
  echo "Found staging deployment: Run #$STAGING_RUN"
  echo "Extracting deployment IDs from logs..."
  echo ""

  # Get workflow logs
  DEPLOY_LOGS=$(gh run view "$STAGING_RUN" --log 2>/dev/null || echo "")

  if [ -z "$DEPLOY_LOGS" ]; then
    echo "⚠️  Could not fetch workflow logs"
    MARKETING_ID=""
    APP_ID=""
    API_IMAGE=""
  else
    # Extract Vercel deployment IDs
    # Pattern: marketing-abc123.vercel.app or https://marketing-abc123.vercel.app
    MARKETING_ID=$(echo "$DEPLOY_LOGS" | grep -oE "(https://)?[a-z]+-marketing-[a-z0-9]+\.vercel\.app" | sed 's|https://||' | head -1 || echo "")

    # Pattern: app-abc123.vercel.app or https://app-abc123.vercel.app
    APP_ID=$(echo "$DEPLOY_LOGS" | grep -oE "(https://)?app-[a-z0-9-]+\.vercel\.app" | sed 's|https://||' | head -1 || echo "")

    # Extract Railway/Docker image
    # Pattern: ghcr.io/org/api:sha123 or ghcr.io/org/api:abc123def456
    API_IMAGE=$(echo "$DEPLOY_LOGS" | grep -oE "ghcr\.io/[^/]+/[^:]+:[a-f0-9]{7,40}" | head -1 || echo "")

    echo "Extracted IDs:"
    echo "  Marketing: ${MARKETING_ID:-[not found]}"
    echo "  App: ${APP_ID:-[not found]}"
    echo "  API: ${API_IMAGE:-[not found]}"
    echo ""
  fi
fi

# Verify we got all required IDs
MISSING_IDS=()
[ -z "$MARKETING_ID" ] && MISSING_IDS+=("marketing")
[ -z "$APP_ID" ] && MISSING_IDS+=("app")
[ -z "$API_IMAGE" ] && MISSING_IDS+=("API")

if [ ${#MISSING_IDS[@]} -gt 0 ]; then
  echo "⚠️  Missing deployment IDs: ${MISSING_IDS[*]}"
  echo ""
  echo "Rollback information incomplete. Manual extraction required:"
  echo "  1. View workflow logs: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$STAGING_RUN"
  echo "  2. Search logs for deployment URLs"
  echo "  3. Record IDs in workflow-state.yaml manually"
  echo ""
  echo "⚠️  Continuing with incomplete rollback metadata"
  echo ""
else
  echo "✅ All deployment IDs captured"
  echo ""

  # Store in workflow state if state management is available
  if [ -f ".spec-flow/scripts/bash/workflow-state.sh" ]; then
    source .spec-flow/scripts/bash/workflow-state.sh

    # Update deployment state
    update_deployment_state "$FEATURE_DIR" "staging" "$(git rev-parse origin/main)" "$STAGING_RUN"
    update_deployment_ids "$FEATURE_DIR" "staging" "$MARKETING_ID" "$APP_ID" "$API_IMAGE"

    echo "✅ Deployment IDs saved to workflow-state.yaml"
    echo ""
  fi

  # Store in separate JSON file for easy rollback reference
  cat > "$FEATURE_DIR/deployment-metadata.json" <<EOF
{
  "staging": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "commit_sha": "$(git rev-parse origin/main)",
    "run_id": "$STAGING_RUN",
    "pr_number": "$PR_NUMBER",
    "deployments": {
      "marketing": "$MARKETING_ID",
      "app": "$APP_ID",
      "api": "$API_IMAGE"
    },
    "urls": {
      "marketing": "https://staging.cfipros.com",
      "app": "https://app.staging.cfipros.com",
      "api": "https://api.staging.cfipros.com"
    }
  }
}
EOF

  echo "✅ Rollback metadata saved: $FEATURE_DIR/deployment-metadata.json"
  echo ""
fi
```

---

## VERIFY STAGING DEPLOYMENT HEALTH

**Validate that staging deployment is actually working:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Staging Deployment Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$DEPLOYMENT_MODE" != "staging" ]; then
  echo "Skipping health checks (deployment mode: $DEPLOYMENT_MODE)"
  echo ""
else
  echo "Waiting for staging deployment to become healthy..."
  echo ""

  # Define staging URLs (customize for your project)
  STAGING_MARKETING="https://staging.cfipros.com"
  STAGING_APP="https://app.staging.cfipros.com"
  STAGING_API="https://api.staging.cfipros.com/api/v1/health/healthz"

  # Wait for DNS propagation and deployment
  echo "Waiting 2 minutes for deployment propagation..."
  sleep 120

  HEALTH_PASSED=true
  HEALTH_CHECKS_DONE=0
  HEALTH_CHECKS_PASSED=0

  # Check marketing site
  echo "Checking marketing site..."
  ((HEALTH_CHECKS_DONE++))

  if curl -sf --max-time 10 "$STAGING_MARKETING" > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$STAGING_MARKETING" 2>/dev/null)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
      echo "  ✅ Marketing: $HTTP_CODE"
      ((HEALTH_CHECKS_PASSED++))
    else
      echo "  ❌ Marketing: HTTP $HTTP_CODE (expected 200)"
      HEALTH_PASSED=false
    fi
  else
    echo "  ❌ Marketing: Not responding"
    echo "     URL: $STAGING_MARKETING"
    HEALTH_PASSED=false
  fi

  # Check app
  echo "Checking app..."
  ((HEALTH_CHECKS_DONE++))

  if curl -sf --max-time 10 "$STAGING_APP" > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$STAGING_APP" 2>/dev/null)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
      echo "  ✅ App: $HTTP_CODE"
      ((HEALTH_CHECKS_PASSED++))
    else
      echo "  ❌ App: HTTP $HTTP_CODE (expected 200)"
      HEALTH_PASSED=false
    fi
  else
    echo "  ❌ App: Not responding"
    echo "     URL: $STAGING_APP"
    HEALTH_PASSED=false
  fi

  # Check API health endpoint
  echo "Checking API health..."
  ((HEALTH_CHECKS_DONE++))

  if curl -sf --max-time 10 "$STAGING_API" 2>/dev/null | grep -qi "healthy\|ok\|status.*ok"; then
    echo "  ✅ API: Healthy"
    ((HEALTH_CHECKS_PASSED++))
  else
    echo "  ❌ API: Health check failed"
    echo "     URL: $STAGING_API"
    HEALTH_PASSED=false
  fi

  # Check for immediate errors (first 60 seconds of logs)
  if [ -n "$DEPLOY_RUN" ]; then
    echo ""
    echo "Checking for immediate errors in logs..."

    # Wait a bit more for logs to populate
    sleep 15

    # Get recent logs
    RECENT_LOGS=$(gh run view "$DEPLOY_RUN" --log 2>/dev/null | tail -100 || echo "")

    # Count critical errors
    CRITICAL_ERRORS=$(echo "$RECENT_LOGS" | grep -ci "error\|exception\|fatal\|crashed" || echo 0)

    if [ "$CRITICAL_ERRORS" -gt 5 ]; then
      echo "  ⚠️  Found $CRITICAL_ERRORS critical error mentions in recent logs"
      echo "     Review logs: gh run view $DEPLOY_RUN --log"
      HEALTH_PASSED=false
    else
      echo "  ✅ No critical errors in initial logs"
    fi
  fi

  echo ""
  echo "Health check results: $HEALTH_CHECKS_PASSED / $HEALTH_CHECKS_DONE passed"
  echo ""

  if [ "$HEALTH_PASSED" != true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ STAGING HEALTH CHECK FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Staging deployment is not healthy!"
    echo ""
    echo "Failed checks:"
    echo "  - Marketing responding: $([[ "$STAGING_MARKETING" == *"200"* ]] && echo "✅" || echo "❌")"
    echo "  - App responding: $([[ "$STAGING_APP" == *"200"* ]] && echo "✅" || echo "❌")"
    echo "  - API health: $([[ "$STAGING_API" == *"healthy"* ]] && echo "✅" || echo "❌")"
    echo ""
    echo "⚠️  CRITICAL: Staging deployment may be broken!"
    echo ""
    echo "Recommended actions:"
    echo "  1. Check deployment logs: gh run view $DEPLOY_RUN --log"
    echo "  2. Test URLs manually:"
    echo "     - $STAGING_MARKETING"
    echo "     - $STAGING_APP"
    echo "     - $STAGING_API"
    echo "  3. Revert if broken:"
    echo "     git revert -m 1 $MERGE_COMMIT"
    echo "     git push origin main"
    echo ""

    read -p "Continue despite health check failure? (y/N): " CONTINUE_UNHEALTHY
    if [ "$CONTINUE_UNHEALTHY" != "y" ]; then
      echo ""
      echo "Stopping. Fix staging health before proceeding."
      echo ""
      echo "Next steps:"
      echo "  1. Debug staging deployment"
      echo "  2. Revert merge if necessary"
      echo "  3. Fix issues on feature branch"
      echo "  4. Re-run /phase-1-ship"
      exit 1
    fi

    echo ""
    echo "⚠️  Proceeding with unhealthy deployment (HIGH RISK)"
  else
    echo "✅ Staging deployment is healthy"
  fi
fi

echo ""
```

---

## CREATE STAGING SHIP REPORT

**Generate report with deployment metadata:**

```bash
cat > "$FEATURE_DIR/staging-ship-report.md" <<EOF
# Staging Deployment Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Feature**: $TITLE
**PR**: #$PR_NUMBER ($PR_URL)
**Branch**: $CURRENT_BRANCH → main

---

## Deployment

**Status**: ✅ Merged to main, deployed to staging
**Mode**: $DEPLOYMENT_MODE

**Staging URLs**:
- Marketing: https://staging.cfipros.com
- App: https://app.staging.cfipros.com
- API: https://api.staging.cfipros.com

**Deployment IDs** (for rollback):
- Marketing: ${MARKETING_ID:-[Extraction failed - see logs]}
- App: ${APP_ID:-[Extraction failed - see logs]}
- API: ${API_IMAGE:-[Extraction failed - see logs]}

**Rollback metadata**: $FEATURE_DIR/deployment-metadata.json
**GitHub Actions logs**: $PR_URL/checks

---

## CI/CD Results

**Auto-merge**: ✅ Enabled
**Merged at**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**CI duration**: $((ELAPSED / 60)) minutes

### Checks Passed

$(gh pr checks "$PR_NUMBER" --json name,state -q '.[] | "- ✅ \(.name)"')

---

## Optimization Summary

$(if [ -f "$FEATURE_DIR/optimization-report.md" ]; then
  sed -n '/## Performance/,/## Security/p' "$FEATURE_DIR/optimization-report.md" | head -n -1
else
  echo "No optimization report available"
fi)

---

## Next Steps

1. **Wait for deployment**: ~5-10 minutes for staging deployment to complete
2. **Manual validation**: Run \`/validate-staging\` to test feature in staging
3. **Production deploy**: After validation passes, run \`/phase-2-ship\`

---

## Rollback Information

**If deployment fails or issues found:**

\`\`\`bash
# Get deploy IDs from GitHub Actions logs
# Then rollback using 3-command procedure (see runbook/rollback.md)

# 1. Revert merge commit
git revert -m 1 <merge-commit-sha>
git push origin main

# 2. Set Vercel alias to previous deploy
vercel alias set <previous-deploy-id> staging.cfipros.com

# 3. Update Railway API image
railway service update --image ghcr.io/.../api:<previous-sha>
\`\`\`

---
Generated by \`/phase-1-ship\` at $(date -Iseconds)
EOF

echo "✅ Staging ship report created"
echo "   Location: $FEATURE_DIR/staging-ship-report.md"
echo ""
```

## UPDATE NOTES.MD

**Add phase checkpoint with deployment metadata:**

```bash
# Source the template
source \spec-flow/templates/notes-update-template.sh

# Add Phase 7 checkpoint
update_notes_checkpoint "$FEATURE_DIR" "7" "Ship to Staging" \
  "PR: #$PR_NUMBER" \
  "Branch: $CURRENT_BRANCH → main" \
  "Auto-merge: Enabled" \
  "CI duration: $((ELAPSED / 60)) minutes" \
  "Deployment mode: $DEPLOYMENT_MODE" \
  "Merged at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"

# Add Deployment Metadata section (custom section, not part of template)
cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Deployment Metadata

**Staging Deploy** ($(date -u +"%Y-%m-%d")):

| Service | Deploy ID | Status |
|---------|-----------|--------|
| Marketing | [See GitHub Actions] | Deployed |
| App | [See GitHub Actions] | Deployed |
| API | [See GitHub Actions] | Deployed |

**Staging URLs**:
- Marketing: https://staging.cfipros.com
- App: https://app.staging.cfipros.com
- API: https://api.staging.cfipros.com

**GitHub Actions Logs**: $PR_URL/checks

**Rollback Commands** (if needed):
\`\`\`bash
# See runbook/rollback.md for full procedure
git revert -m 1 <merge-commit-sha>
vercel alias set <previous-deploy-id> staging.cfipros.com
railway service update --image ghcr.io/.../api:<previous-sha>
\`\`\`
EOF

update_notes_timestamp "$FEATURE_DIR"

echo "✅ NOTES.md updated with deployment metadata"
echo ""
```

## GIT COMMIT

```bash
git add "$FEATURE_DIR/"
git commit -m "integration:ship-staging: merge to main, deploy to staging

PR: #$PR_NUMBER
Auto-merge: Enabled
CI checks: Passed ($((ELAPSED / 60)) minutes)
Merged to: main
Deployment mode: $DEPLOYMENT_MODE
Deployed to: staging.cfipros.com

Next: Manual validation via /validate-staging

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin "$CURRENT_BRANCH"
```

## RETURN

Brief summary:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase 1: Feature → Staging Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: $TITLE
PR: #$PR_NUMBER
URL: $PR_URL

Status:
✅ Auto-merge enabled
✅ CI checks passed ($((ELAPSED / 60)) minutes)
✅ Merged to main
✅ Deployed to staging

Staging URLs:
🌐 Marketing: https://staging.cfipros.com
🌐 App: https://app.staging.cfipros.com
🌐 API: https://api.staging.cfipros.com

Reports:
📋 Ship report: $FEATURE_DIR/staging-ship-report.md
📊 Deployment logs: $PR_URL/checks

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏳ Wait for Deployment (~5-10 minutes)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Staging deployment in progress. Wait for:
- Vercel deployments to complete
- Railway API to restart
- DNS propagation (if needed)

Check status: $PR_URL/checks

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT: /validate-staging
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/validate-staging will:
1. Test feature in staging environment
2. Run manual QA checklist
3. Verify all user flows work
4. Check for regressions
5. Generate validation report

After validation passes:
→ /phase-2-ship (promote staging → production)

If issues found:
→ Fix on feature branch, /phase-1-ship again
```


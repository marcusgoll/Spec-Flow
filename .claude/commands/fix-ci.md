---
description: Fix CI/deployment blockers after /ship creates PR
---

Get PR ready for deployment: $ARGUMENTS

## MENTAL MODEL

**Mission:** Deployment doctor - diagnose → fix → delegate → validate

**What this does**:
- Reads PR context (checks, files, reviews, logs)
- Categorizes blockers (lint, types, tests, build, deploy, smoke)
- Auto-fixes simple issues (lint, format)
- Delegates complex issues to specialist agents
- Posts progress updates to PR
- Validates deployment readiness

**State awareness:**
- Feature branch → Staging readiness (Phase 1 gate)
- Main branch → Production readiness (Phase 2 gate)
- Auto-detect context from PR base branch

**Deployment mode awareness:**
- **Preview mode**: For CI testing, debugging workflows (unlimited quota)
- **Staging mode**: Updates custom domain staging.cfipros.com (production quota)
- Default workflow triggers to preview mode to prevent rate limit burns
- Only use staging mode when explicitly deploying to staging environment

**Progressive disclosure:**
- Show only relevant blockers and fixes
- Link to full logs, don't dump everything
- PR comments <30 lines

**Prerequisites**:
- GitHub CLI (`gh`) installed and authenticated
- PR must exist
- Branch checked out locally (for auto-fixes)

## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent false CI fix claims.

1. **Never claim a fix worked without running checks**
   - ❌ BAD: "Fixed lint errors" (without running linter)
   - ✅ GOOD: Run `npm run lint`, show output, confirm 0 errors
   - Always verify fixes with actual tool runs

2. **Cite actual CI log output when diagnosing issues**
   - When reporting errors: "CI log line 245: 'TypeError: Cannot read property...'"
   - Extract actual error messages from `gh pr checks` output
   - Don't paraphrase errors - quote them exactly

3. **Never assume what broke without reading PR diff**
   - Before fixing, read: `gh pr diff` to see what changed
   - Correlate errors to specific file changes
   - Don't guess which file caused the issue

4. **Verify PR checks status before claiming success**
   - After fixes, run: `gh pr checks` to see actual status
   - Quote check statuses: "✓ lint (passed), ✗ test (failed)"
   - Don't say "all checks pass" without verification

5. **Never fabricate deployment URLs or IDs**
   - Only report URLs/IDs extracted from actual PR check logs
   - Use `gh pr view --json checks` to get real deployment info
   - If URL not in logs, say so - don't make one up

**Why this matters**: False fix claims lead to merged broken code. Hallucinated error messages waste debugging time. Accurate CI troubleshooting based on real logs ensures deployments succeed.

## BLOCKER TRACKING

**IMPORTANT**: Use the TodoWrite tool to track CI fix progress throughout this command.

**At start** - Create todo list (adapt based on actual blockers found):

```javascript
TodoWrite({
  todos: [
    {content: "Load PR context and checks", status: "pending", activeForm: "Loading PR context"},
    {content: "Categorize blockers (lint/types/tests/build)", status: "pending", activeForm: "Categorizing blockers"},
    {content: "Auto-fix lint issues", status: "pending", activeForm: "Auto-fixing lint issues"},
    {content: "Fix type errors", status: "pending", activeForm: "Fixing type errors"},
    {content: "Fix failing tests", status: "pending", activeForm: "Fixing failing tests"},
    {content: "Fix build errors", status: "pending", activeForm: "Fixing build errors"},
    {content: "Validate all checks pass", status: "pending", activeForm: "Validating checks"},
    {content: "Update PR with status", status: "pending", activeForm: "Updating PR"},
  ]
})
```

**During execution**:
- **Adapt** todo list based on actual blockers found (add/remove as needed)
- Mark each fix as `in_progress` when starting
- Mark as `completed` IMMEDIATELY after fix succeeds
- Update to `failed` if fix doesn't work (with blocker details)
- Only ONE item should be `in_progress` at a time

**Why**: CI fixes can involve multiple blockers across different categories. Users need visibility into which fixes are in progress vs complete, especially when delegating to specialist agents.

---

## LOAD PR

**Parse PR number from arguments:**

```bash
if [ -z "$ARGUMENTS" ]; then
  # Try to get PR for current branch
  CURRENT_BRANCH=$(git branch --show-current)

  # Search for PR by head branch
  PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number -q '.[0].number' 2>/dev/null)

  if [ -z "$PR_NUMBER" ]; then
    echo "Usage: /fix-ci pr [number]"
    echo "   or: /fix-ci [number]"
    echo ""
    echo "Or run from PR branch to auto-detect"
    exit 1
  fi

  echo "Auto-detected PR from branch: $CURRENT_BRANCH"
else
  # Parse PR number from various formats
  # "pr 123", "#123", "123", "review pr 123"
  if [[ "$ARGUMENTS" =~ ([0-9]+) ]]; then
    PR_NUMBER="${BASH_REMATCH[1]}"
  else
    echo "❌ Could not parse PR number from: $ARGUMENTS"
    echo "Usage: /fix-ci pr 123"
    exit 1
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Doctor: PR #$PR_NUMBER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

**Verify PR exists:**

```bash
if ! gh pr view "$PR_NUMBER" &>/dev/null; then
  echo "❌ PR #$PR_NUMBER not found"
  exit 1
fi

# Get PR details
PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body,author,baseRefName,headRefName,state,mergeable,reviewDecision)

PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_BASE=$(echo "$PR_DATA" | jq -r '.baseRefName')
PR_HEAD=$(echo "$PR_DATA" | jq -r '.headRefName')
PR_STATE=$(echo "$PR_DATA" | jq -r '.state')
PR_AUTHOR=$(echo "$PR_DATA" | jq -r '.author.login')
PR_MERGEABLE=$(echo "$PR_DATA" | jq -r '.mergeable')
PR_REVIEW=$(echo "$PR_DATA" | jq -r '.reviewDecision')

echo "Title: $PR_TITLE"
echo "Branch: $PR_HEAD → $PR_BASE"
echo "State: $PR_STATE"
echo "Author: $PR_AUTHOR"
echo "Mergeable: $PR_MERGEABLE"
echo ""
```

---

## DETECT DEPLOYMENT PHASE

**Determine if this is Phase 1 (staging) or Phase 2 (production):**

```bash
echo "Detecting deployment phase..."

PHASE_2_BLOCKED=false

if [ "$PR_BASE" = "main" ]; then
  PHASE=1
  ENVIRONMENT="staging"
  NEXT_COMMAND="/phase-1-ship"
  PHASE_NOTE="(deploys to staging environment)"

  echo "✅ Phase 1: Feature → Staging"

elif [ "$PR_BASE" = "production" ]; then
  PHASE=2
  ENVIRONMENT="production"
  NEXT_COMMAND="/phase-2-ship"
  PHASE_NOTE="(promotes staging → production)"

  echo "✅ Phase 2: Staging → Production"

  # Additional validation for Phase 2
  echo ""
  echo "Phase 2 requires staging validation..."

  # Try to find feature slug from head branch
  SLUG="$PR_HEAD"
  VALIDATION_REPORT="specs/$SLUG/staging-validation-report.md"

  if [ ! -f "$VALIDATION_REPORT" ]; then
    echo "❌ Missing: $VALIDATION_REPORT"
    echo "   Run /validate-staging first"
    PHASE_2_BLOCKED=true
  elif ! grep -q "Ready for production: ✅ Yes" "$VALIDATION_REPORT" 2>/dev/null; then
    echo "❌ Staging validation not approved"
    echo "   Complete staging validation first"
    PHASE_2_BLOCKED=true
  else
    echo "✅ Staging validation approved"
  fi

else
  echo "⚠️  Unknown base branch: $PR_BASE"
  echo "   Expected: main (Phase 1) or production (Phase 2)"
  PHASE=0
  ENVIRONMENT="unknown"
  NEXT_COMMAND="unknown"
  PHASE_NOTE=""
fi

echo ""

if [ "$PHASE_2_BLOCKED" = true ]; then
  echo "❌ Phase 2 blocked: Staging validation required"
  echo ""
  echo "Next: /validate-staging"
  exit 1
fi
```

---

## READ PR CONTEXT

**Gather PR information via GitHub CLI:**

```bash
echo "Reading PR context..."
echo ""

# Get check status
CHECK_DATA=$(gh pr checks "$PR_NUMBER" --json name,state,conclusion,detailsUrl 2>/dev/null || echo "[]")

if [ "$CHECK_DATA" = "[]" ]; then
  echo "⚠️  No CI checks found"
  echo "   CI may not have started yet"
  echo ""
  read -p "Continue anyway? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    exit 0
  fi

  TOTAL_CHECKS=0
  PENDING=0
  SUCCESS=0
  FAILURE=0
else
  TOTAL_CHECKS=$(echo "$CHECK_DATA" | jq 'length')
  PENDING=$(echo "$CHECK_DATA" | jq '[.[] | select(.state=="PENDING" or .state=="QUEUED" or .state=="IN_PROGRESS")] | length')
  SUCCESS=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="SUCCESS")] | length')
  FAILURE=$(echo "$CHECK_DATA" | jq '[.[] | select(.conclusion=="FAILURE")] | length')
fi

echo "CI Status: $SUCCESS/$TOTAL_CHECKS passed, $PENDING pending, $FAILURE failed"
echo ""

if [ "$FAILURE" -eq 0 ] && [ "$PENDING" -eq 0 ]; then
  echo "✅ All checks passed!"

  # Check review status
  if [ "$PR_REVIEW" = "APPROVED" ]; then
    echo "✅ Review approved"
    echo ""
    echo "PR is ready for: $NEXT_COMMAND"
    exit 0
  else
    echo "⏳ Awaiting review approval"
    echo ""
    echo "Next: Request review or approve PR"
    exit 0
  fi
fi

if [ "$PENDING" -gt 0 ]; then
  echo "⏳ $PENDING check(s) still running"
  echo ""
  echo "Wait for checks to complete, then re-run /fix-ci"
  exit 0
fi

# Get changed files
echo "Changed files:"
CHANGED_FILES=$(gh pr view "$PR_NUMBER" --json files -q '.files[].path')
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
echo "  Total: $FILE_COUNT files"
echo "$CHANGED_FILES" | head -5 | sed 's/^/  /'
if [ "$FILE_COUNT" -gt 5 ]; then
  echo "  ... and $((FILE_COUNT - 5)) more"
fi
echo ""
```

---

## CATEGORIZE FAILURES

**Extract error details from failing checks:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Analyzing Failures"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get failing checks
FAILING_CHECKS=$(echo "$CHECK_DATA" | jq -r '.[] | select(.conclusion=="FAILURE") | "\(.name)|\(.detailsUrl)"')

if [ -z "$FAILING_CHECKS" ]; then
  echo "No failures to analyze"
  exit 0
fi

declare -A FAILURES_BY_TYPE
RATE_LIMITED=false

while IFS='|' read -r check_name check_url; do
  if [ -z "$check_name" ]; then continue; fi

  echo "Analyzing: $check_name"

  # Categorize by check name
  CATEGORY="other"
  if [[ "$check_name" =~ [Ll]int ]]; then
    CATEGORY="lint"
  elif [[ "$check_name" =~ [Tt]ype|TypeScript|MyPy ]]; then
    CATEGORY="types"
  elif [[ "$check_name" =~ [Tt]est|Jest|Pytest ]]; then
    CATEGORY="tests"
  elif [[ "$check_name" =~ [Bb]uild ]]; then
    CATEGORY="build"
  elif [[ "$check_name" =~ [Dd]eploy|Vercel|Railway ]]; then
    CATEGORY="deploy"
  elif [[ "$check_name" =~ [Ss]moke ]]; then
    CATEGORY="smoke"
  elif [[ "$check_name" =~ E2E|e2e|Playwright ]]; then
    CATEGORY="e2e"
  fi

  FAILURES_BY_TYPE[$CATEGORY]="${FAILURES_BY_TYPE[$CATEGORY]}$check_name|$check_url
"

  echo "  Category: $CATEGORY"
  echo "  URL: $check_url"

  # Check for rate limit in deployment failures
  if [ "$CATEGORY" = "deploy" ]; then
    # Extract workflow run ID from URL
    if [[ "$check_url" =~ /runs/([0-9]+) ]]; then
      RUN_ID="${BASH_REMATCH[1]}"

      # Check logs for rate limit errors
      LOGS=$(gh run view "$RUN_ID" --log 2>/dev/null | grep -i "rate limit\|resource is limited" || echo "")
      if [ -n "$LOGS" ]; then
        RATE_LIMITED=true
        echo "  ⚠️  Rate limit detected"
      fi
    fi
  fi

  echo ""
done <<< "$FAILING_CHECKS"

# Summary
echo "Failure summary:"
for category in "${!FAILURES_BY_TYPE[@]}"; do
  count=$(echo "${FAILURES_BY_TYPE[$category]}" | grep -c "|" || echo 0)
  echo "  $category: $count failure(s)"
done
echo ""
```

---

## HANDLE RATE LIMIT ERRORS

**If rate limit detected, guide recovery:**

```bash
if [ "$RATE_LIMITED" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Rate Limit Recovery"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Post recovery guide
  gh pr comment "$PR_NUMBER" --body "⚠️ **Vercel Rate Limit Reached**

**Problem**: 100 deployments/day limit exhausted

**Recovery Options**:

### 1. Local Validation (0 deployments)
\`\`\`bash
pnpm run ci:validate  # Full quality checks + build test
\`\`\`

### 2. Wait for Quota Reset
- Quota resets in ~4 hours
- Check current usage in Vercel dashboard

### 3. Use Preview Mode (Unlimited)
- Workflow dispatch → Select \`deployment_mode: preview\`
- Tests deployment process without updating staging domain
- Does NOT count toward production quota

**Prevention Checklist**:
- [ ] Run \`pnpm run ci:validate\` locally before pushing
- [ ] Use preview mode for CI debugging (not staging mode)
- [ ] Enable concurrency controls in workflows
- [ ] Limit manual workflow triggers

**Reference**: [docs/DEPLOYMENT_OPTIMIZATION_REPORT.md](../docs/DEPLOYMENT_OPTIMIZATION_REPORT.md)

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Failed to post comment (check gh auth)"

  echo "✅ Rate limit recovery guide posted"
  echo ""
  echo "Next steps:"
  echo "  1. Run local validation: pnpm run ci:validate"
  echo "  2. Or wait ~4 hours for quota reset"
  echo "  3. Or use preview mode for testing"
  echo ""

  exit 0
fi
```

---

## AUTO-FIX LINT ERRORS

**If lint checks failed, attempt auto-fix:**

```bash
if [ -n "${FAILURES_BY_TYPE[lint]}" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Auto-Fixing Lint Errors"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Ensure we're on the right branch
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" != "$PR_HEAD" ]; then
    echo "Checking out branch: $PR_HEAD"
    git fetch origin "$PR_HEAD"
    git checkout "$PR_HEAD"
  fi

  LINT_FIXED=false
  LINT_ERRORS=""

  # Detect affected areas from changed files
  if echo "$CHANGED_FILES" | grep -q "apps/marketing"; then
    echo "Running ESLint fix on marketing..."
    cd apps/marketing
    pnpm install --silent 2>/dev/null || true
    pnpm lint --fix 2>&1 | tee /tmp/lint-marketing.log
    LINT_EXIT=${PIPESTATUS[0]}

    if [ $LINT_EXIT -eq 0 ]; then
      echo "  ✅ Marketing lint fixed"
      LINT_FIXED=true
    else
      echo "  ⚠️  Some lint errors remain"
      LINT_ERRORS="$LINT_ERRORS\nMarketing: $(tail -5 /tmp/lint-marketing.log)"
    fi
    cd ../..
  fi

  if echo "$CHANGED_FILES" | grep -q "apps/app"; then
    echo "Running ESLint fix on app..."
    cd apps/app
    pnpm install --silent 2>/dev/null || true
    pnpm lint --fix 2>&1 | tee /tmp/lint-app.log
    LINT_EXIT=${PIPESTATUS[0]}

    if [ $LINT_EXIT -eq 0 ]; then
      echo "  ✅ App lint fixed"
      LINT_FIXED=true
    else
      echo "  ⚠️  Some lint errors remain"
      LINT_ERRORS="$LINT_ERRORS\nApp: $(tail -5 /tmp/lint-app.log)"
    fi
    cd ../..
  fi

  if echo "$CHANGED_FILES" | grep -q "^api/"; then
    echo "Running Ruff fix on API..."
    cd api
    uv run ruff check --fix 2>&1 | tee /tmp/lint-api.log
    uv run ruff format
    LINT_EXIT=${PIPESTATUS[0]}

    if [ $LINT_EXIT -eq 0 ]; then
      echo "  ✅ API lint fixed"
      LINT_FIXED=true
    else
      echo "  ⚠️  Some lint errors remain"
      LINT_ERRORS="$LINT_ERRORS\nAPI: $(tail -5 /tmp/lint-api.log)"
    fi
    cd ..
  fi

  # Commit and push if fixes applied
  if [ "$LINT_FIXED" = true ]; then
    if [ -n "$(git status --porcelain)" ]; then
      echo ""
      echo "Committing lint fixes..."
      git add .
      git commit -m "fix: auto-fix lint errors

Applied ESLint/Ruff fixes via /fix-ci

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
      git push origin "$PR_HEAD"

      echo "✅ Lint fixes pushed"
      echo ""

      # Post comment
      gh pr comment "$PR_NUMBER" --body "✅ **Lint Errors Auto-Fixed**

Applied ESLint/Ruff fixes and pushed to branch.

**Next**: CI checks will re-run automatically.

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"
    else
      echo "⚠️  No files modified by lint --fix"

      if [ -n "$LINT_ERRORS" ]; then
        echo ""
        echo "Remaining errors:"
        echo -e "$LINT_ERRORS"
        echo ""
        echo "These require manual fixes"
      fi
    fi
  else
    echo "❌ Auto-fix failed or not applicable"
    echo ""

    if [ -n "$LINT_ERRORS" ]; then
      echo "Errors:"
      echo -e "$LINT_ERRORS"
    fi
  fi

  echo ""
fi
```

---

## ANALYZE TYPE ERRORS

**If type checks failed, diagnose:**

```bash
if [ -n "${FAILURES_BY_TYPE[types]}" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Type Error Analysis"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  TYPE_ERRORS=""

  # Run type check to get errors
  if echo "$CHANGED_FILES" | grep -q "apps/app"; then
    echo "Running TypeScript check on app..."
    cd apps/app
    pnpm install --silent 2>/dev/null || true
    pnpm type-check 2>&1 | tee /tmp/type-errors-app.log
    TYPE_EXIT=${PIPESTATUS[0]}
    cd ../..

    if [ $TYPE_EXIT -ne 0 ]; then
      # Parse common errors
      MISSING_PROPS=$(grep "Property .* does not exist" /tmp/type-errors-app.log | head -3 || echo "")
      TYPE_MISMATCHES=$(grep "Type .* is not assignable" /tmp/type-errors-app.log | head -3 || echo "")

      if [ -n "$MISSING_PROPS" ]; then
        TYPE_ERRORS="$TYPE_ERRORS\n**Missing properties**:\n$MISSING_PROPS"
      fi

      if [ -n "$TYPE_MISMATCHES" ]; then
        TYPE_ERRORS="$TYPE_ERRORS\n**Type mismatches**:\n$TYPE_MISMATCHES"
      fi

      echo "Type errors found in app"
    fi
  fi

  if echo "$CHANGED_FILES" | grep -q "^api/"; then
    echo "Running MyPy check on API..."
    cd api
    uv run mypy app/ 2>&1 | tee /tmp/type-errors-api.log
    TYPE_EXIT=${PIPESTATUS[0]}
    cd ..

    if [ $TYPE_EXIT -ne 0 ]; then
      API_TYPE_ERRORS=$(tail -5 /tmp/type-errors-api.log || echo "")
      TYPE_ERRORS="$TYPE_ERRORS\n**API type errors**:\n$API_TYPE_ERRORS"

      echo "Type errors found in API"
    fi
  fi

  if [ -n "$TYPE_ERRORS" ]; then
    echo ""
    echo "Delegating to specialist..."

    # Determine which specialist
    if echo "$CHANGED_FILES" | grep -q "apps/"; then
      AGENT="cfipros-frontend-shipper"
    else
      AGENT="cfipros-backend-dev"
    fi

    gh pr comment "$PR_NUMBER" --body "❌ **Type Errors Detected**

TypeScript/MyPy compilation failures.

**Errors**:
\`\`\`
$(echo -e "$TYPE_ERRORS" | head -10)
\`\`\`

**Action**: Delegating to \`$AGENT\` for fixes.

**Status**: ⏳ In progress

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

    echo "✅ Delegated to $AGENT"
  fi

  echo ""
fi
```

---

## ANALYZE BUILD FAILURES

**If build checks failed, diagnose common issues:**

```bash
if [ -n "${FAILURES_BY_TYPE[build]}" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Build Failure Diagnosis"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "Common build issues:"
  echo "  1. Missing dependencies (pnpm install needed)"
  echo "  2. TypeScript errors (run tsc --noEmit)"
  echo "  3. Environment variables missing"
  echo "  4. Import errors (check file paths)"
  echo "  5. Out of memory (increase Node memory)"
  echo ""

  BUILD_ERRORS=""

  # Try local build
  if echo "$CHANGED_FILES" | grep -q "apps/app"; then
    echo "Attempting local build of app..."
    cd apps/app
    pnpm install --silent 2>/dev/null || true

    # Clear cache first
    rm -rf .next

    pnpm build 2>&1 | tee /tmp/build-app.log
    APP_BUILD=${PIPESTATUS[0]}
    cd ../..

    if [ $APP_BUILD -ne 0 ]; then
      echo "❌ App build failed locally"

      # Parse error
      BUILD_ERRORS=$(tail -20 /tmp/build-app.log | grep -E "Error:|Failed|error TS" | head -5 || echo "Check build log")

      echo ""
      echo "Build errors:"
      echo "$BUILD_ERRORS"
    else
      echo "✅ App builds locally"
      echo "   CI failure may be environment-specific"

      BUILD_ERRORS="Build succeeds locally but fails in CI. Check environment variables or Node version."
    fi
  fi

  if echo "$CHANGED_FILES" | grep -q "apps/marketing"; then
    echo "Attempting local build of marketing..."
    cd apps/marketing
    pnpm install --silent 2>/dev/null || true

    rm -rf .next

    pnpm build 2>&1 | tee /tmp/build-marketing.log
    MARKETING_BUILD=${PIPESTATUS[0]}
    cd ../..

    if [ $MARKETING_BUILD -ne 0 ]; then
      echo "❌ Marketing build failed locally"

      MARKETING_ERRORS=$(tail -20 /tmp/build-marketing.log | grep -E "Error:|Failed|error TS" | head -5 || echo "Check build log")
      BUILD_ERRORS="$BUILD_ERRORS\n\nMarketing:\n$MARKETING_ERRORS"
    else
      echo "✅ Marketing builds locally"
    fi
  fi

  if [ -n "$BUILD_ERRORS" ]; then
    echo ""
    echo "Delegating to specialist..."

    gh pr comment "$PR_NUMBER" --body "❌ **Build Failures**

Next.js build compilation errors.

**Errors**:
\`\`\`
$BUILD_ERRORS
\`\`\`

**Action**: Delegating to \`cfipros-frontend-shipper\` for diagnosis.

**Status**: ⏳ In progress

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

    echo "✅ Delegated to cfipros-frontend-shipper"
  fi

  echo ""
fi
```

---

## ANALYZE TEST FAILURES

**If tests failed, delegate to debugger:**

```bash
if [ -n "${FAILURES_BY_TYPE[tests]}" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Failure Analysis"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Extract test failure details from check URLs
  TEST_FAILURES="${FAILURES_BY_TYPE[tests]}"

  echo "Test failures detected:"
  echo "$TEST_FAILURES" | sed 's/^/  /'
  echo ""

  echo "Delegating to cfipros-debugger..."

  gh pr comment "$PR_NUMBER" --body "❌ **Test Failures Detected**

Delegating to \`cfipros-debugger\` for analysis and fixes.

**Failing checks**:
$(echo "$TEST_FAILURES" | cut -d'|' -f1 | sed 's/^/- /')

**Changed files** (context):
$(echo "$CHANGED_FILES" | head -10 | sed 's/^/- /')

**Instructions for debugger**:
1. Analyze test failures from CI logs
2. Fix issues in affected files
3. Run tests locally to verify
4. Commit fixes to branch: \`$PR_HEAD\`
5. Report back via PR comment

**Status**: ⏳ In progress

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

  echo "✅ Delegated to cfipros-debugger"
  echo ""
fi
```

---

## VALIDATE SMOKE TESTS

**If smoke tests failed, diagnose and guide:**

```bash
if [ -n "${FAILURES_BY_TYPE[smoke]}" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Smoke Test Failure Analysis"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check if dev servers are accessible locally
  echo "Checking local dev servers..."

  # Frontend health
  FRONTEND_UP=false
  BACKEND_UP=false

  if curl -sf http://localhost:3001/health &>/dev/null; then
    echo "  ✅ Frontend server responding"
    FRONTEND_UP=true
  else
    echo "  ❌ Frontend server not responding"
    echo "     Start: cd apps/app && pnpm dev"
  fi

  # Backend health
  if curl -sf http://localhost:8000/api/v1/health/healthz &>/dev/null; then
    echo "  ✅ Backend server responding"
    BACKEND_UP=true
  else
    echo "  ❌ Backend server not responding"
    echo "     Start: cd api && uv run uvicorn app.main:app --reload"
  fi

  echo ""

  # Run smoke tests locally if servers up
  if [ "$FRONTEND_UP" = true ] && [ "$BACKEND_UP" = true ]; then
    echo "Running smoke tests locally..."

    # Frontend smoke tests
    FRONTEND_SMOKE=1
    BACKEND_SMOKE=1

    if [ -d "apps/app/tests" ]; then
      cd apps/app
      pnpm exec playwright test -g "@smoke" --reporter=line 2>&1 | tee /tmp/smoke-frontend.log
      FRONTEND_SMOKE=${PIPESTATUS[0]}
      cd ../..
    fi

    # Backend smoke tests
    if [ -d "api/tests/smoke" ]; then
      cd api
      pytest -m smoke --tb=short 2>&1 | tee /tmp/smoke-backend.log
      BACKEND_SMOKE=${PIPESTATUS[0]}
      cd ..
    fi

    if [ $FRONTEND_SMOKE -eq 0 ] && [ $BACKEND_SMOKE -eq 0 ]; then
      echo "✅ All smoke tests pass locally"
      echo ""
      echo "⚠️  Tests pass locally but fail in CI"
      echo ""
      echo "Possible causes:"
      echo "  - Environment variable mismatch"
      echo "  - Timing issues (race conditions)"
      echo "  - Missing test data in CI environment"
      echo ""

      gh pr comment "$PR_NUMBER" --body "⚠️ **Smoke Tests: Local vs CI Mismatch**

Smoke tests **pass locally** but **fail in CI**.

**Local results**:
- Frontend: ✅ Pass
- Backend: ✅ Pass

**Possible causes**:
1. Environment variable differences
2. Race conditions or timing issues
3. Missing test data in CI

**Action**: Review CI logs for specific errors.

**Check CI logs**: ${FAILURES_BY_TYPE[smoke]%%$'\n'*}

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

    else
      echo "❌ Smoke tests fail locally"
      echo ""

      SMOKE_STATUS="**Frontend**: $([ $FRONTEND_SMOKE -eq 0 ] && echo "✅ Pass" || echo "❌ Fail")
**Backend**: $([ $BACKEND_SMOKE -eq 0 ] && echo "✅ Pass" || echo "❌ Fail")"

      gh pr comment "$PR_NUMBER" --body "❌ **Smoke Tests Failing**

Tests fail both locally and in CI.

$SMOKE_STATUS

**Action**: Delegating to \`cfipros-debugger\` for diagnosis.

**Frontend logs**: \`/tmp/smoke-frontend.log\`
**Backend logs**: \`/tmp/smoke-backend.log\`

**Status**: ⏳ In progress

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

      echo "Delegated to cfipros-debugger"
    fi
  else
    echo "⚠️  Cannot run smoke tests (servers not running)"
    echo ""

    gh pr comment "$PR_NUMBER" --body "⚠️ **Smoke Test Validation Skipped**

Local dev servers not running. Cannot validate smoke tests.

**To debug**:
1. Start servers:
   - Frontend: \`cd apps/app && pnpm dev\`
   - Backend: \`cd api && uv run uvicorn app.main:app --reload\`
2. Run smoke tests: \`pnpm smoke\`
3. Fix failures
4. Push fixes

**Check CI logs**: ${FAILURES_BY_TYPE[smoke]%%$'\n'*}

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"
  fi

  echo ""
fi
```

---

## CHECK REVIEW STATUS

**Handle review comments and approvals:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Review Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REVIEW_GATE=false

if [ "$PR_REVIEW" = "APPROVED" ]; then
  echo "✅ Review approved"
  REVIEW_GATE=true

elif [ "$PR_REVIEW" = "CHANGES_REQUESTED" ]; then
  echo "❌ Changes requested"

  # Get review comments
  REVIEW_DATA=$(gh pr view "$PR_NUMBER" --json reviews -q '.reviews[] | select(.state=="CHANGES_REQUESTED")')

  if [ -n "$REVIEW_DATA" ]; then
    REVIEW_BODY=$(echo "$REVIEW_DATA" | jq -r '.body' | head -10)

    echo ""
    echo "Review feedback (first 10 lines):"
    echo "$REVIEW_BODY" | sed 's/^/  /'
    echo ""

    # Offer to address feedback
    echo "Address review feedback? (y/N)"
    read -p "> " DELEGATE_REVIEW

    if [ "$DELEGATE_REVIEW" = "y" ]; then
      gh pr comment "$PR_NUMBER" --body "🔍 **Addressing Review Feedback**

Delegating requested changes to \`senior-code-reviewer\`.

**Feedback**:
$(echo "$REVIEW_BODY" | head -20)

**Status**: ⏳ In progress

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

      echo "✅ Delegated to senior-code-reviewer"
    fi
  fi

  REVIEW_GATE=false

else
  echo "⏳ Review pending"
  REVIEW_GATE=false
fi

echo ""
```

---

## VALIDATE DEPLOYMENT TRACKING

**Ensure NOTES.md has deployment metadata for rollback:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Tracking"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect feature from PR branch
SLUG="$PR_HEAD"
FEATURE_DIR="specs/$SLUG"

if [ -d "$FEATURE_DIR" ]; then
  NOTES_FILE="$FEATURE_DIR/NOTES.md"

  if [ ! -f "$NOTES_FILE" ]; then
    echo "⚠️  NOTES.md not found: $NOTES_FILE"
  elif ! grep -q "## Deployment Metadata" "$NOTES_FILE" 2>/dev/null; then
    echo "⚠️  Missing deployment tracking in NOTES.md"
    echo ""
    echo "Adding deployment tracking template..."

    cat >> "$NOTES_FILE" <<'EOF'

## Deployment Metadata

**Purpose**: Track deploy IDs for instant 3-command rollback

### Staging Deploys

| Date | Marketing Deploy ID | App Deploy ID | API Image SHA | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | [pending] | [pending] | [pending] | ⏳ Pending |

### Production Deploys

| Date | Marketing Deploy ID | App Deploy ID | API Image SHA | Status |
|------|---------------------|---------------|---------------|--------|
| YYYY-MM-DD | [not deployed] | [not deployed] | [not deployed] | - |

**Rollback Commands** (see docs/ROLLBACK_RUNBOOK.md):
```bash
# 1. Get deploy ID from table above
# 2. Set Vercel alias to previous deploy
vercel alias set <previous-deploy-id> cfipros.com

# 3. Update Railway API image
railway service update --image ghcr.io/.../api:<previous-sha>
```
EOF

    # Commit if on feature branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" = "$PR_HEAD" ]; then
      git add "$NOTES_FILE"
      git commit -m "docs: add deployment tracking to NOTES.md

Enables 3-command rollback capability.

🤖 Generated by /fix-ci
Co-Authored-By: Claude <noreply@anthropic.com>"
      git push origin "$PR_HEAD"

      echo "✅ Deployment tracking added and committed"
    else
      echo "⚠️  Not on feature branch, manual commit required"
    fi
  else
    echo "✅ Deployment tracking present"
  fi
else
  echo "⚠️  Feature directory not found: $FEATURE_DIR"
  echo "   Deployment tracking validation skipped"
fi

echo ""
```

---

## VALIDATE READINESS

**Check all deployment gates:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Readiness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GATES_PASSED=0
GATES_TOTAL=0

# Common gates
echo "Common gates:"

# 1. CI checks
((GATES_TOTAL++))
if [ "$FAILURE" -eq 0 ]; then
  echo "  ✅ All CI checks passing"
  ((GATES_PASSED++))
else
  echo "  ❌ $FAILURE CI check(s) failing"
fi

# 2. Review
((GATES_TOTAL++))
if [ "$REVIEW_GATE" = true ]; then
  echo "  ✅ Review approved"
  ((GATES_PASSED++))
else
  echo "  ⏳ Awaiting review approval"
fi

# 3. Conflicts
((GATES_TOTAL++))
if [ "$PR_MERGEABLE" = "MERGEABLE" ]; then
  echo "  ✅ No merge conflicts"
  ((GATES_PASSED++))
else
  echo "  ❌ Merge conflicts detected"
fi

# Phase-specific gates
if [ "$PHASE" -eq 1 ]; then
  echo ""
  echo "Phase 1 (Staging) gates:"

  # 4. Smoke tests (if applicable)
  ((GATES_TOTAL++))
  if [ -z "${FAILURES_BY_TYPE[smoke]}" ]; then
    echo "  ✅ Smoke tests passing"
    ((GATES_PASSED++))
  else
    echo "  ❌ Smoke tests failing"
  fi

  PHASE_SPECIFIC_GATES="- ✅ Smoke tests passing"

elif [ "$PHASE" -eq 2 ]; then
  echo ""
  echo "Phase 2 (Production) gates:"

  # 4. Staging validation
  ((GATES_TOTAL++))
  if [ -f "$VALIDATION_REPORT" ] && grep -q "Ready for production: ✅ Yes" "$VALIDATION_REPORT" 2>/dev/null; then
    echo "  ✅ Staging validation complete"
    ((GATES_PASSED++))
  else
    echo "  ❌ Staging validation required"
  fi

  # 5. Deployment tracking
  ((GATES_TOTAL++))
  if [ -f "$NOTES_FILE" ] && grep -q "## Deployment Metadata" "$NOTES_FILE" 2>/dev/null; then
    echo "  ✅ Deployment tracking ready"
    ((GATES_PASSED++))
  else
    echo "  ⚠️  Deployment tracking missing"
  fi

  PHASE_SPECIFIC_GATES="- ✅ Staging validation complete
- ✅ Deployment tracking ready"
fi

echo ""
echo "Gates: $GATES_PASSED / $GATES_TOTAL passed"
echo ""

# Determine readiness
if [ "$GATES_PASSED" -eq "$GATES_TOTAL" ]; then
  READY_STATUS="✅ Ready for $ENVIRONMENT"
  READY_EMOJI="✅"

  gh pr comment "$PR_NUMBER" --body "## ✅ Ready for $ENVIRONMENT

**All gates passed:**
- ✅ CI checks green
- ✅ Review approved
- ✅ No merge conflicts
$PHASE_SPECIFIC_GATES

**Next**: \`$NEXT_COMMAND\` $PHASE_NOTE

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"

else
  READY_STATUS="❌ Not ready - $((GATES_TOTAL - GATES_PASSED)) gate(s) failing"
  READY_EMOJI="❌"

  # List blocking gates
  BLOCKERS=""
  [ "$FAILURE" -gt 0 ] && BLOCKERS="$BLOCKERS\n- CI checks failing"
  [ "$REVIEW_GATE" = false ] && BLOCKERS="$BLOCKERS\n- Review approval needed"
  [ "$PR_MERGEABLE" != "MERGEABLE" ] && BLOCKERS="$BLOCKERS\n- Merge conflicts"
  [ -n "${FAILURES_BY_TYPE[smoke]}" ] && BLOCKERS="$BLOCKERS\n- Smoke tests failing"

  gh pr comment "$PR_NUMBER" --body "## ⚠️ Not Ready for $ENVIRONMENT

**Blockers** ($((GATES_TOTAL - GATES_PASSED)) remaining):
$(echo -e "$BLOCKERS")

**Actions taken**:
$([ -n "${FAILURES_BY_TYPE[lint]}" ] && echo "- Auto-fixed lint errors")
$([ -n "${FAILURES_BY_TYPE[tests]}" ] && echo "- Delegated test failures to cfipros-debugger")
$([ -n "${FAILURES_BY_TYPE[types]}" ] && echo "- Delegated type errors to specialist")
$([ -n "${FAILURES_BY_TYPE[build]}" ] && echo "- Delegated build failures to cfipros-frontend-shipper")

**Next**: Wait for delegated fixes to complete, then re-run \`/fix-ci pr $PR_NUMBER\`

---
🤖 Generated by /fix-ci" 2>/dev/null || echo "Comment post failed"
fi
```

---

## RETURN

**Final summary:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "PR: #$PR_NUMBER"
echo "Phase: $PHASE ($ENVIRONMENT)"
echo ""
echo "Actions taken:"

ACTIONS_COUNT=0

if [ -n "${FAILURES_BY_TYPE[lint]}" ]; then
  echo "  ✅ Auto-fixed lint errors"
  ((ACTIONS_COUNT++))
fi

if [ -n "${FAILURES_BY_TYPE[tests]}" ]; then
  echo "  ⏳ Delegated test failures to cfipros-debugger"
  ((ACTIONS_COUNT++))
fi

if [ -n "${FAILURES_BY_TYPE[types]}" ]; then
  echo "  ⏳ Delegated type errors to specialist"
  ((ACTIONS_COUNT++))
fi

if [ -n "${FAILURES_BY_TYPE[build]}" ]; then
  echo "  ⏳ Delegated build failures to cfipros-frontend-shipper"
  ((ACTIONS_COUNT++))
fi

if [ -n "${FAILURES_BY_TYPE[smoke]}" ]; then
  echo "  ⏳ Delegated smoke test failures to cfipros-debugger"
  ((ACTIONS_COUNT++))
fi

if [ "$RATE_LIMITED" = true ]; then
  echo "  📝 Posted rate limit recovery guide"
  ((ACTIONS_COUNT++))
fi

if [ $ACTIONS_COUNT -eq 0 ]; then
  echo "  (none - no auto-fixable issues)"
fi

echo ""
echo "Verdict: $READY_STATUS"
echo ""

if [ "$GATES_PASSED" -eq "$GATES_TOTAL" ]; then
  echo "Next: $NEXT_COMMAND"
else
  echo "Next: Wait for delegated fixes, then re-run /fix-ci"
fi

echo ""
```

# Validate Staging: Manual Validation Gate

**Command**: `/validate-staging`

**Purpose**: Manual validation of staging deployment before production. Checks E2E tests, Lighthouse metrics, and guides manual testing on staging URLs.

**When to use**: After `/phase-1-ship` completes and deploys to staging environment. This is the quality gate before `/phase-2-ship` to production.

**Workflow position**: \spec-flow → clarify → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → **validate-staging** → phase-2-ship`

---

## MENTAL MODEL

You are a **staging validation orchestrator**. Your job:

1. **Detect feature** from recent staging deployment
2. **Check deployment status** (marketing, app, API on staging)
3. **Review automated tests** (E2E, Lighthouse CI from GitHub Actions)
4. **Guide manual testing** (display checklist from spec.md)
5. **Capture validation results** (create staging-validation-report.md)
6. **Gate production** (block /phase-2-ship if validation fails)

**Philosophy**: Staging is the final checkpoint before production. This command combines automated test results with manual validation to ensure features work correctly in a production-like environment.

**Manual gates**: E2E tests and Lighthouse are automated, but manual testing is required for:
- Visual validation (design matches mockups)
- User flows (UX feels right)
- Edge cases (error states, empty states)
- Cross-browser compatibility (if needed)

---

## BRANCH MODEL ALIGNMENT

**Critical**: This command validates the staging **environment**, not a staging branch.

**Deployment Model**:
- Main branch → Deployed to staging environment (staging.cfipros.com)
- Staging environment → Promoted to production environment (cfipros.com)
- NO staging branch exists (trunk-based development)

**Where to run this**:
- Run from main branch after `/phase-1-ship` deploys to staging
- Or run from feature branch after PR merged and deployed

---

## EXECUTION

### Phase V.0: Load Feature from Recent Deployment

**Detect which feature was just deployed to staging:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.0: LOAD FEATURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get latest staging deployment
LATEST_DEPLOY=$(gh run list \
  --workflow=deploy-staging.yml \
  --branch=main \
  --limit=1 \
  --json databaseId,headSha,conclusion,status,createdAt,displayTitle)

if [ -z "$LATEST_DEPLOY" ] || [ "$LATEST_DEPLOY" = "[]" ]; then
  echo "❌ No staging deployments found"
  echo ""
  echo "Expected workflow: deploy-staging.yml"
  echo ""
  echo "Did you run /phase-1-ship?"
  exit 1
fi

RUN_ID=$(echo "$LATEST_DEPLOY" | jq -r '.[0].databaseId')
COMMIT_SHA=$(echo "$LATEST_DEPLOY" | jq -r '.[0].headSha')
DEPLOY_STATUS=$(echo "$LATEST_DEPLOY" | jq -r '.[0].status')
DEPLOY_CONCLUSION=$(echo "$LATEST_DEPLOY" | jq -r '.[0].conclusion')
DEPLOY_TITLE=$(echo "$LATEST_DEPLOY" | jq -r '.[0].displayTitle')
DEPLOY_DATE=$(echo "$LATEST_DEPLOY" | jq -r '.[0].createdAt')

echo "Latest staging deployment:"
echo "  Workflow: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID"
echo "  Commit: $COMMIT_SHA"
echo "  Status: $DEPLOY_STATUS"
echo "  Conclusion: $DEPLOY_CONCLUSION"
echo "  Date: $DEPLOY_DATE"
echo ""

# Extract feature from commit message
COMMIT_MSG=$(git log --format=%s -n 1 "$COMMIT_SHA")
echo "Commit message: $COMMIT_MSG"
echo ""

# Try to extract slug from commit message
if [[ "$COMMIT_MSG" =~ feat:\ ([a-z0-9-]+) ]]; then
  SLUG="${BASH_REMATCH[1]}"
  echo "Detected feature: $SLUG"
elif [[ "$COMMIT_MSG" =~ ([a-z0-9-]+):\ ]]; then
  SLUG="${BASH_REMATCH[1]}"
  echo "Detected feature: $SLUG (from commit prefix)"
else
  echo "⚠️  Could not detect feature from commit message"
  echo ""
  read -p "Enter feature slug manually: " SLUG
fi

# Find feature directory
FEATURE_DIR="specs/$SLUG"

if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature directory not found: $FEATURE_DIR"
  echo ""
  echo "Available specs:"
  ls -1 specs/ | grep -v "^archive$" | head -10 | sed 's/^/  /'
  echo ""
  exit 1
fi

if [ ! -f "$FEATURE_DIR/spec.md" ]; then
  echo "❌ spec.md not found: $FEATURE_DIR/spec.md"
  exit 1
fi

echo "Feature directory: $FEATURE_DIR"
echo ""
echo "✅ Feature loaded: $SLUG"
echo ""
```

---

### Phase V.1: Check Deployment Status

**Verify deployment completed successfully:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.1: DEPLOYMENT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if deployment is still running
if [ "$DEPLOY_STATUS" = "in_progress" ] || [ "$DEPLOY_STATUS" = "queued" ]; then
  echo "⏳ Deployment still running"
  echo ""
  echo "Current status: $DEPLOY_STATUS"
  echo "Workflow: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID"
  echo ""
  echo "Wait for deployment to complete, then run /validate-staging again"
  exit 1
fi

# Check if deployment failed
if [ "$DEPLOY_CONCLUSION" != "success" ]; then
  echo "❌ Deployment failed"
  echo ""
  echo "Conclusion: $DEPLOY_CONCLUSION"
  echo ""

  # Get failed jobs
  FAILED_JOBS=$(gh run view "$RUN_ID" --json jobs --jq '.jobs[] | select(.conclusion == "failure") | .name')

  if [ -n "$FAILED_JOBS" ]; then
    echo "Failed jobs:"
    echo "$FAILED_JOBS" | sed 's/^/  - /'
    echo ""
  fi

  echo "Fix deployment failures before validating staging"
  echo ""
  echo "Workflow: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID"
  exit 1
fi

echo "✅ Deployment successful"
echo ""

# Get all jobs for status breakdown
JOBS_JSON=$(gh run view "$RUN_ID" --json jobs)

echo "Job Status:"

# Check deploy-marketing
MARKETING_STATUS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("deploy-marketing")) | .conclusion' | head -1)
if [ "$MARKETING_STATUS" = "success" ]; then
  echo "  ✅ deploy-marketing"
else
  echo "  ❌ deploy-marketing: $MARKETING_STATUS"
fi

# Check deploy-app
APP_STATUS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("deploy-app")) | .conclusion' | head -1)
if [ "$APP_STATUS" = "success" ]; then
  echo "  ✅ deploy-app"
else
  echo "  ❌ deploy-app: $APP_STATUS"
fi

# Check deploy-api
API_STATUS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("deploy-api")) | .conclusion' | head -1)
if [ "$API_STATUS" = "success" ]; then
  echo "  ✅ deploy-api"
else
  echo "  ❌ deploy-api: $API_STATUS"
fi

# Check smoke-tests
SMOKE_STATUS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("smoke")) | .conclusion' | head -1)
if [ "$SMOKE_STATUS" = "success" ]; then
  echo "  ✅ smoke-tests"
else
  echo "  ⚠️  smoke-tests: ${SMOKE_STATUS:-not run}"
fi

echo ""
```

---

### Phase V.2: Verify Staging Health

**Check staging endpoints responding:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.2: STAGING HEALTH CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Staging URLs
STAGING_MARKETING="https://staging.cfipros.com"
STAGING_APP="https://app.staging.cfipros.com"
STAGING_API="https://api.staging.cfipros.com"

echo "Checking staging endpoints..."
echo ""

# Check marketing health
echo -n "  Marketing ($STAGING_MARKETING/health)... "
MARKETING_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_MARKETING/health" || echo "000")

if [ "$MARKETING_HEALTH" = "200" ]; then
  echo "✅"
else
  echo "❌ HTTP $MARKETING_HEALTH"
fi

# Check app health
echo -n "  App ($STAGING_APP/health)... "
APP_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_APP/health" || echo "000")

if [ "$APP_HEALTH" = "200" ]; then
  echo "✅"
else
  echo "❌ HTTP $APP_HEALTH"
fi

# Check API health
echo -n "  API ($STAGING_API/api/v1/health/healthz)... "
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_API/api/v1/health/healthz" || echo "000")

if [ "$API_HEALTH" = "200" ]; then
  echo "✅"
else
  echo "❌ HTTP $API_HEALTH"
fi

echo ""

# Check if any critical endpoints failed
if [ "$MARKETING_HEALTH" != "200" ] || [ "$APP_HEALTH" != "200" ] || [ "$API_HEALTH" != "200" ]; then
  echo "⚠️  Some health checks failed"
  echo ""
  echo "Deployment may not be fully ready. Continue anyway? (y/N)"
  read -p "> " CONTINUE_UNHEALTHY

  if [ "$CONTINUE_UNHEALTHY" != "y" ]; then
    echo "Validation cancelled"
    exit 1
  fi
  echo ""
else
  echo "✅ All staging endpoints healthy"
  echo ""
fi
```

---

### Phase V.3: Review E2E Test Results

**Parse E2E test results from workflow:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.3: E2E TEST RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find E2E job in workflow
E2E_JOB=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("e2e") or contains("E2E")) | {name: .name, conclusion: .conclusion, htmlUrl: .html_url} | @json' | head -1)

if [ -z "$E2E_JOB" ] || [ "$E2E_JOB" = "null" ]; then
  echo "⚠️  No E2E tests found in workflow"
  echo ""
  E2E_STATUS="not_run"
  E2E_URL=""
else
  E2E_NAME=$(echo "$E2E_JOB" | jq -r '.name')
  E2E_CONCLUSION=$(echo "$E2E_JOB" | jq -r '.conclusion')
  E2E_URL=$(echo "$E2E_JOB" | jq -r '.htmlUrl')

  echo "E2E Job: $E2E_NAME"
  echo "Status: $E2E_CONCLUSION"
  echo "URL: $E2E_URL"
  echo ""

  if [ "$E2E_CONCLUSION" = "success" ]; then
    E2E_STATUS="passed"
    echo "✅ E2E tests passed"
  elif [ "$E2E_CONCLUSION" = "failure" ]; then
    E2E_STATUS="failed"
    echo "❌ E2E tests failed"
    echo ""

    # Get failure details from logs
    echo "Fetching failure details..."
    E2E_LOGS=$(gh run view "$RUN_ID" --log | grep -A 5 "e2e" | grep -i "error\|fail" | head -10)

    if [ -n "$E2E_LOGS" ]; then
      echo "Failure summary:"
      echo "$E2E_LOGS" | sed 's/^/  /'
      echo ""
    fi

    echo "🚫 BLOCKER: E2E tests must pass before production"
    echo ""
    echo "Fix E2E failures and redeploy to staging"
    exit 1
  else
    E2E_STATUS="$E2E_CONCLUSION"
    echo "⚠️  E2E status: $E2E_CONCLUSION"
  fi

  echo ""
fi
```

---

### Phase V.4: Review Lighthouse Results

**Parse Lighthouse CI results from workflow:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.4: LIGHTHOUSE CI RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find Lighthouse job in workflow
LIGHTHOUSE_JOB=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.name | contains("lighthouse") or contains("Lighthouse")) | {name: .name, conclusion: .conclusion, htmlUrl: .html_url} | @json' | head -1)

if [ -z "$LIGHTHOUSE_JOB" ] || [ "$LIGHTHOUSE_JOB" = "null" ]; then
  echo "⚠️  No Lighthouse CI found in workflow"
  echo ""
  LIGHTHOUSE_STATUS="not_run"
  LIGHTHOUSE_URL=""
else
  LIGHTHOUSE_NAME=$(echo "$LIGHTHOUSE_JOB" | jq -r '.name')
  LIGHTHOUSE_CONCLUSION=$(echo "$LIGHTHOUSE_JOB" | jq -r '.conclusion')
  LIGHTHOUSE_URL=$(echo "$LIGHTHOUSE_JOB" | jq -r '.htmlUrl')

  echo "Lighthouse Job: $LIGHTHOUSE_NAME"
  echo "Status: $LIGHTHOUSE_CONCLUSION"
  echo "URL: $LIGHTHOUSE_URL"
  echo ""

  if [ "$LIGHTHOUSE_CONCLUSION" = "success" ]; then
    LIGHTHOUSE_STATUS="passed"

    # Try to extract scores from logs
    echo "Extracting performance scores..."
    LIGHTHOUSE_LOGS=$(gh run view "$RUN_ID" --log | grep -E "Performance|Accessibility|score" | head -20)

    if [ -n "$LIGHTHOUSE_LOGS" ]; then
      echo "Lighthouse scores:"
      echo "$LIGHTHOUSE_LOGS" | sed 's/^/  /'
      echo ""
    fi

    # Check for performance warnings
    PERF_WARNINGS=$(echo "$LIGHTHOUSE_LOGS" | grep -i "warning\|below.*target" || echo "")

    if [ -n "$PERF_WARNINGS" ]; then
      echo "⚠️  Performance warnings:"
      echo "$PERF_WARNINGS" | sed 's/^/  /'
      echo ""
      echo "Targets: Performance >85, Accessibility >95"
      echo ""

      read -p "Continue with performance warnings? (y/N): " CONTINUE_PERF
      if [ "$CONTINUE_PERF" != "y" ]; then
        echo "Validation cancelled"
        exit 1
      fi
      echo ""
    else
      echo "✅ Lighthouse CI passed"
    fi

  elif [ "$LIGHTHOUSE_CONCLUSION" = "failure" ]; then
    LIGHTHOUSE_STATUS="failed"
    echo "❌ Lighthouse CI failed"
    echo ""

    # Get failure details
    LIGHTHOUSE_ERRORS=$(gh run view "$RUN_ID" --log | grep -A 3 "lighthouse" | grep -i "error\|fail" | head -10)

    if [ -n "$LIGHTHOUSE_ERRORS" ]; then
      echo "Failures:"
      echo "$LIGHTHOUSE_ERRORS" | sed 's/^/  /'
      echo ""
    fi

    echo "⚠️  Lighthouse failures detected"
    echo ""
    echo "Recommended: Fix performance issues before production"
    echo "Continue anyway? (y/N)"
    read -p "> " CONTINUE_LIGHTHOUSE

    if [ "$CONTINUE_LIGHTHOUSE" != "y" ]; then
      echo "Validation cancelled"
      exit 1
    fi
    echo ""
  else
    LIGHTHOUSE_STATUS="$LIGHTHOUSE_CONCLUSION"
    echo "⚠️  Lighthouse status: $LIGHTHOUSE_CONCLUSION"
    echo ""
  fi
fi
```

---

### Phase V.5: Generate Manual Testing Checklist

**Create interactive testing checklist from spec.md:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.5: MANUAL TESTING CHECKLIST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract acceptance criteria from spec.md
SPEC_FILE="$FEATURE_DIR/spec.md"

echo "Extracting test criteria from spec.md..."
echo ""

# Find Acceptance Criteria section
ACCEPTANCE_START=$(grep -n "## Acceptance Criteria" "$SPEC_FILE" | cut -d: -f1 | head -1)

if [ -z "$ACCEPTANCE_START" ]; then
  echo "⚠️  No 'Acceptance Criteria' section found in spec.md"
  ACCEPTANCE_ITEMS=""
else
  # Extract criteria (until next ## section)
  ACCEPTANCE_END=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

  if [ -z "$ACCEPTANCE_END" ]; then
    ACCEPTANCE_ITEMS=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE")
  else
    ACCEPTANCE_ITEMS=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE" | head -n $((ACCEPTANCE_END - 1)))
  fi

  # Filter to just list items
  ACCEPTANCE_ITEMS=$(echo "$ACCEPTANCE_ITEMS" | grep "^- " || echo "")
fi

# Find User Flows section
FLOWS_START=$(grep -n "## User Flows\|## User Stories" "$SPEC_FILE" | cut -d: -f1 | head -1)

if [ -z "$FLOWS_START" ]; then
  FLOW_ITEMS=""
else
  FLOWS_END=$(tail -n +$((FLOWS_START + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

  if [ -z "$FLOWS_END" ]; then
    FLOW_ITEMS=$(tail -n +$((FLOWS_START + 1)) "$SPEC_FILE")
  else
    FLOW_ITEMS=$(tail -n +$((FLOWS_START + 1)) "$SPEC_FILE" | head -n $((FLOWS_END - 1)))
  fi

  FLOW_ITEMS=$(echo "$FLOW_ITEMS" | grep "^- \|^[0-9]\." || echo "")
fi

# Create checklist file
CHECKLIST_FILE="/tmp/staging-validation-checklist-$SLUG.md"

cat > "$CHECKLIST_FILE" <<EOF
# Staging Validation Checklist: $SLUG

**Date**: $(date +"%Y-%m-%d %H:%M")
**Deployment**: $RUN_ID
**Commit**: $COMMIT_SHA

---

## Staging URLs

- **Marketing**: $STAGING_MARKETING
- **App**: $STAGING_APP
- **API**: $STAGING_API/docs

---

## Acceptance Criteria

EOF

if [ -n "$ACCEPTANCE_ITEMS" ]; then
  echo "$ACCEPTANCE_ITEMS" | sed 's/^- /- [ ] /' >> "$CHECKLIST_FILE"
else
  echo "- [ ] Feature works as described in spec.md" >> "$CHECKLIST_FILE"
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## User Flows

EOF

if [ -n "$FLOW_ITEMS" ]; then
  echo "$FLOW_ITEMS" | sed 's/^- /- [ ] /' | sed 's/^[0-9]\. /- [ ] /' >> "$CHECKLIST_FILE"
else
  echo "- [ ] Primary user flow works end-to-end" >> "$CHECKLIST_FILE"
fi

cat >> "$CHECKLIST_FILE" <<EOF

---

## Edge Cases

- [ ] Error states display correctly
- [ ] Empty states display correctly
- [ ] Loading states display correctly
- [ ] Form validation works
- [ ] Network errors handled gracefully

---

## Visual Validation

- [ ] Design matches mockups/visuals
- [ ] Responsive on mobile (if applicable)
- [ ] Animations smooth (if applicable)
- [ ] Typography and spacing correct
- [ ] Colors and branding consistent

---

## Accessibility (Quick Checks)

- [ ] Keyboard navigation works
- [ ] Screen reader labels present
- [ ] Focus indicators visible
- [ ] Color contrast sufficient

---

## Cross-Browser (Optional)

- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari (if accessible)

---

## Instructions

1. Open staging URLs above
2. Test each item in this checklist
3. Note any issues found below
4. Return to terminal when complete

---

## Issues Found

(Add any issues here)

EOF

echo "✅ Checklist created: $CHECKLIST_FILE"
echo ""

# Display checklist
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$CHECKLIST_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

---

### Phase V.6: Interactive Manual Testing

**Guide user through manual validation:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MANUAL TESTING REQUIRED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Please complete manual testing on staging:"
echo ""
echo "  1. Open staging URLs in browser"
echo "  2. Test all items in checklist above"
echo "  3. Note any issues found"
echo ""

# Open checklist in editor for user to fill out
if command -v code &> /dev/null; then
  echo "Opening checklist in VS Code..."
  code "$CHECKLIST_FILE"
elif command -v vim &> /dev/null; then
  echo "Press Enter to open checklist in vim..."
  read
  vim "$CHECKLIST_FILE"
elif command -v nano &> /dev/null; then
  echo "Press Enter to open checklist in nano..."
  read
  nano "$CHECKLIST_FILE"
else
  echo "Edit checklist manually: $CHECKLIST_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wait for user to complete testing
read -p "Have you completed manual testing? (y/N): " TESTING_COMPLETE

if [ "$TESTING_COMPLETE" != "y" ]; then
  echo ""
  echo "⏸️  Manual testing incomplete"
  echo ""
  echo "Complete testing, then run /validate-staging again"
  echo "Checklist saved: $CHECKLIST_FILE"
  exit 0
fi

echo ""

# Check for issues
read -p "Were any issues found? (y/N): " ISSUES_FOUND

if [ "$ISSUES_FOUND" = "y" ]; then
  echo ""
  echo "Describe the issues found (or reference checklist):"
  read -p "> " ISSUE_DESCRIPTION

  if [ -z "$ISSUE_DESCRIPTION" ]; then
    ISSUE_DESCRIPTION="See checklist: $CHECKLIST_FILE"
  fi

  MANUAL_STATUS="failed"
  MANUAL_ISSUES="$ISSUE_DESCRIPTION"

  echo ""
  echo "❌ Manual testing failed"
  echo ""
else
  MANUAL_STATUS="passed"
  MANUAL_ISSUES="None - all checks passed ✅"

  echo ""
  echo "✅ Manual testing passed"
  echo ""
fi
```

---

### Phase V.7: Generate Validation Report

**Create staging-validation-report.md with actual data:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE V.7: VALIDATION REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VALIDATION_REPORT="$FEATURE_DIR/staging-validation-report.md"

# Determine overall status
if [ "$E2E_STATUS" = "failed" ] || [ "$MANUAL_STATUS" = "failed" ]; then
  OVERALL_STATUS="❌ Blocked"
  READY_FOR_PROD="false"
elif [ "$LIGHTHOUSE_STATUS" = "failed" ]; then
  OVERALL_STATUS="⚠️ Review Required"
  READY_FOR_PROD="warning"
else
  OVERALL_STATUS="✅ Ready for Production"
  READY_FOR_PROD="true"
fi

# Get current user
USER_NAME=$(git config user.name || echo "Unknown")
VALIDATED_DATE=$(date +"%Y-%m-%d %H:%M")

echo "Generating validation report..."
echo ""

cat > "$VALIDATION_REPORT" <<EOF
# Staging Validation Report

**Date**: $VALIDATED_DATE
**Feature**: $SLUG
**Status**: $OVERALL_STATUS

---

## Deployment Info

**Workflow**: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID
**Commit**: $COMMIT_SHA
**Branch**: main
**Deployed**: $DEPLOY_DATE

---

## Staging URLs

- **Marketing**: $STAGING_MARKETING
- **App**: $STAGING_APP
- **API**: $STAGING_API

---

## Automated Tests

### E2E Tests

**Status**: $([ "$E2E_STATUS" = "passed" ] && echo "✅ Passed" || echo "❌ Failed / Not Run")

EOF

if [ "$E2E_STATUS" = "passed" ]; then
  cat >> "$VALIDATION_REPORT" <<EOF
All E2E tests passed successfully.

**Report**: $E2E_URL
EOF
elif [ "$E2E_STATUS" = "failed" ]; then
  cat >> "$VALIDATION_REPORT" <<EOF
**Failures detected**

**Report**: $E2E_URL

🚫 **BLOCKER**: E2E tests must pass before production deployment.
EOF
else
  cat >> "$VALIDATION_REPORT" <<EOF
E2E tests were not run or are pending.

**Status**: $E2E_STATUS
EOF
fi

cat >> "$VALIDATION_REPORT" <<EOF

---

### Lighthouse CI

**Status**: $([ "$LIGHTHOUSE_STATUS" = "passed" ] && echo "✅ Passed" || echo "❌ Failed / Not Run")

EOF

if [ "$LIGHTHOUSE_STATUS" = "passed" ]; then
  cat >> "$VALIDATION_REPORT" <<EOF
Performance targets met.

**Targets**:
- Performance: ≥85
- Accessibility: ≥95
- FCP: <1500ms
- TTI: <3000ms
- LCP: <2500ms

**Report**: $LIGHTHOUSE_URL
EOF
elif [ "$LIGHTHOUSE_STATUS" = "failed" ]; then
  cat >> "$VALIDATION_REPORT" <<EOF
**Performance issues detected**

**Report**: $LIGHTHOUSE_URL

⚠️ **WARNING**: Performance below targets. Review recommended before production.
EOF
else
  cat >> "$VALIDATION_REPORT" <<EOF
Lighthouse CI was not run or is pending.

**Status**: $LIGHTHOUSE_STATUS
EOF
fi

cat >> "$VALIDATION_REPORT" <<EOF

---

## Manual Validation

**Status**: $([ "$MANUAL_STATUS" = "passed" ] && echo "✅ Passed" || echo "❌ Failed")
**Tested by**: $USER_NAME
**Tested on**: $VALIDATED_DATE

### Issues Found

$MANUAL_ISSUES

### Checklist

See detailed checklist: $CHECKLIST_FILE

EOF

# Copy checklist into report
if [ -f "$CHECKLIST_FILE" ]; then
  echo "### Testing Checklist" >> "$VALIDATION_REPORT"
  echo "" >> "$VALIDATION_REPORT"
  grep "^- \[" "$CHECKLIST_FILE" >> "$VALIDATION_REPORT"
  echo "" >> "$VALIDATION_REPORT"
fi

cat >> "$VALIDATION_REPORT" <<EOF

---

## Deployment Readiness

**Status**: $OVERALL_STATUS

EOF

if [ "$READY_FOR_PROD" = "true" ]; then
  cat >> "$VALIDATION_REPORT" <<EOF
All staging validation checks passed:
- ✅ Deployment successful
- ✅ Health checks passing
- $([ "$E2E_STATUS" = "passed" ] && echo "✅" || echo "⚠️ ") E2E tests
- $([ "$LIGHTHOUSE_STATUS" = "passed" ] && echo "✅" || echo "⚠️ ") Lighthouse CI
- ✅ Manual validation complete

**Next step**: Run \`/phase-2-ship\` to deploy to production

EOF
else
  cat >> "$VALIDATION_REPORT" <<EOF
**Blockers:**

EOF

  if [ "$E2E_STATUS" = "failed" ]; then
    echo "- ❌ E2E tests failing" >> "$VALIDATION_REPORT"
  fi

  if [ "$MANUAL_STATUS" = "failed" ]; then
    echo "- ❌ Manual validation failed" >> "$VALIDATION_REPORT"
  fi

  if [ "$LIGHTHOUSE_STATUS" = "failed" ]; then
    echo "- ⚠️  Lighthouse performance below targets" >> "$VALIDATION_REPORT"
  fi

  cat >> "$VALIDATION_REPORT" <<EOF

**Action required**: Fix blockers, redeploy staging, then run \`/validate-staging\` again

EOF
fi

cat >> "$VALIDATION_REPORT" <<EOF
---

*Generated by \`/validate-staging\` command*
EOF

# Copy checklist to feature directory for archival
cp "$CHECKLIST_FILE" "$FEATURE_DIR/staging-validation-checklist.md" 2>/dev/null || true

echo "✅ Validation report created: $VALIDATION_REPORT"
echo ""
```

---

### Phase V.8: Final Output

**Display results and next steps:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$READY_FOR_PROD" = "true" ]; then
  echo "## ✅ Staging Validation Passed"
  echo ""
  echo "**Feature**: $SLUG"
  echo "**Status**: Ready for Production"
  echo ""
  echo "### Validation Summary"
  echo ""
  echo "- ✅ Deployment successful"
  echo "- ✅ Health checks passing"
  echo "- $([ "$E2E_STATUS" = "passed" ] && echo "✅" || echo "⚠️ ") E2E tests"
  echo "- $([ "$LIGHTHOUSE_STATUS" = "passed" ] && echo "✅" || echo "⚠️ ") Lighthouse CI"
  echo "- ✅ Manual validation complete"
  echo ""
  echo "### Staging URLs Tested"
  echo ""
  echo "- Marketing: $STAGING_MARKETING"
  echo "- App: $STAGING_APP"
  echo "- API: $STAGING_API"
  echo ""
  echo "### Report"
  echo ""
  echo "Validation report: $VALIDATION_REPORT"
  echo ""
  echo "### Next Steps"
  echo ""
  echo "Run \`/phase-2-ship\` to deploy to production"
  echo ""
  echo "---"
  echo "**Workflow**: \`... → phase-1-ship → validate-staging ✅ → phase-2-ship (next)\`"

elif [ "$READY_FOR_PROD" = "warning" ]; then
  echo "## ⚠️  Staging Validation Complete (With Warnings)"
  echo ""
  echo "**Feature**: $SLUG"
  echo "**Status**: Review recommended"
  echo ""
  echo "### Warnings"
  echo ""

  if [ "$LIGHTHOUSE_STATUS" = "failed" ]; then
    echo "- ⚠️  Lighthouse performance below targets"
  fi

  if [ "$E2E_STATUS" != "passed" ]; then
    echo "- ⚠️  E2E tests incomplete or skipped"
  fi

  echo ""
  echo "### Report"
  echo ""
  echo "Validation report: $VALIDATION_REPORT"
  echo ""
  echo "### Next Steps"
  echo ""
  echo "1. Review warnings in validation report"
  echo "2. Decide: Fix issues or proceed with warnings"
  echo "3. If proceeding: Run \`/phase-2-ship\`"
  echo ""
  echo "---"
  echo "**Workflow**: \`... → phase-1-ship → validate-staging ⚠️  → phase-2-ship (optional)\`"

else
  echo "## ❌ Staging Validation Failed"
  echo ""
  echo "**Feature**: $SLUG"
  echo "**Status**: Blocked"
  echo ""
  echo "### Blockers"
  echo ""

  if [ "$E2E_STATUS" = "failed" ]; then
    echo "- ❌ E2E tests failing"
  fi

  if [ "$MANUAL_STATUS" = "failed" ]; then
    echo "- ❌ Manual validation failed"
    echo "  Issues: $MANUAL_ISSUES"
  fi

  if [ "$DEPLOY_CONCLUSION" != "success" ]; then
    echo "- ❌ Deployment failures"
  fi

  echo ""
  echo "### Report"
  echo ""
  echo "Validation report: $VALIDATION_REPORT"
  echo ""
  echo "### Next Steps"
  echo ""
  echo "1. Fix issues identified above"
  echo "2. Redeploy to staging (may need to update code and re-run \`/phase-1-ship\`)"
  echo "3. Run \`/validate-staging\` again"
  echo ""
  echo "---"
  echo "**Workflow**: \`... → phase-1-ship → validate-staging ❌ → (fix issues, retry)\`"

  exit 1
fi

echo ""
```

---

## ERROR HANDLING

**If not on main branch:**

This command can run from any branch, but warns if not on main:

```bash
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠️  Not on main branch"
  echo ""
  echo "Current branch: $CURRENT_BRANCH"
  echo ""
  echo "Staging deployments come from main branch."
  echo "Validating latest main deployment (not current branch)"
  echo ""
fi
```

**If no recent staging deployment:**

Already handled in Phase V.0 - will detect and exit with helpful message.

**If deployment still running:**

Already handled in Phase V.1 - will detect and exit with workflow URL.

**If deployment failed:**

Already handled in Phase V.1 - will show failed jobs and exit.

---

## NOTES

**Manual validation importance**: Automated tests validate functionality, but manual testing ensures the UX feels right. This gate prevents shipping features that work technically but feel wrong to users.

**Staging environment**: Staging uses production builds (optimized bundles) but separate databases and infrastructure. This validates production build performance without affecting real users.

**Blocking production**: If validation fails, `/phase-2-ship` should check for recent staging-validation-report.md and refuse to run if status is "Blocked".

**Iteration**: It's normal to iterate 2-3 times on staging validation. Fix issues, redeploy via `/phase-1-ship` (or directly via workflow), validate again.

**Next command**: `/phase-2-ship` (only if validation passed or warnings accepted)

---

## INTEGRATION WITH /phase-2-ship

The `/phase-2-ship` command should validate this report exists and passed:

```bash
# In /phase-2-ship, check validation report
VALIDATION_REPORT="$FEATURE_DIR/staging-validation-report.md"

if [ ! -f "$VALIDATION_REPORT" ]; then
  echo "❌ No staging validation report found"
  echo "Run /validate-staging first"
  exit 1
fi

# Check if validation passed
if grep -q "❌ Blocked" "$VALIDATION_REPORT"; then
  echo "❌ Staging validation failed"
  echo "Fix blockers before shipping to production"
  exit 1
fi
```


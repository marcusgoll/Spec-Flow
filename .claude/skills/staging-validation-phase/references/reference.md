# Staging Validation Phase - Reference Documentation

Complete reference for staging validation procedures, automated test review, rollback testing, manual validation workflows, and production readiness assessment.

## Table of Contents

1. [Feature Detection](#feature-detection)
2. [Deployment Status Verification](#deployment-status-verification)
3. [Health Check Procedures](#health-check-procedures)
4. [Rollback Capability Testing](#rollback-capability-testing)
5. [E2E Test Result Review](#e2e-test-result-review)
6. [Lighthouse CI Analysis](#lighthouse-ci-analysis)
7. [Manual Testing Checklist Generation](#manual-testing-checklist-generation)
8. [Interactive Manual Validation](#interactive-manual-validation)
9. [Validation Report Structure](#validation-report-structure)
10. [Production Readiness Assessment](#production-readiness-assessment)
11. [Error Conditions](#error-conditions)

---

## Feature Detection

**Goal**: Detect which feature was just deployed to staging from recent workflow run.

### Process

```bash
# Get latest staging deployment
LATEST_DEPLOY=$(gh run list \
  --workflow=deploy-staging.yml \
  --branch=main \
  --limit=1 \
  --json databaseId,headSha,conclusion,status,createdAt,displayTitle)

# Extract deployment metadata
RUN_ID=$(echo "$LATEST_DEPLOY" | yq eval '.[0].databaseId')
COMMIT_SHA=$(echo "$LATEST_DEPLOY" | yq eval '.[0].headSha')
DEPLOY_STATUS=$(echo "$LATEST_DEPLOY" | yq eval '.[0].status')
DEPLOY_CONCLUSION=$(echo "$LATEST_DEPLOY" | yq eval '.[0].conclusion')
DEPLOY_TITLE=$(echo "$LATEST_DEPLOY" | yq eval '.[0].displayTitle')
DEPLOY_DATE=$(echo "$LATEST_DEPLOY" | yq eval '.[0].createdAt')

# Extract feature slug from commit message
COMMIT_MSG=$(git log --format=%s -n 1 "$COMMIT_SHA")

# Try to extract slug from commit message patterns
if [[ "$COMMIT_MSG" =~ feat:\ ([a-z0-9-]+) ]]; then
  SLUG="${BASH_REMATCH[1]}"
elif [[ "$COMMIT_MSG" =~ ([a-z0-9-]+):\ ]]; then
  SLUG="${BASH_REMATCH[1]}"
else
  # Fallback: prompt user
  read -p "Enter feature slug manually: " SLUG
fi

# Find feature directory
FEATURE_DIR="specs/$SLUG"
```

### Validation

- Verify deployment exists (not empty or `[]`)
- Confirm feature directory exists at `specs/$SLUG`
- Confirm spec.md exists at `specs/$SLUG/spec.md`

### Error Conditions

**No deployments found**:

```
❌ No staging deployments found

Expected workflow: deploy-staging.yml

Did you run /ship-staging?
```

**Feature directory not found**:

```
❌ Feature directory not found: specs/$SLUG

Available specs:
  feature-001
  feature-002
  ...
```

---

## Deployment Status Verification

**Goal**: Verify deployment completed successfully before validating.

### Process

```bash
# Check if deployment is still running
if [ "$DEPLOY_STATUS" = "in_progress" ] || [ "$DEPLOY_STATUS" = "queued" ]; then
  echo "⏳ Deployment still running"
  echo "Wait for deployment to complete, then run /validate-staging again"
  exit 1
fi

# Check if deployment failed
if [ "$DEPLOY_CONCLUSION" != "success" ]; then
  echo "❌ Deployment failed"

  # Get failed jobs
  FAILED_JOBS=$(gh run view "$RUN_ID" --json jobs --jq '.jobs[] | select(.conclusion == "failure") | .name')

  echo "Failed jobs:"
  echo "$FAILED_JOBS" | sed 's/^/  - /'

  exit 1
fi

# Get job status breakdown
JOBS_JSON=$(gh run view "$RUN_ID" --json jobs)

# Check individual jobs
MARKETING_STATUS=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("deploy-marketing")) | .conclusion' | head -1)
APP_STATUS=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("deploy-app")) | .conclusion' | head -1)
API_STATUS=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("deploy-api")) | .conclusion' | head -1)
SMOKE_STATUS=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("smoke")) | .conclusion' | head -1)
```

### Job Status Display

```
Job Status:
  ✅ deploy-marketing
  ✅ deploy-app
  ✅ deploy-api
  ✅ smoke-tests
```

### Error Conditions

**Deployment still running**:

```
⏳ Deployment still running

Current status: in_progress
Workflow: https://github.com/owner/repo/actions/runs/12345

Wait for deployment to complete, then run /validate-staging again
```

**Deployment failed**:

```
❌ Deployment failed

Conclusion: failure

Failed jobs:
  - deploy-app

Fix deployment failures before validating staging
```

---

## Health Check Procedures

**Goal**: Verify staging endpoints are responding correctly.

### Staging URLs

```bash
STAGING_MARKETING="https://staging.{domain}.com"
STAGING_APP="https://app.staging.{domain}.com"
STAGING_API="https://api.staging.{domain}.com"
```

### Health Checks

```bash
# Marketing health
MARKETING_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_MARKETING/health" || echo "000")

# App health
APP_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_APP/health" || echo "000")

# API health
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$STAGING_API/api/v1/health/healthz" || echo "000")
```

### Success Criteria

All health checks return HTTP 200 OK:

```
Checking staging endpoints...

  Marketing (https://staging.{domain}.com/health)... ✅
  App (https://app.staging.{domain}.com/health)... ✅
  API (https://api.staging.{domain}.com/api/v1/health/healthz)... ✅

✅ All staging endpoints healthy
```

### Failure Handling

If any endpoint fails:

```
⚠️  Some health checks failed

Deployment may not be fully ready. Continue anyway? (y/N)
```

User can choose to:

- **N** (default): Cancel validation, fix health checks
- **y**: Continue despite unhealthy endpoints (not recommended)

---

## Rollback Capability Testing

**Goal**: Verify rollback works BEFORE allowing production deployment. This is critical - if rollback is broken, production incidents cannot be recovered.

### Process Overview

1. Load current and previous deployment IDs
2. Roll back to previous deployment
3. Verify rollback succeeded (check live URL)
4. Roll forward to current deployment
5. Update quality gate in state.yaml

### Implementation

```bash
# Load deployment metadata
METADATA_FILE="$FEATURE_DIR/deployment-metadata.json"

if [ ! -f "$METADATA_FILE" ]; then
  echo "⚠️  Deployment metadata not found"
  echo "   Skipping rollback test (first deployment or metadata missing)"
  ROLLBACK_TESTED=false
else
  # Extract current deployment ID
  CURRENT_APP_ID=$(yq eval '.staging.deployments.app // empty' "$METADATA_FILE")

  # Get previous deployment from state.yaml
  STATE_FILE="$FEATURE_DIR/state.yaml"
  if [ -f "$STATE_FILE" ]; then
    PREV_APP_ID=$(yq eval '.deployment.staging.previous_deployment_ids.app // empty' "$STATE_FILE")
  fi

  if [ -z "$PREV_APP_ID" ]; then
    echo "ℹ️  No previous deployment found (first deployment to staging)"
    echo "   Skipping rollback test"
    ROLLBACK_TESTED=true  # Not a blocker for first deployment
  else
    echo "Current deployment: $CURRENT_APP_ID"
    echo "Previous deployment: $PREV_APP_ID"

    # Step 1: Rollback to previous deployment
    echo "Step 1: Rolling back to previous deployment..."

    # Verify Vercel CLI available
    if ! command -v vercel &> /dev/null; then
      echo "⚠️  Vercel CLI not found"
      echo "   Install: npm install -g vercel"
      echo ""
      echo "🚨 BLOCKER: Cannot verify rollback capability"
      exit 1
    fi

    # Perform rollback
    ROLLBACK_OUTPUT=$(vercel alias set "$PREV_APP_ID" "$STAGING_APP" --token="$VERCEL_TOKEN" 2>&1)
    ROLLBACK_EXIT_CODE=$?

    if [ $ROLLBACK_EXIT_CODE -ne 0 ]; then
      echo "❌ ROLLBACK COMMAND FAILED"
      echo "Output:"
      echo "$ROLLBACK_OUTPUT" | sed 's/^/  /'
      echo ""
      echo "🚨 BLOCKER: Rollback capability broken"
      echo "Without working rollback, production incidents cannot be recovered."
      exit 1
    fi

    echo "✅ Rollback command succeeded"

    # Step 2: Verify rollback (wait for DNS propagation)
    echo "Step 2: Verifying rollback (waiting 15s for DNS propagation)..."
    sleep 15

    # Check if previous version is live
    LIVE_RESPONSE=$(curl -sI "$STAGING_APP" 2>&1)
    LIVE_VERCEL_ID=$(echo "$LIVE_RESPONSE" | grep -i "x-vercel-id" | awk '{print $2}' | tr -d '\r\n')

    # Extract deployment ID from URL for comparison
    PREV_ID=$(echo "$PREV_APP_ID" | sed 's|https://||' | cut -d. -f1)

    if [[ "$LIVE_RESPONSE" == *"$PREV_ID"* ]] || [[ "$LIVE_VERCEL_ID" == *"$PREV_ID"* ]]; then
      echo "✅ Rollback verified (previous version is live)"

      # Step 3: Roll forward to current version
      echo "Step 3: Rolling forward to current deployment..."

      ROLLFORWARD_OUTPUT=$(vercel alias set "$CURRENT_APP_ID" "$STAGING_APP" --token="$VERCEL_TOKEN" 2>&1)
      ROLLFORWARD_EXIT_CODE=$?

      if [ $ROLLFORWARD_EXIT_CODE -ne 0 ]; then
        echo "⚠️  ROLL-FORWARD FAILED"
        echo "🚨 CRITICAL: Staging is now on old deployment"
        echo "   Manual intervention required:"
        echo "   vercel alias set $CURRENT_APP_ID $STAGING_APP"
        exit 1
      fi

      sleep 10  # Wait for DNS
      echo "✅ Rolled forward to current version"

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✅ ROLLBACK CAPABILITY VERIFIED"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Rollback test results:"
      echo "  ✅ Rollback command works"
      echo "  ✅ Previous deployment accessible"
      echo "  ✅ Alias switching functional"
      echo "  ✅ Roll-forward works"
      echo ""
      echo "Production deployment can proceed with confidence."

      ROLLBACK_TESTED=true

      # Update workflow state with rollback test result
      GATE_DATA='{"passed": true, "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "previous_deployment": "'$PREV_APP_ID'", "current_deployment": "'$CURRENT_APP_ID'"}'
      # Update quality gate using workflow-state.sh if available

    else
      echo "❌ ROLLBACK VERIFICATION FAILED"
      echo "Expected previous deployment: $PREV_ID"
      echo "Got Vercel ID: ${LIVE_VERCEL_ID:-[not found]}"
      echo ""
      echo "🚨 BLOCKER: Rollback command succeeded but verification failed"
      echo "Recommendation: Wait 1-2 minutes and re-run /validate-staging"
      exit 1
    fi
  fi
fi
```

### Rollback Test Outcomes

**Success**:

- Rollback command succeeds
- Previous deployment goes live (verified via headers)
- Roll-forward succeeds
- Quality gate updated in state.yaml

**Blocker - Vercel CLI missing**:

```
🚨 BLOCKER: Cannot verify rollback capability
Install Vercel CLI and re-run /validate-staging
```

**Blocker - Rollback command failed**:

```
🚨 BLOCKER: Rollback capability broken

Possible causes:
  - VERCEL_TOKEN not set or invalid
  - Previous deployment ID no longer exists
  - Vercel alias permissions issue

Fix rollback capability before proceeding to production.
```

**Blocker - Rollback verification failed**:

```
🚨 BLOCKER: Rollback command succeeded but verification failed

Possible causes:
  - DNS propagation delay (try waiting longer)
  - Vercel alias not applied correctly
  - Staging URL pointing to wrong deployment

Recommendation: Wait 1-2 minutes and re-run /validate-staging
```

### First Deployment Handling

For first deployment (no previous deployment exists):

```
ℹ️  No previous deployment found (first deployment to staging)
   Skipping rollback test

ROLLBACK_TESTED=true  # Not a blocker for first deployment
```

---

## E2E Test Result Review

**Goal**: Parse and report E2E test results from GitHub Actions workflow.

### Process

```bash
# Find E2E job in workflow
E2E_JOB=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("e2e") or contains("E2E")) | {name: .name, conclusion: .conclusion, htmlUrl: .html_url} | @json' | head -1)

if [ -z "$E2E_JOB" ] || [ "$E2E_JOB" = "null" ]; then
  echo "⚠️  No E2E tests found in workflow"
  E2E_STATUS="not_run"
else
  E2E_NAME=$(echo "$E2E_JOB" | yq eval '.name')
  E2E_CONCLUSION=$(echo "$E2E_JOB" | yq eval '.conclusion')
  E2E_URL=$(echo "$E2E_JOB" | yq eval '.htmlUrl')

  echo "E2E Job: $E2E_NAME"
  echo "Status: $E2E_CONCLUSION"
  echo "URL: $E2E_URL"

  if [ "$E2E_CONCLUSION" = "success" ]; then
    E2E_STATUS="passed"
    echo "✅ E2E tests passed"
  elif [ "$E2E_CONCLUSION" = "failure" ]; then
    E2E_STATUS="failed"
    echo "❌ E2E tests failed"

    # Get failure details from logs
    E2E_LOGS=$(gh run view "$RUN_ID" --log | grep -A 5 "e2e" | grep -i "error\|fail" | head -10)

    if [ -n "$E2E_LOGS" ]; then
      echo "Failure summary:"
      echo "$E2E_LOGS" | sed 's/^/  /'
    fi

    echo "🚫 BLOCKER: E2E tests must pass before production"
    echo "Fix E2E failures and redeploy to staging"
    exit 1
  else
    E2E_STATUS="$E2E_CONCLUSION"
    echo "⚠️  E2E status: $E2E_CONCLUSION"
  fi
fi
```

### E2E Status Values

- `passed` - All E2E tests passed (✅ Allow production)
- `failed` - E2E tests failed (🚫 BLOCK production)
- `not_run` - No E2E job found (⚠️ Warning)
- Other - Unexpected status (⚠️ Warning)

### Blocker Condition

E2E test failures are **blocking** - production deployment cannot proceed:

```
🚫 BLOCKER: E2E tests must pass before production

Fix E2E failures and redeploy to staging
```

---

## Lighthouse CI Analysis

**Goal**: Parse and report Lighthouse CI performance results.

### Process

```bash
# Find Lighthouse job in workflow
LIGHTHOUSE_JOB=$(echo "$JOBS_JSON" | yq eval '.jobs[] | select(.name | contains("lighthouse") or contains("Lighthouse")) | {name: .name, conclusion: .conclusion, htmlUrl: .html_url} | @json' | head -1)

if [ -z "$LIGHTHOUSE_JOB" ] || [ "$LIGHTHOUSE_JOB" = "null" ]; then
  echo "⚠️  No Lighthouse CI found in workflow"
  LIGHTHOUSE_STATUS="not_run"
else
  LIGHTHOUSE_NAME=$(echo "$LIGHTHOUSE_JOB" | yq eval '.name')
  LIGHTHOUSE_CONCLUSION=$(echo "$LIGHTHOUSE_JOB" | yq eval '.conclusion')
  LIGHTHOUSE_URL=$(echo "$LIGHTHOUSE_JOB" | yq eval '.htmlUrl')

  echo "Lighthouse Job: $LIGHTHOUSE_NAME"
  echo "Status: $LIGHTHOUSE_CONCLUSION"
  echo "URL: $LIGHTHOUSE_URL"

  if [ "$LIGHTHOUSE_CONCLUSION" = "success" ]; then
    LIGHTHOUSE_STATUS="passed"

    # Try to extract scores from logs
    LIGHTHOUSE_LOGS=$(gh run view "$RUN_ID" --log | grep -E "Performance|Accessibility|score" | head -20)

    if [ -n "$LIGHTHOUSE_LOGS" ]; then
      echo "Lighthouse scores:"
      echo "$LIGHTHOUSE_LOGS" | sed 's/^/  /'
    fi

    # Check for performance warnings
    PERF_WARNINGS=$(echo "$LIGHTHOUSE_LOGS" | grep -i "warning\|below.*target" || echo "")

    if [ -n "$PERF_WARNINGS" ]; then
      echo "⚠️  Performance warnings:"
      echo "$PERF_WARNINGS" | sed 's/^/  /'
      echo "Targets: Performance >85, Accessibility >95"

      read -p "Continue with performance warnings? (y/N): " CONTINUE_PERF
      if [ "$CONTINUE_PERF" != "y" ]; then
        echo "Validation cancelled"
        exit 1
      fi
    else
      echo "✅ Lighthouse CI passed"
    fi

  elif [ "$LIGHTHOUSE_CONCLUSION" = "failure" ]; then
    LIGHTHOUSE_STATUS="failed"
    echo "❌ Lighthouse CI failed"

    # Get failure details
    LIGHTHOUSE_ERRORS=$(gh run view "$RUN_ID" --log | grep -A 3 "lighthouse" | grep -i "error\|fail" | head -10)

    if [ -n "$LIGHTHOUSE_ERRORS" ]; then
      echo "Failures:"
      echo "$LIGHTHOUSE_ERRORS" | sed 's/^/  /'
    fi

    echo "⚠️  Lighthouse failures detected"
    echo "Recommended: Fix performance issues before production"
    read -p "Continue anyway? (y/N): " CONTINUE_LIGHTHOUSE

    if [ "$CONTINUE_LIGHTHOUSE" != "y" ]; then
      echo "Validation cancelled"
      exit 1
    fi
  else
    LIGHTHOUSE_STATUS="$LIGHTHOUSE_CONCLUSION"
    echo "⚠️  Lighthouse status: $LIGHTHOUSE_CONCLUSION"
  fi
fi
```

### Performance Targets

- **Performance**: ≥85
- **Accessibility**: ≥95
- **First Contentful Paint (FCP)**: <1500ms
- **Time to Interactive (TTI)**: <3000ms
- **Largest Contentful Paint (LCP)**: <2500ms

### Lighthouse Status Values

- `passed` - Performance targets met (✅ Recommended)
- `failed` - Performance below targets (⚠️ Warning - can continue with user confirmation)
- `not_run` - No Lighthouse job found (ℹ️ Info)

### Warning Handling

Lighthouse failures are **warnings**, not blockers. User can choose to:

- Fix performance issues and redeploy
- Continue with warnings (not recommended)

---

## Manual Testing Checklist Generation

**Goal**: Generate interactive testing checklist from spec.md acceptance criteria and user flows.

### Process

```bash
SPEC_FILE="$FEATURE_DIR/spec.md"

# Extract Acceptance Criteria section
ACCEPTANCE_START=$(grep -n "## Acceptance Criteria" "$SPEC_FILE" | cut -d: -f1 | head -1)

if [ -z "$ACCEPTANCE_START" ]; then
  ACCEPTANCE_ITEMS=""
else
  # Extract criteria until next ## section
  ACCEPTANCE_END=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

  if [ -z "$ACCEPTANCE_END" ]; then
    ACCEPTANCE_ITEMS=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE")
  else
    ACCEPTANCE_ITEMS=$(tail -n +$((ACCEPTANCE_START + 1)) "$SPEC_FILE" | head -n $((ACCEPTANCE_END - 1)))
  fi

  # Filter to just list items
  ACCEPTANCE_ITEMS=$(echo "$ACCEPTANCE_ITEMS" | grep "^- " || echo "")
fi

# Extract User Flows section
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
```

### Checklist Template

Create checklist at `/tmp/staging-validation-checklist-$SLUG.md`:

```markdown
# Staging Validation Checklist: {slug}

**Date**: {timestamp}
**Deployment**: {run_id}
**Commit**: {commit_sha}

---

## Staging URLs

- **Marketing**: https://staging.{domain}.com
- **App**: https://app.staging.{domain}.com
- **API**: https://api.staging.{domain}.com/docs

---

## Acceptance Criteria

- [ ] {acceptance criterion 1}
- [ ] {acceptance criterion 2}
      ...

---

## User Flows

- [ ] {user flow 1}
- [ ] {user flow 2}
      ...

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
```

### Fallback Content

If spec.md doesn't have structured acceptance criteria or user flows:

**Acceptance Criteria fallback**:

```markdown
- [ ] Feature works as described in spec.md
```

**User Flows fallback**:

```markdown
- [ ] Primary user flow works end-to-end
```

---

## Interactive Manual Validation

**Goal**: Guide user through manual testing with checklist.

### Process

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MANUAL TESTING REQUIRED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Please complete manual testing on staging:"
echo ""
echo "  1. Open staging URLs in browser"
echo "  2. Test all items in checklist above"
echo "  3. Note any issues found"

# Open checklist in editor
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

# Wait for user to complete testing
read -p "Have you completed manual testing? (y/N): " TESTING_COMPLETE

if [ "$TESTING_COMPLETE" != "y" ]; then
  echo "⏸️  Manual testing incomplete"
  echo "Complete testing, then run /validate-staging again"
  echo "Checklist saved: $CHECKLIST_FILE"
  exit 0
fi

# Check for issues
read -p "Were any issues found? (y/N): " ISSUES_FOUND

if [ "$ISSUES_FOUND" = "y" ]; then
  echo "Describe the issues found (or reference checklist):"
  read -p "> " ISSUE_DESCRIPTION

  if [ -z "$ISSUE_DESCRIPTION" ]; then
    ISSUE_DESCRIPTION="See checklist: $CHECKLIST_FILE"
  fi

  MANUAL_STATUS="failed"
  MANUAL_ISSUES="$ISSUE_DESCRIPTION"

  echo "❌ Manual testing failed"
else
  MANUAL_STATUS="passed"
  MANUAL_ISSUES="None - all checks passed ✅"

  echo "✅ Manual testing passed"
fi
```

### Manual Testing Outcomes

**Passed**:

```
MANUAL_STATUS="passed"
MANUAL_ISSUES="None - all checks passed ✅"
```

**Failed with issues**:

```
MANUAL_STATUS="failed"
MANUAL_ISSUES="Login button not working on mobile"
```

**Incomplete** (user exits early):

```
⏸️  Manual testing incomplete

Complete testing, then run /validate-staging again
Checklist saved: /tmp/staging-validation-checklist-{slug}.md
```

---

## Validation Report Structure

**Goal**: Generate comprehensive staging-validation-report.md with all test results.

### Report Template

Create report at `specs/{slug}/staging-validation-report.md`:

```markdown
# Staging Validation Report

**Date**: {validated_date}
**Feature**: {slug}
**Status**: {overall_status}

---

## Deployment Info

**Workflow**: https://github.com/{owner}/{repo}/actions/runs/{run_id}
**Commit**: {commit_sha}
**Branch**: main
**Deployed**: {deploy_date}

---

## Staging URLs

- **Marketing**: {staging_marketing}
- **App**: {staging_app}
- **API**: {staging_api}

---

## Automated Tests

### E2E Tests

**Status**: {e2e_status_with_emoji}

{e2e_details}

**Report**: {e2e_url}

---

### Lighthouse CI

**Status**: {lighthouse_status_with_emoji}

{lighthouse_details}

**Targets**:

- Performance: ≥85
- Accessibility: ≥95
- FCP: <1500ms
- TTI: <3000ms
- LCP: <2500ms

**Report**: {lighthouse_url}

---

## Manual Validation

**Status**: {manual_status_with_emoji}
**Tested by**: {user_name}
**Tested on**: {validated_date}

### Issues Found

{manual_issues}

### Checklist

See detailed checklist: {checklist_file}

### Testing Checklist

{checklist_items}

---

## Deployment Readiness

**Status**: {overall_status}

{readiness_details}

**Next step**: Run `/ship-prod` to deploy to production

---

_Generated by `/validate-staging` command_
```

### Overall Status Determination

```bash
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
```

### Report Sections by Status

**Ready for Production** (`READY_FOR_PROD="true"`):

```markdown
All staging validation checks passed:

- ✅ Deployment successful
- ✅ Health checks passing
- ✅ E2E tests
- ✅ Lighthouse CI
- ✅ Manual validation complete

**Next step**: Run `/ship-prod` to deploy to production
```

**Blocked** (`READY_FOR_PROD="false"`):

```markdown
**Blockers:**

- ❌ E2E tests failing
- ❌ Manual validation failed

**Action required**: Fix blockers, redeploy staging, then run `/validate-staging` again
```

**Review Required** (`READY_FOR_PROD="warning"`):

```markdown
**Warnings:**

- ⚠️ Lighthouse performance below targets

**Action required**: Review warnings, fix if critical, or proceed with caution
```

---

## Production Readiness Assessment

**Goal**: Determine if feature is ready for production deployment.

### Decision Matrix

| E2E Status | Lighthouse Status | Manual Status | Overall Status          | Production Ready |
| ---------- | ----------------- | ------------- | ----------------------- | ---------------- |
| passed     | passed            | passed        | ✅ Ready for Production | true             |
| passed     | failed            | passed        | ⚠️ Review Required      | warning          |
| failed     | any               | any           | ❌ Blocked              | false            |
| any        | any               | failed        | ❌ Blocked              | false            |
| not_run    | passed            | passed        | ⚠️ Review Required      | warning          |
| not_run    | not_run           | passed        | ⚠️ Review Required      | warning          |

### Blocking Conditions

Production deployment is **blocked** if:

- E2E tests failed
- Manual validation failed
- Deployment failed
- Rollback capability test failed

### Warning Conditions

Production deployment has **warnings** if:

- Lighthouse performance below targets
- E2E tests not run
- Lighthouse not run

### Final Output Examples

**Ready for Production**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VALIDATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ Staging Validation Passed

**Feature**: feature-123
**Status**: Ready for Production

### Validation Summary

- ✅ Deployment successful
- ✅ Health checks passing
- ✅ E2E tests
- ✅ Lighthouse CI
- ✅ Manual validation complete

### Staging URLs Tested

- Marketing: https://staging.cfipros.com
- App: https://app.staging.cfipros.com
- API: https://api.staging.cfipros.com

### Report

Validation report: specs/feature-123/staging-validation-report.md

### Next Steps

Run `/ship-prod` to deploy to production

---
**Workflow**: `... → ship-staging → validate-staging ✅ → ship-prod (next)`
```

**Blocked**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VALIDATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ❌ Staging Validation Failed

**Feature**: feature-123
**Status**: Blocked

### Blockers

- ❌ E2E tests failing
- ❌ Manual validation failed
  Issues: Login button not working on mobile

### Report

Validation report: specs/feature-123/staging-validation-report.md

### Next Steps

1. Fix issues identified above
2. Redeploy to staging (may need to update code and re-run `/ship-staging`)
3. Run `/validate-staging` again

---
**Workflow**: `... → ship-staging → validate-staging ❌ → (fix issues, retry)`
```

**Review Required**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VALIDATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ⚠️  Staging Validation Complete (With Warnings)

**Feature**: feature-123
**Status**: Review recommended

### Warnings

- ⚠️  Lighthouse performance below targets

### Report

Validation report: specs/feature-123/staging-validation-report.md

### Next Steps

1. Review warnings in validation report
2. Decide: Fix issues or proceed with warnings
3. If proceeding: Run `/ship-prod`

---
**Workflow**: `... → ship-staging → validate-staging ⚠️  → ship-prod (optional)`
```

---

## Error Conditions

### Not on Main Branch

Command can run from any branch, but warns:

```bash
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠️  Not on main branch"
  echo ""
  echo "Current branch: $CURRENT_BRANCH"
  echo ""
  echo "Staging deployments come from main branch."
  echo "Validating latest main deployment (not current branch)"
fi
```

### No Recent Staging Deployment

```
❌ No staging deployments found

Expected workflow: deploy-staging.yml

Did you run /ship-staging?
```

### Deployment Still Running

```
⏳ Deployment still running

Current status: in_progress
Workflow: https://github.com/owner/repo/actions/runs/12345

Wait for deployment to complete, then run /validate-staging again
```

### Deployment Failed

```
❌ Deployment failed

Conclusion: failure

Failed jobs:
  - deploy-app

Fix deployment failures before validating staging

Workflow: https://github.com/owner/repo/actions/runs/12345
```

### Feature Directory Not Found

```
❌ Feature directory not found: specs/feature-123

Available specs:
  feature-001
  feature-002
  feature-003
  ...
```

### spec.md Not Found

```
❌ spec.md not found: specs/feature-123/spec.md
```

### Rollback Test Failures

See [Rollback Capability Testing](#rollback-capability-testing) section for detailed error conditions.

---

## Integration with /ship-prod

The `/ship-prod` command should verify staging validation passed:

```bash
# In /ship-prod, check validation report
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

---

## Workflow State Integration

After successful validation, update state.yaml:

```yaml
workflow:
  manual_gates:
    staging_validation:
      status: approved
      timestamp: 2025-11-20T10:30:00Z
      validated_by: John Doe
      issues_found: none

quality_gates:
  rollback_capability:
    passed: true
    timestamp: 2025-11-20T10:25:00Z
    previous_deployment: "prev-deploy-id.vercel.app"
    current_deployment: "current-deploy-id.vercel.app"
```

---

## Best Practices

1. **Run after every staging deployment** - Always validate before promoting to production
2. **Complete all checklist items** - Don't skip manual testing sections
3. **Document issues thoroughly** - Help future debugging by noting specific problems
4. **Test rollback capability** - Critical for production incident recovery
5. **Review automated test failures** - Don't ignore E2E or Lighthouse warnings
6. **Iterate 2-3 times if needed** - Normal to find and fix issues in staging
7. **Save checklist for records** - Keep completed checklist in feature directory

---

## Philosophy

**Staging is the final checkpoint before production.** This command combines:

- **Automated validation** (E2E, Lighthouse, health checks)
- **Rollback verification** (ensures production recovery capability)
- **Manual validation** (ensures UX quality beyond automated tests)

Together, these checks prevent shipping features that work technically but feel wrong to users, or features that would be impossible to roll back in a production incident.

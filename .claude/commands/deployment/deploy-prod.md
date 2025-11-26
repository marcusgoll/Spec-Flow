---
name: deploy-prod
description: Deploy feature directly to production by triggering GitHub Actions workflow, monitoring deployment, extracting rollback IDs, and verifying health
internal: true
argument-hint: (automatically called by /ship)
allowed-tools:
  [
    Read,
    Write,
    Edit,
    Grep,
    Bash(git *),
    Bash(gh *),
    Bash(yq *),
    Bash(jq *),
    Bash(curl *),
    Bash(python .spec-flow/*),
    Bash(sleep *),
    Bash(ls *),
    Bash(cat *),
    Bash(test *),
    Bash(grep *),
    TodoWrite,
  ]
---

> **⚠️ INTERNAL COMMAND**: This command is automatically called by `/ship` when deployment model is `direct-prod`.
> Most users should use `/ship` instead of calling this directly.

# /deploy-prod - Direct Production Deployment

<context>
**Current Feature Directory**: !`find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1 2>$null || echo "none"`

**Workflow State**: @specs/\*/state.yaml

**Current Git Branch**: !`git branch --show-current 2>$null || echo "none"`

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Uncommitted Changes**: !`git diff --quiet && git diff --cached --quiet && echo "none" || echo "DETECTED"`

**Production Workflows**:

- deploy-production.yml: !`test -f .github/workflows/deploy-production.yml && echo "exists" || echo "missing"`
- deploy.yml: !`test -f .github/workflows/deploy.yml && echo "exists" || echo "missing"`

**GitHub CLI Status**: !`gh auth status 2>$null | head -1 || echo "not authenticated"`

**Previous Phases**:

- Pre-flight: !`yq eval '.quality_gates.pre_flight.passed' specs/*/state.yaml 2>$null || echo "unknown"`
- Optimize: !`yq eval '.phases.optimize.status' specs/*/state.yaml 2>$null || echo "unknown"`

**Platform Detection**:

- Vercel: !`test -f vercel.json && echo "yes" || test -f .vercel && echo "yes" || echo "no"`
- Netlify: !`test -f netlify.toml && echo "yes" || echo "no"`
- Railway: !`test -f railway.json && echo "yes" || echo "no"`
  </context>

<objective>
Deploy feature directly to production without staging validation for projects using the `direct-prod` deployment model.

**Purpose**: Single-environment deployment for simple applications or projects without staging infrastructure.

**Risk Level**: 🔴 HIGH - Deploys directly to production without staging validation

**When Used**: Automatically called by `/ship` when:

- Git remote exists
- No staging branch configured
- No `.github/workflows/deploy-staging.yml` present

**Prerequisites** (verified before execution):

- `/implement` phase complete
- `/optimize` phase complete
- Pre-flight validation passed
- Production workflow file exists with `workflow_dispatch` trigger

**Deployment Flow**:

1. Pre-deployment safety checks
2. Trigger GitHub Actions production workflow
3. Monitor deployment progress
4. Extract deployment IDs for rollback capability
5. Verify production health checks
6. Generate production report with rollback instructions

**Timing**: 5-10 minutes (depends on deployment platform and build time)
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent production deployment failures.

1. **Never assume production workflow file location**

   - Check both `.github/workflows/deploy-production.yml` and `.github/workflows/deploy.yml`
   - If neither exists, FAIL with clear error message
   - Don't proceed with deployment without confirmed workflow file

2. **Verify uncommitted changes before deploying**

   - Always run `git diff --quiet && git diff --cached --quiet`
   - If uncommitted changes detected, FAIL immediately
   - Production must deploy from clean working tree

3. **Extract actual deployment IDs from platform output**

   - Parse deployment IDs from actual `gh run view` or platform API output
   - Never fabricate deployment IDs (needed for rollback)
   - If ID extraction fails, record as "unknown" in report (don't invent)

4. **Quote actual health check responses**

   - Run actual `curl` commands to verify endpoints
   - Report actual HTTP status codes from responses
   - Don't claim "200 OK" without actual curl verification

5. **Read state.yaml for prerequisite verification**

   - Check actual `quality_gates.pre_flight.passed` value
   - Check actual `phases.optimize.status` value
   - If prerequisites not met, FAIL with specific missing requirement

6. **Generate production report from actual data**
   - Production URL from actual deployment output (not guessed)
   - Deployment ID from actual platform response (not fabricated)
   - Health check results from actual curl output (not assumed)
   - Rollback instructions based on actual platform detected (not generic)

**Why this matters**: False assumptions in production deployment cause outages. Accurate verification of actual state prevents production incidents.

---

<process>

### Step 1: Load Feature Context and Verify Prerequisites

**Load feature directory**:

```bash
FEATURE_DIR=$(find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1)
```

**Verify workflow state file exists**:

```bash
test -f "$FEATURE_DIR/state.yaml" || (echo "❌ No workflow state found" && exit 1)
```

**Update workflow phase to in_progress**:

```bash
python .spec-flow/scripts/bash/workflow-state.sh update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "in_progress"
```

**Display deployment banner**:

```
🚀 Direct Production Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  WARNING: Deploying directly to production
   No staging environment for validation
```

### Step 2: Run Pre-Deployment Safety Checks

**Purpose**: Final safety verification before production deployment

**Check 1: Pre-flight validation passed**

```bash
yq eval '.quality_gates.pre_flight.passed == true' "$FEATURE_DIR/state.yaml"
```

- If not true: Display "❌ Pre-flight validation not completed or failed" and EXIT

**Check 2: Optimize phase completed**

```bash
yq eval '.phases.optimize.status == "completed"' "$FEATURE_DIR/state.yaml"
```

- If not completed: Display "❌ Optimization phase not completed" and EXIT

**Check 3: Production workflow exists**

Check for workflow files in this order:

1. `.github/workflows/deploy-production.yml`
2. `.github/workflows/deploy.yml`

```bash
if [ -f ".github/workflows/deploy-production.yml" ]; then
  PROD_WORKFLOW="deploy-production.yml"
elif [ -f ".github/workflows/deploy.yml" ]; then
  PROD_WORKFLOW="deploy.yml"
else
  echo "❌ No production deployment workflow found"
  echo "   Expected: .github/workflows/deploy-production.yml or .github/workflows/deploy.yml"
  exit 1
fi
```

**Check 4: Workflow has workflow_dispatch trigger**

```bash
grep -q "workflow_dispatch:" ".github/workflows/$PROD_WORKFLOW"
```

- If not found: Display "❌ Workflow missing 'on: workflow_dispatch' trigger" and EXIT
- Required for manual deployment via gh CLI

**Check 5: No uncommitted changes**

```bash
git diff --quiet && git diff --cached --quiet
```

- If changes detected:

  ```
  ❌ Uncommitted changes detected

  Production deployments must be from a clean working tree.

  Fix options:
    1. Commit changes: git add . && git commit -m 'chore: prepare for deployment'
    2. Stash changes: git stash
    3. Discard changes: git restore .
  ```

  EXIT immediately

**If all checks pass**:

```
✅ Pre-flight validation passed
✅ Optimization complete
✅ Production workflow found with dispatch trigger
✅ Working tree clean

✅ All pre-deployment checks passed
```

**If any check fails**: Update workflow phase to "failed" and EXIT

### Step 3: Trigger Production Deployment

**Purpose**: Trigger GitHub Actions workflow for production deployment

**Get current branch**:

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"
```

**Push to remote if needed**:

```bash
git rev-parse "origin/$CURRENT_BRANCH" >/dev/null 2>&1
```

- If remote branch doesn't exist:
  ```bash
  echo "📤 Pushing branch to remote..."
  git push -u origin "$CURRENT_BRANCH"
  ```

**Trigger GitHub Actions workflow**:

```bash
echo "🚀 Triggering production deployment workflow..."
gh workflow run "$PROD_WORKFLOW" --ref "$CURRENT_BRANCH"
```

**Wait for workflow run to appear** (GitHub API delay):

```bash
echo "⏳ Waiting for workflow run to start..."
sleep 5
```

**Get workflow run ID**:

```bash
RUN_ID=$(gh run list --workflow="$PROD_WORKFLOW" --branch="$CURRENT_BRANCH" --limit=1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
  echo "❌ Failed to get workflow run ID"
  echo "   Check GitHub Actions: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions"
  exit 1
fi

echo "Workflow run ID: $RUN_ID"
echo "Monitoring: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID"
```

### Step 4: Monitor Deployment Progress

**Purpose**: Watch GitHub Actions workflow until completion

**Monitor workflow run**:

```bash
echo ""
echo "📊 Monitoring deployment progress..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gh run watch "$RUN_ID" --exit-status
DEPLOY_EXIT_CODE=$?
```

**If deployment fails** (exit code != 0):

```bash
if [ "$DEPLOY_EXIT_CODE" -ne 0 ]; then
  echo ""
  echo "❌ Production deployment FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "View logs: gh run view $RUN_ID --log"
  echo "Workflow URL: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RUN_ID"

  # Update workflow state
  python .spec-flow/scripts/bash/workflow-state.sh update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "failed"

  # Generate failure report
  python .spec-flow/scripts/spec-cli.py generate-failure-report \
    --feature-dir "$FEATURE_DIR" \
    --phase "deploy-prod" \
    --run-id "$RUN_ID"

  echo ""
  echo "Failure report: $FEATURE_DIR/production-deployment-failure.md"

  exit 1
fi
```

**If deployment succeeds**:

```
✅ Production deployment completed successfully
```

### Step 5: Extract Deployment IDs for Rollback

**Purpose**: Extract platform-specific deployment IDs needed for rollback operations

**Get deployment logs**:

```bash
gh run view "$RUN_ID" --log > "$FEATURE_DIR/production-deploy.log"
```

**Platform-specific ID extraction**:

**If Vercel detected** (vercel.json exists):

```bash
# Extract deployment URL from Vercel output
PROD_URL=$(grep -oP 'https://[a-zA-Z0-9-]+\.vercel\.app' "$FEATURE_DIR/production-deploy.log" | tail -1)

# Extract deployment ID from URL (before .vercel.app)
DEPLOYMENT_ID=$(echo "$PROD_URL" | grep -oP 'https://\K[a-zA-Z0-9-]+(?=\.vercel\.app)')

if [ -n "$DEPLOYMENT_ID" ]; then
  echo "Vercel Deployment ID: $DEPLOYMENT_ID"
  echo "Production URL: $PROD_URL"
else
  echo "⚠️  Could not extract Vercel deployment ID from logs"
  DEPLOYMENT_ID="unknown"
  PROD_URL="unknown"
fi
```

**If Netlify detected** (netlify.toml exists):

```bash
# Extract Netlify deploy ID from logs
DEPLOYMENT_ID=$(grep -oP 'Deploy ID: \K[a-f0-9]+' "$FEATURE_DIR/production-deploy.log" | tail -1)

# Extract production URL
PROD_URL=$(grep -oP 'https://[a-zA-Z0-9-]+\.netlify\.app' "$FEATURE_DIR/production-deploy.log" | tail -1)

if [ -n "$DEPLOYMENT_ID" ]; then
  echo "Netlify Deployment ID: $DEPLOYMENT_ID"
  echo "Production URL: $PROD_URL"
else
  echo "⚠️  Could not extract Netlify deployment ID from logs"
  DEPLOYMENT_ID="unknown"
  PROD_URL="unknown"
fi
```

**If Railway detected** (railway.json exists):

```bash
# Extract Railway deployment ID
DEPLOYMENT_ID=$(grep -oP 'Deployment: \K[a-f0-9-]+' "$FEATURE_DIR/production-deploy.log" | tail -1)

# Railway doesn't always expose deployment ID in logs
if [ -z "$DEPLOYMENT_ID" ]; then
  echo "⚠️  Railway deployment ID not available in logs"
  DEPLOYMENT_ID="unknown"
fi

PROD_URL="See Railway dashboard"
```

**If custom platform** (no recognized config):

```bash
echo "ℹ️  Custom deployment platform detected"
echo "   Manual extraction of deployment ID may be required"
DEPLOYMENT_ID="see-logs"
PROD_URL="see-workflow-output"
```

**Save deployment metadata to state.yaml**:

```bash
yq eval -i ".deployment.production.url = \"$PROD_URL\"" "$FEATURE_DIR/state.yaml"
yq eval -i ".deployment.production.deployment_id = \"$DEPLOYMENT_ID\"" "$FEATURE_DIR/state.yaml"
yq eval -i ".deployment.production.workflow_run_id = \"$RUN_ID\"" "$FEATURE_DIR/state.yaml"
yq eval -i ".deployment.production.deployed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$FEATURE_DIR/state.yaml"
```

### Step 6: Verify Production Health Checks

**Purpose**: Verify production deployment is responding correctly

**If production URL is known** (not "unknown" or "see-\*"):

**Test production endpoint**:

```bash
if [[ "$PROD_URL" != "unknown" && "$PROD_URL" != "see-"* ]]; then
  echo ""
  echo "🏥 Running health checks..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Wait for deployment to fully propagate
  sleep 10

  # Test root endpoint
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL" || echo "000")

  if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo "✅ Production endpoint responding: $HTTP_STATUS"
  else
    echo "⚠️  Production endpoint returned: $HTTP_STATUS (expected 200/301/302)"
    echo "   URL: $PROD_URL"
    echo "   This may indicate deployment issues - investigate immediately"
  fi

  # Save health check result
  yq eval -i ".deployment.production.health_check.status = $HTTP_STATUS" "$FEATURE_DIR/state.yaml"
  yq eval -i ".deployment.production.health_check.checked_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$FEATURE_DIR/state.yaml"
else
  echo ""
  echo "ℹ️  Skipping automated health checks (production URL not extracted)"
  echo "   Manually verify deployment in platform dashboard"
fi
```

**If health check fails with 5xx error**:

- Don't fail the deployment (deployment succeeded, app may be starting)
- Warn user to investigate
- Include warning in production report

### Step 7: Generate Production Deployment Report

**Purpose**: Create comprehensive deployment report with rollback instructions

**Use centralized report generator**:

```bash
python .spec-flow/scripts/spec-cli.py generate-production-report \
  --feature-dir "$FEATURE_DIR" \
  --prod-url "$PROD_URL" \
  --deployment-id "$DEPLOYMENT_ID" \
  --workflow-run-id "$RUN_ID"
```

**Report includes**:

- Production URL and deployment timestamp
- Deployment ID (for rollback)
- GitHub Actions workflow run link
- Health check results
- Platform-specific rollback instructions
- Emergency rollback commands

**Display report location**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PRODUCTION DEPLOYMENT COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Production URL: $PROD_URL
Deployment ID: $DEPLOYMENT_ID
Workflow Run: https://github.com/{owner}/{repo}/actions/runs/$RUN_ID

Health Check: ✅ Passed (HTTP $HTTP_STATUS)

📋 Production Report: $FEATURE_DIR/production-deployment-report.md

⚠️  IMPORTANT: Review rollback instructions in the report
   Keep deployment ID for emergency rollback if needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Update workflow phase to completed**:

```bash
python .spec-flow/scripts/bash/workflow-state.sh update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "completed"
python .spec-flow/scripts/bash/workflow-state.sh complete_phase_timing "$FEATURE_DIR" "ship:deploy-prod"
```

</process>

<success_criteria>
**Production deployment successfully completed when:**

1. **Pre-deployment checks passed**:

   - Pre-flight validation marked as passed in state.yaml
   - Optimize phase completed
   - Production workflow file exists with workflow_dispatch trigger
   - Working tree clean (no uncommitted changes)

2. **Deployment triggered successfully**:

   - GitHub Actions workflow run started
   - Workflow run ID obtained from gh CLI
   - Workflow monitoring initiated

3. **Deployment completed without errors**:

   - `gh run watch` exited with status 0
   - No deployment failures in GitHub Actions logs
   - Platform-specific deployment succeeded

4. **Deployment metadata extracted**:

   - Production URL extracted from actual deployment output (or marked "unknown")
   - Deployment ID extracted from actual platform output (or marked "unknown")
   - Workflow run ID recorded
   - Deployment timestamp recorded

5. **Health checks completed** (if URL available):

   - Production endpoint responding with 2xx or 3xx status
   - Health check results recorded in state.yaml
   - Health check timestamp recorded

6. **Production report generated**:

   - Report file created at `$FEATURE_DIR/production-deployment-report.md`
   - Report contains actual deployment data (not placeholders)
   - Rollback instructions included for detected platform

7. **Workflow state updated**:

   - Phase marked as "completed" in state.yaml
   - Deployment metadata saved in state.yaml
   - Phase timing recorded

8. **User informed**:
   - Production URL displayed (or warning if unknown)
   - Deployment ID displayed (needed for rollback)
   - Health check results displayed
   - Report location displayed
   - Rollback instructions highlighted
     </success_criteria>

<verification>
**Before marking deploy-prod complete, verify:**

1. **Check workflow state file updated**:

   ```bash
   yq eval '.phases.ship:deploy-prod.status' "$FEATURE_DIR/state.yaml"
   # Should show: completed

   yq eval '.deployment.production.url' "$FEATURE_DIR/state.yaml"
   # Should show actual URL or "unknown" (not empty)

   yq eval '.deployment.production.deployment_id' "$FEATURE_DIR/state.yaml"
   # Should show actual ID or "unknown" (not empty)
   ```

2. **Verify production report exists**:

   ```bash
   test -f "$FEATURE_DIR/production-deployment-report.md" && echo "exists" || echo "MISSING"
   # Should show: exists
   ```

3. **Verify deployment artifacts not fabricated**:

   ```bash
   # Check production URL is from actual logs, not guessed
   grep "$PROD_URL" "$FEATURE_DIR/production-deploy.log"
   # Should find URL in actual deployment logs (if not "unknown")

   # Check deployment ID is from actual output, not invented
   grep "$DEPLOYMENT_ID" "$FEATURE_DIR/production-deploy.log"
   # Should find ID in actual logs (if not "unknown")
   ```

4. **Verify health check was actually performed** (if URL not "unknown"):

   ```bash
   yq eval '.deployment.production.health_check.status' "$FEATURE_DIR/state.yaml"
   # Should show actual HTTP status code (200, 301, 302, 404, 500, etc.)
   ```

5. **Verify GitHub Actions workflow succeeded**:

   ```bash
   gh run view "$RUN_ID" --json conclusion -q .conclusion
   # Should show: success
   ```

6. **Verify working tree remains clean**:
   ```bash
   git status --short
   # Should be empty (no modified files)
   ```

**Never claim deployment complete without:**

- Actual production URL (or "unknown" with justification)
- Actual deployment ID (or "unknown" with justification)
- Actual health check status code (if URL available)
- Actual GitHub Actions workflow success confirmation
- Production report file exists and contains real data
  </verification>

<output>
**Files created/modified by this command:**

**Deployment artifacts**:

- `$FEATURE_DIR/production-deploy.log` - Full GitHub Actions workflow logs
- `$FEATURE_DIR/production-deployment-report.md` - Comprehensive deployment report with rollback instructions
- `$FEATURE_DIR/production-deployment-failure.md` - Generated only if deployment fails (contains recovery steps)

**Workflow state**:

- `$FEATURE_DIR/state.yaml` - Updated with:
  - `phases.ship:deploy-prod.status = "completed"` (or "failed")
  - `deployment.production.url` - Production URL from deployment output
  - `deployment.production.deployment_id` - Platform-specific deployment ID for rollback
  - `deployment.production.workflow_run_id` - GitHub Actions run ID
  - `deployment.production.deployed_at` - ISO 8601 timestamp
  - `deployment.production.health_check.status` - HTTP status code from health check
  - `deployment.production.health_check.checked_at` - ISO 8601 timestamp

**Git operations**:

- Branch pushed to remote: `git push -u origin $CURRENT_BRANCH` (if remote branch didn't exist)

**GitHub Actions**:

- Workflow run triggered: Production deployment workflow via `gh workflow run`
- Workflow run ID obtained for monitoring and rollback reference

**Console output**:

- Pre-deployment check results (pre-flight, optimize, workflow file, uncommitted changes)
- Deployment trigger confirmation (workflow name, branch, run ID)
- Deployment progress monitoring (from `gh run watch`)
- Deployment ID extraction (platform-specific)
- Health check results (HTTP status code)
- Production deployment summary (URL, deployment ID, workflow run link, health status)
- Report location and rollback instructions reminder
  </output>

---

## Notes

**Deployment Model Detection**:

- `direct-prod` model detected when: Git remote exists + no staging branch + no `.github/workflows/deploy-staging.yml`
- Automatically selected by `/ship` - users should not call `/deploy-prod` directly

**Platform Support**:

- **Vercel**: First-class support (deployment ID and URL extraction from logs)
- **Netlify**: First-class support (deployment ID and URL extraction from logs)
- **Railway**: Partial support (URL extraction limited, deployment ID may be unavailable)
- **Custom platforms**: Supported via GitHub Actions (manual ID extraction may be required)

**GitHub Actions Requirements**:

- Production workflow file must exist: `.github/workflows/deploy-production.yml` OR `.github/workflows/deploy.yml`
- Workflow must have `workflow_dispatch` trigger for manual execution via gh CLI
- Workflow must output deployment URL and/or deployment ID in logs for extraction

**Rollback Capability**:

- Deployment IDs extracted and saved for emergency rollback
- Platform-specific rollback instructions included in production report
- Previous deployment IDs preserved in workflow state for rollback reference

**Health Check Logic**:

- Automated if production URL extracted from deployment logs
- Skipped if URL is "unknown" or platform doesn't expose URLs
- Non-blocking: Deployment marked successful even if health check fails (warns user to investigate)
- Acceptable status codes: 200 (OK), 301 (redirect), 302 (redirect)

**Failure Handling**:

- If any pre-deployment check fails: Exit immediately, mark phase as "failed"
- If GitHub Actions workflow fails: Generate failure report with recovery steps
- If deployment ID extraction fails: Mark as "unknown" in report (don't fabricate)
- If health check fails: Warn user but don't fail deployment (app may be starting)

**Error Recovery**:

- Failure report generated at `$FEATURE_DIR/production-deployment-failure.md`
- Includes GitHub Actions logs link for debugging
- Lists specific recovery steps based on failure type
- Provides rollback commands if previous deployment available

**Timing**:

- Pre-deployment checks: <1 minute
- Workflow trigger + start: ~5-10 seconds
- Deployment execution: 3-8 minutes (platform-dependent)
- Health checks: ~10 seconds
- Report generation: <5 seconds
- Total: 5-10 minutes typical

**Security**:

- Tool restrictions enforce only deployment-related bash commands
- Production deployments require clean working tree (no uncommitted changes)
- GitHub CLI authentication required (verified in pre-checks)
- No arbitrary bash execution allowed (restricted to git, gh, yq, jq, curl)

**Troubleshooting**:

- If workflow run ID not found: Check GitHub Actions UI manually, may be API delay
- If deployment URL not extracted: Check deployment logs in `$FEATURE_DIR/production-deploy.log`
- If health check fails: Manually verify deployment in platform dashboard
- If rollback needed: Use commands in production report (platform-specific)

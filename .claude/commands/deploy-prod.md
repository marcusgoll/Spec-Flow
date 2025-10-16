# /deploy-prod - Direct Production Deployment

**Purpose**: Deploy directly to production for projects without staging environments. This command is called by `/ship` when deployment model is `direct-prod`.

**When to Use**:
- Projects without staging branch or workflow
- Single-environment deployments
- Simple applications with minimal infrastructure

**Risk Level**: 🔴 HIGH - deploys directly to production without staging validation

**Prerequisites**:
- `/implement` phase complete
- `/optimize` phase complete
- `/preview` manual gate approved
- Pre-flight validation passed

---

## Phase DP.1: Pre-Deployment Checks

**Purpose**: Final safety checks before production deployment

```bash
#!/bin/bash
set -e

# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../../.spec-flow/scripts/bash/workflow-state.sh"
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Find feature directory
FEATURE_DIR=$(ls -td specs/*/ | head -1)
STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No workflow state found"
  exit 1
fi

# Update phase
update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "in_progress"

echo "🚀 Direct Production Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  WARNING: Deploying directly to production"
echo "   No staging environment for validation"
echo ""

# Verify prerequisites
echo "📋 Pre-Deployment Checklist"
echo "─────────────────────────────────────────────"

CHECKS_PASSED=true

# Check 1: Pre-flight validation completed
if ! yq eval '.quality_gates.pre_flight.passed == true' "$STATE_FILE" > /dev/null 2>&1; then
  echo "❌ Pre-flight validation not completed or failed"
  CHECKS_PASSED=false
else
  echo "✅ Pre-flight validation passed"
fi

# Check 2: Optimize phase completed
if ! test_phase_completed "$FEATURE_DIR" "ship:optimize"; then
  echo "❌ Optimization phase not completed"
  CHECKS_PASSED=false
else
  echo "✅ Optimization complete"
fi

# Check 3: Preview approved
PREVIEW_STATUS=$(yq eval '.workflow.manual_gates.preview.status // "pending"' "$STATE_FILE")
if [ "$PREVIEW_STATUS" != "approved" ]; then
  echo "❌ Preview gate not approved"
  CHECKS_PASSED=false
else
  echo "✅ Preview approved"
fi

# Check 4: Production workflow exists
if [ ! -f ".github/workflows/deploy-production.yml" ] && [ ! -f ".github/workflows/deploy.yml" ]; then
  echo "❌ No production deployment workflow found"
  echo "   Expected: .github/workflows/deploy-production.yml or .github/workflows/deploy.yml"
  CHECKS_PASSED=false
else
  echo "✅ Production workflow found"
fi

echo ""

if [ "$CHECKS_PASSED" = false ]; then
  echo "❌ Pre-deployment checks failed"
  update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "failed"
  exit 1
fi

echo "✅ All pre-deployment checks passed"
echo ""
```

**Blocking Conditions**:
- Pre-flight validation failed
- Optimization not complete
- Preview not approved
- No production workflow file

---

## Phase DP.2: Trigger Production Deployment

**Purpose**: Trigger GitHub Actions workflow for production deployment

```bash
echo "🔧 Phase DP.2: Trigger Production Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determine production workflow file
PROD_WORKFLOW=""
if [ -f ".github/workflows/deploy-production.yml" ]; then
  PROD_WORKFLOW="deploy-production.yml"
elif [ -f ".github/workflows/deploy.yml" ]; then
  PROD_WORKFLOW="deploy.yml"
else
  echo "❌ No production workflow found"
  exit 1
fi

echo "Production workflow: $PROD_WORKFLOW"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Check if we need to push
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "⚠️  Uncommitted changes detected"
  echo ""
  read -p "Commit changes before deployment? (yes/no): " SHOULD_COMMIT

  if [ "$SHOULD_COMMIT" = "yes" ]; then
    echo ""
    echo "Creating deployment commit..."

    git add .
    git commit -m "chore: prepare for production deployment

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    echo "✅ Changes committed"
  else
    echo "❌ Cannot deploy with uncommitted changes"
    exit 1
  fi
fi

# Push to remote if needed
REMOTE_BRANCH="origin/$CURRENT_BRANCH"
if ! git rev-parse "$REMOTE_BRANCH" >/dev/null 2>&1; then
  echo ""
  echo "📤 Pushing branch to remote..."
  git push -u origin "$CURRENT_BRANCH"
else
  LOCAL_SHA=$(git rev-parse HEAD)
  REMOTE_SHA=$(git rev-parse "$REMOTE_BRANCH")

  if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
    echo ""
    echo "📤 Pushing updates to remote..."
    git push
  fi
fi

echo ""
echo "🚀 Triggering production deployment workflow..."

# Trigger workflow
gh workflow run "$PROD_WORKFLOW" \
  --ref "$CURRENT_BRANCH" \
  --field feature="$(yq eval '.feature.slug' "$STATE_FILE")" \
  --field deployment_type="production"

# Wait for workflow to start (give GitHub a few seconds)
echo "⏳ Waiting for workflow to start..."
sleep 5

# Find the workflow run
PROD_RUN=$(gh run list \
  --workflow="$PROD_WORKFLOW" \
  --branch="$CURRENT_BRANCH" \
  --limit=1 \
  --json databaseId,status,conclusion \
  --jq '.[0].databaseId')

if [ -z "$PROD_RUN" ]; then
  echo "❌ Could not find workflow run"
  echo "Check GitHub Actions manually: gh run list"
  exit 1
fi

echo "✅ Workflow started: Run ID $PROD_RUN"
echo ""
echo "📊 View workflow: gh run view $PROD_RUN --web"
echo ""
```

**Actions**:
1. Detect production workflow file
2. Commit and push any pending changes
3. Trigger GitHub Actions workflow
4. Record run ID for monitoring

---

## Phase DP.3: Monitor Deployment

**Purpose**: Wait for production deployment to complete and monitor progress

```bash
echo "⏳ Phase DP.3: Monitor Production Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Watch workflow run
gh run watch "$PROD_RUN" --exit-status || {
  echo ""
  echo "❌ Production deployment FAILED"
  echo ""
  echo "View logs: gh run view $PROD_RUN --log"
  echo ""

  # Update state
  update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "failed"

  # Save failure information
  cat > "$FEATURE_DIR/deploy-prod-failure.md" <<EOF
# Production Deployment Failure

**Run ID**: $PROD_RUN
**Timestamp**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Branch**: $CURRENT_BRANCH

## View Logs

\`\`\`bash
gh run view $PROD_RUN --log
\`\`\`

## Retry Deployment

After fixing the issue, retry with:

\`\`\`bash
/ship continue
\`\`\`

## Manual Rollback

If the deployment partially succeeded and broke production:

1. Check previous deployment ID (if available)
2. Use your deployment platform's rollback feature
3. For Vercel: \`vercel alias set <previous-id> <production-url>\`
4. For Railway/other: Use platform's UI or CLI

## Debug Workflow

\`\`\`bash
# View full workflow output
gh run view $PROD_RUN --log > production-deploy-logs.txt

# Check workflow configuration
cat .github/workflows/$PROD_WORKFLOW

# Verify environment secrets
gh secret list
\`\`\`
EOF

  echo "💾 Failure report saved: $FEATURE_DIR/deploy-prod-failure.md"
  exit 1
}

echo ""
echo "✅ Production deployment workflow completed successfully"
echo ""
```

**Monitoring**:
- Live output from GitHub Actions
- Automatic failure detection
- Failure report generation with debug commands
- Exit on deployment failure

---

## Phase DP.4: Extract Deployment IDs

**Purpose**: Extract deployment IDs from workflow logs for rollback capability

```bash
echo "🔍 Phase DP.4: Extract Deployment IDs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get workflow logs
echo "Fetching deployment logs..."
DEPLOY_LOGS=$(gh run view "$PROD_RUN" --log 2>/dev/null || echo "")

# Extract deployment IDs based on deployment platform
# Try to detect multiple common patterns

# Vercel deployments
MARKETING_ID=$(echo "$DEPLOY_LOGS" | grep -oE "(https://)?[a-z]+-marketing-[a-z0-9]+\.vercel\.app" | sed 's|https://||' | head -1)
APP_ID=$(echo "$DEPLOY_LOGS" | grep -oE "(https://)?[a-z]+-[a-z0-9-]+\.vercel\.app" | sed 's|https://||' | grep -v "marketing" | head -1)

# Docker/Railway/generic
API_IMAGE=$(echo "$DEPLOY_LOGS" | grep -oE "ghcr\.io/[^/]+/[^:]+:[a-f0-9]{7,40}" | head -1)

# Railway deployment ID
RAILWAY_ID=$(echo "$DEPLOY_LOGS" | grep -oE "railway-[a-z0-9-]+" | head -1)

# Netlify deployment ID
NETLIFY_ID=$(echo "$DEPLOY_LOGS" | grep -oE "https://[a-z0-9-]+--[a-z0-9-]+\.netlify\.app" | head -1)

echo "Extracted deployment IDs:"

if [ -n "$MARKETING_ID" ]; then
  echo "  Marketing (Vercel): $MARKETING_ID"
fi

if [ -n "$APP_ID" ]; then
  echo "  App (Vercel): $APP_ID"
fi

if [ -n "$API_IMAGE" ]; then
  echo "  API (Docker): $API_IMAGE"
fi

if [ -n "$RAILWAY_ID" ]; then
  echo "  Railway: $RAILWAY_ID"
fi

if [ -n "$NETLIFY_ID" ]; then
  echo "  Netlify: $NETLIFY_ID"
fi

# Check if we got at least one ID
if [ -z "$MARKETING_ID" ] && [ -z "$APP_ID" ] && [ -z "$API_IMAGE" ] && [ -z "$RAILWAY_ID" ] && [ -z "$NETLIFY_ID" ]; then
  echo ""
  echo "⚠️  WARNING: Could not extract deployment IDs from logs"
  echo "   Rollback may not be possible without manual ID lookup"
  echo ""
  echo "Check logs manually: gh run view $PROD_RUN --log"
  echo ""

  # Continue anyway - not a fatal error
fi

# Store deployment metadata
cat > "$FEATURE_DIR/deployment-metadata.json" <<EOF
{
  "production": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "commit_sha": "$(git rev-parse HEAD)",
    "run_id": "$PROD_RUN",
    "branch": "$CURRENT_BRANCH",
    "deployments": {
      "marketing": "${MARKETING_ID:-}",
      "app": "${APP_ID:-}",
      "api": "${API_IMAGE:-}",
      "railway": "${RAILWAY_ID:-}",
      "netlify": "${NETLIFY_ID:-}"
    }
  }
}
EOF

echo ""
echo "💾 Deployment metadata saved: $FEATURE_DIR/deployment-metadata.json"
echo ""

# Update workflow state
update_deployment_state "$FEATURE_DIR" "production" "$(git rev-parse HEAD)" "$PROD_RUN"

# Store individual IDs in state
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Windows - use PowerShell for state update
  pwsh -Command "
    Import-Module '.spec-flow/scripts/powershell/workflow-state.ps1'
    Update-DeploymentIds -FeatureDir '$FEATURE_DIR' -Environment 'production' \
      -MarketingId '$MARKETING_ID' -AppId '$APP_ID' -ApiImage '$API_IMAGE'
  "
else
  # Unix - use bash function
  update_deployment_ids "$FEATURE_DIR" "production" "$MARKETING_ID" "$APP_ID" "$API_IMAGE"
fi
```

**Extracted Information**:
- Vercel deployment URLs (marketing, app)
- Docker image references (API)
- Railway deployment IDs
- Netlify deployment IDs
- Git commit SHA
- GitHub Actions run ID

**Storage**:
- `deployment-metadata.json` - Human-readable metadata
- `workflow-state.yaml` - Machine-readable state for rollback

---

## Phase DP.5: Verify Production Health

**Purpose**: Basic health checks on production deployment

```bash
echo "🏥 Phase DP.5: Production Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try to determine production URL from deployment IDs or workflow logs
PROD_URL=""

if [ -n "$APP_ID" ]; then
  PROD_URL="https://$APP_ID"
elif [ -n "$NETLIFY_ID" ]; then
  PROD_URL="$NETLIFY_ID"
else
  # Try to extract from workflow logs
  PROD_URL=$(echo "$DEPLOY_LOGS" | grep -oE "https://[a-z0-9-]+\.(vercel\.app|netlify\.app|railway\.app)" | head -1)
fi

if [ -z "$PROD_URL" ]; then
  echo "⚠️  Could not determine production URL"
  echo "   Manual health check required"
  echo ""
else
  echo "Production URL: $PROD_URL"
  echo ""

  # Wait for DNS propagation
  echo "⏳ Waiting 30 seconds for DNS propagation..."
  sleep 30

  # Health check
  echo "Running health check..."

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL" || echo "000")

  if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "304" ]; then
    echo "✅ Production site is accessible (HTTP $HTTP_STATUS)"
  elif [ "$HTTP_STATUS" = "000" ]; then
    echo "⚠️  Could not reach production site (connection failed)"
    echo "   This may be due to DNS propagation delay"
  else
    echo "⚠️  Production site returned HTTP $HTTP_STATUS"
    echo "   Manual verification recommended"
  fi

  echo ""

  # Check for errors in browser console (if we can parse HTML)
  echo "Checking for JavaScript errors..."

  HTML_CONTENT=$(curl -s "$PROD_URL" || echo "")

  if echo "$HTML_CONTENT" | grep -qi "error"; then
    echo "⚠️  Potential errors detected in page content"
    echo "   Manual verification recommended"
  else
    echo "✅ No obvious errors in page content"
  fi

  echo ""
fi

# Store health check results
HEALTH_PASSED=true
[ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "304" ] || HEALTH_PASSED=false

cat > "$FEATURE_DIR/production-health-check.json" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "url": "${PROD_URL:-unknown}",
  "http_status": "${HTTP_STATUS:-unknown}",
  "passed": $HEALTH_PASSED
}
EOF

echo "💾 Health check results: $FEATURE_DIR/production-health-check.json"
echo ""
```

**Health Checks**:
- HTTP status code verification
- DNS propagation wait
- Basic content validation
- Error detection in HTML

**Non-Blocking**: Health check failures don't stop deployment (production is already live)

---

## Phase DP.6: Generate Production Report

**Purpose**: Create comprehensive production deployment report

```bash
echo "📝 Phase DP.6: Production Deployment Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate report
FEATURE_SLUG=$(yq eval '.feature.slug' "$STATE_FILE")
FEATURE_TITLE=$(yq eval '.feature.title' "$STATE_FILE")

cat > "$FEATURE_DIR/production-ship-report.md" <<EOF
# Production Deployment Report

**Feature**: $FEATURE_TITLE
**Slug**: $FEATURE_SLUG
**Deployed**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Branch**: $CURRENT_BRANCH
**Commit**: $(git rev-parse HEAD)

---

## Deployment Summary

**Model**: Direct-to-Production
**Workflow**: $PROD_WORKFLOW
**Run ID**: $PROD_RUN
**Status**: ✅ SUCCESS

### Production URL

EOF

if [ -n "$PROD_URL" ]; then
  echo "$PROD_URL" >> "$FEATURE_DIR/production-ship-report.md"
else
  echo "_URL not detected - check deployment logs_" >> "$FEATURE_DIR/production-ship-report.md"
fi

cat >> "$FEATURE_DIR/production-ship-report.md" <<EOF

---

## Deployment IDs (for rollback)

EOF

if [ -n "$MARKETING_ID" ]; then
  echo "- **Marketing**: $MARKETING_ID" >> "$FEATURE_DIR/production-ship-report.md"
fi

if [ -n "$APP_ID" ]; then
  echo "- **App**: $APP_ID" >> "$FEATURE_DIR/production-ship-report.md"
fi

if [ -n "$API_IMAGE" ]; then
  echo "- **API**: $API_IMAGE" >> "$FEATURE_DIR/production-ship-report.md"
fi

if [ -n "$RAILWAY_ID" ]; then
  echo "- **Railway**: $RAILWAY_ID" >> "$FEATURE_DIR/production-ship-report.md"
fi

if [ -n "$NETLIFY_ID" ]; then
  echo "- **Netlify**: $NETLIFY_ID" >> "$FEATURE_DIR/production-ship-report.md"
fi

if [ -z "$MARKETING_ID" ] && [ -z "$APP_ID" ] && [ -z "$API_IMAGE" ] && [ -z "$RAILWAY_ID" ] && [ -z "$NETLIFY_ID" ]; then
  echo "_No deployment IDs extracted - manual lookup required for rollback_" >> "$FEATURE_DIR/production-ship-report.md"
fi

cat >> "$FEATURE_DIR/production-ship-report.md" <<EOF

---

## Health Check

**Status**: $([ "$HEALTH_PASSED" = true ] && echo "✅ PASSED" || echo "⚠️  REQUIRES VERIFICATION")
**HTTP Status**: ${HTTP_STATUS:-unknown}
**Checked**: $(date -u +%Y-%m-%dT%H:%M:%SZ)

---

## Rollback Instructions

If issues arise, rollback using the deployment IDs above.

### Vercel Rollback

\`\`\`bash
# Rollback app to previous deployment
vercel alias set <previous-deployment-id> <production-url> --token=\$VERCEL_TOKEN

# Example:
# vercel alias set app-abc123.vercel.app myapp.com --token=\$VERCEL_TOKEN
\`\`\`

### Railway Rollback

1. Go to Railway dashboard
2. Select your project
3. Click "Deployments"
4. Select previous deployment and click "Redeploy"

### Manual Rollback

\`\`\`bash
# Revert the git commit
git revert $(git rev-parse HEAD)

# Or reset to previous commit (WARNING: destructive)
git reset --hard HEAD~1

# Force push (if necessary)
git push --force
\`\`\`

---

## Post-Deployment Tasks

- [ ] Monitor error logs for issues
- [ ] Check analytics/metrics for anomalies
- [ ] Verify all features working in production
- [ ] Update release notes or changelog
- [ ] Notify stakeholders of deployment

---

## Artifacts

- Deployment logs: \`gh run view $PROD_RUN --log\`
- Deployment metadata: \`deployment-metadata.json\`
- Health check: \`production-health-check.json\`
- Workflow state: \`workflow-state.yaml\`

---

**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo "📄 Production report created: $FEATURE_DIR/production-ship-report.md"
echo ""

# Update workflow state
update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "completed"

# Store production URL in state if found
if [ -n "$PROD_URL" ]; then
  STATE_TEMP="${STATE_FILE}.tmp"
  jq --arg url "$PROD_URL" '.deployment.production.url = $url' "$STATE_FILE" > "$STATE_TEMP"
  mv "$STATE_TEMP" "$STATE_FILE"
fi

echo "✅ Production deployment complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Feature Deployed to Production"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$PROD_URL" ]; then
  echo "🚀 Live at: $PROD_URL"
  echo ""
fi

echo "📊 Full report: $FEATURE_DIR/production-ship-report.md"
echo "📦 Deployment IDs: $FEATURE_DIR/deployment-metadata.json"
echo ""
echo "⚠️  IMPORTANT: Monitor production for the next 24 hours"
echo "   - Watch error logs"
echo "   - Check user feedback"
echo "   - Monitor performance metrics"
echo ""

if [ -n "$MARKETING_ID" ] || [ -n "$APP_ID" ] || [ -n "$API_IMAGE" ]; then
  echo "🔄 Rollback available via deployment IDs (see report)"
else
  echo "⚠️  Rollback IDs not detected - use git revert if needed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Report Contents**:
- Deployment summary with timestamps
- Production URL
- Deployment IDs for rollback
- Health check results
- Rollback instructions for multiple platforms
- Post-deployment task checklist
- Links to all artifacts

**State Updates**:
- Mark `ship:deploy-prod` as completed
- Store production URL
- Record deployment timestamp

---

## Error Recovery

**Common Failures**:

1. **Workflow not found**
   ```bash
   # Check workflow files
   ls -la .github/workflows/
   # Look for deploy-production.yml or deploy.yml
   ```

2. **Deployment failed**
   ```bash
   # View logs
   gh run view <run-id> --log
   # Check for:
   # - Missing environment variables
   # - Build failures
   # - Deployment platform errors
   ```

3. **Health check failed**
   ```bash
   # Manual check
   curl -I <production-url>
   # Check DNS
   dig <your-domain>
   # Wait for DNS propagation (can take 5-30 minutes)
   ```

4. **Rollback IDs missing**
   ```bash
   # Manual extraction from logs
   gh run view <run-id> --log > deploy-logs.txt
   grep -E "vercel|railway|netlify" deploy-logs.txt
   ```

**Recovery Steps**:
- Fix the issue causing failure
- Run `/ship continue` to retry
- If production is broken, use manual rollback instructions
- Check workflow logs for detailed error messages

---

## Success Criteria

- ✅ Pre-deployment checks passed
- ✅ Production workflow triggered successfully
- ✅ Deployment completed without errors
- ✅ Deployment IDs extracted (or manual rollback documented)
- ✅ Production health check passed (or manual verification noted)
- ✅ Production report generated
- ✅ State updated to completed

---

## Notes

- **No staging validation**: This deployment goes straight to production
- **Risk level**: Higher than staging-prod model
- **Best for**: Simple applications, solo developers, rapid iteration
- **Rollback**: Critical to extract and store deployment IDs
- **Monitoring**: Manual monitoring more important without staging gate
- **Recovery**: Document manual rollback procedures if IDs not extracted

This command is automatically called by `/ship` when deployment model is `direct-prod`.

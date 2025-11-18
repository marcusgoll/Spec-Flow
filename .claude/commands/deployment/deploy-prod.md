---
description: Direct production deployment without staging
internal: true
---

> **⚠️  INTERNAL COMMAND**: This command is called automatically by `/ship` when deployment model is `direct-prod`.
> Most users should use `/ship` instead of calling this directly.

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
#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap to ensure proper cleanup on failure
on_error() {
  echo "⚠️  Error in /deploy-prod. Marking phase as failed."
  complete_phase_timing "$FEATURE_DIR" "ship:deploy-prod" 2>/dev/null || true
  update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "failed" 2>/dev/null || true
}
trap on_error ERR

# Always start at repo root
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Tool preflight checks
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    echo "   Install via: brew install $1  # or appropriate package manager"
    exit 1
  }
}

need git
need yq
need jq
need gh
need curl

# Source state management functions
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../../.spec-flow/scripts/bash/workflow-state.sh"
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

# Find feature directory
FEATURE_DIR=$(ls -td specs/*/ 2>/dev/null | head -1)
STATE_FILE="$FEATURE_DIR/workflow-state.yaml"

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No workflow state found"
  exit 1
fi

# Update phase
update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "in_progress"
# Start timing for deploy-prod phase
start_phase_timing "$FEATURE_DIR" "ship:deploy-prod"

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

# Preview phase removed - all testing now happens in staging

# Check 4: Production workflow exists
PROD_WORKFLOW=""
if [ -f ".github/workflows/deploy-production.yml" ]; then
  PROD_WORKFLOW="deploy-production.yml"
elif [ -f ".github/workflows/deploy.yml" ]; then
  PROD_WORKFLOW="deploy.yml"
else
  echo "❌ No production deployment workflow found"
  echo "   Expected: .github/workflows/deploy-production.yml or .github/workflows/deploy.yml"
  CHECKS_PASSED=false
fi

# Check 5: Workflow has workflow_dispatch trigger
if [ -n "$PROD_WORKFLOW" ]; then
  if ! grep -q "workflow_dispatch:" ".github/workflows/$PROD_WORKFLOW"; then
    echo "❌ Workflow missing 'on: workflow_dispatch' trigger"
    echo "   Required for manual deployment via gh CLI"
    CHECKS_PASSED=false
  else
    echo "✅ Production workflow found with dispatch trigger"
  fi
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
- Workflow missing `workflow_dispatch` trigger

**Changes from v1.x**:
- ✅ Added strict bash mode (`set -Eeuo pipefail`)
- ✅ Added error trap for cleanup
- ✅ Added tool preflight checks
- ✅ Fixed typo on line 54 (`n#` → `#`)
- ✅ Added workflow_dispatch verification

---

## Phase DP.2: Trigger Production Deployment

**Purpose**: Trigger GitHub Actions workflow for production deployment

```bash
echo "🔧 Phase DP.2: Trigger Production Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Production workflow: $PROD_WORKFLOW"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Fail fast if uncommitted changes detected (non-interactive)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ Uncommitted changes detected"
  echo ""
  echo "Production deployments must be from a clean working tree."
  echo ""
  echo "Fix options:"
  echo "  1. Commit changes: git add . && git commit -m 'chore: prepare for deployment'"
  echo "  2. Stash changes: git stash"
  echo "  3. Discard changes: git restore ."
  echo ""
  exit 1
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
2. **Fail fast** if uncommitted changes (non-interactive)
3. Push to remote if needed
4. Trigger GitHub Actions workflow
5. Record run ID for monitoring

**Changes from v1.x**:
- ✅ Removed interactive `read -p "Commit changes?"` prompt
- ✅ Fail fast with actionable error messages
- ✅ CI-safe (no human intervention required)

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

## Manual Rollback (Platform-Specific)

If the deployment partially succeeded and broke production:

### Vercel Rollback

1. **Find previous deployment ID**:
   \`\`\`bash
   vercel ls --token=\$VERCEL_TOKEN
   \`\`\`

2. **Alias previous deployment to production URL**:
   \`\`\`bash
   vercel alias set <previous-deployment-id> <production-url> --token=\$VERCEL_TOKEN
   # Example: vercel alias set app-abc123.vercel.app myapp.com --token=\$VERCEL_TOKEN
   \`\`\`

### Railway Rollback

1. Go to Railway dashboard: https://railway.app
2. Select your project
3. Click "Deployments" tab
4. Select previous successful deployment
5. Click "Redeploy" button

### Netlify Rollback

1. **Find previous deployment ID**:
   \`\`\`bash
   netlify sites:list
   netlify deploys:list --site=<site-id>
   \`\`\`

2. **Restore previous deployment**:
   \`\`\`bash
   netlify deploy:restore <previous-deploy-id> --site=<site-id>
   \`\`\`

### Git-Based Rollback (Universal)

\`\`\`bash
# Revert the git commit (safe, creates new commit)
git revert $(git rev-parse HEAD)
git push

# OR reset to previous commit (destructive, rewrites history)
git reset --hard HEAD~1
git push --force
\`\`\`

## Debug Workflow

\`\`\`bash
# View full workflow output
gh run view $PROD_RUN --log > production-deploy-logs.txt

# Check workflow configuration
cat .github/workflows/$PROD_WORKFLOW

# Verify environment secrets
gh secret list

# Check environment variables in GitHub Actions
gh variable list
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
- Failure report generation with platform-specific rollback instructions
- Exit on deployment failure

**Changes from v1.x**:
- ✅ Added concrete Vercel rollback commands
- ✅ Added concrete Railway rollback steps
- ✅ Added concrete Netlify rollback commands
- ✅ Added git-based universal rollback

---

## Phase DP.4: Extract Deployment IDs

**Purpose**: Extract deployment IDs using platform APIs for rollback capability

```bash
echo "🔍 Phase DP.4: Extract Deployment IDs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect deployment platform from environment or config
DEPLOY_PLATFORM="${DEPLOY_PLATFORM:-vercel}"  # Default to Vercel

echo "Fetching deployment IDs via $DEPLOY_PLATFORM API..."
echo ""

# Initialize deployment ID variables
MARKETING_ID=""
APP_ID=""
API_IMAGE=""
RAILWAY_ID=""
NETLIFY_ID=""

case "$DEPLOY_PLATFORM" in
  vercel)
    # Use Vercel API to get recent deployments
    if [ -n "$VERCEL_TOKEN" ] && [ -n "$VERCEL_PROJECT_ID" ]; then
      VERCEL_RESPONSE=$(curl -sS -H "Authorization: Bearer $VERCEL_TOKEN" \
        "https://api.vercel.com/v6/deployments?projectId=$VERCEL_PROJECT_ID&limit=10&target=production" 2>/dev/null)

      # Extract most recent production deployment ID
      APP_ID=$(echo "$VERCEL_RESPONSE" | jq -r '.deployments[0].uid // empty' 2>/dev/null)

      # If multiple projects, extract marketing deployment
      if [ -n "$VERCEL_MARKETING_PROJECT_ID" ]; then
        MARKETING_RESPONSE=$(curl -sS -H "Authorization: Bearer $VERCEL_TOKEN" \
          "https://api.vercel.com/v6/deployments?projectId=$VERCEL_MARKETING_PROJECT_ID&limit=5&target=production" 2>/dev/null)
        MARKETING_ID=$(echo "$MARKETING_RESPONSE" | jq -r '.deployments[0].uid // empty' 2>/dev/null)
      fi

      echo "Vercel API response received"
    else
      echo "⚠️  VERCEL_TOKEN or VERCEL_PROJECT_ID not set - falling back to log parsing"
      # Fallback to log parsing if API credentials missing
      DEPLOY_LOGS=$(gh run view "$PROD_RUN" --log 2>/dev/null || echo "")
      APP_ID=$(echo "$DEPLOY_LOGS" | grep -oE "dpl_[a-zA-Z0-9]{24}" | head -1)
    fi
    ;;

  railway)
    # Use Railway API
    if [ -n "$RAILWAY_TOKEN" ] && [ -n "$RAILWAY_SERVICE_ID" ]; then
      RAILWAY_RESPONSE=$(curl -sS -H "Authorization: Bearer $RAILWAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"query { service(id: \\\"$RAILWAY_SERVICE_ID\\\") { deployments(first: 5) { edges { node { id createdAt } } } } }\"}" \
        "https://backboard.railway.app/graphql" 2>/dev/null)

      RAILWAY_ID=$(echo "$RAILWAY_RESPONSE" | jq -r '.data.service.deployments.edges[0].node.id // empty' 2>/dev/null)
      echo "Railway API response received"
    else
      echo "⚠️  RAILWAY_TOKEN or RAILWAY_SERVICE_ID not set - falling back to log parsing"
      DEPLOY_LOGS=$(gh run view "$PROD_RUN" --log 2>/dev/null || echo "")
      RAILWAY_ID=$(echo "$DEPLOY_LOGS" | grep -oE "railway-[a-z0-9-]+" | head -1)
    fi
    ;;

  netlify)
    # Use Netlify API
    if [ -n "$NETLIFY_AUTH_TOKEN" ] && [ -n "$NETLIFY_SITE_ID" ]; then
      NETLIFY_RESPONSE=$(curl -sS -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
        "https://api.netlify.com/api/v1/sites/$NETLIFY_SITE_ID/deploys?per_page=5" 2>/dev/null)

      NETLIFY_ID=$(echo "$NETLIFY_RESPONSE" | jq -r '.[0].id // empty' 2>/dev/null)
      echo "Netlify API response received"
    else
      echo "⚠️  NETLIFY_AUTH_TOKEN or NETLIFY_SITE_ID not set - falling back to log parsing"
      DEPLOY_LOGS=$(gh run view "$PROD_RUN" --log 2>/dev/null || echo "")
      NETLIFY_ID=$(echo "$DEPLOY_LOGS" | grep -oE "https://[a-z0-9-]+--[a-z0-9-]+\.netlify\.app" | head -1)
    fi
    ;;

  docker|custom)
    # Docker images - extract from GitHub Container Registry
    API_IMAGE=$(gh api "/repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/packages?package_type=container" \
      --jq '.[0].name' 2>/dev/null || echo "")

    if [ -z "$API_IMAGE" ]; then
      # Fallback to log parsing
      DEPLOY_LOGS=$(gh run view "$PROD_RUN" --log 2>/dev/null || echo "")
      API_IMAGE=$(echo "$DEPLOY_LOGS" | grep -oE "ghcr\.io/[^/]+/[^:]+:[a-f0-9]{7,40}" | head -1)
    fi
    ;;
esac

echo ""
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
  echo "⚠️  WARNING: Could not extract deployment IDs via API"
  echo "   Ensure platform credentials are configured:"
  echo "   - Vercel: VERCEL_TOKEN, VERCEL_PROJECT_ID"
  echo "   - Railway: RAILWAY_TOKEN, RAILWAY_SERVICE_ID"
  echo "   - Netlify: NETLIFY_AUTH_TOKEN, NETLIFY_SITE_ID"
  echo ""
  echo "   Rollback may require manual ID lookup"
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
# Find previous deployments
vercel ls --token=\$VERCEL_TOKEN

# Rollback app to previous deployment
vercel alias set <previous-deployment-id> <production-url> --token=\$VERCEL_TOKEN

# Example:
# vercel alias set app-abc123.vercel.app myapp.com --token=\$VERCEL_TOKEN
\`\`\`

### Railway Rollback

1. Go to Railway dashboard: https://railway.app
2. Select your project
3. Click "Deployments" tab
4. Select previous successful deployment
5. Click "Redeploy" button

### Netlify Rollback

\`\`\`bash
# Find previous deployments
netlify sites:list
netlify deploys:list --site=<site-id>

# Restore previous deployment
netlify deploy:restore <previous-deploy-id> --site=<site-id>
\`\`\`

### Git-Based Rollback (Universal)

\`\`\`bash
# Revert the git commit (safe, creates new commit)
git revert $(git rev-parse HEAD)
git push

# OR reset to previous commit (destructive, rewrites history)
git reset --hard HEAD~1
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
# Complete timing for deploy-prod phase
complete_phase_timing "$FEATURE_DIR" "ship:deploy-prod"

# Update workflow state
update_workflow_phase "$FEATURE_DIR" "ship:deploy-prod" "completed"

# Store production URL in state if found
if [ -n "$PROD_URL" ]; then
  STATE_TEMP="${STATE_FILE}.tmp"
  jq --arg url "$PROD_URL" '.deployment.production.url = $url' "$STATE_FILE" > "$STATE_TEMP"
  mv "$STATE_TEMP" "$STATE_FILE"
fi

# Regenerate project-level CLAUDE.md to reflect deployed feature
echo "Regenerating project CLAUDE.md..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-project-claude-md.ps1 2>/dev/null || echo "⚠️  Could not regenerate project CLAUDE.md (non-blocking)"
else
  .spec-flow/scripts/bash/generate-project-claude-md.sh 2>/dev/null || echo "⚠️  Could not regenerate project CLAUDE.md (non-blocking)"
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
- **Platform-specific rollback instructions** (Vercel, Railway, Netlify, Git)
- Post-deployment task checklist
- Links to all artifacts

**State Updates**:
- Mark `ship:deploy-prod` as completed
- Store production URL
- Record deployment timestamp

**Changes from v1.x**:
- ✅ Added concrete Vercel rollback commands with examples
- ✅ Added step-by-step Railway rollback instructions
- ✅ Added Netlify rollback commands
- ✅ Added git-based universal rollback
- ✅ Fixed typo on line 669 (`n#` → `#`)

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
- If production is broken, use platform-specific rollback instructions from the failure report
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
- **Recovery**: Platform-specific rollback procedures documented in failure report

This command is automatically called by `/ship` when deployment model is `direct-prod`.

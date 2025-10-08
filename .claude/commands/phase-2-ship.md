---
description: Automated staging→production promotion with versioning and release
---

# Phase 2 Ship: Staging → Production Deployment

**Command**: `/phase-2-ship`

**Purpose**: Automated staging→production promotion via workflow trigger. Validates staging, triggers promote.yml, waits for deployment, creates release.

**When to use**: After `/validate-staging` passes with all checks green. This is the final step to ship features to production.

**Workflow position**: \spec-flow → clarify → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → **phase-2-ship**`

---

## MENTAL MODEL

You are a **production deployment orchestrator**. Your job:

1. **Validate staging readiness** (staging-validation-report.md exists and passed)
2. **Trigger promote.yml workflow** (manual workflow_dispatch with commit SHA)
3. **Wait for production deployment** (GitHub CLI polling)
4. **Monitor deployment** (canary tests, alias flip, rollback if needed)
5. **Create release** (version tag + GitHub release)
6. **Update roadmap** (move to "Shipped")
7. **Report success** (ship-report.md with production URLs)

**Philosophy**: Fully automated from staging environment → production environment. The only manual gate is `/validate-staging`. Once validated, this command handles everything: workflow trigger, deployment waiting, versioning, and roadmap updates.

**Token efficiency**: Use GitHub CLI to poll workflow status. Minimize API calls by polling every 30 seconds. Scripts run efficiently without burning Claude tokens.

**Branch model**: No staging branch exists. Main branch is deployed to staging environment. Production is a promotion of the same artifacts.

---

## INPUTS

**Required context:**
- `staging-validation-report.md` exists in specs/$SLUG/ with all checks ✅
- Clean git working tree (no uncommitted changes)

**Auto-detected:**
- Feature name from staging-validation-report.md path
- Latest validated commit SHA from staging validation
- Current version from CHANGELOG.md

---

## EXECUTION PHASES

### Phase 2.1: LOAD FEATURE

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 2 Ship: Staging → Production"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find latest staging validation report
VALIDATION_REPORTS=$(find specs -name "staging-validation-report.md" 2>/dev/null | grep -v archive)

if [ -z "$VALIDATION_REPORTS" ]; then
  echo "❌ No staging validation report found"
  echo ""
  echo "Run /validate-staging first to validate staging deployment"
  echo ""
  echo "Expected: specs/[feature-slug]/staging-validation-report.md"
  exit 1
fi

# If multiple reports, use most recent
LATEST_REPORT=$(echo "$VALIDATION_REPORTS" | xargs ls -t | head -1)

# Extract feature slug from path (specs/$SLUG/staging-validation-report.md)
SLUG=$(echo "$LATEST_REPORT" | sed 's|specs/||' | sed 's|/.*||')
FEATURE_DIR="specs/$SLUG"
VALIDATION_REPORT="$LATEST_REPORT"

echo "✅ Feature detected: $SLUG"
echo "✅ Validation report: $VALIDATION_REPORT"
echo ""

# Validate feature directory exists
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature directory not found: $FEATURE_DIR"
  exit 1
fi

# Initialize file paths
SPEC_FILE="$FEATURE_DIR/spec.md"
SHIP_REPORT="$FEATURE_DIR/ship-report.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
ROADMAP_FILE="\spec-flow/memory/roadmap.md"

# Initialize production URLs
GITHUB_REPO="cfipros/monorepo"
WORKFLOW_FILE="promote.yml"
PROD_MARKETING="https://cfipros.com"
PROD_APP="https://app.cfipros.com"
PROD_API="https://api.cfipros.com"

echo "Feature directory: $FEATURE_DIR"
echo ""
```

---

### Phase 2.2: CHECK REMOTE REPOSITORY

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Remote Repository Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if remote origin exists
if ! git remote -v | grep -q "origin"; then
  echo "❌ No remote repository configured"
  echo ""
  echo "Phase 2 Ship requires a remote repository with production workflow."
  echo ""
  echo "This appears to be a local-only project."
  echo ""
  echo "Options:"
  echo "  1. Add remote repository:"
  echo "     git remote add origin <repository-url>"
  echo "     git push -u origin main"
  echo ""
  echo "  2. For local-only deployment:"
  echo "     Manually deploy your feature to production environment"
  echo "     See project documentation for deployment instructions"
  echo ""
  echo "  3. Update project configuration:"
  echo "     See .spec-flow/memory/constitution.md (Project Configuration section)"
  exit 1
fi

# Check if GitHub CLI is available for workflow dispatch
if ! command -v gh &> /dev/null; then
  echo "⚠️  GitHub CLI (gh) not found"
  echo ""
  echo "Phase 2 Ship requires GitHub CLI for workflow dispatch."
  echo ""
  echo "Install GitHub CLI:"
  echo "  macOS: brew install gh"
  echo "  Windows: winget install GitHub.cli"
  echo "  Linux: See https://github.com/cli/cli#installation"
  exit 1
fi

echo "✅ Remote repository configured"
echo "✅ GitHub CLI available"
echo ""
```

---

### Phase 2.3: VALIDATE STAGING PASSED

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Validating Staging Readiness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if report shows ready for production
if ! grep -q "Status: ✅ Ready for Production" "$VALIDATION_REPORT"; then
  echo "❌ Staging validation has not passed"
  echo ""

  # Show current status
  echo "Current status:"
  grep "Status:" "$VALIDATION_REPORT" | head -1 | sed 's/^/  /'
  echo ""

  # Show blockers
  BLOCKERS=$(grep "❌" "$VALIDATION_REPORT" | head -5)
  if [ -n "$BLOCKERS" ]; then
    echo "Blockers:"
    echo "$BLOCKERS" | sed 's/^/  /'
    echo ""
  fi

  echo "Fix blockers and re-run /validate-staging"
  echo "Once all checks pass, run /phase-2-ship again"
  exit 1
fi

echo "✅ Staging validation passed"
echo ""

# Extract validated commit SHA
echo "Reading validated commit SHA..."

# Try multiple patterns
COMMIT_SHA=$(grep -E "Commit SHA:|Validated SHA:|SHA:" "$VALIDATION_REPORT" | \
             head -1 | \
             grep -oE "[a-f0-9]{7,40}" | \
             head -1)

if [ -z "$COMMIT_SHA" ]; then
  echo "⚠️  Could not extract commit SHA from validation report"
  echo ""

  # Fallback: Use latest commit on main
  echo "Using latest commit on main..."
  git fetch origin main --quiet
  COMMIT_SHA=$(git rev-parse origin/main)
fi

# Validate SHA exists
if ! git cat-file -e "$COMMIT_SHA" 2>/dev/null; then
  echo "❌ Commit SHA not found: $COMMIT_SHA"
  exit 1
fi

# Get short SHA for display
SHORT_SHA=$(git rev-parse --short "$COMMIT_SHA")

echo "✅ Validated commit: $SHORT_SHA"
echo "   Full SHA: $COMMIT_SHA"
echo ""

# Show commit details
echo "Commit details:"
git log -1 --oneline --decorate "$COMMIT_SHA" | sed 's/^/  /'
echo ""
```

---

### Phase 2.3: CHECK DEPLOYMENT QUOTA

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Deployment Quota"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count recent production deployments
RECENT_PROD=$(gh run list \
  --workflow="$WORKFLOW_FILE" \
  --created="$(date -u -d '24 hours ago' -Iseconds 2>/dev/null || date -u -v-24H -Iseconds)" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)

QUOTA_TOTAL=100
QUOTA_USED=$RECENT_PROD
QUOTA_REMAINING=$((QUOTA_TOTAL - QUOTA_USED))

# Calculate deployment cost (2 apps × 3 retries max)
DEPLOYMENT_COST=6

echo "Deployment Quota (24h rolling):"
echo "  Used: $QUOTA_USED / $QUOTA_TOTAL"
echo "  Remaining: $QUOTA_REMAINING"
echo "  This deployment: ~$DEPLOYMENT_COST (2 apps × 3 retries)"
echo "  After deployment: ~$((QUOTA_USED + DEPLOYMENT_COST)) / $QUOTA_TOTAL"
echo ""

# Warning levels
if [ "$QUOTA_REMAINING" -lt "$DEPLOYMENT_COST" ]; then
  echo "❌ INSUFFICIENT QUOTA"
  echo ""
  echo "Not enough quota for production deployment"
  echo "Required: $DEPLOYMENT_COST deployments"
  echo "Available: $QUOTA_REMAINING deployments"
  echo ""
  echo "Options:"
  echo "  1. Wait for quota reset (~$(( (86400 - $(date +%s) % 86400) / 3600 )) hours)"
  echo "  2. Test locally: pnpm run ci:validate"
  exit 1

elif [ "$QUOTA_REMAINING" -lt 20 ]; then
  echo "⚠️  LOW QUOTA WARNING"
  echo ""
  echo "After this deployment: ~$((QUOTA_USED + DEPLOYMENT_COST)) / $QUOTA_TOTAL used"
  echo "Only $((QUOTA_REMAINING - DEPLOYMENT_COST)) deployments will remain"
  echo ""
  read -p "Continue? (y/N): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    exit 1
  fi

elif [ "$QUOTA_REMAINING" -lt 50 ]; then
  echo "✅ MODERATE QUOTA"
  echo "   Sufficient for this deployment"
else
  echo "✅ NORMAL QUOTA"
  echo "   Plenty of capacity"
fi

echo ""
```

---

### Phase 2.4: CHECK WORKING TREE

```bash
echo "Checking git working tree..."

DIRTY_FILES=$(git status --porcelain)

if [ -n "$DIRTY_FILES" ]; then
  echo "❌ Uncommitted changes detected"
  echo ""
  echo "Changed files:"
  echo "$DIRTY_FILES" | head -10 | sed 's/^/  /'
  echo ""
  echo "Please commit or stash changes:"
  echo "  git add ."
  echo "  git commit -m \"chore: prepare for production deployment\""
  echo ""
  echo "Then run /phase-2-ship again"
  exit 1
fi

echo "✅ Working tree clean"
echo ""
```

---

### Phase 2.5: TRIGGER PRODUCTION PROMOTION

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Triggering Production Promotion"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Workflow: $WORKFLOW_FILE"
echo "Commit: $SHORT_SHA"
echo ""

# Trigger workflow
gh workflow run "$WORKFLOW_FILE" \
  --ref main \
  --field sha="$COMMIT_SHA"

if [ $? -ne 0 ]; then
  echo "❌ Failed to trigger workflow"
  echo ""
  echo "Manual trigger:"
  echo "  1. Go to: https://github.com/$GITHUB_REPO/actions/workflows/$WORKFLOW_FILE"
  echo "  2. Click 'Run workflow'"
  echo "  3. Branch: main"
  echo "  4. SHA: $COMMIT_SHA"
  exit 1
fi

echo "✅ Workflow triggered"
echo ""

# Wait for workflow to register
echo "Waiting for workflow to start..."
sleep 10

# Get workflow run ID
RUN_ID=$(gh run list \
  --workflow="$WORKFLOW_FILE" \
  --limit 5 \
  --json databaseId,headSha \
  --jq ".[] | select(.headSha==\"$COMMIT_SHA\") | .databaseId" | head -1)

if [ -z "$RUN_ID" ]; then
  echo "⚠️  Could not find workflow run"
  echo "   Check manually: https://github.com/$GITHUB_REPO/actions"
  echo ""
  read -p "Enter run ID manually: " RUN_ID

  if [ -z "$RUN_ID" ]; then
    echo "❌ No run ID provided"
    exit 1
  fi
fi

echo "✅ Run ID: $RUN_ID"
echo "   Monitor: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"
echo ""
```

---

### Phase 2.6: WAIT FOR PRODUCTION DEPLOYMENT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Waiting for Production Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Workflow: promote.yml"
echo "Run ID: $RUN_ID"
echo "Monitoring: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"
echo ""

TIMEOUT=1800  # 30 minutes
ELAPSED=0
POLL_INTERVAL=30
DEPLOYMENT_SUCCESS=false

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Get workflow status
  WORKFLOW_DATA=$(gh run view "$RUN_ID" --json status,conclusion,jobs 2>/dev/null || echo "{}")

  STATUS=$(echo "$WORKFLOW_DATA" | jq -r '.status // "unknown"')
  CONCLUSION=$(echo "$WORKFLOW_DATA" | jq -r '.conclusion // "none"')

  echo "[$(date +%H:%M:%S)] Status: $STATUS"

  # Check if completed
  if [ "$STATUS" = "completed" ]; then
    echo ""

    if [ "$CONCLUSION" = "success" ]; then
      echo "✅ Production deployment successful!"
      echo ""

      # Get deployment details
      JOBS=$(echo "$WORKFLOW_DATA" | jq -r '.jobs[] | "\(.name): \(.conclusion)"')
      echo "Job results:"
      echo "$JOBS" | sed 's/^success$/✅ success/' | sed 's/^/  /'
      echo ""

      DEPLOYMENT_SUCCESS=true
      break
    else
      echo "❌ Production deployment failed"
      echo ""

      # Show failed jobs
      FAILED_JOBS=$(echo "$WORKFLOW_DATA" | jq -r '.jobs[] | select(.conclusion!="success") | .name')

      if [ -n "$FAILED_JOBS" ]; then
        echo "Failed jobs:"
        echo "$FAILED_JOBS" | sed 's/^/  ❌ /'
        echo ""
      fi

      echo "View logs: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"
      echo ""
      echo "Common issues:"
      echo "  - Canary smoke tests failed: Check production URLs, verify health endpoints"
      echo "  - Alias flip failed: Check Vercel token permissions, verify custom domains"
      echo "  - API deployment failed: Check Railway service, verify Docker image exists"
      exit 1
    fi
  fi

  # Wait before next poll
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

if [ "$DEPLOYMENT_SUCCESS" != true ]; then
  echo ""
  echo "⏱️  Timeout: Deployment taking >30 minutes"
  echo "Check status: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID"
  exit 1
fi
```

---

### Phase 2.7: CAPTURE DEPLOYMENT ARTIFACTS

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Capturing Deployment Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get deployment details from workflow logs
DEPLOY_LOGS=$(gh run view "$RUN_ID" --log 2>/dev/null || echo "")

# Extract Vercel deployment IDs
MARKETING_DEPLOY=$(echo "$DEPLOY_LOGS" | grep -oE "cfipros-[a-z0-9]+\.vercel\.app" | head -1 || echo "")
APP_DEPLOY=$(echo "$DEPLOY_LOGS" | grep -oE "app-cfipros-[a-z0-9]+\.vercel\.app" | head -1 || echo "")

# Extract Railway/Docker image
API_IMAGE=$(echo "$DEPLOY_LOGS" | grep -oE "ghcr\.io/.*/api:$SHORT_SHA" | head -1 || echo "")

echo "Deployment artifacts:"
if [ -n "$MARKETING_DEPLOY" ]; then
  echo "  Marketing: $MARKETING_DEPLOY"
else
  echo "  Marketing: [Check workflow logs]"
fi

if [ -n "$APP_DEPLOY" ]; then
  echo "  App: $APP_DEPLOY"
else
  echo "  App: [Check workflow logs]"
fi

if [ -n "$API_IMAGE" ]; then
  echo "  API: $API_IMAGE"
else
  echo "  API: [Check workflow logs]"
fi

echo ""
```

---

### Phase 2.8: VALIDATE PRODUCTION HEALTH

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Production Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Waiting for DNS propagation..."
sleep 30

# Marketing
echo "Checking marketing..."
if curl -sf "$PROD_MARKETING" > /dev/null 2>&1; then
  echo "  ✅ Marketing responding"
else
  echo "  ⚠️  Marketing not responding (may need DNS time)"
fi

# App
echo "Checking app..."
if curl -sf "$PROD_APP" > /dev/null 2>&1; then
  echo "  ✅ App responding"
else
  echo "  ⚠️  App not responding (may need DNS time)"
fi

# API health endpoint
echo "Checking API health..."
if curl -sf "$PROD_API/api/v1/health/healthz" 2>/dev/null | grep -q "healthy"; then
  echo "  ✅ API healthy"
else
  echo "  ⚠️  API not healthy"
  echo "     Check: $PROD_API/api/v1/health/healthz"
fi

echo ""
echo "✅ Health checks complete"
echo "   Note: DNS propagation may take 5-10 minutes"
echo ""
```

---

### Phase 2.9: DETERMINE VERSION NUMBER

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Determining Version Number"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if CHANGELOG.md exists
if [ ! -f "CHANGELOG.md" ]; then
  echo "⚠️  CHANGELOG.md not found"
  echo "   Starting at v1.0.0"
  CURRENT_VERSION="v0.0.0"
else
  # Extract latest version from CHANGELOG
  CURRENT_VERSION=$(grep -E "^## \[?v?[0-9]+" CHANGELOG.md | head -1 | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+" | head -1 || echo "")

  if [ -z "$CURRENT_VERSION" ]; then
    echo "⚠️  No version found in CHANGELOG.md"
    CURRENT_VERSION="v0.0.0"
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
    ;;
  2)
    NEXT_VERSION="$MINOR_VERSION"
    ;;
  3)
    NEXT_VERSION="$MAJOR_VERSION"
    ;;
  4)
    read -p "Enter custom version (e.g., v1.2.3): " NEXT_VERSION
    # Validate format
    if ! [[ "$NEXT_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "❌ Invalid version format"
      exit 1
    fi
    # Add v prefix if missing
    if [[ ! "$NEXT_VERSION" =~ ^v ]]; then
      NEXT_VERSION="v$NEXT_VERSION"
    fi
    ;;
  *)
    NEXT_VERSION="$PATCH_VERSION"
    ;;
esac

echo ""
echo "Selected version: $NEXT_VERSION"
echo ""
```

---

### Phase 2.10: CREATE VERSION TAG

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating Version Tag"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ensure on main and up to date
git fetch origin main --quiet
git checkout main --quiet
git pull origin main --quiet

echo "Creating tag: $NEXT_VERSION"
echo ""

# Check if tag already exists
if git rev-parse "$NEXT_VERSION" >/dev/null 2>&1; then
  echo "⚠️  Tag $NEXT_VERSION already exists"
  echo ""
  echo "Options:"
  echo "  1. Use existing tag"
  echo "  2. Delete and recreate"
  echo "  3. Choose different version"
  read -p "Choose (1-3): " TAG_OPTION

  case "$TAG_OPTION" in
    1)
      echo "Using existing tag"
      ;;
    2)
      echo "Deleting existing tag..."
      git tag -d "$NEXT_VERSION"
      git push origin ":refs/tags/$NEXT_VERSION" 2>/dev/null || true

      # Create new tag
      git tag -a "$NEXT_VERSION" "$COMMIT_SHA" -m "Release $NEXT_VERSION: $SLUG"
      git push origin "$NEXT_VERSION"
      echo "✅ Tag recreated"
      ;;
    3)
      echo "Please re-run /phase-2-ship and choose different version"
      exit 1
      ;;
  esac
else
  # Create new tag
  git tag -a "$NEXT_VERSION" "$COMMIT_SHA" -m "Release $NEXT_VERSION: $SLUG"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to create tag"
    exit 1
  fi

  # Push tag
  git push origin "$NEXT_VERSION"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to push tag"
    echo "   Tag created locally but not on remote"
    echo "   Try: git push origin $NEXT_VERSION"
    exit 1
  fi

  echo "✅ Tag created and pushed: $NEXT_VERSION"
fi

echo ""
```

---

### Phase 2.11: GENERATE RELEASE NOTES

```bash
echo "Generating release notes..."
echo ""

if [ ! -f "$SPEC_FILE" ]; then
  echo "⚠️  spec.md not found, using default notes"
  FEATURE_DESCRIPTION="New feature: $SLUG"
  KEY_FEATURES="- Feature deployed to production"
else
  # Extract description from spec.md
  FEATURE_DESCRIPTION=$(sed -n '/## Summary/,/^## /p' "$SPEC_FILE" | grep -v "^## " | head -5 | sed '/^$/d')

  if [ -z "$FEATURE_DESCRIPTION" ]; then
    FEATURE_DESCRIPTION="New feature: $SLUG"
  fi

  # Extract key features from functional requirements
  KEY_FEATURES=$(sed -n '/## Functional Requirements/,/^## /p' "$SPEC_FILE" | \
                 grep "^- " | \
                 head -5 | \
                 sed 's/^- /- ✅ /')

  if [ -z "$KEY_FEATURES" ]; then
    KEY_FEATURES="- ✅ Feature deployed to production"
  fi
fi

# Create release notes
RELEASE_NOTES=$(cat <<EOF
## What's New

$FEATURE_DESCRIPTION

## Changes

$KEY_FEATURES

## Deployment

- **Marketing**: $PROD_MARKETING
- **App**: $PROD_APP
- **API**: $PROD_API

## Validation

All production checks passed:
- ✅ Full CI suite
- ✅ Staging validation complete
- ✅ Production deployments successful
- ✅ Canary smoke tests passing
- ✅ Production alias updated

## Rollback

If needed, production can be rolled back using:

\`\`\`bash
# Vercel
vercel rollback $PROD_MARKETING --token=\$VERCEL_TOKEN
vercel rollback $PROD_APP --token=\$VERCEL_TOKEN

# Railway
railway deployments --service api --environment production
railway redeploy [PREVIOUS_ID]
\`\`\`

---
🤖 Generated with [Claude Code](https://claude.ai/claude-code)
EOF
)

# Save to temp file
echo "$RELEASE_NOTES" > /tmp/release-notes-$SLUG.md

echo "✅ Release notes generated"
echo ""
```

---

### Phase 2.12: CREATE GITHUB RELEASE

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating GitHub Release"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create release
gh release create "$NEXT_VERSION" \
  --title "$NEXT_VERSION: $SLUG" \
  --notes-file /tmp/release-notes-$SLUG.md

if [ $? -ne 0 ]; then
  echo "❌ Failed to create GitHub release"
  echo ""
  echo "Manual release creation:"
  echo "  1. Go to: https://github.com/$GITHUB_REPO/releases/new?tag=$NEXT_VERSION"
  echo "  2. Title: $NEXT_VERSION: $SLUG"
  echo "  3. Notes: cat /tmp/release-notes-$SLUG.md"
  echo ""
  echo "Continuing anyway..."
else
  echo "✅ GitHub release created"
  RELEASE_URL="https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION"
  echo "   URL: $RELEASE_URL"
fi

echo ""

# Cleanup temp file
rm -f /tmp/release-notes-$SLUG.md
```

---

### Phase 2.13: UPDATE ROADMAP

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Updating Roadmap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "$ROADMAP_FILE" ]; then
  echo "⚠️  Roadmap not found: $ROADMAP_FILE"
  echo "   Skipping roadmap update"
else
  # Find feature in "In Progress" section
  FEATURE_SECTION=$(sed -n "/## In Progress/,/## /p" "$ROADMAP_FILE" | \
                    grep -A 20 "### $SLUG" || echo "")

  if [ -z "$FEATURE_SECTION" ]; then
    echo "⚠️  Feature '$SLUG' not found in roadmap"
    echo "   Manual update may be needed"
  else
    echo "Found feature in roadmap: $SLUG"
    echo ""

    # Extract feature metadata
    TITLE=$(echo "$FEATURE_SECTION" | grep "Title:" | sed 's/.*Title: //' | head -1)
    AREA=$(echo "$FEATURE_SECTION" | grep "Area:" | sed 's/.*Area: //' | head -1)
    ROLE=$(echo "$FEATURE_SECTION" | grep "Role:" | sed 's/.*Role: //' | head -1)
    REQUIREMENTS=$(echo "$FEATURE_SECTION" | sed -n '/Requirements:/,/^$/p' | grep "^  -")

    # Create shipped entry
    SHIPPED_ENTRY="### $SLUG
- **Title**: $TITLE
- **Area**: $AREA
- **Role**: $ROLE
- **Date**: $(date +%Y-%m-%d)
- **Release**: $NEXT_VERSION - $(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
- **Requirements**:
$REQUIREMENTS"

    # Create temp file with updated roadmap
    awk -v slug="$SLUG" -v entry="$SHIPPED_ENTRY" '
      # Remove from In Progress section
      /^### / {
        if ($0 ~ slug && in_progress) {
          skip = 1
          next
        }
      }
      /^## In Progress/ { in_progress = 1 }
      /^## / && !/^## In Progress/ { in_progress = 0; skip = 0 }

      # Add to Shipped section
      /^## Shipped/ {
        print
        print ""
        print entry
        next
      }

      # Print all non-skipped lines
      !skip { print }
    ' "$ROADMAP_FILE" > /tmp/roadmap-updated.md

    mv /tmp/roadmap-updated.md "$ROADMAP_FILE"

    echo "✅ Roadmap updated"
    echo "   Moved $SLUG to Shipped section"
    echo ""

    # Commit roadmap update
    git add "$ROADMAP_FILE"
    git commit -m "docs: mark $SLUG as shipped ($NEXT_VERSION)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

    git push origin main

    echo "✅ Roadmap changes committed and pushed"
    echo ""
  fi
fi
```

---

### Phase 2.14: UPDATE NOTES.MD

```bash
echo "Updating NOTES.md with deployment metadata..."
echo ""

# Source the template
source \spec-flow/templates/notes-update-template.sh

# Add Phase 8 (Production) checkpoint
update_notes_checkpoint "$FEATURE_DIR" "8" "Ship to Production" \
  "Version: $NEXT_VERSION" \
  "Commit: $SHORT_SHA" \
  "Workflow: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID" \
  "Release: https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION"

# Add Production Deployment section (custom section with deployment IDs)
cat >> "$NOTES_FILE" <<EOF

## Production Deployment

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Version**: $NEXT_VERSION
**Commit**: $SHORT_SHA

### Deployment IDs

| Service | Deploy ID | Status |
|---------|-----------|--------|
| Marketing | ${MARKETING_DEPLOY:-See logs} | ✅ Deployed |
| App | ${APP_DEPLOY:-See logs} | ✅ Deployed |
| API | ${API_IMAGE:-See logs} | ✅ Deployed |

**Workflow**: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID
**Release**: https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION

EOF

update_notes_timestamp "$FEATURE_DIR"

echo "✅ Deployment metadata saved to NOTES.md"
echo ""
```

---

### Phase 2.15: CREATE SHIP REPORT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Creating Ship Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get staging validation summary
STAGING_SUMMARY=$(sed -n '/## Deployment Readiness/,/## /p' "$VALIDATION_REPORT" | grep -v "^## " | head -15)

cat > "$SHIP_REPORT" <<EOF
# Production Ship Report

**Date**: $(date +"%Y-%m-%d %H:%M")
**Feature**: $SLUG
**Version**: $NEXT_VERSION

## Deployment Status

**Workflow**: promote.yml (#$RUN_ID)
**Commit SHA**: $COMMIT_SHA
**Released**: $NEXT_VERSION on $(date +%Y-%m-%d)

## Production URLs

- **Marketing**: $PROD_MARKETING
- **App**: $PROD_APP
- **API**: $PROD_API

## Deployment Results

**Prerequisites**: ✅ Passed
**Deploy Web**: ✅ Passed
**Deploy API**: ✅ Passed
**Canary Smoke Tests**: ✅ Passed
**Alias Flip**: ✅ Completed

### Deployment Details

| Service | Deploy ID | Status |
|---------|-----------|--------|
| Marketing | ${MARKETING_DEPLOY:-See logs} | ✅ Deployed |
| App | ${APP_DEPLOY:-See logs} | ✅ Deployed |
| API | ${API_IMAGE:-See logs} | ✅ Deployed |

## Staging Validation Summary

$STAGING_SUMMARY

## Release Notes

$RELEASE_NOTES

## Rollback Plan

If issues arise in production:

**Vercel (marketing + app):**
\`\`\`bash
vercel rollback $PROD_MARKETING --token=\$VERCEL_TOKEN
vercel rollback $PROD_APP --token=\$VERCEL_TOKEN
\`\`\`

**Railway (API):**
\`\`\`bash
railway deployments --service api --environment production
railway redeploy [PREVIOUS_DEPLOYMENT_ID] --service api --environment production
\`\`\`

**Git revert:**
\`\`\`bash
git checkout main
git revert $COMMIT_SHA
git push origin main
\`\`\`

## Monitoring

**Next Steps:**
- [ ] Monitor production metrics (PostHog, Sentry)
- [ ] Watch for error spikes in first 24 hours
- [ ] Validate user feedback
- [ ] Update documentation if needed

**Links:**
- Sentry: https://sentry.io/organizations/cfipros/issues/
- PostHog: https://app.posthog.com
- Workflow: https://github.com/$GITHUB_REPO/actions/runs/$RUN_ID
- Release: https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION

---
*Generated by /phase-2-ship command*
EOF

echo "✅ Ship report created: $SHIP_REPORT"
echo ""
```

---

### Phase 2.16: SETUP MONITORING

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Production Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Monitoring checklist:"
echo "  [ ] Sentry release created for $NEXT_VERSION"
echo "  [ ] PostHog feature flag enabled (if applicable)"
echo "  [ ] Error alerts configured"
echo "  [ ] Performance monitoring active"
echo ""

# Create Sentry release if configured
if command -v sentry-cli &>/dev/null; then
  echo "Creating Sentry release..."

  export SENTRY_ORG="cfipros"
  export SENTRY_PROJECT="app"

  sentry-cli releases new "$NEXT_VERSION" --finalize 2>/dev/null || echo "⚠️  Sentry release creation failed (may need auth)"
  sentry-cli releases set-commits "$NEXT_VERSION" --commit "$GITHUB_REPO@$COMMIT_SHA" 2>/dev/null || true

  echo "✅ Sentry release created (if authenticated)"
else
  echo "⚠️  sentry-cli not installed"
  echo "   Install: npm install -g @sentry/cli"
fi

echo ""

# PostHog feature flag reminder
echo "PostHog feature flags:"
echo "  If this feature uses a flag, enable it now:"
echo "  https://app.posthog.com/project/[PROJECT]/feature_flags"
echo ""

echo "Monitor production for 24-48 hours:"
echo "  - Error rates: https://sentry.io/organizations/cfipros/issues/"
echo "  - Performance: https://app.posthog.com"
echo "  - Logs: Vercel Dashboard, Railway Dashboard"
echo ""
```

---

### Phase 2.17: FINAL OUTPUT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Production Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "**Feature**: $SLUG"
echo "**Version**: $NEXT_VERSION"
echo "**Release**: ${RELEASE_URL:-https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION}"
echo ""

echo "### Deployed to Production"
echo ""
echo "- ✅ Marketing: $PROD_MARKETING"
echo "- ✅ App: $PROD_APP"
echo "- ✅ API: $PROD_API"
echo ""

echo "### Validation"
echo ""
echo "- ✅ Prerequisites passed"
echo "- ✅ All deployments successful"
echo "- ✅ Canary smoke tests passing"
echo "- ✅ Alias flip completed"
echo "- ✅ Roadmap updated (moved to \"Shipped\")"
echo ""

echo "### Reports"
echo ""
echo "- Ship report: $SHIP_REPORT"
echo "- GitHub release: ${RELEASE_URL:-https://github.com/$GITHUB_REPO/releases/tag/$NEXT_VERSION}"
echo ""

echo "### Next Steps"
echo ""
echo "1. Monitor production metrics (PostHog, Sentry)"
echo "2. Watch for error spikes in first 24 hours"
echo "3. Celebrate! 🎉"
echo ""

echo "---"
echo "**Workflow complete**:\spec-flow → ... → optimize → preview → phase-1-ship → validate-staging → phase-2-ship ✅"
echo ""
```

---

## ERROR HANDLING

**If working tree dirty:**
```markdown
❌ Error: Uncommitted changes detected

Please commit or stash changes:
```bash
git status
git add .
git commit -m "chore: prepare for production deployment"
# OR
git stash
```

Then run /phase-2-ship again.
```

**If staging-validation-report.md missing:**
```markdown
❌ Error: Staging validation report not found

Run /validate-staging first to validate the staging deployment.

Expected file: specs/[feature-slug]/staging-validation-report.md
```

**If staging validation failed:**
```markdown
❌ Error: Staging validation has blockers

The staging-validation-report.md shows:

**Blockers:**
- ❌ [Blocker 1]
- ❌ [Blocker 2]

Please fix these issues, then run /validate-staging again.

Once all checks pass (✅ Ready for Production), run /phase-2-ship.
```

**If workflow trigger fails:**
```markdown
❌ Error: Could not trigger promote.yml workflow

Reason: [gh workflow run error]

**Manual trigger:**
1. Go to: https://github.com/cfipros/monorepo/actions/workflows/promote.yml
2. Click "Run workflow"
3. Select branch: main
4. Enter SHA: [COMMIT_SHA]
5. Click "Run workflow"

Then monitor: https://github.com/cfipros/monorepo/actions
```

**If production deployment fails:**
```markdown
❌ Error: Production deployment failed

**Failed job**: [job-name]

**Logs**: https://github.com/cfipros/monorepo/actions/runs/[run-id]

**Common issues**:
- Canary smoke tests failed: Check production URLs, verify health endpoints
- Alias flip failed: Check Vercel token permissions, verify custom domains
- API deployment failed: Check Railway service, verify Docker image exists

**Rollback** (if needed):
```bash
# Vercel
vercel rollback https://cfipros.com --token=$VERCEL_TOKEN
vercel rollback https://app.cfipros.com --token=$VERCEL_TOKEN

# Railway
railway deployments --service api --environment production
railway redeploy [PREVIOUS_ID] --service api --environment production
```

**Next steps:**
1. Review workflow logs
2. Fix deployment issues
3. Run /phase-2-ship again
```

**If version tag creation fails:**
```markdown
❌ Error: Could not create version tag

Reason: [git error]

**Manual tag creation:**
```bash
git checkout main
git pull origin main
git tag -a v[X.Y.Z] -m "Release v[X.Y.Z]: [Feature Name]"
git push origin v[X.Y.Z]
```

Then create GitHub release manually:
https://github.com/cfipros/monorepo/releases/new?tag=v[X.Y.Z]
```

---

## CONSTRAINTS

- ALWAYS validate staging-validation-report.md before proceeding
- NEVER skip quota checking (prevents rate limit errors)
- Deployment must complete successfully before creating release
- Version tag must be created before GitHub release
- Roadmap update is optional but recommended
- Ship report documents the complete deployment for future reference

---

## RETURN

```markdown
## 🎉 Production Deployment Complete!

**Feature**: [feature-slug]
**Version**: v[X.Y.Z]
**Release**: https://github.com/cfipros/monorepo/releases/tag/v[X.Y.Z]

### Deployed to Production

- ✅ Marketing: https://cfipros.com
- ✅ App: https://app.cfipros.com
- ✅ API: https://api.cfipros.com

### Validation

- ✅ Prerequisites passed
- ✅ All deployments successful
- ✅ Canary smoke tests passing
- ✅ Alias flip completed
- ✅ Roadmap updated (moved to "Shipped")

### Reports

- Ship report: specs/[feature-slug]/ship-report.md
- GitHub release: https://github.com/cfipros/monorepo/releases/tag/v[X.Y.Z]

### Next Steps

1. Monitor production metrics (PostHog, Sentry)
2. Watch for error spikes in first 24 hours
3. Celebrate! 🎉

---
**Workflow complete**:\spec-flow → ... → optimize → preview → phase-1-ship → validate-staging → phase-2-ship ✅
```


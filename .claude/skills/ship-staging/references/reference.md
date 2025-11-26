# Ship Staging — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-20

This document provides comprehensive reference material for the `/ship-staging` command (internally `/phase-1-ship`), including pre-flight validation procedures, PR creation workflow, health check protocols, and deployment metadata capture.

---

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [Pre-Flight Validation](#pre-flight-validation)
3. [Deployment Mode Selection](#deployment-mode-selection)
4. [Pull Request Creation](#pull-request-creation)
5. [Auto-Merge Configuration](#auto-merge-configuration)
6. [Health Check Procedures](#health-check-procedures)
7. [Deployment Metadata Capture](#deployment-metadata-capture)
8. [Staging Ship Report](#staging-ship-report)
9. [Error Conditions](#error-conditions)
10. [Rollback Procedures](#rollback-procedures)

---

## Workflow Overview

### State Machine

```
Feature Branch → Pre-Flight Validation → Create PR → Enable Auto-Merge →
Wait for CI → Health Checks → Capture Metadata → Generate Report →
Suggest /validate-staging
```

### Integration Point

**Called by**: `/ship` (parent orchestrator)

**Position in workflow**:

```
/feature → /clarify → /plan → /tasks → /analyze → /implement →
/optimize → /preview → **/ ship-staging** → /validate-staging → /ship-prod
```

### Auto-Suggestions

After successful staging deployment:

- **Next step**: `/validate-staging` for manual testing
- **If CI fails**: `/checks pr [number]` to investigate

---

## Pre-Flight Validation

The command performs 6 critical validation checks before deployment.

### Check 1: Remote Repository Configuration

**Purpose**: Ensure remote repository exists with staging workflow

**Validation**:

```bash
# Check remote origin exists
git remote -v | grep -q "origin"

# Check staging branch exists (local or remote)
git show-ref --verify --quiet refs/heads/staging || \
git show-ref --verify --quiet refs/remotes/origin/staging
```

**Error conditions**:

- **No remote**: Display instructions to add remote repository
- **No staging branch**: Show commands to create staging branch

**Remediation**:

```bash
# Add remote
git remote add origin <repository-url>
git push -u origin main

# Create staging branch
git checkout -b staging main
git push -u origin staging
```

### Check 2: Clean Working Tree

**Purpose**: Prevent deploying uncommitted changes

**Validation**:

```bash
git status --porcelain
```

**Error conditions**:

- Uncommitted changes exist
- Untracked files present

**Remediation**:

```bash
# Commit changes
git add .
git commit -m "..."

# Or stash
git stash
```

### Check 3: Optimization Complete

**Purpose**: Ensure `/optimize` phase completed successfully

**Validation**:

```bash
# Check for optimization-report.md
test -f "$FEATURE_DIR/optimization-report.md"

# Verify quality gates passed
grep -q "✅.*PASSED" "$FEATURE_DIR/optimization-report.md"
```

**Error conditions**:

- optimization-report.md missing
- Quality gates failed

**Remediation**:
Run `/optimize` to complete quality gates

### Check 4: Pre-Flight Smoke Tests

**Purpose**: Run quick local tests before deployment

**Test suite**:

- Build validation (if applicable)
- Linting checks
- Unit test subset (fast tests only)
- Type checking

**Example**:

```bash
# Node.js project
pnpm run type-check
pnpm run lint
pnpm run test:unit --bail
```

**Error conditions**:

- Any test fails
- Build errors
- Type errors

**Remediation**:
Fix issues locally before proceeding

### Check 5: Deployment Budget

**Purpose**: Check quota before consuming Vercel deployments

**Validation**:

```bash
# Count deployments in last 24h
DEPLOYMENTS=$(gh run list --workflow=deploy-staging.yml \
  --created="$(date -d '24 hours ago' -Iseconds)" \
  --json conclusion --jq 'length')

# Check remaining quota
REMAINING=$((100 - DEPLOYMENTS))

if [ "$REMAINING" -lt 2 ]; then
  echo "⚠️  Low deployment quota: $REMAINING remaining"
  # Suggest preview mode or wait
fi
```

**Thresholds**:

- **< 10 remaining**: Critical, block deployment
- **< 20 remaining**: Warning, suggest preview mode
- **>= 20 remaining**: Safe to proceed

### Check 6: Environment Variables

**Purpose**: Verify required environment variables exist

**Required variables**:

- `VERCEL_TOKEN` (or `VERCEL_ORG_ID` + `VERCEL_PROJECT_ID`)
- `DATABASE_URL` (if using database)
- `REDIS_URL` (if using cache)
- Application-specific secrets

**Validation**:

```bash
# Check .env.staging exists
test -f .env.staging

# Verify required vars set
grep -q "VERCEL_TOKEN" .env.staging
```

**Error conditions**:

- .env.staging missing
- Required variables not set

**Remediation**:
Create .env.staging with required variables

---

## Deployment Mode Selection

### Modes

**Staging Mode** (default):

- Deploys to staging.{domain}.com
- Consumes Vercel quota (2 deployments per ship)
- Updates staging environment
- Triggers CI/CD pipeline

**Preview Mode** (quota-conscious):

- Creates preview deployment
- Does NOT consume quota
- Does NOT update staging.{domain}.com
- Unlimited usage
- Ideal for testing CI without quota cost

### Mode Selection Logic

```bash
echo "Deployment mode:"
echo "  1) Staging (updates staging.{domain}.com) - Consumes quota"
echo "  2) Preview (CI testing only) - Free, unlimited"
echo ""
read -p "Select mode (1/2): " MODE_CHOICE

case "$MODE_CHOICE" in
  1)
    DEPLOYMENT_MODE="staging"
    ;;
  2)
    DEPLOYMENT_MODE="preview"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac
```

### Mode Implications

**Staging mode**:

- ✅ Updates staging environment
- ✅ Runs full CI pipeline
- ❌ Consumes quota (2 per ship)
- ❌ Requires quota availability

**Preview mode**:

- ✅ Free, unlimited
- ✅ Tests CI without quota cost
- ❌ Does NOT update staging environment
- ❌ Preview URL expires after 7 days

---

## Pull Request Creation

### PR Title Format

```
feat: {feature-title} ({slug})
```

**Example**:

```
feat: User Authentication System (001-user-auth)
```

### PR Body Structure

```markdown
## Summary

{1-3 sentence feature summary from spec.md}

## Implementation Highlights

- {Key implementation detail 1}
- {Key implementation detail 2}
- {Key implementation detail 3}

## Testing

- {Test coverage summary}
- {Manual testing notes}

## Deployment

- Deployment mode: {staging|preview}
- Estimated cost: {2 quota if staging, 0 if preview}
- Health checks: {enabled|disabled}

## Next Steps

After merge and CI success:

1. Run `/validate-staging` for manual testing
2. Monitor staging environment for issues
3. Proceed with `/ship-prod` when validated

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### PR Creation Command

```bash
gh pr create \
  --base main \
  --head "$CURRENT_BRANCH" \
  --title "$PR_TITLE" \
  --body "$PR_BODY" \
  --assignee "@me"
```

**Error conditions**:

- PR already exists for branch
- Base branch doesn't exist
- GitHub CLI not authenticated

---

## Auto-Merge Configuration

### Enable Auto-Merge

```bash
PR_NUMBER=$(gh pr view --json number --jq '.number')

gh pr merge "$PR_NUMBER" \
  --auto \
  --squash \
  --delete-branch
```

**Flags**:

- `--auto`: Enable auto-merge (merges when CI passes)
- `--squash`: Squash commits into single commit
- `--delete-branch`: Delete feature branch after merge

### Auto-Merge Behavior

**Merge conditions**:

- All required CI checks pass
- No merge conflicts
- Branch up-to-date with base

**Merge method**: Squash merge

- Combines all feature commits into single commit
- Clean main branch history
- Commit message: PR title + body

**Branch cleanup**:

- Feature branch deleted automatically
- Local branch remains (user must delete manually if desired)

### Monitor CI Progress

```bash
# CRITICAL: Check if PR already merged (for /epic continue resume cases)
PR_STATE=$(gh pr view "$PR_NUMBER" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")

if [ "$PR_STATE" = "MERGED" ]; then
  echo "✅ PR already merged (resume detected), skipping CI wait"
else
  # Wait for initial CI trigger
  sleep 10

  # Check CI status
  gh pr checks "$PR_NUMBER"

  # Wait for CI completion (with 30-minute timeout and manual override)
  TIMEOUT=1800  # 30 minutes
  ELAPSED=0
  START_TIME=$(date +%s)

  while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '.statusCheckRollup[0].state')

    if [ "$STATUS" = "SUCCESS" ]; then
      echo "✅ CI checks passed"
      break
    elif [ "$STATUS" = "FAILURE" ]; then
      echo "❌ CI checks failed"
      exit 1
    elif [ "$STATUS" = "MERGED" ]; then
      echo "✅ PR merged while waiting (auto-merge succeeded)"
      break
    fi

    # Show progress every 5 minutes
    if [ $((ELAPSED % 300)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
      echo "⏱️  CI still running... ($((ELAPSED / 60)) minutes elapsed)"
    fi

    sleep 30
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
  done

  # Handle timeout with manual override prompt
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "⏱️  CI wait exceeded 30 minutes"
    echo ""
    echo "Current PR state: $PR_STATE"
    echo "Current CI status: $STATUS"
    echo ""
    echo "Options:"
    echo "  1) Continue anyway (CI may still be running, proceed to health checks)"
    echo "  2) Abort (investigate CI manually and re-run /ship later)"
    echo ""
    read -p "Choice [1]: " TIMEOUT_CHOICE

    if [ "${TIMEOUT_CHOICE:-1}" = "1" ]; then
      echo "⚠️  Continuing despite timeout..."
    else
      echo "❌ Aborting ship-staging workflow"
      echo "   Check CI status: gh pr checks $PR_NUMBER"
      echo "   View logs: gh run view --log"
      exit 1
    fi
  fi
fi
```

---

## Health Check Procedures

After CI passes and deployment completes, run health checks to verify deployment success.

### Check 1: Deployment URL Accessibility

**Marketing site**:

```bash
curl -sS -o /dev/null -w "%{http_code}" https://staging.{domain}.com
# Expected: 200
```

**App site**:

```bash
curl -sS -o /dev/null -w "%{http_code}" https://app.staging.{domain}.com
# Expected: 200
```

**Error conditions**:

- 404: Site not deployed
- 500: Server error
- Timeout: Network issue or site down

### Check 2: API Health Endpoint

```bash
curl -sS https://app.staging.{domain}.com/api/health | jq
# Expected: {"status":"ok","timestamp":"..."}
```

**Health endpoint contract**:

```json
{
  "status": "ok",
  "timestamp": "2025-01-08T14:30:00Z",
  "database": "connected",
  "redis": "connected",
  "version": "1.2.0"
}
```

### Check 3: Database Connectivity

```bash
# Via health endpoint
curl -sS https://app.staging.{domain}.com/api/health | jq '.database'
# Expected: "connected"
```

**Error conditions**:

- "disconnected": Database connection failed
- null: Health endpoint doesn't check database
- Timeout: API not responding

### Check 4: Deployment Metadata Validation

```bash
# Check Vercel deployment ID exists
curl -sS https://staging.{domain}.com/_vercel/deployment.json | jq '.id'

# Check build timestamp
curl -sS https://staging.{domain}.com/_vercel/deployment.json | jq '.createdAt'
```

---

## Deployment Metadata Capture

### Metadata to Capture

```yaml
deployment:
  staging:
    deployed: true
    timestamp: "2025-01-08T14:30:00Z"
    commit_sha: "abc1234567890"
    pr_number: 42
    deployment_ids:
      marketing: "marketing-xyz789.vercel.app"
      app: "app-def456.vercel.app"
      api: "ghcr.io/org/api:sha123abc"
    urls:
      marketing: "https://staging.{domain}.com"
      app: "https://app.staging.{domain}.com"
    health_checks:
      marketing_http: "passed"
      app_http: "passed"
      api_health: "passed"
      database: "connected"
```

### Capture Vercel Deployment IDs

```bash
# Get latest deployment for project
MARKETING_ID=$(vercel ls --scope "$VERCEL_ORG" "$MARKETING_PROJECT" --json | \
  jq -r '.[0].url')

APP_ID=$(vercel ls --scope "$VERCEL_ORG" "$APP_PROJECT" --json | \
  jq -r '.[0].url')
```

### Update state.yaml

```bash
yq eval -i ".deployment.staging.deployed = true" "$STATE_FILE"
yq eval -i ".deployment.staging.timestamp = \"$(date -Iseconds)\"" "$STATE_FILE"
yq eval -i ".deployment.staging.commit_sha = \"$COMMIT_SHA\"" "$STATE_FILE"
yq eval -i ".deployment.staging.pr_number = $PR_NUMBER" "$STATE_FILE"
yq eval -i ".deployment.staging.deployment_ids.marketing = \"$MARKETING_ID\"" "$STATE_FILE"
yq eval -i ".deployment.staging.deployment_ids.app = \"$APP_ID\"" "$STATE_FILE"
```

### Create deployment-metadata.json

```json
{
  "environment": "staging",
  "timestamp": "2025-01-08T14:30:00Z",
  "commit_sha": "abc1234567890",
  "pr_number": 42,
  "deployments": {
    "marketing": {
      "url": "https://staging.{domain}.com",
      "deployment_id": "marketing-xyz789.vercel.app",
      "health_check": "passed"
    },
    "app": {
      "url": "https://app.staging.{domain}.com",
      "deployment_id": "app-def456.vercel.app",
      "health_check": "passed"
    }
  },
  "rollback": {
    "previous_commit": "def9876543210",
    "rollback_command": "git revert abc1234567890 && git push origin main"
  }
}
```

---

## Staging Ship Report

### Report Structure

**File**: `specs/{slug}/staging-ship-report.md`

**Sections**:

1. **Deployment Summary** - Status, timestamp, commit, PR
2. **Deployment Details** - URLs, IDs, health checks
3. **Quality Gates** - Pre-flight results, CI status
4. **Rollback Metadata** - Previous commit, rollback commands
5. **Next Steps** - Validation checklist, production readiness

**Example**:

````markdown
# Staging Deployment Report

**Feature**: 001-user-auth
**Deployed**: 2025-01-08 14:30:00
**Status**: ✅ SUCCESS

## Deployment Summary

- **Commit**: abc1234567890
- **PR**: #42 (auto-merged)
- **CI Status**: ✅ All checks passed
- **Deployment Mode**: staging

## Deployment Details

### Marketing Site

- **URL**: https://staging.{domain}.com
- **Deployment ID**: marketing-xyz789.vercel.app
- **Health Check**: ✅ PASSED (200 OK)

### App Site

- **URL**: https://app.staging.{domain}.com
- **Deployment ID**: app-def456.vercel.app
- **Health Check**: ✅ PASSED (200 OK)
- **API Health**: ✅ PASSED (database connected)

## Quality Gates

✅ Pre-flight validation passed
✅ Optimization complete
✅ CI checks passed
✅ Health checks passed

## Rollback Metadata

**Previous Commit**: def9876543210

**Rollback Commands**:

```bash
# Revert commit
git revert abc1234567890
git push origin main

# Or reset to previous
git reset --hard def9876543210
git push --force origin main
```
````

## Next Steps

1. **Validate Staging**:

   ```bash
   /validate-staging
   ```

2. **Manual Testing Checklist**:

   - [ ] Test authentication flow
   - [ ] Verify database operations
   - [ ] Check API responses
   - [ ] Test error handling

3. **Production Deployment**:
   After validation complete:
   ```bash
   /ship-prod
   ```

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

````

---

## Error Conditions

### PR Creation Fails

**Causes**:
- PR already exists for branch
- GitHub CLI not authenticated
- Network error

**Remediation**:
```bash
# Check existing PRs
gh pr list --head "$BRANCH_NAME"

# Re-authenticate
gh auth login

# Retry PR creation
gh pr create ...
````

### Auto-Merge Fails

**Causes**:

- Merge conflicts
- CI checks failed
- Branch protection rules

**Remediation**:

```bash
# Check PR status
gh pr view "$PR_NUMBER"

# Resolve conflicts
git pull origin main
git merge main
git push

# Check CI logs
gh pr checks "$PR_NUMBER"
```

### Health Checks Fail

**Causes**:

- Deployment not complete
- Service errors
- Database connection issues

**Remediation**:

```bash
# Check deployment logs
vercel logs "$DEPLOYMENT_ID"

# Check service status
curl -v https://staging.{domain}.com

# Investigate errors
/debug
```

### Deployment Timeout

**Causes**:

- CI takes longer than timeout (10 minutes)
- Build errors
- Test failures

**Remediation**:

```bash
# Check CI status
gh pr checks "$PR_NUMBER"

# View workflow logs
gh run view --log

# Extend timeout or optimize build
```

---

## Rollback Procedures

### Immediate Rollback

```bash
# Get previous commit
PREVIOUS_COMMIT=$(git log --format="%H" -n 2 | tail -1)

# Revert last commit
git revert HEAD
git push origin main

# Or hard reset (destructive)
git reset --hard "$PREVIOUS_COMMIT"
git push --force origin main
```

### Rollback via PR

```bash
# Create revert PR
gh pr create \
  --base main \
  --head revert-branch \
  --title "Revert: {feature-title}" \
  --body "Rolling back due to {issue}"
```

### Rollback to Specific Deployment

```bash
# Get deployment ID from report
DEPLOYMENT_ID="marketing-xyz789.vercel.app"

# Promote previous deployment
vercel promote "$PREVIOUS_DEPLOYMENT_ID"
```

---

## Best Practices

### Pre-Deployment

1. **Always run `/optimize`** before shipping
2. **Check deployment budget** to avoid quota exhaustion
3. **Use preview mode** for testing without quota cost
4. **Run local smoke tests** before creating PR

### During Deployment

1. **Monitor CI progress** for failures
2. **Wait for auto-merge** (don't manually merge)
3. **Capture deployment IDs** for rollback capability
4. **Run health checks** after deployment completes

### Post-Deployment

1. **Run `/validate-staging`** for manual testing
2. **Monitor error logs** for issues
3. **Check performance metrics** for regressions
4. **Document any issues** in staging validation report

---

## Related Commands

- `/optimize` - Quality gates (run before shipping)
- `/preview` - Local testing (run before shipping)
- `/ship` - Parent orchestrator (calls ship-staging)
- `/validate-staging` - Manual staging validation (run after shipping)
- `/ship-prod` - Production deployment (run after validation)
- `/checks pr [number]` - CI failure investigation

---

## Notes

**Internal command**: Called automatically by `/ship`, most users should use `/ship` instead

**Deployment modes**:

- **Staging**: Updates staging environment, consumes quota
- **Preview**: CI testing only, free and unlimited

**Auto-merge**: Enabled by default, merges when CI passes

**Health checks**: Run automatically after deployment

**Rollback capability**: Deployment metadata captured for easy rollback

**Report generation**: staging-ship-report.md created with full deployment details

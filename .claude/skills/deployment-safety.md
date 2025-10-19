---
name: deployment-safety
description: Enforce deployment safety checks before shipping to prevent broken deployments and production failures. Auto-trigger when detecting deployment commands (/phase-1-ship, /phase-2-ship, deploy, merge to production). Verify preflight checks run, CI passing, environment variables present, and no force-push to main. Block unsafe deployments.
allowed-tools: Bash, Read
---

# Deployment Safety: Prevent Broken Deployments

**Purpose**: Enforce mandatory safety checks before deployments to prevent broken builds, failed CI, and production outages.

**Philosophy**: "Deploy with confidence. Never ship broken code to production."

---

## The Problem

**Deployments fail due to skipped checks:**

**Scenario 1: Preflight Skipped**
```bash
# User runs /phase-1-ship without /preflight
# Result:
- ❌ Railway API build fails (Docker error)
- ❌ Vercel marketing build fails (TypeScript error)
- ❌ Vercel app build fails (import error)
- ❌ CI quota consumed for broken deployment
- ❌ Staging environment broken for 30+ minutes
```

**Scenario 2: Environment Variables Missing**
```bash
# User deploys without DATABASE_URL
# Result:
- ❌ API container crashes on startup
- ❌ Health check fails
- ❌ Staging unusable
- ❌ Manual rollback required
```

**Scenario 3: CI Checks Not Registered**
```bash
# User auto-merges before CI checks register
# Result:
- ❌ PR merged while checks still pending
- ❌ Checks fail after merge (too late)
- ❌ Main branch broken
- ❌ Revert commit required
```

**Scenario 4: Force Push to Main**
```bash
# User runs git push --force origin main
# Result:
- ❌ Commit history rewritten
- ❌ Other developers' commits lost
- ❌ CI pipeline broken
- ❌ Team coordination required to recover
```

---

## The Solution: Deployment Safety Gates

**Before any deployment, verify:**

1. **Preflight checks passed** (local build validation)
2. **Environment variables present** (all required vars)
3. **CI checks registered** (prevent race conditions)
4. **Build artifacts valid** (CI success = working build)
5. **No force-push to main** (protect commit history)
6. **No uncommitted changes** (clean working tree)

---

## When to Trigger

Auto-invoke this Skill when detecting:

**Deployment Commands:**
- `/phase-1-ship`
- `/phase-2-ship`
- `deploy to staging`
- `deploy to production`
- `ship to production`

**Git Operations:**
- `git push --force origin main`
- `git push --force origin master`
- `git push -f`
- `merge to main`
- `merge to master`

**Dangerous Flags:**
- `--skip-ci`
- `--no-verify`
- `--force`
- `--skip-preflight`

---

## Deployment Safety Checklist

### Gate 1: Preflight Verification

**Required before /phase-1-ship:**

```bash
# Check if /preflight has been run recently
PREFLIGHT_LOG=".spec-flow/memory/preflight-last-run.log"

if [ ! -f "$PREFLIGHT_LOG" ]; then
  echo "❌ **DEPLOYMENT BLOCKED: Preflight not run**"
  echo ""
  echo "Mandatory pre-flight checks missing."
  echo ""
  echo "**Run first:**"
  echo "  /preflight"
  echo ""
  echo "This validates:"
  echo "  • Environment variables"
  echo "  • Production builds (marketing, app, API)"
  echo "  • Docker image builds"
  echo "  • Database migrations"
  echo "  • Type safety"
  echo ""
  echo "Cannot proceed without preflight verification."
  exit 1
fi

# Check preflight timestamp (must be <1 hour old)
PREFLIGHT_AGE=$(($(date +%s) - $(stat -c %Y "$PREFLIGHT_LOG" 2>/dev/null || stat -f %m "$PREFLIGHT_LOG")))

if [ "$PREFLIGHT_AGE" -gt 3600 ]; then
  echo "⚠️  **STALE PREFLIGHT RESULTS**"
  echo ""
  echo "Preflight last run: $((PREFLIGHT_AGE / 60)) minutes ago"
  echo ""
  echo "Code may have changed since preflight."
  echo ""
  echo "**Recommendation:**"
  echo "  Re-run /preflight to verify current state"
  echo ""
  read -p "Proceed anyway? (yes/no): " response
  [ "$response" != "yes" ] && exit 1
fi

# Check preflight status
if ! grep -q "READY TO DEPLOY" "$PREFLIGHT_LOG"; then
  echo "❌ **DEPLOYMENT BLOCKED: Preflight failed**"
  echo ""
  echo "Pre-flight checks did not pass."
  echo ""
  echo "Last preflight result:"
  tail -20 "$PREFLIGHT_LOG" | sed 's/^/  /'
  echo ""
  echo "Fix preflight failures before deploying."
  exit 1
fi

echo "✅ Preflight verified (passed, <1 hour ago)"
```

### Gate 2: Environment Variables

**Check all required vars present:**

```bash
echo "Checking environment variables..."

# Backend required vars
BACKEND_VARS=(
  "DATABASE_URL"
  "DIRECT_URL"
  "OPENAI_API_KEY"
  "SECRET_KEY"
  "ENVIRONMENT"
)

# Frontend required vars
FRONTEND_VARS=(
  "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY"
  "CLERK_SECRET_KEY"
  "NEXT_PUBLIC_API_URL"
)

MISSING_VARS=()

# Check backend
for var in "${BACKEND_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    MISSING_VARS+=("$var (backend)")
  fi
done

# Check frontend (from .env.local)
if [ -f "apps/app/.env.local" ]; then
  for var in "${FRONTEND_VARS[@]}"; do
    if ! grep -q "^$var=" "apps/app/.env.local"; then
      MISSING_VARS+=("$var (frontend)")
    fi
  done
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo "❌ **DEPLOYMENT BLOCKED: Missing environment variables**"
  echo ""
  echo "Required variables not found:"
  for var in "${MISSING_VARS[@]}"; do
    echo "  ❌ $var"
  done
  echo ""
  echo "**Actions:**"
  echo "1. Add missing variables to .env files"
  echo "2. Verify variables in deployment platform (Vercel/Railway)"
  echo "3. Run /check-env to validate"
  echo ""
  echo "Cannot deploy without required environment variables."
  exit 1
fi

echo "✅ Environment variables present"
```

### Gate 3: Clean Working Tree

**No uncommitted changes:**

```bash
# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  **UNCOMMITTED CHANGES DETECTED**"
  echo ""
  echo "Working directory has uncommitted changes:"
  git status --short | sed 's/^/  /'
  echo ""
  echo "**Recommendation:**"
  echo "1. Commit changes: git add . && git commit -m \"...\""
  echo "2. Or stash: git stash"
  echo ""
  read -p "Proceed with uncommitted changes? (yes/no): " response
  [ "$response" != "yes" ] && exit 1
fi

echo "✅ Working tree clean"
```

### Gate 4: Branch Protection

**Block force-push to main/master:**

```bash
# Check if pushing to protected branch with --force
CURRENT_BRANCH=$(git branch --show-current)
PROTECTED_BRANCHES=("main" "master" "production")

if [[ " ${PROTECTED_BRANCHES[@]} " =~ " ${CURRENT_BRANCH} " ]]; then
  # Check if force-push attempted
  if [[ "$GIT_COMMAND" =~ --force|-f ]]; then
    echo "❌ **DEPLOYMENT BLOCKED: Force-push to protected branch**"
    echo ""
    echo "Cannot force-push to: $CURRENT_BRANCH"
    echo ""
    echo "**Why this is dangerous:**"
    echo "  • Rewrites commit history"
    echo "  • Deletes other developers' commits"
    echo "  • Breaks CI/CD pipeline"
    echo "  • Requires team coordination to recover"
    echo ""
    echo "**Instead:**"
    echo "  • Create a new PR with your changes"
    echo "  • Revert specific commits if needed: git revert <commit>"
    echo "  • Coordinate with team if history rewrite is necessary"
    echo ""
    echo "Force-push to $CURRENT_BRANCH is blocked."
    exit 1
  fi
fi

echo "✅ No force-push to protected branch"
```

### Gate 5: CI Check Registration (for /phase-1-ship)

**Wait for CI checks to register before auto-merge:**

```bash
# After creating PR, wait for CI checks to register
PR_NUMBER=$(gh pr view --json number -q '.number')

echo "Waiting for CI checks to register..."

REQUIRED_CHECKS=(
  "Lint"
  "Type Check"
  "Test"
  "Build"
  "Verify Build Artifacts"
  "Deploy to Staging"
)

REGISTRATION_TIMEOUT=300  # 5 minutes
REGISTRATION_ELAPSED=0
POLL_INTERVAL=10

while [ $REGISTRATION_ELAPSED -lt $REGISTRATION_TIMEOUT ]; do
  CURRENT_CHECKS=$(gh pr checks "$PR_NUMBER" --json name -q '.[].name')

  REGISTERED_COUNT=0
  for check in "${REQUIRED_CHECKS[@]}"; do
    if echo "$CURRENT_CHECKS" | grep -q "$check"; then
      ((REGISTERED_COUNT++))
    fi
  done

  echo "  Registered: $REGISTERED_COUNT/${#REQUIRED_CHECKS[@]} checks"

  if [ "$REGISTERED_COUNT" -eq "${#REQUIRED_CHECKS[@]}" ]; then
    echo "✅ All CI checks registered"
    break
  fi

  sleep $POLL_INTERVAL
  REGISTRATION_ELAPSED=$((REGISTRATION_ELAPSED + POLL_INTERVAL))
done

if [ "$REGISTRATION_ELAPSED" -ge "$REGISTRATION_TIMEOUT" ]; then
  echo "⚠️  **CI CHECK REGISTRATION TIMEOUT**"
  echo ""
  echo "Not all CI checks registered after 5 minutes."
  echo ""
  echo "Registered checks:"
  echo "$CURRENT_CHECKS" | sed 's/^/  • /'
  echo ""
  echo "**Missing checks:**"
  for check in "${REQUIRED_CHECKS[@]}"; do
    if ! echo "$CURRENT_CHECKS" | grep -q "$check"; then
      echo "  ❌ $check"
    fi
  done
  echo ""
  read -p "Proceed without all checks? (yes/no): " response
  [ "$response" != "yes" ] && exit 1
fi
```

### Gate 6: Build Artifact Verification

**Verify CI build artifacts are valid:**

```bash
# Check "Verify Build Artifacts" CI check
echo "Checking 'Verify Build Artifacts' status..."

VERIFY_CHECK=$(gh pr checks "$PR_NUMBER" --json name,conclusion -q '.[] | select(.name | test("Verify.*Build.*Artifacts"; "i"))')

if [ -z "$VERIFY_CHECK" ]; then
  echo "⚠️  **BUILD ARTIFACT CHECK NOT FOUND**"
  echo ""
  echo "CI check 'Verify Build Artifacts' not present."
  echo ""
  echo "This check verifies:"
  echo "  • Marketing .next directory exists"
  echo "  • App .next directory exists"
  echo "  • All required assets present"
  echo ""
  read -p "Proceed without artifact verification? (yes/no): " response
  [ "$response" != "yes" ] && exit 1
else
  VERIFY_CONCLUSION=$(echo "$VERIFY_CHECK" | jq -r '.conclusion')

  if [ "$VERIFY_CONCLUSION" != "SUCCESS" ]; then
    echo "❌ **DEPLOYMENT BLOCKED: Build artifacts invalid**"
    echo ""
    echo "Verify Build Artifacts: $VERIFY_CONCLUSION"
    echo ""
    echo "Build artifacts are missing or corrupted."
    echo "Deployment would fail in staging."
    echo ""
    echo "Check CI logs for build errors."
    exit 1
  fi

  echo "✅ Build artifacts verified"
fi
```

---

## Deployment Command Validation

### For /phase-1-ship (Staging)

**Pre-deployment checklist:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚦 DEPLOYMENT SAFETY CHECK (Staging)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Gate 1: Preflight
run_gate "Preflight verification" check_preflight

# Gate 2: Environment vars
run_gate "Environment variables" check_env_vars

# Gate 3: Working tree
run_gate "Clean working tree" check_working_tree

# Gate 4: Branch protection
run_gate "Branch protection" check_branch_protection

# Gate 5: CI registration
run_gate "CI check registration" wait_for_ci_checks

# Gate 6: Build artifacts
run_gate "Build artifact verification" verify_build_artifacts

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL SAFETY CHECKS PASSED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Safe to deploy to staging."
echo ""
```

### For /phase-2-ship (Production)

**Additional production checks:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚦 DEPLOYMENT SAFETY CHECK (Production)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# All staging checks
run_gate "Preflight verification" check_preflight
run_gate "Environment variables" check_env_vars
run_gate "Clean working tree" check_working_tree
run_gate "Branch protection" check_branch_protection

# Additional production checks
run_gate "Staging validation" check_staging_validated
run_gate "Manual approval" check_manual_approval
run_gate "Production artifacts" verify_production_artifacts

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL SAFETY CHECKS PASSED (Production)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Safe to deploy to production."
echo ""
```

**Staging validation check:**

```bash
check_staging_validated() {
  # Verify staging deployment succeeded
  STAGING_PR=$(gh pr list --label "staging" --state merged --limit 1 --json number -q '.[0].number')

  if [ -z "$STAGING_PR" ]; then
    echo "❌ No recent staging deployment found"
    echo ""
    echo "Production requires successful staging deployment first."
    echo ""
    echo "Run /phase-1-ship to deploy to staging."
    exit 1
  fi

  # Check staging deployment checks
  STAGING_CHECKS=$(gh pr checks "$STAGING_PR" --json name,conclusion)
  STAGING_FAILED=$(echo "$STAGING_CHECKS" | jq '[.[] | select(.conclusion != "SUCCESS")] | length')

  if [ "$STAGING_FAILED" -gt 0 ]; then
    echo "❌ Staging deployment has failures"
    echo ""
    echo "Failed checks:"
    echo "$STAGING_CHECKS" | jq -r '.[] | select(.conclusion != "SUCCESS") | "  ❌ \(.name): \(.conclusion)"'
    echo ""
    echo "Fix staging issues before promoting to production."
    exit 1
  fi

  echo "✅ Staging validated (PR #$STAGING_PR, all checks passed)"
}
```

**Manual approval check:**

```bash
check_manual_approval() {
  # Check for manual approval file (created by /validate-staging)
  APPROVAL_FILE=".spec-flow/memory/staging-approval.log"

  if [ ! -f "$APPROVAL_FILE" ]; then
    echo "❌ **PRODUCTION DEPLOYMENT BLOCKED: No manual approval**"
    echo ""
    echo "Production requires manual staging validation."
    echo ""
    echo "**Process:**"
    echo "1. Test staging environment thoroughly"
    echo "2. Run /validate-staging to approve"
    echo "3. Then run /phase-2-ship"
    echo ""
    echo "Cannot deploy to production without approval."
    exit 1
  fi

  # Check approval timestamp (must be <24 hours old)
  APPROVAL_AGE=$(($(date +%s) - $(stat -c %Y "$APPROVAL_FILE" 2>/dev/null || stat -f %m "$APPROVAL_FILE")))

  if [ "$APPROVAL_AGE" -gt 86400 ]; then
    echo "⚠️  **STALE APPROVAL**"
    echo ""
    echo "Staging approved: $((APPROVAL_AGE / 3600)) hours ago"
    echo ""
    echo "Re-validate staging if code changed since approval."
    echo ""
    read -p "Proceed with stale approval? (yes/no): " response
    [ "$response" != "yes" ] && exit 1
  fi

  echo "✅ Manual approval verified (<24 hours old)"
}
```

---

## Dangerous Operation Blocks

### Block 1: Force-Push to Main

**Detection:**
```bash
if [[ "$GIT_COMMAND" =~ git\ push.*(--force|-f) ]] && [[ "$BRANCH" =~ ^(main|master|production)$ ]]; then
  echo "❌ BLOCKED"
fi
```

**Response:**
```markdown
❌ **DANGEROUS OPERATION BLOCKED**

**Command:** git push --force origin main

**Why this is blocked:**
Force-pushing to main/master/production:
  • Rewrites commit history
  • Deletes other developers' commits
  • Breaks CI/CD pipeline
  • Requires team-wide coordination to recover

**Alternatives:**
1. Create feature branch and PR:
   git checkout -b fix/issue-123
   git push origin fix/issue-123

2. Revert specific commits (safe):
   git revert <commit-hash>
   git push origin main

3. Coordinate with team if history rewrite necessary:
   - Notify all developers
   - Ensure everyone has pushed their work
   - Use with extreme caution

**Force-push to main is blocked for safety.**
```

### Block 2: Skip Preflight

**Detection:**
```bash
if [[ "$COMMAND" =~ /phase-1-ship ]] && ! preflight_completed; then
  echo "❌ BLOCKED"
fi
```

**Response:**
```markdown
❌ **DEPLOYMENT BLOCKED: Preflight required**

**Command:** /phase-1-ship

**Missing:** /preflight checks

**Why preflight is mandatory:**
Preflight validates locally before consuming CI/CD quota:
  • Environment variables (all required vars)
  • Production builds (marketing + app)
  • Docker images (API container)
  • Database migrations (on test DB)
  • Type safety (TypeScript errors)

**Catching failures locally saves:**
  • CI/CD quota (failed builds cost money)
  • Time (local builds faster than CI)
  • Broken staging (users can't test broken environment)

**Run first:**
/preflight

**Then proceed with:**
/phase-1-ship

Preflight is mandatory and cannot be skipped.
```

### Block 3: Uncommitted Changes

**Detection:**
```bash
if [ -n "$(git status --porcelain)" ] && [[ "$COMMAND" =~ deploy|ship ]]; then
  echo "⚠️  WARNING"
fi
```

**Response:**
```markdown
⚠️  **WARNING: Uncommitted Changes**

**Deployment command:** {COMMAND}

**Uncommitted files:**
{GIT_STATUS_OUTPUT}

**Risks:**
  • Changes won't be deployed (not committed)
  • Working directory state != deployed state
  • Confusion about what's in staging/production

**Recommendation:**
1. Commit changes:
   git add .
   git commit -m "..."

2. Or stash if not ready:
   git stash

Proceed with uncommitted changes? (yes/no)
```

---

## Integration with Spec-Flow Workflow

### Pre-/phase-1-ship

**Automatic safety checks:**

1. ✅ Verify `/preflight` completed (mandatory, <1 hour old)
2. ✅ Check environment variables (all required vars)
3. ✅ Verify working tree clean (no uncommitted changes)
4. ✅ Wait for CI checks to register (prevent race conditions)
5. ✅ Verify build artifacts (CI success = valid artifacts)
6. ✅ Block force-push to main (protect history)

**Result:** Zero broken staging deployments, CI quota preserved

### Pre-/phase-2-ship

**Additional production checks:**

7. ✅ Verify staging validated (successful deployment + checks)
8. ✅ Check manual approval (from /validate-staging, <24 hours)
9. ✅ Verify production artifacts (all deployment jobs succeeded)

**Result:** Zero broken production deployments, manual gate enforced

---

## Examples

### Example 1: Preflight Not Run

**User Command:**
```
/phase-1-ship
```

**Deployment Safety Response:**
```markdown
❌ **DEPLOYMENT BLOCKED: Preflight not run**

Mandatory pre-flight checks missing.

**Run first:**
/preflight

This validates:
  • Environment variables ✓
  • Production builds (marketing, app, API) ✓
  • Docker image builds ✓
  • Database migrations ✓
  • Type safety ✓

**Then proceed with:**
/phase-1-ship

Cannot deploy without preflight verification.
```

### Example 2: Missing Environment Variable

**User Command:**
```
/phase-1-ship
```

**Deployment Safety Response:**
```markdown
❌ **DEPLOYMENT BLOCKED: Missing environment variables**

Required variables not found:
  ❌ DATABASE_URL (backend)
  ❌ OPENAI_API_KEY (backend)

**Actions:**
1. Add missing variables to .env files
2. Verify variables in deployment platform (Railway)
3. Run /check-env to validate

Cannot deploy without required environment variables.

Deployment blocked.
```

### Example 3: Force-Push Attempted

**User Command:**
```bash
git push --force origin main
```

**Deployment Safety Response:**
```markdown
❌ **DANGEROUS OPERATION BLOCKED**

Command: git push --force origin main

**Why this is blocked:**
Force-pushing to main:
  • Rewrites commit history
  • Deletes other developers' commits
  • Breaks CI/CD pipeline

**Alternatives:**
1. Create PR: git checkout -b fix/issue && git push origin fix/issue
2. Revert: git revert <commit> && git push origin main

Force-push to main is blocked for safety.
```

### Example 4: All Checks Pass

**User Command:**
```
/phase-1-ship
```

**Deployment Safety Response:**
```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚦 DEPLOYMENT SAFETY CHECK (Staging)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking deployment safety gates...

✅ Preflight verification (passed, 15 minutes ago)
✅ Environment variables (all required vars present)
✅ Clean working tree (no uncommitted changes)
✅ Branch protection (no force-push)
✅ CI check registration (6/6 checks registered)
✅ Build artifact verification (artifacts valid)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL SAFETY CHECKS PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Safe to deploy to staging.

Proceeding with /phase-1-ship...
```

---

## Deployment Safety Rules

1. **Preflight is mandatory** - Block /phase-1-ship if preflight not run or failed
2. **Environment vars required** - Block deployment if required vars missing
3. **CI checks must register** - Wait for all checks to appear before auto-merge
4. **Build artifacts must be valid** - Verify "Verify Build Artifacts" check passed
5. **No force-push to main** - Block destructive git operations on protected branches
6. **Staging before production** - Block /phase-2-ship if staging not validated
7. **Manual approval for production** - Require /validate-staging approval (<24 hours)
8. **Warn on uncommitted changes** - Allow but warn if working tree dirty

---

## Constraints

- **Bash access**: Required to run git, gh CLI, and check commands
- **Read access**: Required to read preflight/approval logs
- **Fast checks**: Complete validation in <30 seconds
- **Clear feedback**: Show which gate failed and how to fix
- **User override**: Allow proceed after warning (except hard blocks)

---

## Return Format

**Safety Checks Passed:**
```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL SAFETY CHECKS PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{LIST_OF_PASSED_CHECKS}

Safe to deploy to {ENVIRONMENT}.

Proceeding with {COMMAND}...
```

**Safety Check Failed (Hard Block):**
```markdown
❌ **DEPLOYMENT BLOCKED: {REASON}**

{DESCRIPTION_OF_FAILURE}

**Actions:**
{REQUIRED_FIXES}

Cannot proceed until issue is resolved.

Deployment blocked.
```

**Safety Check Warning (Soft Block):**
```markdown
⚠️  **DEPLOYMENT WARNING: {ISSUE}**

{DESCRIPTION_OF_ISSUE}

**Risks:**
{LIST_OF_RISKS}

**Recommendation:**
{SUGGESTED_ACTIONS}

Proceed anyway? (yes/no)
```

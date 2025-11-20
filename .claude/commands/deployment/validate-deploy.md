---
name: validate-deploy
description: Validate deployment readiness by simulating production builds, Docker images, and migrations locally to catch failures before consuming CI/CD quota
argument-hint: [staging|production]
allowed-tools: [Bash(python .spec-flow/*), Bash(.spec-flow/scripts/bash/validate-deploy.sh), Bash(.spec-flow/scripts/bash/check-env.sh), Read, Grep]
---

# /validate-deploy — Deployment Readiness Validation

<context>
**Target Environment**: $ARGUMENTS

**Current Feature Directory**: !`find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1 2>$null || echo "none"`

**Workflow State**: @specs/*/workflow-state.yaml

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Git Branch**: !`git branch --show-current 2>$null || echo "none"`

**Deployment Workflows**:
- Staging: !`test -f .github/workflows/deploy-staging.yml && echo "exists" || echo "missing"`
- Production: !`test -f .github/workflows/deploy-production.yml && echo "exists" || echo "missing"`

**Environment Check Script**: !`test -f .spec-flow/scripts/bash/check-env.sh && echo "exists" || echo "missing"`

**Validation Script**: !`test -f .spec-flow/scripts/bash/validate-deploy.sh && echo "exists" || echo "missing"`

**Package Manager**: !`command -v pnpm >/dev/null 2>&1 && echo "pnpm" || (command -v npm >/dev/null 2>&1 && echo "npm" || echo "unknown")`

**Docker Status**: !`command -v docker >/dev/null 2>&1 && docker ps >/dev/null 2>&1 && echo "running" || echo "not available"`
</context>

<objective>
Validate deployment readiness for $ARGUMENTS environment by simulating production builds, Docker images, database migrations, and other critical deployment operations locally **before** consuming CI/CD quota.

**Purpose**: Catch 90% of deployment failures (environment vars, builds, Docker, migrations, types, bundles) through local simulation, preventing broken deployments from reaching CI/CD pipelines or production.

**Philosophy**: Test in production-like conditions locally. Fast validation with minimal output using red/green status indicators.

**Mandatory Gate**: As of v1.8.0, preflight checks are **mandatory** and automatically invoked by `/ship`. Cannot be bypassed. This prevents broken builds from consuming CI/CD quota and reaching production.

**When Used**:
- **Automatically**: Invoked by `/ship` before deployment (cannot be skipped)
- **Manually**: Before manual deployments or after major configuration changes
- **Debugging**: To validate fixes after deployment failures

**Validation Phases** (executed in order):
1. **Environment Variables**: Comprehensive validation via `/check-env` (Doppler sync, URL sanity, platform sync, 29 required secrets)
2. **Production Builds**: Marketing site + app builds with production optimization
3. **Docker Images**: API container startup and health checks
4. **Database Migrations**: Run migrations on temporary test database
5. **Type Checking**: TypeScript type safety (backend + frontend, strict mode)
6. **Bundle Sizes**: Verify Vercel limits compliance (4.5MB first load JS)
7. **Lighthouse Scores**: Performance/accessibility validation (optional if .lighthouserc.json exists)
8. **Final Report**: Summary with pass/fail for each phase

**Arguments**:
- `staging`: Validate for staging deployment (default if omitted)
- `production`: Validate for production deployment

**Timing**: 2-3 minutes for full validation suite

**Zero Quota Consumption**: All checks run locally, no CI/CD resources used
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent false validation results.

1. **Never claim validation passed without actual script exit code 0**
   - Check actual bash exit code from validation script
   - Exit code 0 = all phases passed
   - Exit code 1 = one or more phases failed
   - Don't claim success if script errored or was interrupted

2. **Quote actual validation output for each phase**
   - Report actual ✅ or ❌ status from script output
   - Don't invent phase results
   - If phase didn't run, say "Phase X not executed" (don't claim passed)

3. **Report actual error messages from failed phases**
   - Quote actual build errors, type errors, migration failures
   - Include file:line references from actual output
   - Don't generalize errors - be specific

4. **Verify cleanup actually happened**
   - Check script cleaned up temporary artifacts (Docker images, test databases, log files)
   - If cleanup failed, warn user about leftover artifacts
   - Don't claim "all cleaned up" without verification

5. **Check validation script exists before running**
   - Verify `.spec-flow/scripts/bash/validate-deploy.sh` exists
   - If script missing, report error and suggest running `npx spec-flow init` to create it
   - Don't proceed without validation script

**Why this matters**: False validation success allows broken deployments to proceed, consuming quota and potentially causing production incidents. Accurate validation prevents wasted resources and outages.

---

<process>

### Step 1: Verify Prerequisites

**Check validation script exists**:
```bash
test -f .spec-flow/scripts/bash/validate-deploy.sh
```

If script doesn't exist:
```
❌ Validation script not found

Expected: .spec-flow/scripts/bash/validate-deploy.sh

This script should be created during project initialization.
Run: npx spec-flow init

Or create manually following the validate-deploy reference documentation.
```
EXIT immediately

**Check environment check script exists**:
```bash
test -f .spec-flow/scripts/bash/check-env.sh
```

If script doesn't exist:
```
⚠️  Environment check script not found

Expected: .spec-flow/scripts/bash/check-env.sh

Validation will skip environment variable checks.
Consider running: npx spec-flow init
```

Proceed with warning (environment check optional)

### Step 2: Determine Target Environment

**Parse $ARGUMENTS to determine target**:

- If `$ARGUMENTS` is empty or "staging": Target = staging
- If `$ARGUMENTS` is "production": Target = production
- Otherwise: Display error and EXIT

**Set environment variable for validation script**:
```bash
export DEPLOY_TARGET="$TARGET_ENV"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚦 PRE-FLIGHT VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target: {TARGET_ENV}
Feature: {FEATURE_DIR}

Validating deployment readiness...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Execute Validation Script

**Run comprehensive validation script using Bash tool**:

```bash
.spec-flow/scripts/bash/validate-deploy.sh "$TARGET_ENV"
```

**Validation script executes these phases** (in order):

**Phase 1: Environment Variables**
- Delegates to `.spec-flow/scripts/bash/check-env.sh "$TARGET_ENV"`
- Validates all required secrets (21 frontend, 8 backend)
- Performs environment-specific sanity checks (ENVIRONMENT var, URL domains, platform sync)
- Produces JSON report at `specs/<feature>/reports/check-env.json`
- Never prints secret values (security hardened)

**Phase 2: Production Builds**
- Marketing site build: `cd apps/marketing && pnpm build`
- App build: `cd apps/app && pnpm build`
- Logs saved to `/tmp/validate-deploy-{marketing|app}-build.log`
- Validates builds with production optimizations enabled

**Phase 3: Docker Image (API)**
- Builds API Docker image: `docker build -f apps/api/Dockerfile -t api:preflight .`
- Starts container with health checks: `docker run --health-cmd /health`
- Waits for healthy status (30s timeout)
- Stops and removes container after validation

**Phase 4: Database Migrations**
- Creates temporary test database
- Runs all pending migrations: `pnpm db:migrate`
- Validates migration scripts without affecting production
- Cleans up test database after validation

**Phase 5: Type Checking**
- Backend: `cd apps/api && pnpm tsc --noEmit`
- Frontend: `cd apps/app && pnpm tsc --noEmit`
- Strict mode enabled, no implicit any allowed

**Phase 6: Bundle Sizes**
- Analyzes production bundle: `pnpm build && du -sh .next/static`
- Validates against Vercel limits (4.5MB first load JS)
- Warns if approaching 80% of limit

**Phase 7: Lighthouse (Optional)**
- Runs if `.lighthouserc.json` exists
- Starts local preview server
- Runs Lighthouse CLI: `lhci autorun`
- Validates performance, accessibility, best practices, SEO
- Stops preview server after validation

**Phase 8: Final Report**
- Summarizes all phase results
- Displays pass/fail for each phase
- Shows total validation time
- Exits with code 0 (all passed) or 1 (any failed)

**Script output format**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: Environment Variables
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Validating environment variables via check-env...

✅ Environment variables validated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: Production Builds
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Building marketing site...
✅ Marketing build passed (12.4s)

Building app...
✅ App build passed (18.2s)

... (additional phases) ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VALIDATION SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Environment Variables
✅ Production Builds
✅ Docker Image
✅ Database Migrations
✅ Type Checking
✅ Bundle Sizes
⏭️  Lighthouse (skipped - no config)

✅ READY TO DEPLOY

Validation completed in 2m 34s
```

### Step 4: Check Validation Result

**Check script exit code**:
- Exit 0: All phases passed, deployment ready
- Exit 1: One or more phases failed, deployment blocked

**If script exited with code 1**:

Display failure summary:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ PRE-FLIGHT FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Failed phases (from script output):
{List actual failed phases with ❌}

Errors:
{Quote actual error messages from script output}

Fix the errors above and re-run validation before deploying.

Logs:
- Build logs: /tmp/validate-deploy-*.log
- Environment report: specs/{feature}/reports/check-env.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Update workflow state to mark validation as failed and EXIT

**If script exited with code 0**:

Display success summary:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PRE-FLIGHT PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All validation phases passed:
{List actual passed phases with ✅ from script output}

Deployment predictions:
- Vercel: Build will succeed (validated locally)
- CI checks: Type checks will pass (validated locally)
- Database: Migrations will apply cleanly (validated on test DB)

Ready to deploy to {TARGET_ENV}.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Update workflow state to mark validation as passed

### Step 5: Verify Cleanup

**Check temporary artifacts cleaned up**:

```bash
# Check Docker images removed
docker images | grep "preflight" || echo "No preflight images found"

# Check log files cleaned (optional - logs useful for debugging)
ls /tmp/validate-deploy-*.log 2>/dev/null || echo "No validation logs found"
```

**If cleanup incomplete**:
```
⚠️  Cleanup incomplete

Leftover artifacts detected:
- Docker images: {list}
- Log files: {list}

Manual cleanup:
docker rmi api:preflight
rm /tmp/validate-deploy-*.log
```

Display warning but don't fail validation

</process>

<success_criteria>
**Validation successfully completed when:**

1. **Prerequisites verified**:
   - Validation script exists at `.spec-flow/scripts/bash/validate-deploy.sh`
   - Environment check script exists (or warning displayed)

2. **Target environment determined**:
   - $ARGUMENTS parsed correctly (staging or production)
   - DEPLOY_TARGET environment variable set

3. **Validation script executed**:
   - All 8 phases executed (or skipped with justification)
   - Each phase reported ✅ (passed) or ❌ (failed)
   - Script completed without crashing

4. **Exit code checked**:
   - Script exit code 0 = all phases passed
   - Script exit code 1 = one or more phases failed
   - Exit code accurately reflects validation result

5. **Results reported**:
   - Pass/fail status displayed for each phase
   - Actual error messages quoted for failed phases
   - Deployment readiness verdict clear (READY or BLOCKED)

6. **Cleanup verified** (best effort):
   - Temporary Docker images removed
   - Test databases cleaned up
   - Log files preserved for debugging (optional cleanup)

7. **Workflow state updated**:
   - Validation result recorded in workflow-state.yaml
   - Pass/fail status accurate
   - Timestamp recorded

8. **Zero quota consumed**:
   - All checks ran locally
   - No CI/CD pipelines triggered
   - No remote deployments initiated
</success_criteria>

<verification>
**Before marking validation complete, verify:**

1. **Check validation script exit code**:
   - Actual bash exit code from script execution
   - 0 = passed, 1 = failed
   - Don't claim passed without verifying exit code

2. **Verify phase results from actual output**:
   ```bash
   # Count passed phases
   grep "✅" /tmp/validate-deploy-output.log | wc -l

   # Count failed phases
   grep "❌" /tmp/validate-deploy-output.log | wc -l
   ```
   Should match script's final summary

3. **Check workflow state updated**:
   ```bash
   yq eval '.quality_gates.pre_flight.passed' "$FEATURE_DIR/workflow-state.yaml"
   # Should show: true (if passed) or false (if failed)

   yq eval '.quality_gates.pre_flight.validated_at' "$FEATURE_DIR/workflow-state.yaml"
   # Should show actual timestamp
   ```

4. **Verify cleanup (best effort)**:
   ```bash
   docker images | grep "api:preflight"
   # Should return empty (image removed)
   ```

5. **Check no fabricated results**:
   - All phase results from actual script output (not assumed)
   - Error messages quoted from actual logs (not invented)
   - Deployment predictions based on actual validation (not guessed)

**Never claim validation passed without:**
- Actual script exit code 0
- Actual ✅ status for all critical phases from script output
- Actual workflow state update confirming passed status
</verification>

<output>
**Files created/modified by this command:**

**Validation reports**:
- `specs/{feature}/reports/check-env.json` - Environment variable validation report (created by check-env.sh)

**Build logs** (preserved for debugging):
- `/tmp/validate-deploy-marketing-build.log` - Marketing site build output
- `/tmp/validate-deploy-app-build.log` - App build output
- `/tmp/validate-deploy-api-docker.log` - Docker build and health check output
- `/tmp/validate-deploy-migrations.log` - Database migration output
- `/tmp/validate-deploy-types.log` - TypeScript type check output

**Workflow state**:
- `specs/{feature}/workflow-state.yaml` - Updated with:
  - `quality_gates.pre_flight.passed` = true/false
  - `quality_gates.pre_flight.validated_at` = ISO 8601 timestamp
  - `quality_gates.pre_flight.target_environment` = staging/production
  - `quality_gates.pre_flight.phases` = Array of phase results

**Temporary artifacts** (cleaned up after validation):
- Docker image: `api:preflight` (removed after health check)
- Test database: Temporary schema (dropped after migration validation)

**Console output**:
- Validation phase headers and progress
- Pass/fail status for each phase (✅/❌)
- Error messages for failed phases (with file:line references)
- Final validation summary (READY or BLOCKED)
- Cleanup status and warnings
- Total validation time
</output>

---

## Notes

**Mandatory Gate**: Cannot be bypassed. `/ship` automatically invokes this validation before deployment.

**Fast Feedback**: ~2-3 minutes for full validation suite (much faster than waiting for CI/CD to fail).

**Cost Savings**: Prevents consuming CI/CD quota on deployments that would fail anyway.

**Local Simulation**: All checks run in production-like conditions without affecting remote environments.

**Phase Independence**: Phases run sequentially. If Phase 1 fails, subsequent phases are skipped (fail fast).

**Cleanup Strategy**:
- Docker images: Always removed (prevents disk space issues)
- Test databases: Always dropped (prevents data pollution)
- Build logs: Preserved in /tmp for debugging (manually clean if needed)

**Optional Phases**:
- Lighthouse: Only runs if `.lighthouserc.json` exists in project root
- Docker: Only runs if Docker daemon is running and Dockerfile exists

**Environment-Specific Validation**:
- Staging: Validates with staging environment variables
- Production: Validates with production environment variables
- Uses Doppler for environment variable management

**Common Failures**:
1. **Environment Variables**: Missing secrets, invalid URLs, Doppler sync issues
2. **Production Builds**: TypeScript errors, missing dependencies, build config issues
3. **Docker Image**: Container fails to start, health checks fail, missing environment vars
4. **Database Migrations**: Migration syntax errors, constraint violations, orphaned migrations
5. **Type Checking**: Implicit any, missing types, type mismatches in strict mode
6. **Bundle Sizes**: Exceeded Vercel 4.5MB limit, large dependencies not tree-shaken
7. **Lighthouse**: Performance score <90, accessibility failures, best practices violations

**Troubleshooting**:
- Check logs in `/tmp/validate-deploy-*.log` for detailed error output
- Review environment report at `specs/{feature}/reports/check-env.json`
- Verify Docker daemon running: `docker ps`
- Verify package manager installed: `pnpm --version` or `npm --version`
- Ensure all dependencies installed: `pnpm install`

**Manual Cleanup** (if needed):
```bash
# Remove Docker preflight images
docker rmi api:preflight

# Remove validation logs
rm /tmp/validate-deploy-*.log

# Drop test database (if cleanup failed)
psql -c "DROP DATABASE IF EXISTS test_migrations_$(date +%s);"
```

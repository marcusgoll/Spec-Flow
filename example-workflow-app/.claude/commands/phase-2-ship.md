# Phase 2 Ship: Staging  Production Deployment

**Command**: `/phase-2-ship`

**Purpose**: Automated stagingproduction deployment with auto-merge. Validates staging, creates production PR, enables auto-merge, waits for CI, deploys to production, creates release.

**When to use**: After `/validate-staging` passes with all checks green. This is the final step to ship features to production.

**Workflow position**: `spec-flow  clarify  plan  tasks  analyze  implement  optimize  debug  preview  phase-1-ship  validate-staging  **phase-2-ship**`

---

## MENTAL MODEL

You are a **production deployment orchestrator**. Your job:

1. **Validate staging readiness** (staging-validation-report.md exists and passed)
2. **Create production PR** (staging  main)
3. **Enable auto-merge** (via PowerShell script)
4. **Wait for production CI** (token-efficient polling)
5. **Monitor auto-merge** (squash merge to main)
6. **Create release** (version tag + GitHub release)
7. **Update roadmap** (move to "Shipped")
8. **Report success** (ship-report.md with production URLs)

**Philosophy**: Fully automated from staging  production. The only manual gate is `/validate-staging`. Once validated, this command handles everything: PR creation, CI waiting, merging, versioning, and roadmap updates.

**Token efficiency**: Use `wait-for-ci.ps1` PowerShell script to poll GitHub API instead of constantly checking in Claude. Script runs in background and notifies when CI completes.

---

## INPUTS

**Required context:**
- Current branch: `staging` (validates you're on staging)
- Clean git working tree (no uncommitted changes)
- `staging-validation-report.md` exists in specs/NNN/artifacts/ with all checks 

**Auto-detected:**
- Feature name from branch/commit history
- Feature number (NNN) from specs/ directory
- Main branch name (from git remote)
- Latest staging commit SHA

---

## EXECUTION PHASES

### Phase 2.1: Validate Prerequisites

**Check staging branch:**
```bash
git rev-parse --abbrev-ref HEAD
```
- Must be on `staging` branch
- If not: Error with instructions to checkout staging

**Check working tree:**
```bash
git status --porcelain
```
- Must be clean (no output)
- If dirty: Error with instructions to commit/stash

**Detect feature:**
- Read `specs/*/artifacts/staging-validation-report.md`
- Extract feature name and number from report
- If not found: Error with instructions to run `/validate-staging` first

**Check validation passed:**
- Read staging-validation-report.md
- Look for "Status:  Ready for Production" in Deployment Readiness section
- If validation failed (): Error with list of remaining blockers

**Example validation check:**
```markdown
## Deployment Readiness

**Status**:  Ready for Production

All staging checks passed:
-  E2E tests passing
-  Lighthouse performance > 90
-  Manual validation complete
-  No critical errors in logs
```

### Phase 2.2: Create Production PR

**PR details:**
- **From**: `staging` branch
- **To**: `main` (or repo default branch)
- **Title**: `Production: [Feature Name]`
- **Body**: Generated from template below

**PR body template:**
```markdown
## Production Deployment

**Feature**: [NNN-feature-name]
**Staging validation**:  Passed on [YYYY-MM-DD]

## Staging Validation Summary

[Paste key metrics from staging-validation-report.md]

## Production Deployment Checklist

- [ ] Full CI suite (lint, type, test, build)
- [ ] Deploy marketing to production ([production marketing URL])
- [ ] Deploy app to production ([production app URL])
- [ ] Deploy API to production ([production API URL])
- [ ] Run smoke tests on production URLs
- [ ] Verify no regressions

## Rollback Plan

If smoke tests fail:

**Vercel (marketing + app):**
```bash
vercel rollback ${PROD_MARKETING_URL:-<production marketing url>} --token=$VERCEL_TOKEN
vercel rollback ${PROD_APP_URL:-<production app url>} --token=$VERCEL_TOKEN
```

**Railway (API):**
```bash
railway deployments --service api --environment production
railway redeploy [PREVIOUS_DEPLOYMENT_ID] --service api --environment production
```

## Auto-Merge

This PR has auto-merge enabled. It will automatically merge when all checks pass.

---
 Generated with [Claude Code](https://claude.com/claude-code)
```

**Create PR using GitHub MCP:**
```bash
gh pr create --base main --head staging --title "Production: [Feature Name]" --body "[Generated body]"
```

**Capture PR number** from output (e.g., #123)

### Phase 2.3: Enable Auto-Merge

**Run PowerShell helper:**
```powershell
.\.spec-flow\scripts\powershell\enable-auto-merge.ps1 -PrNumber [NUMBER] -MergeMethod squash
```

**Script verifies:**
- PR exists and is open
- Branch protection configured on main
- Required checks are defined
- Auto-merge enabled successfully

**If auto-merge fails:**
- Report error with link to PR
- Suggest manual merge after CI passes
- Continue to Phase 2.4 (still wait for CI)

### Phase 2.4: Wait for Production CI

**Production CI workflow** (`.github/workflows/deploy-production.yml`):
1. **Full CI suite** (ci-reusable.yml)
   - Lint (ESLint + Ruff)
   - Type check (TypeScript + MyPy)
   - Unit tests + integration tests
   - Build (Next.js + FastAPI)
2. **Deploy marketing** to Vercel production
3. **Deploy app** to Vercel production
4. **Deploy API** to Railway production
5. **Smoke tests** on production URLs
6. **Notify** deployment status

**Token-efficient waiting:**
```powershell
.\.spec-flow\scripts\powershell\wait-for-ci.ps1 -PrNumber [NUMBER] -Json
```

**Script behavior:**
- Polls GitHub API every 30 seconds
- Checks status of all required checks
- Returns JSON when CI completes (success/failure)
- Outputs live status updates to console

**Example output:**
```json
{
  "status": "success",
  "checks": [
    {"name": "ci", "status": "success"},
    {"name": "deploy-marketing", "status": "success"},
    {"name": "deploy-app", "status": "success"},
    {"name": "deploy-api", "status": "success"},
    {"name": "smoke-tests", "status": "success"}
  ],
  "prNumber": 123,
  "merged": true,
  "mergedAt": "2025-10-03T14:30:22Z"
}
```

**If CI fails:**
- Parse JSON to identify failed checks
- Report failed check names
- Suggest: "Run `/checks pr [number]` to diagnose and fix failures"
- **Do not proceed** to Phase 2.5

**If CI succeeds and auto-merge enabled:**
- PR automatically merges via GitHub auto-merge
- Continue to Phase 2.5

**If CI succeeds but auto-merge failed:**
- Suggest manual merge: `gh pr merge [number] --squash`
- Wait for user to merge
- Continue to Phase 2.5

### Phase 2.5: Create Version Tag and Release

**Determine version number:**
- Read `CHANGELOG.md` to find latest version (e.g., v1.2.0)
- Increment patch version (v1.2.0  v1.2.1)
- If major feature, suggest minor bump (v1.2.0  v1.3.0)
- If breaking changes, suggest major bump (v1.2.0  v2.0.0)

**Create git tag:**
```bash
git checkout main
git pull origin main
git tag -a v[X.Y.Z] -m "Release v[X.Y.Z]: [Feature Name]"
git push origin v[X.Y.Z]
```

**Create GitHub release using MCP:**
```bash
gh release create v[X.Y.Z] --title "v[X.Y.Z]: [Feature Name]" --notes "[Generated notes]"
```

**Release notes template:**
```markdown
## What's New

[Feature description from spec.md]

## Changes

-  [Key feature 1]
-  [Key feature 2]
-  [Key feature 3]

## Deployment

- **Marketing**: [production marketing URL]
- **App**: [production app URL]
- **API**: [production API URL]

## Validation

All production checks passed:
-  Full CI suite
-  Deployments successful
-  Smoke tests passing

---
 Generated with [Claude Code](https://claude.com/claude-code)
```

### Phase 2.6: Update Roadmap

**Read roadmap:**
```bash
cat .spec-flow/memory/roadmap.md
```

**Find feature in "In Progress" section:**
- Match by slug or title
- Extract all metadata (area, role, requirements, etc.)

**Move to "Shipped" section:**
- Remove: Branch, Phase, Impact, Effort, Confidence, Score
- Add: Date (today), Release (version tag)
- Keep: Slug, Title, Area, Role, Requirements

**Example transformation:**

**Before (In Progress):**
```markdown
### student-dashboard
- **Title**: Student Progress Tracking Dashboard
- **Area**: app
- **Role**: student
- **Branch**: feat/012-student-dashboard
- **Spec**: specs/012-student-dashboard/spec.md
- **Phase**: Validated on Staging
- **Impact**: 4
- **Effort**: 3
- **Confidence**: 0.9
- **Score**: 1.20
- **Requirements**:
  - Show ACS mastery progress over time
  - Visualize study plan completion
  - Display upcoming tasks and deadlines
```

**After (Shipped):**
```markdown
### student-dashboard
- **Title**: Student Progress Tracking Dashboard
- **Area**: app
- **Role**: student
- **Date**: 2025-10-03
- **Release**: v1.3.0 - Student progress tracking dashboard
- **Requirements**:
  - Show ACS mastery progress over time
  - Visualize study plan completion
  - Display upcoming tasks and deadlines
```

**Write updated roadmap:**
```bash
# Edit .spec-flow/memory/roadmap.md with updated content
```

### Phase 2.7: Create Ship Report

**Generate ship-report.md** in `specs/NNN-feature/artifacts/`:

**Template:**
```markdown
# Production Ship Report

**Date**: [YYYY-MM-DD HH:MM]
**Feature**: [NNN-feature-name]
**Version**: v[X.Y.Z]

## Deployment Status

**PR**: #[NUMBER] (merged to main)
**Commit SHA**: [SHA]
**Released**: v[X.Y.Z] on [YYYY-MM-DD]

## Production URLs

- **Marketing**: [production marketing URL]
- **App**: [production app URL]
- **API**: [production API URL]

## CI/CD Results

**Full CI Suite**:  Passed
- Lint: 
- Type check: 
- Tests: 
- Build: 

**Deployments**:  All successful
- Marketing (Vercel):  [deployment URL]
- App (Vercel):  [deployment URL]
- API (Railway):  [deployment URL]

**Smoke Tests**:  Passed
- Marketing health: 
- App health: 
- API health: 

## Staging Validation Summary

[Paste key sections from staging-validation-report.md]

## Release Notes

[Paste generated release notes]

## Rollback Plan

If issues arise in production:

**Vercel (marketing + app):**
```bash
vercel rollback ${PROD_MARKETING_URL:-<production marketing url>} --token=$VERCEL_TOKEN
vercel rollback ${PROD_APP_URL:-<production app url>} --token=$VERCEL_TOKEN
```

**Railway (API):**
```bash
railway deployments --service api --environment production
railway redeploy [PREVIOUS_DEPLOYMENT_ID] --service api --environment production
```

**Git revert:**
```bash
git checkout main
git revert [MERGE_COMMIT_SHA]
git push origin main
```

## Next Steps

- [ ] Monitor production metrics (PostHog, Sentry)
- [ ] Watch for error spikes in first 24 hours
- [ ] Validate user feedback
- [ ] Update documentation if needed

---
*Generated by `/phase-2-ship` command*
```

**Write report:**
```bash
cat > specs/[NNN-feature]/artifacts/ship-report.md
```

### Phase 2.8: Final Output

**Display summary to user:**
```markdown
##  Production Deployment Complete!

**Feature**: [NNN-feature-name]
**Version**: v[X.Y.Z]
**Release**: https://github.com/[org]/[repo]/releases/tag/v[X.Y.Z]

### Deployed to Production

-  Marketing: [production marketing URL]
-  App: [production app URL]
-  API: [production API URL]

### Validation

-  Full CI suite passed
-  All deployments successful
-  Smoke tests passing
-  Roadmap updated (moved to "Shipped")

### Reports

- Ship report: specs/[NNN-feature]/artifacts/ship-report.md
- GitHub release: https://github.com/[org]/[repo]/releases/tag/v[X.Y.Z]

### Next Steps

1. Monitor production metrics (PostHog, Sentry)
2. Watch for error spikes in first 24 hours
3. Celebrate! 

---
**Workflow complete**: `spec-flow  ...  optimize  preview  phase-1-ship  validate-staging  phase-2-ship `
```

---

## ERROR HANDLING

**If staging branch check fails:**
```markdown
 Error: Must run from staging branch

Current branch: [branch-name]

Please run:
```bash
git checkout staging
git pull origin staging
/phase-2-ship
```
```

**If working tree dirty:**
```markdown
 Error: Uncommitted changes detected

Please commit or stash changes:
```bash
git status
git add .
git commit -m "chore: prepare for production deployment"
# OR
git stash
```

Then run `/phase-2-ship` again.
```

**If staging-validation-report.md missing:**
```markdown
 Error: Staging validation report not found

Run `/validate-staging` first to validate the staging deployment.

Expected file: specs/[NNN-feature]/artifacts/staging-validation-report.md
```

**If staging validation failed:**
```markdown
 Error: Staging validation has blockers

The staging-validation-report.md shows:

**Blockers:**
-  [Blocker 1]
-  [Blocker 2]

Please fix these issues, then run `/validate-staging` again.

Once all checks pass ( Ready for Production), run `/phase-2-ship`.
```

**If production CI fails:**
```markdown
 Error: Production CI checks failed

**Failed checks:**
-  [check-name-1]: [error summary]
-  [check-name-2]: [error summary]

**Next steps:**

1. Review workflow logs: https://github.com/[org]/[repo]/actions/runs/[run-id]
2. Fix failures using `/checks pr [number]`
3. Push fixes to staging branch
4. Wait for CI to re-run
5. Run `/phase-2-ship` again

**Note**: Auto-merge is still enabled. PR will automatically merge once all checks pass.
```

**If auto-merge not enabled:**
```markdown
 Warning: Auto-merge could not be enabled

Reason: [error from enable-auto-merge.ps1]

**Manual merge required:**

Once all CI checks pass, merge manually:
```bash
gh pr merge [number] --squash
```

Continuing to wait for CI...
```

**If version tag creation fails:**
```markdown
 Error: Could not create version tag

Reason: [git error]

**Manual tag creation:**
```bash
git checkout main
git pull origin main
git tag -a v[X.Y.Z] -m "Release v[X.Y.Z]: [Feature Name]"
git push origin v[X.Y.Z]
```

Then create GitHub release manually:
https://github.com/[org]/[repo]/releases/new?tag=v[X.Y.Z]
```

---

## NOTES

**Token efficiency**: This command delegates CI waiting to `wait-for-ci.ps1` PowerShell script. The script polls GitHub API every 30 seconds in the background, avoiding constant Claude Code token usage.

**Auto-merge behavior**: GitHub auto-merge waits for all required checks to pass, then automatically merges using the Specified method (squash). This eliminates manual merge step.

**Version bumping**: Default is patch bump (x.y.Z). Suggest minor bump for new features, major bump for breaking changes. User can override during tag creation.

**Rollback safety**: Production has multiple rollback mechanisms:
1. Vercel instant rollback (previous deployment)
2. Railway redeploy (specific deployment ID)
3. Git revert (undo merge commit)

**Roadmap archival**: Moving feature to "Shipped" section archives its development history. ICE scores removed since feature is no longer being prioritized.

**Next command**: None - this is the end of the feature development workflow. Next feature starts with `/spec-flow`.




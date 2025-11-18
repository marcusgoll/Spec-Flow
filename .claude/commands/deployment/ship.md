---
description: Unified deployment orchestrator with multi-model support
version: 3.0
updated: 2025-11-18
---

# /ship — Unified Deployment Orchestrator

**Purpose**: Orchestrate complete post-implementation deployment workflow with zero manual gates

**Workflow**: [pre-flight + optimize] (parallel) → deploy-staging → [automated validation] → deploy-prod → finalize

**Timing**: 25-35 minutes fully automated (down from 65-165 min with 3 manual gates)

**Usage**:
- `/ship` - Start deployment workflow from beginning (fully automated)
- `/ship continue` - Resume from last completed phase (if failure occurred)
- `/ship status` - Display current deployment status

**Deployment Models**:
- **staging-prod**: Automated staging validation before production (recommended)
- **direct-prod**: Direct production deployment (skip staging)
- **local-only**: Local build and integration only

**Automation**:
- ✅ Pre-flight + optimize run in parallel (saves ~10 min)
- ✅ Zero manual gates (removed /preview, interactive version selection)
- ✅ Auto-generated validation reports (E2E, Lighthouse, rollback test)
- ✅ Platform API-based deployment ID extraction (no log parsing)
- ✅ Auto-fix CI failures via GitHub Action

**Dependencies**: Requires completed `/implement` phase

---

<context>
## TODO TRACKING REQUIREMENT

**CRITICAL**: You MUST use TodoWrite to track all ship workflow progress.

**Why**: The /ship workflow involves 5 phases over 25-35 minutes, fully automated. Without TodoWrite, user loses visibility and cannot resume after errors.

**When to use TodoWrite**:
1. Immediately after loading feature context - create full todo list
2. After every phase completes - mark completed, mark next as in_progress
3. When errors occur - add "Fix [specific error]" todo
4. On completion - mark all todos as completed

**Only ONE todo should be in_progress at a time.**
</context>

---

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Step 1: Initialize & Create Todo List

1. Read workflow-state.yaml from most recent feature directory
2. Detect deployment model (staging-prod, direct-prod, or local-only)
3. **IMMEDIATELY create TodoWrite list** based on model (see examples in original ship.md)

## Step 2: Run Pre-flight Validation & /optimize (Parallel)

**IMPORTANT**: Run these checks in parallel by making both tool calls in a single message. This saves ~10 minutes.

**Pre-flight validation** (Bash tool):
```bash
python .spec-flow/scripts/spec-cli.py ship-finalize preflight --feature-dir "$FEATURE_DIR"
```

**Optimize checks** (SlashCommand tool):
```bash
/optimize
```

**Pre-flight does**:
- Runs local build to catch errors early
- Checks GitHub secrets (if gh CLI available)
- Validates CI workflow syntax (if .github/workflows exists)

**Optimize does** (see `.claude/commands/phases/optimize.md`):
- Code review (KISS/DRY, security, performance)
- Accessibility audit (WCAG 2.1 AA)
- Performance profiling
- Type safety enforcement
- Dependency audit

**After both complete**:
- If either fails:
  - Update TodoWrite: Add "Fix [specific errors]" as new todo
  - Keep "Run pre-flight + optimize" as `in_progress`
  - Tell user to fix errors and run `/ship continue`
  - **EXIT**

- If both pass:
  - Update TodoWrite: Mark pre-flight + optimize as `completed`, mark deployment phase as `in_progress`
  - Continue to Step 3

## Step 3: Deploy (Model-Specific)

### If staging-prod model:

1. **Deploy to staging**:
   ```bash
   /ship-staging
   ```
   Update TodoWrite: Mark staging deploy as `completed`, mark validation as `in_progress`

2. **Automated staging validation**:

   Run validation report generation:
   ```bash
   python .spec-flow/scripts/spec-cli.py validate-staging --feature-dir "$FEATURE_DIR" --auto
   ```

   **What it validates** (fully automated):
   1. ✅ E2E test results (already passed in CI before staging deployment)
   2. ✅ Lighthouse CI results (performance/accessibility/best practices)
   3. ✅ Rollback capability test (verifies deployment IDs, tests alias swap)
   4. ✅ Health checks (staging deployment responding correctly)

   **Auto-generates validation report** with:
   - E2E test summary (passed/failed/skipped)
   - Lighthouse scores (performance, accessibility, best practices, SEO)
   - Rollback test results (previous deployment verified live)
   - Health check status (200 responses from all critical endpoints)

   Display validation summary:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ Automated Staging Validation Complete
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   E2E Tests: 45/45 passed ✅
   Lighthouse Performance: 98/100 ✅
   Lighthouse Accessibility: 100/100 ✅
   Lighthouse Best Practices: 95/100 ✅
   Rollback Test: Passed ✅
   Health Checks: All endpoints responding ✅

   Staging validation report: specs/NNN-slug/staging-validation-report.md

   Proceeding to production deployment...
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

   Update TodoWrite: Mark validation as `completed`, mark production deploy as `in_progress`

   If validation fails:
   - Update TodoWrite: Add "Fix staging validation failures" as new todo
   - Display failure details from report
   - Tell user to fix issues and run `/ship continue`
   - **EXIT**

3. **Deploy to production** (automatic after validation passes):
   ```bash
   /ship-prod
   ```
   Update TodoWrite: Mark production deploy as `completed`, mark finalize as `in_progress`

### If direct-prod model:

1. **Deploy directly to production**:
   ```bash
   /deploy-prod
   ```
   Update TodoWrite: Mark production deploy as `completed`, mark finalize as `in_progress`

### If local-only model:

1. **Build locally**:
   ```bash
   /build-local
   ```
   Update TodoWrite: Mark local build as `completed`, mark merge as `in_progress`

2. **Merge to main**:
   ```bash
   git checkout main
   git merge --no-ff [feature-branch]
   git push origin main
   ```
   Update TodoWrite: Mark merge as `completed`, mark finalize as `in_progress`

## Step 4: Essential Finalization (All Models)

Run essential finalization tasks using centralized CLI:

```bash
python .spec-flow/scripts/spec-cli.py ship-finalize finalize --feature-dir "$FEATURE_DIR"
```

**What it does**:

1. **Update roadmap issue to 'shipped'**:
   - Finds GitHub issue for feature
   - Updates labels (status:shipped, removes status:in-progress)
   - Adds shipped comment with deployment details
   - Closes the issue

2. **Clean up feature branch**:
   - Switches to main/master branch
   - Deletes local feature branch
   - Deletes remote feature branch (if exists)

3. **Check for infrastructure cleanup needs**:
   - Detects active feature flags
   - Recommends cleanup commands
   - Warns about tech debt

After essential finalization completes:
- Update TodoWrite: Mark essential finalization as `completed`, mark full finalization as `in_progress`
- Continue to Step 5

## Step 5: Full Finalization (Automatic)

Run the `/finalize` slash command to complete all documentation:

```bash
/finalize
```

**What it does** (see `.claude/commands/phases/finalize.md` for full details):

1. **Update CHANGELOG.md**:
   - Moves unreleased changes to versioned section
   - Extracts version number for tagging
   - Follows Keep a Changelog format

2. **Update README.md**:
   - Installation instructions
   - Usage examples
   - Feature list

3. **Update help documentation**:
   - User guides
   - API documentation
   - Integration docs

4. **GitHub Release Management**:
   - Creates/updates milestones
   - Closes current milestone
   - Creates next milestone
   - Generates GitHub release with notes

5. **Version tagging** (if tagged promotion enabled):
   - Extracts version from CHANGELOG.md
   - Creates annotated git tag: `v{version}`
   - Pushes tag to trigger production deployment

After full finalization completes:
- Update TodoWrite: Mark full finalization as `completed`
- Display final summary with deployment URLs, version, and next steps

## Error Handling

**When ANY phase fails**:
1. Update TodoWrite: Add "Fix [specific error from logs]" as new todo
2. Keep failed phase as `in_progress`
3. Display clear error message with log file path
4. Tell user to fix error and run `/ship continue`
5. **EXIT**

## Resume Capability (/ship continue)

When user runs `/ship continue`:
1. Read workflow-state.yaml to get current phase
2. Find first todo with status `pending` or `in_progress`
3. Mark that todo as `in_progress`
4. Resume from that phase (skip completed phases)

## Status Display (/ship status)

When user runs `/ship status`:
1. Read workflow-state.yaml
2. Display:
   - Deployment model
   - Current phase
   - Completed phases (from TodoWrite)
   - Pending phases (from TodoWrite)
   - Any errors or blockers
   - Manual gates waiting for approval

</instructions>

---

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent deployment failures from false assumptions.

1. **Never assume deployment configuration you haven't read**
   - ❌ BAD: "The app probably deploys to Vercel"
   - ✅ GOOD: "Let me check .github/workflows/ and package.json for deployment config"

2. **Cite actual workflow files when describing deployment**
   - When describing CI: "Per .github/workflows/deploy.yml:15-20, staging deploys on push to staging branch"
   - When describing environment vars: "VERCEL_TOKEN required per .env.example:5"

3. **Verify deployment URLs exist before reporting them**
   - Extract actual URLs from deployment tool output
   - If URL unknown, say: "Deployment succeeded but URL not captured in logs"

4. **Never fabricate deployment IDs or version tags**
   - Only report deployment IDs extracted from actual tool output
   - Don't invent git tags - verify with `git tag -l`

5. **Quote workflow-state.yaml exactly for phase status**
   - Don't paraphrase phase completion - quote the actual status
   - If state file missing/corrupted, flag it - don't assume status

## TODO UPDATE FREQUENCY

**After EVERY phase transition**:
- Mark previous phase as `completed`
- Mark next phase as `in_progress`
- Call TodoWrite (don't batch updates)

**When errors occur**:
- Add "Fix [specific error]" as new todo
- Keep current phase as `in_progress`
- Don't proceed to next phase

**At manual gates**:
- Mark current phase as `completed`
- Keep next phase as `pending` (not `in_progress` until user approves)
- Exit and wait for `/ship continue`

</constraints>

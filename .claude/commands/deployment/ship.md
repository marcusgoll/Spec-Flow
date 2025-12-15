---
name: ship
description: Deploy feature through automated staging validation to production with rollback testing
argument-hint: "[continue|status|budget|rollback|recover|--staging|--prod|--validate|--dry-run|--auto]"
allowed-tools: [Read, Bash, Task, AskUserQuestion, SlashCommand, TodoWrite]
version: 11.0
updated: 2025-12-09
---

# /ship — Unified Deployment Orchestrator (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `ship-phase-agent` via Task(). Deployment operations run in isolated context with question batching for production approval.

<context>
**Arguments**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`

**Deployment Model**: !`test -f .github/workflows/deploy-staging.yml && echo "staging-prod" || (git remote 2>/dev/null && echo "direct-prod" || echo "local-only")`
</context>

<objective>
Spawn isolated ship-phase-agent to orchestrate deployment workflow.

**Architecture (v11.0 - Phase Isolation):**
```
/ship → Task(ship-phase-agent) → Q&A for prod approval → deployment
```

**Agent responsibilities:**
- Auto-detect deployment model (staging-prod, direct-prod, local-only)
- Execute pre-flight validation
- Deploy to staging (auto-proceed)
- Request approval for production deployment (returns question)
- Create GitHub release
- Record deployment metadata

**Deployment Models** (auto-detected):

1. **staging-prod**: Automated staging validation before production (recommended)

   - Detection: Git remote + staging branch + `.github/workflows/deploy-staging.yml`
   - Workflow: pre-flight + optimize (parallel) → deploy-staging → automated validation → deploy-prod → finalize

2. **direct-prod**: Direct production deployment without staging

   - Detection: Git remote + no staging branch
   - Workflow: pre-flight + optimize (parallel) → deploy-prod → finalize

3. **local-only**: Local build and integration only
   - Detection: No git remote
   - Workflow: pre-flight + optimize (parallel) → build-local → merge to main → finalize

**Automation Features**:

- Pre-flight + optimize run in parallel (saves ~10 minutes)
- Zero manual gates (removed /preview, interactive version selection)
- Auto-generated validation reports (E2E, Lighthouse, rollback tests)
- Platform API-based deployment ID extraction (no log parsing)
- Auto-fix CI failures via GitHub Actions

**Arguments**:

- (empty): Start deployment workflow from beginning
- `continue`: Resume from last completed phase (if failure occurred)
- `status`: Display current deployment status and exit
- `rollback [version]`: Rollback to previous deployment version (v10.14+)
- `recover`: Recover corrupted state.yaml from git history (v10.14+)
- `budget`: Display deployment quota status
- `--auto`: Full autopilot mode - skip prompts, auto-merge when CI passes, continue to finalize (v11.7)

**Dependencies**: Requires completed `/implement` phase

**Timing**: 25-35 minutes fully automated
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent deployment failures from false assumptions.

1. **Never assume deployment configuration you haven't read**

   - ❌ BAD: "The app probably deploys to Vercel"
   - ✅ GOOD: Read .github/workflows/, package.json, vercel.json to detect deployment config

2. **Cite actual workflow files when describing deployment**

   - When describing CI: "Per .github/workflows/deploy.yml:15-20, staging deploys on push to staging branch"
   - When describing environment vars: "VERCEL_TOKEN required per .env.example:5"

3. **Verify deployment URLs exist before reporting them**

   - Extract actual URLs from deployment tool output
   - If URL unknown, say: "Deployment succeeded but URL not captured in logs"

4. **Never fabricate deployment IDs or version tags**

   - Only report deployment IDs extracted from actual tool output
   - Don't invent git tags - verify with `git tag -l`

5. **Quote state.yaml exactly for phase status**

   - Don't paraphrase phase completion - quote the actual status value
   - If state file missing/corrupted, flag it - don't assume status

6. **TodoWrite is MANDATORY for all ship workflows**
   - Create full todo list immediately after Step 1
   - Update after EVERY phase transition (don't batch updates)
   - Only ONE todo should be in_progress at a time
   - When errors occur: Add "Fix [specific error]" as new todo

**Why this matters**: False assumptions about deployment config cause production incidents. Accurate reading of actual configuration prevents failures.

---

<process>

## TODO TRACKING REQUIREMENT

**CRITICAL**: You MUST use TodoWrite to track all ship workflow progress.

**Why**: The /ship workflow involves 5-7 phases over 25-35 minutes, fully automated. Without TodoWrite, user loses visibility and cannot resume after errors.

**TodoWrite pattern**:

1. After Step 1 (loading context) - Create full todo list based on deployment model
2. After every phase completes - Mark completed, mark next as in_progress
3. When errors occur - Add "Fix [specific error]" todo, keep current phase in_progress
4. On completion - Mark all todos as completed

**Only ONE todo should be in_progress at a time.**

---

### Step 0: Route Consolidated Arguments

**Check $ARGUMENTS for routing to scripts or archived commands:**

**Rollback or Recover Operations** (v10.14+):

If `$ARGUMENTS` starts with `rollback`:

1. Extract version if provided (e.g., `rollback v1.2.3` → `v1.2.3`)
2. Run rollback script:
   ```bash
   python .spec-flow/scripts/spec-cli.py ship-rollback [version]
   ```
3. Display rollback results and EXIT

If `$ARGUMENTS` is `recover`:

1. Run state recovery script:
   ```bash
   python .spec-flow/scripts/spec-cli.py ship-recover --feature-dir "$FEATURE_DIR"
   ```
2. Display recovered state and EXIT

**Route budget command:**

If `$ARGUMENTS` is `budget`:

```
SlashCommand: /deployment/budget
```

Display deployment quota status and EXIT.

**If none of the above, continue to Step 0.1.**

---

### Step 0.1: DRY-RUN AND AUTO MODE DETECTION

**Check for --dry-run and --auto flags:**

```bash
DRY_RUN="false"
AUTO_MODE="false"

if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="true"
  ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/--dry-run//g' | xargs)
  echo "DRY-RUN MODE ENABLED"
fi

if [[ "$ARGUMENTS" == *"--auto"* ]]; then
  AUTO_MODE="true"
  ARGUMENTS=$(echo "$ARGUMENTS" | sed 's/--auto//g' | xargs)
  echo "AUTO MODE ENABLED"

  # Load auto-mode preferences
  AUTO_MERGE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_merge" --default "false" 2>/dev/null || echo "false")
  AUTO_FINALIZE=$(bash .spec-flow/scripts/utils/load-preferences.sh --key "deployment.auto_finalize" --default "true" 2>/dev/null || echo "true")
  echo "Auto-merge: $AUTO_MERGE, Auto-finalize: $AUTO_FINALIZE"
fi
```

**Auto mode behavior (v11.7)**:
When `--auto` flag is set, /ship will:
1. Skip all manual approval prompts (proceed automatically)
2. Auto-merge PR when CI passes (if `deployment.auto_merge: true`)
3. Continue to /finalize automatically after successful deployment (if `deployment.auto_finalize: true`)

**If DRY_RUN is true:**

1. Detect deployment model (staging-prod, direct-prod, local-only)
2. Read state.yaml for current phase status
3. Output dry-run summary and exit:

```
════════════════════════════════════════════════════════════════════════════════
DRY-RUN MODE: No changes will be made
════════════════════════════════════════════════════════════════════════════════

📋 DEPLOYMENT CONFIGURATION:
  Feature: $FEATURE_DIR
  Deployment model: [staging-prod | direct-prod | local-only]
  Current phase: [phase from state.yaml]

📋 PRE-FLIGHT CHECKS (would execute):
  ✓ Build verification
  ✓ Test suite (N tests)
  ✓ Type checking
  ✓ Security scan
  ✓ Environment variables validation

🔀 GIT OPERATIONS THAT WOULD OCCUR:
  • git push origin feature/$SLUG
  • gh pr create --base [staging|main] --head feature/$SLUG
  • Wait for CI to pass
  • gh pr merge --auto

📦 DEPLOYMENT THAT WOULD OCCUR:
  [If staging-prod model:]
  • Merge to staging branch triggers deploy-staging.yml
  • Staging health check verification
  • Production approval requested
  • Merge staging to main triggers deploy-prod.yml
  • Production health check verification

  [If direct-prod model:]
  • Merge to main triggers production deployment
  • Health check verification

  [If local-only model:]
  • Build artifacts created locally
  • No remote deployment

🤖 AGENTS THAT WOULD BE SPAWNED:
  1. ship-staging-phase-agent → Execute staging deployment
  2. ship-prod-phase-agent → Execute production deployment
  3. finalize-phase-agent → Archive and document

📊 STATE CHANGES:
  state.yaml:
    - phases.ship: pending → completed
    - deployment.staging.status: → deployed (if staging-prod)
    - deployment.prod.status: → deployed
    - deployment.prod.version: → [semver]

════════════════════════════════════════════════════════════════════════════════
DRY-RUN COMPLETE: 0 actual changes made
Run `/ship` to execute deployment workflow
════════════════════════════════════════════════════════════════════════════════
```

**Exit after dry-run summary. Do NOT proceed to deployment.**

---

### Step 1: Parse Arguments and Load Context

**Parse $ARGUMENTS**:

- If `$ARGUMENTS` is empty: Start fresh deployment workflow
- If `$ARGUMENTS` == "status": Display current deployment status and EXIT
- If `$ARGUMENTS` == "continue": Resume from last completed phase
- Otherwise: Display usage error and EXIT

**If "status" argument**:

1. Read state.yaml from current feature directory
2. Display:
   - Deployment model (staging-prod, direct-prod, or local-only)
   - Current phase and status
   - Completed phases (from TodoWrite or state.yaml)
   - Pending phases
   - Any errors or blockers
   - Manual gates waiting for approval (if any)
3. EXIT (do not proceed with deployment)

**Load feature context**:

1. Find most recent feature directory: `find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1`
2. Store as `FEATURE_DIR` variable for use throughout workflow
3. Read state.yaml from `$FEATURE_DIR/state.yaml`
4. Verify `/implement` phase is completed:
   - If not completed: Display error "Cannot ship - /implement phase not complete" and EXIT
5. Detect deployment model from dynamic context (staging-prod, direct-prod, or local-only)

**Create TodoWrite list** based on detected model:

**For staging-prod model**:

```
1. Run pre-flight validation + /optimize (parallel)
2. Deploy to staging
3. Run automated staging validation
4. Deploy to production
5. Run essential finalization
6. Run full finalization (/finalize)
```

**For direct-prod model**:

```
1. Run pre-flight validation + /optimize (parallel)
2. Deploy to production
3. Run essential finalization
4. Run full finalization (/finalize)
```

**For local-only model**:

```
1. Run pre-flight validation + /optimize (parallel)
2. Build locally
3. Merge to main branch
4. Run essential finalization
5. Run full finalization (/finalize)
```

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHIP WORKFLOW INITIALIZED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {FEATURE_DIR}
Model: {deployment-model}
Estimated time: 25-35 minutes

Starting deployment...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If "continue" argument**:

1. Read state.yaml to get current phase
2. Read existing TodoWrite list
3. Find first todo with status `pending` or `in_progress`
4. Mark that todo as `in_progress`
5. Skip to that phase's step in this process (jump to Step 2, 3, 4, or 5 as appropriate)

### Step 2: Run Pre-flight Validation & /optimize (Parallel)

**IMPORTANT**: Run these checks in parallel by making both tool calls in a single message. This saves ~10 minutes.

**Use Bash tool for pre-flight**:

```bash
python .spec-flow/scripts/spec-cli.py ship-finalize preflight --feature-dir "$FEATURE_DIR"
```

**Use SlashCommand tool for optimize**:

```
/optimize
```

**Pre-flight validation checks**:

- Runs local build to catch errors early
- Checks GitHub secrets (if gh CLI available)
- Validates CI workflow syntax (if .github/workflows exists)
- Verifies deployment configuration files exist

**Optimize checks** (see `.claude/commands/phases/optimize.md`):

- Code review (KISS/DRY violations, security issues, performance problems)
- Accessibility audit (WCAG 2.1 AA compliance)
- Performance profiling (N+1 queries, slow endpoints)
- Type safety enforcement (no implicit any, null safety)
- Dependency audit (vulnerabilities, bundle size)

**After both complete**:

**If either fails**:

1. Update TodoWrite: Add "Fix [specific errors from logs]" as new todo
2. Keep "Run pre-flight + optimize" as `in_progress`
3. Display clear error message with log file paths
4. Tell user to fix errors and run `/ship continue`
5. **EXIT**

**If both pass**:

1. Update TodoWrite: Mark "Run pre-flight + optimize" as `completed`
2. Continue to Step 3

### Step 3: Deploy (Model-Specific)

**Determine deployment model** from context loaded in Step 1.

#### If staging-prod model:

**Phase 3a: Deploy to Staging**

1. Update TodoWrite: Mark "Deploy to staging" as `in_progress`

2. Spawn staging deployment agent via Task tool:

   ```
   Task tool call:
     subagent_type: "ship-staging-phase-agent"
     description: "Deploy to staging"
     prompt: |
       Deploy this feature to staging environment.

       Feature directory: ${FEATURE_DIR}
       Feature slug: ${FEATURE_SLUG}

       Execute staging deployment:
       1. Create PR if needed
       2. Monitor CI checks
       3. Auto-merge on success
       4. Extract deployment URLs and metadata

       Return:
       ---COMPLETED---
       deployment_url: [staging URL]
       pr_number: [PR number]
       ci_status: passed
       ---END_COMPLETED---

       Or if failed:
       ---FAILED---
       error: [error description]
       logs: [relevant log excerpt]
       ---END_FAILED---
   ```

3. After deployment completes successfully:

   - Update TodoWrite: Mark "Deploy to staging" as `completed`
   - Continue to Phase 3b

4. If deployment fails:
   - Update TodoWrite: Add "Fix staging deployment failure" as new todo
   - Keep "Deploy to staging" as `in_progress`
   - Display error details from deployment logs
   - Tell user to fix and run `/ship continue`
   - **EXIT**

**Phase 3b: Automated Staging Validation**

1. Update TodoWrite: Mark "Run automated staging validation" as `in_progress`

2. Run validation report generation using Bash tool:

   ```bash
   python .spec-flow/scripts/spec-cli.py validate-staging --feature-dir "$FEATURE_DIR" --auto
   ```

3. **What it validates** (fully automated):

   - ✅ E2E test results (already passed in CI before staging deployment)
   - ✅ Lighthouse CI results (performance/accessibility/best practices)
   - ✅ **Performance baseline comparison** (v10.14+):
     - Compares current Lighthouse scores against baseline
     - Checks TTFB, LCP, CLS, FID against thresholds
     - Compares bundle size against previous deployment
     - Blocks deployment if regression >10% (configurable)
   - ✅ Rollback capability test (verifies deployment IDs, tests alias swap)
   - ✅ Health checks (staging deployment responding correctly)

4. **Auto-generates validation report** at `$FEATURE_DIR/staging-validation-report.md` with:

   - E2E test summary (passed/failed/skipped)
   - Lighthouse scores (performance, accessibility, best practices, SEO)
   - Rollback test results (previous deployment verified live)
   - Health check status (200 responses from all critical endpoints)

5. Display validation summary:

   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ Automated Staging Validation Complete
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   E2E Tests: {X}/{total} passed ✅
   Lighthouse Performance: {score}/100 ✅
   Lighthouse Accessibility: {score}/100 ✅
   Lighthouse Best Practices: {score}/100 ✅
   Rollback Test: Passed ✅
   Health Checks: All endpoints responding ✅

   Staging validation report: {FEATURE_DIR}/staging-validation-report.md

   Proceeding to production deployment...
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

6. If validation passes:

   - Update TodoWrite: Mark "Run automated staging validation" as `completed`
   - Continue to Phase 3c

7. If validation fails:
   - Update TodoWrite: Add "Fix staging validation failures" as new todo
   - Keep "Run automated staging validation" as `in_progress`
   - Display failure details from report (file:line references for test failures)
   - Tell user to fix issues and run `/ship continue`
   - **EXIT**

**Phase 3c: Deploy to Production**

1. Update TodoWrite: Mark "Deploy to production" as `in_progress`

2. Spawn production deployment agent via Task tool:

   ```
   Task tool call:
     subagent_type: "ship-prod-phase-agent"
     description: "Deploy to production"
     prompt: |
       Promote staging build to production environment.

       Feature directory: ${FEATURE_DIR}
       Feature slug: ${FEATURE_SLUG}
       Staging validation: passed

       Execute production deployment:
       1. Trigger production deployment workflow
       2. Create GitHub release with version tag
       3. Update roadmap issue to "Shipped" status
       4. Verify deployment health

       Return:
       ---COMPLETED---
       production_url: [production URL]
       release_version: [version tag]
       github_release: [release URL]
       ---END_COMPLETED---

       Or if failed:
       ---FAILED---
       error: [error description]
       rollback_available: true/false
       ---END_FAILED---
   ```

3. After deployment completes successfully:

   - Update TodoWrite: Mark "Deploy to production" as `completed`
   - Continue to Step 4

4. If deployment fails:
   - Update TodoWrite: Add "Fix production deployment failure" as new todo
   - Keep "Deploy to production" as `in_progress`
   - Display error details
   - Tell user to fix and run `/ship continue`
   - **EXIT**

#### If direct-prod model:

**Phase 3: Deploy Directly to Production**

1. Update TodoWrite: Mark "Deploy to production" as `in_progress`

2. Spawn production deployment agent via Task tool:

   ```
   Task tool call:
     subagent_type: "ship-prod-phase-agent"
     description: "Deploy directly to production"
     prompt: |
       Deploy this feature directly to production (no staging step).

       Feature directory: ${FEATURE_DIR}
       Feature slug: ${FEATURE_SLUG}
       Deployment model: direct-prod

       Execute production deployment:
       1. Trigger production deployment workflow
       2. Create GitHub release with version tag
       3. Update roadmap issue to "Shipped" status
       4. Verify deployment health

       Return:
       ---COMPLETED---
       production_url: [production URL]
       release_version: [version tag]
       github_release: [release URL]
       ---END_COMPLETED---

       Or if failed:
       ---FAILED---
       error: [error description]
       ---END_FAILED---
   ```

3. After deployment completes successfully:

   - Update TodoWrite: Mark "Deploy to production" as `completed`
   - Continue to Step 4

4. If deployment fails:
   - Update TodoWrite: Add "Fix production deployment failure" as new todo
   - Keep "Deploy to production" as `in_progress`
   - Display error details
   - Tell user to fix and run `/ship continue`
   - **EXIT**

#### If local-only model:

**Phase 3a: Build Locally**

1. Update TodoWrite: Mark "Build locally" as `in_progress`

2. Use SlashCommand tool:

   ```
   /build-local
   ```

3. After build completes successfully:

   - Update TodoWrite: Mark "Build locally" as `completed`
   - Continue to Phase 3b

4. If build fails:
   - Update TodoWrite: Add "Fix local build failure" as new todo
   - Keep "Build locally" as `in_progress`
   - Display error details
   - Tell user to fix and run `/ship continue`
   - **EXIT**

**Phase 3b: Merge to Main Branch**

1. Update TodoWrite: Mark "Merge to main branch" as `in_progress`

2. Get current feature branch name:

   ```bash
   git branch --show-current
   ```

3. Merge to main using Bash tool:

   ```bash
   git checkout main && git merge --no-ff [feature-branch] && git push origin main
   ```

4. After merge completes successfully:

   - Update TodoWrite: Mark "Merge to main branch" as `completed`
   - Continue to Step 4

5. If merge fails:
   - Update TodoWrite: Add "Fix merge conflicts" as new todo
   - Keep "Merge to main branch" as `in_progress`
   - Display conflict details
   - Tell user to resolve conflicts and run `/ship continue`
   - **EXIT**

### Step 3.5: Worktree Merge and Cleanup (If Enabled)

**Check if feature was developed in a worktree:**

```bash
WORKTREE_ENABLED=$(yq eval '.git.worktree_enabled // false' "$FEATURE_DIR/state.yaml")
WORKTREE_PATH=$(yq eval '.git.worktree_path // ""' "$FEATURE_DIR/state.yaml")
echo "Worktree enabled: $WORKTREE_ENABLED"
echo "Worktree path: $WORKTREE_PATH"
```

**If worktree was used:**

```bash
if [ "$WORKTREE_ENABLED" = "true" ] && [ -n "$WORKTREE_PATH" ]; then
    echo "Merging worktree branch to main..."

    # Load cleanup preference
    CLEANUP_ON_FINALIZE=$(bash .spec-flow/scripts/utils/load-preferences.sh \
        --key "worktrees.cleanup_on_finalize" --default "true" 2>/dev/null)

    # Get feature slug for merge
    FEATURE_SLUG=$(yq eval '.slug' "$FEATURE_DIR/state.yaml")

    # Merge worktree branch back to main
    bash .spec-flow/scripts/bash/worktree-context.sh merge "$FEATURE_SLUG"

    # Cleanup worktree if preference enabled
    if [ "$CLEANUP_ON_FINALIZE" = "true" ]; then
        echo "Cleaning up worktree: $FEATURE_SLUG"
        bash .spec-flow/scripts/bash/worktree-manager.sh remove "$FEATURE_SLUG" --force
        echo "Worktree removed: $WORKTREE_PATH"

        # Update state.yaml to reflect cleanup
        yq eval '.git.worktree_enabled = false' -i "$FEATURE_DIR/state.yaml"
        yq eval '.git.worktree_path = ""' -i "$FEATURE_DIR/state.yaml"
        yq eval '.git.worktree_merged_at = "'$(date -Iseconds)'"' -i "$FEATURE_DIR/state.yaml"
    else
        echo "Worktree preserved (cleanup_on_finalize=false): $WORKTREE_PATH"
    fi
fi
```

**Epic sprint worktrees:**

For epics with multiple sprint worktrees, merge each sprint branch:

```bash
if [ -d "epics/$EPIC_SLUG/sprints" ]; then
    for sprint_dir in epics/$EPIC_SLUG/sprints/*/; do
        SPRINT_ID=$(basename "$sprint_dir")
        SPRINT_WORKTREE_ENABLED=$(yq eval '.git.worktree_enabled // false' "${sprint_dir}state.yaml")

        if [ "$SPRINT_WORKTREE_ENABLED" = "true" ]; then
            SPRINT_SLUG="${EPIC_SLUG}-${SPRINT_ID}"
            bash .spec-flow/scripts/bash/worktree-context.sh merge "$SPRINT_SLUG"

            if [ "$CLEANUP_ON_FINALIZE" = "true" ]; then
                bash .spec-flow/scripts/bash/worktree-manager.sh remove "$SPRINT_SLUG" --force
            fi
        fi
    done
fi
```

### Step 4: Essential Finalization (All Models)

1. Update TodoWrite: Mark "Run essential finalization" as `in_progress`

2. Run essential finalization tasks using centralized CLI (Bash tool):

   ```bash
   python .spec-flow/scripts/spec-cli.py ship-finalize finalize --feature-dir "$FEATURE_DIR"
   ```

3. **What it does**:

   **Update roadmap issue to 'shipped'**:

   ```bash
   # Check if roadmap issue was linked during /feature
   ROADMAP_ISSUE=$(yq eval '.roadmap.issue_number' "$FEATURE_DIR/state.yaml" 2>/dev/null)

   if [ -n "$ROADMAP_ISSUE" ] && [ "$ROADMAP_ISSUE" != "null" ]; then
       # Use roadmap manager to mark as shipped
       source .spec-flow/scripts/bash/github-roadmap-manager.sh
       mark_issue_shipped "$FEATURE_SLUG" "$VERSION" "$(date +%Y-%m-%d)" "$PRODUCTION_URL"
   else
       # Fallback: Search by feature slug
       gh issue list --label "roadmap" --search "$FEATURE_SLUG in:body" --json number --jq '.[0].number' | while read -r issue_num; do
           [ -n "$issue_num" ] && mark_issue_shipped "$FEATURE_SLUG" "$VERSION"
       done
   fi
   ```

   - Uses issue number from state.yaml (stored by /feature) OR searches by slug
   - Updates labels: adds `status:shipped`, removes `status:in-progress`
   - Adds shipped comment with deployment details (URLs, version, timestamp)
   - Closes the issue

   **Clean up feature branch**:

   - Switches to main/master branch
   - Deletes local feature branch: `git branch -d [feature-branch]`
   - Deletes remote feature branch: `git push origin --delete [feature-branch]`

   **Check for infrastructure cleanup needs**:

   - Detects active feature flags (if using feature flag system)
   - Recommends cleanup commands for deprecated code
   - Warns about technical debt that should be addressed

4. After essential finalization completes successfully:

   - Update TodoWrite: Mark "Run essential finalization" as `completed`
   - Continue to Step 5

5. If essential finalization fails:
   - Update TodoWrite: Add "Fix finalization failure: [specific error]" as new todo
   - Keep "Run essential finalization" as `in_progress`
   - Display error details
   - Tell user to fix and run `/ship continue`
   - **EXIT**

### Step 5: Full Finalization (All Models)

1. Update TodoWrite: Mark "Run full finalization (/finalize)" as `in_progress`

2. Run the `/finalize` slash command (SlashCommand tool):

   ```
   /finalize
   ```

3. **What /finalize does** (see `.claude/commands/phases/finalize.md` for full details):

   **Update CHANGELOG.md**:

   - Moves unreleased changes to versioned section with today's date
   - Extracts version number for tagging (e.g., "1.2.0" from "## [1.2.0] - 2025-11-20")
   - Follows Keep a Changelog format

   **Update README.md**:

   - Updates installation instructions if dependencies changed
   - Adds usage examples for new features
   - Updates feature list in overview section

   **Update help documentation**:

   - User guides for new functionality
   - API documentation if endpoints added
   - Integration docs if third-party services added

   **GitHub Release Management**:

   - Creates/updates GitHub milestones
   - Closes current milestone (marks all issues complete)
   - Creates next milestone for upcoming work
   - Generates GitHub release with notes extracted from CHANGELOG.md

   **Version tagging** (if tagged promotion enabled):

   - Extracts version from CHANGELOG.md (e.g., "1.2.0")
   - Creates annotated git tag: `v{version}` with message from CHANGELOG
   - Pushes tag to remote: `git push origin v{version}`
   - Tag push triggers production deployment workflow (if configured)

4. After full finalization completes successfully:

   - Update TodoWrite: Mark "Run full finalization (/finalize)" as `completed`
   - Continue to Step 6

5. If full finalization fails:
   - Update TodoWrite: Add "Fix finalization failure: [specific error]" as new todo
   - Keep "Run full finalization (/finalize)" as `in_progress`
   - Display error details
   - Tell user to fix and run `/ship continue`
   - **EXIT**

### Step 6: Display Final Summary

1. Read state.yaml to extract deployment URLs and version

2. Display final summary:

   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ DEPLOYMENT COMPLETE
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Feature: {feature-name}
   Version: {version-tag}
   Model: {deployment-model}

   {If staging-prod}
   Staging URL: {staging-url}
   Production URL: {production-url}

   {If direct-prod}
   Production URL: {production-url}

   {If local-only}
   Local Build: ✅ Passed
   Main Branch: Merged and pushed

   Documentation:
   - CHANGELOG: Updated with v{version}
   - README: Updated with new features
   - GitHub Release: Created at https://github.com/{owner}/{repo}/releases/tag/v{version}

   Cleanup:
   - Feature branch deleted (local + remote)
   - Roadmap issue #{issue-number} closed and marked shipped

   📋 POST-DEPLOY CHECKLIST:
   □ Check health endpoint in 15 minutes: {production-url}/health
   □ Check error rates in 1 hour (monitoring dashboard)
   □ If issues detected: /ship rollback

   Next Steps:
   1. Complete post-deploy checklist above
   2. {If tech debt detected} Address technical debt before next feature
   3. Start next feature: /roadmap → /feature

   Total time: {elapsed-time}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

3. All TodoWrite items should now be marked `completed`

### Error Handling (All Steps)

**When ANY phase fails**:

1. Update TodoWrite: Add "Fix [specific error from logs]" as new todo
2. Keep failed phase as `in_progress` (don't mark as completed)
3. Display clear error message with:
   - Exact error message from tool output
   - Log file path if applicable (e.g., `$FEATURE_DIR/deploy.log`)
   - File:line references for code errors
   - Suggested remediation steps
4. Tell user: "Fix the error above and run `/ship continue` to resume from this phase"
5. **EXIT** (do not proceed to next phase)

**Resume from failure**:

- User runs `/ship continue`
- Workflow resumes from first `pending` or `in_progress` todo
- Skips all `completed` phases
- Retries failed phase after user has fixed the issue

</process>

<success_criteria>
**Ship workflow successfully completed when:**

1. **All phases executed** based on deployment model:

   - staging-prod: pre-flight + optimize (parallel) → staging deploy → validation → prod deploy → essential finalize → full finalize
   - direct-prod: pre-flight + optimize (parallel) → prod deploy → essential finalize → full finalize
   - local-only: pre-flight + optimize (parallel) → local build → merge to main → essential finalize → full finalize

2. **TodoWrite tracking maintained**:

   - All todos created at start of workflow
   - Each phase marked `completed` after success
   - Only one todo `in_progress` at a time
   - Errors added as new todos when failures occur

3. **Deployment successful**:

   - Pre-flight validation passed (local build, secrets check, CI syntax)
   - Optimize checks passed (code review, accessibility, performance, type safety, dependencies)
   - Deployment commands executed without errors
   - Deployment URLs extracted from actual tool output (not fabricated)
   - Version tags created and pushed (if applicable)

4. **Validation passed** (staging-prod model only):

   - E2E tests passed
   - Lighthouse scores meet thresholds
   - Rollback test passed
   - Health checks passed
   - Validation report generated at `$FEATURE_DIR/staging-validation-report.md`

5. **Finalization completed**:

   - Essential finalization: roadmap issue closed, feature branch deleted, cleanup recommendations generated
   - Full finalization: CHANGELOG updated, README updated, GitHub release created, version tag pushed

6. **User informed**:

   - Final summary displayed with deployment URLs, version, next steps
   - All TodoWrite items marked `completed`
   - No errors or warnings

7. **Continue mode works**:

   - `/ship continue` resumes from last completed phase
   - Skips completed work, retries failed phase
   - TodoWrite state preserved across continue invocations

8. **Status mode works**:
   - `/ship status` displays current phase, completed/pending phases, errors
   - Does not modify state or proceed with deployment
   - Exits after displaying status

9. **Auto mode works** (v11.7):
   - `/ship --auto` runs full deployment without manual prompts
   - Auto-merge PR when CI passes (if `deployment.auto_merge: true`)
   - Continues to /finalize automatically (if `deployment.auto_finalize: true`)
   - Stores auto_mode settings in state.yaml for resume capability
   - Works with all deployment models (staging-prod, direct-prod, local-only)
     </success_criteria>

<verification>
**Before marking ship workflow complete, verify:**

1. **Check TodoWrite state**:

   - All todos should be marked `completed`
   - No todos should remain `in_progress` or `pending`
   - If using `/ship status`, verify displayed state matches actual state.yaml

2. **Verify deployment artifacts**:

   ```bash
   # Check workflow state file
   cat $FEATURE_DIR/state.yaml | grep -A2 "ship:"
   # Should show: status: completed

   # Check deployment URLs recorded
   cat $FEATURE_DIR/state.yaml | grep "deployment_url"
   # Should show actual URLs from deployment output

   # Check version tag created (if applicable)
   git tag -l | grep "v[0-9]"
   # Should show new version tag

   # Check feature branch deleted
   git branch -a | grep [feature-branch-name]
   # Should return empty (branch deleted)
   ```

3. **Verify finalization artifacts**:

   ```bash
   # Check CHANGELOG updated
   head -20 CHANGELOG.md
   # Should show new version section with today's date

   # Check GitHub release created
   gh release list | head -3
   # Should show new release with correct version tag

   # Check roadmap issue closed
   gh issue view {issue-number} --json state -q .state
   # Should show: closed
   ```

4. **Verify validation report** (staging-prod model only):

   ```bash
   # Check staging validation report exists
   test -f $FEATURE_DIR/staging-validation-report.md && echo "exists" || echo "missing"
   # Should show: exists

   # Check validation report contains actual results
   grep -E "E2E Tests:|Lighthouse" $FEATURE_DIR/staging-validation-report.md
   # Should show actual test counts and scores (not placeholders)
   ```

5. **Verify no fabricated data**:

   - Deployment URLs match actual output from deployment tools (not guessed)
   - Version tags exist in git (verified with `git tag -l`)
   - Deployment IDs extracted from actual platform APIs (not invented)
   - Validation scores from actual Lighthouse/E2E reports (not assumed)

6. **Verify error handling** (if any phase failed):
   - TodoWrite shows "Fix [specific error]" todo added
   - Failed phase remains `in_progress` (not marked completed)
   - Error message includes actual tool output (not generic message)
   - Log file path provided if applicable

**Never claim deployment complete without verifying all artifacts exist and contain real data (not placeholders).**
</verification>

<output>
**Files created/modified by this command:**

**Workflow state**:

- `specs/NNN-slug/state.yaml` - Ship phase marked completed, deployment URLs recorded, version tag recorded

**Validation reports** (staging-prod model only):

- `specs/NNN-slug/staging-validation-report.md` - E2E tests, Lighthouse scores, rollback test, health checks

**Documentation**:

- `CHANGELOG.md` - Unreleased section moved to versioned section with date
- `README.md` - Installation, usage, features updated
- Help docs - User guides, API docs, integration docs updated (if applicable)

**GitHub artifacts**:

- GitHub Release created at `https://github.com/{owner}/{repo}/releases/tag/v{version}`
- Roadmap issue closed and labeled `status:shipped`
- Current milestone closed (if all issues complete)
- Next milestone created (if workflow configured)

**Git artifacts**:

- Version tag created: `v{version}` (if tagged promotion enabled)
- Version tag pushed to remote: `git push origin v{version}`
- Feature branch deleted locally: `git branch -d [feature-branch]`
- Feature branch deleted remotely: `git push origin --delete [feature-branch]`

**Console output**:

- Pre-flight validation results (build status, secrets check, CI syntax)
- Optimize check results (code review, accessibility, performance, type safety, dependencies)
- Deployment URLs (staging and/or production)
- Validation summary (E2E tests, Lighthouse scores, rollback test, health checks) - staging-prod model only
- Final summary (deployment URLs, version, cleanup status, next steps)
- TodoWrite progress updates throughout workflow

**Deployment artifacts** (platform-specific):

- Vercel: Deployment ID, preview URL, production URL
- Netlify: Deployment ID, deploy URL, production URL
- Custom CI/CD: Deployment logs, artifact URLs

**Error artifacts** (if failures occurred):

- Error logs at `$FEATURE_DIR/deploy.log` (if deployment failed)
- Build logs at `$FEATURE_DIR/build.log` (if build failed)
- Validation failure details in `$FEATURE_DIR/staging-validation-report.md` (if validation failed)
  </output>

---

## Notes

**Deployment Model Auto-Detection**:

- **staging-prod**: Detected when git remote exists + staging branch exists + `.github/workflows/deploy-staging.yml` exists
- **direct-prod**: Detected when git remote exists + no staging branch
- **local-only**: Detected when no git remote configured

**Parallel Execution**:

- Pre-flight + /optimize run in parallel (saves ~10 minutes)
- Use single message with multiple tool calls to execute in parallel

**Continue Mode**:

- `/ship continue` resumes from last completed phase
- Reads state.yaml to find current phase
- Skips completed work, retries failed phase
- Preserves TodoWrite state across invocations

**Status Mode**:

- `/ship status` displays current deployment status
- Shows deployment model, current phase, completed/pending phases, errors
- Does NOT proceed with deployment (read-only operation)
- Exits after displaying status

**Auto Mode (v11.7)**:

- `/ship --auto` runs full deployment without manual prompts
- Controlled by user preferences:
  - `deployment.auto_ship: true` → Enable auto-mode for ship command (when called from /feature --auto)
  - `deployment.auto_merge: true` → Auto-merge PR when CI passes (no production approval prompt)
  - `deployment.auto_finalize: true` → Continue to /finalize automatically
- Use case: CI/CD pipelines, trusted deployments, experienced users
- Stores auto_mode settings in state.yaml: `auto_mode.enabled`, `auto_mode.auto_merge`, `auto_mode.auto_finalize`
- Resume works normally: `/ship continue` respects stored auto_mode settings

**Manual Gates Removed**:

- v3.0 removed /preview manual gate (now fully automated in /optimize)
- v3.0 removed interactive version selection (now auto-extracted from CHANGELOG)
- v3.0 replaced manual staging validation with automated report generation

**Validation Automation** (staging-prod model):

- E2E tests: Results already in CI logs (no re-run needed)
- Lighthouse: Automated scan of staging URL
- Rollback test: Automated alias swap verification
- Health checks: Automated HTTP 200 verification

**Platform Support**:

- Vercel: First-class support (deployment ID extraction via API)
- Netlify: First-class support (deployment ID extraction via API)
- Custom CI/CD: Supported (requires platform-specific scripts)
- Docker: Supported (local build + push to registry)

**GitHub CLI Required**:

- For roadmap issue updates (closing issues, updating labels)
- For GitHub release creation
- For milestone management
- If `gh` not authenticated, certain finalization steps will be skipped with warnings

**Troubleshooting**:

- If deployment fails: Check platform credentials (VERCEL_TOKEN, NETLIFY_AUTH_TOKEN)
- If validation fails: Review `$FEATURE_DIR/staging-validation-report.md` for specific test failures
- If finalization fails: Ensure GitHub CLI is authenticated (`gh auth login`)
- If continue mode doesn't resume: Check state.yaml for correct phase status

**Performance Baseline (v10.14+)**:

Performance baseline comparison is stored in `.spec-flow/analytics/performance-baseline.json`:

```json
{
  "baseline_date": "2025-12-01",
  "lighthouse": {
    "performance": 85,
    "accessibility": 95,
    "best_practices": 90,
    "seo": 100
  },
  "web_vitals": {
    "ttfb_ms": 200,
    "lcp_ms": 2500,
    "cls": 0.1,
    "fid_ms": 100
  },
  "bundle_size_kb": 150
}
```

During staging validation, current metrics are compared against baseline:
- **Regression threshold**: 10% (configurable via `PERF_REGRESSION_THRESHOLD` env var)
- **Blocking**: Deployment blocked if any metric regresses beyond threshold
- **Override**: Use `--skip-perf-check` to bypass (not recommended for production)

To update baseline after intentional changes:
```bash
python .spec-flow/scripts/spec-cli.py update-perf-baseline --feature-dir "$FEATURE_DIR"
```

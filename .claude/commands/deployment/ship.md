---
description: Unified deployment orchestrator with multi-model support
version: 3.0
updated: 2025-11-18
---

# /ship — Unified Deployment Orchestrator

**Purpose**: Orchestrate complete post-implementation deployment workflow from optimization through production release

**Workflow**: optimize → deploy-staging → [manual staging validation] → deploy-prod → finalize

**Usage**:
- `/ship` - Start deployment workflow from beginning
- `/ship continue` - Resume from last completed phase or proceed after manual gate
- `/ship status` - Display current deployment status

**Deployment Models**:
- **staging-prod**: Full staging validation before production (recommended)
- **direct-prod**: Direct production deployment (skip staging)
- **local-only**: Local build and integration only

**Manual Gate**: Staging validation (test complete feature in staging before production)

**Dependencies**: Requires completed `/implement` phase

---

<context>
## TODO TRACKING REQUIREMENT

**CRITICAL**: You MUST use TodoWrite to track all ship workflow progress.

**Why**: The /ship workflow involves 5-8 phases over 20-40 minutes with manual gates. Without TodoWrite, user loses visibility and cannot resume after errors.

**When to use TodoWrite**:
1. Immediately after loading feature context - create full todo list
2. After every phase completes - mark completed, mark next as in_progress
3. When errors occur - add "Fix [specific error]" todo
4. At manual gates - keep as pending until user approval

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

## Step 2: Execute Pre-flight Validation

Run pre-flight checks using centralized CLI:

```bash
python .spec-flow/scripts/spec-cli.py ship-finalize preflight --feature-dir "$FEATURE_DIR"
```

**What it does**:
- Runs local build to catch errors early
- Checks GitHub secrets (if gh CLI available)
- Validates CI workflow syntax (if .github/workflows exists)

If any check fails:
- Update TodoWrite: Add "Fix [specific error]" as new todo
- Keep "Run pre-flight validation" as `in_progress`
- Tell user to fix error and run `/ship continue`
- **EXIT**

If all checks pass:
- Update TodoWrite: Mark pre-flight as `completed`, mark /optimize as `in_progress`
- Continue to Step 3

## Step 3: Run /optimize

Execute the `/optimize` slash command:

```bash
/optimize
```

After `/optimize` completes:
- Update TodoWrite: Mark /optimize as `completed`, mark deployment phase as `in_progress`
- Continue to Step 4

If `/optimize` fails:
- Update TodoWrite: Add "Fix code review issues" as new todo
- Tell user to address issues and run `/ship continue`
- **EXIT**

## Step 4: Deploy (Model-Specific)

### If staging-prod model:

1. **Deploy to staging**:
   ```bash
   /ship-staging
   ```
   Update TodoWrite: Mark staging deploy as `completed`, mark validation as `pending`

2. **Wait for staging validation** (manual gate):

   Display manual gate message:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🛑 MANUAL GATE: Staging Validation Required
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Feature deployed to staging. Test in production-like environment:

   **What to test** (all UI/UX, accessibility, performance testing happens here):
   1. ✅ All feature functionality and user flows
   2. ✅ UI/UX across browsers and screen sizes
   3. ✅ Accessibility (keyboard nav, screen readers, WCAG 2.1 AA)
   4. ✅ Performance (load times, responsiveness)
   5. ✅ Integration with existing features
   6. ✅ Error handling and edge cases
   7. ✅ Visual design matches mockups

   **Staging URLs**:
   - Marketing: https://staging.[domain].com
   - App: https://app.staging.[domain].com
   - API: https://api.staging.[domain].com/docs

   When validation complete, run: /ship continue
   To abort: /ship abort
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

   **EXIT** - wait for user to run `/ship continue`

3. **Deploy to production** (after staging approval):
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

## Step 5: Essential Finalization (All Models)

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
- Continue to Step 6

## Step 6: Full Finalization (Automatic)

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

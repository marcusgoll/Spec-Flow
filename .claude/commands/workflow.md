---
description: Orchestrate full feature workflow from idea to staging (with manual gates)
---

## PARSE ARGUMENTS

**Get feature description or continue mode:**

If $ARGUMENTS is empty, show usage:
```
Usage: /workflow [feature description]
   or: /workflow continue

Examples:
  /workflow "Student progress tracking dashboard"
  /workflow continue
```

If $ARGUMENTS is "continue":
- Set CONTINUE_MODE = true
- Load workflow state from `\spec-flow/workflow-state.json`
- Resume from last completed phase

Else:
- Set CONTINUE_MODE = false
- Set FEATURE_DESCRIPTION = $ARGUMENTS
- Initialize new workflow

## DETECT PROJECT TYPE

**Run project type detection:**

```bash
# Use detection script (bash or PowerShell based on OS)
if command -v bash &> /dev/null; then
  PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
else
  PROJECT_TYPE=$(pwsh -File .spec-flow/scripts/powershell/detect-project-type.ps1)
fi

echo "📦 Project type: $PROJECT_TYPE"
echo ""
```

**Project types:**
- `local-only` - No remote repo, workflow ends at `/optimize`
- `remote-staging-prod` - Full staging → production workflow
- `remote-direct` - Remote repo, direct to main (no staging)

## INITIALIZE WORKFLOW STATE

**Create or load workflow state file:**

State file location: `\spec-flow/workflow-state.json`

**For new workflows:**
Create state file with:
```json
{
  "feature": "[feature-slug]",
  "project_type": "[local-only|remote-staging-prod|remote-direct]",
  "current_phase": 0,
  "phases_completed": [],
  "started_at": "[ISO timestamp]",
  "last_updated": "[ISO timestamp]",
  "status": "in_progress",
  "manual_gates": {
    "preview": false,
    "validate_staging": false
  },
  "timings": {}
}
```

**For continue mode:**
Read existing state file to determine next phase and project type.

## MENTAL MODEL

**Workflow**: Feature idea → Staging deployment (**YOLO mode** - fully automated)

**Pattern**: Orchestrator-Workers (from Anthropic best practices)
- **Orchestrator**: /workflow tracks progress, manages context, handles errors
- **Workers**: Individual slash commands are specialists
- **YOLO mode**: Full automation, only stops for:
  - User questions (clarifications during \spec-flow)
  - Manual testing gates (/preview, /validate-staging)

**Context management**:
- Auto-compact after each phase with phase-specific instructions
- Just-in-time loading of artifacts
- Phase-aware compression strategies (aggressive/moderate/minimal)

## STATE MACHINE

```
IDEA/DESCRIPTION
  ↓
PHASE 0:\spec-flow → spec.md created → /compact (preserve spec decisions)
  ↓ [auto-check for clarifications]
  ├─ If [NEEDS CLARIFICATION] → PHASE 0.5: CLARIFY → /compact
  └─ Else → PHASE 1: PLAN
  ↓
PHASE 1: PLAN → plan.md, research.md created → /compact (preserve research decisions)
  ↓
PHASE 2: TASKS → tasks.md (20-30 tasks) created → /compact (keep task breakdown)
  ↓
PHASE 3: ANALYZE → analysis-report.md → /compact (preserve critical issues)
  ↓ [check for CRITICAL issues]
  ├─ If CRITICAL → PAUSE: User must fix
  └─ Else → PHASE 4: IMPLEMENT
  ↓
PHASE 4: IMPLEMENT → All tasks completed → /compact (keep last 20 checkpoints)
  ↓
PHASE 5: OPTIMIZE → optimization-report.md → /compact (preserve code review)
  ↓ [auto-fix enabled?]
  ├─ If critical issues → Auto-fix loop (max 3 iterations)
  └─ If blockers remain → PAUSE: User must fix
  ↓
MANUAL GATE 1: PREVIEW → User validates UI/UX
  ↓ User confirms quality
  ↓
PHASE 6: PHASE-1-SHIP → PR to staging, auto-merge
  ↓ [wait for CI, auto-merge when green]
  ↓
MANUAL GATE 2: VALIDATE-STAGING → User validates staging deployment
  ↓ User approves for production
  ↓
PHASE 7: PHASE-2-SHIP → PR to main, auto-merge, release
  ↓
PHASE 7.5: FINALIZE → Update docs (CHANGELOG, README, help), manage milestones
  ↓
✅ DONE: Feature shipped to production with documentation complete
```

## EXECUTION STRATEGY

### Phase 0: Specification (DESIGN)

**EXECUTE in sequence:**

1. **Update state (start phase 0):**
   - Set `current_phase = 0`
   - Set `status = "in_progress"`
   - Record start timestamp

2. **Run /spec-flow command:**
   - INVOKE: `/spec-flow "$ARGUMENTS"` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: `specs/[feature-slug]/spec.md` created

3. **Run /compact command (if available):**
   - TRY: `/compact "preserve spec decisions, requirements, and UX research"`
   - If command not found: Skip with log message

4. **Check for clarifications:**
   - READ: `specs/[feature-slug]/spec.md`
   - SCAN: For `[NEEDS CLARIFICATION]` markers
   - IF FOUND:
     - LOG: "📋 Clarifications needed"
     - INVOKE: `/clarify` (use SlashCommand tool)
     - WAIT: For completion
     - TRY: `/compact "preserve spec decisions and clarifications"`

5. **Update state (complete phase 0):**
   - Add 0 to `phases_completed`
   - Record end timestamp
   - Update `last_updated`

6. **Auto-progress to Phase 1:**
   - LOG: "✅ Spec clear, proceeding to plan"
   - CONTINUE to Phase 1 (no user input needed)

### Phase 1: Planning (DESIGN)

**EXECUTE in sequence:**

1. **Run /plan command:**
   - INVOKE: `/plan` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: `specs/NNN-*/plan.md` created

2. **Run /compact command:**
   - INVOKE: `/compact "preserve research decisions, architecture headings, and reuse analysis"`
   - WAIT: For completion

3. **Auto-progress to Phase 2:**
   - LOG: "✅ Plan complete, proceeding to tasks"
   - CONTINUE to Phase 2 (no user input needed)

### Phase 2: Task Breakdown (DESIGN)

**EXECUTE in sequence:**

1. **Run /tasks command:**
   - INVOKE: `/tasks` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: `specs/NNN-*/tasks.md` created

2. **Run /compact command:**
   - INVOKE: `/compact "keep task breakdown, priorities, and error log"`
   - WAIT: For completion

3. **Auto-progress to Phase 3:**
   - LOG: "✅ Tasks generated, proceeding to analyze"
   - CONTINUE to Phase 3 (no user input needed)

### Phase 3: Analysis (VALIDATION)

**EXECUTE in sequence:**

1. **Run /analyze command:**
   - INVOKE: `/analyze` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: `specs/NNN-*/artifacts/analysis-report.md` created

2. **Run /compact command:**
   - INVOKE: `/compact "preserve critical issues, blocking concerns, and analysis findings"`
   - WAIT: For completion

3. **Check for blockers:**
   - READ: `specs/NNN-*/artifacts/analysis-report.md`
   - SCAN: For `"Critical: [1-9]"` pattern
   - IF CRITICAL ISSUES FOUND:
     - LOG: "❌ CRITICAL ISSUES FOUND"
     - LOG: "Review: specs/NNN-*/artifacts/analysis-report.md"
     - LOG: ""
     - LOG: "Fix critical issues, then run: /workflow continue"
     - PAUSE: Exit workflow, return control to user
   - ELSE:
     - LOG: "✅ Analysis passed, proceeding to implement"
     - CONTINUE to Phase 4 (no user input needed)

### Phase 4: Implementation (EXECUTION)

**EXECUTE in sequence:**

1. **Run /implement command:**
   - INVOKE: `/implement` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: All tasks completed

2. **Run /compact command:**
   - INVOKE: `/compact "keep last 20 task checkpoints, full error log, and implementation notes"`
   - WAIT: For completion

3. **Auto-progress to Phase 5:**
   - LOG: "✅ Implementation complete, proceeding to optimize"
   - CONTINUE to Phase 5 (no user input needed)

### Phase 5: Optimization (VALIDATION)

**EXECUTE in sequence:**

1. **Update state (start phase 5):**
   - Set `current_phase = 5`
   - Set `status = "in_progress"`
   - Record start timestamp

2. **Run /optimize command:**
   - INVOKE: `/optimize` (use SlashCommand tool)
   - WAIT: For completion
   - VERIFY: `specs/[feature-slug]/artifacts/optimization-report.md` created

3. **Run /compact command (if available):**
   - TRY: `/compact "preserve code review report, all quality metrics, and all checkpoints"`
   - If command not found: Skip with log message

4. **Check for blockers (see BLOCKER DETECTION section):**
   - READ: `specs/[feature-slug]/artifacts/optimization-report.md`
   - COUNT: "❌ BLOCKER" occurrences
   - IF BLOCKERS FOUND:
     - Display blockers to user
     - Check `specs/[feature-slug]/artifacts/code-review-report.md` for auto-fixable issues
     - IF AUTO-FIXABLE:
       - ASK: "Auto-fix critical issues? (y/n)"
       - IF YES: /optimize handles auto-fix internally, then re-check
       - IF NO: PAUSE workflow
     - ELSE:
       - LOG: "Manual fixes required"
       - PAUSE: Set `status = "blocked"`, exit workflow

5. **Update state (complete phase 5):**
   - Add 5 to `phases_completed`
   - Record end timestamp
   - Update `last_updated`

6. **Auto-progress to MANUAL GATE 1:**
   - LOG: "✅ Optimization complete, ready for preview"
   - CONTINUE to MANUAL GATE 1 (no user input needed)

### MANUAL GATE 1: Preview (USER VALIDATION)

**PAUSE for user validation:**

1. **Update state:**
   - Set `status = "awaiting_preview"`
   - Record gate reached timestamp

2. **Display preview gate:**
   - LOG: ""
   - LOG: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   - LOG: "🎨 MANUAL GATE: UI/UX PREVIEW"
   - LOG: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   - LOG: ""
   - LOG: "Next: /preview"
   - LOG: ""
   - LOG: "Action required:"
   - LOG: "1. Run local dev server"
   - LOG: "2. Test UI/UX manually"
   - LOG: "3. Verify against spec.md requirements"
   - LOG: "4. Check visuals/README.md patterns followed"
   - LOG: ""
   - LOG: "Then continue with: /workflow continue"
   - PAUSE: Exit workflow, return control to user

3. **Resume after /preview (when user runs /workflow continue):**
   - Check for preview completion markers (see MANUAL GATE DETECTION)
   - If preview not complete: Display error, require /preview first
   - If preview complete:
     - Set `manual_gates.preview = true`
     - CONTINUE to Phase 6 (Ship to Staging)

### Phase 6: Ship to Staging (DEPLOYMENT)

**Check project type (skip for local-only):**

```bash
# Read project type from state file
PROJECT_TYPE=$(grep -o '"project_type":\s*"[^"]*"' .spec-flow/workflow-state.json | cut -d'"' -f4)

if [ "$PROJECT_TYPE" = "local-only" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Local-only project detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Skipping staging deployment (no remote repository configured)."
  echo ""
  echo "✅ Feature implementation complete!"
  echo ""
  echo "Next steps (manual deployment):"
  echo "  1. Review changes: git diff main"
  echo "  2. Merge to main: git checkout main && git merge \$FEATURE_BRANCH"
  echo "  3. Tag release: git tag v1.0.0"
  echo "  4. Deploy manually to your environment"
  echo ""
  echo "To enable remote workflow:"
  echo "  1. Add remote: git remote add origin <url>"
  echo "  2. Create staging branch: git checkout -b staging main && git push -u origin staging"
  echo "  3. Re-run: /workflow continue"
  echo ""
  exit 0
fi

echo "✅ Project type: $PROJECT_TYPE (remote deployment enabled)"
echo ""
```

**EXECUTE in sequence (after /preview completed):**

1. **Update state (start phase 6):**
   - Set `current_phase = 6`
   - Set `status = "in_progress"`
   - Record start timestamp

2. **Run /phase-1-ship command:**
   - INVOKE: `/phase-1-ship` (use SlashCommand tool)
   - WAIT: For completion (includes CI wait + auto-merge)
   - VERIFY: PR created, CI passing, auto-merged to main

3. **Log deployment success:**
   - LOG: "⏳ Waiting for CI checks and auto-merge..."
   - LOG: "✅ Deployed to staging environment"
   - LOG: ""
   - LOG: "Staging URLs:"
   - LOG: "  - Marketing: https://staging.cfipros.com"
   - LOG: "  - App: https://app.staging.cfipros.com"
   - LOG: "  - API: https://api.staging.cfipros.com"

4. **Update state (complete phase 6):**
   - Add 6 to `phases_completed`
   - Record end timestamp
   - Update `last_updated`

5. **Auto-progress to MANUAL GATE 2:**
   - CONTINUE to MANUAL GATE 2 (no user input needed)

### MANUAL GATE 2: Validate Staging (USER VALIDATION)

**PAUSE for user validation:**

1. **Update state:**
   - Set `status = "awaiting_staging_validation"`
   - Record gate reached timestamp

2. **Display staging validation gate:**
   - LOG: ""
   - LOG: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   - LOG: "🧪 MANUAL GATE: STAGING VALIDATION"
   - LOG: "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   - LOG: ""
   - LOG: "Next: /validate-staging"
   - LOG: ""
   - LOG: "Action required:"
   - LOG: "1. Test feature on staging environment"
   - LOG: "2. Verify E2E tests passed (GitHub Actions)"
   - LOG: "3. Check Lighthouse CI scores (Performance >90, A11y >95)"
   - LOG: "4. Confirm no regressions"
   - LOG: ""
   - LOG: "Then continue with: /workflow continue"
   - PAUSE: Exit workflow, return control to user

3. **Resume after /validate-staging (when user runs /workflow continue):**
   - Check for staging validation completion (see MANUAL GATE DETECTION)
   - If validation not complete: Display error, require /validate-staging first
   - If validation complete:
     - Set `manual_gates.validate_staging = true`
     - CONTINUE to Phase 7 (Ship to Production)

### Phase 7: Ship to Production (DEPLOYMENT)

**EXECUTE in sequence (after /validate-staging completed):**

1. **Ensure on main branch:**
   - VERIFY: Current branch is `main` (staging is an environment, not a branch)
   - If not on main: `git checkout main && git pull origin main`

2. **Run /phase-2-ship command:**
   - INVOKE: `/phase-2-ship` (use SlashCommand tool)
   - WAIT: For completion (promotes staging artifacts to production)
   - VERIFY: Artifacts promoted, release created

3. **Run /finalize command (documentation housekeeping):**
   - INVOKE: `/finalize` (use SlashCommand tool)
   - WAIT: For completion
   - Updates CHANGELOG.md, README.md, help docs
   - Manages GitHub milestones
   - Commits documentation changes

4. **Update workflow state:**
   - Mark phase 7 as complete
   - Set status to "completed"
   - Record completion timestamp

5. **Complete workflow:**
   - LOG: "✅ SHIPPED TO PRODUCTION 🎉"
   - LOG: ""
   - LOG: "Production URLs:"
   - LOG: "  - Marketing: https://cfipros.com"
   - LOG: "  - App: https://app.cfipros.com"
   - LOG: "  - API: https://api.cfipros.com"
   - LOG: ""
   - LOG: "Release created with version tag"
   - LOG: "Roadmap updated (moved to 'Shipped')"
   - LOG: "Documentation updated (CHANGELOG, README, help)"
   - DONE: Workflow complete

## CONTEXT COMPACTION (Auto After Each Phase)

The `/workflow` command automatically runs `/compact` after each phase with phase-specific instructions.

**Note**: If `/compact` command doesn't exist, skip compaction and continue workflow.

### Compaction Triggers (Automatic in YOLO Mode)

Try to invoke `/compact` after each phase:

- **After \spec-flow**: `/compact "preserve spec decisions, requirements, and UX research"`
- **After /clarify**: `/compact "preserve spec decisions and clarifications"`
- **After /plan**: `/compact "preserve research decisions, architecture headings, and reuse analysis"`
- **After /tasks**: `/compact "keep task breakdown, priorities, and error log"`
- **After /analyze**: `/compact "preserve critical issues, blocking concerns, and analysis findings"`
- **After /implement**: `/compact "keep last 20 task checkpoints, full error log, and implementation notes"`
- **After /optimize**: `/compact "preserve code review report, all quality metrics, and all checkpoints"`

If `/compact` command is not available:
- Log: "⚡ Compaction skipped (command not available)"
- Continue to next phase

### Phase-Specific Strategies

**Planning (Aggressive):**
- ✅ Keep: Decisions, architecture, last 5 checkpoints, error log
- ❌ Remove: Detailed research notes, full task descriptions

**Implementation (Moderate):**
- ✅ Keep: Decisions, architecture, last 20 checkpoints, error log
- ❌ Remove: Old research, verbose task descriptions

**Optimization (Minimal):**
- ✅ Keep: All decisions, all checkpoints, error log, **code review report**
- ❌ Remove: Only redundant research

## PAUSE POINTS (Manual Intervention)

### Critical Issues After /analyze
```
❌ PAUSE: Critical issues found in analysis

Review: specs/NNN-*/artifacts/analysis-report.md

Fix critical issues:
- [Issue 1 description]
- [Issue 2 description]

Then continue: /workflow continue
```

### Blockers After /optimize
```
⚠️  PAUSE: Optimization blockers found

Review: specs/NNN-*/artifacts/optimization-report.md

Auto-fix available? (y/n)

If yes: Auto-fix will run (max 3 iterations)
If no: Fix manually, then: /workflow continue
```

### Preview Gate
```
🎨 MANUAL GATE: UI/UX Preview

Run: /preview

Validate:
- [ ] UI matches spec requirements
- [ ] UX follows visuals/README.md patterns
- [ ] No visual regressions
- [ ] Responsive design works

Then continue: /workflow continue
```

### Staging Validation Gate
```
🧪 MANUAL GATE: Staging Validation

Run: /validate-staging

Check:
- [ ] Feature works on staging
- [ ] E2E tests passed (GitHub Actions)
- [ ] Lighthouse CI scores met (>90 Performance, >95 A11y)
- [ ] No production-breaking changes

Then continue: /workflow continue
```

## CONTINUE MODE

Resume workflow after manual intervention:

```bash
/workflow continue
```

### Resume Logic

**Load workflow state:**

1. Read `\spec-flow/workflow-state.json`
2. Extract current phase, manual gate status, and feature slug
3. Determine next action based on state

**Decision tree:**

```
If current_phase = 0:
  → Check if clarifications resolved → Next: /plan

If current_phase = 1:
  → Next: /tasks

If current_phase = 2:
  → Next: /analyze

If current_phase = 3:
  → Check if critical issues exist → Next: /implement or PAUSE

If current_phase = 4:
  → Next: /optimize

If current_phase = 5:
  → Check manual_gates.preview status
    → If false: PAUSE "Run /preview first"
    → If true: Next: /phase-1-ship

If current_phase = 6:
  → Check manual_gates.validate_staging status
    → If false: PAUSE "Run /validate-staging first"
    → If true: Next: /phase-2-ship

If current_phase = 7:
  → Workflow complete
```

**Display progress:**

Show user:
- Current phase completed
- Next phase to execute
- Time spent so far
- Tasks completed / total

## STATE MANAGEMENT

**Update workflow state after each phase:**

1. **Start phase:**
   - Update `current_phase` in state file
   - Record start timestamp in `timings[phase]`
   - Set `status` to "in_progress"

2. **Complete phase:**
   - Add phase to `phases_completed` array
   - Record end timestamp and duration
   - Update `last_updated` timestamp

3. **Manual gate reached:**
   - Set `status` to "awaiting_[gate_name]"
   - Display gate requirements
   - Pause workflow

4. **Manual gate completed:**
   - When /preview completes: Set `manual_gates.preview = true`
   - When /validate-staging completes: Set `manual_gates.validate_staging = true`
   - Update state file

**State file operations:**

Use JSON manipulation:
- Read: Parse `\spec-flow/workflow-state.json`
- Write: Update and save back to file
- Atomic: Ensure writes don't corrupt state

## MANUAL GATE DETECTION

**Preview gate completion:**

Check if user has completed /preview:
1. Look for `specs/[feature-slug]/artifacts/preview-notes.md`
2. Check for "✅ Preview complete" marker in NOTES.md
3. If found: Set `manual_gates.preview = true`

**Staging validation gate completion:**

Check if user has completed /validate-staging:
1. Look for `specs/[feature-slug]/artifacts/staging-validation-report.md`
2. Check for "Ready for production: ✅ Yes" in report
3. If found: Set `manual_gates.validate_staging = true`

**Gate status display:**

When pausing at gate:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 MANUAL GATE: [Gate Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: ⏳ Waiting for validation

Action required:
  1. [Step 1]
  2. [Step 2]
  3. [Step 3]

Then: /workflow continue
```

## COMMAND INVOCATION

**Execute slash commands:**

Use SlashCommand tool to invoke other commands:

```
\spec-flow "[feature description]"
/clarify
/plan
/tasks
/analyze
/implement
/optimize
/preview
/phase-1-ship
/validate-staging
/phase-2-ship
```

**Wait for completion:**
- Each command runs synchronously
- Wait for command to complete before next phase
- Check exit status / completion markers

**Error handling:**
- If command fails: Offer debug/skip/abort options
- If critical issues found: Pause workflow
- If auto-fix available: Offer to run

## BLOCKER DETECTION

**After /analyze (Phase 3):**

Check for critical issues:
1. Read `specs/[feature-slug]/artifacts/analysis-report.md`
2. Look for "Critical:" markers
3. Count critical issues
4. If count > 0:
   - Display critical issues
   - PAUSE workflow
   - Show: "Fix critical issues, then: /workflow continue"

**After /optimize (Phase 5):**

Check for blockers:
1. Read `specs/[feature-slug]/artifacts/optimization-report.md`
2. Look for "❌ BLOCKER" markers
3. Count blockers
4. If count > 0:
   - Check if auto-fix available (look for "Severity: CRITICAL" in code-review-report.md)
   - If auto-fix available:
     - Offer: "Auto-fix critical issues? (y/n)"
     - If yes: /optimize handles auto-fix internally
   - If no auto-fix or user declines:
     - PAUSE workflow
     - Show: "Fix blockers, then: /workflow continue"

## ERROR HANDLING

**When command fails:**

1. Display error context:
   - Phase number and command name
   - Error message
   - Relevant logs from NOTES.md or error-log.md

2. Offer recovery options:
   ```
   ❌ Error in Phase N: [command]

   Error: [error message]

   Options:
     A) Debug with /debug
     B) Skip phase (with warning - may cause downstream issues)
     C) Abort workflow

   Choose option:
   ```

3. Execute chosen option:
   - **Debug**: Invoke /debug command, then ask if ready to continue
   - **Skip**: Mark phase as skipped, continue to next phase with warning
   - **Abort**: Exit workflow, preserve state for later resume

**When CI fails:**

1. Detect CI failure in /phase-1-ship or /phase-2-ship
2. Offer auto-fix via /checks:
   ```
   ❌ CI checks failed

   Failed checks: [list]

   Auto-fix available: /checks pr [number]

   Options:
     A) Run /checks to auto-fix
     B) Fix manually
     C) Abort deployment

   Choose option:
   ```

**When agent times out:**

1. Display timeout context
2. Offer retry with explanation:
   ```
   ⏱️  Agent timeout in Phase N

   Agent: [agent-name]
   Task: [task-description]

   Options:
     A) Retry (may take longer)
     B) Manual implementation
     C) Skip task

   Choose option:
   ```

## WORKFLOW COMPLETION

**When Phase 7 completes successfully:**

1. **Update state:**
   - Set `current_phase = 7`
   - Set `status = "completed"`
   - Add 7 to `phases_completed`
   - Record completion timestamp

2. **Calculate metrics:**
   - Total duration: completion timestamp - started_at
   - Phase durations: from timings object
   - Total tasks completed
   - Auto-compactions run
   - Auto-fixes applied

3. **Display completion summary:**
   - See RETURN section for format
   - Show timeline, metrics, URLs, release info

4. **Cleanup (optional):**
   - Archive workflow state to `specs/[feature-slug]/.workflow-state.json`
   - Remove `\spec-flow/workflow-state.json`
   - Allow starting new workflow

## PROGRESS VISUALIZATION

**Display progress bar when requested:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Workflow Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Phase 0:\spec-flow
✅ Phase 1: Plan
✅ Phase 2: Tasks
✅ Phase 3: Analyze
⏳ Phase 4: Implement (in progress)
⏭️  Phase 5: Optimize
⏭️  Phase 6: Ship to Staging
⏭️  Phase 7: Ship to Production

Progress: 50% (4/8 phases complete)
Time elapsed: 2h 15m
Estimated remaining: 2h 30m
```

## CONSTRAINTS

- **One feature at a time**: Workflow tracks single feature directory
- **Sequential phases**: Cannot skip phases (analysis before implementation)
- **Manual gates are mandatory**: Preview and staging validation required
- **Auto-compaction**: Runs after each phase (if /compact available)
- **State persistence**: All state in `\spec-flow/workflow-state.json`
- **Resumable**: Can pause/continue at any phase or gate

## USAGE EXAMPLES

### Example 1: New Feature (Full Flow)
```bash
/workflow "Student progress tracking dashboard"

# Output:
# ✅ Phase 0: Spec created (specs/015-student-progress-dashboard)
# ⚡ Auto-compacted (preserved spec decisions)
# ✅ Phase 0.5: Clarifications resolved
# ⚡ Auto-compacted (preserved clarifications)
# ✅ Phase 1: Plan generated (research + architecture)
# ⚡ Auto-compacted (preserved research decisions)
# ✅ Phase 2: Tasks created (28 tasks)
# ⚡ Auto-compacted (preserved task breakdown)
# ✅ Phase 3: Analysis passed (0 critical issues)
# ⚡ Auto-compacted (preserved analysis findings)
# ✅ Phase 4: Implementation complete (28/28 tasks)
# ⚡ Auto-compacted (preserved last 20 checkpoints)
# ✅ Phase 5: Optimization passed (0 blockers)
# ⚡ Auto-compacted (preserved code review)
# 🎨 MANUAL GATE: Run /preview
```

### Example 2: Resume After Preview
```bash
# After /preview completed
/workflow continue

# Output:
# Resuming from: Phase 6 (Ship to Staging)
# ✅ PR created: #123
# ⏳ Waiting for CI...
# ✅ Auto-merged to staging
# 🧪 MANUAL GATE: Run /validate-staging
```

### Example 3: Resume After Fixes
```bash
# After fixing critical issues from /analyze
/workflow continue

# Output:
# Resuming from: Phase 4 (Implementation)
# ✅ Tasks completed: 28/28
# ✅ Optimization complete
# 🎨 MANUAL GATE: Run /preview
```

## RETURN

### On Complete
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 WORKFLOW COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: [feature-name]
Shipped: ✅ Production

Timeline:
- Spec created: [date]
- Implementation: [N days]
- Staging: [date]
- Production: [date]

Metrics:
- Tasks completed: N/N
- Auto-compactions: N phases
- Auto-fixes applied: N

Deployments:
- Staging: https://staging.cfipros.com
- Production: https://cfipros.com

Release: v[version] ([GitHub release URL])
Roadmap: Updated (moved to 'Shipped')
```

### On Pause (Manual Gate)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏸️  WORKFLOW PAUSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: [phase-name] (Manual Gate)

Action required:
- [specific validation steps]

Next: /workflow continue (after validation complete)
```

### On Error
```
❌ WORKFLOW ERROR

Phase: [phase-name]
Error: [error-description]

Options:
  A) Debug: /debug
  B) Fix: [specific fix instructions]
  C) Skip: /workflow continue --skip-phase
  D) Abort: Exit workflow

Logs: specs/NNN-*/NOTES.md
```


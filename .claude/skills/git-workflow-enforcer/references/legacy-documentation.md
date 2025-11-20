---
name: git-workflow-enforcer
description: Enforce git commits after every phase and task to enable rollback and prevent lost work. Auto-trigger when completing phases, tasks, or when detecting uncommitted changes. Verify commits happened, check branch safety, enforce clean working tree. Block completion if changes not committed.
allowed-tools: Bash, Read
---

# Git Workflow Enforcer: Commit Everything

**Purpose**: Ensure every meaningful change is committed for rollback safety and clean history.

**Philosophy**: "Commit early, commit often. Every phase, every task, every meaningful change gets a commit."

---

## The Problem

**Uncommitted changes cause lost work:**

**Scenario 1: Phase creates artifacts but doesn't commit**
```bash
# /specify creates spec.md
# Working tree: spec.md (untracked)
# User runs /plan
# /plan fails due to error
# User runs: git restore .
# Result: ❌ spec.md DELETED (work lost)
```

**Scenario 2: Task implemented but not committed**
```bash
# Agent implements T001 (creates Message model)
# Working tree: api/app/models/message.py (modified)
# Tests fail on T002
# Agent runs: git restore .  (auto-rollback)
# Result: ❌ T001 implementation DELETED (no rollback point)
```

**Scenario 3: Multiple tasks bundled in one commit**
```bash
# Agent implements T001, T002, T003
# All committed together: git commit -m "implement tasks"
# T002 has bug discovered later
# Want to revert T002 only
# Result: ❌ Can't revert T002 without reverting T001 and T003
```

---

## The Solution: Mandatory Commits

**After every meaningful change, commit:**

1. **Phase Artifacts**: spec.md, plan.md, tasks.md, etc.
2. **Task Implementation**: After each task (RED, GREEN, REFACTOR)
3. **Batch Implementation**: After 3-5 tasks in parallel
4. **Reports**: analysis-report.md, optimization-report.md, etc.
5. **Documentation**: release-notes.md, README updates, etc.

---

## When to Trigger

Auto-invoke this Skill when detecting:

**Phase Completion:**
- "Phase N complete"
- "/specify complete"
- "/plan complete"
- "/tasks complete"
- "analysis complete"
- "optimization complete"
- "preview ready"

**Task Completion:**
- "mark task complete"
- "T001 complete"
- "update task status"
- "task-tracker mark-done"

**Commit Keywords:**
- "commit changes"
- "save progress"
- "git commit"
- "ready to commit"

**Change Detection:**
- Files created/modified but not committed
- Working tree dirty
- Staging area has changes

---

## Pre-Completion Checklist

### Step 1: Detect Uncommitted Changes

```bash
# Check if working tree has uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  **UNCOMMITTED CHANGES DETECTED**"
  echo ""
  git status --short
  echo ""

  # This is a problem if completing a phase/task
  return 1
fi

echo "✅ Working tree clean"
```

### Step 2: Verify Recent Commit

**For phase completion:**

```bash
# Check if last commit is recent (within last 5 minutes)
LAST_COMMIT_TIME=$(git log -1 --format=%ct)
CURRENT_TIME=$(date +%s)
TIME_DIFF=$((CURRENT_TIME - LAST_COMMIT_TIME))

if [ $TIME_DIFF -gt 300 ]; then
  echo "⚠️  **NO RECENT COMMIT**"
  echo ""
  echo "Last commit: $(git log -1 --format='%ar')"
  echo "Phase artifacts created but not committed."
  echo ""
  return 1
fi

echo "✅ Recent commit found ($(git log -1 --format='%ar'))"
```

**For task completion:**

```bash
# Verify commit hash was provided to task-tracker
COMMIT_HASH="$1"

if [ -z "$COMMIT_HASH" ] || [ "$COMMIT_HASH" = "HEAD" ]; then
  echo "❌ **COMMIT HASH MISSING**"
  echo ""
  echo "Task completion requires commit hash."
  echo ""
  echo "Did you commit the changes?"
  echo "  git add ."
  echo "  git commit -m '...'"
  echo "  git rev-parse --short HEAD"
  echo ""
  return 1
fi

# Verify commit hash exists
if ! git rev-parse --verify "$COMMIT_HASH" >/dev/null 2>&1; then
  echo "❌ **INVALID COMMIT HASH**"
  echo ""
  echo "Commit $COMMIT_HASH not found in git history."
  echo ""
  return 1
fi

echo "✅ Commit verified: $COMMIT_HASH"
```

### Step 3: Check Branch Safety

```bash
# Warn if implementing on main/master (should be on feature branch)
CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
  echo "⚠️  **WORKING ON PROTECTED BRANCH**"
  echo ""
  echo "Current branch: $CURRENT_BRANCH"
  echo ""
  echo "You should be on a feature branch, not main/master."
  echo ""
  echo "Recommended:"
  echo "  git checkout -b feat/feature-name"
  echo ""
  read -p "Continue anyway? (yes/no): " response
  [ "$response" != "yes" ] && return 1
fi

echo "✅ On feature branch: $CURRENT_BRANCH"
```

---

## Commit Guidelines by Phase

### Phase 0: Specification (/specify)

**What to commit:**
- `specs/$SLUG/spec.md`
- `specs/$SLUG/visuals/` (if created)
- `specs/$SLUG/NOTES.md` (if initialized)

**Commit message:**
```bash
git add specs/$SLUG/
git commit -m "docs(spec): create specification for $SLUG

- Feature: $FEATURE_DESCRIPTION
- Acceptance criteria: $CRITERIA_COUNT
- User stories: $STORY_COUNT
- Technical requirements specified"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(spec)"
```

---

### Phase 0.5: Clarification (/clarify)

**What to commit:**
- `specs/$SLUG/spec.md` (updated with clarifications)

**Commit message:**
```bash
git add specs/$SLUG/spec.md
git commit -m "docs(clarify): resolve $QUESTION_COUNT clarifications for $SLUG

Clarifications:
$(list_clarifications | head -5)"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(clarify)"
```

---

### Phase 1: Planning (/plan)

**What to commit:**
- `specs/$SLUG/plan.md`
- `specs/$SLUG/research.md`

**Commit message:**
```bash
git add specs/$SLUG/plan.md specs/$SLUG/research.md
git commit -m "docs(plan): create implementation plan for $SLUG

- Architecture: $ARCHITECTURE_CHOICE
- REUSE: $REUSE_COUNT files
- Complexity: $COMPLEXITY_SCORE
- Estimated time: $TIME_ESTIMATE"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(plan)"
```

---

### Phase 2: Task Breakdown (/tasks)

**What to commit:**
- `specs/$SLUG/tasks.md`
- `specs/$SLUG/checklists/` (if created)

**Commit message:**
```bash
git add specs/$SLUG/tasks.md specs/$SLUG/checklists/
git commit -m "docs(tasks): create task breakdown for $SLUG

- Total tasks: $TASK_COUNT
- Format: $TASK_FORMAT (TDD/User Story)
- Breakdown: P1=$P1_COUNT, P2=$P2_COUNT, P3=$P3_COUNT"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(tasks)"
```

---

### Phase 3: Analysis (/analyze)

**What to commit:**
- `specs/$SLUG/analysis-report.md`

**Commit message:**
```bash
git add specs/$SLUG/analysis-report.md
git commit -m "docs(analyze): create cross-artifact analysis for $SLUG

- Consistency checks: $CHECK_COUNT
- Issues found: $ISSUE_COUNT
- Critical blockers: $BLOCKER_COUNT"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(analyze)"
```

---

### Phase 4: Implementation (/implement)

**Per-Task Commits (TDD):**

**RED Phase:**
```bash
git add api/tests/test_message.py
git commit -m "test(red): T015 write failing test for Message model

Test: test_message_creation
Expected: FAILED (ImportError: No module named 'app.models.message')
Evidence: pytest output showing import failure"
```

**GREEN Phase:**
```bash
git add api/app/models/message.py api/tests/test_message.py
git commit -m "feat(green): T015 implement Message model to pass test

Implementation: SQLAlchemy model with validation
Tests: 26/26 passing
Coverage: 93% (+1%)"
```

**REFACTOR Phase:**
```bash
git add api/app/models/message.py
git commit -m "refactor: T015 improve Message model with base class

Improvements:
- Extract to TimestampedModel
- Add __repr__ method
- Improve type hints

Tests: 26/26 passing (still green)
Coverage: 93% (maintained)"
```

**Batch Commits (User Story):**
```bash
git add .
git commit -m "feat(batch): implement T001-T005 for US1 (P1)

Tasks completed:
- T001: Create Message model ✅
- T002: Create MessageForm component ✅
- T003: Add messages table migration ✅
- T004: Create /messages endpoint ✅
- T005: Add message tests ✅

Tests: All passing (backend: 26/26, frontend: 12/12)
Coverage: Backend 93%, Frontend 88%"
```

**MVP Commit:**
```bash
git add .
git commit -m "feat(mvp): complete P1 (MVP) implementation for $SLUG

MVP tasks: $P1_COMPLETE/$P1_TOTAL ✅
All acceptance criteria met
Tests: All passing
Coverage: Backend $BACKEND_COV%, Frontend $FRONTEND_COV%

Deferred to roadmap:
- P2 enhancements: $P2_COUNT tasks
- P3 features: $P3_COUNT tasks"
```

---

### Phase 5: Optimization (/optimize)

**What to commit:**
- `specs/$SLUG/optimization-report.md`
- `specs/$SLUG/code-review-report.md`
- Any code improvements made

**Commit message:**
```bash
git add specs/$SLUG/optimization-report.md
git add specs/$SLUG/code-review-report.md
git add .  # Include code improvements

git commit -m "docs(optimize): complete optimization review for $SLUG

- Performance: $PERF_SCORE/100 (all endpoints <500ms)
- Security: $SECURITY_ISSUES issues fixed
- Code quality: $QUALITY_SCORE/100
- Accessibility: $A11Y_ISSUES violations fixed
- Improvements: $IMPROVEMENT_COUNT applied"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(optimize)"
```

---

### Phase 6: Preview (/preview)

**What to commit:**
- `specs/$SLUG/release-notes.md`

**Commit message:**
```bash
git add specs/$SLUG/release-notes.md
git commit -m "docs(preview): create release notes for $SLUG

Version: v$VERSION
Changes: $CHANGE_COUNT
Breaking changes: $BREAKING_COUNT
Manual testing: Ready for validation"
```

**Verification:**
```bash
git log -1 --oneline | grep "docs(preview)"
```

---

## Blocking Scenarios

### Block 1: Phase Complete Without Commit

**Detection:**
```bash
# Phase agent returns "complete" but no recent commit
if phase_complete && ! recent_commit_exists; then
  echo "❌ BLOCKED"
fi
```

**Response:**
```markdown
❌ **PHASE COMPLETION BLOCKED: No Commit**

**Issue:**
Phase "$PHASE_NAME" completed but changes not committed.

**Uncommitted files:**
{GIT_STATUS_OUTPUT}

**Required:**
Commit phase artifacts before proceeding:

```bash
git add specs/$SLUG/
git commit -m "docs($PHASE): create $ARTIFACTS for $SLUG"
```

**Then verify:**
```bash
git log -1 --oneline
```

Phase blocked until changes committed.
```

### Block 2: Task Complete Without Commit Hash

**Detection:**
```bash
# task-tracker called without CommitHash
if task_complete && commit_hash_missing; then
  echo "❌ BLOCKED"
fi
```

**Response:**
```markdown
❌ **TASK COMPLETION BLOCKED: No Commit Hash**

**Issue:**
Task $TASK_ID marked complete but no commit hash provided.

**Required:**
1. Commit your changes:
   ```bash
   git add .
   git commit -m "feat(green): $TASK_ID implement to pass test"
   ```

2. Get commit hash:
   ```bash
   git rev-parse --short HEAD
   ```

3. Provide hash to task-tracker:
   ```bash
   .spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
     -TaskId "$TASK_ID" \
     -Notes "..." \
     -Evidence "..." \
     -Coverage "..." \
     -CommitHash "$(git rev-parse --short HEAD)" \
     -FeatureDir "$FEATURE_DIR"
   ```

Task blocked until committed.
```

### Block 3: Dirty Working Tree Before Phase

**Detection:**
```bash
# Starting new phase but working tree dirty
if phase_starting && working_tree_dirty; then
  echo "⚠️  WARNING"
fi
```

**Response:**
```markdown
⚠️  **WARNING: Uncommitted Changes**

**Issue:**
Starting phase "$NEXT_PHASE" but working tree has uncommitted changes.

**Uncommitted files:**
{GIT_STATUS_OUTPUT}

**Options:**
1. Commit changes from previous phase:
   ```bash
   git add .
   git commit -m "docs($PREV_PHASE): complete phase artifacts"
   ```

2. Stash changes (if experimental):
   ```bash
   git stash push -m "WIP: $PREV_PHASE artifacts"
   ```

3. Discard changes (DANGER - permanent loss):
   ```bash
   git restore .
   ```

Recommended: Option 1 (commit)

Proceed anyway? (yes/no)
```

### Block 4: Working on Main Branch

**Detection:**
```bash
# Implementing on main/master instead of feature branch
if on_main_branch && ! deployment_phase; then
  echo "⚠️  WARNING"
fi
```

**Response:**
```markdown
⚠️  **WARNING: Working on Protected Branch**

**Issue:**
Current branch: main

You should be on a feature branch for development.

**Recommended:**
Create feature branch:
```bash
git checkout -b feat/$SLUG
```

**If already have commits:**
```bash
# Save commits to new branch
git checkout -b feat/$SLUG
git checkout main
git reset --hard origin/main
```

Proceed on main branch? (yes/no)
```

---

## Commit Message Templates

### Conventional Commits Format

**Structure:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding tests
- `refactor`: Code restructure
- `perf`: Performance improvement
- `chore`: Maintenance

**Scopes:**
- `spec`: Specification
- `plan`: Planning
- `tasks`: Task breakdown
- `analyze`: Analysis
- `implement`: Implementation
- `optimize`: Optimization
- `preview`: Preview/release notes
- `red`: RED phase (TDD)
- `green`: GREEN phase (TDD)
- `batch`: Batch implementation

### Examples

**Phase commits:**
```bash
docs(spec): create specification for user-messaging
docs(plan): create implementation plan for user-messaging
docs(tasks): create task breakdown for user-messaging (25 tasks)
docs(analyze): create cross-artifact analysis for user-messaging
docs(optimize): complete optimization review for user-messaging
docs(preview): create release notes for user-messaging v1.2.0
```

**Task commits:**
```bash
test(red): T015 write failing test for Message model
feat(green): T015 implement Message model to pass test
refactor: T015 improve Message model with base class
feat(batch): implement T001-T005 for US1 (P1)
feat(mvp): complete P1 implementation for user-messaging
```

**Fix commits:**
```bash
fix: T015 correct Message model validation
fix(security): add input sanitization to MessageForm
fix(perf): optimize message query with eager loading
```

---

## Rollback Procedures

### Rollback Last Uncommitted Changes

```bash
# Discard all uncommitted changes
git restore .

# OR discard specific file
git restore api/app/models/message.py
```

### Rollback Last Commit

```bash
# Keep changes in working tree (can re-commit)
git reset --soft HEAD~1

# Discard changes permanently (DANGER)
git reset --hard HEAD~1
```

### Rollback Specific Task

```bash
# Find commit for task
git log --oneline --grep="T015"

# Revert that commit (creates new commit)
git revert <commit-hash>

# OR reset to before that commit (rewrites history)
git reset --hard <commit-before-task>
```

### Rollback Entire Phase

```bash
# Find commit for phase
git log --oneline --grep="docs(plan)"

# Reset to before phase
git reset --hard <commit-before-phase>
```

---

## Integration with Spec-Flow Workflow

### Pre-Phase Verification

**At start of EVERY command:**

1. Check working tree clean (enforce previous phase committed)
2. Verify on feature branch (warn if on main/master)
3. Display last commit (confirm clean state)

### Post-Phase Enforcement

**At end of EVERY command:**

1. Check for uncommitted files
2. Block completion if changes not committed
3. Suggest commit message template
4. Verify commit after user commits

### Per-Task Enforcement

**During /implement:**

1. Require CommitHash parameter in task-tracker
2. Verify commit exists before marking task complete
3. Block task completion if no commit
4. Suggest commit message based on TDD phase

---

## Examples

### Example 1: Phase Completed Without Commit

**User runs:** `/specify "User messaging system"`

**Specify command creates:** `specs/user-messaging/spec.md`

**Git Workflow Enforcer triggers:**
```markdown
⚠️  **UNCOMMITTED CHANGES DETECTED**

specs/user-messaging/spec.md (new file)

Phase "specify" completed but changes not committed.

**Commit changes:**
```bash
git add specs/user-messaging/
git commit -m "docs(spec): create specification for user-messaging

- Feature: User messaging system
- Acceptance criteria: 15 defined
- User stories: 3 outlined
- Technical requirements specified"
```

**Verify:**
```bash
git log -1 --oneline
```

Expected: Latest commit shows "docs(spec): create specification"
```

### Example 2: Task Completed Without Commit

**Agent implements:** T015 - Create Message model

**Agent calls task-tracker:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Created Message model" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% (+1%)" \
  -CommitHash "" \  # EMPTY!
  -FeatureDir "specs/user-messaging"
```

**Git Workflow Enforcer blocks:**
```markdown
❌ **TASK COMPLETION BLOCKED: No Commit Hash**

Task T015 marked complete but no commit hash provided.

**Did you commit?**
```bash
git add api/app/models/message.py api/tests/test_message.py
git commit -m "feat(green): T015 implement Message model to pass test

Implementation: SQLAlchemy model with validation
Tests: 26/26 passing
Coverage: 93% (+1%)"
```

**Get commit hash:**
```bash
git rev-parse --short HEAD
# Output: a1b2c3d
```

**Re-run task-tracker with hash:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Created Message model" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% (+1%)" \
  -CommitHash "a1b2c3d" \  # PROVIDED!
  -FeatureDir "specs/user-messaging"
```

Task blocked until commit hash provided.
```

### Example 3: Starting Phase with Dirty Tree

**User runs:** `/plan` (after /specify)

**But spec.md not committed yet**

**Git Workflow Enforcer warns:**
```markdown
⚠️  **WARNING: Uncommitted Changes**

Starting phase "plan" but working tree has uncommitted changes:

specs/user-messaging/spec.md (modified)

Previous phase (/specify) did not commit changes.

**Recommended: Commit changes from /specify first**
```bash
git add specs/user-messaging/spec.md
git commit -m "docs(spec): create specification for user-messaging"
```

Proceed without committing? (yes/no)
```

---

## Git Workflow Enforcer Rules

1. **Every phase must commit** - No phase completion without commit
2. **Every task must commit** - No task completion without commit hash
3. **Clean working tree between phases** - Warn if dirty tree when starting new phase
4. **Feature branch required** - Warn if on main/master (except deployment)
5. **Commit message conventions** - Use conventional commits format
6. **Granular commits** - One commit per task (TDD) or batch (User Story)
7. **Rollback safety** - Every commit is a rollback point
8. **Evidence required** - Commit message includes what changed and why

---

## Constraints

- **Bash access**: Required to run git commands
- **Read access**: Required to check git status
- **Fast checks**: Verification should complete in <5 seconds
- **Non-destructive**: This Skill only checks/warns, doesn't modify files
- **User control**: Allow proceed after warning (except hard blocks)

---

## Return Format

**Phase Completion Check (Success):**
```markdown
✅ **GIT WORKFLOW VERIFIED**

**Recent commit:**
a1b2c3d docs(spec): create specification for user-messaging (2 minutes ago)

**Working tree:** Clean
**Branch:** feat/user-messaging
**Rollback point:** Available

Phase completion allowed.
```

**Phase Completion Check (Blocked):**
```markdown
❌ **GIT WORKFLOW VIOLATION: No Commit**

**Issue:**
Phase "specify" completed but changes not committed.

**Uncommitted files:**
  specs/user-messaging/spec.md (new)

**Required:**
Commit changes before proceeding:
```bash
git add specs/user-messaging/
git commit -m "docs(spec): create specification for user-messaging"
```

Phase blocked until changes committed.
```

**Task Completion Check (Success):**
```markdown
✅ **COMMIT VERIFIED: T015**

**Commit:** a1b2c3d (3 minutes ago)
**Message:** feat(green): T015 implement Message model
**Files:** 2 files changed (message.py, test_message.py)
**Rollback:** Available (git revert a1b2c3d)

Task completion allowed.
```

**Task Completion Check (Blocked):**
```markdown
❌ **TASK COMPLETION BLOCKED: No Commit**

**Issue:**
Task T015 completed but no commit hash provided.

**Required:**
1. Commit changes:
   git add .
   git commit -m "feat(green): T015 implement to pass test"

2. Get hash:
   git rev-parse --short HEAD

3. Provide to task-tracker:
   -CommitHash "$(git rev-parse --short HEAD)"

Task blocked until committed.
```

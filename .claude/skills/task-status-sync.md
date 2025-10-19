---
name: task-status-sync
description: Prevent manual edits to NOTES.md and tasks.md. Enforce task-tracker usage for all task status updates to maintain atomic synchronization. Auto-trigger when detecting attempts to edit task files, mark tasks complete, or update task status. Block direct edits and suggest task-tracker commands instead.
allowed-tools: Read, Bash
---

# Task Status Sync: Prevent Manual Edits

**Purpose**: Enforce task-tracker usage to prevent desynchronization between tasks.md and NOTES.md.

**Philosophy**: "One source of truth, one way to update it. Use task-tracker for all task status changes."

---

## The Problem

**Manual edits cause desync:**

**Scenario 1: Manual NOTES.md edit**
```markdown
# Agent manually adds to NOTES.md:
✅ T001: Create Message model
  - Evidence: pytest passing
```

**Result:**
- ✅ NOTES.md shows T001 complete
- ❌ tasks.md checkbox still unchecked `- [ ] T001 [RED] Write failing test`
- ❌ Desync: task-tracker thinks T001 incomplete
- ❌ Future /implement runs will re-execute T001

**Scenario 2: Manual tasks.md edit**
```markdown
# Agent manually checks checkbox:
- [x] T001 [RED] Write failing test
```

**Result:**
- ✅ tasks.md shows T001 complete
- ❌ NOTES.md has no completion marker or evidence
- ❌ Desync: No record of what was done, how it was tested
- ❌ Loss of evidence trail (coverage, commit hash)

---

## The Solution: task-tracker

**Atomic updates to both files:**

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T001" \
  -Notes "Created Message model with validation" \
  -Evidence "pytest: 25/25 passing" \
  -Coverage "92% line (+8%)" \
  -CommitHash "a1b2c3d" \
  -FeatureDir "specs/user-messaging"
```

**Result:**
- ✅ tasks.md checkbox updated: `- [x] T001 [RED] Write failing test`
- ✅ NOTES.md completion marker added:
  ```markdown
  ✅ T001 [RED]: Write failing test
    - Evidence: pytest: 25/25 passing ✓
    - Coverage: 92% (+8%)
    - Committed: a1b2c3d
  ```
- ✅ Both files synchronized atomically
- ✅ Evidence preserved for audit trail

---

## When to Trigger

Auto-invoke this Skill when detecting:

**Edit Intentions:**
- "edit NOTES.md"
- "update tasks.md"
- "add to NOTES.md"
- "check off task"
- "mark task complete"

**File Edit Attempts:**
- Edit tool targeting NOTES.md
- Edit tool targeting tasks.md
- Write tool targeting NOTES.md
- Write tool targeting tasks.md

**Status Update Keywords:**
- "mark T001 done"
- "update task status"
- "record task completion"
- "add task evidence"

---

## Pre-Edit Checklist

### Step 1: Detect Manual Edit Attempt

```bash
# Check if Edit/Write tool is targeting task files
if [[ "$FILE_PATH" =~ NOTES\.md$ ]] || [[ "$FILE_PATH" =~ tasks\.md$ ]]; then
  echo "⚠️  MANUAL EDIT DETECTED"
  echo "   File: $FILE_PATH"
  echo "   Use task-tracker instead to maintain sync"
fi
```

### Step 2: Identify Intent

**What is the agent trying to do?**

**Intent A: Mark task complete**
```markdown
# Agent wants to add to NOTES.md:
✅ T015 [GREEN]: Implement Message model to pass test
```

**Redirect to task-tracker:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implement Message model to pass test" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "$FEATURE_DIR"
```

**Intent B: Mark task failed**
```markdown
# Agent wants to add to NOTES.md:
⚠️  T015: Failed - test timeout
```

**Redirect to task-tracker:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "T015" \
  -ErrorMessage "Test timeout after 30s (API not responding)" \
  -FeatureDir "$FEATURE_DIR"
```

**Intent C: Add notes to existing task**
```markdown
# Agent wants to append to NOTES.md:
  - Additional context: Used async SQLAlchemy pattern
```

**Allow but warn:**
```markdown
⚠️  **PREFER task-tracker FOR UPDATES**

Adding notes to existing completed task is allowed, but prefer task-tracker for new completions.

If marking a NEW task complete, use:
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes ...
```

### Step 3: Verify task-tracker Exists

```bash
TASK_TRACKER=".spec-flow/scripts/bash/task-tracker.sh"

if [ ! -f "$TASK_TRACKER" ]; then
  echo "❌ task-tracker not found: $TASK_TRACKER"
  echo "   Cannot enforce atomic updates without task-tracker"
  echo "   Fallback: Allow manual edit (not ideal)"
  exit 0  # Allow edit if task-tracker missing
fi

echo "✅ task-tracker available"
```

### Step 4: Block or Redirect

**Block if:**
- Trying to mark task complete via manual NOTES.md edit
- Trying to check off task via manual tasks.md edit
- task-tracker is available

**Allow if:**
- Adding notes to existing completed task
- task-tracker not available (fallback mode)
- User explicitly overrides (after warning)

---

## Blocking Scenarios

### Scenario 1: Manual NOTES.md Completion

**Detection:**
```bash
# Check if Edit/Write is adding completion marker to NOTES.md
if [[ "$FILE_PATH" =~ NOTES\.md$ ]] && [[ "$NEW_CONTENT" =~ ✅.*T[0-9]{3} ]]; then
  echo "❌ MANUAL TASK COMPLETION DETECTED"
  # Block and suggest task-tracker
fi
```

**Response:**
```markdown
❌ **MANUAL TASK COMPLETION BLOCKED**

**Issue:**
You're trying to manually add task completion to NOTES.md:
```
✅ T015: Implement Message model to pass test
```

**Problem:**
Manual edits cause desync between NOTES.md and tasks.md.

**Solution:**
Use task-tracker for atomic updates:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implement Message model to pass test" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "specs/user-messaging"
```

This updates BOTH tasks.md checkbox AND NOTES.md completion marker atomically.

**Manual edit blocked. Use task-tracker command above.**
```

### Scenario 2: Manual tasks.md Checkbox

**Detection:**
```bash
# Check if Edit is changing checkbox state in tasks.md
if [[ "$FILE_PATH" =~ tasks\.md$ ]] && [[ "$NEW_CONTENT" =~ - \[x\] T[0-9]{3} ]]; then
  echo "❌ MANUAL CHECKBOX EDIT DETECTED"
  # Block and suggest task-tracker
fi
```

**Response:**
```markdown
❌ **MANUAL CHECKBOX EDIT BLOCKED**

**Issue:**
You're trying to manually check off task in tasks.md:
```
- [x] T015 [GREEN→T014] Implement Message model
```

**Problem:**
Checking the box directly doesn't update NOTES.md or add evidence.

**Solution:**
Use task-tracker for atomic updates:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implement Message model to pass test" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "specs/user-messaging"
```

This checks the tasks.md box AND adds completion marker with evidence to NOTES.md.

**Manual edit blocked. Use task-tracker command above.**
```

### Scenario 3: Missing Evidence in Manual Edit

**Detection:**
```bash
# Check if completion marker lacks evidence
if [[ "$NEW_CONTENT" =~ ✅.*T[0-9]{3} ]] && ! [[ "$NEW_CONTENT" =~ Evidence: ]]; then
  echo "⚠️  COMPLETION WITHOUT EVIDENCE"
  # Warn and suggest task-tracker
fi
```

**Response:**
```markdown
⚠️  **INCOMPLETE TASK COMPLETION**

**Issue:**
You're marking task complete without evidence:
```
✅ T015: Implement Message model
```

**Missing:**
- Evidence (test results, verification)
- Coverage (line/branch percentage)
- Commit hash (traceability)

**Solution:**
Use task-tracker to include all required fields:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implement Message model to pass test" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "specs/user-messaging"
```

**Prefer task-tracker for complete audit trail.**
```

---

## Allowed Scenarios (Non-Blocking)

### Scenario 1: Appending Notes to Completed Task

**Allowed:**
```bash
# Adding context to existing completed task
# NOTES.md already has:
# ✅ T015 [GREEN]: Implement Message model
#   - Evidence: pytest: 26/26 passing ✓
#   - Coverage: 93% (+1%)
#   - Committed: a1b2c3d

# Agent adds:
#   - Additional: Used TimestampedModel base class for created_at/updated_at
```

**Response:**
```markdown
✅ **APPEND TO COMPLETED TASK ALLOWED**

Adding supplementary notes to already-completed task T015.

**Note:** For NEW task completions, prefer task-tracker:
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes ...

Proceeding with manual append.
```

### Scenario 2: Creating NOTES.md Initially

**Allowed:**
```bash
# Creating NOTES.md for first time
if [ ! -f "$FEATURE_DIR/NOTES.md" ]; then
  echo "✅ Creating initial NOTES.md - allowed"
fi
```

**Response:**
```markdown
✅ **INITIAL NOTES.md CREATION ALLOWED**

Creating NOTES.md for the first time.

**Going forward:**
- Use task-tracker for all task completions
- Use task-tracker for all task failures
- Manual edits only for supplementary notes

Proceeding with file creation.
```

### Scenario 3: Fixing Typos in NOTES.md

**Allowed:**
```bash
# Fixing typo in existing note
# OLD: "pytest: 26/26 passing (tyop)"
# NEW: "pytest: 26/26 passing (typo fixed)"
```

**Response:**
```markdown
✅ **TYPO FIX ALLOWED**

Fixing typo in existing NOTES.md content.

**Reminder:**
For NEW task completions, use task-tracker to avoid manual edits.

Proceeding with typo fix.
```

---

## task-tracker Commands Reference

### Mark Task Complete (with evidence)

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "One-line summary of what was done" \
  -Evidence "pytest: NN/NN passing" or "jest: NN/NN passing" \
  -Coverage "NN% line, NN% branch (+ΔΔ%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "$FEATURE_DIR"
```

**Updates:**
- tasks.md: Checks off `- [x] T015 ...`
- NOTES.md: Adds completion marker with evidence
  ```markdown
  ✅ T015 [PHASE]: Notes
    - Evidence: pytest: NN/NN passing ✓
    - Coverage: NN% (+ΔΔ%)
    - Committed: hash
  ```

### Mark Task Failed (with error)

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId "T015" \
  -ErrorMessage "Detailed error description (test output, exception)" \
  -FeatureDir "$FEATURE_DIR"
```

**Updates:**
- tasks.md: Leaves checkbox unchecked `- [ ] T015 ...`
- NOTES.md: Adds failure marker
  ```markdown
  ⚠️  T015 [PHASE]: Failed
    - Error: Detailed error description
    - Rollback: Changes reverted
  ```
- error-log.md: Appends error for tracking

### Query Task Status (read-only)

```bash
.spec-flow/scripts/bash/task-tracker.sh status \
  -FeatureDir "$FEATURE_DIR" \
  -Json
```

**Returns:**
```json
{
  "CompletedTasks": [
    {"Id": "T001", "Phase": "RED", "Evidence": "pytest: 25/25"},
    {"Id": "T014", "Phase": "GREEN", "Evidence": "pytest: 26/26"}
  ],
  "PendingTasks": [
    {"Id": "T015", "Phase": "REFACTOR"}
  ],
  "FailedTasks": [
    {"Id": "T016", "Error": "Test timeout"}
  ]
}
```

---

## Integration with Spec-Flow Workflow

### During /implement Phase

**When agents complete tasks:**

1. **Block manual NOTES.md edits** for task completions
2. **Redirect to task-tracker** with proper command
3. **Verify task-tracker exists** before blocking
4. **Allow fallback** to manual edit if task-tracker missing (not ideal)
5. **Preserve evidence** by enforcing Evidence/Coverage/CommitHash fields

**Result:** Zero desync, complete audit trail, atomic updates

### After Task Completion

**Agent workflow:**

```bash
# 1. Implement feature
git add .
git commit -m "feat(green): T015 implement Message model"

# 2. Run tests
pytest api/tests/ -v
# Output: 26/26 passing

# 3. Get coverage
pytest --cov=app --cov-report=term
# Output: 93% line coverage (+1% from baseline)

# 4. Update task status (ATOMIC)
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implement Message model to pass test" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "$(git rev-parse --short HEAD)" \
  -FeatureDir "$FEATURE_DIR"

# 5. Verify sync
grep "T015" "$FEATURE_DIR/tasks.md"  # [x] checkbox
grep "T015" "$FEATURE_DIR/NOTES.md"  # ✅ completion marker
```

---

## Error Prevention Examples

### Example 1: Prevent Desync (Backend)

**Agent Intent:**
```markdown
I'll add this to NOTES.md:
✅ T015: Implemented Message model
```

**Task Status Sync Response:**
```markdown
❌ **BLOCKED: Use task-tracker**

Detected manual NOTES.md edit for task completion.

**Instead, run:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T015" \
  -Notes "Implemented Message model with SQLAlchemy" \
  -Evidence "pytest: 26/26 passing" \
  -Coverage "93% line (+1%)" \
  -CommitHash "a1b2c3d" \
  -FeatureDir "specs/user-messaging"
```

This updates BOTH tasks.md and NOTES.md atomically.
```

### Example 2: Prevent Evidence Loss (Frontend)

**Agent Intent:**
```markdown
I'll check off the task in tasks.md:
- [x] T022 [P] Create MessageList component
```

**Task Status Sync Response:**
```markdown
❌ **BLOCKED: Evidence Required**

Checking task box without evidence loses audit trail.

**Instead, run:**
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId "T022" \
  -Notes "Created MessageList component with pagination" \
  -Evidence "jest: 12/12 passing, a11y: 0 violations" \
  -Coverage "88% line (+6%)" \
  -CommitHash "d4e5f6g" \
  -FeatureDir "specs/user-messaging"
```

This preserves test results, coverage, and commit traceability.
```

### Example 3: Allow Supplementary Notes

**Agent Intent:**
```markdown
I'll add to NOTES.md:
✅ T015 [GREEN]: Implement Message model
  - Evidence: pytest: 26/26 passing ✓
  - Coverage: 93% (+1%)
  - Committed: a1b2c3d
  - Note: Also added soft-delete support with deleted_at column
```

**Task Status Sync Response:**
```markdown
✅ **ALLOWED: Supplementary Notes**

Appending additional context to completed task T015.

Task already marked complete via task-tracker. Adding supplementary notes is fine.

**Reminder:** For NEW completions, use task-tracker.

Proceeding with manual append.
```

---

## Task Status Sync Rules

1. **Always use task-tracker for completions** - Block manual NOTES.md completion markers
2. **Always use task-tracker for failures** - Block manual error notes
3. **Require evidence** - Evidence, Coverage, CommitHash must be provided
4. **Allow supplementary notes** - Appending to existing completions is okay
5. **Fallback to manual** - If task-tracker missing, allow manual (warn user)
6. **Verify sync** - After update, verify both files match
7. **Audit trail** - Preserve evidence for all completions

---

## Constraints

- **Read access**: Required to check NOTES.md and tasks.md
- **Bash access**: Required to run task-tracker commands
- **No file edits**: This Skill blocks edits, doesn't make them
- **Fast detection**: Should catch manual edits immediately (<1 second)
- **Fallback mode**: Allow manual edits if task-tracker unavailable

---

## Return Format

**Manual Edit Blocked:**
```markdown
❌ **MANUAL TASK STATUS EDIT BLOCKED**

**Issue:**
{DESCRIPTION_OF_MANUAL_EDIT_ATTEMPT}

**Problem:**
{WHY_MANUAL_EDIT_CAUSES_DESYNC}

**Solution:**
Use task-tracker for atomic updates:

```bash
{TASK_TRACKER_COMMAND}
```

**Manual edit blocked. Use task-tracker command above.**
```

**Manual Edit Allowed (with warning):**
```markdown
✅ **MANUAL EDIT ALLOWED (SUPPLEMENTARY)**

{DESCRIPTION_OF_ALLOWED_EDIT}

**Reminder:**
For NEW task completions, use task-tracker to avoid manual edits.

Proceeding with manual edit.
```

**task-tracker Unavailable:**
```markdown
⚠️  **TASK-TRACKER UNAVAILABLE**

task-tracker not found: .spec-flow/scripts/bash/task-tracker.sh

**Fallback:**
Allowing manual edit, but this may cause desync.

**Recommendation:**
Install task-tracker for atomic updates:
- Ensures tasks.md and NOTES.md stay synchronized
- Preserves evidence trail (coverage, commit hash)

Proceeding with manual edit (not ideal).
```

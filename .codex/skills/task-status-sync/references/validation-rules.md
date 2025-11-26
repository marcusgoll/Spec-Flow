# Task Status Validation Rules

## Validation Checks

### 1. TaskId Format Validation

**Rule**: TaskId must match `T\d{3}` pattern

**Valid**: T001, T002, T123
**Invalid**: T1, T12, T1234, T001A

**Auto-fix**:
```bash
# Pad with zeros
T1   → T001
T12  → T012

# Reject if too long
T1234 → ERROR: TaskId must be 3 digits (T001-T999)
```

---

### 2. Status Transition Validation

**Valid Transitions**:
```
pending ( ) → in-progress (~) → completed (X)
pending ( ) → completed (X)  # Warning: Skipped in-progress
```

**Invalid Transitions**:
```
completed (X) → in-progress (~)  # ERROR: Already complete
completed (X) → pending ( )      # ERROR: Can't uncomplete
```

**Enforcement**:
```bash
if [[ "$current_status" == "X" && "$new_status" != "X" ]]; then
  error="Cannot change status of completed task T${TaskId}"
  suggestion="Create new task or use force flag"
fi

if [[ "$current_status" == " " && "$new_status" == "X" ]]; then
  warning="Recommended: mark-in-progress first for tracking"
fi
```

---

### 3. TDD Flow Validation

**Rule**: Test tasks should be completed before implementation tasks

**Pattern Detection**:
- Test task: Description contains "test", "spec", "[RED]", "[GREEN]"
- Implementation task: Description contains "implement", "create", "build" (without "test")

**Validation Logic**:
```bash
# Find related test/impl pairs
test_tasks=$(grep -E '\[RED\]|\[GREEN\]|test|spec' tasks.md)
impl_tasks=$(grep -E 'implement|create|build' tasks.md | grep -v 'test')

# Check if impl completed before test
for impl in $impl_tasks; do
  impl_id=$(echo "$impl" | grep -oP 'T\d{3}')
  impl_status=$(echo "$impl" | grep -oP '\[(.?)\]' | tr -d '[]')

  # Find related test (similar description)
  related_test=$(find_related_test "$impl")

  if [[ "$impl_status" == "X" && "$related_test_status" != "X" ]]; then
    warning="TDD Violation: $impl_id completed but test ${related_test_id} pending"
    recommendation="Complete ${related_test_id} first for TDD compliance"
  fi
done
```

**Example Violation**:
```markdown
- [X] T012 Implement message validation      # ⚠️ Completed
- [ ] T011 Write tests for message validation  # ❌ Pending

Warning: TDD Violation - T012 completed before T011
```

---

### 4. Parallel Task Safety

**Rule**: Maximum 2 tasks can be in-progress simultaneously

**Validation**:
```bash
in_progress_count=$(grep -c '\[~\]' tasks.md)

if [[ $in_progress_count -gt 2 ]]; then
  error="Parallel task limit exceeded: ${in_progress_count}/2"
  recommendation="Complete or pause existing tasks before starting new ones"
fi
```

**File Conflict Detection**:
```bash
# Extract file paths from in-progress tasks
in_progress=$(grep '\[~\]' tasks.md)
file_paths=$(echo "$in_progress" | grep -oP '`([^`]+)`' | tr -d '`')

# Check for duplicates
conflicts=$(echo "$file_paths" | sort | uniq -d)

if [[ -n "$conflicts" ]]; then
  error="File conflicts in parallel tasks: $conflicts"
  recommendation="Tasks modifying same file cannot run in parallel"
fi
```

**Example Conflict**:
```markdown
- [~] T003 Implement API routes `apps/api/routes.py`
- [~] T005 Add middleware `apps/api/routes.py`  # ❌ Conflict

Error: T003 and T005 both modify apps/api/routes.py
```

---

### 5. Required Field Validation

**For mark-done-with-notes**:
- `TaskId`: Required
- `Notes`: Recommended (prompt if missing)
- `Duration`: Auto-default to "est"

**For mark-failed**:
- `TaskId`: Required
- `ErrorMessage`: Required (no default)

**Validation**:
```bash
if [[ "$Action" == "mark-failed" && -z "$ErrorMessage" ]]; then
  error="ErrorMessage required for mark-failed action"
  prompt="Describe the error encountered for T${TaskId}:"
fi

if [[ "$Action" == "mark-done-with-notes" && -z "$Notes" ]]; then
  warning="No implementation summary provided"
  prompt="Add summary for T${TaskId} (or press Enter to skip):"
fi
```

---

### 6. TaskId Existence Validation

**Rule**: TaskId must exist in tasks.md

**Validation**:
```bash
if ! grep -q "T${TaskId}" tasks.md; then
  error="Task ${TaskId} not found in tasks.md"

  # Suggest similar task IDs
  available=$(grep -oP 'T\d{3}' tasks.md | sort -u)
  suggestion="Available task IDs: ${available}"

  # Fuzzy match for typos
  closest=$(echo "$available" | grep -E "T0*${TaskId:1}") || echo ""
  if [[ -n "$closest" ]]; then
    suggestion="Did you mean: ${closest}?"
  fi
fi
```

---

### 7. Duplicate Completion Validation

**Rule**: Don't mark already-completed tasks as complete again

**Validation**:
```bash
current_status=$(grep "T${TaskId}" tasks.md | grep -oP '\[(.?)\]' | tr -d '[]')

if [[ "$current_status" == "X" && "$Action" == "mark-done-with-notes" ]]; then
  warning="Task ${TaskId} already marked complete"
  prompt="Mark complete again? (y/N)"
  # If N, skip; if y, allow re-completion
fi
```

---

### 8. File Path Validation

**Rule**: Non-setup tasks should have file paths specified

**Validation**:
```bash
tasks_without_paths=$(grep '\[ \]' tasks.md | grep -v 'setup\|configure\|initialize' | grep -v '`.*`')

if [[ -n "$tasks_without_paths" ]]; then
  warning="Missing file paths in tasks:"
  echo "$tasks_without_paths" | while read task; do
    task_id=$(echo "$task" | grep -oP 'T\d{3}')
    echo "  - ${task_id}: No file paths specified"
  done

  recommendation="Add file paths for agent routing and conflict detection"
fi
```

---

## Auto-Fix Strategies

### Auto-Fix 1: Pad TaskId

```bash
# Input: T1, T12
# Output: T001, T012

if [[ "$TaskId" =~ ^T[0-9]{1,2}$ ]]; then
  TaskId=$(printf "T%03d" "${TaskId:1}")
  info="Auto-fixed TaskId format: ${TaskId}"
fi
```

### Auto-Fix 2: Default Duration

```bash
# Input: Duration not provided
# Output: Duration="est"

Duration="${Duration:-est}"
```

### Auto-Fix 3: Insert In-Progress Step

```bash
# Input: Marking pending task as complete directly
# Output: Mark in-progress first, then complete

if [[ "$current_status" == " " && "$new_status" == "X" ]]; then
  info="Inserting in-progress step for tracking"

  # Step 1: Mark in-progress
  task-tracker.sh mark-in-progress -TaskId "$TaskId"

  # Step 2: Mark complete
  task-tracker.sh mark-done-with-notes -TaskId "$TaskId" -Notes "$Notes"
fi
```

### Auto-Fix 4: Extract Notes from Context

```bash
# Input: Task completion mentioned verbally without notes
# Output: Extract notes from conversation context

if [[ -z "$Notes" && -n "$CONVERSATION_CONTEXT" ]]; then
  # Extract sentence containing TaskId
  Notes=$(echo "$CONVERSATION_CONTEXT" | grep -oP "T${TaskId}.*?\.?\s*[A-Z]" | head -1)

  info="Auto-extracted notes from context: ${Notes}"
fi
```

### Auto-Fix 5: Normalize Phase Markers

```bash
# Input: [red], [Red], [RED]
# Output: [RED]

PhaseMarker=$(echo "$PhaseMarker" | tr '[:lower:]' '[:upper:]')
```

---

## Validation Error Messages

### Clear Error Formats

```bash
# ERROR (blocking)
❌ ERROR: Task T${TaskId} not found in tasks.md
   Available: T001, T002, T003, T004
   Suggestion: Did you mean T002?

# WARNING (non-blocking)
⚠️ WARNING: Skipping in-progress marker for T${TaskId}
   Recommendation: Use mark-in-progress first for better tracking

# INFO (informational)
ℹ️ INFO: Auto-fixed TaskId format: T1 → T001
```

---

## Validation Workflow

```
1. Validate TaskId format
   ├─ Valid → Continue
   └─ Invalid → Auto-fix if possible, else ERROR

2. Check TaskId exists in tasks.md
   ├─ Exists → Continue
   └─ Not found → ERROR with suggestions

3. Validate status transition
   ├─ Valid → Continue
   ├─ Skipped in-progress → WARNING, allow
   └─ Invalid (e.g., uncomplete) → ERROR

4. Check TDD compliance
   ├─ Test before impl → Continue
   └─ Impl before test → WARNING (non-blocking)

5. Check parallel safety
   ├─ Within limit → Continue
   ├─ Exceeds limit → WARNING
   └─ File conflict → ERROR

6. Validate required fields
   ├─ All present → Continue
   ├─ Optional missing → Prompt or default
   └─ Required missing → ERROR

7. Execute task-tracker command
```

---

## Example Validations

### Example 1: Invalid TaskId

```bash
# Input
TaskId="T1"

# Validation
❌ ERROR: TaskId format invalid: T1
✅ AUTO-FIX: Padded to T001

# Result
TaskId="T001"
```

### Example 2: TDD Violation

```bash
# Input
mark-done-with-notes T012  # Implementation task

# Validation
⚠️ WARNING: TDD Violation
   T012 (implement) completed before T011 (test)
   Recommendation: Complete T011 first

# Result
Allow but warn (non-blocking)
```

### Example 3: Parallel Limit

```bash
# Input
mark-in-progress T005

# Validation
Current in-progress: T003, T004
Attempting to start: T005

❌ ERROR: Parallel task limit exceeded (3/2)
   Current: T003, T004
   Recommendation: Complete T003 or T004 first

# Result
Block until under limit
```

### Example 4: File Conflict

```bash
# Input
mark-in-progress T006 `apps/api/routes.py`

# Validation
Current in-progress: T003 `apps/api/routes.py`
Attempting to start: T006 `apps/api/routes.py`

❌ ERROR: File conflict detected
   Both T003 and T006 modify: apps/api/routes.py
   Recommendation: Complete T003 before starting T006

# Result
Block to prevent conflicts
```

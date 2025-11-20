# Manual Edit → Task-Tracker Conversion Logic

## Detection Patterns

### Pattern 1: Direct Checkbox Edit

**Detected Edit**:
```javascript
Edit({
  file_path: "specs/001-feature/tasks.md",
  old_string: "- [ ] T001 Create database schema",
  new_string: "- [X] T001 Create database schema"
})
```

**Extraction**:
- `TaskId`: T001 (from checkbox pattern)
- `NewStatus`: X (completed)
- `Action`: mark-done-with-notes

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T001 \
  -Duration "est"
```

---

### Pattern 2: Adding NOTES.md Marker

**Detected Edit**:
```javascript
Edit({
  file_path: "specs/001-feature/NOTES.md",
  old_string: "## Implementation Progress\n\n",
  new_string: "## Implementation Progress\n\n✅ T002: Implemented API routes\n"
})
```

**Extraction**:
- `TaskId`: T002 (from ✅ pattern)
- `Notes`: "Implemented API routes"
- `Action`: mark-done-with-notes

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T002 \
  -Notes "Implemented API routes" \
  -Duration "est"
```

---

### Pattern 3: Marking In-Progress

**Detected Edit**:
```javascript
Edit({
  file_path: "specs/001-feature/tasks.md",
  old_string: "- [ ] T003 Create UI components",
  new_string: "- [~] T003 Create UI components"
})
```

**Extraction**:
- `TaskId`: T003
- `NewStatus`: ~ (in-progress)
- `Action`: mark-in-progress

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-in-progress \
  -TaskId T003
```

---

### Pattern 4: Verbal Completion Mention

**Detected Phrase**:
- "Mark T004 as completed"
- "T004 is done"
- "Completed T004"
- "Task T004 complete"

**Extraction**:
- `TaskId`: T004 (from regex `T\d+`)
- `Action`: mark-done-with-notes

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T004 \
  -Duration "est"
```

---

### Pattern 5: Completion with Evidence

**Detected Edit**:
```javascript
Edit({
  file_path: "specs/001-feature/NOTES.md",
  new_string: "✅ T005: Created Message model - 15min\n  - Evidence: pytest: 25/25 passing\n  - Coverage: 92% (+8%)\n"
})
```

**Extraction**:
- `TaskId`: T005
- `Notes`: "Created Message model"
- `Evidence`: "pytest: 25/25 passing"
- `Coverage`: "92% (+8%)"
- `Duration`: "15min"
- `Action`: mark-done-with-notes

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T005 \
  -Notes "Created Message model" \
  -Evidence "pytest: 25/25 passing" \
  -Coverage "92% (+8%)" \
  -Duration "15min"
```

---

### Pattern 6: Task Failure

**Detected Phrase**:
- "T006 failed"
- "Mark T006 as failed: ImportError"
- "Task T006 encountered error: ..."

**Extraction**:
- `TaskId`: T006
- `ErrorMessage`: Extract error description after colon or "error:"
- `Action`: mark-failed

**Converted Command**:
```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId T006 \
  -ErrorMessage "ImportError on MessageService"
```

---

## Regex Patterns for Extraction

### TaskId Pattern
```regex
T\d{3}
```

Matches: T001, T002, T123
Does not match: T1, T12, T1234

**Auto-fix**: Pad with zeros if T\d{1,2} detected:
- T1 → T001
- T12 → T012

### Checkbox Status Pattern
```regex
- \[(.?)\] (T\d+)
```

Captures:
- Group 1: Checkbox status (space, X, x, ~, P)
- Group 2: Task ID

Status mapping:
- ` ` → pending
- `X` or `x` → completed
- `~` or `P` → in-progress

### NOTES.md Marker Pattern
```regex
^✅ (T\d+)(?:\s*\[([^\]]+)\])?:\s*(.+?)\s*-\s*(\d+min|est)
```

Captures:
- Group 1: Task ID
- Group 2: Phase marker (optional, e.g., [RED], [GREEN])
- Group 3: Notes/description
- Group 4: Duration

### Evidence Pattern
```regex
Evidence:\s*(.+)
```

Captures:
- Group 1: Evidence text (e.g., "pytest: 25/25 passing")

### Coverage Pattern
```regex
Coverage:\s*(\d+%)\s*\(([+-]\d+%)\)
```

Captures:
- Group 1: Current coverage (e.g., "92%")
- Group 2: Change indicator (e.g., "+8%")

### Commit Hash Pattern
```regex
Committed?:\s*([a-f0-9]{6,40})
```

Captures:
- Group 1: Git commit hash

### Error Message Pattern
```regex
(?:failed|error):\s*(.+)
```

Captures:
- Group 1: Error description

---

## Conversion Decision Tree

```
Intent detected?
│
├─ Checkbox change ([ ] → [X])
│  └─ Convert to: mark-done-with-notes
│     - Extract TaskId from checkbox pattern
│     - Check for adjacent notes to include
│     - Default Duration: "est"
│
├─ Checkbox change ([ ] → [~])
│  └─ Convert to: mark-in-progress
│     - Extract TaskId from checkbox pattern
│
├─ NOTES.md marker addition (✅ T###)
│  └─ Convert to: mark-done-with-notes
│     - Extract TaskId, Notes, Evidence, Coverage, Duration
│     - Include all available metadata
│
├─ Verbal completion ("T### is done")
│  └─ Convert to: mark-done-with-notes
│     - Extract TaskId from phrase
│     - Check conversation context for notes
│     - Default Duration: "est"
│
├─ Verbal failure ("T### failed: error")
│  └─ Convert to: mark-failed
│     - Extract TaskId and ErrorMessage
│
└─ Write entire tasks.md/NOTES.md file
   └─ Diff analysis required:
      - Compare old vs new content
      - Identify changed task statuses
      - Generate multiple task-tracker commands if needed
```

---

## Validation Before Conversion

### 1. TaskId Exists

```bash
# Read tasks.md
tasks=$(cat specs/*/tasks.md)

# Check if TaskId present
if ! grep -q "T${TaskId}" <<< "$tasks"; then
  error="Task ${TaskId} not found in tasks.md"
  # List available task IDs for suggestion
  available=$(grep -oP 'T\d{3}' <<< "$tasks" | sort -u)
  suggestion="Available: ${available}"
fi
```

### 2. Status Transition Valid

```bash
# Get current status
current_status=$(grep "T${TaskId}" tasks.md | grep -oP '\[(.?)\]' | tr -d '[]')

# Validate transition
if [[ "$current_status" == " " && "$new_status" == "X" ]]; then
  warning="Skipping in-progress marker. Recommend: mark-in-progress first"
fi

if [[ "$current_status" == "X" ]]; then
  error="Task already completed. Use force flag to override?"
fi
```

### 3. Required Fields Present

```bash
# For mark-done-with-notes
if [[ -z "$Notes" ]]; then
  prompt="Add implementation summary for T${TaskId}:"
  # Use AskUserQuestion to gather notes
fi

# For mark-failed
if [[ -z "$ErrorMessage" ]]; then
  error="ErrorMessage required for mark-failed"
fi
```

---

## Auto-Fix Common Mistakes

### Mistake 1: Wrong TaskId Format

```bash
# Detected: T1, T12
# Auto-fix: Pad with zeros

if [[ "$TaskId" =~ ^T[0-9]{1,2}$ ]]; then
  TaskId=$(printf "T%03d" "${TaskId:1}")
  info="Auto-fixed TaskId format: ${TaskId}"
fi
```

### Mistake 2: Missing Duration

```bash
# Default to "est" if not provided
Duration="${Duration:-est}"
```

### Mistake 3: Invalid Characters in Notes

```bash
# Escape special characters for bash
Notes=$(printf "%q" "$Notes")
```

### Mistake 4: Marking Multiple Tasks Simultaneously

```bash
# Detected: Multiple checkbox changes in single edit
# Auto-fix: Generate separate commands for each

if [[ $(grep -c '\[X\]' <<< "$new_string") -gt 1 ]]; then
  # Extract each TaskId
  task_ids=$(grep -oP 'T\d{3}' <<< "$new_string")

  # Generate command for each
  for task_id in $task_ids; do
    task-tracker.sh mark-done-with-notes -TaskId "$task_id"
  done
fi
```

---

## Example Conversions

### Example 1: Simple Completion

**Input** (Edit attempt):
```markdown
old_string: - [ ] T001 Create database schema
new_string: - [X] T001 Create database schema
```

**Conversion**:
```bash
# Extracted
TaskId="T001"
Action="mark-done-with-notes"
Duration="est"

# Generated command
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T001 \
  -Duration est
```

---

### Example 2: Completion with Full Context

**Input** (Edit attempt):
```markdown
new_string: ✅ T002 [RED]: Created Message model with validation - 15min (2025-11-19 10:30)
  - Evidence: pytest: 25/25 passing
  - Coverage: 92% (+8%)
  - Committed: abc123
```

**Conversion**:
```bash
# Extracted
TaskId="T002"
Notes="Created Message model with validation"
Evidence="pytest: 25/25 passing"
Coverage="92% (+8%)"
CommitHash="abc123"
Duration="15min"
Action="mark-done-with-notes"

# Generated command
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T002 \
  -Notes "Created Message model with validation" \
  -Evidence "pytest: 25/25 passing" \
  -Coverage "92% (+8%)" \
  -CommitHash abc123 \
  -Duration 15min
```

---

### Example 3: Verbal Mention

**Input** (User message):
```
"I've completed T003, all tests are passing"
```

**Conversion**:
```bash
# Extracted from context
TaskId="T003"
Notes="all tests are passing"  # From surrounding context
Action="mark-done-with-notes"

# Generated command
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T003 \
  -Notes "all tests are passing" \
  -Duration est
```

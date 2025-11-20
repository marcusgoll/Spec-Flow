# Task-Tracker API Reference

## Command Overview

| Command                | Purpose                             | Required Parameters        | Optional Parameters                                            |
| ---------------------- | ----------------------------------- | -------------------------- | -------------------------------------------------------------- |
| `status`               | Get current task status             | None                       | `-Json`                                                        |
| `mark-done-with-notes` | Mark task complete atomically       | `-TaskId`                  | `-Notes`, `-Evidence`, `-Coverage`, `-CommitHash`, `-Duration` |
| `mark-in-progress`     | Mark task as in progress            | `-TaskId`                  | None                                                           |
| `mark-failed`          | Log task failure                    | `-TaskId`, `-ErrorMessage` | None                                                           |
| `sync-status`          | Migrate completed tasks to NOTES.md | None                       | None                                                           |
| `next`                 | Get next available task             | None                       | `-Json`                                                        |
| `summary`              | Get phase-wise progress summary     | None                       | `-Json`                                                        |
| `validate`             | Validate task file structure        | None                       | `-Json`                                                        |

## Command Details

### status

**Purpose**: Get current task status including completed, in-progress, and pending tasks.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh status -Json
```

**Output (JSON)**:

```json
{
  "FeatureDir": "specs/001-example-feature",
  "TasksFile": "specs/001-example-feature/tasks.md",
  "TotalTasks": 28,
  "CompletedCount": 12,
  "InProgressCount": 2,
  "PendingCount": 14,
  "CompletedTasks": [
    {
      "Id": "T001",
      "Description": "Create database schema",
      "Notes": ["Created Message model", "Added indexes"]
    }
  ],
  "InProgressTasks": [
    {
      "Id": "T003",
      "Description": "Implement API routes",
      "FilePaths": ["apps/api/routes.py"]
    }
  ],
  "NextAvailableTasks": [
    {
      "Id": "T004",
      "Description": "Create UI components",
      "IsParallel": false,
      "Priority": "High",
      "RecommendedAgent": "frontend-dev"
    }
  ],
  "ParallelSafetyCheck": {
    "Safe": true,
    "Message": "Within parallel task limit (2/2)"
  }
}
```

**Output (Table)**:

```
Total: 28 | Completed: 12 (43%) | In Progress: 2 | Pending: 14
Next: T004 - Create UI components (frontend-dev)
```

---

### mark-done-with-notes

**Purpose**: Atomically mark task complete in both tasks.md and NOTES.md with implementation evidence.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-done-with-notes \
  -TaskId T001 \
  -Notes "Created Message model with validation" \
  -Evidence "pytest: 25/25 passing" \
  -Coverage "92% (+8%)" \
  -CommitHash "abc123" \
  -Duration "15min"
```

**Parameters**:

- `-TaskId` (required): Task ID (e.g., T001, T002)
- `-Notes` (optional): Implementation summary
- `-Evidence` (optional): Test execution evidence
- `-Coverage` (optional): Coverage metrics with change indicator
- `-CommitHash` (optional): Git commit hash for traceability
- `-Duration` (optional): Task duration (e.g., "15min", "2h"). Defaults to "est" if not provided

**Output (JSON)**:

```json
{
  "Success": true,
  "TaskId": "T001",
  "Message": "Task T001 marked complete in both tasks.md and NOTES.md",
  "TasksFile": "specs/001-example/tasks.md",
  "NotesFile": "specs/001-example/NOTES.md",
  "PhaseMarker": "[RED]"
}
```

**File Updates**:

**tasks.md (before)**:

```markdown
- [ ] T001 [RED] Create Message model with validation
```

**tasks.md (after)**:

```markdown
- [x] T001 [RED] Create Message model with validation
```

**NOTES.md (appended)**:

```markdown
✅ T001 [RED]: Created Message model with validation - 15min (2025-11-19 10:30)

- Evidence: pytest: 25/25 passing
- Coverage: 92% (+8%)
- Committed: abc123
```

---

### mark-in-progress

**Purpose**: Mark task as currently being worked on.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-in-progress -TaskId T002
```

**Parameters**:

- `-TaskId` (required): Task ID to mark in progress

**Output (JSON)**:

```json
{
  "Success": true,
  "TaskId": "T002",
  "NewStatus": "~",
  "Message": "Task T002 marked as in progress"
}
```

**File Updates**:

**tasks.md (before)**:

```markdown
- [ ] T002 Implement API routes
```

**tasks.md (after)**:

```markdown
- [~] T002 Implement API routes
```

**Note**: Does NOT update NOTES.md (completion marker added only when task is done).

---

### mark-failed

**Purpose**: Log task failure in error-log.md for debugging and retry tracking.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh mark-failed \
  -TaskId T003 \
  -ErrorMessage "Tests failing: ImportError on MessageService"
```

**Parameters**:

- `-TaskId` (required): Task ID that failed
- `-ErrorMessage` (required): Error description

**Output (JSON)**:

```json
{
  "Success": true,
  "TaskId": "T003",
  "Message": "Task T003 marked as failed in error-log.md",
  "ErrorLogFile": "specs/001-example/error-log.md",
  "Timestamp": "2025-11-19 10:30:45"
}
```

**File Updates**:

**error-log.md (created if doesn't exist, appended otherwise)**:

```markdown
# Error Log

## ❌ T003 - 2025-11-19 10:30

**Error:** Tests failing: ImportError on MessageService

**Status:** Needs retry or investigation

---
```

**tasks.md (unchanged)**:

```markdown
- [ ] T003 Create test suite for MessageService
```

**Note**: Checkbox remains unchecked for retry. Error is logged for tracking.

---

### sync-status

**Purpose**: Migration utility to sync completed tasks from tasks.md to NOTES.md.

**Use Case**: When NOTES.md is missing or incomplete, this command reads tasks.md and generates NOTES.md entries for already-completed tasks.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh sync-status
```

**Output (JSON)**:

```json
{
  "Success": true,
  "Message": "Synced 5 task(s) from tasks.md to NOTES.md",
  "SyncedCount": 5,
  "SyncedTasks": ["T001", "T002", "T005", "T008", "T012"]
}
```

**Example Migration**:

**Before (tasks.md has completions, NOTES.md missing/incomplete)**:

```markdown
# tasks.md

- [x] T001 Create database schema
- [x] T002 Implement API routes
- [ ] T003 Create UI components
```

**After sync-status**:

```markdown
# NOTES.md (generated)

✅ T001: Create database schema

- Migrated from tasks.md (completed previously)

✅ T002: Implement API routes

- Migrated from tasks.md (completed previously)
```

---

### next

**Purpose**: Get next available task based on dependencies and parallel safety.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh next -Json
```

**Output (JSON)**:

```json
{
  "NextTasks": [
    {
      "Id": "T004",
      "Description": "Create UI components",
      "IsParallel": false,
      "FilePaths": ["apps/web/components/MessageList.tsx"],
      "Priority": "High",
      "RecommendedAgent": "frontend-dev",
      "McpTools": [
        "mcp__chrome-devtools__take_screenshot",
        "mcp__chrome-devtools__performance_start_trace"
      ]
    },
    {
      "Id": "T007",
      "Description": "Write integration tests [P]",
      "IsParallel": true,
      "Priority": "Low",
      "RecommendedAgent": "qa-test"
    }
  ],
  "CurrentInProgress": [
    {
      "Id": "T003",
      "Description": "Implement API routes"
    }
  ],
  "Recommendation": "Start with: T004"
}
```

**Agent Routing Logic**:

- File path contains `apps/api` → `backend-dev`
- File path contains `apps/web` → `frontend-dev`
- File path contains `contracts/` → `contracts-sdk`
- File path contains `migrations` → `database-architect`
- Description contains `test` → `qa-test`
- Description contains `debug|fix` → `debugger`

**MCP Tool Recommendations**:

- Frontend tasks → Chrome DevTools (screenshot, performance)
- Test tasks → Chrome DevTools (snapshot, click) + IDE (getDiagnostics)
- CI/CD tasks → GitHub MCP (run_workflow, create_release)
- Debug tasks → Chrome console + IDE diagnostics

---

### summary

**Purpose**: Get phase-wise progress breakdown and recommendations.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh summary -Json
```

**Output (JSON)**:

```json
{
  "OverallProgress": 42.9,
  "PhaseProgress": {
    "Setup": {
      "Completed": 3,
      "Total": 3,
      "Percentage": 100.0
    },
    "Tests": {
      "Completed": 4,
      "Total": 8,
      "Percentage": 50.0
    },
    "Implementation": {
      "Completed": 5,
      "Total": 12,
      "Percentage": 41.7
    },
    "Integration": {
      "Completed": 0,
      "Total": 3,
      "Percentage": 0.0
    },
    "Polish": {
      "Completed": 0,
      "Total": 2,
      "Percentage": 0.0
    }
  },
  "RecentlyCompleted": [
    { "Id": "T008", "Description": "Create test fixtures" },
    { "Id": "T009", "Description": "Implement message validation" },
    { "Id": "T010", "Description": "Add database indexes" }
  ],
  "Recommendations": ["Write tests BEFORE code - complete T011 before T012"]
}
```

**Phase Classification**:

- **Setup**: Tasks matching "setup|configure|initialize"
- **Tests**: Tasks matching "test|spec"
- **Implementation**: Tasks matching "implement|create|build" (excluding tests)
- **Integration**: Tasks matching "integrate|connect|middleware"
- **Polish**: Tasks matching "polish|performance|documentation|accessibility"

---

### validate

**Purpose**: Validate task file structure for TDD compliance and parallel safety.

**Usage**:

```bash
.spec-flow/scripts/bash/task-tracker.sh validate -Json
```

**Output (JSON)**:

```json
{
  "Valid": false,
  "Issues": [
    "TDD Violation: T012 completed but related test T011 not done",
    "Parallel Safety: Too many parallel tasks (3/2)",
    "Missing file paths in tasks: T015, T016"
  ],
  "TaskCount": 28,
  "Recommendations": ["Fix issues before implementation"]
}
```

**Validation Checks**:

1. **TDD Violations**: Implementation tasks completed before related tests
2. **Parallel Safety**: More than 2 in-progress tasks or file path conflicts
3. **Missing File Paths**: Tasks without file paths (excluding setup/configure tasks)

**Example TDD Check**:

```markdown
# Violation detected:

- [x] T012 Implement message validation
- [ ] T011 Write tests for message validation

# Recommendation:

Complete T011 (test) before T012 (implement) for TDD compliance
```

---

## Error Handling

All commands return structured error output when failures occur:

```json
{
  "Success": false,
  "Error": "Task T999 not found in tasks.md",
  "Action": "mark-done-with-notes",
  "Timestamp": "2025-11-19 10:30:45"
}
```

**Common Errors**:

- `"No specs directory found. Run /feature first."` → No active feature directory
- `"No tasks.md found. Run /tasks first."` → Task breakdown phase not complete
- `"Task T### not found in tasks.md"` → Invalid task ID
- `"TaskId required for mark-done action"` → Missing required parameter
- `"ErrorMessage required for mark-failed action"` → Missing required parameter

---

## Best Practices

### 1. Always use mark-done-with-notes for completions

```bash
# ✅ GOOD (full context)
task-tracker.sh mark-done-with-notes \
  -TaskId T001 \
  -Notes "Implemented feature X" \
  -Evidence "Jest: 42/42 passing" \
  -Coverage "88% (+5%)" \
  -CommitHash "abc123" \
  -Duration "25min"

# ❌ BAD (missing context)
task-tracker.sh mark-done -TaskId T001
```

### 2. Mark in-progress before starting work

```bash
# Start work
task-tracker.sh mark-in-progress -TaskId T002

# [implement task]

# Complete work
task-tracker.sh mark-done-with-notes -TaskId T002 -Notes "..."
```

### 3. Use sync-status for existing features

When adopting task-tracker for an existing feature:

```bash
# Migrate existing completions
task-tracker.sh sync-status

# Verify migration
task-tracker.sh status
```

### 4. Check next before starting new task

```bash
# Get recommended next task
task-tracker.sh next -Json

# Start the recommended task
task-tracker.sh mark-in-progress -TaskId T004
```

### 5. Validate before shipping

```bash
# Check for TDD violations and parallel safety
task-tracker.sh validate -Json

# Fix any issues before proceeding
```

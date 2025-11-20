# Task File Formats Reference

## tasks.md Structure

### Overall Format

```markdown
# Task Breakdown: [Feature Name]

[Phase group 1]
- [ ] T001 Task description `file/path.ext`
- [~] T002 [PHASE] Task description `file/path.ext`
- [X] T003 Task description `file/path.ext`

[Phase group 2]
- [ ] T004 [P] Parallel task description `file/path.ext`
```

### Checkbox States

| Symbol | Meaning | Status |
|--------|---------|--------|
| `[ ]` | Pending | Not started |
| `[~]` | In Progress | Currently being worked on |
| `[X]` | Completed | Done |
| `[P]` | Parallel-safe | Can run alongside other [P] tasks |

### Phase Markers

| Marker | Meaning | TDD Phase |
|--------|---------|-----------|
| `[RED]` | Write failing test | Red phase |
| `[GREEN]` | Make test pass | Green phase |
| `[REFACTOR]` | Improve code | Refactor phase |
| `[US#]` | User story # | Feature grouping (e.g., [US1], [US2]) |
| `[P#]` | Priority level | Priority grouping (e.g., [P1], [P2]) |

### File Path Format

**Required for non-setup tasks**: Backtick-enclosed paths
```markdown
- [ ] T001 Create API route `apps/api/routes.py`
- [ ] T002 Add tests `apps/api/tests/test_routes.py`
```

**Multiple files**:
```markdown
- [ ] T003 Update models `apps/api/models.py, apps/api/schemas.py`
```

### Complete Example

```markdown
# Task Breakdown: Message System

## Phase 1: Red (Write Failing Tests)
- [X] T001 [RED] Write Message model tests `apps/api/tests/test_message.py`
- [X] T002 [RED] Write MessageService tests `apps/api/tests/test_message_service.py`

## Phase 2: Green (Make Tests Pass)
- [X] T003 [GREEN] Implement Message model `apps/api/models/message.py`
- [~] T004 [GREEN] Implement MessageService `apps/api/services/message_service.py`

## Phase 3: Refactor
- [ ] T005 [REFACTOR] Extract validation logic `apps/api/validators/message_validator.py`

## Phase 4: Integration
- [ ] T006 Add API endpoints `apps/api/routes/message.py`
- [ ] T007 [P] Add integration tests `apps/api/tests/integration/test_message_api.py`
```

---

## NOTES.md Structure

### Overall Format

```markdown
# Notes: [Feature Name]

## Checkpoints

- **YYYY-MM-DD HH:MM** - Phase N: Milestone description
  - Detail 1
  - Detail 2

## Implementation Progress

✅ T001 [PHASE]: Description - duration (YYYY-MM-DD HH:MM)
  - Evidence: test results
  - Coverage: percentage (change)
  - Committed: git hash

## Decisions

### Decision Title
Rationale and alternatives considered.

## Blockers Resolved

### Blocker Title
**Resolution**: How it was fixed.

## Research Notes

Findings and references.
```

### Completion Marker Format

**Basic format**:
```markdown
✅ T001: Description - est (2025-11-19 10:30)
```

**With phase marker**:
```markdown
✅ T002 [RED]: Created failing test - 10min (2025-11-19 11:00)
```

**With evidence**:
```markdown
✅ T003 [GREEN]: Implemented Message model - 15min (2025-11-19 11:30)
  - Evidence: pytest: 25/25 passing
  - Coverage: 92% (+8%)
  - Committed: abc123
```

**With multiple evidence fields**:
```markdown
✅ T004: Refactored validation logic - 20min (2025-11-19 12:00)
  - Evidence: pytest: 42/42 passing
  - Coverage: 95% (+3%)
  - Committed: def456
  - Performance: 15ms → 8ms (47% improvement)
```

### Duration Format

| Format | Meaning |
|--------|---------|
| `est` | Estimated (default when duration unknown) |
| `5min` | 5 minutes |
| `1h` | 1 hour |
| `90min` | 90 minutes (prefer minutes over fractional hours) |
| `2h30min` | 2 hours 30 minutes |

### Complete Example

```markdown
# Notes: Message System

## Checkpoints

- **2025-11-19 10:00** - Phase 0: Specification complete
- **2025-11-19 10:30** - Phase 1: Task breakdown complete (7 tasks)
- **2025-11-19 11:00** - Phase 2: RED phase started (TDD)

## Implementation Progress

✅ T001 [RED]: Write Message model tests - 10min (2025-11-19 10:35)
  - Evidence: pytest: 0/8 passing (failing as expected)
  - Coverage: N/A (tests written first)
  - Committed: abc123

✅ T002 [RED]: Write MessageService tests - 12min (2025-11-19 10:50)
  - Evidence: pytest: 0/12 passing (failing as expected)
  - Committed: def456

✅ T003 [GREEN]: Implement Message model with validation - 15min (2025-11-19 11:15)
  - Evidence: pytest: 8/8 passing
  - Coverage: 92% (+92%)
  - Committed: ghi789

⏳ T004 [GREEN]: Implement MessageService (in progress)

## Decisions

### Why SQLAlchemy over Django ORM?
FastAPI ecosystem, better type hints, async support. Django ORM would require full Django which is overkill for API-only service.

## Blockers Resolved

### Blocker 1: Pydantic v2 breaking changes
**Resolution**: Updated validation logic to use new API. Refer to Pydantic migration guide.

## Research Notes

### Message Validation Patterns
- Researched: sanitize-html vs DOMPurify for XSS prevention
- Decision: DOMPurify (better maintained, fewer CVEs)
```

---

## error-log.md Structure

### Overall Format

```markdown
# Error Log

## ❌ T### - YYYY-MM-DD HH:MM

**Error:** Error description

**Status:** Needs retry or investigation

---

## ❌ T### - YYYY-MM-DD HH:MM

**Error:** Error description

**Status:** Resolved (see T### completion)

---
```

### Entry Format

**Fresh failure**:
```markdown
## ❌ T005 - 2025-11-19 12:30

**Error:** Tests failing: ImportError on MessageService

**Status:** Needs retry or investigation

---
```

**Resolved failure**:
```markdown
## ❌ T005 - 2025-11-19 12:30

**Error:** Tests failing: ImportError on MessageService

**Status:** Resolved (see T006: Fixed import paths)

---
```

### Complete Example

```markdown
# Error Log

## ❌ T004 - 2025-11-19 11:45

**Error:** Tests failing: TypeError on MessageService.create()

**Status:** Resolved (fixed in T004 retry at 12:00)

---

## ❌ T007 - 2025-11-19 13:15

**Error:** Integration test timeout on /api/messages endpoint

**Stack Trace:**
```
TimeoutError: Test exceeded 5s limit
  at test_create_message (test_message_api.py:42)
```

**Status:** Needs investigation - likely database connection pool issue

---
```

---

## Parsing Patterns

### Regex for tasks.md

**Task line**:
```regex
^\s*-?\s*\[\s*(.?)\s*\]\s*(T\d+)(.*)$
```

Captures:
- Group 1: Status (space, X, x, ~, P)
- Group 2: Task ID
- Group 3: Description + metadata

**Phase marker**:
```regex
\[([A-Z]+|US\d+|P\d+|P)\]
```

**File paths**:
```regex
`([^`]+)`
```

**Parallel marker**:
```regex
\[P\]
```

### Regex for NOTES.md

**Completion marker**:
```regex
^✅\s+(T\d+)(?:\s*\[([^\]]+)\])?:\s*(.+?)\s*-\s*(\w+)\s*\(([0-9\-:\s]+)\)
```

Captures:
- Group 1: Task ID
- Group 2: Phase marker (optional)
- Group 3: Description
- Group 4: Duration
- Group 5: Timestamp

**Evidence line**:
```regex
^\s+-\s+Evidence:\s*(.+)
```

**Coverage line**:
```regex
^\s+-\s+Coverage:\s*(\d+%)\s*\(([+-]\d+%)\)
```

**Commit line**:
```regex
^\s+-\s+Committed?:\s*([a-f0-9]{6,40})
```

### Regex for error-log.md

**Error header**:
```regex
^##\s*❌\s*(T\d+)\s*-\s*(.+)
```

Captures:
- Group 1: Task ID
- Group 2: Timestamp

**Status line**:
```regex
^\*\*Status:\*\*\s*(.+)
```

---

## File Location Patterns

### Feature Directory Structure

```
specs/
  001-feature-slug/
    spec.md
    plan.md
    tasks.md          ← Task breakdown
    NOTES.md          ← Progress tracking
    error-log.md      ← Failure tracking (created on first failure)
    artifacts/
      tasks.md        ← Legacy location (deprecated)
```

**Current Location (Spec-Flow v5+)**:
- `specs/NNN-slug/tasks.md`
- `specs/NNN-slug/NOTES.md`

**Legacy Location (Spec-Flow v4)**:
- `specs/NNN-slug/artifacts/tasks.md`
- `specs/NNN-slug/NOTES.md` (same location)

**Fallback Search**:
```bash
# Try current location first
TASKS_FILE="specs/*/tasks.md"

# Fall back to artifacts/
if [[ ! -f "$TASKS_FILE" ]]; then
  TASKS_FILE="specs/*/artifacts/tasks.md"
fi
```

---

## Best Practices

### tasks.md Best Practices

1. **Always include file paths** (except setup/configure tasks)
2. **Use phase markers** for TDD workflow ([RED], [GREEN], [REFACTOR])
3. **Mark parallel-safe tasks** with [P] to enable concurrent work
4. **Keep descriptions concise** (1 line, < 80 chars)
5. **Group by phase** for better readability

### NOTES.md Best Practices

1. **Update checkpoints** at major milestones
2. **Include evidence** with completions (tests, coverage, commits)
3. **Document decisions** with rationale
4. **Record blockers** and their resolutions
5. **Add research notes** for future reference

### error-log.md Best Practices

1. **Include stack traces** when available
2. **Update status** when errors are resolved
3. **Cross-reference** fix task IDs
4. **Keep chronological** (newest at bottom)
5. **Add investigation notes** for complex errors

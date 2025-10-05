---
description: Execute tasks with TDD, anti-duplication checks, pattern following
---

Execute tasks from: specs/$FEATURE/tasks.md

## PER-TASK WORKFLOW (TDD: RED  GREEN  REFACTOR)

For each task T001, T002, T003...

### 1. READ TASK (identify phase: RED/GREEN/REFACTOR)

Task examples:
```
T006 [RED] Write failing test: Message validates content length
T016 [GREENT006] Implement Message.validate_content() to pass T006
T024 [REFACTOR] Extract validation to MessageValidator (tests stay green)
```

### 2. READ REFERENCED FILES (for context)

Before implementing, read files marked for REUSE:
```bash
# Read files mentioned in REUSE markers
Read api/src/services/database_service.py
Read api/src/services/cache_service.py

# Read pattern reference
Read api/src/modules/notifications/services/notification_service.py

# Read visual specs for UI tasks
if [frontend task]:
  Read specs/NNN-feature/visuals/README.md

# Read test patterns
Read .spec-flow/templates/test-patterns.md
```

### 3A. RED PHASE: Write Failing Test

**Step 1: Write test that expresses desired behavior**
```python
import pytest
from app.models.message import Message, ValidationError

def test_content_exceeding_4000_chars_raises_validation_error():
    # GIVEN: Content exceeding max length
    long_content = "x" * 4001

    # WHEN: Validating content
    with pytest.raises(ValidationError) as exc:
        Message.validate_content(long_content)

    # THEN: Validation error raised
    assert "exceeds maximum length" in str(exc.value)
```

**Step 2: RUN TEST - MUST fail for the right reason**
```bash
pytest api/tests/test_message.py::test_content_exceeding_4000_chars_raises_validation_error -v
```

**Step 3: CAPTURE EVIDENCE (mandatory)**
```
 FAIL api/tests/test_message.py::test_content_exceeding_4000_chars_raises_validation_error
AttributeError: module 'app.models.message' has no attribute 'validate_content'
REASON: Message.validate_content() not implemented yet  (expected failure)
```

**Step 4: Commit RED phase**
```bash
git add api/tests/test_message.py
git commit -m "test(red): add failing test for content length validation

RED phase: Test must fail
Expected: ValidationError for content >4000 chars
Actual: AttributeError (validate_content not implemented)

Completed: T006/30

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 3B. GREEN PHASE: Minimal Implementation

**Step 1: Write MINIMUM code to pass test**
```python
class Message:
    @staticmethod
    def validate_content(content: str) -> None:
        if len(content) > 4000:
            raise ValidationError("Content exceeds maximum length of 4000 characters")
        if len(content) == 0:
            raise ValidationError("Content cannot be empty")
```

**Step 2: RUN TEST - MUST pass now**
```bash
pytest api/tests/test_message.py::test_content_exceeding_4000_chars_raises_validation_error -v
```

**Step 3: CAPTURE EVIDENCE (mandatory)**
```
 PASS api/tests/test_message.py::test_content_exceeding_4000_chars_raises_validation_error (0.8s)
Coverage: message.py 85% (+15% from baseline)
```

**Step 4: Commit GREEN phase**
```bash
git add api/src/models/message.py
git commit -m "feat(green): implement content validation to pass test

GREEN phase: Test now passes
Implements: Message.validate_content()
Validates: Max 4000 chars, non-empty
Coverage: 85% (target: 80%)

Completed: T016/30 (passes T006)

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 3C. REFACTOR PHASE: Clean Up

**Step 1: Improve code (extract, rename, DRY)**
```python
# Extract to separate validator class
class MessageValidator:
    MAX_CONTENT_LENGTH = 4000

    @staticmethod
    def validate_content(content: str) -> None:
        if len(content) > MessageValidator.MAX_CONTENT_LENGTH:
            raise ValidationError(
                f"Content exceeds maximum length of {MessageValidator.MAX_CONTENT_LENGTH}"
            )
        if not content.strip():
            raise ValidationError("Content cannot be empty")

class Message:
    @staticmethod
    def validate_content(content: str) -> None:
        return MessageValidator.validate_content(content)
```

**Step 2: RUN TESTS - MUST stay green**
```bash
pytest api/tests/test_message.py -v
```

**Step 3: CAPTURE EVIDENCE (mandatory)**
```
 PASS api/tests/ (12 tests, 4.2s)
Coverage: 85% (maintained, no drop)
All tests green after refactor 
```

**Step 4: Commit REFACTOR phase**
```bash
git add api/src/models/message.py api/src/validators/message_validator.py
git commit -m "refactor: extract validation to MessageValidator for reusability

REFACTOR phase: Tests stay green
Extracted: MessageValidator class
Improved: Constant for max length, clearer error messages
Tests: All passing (12/12, 4.2s)

Completed: T024/30

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 4. EVIDENCE REQUIREMENTS (MANDATORY)

**Every test execution MUST show:**
-  Command run: `pytest [path] -v` or `npm test [path]`
-  Pass/fail status with test names
-  Execution time (<2s unit, <10s integration, <6min suite)
-  Coverage delta (if applicable)
-  Failure reason (RED phase only)

**If no evidence found:**
```
 WARNING: No test execution evidence for T016
Required: pytest/jest output showing pass/fail
Run tests now? (Y/n)
```

**Evidence validation:**
```bash
# Check test was actually run
git log -1 --grep="T016" | grep -E "PASS|FAIL"
# If not found  prompt for test execution
```

### 5. GUARDRAIL VALIDATION (before marking complete)

**Speed Check:**
```bash
# Unit tests <2s
pytest api/tests/test_message.py --durations=5
# Flag if any test >2s  "Optimize: Mock DB calls"

# Suite <6min
time pytest api/tests/
# If >360s  "FAIL: Suite too slow, refactor tests"
```

**Quality Check:**
```bash
# One behavior per test (check assertions)
pytest api/tests/test_message.py --collect-only | wc -l
# Should match number of behaviors tested

# No snapshots (frontend)
grep -r "toMatchSnapshot" apps/app/tests/
# If found  "FAIL: Remove snapshots, use semantic queries"

# Prefer accessible queries
grep -c "getByRole\|getByText" apps/app/tests/ vs grep -c "getByTestId"
# Ratio >70% is good
```

**Validation Output:**
```
 Speed: All tests <2s (avg: 0.9s, max: 1.8s)
 Suite: 4.2s total (<6min )
 Clarity: 12 tests, 14 assertions (1.2 avg)
 Accessible: 9/12 use role/text (75%)
 FAIL: Found 2 snapshots  Action: Replace with semantic assertions
```

### 6. UPDATE NOTES.md (checkpoint per task)

```markdown
## Checkpoints
-  T006 [RED]: Content validation test (failing as expected)
  - Evidence: pytest output showing AttributeError 
  - Committed: abc1234

-  T016 [GREEN]: Implement Message.validate_content()
  - Evidence: pytest output showing PASS (0.8s) 
  - Coverage: 85% (+15%)
  - Committed: def5678

-  T024 [REFACTOR]: Extract MessageValidator
  - Evidence: All tests green (12/12, 4.2s) 
  - Improved: Extracted validator, added constant
  - Committed: ghi9012
```

## CONSTRAINTS

**TDD Workflow (strict):**
- RED  GREEN  REFACTOR loop (no exceptions)
- RED: Test MUST fail for right reason, evidence required
- GREEN: Minimal code to pass, evidence required
- REFACTOR: Tests MUST stay green, evidence required

**Code Quality:**
- REUSE: Check task markers, read referenced files first
- Pattern: Follow similar file structure
- JSDoc/docstrings: Add @see tags to reused code
- One task at a time (no batching)

**Process:**
- Commit after EVERY task (RED, GREEN, REFACTOR phases)
- Update NOTES.md with evidence checkpoints
- Compact every 10 tasks
- Validate guardrails before marking complete

## AGENT ROUTING (Enhanced)

**Use `/route-agent` for intelligent delegation:**

Before implementing each task, determine appropriate specialist agent:

```bash
# Extract task domain from file paths and keywords
TASK_DOMAIN=$(analyze-task-domain "$TASK_ID" "$TASK_DESCRIPTION")

# Route to specialist using /route-agent helper
/route-agent "$TASK_DOMAIN" "$TASK_ID"
```

**Routing decision tree** (from `/route-agent`):
- `api/**/*.py`  spec-flow-backend-dev
- `apps/**/*.tsx`  spec-flow-frontend-shipper
- `api/alembic/**`  spec-flow-database-architect
- `**/tests/**`  spec-flow-qa-test
- "bug"|"error"|"fix"  spec-flow-debugger

**Context provided to agent:**
- Task description with REUSE markers
- Relevant spec.md sections
- Visual specs (visuals/README.md if UI task)
- error-log.md recent entries
- Pattern references from tasks.md

**Agent returns structured result:**
```json
{
  "agent": "spec-flow-backend-dev",
  "task_completed": true,
  "files_changed": ["api/app/routes/users.py"],
  "tests_added": ["api/tests/test_users.py"],
  "verification": {
    "lint": "pass",
    "type_check": "pass",
    "tests": "pass (12/12)",
    "coverage": "85%"
  }
}
```

## AGENT ERROR HANDLING

- **Agent unavailable**: Fall back to manual implementation, log which agent failed, continue with next task
- **Agent returns error**: Retry once with clarified context, then fail with agent error message
- **Agent timeout (>5min)**: Cancel agent, ask user "Continue manually or skip task?"
- **Agent output invalid**: Validate against expected schema, request re-run with explicit format requirements
- **Agent fails validation**: Check if files created, tests pass; if partial success, ask "Keep changes or rollback?"

**When errors occur during implementation**:
- Use `/debug` command to systematically debug and update error-log.md
- Document failures with: Failure, Symptom, Learning, Ghost Context Cleanup
- Include task ID in error-log entry (e.g., "During T023 middleware update")

## REUSE VALIDATION

Before marking task complete:
1. Verify REUSE markers reference real files: `grep -l "import.*DatabaseService" [task-file]`
2. Check pattern file exists: `test -f api/src/modules/notifications/service.py`
3. If missing: Fail task with "Pattern file not found: [path]", don't proceed
4. Validate imports compile: Run type-check or linter on new file
5. Flag if claimed reuse but no import statement found

## RECOVERY MODE

If Claude Code crashes mid-task:

1. Read NOTES.md  find last checkpoint
2. Read error-log.md  check for recent failures
3. Check git log  last commit
4. Check git status  unstaged changes
5. Prompt:
```
Last checkpoint: T015 completed
Recent error-log entries: N (review with /debug if needed)
Unstaged: api/src/modules/chat/services/message_service.py

Resume T016 (MessageService)?
A) Continue (commit current state)
B) Rollback (discard changes, restart T016)
C) Review (show diff first)
D) Debug (run /debug to investigate issues)
```

## RETURN (per task)

Brief update:
-  T0NN: [task name] - COMPLETED
-  Files: [changed files]
-  Tests: N passing, coverage NN%
-   Reused: [services/modules]
-  NOTES.md: Checkpoint added
-  Context: NN,NNN/100,000 tokens (implementation phase)

After all tasks:
```

 IMPLEMENTATION COMPLETE


Tasks: NN/NN completed
Tests: NNN passing, coverage NN%
Phase: Implementation (3-4)

Next: /optimize
Optional: /compact implementation (to reduce context before optimize)
```



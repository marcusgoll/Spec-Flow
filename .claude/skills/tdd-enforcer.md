---
name: tdd-enforcer
description: Enforce proper TDD workflow (RED→GREEN→REFACTOR) before implementation. Auto-trigger when detecting TDD phase markers ([RED], [GREEN→T], [REFACTOR]) in tasks or when user mentions writing tests. Verify failing test exists before GREEN phase, passing tests before REFACTOR phase. Block violations to prevent auto-rollback scenarios.
allowed-tools: Bash, Read, Grep
---

# TDD Enforcer: RED→GREEN→REFACTOR Compliance

**Purpose**: Ensure Test-Driven Development phases follow proper sequence to prevent auto-rollback and rework.

**Philosophy**: "Tests are the specification. Write them first, make them pass, then improve."

---

## TDD Phase Rules (Strict Sequential Order)

### Phase 1: RED (Write Failing Test)

**Requirements:**
- Write test first (before implementation)
- Test must fail for the right reason
- Provide test output as evidence of failure
- Commit: `test(red): TXXX write failing test`

**Verification:**
```bash
# Run test suite
pytest api/tests/test_*.py -v  # Backend
pnpm test -- --testNamePattern="TestName"  # Frontend

# Expected: Test fails with AssertionError or NotImplementedError
# NOT expected: Test passes, import errors, syntax errors
```

**Anti-Patterns to Block:**
- Test passes on first run (not a proper RED phase)
- Test fails due to syntax error (not testing logic)
- Test fails due to missing imports (setup issue, not RED phase)
- No test output provided as evidence

---

### Phase 2: GREEN (Minimal Implementation)

**Requirements:**
- Implement minimal code to pass RED test
- All tests must pass (including RED test)
- Auto-rollback if tests fail
- Commit: `feat(green): TXXX implement to pass test`

**Prerequisite Check:**
```bash
# Before allowing GREEN phase, verify RED phase exists
TASK_ID="T001"
RED_TASK_ID=$(grep -B 1 "GREEN→$TASK_ID" "$TASKS_FILE" | grep "\[RED\]" | grep -o "^T[0-9]\{3\}")

if [ -z "$RED_TASK_ID" ]; then
  echo "❌ GREEN phase requires prior RED phase"
  echo "   Cannot implement GREEN→$TASK_ID without RED test"
  exit 1
fi

# Verify RED task is completed
if ! grep -q "✅ $RED_TASK_ID" "$NOTES_FILE"; then
  echo "❌ RED phase not complete: $RED_TASK_ID"
  echo "   Complete RED test first before GREEN implementation"
  exit 1
fi
```

**Verification:**
```bash
# Run test suite
pytest api/tests/ -v  # Backend
pnpm test  # Frontend

# Expected: All tests pass (including the RED test)
# NOT expected: Any test failures, errors
```

**Anti-Patterns to Block:**
- No prior RED test exists
- RED test not completed/marked done
- Implementing before writing test
- Tests fail after implementation (auto-rollback required)

---

### Phase 3: REFACTOR (Clean Up Code)

**Requirements:**
- Improve code quality (DRY, KISS principles)
- All tests must stay green
- Auto-rollback if tests break
- Commit: `refactor: TXXX clean up implementation`

**Prerequisite Check:**
```bash
# Before allowing REFACTOR, verify GREEN phase exists and tests pass
TASK_ID="T001"

# Find corresponding GREEN task
GREEN_TASK=$(grep "GREEN→.*$TASK_ID\|REFACTOR.*→.*$TASK_ID" "$TASKS_FILE" -B 1 | grep "\[GREEN" | grep -o "^T[0-9]\{3\}")

if [ -z "$GREEN_TASK" ]; then
  echo "❌ REFACTOR requires prior GREEN phase"
  echo "   Cannot refactor without implementation"
  exit 1
fi

# Verify GREEN task completed
if ! grep -q "✅ $GREEN_TASK" "$NOTES_FILE"; then
  echo "❌ GREEN phase not complete: $GREEN_TASK"
  echo "   Complete implementation first before refactoring"
  exit 1
fi

# Verify tests currently pass
if ! pytest api/tests/ -q 2>/dev/null; then
  echo "❌ Tests failing before REFACTOR"
  echo "   Fix tests first, then refactor"
  exit 1
fi
```

**Verification:**
```bash
# Run tests after refactoring
pytest api/tests/ -v  # Backend
pnpm test  # Frontend

# Expected: All tests still pass (green remains green)
# NOT expected: Any test failures (means refactor broke functionality)
```

**Anti-Patterns to Block:**
- No prior GREEN implementation
- GREEN test not passing
- Refactoring breaks tests (auto-rollback required)

---

## When to Trigger

Auto-invoke this Skill when detecting:

**TDD Phase Markers:**
- `[RED]` in task description
- `[GREEN→T001]` in task description
- `[REFACTOR]` in task description

**TDD Keywords:**
- "write test first"
- "failing test"
- "make test pass"
- "refactor code"
- "TDD workflow"
- "test-driven"

**Anti-Pattern Indicators:**
- Implementing without prior test
- Claiming GREEN phase without RED
- Refactoring without GREEN

---

## Pre-Implementation TDD Checklist

### For RED Phase Tasks

**Before allowing implementation:**

1. **Verify this is truly a RED phase**
   ```bash
   # Check task markers
   if ! grep -q "\[RED\]" <<< "$TASK_DESC"; then
     echo "⚠️  Task not marked as RED phase"
     echo "   Add [RED] marker if writing failing test"
   fi
   ```

2. **Ensure no implementation exists yet**
   ```bash
   # Check if implementation file already exists
   IMPL_FILE="api/app/models/message.py"

   if [ -f "$IMPL_FILE" ]; then
     echo "⚠️  Implementation file already exists: $IMPL_FILE"
     echo "   RED phase writes test first, not implementation"
     echo "   Did you mean GREEN phase?"
   fi
   ```

3. **Present RED phase guidelines**
   ```markdown
   ✅ **RED PHASE GUIDELINES**

   Your test should:
   1. Import the module to be implemented (will fail with ImportError initially)
   2. Call the function/method that doesn't exist yet
   3. Assert expected behavior
   4. FAIL with ImportError, AttributeError, or NotImplementedError

   Example (Backend):
   ```python
   from app.models.message import Message  # Will fail - module doesn't exist

   def test_message_creation():
       message = Message(content="Hello", user_id=1)
       assert message.content == "Hello"
       assert message.user_id == 1
   ```

   Run test: `pytest api/tests/test_message.py -v`
   Expected: FAILED (ImportError: No module named 'app.models.message')

   Commit: `test(red): T001 write failing test for Message model`
   ```

### For GREEN Phase Tasks

**Before allowing implementation:**

1. **Verify RED phase completed**
   ```bash
   # Extract GREEN dependency (e.g., GREEN→T014 depends on T014 being RED)
   GREEN_MARKER=$(echo "$TASK_DESC" | grep -o "GREEN→T[0-9]\{3\}")

   if [ -n "$GREEN_MARKER" ]; then
     RED_TASK=$(echo "$GREEN_MARKER" | grep -o "T[0-9]\{3\}")

     # Check if RED task complete
     if ! grep -q "✅ $RED_TASK" "$NOTES_FILE"; then
       echo "❌ **TDD VIOLATION: GREEN before RED**"
       echo ""
       echo "Task $TASK_ID requires RED test $RED_TASK to be completed first."
       echo ""
       echo "**TDD Sequence:**"
       echo "  1. Complete $RED_TASK (write failing test)"
       echo "  2. Then implement $TASK_ID (make test pass)"
       echo ""
       echo "Cannot proceed with GREEN phase until RED test exists."
       exit 1
     fi

     echo "✅ RED phase verified: $RED_TASK complete"
   else
     echo "⚠️  GREEN phase without explicit RED dependency"
     echo "   Searching for recent RED tests..."

     # Look for recent RED tasks
     RECENT_RED=$(grep "\[RED\]" "$TASKS_FILE" | grep -o "^T[0-9]\{3\}" | tail -1)

     if [ -n "$RECENT_RED" ] && ! grep -q "✅ $RECENT_RED" "$NOTES_FILE"; then
       echo "⚠️  Found incomplete RED task: $RECENT_RED"
       echo "   Should $TASK_ID depend on $RECENT_RED?"
     fi
   fi
   ```

2. **Verify test exists and fails**
   ```bash
   # Find test file from RED task
   RED_NOTES=$(grep "✅ $RED_TASK" "$NOTES_FILE" -A 3)
   TEST_FILE=$(echo "$RED_NOTES" | grep -o "tests/test_.*\.py\|.*\.test\.tsx")

   if [ -z "$TEST_FILE" ]; then
     echo "❌ Cannot find test file from RED task: $RED_TASK"
     echo "   RED phase should have created a test file"
     exit 1
   fi

   # Verify test file exists
   if [ ! -f "$TEST_FILE" ]; then
     echo "❌ Test file not found: $TEST_FILE"
     echo "   RED phase incomplete - test file missing"
     exit 1
   fi

   echo "✅ Test file verified: $TEST_FILE"
   ```

3. **Present GREEN phase guidelines**
   ```markdown
   ✅ **GREEN PHASE GUIDELINES**

   Your implementation should:
   1. Create the minimal code to make the RED test pass
   2. Don't add extra features (YAGNI - You Aren't Gonna Need It)
   3. Don't optimize prematurely (that's for REFACTOR phase)
   4. Run tests and verify they pass

   Example (Backend):
   ```python
   # api/app/models/message.py
   from sqlalchemy import Column, Integer, String
   from app.core.database import Base

   class Message(Base):
       __tablename__ = "messages"

       id = Column(Integer, primary_key=True)
       content = Column(String, nullable=False)
       user_id = Column(Integer, nullable=False)
   ```

   Run test: `pytest api/tests/test_message.py -v`
   Expected: PASSED (1 passed)

   Commit: `feat(green): T015 implement Message model to pass test`
   ```

### For REFACTOR Phase Tasks

**Before allowing implementation:**

1. **Verify GREEN phase completed and tests pass**
   ```bash
   # Ensure implementation exists and tests pass
   if ! pytest api/tests/ -q 2>/dev/null && ! pnpm test --passWithNoTests 2>/dev/null; then
     echo "❌ **TDD VIOLATION: REFACTOR with failing tests**"
     echo ""
     echo "Tests must be passing (GREEN) before refactoring."
     echo ""
     echo "**Current State:**"
     pytest api/tests/ -v 2>&1 | tail -10
     echo ""
     echo "Fix failing tests first, then refactor."
     exit 1
   fi

   echo "✅ Tests passing - safe to refactor"
   ```

2. **Identify refactoring opportunities**
   ```bash
   # Suggest common refactoring patterns
   echo "🔍 **REFACTORING OPPORTUNITIES**"
   echo ""
   echo "Common patterns to improve:"
   echo "  1. Extract repeated code into functions"
   echo "  2. Remove magic numbers (use constants)"
   echo "  3. Simplify complex conditionals"
   echo "  4. Improve variable naming"
   echo "  5. Add type hints (Python) or types (TypeScript)"
   echo ""
   ```

3. **Present REFACTOR phase guidelines**
   ```markdown
   ✅ **REFACTOR PHASE GUIDELINES**

   Your refactoring should:
   1. Improve code readability (better names, simpler logic)
   2. Remove duplication (DRY principle)
   3. Simplify complexity (KISS principle)
   4. Keep tests green (no behavior changes)
   5. Run tests after each change

   Example (Backend):
   ```python
   # Before (GREEN phase):
   class Message(Base):
       __tablename__ = "messages"
       id = Column(Integer, primary_key=True)
       content = Column(String, nullable=False)
       user_id = Column(Integer, nullable=False)

   # After (REFACTOR phase):
   from app.models.base import TimestampedModel  # Reuse base

   class Message(TimestampedModel):
       __tablename__ = "messages"

       content = Column(String(500), nullable=False, index=True)
       user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

       def __repr__(self):
           return f"<Message(id={self.id}, user_id={self.user_id})>"
   ```

   Run test: `pytest api/tests/test_message.py -v`
   Expected: PASSED (tests still pass after refactor)

   Commit: `refactor: T016 improve Message model with FK and repr`
   ```

---

## TDD Violation Scenarios

### Violation 1: GREEN without RED

**Detection:**
```bash
# Task marked as GREEN but no RED task found
if [[ "$TASK_DESC" =~ GREEN→T[0-9]{3} ]]; then
  RED_ID=$(echo "$TASK_DESC" | grep -o "GREEN→T[0-9]\{3\}" | sed 's/GREEN→//')

  if ! grep -q "\[RED\].*$RED_ID" "$TASKS_FILE"; then
    # VIOLATION: GREEN phase without RED
    echo "❌ TDD VIOLATION DETECTED"
  fi
fi
```

**Response:**
```markdown
❌ **TDD VIOLATION: GREEN Phase Without RED Test**

**Issue:**
Task $TASK_ID is marked as [GREEN→T014], but T014 is not a RED phase task.

**TDD Sequence Requirement:**
1. T014 must be marked [RED] and write a failing test
2. Only then can $TASK_ID be [GREEN→T014] to implement

**Actions:**
Option A: Update T014 to [RED] phase if it's a test
Option B: Remove GREEN→ marker if implementing without TDD
Option C: Create a new RED task first

Cannot proceed until TDD sequence is correct.
```

### Violation 2: REFACTOR without passing tests

**Detection:**
```bash
# Before REFACTOR phase, run tests
if [[ "$TASK_DESC" =~ REFACTOR ]]; then
  if ! pytest api/tests/ -q 2>/dev/null; then
    # VIOLATION: Refactoring with failing tests
    echo "❌ TDD VIOLATION DETECTED"
  fi
fi
```

**Response:**
```markdown
❌ **TDD VIOLATION: REFACTOR With Failing Tests**

**Issue:**
Task $TASK_ID is marked [REFACTOR], but tests are currently failing.

**Test Failures:**
```
FAILED api/tests/test_message.py::test_message_creation - AssertionError
FAILED api/tests/test_message.py::test_message_validation - AttributeError
```

**TDD Rule:**
REFACTOR phase requires all tests to be passing (GREEN state).

**Actions:**
1. Fix failing tests first
2. Get to GREEN state (all tests pass)
3. Then proceed with REFACTOR

Cannot refactor until tests pass.
```

### Violation 3: Implementing before testing

**Detection:**
```bash
# Check if implementation file exists before RED test
if [[ "$TASK_DESC" =~ \[RED\] ]]; then
  # Extract implementation path from task
  if [ -f "$IMPL_PATH" ]; then
    # VIOLATION: Implementation exists before test
    echo "❌ TDD VIOLATION DETECTED"
  fi
fi
```

**Response:**
```markdown
❌ **TDD VIOLATION: Implementation Before Test**

**Issue:**
Task $TASK_ID is marked [RED] (write failing test), but the implementation file already exists:
- api/app/models/message.py (created 5 minutes ago)

**TDD Principle:**
Tests must be written BEFORE implementation.

**Actions:**
Option A: Remove implementation, write test first
Option B: Change task phase from RED to GREEN if implementing
Option C: Keep implementation, but write test to cover it (not true TDD)

Recommended: Option A (follow pure TDD)
```

---

## Test Verification Commands

### Backend (Python/pytest)

**Run RED test (expect failure):**
```bash
cd api
pytest tests/test_message.py -v --tb=short

# Expected output:
# FAILED tests/test_message.py::test_message_creation - ImportError
# OR
# FAILED tests/test_message.py::test_message_creation - NotImplementedError
```

**Run GREEN test (expect pass):**
```bash
cd api
pytest tests/test_message.py -v

# Expected output:
# PASSED tests/test_message.py::test_message_creation
# 1 passed in 0.05s
```

**Run REFACTOR test (expect still pass):**
```bash
cd api
pytest tests/test_message.py -v

# Expected output (same as GREEN):
# PASSED tests/test_message.py::test_message_creation
# 1 passed in 0.05s
```

### Frontend (TypeScript/Jest)

**Run RED test (expect failure):**
```bash
cd apps/app
pnpm test -- MessageForm.test.tsx

# Expected output:
# FAIL src/components/MessageForm.test.tsx
# ● renders message form
#   ReferenceError: MessageForm is not defined
```

**Run GREEN test (expect pass):**
```bash
cd apps/app
pnpm test -- MessageForm.test.tsx

# Expected output:
# PASS src/components/MessageForm.test.tsx
# ✓ renders message form (45 ms)
```

**Run REFACTOR test (expect still pass):**
```bash
cd apps/app
pnpm test -- MessageForm.test.tsx

# Expected output (same as GREEN):
# PASS src/components/MessageForm.test.tsx
# ✓ renders message form (42 ms)
```

---

## Integration with Spec-Flow Workflow

### During /implement Phase

When implementing TDD tasks:

1. **Parse task phase** ([RED], [GREEN→T], [REFACTOR])
2. **Verify prerequisite** phase completed (if GREEN/REFACTOR)
3. **Check test state** (failing for RED, passing for GREEN/REFACTOR)
4. **Block violations** before implementation
5. **Provide guidance** on proper TDD sequence
6. **Verify test output** after implementation

### Task Completion Evidence

**RED Phase Evidence:**
```markdown
✅ T014 [RED]: Write failing test for Message model
  - Evidence: pytest FAILED (ImportError: No module named 'app.models.message') ✓
  - Test file: api/tests/test_message.py
  - Committed: a1b2c3d
```

**GREEN Phase Evidence:**
```markdown
✅ T015 [GREEN→T014]: Implement Message model to pass test
  - Evidence: pytest PASSED (1 passed) ✓
  - Coverage: 92% line (+12%)
  - Committed: d4e5f6g
```

**REFACTOR Phase Evidence:**
```markdown
✅ T016 [REFACTOR]: Improve Message model with base class
  - Evidence: pytest PASSED (1 passed, tests still green) ✓
  - Changes: Extract to TimestampedModel, add __repr__
  - Committed: h7i8j9k
```

---

## Auto-Rollback Prevention

This Skill helps prevent auto-rollback scenarios by catching TDD violations before implementation:

**Prevented Rollbacks:**
1. ❌ GREEN phase without RED test → Caught before implementing
2. ❌ Tests fail after GREEN → Caught before commit
3. ❌ REFACTOR breaks tests → Caught before commit
4. ❌ Implementing before testing → Caught before writing code

**Result:** Fewer rollbacks, less rework, faster development

---

## TDD Workflow Examples

### Example 1: Backend Model (Complete Cycle)

**RED Task:**
```
T014 [RED] Write failing test for Message model
```

**TDD Enforcer Check:**
```markdown
✅ **TDD PHASE: RED**

Ready to write failing test.

**Guidelines:**
1. Create: api/tests/test_message.py
2. Import Message (will fail - doesn't exist yet)
3. Write test for Message creation
4. Run: pytest api/tests/test_message.py -v
5. Expect: FAILED (ImportError or NotImplementedError)
6. Commit: test(red): T014 write failing test for Message model

Proceed with RED phase? (yes)
```

**GREEN Task:**
```
T015 [GREEN→T014] Implement Message model to pass test
```

**TDD Enforcer Check:**
```markdown
✅ **TDD PHASE: GREEN**

**Prerequisite Check:**
✅ RED phase complete: T014 (test exists, currently failing)
✅ Test file found: api/tests/test_message.py
✅ Test output: FAILED (ImportError: No module named 'app.models.message')

**Guidelines:**
1. Create: api/app/models/message.py
2. Implement minimal Message class
3. Run: pytest api/tests/test_message.py -v
4. Expect: PASSED (1 passed)
5. Commit: feat(green): T015 implement Message model to pass test

Proceed with GREEN phase? (yes)
```

**REFACTOR Task:**
```
T016 [REFACTOR] Improve Message model with base class and repr
```

**TDD Enforcer Check:**
```markdown
✅ **TDD PHASE: REFACTOR**

**Prerequisite Check:**
✅ GREEN phase complete: T015 (implementation exists)
✅ Tests passing: pytest PASSED (1 passed in 0.05s)
✅ Safe to refactor

**Refactoring Opportunities:**
- Extract common fields to TimestampedModel base class
- Add __repr__ for better debugging
- Add __str__ for user-friendly display
- Improve type hints

**Guidelines:**
1. Make small changes incrementally
2. Run tests after each change
3. Keep tests green throughout
4. Commit: refactor: T016 improve Message model

Proceed with REFACTOR phase? (yes)
```

---

## TDD Enforcer Rules

1. **RED before GREEN**: Block GREEN phase if no RED test exists or is incomplete
2. **GREEN before REFACTOR**: Block REFACTOR if implementation incomplete or tests failing
3. **Tests must match phase**:
   - RED: Tests fail (ImportError, NotImplementedError, AssertionError)
   - GREEN: Tests pass (all tests green)
   - REFACTOR: Tests stay green (no failures introduced)
4. **Evidence required**: Test output must be provided for each phase
5. **Auto-rollback on violation**: If tests fail after GREEN/REFACTOR, rollback changes
6. **Commit per phase**: Each phase gets its own commit with proper message

---

## Constraints

- **Bash access**: Required to run test commands
- **Read access**: Required to check NOTES.md and tasks.md for completion status
- **Grep access**: Required to parse task markers and test output
- **No file edits**: This Skill only verifies and blocks, doesn't modify code
- **Fast checks**: Verification should complete in <10 seconds

---

## Return Format

**Phase Verification Success:**
```markdown
✅ **TDD PHASE VERIFIED: {PHASE}**

**Prerequisites:**
{LIST_OF_CHECKS_PASSED}

**Ready to proceed** with {PHASE} phase implementation.

Guidelines provided above. Follow TDD sequence.
```

**Phase Verification Failure:**
```markdown
❌ **TDD VIOLATION: {VIOLATION_TYPE}**

**Issue:**
{DESCRIPTION_OF_VIOLATION}

**Required Sequence:**
{CORRECT_TDD_SEQUENCE}

**Actions:**
{LIST_OF_FIXES}

Cannot proceed until TDD sequence is correct.
```

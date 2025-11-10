---
name: implementation-phase
description: "Standard Operating Procedure for /implement phase. Covers tech stack validation (from tech-stack.md), TDD workflow, anti-duplication checks, task execution, and continuous testing. Auto-validates framework/library choices against documented tech stack before implementation."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Implementation Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/implement` command with strict TDD discipline and anti-duplication focus.

**Supporting references**:
- [reference.md](reference.md) - TDD workflow, anti-duplication checklist, common blockers
- [examples.md](examples.md) - Good implementations (tests first) vs bad (tests after)
- [scripts/batch-validator.sh](scripts/batch-validator.sh) - Validates multiple tasks at once

---

## Phase Overview

**Purpose**: Execute tasks from tasks.md using Test-Driven Development, preventing code duplication, and maintaining high quality through continuous testing.

**Inputs**:
- `specs/NNN-slug/tasks.md` - Task breakdown (20-30 tasks)
- `specs/NNN-slug/plan.md` - Implementation plan
- Reuse strategy from planning phase

**Outputs**:
- Implemented code (models, services, API endpoints, UI components)
- Test suites (unit, integration, component, E2E)
- Updated `tasks.md` (task statuses)
- Updated `workflow-state.yaml`

**Expected duration**: Variable (2-10 days depending on feature complexity)

---

## Prerequisites

**Environment checks**:
- [ ] Tasks phase completed (`tasks.md` exists with 20-30 tasks)
- [ ] Plan phase completed (`plan.md` exists)
- [ ] Development environment set up
- [ ] Test framework configured
- [ ] Git working tree clean

**Knowledge requirements**:
- TDD workflow (RED → GREEN → REFACTOR)
- Anti-duplication strategies
- Code review checklist
- Testing best practices

---

## Execution Steps

### Step 1: Review Task List and Dependencies

**Actions**:
1. Read `tasks.md` to understand:
   - Total task count and estimated duration
   - Task dependencies and sequencing
   - Critical path (longest dependency chain)
   - Parallel work opportunities

2. Identify starting tasks:
   - Tasks with no dependencies
   - Foundation tasks (database, models, config)
   - Can execute multiple foundation tasks in parallel

**Quality check**: Do you understand which tasks to start with?

---

### Step 1.5: Load Tech Stack Constraints (NEW - Critical)

**Purpose**: Load documented tech stack from `tech-stack.md` to validate implementation choices and prevent hallucinated tech suggestions.

**When to execute**:
- Always before implementing any task
- Before suggesting alternative libraries or frameworks
- Before importing any new dependencies

**Actions**:

```bash
TECH_STACK_DOC="docs/project/tech-stack.md"
HAS_TECH_STACK=false

if [ -f "$TECH_STACK_DOC" ]; then
  HAS_TECH_STACK=true
  echo "✅ Tech stack documentation found"
  echo ""

  # Read tech stack for validation
  # Claude Code: Read docs/project/tech-stack.md

  # Extract key sections (see extraction logic below)
else
  echo "⚠️  No tech stack documentation found"
  echo "   Run /init-project to document tech stack"
  echo "   (Implementation will proceed without validation)"
  echo ""
fi
```

**Extraction logic** (from tech-stack.md):

```bash
# Extract technology versions from tech stack table
# Format: | Category | Technology | Version | Purpose |

# Backend
BACKEND_FRAMEWORK=$(grep -A 1 "| Backend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
BACKEND_VERSION=$(grep -A 1 "| Backend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# Frontend
FRONTEND_FRAMEWORK=$(grep -A 1 "| Frontend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
FRONTEND_VERSION=$(grep -A 1 "| Frontend" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# Database
DATABASE=$(grep -A 1 "| Database" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
DATABASE_VERSION=$(grep -A 1 "| Database" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $4}' | xargs)

# ORM
ORM=$(grep -A 1 "| ORM" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)

# Testing
BACKEND_TEST_FRAMEWORK=$(grep -A 1 "| Testing" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)
FRONTEND_TEST_FRAMEWORK=$(grep -A 1 "| UI Testing" "$TECH_STACK_DOC" | tail -1 | awk -F'|' '{print $3}' | xargs)

# Store for validation
export BACKEND_FRAMEWORK BACKEND_VERSION FRONTEND_FRAMEWORK FRONTEND_VERSION
export DATABASE DATABASE_VERSION ORM
export BACKEND_TEST_FRAMEWORK FRONTEND_TEST_FRAMEWORK

echo "📋 Tech Stack Constraints (from tech-stack.md):"
echo "   Backend: $BACKEND_FRAMEWORK $BACKEND_VERSION"
echo "   Frontend: $FRONTEND_FRAMEWORK $FRONTEND_VERSION"
echo "   Database: $DATABASE $DATABASE_VERSION"
echo "   ORM: $ORM"
echo "   Testing: $BACKEND_TEST_FRAMEWORK, $FRONTEND_TEST_FRAMEWORK"
echo ""
```

**Example extracted context**:
```
📋 Tech Stack Constraints (from tech-stack.md):
   Backend: FastAPI 0.110.0
   Frontend: Next.js 14.2
   Database: PostgreSQL 16
   ORM: SQLAlchemy 2.0
   Testing: pytest, Playwright
```

**Tech Stack Validation Rules**:

**Rule 1: No alternative frameworks** (BLOCKING)
```bash
# Example violation: Suggesting Django when FastAPI documented
SUGGESTED_FRAMEWORK="Django"

if [ "$HAS_TECH_STACK" = true ] && [ "$SUGGESTED_FRAMEWORK" != "$BACKEND_FRAMEWORK" ]; then
  echo "❌ TECH STACK VIOLATION"
  echo ""
  echo "Documented tech stack:"
  echo "  Backend: $BACKEND_FRAMEWORK (tech-stack.md:12)"
  echo ""
  echo "Suggested implementation:"
  echo "  Backend: $SUGGESTED_FRAMEWORK"
  echo ""
  echo "Options:"
  echo "  A) Use documented tech ($BACKEND_FRAMEWORK)"
  echo "  B) Update tech-stack.md if migrating"
  echo "  C) Reject suggestion (enforce tech stack)"
  echo ""
  echo "BLOCKING: Cannot implement with wrong tech stack"
  exit 1
fi
```

**Rule 2: Version compatibility** (WARNING)
```bash
# Example: Using incompatible library version
SUGGESTED_LIBRARY="pydantic"
SUGGESTED_VERSION="1.10"
DOCUMENTED_VERSION="2.6"  # From tech-stack.md dependencies

MAJOR_SUGGESTED=$(echo "$SUGGESTED_VERSION" | cut -d. -f1)
MAJOR_DOCUMENTED=$(echo "$DOCUMENTED_VERSION" | cut -d. -f1)

if [ "$MAJOR_SUGGESTED" != "$MAJOR_DOCUMENTED" ]; then
  echo "⚠️  VERSION INCOMPATIBILITY DETECTED"
  echo ""
  echo "Documented version:"
  echo "  $SUGGESTED_LIBRARY $DOCUMENTED_VERSION (tech-stack.md:45)"
  echo ""
  echo "Suggested version:"
  echo "  $SUGGESTED_LIBRARY $SUGGESTED_VERSION"
  echo ""
  echo "Major version mismatch may cause breaking changes"
  echo "Review tech-stack.md before proceeding"
  echo ""
fi
```

**Rule 3: Test framework consistency** (BLOCKING)
```bash
# Example: Using wrong test framework
TASK_DESCRIPTION="Write unit tests for StudentProgressService"
SUGGESTED_TEST_FRAMEWORK="unittest"  # Detected from task description

if [ "$HAS_TECH_STACK" = true ] && [ "$SUGGESTED_TEST_FRAMEWORK" != "$BACKEND_TEST_FRAMEWORK" ]; then
  echo "❌ TEST FRAMEWORK VIOLATION"
  echo ""
  echo "Documented test framework:"
  echo "  $BACKEND_TEST_FRAMEWORK (tech-stack.md:23)"
  echo ""
  echo "Suggested in task:"
  echo "  $SUGGESTED_TEST_FRAMEWORK"
  echo ""
  echo "Corrected task description:"
  echo "  'Write unit tests using $BACKEND_TEST_FRAMEWORK for StudentProgressService'"
  echo ""
  echo "BLOCKING: Use documented test framework"
  exit 1
fi
```

**Tech Stack Validation Decision Tree**:

```
Start implementation task
    |
    v
Is tech-stack.md present?
    |-- No --> Proceed without validation (warn user)
    |
    v (Yes)
Extract: Backend, Frontend, Database, ORM, Testing frameworks
    |
    v
Does task suggest different framework?
    |-- Yes --> BLOCK: "Use documented framework or update tech-stack.md"
    |
    v (No)
Does task use incompatible library version?
    |-- Yes --> WARN: "Major version mismatch, review tech-stack.md"
    |
    v (No - or warning acknowledged)
Does task use wrong test framework?
    |-- Yes --> BLOCK: "Use documented test framework"
    |
    v (No)
✅ Validation passed, proceed to TDD workflow
```

**Integration with Hallucination Detector**:

This step works in conjunction with the `hallucination-detector` skill:
- **Hallucination detector**: Prevents suggesting wrong tech during spec/plan phases
- **Tech stack validation**: Enforces correct tech during implementation phase
- **Together**: 100% tech stack compliance across workflow

**Example validation scenarios**:

**Scenario 1: Wrong backend framework** (BLOCKED)
```
Task 5: Implement authentication middleware

Suggested implementation:
  "Use Django middleware for authentication"

❌ TECH STACK VIOLATION

Documented tech stack:
  Backend: FastAPI 0.110.0 (tech-stack.md:12)

Suggested implementation:
  Backend: Django

BLOCKING: Cannot implement with wrong tech stack

✅ Corrected:
  "Use FastAPI middleware for authentication"
```

**Scenario 2: Wrong ORM** (BLOCKED)
```
Task 8: Create Student model

Suggested implementation:
  "Use Django ORM for Student model"

❌ TECH STACK VIOLATION

Documented ORM:
  SQLAlchemy 2.0 (tech-stack.md:18)

Suggested ORM:
  Django ORM

BLOCKING: Use documented ORM (SQLAlchemy)

✅ Corrected:
  "Use SQLAlchemy declarative base for Student model"
```

**Scenario 3: Wrong test framework** (BLOCKED)
```
Task 12: Write unit tests for StudentProgressService

Suggested implementation:
  "Use unittest framework"

❌ TEST FRAMEWORK VIOLATION

Documented test framework:
  pytest (tech-stack.md:23)

Suggested in task:
  unittest

BLOCKING: Use documented test framework

✅ Corrected:
  "Write unit tests using pytest for StudentProgressService"
```

**Scenario 4: Compatible library added** (ALLOWED)
```
Task 15: Add email validation

Suggested library:
  "Install email-validator 2.1.0"

✅ VALIDATION PASSED

Reason:
  - No alternative email library documented
  - Version compatible with Python 3.11 (tech-stack.md:11)
  - No conflicts with documented dependencies

Proceed with implementation
```

**Token budget**: ~5-8K tokens (tech-stack.md is typically 2-4 pages)

**Performance impact**: <10 seconds (one-time read at start of implementation)

**Quality check**: Tech stack constraints loaded, validation rules active

---

### Step 2: Execute Tasks Using TDD Workflow

**For EVERY task, follow strict TDD process**:

#### RED Phase: Write Failing Test

**Actions**:
1. Read task acceptance criteria
2. Write test cases BEFORE any implementation
3. Run tests → verify they FAIL (RED)
4. Commit failing tests

**Example**:
```bash
# Task 8: Write unit tests for StudentProgressService

# 1. Create test file
touch api/app/tests/services/test_student_progress_service.py

# 2. Write test cases
# (Write 5 test cases covering happy path + edge cases)

# 3. Run tests → expect failures
pytest api/app/tests/services/test_student_progress_service.py
# Expected: 5 failed, 0 passed ✓

# 4. Commit
git add api/app/tests/services/test_student_progress_service.py
git commit -m "test: add failing tests for StudentProgressService

Task 8: Write unit tests for StudentProgressService
- calculateProgress() tests (3 cases)
- getRecentActivity() tests (2 cases)
All tests currently failing (RED phase)
"
```

**Quality check**: Tests fail for the right reason (not implemented yet, not syntax errors).

---

#### GREEN Phase: Make Tests Pass

**Actions**:
1. Write minimal code to make tests pass
2. Run tests frequently → work toward GREEN
3. Stop when all tests pass
4. Commit working code

**Anti-duplication checklist BEFORE writing code**:
- [ ] Search for similar functions in codebase
- [ ] Review reuse strategy from plan.md
- [ ] Check for base classes to extend
- [ ] Look for utility functions to reuse

**Example**:
```bash
# Task 9: Implement StudentProgressService

# 1. Check for code reuse opportunities
grep -r "def calculate" api/app/services/*.py
grep -r "BaseService" api/app/services/*.py

# 2. Implement service (reusing BaseService pattern)
# (Write StudentProgressService class)

# 3. Run tests → work toward passing
pytest api/app/tests/services/test_student_progress_service.py
# First run: 3 failed, 2 passed
# Second run: 1 failed, 4 passed
# Final run: 0 failed, 5 passed ✓

# 4. Commit
git add api/app/services/student_progress_service.py
git commit -m "feat: implement StudentProgressService

Task 9: Implement StudentProgressService
- calculateProgress() method
- getRecentActivity() method
- Reuses BaseService pattern
All 5 tests passing (GREEN phase)
"
```

**Quality check**: All tests pass, no code duplication, follows existing patterns.

---

#### REFACTOR Phase: Clean Up While Keeping Tests Green

**Actions**:
1. Improve code quality without changing behavior
2. Run tests after EACH refactor → stay GREEN
3. Extract common logic to utilities
4. Add type hints, improve naming
5. Commit refactored code

**Refactoring checklist**:
- [ ] Remove code duplication
- [ ] Extract magic numbers to constants
- [ ] Improve variable/function names
- [ ] Add type hints
- [ ] Add docstrings
- [ ] Simplify complex conditionals

**Example**:
```bash
# Task 10: Refactor StudentProgressService

# 1. Extract common calculation logic
# Before: completion_rate = len(completed) / len(total)
# After: completion_rate = calculate_percentage(completed, total)

# 2. Run tests after each change
pytest api/app/tests/services/test_student_progress_service.py
# Still: 0 failed, 5 passed ✓

# 3. Commit refactor
git add api/app/services/student_progress_service.py api/app/utils/math.py
git commit -m "refactor: extract percentage calculation to utility

Task 10: Refactor StudentProgressService
- Extracted calculate_percentage() to utils/math.py
- Added type hints to all methods
- Improved variable names (comp_rate → completion_rate)
All tests still passing (REFACTOR phase)
"
```

**Quality check**: Tests still pass, code is cleaner, no behavior changes.

---

### Step 3: Update Task Status

**Actions**:
After completing each task:

1. Mark task as complete in `tasks.md`:
   ```markdown
   ### Task 9: Implement StudentProgressService ✅

   **Status**: Completed
   **Completion date**: 2025-10-21
   **Actual time**: 6 hours (estimated: 6-8 hours)

   **Acceptance criteria**:
   - [x] All 5 unit tests from Task 8 pass
   - [x] No code duplication (reuses BaseService)
   - [x] Follows existing service patterns
   - [x] Type hints on all methods
   ```

2. Commit task status update:
   ```bash
   git add specs/NNN-slug/tasks.md
   git commit -m "chore: mark Task 9 as complete"
   ```

**Quality check**: Task marked complete only when ALL acceptance criteria met.

---

### Step 4: Continuous Anti-Duplication Checks

**Before implementing any new function/class, run these checks**:

1. **Search for similar code**:
   ```bash
   # Search by function name pattern
   grep -r "def calculate" api/app/**/*.py

   # Search by purpose keywords
   grep -r "completion.*rate" api/app/**/*.py

   # Search in plan.md for reuse strategy
   grep "Reuse Strategy" specs/NNN-slug/plan.md
   ```

2. **If similar code exists**:
   - Extract to shared utility module
   - Update existing code to use utility
   - Document reuse in commit message

3. **If creating new reusable pattern**:
   - Place in appropriate shared location (utils/, shared/, common/)
   - Add unit tests for utility
   - Document in plan.md reuse strategy

**Quality check**: No duplicate logic, high reuse rate (≥60% for standard features).

---

### Step 5: Run Tests Continuously

**Test frequency guidelines**:

**After every code change** (TDD discipline):
```bash
# Run specific test file
pytest api/app/tests/services/test_student_progress_service.py

# Run with coverage
pytest --cov=api/app/services api/app/tests/services/
```

**After completing each task**:
```bash
# Run all tests in category
pytest api/app/tests/services/  # All service tests
pytest api/app/tests/routes/    # All API tests
npm test src/components/        # All component tests
```

**Before committing**:
```bash
# Run full test suite
pytest
npm test

# Check coverage
pytest --cov=api --cov-report=term-missing
npm test -- --coverage
```

**Quality check**: All tests pass before committing, coverage ≥80% for business logic.

---

### Step 6: Handle Blocked Tasks

**If task is blocked**:

1. **Identify blocker**:
   - Missing dependency (another task not complete)?
   - Unclear requirement (needs clarification)?
   - Technical issue (environment, library, etc.)?

2. **Document blocker** in tasks.md:
   ```markdown
   ### Task 15: Implement Progress API Endpoint

   **Status**: Blocked
   **Blocked by**: Task 9 (StudentProgressService not complete)
   **Blocked date**: 2025-10-21
   ```

3. **Move to next task**:
   - Find tasks with satisfied dependencies
   - Work on parallel path
   - Return to blocked task when unblocked

**Quality check**: Blocked tasks documented, alternative tasks identified.

---

### Step 7: Integration Testing

**After completing related tasks, run integration tests**:

**Example** (after API endpoint implemented):
```bash
# Task 16 complete → run integration tests
pytest api/app/tests/integration/test_student_progress_api.py

# Expected results:
# - 200 response with valid student ID ✓
# - 404 response with invalid ID ✓
# - 403 response without auth ✓
# - 400 response with invalid params ✓
# - Response time <500ms ✓
```

**Quality check**: All integration tests pass, response times meet targets.

---

### Step 8: UI Component Testing (if HAS_UI=true)

**After implementing UI components, run component tests**:

**Example**:
```bash
# Task 23 complete → run component tests
npm test src/pages/ProgressDashboard.test.tsx

# Expected results:
# - Renders loading state ✓
# - Renders chart with data ✓
# - Handles error state ✓
# - Date filter works ✓
# - Keyboard navigation works ✓

# Run Lighthouse for accessibility
npx lighthouse http://localhost:3000/progress --only-categories=accessibility
# Expected: Score ≥95
```

**Quality check**: All component tests pass, accessibility score ≥95.

---

### Step 9: End-to-End Testing

**After completing all implementation tasks, run E2E tests**:

**Example**:
```bash
# All tasks 1-26 complete → run E2E tests
npx playwright test e2e/progress-dashboard.spec.ts

# Expected user flow:
# 1. User logs in ✓
# 2. Navigates to student list ✓
# 3. Clicks "View Progress" ✓
# 4. Dashboard loads ✓
# 5. Filters by 7-day period ✓
# 6. Chart updates ✓
```

**Quality check**: Top 3 user journeys work end-to-end.

---

### Step 10: Code Review Checklist

**Before marking implementation phase complete, review**:

**Code quality**:
- [ ] No code duplication
- [ ] Follows existing patterns
- [ ] Type hints on all functions
- [ ] Docstrings on public APIs
- [ ] No magic numbers (use constants)
- [ ] Meaningful variable names

**Testing**:
- [ ] Test coverage ≥80% for business logic
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All component tests pass (if HAS_UI)
- [ ] E2E tests pass

**Performance**:
- [ ] API response times <500ms (95th percentile)
- [ ] Database queries optimized (indexes added)
- [ ] No N+1 query problems

**Security**:
- [ ] Authentication/authorization implemented
- [ ] Input validation on all endpoints
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities (if HAS_UI)

**Accessibility** (if HAS_UI):
- [ ] Lighthouse score ≥95
- [ ] Keyboard navigation works
- [ ] Screen reader compatible (ARIA labels)

**Quality check**: All checklist items satisfied.

---

### Step 11: Final Validation

**Actions**:
1. Run full test suite:
   ```bash
   # Backend tests
   pytest --cov=api --cov-report=term-missing

   # Frontend tests
   npm test -- --coverage

   # E2E tests
   npx playwright test
   ```

2. Verify all tasks complete:
   ```bash
   grep "Status: Completed" specs/NNN-slug/tasks.md | wc -l
   # Expected: 28 (all tasks)
   ```

3. Update workflow state:
   ```bash
   # Update workflow-state.yaml
   currentPhase: implementation
   status: completed
   completedAt: 2025-10-21T14:30:00Z
   ```

**Quality check**: All tests pass, all tasks complete, workflow state updated.

---

### Step 12: Commit Implementation

**Actions**:
```bash
git add .
git commit -m "feat: complete implementation for <feature-name>

Completed 28 tasks:
- Foundation: 3 tasks ✓
- Data layer: 4 tasks ✓
- Business logic: 6 tasks ✓
- API layer: 6 tasks ✓
- UI layer: 6 tasks ✓
- Testing: 3 tasks ✓

Test results:
- Unit tests: 45 passed
- Integration tests: 12 passed
- Component tests: 18 passed
- E2E tests: 3 passed
- Coverage: 87%

🤖 Generated with [Claude Code](https://claude.com/claude-code)
"
```

**Quality check**: Implementation committed with comprehensive summary.

---

## Common Mistakes to Avoid

### 🚫 Implementation Without Tests (Skipping RED Phase)

**Impact**: Unverified code, regression risk, poor test coverage

**Bad workflow**:
```
1. Implement StudentProgressService
2. Write tests afterward (if at all)
Result: Tests don't catch real bugs, coverage gaps
```

**Correct TDD workflow**:
```
1. Write failing tests (RED)
2. Implement to pass tests (GREEN)
3. Refactor while tests pass (REFACTOR)
Result: High confidence, comprehensive coverage
```

**Prevention**:
- ALWAYS write test task before implementation task
- Commit failing tests before any implementation
- Run tests continuously (after every small change)

---

### 🚫 Duplicate Code Written

**Impact**: Technical debt, maintenance burden, inconsistent behavior

**Scenario**:
```
Task: Implement calculateCompletion() for student progress
Action: Writes new function from scratch
Existing: Similar calculateProgress() exists in 3 other modules
Result: 4th duplicate implementation
```

**Prevention**:
1. Search codebase BEFORE implementing anything new
2. Review reuse strategy from plan.md
3. Extract common logic to shared utilities
4. Target: ≥60% code reuse rate

**Anti-duplication checklist**:
```bash
# Before implementing, search for similar code
grep -r "def calculate.*completion" api/
grep -r "completion.*rate" api/

# Check plan.md reuse strategy
grep "Reuse Strategy" specs/NNN-slug/plan.md
```

---

### 🚫 Tests Written After Code

**Impact**: Tests don't catch real bugs, false confidence

**Why it's bad**:
- Tests designed to pass existing code (not verify behavior)
- Miss edge cases that TDD would catch
- Can't refactor confidently

**Prevention**: Enforce RED → GREEN → REFACTOR discipline

---

### 🚫 Large Commits Without Context

**Impact**: Hard to review, hard to revert, unclear history

**Bad commit**:
```bash
git commit -m "implement feature"
# Changed: 15 files, +2000 lines, -500 lines
```

**Good commits** (small, focused):
```bash
git commit -m "test: add failing tests for StudentProgressService (Task 8)"
# Changed: 1 file, +85 lines

git commit -m "feat: implement StudentProgressService (Task 9)"
# Changed: 1 file, +120 lines

git commit -m "refactor: extract percentage calculation to utility (Task 10)"
# Changed: 2 files, +15 lines, -10 lines
```

**Prevention**: Commit after each task (or even more frequently)

---

### 🚫 Skipping Tests Before Committing

**Impact**: Broken code committed, CI fails, blocks team

**Prevention**:
```bash
# Pre-commit hook (add to .git/hooks/pre-commit)
#!/bin/bash
pytest
npm test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

---

### 🚫 Ignoring Blocked Tasks

**Impact**: Tasks forgotten, feature incomplete

**Prevention**:
- Document blockers explicitly in tasks.md
- Set reminders to check blocked tasks
- Escalate blockers that can't be resolved quickly

---

## Best Practices

### ✅ TDD Workflow Example

**Perfect TDD execution**:

```markdown
## Task 8-10: StudentProgressService (TDD Triplet)

### Task 8: Write Tests (RED)
1. Create test file with 5 test cases
2. Run tests → all fail (expected)
3. Commit: "test: add failing tests for StudentProgressService"

### Task 9: Implement (GREEN)
1. Check for code reuse opportunities (BaseService, utilities)
2. Write minimal code to pass tests
3. Run tests frequently → work toward all passing
4. Commit: "feat: implement StudentProgressService"

### Task 10: Refactor (REFACTOR)
1. Extract common logic to utilities
2. Add type hints and docstrings
3. Improve names and structure
4. Run tests after EACH change → stay green
5. Commit: "refactor: extract percentage calculation"
```

**Result**: High confidence, clean code, comprehensive tests

---

### ✅ Anti-Duplication Search Pattern

**Before writing ANY new function**:

```bash
# 1. Search by name pattern
grep -r "def calculate" api/app/**/*.py

# 2. Search by purpose
grep -r "completion.*rate" api/

# 3. Search by similar functionality
grep -r "percentage" api/app/utils/*.py

# 4. Check plan.md reuse strategy
grep -A 10 "Existing patterns to leverage" specs/NNN-slug/plan.md

# 5. If found → reuse or extract
# If not found → implement and document as new reusable pattern
```

---

### ✅ Continuous Testing Cadence

**Test at multiple levels**:

| When | What to Run | Why |
|------|-------------|-----|
| After each small change | Single test file | Immediate feedback, stay in flow |
| After completing task | Test category (all service tests) | Verify task complete, no regressions |
| Before committing | Full test suite | Ensure nothing broken |
| Before PR | Full suite + E2E + coverage | Ready for review |

---

### ✅ Commit Message Template

**Use consistent format**:

```
<type>: <short summary> (Task N)

<detailed description>
- Bullet point 1
- Bullet point 2

<test results or metrics>
```

**Types**:
- `test:` - Test file additions/changes
- `feat:` - New feature implementation
- `refactor:` - Code cleanup without behavior change
- `fix:` - Bug fix
- `chore:` - Task status update, tooling

**Example**:
```
feat: implement GET /api/v1/students/{id}/progress (Task 16)

Implemented API endpoint for student progress dashboard.
- Route in routes/students.py
- Authentication with @require_teacher
- Validation of student_id and period params
- Calls StudentProgressService
- Returns JSON per OpenAPI schema
- Error handling (404, 403, 400)

Test results: All 5 integration tests passing
Response time: 287ms (95th percentile, 500 lessons) ✓
```

---

## Phase Checklist

**Pre-phase checks**:
- [ ] Tasks phase completed (tasks.md exists)
- [ ] Plan phase completed (plan.md exists)
- [ ] Development environment set up
- [ ] Test framework configured
- [ ] Git working tree clean

**During phase** (for EACH task):
- [ ] RED: Write failing tests first
- [ ] GREEN: Implement to pass tests
- [ ] REFACTOR: Clean up while staying green
- [ ] Anti-duplication check performed
- [ ] Tests run and passing
- [ ] Task status updated in tasks.md
- [ ] Changes committed

**Post-phase validation**:
- [ ] All tasks complete (20-30 tasks)
- [ ] All tests pass (unit + integration + component + E2E)
- [ ] Test coverage ≥80% for business logic
- [ ] Code review checklist satisfied
- [ ] No code duplication
- [ ] Performance targets met
- [ ] Security checklist satisfied
- [ ] Accessibility score ≥95 (if HAS_UI)
- [ ] Implementation committed
- [ ] workflow-state.yaml updated

---

## Quality Standards

**Implementation quality targets**:
- Test coverage: ≥80% for business logic
- Code reuse rate: ≥60%
- TDD adherence: 100% (all tests before implementation)
- Code duplication: <5%
- Performance: API <500ms, UI FCP <1.5s
- Accessibility: Lighthouse ≥95 (if HAS_UI)

**What makes good implementation**:
- Strict TDD discipline (RED → GREEN → REFACTOR)
- High code reuse (leverages existing patterns)
- Comprehensive test coverage (≥80%)
- Clean, readable code (type hints, docstrings, good names)
- No duplication (<5%)
- Meets performance targets

**What makes bad implementation**:
- Tests after code (or no tests)
- Code duplication (reinventing wheels)
- Poor test coverage (<60%)
- Unclear code (no types, cryptic names)
- Performance issues (slow queries, heavy renders)
- Accessibility failures (if HAS_UI)

---

## Completion Criteria

**Phase is complete when**:
- [ ] All pre-phase checks passed
- [ ] All tasks completed (100%)
- [ ] All tests passing (unit + integration + component + E2E)
- [ ] Code review checklist satisfied
- [ ] Implementation committed
- [ ] workflow-state.yaml shows `currentPhase: implementation` and `status: completed`

**Ready to proceed to next phase** (`/optimize` or `/ship`):
- [ ] Feature works end-to-end
- [ ] All acceptance criteria met
- [ ] Test coverage ≥80%
- [ ] No critical issues

---

## Troubleshooting

**Issue**: Tests fail unexpectedly
**Solution**: Run tests in isolation, check for test pollution, verify test fixtures, review test output carefully

**Issue**: Can't find code to reuse
**Solution**: Use scripts/verify-reuse.sh, search with broader keywords, review plan.md reuse strategy, ask for code review

**Issue**: Task blocked by dependency
**Solution**: Document blocker in tasks.md, work on parallel tasks, escalate if blocker can't be resolved

**Issue**: Performance targets not met
**Solution**: Profile code, add database indexes, optimize queries, implement caching, review plan.md performance strategy

**Issue**: Test coverage below 80%
**Solution**: Identify untested paths with coverage report, add missing test cases, focus on business logic

---

_This SOP guides the implementation phase. Refer to reference.md for TDD details and examples.md for code patterns._

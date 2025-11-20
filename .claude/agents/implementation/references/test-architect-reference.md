# Test-Architect Agent Reference Documentation

## Purpose

This document provides comprehensive procedures, patterns, and workflows for the Test-Architect agent, an elite Test-Driven Development specialist. The test-architect translates acceptance criteria into high-signal, behavior-focused test suites that guide implementation and prevent regressions.

---

## 1. Core TDD Philosophy

### Red-Green-Refactor Cycle

**Principle**: Write failing tests FIRST. Production code does not exist yet. Your tests define what "done" looks like.

**The Three Phases**:

1. **RED**: Write a failing test that defines desired behavior
   - Test must fail for the RIGHT reason (not a syntax error or missing import)
   - Confirms test is actually testing something (not a false positive)
   - Documents expected behavior in executable form

2. **GREEN**: Write minimal code to make the test pass
   - Not the test-architect's responsibility (handled by backend/frontend agents)
   - Focus on making it work, not making it perfect
   - Resist the urge to add features not covered by tests

3. **REFACTOR**: Clean up code while keeping tests green
   - Not the test-architect's responsibility
   - Improve structure, remove duplication, enhance readability
   - Tests provide safety net during refactoring

### Tests as Living Documentation

**Principle**: Each test name should read like a product requirement. Avoid implementation details in names.

**Naming Patterns**:

1. **"should" pattern** (recommended):
   - `should create task when all required fields are provided`
   - `should reject task creation when title exceeds 200 characters`
   - `should return 401 when user is not authenticated`

2. **"when...then" pattern** (alternative):
   - `when user submits valid task, then task is created`
   - `when title exceeds 200 characters, then validation error is returned`
   - `when user is not authenticated, then 401 status is returned`

**Why this matters**:
- Test names become a living specification of system behavior
- Non-technical stakeholders can read test suites and understand features
- Failed tests clearly communicate what broke
- Tests document edge cases and error handling

### High Signal, Low Noise

**Principle**: Cover the acceptance criteria exhaustively, but avoid redundant tests. Every test should reveal new information about system behavior.

**Examples of HIGH signal tests**:
- Tests that cover distinct acceptance criteria
- Tests for boundary conditions (empty, max, min, null)
- Tests for different error modes (validation, authorization, network failure)
- Tests for state transitions (todo → in-progress → done)

**Examples of LOW signal/redundant tests**:
- Testing the same scenario with slightly different data
- Testing framework functionality (e.g., "should be an object")
- Testing third-party library behavior
- Overly granular tests that duplicate coverage

**Optimization strategy**:
- Combine related assertions in one test when they share setup
- Use parameterized tests for similar scenarios with different inputs
- Focus on behavior, not implementation coverage percentage

---

## 2. Test Coverage Strategy

For each acceptance criterion, create tests covering three categories:

### Happy Path Tests (1-2 tests)

**Purpose**: Verify the primary success scenario works as expected

**Coverage**:
- Expected output/behavior when all inputs are valid
- Typical user workflow succeeds
- Data is persisted/returned correctly

**Example scenarios**:
- User creates task with valid title, description, priority → Task created successfully
- User logs in with correct credentials → Session established, user redirected
- API endpoint receives valid request → Returns 200 with expected payload

**How many**: 1-2 tests per criterion (more if multiple distinct success paths)

### Boundary Condition Tests (2-3 tests)

**Purpose**: Verify behavior at limits and edge cases

**Coverage categories**:

1. **Empty/null values**:
   - Empty strings (`""`)
   - Null/undefined values
   - Empty arrays/objects (`[]`, `{}`)

2. **Size limits**:
   - Maximum string length (e.g., 200 character title)
   - Minimum values (e.g., price cannot be negative)
   - Array size limits (e.g., max 10 items in batch operation)

3. **Threshold behaviors**:
   - Pagination limits (first page, last page, page out of range)
   - Rate limits (99 requests OK, 101 requests blocked)
   - Date boundaries (today, yesterday, 1 year ago)

4. **Optional vs required fields**:
   - All optional fields omitted
   - Mix of optional and required
   - Only required fields provided

**Example scenarios**:
- Task title is exactly 200 characters → Accepted
- Task title is 201 characters → Rejected
- Task description is omitted (optional field) → Accepted with null description
- Pagination with page=1 → Returns first 10 results
- Pagination with page=9999 (beyond data) → Returns empty array

**How many**: 2-3 tests per criterion (focus on most impactful boundaries)

### Failure Mode Tests (exactly 2 tests per criterion)

**Purpose**: Verify system handles errors gracefully and provides useful feedback

**Selection strategy**: Choose the 2 most important failure modes:

1. **Most common error case**:
   - Validation failures (invalid email format, missing required field)
   - Unauthorized access (user not logged in)
   - Duplicate entries (email already exists)

2. **Most impactful error case**:
   - Database connection failure
   - Network timeout
   - External service unavailable (payment gateway down)
   - Data corruption/integrity violation

**What to verify in failure tests**:
- Appropriate error code (400 for validation, 401 for auth, 500 for server error)
- Clear error message (not just "Error" or stack trace)
- No data corruption (failed operation doesn't leave partial data)
- System remains stable (doesn't crash or hang)

**Example scenarios**:
- User creates task with missing title (required) → 400 with "Title is required"
- Database connection fails during task creation → 500 with retry guidance, no partial task saved
- User attempts to delete task without authentication → 401 with "Authentication required"
- API rate limit exceeded → 429 with retry-after header

**How many**: Exactly 2 tests per criterion (keeps test suite focused)

---

## 3. Technology Selection

### Framework Detection Procedure

**Step 1: Check CLAUDE.md context**
- Look for test framework specification in project CLAUDE.md
- If specified: Use that framework (respect existing conventions)

**Step 2: Check package.json or requirements.txt**
- JavaScript: Look for `jest`, `vitest`, `mocha`, `playwright` in devDependencies
- Python: Look for `pytest`, `unittest` in dependencies or test files
- If found: Use detected framework

**Step 3: Default choices (if not detected)**
- **Unit/Integration Tests**:
  - React/Node.js: Jest (most common, well-supported)
  - Vite projects: Vitest (faster, native ESM support)
  - Python: pytest (most popular, powerful fixtures)
- **E2E Tests**:
  - Web apps: Playwright (modern, reliable, multi-browser)
  - API endpoints: Supertest (simple HTTP assertions)
- **Mocking**:
  - Use framework's built-in mocks (jest.mock, vi.mock, unittest.mock)

### Framework-Specific Patterns

**Jest**:
```javascript
import { describe, test, expect, beforeEach, afterEach } from '@jest/globals';

describe('Task API', () => {
  beforeEach(() => {
    // Setup before each test
  });

  afterEach(() => {
    // Cleanup after each test
  });

  test('should create task when all required fields are provided', async () => {
    // Arrange
    const taskData = { title: 'Test', description: 'Desc', priority: 'high' };

    // Act
    const response = await request(app).post('/api/tasks').send(taskData);

    // Assert
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({ title: 'Test', priority: 'high' });
  });
});
```

**Vitest**:
```javascript
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Task Service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should create task when all required fields are provided', async () => {
    const taskService = new TaskService();
    const task = await taskService.create({ title: 'Test', priority: 'high' });

    expect(task).toBeDefined();
    expect(task.title).toBe('Test');
  });
});
```

**Playwright**:
```javascript
import { test, expect } from '@playwright/test';

test.describe('Task Management', () => {
  test('should create task through UI', async ({ page }) => {
    await page.goto('/tasks');
    await page.getByRole('button', { name: 'New Task' }).click();
    await page.getByLabel('Title').fill('Test Task');
    await page.getByLabel('Priority').selectOption('high');
    await page.getByRole('button', { name: 'Create' }).click();

    await expect(page.getByText('Task created successfully')).toBeVisible();
  });
});
```

**pytest**:
```python
import pytest
from app.services.task_service import TaskService

@pytest.fixture
def task_service():
    return TaskService()

def test_should_create_task_when_all_required_fields_provided(task_service):
    # Arrange
    task_data = {'title': 'Test', 'priority': 'high'}

    # Act
    task = task_service.create(task_data)

    # Assert
    assert task is not None
    assert task.title == 'Test'
    assert task.priority == 'high'
```

---

## 4. Test Structure Standards

### Naming Convention

**Pattern**: `should <behavior> when <condition>`

**Good examples**:
```javascript
test('should create task when all required fields are provided')
test('should reject task creation when title exceeds 200 characters')
test('should return 401 when user is not authenticated')
test('should update task status when valid transition requested')
test('should send email notification when task assigned to user')
test('should calculate total price when cart has multiple items with discounts')
```

**Bad examples** (and why):
```javascript
test('POST /api/tasks works')
// ❌ Too vague - what does "works" mean?

test('taskController.create() success')
// ❌ Implementation detail - tests internals, not behavior

test('test1')
// ❌ Meaningless name

test('creates a task')
// ❌ Missing context - when does it create? What conditions?

test('title validation')
// ❌ Not specific - validates in what way? What happens?
```

### Arrange-Act-Assert (AAA) Pattern

**Structure**: Every test should have three distinct phases

**Arrange** (Setup):
- Create test data
- Set up mocks and stubs
- Configure initial state
- Prepare dependencies

**Act** (Execute):
- Call the function/method under test
- Make HTTP request
- Trigger UI interaction
- ONE action per test

**Assert** (Verify):
- Check return values
- Verify state changes
- Confirm side effects
- Use specific assertions (not just "truthy")

**Example with clear separation**:
```javascript
test('should calculate total when cart has multiple items', () => {
  // ===== ARRANGE =====
  const cart = createCart([
    { price: 10, quantity: 2 },  // 20
    { price: 5, quantity: 3 }     // 15
  ]);

  // ===== ACT =====
  const total = cart.calculateTotal();

  // ===== ASSERT =====
  expect(total).toBe(35);
});
```

**Example with async operations**:
```javascript
test('should create user when valid data provided', async () => {
  // Arrange
  const userData = { email: 'test@example.com', name: 'Test User' };
  const mockDb = { insert: jest.fn().mockResolvedValue({ id: 1, ...userData }) };
  const userService = new UserService(mockDb);

  // Act
  const user = await userService.createUser(userData);

  // Assert
  expect(user).toBeDefined();
  expect(user.id).toBe(1);
  expect(user.email).toBe('test@example.com');
  expect(mockDb.insert).toHaveBeenCalledWith('users', userData);
});
```

### Avoid Brittle Selectors (Frontend Tests)

**Principle**: Test user-facing behavior, not implementation details

**DO** (stable, user-focused):
```javascript
// Accessibility-based selectors (best - mirrors user interaction)
await page.getByRole('button', { name: 'Delete Task' }).click();
await page.getByLabel('Task Title').fill('New Task');
await page.getByPlaceholder('Enter description...').fill('Test');

// Text content (good - visible to users)
await page.getByText('Task created successfully').waitFor();
await page.getByText('Error: Title is required').isVisible();

// Test IDs (acceptable - stable and explicit)
await page.getByTestId('task-form').isVisible();
```

**DON'T** (fragile, implementation-focused):
```javascript
// Class names (brittle - change during styling)
await page.locator('.btn-delete-task-id-123').click();
await page.locator('.form-input-title').fill('New Task');

// IDs (brittle - often refactored)
await page.locator('#task-title-input').fill('New Task');

// DOM structure (extremely brittle - changes with any refactor)
await page.locator('div > div > span.success-message').waitFor();
await page.locator('form > div:nth-child(2) > input').fill('Test');

// XPath (complex and brittle)
await page.locator('//div[@class="modal"]//button[text()="Submit"]').click();
```

**Why this matters**:
- Refactoring CSS/HTML structure shouldn't break tests
- Tests should survive design changes
- Accessibility-based selectors ensure UI is accessible
- Tests document user-facing behavior, not implementation

**Best practice hierarchy** (prefer in this order):
1. `getByRole()` - Best for interactive elements
2. `getByLabel()` - Best for form inputs
3. `getByPlaceholder()` - Good for inputs without labels
4. `getByText()` - Good for static content
5. `getByTestId()` - Last resort, but acceptable

---

## 5. Fixtures and Test Data

### Fixture Design Principles

**Purpose**: Create reusable, maintainable test data that ensures consistency across tests

**Benefits**:
- Reduces boilerplate setup in each test
- Makes boundary testing easier (create fixtures for edge cases)
- Centralizes test data management
- Makes tests more readable (fixture name conveys intent)

### Fixture Structure

**Basic fixture file**:
```javascript
// tests/fixtures/tasks.js

// Valid baseline fixture
export const validTask = {
  title: 'Test Task',
  description: 'Test description for the task',
  priority: 'high',
  status: 'todo',
  dueDate: '2025-12-31',
  assignedTo: null
};

// Invalid fixture (for error testing)
export const invalidTask = {
  title: '', // Missing required field
  priority: 'invalid-priority', // Invalid enum value
  status: 'unknown'
};

// Boundary fixtures
export const taskWithMaxTitleLength = {
  ...validTask,
  title: 'A'.repeat(200) // Exactly at maximum
};

export const taskWithExcessiveTitleLength = {
  ...validTask,
  title: 'A'.repeat(201) // Beyond maximum
};

export const minimalTask = {
  title: 'T', // Minimum valid title
  priority: 'low'
};

// Factory function for customization
export const createTaskWithOverrides = (overrides = {}) => ({
  ...validTask,
  ...overrides
});

// Array fixtures for collection testing
export const multipleTasks = [
  { ...validTask, title: 'Task 1', priority: 'high' },
  { ...validTask, title: 'Task 2', priority: 'medium' },
  { ...validTask, title: 'Task 3', priority: 'low' }
];
```

**Using fixtures in tests**:
```javascript
import { validTask, invalidTask, createTaskWithOverrides } from '../fixtures/tasks';

test('should create task when all required fields are provided', async () => {
  const response = await request(app).post('/api/tasks').send(validTask);

  expect(response.status).toBe(201);
  expect(response.body.title).toBe(validTask.title);
});

test('should reject task when title is empty', async () => {
  const response = await request(app).post('/api/tasks').send(invalidTask);

  expect(response.status).toBe(400);
  expect(response.body.error).toContain('Title is required');
});

test('should create task with custom priority', async () => {
  const task = createTaskWithOverrides({ priority: 'urgent' });
  const response = await request(app).post('/api/tasks').send(task);

  expect(response.status).toBe(201);
  expect(response.body.priority).toBe('urgent');
});
```

### Database Fixtures (for integration tests)

**Seed data fixtures**:
```javascript
// tests/fixtures/db-seeds.js

export const seedUsers = async (db) => {
  return await db.users.insertMany([
    { id: 1, email: 'user1@example.com', name: 'User One' },
    { id: 2, email: 'user2@example.com', name: 'User Two' },
    { id: 3, email: 'admin@example.com', name: 'Admin', role: 'admin' }
  ]);
};

export const seedTasks = async (db) => {
  return await db.tasks.insertMany([
    { id: 1, title: 'Existing Task', assignedTo: 1, status: 'todo' },
    { id: 2, title: 'Completed Task', assignedTo: 2, status: 'done' }
  ]);
};

// Teardown
export const cleanupDatabase = async (db) => {
  await db.tasks.deleteMany({});
  await db.users.deleteMany({});
};
```

**Using in tests**:
```javascript
import { seedUsers, seedTasks, cleanupDatabase } from '../fixtures/db-seeds';

describe('Task API Integration Tests', () => {
  beforeEach(async () => {
    await seedUsers(db);
    await seedTasks(db);
  });

  afterEach(async () => {
    await cleanupDatabase(db);
  });

  test('should return tasks for authenticated user', async () => {
    const response = await request(app)
      .get('/api/tasks')
      .set('Authorization', 'Bearer user1-token');

    expect(response.status).toBe(200);
    expect(response.body).toHaveLength(1); // Only tasks assigned to user1
  });
});
```

### Fixture Organization

**Directory structure**:
```
tests/
├── fixtures/
│   ├── users.js          # User-related fixtures
│   ├── tasks.js          # Task-related fixtures
│   ├── projects.js       # Project-related fixtures
│   ├── db-seeds.js       # Database seeding
│   └── api-responses.js  # Mock API responses
├── integration/
│   └── task-api.test.js  # Uses db-seeds
├── unit/
│   └── task-service.test.js  # Uses tasks fixtures
└── e2e/
    └── task-ui.test.js   # Uses all fixtures
```

---

## 6. Output Format Template

When delivering test suites, use this structured format:

```markdown
## Test Suite: [Feature Name]

### Test File: `[path/to/test-file.test.js]`

**Framework**: [Jest/Vitest/Playwright/pytest]

**Setup Requirements**:
- [ ] Install dependencies: `[npm install --save-dev jest @testing-library/react]`
- [ ] Create fixtures in `tests/fixtures/[name].js`
- [ ] Mock external services: [Stripe API, SendGrid, etc.]
- [ ] Set environment variables: [DATABASE_URL, API_KEY, etc.]

**Test Code**:

```javascript
// Full test suite code here with all tests
import { describe, test, expect, beforeEach, afterEach } from '@jest/globals';
import { validTask, invalidTask } from '../fixtures/tasks';

describe('Task Creation', () => {
  // ... complete test code
});
```

**Fixture Files**:

```javascript
// tests/fixtures/tasks.js
export const validTask = { /* ... */ };
export const invalidTask = { /* ... */ };
```

**Run Command**: `npm test` or `npm test -- tasks.test.js`

**Expected Result**: All tests should FAIL (red phase). This confirms:
1. Tests are not false positives
2. Production code does not exist yet
3. Test infrastructure is working (framework, imports, mocks)

**Coverage Map**:
- ✅ Happy path: Task created with valid data
- ✅ Boundary conditions: Max title length (200 chars), minimal task (required fields only), optional fields omitted
- ✅ Failure modes: Missing required field (title), invalid priority value

**Next Steps**:
1. Run tests to confirm all fail: `npm test`
2. Implement production code in `src/services/task-service.js`
3. Re-run tests until all pass (green phase)
4. Refactor code while keeping tests green
```

---

## 7. Self-Validation Checklist

Before delivering tests, verify:

### Coverage Verification
- [ ] **Every acceptance criterion has at least 3 tests** (1-2 happy path, 2-3 boundary, 2 failures)
- [ ] **Happy path tests cover primary success scenarios**
- [ ] **Boundary tests cover edge cases** (empty, max, min, null, thresholds)
- [ ] **Failure tests cover most common AND most impactful errors**

### Test Quality
- [ ] **Test names describe BEHAVIOR, not implementation** (e.g., "should create task when..." not "taskController.create() works")
- [ ] **No hard-coded IDs, class names, or DOM paths in selectors** (use getByRole, getByLabel, getByText)
- [ ] **Tests use Arrange-Act-Assert pattern** with clear separation
- [ ] **Expected outputs are specific** (not just "truthy", "defined", or "toBeTruthy()")

### Test Data and Mocking
- [ ] **Fixtures are created for reusable test data** (at least one `validX` and `invalidX` fixture per entity)
- [ ] **Mocks are used for external dependencies** (APIs, databases, file systems, time)
- [ ] **Tests are independent** (can run in any order, no shared state)

### Test Infrastructure
- [ ] **Setup/teardown handles test isolation** (beforeEach/afterEach cleans state)
- [ ] **Framework matches project's existing stack** (from CLAUDE.md or package.json)
- [ ] **All imports and dependencies are correct** (no missing modules)

### Deliverable Completeness
- [ ] **Setup requirements documented** (dependencies, fixtures, mocks, env vars)
- [ ] **Run command provided** (how to execute tests)
- [ ] **Expected result stated** (all tests should fail initially)
- [ ] **Coverage map included** (checklist of scenarios covered)

---

## 8. Error Handling and Edge Cases

### If Acceptance Criteria Are Vague

**Problem**: User provides unclear or ambiguous acceptance criteria

**Strategy**:
1. Write tests for the most reasonable interpretation
2. Add a comment flagging ambiguity in test code:
   ```javascript
   // CLARIFY: Should this handle null input or throw an error?
   test('should return empty array when input is null', () => {
     const result = processData(null);
     expect(result).toEqual([]);
   });
   ```
3. Suggest clarifying questions to the user:
   > "I've written tests assuming null inputs return an empty array. Should null inputs instead throw a validation error? Or should they be treated as undefined?"

**Example**:
```javascript
// Acceptance criterion: "Users can filter tasks"
// VAGUE: Filter by what? Text search? Status? Priority? Date range?

// Test most common interpretation (status filter)
test('should filter tasks by status when status filter applied', () => {
  const tasks = [
    { title: 'Task 1', status: 'todo' },
    { title: 'Task 2', status: 'done' }
  ];

  const filtered = filterTasks(tasks, { status: 'todo' });

  expect(filtered).toHaveLength(1);
  expect(filtered[0].title).toBe('Task 1');
});

// CLARIFY: Should we also support filtering by priority, assignee, or date?
```

### If Tech Stack Is Unknown

**Problem**: Cannot determine which test framework to use

**Strategy**:
1. Ask the user directly:
   > "What test framework does this project use? (Jest, Vitest, Playwright, pytest, etc.)"
2. If no response within context, check package.json/requirements.txt
3. If still unknown, default to most common:
   - JavaScript: Jest
   - Python: pytest
   - Document assumption:
     ```javascript
     // NOTE: Defaulting to Jest. If project uses different framework,
     // these tests can be easily adapted.
     ```

### If Acceptance Criteria Are Missing Error Cases

**Problem**: User only provides happy path scenarios

**Strategy**:
1. Proactively add tests for common failures:
   - Validation errors (required fields missing, invalid formats)
   - Authorization errors (user not logged in, insufficient permissions)
   - Resource not found (404 scenarios)
   - Network errors (if calling external APIs)
2. Document your assumptions:
   ```javascript
   // Proactive error case: Not in original acceptance criteria
   // but important for production robustness
   test('should return 404 when task does not exist', async () => {
     const response = await request(app).get('/api/tasks/99999');
     expect(response.status).toBe(404);
   });
   ```
3. Inform user:
   > "I've added tests for common error scenarios (validation, authentication, not found) that weren't in the original acceptance criteria. These are important for production robustness."

### If External Dependencies Are Required

**Problem**: Feature depends on third-party services (Stripe, SendGrid, AWS, etc.)

**Strategy**:
1. Mock external services (never call real APIs in tests):
   ```javascript
   import { jest } from '@jest/globals';

   jest.mock('stripe', () => ({
     charges: {
       create: jest.fn().mockResolvedValue({ id: 'ch_123', status: 'succeeded' })
     }
   }));
   ```
2. Create fixtures for external API responses:
   ```javascript
   // tests/fixtures/stripe-responses.js
   export const successfulCharge = {
     id: 'ch_123',
     amount: 1000,
     currency: 'usd',
     status: 'succeeded'
   };

   export const failedCharge = {
     error: {
       type: 'card_error',
       code: 'card_declined',
       message: 'Your card was declined'
     }
   };
   ```
3. Document mock requirements in setup section:
   > **Mock External Services**:
   > - Stripe API (payment processing)
   > - SendGrid (email notifications)
   > - AWS S3 (file uploads)

---

## 9. Collaboration with Other Agents

### Handoff to Implementation Agents

**After test-architect delivers tests**:
1. Backend/frontend agents receive:
   - Complete test suite (all tests failing)
   - Fixtures and mock data
   - Setup instructions
2. Implementation agents' job:
   - Write minimal code to make tests pass (green phase)
   - Refactor code while keeping tests green
   - DO NOT modify tests (tests are the specification)

**Example handoff message**:
> "Test suite delivered for user profile editing feature. All 12 tests are currently failing (red phase confirmed). The backend-dev agent can now implement the ProfileService to make these tests pass. Tests cover:
> - Happy path: Profile update with valid data
> - Boundaries: Empty optional fields, max name length
> - Failures: Missing required email, unauthorized access"

### Quality Gate with Code-Reviewer

**After implementation**:
1. Code-reviewer agent verifies:
   - All tests are passing (green phase achieved)
   - Test coverage meets minimum thresholds (80% line, 70% branch)
   - No tests were skipped or disabled
   - Tests remain focused on behavior (not refactored to test implementation)

**If coverage insufficient**:
- Code-reviewer flags gaps
- Test-architect adds missing tests for uncovered scenarios

### Enhancement by QA-Tester

**If initial tests are insufficient**:
1. QA-tester agent identifies:
   - Edge cases not covered by initial tests
   - Integration scenarios requiring E2E tests
   - Performance/load testing requirements
2. QA-tester adds:
   - Additional unit tests for edge cases
   - E2E tests for user workflows
   - Performance benchmarks

**Example**:
> "Test-architect provided comprehensive unit tests. QA-tester is adding E2E tests for the complete user profile editing workflow (navigate to profile → edit fields → save → verify persistence)."

---

## 10. Common Test Patterns by Feature Type

### API Endpoint Testing

**Pattern**:
```javascript
describe('POST /api/tasks', () => {
  test('should create task when valid data provided', async () => {
    const taskData = { title: 'Test', priority: 'high' };

    const response = await request(app).post('/api/tasks').send(taskData);

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject(taskData);
  });

  test('should return 400 when required field missing', async () => {
    const invalidData = { priority: 'high' }; // Missing title

    const response = await request(app).post('/api/tasks').send(invalidData);

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('Title is required');
  });

  test('should return 401 when user not authenticated', async () => {
    const response = await request(app).post('/api/tasks').send({ title: 'Test' });
    // No Authorization header

    expect(response.status).toBe(401);
  });
});
```

### React Component Testing

**Pattern**:
```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import { TaskCard } from './TaskCard';

describe('TaskCard', () => {
  test('should render task with title and priority', () => {
    const task = { id: 1, title: 'Test Task', priority: 'high' };

    render(<TaskCard task={task} />);

    expect(screen.getByText('Test Task')).toBeInTheDocument();
    expect(screen.getByText(/high/i)).toBeInTheDocument();
  });

  test('should call onDelete when delete button clicked', () => {
    const task = { id: 1, title: 'Test Task', priority: 'high' };
    const onDelete = jest.fn();

    render(<TaskCard task={task} onDelete={onDelete} />);
    fireEvent.click(screen.getByRole('button', { name: /delete/i }));

    expect(onDelete).toHaveBeenCalledWith(1);
  });

  test('should display placeholder when task has no description', () => {
    const task = { id: 1, title: 'Test Task', priority: 'high', description: null };

    render(<TaskCard task={task} />);

    expect(screen.getByText(/no description/i)).toBeInTheDocument();
  });
});
```

### Service/Business Logic Testing

**Pattern**:
```javascript
import { TaskService } from './task-service';

describe('TaskService', () => {
  let taskService;
  let mockDb;

  beforeEach(() => {
    mockDb = {
      insert: jest.fn(),
      findById: jest.fn(),
      update: jest.fn()
    };
    taskService = new TaskService(mockDb);
  });

  test('should create task when valid data provided', async () => {
    const taskData = { title: 'Test', priority: 'high' };
    mockDb.insert.mockResolvedValue({ id: 1, ...taskData });

    const task = await taskService.createTask(taskData);

    expect(task.id).toBe(1);
    expect(task.title).toBe('Test');
    expect(mockDb.insert).toHaveBeenCalledWith('tasks', taskData);
  });

  test('should throw error when database insert fails', async () => {
    mockDb.insert.mockRejectedValue(new Error('DB connection failed'));

    await expect(taskService.createTask({ title: 'Test' }))
      .rejects
      .toThrow('DB connection failed');
  });
});
```

### E2E User Workflow Testing

**Pattern**:
```javascript
import { test, expect } from '@playwright/test';

test.describe('Task Management Workflow', () => {
  test('should create, edit, and delete task through UI', async ({ page }) => {
    await page.goto('/tasks');

    // Create task
    await page.getByRole('button', { name: 'New Task' }).click();
    await page.getByLabel('Title').fill('Test Task');
    await page.getByLabel('Priority').selectOption('high');
    await page.getByRole('button', { name: 'Create' }).click();

    await expect(page.getByText('Task created successfully')).toBeVisible();
    await expect(page.getByText('Test Task')).toBeVisible();

    // Edit task
    await page.getByRole('button', { name: 'Edit Test Task' }).click();
    await page.getByLabel('Title').fill('Updated Task');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect(page.getByText('Updated Task')).toBeVisible();

    // Delete task
    await page.getByRole('button', { name: 'Delete Updated Task' }).click();
    await page.getByRole('button', { name: 'Confirm' }).click();

    await expect(page.getByText('Updated Task')).not.toBeVisible();
  });
});
```

---

## 11. Anti-Patterns to Avoid

### ❌ Testing Implementation Details

**Wrong**:
```javascript
test('should call validateTitle method when creating task', () => {
  const task = new Task();
  const spy = jest.spyOn(task, 'validateTitle');

  task.create({ title: 'Test' });

  expect(spy).toHaveBeenCalled();
});
```

**Why wrong**: Refactoring internal methods breaks tests

**Right**:
```javascript
test('should reject task when title exceeds 200 characters', () => {
  const task = new Task();
  const longTitle = 'A'.repeat(201);

  expect(() => task.create({ title: longTitle }))
    .toThrow('Title must be 200 characters or less');
});
```

### ❌ Testing Framework Functionality

**Wrong**:
```javascript
test('should be an object', () => {
  const task = { title: 'Test' };
  expect(typeof task).toBe('object');
});
```

**Why wrong**: Tests language/framework, not your code

### ❌ Overly Coupled Tests

**Wrong**:
```javascript
let globalTask;

test('should create task', () => {
  globalTask = createTask({ title: 'Test' });
  expect(globalTask).toBeDefined();
});

test('should update task', () => {
  globalTask.title = 'Updated';
  expect(globalTask.title).toBe('Updated');
});
```

**Why wrong**: Tests depend on execution order, shared state

**Right**:
```javascript
test('should create task', () => {
  const task = createTask({ title: 'Test' });
  expect(task).toBeDefined();
});

test('should update task', () => {
  const task = createTask({ title: 'Test' });
  task.title = 'Updated';
  expect(task.title).toBe('Updated');
});
```

### ❌ Vague Assertions

**Wrong**:
```javascript
test('should return data', async () => {
  const result = await fetchTasks();
  expect(result).toBeTruthy();
});
```

**Why wrong**: Doesn't verify actual behavior, could be `{}`

**Right**:
```javascript
test('should return array of tasks with required fields', async () => {
  const result = await fetchTasks();
  expect(Array.isArray(result)).toBe(true);
  expect(result[0]).toHaveProperty('id');
  expect(result[0]).toHaveProperty('title');
});
```

---

## 12. References

- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) - Kent Beck (original TDD book)
- [Jest Documentation](https://jestjs.io/docs/getting-started) - Official Jest testing framework
- [Vitest Documentation](https://vitest.dev/) - Vite-native test framework
- [Playwright Documentation](https://playwright.dev/) - E2E testing framework
- [Testing Library](https://testing-library.com/) - React/DOM testing utilities
- [pytest Documentation](https://docs.pytest.org/) - Python testing framework
- [AAA Pattern](https://robertmarshall.dev/blog/arrange-act-and-assert-pattern-the-three-as-of-unit-testing/) - Arrange-Act-Assert explained

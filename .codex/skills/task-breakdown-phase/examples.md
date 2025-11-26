<overview>
Real-world task breakdown examples demonstrating good vs bad tasks, complete TDD triplet patterns, and progressive learning from real feature implementations.

Use these examples to understand quality task breakdown patterns, avoid common anti-patterns, and see complete workflows from plan.md → tasks.md.
</overview>

<good_task_examples>
**High-quality right-sized tasks with clear acceptance criteria**

<example_api_endpoint>
**Good Task: API Endpoint (Right-sized)**

```markdown
### Task 15: Implement GET /api/v1/students/{id}/progress

**Complexity**: Medium (6-8 hours)

**Description**: Implement API endpoint to make integration tests from Task 14 pass.

**Implementation steps**:
1. Create route in routes/students.py
2. Add authentication decorator (@require_teacher)
3. Validate student_id and period parameters
4. Call StudentProgressService.calculateProgress()
5. Format response per OpenAPI schema
6. Handle errors (404, 403, 400)

**Acceptance criteria**:
- [ ] All 5 integration tests from Task 14 pass
- [ ] Response time <500ms (95th percentile, 500 lessons)
- [ ] Follows API versioning (/api/v1/)
- [ ] Error responses include error codes (RFC 7807)

**Dependencies**: Task 14 (API tests), Task 9 (StudentProgressService)
**Blocks**: Task 22 (UI component)
**Files**: api/app/routes/students.py
```

**Why it's good**:
- Clear scope (single endpoint)
- Sized appropriately (6-8 hours)
- Test-driven (depends on test task 14)
- Measurable AC (4 checkboxes, all testable)
- Dependencies explicit (task numbers listed)
- Implementation steps guide without over-specifying
</example_api_endpoint>

<example_ui_component>
**Good Task: UI Component (Right-sized)**

```markdown
### Task 22: Implement StudentProgressDashboard component

**Complexity**: Medium (6-8 hours)

**Description**: Implement React component to make tests from Task 21 pass.

**Implementation steps**:
1. Create StudentProgressDashboard.tsx
2. Fetch data from GET /api/v1/students/{id}/progress
3. Display loading/error/empty/success states
4. Integrate ProgressChart component (from shared library)
5. Add filter controls (weekly/monthly/yearly)
6. Ensure WCAG 2.1 AA compliance

**Acceptance criteria**:
- [ ] All 4 tests from Task 21 pass
- [ ] Lighthouse accessibility score ≥95
- [ ] Reuses ProgressChart from shared/components
- [ ] All 4 states render correctly (loading, error, empty, success)

**Dependencies**: Task 21 (component tests), Task 15 (API endpoint)
**Blocks**: Task 27 (E2E test)
**Files**: src/components/StudentProgressDashboard.tsx
```

**Why it's good**:
- Right-sized (6-8 hours)
- Test-driven (links to Task 21)
- Accessibility validated (Lighthouse ≥95)
- Reuse enforced (ProgressChart from shared library)
- All UI states covered (loading, error, empty, success)
</example_ui_component>

<example_database_migration>
**Good Task: Database Migration (Right-sized)**

```markdown
### Task 1: Create database migration for student progress tables

**Complexity**: Small (2-4 hours)

**Description**: Create Alembic migration for students and lessons tables.

**Implementation steps**:
1. Create migration file (alembic revision --autogenerate)
2. Define students table (id, name, grade_level, created_at)
3. Define lessons table (id, student_id, subject, duration_mins)
4. Add indexes (student_id, created_at)
5. Add foreign key constraints (lessons.student_id → students.id)

**Acceptance criteria**:
- [ ] Migration runs successfully on clean database
- [ ] Rollback works without errors
- [ ] Index on student_id improves query from 450ms to <100ms (measured)
- [ ] Foreign key prevents orphaned lesson records (validated)

**Dependencies**: None (foundation task)
**Blocks**: Task 2 (Student model), Task 3 (Lesson model)
**Files**: alembic/versions/YYYY_MM_DD_create_student_progress_tables.py
```

**Why it's good**:
- Right-sized (2-4 hours)
- Rollback verified (production safety)
- Performance validated (index improvement measured)
- Integrity enforced (foreign key constraint)
- Foundation task (no dependencies, blocks all other tasks)
</example_database_migration>
</good_task_examples>

<bad_task_examples>
**Problematic tasks demonstrating common anti-patterns**

<example_too_large>
**Bad Task: Too Large (>1.5 days)**

```markdown
### Task: Build entire user management system

**Complexity**: Very High (5 days)

**Description**: Implement complete user management with authentication, authorization, profile editing, password reset, and admin panel.

[No acceptance criteria]
[No dependencies]
[No implementation steps]
```

**Why it's bad**:
- Way too large (5 days vs 0.5-1 day target)
- No clear completion criteria
- No breakdown into subtasks
- Impossible to estimate accurately
- Can't test incrementally
- Blocks all progress for 5 days

**How to fix**:
Split into 15-20 tasks following TDD workflow:
- Foundation: User model, migration
- Authentication: Login/logout (test + implement)
- Authorization: Role-based access control (test + implement)
- Profile: Edit profile (test + implement)
- Password: Reset flow (test + implement)
- Admin: Admin panel (test + implement per feature)
- Integration: E2E tests for complete flows
</example_too_large>

<example_vague_acceptance_criteria>
**Bad Task: Vague Acceptance Criteria**

```markdown
### Task: Implement API endpoint

**Complexity**: Medium (6 hours)

**Acceptance criteria**:
- ✓ Code works correctly
- ✓ Endpoint is implemented
- ✓ Tests pass
```

**Why it's bad**:
- AC are not measurable ("works correctly" is subjective)
- No performance targets
- No error handling specified
- No schema/contract validation
- Impossible to verify without implementation details

**How to fix**:
Use specific, testable AC:
- [ ] Returns 200 with completion_rate field (tested)
- [ ] Response time <500ms (95th percentile, measured)
- [ ] Returns 404 for invalid student ID (tested)
- [ ] Follows StudentProgressSchema from plan.md (validated)
</example_vague_acceptance_criteria>

<example_no_tdd>
**Bad Task: No TDD Workflow**

```markdown
### Task 8: Implement StudentProgressService
### Task 9: Write tests for StudentProgressService
```

**Why it's bad**:
- Implementation before tests (violates TDD)
- Tests written as afterthought (poor coverage)
- Missed edge cases (tests don't drive design)
- Hard to refactor (tests coupled to implementation)

**How to fix**:
Reverse order and add refactor task:
```
Task 8: Write unit tests for StudentProgressService (RED)
Task 9: Implement StudentProgressService to pass tests (GREEN)
Task 10: Refactor StudentProgressService (REFACTOR)
```
</example_no_tdd>

<example_unclear_dependencies>
**Bad Task: Unclear Dependencies**

```markdown
### Task 15: Implement API endpoint

**Dependencies**: Other tasks
**Blocks**: Some UI components
```

**Why it's bad**:
- Dependencies not specific (which tasks?)
- Blocks not specific (which components?)
- Can't determine critical path
- Can't identify parallel work opportunities
- Developer unsure what to start with

**How to fix**:
List explicit task numbers:
```
**Dependencies**: Task 14 (API tests), Task 9 (StudentProgressService)
**Blocks**: Task 22 (StudentProgressDashboard), Task 24 (ProgressChart)
```
</example_unclear_dependencies>
</bad_task_examples>

<tdd_triplet_examples>
**Complete TDD triplet patterns for different component types**

<service_tdd_triplet>
**Service TDD Triplet (test → implement → refactor)**

**Task 8: Write unit tests for StudentProgressService** (RED phase)

```markdown
**Complexity**: Medium (4 hours)

**Description**: Write comprehensive unit tests before implementing StudentProgressService.

**Test cases to implement**:
1. calculateProgress() with valid student (expects completion rate)
2. calculateProgress() with no lessons (expects 0%)
3. calculateProgress() with student not found (expects error)
4. getRecentActivity() returns last 10 activities
5. getRecentActivity() with no activity (expects empty array)

**Acceptance criteria**:
- [ ] 5 test cases implemented (all failing initially - RED)
- [ ] Tests cover happy path + 2 edge cases (no lessons, invalid student)
- [ ] Mocks used for Student/Lesson/TimeLog models
- [ ] Test coverage ≥90% for service interface

**Dependencies**: Task 4 (models created)
**Blocks**: Task 9 (implementation)
**Files**: api/app/tests/test_student_progress_service.py
```

**Task 9: Implement StudentProgressService** (GREEN phase)

```markdown
**Complexity**: Medium (6 hours)

**Description**: Implement StudentProgressService to make all tests from Task 8 pass.

**Implementation steps**:
1. Create StudentProgressService class
2. Implement calculateProgress(student_id, period)
3. Implement getRecentActivity(student_id, limit)
4. Add error handling (student not found, invalid period)
5. Optimize queries (JOIN instead of N+1)

**Acceptance criteria**:
- [ ] All 5 tests from Task 8 pass
- [ ] calculateProgress() returns completion_rate (0-100%)
- [ ] Response time <100ms for 500 lessons (measured)
- [ ] Follows BaseService pattern from plan.md

**Implementation notes**:
- Reuse BaseService pattern (api/app/services/base.py)
- Follow TDD: Implement minimal code to pass tests (no extra features)
- Use database indexes on student_id and created_at
- Refer to plan.md section "StudentProgressService" for details

**Dependencies**: Task 8 (tests written)
**Blocks**: Task 10 (refactor), Task 14 (API tests)
**Files**: api/app/services/student_progress_service.py
```

**Task 10: Refactor StudentProgressService** (REFACTOR phase)

```markdown
**Complexity**: Small (3 hours)

**Description**: Refactor StudentProgressService while keeping all tests green.

**Refactor targets**:
1. Extract magic numbers to constants (e.g., DEFAULT_RECENT_LIMIT = 10)
2. Reduce cyclomatic complexity (split complex methods)
3. Eliminate code duplication (extract common query logic)
4. Improve method names (calculateProgress → calculateCompletionRate)

**Acceptance criteria**:
- [ ] All 5 tests still pass after refactor
- [ ] Cyclomatic complexity <10 (all methods)
- [ ] No code duplication (DRY violations <2)
- [ ] Magic numbers extracted to constants

**Implementation notes**:
- Run tests after each refactor step
- Use linter/complexity tools (pylint, radon)
- Don't change behavior (tests remain unchanged)

**Dependencies**: Task 9 (implementation complete)
**Blocks**: Task 14 (API tests can use refactored service)
**Files**: api/app/services/student_progress_service.py
```

**Result**: Clean, well-tested, maintainable service with ≥90% coverage
</service_tdd_triplet>

<api_tdd_pair>
**API TDD Pair (test → implement)**

**Task 14: Write integration tests for GET /api/v1/students/{id}/progress** (RED phase)

```markdown
**Complexity**: Medium (4 hours)

**Description**: Write integration tests before implementing API endpoint.

**Test cases to implement**:
1. Returns 200 with completion_rate field for valid student
2. Returns 404 for invalid student ID
3. Returns 401 without authentication token
4. Returns 403 for non-teacher role (student accessing)
5. Response time <500ms (95th percentile, 500 lessons)

**Acceptance criteria**:
- [ ] 5 integration tests implemented (all failing - RED)
- [ ] Tests use test database with seed data
- [ ] Authentication tested (401, 403 status codes)
- [ ] Performance tested (response time <500ms)

**Dependencies**: Task 9 (StudentProgressService), Task 12 (auth middleware)
**Blocks**: Task 15 (endpoint implementation)
**Files**: api/app/tests/test_students_api.py
```

**Task 15: Implement GET /api/v1/students/{id}/progress** (GREEN phase)

```markdown
**Complexity**: Medium (6 hours)

**Description**: Implement endpoint to make all integration tests from Task 14 pass.

**Implementation steps**:
1. Create route in routes/students.py
2. Add @require_teacher authentication decorator
3. Validate student_id parameter (int, >0)
4. Call StudentProgressService.calculateProgress()
5. Format response per StudentProgressSchema
6. Handle errors (404, 403, 400, 500)

**Acceptance criteria**:
- [ ] All 5 integration tests from Task 14 pass
- [ ] Response time <500ms (95th percentile, measured)
- [ ] Follows API versioning (/api/v1/)
- [ ] Error responses include error codes (RFC 7807)

**Implementation notes**:
- Reuse existing auth decorators (@require_teacher)
- Follow error handling pattern from plan.md
- Use StudentProgressSchema for validation (marshmallow)

**Dependencies**: Task 14 (API tests), Task 9 (service)
**Blocks**: Task 22 (UI component)
**Files**: api/app/routes/students.py
```

**Result**: Fully tested API endpoint with auth, validation, error handling
</api_tdd_pair>

<ui_tdd_pair>
**UI TDD Pair (test → implement)**

**Task 21: Write tests for StudentProgressDashboard component** (RED phase)

```markdown
**Complexity**: Medium (4 hours)

**Description**: Write component tests before implementing StudentProgressDashboard.

**Test cases to implement**:
1. Renders progress chart with student data (happy path)
2. Loading state displays spinner
3. Error state displays error message
4. Empty state displays "No data" message
5. Filter selection updates chart data

**Acceptance criteria**:
- [ ] 5 component tests implemented (all failing - RED)
- [ ] Tests use React Testing Library + Jest
- [ ] All 4 states tested (loading, error, empty, success)
- [ ] User interactions tested (filter clicks)

**Dependencies**: Task 15 (API endpoint for data fetching)
**Blocks**: Task 22 (component implementation)
**Files**: src/components/__tests__/StudentProgressDashboard.test.tsx
```

**Task 22: Implement StudentProgressDashboard component** (GREEN phase)

```markdown
**Complexity**: Medium (6 hours)

**Description**: Implement React component to make all tests from Task 21 pass.

**Implementation steps**:
1. Create StudentProgressDashboard.tsx
2. Fetch data from GET /api/v1/students/{id}/progress
3. Implement 4 states (loading, error, empty, success)
4. Integrate ProgressChart component (shared library)
5. Add filter controls (weekly, monthly, yearly)
6. Ensure accessibility (WCAG 2.1 AA)

**Acceptance criteria**:
- [ ] All 5 tests from Task 21 pass
- [ ] Lighthouse accessibility score ≥95
- [ ] Reuses ProgressChart from shared/components
- [ ] All 4 states render correctly

**Implementation notes**:
- Use React hooks (useState, useEffect) for data fetching
- Reuse ProgressChart (don't duplicate chart code)
- Add ARIA labels for screen readers
- Test with keyboard navigation (tab, enter, space)

**Dependencies**: Task 21 (component tests), Task 15 (API)
**Blocks**: Task 27 (E2E test)
**Files**: src/components/StudentProgressDashboard.tsx
```

**Result**: Accessible, well-tested UI component with all states covered
</ui_tdd_pair>
</tdd_triplet_examples>

<complete_feature_example>
**Complete feature breakdown from plan.md → tasks.md**

**Feature**: Student Progress Dashboard

**From plan.md**:
- Data layer: students, lessons tables
- Business logic: StudentProgressService (calculateProgress, getRecentActivity)
- API layer: GET /api/v1/students/{id}/progress
- UI layer: StudentProgressDashboard component
- Integration: E2E test (login → navigate → filter → verify)

**Generated tasks** (28 total):

**Foundation (3 tasks)**:
- Task 1: Create database migration for student progress tables (2-4h)
- Task 2: Define Student model with validation (3h)
- Task 3: Define Lesson model with foreign key (3h)

**Business Logic (TDD triplet, 3 tasks)**:
- Task 8: Write unit tests for StudentProgressService (4h)
- Task 9: Implement StudentProgressService (6h)
- Task 10: Refactor StudentProgressService (3h)

**API Layer (TDD pair, 2 tasks)**:
- Task 14: Write integration tests for GET /api/v1/students/{id}/progress (4h)
- Task 15: Implement GET /api/v1/students/{id}/progress (6h)

**UI Layer (TDD pair, 2 tasks)**:
- Task 21: Write tests for StudentProgressDashboard (4h)
- Task 22: Implement StudentProgressDashboard (6h)

**Integration (2 tasks)**:
- Task 27: Write E2E test for student progress workflow (6h)
- Task 28: Run smoke tests on complete feature (2h)

**Total**: 28 tasks, 4-5 days estimated, critical path 15 hours
</complete_feature_example>

<progressive_learning_pattern>
**How task breakdown quality improves over time**

**After 5 features** (Baseline):
- Avg task size: 0.7 days
- Avg AC per task: 3.2
- TDD workflow followed: 85%
- Tasks with clear dependencies: 70%
- Avg time to generate tasks.md: 45 min

**After 10 features** (Improvement):
- Avg task size: 0.6 days (better sizing)
- Avg AC per task: 3.8 (more thorough)
- TDD workflow followed: 95%
- Tasks with clear dependencies: 90%
- Avg time to generate tasks.md: 30 min (faster with templates)

**After 20 features** (Mastery):
- Avg task size: 0.5 days (optimal)
- Avg AC per task: 4.0 (comprehensive)
- TDD workflow followed: 98%
- Tasks with clear dependencies: 98%
- Avg time to generate tasks.md: 20 min (template reuse)

**Patterns detected**:
- Similar features reuse task templates (saves 50% time)
- AC templates evolve per project (API patterns, UI patterns)
- Dependency graphs become predictable (layer-based architecture)
</progressive_learning_pattern>

<real_world_features>
**Section for capturing actual features from workflow execution**

<template>
**Feature**: [Feature Name]

**Date**: YYYY-MM-DD
**Total tasks**: N
**Task size**: Avg X hours (range Y-Z hours)
**TDD workflow**: N% followed
**Time to generate**: N minutes
**Outcome**: ✅ Completed | ⚠️ Needed revision | ❌ Blocked

**Lessons learned**:
- [What went well]
- [What could improve]
- [Pattern to repeat]
</template>

<placeholder>
_This section will be populated as real features move through the /tasks phase._

**Purpose**: Capture real-world execution data to improve task breakdown quality over time. Each feature completed through /tasks phase adds to this library, creating a self-improving knowledge base.

**Update trigger**: After /tasks phase completes successfully, append feature summary using template above.
</placeholder>
</real_world_features>

<usage_notes>
**How to use these examples during /tasks execution**:

1. **Before generating tasks**: Review good task examples for sizing and AC patterns
2. **During task generation**: Use TDD triplet examples as templates
3. **When unsure about dependencies**: Reference complete feature example for layer sequencing
4. **For quality checks**: Compare generated tasks against bad examples to spot anti-patterns
5. **Post-execution review**: Compare your tasks.md against examples to identify improvements
</usage_notes>

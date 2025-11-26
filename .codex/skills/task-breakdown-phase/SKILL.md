---
name: task-breakdown-phase
description: Standard Operating Procedure for /tasks phase. Covers task sizing, acceptance criteria definition, and TDD-first task sequencing. (project)
---

<objective>
Transform plan.md into 20-30 concrete, right-sized tasks with TDD workflow, explicit dependencies, and measurable acceptance criteria. Ensures implementation phase has clear, testable tasks that enforce test-first development.

This skill orchestrates the /tasks phase, producing tasks.md with:

- Right-sized tasks (0.5-1 day each, 4-8 hours)
- TDD workflow (test → implement → refactor triplet for all components)
- Clear acceptance criteria (2-4 testable checkboxes per task)
- Explicit dependencies (task numbers, critical path, parallel opportunities)
- Implementation hints (reuse patterns, file paths, references to plan.md)

Inputs: plan.md (architecture, components, reuse strategy)
Outputs: tasks.md (20-30 tasks sequenced by dependencies)
Expected duration: 30-60 minutes
</objective>

<quick_start>
Execute /tasks workflow in 12 steps:

1. **Parse plan.md** - Extract architecture components, reuse patterns, data models, API endpoints, UI components
2. **Generate foundation tasks** - Database migrations, model definitions, configuration setup (3-5 tasks)
3. **Generate business logic tasks** - TDD triplet (test → implement → refactor) for each service/utility (2-4 tasks per component)
4. **Generate API tasks** - TDD for controllers/routes (test → implement per endpoint)
5. **Generate UI tasks** - TDD for components (test → implement per screen/component) if HAS_UI
6. **Generate integration tasks** - E2E tests, smoke tests, integration validation (2-3 tasks)
7. **Map dependencies** - Build dependency graph, identify critical path, mark parallel opportunities
8. **Size tasks** - Validate 0.5-1 day per task (split if >1.5 days, combine if <0.5 day)
9. **Write acceptance criteria** - 2-4 testable checkboxes per task using AC templates
10. **Add implementation notes** - Reuse hints, file paths, plan.md references for complex tasks
11. **Generate tasks.md** - Render with task summary (total, duration, critical path, distribution)
12. **Validate and commit** - Check 20-30 tasks total, all AC clear, TDD followed, dependencies explicit

Key principle: Every task is test-driven with measurable acceptance criteria.
</quick_start>

<prerequisites>
Before beginning task breakdown:
- Planning phase completed (plan.md exists)
- Architecture components defined (data layer, business logic, API layer, UI layer)
- Reuse strategy documented (existing services/components to leverage)
- Git working tree clean (no uncommitted changes)

If prerequisites not met, return to /plan phase.
</prerequisites>

<workflow>
<step number="1">
**Parse plan.md**

Extract all implementation components from plan.md:

**Architecture components to extract**:

- Data layer: models, schemas, migrations
- Business logic: services, utilities, helpers
- API layer: controllers, routes, middleware
- UI layer: components, screens, forms (if HAS_UI)
- Testing: integration points, E2E scenarios

**Reuse patterns to identify**:

- Existing services/utilities referenced in plan.md
- Shared components/libraries to leverage
- Established patterns to follow (e.g., BaseService, repository pattern)

**Quality check**: All components from plan.md extracted, reuse opportunities documented.

See reference.md for component extraction examples.
</step>

<step number="2">
**Generate Foundation Tasks**

Create infrastructure setup tasks (first to execute, all others depend on these).

**Foundation task categories**:

1. Database migration task (create tables, indexes, constraints)
2. Model definition tasks (data models, schemas, validation)
3. Configuration tasks (environment setup, dependency installation)

**Example foundation task**:

```
Task 1: Create database migration for student progress tables

Complexity: Small (2-4 hours)

Steps:
1. Create migration file (alembic revision --autogenerate)
2. Define students table (id, name, grade_level, created_at)
3. Define lessons table (id, student_id, subject, duration_mins)
4. Add indexes (student_id, created_at)
5. Add foreign key constraints

Acceptance criteria:
- [ ] Migration runs successfully on clean database
- [ ] Rollback works without errors
- [ ] Indexes improve query performance (measured)
- [ ] Foreign keys enforce referential integrity

Dependencies: None (foundation task)
Blocks: Task 4 (model definitions)
```

**Quality check**: 3-5 foundation tasks created, all have clear dependencies.

See reference.md for foundation task templates.
</step>

<step number="3">
**Generate Business Logic Tasks (TDD-First)**

For each service/utility in plan.md, create TDD triplet (test → implement → refactor).

**TDD task structure** (3 tasks per component):

1. **Task N: Write tests for [Component]** ← RED phase
2. **Task N+1: Implement [Component]** ← GREEN phase
3. **Task N+2: Refactor [Component]** ← REFACTOR phase

**Example TDD triplet**:

```
Task 8: Write unit tests for StudentProgressService
→ Task 9: Implement StudentProgressService to pass tests
→ Task 10: Refactor StudentProgressService

Task 8 acceptance criteria:
- [ ] 5 test cases implemented (all failing initially)
- [ ] Tests cover happy path + edge cases
- [ ] Mocks used for Student/Lesson models
- [ ] Test coverage ≥90% for service interface

Task 9 acceptance criteria:
- [ ] All 5 tests from Task 8 pass
- [ ] calculateProgress() returns completion rate
- [ ] Response time <100ms for 500 lessons
- [ ] Follows service pattern from plan.md

Task 10 acceptance criteria:
- [ ] All tests still pass after refactor
- [ ] Cyclomatic complexity <10 (all methods)
- [ ] No code duplication (DRY violations <2)
- [ ] Clear method names, extracted constants
```

**Quality check**: Every business logic component has TDD triplet, test task always before implement task.

See examples.md for complete TDD triplet examples.
</step>

<step number="4">
**Generate API Tasks (TDD)**

For each API endpoint in plan.md, create test + implement tasks.

**API task structure** (2 tasks per endpoint):

1. **Task N: Write integration tests for [Endpoint]** ← RED
2. **Task N+1: Implement [Endpoint]** ← GREEN

**Example API task pair**:

```
Task 14: Write integration tests for GET /api/v1/students/{id}/progress
→ Task 15: Implement GET /api/v1/students/{id}/progress

Task 14 acceptance criteria:
- [ ] Test: Returns 200 with completion_rate field
- [ ] Test: Returns 404 for invalid student ID
- [ ] Test: Requires authentication (401 without token)
- [ ] Test: Response time <500ms (95th percentile)

Task 15 acceptance criteria:
- [ ] All 4 integration tests from Task 14 pass
- [ ] Follows OpenAPI schema from plan.md
- [ ] Error responses include error codes (RFC 7807)
- [ ] API versioning enforced (/api/v1/)

Dependencies: Task 14 (API tests), Task 9 (StudentProgressService)
Blocks: Task 22 (UI component consuming this API)
```

**Quality check**: Every API endpoint has test task before implement task.

See reference.md for API task templates.
</step>

<step number="5">
**Generate UI Tasks (TDD)** - If HAS_UI

For each screen/component in plan.md, create test + implement tasks.

**UI task structure** (2 tasks per component):

1. **Task N: Write component tests for [Component]** ← RED
2. **Task N+1: Implement [Component]** ← GREEN

**Example UI task pair**:

```
Task 21: Write tests for StudentProgressDashboard component
→ Task 22: Implement StudentProgressDashboard component

Task 21 acceptance criteria:
- [ ] Test: Renders progress chart with student data
- [ ] Test: Loading state displays spinner
- [ ] Test: Error state displays error message
- [ ] Test: Empty state displays "No data" message

Task 22 acceptance criteria:
- [ ] All 4 tests from Task 21 pass
- [ ] Lighthouse accessibility score ≥95
- [ ] Reuses ProgressChart from shared library
- [ ] Fetches data from GET /api/v1/students/{id}/progress

Dependencies: Task 21 (component tests), Task 15 (API endpoint)
```

**Quality check**: Every UI component has test task, accessibility validated.

**Skip if**: No UI changes in this feature (HAS_UI=false).

See reference.md for UI task templates.
</step>

<step number="6">
**Generate Integration Tasks**

Create end-to-end and integration validation tasks.

**Integration task types**:

- E2E tests (complete user workflows)
- Integration tests (multi-component interactions)
- Smoke tests (critical path validation)

**Example integration task**:

```
Task 27: Write E2E test for student progress workflow

Complexity: Medium (4-6 hours)

Steps:
1. Set up test database with seed data
2. Simulate teacher login
3. Navigate to student progress dashboard
4. Verify progress data displays correctly
5. Test filtering and date range selection
6. Verify API calls and response times

Acceptance criteria:
- [ ] Complete workflow tested (login → dashboard → filters)
- [ ] All API calls succeed (200 responses)
- [ ] UI updates correctly on filter changes
- [ ] Test runs in <30 seconds

Dependencies: All UI tasks (21-26), all API tasks (14-20)
```

**Quality check**: 2-3 integration tasks created, cover critical paths.

See reference.md for integration task patterns.
</step>

<step number="7">
**Map Dependencies**

Build dependency graph, identify critical path, mark parallel opportunities.

**Dependency mapping**:

```
Foundation (Tasks 1-3) → Sequential (no parallel work)
  ↓
Data layer (Tasks 4-7) → Sequential (model definitions depend on migrations)
  ↓
Business logic (Tasks 8-13) → Parallel work possible (independent services)
  ↓
API layer (Tasks 14-20) → Parallel work possible (independent endpoints)
  ↓
UI layer (Tasks 21-26) → Parallel work possible (independent components)
  ↓
Integration (Tasks 27-28) → Sequential (depends on all above)
```

**Critical path identification**:

```
Critical path: Tasks 1 → 4 → 8 → 9 → 14 → 15 → 21 → 22 → 27 (15 hours)
Parallel paths: API tasks (14-20) can run parallel to UI tasks (21-26)
```

**Quality check**: All dependencies explicit (task numbers listed), critical path identified.

See reference.md for dependency graph examples.
</step>

<step number="8">
**Size Tasks**

Validate all tasks are 0.5-1 day (4-8 hours).

**Sizing validation**:

- **Target**: 90% of tasks are 0.5-1 day
- **If task >1.5 days**: Split into subtasks using TDD triplet
- **If task <0.5 day**: Consider grouping related small tasks

**Example task splitting**:

```
❌ Task: Implement entire student progress dashboard (3 days)

✅ Split into:
Task 21: Write tests for dashboard component (4 hours)
Task 22: Implement dashboard component (6 hours)
Task 23: Write tests for progress chart (3 hours)
Task 24: Implement progress chart (5 hours)
```

**Quality check**: All tasks ≤1.5 days, most 0.5-1 day.

See reference.md for task sizing guidelines.
</step>

<step number="9">
**Write Acceptance Criteria**

Add 2-4 testable checkboxes per task using AC templates.

**AC quality standards**:

- All AC are testable (not vague like "code works")
- Use Given-When-Then format where helpful
- Include success metrics (response time, coverage %, score)
- Reference schemas/patterns from plan.md

**Good acceptance criteria examples**:

```
✅ [ ] API returns 200 with completion_rate field (tested)
✅ [ ] Response time <500ms with 500 lessons (measured)
✅ [ ] Returns 404 for invalid student ID (tested)
✅ [ ] Follows API schema from plan.md (validated)
```

**Bad acceptance criteria to avoid**:

```
❌ [ ] Code works correctly
❌ [ ] API is implemented
❌ [ ] Tests pass
```

**Quality check**: Every task has 2-4 checkboxes, all are testable.

See reference.md for AC templates (API, UI, database, service).
</step>

<step number="10">
**Add Implementation Notes**

For complex tasks, add implementation hints without over-specifying.

**Implementation notes examples**:

```
Implementation notes:
- Reuse BaseService pattern (see api/app/services/base.py)
- Follow TDD: Write test first, implement minimal code, refactor
- Use existing time_spent calculation utility
- Refer to plan.md section "StudentProgressService" for details
```

**Quality check**: Complex tasks have helpful hints, don't prescribe exact implementation.

See reference.md for implementation note patterns.
</step>

<step number="11">
**Generate tasks.md**

Render tasks.md from template with task summary.

**Task summary format**:

```
## Task Summary

**Total tasks**: 28
**Estimated duration**: 4-5 days
**Critical path**: Tasks 1 → 4 → 8 → 9 → 15 → 16 → 22 → 23 → 27 (15 hours)
**Parallel paths**: UI tasks (21-26) can run parallel to API tasks (16-20)

**Task distribution**:
- Foundation: 3 tasks
- Data layer: 4 tasks
- Business logic: 6 tasks (TDD: test + implement + refactor)
- API layer: 6 tasks (TDD: test + implement)
- UI layer: 6 tasks (TDD: test + implement)
- Testing: 3 tasks (integration + E2E)
```

**Quality check**: tasks.md is complete and ready for /implement phase.

See reference.md for tasks.md template.
</step>

<step number="12">
**Validate and Commit**

Run validation checks and commit tasks to git.

**Validation checks**:

- [ ] 20-30 tasks total (appropriate for feature complexity)
- [ ] All tasks ≤1.5 days (most 0.5-1 day)
- [ ] All tasks have 2-4 acceptance criteria
- [ ] TDD workflow followed (test-first tasks)
- [ ] Dependencies clearly documented
- [ ] No circular dependencies

**Commit tasks**:

```bash
git add specs/NNN-slug/tasks.md
git commit -m "feat: add task breakdown for <feature-name>

Generated 28 tasks with TDD workflow:
- Foundation: 3 tasks
- Data layer: 4 tasks
- Business logic: 6 tasks
- API layer: 6 tasks
- UI layer: 6 tasks
- Testing: 3 tasks

Estimated duration: 4-5 days"
```

**Quality check**: Tasks committed, state.yaml updated to tasks phase completed.
</step>
</workflow>

<validation>
After task breakdown phase, verify:

- [ ] 20-30 tasks created (adjust for feature complexity)
- [ ] All tasks ≤1.5 days (90% are 0.5-1 day)
- [ ] All tasks have 2-4 testable acceptance criteria
- [ ] TDD workflow followed (test tasks before implementation tasks)
- [ ] Dependencies explicitly documented (task numbers listed)
- [ ] Critical path identified in task summary
- [ ] Parallel work opportunities marked
- [ ] Implementation notes added for complex tasks
- [ ] tasks.md committed to git
- [ ] state.yaml updated (tasks phase completed)

If validation fails, return to workflow steps to fix issues.
</validation>

<anti_patterns>
<pitfall name="tasks_too_large">
**❌ Don't**: Create tasks >1.5 days (unclear completion, blocks progress)
**✅ Do**: Target 0.5-1 day per task, split large tasks using TDD triplet

**Why**: Large tasks are hard to estimate, test incrementally, and track progress.

**Example** (bad):

```
Task: Implement entire student progress dashboard
Complexity: Very High (3 days)
Result: Unclear when 50% complete, hard to test incrementally
```

**Example** (good):

```
Task 21: Write tests for dashboard component (4 hours)
Task 22: Implement dashboard component (6 hours)
Task 23: Refactor dashboard component (3 hours)
Result: Clear progress, testable increments, easy to estimate
```

</pitfall>

<pitfall name="vague_acceptance_criteria">
**❌ Don't**: Use vague AC like "code works", "feature done", "tests pass"
**✅ Do**: Use measurable, testable AC with success metrics

**Why**: Vague AC causes unclear completion, rework risk, merge conflicts.

**Bad examples**:

```
❌ [ ] Code works correctly
❌ [ ] Feature is implemented
❌ [ ] Tests pass
```

**Good examples**:

```
✅ [ ] API returns 200 with completion_rate field (tested)
✅ [ ] Response time <500ms with 500 lessons (measured)
✅ [ ] Returns 404 for invalid student ID (tested)
```

</pitfall>

<pitfall name="no_tdd_workflow">
**❌ Don't**: Write implementation tasks before test tasks
**✅ Do**: Always create test task before implementation task (TDD)

**Why**: Tests written after code leads to poor coverage, missed edge cases.

**Bad task order**:

```
Task 8: Implement StudentProgressService
Task 9: Write tests for StudentProgressService
```

**Good task order** (TDD):

```
Task 8: Write unit tests for StudentProgressService (RED)
Task 9: Implement StudentProgressService to pass tests (GREEN)
Task 10: Refactor StudentProgressService (REFACTOR)
```

</pitfall>
</anti_patterns>

<best_practices>
<practice name="tdd_triplet_pattern">
For every component, create 3 tasks: test → implement → refactor.

**TDD triplet example**:

```
Task 8: Write unit tests for StudentProgressService
  → Tests all failing initially (RED)
  → Acceptance: 5 test cases, ≥90% coverage

Task 9: Implement StudentProgressService
  → Make all tests pass with minimal code (GREEN)
  → Acceptance: All 5 tests pass, <100ms response time

Task 10: Refactor StudentProgressService
  → Clean up while keeping tests green (REFACTOR)
  → Acceptance: Tests still pass, complexity <10, DRY violations <2
```

**Result**: Enforces TDD discipline, ensures test coverage, encourages refactoring.

See examples.md for complete TDD triplet examples.
</practice>

<practice name="acceptance_criteria_templates">
Use consistent AC templates for different task types.

**API endpoint AC template**:

```
- [ ] Returns {status_code} with {field} in response (tested)
- [ ] Response time <{threshold}ms (measured)
- [ ] Returns {error_code} for {error_condition} (tested)
- [ ] Follows {schema} from plan.md (validated)
```

**UI component AC template**:

```
- [ ] Renders {element} with {prop} (tested)
- [ ] {interaction} updates {state} (tested)
- [ ] Lighthouse accessibility score ≥{threshold}
- [ ] Reuses {component} from shared library
```

**Database migration AC template**:

```
- [ ] Migration runs successfully on clean database
- [ ] Rollback works without errors
- [ ] Indexes improve query performance (measured)
- [ ] Foreign keys enforce referential integrity
```

**Result**: Consistent, testable AC across all tasks, speeds up task creation.

See reference.md for complete AC template library.
</practice>
</best_practices>

<quality_standards>
**Good task breakdown**:

- Right-sized tasks (0.5-1 day each, 90% of tasks)
- Clear, testable acceptance criteria (2-4 per task)
- TDD workflow (test tasks before implementation tasks)
- Explicit dependencies (task numbers listed, critical path identified)
- Helpful implementation notes (reuse patterns, file paths, plan.md references)

**Bad task breakdown**:

- Tasks >1.5 days (too large, hard to estimate)
- Vague AC ("code works", "feature done")
- No TDD workflow (tests after implementation)
- Unclear dependencies ("depends on other tasks")
- Missing implementation hints for complex tasks

**Quality targets**:

- Total tasks: 20-30 (adjust for feature complexity)
- Avg task size: 0.5-1 day (4-8 hours)
- Tasks with clear AC: 100%
- Tasks following TDD: 100% for business logic + API + UI
- Task rework rate: <5%
  </quality_standards>

<success_criteria>
Task breakdown phase complete when:

- [ ] 20-30 concrete tasks defined (right-sized, 0.5-1 day each)
- [ ] All tasks have 2-4 testable acceptance criteria
- [ ] TDD workflow established (test tasks before implementation tasks)
- [ ] Dependencies mapped (task numbers, critical path, parallel opportunities)
- [ ] Implementation notes added for complex tasks
- [ ] Task summary generated (total, duration, distribution, critical path)
- [ ] tasks.md committed to git
- [ ] state.yaml updated (currentPhase: tasks, status: completed)

Ready to proceed to /implement phase with clear, testable tasks.
</success_criteria>

<troubleshooting>
**Issue**: Tasks too large (>1.5 days)
**Solution**: Split into subtasks using TDD triplet (test + implement + refactor)

**Issue**: Acceptance criteria vague
**Solution**: Use AC templates from best practices, ensure all are testable

**Issue**: Dependencies unclear
**Solution**: Create dependency graph, list task numbers explicitly

**Issue**: Not enough tasks for complexity
**Solution**: Review plan.md components, ensure each has test + implement tasks

**Issue**: Too many tasks (>40)
**Solution**: Review for granularity, combine trivial tasks, verify feature scope

**Issue**: No TDD workflow
**Solution**: Ensure test task always before implementation task for all components
</troubleshooting>

<reference_guides>
Task breakdown detailed guides:

- Task Sizing Guidelines (reference.md) - 0.5-1 day target, split/combine strategies
- AC Templates (reference.md) - API, UI, database, service AC patterns
- Component Extraction (reference.md) - How to parse plan.md for all components
- Dependency Graphing (reference.md) - Critical path, parallel work identification
- TDD Triplet Examples (examples.md) - Complete test → implement → refactor examples

Next phase:
After task breakdown completes → /implement (execute tasks with TDD workflow)
</reference_guides>

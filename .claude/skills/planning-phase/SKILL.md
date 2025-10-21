---
name: planning-phase
description: "Standard Operating Procedure for /plan phase. Covers research depth, code reuse detection, design pattern selection, and architecture planning."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Planning Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/plan` command with emphasis on code reuse and thorough research.

**Supporting references**:
- [reference.md](reference.md) - Reuse detection strategies, research depth matrix, design pattern catalog
- [examples.md](examples.md) - Good plans (high reuse) vs bad plans (reinventing wheels)
- [scripts/verify-reuse.sh](scripts/verify-reuse.sh) - Script to detect reusable code patterns

---

## Phase Overview

**Purpose**: Transform specifications into detailed implementation plans with emphasis on code reuse, pattern identification, and architecture decisions.

**Inputs**:
- `specs/NNN-slug/spec.md` - Feature specification
- Codebase context (existing patterns, utilities, components)
- Design inspirations (if HAS_UI=true)

**Outputs**:
- `specs/NNN-slug/plan.md` - Detailed implementation plan
- `specs/NNN-slug/research.md` - Research findings and decisions
- Updated `workflow-state.yaml`

**Expected duration**: 15-25 minutes

---

## Prerequisites

**Environment checks**:
- [ ] Spec phase completed (`spec.md` exists)
- [ ] Clarifications resolved (if any existed)
- [ ] Git working tree clean
- [ ] Feature branch active

**Knowledge requirements**:
- Research depth guidelines (3-5 tools for simple, 8-12 for complex)
- Code reuse detection strategies
- Design pattern catalog
- Architecture decision records (ADRs)

---

## Execution Steps

### Step 1: Analyze Specification

**Actions**:
1. Read `spec.md` to understand:
   - Feature requirements and scope
   - Classification flags (HAS_UI, IS_IMPROVEMENT, etc.)
   - Success criteria and constraints
   - Assumptions made during spec phase
2. Identify planning complexity level:
   - **Simple**: Single component, no dependencies (3-5 research tools)
   - **Standard**: Multiple components, some dependencies (5-8 tools)
   - **Complex**: Multi-layer architecture, many dependencies (8-12 tools)

**Quality check**: Do you understand what needs to be built and why?

---

### Step 2: Research Existing Patterns (Code Reuse)

**Actions**:
1. **Search for similar features**:
   ```bash
   # Find similar specs
   grep -r "similar keywords" specs/*/spec.md

   # Find similar implementations
   grep -r "relevant patterns" src/
   ```

2. **Identify reusable components**:
   - Base classes and abstract classes
   - Utility functions and helpers
   - Shared components (if HAS_UI=true)
   - API contracts and interfaces
   - Database models and migrations

3. **Document reuse strategy**:
   ```markdown
   ## Reuse Strategy

   **Existing patterns to leverage**:
   - BaseModel class (api/app/models/base.py) - timestamps, soft delete
   - StandardController (api/app/controllers/base.py) - CRUD operations
   - ValidationMixin (api/app/utils/validation.py) - input validation

   **New patterns to create**:
   - StudentProgressCalculator - reusable across dashboard + reports
   ```

**Quality check**: Have you identified at least 3 reusable patterns for standard/complex features?

---

### Step 3: Research Technology Choices

**Actions**:
1. **For backend features**:
   - Database schema requirements
   - API endpoint patterns
   - Authentication/authorization needs
   - Background job requirements
   - Caching strategies

2. **For UI features**:
   - Component library patterns
   - State management approach
   - Form handling patterns
   - Responsive design requirements
   - Accessibility considerations

3. **For infrastructure features**:
   - Deployment configuration
   - Environment variables
   - Migration scripts
   - Health check endpoints

**Quality check**: Are technology choices consistent with existing codebase patterns?

---

### Step 4: Design Architecture

**Actions**:
1. **Define layers and components**:
   - Data layer (models, schemas)
   - Business logic layer (services, utilities)
   - API layer (endpoints, controllers)
   - UI layer (components, pages) - if HAS_UI=true
   - Integration layer (external APIs, webhooks)

2. **Map dependencies**:
   - Component A depends on Component B
   - Service X requires Database Y
   - Frontend calls API Z

3. **Document architecture decisions**:
   ```markdown
   ## Architecture

   **Components**:
   1. StudentProgressService (business logic)
      - Depends on: Student model, Lesson model, TimeLog model
      - Provides: calculateProgress(), getRecentActivity()

   2. StudentProgressController (API layer)
      - Depends on: StudentProgressService
      - Exposes: GET /api/v1/students/{id}/progress

   3. ProgressDashboard (UI component) - if HAS_UI=true
      - Depends on: StudentProgressController API
      - Displays: Chart, metrics, activity list
   ```

**Quality check**: Can each component be implemented and tested independently?

---

### Step 5: Plan Data Model Changes

**Actions**:
1. **Identify database changes**:
   - New tables/collections needed
   - Schema modifications to existing tables
   - Indexes required for performance
   - Foreign key relationships

2. **Document migration strategy**:
   ```markdown
   ## Database Changes

   **New tables**:
   - `time_logs` (id, student_id, lesson_id, time_spent, created_at)
     - Index on (student_id, lesson_id) for fast lookups
     - Foreign keys to students and lessons tables

   **Schema modifications**:
   - Add `last_activity` column to students table (timestamp, nullable)
   ```

3. **Plan migration safety**:
   - Backward compatibility considerations
   - Rollback strategy
   - Data migration scripts (if needed)

**Quality check**: Are migrations safe to run in production without downtime?

---

### Step 6: Define API Contracts

**Actions**:
1. **Specify endpoints** (for backend/fullstack features):
   ```markdown
   ## API Endpoints

   ### GET /api/v1/students/{id}/progress

   **Request**:
   - Path params: `id` (integer, required)
   - Query params: `period` (string, optional: 7d|30d|90d, default: 30d)

   **Response** (200):
   ```json
   {
     "student_id": 123,
     "completion_rate": 0.75,
     "time_spent": 14400,
     "last_activity": "2025-10-15T14:30:00Z",
     "lessons_completed": 45,
     "lessons_total": 60
   }
   ```

   **Error responses**:
   - 404: Student not found
   - 403: Unauthorized access
   ```

2. **Document request/response schemas**
3. **Specify validation rules**

**Quality check**: Are API contracts versioned and backward compatible?

---

### Step 7: Plan UI/UX Flow (if HAS_UI=true)

**Actions**:
1. **Define screen flow**:
   ```markdown
   ## Screen Flow

   1. Dashboard (/) → Click "View Progress" → Progress Detail Page
   2. Progress Detail → Filter by date range → Updated chart
   3. Progress Detail → Click lesson → Lesson detail modal
   ```

2. **Identify components**:
   - Page components (routes)
   - Feature components (major UI blocks)
   - Shared components (buttons, forms, charts)

3. **Plan state management**:
   - Local component state vs global state
   - API data caching strategy
   - Form state handling

**Quality check**: Is the UI flow clear and matches user expectations?

---

### Step 8: Define Testing Strategy

**Actions**:
1. **Unit tests**:
   - Test business logic in isolation
   - Mock external dependencies
   - Target: ≥80% coverage for business logic

2. **Integration tests**:
   - Test API endpoints with database
   - Test component interactions
   - Target: All critical paths covered

3. **End-to-end tests** (if HAS_UI=true):
   - Test complete user flows
   - Target: Top 3 user journeys covered

**Example**:
```markdown
## Testing Strategy

**Unit tests**:
- StudentProgressService.calculateProgress() - 5 test cases
- StudentProgressService.getRecentActivity() - 3 test cases

**Integration tests**:
- GET /api/v1/students/{id}/progress - 4 scenarios (success, not found, unauthorized, invalid period)

**E2E tests**:
- User views progress dashboard and filters by date range
```

**Quality check**: Are all success criteria from spec.md testable?

---

### Step 9: Estimate Complexity and Task Count

**Actions**:
1. Count anticipated tasks based on components:
   - Data layer tasks (models, migrations)
   - API layer tasks (endpoints, validation)
   - UI layer tasks (components, pages)
   - Testing tasks (unit, integration, e2e)

2. Estimate total effort:
   - Simple features: 10-15 tasks (2-3 days)
   - Standard features: 20-30 tasks (3-5 days)
   - Complex features: 30-50 tasks (5-10 days)

**Example**:
```markdown
## Complexity Estimate

**Task breakdown preview**:
- Data layer: 3 tasks (models + migrations)
- API layer: 5 tasks (endpoints + validation)
- UI layer: 8 tasks (components + pages)
- Testing: 6 tasks (unit + integration + e2e)
- Total: ~22 tasks (estimated 4-5 days)
```

**Quality check**: Does estimate align with spec complexity and deadline?

---

### Step 10: Document Research Findings

**Actions**:
1. Create `research.md` with:
   - Patterns discovered in codebase
   - Technology choices and rationale
   - Design patterns selected
   - Performance considerations
   - Security considerations
   - Accessibility considerations (if HAS_UI=true)

2. Document ADRs (Architecture Decision Records) for major choices:
   ```markdown
   ## ADR: Use Server-Side Pagination

   **Context**: Dashboard may show thousands of lessons per student
   **Decision**: Implement server-side pagination with page size of 20
   **Rationale**: Client-side pagination would degrade performance for large datasets
   **Consequences**: Requires pagination UI component, cursor-based pagination in API
   ```

**Quality check**: Are all major architectural decisions documented with rationale?

---

### Step 11: Write Implementation Plan

**Actions**:
1. Render `plan.md` from template with:
   - Architecture overview
   - Component breakdown
   - Data model changes
   - API contracts
   - UI/UX flow (if HAS_UI=true)
   - Reuse strategy
   - Testing strategy
   - Complexity estimate

2. Organize plan sections logically:
   - Overview
   - Reuse Strategy
   - Architecture
   - Data Model
   - API Contracts
   - UI Components (if applicable)
   - Testing Strategy
   - Implementation Notes

**Quality check**: Can another developer implement the feature from this plan alone?

---

### Step 12: Validate and Commit

**Actions**:
1. Run validation checks:
   - [ ] Reuse strategy documented (≥3 patterns for standard features)
   - [ ] Architecture components clearly defined
   - [ ] API contracts specified (if backend feature)
   - [ ] UI flow mapped (if HAS_UI=true)
   - [ ] Testing strategy defined
   - [ ] Research depth appropriate (3-12 tools used)

2. Commit plan:
   ```bash
   git add specs/NNN-slug/plan.md specs/NNN-slug/research.md
   git commit -m "feat: add implementation plan for <feature-name>

   Plan includes:
   - Reuse strategy (X existing patterns leveraged)
   - Architecture (Y components defined)
   - Testing strategy (Z test categories)

   Research depth: N tools used
   Estimated tasks: M tasks (~P days)
   ```

**Quality check**: Plan committed, workflow-state.yaml updated to planning phase completed.

---

## Common Mistakes to Avoid

### 🚫 Missing Code Reuse Opportunities

**Impact**: Duplicate code, technical debt, wasted implementation time

**Scenario**:
```
Feature: "Add student progress calculation"
Plan: Writes new calculateCompletion() function
Existing: Similar calculateProgress() already exists in 3 other features
Result: 4th duplicate implementation instead of extracting to shared utility
```

**Prevention**:
1. Search codebase for similar patterns before designing
2. Identify base classes, utilities, patterns to reuse
3. Document reuse strategy in plan.md with specific file references
4. Target: ≥60% code reuse rate for standard features

**If encountered**: Extract common logic to utility module, refactor existing code to use it

---

### 🚫 Insufficient Research Depth

**Impact**: Implementation surprises, rework, missed integration points

**Scenario**:
```
Feature: Complex multi-layer dashboard
Research tools used: 2 (constitution check, quick grep)
Result: Missed existing dashboard component, authentication patterns, state management
Result: Rework during implementation, wasted 2 days
```

**Prevention**:
- **Simple features**: 3-5 research tools (constitution, pattern search, similar specs)
- **Standard features**: 5-8 tools (+ UI inventory, performance budgets, integration points)
- **Complex features**: 8-12 tools (+ design inspirations, web search, deep dives)

**Quality check**: Does research depth match feature complexity?

---

### 🚫 Vague Architecture Descriptions

**Impact**: Unclear implementation boundaries, component confusion

**Bad example**:
```markdown
## Architecture
- Frontend calls backend
- Backend queries database
- Returns data to frontend
```

**Good example**:
```markdown
## Architecture

**Components**:
1. **ProgressDashboard** (frontend: src/pages/ProgressDashboard.tsx)
   - Depends on: GET /api/v1/students/{id}/progress
   - State: progressData (from API), dateFilter (local)
   - Renders: ProgressChart, MetricsSummary, ActivityList

2. **StudentProgressController** (backend: api/app/controllers/student_progress.py)
   - Depends on: StudentProgressService
   - Exposes: GET /api/v1/students/{id}/progress
   - Validates: student_id (int), period (enum)

3. **StudentProgressService** (backend: api/app/services/student_progress.py)
   - Depends on: Student, Lesson, TimeLog models
   - Business logic: calculateCompletion(), getRecentActivity()
```

**Prevention**: Specify file paths, dependencies, and responsibilities for each component

---

### 🚫 Missing API Contract Details

**Impact**: Frontend-backend integration issues, rework, confusion

**Bad example**:
```markdown
## API Endpoints
- GET /api/students/progress - returns student progress
```

**Good example**:
```markdown
## API Endpoints

### GET /api/v1/students/{id}/progress

**Request**:
- Path: `id` (integer, required) - Student ID
- Query: `period` (string, optional: 7d|30d|90d, default: 30d)
- Headers: `Authorization: Bearer <token>` (required)

**Response** (200):
```json
{
  "student_id": 123,
  "completion_rate": 0.75,
  "time_spent": 14400,
  "last_activity": "2025-10-15T14:30:00Z"
}
```

**Error responses**:
- 400: Invalid period value
- 403: Unauthorized (not student's teacher)
- 404: Student not found
```

**Prevention**: Document request/response schemas, validation rules, error cases

---

### 🚫 No Testing Strategy

**Impact**: Unclear test coverage expectations, missed test cases

**Prevention**: Define unit/integration/e2e test strategy upfront
- Specify what to test (business logic, API endpoints, UI flows)
- Define coverage targets (≥80% for business logic)
- List critical test scenarios

---

### 🚫 Technology Stack Inconsistencies

**Impact**: Mixed patterns, maintenance burden, team confusion

**Scenario**:
```
Existing: Uses Redux for state management
Plan: Suggests using Context API for new feature
Result: Two state management approaches in same codebase
```

**Prevention**:
1. Research existing technology choices
2. Maintain consistency unless there's strong rationale for change
3. Document ADR if introducing new technology
4. Get team approval for architecture changes

---

## Best Practices

### ✅ Reuse Strategy Documentation

**Approach**:
1. List existing patterns to leverage (with file paths)
2. List new reusable patterns to create
3. Specify how to extract common logic

**Example**:
```markdown
## Reuse Strategy

**Existing patterns to leverage**:
- BaseModel (api/app/models/base.py) - provides id, timestamps, soft_delete
- StandardCRUD (api/app/controllers/base.py) - provides create(), read(), update(), delete()
- useApiData hook (src/hooks/useApiData.ts) - provides data fetching + caching

**New reusable patterns**:
- ProgressCalculator (api/app/utils/progress.py) - reusable across dashboard + reports + exports
- ProgressChart component (src/components/charts/ProgressChart.tsx) - reusable in multiple dashboards
```

**Result**: 60%+ code reuse, faster implementation, consistent patterns

---

### ✅ Research Depth Matrix

**Use case-based research depth**:

| Feature Complexity | Research Tools | What to Research |
|-------------------|---------------|------------------|
| **Simple** (3-5 tools) | Constitution, Pattern search, Similar specs | Alignment, existing patterns, constraints |
| **Standard** (5-8 tools) | + UI inventory, Performance budgets, Integration points | Component reuse, perf targets, dependencies |
| **Complex** (8-12 tools) | + Design inspirations, Web search, Deep integration analysis | Novel patterns, best practices, architecture |

**Quality check**: Tool count matches feature complexity from spec classification

---

### ✅ Architecture Decision Records (ADRs)

**When to create ADR**:
- Choosing between multiple valid approaches
- Introducing new technology or pattern
- Deviating from existing conventions
- Making performance vs simplicity tradeoffs

**ADR format**:
```markdown
## ADR-001: Use Server-Side Pagination

**Context**: Dashboard may display 1000+ lessons per student

**Options considered**:
1. Client-side pagination (simple, but slow for large datasets)
2. Server-side pagination (complex, but performant)
3. Infinite scroll (good UX, but complex state management)

**Decision**: Server-side pagination with page size of 20

**Rationale**:
- Performance: Client-side would load 1000+ records unnecessarily
- Simplicity: More straightforward than infinite scroll
- Consistency: Matches existing patterns in admin dashboard

**Consequences**:
- Requires pagination UI component
- Requires cursor-based pagination in API
- Adds complexity to API endpoint
```

**Result**: Documented rationale, team alignment, future reference

---

## Phase Checklist

**Pre-phase checks**:
- [ ] Spec phase completed (`spec.md` exists)
- [ ] Clarifications resolved (if any)
- [ ] Git working tree clean
- [ ] Feature branch active

**During phase**:
- [ ] Research depth matches complexity (3-12 tools)
- [ ] Code reuse opportunities identified (≥3 for standard features)
- [ ] Architecture components clearly defined
- [ ] Dependencies mapped
- [ ] API contracts specified (if backend feature)
- [ ] UI flow mapped (if HAS_UI=true)
- [ ] Testing strategy defined
- [ ] ADRs created for major decisions

**Post-phase validation**:
- [ ] `plan.md` created with all sections
- [ ] `research.md` created with findings
- [ ] Reuse strategy documented
- [ ] Complexity estimate provided
- [ ] Plan committed to git
- [ ] workflow-state.yaml updated

---

## Quality Standards

**Planning quality targets**:
- Code reuse rate: ≥60%
- Research depth: 3-12 tools (based on complexity)
- Plan completeness: ≥90%
- Component clarity: All components have file paths + dependencies
- API contract completeness: 100% for backend features

**What makes a good plan**:
- High code reuse (leverages existing patterns)
- Clear component boundaries (file paths, dependencies, responsibilities)
- Complete API contracts (request/response schemas, validation, errors)
- Comprehensive testing strategy (unit + integration + e2e)
- Documented architecture decisions (ADRs for major choices)
- Realistic complexity estimate

**What makes a bad plan**:
- Reinventing wheels (missing reuse opportunities)
- Vague architecture ("frontend calls backend")
- Missing API details (no schemas, no error cases)
- No testing strategy
- Undocumented decisions (no rationale for choices)

---

## Completion Criteria

**Phase is complete when**:
- [ ] All pre-phase checks passed
- [ ] All execution steps completed
- [ ] All post-phase validations passed
- [ ] Plan committed to git
- [ ] workflow-state.yaml shows `currentPhase: planning` and `status: completed`

**Ready to proceed to next phase** (`/tasks`):
- [ ] Plan provides sufficient detail for task breakdown
- [ ] All major architectural decisions documented
- [ ] Reuse strategy clear and actionable

---

## Troubleshooting

**Issue**: Not enough code reuse identified
**Solution**: Use `scripts/verify-reuse.sh`, search for similar patterns with Grep, review plan.md from similar features

**Issue**: Research seems shallow (too few tools)
**Solution**: Review research depth matrix, ensure complexity level correct, add more research areas (UI inventory, performance, integration)

**Issue**: Architecture unclear
**Solution**: Add file paths for each component, specify dependencies, clarify responsibilities

**Issue**: API contracts incomplete
**Solution**: Add request/response schemas, validation rules, error cases, authentication requirements

---

_This SOP guides the planning phase. Refer to reference.md for technical details and examples.md for real-world patterns._

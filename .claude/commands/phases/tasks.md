---
description: Generate TDD task breakdown from plan.md with test-first sequencing and mockup-first mode (--ui-first)
allowed-tools: [Read, Bash, Task, AskUserQuestion]
argument-hint: [--ui-first | --standard | --no-input] (optional flags for mode selection)
version: 11.0
updated: 2025-12-09
---

# /tasks — Task Breakdown Generator (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `tasks-phase-agent` via Task(). All task breakdown logic runs in isolated context.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated tasks-phase-agent to generate TDD task breakdown from plan.md.

**Architecture (v11.0 - Phase Isolation):**
```
/tasks → Task(tasks-phase-agent) → tasks.md with TDD structure
```

**Agent responsibilities:**
- Read plan.md and spec.md
- Generate 20-30 tasks with acceptance criteria
- Follow TDD Red-Green-Refactor pattern
- Calculate task sizes (XS/S/M/L)
- Identify dependencies and parallel-safe tasks

**Mode detection:**
- **Epic workflows**: Sprint breakdown with dependency graph
- **Feature workflows**: Tasks organized by user story priority
- **UI-first mode** (--ui-first): Mockup tasks before implementation

**Flags**:
- `--ui-first`: Generate HTML mockup tasks first
- `--standard`: Standard TDD task generation
- `--no-input`: Non-interactive mode for CI/CD

**Workflow position**: `spec → clarify → plan → tasks → implement → optimize → ship`
</objective>

## Legacy Context (for agent reference)

<legacy_context>
Current git status: !`git status --short | head -10`

Current branch: !`git branch --show-current`

Feature spec exists: Auto-detected (epics/_/epic-spec.md OR specs/_/spec.md)

Plan exists: Auto-detected (epics/_/plan.md OR specs/_/plan.md)
</legacy_context>

<process>

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails (exit code != 0): Use AskUserQuestion fallback
4. Set paths:
   - Feature: `SPEC_FILE="${BASE_DIR}/${SLUG}/spec.md"`
   - Epic: `SPEC_FILE="${BASE_DIR}/${SLUG}/epic-spec.md"`
   - Common: `PLAN_FILE="${BASE_DIR}/${SLUG}/plan.md"`, `TASKS_FILE="${BASE_DIR}/${SLUG}/tasks.md"`

**Fallback prompt** (if detection fails):
- Question: "Which workflow are you working on?"
- Options: "Feature" (specs/), "Epic" (epics/)

---

### Step 1: Load User Preferences (3-Tier System)

0. **Load User Preferences (3-Tier System)**:

   **Determine task generation mode using 3-tier preference system:**

   a. **Load configuration file** (Tier 1 - lowest priority):

   ```powershell
   $preferences = & .spec-flow/scripts/utils/load-preferences.ps1 -Command "tasks"
   $configMode = $preferences.commands.tasks.default_mode  # "standard" or "ui-first"
   ```

   b. **Load command history** (Tier 2 - medium priority, overrides config):

   ```powershell
   $history = & .spec-flow/scripts/utils/load-command-history.ps1 -Command "tasks"

   if ($history.last_used_mode -and $history.total_uses -gt 0) {
       $preferredMode = $history.last_used_mode  # Use learned preference
   } else {
       $preferredMode = $configMode  # Fall back to config
   }
   ```

   c. **Check command-line flags** (Tier 3 - highest priority):

   ```javascript
   const args = "$ARGUMENTS".trim();
   const hasUIFirstFlag = args.includes("--ui-first");
   const hasStandardFlag = args.includes("--standard");
   const hasNoInput = args.includes("--no-input");

   let selectedMode;
   let passToScript;

   if (hasNoInput) {
     selectedMode = "standard"; // CI default
     passToScript = ""; // No flag to script
   } else if (hasUIFirstFlag) {
     selectedMode = "ui-first";
     passToScript = "--ui-first";
   } else if (hasStandardFlag) {
     selectedMode = "standard";
     passToScript = ""; // No flag means standard
   } else {
     // No explicit flag - use preference
     selectedMode = preferredMode;
     passToScript = selectedMode === "ui-first" ? "--ui-first" : "";
   }
   ```

   d. **Track usage for learning system**:

   ```powershell
   # Record selection after command completes successfully
   & .spec-flow/scripts/utils/track-command-usage.ps1 -Command "tasks" -Mode $selectedMode
   ```

### Step 1.5: MIGRATION TASK DETECTION (v10.5)

**Detect and generate migration tasks before standard task generation:**

```bash
# Check for migration-plan.md from /plan phase
MIGRATION_PLAN="${BASE_DIR}/${SLUG}/migration-plan.md"

if [ -f "$MIGRATION_PLAN" ]; then
    echo "🗄️  Migration plan detected: $MIGRATION_PLAN"
    HAS_MIGRATIONS=true

    # Parse migration-plan.md for tables/changes
    NEW_TABLES=$(grep -E '#### Table:' "$MIGRATION_PLAN" | wc -l | tr -d ' ')
    MODIFIED_TABLES=$(grep -E '#### Table:.*Modified' "$MIGRATION_PLAN" | wc -l | tr -d ' ')

    echo "   New tables: $NEW_TABLES"
    echo "   Modified tables: $MODIFIED_TABLES"
else
    # Fallback: Check state.yaml for has_migrations flag
    STATE_FILE="${BASE_DIR}/${SLUG}/state.yaml"
    if [ -f "$STATE_FILE" ]; then
        HAS_MIGRATIONS=$(yq eval '.has_migrations // false' "$STATE_FILE" 2>/dev/null || echo "false")
    else
        HAS_MIGRATIONS=false
    fi
fi
```

**If migrations detected, generate Phase 1.5 tasks:**

When `HAS_MIGRATIONS=true`, generate migration tasks BEFORE standard tasks:

```markdown
## Phase 1.5: Database Migrations (BLOCKING)

> Auto-generated from migration-plan.md
> Priority: P0 - Must complete before ORM/API tasks

### T001: [MIGRATION] Create {table_name} table
**Depends On**: T000 (Setup)
**Delegated To**: database-architect
**Priority**: P0 (BLOCKING)
**Framework**: {Alembic | Prisma}
**Source**: migration-plan.md

**Acceptance Criteria**:
- [ ] Migration file created with upgrade()/downgrade()
- [ ] Table schema matches migration-plan.md
- [ ] Foreign keys reference existing tables
- [ ] Indexes created per plan
- [ ] Migration up/down cycle tested
- [ ] Data validation: 0 integrity violations
```

**Task ID Convention:**

| ID Range | Phase | Type | Blocking |
|----------|-------|------|----------|
| T001-T009 | 1.5 | Migration | Yes |
| T010-T019 | 2 | ORM Models | No |
| T020-T029 | 2.5 | Services | No |
| T030+ | 3+ | API/UI | No |

**Dependency enforcement:**

ORM tasks (T010+) must declare dependency on migration tasks:
```markdown
### T010: Create User ORM model
**Depends On**: T001, T002 (Migration tasks MUST complete first)
```

---

### Step 2: GENERATE TASKS.MD (MANDATORY)

**You MUST generate the tasks.md file directly. Do not wait for scripts.**

#### 2.1 Read Source Artifacts

Read these files to extract task requirements:

```
1. ${BASE_DIR}/${SLUG}/plan.md - Extract:
   - Architecture decisions
   - Components to CREATE (new infrastructure)
   - Components to REUSE (existing infrastructure)
   - Data model entities
   - API endpoints

2. ${BASE_DIR}/${SLUG}/spec.md - Extract:
   - User stories with priorities [P1], [P2], [P3]
   - Acceptance criteria for each story
   - UI screens (if HAS_UI feature)

3. ${BASE_DIR}/${SLUG}/research.md (if exists) - Extract:
   - Codebase patterns to follow
   - Existing services to import
```

#### 2.2 Generate Task Structure

Create tasks.md with this structure:

```markdown
# Tasks: {Feature Name}

## [CODEBASE REUSE ANALYSIS]
Scanned: {directories scanned}

[EXISTING - REUSE]
- ✅ {ServiceName} ({file_path})

[NEW - CREATE]
- 🆕 {NewComponent} (no existing pattern)

## [DEPENDENCY GRAPH]
Story completion order:
1. Phase 2: Foundational (blocks all stories)
2. Phase 3: US1 [P1] - {story title}
3. Phase 4: US2 [P2] - {story title}

## [PARALLEL EXECUTION OPPORTUNITIES]
- US1: T010, T011, T012 (different files, no dependencies)

## [IMPLEMENTATION STRATEGY]
**MVP Scope**: Phase 3 (US1) only
**Testing approach**: TDD (red-green-refactor)

---

## Phase 1: Setup

- [ ] T001 Create project structure per plan.md
  - From: plan.md [PROJECT STRUCTURE]

## Phase 2: Foundational

- [ ] T005 {Blocking prerequisite task}
  - REUSE: {existing_service} ({file_path})
  - Pattern: {similar_file_path}

## Phase 3: User Story 1 [P1] - {Story Title}

**Story Goal**: {Goal from spec.md}

### Tests
- [ ] T010 [RED] Write failing test for {behavior}
- [ ] T011 [GREEN] Implement {component} to pass test
- [ ] T012 [REFACTOR] Clean up {component}

### Implementation
- [ ] T015 [US1] Create {Model/Service/Component}
  - REUSE: {existing} ({path})
  - From: plan.md:{line_numbers}

## Phase N: Polish

- [ ] T080 Add error handling
- [ ] T085 Document rollback procedure
```

#### 2.3 Task Format Rules

Each task MUST have:
- **Checkbox**: `- [ ]` (GitHub-trackable)
- **Task ID**: Sequential T001, T002, T003...
- **[Phase] marker**: [RED], [GREEN], [REFACTOR], or [USn]
- **Description**: Concrete action + exact file path
- **REUSE**: What existing code to use (if applicable)
- **From**: Source reference (plan.md:45-60)

#### 2.4 Write tasks.md

Use Write tool to create `${BASE_DIR}/${SLUG}/tasks.md` with generated content.

#### 2.5 Verify Creation

Use Read tool to verify tasks.md was created successfully.

---

### Step 2.6: Ultrathink Checkpoint — Simplify Ruthlessly

> **Philosophy**: "Is each task necessary, or can we achieve more with less?"

After generating tasks.md, apply ruthless simplification.

**Display thinking prompt:**

```
┌─────────────────────────────────────────────────────────────┐
│ 💭 ULTRATHINK CHECKPOINT: Simplify Ruthlessly               │
├─────────────────────────────────────────────────────────────┤
│ Review each task and ask:                                   │
│                                                             │
│ • Is this task NECESSARY or just nice-to-have?              │
│ • Can any tasks be COMBINED?                                │
│ • Are we adding complexity that isn't justified?            │
│ • What tasks could we REMOVE without losing core value?     │
└─────────────────────────────────────────────────────────────┘
```

**Task Count Validation:**

```bash
# Count generated tasks
TASK_COUNT=$(grep -c "^- \[ \] T[0-9]" "${TASKS_FILE}" || echo "0")

echo "Generated tasks: $TASK_COUNT"

# Thresholds from ultrathink-integration.yaml
MAX_WITHOUT_JUSTIFICATION=25
REQUIRE_RATIONALE_ABOVE=20

if [ "$TASK_COUNT" -gt "$MAX_WITHOUT_JUSTIFICATION" ]; then
    echo "⚠️  High task count ($TASK_COUNT) - requires complexity rationale"
fi
```

**Simplification Questions** (for complex features):

```json
{
  "question": "This feature has $TASK_COUNT tasks. Would you like to simplify?",
  "header": "Simplify",
  "multiSelect": false,
  "options": [
    {"label": "Proceed as-is", "description": "All tasks are necessary"},
    {"label": "Review for removal", "description": "Let's identify tasks to cut"},
    {"label": "Split into phases", "description": "Defer some tasks to future iteration"}
  ]
}
```

**If "Review for removal" selected:**

Analyze tasks and suggest removals:

```markdown
## Task Simplification Review

| Task | Recommendation | Rationale |
|------|----------------|-----------|
| T025 | REMOVE | Nice-to-have, not in core requirements |
| T030, T031 | COMBINE | Same file, sequential operations |
| T045 | DEFER | Enhancement, not MVP |

**Simplification Result**:
- Before: {X} tasks
- After: {Y} tasks
- Removed: {list of removed task IDs}
- Combined: {list of combined tasks}
- Deferred: {list of deferred to future iteration}
```

**Add complexity rationale** (for 20+ tasks):

```markdown
## Complexity Rationale

This feature requires {X} tasks because:
1. [Reason 1 - e.g., "Multiple user stories with distinct acceptance criteria"]
2. [Reason 2 - e.g., "TDD requires separate RED/GREEN/REFACTOR cycles"]
3. [Reason 3 - e.g., "Database migrations must precede ORM code"]

**Simplification attempted**:
- Combined {N} redundant tasks
- Deferred {M} non-MVP tasks
- Final count represents minimum viable implementation
```

---

### Step 2.5: EPIC SPRINT BREAKDOWN (Epic Workflows Only)

**If WORKFLOW_TYPE == "epic"**, generate sprint breakdown:

#### 2.5.1 Analyze Complexity

Read plan.md and count:
- Subsystems (frontend, backend, database, etc.)
- Estimated hours (from plan.md estimates)
- API endpoints to create
- Database tables to create

#### 2.5.2 Create Sprint Boundaries

```markdown
# Sprint Plan: {Epic Name}

## Sprint Structure

| Sprint | Subsystem | Dependencies | Duration |
|--------|-----------|--------------|----------|
| S01 | Backend + Database | None | {days} |
| S02 | Frontend | S01 | {days} |
| S03 | Integration + E2E | S01, S02 | {days} |

## Dependency Graph

```
S01 (Backend) ──┐
                ├──> S03 (Integration)
S02 (Frontend) ─┘
```

## Critical Path

S01 → S02 → S03 (total: {days})
```

#### 2.5.3 Write sprint-plan.md

Use Write tool to create `${BASE_DIR}/${SLUG}/sprint-plan.md`.

#### 2.5.4 Generate Per-Sprint Tasks

Create separate tasks in tasks.md grouped by sprint:

```markdown
## Sprint S01: Backend + Database

### T001-T020: Backend tasks...

## Sprint S02: Frontend

### T021-T040: Frontend tasks (Depends On: S01 complete)

## Sprint S03: Integration

### T041-T060: Integration tasks (Depends On: S01, S02 complete)
```

---

### Step 3: UI-First Mode (if --ui-first flag)

**If UI_FIRST == true**, generate mockup tasks BEFORE implementation:

#### 3.1 Detect Multi-Screen Flow

Count screens in spec.md user stories:
- ≥3 screens → Generate navigation hub (index.html)
- <3 screens → Generate individual screen mockups only

#### 3.2 Generate Mockup Tasks

Add Phase 1 tasks for mockups:

```markdown
## Phase 1: Design Mockups (APPROVAL REQUIRED)

- [ ] T001 [DESIGN] Create navigation hub (index.html)
  - Output: ${BASE_DIR}/${SLUG}/mockups/index.html
  - Include: Links to all screens, keyboard shortcuts

- [ ] T002 [DESIGN] Create {screen_name} mockup
  - Output: ${BASE_DIR}/${SLUG}/mockups/{screen_name}.html
  - States: success, loading, error, empty
  - Tokens: Link to design/systems/tokens.css

- [ ] T003 [APPROVAL-GATE] Review and approve mockups
  - Preview: Open mockups/*.html in browser
  - Checklist: mockup-approval-checklist.md
  - BLOCKS: All implementation tasks
```

---

### Step 4: Generate E2E Test Tasks (Epic Workflows Only)

**For epic workflows only**, generate E2E test tasks:

   a. **Analyze user workflows** from spec.md:

   - Read `$SPEC_FILE` (auto-detected: `epics/*/epic-spec.md` or `specs/*/spec.md`)
   - Extract "User Stories" section
   - Identify critical user journeys (flows that span multiple screens/endpoints)
   - Look for integration points: API → DB, Frontend → Backend, External APIs

   b. **Map user journeys to E2E test scenarios**:

   ```javascript
   // Example: Extract user story
   const userStory =
     "As a user, I want to create an account so I can access the dashboard";

   // Map to E2E scenario
   const e2eScenario = {
     journey: "User Registration",
     given: "User navigates to /signup",
     when: "User fills form and submits",
     then: "Account created, redirected to /dashboard",
     externalIntegrations: ["Email service (SendGrid)", "Database (Postgres)"],
     testFile: "e2e/auth/registration.spec.ts",
   };
   ```

   c. **Generate e2e-tests.md**:

   - Use template from `.spec-flow/templates/e2e-tests-template.md`
   - Create ≥3 critical user journey tests
   - Include:
     - Complete user workflows (start → finish)
     - External integration testing (APIs, CLIs, webhooks)
     - Expected outcomes in production systems (GitHub commits, DB records)
     - Test isolation strategy (Docker containers, test databases)
   - Save to `epics/{NNN}-{slug}/e2e-tests.md`

   d. **Add E2E test tasks to tasks.md**:

   - Append E2E test batch group to existing tasks.md
   - One task per critical journey
   - Priority: P1 (critical for deployment)
   - Reference e2e-tests.md for acceptance criteria
   - Example task structure:

     ```markdown
     ## E2E Testing

     ### T030: Implement User Registration E2E Test

     **Depends On**: T015 (Backend API), T022 (Frontend Form)
     **Source**: e2e-tests.md:10-25
     **Priority**: P1

     **Acceptance Criteria**:

     - [ ] Test creates new user via /signup endpoint
     - [ ] Test verifies user in database
     - [ ] Test validates email sent via SendGrid (mock)
     - [ ] Test verifies redirect to /dashboard
     - [ ] Test runs in isolated Docker container

     **Implementation Notes**:

     - Use Playwright/Cypress for browser automation
     - Mock external APIs (SendGrid) with msw or nock
     - Use test database with seed data
     ```

   e. **Update state.yaml**:

   ```yaml
   artifacts:
     e2e_tests: epics/{NNN}-{slug}/e2e-tests.md
   ```

   f. **Skip for feature workflows**:

   - Feature workflows can have E2E tests, but generation is optional
   - Only auto-generate for epics (multi-subsystem, complex workflows)

---

### Step 5: Verify and Commit

#### 5.1 Verify Generated Artifacts

Use Read tool to verify files were created:
- Epic: `sprint-plan.md`, `tasks.md`, `e2e-tests.md`
- Feature: `tasks.md`
- UI-first: `tasks.md`, `mockups/` directory structure

#### 5.2 Update NOTES.md

Append Phase 2 checkpoint to `${BASE_DIR}/${SLUG}/NOTES.md`:

```markdown
## Phase 2: Tasks ({current_date})

**Summary**:
- Total tasks: {count}
- User story tasks: {count}
- Parallel opportunities: {count}
- Task file: ${BASE_DIR}/${SLUG}/tasks.md

**Checkpoint**:
- ✅ Tasks generated
- ✅ User story organization: Complete
- ✅ Dependency graph: Created
- 📋 Ready for: /implement
```

#### 5.3 Git Commit

```bash
git add ${BASE_DIR}/${SLUG}/tasks.md ${BASE_DIR}/${SLUG}/NOTES.md
git commit -m "design:tasks: generate {count} concrete tasks organized by user story

- {total} tasks (setup, foundational, user stories, polish)
- {story_count} user story tasks
- {parallel_count} parallel opportunities

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Step 6: Present Summary and Next Action

Present to user:

```
✅ TASKS GENERATED

File: ${BASE_DIR}/${SLUG}/tasks.md

📊 Summary:
- Total: {count} tasks
- User story tasks: {count} (organized by priority)
- Parallel opportunities: {count} tasks marked [P]

📋 Task organization:
- Phase 1 (Setup): Infrastructure and dependencies
- Phase 2 (Foundational): Blocking prerequisites
- Phase 3+ (User Stories): Story-specific implementation
- Phase N (Polish): Cross-cutting concerns

📋 NEXT: /implement (auto-continues)
```
</process>

<verification>
Before completing, verify:
- Workspace type correctly detected (epic vs feature)
- Epic workflows: sprint-plan.md validates, contracts locked, tasks.md per sprint, e2e-tests.md generated
- Feature workflows: tasks.md has 20-30 tasks, organized by user story
- UI-first: mockup tasks generated, checklist created for reference
- E2E tests (epic only): ≥3 critical user journeys documented, E2E tasks added to tasks.md
- Git commit successful with task summary
- Auto-proceeding to /implement
</verification>

<success_criteria>
**Epic workflows**:

- sprint-plan.md exists and validates
- Dependency graph shows execution layers
- API contracts locked in contracts/
- Per-sprint tasks.md files created
- Critical path calculated
- e2e-tests.md generated with ≥3 critical user journeys
- E2E test tasks added to tasks.md (P1 priority)

**Feature workflows**:

- tasks.md has 20-30 tasks
- Tasks organized by user story priority
- TDD sequence followed (test → impl → refactor)
- Parallel batches identified
- Each task has: ID, Title, Depends On, Acceptance Criteria, Source (line numbers)

**UI-first mode**:

- Mockup tasks generated (hub + screens if multi-screen)
- mockup-approval-checklist.md created for reference
- Auto-proceeds to implementation (no blocking gate)

**All workflows**:

- Anti-hallucination rules followed (no tasks for non-existent code)
- Tasks trace to plan.md/spec.md source lines
- Dependencies verified (no circular dependencies)
- Git commit created
- User knows next action
  </success_criteria>

<mental_model>
**Workflow state machine (Autopilot)**:

```
Setup
  ↓
[WORKSPACE TYPE] (epic vs feature)
  ↓
{IF epic}
  → Sprint Breakdown
    → Lock Contracts
    → Generate Per-Sprint Tasks
{ELSE IF feature + --ui-first}
  → Generate Mockup Tasks
    → Auto-proceed to /implement
{ELSE}
  → Generate Traditional Tasks (20-30)
{ENDIF}
  ↓
Git Commit
  ↓
Auto-proceed to /implement
```

**Auto-continues to /implement after task generation** (no manual gate).
</mental_model>

<anti_hallucination_rules>
**CRITICAL**: Follow these rules to prevent creating impossible tasks.

1. **Never create tasks for code you haven't verified exists**

   - ❌ BAD: "T001: Update the UserService.create_user method"
   - ✅ GOOD: First search for UserService, then create task based on what exists

2. **Cite plan.md when deriving tasks**

   - Each task should trace to plan.md section
   - Example: "T001 implements data model from plan.md:45-60"

3. **Verify test file locations before creating test tasks**

   - Before task "Add test_user_service.py", check if tests/ directory exists
   - Use Glob to find test patterns: `**/test_*.py` or `**/*_test.py`

4. **Quote acceptance criteria from spec.md exactly**

   - Copy user story acceptance criteria verbatim to task AC
   - Don't paraphrase or add unstated criteria

5. **Verify dependencies between tasks**
   - Before marking T002 depends on T001, confirm T001 creates what T002 needs
   - Don't create circular dependencies

**Why this matters**: Hallucinated tasks create impossible work. Tasks referencing non-existent code waste implementation time. Clear, verified tasks reduce implementation errors by 50-60%.

See `.claude/skills/task-breakdown-phase/reference.md` for full anti-hallucination rules and examples.
</anti_hallucination_rules>

<epic_sprint_breakdown>
**Epic workflows only** (detected via `epics/*/epic-spec.md`):

When tasks detects an epic workflow, it performs sprint breakdown with parallel execution planning.

### Complexity Analysis

**Decision criteria for multiple sprints:**

- Subsystems ≥ 2 (e.g., frontend + backend)
- Estimated hours > 16 (more than 2 work days)
- API endpoints > 5 (large API surface)
- Database tables > 3 (complex data model)

### Sprint Boundaries

**Typical sprint structure:**

- **S01**: Backend + Database (API contracts, business logic)
- **S02**: Frontend (UI components, state management) - depends on S01
- **S03**: Integration + Testing (E2E tests) - depends on S01 + S02

### Contract Locking

**Before parallel work:**

- Identify API contracts from plan.md
- Generate OpenAPI 3.0 specs in `contracts/`
- Producer sprint (S01) locks contract
- Consumer sprint (S02) consumes contract
- No integration surprises (contract violations caught early)

### Generated Artifacts

**sprint-plan.md structure:**

```xml
<sprint_plan>
  <metadata>...</metadata>
  <sprints>...</sprints>
  <execution_layers>...</execution_layers>
  <critical_path>...</critical_path>
</sprint_plan>
```

**Benefits:**

- Parallel execution reduces critical path duration
- Locked contracts enable independent frontend/backend work
- Dependency graph prevents blocking work
- Velocity multiplier: 2-3x speedup for independent layers

See `.claude/skills/task-breakdown-phase/reference.md` for full epic sprint breakdown workflow (Steps 1-9).
</epic_sprint_breakdown>

<ui_first_mode>
**Trigger**: `--ui-first` flag passed to /tasks

**Behavior:**

- Generates HTML mockup tasks before implementation
- Creates multi-screen navigation hub (index.html) if ≥3 screens detected
- Creates individual screen mockups with state switching (S key)
- Creates mockup-approval-checklist.md for reference
- Auto-proceeds to /implement (no blocking gate)

### Multi-Screen Detection

**Auto-detected when:**

- ≥3 distinct screens mentioned in spec.md user stories
- Navigation keywords detected ("navigate to", "redirects to", "shows modal")
- Multi-step flows identified ("wizard", "onboarding", "checkout process")

**Mockup structure (≥3 screens):**

```
${BASE_DIR}/NNN-slug/mockups/
├── index.html                   # Navigation hub
├── screen-01-[name].html        # Individual screens
├── screen-02-[name].html
├── screen-03-[name].html
├── _shared/
│   ├── navigation.js            # Keyboard shortcuts (H=hub, 1-9=screens)
│   └── state-switcher.js        # State cycling (S key)
└── mockup-approval-checklist.md
```

**Mockup structure (1-2 screens):**

```
${BASE_DIR}/NNN-slug/mockups/
├── [screen-name].html
└── mockup-approval-checklist.md
```

### Mockup Quality Checklist (Reference)

**Generated mockups should have:**

- Multi-screen flow: All screens accessible via keyboard (1-9)
- State completeness: All 4 states (Success, Loading, Error, Empty)
- Design system compliance: Colors/spacing from theme.css
- Component reuse: Match ui-inventory.md patterns
- Accessibility: Contrast ≥4.5:1, touch targets ≥24x24px

**mockup-approval-checklist.md** is created for reference but does not block workflow. Implementation proceeds automatically.

### Component Extraction Tasks

**During `/implement`**, component extraction (Step 0.7) generates extraction tasks. These tasks are appended to tasks.md:

**Extraction task structure:**

```markdown
## Component Extraction (from prototype-patterns.md)

### TEXP-001: Extract Button component
**Source Screens**: login.html, signup.html, dashboard.html
**Occurrences**: 12 (Must extract)
**Priority**: P0

**Variants**:
- primary, secondary, outline, ghost, danger

**States**:
- [ ] default
- [ ] hover (bg-primary-hover)
- [ ] focus (ring-2 ring-primary/30)
- [ ] active (scale-95)
- [ ] disabled (opacity-50, cursor-not-allowed)
- [ ] loading (animate-spin icon)

**Props Interface**:
```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size: 'sm' | 'md' | 'lg';
  icon?: React.ReactNode;
  loading?: boolean;
  disabled?: boolean;
  children: React.ReactNode;
}
```

**Tailwind Classes**:
`inline-flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-md transition-all duration-100`

### TEXP-002: Extract Card component
**Source Screens**: dashboard.html, settings.html
**Occurrences**: 8 (Must extract)
**Priority**: P0

**Variants**:
- default, elevated, bordered

**Props Interface**:
```typescript
interface CardProps {
  padding?: 'sm' | 'md' | 'lg';
  shadow?: 'none' | 'sm' | 'md' | 'lg';
  header?: React.ReactNode;
  footer?: React.ReactNode;
  children: React.ReactNode;
}
```
```

**Task ID convention:**

| ID Range | Type | Priority |
|----------|------|----------|
| TEXP-001 to TEXP-009 | Must extract (3+ occurrences) | P0 |
| TEXP-010 to TEXP-019 | Consider extraction (2 occurrences) | P1 |
| TEXP-020+ | Low priority (1 occurrence) | P2 |

**Extraction scoring (from mockup-extraction skill):**

| Occurrences | Score | Action |
|-------------|-------|--------|
| 1 | Low | Inline styles OK |
| 2 | Medium | Consider extraction |
| 3+ | High | **Must extract** |
| 5+ | Critical | Extract with variants |

**Dependency chain:**

```
Mockup Tasks (T00x) → Mockup Approval → Extraction Tasks (TEXP-xxx) → Implementation Tasks (T0xx)
```

Extraction tasks block implementation until components are extracted and documented in prototype-patterns.md.

See `.claude/skills/mockup-extraction/SKILL.md` for full extraction workflow.
</ui_first_mode>

<task_structure>
**Each task includes:**

- **ID**: T001, T002, ... (deterministic, sequential)
- **Title**: Clear, actionable description
- **Depends On**: T000 (or specific task IDs)
- **Acceptance Criteria**: Copied from spec.md or derived from plan.md
- **Source**: plan.md:45-60 (exact line numbers)

**Example task:**

```markdown
### T001: Create User Entity Schema

**Depends On**: T000
**Source**: plan.md:145-160

**Acceptance Criteria**:

- [ ] User table created with id, email, name, created_at
- [ ] Email unique constraint enforced
- [ ] Migration file generated
- [ ] Alembic upgrade/downgrade tested

**Implementation Notes**:

- Follow plan.md data model (SQLAlchemy ORM)
- Reuse existing migration template from api/migrations/
```

**TDD sequencing:**

1. Test task (write failing tests)
2. Implementation task (make tests pass)
3. Refactor task (improve code quality, optional)

**Parallel batching:**

- Batch 1: Frontend tasks (no backend dependencies)
- Batch 2: Backend tasks (no frontend dependencies)
- Batch 3: Integration tasks (depends on both)

See `.claude/skills/task-breakdown-phase/reference.md` for task structure guidelines and TDD patterns.
</task_structure>

<standards>
**Industry Standards**:
- **TDD**: [Test-Driven Development (Martin Fowler)](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- **Parallel Execution**: [Critical Path Method](https://en.wikipedia.org/wiki/Critical_path_method)
- **API Contracts**: [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- **Multi-Screen UX**: [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)

**Workflow Standards**:

- All tasks cite source lines from plan.md or spec.md
- Anti-hallucination rules enforced (verify code exists before creating tasks)
- TDD sequence followed within each task group
- Dependencies verified (no circular dependencies)
- Idempotent execution (safe to re-run)
  </standards>

<notes>
**Self-sufficient execution**: This command generates tasks.md directly using the instructions in the `<process>` section. No external scripts are required.

**Optional script**: The bash implementation at `.spec-flow/scripts/bash/tasks-workflow.sh` provides validation utilities but task generation happens via Claude following the process steps above.

**Reference documentation**: Anti-hallucination rules, epic sprint breakdown (9 steps), multi-screen mockup workflow, TDD sequencing, and all detailed procedures are in `.claude/skills/task-breakdown-phase/reference.md`.

**Version**: v3.0 (2025-12-04) - Made self-sufficient without script dependency. Added explicit task generation, sprint breakdown, and migration detection instructions.

**Next steps after tasks**:

- Feature: `/implement` (auto-continues)
- Epic: `/implement-epic` (parallel sprint execution with E2E tests)
- UI-first: `/implement` → mockups → approval → `/implement --continue`
</notes>

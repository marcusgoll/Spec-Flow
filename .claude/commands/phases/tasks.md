---
description: Generate TDD task breakdown from plan.md with test-first sequencing and mockup-first mode (--ui-first)
allowed-tools: [Read, Grep, Glob, Bash(python .spec-flow/scripts/spec-cli.py tasks:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git branch:*), Bash(jq:*), Bash(ls:*), Bash(wc:*)]
argument-hint: [--ui-first | --standard | --no-input] (optional flags for mode selection)
version: 2.0
updated: 2025-11-20
---

<context>
Current git status: !`git status --short | head -10`

Current branch: !`git branch --show-current`

Feature spec exists: !`ls specs/*/spec.md 2>/dev/null | wc -l` file(s)

Plan exists: !`ls specs/*/plan.md 2>/dev/null | wc -l` file(s)

Feature workspace: !`python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only 2>/dev/null | jq -r '.FEATURE_DIR // "Not initialized"'`

Workspace type: !`test -f epics/*/epic-spec.xml && echo "epic" || echo "feature"`
</context>

<objective>
Generate concrete TDD tasks from design artifacts with test-first sequencing.

**Mode detection:**
- **Epic workflows**: Auto-generates sprint breakdown with dependency graph and contract locking (multiple sprints for >16h work or 2+ subsystems)
- **Feature workflows**: Generates 20-30 tasks organized by user story priority
- **UI-first mode** (--ui-first flag): Generates HTML mockup tasks first, blocks implementation until approval

This ensures traceable, deterministic task generation that prevents hallucinated tasks referencing non-existent code.

**Dependencies**:
- Git repository initialized
- Feature spec (spec.md) and plan (plan.md) completed
- Required tools: git, jq

**Flags**:
- `--ui-first`: Generate HTML mockup tasks before implementation (sets manual gate for mockup approval)
- `--standard`: Standard TDD task generation (no mockups) - explicit override of config/history
- `--no-input`: Non-interactive mode for CI/CD - uses default (standard) mode
</objective>

<process>
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
      const hasUIFirstFlag = args.includes('--ui-first');
      const hasStandardFlag = args.includes('--standard');
      const hasNoInput = args.includes('--no-input');

      let selectedMode;
      let passToScript;

      if (hasNoInput) {
          selectedMode = 'standard';  // CI default
          passToScript = '';  // No flag to script
      } else if (hasUIFirstFlag) {
          selectedMode = 'ui-first';
          passToScript = '--ui-first';
      } else if (hasStandardFlag) {
          selectedMode = 'standard';
          passToScript = '';  // No flag means standard
      } else {
          // No explicit flag - use preference
          selectedMode = preferredMode;
          passToScript = selectedMode === 'ui-first' ? '--ui-first' : '';
      }
      ```

   d. **Track usage for learning system**:
      ```powershell
      # Record selection after command completes successfully
      & .spec-flow/scripts/utils/track-command-usage.ps1 -Command "tasks" -Mode $selectedMode
      ```

1. **Execute task generation workflow** via spec-cli.py:
   ```bash
   python .spec-flow/scripts/spec-cli.py tasks $passToScript
   ```

   The tasks-workflow.sh script performs:

   a. **Detect workspace type**: Epic vs Feature
      - Epic: If `epics/*/epic-spec.xml` exists
      - Feature: Otherwise

   b. **Epic workflows only** (Sprint breakdown):
      - Analyze plan complexity (subsystems, hours, endpoints, tables)
      - Create sprint boundaries (Backend + DB = S01, Frontend = S02, Integration = S03)
      - Build dependency graph with execution layers
      - Lock API contracts (OpenAPI 3.0 specs in contracts/)
      - Generate sprint-plan.xml with critical path analysis
      - Generate tasks.md for each sprint in sprints/{S01,S02,S03}/
      - Commit sprint plan with summary

   c. **Feature workflows** (Traditional task generation):
      - Load artifacts (spec.md, plan.md, research.md)
      - Extract user stories from spec.md
      - Generate 20-30 tasks with deterministic IDs (T001-T030)
      - Map tasks to user story priority
      - UI-first mode: Generate HTML mockup tasks if --ui-first
      - TDD sequence: Order as spec → test → impl → refactor
      - Parallel batching: Detect independent tasks (frontend vs backend)
      - Git commit with task summary

   d. **UI-first mode** (if --ui-first flag):
      - Detect multi-screen workflow (≥3 screens in spec.md)
      - Generate mockup tasks: navigation hub (index.html) + individual screens
      - Create mockup-approval-checklist.md
      - Set manual gate in workflow-state.yaml (blocks /implement)
      - Tasks include: hub, screens, navigation wiring, approval checklist

2. **Generate E2E Test Suite** (Epic workflows only):

   **For epic workflows only**, after task generation completes:

   a. **Analyze user workflows** from spec.md:
      - Read `epics/*/spec.md` or `specs/*/spec.md`
      - Extract "User Stories" section
      - Identify critical user journeys (flows that span multiple screens/endpoints)
      - Look for integration points: API → DB, Frontend → Backend, External APIs

   b. **Map user journeys to E2E test scenarios**:
      ```javascript
      // Example: Extract user story
      const userStory = "As a user, I want to create an account so I can access the dashboard";

      // Map to E2E scenario
      const e2eScenario = {
        journey: "User Registration",
        given: "User navigates to /signup",
        when: "User fills form and submits",
        then: "Account created, redirected to /dashboard",
        externalIntegrations: ["Email service (SendGrid)", "Database (Postgres)"],
        testFile: "e2e/auth/registration.spec.ts"
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

   e. **Update workflow-state.yaml**:
      ```yaml
      artifacts:
        e2e_tests: epics/{NNN}-{slug}/e2e-tests.md
      ```

   f. **Skip for feature workflows**:
      - Feature workflows can have E2E tests, but generation is optional
      - Only auto-generate for epics (multi-subsystem, complex workflows)

3. **Read generated artifacts**:
   - Epic: `sprint-plan.xml`, `contracts/*.yaml`, `sprints/*/tasks.md`, `e2e-tests.md`
   - Feature: `tasks.md`
   - UI-first: `tasks.md` with mockup tasks, `mockup-approval-checklist.md`

4. **Present task summary** to user with task count, story breakdown, TDD coverage, E2E test count (epic only)

5. **Suggest next action** based on workflow type
</process>

<verification>
Before completing, verify:
- Workspace type correctly detected (epic vs feature)
- Epic workflows: sprint-plan.xml validates, contracts locked, tasks.md per sprint, e2e-tests.md generated
- Feature workflows: tasks.md has 20-30 tasks, organized by user story
- UI-first: mockup tasks generated, manual gate set in workflow-state.yaml
- E2E tests (epic only): ≥3 critical user journeys documented, E2E tasks added to tasks.md
- Git commit successful with task summary
- Next-step suggestions presented
</verification>

<success_criteria>
**Epic workflows**:
- sprint-plan.xml exists and validates
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
- mockup-approval-checklist.md created
- workflow-state.yaml manual gate set
- Implementation tasks blocked until approval

**All workflows**:
- Anti-hallucination rules followed (no tasks for non-existent code)
- Tasks trace to plan.md/spec.md source lines
- Dependencies verified (no circular dependencies)
- Git commit created
- User knows next action
</success_criteria>

<mental_model>
**Workflow state machine**:
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
    → Set Manual Gate (blocks /implement)
{ELSE}
  → Generate Traditional Tasks (20-30)
{ENDIF}
  ↓
Git Commit
  ↓
[SUGGEST NEXT STEP]
```

**Next steps after tasks**:
- Feature: `/validate` (recommended) or `/implement`
- Epic: `/implement` (parallel sprint execution)
- UI-first: `/implement` → Generate mockups → Approval → `/implement --continue`
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
**Epic workflows only** (detected via `epics/*/epic-spec.xml`):

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
- Identify API contracts from plan.xml
- Generate OpenAPI 3.0 specs in `contracts/`
- Producer sprint (S01) locks contract
- Consumer sprint (S02) consumes contract
- No integration surprises (contract violations caught early)

### Generated Artifacts

**sprint-plan.xml structure:**
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
- Creates mockup-approval-checklist.md
- Sets manual gate in workflow-state.yaml (blocks /implement)

### Multi-Screen Detection

**Auto-detected when:**
- ≥3 distinct screens mentioned in spec.md user stories
- Navigation keywords detected ("navigate to", "redirects to", "shows modal")
- Multi-step flows identified ("wizard", "onboarding", "checkout process")

**Mockup structure (≥3 screens):**
```
specs/NNN-slug/mockups/
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
specs/NNN-slug/mockups/
├── [screen-name].html
└── mockup-approval-checklist.md
```

### Mockup Approval Process

**After mockup generation:**
1. Open navigation hub: `specs/NNN-slug/mockups/index.html`
2. Review each screen (press 1-9 to navigate, S to cycle states)
3. Complete mockup-approval-checklist.md
4. Update workflow-state.yaml: `manual_gates.mockup_approval.status = approved`
5. Continue implementation: `/feature continue` or `/implement`

### Quality Gates

**Before approval:**
- Multi-screen flow: All screens accessible via keyboard (1-9)
- State completeness: All 4 states (Success, Loading, Error, Empty)
- Design system compliance: Colors/spacing from tokens.css
- Component reuse: Match ui-inventory.md patterns
- Accessibility: Contrast ≥4.5:1, touch targets ≥24x24px

See `.claude/skills/task-breakdown-phase/reference.md` for full multi-screen mockup workflow.
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
**Script location**: The bash implementation is at `.spec-flow/scripts/bash/tasks-workflow.sh`. It is invoked via spec-cli.py for cross-platform compatibility.

**Reference documentation**: Anti-hallucination rules, epic sprint breakdown (9 steps), multi-screen mockup workflow, TDD sequencing, and all detailed procedures are in `.claude/skills/task-breakdown-phase/reference.md`.

**Version**: v2.0 (2025-11-17) - Added epic sprint breakdown, multi-screen mockup workflow, UI-first mode with manual approval gate.

**Next steps after tasks**:
- Feature: `/validate` (recommended) or `/implement`
- Epic: `/implement-epic` (parallel sprint execution with E2E tests)
- UI-first: `/implement` → mockups → approval → `/implement --continue`
</notes>

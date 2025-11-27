# Task Breakdown Phase - Reference Documentation

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent creating impossible tasks.

### 1. Never create tasks for code you haven't verified exists

- ❌ BAD: "T001: Update the UserService.create_user method"
- ✅ GOOD: First search for UserService, then create task based on what exists
- Use Glob to find files before creating file modification tasks

**Example verification:**

```bash
# Before creating task to modify UserService
glob "**/*user*service*.py"

# If found: Create task with exact file path
# If not found: Create task to create new UserService
```

### 2. Cite plan.md when deriving tasks

- Each task should trace to plan.md section
- Example: "T001 implements data model from plan.md:45-60"
- Don't create tasks not mentioned in the plan

**Traceability format:**

```markdown
### T001: Create User Entity Schema

**Source**: plan.md:145-160

**Acceptance Criteria**:

- [ ] User table created with id, email, name, created_at
- [ ] Email unique constraint enforced
```

### 3. Verify test file locations before creating test tasks

- Before task "Add test_user_service.py", check if tests/ directory exists
- Use Glob to find test patterns: `**/test_*.py` or `**/*_test.py`
- Don't assume test structure matches your expectations

**Test structure detection:**

```bash
# Check test pattern
glob "tests/**/*.py"  # Python (tests/ directory)
glob "**/*.test.ts"   # Jest/Vitest (colocated tests)
glob "**/*_test.go"   # Go (colocated tests)
```

### 4. Quote acceptance criteria from spec.md exactly

- Copy user story acceptance criteria verbatim to task AC
- Don't paraphrase or add unstated criteria
- If criteria missing, flag: "[NEEDS: Acceptance criteria for...]"

**Example:**

```markdown
# From spec.md:

As a user, I want to reset my password so I can recover my account.

Acceptance Criteria:

- User can request password reset via email
- Email contains secure token valid for 24 hours

# Task AC should quote exactly:

**Acceptance Criteria** (from spec.md:45-48):

- [ ] User can request password reset via email
- [ ] Email contains secure token valid for 24 hours
```

### 5. Verify dependencies between tasks

- Before marking T002 depends on T001, confirm T001 creates what T002 needs
- Don't create circular dependencies
- Check plan.md for intended sequence

**Dependency verification:**

```markdown
# T001 creates User model

### T001: Create User Entity Schema

Creates: api/app/models/user.py

# T002 depends on User model - VALID

### T002: Create UserService

**Depends On**: T001
Uses: api/app/models/user.py (created by T001)

# T003 depends on T002 - VALID

### T003: Create UserController

**Depends On**: T002
Uses: api/app/services/user_service.py (created by T002)
```

**Why this matters**: Hallucinated tasks create impossible work. Tasks referencing non-existent code waste implementation time. Clear, verified tasks reduce implementation errors by 50-60%.

---

## Epic Sprint Breakdown Workflow

**For epic workflows**, break down the implementation plan into parallel sprints with dependency management.

### Step 1: Detect Epic vs Feature

**Check workspace type:**

```bash
if [ -f "epics/*/epic-spec.xml" ]; then
  WORKSPACE_TYPE="epic"
  EPIC_DIR=$(dirname "epics/*/epic-spec.xml")
else
  WORKSPACE_TYPE="feature"
  FEATURE_DIR=$(python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only | jq -r '.FEATURE_DIR')
fi
```

**If feature workflow detected:**
→ Skip sprint breakdown, use traditional task generation

**If epic workflow detected:**
→ Proceed with sprint breakdown pipeline

### Step 2: Analyze Plan Complexity

**Load epic artifacts:**

```bash
EPIC_SPEC="$EPIC_DIR/epic-spec.xml"
PLAN_XML="$EPIC_DIR/plan.xml"
RESEARCH_XML="$EPIC_DIR/research.xml"
```

**Extract complexity indicators:**

```javascript
const epicSpec = readXML(EPIC_SPEC);
const planXml = readXML(PLAN_XML);

const complexity = {
  subsystems: epicSpec.subsystems.subsystem.filter((s) => s.involved === "yes")
    .length,
  estimated_hours: planXml.phases.reduce(
    (sum, p) => sum + p.estimated_hours,
    0
  ),
  dependencies: epicSpec.dependencies.external_dependency?.length || 0,
  api_endpoints: planXml.api_design?.endpoints?.endpoint?.length || 0,
  database_tables: planXml.data_model?.entities?.entity?.length || 0,
};

// Decision: Single sprint vs multiple sprints
const needsMultipleSprints =
  complexity.subsystems >= 2 ||
  complexity.estimated_hours > 16 ||
  complexity.api_endpoints > 5 ||
  complexity.database_tables > 3;
```

**Why multiple sprints:**

- More than 1 subsystem involved (frontend + backend)
- Estimated work > 16 hours (2 work days)
- Large API surface area (>5 endpoints)
- Complex data model (>3 tables)

### Step 3: Create Sprint Boundaries

**Group work by subsystem and dependencies:**

```javascript
if (needsMultipleSprints) {
  // Identify natural boundaries
  const sprints = [];

  // Sprint 1: Backend foundation (if backend involved)
  if (epicSpec.subsystems.backend.involved === "yes") {
    sprints.push({
      id: "S01",
      name: "Backend API & Data Layer",
      subsystems: ["backend", "database"],
      dependencies: [],
      description: "Database schema, API contracts, business logic",
      estimated_hours: estimateHours(planXml, ["backend", "database"]),
      contracts_to_lock: identifyAPIContracts(planXml),
    });
  }

  // Sprint 2: Frontend UI (if frontend involved, depends on backend)
  if (epicSpec.subsystems.frontend.involved === "yes") {
    sprints.push({
      id: "S02",
      name: "Frontend UI Components",
      subsystems: ["frontend"],
      dependencies: hasSprint("S01") ? ["S01"] : [],
      description: "UI components, state management, API integration",
      estimated_hours: estimateHours(planXml, ["frontend"]),
      contracts_consumed: identifyConsumedContracts(planXml, "frontend"),
    });
  }

  // Sprint 3: Integration & Testing (depends on both)
  sprints.push({
    id: `S${sprints.length + 1}`,
    name: "Integration & E2E Testing",
    subsystems: ["testing", "integration"],
    dependencies: sprints.map((s) => s.id),
    description: "E2E tests, integration tests, performance tests",
    estimated_hours: estimateHours(planXml, ["testing"]),
    tests_type: "integration",
  });
}
```

**Sprint boundary heuristics:**

- Backend + Database = Sprint 1 (foundation layer)
- Frontend = Sprint 2 (depends on API contracts from Sprint 1)
- Integration/Testing = Final sprint (depends on all previous)
- Infrastructure/DevOps = Parallel to Sprint 1 (if independent)

### Step 4: Build Dependency Graph

**Analyze dependencies between sprints:**

```javascript
const dependencyGraph = {
  layers: [],
};

// Layer 1: No dependencies (can start immediately)
const layer1 = sprints.filter((s) => s.dependencies.length === 0);
dependencyGraph.layers.push({
  num: 1,
  sprint_ids: layer1.map((s) => s.id),
  parallelizable: layer1.length > 1,
  dependencies: [],
  rationale: "Foundation layer - no external dependencies",
});

// Layer 2: Depends only on Layer 1
const layer1Ids = layer1.map((s) => s.id);
const layer2 = sprints.filter(
  (s) =>
    s.dependencies.length > 0 &&
    s.dependencies.every((dep) => layer1Ids.includes(dep))
);
if (layer2.length > 0) {
  dependencyGraph.layers.push({
    num: 2,
    sprint_ids: layer2.map((s) => s.id),
    parallelizable: layer2.length > 1,
    dependencies: layer1Ids,
    rationale: "Depends on foundation layer completion",
  });
}

// Layer 3+: Depends on Layer 2 or multiple layers
const processedIds = [...layer1Ids, ...layer2.map((s) => s.id)];
const remaining = sprints.filter((s) => !processedIds.includes(s.id));
if (remaining.length > 0) {
  dependencyGraph.layers.push({
    num: 3,
    sprint_ids: remaining.map((s) => s.id),
    parallelizable: false, // Integration typically sequential
    dependencies: processedIds,
    rationale: "Integration layer - requires all previous work",
  });
}
```

**Critical path analysis:**

```javascript
const criticalPath = calculateCriticalPath(sprints, dependencyGraph);
// Critical path = longest dependency chain
// Example: S01 → S02 → S03 (sequential) = 48 hours
// vs S01 + S04 (parallel) = max(24h, 16h) = 24 hours
```

### Step 5: Lock API Contracts

**Identify contracts that must be locked before parallel work:**

```javascript
const contracts = [];

for (const sprint of sprints) {
  if (sprint.contracts_to_lock) {
    for (const contract of sprint.contracts_to_lock) {
      contracts.push({
        name: contract.name,
        path: `contracts/api/${contract.name}.yaml`,
        producer_sprint: sprint.id,
        consumer_sprints: findConsumers(sprints, contract.name),
        endpoints: contract.endpoints,
        schemas: contract.schemas,
      });
    }
  }
}

// Lock contracts in epic workspace
for (const contract of contracts) {
  // Create OpenAPI 3.0 specification
  const openapi = generateOpenAPISpec(contract, planXml);

  // Write to contracts directory
  writeFile(`$EPIC_DIR/contracts/${contract.name}.yaml`, openapi);

  // Add to sprint plan for reference
  log(
    `✅ Contract locked: ${contract.name} (producer: ${contract.producer_sprint})`
  );
}
```

**Contract locking benefits:**

- Frontend sprint can start using typed API clients immediately
- Backend sprint knows exact contract to implement
- No integration surprises (contract violations caught early)
- Parallel work proceeds safely

### Step 6: Generate sprint-plan.xml

**Generated XML structure:**

```xml
<sprint_plan>
  <metadata>
    <epic_number>001</epic_number>
    <epic_slug>auth-system</epic_slug>
    <total_sprints>3</total_sprints>
    <total_estimated_hours>48</total_estimated_hours>
    <execution_strategy>parallel</execution_strategy>
  </metadata>

  <sprints>
    <sprint id="S01" name="Backend API">
      <subsystems>backend,database</subsystems>
      <dependencies></dependencies>
      <estimated_hours>18</estimated_hours>
      <contracts_locked>
        <api_contract>contracts/api/auth-v1.yaml</api_contract>
      </contracts_locked>
    </sprint>
    <sprint id="S02" name="Frontend UI">
      <subsystems>frontend</subsystems>
      <dependencies>S01</dependencies>
      <estimated_hours>16</estimated_hours>
      <contracts_consumed>
        <api_contract>contracts/api/auth-v1.yaml</api_contract>
      </contracts_consumed>
    </sprint>
    <sprint id="S03" name="Integration">
      <subsystems>testing,integration</subsystems>
      <dependencies>S01,S02</dependencies>
      <estimated_hours>14</estimated_hours>
    </sprint>
  </sprints>

  <execution_layers>
    <layer num="1">
      <sprint_ids>S01</sprint_ids>
      <parallelizable>false</parallelizable>
      <dependencies></dependencies>
      <rationale>Foundation layer - API contracts must be locked first</rationale>
    </layer>
    <layer num="2">
      <sprint_ids>S02</sprint_ids>
      <parallelizable>false</parallelizable>
      <dependencies>S01</dependencies>
      <rationale>Depends on API contracts from S01</rationale>
    </layer>
    <layer num="3">
      <sprint_ids>S03</sprint_ids>
      <parallelizable>false</parallelizable>
      <dependencies>S01,S02</dependencies>
      <rationale>Integration requires all subsystems complete</rationale>
    </layer>
  </execution_layers>

  <critical_path>
    <total_duration_hours>48</total_duration_hours>
    <path>S01 → S02 → S03</path>
    <bottleneck_sprint>S01</bottleneck_sprint>
    <parallelization_opportunity>None (sequential dependencies)</parallelization_opportunity>
  </critical_path>
</sprint_plan>
```

---

## Multi-Screen Mockup Workflow

**When to use multi-screen mockups** (auto-detected by script):

- Feature has ≥3 distinct screens/pages
- Screens have navigation relationships (flow between screens)
- User journey involves multiple steps (onboarding, checkout, settings)

**Script auto-detection logic:**

1. Counts screen mentions in spec.md user stories (e.g., "login screen", "dashboard page")
2. Detects navigation keywords ("navigate to", "redirects to", "shows modal")
3. Identifies multi-step flows ("wizard", "onboarding", "checkout process")
4. If ≥3 screens detected → Enable multi-screen mode

### Generated Mockup Structure

**For features with ≥3 screens:**

```
specs/NNN-slug/mockups/
├── index.html                   # Navigation hub (entry point)
├── screen-01-[name].html        # Individual screen with state switching
├── screen-02-[name].html
├── screen-03-[name].html
├── _shared/
│   ├── navigation.js            # Keyboard shortcuts (H=hub, 1-9=screens)
│   └── state-switcher.js        # State cycling (S key)
└── mockup-approval-checklist.md # Review criteria
```

**For features with 1-2 screens:**

```
specs/NNN-slug/mockups/
├── [screen-name].html           # Single screen with state switching
└── mockup-approval-checklist.md # Review criteria
```

### Keyboard Shortcuts (Automatic)

**Provided by navigation.js:**

- `H` key → Return to hub (index.html)
- `1`-`9` keys → Jump to screen by number
- `Esc` → Close modals/dialogs

**Provided by state-switcher.js:**

- `S` key → Cycle state (Success → Loading → Error → Empty → Success)
- State persists in sessionStorage during review

### Mockup Approval Process

**After mockup generation:**

1. **Open navigation hub** in browser:

   ```bash
   open specs/NNN-slug/mockups/index.html
   ```

2. **Review each screen** (manual validation):

   - Press number keys 1-9 to navigate
   - Press S to cycle through all states
   - Verify design token usage
   - Check component reuse (matches ui-inventory.md)
   - Validate accessibility (contrast, touch targets, keyboard nav)

3. **Complete approval checklist:**

   - Fill out `mockup-approval-checklist.md`
   - Mark each screen as approved
   - Note any changes needed

4. **Update workflow state:**

   ```yaml
   # In specs/NNN-slug/state.yaml
   manual_gates:
     mockup_approval:
       status: approved # or needs_changes
       approved_at: "2025-11-17T14:30:00Z"
       approved_by: "user@example.com"
   ```

5. **Continue implementation:**
   ```bash
   /feature continue
   # or
   /implement
   ```

### Quality Gates for Mockups

**Before mockup approval, verify:**

✅ **Multi-screen flow** (manual review):

- All screens accessible via keyboard shortcuts (1-9)
- Navigation wiring matches user flow diagram
- Breadcrumbs link back to hub

✅ **State completeness** (manual review):

- All 4 states implemented (Success, Loading, Error, Empty)
- S key cycles through states correctly
- Loading spinners use CSS animations (no GIFs)

✅ **Design system compliance**:

- All colors from tokens.css (no hardcoded hex codes)
- All spacing from 8pt grid (multiples of 4px or 8px)
- Typography uses scale (text-sm, text-base, text-lg)
- Shadows use scale (shadow-sm, shadow-md, shadow-lg)

✅ **Component reuse**:

- Suggested components from plan.md used where applicable
- New components justified in Design System Constraints section
- Components match ui-inventory.md patterns
- No duplicate implementations detected

✅ **Accessibility baseline**:

- Touch targets ≥24x24px (44x44px preferred)
- Color contrast ≥4.5:1 for text
- Focus indicators visible (2px outline, 4.5:1 contrast)
- Semantic HTML (<button> not <div onclick>)
- ARIA labels on icon-only buttons
- Form labels associated with inputs (for/id)
- Keyboard navigation works (Tab, Enter, Esc)

---

## MAKER-Style Task Complexity Scoring

**Based on**: "Solving a Million-Step LLM Task with Zero Errors" (arXiv:2511.09030)

**Core insight**: Smaller tasks = more reliable execution. Tasks scoring >5 should be decomposed further.

### Complexity Score (1-10)

Rate each task on these dimensions:

| Score | Level | Description | Agent Reliability |
|-------|-------|-------------|-------------------|
| 1-3 | Atomic | Single operation, clear input/output | ~95% success rate |
| 4-6 | Compound | 2-4 dependent operations | ~85% success rate |
| 7-10 | Complex | Multiple dependencies, unclear scope | ~70% success rate |

### Scoring Criteria

**Add 1 point for each:**

1. **Multiple files modified** (+1 per file after first)
2. **Cross-subsystem work** (backend + frontend in same task)
3. **External dependency** (API call, database, third-party service)
4. **Conditional logic** (if/else branches in implementation)
5. **State management** (context, session, cache updates)
6. **Error handling** (multiple error paths)
7. **Integration point** (connecting components)
8. **Unclear acceptance criteria** (vague requirements)
9. **No existing pattern** (novel implementation)
10. **High-stakes operation** (data migration, security, payments)

### Example Scoring

```markdown
### T008: Write unit tests for StudentProgressService

Complexity Score: 3/10 (Atomic)
- Single file modification: tests/test_student_progress.py
- Clear input/output: mock data → test assertions
- Existing pattern: follows test template
- No external dependencies: all mocked

Recommendation: ✅ Good size, proceed as-is

---

### T015: Implement authentication flow with OAuth2 + session management

Complexity Score: 8/10 (Complex - DECOMPOSE)
- Multiple files: +3 (auth controller, service, middleware)
- External dependency: +1 (OAuth2 provider)
- State management: +2 (session + token refresh)
- Error handling: +1 (multiple OAuth error codes)
- High-stakes: +1 (security-critical)

Recommendation: ⚠️ Split into 4-5 atomic tasks

Decomposition:
→ T015a: Create OAuth2 callback endpoint (score: 3)
→ T015b: Implement token validation service (score: 2)
→ T015c: Create session management middleware (score: 3)
→ T015d: Add token refresh logic (score: 2)
→ T015e: Write integration tests for auth flow (score: 3)
```

### Automatic Complexity Warnings

**In tasks.md header, include complexity summary:**

```markdown
## Complexity Analysis

| Score Range | Count | Recommendation |
|-------------|-------|----------------|
| 1-3 (Atomic) | 18 | ✅ Proceed |
| 4-6 (Compound) | 8 | ⚠️ Monitor closely |
| 7-10 (Complex) | 2 | ❌ DECOMPOSE BEFORE /implement |

**High Complexity Tasks Requiring Decomposition:**
- T015: Implement authentication flow (score: 8) → Split into T015a-T015e
- T022: Database migration with data transformation (score: 7) → Split into T022a-T022c

**Total after decomposition:** 28 tasks → 35 tasks (7 new atomic tasks)
```

### Integration with Red-Flagging

**During /implement phase:**

1. Before executing task, check complexity score
2. If score > 5, warn agent about potential difficulties
3. Track success rate vs complexity (learning system)
4. If task fails 2x, suggest further decomposition

**Configuration** (`.spec-flow/config/red-flags.yaml`):

```yaml
task_complexity:
  warn_threshold: 5
  block_threshold: 7  # Require manual approval for score >7
  auto_decompose: false  # Set true to auto-split high-complexity tasks
```

### Benefits of MAKER-Style Decomposition

1. **Higher success rate**: Atomic tasks have ~95% vs ~70% for complex
2. **Better error localization**: When task fails, know exactly what broke
3. **Parallel execution**: More atomic tasks = more parallelization opportunities
4. **Cost efficiency**: Can use smaller/cheaper models (haiku) for atomic tasks
5. **Progress visibility**: More tasks completed = clearer progress tracking

### Learning Integration

**Track complexity vs outcome:**

```yaml
# .spec-flow/learnings/observations/task-complexity-observations.yaml
observations:
  - task_id: T015
    complexity_score: 8
    outcome: failed
    retries: 3
    decomposed_into: [T015a, T015b, T015c, T015d, T015e]
    post_decomposition_success: true

  - task_id: T008
    complexity_score: 3
    outcome: success
    retries: 0
```

**Adaptive thresholds**: If tasks scoring 5-6 fail frequently, lower warn_threshold to 4.

---

## Task Structure

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

---

## Parallel Batching

**Independent tasks grouped for parallel execution:**

- Batch 1: Frontend tasks (no backend dependencies)
- Batch 2: Backend tasks (no frontend dependencies)
- Batch 3: Integration tasks (requires both frontend + backend)

**Dependencies respected:**

- Test tasks depend on implementation tasks
- Integration tasks depend on both frontend and backend
- Refactoring tasks depend on working implementation

**Example parallel batching:**

```markdown
## Batch 1: Backend API (can run in parallel with Batch 2)

- T001: Create User model
- T002: Create UserService
- T003: Create UserController

## Batch 2: Frontend Components (can run in parallel with Batch 1)

- T004: Create LoginForm component
- T005: Create Dashboard component
- T006: Create UserProfile component

## Batch 3: Integration (depends on Batch 1 + Batch 2)

- T007: Create E2E test for login flow
- T008: Create E2E test for dashboard
```

---

## TDD Task Sequencing

**For each feature component, follow TDD triplet pattern:**

1. **Spec task**: Define component API/interface (optional)
2. **Test task**: Write failing tests
3. **Implementation task**: Make tests pass
4. **Refactor task**: Improve code quality (optional)

**Example TDD sequence:**

```markdown
### T010: Write tests for UserService.create_user

**Depends On**: T001 (User model must exist)
**Source**: plan.md:165-175

**Acceptance Criteria**:

- [ ] Test: creates user with valid data
- [ ] Test: rejects duplicate email
- [ ] Test: validates email format
- [ ] Test: hashes password before saving
- [ ] All tests failing (red state)

---

### T011: Implement UserService.create_user

**Depends On**: T010 (tests must exist)
**Source**: plan.md:165-175

**Acceptance Criteria**:

- [ ] All tests from T010 passing (green state)
- [ ] User created in database
- [ ] Password hashed with bcrypt
- [ ] Email uniqueness enforced

---

### T012: Refactor UserService validation logic (optional)

**Depends On**: T011 (implementation must work)
**Source**: plan.md:165-175

**Acceptance Criteria**:

- [ ] Extract validation to separate validator class
- [ ] All tests still passing
- [ ] Code coverage maintained
```

---

## UI-First Mode

**Trigger**: `--ui-first` flag passed to /tasks

**Behavior:**

- Generates HTML mockup tasks before implementation
- Creates multi-screen navigation hub (index.html) if ≥3 screens
- Creates individual screen mockups with state switching (S key)
- Creates mockup-approval-checklist.md with multi-screen flow criteria
- Sets manual gate in state.yaml
- Blocks /implement until mockups approved

**Example task breakdown (UI-first):**

```markdown
## Phase 1: Mockup Generation

### T001: Create mockup navigation hub

**Depends On**: T000
**Source**: plan.md:120-135

**Acceptance Criteria**:

- [ ] index.html created from template
- [ ] 4 screen cards with descriptions
- [ ] User flow diagram includes: Welcome → Sign Up → Profile Setup → Dashboard
- [ ] Keyboard shortcuts documented (1-4 navigate, H returns to hub)

### T002: Create welcome screen mockup

**Depends On**: T001
**Source**: spec.md:45-52 (User Story 1)

**Acceptance Criteria**:

- [ ] screen-01-welcome.html created from template
- [ ] Success state: Hero section + CTA button
- [ ] Loading state: Skeleton loader for hero
- [ ] Breadcrumb links to hub
- [ ] CTA button navigates to screen-02-signup.html

## Phase 2: Implementation (Blocked until mockup approval)

### T008: Convert welcome screen to Next.js component

**Depends On**: T007 (mockup approval)
**Source**: mockups/screen-01-welcome.html

[Implementation tasks follow after mockup approval...]
```

---

## Prerequisites

### Required Tools

- `git` — Version control
- `jq` — JSON parsing
- Feature spec and plan completed (spec.md, plan.md exist)

**Check command**:

```bash
for tool in git jq; do
  command -v "$tool" >/dev/null || error "Missing required tool: $tool"
done
```

### Required Files

- `spec.md` — Feature specification (must exist)
- `plan.md` — Implementation plan (must exist)
- `.git/` — Git repository (must be initialized)

**Check command**:

```bash
test -f "specs/*/spec.md" || error "Missing spec.md"
test -f "specs/*/plan.md" || error "Missing plan.md"
test -d ".git" || error "Not a git repository"
```

---

## Version History

**v2.0** (2025-11-17):

- Added epic sprint breakdown workflow
- Added multi-screen mockup workflow
- Added UI-first mode with mockup approval gate
- Enhanced anti-hallucination rules

**v1.0** (2025-09-15):

- Initial task generation from plan.md
- TDD task sequencing
- Parallel batching support

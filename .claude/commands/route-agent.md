---
description: Internal helper to route tasks to specialist agents (context-aware delegation)
---

## PARSE ARGUMENTS

**Extract task description:**

If $ARGUMENTS is empty:
```
Usage: /route-agent [task description]

Examples:
  /route-agent "Implement POST /api/users endpoint"
  /route-agent "Fix failing test_user_creation"
  /route-agent "Create UserProfile component"
```

Else: Set TASK_DESCRIPTION = $ARGUMENTS

## MENTAL MODEL

**Purpose**: Intelligent agent delegation based on task domain, file paths, and keywords.

**Pattern**: Routing (from Anthropic best practices)
- Classify input by domain → Route to specialized sub-agent → Return structured result

**Context efficiency**:
- Agent receives minimal, focused context
- No token waste on irrelevant codebase scanning

**Tool used**: Claude Code's Task tool (available in this environment)

## ANALYZE TASK

**Extract classification signals from task description:**

1. **File paths** mentioned:
   - Look for patterns like `api/app/*.py`, `apps/**/*.tsx`, `api/alembic/**`
   - Extract explicit file paths from task text

2. **Keywords** present:
   - Backend: "endpoint", "route", "service", "FastAPI", "Pydantic", "middleware", "API"
   - Frontend: "component", "UI", "React", "Next.js", "page", "form", "button", "tsx"
   - Database: "migration", "schema", "database", "SQL", "Alembic", "table", "RLS", "model"
   - Tests: "test", "coverage", "E2E", "Playwright", "Jest", "integration", "unit"
   - Debug: "bug", "error", "failing", "broken", "fix", "debug", "crash"
   - Review: "review", "quality", "contract", "KISS", "DRY", "security", "compliance"

3. **Task type**:
   - Implement: "create", "add", "implement", "build"
   - Fix: "fix", "resolve", "debug", "repair"
   - Test: "test", "coverage", "verify"
   - Review: "review", "check", "validate"

## ROUTING DECISION TREE

**Score each agent based on triggers, then select highest score:**

### Backend API/Services → `cfipros-backend-dev`

**Triggers (+10 points each)**:
- File paths: `api/**/*.py`, `app/**/*.py`
- Keywords: "endpoint", "route", "service", "FastAPI", "Pydantic", "middleware", "API"
- Task types: Implement API, create service, add endpoint

**Context to gather**:
- spec.md (requirements section)
- tasks.md (REUSE markers if T0NN task)
- error-log.md (recent entries for debugging context)

---

### Frontend UI/Components → `cfipros-frontend-shipper`

**Triggers (+10 points each)**:
- File paths: `apps/**/*.tsx`, `apps/**/*.ts`, `components/**`
- Keywords: "component", "UI", "React", "Next.js", "page", "form", "button", "tsx"
- Task types: Implement UI, create component, add page

**Context to gather**:
- visuals/README.md (UX patterns)
- design/systems/ui-inventory.md (component catalog)
- tasks.md (REUSE markers)

---

### Database Schema/Queries → `cfipros-database-architect`

**Triggers (+10 points each)**:
- File paths: `api/alembic/**`, `api/app/models/**`
- Keywords: "migration", "schema", "database", "SQL", "Alembic", "table", "RLS", "model"
- Task types: Create migration, update schema, optimize query

**Specificity bonus**: +5 points (most specific domain)

**Context to gather**:
- data-model.md (ERD and schema)
- api/alembic/versions/ (existing migrations)
- plan.md (performance targets)

---

### Tests/QA → `cfipros-qa-test`

**Triggers (+10 points each)**:
- File paths: `**/tests/**`, `**/test_*.py`, `**/*.test.ts`
- Keywords: "test", "coverage", "E2E", "Playwright", "Jest", "integration", "unit"
- Task types: Write tests, increase coverage, fix failing tests

**Context to gather**:
- \spec-flow/templates/test-patterns.md
- plan.md (coverage targets: 80%+ line/branch)
- TDD workflow reminder

---

### Debugging/Error Fixing → `cfipros-debugger`

**Triggers (+10 points each)**:
- Keywords: "bug", "error", "failing", "broken", "fix", "debug", "crash"
- Task types: Debug issue, fix error, resolve failure

**Default agent**: If no other agent scores >0, route to debugger

**Context to gather**:
- error-log.md (recent entries)
- Stack trace or error message
- Files involved in error

---

### Code Review/Quality → `senior-code-reviewer`

**Triggers (+10 points each)**:
- Keywords: "review", "quality", "contract", "KISS", "DRY", "security", "compliance"
- Task types: Review code, validate contracts, check quality gates

**Context to gather**:
- git diff (files changed)
- OpenAPI contracts (if in specs/NNN/contracts/)
- plan.md (quality gate requirements)
- \spec-flow/memory/constitution.md

---

## SELECT AGENT

**Scoring algorithm**:

1. Count keyword matches for each agent (each match = +10 points)
2. Check file path patterns (match = +10 points)
3. Apply specificity bonuses:
   - Database: +5 (most specific)
   - If database AND backend both match: database wins
   - If debugger AND qa both match on "test": qa wins
4. Select agent with highest score
5. If all scores = 0: Default to `cfipros-debugger`

**Display routing decision**:
```
Routing analysis:
  Backend: 20 points
  Frontend: 0 points
  Database: 15 points
  Tests: 0 points
  Debug: 10 points
  Review: 0 points

Selected: cfipros-backend-dev (20 points)
```

## GATHER CONTEXT

**Collect minimal, focused context for agent:**

1. **Identify feature directory**:
   - Current working directory may be `specs/NNN-feature-name/`
   - Or check for most recent feature: `specs/` directories sorted by date

2. **Read context files based on agent type**:
   - Backend: spec.md, tasks.md, error-log.md
   - Frontend: visuals/README.md, design/systems/ui-inventory.md, tasks.md
   - Database: data-model.md, api/alembic/versions/*, plan.md
   - Tests: \spec-flow/templates/test-patterns.md, plan.md
   - Debug: error-log.md, stack trace
   - Review: git diff output, OpenAPI contracts, constitution.md

3. **Extract relevant sections**:
   - Don't send entire files - extract relevant sections only
   - For spec.md: Get requirement related to task
   - For tasks.md: Get REUSE markers if T0NN task mentioned
   - For error-log.md: Get last 20 entries only

4. **Prepare context summary** (keep under 2000 tokens):
   ```
   **Feature**: [feature-name] (specs/NNN-feature-name)
   **Task ID**: T0NN (if applicable)
   **Files involved**: [list]

   **Requirements** (from spec.md):
   [extracted section]

   **REUSE patterns** (from tasks.md):
   [REUSE markers if applicable]

   **Recent context** (from error-log.md):
   [last 3-5 entries if debugging]
   ```

## INVOKE AGENT

**Use Task tool (available in Claude Code environment):**

```python
Task(
  subagent_type="[agent-name]",  # e.g., "cfipros-backend-dev"
  description="[5-10 word summary]",  # e.g., "Implement user endpoint with validation"
  prompt=f"""[Domain] task: {TASK_DESCRIPTION}

**Context**:
{CONTEXT_SUMMARY}

**Expected deliverables**:
1. Implementation complete with proper error handling
2. Tests written/updated (with evidence of pass/fail)
3. Verification status (lint, types, tests, coverage)
4. Files changed (list with paths)

**Quality requirements**:
- KISS/DRY principles
- Type safety (TypeScript/MyPy)
- Test coverage ≥80%
- No security vulnerabilities

**Return when complete**:
Summary of changes, test evidence, verification status, next steps."""
)
```

**Task tool parameters**:
- `subagent_type`: One of the 6 specialist agents (cfipros-backend-dev, cfipros-frontend-shipper, etc.)
- `description`: Short task summary (5-10 words) for progress tracking
- `prompt`: Detailed task description with context, requirements, and expected outputs

## VALIDATE AGENT RESULT

**After agent completes, validate structured output:**

1. **Check agent returned summary**:
   - Files changed (list with paths)
   - Tests added/modified
   - Verification status (lint, types, tests, coverage)
   - Notes or side effects

2. **Verify deliverables**:
   - If agent says "tests pass", check for actual test output
   - If agent says "lint clean", verify with linter command
   - If agent says "coverage 85%", check coverage report

3. **Validate quality gates**:
   - Lint: No errors, warnings acceptable
   - Types: No type errors
   - Tests: All pass, coverage ≥80%
   - Security: No new vulnerabilities (if debugger ran)

**If validation fails**:
- Report missing deliverables to user
- Suggest re-running agent with stricter requirements
- Or manual completion

**Expected agent return format**:
```
Task complete: [brief summary]

Files changed:
  - [file path 1]
  - [file path 2]

Tests:
  - Added: [test file paths]
  - Results: [pass/fail counts]
  - Coverage: [percentage]

Verification:
  ✅ Lint: Clean
  ✅ Types: No errors
  ✅ Tests: 12/12 passing
  ✅ Coverage: 85% line, 82% branch

Notes: [any side effects, warnings, or next steps]
```

## ROUTING EXAMPLES

### Example 1: Backend Task
```
Input: "Implement POST /api/users endpoint with validation"
Analysis:
  - Domain: Backend API
  - Keywords: "endpoint", "POST", "api"
  - File paths: None explicit (will be api/app/routes/)
Route: cfipros-backend-dev
Context: spec.md requirements, data-model.md User schema, REUSE: validation_service
```

### Example 2: Frontend Task
```
Input: "Create UserProfile component with avatar upload"
Analysis:
  - Domain: Frontend UI
  - Keywords: "component", "avatar", "upload"
  - File paths: None explicit (will be apps/app/components/)
Route: cfipros-frontend-shipper
Context: visuals/README.md patterns, design system colors, REUSE: ImageUpload component
```

### Example 3: Database Task
```
Input: "Add migration for user_preferences table"
Analysis:
  - Domain: Database
  - Keywords: "migration", "table"
  - File paths: None explicit (will be api/alembic/versions/)
Route: cfipros-database-architect
Context: data-model.md ERD, existing migrations, RLS requirements from plan.md
```

### Example 4: Debugging Task
```
Input: "Fix failing test_user_creation - IntegrityError on email field"
Analysis:
  - Domain: Debugging
  - Keywords: "fix", "failing", "error"
  - File paths: test_user_creation (implies api/tests/)
Route: cfipros-debugger
Context: error-log.md recent entries, test file, User model definition
```

## ERROR HANDLING

**Handle routing and agent failures:**

### No Clear Match (all scores = 0)
```
⚠️  No clear agent match

Task: [task description]

Defaulting to: cfipros-debugger (general-purpose)

Reason: No domain-specific keywords detected
```

### Multiple High Scores (tie)
```
⚠️  Multiple agents matched

Scores:
  Backend: 20 points
  Database: 20 points

Applying specificity rules:
  → Database is more specific than Backend
  → Routing to: cfipros-database-architect
```

### Agent Timeout (if Task tool supports)
```
⏱️  Agent timeout after 5 minutes

Options:
  A) Retry with extended timeout
  B) Try different agent
  C) Manual implementation

Choose:
```

### Invalid Agent Result
```
❌ Agent returned incomplete result

Missing:
  - Verification status
  - Test evidence

Action: Request agent re-run with stricter requirements
```

## CONSTRAINTS

**When routing tasks, always:**
- ✅ Provide minimal, focused context (keep under 2000 tokens)
- ✅ Include REUSE markers when available (prevent duplication)
- ✅\spec-flow expected deliverables clearly
- ✅ Require evidence for test execution ("tests pass" needs proof)
- ✅ Validate agent output before returning to user

**Never:**
- ❌ Send full codebase dumps to agents
- ❌ Route without analyzing task first
- ❌ Accept agent output without validation
- ❌ Skip quality gate checks

## RETURN

**Display routing decision and agent status:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Routing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: [task description]

Routing analysis:
  Backend: [N] points
  Frontend: [N] points
  Database: [N] points
  Tests: [N] points
  Debug: [N] points
  Review: [N] points

Selected: [agent-name] ([N] points)

Context provided:
  ✅ [context file 1]
  ✅ [context file 2]
  ✅ [context file 3]

Agent working...
```

**When agent completes:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent: [agent-name]
Task: [brief summary]

Files changed:
  - [file paths]

Tests:
  - Results: [counts]
  - Coverage: [percentage]

Verification:
  [lint/types/tests status]

Next steps: [if any]
```


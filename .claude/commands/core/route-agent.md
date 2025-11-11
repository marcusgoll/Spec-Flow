---
description: Internal helper to route tasks to specialist agents (context-aware delegation)
internal: true
---

> **⚠️  INTERNAL COMMAND**: This command is called automatically by `/implement`.
> Most users should not need to call this directly. Use `/implement` instead.

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

**Parallel execution**:
- Multiple Task() calls in single message = parallel execution
- Used by /implement for batched task processing

**Tool used**: Claude Code's Task tool (available in this environment)

**Shared configuration**: This command uses `.claude/agents/agent-routing-rules.json` and `.claude/hooks/routingEngine.ts` for consistent routing logic with the auto-routing hook.

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

**All routing logic is defined in `.claude/agents/agent-routing-rules.json`**

This shared configuration contains:
- **26 specialist agents** (backend-dev, frontend-shipper, database-architect, qa-test, debugger, senior-code-reviewer, 10 phase agents, and others)
- **Trigger patterns** for each agent:
  - File path globs (`api/**/*.py`, `apps/**/*.tsx`, `**/tests/**`, etc.)
  - Keywords (endpoint, component, migration, test, bug, etc.)
  - Intent patterns (regex matching task descriptions)
- **Context files** each agent should receive
- **Chain rules** for sequential agent delegation
- **Tie-breaking rules** for conflict resolution
- **Anti-loop protection** (max chain depth: 3, cooldown: 5s)

**To view full routing rules**:
```bash
cat .claude/agents/agent-routing-rules.json
```

**Key specialists** (excerpt):
- `backend-dev` — Backend APIs, services, business logic
- `frontend-shipper` — UI components, pages, client-side logic
- `database-architect` — Schema design, migrations, query optimization
- `qa-test` — Test creation, QA planning, automated suites
- `debugger` — Error triage, bug investigation, root cause analysis
- `senior-code-reviewer` — Code quality, DRY/KISS, contract compliance

---

## SELECT AGENT

**Use shared routing engine** (`.claude/hooks/routingEngine.ts`):

The routing engine implements this scoring algorithm:
1. **File path matching**: +20 points per matched glob pattern
2. **Keyword matching**: +10 points per matched keyword
3. **Intent pattern matching**: +15 points for regex match on task description
4. **Specificity bonus**: Additional points from config (database-architect: +5, phase agents: +10)
5. **Tie-breaking**: Apply conflict resolution rules (database wins over backend, qa wins over debugger, etc.)
6. **Confidence threshold**: Only route if score ≥ 10 (minScore from config)

**Example TypeScript usage** (if calling programmatically):
```typescript
import { routeToSpecialist } from '.claude/hooks/routingEngine.js';

const result = routeToSpecialist({
  filePaths: ['api/app/main.py'],
  keywords: ['endpoint', 'fastapi'],
  intent: 'Implement POST /api/users endpoint'
});

// result = { specialist: "backend-dev", score: 30, reason: "file path match, keyword match", ... }
```

**Display routing decision**:
```
Routing analysis:
  backend-dev: 30 points
  frontend-shipper: 0 points
  database-architect: 5 points (specificity bonus only)
  qa-test: 0 points
  debugger: 0 points

Selected: backend-dev (30 points, high confidence)
Reason: file path match, keyword match
```

## GATHER CONTEXT

**Collect minimal, focused context for agent:**

1. **Identify feature directory**:
   - Current working directory may be `specs/NNN-feature-name/`
   - Or check for most recent feature: `specs/` directories sorted by date

2. **Read context files from routing config**:
   - The selected agent's `contextFiles` array in `.claude/agents/agent-routing-rules.json` specifies which files to load
   - Example for `backend-dev`: `["spec.md", "plan.md", "tasks.md"]`
   - Example for `database-architect`: `["spec.md", "plan.md", "tasks.md", "docs/project/data-architecture.md"]`
   - Example for `frontend-shipper`: `["spec.md", "plan.md", "tasks.md", "visuals/screens.yaml"]`

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
  subagent_type="[agent-name]",  # e.g., "backend-dev"
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
- `subagent_type`: One of the 6 specialist agents (backend-dev, frontend-shipper, etc.)
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
Route: backend-dev
Context: spec.md requirements, data-model.md User schema, REUSE: validation_service
```

### Example 2: Frontend Task
```
Input: "Create UserProfile component with avatar upload"
Analysis:
  - Domain: Frontend UI
  - Keywords: "component", "avatar", "upload"
  - File paths: None explicit (will be apps/app/components/)
Route: frontend-shipper
Context: visuals/README.md patterns, design system colors, REUSE: ImageUpload component
```

### Example 3: Database Task
```
Input: "Add migration for user_preferences table"
Analysis:
  - Domain: Database
  - Keywords: "migration", "table"
  - File paths: None explicit (will be api/alembic/versions/)
Route: database-architect
Context: data-model.md ERD, existing migrations, RLS requirements from plan.md
```

### Example 4: Debugging Task
```
Input: "Fix failing test_user_creation - IntegrityError on email field"
Analysis:
  - Domain: Debugging
  - Keywords: "fix", "failing", "error"
  - File paths: test_user_creation (implies api/tests/)
Route: debugger
Context: error-log.md recent entries, test file, User model definition
```

## ERROR HANDLING

**Handle routing and agent failures:**

### No Clear Match (all scores = 0)
```
⚠️  No clear agent match

Task: [task description]

Defaulting to: debugger (general-purpose)

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
  → Routing to: database-architect
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


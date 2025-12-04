---
description: Analyze task and route to specialist agent (backend, frontend, database, qa, debugger, or reviewer) using scoring algorithm and shared routing rules
argument-hint: [task description]
allowed-tools: [Read, Task, Grep, Bash(cat:*)]
internal: true
version: 2.0
updated: 2025-11-20
---

<objective>
Intelligent agent delegation based on task domain analysis, file path patterns, and keyword matching.

**Purpose**: Route tasks to the most appropriate specialist agent using a quantitative scoring algorithm.

**When called**: Automatically invoked by `/implement` for task processing. Users rarely call directly.

**Architecture**:

- **Routing Engine**: Shared scoring algorithm in `@.claude/agents/agent-routing-rules.json`
- **26 Specialist Agents**: backend-dev, frontend-dev, database-architect, qa-test, debugger, senior-code-reviewer, plus 10 phase agents
- **Context Efficiency**: Each agent receives minimal, focused context (< 2000 tokens)
  </objective>

<context>
**Task to route**:
```text
$ARGUMENTS
```

**Routing configuration**:
!`cat .claude/agents/agent-routing-rules.json 2>/dev/null || echo "{}"`

**Current feature directory**:
!`ls -td specs/*/ 2>/dev/null | head -1`

**Available context files** (feature directory):
!`ls specs/*/spec.md specs/*/plan.md specs/*/tasks.md 2>/dev/null | head -10`
</context>

<process>
## 1. Validate Arguments

If `$ARGUMENTS` is empty, display usage:

```
Usage: /route-agent [task description]

Examples:
  /route-agent "Implement POST /api/users endpoint"
  /route-agent "Fix failing test_user_creation"
  /route-agent "Create UserProfile component"
```

Set `TASK_DESCRIPTION = $ARGUMENTS`

## 2. Analyze Task Signals

Extract classification signals from task description:

**File paths mentioned**:

- Look for patterns: `api/app/*.py`, `apps/**/*.tsx`, `api/alembic/**`, `tests/**`
- Extract explicit file paths from task text

**Keywords present**:

- **Backend**: "endpoint", "route", "service", "FastAPI", "Pydantic", "middleware", "API"
- **Frontend**: "component", "UI", "React", "Next.js", "page", "form", "button", "tsx"
- **Database**: "migration", "schema", "database", "SQL", "Alembic", "table", "RLS", "model"
- **Tests**: "test", "coverage", "E2E", "Playwright", "Jest", "integration", "unit"
- **Debug**: "bug", "error", "failing", "broken", "fix", "debug", "crash"
- **Review**: "review", "quality", "contract", "KISS", "DRY", "security", "compliance"

**Task type**:

- **Implement**: "create", "add", "implement", "build"
- **Fix**: "fix", "resolve", "debug", "repair"
- **Test**: "test", "coverage", "verify"
- **Review**: "review", "check", "validate"

## 3. Apply Routing Decision Tree

Use shared routing engine from `@.claude/agents/agent-routing-rules.json`:

**Scoring algorithm**:

1. **File path matching**: +20 points per matched glob pattern
2. **Keyword matching**: +10 points per matched keyword
3. **Intent pattern matching**: +15 points for regex match on task description
4. **Specificity bonus**: Additional points from config (database-architect: +5, phase agents: +10)
5. **Tie-breaking**: Apply conflict resolution rules:
   - database-architect wins over backend-dev (schema/migration tasks)
   - qa-test wins over debugger (test creation tasks)
   - frontend-dev wins over backend-dev (UI tasks)
6. **Confidence threshold**: Only route if score ≥ 10 (minScore from config)

**Display routing decision**:

```
Routing analysis:
  backend-dev: [N] points
  frontend-dev: [N] points
  database-architect: [N] points
  qa-test: [N] points
  debugger: [N] points
  senior-code-reviewer: [N] points

Selected: [agent-name] ([N] points)
Reason: [file path match | keyword match | intent match]
```

**Fallback for no clear match** (all scores < 10):

- Default to `debugger` (general-purpose agent)
- Display warning: "⚠️ No clear agent match, defaulting to debugger"

## 4. Gather Minimal Context

Collect focused context for selected agent (keep under 2000 tokens):

**Identify feature directory**:

- Current working directory if in `specs/NNN-feature-name/`
- Or most recent feature: `ls -td specs/*/ | head -1`

**Read context files from routing config**:

- The selected agent's `contextFiles` array in routing rules specifies which files to load
- **backend-dev**: `["spec.md", "plan.md", "tasks.md"]`
- **database-architect**: `["spec.md", "plan.md", "tasks.md", "docs/project/data-architecture.md"]`
- **frontend-dev**: `["spec.md", "plan.md", "tasks.md", "visuals/screens.yaml"]`

**Extract relevant sections only** (don't send entire files):

- For `@spec.md`: Get requirement related to task
- For `@tasks.md`: Get REUSE markers if task ID mentioned
- For `@error-log.md`: Get last 20 entries only (if debugging)

**Prepare context summary**:

```
**Feature**: [feature-name] (specs/NNN-feature-name)
**Task ID**: T0NN (if applicable)
**Files involved**: [list]

**Requirements** (from @spec.md):
[extracted section]

**REUSE patterns** (from @tasks.md):
[REUSE markers if applicable]

**Recent context** (from @error-log.md):
[last 3-5 entries if debugging]
```

## 5. Invoke Specialist Agent

Use Task tool to delegate to selected agent:

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

Display progress:

```
Agent: [agent-name]
Context: [N] tokens (files: [list])
Working...
```

## 6. Validate Agent Result

After agent completes, validate structured output:

**Check agent returned**:

- Files changed (list with paths)
- Tests added/modified
- Verification status (lint, types, tests, coverage)
- Notes or side effects

**Verify deliverables**:

- If agent says "tests pass", check for actual test output
- If agent says "lint clean", verify with linter command
- If agent says "coverage 85%", check coverage report

**Validate quality gates**:

- ✅ Lint: No errors, warnings acceptable
- ✅ Types: No type errors
- ✅ Tests: All pass, coverage ≥80%
- ✅ Security: No new vulnerabilities

**If validation fails**:

- Report missing deliverables to user
- Suggest re-running agent with stricter requirements
  </process>

<success_criteria>
Routing is successful when:

- ✅ Task description analyzed for domain signals
- ✅ Agent selected with confidence score ≥ 10
- ✅ Context gathered and kept under 2000 tokens
- ✅ Agent invoked via Task tool with clear requirements
- ✅ Agent returns structured output with all deliverables
- ✅ Quality gates validated (lint, types, tests, coverage)
- ✅ Files changed listed with paths
- ✅ Test evidence provided
- ✅ Routing decision displayed with reasoning
  </success_criteria>

<constraints>
**When routing tasks, always**:
- ✅ Provide minimal, focused context (keep under 2000 tokens)
- ✅ Include REUSE markers when available (prevent code duplication)
- ✅ Specify expected deliverables clearly
- ✅ Require evidence for test execution ("tests pass" needs proof)
- ✅ Validate agent output before returning to user
- ✅ Use shared routing rules from `@.claude/agents/agent-routing-rules.json`

**Never**:

- ❌ Send full codebase dumps to agents
- ❌ Route without analyzing task first
- ❌ Accept agent output without validation
- ❌ Skip quality gate checks
- ❌ Invoke agents without focused context
  </constraints>

<output>
Display routing decision and agent status:

**Routing Phase**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Routing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: [task description]

Selected: [agent-name] ([N] points)

Context provided ([N] tokens):
  ✅ [context file 1]
  ✅ [context file 2]

Agent working...
```

**Completion Phase**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent: [agent-name]
Task: [brief summary]

Files changed:
  - [file paths]

Tests:
  - Results: [pass/fail counts]
  - Coverage: [percentage]

Verification:
  ✅ Lint: Clean
  ✅ Types: No errors
  ✅ Tests: [N]/[N] passing
  ✅ Coverage: [percentage]

Next steps: [if any]
```

</output>

<examples>
## Routing Examples

**Backend Task**:

```bash
/route-agent "Implement POST /api/users endpoint with validation"
```

→ Routes to `backend-dev` (30 points: keywords "endpoint", "api", "POST")

**Frontend Task**:

```bash
/route-agent "Create UserProfile component with avatar upload"
```

→ Routes to `frontend-dev` (20 points: keywords "component", "avatar")

**Database Task**:

```bash
/route-agent "Add migration for user_preferences table"
```

→ Routes to `database-architect` (25 points: keywords "migration", "table" + specificity bonus)

**Debugging Task**:

```bash
/route-agent "Fix failing test_user_creation - IntegrityError on email field"
```

→ Routes to `debugger` (25 points: keywords "fix", "failing", "error")
</examples>

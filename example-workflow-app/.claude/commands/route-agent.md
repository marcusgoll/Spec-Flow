---
description: Internal helper to route tasks to specialist agents (context-aware delegation)
---

Route task to specialist agent: $ARGUMENTS

## MENTAL MODEL

**Purpose**: Intelligent agent delegation based on task domain, file paths, and keywords.

**Pattern**: Routing (from Anthropic best practices)
- Classify input by domain -> Route to specialized sub-agent -> Return structured result

**Context efficiency**:
- Agent receives minimal, focused context
- No token waste on irrelevant codebase scanning

## PARSE TASK DESCRIPTION

From `$ARGUMENTS`, extract:
- **Domain**: Backend | Frontend | Database | Tests | Debugging | Review
- **File paths**: Explicit paths mentioned (e.g., "api/app/routes/users.py")
- **Keywords**: Trigger words for agent selection
- **Task type**: Implement | Fix | Test | Review | Optimize

## ROUTING DECISION TREE

### Backend API/Services
**Agent**: `spec-flow-backend-dev`

**Triggers**:
- File paths: `api/**/*.py`, `app/**/*.py`
- Keywords: "endpoint", "route", "service", "FastAPI", "Pydantic", "middleware"
- Task types: Implement API, create service, add endpoint

**Context to provide**:
- Task description
- Relevant spec.md sections
- REUSE markers from tasks.md (if applicable)
- Error-log.md recent entries (for context)

---

### Frontend UI/Components
**Agent**: `spec-flow-frontend-shipper`

**Triggers**:
- File paths: `apps/**/*.tsx`, `apps/**/*.ts`, `components/**`
- Keywords: "component", "UI", "React", "Next.js", "page", "form", "button"
- Task types: Implement UI, create component, add page

**Context to provide**:
- Task description
- visuals/README.md (for UX patterns)
- Design system references
- REUSE markers from tasks.md

---

### Database Schema/Queries
**Agent**: `spec-flow-database-architect`

**Triggers**:
- File paths: `api/alembic/**`, `api/app/models/**`
- Keywords: "migration", "schema", "database", "SQL", "Alembic", "table", "RLS"
- Task types: Create migration, update schema, optimize query

**Context to provide**:
- Task description
- data-model.md (ERD and schema definitions)
- Existing migration files
- Performance targets from plan.md

---

### Tests/QA
**Agent**: `spec-flow-qa-test`

**Triggers**:
- File paths: `**/tests/**`, `**/test_*.py`, `**/*.test.ts`
- Keywords: "test", "coverage", "E2E", "Playwright", "Jest", "integration", "unit"
- Task types: Write tests, increase coverage, fix failing tests

**Context to provide**:
- Task description
- Test patterns from .spec-flow/templates/test-patterns.md
- Coverage targets from plan.md (80%+ line, 80%+ branch)
- TDD workflow (RED -> GREEN -> REFACTOR)

---

### Debugging/Error Fixing
**Agent**: `spec-flow-debugger`

**Triggers**:
- Keywords: "bug", "error", "failing", "broken", "fix", "debug", "crash"
- Task types: Debug issue, fix error, resolve failure

**Context to provide**:
- Error description and stack trace
- error-log.md (recent entries for context)
- Reproduction steps
- Files involved

---

### Code Review/Quality
**Agent**: `spec-flow-senior-code-reviewer`

**Triggers**:
- Keywords: "review", "quality", "contract", "KISS", "DRY", "security", "compliance"
- Task types: Review code, validate contracts, check quality gates

**Context to provide**:
- Files to review (git diff or specific paths)
- OpenAPI contracts (if exist in specs/NNN/contracts/)
- Quality gate requirements from plan.md
- Constitution.md for MUST principles

---

## AGENT INVOCATION

Use Task tool with structured prompt:

```javascript
Task({
  subagent_type: "[agent-name]",
  description: "[5-10 word description]",
  prompt: `[Domain] task: [task description]

**Context**:
- Feature: specs/NNN-feature-name
- Task ID: T0NN (if applicable)
- Files: [relevant file paths]

**Requirements**:
[Extract from spec.md, plan.md, or tasks.md]

**Patterns to follow**:
- REUSE: [services/modules from tasks.md markers]
- Pattern reference: [file path if exists]
- Visual specs: [visuals/README.md if applicable]

**Expected deliverables**:
1. [specific output 1]
2. [specific output 2]
3. Evidence: Test output showing pass/fail
4. Verification: Quality gates passed

**Return format**:
- Root cause (if debugging)
- Files changed (list with paths)
- Tests added/modified (with evidence)
- Verification status (lint, types, tests)
- Notes or side effects`
})
```

## STRUCTURED RESULT

Agent should return:
```json
{
  "agent": "spec-flow-backend-dev",
  "task_completed": true,
  "files_changed": ["api/app/routes/users.py", "api/app/schemas/user.py"],
  "tests_added": ["api/tests/test_users.py"],
  "verification": {
    "lint": "pass",
    "type_check": "pass",
    "tests": "pass (12/12)",
    "coverage": "85%"
  },
  "notes": "Added user listing endpoint with pagination",
  "side_effects": "None",
  "next_steps": "Review contract alignment with OpenAPI spec"
}
```

## ROUTING EXAMPLES

### Example 1: Backend Task
```
Input: "Implement POST /api/users endpoint with validation"
Analysis:
  - Domain: Backend API
  - Keywords: "endpoint", "POST", "api"
  - File paths: None explicit (will be api/app/routes/)
Route: spec-flow-backend-dev
Context: spec.md requirements, data-model.md User schema, REUSE: validation_service
```

### Example 2: Frontend Task
```
Input: "Create UserProfile component with avatar upload"
Analysis:
  - Domain: Frontend UI
  - Keywords: "component", "avatar", "upload"
  - File paths: None explicit (will be apps/app/components/)
Route: spec-flow-frontend-shipper
Context: visuals/README.md patterns, design system colors, REUSE: ImageUpload component
```

### Example 3: Database Task
```
Input: "Add migration for user_preferences table"
Analysis:
  - Domain: Database
  - Keywords: "migration", "table"
  - File paths: None explicit (will be api/alembic/versions/)
Route: spec-flow-database-architect
Context: data-model.md ERD, existing migrations, RLS requirements from plan.md
```

### Example 4: Debugging Task
```
Input: "Fix failing test_user_creation - IntegrityError on email field"
Analysis:
  - Domain: Debugging
  - Keywords: "fix", "failing", "error"
  - File paths: test_user_creation (implies api/tests/)
Route: spec-flow-debugger
Context: error-log.md recent entries, test file, User model definition
```

## ERROR HANDLING

- **No clear match**: Default to spec-flow-debugger (most general)
- **Multiple matches**: Prefer most specific (Database > Backend > Debugger)
- **Agent unavailable**: Return error, suggest manual implementation
- **Agent timeout**: Cancel after 5 minutes, suggest retry or manual
- **Agent returns invalid**: Validate against expected schema, request re-run

## CONSTRAINTS

- Always provide minimal, focused context (avoid full codebase dumps)
- Include REUSE markers when available (prevent duplication)
- Specify expected deliverables clearly
- Require evidence for test execution (no "tests should pass" without proof)

## RETURN

Brief routing summary:
```
Routed to: [agent-name]
Domain: [Backend/Frontend/Database/Tests/Debug/Review]
Context provided:
  - [context item 1]
  - [context item 2]
  - [context item 3]

Agent working on: [task description]
```




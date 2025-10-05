# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]`
**Date**: [DATE]
**Spec**: [link]

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: [e.g., Python 3.11, TypeScript 5.0 or NEEDS CLARIFICATION]
**Dependencies**: [e.g., FastAPI, Next.js, PostgreSQL or NEEDS CLARIFICATION]
**Storage**: [e.g., PostgreSQL, Redis, files or N/A]
**Testing**: [e.g., pytest, Jest, Playwright or NEEDS CLARIFICATION]
**Platform**: [e.g., Linux server, Browser, Mobile or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines structure]
**Performance**: [<10s extraction, <500ms API, <1.5s FCP or NEEDS CLARIFICATION]
**Constraints**: [<200ms p95, <100MB memory, offline or NEEDS CLARIFICATION]
**Scale**: [10k users, 1M records, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

**Spec-Flow Workflow Principles**:
- [ ] Alignment: Spec, plan, and tasks describe the same outcomes
- [ ] Simplicity: Ship the smallest change that satisfies the requirement
- [ ] Contract-first: APIs, events, and schemas documented before code lands
- [ ] Quality gates: Lint, type checks, tests, and coverage thresholds met
- [ ] Observability: Logging/metrics/traces updated for new behaviour
- [ ] Accessibility & performance budgets respected
- [ ] Security & privacy reviewed for new data flows

## Project Structure

**Documentation** (`specs/[###-feature]/`):
- `plan.md` - This file
- `research.md` - Phase 0 output
- `data-model.md` - Phase 1 output
- `quickstart.md` - Phase 1 output
- `error-log.md` - Failure tracking
- `contracts/` - Phase 1 output
- `tasks.md` - Phase 2 output (from /tasks command)

**Source Code** (repository root):

```
# Option 1: Single project (DEFAULT)
src/, tests/

# Option 2: Web application (frontend + backend detected)
backend/src/, frontend/src/

# Option 3: Mobile + API (iOS/Android detected)
api/, ios/ or android/
```

**Structure Decision**: [DEFAULT to Option 1 unless Technical Context indicates web/mobile]

## Phase 0: Codebase Scan & Research

### [EXISTING INFRASTRUCTURE - REUSE]

From codebase scan:
-  [ExistingService] ([path])
-  [ExistingMiddleware] ([path])
-  Similar pattern: [path] (follow this structure)

### [NEW INFRASTRUCTURE - CREATE]

No existing alternatives:
-  [NewService] (new capability)
-  [NewIntegration] (new integration)

### Research Findings

Decision: [what was chosen]
Rationale: [why chosen]
Alternatives considered: [what else evaluated]
Existing code to reuse: [from codebase scan]

**Output**: research.md with [EXISTING/NEW] sections and all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts

### [ARCHITECTURE DECISIONS]

- Stack choices with rationale (from research.md)
- Communication patterns (REST/GraphQL/WebSocket)
- State management approach
- Why reusing X instead of creating Y

### [STRUCTURE]

- Directory layout (follow existing patterns from scan)
- Module organization
- File naming conventions

### [SCHEMA]

- Database tables with relationships (Mermaid ERD)
- Migrations needed
- Index strategy

### [PERFORMANCE TARGETS]

- API: <500ms p95 response time
- Frontend: <1.5s FCP, <3s TTI
- Database: <100ms query time
- Bundle size: <200KB initial

### [SECURITY]

- Authentication strategy (JWT/Clerk/OAuth)
- Authorization model (RBAC/ABAC)
- Input validation approach
- Rate limiting rules

### Artifacts Generated

1. **data-model.md**: Entities, fields (referencing REUSE from existing models), relationships, validation rules
2. **contracts/**: OpenAPI/GraphQL schemas for each endpoint
3. **Contract tests**: One test file per endpoint, must fail initially
4. **quickstart.md**: Integration test scenarios from user stories
5. **Agent context**: Updated incrementally with NEW tech only

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, [EXISTING/NEW] in plan.md

## Phase 2: Task Planning Approach

*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.spec-flow/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs
- Each contract  contract test task [P]
- Each entity  model creation task [P]
- Each user story  integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected |
|-----------|------------|------------------------------|
| [Only if constitutional violations exist] | [specific need] | [why simpler approach insufficient] |

## Progress Tracking

**Phase Gates**:
- [ ] Phase 0: Research complete  `research.md` generated
- [ ] Phase 1: Design complete  `data-model.md`, `contracts/`, `quickstart.md`
- [ ] Phase 2: Task approach documented  Ready for `/tasks`
- [ ] Error ritual entry added after latest failure (if any)

**Quality Gates**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity justified (if any)
- [ ] Stack alignment confirmed



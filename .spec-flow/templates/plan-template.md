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

> **REMOVE THIS SECTION IF**: No project constitution file exists at `.spec-flow/memory/constitution.md`

**Project Constitution Principles** (from `.spec-flow/memory/constitution.md`):
- [ ] [Principle I]: [Description]
- [ ] [Principle II]: [Description]
- [ ] [Principle III]: [Description]
- [ ] [Principle IV]: [Description]
- [ ] [Principle V]: [Description]
- [ ] [Principle VI]: [Description]
- [ ] [Principle VII]: [Description]
- [ ] [Principle VIII]: [Description]

*Replace with actual principles from your project's constitution file, or remove this section entirely if no constitution exists*

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

## Context Engineering Plan

- **Context budget**: [Max tokens, tool output trims, when to compact]
- **Token triage**: [What stays resident vs. retrieved on demand]
- **Retrieval strategy**: [JIT tools, identifiers, caching heuristics]
- **Memory artifacts**: [NOTES.md / TODO.md cadence, retention policy]
- **Compaction & resets**: [Summaries, tool log pruning, restart triggers]
- **Sub-agent handoffs**: [Scopes, shared state, summary contract]

## Phase 0: Codebase Scan & Research

### [EXISTING INFRASTRUCTURE - REUSE]

From codebase scan:
- ✅ [ExistingService] ([path])
- ✅ [ExistingMiddleware] ([path])
- ✅ Similar pattern: [path] (follow this structure)

### [NEW INFRASTRUCTURE - CREATE]

No existing alternatives:
- 🆕 [NewService] (new capability)
- 🆕 [NewIntegration] (new integration)

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

> **REMOVE THIS SECTION IF**: No database changes needed (pure UI feature, config-only change)

- Database tables with relationships (Mermaid ERD)
- Migrations needed
- Index strategy
- RLS policies (if applicable)

### [PERFORMANCE TARGETS]

- API: <500ms p95 response time
- Frontend: <1.5s FCP, <3s TTI
- Database: <100ms query time
- Bundle size: <200KB initial

### [SECURITY]

> **REMOVE THIS SECTION IF**: No security-sensitive changes (internal tool, read-only feature, cosmetic UI)

- Authentication strategy (JWT/Clerk/OAuth)
- Authorization model (RBAC/ABAC)
- Input validation approach
- Rate limiting rules
- Data encryption (at rest/in transit)

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
- Load `\spec-flow/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs
- Each contract → contract test task [P]
- Each entity → model creation task [P]
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

## Complexity Tracking

> **REMOVE THIS SECTION IF**: No constitution violations or complexity exceptions needed

**Purpose**: Document and justify any deviations from project constitution or KISS principle.

| Violation | Why Needed | Simpler Alternative Rejected |
|-----------|------------|------------------------------|
| [Principle violated] | [Specific business need] | [Why simpler approach insufficient] |
| [e.g., "No file storage"] | [e.g., "User-uploaded PDFs for 7-day preview"] | [e.g., "In-memory only insufficient for multi-device access"] |

*Only include this section if you need to justify complexity that violates constitution principles*

## Progress Tracking

**Phase Gates**:
- [ ] Phase 0: Research complete → `research.md` generated
- [ ] Phase 1: Design complete → `data-model.md`, `contracts/`, `quickstart.md`
- [ ] Phase 2: Task approach documented → Ready for `/tasks`
- [ ] Error ritual entry added after latest failure (if any)
- [ ] Context plan documented (budget, retrieval, memory)

**Quality Gates**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity justified (if any)
- [ ] Stack alignment confirmed
- [ ] Context engineering plan documented

---

## Discovered Patterns

> **Purpose**: Track reusable code found during implementation that wasn't identified in Phase 0 research
> **Updated by**: `/implement` command when task agents discover patterns
> **Last Updated**: [Auto-updated timestamp]

### Reuse Additions

**Format**: Document patterns discovered during implementation that should be reused by future features

- ✅ **[ServiceName/FunctionName]** (`[path]:[line-range]`)
  - **Discovered in**: Task [ID] - [Brief task description]
  - **Purpose**: [What this code does]
  - **Reusable for**: [What types of tasks can reuse this]
  - **Why not in Phase 0**: [Why this wasn't found during initial scan - new code, buried in unrelated file, etc.]

**Example**:
- ✅ **UserService.create_user()** (`api/src/services/user.py:42-58`)
  - **Discovered in**: T013 - Create user registration endpoint
  - **Purpose**: Handles user creation with password hashing, email validation, and role assignment
  - **Reusable for**: Any endpoint that creates users (admin panel, invite flow, etc.)
  - **Why not in Phase 0**: New code created in T010, wasn't scanned yet

- ✅ **ErrorHandler middleware** (`api/src/middleware/errors.py`)
  - **Discovered in**: T020 - Add error handling to auth endpoints
  - **Purpose**: Standardized RFC 7807 error responses with logging
  - **Reusable for**: All API endpoints requiring consistent error formatting
  - **Why not in Phase 0**: Generic middleware, not keyword-specific (auth, user, session)

### Architecture Adjustments

**Format**: Document when actual architecture differs from Phase 1 design

- **[Component/Schema Change]**: [What changed]
  - **Original design**: [What Phase 1 specified]
  - **Actual implementation**: [What was built instead]
  - **Reason**: [Why the change was needed - discovered need, technical constraint, integration requirement]
  - **Migration**: [Path to migration file if database change]
  - **Impact**: [None | Requires plan.md update]

**Example**:
- **Database schema change**: Added `last_login` column to `users` table
  - **Original design**: Users table with id, email, password_hash, created_at
  - **Actual implementation**: Added last_login timestamp column
  - **Reason**: Session timeout logic (T015) requires tracking last login time for 30-day expiry
  - **Migration**: `api/alembic/versions/005_add_last_login.py`
  - **Impact**: Minor - additive change, no breaking impact

### Integration Discoveries

**Format**: Document unexpected integrations or dependencies found during implementation

- **[Integration Point]**: [What was discovered]
  - **Component**: [What code needs to integrate]
  - **Dependency**: [What it depends on]
  - **Reason**: [Why this dependency exists]
  - **Resolution**: [How it was handled]

**Example**:
- **Email verification**: Requires Clerk webhook subscription
  - **Component**: User registration flow (T013)
  - **Dependency**: Clerk webhook for email_verified event
  - **Reason**: Clerk handles email verification, not our API
  - **Resolution**: Added webhook handler in `api/src/webhooks/clerk.py` (T014)


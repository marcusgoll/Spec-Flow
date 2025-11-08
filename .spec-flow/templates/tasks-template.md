# Tasks: [FEATURE NAME]

## Progress Summary

> **Purpose**: Track task completion velocity, ETA, and identify bottlenecks
> **Updated by**: Task tracker after each task completion
> **Last Updated**: [Auto-updated timestamp]

### Overall Progress

- **Total Tasks**: [N]
- **Completed**: [X] ([percentage]%)
- **In Progress**: [Y]
- **Blocked**: [Z]
- **Remaining**: [N - X - Y - Z]

### Velocity Metrics

- **Average Time per Task**: [N] minutes
- **Completion Rate**: [N] tasks/day (last 2 days)
- **Estimated Remaining Time**: [N] hours
- **ETA**: [Date and time based on current velocity]

### Recent Completions

- ✅ [TaskID]: [Description] - [duration] ([timestamp])
- ✅ [TaskID]: [Description] - [duration] ([timestamp])
- ✅ [TaskID]: [Description] - [duration] ([timestamp])

### Bottlenecks

**Tasks Taking Longer Than Estimated**:

- **[TaskID] ([Name])**: Took [actual] vs estimated [estimate]
  - **Reason**: [Why it took longer - complexity, blockers, learning curve]
  - **Impact**: +[N] hours overall delay

**Example**:
- **T006-T009 (Migration tasks)**: Took 90min vs estimated 30min
  - **Reason**: RLS policy complexity - required research on Postgres row-level security
  - **Impact**: +1 hour overall delay

### Current Sprint Status

**Today's Goal**: Complete [task range, e.g., T015-T020]
**Progress**: [X]/[Y] tasks completed today
**On Track**: [Yes/No - based on ETA vs deadline]

---

## [CODEBASE REUSE ANALYSIS]

**From plan.md [EXISTING/NEW] sections:**

Scanned: api/src/**/*.py, frontend/**/*.tsx

**[EXISTING - REUSE]**
- ✅ DatabaseService (api/src/services/database_service.py)
- ✅ AuthMiddleware (api/src/middleware/auth.py)
- ✅ UserModel (api/src/models/user.py) - has email, role fields
- ✅ Pattern: api/src/modules/notifications/ (follow structure)

**[NEW - CREATE]**
- 🆕 MessageService (no existing)
- 🆕 WebSocketGateway (no existing)
- 🆕 MessageQueue (Redis pub/sub)

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`

---

## Phase 3.1: Setup & Quality Gates

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools (ESLint/Prettier or Black/Ruff)
- [ ] T004 [P] Set up type checking (TypeScript or Python type hints)
- [ ] T005 [P] Configure test coverage reporting (target: 80% minimum)

---

## Phase 3.1.5: Database Migrations (if schema changes)

**ONLY include this section if migration-plan.md exists**

**Migration Tasks (delegated to cfipros-database-architect):**

- [ ] T006 [RED] Write failing migration test for [entity] table in `api/tests/migrations/test_[entity]_migration.py`
      Test: Query [entity] table → should fail (doesn't exist yet)
      Test: Check constraint [constraint_name] → should fail (not defined yet)
      REUSE: api/tests/migrations/test_initial_schema.py (test pattern)
      Must FAIL initially

- [ ] T007 [GREEN→T006] Create migration XXX_[change] in `api/alembic/versions/XXX_[change].py`
      **DELEGATE**: cfipros-database-architect
      Fields: [list from data-model.md]
      Constraints: [FK, UNIQUE, CHECK, NOT NULL from data-model.md]
      Indexes: [from migration-plan.md]
      REUSE: api/alembic/versions/001_initial_schema.py (migration pattern)
      Must include: upgrade(), downgrade(), verify queries
      From: migration-plan.md Migration XXX

- [ ] T008 [P] Create RLS policies in `api/sql/policies/[table]_policies.sql` (if applicable)
      Policies: anon (read-only), authenticated (CRUD own), service (full access)
      DELEGATE: cfipros-database-architect
      Pattern: api/sql/policies/reports_policies.sql
      From: migration-plan.md RLS section

- [ ] T009 [P] Create seed script in `seeds/[feature]/seed_[table].sql` (if needed)
      Idempotent: INSERT ... ON CONFLICT DO NOTHING
      DELEGATE: cfipros-database-architect
      Pattern: seeds/acs/seed_acs_codes.sql
      From: migration-plan.md Seed Data section

**Example (concrete):**

- [ ] T006 [RED] Write failing migration test for Message table in `api/tests/migrations/test_message_migration.py`
      Test: SELECT * FROM messages → should fail (table doesn't exist)
      Test: Check FK constraint messages_channel_id_fkey → should fail
      REUSE: api/tests/migrations/test_reports.py (pattern)

- [ ] T007 [GREEN→T006] Create migration 004_create_messages in `api/alembic/versions/004_create_messages.py`
      **DELEGATE**: cfipros-database-architect
      Fields: id (UUID PK), channel_id (FK), user_id (FK), content (TEXT max 4000), created_at (TIMESTAMPTZ)
      Constraints: FK to channels(id), FK to users(id), CHECK (LENGTH(content) <= 4000)
      Indexes: idx_messages_channel (channel_id, created_at DESC), idx_messages_user (user_id)
      REUSE: api/alembic/versions/001_initial_schema.py
      From: migration-plan.md Migration 004

- [ ] T008 [P] Create RLS policies in `api/sql/policies/messages_policies.sql`
      **DELEGATE**: cfipros-database-architect
      Policies:
        - anon: NONE (no access)
        - authenticated: SELECT/INSERT own, UPDATE/DELETE own (user_id = auth.uid())
        - service: ALL (bypass RLS)
      Pattern: api/sql/policies/reports_policies.sql

- [ ] T009 [P] Create seed script in `seeds/chat/seed_messages.sql`
      **DELEGATE**: cfipros-database-architect
      10 example messages for development
      Idempotent: DELETE FROM messages WHERE id IN (...); INSERT ...

---

## Phase 3.2: Tests - TDD (MUST FAIL before implementation)

**CONCRETE EXAMPLES:**

- [ ] T010 [P] Contract test POST /api/chat/messages in `tests/contract/test_messages_post.py`
      Request: {channel_id: str, content: str}
      Response: {id: UUID, channel_id: str, user_id: str, content: str, created_at: datetime}
      Status: 201 Created
      Auth: Requires valid JWT token
      REUSE: api/tests/contract/test_auth.py (JWT test patterns)
      Must FAIL (no implementation yet)

- [ ] T011 [P] WebSocket connection test in `api/tests/integration/test_ws_connection.py`
      REUSE: api/tests/integration/test_auth.py (JWT test patterns)
      Test: Connect with valid token → receive welcome event
      Must FAIL (no implementation yet)

- [ ] T012 [P] Message creation test in `api/tests/unit/test_message_model.py`
      Test: Create message with valid data → saves to DB
      Test: Create with invalid content (>4000 chars) → raises ValidationError
      Must FAIL initially

---

## Phase 3.3: Implementation

**CONCRETE EXAMPLES:**

- [ ] T013 [P] Create Message model in `api/src/modules/chat/models/message.py`
      Fields: id (UUID), channel_id (FK), user_id (FK), content (str, max 4000), created_at (timestamp)
      Relationships: belongs_to Channel, belongs_to User
      REUSE: Base model from api/src/models/base.py (SQLAlchemy setup)
      Pattern: Follow api/src/models/notification.py structure
      Validation: content not empty, max 4000 chars
      From: data-model.md Message entity

- [ ] T014 [P] Create MessageService in `api/src/modules/chat/services/message_service.py`
      REUSE: DatabaseService (api/src/services/database_service.py)
      REUSE: CacheService (api/src/services/cache_service.py)
      Pattern: Follow api/src/modules/notifications/services/notification_service.py
      Methods:
        - send_message(channel_id, user_id, content) -> Message
        - get_messages(channel_id, limit=50, before=None) -> List[Message]
      From: contracts/chat-api.yaml

- [ ] T015 [P] Create WebSocketGateway in `api/src/modules/chat/gateway/ws_gateway.py`
      REUSE: AuthMiddleware (api/src/middleware/auth.py)
      NEW: WebSocket connection handler (no existing)
      Methods:
        - handle_connect(websocket, token) -> Connection
        - handle_message(connection, data) -> None
        - broadcast(channel_id, message) -> None
      Events: connect, disconnect, message, error
      From: contracts/websocket-events.yaml

- [ ] T016 POST /api/chat/messages endpoint in `api/src/api/v1/chat.py`
      REUSE: MessageService (from T014)
      REUSE: AuthMiddleware (api/src/middleware/auth.py)
      Request: {channel_id: str, content: str}
      Response: {id: UUID, ...} 201 Created
      Error handling: 400 validation, 401 auth, 404 channel not found
      Performance: <500ms p95 response time
      From: contracts/chat-api.yaml POST /api/chat/messages

---

## Phase 3.4: Integration

- [ ] T020 Connect [Service] to database in `src/services/[service].py`
- [ ] T021 Auth middleware in `src/middleware/auth.py`
- [ ] T022 Request/response logging in `src/middleware/logging.py`
- [ ] T023 CORS and security headers in `src/config/security.py`

---

## Phase 3.5: Polish

- [ ] T024 [P] Unit tests 80% coverage in `tests/unit/`
- [ ] T025 Performance validation API <500ms, extraction <10s P95
- [ ] T026 [P] Accessibility audit WCAG 2.1 AA compliance
- [ ] T027 [P] Mobile responsiveness testing
- [ ] T028 [P] Update API documentation
- [ ] T029 Remove code duplication (DRY principle)
- [ ] T030 Run linting and type checking
- [ ] T031 Execute `quickstart.md` for validation

---

## Dependencies

**Sequential**: Setup → Tests (failing) → Implementation → Integration → Polish

**Parallel Safety**:
- [P] tasks = different files, no shared dependencies
- Same file modifications = sequential only

---

## Validation Checklist

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation (TDD)
- [ ] Parallel tasks truly independent ([P] = different files)
- [ ] Each task specifies exact file path
- [ ] Quality gates configured (linting, type checking, 80% coverage)
- [ ] Performance tests included (<10s extraction, <500ms API)
- [ ] Accessibility requirements (WCAG 2.1 AA)
- [ ] Max 25-30 tasks for maintainability

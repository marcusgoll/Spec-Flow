# Tasks: [FEATURE NAME]

## [CODEBASE REUSE ANALYSIS]

**From plan.md [EXISTING/NEW] sections:**

Scanned: api/src/**/*.py, frontend/**/*.tsx

**[EXISTING - REUSE]**
-  DatabaseService (api/src/services/database_service.py)
-  AuthMiddleware (api/src/middleware/auth.py)
-  UserModel (api/src/models/user.py) - has email, role fields
-  Pattern: api/src/modules/notifications/ (follow structure)

**[NEW - CREATE]**
-  MessageService (no existing)
-  WebSocketGateway (no existing)
-  MessageQueue (Redis pub/sub)

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

## Phase 3.2: Tests - TDD (MUST FAIL before implementation)

**CONCRETE EXAMPLES:**

- [ ] T006 [P] Contract test POST /api/chat/messages in `tests/contract/test_messages_post.py`
      Request: {channel_id: str, content: str}
      Response: {id: UUID, channel_id: str, user_id: str, content: str, created_at: datetime}
      Status: 201 Created
      Auth: Requires valid JWT token
      REUSE: api/tests/contract/test_auth.py (JWT test patterns)
      Must FAIL (no implementation yet)

- [ ] T007 [P] WebSocket connection test in `api/tests/integration/test_ws_connection.py`
      REUSE: api/tests/integration/test_auth.py (JWT test patterns)
      Test: Connect with valid token  receive welcome event
      Must FAIL (no implementation yet)

- [ ] T008 [P] Message creation test in `api/tests/unit/test_message_model.py`
      Test: Create message with valid data  saves to DB
      Test: Create with invalid content (>4000 chars)  raises ValidationError
      Must FAIL initially

---

## Phase 3.3: Implementation

**CONCRETE EXAMPLES:**

- [ ] T011 [P] Create Message model in `api/src/modules/chat/models/message.py`
      Fields: id (UUID), channel_id (FK), user_id (FK), content (str, max 4000), created_at (timestamp)
      Relationships: belongs_to Channel, belongs_to User
      REUSE: Base model from api/src/models/base.py (SQLAlchemy setup)
      Pattern: Follow api/src/models/notification.py structure
      Validation: content not empty, max 4000 chars
      From: data-model.md Message entity

- [ ] T012 [P] Create MessageService in `api/src/modules/chat/services/message_service.py`
      REUSE: DatabaseService (api/src/services/database_service.py)
      REUSE: CacheService (api/src/services/cache_service.py)
      Pattern: Follow api/src/modules/notifications/services/notification_service.py
      Methods:
        - send_message(channel_id, user_id, content) -> Message
        - get_messages(channel_id, limit=50, before=None) -> List[Message]
      From: contracts/chat-api.yaml

- [ ] T013 [P] Create WebSocketGateway in `api/src/modules/chat/gateway/ws_gateway.py`
      REUSE: AuthMiddleware (api/src/middleware/auth.py)
      NEW: WebSocket connection handler (no existing)
      Methods:
        - handle_connect(websocket, token) -> Connection
        - handle_message(connection, data) -> None
        - broadcast(channel_id, message) -> None
      Events: connect, disconnect, message, error
      From: contracts/websocket-events.yaml

- [ ] T014 POST /api/chat/messages endpoint in `api/src/api/v1/chat.py`
      REUSE: MessageService (from T012)
      REUSE: AuthMiddleware (api/src/middleware/auth.py)
      Request: {channel_id: str, content: str}
      Response: {id: UUID, ...} 201 Created
      Error handling: 400 validation, 401 auth, 404 channel not found
      Performance: <500ms p95 response time
      From: contracts/chat-api.yaml POST /api/chat/messages

---

## Phase 3.4: Integration

- [ ] T018 Connect [Service] to database in `src/services/[service].py`
- [ ] T019 Auth middleware in `src/middleware/auth.py`
- [ ] T020 Request/response logging in `src/middleware/logging.py`
- [ ] T021 CORS and security headers in `src/config/security.py`

---

## Phase 3.5: Polish

- [ ] T022 [P] Unit tests 80% coverage in `tests/unit/`
- [ ] T023 Performance validation API <500ms, extraction <10s P95
- [ ] T024 [P] Accessibility audit WCAG 2.1 AA compliance
- [ ] T025 [P] Mobile responsiveness testing
- [ ] T026 [P] Update API documentation
- [ ] T027 Remove code duplication (DRY principle)
- [ ] T028 Run linting and type checking
- [ ] T029 Execute `quickstart.md` for validation

---

## Dependencies

**Sequential**: Setup  Tests (failing)  Implementation  Integration  Polish

**Parallel Safety**:
- [P] tasks = different files, no shared dependencies
- Same file modifications = sequential only

---

## Validation Checklist

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation (TDD)
- [ ] Parallel tasks truly independent ([P] = different files)
- [ ] Each task Specifies exact file path
- [ ] Quality gates configured (linting, type checking, 80% coverage)
- [ ] Performance tests included (<10s extraction, <500ms API)
- [ ] Accessibility requirements (WCAG 2.1 AA)
- [ ] Max 25-30 tasks for maintainability


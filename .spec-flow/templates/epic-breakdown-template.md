# Epic Breakdown Template

**Purpose**: Guide for including epic breakdowns in plan.md for parallel development.

## When to Use Epic Mode

**Use epic breakdowns when**:
- Feature requires >3 distinct vertical slices (API, DB, UI, etc.)
- Work can be parallelized across multiple agents
- Contracts can be defined upfront

**Don't use epic mode when**:
- Simple feature with <3 tasks
- Work is highly sequential with dependencies
- Contracts are unclear or will evolve during implementation

## Epic Breakdown Section Format

Add this section to plan.md after the implementation plan:

```markdown
## Epic Breakdown

### Epic 1: [Epic Name]
**Vertical Slice**: [Backend/Frontend/Database/Infrastructure]
**Contracts**: [API endpoints, events, schemas this epic exposes]
**Dependencies**: [None | Epic N (reason)]
**Estimated Tasks**: [Number of tasks]
**Agent Type**: [backend-dev | frontend-shipper | database-architect]

**Deliverables**:
- [ ] API endpoint: POST /api/auth/login
- [ ] Database migration: users table with RLS
- [ ] Unit tests with 80% coverage
- [ ] Feature flag: auth_api_enabled

**Contract Outputs**:
```yaml
# contracts/api/v1.1.0/openapi.yaml excerpt
paths:
  /api/auth/login:
    post:
      operationId: login
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email: { type: string, format: email }
                password: { type: string, minLength: 8 }
      responses:
        200:
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  token: { type: string }
                  user: { $ref: '#/components/schemas/User' }
```

**Rationale**: Authentication backend logic can be developed independently once API contract is locked.

---

### Epic 2: [Epic Name]
**Vertical Slice**: Frontend
**Contracts**: [API endpoints this epic consumes]
**Dependencies**: Epic 1 (consumes /api/auth/login endpoint)
**Estimated Tasks**: 6
**Agent Type**: frontend-shipper

**Deliverables**:
- [ ] Login form component with validation
- [ ] Auth context provider
- [ ] Protected route wrapper
- [ ] Feature flag: auth_ui_enabled

**Contract Inputs**:
- Consumes: POST /api/auth/login (Epic 1)
- Expects: JWT token in response

**Rationale**: UI can be developed against mocked API once contract is locked. Can start in parallel with Epic 1 using fixtures.

---

[Repeat for each epic]
```

## Epic Breakdown Guidelines

### Vertical Slicing

**Good vertical slices**:
- **Backend API** (epic-auth-api): API routes, business logic, tests
- **Frontend UI** (epic-auth-ui): Components, forms, state management
- **Database** (epic-auth-db): Migrations, RLS policies, indexes
- **Infrastructure** (epic-deploy-config): CI/CD, secrets, environment config

**Bad vertical slices** (too granular or coupled):
- "Write login function" (too small, not vertical)
- "All authentication" (too large, not sliceable)
- "Testing" (not a vertical slice, should be per epic)

### Dependency Guidelines

**Clear dependencies**:
- Frontend depends on Backend (consumes API)
- Deployment depends on Backend + Frontend (deploys both)

**Avoid circular dependencies**:
- ❌ Epic 1 depends on Epic 2, Epic 2 depends on Epic 1
- ✅ Epic 1 has no dependencies, Epic 2 depends on Epic 1

### Contract Definition

**Contracts must include**:
- API endpoint paths and methods
- Request/response schemas
- Error responses
- Authentication requirements

**Lock contracts before parallel work**:
1. Draft contracts in `contracts/api/vX.Y.Z/openapi.yaml`
2. Create Pact CDC tests in `contracts/pacts/`
3. Run `/contract.verify` to validate
4. Only then assign epics via `/scheduler.assign`

## Example: Authentication System

```markdown
## Epic Breakdown

### Epic 1: Authentication API
**Vertical Slice**: Backend
**Contracts**: POST /api/auth/login, POST /api/auth/register, GET /api/auth/me
**Dependencies**: None
**Estimated Tasks**: 8
**Agent Type**: backend-dev

**Deliverables**:
- [ ] POST /api/auth/register endpoint
- [ ] POST /api/auth/login endpoint (JWT generation)
- [ ] GET /api/auth/me endpoint (JWT validation)
- [ ] Password hashing (bcrypt)
- [ ] Unit tests (80% coverage)
- [ ] Integration tests (API contract validation)
- [ ] Feature flag: auth_api_enabled

**Contract Outputs**:
- POST /api/auth/register: Email + password → User + JWT token
- POST /api/auth/login: Email + password → JWT token
- GET /api/auth/me: JWT token → User profile

**Rationale**: Core authentication logic. Must complete first as Epic 2 depends on these endpoints.

---

### Epic 2: Authentication UI
**Vertical Slice**: Frontend
**Contracts**: Consumes Epic 1 API endpoints
**Dependencies**: Epic 1 (contracts locked)
**Estimated Tasks**: 6
**Agent Type**: frontend-shipper

**Deliverables**:
- [ ] LoginForm component (email/password inputs, validation)
- [ ] RegisterForm component
- [ ] AuthContext provider (token management)
- [ ] ProtectedRoute wrapper (redirect if not authenticated)
- [ ] E2E tests (Playwright)
- [ ] Feature flag: auth_ui_enabled

**Contract Inputs**:
- Consumes: POST /api/auth/login (Epic 1)
- Consumes: POST /api/auth/register (Epic 1)
- Consumes: GET /api/auth/me (Epic 1)

**Rationale**: UI can be developed in parallel with Epic 1 backend work using mocked API responses (fixtures). Once Epic 1 API is deployed, switch to real API.

---

### Epic 3: Database Setup
**Vertical Slice**: Database
**Contracts**: users table schema
**Dependencies**: None (can run in parallel with Epic 1)
**Estimated Tasks**: 4
**Agent Type**: database-architect

**Deliverables**:
- [ ] Create users table migration
- [ ] Add RLS policies (users can only read their own data)
- [ ] Add indexes (email unique index)
- [ ] Seed test data
- [ ] Feature flag: N/A (database changes don't need flags)

**Contract Outputs**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE POLICY user_isolation ON users
  FOR ALL USING (auth.uid() = id);
```

**Rationale**: Database schema can be defined and migrated independently. Epic 1 backend code will connect to this schema.
```

## Dependency Graph

Use the dependency graph parser to validate epic dependencies:

```bash
.spec-flow/scripts/bash/dependency-graph-parser.sh specs/002-auth/plan.md --format dot > graph.dot
dot -Tpng graph.dot -o graph.png
```

**Expected output**:
```
epic-auth-db → epic-auth-api → epic-auth-ui
               ↓
            epic-deploy-config
```

## Integration with Workflow

### Planning Phase (/plan)

When generating plan.md, the planning agent should:
1. Identify if feature is large enough for epic mode (>10 tasks)
2. If yes, add Epic Breakdown section after implementation plan
3. Define clear vertical slices with contracts
4. Document dependencies

### Task Phase (/tasks)

When generating tasks.md from plan.md:
- If epic breakdown exists, generate tasks per epic
- Prefix tasks with epic name: `[epic-auth-api] T001: Implement POST /login`
- Group tasks by epic in tasks.md

### Implementation Phase (/implement --parallel)

When executing parallel implementation:
1. Parse epic breakdown from plan.md
2. Lock contracts: `/contract.verify`
3. Assign epics: `/scheduler.assign epic-auth-api --agent backend-agent`
4. Launch specialist agents for each epic in parallel
5. Monitor progress in wip-tracker.yaml

## Best Practices

1. **Keep epics small**: 4-8 tasks per epic (1-2 days of work)
2. **Lock contracts early**: Before any implementation starts
3. **Minimize dependencies**: Aim for max 2 levels of dependency depth
4. **Test contracts**: CDC tests prevent breaking changes
5. **Use feature flags**: Every epic gets its own flag for safe merging

## Anti-Patterns

❌ **Too many dependencies**: Epic 5 depends on Epic 4, which depends on Epic 3...
- **Fix**: Simplify dependencies or merge epics

❌ **Unclear contracts**: "Epic 1 will expose some API endpoints"
- **Fix**: Define exact endpoints, schemas, responses upfront

❌ **Mixed concerns**: Epic includes both API and UI work
- **Fix**: Split into separate backend and frontend epics

❌ **No feature flags**: Merging incomplete epic without flag
- **Fix**: Add feature flag per epic, register with `/flag.add`

## References

- Epic State Machine: `.spec-flow/memory/epic-states.md`
- Dependency Graph Parser: `.spec-flow/scripts/bash/dependency-graph-parser.sh`
- Contract Governance: `docs/contract-governance.md`
- Vertical Slicing Guide: https://www.agilealliance.org/glossary/vertical-slice/

---

**Last Updated**: 2025-11-10

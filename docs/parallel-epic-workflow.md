# Parallel Epic Workflow Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-10

## Overview

This guide explains how to use the parallel epic development workflow for large features requiring coordination across multiple agents (backend, frontend, database, etc.).

**When to Use**:
- Feature requires >10 tasks
- Work can be split into independent vertical slices
- Multiple specialist agents can work simultaneously
- Contracts can be defined upfront

**Benefits**:
- **Faster delivery**: Parallel development reduces lead time
- **WIP limits**: One epic per agent prevents context switching
- **Quality gates**: Both CI and security gates enforce standards
- **Trunk-based**: Max 24h branch lifetime with feature flag protection

---

## End-to-End Workflow

### Phase 1: Feature Planning

**Command**: `/feature "Feature Name"`

Creates feature directory with initial structure:
```
specs/002-auth-system/
├── CLAUDE.md           # Feature context
├── spec.md             # Requirements
├── NOTES.md            # Implementation notes
├── workflow-state.yaml # State tracking
└── visuals/            # Diagrams, mockups
```

---

### Phase 2: Epic Breakdown

**Command**: `/plan`

The planning agent generates `plan.md` with:
1. **Implementation Plan** (standard, sequential approach)
2. **Epic Breakdown** (parallel approach, if feature is large enough)

**Epic Breakdown Example**:
```markdown
## Epic Breakdown

### Epic 1: Authentication API
**Vertical Slice**: Backend
**Contracts**: POST /api/auth/login, POST /api/auth/register
**Dependencies**: None
**Estimated Tasks**: 8
**Agent Type**: backend-dev

**Deliverables**:
- [ ] POST /api/auth/register endpoint
- [ ] POST /api/auth/login endpoint (JWT generation)
- [ ] Unit tests (80% coverage)
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
      responses:
        200:
          description: Login successful
```

---

### Epic 2: Authentication UI
**Vertical Slice**: Frontend
**Contracts**: Consumes Epic 1 API endpoints
**Dependencies**: Epic 1 (contracts locked)
**Estimated Tasks**: 6
**Agent Type**: frontend-shipper

**Deliverables**:
- [ ] LoginForm component
- [ ] AuthContext provider
- [ ] E2E tests
- [ ] Feature flag: auth_ui_enabled
```

**Validation**: Run dependency graph parser
```bash
.spec-flow/scripts/bash/dependency-graph-parser.sh specs/002-auth/plan.md --format text
```

**Output**:
```
Epic Dependency Graph
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

epic-auth-api
  └─ no dependencies

epic-auth-ui
  ├─ depends on: epic-auth-api

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Execution Order (Topological Sort):

  1. epic-auth-api
  2. epic-auth-ui
```

---

### Phase 3: Contract Design & Locking

**Step 1**: Design contracts (OpenAPI schemas)

Create `contracts/api/v1.1.0/openapi.yaml`:
```yaml
openapi: 3.1.0
info:
  title: Auth API
  version: 1.1.0
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
              required: [email, password]
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
        401:
          description: Invalid credentials
```

**Step 2**: Create CDC pacts

Create `contracts/pacts/auth-ui-to-auth-api.json`:
```json
{
  "consumer": { "name": "auth-ui" },
  "provider": { "name": "auth-api" },
  "interactions": [{
    "description": "login with valid credentials",
    "request": {
      "method": "POST",
      "path": "/api/auth/login",
      "headers": { "Content-Type": "application/json" },
      "body": {
        "email": "user@example.com",
        "password": "password123"
      }
    },
    "response": {
      "status": 200,
      "headers": { "Content-Type": "application/json" },
      "body": {
        "token": "jwt-token-here",
        "user": {
          "id": "user-id",
          "email": "user@example.com"
        }
      }
    }
  }]
}
```

**Step 3**: Verify contracts

**Command**: `/contract.verify`

```bash
.spec-flow/scripts/bash/contract-verify.sh --verbose
```

**Output** (success):
```
Contract Verification
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Found 1 pact(s)

Testing pact: auth-ui-to-auth-api.json
  Provider: auth-api
  Consumer: auth-ui

✅ All pacts verified

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Contracts locked ✅

Next: Assign epics to agents
  /scheduler.assign epic-auth-api --agent backend-agent
```

**Effect**: All epics transition from `Planned` → `ContractsLocked`

**Step 4**: Generate golden fixtures

**Command**: `/fixture.refresh`

```bash
.spec-flow/scripts/bash/fixture-refresh.sh contracts/api/v1.1.0/openapi.yaml
```

Creates `contracts/fixtures/auth-api-v1.1.0.json`:
```json
{
  "LoginRequest": {
    "email": "user@example.com",
    "password": "SecurePass123!"
  },
  "LoginResponse": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com"
    }
  }
}
```

**Usage**: Frontend agent uses fixtures to mock API during development

---

### Phase 4: Epic Assignment

**Command**: `/scheduler.assign <epic-name> --agent <agent-name>`

**Step 1**: Assign first epic (no dependencies)

```bash
/scheduler.assign epic-auth-api --agent backend-agent
```

**Output**:
```
✅ Assigned epic-auth-api to backend-agent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic assigned successfully

  Epic: epic-auth-api
  Agent: backend-agent
  State: ContractsLocked → Implementing

  WIP Slots: 1/2 occupied

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
  1. Register feature flag: /flag.add auth_api_enabled --reason "Epic in progress"
  2. Start implementing tasks (max 24h branch lifetime)
  3. Merge daily to main behind feature flag
```

**Step 2**: Register feature flag

```bash
/flag.add auth_api_enabled --reason "Authentication API epic in progress"
```

**Step 3**: Backend agent implements tasks

The backend-dev agent:
1. Reads `plan.md` for Epic 1 deliverables
2. Reads `contracts/api/v1.1.0/openapi.yaml` for API contract
3. Implements behind `if (featureFlags.auth_api_enabled) { ... }`
4. Merges to main daily (branch age <24h)
5. Marks epic complete when all tasks done

**Step 4**: Assign dependent epic

Once Epic 1 tasks are complete (or can run in parallel if using fixtures):

```bash
/scheduler.assign epic-auth-ui --agent frontend-agent
```

**Output**:
```
✅ Assigned epic-auth-ui to frontend-agent

  WIP Slots: 2/2 occupied

Next steps:
  1. Register feature flag: /flag.add auth_ui_enabled --reason "Epic in progress"
  2. Use fixtures for API mocking: contracts/fixtures/auth-api-v1.1.0.json
  3. Merge daily to main behind feature flag
```

**Step 5**: Frontend agent implements

The frontend-shipper agent:
1. Reads `plan.md` for Epic 2 deliverables
2. Reads `contracts/api/v1.1.0/openapi.yaml` for API contract
3. Uses `contracts/fixtures/auth-api-v1.1.0.json` to mock API calls
4. Implements behind `if (featureFlags.auth_ui_enabled) { ... }`
5. Merges to main daily
6. Switches to real API once Epic 1 is deployed

---

### Phase 5: Monitoring Progress

**Command**: `/scheduler.list`

```bash
/scheduler.list
```

**Output**:
```
Epic State Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Implementing (2):
  • epic-auth-api (backend-agent)
    Progress: 6/8 tasks (75%)
    Time: 3h 15m

  • epic-auth-ui (frontend-agent)
    Progress: 3/6 tasks (50%)
    Time: 2h 45m

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WIP Status: 2/2 slots occupied
```

**DORA Metrics**:

```bash
/metrics.dora --days 7
```

**Output**:
```
DORA Metrics (Last 7 Days)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment Frequency: 1.4/day
Lead Time for Changes: 16h
Change Failure Rate: 6%
Mean Time to Restore: 1.5h

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DORA Performance Tier: High
```

---

### Phase 6: Quality Gates

When epic completes all tasks, it transitions to `Review` state.

**Automatic**: GitHub Actions runs quality gates on PR merge

**Manual**: Run gates locally

```bash
/gate.ci --epic epic-auth-api --verbose
```

**Output** (passing):
```
CI Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Tests passed
✅ Linters passed
✅ Type checks passed
✅ Coverage sufficient (≥80%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CI gate PASSED

Epic can transition: Review → Integrated
```

```bash
/gate.sec --epic epic-auth-api --verbose
```

**Output** (passing):
```
Security Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ SAST passed (no HIGH/CRITICAL issues)
✅ No secrets detected
✅ Dependencies secure

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Security gate PASSED

Epic can transition: Review → Integrated
```

**Effect**: Both gates pass → epic transitions `Review` → `Integrated`

---

### Phase 7: Feature Flag Enablement

Once all epics are integrated:

**Step 1**: Enable flags in staging

```bash
# Backend flag
export AUTH_API_ENABLED=true

# Frontend flag
export AUTH_UI_ENABLED=true
```

**Step 2**: Test in staging

Manual QA verification:
- Login form appears
- Login succeeds with valid credentials
- Login fails with invalid credentials
- JWT token stored correctly
- Protected routes work

**Step 3**: Enable flags in production

Gradual rollout:
1. Enable for 10% of users
2. Monitor metrics (error rate, latency)
3. Enable for 50% of users
4. Monitor
5. Enable for 100% of users

**Step 4**: Retire feature flags

```bash
/flag.cleanup auth_api_enabled --verify
```

**Output**:
```
ℹ️  Scanning codebase for references to: auth_api_enabled

✅ No code references found

✅ Flag retired: auth_api_enabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Registry updated.

Commit changes:
  git add .spec-flow/memory/feature-flags.yaml
  git commit -m "refactor: remove auth_api_enabled flag"

Feature complete and deployed.
```

---

## Handling Blocked Epics

### Scenario: Epic Blocked by External Dependency

**Problem**: Epic 3 (Payment Integration) blocked waiting for Stripe API keys from DevOps

**Solution**: Park the epic

```bash
/scheduler.park epic-payment-integration --reason "Waiting for Stripe API keys" --blocked-by devops-team
```

**Output**:
```
⚠️ Parked epic-payment-integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic parked

  Epic: epic-payment-integration
  Agent: backend-agent (WIP slot released)
  Reason: Waiting for Stripe API keys
  Blocked by: devops-team
  State: Implementing → Parked

  WIP Slots: 1/2 occupied

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Auto-assigning next queued epic: epic-search-api

✅ Assigned epic-search-api to backend-agent
...
```

**Effect**:
- WIP slot released
- Next queued epic auto-assigned
- Backend agent continues working on different epic

**Resume**: When blocker resolved

```bash
/scheduler.assign epic-payment-integration
```

---

## DORA Alerts

**Daily monitoring** (run via cron):

```bash
.spec-flow/scripts/bash/dora-alerts.sh --notify
```

**Checks**:
1. Branch age violations (>24h)
2. CFR spike (>15%)
3. Flag debt (>5 active flags, expired flags)
4. Epic parking time (>48h)

**Output** (alert triggered):
```
DORA Metrics Alerts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ CFR is 18% (threshold: 15%)
  Recent deployments are failing frequently
  Action: Review failed CI runs, improve test coverage

🚨 1 alert(s) triggered

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Notification**: GitHub issue created with "dora-alert" label

---

## Best Practices

### 1. Epic Sizing

✅ **Good**: 4-8 tasks per epic (1-2 days of work)
❌ **Bad**: 20 tasks per epic (1 week of work)

**Why**: Smaller epics enable faster feedback loops and easier parking/reassignment

### 2. Contract Clarity

✅ **Good**: Fully specified OpenAPI schema with examples
❌ **Bad**: "Epic 1 will expose some endpoints"

**Why**: Clear contracts enable true parallel development

### 3. Feature Flag Hygiene

✅ **Good**: One flag per epic, retired within 14 days
❌ **Bad**: One flag for entire feature, kept forever

**Why**: Reduces flag debt and code complexity

### 4. Daily Merges

✅ **Good**: Merge to main every day behind feature flag
❌ **Bad**: Long-lived feature branch (>24h)

**Why**: Trunk-based development reduces merge conflicts

### 5. WIP Limits

✅ **Good**: One epic per agent at a time
❌ **Bad**: Agent works on 3 epics simultaneously

**Why**: Focus reduces context switching overhead

---

## Troubleshooting

### Problem: Epic won't assign

**Symptom**: `/scheduler.assign` fails with "Epic not in ContractsLocked state"

**Cause**: Contracts not verified

**Fix**:
```bash
/contract.verify
```

### Problem: Gate fails in CI but passes locally

**Symptom**: GitHub Actions shows gate failure, local run passes

**Cause**: Environment differences (Node version, missing dependencies)

**Fix**:
1. Check Node/Python version matches CI
2. Run `npm ci` (not `npm install`) to match lockfile
3. Check for missing environment variables

### Problem: Epic parked for >48h

**Symptom**: DORA alert shows epic-payment-integration parked 72h

**Cause**: Blocker not resolved or forgotten

**Fix**:
1. Escalate blocker resolution
2. If blocker will take >1 week, deprioritize epic (remove from sprint)
3. Assign different epic to agent

---

## References

- **Epic State Machine**: `.spec-flow/memory/epic-states.md`
- **Contract Governance**: `docs/contract-governance.md`
- **Epic Breakdown Template**: `.spec-flow/templates/epic-breakdown-template.md`
- **DORA Metrics**: `docs/dora-metrics.md`
- **Trunk-Based Development**: https://trunkbaseddevelopment.com/

---

**Version History**:
- v1.0.0 (2025-11-10): Initial guide for parallel epic workflow

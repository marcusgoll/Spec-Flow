# Contract Governance Guide

**Purpose**: Establish rules and processes for managing API and event contracts in the Spec-Flow workflow system to enable safe parallel epic development.

---

## Philosophy

**Contract-first development**: Lock API schemas and event contracts before parallelizing epic implementation. This prevents breaking changes mid-sprint and enables independent agent work.

**Key Principle**: "Contracts are the source of truth. Code must conform to contracts, not the other way around."

---

## Contract Types

### 1. API Contracts (HTTP)

**Location**: `contracts/api/vX.Y.Z/openapi.yaml`

**Format**: OpenAPI 3.1 specification

**Purpose**: Define REST API endpoints, request/response schemas, authentication, error handling

**Examples**:
- `GET /api/users/:id` → Returns User schema
- `POST /api/features` → Accepts Feature schema, returns Feature schema
- `DELETE /api/features/:slug` → Returns 204 No Content

### 2. Event Contracts (Webhooks)

**Location**: `contracts/events/webhook-schemas/*.json`

**Format**: JSON Schema Draft 7+

**Purpose**: Define outbound webhook payloads sent to external systems

**Examples**:
- `feature.shipped` event → Sent when feature deployed to production
- `deployment.complete` event → Sent when deployment finishes
- `contract.violated` event → Sent when CDC test fails

**Security**: All webhooks signed with HMAC-SHA256 (see Webhook Security section)

### 3. Consumer-Driven Contracts (CDC)

**Location**: `contracts/pacts/*.json`

**Format**: Pact JSON format

**Purpose**: Define consumer expectations for provider behavior

**Examples**:
- `frontend-backend.json` → Frontend expects backend endpoints
- `webhook-consumer.json` → External system expects webhook schema
- `epic-a-epic-b.json` → Epic A depends on Epic B's API

---

## Versioning Rules

### Semantic Versioning

Follow [semver](https://semver.org/):

**MAJOR (X.0.0)** - Breaking changes:
- Remove endpoints
- Remove required fields from responses
- Change field types (string → integer)
- Rename fields or endpoints
- Change authentication mechanism

**MINOR (X.Y.0)** - Additive changes (backward-compatible):
- Add new endpoints
- Add optional fields to requests/responses
- Add new query parameters (optional)
- Add new event types

**PATCH (X.Y.Z)** - Documentation/examples only:
- Fix typos in descriptions
- Update examples
- Clarify documentation
- Add response code examples

### Mid-Sprint Change Policy

**Allowed mid-sprint**:
- ✅ Minor bumps (additive changes)
- ✅ Patch bumps (documentation)

**Blocked mid-sprint**:
- ❌ Major bumps (breaking changes)
- **Exception**: Major bumps allowed with RFC approval

**Rationale**: Breaking changes mid-sprint break parallel epic development. Epics build against locked contracts.

### RFC Process for Breaking Changes

**When required**: Major version bump mid-sprint

**Steps**:
1. Create RFC issue: `/roadmap ADD "RFC: Breaking contract change - [description]" --type rfc`
2. Document rationale, migration path, affected consumers
3. Get approval from tech lead (apply `rfc:approved` label)
4. Run `/contract.bump major --rfc ISSUE_NUMBER`

**Example RFC**:

```markdown
# RFC: Remove 'email' field from User schema

## Rationale
PII compliance - storing emails in User object violates data retention policy.

## Breaking Change
- Field removed: `User.email` (string)
- Affected endpoints: GET /api/users/:id, POST /api/users

## Migration Path
1. Consumers using `User.email` switch to `User.contact.email`
2. Add `contact.email` as optional field (minor bump)
3. Deprecate `email` field in v1.1.0
4. Remove `email` field in v2.0.0 (next sprint)

## Consumers Affected
- Frontend epic (UI displays email)
- Webhook consumers (external CRM)

## Timeline
- v1.1.0: Add `contact.email` (this sprint)
- v2.0.0: Remove `email` (Sprint 6)
```

---

## Contract Lifecycle

### 1. Contract Creation

**When**: Before epic parallelization

**Who**: Platform agent

**Process**:
```bash
# 1. Define API contracts in OpenAPI
vim contracts/api/v1.0.0/openapi.yaml

# 2. Define event schemas
vim contracts/events/webhook-schemas/feature-shipped.json

# 3. Generate golden fixtures
/fixture.refresh

# 4. Publish for epic agents
git add contracts/
git commit -m "feat(contracts): initial API contract v1.0.0"
```

**Output**: Locked contracts ready for epic agents

### 2. Contract Locking (Epic Gate)

**When**: Before parallel implementation starts

**Who**: Platform agent via `/contracts` command

**Process**:
```bash
# 1. Review contracts
cat contracts/api/v1.0.0/openapi.yaml

# 2. Verify no violations
/contract.verify

# 3. Lock contracts (block changes until sprint ends)
# Mark epic state: Planned → Contracts-Locked
```

**Gate**: Epics can only start implementing after contracts locked and verified

### 3. Contract Evolution (Mid-Sprint)

**Allowed**: Additive changes only

**Process**:
```bash
# 1. Platform agent bumps version
/contract.bump minor

# 2. Automatic steps:
#    - Creates contracts/api/v1.1.0/
#    - Updates openapi.yaml: version 1.1.0
#    - Adds CHANGELOG entry
#    - Runs /contract.verify (blocks if violations)
#    - Creates PR with contract changes

# 3. Epic agents update dependencies
npm install @app/sdk@1.1.0
```

**Example**: Add optional `epic` field to Feature schema

### 4. Contract Breaking (Next Sprint)

**Required**: Major version bump + RFC

**Process**:
```bash
# 1. Create RFC (Sprint 5)
/roadmap ADD "RFC: Remove deprecated field" --type rfc
# Get approval: rfc:approved label

# 2. Bump major version (Sprint 6)
/contract.bump major --rfc 123

# 3. Update consumers
# Frontend, backend, external systems migrate to v2.0.0

# 4. Deploy v2.0.0
/ship
```

**Deprecation Policy**: Deprecated fields remain for 2 major versions before removal

---

## Consumer-Driven Contract (CDC) Testing

### What is CDC?

**Problem without CDC**:
- Provider changes API
- Consumers break in production
- Discovered too late (QA or post-deploy)

**Solution with CDC**:
- Consumer defines expectations (pact)
- Provider verifies against pact in CI
- Breaking changes caught before merge

### Workflow

**Consumer side** (e.g., Frontend epic):

```javascript
// Define expected API behavior (pact)
const pact = {
  consumer: { name: "frontend-epic-ui" },
  provider: { name: "backend-epic-api" },
  interactions: [
    {
      description: "get user by ID",
      request: {
        method: "GET",
        path: "/api/users/123"
      },
      response: {
        status: 200,
        body: {
          id: "123",
          email: "user@example.com"
        }
      }
    }
  ]
};

// Publish pact
publishPact(pact, "contracts/pacts/frontend-backend.json");
```

**Provider side** (e.g., Backend epic):

```bash
# CI runs on every PR
/contract.verify

# Verifies backend implementation matches frontend's pact
# If backend removes 'email' field → verification fails → PR blocked
```

**Benefit**: Frontend and backend can develop in parallel. CI catches integration issues immediately.

### Pact Publishing

**When**: After consumer implements API integration

**Where**: `contracts/pacts/consumer-provider.json`

**Format**:

```json
{
  "consumer": { "name": "frontend-epic-ui" },
  "provider": { "name": "backend-epic-api" },
  "interactions": [...],
  "metadata": {
    "pactSpecification": { "version": "2.0.0" },
    "created": "2025-11-10T14:30:00Z"
  }
}
```

**Optional**: Publish to Pact Broker for centralized management

---

## Webhook Security

### HMAC-SHA256 Signing

**All webhooks must be signed** to prevent tampering.

**Signing (Provider)**:

```javascript
const crypto = require('crypto');

function signWebhook(payload, secretKey) {
  const signature = crypto
    .createHmac('sha256', secretKey)
    .update(JSON.stringify(payload))
    .digest('hex');

  return signature;
}

// Add to webhook headers
headers['X-Webhook-Signature'] = signWebhook(payload, SECRET_KEY);
```

**Verification (Consumer)**:

```javascript
function verifyWebhook(payload, signature, secretKey) {
  const expectedSig = crypto
    .createHmac('sha256', secretKey)
    .update(JSON.stringify(payload))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSig)
  );
}

if (!verifyWebhook(req.body, req.headers['x-webhook-signature'], SECRET_KEY)) {
  throw new Error('Invalid webhook signature');
}
```

**Key Management**: Platform agent owns secret key generation and rotation

---

## Commands Reference

### `/contract.bump [major|minor|patch]`

**Purpose**: Bump contract version

**Usage**:
```bash
/contract.bump minor  # Additive changes
/contract.bump major --rfc 123  # Breaking changes (requires RFC)
/contract.bump patch  # Documentation only
```

**Behavior**:
- Creates new version directory
- Updates openapi.yaml version
- Adds CHANGELOG entry
- Runs `/contract.verify`
- Creates PR if verification passes

**Blocks**:
- Major bumps mid-sprint without RFC
- Any bumps if CDC verification fails

### `/contract.verify`

**Purpose**: Run CDC tests

**Usage**:
```bash
/contract.verify  # All pacts
/contract.verify --consumer frontend-epic-ui  # Specific consumer
/contract.verify --verbose  # Detailed output
```

**Behavior**:
- Discovers pacts in `contracts/pacts/`
- Starts provider services
- Verifies each pact
- Reports violations

**Blocks**:
- Merges if any pact violated
- Contract bumps if verification fails

### `/fixture.refresh`

**Purpose**: Regenerate golden fixtures from schemas

**Usage**:
```bash
/fixture.refresh  # All versions
/fixture.refresh --path contracts/api/v1.2.0  # Specific version
/fixture.refresh --verify  # Run CDC tests after
```

**Behavior**:
- Parses OpenAPI schemas
- Generates realistic examples
- Writes to `examples/` directory
- Optionally verifies with CDC tests

---

## CI/CD Integration

### GitHub Actions Workflow

**Location**: `.github/workflows/contract-verification.yml`

**Triggers**:
- Pull requests modifying `contracts/**`
- Pull requests modifying `src/**` or `api/**`

**Jobs**:
1. **verify-contracts**: Run `/contract.verify`
2. **check-fixture-freshness**: Warn if fixtures older than schemas
3. **publish-pacts**: Publish to Pact Broker (if configured)

**Branch Protection**:
- Require "Contract Verification" check to pass
- Block merge if contracts violated

### Pre-Merge Checklist

Before merging contract changes:

- [ ] `/contract.verify` passes (all pacts verified)
- [ ] CHANGELOG updated with changes
- [ ] Golden fixtures refreshed (`/fixture.refresh`)
- [ ] Breaking changes documented (if major bump)
- [ ] RFC approved (if major bump mid-sprint)
- [ ] Consumers notified (if breaking change)

---

## Epic Parallelization Integration

### How Contracts Enable Parallel Epics

**Scenario**: ACS Sync program with 5 epics

**Without contracts**:
- Epics step on each other's toes
- Integration issues discovered at end (big bang)
- Rework required

**With contracts**:
- Platform agent locks contracts upfront
- Each epic implements against locked contract
- CDC tests catch integration issues immediately
- Epics work independently

### Epic State Machine Gate

**Epic States**:
```
Planned → Contracts-Locked → Implementing → Review → Integrated → Released
          ↑ GATE
```

**Gate requirement**: `/contract.verify` must pass

**Epics cannot start implementing until**:
1. Contracts defined (OpenAPI + JSON Schema)
2. Pacts published (expected behaviors)
3. CDC verification passes (no violations)

### Example: Five Parallel Epics

**Platform agent setup**:

```bash
# 1. Define contracts for all epics
/contract.bump minor  # v1.1.0

# 2. Add endpoints for each epic:
#    Epic A: POST /documents/sync
#    Epic B: GET /documents/:id
#    Epic C: POST /diff/compute
#    Epic D: PUT /crosswalk/update
#    Epic E: POST /webhooks/deliver

# 3. Generate SDK
npm run generate:sdk  # Creates @app/sdk@1.1.0

# 4. Lock contracts
# Mark all epics: Planned → Contracts-Locked
```

**Epic agents implement**:

```bash
# Epic A agent (backend-dev)
npm install @app/sdk@1.1.0  # Use locked contract
# Implement POST /documents/sync
# Publish pact (expected behavior)

# Epic B agent (backend-dev)
# Implement GET /documents/:id
# Publish pact

# (etc. for Epic C, D, E)
```

**Platform agent verifies**:

```bash
# On every PR from epic agents
/contract.verify

# Ensures:
# - Epic A's implementation matches its pact ✅
# - Epic B's implementation matches its pact ✅
# - No epic breaks another epic's pact ✅
```

**Result**: Epics ship independently without breaking each other.

---

## Troubleshooting

### Contract Verification Fails

**Symptom**:
```
❌ Contract verification failed

Violation: frontend-backend.json
  Expected: { "email": "user@example.com" }
  Actual:   { "email": null }
```

**Diagnosis**:
- Provider removed or changed required field
- Consumer expects field that provider no longer provides

**Fix**:
```bash
# Option 1: Add field back to provider
# Update backend to include 'email' in response

# Option 2: Update consumer pact
# Coordinate with frontend to update expectations

# Option 3: Breaking change (next sprint)
# Create RFC for major version bump
```

### Fixture Validation Fails

**Symptom**:
```
❌ Validation failed: auth-login-response.json

Error: Missing required property 'token'
```

**Diagnosis**:
- Generated fixture doesn't match schema
- Schema has required fields but no examples

**Fix**:
```bash
# Add inline examples to schema
yq eval '.components.schemas.LoginResponse.properties.token.example = "eyJ..."' -i openapi.yaml

# Regenerate fixtures
/fixture.refresh
```

### Stale Fixtures

**Symptom**:
```
⚠️ Fixture older than schema - run /fixture.refresh

Stale fixtures:
- auth-login-response.json (schema modified 2 days ago)
```

**Fix**:
```bash
/fixture.refresh --verify
```

**Prevention**: CI checks fixture freshness automatically

---

## Best Practices

### 1. Lock Contracts Early

Lock contracts before parallelizing epics. Don't let epics start until contracts are stable.

### 2. Use Inline Examples

Add `example` fields to OpenAPI properties for realistic fixture generation:

```yaml
properties:
  email:
    type: string
    format: email
    example: user@example.com  # ← Inline example
```

### 3. Publish Pacts Early

Epic agents should publish pacts as soon as they integrate with provider APIs.

### 4. Run CDC on Every PR

CI must verify contracts on every PR. Don't skip verification.

### 5. Version SDKs with Contracts

When contract bumps, regenerate and publish SDK:

```bash
/contract.bump minor
npm run generate:sdk
npm publish @app/sdk
```

### 6. Document Breaking Changes

Use CHANGELOG and migration guides for major bumps.

### 7. Rotate Webhook Keys

Platform agent should rotate HMAC keys quarterly.

---

## Platform Agent Responsibilities

The **platform agent** owns:

1. **Contract lifecycle**: Creation, versioning, locking
2. **CDC verification**: Run `/contract.verify` on every PR
3. **SDK generation**: Regenerate when contracts change
4. **Webhook security**: Signing, key management
5. **Epic coordination**: Lock contracts, notify epic agents
6. **Quality gates**: Block merges if contracts violated

**Handoffs**:
- **To epic agents**: "Contracts locked - implement per contract"
- **From epic agents**: "Pact published - verify against it"

---

## References

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [JSON Schema](https://json-schema.org/)
- [Pact Documentation](https://docs.pact.io/)
- [Semantic Versioning](https://semver.org/)
- [Consumer-Driven Contracts (Martin Fowler)](https://martinfowler.com/articles/consumerDrivenContracts.html)
- `.claude/agents/implementation/platform.md` - Platform agent brief
- `contracts/README.md` - Contracts directory overview
- `.claude/commands/contract-bump.md` - Version bumping command
- `.claude/commands/contract-verify.md` - CDC verification command

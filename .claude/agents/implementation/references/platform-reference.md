# Platform Agent Reference Documentation

## Purpose

This document provides comprehensive procedures, patterns, and workflows for the Platform Agent (Complicated-Subsystem Team pattern from Team Topologies). The platform agent owns shared infrastructure, contracts, CI/CD gates, and cross-cutting concerns so stream-aligned epic agents stay focused on vertical slices.

---

## 1. Contract Governance

### Ownership

**Owned assets**:
- API contracts (OpenAPI specs in `contracts/api/`)
- Event contracts (JSON Schemas in `contracts/events/`)
- Consumer-driven contracts (Pacts in `contracts/pacts/`)
- Contract versioning and CHANGELOG maintenance

### Contract Bump Procedure

**When to execute**: When schemas change (new endpoints, new fields, schema modifications)

**Command**: `/contract.bump [major|minor|patch]`

**Workflow**:
1. **Read current contract version** from `contracts/api/openapi.yaml` (or equivalent)
2. **Apply requested schema changes** (add endpoint, modify response schema, etc.)
3. **Detect breaking changes** by comparing old vs new schema
4. **Determine version bump type**:
   - MAJOR: Breaking changes (removed fields, changed types, removed endpoints)
   - MINOR: Backward-compatible additions (new endpoints, new optional fields)
   - PATCH: Documentation/bug fixes only
5. **Update contract version** in schema files
6. **Update CHANGELOG.md** with version and changes
7. **Regenerate SDKs** from updated contracts (see SDK Generation section)
8. **Run contract verification** to ensure all pacts still satisfied
9. **Commit changes** with conventional commit message

**Gating rules**:
- Block major bumps mid-sprint without RFC approval
- Block contract bumps if CDC (Consumer-Driven Contract) tests fail
- Require epic agents to publish pacts before parallel implementation
- Only additive changes allowed mid-sprint (MINOR/PATCH only)

### Contract Verification Procedure

**When to execute**: On every PR before merge, after contract changes

**Command**: `/contract.verify`

**Workflow**:
1. **Locate all pact files** in `contracts/pacts/`
2. **Run Pact verification** against provider implementations
3. **For each pact**:
   - Load pact expectations (consumer-defined)
   - Send requests to provider endpoint
   - Compare actual response with expected response
   - Report violations (missing fields, wrong types, status codes)
4. **Generate verification report**:
   - Total pacts verified
   - Pass/fail count
   - Specific violations with examples
5. **Exit with failure** if any pact violated (blocks merge)

**Success criteria**:
- All pacts pass verification (100%)
- No unexpected fields in responses (strict validation)
- Status codes match expectations
- Response times within SLO (<200ms for 95th percentile)

### Backward Compatibility Strategy

**Rules**:
- **Always allowed**: Add optional fields, add new endpoints, add new enum values (with default handling)
- **Requires migration**: Remove fields (deprecation period required), change field types, change endpoint paths
- **Blocked mid-sprint**: Breaking changes without deprecation period

**Deprecation workflow**:
1. Mark field/endpoint as deprecated in OpenAPI spec
2. Add `X-Deprecated` header to responses
3. Notify consumers via changelog
4. Maintain deprecated feature for minimum 90 days
5. After deprecation period: Remove in next MAJOR version

---

## 2. CI/CD Pipeline Ownership

### Owned Workflows

**Pipeline files**:
- `.github/workflows/contract-verification.yml` - Runs on every PR
- `.github/workflows/gates.yml` - Quality gates (CI, security)
- `.github/workflows/deploy-staging.yml` - Staging deployments
- `.github/workflows/deploy-production.yml` - Production deployments

### CI Gate Procedure (`/gate.ci`)

**When to execute**: Pre-merge quality gate (automatic on every PR)

**Workflow**:
1. **Run tests**:
   - Unit tests (`npm test` or equivalent)
   - Integration tests
   - Contract tests (pact verification)
2. **Run linters**:
   - ESLint/TSLint for TypeScript
   - Prettier for formatting
   - TypeScript type checking
3. **Check coverage**:
   - Minimum 80% line coverage
   - Minimum 70% branch coverage
   - Report coverage delta vs main branch
4. **Build validation**:
   - Ensure project builds without errors
   - Check bundle size (warn if >10% increase)
5. **Generate report**:
   - Test results (pass/fail counts)
   - Coverage metrics
   - Linter violations
   - Build status

**Blocking conditions**:
- Any test failures
- Coverage below minimum thresholds
- Build failures
- Critical linter violations

### Security Gate Procedure (`/gate.sec`)

**When to execute**: Pre-merge security gate (automatic on every PR)

**Workflow**:
1. **SAST (Static Application Security Testing)**:
   - Run Semgrep or equivalent
   - Scan for OWASP Top 10 vulnerabilities
   - Check for hardcoded secrets
2. **Dependency scanning**:
   - Run `npm audit` or `yarn audit`
   - Check for known CVEs in dependencies
   - Report vulnerable packages with severity
3. **Secret detection**:
   - Scan for API keys, tokens, passwords
   - Check `.env` files not committed
   - Verify secrets in environment variables only
4. **License compliance**:
   - Verify all dependencies use compatible licenses
   - Block GPL/AGPL in proprietary projects
5. **Generate report**:
   - Critical/high/medium/low vulnerabilities
   - Secret exposure incidents
   - License violations

**Blocking conditions**:
- Critical vulnerabilities found
- Secrets detected in committed code
- High-severity CVEs with available patches
- License violations

### Branch Protection Configuration

**Required settings** (configured via GitHub API or UI):
- Require status checks to pass before merging:
  - CI gate (tests, linters, coverage)
  - Security gate (SAST, dependencies)
  - Contract verification
- Require pull request reviews (minimum 1)
- Require branches to be up to date before merging
- Block force pushes to main
- Block deletions of main branch

**Trunk-based development enforcement**:
- Alert when branch >18h old
- Block merge when branch >24h old
- Recommend feature flags for incomplete work

---

## 3. Shared SDK & Code Generation

### SDK Generation Procedure

**When to execute**: After contract version bump

**Workflow**:
1. **Detect contract changes**:
   - Check if `contracts/api/openapi.yaml` modified
   - Extract new version number
2. **Generate TypeScript SDK**:
   - Run `openapi-generator-cli generate -i contracts/api/openapi.yaml -g typescript-fetch -o sdk/typescript/`
   - Validate generated code compiles
   - Run linters on generated code
3. **Generate Python SDK** (if applicable):
   - Run `openapi-generator-cli generate -i contracts/api/openapi.yaml -g python -o sdk/python/`
   - Validate with `mypy`
4. **Version SDK packages**:
   - Update `sdk/typescript/package.json` version to match contract version
   - Update `sdk/python/setup.py` version to match contract version
5. **Publish SDK packages**:
   - TypeScript: `npm publish` to internal registry or public npm
   - Python: `python setup.py sdist bdist_wheel && twine upload dist/*`
6. **Notify epic agents**:
   - Create GitHub issue: "SDK @1.2.0 available with new endpoints"
   - Tag epic agents that depend on changed endpoints

**Example automation script**:
```bash
#!/bin/bash
# .spec-flow/scripts/bash/generate-sdk.sh

CONTRACT_VERSION=$(yq eval '.info.version' contracts/api/openapi.yaml)

# Generate TypeScript SDK
openapi-generator-cli generate \
  -i contracts/api/openapi.yaml \
  -g typescript-fetch \
  -o sdk/typescript/

# Update version
cd sdk/typescript
npm version "$CONTRACT_VERSION" --no-git-tag-version

# Publish
npm publish --access public

echo "✅ SDK @$CONTRACT_VERSION published"
```

### Type Safety Maintenance

**Ensure**:
- Generated SDKs match contract exactly
- No manual edits to generated code
- TypeScript strict mode enabled
- Pydantic models for Python SDKs

**Validation**:
- Run TypeScript type checker on generated code
- Run mypy on Python SDK
- Compare generated types with contract schemas

---

## 4. Webhook Infrastructure

### Webhook Signing Implementation

**Purpose**: Prevent webhook payload tampering and ensure authenticity

**Implementation** (Node.js example):
```javascript
const crypto = require('crypto');

function signWebhook(payload, secret) {
  const signature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');

  return signature;
}

// When sending webhook
const payload = { event: 'user.created', data: { id: 123 } };
const signature = signWebhook(payload, process.env.WEBHOOK_SECRET);

await fetch(webhookUrl, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Webhook-Signature': signature,
    'X-Webhook-Timestamp': Date.now().toString(),
  },
  body: JSON.stringify(payload),
});
```

**Consumer verification**:
```javascript
function verifyWebhook(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// In webhook receiver
const signature = req.headers['x-webhook-signature'];
const isValid = verifyWebhook(req.body, signature, process.env.WEBHOOK_SECRET);

if (!isValid) {
  return res.status(401).json({ error: 'Invalid signature' });
}
```

### Webhook Payload Schema Management

**Maintain schemas** in `contracts/events/`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "event": {
      "type": "string",
      "enum": ["user.created", "user.updated", "user.deleted"]
    },
    "data": {
      "type": "object",
      "properties": {
        "id": { "type": "integer" },
        "email": { "type": "string", "format": "email" },
        "name": { "type": "string" }
      },
      "required": ["id", "email"]
    },
    "timestamp": { "type": "string", "format": "date-time" }
  },
  "required": ["event", "data", "timestamp"]
}
```

**Validation**:
- Validate outgoing webhooks against schema
- Publish schemas for consumers
- Version schemas alongside contract versions

### Webhook Delivery Retry Logic

**Implementation pattern**:
```javascript
async function deliverWebhook(url, payload, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Signature': signWebhook(payload, SECRET),
          'X-Webhook-Attempt': attempt.toString(),
        },
        body: JSON.stringify(payload),
        timeout: 5000, // 5 second timeout
      });

      if (response.ok) {
        await logWebhookSuccess(url, payload);
        return { success: true, attempt };
      }

      if (response.status >= 500) {
        // Retry on server errors
        await sleep(Math.pow(2, attempt) * 1000); // Exponential backoff
        continue;
      }

      // Don't retry on 4xx errors
      await logWebhookFailure(url, payload, response.status);
      return { success: false, attempt, status: response.status };
    } catch (error) {
      if (attempt === retries) {
        await logWebhookFailure(url, payload, error.message);
        return { success: false, attempt, error: error.message };
      }
      await sleep(Math.pow(2, attempt) * 1000);
    }
  }
}
```

**Monitoring**:
- Track delivery success rate (target: >95%)
- Alert on repeated failures to same endpoint
- Log all webhook attempts with payload IDs

---

## 5. Feature Flag Management (Support)

### Flag Registry Maintenance

**Registry location**: `.spec-flow/memory/feature-flags.yaml`

**Schema**:
```yaml
flags:
  - name: new-dashboard
    description: Enable redesigned dashboard UI
    created: 2025-11-15
    expires: 2025-11-30
    owner: epic-dashboard
    environments:
      - development: true
      - staging: true
      - production: false
    justification: Incomplete work - awaiting UX review

  - name: experimental-ai
    description: Enable AI-powered recommendations
    created: 2025-11-10
    expires: 2025-11-25
    owner: epic-ai-features
    environments:
      - development: true
      - staging: false
      - production: false
    justification: R&D phase - not ready for users
```

### Flag Expiry Linter

**CI integration**:
```bash
#!/bin/bash
# .spec-flow/scripts/bash/flag-expiry-linter.sh

FLAGS_FILE=".spec-flow/memory/feature-flags.yaml"
TODAY=$(date +%s)

WARNINGS=0
ERRORS=0

while IFS= read -r flag; do
  NAME=$(echo "$flag" | yq eval '.name' -)
  EXPIRES=$(echo "$flag" | yq eval '.expires' -)
  EXPIRES_TS=$(date -d "$EXPIRES" +%s)

  DAYS_UNTIL_EXPIRY=$(( (EXPIRES_TS - TODAY) / 86400 ))

  if [ "$DAYS_UNTIL_EXPIRY" -lt -14 ]; then
    echo "❌ ERROR: Flag '$NAME' expired >14 days ago (expires: $EXPIRES)"
    ERRORS=$((ERRORS + 1))
  elif [ "$DAYS_UNTIL_EXPIRY" -lt -7 ]; then
    echo "⚠️ WARNING: Flag '$NAME' expired >7 days ago (expires: $EXPIRES)"
    WARNINGS=$((WARNINGS + 1))
  fi
done < <(yq eval '.flags[]' "$FLAGS_FILE" -o=json -I=0)

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "🚫 BLOCKED: $ERRORS flag(s) expired >14 days ago"
  echo "Run /flag.cleanup to remove expired flags"
  exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "⚠️ WARNING: $WARNINGS flag(s) expired >7 days ago"
  echo "Consider running /flag.cleanup"
fi

exit 0
```

**Gating rules**:
- **Warn** when flag >7 days past expiry (non-blocking)
- **Block** when flag >14 days past expiry (prevents technical debt accumulation)

### Epic Agent Responsibilities

Epic agents use platform-provided commands:
- **Add flag**: `/flag.add --name=new-feature --expires=2025-12-01 --reason="Incomplete work"`
- **Cleanup flag**: `/flag.cleanup --name=new-feature` (removes from code and registry)

Platform agent provides:
- Flag registry maintenance
- Expiry linting in CI
- Alerting for expired flags
- Cleanup scripts

---

## 6. Deployment Quota & Rate Limiting

### Quota Tracking Procedure

**Command**: `/deployment-budget`

**Data sources**:
- Vercel API: `GET /v9/deployments?limit=100&since=<timestamp>`
- Railway API: `GET /projects/:id/deployments`
- Platform-specific metrics endpoints

**Workflow**:
1. **Fetch deployment history** for current billing period
2. **Count deployments** by type:
   - Staging deployments
   - Production deployments
   - Preview deployments
3. **Calculate quota usage**:
   - Current: 18 deployments
   - Limit: 20 deployments (free tier)
   - Usage: 90%
4. **Generate alert** if usage >80%
5. **Recommend mitigation strategies**:
   - Batch small PRs to reduce staging deploys
   - Use `/build-local` for validation before `/ship-staging`
   - Upgrade to paid tier if sustained high usage

**Alert format**:
```
⚠️ Deployment Quota Warning

Platform: Vercel
Period: November 2025
Current: 18/20 deployments (90%)
Reset: 2025-12-01 (10 days)

Breakdown:
- Staging: 12 deploys
- Production: 4 deploys
- Preview: 2 deploys

Recommendation:
- Batch 2-3 small PRs before deploying
- Use /build-local for pre-flight validation
- Consider upgrading to Pro tier ($20/mo for 100 deploys)

Next deployment will consume: 95% quota
```

### Rate Limiting Strategy

**Implement progressive backoff**:
1. 80-89% usage: Warning (non-blocking)
2. 90-94% usage: Require confirmation before deploy
3. 95-99% usage: Recommend batching PRs
4. 100% usage: Block deployment, require upgrade or wait for reset

---

## 7. Shared Infrastructure

### Database Connection Pooling

**Configuration** (example with PostgreSQL):
```javascript
// config/database.js
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,

  // Platform-managed pool settings
  max: 20, // Maximum connections
  min: 5,  // Minimum connections
  idleTimeoutMillis: 30000, // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Fail fast if no connection available
});

// Export singleton
module.exports = pool;
```

**Epic agents use**:
```javascript
const pool = require('./config/database');

async function getUser(id) {
  const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  return result.rows[0];
}
```

### Secrets Management

**Platform responsibilities**:
- Rotate secrets every 90 days
- Store secrets in environment variables (never in code)
- Provide secrets access documentation

**Epic agent requirements**:
- Never commit secrets to git
- Use `process.env.SECRET_NAME` to access secrets
- Request new secrets via platform agent

**Secret rotation workflow**:
1. **Generate new secret** (API key, database password, etc.)
2. **Update environment variables** in deployment platform (Vercel, Railway, etc.)
3. **Deploy with new secret** (zero-downtime: old and new both valid briefly)
4. **Verify new secret works** in production
5. **Revoke old secret** after verification period (24-48h)
6. **Document rotation** in changelog

### Logging and Monitoring Setup

**Platform provides** (example with Winston):
```javascript
// config/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'api' },
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

module.exports = logger;
```

**Epic agents use**:
```javascript
const logger = require('./config/logger');

logger.info('User created', { userId: 123 });
logger.error('Database connection failed', { error: err.message });
```

### Error Tracking Setup

**Platform configures** (example with Sentry):
```javascript
// config/sentry.js
const Sentry = require('@sentry/node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1, // 10% of transactions
});

// Express middleware
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());

module.exports = Sentry;
```

**Epic agents benefit**:
- Automatic error capture
- Stack traces with source maps
- Error grouping and deduplication
- Alerting on error rate spikes

---

## 8. Epic Parallelization Support

### Contract Locking Procedure

**When to execute**: Before sprint starts with parallel epics

**Workflow**:
1. **Define all API contracts** for upcoming epics
2. **Generate SDKs** from contracts
3. **Lock contracts** (prevent changes mid-sprint)
4. **Publish pacts** (expected behaviors)
5. **Notify epic agents**: "Contracts locked - implement per contract"

**Example scenario: Five Epics in Parallel**:

**Setup phase**:
```bash
# Platform agent defines contracts for all 5 epics
/contract.bump minor  # Creates contracts/api/v1.1.0

# Adds endpoints:
# - POST /documents/sync (Epic A: Fetcher)
# - GET /documents/:id (Epic B: Parser)
# - POST /diff/compute (Epic C: Diff)
# - POST /documents/export (Epic D: Exporter)
# - GET /analytics/summary (Epic E: Analytics)

# Generate SDK
npm run generate:sdk  # Creates @app/sdk@1.1.0

# Publish pacts (expectations)
# Epic A expects: POST /documents/sync returns { id, status }
# Epic B expects: GET /documents/:id returns { id, content, metadata }
# Epic C expects: POST /diff/compute returns { changes: [] }
# etc.

# Lock contracts
echo "Contracts locked for Sprint 5" > contracts/LOCKED
```

**Implementation phase**:
Epic agents work independently:
- Epic A: Implements POST /documents/sync using locked contract
- Epic B: Implements GET /documents/:id using locked contract
- Epic C: Implements POST /diff/compute using locked contract

**Verification**:
On every PR from epic agents:
```bash
/contract.verify

# Ensures:
# - Epic A's implementation matches pact (correct response shape)
# - Epic B's implementation matches pact
# - Epic C's implementation matches pact
# - No contract drift
```

**Benefit**: No epic breaks another epic. CI catches violations before merge.

---

## 9. Communication Patterns

### Epic Agents → Platform Agent

**Request patterns**:

1. **"Need new API endpoint for feature X"**
   - Platform adds endpoint to OpenAPI spec
   - Runs `/contract.bump minor`
   - Regenerates SDK
   - Notifies: "SDK @1.2.0 ready with new endpoint"

2. **"Webhook payload missing field Y"**
   - Platform updates JSON Schema
   - Runs `/contract.verify` (ensure no consumer breaks)
   - Notifies consumers of schema change

3. **"CI pipeline broken"**
   - Platform debugs CI workflow
   - Fixes broken step
   - Notifies: "CI restored - rerun your PR"

### Platform Agent → Epic Agents

**Broadcast patterns**:

1. **"Contract locked for Sprint 5 - no changes until sprint ends"**
   - Epic agents implement using locked contracts
   - No breaking changes allowed mid-sprint

2. **"Your branch >24h old - merge or use feature flag"**
   - Epic agent either:
     - Merges incomplete work behind feature flag
     - Completes work and merges

3. **"Epic B, your pact expects field 'epic' but schema doesn't include it"**
   - Epic B either:
     - Updates pact to remove field
     - Requests platform to add field to contract

---

## 10. Metrics & SLOs

### Contract Health Metrics

**Tracked**:
- CDC verification pass rate: Target >95%
- Contract drift incidents: Target <1 per sprint
- Breaking changes mid-sprint: Target 0 (enforced by gates)

**Calculation**:
```bash
# CDC pass rate
TOTAL_PACTS=$(find contracts/pacts -name "*.json" | wc -l)
PASSED_PACTS=$(npm test -- --grep "pact verification" | grep -c "passing")
PASS_RATE=$(echo "scale=2; $PASSED_PACTS / $TOTAL_PACTS * 100" | bc)

echo "CDC Pass Rate: $PASS_RATE%"

if (( $(echo "$PASS_RATE < 95" | bc -l) )); then
  echo "⚠️ Below 95% target"
fi
```

### CI/CD Health Metrics

**Tracked**:
- Pipeline uptime: Target >99%
- Average CI run time: Target <5 minutes
- Flaky test rate: Target <5%

**Calculation**:
```bash
# Flaky test rate (tests that pass on retry)
TOTAL_TEST_RUNS=$(gh run list --workflow=ci.yml --limit=100 --json conclusion | jq 'length')
FLAKY_RUNS=$(gh run list --workflow=ci.yml --limit=100 --json conclusion,runNumber | jq '[.[] | select(.conclusion == "success")] | length')
FLAKY_RATE=$(echo "scale=2; ($TOTAL_TEST_RUNS - $FLAKY_RUNS) / $TOTAL_TEST_RUNS * 100" | bc)

echo "Flaky Test Rate: $FLAKY_RATE%"
```

### Deployment Health Metrics

**Tracked**:
- Deployment success rate: Target >95%
- Quota utilization: Target <80% of limit
- Rollback rate: Target <10%

**Calculation**:
```bash
# Deployment success rate
TOTAL_DEPLOYS=$(gh run list --workflow=deploy-production.yml --limit=50 --json conclusion | jq 'length')
SUCCESS_DEPLOYS=$(gh run list --workflow=deploy-production.yml --limit=50 --json conclusion | jq '[.[] | select(.conclusion == "success")] | length')
SUCCESS_RATE=$(echo "scale=2; $SUCCESS_DEPLOYS / $TOTAL_DEPLOYS * 100" | bc)

echo "Deployment Success Rate: $SUCCESS_RATE%"
```

### Branch Health Metrics

**Tracked**:
- Branch lifetime (avg): Target <18h
- Branches >24h old: Target 0 (enforced by gates)
- Feature flag debt: Target 0 expired flags >7 days

---

## 11. Anti-Patterns (What Platform Does NOT Do)

### ❌ Don't Implement Business Logic

**Wrong**:
```javascript
// platform.md implementing user creation logic
async function createUser(data) {
  // Business validation
  if (data.age < 18) throw new Error('Must be 18+');

  // Business logic
  const user = await db.insert('users', data);
  await sendWelcomeEmail(user);

  return user;
}
```

**Right**:
```javascript
// Platform provides infrastructure only
const pool = require('./config/database'); // Platform-provided
const logger = require('./config/logger');   // Platform-provided

// Epic agent implements business logic
async function createUser(data) {
  if (data.age < 18) throw new Error('Must be 18+');

  const user = await pool.query('INSERT INTO users ...', [data]);
  await sendWelcomeEmail(user);
  logger.info('User created', { userId: user.id });

  return user;
}
```

**Principle**: Platform owns infrastructure (database pool, logger, config). Epic agents own vertical slices (API + DB + UI for specific features).

### ❌ Don't Block Epic Agents Unnecessarily

**Wrong**:
```bash
# Blocking on minor issues
if [ "$COVERAGE" -lt 85 ]; then
  echo "❌ BLOCKED: Coverage must be exactly 85%"
  exit 1
fi
```

**Right**:
```bash
# Warn before hard blocks
if [ "$COVERAGE" -lt 80 ]; then
  echo "❌ BLOCKED: Coverage below minimum (80%)"
  exit 1
elif [ "$COVERAGE" -lt 85 ]; then
  echo "⚠️ WARNING: Coverage below target (85%)"
  echo "Consider adding tests, but not blocking merge"
fi
```

**Principle**: Use warnings before hard blocks. Provide clear fix instructions.

### ❌ Don't Allow Shared Mutable State Between Epics

**Wrong**:
```javascript
// Shared global cache modified by multiple epics
const sharedCache = {};

// Epic A
sharedCache.users = await fetchUsers();

// Epic B (accidentally overwrites Epic A's data)
sharedCache.users = await fetchDifferentUsers();
```

**Right**:
```javascript
// Each epic has isolated context
// Epic A
const epicACache = {};
epicACache.users = await fetchUsers();

// Epic B
const epicBCache = {};
epicBCache.users = await fetchDifferentUsers();

// Or use namespaced keys
const sharedCache = new Map();
sharedCache.set('epic-a:users', await fetchUsers());
sharedCache.set('epic-b:users', await fetchDifferentUsers());
```

**Principle**: Shared state goes through contracts only (API calls, events). No direct mutable shared memory.

---

## 12. Onboarding New Epic Agents

### Onboarding Checklist

**When new epic agent joins sprint**:

1. **Provide contracts**:
   - Share `contracts/api/vX.Y.Z/openapi.yaml`
   - Share generated SDK package: `@app/sdk@X.Y.Z`
   - Share event schemas: `contracts/events/*.json`

2. **Explain constraints**:
   - "Contracts are locked - no breaking changes mid-sprint"
   - "Only MINOR/PATCH bumps allowed (additive only)"
   - "Branches must merge within 24h (use feature flags for incomplete work)"
   - "All PRs require gates to pass (CI, security, contracts)"

3. **Request pact**:
   - "Publish pact for your epic's expected API behavior"
   - "We'll verify your implementation matches your pact on every PR"
   - "Use `/contract.verify` locally before pushing"

4. **Monitor progress**:
   - Track epic agent's WIP (work in progress)
   - Alert if branch aging (>18h warning, >24h block)
   - Alert if gates failing repeatedly

**Example onboarding message**:
```
Welcome to Sprint 5, Epic Agent "Document Parser"!

📋 Your Contract Package:
- API: contracts/api/v1.1.0/openapi.yaml
- SDK: @app/sdk@1.1.0 (install: npm install @app/sdk@1.1.0)
- Events: contracts/events/document.schema.json

⚠️ Constraints:
- Contracts locked until sprint ends (Nov 30)
- Branches must merge within 24h
- All PRs require gates to pass

📝 Next Steps:
1. Publish your pact: Define expected API behavior
2. Implement using SDK: Type-safe API calls
3. Verify locally: Run /contract.verify
4. Push PR: CI will verify contract compliance

Questions? Tag @platform-agent
```

---

## 13. Tools & Scripts Reference

### Contract Management Scripts

**Location**: `.spec-flow/scripts/bash/`

**Scripts**:
- `contract-bump.sh [major|minor|patch]` - Bump contract version
- `contract-verify.sh` - Verify all pacts
- `fixture-refresh.sh` - Regenerate test fixtures from contracts

### CI/CD Scripts

**Location**: `.spec-flow/scripts/bash/` and `.github/workflows/`

**Scripts**:
- `gate-ci.sh` - Run CI quality gates
- `gate-sec.sh` - Run security gates
- `.github/workflows/contract-verification.yml` - Auto-run on PR
- `.github/workflows/gates.yml` - Combined CI/security gates

### Monitoring Scripts

**Location**: `.spec-flow/scripts/bash/`

**Scripts**:
- `dora-tracker.sh` - Calculate DORA metrics
- `deployment-budget.sh` - Check quota usage

---

## 14. Integration with Other Agents

### Backend Dev Agent

**Platform provides**:
- API contracts (OpenAPI) - Single source of truth
- Database schemas - Migration framework
- CI/CD pipelines - Quality gates

**Backend implements**:
- Business logic
- API endpoints per contract
- Database queries

### Frontend Shipper Agent

**Platform provides**:
- Generated TypeScript SDK
- API contracts (for reference)
- Type definitions

**Frontend uses**:
- SDK for type-safe API calls
- Publishes pacts (expected API behavior)

### Database Architect Agent

**Platform provides**:
- Migration framework
- Schema validation tools
- Rollback testing infrastructure

**Database implements**:
- Migrations (forward-only)
- Query optimization
- Index strategy

### QA Tester Agent

**Platform provides**:
- CDC tests (contract verification)
- CI gates (quality checks)
- Test infrastructure

**QA adds**:
- End-to-end tests
- Integration tests
- Manual test plans

---

## 15. References

- [Team Topologies](https://teamtopologies.com/key-concepts) - Platform as Complicated-Subsystem Team
- [Pact Documentation](https://docs.pact.io/) - Consumer-Driven Contracts
- [Trunk-Based Development](https://trunkbaseddevelopment.com/) - Branch lifetime limits
- [DORA Metrics](https://dora.dev/research/) - Deployment frequency, lead time, change failure rate
- `contracts/README.md` - Contract governance guide (project-specific)
- `.claude/agents/implementation/backend.md` - Backend epic agent
- `.claude/agents/implementation/frontend.md` - Frontend epic agent

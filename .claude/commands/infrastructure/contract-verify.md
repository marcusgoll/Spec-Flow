# /contract.verify - Consumer-Driven Contract Verification

**Purpose**: Verify all consumer-driven contracts (pacts) to ensure providers don't break consumers. Blocks merges if any pact is violated.

**Usage**:
```bash
/contract.verify [--consumer NAME] [--provider NAME] [--verbose]
```

**Parameters**:
- `--consumer NAME`: Verify specific consumer's pacts only
- `--provider NAME`: Verify specific provider only
- `--verbose`: Show detailed verification output

**Prerequisites**:
- Contracts directory exists (`contracts/`)
- Pacts published in `contracts/pacts/`
- Provider implementations available (APIs running locally or in test mode)

**Blocks**:
- **Merge if verification fails**: Any pact violation blocks PR merge
- **Contract bumps**: Cannot bump contract if verification fails

---

## What is CDC Verification?

**Consumer-Driven Contract (CDC) testing** ensures that API providers honor the contracts expected by consumers.

**Traditional testing problem**:
- Provider changes API
- Consumers break in production
- Discovered too late

**CDC solution**:
- Consumer defines expectations (pact)
- Provider verifies against pact in CI
- Breaking changes caught before merge

---

## Workflow Steps

### 1. Discover Pacts

Scan `contracts/pacts/` directory for all published pacts.

```bash
contracts/pacts/
├── frontend-backend.json       # Frontend expects backend behavior
├── webhook-consumer.json       # External webhook consumer
└── epic-a-epic-b.json          # Epic A depends on Epic B
```

### 2. Parse Pact Metadata

Extract consumer/provider names and interactions:

```json
{
  "consumer": { "name": "frontend-epic-ui" },
  "provider": { "name": "backend-epic-api" },
  "interactions": [
    {
      "description": "get user by ID",
      "request": {
        "method": "GET",
        "path": "/api/users/123"
      },
      "response": {
        "status": 200,
        "body": {
          "id": "123",
          "email": "user@example.com"
        }
      }
    }
  ]
}
```

### 3. Start Provider (If Local)

For local providers, start test server:

```bash
# Start provider in test mode
npm run test:api &
PROVIDER_PID=$!

# Wait for health check
curl --retry 10 --retry-delay 1 http://localhost:3000/health
```

### 4. Run Pact Verification

Use Pact Verifier or compatible tool:

**Option A: Pact CLI**

```bash
pact-provider-verifier \
  --provider-base-url=http://localhost:3000 \
  --pact-urls=contracts/pacts/frontend-backend.json \
  --provider-app-version=$(git rev-parse HEAD) \
  --verbose
```

**Option B: Language-Specific Pact Libraries**

```javascript
// Node.js example
const { Verifier } = require('@pact-foundation/pact');

const verifier = new Verifier({
  provider: 'backend-epic-api',
  providerBaseUrl: 'http://localhost:3000',
  pactUrls: ['contracts/pacts/frontend-backend.json'],
  publishVerificationResult: true,
});

verifier.verifyProvider().then(() => {
  console.log('Pact verification successful');
});
```

**Option C: cURL-based Simple Verification (Fallback)**

If Pact tooling unavailable, use simple HTTP verification:

```bash
# For each interaction in pact
curl -X GET http://localhost:3000/api/users/123 \
  -H "Authorization: Bearer test-token" \
  | jq -e '.email == "user@example.com"'
```

### 5. Collect Results

Track verification results per pact:

```yaml
verification_results:
  - pact: frontend-backend.json
    consumer: frontend-epic-ui
    provider: backend-epic-api
    status: passed
    interactions_tested: 5
    interactions_failed: 0

  - pact: webhook-consumer.json
    consumer: external-system
    provider: webhook-service
    status: failed
    interactions_tested: 3
    interactions_failed: 1
    failures:
      - interaction: "receive feature.shipped webhook"
        error: "Expected field 'epic' in payload, but not found"
        expected: { "epic": "epic:auth" }
        actual: { "epic": null }
```

### 6. Stop Provider

Clean up test server:

```bash
kill $PROVIDER_PID
```

### 7. Report Results

**All Passed**:

```
✅ Contract verification passed

Verified 3 pacts:
  ✅ frontend-backend (5 interactions)
  ✅ webhook-consumer (3 interactions)
  ✅ epic-a-epic-b (2 interactions)

Total: 10 interactions tested, 0 failures
```

**Failures Detected**:

```
❌ Contract verification failed

Verified 3 pacts:
  ✅ frontend-backend (5 interactions)
  ❌ webhook-consumer (3 interactions, 1 failed)
  ✅ epic-a-epic-b (2 interactions)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Violation: webhook-consumer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Interaction: "receive feature.shipped webhook"

Expected:
  {
    "event_type": "feature.shipped",
    "data": {
      "epic": "epic:auth"  ← MISSING
    }
  }

Actual:
  {
    "event_type": "feature.shipped",
    "data": {
      "epic": null
    }
  }

Fix:
  1. Add 'epic' field to webhook payload schema
  2. Update contracts/events/webhook-schemas/feature-shipped.json
  3. Re-run /contract.verify

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total: 10 interactions tested, 1 failure

Run '/contract.verify --verbose' for detailed logs.
```

---

## Integration with Workflow

### Epic State Machine Gate

Epics can only transition to `Contracts-Locked` state after `/contract.verify` passes.

**State Transition**:

```
Planned → Contracts-Locked (requires /contract.verify ✅)
```

### Pre-Merge Gate

**GitHub Actions**: `.github/workflows/contract-verification.yml`

```yaml
name: Contract Verification

on:
  pull_request:
    paths:
      - 'contracts/**'
      - 'src/**'

jobs:
  verify-contracts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: npm install

      - name: Start provider
        run: npm run test:api &

      - name: Verify contracts
        run: .spec-flow/scripts/bash/contract-verify.sh

      - name: Block merge if failed
        if: failure()
        run: |
          echo "❌ Contract verification failed - blocking merge"
          exit 1
```

**Branch Protection**: Require "Contract Verification" check to pass.

### Integration with /contract.bump

`/contract.bump` calls `/contract.verify` automatically:

```bash
/contract.bump minor
  → Create new version
  → Update schemas
  → Run /contract.verify  ← Automatic
  → Block if verification fails
```

---

## Error Handling

### No Pacts Found

```
⚠️ No pacts found in contracts/pacts/

This means no consumers have published expectations yet.

Actions:
  1. If consumers exist, ask them to publish pacts
  2. If no consumers yet, skip verification (no contracts to break)
  3. Once consumers publish pacts, re-run /contract.verify
```

### Provider Not Running

```
❌ Cannot connect to provider: backend-epic-api

Tried: http://localhost:3000/health

Fix:
  1. Start provider: npm run test:api
  2. Verify health endpoint responds
  3. Re-run /contract.verify
```

### Pact Format Invalid

```
❌ Invalid pact format: contracts/pacts/malformed.json

Error: Missing required field 'consumer.name'

Fix:
  1. Validate pact structure
  2. Ensure pact follows Pact specification
  3. Use Pact libraries to generate pacts (recommended)

Reference: https://docs.pact.io/
```

---

## Implementation Details

### Script Location

**Bash**: `.spec-flow/scripts/bash/contract-verify.sh`
**PowerShell**: `.spec-flow/scripts/powershell/contract-verify.ps1`

### Functions Required

```bash
# Discover all pacts in contracts/pacts/
discover_pacts() {
  find contracts/pacts -name '*.json' -type f
}

# Parse consumer/provider from pact
parse_pact_metadata() {
  local pact_file=$1
  jq -r '.consumer.name, .provider.name' "$pact_file"
}

# Start provider in test mode
start_provider() {
  local provider_name=$1
  # Infer start command based on provider
  # e.g., npm run test:api for backend-epic-api
}

# Verify single pact
verify_pact() {
  local pact_file=$1
  local provider_url=$2

  if command -v pact-provider-verifier &> /dev/null; then
    # Use Pact CLI
    pact-provider-verifier \
      --provider-base-url="$provider_url" \
      --pact-urls="$pact_file"
  else
    # Fallback: Simple HTTP verification
    verify_pact_simple "$pact_file" "$provider_url"
  fi
}

# Simple verification (no Pact CLI)
verify_pact_simple() {
  local pact_file=$1
  local provider_url=$2

  # Extract interactions
  local interactions=$(jq -c '.interactions[]' "$pact_file")

  # Test each interaction
  while IFS= read -r interaction; do
    local method=$(echo "$interaction" | jq -r '.request.method')
    local path=$(echo "$interaction" | jq -r '.request.path')
    local expected_status=$(echo "$interaction" | jq -r '.response.status')

    # Make request
    local actual_status=$(curl -s -o /dev/null -w "%{http_code}" \
      -X "$method" "$provider_url$path")

    if [[ "$actual_status" != "$expected_status" ]]; then
      echo "FAIL: Expected $expected_status, got $actual_status"
      return 1
    fi
  done <<< "$interactions"
}

# Stop provider
stop_provider() {
  local pid=$1
  kill "$pid" 2>/dev/null || true
}

# Format verification results
format_results() {
  local total=$1
  local failed=$2

  if [[ $failed -eq 0 ]]; then
    log_success "Contract verification passed"
    log_success "Total: $total interactions tested, 0 failures"
  else
    log_error "Contract verification failed"
    log_error "Total: $total interactions tested, $failed failures"
    return 1
  fi
}
```

### Dependencies

- **jq**: JSON parsing
- **curl**: HTTP requests
- **pact-provider-verifier** (optional): Pact CLI tool
- **@pact-foundation/pact** (optional): Node.js Pact library

**Fallback**: If Pact tooling unavailable, use simple HTTP verification.

---

## Advanced Features

### Provider States

Some interactions require specific provider state:

```json
{
  "description": "get user by ID",
  "providerState": "user 123 exists",
  "request": {
    "method": "GET",
    "path": "/api/users/123"
  }
}
```

**Setup**: Provider must support state setup endpoint:

```bash
# Before verification, set provider state
curl -X POST http://localhost:3000/_pact/provider-states \
  -d '{"state": "user 123 exists"}'
```

### Pact Broker Integration

**For teams**, publish pacts to Pact Broker:

```bash
# Consumer publishes pact
pact-broker publish contracts/pacts/ \
  --consumer-app-version=$(git rev-parse HEAD) \
  --broker-base-url=$PACT_BROKER_URL

# Provider verifies from broker
pact-provider-verifier \
  --provider-base-url=http://localhost:3000 \
  --pact-broker-url=$PACT_BROKER_URL \
  --provider=backend-epic-api
```

**Benefit**: Centralized pact storage, versioning, and notifications.

---

## Examples

### Example 1: Verify All Pacts

```bash
/contract.verify

# Output:
✅ Contract verification passed

Verified 3 pacts:
  ✅ frontend-backend (5 interactions)
  ✅ webhook-consumer (3 interactions)
  ✅ epic-a-epic-b (2 interactions)

Total: 10 interactions tested, 0 failures
```

### Example 2: Verify Specific Consumer

```bash
/contract.verify --consumer frontend-epic-ui

# Output:
✅ Contract verification passed

Verified 1 pact:
  ✅ frontend-backend (5 interactions)

Total: 5 interactions tested, 0 failures
```

### Example 3: Verification Failure

```bash
/contract.verify

# Output:
❌ Contract verification failed

Violation: frontend-backend
  Interaction: "get user by ID"
  Expected: { "email": "user@example.com" }
  Actual:   { "email": null }

Fix: Add 'email' field to User schema in openapi.yaml

Total: 10 interactions tested, 1 failure
```

### Example 4: Verbose Output

```bash
/contract.verify --verbose

# Output:
ℹ Discovered 3 pacts in contracts/pacts/
ℹ Starting provider: backend-epic-api (http://localhost:3000)
ℹ Verifying pact: frontend-backend.json
  ✅ GET /api/users/123 → 200
  ✅ POST /api/users → 201
  ✅ DELETE /api/users/123 → 204
ℹ Verifying pact: webhook-consumer.json
  ✅ POST /webhooks/test → 200
ℹ Stopping provider (PID: 12345)

✅ Contract verification passed
Total: 10 interactions tested, 0 failures
```

---

## References

- [Pact Documentation](https://docs.pact.io/)
- [Consumer-Driven Contracts (Martin Fowler)](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Pact CLI](https://github.com/pact-foundation/pact-ruby-standalone/releases)
- [Pact Broker](https://github.com/pact-foundation/pact_broker)
- `contracts/pacts/README.md` - Pact structure and examples
- `/contract.bump` - Version bumping with CDC verification

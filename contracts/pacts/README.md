# Consumer-Driven Contract (CDC) Pacts

Published consumer contracts for CDC testing using Pact or compatible frameworks.

## What is CDC Testing?

**Consumer-Driven Contract (CDC) testing** ensures API providers don't break consumers by verifying against expected behavior defined by consumers.

**Flow**:

1. **Consumer** defines expectations (pact)
2. **Consumer** publishes pact to broker/repo
3. **Provider** verifies against pact in CI
4. **Merge blocked** if provider violates pact

## Why CDC?

**Without CDC**: Provider changes API → consumers break in production

**With CDC**: Provider CI fails → breaking change caught before merge

**Benefit**: Safe parallel development of epics (backend and frontend can evolve independently)

## Directory Structure

```
pacts/
├── frontend-backend.json         # Frontend expects backend behavior
├── webhook-consumer.json         # External consumer expects webhook schema
└── epic-a-epic-b.json            # Epic A depends on Epic B's API
```

## Pact Example

**Consumer**: Frontend epic
**Provider**: Backend API epic

`frontend-backend.json`:

```json
{
  "consumer": {
    "name": "frontend-epic-ui"
  },
  "provider": {
    "name": "backend-epic-api"
  },
  "interactions": [
    {
      "description": "get user by ID",
      "request": {
        "method": "GET",
        "path": "/api/users/123",
        "headers": {
          "Authorization": "Bearer token"
        }
      },
      "response": {
        "status": 200,
        "headers": {
          "Content-Type": "application/json"
        },
        "body": {
          "id": "123",
          "email": "user@example.com",
          "role": "student"
        }
      }
    }
  ],
  "metadata": {
    "pactSpecification": {
      "version": "2.0.0"
    }
  }
}
```

## Publishing Pacts

**When**: After consumer epic implements API integration

**How**: Use Pact CLI or CI integration

```bash
# Publish pact to broker (or commit to repo)
pact-broker publish pacts/ \
  --consumer-app-version=$GIT_SHA \
  --branch=$BRANCH_NAME \
  --broker-base-url=$PACT_BROKER_URL
```

## Verifying Pacts (Provider)

**When**: Every provider build/PR

**How**: Provider runs verification tests

```bash
# Verify provider against published pacts
pact-provider-verifier \
  --provider-base-url=http://localhost:3000 \
  --pact-urls=contracts/pacts/ \
  --provider-app-version=$GIT_SHA
```

**Result**: CI fails if provider doesn't match consumer expectations

## Breaking Change Detection

**Scenario**: Backend removes required field `email` from `/api/users/:id`

**Without CDC**:
- Backend merges change
- Frontend breaks in production
- Discovered during QA or after deploy

**With CDC**:
- Backend CI runs pact verification
- Pact expects `email` field
- Verification fails → PR blocked
- Breaking change caught before merge

## Epic Parallelization Use Case

**Problem**: Epic A (frontend) and Epic B (backend) work in parallel. How to ensure API compatibility?

**Solution**:

1. **Lock contracts** with `/contracts` (defines expected API)
2. Epic A publishes pact (expected behavior)
3. Epic B implements provider
4. Epic B CI verifies against Epic A's pact
5. **Merge blocked** if Epic B violates Epic A's expectations

**Benefit**: Agents work independently, CI enforces compatibility

## Commands

```bash
# Verify all pacts (provider-side)
/contract.verify

# Run after contract bump
/contract.bump minor
/contract.verify  # Ensures no pacts broken
```

## Tools

**Recommended**:
- [Pact](https://pact.io/) - Most popular CDC framework
- [Pactflow](https://pactflow.io/) - Hosted pact broker
- [Pact Broker](https://github.com/pact-foundation/pact_broker) - Self-hosted

**Alternatives**:
- [Spring Cloud Contract](https://spring.io/projects/spring-cloud-contract) (JVM)
- [Dredd](https://dredd.org/) (OpenAPI-based)

## Platform Agent Responsibility

The **platform agent** owns:
- Pact broker setup/maintenance
- Provider verification in CI
- Breaking change alerts
- Pact versioning and lifecycle

## Integration with Workflow

### Epic State Machine Gate

Epics can only transition to `Contracts-Locked` state after:
1. Contracts defined (OpenAPI + JSON Schema)
2. Expected pacts published (consumers define expectations)
3. `/contract.verify` passes (no existing pacts violated)

### Parallel Implementation Safety

With CDC:
- Agents work on epics independently
- CI catches integration issues immediately
- No "big bang" integration at end of sprint

## References

- [Pact Documentation](https://docs.pact.io/)
- [Consumer-Driven Contracts: A Service Evolution Pattern](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Pactflow Best Practices](https://docs.pactflow.io/docs/workshops/)

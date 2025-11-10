# Contract Governance

This directory contains versioned API contracts, event schemas, and consumer-driven contract (CDC) pacts for the Spec-Flow workflow system.

## Philosophy

**Contract-first development**: Lock API schemas and event contracts before parallelizing epic implementation. This prevents breaking changes mid-sprint and enables independent agent work.

## Directory Structure

```
contracts/
├── api/                    # HTTP API contracts (OpenAPI)
│   ├── v1.0.0/
│   │   ├── openapi.yaml    # OpenAPI 3.1 specification
│   │   ├── CHANGELOG.md    # Semantic versioning changelog
│   │   └── examples/       # Golden request/response fixtures
│   └── v1.1.0/             # Next version (additive changes only)
├── events/                 # Event/webhook contracts (JSON Schema)
│   ├── webhook-schemas/    # Outbound webhook payloads
│   └── message-queue/      # Message queue event schemas
└── pacts/                  # Published consumer contracts (Pact)
```

## Versioning Rules

### Mid-Sprint Changes (Additive Only)

- **Minor/Patch bumps**: Add new fields, endpoints, or events
- **Backward-compatible**: Existing consumers must not break
- **Examples**: Add optional field, add new endpoint, add event type

### Breaking Changes (Require New Sprint)

- **Major version bump**: Remove fields, change types, rename endpoints
- **Requires RFC**: Document rationale and migration path
- **Examples**: Remove required field, change field type, delete endpoint

## Commands

### Bump Contract Version

```bash
/contract.bump [major|minor|patch]
```

Updates OpenAPI and JSON Schema versions, regenerates CHANGELOG.md, runs CDC verification.

### Verify Contracts

```bash
/contract.verify
```

Runs consumer-driven contract (CDC) tests. Blocks merge if any pact is violated.

### Refresh Fixtures

```bash
/fixture.refresh
```

Regenerates golden JSON fixtures from schemas, replays through CDC tests.

## Workflow Integration

### 1. Lock Contracts (Before Parallelization)

```bash
/contracts  # Review and approve schemas
```

### 2. Epic State Transition

Epics can only move to `Contracts-Locked` state after `/contract.verify` passes.

### 3. Parallel Implementation

Agents receive locked contracts + golden fixtures. No contract changes allowed until all epics complete.

### 4. Contract Evolution

After sprint, breaking changes allowed via RFC + major version bump.

## CDC Testing (Pact)

**Consumer-driven contracts** ensure providers don't break consumers.

**Flow**:
1. Consumer publishes pact (expected API behavior)
2. Provider verifies against pact in CI
3. Merge blocked if verification fails

**Tools**: Pact, Pactflow, or compatible CDC framework

## Webhook Signing

All webhooks must be signed with HMAC-SHA256 to prevent tampering.

**Platform agent** responsibility: Generate keys, sign payloads, publish schemas.

## References

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [JSON Schema](https://json-schema.org/)
- [Pact Documentation](https://docs.pact.io/)
- [Semantic Versioning](https://semver.org/)

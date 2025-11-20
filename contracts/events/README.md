# Event Contracts (JSON Schema)

Event and webhook payload schemas using JSON Schema Draft 7+.

## Structure

```
events/
├── webhook-schemas/     # Outbound webhook payloads
│   ├── feature-shipped.json
│   ├── deployment-complete.json
│   └── contract-violated.json
└── message-queue/       # Message queue event schemas
    ├── epic-started.json
    ├── task-completed.json
    └── gate-failed.json
```

## Webhook Schemas

**Purpose**: Define payload structure for outbound webhooks sent to external systems.

**Security**: All webhooks must be signed with HMAC-SHA256.

**Example**: `webhook-schemas/feature-shipped.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Feature Shipped Event",
  "type": "object",
  "required": ["event_type", "timestamp", "data"],
  "properties": {
    "event_type": {
      "const": "feature.shipped",
      "description": "Event identifier"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp"
    },
    "data": {
      "type": "object",
      "required": ["slug", "version", "environment"],
      "properties": {
        "slug": { "type": "string", "description": "Feature slug" },
        "version": { "type": "string", "description": "Semantic version" },
        "environment": { "enum": ["staging", "production"] }
      }
    }
  }
}
```

## Message Queue Schemas

**Purpose**: Define event structure for internal message queues (e.g., agent coordination).

**Example**: `message-queue/epic-started.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Epic Started Event",
  "type": "object",
  "required": ["epic_id", "agent", "contracts_locked"],
  "properties": {
    "epic_id": { "type": "string" },
    "agent": { "enum": ["backend-dev", "frontend-dev", "database-architect"] },
    "contracts_locked": { "type": "boolean" }
  }
}
```

## Versioning

**Breaking changes** to event schemas require major version bump:

- Removing required fields
- Changing field types
- Renaming fields

**Additive changes** are safe:

- Adding optional fields
- Adding new event types

## Webhook Signing (Platform Agent)

**HMAC-SHA256 signing** prevents payload tampering.

**Implementation** (platform agent responsibility):

```javascript
const signature = crypto
  .createHmac("sha256", SECRET_KEY)
  .update(JSON.stringify(payload))
  .digest("hex");

// Include in webhook header
headers["X-Webhook-Signature"] = signature;
```

**Verification** (consumer side):

```javascript
const expectedSig = crypto
  .createHmac("sha256", SECRET_KEY)
  .update(rawBody)
  .digest("hex");

if (signature !== expectedSig) {
  throw new Error("Invalid webhook signature");
}
```

## CDC Testing

Event consumers can publish pacts expecting specific event structures. Providers verify they emit compliant events.

## Commands

```bash
# Validate all event schemas
/contract.verify

# Refresh event examples
/fixture.refresh
```

## Platform Agent Responsibility

The **platform agent** owns:

- Webhook signing key management
- Event schema versioning
- Breaking change detection
- Consumer notification for schema updates

## References

- [JSON Schema](https://json-schema.org/)
- [Webhook Security Best Practices](https://webhooks.fyi/security)
- [CloudEvents Specification](https://cloudevents.io/) (optional standard)

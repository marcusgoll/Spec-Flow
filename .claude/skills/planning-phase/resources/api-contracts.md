# API Contracts

**Purpose**: Define API endpoints with request/response schemas before implementation.

---

## Endpoint Design

### REST Pattern

```
GET    /api/v1/students           # List
POST   /api/v1/students           # Create
GET    /api/v1/students/{id}      # Read
PUT    /api/v1/students/{id}      # Update
DELETE /api/v1/students/{id}      # Delete
```

### Request Schema

```json
{
  "name": "string (required, 2-100 chars)",
  "email": "string (required, valid email)",
  "age": "number (optional, 13-120)"
}
```

### Response Schema

```json
{
  "id": "number",
  "name": "string",
  "email": "string",
  "age": "number | null",
  "createdAt": "ISO8601 datetime"
}
```

---

## Error Handling

**RFC 7807 Problem Details**:
```json
{
  "type": "/errors/validation-error",
  "title": "Validation Failed",
  "status": 400,
  "detail": "Email must be valid",
  "instance": "/api/v1/students"
}
```

**See [../reference.md](../reference.md#api-contracts) for complete OpenAPI examples**

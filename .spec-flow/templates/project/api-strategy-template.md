# API Strategy

**Last Updated**: [DATE]
**Related Docs**: See `system-architecture.md` for API architecture, `tech-stack.md` for framework choice

## API Style

**Choice**: [REST | GraphQL | tRPC | gRPC]
**Rationale**: [Why chosen]

**Example**:
**Choice**: REST over HTTPS
**Rationale**:
- Simple, universally understood
- Good for CRUD operations (students, lessons, progress)
- HTTP caching works out of box
- Easy to test (curl, Postman)
- No need for GraphQL complexity (no deep nesting, over-fetching not a problem)

---

## API Categories

### Category 1: [Category Name]

**Purpose**: [What these endpoints do]
**Base Path**: `/api/v1/[category]`
**Authentication**: [Required | Public]
**Example Endpoints**:
- `GET /api/v1/[resource]` - List resources
- `POST /api/v1/[resource]` - Create resource
- `GET /api/v1/[resource]/{id}` - Get single resource
- `PUT /api/v1/[resource]/{id}` - Update resource
- `DELETE /api/v1/[resource]/{id}` - Delete resource

**Example**:

### Category: Student Management

**Purpose**: CRUD operations for students
**Base Path**: `/api/v1/students`
**Authentication**: Required (JWT Bearer token)
**Authorization**: Instructors can only access their own students

**Endpoints**:
- `GET /api/v1/students` - List instructor's students
  - Query params: `?limit=20&offset=0&sort_by=created_at`
  - Returns: `{ data: Student[], total: number, has_more: boolean }`

- `POST /api/v1/students` - Create new student
  - Body: `{ name, email, certificate_type }`
  - Returns: `{ id, name, email, ... }`

- `GET /api/v1/students/{id}` - Get student details
  - Returns: `{ id, name, email, progress: {...}, recent_lessons: [...] }`

- `PUT /api/v1/students/{id}` - Update student
  - Body: Partial student object
  - Returns: Updated student

- `DELETE /api/v1/students/{id}` - Soft-delete student
  - Returns: `{ success: true }`

---

## Versioning Strategy

**Approach**: [URL | Header | Query param]
**Current Version**: [v1 | v2]
**Migration Policy**: [How long old versions supported]

**Example**:
**Approach**: URL-based (`/api/v1/`, `/api/v2/`)
**Current Version**: v1
**Migration Policy**:
- Maintain backward compatibility within major version (v1.x)
- Support old version for 6 months after new version released
- Breaking changes = new major version
- Deprecation warnings in response headers: `Deprecation: true`, `Sunset: 2026-01-01`

**When to Bump Version**:
- ✅ Breaking change: Remove field, change data type, change auth
- ✅ Breaking change: Change error response format
- ❌ Non-breaking: Add optional field, add new endpoint

---

## Authentication

**Method**: [JWT | Session | API Key | OAuth2]
**Provider**: [Self-hosted | Third-party]
**Token Lifetime**: [Duration]

**Example**:
**Method**: JWT Bearer tokens
**Provider**: Clerk (third-party)
**Token Lifetime**: 1 hour (Clerk manages refresh)

**How it Works**:
1. User logs in via Clerk (frontend)
2. Clerk returns JWT
3. Frontend sends JWT in `Authorization: Bearer <token>` header
4. API validates JWT signature with Clerk public key
5. Extracts `user_id` and `role` from token claims
6. Checks permissions

**Token Validation**:
```python
# FastAPI middleware
async def validate_token(request: Request):
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    payload = await clerk.verify_token(token)  # Validates signature
    request.state.user_id = payload["sub"]
    request.state.role = payload["role"]
```

---

## Authorization

**Model**: [RBAC | ABAC | Custom]
**Enforcement**: [Where/how checked]

**Example**:
**Model**: Role-Based Access Control (RBAC)

**Roles**:
- `instructor`: Manage own students, lessons, progress
- `student`: View own progress (read-only)
- `admin`: Full access

**Enforcement**:
- **Endpoint level**: Decorator checks role
  ```python
  @require_role("instructor")
  async def create_student(...):
  ```

- **Resource level**: Check ownership
  ```python
  student = await db.get_student(id)
  if student.instructor_id != request.state.user_id:
      raise Forbidden()
  ```

- **Database level**: Row-Level Security (RLS) as safety net
  ```sql
  CREATE POLICY instructor_students_policy ON students
    USING (instructor_id = current_user_id());
  ```

---

## Request/Response Format

### Request Format

**Content-Type**: [application/json | multipart/form-data]
**Encoding**: [UTF-8]

**Example**:
**Content-Type**: `application/json` (default), `multipart/form-data` (file uploads)
**Encoding**: UTF-8

**Request Body Structure**:
```json
{
  "field1": "value",
  "field2": 123,
  "nested": {
    "field3": true
  }
}
```

**Validation**:
- Pydantic schemas validate all inputs
- Reject unknown fields
- Type coercion where safe (string "123" → int 123)

### Response Format

**Success Response**:
```json
{
  "data": { ... }  // or [...] for lists
}
```

**List Response** (with pagination):
```json
{
  "data": [ ... ],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

**Error Response** (RFC 7807 Problem Details):
```json
{
  "type": "https://docs.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Request body failed validation",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ],
  "request_id": "req_abc123"
}
```

---

## Pagination

**Strategy**: [Offset | Cursor | Page number]
**Default Limit**: [Number]
**Max Limit**: [Number]

**Example**:
**Strategy**: Offset-based (simple, works for < 10K records per instructor)
**Default Limit**: 20
**Max Limit**: 100

**Query Parameters**:
- `?limit=20` - Items per page
- `?offset=0` - Starting position
- `?sort_by=created_at&order=desc` - Sorting

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 40,
    "has_more": true
  }
}
```

**When to Switch**:
- At 10K+ records per instructor → cursor-based pagination (faster for deep pages)

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST (created resource) |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error, malformed request |
| 401 | Unauthorized | Missing/invalid auth token |
| 403 | Forbidden | Valid token, but insufficient permissions |
| 404 | Not Found | Resource doesn't exist or user doesn't own it |
| 409 | Conflict | Duplicate resource (e.g., email already exists) |
| 422 | Unprocessable Entity | Business logic violation |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Maintenance, DB down |

### Error Response Structure

**Format**: RFC 7807 Problem Details

**Example**:
```json
{
  "type": "https://docs.flightpro.com/errors/student-limit-exceeded",
  "title": "Student Limit Exceeded",
  "status": 422,
  "detail": "Free plan limited to 5 students. Upgrade to Pro for unlimited.",
  "instance": "/api/v1/students",
  "request_id": "req_XyZ789",
  "support_url": "https://support.flightpro.com/article/plans"
}
```

**Validation Errors** (400):
```json
{
  "type": "https://docs.flightpro.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "Request validation failed",
  "errors": [
    {
      "field": "email",
      "code": "invalid_format",
      "message": "Must be valid email"
    },
    {
      "field": "certificate_type",
      "code": "invalid_choice",
      "message": "Must be one of: private, instrument, commercial"
    }
  ],
  "request_id": "req_abc123"
}
```

---

## Rate Limiting

**Strategy**: [Per user | Per IP | Per API key]
**Limits**: [Requests per time window]
**Response**: [HTTP 429 with Retry-After]

**Example**:
**Strategy**: Per user (authenticated) or per IP (public endpoints)
**Limits**:
- Authenticated: 100 requests/minute per user
- Public (health, status): 20 requests/minute per IP

**Implementation**: Redis + sliding window

**Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 73
X-RateLimit-Reset: 1677721600
```

**429 Response**:
```json
{
  "type": "https://docs.flightpro.com/errors/rate-limit",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "Too many requests. Try again in 45 seconds.",
  "retry_after": 45
}
```

**When to Increase Limits**:
- Power users hitting limits → increase to 200/min
- Webhooks → exempt from rate limiting

---

## Caching

**Strategy**: [Server-side | Client-side | Both]
**Cache Headers**: [Cache-Control, ETag, etc.]

**Example**:
**Strategy**: Both server-side (Redis) and client-side (HTTP headers)

**Server-Side**:
- Cache student progress summaries (5 min TTL)
- Cache ACS reference data (24 hour TTL)
- Invalidate on writes

**Client-Side**:
```http
Cache-Control: public, max-age=300  // 5 minutes
ETag: "abc123xyz"
```

**Conditional Requests**:
- Client sends: `If-None-Match: "abc123xyz"`
- Server responds: `304 Not Modified` (if unchanged)

**No-Cache Endpoints**:
- Billing/payments: `Cache-Control: no-store`
- User profile: `Cache-Control: private, max-age=60`

---

## API Documentation

**Tool**: [OpenAPI/Swagger | Postman | Custom]
**Auto-Generated**: [Yes | No]
**Location**: [URL]

**Example**:
**Tool**: OpenAPI 3.0 (Swagger UI)
**Auto-Generated**: Yes (FastAPI generates from Pydantic schemas)
**Location**: `https://api.flightpro.com/docs`

**What's Documented**:
- All endpoints with request/response examples
- Authentication requirements
- Error responses
- Rate limits
- Pagination details

**Additional Docs**:
- Getting started guide: `docs/api/getting-started.md`
- Authentication tutorial: `docs/api/authentication.md`
- Postman collection: `docs/api/flightpro.postman_collection.json`

---

## Webhook Strategy

**Use Case**: [What events trigger webhooks]
**Format**: [HTTP POST with JSON]
**Security**: [Signature verification]

**Example**:
**Use Case**: Notify instructors when students complete lessons
**Format**: HTTP POST with JSON payload

**Events**:
- `lesson.completed`
- `progress.updated`
- `subscription.cancelled` (from Stripe)

**Payload**:
```json
{
  "event": "lesson.completed",
  "data": {
    "lesson_id": "uuid",
    "student_id": "uuid",
    "instructor_id": "uuid",
    "completed_at": "2025-10-24T10:30:00Z"
  },
  "webhook_id": "wh_123",
  "timestamp": 1677721600
}
```

**Security**:
- HMAC signature in `X-Webhook-Signature` header
- Instructor configures webhook URL + secret in settings
- Verify signature before processing

**Retry Logic**:
- Retry 3 times with exponential backoff (1s, 4s, 16s)
- Mark as failed after 3 attempts
- UI shows failed webhooks for manual retry

---

## CORS Policy

**Allowed Origins**: [List or wildcard]
**Allowed Methods**: [GET, POST, etc.]
**Credentials**: [Allowed | Not allowed]

**Example**:
**Allowed Origins**:
- `https://flightpro.com` (production)
- `https://*.flightpro.com` (staging/preview)
- `http://localhost:3000` (development)

**Allowed Methods**: GET, POST, PUT, DELETE, OPTIONS
**Allowed Headers**: Authorization, Content-Type
**Credentials**: Allowed (cookies, auth headers)
**Max Age**: 86400 (cache preflight for 24 hours)

**Implementation** (FastAPI):
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

---

## API Lifecycle

### Deprecation Process

1. **Announce**: [How much notice]
2. **Mark**: [Headers/docs]
3. **Support**: [How long]
4. **Sunset**: [When removed]

**Example**:
1. **Announce**: 3 months notice (blog post, email, docs banner)
2. **Mark**: Add deprecation headers
   ```http
   Deprecation: true
   Sunset: Fri, 01 Jan 2026 00:00:00 GMT
   Link: <https://docs.flightpro.com/migration/v1-to-v2>; rel="alternate"
   ```
3. **Support**: 6 months minimum
4. **Sunset**: Remove endpoint, return 410 Gone

### Breaking Changes

**What Counts as Breaking**:
- ✅ Remove endpoint
- ✅ Remove field from response
- ✅ Change field type (string → int)
- ✅ Make optional field required
- ✅ Change auth method
- ❌ Add optional field to request
- ❌ Add field to response
- ❌ Add new endpoint

**How to Handle**:
- Breaking changes → new major version (`/api/v2/`)
- Run v1 and v2 in parallel for 6 months
- Redirect users to migration guide

---

## Testing Strategy

**Unit Tests**: [What to test]
**Integration Tests**: [What to test]
**Contract Tests**: [What to test]

**Example**:
**Unit Tests**: Business logic (ACS calculations, validation rules)
**Integration Tests**: Full request → response cycle (with test DB)
**Contract Tests**: Request/response schemas match OpenAPI spec

**Tools**:
- pytest for backend tests
- Postman/Newman for API contract tests
- Playwright for E2E flows

**Coverage Target**: 80% for API code

---

## Performance Targets

**Endpoint**: [Endpoint pattern]
**Target**: [Response time]

**Example**:

| Endpoint | P50 Target | P95 Target | P99 Target |
|----------|------------|------------|------------|
| GET /students | < 100ms | < 300ms | < 500ms |
| POST /students | < 200ms | < 500ms | < 1s |
| GET /students/{id}/progress | < 200ms | < 500ms | < 1s (complex calculation) |
| POST /lessons (with progress update) | < 500ms | < 1s | < 2s |

**How Measured**: APM tool (Railway metrics), logged per request

**Violations**:
- P95 > 1s → Alert to Slack
- P99 > 2s → Investigate (slow query log)

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| [DATE] | [What] | [Why] | [Effect] |

**Example**:

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-01 | Added `X-Request-ID` header to all responses | Easier debugging, better support | No breaking change |
| 2025-09-20 | Changed error format from custom to RFC 7807 | Industry standard, better tooling | Minor breaking (v1.1 → v2.0) |
| 2025-09-10 | Added rate limiting (100 req/min) | Prevent abuse, ensure fair usage | Transparent to normal users |

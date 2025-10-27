# System Architecture

**Last Updated**: [DATE]
**Architecture Style**: [Monolith | Microservices | Serverless | Hybrid]
**Related Docs**: See `tech-stack.md` for technology choices, `deployment-strategy.md` for infrastructure

## System Context (C4 Level 1)

**High-level view: How does our system fit in the wider world?**

```mermaid
C4Context
    title System Context Diagram - [Project Name]

    Person(user, "[Primary User]", "Description")
    Person(admin, "[Admin User]", "Description")

    System(system, "[Project Name]", "Core system")

    System_Ext(auth, "[Auth Provider]", "Authentication (e.g., Clerk, Auth0)")
    System_Ext(payment, "[Payment Provider]", "Billing (e.g., Stripe)")
    System_Ext(email, "[Email Service]", "Transactional emails (e.g., SendGrid)")
    System_Ext(storage, "[Storage]", "File storage (e.g., S3, Cloudinary)")

    Rel(user, system, "Uses", "HTTPS")
    Rel(admin, system, "Manages", "HTTPS")

    Rel(system, auth, "Authenticates users", "HTTPS/API")
    Rel(system, payment, "Processes payments", "HTTPS/API")
    Rel(system, email, "Sends emails", "HTTPS/API")
    Rel(system, storage, "Stores files", "HTTPS/API")
```

**Example**:
```mermaid
C4Context
    title System Context - FlightPro

    Person(cfi, "Flight Instructor", "Tracks student progress, manages lessons")
    Person(student, "Student Pilot", "Views progress, schedules lessons")

    System(flightpro, "FlightPro Platform", "Student management and progress tracking")

    System_Ext(clerk, "Clerk", "Authentication & user management")
    System_Ext(stripe, "Stripe", "Subscription billing")
    System_Ext(vercel, "Vercel Blob", "PDF/image storage for lesson plans")
    System_Ext(posthog, "PostHog", "Analytics and feature flags")

    Rel(cfi, flightpro, "Uses", "HTTPS")
    Rel(student, flightpro, "Views", "HTTPS")
    Rel(flightpro, clerk, "Authenticates", "API")
    Rel(flightpro, stripe, "Processes subscriptions", "Webhooks")
    Rel(flightpro, vercel, "Stores files", "API")
    Rel(flightpro, posthog, "Tracks events", "API")
```

---

## Container Diagram (C4 Level 2)

**Major components and how they communicate:**

```mermaid
C4Container
    title Container Diagram - [Project Name]

    Person(user, "User", "Description")

    Container(web, "Web Application", "[Tech]", "Description")
    Container(api, "API Backend", "[Tech]", "Description")
    ContainerDb(db, "Database", "[Tech]", "Description")
    ContainerDb(cache, "Cache", "[Tech]", "Description")

    System_Ext(external, "External Service", "Description")

    Rel(user, web, "Uses", "HTTPS")
    Rel(web, api, "API calls", "HTTPS/REST")
    Rel(api, db, "Reads/Writes", "SQL")
    Rel(api, cache, "Caches data", "Redis protocol")
    Rel(api, external, "Integrates", "HTTPS/API")
```

**Example**:
```mermaid
C4Container
    title Container Diagram - FlightPro

    Person(cfi, "CFI", "Instructor")

    Container(web, "Next.js App", "TypeScript/React", "Server-rendered UI, instructor dashboard")
    Container(api, "FastAPI Backend", "Python 3.11", "Business logic, ACS calculations")
    ContainerDb(postgres, "PostgreSQL", "v15", "Users, students, lessons, progress")
    ContainerDb(redis, "Redis", "v7", "Session cache, rate limiting")
    Container(worker, "Background Jobs", "Python/Celery", "Email sending, report generation")

    System_Ext(clerk, "Clerk", "Auth")
    System_Ext(stripe, "Stripe", "Billing")

    Rel(cfi, web, "Uses", "HTTPS")
    Rel(web, api, "API calls", "REST/JSON")
    Rel(api, postgres, "Persists data", "SQL")
    Rel(api, redis, "Caches", "Redis")
    Rel(api, worker, "Enqueues jobs", "Redis queue")
    Rel(worker, postgres, "Reads/Writes", "SQL")
    Rel(web, clerk, "SSO", "OAuth2")
    Rel(api, stripe, "Webhooks", "HTTPS")
```

---

## Component Architecture

### Frontend Components

**Structure**: [Describe component organization]

**Example**:
```
apps/
├── web/                    # Marketing site
│   ├── app/                # Next.js 14 App Router
│   ├── components/         # React components
│   └── lib/                # Utilities (SWR, formatting)
│
└── app/                    # Main application
    ├── app/(authed)/       # Authenticated routes
    ├── app/(public)/       # Public routes
    ├── components/         # Shared components
    └── lib/                # Client utilities
```

**Key Components**:
- [Component 1]: [Purpose, technology, interfaces]
- [Component 2]: [Purpose, technology, interfaces]

**Example**:
- **StudentProgressDashboard**: Displays ACS-mapped progress chart, uses SWR for data fetching
- **LessonPlanner**: Drag-and-drop lesson builder, integrates with calendar
- **ComplianceReportGenerator**: PDF generation client, calls API for data

### Backend Services

**Structure**: [Describe service organization]

**Example**:
```
api/
├── src/
│   ├── modules/            # Feature modules
│   │   ├── students/       # Student management
│   │   ├── lessons/        # Lesson planning
│   │   └── progress/       # ACS progress tracking
│   ├── services/           # Shared services
│   │   ├── acs_calculator/ # Core business logic
│   │   └── pdf_generator/  # Report generation
│   └── core/               # Infrastructure (DB, auth)
```

**Key Services**:
- [Service 1]: [Purpose, dependencies, API surface]
- [Service 2]: [Purpose, dependencies, API surface]

**Example**:
- **ACSCalculatorService**: Calculates student proficiency levels, depends on progress data
- **LessonService**: CRUD for lessons, enforces business rules (min duration, required fields)
- **ProgressTrackingService**: Maps lessons to ACS standards, updates student metrics

---

## Data Flow

### Primary User Journey: [Journey Name]

```mermaid
sequenceDiagram
    actor User
    participant Web
    participant API
    participant DB
    participant External

    User->>Web: [Action]
    Web->>API: [Request]
    API->>DB: [Query]
    DB-->>API: [Data]
    API->>External: [API call]
    External-->>API: [Response]
    API-->>Web: [JSON response]
    Web-->>User: [Updated UI]
```

**Example - Student Progress Update**:
```mermaid
sequenceDiagram
    actor CFI
    participant Web as Next.js App
    participant API as FastAPI
    participant DB as PostgreSQL
    participant Cache as Redis

    CFI->>Web: Mark maneuver complete (steep turn)
    Web->>API: POST /api/v1/progress
    API->>DB: SELECT student ACS progress
    DB-->>API: Current progress data
    API->>API: Calculate new proficiency score
    API->>DB: UPDATE progress SET proficiency=0.85
    DB-->>API: Success
    API->>Cache: INVALIDATE progress:student:123
    API-->>Web: { proficiency: 0.85, weak_areas: [...] }
    Web-->>CFI: Updated progress chart
```

### Background Processes

**Job**: [Job name]
**Trigger**: [What triggers it]
**Frequency**: [How often]
**Process**: [What it does]

**Example**:
**Job**: Weekly compliance report generation
**Trigger**: Cron (every Sunday 6am UTC)
**Frequency**: Weekly
**Process**:
1. Query all students with checkrides in next 30 days
2. Calculate ACS coverage percentage
3. Generate PDF report per student
4. Email CFI with report + weak areas list
5. Log completion to DB

---

## Communication Patterns

### Frontend \u2194 Backend

**Protocol**: [REST | GraphQL | tRPC | WebSocket]
**Format**: [JSON | Protocol Buffers | etc.]
**Authentication**: [JWT | Session | API Key]

**Example**:
**Protocol**: REST over HTTPS
**Format**: JSON
**Authentication**: JWT (Bearer token from Clerk)
**Error Handling**: RFC 7807 Problem Details
**Versioning**: URL-based (/api/v1/, /api/v2/)

### Backend \u2194 External Services

**Pattern**: [Direct API calls | Webhooks | Message queue]

**Example**:
- **Stripe**: Webhook-based (receive payment events), sync API calls (create subscriptions)
- **PostHog**: Fire-and-forget event tracking (doesn't block requests)
- **Vercel Blob**: Direct upload with signed URLs (frontend uploads directly after getting URL from backend)

### Internal Services

**If microservices**: [How services communicate]

**Example** (if applicable):
**Pattern**: Event-driven via Redis Pub/Sub
**Events**:
- `student.progress.updated` → triggers weak area recalculation
- `lesson.completed` → updates student stats, sends notification
- `subscription.cancelled` → archives user data, sends offboarding email

---

## Infrastructure Diagram

```mermaid
graph TB
    subgraph Internet
        User([User Browser])
    end

    subgraph Vercel
        Web[Next.js App]
        Edge[Edge Middleware]
    end

    subgraph Railway
        API[FastAPI Container]
        Worker[Celery Worker]
    end

    subgraph Supabase
        DB[(PostgreSQL)]
        Storage[Blob Storage]
    end

    subgraph External
        Clerk[Clerk Auth]
        Stripe[Stripe API]
    end

    User -->|HTTPS| Edge
    Edge -->|Auth Check| Clerk
    Edge -->|Route| Web
    Web -->|API Calls| API
    API -->|SQL| DB
    API -->|Files| Storage
    Worker -->|SQL| DB
    API -->|Events| Worker
    API -->|Webhooks| Stripe
```

---

## Security Architecture

### Authentication Flow

```mermaid
sequenceDiagram
    actor User
    participant Web
    participant Clerk
    participant API
    participant DB

    User->>Web: Click Login
    Web->>Clerk: Redirect to Clerk auth
    Clerk-->>User: Show login form
    User->>Clerk: Submit credentials
    Clerk->>Clerk: Validate & create session
    Clerk-->>Web: Redirect with JWT
    Web->>API: Request with JWT in header
    API->>Clerk: Validate JWT signature
    Clerk-->>API: Valid (user_id, role)
    API->>DB: Check user permissions
    DB-->>API: Allowed actions
    API-->>Web: Protected resource
```

### Authorization Model

**Type**: [RBAC | ABAC | Custom]
**Roles**: [List roles]
**Enforcement**: [Where/how enforced]

**Example**:
**Type**: Role-Based Access Control (RBAC)
**Roles**:
- `instructor`: Can manage own students, lessons, progress
- `student`: Can view own progress (read-only)
- `admin`: Full system access

**Enforcement**:
- API level: Middleware checks JWT claims, enforces role-based permissions
- DB level: Row-Level Security (RLS) policies ensure users only see own data
- UI level: Components hidden/disabled based on role (not security boundary, just UX)

### Data Protection

**At Rest**:
- Database: [Encryption method]
- Files: [Encryption method]

**In Transit**:
- All connections: [TLS version]
- Cert management: [How managed]

**Example**:
**At Rest**:
- PostgreSQL: AES-256 encryption at rest (provider-managed)
- Blob storage: Encrypted by provider (Vercel)
- No local file storage

**In Transit**:
- TLS 1.3 minimum
- Certificates managed by Vercel/Railway (auto-renewal)

---

## Scalability Considerations

**Current Architecture**: [Optimized for what scale?]
**Bottlenecks**: [Known limitations]
**Scale Path**: [How to scale each component]

**Example**:
**Current Architecture**: Optimized for 100-1,000 users (micro to small)
**Bottlenecks**:
- **Database**: Single PostgreSQL instance, limited to ~1K concurrent connections
- **API**: Single Railway container, scales vertically (more RAM/CPU)
- **Background jobs**: Single Celery worker

**Scale Path**:
- **10K users**: Read replicas for PostgreSQL, horizontal API scaling (2-3 containers)
- **100K users**: Postgres sharding by instructor_id, Redis cluster, dedicated job queue service
- **1M+ users**: Microservices split (students, lessons, billing), CDN for static assets

---

## Monitoring & Observability

**Logging**: [Where logs go, format]
**Metrics**: [What metrics tracked, where]
**Tracing**: [Distributed tracing approach]
**Alerting**: [Alert conditions, channels]

**Example**:
**Logging**:
- Structured JSON logs (FastAPI → Railway logs)
- Frontend errors → PostHog
- Retention: 30 days

**Metrics**:
- API response times, error rates → Railway metrics
- User behavior → PostHog
- Business metrics → PostgreSQL queries

**Tracing**:
- Not implemented in MVP (defer to v2.0)

**Alerting**:
- Error rate >5% → PagerDuty
- API p95 >2s → Slack webhook
- Payment failures → Email

---

## Integration Points

### Third-Party Services

| Service | Purpose | Integration Type | Data Shared | Failure Mode |
|---------|---------|------------------|-------------|--------------|
| [Service] | [Why] | [How] | [What] | [Fallback] |

**Example**:

| Service | Purpose | Integration Type | Data Shared | Failure Mode |
|---------|---------|------------------|-------------|--------------|
| Clerk | Authentication | OAuth2, JWT verification | Email, user_id, role | Graceful degradation: cached JWTs valid for 1hr |
| Stripe | Billing | Webhooks + API calls | Subscription status, payment methods | Queue failed webhooks, retry; manual invoicing fallback |
| PostHog | Analytics | Client-side + server-side events | User actions, feature usage | Fire-and-forget: failures don't block user |
| Vercel Blob | File storage | Signed upload URLs | PDFs, images | S3 fallback (manual config switch) |

---

## Technology Choices Rationale

> See `tech-stack.md` for full details. This section explains *why* this architecture.

**Why [Monolith | Microservices | Serverless]?**

[Rationale based on team size, complexity, scale]

**Example**:
**Why Monolith?**:
- Team size: 1 developer (solo) → microservices overhead not justified
- Complexity: Low (CRUD + calculations) → single codebase easier to maintain
- Scale: 100-1K users (MVP) → monolith handles this easily
- **Migration path**: Modular structure allows extraction to microservices later if needed

**Why Next.js + FastAPI split?**:
- Next.js: Excellent SEO, server-side rendering, Vercel deployment simplicity
- FastAPI: Python better for ACS calculations (complex math), mature data ecosystem
- Split allows: Independent scaling (more API containers vs web), different deployment platforms

---

## Design Principles

1. **[Principle 1]**: [Description]
2. **[Principle 2]**: [Description]

**Example**:
1. **Simplicity over flexibility**: Choose boring, proven tech (PostgreSQL vs NoSQL) unless strong reason
2. **Optimize for developer experience**: Fast iteration > premature optimization
3. **Data integrity**: Use database constraints, not application logic, for invariants
4. **Fail loudly**: Errors should be obvious and trackable, not silent
5. **Modular from day one**: Even in monolith, clear boundaries enable future microservices if needed

---

## Migration Path

**From MVP → Next Scale**:

[What changes as system grows?]

**Example**:
**100 → 1,000 users**:
- Add read replica for PostgreSQL
- Enable Redis caching for frequent queries (student progress)
- Split background jobs to dedicated service
- Cost: +$50/mo

**1,000 → 10,000 users**:
- Horizontal API scaling (3-5 containers)
- PostgreSQL connection pooling (PgBouncer)
- CDN for static assets
- Cost: +$200/mo

**10,000 → 100,000 users**:
- Extract billing service (microservice)
- Postgres sharding by instructor_id
- Dedicated Redis cluster
- Cost: +$1,000/mo

---

## Decision Log

| Date | Decision | Rationale | Alternatives Rejected |
|------|----------|-----------|----------------------|
| [DATE] | [What] | [Why] | [Other options] |

**Example**:

| Date | Decision | Rationale | Alternatives Rejected |
|------|----------|-----------|----------------------|
| 2025-10-01 | Use Clerk for auth | Fast implementation, good DX, handles edge cases (MFA, social login) | Auth0 (expensive), Supabase Auth (less mature), roll-our-own (time sink) |
| 2025-09-20 | PostgreSQL over MongoDB | Relational data (students → lessons → progress), strong consistency needed | MongoDB (no strong relations), SQLite (can't scale past single server) |
| 2025-09-15 | Monolith over microservices | Team of 1, simpler deployment, faster iteration | Microservices (premature, overhead too high for MVP) |

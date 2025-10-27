# Technology Stack

**Last Updated**: [DATE]
**Related Docs**: See `system-architecture.md` for how components fit together, `deployment-strategy.md` for infrastructure

## Stack Overview

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Frontend | [Framework] | [Version] | [Purpose] |
| Backend | [Framework] | [Version] | [Purpose] |
| Database | [DB] | [Version] | [Purpose] |
| Cache | [Cache] | [Version] | [Purpose] |
| Deployment | [Platform] | [N/A] | [Purpose] |

**Example**:

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Frontend | Next.js | 14.x (App Router) | Server-rendered UI, SEO, fast iteration |
| Backend | FastAPI | 0.110.x | Python API, async support, auto-docs |
| Database | PostgreSQL | 15.x | Relational data, ACID compliance |
| Cache | Redis | 7.x | Session storage, rate limiting |
| Queue | Celery + Redis | 5.x | Background jobs (emails, reports) |
| Storage | Vercel Blob | Latest | PDF/image file storage |
| Deployment (Web) | Vercel | Latest | Zero-config Next.js hosting |
| Deployment (API) | Railway | Latest | Container hosting, auto-deploy |

---

## Frontend Stack

### Core Framework

**Choice**: [Framework]
**Version**: [Version]
**Rationale**: [Why chosen]
**Alternatives Rejected**: [What else considered]

**Example**:
**Choice**: Next.js 14 (App Router)
**Version**: 14.2.x
**Rationale**:
- Server-side rendering improves SEO (critical for marketing site)
- App Router enables React Server Components (better performance)
- Vercel deployment is seamless
- Large ecosystem, excellent docs

**Alternatives Rejected**:
- Vite + React: No SSR out of box, would need custom server
- Remix: Smaller ecosystem, less mature than Next.js
- Create React App: Deprecated, poor performance
- Vue/Nuxt: Team knows React better

### Language

**Choice**: [Language]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: TypeScript
**Version**: 5.x
**Rationale**:
- Type safety prevents runtime errors (critical for solo dev)
- Better IDE support (autocomplete, refactoring)
- Industry standard for React projects
- Easier maintenance long-term

**Alternatives Rejected**:
- JavaScript: No type safety, more bugs in production
- Flow: Facebook deprecated it, TypeScript won

### UI Framework

**Choice**: [Library]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Tailwind CSS + shadcn/ui
**Version**: Tailwind 3.x, shadcn/ui latest
**Rationale**:
- Tailwind: Utility-first, fast prototyping, small bundle size
- shadcn/ui: Copy-paste components (no npm bloat), accessible, customizable
- Combined: Rapid UI development without design skills

**Alternatives Rejected**:
- MUI: Heavy bundle size (300KB+), opinionated design
- Chakra UI: Good but heavier than Tailwind
- Bootstrap: Outdated, hard to customize
- Plain CSS: Too slow for rapid iteration

### State Management

**Choice**: [Library]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: SWR + React Context
**Version**: SWR 2.x
**Rationale**:
- SWR: Server state management, automatic revalidation, optimistic updates
- React Context: Local UI state (modals, forms), no extra lib needed
- Simple mental model: server data in SWR, UI state in Context

**Alternatives Rejected**:
- Redux: Too complex for this app, boilerplate overhead
- Zustand: Good but not needed (SWR + Context sufficient)
- TanStack Query: Similar to SWR, SWR has better Vercel integration

### Build Tool

**Choice**: [Tool]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Turbo (Vercel's bundler, built into Next.js)
**Version**: Built-in
**Rationale**:
- Zero config (comes with Next.js)
- Fast refresh, optimized builds
- No need to configure Webpack/Vite

---

## Backend Stack

### Core Framework

**Choice**: [Framework]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: FastAPI
**Version**: 0.110.x
**Rationale**:
- Async/await support (important for DB queries)
- Auto-generated OpenAPI docs (saves documentation time)
- Pydantic validation (type-safe requests/responses)
- Fast development (Python's readability)
- Good for math-heavy logic (ACS calculations)

**Alternatives Rejected**:
- Flask: No async, no auto-validation
- Django: Too heavy, includes ORM we don't need (using raw SQL)
- Express (Node.js): Python better for data/math logic
- Go: Steeper learning curve, Python ecosystem richer

### Language

**Choice**: [Language]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Python
**Version**: 3.11
**Rationale**:
- Excellent for data processing (ACS calculations)
- Rich ecosystem (pandas, numpy if needed later)
- Fast development (readable, concise)
- Good async support (asyncio)

**Alternatives Rejected**:
- TypeScript/Node.js: Good but Python better for data logic
- Go: Faster but less productive for solo dev
- Rust: Too complex, overkill for MVP

### ORM / Database Library

**Choice**: [Library]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: SQLAlchemy 2.0 (Core, not ORM) + asyncpg
**Version**: SQLAlchemy 2.0.x, asyncpg 0.29.x
**Rationale**:
- SQLAlchemy Core: SQL builder, type-safe, no ORM complexity
- asyncpg: Fastest PostgreSQL driver for Python
- Direct SQL control (important for complex queries)
- Avoids ORM pitfalls (N+1 queries, hidden joins)

**Alternatives Rejected**:
- SQLAlchemy ORM: Too much magic, prefer explicit SQL
- Django ORM: Tied to Django framework
- Raw SQL strings: No type safety, harder to maintain
- Tortoise ORM: Less mature, smaller community

### Validation

**Choice**: [Library]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Pydantic
**Version**: 2.x
**Rationale**:
- Built into FastAPI
- Runtime validation + type hints
- Auto-generates JSON schemas for API docs
- Excellent error messages

**Alternatives Rejected**:
- Marshmallow: Older, less integrated with FastAPI
- Cerberus: Less Pythonic, no type hints

### Background Jobs

**Choice**: [Library]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Celery + Redis
**Version**: Celery 5.x, Redis 7.x
**Rationale**:
- Industry standard for Python async jobs
- Redis as both broker and result backend (simple setup)
- Good for emails, PDF generation (long-running tasks)

**Alternatives Rejected**:
- RQ: Simpler but less features (no scheduled tasks)
- APScheduler: In-process only, doesn't scale
- Cloud functions: Too expensive for frequent jobs

---

## Database Stack

### Primary Database

**Choice**: [Database]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: PostgreSQL
**Version**: 15.x
**Rationale**:
- Relational data model fits perfectly (students → lessons → progress)
- ACID compliance (important for billing, progress tracking)
- JSON support (flexible for metadata without schema changes)
- Excellent performance for < 10K concurrent users
- Strong community, proven at scale

**Alternatives Rejected**:
- MySQL: Weaker JSON support, less feature-rich
- MongoDB: Relational data doesn't fit document model
- SQLite: Can't scale past single server
- DynamoDB: Overkill, expensive, vendor lock-in

### Cache Layer

**Choice**: [Cache]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Redis
**Version**: 7.x
**Rationale**:
- Fast in-memory cache (< 1ms reads)
- Also used as Celery broker (reduces services)
- Good for session storage, rate limiting
- Simple key-value model (no over-engineering)

**Alternatives Rejected**:
- Memcached: Less features than Redis (no pub/sub, no persistence)
- In-memory dict: Doesn't work across API containers
- No cache: Premature optimization, can add later if needed

### Migrations

**Choice**: [Tool]
**Version**: [Version]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Alembic
**Version**: 1.13.x
**Rationale**:
- Standard for Python + PostgreSQL
- Auto-generates migrations from SQLAlchemy models
- Reversible migrations (important for rollback)
- Battle-tested in production

**Alternatives Rejected**:
- Flyway: Java-based, overkill
- Raw SQL migrations: No auto-generation, error-prone
- Django migrations: Tied to Django framework

---

## Infrastructure & Deployment

### Hosting - Frontend

**Choice**: [Platform]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Vercel
**Pricing**: Free (Hobby), $20/mo (Pro) when > 100K requests/mo
**Rationale**:
- Zero-config Next.js deployment (push to deploy)
- Global CDN (fast page loads worldwide)
- Automatic HTTPS, preview deployments
- Generous free tier (10K req/mo)

**Alternatives Rejected**:
- Netlify: Similar but slightly worse Next.js support
- AWS Amplify: More complex setup
- Railway: Good but Vercel better for Next.js specifically
- Self-hosted: Too much DevOps overhead

### Hosting - Backend

**Choice**: [Platform]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Railway
**Pricing**: $5/mo base + usage (estimate $20-30/mo for MVP)
**Rationale**:
- Simple Docker deployment (Dockerfile → deploy)
- Includes PostgreSQL + Redis (no separate DBaaS)
- Auto-scaling, zero-downtime deploys
- Good DX (better than AWS/GCP)

**Alternatives Rejected**:
- Heroku: More expensive ($25/mo dyno + $9/mo Postgres)
- Render: Similar to Railway but slightly worse DX
- AWS ECS: Too complex, need DevOps expertise
- DigitalOcean App Platform: Good but Railway has better UX

### Database Hosting

**Choice**: [Platform]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Railway PostgreSQL
**Pricing**: Included in Railway usage pricing
**Rationale**:
- Managed service (backups, updates handled)
- Same platform as API (simpler billing, networking)
- Scales to 10K users easily

**Alternatives Rejected**:
- Supabase: Good but adds another service to manage
- AWS RDS: Too expensive for MVP ($15/mo minimum)
- Self-hosted Postgres: Too much overhead

### File Storage

**Choice**: [Service]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Vercel Blob
**Pricing**: $0.10/GB storage, $0.10/GB transfer (estimate $5/mo)
**Rationale**:
- Integrated with Vercel deployment
- Simple API (no AWS SDK complexity)
- Adequate for MVP (<100GB files)

**Alternatives Rejected**:
- AWS S3: More complex, overkill for MVP
- Cloudinary: Image-focused, we need PDFs too
- Self-hosted: Storage on Railway (expensive)

---

## Developer Tools

### Package Managers

**Frontend**: [Tool]
**Backend**: [Tool]
**Rationale**: [Why chosen]

**Example**:
**Frontend**: pnpm
**Backend**: uv (Python package manager)
**Rationale**:
- pnpm: Faster than npm/yarn, efficient disk usage
- uv: Faster than pip, better dependency resolution

### Code Quality

**Linting**: [Tool]
**Formatting**: [Tool]
**Type Checking**: [Tool]

**Example**:
**Linting**:
- Frontend: ESLint with Next.js config
- Backend: Ruff (modern Python linter, 10x faster than Pylint)

**Formatting**:
- Frontend: Prettier
- Backend: Black (opinionated Python formatter)

**Type Checking**:
- Frontend: TypeScript compiler (tsc)
- Backend: Pyright (fast type checker for Python)

### Testing

**Frontend**: [Framework]
**Backend**: [Framework]
**E2E**: [Tool]

**Example**:
**Frontend**: Jest + React Testing Library
**Backend**: pytest + pytest-asyncio
**E2E**: Playwright
**Rationale**:
- Industry standards, large communities
- Good integration with CI/CD

---

## Authentication & Third-Party Services

### Authentication

**Choice**: [Service]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Clerk
**Pricing**: Free < 10K users, then $25/mo
**Rationale**:
- Handles complex auth flows (MFA, social login, password reset)
- Excellent DX (React hooks, middleware)
- Saves 2-3 weeks of development time
- SOC 2 compliant (important for SaaS)

**Alternatives Rejected**:
- Auth0: More expensive ($23/mo minimum)
- Supabase Auth: Less mature, fewer features
- Roll-our-own: High risk, time sink (2-3 weeks)

### Payments

**Choice**: [Service]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Stripe
**Pricing**: 2.9% + $0.30 per transaction
**Rationale**:
- Industry standard for SaaS subscriptions
- Excellent docs, strong API
- Handles PCI compliance, tax calculation
- Webhooks for subscription lifecycle events

**Alternatives Rejected**:
- PayPal: Worse UX, less developer-friendly
- Paddle: Merchant of record model (don't want)
- Manual invoicing: Not scalable

### Analytics

**Choice**: [Service]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: PostHog
**Pricing**: Free < 1M events/mo
**Rationale**:
- Product analytics + feature flags + session recording
- Self-hosted option (avoid vendor lock-in)
- Privacy-friendly (GDPR compliant)
- Generous free tier

**Alternatives Rejected**:
- Google Analytics: Privacy concerns, basic features
- Mixpanel: Expensive ($25/mo after trial)
- Amplitude: Similar to Mixpanel, pricey

### Email

**Choice**: [Service]
**Pricing**: [Cost]
**Rationale**: [Why chosen]

**Example**:
**Choice**: Resend
**Pricing**: Free < 3K emails/mo, then $20/mo
**Rationale**:
- Modern API (better DX than SendGrid)
- React email templates (reuse frontend components)
- Good deliverability

**Alternatives Rejected**:
- SendGrid: Older API, worse DX
- Mailgun: More expensive
- AWS SES: Complex setup

---

## Constraints & Trade-offs

### Performance

**Target**: [Performance target]
**Trade-off**: [What sacrificed]

**Example**:
**Target**: API p95 < 500ms, Frontend FCP < 1.5s
**Trade-off**: Using TypeScript/Python (slower than Go/Rust) for developer productivity

### Cost

**Budget**: [Monthly budget]
**Trade-off**: [Where cutting costs]

**Example**:
**Budget**: < $50/mo for MVP (100 users)
**Trade-off**: Using managed services (Vercel, Railway) instead of AWS (higher per-unit cost, lower DevOps time)

### Scalability

**Current Capacity**: [Max users/requests]
**Next Tier**: [When/how to scale]

**Example**:
**Current Capacity**: 1,000 concurrent users, 100K req/day
**Next Tier**: At 10K users, add read replicas, horizontal API scaling (+$50/mo)

---

## Dependency Management

### Frontend

**Lock File**: `pnpm-lock.yaml`
**Update Strategy**: [How often to update]
**Security**: [How to check vulnerabilities]

**Example**:
**Lock File**: `pnpm-lock.yaml` (committed)
**Update Strategy**: Monthly security updates, quarterly major version bumps
**Security**: `pnpm audit` in CI, Dependabot alerts

### Backend

**Lock File**: `uv.lock` / `requirements.txt`
**Update Strategy**: [How often to update]
**Security**: [How to check vulnerabilities]

**Example**:
**Lock File**: `requirements.txt` with pinned versions
**Update Strategy**: Monthly for security, quarterly for features
**Security**: `safety check` in CI, GitHub security alerts

---

## Technology Upgrade Path

**When to Upgrade**: [Triggers for major version bumps]
**How to Upgrade**: [Process]

**Example**:
**When to Upgrade**:
- Security vulnerabilities: Immediately
- Major framework versions: Within 6 months of stable release
- End-of-life libraries: Before EOL date

**How to Upgrade**:
1. Test in feature branch
2. Run full test suite
3. Deploy to staging
4. Manual smoke testing
5. Monitor for 24 hours
6. Deploy to production

---

## Decision Log

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| [DATE] | [What] | [Why] | [Effect on project] |

**Example**:

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| 2025-10-01 | Switched from npm to pnpm | 3x faster installs, disk space savings | Saves 30s per CI run |
| 2025-09-20 | Added Redis for caching | API response time reduced 60% (1.2s → 500ms) | +$5/mo hosting cost |
| 2025-09-10 | Chose Railway over Heroku | 40% cheaper ($30/mo vs $50/mo at 1K users) | Saved $240/year |

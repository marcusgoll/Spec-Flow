# Capacity Planning

**Last Updated**: [DATE]
**Related Docs**: See `system-architecture.md` for components, `tech-stack.md` for infrastructure choices

## Current Scale (MVP Baseline)

**Users**: [Number]
**Requests**: [Per day/month]
**Storage**: [Size]
**Budget**: [Monthly cost]

**Example**:
**Users**: 100 active users (10-15 CFIs × 5-10 students each)
**Requests**: ~10,000/day (100 req/user/day average)
**Storage**: 5GB (mostly lesson plans, uploaded docs)
**Database**: < 1GB (mostly text, small tables)
**Budget**: $40/mo total
  - Vercel: $0 (within free tier)
  - Railway: $30 (API + PostgreSQL + Redis)
  - Vercel Blob: $5 (storage)
  - Clerk: $0 (< 10K MAU)
  - Stripe: $0 (no minimum)

**Constraints**:
- Single API container (1GB RAM, 1 vCPU)
- Single PostgreSQL instance (shared, 100 connections max)
- No CDN beyond Vercel edge network
- No dedicated Redis cluster

---

## Growth Projections

### Tier 1: 10x Growth (100 → 1,000 users)

**Timeline**: [When expected]
**Triggers**: [What indicates we're approaching this]

**Example**:
**Timeline**: 6-9 months
**Triggers**:
- Monthly active users (MAU) > 800
- API response time p95 > 1s
- Database connections > 80 (80% of limit)
- Storage > 40GB

**Infrastructure Changes**:

| Component | Current | New | Cost Change |
|-----------|---------|-----|-------------|
| API | 1 container (1GB RAM) | 2 containers (2GB RAM each) | +$20/mo |
| Database | Single instance | Add read replica | +$15/mo |
| Cache | Shared Redis | Dedicated Redis | +$10/mo |
| Storage | Vercel Blob | Same (scales) | +$10/mo (usage) |

**Total New Cost**: $40/mo → $95/mo (+$55/mo, +137%)

**Capacity**:
- Handles 100,000 req/day (10x increase)
- 500 concurrent connections (from read replica)
- 500GB storage capacity

**Optimizations Needed**:
- Add database indexes for slow queries
- Implement query result caching (Redis)
- Enable connection pooling (PgBouncer)
- Compress uploaded files (reduce storage cost)

**Bottlenecks**:
- Background jobs (single Celery worker) → add 1 more worker

---

### Tier 2: 100x Growth (100 → 10,000 users)

**Timeline**: [When expected]
**Triggers**: [What indicates we're approaching this]

**Example**:
**Timeline**: 18-24 months
**Triggers**:
- MAU > 8,000
- API p95 > 800ms
- Database CPU > 70%
- Storage > 400GB

**Infrastructure Changes**:

| Component | Tier 1 | Tier 2 | Cost Change |
|-----------|--------|--------|-------------|
| API | 2 containers (2GB) | 5 containers (4GB), auto-scale | +$100/mo |
| Database | Primary + 1 read replica | Primary + 2 read replicas, vertical scale (4 vCPU) | +$80/mo |
| Cache | Dedicated Redis | Redis cluster (3 nodes) | +$40/mo |
| CDN | Vercel edge | Add Cloudflare (for Blob) | +$20/mo |
| Queue | 2 Celery workers | Dedicated queue service (5 workers) | +$30/mo |
| Monitoring | Basic logs | APM (Datadog/New Relic) | +$50/mo |

**Total New Cost**: $95/mo → $415/mo (+$320/mo, +337%)

**Capacity**:
- Handles 1,000,000 req/day (100x increase)
- 2,000 concurrent connections
- 5TB storage capacity

**Architecture Changes**:
- **Sharding**: Partition database by `instructor_id` (e.g., hash mod 4 shards)
- **Microservices** (optional): Extract billing service (independent scaling)
- **CDN**: Offload static asset delivery
- **Caching**: Aggressive caching (80% cache hit rate target)

**Bottlenecks**:
- PostgreSQL write throughput → consider write sharding
- Job queue → dedicated service (RabbitMQ or SQS)

---

### Tier 3: 1000x Growth (100 → 100,000 users)

**Timeline**: [When expected - likely years]
**Triggers**: [What indicates we're approaching this]

**Example**:
**Timeline**: 3-5 years (if successful)
**Triggers**:
- MAU > 80,000
- Revenue > $100K/mo (justifies larger infrastructure)
- Multi-region demand (international users)

**Infrastructure Changes**:

| Component | Tier 2 | Tier 3 | Cost Change |
|-----------|--------|--------|-------------|
| API | 5 containers | 20-50 containers, Kubernetes (multi-region) | +$500/mo |
| Database | 1 primary + 2 replicas | Sharded cluster (16 shards, 3 replicas each) | +$800/mo |
| Cache | Redis cluster (3 nodes) | Redis cluster per region (15 nodes total) | +$150/mo |
| CDN | Cloudflare | Multi-CDN (Cloudflare + Fastly) | +$100/mo |
| Search | PostgreSQL full-text | Elasticsearch cluster | +$200/mo |
| Observability | Datadog | Datadog + custom dashboards + on-call | +$150/mo |

**Total New Cost**: $415/mo → $2,315/mo (+$1,900/mo, +458%)

**Capacity**:
- Handles 10,000,000 req/day (1000x increase)
- Multi-region deployment (US-East, US-West, EU)
- 50TB storage capacity
- 99.99% uptime SLA

**Architecture Changes**:
- **Microservices**: Split into 5-10 services (students, lessons, billing, notifications, analytics)
- **Event-driven**: Kafka or SQS for async communication between services
- **Multi-region**: Active-active deployment, geo-routing
- **Dedicated teams**: Platform, SRE, separate product teams per domain

**Bottlenecks**:
- Cross-region data sync → eventual consistency model
- Cost optimization becomes critical (engineers dedicated to cost)

---

## Resource Estimates

### Compute (API)

**Current**:
- 1 container: 1GB RAM, 1 vCPU
- Handles ~20 req/sec (p95 < 500ms)

**Formula**: Requests/sec = (vCPU × efficiency_factor) / avg_response_time
- Efficiency factor: 0.7 (70% utilization)
- Avg response time: 200ms

**Example Calculation**:
- 1 vCPU × 0.7 / 0.2s = 3.5 req/sec per vCPU
- For 100 req/sec → need ~30 vCPUs → ~30 containers (1 vCPU each) or 8 containers (4 vCPU each)

### Database Connections

**Current**: 100 max connections

**Formula**: Connections needed = (API containers × connections_per_container) + background_jobs
- Connections per container: 10 (pool size)
- Background jobs: 5 workers × 5 connections = 25

**Example**:
- Tier 1 (2 containers): 2 × 10 + 25 = 45 connections
- Tier 2 (5 containers): 5 × 10 + 25 = 75 connections
- Tier 3 (50 containers): Need connection pooler (PgBouncer) → 500 backend connections

### Storage

**Current**: 5GB

**Formula**: Total storage = (user_files × avg_file_size × users) + database_size

**Example**:
- Avg files per user: 10 (lesson plans, logbook scans)
- Avg file size: 2MB
- 100 users: 100 × 10 × 2MB = 2GB files + 1GB DB = 3GB total
- 1,000 users: 1,000 × 10 × 2MB = 20GB files + 5GB DB = 25GB
- 10,000 users: 10,000 × 10 × 2MB = 200GB files + 30GB DB = 230GB

**Growth Rate**: ~2GB/month (assuming 20 new users/month)

---

## Cost Model

### Cost Per User

**Tier 1** (1,000 users):
- Total cost: $95/mo
- Cost per user: $0.095/mo (~$1.14/year)

**Tier 2** (10,000 users):
- Total cost: $415/mo
- Cost per user: $0.041/mo (~$0.50/year)

**Tier 3** (100,000 users):
- Total cost: $2,315/mo
- Cost per user: $0.023/mo (~$0.28/year)

**Economics**: Cost per user decreases as we scale (economies of scale)

### Revenue Targets

**Pricing**: [Your pricing model]

**Example**:
**Pricing**: $25/mo per instructor

**Break-Even**:
- Tier 1 ($95/mo cost): 4 paying instructors
- Tier 2 ($415/mo cost): 17 paying instructors
- Tier 3 ($2,315/mo cost): 93 paying instructors

**Healthy Margin** (5x cost coverage):
- Tier 1: 20 instructors → $500/mo revenue, $95 cost = 81% margin
- Tier 2: 85 instructors → $2,125/mo revenue, $415 cost = 80% margin
- Tier 3: 465 instructors → $11,625/mo revenue, $2,315 cost = 80% margin

---

## Performance Targets by Tier

| Metric | Tier 0 (MVP) | Tier 1 (1K users) | Tier 2 (10K users) | Tier 3 (100K users) |
|--------|--------------|-------------------|--------------------|--------------------|
| API p50 | < 200ms | < 150ms | < 100ms | < 80ms |
| API p95 | < 500ms | < 400ms | < 300ms | < 200ms |
| API p99 | < 1s | < 800ms | < 600ms | < 500ms |
| Uptime | 99% | 99.5% | 99.9% | 99.99% |
| Database query p95 | < 200ms | < 150ms | < 100ms | < 50ms |
| Frontend FCP | < 1.5s | < 1.2s | < 1s | < 800ms |

---

## Scaling Triggers

**When to Scale**: Don't wait until breaking, scale proactively

| Trigger | Action | Lead Time |
|---------|--------|-----------|
| CPU > 70% for 1 hour | Add API container | Immediate (auto-scale) |
| RAM > 80% for 30 min | Increase container size | 1 hour |
| DB connections > 80% | Add read replica or connection pooler | 1 week |
| Storage > 80% capacity | Increase storage tier | 3 days |
| p95 response time > target for 24 hours | Investigate, optimize, or scale | 1 week |

**Auto-Scaling Rules** (Tier 2+):
- CPU > 70% for 5 min → +1 container
- CPU < 30% for 15 min → -1 container
- Min containers: 2 (always)
- Max containers: 20 (cost limit)

---

## Disaster Scenarios

### Scenario 1: Sudden 10x Traffic Spike

**Cause**: [Viral post, competitor shutdown, etc.]
**Impact**: [What breaks]
**Response**: [How to handle]

**Example**:
**Cause**: Mentioned on popular aviation podcast, 5,000 new signups in 24 hours
**Impact**:
- API containers max out (100% CPU)
- Database connections exhausted
- Response times degrade to 5-10s

**Response**:
1. **Immediate** (0-30 min): Manually scale API to 10 containers, enable rate limiting
2. **Short-term** (1-4 hours): Add read replica, increase DB connection limit
3. **Medium-term** (1-3 days): Optimize slow queries, increase cache TTL, add CDN
4. **Long-term** (1-2 weeks): Review architecture, implement auto-scaling

**Cost**: +$150/mo during spike (can scale back after)

### Scenario 2: Database Failure

**Impact**: [What breaks]
**Recovery Time**: [RTO]
**Data Loss**: [RPO]

**Example**:
**Impact**: All API requests fail (database is unavailable)
**Recovery Time**: 30 minutes (restore from backup)
**Data Loss**: Up to 15 minutes (last backup)

**Response**:
1. **Immediate**: Switch to maintenance mode page
2. **Restore**: Railway automated restore from latest backup
3. **Validate**: Run smoke tests, check data integrity
4. **Resume**: Bring API back online
5. **Post-mortem**: Document, add monitoring for early detection

---

## Optimization Opportunities

### Current (MVP) Optimizations

**Low-hanging fruit** (implement now):
1. **Database indexing**: Add indexes for common queries (+50% query speedup)
2. **Query optimization**: Reduce N+1 queries (+30% API speedup)
3. **Response caching**: Cache student progress summaries (+60% cache hit rate)
4. **Compression**: Gzip API responses (-70% bandwidth)

**ROI**: High (minimal cost, significant performance gain)

### Tier 1 Optimizations

**As we grow**:
1. **Connection pooling**: PgBouncer for database (+200 connections capacity)
2. **CDN**: Cloudflare for static assets (+40% faster global loads)
3. **Image optimization**: Compress/resize uploaded images (-50% storage cost)
4. **Query caching**: Redis for frequent queries (+80% cache hit rate)

**ROI**: Medium (some cost, good performance gain)

### Tier 2 Optimizations

**At scale**:
1. **Sharding**: Partition database by `instructor_id` (+10x write throughput)
2. **Read replicas**: Offload read traffic from primary (+50% read capacity)
3. **Async processing**: Move heavy tasks to background queue (+70% API speedup)
4. **Materialized views**: Pre-compute analytics (+90% dashboard load time reduction)

**ROI**: Medium (higher cost, necessary for scale)

---

## Breaking Points

**What fails first at each tier:**

**Tier 0 → Tier 1**:
- **First to break**: API containers (CPU)
- **Symptom**: Response times > 2s
- **Fix**: Add container (+$10/mo)

**Tier 1 → Tier 2**:
- **First to break**: Database connections
- **Symptom**: "Too many connections" errors
- **Fix**: Add read replica (+$15/mo)

**Tier 2 → Tier 3**:
- **First to break**: Database write throughput
- **Symptom**: Slow writes (> 500ms), replication lag
- **Fix**: Shard database (+$300/mo for migration + $500/mo ongoing)

---

## Monitoring & Alerts

**Metrics to Track**:

| Metric | Tool | Alert Threshold |
|--------|------|----------------|
| API response time p95 | Railway | > 800ms for 10 min |
| Error rate | PostHog | > 2% for 5 min |
| CPU utilization | Railway | > 80% for 30 min |
| Database connections | PostgreSQL | > 80 connections |
| Storage usage | Vercel/Railway | > 80% capacity |
| Cost | Billing dashboard | > $60/mo (Tier 0) |

**Alert Channels**:
- Critical (p0): PagerDuty (phone call)
- High (p1): Slack #alerts
- Medium (p2): Email

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| [DATE] | [What] | [Why] | [Effect] |

**Example**:

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-10 | Added 2nd API container | p95 exceeded 1s during peak hours | Reduced p95 to 400ms, +$10/mo |
| 2025-09-25 | Increased database connections to 150 | Hit connection limit at 95 users | Headroom for growth to 200 users |
| 2025-09-15 | Enabled Redis caching | Dashboard loads were slow (1.2s) | Reduced to 300ms, +$10/mo |

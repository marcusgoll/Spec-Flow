# Deployment Strategy

**Last Updated**: [DATE]
**Deployment Model**: [staging-prod | direct-prod | local-only]
**Related Docs**: See `system-architecture.md` for infrastructure, `tech-stack.md` for platform choices

## Deployment Model

**Choice**: [staging-prod | direct-prod | local-only]
**Rationale**: [Why chosen for this project]

**Example**:
**Choice**: staging-prod
**Rationale**:
- Production SaaS (requires high reliability)
- Team of 1-3 developers (benefits from staging validation)
- Regulatory considerations (FAA compliance requires testing)
- Rollback capability critical (handles billing)

**Alternatives Rejected**:
- direct-prod: Too risky (no staging validation)
- local-only: Not applicable (deploying to users)

---

## Environments

### Development (Local)

**Purpose**: Local development and testing
**URL**: `http://localhost:3000` (web), `http://localhost:8000` (API)
**Database**: Local PostgreSQL or Docker
**Data**: Sample/seed data (not production data)
**Secrets**: `.env.local` (not committed)

**How to Run**:
```bash
# Frontend
cd apps/web
pnpm dev  # Runs on :3000

# Backend
cd api
uv run uvicorn main:app --reload  # Runs on :8000
```

### Staging

**Purpose**: Pre-production validation, testing with near-production data
**URL**: `https://app-staging.flightpro.com`
**Database**: Separate staging database (copy of production schema, sample data)
**Branch**: `staging` branch
**Deploy Trigger**: Merge to `staging` branch (auto-deploy)

**Differences from Production**:
- Feature flags enabled for unreleased features
- Less stringent rate limits (easier testing)
- Mock payment gateway (Stripe test mode)
- Verbose logging enabled

**Data**: Anonymized copy of production data (refreshed weekly) OR synthetic test data

### Production

**Purpose**: Live user-facing environment
**URL**: `https://app.flightpro.com`
**Database**: Production database (managed, backups enabled)
**Branch**: `main` branch
**Deploy Trigger**: Manual approval after staging validation

**Protections**:
- Required PR reviews (min 1 approval)
- Automated tests must pass
- Pre-flight checks (build, lint, type-check)
- Rollback plan documented

---

## CI/CD Pipeline

**Tool**: [GitHub Actions | GitLab CI | CircleCI]
**Configuration**: [Where config lives]

**Example**:
**Tool**: GitHub Actions
**Configuration**: `.github/workflows/`

### Pipeline Stages

**Stage 1: Verify (on every PR)**
```yaml
# .github/workflows/verify.yml
- Lint (ESLint, Ruff)
- Type check (TypeScript, Pyright)
- Unit tests (Jest, pytest)
- Build (ensure no build errors)
- Security scan (npm audit, safety)
```
**Duration**: ~3 minutes
**Blocks merge if**: Any step fails

**Stage 2: Deploy to Staging (on merge to `staging`)**
```yaml
# .github/workflows/deploy-staging.yml
- Run verify steps
- Build Docker image (API)
- Build Next.js (Web)
- Deploy to Railway (API)
- Deploy to Vercel (Web)
- Run smoke tests
- Update deployment metadata
```
**Duration**: ~5 minutes
**Blocks deployment if**: Build or smoke tests fail

**Stage 3: Deploy to Production (manual trigger)**
```yaml
# .github/workflows/deploy-production.yml
- Require manual approval
- Pre-flight validation
- Promote staging artifacts to production
- Run database migrations
- Deploy API (blue-green or rolling)
- Deploy Web (Vercel promotion)
- Run smoke tests
- Update roadmap (mark feature as shipped)
- Create release notes
```
**Duration**: ~7 minutes
**Rollback if**: Smoke tests fail

---

## Deployment Process

### Deploying to Staging

**Trigger**: Merge feature branch to `staging`

**Steps**:
1. Create PR: `feature/[name]` → `staging`
2. Code review (1 approval required)
3. CI runs verify pipeline (must pass)
4. Merge PR (auto-deploys to staging)
5. Monitor deployment logs
6. Run manual validation checklist
7. If issues found: Fix in feature branch, repeat

**Validation Checklist**:
- [ ] App loads without errors
- [ ] New feature works as expected
- [ ] Existing features still work (smoke test)
- [ ] No console errors
- [ ] Lighthouse performance ≥ 85
- [ ] Database migrations applied successfully

**Typical Duration**: 10-15 minutes (CI + manual validation)

### Deploying to Production

**Trigger**: Manual (after staging validation passes)

**Steps**:
1. Create PR: `staging` → `main`
2. Review changes (all commits since last production deploy)
3. Update version in `package.json` (automated by CI)
4. Create changelog/release notes
5. Merge PR with approval
6. GitHub Actions: Manual approval gate
7. Approve deployment (triggers production pipeline)
8. Monitor deployment
9. Validate with smoke tests
10. Monitor error rates for 1 hour
11. Update roadmap (mark features as shipped)

**Quality Gates** (must pass before production):
- ✅ Staging validation complete
- ✅ Code review approved
- ✅ Database migrations tested in staging
- ✅ Rollback plan documented
- ✅ Smoke tests pass
- ✅ Pre-flight checks pass (env vars, builds, Docker)

**Typical Duration**: 30-40 minutes (includes monitoring period)

---

## Deployment Artifacts

### Build Artifacts

**Web (Next.js)**:
- Build output: `.next/` directory
- Static export: `.vercel/output/` (Vercel-specific)
- Generated: During CI build step
- Stored: Vercel CDN (cached)

**API (FastAPI)**:
- Docker image: `ghcr.io/[org]/api:[commit-sha]`
- Generated: During CI build step
- Stored: GitHub Container Registry
- Tagged: `latest` (rolling), `v1.2.3` (release), `staging` (staging env)

**Database Migrations**:
- Alembic migration files: `api/alembic/versions/*.py`
- Applied: Before deployment (automated in pipeline)
- Reversible: Yes (all migrations have `downgrade()` function)

### Artifact Promotion

**Strategy**: Build once, promote to production (not rebuild)

**Example**:
1. **Staging deploy**: Build Docker image `api:abc123`, deploy to Railway staging
2. **Production deploy**: Promote same `api:abc123` image to Railway production (no rebuild)

**Why**: Ensures exact same code tested in staging goes to production

---

## Database Migrations

**Tool**: [Alembic | Flyway | Liquibase]
**Strategy**: [How migrations applied]

**Example**:
**Tool**: Alembic (Python)
**Strategy**: Auto-apply before deployment

**Migration Workflow**:
1. Developer creates migration: `alembic revision --autogenerate -m "add_user_preferences_table"`
2. Review generated SQL (manual check for safety)
3. Test locally: `alembic upgrade head` then `alembic downgrade -1` (ensure reversible)
4. Commit migration file
5. CI runs migration in staging before deploying app
6. Validate data in staging
7. CI runs migration in production before deploying app

**Safety Checks**:
- ✅ All migrations reversible (have `downgrade()`)
- ✅ Migrations tested in staging first
- ✅ No data loss on rollback
- ✅ Zero-downtime (expand-contract pattern for breaking changes)

**Example Zero-Downtime Migration** (renaming column):
```python
# Step 1: Add new column (nullable)
def upgrade():
    op.add_column('users', sa.Column('email_address', sa.String()))

# Deploy app (dual-write to both columns)

# Step 2: Backfill data
UPDATE users SET email_address = email WHERE email_address IS NULL;

# Deploy app (read from new column)

# Step 3: Drop old column
def upgrade():
    op.drop_column('users', 'email')
```

---

## Rollback Procedure

**When to Rollback**:
- Error rate > 5% for 5 minutes
- Critical feature broken
- Data corruption detected
- Performance degradation (p95 > 2x baseline)

**How to Rollback**:

### Quick Rollback (< 5 minutes)

**Web (Vercel)**:
```bash
# Via Vercel dashboard
1. Go to Deployments
2. Find previous deployment
3. Click "Promote to Production"

# Via CLI
vercel rollback [deployment-url]
```

**API (Railway)**:
```bash
# Via Railway dashboard
1. Go to Deployments
2. Select previous deployment
3. Click "Redeploy"

# Via CLI
railway up --deployment [previous-deployment-id]
```

### Full Rollback (with database)

**If migration applied**:
```bash
# 1. Revert app code (above)
# 2. Revert database migration
cd api
alembic downgrade -1  # Or specific revision

# 3. Validate
# Run smoke tests
```

**Duration**: 5-10 minutes

**Testing**: Quarterly rollback drills to ensure procedure works

---

## Monitoring & Alerts

**What to Monitor**:

| Metric | Tool | Alert Threshold | Action |
|--------|------|-----------------|--------|
| Error rate | PostHog | > 2% for 5 min | Investigate, rollback if > 5% |
| API response time p95 | Railway | > 1s for 10 min | Investigate performance |
| Deployment status | GitHub Actions | Failed | Notify team, block deployment |
| Database CPU | Railway | > 85% for 30 min | Scale up |
| Disk space | Railway | > 80% | Increase storage |

**Alert Channels**:
- **Critical** (error rate, deployment failures): PagerDuty → phone call
- **Warning** (performance degradation): Slack #alerts
- **Info** (successful deployment): Slack #deploys

**Post-Deployment Monitoring**:
- Watch error rate for 1 hour after production deploy
- Compare with baseline (pre-deploy error rate)
- If errors spike > 2x baseline → investigate immediately

---

## Feature Flags

**Tool**: [PostHog | LaunchDarkly | Custom]
**Use Cases**: [When to use]

**Example**:
**Tool**: PostHog (built-in feature flags)
**Use Cases**:
- Gradual rollout (0% → 5% → 25% → 50% → 100%)
- A/B testing
- Kill switch for problematic features
- Early access for beta users

**Implementation**:
```typescript
// Frontend
const isNewDashboardEnabled = posthog.isFeatureEnabled('new-dashboard')

// Backend
is_enabled = posthog.is_feature_enabled('new-dashboard', user.id)
```

**Rollout Strategy**:
1. **Day 0**: Deploy code, flag = 0% (off for all users)
2. **Day 1**: Enable for team only (hardcoded user IDs)
3. **Day 3**: 5% of users (random)
4. **Day 7**: 25% of users
5. **Day 14**: 50% of users
6. **Day 21**: 100% (remove flag in next release)

**Kill Switch**: If issues found, set flag to 0% immediately (no redeployment needed)

---

## Secrets Management

**Tool**: [How secrets stored/accessed]
**Rotation**: [How often, what process]

**Example**:
**Tool**: Platform-managed environment variables (Vercel, Railway)
**Storage**: Secrets stored in platform (encrypted at rest)
**Access**: Env vars injected at runtime (not in code)

**Secrets Inventory**:
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `CLERK_SECRET_KEY` - Clerk API key
- `STRIPE_SECRET_KEY` - Stripe API key
- `NEXT_PUBLIC_*` - Public env vars (not secret, but configured)

**Rotation**:
- API keys: Every 90 days (automated reminders)
- Database passwords: Every 180 days
- Process: Update in platform → redeploy (zero downtime)

**Never Commit**:
- ❌ `.env` files (use `.env.example` as template)
- ❌ API keys in code
- ❌ Passwords in comments

---

## Deployment Schedule

**Recommended Schedule**: [When to deploy]

**Example**:
**Regular Deployments**: Tuesdays and Thursdays, 10am-2pm EST
**Why**: Allows time to monitor, avoid Friday deployments (weekend issues)

**Emergency Hotfixes**: Anytime (for critical bugs, security issues)

**Deployment Freeze**:
- Week before major product launch
- During Black Friday/major events
- December 20 - January 2 (holidays)

---

## Disaster Recovery

**Scenario**: Total platform failure (Vercel/Railway down)

**Recovery Plan**:
1. **Immediate** (0-15 min): Post status page update, notify users
2. **Short-term** (15-60 min): Switch to backup platform (if prepared) OR wait for provider recovery
3. **Long-term** (1-24 hours): If provider doesn't recover, manual deployment to alternative platform

**Backup Platforms**:
- Web: Netlify (prepared config, not actively deployed)
- API: Render or Fly.io (Docker image compatible)
- Database: Backup restoration to local or alternative cloud

**RTO** (Recovery Time Objective): 4 hours
**RPO** (Recovery Point Objective): 1 hour (latest backup)

---

## Compliance & Audit

**Deployment Audit Log**:
- Who deployed: GitHub user
- What changed: Git commit diff
- When: Timestamp
- Where: Environment (staging/production)
- Stored: GitHub Actions logs (90 days), exported to S3 (7 years)

**Regulatory Requirements** (if applicable):
- SOC 2: Deployment process documented, change management
- HIPAA: Deployment logs retained, access controls
- PCI: Production access restricted, deployment approvals required

---

## Performance Validation

**Pre-Deployment Checks**:
- Lighthouse CI score ≥ 85 (performance)
- Bundle size < 200KB initial load
- Docker image size < 500MB

**Post-Deployment Checks**:
- Run smoke tests (critical paths)
- Lighthouse audit on production URL
- Compare metrics with baseline

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| [DATE] | [What] | [Why] | [Effect] |

**Example**:

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-15 | Added automated rollback on error rate > 5% | Reduce manual intervention | Faster incident response |
| 2025-10-01 | Switched from Heroku to Railway | 40% cost savings | No user impact, better DX |
| 2025-09-20 | Enabled feature flags via PostHog | Gradual rollouts, safer deployments | Reduced deployment risk |

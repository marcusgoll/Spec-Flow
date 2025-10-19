# Specification Phase Reference Guide

## Classification Decision Tree

```
Does description mention UI keywords?
(screen, page, component, dashboard, form, modal, frontend, interface)
├─ Yes → Check for backend-only exclusions
│  ├─ Contains: API, endpoint, service, backend, database, migration, health check, cron, job, worker
│  │  └─ HAS_UI = false (backend infrastructure, not UI)
│  └─ No backend-only keywords
│     └─ HAS_UI = true (UI feature)
└─ No → HAS_UI = false (backend/data feature)

Does description mention improvement keywords?
(improve, optimize, enhance, speed up, reduce time, increase performance)
AND mentions existing baseline?
(existing, current, slow, faster, better)
├─ Yes → IS_IMPROVEMENT = true (generates hypothesis)
└─ No → IS_IMPROVEMENT = false

Does description mention metrics keywords?
(track user, measure user, user engagement, user retention, conversion, behavior, analytics, A/B test)
├─ Yes → HAS_METRICS = true (generates HEART metrics)
└─ No → HAS_METRICS = false

Does description mention deployment keywords?
(migration, alembic, schema change, env variable, breaking change, platform change, infrastructure, docker, deploy config)
├─ Yes → HAS_DEPLOYMENT_IMPACT = true (prompts deployment questions)
└─ No → HAS_DEPLOYMENT_IMPACT = false
```

## Informed Guess Heuristics

**Don't ask about these - use reasonable defaults:**

### Performance Targets

**Default assumptions (web applications)**:
- API response time: <500ms (95th percentile)
- Frontend First Contentful Paint (FCP): <1.5s
- Frontend Time to Interactive (TTI): <3.0s
- Database queries: <100ms
- Lighthouse Performance Score: ≥85
- Lighthouse Accessibility Score: ≥95

**Document in spec**:
```markdown
## Performance Targets (Assumed)
- API endpoints: <500ms (95th percentile)
- Frontend FCP: <1.5s, TTI: <3.0s
- Lighthouse: Performance ≥85, Accessibility ≥95

_Assumption: Standard web application performance expectations applied._
```

### Data Retention

**Default assumptions (GDPR-compliant)**:
- User data: Indefinite with deletion option
- Logs: 90 days rolling retention
- Analytics: 365 days aggregated
- Temporary uploads: 24 hours
- Session data: 30 days inactive
- Error traces: 30 days

**Document in spec**:
```markdown
## Data Retention (Assumed)
- User profiles: Indefinite (user can delete anytime)
- Application logs: 90 days rolling
- Analytics data: 365 days aggregated

_Assumption: GDPR-compliant data retention applied. User controls own data._
```

### Error Handling

**Default assumptions**:
- User-friendly messages (no stack traces to users)
- Error ID for support tracking
- Logging to error-log.md + monitoring system
- Graceful degradation where possible
- Retry with exponential backoff for transient failures

**Document in spec**:
```markdown
## Error Handling (Assumed)
- User sees: Friendly message + Error ID (ERR-XXXX)
- System logs: Full error details + stack trace
- Retry: 3 attempts with exponential backoff for API/DB errors

_Assumption: Standard error handling patterns applied._
```

### Authentication Method

**Default assumptions**:
- External users: OAuth2 (Google, GitHub)
- Internal users: Session-based with secure cookies
- API access: JWT bearer tokens (RS256)
- MFA: Optional for users, required for admins

**Document in spec**:
```markdown
## Authentication (Assumed)
- User login: OAuth2 (Google, GitHub)
- API access: JWT bearer tokens
- Sessions: Secure cookies, 30-day expiry

_Assumption: Standard OAuth2 flow for user authentication._
```

### Rate Limiting

**Default assumptions**:
- Per user: 100 requests/minute
- Per IP: 1000 requests/minute
- Bulk operations: 10 operations/hour
- API exports: 10 exports/day

**Document in spec**:
```markdown
## Rate Limits (Assumed)
- User actions: 100 requests/minute
- Bulk operations: 10/hour per user
- CSV exports: 10/day per user

_Assumption: Conservative rate limits to prevent abuse._
```

### Integration Patterns

**Default assumptions**:
- API style: RESTful (unless GraphQL explicitly needed)
- Data format: JSON (unless CSV/XML explicitly needed)
- Pagination: Offset/limit with max 100 items per page
- Versioning: URL-based (/api/v1/...)
- CORS: Allowed from same domain + configured allowlist

## Clarification Prioritization Matrix

**Only use [NEEDS CLARIFICATION] for these categories:**

| Category | Priority | Ask? | Example |
|----------|----------|------|---------|
| **Scope boundary** | Critical | ✅ Always | "Does this include admin features or only user features?" |
| **Security/Privacy** | Critical | ✅ Always | "Should PII be encrypted at rest?" |
| **Breaking changes** | Critical | ✅ Always | "Is it okay to change the API response format?" |
| **User experience** | High | ✅ If ambiguous | "Should this be a modal or new page?" |
| **Performance SLA** | Medium | ❌ Use defaults | "What's the target response time?" → Assume <500ms |
| **Technical stack** | Medium | ❌ Defer to plan | "Which database?" → Plan phase decision |
| **Error messages** | Low | ❌ Use standard | "What error message?" → Standard pattern |
| **Rate limits** | Low | ❌ Use defaults | "How many requests?" → 100/min default |

**Limit: Maximum 3 clarifications total per spec**

If you have 5 potential clarifications:
1. Rank by category priority
2. Keep top 3
3. Make informed guesses for remaining 2
4. Document assumptions clearly

## Slug Generation Rules

**Goal**: Generate clean, concise slugs that match roadmap entries

### Remove Filler Words

```bash
# Strip common filler patterns
echo "$ARGUMENTS" |
  # Remove action verbs
  sed 's/\bwe want to\b//gi; s/\bI want to\b//gi' |
  sed 's/\badd\b//gi; s/\bcreate\b//gi; s/\bimplement\b//gi' |

  # Remove connecting phrases
  sed 's/\bget our\b//gi; s/\bto a\b//gi; s/\bwith\b//gi; s/\bfor the\b//gi' |
  sed 's/\bbefore moving on to\b//gi; s/\bother features\b//gi' |

  # Remove articles
  sed 's/\ba\b//gi; s/\ban\b//gi; s/\bthe\b//gi' |

  # Convert to lowercase and hyphenate
  tr '[:upper:]' '[:lower:]' |
  sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' |

  # Limit length
  cut -c1-50
```

### Examples

| User Input | Generated Slug | Notes |
|-----------|----------------|-------|
| "We want to add student progress dashboard" | `student-progress-dashboard` | ✅ Clean |
| "Get our Vercel and Railway app to a healthy state" | `vercel-railway-app-healthy-state` | ✅ Preserves technical terms |
| "Add user authentication with OAuth2" | `user-authentication-oauth2` | ✅ Preserves OAuth2 |
| "Create a background worker to process uploads" | `background-worker-process-uploads` | ✅ Technical terms kept |

### Fuzzy Matching

If exact slug not found in roadmap, suggest fuzzy matches:

```bash
# Levenshtein distance < 3 edits
# Example: "student-dashboard" matches "student-progress-dashboard" (diff: 9 chars but semantically close)
```

## Research Depth Guidelines

**Minimal research** (1-2 tools) - Backend/API features:
1. Constitution check (alignment with mission/values)
2. Quick grep for similar patterns

**Standard research** (3-5 tools) - Single-aspect features:
1-2. Minimal research (above)
3. UI inventory scan (if HAS_UI=true)
4. Performance budgets check
5. Similar spec search

**Full research** (5-8 tools) - Complex multi-aspect features:
1-5. Standard research (above)
6. Design inspirations check (if HAS_UI=true)
7. Web search for novel patterns
8. Deep dive on integration points

**Decision criteria**:
- FLAG_COUNT ≤1: Minimal research
- FLAG_COUNT = 1: Standard research
- FLAG_COUNT ≥2: Full research

## Common Mistakes to Avoid

### ❌ Too Many Research Tools

**Bad**:
```bash
# 15 research tools for simple backend endpoint
Glob *.py
Glob *.ts
Glob *.tsx
Grep "database"
Grep "model"
Grep "endpoint"
...10 more
```

**Good**:
```bash
# 2 research tools for simple backend endpoint
grep "similar endpoint" specs/*/spec.md
grep "BaseModel" api/app/models/*.py
```

### ❌ Missing Roadmap Integration

**Bad**:
```bash
# Generate fresh spec without checking roadmap
SLUG="student-dashboard"
# No roadmap check - user had already documented requirements there
```

**Good**:
```bash
# Check roadmap first
SLUG="student-dashboard"
if grep -qi "^### ${SLUG}" .spec-flow/memory/roadmap.md; then
  FROM_ROADMAP=true
  # Reuse existing context
fi
```

### ❌ Unclear Success Criteria

**Bad**:
```markdown
## Success Criteria
- System works correctly
- API is fast
- UI looks good
```

**Good**:
```markdown
## Success Criteria
- User can complete registration in <3 minutes (measured via PostHog funnel)
- API response time <500ms for 95th percentile (measured via Datadog APM)
- Lighthouse accessibility score ≥95 (measured via CI Lighthouse check)
```

### ❌ Technology-Specific Success Criteria

**Bad**:
```markdown
## Success Criteria
- React components render efficiently
- Redis cache hit rate >80%
- PostgreSQL queries use proper indexes
```

**Good**:
```markdown
## Success Criteria
- Page load time <1.5s (First Contentful Paint)
- 95% of user searches return results in <1 second
- Database queries complete in <100ms average
```

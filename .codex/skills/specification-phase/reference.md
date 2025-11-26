<overview>
Comprehensive reference material for specification-phase skill execution, including classification decision tree, informed guess heuristics, clarification prioritization matrix, slug generation rules, research depth guidelines, and common mistake patterns.

Use this as detailed reference when executing /specify workflow. SKILL.md provides execution steps, this file provides decision-making logic and defaults.
</overview>

<classification_decision_tree>
**Systematic classification logic for setting HAS_UI, IS_IMPROVEMENT, HAS_METRICS, HAS_DEPLOYMENT_IMPACT flags**

<has_ui_logic>
**HAS_UI Flag Decision**: Does feature include user-facing screens or components?

**Decision Flow**:
```
Does description mention UI keywords?
(screen, page, component, dashboard, form, modal, frontend, interface)
├─ Yes → Check for backend-only exclusions
│  ├─ Contains: API, endpoint, service, backend, database, migration, health check, cron, job, worker
│  │  └─ HAS_UI = false (backend infrastructure, not UI)
│  └─ No backend-only keywords
│     └─ HAS_UI = true (UI feature)
└─ No → HAS_UI = false (backend/data feature)
```

**Examples**:
- "Add student dashboard" → HAS_UI = true ✅ (UI keyword: dashboard, no backend exclusions)
- "Add background worker to process uploads" → HAS_UI = false ✅ (backend-only keyword: worker)
- "Create API endpoint for user data" → HAS_UI = false ✅ (backend-only keywords: API, endpoint)
- "Build user registration form" → HAS_UI = true ✅ (UI keyword: form, no backend exclusions)
</has_ui_logic>

<is_improvement_logic>
**IS_IMPROVEMENT Flag Decision**: Does feature optimize existing functionality with measurable baseline?

**Decision Flow**:
```
Does description mention improvement keywords?
(improve, optimize, enhance, speed up, reduce time, increase performance)
AND mentions existing baseline?
(existing, current, slow, faster, better)
├─ Yes → IS_IMPROVEMENT = true (generates hypothesis)
└─ No → IS_IMPROVEMENT = false
```

**Examples**:
- "Improve search performance from 3.2s to <500ms" → IS_IMPROVEMENT = true ✅ (improvement keyword: improve, baseline: 3.2s)
- "Make search faster" → IS_IMPROVEMENT = false ❌ (improvement keyword but no baseline)
- "Optimize API response time from 800ms to <500ms" → IS_IMPROVEMENT = true ✅ (baseline: 800ms, target: <500ms)
- "Add caching to improve performance" → IS_IMPROVEMENT = false ❌ (no current baseline specified)
</is_improvement_logic>

<has_metrics_logic>
**HAS_METRICS Flag Decision**: Does feature track user behavior?

**Decision Flow**:
```
Does description mention metrics keywords?
(track user, measure user, user engagement, user retention, conversion, behavior, analytics, A/B test)
├─ Yes → HAS_METRICS = true (generates HEART metrics)
└─ No → HAS_METRICS = false
```

**Examples**:
- "Track dashboard engagement" → HAS_METRICS = true ✅ (metrics keyword: track, engagement)
- "Measure user retention for onboarding flow" → HAS_METRICS = true ✅ (metrics keywords: measure, retention)
- "Add user authentication" → HAS_METRICS = false ❌ (no metrics keywords)
- "Build analytics dashboard for conversion rates" → HAS_METRICS = true ✅ (metrics keywords: analytics, conversion)
</has_metrics_logic>

<has_deployment_impact_logic>
**HAS_DEPLOYMENT_IMPACT Flag Decision**: Does feature require env vars, migrations, or breaking changes?

**Decision Flow**:
```
Does description mention deployment keywords?
(migration, alembic, schema change, env variable, breaking change, platform change, infrastructure, docker, deploy config)
├─ Yes → HAS_DEPLOYMENT_IMPACT = true (prompts deployment questions)
└─ No → HAS_DEPLOYMENT_IMPACT = false
```

**Examples**:
- "OAuth authentication (needs env vars)" → HAS_DEPLOYMENT_IMPACT = true ✅ (deployment keyword: env vars)
- "Add user table to database with migration" → HAS_DEPLOYMENT_IMPACT = true ✅ (deployment keyword: migration)
- "Change API response format (breaking change)" → HAS_DEPLOYMENT_IMPACT = true ✅ (deployment keyword: breaking change)
- "Add read-only dashboard screen" → HAS_DEPLOYMENT_IMPACT = false ❌ (no deployment keywords)
</has_deployment_impact_logic>
</classification_decision_tree>

<informed_guess_heuristics>
**Industry-standard defaults for non-critical technical decisions - use these instead of asking clarification questions**

<performance_targets>
**Performance Targets** (web applications)

**Defaults**:
- API response time: <500ms (95th percentile)
- Frontend First Contentful Paint (FCP): <1.5s
- Frontend Time to Interactive (TTI): <3.0s
- Database queries: <100ms average
- Lighthouse Performance Score: ≥85
- Lighthouse Accessibility Score: ≥95

**Document in spec.md**:
```markdown
## Performance Targets (Assumed)
- API endpoints: <500ms (95th percentile)
- Frontend FCP: <1.5s, TTI: <3.0s
- Lighthouse: Performance ≥85, Accessibility ≥95

_Assumption: Standard web application performance expectations applied._
```

**When NOT to use**: User explicitly mentions different targets, or feature is performance-critical (e.g., real-time systems)
</performance_targets>

<data_retention>
**Data Retention** (GDPR-compliant)

**Defaults**:
- User data: Indefinite with deletion option (user controls own data)
- Application logs: 90 days rolling retention
- Analytics data: 365 days aggregated (anonymized after 90 days)
- Temporary uploads: 24 hours
- Session data: 30 days inactive
- Error traces: 30 days

**Document in spec.md**:
```markdown
## Data Retention (Assumed)
- User profiles: Indefinite (user can delete anytime)
- Application logs: 90 days rolling
- Analytics data: 365 days aggregated

_Assumption: GDPR-compliant data retention applied. User controls own data._
```

**When NOT to use**: Healthcare (HIPAA), financial (SOX), or other regulated industries with specific retention requirements
</data_retention>

<error_handling>
**Error Handling** (user-friendly + debugging)

**Defaults**:
- User-friendly messages (no stack traces to end users)
- Error ID for support tracking (e.g., ERR-XXXX format)
- Full error details logged to error-log.md + monitoring system
- Graceful degradation where possible (show partial data if available)
- Retry with exponential backoff for transient failures (3 attempts: 1s, 2s, 4s delays)

**Document in spec.md**:
```markdown
## Error Handling (Assumed)
- User sees: Friendly message + Error ID (ERR-XXXX)
- System logs: Full error details + stack trace
- Retry: 3 attempts with exponential backoff for API/DB errors

_Assumption: Standard error handling patterns applied._
```

**When NOT to use**: Critical systems where users need detailed error info (e.g., developer tools, admin interfaces)
</error_handling>

<authentication_method>
**Authentication Method** (modern web apps)

**Defaults**:
- External users: OAuth2 (Google, GitHub providers)
- Internal users: Session-based with secure HTTP-only cookies
- API access: JWT bearer tokens (RS256 algorithm)
- MFA: Optional for regular users, required for admins
- Session duration: 30 days with auto-refresh

**Document in spec.md**:
```markdown
## Authentication (Assumed)
- User login: OAuth2 (Google, GitHub)
- API access: JWT bearer tokens
- Sessions: Secure HTTP-only cookies, 30-day expiry with auto-refresh

_Assumption: Standard OAuth2 flow for user authentication._
```

**When NOT to use**: Enterprise environments with specific SSO requirements (SAML, LDAP), or high-security environments requiring hardware tokens
</authentication_method>

<rate_limiting>
**Rate Limiting** (abuse prevention)

**Defaults**:
- Per user: 100 requests/minute
- Per IP: 1000 requests/minute
- Bulk operations: 10 operations/hour per user
- File uploads: 10 uploads/day per user
- API exports: 10 exports/day per user
- Response: HTTP 429 with Retry-After header

**Document in spec.md**:
```markdown
## Rate Limits (Assumed)
- User actions: 100 requests/minute
- Bulk operations: 10/hour per user
- CSV exports: 10/day per user

_Assumption: Conservative rate limits to prevent abuse._
```

**When NOT to use**: High-throughput systems (real-time analytics, IoT), or paid tiers with different limits
</rate_limiting>

<integration_patterns>
**Integration Patterns** (API design)

**Defaults**:
- API style: RESTful (unless GraphQL explicitly needed)
- Data format: JSON (unless CSV/XML explicitly needed)
- Pagination: Offset/limit with max 100 items per page
- Versioning: URL-based (/api/v1/...)
- CORS: Allowed from same domain + configured allowlist
- Compression: Gzip enabled for responses >1KB

**Document in spec.md**:
```markdown
## API Patterns (Assumed)
- REST endpoints with JSON format
- Pagination: Offset/limit (max 100 items)
- Versioning: URL-based (/api/v1/)

_Assumption: Standard RESTful API patterns applied._
```

**When NOT to use**: GraphQL-first architecture, or legacy systems requiring XML/SOAP
</integration_patterns>
</informed_guess_heuristics>

<clarification_prioritization_matrix>
**Prioritize clarifications by impact - only ask top 3 most critical**

<priority_categories>
| Category | Priority | Ask? | Rationale | Example |
|----------|----------|------|-----------|---------|
| **Scope boundary** | Critical | ✅ Always | Defines what's in/out of feature | "Does this include admin features or only user features?" |
| **Security/Privacy** | Critical | ✅ Always | Compliance and legal requirements | "Should PII be encrypted at rest?" |
| **Breaking changes** | Critical | ✅ Always | Impacts existing users/systems | "Is it okay to change the API response format?" |
| **User experience** | High | ✅ If ambiguous | Affects user satisfaction | "Should this be a modal or new page?" |
| **Performance SLA** | Medium | ❌ Use defaults | Has industry standards | "What's the target response time?" → Assume <500ms |
| **Technical stack** | Medium | ❌ Defer to plan | Planning-phase decision | "Which database?" → Decided during /plan |
| **Error messages** | Low | ❌ Use standard | Well-established patterns | "What error message?" → User-friendly + error ID |
| **Rate limits** | Low | ❌ Use defaults | Conservative defaults exist | "How many requests?" → 100/min default |
</priority_categories>

<prioritization_process>
**Process for limiting to 3 clarifications**:

1. **Identify all ambiguities** - List every unclear decision point
2. **Rank by category priority** - Assign Critical/High/Medium/Low based on table above
3. **Apply informed guesses to Medium/Low** - Use defaults from reference.md § Informed Guess Heuristics
4. **Keep top 3 Critical/High** - Only ask most impactful questions
5. **Document assumptions clearly** - Write assumed defaults in spec.md "Assumptions" section

**Example Scenario**:
```
5 potential clarifications identified:
1. [Critical - Scope] "Should dashboard show all students or only assigned classes?"
2. [Critical - Security] "Should student grades be encrypted at rest?"
3. [High - UX] "Should this be a modal or new page?"
4. [Medium - Performance] "What's the target load time?" → Assume <2s (use default)
5. [Low - Rate limit] "How many dashboard refreshes per minute?" → Assume 100/min (use default)

Result: Keep #1, #2, #3. Document #4, #5 as assumptions.
```
</prioritization_process>
</clarification_prioritization_matrix>

<slug_generation_rules>
**Generate clean, concise slugs that match roadmap entry format**

<normalization_logic>
**Filler Word Removal**:

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

  # Limit length to 50 characters
  cut -c1-50
```
</normalization_logic>

<slug_examples>
**Normalization Examples**:

| User Input | Generated Slug | Notes |
|-----------|----------------|-------|
| "We want to add student progress dashboard" | `student-progress-dashboard` | ✅ Clean (removed "we want to add") |
| "Get our Vercel and Railway app to a healthy state" | `vercel-railway-app-healthy-state` | ✅ Preserves technical terms |
| "Add user authentication with OAuth2" | `user-authentication-oauth2` | ✅ Preserves OAuth2 (technical term) |
| "Create a background worker to process uploads" | `background-worker-process-uploads` | ✅ Technical terms kept |
| "Implement the new dashboard for students" | `new-dashboard-students` | ✅ Removed "implement", "the", "for" |
</slug_examples>

<fuzzy_matching>
**Fuzzy Matching for Roadmap Integration**:

If exact slug not found in roadmap, suggest fuzzy matches:

```bash
# Levenshtein distance < 3 edits OR semantic similarity
# Example matches:
# - "student-dashboard" matches "student-progress-dashboard"
# - "auth" matches "authentication"
# - "api-endpoint" matches "api-endpoints"

# Implementation:
grep -i "student.*dashboard" .spec-flow/memory/roadmap.md
# Or use fzf for interactive fuzzy matching
```

**Offer user choice**:
```
No exact match for "student-dashboard"
Found similar roadmap entries:
  1. student-progress-dashboard (80% match)
  2. teacher-dashboard (60% match)

Use existing entry? (1/2/n):
```
</fuzzy_matching>
</slug_generation_rules>

<research_depth_guidelines>
**Select research depth based on feature complexity (FLAG_COUNT)**

<depth_minimal>
**Minimal Research** (FLAG_COUNT = 0) - 1-2 tools

**Use for**:
- Simple backend endpoint (no UI, no metrics, no deployment impact)
- Configuration change
- Minor bug fix

**Tools**:
1. Constitution check - Verify alignment with project mission/values
2. Grep similar patterns - Find existing code to replicate

**Example**:
```bash
# Simple backend endpoint: "Add GET /api/health endpoint"
grep -r "health.*endpoint" specs/*/spec.md
grep -r "GET.*api" api/app/routes/*.py
```

**Rationale**: Simple features don't need extensive research. Constitution + pattern search is sufficient.
</depth_minimal>

<depth_standard>
**Standard Research** (FLAG_COUNT = 1) - 3-5 tools

**Use for**:
- Single-aspect feature (UI-only OR backend-only)
- Standard CRUD operation
- Common integration pattern

**Tools**:
1-2. Minimal research (above)
3. UI inventory scan (if HAS_UI=true) - Check for reusable components
4. Performance budgets check - Verify targets align with constitution
5. Similar spec search - Find comparable features for pattern reuse

**Example**:
```bash
# UI-only feature: "Add student roster page"
grep -r "roster\|list" .spec-flow/templates/design-system/ui-inventory.md
grep -r "Performance.*budget" .spec-flow/memory/constitution.md
find specs/ -name "spec.md" -exec grep -l "list.*page" {} \;
```

**Rationale**: Single-aspect features benefit from component/pattern reuse but don't need deep research.
</depth_standard>

<depth_full>
**Full Research** (FLAG_COUNT ≥ 2) - 5-8 tools

**Use for**:
- Complex multi-aspect feature (UI + metrics + deployment)
- Novel pattern (no existing examples in codebase)
- Cross-cutting concern (affects multiple systems)

**Tools**:
1-5. Standard research (above)
6. Design inspirations check (if HAS_UI=true) - Web search for UX patterns
7. Web search for novel patterns - Research best practices
8. Deep dive on integration points - Identify system dependencies

**Example**:
```bash
# Complex feature: "Add OAuth authentication with analytics tracking"
# (HAS_UI=true, HAS_METRICS=true, HAS_DEPLOYMENT_IMPACT=true)

# Standard tools 1-5
grep -r "OAuth" specs/*/spec.md
grep -r "authentication.*flow" .spec-flow/templates/design-system/

# Additional tools 6-8
# WebSearch: "OAuth2 UX best practices"
# WebSearch: "authentication analytics tracking"
grep -rn "env.*OAUTH" .
```

**Rationale**: Complex features require comprehensive research to avoid architectural mistakes.
</depth_full>

<decision_criteria>
**Research Depth Decision Matrix**:

| FLAG_COUNT | Depth | Tools | Rationale |
|------------|-------|-------|-----------|
| 0 | Minimal | 1-2 | Simple feature, pattern search sufficient |
| 1 | Standard | 3-5 | Single aspect, need component/pattern reuse |
| ≥2 | Full | 5-8 | Multi-aspect, need comprehensive research |

**Over-research Prevention**:
- Don't use 8 tools for FLAG_COUNT = 0 (wastes time, exceeds token budget)
- Don't use 1 tool for FLAG_COUNT ≥ 2 (risks architectural mistakes)
- Follow guideline: more complexity → more research
</decision_criteria>
</research_depth_guidelines>

<common_mistakes>
**Anti-patterns and how to avoid them**

<too_many_research_tools>
**❌ Too Many Research Tools**

**Bad Example**:
```bash
# 15 research tools for simple backend endpoint (WRONG)
Glob *.py
Glob *.ts
Glob *.tsx
Grep "database"
Grep "model"
Grep "endpoint"
Grep "route"
Grep "service"
Grep "controller"
Grep "handler"
...10 more tools
```

**Good Example**:
```bash
# 2 research tools for simple backend endpoint (CORRECT)
grep "similar endpoint" specs/*/spec.md
grep "BaseModel" api/app/models/*.py
```

**Prevention**: Follow FLAG_COUNT guidelines (0→1-2 tools, 1→3-5 tools, ≥2→5-8 tools)
</too_many_research_tools>

<missing_roadmap_integration>
**❌ Missing Roadmap Integration**

**Bad Example**:
```bash
# Generate fresh spec without checking roadmap
SLUG="student-dashboard"
# No roadmap check - user had already documented requirements there
```

**Good Example**:
```bash
# Check roadmap first
SLUG="student-dashboard"
if grep -qi "^### ${SLUG}" .spec-flow/memory/roadmap.md; then
  FROM_ROADMAP=true
  # Reuse existing context (saves ~10 minutes)
fi
```

**Prevention**: Always run Step 2 (Check Roadmap Integration) before generating fresh spec
</missing_roadmap_integration>

<unclear_success_criteria>
**❌ Unclear Success Criteria**

**Bad Examples**:
```markdown
## Success Criteria
- System works correctly (not measurable)
- API is fast (not quantifiable)
- UI looks good (subjective)
```

**Good Examples**:
```markdown
## Success Criteria
- User can complete registration in <3 minutes (measured via PostHog funnel)
- API response time <500ms for 95th percentile (measured via Datadog APM)
- Lighthouse accessibility score ≥95 (measured via CI Lighthouse check)
```

**Prevention**: Every criterion must answer: "How do we measure this objectively?"
</unclear_success_criteria>

<technology_specific_criteria>
**❌ Technology-Specific Success Criteria**

**Bad Examples**:
```markdown
## Success Criteria
- React components render efficiently (technology-specific)
- Redis cache hit rate >80% (implementation detail)
- PostgreSQL queries use proper indexes (mechanism, not outcome)
```

**Good Examples** (outcome-focused):
```markdown
## Success Criteria
- Page load time <1.5s (First Contentful Paint)
- 95% of user searches return results in <1 second
- Database queries complete in <100ms average
```

**Prevention**: Focus on user-facing outcomes, not implementation mechanisms
</technology_specific_criteria>
</common_mistakes>

<performance_benchmarks>
**Expected metrics for specification phase execution**

<token_usage>
**Token Usage Estimates**:

- Minimal research (FLAG_COUNT=0): 8,000-12,000 tokens
- Standard research (FLAG_COUNT=1): 15,000-25,000 tokens
- Full research (FLAG_COUNT≥2): 30,000-50,000 tokens

**Token Budget**: 75,000 tokens allocated for specification phase (as per workflow constitution)

**Optimization**: Use FLAG_COUNT guidelines to avoid over-research and token waste
</token_usage>

<duration_estimates>
**Duration Estimates**:

- Minimal research: 5-8 minutes
- Standard research: 10-12 minutes
- Full research: 12-15 minutes

**Target**: ≤15 minutes total for specification phase

**Bottlenecks**:
- Over-research (too many tools): Adds 5-10 minutes unnecessarily
- Missing roadmap integration: Wastes 10 minutes re-documenting requirements
- Excessive clarifications (>3): Delays planning phase by 20-30 minutes
</duration_estimates>

<quality_metrics>
**Quality Targets**:

- Clarifications per spec: ≤3 (average: 1.5)
- Classification accuracy: ≥90%
- Success criteria measurability: 100%
- Rework rate: <5%
- Roadmap reuse rate: ≥30% (when roadmap exists)
</quality_metrics>
</performance_benchmarks>

<external_references>
**Links to external resources for deep dives**

- **Mermaid Diagrams**: Not applicable to specification phase (used in planning phase)
- **C4 Model**: Not applicable to specification phase (used in planning phase for architecture diagrams)
- **HEART Metrics Framework**: https://storage.googleapis.com/pub-tools-public-publication-data/pdf/36299.pdf (Google research paper on user-centered metrics)
- **Informed Guess Strategy**: Based on industry standards (OWASP, WCAG 2.1, REST API best practices)
- **OAuth2 Best Practices**: https://datatracker.ietf.org/doc/html/rfc6749 (OAuth 2.0 Authorization Framework)
</external_references>

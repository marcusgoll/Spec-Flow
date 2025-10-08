# Feature Specification: [FEATURE NAME]

**Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft

## User Scenarios

### Primary User Story
[Describe the main user journey in plain language]

### Acceptance Scenarios
1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

### Edge Cases
- What happens when [boundary condition]?
- How does system handle [error scenario]?

## Visual References

See `./visuals/README.md` for UI research and design patterns (if applicable)

## Success Metrics (HEART Framework)

> **Purpose**: Define quantified success criteria using Google's HEART framework.
> **Constraint**: All metrics MUST be Claude Code-measurable (SQL, logs, Lighthouse).

| Dimension | Goal | Signal | Metric | Target | Guardrail |
|-----------|------|--------|--------|--------|-----------|
| **Happiness** | [User satisfaction outcome] | [Observable behavior] | [Quantified measure] | [e.g., <2% error rate] | [e.g., P95 <500ms] |
| **Engagement** | [Depth of interaction] | [Usage pattern] | [Frequency/duration] | [e.g., 3+ sessions/week] | [e.g., <5min session] |
| **Adoption** | [New user activation] | [First-time usage] | [Signup/conversion rate] | [e.g., +20% signups] | [e.g., <$5 CAC] |
| **Retention** | [Repeat usage] | [Return visits] | [7-day return rate] | [e.g., 40% return] | [e.g., <10%/month churn] |
| **Task Success** | [Core job completed] | [Completion event] | [Success rate] | [e.g., 85% complete] | [e.g., <30s P95] |

**Performance Targets** (from `design/systems/budgets.md`):
- FCP <1.5s, TTI <3.5s, CLS <0.15, LCP <3.0s
- Lighthouse Performance ≥85, Accessibility ≥95

See `.spec-flow/templates/heart-metrics-template.md` for full measurement plan.

## Screens Inventory (UI Features Only)

> **Purpose**: Define screens for `/design-variations` workflow (Phase 1).
> **Skip if**: Feature has no UI components.

Screens to design:
1. **[screen-id]**: [Purpose] - Primary action: [CTA]
2. **[screen-id]**: [Purpose] - Primary action: [CTA]

States per screen: `default`, `loading`, `empty`, `error`

See `.spec-flow/templates/screens-yaml-template.yaml` for full screen definitions.

## Hypothesis

> **Purpose**: State the problem, solution, and predicted improvement.
> **Format**: Problem → Solution → Prediction (with magnitude)

**Problem**: [Current pain point with evidence]
- Evidence: [Metrics, logs, user feedback]
- Impact: [Who affected, how often]

**Solution**: [Proposed change]
- Change: [Specific UI/UX/feature modification]
- Mechanism: [Why this should work]

**Prediction**: [Specific, measurable outcome]
- Primary metric: [e.g., Time-to-insight <8s (currently 15s)]
- Expected improvement: [e.g., -47% reduction]
- Confidence: [Low | Medium | High]

**Example**: Inline preview (no redirect) will reduce time-to-insight from 15s to <8s by eliminating page load delays (-47% improvement).

## Context Strategy & Signal Design

- **System prompt altitude**: [Describe cue level and rationale]
- **Tool surface**: [Essential tools + why token-efficient]
- **Examples in scope**: [≤3 canonical examples]
- **Context budget**: [Target tokens + compaction trigger]
- **Retrieval strategy**: [JIT vs. upfront; identifiers]
- **Memory artifacts**: [NOTES.md, TODO.md update cadence]
- **Compaction cadence**: [Summaries every N turns]
- **Sub-agents**: [If used, scope + handoff contract]

## Requirements

### Functional (testable only)

- **FR-001**: System MUST [specific capability]
- **FR-002**: Users MUST be able to [key interaction]
- **FR-003**: System MUST [data requirement]

*Mark ambiguities:*
- **FR-XXX**: [NEEDS CLARIFICATION: specific question]

### Non-Functional

- **NFR-001**: Performance: [specific target with metrics]
- **NFR-002**: Accessibility: [compliance standard]
- **NFR-003**: Mobile: [responsive requirements]
- **NFR-004**: Error Handling: [user experience]

### Key Entities (if data involved)

- **[Entity]**: [Purpose, key attributes, relationships]

## Deployment Considerations

> **Purpose**: Document deployment constraints and dependencies for planning phase.
> **Skip if**: Purely cosmetic UI changes or documentation-only changes.

### Platform Dependencies

**Vercel** (marketing/app):
- [None / Edge middleware change for X / Ignored build step update]

**Railway** (API):
- [None / Dockerfile change: new base image / Start command change: add --workers flag]

**Dependencies**:
- [None / New: package-x@1.2.3 (requires Node 22+)]

### Environment Variables

**New Required Variables**:
- `NEXT_PUBLIC_FEATURE_FLAG_X`: [Description, staging value, production value]
- `API_KEY_Y`: [Description, staging value, production value]

**Changed Variables**:
- `NEXT_PUBLIC_API_URL`: [Format change from X to Y]

**Schema Update Required**: [Yes/No] - Update `secrets.schema.json` in `/plan` phase

### Breaking Changes

**API Contract Changes**:
- [No / Yes: Endpoint /v1/users → /v2/users requires version bump]

**Database Schema Changes**:
- [No / Yes: New table user_preferences]

**Auth Flow Modifications**:
- [No / Yes: Clerk multi-domain auth requires session token changes]

**Client Compatibility**:
- [Backward compatible / Requires client update / Feature flag gated]

### Migration Requirements

**Database Migrations**:
- [No / Yes: Add user_preferences table + backfill from users table]

**Data Backfill**:
- [Not required / Required: Backfill N existing users with default preferences]

**RLS Policy Changes**:
- [No / Yes: Add policy for user_preferences table (users can only see own)]

**Reversibility**:
- [Fully reversible / Special considerations: Must preserve old data for 30 days]

### Rollback Considerations

**Standard Rollback**:
- [Yes: 3-command rollback via runbook/rollback.md]

**Special Rollback Needs**:
- [None / Must downgrade migration first / Feature flag required for safe rollback / Client compatibility window (7 days)]

**Deployment Metadata**:
- [Deploy IDs tracked in specs/NNN-feature/NOTES.md (Deployment Metadata section)]

---

## Measurement Plan

> **Purpose**: Define how success will be measured using Claude Code-accessible sources.
> **Sources**: SQL queries, structured logs, Lighthouse CI, database aggregates.

### Data Collection

**Analytics Events** (dual instrumentation):
- PostHog (dashboards): `posthog.capture(event_name, properties)`
- Structured logs (Claude measurement): `logger.info({ event, ...props })`
- Database (A/B tests): `db.featureMetrics.create({ feature, variant, outcome, value })`

**Key Events to Track**:
1. `[feature].page_view` - Engagement
2. `[feature].[primary_action]` - Task Success
3. `[feature].completed` - Task Success (primary metric)
4. `[feature].error` - Happiness (inverse)
5. `[feature].abandoned` - Task Success (inverse)

### Measurement Queries

**SQL** (`specs/NNN-[feat]/design/queries/*.sql`):
- Task completion rate: `SELECT COUNT(*) FILTER (WHERE outcome='completed') * 100.0 / COUNT(*)`
- Time-to-insight: `SELECT PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY value) FROM feature_metrics`
- A/B test results: `SELECT variant, AVG(value), COUNT(*) FROM feature_metrics GROUP BY variant`

**Logs** (`logs/metrics/*.jsonl`):
- Event counts: `grep '"feature":"[slug]"' logs/metrics/*.jsonl | jq -r '.event' | sort | uniq -c`
- Error rate: `errors / total_events * 100`
- Duration P95: `jq -r '.duration' | sort -n | awk '{a[NR]=$1} END {print a[int(NR*0.95)]}'`

**Lighthouse** (`.lighthouseci/results/*.json`):
- Performance: `jq '.categories.performance.score'`
- FCP/TTI/CLS/LCP: `jq '.audits["first-contentful-paint"].numericValue'`

### Experiment Design (A/B Test)

**Variants**:
- Control: [Current experience]
- Treatment: [New experience with change]

**Ramp Plan**:
1. Internal (Days 1-3): Team only, ~10 users
2. 5% (Days 4-7): Random 5%, monitor errors
3. 25% (Days 8-14): Accumulate statistical power
4. 50% (Days 15-21): Validate at scale
5. 100% (Days 22+): Full rollout if positive

**Kill Switch**: Error rate >5% OR P95 >15s → instant rollback

**Sample Size**: ~385 users per variant (15% MDE, 80% power, α=0.05)

See `.spec-flow/templates/experiment-design-template.md` for full plan.

---

## Quality Gates *(all must pass before `/plan`)*

### Core Requirements
- [ ] No implementation details (tech stack, APIs, code)
- [ ] Requirements testable and unambiguous
- [ ] Context strategy documented
- [ ] No [NEEDS CLARIFICATION] markers
- [ ] Constitution aligned (performance, UX, data, access)

### Success Metrics (HEART)
- [ ] All 5 HEART dimensions have targets defined
- [ ] Metrics are Claude Code-measurable (SQL, logs, Lighthouse)
- [ ] Hypothesis is specific and testable
- [ ] Performance targets from budgets.md specified

### Screens (UI Features Only)
- [ ] All screens identified with primary actions
- [ ] States documented (default, loading, error, empty)
- [ ] System components from ui-inventory.md planned
- [ ] Skip if feature has no UI

### Measurement Plan
- [ ] Analytics events defined (PostHog + logs + DB)
- [ ] SQL queries drafted for key metrics
- [ ] Experiment design complete (control, treatment, ramp)
- [ ] Measurement sources are Claude Code-accessible

### Deployment Considerations
- [ ] Platform dependencies documented (Vercel, Railway, build tools)
- [ ] Environment variables listed (new/changed, with staging/production values)
- [ ] Breaking changes identified (API, schema, auth, client compatibility)
- [ ] Migration requirements documented (database, backfill, RLS, reversibility)
- [ ] Rollback plan specified (standard or special considerations)
- [ ] Skip if purely cosmetic UI changes or docs-only

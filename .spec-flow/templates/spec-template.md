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

## User Stories (Prioritized)

> **Purpose**: Break down feature into independently deliverable stories for MVP-first delivery.
> **Format**: [P1] = MVP (ship first), [P2] = Enhancement, [P3] = Nice-to-have

### Story Prioritization

**Priority 1 (MVP) 🎯**
- **US1** [P1]: As a [role], I want to [action] so that [benefit]
  - **Acceptance**: [Specific, testable criteria]
  - **Independent test**: [How to verify this story works standalone]
  - **Effort**: [XS/S/M/L/XL]

**Priority 2 (Enhancement)**
- **US2** [P2]: As a [role], I want to [action] so that [benefit]
  - **Acceptance**: [Specific, testable criteria]
  - **Depends on**: US1
  - **Effort**: [XS/S/M/L/XL]

**Priority 3 (Nice-to-have)**
- **US3** [P3]: As a [role], I want to [action] so that [benefit]
  - **Acceptance**: [Specific, testable criteria]
  - **Depends on**: US1, US2
  - **Effort**: [XS/S/M/L/XL]

**Effort Scale**:
- XS: <2 hours
- S: 2-4 hours
- M: 4-8 hours (½ day)
- L: 8-16 hours (1-2 days)
- XL: 16+ hours (>2 days, consider breaking down)

**MVP Strategy**: Ship US1 first, validate with users, then incrementally add US2, US3 based on feedback.

## Visual References

See `./visuals/README.md` for UI research and design patterns (if applicable)

## Success Metrics (HEART Framework)

> **SKIP IF**: No user behavior tracking needed (internal tools, infrastructure)
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

> **SKIP IF**: Backend-only feature (no UI components)
> **Purpose**: Define screens for `/design-variations` workflow (Phase 1).

Screens to design:
1. **[screen-id]**: [Purpose] - Primary action: [CTA]
2. **[screen-id]**: [Purpose] - Primary action: [CTA]

States per screen: `default`, `loading`, `empty`, `error`

See `.spec-flow/templates/screens-yaml-template.yaml` for full screen definitions.

## Hypothesis

> **SKIP IF**: New feature (not improving an existing flow)
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

> **SKIP IF**: No infrastructure changes (cosmetic UI, documentation-only)
> **Purpose**: Document deployment constraints and dependencies for planning phase.

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

## Quality Gates *(Must pass before `/plan`)*

### Core (Always Required)
- [ ] Requirements testable, no [NEEDS CLARIFICATION] markers
- [ ] Constitution aligned (performance, UX, data, access)
- [ ] No implementation details (tech stack, APIs, code)

### Conditional: Success Metrics (Skip if no user tracking)
- [ ] HEART metrics defined with Claude Code-measurable sources
- [ ] Hypothesis stated (Problem → Solution → Prediction)

### Conditional: UI Features (Skip if backend-only)
- [ ] All screens identified with states (default, loading, error)
- [ ] System components from ui-inventory.md planned

### Conditional: Deployment Impact (Skip if no infrastructure changes)
- [ ] Breaking changes identified (API, schema, migrations)
- [ ] Environment variables documented (staging + production values)
- [ ] Rollback plan specified

---

## Implementation Status

> **Purpose**: Track how implementation fulfills requirements, document deviations, and record actual performance.
> **Updated by**: `/implement` command during task execution
> **Last Updated**: [Auto-updated timestamp]

### Requirements Fulfilled

- ✅ **FR-001**: [Brief description] - Implemented in tasks T001-T003
- ✅ **FR-002**: [Brief description] - Implemented in task T004
- ⚠️ **FR-003**: [Brief description] - Deferred to P2 (see Deviations below)
- ❌ **FR-004**: [Brief description] - Not implemented (descoped, see Deviations)

### Deviations from Spec

**Format**: Document when implementation differs from original spec

- **Requirement [ID] ([Name])**: [What changed]
  - **Original approach**: [What spec specified]
  - **Actual implementation**: [What was built instead]
  - **Reason**: [Technical constraint, vendor change, user feedback, etc.]
  - **Impact**: [None | Minor | Requires spec update]
  - **Reference**: See `plan.md` [section] or `NOTES.md` [task]

**Example**:
- **Requirement FR-004 (Email verification)**: Vendor changed from Postmark to SendGrid
  - **Original approach**: Postmark API with custom templates
  - **Actual implementation**: SendGrid with dynamic templates
  - **Reason**: Postmark pricing increased 3x; SendGrid already used for transactional emails
  - **Impact**: Minor - same user experience, different provider
  - **Reference**: See `plan.md` Phase 0 research, decision logged in T015 notes

### Performance Actuals vs Targets

**Format**: Record actual performance compared to NFR targets

| Metric | Target | Actual | Status | Notes |
|--------|--------|--------|--------|-------|
| FCP | <1.5s | 1.2s | ✅ Pass | Exceeded target by 20% |
| TTI | <3.5s | 4.1s | ⚠️ Warning | +17% over target, acceptable for MVP |
| API P95 | <500ms | 450ms | ✅ Pass | - |
| Test Coverage | >80% | 92% | ✅ Pass | - |

### Lessons Learned

> **Populated by**: `/finalize` command at end of feature lifecycle
> **Purpose**: Capture insights for future features

- **What went well**: [Positive outcomes, efficient approaches]
- **What could improve**: [Bottlenecks, missteps, surprises]
- **Would do differently**: [Specific changes for next feature]

**Example**:
- **What went well**: TDD approach for auth flow reduced debugging time by ~40%
- **What could improve**: Initial schema design missed last_login column (discovered in T015), required migration
- **Would do differently**: Review schema with database-architect agent before starting tasks

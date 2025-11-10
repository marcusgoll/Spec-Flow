**Structure Decision**: [pick one with one-sentence rationale]

## Context Engineering Plan
- **Budget**: [token ceiling]; when to compact.
- **Token triage**: [resident vs on-demand retrieval].
- **Retrieval strategy**: [IDs, caching TTLs].
- **Memory artifacts**: [NOTES.md cadence].
- **Compaction & resets**: [when/how to summarize].
- **Sub-agent handoffs**: [scopes + summary contract].

---

## Phase 0: Codebase Scan & Research

### Existing Infrastructure — Reuse
- ✅ [ServiceName] (`[path]`)
- ✅ [MiddlewareName] (`[path]`)
- ✅ Pattern to follow: (`[path]`)

### New Infrastructure — Create
- 🆕 [NewService] (reason)
- 🆕 [NewIntegration] (reason)

### Research Findings
**Decision**: [final choice]
**Rationale**: [why chosen]
**Alternatives considered**: [A/B/C]
**Reuse**: [list concrete modules/paths]

**Output**: `research.md` with all **NEEDS CLARIFICATION** resolved or explicitly deferred with owners/dates.

---

## Phase 1: Design & Contracts

### Architecture Decisions
- **Stack**: [from research.md, not invented]
- **Communication**: [REST/GraphQL/WebSocket] with rationale
- **State management**: [SWR/React Query/Zustand/etc.]
- **Reuse vs build-new**: [why reusing X beats creating Y]

### Structure
- Directory layout (follow found patterns)
- Module boundaries & naming

### Schema
> Remove if no DB change.

- Tables/entities + relationships (Mermaid ERD)
- Migrations plan
- Indexing strategy
- RLS policies (if multi-tenant or PII)

### API Contracts (OpenAPI 3.1)
- One path per endpoint, request/response schemas from **JSON Schema 2020-12**
- **Errors**: all responses use **RFC 9457 Problem Details** (`type`, `title`, `status`, `detail`, `instance`)

### Security
> Remove if purely cosmetic UI.

- **Auth**: [Clerk/JWT/OAuth]
- **Authorization**: [RBAC/ABAC], matrix by role
- **Input validation**: [Zod/Pydantic] + strict JSON Schema
- **Rate limiting**: policy + responses (**429 per RFC 9110**)
- **ASVS mapping**: bullet list of requirements covered (level [1/2/3])

### Performance Targets
- Backend: <500ms p95; heavy ops offloaded to jobs/queues
- Frontend: FCP <1.5s, TTI <3s; initial bundle <200KB
- DB: queries <100ms; avoid N+1

### Artifacts Generated
1. `data-model.md` (entities, validation, relationships)
2. `contracts/api.yaml` (OpenAPI 3.1)
3. **Contract tests** (fail first)
4. `quickstart.md` (integration scenarios)
5. **Agent context**: NEW tech only

---

## Phase 2: Task Planning Approach
> Describes `/tasks` behavior; do not execute here.

**Generation**:
- Load `spec-flow/templates/tasks-template.md`
- Each contract → contract test [P]
- Each entity → model task [P]
- Each user story → integration test
- Impl tasks to make tests pass

**Ordering**:
- TDD: tests before impl
- Dependencies: models → services → UI
- Mark [P] for parallelizable items

**Estimated Output**: ~25–30 tasks in `tasks.md`.

---

## CI/CD & Quality Gates

**Pipelines**:
- **API**: contract tests + schema validation against OpenAPI 3.1
- **App**: Lighthouse CI with **performance budgets** enforced in CI
- **Smoke**: `/api/v1/[feature]/health` returns 200 and `{"status":"ok"}`

**Env/Secrets**:
- New: [LIST]
- Changed: [LIST]
- Update `secrets.schema.json`

**Migrations**:
- Reversible yes/no; dry-run required yes/no

**Platform**:
- Build-once promote-many; record deploy IDs in `NOTES.md`

---

## Rollout & Rollback

**Flags**:
- `[feature_x]` default OFF in production
- Staged rollout: 1% → 10% → 50% → 100% with metrics

**Observability**:
- Metrics: [p95 latency, error rate, conversion]
- Alerts: thresholds + oncall owner

**Rollback**:
- Trigger: [SLO breach / error rate spike]
- Command: [link to runbook + exact commands]
- Data migration mitigation (if any)

---

## Complexity Tracking
> Include only if deviating from constitution/KISS.

| Violation | Why Needed | Simpler Alternative Rejected |
|---|---|---|
| [Principle] | [Need] | [Why insufficient] |

---

## Progress Tracking

**Phase Gates**
- [ ] Phase 0: `research.md` ready
- [ ] Phase 1: `data-model.md`, `contracts/`, `quickstart.md`
- [ ] Phase 2: `tasks.md` strategy recorded
- [ ] Error ritual entry added (if any)
- [ ] Context plan documented

**Quality Gates**
- [ ] Constitution check: PASS
- [ ] Post-design check: PASS
- [ ] All clarifications resolved
- [ ] Complexity justified
- [ ] Stack alignment confirmed
- [ ] CI budgets configured

---

## Discovered Patterns
> To be updated during `/implement`.

### Reuse Additions
- ✅ **[Service.fn]** (`[path]:[lines]`)
  - Discovered in: T[ID]
  - Purpose:
  - Reusable for:
  - Why missed in Phase 0:

### Architecture Adjustments
- **[Change]**:
  - Original:
  - Actual:
  - Reason:
  - Migration:
  - Impact:

### Integration Discoveries
- **[Integration]**:
  - Component:
  - Dependency:
  - Reason:
  - Resolution:

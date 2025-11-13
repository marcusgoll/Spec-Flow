# Skill Dependencies Graph

**Purpose**: Document the relationships, dependencies, and integration points between all workflow skills.

**Last updated**: 2025-10-26

---

## Skill Hierarchy

### Phase-Based Skills (16 skills)

Execute workflow phases in fixed sequence:

```
Workflow Flow:
/feature
  |
  v
specification-phase (SKILL.md)
  |-- Depends on: project-docs-integration, hallucination-detector
  |-- Reads: roadmap-integration output, docs/project/overview.md, tech-stack.md, api-strategy.md, data-architecture.md
  |-- Outputs: spec.md, NOTES.md, visuals/README.md
  |
  v
clarification-phase (SKILL.md) [optional]
  |-- Depends on: None
  |-- Reads: spec.md
  |-- Outputs: Updated spec.md with clarifications
  |
  v
planning-phase (SKILL.md)
  |-- Depends on: project-docs-integration, hallucination-detector, anti-duplication, caching-strategy
  |-- Reads: spec.md, ALL 8 project docs
  |-- Outputs: plan.md, research.md, reuse-analysis.md
  |
  v
task-breakdown-phase (SKILL.md)
  |-- Depends on: tdd-enforcer, spec-compliance-validator
  |-- Reads: spec.md, plan.md
  |-- Outputs: tasks.md (20-30 tasks with TDD structure)
  |
  v
analysis-phase (SKILL.md)
  |-- Depends on: breaking-change-detector, spec-compliance-validator
  |-- Reads: spec.md, plan.md, tasks.md
  |-- Outputs: analysis-report.md
  |
  v
implementation-phase (SKILL.md)
  |-- Depends on: tdd-enforcer, anti-duplication, hallucination-detector, context-budget-enforcer, parallel-execution-optimizer,
  |               test-architect (TDD test generation - NEW v6.1.0),
  |               type-enforcer (TypeScript type safety - NEW v6.1.0),
  |               refactor-surgeon (complex refactorings - NEW v6.1.0),
  |               security-sentry (security validation - NEW v6.1.0, conditional)
  |-- Reads: tasks.md, plan.md, tech-stack.md
  |-- Outputs: Code files, test files, updated tasks.md
  |-- NEW Integration Points (v6.1.0):
      • test-architect: Invoked before implementing complex features (RED phase)
      • type-enforcer: Runs after task batches (TypeScript projects only)
      • refactor-surgeon: Handles complex REFACTOR phases (≥5 files affected)
      • security-sentry: Validates auth/API/file upload implementations (conditional)
  |
  v
optimization-phase (SKILL.md)
  |-- Depends on: parallel-execution-optimizer (5 parallel checks)
  |-- Reads: Implementation code, tests
  |-- Outputs: optimization-report.md, code-review-report.md
  |
  v
preview-phase (SKILL.md)
  |-- Depends on: None
  |-- Reads: optimization-report.md
  |-- Outputs: Manual UI/UX testing checklist, release-notes.md
  |
  v
staging-deployment-phase (SKILL.md) [if deployment model = staging-prod]
  |-- Depends on: deployment-safety, parallel-execution-optimizer (pre-flight checks)
  |-- Reads: workflow-state.yaml, deployment-strategy.md
  |-- Outputs: staging-ship-report.md, deployment-metadata.json
  |
  v
staging-validation-phase (SKILL.md) [if deployment model = staging-prod]
  |-- Depends on: deployment-safety (rollback testing)
  |-- Reads: staging-ship-report.md
  |-- Outputs: Staging sign-off summary
  |
  v
production-deployment-phase (SKILL.md)
  |-- Depends on: deployment-safety, git-workflow-enforcer
  |-- Reads: staging-validation summary, deployment-strategy.md
  |-- Outputs: production-ship-report.md, version tag, RELEASE_NOTES.md
  |
  v
finalize-phase (SKILL.md)
  |-- Depends on: roadmap-integration (mark shipped)
  |-- Reads: production-ship-report.md
  |-- Outputs: Updated roadmap, archived artifacts
```

---

### Cross-Cutting Skills (9 skills)

Apply across multiple phases:

#### **1. project-initialization-phase** (NEW)

**Purpose**: One-time project setup, creates all 8 project docs

**Dependencies**: None (entry point)

**Used by**:
- Manual `/init-project` command
- All downstream phase skills (read project docs created by this skill)

**Outputs**:
- `docs/project/overview.md`
- `docs/project/system-architecture.md`
- `docs/project/tech-stack.md`
- `docs/project/data-architecture.md`
- `docs/project/api-strategy.md`
- `docs/project/capacity-planning.md`
- `docs/project/deployment-strategy.md`
- `docs/project/development-workflow.md`

---

#### **2. project-docs-integration** (NEW)

**Purpose**: Ensure ALL workflow commands read relevant project docs before execution

**Dependencies**:
- Requires project-initialization-phase to have run (creates docs)

**Used by**:
- specification-phase (reads 4 docs)
- planning-phase (reads all 8 docs)
- implementation-phase (reads tech-stack.md)
- roadmap-integration (reads overview.md)

**Integration pattern**:
```bash
# Before /spec
project-docs-integration → reads overview, tech-stack, api-strategy, data-architecture
  |
  v
specification-phase → uses loaded docs to validate feature

# Before /plan
project-docs-integration → reads ALL 8 docs
  |
  v
planning-phase → uses docs to inform architecture decisions

# Before /implement
project-docs-integration → reads tech-stack.md
  |
  v
implementation-phase → validates tech choices against docs
```

---

#### **3. hallucination-detector** (NEW)

**Purpose**: Detect and prevent hallucinated technical decisions

**Dependencies**:
- Requires project-docs-integration (reads tech-stack.md, data-architecture.md, api-strategy.md)

**Used by**:
- specification-phase (tech stack validation)
- planning-phase (entity duplication check, API pattern validation)
- implementation-phase (framework validation)

**Validation checks**:
1. Tech stack validation (against tech-stack.md)
2. Entity duplication validation (against data-architecture.md)
3. API pattern validation (against api-strategy.md)
4. External service validation (against system-architecture.md)
5. Version compatibility validation

**Blocking behavior**: ❌ BLOCKS execution if violation detected

---

#### **4. breaking-change-detector** (NEW)

**Purpose**: Detect and warn about breaking API/schema changes

**Dependencies**:
- Requires api-strategy.md for versioning strategy

**Used by**:
- analysis-phase (validate plan against existing APIs)
- implementation-phase (detect breaking migrations)
- code review (pre-merge check)

**Breaking change types**:
- API: Removing endpoint, adding required field, changing HTTP method
- Database: DROP COLUMN, ADD NOT NULL without default, ALTER incompatible type
- Functions: Removing parameter, changing signature

**Blocking behavior**: ❌ BLOCKS by default, override with justification

---

#### **5. dependency-conflict-resolver** (NEW)

**Purpose**: Detect and resolve package dependency conflicts before installation

**Dependencies**:
- Requires tech-stack.md for documented dependency versions
- Uses caching-strategy for npm info caching

**Used by**:
- planning-phase (validate proposed dependencies)
- implementation-phase (before npm install / pip install)

**Conflict detection**:
1. Peer dependency conflicts (Node.js)
2. Version range conflicts (Python)
3. Security vulnerabilities (npm audit, pip-audit)
4. Conflicting transitive dependencies

**Blocking behavior**: ❌ BLOCKS installation if critical conflict, ⚠️ WARNS on minor conflicts

---

#### **6. anti-duplication**

**Purpose**: Prevent code duplication through reuse analysis

**Dependencies**:
- Requires planning-phase output (reuse-analysis.md)
- Uses caching-strategy for grep result caching
- Reads system-architecture.md for reusable components

**Used by**:
- planning-phase (identify reuse opportunities)
- implementation-phase (verify reuse before writing code)

**Reuse target**: ≥60% code reuse rate for standard features

**Updated integration** (NEW):
- Reads `system-architecture.md` for documented reusable components
- References `data-architecture.md` for existing entities
- Consults `api-strategy.md` for common API patterns

---

#### **7. tdd-enforcer**

**Purpose**: Enforce Test-Driven Development discipline (RED → GREEN → REFACTOR)

**Dependencies**:
- Requires development-workflow.md for testing standards
- Uses tech-stack.md for test framework validation

**Used by**:
- task-breakdown-phase (structure tasks as TDD triplets)
- implementation-phase (enforce RED → GREEN → REFACTOR)

**Coverage targets**: ≥80% for business logic (configurable in development-workflow.md)

**Updated integration** (NEW):
- Reads `development-workflow.md` for coverage targets
- Validates test framework against `tech-stack.md`
- Enforces documented TDD workflow from project docs

---

#### **8. deployment-safety**

**Purpose**: Prevent unsafe deployments through pre-flight validation and rollback testing

**Dependencies**:
- Requires deployment-strategy.md for deployment model
- Uses parallel-execution-optimizer for pre-flight checks

**Used by**:
- staging-deployment-phase (pre-flight validation)
- staging-validation-phase (rollback testing)
- production-deployment-phase (final safety checks)

**Deployment models**: staging-prod, direct-prod, local-only (auto-detected or configured)

**Updated integration** (NEW):
- Reads `deployment-strategy.md` for deployment model
- Validates against documented CI/CD workflow
- Enforces deployment gates from project docs

---

#### **9. roadmap-integration**

**Purpose**: Manage product roadmap via GitHub Issues with ICE prioritization

**Dependencies**:
- Requires overview.md for vision alignment
- Integrates with specification-phase (feature → spec handoff)

**Used by**:
- Manual `/roadmap` command
- finalize-phase (mark features as shipped)

**Vision alignment**: Validates new features against project vision and out-of-scope exclusions

**Updated integration** (NEW):
- Reads `overview.md` for vision, scope boundaries, target users
- Validates features before adding to roadmap
- BLOCKS out-of-scope features with override option

---

### Performance Skills (3 NEW skills)

Optimize workflow execution:

#### **1. context-budget-enforcer** (NEW)

**Purpose**: Monitor and enforce token budgets across workflow phases

**Dependencies**: None (low-level utility)

**Used by**:
- ALL phases (monitors token usage continuously)
- Automatically invokes before heavy operations

**Phase budgets**:
- Specification: 75K tokens
- Planning: 75K tokens
- Tasks: 50K tokens
- Implementation: 100K tokens
- Optimization: 125K tokens

**Compaction strategies**:
- Lightweight (30% reduction): Spec & Tasks phases
- Medium (60% reduction): Planning phase
- Heavy (90% reduction): Implementation & Optimization phases

**Integration**:
```bash
# Before any phase
context-budget-enforcer → check current usage vs budget
  |-- Over 80%? → auto-compact
  |
  v
Phase execution → within budget
```

---

#### **2. parallel-execution-optimizer** (NEW)

**Purpose**: Identify and execute independent operations in parallel for 3-5x speedup

**Dependencies**: None (low-level utility)

**Used by**:
- optimization-phase (5 parallel checks)
- staging-deployment-phase (5 parallel pre-flight checks)
- implementation-phase (intelligent task batching)
- ui-ux-design (parallel screen generation)

**Parallelization patterns**:
1. Independent checks (all-or-nothing)
2. Batch execution (dependency-aware)
3. Parallel research (independent queries)
4. Parallel screen generation

**Average speedup**: 3-5x for typical workflows

**Integration**:
```bash
# Optimization phase
parallel-execution-optimizer → analyze 5 checks (all independent)
  |
  v
Launch 5 parallel Task() calls
  |
  v
Aggregate results → total time = max(check durations) instead of sum
```

---

#### **3. caching-strategy** (NEW)

**Purpose**: Cache expensive operations to avoid redundant work

**Dependencies**: None (low-level utility)

**Used by**:
- project-docs-integration (cache project docs reads)
- dependency-conflict-resolver (cache npm info calls)
- anti-duplication (cache grep results)
- context-budget-enforcer (cache token counts)

**Cache categories**:
1. Project docs (15min TTL): 97% faster on hits
2. npm metadata (60min TTL): 99.5% faster on hits
3. Grep results (30min TTL): 98% faster on hits
4. Token counts (mtime-based): 95% faster on hits
5. Web searches (15min auto): Built-in to WebFetch

**Performance impact**: 20-40% workflow execution time reduction

**Integration**:
```bash
# Before reading project docs (e.g., in /spec, /plan, /implement)
caching-strategy → check if overview.md in cache
  |-- Cache hit? → return cached (10ms)
  |-- Cache miss? → read file (300ms), cache result
  |
  v
Phase execution → uses cached or fresh data
```

---

## Skill Dependency Graph (Visual)

```
PROJECT INITIALIZATION (ONE-TIME)
┌─────────────────────────────────────┐
│ project-initialization-phase        │
│ - Creates all 8 project docs        │
└───────────────┬─────────────────────┘
                |
                v
        ┌───────────────────┐
        │ docs/project/*.md │ (8 files)
        └───────┬───────────┘
                |
    ┌───────────┴────────────┐
    v                        v
CROSS-CUTTING            ROADMAP
┌─────────────────┐     ┌──────────────────────┐
│ project-docs-   │     │ roadmap-integration  │
│ integration     │     │ - Vision alignment   │
│ - Loads docs    │     └──────────────────────┘
└────┬────────────┘               |
     |                             |
     v                             v
┌────────────────────┐        ┌──────────┐
│ hallucination-     │        │ /roadmap │
│ detector           │        └──────────┘
│ - Tech validation  │
└─────┬──────────────┘
      |
      v
PHASE 1: SPECIFICATION
┌────────────────────────────┐
│ specification-phase        │
│ - Uses: project-docs-integration │
│ - Uses: hallucination-detector   │
└──────────┬─────────────────┘
           |
           v
PHASE 2: CLARIFICATION (optional)
┌────────────────────────────┐
│ clarification-phase        │
└──────────┬─────────────────┘
           |
           v
PHASE 3: PLANNING
┌────────────────────────────────────┐
│ planning-phase                     │
│ - Uses: project-docs-integration   │
│ - Uses: hallucination-detector     │
│ - Uses: anti-duplication           │
│ - Uses: caching-strategy           │
└──────────┬─────────────────────────┘
           |
           v
PHASE 4: TASK BREAKDOWN
┌────────────────────────────────────┐
│ task-breakdown-phase               │
│ - Uses: tdd-enforcer               │
│ - Uses: spec-compliance-validator  │
└──────────┬─────────────────────────┘
           |
           v
PHASE 5: ANALYSIS
┌────────────────────────────────────┐
│ analysis-phase                     │
│ - Uses: breaking-change-detector   │
│ - Uses: spec-compliance-validator  │
└──────────┬─────────────────────────┘
           |
           v
PHASE 6: IMPLEMENTATION
┌───────────────────────────────────────────┐
│ implementation-phase                      │
│ - Uses: tdd-enforcer                      │
│ - Uses: anti-duplication                  │
│ - Uses: hallucination-detector            │
│ - Uses: context-budget-enforcer           │
│ - Uses: parallel-execution-optimizer      │
│ - Uses: dependency-conflict-resolver      │
└──────────┬────────────────────────────────┘
           |
           v
PHASE 7: OPTIMIZATION
┌───────────────────────────────────────────┐
│ optimization-phase                        │
│ - Uses: parallel-execution-optimizer      │
│         (5 parallel checks)               │
└──────────┬────────────────────────────────┘
           |
           v
PHASE 8: PREVIEW
┌────────────────────────────┐
│ preview-phase              │
└──────────┬─────────────────┘
           |
           v
PHASE 9: DEPLOYMENT
┌─────────────────────────────────────────────┐
│ staging-deployment-phase                    │
│ - Uses: deployment-safety                   │
│ - Uses: parallel-execution-optimizer        │
│         (pre-flight checks)                 │
└──────────┬──────────────────────────────────┘
           |
           v
┌────────────────────────────────────────────┐
│ staging-validation-phase                   │
│ - Uses: deployment-safety (rollback test)  │
└──────────┬─────────────────────────────────┘
           |
           v
┌────────────────────────────────────────────┐
│ production-deployment-phase                │
│ - Uses: deployment-safety                  │
│ - Uses: git-workflow-enforcer              │
└──────────┬─────────────────────────────────┘
           |
           v
PHASE 10: FINALIZE
┌────────────────────────────────────────────┐
│ finalize-phase                             │
│ - Uses: roadmap-integration (mark shipped) │
└────────────────────────────────────────────┘
```

---

## Integration Patterns

### Pattern 1: Validation Chain

**Scenario**: Spec phase validates feature against all constraints

```
User request: "Add flight scheduling"
  |
  v
roadmap-integration → Vision alignment check
  |-- Reads overview.md
  |-- "Flight scheduling" in Out-of-Scope? → YES
  |-- ❌ BLOCK with options (Skip / Update overview / Override)
  |
  v (if override approved)
specification-phase → Begin spec creation
  |
  v
project-docs-integration → Load constraints
  |-- Reads: tech-stack.md, api-strategy.md, data-architecture.md
  |-- Caches results (caching-strategy)
  |
  v
hallucination-detector → Validate tech choices
  |-- Check: Using documented tech stack? → Django suggested, FastAPI documented
  |-- ❌ BLOCK: "Use FastAPI per tech-stack.md:12"
  |
  v (if all validations pass)
Spec created successfully
```

---

### Pattern 2: Performance Optimization Chain

**Scenario**: Planning phase with context budget management

```
/plan command starts
  |
  v
context-budget-enforcer → Check current budget
  |-- Current: 15K tokens (spec.md, NOTES.md)
  |-- Operation estimate: 50K (plan + research + 8 project docs)
  |-- Projected: 65K tokens
  |-- Budget: 75K tokens
  |-- 65K < 75K → ✅ Under budget, proceed
  |
  v
caching-strategy → Pre-warm project docs cache
  |-- Warm all 8 docs: ~2.4s upfront
  |-- All subsequent reads: 10ms (cache hits)
  |
  v
project-docs-integration → Load ALL 8 docs
  |-- Cache hits: 8 × 10ms = 80ms (instead of 8 × 300ms = 2.4s)
  |-- ✅ Savings: 2.32s
  |
  v
planning-phase → Generate plan + research
  |
  v (mid-operation)
context-budget-enforcer → Monitor token growth
  |-- Current: 55K tokens (plan halfway done)
  |-- Growth rate: 40K in 5 minutes
  |-- Projected final: 75K
  |-- Still under budget → ✅ Continue
  |
  v
Plan completed successfully
```

---

### Pattern 3: Parallel Execution Chain

**Scenario**: Optimization phase with 5 parallel checks

```
/optimize command starts
  |
  v
parallel-execution-optimizer → Analyze operations
  |-- 5 checks: Performance, Security, A11y, Code Review, Migrations
  |-- Dependencies? → None (all independent)
  |-- Pattern: Independent Checks (all-or-nothing)
  |
  v
Launch 5 parallel Task() calls
  ├─> Performance benchmarks (2min)
  ├─> Security scan (3min)
  ├─> Accessibility audit (2min)
  ├─> Code review (5min)
  └─> Migration validation (1min)
      |
      v
  Wait for all (max = 5min, not sum = 13min)
      |
      v
  Aggregate results
  |-- Critical issues? → YES in Security scan
  |-- ❌ BLOCK deployment
  |
  v
optimization-report.md created with critical issues
```

---

## Execution Order

### Cold Start (First Feature in Fresh Repo)

```
1. /init-project
   - project-initialization-phase creates 8 docs
   - Duration: 15-30 minutes (interactive questionnaire)

2. /roadmap add "Feature"
   - roadmap-integration reads overview.md
   - caching-strategy caches overview.md
   - Duration: 2-5 minutes

3. /feature "Feature"
   - context-budget-enforcer checks budget (empty, ✅ OK)
   - caching-strategy pre-warms project docs
   - specification-phase loads 4 docs (cache hits)
   - hallucination-detector validates tech stack
   - Duration: 10-15 minutes

4. /plan
   - context-budget-enforcer checks budget (15K used, ✅ OK)
   - project-docs-integration loads ALL 8 docs (cache hits)
   - planning-phase generates plan
   - anti-duplication analyzes reuse (first feature, minimal reuse)
   - Duration: 15-20 minutes

5. /tasks
   - tdd-enforcer structures tasks as TDD triplets
   - context-budget-enforcer checks budget (60K used, ✅ OK)
   - Duration: 5-10 minutes

6. /implement
   - context-budget-enforcer checks budget (70K used, ⚠️ 93%)
   - Auto-compact: Medium strategy (70K → 40K)
   - parallel-execution-optimizer batches tasks (4 batches)
   - hallucination-detector validates frameworks
   - dependency-conflict-resolver checks npm installs
   - tdd-enforcer enforces RED → GREEN → REFACTOR
   - Duration: 2-10 hours (depending on complexity)

7. /optimize
   - parallel-execution-optimizer runs 5 parallel checks
   - Duration: 5-10 minutes (vs 13+ minutes sequential)

8. /preview
   - Manual UI/UX testing
   - Duration: 15-30 minutes (human)

9. /ship
   - deployment-safety validates deployment model
   - parallel-execution-optimizer runs pre-flight checks
   - Duration: 10-15 minutes

10. /ship continue (after staging validation)
    - production-deployment-phase deploys to prod
    - finalize-phase marks feature shipped in roadmap
    - Duration: 5-10 minutes
```

**Total cold start**: ~4-12 hours (depending on feature complexity)

---

### Warm Start (Subsequent Features, Docs Exist)

```
1. /roadmap add "Feature"
   - Duration: 2-5 minutes (cache hits on overview.md)

2. /feature "Feature"
   - Duration: 5-10 minutes (cache hits on all project docs)

3. /plan
   - Duration: 10-15 minutes (cache hits, reuse opportunities detected)

4-10. Same as cold start but with:
   - Better cache hit rates (20-40% faster)
   - Higher code reuse (60%+ vs 10-20% first feature)
   - Fewer dependency conflicts (npm cache warmed)

Total warm start: ~3-8 hours (25-30% faster than cold start)
```

---

## Skill Coverage Map

### Which skills apply to which phases?

| Skill | Spec | Clarify | Plan | Tasks | Analysis | Impl | Optimize | Preview | Deploy | Finalize |
|-------|------|---------|------|-------|----------|------|----------|---------|--------|----------|
| **project-docs-integration** | ✅ | | ✅ | | | ✅ | | | | |
| **hallucination-detector** | ✅ | | ✅ | | | ✅ | | | | |
| **breaking-change-detector** | | | | | ✅ | ✅ | | | | |
| **dependency-conflict-resolver** | | | ✅ | | | ✅ | | | | |
| **anti-duplication** | | | ✅ | | | ✅ | | | | |
| **tdd-enforcer** | | | | ✅ | | ✅ | | | | |
| **deployment-safety** | | | | | | | | | ✅ | |
| **roadmap-integration** | | | | | | | | | | ✅ |
| **context-budget-enforcer** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | | |
| **parallel-execution-optimizer** | | | | | | ✅ | ✅ | | ✅ | |
| **caching-strategy** | ✅ | | ✅ | ✅ | | ✅ | | | | |

---

## Quality Gates Enforced by Skills

### Blocking Gates (❌ MUST pass)

1. **Vision Alignment** (roadmap-integration)
   - Feature not in out-of-scope list
   - Feature aligns with project vision
   - Phase: Roadmap

2. **Tech Stack Compliance** (hallucination-detector)
   - Use documented frameworks only
   - No alternative tech stack suggestions
   - Phases: Spec, Plan, Implementation

3. **Entity Duplication** (hallucination-detector)
   - No duplicate database entities
   - Reuse existing models
   - Phases: Plan, Implementation

4. **Breaking Changes** (breaking-change-detector)
   - No API endpoint removal without versioning
   - No database column drops without migration path
   - Phases: Analysis, Implementation

5. **Dependency Conflicts** (dependency-conflict-resolver)
   - Peer dependencies satisfied
   - No security vulnerabilities
   - Phases: Plan, Implementation

6. **TDD Discipline** (tdd-enforcer)
   - Tests before implementation
   - RED → GREEN → REFACTOR followed
   - Phase: Implementation

7. **Deployment Safety** (deployment-safety)
   - Pre-flight checks passed
   - Rollback capability verified
   - Phase: Deployment

### Warning Gates (⚠️ Can override)

1. **Code Reuse Rate** (anti-duplication)
   - Target: ≥60% reuse
   - Warning if <40%
   - Phases: Plan, Implementation

2. **Context Budget** (context-budget-enforcer)
   - Warning at 80% threshold
   - Auto-compact before overflow
   - All phases

3. **Test Coverage** (tdd-enforcer)
   - Target: ≥80%
   - Warning if <60%
   - Phase: Implementation

---

## Skill Metrics & Success Criteria

### Effectiveness Metrics

| Metric | Target | Measured By |
|--------|--------|-------------|
| **Hallucination Rate** | <5% | # tech violations / # suggestions |
| **Breaking Change Catch Rate** | >95% | # caught / # actual breaking changes |
| **Dependency Conflict Prevention** | >90% | # conflicts caught / # total installations |
| **Code Reuse Rate** | ≥60% | Lines reused / Total lines |
| **TDD Adherence** | 100% | # tests-first / # implementation tasks |
| **Test Coverage** | ≥80% | Coverage % for business logic |
| **Deployment Success Rate** | >98% | # successful deploys / # total deploys |

### Performance Metrics

| Metric | Target | Measured By |
|--------|--------|-------------|
| **Cache Hit Rate** | >70% | # cache hits / # total reads |
| **Parallel Speedup** | 3-5x | Sequential time / Parallel time |
| **Context Compaction Savings** | 60-90% | Tokens before / Tokens after |
| **Workflow Execution Time** | -30-40% | With optimizations vs without |

---

## Troubleshooting Skill Conflicts

### Conflict 1: Hallucination Detector Blocks, But User Insists

**Scenario**: User wants to use Django, but FastAPI documented

**Resolution**:
1. Hallucination detector blocks
2. Options presented:
   - A) Use FastAPI (documented tech)
   - B) Update tech-stack.md to Django
   - C) Override with justification
3. If B chosen: Update tech-stack.md, then proceed
4. If C chosen: Add note to spec, proceed with warning

---

### Conflict 2: Context Budget Exceeded After Compaction

**Scenario**: Heavy compaction still leaves context over budget

**Resolution**:
1. Context-budget-enforcer reports failure
2. Options:
   - A) Restart phase (lose progress, fresh context)
   - B) Continue with warning (risk OOM)
   - C) Split feature into smaller parts
3. Recommend C for features >100K tokens after compaction

---

### Conflict 3: Parallel Execution Failure (1 of 5 Checks Failed)

**Scenario**: Security scan fails while other 4 optimization checks pass

**Resolution**:
1. Parallel-execution-optimizer aggregates results
2. Identify failed check: Security scan
3. Block deployment (critical issue)
4. User fixes security issue
5. Re-run /optimize (only failed check, 3min vs 5min full run)

---

## Future Skill Additions

### Planned Skills (Roadmap)

1. **accessibility-compliance-validator** (ui-ux-design integration)
   - WCAG 2.1 AA validation
   - Lighthouse score ≥95 enforcement
   - Auto-fix suggestions

2. **performance-budget-enforcer** (optimization-phase integration)
   - Page load budget: <1.5s FCP
   - API response budget: <500ms p95
   - Bundle size budget: <200KB initial

3. **security-audit-automator** (optimization-phase integration)
   - OWASP Top 10 checks
   - Dependency vulnerability scanning
   - SQL injection / XSS detection

4. **contract-testing-enforcer** (implementation-phase integration)
   - API contract compliance (OpenAPI spec)
   - Consumer-driven contract tests
   - Breaking change detection via contracts

---

## References

- **Workflow architecture**: `docs/architecture.md`
- **Command definitions**: `.claude/commands/*.md`
- **Agent briefs**: `.claude/agents/**/*.md`
- **Skill files**: `.claude/skills/**/*.md`

---

_This dependency graph ensures skills integrate correctly and enforce quality gates throughout the workflow._

---
description: Run 15 parallel quality gates (core checks, E2E/visual, pre-CI validation, plus contracts/load/integrity for epics) with auto-retry for transient failures
allowed-tools: [Read, Bash, Task]
argument-hint: [feature-slug or empty for auto-detection]
version: 11.0
updated: 2025-12-09
---

# /optimize — Quality Gates Runner (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `optimize-phase-agent` via Task(). All quality gate logic runs in isolated context.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated optimize-phase-agent to run production-readiness quality gates.

**Architecture (v11.0 - Phase Isolation):**
```
/optimize → Task(optimize-phase-agent) → optimization-report.md
```

**Agent responsibilities:**
- Run 15 parallel quality checks
- Auto-retry transient failures (2-3 times)
- Generate optimization-report.md
- Return blocking issues or completion status

**Quality Gates** (15 checks, expandable to 18 for epics):
1-7: Core (performance, security, a11y, code review, migrations, docker, E2E)
8-15: Pre-CI (licenses, env vars, circular deps, dead code, dockerfile, deps, bundle, health)
16-18: Epic-only (contracts, load testing, migration integrity)

**Auto-Retry Logic**:
- Transient failures auto-retry with progressive delays
- Critical failures (security, breaking changes) block immediately

**Prerequisites**: `/implement` phase complete

**Workflow position**: `spec → clarify → plan → tasks → implement → optimize → ship`
</objective>

## Legacy Context (for agent reference)

<legacy_context>
Workflow Detection: Auto-detected via workspace files, branch pattern, or state.yaml

Current phase: Auto-detected from ${BASE_DIR}/\*/state.yaml

Implementation status: Auto-detected from ${BASE_DIR}/\*/state.yaml

Quality targets: Auto-detected from ${BASE_DIR}/\*/plan.md
</legacy_context>

<process>

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails: Use default (feature workflow with 6 gates)
4. Set gate count:
   - Feature: 6 core gates
   - Epic: 10 gates (core + enhanced)
5. Set `WORKFLOW_STATE="${BASE_DIR}/${SLUG}/state.yaml"`

---

### Step 0.1: LOAD USER PREFERENCES

**Load user preferences that affect quality gate behavior:**

```bash
# Load preference utility functions
source .spec-flow/scripts/utils/load-preferences.sh 2>/dev/null || true

# Load E2E visual testing preferences
E2E_ENABLED=$(get_preference_value --key "e2e_visual.enabled" --default "true")
E2E_FAILURE_MODE=$(get_preference_value --key "e2e_visual.failure_mode" --default "blocking")
E2E_THRESHOLD=$(get_preference_value --key "e2e_visual.threshold" --default "0.1")
E2E_AUTO_COMMIT=$(get_preference_value --key "e2e_visual.auto_commit_baselines" --default "true")

# Load automation preferences
AUTO_APPROVE_MINOR=$(get_preference_value --key "automation.auto_approve_minor_changes" --default "false")
CI_MODE=$(get_preference_value --key "automation.ci_mode_default" --default "false")

echo "User Preferences Loaded:"
echo "  E2E Testing: $( [ "$E2E_ENABLED" = "true" ] && echo "enabled" || echo "disabled" )"
echo "  E2E Failure Mode: $E2E_FAILURE_MODE"
echo "  Visual Threshold: ${E2E_THRESHOLD}%"
echo "  Auto-approve Minor: $AUTO_APPROVE_MINOR"
echo "  CI Mode: $CI_MODE"
```

**Preferences affecting quality gates:**

| Preference | Gate | Effect |
|------------|------|--------|
| `e2e_visual.enabled` | Gate 7 (E2E + Visual) | Skip gate if false |
| `e2e_visual.failure_mode` | Gate 7 | blocking=hard fail, warning=continue |
| `e2e_visual.threshold` | Gate 7 (Visual) | Pixel diff allowed (0.1=10%) |
| `automation.auto_approve_minor` | Code Review | Auto-approve formatting-only changes |
| `automation.ci_mode_default` | All gates | Non-interactive, assumes defaults |

---

### Step 0.5: ITERATION DETECTION (v3.0 - Feedback Loop Support)

**NEW**: Check if workflow is in iteration mode and adjust quality gate focus.

```bash
# Read workflow state to check iteration
if [ -f "$WORKFLOW_STATE" ]; then
    CURRENT_ITERATION=$(yq eval '.iteration.current' "$WORKFLOW_STATE" 2>/dev/null || echo "1")
    TOTAL_ITERATIONS=$(yq eval '.iteration.total_iterations' "$WORKFLOW_STATE" 2>/dev/null || echo "0")

    if [ "$CURRENT_ITERATION" -gt 1 ]; then
        echo "🔄 Iteration Mode Detected"
        echo "  Current iteration: $CURRENT_ITERATION"
        echo "  Previous iterations: $TOTAL_ITERATIONS"
        echo "  Quality gates will focus on:"
        echo "    - New code from iteration $CURRENT_ITERATION"
        echo "    - Regression checks for iteration 1-$((CURRENT_ITERATION - 1))"

        # Set iteration flag for focused testing
        ITERATION_MODE=true
        ITERATION_NUMBER=$CURRENT_ITERATION

        # Get list of files changed in current iteration
        # (Compare current HEAD with commit from iteration start)
        ITERATION_START_COMMIT=$(yq eval ".iteration.history[-1].completed_at" "$WORKFLOW_STATE" 2>/dev/null)
        if [ -n "$ITERATION_START_COMMIT" ]; then
            # Find commit closest to iteration start time
            BASELINE_COMMIT=$(git log --until="$ITERATION_START_COMMIT" --format="%H" -1)
            CHANGED_FILES=$(git diff --name-only "$BASELINE_COMMIT" HEAD)

            echo ""
            echo "Changed files in iteration $CURRENT_ITERATION:"
            echo "$CHANGED_FILES" | sed 's/^/    /'
        fi
    else
        echo "  Iteration: 1 (initial implementation)"
        ITERATION_MODE=false
        ITERATION_NUMBER=1
    fi
else
    # No workflow state file - default to iteration 1
    ITERATION_MODE=false
    ITERATION_NUMBER=1
fi
```

**Iteration-specific quality gates:**

When `ITERATION_MODE=true`, quality gates adjust their focus:

1. **Performance**:

   - Run benchmarks on **new code only** (iteration N functions/endpoints)
   - Check for performance **regressions** in iteration 1 code
   - Compare baseline metrics from iteration 1 vs current

2. **Security**:

   - Scan **new files** from iteration N
   - Re-scan dependencies (may have changed)
   - No regression scans needed (security is additive)

3. **Accessibility**:

   - Test **new UI components** from iteration N
   - Regression test: Run smoke tests on iteration 1 pages
   - Ensure no WCAG violations introduced

4. **Code Review**:

   - Lint/type check **changed files only**
   - Test coverage for **new code** must meet threshold
   - Overall project coverage should not decrease

5. **Migrations**:

   - Only if database changes in iteration N
   - Verify reversibility of new migrations only

6. **Docker Build**:
   - Full build (can't isolate to iteration)
   - Check image size hasn't increased significantly

**E2E Testing (Epic only)**:

- Run **full E2E suite** (can't isolate to iteration - integration risk)
- But focus failure investigation on iteration N changes

**Contract Validation (Epic only)**:

- Validate **new/modified contracts** only
- Check for breaking changes in existing contracts

**Load Testing (Epic only)**:

- Run **full load test** (system-wide performance)
- Compare results to iteration 1 baseline
- Alert if p95 latency increased >10%

**Migration Integrity (Epic only)**:

- Test **new migrations** only
- Verify data integrity for iteration N schema changes

**Report naming:**

- Iteration 1: `optimization-report.md`
- Iteration 2+: `optimization-report-iteration-{N}.md`

**Performance:**

- Iteration 2+ runs **faster** (fewer files to check)
- Typical speedup: 40-60% reduction in quality gate time
- Example: Iteration 1 optimize: 15 min, Iteration 2: 6 min

---

### Step 0.75: Clean Up HTML Blueprint Mockups

**Before running quality gates**, remove all HTML blueprint mockups to ensure they don't reach production:

```bash
# Check if mockups directory exists
if [ -d "${BASE_DIR}/${SLUG}/mockups" ]; then
    echo "🧹 Cleaning up HTML blueprint mockups..."
    bash .spec-flow/scripts/bash/cleanup-mockups.sh
    echo "✅ Mockups removed - TSX components are the single source of truth"
fi
```

**Cleanup behavior**:

- Deletes entire `mockups/` directory
- Preserves `blueprint-patterns.md` for reference (if exists)
- Ensures no HTML mockups reach production deployment
- Only runs if mockups directory exists (safe for non-frontend epics)

**Why cleanup before /optimize**:

- Quality gates validate production code (TSX components)
- HTML blueprints are development artifacts, not production code
- Prevents accidental deployment of mockup files
- Ensures clean workspace for deployment pipeline

---

### Step 0.8: Initialize Multi-Agent Voting System

**NEW (v10.16)**: Initialize voting system for quality gates if enabled.

```bash
# Check if voting configuration exists
if [ -f ".spec-flow/config/voting.yaml" ]; then
    echo "🗳️  Multi-agent voting enabled"

    # Source voting engine functions
    if [ -f ".claude/skills/multi-agent-voting/voting-engine.sh" ]; then
        source .claude/skills/multi-agent-voting/voting-engine.sh

        # Check dependencies (yq, python3, bc)
        check_dependencies

        VOTING_ENABLED=true
        echo "  ✓ Voting engine loaded"
        echo "  ✓ Operations with voting: code_review, security_review, breaking_change_detection"
        echo ""
    else
        echo "  ⚠ voting-engine.sh not found, falling back to single-agent"
        VOTING_ENABLED=false
    fi
else
    VOTING_ENABLED=false
fi
```

**Voting-enabled operations:**

When `VOTING_ENABLED=true`, the following quality gates use multi-agent voting:

| Gate | Strategy | Agents | k | Benefit |
|------|----------|--------|---|---------|
| Gate 4: Code Review | first_to_ahead_by_k | 3 | 2 | Error decorrelation, higher accuracy |
| Gate 2: Security Review | unanimous | 3 | - | All agents must agree (safety first) |
| Gate 16: Breaking Changes | first_to_ahead_by_k | 3 | 2 | Consensus on API compatibility |

**Voting disabled fallback:**

If voting is disabled (missing config or engine), gates use single specialist agents as before. No functionality loss, just less accuracy.

**Error decorrelation:**

Voting uses temperature variation (0.5, 0.7, 0.9) to decorrelate errors across agents. Based on MAKER paper's findings that diverse sampling improves aggregate accuracy.

---

### Step 1: Execute Optimization Workflow

1. **Execute optimization workflow** via spec-cli.py:

   ```bash
   python .spec-flow/scripts/spec-cli.py optimize "$ARGUMENTS"
   ```

   The optimize-workflow.sh script performs:

   a. **Pre-checks**: Validates environment, feature state, implementation complete

   b. **Extract targets**: Reads quality targets from plan.md (performance, security, accessibility, load testing)

   c. **Parallel checks**: Runs all 10 checks concurrently:

   **Core checks (1-6)**:

   - **Performance**: Backend benchmarks, Lighthouse, bundle size
   - **Security**: Bandit, Safety, pnpm audit, security tests
   - **Accessibility**: jest-axe, Lighthouse A11y (WCAG 2.2 AA default)
   - **Code review**: Lints (ESLint, Ruff), type checks (TypeScript, mypy), tests
   - **Migrations**: Reversibility check (downgrade() exists), drift-free (alembic check)
   - **Docker Build**: Validates Dockerfile builds (skipped if no Dockerfile)

   **Enhanced checks (7-10)** - Epic workflows only:

   - **E2E Testing**:

     - Read e2e-tests.md (generated in /tasks phase)
     - Run E2E tests for each critical user journey
     - Test external integrations (GitHub CLI, APIs, webhooks)
     - Verify outcomes in production systems (commits, DB records)
     - Use Docker for isolated testing
     - Auto-retry: restart-services, check-ports, re-run-flaky-tests

   - **Contract Validation**:

     - Find all contracts in contracts/\*.yaml
     - Verify endpoints exist in codebase
     - Validate request/response schemas match OpenAPI
     - Run Pact CDC tests if present
     - Check for contract drift
     - Auto-retry: regenerate-schemas, sync-contracts, re-run-contract-tests

   - **Load Testing** (optional - only if plan.md mentions "load test" or "concurrent users"):

     - Run k6, artillery, or locust tests
     - Default: 100 VUs, 30s duration
     - Check p95 latency < target (from capacity-planning.md)
     - Verify error rate < 1%
     - Validate throughput meets target RPS
     - Auto-retry: warm-up-services, scale-up-resources, optimize-db-connections

   - **Migration Integrity**:
     - Find migration files (alembic, knex, prisma)
     - Run migration up (upgrade head)
     - Capture database state (row counts, checksums)
     - Run integrity checks (no orphaned records, FK intact)
     - Run migration down (downgrade -1)
     - Verify data restored correctly
     - Auto-retry: reset-test-db, re-run-migration, fix-seed-data

   d. **Auto-retry logic** (for transient failures):

   ```javascript
   function classifyFailure(gateName, errorOutput) {
     // Critical: Block immediately (no retry)
     if (isCritical) return { type: "critical", strategies: [] };

     // Fixable: Auto-retry 2-3 times
     return { type: "fixable", strategies: [strategy1, strategy2, ...] };
   }

   function attemptAutoFix(gateName, strategies) {
     for (let attempt = 1; attempt <= 3; attempt++) {
       for (const strategy of strategies) {
         if (executeStrategy(strategy).success) {
           return { success: true, strategy, attempts: attempt };
         }
       }
       sleep(attempt * 5); // Progressive delay: 5s, 10s, 15s
     }
     return { success: false, reason: "All strategies exhausted" };
   }
   ```

   e. **Aggregate results**: Collects pass/fail status from each check (after auto-retry attempts)

   f. **Deploy hygiene**: Warns if artifact strategy missing from plan.md

   g. **Final decision**: PASS (ready for /preview) or FAIL (fix blockers first)

2. **Review optimization results** from generated files:

   **Core checks (1-6)**:

   - `specs/*/optimization-performance.md`
   - `specs/*/optimization-security.md`
   - `specs/*/optimization-accessibility.md`
   - `specs/*/code-review.md`
   - `specs/*/optimization-migrations.md`
   - `specs/*/optimization-docker.md`

   **Enhanced checks (7-10)** - Epic workflows:

   - `epics/*/e2e-test-results.log`
   - `epics/*/contract-validation-report.md`
   - `epics/*/load-test-results.log` (optional)
   - `epics/*/migration-integrity-report.md`

3. **Analyze blockers** and determine severity:

   - **CRITICAL** (Block immediately, no retry):

     - Security High/Critical findings
     - Type errors
     - Migration not reversible
     - Docker build failed
     - Contract breaking changes
     - Data corruption in migration integrity checks

   - **HIGH** (Block after auto-retry):

     - Accessibility score < 95
     - Linting errors
     - Test failures (unit/integration)
     - E2E test failures (not flaky)
     - Contract drift (non-breaking but significant)
     - Load test p95 > target (if target specified)

   - **MEDIUM** (Warning, can proceed):

     - Performance targets missed (soft targets)
     - Flaky E2E tests (passed after retry)
     - Load testing not run (optional)

   - **LOW** (Info only):
     - Deploy hygiene warnings (artifact strategy missing)
     - Migration integrity skipped (no migrations)

4. **Epic workflows only** (v5.0+): Run workflow audit if quality gates passed

   - Invoke /audit-workflow for phase efficiency and velocity analysis
   - Load audit results from audit-report.xml
   - Offer workflow healing via /heal-workflow if improvements available
   - Track pattern detection across epics (if 2-3+ completed)

5. **Present results** to user with clear next action
   </process>

<verification>
Before completing, verify:
- All quality gate result files exist (6 core + 4 enhanced for epics)
- Each result file has Status: PASSED/FAILED/SKIPPED
- Auto-retry attempts logged for fixable failures
- Blockers are clearly identified with severity (CRITICAL, HIGH, MEDIUM, LOW)
- User knows exact next action (fix blockers or proceed to /preview)
- Script exit code matches result (0 = passed, 1 = failed)
- Epic workflows: E2E tests, contracts, load tests (if applicable), migration integrity all checked
</verification>

<success_criteria>
**Core checks (1-6) - All workflows**:

- Performance: Targets met or no targets specified
- Security: No Critical/High findings
- Accessibility: WCAG level met, Lighthouse ≥ 95 (if measured)
- Code Quality: Lints, types, tests pass
- Migrations: Reversible and drift-free (or skipped)
- Docker Build: Builds successfully (or skipped if no Dockerfile)

**Enhanced checks (7-10) - Epic workflows**:

- E2E Testing: All critical user journeys pass (after auto-retry if needed)
- Contract Validation: All contracts implemented, no breaking changes, CDC tests pass
- Load Testing: p95 < target, error rate < 1% (or skipped if not required)
- Migration Integrity: No data corruption, rollback restores data correctly

**General**:

- Auto-retry attempts logged for transparency
- Workflow state updated to completed (if passed) or failed (if blockers)
  </success_criteria>

<output>
**If all checks pass**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Optimization PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Core Quality Gates (1-7):
✅ Performance: PASSED
✅ Security: PASSED
✅ Accessibility: PASSED
✅ Code Review: PASSED
✅ Migrations: PASSED
✅ Docker Build: PASSED (or SKIPPED)
✅ E2E + Visual: PASSED (or SKIPPED)

Pre-CI Validation Gates (8-15):
✅ License Compliance: PASSED
✅ Environment Validation: PASSED
✅ Circular Dependencies: PASSED
✅ Dead Code Detection: PASSED
✅ Dockerfile Best Practices: PASSED (or SKIPPED)
⚠️ Dependency Freshness: 3 outdated (non-blocking)
✅ Bundle Size: 420KB (under threshold)
✅ Health Check: PASSED

{IF epic workflow}
Enhanced Validation Gates (16-18):
✅ Contract Validation: PASSED (5 contracts compliant)
✅ Load Testing: PASSED (p95: 180ms, error rate: 0.1%) [or SKIPPED]
✅ Migration Integrity: PASSED (no data corruption)

{IF auto_retry_used}
Auto-Retry Summary:
🔄 E2E tests: 1 retry (flaky test recovered)
🔄 Load tests: 2 retries (warm-up required)
{ENDIF}

Workflow Audit Results:
Overall Score: {audit_score}/100
Phase Efficiency: {phase_efficiency}/100
Sprint Parallelization: {parallelization_score}/100
Velocity Multiplier: {velocity_multiplier}x
Bottlenecks: {bottlenecks_count}
Recommendations: {recommendations_count}

{IF recommendations > 0}
💡 Workflow improvements available
Run /heal-workflow to apply immediate improvements
{ENDIF}
{ENDIF}

All quality gates passed. Ready for /preview

```

**If any checks fail**:
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Optimization FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Core Quality Gates (1-7):
❌ Performance: FAILED (Lighthouse performance: 65/100, target: 85)
✅ Security: PASSED
❌ Accessibility: FAILED (Color contrast violations: 3 issues)
❌ Code Review: FAILED (TypeScript errors: 12)
✅ Migrations: PASSED
❌ Docker Build: FAILED (Build timeout after 10 minutes)
❌ E2E + Visual: FAILED (User registration journey failed)

Pre-CI Validation Gates (8-15):
❌ License Compliance: FAILED (GPL dependency: node-gpl-lib)
✅ Environment Validation: PASSED
❌ Circular Dependencies: FAILED (5 import cycles detected)
⚠️ Dead Code Detection: 8 unused exports (under threshold)
✅ Dockerfile Best Practices: PASSED
⚠️ Dependency Freshness: 12 outdated (non-blocking)
❌ Bundle Size: 680KB (exceeds 500KB threshold)
⚠️ Health Check: No /health endpoint found

{IF epic workflow}
Enhanced Validation Gates (16-18):
✅ Contract Validation: PASSED (5 contracts compliant)
⚠️ Load Testing: SKIPPED (not required for this epic)
❌ Migration Integrity: FAILED (Data corruption detected in rollback)

Auto-Retry Summary:
🔄 E2E tests: 3 retries exhausted (still failing after restart-services, check-ports)
🔄 Docker Build: 2 retries exhausted (still failing after clear-cache, rebuild)
✅ Migration Integrity: 1 retry succeeded (reset-test-db strategy worked)
{ENDIF}

CRITICAL Blockers (must fix):

- TypeScript errors (12 issues) - code-review.md
- E2E test failure (user registration) - e2e-test-results.log
- Migration data corruption - migration-integrity-report.md

HIGH Blockers (fix before deployment):

- Accessibility violations (3 issues) - optimization-accessibility.md
- Docker build timeout - optimization-docker.md

MEDIUM Warnings (can proceed with caution):

- Performance below target (65/100, target 85/100) - optimization-performance.md

Report Files:

- specs/{slug}/optimization-performance.md
- specs/{slug}/optimization-accessibility.md
- specs/{slug}/code-review.md
- specs/{slug}/optimization-docker.md
- epics/{slug}/e2e-test-results.log
- epics/{slug}/migration-integrity-report.md

Fix the blockers above and re-run /optimize

```
</output>

<actionable_fixes>
**For each blocker type, provide specific guidance**:

### Security Blocker
```

❌ Security check failed

Critical/High findings: {count}

View logs:
cat specs/{slug}/security-backend.log
cat specs/{slug}/security-deps.log
cat specs/{slug}/security-frontend.log

Fix:

1. Update vulnerable dependencies
2. Address static analysis warnings
3. Re-run /optimize

```

### Type Check Blocker
```

❌ Code review failed (type errors)

View errors:
cat specs/{slug}/tsc.log
cat specs/{slug}/mypy.log

Fix type errors and re-run /optimize

```

### Accessibility Blocker
```

❌ Accessibility check failed

Lighthouse A11y score: {score} / 100 (threshold: 95)

View report:
cat specs/{slug}/lh-perf.json | jq '.categories.accessibility'

Check specific failures:
cat specs/{slug}/lh-perf.json | jq '.audits | to_entries | .[] | select(.value.score < 1) | {key, title: .value.title, score: .value.score}'

Fix issues and re-run /optimize

```

### Migration Blocker
```

❌ Migrations check failed

Issue: Migration not reversible

Find migrations without downgrade:
cd api
grep -L "def downgrade" alembic/versions/\*.py

Add downgrade() function and re-run /optimize

```

### Docker Build Blocker
```

❌ Docker build check failed

View build output:
cat specs/{slug}/docker-build.log

Common issues:

- Missing dependencies in Dockerfile
- Invalid base image
- Copy command referencing non-existent files
- Build arguments not defined

Fix Dockerfile and re-run /optimize

```
</actionable_fixes>

<next_action>
**If passed**:
```

Next: /preview

Manual UI/UX testing and backend validation before shipping

```

**If failed**:
```

Next: Fix blockers listed above, then re-run /optimize

All checks are idempotent (safe to re-run multiple times)

````
</next_action>

<epic_workflow_integration>
**Epic workflows only** (v5.0+):

When /optimize detects an epic workflow (presence of `epics/*/sprint-plan.md`), it integrates workflow audit after quality gates pass.

### Workflow Audit Integration

**Invocation**:
```bash
# Only run if quality gates passed
if [ "${#BLOCKERS[@]}" -eq 0 ]; then
  /audit-workflow
fi
````

**Audit analyzes**:

- Phase efficiency (time spent per phase)
- Sprint parallelization effectiveness
- Bottleneck detection (critical path analysis)
- Quality gate pass rates
- Documentation quality
- Pattern detection (after 2-3 epics)

**Results integration**:

```javascript
const optimizationSummary = {
  quality_gates: { ... },
  workflow_audit: {
    overall_score: auditSummary.overall_score,
    phase_efficiency: auditSummary.phase_efficiency,
    sprint_parallelization: auditSummary.sprint_parallelization,
    velocity_multiplier: auditSummary.velocity_impact,
    bottlenecks_count: auditSummary.bottlenecks.length,
    recommendations_count: auditSummary.recommendations.length
  }
};
```

**Workflow healing**:
If audit recommends improvements, offer /heal-workflow:

- Immediate improvements: Apply now for current epic
- Deferred improvements: Apply after 2-3 epics for pattern-based optimization

See .claude/skills/optimization-phase/reference.md for detailed audit integration workflow.
</epic_workflow_integration>

<standards>
**Industry Standards**:
- **Performance**: [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/)
- **Security**: [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)
- **Accessibility**: [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
- **Migrations**: [Alembic Best Practices](https://alembic.sqlalchemy.org/en/latest/tutorial.html)
- **Deploy Hygiene**: [Twelve-Factor App](https://12factor.net/build-release-run)

**Workflow Standards**:

- All checks write result files (no vibes-based decisions)
- Hard blockers are crisp (Security High/Critical, A11y fail, type errors, unreversible migrations)
- Idempotent execution (safe to re-run multiple times)
- Graceful degradation for optional tools (Lighthouse, Docker)
  </standards>

<notes>
**Script locations**:
- Core gates: `.spec-flow/scripts/bash/optimize-workflow.sh`
- Pre-CI gates (8-15): `.spec-flow/scripts/bash/check-pre-ci.sh`

Both are invoked via spec-cli.py for cross-platform compatibility.

**Reference documentation**: Detailed quality gate criteria, error recovery procedures, and alternative modes are documented in `.claude/skills/optimization-phase/reference.md`.

**Result files**:
- Core checks: `specs/{slug}/optimization-*.md`, `specs/{slug}/code-review.md`
- Pre-CI checks: `specs/{slug}/pre-ci-report.md`

All files include Status: PASSED/FAILED/SKIPPED.

**Log files**: Detailed logs are written to `specs/{slug}/*.log` for debugging failures.

**Idempotency**: Re-running /optimize is safe. All checks overwrite previous results.

**Tech stack detection**: Pre-CI gates auto-detect project type (Node.js, Python, Docker, Frontend) and run appropriate tools. Checks gracefully skip if tools aren't installed.
</notes>

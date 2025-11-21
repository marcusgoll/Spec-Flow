---
description: Run 10 parallel quality gates (performance, security, accessibility, code review, migrations, Docker, E2E, contracts, load testing, migration integrity) with auto-retry for transient failures
allowed-tools: [Bash(python .spec-flow/scripts/spec-cli.py optimize:*), Bash(cat *), Bash(grep *), Bash(jq *), Read, Grep, Glob]
argument-hint: [feature-slug or empty for auto-detection]
---

<context>
Workflow Detection: Auto-detected via workspace files, branch pattern, or workflow-state.yaml

Current phase: Auto-detected from ${BASE_DIR}/*/workflow-state.yaml

Implementation status: Auto-detected from ${BASE_DIR}/*/workflow-state.yaml

Quality targets: Auto-detected from ${BASE_DIR}/*/plan.md

WCAG requirements: Auto-detected from ${BASE_DIR}/*/plan.md
</context>

<objective>
Run fast, parallel production-readiness checks with auto-retry logic for transient failures, and block deployment if any hard blockers are found.

This command validates features meet production quality standards across 10 parallel checks:

**Core Quality Gates** (Checks 1-6 - All workflows):
1. **Performance** - Backend benchmarks, frontend Lighthouse, bundle size
2. **Security** - Static analysis (Bandit/Ruff), dependency audit (Safety/pnpm), security tests
3. **Accessibility** - WCAG compliance via jest-axe and Lighthouse A11y
4. **Code Review** - Lints, type checks, test coverage
5. **Migrations** - Reversibility and drift-free validation
6. **Docker Build** - Validates Dockerfile builds successfully (skipped if no Dockerfile)

**Enhanced Validation Gates** (Checks 7-10 - Epic workflows):
7. **E2E Testing** - Complete user workflow validation from start to finish, external integration testing
8. **Contract Validation** - API contract compliance (OpenAPI schemas), contract tests (Pact CDC)
9. **Load Testing** - Performance under production-like load (100 VUs, 30s duration)
10. **Migration Integrity** - Data integrity validation during up/down migrations, no data corruption

**Auto-Retry Logic**:
- Transient failures (flaky tests, timing issues) auto-retry 2-3 times
- Critical failures (security, breaking changes) block immediately
- Progressive delays: 5s, 10s, 15s between retries

**Prerequisites**:
- `/implement` or `/implement-epic` phase complete
- Feature directory exists with plan.md
- Epic workflows: e2e-tests.md generated (from /tasks phase)

**Risk Level**: 🟡 MEDIUM - Blocks deployment if quality gates fail (after auto-retry attempts)
</objective>

<process>

### Step 0: WORKFLOW TYPE DETECTION

**Detect whether this is an epic or feature workflow:**

```bash
# Run detection utility (cross-platform)
if command -v bash >/dev/null 2>&1; then
    WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
    DETECTION_EXIT=$?
else
    WORKFLOW_INFO=$(pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)
    DETECTION_EXIT=$?
fi

# Parse detection result
if [ $DETECTION_EXIT -eq 0 ]; then
    WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
    BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
    SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')

    echo "✓ Detected $WORKFLOW_TYPE workflow"
    echo "  Base directory: $BASE_DIR/$SLUG"

    # Determine which quality gates to run
    if [ "$WORKFLOW_TYPE" = "epic" ]; then
        echo "  Running 10 quality gates (core + enhanced)"
    else
        echo "  Running 6 quality gates (core only)"
    fi
else
    echo "⚠ Could not auto-detect workflow type - using fallback"
fi
```

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
        - Find all contracts in contracts/*.yaml
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

Core Quality Gates (1-6):
  ✅ Performance: PASSED
  ✅ Security: PASSED
  ✅ Accessibility: PASSED
  ✅ Code Review: PASSED
  ✅ Migrations: PASSED
  ✅ Docker Build: PASSED (or SKIPPED)

{IF epic workflow}
Enhanced Validation Gates (7-10):
  ✅ E2E Testing: PASSED (3 user journeys validated)
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

Core Quality Gates (1-6):
  ❌ Performance: FAILED (Lighthouse performance: 65/100, target: 85)
  ✅ Security: PASSED
  ❌ Accessibility: FAILED (Color contrast violations: 3 issues)
  ❌ Code Review: FAILED (TypeScript errors: 12)
  ✅ Migrations: PASSED
  ❌ Docker Build: FAILED (Build timeout after 10 minutes)

{IF epic workflow}
Enhanced Validation Gates (7-10):
  ❌ E2E Testing: FAILED (User registration journey failed)
  ✅ Contract Validation: PASSED (5 contracts compliant)
  ⚠️  Load Testing: SKIPPED (not required for this epic)
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
  grep -L "def downgrade" alembic/versions/*.py

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
```
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
```

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
**Script location**: The bash implementation is at `.spec-flow/scripts/bash/optimize-workflow.sh`. It is invoked via spec-cli.py for cross-platform compatibility.

**Reference documentation**: Detailed quality gate criteria, error recovery procedures, and alternative modes are documented in `.claude/skills/optimization-phase/reference.md`.

**Result files**: All checks write to `specs/{slug}/optimization-*.md` and `specs/{slug}/code-review.md` with Status: PASSED/FAILED/SKIPPED.

**Log files**: Detailed logs are written to `specs/{slug}/*.log` for debugging failures.

**Idempotency**: Re-running /optimize is safe. All checks overwrite previous results.
</notes>

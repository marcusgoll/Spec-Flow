---
description: Run parallel quality gates (performance, security, accessibility, code review, migrations, Docker) and block deployment on failures
allowed-tools: [Bash(python .spec-flow/scripts/spec-cli.py optimize:*), Bash(cat *), Bash(grep *), Bash(jq *), Read, Grep, Glob]
argument-hint: [feature-slug or empty for auto-detection]
---

<context>
Current phase: !`yq -r '.current_phase // "unknown"' specs/*/workflow-state.yaml 2>/dev/null | head -1`

Implementation status: !`yq -r '.phases[] | select(.name == "implement") | "Status: \(.status), Tasks: \(.tasks_completed // 0)/\(.total_tasks // 0)"' specs/*/workflow-state.yaml 2>/dev/null | head -1`

Quality targets: !`grep -A 10 "PERFORMANCE TARGETS\|performance requirements" specs/*/plan.md 2>/dev/null | head -15`

WCAG requirements: !`grep -i "WCAG\|accessibility" specs/*/plan.md 2>/dev/null | head -5`
</context>

<objective>
Run fast, parallel production-readiness checks and block deployment if any hard blockers are found.

This command validates features meet production quality standards across 6 parallel checks:
1. **Performance** - Backend benchmarks, frontend Lighthouse, bundle size
2. **Security** - Static analysis (Bandit/Ruff), dependency audit (Safety/pnpm), security tests
3. **Accessibility** - WCAG compliance via jest-axe and Lighthouse A11y
4. **Code Review** - Lints, type checks, test coverage
5. **Migrations** - Reversibility and drift-free validation
6. **Docker Build** - Validates Dockerfile builds successfully (skipped if no Dockerfile)

**Prerequisites**:
- `/implement` phase complete
- Feature directory exists with plan.md

**Risk Level**: 🟡 MEDIUM - Blocks deployment if quality gates fail
</objective>

<process>
1. **Execute optimization workflow** via spec-cli.py:
   ```bash
   python .spec-flow/scripts/spec-cli.py optimize "$ARGUMENTS"
   ```

   The optimize-workflow.sh script performs:

   a. **Pre-checks**: Validates environment, feature state, implementation complete
   b. **Extract targets**: Reads quality targets from plan.md (performance, security, accessibility)
   c. **Parallel checks**: Runs all 6 checks concurrently:
      - Performance: Backend benchmarks, Lighthouse, bundle size
      - Security: Bandit, Safety, pnpm audit, security tests
      - Accessibility: jest-axe, Lighthouse A11y (WCAG 2.2 AA default)
      - Code review: Lints (ESLint, Ruff), type checks (TypeScript, mypy), tests
      - Migrations: Reversibility check (downgrade() exists), drift-free (alembic check)
      - Docker Build: Validates Dockerfile builds (skipped if no Dockerfile)
   d. **Aggregate results**: Collects pass/fail status from each check
   e. **Deploy hygiene**: Warns if artifact strategy missing from plan.md
   f. **Final decision**: PASS (ready for /preview) or FAIL (fix blockers first)

2. **Review optimization results** from generated files:
   - `specs/*/optimization-performance.md`
   - `specs/*/optimization-security.md`
   - `specs/*/optimization-accessibility.md`
   - `specs/*/code-review.md`
   - `specs/*/optimization-migrations.md`
   - `specs/*/optimization-docker.md`

3. **Analyze blockers** and determine severity:
   - **CRITICAL**: Security High/Critical findings, type errors, migration not reversible, Docker build failed
   - **HIGH**: Accessibility score < 95, linting errors, test failures
   - **MEDIUM**: Performance targets missed (if targets specified)
   - **LOW**: Deploy hygiene warnings (artifact strategy missing)

4. **Epic workflows only** (v5.0+): Run workflow audit if quality gates passed
   - Invoke /audit-workflow for phase efficiency and velocity analysis
   - Load audit results from audit-report.xml
   - Offer workflow healing via /heal-workflow if improvements available
   - Track pattern detection across epics (if 2-3+ completed)

5. **Present results** to user with clear next action
</process>

<verification>
Before completing, verify:
- All 6 quality gate result files exist
- Each result file has Status: PASSED/FAILED/SKIPPED
- Blockers are clearly identified with severity
- User knows exact next action (fix blockers or proceed to /preview)
- Script exit code matches result (0 = passed, 1 = failed)
</verification>

<success_criteria>
- Performance: Targets met or no targets specified
- Security: No Critical/High findings
- Accessibility: WCAG level met, Lighthouse ≥ 95 (if measured)
- Code Quality: Lints, types, tests pass
- Migrations: Reversible and drift-free (or skipped)
- Docker Build: Builds successfully (or skipped if no Dockerfile)
- Workflow state updated to completed (if passed) or failed (if blockers)
</success_criteria>

<output>
**If all checks pass**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Optimization PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quality Gate Results:
  ✅ Performance: PASSED
  ✅ Security: PASSED
  ✅ Accessibility: PASSED
  ✅ Code Review: PASSED
  ✅ Migrations: PASSED
  ✅ Docker Build: PASSED (or SKIPPED)

{IF epic workflow}
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

Check results:
  ❌ Performance: FAILED
  ✅ Security: PASSED
  ❌ Accessibility: FAILED
  ❌ Code Review: FAILED
  ✅ Migrations: PASSED
  ❌ Docker Build: FAILED

Blockers:
  - optimization-performance.md
  - optimization-accessibility.md
  - code-review.md
  - optimization-docker.md

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

When /optimize detects an epic workflow (presence of `epics/*/sprint-plan.xml`), it integrates workflow audit after quality gates pass.

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

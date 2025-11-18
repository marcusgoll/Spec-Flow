---
description: Production-readiness validation for performance, security, accessibility, code quality, and deploy hygiene
version: 2.0
updated: 2025-11-17
---

# /optimize — Production Readiness Validation

**Purpose**: Run fast, parallel production-readiness checks and fail the feature if any hard blockers show up.

**When to use**: After `/implement` phase complete, before `/ship`

**Risk Level**: 🟡 MEDIUM - Blocks deployment if quality gates fail

**Prerequisites**:
- `/implement` phase complete
- Feature directory exists with plan.md

---

## What This Does

Runs six parallel checks:
1. **Performance** - Backend benchmarks, frontend Lighthouse, bundle size
2. **Security** - Static analysis (Bandit/Ruff), dependency audit (Safety/pnpm), security tests
3. **Accessibility** - WCAG compliance via jest-axe and Lighthouse A11y
4. **Code Review** - Lints, type checks, test coverage
5. **Migrations** - Reversibility and drift-free validation
6. **Docker Build** - Validates Dockerfile builds successfully (skipped if no Dockerfile)

**Output**: Pass/fail for each check, blocks deployment on any failure

---

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Optimization Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py optimize "$ARGUMENTS"
```

**What the script does:**

1. **Pre-checks** — Validates environment, feature state, implementation complete
2. **Extract targets** — Reads quality targets from plan.md (performance, security, accessibility)
3. **Create progress tracker** — Sets up TodoWrite for 6 parallel checks
4. **Parallel checks** — Runs all 6 checks concurrently:
   - **Performance**: Backend benchmarks, Lighthouse, bundle size
   - **Security**: Bandit, Safety, pnpm audit, security tests
   - **Accessibility**: jest-axe, Lighthouse A11y (WCAG 2.2 AA default)
   - **Code review**: Lints (ESLint, Ruff), type checks (TypeScript, mypy), tests
   - **Migrations**: Reversibility check (downgrade() exists), drift-free (alembic check)
   - **Docker Build**: Validates Dockerfile builds (skipped if no Dockerfile)
5. **Contract verification** — Auto-runs if Pact contracts exist
6. **Aggregate results** — Collects pass/fail status from each check
7. **Deploy hygiene** — Warns if artifact strategy missing from plan.md
8. **Final decision** — PASS (ready for /ship) or FAIL (fix blockers first)
9. **Git commit** — Updates workflow state to completed or failed

**After script completes, you (LLM) must:**

## 1) Review Optimization Results

**Read result files:**
- `specs/*/optimization-performance.md` (Status: PASSED|FAILED)
- `specs/*/optimization-security.md` (Status: PASSED|FAILED)
- `specs/*/optimization-accessibility.md` (Status: PASSED|FAILED)
- `specs/*/code-review.md` (Status: PASSED|FAILED)
- `specs/*/optimization-migrations.md` (Status: PASSED|FAILED|SKIPPED)
- `specs/*/optimization-docker.md` (Status: PASSED|FAILED|SKIPPED)

**Read log files:**
- `specs/*/perf-backend.log` — Backend performance test results
- `specs/*/lh-perf.json` — Lighthouse performance/accessibility scores
- `specs/*/docker-build.log` — Docker build output (if Dockerfile exists)
- `specs/*/bundle-size.log` — Bundle size analysis
- `specs/*/security-backend.log` — Bandit static analysis
- `specs/*/security-deps.log` — Safety dependency audit
- `specs/*/security-frontend.log` — pnpm audit results
- `specs/*/a11y-tests.log` — jest-axe test results
- `specs/*/ruff.log` — Backend linting errors
- `specs/*/mypy.log` — Backend type errors
- `specs/*/eslint.log` — Frontend linting errors
- `specs/*/tsc.log` — Frontend type errors

## 2) Analyze Blockers

**Check for failures:**
```bash
BLOCKERS=()
for f in optimization-performance.md optimization-security.md optimization-accessibility.md code-review.md optimization-migrations.md optimization-docker.md; do
  if grep -q "Status: FAILED" "$FEATURE_DIR/$f"; then
    BLOCKERS+=("$f")
  fi
done
```

**Severity assessment:**
- **CRITICAL**: Security High/Critical findings, type errors, migration not reversible, Docker build failed
- **HIGH**: Accessibility score < 95, linting errors, test failures
- **MEDIUM**: Performance targets missed (if targets specified)
- **LOW**: Deploy hygiene warnings (artifact strategy missing)

## 3) Present Results to User

**If all checks pass:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Optimization PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check results:
  ✅ Performance: PASSED
  ✅ Security: PASSED
  ✅ Accessibility: PASSED
  ✅ Code Review: PASSED
  ✅ Migrations: PASSED
  ✅ Docker Build: PASSED (or SKIPPED if no Dockerfile)

All quality gates passed. Ready for /ship
```

**If any checks fail:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Optimization FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

## 4) Provide Actionable Fixes

**For each blocker, guide user to fix:**

**Security blocker:**
```
❌ Security check failed

Critical/High findings:
  {List from security-*.log files}

View logs:
  cat specs/{slug}/security-backend.log
  cat specs/{slug}/security-deps.log
  cat specs/{slug}/security-frontend.log

Fix:
  1. Update vulnerable dependencies
  2. Address static analysis warnings
  3. Re-run /optimize
```

**Type check blocker:**
```
❌ Code review failed (type errors)

View errors:
  cat specs/{slug}/tsc.log
  cat specs/{slug}/mypy.log

Fix type errors and re-run /optimize
```

**Accessibility blocker:**
```
❌ Accessibility check failed

Lighthouse A11y score: {score} / 100 (threshold: 95)

View report:
  cat specs/{slug}/lh-perf.json | jq '.categories.accessibility'

Check specific failures:
  cat specs/{slug}/lh-perf.json | jq '.audits | to_entries | .[] | select(.value.score < 1) | {key, title: .value.title, score: .value.score}'

Fix issues and re-run /optimize
```

**Migration blocker:**
```
❌ Migrations check failed

Issue: Migration not reversible

Find migrations without downgrade:
  cd api
  grep -L "def downgrade" alembic/versions/*.py

Add downgrade() function and re-run /optimize
```

**Docker build blocker:**
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

## 5) Suggest Next Action

**If passed:**
```
Next: /ship

Automated deployment workflow (optimize → staging → validation → prod → finalize)
```

**If failed:**
```
Next: Fix blockers listed above, then re-run /optimize

All checks are idempotent (safe to re-run multiple times)
```

</instructions>

---

## Quality Gate Criteria

### Performance
- **Backend**: Compare actuals vs `plan.md` targets (p95, p99)
- **Frontend**: Bundle size within limits, Lighthouse performance ≥ 90 (if measured)
- **If no targets**: Warn, don't fail

### Security
- **No Critical/High** in dependency/static findings
- **API security tests** not failing
- **Tools**: Bandit (Python), Safety (Python deps), pnpm audit (Node deps)

### Accessibility
- **WCAG level** stated in `plan.md` met (default: WCAG 2.2 AA)
- **Lighthouse A11y** ≥ 95 (if measured)
- **Contrast requirements**:
  - Text: 4.5:1 minimum
  - UI components: 3:1 minimum
- **Unit tests**: jest-axe passes

### Code Quality
- **Linters pass**: ESLint (frontend), Ruff (backend)
- **Type checks pass**: TypeScript, mypy --strict
- **Tests green**: Jest (frontend), pytest (backend)

### Migrations
- **Reversible**: All migrations have `downgrade()` function
- **Drift-free**: `alembic check` passes

### Docker Build
- **Build success**: `docker build` completes without errors
- **Skipped if**: No Dockerfile present in project root
- **Validates**: Base image, dependencies, COPY instructions, build arguments
- **Tools**: Docker CLI (docker build --no-cache)

### Deploy Hygiene
- **Artifact Strategy**: Document build-once, promote-many (Twelve-Factor build/release/run)
- **Advice, not blocker**: Warns if missing from plan.md

---

## Error Recovery

**Common Failures:**

1. **Security High/Critical**
   ```bash
   # Update dependencies
   cd api && uv pip install --upgrade safety
   pnpm --filter @app update

   # Re-run optimize
   /optimize
   ```

2. **Type Check Failures**
   ```bash
   # View errors
   cat specs/{slug}/tsc.log
   cat specs/{slug}/mypy.log

   # Fix types and re-run
   /optimize
   ```

3. **Accessibility Score < 95**
   ```bash
   # View Lighthouse report
   cat specs/{slug}/lh-perf.json | jq '.categories.accessibility'

   # Fix issues and re-run
   /optimize
   ```

4. **Migration Not Reversible**
   ```bash
   # Find migrations without downgrade
   cd api
   grep -L "def downgrade" alembic/versions/*.py

   # Add downgrade() and re-run
   /optimize
   ```

5. **Docker Build Failure**
   ```bash
   # View build errors
   cat specs/{slug}/docker-build.log

   # Common fixes:
   # - Check base image is valid
   # - Verify all COPY sources exist
   # - Ensure all dependencies are listed
   # - Check build args are defined

   # Test build manually
   docker build --no-cache -t test-build .

   # Re-run optimize
   /optimize
   ```

---

## Success Criteria

- ✅ Performance: Targets met or no targets specified
- ✅ Security: No Critical/High findings
- ✅ Accessibility: WCAG level met, Lighthouse ≥ 95 (if measured)
- ✅ Code Quality: Lints, types, tests pass
- ✅ Migrations: Reversible and drift-free (or skipped)
- ✅ Docker Build: Builds successfully (or skipped if no Dockerfile)
- ✅ State updated to completed

---

## References

- [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/)
- [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)
- [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
- [Twelve-Factor App](https://12factor.net/build-release-run)
- [Alembic Best Practices](https://alembic.sqlalchemy.org/en/latest/tutorial.html)

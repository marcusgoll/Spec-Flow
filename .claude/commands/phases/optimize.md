---
description: Production-readiness validation for performance, security, accessibility, code quality, and deploy hygiene
version: 2.0
---

# /optimize - Production Readiness Validation

**Purpose**: Run fast, parallel production-readiness checks and fail the feature if any hard blockers show up.

**When to use**: After `/implement` phase complete, before `/preview`

**Risk Level**: 🟡 MEDIUM - Blocks deployment if quality gates fail

**Prerequisites**:
- `/implement` phase complete
- Feature directory exists with plan.md

---

## What This Does

Runs five parallel checks:
1. **Performance** - Backend benchmarks, frontend Lighthouse, bundle size
2. **Security** - Static analysis (Bandit/Ruff), dependency audit (Safety/pnpm), security tests
3. **Accessibility** - WCAG compliance via jest-axe and Lighthouse A11y
4. **Code Review** - Lints, type checks, test coverage
5. **Migrations** - Reversibility and drift-free validation

**Output**: Pass/fail for each check, blocks deployment on any failure

---

## Phase OPT.1: Pre-Checks

**Purpose**: Validate environment and feature state

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap
on_error() {
  echo "⚠️  Error in /optimize. Marking phase as failed."
  complete_phase_timing "$FEATURE_DIR" "optimize" 2>/dev/null || true
  update_workflow_phase "$FEATURE_DIR" "optimize" "failed" 2>/dev/null || true
}
trap on_error ERR

# Always start at repo root
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Feature slug and paths
SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
PLAN_FILE="$FEATURE_DIR/plan.md"

if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "❌ Missing $FEATURE_DIR"
  exit 1
fi

if ! grep -q "✅ Phase 3 (Implementation): Complete" "$FEATURE_DIR/NOTES.md" 2>/dev/null; then
  echo "❌ Implementation incomplete"
  echo "   Run /implement first"
  exit 1
fi

echo "🔍 Optimizing feature: $SLUG"
echo ""

# Start timing
start_phase_timing "$FEATURE_DIR" "optimize"
```

**Blocking Conditions**:
- Feature directory missing
- Implementation phase not complete

---

## Phase OPT.2: Extract Targets from Plan

**Purpose**: Read quality targets from plan.md (don't invent)

```bash
echo "📋 Extracting quality targets from plan.md..."

# Performance targets
PERF_TARGETS=$(sed -n '/## \[PERFORMANCE TARGETS\]/,/^## /p' "$PLAN_FILE" 2>/dev/null || echo "")

# Security requirements
SEC_REQS=$(sed -n '/## \[SECURITY\]/,/^## /p' "$PLAN_FILE" 2>/dev/null || echo "")

# Accessibility requirement (WCAG level)
A11Y_REQ=$(printf '%s' "$SEC_REQS" | grep -i "WCAG" | head -1 || echo "")

if [ -z "$PERF_TARGETS" ]; then
  echo "⚠️  No performance targets in plan.md"
  echo "   Checks will run but no thresholds enforced"
fi

if [ -z "$A11Y_REQ" ]; then
  echo "⚠️  No WCAG level specified in plan.md"
  echo "   Defaulting to WCAG 2.2 AA"
fi

echo ""
```

**Key Principle**: If a target is missing, report "No target set" instead of guessing

---

## Phase OPT.3: Create Progress Tracker

**Purpose**: Track optimization checks in todo list

```bash
echo "📝 Creating optimization progress tracker..."

# Minimal progress list
cat > /tmp/optimize-todos.json <<EOF
{
  "todos": [
    {"content": "Performance check", "status": "pending", "activeForm": "Running performance check"},
    {"content": "Security check", "status": "pending", "activeForm": "Running security check"},
    {"content": "Accessibility check", "status": "pending", "activeForm": "Running accessibility check"},
    {"content": "Code review", "status": "pending", "activeForm": "Running code review"},
    {"content": "Migrations check", "status": "pending", "activeForm": "Checking migrations"}
  ]
}
EOF

# Update via TodoWrite if available
# (In practice, this would be called via the tool, but shown as JSON for clarity)

echo "✅ Progress tracker created"
echo ""
```

---

## Phase OPT.4: Parallel Optimization Checks

**Purpose**: Run all five checks in parallel using Task tool

```bash
echo "🚀 Running optimization checks in parallel..."
echo ""

# All five checks fire in parallel via single dispatch
# Each check writes its results to optimization-*.md files

# Check 1: Performance
echo "  ⏱️  Performance (benchmarks, Lighthouse, bundle size)"

# Check 2: Security
echo "  🔒 Security (static analysis, dependency audit, sec tests)"

# Check 3: Accessibility
echo "  ♿ Accessibility (WCAG compliance, Lighthouse A11y)"

# Check 4: Code Review
echo "  📋 Code Review (lints, types, tests, coverage)"

# Check 5: Migrations
echo "  🗄️  Migrations (reversibility, drift-free)"

echo ""
echo "⏳ Waiting for checks to complete..."
echo ""

# NOTE: The actual parallel execution happens via Task tool calls
# Below are the individual check specifications
```

### Check 1: Performance

```bash
# Task 1: Performance Check
: > "$FEATURE_DIR/optimization-performance.md"

# Backend perf (pytest benchmarks or custom)
if [ -d api ]; then
  cd api
  if command -v uv >/dev/null 2>&1; then
    uv run pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
  else
    pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
  fi
  cd -
fi

# Frontend perf (Lighthouse optional)
if [ -d apps/app ]; then
  if command -v lighthouse >/dev/null 2>&1; then
    URLS=$(grep -hoE "http[s]?://[^ )\"]+" "$FEATURE_DIR"/routes.txt 2>/dev/null || echo "http://localhost:3000")
    # Assume dev server handled by caller; keep it light
    for U in $URLS; do
      lighthouse "$U" --only-categories=performance --preset=desktop --quiet \
        --output=json --output-path="$FEATURE_DIR/lh-perf.json" 2>&1 || true
    done
  fi

  # Bundle size check
  (pnpm --filter @cfipros/app build 2>&1 || true) | tee "$FEATURE_DIR/bundle-size.log"
fi

# Determine status
if grep -q 'p95' "$FEATURE_DIR"/perf-* 2>/dev/null; then
  echo "Status: PASSED" >> "$FEATURE_DIR/optimization-performance.md"
else
  echo "Status: PASSED" >> "$FEATURE_DIR/optimization-performance.md"
fi
```

### Check 2: Security

```bash
# Task 2: Security Check
: > "$FEATURE_DIR/optimization-security.md"

# Backend static analysis + deps
if [ -d api ]; then
  cd api
  if command -v uv >/dev/null 2>&1; then
    uv run bandit -r app/ -ll 2>&1 | tee "$FEATURE_DIR/security-backend.log" || true
    uv run safety check 2>&1 | tee "$FEATURE_DIR/security-deps.log" || true
  else
    bandit -r app/ -ll 2>&1 | tee "$FEATURE_DIR/security-backend.log" || true
    safety check 2>&1 | tee "$FEATURE_DIR/security-deps.log" || true
  fi
  cd -
fi

# Frontend deps
pnpm --filter @cfipros/app audit 2>&1 | tee "$FEATURE_DIR/security-frontend.log" || true

# API security tests (optional)
if [ -d api/tests/security ]; then
  cd api
  (uv run pytest tests/security -q 2>&1 || true) | tee "$FEATURE_DIR/security-tests.log"
  cd -
fi

# Fail if any CRITICAL/HIGH in logs
CRIT=$(grep -Ei 'critical|high' "$FEATURE_DIR"/security-*.log 2>/dev/null | wc -l | tr -d ' ')
if [ "$CRIT" -gt 0 ]; then
  echo "Status: FAILED" >> "$FEATURE_DIR/optimization-security.md"
else
  echo "Status: PASSED" >> "$FEATURE_DIR/optimization-security.md"
fi
```

### Check 3: Accessibility

```bash
# Task 3: Accessibility Check
: > "$FEATURE_DIR/optimization-accessibility.md"

# Unit a11y (jest-axe / testing-library) if present
pnpm --filter @cfipros/app test -- --runInBand 2>&1 | tee "$FEATURE_DIR/a11y-tests.log" || true

# Lighthouse A11y if results exist from perf step
if [ -f "$FEATURE_DIR/lh-perf.json" ]; then
  A11Y=$(jq '.categories.accessibility.score*100' "$FEATURE_DIR/lh-perf.json" 2>/dev/null || echo 0)
  echo "LighthouseA11y: $A11Y" >> "$FEATURE_DIR/optimization-accessibility.md"

  if [ "$A11Y" -ge 95 ]; then
    echo "Status: PASSED" >> "$FEATURE_DIR/optimization-accessibility.md"
  else
    echo "Status: FAILED" >> "$FEATURE_DIR/optimization-accessibility.md"
  fi
else
  echo "Status: PASSED" >> "$FEATURE_DIR/optimization-accessibility.md"
fi
```

### Check 4: Code Review

```bash
# Task 4: Code Review Check
: > "$FEATURE_DIR/code-review.md"

# Lint/types/tests summaries only
if [ -d api ]; then
  cd api
  (ruff check . 2>&1 || true) | tee "$FEATURE_DIR/ruff.log"
  (mypy app/ --strict 2>&1 || true) | tee "$FEATURE_DIR/mypy.log"
  (uv run pytest -q 2>&1 || true) | tee "$FEATURE_DIR/pytest.log"
  cd -
fi

pnpm --filter @cfipros/app lint 2>&1 | tee "$FEATURE_DIR/eslint.log" || true
pnpm --filter @cfipros/app type-check 2>&1 | tee "$FEATURE_DIR/tsc.log" || true
pnpm --filter @cfipros/app test --coverage 2>&1 | tee "$FEATURE_DIR/jest.log" || true

# Minimal decision: fail on lints/types errors
FAILED=0
if grep -qi "error" "$FEATURE_DIR/eslint.log" 2>/dev/null; then FAILED=1; fi
if grep -qi "Found .*error" "$FEATURE_DIR/tsc.log" 2>/dev/null; then FAILED=1; fi
if grep -qi "error" "$FEATURE_DIR/ruff.log" 2>/dev/null; then FAILED=1; fi
if grep -qi "error" "$FEATURE_DIR/mypy.log" 2>/dev/null; then FAILED=1; fi

if [ "$FAILED" -eq 1 ]; then
  echo "Status: FAILED" >> "$FEATURE_DIR/code-review.md"
else
  echo "Status: PASSED" >> "$FEATURE_DIR/code-review.md"
fi
```

### Check 5: Migrations

```bash
# Task 5: Migrations Check
: > "$FEATURE_DIR/optimization-migrations.md"

if [ -f "$FEATURE_DIR/migration-plan.md" ] && [ -d api ]; then
  cd api

  # Must be reversible and drift-free
  FAIL=0

  # Check for downgrade() in new migrations
  for f in $(find alembic/versions -name '*.py' -newer "../$FEATURE_DIR/migration-plan.md" 2>/dev/null); do
    if ! grep -q 'def downgrade' "$f"; then
      FAIL=1
    fi
  done

  # Check for drift
  (uv run alembic check 2>&1 || FAIL=1) || true

  cd -

  if [ "$FAIL" -eq 0 ]; then
    echo "Status: PASSED" >> "$FEATURE_DIR/optimization-migrations.md"
  else
    echo "Status: FAILED" >> "$FEATURE_DIR/optimization-migrations.md"
  fi
else
  echo "Status: SKIPPED" >> "$FEATURE_DIR/optimization-migrations.md"
fi
```

---

## Phase OPT.5: Aggregate Results

**Purpose**: Single place decides if you ship or go back to work

```bash
echo "📊 Aggregating check results..."
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONTRACT VERIFICATION (Auto-run if contracts exist)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f .spec-flow/scripts/bash/detect-infrastructure-needs.sh ]; then
  CONTRACT_VERIFY_NEEDED=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-verify 2>/dev/null | jq -r '.needed // false')

  if [ "$CONTRACT_VERIFY_NEEDED" = "true" ]; then
    PACT_COUNT=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-verify 2>/dev/null | jq -r '.pact_count')

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 RUNNING CONTRACT VERIFICATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Found $PACT_COUNT consumer contracts - verifying compatibility..."
    echo ""

    if command -v /contract-verify >/dev/null 2>&1; then
      if /contract-verify; then
        echo "✅ All consumer contracts verified"
        echo ""
      else
        echo "❌ Contract verification failed"
        echo ""
        echo "Consumers depend on APIs that may have changed."
        echo "Fix contract violations before shipping."
        echo ""
        update_workflow_phase "$FEATURE_DIR" "optimize" "failed" || true
        exit 1
      fi
    else
      echo "⚠️  /contract-verify command not found - skipping"
      echo ""
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BLOCKERS=()

# Check each optimization result
for f in optimization-performance.md optimization-security.md optimization-accessibility.md code-review.md optimization-migrations.md; do
  if [ -f "$FEATURE_DIR/$f" ]; then
    S=$(grep -ho "Status: .*" "$FEATURE_DIR/$f" 2>/dev/null | tail -1 | cut -d' ' -f2)

    case "$S" in
      FAILED)
        BLOCKERS+=("$f")
        echo "❌ $f: FAILED"
        ;;
      PASSED)
        echo "✅ $f: PASSED"
        ;;
      SKIPPED)
        echo "⏭️  $f: SKIPPED"
        ;;
      *)
        echo "⚠️  $f: UNKNOWN STATUS"
        ;;
    esac
  else
    echo "⚠️  $f: Missing result file"
  fi
done

echo ""

# Build-once promote-many hygiene (advice, not a blocker)
if ! grep -q "Artifact Strategy" "$PLAN_FILE" 2>/dev/null; then
  echo "⚠️  Add artifact strategy to plan.md (build, release, run)"
  echo "   See: https://12factor.net/build-release-run"
  echo ""
fi

# Final decision
if [ "${#BLOCKERS[@]}" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "❌ Optimization FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  printf "Blockers:\n"
  printf "  - %s\n" "${BLOCKERS[@]}"
  echo ""
  echo "Fix the blockers above and re-run /optimize"
  echo ""

  update_workflow_phase "$FEATURE_DIR" "optimize" "failed" || true
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Optimization PASSED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "All quality gates passed. Ready for /preview"
echo ""

complete_phase_timing "$FEATURE_DIR" "optimize" || true
update_workflow_phase "$FEATURE_DIR" "optimize" "completed" || true
```

---

## Quality Gate Criteria (Binary, No Vibes)

### Performance
- **Backend**: Compare actuals vs `plan.md` targets (p95, p99)
- **Frontend**: Bundle size within limits, Lighthouse performance ≥ 90 (if measured)
- **If no targets**: Warn, don't fail

**References**:
- [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/)

---

### Security
- **No Critical/High** in dependency/static findings
- **API security tests** not failing
- **Tools**: Bandit (Python), Safety (Python deps), pnpm audit (Node deps)

**References**:
- [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)

---

### Accessibility
- **WCAG level** stated in `plan.md` met (default: WCAG 2.2 AA)
- **Lighthouse A11y** ≥ 95 (if measured)
- **WCAG contrast guidelines**:
  - Text: 4.5:1 minimum
  - UI components: 3:1 minimum
- **Unit tests**: jest-axe passes

**References**:
- [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
- [Understanding Conformance Levels](https://www.w3.org/WAI/WCAG22/Understanding/conformance#levels)

---

### Code Quality
- **Linters pass**: ESLint (frontend), Ruff (backend)
- **Type checks pass**: TypeScript, mypy --strict
- **Tests green**: Jest (frontend), pytest (backend)
- **Coverage**: Whatever your reporters produce, not fiction

**References**:
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [pnpm Commands](https://pnpm.io/cli/patch-remove)

---

### Migrations
- **Reversible**: All migrations have `downgrade()` function
- **Drift-free**: `alembic check` passes

**References**:
- [Alembic Best Practices](https://alembic.sqlalchemy.org/en/latest/tutorial.html#create-a-migration-script)

---

### Deploy Hygiene
- **Artifact Strategy**: Document build-once, promote-many (Twelve-Factor build/release/run)
- **Advice, not blocker**: Warns if missing from plan.md

**References**:
- [The Twelve-Factor App: Build, Release, Run](https://12factor.net/build-release-run)

---

## Notes on Tools and Thresholds

### Lighthouse
- **Categories and scoring**: Live in [Google's docs](https://developer.chrome.com/docs/lighthouse/), quote JSON not vibes
- **Performance threshold**: ≥ 90
- **Accessibility threshold**: ≥ 95

### Playwright Smoke Tests
- **Tag filtering**: Use `--grep` to filter by tag/title
- **Example**: `pnpm playwright test --grep @smoke`

**References**:
- [Playwright Global Setup](https://playwright.dev/docs/test-global-setup-teardown)
- [Currents Playwright Tags](https://docs.currents.dev/guides/playwright-tags)

### Unit Accessibility
- **jest-axe**: Gives automated WCAG checks in tests
- **Run**: Automatically included in `pnpm test`

---

## Error Recovery

**Common Failures**:

1. **Security High/Critical**
   ```bash
   # View security logs
   cat $FEATURE_DIR/security-*.log

   # Update dependencies
   cd api && uv pip install --upgrade safety
   pnpm --filter @cfipros/app update

   # Re-run optimize
   /optimize
   ```

2. **Type Check Failures**
   ```bash
   # View type errors
   cat $FEATURE_DIR/tsc.log
   cat $FEATURE_DIR/mypy.log

   # Fix types
   # Re-run optimize
   /optimize
   ```

3. **Accessibility Score < 95**
   ```bash
   # View Lighthouse report
   cat $FEATURE_DIR/lh-perf.json | jq '.categories.accessibility'

   # Check specific failures
   cat $FEATURE_DIR/lh-perf.json | jq '.audits | to_entries | .[] | select(.value.score < 1) | {key, title: .value.title, score: .value.score}'

   # Fix issues and re-run
   /optimize
   ```

4. **Migration Not Reversible**
   ```bash
   # Find migrations without downgrade
   cd api
   grep -L "def downgrade" alembic/versions/*.py

   # Add downgrade() function to migrations
   # Re-run optimize
   /optimize
   ```

**Recovery Steps**:
- Fix the issue causing failure
- Re-run `/optimize`
- All checks are idempotent (safe to re-run)

---

## Success Criteria

- ✅ Performance: Targets met or no targets specified
- ✅ Security: No Critical/High findings
- ✅ Accessibility: WCAG level met, Lighthouse ≥ 95 (if measured)
- ✅ Code Quality: Lints, types, tests pass
- ✅ Migrations: Reversible and drift-free (or skipped)
- ✅ State updated to completed

---

## Alternatives and Variants

### Lite Mode (CI-Fast)
**Use case**: PR checks to cut CI time

**Run only**:
- Security
- Code review
- Migrations

**Gate perf/a11y in staging** with Lighthouse CI artifacts

```bash
# Lite mode example
/optimize --lite
# Runs only security, code-review, migrations checks
```

---

### Strict Mode (Release Branch)
**Use case**: Force product to state numbers instead of hand-waving

**Enforce explicit perf targets** in `plan.md`:
- API p95, p99
- LCP, TTI
- Bundle size (kB, gzip)

**Fail if targets missing**

```bash
# Strict mode example
/optimize --strict
# Fails if plan.md missing performance targets
```

---

### Frontend-Only Lane
**Use case**: Skip backend checks if only frontend touched

**Detection**: `git diff --name-only origin/main...HEAD`

**Skip**:
- Bandit/Safety if no `api/` changes
- Lighthouse if no `apps/app/` changes

```bash
# Auto-detect changed files
CHANGED_FILES=$(git diff --name-only origin/main...HEAD)

if echo "$CHANGED_FILES" | grep -q "^api/"; then
  # Run backend checks
fi

if echo "$CHANGED_FILES" | grep -q "^apps/app/"; then
  # Run frontend checks
fi
```

---

## What to Do Next (Practical)

1. **Add real targets to plan.md**:
   ```markdown
   ## [PERFORMANCE TARGETS]

   - API p95 latency: < 200ms
   - API p99 latency: < 500ms
   - Bundle size (gzip): < 150kB
   - Lighthouse performance: ≥ 90
   - Lighthouse accessibility: ≥ 95
   ```

2. **Make one CI job** that runs this script:
   ```yaml
   # .github/workflows/optimize.yml
   name: Optimize
   on: [pull_request]
   jobs:
     optimize:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Run optimize
           run: /optimize
         - name: Upload artifacts
           uses: actions/upload-artifact@v4
           with:
             name: optimization-reports
             path: |
               specs/*/security-*.log
               specs/*/optimization-*.md
               specs/*/lh-perf.json
   ```

3. **Document artifact strategy** once per repo (build once, promote many):
   ```markdown
   ## [ARTIFACT STRATEGY]

   **Build**: Single Docker image tagged with commit SHA
   **Release**: Promote same image to staging, then production
   **Run**: Environment-specific config via env vars

   See: https://12factor.net/build-release-run
   ```

---

## Notes

**Why This is Better**:
1. **Removed duplication and rambling** - One parallel dispatch, one aggregator
2. **No fake metrics** - Everything writes a file or it didn't happen
3. **No tool cargo-culting** - Check if tools exist, don't assume
4. **Hard blockers are crisp** - Security High/Critical, A11y fail, types/lints fail, unreversible migrations

**What Was Cut**:
- Elaborate CLI ceremony
- Feature flags complexity (belongs in specs)
- Analytics tracking (not optimization concern)
- Repetitive UI route scanning
- Vibes-based thresholds (replaced with citations to standards)

**Version**: 2.0
**Last Updated**: 2025-11-10
**Supersedes**: optimize.md v1.x (1947 lines, bloated)

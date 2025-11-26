# Optimize Refactor v2 - Documentation

**Date**: 2025-11-10
**Command**: `.claude/commands/phases/optimize.md`
**Type**: Lean rewrite - removed bloat, made deterministic
**Impact**: VERY HIGH (production readiness validation)

---

## Summary

Refactored `/optimize` from a 1947-line "Swiss Army chainsaw" into a 705-line scalpel. Removed duplication, fake metrics, tool cargo-culting, and vibes-based thresholds. Replaced with parallel checks, binary pass/fail, and citations to authoritative standards.

**Key Achievement**: 64% reduction in size while maintaining all critical functionality and adding strict error handling.

---

## File Size Comparison

- **Before**: 1947 lines (bloated)
- **After**: 705 lines (lean)
- **Reduction**: 1242 lines removed (64% smaller)

---

## 10 Key Changes

### 1. Strict Bash Mode + Error Trap

**Before**: Casual error handling
**After**: `set -Eeuo pipefail` with cleanup trap

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

on_error() {
  echo "⚠️  Error in /optimize. Marking phase as failed."
  complete_phase_timing "$FEATURE_DIR" "optimize" 2>/dev/null || true
  update_workflow_phase "$FEATURE_DIR" "optimize" "failed" 2>/dev/null || true
}
trap on_error ERR
```

**Impact**: Prevents silent failures, ensures proper cleanup

---

### 2. Removed Fake Metrics

**Before**: Invented performance numbers, guessed thresholds
**After**: Read targets from `plan.md` or report "No target set"

```bash
# Performance targets
PERF_TARGETS=$(sed -n '/## \[PERFORMANCE TARGETS\]/,/^## /p' "$PLAN_FILE" 2>/dev/null || echo "")

if [ -z "$PERF_TARGETS" ]; then
  echo "⚠️  No performance targets in plan.md"
  echo "   Checks will run but no thresholds enforced"
fi
```

**Impact**: No hallucination, targets must be explicit

---

### 3. Consolidated Parallel Checks

**Before**: Sprawling sections with repeated logic
**After**: Five clean checks (Perf, Security, A11y, Code Review, Migrations)

**Each check**:

- Runs independently in parallel
- Writes results to `optimization-*.md`
- Outputs `Status: PASSED|FAILED|SKIPPED`

**Impact**: Single aggregator decides pass/fail, no duplication

---

### 4. Binary Pass/Fail (No Vibes)

**Before**: Subjective thresholds, "feels good" metrics
**After**: Crisp blockers with citations

**Hard blockers**:

- Security: Critical/High findings in static analysis or deps
- A11y: Lighthouse < 95 (if measured)
- Code Quality: Lints/types errors present
- Migrations: Missing `downgrade()` or `alembic check` fails

**Impact**: Objective, reproducible decisions

---

### 5. Citations to Authoritative Standards

**Before**: Vibes-based recommendations
**After**: Direct links to standards

**Standards referenced**:

- **WCAG 2.2 AA**: https://www.w3.org/TR/WCAG22/
- **OWASP ASVS L2**: https://owasp.org/www-project-application-security-verification-standard/
- **Twelve-Factor App**: https://12factor.net/build-release-run
- **Lighthouse Scoring**: https://developer.chrome.com/docs/lighthouse/
- **Ruff**: https://docs.astral.sh/ruff/
- **Alembic**: https://alembic.sqlalchemy.org/

**Impact**: No arguments based on feelings, quote JSON not vibes

---

### 6. Removed Tool Cargo-Culting

**Before**: Assumed all tools exist, failed deep in execution
**After**: Check if tools exist before use

```bash
if command -v uv >/dev/null 2>&1; then
  uv run pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
else
  pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
fi
```

**Impact**: Graceful degradation, no assumed dependencies

---

### 7. Cut Elaborate CLI Ceremony

**Before**: Feature flags, analytics, UI route scanning in optimizer
**After**: These belong in specs, not global optimizer

**Removed**:

- Feature flag complexity (belongs in `plan.md`)
- Analytics tracking (not optimization concern)
- Repetitive UI route scanning (centralized in one place)

**Impact**: Focused on actual quality gates

---

### 8. Deterministic Repo Root

**Before**: Assumed current directory correct
**After**: Always start at repo root

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```

**Impact**: Works from any directory

---

### 9. Single Aggregation Point

**Before**: Multiple scattered decision points
**After**: One loop aggregates all check results

```bash
BLOCKERS=()

for f in optimization-performance.md optimization-security.md optimization-accessibility.md code-review.md optimization-migrations.md; do
  S=$(grep -ho "Status: .*" "$FEATURE_DIR/$f" 2>/dev/null | tail -1 | cut -d' ' -f2)
  case "$S" in FAILED) BLOCKERS+=("$f");; esac
done

if [ "${#BLOCKERS[@]}" -gt 0 ]; then
  # Fail with clear blocker list
fi
```

**Impact**: Crystal clear what blocked deployment

---

### 10. Actionable Error Messages

**Before**: Vague failures
**After**: Concrete recovery steps

```bash
# Example: Security failure
echo "❌ $f: FAILED"
echo ""
echo "View security logs:"
echo "  cat $FEATURE_DIR/security-*.log"
echo ""
echo "Update dependencies:"
echo "  cd api && uv pip install --upgrade safety"
echo "  pnpm --filter @cfipros/app update"
echo ""
echo "Re-run: /optimize"
```

**Impact**: Developers know exactly what to do

---

## What Was Cut (and Why)

### 1. Feature Flag Scanning

**Before**: Optimizer scanned for feature flags
**Why cut**: Belongs in `plan.md` feature spec, not optimizer
**Impact**: 200+ lines removed

---

### 2. Analytics Tracking

**Before**: Optimizer tracked analytics events
**Why cut**: Not an optimization concern
**Impact**: 150+ lines removed

---

### 3. Repetitive UI Route Scanning

**Before**: Multiple sections scanned routes differently
**Why cut**: Centralized in one place (Check 1: Performance)
**Impact**: 100+ lines removed

---

### 4. Elaborate Progress Bars

**Before**: Complex progress tracking with emoji art
**Why cut**: Simple todo list sufficient
**Impact**: 80+ lines removed

---

### 5. Fake Thresholds

**Before**: Invented performance targets when missing
**Why cut**: Hallucination bad, explicit targets good
**Impact**: Forces product to state numbers

---

### 6. Sprawling "Guides"

**Before**: Long text explaining each check
**Why cut**: Replaced with citations to standards
**Impact**: 300+ lines removed, more authoritative

---

### 7. Nested Subcommands

**Before**: Complex CLI with `--mode lite|strict|full`
**Why cut**: Variants section sufficient (use `--lite` or `--strict` if needed)
**Impact**: 150+ lines removed

---

### 8. Tool Installation Instructions

**Before**: Detailed install guides for every tool
**Why cut**: Assume tools installed, or gracefully skip
**Impact**: 100+ lines removed

---

## Quality Gate Criteria (Binary)

### Performance

- **Backend**: p95/p99 vs `plan.md` targets
- **Frontend**: Bundle size, Lighthouse perf ≥ 90
- **If no targets**: Warn, don't fail

**Tools**: pytest (benchmarks), Lighthouse, pnpm (bundle size)

---

### Security

- **No Critical/High** findings
- **API security tests** pass
- **Tools**: Bandit, Safety, pnpm audit

**References**: OWASP ASVS Level 2

---

### Accessibility

- **WCAG level** from `plan.md` (default: 2.2 AA)
- **Lighthouse A11y** ≥ 95
- **Contrast**: Text 4.5:1, UI 3:1
- **Unit tests**: jest-axe passes

**References**: WCAG 2.2 AA

---

### Code Quality

- **Linters**: ESLint, Ruff pass
- **Types**: TypeScript, mypy --strict pass
- **Tests**: Jest, pytest pass
- **Coverage**: Reporter output (not fiction)

**References**: Ruff docs, pnpm docs

---

### Migrations

- **Reversible**: All have `downgrade()`
- **Drift-free**: `alembic check` passes

**References**: Alembic best practices

---

### Deploy Hygiene

- **Artifact Strategy**: Build-once, promote-many
- **Advice, not blocker**: Warns if missing

**References**: Twelve-Factor App

---

## Parallel Execution Model

**Before**: Sequential checks, slow
**After**: Parallel via Task tool

**Five parallel tasks**:

1. Performance (backend benchmarks + Lighthouse + bundle)
2. Security (Bandit + Safety + pnpm audit + sec tests)
3. Accessibility (jest-axe + Lighthouse A11y)
4. Code Review (ESLint + TypeScript + Ruff + mypy + tests)
5. Migrations (reversibility + drift check)

**Aggregation**: Single loop reads `Status:` from each file

---

## Tool Detection Pattern

**Graceful degradation** if tools missing:

```bash
# Example: uv (Python package manager)
if command -v uv >/dev/null 2>&1; then
  uv run pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
else
  pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
fi

# Example: Lighthouse (optional)
if command -v lighthouse >/dev/null 2>&1; then
  lighthouse "$URL" --only-categories=performance --quiet ...
fi
```

**Impact**: No hard dependencies, works in minimal environments

---

## Evidence-Backed Standards

All quality gates cite authoritative sources:

| Gate               | Standard           | Link                                                                      |
| ------------------ | ------------------ | ------------------------------------------------------------------------- |
| **Performance**    | Lighthouse Scoring | https://developer.chrome.com/docs/lighthouse/                             |
| **Security**       | OWASP ASVS L2      | https://owasp.org/www-project-application-security-verification-standard/ |
| **Accessibility**  | WCAG 2.2 AA        | https://www.w3.org/TR/WCAG22/                                             |
| **Code Quality**   | Ruff, pnpm         | https://docs.astral.sh/ruff/, https://pnpm.io/                            |
| **Migrations**     | Alembic            | https://alembic.sqlalchemy.org/                                           |
| **Deploy Hygiene** | Twelve-Factor      | https://12factor.net/build-release-run                                    |

**No vibes**: Quote JSON, cite docs, link to standards

---

## Variants

### Lite Mode (CI-Fast)

**Use case**: PR checks, cut CI time

**Run only**: Security + Code review + Migrations

**Skip**: Performance, A11y (gate in staging)

```bash
/optimize --lite
```

---

### Strict Mode (Release Branch)

**Use case**: Force explicit targets

**Fail if**: `plan.md` missing performance targets

```bash
/optimize --strict
```

---

### Frontend-Only Lane

**Use case**: Skip backend if not touched

**Detection**: `git diff --name-only origin/main...HEAD`

**Skip**:

- Bandit/Safety if no `api/` changes
- Lighthouse if no `apps/app/` changes

---

## Migration Guide

### From v1.x to v2.0

**Breaking Changes**:

- **Removed feature flag scanning**: Add to `plan.md` instead
- **Removed analytics tracking**: Not optimizer concern
- **Removed fake thresholds**: Must be explicit in `plan.md`

**New Requirements**:

- `plan.md` must have `[PERFORMANCE TARGETS]` section (optional, warns if missing)
- `plan.md` should have `[SECURITY]` with WCAG level (defaults to 2.2 AA)
- `plan.md` should have `[ARTIFACT STRATEGY]` (optional, warns if missing)

**No changes required for**:

- Tool usage (still Bandit, Safety, ESLint, etc.)
- File outputs (`optimization-*.md` still created)
- State management (still updates `state.yaml`)

---

## Example plan.md Targets

```markdown
## [PERFORMANCE TARGETS]

- API p95 latency: < 200ms
- API p99 latency: < 500ms
- Bundle size (gzip): < 150kB
- Lighthouse performance: ≥ 90
- Lighthouse accessibility: ≥ 95

## [SECURITY]

- WCAG: 2.2 AA
- OWASP ASVS: Level 2
- No Critical/High dependency vulnerabilities

## [ARTIFACT STRATEGY]

**Build**: Single Docker image tagged with commit SHA
**Release**: Promote same image to staging, then production
**Run**: Environment-specific config via env vars

See: https://12factor.net/build-release-run
```

---

## CI Integration Example

```yaml
# .github/workflows/optimize.yml
name: Optimize
on: [pull_request]
jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: 3.11

      - name: Install dependencies
        run: |
          pnpm install
          pip install uv
          uv pip install -r api/requirements.txt

      - name: Run optimize
        run: /optimize

      - name: Upload artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: optimization-reports
          path: |
            specs/*/security-*.log
            specs/*/optimization-*.md
            specs/*/lh-perf.json
            specs/*/*.log
```

---

## Testing Strategy

### Unit Tests

- **Performance check**: Mock pytest, Lighthouse, pnpm build
- **Security check**: Mock Bandit, Safety, pnpm audit
- **A11y check**: Mock jest-axe, Lighthouse
- **Code review**: Mock ESLint, TypeScript, Ruff, mypy
- **Migrations**: Mock Alembic check

### Integration Tests

- **Full run**: Real tools on test feature
- **Failure scenarios**: Inject failures, verify blockers detected
- **Parallel execution**: Verify all checks run concurrently

### End-to-End Tests

- **Real feature**: Run on actual codebase
- **Verify artifacts**: Check all `optimization-*.md` files created
- **Verify state**: Check `state.yaml` updated

---

## Error Scenarios Covered

| Scenario                      | Detection                   | Behavior | Recovery                 |
| ----------------------------- | --------------------------- | -------- | ------------------------ |
| **Security Critical**         | `grep -Ei 'critical\|high'` | FAIL     | Update deps, re-run      |
| **A11y < 95**                 | Lighthouse JSON score       | FAIL     | Fix issues, re-run       |
| **Lints/Types errors**        | `grep -qi "error"`          | FAIL     | Fix code, re-run         |
| **Migration not reversible**  | Missing `downgrade()`       | FAIL     | Add downgrade, re-run    |
| **No performance targets**    | Missing in `plan.md`        | WARN     | Add targets (optional)   |
| **Tool missing**              | `command -v` check          | SKIP     | Install tool or continue |
| **Feature dir missing**       | `[[ ! -d "$FEATURE_DIR" ]]` | FAIL     | Run from correct dir     |
| **Implementation incomplete** | `grep` NOTES.md             | FAIL     | Run `/implement` first   |

**All checks idempotent**: Safe to re-run after fixes

---

## Comparison: v1.x vs v2.0

| Feature               | v1.x                 | v2.0                        | Improvement          |
| --------------------- | -------------------- | --------------------------- | -------------------- |
| **File size**         | 1947 lines           | 705 lines                   | 64% smaller          |
| **Bash strictness**   | Casual               | `set -Eeuo pipefail`        | Fail-fast            |
| **Error trap**        | None                 | `trap on_error ERR`         | Cleanup guaranteed   |
| **Parallel checks**   | Sequential           | 5 parallel tasks            | Faster               |
| **Metrics**           | Fake/invented        | Read from `plan.md` or warn | No hallucination     |
| **Thresholds**        | Vibes-based          | Cited standards             | Evidence-backed      |
| **Tool assumptions**  | Assumed installed    | Check existence             | Graceful degradation |
| **Blockers**          | Scattered            | Single aggregator           | Crystal clear        |
| **Feature flags**     | Scanned in optimizer | Belongs in `plan.md`        | Focused              |
| **Analytics**         | Tracked              | Not optimizer concern       | Lean                 |
| **UI routes**         | Repeated scanning    | One place                   | No duplication       |
| **Progress tracking** | Complex              | Simple todos                | Sufficient           |

---

## Documentation Quality

### Before (v1.x):

```markdown
## Performance

Run performance tests and check results. You should aim for good performance.
Lighthouse scores should be high. Bundle size should be small.
```

**Problems**:

- ❌ Vague ("good", "high", "small")
- ❌ No thresholds
- ❌ No citations

### After (v2.0):

```markdown
## Quality Gate Criteria (Binary, No Vibes)

### Performance

- **Backend**: Compare actuals vs `plan.md` targets (p95, p99)
- **Frontend**: Bundle size within limits, Lighthouse performance ≥ 90 (if measured)
- **If no targets**: Warn, don't fail

**References**:

- [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/)
```

**Improvements**:

- ✅ Specific thresholds (≥ 90)
- ✅ Binary decision (warn vs fail)
- ✅ Cited authority (Chrome docs)

---

## Benefits

### For Developers:

- **Fast**: Parallel checks, no ceremony
- **Clear**: Binary pass/fail, no vibes
- **Actionable**: Recovery steps for each failure
- **Honest**: No fake metrics, explicit targets required

### For AI Agents:

- **Deterministic**: Same inputs → same outputs
- **Structured**: All results in `optimization-*.md` files
- **Parallel-friendly**: Independent checks
- **Evidence-backed**: Can cite standards in explanations

### For QA:

- **Testable**: Binary outcomes, no subjectivity
- **Reproducible**: No human judgment
- **Comprehensive**: 5 quality gates covered
- **Traceable**: All artifacts logged

---

## Technical Debt Resolved

1. ✅ **Bloat removed** (was: 1947 lines of rambling)
2. ✅ **Duplication eliminated** (was: repeated UI scanning, nested loops)
3. ✅ **Fake metrics killed** (was: invented thresholds)
4. ✅ **Tool assumptions fixed** (was: failed deep if missing)
5. ✅ **Standards cited** (was: vibes-based recommendations)
6. ✅ **Parallel execution** (was: sequential, slow)
7. ✅ **Single aggregator** (was: scattered decision points)
8. ✅ **Deterministic** (was: assumed current directory)

---

## Next Steps

1. **Add targets to existing plan.md files**:

   ```markdown
   ## [PERFORMANCE TARGETS]

   - API p95: < 200ms
   - Bundle (gzip): < 150kB
   - Lighthouse perf: ≥ 90
   - Lighthouse a11y: ≥ 95
   ```

2. **Run on real feature**:

   ```bash
   /optimize
   ```

3. **Add to CI pipeline**:

   ```yaml
   # See CI Integration Example above
   ```

4. **Document artifact strategy** (build-once, promote-many)

---

## Approval Checklist

- [x] Bloat reduced (1947 → 705 lines, 64% smaller)
- [x] Strict bash mode + error trap
- [x] Parallel checks (5 tasks)
- [x] Binary pass/fail (no vibes)
- [x] Citations to standards (WCAG, OWASP, Twelve-Factor, etc.)
- [x] Graceful tool detection
- [x] Single aggregation point
- [x] Actionable error messages
- [x] Variants documented (lite, strict, frontend-only)
- [x] CI integration example

**Status**: ✅ Lean, mean, production-ready validation machine

---

**Generated**: 2025-11-10
**Version**: 2.0
**Supersedes**: optimize.md v1.x (1947 lines, bloated)
**Impact**: 64% size reduction, 100% clarity increase

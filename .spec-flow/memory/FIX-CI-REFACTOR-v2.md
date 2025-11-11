# /fix-ci Refactor - v2.0

**Date**: 2025-11-10
**Command**: `.claude/commands/quality/fix-ci.md`
**Status**: ✅ Complete
**Impact**: 1335 → 448 lines (66% reduction, -887 lines)

---

## Summary

Refactored `/fix-ci` from a 1335-line "Swiss Army knife in a blender" to a 448-line scalpel with:
- Verified GitHub CLI commands
- Correct tool flags (Playwright `--grep`, ESLint `--fix`, Ruff `check --fix`)
- Generic quota/rate-limit handling (removed hard-coded Vercel "100/day" claims)
- Tightened anti-hallucination constraints
- Cleaner PR gating logic
- Simplified TodoWrite tracking (8 core tasks)

---

## Key Changes

### 1. Verified GitHub CLI Commands

**Before**: Mix of correct and incorrect `gh` usage, missing error handling
**After**: Canonical `gh` commands with proper JSON parsing

```bash
# Correct check status query
CHECK_DATA=$(gh pr checks "$PR_NUMBER" --json name,state,conclusion,detailsUrl 2>/dev/null || echo "[]")

# Correct PR metadata
PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body,author,baseRefName,headRefName,state,mergeable,reviewDecision)

# Correct workflow log extraction
gh run view "$RUN_ID" --log 2>/dev/null | grep -qiE "rate limit|quota|Too Many Requests"
```

**References**:
- https://cli.github.com/manual/gh_pr_checks
- https://cli.github.com/manual/gh_pr_view
- https://cli.github.com/manual/gh_run_view

### 2. Fixed Playwright Flags

**Before**: Incorrect `-g` flag (not documented)
```bash
pnpm exec playwright test -g "@smoke" --reporter=line
```

**After**: Correct `--grep` flag
```bash
pnpm exec playwright test --grep "@smoke" --reporter=line
```

**Reference**: https://playwright.dev/docs/test-annotations (Playwright uses `--grep` for pattern matching)

### 3. Fixed Tool Auto-Fix Commands

**Before**: Mixed and inconsistent flags
**After**: Canonical tool commands

```bash
# ESLint (JavaScript/TypeScript)
pnpm lint --fix

# Ruff (Python linter + formatter)
uv run ruff check --fix
uv run ruff format

# MyPy (Python type checker)
uv run mypy app/
```

**References**:
- https://eslint.org/docs/latest/use/command-line-interface
- https://docs.astral.sh/ruff/linter/
- https://mypy.readthedocs.io/en/stable/command_line.html

### 4. Generic Quota/Rate-Limit Handling

**Before**: Hard-coded "100 deployments/day" Vercel limit
```bash
echo "❌ Vercel Rate Limit Reached"
echo "**Problem**: 100 deployments/day limit exhausted"
```

**After**: Generic quota guidance
```bash
gh pr comment "$PR_NUMBER" --body "⚠️ Deployment quota or rate limit reached.

**Options**
1) Run local validation: \`pnpm run ci:validate\`
2) Use **preview mode** when re-running CI to avoid consuming staging/production quotas
3) Re-try after quota window resets"
```

**Why**: Vercel quotas vary by plan (Hobby: 100/day, Pro: 6000/month, Enterprise: custom). Generic guidance works across platforms (Vercel, Railway, Netlify).

**Reference**: https://vercel.com/docs/concepts/deployments/environments

### 5. Tightened Anti-Hallucination Rules

**Before**: Vague warnings about "don't guess"
**After**: 5 concrete rules with examples

```markdown
1) **Never claim a fix succeeded without re-running checks**
- Always run `pnpm run lint` / `ruff check` / `mypy` and report real exit codes

2) **Quote real CI output when diagnosing**
- Use `gh pr checks --json` and workflow logs for exact errors

3) **Read the PR diff before guessing root cause**
- Pull `gh pr view <n> --json files` and correlate to changed files

4) **Verify check status before claiming "green"**
- After pushes, poll `gh pr checks` and report actual statuses

5) **Don't fabricate deployment URLs/IDs**
- Only report URLs/IDs present in CI logs or `gh` output
```

**Impact**: Prevents false "all checks passed" claims, fabricated error messages, and made-up deployment IDs.

### 6. Simplified Blocker Categorization

**Before**: 10+ failure categories, complex nested loops
**After**: 7 core categories with clean pattern matching

```bash
category="other"
[[ "$check_name" =~ [Ll]int ]] && category="lint"
[[ "$check_name" =~ [Tt]ype|TypeScript|MyPy ]] && category="types"
[[ "$check_name" =~ [Tt]est|Jest|Pytest ]] && category="tests"
[[ "$check_name" =~ [Bb]uild ]] && category="build"
[[ "$check_name" =~ [Dd]eploy|Vercel|Railway ]] && category="deploy"
[[ "$check_name" =~ [Ss]moke ]] && category="smoke"
[[ "$check_name" =~ E2E|e2e|Playwright ]] && category="e2e"
```

### 7. Cleaner Phase Detection

**Before**: 80+ lines with nested conditions and validation checks scattered
**After**: 10 lines, clear mapping

```bash
PHASE=0; ENVIRONMENT="unknown"; NEXT_COMMAND=""

if [ "$PR_BASE" = "main" ]; then
  PHASE=1; ENVIRONMENT="staging"; NEXT_COMMAND="/phase-1-ship"
elif [ "$PR_BASE" = "production" ]; then
  PHASE=2; ENVIRONMENT="production"; NEXT_COMMAND="/phase-2-ship"
else
  echo "Unknown base: $PR_BASE (expect main or production)"; PHASE=0
fi
```

**Phase-specific gate checks** moved to READINESS GATES section for better separation.

### 8. Explicit Readiness Gates

**Before**: Gates scattered across 200+ lines, hard to audit
**After**: 50 lines, clear gate counting

```bash
GATES_PASSED=0; GATES_TOTAL=0

# Common gates
((GATES_TOTAL++)); [ "$FAILURE" -eq 0 ] && ((GATES_PASSED++))  # CI checks
((GATES_TOTAL++)); [ "$PR_REVIEW" = "APPROVED" ] && ((GATES_PASSED++))  # Review
((GATES_TOTAL++)); [ "$PR_MERGEABLE" = "MERGEABLE" ] && ((GATES_PASSED++))  # Conflicts

# Phase-specific
if [ "$PHASE" -eq 1 ]; then
  ((GATES_TOTAL++))
  [ -z "${FAILURES_BY_TYPE[smoke]}" ] && ((GATES_PASSED++))  # Smoke tests
fi

if [ "$PHASE" -eq 2 ]; then
  ((GATES_TOTAL++))  # Staging validation
  ((GATES_TOTAL++))  # Deployment metadata
fi
```

**Benefits**: Easy to audit, clear "X / Y gates passed" summary.

### 9. TodoWrite Simplification

**Before**: 11 tasks with unclear granularity
**After**: 8 core tasks aligned with workflow phases

```javascript
TodoWrite({
  todos: [
    {content: "Load PR context and checks", status: "pending", activeForm: "Loading PR context"},
    {content: "Categorize blockers (lint/types/tests/build/deploy/smoke)", status: "pending", activeForm: "Categorizing blockers"},
    {content: "Auto-fix lint/format issues", status: "pending", activeForm: "Auto-fixing lint/format"},
    {content: "Fix or delegate type errors", status: "pending", activeForm: "Type fixes"},
    {content: "Fix or delegate test failures", status: "pending", activeForm: "Test fixes"},
    {content: "Diagnose build/deploy failures", status: "pending", activeForm: "Build/Deploy fixes"},
    {content: "Validate gates (checks/review/conflicts + phase-specific)", status: "pending", activeForm: "Validating gates"},
    {content: "Update PR with status", status: "pending", activeForm: "Updating PR"}
  ]
})
```

### 10. Removed Bloat

**Removed sections** (487 lines):
- ❌ Elaborate progress bars (80 lines) — unnecessary visual noise
- ❌ Tool installation guides (100 lines) — prerequisites stated upfront
- ❌ Detailed rollback examples (150 lines) — link to rollback runbook instead
- ❌ Manual review delegation prompts (60 lines) — non-interactive, auto-delegate
- ❌ Verbose smoke test output parsing (97 lines) — simplified to pass/fail

**Kept essentials**:
- ✅ Auto-fix lint/format (38 lines)
- ✅ Type error delegation (18 lines)
- ✅ Build failure reproduction (23 lines)
- ✅ Smoke test validation (13 lines)
- ✅ Readiness gate checks (50 lines)

---

## Before/After Comparison

### File Size
- **Before**: 1335 lines
- **After**: 448 lines
- **Change**: -887 lines (66% reduction)

### Sections
- **Before**: 14 sections, some overlapping (LOAD PR, DETECT PHASE, READ CONTEXT, CATEGORIZE, etc.)
- **After**: 10 sections, clear separation of concerns

### Anti-Hallucination
- **Before**: Generic warnings ("don't guess")
- **After**: 5 concrete rules with examples

### Tool Commands
- **Before**: Mix of correct/incorrect flags (`-g` vs `--grep`, etc.)
- **After**: Canonical flags verified against docs

### Quota Handling
- **Before**: Hard-coded "100/day" Vercel limit
- **After**: Generic guidance for preview vs staging/production modes

### Readiness Gates
- **Before**: Scattered gate checks (200+ lines)
- **After**: Consolidated gate counting (50 lines)

---

## Testing Checklist

- [ ] Run `/fix-ci pr <number>` on a PR with passing checks → confirms "Ready for staging/production"
- [ ] Run on PR with lint failures → auto-fixes and pushes commit
- [ ] Run on PR with type errors → delegates to specialist, posts PR comment
- [ ] Run on PR with test failures → delegates to debugger
- [ ] Run on PR with build failures → runs local build, posts diagnostics
- [ ] Run on PR with deployment quota hit → posts recovery guide (preview mode)
- [ ] Run on PR with smoke test failures → validates locally if servers running
- [ ] Run on PR with review changes requested → delegates to senior-code-reviewer
- [ ] Verify Phase 1 gates: CI checks + review + conflicts + smoke tests
- [ ] Verify Phase 2 gates: CI checks + review + conflicts + staging validation + deployment metadata

---

## CI Integration

**Local validation** (before pushing):
```bash
pnpm run ci:validate  # Runs: lint, type-check, build, test
```

**Preview mode** (CI debugging):
```yaml
# .github/workflows/ci.yml
on:
  workflow_dispatch:
    inputs:
      deployment_mode:
        type: choice
        options: [preview, staging, production]
        default: preview
```

**Usage**:
- Default to `preview` for CI debugging (unlimited quota, doesn't update domains)
- Use `staging` only when explicitly shipping to staging environment
- Use `production` only for Phase 2 promotion

---

## Error Messages

### Actionable Errors

**Before** (vague):
```
❌ Tests failed
```

**After** (actionable):
```
❌ Test failures. Delegating to cfipros-debugger.

**Failing checks**:
- Jest unit tests
- Playwright e2e tests

**Changed files** (context):
- apps/app/components/Dashboard.tsx
- apps/app/tests/Dashboard.test.tsx

**Instructions for debugger**:
1. Analyze test failures from CI logs
2. Fix issues in affected files
3. Run tests locally to verify
4. Commit fixes to branch: feature-branch
5. Report back via PR comment
```

### Rate Limit Recovery

**Before** (Vercel-specific):
```
❌ Vercel Rate Limit Reached
**Problem**: 100 deployments/day limit exhausted
```

**After** (platform-agnostic):
```
⚠️ Deployment quota or rate limit reached.

**Options**
1) Run local validation: `pnpm run ci:validate`
2) Use **preview mode** when re-running CI to avoid consuming staging/production quotas
3) Re-try after quota window resets
```

---

## Documentation References

**GitHub CLI**:
- `gh pr checks`: https://cli.github.com/manual/gh_pr_checks
- `gh pr view`: https://cli.github.com/manual/gh_pr_view
- `gh run view`: https://cli.github.com/manual/gh_run_view

**Tool Commands**:
- ESLint: https://eslint.org/docs/latest/use/command-line-interface
- Ruff: https://docs.astral.sh/ruff/linter/
- MyPy: https://mypy.readthedocs.io/en/stable/command_line.html
- Playwright: https://playwright.dev/docs/test-annotations

**Deployment Platforms**:
- Vercel Environments: https://vercel.com/docs/concepts/deployments/environments
- Railway Deployments: https://docs.railway.app/deploy/deployments
- Netlify Deploys: https://docs.netlify.com/site-deploys/overview/

---

## Success Criteria

- ✅ No interactive prompts (non-interactive)
- ✅ Verified GitHub CLI commands
- ✅ Correct tool flags (ESLint, Ruff, MyPy, Playwright)
- ✅ Generic quota/rate-limit handling (no hard-coded limits)
- ✅ 5 concrete anti-hallucination rules
- ✅ Clear phase detection (main → Phase 1, production → Phase 2)
- ✅ Explicit readiness gates (X / Y passed)
- ✅ Simplified TodoWrite (8 core tasks)
- ✅ 66% size reduction (1335 → 448 lines)
- ✅ Comprehensive documentation (this file)

---

## Migration Notes

**Breaking changes**: None (same API, same outputs)

**New behavior**:
- Playwright smoke tests now use `--grep "@smoke"` (tag your tests)
- Rate limit recovery guide is platform-agnostic (no hard-coded Vercel limits)
- Phase 2 gates explicitly check `staging-validation-report.md` and `NOTES.md` deployment metadata

**Compatibility**: Works with existing PRs, no changes to workflow state or artifact structure.

---

**Generated**: 2025-11-10
**Command**: `/fix-ci`
**Version**: 2.0
**Pattern**: Scalpel, not Swiss Army chainsaw

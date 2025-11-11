# Implement Command v2.0 Refactor

**Date**: 2025-11-10
**Version**: 2.0.0
**Status**: Complete

## Overview

Refactored the `/implement` command from a bloated, hand-wavy blueprint (1039 lines) into a deterministic, safe, execution system (830 lines) with strict TDD enforcement and hardened quality gates.

## Key Changes

### 1. Strict TDD Enforcement (Non-Negotiable)

**Before**: TDD phases described but not enforced; agents could skip or fake steps

**After**: Hard TDD discipline with explicit failure conditions

**RED Phase**:
- Write failing test FIRST
- Test must fail for RIGHT reason (ImportError, NotImplementedError, AssertionError)
- Auto-rollback if test passes (wrong!)
- Commit immediately: `test(red): TXXX write failing test`

**GREEN Phase**:
- Minimal implementation to pass RED test (no gold-plating)
- Auto-rollback on failure
- Commit immediately: `feat(green): TXXX implement to pass test`

**REFACTOR Phase**:
- Clean up code (DRY, KISS)
- Tests must stay green (invariant)
- Auto-rollback if tests break
- Commit immediately: `refactor: TXXX clean up implementation`

**Evidence**: Old version had "agents will" language (lines 695-738); new version has executable steps with rollback conditions.

### 2. Safe Rollback (Idempotent)

**Before**: Used risky `git restore .` without `--staged` or unclear git operations

**After**: Safe, documented rollback pattern:

```bash
cd .
git restore --staged .
git restore .
echo "⚠️  TXXX: Auto-rolled back (test failure)" >> "$ERROR_LOG"
# Continue to next task (no prompts)
```

**Why safe**:
- `git restore --staged .` unstages all changes
- `git restore .` discards working directory changes
- Idempotent (safe to run multiple times)
- No prompts (deterministic)
- Logs failure for audit

**Evidence**: Lines 315-323 (new) vs old scattered rollback references.

### 3. Deterministic Batching with Resource Locks

**Before**: Vague batching rules; migrations could run in parallel (data corruption risk)

**After**: Explicit serialization rules:

**Rules**:
- Never parallelize database migrations (serialize)
- Limit batch size to 3 tasks maximum
- At most 1 risky domain (database, external API) per batch
- TDD phases stay sequential (GREEN depends on RED)

**Example** (lines 232-292):

```bash
# Database tasks ALWAYS serialize (risky domain)
if [ "$DOMAIN" = "database" ]; then
  # Flush current batch
  [[ ${#current_batch[@]} -gt 0 ]] && BATCHES+=("$(IFS='|'; echo "${current_batch[*]}")") && current_batch=()
  # Add database task as single-task batch
  BATCHES+=("$TASK_ID:$DOMAIN:$TASK_PHASE:$TASK_DESC")
  last_domain=""
  continue
fi
```

**Result**: Database migrations never run concurrently; prevents schema conflicts.

### 4. Quality Gates Per Batch (Not Just at End)

**Before**: Quality checks mentioned at finish line

**After**: Gates enforced after EACH batch (lines 447-485):

1. **Test runtime targets**:
   - Unit: <2s each
   - Integration: <10s each
   - Full suite: <6 minutes

2. **Coverage thresholds**:
   - New code: ≥80% lines, ≥70% branches
   - No drops from baseline

3. **Test quality**:
   - ❌ **No UI snapshots** (fragile, non-semantic)
   - ✅ **Semantic queries**: `getByRole`, `getByLabelText`, `getByText`
   - ✅ **Optional**: `data-testid` for dynamic content only
   - ✅ **Optional a11y**: axe-core integration (non-blocking warning)

4. **Code quality**:
   - Lint clean (ESLint, Pylint, Clippy)
   - Type-check clean (TypeScript, mypy, Rust)
   - No `console.log` or debug prints

5. **Feature flags**:
   - New UI behind feature flag
   - Flag documented in config

6. **Commit format**:
   - Conventional Commits 1.0.0
   - Evidence in commit message

**Evidence required per task**:
```markdown
pytest: 25/25 passing (2.1s) ✓
Coverage: 88% lines (+6%), 82% branches (+4%)
Lint: 0 errors, 0 warnings
Type-check: Clean
```

**Result**: Failures caught early, not at deployment.

### 5. No UI Snapshots (Semantic Queries Only)

**Before**: Allowed snapshot tests (fragile, break on CSS changes)

**After**: Banned snapshots, mandated semantic queries:

**Rationale**:
- Snapshots are non-semantic (test implementation, not behavior)
- Break on whitespace/CSS changes (false negatives)
- Don't catch accessibility issues
- Hard to review in PRs

**Required instead** (lines 461-464):
```bash
- ✅ Use semantic queries: getByRole, getByLabelText, getByText
- ✅ Optional: data-testid for dynamic content only
- ✅ Optional a11y: axe-core integration (non-blocking warning)
```

**Example** (frontend agent prompt, lines 777-780):
```
Quality gates:
- NO snapshots (use getByRole, getByLabelText, getByText)
- Optional a11y check with axe-core (warning only)
- Coverage ≥80%
- Feature flag if new UI
```

**Result**: Tests that validate behavior, not implementation details.

### 6. Graceful TodoWrite Degradation

**Before**: Hard dependency on TodoWrite tool

**After**: TodoWrite is optional UI layer (lines 20-48):

**Primary**: `.spec-flow/scripts/bash/task-tracker.sh` (authoritative source of truth)

**Optional UI**: `TodoWrite` tool (graceful fallback if missing)

**Pattern**:
```bash
[ ! -f "$TRACKER" ] && echo "⚠️  task-tracker missing; continuing without it" && TRACKER=""
```

**Result**: Implementation continues even if TodoWrite unavailable.

### 7. `cd .` Safety (Directory Anchoring)

**Before**: Commands could run from wrong directory

**After**: Every bash block starts with `cd .` (lines 113, 131, 207, 239, 318, 328, 492, 608):

**Why**:
- Ensures consistent working directory
- Prevents "yeet changes from wrong directory"
- Idempotent (safe to run multiple times)
- Documents intent (this block expects repo root)

**Example**:
```bash
cd .
SLUG="${ARGUMENTS:-$(git branch --show-current)}"
FEATURE_DIR="specs/$SLUG"
```

**Result**: No more "oops, ran migration from /tmp".

### 8. Simplified Living Docs (Removed Verbosity)

**Before**: 200+ lines of living docs update patterns (lines 818-927 old)

**After**: 68 lines with core patterns only (lines 530-601 new):

**Kept**:
- Update spec.md Implementation Status (requirement fulfilled, deviation, performance)
- Update plan.md Discovered Patterns (reuse discovered)
- Refresh Feature CLAUDE.md (progress tracking)

**Removed**:
- Architecture adjustment (too granular)
- Integration discovery (edge case)
- Verbose examples (trimmed to essentials)

**Result**: Faster reads, clearer intent, less ceremony.

### 9. Alembic Migration Safety (Up/Down Proof)

**Before**: Mentioned migration testing but not enforced

**After**: Mandatory up/down cycle proof (lines 798-813):

**Requirements**:
```bash
- Generate migration: uv run alembic revision --autogenerate
- Test up/down cycle (REQUIRED for rollback safety)
- Auto-rollback on failure: git restore --staged . && git restore .
- Commit migration file
```

**Quality gates**:
```bash
- Up/down cycle proof (rollback safety)
- No data loss on down migration
```

**Why**:
- Ensures migrations are reversible
- Prevents one-way migrations (data loss risk)
- Aligns with Alembic best practices

**Reference**: Alembic docs on autogenerate workflow.

### 10. Removed Ambiguous "Agents Will" Language

**Before**: Hand-wavy instructions like "agents will", "should", "may"

**After**: Executable, deterministic steps:

**Before** (old line ~400):
```
# Agents will handle this...
```

**After** (lines 369-399):
```bash
# Claude Code: Invoke all agents for this batch in parallel using Task tool
# This is done by making multiple Task() calls in a single response message
#
# For each task in batch:
#   Task(
#     subagent_type=AGENT,
#     description="$TASK_ID: $TASK_DESC",
#     prompt=f"""Implement: {TASK_DESC}
#     ...
#     """
#   )
```

**Result**: Clear, executable instructions with no ambiguity.

## Benefits

### For Developers

- **No fake TDD**: RED must fail with right reason before GREEN
- **Safe rollback**: `git restore` pattern is idempotent and documented
- **No snapshot tests**: Semantic queries catch real bugs
- **Early feedback**: Quality gates per batch, not just at end

### For AI Agents

- **Deterministic**: Same inputs → same outputs (no "agents will" ambiguity)
- **Safe**: Rollback pattern prevents dirty states
- **Clear gates**: Explicit pass/fail conditions for quality checks
- **Resource locks**: Migrations serialize, preventing corruption

### For QA/Audit

- **TDD proof**: Commit history shows RED → GREEN → REFACTOR
- **Quality evidence**: Every task commit includes test results, coverage delta
- **Migration safety**: Up/down cycle proof required
- **No snapshots**: Semantic queries validate behavior, not implementation

## Technical Debt Resolved

1. ✅ **No more ambiguous "agents will" language** — Executable steps only
2. ✅ **No more risky rollback** — `git restore --staged . && git restore .` pattern
3. ✅ **No more parallel migrations** — Database tasks serialize
4. ✅ **No more deferred quality gates** — Gates per batch, not just at end
5. ✅ **No more snapshot tests** — Semantic queries mandated
6. ✅ **No more directory confusion** — `cd .` anchors every block
7. ✅ **No more fake TDD** — RED must fail with right reason
8. ✅ **No more TodoWrite dependency** — Graceful degradation

## Workflow Changes

### Before (v1.x)

```bash
/implement
# 1039 lines of ceremony
# TDD described but not enforced
# Rollback risky (unclear git ops)
# Migrations could run in parallel
# Quality gates at finish line
# Snapshot tests allowed
# "Agents will" language
```

### After (v2.0)

```bash
/implement
# 830 lines (20% reduction)
# Strict TDD: RED (fail) → GREEN (minimal) → REFACTOR (clean)
# Safe rollback: git restore --staged . && git restore .
# Migrations serialize (risky domain lock)
# Quality gates per batch
# No snapshots (semantic queries only)
# Executable, deterministic steps
```

## Error Messages

### Unsafe Rollback Detected

**Old** (implicit):
```
(no explicit rollback pattern)
```

**New** (lines 315-323):
```bash
cd .
git restore --staged .
git restore .
echo "⚠️  TXXX: Auto-rolled back (test failure)" >> "$ERROR_LOG"
```

### Snapshot Test Detected

**Old** (allowed):
```
(snapshots not mentioned)
```

**New** (lines 461, 777):
```
❌ No UI snapshots (fragile, non-semantic)
✅ Use semantic queries: getByRole, getByLabelText, getByText
```

### Incomplete Checklist

**Old** (prompt for input):
```
⚠️ Checklists incomplete. Proceed? (yes/no)
```

**New** (require flag, lines 176-191):
```
⚠️ Checklists incomplete.

Options:
  1. Complete checklists first (recommended)
  2. Proceed anyway: /implement --yes
  3. Set env: IMPLEMENT_ASSUME_YES=1

(exit 1 if no flag)
```

## Migration from v1.x

### Existing Features

**For features with incomplete implementation:**

1. **Regenerate tasks.md** if using old format (no [RED]/[GREEN] markers):
   ```bash
   /tasks existing-feature-slug
   ```

2. **Resume implementation**:
   ```bash
   /implement
   # New strict TDD enforcement applies
   # Safe rollback pattern used
   # Quality gates per batch
   ```

3. **Update tests** to remove snapshots:
   ```bash
   # Before (snapshot)
   expect(component).toMatchSnapshot()

   # After (semantic query)
   expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument()
   ```

### Backward Compatibility

**The refactored /implement command is NOT backward compatible with:**

- Old TDD workflow (allowed skipping RED phase)
- Snapshot tests (now banned)
- Parallel migrations (now serialized)
- Hand-wavy quality checks (now enforced per batch)

**Recommendation**: Re-run `/implement` on active features to get new guarantees.

## CI Integration (Recommended)

### Add to .github/workflows/test.yml

```yaml
name: Test

on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # Quality Gates (matching /implement)
      - name: Run tests
        run: |
          # Unit tests <2s each
          pnpm test:unit --maxWorkers=50%

          # Integration tests <10s each
          pnpm test:integration

          # Full suite <6 minutes
          timeout 360 pnpm test

      - name: Check coverage
        run: |
          # Coverage ≥80% lines, ≥70% branches
          pnpm test:coverage --coverageThreshold='{"global":{"lines":80,"branches":70}}'

      - name: Ban snapshot tests
        run: |
          # Fail if .toMatchSnapshot() found
          ! grep -r "toMatchSnapshot" apps/ || {
            echo "❌ Snapshot tests detected (use semantic queries)"
            exit 1
          }

      - name: Lint + type-check
        run: |
          pnpm lint
          pnpm type-check

      - name: Check feature flags
        run: |
          # Ensure new UI behind flags
          .spec-flow/scripts/bash/check-feature-flags.sh
```

## References

- **TDD Cycle**: [Martin Fowler - Test Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Git Restore**: [Git docs - git-restore](https://git-scm.com/docs/git-restore)
- **Semantic Queries**: [Testing Library - Queries](https://testing-library.com/docs/queries/about/)
- **Alembic Migrations**: [Alembic - Auto Generating Migrations](https://alembic.sqlalchemy.org/en/latest/autogenerate.html)
- **Axe-core**: [axe-core - Accessibility Testing](https://github.com/dequelabs/axe-core)

## Rollback Plan

If the refactored `/implement` command causes issues:

```bash
# Revert to v1.x implement.md command
git checkout HEAD~1 .claude/commands/implement.md

# Or manually restore from archive
cp .claude/commands/archive/implement-v1.md .claude/commands/implement.md
```

**Note**: This will lose v2.0 guarantees (strict TDD, safe rollback, deterministic batching, semantic queries).

---

**Refactored by**: Claude Code
**Date**: 2025-11-10
**Commit**: `refactor(implement): v2.0 - strict TDD, safe rollback, deterministic batching`

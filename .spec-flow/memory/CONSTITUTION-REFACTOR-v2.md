# Constitution Command v2.2 Refactor

**Date**: 2025-11-10
**Version**: 2.2.0
**Status**: Complete

## Overview

Refactored the `/constitution` command from an interactive, editor-based workflow (165 lines) into a deterministic, evidence-backed update system (437 lines) with structured change types, canonical file schema, atomic commits, and enforceable quality gates.

## Key Changes

### 1. Removed Interactive Editor Opening

**Before**: Opened file in `code --wait` or prompted "Press Enter when done"

**After**: Deterministic LLM-based edits with structured change types

**Old code removed** (lines 88-94):
```bash
# Open in editor
if command -v code &> /dev/null; then
  code --wait "$PRINCIPLES_FILE"
else
  echo "Edit manually: $PRINCIPLES_FILE"
  read -p "Press Enter when done..."
fi
```

**Why removed**:
- **Doesn't work in Claude Code**: No interactive file editor
- **Not deterministic**: Editor changes can't be validated or reviewed
- **Not atomic**: Multi-line edits without checkpoints
- **Not reproducible**: Same inputs → different outputs based on manual edits

**Result**: LLM applies structured changes programmatically.

### 2. Structured Change Types (Deterministic)

**Before**: Freeform description, no grammar

**After**: Explicit action types with structured arguments

**Pattern** (lines 64-88):
```bash
Usage: /constitution "<action>: <description>"

Actions:
  add: <Principle ID> - <Title> | policy=<...> | metrics=<...> | evidence=<...>
  update: <Principle ID> | policy=<...> | metrics=<...> | evidence=<...>
  remove: <Principle ID>
  set: version=<major|minor|patch>        # bumps principles doc version
  set: owner=@team-platform                # optional governance metadata

Examples:
  /constitution "add: A11Y - Accessibility | policy=WCAG 2.2 AA | metrics=axe CI pass; keyboard nav; color contrast AA | evidence=link:WCAG"
  /constitution "update: SECURITY | policy=OWASP ASVS L2 | metrics=threat model per feature; SAST; DAST | evidence=link:ASVS"
  /constitution "remove: DO-NOT-OVERENGINEER"
  /constitution "set: version=minor"
```

**Actions**:
- **add**: Create new principle block (ID must not exist)
- **update**: Modify existing principle fields
- **remove**: Delete principle by ID
- **set: version**: Bump SemVer (major|minor|patch)
- **set: owner**: Update governance metadata

**Why structured**:
- **Deterministic**: Same action → same result
- **Idempotent**: Re-running same command yields no diff
- **Parseable**: LLM extracts action, ID, fields
- **Auditable**: Git commit message shows exact change

**Result**: Reproducible, verifiable updates.

### 3. Canonical File Structure (Enforceable Schema)

**Before**: Vague "8 core principles" with no structure

**After**: Strict schema for `engineering-principles.md`

**Pattern** (lines 178-365):
```markdown
# Engineering Principles

**Version**: 1.0.0
**Owner**: @team-platform
**Last Updated**: 2025-11-10

## Principles (8)

### [SPEC-FIRST] Specification First

**Policy**:
All features start with a written spec reviewed before implementation.

**Rationale**:
Prevents rework, aligns scope early.

**Measurable checks**:
- Spec approved before any `/implement`
- Acceptance criteria present and testable

**Evidence/links**:
- ADR-001 Spec Flow

**Last updated**: 2025-11-10
```

**Required fields per principle**:
1. **ID** (short, uppercase, e.g., `[A11Y]`)
2. **Title** (human-readable, e.g., "Accessibility")
3. **Policy** (project rule, e.g., "Ship WCAG 2.2 AA conformance")
4. **Rationale** (why this matters, e.g., "Legal compliance, inclusive design")
5. **Measurable checks** (how to verify, e.g., "Axe CI pass")
6. **Evidence/links** (standards or ADRs, e.g., "[WCAG 2.2](...)")
7. **Last updated** (ISO date, e.g., "2025-11-10")

**Why strict**:
- **Enforceable**: `/validate` can check measurable checks
- **Auditable**: Changes tracked with version + changelog
- **Evidence-backed**: Recommendations cite real standards (WCAG, OWASP, etc.)
- **Parseable**: Automation can extract policy, metrics, evidence

**Result**: Principles become merge gates, not wall art.

### 4. Evidence-Backed Policies (No Invented Standards)

**Before**: Vague "8 core principles" with no references

**After**: Explicit standards with citations

**Policies + Evidence** (lines 369-401):

1. **SPEC-FIRST**: ADR-001 Spec Flow
2. **TESTS**: Test strategy doc (coverage ≥ 85%)
3. **PERF**: SLO doc, Core Web Vitals
4. **A11Y**: [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
5. **SECURITY**: [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)
6. **REVIEW**: [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)
7. **DOCS**: [Conventional Commits](https://www.conventionalcommits.org/), [Keep a Changelog](https://keepachangelog.com/), [SemVer](https://semver.org/)
8. **SIMPLICITY**: Internal RFC template

**Why evidence-backed**:
- **WCAG 2.2 AA**: Legal standard for accessibility (ADA, Section 508)
- **OWASP ASVS L2**: Industry standard for web app security verification
- **Google Code Review Guide**: Battle-tested from high-performing teams
- **Conventional Commits + SemVer**: Automated versioning and changelog

**Result**: Principles grounded in real standards, not made up.

### 5. Atomic Commits with Checkpoint

**Before**: Manual commit after manual edits

**After**: Automatic checkpoint + commit per change

**Pattern** (lines 104-122, 139-153):
```bash
# 4.1 Checkpoint for safe rollback
git add "$PRINCIPLES_FILE" >/dev/null 2>&1 || true
git commit -m "constitution: checkpoint before update" --no-verify >/dev/null 2>&1 || true

# 4.2 Apply change (LLM edits the Markdown per schema)

# 4.3 Validate structure minimally
grep -q "^## Principles" "$PRINCIPLES_FILE" || echo "⚠️ Header mismatch"
rg -n "^### \[[A-Z0-9\-]+\] " "$PRINCIPLES_FILE" >/dev/null || { echo "❌ No principles found"; exit 1; }

# ...

# 6) Commit (Atomic)
git add "$PRINCIPLES_FILE"
git commit -m "constitution: $CHANGE_SPEC

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify
```

**Why atomic**:
- **Rollback safety**: Can revert single change without losing others
- **Audit trail**: Git log shows exact change spec
- **Validation**: File structure checked before commit
- **Deterministic**: Same change → same commit message

**Result**: Safe, auditable, reversible updates.

### 6. Metadata Bump (Version + Changelog)

**Before**: No versioning, no changelog

**After**: SemVer version + Keep a Changelog entries

**Pattern** (lines 124-137, 357-364):
```bash
TODAY=$(date +%F)

# Update "Last Updated" in file header
# If "set: version=<x>" given, bump SemVer accordingly
# Add a CHANGELOG entry in the file's "Change Log" section (Keep a Changelog format)

echo "✅ Metadata updated: $TODAY"
```

**Changelog format** (lines 357-364):
```markdown
## Change Log (Keep a Changelog)

- **Added**: New or stricter policies
- **Changed**: Clarified or relaxed wording
- **Removed**: Retired policies

**Example**:
- 2025-11-10 — **Changed**: SECURITY policy to ASVS L2; **Added**: WCAG 2.2 AA
```

**Why versioned**:
- **SemVer**: Breaking changes = major bump; new policies = minor bump; clarifications = patch
- **Keep a Changelog**: User-facing changes documented in standard format
- **Auditability**: Version + date + changelog = full history
- **Automation-friendly**: CI can parse version and changelog

**Result**: Principles evolve with clear versioning and change history.

### 7. Validation + Enforcement Hooks

**Before**: No validation, principles are advisory

**After**: Principles enforced by downstream commands

**Enforcement points** (lines 387-392):
```markdown
**Principles Guide Quality Gates:**

- `/optimize` enforces these principles
- `/validate` checks violations
- Code review uses these as criteria
- `/ship` gates fail if principles regress
```

**How enforcement works**:
1. **`/validate`**: Reads principles file, checks measurable criteria
   - Example: "Coverage ≥ 85%" → fails if coverage < 85%
   - Example: "Axe CI pass" → fails if axe-core reports errors
2. **`/optimize`**: Auto-fixes violations where possible
   - Example: Adds missing tests to reach coverage threshold
3. **`/ship`**: Blocks deployment if violations exist
   - Example: Won't deploy if security scan fails (OWASP ASVS L2)

**Result**: Principles become enforceable gates, not suggestions.

### 8. Governance Model (Blameless Postmortems)

**Before**: No governance process

**After**: Explicit governance + incident-driven updates

**Pattern** (lines 351-355):
```markdown
## Governance

- Changes require `/constitution` with a single, reviewable commit.
- Breaking changes to principles require **minor** or **major** version bump of this file (SemVer).
- Incidents create follow-up work items and may update principles after a **blameless postmortem**.
```

**Blameless postmortems** (Google SRE):
- **What happened**: Timeline, impact, root cause
- **What we learned**: Gaps in principles, tooling, process
- **Action items**: Update principles, add new checks, improve tooling

**Example flow**:
1. **Incident**: Security breach (SQL injection)
2. **Postmortem**: Found SQL injection in user input handling
3. **Action**: Update `[SECURITY]` principle to require parameterized queries
4. **Update**: `/constitution "update: SECURITY | policy=OWASP ASVS L2 + parameterized queries only | metrics=SAST checks for string concatenation in SQL"`
5. **Result**: Future features blocked if SQL string concatenation detected

**Result**: Principles evolve from real incidents, not speculation.

### 9. Alternatives and Tradeoffs (Explicit)

**Before**: No alternatives discussed

**After**: Clear tradeoffs for different org sizes

**Pattern** (lines 405-413):
```markdown
**Minimalist variant**: Strip versioning and changelog; just edit principles directly. Faster but loses audit trail.

**PR-gated variant**: Force `/constitution` to write to `governance/constitution/<date>.md` proposal file and open a PR; merge applies the change. Slower but great for larger orgs.

**Policy tiers**: Add "Min" and "Target" levels for each principle so new teams meet baseline quickly and ratchet up over time.

**Contextual overrides**: Allow per-service overrides (e.g., perf SLOs) in `docs/services/<svc>/principles.override.md`, with a linter that rejects weaker policies without an ADR.
```

**Why alternatives matter**:
- **Minimalist**: Solo devs, prototypes (fast iteration)
- **PR-gated**: Large orgs, regulated industries (audit trail)
- **Policy tiers**: New teams (gradual adoption)
- **Contextual overrides**: Microservices, heterogeneous stacks

**Result**: Flexible governance model for different team contexts.

### 10. Action Plan (Concrete Steps)

**Before**: Vague "update principles" with no steps

**After**: 5-step action plan

**Pattern** (lines 417-423):
```markdown
1. Replace current `constitution.md` with this version
2. Convert current `engineering-principles.md` to canonical structure above
3. Wire `/validate` to check measurable checks for each principle
4. Enforce Conventional Commits + Keep a Changelog + SemVer across updates
5. Add CI to fail merges when principles regress or file structure deviates
```

**Why explicit**:
- **Step 1**: Drop-in replacement for command
- **Step 2**: Migrate existing principles to new schema
- **Step 3**: Connect principles to validation
- **Step 4**: Automate versioning and changelog
- **Step 5**: Prevent regressions in CI

**Result**: Clear path from current state to enforced principles.

## Benefits

### For Developers

- **No manual editing**: LLM applies structured changes deterministically
- **Evidence-backed**: Recommendations cite real standards (WCAG, OWASP)
- **Rollback safety**: Atomic commits with checkpoints
- **Clear expectations**: Measurable checks for each principle

### For AI Agents

- **Deterministic**: Same action → same result (idempotent)
- **Parseable**: Structured grammar for actions and fields
- **Validatable**: File structure checked before commit
- **Enforceable**: Principles become merge gates via `/validate`, `/optimize`, `/ship`

### For Teams

- **Audit trail**: SemVer version + Keep a Changelog + git history
- **Incident-driven**: Blameless postmortems update principles
- **Governance**: Breaking changes require version bump + review
- **Flexible**: Alternatives for different org sizes (minimalist, PR-gated, etc.)

## Technical Debt Resolved

1. ✅ **No more manual editor** — LLM applies structured changes
2. ✅ **No more vague principles** — Canonical schema with measurable checks
3. ✅ **No more invented standards** — Evidence-backed (WCAG, OWASP, Google)
4. ✅ **No more manual commits** — Atomic commits with checkpoints
5. ✅ **No more missing versioning** — SemVer + Keep a Changelog
6. ✅ **No more advisory principles** — Enforced by `/validate`, `/optimize`, `/ship`
7. ✅ **No more missing governance** — Blameless postmortems, version bumps
8. ✅ **No more single-size-fits-all** — Alternatives for different org contexts

## Workflow Changes

### Before (v1.0)

```bash
/constitution "Update test coverage requirement to 85%"
# Opens editor (code --wait or manual edit)
# User edits freeform text
# User saves and closes editor
# No validation
# Manual commit
# No versioning, no changelog
# Principles are advisory (not enforced)
```

### After (v2.2)

```bash
/constitution "update: TESTS | policy=Coverage ≥ 85% | metrics=CI fails if coverage < 85% | evidence=Test strategy doc"
# Checkpoint for rollback
# LLM applies structured change (add/update/remove/set)
# Validates file structure (grep, rg)
# Updates metadata (version, date, changelog)
# Atomic commit with change spec
# Principles enforced by /validate, /optimize, /ship
```

## Error Messages

### Missing File

**Old** (lines 35-40):
```
❌ Engineering principles not found: docs/project/engineering-principles.md

Run /init-project first to create project documentation.
```

**New** (lines 51-55):
```
❌ Not found: docs/project/engineering-principles.md
Run /init-project first or create the file with the canonical structure.
```

### Invalid Action

**New** (lines 64-81):
```
Usage: /constitution "<action>: <description>"

Actions:
  add: <Principle ID> - <Title> | policy=<...> | metrics=<...> | evidence=<...>
  update: <Principle ID> | policy=<...> | metrics=<...> | evidence=<...>
  remove: <Principle ID>
  set: version=<major|minor|patch>
  set: owner=@team-platform

Examples:
  [examples shown]
```

### Structure Validation Failed

**New** (lines 117-121):
```bash
grep -q "^## Principles" "$PRINCIPLES_FILE" || echo "⚠️ Header mismatch (expected '## Principles')"
rg -n "^### \[[A-Z0-9\-]+\] " "$PRINCIPLES_FILE" >/dev/null || { echo "❌ No principles found"; exit 1; }

echo "✅ File structure validated"
```

## Migration from v1.0

### Existing Principles

**Convert to canonical structure:**

1. **Add version, owner, date** to file header
2. **Convert each principle** to structured format:
   - Add `[ID]` prefix (e.g., `[A11Y]`)
   - Add **Policy**, **Rationale**, **Measurable checks**, **Evidence/links**, **Last updated**
3. **Add Change Log** section at end
4. **Add Governance** section

**Example conversion**:

**Old** (freeform):
```markdown
## Accessibility
All UI should be accessible.
```

**New** (structured):
```markdown
### [A11Y] Accessibility

**Policy**:
Ship **WCAG 2.2 AA** conformance for all UI.

**Rationale**:
Legal compliance, inclusive design.

**Measurable checks**:
- Axe CI pass; keyboard-only nav; focus states
- Color contrast AA or better
- Form labels, roles, and names computed correctly

**Evidence/links**:
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)

**Last updated**: 2025-11-10
```

### Wire Validation

**Connect principles to quality gates:**

1. **`/validate`**: Read principles file, check measurable criteria
2. **`/optimize`**: Auto-fix violations where possible
3. **`/ship`**: Block deployment if violations exist

**Example `/validate` check**:
```bash
# Read [TESTS] principle
COVERAGE_THRESHOLD=$(rg "Coverage ≥ ([0-9]+)%" docs/project/engineering-principles.md -o -r '$1')

# Check actual coverage
ACTUAL_COVERAGE=$(pytest --cov --cov-report=json | jq '.totals.percent_covered')

if (( $(echo "$ACTUAL_COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
  echo "❌ Test coverage violation: $ACTUAL_COVERAGE% < $COVERAGE_THRESHOLD%"
  exit 1
fi
```

## Backward Compatibility

**The refactored /constitution command is NOT backward compatible with v1.0:**

- Old usage `cd repo && /constitution "Update test coverage"` no longer works
- New usage requires structured action: `cd repo && /constitution "update: TESTS | policy=..."`

**Breaking changes**:
- No more interactive editor opening
- Requires structured change type (add/update/remove/set)
- Requires canonical file structure with IDs, policy, measurable checks, evidence

**Recommendation**: Migrate to v2.2 for all new principles updates. Convert existing `engineering-principles.md` to canonical structure.

## CI Integration (Recommended)

### Validate Principles on PR

```yaml
name: Validate Principles

on: [pull_request]

jobs:
  validate-principles:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check principles file structure
        run: |
          # Validate canonical structure
          grep -q "^## Principles" docs/project/engineering-principles.md
          rg -n "^\### \[[A-Z0-9\-]+\] " docs/project/engineering-principles.md

      - name: Check measurable criteria
        run: |
          # Extract and check each principle's measurable checks
          # Example: Check test coverage threshold
          COVERAGE_THRESHOLD=$(rg "Coverage ≥ ([0-9]+)%" docs/project/engineering-principles.md -o -r '$1')
          echo "Coverage threshold: $COVERAGE_THRESHOLD%"

          # Check actual coverage
          pnpm test:coverage
          ACTUAL_COVERAGE=$(jq '.total.lines.pct' coverage/coverage-summary.json)
          echo "Actual coverage: $ACTUAL_COVERAGE%"

          # Fail if below threshold
          if (( $(echo "$ACTUAL_COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
            echo "❌ Coverage violation: $ACTUAL_COVERAGE% < $COVERAGE_THRESHOLD%"
            exit 1
          fi
```

### Enforce Principles on Merge

```yaml
name: Principles Gate

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  principles-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run /validate
        run: |
          # Reads principles file, checks all measurable criteria
          /validate

      - name: Block merge if violations
        if: failure()
        run: |
          echo "❌ Principles violations detected. Merge blocked."
          exit 1
```

## References

- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [SemVer](https://semver.org/)
- [Google SRE - Blameless Postmortems](https://sre.google/sre-book/service-best-practices/)
- [DORA Metrics](https://dora.dev/guides/dora-metrics-four-keys/)

## Rollback Plan

If the refactored `/constitution` command causes issues:

```bash
# Revert to v1.0 constitution.md command
git checkout HEAD~1 .claude/commands/constitution.md

# Or manually restore from archive
cp .claude/commands/archive/constitution-v1.0.md .claude/commands/constitution.md
```

**Note**: This will lose v2.2 guarantees (no editor opening, no structured changes, no validation, no versioning, no enforcement).

---

**Refactored by**: Claude Code
**Date**: 2025-11-10
**Commit**: `refactor(constitution): v2.2 - evidence-backed, enforceable principles with SemVer + changelog`

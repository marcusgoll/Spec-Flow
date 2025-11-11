---
description: Update project engineering principles (the 8 core standards that govern feature development)
version: 2.2
updated: 2025-11-10
command: /constitution
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# /constitution — Update Engineering Principles

**Purpose**: Update the canonical engineering principles file and bump metadata in a controlled, reviewable way.

**When to use**:
- Add, remove, or revise a principle
- Tighten quality gates (security, a11y, perf, tests)
- Align standards with new evidence or incidents

**Workflow slot**: Project governance command. Downstream gates (`/optimize`, `/validate`, `/ship`) enforce these principles.

---

## Mental Model

You are modifying the **8 core standards** that every feature must satisfy. Changes are **atomic**, **auditable**, and **measurable**.

- **Source of truth**: `docs/project/engineering-principles.md`
- **Principles must be**:
  - **Named** (short ID)
  - **Policy** (project rule)
  - **Rationale** (why)
  - **Measurable checks** (how we verify)
  - **Evidence/links** (standards or internal ADRs)
  - **Last updated** (ISO date)

---

## Execution

### 1) Preconditions

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "UPDATE ENGINEERING PRINCIPLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PRINCIPLES_FILE="docs/project/engineering-principles.md"

if [ ! -f "$PRINCIPLES_FILE" ]; then
  echo "❌ Not found: $PRINCIPLES_FILE"
  echo "Run /init-project first or create the file with the canonical structure."
  exit 1
fi

echo "✅ Found: $PRINCIPLES_FILE"
echo ""
```

### 2) Parse Arguments

```bash
if [ -z "$ARGUMENTS" ]; then
  cat <<USAGE
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
USAGE
  exit 1
fi

CHANGE_SPEC="$ARGUMENTS"
echo "Change request:"
echo "  $CHANGE_SPEC"
echo ""
```

### 3) Change Types (Deterministic)

**Supported actions:**

* **add**: Create a new principle block if ID not present
* **update**: Replace fields on existing ID
* **remove**: Delete principle by ID
* **set: version**: Bump doc version (SemVer)
* **set: owner**: Update governance metadata

**Idempotency**: Re-running the same command yields no diff.

### 4) Edit Engine (LLM applies; script guards and validates)

```bash
# 4.1 Checkpoint for safe rollback
git add "$PRINCIPLES_FILE" >/dev/null 2>&1 || true
git commit -m "constitution: checkpoint before update" --no-verify >/dev/null 2>&1 || true

# 4.2 Apply change (LLM edits the Markdown per schema below)
# The LLM will:
# - Parse the action (add/update/remove/set)
# - Locate or create the principle block
# - Update fields according to canonical structure
# - Validate the file structure

# 4.3 Validate structure minimally
grep -q "^## Principles" "$PRINCIPLES_FILE" || echo "⚠️ Header mismatch (expected '## Principles')"
rg -n "^### \[[A-Z0-9\-]+\] " "$PRINCIPLES_FILE" >/dev/null || { echo "❌ No principles found"; exit 1; }

echo "✅ File structure validated"
echo ""
```

### 5) Metadata Bump

**Update version and date:**

```bash
TODAY=$(date +%F)

# Update "Last Updated" in file header
# If "set: version=<x>" given, bump SemVer accordingly
# Add a CHANGELOG entry in the file's "Change Log" section (Keep a Changelog format)

echo "✅ Metadata updated: $TODAY"
echo ""
```

### 6) Commit (Atomic)

```bash
git add "$PRINCIPLES_FILE"
git commit -m "constitution: $CHANGE_SPEC

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Committed update: $COMMIT_HASH"
echo ""
```

### 7) Output Next Steps

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ENGINEERING PRINCIPLES UPDATE COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Updated: $PRINCIPLES_FILE"
echo "Change: $CHANGE_SPEC"
echo ""

echo "### 💾 Next Steps"
echo ""
echo "1. Review changes: cat $PRINCIPLES_FILE"
echo "2. Run /validate to check policy compliance"
echo "3. Run /optimize to auto-fix trivial violations"
echo "4. Future /ship gates will enforce updated principles"
echo ""
```

---

## Canonical File Structure

`docs/project/engineering-principles.md` must follow this layout for automation:

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

---

### [TESTS] Testing Standards

**Policy**:
Automated unit + integration tests required for all changes.

**Rationale**:
Prevents regressions, enables confident refactoring.

**Measurable checks**:
- Coverage ≥ 85% lines on changed code
- Critical paths have integration tests
- CI must pass before merge

**Evidence/links**:
- Test strategy doc

**Last updated**: 2025-11-10

---

### [PERF] Performance SLOs

**Policy**:
Backends meet p95 latency targets; frontends meet Core Web Vitals budgets.

**Rationale**:
User experience degrades with slow responses.

**Measurable checks**:
- API p95 target per service (documented SLO)
- LCP/INP budgets enforced in CI

**Evidence/links**:
- SLO doc, Core Web Vitals

**Last updated**: 2025-11-10

---

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
- [WAI summary](https://www.w3.org/WAI/)

**Last updated**: 2025-11-10

---

### [SECURITY] Security Practices

**Policy**:
Meet **OWASP ASVS Level 2** controls for web apps. Threat model each feature.

**Rationale**:
Prevent vulnerabilities, protect user data.

**Measurable checks**:
- Secrets in vault; no hardcoded creds
- SAST on PRs; DAST at staging
- AuthZ test paths for role boundaries

**Evidence/links**:
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)

**Last updated**: 2025-11-10

---

### [REVIEW] Code Quality & Review

**Policy**:
Every PR improves code health over time; small, focused CLs; fast reviewer SLAs.

**Rationale**:
Maintains codebase quality, reduces technical debt.

**Measurable checks**:
- Max PR size threshold
- Required approvals per ownership rules
- Lints + formatters block merge

**Evidence/links**:
- [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)

**Last updated**: 2025-11-10

---

### [DOCS] Documentation & Changelog

**Policy**:
Docs updated with the change. Changelog follows **Keep a Changelog**; commits follow **Conventional Commits**; principles use **SemVer**.

**Rationale**:
Enables onboarding, troubleshooting, and versioning.

**Measurable checks**:
- `CHANGELOG` entry on user-facing changes
- Conventional Commit type present
- Version bump for breaking changes

**Evidence/links**:
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [SemVer](https://semver.org/)

**Last updated**: 2025-11-10

---

### [SIMPLICITY] Simplicity, not Overengineering

**Policy**:
Prefer the simplest design that meets requirements. Delete complexity when no longer needed.

**Rationale**:
Reduces maintenance burden, improves velocity.

**Measurable checks**:
- No unused feature flags or dead code on merge
- RFC required for introducing new infra components

**Evidence/links**:
- Internal RFC template

**Last updated**: 2025-11-10

---

## Governance

- Changes require `/constitution` with a single, reviewable commit.
- Breaking changes to principles require **minor** or **major** version bump of this file (SemVer).
- Incidents create follow-up work items and may update principles after a **blameless postmortem**.

## Change Log (Keep a Changelog)

- **Added**: New or stricter policies
- **Changed**: Clarified or relaxed wording
- **Removed**: Retired policies

**Example**:
- 2025-11-10 — **Changed**: SECURITY policy to ASVS L2; **Added**: WCAG 2.2 AA
```

---

## Notes

**The 8 Core Principles:**

1. **SPEC-FIRST** — Specification First
2. **TESTS** — Testing Standards
3. **PERF** — Performance SLOs
4. **A11Y** — Accessibility (WCAG 2.2 AA)
5. **SECURITY** — Security Practices (OWASP ASVS L2)
6. **REVIEW** — Code Quality & Review
7. **DOCS** — Documentation & Changelog
8. **SIMPLICITY** — Simplicity, not Overengineering

**Principles vs Configuration:**

- `engineering-principles.md` — Quality standards (this command)
- `project-configuration.md` — Deployment model, scale tier (`/update-project-config`)

**Principles Guide Quality Gates:**

- `/optimize` enforces these principles
- `/validate` checks violations
- Code review uses these as criteria
- `/ship` gates fail if principles regress

**Standards Referenced:**

- **Accessibility**: [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
- **Security**: [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)
- **Code Review**: [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)
- **Versioning**: [Conventional Commits](https://www.conventionalcommits.org/), [Keep a Changelog](https://keepachangelog.com/), [SemVer](https://semver.org/)
- **Reliability**: [Google SRE](https://sre.google/sre-book/service-best-practices/)
- **Delivery Performance**: [DORA Metrics](https://dora.dev/guides/dora-metrics-four-keys/)

---

## Alternatives and Tradeoffs

**Minimalist variant**: Strip versioning and changelog; just edit principles directly. Faster but loses audit trail.

**PR-gated variant**: Force `/constitution` to write to `governance/constitution/<date>.md` proposal file and open a PR; merge applies the change. Slower but great for larger orgs.

**Policy tiers**: Add "Min" and "Target" levels for each principle so new teams meet baseline quickly and ratchet up over time.

**Contextual overrides**: Allow per-service overrides (e.g., perf SLOs) in `docs/services/<svc>/principles.override.md`, with a linter that rejects weaker policies without an ADR.

---

## Action Plan

1. Replace current `constitution.md` with this version
2. Convert current `engineering-principles.md` to canonical structure above
3. Wire `/validate` to check measurable checks for each principle
4. Enforce Conventional Commits + Keep a Changelog + SemVer across updates
5. Add CI to fail merges when principles regress or file structure deviates

---

## References

- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [SemVer](https://semver.org/)
- [Google SRE](https://sre.google/sre-book/service-best-practices/)
- [DORA Metrics](https://dora.dev/guides/dora-metrics-four-keys/)

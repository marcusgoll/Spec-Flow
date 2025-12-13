---
name: constitution
description: Add, update, or remove engineering principles in docs/project/engineering-principles.md with atomic versioned commits
argument-hint: "<action>: <description>" (e.g., "add: A11Y - Accessibility | policy=...")
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash(git add:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git status:*), Bash(date:*)]
---

# /constitution — Update Engineering Principles

<context>
**User Input**: $ARGUMENTS

**Current Git Status**: !`git status --short 2>/dev/null || echo "clean"`

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Principles File Exists**: !`test -f docs/project/engineering-principles.md && echo "Yes" || echo "No"`

**Principles File**: @docs/project/engineering-principles.md

**Recent Constitution Commits**: !`git log --oneline --grep="constitution:" -5 2>/dev/null || echo "none"`
</context>

<objective>
Update the canonical engineering principles file (docs/project/engineering-principles.md) with atomic, auditable changes to the 8 core standards that govern feature development.

**Purpose**: Modify quality gates, add/update/remove principles, and maintain governance metadata with version control.

**When to use**:
- Add, remove, or revise a principle
- Tighten quality gates (security, accessibility, performance, tests)
- Align standards with new evidence or incidents
- Bump principle document version

**Workflow position**: Project governance command. Downstream gates (`/optimize`, `/validate`, `/ship`) enforce these principles.
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent implementation errors.

1. **Never modify the file without reading it first**
   - Always Read docs/project/engineering-principles.md before making changes
   - Verify file structure matches canonical template
   - Quote current content when analyzing changes

2. **Verify file existence before proceeding**
   - Use Grep to check file exists
   - If not found, instruct user to run /init-project first
   - Don't assume file structure - read and verify

3. **Validate principle structure after changes**
   - Check for required headers (## Principles)
   - Verify principle IDs match pattern: `### [ID] Title`
   - Ensure all required fields present (Policy, Rationale, Measurable checks, Evidence, Last updated)

4. **Quote arguments exactly**
   - Parse $ARGUMENTS precisely without adding interpretation
   - If arguments unclear, show usage examples and ask for clarification
   - Never guess at action types or field values

5. **Verify git operations succeeded**
   - Check git commit with rev-parse after committing
   - Confirm file staged with git status
   - Quote actual commit hash in output

**Why this matters**: Principles file governs all quality gates. Incorrect changes break downstream automation and enforce wrong standards.

---

## Mental Model

You are modifying the **8 core standards** that every feature must satisfy. Changes are **atomic**, **auditable**, and **measurable**.

- **Source of truth**: `docs/project/engineering-principles.md`
- **Principles must be**:
  - **Named** (short ID like `[A11Y]` or `[SECURITY]`)
  - **Policy** (project rule statement)
  - **Rationale** (why this matters)
  - **Measurable checks** (how we verify compliance)
  - **Evidence/links** (standards or internal ADRs)
  - **Last updated** (ISO date)

---

<process>

### Step 1: Verify Prerequisites

**Check that principles file exists:**
1. Read docs/project/engineering-principles.md
2. If not found, display error:
   ```
   ❌ Not found: docs/project/engineering-principles.md

   Run /init-project first or create the file with the canonical structure.
   See "Canonical File Structure" section below.
   ```
3. If found, confirm:
   ```
   ✅ Found: docs/project/engineering-principles.md
   ```

### Step 2: Parse Arguments

**If $ARGUMENTS is empty**, display usage:

```
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

**If $ARGUMENTS provided**, parse the action type:
- Extract action: `add`, `update`, `remove`, or `set`
- Extract principle ID if applicable
- Extract field values (policy, metrics, evidence) from pipe-delimited format
- Display parsed change request:
  ```
  Change request:
    {$ARGUMENTS}
  ```

### Step 3: Determine Change Type

**Supported actions:**

- **add**: Create a new principle block if ID not already present
  - Check if principle ID exists using Grep
  - If exists, display error and stop
  - If not, proceed to add new principle section

- **update**: Replace fields on existing principle ID
  - Locate principle by ID using Grep
  - If not found, display error and stop
  - Update specified fields only (policy, metrics, evidence)
  - Preserve other fields unchanged

- **remove**: Delete entire principle block by ID
  - Locate principle by ID
  - Remove from `### [ID]` to next `---` separator or next principle
  - Decrease principle count in header

- **set: version**: Bump document version (SemVer)
  - Parse version field in file header
  - Apply major/minor/patch increment
  - Update version field

- **set: owner**: Update governance metadata
  - Update Owner field in file header

**Idempotency**: Re-running the same command yields no diff.

### Step 4: Create Git Checkpoint

**Before making changes:**
1. Stage the current principles file:
   ```bash
   git add docs/project/engineering-principles.md
   ```

2. Create checkpoint commit (allow failure if no changes):
   ```bash
   git commit -m "constitution: checkpoint before update" --no-verify
   ```
   *(Ignore errors if nothing to commit)*

### Step 5: Apply Changes to File

**Edit docs/project/engineering-principles.md using Edit tool:**

**For `add` action:**
1. Locate the `## Principles` section
2. Add new principle block before the last principle or at end:
   ```markdown
   ### [{ID}] {Title}

   **Policy**:
   {policy value from arguments}

   **Rationale**:
   {rationale - infer or ask user}

   **Measurable checks**:
   {metrics value from arguments, formatted as bullet list}

   **Evidence/links**:
   {evidence value from arguments}

   **Last updated**: {current date YYYY-MM-DD}

   ---
   ```
3. Increment principle count in header if present

**For `update` action:**
1. Locate principle by ID: `### [{ID}]`
2. Update specified fields only:
   - If `policy=` provided, replace **Policy**: section
   - If `metrics=` provided, replace **Measurable checks**: section
   - If `evidence=` provided, replace **Evidence/links**: section
3. Update **Last updated**: to current date

**For `remove` action:**
1. Locate principle block by ID
2. Delete from `### [{ID}]` to next `---` separator
3. Decrement principle count in header

**For `set: version` action:**
1. Locate version field in header: `**Version**: X.Y.Z`
2. Apply SemVer bump (major/minor/patch)
3. Update version field

**For `set: owner` action:**
1. Locate owner field in header: `**Owner**: @team`
2. Update owner value

### Step 6: Validate File Structure

**After applying changes, validate:**

1. Check for required header:
   ```bash
   grep -q "^## Principles" docs/project/engineering-principles.md
   ```
   If missing, display warning: `⚠️ Header mismatch (expected '## Principles')`

2. Check for principle IDs:
   ```bash
   grep -E "^### \[[A-Z0-9\-]+\] " docs/project/engineering-principles.md
   ```
   If no matches, display error: `❌ No principles found` and stop

3. Display confirmation:
   ```
   ✅ File structure validated
   ```

### Step 7: Update Metadata

**Update Last Updated timestamp:**
1. Get current date in ISO format (YYYY-MM-DD)
2. Update header metadata:
   - **Last Updated**: {current date}
3. If `set: version` was specified, version already updated in Step 5

**Add CHANGELOG entry** (if file has Change Log section):
1. Locate `## Change Log` section
2. Add entry at top:
   ```markdown
   - {current date} — **{Added|Changed|Removed}**: {brief description of change}
   ```

Display confirmation:
```
✅ Metadata updated: {current date}
```

### Step 8: Commit Changes Atomically

**Create atomic commit:**

1. Stage the updated file:
   ```bash
   git add docs/project/engineering-principles.md
   ```

2. Commit with descriptive message:
   ```bash
   git commit -m "constitution: $ARGUMENTS

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify
   ```

3. Verify commit succeeded and get hash:
   ```bash
   git rev-parse --short HEAD
   ```

4. Display commit confirmation:
   ```
   ✅ Committed update: {commit hash}
   ```

### Step 9: Display Next Steps

**Output summary to user:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ENGINEERING PRINCIPLES UPDATE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated: docs/project/engineering-principles.md
Change: {$ARGUMENTS}
Commit: {hash}

### 💾 Next Steps

1. Review changes: Read docs/project/engineering-principles.md
2. Run /validate to check policy compliance across features
3. Run /optimize to auto-fix trivial violations
4. Future /ship gates will enforce updated principles
```

</process>

<success_criteria>
**Constitution update successfully completed when:**

1. **Principles file modified correctly**:
   - File read before modifications
   - Changes applied according to action type (add/update/remove/set)
   - File structure validated after changes
   - No syntax errors in markdown

2. **Metadata updated**:
   - Last Updated field shows current date
   - Version bumped if `set: version` specified
   - CHANGELOG entry added (if section exists)

3. **Git operations successful**:
   - Checkpoint commit created (or gracefully skipped)
   - Final commit created with atomic changes
   - Commit hash retrieved and displayed
   - Working tree clean after commit

4. **Validation passed**:
   - `## Principles` header present
   - Principle IDs match pattern `### [ID] Title`
   - All modified principles have required fields
   - File structure remains valid

5. **User informed**:
   - Summary displayed with file path, change description, commit hash
   - Next steps provided
   - No errors or warnings (unless expected)
</success_criteria>

<verification>
**Before marking constitution update complete, verify:**

1. **Read updated file**:
   ```bash
   cat docs/project/engineering-principles.md
   ```
   Should show applied changes

2. **Check file structure**:
   ```bash
   grep "^## Principles" docs/project/engineering-principles.md
   grep -E "^### \[[A-Z0-9\-]+\] " docs/project/engineering-principles.md
   ```
   Both should return matches

3. **Verify git commit**:
   ```bash
   git log -1 --oneline
   ```
   Should show "constitution:" commit

4. **Check commit hash**:
   ```bash
   git rev-parse --short HEAD
   ```
   Should return valid hash

5. **Validate working tree**:
   ```bash
   git status
   ```
   Should show clean working tree or only unrelated changes

**Never claim completion without reading the updated file and verifying commit hash.**
</verification>

<output>
**Files created/modified by this command:**

**Principles file**:
- docs/project/engineering-principles.md — Updated with principle changes

**Git commits**:
- Checkpoint commit (optional, may skip if no changes)
- Final atomic commit: "constitution: {$ARGUMENTS}"

**Console output**:
- Verification status (file found, structure validated)
- Change summary (action type, principle affected)
- Commit hash confirmation
- Next steps recommendation
</output>

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

### The 8 Core Principles

1. **SPEC-FIRST** — Specification First
2. **TESTS** — Testing Standards
3. **PERF** — Performance SLOs
4. **A11Y** — Accessibility (WCAG 2.2 AA)
5. **SECURITY** — Security Practices (OWASP ASVS L2)
6. **REVIEW** — Code Quality & Review
7. **DOCS** — Documentation & Changelog
8. **SIMPLICITY** — Simplicity, not Overengineering

### Principles vs Configuration

- `engineering-principles.md` — Quality standards (this command)
- `project-configuration.md` — Deployment model, scale tier (`/update-project-config`)

### Principles Guide Quality Gates

- `/optimize` enforces these principles
- `/validate` checks violations
- Code review uses these as criteria
- `/ship` gates fail if principles regress

### Standards Referenced

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

## References

- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [Google Code Review Guide](https://google.github.io/eng-practices/review/reviewer/standard.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [SemVer](https://semver.org/)
- [Google SRE](https://sre.google/sre-book/service-best-practices/)
- [DORA Metrics](https://dora.dev/guides/dora-metrics-four-keys/)

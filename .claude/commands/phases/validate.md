---
description: Analyze spec, plan, and tasks for consistency violations, breaking changes, and constitution compliance. Generates analysis-report.md with CRITICAL/MAJOR/MINOR findings.
allowed-tools: [Read, Grep, Glob, Bash(python .spec-flow/scripts/spec-cli.py validate:*), Bash(git status:*), Bash(git commit:*), Bash(git add:*), Bash(ls:*), Bash(cat:*), Bash(wc:*)]
argument-hint: [feature-slug] [--quick|--constitution]
---

<context>
Current workflow state: !`cat specs/*/workflow-state.yaml 2>/dev/null | grep -A5 current_phase || echo "No workflow state found"`

Feature spec exists: !`test -f specs/*/spec.md && echo "✅ Found" || echo "❌ Missing"`

Plan exists: !`test -f specs/*/plan.md && echo "✅ Found" || echo "❌ Missing"`

Tasks exist: !`test -f specs/*/tasks.md && echo "✅ Found" || echo "❌ Missing"`

Constitution exists: !`test -f docs/project/constitution.md && echo "✅ Found" || echo "❌ Missing (run /init-project)"`

Previous validation: !`ls -1 specs/*/analysis-report.md 2>/dev/null | wc -l` report(s) found
</context>

<objective>
Cross-artifact consistency analysis to validate implementation readiness.

**Analyzes:**
- Spec ↔ Plan ↔ Tasks consistency
- Constitution compliance (8 engineering principles)
- Breaking changes (API, schema, env vars)
- Test coverage completeness
- Implementation readiness

**Outputs:**
- analysis-report.md with CRITICAL/MAJOR/MINOR findings
- Recommendation: PROCEED | FIX_CRITICAL | FIX_ALL

**Operating constraints:**
- **STRICTLY READ-ONLY** — Never modify spec, plan, or tasks files
- **Constitution Authority** — Constitution violations auto-CRITICAL
- **Token Efficient** — Max 50 findings, aggregate overflow
- **Deterministic** — Consistent finding IDs across runs

**Dependencies:**
- Git repository initialized
- spec.md, plan.md, tasks.md completed
- Optional: docs/project/constitution.md for principle validation
</objective>

<process>
1. **Execute validation workflow** via spec-cli.py:
   ```bash
   python .spec-flow/scripts/spec-cli.py validate "$ARGUMENTS"
   ```

   The validate-workflow.sh script performs:
   a. **Prerequisite validation** — Runs check-prerequisites.sh with --require-tasks flag
   b. **Load artifacts** — Reads spec.md, plan.md, tasks.md, constitution.md
   c. **Run 6 detection passes**:
      - Pass 1: Constitution violations (auto-CRITICAL)
      - Pass 2: Spec ↔ Plan consistency
      - Pass 3: Plan ↔ Tasks consistency
      - Pass 4: Breaking changes (API, schema, env vars)
      - Pass 5: Test coverage analysis
      - Pass 6: Implementation readiness
   d. **Assign severity** — CRITICAL/MAJOR/MINOR based on implementation impact
   e. **Generate report** — Creates analysis-report.md with findings and remediation
   f. **Git commit** — Commits validation report
   g. **Suggest next** — Recommends /implement or fix blockers

2. **Read generated report**:
   - Load `specs/*/analysis-report.md` (created by script)
   - Review executive summary with severity counts
   - Examine findings grouped by severity (CRITICAL → MAJOR → MINOR)

3. **Assess severity distribution**:

   **CRITICAL (Blocks implementation):**
   - Constitution violations
   - Spec-plan contradictions (different tech stack, incompatible requirements)
   - Missing external dependencies (APIs, services not provisioned)
   - Breaking changes without migration plan

   **MAJOR (Causes rework):**
   - Plan-tasks misalignment (tasks don't implement plan sections)
   - Incomplete test coverage (acceptance criteria without tests)
   - Unclear implementation details (authentication flow ambiguous)

   **MINOR (Nice to fix):**
   - Cosmetic inconsistencies (different terminology for same concept)
   - Optional test coverage (edge cases for rare scenarios)
   - Documentation gaps (missing inline comments, README updates)

   **Decision logic:**
   ```
   IF critical_findings > 0 THEN
     recommendation = FIX_CRITICAL
   ELSE IF major_findings > 5 THEN
     recommendation = FIX_ALL
   ELSE
     recommendation = PROCEED
   END IF
   ```

4. **Present results to user**:

   **Summary format:**
   ```
   Validation Summary

   Feature: {slug}
   Artifacts analyzed: spec.md, plan.md, tasks.md, constitution.md

   Findings:
     CRITICAL: {count} (blocks implementation)
     MAJOR: {count} (causes rework)
     MINOR: {count} (nice to fix)

   Constitution compliance: {PASS|FAIL}

   Top issues:
     1. [CRITICAL-001] {Title} - {Impact}
     2. [CRITICAL-002] {Title} - {Impact}
     3. [MAJOR-001] {Title} - {Impact}

   Recommendation: {PROCEED|FIX_CRITICAL|FIX_ALL}
   ```

5. **Suggest next action** based on recommendation:

   **PROCEED (No blockers):**
   ```
   ✅ No critical issues found. Ready for implementation.

   Next: /implement

   All artifacts are consistent. {minor_count} minor findings can be addressed during implementation.
   ```

   **FIX_CRITICAL ({count} blockers):**
   ```
   ❌ {count} critical findings block implementation

   Blockers:
     {List CRITICAL findings with remediation}

   Fix these issues first, then re-run /validate to verify.
   ```

   **FIX_ALL (Too many major issues):**
   ```
   ⚠️  {major_count} major issues will cause implementation rework

   Recommendation: Fix major issues before /implement to avoid costly rework.

   Options:
     A) Fix all major issues now (recommended)
     B) Proceed anyway (risk: 30-40% rework during implementation)
   ```
</process>

<verification>
Before completing, verify:
- analysis-report.md created in specs/*/
- Report contains all 6 detection pass results
- Severity counts match findings list
- Recommendation (PROCEED/FIX_CRITICAL/FIX_ALL) is present
- Report committed to git
- Next-step suggestions presented based on severity distribution
</verification>

<success_criteria>
**Report generation:**
- analysis-report.md exists in specs/{NNN-slug}/
- Executive summary includes severity counts
- Findings grouped by severity (CRITICAL → MAJOR → MINOR)
- Each finding includes: ID, Title, Severity, Category, Location, Impact, Evidence, Remediation
- Recommendation section with rationale

**Severity accuracy:**
- Constitution violations automatically CRITICAL
- Spec-plan contradictions marked CRITICAL
- Plan-tasks misalignment marked MAJOR
- Cosmetic inconsistencies marked MINOR

**Git commit:**
- analysis-report.md committed with message "validate: Add validation report for {slug}"
- NOTES.md updated with validation checkpoint

**User guidance:**
- Summary presented with clear severity breakdown
- Top 3 issues highlighted
- Next action recommended based on findings
- Remediation steps provided for CRITICAL findings
</success_criteria>

<anti_hallucination_rules>
**CRITICAL**: Follow these rules to prevent false validation findings.

1. **Never report inconsistencies without verification**
   - ❌ BAD: "spec.md probably doesn't match plan.md"
   - ✅ GOOD: Read both files, extract specific quotes, compare them
   - Use Read tool for all files before claiming inconsistencies

2. **Cite exact line numbers when reporting issues**
   - Format: "spec.md:45 says 'POST /users' but plan.md:120 says 'POST /api/users'"
   - Include exact quotes from both files
   - Don't paraphrase - quote verbatim

3. **Never invent missing test coverage**
   - Don't say "Missing test for user creation" unless you verified no test exists
   - Use Grep to search for test files: `test.*user.*create`
   - If uncertain whether test exists, search before claiming it's missing

4. **Verify constitution rules exist before citing violations**
   - Read constitution.md before claiming violations
   - Quote exact rule violated: "Violates constitution.md:25 'All APIs must use OpenAPI contracts'"
   - Don't invent constitution rules

5. **Never fabricate severity levels**
   - Use actual severity assessment based on impact
   - CRITICAL: Blocks implementation, MAJOR: Causes rework, MINOR: Nice to fix
   - Don't inflate severity without evidence

**Why this matters**: False inconsistencies waste time investigating non-issues. Invented missing tests create unnecessary work. Accurate validation based on actual file reads builds trust in the validation process.

See `.claude/skills/analysis-phase/references/reference.md` for structured reasoning approach and detailed anti-hallucination examples.
</anti_hallucination_rules>

<standards>
**Industry Standards:**
- **Artifact Consistency**: [Semantic Versioning](https://semver.org/) for breaking change detection
- **Test Coverage**: [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) principles

**Workflow Standards:**
- All findings cite exact file:line locations
- Severity assigned based on implementation impact
- Constitution violations automatically CRITICAL
- Deterministic finding IDs across runs
- Max 50 findings to prevent context overflow
</standards>

<notes>
**Script location**: `.spec-flow/scripts/bash/validate-workflow.sh`

**Reference documentation**: Anti-hallucination rules, reasoning approach, detection passes (6 types), severity assessment criteria, report structure, validation modes (full, quick, constitution-only), and all detailed procedures are in `.claude/skills/analysis-phase/references/reference.md`.

**Version**: v2.0 (2025-11-17) — Refactored to XML structure, added dynamic context, tool restrictions

**Validation modes:**
- Default: All 6 passes (constitution, consistency, breaking changes, test coverage, readiness)
- --quick: Constitution + spec-plan consistency only
- --constitution: Constitution validation only

**Next steps after validation:**
- PROCEED: `/implement` (no blockers)
- FIX_CRITICAL: Fix blockers, re-run `/validate`
- FIX_ALL: Fix major issues or risk 30-40% rework
</notes>

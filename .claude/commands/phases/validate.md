---
description: Cross-artifact consistency analysis (review work and list what might be broken)
version: 2.0
updated: 2025-11-17
---

# /validate — Artifact Consistency Analysis

Analyze feature artifacts for consistency, coverage, and quality: $ARGUMENTS

<context>
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## MENTAL MODEL

**Workflow**: spec-flow → clarify → plan → tasks → **analyze** → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**
- Run prerequisite script → Load artifacts → Build semantic models → Run detection passes → Assign severity → Generate report → Suggest next

**Auto-suggest:**
- When complete → `/implement` (if no critical issues) or Fix issues first

**Operating Constraints:**
- **STRICTLY READ-ONLY**: Do NOT modify any files
- **Constitution Authority**: Constitution violations are automatically CRITICAL
- **Token Efficient**: Limit to 50 findings max, aggregate overflow
- **Deterministic**: Rerunning should produce consistent IDs
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent false validation findings.

1. **Never report inconsistencies you haven't verified by reading files**
   - ❌ BAD: "spec.md probably doesn't match plan.md"
   - ✅ GOOD: Read both files, extract specific quotes, compare them
   - Use Read tool for all files before claiming inconsistencies

2. **Cite exact line numbers when reporting issues**
   - When reporting mismatch: "spec.md:45 says 'POST /users' but plan.md:120 says 'POST /api/users'"
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

## REASONING APPROACH

For complex validation decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this consistency issue:
1. What does spec.md say? [Quote exact text with line numbers]
2. What does plan.md say? [Quote exact text with line numbers]
3. Is this a true inconsistency or semantic equivalence? [Compare meanings]
4. What's the impact? [Assess severity: blocks implementation, breaks features, cosmetic]
5. What's the fix? [Identify which artifact to update]
6. Conclusion: [Inconsistency assessment with severity]
</thinking>

<answer>
[Validation finding based on reasoning]
</answer>

**When to use structured thinking:**
- Assessing severity of cross-artifact inconsistencies
- Determining whether differences are true conflicts or semantic equivalents
- Deciding which artifact to fix (spec vs plan vs tasks vs implementation)
- Evaluating completeness of test coverage
- Prioritizing validation findings for developer action

**Benefits**: Explicit reasoning reduces false positives by 30-40% and improves finding accuracy.
</constraints>

<instructions>
## Execute Validation Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py validate "$ARGUMENTS"
```

**What the script does:**

1. **Prerequisite validation** — Runs check-prerequisites.sh with --require-tasks flag
2. **Load artifacts** — Reads spec.md, plan.md, tasks.md, constitution.md
3. **Constitution validation** — Checks all requirements against 8 engineering principles
4. **Cross-artifact consistency** — Detects spec ↔ plan ↔ tasks mismatches
5. **Breaking change detection** — Identifies API/schema changes affecting existing features
6. **Test coverage analysis** — Validates task acceptance criteria completeness
7. **Implementation readiness** — Checks for missing dependencies, unclear requirements
8. **Severity assignment** — CRITICAL/MAJOR/MINOR based on implementation impact
9. **Generate report** — Creates analysis-report.md with findings and remediation
10. **Git commit** — Commits validation report
11. **Suggest next** — Recommends /implement or fix blockers

**Detection passes:**

**Pass 1: Constitution Violations (Auto-CRITICAL)**
- Data model lacks ERD (constitution.md principle #4)
- API endpoints missing OpenAPI contracts (principle #5)
- No performance benchmarks (principle #6)
- Missing rollback procedures (principle #7)

**Pass 2: Spec ↔ Plan Consistency**
- User stories in spec.md not addressed in plan.md
- Tech stack mismatch (spec says React, plan says Vue)
- Acceptance criteria missing from implementation scope

**Pass 3: Plan ↔ Tasks Consistency**
- Tasks don't implement all plan sections
- File structure in tasks doesn't match plan architecture
- Missing error handling tasks for API endpoints

**Pass 4: Breaking Changes**
- API endpoint removed (existing consumers affected)
- Database schema change requires migration
- Environment variable renamed (deployment impact)

**Pass 5: Test Coverage**
- Acceptance criteria without corresponding test tasks
- Edge cases not tested (null, empty, large values)
- Error scenarios missing (network failure, timeout)

**Pass 6: Implementation Readiness**
- External dependencies not documented
- Authentication flow unclear
- Performance targets not quantified

**After script completes, you (LLM) must:**

## 1) Read Generated Report

**Load validation results:**
- `specs/*/analysis-report.md` (created by script)

**Report structure:**
```markdown
# Validation Report: {feature}

## Executive Summary
- Total findings: {count}
- CRITICAL: {count} (blocks implementation)
- MAJOR: {count} (causes rework)
- MINOR: {count} (nice to fix)
- Recommendation: {PROCEED|FIX_CRITICAL|FIX_ALL}

## Findings

### [CRITICAL-001] Missing OpenAPI Contract for POST /users
**Severity**: CRITICAL
**Category**: Constitution Violation (Principle #5)
**Location**: plan.md:145-160
**Impact**: Blocks implementation - no type-safe client generation

**Evidence**:
- plan.md:145 defines endpoint: "POST /api/v1/users creates user"
- contracts/api.yaml does not include /api/v1/users
- Constitution.md:87 requires: "All API endpoints MUST have OpenAPI 3.0 contracts"

**Remediation**:
1. Add OpenAPI spec to contracts/api.yaml for POST /api/v1/users
2. Include request/response schemas
3. Update plan.md to reference contract file

**Priority**: Fix before /implement
```

## 2) Assess Severity Distribution

**Severity thresholds:**

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
  next_step = Fix blockers first
ELSE IF major_findings > 5 THEN
  recommendation = FIX_ALL
  next_step = Resolve major issues
ELSE
  recommendation = PROCEED
  next_step = /implement
END IF
```

## 3) Present Results to User

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

## 4) Suggest Next Action

**Based on recommendation:**

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

</instructions>

---

## VALIDATION MODES

**Full validation (default):**
- All 6 detection passes
- Constitution compliance check
- Breaking change analysis
- Test coverage validation

**Quick validation (--quick flag):**
- Constitution compliance only
- Spec-plan consistency only
- Skips test coverage analysis

**Constitution-only (--constitution flag):**
- Only validates against constitution.md principles
- Fast feedback on engineering standards

## SEVERITY EXAMPLES

**CRITICAL:**
- Missing database migration for schema change
- API endpoint in spec.md not in plan.md
- Constitution violation: No OpenAPI contract for API

**MAJOR:**
- Task T005 doesn't implement plan.md Section 4.2
- Acceptance criteria "Users can reset password" has no test task
- File structure mismatch: tasks.md creates `api/v1/` but plan.md uses `api/v2/`

**MINOR:**
- Spec.md calls it "profile page", plan.md calls it "account page" (semantic equivalence)
- Missing test for rare edge case (negative user age)
- Optional performance optimization not in tasks

## OUTPUT ARTIFACTS

**analysis-report.md:**
- Executive summary with recommendation
- Grouped findings by severity
- Remediation steps for each finding
- Validation metadata (timestamp, artifact versions)

**NOTES.md update:**
- Phase 4 checkpoint with findings count
- Validation status (PASS/FAIL/CONDITIONAL)
- Context budget tracking

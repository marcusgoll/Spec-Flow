# Analysis Phase — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-17

This document provides comprehensive reference material for the `/validate` command, including anti-hallucination rules, detection passes, severity assessment, and validation workflows.

---

## Table of Contents

1. [Anti-Hallucination Rules](#anti-hallucination-rules)
2. [Reasoning Approach](#reasoning-approach)
3. [Detection Passes](#detection-passes)
4. [Severity Assessment](#severity-assessment)
5. [Report Structure](#report-structure)
6. [Validation Modes](#validation-modes)
7. [Output Artifacts](#output-artifacts)

---

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent false validation findings.

### Rule 1: Never Report Inconsistencies Without Verification

- ❌ **BAD**: "spec.md probably doesn't match plan.md"
- ✅ **GOOD**: Read both files, extract specific quotes, compare them
- **Requirement**: Use Read tool for all files before claiming inconsistencies

**Example violation:**
```
"The API endpoint in spec.md doesn't match the plan"
```

**Correct approach:**
```
Reading spec.md...
spec.md:45 says: "POST /users endpoint for user creation"

Reading plan.md...
plan.md:120 says: "POST /api/users endpoint for user creation"

Inconsistency detected: Path mismatch (/users vs /api/users)
```

### Rule 2: Cite Exact Line Numbers

When reporting mismatch, include:
- File name with line number
- Exact quotes from both files
- Don't paraphrase - quote verbatim

**Example:**
```markdown
### [CRITICAL-001] API Path Mismatch

**Evidence**:
- spec.md:45 says 'POST /users'
- plan.md:120 says 'POST /api/users'

**Impact**: Spec and plan describe different API paths
```

### Rule 3: Never Invent Missing Test Coverage

- Don't say "Missing test for user creation" unless you verified no test exists
- Use Grep to search for test files: `test.*user.*create`
- If uncertain whether test exists, search before claiming it's missing

**Verification process:**
1. Search for test files related to the feature
2. Search for test names matching the functionality
3. Only report missing if search returns no results

**Example:**
```bash
# Before claiming missing test coverage
grep -r "test.*user.*creation" tests/
# If no results, then report missing coverage
```

### Rule 4: Verify Constitution Rules Before Citing Violations

- Read constitution.md before claiming violations
- Quote exact rule violated: "Violates constitution.md:25 'All APIs must use OpenAPI contracts'"
- Don't invent constitution rules

**Example:**
```markdown
### [CRITICAL-002] Constitution Violation

**Evidence**:
- Constitution.md:87 requires: "All API endpoints MUST have OpenAPI 3.0 contracts"
- plan.md:145 defines endpoint: "POST /api/v1/users creates user"
- contracts/api.yaml does not include /api/v1/users

**Verdict**: Violates constitution principle #5 (API Contract Stability)
```

### Rule 5: Never Fabricate Severity Levels

Use actual severity assessment based on impact:
- **CRITICAL**: Blocks implementation
- **MAJOR**: Causes rework
- **MINOR**: Nice to fix

Don't inflate severity without evidence.

**Why This Matters**:
- False inconsistencies waste time investigating non-issues
- Invented missing tests create unnecessary work
- Accurate validation based on actual file reads builds trust in the validation process
- Reduces false positives by 30-40%

---

## Reasoning Approach

For complex validation decisions, show step-by-step reasoning using structured thinking.

### When to Use Structured Thinking

- Assessing severity of cross-artifact inconsistencies
- Determining whether differences are true conflicts or semantic equivalents
- Deciding which artifact to fix (spec vs plan vs tasks vs implementation)
- Evaluating completeness of test coverage
- Prioritizing validation findings for developer action

### Structured Thinking Template

```xml
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
```

### Example: Semantic Equivalence vs True Conflict

**Scenario**: Spec says "profile page", plan says "account page"

```xml
<thinking>
1. spec.md:34 says: "Users can edit their profile page"
2. plan.md:78 says: "Implement account page with edit functionality"
3. Semantic analysis: "profile page" and "account page" likely refer to the same screen
4. Impact: Cosmetic - different terminology for same concept, unlikely to cause implementation confusion
5. Fix: Update spec.md or plan.md to use consistent terminology (MINOR priority)
6. Conclusion: MINOR severity - semantic equivalence, not a blocking inconsistency
</thinking>

<answer>
### [MINOR-001] Terminology Inconsistency

**Severity**: MINOR
**Category**: Semantic Equivalence
**Location**: spec.md:34, plan.md:78

**Evidence**:
- spec.md:34: "Users can edit their profile page"
- plan.md:78: "Implement account page with edit functionality"

**Assessment**: Different terminology for same concept. Not a blocking issue.

**Remediation**: Update spec.md or plan.md to use consistent terminology ("profile page" or "account page" throughout)
</answer>
```

**Benefits**: Explicit reasoning reduces false positives by 30-40% and improves finding accuracy.

---

## Detection Passes

The validation workflow runs **6 detection passes** to identify issues across different categories.

### Pass 1: Constitution Violations (Auto-CRITICAL)

Constitution violations are automatically assigned **CRITICAL** severity because they represent violations of the project's engineering principles.

**What it detects:**
- Data model lacks ERD (constitution.md principle #4)
- API endpoints missing OpenAPI contracts (principle #5)
- No performance benchmarks (principle #6)
- Missing rollback procedures (principle #7)

**Example finding:**
```markdown
### [CRITICAL-001] Missing OpenAPI Contract

**Severity**: CRITICAL
**Category**: Constitution Violation (Principle #5: API Contract Stability)
**Location**: plan.md:145-160

**Evidence**:
- plan.md:145 defines endpoint: "POST /api/v1/users creates user"
- contracts/api.yaml does not include /api/v1/users
- Constitution.md:87 requires: "All API endpoints MUST have OpenAPI 3.0 contracts"

**Impact**: Blocks implementation - no type-safe client generation

**Remediation**:
1. Add OpenAPI spec to contracts/api.yaml for POST /api/v1/users
2. Include request/response schemas
3. Update plan.md to reference contract file
```

### Pass 2: Spec ↔ Plan Consistency

Detects mismatches between what the spec promises and what the plan implements.

**What it detects:**
- User stories in spec.md not addressed in plan.md
- Tech stack mismatch (spec says React, plan says Vue)
- Acceptance criteria missing from implementation scope

**Example finding:**
```markdown
### [CRITICAL-002] Missing User Story Implementation

**Severity**: CRITICAL
**Category**: Spec-Plan Inconsistency
**Location**: spec.md:56-62, plan.md

**Evidence**:
- spec.md:56-62 defines user story: "As a student, I want to track my progress across ACS areas"
- plan.md does not include implementation for progress tracking feature

**Impact**: Blocks implementation - user story not in scope

**Remediation**:
Add progress tracking implementation to plan.md Section 4.2
```

### Pass 3: Plan ↔ Tasks Consistency

Detects mismatches between the plan's architecture and the tasks' implementation steps.

**What it detects:**
- Tasks don't implement all plan sections
- File structure in tasks doesn't match plan architecture
- Missing error handling tasks for API endpoints

**Example finding:**
```markdown
### [MAJOR-001] Unimplemented Plan Section

**Severity**: MAJOR
**Category**: Plan-Tasks Inconsistency
**Location**: plan.md:145-160, tasks.md

**Evidence**:
- plan.md:145-160 defines "Authentication Middleware" section
- tasks.md does not include tasks for authentication middleware implementation

**Impact**: Causes rework - plan section will be discovered during implementation

**Remediation**:
Add tasks T015-T018 for authentication middleware:
- T015: Create JWT verification middleware
- T016: Add role-based access control
- T017: Test authentication edge cases
- T018: Update API routes to use auth middleware
```

### Pass 4: Breaking Changes

Detects changes that could affect existing features, consumers, or deployments.

**What it detects:**
- API endpoint removed (existing consumers affected)
- Database schema change requires migration
- Environment variable renamed (deployment impact)

**Example finding:**
```markdown
### [CRITICAL-003] Breaking Database Schema Change

**Severity**: CRITICAL
**Category**: Breaking Change
**Location**: plan.md:89-95

**Evidence**:
- plan.md:89 changes User.email from VARCHAR(255) to VARCHAR(100)
- Existing data may exceed 100 character limit
- No migration plan for existing records

**Impact**: Blocks deployment - data loss risk

**Remediation**:
1. Add data validation query to check existing email lengths
2. Create migration script to handle oversized emails
3. Add rollback procedure if migration fails
```

### Pass 5: Test Coverage

Validates that all acceptance criteria have corresponding test tasks.

**What it detects:**
- Acceptance criteria without corresponding test tasks
- Edge cases not tested (null, empty, large values)
- Error scenarios missing (network failure, timeout)

**Example finding:**
```markdown
### [MAJOR-002] Missing Test Coverage

**Severity**: MAJOR
**Category**: Test Coverage
**Location**: spec.md:67, tasks.md

**Evidence**:
- spec.md:67 acceptance criteria: "Users can reset their password"
- tasks.md does not include test task for password reset functionality

**Impact**: Causes rework - untested feature may have bugs

**Remediation**:
Add task T025: Test password reset flow
- Test valid email receives reset link
- Test invalid email shows error
- Test expired reset token is rejected
```

### Pass 6: Implementation Readiness

Checks if the plan provides sufficient detail for implementation to begin.

**What it detects:**
- External dependencies not documented
- Authentication flow unclear
- Performance targets not quantified

**Example finding:**
```markdown
### [MAJOR-003] Unclear Implementation Detail

**Severity**: MAJOR
**Category**: Implementation Readiness
**Location**: plan.md:120-125

**Evidence**:
- plan.md:120 mentions "Use third-party email service" but doesn't specify which service
- No API credentials documented
- No fallback strategy for service outage

**Impact**: Causes rework - implementation will stall when email integration is reached

**Remediation**:
1. Specify email service provider (SendGrid, Mailgun, AWS SES)
2. Document required API credentials in .env.example
3. Define fallback strategy (retry logic, circuit breaker)
```

---

## Severity Assessment

Severity levels determine priority and whether findings block implementation.

### CRITICAL (Blocks Implementation)

**Definition**: Issues that **prevent implementation from starting** or **guarantee production failures**.

**Criteria:**
- Constitution violations
- Spec-plan contradictions (different tech stack, incompatible requirements)
- Missing external dependencies (APIs, services not provisioned)
- Breaking changes without migration plan

**Examples:**
- Missing database migration for schema change
- API endpoint in spec.md not in plan.md
- Constitution violation: No OpenAPI contract for API
- External API credentials not documented

**Decision logic:**
```
IF critical_findings > 0 THEN
  recommendation = FIX_CRITICAL
  next_step = "Fix blockers first, then re-run /validate"
END IF
```

### MAJOR (Causes Rework)

**Definition**: Issues that **allow implementation to start** but **will cause rework during or after implementation**.

**Criteria:**
- Plan-tasks misalignment (tasks don't implement plan sections)
- Incomplete test coverage (acceptance criteria without tests)
- Unclear implementation details (authentication flow ambiguous)

**Examples:**
- Task T005 doesn't implement plan.md Section 4.2
- Acceptance criteria "Users can reset password" has no test task
- File structure mismatch: tasks.md creates `api/v1/` but plan.md uses `api/v2/`

**Decision logic:**
```
IF critical_findings == 0 AND major_findings > 5 THEN
  recommendation = FIX_ALL
  next_step = "Resolve major issues to avoid 30-40% rework"
END IF
```

### MINOR (Nice to Fix)

**Definition**: Issues that are **cosmetic or low-impact** and won't affect implementation quality.

**Criteria:**
- Cosmetic inconsistencies (different terminology for same concept)
- Optional test coverage (edge cases for rare scenarios)
- Documentation gaps (missing inline comments, README updates)

**Examples:**
- Spec.md calls it "profile page", plan.md calls it "account page" (semantic equivalence)
- Missing test for rare edge case (negative user age)
- Optional performance optimization not in tasks

**Decision logic:**
```
IF critical_findings == 0 AND major_findings <= 5 THEN
  recommendation = PROCEED
  next_step = "/implement (MINOR findings can be addressed during implementation)"
END IF
```

---

## Report Structure

The validation script generates `analysis-report.md` with the following structure:

### Executive Summary

```markdown
# Validation Report: {feature-slug}

## Executive Summary

- **Total findings**: {count}
- **CRITICAL**: {count} (blocks implementation)
- **MAJOR**: {count} (causes rework)
- **MINOR**: {count} (nice to fix)
- **Recommendation**: {PROCEED|FIX_CRITICAL|FIX_ALL}

**Artifacts analyzed**:
- spec.md (version: {git-commit-hash})
- plan.md (version: {git-commit-hash})
- tasks.md (version: {git-commit-hash})
- constitution.md (version: {git-commit-hash})

**Constitution compliance**: {PASS|FAIL}

**Validation timestamp**: {ISO-8601-datetime}
```

### Findings Section

Each finding includes:
- **ID**: Unique identifier (CRITICAL-001, MAJOR-002, MINOR-003)
- **Title**: Concise description
- **Severity**: CRITICAL | MAJOR | MINOR
- **Category**: Constitution Violation | Spec-Plan Inconsistency | Plan-Tasks Inconsistency | Breaking Change | Test Coverage | Implementation Readiness
- **Location**: File:line references
- **Impact**: Implementation consequences
- **Evidence**: Quoted text from files with line numbers
- **Remediation**: Step-by-step fix instructions
- **Priority**: When to fix (before /implement, during implementation, optional)

**Example:**
```markdown
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

### Recommendation Section

```markdown
## Recommendation

{PROCEED|FIX_CRITICAL|FIX_ALL}

**Rationale**:
{Explanation of why this recommendation is made based on severity distribution}

**Next Steps**:
{Specific actions to take}
```

---

## Validation Modes

The validation script supports three modes for different use cases:

### Full Validation (Default)

**Command:**
```bash
python .spec-flow/scripts/spec-cli.py validate
```

**What it does:**
- All 6 detection passes
- Constitution compliance check
- Breaking change analysis
- Test coverage validation

**When to use:**
- Before running `/implement` for the first time
- After making significant changes to spec, plan, or tasks
- Before committing to a major refactor

**Output**: Complete analysis-report.md with all findings

### Quick Validation (--quick flag)

**Command:**
```bash
python .spec-flow/scripts/spec-cli.py validate --quick
```

**What it does:**
- Constitution compliance only
- Spec-plan consistency only
- **Skips**: Test coverage analysis, breaking change detection, implementation readiness

**When to use:**
- During iterative spec/plan editing
- Quick sanity check before full validation
- When you only care about high-level consistency

**Output**: Abbreviated analysis-report.md with constitution and spec-plan findings only

### Constitution-Only (--constitution flag)

**Command:**
```bash
python .spec-flow/scripts/spec-cli.py validate --constitution
```

**What it does:**
- Only validates against constitution.md principles
- Fast feedback on engineering standards

**When to use:**
- After updating constitution.md
- Verifying compliance with specific engineering principle
- Quick check during plan drafting

**Output**: Minimal analysis-report.md with constitution findings only

---

## Output Artifacts

### analysis-report.md

**Location**: `specs/{NNN-feature-slug}/analysis-report.md`

**Structure**:
1. Executive Summary (severity counts, recommendation)
2. Findings (grouped by severity: CRITICAL → MAJOR → MINOR)
3. Recommendation (PROCEED | FIX_CRITICAL | FIX_ALL)
4. Validation Metadata (timestamp, artifact versions)

**Usage**: Reviewed by developer to fix issues before implementation

### NOTES.md Update

**Location**: `specs/{NNN-feature-slug}/NOTES.md`

**What's added**:
- Phase 4 checkpoint with findings count
- Validation status (PASS | FAIL | CONDITIONAL)
- Context budget tracking

**Example entry**:
```markdown
## Phase 4: Validation

**Timestamp**: 2025-11-20 14:30:00
**Status**: CONDITIONAL (2 CRITICAL findings)
**Findings**: 2 CRITICAL, 5 MAJOR, 3 MINOR

**Recommendation**: FIX_CRITICAL

**Context Budget**: 45,000 tokens used (22% of 200,000)
```

---

## Operating Constraints

### Strictly Read-Only

**Rule**: `/validate` NEVER modifies any files except:
- Creating `analysis-report.md`
- Updating `NOTES.md` with validation checkpoint

**Enforcement**: The `allowed-tools` restriction prevents file modifications.

### Constitution Authority

**Rule**: Constitution violations are **automatically CRITICAL** severity.

**Rationale**: The constitution represents the team's engineering principles. Violating them is non-negotiable.

**Example**: If constitution.md says "All APIs must have OpenAPI contracts" and a plan defines an API without a contract, that's automatically CRITICAL.

### Token Efficient

**Rule**: Limit validation findings to **50 max** to prevent context overflow.

**Aggregation**: If more than 50 findings detected:
- Report first 50 by severity (all CRITICAL, then MAJOR, then MINOR)
- Add summary: "... and 25 additional MINOR findings (see full report)"

**Rationale**: 50 findings is already overwhelming. More detail doesn't help.

### Deterministic

**Rule**: Re-running validation on same artifacts should produce **consistent finding IDs**.

**Implementation**: Finding IDs are generated deterministically based on:
- Category prefix (CRITICAL, MAJOR, MINOR)
- Sequential number within category
- Findings sorted by file:line location before numbering

**Benefit**: Developers can reference findings by ID across validation runs.

---

## Next Steps After Validation

### PROCEED (No Blockers)

**Condition**: `critical_findings == 0 AND major_findings <= 5`

**Message:**
```
✅ No critical issues found. Ready for implementation.

Next: /implement

All artifacts are consistent. {minor_count} minor findings can be addressed during implementation.
```

### FIX_CRITICAL ({count} Blockers)

**Condition**: `critical_findings > 0`

**Message:**
```
❌ {count} critical findings block implementation

Blockers:
  {List CRITICAL findings with remediation}

Fix these issues first, then re-run /validate to verify.
```

### FIX_ALL (Too Many Major Issues)

**Condition**: `critical_findings == 0 AND major_findings > 5`

**Message:**
```
⚠️  {major_count} major issues will cause implementation rework

Recommendation: Fix major issues before /implement to avoid costly rework.

Options:
  A) Fix all major issues now (recommended)
  B) Proceed anyway (risk: 30-40% rework during implementation)
```

---

## References

- **Skill**: `.claude/skills/analysis-phase/SKILL.md` (full SOP)
- **Scripts**: `.spec-flow/scripts/bash/validate-workflow.sh`
- **Constitution**: `docs/project/constitution.md` (8 engineering principles)

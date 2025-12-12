# Error Log: [FEATURE_NAME]

**Feature**: [NNN-feature-name]
**Created**: [YYYY-MM-DD]

This log tracks failures, learnings, and ghost context cleanup during implementation.

---

## Entry Format

- **Failure**: What broke or failed
- **Symptom**: Observable behavior (errors, incorrect behavior, test failures)
- **Learning**: Root cause and key insights
- **Ghost Context Cleanup**: Retired artifacts, corrected assumptions, removed dead code
- **Regression Test**: Test file capturing bug to prevent recurrence

---

## Entries

### Entry 1: [YYYY-MM-DD] - Initial Setup

**Failure**: N/A (feature not yet implemented)
**Symptom**: N/A
**Learning**: Pre-implementation log created per constitution requirement
**Ghost Context Cleanup**: N/A
**Regression Test**: N/A (no bug to capture)

### Entry N: [YYYY-MM-DD] - [Error Title] (ERR-XXXX)

**Failure**: [What broke or failed]
**Symptom**: [Observable behavior - errors, timeouts, incorrect output]
**Learning**: [Root cause from 5 Whys analysis]
**Ghost Context Cleanup**: [Retired artifacts, corrected assumptions]
**Regression Test**:
- **File**: `tests/regression/regression-ERR-XXXX-slug.test.ts`
- **Status**: Generated | Passing | Needs Update
- **Validates**: [What the test checks to prevent recurrence]

---

## Guidelines

- Add entries IMMEDIATELY when failures occur
- Include timestamps and task IDs (e.g., "During T023 middleware update")
- Be specific about ghost context: file paths, variable names, assumptions
- Update during /implement phase as issues arise
- Use /debug command to systematically debug and update this log
- **Regression tests are auto-generated** during /debug - review and approve before committing
- Keep regression test reference updated as tests are modified or moved

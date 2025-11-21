# Implementation Gaps

**Epic/Feature**: {EPIC_SLUG}
**Iteration**: {ITERATION_NUMBER}
**Discovered At**: {PHASE_NAME} phase
**Discovered By**: {USER_NAME}
**Timestamp**: {ISO8601_TIMESTAMP}

---

## Gap {GAP_ID}: {GAP_TITLE}

**Source**: {SPEC_FILE}:{LINE_NUMBERS}
**Priority**: {PRIORITY}  <!-- P1, P2, P3 -->
**Scope Status**: {SCOPE_STATUS}  <!-- ✅ IN SCOPE | ❌ OUT OF SCOPE | ⚠️ AMBIGUOUS -->
**Subsystems**: {AFFECTED_SUBSYSTEMS}

### Description

{GAP_DESCRIPTION}

### Scope Validation

{VALIDATION_EVIDENCE}
<!-- Example evidence items:
- ✅ Mentioned in epic-spec.md:45 "Backend authentication endpoints"
- ✅ Backend subsystem marked as involved
- ✅ NOT in "Out of Scope" section
- ✅ Aligns with success metric: "User can view profile"
-->

### Impact

{IMPACT_DESCRIPTION}

### Acceptance Criteria

*From {SPEC_FILE}*:

- [ ] {CRITERION_1}
- [ ] {CRITERION_2}
- [ ] {CRITERION_3}

### Supplemental Tasks

<!-- Only populated if scope status is IN SCOPE -->

{SUPPLEMENTAL_TASKS_LIST}
<!-- Example:
- T031: Implement GET /v1/auth/me endpoint
- T032: Add integration test for /v1/auth/me
- T033: Update API documentation
-->

### Recommendation

{RECOMMENDATION_TEXT}
<!-- Examples:
- IN SCOPE: "Generate supplemental tasks for implementation in iteration {N}"
- OUT OF SCOPE: "Create new epic/feature for this functionality after current work completes"
- AMBIGUOUS: "Requires user decision - see scope validation evidence above"
-->

---

## Summary

- **Total Gaps**: {TOTAL_GAPS}
- **In Scope**: {IN_SCOPE_COUNT} ✅
- **Out of Scope**: {OUT_OF_SCOPE_COUNT} ❌
- **Ambiguous**: {AMBIGUOUS_COUNT} ⚠️
- **Supplemental Tasks Generated**: {SUPPLEMENTAL_TASK_COUNT}

### Next Steps

<!-- If in_scope_count > 0 -->
1. Review generated supplemental tasks in tasks.md
2. Run `/epic continue` or `/feature continue` to execute iteration {NEXT_ITERATION}
3. Re-validate after implementation completes

### Deferred Gaps (Out of Scope)

<!-- List gaps that were blocked as feature creep -->

{OUT_OF_SCOPE_GAPS_LIST}
<!-- Example:
- Gap 002: Social Login Buttons - Create new epic after current completion
-->

---

## Gap Documentation Guidelines

When capturing gaps during validation:

1. **Be Specific**: Describe exactly what's missing (e.g., "Missing /v1/auth/me endpoint" not "Auth doesn't work")
2. **Reference Source**: Link to spec file and line numbers where requirement was defined
3. **Validate Scope**: System will auto-check against epic-spec.md or spec.md
4. **Prioritize**: P1 (Blocking), P2 (Important), P3 (Nice to have)
5. **Document Impact**: Explain how gap affects user experience or system functionality

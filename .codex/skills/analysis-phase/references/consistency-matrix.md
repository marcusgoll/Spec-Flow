<cross_artifact_consistency_matrix>

<validation_rules>

<rule name="spec_to_plan">
**Check**: Each spec requirement has corresponding plan component

**How**:
1. Extract requirements from spec.md (look for ## headings, bullet lists under "Requirements")
2. Extract components from plan.md (look for ### headings under "Components")
3. Map each requirement to component(s)
4. Flag unmapped requirements

**Example**:
- Spec: "Users can export data to CSV"
- Plan: "### Export Service - Handles CSV generation and download"
- Status: ✓ Mapped
</rule>

<rule name="plan_to_tasks">
**Check**: Each plan component broken into tasks

**How**:
1. Extract components from plan.md
2. Extract tasks from tasks.md (look for T### task IDs)
3. Verify each component has ≥1 task
4. Flag components without tasks

**Example**:
- Plan: "### Authentication Service"
- Tasks: "T001: Implement JWT token generation", "T002: Add token validation middleware"
- Status: ✓ Mapped (2 tasks)
</rule>

<rule name="task_to_spec_criteria">
**Check**: Task acceptance criteria align with spec success criteria

**How**:
1. Extract success criteria from spec.md
2. Extract acceptance criteria from tasks.md
3. Verify alignment
4. Flag mismatches

**Example**:
- Spec success: "Users can log in within 2 seconds"
- Task acceptance: "Login API responds in <200ms (p95)"
- Status: ✓ Aligned (supports spec goal)
</rule>

<rule name="no_orphans">
**Check**: No orphaned tasks (tasks without plan component)

**How**:
1. Extract all tasks from tasks.md
2. Map each task to plan component
3. Flag tasks with no corresponding component

**Example**:
- Task: "T099: Add logging to dashboard"
- Plan: No "Dashboard Observability" component
- Status: ✗ Orphaned (add component or remove task)
</rule>

</validation_rules>

<consistency_table>
| From Artifact | To Artifact | Validation Check | Flag If |
|---------------|-------------|------------------|---------|
| Spec requirements | Plan components | Each requirement → ≥1 component | Unmapped requirement |
| Plan components | Tasks | Each component → ≥1 task | Component without tasks |
| Tasks criteria | Spec criteria | Criteria alignment | Mismatch or missing |
| Tasks | Plan components | Each task → 1 component | Orphaned task |
| Dependencies (plan) | Dependencies (tasks) | All mentioned → documented | Undocumented dependency |
</consistency_table>

</cross_artifact_consistency_matrix>

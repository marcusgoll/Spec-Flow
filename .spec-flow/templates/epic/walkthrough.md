# Epic Walkthrough: {{EPIC_TITLE}}

> Generated on {{GENERATED_DATE}} after successful completion of Epic #{{EPIC_NUMBER}}

---

## Overview

| Metric | Value |
|--------|-------|
| **Epic** | #{{EPIC_NUMBER}} - {{EPIC_SLUG}} |
| **Started** | {{START_DATE}} |
| **Completed** | {{END_DATE}} |
| **Duration** | {{DURATION_DAYS}} days ({{DURATION_HOURS}}h work time) |
| **Sprints** | {{SPRINT_COUNT}} |
| **Tasks Completed** | {{TASKS_COMPLETED}} |

### Business Value Delivered

{{BUSINESS_VALUE}}

### Velocity Metrics

| Metric | Expected | Actual | Delta |
|--------|----------|--------|-------|
| Duration | {{EXPECTED_HOURS}}h | {{ACTUAL_HOURS}}h | {{DURATION_DELTA}} |
| Velocity Multiplier | {{EXPECTED_VELOCITY}}x | {{ACTUAL_VELOCITY}}x | {{VELOCITY_DELTA}} |
| Parallel Efficiency | - | {{PARALLEL_EFFICIENCY}}% | - |

---

## Phase Timeline

```
{{PHASE_TIMELINE_ASCII}}
```

### Phase Details

#### Phase 0: Specification
- **Duration**: {{SPEC_DURATION}}
- **Key Decisions**: {{SPEC_DECISIONS}}
- **Artifacts**: epic-spec.md

#### Phase 1: Research & Planning
- **Duration**: {{PLAN_DURATION}}
- **Key Findings**: {{RESEARCH_FINDINGS}}
- **Architecture Decisions**: {{ARCH_DECISIONS}}
- **Artifacts**: research.md, plan.md

#### Phase 2: Sprint Breakdown
- **Duration**: {{TASKS_DURATION}}
- **Sprints Generated**: {{SPRINT_COUNT}}
- **Execution Layers**: {{LAYER_COUNT}}
- **Contracts Locked**: {{CONTRACT_COUNT}}
- **Artifacts**: sprint-plan.md, tasks.md

#### Phase 3: Implementation
- **Duration**: {{IMPL_DURATION}}
- **Parallel Sprints**: {{PARALLEL_SPRINT_DETAILS}}
- **Blockers Encountered**: {{BLOCKER_COUNT}}
- **Artifacts**: Implementation code in sprints/

#### Phase 4: Optimization
- **Duration**: {{OPT_DURATION}}
- **Quality Gate Results**: {{QUALITY_RESULTS}}
- **Issues Fixed**: {{ISSUES_FIXED}}
- **Artifacts**: optimization-report.md

#### Phase 5: Deployment
- **Duration**: {{DEPLOY_DURATION}}
- **Environment**: {{DEPLOY_ENV}}
- **Release Version**: {{VERSION}}
- **Rollback ID**: {{ROLLBACK_ID}}

---

## Sprint Execution Summary

### Dependency Graph

```
{{DEPENDENCY_GRAPH_ASCII}}
```

### Sprint Details

{{#SPRINTS}}
#### Sprint {{SPRINT_ID}}: {{SPRINT_NAME}}
- **Layer**: {{LAYER}}
- **Dependencies**: {{DEPENDENCIES}}
- **Estimated**: {{ESTIMATED_HOURS}}h
- **Actual**: {{ACTUAL_HOURS}}h
- **Accuracy**: {{ESTIMATION_ACCURACY}}%
- **Status**: {{STATUS}}
- **Key Files**:
{{#FILES}}
  - `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/FILES}}
{{/SPRINTS}}

### Parallelization Analysis

| Layer | Sprints | Sequential Time | Parallel Time | Speedup |
|-------|---------|-----------------|---------------|---------|
{{#LAYERS}}
| {{LAYER_NUM}} | {{SPRINT_IDS}} | {{SEQ_HOURS}}h | {{PAR_HOURS}}h | {{SPEEDUP}}x |
{{/LAYERS}}

**Total Speedup**: {{TOTAL_SPEEDUP}}x ({{TIME_SAVED}}h saved)

---

## Quality Gates

### Gate Results

| Gate | Status | Score | Details |
|------|--------|-------|---------|
| Tests | {{TEST_STATUS}} | {{TEST_COVERAGE}}% coverage | {{TEST_DETAILS}} |
| Security | {{SEC_STATUS}} | {{SEC_SCORE}}/100 | {{SEC_DETAILS}} |
| Performance | {{PERF_STATUS}} | {{PERF_SCORE}}/100 | {{PERF_DETAILS}} |
| Accessibility | {{A11Y_STATUS}} | {{A11Y_SCORE}}/100 | {{A11Y_DETAILS}} |
| Code Quality | {{CODE_STATUS}} | {{CODE_SCORE}}/100 | {{CODE_DETAILS}} |

### Issues Caught by Gates

{{#GATE_ISSUES}}
- **{{ISSUE_GATE}}**: {{ISSUE_DESCRIPTION}} ({{ISSUE_SEVERITY}}) - {{ISSUE_RESOLUTION}}
{{/GATE_ISSUES}}

---

## Key Files Modified

### By Category

#### Backend
{{#BACKEND_FILES}}
- `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/BACKEND_FILES}}

#### Frontend
{{#FRONTEND_FILES}}
- `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/FRONTEND_FILES}}

#### Database
{{#DATABASE_FILES}}
- `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/DATABASE_FILES}}

#### Infrastructure
{{#INFRA_FILES}}
- `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/INFRA_FILES}}

#### Tests
{{#TEST_FILES}}
- `{{FILE_PATH}}` - {{FILE_DESCRIPTION}}
{{/TEST_FILES}}

### File Statistics

| Category | Files Added | Files Modified | Lines Changed |
|----------|-------------|----------------|---------------|
| Backend | {{BE_ADDED}} | {{BE_MODIFIED}} | +{{BE_ADDED_LINES}}/-{{BE_REMOVED_LINES}} |
| Frontend | {{FE_ADDED}} | {{FE_MODIFIED}} | +{{FE_ADDED_LINES}}/-{{FE_REMOVED_LINES}} |
| Database | {{DB_ADDED}} | {{DB_MODIFIED}} | +{{DB_ADDED_LINES}}/-{{DB_REMOVED_LINES}} |
| Tests | {{TEST_ADDED}} | {{TEST_MODIFIED}} | +{{TEST_ADDED_LINES}}/-{{TEST_REMOVED_LINES}} |
| **Total** | {{TOTAL_ADDED}} | {{TOTAL_MODIFIED}} | +{{TOTAL_ADDED_LINES}}/-{{TOTAL_REMOVED_LINES}} |

---

## Deployment Information

### Release Details

| Field | Value |
|-------|-------|
| Version | {{VERSION}} |
| Release Date | {{RELEASE_DATE}} |
| GitHub Release | {{GITHUB_RELEASE_URL}} |
| Deployment URL | {{DEPLOYMENT_URL}} |
| Rollback Command | `{{ROLLBACK_COMMAND}}` |

### Deployment Verification

- [ ] Health checks passing
- [ ] Smoke tests passing
- [ ] No error spikes in monitoring
- [ ] Performance within thresholds

---

## Retrospective

### What Worked Well

{{#WORKED_WELL}}
- {{ITEM}}
{{/WORKED_WELL}}

### What Struggled

{{#STRUGGLED}}
- {{ITEM}}
{{/STRUGGLED}}

### Lessons Learned

{{#LESSONS}}
1. **{{LESSON_TITLE}}**: {{LESSON_DESCRIPTION}}
{{/LESSONS}}

### Estimation Accuracy

| Sprint | Estimated | Actual | Accuracy | Notes |
|--------|-----------|--------|----------|-------|
{{#ESTIMATION_TABLE}}
| {{SPRINT_ID}} | {{ESTIMATED}}h | {{ACTUAL}}h | {{ACCURACY}}% | {{NOTES}} |
{{/ESTIMATION_TABLE}}

**Average Accuracy**: {{AVG_ACCURACY}}%
**Recommendation**: {{ESTIMATION_RECOMMENDATION}}

---

## Next Steps

### Future Enhancements

{{#FUTURE_ENHANCEMENTS}}
- **{{ENHANCEMENT_TITLE}}** ({{PRIORITY}}): {{ENHANCEMENT_DESCRIPTION}}
{{/FUTURE_ENHANCEMENTS}}

### Technical Debt

{{#TECH_DEBT}}
- **{{DEBT_TITLE}}**: {{DEBT_DESCRIPTION}} ({{DEBT_EFFORT}})
{{/TECH_DEBT}}

### Monitoring & Alerts

{{#MONITORING}}
- **{{METRIC_NAME}}**: {{METRIC_THRESHOLD}} - {{METRIC_ACTION}}
{{/MONITORING}}

---

## Appendix

### Commit History

```
{{COMMIT_LOG}}
```

### Related Artifacts

- [Epic Specification](./epic-spec.md)
- [Research Document](./research.md)
- [Implementation Plan](./plan.md)
- [Sprint Plan](./sprint-plan.md)
- [Task Breakdown](./tasks.md)
- [Optimization Report](./optimization-report.md)
- [Audit Report](./audit-report.xml)

### References

{{#REFERENCES}}
- {{REFERENCE}}
{{/REFERENCES}}

---

*This walkthrough was generated by the Spec-Flow workflow system.*
*For questions about this epic, refer to the artifacts in `epics/{{EPIC_SLUG}}/`.*

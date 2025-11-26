# Conventional Commits Templates

## Format

```
<type>(<scope>): <subject line (max 50 chars)>

<body (optional, wrapped at 72 chars)>

<footer (optional)>
```

## Phase Commit Templates

### Phase 0: Specification

```bash
git commit -m "docs(spec): create specification for ${FEATURE_SLUG}

- Acceptance criteria: ${CRITERIA_COUNT}
- User stories: ${STORY_COUNT}
- Technical requirements: Defined"
```

### Phase 0.5: Clarification

```bash
git commit -m "docs(clarify): resolve ${QUESTION_COUNT} clarifications for ${FEATURE_SLUG}

Clarifications:
- ${QUESTION_1}
- ${QUESTION_2}
- ${QUESTION_3}"
```

### Phase 1: Planning

```bash
git commit -m "docs(plan): create implementation plan for ${FEATURE_SLUG}

- Architecture: ${ARCHITECTURE}
- Code reuse: ${REUSE_COUNT} files
- Complexity: ${COMPLEXITY_SCORE}
- Estimated time: ${TIME_ESTIMATE}"
```

### Phase 2: Task Breakdown

```bash
git commit -m "docs(tasks): create task breakdown for ${FEATURE_SLUG} (${TASK_COUNT} tasks)

- TDD tasks: ${TDD_COUNT}
- Integration tasks: ${INTEGRATION_COUNT}
- Polish tasks: ${POLISH_COUNT}
- Format: ${FORMAT}"
```

### Phase 3: Analysis

```bash
git commit -m "docs(analyze): create cross-artifact analysis for ${FEATURE_SLUG}

- Consistency checks: ${CHECK_COUNT}
- Issues found: ${ISSUE_COUNT}
- Critical blockers: ${BLOCKER_COUNT}
- Recommendations: ${REC_COUNT}"
```

### Phase 5: Optimization

```bash
git commit -m "docs(optimize): complete optimization review for ${FEATURE_SLUG}

- Performance: ${PERF_SCORE}/100
- Security: ${SEC_ISSUES} fixed
- Code quality: ${QUALITY_SCORE}/100
- Accessibility: ${A11Y_ISSUES} fixed"
```

### Phase 6: Preview

```bash
git commit -m "docs(preview): create release notes for ${FEATURE_SLUG} v${VERSION}

- Changes: ${CHANGE_COUNT}
- Breaking changes: ${BREAKING_COUNT}
- Deprecations: ${DEPRECATION_COUNT}
- Migration guide: ${HAS_MIGRATION}"
```

## Epic Phase Commit Templates

### Epic Phase 0: Specification

```bash
git commit -m "docs(epic-spec): create specification for ${EPIC_SLUG}

Type: ${EPIC_TYPE}
Complexity: ${COMPLEXITY}
Subsystems: ${SUBSYSTEM_COUNT}
Estimated sprints: ${ESTIMATED_SPRINTS}

Next: /clarify (if needed) or research phase"
```

### Epic Phase 1: Research

```bash
git commit -m "docs(epic-research): complete technical research for ${EPIC_SLUG}

Findings: ${FINDINGS_COUNT}
Confidence: ${CONFIDENCE_LEVEL}
Open questions: ${OPEN_QUESTIONS}
Dependencies: ${DEPENDENCY_COUNT}

Next: Planning phase"
```

### Epic Phase 1: Planning

```bash
git commit -m "docs(epic-plan): create implementation plan for ${EPIC_SLUG}

Architecture decisions: ${ARCH_DECISIONS}
Phases: ${PHASE_COUNT}
Dependencies: ${DEPENDENCY_COUNT}
Risks: ${RISK_COUNT}

Next: Sprint breakdown"
```

### Epic Phase 2: Sprint Breakdown

```bash
git commit -m "docs(epic-tasks): create sprint breakdown for ${EPIC_SLUG} (${SPRINT_COUNT} sprints)

Sprints: ${SPRINT_COUNT}
Layers: ${LAYER_COUNT}
Contracts locked: ${CONTRACT_COUNT}
Total tasks: ${TASK_COUNT}

Next: /implement-epic (parallel sprint execution)"
```

### Epic Phase 3: Layer Implementation

```bash
git commit -m "feat(epic): complete layer ${LAYER_NUM} (sprints ${SPRINT_IDS})

Duration: ${DURATION_HOURS}h
Tasks: ${TASKS_COMPLETED}
Tests: ${TESTS_PASSING} passing
Coverage: ${COVERAGE}%
Contracts locked: ${CONTRACTS_LOCKED}

Layer ${LAYER_NUM} of ${LAYER_TOTAL} complete
Epic progress: ${SPRINTS_COMPLETED}/${SPRINTS_TOTAL} sprints

Next layer: ${NEXT_LAYER} (or optimization if final)"
```

### Epic Phase 3: Implementation Summary

```bash
git commit -m "feat(epic): complete ${EPIC_SLUG} with ${MULTIPLIER}x velocity

Total sprints: ${TOTAL_SPRINTS}
Execution strategy: ${EXECUTION_STRATEGY}
Expected duration: ${EXPECTED_HOURS}h (sequential)
Actual duration: ${ACTUAL_HOURS}h (parallel)

Audit score: ${AUDIT_SCORE}/100
Bottlenecks: ${BOTTLENECK_COUNT}

Next: /optimize"
```

### Epic Phase 5: Optimization

```bash
git commit -m "docs(epic-optimize): complete optimization for ${EPIC_SLUG}

Performance: ${PERF_SCORE}/100
Security: ${SEC_SCORE}/100
Accessibility: ${A11Y_SCORE}/100
Code quality: ${QUALITY_SCORE}/100

All quality gates passed

Next: /preview (if needed) or /ship"
```

### Epic Phase 6: Preview

```bash
git commit -m "docs(epic-preview): complete preview for ${EPIC_SLUG}

Auto-checks: ${AUTO_CHECK_RESULTS}
Manual review: ${MANUAL_REVIEW_STATUS}

Ready for deployment

Next: /ship"
```

## Task Commit Templates

### RED Phase (Write Failing Test)

```bash
git commit -m "test(red): ${TASK_ID} write failing test for ${DESCRIPTION}

Test: ${TEST_NAME}
Expected: FAILED (${EXPECTED_ERROR})
Evidence: ${TEST_OUTPUT}"
```

### GREEN Phase (Make Test Pass)

```bash
git commit -m "feat(green): ${TASK_ID} implement ${DESCRIPTION} to pass test

Implementation: ${IMPLEMENTATION_SUMMARY}
Tests: ${PASSING_COUNT}/${TOTAL_COUNT} passing
Coverage: ${COVERAGE}% (+${COVERAGE_DELTA}%)"
```

### REFACTOR Phase (Improve Code)

```bash
git commit -m "refactor: ${TASK_ID} improve ${DESCRIPTION}

Improvements:
- ${IMPROVEMENT_1}
- ${IMPROVEMENT_2}
- ${IMPROVEMENT_3}

Tests: ${PASSING_COUNT}/${TOTAL_COUNT} passing (still green)
Coverage: ${COVERAGE}% (maintained)"
```

### Batch Commits (User Story)

```bash
git commit -m "feat(batch): implement ${TASK_RANGE} for ${USER_STORY} (${PRIORITY})

Tasks completed:
- ${TASK_1}: ${DESC_1} ✅
- ${TASK_2}: ${DESC_2} ✅
- ${TASK_3}: ${DESC_3} ✅

Tests: All passing (backend: ${BE_TESTS}, frontend: ${FE_TESTS})
Coverage: Backend ${BE_COV}%, Frontend ${FE_COV}%"
```

### MVP Commits

```bash
git commit -m "feat(mvp): complete P1 (MVP) implementation for ${FEATURE_SLUG}

MVP tasks: ${P1_COMPLETE}/${P1_TOTAL} ✅
All acceptance criteria met
Tests: All passing
Coverage: Backend ${BE_COV}%, Frontend ${FE_COV}%

Deferred to roadmap:
- P2 enhancements: ${P2_COUNT} tasks
- P3 features: ${P3_COUNT} tasks"
```

## Fix Commit Templates

### Bug Fix

```bash
git commit -m "fix(${SCOPE}): ${DESCRIPTION}

Root cause: ${ROOT_CAUSE}
Solution: ${SOLUTION}
Tests: ${TEST_UPDATES}
Regression prevented by: ${REGRESSION_PREVENTION}"
```

### Security Fix

```bash
git commit -m "fix(security): ${DESCRIPTION}

Vulnerability: ${VULN_TYPE}
Severity: ${SEVERITY}
CVE: ${CVE_ID} (if applicable)
Fix: ${FIX_DESCRIPTION}"
```

### Performance Fix

```bash
git commit -m "perf(${SCOPE}): ${DESCRIPTION}

Before: ${BEFORE_METRIC}
After: ${AFTER_METRIC}
Improvement: ${IMPROVEMENT_PERCENT}%
Method: ${OPTIMIZATION_METHOD}"
```

## Variable Substitution Guide

| Variable | Source | Example |
|----------|--------|---------|
| `${FEATURE_SLUG}` | Current feature directory name | `user-messaging` |
| `${TASK_ID}` | Task tracker or tasks.md | `T001` |
| `${DESCRIPTION}` | Task description from tasks.md | `Create Message model` |
| `${PHASE_NAME}` | Current workflow phase | `spec`, `plan`, `tasks` |
| `${CRITERIA_COUNT}` | Count from spec.md | `15` |
| `${TASK_COUNT}` | Count from tasks.md | `28` |
| `${PASSING_COUNT}` | From test output | `26` |
| `${COVERAGE}` | From coverage report | `93` |
| `${COVERAGE_DELTA}` | Coverage change | `+8` |
| `${USER_STORY}` | From task marker | `US1`, `US2` |
| `${PRIORITY}` | From task marker | `P1`, `P2`, `P3` |

## Commit Type Reference

| Type | Use When | Scope Examples |
|------|----------|----------------|
| `feat` | New feature added | api, ui, auth, messaging |
| `fix` | Bug fix | validation, api, ui, security |
| `docs` | Documentation only | spec, plan, tasks, readme |
| `test` | Adding tests | red, integration, e2e |
| `refactor` | Code restructure | models, services, utils |
| `perf` | Performance improvement | query, render, load |
| `chore` | Maintenance | deps, config, build |
| `ci` | CI/CD changes | github, deploy, test |
| `build` | Build system changes | webpack, vite, rollup |
| `revert` | Reverting previous commit | - |

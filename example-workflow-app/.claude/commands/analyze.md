---
description: Cross-artifact consistency analysis (review work and list what might be broken)
---

Analyze feature artifacts: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine**
- Load artifacts -> Scan issues -> Generate report -> Suggest next step

**Auto-suggest**
- When complete -> `/implement`

## LOAD ARTIFACTS

Use the helper script for your platform:
```bash
pwsh -NoProfile -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
# or
.spec-flow/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
```

Load: `spec.md`, `plan.md`, `tasks.md`, `error-log.md` (if it exists), `constitution.md`

## DETECTION ANALYSIS

Check for:
- **Duplication**  near-duplicate requirements across artifacts
- **Ambiguity**  vague adjectives or missing success metrics
- **Coverage gaps**  requirements without tasks or tests
- **Principle conflicts**  violations of constitution or team guardrails
- **Terminology drift**  inconsistent naming across files
- **Error ritual**  missing or stale `error-log.md`
- **Context discipline**  missing strategy/context sections

Severity levels:
- CRITICAL: Missing core artifact, contract violation, zero coverage
- HIGH: Duplicate requirements, ambiguous security/performance, untestable criteria
- MEDIUM: Terminology drift, missing non-functional coverage
- LOW: Wording or formatting improvements

Limit: flag at most 50 issues; roll up the remainder.

## GENERATE REPORT

Write to `specs/NNN-feature/artifacts/analysis-report.md`:

```markdown
# Cross-Artifact Analysis Report

**Date**: YYYY-MM-DD HH:MM
**Feature**: NNN-feature-slug

## Issues Found

| ID | Category | Severity | Location | Summary | Recommendation |
|----|----------|----------|----------|---------|----------------|
| A1 | [Category] | [CRITICAL/HIGH/MEDIUM/LOW] | file.md:LNN | [Issue] | [Fix] |

## Coverage & Risks
- Requirements without tasks: [count/list]
- Tasks lacking tests: [count/list]
- Ambiguities: [summary]
- Blockers: [critical issues that must be fixed before `/implement`]

## Suggested Next Actions
- [ ] `/implement` (if no blockers)
- [ ] `/clarify` (if ambiguities remain)
- [ ] `/plan` update (if scope drift detected)
```

## TOKEN MANAGEMENT

After writing the report, update token usage:
```bash
pwsh -NoProfile -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/NNN-feature -Phase implementation
# or
.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/NNN-feature --phase implementation
```

If usage exceeds the threshold, run `compact-context` for the feature.

## AUTO-PROGRESSION

Summarise findings and recommend the next command. If blockers remain, stop the workflow until they are addressed; otherwise suggest `/implement` or `/flow continue`.



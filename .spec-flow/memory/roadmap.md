# Spec-Flow Product Roadmap

**Last updated**: 2025-10-03

> Features from brainstorm → shipped. Managed via `/roadmap`

## In Progress

<!-- Currently implementing (linked to active branches) -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Phase**: 0-12 (optional)
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**:
  - Requirement 1
- **Branch**: NNN-feature-name
- **Owner**: @username (optional)
-->

## Next

<!-- Top 5-10 prioritized features (sorted by score) -->
<!-- Same format as In Progress, no Branch/Owner -->

## Backlog

<!-- All other ideas (unlimited, sorted by score) -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api
- **Role**: student|cfi|school|all
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**: [CLARIFY: questions] or brief bullets
-->

## Later

<!-- Future features (10-20 items, sorted by score) -->
<!-- Same format as Next -->

## Shipped

<!-- Released to production -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Date**: YYYY-MM-DD
- **Release**: vX.Y.Z - One-line release notes
-->

## Archive

<!-- Deprecated features -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Reason**: Why archived
- **Date**: YYYY-MM-DD
-->

---

## Scoring Guide

**ICE** = Impact × Confidence ÷ Effort

- **Impact** (1-5): 1=nice-to-have, 3=useful, 5=critical
- **Effort** (1-5): 1=<1 day, 3=1-2 weeks, 5=4+ weeks
- **Confidence** (0-1): 0.5=uncertain, 0.7=some unknowns, 0.9=high, 1.0=certain

Higher score = higher priority

## Status Flow

```
Backlog → Later → Next → In Progress → Shipped
                               ↓
                          Archive
```

## Feature Sizing

**/spec-flow-sized**: 30 tasks, one screen/flow/API, 1-2 weeks

If larger: Break into multiple features by area or domain

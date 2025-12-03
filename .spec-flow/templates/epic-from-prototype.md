# Epic Specification: [EPIC_NAME]

> Auto-populated from prototype discovery on [DATE]
> Source: design/prototype/

## Overview

| Field | Value |
|-------|-------|
| Epic Number | [EPIC_NUM] |
| Epic Slug | [EPIC_SLUG] |
| Source | Prototype Discovery |
| Prototype Path | design/prototype/ |
| Status | Planning |
| Created | [TIMESTAMP] |

## Discovered Features

> Copied from design/prototype/discovered-features.md

### Feature Summary

| # | Feature | Complexity | Category | Sprint |
|---|---------|------------|----------|--------|
| 1 | [FEATURE_1] | [Epic/Feature] | [Category] | S[N] |
| 2 | [FEATURE_2] | [Epic/Feature] | [Category] | S[N] |

### Feature Details

<!-- For each discovered feature, copy the user stories and requirements -->

#### [FEATURE_1]

**Screens**: [SCREENS]
**Complexity**: [COMPLEXITY]
**Sprint Assignment**: S[N]

**User Stories**:
- [ ] As a user, I can [ACTION]
- [ ] As a user, I can [ACTION]

**Components Required**:
- [COMPONENT] (from component-inventory.md)

---

## Suggested Sprint Structure

> Copied from discovered-features.md "Suggested Epic Structure" section

**Total Estimated Hours**: [TOTAL_HOURS]h
**Sprint Count**: [SPRINT_COUNT]
**Complexity Rating**: [Small/Medium/Large]

### Sprint 1: Foundation (~[HOURS]h)

**Goal**: [SPRINT_GOAL]
**Features**:
- [ ] [FEATURE_A] - [DESCRIPTION]
- [ ] [FEATURE_B] - [DESCRIPTION]

**Deliverables**:
- [DELIVERABLE]

### Sprint 2: Core Value (~[HOURS]h)

**Goal**: [SPRINT_GOAL]
**Features**:
- [ ] [FEATURE_C] - [DESCRIPTION]
- [ ] [FEATURE_D] - [DESCRIPTION]

**Deliverables**:
- [DELIVERABLE]

### Sprint 3: Polish (~[HOURS]h)

**Goal**: [SPRINT_GOAL]
**Features**:
- [ ] [FEATURE_E] - [DESCRIPTION]
- [ ] [FEATURE_F] - [DESCRIPTION]

**Deliverables**:
- [DELIVERABLE]

---

## Component Dependencies

> Copied from design/prototype/component-inventory.md

### Must Build (3+ occurrences)

| Component | Occurrences | Screens | Priority |
|-----------|-------------|---------|----------|
| [COMPONENT] | [N] | [SCREENS] | Must build |

### Should Build (2 occurrences)

| Component | Occurrences | Screens | Priority |
|-----------|-------------|---------|----------|
| [COMPONENT] | [N] | [SCREENS] | Should build |

### Consider (1 occurrence)

| Component | Occurrences | Screens | Priority |
|-----------|-------------|---------|----------|
| [COMPONENT] | [N] | [SCREENS] | Consider |

---

## Consolidated User Stories

> All user stories from discovered features, grouped by theme

### Authentication & Access
- [ ] As a user, I can [STORY]
- [ ] As a user, I can [STORY]

### Core Functionality
- [ ] As a user, I can [STORY]
- [ ] As a user, I can [STORY]

### Settings & Preferences
- [ ] As a user, I can [STORY]
- [ ] As a user, I can [STORY]

---

## Feature Dependencies

> Shows build order requirements

| Feature | Depends On | Blocks | Sprint |
|---------|------------|--------|--------|
| [FEATURE_A] | - | [FEATURE_C, D] | S1 |
| [FEATURE_B] | - | [FEATURE_C] | S1 |
| [FEATURE_C] | [A, B] | [FEATURE_E] | S2 |

**Critical Path**: [FEATURE_A] → [FEATURE_C] → [FEATURE_E]

---

## Open Questions

> Copied from discovered-features.md - resolve before implementation

### Question 1: [QUESTION]
- **Screen**: [WHERE_CAPTURED]
- **Impact**: [WHAT_AFFECTED]
- **Status**: [ ] Unresolved

### Question 2: [QUESTION]
- **Screen**: [WHERE_CAPTURED]
- **Impact**: [WHAT_AFFECTED]
- **Status**: [ ] Unresolved

---

## Ideas for Future

> Ideas captured during discovery that aren't in this epic scope

- **[IDEA_TITLE]**: [DESCRIPTION] (from [SCREEN])

---

## Prototype References

| Artifact | Location |
|----------|----------|
| Screens | design/prototype/screens/ |
| Theme | design/prototype/theme.yaml |
| Theme CSS | design/prototype/theme.css |
| Ideas | design/prototype/_discovery/ideas.md |
| Questions | design/prototype/_discovery/questions.md |
| Scrapped | design/prototype/_discovery/scrapped/ |

**Theme Locked**: [YES/NO]

---

## Next Steps

1. Review this spec and adjust feature priorities
2. Resolve open questions (above)
3. Run `/epic continue` to start planning phase
4. Planning will generate plan.md with architecture decisions
5. Then `/tasks` will generate sprint-plan.md with detailed breakdown

---

## Metadata

```yaml
source: prototype
prototype_version: [PROTOTYPE_VERSION]
extraction_date: [DATE]
features_count: [N]
sprints_suggested: [M]
components_required: [K]
questions_open: [Q]
```

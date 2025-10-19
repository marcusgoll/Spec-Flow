# UI/UX Design: Learnings Data

> **Note**: This file stores accumulated learnings from the design workflow. It is shipped with the npm package but preserved across updates (user-owned). SKILL.md references this file for current frequencies and metrics.

**Last updated**: Never
**Features processed**: 0

---

## Common Pitfalls

### too-many-variants
**ID**: `too-many-variants`
**Frequency**: 0/5 ⭐☆☆☆☆
**Last seen**: Never
**Impact**: High
**Instances**: []

### variants-not-cleaned-up
**ID**: `variants-not-cleaned-up`
**Frequency**: 0/5 ⭐☆☆☆☆
**Last seen**: Never
**Impact**: Medium
**Instances**: []

### design-system-violations
**ID**: `design-system-violations`
**Frequency**: 0/5 ⭐☆☆☆☆
**Last seen**: Never
**Impact**: High
**Instances**: []

### accessibility-failures
**ID**: `accessibility-failures`
**Frequency**: 0/5 ⭐☆☆☆☆
**Last seen**: Never
**Impact**: Critical
**Instances**: []

### performance-regressions
**ID**: `performance-regressions`
**Frequency**: 0/5 ⭐☆☆☆☆
**Last seen**: Never
**Impact**: Medium
**Instances**: []

---

## Successful Patterns

### 3-5-variants-strategy
**ID**: `3-5-variants-strategy`
**Usage count**: 0
**First used**: Never
**Success rate**: null
**Impact**: High

### git-tag-before-cleanup
**ID**: `git-tag-before-cleanup`
**Usage count**: 0
**First used**: Never
**Success rate**: null
**Impact**: High

### design-token-compliance
**ID**: `design-token-compliance`
**Usage count**: 0
**First used**: Never
**Success rate**: null
**Impact**: Critical

### jobs-perfection-checklist
**ID**: `jobs-perfection-checklist`
**Usage count**: 0
**First used**: Never
**Success rate**: null
**Impact**: High

---

## Metrics

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg variants per screen | 3-5 | null | - |
| Cleanup compliance | 100% | null | - |
| Design token violations | 0 | null | - |
| Lighthouse accessibility | ≥95 | null | - |
| Lighthouse performance | ≥90 | null | - |
| Jobs checklist pass rate | 100% | null | - |

---

## Auto-Update Instructions

This file is automatically updated by the design workflow:

1. **After /design-variations**: Increment `too-many-variants.frequency` if >5 variants created
2. **After /design-functional**: Increment `variants-not-cleaned-up.frequency` if cleanup skipped
3. **After /design-polish**: Increment `design-system-violations.frequency` if violations found
4. **On success**: Increment successful pattern usage counts
5. **Metrics**: Update averages after each feature completion

---

_This file is preserved across npm updates to maintain your accumulated learnings._

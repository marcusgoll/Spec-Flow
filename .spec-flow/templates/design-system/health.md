# Design System Health Dashboard

**Last Updated**: {TIMESTAMP}
**Health Score**: {HEALTH_SCORE}% {STATUS_EMOJI}
**Status**: {STATUS_TEXT}

---

## Overview

| Metric | Count | Target | Status |
|--------|-------|--------|--------|
| **Critical Issues** | {CRITICAL_COUNT} | 0 | {CRITICAL_STATUS} |
| **Warnings** | {WARNING_COUNT} | <5 | {WARNING_STATUS} |
| **Info Messages** | {INFO_COUNT} | - | ℹ️ |
| **Health Score** | {HEALTH_SCORE}% | ≥90% | {SCORE_STATUS} |

---

## Status Legend

- 🟢 **Excellent** (90-100%): Design system is healthy and well-maintained
- 🟡 **Good** (70-89%): Minor issues, no immediate action required
- 🟠 **Needs Attention** (50-69%): Several warnings, review recommended
- 🔴 **Poor** (<50%): Critical issues require immediate attention

---

## Detailed Health Checks

### 1. Design System Core Files

**Status**: {CHECK1_STATUS}

**Required Files**:
- ✅ `design/systems/tokens.css` - Design tokens (colors, spacing, typography)
- ✅ `design/systems/ui-inventory.md` - Component catalog
- ✅ `docs/project/style-guide.md` - Core 9 Rules and accessibility baseline

**Optional Files**:
- {OPTIONAL_FILE1_STATUS} `design/systems/approved-patterns.md` - Reusable layout patterns
- {OPTIONAL_FILE2_STATUS} `design/inspirations.md` - Design references
- {OPTIONAL_FILE3_STATUS} `design/systems/health.md` - This health dashboard

**Issues**:
{CHECK1_ISSUES}

---

### 2. Living Documentation Freshness

**Status**: {CHECK2_STATUS}

**CLAUDE.md Files**:
- **Project CLAUDE.md**: {PROJECT_CLAUDE_AGE} days old {PROJECT_CLAUDE_STATUS}
- **Feature CLAUDE.md Files**: {FEATURE_CLAUDE_COUNT} total, {STALE_FEATURES} stale

**Freshness Threshold**: 7 days

**Stale Features** (>7 days old):
{STALE_FEATURES_LIST}

**Recommendation**:
- Run `/feature continue` on stale features to update documentation
- Update project CLAUDE.md after major deployments

---

### 3. UI Inventory Synchronization

**Status**: {CHECK3_STATUS}

**Component Count**:
- **Documented** (ui-inventory.md): {INVENTORY_COUNT} components
- **Actual Files** (components/ui/): {ACTUAL_COUNT} components
- **Difference**: {SYNC_DIFF} components

**Sync Status**:
{SYNC_STATUS_TEXT}

**Undocumented Components**:
{UNDOCUMENTED_COMPONENTS}

**Recommendation**:
- Run frontend agent to auto-update ui-inventory.md during implementation
- Document new components in ui-inventory.md within 24 hours of creation

---

### 4. Approved Patterns Coverage

**Status**: {CHECK4_STATUS}

**Pattern Metrics**:
- **Features with Mockups**: {MOCKUP_FEATURES}
- **Documented Patterns**: {PATTERN_COUNT}
- **Coverage**: {PATTERN_COVERAGE}%

**Target**: At least 1 pattern per 2 features (50% coverage)

**Recent Patterns**:
{RECENT_PATTERNS_LIST}

**Recommendation**:
- Extract reusable patterns from approved mockups
- Document patterns in `design/systems/approved-patterns.md`
- Include code examples and usage guidelines

---

### 5. Design Token Usage

**Status**: {CHECK5_STATUS}

**Recent Mockups** (last 30 days):
- **Total Mockups**: {RECENT_MOCKUPS}
- **Using tokens.css**: {MOCKUPS_WITH_TOKENS}
- **Compliance Rate**: {TOKEN_COMPLIANCE}%

**Mockups Missing tokens.css Link**:
{MOCKUPS_WITHOUT_TOKENS}

**Recommendation**:
- All new mockups must link to `design/systems/tokens.css`
- Run design-lint agent to detect hardcoded values
- Update mockup templates to include tokens.css by default

---

### 6. Style Guide Freshness

**Status**: {CHECK6_STATUS}

**File Age**: {STYLE_GUIDE_AGE} days old

**Core 9 Rules Section**: {CORE_9_RULES_STATUS}

**Last Updated**: {STYLE_GUIDE_LAST_UPDATED}

**Recommendation**:
- Review style-guide.md quarterly (every 90 days)
- Update Core 9 Rules when new accessibility requirements emerge
- Add new token categories (e.g., animations, transitions)

---

### 7. Mockup Template Availability

**Status**: {CHECK7_STATUS}

**Required Templates**:
- {TEMPLATE1_STATUS} `.spec-flow/templates/mockups/index.html` - Navigation hub
- {TEMPLATE2_STATUS} `.spec-flow/templates/mockups/screen.html` - Individual screen
- {TEMPLATE3_STATUS} `.spec-flow/templates/mockups/_shared/navigation.js` - Keyboard shortcuts
- {TEMPLATE4_STATUS} `.spec-flow/templates/mockups/_shared/state-switcher.js` - State cycling

**Missing Templates**: {MISSING_TEMPLATES_COUNT}

**Recommendation**:
- Ensure all templates are available before running `/tasks --ui-first`
- Templates should be version-controlled in `.spec-flow/templates/`

---

## Critical Issues

{CRITICAL_ISSUES_LIST}

**Action Required**:
- Critical issues block feature development and must be fixed immediately
- Run `/init-project` or `/init-brand-tokens` if core files are missing
- Update stale documentation to unblock new features

---

## Warnings

{WARNINGS_LIST}

**Recommended Actions**:
- Warnings are non-blocking but should be addressed during the next maintenance cycle
- Schedule design system maintenance sprint to resolve accumulated warnings
- Update living documentation after each feature completion

---

## Trends

### Health Score History (Last 30 Days)

```
{HEALTH_SCORE_TREND}
```

### Component Growth

```
Month       | New Components | Documented | Coverage
------------|----------------|------------|----------
{COMPONENT_GROWTH_DATA}
```

### Pattern Adoption

```
Feature     | Patterns Used | Reuse Rate | Token Compliance
------------|---------------|------------|------------------
{PATTERN_ADOPTION_DATA}
```

---

## Recommendations

### Immediate Actions (Critical)

{IMMEDIATE_ACTIONS}

### Short-Term Actions (This Sprint)

{SHORT_TERM_ACTIONS}

### Long-Term Improvements (Next Quarter)

{LONG_TERM_ACTIONS}

---

## Maintenance Schedule

### Weekly
- Run `design-health-check.sh` to monitor design system health
- Review new components for documentation in ui-inventory.md
- Extract patterns from newly approved mockups

### Monthly
- Review and update approved-patterns.md with new patterns
- Check token compliance across all recent features
- Update CLAUDE.md files for active features

### Quarterly
- Review and update style-guide.md Core 9 Rules
- Audit component reuse rate (target: 85%+)
- Conduct accessibility audit (WCAG 2.1 AA compliance)

### Annually
- Major design system version upgrade
- Token consolidation and cleanup
- Component library refactoring

---

## Metrics Summary

### Component Reuse
- **Target**: 85%+
- **Current**: {COMPONENT_REUSE_RATE}%
- **Trend**: {REUSE_TREND}

### Token Compliance
- **Target**: 95%+
- **Current**: {TOKEN_COMPLIANCE_RATE}%
- **Trend**: {TOKEN_TREND}

### Accessibility Score
- **Target**: 100%
- **Current**: {ACCESSIBILITY_SCORE}%
- **Trend**: {ACCESSIBILITY_TREND}

### Design System Freshness
- **Target**: <7 days average age
- **Current**: {AVG_DOC_AGE} days
- **Trend**: {FRESHNESS_TREND}

---

## How to Improve Health Score

### From Poor (< 50%) to Needs Attention (50-69%):
1. Fix all critical issues (missing core files, broken templates)
2. Update stale CLAUDE.md files (>7 days old)
3. Document all existing components in ui-inventory.md

### From Needs Attention (50-69%) to Good (70-89%):
1. Resolve warnings (unsync'd inventory, missing patterns)
2. Ensure all recent mockups use tokens.css
3. Extract and document reusable patterns

### From Good (70-89%) to Excellent (90-100%):
1. Maintain zero critical issues
2. Keep warnings below 5
3. Achieve 85%+ component reuse rate
4. Achieve 95%+ token compliance
5. Keep all documentation fresh (<7 days old)

---

## Next Health Check

**Recommended**: Weekly (every 7 days)

**Run Command**:
```bash
.spec-flow/scripts/bash/design-health-check.sh --verbose
```

**Automated Scheduling** (optional):
```bash
# Add to cron (Linux/macOS)
0 9 * * 1 cd /path/to/repo && .spec-flow/scripts/bash/design-health-check.sh --json > design/systems/health-$(date +\%Y-\%m-\%d).json

# Add to GitHub Actions (on push to main)
name: Design Health Check
on:
  push:
    branches: [main]
jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: .spec-flow/scripts/bash/design-health-check.sh --json
```

---

## Resources

- **Style Guide**: `docs/project/style-guide.md`
- **UI Inventory**: `design/systems/ui-inventory.md`
- **Approved Patterns**: `design/systems/approved-patterns.md`
- **Design Tokens**: `design/systems/tokens.css`
- **Health Check Script**: `.spec-flow/scripts/bash/design-health-check.sh`

---

**Generated by**: `design-health-check.sh`
**Template Version**: 1.0.0
**Spec-Flow Workflow Kit**

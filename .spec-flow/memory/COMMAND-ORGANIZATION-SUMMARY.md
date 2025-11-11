# Command Organization Summary

**Date**: 2025-11-10
**Type**: Organization and documentation
**Impact**: Improves command discoverability and establishes refactor roadmap

---

## What Was Done

### 1. Created Comprehensive Command Index

**File**: `.claude/commands/README.md`

**Contents**:
- **Command Index by Category**: 47 commands organized into 9 logical categories
- **Status Legend**: Stable, Beta, Internal, Refactor status
- **v2.0 Refactor Pattern**: Documented standard for all future refactors
- **Proposed Directory Structure**: Future reorganization plan
- **Typical Workflows**: Usage examples for common scenarios
- **Command Conventions**: Standards for frontmatter, structure, bash/PowerShell
- **Adding New Commands**: Contribution guide

**Categories**:
1. **Core Workflow** (4 commands): feature, help, quick, route-agent
2. **Phase Commands** (10 commands): spec, clarify, plan, tasks, implement, validate, optimize, preview, finalize, debug
3. **Deployment Commands** (10 commands): ship, ship-staging, validate-staging, ship-prod, deploy-prod, deploy-status, validate-deploy, test-deploy, deployment-budget, check-env
4. **Quality Gates** (3 commands): gate-ci, gate-sec, fix-ci
5. **Infrastructure** (6 commands): contract-bump, contract-verify, flag-add, flag-list, flag-cleanup, fixture-refresh
6. **Project Management** (6 commands): init-project, roadmap, constitution, update-project-config, init-brand-tokens, dev-docs
7. **Metrics & Monitoring** (2 commands): metrics, metrics-dora
8. **Build & CI** (2 commands): build-local, branch-enforce
9. **Task Scheduling** (3 commands): scheduler-assign, scheduler-list, scheduler-park
10. **Internal** (1 command): release

---

### 2. Created Prioritized Refactor Plan

**File**: `.spec-flow/memory/COMMAND-REFACTOR-PLAN.md`

**Contents**:
- **Completed Refactors**: 5 commands (11% complete)
- **Prioritized Refactor Queue**: 8 priority tiers (P1-P8)
- **Execution Plan**: 4 sprints over 4 weeks
- **Common Issues to Watch For**: 8 patterns from completed refactors
- **Metrics & Success Criteria**: Per-command and project-wide goals
- **Directory Reorganization**: Post-refactor structure plan
- **Testing Strategy**: Per-command and integration testing

**Priority Tiers**:

| Tier | Commands | Days | Focus |
|------|----------|------|-------|
| P1: Critical Path | 5 | 2-3 | spec, plan, tasks, implement, ship |
| P2: Deployment Pipeline | 5 | 2 | ship-staging, validate-staging, ship-prod, optimize, preview |
| P3: Quality & Validation | 5 | 1.5 | validate, fix-ci, debug, gate-ci, gate-sec |
| P4: Project Management | 5 | 2 | init-project, roadmap, update-project-config, finalize, **feature** |
| P5: Deployment Support | 5 | 1 | deploy-status, validate-deploy, test-deploy, deployment-budget, check-env |
| P6: Infrastructure (Beta) | 6 | 1.5 | contract-*, flag-*, fixture-refresh |
| P7: Metrics & Scheduling | 7 | 2 | metrics, metrics-dora, scheduler-*, dev-docs, init-brand-tokens |
| P8: Internal/Special | 4 | 1 | release, route-agent, help, quick |

**Total**: 42 pending commands, 13-14 days estimated

---

### 3. Identified Metadata Gaps

**Commands Missing YAML Frontmatter** (20 total):

```
branch-enforce.md
contract-bump.md
contract-verify.md
deploy-status.md
dev-docs.md
fixture-refresh.md
flag-add.md
flag-cleanup.md
flag-list.md
gate-ci.md
gate-sec.md
init-brand-tokens.md
metrics-dora.md
scheduler-assign.md
scheduler-list.md
scheduler-park.md
ship.md
tasks.md
update-project-config.md
validate-staging.md
```

**Action**: Add consistent YAML frontmatter in future refactors

**Standard Frontmatter**:
```yaml
---
description: Brief description (used in command list)
internal: true  # Optional: mark as internal-only
version: 2.0     # Optional: after v2.0 refactor
---
```

---

## Benefits

### For Users:
- **Discoverability**: Quick reference to find commands by category
- **Context**: Understand command status (stable vs beta)
- **Guidance**: Typical workflows show how commands fit together
- **Transparency**: See refactor progress and upcoming changes

### For Contributors:
- **Standards**: Clear conventions for new commands
- **Roadmap**: Know which commands need work
- **Patterns**: 8 documented issues from completed refactors
- **Testing**: Defined per-command and integration tests

### For Project:
- **Organization**: Logical categorization of 47 commands
- **Planning**: 4-sprint roadmap to 100% v2.0 coverage
- **Quality**: Success criteria for each refactor
- **Future-proof**: Directory structure plan for scalability

---

## Proposed Directory Structure (Future)

**Not yet implemented** - will be done after v2.0 refactors complete.

```
.claude/commands/
├── README.md
├── core/          (4 commands)
├── phases/        (10 commands)
├── deployment/    (10 commands)
├── quality/       (3 commands)
├── infrastructure/ (6 commands)
├── project/       (6 commands)
├── metrics/       (2 commands)
├── build/         (2 commands)
├── scheduling/    (3 commands)
└── internal/      (1 command)
```

**Rationale**: Flat structure works for now, but subdirectories will improve navigation as commands grow.

**Migration Plan**:
1. Complete v2.0 refactors (42 commands remaining)
2. Create subdirectories
3. Move commands gradually (with symlinks for backward compatibility)
4. Update slash command loader to search subdirectories
5. Update references in skills and agents
6. Remove symlinks after 2-3 week transition

---

## Current State

**Total Commands**: 47
**Refactored to v2.0**: 5 (11%)
**Missing Metadata**: 20 (43%)
**Beta Status**: ~14 (30%)
**Stable**: ~33 (70%)

**v2.0 Pattern Established**:
- ✅ Strict bash mode (`set -Eeuo pipefail`)
- ✅ Error trap (`trap on_error ERR`)
- ✅ Tool preflight checks (`need()` function)
- ✅ Non-interactive (no prompts, fail fast)
- ✅ Deterministic repo root
- ✅ Actionable error messages
- ✅ Concrete examples (evidence-backed)
- ✅ Comprehensive documentation

---

## Next Steps

### Immediate:
1. ✅ Commit organization improvements (README.md + COMMAND-REFACTOR-PLAN.md)
2. ⏳ Start Sprint 1: Refactor `/spec` command (P1: Critical Path)

### Sprint 1 (Week 1):
- `/spec` (1 day)
- `/plan` (1 day)
- `/tasks` (0.5 day)
- `/implement` (1.5 days)
- `/ship` (1.5 days)

**Goal**: Core workflow is non-interactive and deterministic

### Sprint 2 (Week 2):
- `/optimize`, `/preview`, `/ship-staging`, `/validate-staging`, `/ship-prod`, `/validate`

**Goal**: Deployment pipeline and quality gates are deterministic

### Sprint 3 (Week 3):
- `/feature`, `/quick`, `/init-project`, `/roadmap`

**Goal**: All primary user-facing commands refactored

### Sprint 4 (Week 4):
- Remaining P5-P8 commands (13 commands)

**Goal**: 100% command coverage

---

## Comparison: Before vs After

### Before:
- ❌ No command index (hard to discover commands)
- ❌ No refactor roadmap (unclear priority)
- ❌ Inconsistent metadata (20 commands missing description)
- ❌ No directory structure plan
- ❌ No testing strategy
- ❌ Refactor patterns undocumented (ad-hoc)

### After:
- ✅ Comprehensive README with 9 categories
- ✅ 4-sprint refactor plan with priorities
- ✅ Metadata gaps identified (20 commands listed)
- ✅ Future directory structure proposed
- ✅ Per-command and integration testing defined
- ✅ 8 refactor patterns documented with examples

---

## Files Created

1. **`.claude/commands/README.md`** (434 lines)
   - Command index by category
   - v2.0 refactor pattern documentation
   - Typical workflows
   - Contribution guide

2. **`.spec-flow/memory/COMMAND-REFACTOR-PLAN.md`** (725 lines)
   - Prioritized refactor queue (8 tiers)
   - 4-sprint execution plan
   - Common issues (8 patterns)
   - Success criteria and metrics

3. **`.spec-flow/memory/COMMAND-ORGANIZATION-SUMMARY.md`** (this file)
   - Summary of organization work
   - Metadata gaps identified
   - Next steps and comparison

**Total**: 3 files, ~1,200 lines of documentation

---

## Metrics

**Documentation Coverage**:
- Before: No command index, no refactor plan
- After: 100% commands documented with category, status, and refactor priority

**Refactor Progress**:
- Completed: 5 / 47 commands (11%)
- Remaining: 42 commands
- Estimated: 13-14 days (4 sprints)

**Quality Standards**:
- v2.0 Pattern: Defined with 8 documented practices
- Testing Strategy: Per-command + integration tests specified
- Success Criteria: 10 checkpoints per command

---

## Approval Checklist

- [x] Comprehensive README created
- [x] All 47 commands categorized
- [x] Refactor plan prioritized (8 tiers)
- [x] 4-sprint execution plan defined
- [x] Common refactor issues documented (8 patterns)
- [x] Metadata gaps identified (20 commands)
- [x] Future directory structure proposed
- [x] Testing strategy defined
- [x] Success criteria established
- [x] Ready to start Sprint 1

**Status**: ✅ Organization complete, ready for systematic refactoring

---

**Generated**: 2025-11-10
**Impact**: High (establishes foundation for 42 command refactors)
**Next Command**: `/spec` (Sprint 1, Day 1)

# Cross-Platform Script Coverage Analysis

**Date**: 2025-11-18
**Analysis By**: Claude Code
**Total Commands**: 40

---

## Executive Summary

### Coverage Status

| Category | Count | Percentage |
|----------|-------|------------|
| **Both Bash & PowerShell** | 8 | 20% |
| **Bash Only** | 22 | 55% |
| **PowerShell Only** | 0 | 0% |
| **Name Mismatch** | 10 | 25% |

### Key Findings

1. **Good News**: No PowerShell-only commands → macOS/Linux fully supported
2. **Issue #1**: 22 commands have bash implementations but no PowerShell equivalents → Windows users must use Git Bash
3. **Issue #2**: 10 commands call wrong script names (naming mismatch)

---

## Category 1: Both Bash & PowerShell (8 commands) ✅

These commands work on ALL platforms (Windows, macOS, Linux):

| Command | Script Name | Bash | PowerShell |
|---------|------------|------|------------|
| calculate_tokens | calculate-tokens | ✓ | ✓ |
| check_prereqs | check-prerequisites | ✓ | ✓ |
| compact | compact-context | ✓ | ✓ |
| create_feature | create-new-feature | ✓ | ✓ |
| enable_auto_merge | enable-auto-merge | ✓ | ✓ |
| health_check_docs | health-check-docs | ✓ | ✓ |
| init_project | init-project | ✓ | ✓ |
| update_living_docs | update-living-docs | ✓ | ✓ |

**Status**: ✅ READY FOR RELEASE - Full cross-platform support

---

## Category 2: Bash Only (22 commands) ⚠️

These commands work on macOS/Linux, but Windows requires Git Bash:

| Command | Script Name | Bash | PowerShell Needed |
|---------|------------|------|-------------------|
| branch_enforce | branch-enforce | ✓ | ❌ |
| clarify | clarify-workflow | ✓ | ❌ |
| contract_bump | contract-bump | ✓ | ❌ |
| contract_verify | contract-verify | ✓ | ❌ |
| debug | debug-workflow | ✓ | ❌ |
| design_health | design-health-check | ✓ | ❌ |
| detect_infra | detect-infrastructure-needs | ✓ | ❌ |
| feature | feature-workflow | ✓ | ❌ |
| fixture_refresh | fixture-refresh | ✓ | ❌ |
| implement | implement-workflow | ✓ | ❌ |
| metrics | metrics-track | ✓ | ❌ |
| metrics_dora | dora-calculate | ✓ | ❌ |
| optimize | optimize-workflow | ✓ | ❌ |
| plan | plan-workflow | ✓ | ❌ |
| preview | preview-workflow | ✓ | ❌ |
| scheduler_assign | scheduler-assign | ✓ | ❌ |
| scheduler_list | scheduler-list | ✓ | ❌ |
| scheduler_park | scheduler-park | ✓ | ❌ |
| ship_finalize | ship-finalization | ✓ | ❌ |
| ship_prod | ship-prod-workflow | ✓ | ❌ |
| tasks | tasks-workflow | ✓ | ❌ |
| validate | validate-workflow | ✓ | ❌ |

**Impact**: Windows users without Git Bash cannot use 22/40 commands (55%)

**Priority**: HIGH - Core workflow commands missing PowerShell versions

**Effort Estimate**: 40-60 hours (2-3 hours per script × 22 scripts)

---

## Category 3: Name Mismatch (10 commands) 🔴

These commands call the wrong script name → spec-cli.py needs fixes:

| Command | Called Script | Actual Script | Fix Required |
|---------|--------------|---------------|--------------|
| deps | deps-manage | (none) | Create deps-manage.sh/.ps1 or update spec-cli.py |
| epic | epic-manage | epic-manager | Update spec-cli.py: epic-manage → epic-manager |
| flag | flag-manage | flag-add/flag-list/flag-cleanup | Create wrapper or update spec-cli.py |
| gate | gate-check | gate-ci/gate-sec | Create wrapper or update spec-cli.py |
| generate_feature_claude | generate-feature-claude | generate-feature-claude-md | Update spec-cli.py |
| generate_project_claude | generate-project-claude | generate-project-claude-md | Update spec-cli.py |
| roadmap | roadmap | roadmap-manager | Update spec-cli.py |
| schedule | schedule-manage | (scheduler-assign/list/park exist) | Create wrapper or update spec-cli.py |
| sprint | sprint-manage | (none) | Create sprint-manage.sh/.ps1 |
| version | version-bump | version-manager | Update spec-cli.py: version-bump → version-manager |

**Priority**: CRITICAL - Commands completely broken

**Effort Estimate**: 2-4 hours (update spec-cli.py + create 2-3 wrapper scripts)

---

## Detailed Analysis: Name Mismatch Scripts

### 1. generate-feature-claude / generate-project-claude

**Called**: `generate-feature-claude`, `generate-project-claude`
**Actual**: `generate-feature-claude-md.sh/.ps1`, `generate-project-claude-md.ps1`

**Fix**: Update spec-cli.py:
```python
return run_script('generate-feature-claude-md', script_args)  # Add -md suffix
return run_script('generate-project-claude-md', script_args)  # Add -md suffix
```

**Status**: Both bash and PowerShell versions exist

---

### 2. roadmap

**Called**: `roadmap`
**Actual**: `roadmap-manager.sh/.ps1`

**Fix**: Update spec-cli.py:
```python
return run_script('roadmap-manager', script_args)
```

**Status**: Both bash and PowerShell versions exist

---

### 3. version

**Called**: `version-bump`
**Actual**: `version-manager.sh/.ps1`

**Fix**: Update spec-cli.py:
```python
return run_script('version-manager', script_args)
```

**Status**: Both bash and PowerShell versions exist

---

### 4. epic

**Called**: `epic-manage`
**Actual**: `epic-manager.sh` (bash only)

**Fix Options**:
1. Update spec-cli.py: `epic-manage` → `epic-manager`
2. Create PowerShell version: `epic-manager.ps1`

**Status**: Bash only

---

### 5. flag

**Called**: `flag-manage`
**Actual**: `flag-add.sh`, `flag-list.sh`, `flag-cleanup.sh` (bash only)

**Fix Options**:
1. Create wrapper script `flag-manage.sh` that dispatches to sub-commands
2. Update spec-cli.py to call specific flag scripts based on args

**Status**: Bash only, needs wrapper

---

### 6. gate

**Called**: `gate-check`
**Actual**: `gate-ci.sh`, `gate-sec.sh` (bash only)

**Fix Options**:
1. Create wrapper script `gate-check.sh` that runs both gates
2. Update spec-cli.py to call specific gate scripts based on args

**Status**: Bash only, needs wrapper

---

### 7. schedule

**Called**: `schedule-manage`
**Actual**: `scheduler-assign.sh`, `scheduler-list.sh`, `scheduler-park.sh` (bash only)

**Fix Options**:
1. Create wrapper script `schedule-manage.sh`
2. Update spec-cli.py to dispatch to scheduler-* scripts

**Status**: Bash only, needs wrapper

---

### 8. deps

**Called**: `deps-manage`
**Actual**: `dependency-graph-parser.sh` (bash only)

**Fix Options**:
1. Rename `dependency-graph-parser.sh` → `deps-manage.sh`
2. Update spec-cli.py to call `dependency-graph-parser`

**Status**: Bash only, unclear mapping

---

### 9. sprint

**Called**: `sprint-manage`
**Actual**: (none found)

**Fix Options**:
1. Create `sprint-manage.sh/.ps1` from scratch
2. Remove from spec-cli.py if not implemented

**Status**: Not implemented

---

## Recommended Strategy

### Phase 1: Fix Name Mismatches (CRITICAL - 2-4 hours)

**Priority 1A: Update spec-cli.py for exact name matches** (30 minutes)

Fix these 4 commands where scripts exist with slightly different names:

```python
# spec-cli.py fixes
def cmd_generate_feature_claude(args):
    return run_script('generate-feature-claude-md', script_args)  # Add -md

def cmd_generate_project_claude(args):
    return run_script('generate-project-claude-md', script_args)  # Add -md

def cmd_roadmap(args):
    return run_script('roadmap-manager', script_args)  # Change to -manager

def cmd_version(args):
    return run_script('version-manager', script_args)  # Change to -manager

def cmd_epic(args):
    return run_script('epic-manager', script_args)  # Change to -manager
```

**Impact**: +5 commands working immediately (both bash & PowerShell for 3 commands)

**Priority 1B: Create wrapper scripts** (1-2 hours)

Create 3 wrapper scripts to dispatch to existing sub-command scripts:

1. **bash/flag-manage.sh** → dispatches to flag-add/list/cleanup
2. **bash/gate-check.sh** → runs gate-ci + gate-sec
3. **bash/schedule-manage.sh** → dispatches to scheduler-assign/list/park

**Impact**: +3 commands working on bash

**Priority 1C: Handle deps and sprint** (30 minutes)

1. **deps**: Update spec-cli.py to call `dependency-graph-parser` OR rename script
2. **sprint**: Either create sprint-manage.sh or mark as not implemented

**Impact**: +1-2 commands working

---

### Phase 2: Create PowerShell Versions of Bash-Only Scripts (HIGH - 40-60 hours)

**Option A: Port all 22 bash scripts to PowerShell** (40-60 hours)
- Ensures native PowerShell experience on Windows
- No Git Bash dependency
- Effort: 2-3 hours per script × 22 scripts = 44-66 hours

**Option B: Prioritize core workflow scripts** (20-30 hours)
- Port only the 9 most critical workflow scripts
- Leave utility scripts bash-only
- Effort: 2-3 hours × 9 scripts = 18-27 hours

**Priority Order for Option B**:
1. clarify-workflow (Phase 0)
2. plan-workflow (Phase 1)
3. tasks-workflow (Phase 2)
4. validate-workflow (Phase 3)
5. implement-workflow (Phase 4)
6. optimize-workflow (Phase 5)
7. preview-workflow (Phase 6)
8. ship-prod-workflow (Phase 7)
9. feature-workflow (orchestrator)

**Option C: Create PowerShell wrappers that call bash** (4-6 hours)
- Create thin PowerShell wrappers that invoke bash scripts via WSL or Git Bash
- Quick win, but requires bash on Windows
- Effort: 15-20 minutes per wrapper × 22 scripts = 5.5-7.3 hours

Example wrapper:
```powershell
# powershell/clarify-workflow.ps1
param($Feature, [switch]$Json)

$bashScript = Join-Path $PSScriptRoot "..\bash\clarify-workflow.sh"
$args = @($Feature)
if ($Json) { $args += "--json" }

& bash $bashScript @args
```

---

### Phase 3: Testing & Documentation (LOW - 4-6 hours)

1. Re-run comprehensive tests (1 hour)
2. Update CLAUDE.md with platform compatibility notes (1 hour)
3. Update README with platform-specific installation instructions (2 hours)

---

## Recommended Implementation Plan

### Sprint 1: Fix Critical Name Mismatches (1 day)

**Goal**: Get all existing scripts working via spec-cli.py

**Tasks**:
- [ ] Update spec-cli.py script names (5 commands)
- [ ] Create 3 wrapper scripts (flag-manage, gate-check, schedule-manage)
- [ ] Handle deps and sprint commands
- [ ] Test all 10 fixed commands

**Deliverable**: 40/40 commands have correct script mappings

**Impact**: +10 commands working on macOS/Linux, +5 commands working on Windows (PowerShell)

---

### Sprint 2: PowerShell Wrappers (2-3 days)

**Goal**: Get all commands working on Windows (Git Bash fallback)

**Tasks**:
- [ ] Create PowerShell wrapper template
- [ ] Generate 22 PowerShell wrappers for bash-only commands
- [ ] Test all wrappers on Windows
- [ ] Document Git Bash requirement

**Deliverable**: 40/40 commands work on Windows with Git Bash installed

**Impact**: Full cross-platform support (Windows requires Git Bash)

---

### Sprint 3: Native PowerShell (Optional - 4-6 weeks)

**Goal**: Remove Git Bash dependency for Windows users

**Tasks**:
- [ ] Port 9 core workflow scripts to PowerShell
- [ ] Port 13 utility scripts to PowerShell
- [ ] Comprehensive testing on Windows (PowerShell only)
- [ ] Remove wrapper scripts, use native implementations

**Deliverable**: 40/40 commands work natively on Windows PowerShell

**Impact**: Native Windows experience, no Git Bash required

---

## Current State Summary

### What Works Today

**macOS/Linux**: 30/40 commands (75%)
- 8 commands with both bash & PowerShell
- 22 commands with bash only
- 10 commands broken (name mismatch)

**Windows (PowerShell)**: 8/40 commands (20%)
- 8 commands with both bash & PowerShell
- 0 PowerShell-only commands
- 32 commands unavailable (22 bash-only + 10 broken)

**Windows (Git Bash)**: 30/40 commands (75%) - Same as macOS/Linux
- Requires Git Bash installation
- Uses bash scripts via Unix path conversion (Priority Fix #1)

---

## Release Recommendation

### v6.7.0 (Current Release)

**Ship with**:
- Priority Fix #1 (Windows path conversion) ✅
- Priority Fix #2 (PowerShell parameter naming) ✅
- Priority Fix #3 (Verbose parameter) ✅
- 8 commands with full cross-platform support ✅

**Document**:
- Windows users need Git Bash for full functionality
- macOS/Linux fully supported
- 10 commands broken (name mismatch) - list in KNOWN_ISSUES.md

**Effort**: 0 hours (already complete)

---

### v6.8.0 (Next Release - 1 week)

**Add**:
- Phase 1: Fix all name mismatches (+10 commands working)
- Phase 2: PowerShell wrappers for bash scripts (+22 commands on Windows with Git Bash)

**Result**: 40/40 commands working on all platforms (Windows requires Git Bash)

**Effort**: 6-10 hours

---

### v7.0.0 (Future - 6-8 weeks)

**Add**:
- Phase 3: Native PowerShell implementations (remove Git Bash dependency)

**Result**: 40/40 commands natively supported on Windows PowerShell, macOS, Linux

**Effort**: 40-60 hours

---

## Platform Support Matrix

| Platform | v6.7.0 | v6.8.0 | v7.0.0 |
|----------|--------|--------|--------|
| **macOS** | 30/40 (75%) | 40/40 (100%) | 40/40 (100%) |
| **Linux** | 30/40 (75%) | 40/40 (100%) | 40/40 (100%) |
| **Windows (PowerShell)** | 8/40 (20%) | 8/40 (20%)* | 40/40 (100%) |
| **Windows (Git Bash)** | 30/40 (75%) | 40/40 (100%) | 40/40 (100%) |

*v6.8.0 Windows PowerShell: Can invoke bash via wrappers if Git Bash installed

---

**Analysis Generated**: 2025-11-18
**Next Step**: Decide on Sprint 1 (fix name mismatches) or Sprint 2 (PowerShell wrappers)

# Implementation Plan: Epic/Feature Workflow Simplification

## Overview

Refactor the epic and feature workflow system to reduce complexity while preserving the excellent architectural foundations (Task() isolation, Domain Memory v2, observable state).

## Problem Statement

The current implementation has accumulated complexity:
- `implement-epic.md` is 1,558 lines (unmaintainable)
- Unclear agent routing (worker vs specialist)
- No recovery mechanism for corrupted state
- Over-specified error handling inline in commands

## Goals

1. **Reduce implement-epic.md by 60%** - Extract utilities to shared locations
2. **Clear agent routing** - One decision tree, no ambiguity
3. **Add state recovery** - `/workflow repair` command
4. **Maintainable code** - Each file < 400 lines

## Phase 1: Extract Error Handling (Immediate)

### 1.1 Create error classification skill

Extract `classifyFailure()` and `attemptAutoFix()` to a reusable skill:

**Location**: `.claude/skills/error-recovery/SKILL.md`

**Scope**:
- Failure classification (critical vs fixable)
- Auto-fix strategy execution
- Retry logic with progressive delays

**Why**: This logic is useful across all workflows, not just epic implementation.

### 1.2 Create sprint execution utilities

Extract sprint-specific helpers to bash scripts:

**Location**: `.spec-flow/scripts/bash/sprint-utils.sh`

**Functions**:
- `validate_sprint_dirs()` - Check sprint directories exist
- `check_sprint_status()` - Read sprint state.yaml
- `consolidate_layer_results()` - Aggregate sprint results

## Phase 2: Simplify implement-epic.md

### 2.1 New structure (target: 300 lines)

```markdown
# implement-epic.md

## Context
[Load epic state - 20 lines]

## Process
### Step 1: Validate prerequisites - 30 lines
### Step 2: Execute layers - 50 lines (calls utilities)
### Step 3: Handle results - 30 lines
### Step 4: Trigger audit - 20 lines

## Error Handling
[Reference skill: error-recovery] - 10 lines

## Success Criteria - 20 lines
```

### 2.2 Remove inline JavaScript

Replace pseudocode with:
- References to skills for complex logic
- Bash command invocations for utilities
- Clear prose instructions for orchestration

## Phase 3: Agent Routing Clarity

### 3.1 Create routing decision tree

**Location**: `.claude/agents/ROUTING.md`

```
When to use which agent:

1. WORKER (domain/worker.md)
   - Single feature implementation
   - Atomic work with domain-memory.yaml
   - Default for /implement phase

2. SPECIALIST (backend-dev, frontend-dev, etc.)
   - Sprint-level work in epics
   - When sprint has clear domain (backend-only, frontend-only)
   - Use when no domain-memory.yaml exists

3. PHASE AGENTS (spec-agent, plan-agent, etc.)
   - Workflow phase execution
   - Always spawned by orchestrator
   - Never called directly by user
```

### 3.2 Update implement-epic.md to reference routing

Remove inline agent selection logic, reference ROUTING.md.

## Phase 4: State Recovery Command

### 4.1 Create /workflow repair command

**Location**: `.claude/commands/meta/workflow-repair.md`

**Capabilities**:
- Detect corrupted state.yaml
- Rebuild state from artifacts (spec.md, plan.md exist = those phases complete)
- Reset phase to last known good state
- Clear stale locks in domain-memory.yaml

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing workflows | Test with existing specs/ before committing |
| Skill extraction changes behavior | Keep exact same logic, just relocated |
| Routing doc becomes stale | Add validation in CI |

## Success Metrics

- [ ] implement-epic.md < 400 lines
- [ ] Error recovery skill tested and working
- [ ] Agent routing documented with examples
- [ ] /workflow repair handles common corruption cases
- [ ] All existing tests still pass

## Estimated Effort

| Task | Complexity |
|------|------------|
| Error recovery skill | Medium |
| Sprint utilities script | Small |
| Simplify implement-epic | Medium |
| Agent routing doc | Small |
| Workflow repair command | Medium |

Total: ~4-6 hours focused work

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The Spec-Flow Workflow Kit orchestrates feature delivery through a series of slash commands that transform product ideas into production releases via Spec-Driven Development. Each command produces auditable artifacts and hands context to the next specialist.

## Core Commands

Run commands in sequence to move features through the workflow:

**Windows (PowerShell 7.3+):**
```powershell
# Validate environment
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json

# Create new feature
pwsh -File .spec-flow/scripts/powershell/create-new-feature.ps1 "Feature Name"

# Calculate token budget
pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/NNN-slug

# Compact context when over budget
pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 -FeatureDir specs/NNN-slug -Phase "implementation"
```

**macOS/Linux (Bash 5+):**
```bash
# Validate environment
.spec-flow/scripts/bash/check-prerequisites.sh --json

# Create new feature
.spec-flow/scripts/bash/create-new-feature.sh "Feature Name"

# Calculate token budget
.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/NNN-slug

# Compact context when over budget
.spec-flow/scripts/bash/compact-context.sh --feature-dir specs/NNN-slug --phase implementation
```

## Workflow State Machine

Features progress through fixed phases with automatic state tracking:

```
/feature → /clarify (if needed) → /plan → /tasks → /validate → /implement
  ↓
/ship (unified deployment orchestrator)
  ↓
Model-specific workflow:
  • staging-prod: /optimize → /preview → /ship-staging → /validate-staging → /ship-prod
  • direct-prod: /optimize → /preview → /deploy-prod
  • local-only: /optimize → /preview → /build-local
```

**Unified Deployment**:
- Use `/ship` after `/implement` to automatically execute the appropriate deployment workflow
- Deployment model is auto-detected (staging-prod, direct-prod, or local-only)
- Use `/ship continue` to resume after manual gates or failures
- Use `/ship status` to check current progress
- Commands are defined in `.claude/commands/`

## New Features (v1.1.0)

### YAML State Files

**What Changed**: Workflow state migrated from JSON to YAML.

**Benefits**:
- LLM-friendly (easier for Claude to edit)
- Comments supported
- Human-readable
- Fewer syntax errors

**Prerequisites**:
- **macOS/Linux**: `yq` >= 4.0 (`brew install yq`)
- **Windows**: `yq` >= 4.0 (`choco install yq`)

**Files**: `specs/NNN-slug/workflow-state.yaml` (previously `.json`)

**Auto-Migration**: Automatic conversion from JSON on first access

**Manual Migration**:
```bash
# Bash (with dry-run)
.spec-flow/scripts/bash/migrate-state-to-yaml.sh --dry-run
.spec-flow/scripts/bash/migrate-state-to-yaml.sh

# PowerShell
.spec-flow/scripts/powershell/migrate-state-to-yaml.ps1 -DryRun
.spec-flow/scripts/powershell/migrate-state-to-yaml.ps1
```

### Roadmap Integration (GitHub Issues)

**IMPORTANT**: This workflow is an **npm package**. There are two distinct roadmap use cases:

#### 1. Workflow Development (This Repo)

**Purpose**: Track improvements to the workflow system itself

**Source**: This repo's GitHub Issues

**Status**: ✅ Active (old markdown roadmap archived 2025-10-20)

**Usage**:
```bash
# View workflow improvements
gh issue list --label type:feature

# Create workflow improvement
gh issue create --template feature.yml

# Programmatic creation
source .spec-flow/scripts/bash/github-roadmap-manager.sh
create_roadmap_issue "Improve /roadmap" "Add GitHub Projects" 4 3 0.8 "infra" "all" "roadmap-projects"
```

**See**: `docs/WORKFLOW_DEVELOPMENT_ROADMAP.md`

#### 2. User Project Roadmaps (User Repos)

**Purpose**: Product features that users of this workflow are building

**Source**: User's own GitHub Issues (their repos)

**Status**: ⏳ Pending - `/roadmap` command needs update

**Planned Usage** (when implemented):
- Users run `/roadmap` command in their repos
- Creates issues in their GitHub repo (not this one)
- Same ICE scoring and label system
- Integrates with `/feature` and `/ship` commands

**Current Status**: `/roadmap` command uses markdown (legacy, will be updated)

---

**ICE Prioritization**: Issues include YAML frontmatter with Impact/Confidence/Effort scoring
- Score = (Impact × Confidence) / Effort
- Auto-applied priority labels based on score

**Issue Templates**: `.github/ISSUE_TEMPLATE/`
- `feature.yml` - Features with ICE scoring
- `enhancement.yml` - Enhancements
- `bug.yml` - Bug reports
- `task.yml` - Tasks

**Labels Schema**:
- **Priority**: `priority:high|medium|low` (auto-applied by ICE score)
- **Type**: `type:feature|enhancement|bug|task`
- **Area**: `area:backend|frontend|api|infra|design|marketing`
- **Role**: `role:all|free|student|cfi|school`
- **Status**: `status:backlog|next|later|in-progress|shipped|blocked`
- **Size**: `size:small|medium|large|xl` (auto-applied by effort)

**Core Functions** (for both use cases):
- `.spec-flow/scripts/bash/github-roadmap-manager.sh` - Roadmap functions
- `.spec-flow/scripts/powershell/github-roadmap-manager.ps1` - PowerShell version
- `.spec-flow/scripts/bash/setup-github-labels.sh` - Label setup

**Archived**: `.spec-flow/memory/roadmap-archived-2025-10-20.md` - Old workflow roadmap

**Guides**:
- `docs/WORKFLOW_DEVELOPMENT_ROADMAP.md` - For workflow contributors
- `docs/github-roadmap-migration.md` - Technical reference and user project setup

### Version Management

**Automatic Semantic Versioning**: Every production deployment increments version and creates git tag.

**Process** (during `/ship` Phase S.5):
1. Read current version from `package.json`
2. Analyze spec/ship-report for bump type:
   - "breaking change" → MAJOR (1.2.3 → 2.0.0)
   - "fix"/"bug"/"patch" → PATCH (1.2.3 → 1.2.4)
   - Default → MINOR (1.2.3 → 1.3.0)
3. Update `package.json`
4. Create annotated git tag: `v1.3.0`
5. Generate `RELEASE_NOTES.md`
6. Update roadmap with version

**Scripts**:
- `.spec-flow/scripts/bash/version-manager.sh`
- `.spec-flow/scripts/powershell/version-manager.ps1`

**Manual Bump** (if needed):
```bash
# Bash (interactive)
source .spec-flow/scripts/bash/version-manager.sh
interactive_version_bump "specs/NNN-slug"

# PowerShell (interactive)
. .spec-flow/scripts/powershell/version-manager.ps1
Invoke-InteractiveVersionBump -FeatureDir "specs/NNN-slug"
```

**Non-Blocking**: Continues with warning if `package.json` missing

---

## New Features (v1.2.0) - Workflow Streamlining

### Auto-Continue Workflow

**What Changed**: `/feature` now automatically continues from implementation through deployment.

**Before** (v1.1.0):
```bash
/feature "description"
# ... Phase 4 (implement) completes ...
# ❌ Workflow stops - user must manually run:
/optimize
# ... optimization completes ...
# ❌ Workflow stops again:
/ship
```

**After** (v1.2.0):
```bash
/feature "description"
# ... Phase 4 (implement) completes ...
# ✅ Auto-continues to /optimize
# ... optimization completes ...
# ✅ Auto-continues to /ship
# ... deployment completes ...
# 🎉 Done! (Only stops at manual gates)
```

**Benefits**:
- **30-40% faster** - Eliminates manual transitions between phases
- **Fewer context switches** - Developer doesn't need to babysit workflow
- **Intelligent blocking** - Only stops for critical errors or manual gates

**Manual Gates** (where workflow pauses for human input):
1. **MVP Gate** (during /implement): "Ship P1 MVP now or continue to P2/P3?"
2. **Pre-flight Approval** (before /ship): "Approve deployment start?"
3. **Preview** (after /optimize): Manual UI/UX testing on local dev server
4. **Staging Validation** (after staging deploy): Manual testing in staging environment

**Blocking Conditions** (where workflow stops for fixes):
- ❌ Build failures (frontend/backend/Docker)
- ❌ Critical code review issues (security, contract violations)
- ❌ Deployment failures (CI/CD errors)

**Resume After Stop**:
```bash
/feature continue
# Automatically resumes from last completed phase
```

### Parallel Execution

**What Changed**: Multiple optimization and validation checks now run in parallel for 3-5x speedup.

#### /optimize - 5 Parallel Checks

**Before** (Sequential):
```
Performance → Security → Accessibility → Code Review → Migrations
   ⏱️ 2min     ⏱️ 3min      ⏱️ 2min          ⏱️ 5min         ⏱️ 1min
Total: ~13 minutes
```

**After** (Parallel):
```
Performance ┐
Security    ├─→ All run simultaneously
Accessibility │
Code Review   │
Migrations    ┘
Total: ~5 minutes (4-5x faster)
```

**Implementation**:
- All 5 checks launched as parallel Task() calls in single message
- Results aggregated after all complete
- Critical issues block deployment
- Auto-fix option for fixable issues

#### /ship Pre-flight - 5 Parallel Checks

**Before** (Sequential):
```
Env Vars → Build → Docker → CI Config → Dependencies
  ⏱️ 1min    ⏱️ 3min  ⏱️ 4min    ⏱️ 1min      ⏱️ 2min
Total: ~11 minutes
```

**After** (Parallel):
```
Env Vars   ┐
Build      ├─→ All run simultaneously
Docker     │
CI Config  │
Dependencies┘
Total: ~4 minutes (3-4x faster)
```

**Implementation**:
- All 5 checks launched as background bash jobs (&)
- Results aggregated using wait command
- Build failures block deployment
- Detailed logs per check in preflight-logs/

#### /design-variations - N Parallel Screens

**What Changed**: Design variants for multiple screens generated in parallel.

**Before** (Sequential):
```
Screen 1 → Screen 2 → Screen 3 → Screen 4 → Screen 5
  ⏱️ 5min     ⏱️ 5min     ⏱️ 5min     ⏱️ 5min     ⏱️ 5min
Total: 25 minutes
```

**After** (Parallel):
```
Screen 1 ┐
Screen 2 ├─→ All screens generated simultaneously
Screen 3 │
Screen 4 │
Screen 5 ┘
Total: ~5 minutes (5x faster for 5 screens)
```

**Implementation**:
- Each screen gets dedicated frontend-shipper agent
- All agents launched in single message with multiple Task() calls
- Nx speedup where N = number of screens

### Performance Summary

**Overall Workflow** (feature start → production):
- **Before**: Manual phase transitions + sequential checks = slower
- **After**: Auto-continue + parallel execution = 30-40% faster overall

**Specific Improvements**:
- `/optimize` phase: **4-5x faster** (13min → 5min)
- `/ship` pre-flight: **3-4x faster** (11min → 4min)
- `/design-variations`: **Nx faster** (25min → 5min for 5 screens)
- Phase transitions: **Instant** (no manual delays)

### Workflow State Management

**Enhanced State Tracking** (workflow-state.yaml):
- Tracks current phase and completion status
- Records quality gate results (pre-flight, code review, rollback)
- Stores manual gate approvals (preview, staging validation)
- Enables resume capability with `/feature continue`

**State Example**:
```yaml
workflow:
  phase: ship:optimize
  status: in_progress
  completed_phases:
    - spec
    - plan
    - tasks
    - validate
    - implement
  manual_gates:
    preview:
      status: pending
      timestamp: 2025-10-21T10:30:00Z
quality_gates:
  pre_flight:
    passed: true
    checks:
      env: passed
      build: passed
      docker: passed
      ci: passed
      deps: warning
```

### Breaking Changes

None - all changes are backward compatible. Existing workflows continue to work, but won't get auto-continue or parallel execution benefits until updated.

### Migration

No migration required - changes are in command definitions, not state files.

---

## Architecture

**Directory structure:**
- `.claude/agents/` — Persona briefs for specialists (backend, frontend, QA, release)
- `.claude/commands/` — Command specifications with inputs, outputs, and auto-progression
- `.spec-flow/memory/` — Long-term references (roadmap, constitution, design inspirations)
- `.spec-flow/templates/` — Markdown scaffolds for specs, plans, tasks, reports
- `.spec-flow/scripts/powershell/` — Windows/cross-platform automation
- `.spec-flow/scripts/bash/` — macOS/Linux automation
- `specs/NNN-slug/` — Feature working directories created by `/feature`

**Context management:**
- Phase-based token budgets: Planning (75k), Implementation (100k), Optimization (125k)
- Auto-compact at 80% threshold using phase-aware strategies
- Compaction reduces context by 90%/60%/30% depending on phase
- Run `calculate-tokens` before heavy operations to check budget

## Key Artifacts

Each command produces structured outputs:

| Command | Artifacts |
|---------|-----------|
| `/feature` | `spec.md`, `NOTES.md`, `visuals/README.md`, `workflow-state.yaml` |
| `/plan` | `plan.md`, `research.md` |
| `/tasks` | `tasks.md` (20-30 tasks with acceptance criteria) |
| `/validate` | `analysis-report.md` |
| `/implement` | Implementation checklist + task completion |
| `/ship` | `ship-summary.md`, state updates, deployment orchestration |
| `/optimize` | `optimization-report.md`, `code-review-report.md` |
| `/preview` | `release-notes.md`, preview checklist |
| `/ship-staging` | `staging-ship-report.md`, `deployment-metadata.json` |
| `/validate-staging` | Staging sign-off summary, rollback test results |
| `/ship-prod` | `production-ship-report.md`, release version |
| `/deploy-prod` | `production-ship-report.md`, deployment IDs |
| `/build-local` | `local-build-report.md`, build artifacts analysis |
| `/deploy-status` | Real-time deployment status display |

**State Management**: All commands update `workflow-state.yaml` with:
- Current phase and status
- Completed/failed phases
- Quality gates (pre-flight, code review, rollback capability)
- Manual gates (preview, staging validation)
- Deployment information (URLs, IDs, timestamps)
- Artifact paths

## Deployment Models

The workflow automatically detects and adapts to three deployment models:

### staging-prod (Recommended)
- **Detection**: Git remote + staging branch + `.github/workflows/deploy-staging.yml`
- **Workflow**: optimize → preview → ship-staging → validate-staging → ship-prod
- **Features**: Full staging validation, rollback testing, production promotion
- **Use for**: Production applications, team projects, critical deployments

### direct-prod
- **Detection**: Git remote + no staging branch/workflow
- **Workflow**: optimize → preview → deploy-prod
- **Features**: Direct production deployment, deployment ID tracking
- **Use for**: Simple applications, solo developers, rapid iteration
- **Risk**: Higher (no staging validation)

### local-only
- **Detection**: No git remote configured
- **Workflow**: optimize → preview → build-local
- **Features**: Local build validation, security scanning, artifact analysis
- **Use for**: Local development, prototypes, desktop applications

**Override**: Set deployment model explicitly in `.spec-flow/memory/constitution.md`

## Quality Gates

### Pre-flight Validation (Blocking)
- Environment variables configured
- Production build succeeds
- Docker images build
- CI configuration valid
- Dependencies checked

**Blocks deployment if failed**

### Code Review Gate (Blocking)
- No critical code quality issues
- Performance benchmarks met
- Accessibility standards (WCAG 2.1 AA)
- Security scan completed

**Blocks deployment if critical issues found**

### Rollback Capability Gate (staging-prod only, Blocking)
- Deployment IDs extracted from logs
- Rollback test executed (actual Vercel alias change)
- Previous deployment verified live
- Roll-forward verified

**Blocks production if rollback test fails**

### Manual Gates (Pause for approval)
- **Preview**: Manual UI/UX testing on local dev server
- **Staging Validation**: Manual testing in staging environment (staging-prod only)

**Requires `/ship continue` to proceed**

## Coding Standards

**Markdown:**
- Sentence-case headings
- Wrap near 100 characters
- Imperative voice for instructions
- Bullets for checklists

**PowerShell scripts:**
- Four-space indentation
- `Verb-Noun` function names
- Comment-based help
- No aliases in scripts
- Support `-WhatIf` where feasible

**Shell scripts:**
- POSIX-friendly
- Exit on error (`set -e`)
- Document required tools in header

**Naming:**
- Use `kebab-case` for all files (e.g., `agent-brief.md`)
- CamelCase only for PowerShell modules

## Commit Convention

Follow Conventional Commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `chore:` maintenance
- `refactor:` code restructure
- `test:` test additions

Example: `docs: refresh debugger brief`

Keep subjects under 75 characters, imperative mood.

## Testing

No CI pipeline yet. Validate locally before submitting:
- PowerShell: `Invoke-Pester -Path tests`
- Shell: Test with `-WhatIf` flags or dry-run modes
- Markdown: Preview in renderer, verify token estimates with `calculate-tokens`

## Agent Briefs

Specialist agents are organized in `.claude/agents/` by category:

**Phase Orchestrators** (`phase/`):
- `spec.md`, `clarify.md`, `plan.md`, `tasks.md`, `validate.md`, `implement.md`, `optimize.md`, `ship-staging.md`, `ship-prod.md`, `finalize.md`

**Implementation Specialists** (`implementation/`):
- `backend.md` — Backend implementation
- `frontend.md` — Frontend implementation
- `database.md` — Database architecture
- `api-contracts.md` — API contract management

**Quality Specialists** (`quality/`):
- `code-reviewer.md` — Code review
- `qa-tester.md` — QA and testing
- `test-coverage.md` — Test coverage enhancement
- `debug.md` — Error triage and debugging

**Deployment Specialists** (`deployment/`):
- `release.md` — CI/CD and release management

When working with agents, load the relevant brief for context on capabilities and responsibilities.

## Philosophy

1. **Specification first** — Every artifact traces to explicit requirements
2. **Agents as teammates** — Commands encode expectations for alignment
3. **Context discipline** — Token budgets measured, compacted, recycled
4. **Ship in stages** — Staging and production have dedicated rituals with human gates

## References

- `README.md` — Quick start and script reference
- `docs/architecture.md` — High-level workflow structure
- `docs/commands.md` — Command catalog
- `CONTRIBUTING.md` — Branching, PRs, release process
- `AGENTS.md` — Contributor guide for this repo

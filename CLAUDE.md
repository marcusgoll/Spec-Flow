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

### Roadmap Integration

**Automatic Lifecycle Tracking**: Features move through roadmap sections automatically.

**Lifecycle**: `Backlog → Next → In Progress → Shipped`

**Automatic Updates**:
- `/feature` → Marks feature "In Progress"
- `/ship` (Phase S.5) → Marks feature "Shipped" with version/date

**Feature Discovery**: Workflow detects potential features in code comments:
- Patterns: "TODO", "future work", "phase 2", "out of scope"
- Prompts: "Add to roadmap? (yes/no/later)"
- Saves deferred to `.spec-flow/memory/discovered-features.md`

**File**: `.spec-flow/memory/roadmap.md`

**Scripts**:
- `.spec-flow/scripts/bash/roadmap-manager.sh`
- `.spec-flow/scripts/powershell/roadmap-manager.ps1`

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
| `/ship-status` | Real-time deployment status display |

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

Specialist agents are defined in `.claude/agents/`:
- `backend-dev.md` — Backend implementation
- `frontend-shipper.md` — Frontend implementation
- `qa-test.md` — QA and testing
- `senior-code-reviewer.md` — Code review
- `debugger.md` — Error triage
- `ci-cd-release.md` — CI/CD and deployment

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

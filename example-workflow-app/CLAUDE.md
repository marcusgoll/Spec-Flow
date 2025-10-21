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

Features progress through fixed phases:

```
/spec-flow → /clarify (if needed) → /plan → /tasks → /analyze → /implement → /optimize →
/preview (manual gate) → /phase-1-ship → /validate-staging (manual gate) → /phase-2-ship
```

- Use `/feature "Feature description"` to automate progression with manual gates
- Use `/feature continue` to resume after manual intervention or fixes
- Commands are defined in `.claude/commands/`

## Architecture

**Directory structure:**
- `.claude/agents/` — Persona briefs for specialists (backend, frontend, QA, release)
- `.claude/commands/` — Command specifications with inputs, outputs, and auto-progression
- `.spec-flow/memory/` — Long-term references (roadmap, constitution, design inspirations)
- `.spec-flow/templates/` — Markdown scaffolds for specs, plans, tasks, reports
- `.spec-flow/scripts/powershell/` — Windows/cross-platform automation
- `.spec-flow/scripts/bash/` — macOS/Linux automation
- `specs/NNN-slug/` — Feature working directories created by `/spec-flow`

**Context management:**
- Phase-based token budgets: Planning (75k), Implementation (100k), Optimization (125k)
- Auto-compact at 80% threshold using phase-aware strategies
- Compaction reduces context by 90%/60%/30% depending on phase
- Run `calculate-tokens` before heavy operations to check budget

## Key Artifacts

Each command produces structured outputs:

| Command | Artifacts |
|---------|-----------|
| `/spec-flow` | `spec.md`, `NOTES.md`, `visuals/README.md` |
| `/plan` | `plan.md`, `research.md` |
| `/tasks` | `tasks.md` (20-30 tasks with acceptance criteria) |
| `/analyze` | `analysis-report.md` |
| `/implement` | Implementation checklist + task completion |
| `/optimize` | `optimization-report.md`, `code-review-report.md` |
| `/preview` | `release-notes.md`, preview checklist |
| `/phase-1-ship` | Staging deployment record |
| `/validate-staging` | Staging sign-off summary |
| `/phase-2-ship` | Production launch checklist |

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

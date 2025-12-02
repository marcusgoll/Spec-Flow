# CLAUDE.md

Spec-Flow Workflow Kit: Slash commands transform product ideas into production releases via spec-driven development.

## WHAT This Is

Spec-Flow is a workflow toolkit for Claude Code that automates the entire software development lifecycle through slash commands. It guides features and epics from specification through planning, implementation, and deployment with built-in quality gates.

All workflow artifacts live in `specs/` (features) or `epics/` (complex work). The hierarchical CLAUDE.md system provides progressive disclosure - this file contains essential instructions, while detailed documentation loads on-demand from `docs/references/`.

## WHY This Approach Works

- **LLMs are stateless** — This file onboards Claude consistently each conversation
- **Progressive disclosure** — Essential instructions here; deep dives in `docs/references/`
- **Deterministic validation** — Scripts handle quality gates; Claude handles creative work
- **Hierarchical context** — Root → Project → Feature CLAUDE.md (74-80% token reduction)

## HOW To Use It

### Quick Start

**Feature** (single subsystem, <16h):
```
/feature "desc" → /plan → /tasks → /implement → /optimize → /ship
```

**Epic** (multiple subsystems, >16h):
```
/epic "goal" → /plan → /tasks → /implement-epic → /optimize → /ship → /finalize
```

**Resume work**: `/feature continue` or `/epic continue`

### Essential Commands

| Command | Purpose |
|---------|---------|
| `/feature "name"` | Start single-subsystem feature |
| `/epic "goal"` | Start multi-sprint complex work |
| `/plan` | Generate implementation design |
| `/tasks` | Create TDD task breakdown |
| `/implement` | Execute tasks with TDD |
| `/optimize` | Run quality gates |
| `/ship` | Deploy to appropriate environment |
| `/help` | Context-aware guidance |

**Workflow Health**: `/audit-workflow`, `/heal-workflow`, `/workflow-health`

**Context Management**: `/whats-next`, `/add-to-todos`, `/check-todos`

**Project Setup**: `/init-project`, `/init-preferences`, `/roadmap`

### Deployment Models (Auto-Detected)

- **staging-prod**: `/ship-staging` → `/validate-staging` → `/ship-prod`
- **direct-prod**: `/deploy-prod`
- **local-only**: `/build-local`

Detection: git remote + staging branch + `.github/workflows/deploy-staging.yml`

### Quality Gates

**Blocking**:
- Pre-flight: Build, env vars, CI config
- Code review: No critical issues, security, WCAG 2.1 AA
- E2E + Visual: Playwright tests, visual regression
- Rollback: Verify capability (staging-prod only)

**Manual** (pause for approval):
- Mockup approval (UI-first only)
- Staging validation (staging-prod only)

Resume: `/ship continue` or `/feature continue`

### Directory Structure

```
.claude/agents/     — Specialist briefs (load on-demand)
.claude/commands/   — Slash command definitions
.claude/skills/     — Progressive disclosure content
.spec-flow/scripts/ — Automation scripts
.spec-flow/config/  — User preferences
specs/NNN-slug/     — Feature workspaces
epics/NNN-slug/     — Epic workspaces
docs/project/       — Project documentation
docs/references/    — Deep-dive documentation
```

### Agent Categories

**Phase**: spec, clarify, plan, tasks, validate, implement, optimize, ship-staging, ship-prod, finalize, epic

**Implementation**: backend, frontend, database, api-contracts, test-architect

**Quality/Code**: code-reviewer, refactor-planner, refactor-surgeon, type-enforcer, cleanup-janitor

**Quality/Testing**: qa-tester, test-coverage, api-fuzzer, accessibility-auditor, ux-polisher

**Quality/Security**: security-sentry, performance-profiler, error-budget-guardian

Load briefs from `.claude/agents/` for context.

### Coding Standards

- **Commits**: Conventional Commits (feat/fix/docs/chore), <75 chars, imperative
- **Markdown**: Sentence-case headings, wrap ~100 chars
- **Naming**: kebab-case files, CamelCase PowerShell only
- **Shell**: POSIX-friendly, set -e, document tools

### Preference System

Run `/init-preferences` once to configure defaults. Commands use 3-tier system:
1. Config file (`.spec-flow/config/user-preferences.yaml`)
2. Command history (learns from usage)
3. Command flags (explicit overrides)

All commands support `--no-input` for CI/CD automation.

### State Management

`state.yaml` tracks: phase, status, quality gates, deployment info, artifact paths, workflow type.

### Artifacts by Command

| Command | Outputs |
|---------|---------|
| `/feature` | spec.md, NOTES.md, state.yaml |
| `/plan` | plan.md, research.md |
| `/tasks` | tasks.md |
| `/optimize` | optimization-report.md, code-review-report.md |
| `/finalize` | Archives to completed/ |

### Token Management

Token budgets: Planning (75k), Implementation (100k), Optimization (125k)

Auto-compact at 80% threshold via `.spec-flow/scripts/bash/compact-context.sh`

## Deep References

For detailed documentation, see `docs/references/`:

- [Git Worktrees](docs/references/git-worktrees.md) — Parallel development
- [Perpetual Learning](docs/references/perpetual-learning.md) — Self-improvement system
- [Workflow Detection](docs/references/workflow-detection.md) — Auto-detection utilities
- [Migration Safety](docs/references/migration-safety.md) — Database migration enforcement
- [MAKER Error Correction](docs/references/maker-error-correction.md) — Task decomposition methodology
- [Feedback Loops](docs/references/feedback-loops.md) — Gap discovery workflow
- [Epic Blueprints](docs/references/epic-blueprints.md) — Frontend blueprint workflow
- [Artifact Archival](docs/references/artifact-archival.md) — Post-finalize cleanup

### UI-First Workflow

```
/feature → /clarify → /plan → /tasks --ui-first → [MOCKUP APPROVAL] → /implement → /ship
```

Mockups in `specs/NNN-slug/mockups/*.html`. Blocks /implement until approved.

### Prototype Workflow (v10.3+)

Optional project-wide prototype: `/prototype [create|update|status]`

Location: `design/prototype/`. Coexists with per-feature mockups.

### Project Initialization

`/init-project` generates 8 docs in `docs/project/`:
- overview.md, system-architecture.md, tech-stack.md, data-architecture.md
- api-strategy.md, capacity-planning.md, deployment-strategy.md, development-workflow.md

Add `--with-design` for 4 design docs + tokens.css.

## See Also

- [README.md](README.md) — Quick start
- [docs/commands.md](docs/commands.md) — Command catalog
- [docs/architecture.md](docs/architecture.md) — Workflow structure
- [docs/LIVING_DOCUMENTATION.md](docs/LIVING_DOCUMENTATION.md) — Hierarchical context guide
- [CHANGELOG.md](CHANGELOG.md) — Version history

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

### Essential Commands (30 total)

| Command | Purpose |
|---------|---------|
| `/feature "name"` | Start single-subsystem feature |
| `/epic "goal"` | Start multi-sprint complex work |
| `/quick "desc"` | Quick fix (<100 LOC) |
| `/plan` | Generate implementation design |
| `/tasks` | Create TDD task breakdown |
| `/implement` | Execute tasks with TDD |
| `/implement-epic` | Parallel sprint execution for epics |
| `/optimize` | Run quality gates |
| `/ship` | Deploy (--staging, --prod, status, budget) |
| `/help` | Context-aware guidance |

**Project Setup**: `/init`, `/init --preferences`, `/init --tokens`, `/roadmap`, `/prototype`

**Context Management**: `/context next`, `/context todos`, `/context add`

**Quality Gates**: `/gate ci`, `/gate sec`, `/fix-ci`

**Create Extensions**: `/create prompt`, `/create command`, `/create agent`

**Meta-Prompting**: `/create-prompt`, `/run-prompt`

**Infrastructure**: `/audit-workflow`, `/heal-workflow`, `/workflow-health`

### Deployment Models (Auto-Detected)

- **staging-prod**: `/ship` (auto-detects staging → production flow)
- **direct-prod**: `/ship` (auto-detects direct deployment)
- **local-only**: `/build-local`

Detection: git remote + staging branch + `.github/workflows/deploy-staging.yml`

### Archived Commands

48 specialized commands archived in `.claude/commands/_archived/` (source-only).
NOT included in npm package - accessible via GitHub clone only.

All essential functionality available via 30 active commands.

For development/debugging: Clone GitHub repo to access archived commands.

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

### Continuous Quality Features (v10.16)

**Multi-Agent Voting** - Error decorrelation through diverse sampling:
- Code reviews: 3 agents, k=2 voting (MAKER algorithm)
- Security audits: Unanimous consensus required
- Breaking changes: 3 agents, k=2 for API compatibility
- Temperature variation (0.5, 0.7, 0.9) decorrelates errors
- Auto-fallback to single agent if voting unavailable
- Usage: `/review --voting` or automatic in `/optimize`

**Continuous Checks** - Lightweight validation after each task batch:
- Runs after 3-4 tasks during `/implement` phase
- Checks: linting (auto-fix), type checking, unit tests, coverage delta, dead code, gap detection
- Performance target: < 30 seconds total
- Non-blocking warnings, user decides: fix now, continue, or abort
- Skipped in iteration 2+ (focus on gaps only)

**Progressive Quality Gates** - Three levels throughout workflow:
```
Level 1 (Continuous)    → After each batch    → < 30s   → Warn & continue
Level 2 (Full)          → /optimize phase     → 10-15m  → Block deployment
Level 3 (Critical)      → /ship pre-flight    → < 2m    → Block production
```

**On-Demand Review** - Code review anytime:
- `/review` - Quick review of uncommitted changes
- `/review --voting` - 3-agent voting for high confidence
- `/review --scope all` - Review entire feature
- Auto-fix linting, show file:line references, generate coverage gaps

**Perpetual Learning** - Auto-apply proven patterns:
- Performance patterns (≥0.90 confidence) - auto-applied at workflow start
- Anti-patterns (≥0.85 confidence) - warnings issued
- Custom abbreviations (≥0.95 confidence) - auto-expanded
- CLAUDE.md tweaks (≥0.95 confidence) - queued for approval via `/heal-workflow`
- Collected from past workflows, applied at `/feature` and `/epic` start

**Early Gap Detection** - Find missing implementations before validation:
- Scans changed files for TODO, FIXME, placeholders, edge cases
- Runs during continuous checks (Check 6/6)
- Non-blocking warnings, saved to `.potential-gaps.yaml`
- High-confidence gaps (≥0.8) likely need fixes before deployment

Configuration: `.spec-flow/config/progressive-gates.yaml`, `.spec-flow/config/voting.yaml`

### Directory Structure

```
.claude/agents/           — Specialist briefs (load on-demand)
.claude/commands/         — 30 active slash commands
.claude/commands/_archived/ — 39 specialized commands (hidden from /help)
.claude/skills/           — Progressive disclosure content
.spec-flow/scripts/       — Automation scripts
.spec-flow/config/        — User preferences
specs/NNN-slug/           — Feature workspaces
epics/NNN-slug/           — Epic workspaces
docs/project/             — Project documentation
docs/references/          — Deep-dive documentation
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

### Design Token Compliance

**CRITICAL**: Never hardcode colors, spacing, or typography values.

**Universal Rules**:
1. **Colors**: Use OKLCH tokens from `design/systems/tokens.json`
   - Brand: `--brand-primary`, `--brand-secondary`
   - Semantic: `--semantic-success`, `--semantic-error`, `--semantic-warning`
   - Neutral: `--neutral-50` through `--neutral-950`
   - NEVER: `#hex`, `rgb()`, `hsl()` hardcoded values

2. **Spacing**: Use 8pt grid tokens only
   - Valid: `var(--space-4)`, Tailwind `p-4`, `gap-6`
   - NEVER: `padding: 17px`, `text-[15px]`, arbitrary `[Npx]` values

3. **Context-Aware Mapping** (when replacing grayscale):
   - Buttons/CTAs: gray -> `brand-primary`
   - Headings/Body: gray -> `neutral-900` (NOT brand)
   - Backgrounds: gray -> `neutral-50`
   - Feedback states: red/green -> `semantic-error`/`semantic-success`

**Validation**: Run `design-lint.js` before committing UI code.
**Quick Reference**: `docs/project/style-guide.md`

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
- [docs/developer-guide.md](docs/developer-guide.md) — Complete developer reference
- [CHANGELOG.md](CHANGELOG.md) — Version history

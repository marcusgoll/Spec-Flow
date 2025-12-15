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

**Project Setup**: `/init`, `/init --preferences`, `/init --tokens`, `/roadmap`, `/prototype`, `/constitution`

**Context Management**: `/context next`, `/context todos`, `/context add`

**Quality Gates**: `/gate ci`, `/gate sec`, `/fix-ci`

**Create Extensions**: `/create prompt`, `/create command`, `/create agent`

**Meta-Prompting**: `/create-prompt`, `/run-prompt`

**Deep Thinking**: `/ultrathink "problem"` (craftsman planning mode)

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

### Dry-Run Mode (v11.5+)

Test any command without making changes using `--dry-run`:

```bash
/feature "add auth" --dry-run    # Preview workspace creation and phases
/implement --dry-run              # Preview task execution and file changes
/ship --dry-run                   # Preview deployment operations
```

**Dry-run output shows:**
- Files that would be created/modified
- Agents that would be spawned
- Git operations that would occur
- State changes that would happen

**Use cases:**
- Testing new features before committing to workflow
- Debugging workflow issues safely
- CI/CD validation without side effects
- Training and demonstrations

**Skill reference**: `.claude/skills/dry-run/SKILL.md`

### Ultrathink → Roadmap Flow (v2.0)

Think deeply about problems, then materialize your thinking into actionable roadmap items.

**Flow:**
```
/ultrathink "notification system"    # Deep craftsman thinking
                │
                ▼
     Assumption Questioning
     Codebase Soul Analysis
     Architecture Sketching
     Feature Extraction
                │
                ▼
     "Would you like to add these to the roadmap?"
     [Add All] [Select] [Just Save] [Skip]
                │
                ▼
     GitHub Issues created with traceability
```

**Usage:**
```bash
/ultrathink "redesign notification system"     # Interactive mode
/ultrathink "new feature" --roadmap            # Auto-materialize to roadmap
/ultrathink "idea" --save                      # Save thinking, don't create issues
/roadmap from-ultrathink --list                # List saved ultrathink sessions
/roadmap from-ultrathink specs/ultrathink/notification.yaml  # Materialize later
```

**Output saved to**: `specs/ultrathink/[slug].yaml` with full thinking artifacts and extracted features.

**Skill reference**: `.claude/skills/ultrathink/SKILL.md`

### Studio Mode - Multi-Agent Isolation (v11.8)

Run multiple Claude Code instances in parallel, each with isolated git branches.

**Problem Solved**: When multiple agents work from the same git branch, they overwrite each other's changes. Studio mode gives each agent its own branch namespace.

**How it works**:
```bash
/studio init 3        # Create 3 agent worktrees
# In agent terminals:
cd worktrees/studio/agent-1 && claude
cd worktrees/studio/agent-2 && claude
cd worktrees/studio/agent-3 && claude
```

**Branch namespacing (automatic)**:
- Normal mode: `feature/001-auth`
- Studio mode: `studio/agent-1/feature/001-auth`

**No code changes needed** - existing `/feature`, `/epic`, `/quick` commands auto-detect studio context and namespace branches accordingly.

**Ship behavior in studio mode**:
- Always creates PR instead of direct merge
- PR targets `main` from namespaced branch
- Auto-merge via GitHub branch protection when CI passes
- Like a real dev team with code review gates

**Setup GitHub auto-merge** (one-time):
```bash
/studio setup         # Configure branch protection
```

**Commands**:
| Command | Purpose |
|---------|---------|
| `/studio init N` | Create N agent worktrees (1-10) |
| `/studio setup` | Configure GitHub for auto-merge |
| `/studio status` | Show agent worktrees and their work |
| `/studio stop` | Shutdown guidance |

**Scripts**: `.spec-flow/scripts/bash/worktree-context.sh studio-*`

### Worktree-First Safety Model (v11.8)

All implementation happens in isolated worktrees. Root is read-only orchestration.

**Protection levels** (configure in preferences):
- `strict` (default) - Block changes from root when active worktrees exist
- `prompt` - Ask user before allowing changes from root
- `none` - Allow changes anywhere (not recommended)

**How it works**:
```
ROOT (orchestration only)
├── Can: Read state, spawn Task() agents, update state.yaml
├── Cannot: Edit feature code directly when worktrees exist
│
└── WORKTREES (safe workspaces)
    ├── worktrees/feature/001-auth/  → Full read/write
    ├── worktrees/epic/002-payment/  → Full read/write
    └── Each feature/epic gets its own isolated worktree
```

**Automatic behaviors**:
- `/feature "desc"` from root → Creates worktree → Workers operate there
- `/feature continue` from root → Detects worktree → Prompts to switch
- `/finalize` → Cleans up worktree → Returns to root

**Preferences**:
```yaml
worktrees:
  auto_create: true              # Create worktrees automatically
  enforce_isolation: true        # Block direct edits from root
  root_protection: strict        # strict | prompt | none
  auto_switch_on_continue: true  # Prompt to switch on resume
  cleanup_on_finalize: true      # Remove worktree after completion
```

**Commands**:
```bash
worktree-context.sh check-safety    # Check if safe to make changes
worktree-context.sh find-active     # List active worktrees
worktree-context.sh get-worktree feature 001-auth  # Get worktree path
```

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

### Domain Memory v2 Agents

For implementation isolation (prevents context overflow):

- `.claude/agents/domain/initializer.md` — Initialize feature/epic domain memory
- `.claude/agents/domain/worker.md` — Implement ONE feature atomically, exit
- Skill: `.claude/skills/domain-memory/SKILL.md` — Boot-up ritual protocol

Pattern: Main orchestrator spawns isolated workers via Task(). Each worker reads `domain-memory.yaml`, picks ONE task, implements, updates disk, exits. No shared context between workers.

### Project Setup Agents (Hybrid Pattern)

For project initialization (questionnaire inline, generation isolated):

- `.claude/agents/project/init-project-agent.md` — Generate 8 project docs from cached answers
- `.claude/agents/project/prototype-discover-agent.md` — Create prototype screens from selections
- `.claude/agents/project/roadmap-brainstorm-agent.md` — Research feature ideas via web search

Pattern: Main runs questionnaire → saves to temp config → spawns agent → agent generates artifacts → main shows results.

### Phase Isolation Pattern

All workflow phases spawn isolated agents via Task():

- **Pre-implementation**: spec-agent, clarify-agent, plan-agent, tasks-agent
- **Implementation**: worker (Domain Memory v2 pattern, ONE task per spawn)
- **Post-implementation**: optimize-agent, validate-agent, ship-agent, finalize-agent

Benefits: Unlimited iterations without context overflow, deterministic behavior, resumable at any point.

### Semantic Search with mgrep

For code exploration and pattern discovery, prefer mgrep over Grep/Glob:

- **mgrep**: Semantic search — finds similar code by meaning, not exact text
- **Grep**: Literal/regex search — finds exact text patterns
- **Glob**: File pattern matching — finds files by name patterns

**When to use mgrep**:

- Finding similar implementations across domains
- Discovering patterns without knowing exact naming
- Understanding "how is X done" questions
- Anti-duplication checks before implementing new code

Example: `mgrep "components that display user details"` finds UserCard, ProfileView, AccountInfo, etc.

**Anti-duplication workflow**: Before implementing new code, always run mgrep to find existing patterns.

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

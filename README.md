<div align="center">
  <h1>Spec-Flow</h1>
  <p><strong>Ship features faster with AI-powered spec-driven development.</strong></p>

  <p>
    <a href="https://www.npmjs.com/package/spec-flow">
      <img src="https://img.shields.io/npm/v/spec-flow.svg?logo=npm&color=CB3837" alt="npm package">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/actions/workflows/ci.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/marcusgoll/Spec-Flow/ci.yml?branch=main" alt="CI Status">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/stargazers">
      <img src="https://img.shields.io/github/stars/marcusgoll/Spec-Flow?style=social" alt="GitHub Stars">
    </a>
  </p>
</div>

---

Spec-Flow is a workflow toolkit for [Claude Code](https://claude.ai/code) that transforms how you build software with AI. Instead of ad-hoc prompting, you get a structured pipeline that takes ideas from specification to production.

```
/feature "add user authentication"
```

That's it. Spec-Flow handles the rest: writing specs, planning architecture, breaking down tasks, implementing with TDD, running quality gates, and deploying.

## Why Spec-Flow?

| Without Spec-Flow | With Spec-Flow |
|-------------------|----------------|
| "What were we building again?" | Every decision tracked in NOTES.md |
| Features shipped without tests | TDD enforced, quality gates block bad code |
| Context bloat slows Claude down | Auto-compaction keeps context efficient |
| Each feature starts from scratch | Reusable patterns, proven workflows |
| "Did we test this? Who approved?" | Auditable artifacts for every phase |

## Quick Start

### 1. Install

```bash
npx spec-flow init
```

### 2. Build your first feature

```bash
/feature "add dark mode toggle"
```

Spec-Flow runs you through:

```
spec → plan → tasks → implement → optimize → ship
```

Each phase produces artifacts, runs quality checks, and hands off cleanly to the next.

### 3. That's it

Your feature is deployed. All decisions documented. Tests passing. Ready for the next one.

---

## The Workflow

### Features (< 16 hours)

For focused work on a single subsystem:

```bash
/feature "user profile editing"     # Start the workflow
/feature continue                   # Resume after a break
```

### Epics (> 16 hours)

For complex work spanning multiple subsystems:

```bash
/epic "OAuth 2.1 authentication"    # Multi-sprint orchestration
/epic continue                      # Resume epic work
```

Epics break down into parallel sprints with locked API contracts, giving you 3-5x velocity through parallelization.

### Quick fixes (< 30 min)

For small changes that don't need the full workflow:

```bash
/quick "fix login button alignment"
```

## Commands

### Core Workflow

| Command | What it does |
|---------|--------------|
| `/feature "name"` | Start a feature workflow |
| `/epic "goal"` | Start a multi-sprint epic |
| `/quick "fix"` | Fast path for small changes |
| `/help` | Context-aware guidance |

### Phase Commands

| Command | Phase |
|---------|-------|
| `/spec` | Generate specification |
| `/plan` | Create implementation plan |
| `/tasks` | Break down into TDD tasks |
| `/implement` | Execute tasks |
| `/optimize` | Run quality gates |
| `/ship` | Deploy to staging/production |

### Project Setup

| Command | What it does |
|---------|--------------|
| `/init-project` | Generate project documentation |
| `/init-preferences` | Configure workflow defaults |
| `/roadmap` | Manage features via GitHub Issues |

See [all 46 commands](docs/commands.md) in the full reference.

## How It Works

### 1. Specification Phase

```bash
/spec "user authentication"
```

Generates `spec.md` with:

- User scenarios in Gherkin format
- Functional and non-functional requirements
- Acceptance criteria
- Success metrics

### 2. Planning Phase

```bash
/plan
```

Creates `plan.md` with:

- Architecture decisions
- Component breakdown
- Code reuse opportunities
- Risk assessment

### 3. Task Breakdown

```bash
/tasks
```

Produces `tasks.md` with:

- 20-30 concrete implementation tasks
- TDD sequencing (Red → Green → Refactor)
- Dependency ordering
- Acceptance criteria per task

### 4. Implementation

```bash
/implement
```

Executes tasks with:

- Test-first development
- Specialist agents (backend, frontend, database)
- Parallel batch execution
- Automatic error recovery

### 5. Quality Gates

```bash
/optimize
```

Runs parallel checks:

- Performance benchmarks
- Security scanning
- Accessibility audits
- Code review
- Test coverage validation

### 6. Deployment

```bash
/ship
```

Handles:

- Staging deployment
- Validation checks
- Production promotion
- Rollback capability

## Project Structure

```
your-project/
├── .claude/
│   ├── commands/         # Slash commands
│   ├── agents/           # Specialist agent briefs
│   ├── skills/           # Progressive disclosure content
│   └── hooks/            # Event handlers
├── .spec-flow/
│   ├── scripts/          # Automation scripts
│   ├── config/           # User preferences
│   └── templates/        # Artifact templates
├── specs/
│   └── NNN-feature/      # Feature workspaces
├── epics/
│   └── NNN-epic/         # Epic workspaces
└── docs/
    └── project/          # Project documentation
```

## Using with Gemini CLI

Spec-Flow can be installed as a Gemini CLI extension to bring the same structured workflow to Gemini.

1. **Install**:

    ```bash
    # From within your project root
    npx spec-flow install-gemini-extension
    ```

    *Alternatively, run: `gemini extensions install .` inside your project.*

2. **Use**:
    The extension provides the same slash commands (`/feature`, `/plan`, etc.) directly within your Gemini CLI session.

    ```
    /feature "add user authentication"
    ```

3. **Skills & Agents**:
    The Gemini extension automatically adapts Spec-Flow's agents and skills to work within the Gemini environment, allowing you to leverage specialized personas like `backend-dev` or `git-workflow-enforcer`.

## Requirements

- **Claude Code** with slash command support
- **Git** 2.39+
- **Python** 3.10+
- **yq** 4.0+ for YAML processing

Windows users: Install [Git for Windows](https://git-scm.com/download/win) for full compatibility.

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Step-by-step tutorial |
| [Developer Guide](docs/developer-guide.md) | Complete reference |
| [Commands Reference](docs/commands.md) | All slash commands |
| [Architecture](docs/architecture.md) | System design |
| [Troubleshooting](docs/troubleshooting.md) | Common issues |

## Examples

See a complete feature workflow in [`specs/001-example-feature/`](specs/001-example-feature/):

- Full specification with requirements
- 28 tasks with acceptance criteria
- Performance benchmarks
- Release notes

## 🆕 Recent Updates

### v11.3.0 (December 2025)

**Git Worktree Integration** - Parallel development with isolated git state per feature/epic

- **worktree-context.sh**: Root orchestration utilities for worktree-based development
  - Automatic worktree creation for features/epics
  - Merge and cleanup functions for ship workflow
  - Task() agent context generation with cd-first pattern
- **Worktree-aware agents**: Worker agent supports isolated worktree execution
- **Command integration**: `/feature`, `/implement-epic`, `/ship` now create and manage worktrees
- **Enabled by default**: `worktrees.auto_create: true` - reduces merge conflicts ~90%

---

### v11.2.0 (December 2025)

**Automatic Regression Test Generation** - Bugs captured as tests to prevent recurrence

- **regression-test-generator skill**: Auto-generates framework-specific regression tests
  - Framework auto-detection (Jest, Vitest, pytest, Playwright)
  - Arrange-Act-Assert test structure with error ID references
  - Links tests back to error-log.md entries
- **Auto-invoke /debug on test failures**: When tests fail during `/implement`, `/debug` is automatically invoked
  - Generates regression test for the failure (Step 3.5)
  - Updates error-log.md with test reference
- **Continuous checks integration**: Check 7/7 triggers auto-debug on test failures

---

### v11.1.0 (December 2025)

**/quick Command - Task() Orchestrator Pattern** - Consistent architecture across all workflow commands

- **quick-worker agent**: Isolated agent for atomic quick change execution
  - Domain detection (backend/frontend/test/docs)
  - Test framework detection and execution
  - Style guide validation (UI changes)
  - Automatic commit with conventional message
- **Delimiter-based returns**: `---COMPLETED---`, `---NEEDS_INPUT---`, `---FAILED---`
- **Full Q&A support**: Test failure decisions batched to main context

---

### v11.0.0 (December 2025)

**Imperative Task() Architecture** - Commands now properly spawn isolated agents

- **Breaking Change**: `/feature` and `/epic` commands rewritten to use imperative Task() spawning
  - Phase agents now return structured delimiters (`---COMPLETED---`, `---NEEDS_INPUT---`, `---FAILED---`)
  - Questions batch to main context - agents return questions, main asks user, re-spawns with answers
  - Parallel sprint execution for epics via `run_in_background: true`
- **Ultra-lightweight Orchestrator Pattern**
  - Read state from disk, spawn isolated agents, handle Q&A, update state
  - Never carry implementation details in context
  - Unlimited feature/epic complexity (no context overflow)
- **Updated Agents**:
  - `spec-agent.md`, `plan-agent.md`: Delimiter-based return format
  - `worker.md`: WORKER_COMPLETED, WORKER_FAILED, ALL_DONE, BLOCKED delimiters
  - `initializer.md`: INITIALIZED, INIT_FAILED delimiters

---

### v10.17.0 (December 2025)

**Domain Memory v2 - Full Phase Isolation** - Revolutionary architecture preventing context overflow

- **Domain Memory System** - Persistent disk-based state for unlimited iterations
  - Workers pick ONE task, implement, test, update disk, exit
  - Zero shared context between workers (prevents overflow)
  - 13-command CLI for state management
- **Phase Isolation Pattern** - All phases spawn isolated agents via Task()
  - Question batching: agents return questions, main asks user, agents resume
  - Resumable at any point via interaction-state.yaml
- **Project Setup Agents** - Hybrid pattern for /init-project, /prototype, /roadmap
  - Questionnaire inline, heavy generation isolated
- **mgrep Semantic Search** - Find code by meaning, not exact text
  - Integrated as PRIMARY search in anti-duplication skill
  - Added to agent boot-up rituals

---

### v10.16.0 (December 2025)

**Quality Feedback Loop System** - Multi-agent voting, continuous checks, and perpetual learning

- **Multi-Agent Voting** - Error decorrelation through diverse sampling (MAKER algorithm)
  - 3-agent voting with k=2 strategy for code reviews, security audits, breaking changes
  - Temperature variation (0.5, 0.7, 0.9) decorrelates errors across agents
  - Automatic in `/optimize` phase, manual via `/review --voting`
- **Continuous Quality Checks** - Lightweight validation during `/implement` phase
  - Runs after each task batch (3-4 tasks), < 30s performance target
  - 6 checks: linting (auto-fix), type checking, unit tests, coverage delta, dead code, gap detection
  - Non-blocking warnings with user choice: fix now, continue, or abort
- **Progressive Quality Gates** - Three escalating levels throughout workflow
  - Level 1: Continuous (after each batch, < 30s, warn & continue)
  - Level 2: Full quality gates (`/optimize` phase, 10-15m, block deployment)
  - Level 3: Critical pre-flight (`/ship`, < 2m, block production)
- **On-Demand Review** - New `/review` command for anytime code review
  - Quick review (single agent, ~2-3 min) or comprehensive voting review (3 agents, ~5-8 min)
  - Auto-fix linting, extract file:line references, generate coverage gaps
- **Perpetual Learning** - Auto-apply proven patterns at workflow start
  - Performance optimizations (≥0.90 confidence) auto-applied
  - Anti-patterns (≥0.85 confidence) generate warnings
  - Custom abbreviations (≥0.95 confidence) auto-expanded
- **Early Gap Detection** - Find missing implementations before staging validation
  - Scans for TODO/FIXME/HACK comments, placeholders, edge cases
  - High-confidence gaps (≥0.8) flag likely issues before deployment

---

### v10.15.1 (December 2025)

**Command Architecture Optimization** - Cleaner package structure with 27% size reduction

- **Consolidated Commands**: Merged 11 archived commands into 4 active commands
  - `/gate` now handles both CI and security gates
  - `/create` consolidated 6 creation commands
  - `/context` merged session management commands
  - `/init` updated routing to new active paths
- **Optimized Distribution**: Excluded 48 archived commands from npm package
  - Package size: 8.5 MB → 6.27 MB (27% reduction)
  - Archived commands accessible via GitHub source only
  - All essential functionality in 30 active commands
- **Moved Essential Commands**: Project, deployment, and meta commands organized in active directories

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">
  <p>Built by <a href="https://x.com/marcusgoll">@marcusgoll</a></p>
  <p>
    <a href="https://github.com/marcusgoll/Spec-Flow/issues">Report a bug</a> ·
    <a href="https://github.com/marcusgoll/Spec-Flow/discussions">Ask a question</a> ·
    <a href="https://github.com/marcusgoll/Spec-Flow/stargazers">Star on GitHub</a>
  </p>
</div>

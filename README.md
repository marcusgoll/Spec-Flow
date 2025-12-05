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

<div align="center">
  <h1>Spec-Flow Workflow Kit</h1>
  <p><em>Build high-quality features faster with repeatable Claude workflows.</em></p>

  <p>
    <a href="https://github.com/marcusgoll/Spec-Flow/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/actions/workflows/ci.yml">
      <img src="https://img.shields.io/github/actions/workflow/status/marcusgoll/Spec-Flow/ci.yml?branch=main" alt="CI Status">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/releases">
      <img src="https://img.shields.io/github/v/release/marcusgoll/Spec-Flow" alt="Latest Release">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/issues">
      <img src="https://img.shields.io/github/issues/marcusgoll/Spec-Flow" alt="GitHub Issues">
    </a>
    <a href="https://github.com/marcusgoll/Spec-Flow/stargazers">
      <img src="https://img.shields.io/github/stars/marcusgoll/Spec-Flow?style=social" alt="GitHub Stars">
    </a>
  </p>
</div>

<p align="center">
  <strong>An open toolkit that turns product ideas into production launches through Spec-Driven Development.</strong>
</p>

<div align="center">
  <p>
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-why-spec-flow">Why Spec-Flow?</a> •
    <a href="docs/getting-started.md">Tutorial</a> •
    <a href="docs/architecture.md">Architecture</a> •
    <a href="#-examples">Examples</a> •
    <a href="#-contributing">Contributing</a>
  </p>
</div>

---

## Table of Contents

- [What is Spec-Driven Development?](#what-is-spec-driven-development)
- [Get Started](#get-started)
- [Supported AI Agents](#supported-ai-agents)
- [Script Reference](#script-reference)
- [Core Philosophy](#core-philosophy)
- [Development Phases](#development-phases)
- [Prerequisites](#prerequisites)
- [Learn More](#learn-more)
- [Detailed Process](#detailed-process)
- [Troubleshooting](#troubleshooting)
- [Maintainers](#maintainers)
- [License](#license)

## 🌟 Why Spec-Flow?

Building software with AI assistants is powerful, but without structure, projects drift. You lose context, forget decisions, skip testing, and ship inconsistent features. **Spec-Flow solves this.**

### The Problem Without Spec-Flow

| Challenge | Without Spec-Flow | With Spec-Flow |
|-----------|-------------------|----------------|
| **Context Loss** | "What were we building again?" after interruptions | NOTES.md tracks all decisions, checkpoints restore context instantly |
| **Inconsistent Quality** | Features shipped without tests, reviews vary | Every feature follows same rigorous process: spec → plan → implement → review → ship |
| **Token Waste** | Conversations balloon to 100k+ tokens, Claude slows down | Auto-compaction at 80% budget keeps context efficient (75k/100k/125k per phase) |
| **No Accountability** | "Did we test this? Who approved?" | Auditable artifacts for every phase, approval gates enforced |
| **Reinventing Process** | Each feature starts from scratch | Reusable templates, proven patterns, documented workflows |

### What You Get

✅ **Repeatable Process** - Every feature follows the same proven workflow (spec → plan → tasks → ship)

✅ **Context Discipline** - Token budgets enforced per phase, auto-compaction prevents context bloat

✅ **Quality Gates** - Automated checks for accessibility, performance, testing, security

✅ **Auditable Trail** - Every decision documented in NOTES.md, every phase produces artifacts

✅ **Faster Velocity** - Skip decision paralysis, let the workflow guide you

✅ **Team Alignment** - Specs reviewed upfront, parallel work enabled, consistent outcomes

### Use Cases

- **Web Apps** - Full-stack features with frontend + backend coordination
- **APIs** - Contract-first development with automated testing
- **CLIs** - Command structure definition to distribution
- **Mobile Apps** - Offline-first architecture with platform-specific handling
- **Design Systems** - Component libraries with accessibility built-in
- **Infrastructure** - Terraform modules with security scanning
- **ML Projects** - Experiment tracking with reproducible pipelines

👉 **See more**: [Use Cases](docs/use-cases.md)

---

## What is Spec-Driven Development?

Spec-Driven Development flips the traditional model: specifications become executable assets that orchestrate planning, implementation, QA, and release. Each Claude command owns a phase of delivery, produces auditable artifacts, and tees up the next specialist.

### The Workflow

```
💡 Ideas → 🗺️ Roadmap → 📝 Spec → 📋 Plan → ✅ Tasks → 🔍 Analyze →
💻 Implement → ⚡ Optimize → 👀 Preview → 🚀 Staging → ✅ Validate → 🎉 Production
```

**Key Principle**: Plan your roadmap first, then write specifications from prioritized features, and let AI agents execute faithfully.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/marcusgoll/Spec-Flow.git
cd Spec-Flow

# 2. Configure Claude Code permissions
cp .claude/settings.example.json .claude/settings.local.json
# Edit .claude/settings.local.json and add your project paths

# 3. Verify prerequisites
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json
# OR (macOS/Linux)
.spec-flow/scripts/bash/check-prerequisites.sh --json

# 4. Plan your roadmap (add features and prioritize)
# In Claude Code:
/roadmap

# 5. Build a feature from your roadmap
/spec-flow "dark-mode-toggle"  # References roadmap entry
/plan
/tasks
/implement
# ... follow the workflow phases
```

**Next**: Follow the [**Getting Started Tutorial**](docs/getting-started.md) for a step-by-step walkthrough.

---

## Get Started

### 1. Install the toolkit

Clone this repository and ensure you have either PowerShell 7.3+ (`pwsh`) or a POSIX shell (`bash`) plus Python 3.10+ available. Scripts live under `.spec-flow/scripts/powershell/` and `.spec-flow/scripts/bash/`.

**Full installation guide**: [docs/installation.md](docs/installation.md)

Copy `.claude/settings.example.json` to `.claude/settings.local.json` and update the allow list for your environment.

### 2. Establish principles

Run the `/constitution` command in Claude to document the engineering principles that guard every feature. Store the output in `.spec-flow/memory/constitution.md`.

### 3. Build your roadmap

Use `/roadmap` to add features, prioritize them with ICE scoring (Impact × Confidence / Effort), and organize them into:
- **Backlog** - Ideas to consider
- **Next** - Top 5-10 prioritized features
- **In Progress** - Currently being built
- **Shipped** - Completed features

### 4. Kick off a feature

Select a feature from your roadmap and use `/spec-flow "<feature-slug>"` to initiate the workflow. Follow with `/plan`, `/tasks`, `/implement`, and the remaining commands until `/phase-2-ship` completes.

For a fully automated pass, use `/flow "<feature-slug>"` to step through the entire state machine with manual gates for approvals.

## Supported AI Agents

| Agent | Status | Notes |
|-------|--------|-------|
| Claude Code | Supported | Optimised for slash-command workflow. |
| Cursor | Supported | Pair with `.spec-flow/memory/` context files. |
| Windsurf | Supported | Share roadmap + constitution for planning. |
| GitHub Copilot | Partial | Works for code edits; manual command execution. |
| Gemini CLI | Experimental | Requires manual prompt translation. |

## Script Reference

Every automation script is provided in both PowerShell (`.ps1`) and shell (`.sh`) form. Pick the variant that matches your environment.

| Task | Windows / Cross-platform | macOS / Linux |
|------|--------------------------|---------------|
| Validate prerequisites | `pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json` | `.spec-flow/scripts/bash/check-prerequisites.sh --json` |
| Scaffold a feature | `pwsh -File .spec-flow/scripts/powershell/create-new-feature.ps1 "Dashboard revamp"` | `.spec-flow/scripts/bash/create-new-feature.sh "Dashboard revamp"` |
| Estimate token budget | `pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/015-dashboard` | `.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/015-dashboard` |
| Compact context | `pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 -FeatureDir specs/015-dashboard` | `.spec-flow/scripts/bash/compact-context.sh --feature-dir specs/015-dashboard` |

> Additional scripts such as `enable-auto-merge`, `wait-for-ci`, and `update-agent-context` also ship with `.sh` wrappers that delegate to PowerShell so you can run them from a POSIX shell while we build native equivalents.

## Core Philosophy

1. **Specification first**  every artifact traces back to an explicit requirement.
2. **Agents as teammates**  commands encode expectations so assistants stay aligned.
3. **Context discipline**  token budgets are measured, compacted, and recycled.
4. **Ship in stages**  staging and production have dedicated rituals with human gates.

## Development Phases

| Phase | Command | Primary Outputs |
|-------|---------|-----------------|
| -1 | `/roadmap` | `roadmap.md` with ICE-scored features |
| 0 | `/spec-flow` | `spec.md`, `NOTES.md`, `visuals/README.md` |
| 0.5 | `/clarify` | Clarification log inside the spec |
| 1 | `/plan` | `plan.md`, `research.md` |
| 2 | `/tasks` | `tasks.md` with acceptance criteria |
| 3 | `/analyze` | Risk analysis report |
| 4 | `/implement` | Implementation checklist & validation hooks |
| 5 | `/optimize` | Code review summary & optimization plan |
| 6 | `/debug` | Error triage and remediation plan |
| 7 | `/preview` | Release notes & preview checklist |
| 8 | `/phase-1-ship` | Staging deployment ritual |
| 9 | `/validate-staging` | Sign-off for staging |
| 10 | `/phase-2-ship` | Production launch and follow-up |

## Prerequisites

- Git 2.39+
- Python 3.10+
- PowerShell 7.3+ (`pwsh`) for Windows scripts
- Bash 5+ (or Zsh) for shell scripts
- Claude Code access with slash-command support

Optional:
- GitHub CLI (`gh`) for auto-merge helpers
- Pester 5 for PowerShell test suites

## 📚 Examples

### Complete Working Example: Dark Mode Toggle

Explore a fully-documented feature workflow in [`specs/001-example-feature/`](specs/001-example-feature/):

```
specs/001-example-feature/
├── spec.md                    # Feature specification with user scenarios
├── NOTES.md                   # Progress tracking and decisions
├── artifacts/
│   ├── plan.md                # Implementation plan with architecture
│   ├── tasks.md               # 28 tasks with acceptance criteria
│   ├── analysis-report.md     # Risk assessment (0 critical issues)
│   ├── optimization-report.md # Performance metrics (145ms avg)
│   └── release-notes.md       # v1.2.0 release notes
└── visuals/
    └── README.md              # Design references and color tokens
```

**What's included**:
- Complete specification with FR/NFR requirements
- 28 tasks broken down across 5 implementation phases
- Performance benchmarks (27% better than target)
- WCAG 2.1 AA accessibility compliance
- Cross-browser testing matrix
- Release notes for v1.2.0

👉 **Browse the example**: [`specs/001-example-feature/`](specs/001-example-feature/)

---

## Learn More

- [`docs/architecture.md`](docs/architecture.md) — how the repository fits together
- [`docs/commands.md`](docs/commands.md) — quick lookup for every slash command
- [`docs/getting-started.md`](docs/getting-started.md) — step-by-step tutorial for your first feature
- [`docs/installation.md`](docs/installation.md) — platform-specific installation guide
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — common issues and solutions
- [`docs/use-cases.md`](docs/use-cases.md) — examples for different project types
- [`AGENTS.md`](AGENTS.md) — contributor guide for working in this repo
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — branching, reviews, and release process

## Detailed Process

1. Run `.spec-flow/scripts/bash/check-prerequisites.sh --json` (or the PowerShell variant) to ensure your environment is ready.
2. Build your roadmap with `/roadmap` - add features, prioritize with ICE scoring, and organize into Backlog → Next → In Progress → Shipped.
3. Select a feature from the roadmap and launch `/spec-flow "<feature-slug>"` in Claude to scaffold the spec from the roadmap entry.
4. Progress through `/clarify`, `/plan`, `/tasks`, and `/analyze`, addressing blockers as they appear.
5. Use `calculate-tokens` to watch context budgets and `compact-context` to summarise when approaching thresholds.
6. Walk the release staircase: `/preview`, `/phase-1-ship`, `/validate-staging`, `/phase-2-ship`.
7. The feature automatically moves to "Shipped" in the roadmap, and changelog is updated with the release.

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `pwsh` command not found | Install PowerShell 7 (`winget install Microsoft.PowerShell` or `brew install --cask powershell`). |
| Shell script reports missing feature directory | Run `/spec-flow` first or use `create-new-feature` to scaffold `specs/NNN-slug`. |
| Token estimate returns zero | Verify files are UTF-8 encoded and not empty. |
| Context delta lacks checkpoints | Ensure `NOTES.md` records checkpoints prefixed with `-`. |

## Maintainers

- Marcus Gollahon (@marcusgoll)
- Community contributors  join via pull requests!

## License

Released under the [MIT License](LICENSE).




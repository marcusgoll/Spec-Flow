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
    <a href="https://www.npmjs.com/package/spec-flow">
      <img src="https://img.shields.io/npm/v/spec-flow.svg?logo=npm&color=CB3837" alt="npm package">
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

## 🆕 Recent Updates

### v1.11.1 (October 2024)
**Folder Cleanup Refactor** - Cleaner spec directories with on-demand folder creation

- **Eliminated empty folders**: Removed blanket directory pre-creation from `/specify` command
- **On-demand creation**: Folders (`visuals/`, `design/`) now created only when files are written
- **Benefits**: Cleaner spec directories, easier to identify UI features, follows YAGNI principle
- **Files modified**: `.claude/commands/specify.md`

### v1.11.0 (October 2024)
**Phase-Specific Learning Skills** - Workflow improvement tracking

- Added learning Skills for each workflow phase (spec, plan, tasks, implement, optimize, ship, etc.)
- Auto-triggers on workflow events to capture lessons and improve future iterations
- Skills track common issues: clarification overload, test failures, deployment blockers

[View all releases →](https://github.com/marcusgoll/Spec-Flow/releases)

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
- [Packages & Releases](#packages--releases)
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

### 🚀 New: Optimized Phase Agent Architecture (v1.5.0)

Spec-Flow now features an **optimized orchestrator** (`/spec-flow`) that runs each workflow phase in isolated contexts for maximum efficiency:

**Benefits:**
- ⚡ **67% Token Reduction** - Each phase runs in isolated context (240k → 80k tokens per feature)
- 🏃 **2-3x Faster** - No cumulative context bloat, no /compact overhead between phases
- ✅ **Same Quality** - All slash commands unchanged, proven workflow maintained
- 🔄 **Easy Rollback** - Original `/flow` command available as backup

**How it works:**
```
/spec-flow (Orchestrator - Lightweight State Tracking)
  ├→ spec-phase-agent → /specify → Returns summary
  ├→ plan-phase-agent → /plan → Returns summary
  ├→ tasks-phase-agent → /tasks → Returns summary
  ├→ /implement → Spawns worker agents directly (bypasses phase agent*)
  └→ ... (each phase isolated, efficient handoffs)

  * Phase 4 calls /implement directly due to sub-agent spawning limits
```

**Choose your workflow:**
- **`/spec-flow "feature"`** - New optimized workflow (recommended)
- **`/flow "feature"`** - Original workflow (backup/fallback)
- **`/quick "fix"`** - Fast path for small changes (<100 LOC)

## 🚀 Quick Start

### Option 1: NPM (Recommended)

Install Spec-Flow with a single command:

```bash
# Initialize in current directory
npx spec-flow init

# Or\spec-flow target directory
npx spec-flow init --target ./my-project
```

### Option 2: Manual Installation

Clone and run the interactive wizard:

```bash
# 1. Clone Spec-Flow repository
git clone https://github.com/marcusgoll/Spec-Flow.git
cd Spec-Flow

# 2. Run the installation wizard (Windows)
powershell -File .spec-flow/scripts/powershell/install-wizard.ps1

# OR (macOS/Linux)
./.spec-flow/scripts/bash/install-wizard.sh
```

**What gets installed:**
- ✅ `.claude/` - Agents, commands, and settings
- ✅ `.spec-flow/` - Scripts, templates, and memory
- ✅ `CLAUDE.md` - Workflow documentation
- ✅ `QUICKSTART.md` - Quick start guide (copied to your project)
- ✅ Memory files initialized with defaults

**Next steps after installation:**

1. **Read the guide** - Open `QUICKSTART.md` in your project
2. **Open in Claude Code** - Navigate to your project directory
3. **Set up your project** (optional but recommended):
   ```bash
   /constitution         # Interactive Q&A for engineering standards
   /roadmap              # Plan and prioritize features with ICE scoring
   /design-inspiration   # Curate visual references for consistency
   ```
4. **Start building:**
   ```bash
   /spec-flow "my-feature"  # Optimized workflow (recommended)
   /flow "my-feature"       # Original workflow (backup)
   /quick "fix bug"         # Fast path for small changes
   ```

👉 **Full guide**: [QUICKSTART.md](QUICKSTART.md) | **Detailed tutorial**: [Getting Started](docs/getting-started.md)

---

## Get Started

### 1. Install the toolkit

**From npm (fastest):**

```bash
npm install -g spec-flow
# or use npx without a global install
npx spec-flow init --target ./my-project
```

**From source:**

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

Select a feature from your roadmap and choose your workflow:

**Optimized workflow (recommended):**
```bash
/spec-flow "feature-name"  # Runs full workflow with isolated phase agents
# Auto-progresses through: spec → plan → tasks → analyze → implement → optimize → ship
# Pauses at manual gates: /preview, /validate-staging
# Use: /spec-flow continue (to resume after manual gates)
```

**Original workflow (backup):**
```bash
/flow "feature-name"  # Traditional workflow with cumulative context
```

**Manual step-by-step:**
```bash
/specify "feature-name"  # Create specification
/plan                    # Create plan
/tasks                   # Break down tasks
/implement              # Execute implementation
# ... continue through remaining phases
```

## Supported AI Agents

| Agent | Status | Notes |
|-------|--------|-------|
| Claude Code | Supported | Optimised for slash-command workflow. |
| Cursor | Supported | Pair with `.spec-flow/memory/` context files. |
| Windsurf | Supported | Share roadmap + constitution for planning. |
| GitHub Copilot | Partial | Works for code edits; manual command execution. |
| Gemini CLI | Experimental | Requires manual prompt translation. |

## Skills & Learning System

Spec-Flow includes an auto-learning system that captures lessons from each workflow phase to continuously improve your process.

### How Skills Work

**16 Phase-Specific Skills**: Each workflow phase has a dedicated skill that learns from execution:
- `.claude/skills/specification-phase/` - Learn from /specify (reduce clarifications, improve classification)
- `.claude/skills/planning-phase/` - Learn from /plan (maximize code reuse, detect patterns)
- `.claude/skills/implementation-phase/` - Learn from /implement (TDD enforcement, anti-duplication)
- `.claude/skills/ui-ux-design/` - Learn from design workflow (Jobs principles, a11y compliance)
- ...and 12 more for other phases

**Two-File Architecture**:
1. **SKILL.md** - Template with pitfall descriptions, detection logic, prevention strategies (updated with npm)
2. **learnings.md** - Accumulated data with frequencies, metrics, instances (preserved across updates)

### Learnings Persistence

When you update Spec-Flow via npm, your accumulated learnings are preserved:

**What Gets Updated** (npm overwrites):
- `SKILL.md` - Template improvements, new pitfalls, better detection logic
- `.claude/commands/*.md` - Command improvements, new features
- `.spec-flow/templates/*.md` - Artifact templates

**What Gets Preserved** (your local data):
- `learnings.md` - Pitfall frequencies, pattern usage counts, metrics
- `.spec-flow/memory/roadmap.md` - Your product roadmap
- `.spec-flow/memory/constitution.md` - Your project principles
- `specs/*/` - All your feature specifications

**Example**: After 10 features, your `learnings.md` shows:
```yaml
common_pitfalls:
  - id: "over-clarification"
    frequency: 2/5 ⭐⭐☆☆☆
    last_seen: "2025-01-15"
    instances: [feature-001, feature-007]

successful_patterns:
  - id: "informed-guess-strategy"
    usage_count: 8
    success_rate: 87.5%
```

This data persists across npm updates, so your workflow gets smarter over time.

### Auto-Learning in Action

**Skills auto-trigger** when:
- Starting a phase (loads relevant lessons)
- Completing a phase (detects pitfalls, updates frequencies)
- Encountering errors (captures patterns for prevention)

**Skills auto-update** when:
- Pitfall detected: Increments frequency (0/5 → 1/5 → 2/5 ★★☆☆☆)
- Pattern used successfully: Increments usage count, recalculates success rate
- Metrics updated: Averages recalculated after each feature

**No manual intervention required** - the system learns as you work.

---

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
| 0 | `/specify` | `spec.md`, `NOTES.md`, `visuals/README.md` |
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
| - | `/compact [phase]` | **Optional:** Reduce token usage between phases |

**Context Management**: The `/compact` command is optional and reduces token usage by summarizing verbose artifacts. Use it between phases when context feels heavy or when suggested by auto-progression. In `/flow` mode, compaction happens automatically.

## Prerequisites

- Git 2.39+
- Python 3.10+
- PowerShell 7.3+ (`pwsh`) for Windows scripts
- Bash 5+ (or Zsh) for shell scripts
- Claude Code access with slash-command support
- **yq 4.0+** for YAML state management:
  - macOS: `brew install yq`
  - Linux: See [mikefarah/yq releases](https://github.com/mikefarah/yq/releases)
  - Windows: `choco install yq`
- PowerShell-yaml module for PowerShell scripts:
  - `Install-Module -Name powershell-yaml -Scope CurrentUser`

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
- [`PUBLISHING.md`](PUBLISHING.md) — release checklist for npm & GitHub Packages
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

## Packages & Releases

- **npm**: Published as [`spec-flow`](https://www.npmjs.com/package/spec-flow). Install globally with `npm install -g spec-flow` or run one-off with `npx spec-flow`.
- **GitHub Packages**: The `Publish Packages` workflow mirrors each release to GitHub Packages under the scoped name `@marcusgoll/spec-flow`, enabling the repository's *Packages* tab.
- **Automation**: Creating a GitHub release (or manually running the workflow) triggers the dual publish. Set the `NPM_TOKEN` repository secret with an npm automation token that has `publish` rights; GitHub packages use the built-in `GITHUB_TOKEN`.

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `pwsh` command not found | Install PowerShell 7 (`winget install Microsoft.PowerShell` or `brew install --cask powershell`). |
| Shell script reports missing feature directory | Run `/spec-flow` first or use `create-new-feature` to scaffold `specs/NNN-slug`. |
| Token estimate returns zero | Verify files are UTF-8 encoded and not empty. |
| Context delta lacks checkpoints | Ensure `NOTES.md` records checkpoints prefixed with `-`. |

## Maintainers

* Marcus Gollahon ([@marcusgoll](https://x.com/marcusgoll))
- Community contributors  join via pull requests!

## License

Released under the [MIT License](LICENSE).





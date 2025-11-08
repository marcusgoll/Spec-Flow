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
---

## 🆕 Recent Updates

### v4.0.0 (November 2025)
**Living Documentation** - Hierarchical CLAUDE.md files with automatic updates

- **Hierarchical Context Navigation**: 3-level CLAUDE.md hierarchy (root → project → feature)
  - **Root CLAUDE.md**: Workflow system documentation (~3,000 tokens)
  - **Project CLAUDE.md**: Active features, tech stack summary, common patterns (~2,000 tokens)
  - **Feature CLAUDE.md**: Current progress, velocity, relevant specialists (~500 tokens)
- **Automatic Updates**: Documentation updates atomically with code changes
  - Feature CLAUDE.md: Generated on `/feature`, refreshed on task completion
  - Project CLAUDE.md: Generated on `/init-project`, updated on `/ship`
  - Living artifact sections: spec.md (Implementation Status), plan.md (Discovered Patterns), tasks.md (Progress Summary)
- **Velocity Tracking**: Real-time metrics (avg time/task, completion rate, ETA, bottlenecks)
- **Health Checks**: Detect stale CLAUDE.md files (`.spec-flow/scripts/bash/health-check-docs.sh`)
- **Token Efficiency**: 80-94% reduction in context loading
  - Start new feature: 12,700 → 2,500 tokens (80% reduction)
  - Resume existing feature: 8,000 → 500 tokens (94% reduction)

**Problem Solved**: Traditional documentation becomes stale within weeks, requiring manual synchronization. Reading all project documentation consumes 12,000+ tokens, slowing AI context loading. No visibility into implementation velocity or bottlenecks.

**Impact**: Documentation never lags behind code (atomic updates during workflow). Context loading is 80-94% faster. Always know velocity, ETA, and blockers without manual tracking.

**See**: [docs/LIVING_DOCUMENTATION.md](docs/LIVING_DOCUMENTATION.md) for complete guide

---

### v3.2.0 (November 2025)
**Planning Optimization** - 50-60% faster feature planning with docs/project integration

- **Mandatory Project Docs Integration**: `/plan` now parses `docs/project/` files for instant context
  - Tech stack (tech-stack.md): Framework, backend, database, styling, state management
  - Data architecture (data-architecture.md): Existing entities, naming conventions
  - API strategy (api-strategy.md): API style, auth provider, versioning, error format
  - Performance targets (capacity-planning.md): Scale tier, response time targets
  - Architecture (system-architecture.md): Monolith/microservices/serverless
  - Deployment (deployment-strategy.md): Platform and model
- **Research Phase Optimization**: 5-15 tools → 2-5 tools (with project docs)
  - Eliminates: Codebase scanning for stack detection, API pattern inference, entity discovery
  - Preserves: Component reuse scanning, feature-specific research
- **Freshness Validation**: Compares docs to code, warns if mismatch detected
- **Enhanced research.md**: Project Context section shows parsed values from all 8 docs
- **Time Savings**: 4-8 minutes per feature, 3-4 hours per project (30 features)

**Problem Solved**: Before v3.2.0, `/plan` re-researched information already documented in `docs/project/`, leading to slower planning and potential tech stack hallucination. No integration with `/init-project` output.

**Impact**: Planning phase is 50-60% faster (8-15 min → 4-7 min). Zero tech stack hallucination. Consistent architecture across all features. Clear attribution of decisions to source docs. Better designs that respect performance targets and scale tier.

---

### v3.1.0 (November 2025)
**OKLCH Color Space Upgrade** - Perceptually uniform design tokens

- **OKLCH Color Space**: Upgraded `/init-brand-tokens` to generate OKLCH colors
  - 92% browser support with automatic sRGB fallback
  - Perceptually uniform lightness across all hues
  - Wide gamut support (P3 color space, 50% more colors than sRGB)
- **Semantic Token Structure**: Replaced DEFAULT/light/dark with explicit bg/fg/border/icon tokens
  - Eliminates "ink vs paint" confusion
  - Automated WCAG AAA (7:1) contrast validation using colorjs.io
- **New Token Categories**: Focus (WCAG 2.2), Motion (reduced-motion), Data viz (Okabe-Ito colorblind-safe), Typography features, Dark mode shadows (3-6x opacity)
- **Design Principles**: Comprehensive OKLCH documentation and best practices
- **Added dependency**: colorjs.io ^0.5.0 for OKLCH conversion and WCAG validation

**Problem Solved**: v1.0.0 used RGB colors with false WCAG claims (e.g., claimed 7.8:1 but actually 5.70:1). No semantic token structure caused "ink vs paint" confusion. Missing critical tokens for focus, motion, and accessibility.

**Impact**: Perceptually uniform colors with accurate WCAG validation. Clear semantic meaning for every token. WCAG 2.2 compliant focus indicators. Colorblind-safe data visualization. Proper dark mode depth perception.

---

### v3.0.1 (November 2025)
**Package Fix** - Added missing design commands to npm

- **Fixed npm package**: Added missing design workflow commands
  - `/init-brand-tokens` - Smart brand token initialization
  - `/design` - Unified design orchestrator (Variations → Functional → Polish)
  - `/research-design` - Multi-source design inspiration gathering
  - `/update-project-config` - Project configuration updates (was missing after rename)
- **Removed deprecated**: Removed old `setup-constitution` reference

**Problem Solved**: v2.12.0 introduced comprehensive design workflow commands, but they were accidentally excluded from the npm package files list. Users who installed via npm couldn't access these commands.

**Impact**: Design workflow is now fully available in npm package. Users can initialize brand tokens, run design workflows, and configure projects without cloning the repo.

---

### v3.0.0 (November 2025)
**Constitution Cleanup** - Simplified project structure and documentation

- **BREAKING CHANGE**: Constitution file structure reorganized
  - Split monolithic `constitution.md` into 3 focused files:
    - `docs/project/engineering-principles.md` - User-editable 8 core engineering principles
    - `docs/project/project-configuration.md` - User-editable deployment model and scale tier settings
    - `.spec-flow/memory/workflow-mechanics.md` - Workflow system mechanics (roadmap, versioning, quality gates)
- **Enhanced /init-project**: Now generates 10 comprehensive docs (was 8)
- **Renamed Commands**: `/setup-constitution` → `/update-project-config` (76% size reduction: 862→207 lines)
- **Roadmap Integration**: `/roadmap brainstorm` now reads tech-stack.md and capacity-planning.md for technically grounded features
- **Greenfield Support**: Automatic foundation issue creation for new projects
- **Fixed Broken References**: Updated all commands to reference new file structure

**Problem Solved**: Before v3.0.0, constitution.md was a monolithic 609-line file mixing user project settings with workflow system mechanics. Confusing dual-constitution naming (`constitution.md` vs `setup-constitution.md`). Roadmap brainstorming didn't consider technical constraints.

**Impact**: Clear separation of concerns - user files vs workflow files. Smaller, focused files easier to maintain. Foundation setup automated for greenfield projects. Features are technically validated from brainstorming phase.

---

### v2.12.0 (November 2025)
**S-Tier Design Workflow** - Complete UI/UX design system without Figma

- **Three-Phase Pipeline**: `/design` orchestrator chains Variations → Functional → Polish with human approval gates
- **Token-Based Design System**: Smart initialization with brownfield/greenfield detection via `/init-brand-tokens`
- **Automated Validation**: `design-lint.js` enforces principles (elevation scale, 2:1 hierarchy, subtle gradients, token compliance)
- **Comprehensive Handoff**: `implementation-spec.md` (26KB) provides pixel-perfect component breakdown, interactions, accessibility, testing strategy
- **Usability Evaluation**: `dont-make-me-think-checklist.md` with 130 checkpoints across 10 categories (visual clarity, navigation, content, interactions, feedback, cognitive load, conventions, error prevention, mobile, accessibility)
- **Brownfield Scanner**: Analyzes existing codebases to detect and consolidate design patterns (e.g., 47 colors → 12 tokens)
- **Frontend Integration**: Frontend-shipper agent validates implementation against design artifacts with automated design lint checks

**Problem Solved**: Before v2.12.0, achieving high-quality UI/UX required Figma and manual design handoff, leading to inconsistent implementations and design-dev drift. Manual validation of design principles (elevation, hierarchy, gradients) was error-prone.

**Impact**: Systematic enforcement of S-tier design principles from wireframes through implementation. 100% token compliance ensures consistent UI. Pixel-perfect handoff documentation eliminates design-dev miscommunication. Brownfield support enables design system adoption in existing projects.

---

### v2.10.0 (October 2025)
**X Announcement Slash Command** - Converted X announcement from skill to slash command

- **Direct Invocation**: `/x-announce "version"` replaces skill-based workflow
- **5-Option Workflow**: Post now, schedule, draft, edit, or skip
- **Threaded Replies**: Automatic GitHub release link as reply using `in_reply_to_tweet_id`
- **Release Integration**: Integrated into `/release` command Step 9 (optional, non-blocking)
- **Simplified Architecture**: Command-based execution replaces skill loading

**Problem Solved**: Before v2.10.0, X announcements required loading a skill and complex interaction flow. Now `/x-announce` provides direct, streamlined access with same functionality.

**Impact**: Release announcements are faster and simpler. Command structure is more maintainable than skill-based approach.

---

### v2.9.0 (October 2025)
**Help Command** - Context-aware workflow navigation

- **Contextual Guidance**: `/help` shows where you are and what to do next
- **Six Output Modes**: Adapts to context (no feature, in feature, at gate, blocked, complete, corrupted)
- **Progress Visualization**: Emoji indicators show phase status (✅ ⏳ ⬜ ❌)
- **Deployment Model Aware**: Shows correct phase sequences for staging-prod, direct-prod, local-only
- **Error Recovery**: Highlights blockers with specific recovery options
- **Verbose Mode**: `/help verbose` for detailed state (quality gates, deployments, artifacts)
- **Always Actionable**: Shows next command to run based on current state

**Problem Solved**: Before v2.9.0, users had to manually track workflow state and remember next steps. Now `/help` provides instant orientation and guidance.

**Impact**: Reduced cognitive load and faster error recovery. No more "what do I run next?" confusion.

---

### v2.8.1 (October 2025)
**npm Package Fix** - Properly excludes internal workflow files

- **Fixed npm package**: Internal files (release.md, x-announcement.md) no longer included in published package
- **Explicit file listing**: package.json files array updated with explicit includes and negation patterns
- **Enhanced protection**: .npmignore created for additional safety layer
- **Security**: Prevents accidental exposure of internal API URLs and workflow development files

**Problem Solved**: Before v2.8.1, internal workflow development files leaked into npm package. Now proper exclusion prevents exposure.

**Impact**: Enhanced security - internal API URLs and development files stay private.

---

### v2.8.0 (October 2025)
**X Announcement Integration** - Automated social media announcements for releases

- **Automated X Posts**: `/release` now posts announcements to X (Twitter) automatically with custom post generation
- **Threaded Replies**: GitHub release link posted as threaded reply using `in_reply_to_tweet_id` API parameter
- **Preview & Edit**: Review and customize post text before sending (280 character limit validation)
- **Graceful Fallback**: Manual posting instructions if X Poster API unavailable
- **Security**: X announcement skill and updated /release command gitignored (internal API URL protection)

**Problem Solved**: Before v2.8.0, release announcements required manual X posting. Now `/release` handles social media automatically with customizable posts and proper threading.

**Impact**: Release visibility increased with zero-friction social announcements. Internal API URLs remain protected.

---

### v2.7.0 (October 2025)
**Release Automation & Essential Finalization** - One-command releases and universal branch cleanup

- **Full /release Automation**: CI validation, README updates, CHANGELOG, git tags, GitHub releases, and npm publishing in one command
- **Smart Version Detection**: Analyzes conventional commits to automatically determine MAJOR/MINOR/PATCH bumps
- **Pre-flight Validation**: Checks git remote, branch, working tree, npm auth, and CI status before release
- **Auto-Issue Closing**: GitHub issues automatically close with "shipped" status when features deploy
- **Essential Finalization**: Roadmap updates and branch cleanup now run for ALL deployment models (not just staging-prod)
- **Clean CI**: Fixed all ShellCheck warnings in bash scripts for reliable CI passes

**Problem Solved**: Before v2.7.0, releases required 10+ manual steps and direct-prod/local-only deployments skipped cleanup tasks. Now `/release` handles everything automatically and all deployment models clean up properly.

**Impact**: Release workflow is now 5x faster (2 minutes vs 10+ minutes) and branch cleanup happens consistently across all deployment models.

---

### v2.6.0 (October 2025)
**TodoWrite Progress Tracking** - Clear visibility and error recovery for /ship and /finalize

- **Visual Progress Tracking**: `/ship` now tracks all 5-8 deployment phases with TodoWrite
- **Documentation Tasks Tracked**: `/finalize` tracks all 10 documentation tasks (CHANGELOG, README, releases, issues, branches)
- **No More Silent Failures**: See exactly what's happening when CI errors occur
- **Error Recovery**: Specific "Fix [error]" todos added when builds/deployments fail
- **Resumability**: Run `/ship continue` after fixing errors to resume from failed phase
- **Manual Gate Clarity**: Preview and staging validation gates clearly marked as pending

**Problem Solved**: Before v2.6.0, `/ship` would stop silently on CI errors and `/finalize` would skip tasks without visibility. Now users see current progress, blockers, and can resume after fixes.

**Impact**: Deployment workflows are now transparent and recoverable, preventing the frustration of "it stopped and I don't know why."

### v2.9.0 (October 2025)
**Help Command** - Context-aware workflow navigation

- **Contextual Guidance**: `/help` shows where you are and what to do next
- **Six Output Modes**: Adapts to context (no feature, in feature, at gate, blocked, complete, corrupted)
- **Progress Visualization**: Emoji indicators show phase status (✅ ⏳ ⬜ ❌)
- **Deployment Model Aware**: Shows correct phase sequences for staging-prod, direct-prod, local-only
- **Error Recovery**: Highlights blockers with specific recovery options
- **Verbose Mode**: `/help verbose` for detailed state (quality gates, deployments, artifacts)
- **Always Actionable**: Shows next command to run based on current state

### v2.8.1 (October 2025)
**npm Package Fix** - Properly excludes internal workflow files

- **Fixed npm package**: Internal files (release.md, x-announcement.md) no longer included in published package
- **Explicit file listing**: package.json files array updated with explicit includes and negation patterns
- **Enhanced protection**: .npmignore created for additional safety layer
- **Security**: Prevents accidental exposure of internal API URLs and workflow development files

### v2.8.0 (October 2025)
**X Announcement Integration** - Automated social media announcements

- **Automated X Posts**: `/release` posts to X automatically with threaded GitHub link reply
- **Preview & Edit**: 280 character validation with preview before posting
- **Custom Post Generation**: Extracts CHANGELOG highlights for engaging posts
- **Graceful Fallback**: Manual posting instructions if X Poster API unavailable
- **Security**: Internal files gitignored to protect API URLs

### v2.1.2 (October 2025)
**/feature next Auto-Pull** - Automatically start highest priority roadmap item

- **Usage**: `/feature next` - Auto-pulls highest priority feature from GitHub Issues
- **Smart Search**: Queries `status:next` first, falls back to `status:backlog`
- **Priority Sorting**: Sorts by `priority:high` → `priority:medium` → `priority:low`
- **ICE Display**: Shows Impact/Confidence/Effort scores and calculated ICE score
- **Auto-Status Update**: Moves issue from `next`/`backlog` → `in-progress`
- **Full Traceability**: Links workflow state to GitHub issue number
- **No Manual Input**: Just run `/feature next` - no feature description needed

**Benefits**: Work on highest priority items automatically, reduce context switching, maintain roadmap sync.

### v2.1.0 (October 2025)
**GitHub Issues Roadmap Migration** - Complete migration from markdown to GitHub Issues

- **Backend Migration**: `/roadmap` command now uses GitHub Issues instead of markdown files
- **Label-Based State**: Features organized via labels (`status:backlog`, `status:next`, `status:in-progress`, `status:shipped`)
- **ICE Scoring Preserved**: Impact × Confidence / Effort stored in YAML frontmatter in issue descriptions
- **Priority Labels**: Auto-applied based on ICE score (`priority:high` >= 1.5, `priority:medium` 0.8-1.5, `priority:low` < 0.8)
- **Dynamic Sorting**: Features sorted by priority labels via queries (no manual file editing)
- **Native Integration**: Issues, PRs, and roadmap in one place with GitHub Projects support
- **Cross-Platform**: Both Bash and PowerShell examples throughout
- **Same Workflow**: All actions (add, brainstorm, move, delete, ship) work identically

**Breaking Change**: Roadmap data is now in GitHub Issues, not `.spec-flow/memory/roadmap.md`. Old markdown roadmap can be migrated using `.spec-flow/scripts/bash/migrate-roadmap-to-github.sh`.

**Setup Required**: Run `.spec-flow/scripts/bash/setup-github-labels.sh` to create labels, then authenticate with `gh auth login` or set `GITHUB_TOKEN`.

**Documentation**: See `docs/github-roadmap-migration.md` for complete guide.

### v1.13.0 (October 2025)
**Local Project Integration Workflow** - Automatic merge-to-main for local-only projects

- **New Phase S.4.5a**: Merges feature branch → main/master after successful local build
- **Auto-detects main branch**: Supports both `main` and `master` branch names
- **Preserves feature history**: Uses `--no-ff` merge to maintain branch context
- **Remote sync**: Automatically pushes to origin if remote exists
- **Branch cleanup**: Offers to delete feature branch locally and remotely after merge
- **Correct sequencing**: Merge happens BEFORE version bump and roadmap update
- **Git best practices**: Version tag created on main branch (not feature branch)

**Before**: `optimize → build-local → finalize` ❌ (stayed on feature branch)
**After**: `optimize → build-local → merge-to-main → finalize` ✅ (integrated to main)

**Impact**: Local-only projects now have complete parity with remote deployment models - all features properly integrate to main branch before being marked "Shipped" in roadmap.

### v1.12.1 (October 2025)
**Update Command Simplification** - Removed backup overhead for faster, cleaner updates

- **Removed backup creation**: `npx spec-flow update` no longer creates backup folders
- **Faster updates**: No backup overhead, instant template updates
- **User data still preserved**: Templates updated while learnings.md, memory, and specs remain untouched
- **Removed --force flag**: No longer needed (backwards compatible)
- **Cleaner output**: Shows "Templates updated, user data preserved" message

**Why?** The preserveMemory flag already protects user data during updates. Backups created redundant folders that users had to manually clean up. This change simplifies the update process while maintaining safety.

### v1.12.0 (October 2025)
**Learnings Persistence & Design Iteration** - Skills learn across npm updates + enhanced design workflow

**Part 1: Learnings Persistence (All 16 Skills)**
- **Separated learnings data from SKILL templates**: Created `learnings.md` for all 16 phase skills
- **Preserves knowledge across npm updates**: SKILL.md templates get updated, learnings.md data persists
- **Tracks pitfall frequencies**: Auto-updates frequency stars (⭐☆☆☆☆ → ⭐⭐⭐☆☆) as issues occur
- **Tracks pattern success rates**: Records usage counts and success rates for proven approaches
- **Zero manual intervention**: System learns automatically as you work

**Part 2: Design Iteration Enhancements**
- **Screen-specific targeting**: `/design-variations $SLUG [$SCREEN]` - iterate on single component
- **Overwrite protection**: Warns before regenerating, offers [b]ackup to create git tag first
- **Re-enable support**: Can enable design workflow after initially declining in `/feature`
- **Iteration patterns guide**: 5 common scenarios with step-by-step solutions (component iteration, A/B testing, state-specific refinement)

**Documentation**
- Added "Skills & Learning System" section to README
- Two-file architecture explained (templates vs data)
- Iteration patterns guide for design workflow

**Files**: 36 changed (16 learnings.md created, 16 SKILL.md updated, iteration-patterns.md created)

### v1.11.1 (October 2025)
**Folder Cleanup Refactor** - Cleaner spec directories with on-demand folder creation

- **Eliminated empty folders**: Removed blanket directory pre-creation from `/spec` command
- **On-demand creation**: Folders (`visuals/`, `design/`) now created only when files are written
- **Benefits**: Cleaner spec directories, easier to identify UI features, follows YAGNI principle
- **Files modified**: `.claude/commands/specify.md`

### v1.11.0 (October 2025)
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

Spec-Flow now features an **optimized orchestrator** (`/feature`) that runs each workflow phase in isolated contexts for maximum efficiency:

**Benefits:**
- ⚡ **67% Token Reduction** - Each phase runs in isolated context (240k → 80k tokens per feature)
- 🏃 **2-3x Faster** - No cumulative context bloat, no /compact overhead between phases
- ✅ **Same Quality** - All slash commands unchanged, proven workflow maintained

**How it works:**
```
/feature (Orchestrator - Lightweight State Tracking)
  ├→ spec-phase-agent → /spec → Returns summary
  ├→ plan-phase-agent → /plan → Returns summary
  ├→ tasks-phase-agent → /tasks → Returns summary
  ├→ /implement → Spawns worker agents directly (bypasses phase agent*)
  └→ ... (each phase isolated, efficient handoffs)

  * Phase 4 calls /implement directly due to sub-agent spawning limits
```

**Choose your workflow:**
- **`/feature "feature"`** - Full feature workflow (recommended)
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
   /setup-constitution         # Interactive Q&A for engineering standards
   /roadmap              # Plan and prioritize features with ICE scoring
   /design-inspiration   # Curate visual references for consistency
   ```
4. **Start building:**
   ```bash
   /feature "my-feature"  # Full feature workflow
   /quick "fix bug"       # Fast path for small changes
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

Run the `/setup-constitution` command in Claude to document the engineering principles that guard every feature. Store the output in `.spec-flow/memory/setup-constitution.md`.

### 3. Build your roadmap

Use `/roadmap` to manage features via GitHub Issues with ICE scoring (Impact × Confidence / Effort):
- **Setup**: Authenticate with `gh auth login` or set `GITHUB_TOKEN`, then run `.spec-flow/scripts/bash/setup-github-labels.sh`
- **Add features**: `/roadmap add "feature description"` creates GitHub issue with priority labels
- **Brainstorm**: `/roadmap brainstorm [quick|deep]` generates ideas from research
- **Organize via labels**:
  - `status:backlog` - Ideas to consider
  - `status:next` - Top 5-10 prioritized features
  - `status:in-progress` - Currently being built
  - `status:shipped` - Completed features (issue closed)
- **View roadmap**: Browse GitHub Issues or use `gh issue list --label status:next`

**Documentation**: See `docs/github-roadmap-migration.md` for complete guide.

### 4. Kick off a feature

Select a feature from your roadmap and choose your workflow:

**Full workflow (recommended):**
```bash
/feature "feature-name"  # Runs full workflow with isolated phase agents
# Auto-progresses through: spec → plan → tasks → validate → implement → optimize → ship
# Pauses at manual gates: /preview, /validate-staging
# Use: /feature continue (to resume after manual gates)
```

**Manual step-by-step:**
```bash
/spec "feature-name"  # Create specification
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
- `.claude/skills/specification-phase/` - Learn from /spec (reduce clarifications, improve classification)
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
- GitHub Issues - Your product roadmap (stored as issues with labels)
- `.spec-flow/memory/setup-constitution.md` - Your project principles
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
| -1 | `/roadmap` | GitHub Issues with ICE-scored features and priority labels |
| 0 | `/spec` | `spec.md`, `NOTES.md`, `visuals/README.md` |
| 0.5 | `/clarify` | Clarification log inside the spec |
| 1 | `/plan` | `plan.md`, `research.md` |
| 2 | `/tasks` | `tasks.md` with acceptance criteria |
| 3 | `/validate` | Risk analysis report |
| 4 | `/implement` | Implementation checklist & validation hooks |
| 5 | `/optimize` | Code review summary & optimization plan |
| 6 | `/debug` | Error triage and remediation plan |
| 7 | `/preview` | Release notes & preview checklist |
| 8 | `/ship-staging` | Staging deployment ritual |
| 9 | `/validate-staging` | Sign-off for staging |
| 10 | `/ship-prod` | Production launch and follow-up |
| - | `/compact [phase]` | **Optional:** Reduce token usage between phases |

**Context Management**: The `/compact` command is optional and reduces token usage by summarizing verbose artifacts. Use it between phases when context feels heavy or when suggested by auto-progression.

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
2. **Set up roadmap**: Authenticate with GitHub (`gh auth login`), run `.spec-flow/scripts/bash/setup-github-labels.sh` to create labels.
3. **Build roadmap**: Use `/roadmap` to add features as GitHub Issues, prioritize with ICE scoring, organize via labels (status:backlog → status:next → status:in-progress → status:shipped).
4. Select a feature from GitHub Issues and launch `/feature "<feature-slug>"` in Claude to scaffold the spec from the issue.
5. Progress through `/clarify`, `/plan`, `/tasks`, and `/validate`, addressing blockers as they appear.
6. Use `calculate-tokens` to watch context budgets and `compact-context` to summarise when approaching thresholds.
7. Walk the release staircase: `/preview`, `/ship-staging`, `/validate-staging`, `/ship-prod`.
8. The feature is automatically marked as shipped in GitHub Issues (label changed to `status:shipped`, issue closed), and changelog is updated with the release.

## Packages & Releases

- **npm**: Published as [`spec-flow`](https://www.npmjs.com/package/spec-flow). Install globally with `npm install -g spec-flow` or run one-off with `npx spec-flow`.
- **GitHub Packages**: The `Publish Packages` workflow mirrors each release to GitHub Packages under the scoped name `@marcusgoll/spec-flow`, enabling the repository's *Packages* tab.
- **Automation**: Creating a GitHub release (or manually running the workflow) triggers the dual publish. Set the `NPM_TOKEN` repository secret with an npm automation token that has `publish` rights; GitHub packages use the built-in `GITHUB_TOKEN`.

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `pwsh` command not found | Install PowerShell 7 (`winget install Microsoft.PowerShell` or `brew install --cask powershell`). |
| Shell script reports missing feature directory | Run `/feature` first or use `create-new-feature` to scaffold `specs/NNN-slug`. |
| Token estimate returns zero | Verify files are UTF-8 encoded and not empty. |
| Context delta lacks checkpoints | Ensure `NOTES.md` records checkpoints prefixed with `-`. |

## Maintainers

* Marcus Gollahon ([@marcusgoll](https://x.com/marcusgoll))
- Community contributors  join via pull requests!

## License

Released under the [MIT License](LICENSE).





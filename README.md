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

### v10.9.0 (December 2025)

**Auto-Progression Mode for /feature** - Full workflow automation matching /epic command capabilities.

- **Mode Flags**: `--auto`, `--interactive`, `--no-input` for CI/CD automation
- **3-Tier Preference System**: Config file → command history → flags (highest priority)
- **Smart Defaults**: `skip_mode_prompt` option, auto-select when >80% usage pattern
- **State Tracking**: `auto_mode` in state.yaml, manual gates support `auto_skipped` status

New: Feature command version 3.0, user-preferences schema v1.3

---

### v10.8.0 (December 2025)

**Design Token Enforcement System** - Real-time prevention of hardcoded colors and spacing values via Claude Code hooks.

- **PreToolUse Hooks**: Block `#hex`, `rgb()`, arbitrary Tailwind values (`p-[15px]`) before write
- **SessionStart Hooks**: Context injection reminders at session start
- **CLI Commands**: `npx spec-flow install-hooks` and `uninstall-hooks`
- **Interactive Install**: Prompts during `npx spec-flow init` or `update`
- **Root CLAUDE.md**: Design Token Compliance section loaded every session

New files: `.claude/hooks/design-token-validator.sh`, `design-system-context.sh`, `bin/install-hooks.js`

---

### v10.7.0 (December 2025)

**CLAUDE.md Context Engineering Best Practices** - Major restructure following context engineering research for improved instruction-following and 87% token reduction.

- **WHAT/WHY/HOW Framework**: Root CLAUDE.md uses structured sections for clarity
- **Progressive Disclosure**: Deep-dive content extracted to `docs/references/*.md` (8 files)
- **Quality Validation Tooling**: New `/audit-claude-md` command with 0-100 scoring
- **Deterministic Validation**: Hook and scripts instead of "LLM as linter" pattern
- **Context vs Instructions**: Clear separation of auto-generated context from human-written instructions

New files: `docs/references/*.md`, `.spec-flow/scripts/bash/audit-claude-md.sh`, `.claude/hooks/claude-md-validator.sh`, `.spec-flow/config/claude-md-rules.yaml`

---

### v10.6.0 (November 2025)

**/init-preferences Enhancements** - Extended wizard with E2E and migration preferences.

- **E2E Visual Testing Preferences (Q14-Q15)**: Configure enable/disable, failure mode, pixel threshold
- **Database Migration Preferences (Q16-Q17)**: Configure strictness and detection sensitivity
- **Schema Updates**: Added `e2e_visual` section to preferences schema
- **Question Count**: Increased from 13 to 17 for comprehensive configuration

---

### v10.5.0 (November 2025)

**Database Migration Safety** - Defense-in-depth system to prevent forgotten migrations.

- **Three-Phase Detection**: Early detection in `/plan`, task generation in `/tasks`, runtime enforcement in `/implement`
- **Pattern-Based Detection**: Scans spec.md for schema-change keywords (store, persist, table, etc.)
- **P0 BLOCKING Tasks**: Migration tasks (T001-T009) run before ORM, services, and API tasks
- **Configurable Strictness**: `blocking` (default) | `warning` | `auto_apply` via user preferences
- **Multi-Framework Support**: Alembic (Python), Prisma (TypeScript), and generic migrations

New files: `check-migration-status.sh`, `migration-plan-template.md`, `migration-detection.md`

---

### v10.4.0 (November 2025)

**E2E Visual Testing + Epic Worktrees** - Gate 7 adds automated E2E and visual regression testing to `/optimize` phase.

- **New Gate 7**: Playwright E2E tests with `toHaveScreenshot()` visual comparison
- **Auto Dev Server**: Automatically starts/stops dev server during tests
- **Baseline Management**: Per-feature/epic storage with auto-commit on first run
- **Epic Worktrees**: Full git worktree support for parallel epic development

New files: `.spec-flow/scripts/bash/e2e-visual-gate.sh`, `.spec-flow/templates/playwright.config.template.ts`, `.spec-flow/templates/e2e-visual.spec.template.ts`

---

### v10.2.0 (November 2025)

**MAKER Error Correction Framework** - Integrates concepts from "Solving a Million-Step LLM Task with Zero Errors" (arXiv:2511.09030) for improved reliability.

- **Red-Flagging System**: Discard suspicious agent outputs instead of repairing them
- **Multi-Agent Voting**: First-to-ahead-by-k error correction for critical decisions
- **Task Complexity Scoring**: 1-10 scale with decomposition guidance (score >5 = decompose)
- **Error Rate Tracking**: Historical success rates for adaptive model selection (c/p optimization)

New files: `.spec-flow/config/red-flags.yaml`, `.spec-flow/config/voting.yaml`, `.spec-flow/learnings/error-rates.yaml`, `docs/maker-integration.md`

---

### v10.1.0 (November 2025)

**Codex CLI Support** - Full compatibility layer for OpenAI Codex CLI, enabling Spec-Flow workflows with both Claude Code and Codex. Includes new epic skills (scoping, meta-prompting, sprints, walkthrough), security fixes, and infrastructure improvements.

### v10.0.1 (November 2025)

**Bug Fixes** - Epic workflow branch creation and UTF-8 encoding

- **Epic Branch Creation Fix**: Resolved critical bug where `/epic` command skipped git branch creation
  - Fixed load-preferences.sh to support --key and --default arguments
  - Added get_preference_value() function for nested YAML key extraction
  - Added missing worktrees and learning configuration sections
  - Enhanced error handling with automatic fallback to regular branch creation
  - Result: `/epic` command now correctly creates `epic/NNN-slug` branches before specification phase
- **X Announcement UTF-8**: Fixed UTF-8 encoding issues causing emoji corruption in release announcements
- Updated preferences schema with complete worktrees and learning validation

---

### v10.0.2 (November 2025)

**Epic Workflow Stability** - Critical fixes for epic orchestration and CI monitoring

- **Epic Optimize Phase**: Fixed directory detection to support both epic and feature workflows
  - Replaced hardcoded specs/ detection with centralized workflow detection utility
  - Eliminates "No feature directory found" errors when running /optimize on epics
  - Epic workflows now pass all quality gates correctly
- **Epic Sprint Tracking**: Added fallback for missing sprint state.yaml files
  - Verifies sprint agents created state files after completion
  - Creates minimal fallback with warnings if agent forgets
  - Ensures epic progress monitoring never fails silently
- **Epic CI Monitoring**: Added 30-minute timeout and resume detection to ship-staging
  - Detects if PR already merged (skips CI wait for /epic continue resume)
  - Increased timeout from 10 to 30 minutes with manual override prompt
  - Shows progress updates every 5 minutes
  - Eliminates indefinite blocking on CI monitoring stage

**Impact**: Epic workflows now run reliably from specification through production deployment without manual intervention.

---

### v10.0.0 (November 2025)

**Git Worktrees & Perpetual Learning** - Parallel development and self-improving workflows

- **Git Worktrees**: Enable multiple Claude Code instances on different epics/features
  - Automatic worktree creation per epic/feature
  - Shared memory linking for cross-worktree observability
  - Automatic cleanup after /finalize
  - Isolated workspaces prevent branch conflicts
  - Use cases: parallel epic development, epic + urgent hotfix, multi-developer coordination
- **Perpetual Learning System**: Continuously improve workflow efficiency
  - Performance pattern detection (auto-applied optimizations, 20-40% execution time reduction)
  - Anti-pattern detection (failure prevention with automatic warnings)
  - Custom abbreviation learning (project-specific terminology)
  - CLAUDE.md optimization (system prompt improvements with approval)
  - Learning categories: performance-patterns.yaml, anti-patterns.yaml, custom-abbreviations.yaml, claude-md-tweaks.yaml
  - Migration system preserves learnings across npm package updates
- **NPM Update Protection**: Learnings persist across package updates via migration system
  - Archive/restore learnings to .spec-flow/learnings/archive/v{version}/
  - Schema migration support (add fields, rename keys)
  - Team knowledge sharing via git-committed learning files

**Breaking Changes**:

- None (backwards compatible with v9.x.x)

---

### v6.11.0 (November 2025)

**CLI Workflow Installation & Feature Continue** - Complete workflow integration

- **CLI Workflow Installation**: GitHub workflows now install via `npx spec-flow init` and `npx spec-flow update`
  - Automatically copies `.github/workflows/` directory
  - Uses same conflict resolution as other files (merge by default)
  - Respects `--strategy` flag (merge|backup|skip|force)
  - Skips existing workflows to preserve customizations
- **Feature Continue Mode**: `/feature continue` command now resumes most recent feature
  - Finds most recently modified feature in `specs/`
  - Cross-platform compatible (Linux, macOS, Windows)
  - Extracts feature description from spec.md
  - Shows clear banner with feature info

---

### v6.10.0 (November 2025)

**Auto-Install GitHub Workflows** - Seamless workflow integration on package install

- **Automatic Workflow Installation**: Postinstall script copies GitHub Actions workflows to `.github/workflows/`
  - Auto-installs if directory exists (skips existing files)
  - Prompts to create directory if needed
  - Interactive confirmation (inquirer)
  - Silent in CI/non-interactive environments
- **Update Detection**: New workflows auto-install during `npm install spec-flow`, existing workflows preserved
- **Zero Manual Steps**: Users no longer need to manually copy workflow files

---

### v6.9.0 (November 2025)

**Streamlined Ship Orchestration** - 60% faster deployments with zero manual gates

- **Auto-Fix CI Failures**: New GitHub Action automatically fixes lint/format issues on PR creation
  - PowerShell formatting (PSScriptAnalyzer)
  - Markdown linting (markdownlint)
  - JSON formatting (jq)
  - Auto-commits fixes and comments on PR
- **Docker Build Validation**: Added Docker build check to /optimize (6th parallel check)
  - Validates Dockerfile builds before deployment
  - Auto-skips if no Dockerfile present
  - Critical blocker if build fails
- **Faster Deployments**: Reduced from 65-165 min to 25-35 min
  - Removed /preview manual gate (all testing in staging)
  - Removed interactive version selection (defaults to patch bump)
  - Removed manual staging validation checklist (auto-generated reports)
  - Parallelized pre-flight + optimize checks (saves ~10 min)
- **Platform API-Based Deployment IDs**: Replaced log parsing with direct API calls
  - Vercel API, Railway GraphQL, Netlify API
  - More reliable than grep/awk log parsing

**Breaking Changes**:

- /preview command archived (all testing now in staging)
- /ship-prod no longer prompts for version (use `--version major|minor` flag to override patch default)
- state.yaml schema updated (removed `preview` phase)

---

### v6.8.0 (November 2025)

**Full Cross-Platform Support** - 100% command coverage on all platforms (40/40 commands)

- **PowerShell Wrappers**: All bash-only commands now work on Windows PowerShell
  - 27 PowerShell wrapper scripts automatically generated (invoke bash via Git Bash)
  - Automated wrapper generator for future maintenance (generate-ps-wrappers.py)
  - Maintains single source of truth (bash scripts)
- **Name Mismatch Fixes**: 10 commands now call correct script names
  - generate-feature-claude, generate-project-claude, roadmap, epic, version
  - Created 5 bash dispatcher scripts (flag, gate, schedule, deps, sprint)
- **Windows Path Resolution**: Fixed bash subprocess path issues on Windows
  - spec-cli.py uses relative paths with cwd parameter
  - Handles Windows → Unix path conversion for Git Bash
- **PowerShell Compatibility**: Fixed parameter naming and duplicate Verbose parameter
  - kebab-case → PascalCase parameter mapping (--feature-dir → -FeatureDir)
  - calculate-tokens: Verbose → ShowBreakdown
- **Comprehensive Documentation**: 6,200+ lines across 5 new docs (analysis, sprints, summary)

**Platform Coverage**:

- macOS: 40/40 (100%) ✅
- Linux: 40/40 (100%) ✅
- Windows (Git Bash): 40/40 (100%) ✅
- Windows (PowerShell): 40/40 (100%) ✅ (requires Git Bash)

**Windows Requirements**: Git Bash must be installed for PowerShell wrappers to work. Download from https://git-scm.com/download/win

---

### v6.5.0 (November 2025)

**Comprehensive Error Logging**

- **Automatic Error Tracking**: Error-log.md now automatically populated during workflow execution
  - Native bash `mark-failed` function in task-tracker.sh
  - Specialist agents MUST log errors BEFORE auto-rollback
  - Captures test failures, missing REUSE files, git conflicts, linting errors
  - Structured format with timestamps, task IDs, and error details
- **Mandatory Error Logging**: Updated specialist agent prompts in implement-workflow.sh
  - All failure scenarios require error logging via task-tracker mark-failed
  - Error capture integrated into auto-rollback logic
  - Continue to next task after logging (fail gracefully)
- **CI ShellCheck Fixes**: Excluded workflow instruction files from validation
  - Workflow files (\*-workflow.sh) are documentation, not executable bash scripts
  - Added SC2004 to exclusions (cosmetic style warnings)

**Problem Solved**: Error-log.md files were created with comprehensive templates during /plan phase but remained empty during workflow execution. Only /debug command and PowerShell task-tracker actually wrote to error-log.md, meaning errors during /implement were lost.

**Impact**: All failures during workflow execution are now automatically logged to error-log.md with full context. Debugging is dramatically faster with complete error history. Specialist agents fail gracefully with proper error tracking.

---

### v6.4.1 (November 2025)

**Windows Compatibility Fix**

- **Bash Fallback**: spec-cli.py now automatically falls back to bash scripts when PowerShell equivalents don't exist
  - Enables Windows users to run workflow commands via Git Bash/WSL without errors
  - Graceful fallback with informative message: "Note: PowerShell script not found, using bash"
  - Fixes "PowerShell script not found" error for feature-workflow and other commands
- **Git Permissions**: Fixed executable permissions for ship-prod-workflow.sh (100755 mode)
- **Python Cache**: Added **pycache** to .gitignore to prevent accidental commits

**Problem Solved**: Windows users couldn't run workflow commands because spec-cli.py expected PowerShell scripts that were never created during the CLI migration. Only bash scripts exist, but there was no fallback mechanism.

**Impact**: Windows users with Git Bash/WSL can now run all workflow commands seamlessly. Cross-platform compatibility restored without requiring PowerShell script duplication.

---

### v6.4.0 (November 2025)

**CLI Integration & Design System Expansion**

- **39 Total Commands**: Integrated 15 new commands into spec-cli.py for comprehensive workflow coverage
  - Living Documentation: Auto-generate CLAUDE.md files, health checks for stale docs
  - Project Management: `init-project`, `roadmap`, `design-health`
  - Epic & Sprint: Epic groupings and sprint cycle management
  - Quality & Metrics: Quality gates and HEART/DORA metrics tracking
- **Design System Intelligence**: Component reuse enforcement with automated quality checks
  - `design-scout` agent: Analyzes existing components before mockup creation (85%+ reuse target)
  - `design-lint` agent: Automated mockup quality inspector (WCAG 2.1 AA, color contrast, touch targets)
  - Multi-screen mockup navigation: Keyboard shortcuts (H=hub, 1-9=screens, S=states, Esc=close)
  - Health monitoring: 7 automated checks for design system staleness and documentation sync
- **Infrastructure Commands**: Scheduler (epic assignment with WIP limits), fixture refresh, DORA metrics

**Problem Solved**: Fragmented command interfaces and no systematic design system health monitoring. Component duplication occurred without reuse enforcement. Manual quality checks were inconsistent.

**Impact**: Single CLI entry point for all 39 workflow commands. Automated design quality validation catches issues before implementation. 85%+ component reuse enforced via design-scout analysis.

---

### v6.3.0 (November 2025)

**HTML Mockup Approval Workflow**

- **UI-First Flag**: `/tasks --ui-first` generates browser-previewable HTML mockups before implementation
- **tokens.css Integration**: Mockups link to `design/systems/tokens.css` for live design updates (refresh browser to see changes)
- **Mock Data States**: Inline JavaScript with ALL states (loading, error, empty, success) - press 'S' to cycle
- **Single Approval Gate**: User reviews HTML in browser, approves via checklist before `/implement` proceeds
- **HTML → Next.js Conversion**: Automatic conversion after approval preserves accessibility and tokens
- **Style Guide Evolution**: Agent proposes tokens.css updates when user requests design changes
- **Component Reuse**: Checks ui-inventory.md before creating custom components
- **Workflow Integration**: Mockup approval gate in state.yaml blocks `/implement` until approved

**Problem Solved**: Previous workflow had no design approval gate. Implementation proceeded directly from spec to production code, requiring costly rework if design changes were needed. Design tokens could drift without systematic update proposals.

**Impact**: 75-85% faster UI development by approving design before implementation. Zero implementation rework from design changes. Systematic design token evolution with user approval. Early accessibility validation (WCAG 2.1 AA).

---

### v6.2.3 (November 2025)

**Frontend Agent: Mandatory Design System Enforcement**

- **MANDATORY PRE-WORK**: Design system consultation now blocks ALL UI/UX implementation
- **7-Item Checklist**: Required reading (style-guide.md, tokens.json, ui-inventory.md, design-principles, patterns, inspirations, frontend-design skill) before implementation
- **Creative Direction**: Bold aesthetic guidance (choose distinctive direction, avoid generic AI aesthetics)
- **Aesthetic Guidelines**: Typography, color, motion, spatial composition (avoid font convergence, commit to cohesive themes)
- **Token Proposal Flow**: Process for adding new design tokens when creative vision requires them
- **Quality Gates**: design-lint.js, axe-core, Lighthouse, aesthetic differentiation checks
- **Integration Model**: Design system provides constraints, creative guidelines provide direction

**Problem Solved**: Frontend agent referenced design system files but didn't enforce consultation, allowing agents to skip design system integration and create inconsistent UI.

**Impact**: All UI/UX work now aligns with design system from day one. No more arbitrary colors, spacing, or fonts. Creative excellence within constraints. Quality gates ensure compliance.

---

### v4.8.0 (November 2025)

**/finalize Command Enhancement**

- **GitHub Release Updates**: Automatically updates GitHub Release with production deployment information
- **Production Metadata**: Appends deployment URL, date, run ID, and documentation links to release notes
- **Idempotent Operation**: Checks for existing production info before updating (safe to re-run)
- **Non-Blocking**: Continues finalization workflow even if release doesn't exist
- **Full Traceability**: Links deployment logs, CHANGELOG, and help documentation

**Problem Solved**: GitHub Releases lacked production deployment context after /finalize. Users had to manually update releases with deployment URLs and documentation links.

**Impact**: Complete deployment traceability. GitHub Releases now serve as single source of truth for production deployments with automatic linking to all relevant documentation.

---

### v4.7.0 (November 2025)

**/implement Phase Parallel Execution**

- **Parallel Batch Groups**: 3-5 batches execute simultaneously per group (vs sequential execution)
- **TodoWrite Integration**: Live progress tracking with batch group status updates
- **Optimized Validation**: Single validation pass at end (vs per-batch validation)
- **Checkpoint Commits**: One commit per batch group (cleaner git history)
- **Performance**: 30-50% faster (30min → 15min typical), 33% token reduction (150k → 100k)
- **Pattern Alignment**: Matches /optimize phase parallel dispatch + single aggregation pattern

**ShellCheck Compliance Fixes**

- Resolved SC2162: Added `-r` flag to all `read` commands in init-project.sh
- Resolved SC2120/SC2119: Fixed `scan_brownfield` function parameter handling
- Replaced bash-specific `&>` with POSIX-compliant `> /dev/null 2>&1`

**Problem Solved**: /implement phase executed batches sequentially, taking 30-60 minutes when parallelism could reduce to 15-30 minutes. ShellCheck CI failures blocking releases.

**Impact**: 2-3x faster implementation phase execution. Cleaner git history with batch group commits. CI now passes on all bash scripts.

---

### v4.6.0 (November 2025)

**Infrastructure Command Integration & /init-project Enhancements**

- **Infrastructure Automation**: Context-aware detection and prompts for `/flag-add`, `/contract-bump`, `/flag-cleanup`, `/fixture-refresh` integrated into core phases
- **Idempotent /init-project**: Update mode (fills `[NEEDS CLARIFICATION]` only), force mode (regenerate all), write-missing-only mode
- **Node.js Template Renderer**: Consistent `{{VARIABLE}}` placeholder replacement with 677-line Bash and 669-line PowerShell implementations
- **Brownfield Scanning**: Auto-detect tech stack from existing codebases (package.json, requirements.txt, docker-compose.yml)
- **Quality Gates**: WCAG contrast validation, C4 model checks, markdown linting, NEEDS CLARIFICATION detection
- **Project Templates**: CODEOWNERS (204 lines), CONTRIBUTING (308 lines), SECURITY (231 lines) templates
- **Design System**: Streamlined design-principles.md v2.0.1, WCAG 2.2 aligned checklist with non-UI UX section

**Problem Solved**: Manual /init-project re-runs overwrite customizations. No automated infrastructure command detection. Missing project governance templates.

**Impact**: Safe re-runs preserve existing docs. Brownfield projects get accurate tech stack detection. Context-aware infrastructure prompts reduce manual command invocation.

---

### v4.4.0 (November 2025)

**v2.0 Command Refactor Complete** (11/46 commands - 24%)

- Refactored 6 major commands to v2.0 pattern (/spec, /clarify, /plan, /tasks, /implement, /optimize)
- Fixed PowerShell and Bash script CI failures
- Consolidated bash sections (15+ blocks → 1 unified script per command)
- Added strict error handling (`set -Eeuo pipefail`, error traps)
- Implemented tool preflight checks with install URLs
- Deterministic repo root detection
- Actionable error messages with "Fix:" instructions

### v4.3.0 (November 2025)

**Epic & Sprint Roadmap System** - Comprehensive parallel epic workflow with trunk-based development

- **Contract Infrastructure** (8 tasks)
  - Contract directory structure (contracts/api/, contracts/pacts/, contracts/fixtures/)
  - `/contract.bump`, `/contract.verify`, `/fixture.refresh` commands
  - OpenAPI 3.1 schemas with Pact CDC testing
  - Platform agent brief for shared infrastructure concerns
- **Trunk-Based Development** (6 tasks)
  - Git pre-push hook enforcing 24h branch lifetime (warn 18h, block 24h)
  - `/branch.enforce` for repository-wide branch age audits
  - Feature flag registry with `/flag.add`, `/flag.list`, `/flag.cleanup` commands
  - Flag expiry linter (GitHub Actions daily job)
- **Epic State Machine + Scheduler** (7 tasks)
  - 7-state epic lifecycle (Planned → ContractsLocked → Implementing → Review → Integrated → Released)
  - Parking logic for blocked epics (Implementing ↔ Parked)
  - `/scheduler.assign`, `/scheduler.park`, `/scheduler.list` commands
  - WIP tracker enforcing 1 epic per agent (prevents context switching)
  - Dependency graph parser (topological sort, circular dependency detection)
- **Quality Gates** (5 tasks)
  - `/gate.ci` (tests, linters, type checks, coverage ≥80%)
  - `/gate.sec` (SAST, secrets detection, dependency vulnerabilities)
  - GitHub Actions integration (quality-gates.yml)
- **DORA Metrics** (6 tasks)
  - `/metrics.dora` command (4 key metrics from GitHub API + git log)
  - Tier classification (Elite/High/Medium/Low)
  - dora-alerts.sh (threshold monitoring: branch age, CFR, flag debt, parking time)

**Problem Solved**: Large features require parallel development across vertical slices (API, DB, UI), but traditional sequential workflows create bottlenecks. No support for epics, sprints, or team parallelization. No contract governance or trunk-based development enforcement.

**Impact**: Teams can parallelize epic development with contract-first API design. Trunk-based development enforced with 24h branch limits. WIP limits prevent context switching. Real-time DORA metrics track team velocity and quality.

**See**: [docs/EPIC_SPRINT_ROADMAP.md](docs/EPIC_SPRINT_ROADMAP.md), [docs/parallel-epic-workflow.md](docs/parallel-epic-workflow.md)

---

### v4.2.0 (November 2025)

**Integrated Showcase Features** - Production-tested patterns from 6 months of real-world use

- **Auto-Activation System**: Hook-based skill suggestions (30-40% faster workflow navigation)
- **Progressive Disclosure**: 89% token reduction on skill loading (3,373 → 382 lines)
- **Dev Docs Pattern**: Task-scoped persistence for pause/resume workflows
- **Post-Tool-Use Tracking**: Automatic file modification tracking for living documentation
- **Quality Agents**: Three new specialists (refactor-planner, auto-error-resolver, web-research-specialist)

### v4.1.0 (November 2025)

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
- **Frontend Integration**: frontend-dev agent validates implementation against design artifacts with automated design lint checks

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

| Challenge                | Without Spec-Flow                                        | With Spec-Flow                                                                       |
| ------------------------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Context Loss**         | "What were we building again?" after interruptions       | NOTES.md tracks all decisions, checkpoints restore context instantly                 |
| **Inconsistent Quality** | Features shipped without tests, reviews vary             | Every feature follows same rigorous process: spec → plan → implement → review → ship |
| **Token Waste**          | Conversations balloon to 100k+ tokens, Claude slows down | Auto-compaction at 80% budget keeps context efficient (75k/100k/125k per phase)      |
| **No Accountability**    | "Did we test this? Who approved?"                        | Auditable artifacts for every phase, approval gates enforced                         |
| **Reinventing Process**  | Each feature starts from scratch                         | Reusable templates, proven patterns, documented workflows                            |

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

- **`/epic "large project"`** - Epic-level orchestration with parallel sprint execution (v5.0+)
- **`/feature "feature"`** - Full feature workflow (recommended for single features)
- **`/quick "fix"`** - Fast path for small changes (<100 LOC)

---

## 🚀 Epic Workflow (v5.0) - NEW!

**For large, complex projects:** Use `/epic` to orchestrate multi-sprint workflows with 3-5x velocity improvement through parallel execution.

### When to Use /epic vs /feature

| Criteria            | Use /epic                               | Use /feature     |
| ------------------- | --------------------------------------- | ---------------- |
| **Estimated Work**  | >16 hours                               | ≤16 hours        |
| **Subsystems**      | Multiple (backend + frontend + testing) | Single subsystem |
| **Sprints**         | 2-5 sprints                             | 1 sprint         |
| **API Endpoints**   | >5 endpoints                            | ≤5 endpoints     |
| **Database Tables** | >3 tables                               | ≤3 tables        |
| **Velocity Gain**   | 3-5x (parallel execution)               | 1x (sequential)  |

### Epic Workflow Quick Start

```bash
# 1. Start an epic (from project root)
/epic "User authentication with OAuth 2.1"

# 2. Epic orchestrator will:
#    - Generate epic-spec.xml
#    - Auto-invoke /clarify if ambiguities detected (score > 30)
#    - Run research → plan via meta-prompting (isolated sub-agents)
#    - Break down into sprints with dependency graph
#    - Lock API contracts before parallel work
#    - Execute sprints in parallel layers
#    - Run quality gates + workflow audit
#    - Generate comprehensive walkthrough

# 3. Self-Improvement
#    - /audit-workflow runs automatically after implementation
#    - Detects bottlenecks, calculates velocity, suggests improvements
#    - /heal-workflow applies approved improvements
#    - Pattern detection after 2-3 epics generates custom automation

# 4. Monitor Progress
/workflow-health  # Aggregate metrics across all epics
```

### Example Epic Flow

```
Input: "User authentication with OAuth 2.1"

→ Epic Specification (epic-spec.xml)
  - Ambiguity Score: 45/100 → Auto-invoke /clarify
  - 5 questions asked via AskUserQuestion

→ Meta-Prompting Pipeline
  - Research: OAuth 2.1 best practices → research.xml
  - Planning: Architecture + API contracts → plan.xml

→ Sprint Breakdown (sprint-plan.xml)
  - S01: Backend API + Database (18h)
  - S02: Frontend UI Components (16h, depends on S01)
  - S03: Integration + E2E Tests (14h, depends on S01+S02)
  - Dependency Graph: Layer 1 (S01) → Layer 2 (S02) → Layer 3 (S03)
  - Contracts Locked: contracts/api/auth-v1.yaml

→ Parallel Execution
  - Layer 1: S01 executes (backend-dev agent)
  - Layer 2: S02 executes (frontend-dev agent)
  - Layer 3: S03 executes (test-architect agent)
  - Duration: 48h sequential → 18h actual (2.7x faster)

→ Quality Gates + Audit
  - Performance, Security, Accessibility, Code Review: PASSED
  - Workflow Audit: 87/100, 2 bottlenecks detected
  - Recommendations: 3 immediate improvements

→ Walkthrough Generation
  - Velocity: 2.7x (saved 30h)
  - What Worked: Contract-first prevented integration bugs
  - What Struggled: S02 underestimated (16h → 20h)
  - Lesson: Frontend tasks need 1.25x estimation multiplier
```

### Epic Features

**Parallel Sprint Execution:**

- Automatic dependency graph analysis
- Layer-based execution (Layer 1 → Layer 2 → Layer 3)
- Contract-first development (lock APIs before parallel work)
- Real-time progress monitoring across sprints

**Meta-Prompting (LLM-to-LLM):**

- Isolated sub-agents prevent context pollution
- Research → Plan pipeline with confidence levels
- XML output for machine-parseable artifacts

**Adaptive Workflow:**

- Auto-clarification when ambiguity score > 30
- Auto-skip preview for backend-only epics
- Adaptive question count (2-10 based on ambiguity)

**Self-Healing:**

- /audit-workflow after implementation (bottleneck detection)
- /heal-workflow applies improvements with user approval
- Pattern detection after 2-3 epics (generates custom automation)

**Comprehensive Documentation:**

- walkthrough.md with velocity metrics, lessons learned
- All artifacts in XML for LLM parsing (60% token reduction)
- audit-report.xml with actionable recommendations

### Epic Commands

```bash
# Core orchestration
/epic "goal"              # Start epic workflow
/clarify                  # Auto-invoked if ambiguities (score > 30)
/feature continue         # Resume most recent epic

# Self-improvement
/audit-workflow           # Analyze effectiveness (auto after /implement)
/heal-workflow            # Apply improvements with approval
/workflow-health          # Aggregate metrics across all epics

# Meta-prompting (used internally)
/create-prompt            # Generate optimized prompts for sub-agents
/run-prompt              # Execute prompts in isolated context
```

### Expected Outcomes

**Velocity:**

- 3-5x faster than sequential execution
- Time saved: 30-60 hours for large epics
- Critical path optimization

**Quality:**

- Zero integration bugs (contract-first development)
- 85%+ audit scores
- Comprehensive walkthrough for learning

**Adaptability:**

- Workflow learns from each epic
- Pattern detection generates custom automation
- Self-healing prevents workflow drift

---

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

# 2. Run the installation wizard (Windows PowerShell)
powershell -File .spec-flow/scripts/powershell/install-wizard.ps1

# OR (Windows Git Bash)
./.spec-flow/scripts/bash/install-wizard.sh

# OR (macOS/Linux)
./.spec-flow/scripts/bash/install-wizard.sh
```

**Windows Users**: For full compatibility with all 40 commands, install **Git for Windows** (provides bash):

- Download from: https://git-scm.com/download/win
- Install with default settings (adds bash to PATH)
- Restart PowerShell session after install
- Verify: `bash --version` should show GNU bash 5.x.x
- PowerShell wrappers will automatically invoke bash scripts when needed

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
   /roadmap              # Plan and track features (prioritized by creation order)
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

Clone this repository and ensure you have the required dependencies:

**All Platforms**:

- Python 3.10+ (required for spec-cli.py)

**Windows**:

- PowerShell 7.3+ (`pwsh`) OR Git Bash (recommended: install both)
- **Git for Windows** (required for full cross-platform support): https://git-scm.com/download/win
  - Provides bash for PowerShell wrappers to invoke
  - Enables all 40 commands to work from PowerShell
  - Without Git Bash: Only 13 commands work (those with native PowerShell implementations)

**macOS/Linux**:

- Bash 4.0+ (usually pre-installed)
- No additional requirements

Scripts live under `.spec-flow/scripts/powershell/` (Windows wrappers) and `.spec-flow/scripts/bash/` (cross-platform core).

**Full installation guide**: [docs/installation.md](docs/installation.md)

Copy `.claude/settings.example.json` to `.claude/settings.local.json` and update the allow list for your environment.

### 2. Establish principles

Run the `/setup-constitution` command in Claude to document the engineering principles that guard every feature. Store the output in `.spec-flow/memory/setup-constitution.md`.

### 3. Build your roadmap

Use `/roadmap` to manage features via GitHub Issues (prioritized by creation order):

- **Setup**: Authenticate with `gh auth login` or set `GITHUB_TOKEN`, then run `.spec-flow/scripts/bash/setup-github-labels.sh`
- **Add features**: `/roadmap add "feature description"` creates GitHub issue with metadata labels
- **Brainstorm**: `/roadmap brainstorm [quick|deep]` generates ideas from research
- **Prioritization**: Features are worked in creation order (earlier = higher priority)
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
# Pauses at manual gate: /validate-staging (staging-prod model only)
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

| Agent          | Status       | Notes                                           |
| -------------- | ------------ | ----------------------------------------------- |
| Claude Code    | Supported    | Optimised for slash-command workflow.           |
| Cursor         | Supported    | Pair with `.spec-flow/memory/` context files.   |
| Windsurf       | Supported    | Share roadmap + constitution for planning.      |
| GitHub Copilot | Partial      | Works for code edits; manual command execution. |
| Gemini CLI     | Experimental | Requires manual prompt translation.             |

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

| Task                   | Windows / Cross-platform                                                                        | macOS / Linux                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Validate prerequisites | `pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json`                        | `.spec-flow/scripts/bash/check-prerequisites.sh --json`                         |
| Scaffold a feature     | `pwsh -File .spec-flow/scripts/powershell/create-new-feature.ps1 "Dashboard revamp"`            | `.spec-flow/scripts/bash/create-new-feature.sh "Dashboard revamp"`              |
| Estimate token budget  | `pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 -FeatureDir specs/015-dashboard` | `.spec-flow/scripts/bash/calculate-tokens.sh --feature-dir specs/015-dashboard` |
| Compact context        | `pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 -FeatureDir specs/015-dashboard`  | `.spec-flow/scripts/bash/compact-context.sh --feature-dir specs/015-dashboard`  |

> Additional scripts such as `enable-auto-merge`, `wait-for-ci`, and `update-agent-context` also ship with `.sh` wrappers that delegate to PowerShell so you can run them from a POSIX shell while we build native equivalents.

## Core Philosophy

1. **Specification first** every artifact traces back to an explicit requirement.
2. **Agents as teammates** commands encode expectations so assistants stay aligned.
3. **Context discipline** token budgets are measured, compacted, and recycled.
4. **Ship in stages** staging and production have dedicated rituals with human gates.

## Development Phases

| Phase | Command             | Primary Outputs                                           |
| ----- | ------------------- | --------------------------------------------------------- |
| -1    | `/roadmap`          | GitHub Issues with features prioritized by creation order |
| 0     | `/spec`             | `spec.md`, `NOTES.md`, `visuals/README.md`                |
| 0.5   | `/clarify`          | Clarification log inside the spec                         |
| 1     | `/plan`             | `plan.md`, `research.md`                                  |
| 2     | `/tasks`            | `tasks.md` with acceptance criteria                       |
| 3     | `/validate`         | Risk analysis report                                      |
| 4     | `/implement`        | Implementation checklist & validation hooks               |
| 5     | `/optimize`         | Code review summary & optimization plan                   |
| 6     | `/debug`            | Error triage and remediation plan                         |
| 7     | `/ship-staging`     | Staging deployment ritual                                 |
| 8     | `/validate-staging` | Sign-off for staging                                      |
| 9     | `/ship-prod`        | Production launch and follow-up                           |
| -     | `/compact [phase]`  | **Optional:** Reduce token usage between phases           |

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
3. **Build roadmap**: Use `/roadmap` to add features as GitHub Issues (prioritized by creation order), organize via labels (status:backlog → status:next → status:in-progress → status:shipped).
4. Select a feature from GitHub Issues and launch `/feature "<feature-slug>"` in Claude to scaffold the spec from the issue.
5. Progress through `/clarify`, `/plan`, `/tasks`, and `/validate`, addressing blockers as they appear.
6. Use `calculate-tokens` to watch context budgets and `compact-context` to summarise when approaching thresholds.
7. Walk the release staircase: `/ship-staging`, `/validate-staging`, `/ship-prod`.
8. The feature is automatically marked as shipped in GitHub Issues (label changed to `status:shipped`, issue closed), and changelog is updated with the release.

## Epic-first repository map

- The canonical structure lives in `.spec-flow/repo-map.yaml`. It documents every major area (epics, specs, `.spec-flow/`, `.claude/`, docs, api, sample apps, etc.), including roles, responsibilities, boundaries, and where new code belongs.
- Domain-specific guides live in `.spec-flow/domains/` (e.g., `epics.yaml`, `workflow-engine.yaml`, `examples.yaml`) and explain how to extend those areas without breaking DRY rules.
- Epics are the top-level units of work. Each epic folder (`epics/<epic-slug>/`) owns `spec.md`, `plan.md`, `tasks.md`, sprint notes, and the authoritative `state.yaml`. Features under `specs/<feature>/` must reference their parent epic and stay subordinate to epic governance.
- Templates for new state files live in `.spec-flow/templates/epic-state.template.yaml` and `.spec-flow/templates/feature-state.template.yaml`. Automation and agents read/write these to coordinate manual and auto-driven phases.

## Using Spec-Flow with Codex CLI

- Install the repo-local prompt templates by running `spec-flow install-codex-prompts`. Use `--dry-run` to preview changes or `--force` to overwrite without prompts. Prompts live in `.codex/commands/` if you need to copy them manually.
- Epic prompts: `/prompts:spec-flow-epic-spec`, `/prompts:spec-flow-epic-plan`, `/prompts:spec-flow-epic-tasks`, `/prompts:spec-flow-epic-implement`, and `/prompts:spec-flow-epic-auto`. Each reads `.spec-flow/repo-map.yaml`, domain maps, and `epics/<slug>/state.yaml`, then runs exactly one phase (auto mode can advance only the next safe phase or two early stages before stopping).
- Feature prompts (parity with `/feature`): `/prompts:spec-flow-feature-spec`, `/prompts:spec-flow-feature-plan`, `/prompts:spec-flow-feature-tasks`, `/prompts:spec-flow-feature-implement`. They always read the parent epic’s state and never contradict it.
- Codex-specific prompts, skills, and adapters live in `.codex/`. Codex may read `.claude/**` for reference but only writes inside `.codex/` plus the usual repo areas (epics/, specs/, api/, etc.).
- Cursor follows the same rules via `.cursorrules` and `.cursor/` (prompts + adapters). Cursor also treats `.claude/**` as read-only.
- Manual vs auto: Run the phase-specific prompt when you want explicit control. `spec-flow-epic-auto` offers a guarded flow (spec → clarify → plan) that updates `state.yaml` after each phase and stops at review boundaries.
- Regardless of tool (Claude Code, Codex, Cursor, etc.), always honor the repo map, domain guides, and epic state before writing or refactoring files.

## Packages & Releases

- **npm**: Published as [`spec-flow`](https://www.npmjs.com/package/spec-flow). Install globally with `npm install -g spec-flow` or run one-off with `npx spec-flow`.
- **GitHub Packages**: The `Publish Packages` workflow mirrors each release to GitHub Packages under the scoped name `@marcusgoll/spec-flow`, enabling the repository's _Packages_ tab.
- **Automation**: Creating a GitHub release (or manually running the workflow) triggers the dual publish. Set the `NPM_TOKEN` repository secret with an npm automation token that has `publish` rights; GitHub packages use the built-in `GITHUB_TOKEN`.

## Troubleshooting

| Issue                                          | Resolution                                                                                        |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `pwsh` command not found                       | Install PowerShell 7 (`winget install Microsoft.PowerShell` or `brew install --cask powershell`). |
| Shell script reports missing feature directory | Run `/feature` first or use `create-new-feature` to scaffold `specs/NNN-slug`.                    |
| Token estimate returns zero                    | Verify files are UTF-8 encoded and not empty.                                                     |
| Context delta lacks checkpoints                | Ensure `NOTES.md` records checkpoints prefixed with `-`.                                          |

## Maintainers

- Marcus Gollahon ([@marcusgoll](https://x.com/marcusgoll))

* Community contributors join via pull requests!

## License

Released under the [MIT License](LICENSE).

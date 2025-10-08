# Changelog

All notable changes to the Spec-Flow Workflow Kit will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2025-10-08

### Added - Phase Agent Architecture & Performance Optimizations

**🚀 Optimized Workflow with Phase Agents:**
- **New `/spec-flow` orchestrator command** - Isolated context workflow with 67% token reduction and 2-3x speed improvement
- **10 phase agent files** - Each phase runs in isolated context for maximum efficiency:
  - `spec-phase-agent.md` - Specification creation
  - `clarify-phase-agent.md` - Clarification resolution (conditional)
  - `plan-phase-agent.md` - Planning and architecture
  - `tasks-phase-agent.md` - Task breakdown
  - `analyze-phase-agent.md` - Cross-artifact analysis
  - `implement-phase-agent.md` - Parallel implementation
  - `optimize-phase-agent.md` - Code review and optimization
  - `ship-staging-phase-agent.md` - Staging deployment
  - `ship-prod-phase-agent.md` - Production deployment
  - `finalize-phase-agent.md` - Documentation finalization
- **Structured phase summaries** - Each agent returns JSON summary with status, key decisions, artifacts
- **Auto-progression** - Phases advance automatically, pause at manual gates (/preview, /validate-staging)
- **Workflow state tracking** - Enhanced `.spec-flow/workflow-state.json` with phase summaries

**⚡ Performance Improvements:**
- **67% token reduction** - 240k → 80k tokens per feature via isolated contexts
- **2-3x faster execution** - No cumulative context bloat, no /compact overhead
- **Same quality** - All slash commands unchanged, proven workflow maintained
- **Easy rollback** - Original `/flow` command available as backup

**🔧 Local Project Support:**
- **Project type detection** - Auto-detects local-only, remote-staging-prod, remote-direct
  - `.spec-flow/scripts/bash/detect-project-type.sh`
  - `.spec-flow/scripts/powershell/detect-project-type.ps1`
- **Workflow adaptation** - Local projects skip deployment phases automatically
- **Manual deployment guidance** - Clear instructions for local-only workflows

**⚡ Quick Workflow for Small Changes:**
- **New `/quick` command** - KISS workflow for bug fixes, small refactors (<100 LOC, <30 min)
- **Minimal ceremony** - Skips spec/plan/tasks, goes straight to implementation
- **Quality gates maintained** - Tests required, code patterns followed

**🛡️ Installation Safety:**
- **Conflict detection system** - Detects existing files before installation
- **4 conflict resolution strategies**:
  - `merge` - Smart merge for CLAUDE.md, rename others (default, recommended)
  - `backup` - Create timestamped backups before overwriting
  - `skip` - Skip existing files, only install new
  - `force` - Overwrite everything (requires confirmation)
- **Pure Node.js CLI** - Cross-platform installation without bash/PowerShell dependencies
  - `bin/conflicts.js` - Conflict detection and resolution
  - `bin/install.js` - Core installation logic
  - `bin/install-wizard.js` - Interactive setup wizard
  - `bin/utils.js` - Shared utility functions
  - `bin/validate.js` - Pre-flight checks
- **Interactive prompts** - User chooses conflict resolution strategy
- **Non-interactive mode** - `--strategy` flag for CI/automation

**📝 Project Configuration:**
- **Constitution.md updates** - Project Configuration section with deployment models
- **Auto-detection** - Project type detected and stored in workflow state
- **Workflow adjustments** - Commands adapt based on project type

### Changed

**Command Naming:**
- Renamed old `spec-flow.md` → `specify.md` (specification creation)
- New `spec-flow.md` is now the optimized orchestrator
- `/flow` remains unchanged as backup

**Parallel Execution:**
- Enhanced `/implement` to use parallel agent execution via batch processing
- Tasks grouped by domain (backend/frontend/database/tests)
- TDD phases stay sequential, independent tasks run parallel

**Shipping Commands:**
- `/phase-1-ship` now checks for remote repo and staging branch
- `/phase-2-ship` validates remote repo and GitHub CLI availability
- Both commands provide clear guidance for local-only projects

**Documentation:**
- Updated README.md with phase agent architecture benefits
- Updated workflow examples to recommend `/spec-flow` over `/flow`
- Added `/quick` command to quick start examples
- Updated Development Phases table to use `/specify` for Phase 0

### Fixed

- Fixed typo in `bin/postinstall.js` (line 11: `\spec-flow` → `specify`)
- Security improvements in CLI (removed command injection vulnerabilities)
- Cross-platform path handling in Node.js scripts

## [1.0.0] - 2025-10-03

### Added
- **Complete Spec-Flow workflow** with 10 phases (spec → clarify → plan → tasks → analyze → implement → optimize → preview → phase-1-ship → validate-staging → phase-2-ship)
- **6 specialist agent briefs**: Backend, Frontend, QA, Senior Code Reviewer, Debugger, CI/CD Release
- **10+ slash command definitions** in `.claude/commands/`
- **Dual-platform automation scripts**: PowerShell (Windows/cross-platform) and Bash (macOS/Linux)
- **15+ Markdown templates** for specs, plans, tasks, analysis reports, optimization reports, release notes
- **Context management system**: Phase-based token budgets (75k/100k/125k) with auto-compaction
- **Complete working example**: Dark Mode Toggle feature (`specs/001-example-feature/`)
  - Specification with FR/NFR requirements
  - 28 tasks across 5 implementation phases
  - Performance benchmarks (145ms avg, 27% better than target)
  - WCAG 2.1 AA accessibility compliance
  - Cross-browser testing matrix
  - Release notes for v1.2.0
- **Comprehensive documentation** (7 pages):
  - `docs/getting-started.md` - 30-minute step-by-step tutorial
  - `docs/installation.md` - Platform-specific installation guide (Windows, macOS, Linux)
  - `docs/architecture.md` - Workflow state machine diagram and directory structure
  - `docs/commands.md` - Command reference catalog
  - `docs/troubleshooting.md` - Common issues and solutions
  - `docs/use-cases.md` - 8 project type examples (web apps, APIs, CLIs, mobile, design systems, infrastructure, docs, ML)
  - `CLAUDE.md` - AI agent guidance for working in this repository
- **GitHub Actions CI workflow** (`.github/workflows/ci.yml`):
  - Validates PowerShell scripts with PSScriptAnalyzer
  - Validates Bash scripts with ShellCheck
  - Validates Markdown with markdownlint
  - Validates JSON and YAML syntax
  - Checks repository structure and required files
  - Security scanning for secrets
- **40+ standardized issue labels** in `.github/labels.yml`
- **Security policy** (`SECURITY.md`) with vulnerability reporting process and response timelines
- **Code of Conduct** (`CODE_OF_CONDUCT.md`) with proper contact methods
- **Contribution guidelines** (`CONTRIBUTING.md`) with branching strategy and release process
- **Issue templates**: Bug report and enhancement proposal
- **PR template** with testing checklist
- **Linting configurations**: `.markdownlint.json`, `.markdown-link-check.json`

### Changed
- Renamed core command to `/spec-flow` (previously varied)
- Reorganized automation under `.spec-flow/` directory
- Updated `CODE_OF_CONDUCT.md` contact method (GitHub issues instead of non-existent email)
- Enhanced README with badges, "Why Spec-Flow?" section, quick start, and examples
- Enhanced `docs/architecture.md` with ASCII workflow state machine diagram and complete directory structure

### Fixed
- All placeholder URLs updated to actual repository: `https://github.com/marcusgoll/Spec-Flow`

## [1.2.0] - 2025-10-04

### Changed - Simplified Installation (KISS & DRY)
- **Removed interactive configuration wizard** - Installation now completes in seconds
- **QUICKSTART.md copied to project** - Local quick start guide for immediate reference
- **Let Claude Code do the work** - `/constitution`, `/roadmap`, `/design-inspiration` commands provide interactive Q&A
- **Simplified install flow** - No prompts during installation, just copy files and go
- **Removed `configure` command** - Configuration happens in Claude Code where it belongs

### Enhanced
- **QUICKSTART.md improvements**:
  - Added "Let Claude Code Set Up Your Project" section
  - Clear guidance on optional vs required setup
  - Interactive command examples with expected Claude responses
  - Emphasis on Claude Code's Q&A capabilities
- **Install wizard updates**:
  - Simpler next steps pointing to QUICKSTART.md
  - Clear indication that setup commands are optional
  - Removed configuration decision fatigue
- **Documentation cleanup**:
  - README.md updated to reflect simpler flow
  - Postinstall message now clearer and more concise
  - Help command simplified (no configure references)

### Removed
- `bin/configure.js` - Configuration wizard (moved to Claude Code slash commands)
- Configuration prompts from install wizard
- `spec-flow configure` command from CLI

### Improved
- **Faster installation**: 5 seconds vs several minutes
- **Less decision fatigue**: No prompts during install
- **More flexible**: Set up Constitution, Roadmap, Design Inspirations when ready
- **More powerful**: Claude Code's interactive commands > static wizard
- **Works everywhere**: Same simple flow for all project types

## [1.1.0] - 2025-10-04

### Added
- **Interactive configuration wizard** (`spec-flow configure`):
  - One question at a time with multiple choice options
  - Customizes constitution (project type, test coverage, performance targets, accessibility level)
  - Builds initial roadmap with ICE scoring (Impact × Confidence ÷ Effort)
  - Curates design inspirations (colors, typography, components, layouts)
  - Generates customized memory files based on user answers
- **Post-install configuration prompt** in install wizard:
  - Option to configure during installation or later
  - Automatically launches interactive wizard if user chooses "yes"
  - Shows configuration instructions if user skips
- **Initialization marker** (`.spec-flow/memory/.initialized`):
  - Tracks whether interactive configuration has been completed
  - Prevents duplicate configuration prompts
  - Enables smart MODE DETECTION in slash commands

### Changed
- Install wizard now prompts for configuration after file copy completes
- Constitution, roadmap, and design-inspirations memory files generated with user-specific values
- Help command updated to include `configure` command documentation
- Next steps in installation now context-aware (shows different steps based on configuration state)

### Improved
- Better first-run experience with guided setup
- Memory files start with meaningful defaults instead of placeholders
- Reduced manual configuration time from ~15 minutes to ~3 minutes

## [Unreleased]
- Future enhancements and features will be listed here

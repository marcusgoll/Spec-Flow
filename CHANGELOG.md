# Changelog

All notable changes to the Spec-Flow Workflow Kit will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

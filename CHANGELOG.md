# Changelog

All notable changes to the Spec-Flow Workflow Kit will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.14.0] - 2025-01-19

### Changed - Command Naming Clarity

**Problem**: Several slash commands had unclear or confusing names:
- `/spec-flow` - Collided with package name "spec-flow", unclear action
- `/specify` - Verbose, could be shorter
- `/phase-1-ship` & `/phase-2-ship` - Numbered phases not self-documenting
- `/checks` - Too generic, unclear what it checks
- `/analyze` - Could be more specific about validation purpose
- `/flow` - Too generic, doesn't indicate workflow orchestration
- `/measure-heart` - HEART acronym is implementation detail

**Solution**: Renamed 8 commands with self-documenting, clearer names

#### Command Renames (with backward compatibility)

| Old Command | New Command | Rationale |
|-------------|-------------|-----------|
| `/spec-flow` | `/feature` | Avoids package name collision, clearer action |
| `/specify` | `/spec` | Shorter, clearer, common terminology |
| `/phase-1-ship` | `/ship-staging` | Self-documents deployment target |
| `/phase-2-ship` | `/ship-prod` | Self-documents deployment target |
| `/checks` | `/fix-ci` | More specific about CI/deployment blockers |
| `/analyze` | `/validate` | More specific about validation purpose |
| `/flow` | `/workflow` | More descriptive orchestrator name |
| `/measure-heart` | `/metrics` | Simpler name, hides implementation detail |

#### Backward Compatibility

- **Old commands still work**: All 8 original commands maintained as aliases
- **Deprecation warnings**: Old commands show migration guidance when used
- **Removal timeline**: Old aliases will be removed in v2.0.0
- **Migration guide**: Each deprecated command links to new equivalent

#### Benefits
- ✅ **Self-documenting**: Command names clearly indicate what they do
- ✅ **No package confusion**: `/feature` avoids collision with "spec-flow" package
- ✅ **Easier onboarding**: New users understand commands without documentation
- ✅ **Gradual migration**: Old commands work while users migrate
- ✅ **Clear targets**: `/ship-staging` and `/ship-prod` are explicit about deployment

### Added
- **8 new command files**:
  - `.claude/commands/feature.md` - Feature workflow orchestrator
  - `.claude/commands/spec.md` - Specification creation
  - `.claude/commands/ship-staging.md` - Staging deployment
  - `.claude/commands/ship-prod.md` - Production deployment
  - `.claude/commands/fix-ci.md` - CI/deployment blocker fixes
  - `.claude/commands/validate.md` - Cross-artifact validation
  - `.claude/commands/workflow.md` - Original workflow orchestrator
  - `.claude/commands/metrics.md` - HEART metrics measurement

### Changed
- **8 deprecated command files**: Added deprecation warnings with migration guidance
  - `.claude/commands/spec-flow.md`
  - `.claude/commands/specify.md`
  - `.claude/commands/phase-1-ship.md`
  - `.claude/commands/phase-2-ship.md`
  - `.claude/commands/checks.md`
  - `.claude/commands/analyze.md`
  - `.claude/commands/flow.md`
  - `.claude/commands/measure-heart.md`

- **Documentation updates**:
  - `CLAUDE.md` - Updated all workflow diagrams and command references
  - `README.md` - Updated 15+ command examples throughout
  - Updated workflow state machine diagrams
  - Updated deployment model descriptions
  - Updated command artifacts table

### Files Modified
- 8 new command files created (16 total with deprecation)
- `CLAUDE.md` - Complete command reference update
- `README.md` - All examples and documentation
- `CHANGELOG.md` - This entry

**Impact**: Users can now understand command purposes without consulting documentation. The renaming follows industry conventions (e.g., `/ship-staging`, `/ship-prod`) and improves discoverability.

## [1.13.0] - 2025-01-19

### Added - Local Project Integration Workflow

**Problem**: Local dev projects had disconnect between `/optimize` and roadmap updates:
- No explicit merge to main/master branch after build
- Roadmap marked "Shipped" before integration to main branch
- Version tag created on feature branch instead of main
- Feature code remained isolated on feature branch

**Solution**: New Phase S.4.5a (Local Integration) in `/ship` workflow

#### New Phase S.4.5a: Merge to Main
- **Auto-detects main branch**: Supports both `main` and `master` branch names
- **Preserves feature history**: Uses `--no-ff` merge to maintain branch context
- **Remote sync**: Automatically pushes to origin if remote exists
- **Branch cleanup**: Offers to delete feature branch locally and remotely after merge
- **Conflict handling**: Pauses on conflicts, allows resolution, then `/ship continue`
- **Correct sequencing**: Runs AFTER `/build-local` and BEFORE `/finalize`

#### Updated Workflow for local-only Projects
**Before**: `optimize → preview → build-local → finalize` ❌ (stayed on feature branch)

**After**: `optimize → preview → build-local → merge-to-main → finalize` ✅ (integrated to main)

#### Benefits
- ✅ **Clear integration path**: Local projects now have explicit merge step
- ✅ **Correct sequencing**: Merge happens BEFORE version bump and roadmap update
- ✅ **Roadmap accuracy**: Feature marked "Shipped" AFTER integration (not before)
- ✅ **Git best practices**: Version tag created on main branch (not feature branch)
- ✅ **Safe workflow**: Runs after all validations and builds pass
- ✅ **Flexible**: Works with or without git remote

### Changed
- **`.claude/commands/ship.md`**:
  - Added Phase S.4.5a between build-local and finalize for local-only model
  - Updated workflow descriptions: `local-only: ... → Build-Local → Merge-to-Main → Finalize`
  - Added main branch detection logic (main or master)
  - Added conflict handling and recovery instructions

- **`.claude/commands/build-local.md`**:
  - Updated "Next Steps" to instruct running `/ship continue`
  - Added workflow diagram showing 3-step process
  - Clarified that merge happens automatically in `/ship`
  - Added note that version bump and roadmap update happen after merge

### Files Modified
- `.claude/commands/ship.md` - Added Phase S.4.5a (local integration)
- `.claude/commands/build-local.md` - Updated documentation for new workflow

**Impact**: Local-only projects now have complete parity with remote deployment models - all features properly integrate to main branch before being marked "Shipped" in roadmap.

## [1.12.1] - 2025-01-19

### Changed
- **Simplified update command**: Removed backup creation overhead for faster, cleaner updates
- **Removed `--force` flag**: No longer needed (kept for backwards compatibility)
- **Updated CLI output**: Shows "Templates updated, user data preserved" message after update

### Removed
- Backup creation logic from `update()` function (116 lines removed)
- Backup restoration on error handling
- `BACKUP_DIRECTORIES` constant and related exports
- `createBackup` and `restoreBackup` import references from update flow

### Improved
- **Faster updates**: No backup overhead, instant template updates
- **Cleaner user experience**: No backup folders to manually clean up
- **User data still safe**: `preserveMemory` flag protects learnings.md, memory, and specs

**Why This Change?** The `preserveMemory` flag already protects user data during updates. Backups created redundant `*-backup-*` folders that users had to manually delete. This change simplifies the update process while maintaining safety.

## [1.12.0] - 2025-01-19

### Added - Learnings Persistence & Design Iteration

#### Part 1: Learnings Persistence (All 16 Skills)
- **Created `learnings.md` for all 16 phase skills**: Separated auto-updating data from SKILL.md templates
- **Two-file architecture**:
  - `SKILL.md` - Template with static guidance (updated with npm)
  - `learnings.md` - Dynamic data (preserved across npm updates)
- **Auto-tracking system**:
  - Pitfall frequencies: ⭐☆☆☆☆ → ⭐⭐⭐☆☆ as issues occur
  - Pattern usage counts and success rates
  - Metrics averages (test coverage, code reuse, accessibility scores, etc.)
- **Zero manual intervention**: System learns automatically as you work

**Skills with learnings.md**: specification-phase, clarification-phase, planning-phase, task-breakdown-phase, analysis-phase, implementation-phase, optimization-phase, debug-phase, preview-phase, staging-validation-phase, staging-deployment-phase, checks-phase, production-deployment-phase, finalize-phase, roadmap-integration, ui-ux-design

#### Part 2: Design Iteration Enhancements
- **Screen-specific targeting**: `/design-variations $SLUG [$SCREEN]` - iterate on single component
- **Overwrite protection**: Warns before regenerating variants, offers [b]ackup to create git tag
- **Re-enable support**: Can enable design workflow after initially declining in `/spec-flow`
- **Iteration patterns guide**: New file `.claude/skills/ui-ux-design/iteration-patterns.md` with 5 common scenarios:
  1. Iterate on specific component
  2. Initially skipped, now want design workflow
  3. Refine after initial exploration
  4. A/B test alternative design
  5. Iterate on specific state

### Changed
- **Updated all 16 SKILL.md files**: Replaced inline frequencies/metrics with references to learnings.md
- **Enhanced design-variations.md**:
  - Added optional screen parameter for targeted iteration
  - Added screen filtering logic to all variant generation loops
  - Added overwrite detection with interactive [c]ontinue/[b]ackup/[a]bort prompt
- **Enhanced spec-flow.md**:
  - Detects if `design_workflow.enabled=false` (previously skipped)
  - Shows re-enable prompt: "⚠️ Design workflow was previously skipped for this feature"

### Documentation
- **New README section**: "Skills & Learning System" explaining two-file architecture
- **Learnings persistence**: What gets updated vs preserved across npm updates
- **Auto-learning triggers**: When and how skills update automatically

### Files Changed
- **36 files total**: 16 learnings.md created, 16 SKILL.md updated, 3 command files enhanced, 1 new iteration guide

## [1.5.3] - 2025-10-08

### Fixed - Complete Installation Safety for Brownfield Projects

**Problem**: The `npx spec-flow init` command (both interactive and non-interactive modes) was missing user data protection, potentially overwriting existing directories in brownfield projects.

**Solution - Universal Data Protection**:
- Added `excludeDirectories: USER_DATA_DIRECTORIES` to both installation modes in `install-wizard.js`
- Non-interactive mode (line 33): Now protects user directories during automated installations
- Interactive mode (line 183): Now protects user directories during guided installations
- Ensures identical protection across `init` and `update` commands

**Changes**:
- `bin/install.js`: Exported `USER_DATA_DIRECTORIES` constant for use in wizard
- `bin/install-wizard.js`: Imported and applied `USER_DATA_DIRECTORIES` to both install() calls
- Both greenfield and brownfield installations now safe by default

**Safety**: All npx commands (`init`, `update`) now respect user data boundaries. Directories like `specs/`, `node_modules/`, `.git/`, etc. are never touched during installation or updates.

## [1.5.2] - 2025-10-08

### Fixed - CRITICAL: Data Loss Prevention in Update Command

**Problem**: Running `npx spec-flow update` in brownfield projects could potentially overwrite user-generated content, including the `specs/` directory containing all feature work.

**Solution - Comprehensive User Data Protection**:
- Added explicit exclusion list for user-generated directories (`specs/`, `node_modules/`, `.git/`, `dist/`, etc.)
- Enhanced backup system to backup ALL user directories before update, not just memory files
- Updated `copyDirectory()` to skip excluded directories entirely (prevents any accidental overwrites)
- Improved restore mechanism to restore all backed-up directories if update fails
- Added user-friendly backup reporting in CLI (shows which directories were backed up)

**Changes**:
- `bin/install.js`: Added `USER_DATA_DIRECTORIES` constant with critical exclusions
- `bin/install.js`: Updated `update()` to backup all user data before proceeding
- `bin/install.js`: Enhanced error handling to restore ALL backups on failure
- `bin/utils.js`: Updated `copyDirectory()` to honor `excludeDirectories` option
- `bin/cli.js`: Updated CLI to display backup information to user

**Safety**: Backups now created with timestamps and preserved after update. Users can safely remove `*-backup-*` folders when confident.

## [1.5.1] - 2025-10-08

### Fixed

**Phase 4 Implementation Architecture:**
- Fixed sub-agent spawning limitation in `/spec-flow` workflow
- Phase 4 now calls `/implement` slash command directly instead of using `implement-phase-agent`
- Reason: Sub-agents cannot spawn other sub-agents, and `/implement` needs to spawn parallel worker agents (backend-dev, frontend-shipper, etc.)
- Updated documentation in `spec-flow.md`, `README.md`, and architecture diagrams
- Note: `implement-phase-agent.md` remains in codebase for reference but is bypassed in the workflow

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

**Phase 4 Implementation Architecture:**
- Phase 4 now calls `/implement` directly instead of using `implement-phase-agent`
- Reason: Sub-agents cannot spawn other sub-agents, and `/implement` needs to spawn parallel worker agents
- Note: `implement-phase-agent.md` remains in codebase but is bypassed in actual workflow

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

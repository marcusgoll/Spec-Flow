# Release Notes

## v1.6.1 (2025-10-16)

### 🐛 Bug Fixes

#### Improved Brownfield Project Onboarding

**Problem:**
Running `npx spec-flow init` in brownfield projects with existing `.claude` or `.spec-flow` directories would fail with an unhelpful error message, forcing users to manually discover and run `npx spec-flow update`. This created a poor onboarding experience where the installation wizard felt "just for show."

**Solution:**
The `init` command now intelligently detects existing installations and seamlessly guides users through the update process:

**Interactive Mode:**
- Detects existing Spec-Flow installation
- Shows current installation status (`.claude`, `.spec-flow` directories)
- Prompts user: "Update existing installation (recommended)" or "Cancel"
- Automatically runs update workflow with proper backups
- Displays clear next steps after successful update

**Non-Interactive Mode:**
- Auto-detects existing installation
- Automatically runs update without user intervention
- Perfect for CI/CD pipelines and automation scripts

**Before:**
```bash
$ npx spec-flow init
✗ Already installed. Use update command or remove existing installation.
# User forced to know about separate update command
```

**After (Interactive):**
```bash
$ npx spec-flow init
⚠ Spec-Flow is already installed in this directory
  .claude directory: ✓
  .spec-flow directory: ✓

? What would you like to do?
  ❯ Update existing installation (recommended) - Preserves your data
    Cancel installation

✓ Update complete!

Next steps:
  1. Open project in Claude Code
  2. Run /roadmap to plan features
  3. Run /spec-flow "feature-name" to start building
```

**After (Non-Interactive):**
```bash
$ npx spec-flow init --non-interactive
Auto-updating existing installation...
✓ Update complete!
```

### 📝 Files Changed

- **bin/install-wizard.js**: Added early installation detection and guided update flow
- **bin/install.js**: Improved error messages with actionable guidance
- **package.json**: Version bump to 1.6.1

### 🎯 Impact

- ✅ Brownfield projects can now use `init` command without being blocked
- ✅ Non-interactive mode (CI/automation) auto-updates seamlessly
- ✅ Users get clear, actionable guidance instead of cryptic errors
- ✅ Onboarding is fully functional, not "just for show"

### 📦 Installation

```bash
npm install -g spec-flow@1.6.1
```

Or upgrade from 1.6.0:
```bash
npm update -g spec-flow
```

---

## v1.6.0 (2025-10-16)

### 🎉 Major Features

This release introduces three major enhancements to the Spec-Flow workflow toolkit:

#### YAML State Management

**What's New:**
- All workflow state files now use YAML format instead of JSON
- Improved LLM editability with human-friendly syntax
- Support for inline comments in state files
- Auto-migration from JSON to YAML with backward compatibility

**Benefits:**
- Easier for AI agents to read and modify state
- Better version control diffs
- Human-readable with inline documentation
- Reduced parsing errors

**Migration:**
- Existing JSON files auto-migrate on first access
- Batch migration utility: `.spec-flow/scripts/bash/migrate-state-to-yaml.sh`
- Originals preserved as `.json.backup`
- Schema version: 1.0.0 → 2.0.0

**Prerequisites:**
- `yq` v4.0+ (replaces `jq` for YAML processing)
- PowerShell: `powershell-yaml` module

#### Roadmap Integration

**What's New:**
- Automatic roadmap lifecycle tracking throughout workflow
- `/spec-flow` command marks features as "In Progress"
- `/ship` command marks features as "Shipped" with metadata
- Feature discovery system during implementation
- Interactive prompts for discovered features

**Roadmap Lifecycle:**
```
Backlog → Later → Next → In Progress → Shipped
```

**Feature Discovery:**
- Detects patterns: "TODO", "future work", "phase 2", "out of scope"
- Prompts: Add now, save for later, or skip
- Deferred features saved to `.spec-flow/memory/discovered-features.md`

**Scripts:**
- `.spec-flow/scripts/bash/roadmap-manager.sh` (313 lines)
- `.spec-flow/scripts/powershell/roadmap-manager.ps1` (560 lines)

#### Automated Version Management

**What's New:**
- Semantic versioning with intelligent auto-detection
- Version bumping integrated into `/ship` workflow (Phase S.5)
- Auto-generated release notes from ship reports
- Git tag creation with annotated messages
- npm package version synchronization

**Versioning Logic:**
- Breaking changes → MAJOR bump (e.g., 1.5.3 → 2.0.0)
- Bug fixes/patches → PATCH bump (e.g., 1.5.3 → 1.5.4)
- New features → MINOR bump (e.g., 1.5.3 → 1.6.0)

**Process:**
1. Read current version from `package.json`
2. Analyze spec and ship report for bump type
3. Calculate new version
4. Update `package.json`
5. Create annotated git tag (e.g., `v1.6.0`)
6. Generate release notes
7. Update roadmap with version number

**Scripts:**
- `.spec-flow/scripts/bash/version-manager.sh` (464 lines)
- `.spec-flow/scripts/powershell/version-manager.ps1` (512 lines)

### 📝 Documentation Updates

- **constitution.md**: v1.0.0 → v1.1.0
  - Added "Roadmap Management" section
  - Added "Version Management" section
  - Documented automatic transitions and policies

- **CLAUDE.md**: Added "New Features (v1.1.0)" section
  - YAML state files documentation
  - Roadmap integration guide
  - Version management instructions

- **README.md**: Updated prerequisites
  - Added `yq` installation instructions
  - Added `powershell-yaml` module requirement

### 🔧 Command Updates

**Updated Commands:**
- `/spec-flow`: Integrated roadmap marking (in progress)
- `/ship`: Integrated version management and roadmap updates (shipped)
- `/ship-status`: YAML state compatibility
- `/build-local`: YAML state compatibility
- `/deploy-prod`: YAML state compatibility
- `/phase-1-ship`: YAML state compatibility
- `/validate-staging`: YAML state compatibility

**State File Migration:**
- All `jq` commands replaced with `yq` equivalents
- State file references: `workflow-state.json` → `workflow-state.yaml`

### 📦 New Scripts

**Bash Scripts:**
1. `.spec-flow/scripts/bash/migrate-state-to-yaml.sh` (203 lines)
2. `.spec-flow/scripts/bash/roadmap-manager.sh` (313 lines)
3. `.spec-flow/scripts/bash/version-manager.sh` (464 lines)
4. `.spec-flow/scripts/bash/workflow-state.sh` (456 lines, updated)

**PowerShell Scripts:**
1. `.spec-flow/scripts/powershell/migrate-state-to-yaml.ps1` (221 lines)
2. `.spec-flow/scripts/powershell/roadmap-manager.ps1` (560 lines)
3. `.spec-flow/scripts/powershell/version-manager.ps1` (512 lines)
4. `.spec-flow/scripts/powershell/workflow-state.ps1` (updated)

### 📊 Statistics

- **27 files changed**: 10,504 insertions(+), 1,720 deletions(-)
- **8 new scripts**: 4 bash, 4 PowerShell
- **14 files updated**: Commands and documentation
- **Total new code**: ~2,600 lines of production scripts

### 🔄 Migration Guide

**For Existing Projects:**

1. **Install yq** (required):
   ```bash
   # macOS
   brew install yq

   # Linux
   curl -LO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
   sudo mv yq_linux_amd64 /usr/local/bin/yq
   sudo chmod +x /usr/local/bin/yq

   # Windows
   choco install yq
   ```

2. **Install PowerShell-yaml** (Windows only):
   ```powershell
   Install-Module -Name powershell-yaml -Scope CurrentUser
   ```

3. **Migrate existing features**:
   ```bash
   # Dry run (preview changes)
   .spec-flow/scripts/bash/migrate-state-to-yaml.sh --dry-run

   # Execute migration
   .spec-flow/scripts/bash/migrate-state-to-yaml.sh
   ```

4. **Verify migration**:
   ```bash
   # Check for YAML files
   find specs -name "workflow-state.yaml"

   # Verify backups exist
   find specs -name "workflow-state.json.backup"
   ```

### 🐛 Bug Fixes

- None (feature release)

### ⚠️ Breaking Changes

- **State files now use YAML format** (auto-migration provided)
- **yq v4.0+ now required** (replaces jq for state management)
- **PowerShell scripts require powershell-yaml module**

### 🔮 Future Enhancements

Potential features discovered during implementation:
- Interactive CLI for version management
- Rollback capability testing in staging
- Performance benchmarking integration
- HEART metrics tracking
- Design variation workflows

### 🙏 Acknowledgments

This release was built entirely through AI-assisted development using Claude Code, demonstrating the power of the Spec-Flow workflow for feature delivery.

---

**Installation:**
```bash
npm install -g spec-flow@1.6.0
```

**Upgrade:**
```bash
npm update -g spec-flow
```

**Documentation:**
- GitHub: https://github.com/marcusgoll/Spec-Flow
- Issues: https://github.com/marcusgoll/Spec-Flow/issues

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

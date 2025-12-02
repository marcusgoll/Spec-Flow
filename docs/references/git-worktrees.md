# Git Worktrees (v10.0+)

Enables parallel development of multiple epics and features by running separate Claude Code instances in isolated git worktrees.

## Overview

Git worktrees allow multiple working directories for the same repository, enabling simultaneous work on different branches without conflicts. Each epic/feature gets its own worktree with shared memory linking for observability and learning data.

**Key benefits**:

- Run multiple Claude Code instances simultaneously
- Work on multiple epics/features in parallel
- Isolated workspaces prevent branch conflicts
- Shared memory for cross-worktree observability
- Automatic cleanup after feature completion

## How It Works

**Traditional workflow** (single branch):

```bash
# Must switch branches and stash changes
git checkout main
git checkout -b feature/login
# Work on login
git checkout main
git checkout -b feature/dashboard  # Can't work on both simultaneously
```

**Worktree workflow** (parallel development):

```bash
# Epic 1 in main directory
/epic "auth system"
# → Creates worktree: worktrees/epic/001-auth-system/

# Epic 2 in new Claude Code instance
cd worktrees/epic/002-user-dashboard/
/epic continue
# → Both epics work independently without conflicts
```

## Automatic Worktree Creation

When enabled via `/init-preferences`, worktrees are automatically created during `/epic` and `/feature` commands:

**Epic workflow**:

```bash
/epic "auth system"
# → Step 1: Branch and worktree creation
#   - Creates branch: epic/001-auth-system
#   - Creates worktree: worktrees/epic/001-auth-system/
#   - Links .spec-flow/memory/ via symlink
#   - Switches context to worktree directory
```

**Feature workflow**:

```bash
/feature "user login"
# → Creates branch: feature/001-user-login
# → Creates worktree: worktrees/feature/001-user-login/
# → Links shared memory
```

## Workspace Isolation

Each worktree maintains isolated workspace:

**Isolated** (per-worktree):

- Working directory files
- Branch-specific code
- Epic/feature artifacts (specs/, epics/)
- Git staging area

**Shared** (via symlinks):

- `.spec-flow/memory/` — Workflow mechanics and observation data
- Learning observations collected in main repo
- Command history and execution logs

## Directory Structure

```
my-project/                        # Main repository
├── .git/                          # Git database
├── .spec-flow/
│   ├── memory/                    # Shared across worktrees (symlinked)
│   ├── learnings/                 # Shared learning data
│   └── config/
├── worktrees/                     # Worktree container (gitignored)
│   ├── epic/
│   │   ├── 001-auth-system/       # Epic 1 workspace
│   │   │   ├── .spec-flow/
│   │   │   │   └── memory -> ../../../.spec-flow/memory  # Symlink
│   │   │   ├── epics/
│   │   │   │   └── 001-auth-system/
│   │   │   └── [project files]
│   │   └── 002-user-dashboard/    # Epic 2 workspace
│   │       └── [isolated files]
│   └── feature/
│       ├── 001-user-login/        # Feature 1 workspace
│       └── 002-password-reset/    # Feature 2 workspace
```

## Memory Linking Strategy

**Symlink creation** (Linux/Mac/Git Bash):

```bash
ln -s ../../../.spec-flow/memory worktrees/epic/001-auth-system/.spec-flow/memory
```

**Junction creation** (Windows PowerShell):

```powershell
New-Item -ItemType Junction -Path "worktrees\epic\001-auth-system\.spec-flow\memory" `
         -Target ".spec-flow\memory"
```

**Benefits**:

- Observations from all worktrees collected centrally
- Learning system sees patterns across all parallel work
- Workflow health metrics aggregate across epics
- No data duplication or synchronization needed

## Worktree Lifecycle

**1. Creation** (automatic):

```bash
# Via /epic or /feature with worktrees.auto_create: true
bash .spec-flow/scripts/bash/worktree-manager.sh create epic 001-auth-system epic/001-auth-system
```

**2. Active Development**:

- Work proceeds normally in worktree directory
- All workflow commands function identically
- Observations collected to shared memory

**3. Cleanup** (automatic on /finalize):

```bash
# After /ship-prod or /deploy-prod completes
# Triggered during /finalize if worktrees.cleanup_on_finalize: true
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system
```

**Manual cleanup**:

```bash
# List all worktrees
bash .spec-flow/scripts/bash/worktree-manager.sh list

# Cleanup merged worktrees
bash .spec-flow/scripts/bash/worktree-manager.sh cleanup

# Remove specific worktree
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system
```

## Configuration

Enable/disable via `/init-preferences` or edit `.spec-flow/config/user-preferences.yaml`:

```yaml
worktrees:
  # Automatically create worktrees for epics/features
  # Default: false (use regular branches)
  auto_create: false

  # Automatically cleanup worktrees after /finalize
  # Default: true (recommended)
  cleanup_on_finalize: true
```

**Recommendation**: Keep `auto_create: false` unless you regularly work on multiple epics/features simultaneously.

## Detection and Path Resolution

Worktree detection is integrated into `detect-workflow-paths.sh/ps1`:

**Output includes worktree info**:

```json
{
  "type": "epic",
  "base_dir": "epics",
  "slug": "001-auth-system",
  "branch": "epic/001-auth-system",
  "source": "files",
  "is_worktree": true,
  "worktree_path": "worktrees/epic/001-auth-system",
  "worktree_type": "epic",
  "worktree_slug": "001-auth-system"
}
```

## Scripts and Utilities

**Worktree Management**:

- `.spec-flow/scripts/bash/worktree-manager.sh` - CRUD operations
- `.spec-flow/scripts/powershell/worktree-manager.ps1` - Windows version

**Commands**:

```bash
# Create worktree
worktree-manager.sh create <type> <slug> <branch>

# List all worktrees
worktree-manager.sh list [--json]

# Remove worktree
worktree-manager.sh remove <slug> [--force]

# Cleanup merged worktrees
worktree-manager.sh cleanup [--dry-run]

# Check if path is a worktree
worktree-manager.sh is-worktree [path]
```

**Detection**:

- `.spec-flow/scripts/utils/detect-workflow-paths.sh` - Enhanced with worktree detection
- `.spec-flow/scripts/utils/detect-workflow-paths.ps1` - Windows version

## Integration with Commands

**Epic command** (`.claude/commands/epic/epic.md`):

- Step 1: Checks `worktrees.auto_create` preference
- Creates worktree instead of regular branch if enabled
- Switches to worktree directory automatically

**Feature command** (`.spec-flow/scripts/bash/create-new-feature.sh`):

- Integrated worktree creation with fallback to branches
- Updates feature directory path to worktree location

**Finalize command** (`.spec-flow/scripts/bash/finalize-workflow.sh`):

- Step 11: Checks `worktrees.cleanup_on_finalize` preference
- Removes worktree after successful deployment
- Preserves main repository state

## Use Cases

**1. Parallel Epic Development**:

```bash
# Terminal 1 - Backend epic
cd ~/projects/myapp
/epic "authentication system"

# Terminal 2 - Frontend epic (new Claude Code instance)
cd ~/projects/myapp/worktrees/epic/002-dashboard-redesign
/epic continue
```

**2. Epic + Urgent Hotfix**:

```bash
# Working on epic in main directory
/epic continue  # Long-running implementation

# Urgent bug reported (new terminal)
cd ~/projects/myapp/worktrees/feature/urgent-fix
/feature "fix critical login bug"
/implement
/ship
# → Epic work continues uninterrupted in main directory
```

**3. Multiple Team Members**:

```bash
# Developer A - Epic 1
/epic "payment integration"

# Developer B - Epic 2 (different machine/worktree)
/epic "notification system"

# Both share learnings via git-committed .spec-flow/learnings/
```

## Troubleshooting

**Symlink creation fails**:

- Windows: Run as Administrator or enable Developer Mode
- Linux/Mac: Check permissions on .spec-flow/memory/

**Worktree not detected**:

```bash
# Verify git worktree list
git worktree list

# Check detection utility
bash .spec-flow/scripts/utils/detect-workflow-paths.sh
```

**Cleanup fails**:

```bash
# Force remove worktree
bash .spec-flow/scripts/bash/worktree-manager.sh remove 001-auth-system --force

# Manually remove via git
git worktree remove worktrees/epic/001-auth-system --force
```

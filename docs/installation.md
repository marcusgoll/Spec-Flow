# Installation Guide

This guide provides detailed, platform-specific installation instructions for Spec-Flow.

## Table of Contents

- [Quick Install](#quick-install)
- [Prerequisites](#prerequisites)
- [Platform-Specific Instructions](#platform-specific-instructions)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Post-Installation Setup](#post-installation-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Quick Install

**For the impatient**:

```bash
# Clone the repository
git clone https://github.com/your-org/spec-flow-workflow-kit.git
cd spec-flow-workflow-kit

# Copy settings
cp .claude/settings.example.json .claude/settings.local.json

# Edit settings and add your project paths
# Then verify installation
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json
# OR
.spec-flow/scripts/bash/check-prerequisites.sh --json
```

If all checks pass ✅, you're ready! Continue to [Getting Started](getting-started.md).

## Prerequisites

### Required

| Tool | Minimum Version | Installation Guide |
|------|----------------|-------------------|
| **Git** | 2.39+ | [git-scm.com](https://git-scm.com/downloads) |
| **PowerShell** (Windows) | 7.3+ | [See Windows section](#windows) |
| **Bash** (macOS/Linux) | 5.0+ | Included with OS |
| **Python** | 3.10+ | [python.org](https://www.python.org/downloads/) |
| **Claude Code** | Latest | [claude.com/code](https://claude.com/code) |

### Optional

| Tool | Purpose | Installation |
|------|---------|--------------|
| **GitHub CLI** (`gh`) | Auto-merge helpers | [cli.github.com](https://cli.github.com/) |
| **Pester 5** | PowerShell test suites | `Install-Module -Name Pester -Force` |
| **jq** | JSON parsing in shell scripts | [stedolan.github.io/jq](https://stedolan.github.io/jq/) |

## Platform-Specific Instructions

### Windows

#### 1. Install Git
```powershell
# Using winget (recommended)
winget install Git.Git

# Verify
git --version
# Expected: git version 2.39 or higher
```

#### 2. Install PowerShell 7.3+
```powershell
# Using winget
winget install Microsoft.PowerShell

# Verify
pwsh --version
# Expected: PowerShell 7.3 or higher
```

**Important**: Use `pwsh` (PowerShell 7+), not `powershell` (Windows PowerShell 5.1).

#### 3. Install Python 3.10+
```powershell
# Using winget
winget install Python.Python.3.12

# Verify
python --version
# Expected: Python 3.10 or higher
```

#### 4. Install Claude Code
1. Download from [claude.com/code](https://claude.com/code)
2. Run the installer
3. Follow the setup wizard
4. Verify installation:
   ```powershell
   claude --version
   ```

#### 5. Clone Spec-Flow
```powershell
# Navigate to your projects directory
cd C:\Projects

# Clone the repository
git clone https://github.com/your-org/spec-flow-workflow-kit.git
cd spec-flow-workflow-kit
```

#### 6. Optional: Install GitHub CLI
```powershell
winget install GitHub.cli

# Verify
gh --version
```

### macOS

#### 1. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Git
```bash
# Usually pre-installed, but update to latest
brew install git

# Verify
git --version
# Expected: git version 2.39 or higher
```

#### 3. Install PowerShell 7.3+ (Cross-Platform)
```bash
brew install --cask powershell

# Verify
pwsh --version
# Expected: PowerShell 7.3 or higher
```

**Note**: macOS includes Bash by default, but you can use PowerShell for cross-platform consistency.

#### 4. Install Python 3.10+
```bash
brew install python@3.12

# Verify
python3 --version
# Expected: Python 3.10 or higher
```

#### 5. Install Claude Code
1. Download from [claude.com/code](https://claude.com/code)
2. Open the `.dmg` file
3. Drag Claude Code to Applications
4. Verify installation:
   ```bash
   claude --version
   ```

#### 6. Clone Spec-Flow
```bash
# Navigate to your projects directory
cd ~/Projects

# Clone the repository
git clone https://github.com/your-org/spec-flow-workflow-kit.git
cd spec-flow-workflow-kit
```

#### 7. Optional: Install GitHub CLI
```bash
brew install gh

# Verify
gh --version
```

### Linux

#### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Git
sudo apt install git

# Install PowerShell (optional, cross-platform)
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Update package list
sudo apt update

# Install PowerShell
sudo apt install -y powershell

# Verify
pwsh --version
```

#### Fedora/RHEL/CentOS

```bash
# Install Git
sudo dnf install git

# Install PowerShell
# Register the Microsoft RedHat repository
curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
sudo dnf install powershell

# Verify
pwsh --version
```

#### Arch Linux

```bash
# Install Git
sudo pacman -S git

# Install PowerShell from AUR
yay -S powershell-bin

# Verify
pwsh --version
```

#### Python 3.10+

```bash
# Ubuntu/Debian
sudo apt install python3 python3-pip

# Fedora/RHEL
sudo dnf install python3 python3-pip

# Arch
sudo pacman -S python python-pip

# Verify
python3 --version
```

#### Clone Spec-Flow

```bash
# Navigate to your projects directory
cd ~/projects

# Clone the repository
git clone https://github.com/your-org/spec-flow-workflow-kit.git
cd spec-flow-workflow-kit
```

## Post-Installation Setup

### 1. Configure Claude Code Permissions

Copy the example settings:

```bash
cp .claude/settings.example.json .claude/settings.local.json
```

Edit `.claude/settings.local.json` and add your project paths:

```json
{
  "permissions": {
    "allow": [
      "Read(/absolute/path/to/your/project)",
      "Write(/absolute/path/to/your/project)",
      "Edit(/absolute/path/to/your/project)",
      "Bash(/absolute/path/to/your/project)"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Platform-specific paths**:
- **Windows**: `C:\\Users\\YourName\\Projects\\your-project`
- **macOS/Linux**: `/Users/yourname/projects/your-project`

**Pro tip**: Use absolute paths to avoid permission issues.

### 2. Set Execution Policy (Windows PowerShell Only)

If using Windows, ensure PowerShell scripts can execute:

```powershell
# Check current policy
Get-ExecutionPolicy

# If it's "Restricted", change it:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Make Shell Scripts Executable (macOS/Linux)

```bash
chmod +x .spec-flow/scripts/bash/*.sh
```

### 4. Verify Spec-Flow Directory Structure

Your repository should have:

```
spec-flow-workflow-kit/
├── .claude/
│   ├── agents/
│   ├── commands/
│   └── settings.example.json
├── .spec-flow/
│   ├── scripts/
│   │   ├── powershell/
│   │   └── bash/
│   ├── templates/
│   └── memory/
├── docs/
├── specs/
└── README.md
```

### 5. Initialize Memory Files (First-Time Setup)

Create your engineering constitution:

```bash
# In Claude Code
/constitution
```

This creates `.spec-flow/memory/constitution.md` with your team's principles.

Initialize your roadmap:

**Windows**:
```powershell
pwsh -File .spec-flow/scripts/powershell/roadmap-init.ps1
```

**macOS/Linux**:
```bash
.spec-flow/scripts/bash/roadmap-init.sh
```

This creates `.spec-flow/memory/roadmap.md` for tracking features.

## Verification

Run the prerequisite checker to verify everything is installed:

**Windows (PowerShell)**:
```powershell
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json
```

**macOS/Linux (Bash)**:
```bash
.spec-flow/scripts/bash/check-prerequisites.sh --json
```

### Expected Output

```json
{
  "status": "ready",
  "checks": {
    "git": { "installed": true, "version": "2.39.0" },
    "pwsh": { "installed": true, "version": "7.4.0" },
    "python": { "installed": true, "version": "3.12.0" },
    "claude": { "installed": true, "version": "1.0.0" }
  },
  "warnings": [],
  "errors": []
}
```

If you see `"status": "ready"`, you're all set! ✅

## Troubleshooting

### "pwsh: command not found"

**Solution**: Install PowerShell 7.3+ (see platform instructions above). On macOS/Linux, you can also use the Bash scripts instead.

### "Permission denied" when running scripts

**Windows**: Set execution policy (see [Post-Installation Setup](#2-set-execution-policy-windows-powershell-only))

**macOS/Linux**: Make scripts executable:
```bash
chmod +x .spec-flow/scripts/bash/*.sh
```

### "Python not found"

**Solution**: Ensure Python is in your PATH. On Windows, reinstall Python and check "Add Python to PATH" during installation.

### "Claude Code not accessible"

**Solution**:
1. Verify Claude Code is installed and running
2. Check `.claude/settings.local.json` has correct project paths
3. Restart Claude Code after updating settings

### "Git version too old"

**Solution**: Update Git to 2.39+:
- **Windows**: `winget upgrade Git.Git`
- **macOS**: `brew upgrade git`
- **Linux**: Update via package manager (`apt`, `dnf`, `pacman`)

### "check-prerequisites.ps1" fails

**Common causes**:
1. **PowerShell version**: Ensure you're using `pwsh` (7.3+), not `powershell` (5.1)
2. **Missing dependencies**: Install Python, Git, or Claude Code
3. **Path issues**: Verify tools are in your system PATH

**Debug**:
```powershell
# Check PowerShell version
pwsh --version

# Check if tools are accessible
git --version
python --version
claude --version
```

## Next Steps

Once installation is verified:

1. **Read the Getting Started guide**: [getting-started.md](getting-started.md)
2. **Explore the example feature**: `specs/001-example-feature/`
3. **Customize templates**: Edit files in `.spec-flow/templates/`
4. **Update your constitution**: Tailor `.spec-flow/memory/constitution.md` to your project

## Updating Spec-Flow

To update to the latest version:

```bash
cd spec-flow-workflow-kit
git pull origin main
```

Check `CHANGELOG.md` for breaking changes or new features.

## Uninstalling

To remove Spec-Flow:

```bash
# Navigate to parent directory
cd ..

# Remove the repository
rm -rf spec-flow-workflow-kit

# Optionally, remove PowerShell (if installed only for Spec-Flow)
# Windows: winget uninstall Microsoft.PowerShell
# macOS: brew uninstall --cask powershell
# Linux: sudo apt remove powershell (or equivalent)
```

## Get Help

If you encounter issues not covered here:

- **Troubleshooting Guide**: [troubleshooting.md](troubleshooting.md)
- **GitHub Issues**: [Report a bug](https://github.com/your-org/spec-flow-workflow-kit/issues)
- **Discussions**: [Ask a question](https://github.com/your-org/spec-flow-workflow-kit/discussions)

Happy building! 🚀

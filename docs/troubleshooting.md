# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when using Spec-Flow.

## Table of Contents

- [Prerequisites Issues](#prerequisites-issues)
- [Script Execution Issues](#script-execution-issues)
- [Claude Code Integration Issues](#claude-code-integration-issues)
- [Workflow Phase Issues](#workflow-phase-issues)
- [Context & Token Budget Issues](#context--token-budget-issues)
- [Git & Version Control Issues](#git--version-control-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Performance Issues](#performance-issues)
- [Getting More Help](#getting-more-help)

## Prerequisites Issues

### "pwsh: command not found" or "pwsh not recognized"

**Symptom**: Running PowerShell scripts fails with command not found error.

**Cause**: PowerShell 7+ is not installed or not in PATH.

**Solution**:

**Windows**:
```powershell
winget install Microsoft.PowerShell
```

**macOS**:
```bash
brew install --cask powershell
```

**Linux**:
```bash
# Ubuntu/Debian
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y powershell
```

**Alternative**: Use the Bash scripts instead (`.spec-flow/scripts/bash/*.sh`).

**Verification**:
```bash
pwsh --version
# Expected: PowerShell 7.3 or higher
```

---

### "Python not found" or "python: command not found"

**Symptom**: Token calculation or other Python scripts fail.

**Cause**: Python 3.10+ is not installed or not in PATH.

**Solution**:

**Windows**:
```powershell
winget install Python.Python.3.12
# Make sure "Add Python to PATH" is checked during installation
```

**macOS**:
```bash
brew install python@3.12
```

**Linux**:
```bash
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo dnf install python3 python3-pip  # Fedora/RHEL
```

**Verification**:
```bash
python --version  # or python3 --version
# Expected: Python 3.10 or higher
```

---

### "Git version too old"

**Symptom**: `check-prerequisites.ps1` reports Git version < 2.39.

**Cause**: Outdated Git installation.

**Solution**:

**Windows**:
```powershell
winget upgrade Git.Git
```

**macOS**:
```bash
brew upgrade git
```

**Linux**:
```bash
sudo apt update && sudo apt upgrade git  # Ubuntu/Debian
sudo dnf upgrade git  # Fedora/RHEL
```

**Verification**:
```bash
git --version
# Expected: git version 2.39.0 or higher
```

---

## Script Execution Issues

### "Execution policy does not allow running scripts" (Windows)

**Symptom**: PowerShell scripts fail with execution policy error.

**Cause**: Windows PowerShell has restricted execution policy.

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to RemoteSigned (allows local scripts)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy
# Expected: RemoteSigned
```

**Security Note**: This is safe for local scripts. RemoteSigned allows locally-created scripts while requiring downloaded scripts to be signed.

---

### "Permission denied" when running shell scripts (macOS/Linux)

**Symptom**: `./script.sh` fails with permission denied.

**Cause**: Script is not marked as executable.

**Solution**:
```bash
# Make all scripts executable
chmod +x .spec-flow/scripts/bash/*.sh

# Or for a specific script
chmod +x .spec-flow/scripts/bash/check-prerequisites.sh

# Verify
ls -la .spec-flow/scripts/bash/*.sh
# Should show -rwxr-xr-x (executable)
```

---

### "No such file or directory" when running scripts

**Symptom**: Scripts fail to find files even though they exist.

**Cause**: Incorrect working directory or line ending issues (CRLF vs LF).

**Solution 1** (Wrong directory):
```bash
# Ensure you're in the repository root
cd /path/to/spec-flow-workflow-kit
pwd  # Verify you're in the right place
```

**Solution 2** (Line ending issues):
```bash
# Convert CRLF to LF (common after Windows checkout)
dos2unix .spec-flow/scripts/bash/*.sh
# Or using sed
sed -i 's/\r$//' .spec-flow/scripts/bash/*.sh
```

**Prevention**: Configure Git to handle line endings:
```bash
git config --global core.autocrlf input  # macOS/Linux
git config --global core.autocrlf true   # Windows
```

---

## Claude Code Integration Issues

### "Permission denied" when Claude tries to read/write files

**Symptom**: Claude Code reports permission errors when executing commands.

**Cause**: `.claude/settings.local.json` missing or incorrect paths.

**Solution**:

1. Copy example settings:
   ```bash
   cp .claude/settings.example.json .claude/settings.local.json
   ```

2. Edit `.claude/settings.local.json` with absolute paths:
   ```json
   {
     "permissions": {
       "allow": [
         "Read(/absolute/path/to/your/project)",
         "Write(/absolute/path/to/your/project)",
         "Edit(/absolute/path/to/your/project)",
         "Bash(/absolute/path/to/your/project)"
       ]
     }
   }
   ```

3. Restart Claude Code

**Windows path format**: Use double backslashes or forward slashes:
```json
"Read(C:\\Users\\YourName\\Projects\\your-project)"
// or
"Read(C:/Users/YourName/Projects/your-project)"
```

---

### "Slash command not found" (/spec-flow, /plan, etc.)

**Symptom**: Typing `/spec-flow` in Claude Code does nothing or shows error.

**Cause**: Slash commands are not registered or Claude Code is not in the correct directory.

**Solution**:

1. **Verify directory structure**:
   ```bash
   ls .claude/commands/
   # Should show: spec-flow.md, plan.md, tasks.md, etc.
   ```

2. **Restart Claude Code** - Commands are loaded on startup

3. **Check Claude Code version** - Ensure you have the latest version with slash command support

4. **Verify you're in the project directory** - Claude Code needs to be run from the repository root

---

### "Context budget exceeded" warning

**Symptom**: Claude warns that token budget is exceeded and auto-compacts context.

**Cause**: Large specs, verbose notes, or many tasks consuming too many tokens.

**Solution**:

This is normal! Spec-Flow auto-compacts when budgets are exceeded. But you can also manually compact:

**Windows**:
```powershell
pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 `
  -FeatureDir specs/001-feature-name `
  -Phase implementation
```

**macOS/Linux**:
```bash
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/001-feature-name \
  --phase implementation
```

**Check token usage before compacting**:
```powershell
# Windows
pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 `
  -FeatureDir specs/001-feature-name

# macOS/Linux
.spec-flow/scripts/bash/calculate-tokens.sh \
  --feature-dir specs/001-feature-name
```

**Prevention**: Keep specs concise, use links for research instead of inlining, compact proactively.

---

## Workflow Phase Issues

### "No feature directory found"

**Symptom**: Running `/plan` or other commands fails because no feature directory exists.

**Cause**: You haven't run `/spec-flow` to create the feature directory structure.

**Solution**:
```bash
# In Claude Code
/spec-flow "Your feature name"

# This creates specs/NNN-feature-name/ with all required files
```

**Verification**:
```bash
ls specs/
# Should show: 001-feature-name/ or similar
```

---

### "Critical issues found in analysis" - workflow pauses

**Symptom**: `/analyze` finds critical issues and stops progression.

**Cause**: Inconsistencies between spec, plan, and tasks that need resolution.

**Solution**:

1. **Review the analysis report**:
   ```bash
   cat specs/001-feature-name/artifacts/analysis-report.md
   ```

2. **Fix identified issues** - Edit spec.md, plan.md, or tasks.md to resolve inconsistencies

3. **Re-run analysis**:
   ```bash
   /analyze
   ```

4. **Continue workflow**:
   ```bash
   /flow continue
   ```

**Common issues**:
- Requirements in spec not addressed in plan
- Tasks missing for planned phases
- Acceptance criteria without corresponding tests

---

### "Token estimate returns zero"

**Symptom**: `calculate-tokens.ps1` reports 0 tokens.

**Cause**: Files are empty, missing, or not UTF-8 encoded.

**Solution**:

1. **Check files exist**:
   ```bash
   ls -la specs/001-feature-name/
   # Should show spec.md, NOTES.md, etc.
   ```

2. **Check files have content**:
   ```bash
   cat specs/001-feature-name/spec.md
   # Should show actual content, not empty
   ```

3. **Check file encoding** (Windows):
   ```powershell
   Get-Content specs/001-feature-name/spec.md -Encoding UTF8
   ```

4. **Re-create feature** if files are corrupt:
   ```bash
   /spec-flow "Feature name"
   ```

---

### "Context delta lacks checkpoints"

**Symptom**: Compaction script reports no checkpoints found in NOTES.md.

**Cause**: NOTES.md doesn't have checkpoint entries prefixed with `-` or `**`.

**Solution**:

Ensure NOTES.md has checkpoints in this format:
```markdown
## Checkpoints

- **2025-10-03 10:00** - Phase 0: Specification complete
- **2025-10-03 11:30** - Phase 2: Tasks breakdown complete
```

**Automatic**: Claude Code adds checkpoints when you use `/spec-flow`, `/plan`, `/tasks`, etc.

**Manual**: Add checkpoints yourself when making significant progress.

---

## Context & Token Budget Issues

### "Phase budget unclear" during compaction

**Symptom**: Script doesn't know which phase you're in, uses wrong budget.

**Cause**: Phase not auto-detected from NOTES.md or feature directory.

**Solution**:

**Explicitly\spec-flow phase**:
```powershell
# Windows
pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 `
  -FeatureDir specs/001-feature `
  -Phase implementation  # or planning, optimization

# macOS/Linux
.spec-flow/scripts/bash/compact-context.sh \
  --feature-dir specs/001-feature \
  --phase implementation
```

**Valid phases**: `planning`, `implementation`, `optimization`

---

### Compaction deletes too much context

**Symptom**: After compaction, important information is missing.

**Cause**: Aggressive compaction strategy removed necessary context.

**Solution**:

1. **Restore from git**:
   ```bash
   git checkout HEAD -- specs/001-feature-name/NOTES.md
   ```

2. **Use less aggressive phase**:
   - Planning: 90% reduction (most aggressive)
   - Implementation: 60% reduction (moderate)
   - Optimization: 30% reduction (minimal)

3. **Manually mark important sections** in NOTES.md with `[KEEP]`:
   ```markdown
   ## Decisions

   [KEEP] Why we chose CSS variables instead of CSS-in-JS:
   Better performance, no runtime overhead...
   ```

---

## Git & Version Control Issues

### "Branch already exists" when creating feature

**Symptom**: `create-new-feature.ps1` fails because branch exists.

**Cause**: Feature was previously created or branch name conflicts.

**Solution**:

**Option 1** (Use existing branch):
```bash
git checkout 001-feature-name
# Continue working on existing feature
```

**Option 2** (Create new feature with different name):
```bash
# In Claude Code
/spec-flow "Feature name v2"
# Creates specs/002-feature-name-v2/
```

**Option 3** (Delete old branch - **caution**):
```bash
git branch -D 001-feature-name  # Delete local branch
git push origin --delete 001-feature-name  # Delete remote branch
# Then create feature again
```

---

### "Auto-merge failed" during ship phases

**Symptom**: PR is created but doesn't auto-merge.

**Cause**: CI checks failing, conflicts, or auto-merge not configured.

**Solution**:

1. **Check PR status**:
   ```bash
   gh pr view 123
   # Shows CI status, conflicts, reviews
   ```

2. **Fix CI failures**:
   ```bash
   /checks pr 123
   # Claude analyzes and fixes blockers
   ```

3. **Enable auto-merge** (if not configured):
   ```bash
   gh pr merge 123 --auto --squash
   ```

4. **Resolve conflicts** (if any):
   ```bash
   git pull origin staging
   # Resolve conflicts manually
   git push
   ```

---

## Platform-Specific Issues

### Windows: "Long path names not supported"

**Symptom**: File operations fail due to path length > 260 characters.

**Cause**: Windows has a default path length limit.

**Solution**:
```powershell
# Enable long paths (requires admin)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Restart computer for changes to take effect
```

**Alternative**: Keep feature names short, use shallower directory structures.

---

### macOS: "Operation not permitted" even with chmod

**Symptom**: Scripts fail with permission error despite being executable.

**Cause**: macOS Gatekeeper blocking unverified scripts.

**Solution**:
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine .spec-flow/scripts/bash/*.sh

# Or for specific script
xattr -d com.apple.quarantine .spec-flow/scripts/bash/check-prerequisites.sh
```

---

### Linux: "Bad interpreter: /usr/bin/env: 'pwsh\r'"

**Symptom**: Shell scripts fail with bad interpreter error.

**Cause**: Windows line endings (CRLF) in scripts.

**Solution**:
```bash
# Install dos2unix if not available
sudo apt install dos2unix  # Ubuntu/Debian
sudo dnf install dos2unix  # Fedora/RHEL

# Convert scripts
dos2unix .spec-flow/scripts/bash/*.sh

# Verify
file .spec-flow/scripts/bash/check-prerequisites.sh
# Should show: "POSIX shell script, ASCII text executable"
```

---

## Performance Issues

### Scripts running very slowly

**Symptom**: Prerequisite check or token calculation takes minutes instead of seconds.

**Cause**: Large repository, slow disk, or antivirus scanning.

**Possible Solutions**:

1. **Exclude from antivirus** (Windows Defender, etc.):
   - Add `.spec-flow/` to exclusion list
   - Add project root to exclusion list

2. **Check disk performance**:
   ```bash
   # Test disk speed
   dd if=/dev/zero of=testfile bs=1M count=1000
   # Should complete in seconds on SSD
   ```

3. **Use SSD** instead of HDD if possible

4. **Reduce spec file sizes** - Move large research to external docs

---

### Claude Code responses very slow

**Symptom**: Claude takes a long time to respond to commands.

**Cause**: Large context window, complex codebase, or network latency.

**Solution**:

1. **Compact context** to reduce token count:
   ```bash
   /flow  # Auto-compacts when needed
   ```

2. **Split large features** into smaller ones:
   - Target: ≤30 tasks per feature
   - Break into multiple features if larger

3. **Check network connection** - Claude Code requires internet access

4. **Reduce context** by linking to docs instead of inlining large content

---

## Getting More Help

If your issue isn't covered here:

### 1. Search Existing Issues
[GitHub Issues](https://github.com/your-org/spec-flow-workflow-kit/issues?q=is%3Aissue)

### 2. Check Discussions
[GitHub Discussions](https://github.com/your-org/spec-flow-workflow-kit/discussions)

### 3. Review Documentation
- [Installation Guide](installation.md)
- [Getting Started](getting-started.md)
- [Architecture Overview](architecture.md)
- [Command Reference](commands.md)

### 4. Enable Debug Logging

**PowerShell**:
```powershell
$VerbosePreference = "Continue"
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Verbose
```

**Bash**:
```bash
bash -x .spec-flow/scripts/bash/check-prerequisites.sh
```

### 5. Open a New Issue

When reporting an issue, include:

**Environment**:
```bash
# Run this and include output
pwsh --version
git --version
python --version
uname -a  # or systeminfo on Windows
```

**Error details**:
- Full error message
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or screenshots

**Template**:
```markdown
## Environment
- OS: [Windows 11 / macOS 14 / Ubuntu 22.04]
- PowerShell: [7.4.0]
- Python: [3.12.0]
- Git: [2.39.0]

## Issue Description
[Clear description of the problem]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Error occurs]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Error Output
```
[Paste error messages here]
```

## Additional Context
[Any other relevant information]
```

### 6. Community Support

- **Discussions**: Ask questions and share tips
- **Examples**: Browse `specs/001-example-feature/` for reference
- **Contributing**: Submit PRs to improve documentation

---

**Last Updated**: 2025-10-03


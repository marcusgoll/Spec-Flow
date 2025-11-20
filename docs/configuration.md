# Spec-Flow Configuration Guide

Complete guide to configuring Spec-Flow command defaults, learning system, and automation behavior.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Preference System Overview](#preference-system-overview)
- [Configuration Wizard](#configuration-wizard)
- [Manual Configuration](#manual-configuration)
- [Learning System](#learning-system)
- [Command-Specific Settings](#command-specific-settings)
- [Automation & CI/CD](#automation--cicd)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### 5-Minute Setup

1. **Run the configuration wizard:**
   ```bash
   /init-preferences
   ```

2. **Answer 8 questions** about your workflow preferences

3. **Done!** Commands now use your preferred defaults

### What Gets Configured

✅ Command default modes (/epic, /tasks, /init-project, /run-prompt)
✅ UI preferences (usage stats, last-used recommendations)
✅ Automation behavior (CI/CD defaults)

---

## Preference System Overview

Spec-Flow uses a **3-tier preference system** to eliminate flag memorization:

```
┌─────────────────────┐
│  Tier 3: Flags      │  Highest Priority
│  --auto, --no-input │  Explicit overrides
└─────────────────────┘
         ↑
┌─────────────────────┐
│  Tier 2: History    │  Medium Priority
│  command-history.yaml│  Learns from usage
└─────────────────────┘
         ↑
┌─────────────────────┐
│  Tier 1: Config     │  Lowest Priority
│  user-preferences.yaml│  Set once, use forever
└─────────────────────┘
```

### How It Works

1. **Config File** (Tier 1): Set your defaults once
2. **Learning System** (Tier 2): Commands remember your choices
3. **Command Flags** (Tier 3): Override anytime

### Example Flow

**First time (no config):**
```bash
/epic "add auth"
→ Prompts: "Run in auto or interactive mode?"
→ You select: "Interactive"
→ System records your choice
```

**Next time (has history):**
```bash
/epic "add notifications"
→ Suggests: "Interactive (last used, 1/1 times) ⭐"
→ One-click familiar choice
```

**With config file:**
```yaml
# .spec-flow/config/user-preferences.yaml
commands:
  epic:
    default_mode: auto
```

```bash
/epic "add payments"
→ Runs in auto mode automatically (zero prompts)
```

**Override with flag:**
```bash
/epic "add payments" --interactive
→ Uses interactive mode regardless of config/history
```

---

## Configuration Wizard

### Running the Wizard

```bash
/init-preferences
```

### Wizard Questions (8 total)

#### Round 1: Command Modes (2 questions)

**Question 1: /epic default mode**
- **Interactive** (recommended for new users) - Pause at reviews
- **Auto** (recommended for experienced users) - Skip prompts

**Question 2: /tasks default mode**
- **Standard** (recommended for most projects) - Direct implementation
- **UI-first** (recommended for design-heavy projects) - Mockups first

#### Round 2: Project Setup (2 questions)

**Question 3: /init-project default mode**
- **Interactive** (recommended) - Run questionnaire (15-48 questions)
- **CI** (automation only) - Use environment variables

**Question 4: Include design system by default?**
- **No** (recommended for most projects) - Skip design setup
- **Yes** (design-focused projects) - Always include design tokens

#### Round 3: Execution Strategy (1 question)

**Question 5: /run-prompt execution strategy**
- **Auto-detect** (recommended) - Analyze dependencies automatically
- **Parallel** (fast but risky) - Run simultaneously
- **Sequential** (safe but slow) - One-by-one execution

#### Round 4: UI Preferences (2 questions)

**Question 6: Show usage statistics?**
- **Yes** (recommended) - Display "used 8/10 times"
- **No** (minimal UI) - Hide statistics

**Question 7: Mark last-used with ⭐?**
- **Yes** (recommended) - Highlight recent choice
- **No** (treat all equally) - All options look the same

#### Round 5: Automation (1 question)

**Question 8: CI/CD mode default?**
- **No** (interactive use, recommended) - Normal prompting
- **Yes** (CI/CD only) - Default to --no-input

### Reset Preferences

```bash
/init-preferences --reset
```

Restores all preferences to defaults:
- /epic: interactive mode
- /tasks: standard mode
- /init-project: interactive mode, no design
- /run-prompt: auto-detect strategy
- UI: show stats, recommend last-used
- Automation: interactive (not CI mode)

---

## Manual Configuration

### File Location

```
.spec-flow/config/user-preferences.yaml
```

### File Structure

```yaml
# Spec-Flow User Preferences
# Documentation: docs/configuration.md

commands:
  epic:
    default_mode: interactive  # or auto

  tasks:
    default_mode: standard     # or ui-first

  init-project:
    default_mode: interactive  # or ci
    include_design: false      # or true

  run-prompt:
    default_strategy: auto-detect  # or parallel or sequential

automation:
  auto_approve_minor_changes: false
  ci_mode_default: false

ui:
  show_usage_stats: true
  recommend_last_used: true
```

### Schema Validation

Configuration is validated against:
```
.spec-flow/config/user-preferences-schema.yaml
```

**Valid values:**
- `commands.epic.default_mode`: `interactive` | `auto`
- `commands.tasks.default_mode`: `standard` | `ui-first`
- `commands.init-project.default_mode`: `interactive` | `ci`
- `commands.init-project.include_design`: `true` | `false`
- `commands.run-prompt.default_strategy`: `auto-detect` | `parallel` | `sequential`
- `automation.ci_mode_default`: `true` | `false`
- `ui.show_usage_stats`: `true` | `false`
- `ui.recommend_last_used`: `true` | `false`

### Example Configurations

#### Power User (Automation-Focused)

```yaml
commands:
  epic:
    default_mode: auto
  tasks:
    default_mode: standard
  init-project:
    default_mode: interactive
    include_design: false
  run-prompt:
    default_strategy: parallel

automation:
  auto_approve_minor_changes: false
  ci_mode_default: false

ui:
  show_usage_stats: false
  recommend_last_used: false
```

#### Design-Focused User

```yaml
commands:
  epic:
    default_mode: interactive
  tasks:
    default_mode: ui-first
  init-project:
    default_mode: interactive
    include_design: true
  run-prompt:
    default_strategy: auto-detect

automation:
  auto_approve_minor_changes: false
  ci_mode_default: false

ui:
  show_usage_stats: true
  recommend_last_used: true
```

#### CI/CD Automation

```yaml
commands:
  epic:
    default_mode: auto
  tasks:
    default_mode: standard
  init-project:
    default_mode: ci
    include_design: false
  run-prompt:
    default_strategy: auto-detect

automation:
  auto_approve_minor_changes: false
  ci_mode_default: true

ui:
  show_usage_stats: false
  recommend_last_used: false
```

---

## Learning System

Commands track your mode selections to provide intelligent suggestions.

### How It Works

**Tracking file:**
```
.spec-flow/memory/command-history.yaml
```

**Structure:**
```yaml
epic:
  last_used_mode: auto
  usage_count:
    auto: 12
    interactive: 3
  last_updated: 2025-11-20T10:30:00Z

tasks:
  last_used_mode: ui-first
  usage_count:
    ui-first: 8
    standard: 15
  last_updated: 2025-11-20T09:15:00Z
```

### Smart Suggestions

After using a mode 3+ times, commands suggest it prominently:

```
What's next?

1. Auto (last used, 12/15 times) ⭐  ← Smart suggestion
2. Interactive (used 3/15 times)
```

### Reset History

**Per command:**
```bash
# Not yet implemented - manual edit required
```

Edit `.spec-flow/memory/command-history.yaml` and set counts to 0.

---

## Command-Specific Settings

### /epic Command

**Config options:**
```yaml
commands:
  epic:
    default_mode: interactive  # or auto
```

**Behavior:**
- `interactive`: Pause at spec review and plan review
- `auto`: Skip all prompts, run until blocker

**Flags:**
- `--auto`: Force auto mode
- `--interactive`: Force interactive mode
- `--no-input`: CI/CD mode (same as --auto)

**Examples:**
```bash
# Uses preference
/epic "add auth"

# Override to auto
/epic "add auth" --auto

# Override to interactive
/epic "add auth" --interactive

# CI/CD automation
/epic "add auth" --no-input
```

### /tasks Command

**Config options:**
```yaml
commands:
  tasks:
    default_mode: standard  # or ui-first
```

**Behavior:**
- `standard`: Generate TDD tasks for direct implementation
- `ui-first`: Generate HTML mockups first, then implementation

**Flags:**
- `--ui-first`: Force UI-first mode
- `--standard`: Force standard mode
- `--no-input`: CI/CD mode (uses standard)

**Examples:**
```bash
# Uses preference
/tasks

# Override to UI-first
/tasks --ui-first

# Override to standard
/tasks --standard

# CI/CD automation
/tasks --no-input
```

### /init-project Command

**Config options:**
```yaml
commands:
  init-project:
    default_mode: interactive  # or ci
    include_design: false      # or true
```

**Behavior:**
- `interactive`: Run questionnaire (15 questions, or 48 with --with-design)
- `ci`: Non-interactive mode using environment variables

**Flags:**
- `--interactive`: Force interactive mode
- `--ci` / `--no-input`: Force CI mode
- `--with-design`: Include design system (overrides include_design config)
- `--update`: Fill missing sections only
- `--force`: Overwrite all docs

**Examples:**
```bash
# Uses preferences (interactive, no design)
/init-project

# Uses preferences (interactive, with design from config)
/init-project
# (if include_design: true in config)

# Override: Force CI mode
/init-project --ci

# Override: Include design regardless of config
/init-project --with-design

# CI/CD automation
/init-project --no-input
```

### /run-prompt Command

**Config options:**
```yaml
commands:
  run-prompt:
    default_strategy: auto-detect  # or parallel or sequential
```

**Behavior:**
- `auto-detect`: Analyze prompt dependencies and choose strategy
- `parallel`: Run all prompts simultaneously
- `sequential`: Run prompts one-by-one

**Flags:**
- `--auto-detect`: Force auto-detect
- `--parallel`: Force parallel execution
- `--sequential`: Force sequential execution
- `--no-input`: CI/CD mode (uses auto-detect)

**Examples:**
```bash
# Uses preference
/run-prompt 005 006 007

# Override to parallel
/run-prompt 005 006 007 --parallel

# Override to sequential
/run-prompt 005 006 007 --sequential

# CI/CD automation
/run-prompt 005 006 007 --no-input
```

---

## Automation & CI/CD

### CI Mode Configuration

**Enable CI mode by default:**
```yaml
automation:
  ci_mode_default: true
```

**Effect:**
- All commands assume `--no-input`
- No interactive prompts
- Uses safe defaults for all choices

### Universal --no-input Flag

All commands support `--no-input` for automation:

```bash
# Epic workflow
/epic "deploy infrastructure" --no-input

# Task generation
/tasks --no-input

# Project initialization
/init-project --no-input

# Prompt execution
/run-prompt 005 006 007 --no-input
```

### GitHub Actions Example

```yaml
name: Epic Deployment
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Run Epic Workflow
        run: |
          npx claude /epic "deploy infrastructure" --no-input

      - name: Verify Deployment
        run: |
          npx claude /validate-staging --no-input
```

### Environment Variables

For `/init-project --ci`:

```bash
export PROJECT_NAME="My Project"
export PROJECT_TYPE="web-app"
export TECH_STACK="Next.js,TypeScript,PostgreSQL"
export DEPLOYMENT_MODEL="staging-prod"

/init-project --ci
```

---

## Advanced Usage

### Sharing Configurations Across Team

**Commit preference file:**
```bash
git add .spec-flow/config/user-preferences.yaml
git commit -m "feat: add team workflow preferences"
git push
```

**Team members get preferences:**
```bash
git pull
# Preferences now active for all team members
```

### Per-Project vs Global Preferences

**Current behavior:**
- Preferences are per-project (`.spec-flow/config/` in project root)
- No global preferences yet

**Future:** Global preferences in `~/.spec-flow/config/user-preferences.yaml`

### Override Precedence

From lowest to highest priority:

1. **Default values** (hardcoded in schema)
2. **Config file** (user-preferences.yaml)
3. **Command history** (last-used mode)
4. **Command flags** (--auto, --interactive, etc.)
5. **--no-input flag** (highest - disables all prompts)

### Debugging Preferences

**Check current configuration:**
```bash
cat .spec-flow/config/user-preferences.yaml
```

**Check learning history:**
```bash
cat .spec-flow/memory/command-history.yaml
```

**Validate configuration:**
```bash
# Not yet implemented - manual validation required
```

Compare against schema:
```bash
cat .spec-flow/config/user-preferences-schema.yaml
```

---

## Troubleshooting

### Preferences Not Taking Effect

**Symptoms:**
- Commands still prompt for mode selection
- Changes to config file don't work

**Solutions:**

1. **Verify file location:**
   ```bash
   ls -la .spec-flow/config/user-preferences.yaml
   ```

2. **Check YAML syntax:**
   ```bash
   # Ensure proper indentation (2 spaces)
   # No tabs allowed
   cat .spec-flow/config/user-preferences.yaml
   ```

3. **Verify values match schema:**
   ```yaml
   # WRONG
   commands:
     epic:
       default_mode: automated  # Invalid value

   # RIGHT
   commands:
     epic:
       default_mode: auto  # Valid value
   ```

4. **Restart Claude Code** (if using the extension)

### Learning System Not Working

**Symptoms:**
- Commands don't show "last used" marker
- Usage statistics don't appear

**Solutions:**

1. **Check UI preferences:**
   ```yaml
   ui:
     show_usage_stats: true  # Must be true
     recommend_last_used: true  # Must be true
   ```

2. **Verify history file exists:**
   ```bash
   ls -la .spec-flow/memory/command-history.yaml
   ```

3. **Check history has data:**
   ```bash
   cat .spec-flow/memory/command-history.yaml
   ```

4. **Use command 2-3 times** to establish pattern

### Flags Not Overriding Preferences

**Symptoms:**
- `--auto` flag ignored
- Command uses preference instead of flag

**Solutions:**

1. **Verify flag syntax:**
   ```bash
   # WRONG
   /epic --auto "add auth"

   # RIGHT
   /epic "add auth" --auto
   ```

2. **Check for typos:**
   ```bash
   # WRONG
   /epic "add auth" --automatic

   # RIGHT
   /epic "add auth" --auto
   ```

3. **Use --no-input for CI:**
   ```bash
   # Most reliable for automation
   /epic "add auth" --no-input
   ```

### Configuration File Corrupted

**Symptoms:**
- YAML parsing errors
- Commands fail to load preferences

**Solutions:**

1. **Restore from example:**
   ```bash
   cp .spec-flow/config/user-preferences.example.yaml \
      .spec-flow/config/user-preferences.yaml
   ```

2. **Reset with wizard:**
   ```bash
   /init-preferences --reset
   ```

3. **Manual validation:**
   - Check indentation (2 spaces, no tabs)
   - Ensure all keys are spelled correctly
   - Verify boolean values: `true` / `false` (lowercase)
   - Verify string values match schema

### File Permissions Issues

**Symptoms:**
- "Permission denied" errors
- Cannot write preferences

**Solutions:**

1. **Check file permissions:**
   ```bash
   ls -la .spec-flow/config/user-preferences.yaml
   ```

2. **Fix permissions:**
   ```bash
   chmod 644 .spec-flow/config/user-preferences.yaml
   ```

3. **Check directory permissions:**
   ```bash
   chmod 755 .spec-flow/config/
   ```

---

## FAQ

### Q: Can I have different preferences per project?

**A:** Yes! Preferences are stored in `.spec-flow/config/` within each project, so every project can have its own configuration.

### Q: Can I disable the learning system?

**A:** Yes, set:
```yaml
ui:
  show_usage_stats: false
  recommend_last_used: false
```

This hides usage statistics and last-used markers.

### Q: What's the fastest way to configure preferences?

**A:** Use the wizard:
```bash
/init-preferences
```

It takes ~2 minutes to answer 8 questions.

### Q: Can I edit preferences without the wizard?

**A:** Yes! Edit `.spec-flow/config/user-preferences.yaml` directly. Changes take effect immediately.

### Q: Do flags always override preferences?

**A:** Yes. The priority order is: defaults < config < history < flags < --no-input.

### Q: Can I reset just one command's preferences?

**A:** Not yet. Use `/init-preferences --reset` to reset all, then re-run the wizard.

### Q: How do I share preferences with my team?

**A:** Commit `.spec-flow/config/user-preferences.yaml` to git. Team members will get the same defaults.

### Q: Does the learning system work across projects?

**A:** No. Each project has its own command history (`.spec-flow/memory/command-history.yaml`).

### Q: Can I prevent certain modes from being used?

**A:** Not yet. Preferences set defaults but don't restrict modes. Users can always override with flags.

### Q: What happens if I delete the config file?

**A:** Commands use hardcoded defaults and prompt for mode selection until you reconfigure.

---

## Related Documentation

- [QUICKSTART.md](../QUICKSTART.md) - Quick setup guide
- [CLAUDE.md](../CLAUDE.md) - Full command reference
- [README.md](../README.md) - Project overview

---

**Need help?** [File an issue](https://github.com/marcusgoll/Spec-Flow/issues) or check [GitHub Discussions](https://github.com/marcusgoll/Spec-Flow/discussions).

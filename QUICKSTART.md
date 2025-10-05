# Spec-Flow Quick Start

Get Spec-Flow running in your project in **5 minutes**.

## Prerequisites

✅ **Git 2.39+** | ✅ **PowerShell 7.3+** | ✅ **Python 3.10+** | ✅ **Claude Code**

Not sure? Run the prerequisite checker after installation (Step 3).

---

## Installation

### Option 1: NPM (Recommended - Fastest)

Install Spec-Flow with a single command using npx:

```bash
# Initialize in current directory (interactive wizard)
npx spec-flow init

# Or specify target directory
npx spec-flow init --target ./my-project

# Non-interactive mode (uses defaults)
npx spec-flow init --non-interactive
```

**What happens:**
- ✅ Detects your project type (Next.js, React, API, etc.)
- ✅ Installs `.claude/`, `.spec-flow/`, and `CLAUDE.md`
- ✅ Initializes memory files with default values
- ✅ Validates prerequisites

**Update existing installation:**
```bash
npx spec-flow update
```

### Option 2: Manual Installation (Clone Repository)

If you prefer to clone the repository first:

#### Step 1: Clone Spec-Flow Repository

```bash
# Clone to a workspace directory (not inside your project)
cd ~/projects  # or C:\Projects on Windows
git clone https://github.com/marcusgoll/Spec-Flow.git
cd Spec-Flow
```

#### Step 2: Run the Installation Wizard

**Windows (PowerShell):**
```powershell
# Interactive wizard
powershell -File .spec-flow/scripts/powershell/install-wizard.ps1

# Or specify target directory
powershell -File .spec-flow/scripts/powershell/install-wizard.ps1 -TargetDir ../my-project
```

**macOS/Linux (Bash):**
```bash
# Interactive wizard
./.spec-flow/scripts/bash/install-wizard.sh

# Or specify target directory
./.spec-flow/scripts/bash/install-wizard.sh --target-dir ../my-project
```

### Step 3: Verify Installation (Both Methods)

The installer runs checks automatically, but you can verify manually:

**Windows:**
```powershell
cd /path/to/your/project
pwsh -File .spec-flow/scripts/powershell/check-prerequisites.ps1
```

**macOS/Linux:**
```bash
cd /path/to/your/project
./.spec-flow/scripts/bash/check-prerequisites.sh
```

Expected output:
```
✅ Git 2.39+ installed
✅ PowerShell 7.3+ installed
✅ Python 3.10+ installed
✅ Claude Code accessible
```

If any checks fail, see [Installation Guide](docs/installation.md) for troubleshooting.

---

## Configuration

### Customize Your Constitution

Open `.spec-flow/memory/constitution.md` in your project and customize the engineering principles to match your team's standards:

```markdown
# Engineering Constitution

## Core Principles

### 1. Specification First
Every feature begins with a written specification...

### 2. Testing Standards
All production code must have 80%+ test coverage...

### 3. Performance Requirements
API responses: <200ms p50, <500ms p95...
```

Update the principles, remove what doesn't apply, add what's missing.

### Configure Claude Code Permissions

The installer creates `.claude/settings.local.json` with your project path pre-filled. Review and adjust if needed:

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

**Important**: Restart Claude Code after updating settings.

---

## Your First Feature

### 1. Build Your Roadmap

Open Claude Code in your project directory and run:

```
/roadmap
```

Claude will help you:
- Add feature ideas to `.spec-flow/memory/roadmap.md`
- Prioritize using ICE scoring (Impact × Confidence ÷ Effort)
- Organize features: Backlog → Next → In Progress → Shipped

**Example interaction:**
```
You: /roadmap
Claude: Let's build your product roadmap. What feature would you like to add?

You: Add dark mode toggle
Claude: Great! Let me gather some details...
  - Impact (1-5): 4 (users frequently request this)
  - Effort (1-5): 2 (1-2 days)
  - Confidence (0-1): 0.9 (clear requirements)
  - ICE Score: 1.8

Added to roadmap under "Next". Ready to spec it out?
```

### 2. Create a Specification

Once you have a prioritized feature, create its spec:

```
/spec-flow "dark-mode-toggle"
```

This creates `specs/001-dark-mode-toggle/` with:
- `spec.md` - Full specification (requirements, user stories, acceptance criteria)
- `NOTES.md` - Decision log (tracks changes, blockers, pivots)
- `visuals/README.md` - UI/UX references

### 3. Run the Workflow

Use `/flow` to automate the full workflow with manual gates:

```
/flow "dark-mode-toggle"
```

The workflow progresses through phases:

```
/spec-flow → /clarify → /plan → /tasks → /analyze → /implement →
/optimize → /preview (manual) → /phase-1-ship → /validate-staging (manual) →
/phase-2-ship
```

**Manual Gates**:
- `/preview` - You validate UI/UX before shipping to staging
- `/validate-staging` - You test on staging before production

Or run commands individually:
```
/plan         # Phase 1: Create implementation plan
/tasks        # Phase 2: Break into 20-30 tasks
/implement    # Phase 4: Execute tasks
/optimize     # Phase 5: Code review + performance checks
```

---

## What's Next?

### Learn the Full Workflow
Read the [Getting Started Guide](docs/getting-started.md) for a detailed tutorial.

### Explore Commands
See [Command Reference](docs/commands.md) for all available slash commands.

### Understand the Architecture
Read [Architecture Overview](docs/architecture.md) to understand how Spec-Flow works.

### Customize Templates
Edit templates in `.spec-flow/templates/` to match your project's needs.

### Join the Community
- **Report issues**: [GitHub Issues](https://github.com/marcusgoll/Spec-Flow/issues)
- **Ask questions**: [GitHub Discussions](https://github.com/marcusgoll/Spec-Flow/discussions)
- **Contribute**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Troubleshooting

### "PowerShell not found"
Install PowerShell 7.3+: [PowerShell Installation Guide](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)

### "Permission denied" (macOS/Linux)
Make scripts executable:
```bash
chmod +x .spec-flow/scripts/bash/*.sh
```

### "Claude Code not accessible"
1. Verify Claude Code is running
2. Check `.claude/settings.local.json` has correct paths
3. Restart Claude Code

### Settings not taking effect
Claude Code caches settings. After editing `.claude/settings.local.json`, restart Claude Code completely.

### More Help
See the full [Troubleshooting Guide](docs/troubleshooting.md) or [file an issue](https://github.com/marcusgoll/Spec-Flow/issues).

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/roadmap` | Manage feature backlog with ICE scoring |
| `/spec-flow "name"` | Create specification for a feature |
| `/flow "name"` | Automate workflow from spec to production |
| `/plan` | Generate implementation plan |
| `/tasks` | Break plan into 20-30 actionable tasks |
| `/implement` | Execute implementation tasks |
| `/optimize` | Code review, performance, accessibility checks |
| `/preview` | Manual UI/UX validation gate |
| `/phase-1-ship` | Deploy to staging |
| `/validate-staging` | Manual staging validation gate |
| `/phase-2-ship` | Deploy to production |

**Pro tip**: Use `/flow "feature-name"` to automate progression with manual gates at preview and staging validation.

---

**Happy building!** 🚀

For detailed documentation, visit [docs/getting-started.md](docs/getting-started.md).

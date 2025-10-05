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

## Let Claude Code Set Up Your Project

Instead of manually editing files, let Claude Code's interactive commands configure your project with guided Q&A.

### Recommended Setup (Optional but Powerful)

Open Claude Code in your project directory and run these commands:

#### 1. Define Your Engineering Standards (Optional)

```
/constitution
```

Claude will interactively help you:
- Set project type (Web App, API, Mobile, CLI, etc.)
- Define test coverage requirements (50%, 70%, 80%, 90%)
- Configure performance targets (API response times, page load speeds)
- Set accessibility standards (WCAG Level A, AA, AAA)
- Add custom principles specific to your project

**Why?** Your constitution becomes the Single Source of Truth for all feature development. Every spec, plan, and review references these standards.

**Skip if:** You want to start with defaults (80% coverage, <200ms API, <2s page load, WCAG AA)

#### 2. Plan Your Feature Roadmap (Optional)

```
/roadmap
```

Claude will guide you through:
- Adding feature ideas to your backlog
- ICE scoring (Impact × Confidence ÷ Effort) for prioritization
- Organizing features: Backlog → Next → In Progress → Shipped

**Example interaction:**
```
You: /roadmap
Claude: Let's build your product roadmap. What feature would you like to add?

You: Add dark mode toggle
Claude: Great! Let me score this feature...
  - Impact (1-5): How much value for users? → 4
  - Effort (1-5): Implementation complexity? → 2
  - Confidence (0-1): Estimate certainty? → 0.9
  - ICE Score: (4 × 0.9) ÷ 2 = 1.8

✓ Added to "Next" (high priority). Ready to spec it out?
```

**Why?** Prioritized roadmap = focused development. ICE scoring prevents "urgency bias" and helps you ship high-impact features first.

**Skip if:** You have one clear feature to build and don't need prioritization

#### 3. Curate Design Inspirations (Optional)

```
/design-inspiration
```

Claude will help you collect:
- Color palettes and typography references
- Component styles from sites you admire
- Layout and spacing systems
- Animation and interaction patterns

**Why?** Visual consistency across features. Designers and developers reference the same inspiration sources.

**Skip if:** Your project doesn't have UI components or you're not concerned with design consistency

### Configure Claude Code Permissions (Required)

The installer creates `.claude/settings.local.json` with your project path. Review permissions:

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

### 4. Managing Context (Optional)

If context feels heavy or you're approaching token limits, use `/compact` to reduce token usage:

```
/compact                # Auto-detect phase and compact
/compact planning       # After /plan (aggressive: 90% reduction)
/compact implementation # After /implement (moderate: 60% reduction)
/compact optimization   # After /optimize (minimal: 30% reduction)
```

**What it does:**
- Summarizes verbose research notes → headings only
- Compacts detailed task descriptions → checkpoints
- **Preserves:** Architecture decisions, error logs, code review findings

**When to use:**
- Between workflow phases as an optional optimization
- When suggested by command auto-progression
- If you notice slowdowns or token warnings

**Note:** `/flow` auto-compacts silently, so manual compaction is only needed when stepping through commands individually.

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
| `/compact [phase]` | Reduce token usage (optional between phases) |
| `/preview` | Manual UI/UX validation gate |
| `/phase-1-ship` | Deploy to staging |
| `/validate-staging` | Manual staging validation gate |
| `/phase-2-ship` | Deploy to production |

**Pro tips**:
- Use `/flow "feature-name"` to automate progression with manual gates at preview and staging validation
- Use `/compact` between phases if context feels heavy (auto-compacts in `/flow` mode)

---

**Happy building!** 🚀

For detailed documentation, visit [docs/getting-started.md](docs/getting-started.md).

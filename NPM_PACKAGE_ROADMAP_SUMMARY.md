# GitHub Roadmap - npm Package Integration

**Status**: ✅ Complete and ready for users

---

## What's Included in the Package

When users install Spec-Flow, they get everything needed for GitHub Issues roadmap management:

### 1. Issue Templates (`.github/ISSUE_TEMPLATE/`)

Automatically copied to user's repo:
- `feature.yml` - Feature requests with ICE scoring
- `enhancement.yml` - Enhancements
- `bug.yml` - Bug reports
- `task.yml` - Tasks
- `config.yml` - Template configuration

### 2. Setup Scripts (`.spec-flow/scripts/`)

**Bash** (Linux/macOS):
- `setup-github-labels.sh` - Create roadmap labels
- `github-roadmap-manager.sh` - Core roadmap functions
- `migrate-roadmap-to-github.sh` - Migrate from markdown

**PowerShell** (Windows):
- `setup-github-labels.ps1` - Create roadmap labels
- `github-roadmap-manager.ps1` - Core roadmap functions

### 3. CLI Commands (`bin/`)

**New Command**: `npx spec-flow setup-roadmap`

Interactive wizard that:
1. Checks GitHub authentication (gh CLI or PAT)
2. Creates labels in user's repo
3. Optionally migrates existing markdown roadmap
4. Provides next steps guidance

**npm Scripts**:
```json
{
  "setup:roadmap": "node bin/setup-roadmap.js",
  "setup:roadmap:labels": "bash .spec-flow/scripts/bash/setup-github-labels.sh || pwsh ..."
}
```

### 4. Documentation (`docs/`)

- `USER_ROADMAP_SETUP.md` - User-facing setup guide
- `github-roadmap-migration.md` - Technical reference
- `WORKFLOW_DEVELOPMENT_ROADMAP.md` - For workflow contributors

---

## User Experience Flow

### Installation

```bash
npm install spec-flow
```

**Postinstall message shows**:
```
After installation:
  1. Read QUICKSTART.md
  2. Set up GitHub roadmap: npx spec-flow setup-roadmap (recommended)
  3. Open in Claude Code
  4. Run /constitution, /design-inspiration (optional)
  5. Start building: /feature "feature-name"
```

### Setup Roadmap

User runs:
```bash
npx spec-flow setup-roadmap
```

**Interactive wizard**:
```
═══════════════════════════════════════════════════════════════════
 🗺️  GitHub Issues Roadmap Setup
═══════════════════════════════════════════════════════════════════

This wizard will help you set up GitHub Issues for roadmap management.

Step 1: GitHub Authentication
─────────────────────────────

✓ GitHub CLI authenticated

Step 2: Create GitHub Labels
────────────────────────────

? Create labels for roadmap management? (Y/n)

✓ Creating labels...
✓ Labels created successfully

Step 3: Markdown Roadmap Migration
───────────────────────────────────

✓ No existing markdown roadmap found

═══════════════════════════════════════════════════════════════════
 ✓ Roadmap Setup Complete
═══════════════════════════════════════════════════════════════════

Your roadmap is now managed via GitHub Issues!

Quick Start:
  gh issue list --label type:feature  # View roadmap
  gh issue create --template feature.yml  # Add feature

Using /roadmap command:
  /roadmap add "Feature description"
  /roadmap brainstorm deep backend
  /roadmap move feature-slug to next
```

### Daily Usage

**Create Features**:
```bash
# Via web UI
github.com/user/repo/issues/new → Feature Request template

# Via CLI
gh issue create --template feature.yml

# Via /roadmap (after command update)
/roadmap add "Student progress dashboard"
```

**Start Building**:
```bash
# /feature automatically links to GitHub issue
/feature "student-progress-dashboard"

# Workflow:
# 1. Finds issue by slug
# 2. Adds status:in-progress label
# 3. Stores issue number in workflow state
```

**Ship to Production**:
```bash
/ship

# Workflow:
# 1. Adds status:shipped label
# 2. Closes issue
# 3. Adds comment with version/URL
```

---

## What's Working Now

✅ **Setup CLI**: `npx spec-flow setup-roadmap`
✅ **Label Creation**: Automatic via wizard or npm script
✅ **Issue Templates**: Copied to user's repo on init
✅ **Documentation**: Comprehensive user guide
✅ **Postinstall Guidance**: Shows setup command
✅ **Core Functions**: github-roadmap-manager.sh/ps1 available

---

## What Needs Implementation (Future)

These updates will complete the GitHub Issues integration:

### 1. Update `/roadmap` Command

**Current**: Uses markdown (`.spec-flow/memory/roadmap.md`)

**Needed**: Use GitHub Issues

**File**: `.claude/commands/roadmap.md`

**Changes**:
```bash
# OLD
echo "### $slug" >> .spec-flow/memory/roadmap.md

# NEW
source .spec-flow/scripts/bash/github-roadmap-manager.sh
create_roadmap_issue "$title" "$body" "$impact" "$effort" "$confidence" "$area" "$role" "$slug"
```

### 2. Update `/feature` Command

**File**: `.claude/commands/feature.md`

**Add after slug generation**:
```bash
# Link to GitHub issue
source .spec-flow/scripts/bash/github-roadmap-manager.sh
issue=$(get_issue_by_slug "$SLUG")

if [ -n "$issue" ]; then
  issue_num=$(echo "$issue" | jq -r '.number')
  yq eval -i ".feature.github_issue = $issue_num" "$STATE_FILE"
  mark_issue_in_progress "$SLUG"
fi
```

### 3. Update `/ship` Command

**File**: `.claude/commands/ship.md`

**Add in finalize phase**:
```bash
# Close GitHub issue
source .spec-flow/scripts/bash/github-roadmap-manager.sh
mark_issue_shipped "$SLUG" "$VERSION" "$DATE" "$PROD_URL"
```

---

## Files Included in npm Package

Updated `package.json` files array:
```json
{
  "files": [
    ".claude/",
    ".spec-flow/",
    ".github/ISSUE_TEMPLATE/",  // ← NEW
    "CLAUDE.md",
    "bin/",
    "docs/",                     // ← NEW (includes setup guides)
    "LICENSE",
    "README.md",
    "QUICKSTART.md"
  ]
}
```

Users get:
- ✅ Issue templates (automatically copied on init)
- ✅ Setup scripts (bash + PowerShell)
- ✅ Setup CLI command
- ✅ Core roadmap functions
- ✅ Documentation (user + technical guides)

---

## Testing Checklist (Before Release)

### 1. Test Installation

```bash
# Create test project
mkdir test-project && cd test-project
npm init -y

# Install spec-flow (local)
npm install /path/to/spec-flow

# Verify postinstall message shows setup-roadmap
```

### 2. Test Setup Wizard

```bash
# Run setup
npx spec-flow setup-roadmap

# Should guide through:
# - Auth check
# - Label creation
# - Migration (if applicable)
```

### 3. Test Label Creation

```bash
# Verify labels created
gh label list

# Should see:
# - priority:high/medium/low
# - type:feature/enhancement/bug/task
# - area:*/role:*/status:*/size:*
```

### 4. Test Issue Creation

```bash
# Via web
github.com/user/test-project/issues/new

# Should see feature template with ICE fields

# Via CLI
gh issue create --template feature.yml
```

### 5. Test npm Scripts

```bash
# Test label setup script
npm run setup:roadmap:labels

# Should work on both bash and PowerShell
```

### 6. Test Help

```bash
npx spec-flow help

# Should list:
# - init
# - update
# - status
# - setup-roadmap ← NEW
# - help
```

---

## Documentation for Users

When users need help, they find:

**In their project after init**:
- `.github/ISSUE_TEMPLATE/` - Ready-to-use templates
- `node_modules/spec-flow/docs/USER_ROADMAP_SETUP.md` - Setup guide

**Online**:
- GitHub README - Quick start
- `/docs` folder in repo - All guides

**CLI**:
```bash
npx spec-flow help
npx spec-flow setup-roadmap
```

---

## Release Notes (for v1.17.0)

### New Features

**GitHub Issues Roadmap Management**:
- ✨ New `setup-roadmap` CLI command for interactive setup
- ✨ Issue templates with ICE scoring (Impact/Confidence/Effort)
- ✨ Automatic label creation (priority, type, area, role, status, size)
- ✨ Migration tool from markdown roadmap
- ✨ Core roadmap functions (bash + PowerShell)
- 📚 Comprehensive user documentation

**npm Scripts**:
- `setup:roadmap` - Interactive roadmap setup wizard
- `setup:roadmap:labels` - Create GitHub labels

**Breaking Changes**:
- None (backward compatible, markdown roadmap still works)

**Coming in v1.18.0**:
- `/roadmap` command GitHub Issues integration
- `/feature` auto-linking to issues
- `/ship` auto-closing issues

---

## Support

**For Users**:
- Setup guide: `docs/USER_ROADMAP_SETUP.md`
- Run: `npx spec-flow setup-roadmap`
- Issues: https://github.com/marcusgoll/Spec-Flow/issues

**For Contributors**:
- Development guide: `docs/WORKFLOW_DEVELOPMENT_ROADMAP.md`
- Technical reference: `docs/github-roadmap-migration.md`
- This repo's issues for workflow improvements

---

**Status**: ✅ Ready to ship! Users can set up GitHub roadmap immediately after install.

# Roadmap Setup Guide (For Users)

**Audience**: Users of the Spec-Flow workflow package

**Purpose**: Set up GitHub Issues for managing your product roadmap

---

## Quick Start

After installing Spec-Flow, run the interactive setup:

```bash
npx spec-flow setup-roadmap
```

This wizard will guide you through:

1. GitHub authentication
2. Label creation
3. Optional migration from markdown roadmap

## Manual Setup

If you prefer manual setup or need to troubleshoot:

### Step 1: Authenticate with GitHub

**Option A: GitHub CLI (Recommended)**

```bash
gh auth login
# Follow the prompts to authenticate
```

**Option B: Personal Access Token**

```bash
# Create token at: https://github.com/settings/tokens
# Required scopes: repo, write:discussion

# Linux/macOS:
export GITHUB_TOKEN=ghp_your_token_here

# Windows PowerShell:
$env:GITHUB_TOKEN = "ghp_your_token_here"
```

### Step 2: Create Labels

**Automatic (via npm script)**:

```bash
npm run setup:roadmap:labels
```

**Manual (if npm script fails)**:

*On Linux/macOS:*

```bash
bash node_modules/spec-flow/.spec-flow/scripts/bash/setup-github-labels.sh
```

*On Windows PowerShell:*

```powershell
pwsh -File node_modules\spec-flow\.spec-flow\scripts\powershell\setup-github-labels.ps1
```

This creates 30+ labels:

- **Priority**: `priority:high`, `priority:medium`, `priority:low`
- **Type**: `type:feature`, `type:enhancement`, `type:bug`, `type:task`
- **Area**: `area:backend`, `area:frontend`, `area:api`, `area:infra`, `area:design`, `area:marketing`
- **Role**: `role:all`, `role:free`, `role:student`, etc. (customize to your users)
- **Status**: `status:backlog`, `status:next`, `status:later`, `status:in-progress`, `status:shipped`
- **Size**: `size:small`, `size:medium`, `size:large`, `size:xl`

### Step 3: (Optional) Migrate Existing Roadmap

If you have an existing markdown roadmap (`.spec-flow/memory/roadmap.md`):

```bash
# Preview migration (dry run)
bash node_modules/spec-flow/.spec-flow/scripts/bash/migrate-roadmap-to-github.sh --dry-run

# Run actual migration and archive old file
bash node_modules/spec-flow/.spec-flow/scripts/bash/migrate-roadmap-to-github.sh --archive
```

## Using Your GitHub Roadmap

### View Roadmap

**Via GitHub Web:**

- Browse: `https://github.com/YOUR_ORG/YOUR_REPO/issues`
- Filter by labels (e.g., click `status:next`)

**Via gh CLI:**

```bash
# All features in backlog
gh issue list --label status:backlog --label type:feature

# High priority items
gh issue list --label priority:high

# Backend features
gh issue list --label area:backend

# Features in next sprint
gh issue list --label status:next
```

### Create Features

**Via GitHub Web UI:**

1. Go to Issues → New Issue
2. Select "Feature Request" template
3. Fill in:
   - Feature slug (e.g., "student-progress-widget")
   - Impact (1-5): User value
   - Effort (1-5): Implementation complexity
   - Confidence (0-1): Estimate certainty
   - Area, Role, Requirements
4. Submit

**ICE Score Calculation:**

- Score = (Impact × Confidence) / Effort
- Higher scores = higher priority
- Labels automatically applied based on score

**Example:**

- Impact: 4 (high value)
- Effort: 2 (1-3 days)
- Confidence: 0.9 (high confidence)
- Score: 1.8 (high priority!)

### Using /roadmap Command

The `/roadmap` slash command integrates with GitHub Issues:

```bash
# Add feature to roadmap (creates GitHub issue)
/roadmap add "Student progress tracking dashboard"

# Brainstorm features (creates draft issues)
/roadmap brainstorm deep backend

# Move feature status
/roadmap move student-progress-dashboard to next

# View roadmap
gh issue list --label type:feature
```

**Note**: Current version of `/roadmap` command uses markdown. GitHub Issues integration is coming in v1.17.0.

### Workflow Integration

When you start a feature, it automatically links to the GitHub issue:

```bash
# Start feature (links to GitHub issue by slug)
/feature "student-progress-dashboard"

# Workflow automatically:
# 1. Finds issue by slug
# 2. Adds status:in-progress label
# 3. Stores issue number in workflow state

# When shipped:
/ship

# Workflow automatically:
# 1. Adds status:shipped label
# 2. Closes issue
# 3. Adds comment with version and deployment URL
```

## ICE Scoring Guide

### Impact (1-5): User Value

- **5 - Critical**: Core functionality, blocks users without it
- **4 - High Value**: Significantly improves user experience
- **3 - Useful**: Noticeable improvement
- **2 - Marginal**: Small improvement
- **1 - Nice to Have**: Minimal impact

### Effort (1-5): Implementation Complexity

- **1**: < 1 day
- **2**: 1-3 days
- **3**: 1-2 weeks
- **4**: 2-4 weeks
- **5**: 4+ weeks (consider splitting)

### Confidence (0-1): Estimate Certainty

- **1.0**: Certain (done this before)
- **0.9**: High confidence (clear requirements)
- **0.7**: Medium (some unknowns)
- **0.5**: Low (many unknowns)

### Priority Labels (Auto-Applied)

Based on ICE score:

- **High priority** (score >= 1.5): Quick wins, high value
- **Medium priority** (0.8 <= score < 1.5): Normal queue
- **Low priority** (score < 0.8): Nice to have

## Customization

### Customize Labels

Edit the area and role labels to match your project:

1. Delete default labels you don't need:

   ```bash
   gh label delete "role:student"
   ```

2. Create labels for your domain:

   ```bash
   gh label create "role:admin" --description "Admin users" --color "d4c5f9"
   gh label create "area:payments" --description "Payment processing" --color "0e8a16"
   ```

### Customize Issue Templates

Edit `.github/ISSUE_TEMPLATE/feature.yml` to match your project:

```yaml
# Change area options
- type: dropdown
  id: area
  attributes:
    label: Area
    options:
      - payments      # Your custom areas
      - analytics
      - dashboard
```

## GitHub Projects (Optional)

For visual roadmap management, create a GitHub Project:

1. **Create Project:**
   - Repo → Projects → New Project
   - Choose "Roadmap" template

2. **Auto-Add Issues:**
   - Settings → Workflows
   - Enable "Auto-add to project" for `type:feature` label

3. **Custom Views:**
   - Backlog: Filter `status:backlog`, sort by ICE score
   - Sprint: Filter `status:next`
   - In Progress: Filter `status:in-progress`

4. **Roadmap View:**
   - Add custom date fields (Start Date, Target Date)
   - Switch to "Roadmap" layout
   - Drag issues to timeline

## Troubleshooting

### "No GitHub authentication found"

**Fix:**

```bash
# Option 1: GitHub CLI
gh auth login

# Option 2: Token
export GITHUB_TOKEN=ghp_your_token
```

### "Label already exists"

This is normal on re-run. The script updates existing labels.

### "Command not found: gh"

Install GitHub CLI:

```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
```

### Migration creates duplicate issues

Delete all issues and re-run:

```bash
# WARNING: This deletes ALL issues
gh issue list --limit 1000 --json number -q '.[].number' | \
  xargs -I {} gh issue delete {} --yes

# Re-run migration
bash node_modules/spec-flow/.spec-flow/scripts/bash/migrate-roadmap-to-github.sh
```

### npm script fails on Windows

Use PowerShell scripts directly:

```powershell
pwsh -File node_modules\spec-flow\.spec-flow\scripts\powershell\setup-github-labels.ps1
```

## Next Steps

1. ✅ Roadmap set up with GitHub Issues
2. Create your first feature: `gh issue create --template feature.yml`
3. Start building: `/feature "your-feature-slug"`
4. Ship to production: `/ship`

## See Also

- **Issue Templates**: `.github/ISSUE_TEMPLATE/` (copied to your repo)
- **Technical Guide**: `node_modules/spec-flow/docs/github-roadmap-migration.md`
- **Spec-Flow Docs**: https://github.com/marcusgoll/Spec-Flow
- **GitHub Issues**: https://docs.github.com/en/issues

---

**Questions?** Create an issue: https://github.com/marcusgoll/Spec-Flow/issues

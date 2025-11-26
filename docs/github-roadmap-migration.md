# GitHub Issues Roadmap Guide

**Version**: 1.0.0
**Date**: 2025-10-20
**Status**: Core infrastructure complete, command updates in progress

## Overview

This guide covers GitHub Issues-based roadmap management for both:

1. **Workflow Development** (this repo) - Tracking improvements to the workflow system
2. **User Projects** (their repos) - Product roadmaps using the `/roadmap` command

## Important Distinction

**This Repository (Spec-Flow Workflow Kit):**

- An **npm package** that provides workflow commands
- Uses GitHub Issues to track workflow system improvements
- Old markdown roadmap has been **archived** (not migrated)

**User Repositories (Projects using the workflow):**

- Product development projects using this workflow
- Will use `/roadmap` command to manage product features
- Each project has its own GitHub Issues roadmap

## Benefits

✅ **Native GitHub Integration** - Issues, PRs, and roadmap in one place
✅ **Better Collaboration** - Comments, subscriptions, mentions
✅ **Automatic Linking** - PRs automatically close issues
✅ **Rich Metadata** - Labels, milestones, assignees, projects
✅ **API Access** - Programmatic roadmap management
✅ **No Sync Complexity** - Single source of truth
✅ **ICE Scoring** - Prioritization via frontmatter in issue descriptions

## What's Been Completed

### Phase 1: GitHub Setup

- ✅ **Issue Templates** (`.github/ISSUE_TEMPLATE/`)

  - `feature.yml` - Feature requests with ICE scoring
  - `enhancement.yml` - Enhancements to existing features
  - `bug.yml` - Bug reports
  - `task.yml` - Implementation tasks

- ✅ **Label Setup Scripts**
  - `.spec-flow/scripts/bash/setup-github-labels.sh`
  - `.spec-flow/scripts/powershell/setup-github-labels.ps1`
  - Creates 30+ labels for priority, type, area, role, status, size

### Phase 2: Roadmap Manager

- ✅ **GitHub Roadmap Manager** (bash)

  - `.spec-flow/scripts/bash/github-roadmap-manager.sh`
  - Functions: create, query, update, mark in-progress, mark shipped
  - ICE scoring and frontmatter generation
  - Dual authentication (gh CLI + GitHub API)

- ✅ **GitHub Roadmap Manager** (PowerShell)

  - `.spec-flow/scripts/powershell/github-roadmap-manager.ps1`
  - Windows-compatible version
  - Same functionality as bash version

- ✅ **Migration Script**
  - `.spec-flow/scripts/bash/migrate-roadmap-to-github.sh`
  - Parses existing roadmap.md
  - Creates GitHub issues with proper labels and state
  - Preserves ICE scores, links to spec directories

## Setup for Workflow Development (This Repo)

### Step 1: Authenticate with GitHub

Choose one of the following:

**Option A: GitHub CLI (Recommended)**

```bash
gh auth login
# Follow prompts to authenticate
```

**Option B: Personal Access Token**

```bash
# Create token at: https://github.com/settings/tokens
# Required scopes: repo, write:discussion

export GITHUB_TOKEN=ghp_your_token_here

# On Windows PowerShell:
$env:GITHUB_TOKEN = "ghp_your_token_here"
```

### Step 2: Setup Labels

Run the label setup script to create all necessary labels:

**macOS/Linux:**

```bash
chmod +x .spec-flow/scripts/bash/setup-github-labels.sh

# Dry run to preview
./spec-flow/scripts/bash/setup-github-labels.sh --dry-run

# Create labels
./.spec-flow/scripts/bash/setup-github-labels.sh
```

**Windows PowerShell:**

```powershell
# Dry run to preview
.\.spec-flow\scripts\powershell\setup-github-labels.ps1 -DryRun

# Create labels
.\.spec-flow\scripts\powershell\setup-github-labels.ps1
```

**Expected Output:**

```
✓ GitHub CLI authenticated
✓ Repository: your-org/your-repo

Creating GitHub Labels
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Priority Labels:
✓ Created: priority:high
✓ Created: priority:medium
✓ Created: priority:low

...

LABELS CREATED SUCCESSFULLY
```

### Step 3: Start Using GitHub Issues

The old markdown roadmap has been archived. Start creating workflow improvements:

```bash
# Create workflow improvement via web UI
# Go to: Issues → New Issue → Feature Request

# Or via CLI
gh issue create --template feature.yml

# List workflow improvements
gh issue list --label type:feature
```

## Setup for User Projects

Users of this workflow will set up roadmap management in their own repos:

### For User Projects

```bash
# 1. In user's project repository
cd /path/to/user/project

# 2. Authenticate (if not already)
gh auth login

# 3. Copy label setup script from workflow package
cp node_modules/@your-org/spec-flow-workflow/.spec-flow/scripts/bash/setup-github-labels.sh .

# 4. Run label setup
./setup-github-labels.sh

# 5. Use /roadmap command (will be updated to use GitHub Issues)
# Currently uses markdown, will be updated
```

**Note**: The `/roadmap` command integration for user projects is pending implementation.

## Using the New GitHub Roadmap

### Viewing the Roadmap

**Via GitHub Web UI:**

- Browse issues: `https://github.com/YOUR_ORG/YOUR_REPO/issues`
- Filter by labels: Click labels like `status:next`, `area:backend`
- Create views: Save custom filters

**Via GitHub CLI:**

```bash
# List all features in backlog
gh issue list --label status:backlog --label type:feature

# List by priority
gh issue list --label priority:high

# List by area
gh issue list --label area:backend

# Search
gh issue list --search "authentication"
```

**Via API (for scripts):**

```bash
# Source the roadmap manager
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# List issues by status
list_issues_by_status "next"

# Get issue by slug
get_issue_by_slug "student-progress-widget"
```

### Creating Features

**Via GitHub Web UI:**

- Go to Issues → New Issue
- Select "Feature Request" template
- Fill in ICE scores, area, role, requirements
- Submit

**Via Script:**

```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

create_roadmap_issue \
  "Student Progress Widget" \
  "## Problem\n\nStudents can't track mastery.\n\n## Solution\n\nAdd widget to results page." \
  4 \
  2 \
  0.9 \
  "app" \
  "student" \
  "student-progress-widget" \
  "type:feature,status:backlog"
```

**Via PowerShell:**

```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

New-RoadmapIssue `
  -Title "Student Progress Widget" `
  -Body "## Problem`n`nStudents can't track mastery.`n`n## Solution`n`nAdd widget to results page." `
  -Impact 4 `
  -Effort 2 `
  -Confidence 0.9 `
  -Area "app" `
  -Role "student" `
  -Slug "student-progress-widget" `
  -Labels "type:feature,status:backlog"
```

### Updating Feature Status

**Mark as In Progress:**

```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

mark_issue_in_progress "student-progress-widget"
# ✅ Marked issue #123 as In Progress in roadmap
```

**Mark as Shipped:**

```bash
mark_issue_shipped "student-progress-widget" "1.2.0" "2025-10-20" "https://app.example.com"
# ✅ Marked issue #123 as Shipped (v1.2.0) in roadmap
```

### ICE Scoring Format

Issues include YAML frontmatter in the description:

```yaml
---
ice:
  impact: 4
  effort: 2
  confidence: 0.9
  score: 1.8
metadata:
  area: app
  role: student
  slug: student-progress-widget
---

## Problem
Students struggle to track which ACS codes they've mastered...

## Proposed Solution
Add a progress widget to the results page...

## Requirements
- [ ] Display mastery percentage
- [ ] Group by ACS area
- [ ] Use existing data (no backend changes)
```

**Parsing ICE Scores:**

```bash
# Get issue
issue=$(gh issue view 123 --json body -q .body)

# Parse ICE
source .spec-flow/scripts/bash/github-roadmap-manager.sh
ice_data=$(parse_ice_from_body "$issue")

# Extract values
impact=$(echo "$ice_data" | jq -r '.impact')
effort=$(echo "$ice_data" | jq -r '.effort')
score=$(calculate_ice_score "$impact" "$effort" "$confidence")
```

## Label Schema

### Priority Labels

- `priority:high` - High priority, address soon (ICE score >= 1.5)
- `priority:medium` - Medium priority, normal queue (0.8 <= ICE < 1.5)
- `priority:low` - Low priority, nice to have (ICE < 0.8)

### Type Labels

- `type:feature` - New feature or functionality
- `type:enhancement` - Enhancement to existing feature
- `type:bug` - Bug or defect
- `type:task` - Task or chore

### Area Labels

- `area:backend` - Backend/API code
- `area:frontend` - Frontend/UI code
- `area:api` - API endpoints and contracts
- `area:infra` - Infrastructure and DevOps
- `area:design` - Design and UX
- `area:marketing` - Marketing pages and content

### Role Labels

- `role:all` - All users
- `role:free` - Free tier users
- `role:student` - Student users
- `role:cfi` - CFI (instructor) users
- `role:school` - School/organization users

### Status Labels (Workflow States)

- `status:backlog` - Backlog - not yet prioritized
- `status:next` - Next - queued for implementation
- `status:later` - Later - future consideration
- `status:in-progress` - In Progress - actively being worked on
- `status:shipped` - Shipped - deployed to production (issue closed)
- `status:blocked` - Blocked - waiting on dependency

### Size Labels (Effort Estimation)

- `size:small` - Small - < 1 day
- `size:medium` - Medium - 1-2 weeks
- `size:large` - Large - 2-4 weeks
- `size:xl` - Extra Large - 4+ weeks (consider splitting)

### Special Labels

- `blocked` - Blocked by dependency or external factor
- `good-first-issue` - Good for newcomers
- `help-wanted` - Extra attention needed
- `wont-fix` - Will not be implemented
- `duplicate` - Duplicate of another issue
- `needs-clarification` - Needs more information

## What Remains (Pending Implementation)

### Command Updates

The following slash commands need to be updated to use GitHub Issues:

1. **`/roadmap`** - Main roadmap command

   - Replace markdown operations with GitHub API calls
   - Actions: add, brainstorm, move, delete, search, ship

2. **`/feature`** - Feature workflow orchestrator

   - Query GitHub for existing issue by slug
   - Link issue to state.yaml
   - Call `mark_issue_in_progress()` when starting

3. **`/ship` and `/ship-prod`** - Deployment commands

   - Call `mark_issue_shipped()` instead of `mark_feature_shipped()`
   - Add deployment URL as comment on issue
   - Close issue when shipped

4. **Agent Briefs**

   - `.claude/agents/phase/ship-prod.md` - Update roadmap references
   - `.claude/agents/phase/finalize.md` - Update to close GitHub issue

5. **Skills**

   - `.claude/skills/roadmap-integration.md` - Update with GitHub workflow

6. **Documentation**
   - `CLAUDE.md` - Replace roadmap.md references with GitHub Issues
   - `README.md` - Update roadmap workflow section

### Example: Updating /roadmap Command

The `/roadmap` command (`.claude/commands/roadmap.md`) needs these changes:

**Before (Markdown):**

```bash
# Add feature to roadmap
echo "$FEATURE_DATA" >> .spec-flow/memory/roadmap.md
```

**After (GitHub Issues):**

```bash
# Source GitHub roadmap manager
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Add feature to roadmap
create_roadmap_issue "$TITLE" "$BODY" "$IMPACT" "$EFFORT" "$CONFIDENCE" "$AREA" "$ROLE" "$SLUG"
```

### Example: Updating /feature Command

In `.claude/commands/feature.md`, add after slug generation:

```bash
# Check if GitHub issue exists for this feature
source .spec-flow/scripts/bash/github-roadmap-manager.sh

ISSUE=$(get_issue_by_slug "$SLUG")

if [ -n "$ISSUE" ] && [ "$ISSUE" != "null" ]; then
  ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')
  echo "✅ Found roadmap issue: #$ISSUE_NUMBER"

  # Store in workflow state
  yq eval -i ".feature.github_issue = $ISSUE_NUMBER" "$FEATURE_DIR/state.yaml"

  # Mark as in-progress
  mark_issue_in_progress "$SLUG"
else
  echo "⚠️  No roadmap issue found for: $SLUG"
  echo "   Create one with: /roadmap add \"$FEATURE_DESCRIPTION\""
fi
```

## Troubleshooting

### Authentication Issues

**Problem**: "No GitHub authentication found"

**Solution**:

```bash
# Check gh CLI status
gh auth status

# Re-authenticate if needed
gh auth login

# OR use PAT
export GITHUB_TOKEN=ghp_your_token
```

### Rate Limiting

**Problem**: "API rate limit exceeded"

**Solution**:

- Authenticated users: 5000 requests/hour
- Add delays between bulk operations
- Check remaining quota: `gh api rate_limit`

### Migration Issues

**Problem**: Issue creation fails

**Solutions**:

1. Verify labels exist: `gh label list`
2. Check repository permissions: `gh repo view`
3. Run setup-github-labels.sh first
4. Use `--dry-run` to test without creating

### Label Not Found

**Problem**: "Label 'status:backlog' does not exist"

**Solution**:

```bash
# Recreate labels
./.spec-flow/scripts/bash/setup-github-labels.sh
```

### Duplicate Issues

**Problem**: Running migration twice creates duplicates

**Solution**:

```bash
# Delete all roadmap issues (CAREFUL!)
gh issue list --label type:feature --limit 1000 --json number -q '.[].number' | \
  xargs -I {} gh issue delete {} --yes

# Re-run migration
./.spec-flow/scripts/bash/migrate-roadmap-to-github.sh
```

## Best Practices

### 1. Use Descriptive Slugs

- Keep slugs URL-friendly: `lowercase-with-hyphens`
- Make them unique and searchable
- Max 30 characters for readability

### 2. Maintain ICE Scores

- Update scores when estimates change
- Re-sort backlog periodically by ICE
- Document confidence changes in comments

### 3. Link Issues to PRs

- Reference issues in PR descriptions: "Closes #123"
- GitHub will auto-close issues when PRs merge
- Maintains clean audit trail

### 4. Use Projects for Visualization

- Create GitHub Project for roadmap view
- Use "Roadmap" layout for timeline
- Add custom fields for quarters/themes

### 5. Regular Grooming

- Review `status:backlog` monthly
- Close stale issues with `wont-fix`
- Merge duplicates
- Update priorities based on new data

## GitHub Projects Setup (Optional)

For visual roadmap management:

1. **Create Project:**

   - Go to repository → Projects → New Project
   - Choose "Roadmap" template

2. **Add Custom Fields:**

   - ICE Score (number)
   - Quarter (select: Q1, Q2, Q3, Q4)
   - Theme (text)

3. **Configure Views:**

   - Backlog: Filter `status:backlog`, sort by ICE score descending
   - Next: Filter `status:next`
   - In Progress: Filter `status:in-progress`
   - Shipped: Filter `status:shipped`

4. **Automation:**
   - Auto-add issues with `type:feature` label
   - Auto-move to "Shipped" when closed

## References

- **GitHub Issues Docs**: https://docs.github.com/en/issues
- **GitHub Projects Docs**: https://docs.github.com/en/issues/planning-and-tracking-with-projects
- **GitHub CLI Manual**: https://cli.github.com/manual/
- **GitHub API**: https://docs.github.com/en/rest/issues

## Support

If you encounter issues:

1. Check this troubleshooting guide
2. Review GitHub authentication: `gh auth status`
3. Test with `--dry-run` flags
4. Check issue tracker for similar problems
5. Create issue with `help-wanted` label

---

**Next Steps**: Update slash commands to use GitHub Issues API (see "What Remains" section above)

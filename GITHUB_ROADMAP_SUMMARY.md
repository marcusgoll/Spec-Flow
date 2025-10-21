# GitHub Issues Roadmap - Implementation Summary

**Date**: 2025-10-20
**Status**: Core infrastructure complete, ready for workflow development

---

## What Was Accomplished

### ✅ Phase 1: GitHub Setup

**Issue Templates** created in `.github/ISSUE_TEMPLATE/`:
- `feature.yml` - Feature requests with ICE scoring
- `enhancement.yml` - Enhancements
- `bug.yml` - Bug reports
- `task.yml` - Tasks
- `config.yml` - Template configuration

**Label Setup Scripts**:
- `.spec-flow/scripts/bash/setup-github-labels.sh`
- `.spec-flow/scripts/powershell/setup-github-labels.ps1`
- Creates 30+ labels (priority, type, area, role, status, size)

### ✅ Phase 2: Roadmap Manager

**Bash Functions** (`.spec-flow/scripts/bash/github-roadmap-manager.sh`):
- Dual authentication (gh CLI + GitHub API fallback)
- ICE score calculation and parsing
- Issue CRUD operations
- Status management (in-progress, shipped)
- Feature discovery

**PowerShell Functions** (`.spec-flow/scripts/powershell/github-roadmap-manager.ps1`):
- Windows-compatible version
- Same functionality as bash

**Migration Tool** (`.spec-flow/scripts/bash/migrate-roadmap-to-github.sh`):
- Created but **not needed** (no migration required)
- Can be used by users in their own repos

### ✅ Phase 3: Documentation

**Guides Created**:
1. `docs/WORKFLOW_DEVELOPMENT_ROADMAP.md` - For workflow contributors
2. `docs/github-roadmap-migration.md` - Technical reference
3. `.spec-flow/memory/ROADMAP_ARCHIVE_README.md` - Archive explanation

**Updated Files**:
- `CLAUDE.md` - Added GitHub Issues roadmap section with distinction between workflow dev and user projects

**Archived**:
- Old roadmap → `.spec-flow/memory/roadmap-archived-2025-10-20.md`

---

## Key Clarification: Two Roadmap Use Cases

### 1. Workflow Development (This Repo)

**What**: Improvements to the Spec-Flow Workflow Kit itself

**Example Issues**:
- "Add GitHub Projects integration to `/roadmap` command"
- "Improve parallel task execution in `/implement`"
- "Add automatic rollback on deployment failure"

**Where**: This repo's GitHub Issues

**Status**: ✅ **Ready to use now**

**Quick Start**:
```bash
# Setup (one-time)
gh auth login
./.spec-flow/scripts/bash/setup-github-labels.sh

# Create workflow improvement
gh issue create --template feature.yml

# View roadmap
gh issue list --label type:feature
```

### 2. User Project Roadmaps (Their Repos)

**What**: Product features that users build with this workflow

**Example Issues** (in user repos):
- "Student progress tracking dashboard"
- "CSV export functionality"
- "OAuth authentication"

**Where**: User's own repository GitHub Issues

**Status**: ⏳ **Pending** - `/roadmap` command needs update

**Planned Flow**:
1. User installs workflow: `npm install @your-org/spec-flow-workflow`
2. User runs: `/roadmap add "Feature description"`
3. Command creates GitHub issue in **their repo**
4. `/feature` links to issue, marks in-progress
5. `/ship` closes issue, marks shipped

---

## What's Ready to Use Now

### For Workflow Development

You can immediately start tracking workflow improvements:

```bash
# View current workflow roadmap
gh issue list --repo YOUR_ORG/workflow --label type:feature

# Create a workflow improvement
gh issue create --repo YOUR_ORG/workflow --template feature.yml

# Or programmatically
cd /path/to/workflow
source .spec-flow/scripts/bash/github-roadmap-manager.sh

create_roadmap_issue \
  "Add GitHub Projects to /roadmap" \
  "## Problem\n\nUsers want visual roadmap\n\n## Solution\n\nIntegrate Projects API" \
  4 \
  3 \
  0.8 \
  "infra" \
  "all" \
  "roadmap-github-projects"
```

### Example Workflow Improvements to Track

Here are some suggested first issues for workflow development:

1. **High Priority**: Update `/roadmap` command for GitHub Issues
   - Impact: 5, Effort: 3, Confidence: 0.8
   - Score: 1.33
   - Enables users to use GitHub roadmaps

2. **High Priority**: Update `/feature` to link GitHub issues
   - Impact: 4, Effort: 2, Confidence: 0.9
   - Score: 1.8
   - Auto-tracks feature progress

3. **Medium Priority**: Update `/ship` to close issues
   - Impact: 4, Effort: 2, Confidence: 1.0
   - Score: 2.0
   - Completes the workflow loop

4. **Low Priority**: Add GitHub Projects visualization
   - Impact: 3, Effort: 4, Confidence: 0.6
   - Score: 0.45
   - Nice visual but significant work

---

## What Needs Implementation

### Critical Path (For User Projects)

These updates are needed for users to adopt GitHub Issues roadmaps:

#### 1. Update `/roadmap` Command

**File**: `.claude/commands/roadmap.md`

**Changes Needed**:
- Replace markdown operations with GitHub API calls
- Source github-roadmap-manager.sh functions
- Create issues in user's repo (not workflow repo)
- Maintain same ICE scoring and brainstorming features

**Example**:
```bash
# OLD (markdown)
echo "### $slug" >> .spec-flow/memory/roadmap.md

# NEW (GitHub Issues)
source .spec-flow/scripts/bash/github-roadmap-manager.sh
create_roadmap_issue "$title" "$body" "$impact" "$effort" "$confidence" "$area" "$role" "$slug"
```

#### 2. Update `/feature` Command

**File**: `.claude/commands/feature.md`

**Changes Needed**:
- Check for linked GitHub issue by slug
- Store issue number in workflow-state.yaml
- Call `mark_issue_in_progress()` when starting

**Add After Slug Generation**:
```bash
# Link to GitHub issue if exists
source .spec-flow/scripts/bash/github-roadmap-manager.sh
issue=$(get_issue_by_slug "$SLUG")

if [ -n "$issue" ]; then
  issue_num=$(echo "$issue" | jq -r '.number')
  yq eval -i ".feature.github_issue = $issue_num" "$STATE_FILE"
  mark_issue_in_progress "$SLUG"
fi
```

#### 3. Update `/ship` Command

**File**: `.claude/commands/ship.md`

**Changes Needed**:
- Call `mark_issue_shipped()` in finalize phase
- Add deployment URL to issue comment
- Close issue when feature ships

**Add in Phase S.5 (Finalize)**:
```bash
# Update GitHub issue
source .spec-flow/scripts/bash/github-roadmap-manager.sh
mark_issue_shipped "$SLUG" "$VERSION" "$DATE" "$PROD_URL"
```

#### 4. Update Agent Briefs

**Files**:
- `.claude/agents/phase/ship-prod.md`
- `.claude/agents/phase/finalize.md`

**Changes**: Replace roadmap.md references with GitHub Issues calls

---

## File Structure

```
workflow/
├── .github/
│   └── ISSUE_TEMPLATE/
│       ├── feature.yml          ✅ Created
│       ├── enhancement.yml      ✅ Created
│       ├── bug.yml              ✅ Created
│       ├── task.yml             ✅ Created
│       └── config.yml           ✅ Created
│
├── .spec-flow/
│   ├── memory/
│   │   ├── roadmap-archived-2025-10-20.md    ✅ Archived
│   │   └── ROADMAP_ARCHIVE_README.md         ✅ Created
│   │
│   └── scripts/
│       ├── bash/
│       │   ├── setup-github-labels.sh        ✅ Created
│       │   ├── github-roadmap-manager.sh     ✅ Created
│       │   └── migrate-roadmap-to-github.sh  ✅ Created (for users)
│       │
│       └── powershell/
│           ├── setup-github-labels.ps1       ✅ Created
│           └── github-roadmap-manager.ps1    ✅ Created
│
├── .claude/
│   ├── commands/
│   │   ├── roadmap.md                        ⏳ Needs update
│   │   ├── feature.md                        ⏳ Needs update
│   │   └── ship.md                           ⏳ Needs update
│   │
│   └── agents/
│       └── phase/
│           ├── ship-prod.md                  ⏳ Needs update
│           └── finalize.md                   ⏳ Needs update
│
├── docs/
│   ├── WORKFLOW_DEVELOPMENT_ROADMAP.md       ✅ Created
│   └── github-roadmap-migration.md           ✅ Created
│
├── CLAUDE.md                                  ✅ Updated
└── GITHUB_ROADMAP_SUMMARY.md                 ✅ This file
```

---

## Next Steps

### Immediate (For Workflow Development)

1. **Setup GitHub Issues** for this repo:
   ```bash
   cd /path/to/workflow
   gh auth login
   ./.spec-flow/scripts/bash/setup-github-labels.sh
   ```

2. **Create First Issues** for workflow improvements:
   - Update `/roadmap` command
   - Update `/feature` command
   - Update `/ship` command

3. **Start Using Issues** for workflow development

### Future (For User Support)

1. **Update `/roadmap` command** to use GitHub Issues (high priority)
2. **Update `/feature` command** to link issues
3. **Update `/ship` command** to close issues
4. **Update agent briefs** to use new functions
5. **Test in sample project** before releasing
6. **Document for users** in README

---

## Testing Plan

### Test Workflow Development (Now)

```bash
# 1. Setup
cd /path/to/workflow
gh auth login
./.spec-flow/scripts/bash/setup-github-labels.sh

# 2. Create test issue
gh issue create --template feature.yml

# 3. Test functions
source .spec-flow/scripts/bash/github-roadmap-manager.sh
mark_issue_in_progress "test-feature"
mark_issue_shipped "test-feature" "1.0.0" "2025-10-20"

# 4. Verify
gh issue list
gh issue view 1
```

### Test User Project (After Updates)

```bash
# 1. Create test project
mkdir test-project && cd test-project
npm init -y
npm install @your-org/spec-flow-workflow

# 2. Setup roadmap
./node_modules/.bin/setup-github-labels

# 3. Test workflow
/roadmap add "Test feature"
/feature "Test feature"
/ship

# 4. Verify issue lifecycle
gh issue list
```

---

## Success Criteria

✅ **Workflow Development**: GitHub Issues active for workflow improvements
⏳ **User Projects**: `/roadmap` command uses GitHub Issues
⏳ **Integration**: `/feature` and `/ship` link to issues
⏳ **Documentation**: User guide for GitHub roadmap setup
⏳ **Testing**: Validated in sample project

---

## Questions?

- **Workflow development**: See `docs/WORKFLOW_DEVELOPMENT_ROADMAP.md`
- **Technical details**: See `docs/github-roadmap-migration.md`
- **Archive info**: See `.spec-flow/memory/ROADMAP_ARCHIVE_README.md`
- **Main docs**: See `CLAUDE.md` roadmap section

---

**Status**: ✅ Ready for workflow development, ⏳ User project integration pending

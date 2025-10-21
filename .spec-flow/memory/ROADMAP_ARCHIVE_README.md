# Roadmap Archive

**Date**: 2025-10-20

## What Happened

The markdown-based roadmap (`roadmap.md`) has been **archived** and replaced with GitHub Issues for tracking workflow development.

## Why the Change

This repository contains the **Spec-Flow Workflow Kit** - an npm package that other projects use to manage their product development.

**Two Different Roadmaps:**
1. **Workflow Development** (this repo) - Tracked via GitHub Issues
   - Improvements to the workflow system itself
   - New slash commands
   - Better automation
   - Bug fixes in the workflow

2. **User Project Roadmaps** (user repos) - Managed by `/roadmap` command
   - Product features users are building
   - Uses GitHub Issues in their own repos
   - Managed by the workflow tools we provide

## Archived File

The previous workflow development roadmap has been archived to:
- `roadmap-archived-2025-10-20.md`

This file is kept for historical reference only.

## Moving Forward

### For Workflow Development (This Repo)

Use GitHub Issues to track improvements to the workflow system:

```bash
# View workflow development roadmap
gh issue list --label type:feature

# Create workflow improvement
gh issue create --template feature.yml

# Or programmatically
source .spec-flow/scripts/bash/github-roadmap-manager.sh
create_roadmap_issue "Improve /roadmap command" "Add GitHub Projects support" 4 3 0.8 "infra" "all" "roadmap-projects-support"
```

### For User Projects

Users of this workflow will manage their own product roadmaps using:
- The `/roadmap` slash command (in their repos)
- GitHub Issues in their own repositories
- The same tools we've built, but for their products

## Key Files

**Workflow Development Tools:**
- `.github/ISSUE_TEMPLATE/` - Issue templates for workflow improvements
- `.spec-flow/scripts/bash/setup-github-labels.sh` - Label setup
- `.spec-flow/scripts/bash/github-roadmap-manager.sh` - Roadmap functions

**User-Facing Tools:**
- `.claude/commands/roadmap.md` - `/roadmap` command users will use
- (Will be updated to use GitHub Issues in user repos)

## Migration Status

- ✅ Labels created for this repo
- ✅ GitHub Issues set up for workflow development
- ✅ Old roadmap archived
- ⏳ `/roadmap` command - Still uses markdown (to be updated for user repos)
- ⏳ Workflow commands integration

## See Also

- `docs/github-roadmap-migration.md` - Full technical guide
- This repo's issues: https://github.com/YOUR_ORG/workflow/issues

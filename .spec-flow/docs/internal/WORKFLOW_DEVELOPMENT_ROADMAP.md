# Workflow Development Roadmap

**Purpose**: Track improvements and features for the Spec-Flow Workflow Kit itself

**Audience**: Contributors developing the workflow system

---

## Quick Start

This repo uses GitHub Issues to track workflow development. Users of the workflow will use the `/roadmap` command in their own repos.

### Setup (One-Time)

```bash
# 1. Authenticate with GitHub
gh auth login

# 2. Create labels for this repo
./.spec-flow/scripts/bash/setup-github-labels.sh
```

### Usage

**View Roadmap:**
```bash
# All workflow improvements
gh issue list --label type:feature

# By priority
gh issue list --label priority:high

# By area
gh issue list --label area:backend
gh issue list --label area:infra

# By status
gh issue list --label status:next
gh issue list --label status:in-progress
```

**Create Workflow Improvement:**
```bash
# Via GitHub Web UI
# Go to: Issues → New Issue → Feature Request

# Or via CLI
gh issue create --template feature.yml
```

**Programmatic Creation:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

create_roadmap_issue \
  "Add GitHub Projects integration to /roadmap" \
  "## Problem\n\nUsers want visual roadmap view\n\n## Solution\n\nIntegrate GitHub Projects API" \
  4 \
  3 \
  0.8 \
  "infra" \
  "all" \
  "roadmap-projects-integration"
```

## Roadmap Categories

### Type Labels
- `type:feature` - New workflow feature (new command, new capability)
- `type:enhancement` - Improvement to existing workflow feature
- `type:bug` - Bug in the workflow system
- `type:task` - Maintenance or documentation task

### Area Labels (Workflow Components)
- `area:backend` - Core workflow logic, state management
- `area:frontend` - CLI output, user interaction
- `area:api` - GitHub API integration, external services
- `area:infra` - Build system, deployment, CI/CD
- `area:design` - Templates, formatting, structure

### Priority Labels (ICE-Based)
- `priority:high` - Critical for workflow usability
- `priority:medium` - Useful improvement
- `priority:low` - Nice to have

### Status Labels
- `status:backlog` - Identified but not prioritized
- `status:next` - Queued for implementation
- `status:in-progress` - Actively being worked on
- `status:shipped` - Deployed in published npm package

## ICE Scoring for Workflow Features

When creating workflow improvements, use ICE scoring:

**Impact** (1-5): How much does this improve the workflow for users?
- 5 = Critical - Makes workflow usable/prevents major pain
- 4 = High value - Significantly improves user experience
- 3 = Useful - Noticeable improvement
- 2 = Marginal - Small improvement
- 1 = Nice to have - Minimal impact

**Effort** (1-5): How much work to implement?
- 1 = < 1 day
- 2 = 1-3 days
- 3 = 1-2 weeks
- 4 = 2-4 weeks
- 5 = 4+ weeks (consider splitting)

**Confidence** (0-1): How certain are the estimates?
- 1.0 = Certain (have done this before)
- 0.9 = High (clear requirements)
- 0.7 = Medium (some unknowns)
- 0.5 = Low (many unknowwns)

**Score** = (Impact × Confidence) / Effort

Higher scores = higher priority for workflow development.

## Example Workflow Improvements

### High Priority (Score >= 1.5)
- GitHub Projects integration for `/roadmap` (I:4, E:2, C:0.9 = 1.8)
- Parallel task execution in `/implement` (I:5, E:3, C:0.8 = 1.33)
- Automatic rollback on deployment failure (I:5, E:3, C:0.9 = 1.5)

### Medium Priority (0.8 <= Score < 1.5)
- Add `/metrics` command for HEART metrics (I:4, E:4, C:0.8 = 0.8)
- Improve error messages in state management (I:3, E:2, C:1.0 = 1.5)

### Low Priority (Score < 0.8)
- Add emoji support to task completion (I:2, E:1, C:1.0 = 2.0) ← Wait, this is high!
- Custom color schemes for CLI output (I:2, E:3, C:0.8 = 0.53)

## Contributing Workflow Improvements

1. **Check existing issues** - Search before creating duplicates
2. **Use issue templates** - Provides consistent structure
3. **Include ICE scores** - Helps with prioritization
4. **Link to related issues** - Reference dependencies
5. **Test in real project** - Verify improvement works
6. **Update docs** - Keep CLAUDE.md and README in sync

## Distinction: Workflow vs User Roadmaps

**This Repo (Workflow Development):**
- **What**: Improvements to the workflow system itself
- **Where**: This repo's GitHub Issues
- **Who**: Workflow contributors and maintainers
- **Example**: "Add GitHub Projects integration to `/roadmap` command"

**User Repos (Product Development):**
- **What**: Product features users are building
- **Where**: User's repo GitHub Issues
- **Who**: Users of the workflow
- **Tools**: `/roadmap` command, workflow templates
- **Example**: "Student progress tracking dashboard"

## Current Status

- ✅ GitHub Issues set up for workflow development
- ✅ Labels created
- ✅ Old markdown roadmap archived
- ⏳ `/roadmap` command - Update needed for user repos
- ⏳ Integration with `/feature`, `/ship` commands

## See Also

- `docs/github-roadmap-migration.md` - Technical migration details
- `.spec-flow/memory/ROADMAP_ARCHIVE_README.md` - Archive explanation
- `.spec-flow/memory/roadmap-archived-2025-10-20.md` - Historical roadmap

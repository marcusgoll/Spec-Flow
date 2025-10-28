# /finalize - Complete Documentation & Cleanup After Deployment

**Purpose**: Complete all documentation housekeeping, roadmap updates, and cleanup tasks after successful production deployment.

**Dependencies**: Requires successful production deployment (from `/ship-prod` or `/deploy-prod`)

**Usage**: `/finalize`

<context>
## TODO TRACKING REQUIREMENT

**CRITICAL**: You MUST use TodoWrite to track all finalization tasks.

**Why this matters**: The /finalize phase involves 7-10 distinct tasks that users expect to be completed:
- Without TodoWrite, tasks are silently skipped (releases not created, issues not updated, branches not cleaned)
- User has no visibility into what's done vs what's pending
- Hard to resume if errors occur (e.g., GitHub API failures)

**Create todo list IMMEDIATELY** after loading context, then update after EVERY task completes.
</context>

<instructions>

## Step 1: Initialize & Create Todo List

1. Find most recent feature directory (specs/NNN-slug/)
2. Read workflow-state.yaml to get:
   - Feature title and slug
   - Deployment version (from ship-prod or deploy-prod phase)
   - Production URL
3. **IMMEDIATELY create TodoWrite list**:

```
TodoWrite({
  todos: [
    {content: "Load feature context and version info", status: "completed", activeForm: "..."},
    {content: "Update CHANGELOG.md with new version section", status: "in_progress", activeForm: "Updating CHANGELOG.md"},
    {content: "Update README.md (features list and version badge)", status: "pending", activeForm: "Updating README.md"},
    {content: "Generate user documentation (help article)", status: "pending", activeForm: "Generating help docs"},
    {content: "Update API documentation (if endpoints changed)", status: "pending", activeForm: "Updating API docs"},
    {content: "Close current GitHub milestone", status: "pending", activeForm: "Closing milestone"},
    {content: "Create next GitHub milestone", status: "pending", activeForm: "Creating next milestone"},
    {content: "Update roadmap issue status to 'shipped'", status: "pending", activeForm: "Updating roadmap"},
    {content: "Commit all documentation changes", status: "pending", activeForm: "Committing documentation"},
    {content: "Clean up feature branch (delete local and remote)", status: "pending", activeForm: "Cleaning up branch"},
  ]
})
```

## Step 2: Update CHANGELOG.md

1. Read CHANGELOG.md (if exists)
2. Read git commit history since last version:
   ```bash
   git log --oneline --grep="^feat:" --grep="^fix:" --grep="^security:" --grep="^refactor:" --since="[last-version-date]"
   ```
3. Categorize commits:
   - `feat:` → **Added** section
   - `fix:` → **Fixed** section
   - `refactor:` → **Changed** section
   - `security:` → **Security** section
4. Insert new version section at top of CHANGELOG.md:
   ```markdown
   ## [vX.Y.Z] - YYYY-MM-DD

   ### Added
   - Feature description from spec.md

   ### Fixed
   - Bug fixes from commits

   ### Changed
   - Refactorings from commits

   ### Security
   - Security improvements from commits
   ```

**After completion**:
- **Update TodoWrite**: Mark CHANGELOG as `completed`, mark README as `in_progress`
- Continue to Step 3

**If error** (e.g., CHANGELOG.md missing):
- **Update TodoWrite**: Add "Create CHANGELOG.md file" as new todo
- Create file with template
- Retry

## Step 3: Update README.md

1. Read README.md
2. Update version badge (if exists):
   ```markdown
   ![Version](https://img.shields.io/badge/version-vX.Y.Z-blue)
   ```
3. Add new feature to features list (extract from spec.md):
   ```markdown
   ## Features

   - 🎉 **New Feature Name** - Brief description (vX.Y.Z)
   - ... (existing features)
   ```

**After completion**:
- **Update TodoWrite**: Mark README as `completed`, mark help docs as `in_progress`
- Continue to Step 4

## Step 4: Generate User Documentation

1. Check if docs/help/features/ directory exists (create if not)
2. Create new help article: `docs/help/features/[feature-slug].md`
3. Extract content from spec.md:
   - User stories → "How to use" section
   - Acceptance criteria → "Features" section
   - Visuals → Screenshots/diagrams
4. Template:
   ```markdown
   # Feature Name

   **Version**: vX.Y.Z
   **Released**: YYYY-MM-DD

   ## Overview

   [Brief description from spec.md]

   ## How to Use

   [Step-by-step from user stories]

   ## Features

   - [Acceptance criteria as feature list]

   ## Screenshots

   [Embed visuals from spec.md]

   ## Troubleshooting

   [Common issues if any]
   ```
5. Update docs/help/README.md index:
   ```markdown
   ## Features

   - [Feature Name](features/[feature-slug].md) - Brief description (vX.Y.Z)
   ```

**After completion**:
- **Update TodoWrite**: Mark help docs as `completed`, mark API docs as `in_progress`
- Continue to Step 5

**If error** (e.g., docs directory missing):
- **Update TodoWrite**: Add "Create docs/help structure" as new todo
- Create directories
- Retry

## Step 5: Update API Documentation (Conditional)

1. Check if feature modified API endpoints:
   - Search spec.md for "API", "endpoint", "route"
   - Check plan.md for backend changes
2. If API changes detected:
   - Read docs/API_ENDPOINTS.md (or similar)
   - Add new endpoints or update existing ones
   - Include: Method, Path, Request body, Response body, Auth requirements
3. If no API changes:
   - **Update TodoWrite**: Mark API docs as `completed` (skipped)
   - Continue to Step 6

**After completion**:
- **Update TodoWrite**: Mark API docs as `completed`, mark milestone closure as `in_progress`
- Continue to Step 6

## Step 6: Close Current GitHub Milestone

1. Get current version from workflow-state.yaml (e.g., v1.2.3)
2. Find matching milestone:
   ```bash
   gh api repos/:owner/:repo/milestones --jq '.[] | select(.title | test("v?1\\.2"))'
   ```
3. Close milestone:
   ```bash
   gh api repos/:owner/:repo/milestones/[milestone-number] -X PATCH -f state=closed
   ```

**After completion**:
- **Update TodoWrite**: Mark milestone closure as `completed`, mark next milestone as `in_progress`
- Continue to Step 7

**If error** (e.g., milestone not found):
- **Update TodoWrite**: Keep as `completed` (optional step)
- Log warning: "No milestone found matching v1.2.x"
- Continue to Step 7

## Step 7: Create Next GitHub Milestone

1. Calculate next minor version (v1.2.3 → v1.3.0)
2. Set due date 2 weeks out:
   ```bash
   NEXT_VERSION="v1.3.0"
   DUE_DATE=$(date -d '+2 weeks' '+%Y-%m-%dT%H:%M:%SZ')
   gh api repos/:owner/:repo/milestones -f title="$NEXT_VERSION" -f due_on="$DUE_DATE"
   ```

**After completion**:
- **Update TodoWrite**: Mark next milestone as `completed`, mark roadmap update as `in_progress`
- Continue to Step 8

**If error** (e.g., milestone already exists):
- **Update TodoWrite**: Keep as `completed` (already exists is fine)
- Continue to Step 8

## Step 8: Update Roadmap Issue

1. Find roadmap issue for this feature:
   ```bash
   gh issue list --label type:feature --search "slug: [feature-slug]" --json number,title,body
   ```
2. Update issue with shipped status:
   ```bash
   gh issue edit [issue-number] --add-label "status:shipped" --remove-label "status:in-progress"
   ```
3. Add comment with release details:
   ```bash
   gh issue comment [issue-number] --body "🚀 Shipped in v$VERSION on $(date +%Y-%m-%d)

   **Production URL**: [url]

   See [release notes](https://github.com/owner/repo/releases/tag/v$VERSION)"
   ```

**After completion**:
- **Update TodoWrite**: Mark roadmap update as `completed`, mark commit docs as `in_progress`
- Continue to Step 9

**If error** (e.g., issue not found):
- **Update TodoWrite**: Keep as `completed` (optional step)
- Log warning: "Roadmap issue not found for slug: [feature-slug]"
- Continue to Step 9

## Step 9: Commit Documentation Changes

1. Stage all documentation changes:
   ```bash
   git add CHANGELOG.md README.md docs/
   ```
2. Create commit:
   ```bash
   git commit -m "docs: update documentation for v$VERSION

   - Update CHANGELOG.md with v$VERSION section
   - Update README.md features list
   - Add help article for [feature-name]
   - Update API documentation

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```
3. Push to main:
   ```bash
   git push origin main
   ```

**After completion**:
- **Update TodoWrite**: Mark commit docs as `completed`, mark branch cleanup as `in_progress`
- Continue to Step 10

**If error** (e.g., push rejected):
- **Update TodoWrite**: Add "Resolve git push conflict" as new todo
- Tell user to pull/resolve and run `/finalize` again
- **EXIT**

## Step 10: Clean Up Feature Branch

1. Get feature branch name from workflow-state.yaml
2. Check if already on main:
   ```bash
   git branch --show-current
   ```
3. If on feature branch, switch to main:
   ```bash
   git checkout main
   ```
4. Delete local feature branch:
   ```bash
   git branch -d [feature-branch]
   ```
5. Delete remote feature branch (if exists):
   ```bash
   git push origin --delete [feature-branch]
   ```

**After completion**:
- **Update TodoWrite**: Mark branch cleanup as `completed`
- Continue to Step 11 (Summary)

**If error** (e.g., branch not merged):
- **Update TodoWrite**: Keep as `in_progress`
- Warn user: "Branch may have unmerged changes. Delete manually if needed: git branch -D [feature-branch]"
- Continue to Step 11 (optional cleanup)

## Step 11: Display Final Summary

Display comprehensive summary of finalization:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Documentation & Cleanup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Version**: v$VERSION
**Feature**: [feature-slug]
**Released**: $(date +%Y-%m-%d)

### Files Updated

- ✅ CHANGELOG.md (Added v$VERSION section)
- ✅ README.md (Updated features and version badge)
- ✅ docs/help/features/[feature-slug].md (New help article)
- ✅ docs/API_ENDPOINTS.md (Updated/Skipped)

### GitHub

- ✅ Closed milestone: v1.2.x (#12)
- ✅ Created next milestone: v1.3.0 (due: [date])
- ✅ Updated roadmap issue #45 to "shipped"

### Git

- ✅ Committed documentation: [commit-sha]
- ✅ Pushed to main
- ✅ Deleted feature branch: [feature-branch]

### Next Steps

1. Review documentation accuracy
2. Announce release (social media, blog, email)
3. Monitor user feedback and error logs
4. Plan next feature from roadmap

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Full workflow complete: /feature → /ship → /finalize ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Recovery

**If any step fails**:
1. **Update TodoWrite**: Add "Fix [specific error]" as new todo
2. Keep failed task as `in_progress`
3. Display error with specific instructions:
   ```
   ❌ Failed to close GitHub milestone

   Error: API rate limit exceeded (403)

   Fix: Wait 1 hour or use personal access token with higher limit
   Then run: /finalize (will resume from failed step)
   ```
4. **EXIT** - user will run `/finalize` again after fixing

**Resumability**: When user runs `/finalize` again:
- Read TodoWrite state
- Skip completed tasks
- Resume from first `in_progress` or `pending` task

</instructions>

<constraints>
## TASK COMPLETION DISCIPLINE

**Mark task as completed ONLY when**:
- File successfully written/updated
- Git command completed without errors
- GitHub API call returned 2xx status
- No warnings or errors in output

**Do NOT mark as completed if**:
- File write was skipped
- Git command was not run
- GitHub API call failed
- Step was optional and skipped (mark as completed with note)

## GITHUB API SAFETY

**Before calling gh commands**:
1. Check if gh CLI is authenticated: `gh auth status`
2. Handle rate limiting gracefully (wait or skip)
3. Never fail entire workflow for optional GitHub steps

**If GitHub API fails**:
- Log warning
- Mark task as completed (don't block workflow)
- Continue to next task

## BRANCH CLEANUP SAFETY

**Before deleting branch**:
1. Verify branch is fully merged: `git branch --merged`
2. Confirm not on branch being deleted
3. Use `-d` (safe delete) not `-D` (force delete)

**If branch has unmerged changes**:
- Warn user
- Keep branch intact
- Mark cleanup as completed (user can delete manually)

</constraints>

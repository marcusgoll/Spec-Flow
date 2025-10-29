# /ship - Unified Deployment Orchestrator

**Purpose**: Orchestrate the complete post-implementation deployment workflow from optimization through production release, with support for multiple deployment models and automatic state management.

**Usage**:
- `/ship` - Start deployment workflow from beginning
- `/ship continue` - Resume from last completed phase
- `/ship status` - Display current deployment status

**Deployment Models**:
- **staging-prod**: Full staging validation before production (optimize → preview → ship-staging → validate-staging → ship-prod → essential finalization)
- **direct-prod**: Direct production deployment (optimize → preview → deploy-prod → essential finalization)
- **local-only**: Local build and integration (optimize → preview → build-local → merge-to-main → essential finalization)

**Note**: All models include essential finalization (roadmap update + branch cleanup). Optional full documentation via `/finalize` command.

**Dependencies**: Requires completed `/implement` phase

<context>
## TODO TRACKING REQUIREMENT

**CRITICAL**: You MUST use TodoWrite to track all ship workflow progress. This is non-negotiable.

**Why this matters**: The /ship workflow involves 5-8 phases over 20-40 minutes with manual gates. Without TodoWrite:
- User loses visibility when CI errors occur
- Workflow appears frozen or stuck
- Hard to identify current phase or blockers
- Impossible to resume after fixing errors

**When to use TodoWrite**:
1. **Immediately** after loading feature context - create full todo list
2. **After every phase completes** - mark completed, mark next as in_progress
3. **When errors occur** - add "Fix [specific error]" todo
4. **At manual gates** - keep as pending until user approval

**Only ONE todo should be in_progress at a time.**
</context>

<instructions>

## Step 1: Initialize & Create Todo List

1. Read workflow-state.yaml from most recent feature directory
2. Detect deployment model (staging-prod, direct-prod, or local-only)
3. **IMMEDIATELY create TodoWrite list** based on model:

**staging-prod** (8 phases):
```
TodoWrite({
  todos: [
    {content: "Initialize and load feature context", status: "completed", activeForm: "..."},
    {content: "Run pre-flight validation (env, build, docker, CI, deps)", status: "in_progress", activeForm: "Running pre-flight checks"},
    {content: "Execute /optimize phase", status: "pending", activeForm: "Optimizing for production"},
    {content: "Execute /preview phase (manual gate)", status: "pending", activeForm: "Preparing preview"},
    {content: "Deploy to staging environment", status: "pending", activeForm: "Deploying to staging"},
    {content: "Validate staging environment (manual gate)", status: "pending", activeForm: "Validating staging"},
    {content: "Deploy to production environment", status: "pending", activeForm: "Deploying to production"},
    {content: "Essential finalization (roadmap + branch cleanup)", status: "pending", activeForm: "Finalizing deployment"},
  ]
})
```

**direct-prod** (6 phases):
```
TodoWrite({
  todos: [
    {content: "Initialize and load feature context", status: "completed", activeForm: "..."},
    {content: "Run pre-flight validation (env, build, docker, CI, deps)", status: "in_progress", activeForm: "Running pre-flight checks"},
    {content: "Execute /optimize phase", status: "pending", activeForm: "Optimizing for production"},
    {content: "Execute /preview phase (manual gate)", status: "pending", activeForm: "Preparing preview"},
    {content: "Deploy directly to production", status: "pending", activeForm: "Deploying to production"},
    {content: "Essential finalization (roadmap + branch cleanup)", status: "pending", activeForm: "Finalizing deployment"},
  ]
})
```

**local-only** (7 phases):
```
TodoWrite({
  todos: [
    {content: "Initialize and load feature context", status: "completed", activeForm: "..."},
    {content: "Run pre-flight validation (env, build, docker, CI, deps)", status: "in_progress", activeForm: "Running pre-flight checks"},
    {content: "Execute /optimize phase", status: "pending", activeForm: "Optimizing for production"},
    {content: "Execute /preview phase (manual gate)", status: "pending", activeForm: "Preparing preview"},
    {content: "Build locally and validate artifacts", status: "pending", activeForm: "Building locally"},
    {content: "Merge feature branch to main", status: "pending", activeForm: "Merging to main"},
    {content: "Essential finalization (roadmap + branch cleanup)", status: "pending", activeForm: "Finalizing deployment"},
  ]
})
```

## Step 2: Execute Pre-flight Validation

Run pre-flight checks to validate environment before starting deployment:

```bash
# Run build locally to catch errors early
npm run build  # or yarn build, or pnpm build

# Check for missing environment variables
gh secret list

# Validate CI workflows (if .github/workflows exists)
yq eval '.' .github/workflows/*.yml
```

If any check fails:
- **Update TodoWrite**: Add "Fix [specific error]" as new todo
- Keep "Run pre-flight validation" as `in_progress`
- Tell user to fix error and run `/ship continue`
- **EXIT** - don't proceed to next phase

If all checks pass:
- **Update TodoWrite**: Mark pre-flight as `completed`, mark /optimize as `in_progress`
- Continue to Step 3

## Step 3: Run /optimize

Execute the `/optimize` slash command for code review and production readiness:

```bash
/optimize
```

After `/optimize` completes:
- **Update TodoWrite**: Mark /optimize as `completed`, mark /preview as `in_progress`
- Continue to Step 4

If `/optimize` fails:
- **Update TodoWrite**: Add "Fix code review issues" as new todo
- Tell user to address issues and run `/ship continue`
- **EXIT**

## Step 4: Run /preview (Manual Gate)

Execute the `/preview` slash command to start local dev server:

```bash
/preview
```

After dev server starts:
- **Update TodoWrite**: Mark /preview as `completed`, keep deployment phase as `pending`
- **Display manual gate message**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 MANUAL GATE: Preview Testing Required
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The local dev server is running. Please test:

1. ✅ All feature functionality
2. ✅ UI/UX across screen sizes
3. ✅ Accessibility (keyboard, screen readers)
4. ✅ Error states and edge cases
5. ✅ Performance (no lag)

When complete, run: /ship continue
To abort: /ship abort
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

- **EXIT** - wait for user to run `/ship continue`

## Step 5: Deploy (Model-Specific)

### If staging-prod model:

1. **Deploy to staging**:
   ```bash
   /ship-staging
   ```
   - **Update TodoWrite**: Mark staging deploy as `completed`, mark validation as `pending`

2. **Wait for staging validation** (manual gate):
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🛑 MANUAL GATE: Staging Validation Required
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Staging is live. Please:
   1. ✅ Run /validate-staging for automated checks
   2. ✅ Test feature in staging
   3. ✅ Verify rollback works

   When complete, run: /ship continue
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
   - **EXIT** - wait for user

3. **Deploy to production** (after user approval):
   ```bash
   /ship-prod
   ```
   - **Update TodoWrite**: Mark production deploy as `completed`, mark finalize as `in_progress`

### If direct-prod model:

1. **Deploy directly to production**:
   ```bash
   /deploy-prod
   ```
   - **Update TodoWrite**: Mark production deploy as `completed`, mark finalize as `in_progress`

### If local-only model:

1. **Build locally**:
   ```bash
   /build-local
   ```
   - **Update TodoWrite**: Mark local build as `completed`, mark merge as `in_progress`

2. **Merge to main**:
   ```bash
   git checkout main
   git merge --no-ff [feature-branch]
   git push origin main
   ```
   - **Update TodoWrite**: Mark merge as `completed`, mark finalize as `in_progress`

## Step 6: Essential Finalization (All Models)

Run core cleanup tasks for EVERY deployment, regardless of deployment model:

### 6.1: Update Roadmap Issue to 'Shipped'

1. **Find roadmap issue** for this feature (from workflow-state.yaml):
   ```bash
   FEATURE_SLUG=$(yq eval '.feature.slug' workflow-state.yaml)
   gh issue list --label type:feature --search "slug: $FEATURE_SLUG" --json number,title,body
   ```

2. **Update issue status** to shipped:
   ```bash
   ISSUE_NUMBER=[extracted-from-above]
   gh issue edit $ISSUE_NUMBER \
     --add-label "status:shipped" \
     --remove-label "status:in-progress"
   ```

3. **Add shipped comment** with deployment details:
   ```bash
   # Get production URL from workflow-state.yaml
   PROD_URL=$(yq eval '.deployment.production.url // "Not recorded"' workflow-state.yaml)
   VERSION=$(yq eval '.deployment.version // "unknown"' workflow-state.yaml)

   gh issue comment $ISSUE_NUMBER --body "🚀 Shipped in v$VERSION on $(date +%Y-%m-%d)

**Production URL**: $PROD_URL

Deployment complete!"
   ```

4. **Close the issue**:
   ```bash
   gh issue close $ISSUE_NUMBER --comment "Closing as shipped."
   echo "✅ Issue #$ISSUE_NUMBER closed"
   ```

**Error handling**: If issue not found or GitHub API fails, log warning and continue (non-blocking).

### 6.2: Clean Up Feature Branch

1. **Get branch names**:
   ```bash
   FEATURE_BRANCH=$(git branch --show-current)

   # Detect main branch (main or master)
   if git show-ref --verify --quiet refs/heads/main; then
     MAIN_BRANCH="main"
   elif git show-ref --verify --quiet refs/heads/master; then
     MAIN_BRANCH="master"
   else
     echo "⚠️  Cannot detect main branch, skipping branch cleanup"
     # Continue anyway - non-critical
   fi
   ```

2. **Switch to main branch** (if not already on it):
   ```bash
   if [ "$FEATURE_BRANCH" != "$MAIN_BRANCH" ]; then
     git checkout $MAIN_BRANCH
   else
     echo "Already on $MAIN_BRANCH, no need to switch"
   fi
   ```

3. **Delete local feature branch**:
   ```bash
   if [ "$FEATURE_BRANCH" != "$MAIN_BRANCH" ]; then
     git branch -d $FEATURE_BRANCH
     echo "✅ Deleted local branch: $FEATURE_BRANCH"
   fi
   ```

4. **Delete remote feature branch** (if exists):
   ```bash
   if git ls-remote --exit-code --heads origin "$FEATURE_BRANCH" >/dev/null 2>&1; then
     git push origin --delete $FEATURE_BRANCH
     echo "✅ Deleted remote branch: origin/$FEATURE_BRANCH"
   else
     echo "⏭️  Remote branch doesn't exist, nothing to delete"
   fi
   ```

**Error handling**: If branch deletion fails (unmerged changes), log warning and continue (non-blocking).

### 6.3: Display Final Summary

After essential finalization completes:
- **Update TodoWrite**: Mark finalize as `completed`
- Display final summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Deployment Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Feature Title]
Deployment Model: [staging-prod/direct-prod/local-only]

Essential Cleanup Done:
✅ Roadmap issue #[number] updated to 'shipped' and closed
✅ Feature branch '[branch-name]' deleted (local + remote)

Production URL: [url]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Optional: Full Documentation

For comprehensive documentation updates, run:
  /finalize

This will:
- Update CHANGELOG.md with release notes
- Update README.md with new features
- Generate user documentation
- Manage GitHub milestones
- Create release notes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

**When ANY phase fails**:
1. **Update TodoWrite**: Add "Fix [specific error from logs]" as new todo
2. Keep failed phase as `in_progress` (or pending if not started)
3. Display clear error message with log file path
4. Tell user to fix error and run `/ship continue`
5. **EXIT**

**Example**:
```
Pre-flight build failed with 3 TypeScript errors:

  src/components/Header.tsx:42 - Type 'string' not assignable to 'number'
  src/utils/format.ts:15 - Cannot find module 'date-fns'
  src/pages/Dashboard.tsx:89 - Property 'userId' does not exist on 'User'

TodoWrite updated with: "Fix 3 TypeScript build errors"

Fix these errors and run: /ship continue
```

## Resume Capability (/ship continue)

When user runs `/ship continue`:
1. Read workflow-state.yaml to get current phase
2. Find first todo with status `pending` or `in_progress`
3. Mark that todo as `in_progress`
4. Resume from that phase (skip completed phases)

## Status Display (/ship status)

When user runs `/ship status`:
1. Read workflow-state.yaml
2. Display:
   - Deployment model
   - Current phase
   - Completed phases (from TodoWrite)
   - Pending phases (from TodoWrite)
   - Any errors or blockers
   - Manual gates waiting for approval

</instructions>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent deployment failures from false assumptions.

1. **Never assume deployment configuration you haven't read**
   - ❌ BAD: "The app probably deploys to Vercel"
   - ✅ GOOD: "Let me check .github/workflows/ and package.json for deployment config"

2. **Cite actual workflow files when describing deployment**
   - When describing CI: "Per .github/workflows/deploy.yml:15-20, staging deploys on push to staging branch"
   - When describing environment vars: "VERCEL_TOKEN required per .env.example:5"

3. **Verify deployment URLs exist before reporting them**
   - Extract actual URLs from deployment tool output
   - If URL unknown, say: "Deployment succeeded but URL not captured in logs"

4. **Never fabricate deployment IDs or version tags**
   - Only report deployment IDs extracted from actual tool output
   - Don't invent git tags - verify with `git tag -l`

5. **Quote workflow-state.yaml exactly for phase status**
   - Don't paraphrase phase completion - quote the actual status
   - If state file missing/corrupted, flag it - don't assume status

## TODO UPDATE FREQUENCY

**After EVERY phase transition**:
- Mark previous phase as `completed`
- Mark next phase as `in_progress`
- Call TodoWrite (don't batch updates)

**When errors occur**:
- Add "Fix [specific error]" as new todo
- Keep current phase as `in_progress`
- Don't proceed to next phase

**At manual gates**:
- Mark current phase as `completed`
- Keep next phase as `pending` (not `in_progress` until user approves)
- Exit and wait for `/ship continue`

</constraints>

---
description: Create PR to main with auto-merge, triggering staging deployment via CI/CD pipeline with health checks and deployment metadata capture
allowed-tools: [Read, Write, Bash(git *), Bash(gh *), Bash(curl *), Bash(date *), Bash(grep *), Bash(jq *), Bash(yq *), Bash(test *), Bash(sleep *), Bash(source *)]
argument-hint: [feature-slug] (optional - defaults to current branch)
internal: true
---

> **⚠️  INTERNAL COMMAND**: This command is called automatically by `/ship`.
> Most users should use `/ship` instead of calling this directly.

<context>
Feature slug argument: @ $ARGUMENTS

Current branch: !`git branch --show-current`

Git status (short): !`git status --short | head -5`

Remote repository exists: !`git remote -v | grep -q origin && echo "✅ Yes" || echo "❌ No"`

Staging branch exists: !`git show-ref --verify --quiet refs/heads/staging || git show-ref --verify --quiet refs/remotes/origin/staging && echo "✅ Yes" || echo "❌ No"`

Optimization report exists: !`SLUG=$([ -n "$ARGUMENTS" ] && echo "$ARGUMENTS" || git branch --show-current); test -f "specs/$SLUG/optimization-report.md" && echo "✅ Found" || echo "❌ Missing"`

GitHub CLI authenticated: !`gh auth status >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No"`

Deployment quota remaining: !`SINCE=$(date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || date -u -v-24H -Iseconds); USED=$(gh run list --workflow=deploy-staging.yml --created="$SINCE" --json conclusion --jq 'length' 2>/dev/null || echo 0); echo $((100 - USED))`
</context>

<objective>
Ship feature to staging environment by creating a pull request with auto-merge enabled, triggering the CI/CD pipeline deployment.

**What it does:**
1. Validates pre-flight conditions (remote, clean tree, optimization complete)
2. Runs pre-deployment checks (quota, environment variables)
3. Selects deployment mode (staging or preview)
4. Creates pull request to main branch
5. Enables auto-merge with squash commit
6. Monitors CI pipeline execution
7. Runs health checks after deployment
8. Captures deployment metadata for rollback
9. Generates staging-ship-report.md with deployment details

**Operating constraints:**
- **Internal Command** — Called by `/ship`, not directly by users
- **Feature Branch Only** — Cannot ship from main or staging branches
- **Auto-Merge** — Automatically merges when CI passes
- **Health Checks** — Validates deployment success
- **Quota Aware** — Checks Vercel quota before deploying

**Dependencies:**
- Git repository with remote origin configured
- Staging branch exists (local or remote)
- GitHub CLI authenticated
- Optimization phase complete (/optimize)
- Clean working tree (no uncommitted changes)
</objective>

<process>
1. **Load feature slug**:
   - Use $ARGUMENTS if provided, otherwise current branch name
   - Set FEATURE_DIR="specs/$SLUG"
   - Validate feature directory exists

2. **Validate on feature branch**:
   - Get current branch name
   - Ensure NOT on main or staging:
     ```
     ❌ Cannot ship from main branch
     phase-1-ship runs from feature branches only
     ```

3. **Run pre-flight validation** (6 checks):

   **Check 1: Remote repository**
   - Verify git remote origin exists
   - Verify staging branch exists (local or remote)
   - If missing, display setup instructions

   **Check 2: Clean working tree**
   - Run `git status --porcelain`
   - If uncommitted changes, prompt user to commit or stash

   **Check 3: Optimization complete**
   - Verify optimization-report.md exists in specs/{slug}/
   - Verify quality gates passed
   - If missing, require `/optimize` first

   **Check 4: Pre-flight smoke tests**
   - Run quick local validation (type-check, lint)
   - Execute fast unit tests subset
   - Validate build if applicable

   **Check 5: Deployment budget**
   - Count Vercel deployments in last 24h
   - Calculate remaining quota: 100 - used
   - If < 10 remaining: Block deployment, suggest preview mode
   - If < 20 remaining: Warn, suggest careful deployment

   **Check 6: Environment variables**
   - Verify .env.staging exists (if required)
   - Check required variables are set

4. **Select deployment mode**:
   - **Staging mode**: Updates staging.{domain}.com, consumes quota (2 deployments)
   - **Preview mode**: CI testing only, no quota cost, unlimited usage
   - Prompt user to select mode:
     ```
     Deployment mode:
       1) Staging (updates staging environment) - Consumes quota
       2) Preview (CI testing only) - Free, unlimited

     Select mode (1/2):
     ```

5. **Load metadata**:
   - Read feature title from spec.md
   - Extract implementation highlights
   - Get current commit SHA
   - Generate PR title: `feat: {title} ({slug})`

6. **Create pull request**:
   - Create PR with title and body
   - Base: main, Head: current feature branch
   - Body includes:
     - Summary from spec.md
     - Implementation highlights
     - Testing notes
     - Deployment mode
     - Next steps (/validate-staging)
   - Command:
     ```bash
     gh pr create \
       --base main \
       --head "$CURRENT_BRANCH" \
       --title "$PR_TITLE" \
       --body "$PR_BODY" \
       --assignee "@me"
     ```

7. **Enable auto-merge**:
   - Get PR number: `gh pr view --json number --jq '.number'`
   - Enable auto-merge with squash commit:
     ```bash
     gh pr merge "$PR_NUMBER" \
       --auto \
       --squash \
       --delete-branch
     ```
   - Display PR URL and auto-merge status

8. **Monitor CI pipeline**:
   - Wait 10 seconds for CI to trigger
   - Check CI status every 30 seconds
   - Timeout after 10 minutes
   - If CI fails: Display error and suggest `/checks pr [number]`
   - If CI passes: Continue to health checks

9. **Run health checks** (after deployment completes):

   **Check 1: URL accessibility**
   - Marketing: `curl -sS -o /dev/null -w "%{http_code}" https://staging.{domain}.com`
   - App: `curl -sS -o /dev/null -w "%{http_code}" https://app.staging.{domain}.com`
   - Expected: 200 OK

   **Check 2: API health endpoint**
   - `curl -sS https://app.staging.{domain}.com/api/health | jq`
   - Expected: `{"status":"ok","database":"connected"}`

   **Check 3: Deployment metadata**
   - Verify Vercel deployment IDs exist
   - Check build timestamps

10. **Capture deployment metadata**:
    - Get Vercel deployment IDs (marketing, app)
    - Capture commit SHA, PR number, timestamp
    - Update workflow-state.yaml:
      ```yaml
      deployment:
        staging:
          deployed: true
          timestamp: {ISO 8601}
          commit_sha: {SHA}
          pr_number: {number}
          deployment_ids:
            marketing: {vercel-url}
            app: {vercel-url}
      ```
    - Create deployment-metadata.json with rollback info

11. **Generate staging-ship-report.md**:
    - Create report in specs/{slug}/staging-ship-report.md
    - Sections:
      - Deployment Summary (status, timestamp, commit, PR)
      - Deployment Details (URLs, IDs, health checks)
      - Quality Gates (pre-flight, CI status)
      - Rollback Metadata (previous commit, commands)
      - Next Steps (validation checklist, /ship-prod)

12. **Update workflow state**:
    - Mark ship:phase-1-ship as completed
    - Set next phase: ship:validate-staging
    - Update last_updated timestamp
    - Commit state changes to git

13. **Display summary and next steps**:
    ```
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ✅ Staging Deployment Complete
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    🚀 Deployed to Staging

    PR: #{number}
    Commit: {SHA}
    Mode: {staging|preview}

    URLs:
      Marketing: https://staging.{domain}.com
      App: https://app.staging.{domain}.com

    Health Checks:
      ✅ HTTP Status: 200 OK
      ✅ API Health: Connected
      ✅ Database: Connected

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Next Steps:

    1. Validate Staging Environment:
       /validate-staging

    2. Manual Testing:
       - Test critical user flows
       - Verify database operations
       - Check API responses
       - Test error handling

    3. Production Deployment:
       After validation complete:
       /ship-prod

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ```

See `.claude/skills/ship-staging/references/reference.md` for detailed pre-flight validation procedures, health check protocols, deployment metadata capture, and rollback procedures.
</process>

<verification>
Before completing, verify:
- Pre-flight checks all passed (6/6)
- Deployment mode selected (staging or preview)
- Pull request created successfully
- Auto-merge enabled
- CI pipeline completed (or timeout)
- Health checks passed (HTTP, API, database)
- Deployment metadata captured (IDs, URLs, timestamps)
- staging-ship-report.md generated
- workflow-state.yaml updated
- Git state committed
- Summary displayed with next steps
</verification>

<success_criteria>
**Pre-flight validation:**
- Remote repository configured
- Staging branch exists
- Working tree clean (no uncommitted changes)
- Optimization report exists and passed
- Deployment quota sufficient (or preview mode selected)
- Environment variables validated

**Pull request:**
- PR created with proper title format: `feat: {title} ({slug})`
- PR body includes summary, highlights, testing notes, next steps
- Auto-merge enabled with squash commit
- Delete branch after merge configured

**CI pipeline:**
- CI triggered within 10 seconds
- CI status monitored every 30 seconds
- CI completed within 10-minute timeout
- CI passed all required checks

**Health checks:**
- Marketing URL returns 200 OK
- App URL returns 200 OK
- API health endpoint returns {"status":"ok"}
- Database connectivity confirmed

**Deployment metadata:**
- Vercel deployment IDs captured (marketing, app)
- Commit SHA recorded
- PR number stored
- Timestamp in ISO 8601 format
- URLs saved
- workflow-state.yaml updated correctly

**Report generation:**
- staging-ship-report.md created in specs/{slug}/
- Contains all required sections (summary, details, gates, rollback, next)
- Rollback commands documented
- Validation checklist provided

**Workflow state:**
- ship:phase-1-ship marked completed
- Next phase set to ship:validate-staging
- last_updated timestamp current
- State committed to git

**User presentation:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Staging Deployment Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Deployed to Staging

PR: #{number}
Commit: {SHA}
Mode: {mode}

URLs:
  Marketing: {url}
  App: {url}

Health Checks:
  ✅ HTTP Status: 200 OK
  ✅ API Health: Connected
  ✅ Database: Connected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
1. /validate-staging
2. Manual testing checklist
3. /ship-prod when ready

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
</success_criteria>

<standards>
**Industry Standards:**
- **Semantic Versioning**: [semver.org](https://semver.org/) for version tagging
- **Conventional Commits**: [conventionalcommits.org](https://www.conventionalcommits.org/) for commit messages
- **Health Check Patterns**: [Health Check Response Format](https://inadarei.github.io/rfc-healthcheck/) for API health endpoints
- **Deployment Best Practices**: [The Twelve-Factor App](https://12factor.net/) for deployment methodology

**Workflow Standards:**
- Auto-merge with squash commit (clean history)
- Delete feature branch after merge
- Health checks after deployment
- Deployment metadata capture for rollback capability
- Staging environment validation before production
- Quota-aware deployment (check before consuming)
- Non-destructive preview mode for testing
</standards>

<notes>
**Command location**: `.claude/commands/deployment/ship-staging.md`

**Reference documentation**: Pre-flight validation procedures (6 checks), deployment mode selection, PR creation workflow, auto-merge configuration, health check procedures (3 checks), deployment metadata capture, staging ship report structure, error conditions, and rollback procedures are in `.claude/skills/ship-staging/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Internal command**: Called by `/ship` parent orchestrator, not intended for direct user invocation

**Workflow position**:
```
/feature → /clarify → /plan → /tasks → /analyze → /implement →
/optimize → /preview → **/ship-staging** → /validate-staging → /ship-prod
```

**Deployment modes:**
- **Staging**: Updates staging.{domain}.com, consumes Vercel quota (2 deployments per ship)
- **Preview**: CI testing only, no quota cost, unlimited usage, preview URL expires after 7 days

**Auto-merge behavior:**
- Enabled by default
- Merges when all CI checks pass
- Squash commit (combines all feature commits)
- Deletes feature branch after merge

**Health checks:**
- Run automatically after deployment completes
- Validates HTTP accessibility (200 OK)
- Checks API health endpoint
- Verifies database connectivity

**Deployment metadata:**
- Captured for rollback capability
- Includes Vercel deployment IDs, commit SHA, PR number, timestamps
- Stored in workflow-state.yaml and deployment-metadata.json
- Enables quick rollback if issues discovered

**Quota management:**
- Pre-flight check verifies sufficient quota (>= 2 remaining for staging mode)
- < 10 remaining: Blocks deployment, suggests preview mode
- < 20 remaining: Warns, suggests careful deployment
- Preview mode: 0 quota cost, unlimited usage

**Related commands:**
- `/ship` - Parent orchestrator (calls ship-staging automatically)
- `/optimize` - Quality gates (must run before shipping)
- `/preview` - Local testing (recommended before shipping)
- `/validate-staging` - Manual staging validation (run after shipping)
- `/ship-prod` - Production deployment (run after validation)
- `/checks pr [number]` - CI failure investigation
- `/deployment-budget` - Check quota before shipping

**Error handling:**
- **No remote**: Display setup instructions for adding remote and creating staging branch
- **Uncommitted changes**: Prompt to commit or stash before continuing
- **Optimization missing**: Require `/optimize` before proceeding
- **Low quota**: Block or warn based on remaining quota, suggest preview mode
- **CI failure**: Display error, suggest `/checks pr [number]` for investigation
- **Health check failure**: Report failure, provide troubleshooting steps

**Rollback capability:**
- Previous commit SHA captured
- Rollback commands documented in report
- Revert via new PR or direct git revert + push
- Vercel deployment promotion for immediate rollback

**Best practices:**
- Always run `/optimize` before shipping
- Check `/deployment-budget` to avoid quota exhaustion
- Use preview mode for testing without quota cost
- Monitor CI progress for failures
- Run health checks after deployment
- Validate staging before production deployment
- Document any issues in validation report
</notes>

---
description: Display Vercel and Railway deployment quota usage with 24h rolling window analysis, quota reset predictions, and deployment strategy recommendations
allowed-tools: [Read, Bash(gh run list:*), Bash(gh auth status:*), Bash(railway usage:*), Bash(railway whoami:*), Bash(date *), Bash(echo *), Bash(command -v:*), Bash(grep:*), Bash(wc:*), Bash(bc:*)]
argument-hint: (no arguments - displays current quota status)
---

<context>
GitHub CLI authenticated: !`gh auth status >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No - run gh auth login"`

24h timestamp (GNU): !`date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || echo "N/A"`

24h timestamp (BSD): !`date --version 2>/dev/null | grep -q GNU || date -u -v-24H -Iseconds 2>/dev/null || echo "N/A"`

Marketing deployments (24h): !`SINCE=$(date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || date -u -v-24H -Iseconds); gh run list --workflow=deploy-staging.yml --created="$SINCE" --json conclusion --jq 'length' 2>/dev/null || echo "0"`

App deployments (24h): !`SINCE=$(date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || date -u -v-24H -Iseconds); gh run list --workflow=deploy-app-staging.yml --created="$SINCE" --json conclusion --jq 'length' 2>/dev/null || echo "0"`

Railway CLI installed: !`command -v railway >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No"`

Railway usage: !`railway usage 2>/dev/null || echo "Railway CLI not available"`

Oldest deployment timestamp: !`SINCE=$(date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || date -u -v-24H -Iseconds); gh run list --workflow=deploy-staging.yml --created="$SINCE" --limit 1 --json createdAt --jq '.[0].createdAt' 2>/dev/null || echo ""`

Recent deployment statuses: !`SINCE=$(date --version 2>/dev/null | grep -q GNU && date -d '24 hours ago' -Iseconds || date -u -v-24H -Iseconds); gh run list --workflow=deploy-staging.yml --created="$SINCE" --limit 10 --json conclusion,createdAt,displayTitle --jq '.[] | "\(.conclusion) - \(.displayTitle) - \(.createdAt)"' 2>/dev/null || echo ""`
</context>

<objective>
Track deployment quota usage and predict remaining capacity to prevent rate limiting during deployments.

**What it does:**
- Counts Vercel deployments in 24h rolling window (Marketing + App)
- Checks Railway compute usage (if CLI available)
- Calculates quota reset time from oldest deployment
- Predicts remaining quota after next deployment
- Provides deployment strategy based on quota status
- Analyzes recent deployment failure rate

**Operating constraints:**
- **Vercel Limit** — 100 deployments per 24 hours (rolling window)
- **Warning Threshold** — Alert when < 20 remaining
- **Critical Threshold** — Block when < 10 remaining
- **Read-Only** — Never modifies quotas or settings
- **Non-Blocking** — Always returns, even on errors

**Dependencies:**
- GitHub CLI installed and authenticated (gh auth login)
- Railway CLI optional (for compute usage tracking)
- Access to deploy-staging.yml and deploy-app-staging.yml workflows
</objective>

<process>
1. **Verify GitHub CLI authentication**:
   - Check if gh auth status succeeds
   - If not authenticated, display error and exit:
     ```
     ❌ GitHub CLI not authenticated
        Run: gh auth login
     ```

2. **Calculate total Vercel deployments**:
   - Sum Marketing + App deployments from context
   - Calculate remaining: 100 - total_used
   - Determine status:
     - **normal**: >= 20 remaining (✅)
     - **warning**: 10-19 remaining (⚠️)
     - **critical**: < 10 remaining (🚨)

3. **Display Vercel quota section**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Deployment Budget (24h rolling)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Vercel Deployments:

     Marketing (staging): {count}
     App (staging): {count}

     Total used: {total} / 100
     Remaining: {remaining}

     {status_emoji} {STATUS} - {remaining} deployments {available/remaining/left}
   ```

4. **Display Railway usage** (if CLI available):
   - If Railway CLI installed, show usage output
   - If not installed, show installation instructions:
     ```
     ⚠️  Railway CLI not installed
        Install: npm install -g @railway/cli
     ```

5. **Calculate quota reset time**:
   - Extract oldest deployment timestamp from context
   - Calculate reset time (24 hours from oldest)
   - Calculate time remaining until reset (hours and minutes)
   - Display:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Quota Reset Information
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Oldest deployment: {timestamp}
     Quota resets at: {reset_time}
     Time to reset: {hours}h {minutes}m
     ```

6. **Predict next deployment impact**:
   - Deployment cost: 2 (Marketing + App for staging)
   - Projected remaining: current_remaining - 2
   - Display prediction:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     Next Deployment Impact
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Next /ship --staging will use:
       Marketing: 1 deployment
       App: 1 deployment
       Total: 2 deployments

     Projected remaining: {projected} / 100
     ```
   - Add warning if projected < 0:
     ```
     🚨 WOULD EXCEED QUOTA

     Options:
       A) Wait for quota reset ({reset_time})
       B) Use preview mode (doesn't count toward quota)
       C) Skip deployment and create draft PR
     ```

7. **Provide deployment strategy recommendations**:
   - **If critical status**:
     ```
     Current status: CRITICAL ({remaining} remaining)

     🛑 DO NOT use staging mode

     Recommended actions:
       1. Wait for quota reset ({reset_time})
       2. OR use preview mode:
          - Tests CI without consuming quota
          - Doesn't update staging.cfipros.com
          - Unlimited usage

     Preview mode usage:
       /ship --staging
       → Select 'preview' when prompted
     ```
   - **If warning status**:
     ```
     Current status: LOW ({remaining} remaining)

     ⚠️  Use quota carefully

     Best practices:
       1. Run /validate-staging before every deployment
       2. Use preview mode for CI testing
       3. Use staging mode only for actual staging deploys
       4. Fix issues locally before pushing

     Workflow:
       /validate-staging → /ship (preview) → verify → /ship (staging)
     ```
   - **If normal status**:
     ```
     Current status: NORMAL ({remaining} remaining)

     ✅ Enough quota for normal workflow

     Best practices:
       1. Still run /validate-staging to catch issues early
       2. Use preview mode for experimental changes
       3. Monitor quota with /deployment-budget
     ```

8. **Analyze recent deployment failures**:
   - Parse recent deployment statuses from context
   - Count successes and failures
   - Calculate failure rate: (failures * 100) / total
   - If failure rate > 30%:
     ```
     ⚠️  Failure rate: {rate}%

     🚨 HIGH failure rate detected
        Run /debug to investigate issues
        Use /validate-staging before deploying
     ```

9. **Display final summary**:
   - **Critical**:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     🚨 QUOTA CRITICAL - DO NOT DEPLOY
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Remaining: {remaining} / 100
     Reset at: {reset_time}

     Use preview mode or wait for reset
     ```
   - **Warning**:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ⚠️  QUOTA LOW - DEPLOY CAREFULLY
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Remaining: {remaining} / 100
     After next deploy: ~{projected}

     Run /validate-staging before deploying
     ```
   - **Normal**:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ✅ QUOTA NORMAL - SAFE TO DEPLOY
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Remaining: {remaining} / 100
     After next deploy: ~{projected}

     Proceed with /ship
     ```

See `.claude/skills/deployment-budget/references/reference.md` for detailed quota calculation logic, threshold configuration, failure analysis algorithms, and complete output examples.
</process>

<verification>
Before completing, verify:
- GitHub CLI authentication checked
- Vercel deployments counted correctly (Marketing + App)
- Quota status determined correctly (normal/warning/critical)
- Railway usage shown if CLI available
- Reset time calculated from oldest deployment
- Next deployment impact predicted (cost = 2)
- Strategy recommendations match quota status
- Failure rate analyzed if deployments exist
- Final summary displays correct status emoji
</verification>

<success_criteria>
**Quota calculation:**
- Marketing and App deployments counted from 24h window
- Total used calculated correctly
- Remaining calculated: 100 - total_used
- Status determined by thresholds (20, 10)

**Reset time:**
- Oldest deployment timestamp extracted
- Reset time calculated: oldest + 24 hours
- Time to reset shown in hours and minutes
- "Full quota available" if no deployments

**Deployment prediction:**
- Cost correctly set to 2 (Marketing + App)
- Projected remaining calculated
- Warnings shown if projected < 0 or approaching limits

**Strategy recommendations:**
- Critical (< 10): DO NOT DEPLOY, show wait/preview options
- Warning (10-19): DEPLOY CAREFULLY, show validation workflow
- Normal (>= 20): SAFE TO DEPLOY, show best practices

**Failure analysis:**
- Recent deployments parsed (last 10)
- Success and failure counts calculated
- Failure rate percentage shown
- Warning if failure rate > 30%

**Visual formatting:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Budget (24h rolling)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vercel Deployments:
  Marketing (staging): {count}
  App (staging): {count}
  Total used: {total} / 100
  Remaining: {remaining}

  {emoji} {STATUS} - {remaining} deployments {available/remaining/left}

[Railway section if CLI available]
[Reset time section]
[Prediction section]
[Strategy section]
[Failure analysis if failures exist]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{emoji} QUOTA {STATUS} - {MESSAGE}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: {remaining} / 100
{Additional context}
{Actionable next step}
```
</success_criteria>

<standards>
**Industry Standards:**
- **Rolling Window**: [Wikipedia - Time Window](https://en.wikipedia.org/wiki/Sliding_window_protocol) for accurate 24h tracking
- **ISO 8601**: [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) for timestamp formatting

**Workflow Standards:**
- Vercel limit: 100 deployments / 24 hours (rolling window)
- Warning threshold: 20 remaining (allows ~10 more staging deploys)
- Critical threshold: 10 remaining (allows ~5 more deploys)
- Deployment cost: 2 per /ship --staging (Marketing + App)
- Failure rate threshold: 30% (indicates systematic issues)
- Read-only operations (never modify quotas)
- Non-blocking (always returns exit code 0)
</standards>

<notes>
**Command location**: `.claude/commands/deployment/deployment-budget.md`

**Reference documentation**: Quota calculation logic, threshold configuration, rolling window implementation, reset time calculation, deployment prediction algorithms, strategy recommendation decision trees, failure analysis, and complete output examples are in `.claude/skills/deployment-budget/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Quota limits:**
- **Vercel**: 100 deployments / 24 hours (rolling window, not calendar day)
- **Railway**: Based on compute minutes, not deployment count

**Thresholds:**
- **Warning**: < 20 remaining (⚠️  Deploy carefully)
- **Critical**: < 10 remaining (🚨 Do not deploy)
- **Normal**: >= 20 remaining (✅ Safe to deploy)

**Deployment costs:**
- `/ship --staging` (staging): 2 deployments (Marketing + App)
- Preview mode: 0 deployments (doesn't count toward quota)

**Rolling window calculation:**
- **Not calendar day**: Tracks exactly 24 hours from current time
- **Platform-aware**: Uses GNU date (Linux) or BSD date (macOS)
- **Reset time**: 24 hours from oldest deployment in window

**Strategy philosophy**:
- "Know your limits before you hit them"
- Validate locally before deploying
- Use preview mode for testing
- Reserve staging mode for actual staging updates

**Related commands:**
- `/validate-staging` - Validate deployment locally (doesn't consume quota)
- `/ship --staging` - Deploy to staging (consumes 2 quota)
- `/ship` - Unified deployment orchestrator
- `/debug` - Investigate deployment failures

**Error handling:**
- **Not authenticated**: Show `gh auth login` command
- **Railway CLI missing**: Show installation instructions (non-blocking)
- **No deployments**: Show "Full quota available"
- **API errors**: Fall back to last known status

**Usage scenarios:**
- **Before `/ship --staging`**: Check if enough quota remains
- **Approaching limits**: Plan deployment strategy (preview vs staging)
- **After failures**: Analyze failure rate to identify systematic issues
- **Quota exhausted**: Calculate reset time to plan next deployment window

**Preview mode benefits:**
- Tests CI without consuming quota
- Doesn't update staging environment
- Unlimited usage
- Ideal for experimental changes and debugging
</notes>

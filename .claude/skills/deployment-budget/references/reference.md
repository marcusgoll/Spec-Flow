# Deployment Budget — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-20

This document provides comprehensive reference material for the `/deployment-budget` command, including quota tracking logic, threshold calculations, prediction algorithms, and deployment strategy recommendations.

---

## Table of Contents

1. [Quota Limits](#quota-limits)
2. [Threshold Configuration](#threshold-configuration)
3. [Rolling Window Calculation](#rolling-window-calculation)
4. [Quota Checking Logic](#quota-checking-logic)
5. [Railway Usage Tracking](#railway-usage-tracking)
6. [Reset Time Calculation](#reset-time-calculation)
7. [Deployment Prediction](#deployment-prediction)
8. [Strategy Recommendations](#strategy-recommendations)
9. [Failure Analysis](#failure-analysis)
10. [Output Examples](#output-examples)

---

## Quota Limits

### Vercel Deployments

**Limit**: 100 deployments per 24 hours (rolling window)

**Rolling Window**: Not calendar day - tracks deployments from exactly 24 hours ago

**Services tracked**:
- Marketing (deploy-staging.yml workflow)
- App (deploy-app-staging.yml workflow)

**Cost per `/phase-1-ship`**:
- Marketing: 1 deployment
- App: 1 deployment
- **Total**: 2 deployments per staging ship

### Railway Compute

**Limit**: Based on compute minutes, not deployment count

**Tracking**: Via Railway CLI (`railway usage`)

**Measurement**: CPU-hours consumed in billing period

**Not deployment-gated**: Railway doesn't limit deployments, only runtime

---

## Threshold Configuration

### Warning Levels

```bash
VERCEL_LIMIT=100              # Maximum deployments in 24h
QUOTA_WARNING_THRESHOLD=20    # ⚠️  Warning when < 20 remaining
QUOTA_CRITICAL_THRESHOLD=10   # 🚨 Critical when < 10 remaining
```

### Status Levels

| Remaining | Status | Emoji | Action |
|-----------|--------|-------|--------|
| >= 20 | normal | ✅ | Safe to deploy |
| 10-19 | warning | ⚠️  | Deploy carefully, validate first |
| < 10 | critical | 🚨 | Do not deploy, use preview or wait |

### Rationale

- **20 remaining**: Allows ~10 more staging deploys before critical
- **10 remaining**: Allows ~5 more deploys before exhaustion
- **0 remaining**: Quota exhausted, must wait for reset

---

## Rolling Window Calculation

### Get 24-Hour Timestamp

**GNU date (Linux)**:
```bash
SINCE_TIME=$(date -d '24 hours ago' -Iseconds)
# Example output: 2025-01-07T14:30:00-08:00
```

**BSD date (macOS)**:
```bash
SINCE_TIME=$(date -u -v-24H -Iseconds)
# Example output: 2025-01-07T22:30:00Z
```

### Platform Detection

```bash
if date --version 2>/dev/null | grep -q GNU; then
  # Use GNU date syntax
else
  # Use BSD date syntax
fi
```

### Why Rolling Window?

**Problem with calendar day**: Deployments at 11:59 PM and 12:01 AM count as same day, but are only 2 minutes apart

**Rolling window solution**: Tracks exactly 24 hours from current time, regardless of day boundaries

**Example**:
- Current time: 2025-01-08 14:30:00
- Rolling window: 2025-01-07 14:30:00 → 2025-01-08 14:30:00
- Deployments counted: Any deployment after 2025-01-07 14:30:00

---

## Quota Checking Logic

### Phase 1: Count Vercel Deployments

**Marketing deployments**:
```bash
MARKETING_USED=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)
```

**App deployments**:
```bash
APP_USED=$(gh run list \
  --workflow=deploy-app-staging.yml \
  --created="$SINCE_TIME" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)
```

**Total calculation**:
```bash
VERCEL_USED=$((MARKETING_USED + APP_USED))
VERCEL_REMAINING=$((VERCEL_LIMIT - VERCEL_USED))
```

**Why use `length` instead of counting?**:
- `length` counts all deployments (success, failure, cancelled)
- All deployments consume quota, regardless of outcome

### Phase 2: Determine Status

```bash
if [ "$VERCEL_REMAINING" -lt "$QUOTA_CRITICAL_THRESHOLD" ]; then
  echo "🚨 CRITICAL - Only $VERCEL_REMAINING deployments left"
  BUDGET_STATUS="critical"
elif [ "$VERCEL_REMAINING" -lt "$QUOTA_WARNING_THRESHOLD" ]; then
  echo "⚠️  LOW - $VERCEL_REMAINING deployments remaining"
  BUDGET_STATUS="warning"
else
  echo "✅ NORMAL - $VERCEL_REMAINING deployments available"
  BUDGET_STATUS="normal"
fi
```

---

## Railway Usage Tracking

### Check CLI Availability

```bash
if command -v railway &> /dev/null; then
  # Railway CLI installed
  RAILWAY_USAGE=$(railway usage 2>/dev/null || echo "")
else
  # Railway CLI not installed
  echo "⚠️  Railway CLI not installed"
  echo "   Install: npm install -g @railway/cli"
fi
```

### Parse Railway Usage

Railway CLI output format:
```
Usage for project my-project (January 2025):
  CPU: 12.5 hours / 500 hours
  Memory: 3.2 GB-hours / Unlimited
  Deployments: 25 (unlimited)
```

**Note**: Railway doesn't enforce deployment limits, only compute usage limits

### Authentication Check

```bash
railway whoami
# If not authenticated:
#   Error: Not authenticated. Run `railway login`
```

---

## Reset Time Calculation

### Find Oldest Deployment

```bash
OLDEST_DEPLOY=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --limit 1 \
  --json createdAt \
  --jq '.[0].createdAt' 2>/dev/null || echo "")
```

**Returns**: ISO 8601 timestamp of oldest deployment in 24h window

**Example**: `2025-01-07T14:30:00Z`

### Calculate Reset Time

**GNU date (Linux)**:
```bash
RESET_TIME=$(date -d "$OLDEST_DEPLOY + 24 hours" "+%Y-%m-%d %H:%M:%S")
RESET_IN=$(( ($(date -d "$RESET_TIME" +%s) - $(date +%s)) / 60 ))
```

**BSD date (macOS)**:
```bash
RESET_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$OLDEST_DEPLOY" -v+24H "+%Y-%m-%d %H:%M:%S")
RESET_IN="?"  # BSD date calculation more complex
```

### Convert to Hours/Minutes

```bash
RESET_HOURS=$((RESET_IN / 60))
RESET_MINS=$((RESET_IN % 60))
echo "Time to reset: ${RESET_HOURS}h ${RESET_MINS}m"
```

**Example**:
- RESET_IN = 150 minutes
- RESET_HOURS = 2 hours
- RESET_MINS = 30 minutes
- Output: "Time to reset: 2h 30m"

---

## Deployment Prediction

### Calculate Next Deployment Cost

```bash
DEPLOY_COST=2  # Marketing + App (staging mode)
PROJECTED_REMAINING=$((VERCEL_REMAINING - DEPLOY_COST))
```

**Why 2 deployments?**:
- `/phase-1-ship` deploys both Marketing and App to staging
- Each counts as 1 deployment toward quota
- Total: 2 deployments per staging ship

### Projection Logic

```bash
if [ "$PROJECTED_REMAINING" -lt 0 ]; then
  echo "🚨 WOULD EXCEED QUOTA"
  # Display wait/preview/skip options
elif [ "$PROJECTED_REMAINING" -lt "$QUOTA_CRITICAL_THRESHOLD" ]; then
  echo "⚠️  WARNING: Low quota after deployment"
  # Recommend validation before deploy
elif [ "$PROJECTED_REMAINING" -lt "$QUOTA_WARNING_THRESHOLD" ]; then
  echo "⚠️  Approaching quota limits"
  # Recommend careful planning
else
  echo "✅ Sufficient quota for deployment"
fi
```

---

## Strategy Recommendations

### Critical Status (< 10 remaining)

**Recommendation**: DO NOT DEPLOY

**Options**:
1. **Wait for quota reset** - Check reset time from oldest deployment
2. **Use preview mode** - Tests CI without consuming quota
3. **Skip deployment** - Create draft PR, merge without deploying

**Preview mode workflow**:
```bash
/phase-1-ship
→ Select 'preview' when prompted
→ Doesn't update staging.cfipros.com
→ Doesn't consume quota
→ Unlimited usage
```

### Warning Status (10-19 remaining)

**Recommendation**: DEPLOY CAREFULLY

**Best practices**:
1. Run `/validate-deploy` before every deployment
2. Use preview mode for CI testing
3. Use staging mode only for actual staging deploys
4. Fix issues locally before pushing

**Workflow**:
```bash
/validate-deploy → /ship (preview) → verify → /ship (staging)
```

### Normal Status (>= 20 remaining)

**Recommendation**: SAFE TO DEPLOY

**Best practices**:
1. Still run `/validate-deploy` to catch issues early
2. Use preview mode for experimental changes
3. Monitor quota with `/deployment-budget`

---

## Failure Analysis

### Track Recent Deployments

```bash
RECENT_DEPLOYS=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --limit 10 \
  --json conclusion,createdAt,displayTitle \
  --jq '.[] | "\(.conclusion) - \(.displayTitle) - \(.createdAt)"')
```

**Output format**:
```
success - Deploy marketing (staging) - 2025-01-08T14:00:00Z
failure - Deploy marketing (staging) - 2025-01-08T13:45:00Z
success - Deploy marketing (staging) - 2025-01-08T13:30:00Z
```

### Calculate Failure Rate

```bash
SUCCESS_COUNT=$(echo "$RECENT_DEPLOYS" | grep -c "^success" || echo 0)
FAILURE_COUNT=$(echo "$RECENT_DEPLOYS" | grep -c "^failure" || echo 0)

FAILURE_RATE=$(( (FAILURE_COUNT * 100) / (SUCCESS_COUNT + FAILURE_COUNT) ))
```

**Example**:
- Success: 7
- Failure: 3
- Total: 10
- Failure rate: (3 * 100) / 10 = 30%

### Failure Thresholds

```bash
if [ "$FAILURE_RATE" -gt 30 ]; then
  echo "🚨 HIGH failure rate detected"
  echo "   Run /debug to investigate issues"
  echo "   Use /validate-deploy before deploying"
fi
```

**Why 30% threshold?**:
- 1-2 failures in 10 deploys (10-20%) is normal (transient issues, rate limits)
- 3+ failures in 10 deploys (30%+) indicates systematic issues
- Warrants investigation before continuing

---

## Output Examples

### Example 1: Normal Quota

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Budget (24h rolling)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vercel Deployments:

  Marketing (staging): 8
  App (staging): 10

  Total used: 18 / 100
  Remaining: 82

  ✅ NORMAL - 82 deployments available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Railway Compute Usage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fetching Railway usage...

Usage for project my-project (January 2025):
  CPU: 12.5 hours / 500 hours
  Memory: 3.2 GB-hours / Unlimited
  Deployments: 25 (unlimited)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Quota Reset Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Oldest deployment: 2025-01-07T14:30:00Z
Quota resets at: 2025-01-08 14:30:00
Time to reset: 4h 15m

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next Deployment Impact
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next /phase-1-ship will use:
  Marketing: 1 deployment
  App: 1 deployment
  Total: 2 deployments

Projected remaining: 80 / 100

✅ Sufficient quota for deployment

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Strategy Recommendations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current status: NORMAL (82 remaining)

✅ Enough quota for normal workflow

Best practices:
  1. Still run /validate-deploy to catch issues early
  2. Use preview mode for experimental changes
  3. Monitor quota with /deployment-budget

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recent Deployment Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last 10 deployments (24h):

  Success: 8
  Failure: 2

Recent deploys:
  success - Deploy marketing (staging) - 2025-01-08T14:00:00Z
  success - Deploy marketing (staging) - 2025-01-08T13:45:00Z
  failure - Deploy marketing (staging) - 2025-01-08T13:30:00Z
  success - Deploy marketing (staging) - 2025-01-08T13:15:00Z
  success - Deploy marketing (staging) - 2025-01-08T13:00:00Z

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ QUOTA NORMAL - SAFE TO DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 82 / 100
After next deploy: ~80

Proceed with /ship
```

### Example 2: Low Quota

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Budget (24h rolling)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vercel Deployments:

  Marketing (staging): 42
  App (staging): 43

  Total used: 85 / 100
  Remaining: 15

  ⚠️  LOW - 15 deployments remaining
     Use /preflight before deploying

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next Deployment Impact
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next /phase-1-ship will use:
  Marketing: 1 deployment
  App: 1 deployment
  Total: 2 deployments

Projected remaining: 13 / 100

⚠️  WARNING: Low quota after deployment

Recommendation:
  - Run /validate-deploy before deploying (catches failures locally)
  - Consider preview mode for CI testing
  - Reserve staging mode for final deployment

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Strategy Recommendations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current status: LOW (15 remaining)

⚠️  Use quota carefully

Best practices:
  1. Run /validate-deploy before every deployment
  2. Use preview mode for CI testing
  3. Use staging mode only for actual staging deploys
  4. Fix issues locally before pushing

Workflow:
  /validate-deploy → /ship (preview) → verify → /ship (staging)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  QUOTA LOW - DEPLOY CAREFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 15 / 100
After next deploy: ~13

Run /validate-deploy before deploying
```

### Example 3: Critical Quota

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Budget (24h rolling)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Vercel Deployments:

  Marketing (staging): 48
  App (staging): 49

  Total used: 97 / 100
  Remaining: 3

  🚨 CRITICAL - Only 3 deployments left
     Wait for quota reset or use preview mode

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Quota Reset Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Oldest deployment: 2025-01-07T14:30:00Z
Quota resets at: 2025-01-08 14:30:00
Time to reset: 0h 45m

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next Deployment Impact
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next /phase-1-ship will use:
  Marketing: 1 deployment
  App: 1 deployment
  Total: 2 deployments

Projected remaining: 1 / 100

⚠️  WARNING: Low quota after deployment

Recommendation:
  - Run /validate-deploy before deploying (catches failures locally)
  - Consider preview mode for CI testing
  - Reserve staging mode for final deployment

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployment Strategy Recommendations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current status: CRITICAL (3 remaining)

🛑 DO NOT use staging mode

Recommended actions:
  1. Wait for quota reset (2025-01-08 14:30:00)
  2. OR use preview mode:
     - Tests CI without consuming quota
     - Doesn't update staging.cfipros.com
     - Unlimited usage

Preview mode usage:
  /phase-1-ship
  → Select 'preview' when prompted

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 QUOTA CRITICAL - DO NOT DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 3 / 100
Reset at: 2025-01-08 14:30:00

Use preview mode or wait for reset
```

---

## Error Handling

### GitHub CLI Not Authenticated

**Detection**:
```bash
gh auth status >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ GitHub CLI not authenticated"
  echo "   Run: gh auth login"
  exit 1
fi
```

**User action**: Run `gh auth login` and follow prompts

### Railway CLI Not Found

**Detection**:
```bash
if ! command -v railway &> /dev/null; then
  echo "⚠️  Railway CLI not installed"
  echo "   Install: npm install -g @railway/cli"
fi
```

**User action**: Install Railway CLI with npm

**Non-blocking**: Command continues without Railway data

### No Deployments in Window

**Detection**:
```bash
if [ -z "$OLDEST_DEPLOY" ]; then
  echo "No deployments in last 24 hours"
  echo "Full quota available"
fi
```

**Status**: NORMAL (100/100 available)

**Next steps**: Safe to deploy

### API Rate Limits

**GitHub API limits**: 5000 requests/hour (authenticated)

**Mitigation**: Use cached data if API fails

**Fallback**: Display last known quota status

---

## Best Practices

### When to Check Quota

**Before `/phase-1-ship`**: Always check quota before staging deployment

**During development**: Check periodically if doing frequent deployments

**After failures**: Check if deployments are failing due to rate limits

### Quota Conservation

**Use preview mode** for:
- CI testing
- Experimental changes
- Feature branch validation
- Debug deployments

**Use staging mode** only for:
- Actual staging environment updates
- Pre-production validation
- Final testing before production

### Failure Prevention

**Run `/validate-deploy`** before every deployment:
- Catches build failures locally
- Validates environment variables
- Tests Docker configuration
- Doesn't consume quota

**Monitor failure rate**:
- > 30% failure rate = systematic issue
- Investigate before continuing
- Fix root cause to conserve quota

---

## Related Commands

- `/validate-deploy` - Validate deployment without consuming quota
- `/phase-1-ship` - Deploy to staging (consumes quota)
- `/ship` - Unified deployment orchestrator
- `/debug` - Investigate deployment failures

---

## Notes

**Quota philosophy**: "Know your limits before you hit them. Plan deployments strategically."

**Token efficiency**: Fast calculation (~1-2 seconds), clear warnings, actionable recommendations

**Non-blocking**: Always returns with exit code 0, even on errors

**Read-only**: Does not modify any quotas or settings

**Rolling window**: Tracks exactly 24 hours from current time, not calendar day

**Prediction accuracy**: Assumes next `/phase-1-ship` uses 2 deployments (Marketing + App)

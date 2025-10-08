---
description: Track deployment quota usage and prevent rate limiting
---

# Deployment-Budget: Quota Tracker

**Command**: `/deployment-budget`

**Purpose**: Track deployment quota usage and predict remaining quota after next deployment.

**When to use**:
- Before `/phase-1-ship`
- When approaching rate limits
- To plan deployment strategy
- To debug quota exhaustion

**Quota limits**:
- Vercel: 100 deployments / 24 hours (rolling window)
- Railway: Based on compute minutes, not deployment count

---

## MENTAL MODEL

You are a **quota tracker** that prevents deployment failures due to rate limiting.

**Philosophy**: Know your limits before you hit them. Plan deployments strategically.

**Checks**:
1. Count recent Vercel deployments (24h rolling)
2. Check Railway compute usage
3. Predict quota after next deployment
4. Warn if approaching limits
5. Suggest deployment strategy

**Token efficiency**: Fast calculation, clear warnings, actionable recommendations.

---

## EXECUTION PHASES

### Phase 1: CHECK VERCEL QUOTA

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Budget (24h rolling)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VERCEL_LIMIT=100
QUOTA_WARNING_THRESHOLD=20
QUOTA_CRITICAL_THRESHOLD=10

# Get timestamp 24 hours ago
if date --version 2>/dev/null | grep -q GNU; then
  # GNU date (Linux)
  SINCE_TIME=$(date -d '24 hours ago' -Iseconds)
else
  # BSD date (macOS)
  SINCE_TIME=$(date -u -v-24H -Iseconds)
fi

echo "Vercel Deployments:"
echo ""

# Count marketing deployments
echo "  Counting marketing deployments..."
MARKETING_USED=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)

echo "  Marketing (staging): $MARKETING_USED"

# Count app deployments
echo "  Counting app deployments..."
APP_USED=$(gh run list \
  --workflow=deploy-app-staging.yml \
  --created="$SINCE_TIME" \
  --json conclusion \
  --jq 'length' 2>/dev/null || echo 0)

echo "  App (staging): $APP_USED"

# Total Vercel deployments
VERCEL_USED=$((MARKETING_USED + APP_USED))
VERCEL_REMAINING=$((VERCEL_LIMIT - VERCEL_USED))

echo ""
echo "  Total used: $VERCEL_USED / $VERCEL_LIMIT"
echo "  Remaining: $VERCEL_REMAINING"
echo ""

# Status indicator
if [ "$VERCEL_REMAINING" -lt "$QUOTA_CRITICAL_THRESHOLD" ]; then
  echo "  🚨 CRITICAL - Only $VERCEL_REMAINING deployments left"
  echo "     Wait for quota reset or use preview mode"
  BUDGET_STATUS="critical"
elif [ "$VERCEL_REMAINING" -lt "$QUOTA_WARNING_THRESHOLD" ]; then
  echo "  ⚠️  LOW - $VERCEL_REMAINING deployments remaining"
  echo "     Use /preflight before deploying"
  BUDGET_STATUS="warning"
else
  echo "  ✅ NORMAL - $VERCEL_REMAINING deployments available"
  BUDGET_STATUS="normal"
fi

echo ""
```

---

### Phase 2: CHECK RAILWAY USAGE

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Railway Compute Usage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get Railway usage (requires Railway CLI)
if command -v railway &> /dev/null; then
  echo "Fetching Railway usage..."
  echo ""

  # Railway tracks by compute minutes, not deployments
  RAILWAY_USAGE=$(railway usage 2>/dev/null || echo "")

  if [ -n "$RAILWAY_USAGE" ]; then
    echo "$RAILWAY_USAGE"
  else
    echo "  ⚠️  Unable to fetch Railway usage"
    echo "     Check authentication: railway whoami"
  fi
else
  echo "  ⚠️  Railway CLI not installed"
  echo "     Install: npm install -g @railway/cli"
fi

echo ""
```

---

### Phase 3: QUOTA RESET TIME

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Quota Reset Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Find oldest deployment in window
OLDEST_DEPLOY=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --limit 1 \
  --json createdAt \
  --jq '.[0].createdAt' 2>/dev/null || echo "")

if [ -n "$OLDEST_DEPLOY" ]; then
  # Calculate when quota will reset (24h from oldest deployment)
  if date --version 2>/dev/null | grep -q GNU; then
    RESET_TIME=$(date -d "$OLDEST_DEPLOY + 24 hours" "+%Y-%m-%d %H:%M:%S")
    RESET_IN=$(( ($(date -d "$RESET_TIME" +%s) - $(date +%s)) / 60 ))
  else
    RESET_TIME=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$OLDEST_DEPLOY" -v+24H "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
    RESET_IN="?"
  fi

  echo "Oldest deployment: $OLDEST_DEPLOY"
  echo "Quota resets at: $RESET_TIME"

  if [ "$RESET_IN" != "?" ]; then
    RESET_HOURS=$((RESET_IN / 60))
    RESET_MINS=$((RESET_IN % 60))

    echo "Time to reset: ${RESET_HOURS}h ${RESET_MINS}m"
  fi
else
  echo "No deployments in last 24 hours"
  echo "Full quota available"
fi

echo ""
```

---

### Phase 4: DEPLOYMENT PREDICTION

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Deployment Impact"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Predict quota after next /phase-1-ship
DEPLOY_COST=2  # Marketing + App (staging mode)
PROJECTED_REMAINING=$((VERCEL_REMAINING - DEPLOY_COST))

echo "Next /phase-1-ship will use:"
echo "  Marketing: 1 deployment"
echo "  App: 1 deployment"
echo "  Total: $DEPLOY_COST deployments"
echo ""

echo "Projected remaining: $PROJECTED_REMAINING / $VERCEL_LIMIT"
echo ""

# Warnings
if [ "$PROJECTED_REMAINING" -lt 0 ]; then
  echo "🚨 WOULD EXCEED QUOTA"
  echo ""
  echo "Options:"
  echo "  A) Wait for quota reset ($RESET_TIME)"
  echo "  B) Use preview mode (doesn't count toward quota)"
  echo "  C) Skip deployment and create draft PR"
  echo ""
elif [ "$PROJECTED_REMAINING" -lt "$QUOTA_CRITICAL_THRESHOLD" ]; then
  echo "⚠️  WARNING: Low quota after deployment"
  echo ""
  echo "Recommendation:"
  echo "  - Run /preflight before deploying (catches failures locally)"
  echo "  - Consider preview mode for CI testing"
  echo "  - Reserve staging mode for final deployment"
  echo ""
elif [ "$PROJECTED_REMAINING" -lt "$QUOTA_WARNING_THRESHOLD" ]; then
  echo "⚠️  Approaching quota limits"
  echo ""
  echo "Recommendation:"
  echo "  - Use /preflight to validate before deploying"
  echo "  - Plan remaining deployments carefully"
  echo ""
else
  echo "✅ Sufficient quota for deployment"
  echo ""
fi
```

---

### Phase 5: DEPLOYMENT STRATEGY

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment Strategy Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$BUDGET_STATUS" = "critical" ]; then
  echo "Current status: CRITICAL ($VERCEL_REMAINING remaining)"
  echo ""
  echo "🛑 DO NOT use staging mode"
  echo ""
  echo "Recommended actions:"
  echo "  1. Wait for quota reset ($RESET_TIME)"
  echo "  2. OR use preview mode:"
  echo "     - Tests CI without consuming quota"
  echo "     - Doesn't update staging.cfipros.com"
  echo "     - Unlimited usage"
  echo ""
  echo "Preview mode usage:"
  echo "  /phase-1-ship"
  echo "  → Select 'preview' when prompted"
  echo ""

elif [ "$BUDGET_STATUS" = "warning" ]; then
  echo "Current status: LOW ($VERCEL_REMAINING remaining)"
  echo ""
  echo "⚠️  Use quota carefully"
  echo ""
  echo "Best practices:"
  echo "  1. Run /preflight before every /phase-1-ship"
  echo "  2. Use preview mode for CI testing"
  echo "  3. Use staging mode only for actual staging deploys"
  echo "  4. Fix issues locally before pushing"
  echo ""
  echo "Workflow:"
  echo "  /preflight → /phase-1-ship (preview) → verify → /phase-1-ship (staging)"
  echo ""

else
  echo "Current status: NORMAL ($VERCEL_REMAINING remaining)"
  echo ""
  echo "✅ Enough quota for normal workflow"
  echo ""
  echo "Best practices:"
  echo "  1. Still run /preflight to catch issues early"
  echo "  2. Use preview mode for experimental changes"
  echo "  3. Monitor quota with /deployment-budget"
  echo ""
fi
```

---

### Phase 6: RECENT DEPLOYMENT ANALYSIS

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recent Deployment Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get recent deployments with status
RECENT_DEPLOYS=$(gh run list \
  --workflow=deploy-staging.yml \
  --created="$SINCE_TIME" \
  --limit 10 \
  --json conclusion,createdAt,displayTitle \
  --jq '.[] | "\(.conclusion) - \(.displayTitle) - \(.createdAt)"' 2>/dev/null || echo "")

if [ -n "$RECENT_DEPLOYS" ]; then
  echo "Last 10 deployments (24h):"
  echo ""

  # Count successes and failures
  SUCCESS_COUNT=$(echo "$RECENT_DEPLOYS" | grep -c "^success" || echo 0)
  FAILURE_COUNT=$(echo "$RECENT_DEPLOYS" | grep -c "^failure" || echo 0)

  echo "  Success: $SUCCESS_COUNT"
  echo "  Failure: $FAILURE_COUNT"

  if [ "$FAILURE_COUNT" -gt 0 ]; then
    FAILURE_RATE=$(( (FAILURE_COUNT * 100) / (SUCCESS_COUNT + FAILURE_COUNT) ))
    echo ""
    echo "  ⚠️  Failure rate: ${FAILURE_RATE}%"

    if [ "$FAILURE_RATE" -gt 30 ]; then
      echo ""
      echo "  🚨 HIGH failure rate detected"
      echo "     Run /debug to investigate issues"
      echo "     Use /preflight before deploying"
    fi
  fi

  echo ""
  echo "Recent deploys:"
  echo "$RECENT_DEPLOYS" | head -5 | sed 's/^/  /'
else
  echo "No recent deployments found"
fi

echo ""
```

---

### Phase 7: FINAL SUMMARY

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$BUDGET_STATUS" in
  critical)
    echo "🚨 QUOTA CRITICAL - DO NOT DEPLOY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Remaining: $VERCEL_REMAINING / $VERCEL_LIMIT"
    echo "Reset at: $RESET_TIME"
    echo ""
    echo "Use preview mode or wait for reset"
    ;;

  warning)
    echo "⚠️  QUOTA LOW - DEPLOY CAREFULLY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Remaining: $VERCEL_REMAINING / $VERCEL_LIMIT"
    echo "After next deploy: ~$PROJECTED_REMAINING"
    echo ""
    echo "Run /preflight before deploying"
    ;;

  *)
    echo "✅ QUOTA NORMAL - SAFE TO DEPLOY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Remaining: $VERCEL_REMAINING / $VERCEL_LIMIT"
    echo "After next deploy: ~$PROJECTED_REMAINING"
    echo ""
    echo "Proceed with /phase-1-ship"
    ;;
esac

echo ""
```

---

## ERROR HANDLING

**GitHub CLI not authenticated**: Shows `gh auth login` command

**Railway CLI not found**: Shows installation instructions

**No deployments in window**: Shows "Full quota available"

**API rate limits**: Uses cached data if available

---

## CONSTRAINTS

- Requires GitHub CLI installed and authenticated
- Requires Railway CLI for compute usage (optional)
- Read-only: Does not modify any quotas
- 24-hour rolling window for Vercel
- Non-blocking: Always returns with exit code 0

---

## RETURN

**Normal quota**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ QUOTA NORMAL - SAFE TO DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 82 / 100
After next deploy: ~80

Proceed with /phase-1-ship
```

**Low quota**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  QUOTA LOW - DEPLOY CAREFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 15 / 100
After next deploy: ~13

Run /preflight before deploying
```

**Critical quota**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 QUOTA CRITICAL - DO NOT DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining: 3 / 100
Reset at: 2025-01-08 14:30:00

Use preview mode or wait for reset
```

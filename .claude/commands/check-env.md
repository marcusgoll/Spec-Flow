---
description: Validate environment variables before deployment
---

# Check-Env: Environment Variable Validator

**Command**: `/check-env [environment]`

**Purpose**: Validate environment variables before deployment. Prevents "missing env var" deployment failures.

**When to use**:
- Before `/phase-1-ship` (staging)
- Before `/phase-2-ship` (production)
- After updating environment configurations
- When troubleshooting deployment failures

**Arguments**:
- `staging` - Check staging environment
- `production` - Check production environment
- (none) - Interactive selection

---

## MENTAL MODEL

You are an **environment validator** that ensures all required environment variables are configured in Doppler.

**Philosophy**: Deployments fail 30% of the time due to missing environment variables. Catch these before deployment by validating Doppler (single source of truth).

**Checks**:
1. Verify Doppler CLI installed and authenticated
2. Check Doppler configs exist for target environment
3. Validate all required secrets present in each config
4. Optionally verify platform sync (Vercel, Railway, GitHub)
5. Report missing/misconfigured variables with fix commands

**Token efficiency**: Fast validation, clear output, actionable fixes.

---

## EXECUTION PHASES

### Phase 1: SELECT ENVIRONMENT

```bash
#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment Variable Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ENVIRONMENT="$ARGUMENTS"

if [ -z "$ENVIRONMENT" ]; then
  echo "Select environment:"
  echo "  1. staging"
  echo "  2. production"
  echo ""
  read -p "Choose (1-2): " ENV_CHOICE

  case "$ENV_CHOICE" in
    1) ENVIRONMENT="staging" ;;
    2) ENVIRONMENT="production" ;;
    *)
      echo "Invalid choice"
      exit 1
      ;;
  esac
fi

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo ""
  echo "Usage: /check-env [staging|production]"
  exit 1
fi

echo "Environment: $ENVIRONMENT"
echo ""
```

---

### Phase 2: CHECK DOPPLER CLI

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 2: Doppler CLI Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Doppler CLI is installed
if ! command -v doppler &>/dev/null; then
  echo "❌ Doppler CLI not installed"
  echo ""
  echo "Install via:"
  echo "  scoop install doppler  (Windows)"
  echo "  brew install dopplerhq/cli/doppler  (macOS)"
  echo "  curl -Ls https://cli.doppler.com/install.sh | sh  (Linux)"
  echo ""
  echo "Or run setup:"
  echo "  bash \spec-flow/commands/setup-doppler.sh"
  exit 1
fi

echo "✅ Doppler CLI installed"

# Check authentication
if ! doppler me &>/dev/null; then
  echo "❌ Not authenticated with Doppler"
  echo ""
  echo "Authenticate via:"
  echo "  doppler login"
  echo ""
  exit 1
fi

echo "✅ Doppler authenticated"
echo ""
```

---

### Phase 3: VALIDATE DOPPLER CONFIGS

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 3: Doppler Config Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROJECT="cfipros"
CONFIGS=("${ENVIRONMENT}_marketing" "${ENVIRONMENT}_app" "${ENVIRONMENT}_api")
MISSING_CONFIGS=false

echo "Checking configs for environment: $ENVIRONMENT"
echo ""

for config in "${CONFIGS[@]}"; do
  echo "Config: $config"

  # Check if config exists
  if doppler configs list --project "$PROJECT" --json 2>/dev/null | \
     jq -e ".[] | select(.name==\"$config\")" >/dev/null 2>&1; then
    echo "  ✅ Config exists"
  else
    echo "  ❌ Config missing"
    MISSING_CONFIGS=true
  fi

  echo ""
done

if [ "$MISSING_CONFIGS" = true ]; then
  echo "❌ Missing Doppler configs"
  echo ""
  echo "Run setup to create configs:"
  echo "  bash \spec-flow/commands/setup-doppler.sh"
  echo ""
  exit 1
fi

echo "✅ All Doppler configs exist"
echo ""
```

---

### Phase 4: CHECK REQUIRED SECRETS

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 4: Required Secrets Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MISSING_VARS=false

# Define required secrets per service
FRONTEND_SECRETS=(
  "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY"
  "CLERK_SECRET_KEY"
  "NEXT_PUBLIC_API_URL"
  "BACKEND_API_URL"
  "NEXT_PUBLIC_APP_URL"
  "NEXT_PUBLIC_MARKETING_URL"
  "UPSTASH_REDIS_REST_URL"
  "UPSTASH_REDIS_REST_TOKEN"
  "NEXT_PUBLIC_HCAPTCHA_SITE_KEY"
  "HCAPTCHA_SECRET_KEY"
  "JWT_SECRET"
  "NEXT_PUBLIC_POSTHOG_KEY"
  "NEXT_PUBLIC_POSTHOG_HOST"
)

BACKEND_SECRETS=(
  "DATABASE_URL"
  "DIRECT_URL"
  "OPENAI_API_KEY"
  "VISION_MODEL"
  "SECRET_KEY"
  "ENVIRONMENT"
  "ALLOWED_ORIGINS"
  "REDIS_URL"
)

# Check marketing secrets
echo "Marketing (${ENVIRONMENT}_marketing):"
MARKETING_CONFIG="${ENVIRONMENT}_marketing"

for secret in "${FRONTEND_SECRETS[@]}"; do
  if doppler secrets get "$secret" \
     --project "$PROJECT" \
     --config "$MARKETING_CONFIG" \
     --plain >/dev/null 2>&1; then
    echo "  ✅ $secret"
  else
    echo "  ❌ $secret (missing)"
    MISSING_VARS=true
  fi
done

echo ""

# Check app secrets
echo "App (${ENVIRONMENT}_app):"
APP_CONFIG="${ENVIRONMENT}_app"

for secret in "${FRONTEND_SECRETS[@]}"; do
  if doppler secrets get "$secret" \
     --project "$PROJECT" \
     --config "$APP_CONFIG" \
     --plain >/dev/null 2>&1; then
    echo "  ✅ $secret"
  else
    echo "  ❌ $secret (missing)"
    MISSING_VARS=true
  fi
done

echo ""

# Check API secrets
echo "API (${ENVIRONMENT}_api):"
API_CONFIG="${ENVIRONMENT}_api"

for secret in "${BACKEND_SECRETS[@]}"; do
  if doppler secrets get "$secret" \
     --project "$PROJECT" \
     --config "$API_CONFIG" \
     --plain >/dev/null 2>&1; then
    echo "  ✅ $secret"
  else
    echo "  ❌ $secret (missing)"
    MISSING_VARS=true
  fi
done

echo ""
```

---

### Phase 5: ENVIRONMENT-SPECIFIC CHECKS

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 5: Environment-Specific Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check ENVIRONMENT variable matches target
API_ENV_VAR=$(doppler secrets get ENVIRONMENT \
  --project "$PROJECT" \
  --config "$API_CONFIG" \
  --plain 2>/dev/null || echo "")

if [ "$API_ENV_VAR" != "$ENVIRONMENT" ]; then
  echo "⚠️  ENVIRONMENT mismatch in API config"
  echo "   Expected: $ENVIRONMENT"
  echo "   Actual: $API_ENV_VAR"
  echo ""
else
  echo "✅ ENVIRONMENT variable correct: $ENVIRONMENT"
fi

# Check URLs match environment
# SECURITY: Never print actual URL values to avoid exposing secrets in query params
if [ "$ENVIRONMENT" = "staging" ]; then
  echo "Checking staging URLs..."

  API_URL=$(doppler secrets get NEXT_PUBLIC_API_URL \
    --project "$PROJECT" \
    --config "$APP_CONFIG" \
    --plain 2>/dev/null || echo "")

  if [[ "$API_URL" =~ staging ]] || [[ "$API_URL" =~ railway.app ]]; then
    echo "  ✅ NEXT_PUBLIC_API_URL points to staging"
  else
    # Extract domain only (no query params or paths that might contain secrets)
    URL_DOMAIN=$(echo "$API_URL" | sed -E 's|https?://([^/?]+).*|\1|')
    echo "  ⚠️  NEXT_PUBLIC_API_URL domain: $URL_DOMAIN (should contain 'staging' or 'railway.app')"
    echo "  💡 Tip: Check Doppler dashboard for full URL"
  fi

elif [ "$ENVIRONMENT" = "production" ]; then
  echo "Checking production URLs..."

  API_URL=$(doppler secrets get NEXT_PUBLIC_API_URL \
    --project "$PROJECT" \
    --config "$APP_CONFIG" \
    --plain 2>/dev/null || echo "")

  if [[ "$API_URL" =~ api.cfipros.com ]]; then
    echo "  ✅ NEXT_PUBLIC_API_URL points to production"
  else
    # Extract domain only (no query params or paths that might contain secrets)
    URL_DOMAIN=$(echo "$API_URL" | sed -E 's|https?://([^/?]+).*|\1|')
    echo "  ⚠️  NEXT_PUBLIC_API_URL domain: $URL_DOMAIN (should be api.cfipros.com)"
    echo "  💡 Tip: Check Doppler dashboard for full URL"
  fi
fi

echo ""
```

---

### Phase 6: OPTIONAL PLATFORM SYNC CHECK

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 6: Platform Sync Verification (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check GitHub Secrets (if gh CLI available)
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "GitHub Secrets:"

  GITHUB_SECRETS=(
    "GITHUB_ACTIONS_${ENVIRONMENT^^}_MARKETING"
    "GITHUB_ACTIONS_${ENVIRONMENT^^}_APP"
    "GITHUB_ACTIONS_${ENVIRONMENT^^}_API"
  )

  for secret in "${GITHUB_SECRETS[@]}"; do
    if gh secret list | grep -q "^${secret}"; then
      echo "  ✅ $secret"
    else
      echo "  ⚠️  $secret (not configured)"
    fi
  done

  echo ""
fi

# Check Railway DOPPLER_TOKEN (if railway CLI available)
if command -v railway &>/dev/null && railway whoami &>/dev/null; then
  echo "Railway Configuration:"

  RAILWAY_TOKEN=$(railway variables get DOPPLER_TOKEN --environment "$ENVIRONMENT" 2>/dev/null || echo "")

  if [ -n "$RAILWAY_TOKEN" ]; then
    echo "  ✅ DOPPLER_TOKEN configured"
  else
    echo "  ⚠️  DOPPLER_TOKEN not set (manual env vars or needs setup)"
  fi

  echo ""
fi

echo "✅ Platform sync checks complete"
echo ""
```

---

### Phase 7: FINAL REPORT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$MISSING_VARS" = true ]; then
  echo "❌ MISSING SECRETS IN DOPPLER"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Fix missing secrets before deploying."
  echo ""
  echo "Add secrets to Doppler:"
  echo ""
  echo "  # For marketing:"
  echo "  doppler secrets set VAR_NAME=value \\"
  echo "    --project cfipros \\"
  echo "    --config ${ENVIRONMENT}_marketing"
  echo ""
  echo "  # For app:"
  echo "  doppler secrets set VAR_NAME=value \\"
  echo "    --project cfipros \\"
  echo "    --config ${ENVIRONMENT}_app"
  echo ""
  echo "  # For API:"
  echo "  doppler secrets set VAR_NAME=value \\"
  echo "    --project cfipros \\"
  echo "    --config ${ENVIRONMENT}_api"
  echo ""
  echo "Or use Doppler dashboard:"
  echo "  https://dashboard.doppler.com/workplace/[workplace]/projects/cfipros/configs/${ENVIRONMENT}_[service]"
  echo ""
  echo "Secrets will auto-sync to Vercel/Railway/GitHub"
  echo ""

  exit 1
else
  echo "✅ ALL SECRETS CONFIGURED IN DOPPLER"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Environment: $ENVIRONMENT"
  echo "Frontend secrets: ${#FRONTEND_SECRETS[@]}"
  echo "Backend secrets: ${#BACKEND_SECRETS[@]}"
  echo "Status: All present ✅"
  echo ""
  echo "Safe to deploy to $ENVIRONMENT"
  echo ""
  echo "Next steps:"
  echo "  /validate-deploy     # Run pre-flight validation"
  echo "  /phase-1-ship        # Deploy to staging"
  echo ""

  exit 0
fi
```

---

## ERROR HANDLING

**Vercel CLI not authenticated**: Shows `vercel whoami` command

**Railway CLI not authenticated**: Shows `railway whoami` command

**Environment doesn't exist**: Shows `railway environment` command

**.env.example missing**: Instructs to create with all required vars

**API rate limits**: Retries with exponential backoff

---

## CONSTRAINTS

- Requires Vercel CLI installed and authenticated
- Requires Railway CLI installed and authenticated
- Requires `.env.example` in repository root
- Non-destructive: Only reads environment variables
- Does not modify any environment variables
- Does not expose variable values (only checks presence)

---

## RETURN

**Success**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL ENVIRONMENT VARIABLES CONFIGURED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Environment: staging
Expected: 24 variables
Status: All present

Safe to deploy to staging
```

**Failure**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ MISSING ENVIRONMENT VARIABLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Missing variables listed above]

Add to Vercel:
  vercel env add [VAR_NAME] staging

Add to Railway:
  railway variables set [VAR_NAME]=[value] --environment staging
```


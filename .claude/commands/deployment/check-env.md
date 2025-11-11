---
description: Validate environment variables before deployment
---

# /check-env — Environment Variable Validator

**Command**: `/check-env [staging|production]`

**Purpose**: Fail fast on missing or misrouted configuration. Validates required secrets in Doppler and optionally verifies platform sync (GitHub, Vercel, Railway) without printing values.

**Run before**:
- `/phase-1-ship` (staging)
- `/phase-2-ship` (production)

**Valid targets**: `staging`, `production` (no arg → interactive prompt)

**What it checks**
1. Doppler CLI installed and authenticated (fast "me" probe)
2. Required Doppler configs for each surface: `*_marketing`, `*_app`, `*_api`
3. Presence of all required secrets per surface
4. Env correctness (e.g., `ENVIRONMENT` = target)
5. URL sanity (domain-only match; never echo full values)
6. Optional platform sync:
   - GitHub secrets present for CI
   - Vercel/Railway integration tokens present (if CLIs authed)

**Output**
- Human-readable summary
- Nonzero exit when missing or mismatched
- JSON report at `specs/<feature>/reports/check-env.json`

**Security**
- Never prints secret values
- Domain-only checks for URLs
- All platform checks are read-only

**Token efficiency**: Fast validation, deterministic output, actionable fixes.

---

## MENTAL MODEL

You are an **environment validator** that ensures all required environment variables are configured before deployment.

**Philosophy**: Deployments fail 30% of the time due to missing environment variables. Catch these before deployment by validating Doppler (single source of truth) with zero secrets leakage.

**Central truth**: `.env.example` defines required keys. Curated lists classify keys by surface (frontend/backend).

**Execution**: Hardened bash script (`.spec-flow/scripts/bash/check-env.sh`) with:
- `set -Eeuo pipefail` for fail-fast behavior
- JSON output for programmatic consumption
- Read-only platform probes
- Domain-only URL validation

---

## EXECUTION FLOW

### Phase 1: Environment Selection

Resolve target from CLI arg or interactive prompt. Validate `staging` or `production` only.

### Phase 2: Doppler CLI Validation

- Check `doppler` command exists
- Probe authentication via `doppler me`
- Exit early if not installed or authenticated

### Phase 3: Config Existence

For each surface (`marketing`, `app`, `api`):
- Query `doppler configs list --project PROJECT --json`
- Verify `${TARGET}_${SURFACE}` config exists
- Report missing configs with setup instructions

### Phase 4: Secret Presence

For each required secret:
- Probe `doppler secrets get KEY --config CONFIG --plain`
- Record present/missing status (never print values)
- Aggregate by config

**Secret Lists**:

```bash
# Frontend surfaces (marketing, app)
FRONTEND_SECRETS=(
  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
  CLERK_SECRET_KEY
  NEXT_PUBLIC_API_URL
  BACKEND_API_URL
  NEXT_PUBLIC_APP_URL
  NEXT_PUBLIC_MARKETING_URL
  UPSTASH_REDIS_REST_URL
  UPSTASH_REDIS_REST_TOKEN
  NEXT_PUBLIC_HCAPTCHA_SITE_KEY
  HCAPTCHA_SECRET_KEY
  JWT_SECRET
  NEXT_PUBLIC_POSTHOG_KEY
  NEXT_PUBLIC_POSTHOG_HOST
)

# Backend surface (api)
BACKEND_SECRETS=(
  DATABASE_URL
  DIRECT_URL
  OPENAI_API_KEY
  VISION_MODEL
  SECRET_KEY
  ENVIRONMENT
  ALLOWED_ORIGINS
  REDIS_URL
)
```

**Drift detection**: If `.env.example` exists, compare curated lists against example keys and report extras.

### Phase 5: Environment-Specific Validation

**ENVIRONMENT variable match**:
```bash
api_env=$(doppler secrets get ENVIRONMENT --config ${TARGET}_api --plain)
if [[ "$api_env" != "$TARGET" ]]; then
  warn "ENVIRONMENT mismatch: expected '$TARGET', got '$api_env'"
fi
```

**URL sanity checks** (domain-only, never print full URLs):
```bash
api_url=$(doppler secrets get NEXT_PUBLIC_API_URL --config ${TARGET}_app --plain)
domain=$(echo "$api_url" | sed -E 's|https?://([^/?]+).*|\1|')

if [[ "$TARGET" == "staging" ]]; then
  # Accept staging-like domains
  [[ "$domain" =~ staging|railway.app ]] && ok || warn
else
  # Require production domain
  [[ "$domain" == "api.cfipros.com" ]] && ok || warn
fi
```

### Phase 6: Optional Platform Sync

**GitHub** (if `gh` CLI authenticated):
```bash
gh secret list >/dev/null && ok "gh secret list available"
```

**Vercel** (if `vercel` CLI installed):
```bash
vercel --version >/dev/null && ok "Vercel CLI available"
```

**Railway** (if `railway` CLI authenticated):
```bash
railway whoami >/dev/null && echo "Railway: verify DOPPLER_TOKEN in deployment UI"
```

### Phase 7: Final Report

**JSON output** (`specs/<feature>/reports/check-env.json`):
```json
{
  "environment": "staging",
  "project": "cfipros",
  "summary": {
    "missing": 0,
    "present": 21
  },
  "details": {
    "missing": [],
    "present": [
      "staging_marketing:NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY",
      "staging_app:NEXT_PUBLIC_API_URL",
      "staging_api:DATABASE_URL"
    ]
  }
}
```

**Exit codes**:
- `0` — All secrets present, safe to deploy
- `1` — Missing secrets or mismatched environment

**Console output**:

**Success**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL SECRETS CONFIGURED IN DOPPLER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Environment: staging
Safe to deploy
Report: specs/001-auth/reports/check-env.json
```

**Failure**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ MISSING SECRETS IN DOPPLER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fix with Doppler CLI (examples):
  doppler secrets set VAR=value --project cfipros --config staging_app
  doppler secrets set VAR=value --project cfipros --config staging_api

See JSON report: specs/001-auth/reports/check-env.json
```

---

## ERROR HANDLING

| Error | Fix |
|-------|-----|
| Doppler CLI not installed | Install via `brew install dopplerhq/cli/doppler` (macOS), `curl -Ls https://cli.doppler.com/install.sh \| sh` (Linux), `winget install doppler.doppler` (Windows) |
| Not authenticated | Run `doppler login` |
| Missing configs | Run `.spec-flow/scripts/bash/setup-doppler.sh` (if exists) or create configs manually via Doppler dashboard |
| Missing secrets | Use `doppler secrets set KEY=value --project PROJECT --config CONFIG` or Doppler dashboard |
| ENVIRONMENT mismatch | Update `ENVIRONMENT` variable in Doppler to match target |
| URL points to wrong env | Update URL variables in Doppler (staging should contain "staging" or "railway.app", production should be "api.cfipros.com") |

---

## CONSTRAINTS

- Requires Doppler CLI installed and authenticated
- Requires `.env.example` in repository root (optional, for drift detection)
- Non-destructive: Only reads environment variables
- Does not modify any environment variables
- Does not expose variable values (only checks presence)
- Platform sync checks require respective CLIs installed and authenticated

---

## USAGE EXAMPLES

**Check staging before deployment**:
```bash
/check-env staging
# or via script directly:
.spec-flow/scripts/bash/check-env.sh staging
```

**Interactive selection**:
```bash
/check-env
# Prompts:
# Select environment:
#   1) staging
#   2) production
# Choose (1-2): 1
```

**Override project name**:
```bash
PROJECT=my-project .spec-flow/scripts/bash/check-env.sh production
```

**Check JSON report**:
```bash
cat specs/NNN-slug/reports/check-env.json | jq '.details.missing'
```

---

## INTEGRATION

**Pre-ship validation** (recommended):
```bash
# In .spec-flow/scripts/bash/validate-deploy.sh
echo "Validating environment variables..."
if ! .spec-flow/scripts/bash/check-env.sh "$TARGET"; then
  echo "❌ Environment validation failed"
  exit 1
fi
```

**CI pipeline**:
```yaml
# .github/workflows/deploy.yml
- name: Validate environment
  run: |
    .spec-flow/scripts/bash/check-env.sh staging
```

**Development workflow**:
1. Update `.env.example` when adding new required variables
2. Run `/check-env staging` to verify Doppler sync
3. Add missing secrets to Doppler
4. Re-run `/check-env staging` to confirm
5. Proceed with deployment

---

## ALTERNATIVES

**Schema-driven validation**:
- Keep `config/schema.yaml` mapping surfaces→required keys
- Generate Doppler checklists from schema
- **Pro**: Zero duplication
- **Con**: Another artifact to maintain

**Doppler Service Tokens in CI**:
- Use read-only service tokens scoped to each config
- Verify presence server-side without developer auth
- **Pro**: Cleaner for CI, no developer context needed
- **Con**: Slightly more setup

**Platform-native enforcement**:
- Mirror required keys into Vercel/Railway
- Block CI if any required key is missing
- **Pro**: Single pane for platform teams
- **Con**: Tighter coupling to deploy target

---

## REFERENCES

- [Doppler CLI Installation](https://docs.doppler.com/docs/install-cli)
- [Doppler Authentication](https://docs.doppler.com/docs/multi-factor-authentication)
- [Doppler Secrets Management](https://docs.doppler.com/docs/secrets)
- [Vercel Environment Variables](https://vercel.com/docs/environment-variables)
- [Railway Environment Variables](https://docs.railway.app/deploy/variables)
- [GitHub CLI Secrets](https://cli.github.com/manual/gh_secret)

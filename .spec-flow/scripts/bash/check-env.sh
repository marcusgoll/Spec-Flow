#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------
# /check-env [staging|production]
# -----------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FEATURE_DIR="${FEATURE_DIR:-"$(ls -td "$REPO_ROOT/specs"/*/ 2>/dev/null | head -1)"}"
REPORT_DIR="$FEATURE_DIR/reports"
mkdir -p "$REPORT_DIR"

PROJECT="${PROJECT:-cfipros}"            # override via env if needed
SERVICES=("marketing" "app" "api")        # surfaces to check
TARGET="${1:-}"                           # staging|production|'' (interactive)
JSON="$REPORT_DIR/check-env.json"

# Colors
b() { printf "\033[1m%s\033[0m\n" "$*"; }
ok() { printf "✅ %s\n" "$*"; }
warn(){ printf "⚠️  %s\n" "$*"; }
err(){ printf "❌ %s\n" "$*"; }

# ---- Phase 1: Resolve environment ------------------------------------------------
b "Environment Variable Check"
if [[ -z "${TARGET}" ]]; then
  echo "Select environment:"
  echo "  1) staging"
  echo "  2) production"
  read -r -p "Choose (1-2): " choice
  case "$choice" in
    1) TARGET="staging" ;;
    2) TARGET="production" ;;
    *) err "Invalid choice"; exit 1 ;;
  esac
fi

if [[ "$TARGET" != "staging" && "$TARGET" != "production" ]]; then
  err "Invalid environment: $TARGET"
  echo "Usage: /check-env [staging|production]"
  exit 1
fi
echo "Environment: $TARGET"; echo

# ---- Phase 2: Doppler CLI/auth ---------------------------------------------------
b "Phase 2: Doppler CLI Validation"
if ! command -v doppler >/dev/null 2>&1; then
  err "Doppler CLI not installed"
  echo "Install:"
  echo "  macOS:  brew install dopplerhq/cli/doppler"
  echo "  Linux:  curl -Ls https://cli.doppler.com/install.sh | sh"
  echo "  Win:    winget install doppler.doppler  or  scoop install doppler"
  # Docs: https://docs.doppler.com/docs/install-cli
  exit 1
fi
ok "Doppler CLI installed"

# Quick auth probe (maps to 'me' API)
if ! doppler me >/dev/null 2>&1; then
  err "Not authenticated with Doppler. Run: doppler login"
  exit 1
fi
ok "Doppler authenticated"; echo

# ---- Phase 3: Config existence ---------------------------------------------------
b "Phase 3: Doppler Config Validation"
missing_configs=()
for svc in "${SERVICES[@]}"; do
  cfg="${TARGET}_${svc}"
  echo "Config: $cfg"
  if doppler configs list --project "$PROJECT" --json 2>/dev/null \
    | jq -e ".[] | select(.name==\"$cfg\")" >/dev/null 2>&1; then
    echo "  ✅ Exists"
  else
    echo "  ❌ Missing"
    missing_configs+=("$cfg")
  fi
done
echo

if (( ${#missing_configs[@]} > 0 )); then
  err "Missing Doppler configs: ${missing_configs[*]}"
  echo "Run setup to create configs: .spec-flow/scripts/bash/setup-doppler.sh"
  exit 1
fi
ok "All Doppler configs exist"; echo

# ---- Phase 4: Required secrets ---------------------------------------------------
b "Phase 4: Required Secrets Validation"
# Prefer central truth from .env.example to reduce drift. Fall back to curated lists.
ENV_EXAMPLE="$REPO_ROOT/.env.example"

declare -a FRONTEND_SECRETS=(
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

declare -a BACKEND_SECRETS=(
  DATABASE_URL
  DIRECT_URL
  OPENAI_API_KEY
  VISION_MODEL
  SECRET_KEY
  ENVIRONMENT
  ALLOWED_ORIGINS
  REDIS_URL
)

# If .env.example exists, merge keys (non-comment, KEY= or KEY:)
if [[ -f "$ENV_EXAMPLE" ]]; then
  mapfile -t EXAMPLE_KEYS < <(grep -E '^[A-Z0-9_]+(\s*[:=])' "$ENV_EXAMPLE" | sed -E 's/[:=].*$//' | sort -u)
  # keep curated lists for classification, but use EXAMPLE_KEYS to detect gaps
fi

missing=()
present=()

check_cfg() {
  local cfg="$1"; shift
  local -n KEYS="$1"
  echo "$cfg:"
  for key in "${KEYS[@]}"; do
    if doppler secrets get "$key" --project "$PROJECT" --config "$cfg" --plain >/dev/null 2>&1; then
      echo "  ✅ $key"
      present+=("$cfg:$key")
    else
      echo "  ❌ $key (missing)"
      missing+=("$cfg:$key")
    fi
  done
  echo
}

check_cfg "${TARGET}_marketing" FRONTEND_SECRETS
check_cfg "${TARGET}_app"       FRONTEND_SECRETS
check_cfg "${TARGET}_api"       BACKEND_SECRETS

# Additional keys from .env.example that aren't in curated lists (heads-up only)
if [[ -n "${EXAMPLE_KEYS:-}" ]]; then
  echo "Δ From .env.example (informational):"
  for k in "${EXAMPLE_KEYS[@]}"; do
    if ! printf '%s\n' "${FRONTEND_SECRETS[@]}" "${BACKEND_SECRETS[@]}" | grep -qx "$k"; then
      echo "  • $k (not in curated lists)"
    fi
  done
  echo
fi

# ---- Phase 5: Target-specific sanity --------------------------------------------
b "Phase 5: Environment-Specific Validation"

API_CFG="${TARGET}_api"
api_env="$(doppler secrets get ENVIRONMENT --project "$PROJECT" --config "$API_CFG" --plain 2>/dev/null || true)"
if [[ "${api_env:-}" != "$TARGET" ]]; then
  warn "ENVIRONMENT mismatch in API config: expected '$TARGET', got '${api_env:-unset}'"
else
  ok "ENVIRONMENT variable correct: $TARGET"
fi

APP_CFG="${TARGET}_app"
api_url="$(doppler secrets get NEXT_PUBLIC_API_URL --project "$PROJECT" --config "$APP_CFG" --plain 2>/dev/null || true)"
if [[ -n "${api_url:-}" ]]; then
  domain="$(echo "$api_url" | sed -E 's|https?://([^/?]+).*|\1|')"
  if [[ "$TARGET" == "staging" ]]; then
    if [[ "$domain" == *"staging"* || "$domain" == *"railway.app" ]]; then
      ok "NEXT_PUBLIC_API_URL points to staging-like domain: $domain"
    else
      warn "NEXT_PUBLIC_API_URL domain '$domain' doesn't look like staging"
    fi
  else
    if [[ "$domain" == "api.cfipros.com" ]]; then
      ok "NEXT_PUBLIC_API_URL points to production: $domain"
    else
      warn "NEXT_PUBLIC_API_URL domain '$domain' should be 'api.cfipros.com'"
    fi
  fi
else
  warn "NEXT_PUBLIC_API_URL not set (already flagged above if missing)"
fi
echo

# ---- Phase 6: Optional platform sync --------------------------------------------
b "Phase 6: Platform Sync Verification (Optional)"

# GitHub CLI secrets
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "GitHub Secrets (org/repo scope as configured by gh):"
  # Presence-only; org/repo context comes from gh auth directory
  gh secret list >/dev/null 2>&1 && ok "gh secret list available" || warn "gh secret list not available"
  echo
fi

# Vercel CLI probe (presence only; env management doc: vercel env add)
if command -v vercel >/dev/null 2>&1; then
  vercel --version >/dev/null 2>&1 && ok "Vercel CLI available" || warn "Vercel CLI not working"
fi

# Railway CLI probe and doppler token presence (if using Sync)
if command -v railway >/dev/null 2>&1 && railway whoami >/dev/null 2>&1; then
  echo "Railway: checking DOPPLER_TOKEN presence is project-specific; verify in deployment env UI/CLI."
  # Railway CLI does not universally expose a cross-project `variables get` w/o context; keep informational.
  echo
fi

ok "Platform sync checks complete"; echo

# ---- Phase 7: Final report -------------------------------------------------------
status=0
if (( ${#missing[@]} > 0 )); then
  status=1
fi

# Write JSON report
jq -n --arg env "$TARGET" \
  --arg project "$PROJECT" \
  --argjson missing "$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .)" \
  --argjson present "$(printf '%s\n' "${present[@]}" | jq -R . | jq -s .)" \
  '{
     environment: $env,
     project: $project,
     summary: {
       missing: ($missing | length),
       present: ($present | length)
     },
     details: {
       missing: $missing,
       present: $present
     }
   }' > "$JSON"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if (( status != 0 )); then
  err "MISSING SECRETS IN DOPPLER"
  echo
  echo "Fix with Doppler CLI (examples):"
  echo "  doppler secrets set VAR=value --project $PROJECT --config ${TARGET}_app"
  echo "  doppler secrets set VAR=value --project $PROJECT --config ${TARGET}_api"
  echo
  echo "See JSON report: $JSON"
  exit 1
else
  ok "ALL SECRETS CONFIGURED IN DOPPLER"
  echo "Environment: $TARGET"
  echo "Safe to deploy"
  echo "Report: $JSON"
  exit 0
fi

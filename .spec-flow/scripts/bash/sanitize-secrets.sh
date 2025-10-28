#!/usr/bin/env bash
#
# sanitize-secrets.sh - Secret sanitization utility for Spec-Flow reports
#
# PURPOSE:
#   Removes sensitive information from text before writing to documentation files.
#   Prevents accidental secret exposure in reports, summaries, and artifacts.
#
# USAGE:
#   # Sanitize stdin
#   echo "API_KEY=abc123xyz" | sanitize_secrets
#
#   # Sanitize file
#   sanitize_secrets < input.txt > output.txt
#
#   # Sanitize string variable
#   CLEAN=$(echo "$DIRTY" | sanitize_secrets)
#
#   # Source in scripts
#   source .spec-flow/scripts/bash/sanitize-secrets.sh
#   sanitize_secrets <<< "$CONTENT"
#
# PATTERNS DETECTED:
#   - API keys (api_key, apikey, api-key)
#   - Tokens (token, bearer, auth_token)
#   - Passwords (password, pwd, passwd)
#   - Database URLs (postgresql://, mysql://, mongodb://)
#   - URLs with embedded credentials (https://user:pass@host)
#   - JWT tokens (eyJ... pattern)
#   - AWS keys (AKIA..., aws_secret_access_key)
#   - Generic secrets (secret=value patterns)
#   - Private keys (-----BEGIN PRIVATE KEY-----)
#   - GitHub tokens (ghp_, gho_, etc.)
#   - Vercel tokens (vercel_token)
#   - Railway tokens (railway_token)
#
# REDACTION STRATEGY:
#   - Preserves variable names and structure
#   - Replaces values with: ***REDACTED***
#   - Keeps URLs readable but removes credentials
#   - Maintains JSON/YAML structure
#
# AUTHOR: Spec-Flow Security
# VERSION: 1.0.0

set -euo pipefail

# Color codes for terminal output (optional)
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Redaction marker
readonly REDACTED="***REDACTED***"

#
# sanitize_secrets - Main sanitization function
#
# Reads from stdin and writes sanitized output to stdout.
# Can be used in pipes or with process substitution.
#
sanitize_secrets() {
  local content

  # Read all input
  if [ -t 0 ]; then
    # If stdin is a terminal, read from arguments
    content="$*"
  else
    # If stdin is a pipe/file, read from stdin
    content=$(cat)
  fi

  # Apply sanitization patterns
  content=$(sanitize_api_keys "$content")
  content=$(sanitize_tokens "$content")
  content=$(sanitize_passwords "$content")
  content=$(sanitize_database_urls "$content")
  content=$(sanitize_urls_with_creds "$content")
  content=$(sanitize_jwt_tokens "$content")
  content=$(sanitize_aws_keys "$content")
  content=$(sanitize_github_tokens "$content")
  content=$(sanitize_deployment_tokens "$content")
  content=$(sanitize_private_keys "$content")
  content=$(sanitize_generic_secrets "$content")
  content=$(sanitize_env_vars "$content")

  echo "$content"
}

#
# sanitize_api_keys - Redact API key values
#
# Pattern: (api_key|apikey|api-key)[=:]\s*[^\s&"']+
# Examples:
#   api_key=abc123 → api_key=***REDACTED***
#   apikey: "xyz789" → apikey: "***REDACTED***"
#
sanitize_api_keys() {
  local content="$1"

  # Case-insensitive API key patterns
  # Note: sed -E doesn't support case-insensitive flag on all platforms, so we use multiple patterns
  content=$(echo "$content" | sed -E 's/(api[_-]?key|apikey|API[_-]?KEY|APIKEY)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_tokens - Redact bearer tokens and auth tokens
#
# Pattern: (token|bearer|auth_token)[=:]\s*[^\s&"']+
# Examples:
#   bearer token abc123 → bearer token ***REDACTED***
#   token: xyz789 → token: ***REDACTED***
#
sanitize_tokens() {
  local content="$1"

  # Token patterns
  content=$(echo "$content" | sed -E 's/(token|bearer|auth[_-]?token|TOKEN|BEARER|AUTH[_-]?TOKEN)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_passwords - Redact password values
#
# Pattern: (password|passwd|pwd)[=:]\s*[^\s&"']+
# Examples:
#   password=secret123 → password=***REDACTED***
#   pwd: "mypass" → pwd: "***REDACTED***"
#
sanitize_passwords() {
  local content="$1"

  # Password patterns
  content=$(echo "$content" | sed -E 's/(password|passwd|pwd|PASSWORD|PASSWD|PWD)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_database_urls - Redact credentials in database URLs
#
# Pattern: (postgresql|mysql|mongodb)://[^:]+:[^@]+@
# Examples:
#   postgresql://user:pass@host → postgresql://***:***@host
#   mysql://admin:secret@db → mysql://***:***@db
#
sanitize_database_urls() {
  local content="$1"

  # Database URL patterns (lowercase)
  content=$(echo "$content" | sed -E 's|(postgresql|mysql|mongodb|redis)://[^:]+:[^@]+@|\1://***:***@|g')

  # Database URL patterns (uppercase)
  content=$(echo "$content" | sed -E 's|(POSTGRESQL|MYSQL|MONGODB|REDIS)://[^:]+:[^@]+@|\1://***:***@|g')

  echo "$content"
}

#
# sanitize_urls_with_creds - Redact credentials in HTTP(S) URLs
#
# Pattern: https?://[^:]+:[^@]+@
# Examples:
#   https://user:pass@api.com → https://***:***@api.com
#
sanitize_urls_with_creds() {
  local content="$1"

  # HTTP(S) URL with credentials (case-insensitive for http/https)
  content=$(echo "$content" | sed -E 's|https?://[^:]+:[^@]+@|https://***:***@|g')
  content=$(echo "$content" | sed -E 's|HTTPS?://[^:]+:[^@]+@|HTTPS://***:***@|g')

  echo "$content"
}

#
# sanitize_jwt_tokens - Redact JWT tokens
#
# Pattern: eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+
# Examples:
#   eyJhbGc...xyz → ***REDACTED_JWT***
#
sanitize_jwt_tokens() {
  local content="$1"

  # JWT pattern (starts with eyJ)
  content=$(echo "$content" | sed -E 's/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/***REDACTED_JWT***/g')

  echo "$content"
}

#
# sanitize_aws_keys - Redact AWS access keys and secrets
#
# Pattern: (AKIA[0-9A-Z]{16}|aws_secret_access_key[=:][^\s]+)
# Examples:
#   AKIAIOSFODNN7EXAMPLE → ***REDACTED_AWS_KEY***
#   aws_secret_access_key=abc123 → aws_secret_access_key=***REDACTED***
#
sanitize_aws_keys() {
  local content="$1"

  # AWS access key ID (starts with AKIA)
  content=$(echo "$content" | sed -E 's/AKIA[0-9A-Z]{16}/***REDACTED_AWS_KEY***/g')

  # AWS secret access key
  content=$(echo "$content" | sed -E 's/(aws_secret_access_key|AWS_SECRET_ACCESS_KEY)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_github_tokens - Redact GitHub personal access tokens
#
# Pattern: gh[ps]_[A-Za-z0-9_]{36,255}
# Examples:
#   ghp_abc123xyz789... → ***REDACTED_GITHUB_TOKEN***
#   gho_xyz789abc123... → ***REDACTED_GITHUB_TOKEN***
#
sanitize_github_tokens() {
  local content="$1"

  # GitHub token patterns (ghp_, gho_, ghs_, etc.)
  content=$(echo "$content" | sed -E 's/gh[ps]_[A-Za-z0-9_]{36,255}/***REDACTED_GITHUB_TOKEN***/g')

  echo "$content"
}

#
# sanitize_deployment_tokens - Redact Vercel, Railway, and deployment tokens
#
# Pattern: (vercel_token|railway_token|deploy_token)[=:][^\s]+
# Examples:
#   vercel_token=abc123 → vercel_token=***REDACTED***
#   RAILWAY_TOKEN=xyz789 → RAILWAY_TOKEN=***REDACTED***
#
sanitize_deployment_tokens() {
  local content="$1"

  # Vercel tokens
  content=$(echo "$content" | sed -E 's/(vercel[_-]?token|VERCEL[_-]?TOKEN)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  # Railway tokens
  content=$(echo "$content" | sed -E 's/(railway[_-]?token|RAILWAY[_-]?TOKEN)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  # Generic deploy tokens
  content=$(echo "$content" | sed -E 's/(deploy[_-]?token|DEPLOY[_-]?TOKEN)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_private_keys - Redact private key content
#
# Pattern: -----BEGIN.*PRIVATE KEY-----.*-----END.*PRIVATE KEY-----
# Examples:
#   -----BEGIN PRIVATE KEY----- ... → ***REDACTED_PRIVATE_KEY***
#
sanitize_private_keys() {
  local content="$1"

  # Private key blocks
  content=$(echo "$content" | sed -E ':a;N;$!ba;s/-----BEGIN[^-]*PRIVATE KEY-----[^-]+-----END[^-]*PRIVATE KEY-----/***REDACTED_PRIVATE_KEY***/g')

  echo "$content"
}

#
# sanitize_generic_secrets - Redact generic secret patterns
#
# Pattern: (secret|key|credential)[=:][^\s&"']+
# Examples:
#   secret=abc123 → secret=***REDACTED***
#   api_secret: xyz789 → api_secret: ***REDACTED***
#
sanitize_generic_secrets() {
  local content="$1"

  # Generic secret patterns
  content=$(echo "$content" | sed -E 's/(secret|credential|SECRET|CREDENTIAL)([=:])[[:space:]]*["]?[^"&[:space:]]+["]?/\1\2'"$REDACTED"'/g')

  echo "$content"
}

#
# sanitize_env_vars - Redact environment variable values in command output
#
# Pattern: VAR_NAME=value (when value looks sensitive)
# Examples:
#   DATABASE_URL=postgresql://... → DATABASE_URL=***REDACTED***
#   OPENAI_API_KEY=sk-... → OPENAI_API_KEY=***REDACTED***
#
sanitize_env_vars() {
  local content="$1"

  # Specific sensitive env vars
  local sensitive_vars=(
    "DATABASE_URL"
    "DIRECT_URL"
    "OPENAI_API_KEY"
    "CLERK_SECRET_KEY"
    "HCAPTCHA_SECRET_KEY"
    "JWT_SECRET"
    "SECRET_KEY"
    "REDIS_URL"
    "DOPPLER_TOKEN"
    "GITHUB_TOKEN"
    "VERCEL_TOKEN"
    "RAILWAY_TOKEN"
  )

  for var in "${sensitive_vars[@]}"; do
    # Match VAR=value or VAR="value" or VAR: value (exact match, case-sensitive)
    content=$(echo "$content" | sed -E "s/(${var})([=:])[[:space:]]*[^[:space:]]+/\1\2$REDACTED/g")
  done

  echo "$content"
}

#
# Main execution when script is run directly (not sourced)
#
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly, not sourced
  sanitize_secrets "$@"
fi

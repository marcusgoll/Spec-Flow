#!/usr/bin/env bash
# detect-infrastructure-needs.sh
# Centralized detection for infrastructure command prompts
# Returns JSON with all detected needs

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$REPO_ROOT"

# ============================================================================
# DETECTION FUNCTIONS
# ============================================================================

# Detect if feature flags are needed (branch age >18h)
detect_flag_needed() {
  local result='{"needed": false, "reason": "", "branch_age_hours": 0, "slug": ""}'

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$result"
    return
  fi

  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  # Skip if on main/master
  if [[ "$current_branch" =~ ^(main|master)$ ]]; then
    echo "$result"
    return
  fi

  # Calculate branch age
  local base_commit=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null || echo "")

  if [ -z "$base_commit" ]; then
    echo "$result"
    return
  fi

  local base_timestamp=$(git log --format=%ct -1 "$base_commit" 2>/dev/null || echo "0")
  local current_timestamp=$(date +%s)
  local age_seconds=$((current_timestamp - base_timestamp))
  local age_hours=$((age_seconds / 3600))

  # Extract slug from current feature directory
  local feature_dir=$(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)
  local slug=""

  if [ -n "$feature_dir" ]; then
    slug=$(basename "$feature_dir" | sed 's/^[0-9]\{3\}-//')
  fi

  if [ $age_hours -ge 18 ]; then
    result=$(jq -n \
      --arg reason "Branch is ${age_hours}h old (24h limit approaching)" \
      --argjson hours "$age_hours" \
      --arg slug "$slug" \
      '{needed: true, reason: $reason, branch_age_hours: $hours, slug: $slug}')
  else
    result=$(jq -n \
      --argjson hours "$age_hours" \
      --arg slug "$slug" \
      '{needed: false, reason: "", branch_age_hours: $hours, slug: $slug}')
  fi

  echo "$result"
}

# Detect if API contract changes require contract bump
detect_contract_bump_needed() {
  local result='{"needed": false, "reason": "", "changed_files": []}'

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$result"
    return
  fi

  # Check for API-related file changes
  local api_patterns=(
    "openapi.yaml"
    "openapi.yml"
    "schema.graphql"
    "*.proto"
    "routes/"
    "controllers/"
    "api/"
    "handlers/"
  )

  local changed_files=()
  local base_branch="main"

  # Fallback to master if main doesn't exist
  if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
      base_branch="master"
    else
      echo "$result"
      return
    fi
  fi

  for pattern in "${api_patterns[@]}"; do
    while IFS= read -r file; do
      [ -n "$file" ] && changed_files+=("$file")
    done < <(git diff --name-only "$base_branch"... 2>/dev/null | grep -E "$pattern" || true)
  done

  if [ ${#changed_files[@]} -gt 0 ]; then
    local files_json=$(printf '%s\n' "${changed_files[@]}" | jq -R . | jq -s .)
    result=$(jq -n \
      --argjson files "$files_json" \
      --arg reason "${#changed_files[@]} API-related files modified" \
      '{needed: true, reason: $reason, changed_files: $files}')
  fi

  echo "$result"
}

# Detect if contract verification should run
detect_contract_verify_needed() {
  local result='{"needed": false, "reason": "", "pact_count": 0}'

  if [ ! -d "contracts/pacts" ]; then
    echo "$result"
    return
  fi

  local pact_count=$(find contracts/pacts -name '*.json' -type f 2>/dev/null | wc -l)

  if [ $pact_count -gt 0 ]; then
    result=$(jq -n \
      --argjson count "$pact_count" \
      --arg reason "$pact_count consumer contracts found" \
      '{needed: true, reason: $reason, pact_count: $count}')
  fi

  echo "$result"
}

# Detect if flag cleanup is needed
detect_flag_cleanup_needed() {
  local result='{"needed": false, "reason": "", "active_flags": []}'

  if [ ! -f ".spec-flow/memory/feature-flags.yaml" ]; then
    echo "$result"
    return
  fi

  # Extract active flags
  local active_flags=()
  while IFS= read -r flag; do
    [ -n "$flag" ] && active_flags+=("$flag")
  done < <(yq eval '.flags[] | select(.status == "active") | .name' .spec-flow/memory/feature-flags.yaml 2>/dev/null || true)

  if [ ${#active_flags[@]} -gt 0 ]; then
    local flags_json=$(printf '%s\n' "${active_flags[@]}" | jq -R . | jq -s .)
    result=$(jq -n \
      --argjson flags "$flags_json" \
      --arg reason "${#active_flags[@]} active feature flags found" \
      '{needed: true, reason: $reason, active_flags: $flags}')
  fi

  echo "$result"
}

# Detect if fixture refresh is needed
detect_fixture_refresh_needed() {
  local result='{"needed": false, "reason": "", "migration_files": []}'

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "$result"
    return
  fi

  # Check for migration file changes
  local migration_patterns=(
    "migrations/"
    "alembic/versions/"
    "prisma/migrations/"
    "db/migrate/"
  )

  local migration_files=()
  local base_branch="main"

  if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
      base_branch="master"
    else
      echo "$result"
      return
    fi
  fi

  for pattern in "${migration_patterns[@]}"; do
    while IFS= read -r file; do
      [ -n "$file" ] && migration_files+=("$file")
    done < <(git diff --name-only "$base_branch"... 2>/dev/null | grep -E "$pattern" || true)
  done

  if [ ${#migration_files[@]} -gt 0 ]; then
    local files_json=$(printf '%s\n' "${migration_files[@]}" | jq -R . | jq -s .)
    result=$(jq -n \
      --argjson files "$files_json" \
      --arg reason "${#migration_files[@]} database migration files modified" \
      '{needed: true, reason: $reason, migration_files: $files}')
  fi

  echo "$result"
}

# Detect flag count for roadmap summary
detect_flag_summary() {
  local result='{"total_flags": 0, "active_flags": 0, "expired_flags": 0}'

  if [ ! -f ".spec-flow/memory/feature-flags.yaml" ]; then
    echo "$result"
    return
  fi

  local total=$(yq eval '.flags | length' .spec-flow/memory/feature-flags.yaml 2>/dev/null || echo "0")
  local active=$(yq eval '.flags[] | select(.status == "active") | .name' .spec-flow/memory/feature-flags.yaml 2>/dev/null | wc -l)
  local expired=$(yq eval '.flags[] | select(.status == "expired") | .name' .spec-flow/memory/feature-flags.yaml 2>/dev/null | wc -l)

  result=$(jq -n \
    --argjson total "$total" \
    --argjson active "$active" \
    --argjson expired "$expired" \
    '{total_flags: $total, active_flags: $active, expired_flags: $expired}')

  echo "$result"
}

# Detect if API changes are planned (from spec.md)
detect_api_changes_planned() {
  local result='{"planned": false, "reason": ""}'

  # Find most recent feature directory
  local feature_dir=$(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

  if [ -z "$feature_dir" ] || [ ! -f "$feature_dir/spec.md" ]; then
    echo "$result"
    return
  fi

  # Check if spec mentions API changes
  if grep -qiE "(API endpoint|GraphQL|REST|gRPC|webhook|HTTP)" "$feature_dir/spec.md" 2>/dev/null; then
    result=$(jq -n \
      --arg reason "Feature spec mentions API modifications" \
      '{planned: true, reason: $reason}')
  fi

  echo "$result"
}

# ============================================================================
# MAIN OUTPUT
# ============================================================================

main() {
  local phase="${1:-all}"

  case "$phase" in
    flag-needed)
      detect_flag_needed
      ;;
    contract-bump)
      detect_contract_bump_needed
      ;;
    contract-verify)
      detect_contract_verify_needed
      ;;
    flag-cleanup)
      detect_flag_cleanup_needed
      ;;
    fixture-refresh)
      detect_fixture_refresh_needed
      ;;
    flag-summary)
      detect_flag_summary
      ;;
    api-changes-planned)
      detect_api_changes_planned
      ;;
    all)
      # Return all detections as single JSON object
      local flag_needed=$(detect_flag_needed)
      local contract_bump=$(detect_contract_bump_needed)
      local contract_verify=$(detect_contract_verify_needed)
      local flag_cleanup=$(detect_flag_cleanup_needed)
      local fixture_refresh=$(detect_fixture_refresh_needed)
      local flag_summary=$(detect_flag_summary)
      local api_planned=$(detect_api_changes_planned)

      jq -n \
        --argjson flag_needed "$flag_needed" \
        --argjson contract_bump "$contract_bump" \
        --argjson contract_verify "$contract_verify" \
        --argjson flag_cleanup "$flag_cleanup" \
        --argjson fixture_refresh "$fixture_refresh" \
        --argjson flag_summary "$flag_summary" \
        --argjson api_planned "$api_planned" \
        '{
          flag_needed: $flag_needed,
          contract_bump: $contract_bump,
          contract_verify: $contract_verify,
          flag_cleanup: $flag_cleanup,
          fixture_refresh: $fixture_refresh,
          flag_summary: $flag_summary,
          api_changes_planned: $api_planned
        }'
      ;;
    *)
      echo "Usage: detect-infrastructure-needs.sh [phase]" >&2
      echo "Phases: flag-needed, contract-bump, contract-verify, flag-cleanup, fixture-refresh, flag-summary, api-changes-planned, all" >&2
      exit 1
      ;;
  esac
}

main "$@"

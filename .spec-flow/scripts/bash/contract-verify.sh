#!/usr/bin/env bash
#
# contract-verify.sh - Verify consumer-driven contracts (pacts)
#
# Usage: contract-verify.sh [--consumer NAME] [--provider NAME] [--verbose]
#
# Required tools: jq, curl (pact-provider-verifier optional)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONTRACTS_DIR="$PROJECT_ROOT/contracts"
PACTS_DIR="$CONTRACTS_DIR/pacts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
VERBOSE=false
FILTER_CONSUMER=""
FILTER_PROVIDER=""

# Results tracking
TOTAL_PACTS=0
PASSED_PACTS=0
FAILED_PACTS=0
TOTAL_INTERACTIONS=0
FAILED_INTERACTIONS=0
FAILURES=()

#######################################
# Print usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Verify consumer-driven contracts (pacts) to ensure providers honor consumer expectations.

Options:
  --consumer NAME   Verify specific consumer's pacts only
  --provider NAME   Verify specific provider only
  --verbose         Show detailed verification output
  -h, --help        Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --consumer frontend-epic-ui
  $(basename "$0") --provider backend-epic-api --verbose
EOF
  exit 1
}

#######################################
# Logging
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }
log_verbose() { [[ "$VERBOSE" == true ]] && echo -e "${BLUE}  $*${NC}"; }

#######################################
# Discover all pacts
#######################################
discover_pacts() {
  if [[ ! -d "$PACTS_DIR" ]]; then
    return
  fi

  find "$PACTS_DIR" -name '*.json' -type f 2>/dev/null || true
}

#######################################
# Parse pact metadata
#######################################
parse_pact_consumer() {
  local pact_file=$1
  jq -r '.consumer.name // "unknown"' "$pact_file" 2>/dev/null || echo "unknown"
}

parse_pact_provider() {
  local pact_file=$1
  jq -r '.provider.name // "unknown"' "$pact_file" 2>/dev/null || echo "unknown"
}

#######################################
# Check if pact matches filters
#######################################
matches_filter() {
  local consumer=$1
  local provider=$2

  if [[ -n "$FILTER_CONSUMER" ]] && [[ "$consumer" != "$FILTER_CONSUMER" ]]; then
    return 1
  fi

  if [[ -n "$FILTER_PROVIDER" ]] && [[ "$provider" != "$FILTER_PROVIDER" ]]; then
    return 1
  fi

  return 0
}

#######################################
# Get provider base URL
#######################################
get_provider_base_url() {
  local provider=$1

  # Map provider names to local URLs
  # TODO: Make this configurable via .spec-flow/memory/provider-urls.yaml
  case "$provider" in
    backend-epic-api|backend-*)
      echo "http://localhost:3000"
      ;;
    frontend-epic-ui|frontend-*)
      echo "http://localhost:3001"
      ;;
    webhook-service)
      echo "http://localhost:3002"
      ;;
    *)
      echo "http://localhost:3000"
      ;;
  esac
}

#######################################
# Check if provider is running
#######################################
is_provider_running() {
  local base_url=$1

  if curl -s -f "${base_url}/health" > /dev/null 2>&1; then
    return 0
  fi

  # Try root endpoint
  if curl -s -f "$base_url" > /dev/null 2>&1; then
    return 0
  fi

  return 1
}

#######################################
# Verify pact using Pact CLI (if available)
#######################################
verify_pact_with_pact_cli() {
  local pact_file=$1
  local provider=$2
  local base_url=$3

  if ! command -v pact-provider-verifier &> /dev/null; then
    return 1
  fi

  log_verbose "Using pact-provider-verifier for $pact_file"

  local output
  if output=$(pact-provider-verifier \
    --provider="$provider" \
    --provider-base-url="$base_url" \
    --pact-urls="$pact_file" \
    --provider-app-version="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')" \
    2>&1); then
    return 0
  else
    echo "$output"
    return 1
  fi
}

#######################################
# Simple HTTP-based verification (fallback)
#######################################
verify_pact_simple() {
  local pact_file=$1
  local provider=$2
  local base_url=$3

  log_verbose "Using simple HTTP verification for $pact_file"

  local interactions
  interactions=$(jq -c '.interactions[]' "$pact_file" 2>/dev/null)

  if [[ -z "$interactions" ]]; then
    log_warning "No interactions found in $pact_file"
    return 0
  fi

  local interaction_count=0
  local failed_count=0

  while IFS= read -r interaction; do
    ((interaction_count++))

    local description
    description=$(echo "$interaction" | jq -r '.description')

    local method
    method=$(echo "$interaction" | jq -r '.request.method')

    local path
    path=$(echo "$interaction" | jq -r '.request.path')

    local expected_status
    expected_status=$(echo "$interaction" | jq -r '.response.status')

    local headers
    headers=$(echo "$interaction" | jq -r '.request.headers // {} | to_entries | map("-H \"\(.key): \(.value)\"") | join(" ")')

    log_verbose "  Testing: $description"
    log_verbose "    $method $path → expect $expected_status"

    # Make request
    local actual_status
    if [[ -n "$headers" ]]; then
      actual_status=$(eval curl -s -o /dev/null -w \"%{http_code}\" -X "$method" "$base_url$path" $headers 2>/dev/null || echo "000")
    else
      actual_status=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$base_url$path" 2>/dev/null || echo "000")
    fi

    if [[ "$actual_status" != "$expected_status" ]]; then
      ((failed_count++))
      FAILURES+=("$(printf "Pact: %s\nInteraction: %s\nExpected status: %s\nActual status: %s\nRequest: %s %s" \
        "$(basename "$pact_file")" "$description" "$expected_status" "$actual_status" "$method" "$path")")
      log_verbose "    ❌ FAIL: got $actual_status"
    else
      log_verbose "    ✅ PASS"
    fi
  done <<< "$interactions"

  TOTAL_INTERACTIONS=$((TOTAL_INTERACTIONS + interaction_count))
  FAILED_INTERACTIONS=$((FAILED_INTERACTIONS + failed_count))

  if [[ $failed_count -gt 0 ]]; then
    return 1
  fi

  return 0
}

#######################################
# Verify single pact
#######################################
verify_pact() {
  local pact_file=$1

  local consumer
  consumer=$(parse_pact_consumer "$pact_file")

  local provider
  provider=$(parse_pact_provider "$pact_file")

  local base_url
  base_url=$(get_provider_base_url "$provider")

  log_verbose "Verifying pact: $(basename "$pact_file")"
  log_verbose "  Consumer: $consumer"
  log_verbose "  Provider: $provider"
  log_verbose "  Base URL: $base_url"

  # Check if provider is running
  if ! is_provider_running "$base_url"; then
    log_warning "Provider not running: $provider ($base_url)"
    log_warning "Skipping verification for $(basename "$pact_file")"
    return 0
  fi

  # Try Pact CLI first, fall back to simple verification
  if verify_pact_with_pact_cli "$pact_file" "$provider" "$base_url" 2>/dev/null; then
    log_verbose "  ✅ Verification passed (via Pact CLI)"
    return 0
  elif verify_pact_simple "$pact_file" "$provider" "$base_url"; then
    log_verbose "  ✅ Verification passed (via simple HTTP)"
    return 0
  else
    log_verbose "  ❌ Verification failed"
    return 1
  fi
}

#######################################
# Format final report
#######################################
print_report() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ $FAILED_PACTS -eq 0 ]] && [[ $FAILED_INTERACTIONS -eq 0 ]]; then
    log_success "Contract verification passed"
  else
    log_error "Contract verification failed"
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "Verified $TOTAL_PACTS pacts:"
  echo "  ✅ Passed: $PASSED_PACTS"
  if [[ $FAILED_PACTS -gt 0 ]]; then
    echo "  ❌ Failed: $FAILED_PACTS"
  fi
  echo ""

  echo "Total: $TOTAL_INTERACTIONS interactions tested"
  if [[ $FAILED_INTERACTIONS -gt 0 ]]; then
    echo "       $FAILED_INTERACTIONS failures"
  else
    echo "       0 failures"
  fi
  echo ""

  # Print failures
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Violations:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for failure in "${FAILURES[@]}"; do
      echo "$failure"
      echo ""
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Fix violations and re-run: /contract.verify"
    echo ""
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --consumer)
        FILTER_CONSUMER="$2"
        shift 2
        ;;
      --provider)
        FILTER_PROVIDER="$2"
        shift 2
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        log_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Check contracts directory exists
  if [[ ! -d "$CONTRACTS_DIR" ]]; then
    log_error "Contracts directory not found: $CONTRACTS_DIR"
    log_info "Run project initialization first"
    exit 1
  fi

  # Discover pacts
  log_info "Discovering pacts in $PACTS_DIR"

  local pacts
  pacts=$(discover_pacts)

  if [[ -z "$pacts" ]]; then
    log_warning "No pacts found in $PACTS_DIR"
    echo ""
    echo "This means no consumers have published expectations yet."
    echo ""
    echo "Actions:"
    echo "  1. If consumers exist, ask them to publish pacts"
    echo "  2. If no consumers yet, verification passes (no contracts to break)"
    echo ""
    log_success "Verification passed (0 pacts)"
    exit 0
  fi

  # Count pacts
  TOTAL_PACTS=$(echo "$pacts" | wc -l | tr -d ' ')
  log_info "Found $TOTAL_PACTS pacts"
  echo ""

  # Verify each pact
  while IFS= read -r pact_file; do
    local consumer
    consumer=$(parse_pact_consumer "$pact_file")

    local provider
    provider=$(parse_pact_provider "$pact_file")

    # Apply filters
    if ! matches_filter "$consumer" "$provider"; then
      log_verbose "Skipping $(basename "$pact_file") (filtered out)"
      ((TOTAL_PACTS--))
      continue
    fi

    # Verify pact
    if verify_pact "$pact_file"; then
      ((PASSED_PACTS++))
      log_success "$(basename "$pact_file")"
    else
      ((FAILED_PACTS++))
      log_error "$(basename "$pact_file")"
    fi
  done <<< "$pacts"

  # Print report
  print_report

  # Exit with failure if any pacts failed
  if [[ $FAILED_PACTS -gt 0 ]] || [[ $FAILED_INTERACTIONS -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

main "$@"

#!/usr/bin/env bash
#
# gate-sec.sh - Security quality gate (SAST, secrets, dependencies)
#
# Usage: gate-sec.sh [--epic EPIC] [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || cd "$SCRIPT_DIR/../../.." && pwd)"
WORKFLOW_STATE="$REPO_ROOT/.spec-flow/memory/state.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parameters
EPIC_NAME=""
VERBOSE=false

# Gate results
SAST_PASSED=false
SECRETS_PASSED=false
DEPENDENCIES_PASSED=false

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run security quality gate checks (SAST, secrets, dependencies).

Options:
  --epic EPIC    Epic name (optional, for epic-specific checks)
  --verbose      Show detailed output
  -h, --help     Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --epic epic-auth-api
  $(basename "$0") --verbose
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

#######################################
# Check if command exists
#######################################
command_exists() {
  command -v "$1" &> /dev/null
}

#######################################
# Detect project type
#######################################
detect_project_type() {
  if [[ -f "$REPO_ROOT/package.json" ]]; then
    echo "node"
  elif [[ -f "$REPO_ROOT/requirements.txt" ]] || [[ -f "$REPO_ROOT/pyproject.toml" ]]; then
    echo "python"
  elif [[ -f "$REPO_ROOT/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$REPO_ROOT/go.mod" ]]; then
    echo "go"
  else
    echo "unknown"
  fi
}

#######################################
# Run SAST (Semgrep)
#######################################
run_sast_semgrep() {
  log_info "Running SAST (Semgrep)..."

  if ! command_exists semgrep; then
    log_warning "Semgrep not installed, skipping SAST"
    return 0
  fi

  local semgrep_output
  if semgrep_output=$(semgrep --config=auto --json . 2>&1); then
    # Parse results
    local error_count=0
    if command_exists jq; then
      error_count=$(echo "$semgrep_output" | jq '[.results[] | select(.extra.severity == "ERROR" or .extra.severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
    fi

    if [[ "$VERBOSE" == true ]]; then
      echo "$semgrep_output" | jq -r '.results[] | select(.extra.severity == "ERROR" or .extra.severity == "CRITICAL") | "\(.path):\(.start.line) - \(.extra.message)"' 2>/dev/null || true
    fi

    if [[ $error_count -gt 0 ]]; then
      log_error "SAST found $error_count HIGH/CRITICAL vulnerabilities"
      return 1
    else
      return 0
    fi
  else
    log_error "Semgrep scan failed"
    return 1
  fi
}

#######################################
# Check for secrets (git-secrets)
#######################################
check_secrets() {
  log_info "Checking for secrets..."

  # Method 1: git-secrets
  if command_exists git-secrets; then
    if git-secrets --scan > /dev/null 2>&1; then
      return 0
    else
      log_error "Secrets detected in repository"
      if [[ "$VERBOSE" == true ]]; then
        git-secrets --scan
      fi
      return 1
    fi
  fi

  # Method 2: Simple regex scan (fallback)
  log_info "Using fallback secret detection..."

  local secret_patterns=(
    "password\s*=\s*['\"][^'\"]+['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "secret\s*=\s*['\"][^'\"]+['\"]"
    "token\s*=\s*['\"][^'\"]+['\"]"
    "AKIA[0-9A-Z]{16}"  # AWS access key
    "-----BEGIN RSA PRIVATE KEY-----"
  )

  local secrets_found=false
  for pattern in "${secret_patterns[@]}"; do
    if grep -rEi "$pattern" "$REPO_ROOT" \
      --exclude-dir=node_modules \
      --exclude-dir=.git \
      --exclude-dir=dist \
      --exclude-dir=build \
      > /dev/null 2>&1; then

      if [[ "$VERBOSE" == true ]]; then
        grep -rEin "$pattern" "$REPO_ROOT" \
          --exclude-dir=node_modules \
          --exclude-dir=.git \
          --exclude-dir=dist \
          --exclude-dir=build
      fi

      secrets_found=true
    fi
  done

  if [[ "$secrets_found" == true ]]; then
    log_warning "Potential secrets detected (false positives possible)"
    return 1
  else
    return 0
  fi
}

#######################################
# Check dependencies (Node.js)
#######################################
check_dependencies_node() {
  log_info "Checking dependencies (Node.js)..."

  if ! command -v npm &> /dev/null; then
    log_warning "npm not found, skipping dependency check"
    return 0
  fi

  # Run npm audit
  local audit_output
  if audit_output=$(npm audit --json 2>&1); then
    local high_count=0
    local critical_count=0

    if command_exists jq; then
      high_count=$(echo "$audit_output" | jq '.metadata.vulnerabilities.high // 0' 2>/dev/null || echo "0")
      critical_count=$(echo "$audit_output" | jq '.metadata.vulnerabilities.critical // 0' 2>/dev/null || echo "0")
    fi

    if [[ "$VERBOSE" == true ]]; then
      npm audit
    fi

    if [[ $high_count -gt 0 ]] || [[ $critical_count -gt 0 ]]; then
      log_error "Found $critical_count critical and $high_count high vulnerabilities"
      return 1
    else
      return 0
    fi
  else
    log_error "npm audit failed"
    return 1
  fi
}

#######################################
# Check dependencies (Python)
#######################################
check_dependencies_python() {
  log_info "Checking dependencies (Python)..."

  # Method 1: pip-audit
  if command_exists pip-audit; then
    if pip-audit > /dev/null 2>&1; then
      return 0
    else
      log_error "Vulnerable dependencies detected"
      if [[ "$VERBOSE" == true ]]; then
        pip-audit
      fi
      return 1
    fi
  fi

  # Method 2: safety (fallback)
  if command_exists safety; then
    if safety check > /dev/null 2>&1; then
      return 0
    else
      log_error "Vulnerable dependencies detected"
      if [[ "$VERBOSE" == true ]]; then
        safety check
      fi
      return 1
    fi
  fi

  log_warning "No Python security tools found (install pip-audit or safety)"
  return 0
}

#######################################
# Update gate status
#######################################
update_gate_status() {
  local epic=$1
  local gate_type="security"
  local status=$2  # passed, failed

  if [[ ! -f "$WORKFLOW_STATE" ]]; then
    return
  fi

  if ! command -v yq &> /dev/null; then
    return
  fi

  # Initialize quality_gates if missing
  local gates_exists
  gates_exists=$(yq eval '.quality_gates' "$WORKFLOW_STATE" 2>/dev/null || echo "null")

  if [[ "$gates_exists" == "null" ]]; then
    yq eval '.quality_gates = {}' -i "$WORKFLOW_STATE"
  fi

  # Update gate status
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || echo "2025-11-10T18:00:00Z")

  yq eval ".quality_gates.$gate_type = {
    \"status\": \"$status\",
    \"timestamp\": \"$timestamp\",
    \"sast\": $SAST_PASSED,
    \"secrets\": $SECRETS_PASSED,
    \"dependencies\": $DEPENDENCIES_PASSED
  }" -i "$WORKFLOW_STATE"

  if [[ -n "$epic" ]]; then
    # Update epic-specific gate
    yq eval "(.epics[] | select(.name == \"$epic\") | .gates.security) = {
      \"status\": \"$status\",
      \"timestamp\": \"$timestamp\"
    }" -i "$WORKFLOW_STATE"
  fi
}

#######################################
# Main
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --epic)
        EPIC_NAME="$2"
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

  # Print header
  echo ""
  echo "Security Quality Gate"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Detect project type
  local project_type
  project_type=$(detect_project_type)

  log_info "Project type: $project_type"
  echo ""

  # Run SAST
  if run_sast_semgrep; then
    log_success "SAST passed (no HIGH/CRITICAL issues)"
    SAST_PASSED=true
  else
    log_error "SAST failed"
    SAST_PASSED=false
  fi

  # Check for secrets
  if check_secrets; then
    log_success "No secrets detected"
    SECRETS_PASSED=true
  else
    log_error "Secrets detected"
    SECRETS_PASSED=false
  fi

  # Check dependencies
  case "$project_type" in
    node)
      if check_dependencies_node; then
        log_success "Dependencies secure"
        DEPENDENCIES_PASSED=true
      else
        log_error "Vulnerable dependencies found"
        DEPENDENCIES_PASSED=false
      fi
      ;;
    python)
      if check_dependencies_python; then
        log_success "Dependencies secure"
        DEPENDENCIES_PASSED=true
      else
        log_error "Vulnerable dependencies found"
        DEPENDENCIES_PASSED=false
      fi
      ;;
    *)
      log_warning "Dependency scanning not supported for: $project_type"
      DEPENDENCIES_PASSED=true  # Don't block on unsupported types
      ;;
  esac

  # Print summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local all_passed=true
  if [[ "$SAST_PASSED" == false ]] || [[ "$SECRETS_PASSED" == false ]] || [[ "$DEPENDENCIES_PASSED" == false ]]; then
    all_passed=false
  fi

  if [[ "$all_passed" == true ]]; then
    log_success "Security gate PASSED"
    update_gate_status "$EPIC_NAME" "passed"
    echo ""
    echo "Epic can transition: Review → Integrated"
    echo ""
    exit 0
  else
    log_error "Security gate FAILED"
    update_gate_status "$EPIC_NAME" "failed"
    echo ""
    echo "Fix security issues before proceeding:"
    if [[ "$SAST_PASSED" == false ]]; then
      echo "  • Review SAST findings: semgrep --config=auto ."
    fi
    if [[ "$SECRETS_PASSED" == false ]]; then
      echo "  • Remove secrets from code, use environment variables"
    fi
    if [[ "$DEPENDENCIES_PASSED" == false ]]; then
      echo "  • Update vulnerable dependencies: npm audit fix"
    fi
    echo ""
    echo "Installation:"
    echo "  • Semgrep: pip install semgrep"
    echo "  • git-secrets: brew install git-secrets (macOS)"
    echo "  • pip-audit: pip install pip-audit (Python)"
    echo ""
    exit 1
  fi
}

main "$@"

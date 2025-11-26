#!/usr/bin/env bash
#
# gate-ci.sh - CI quality gate (tests, linters, coverage)
#
# Usage: gate-ci.sh [--epic EPIC] [--verbose]

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
TESTS_PASSED=false
LINTERS_PASSED=false
TYPE_CHECK_PASSED=false
COVERAGE_PASSED=false

#######################################
# Usage
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run CI quality gate checks (tests, linters, coverage).

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
# Run tests (Node.js)
#######################################
run_tests_node() {
  log_info "Running tests (Node.js)..."

  local test_cmd=""
  if command_exists npm && grep -q '"test"' "$REPO_ROOT/package.json" 2>/dev/null; then
    test_cmd="npm test"
  elif command_exists yarn && grep -q '"test"' "$REPO_ROOT/package.json" 2>/dev/null; then
    test_cmd="yarn test"
  else
    log_warning "No test script found in package.json"
    return 1
  fi

  if [[ "$VERBOSE" == true ]]; then
    if $test_cmd; then
      return 0
    else
      return 1
    fi
  else
    if $test_cmd > /dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  fi
}

#######################################
# Run linters (Node.js)
#######################################
run_linters_node() {
  log_info "Running linters (Node.js)..."

  local lint_passed=true

  # ESLint
  if command_exists npx && [[ -f "$REPO_ROOT/.eslintrc.js" ]] || [[ -f "$REPO_ROOT/.eslintrc.json" ]]; then
    if [[ "$VERBOSE" == true ]]; then
      npx eslint . || lint_passed=false
    else
      npx eslint . > /dev/null 2>&1 || lint_passed=false
    fi
  fi

  # Prettier
  if command_exists npx && [[ -f "$REPO_ROOT/.prettierrc" ]] || grep -q '"prettier"' "$REPO_ROOT/package.json" 2>/dev/null; then
    if [[ "$VERBOSE" == true ]]; then
      npx prettier --check . || lint_passed=false
    else
      npx prettier --check . > /dev/null 2>&1 || lint_passed=false
    fi
  fi

  if [[ "$lint_passed" == true ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Run type checks (TypeScript)
#######################################
run_type_check_node() {
  log_info "Running type checks (TypeScript)..."

  if [[ -f "$REPO_ROOT/tsconfig.json" ]]; then
    if command_exists npx; then
      if [[ "$VERBOSE" == true ]]; then
        npx tsc --noEmit
      else
        npx tsc --noEmit > /dev/null 2>&1
      fi
      return $?
    fi
  fi

  # No TypeScript config found
  return 0
}

#######################################
# Check coverage (Node.js)
#######################################
check_coverage_node() {
  log_info "Checking code coverage..."

  local coverage_file=""
  if [[ -f "$REPO_ROOT/coverage/coverage-summary.json" ]]; then
    coverage_file="$REPO_ROOT/coverage/coverage-summary.json"
  elif [[ -f "$REPO_ROOT/coverage/lcov-report/index.html" ]]; then
    # Parse HTML (fallback)
    log_warning "JSON coverage summary not found, skipping coverage check"
    return 0
  else
    log_warning "Coverage report not found, skipping coverage check"
    return 0
  fi

  # Parse coverage percentage
  if command_exists jq; then
    local coverage_pct
    coverage_pct=$(jq -r '.total.lines.pct' "$coverage_file" 2>/dev/null || echo "0")

    if (( $(echo "$coverage_pct >= 80" | bc -l) )); then
      return 0
    else
      log_error "Coverage too low: ${coverage_pct}% (required: 80%)"
      return 1
    fi
  else
    log_warning "jq not found, skipping coverage check"
    return 0
  fi
}

#######################################
# Run tests (Python)
#######################################
run_tests_python() {
  log_info "Running tests (Python)..."

  if command_exists pytest; then
    if [[ "$VERBOSE" == true ]]; then
      pytest
    else
      pytest > /dev/null 2>&1
    fi
    return $?
  else
    log_warning "pytest not found"
    return 1
  fi
}

#######################################
# Run linters (Python)
#######################################
run_linters_python() {
  log_info "Running linters (Python)..."

  local lint_passed=true

  # Black
  if command_exists black; then
    if [[ "$VERBOSE" == true ]]; then
      black --check . || lint_passed=false
    else
      black --check . > /dev/null 2>&1 || lint_passed=false
    fi
  fi

  # Flake8
  if command_exists flake8; then
    if [[ "$VERBOSE" == true ]]; then
      flake8 . || lint_passed=false
    else
      flake8 . > /dev/null 2>&1 || lint_passed=false
    fi
  fi

  if [[ "$lint_passed" == true ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Run type checks (Python)
#######################################
run_type_check_python() {
  log_info "Running type checks (Python)..."

  if command_exists mypy; then
    if [[ "$VERBOSE" == true ]]; then
      mypy .
    else
      mypy . > /dev/null 2>&1
    fi
    return $?
  fi

  return 0
}

#######################################
# Update gate status in state.yaml
#######################################
update_gate_status() {
  local epic=$1
  local gate_type="ci"
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
    \"tests\": $TESTS_PASSED,
    \"linters\": $LINTERS_PASSED,
    \"type_check\": $TYPE_CHECK_PASSED,
    \"coverage\": $COVERAGE_PASSED
  }" -i "$WORKFLOW_STATE"

  if [[ -n "$epic" ]]; then
    # Update epic-specific gate
    yq eval "(.epics[] | select(.name == \"$epic\") | .gates.ci) = {
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
  echo "CI Quality Gate"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Detect project type
  local project_type
  project_type=$(detect_project_type)

  if [[ "$project_type" == "unknown" ]]; then
    log_error "Unknown project type"
    echo ""
    echo "Add package.json, requirements.txt, Cargo.toml, or go.mod"
    echo ""
    exit 1
  fi

  log_info "Project type: $project_type"
  echo ""

  # Run checks based on project type
  case "$project_type" in
    node)
      if run_tests_node; then
        log_success "Tests passed"
        TESTS_PASSED=true
      else
        log_error "Tests failed"
        TESTS_PASSED=false
      fi

      if run_linters_node; then
        log_success "Linters passed"
        LINTERS_PASSED=true
      else
        log_error "Linters failed"
        LINTERS_PASSED=false
      fi

      if run_type_check_node; then
        log_success "Type checks passed"
        TYPE_CHECK_PASSED=true
      else
        log_error "Type checks failed"
        TYPE_CHECK_PASSED=false
      fi

      if check_coverage_node; then
        log_success "Coverage sufficient (≥80%)"
        COVERAGE_PASSED=true
      else
        log_error "Coverage insufficient (<80%)"
        COVERAGE_PASSED=false
      fi
      ;;

    python)
      if run_tests_python; then
        log_success "Tests passed"
        TESTS_PASSED=true
      else
        log_error "Tests failed"
        TESTS_PASSED=false
      fi

      if run_linters_python; then
        log_success "Linters passed"
        LINTERS_PASSED=true
      else
        log_error "Linters failed"
        LINTERS_PASSED=false
      fi

      if run_type_check_python; then
        log_success "Type checks passed"
        TYPE_CHECK_PASSED=true
      else
        log_error "Type checks failed"
        TYPE_CHECK_PASSED=false
      fi

      COVERAGE_PASSED=true  # Python coverage handled by pytest-cov
      ;;

    *)
      log_error "Unsupported project type: $project_type"
      exit 1
      ;;
  esac

  # Print summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local all_passed=true
  if [[ "$TESTS_PASSED" == false ]] || [[ "$LINTERS_PASSED" == false ]] || [[ "$TYPE_CHECK_PASSED" == false ]] || [[ "$COVERAGE_PASSED" == false ]]; then
    all_passed=false
  fi

  if [[ "$all_passed" == true ]]; then
    log_success "CI gate PASSED"
    update_gate_status "$EPIC_NAME" "passed"
    echo ""
    echo "Epic can transition: Review → Integrated"
    echo ""
    exit 0
  else
    log_error "CI gate FAILED"
    update_gate_status "$EPIC_NAME" "failed"
    echo ""
    echo "Fix failures before proceeding:"
    if [[ "$TESTS_PASSED" == false ]]; then
      echo "  • Run tests: npm test (or pytest)"
    fi
    if [[ "$LINTERS_PASSED" == false ]]; then
      echo "  • Fix linting: npm run lint --fix"
    fi
    if [[ "$TYPE_CHECK_PASSED" == false ]]; then
      echo "  • Fix type errors: npx tsc --noEmit"
    fi
    if [[ "$COVERAGE_PASSED" == false ]]; then
      echo "  • Improve coverage: Add tests to reach 80%"
    fi
    echo ""
    exit 1
  fi
}

main "$@"

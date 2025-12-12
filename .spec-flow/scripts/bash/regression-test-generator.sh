#!/usr/bin/env bash
# Regression Test Generator
# Generates regression tests when bugs are discovered
# Used by /debug command and continuous-checks.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
ERROR_ID=""
TITLE=""
SYMPTOMS=""
ROOT_CAUSE=""
COMPONENT=""
FEATURE_DIR="."
SUGGEST_ONLY=false
OUTPUT_FILE=""
FAILED_TESTS=""

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Help text
show_help() {
  cat << EOF
Regression Test Generator

Usage: regression-test-generator.sh [OPTIONS]

Options:
  --error-id ID        Error ID (e.g., ERR-0042)
  --title TEXT         Error title
  --symptoms TEXT      Bug symptoms/description
  --root-cause TEXT    Root cause of the bug
  --component PATH     Affected component (file:function)
  --feature-dir PATH   Feature directory (default: current)
  --suggest-only       Only generate suggestions, don't create files
  --failed-tests FILE  File containing failed test output
  --output FILE        Output file for suggestions (YAML)
  -h, --help           Show this help

Examples:
  # Generate regression test during /debug
  regression-test-generator.sh \\
    --error-id "ERR-0042" \\
    --title "Dashboard Timeout" \\
    --symptoms "Dashboard fails to load after 30s" \\
    --root-cause "Missing pagination parameter" \\
    --component "src/services/StudentProgressService.ts:fetchData" \\
    --feature-dir "specs/001-dashboard"

  # Generate suggestions from failed tests (continuous checks)
  regression-test-generator.sh \\
    --suggest-only \\
    --failed-tests "test-results.log" \\
    --output ".regression-suggestions.yaml"
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --error-id)
      ERROR_ID="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --symptoms)
      SYMPTOMS="$2"
      shift 2
      ;;
    --root-cause)
      ROOT_CAUSE="$2"
      shift 2
      ;;
    --component)
      COMPONENT="$2"
      shift 2
      ;;
    --feature-dir)
      FEATURE_DIR="$2"
      shift 2
      ;;
    --suggest-only)
      SUGGEST_ONLY=true
      shift
      ;;
    --failed-tests)
      FAILED_TESTS="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Detect test framework
detect_framework() {
  local framework="unknown"
  local extension=".test.ts"

  # Check docs/project/tech-stack.md
  if [ -f "docs/project/tech-stack.md" ]; then
    if grep -qi "vitest" docs/project/tech-stack.md; then
      framework="vitest"
      extension=".test.ts"
    elif grep -qi "jest" docs/project/tech-stack.md; then
      framework="jest"
      extension=".test.ts"
    elif grep -qi "pytest" docs/project/tech-stack.md; then
      framework="pytest"
      extension="_test.py"
    elif grep -qi "playwright" docs/project/tech-stack.md; then
      framework="playwright"
      extension=".spec.ts"
    fi
  fi

  # Fallback: Check package.json
  if [ "$framework" = "unknown" ] && [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json; then
      framework="vitest"
      extension=".test.ts"
    elif grep -q '"jest"' package.json; then
      framework="jest"
      extension=".test.ts"
    elif grep -q '"@playwright/test"' package.json; then
      framework="playwright"
      extension=".spec.ts"
    fi
  fi

  # Fallback: Check pyproject.toml or requirements.txt
  if [ "$framework" = "unknown" ]; then
    if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml; then
      framework="pytest"
      extension="_test.py"
    elif [ -f "requirements.txt" ] && grep -q "pytest" requirements.txt; then
      framework="pytest"
      extension="_test.py"
    fi
  fi

  # Fallback: Check existing test files
  if [ "$framework" = "unknown" ]; then
    if find . -name "*.test.ts" -o -name "*.test.tsx" 2>/dev/null | head -1 | grep -q .; then
      framework="jest"  # or vitest, they share format
      extension=".test.ts"
    elif find . -name "*_test.py" -o -name "test_*.py" 2>/dev/null | head -1 | grep -q .; then
      framework="pytest"
      extension="_test.py"
    fi
  fi

  # Default fallback
  if [ "$framework" = "unknown" ]; then
    if [ -f "package.json" ]; then
      framework="jest"
      extension=".test.ts"
    else
      framework="pytest"
      extension="_test.py"
    fi
  fi

  echo "$framework:$extension"
}

# Determine test file location
get_test_location() {
  local framework="$1"
  local error_id="$2"
  local title="$3"

  # Create slug from title
  local slug
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

  local test_dir=""
  local filename=""

  # Determine directory
  if [ -d "tests/regression" ]; then
    test_dir="tests/regression"
  elif [ -d "tests" ]; then
    test_dir="tests/regression"
  elif [ -d "__tests__" ]; then
    test_dir="__tests__/regression"
  elif [ -d "e2e" ] && [ "$framework" = "playwright" ]; then
    test_dir="e2e/regression"
  else
    test_dir="tests/regression"
  fi

  # Determine filename based on framework
  case $framework in
    jest|vitest)
      filename="regression-${error_id}-${slug}.test.ts"
      ;;
    pytest)
      local py_error_id
      py_error_id=$(echo "$error_id" | tr '-' '_' | tr '[:upper:]' '[:lower:]')
      local py_slug
      py_slug=$(echo "$slug" | tr '-' '_')
      filename="test_regression_${py_error_id}_${py_slug}.py"
      ;;
    playwright)
      filename="regression-${error_id}-${slug}.spec.ts"
      ;;
    *)
      filename="regression-${error_id}-${slug}.test.ts"
      ;;
  esac

  echo "${test_dir}/${filename}"
}

# Generate test content based on framework
generate_test_content() {
  local framework="$1"
  local error_id="$2"
  local title="$3"
  local symptoms="$4"
  local root_cause="$5"
  local component="$6"
  local error_log_path="$7"

  local date_fixed
  date_fixed=$(date +%Y-%m-%d)

  # Extract short title (first 3-4 words)
  local title_short
  title_short=$(echo "$title" | cut -d' ' -f1-4)

  case $framework in
    jest|vitest)
      cat << EOF
/**
 * Regression Test for ${error_id}: ${title}
 *
 * Bug: ${symptoms}
 * Date Fixed: ${date_fixed}
 * Root Cause: ${root_cause}
 *
 * This test reproduces the bug scenario to prevent regression.
 * If this test fails, the bug from ${error_id} may have been reintroduced.
 *
 * @see ${error_log_path}#${error_id}
 */
import { describe, test, expect, beforeEach } from 'vitest'; // or '@jest/globals'

describe('Regression: ${error_id} - ${title_short}', () => {
  beforeEach(() => {
    // Setup: Initialize test state
  });

  test('should [EXPECTED_BEHAVIOR] when [CONDITION]', async () => {
    // ===== ARRANGE =====
    // Set up the bug scenario
    // TODO: Add setup code based on reproduction steps

    // ===== ACT =====
    // Execute the action that caused the bug
    // TODO: Add action code

    // ===== ASSERT =====
    // Verify correct behavior (would have failed before fix)
    // TODO: Add specific assertions
    expect(true).toBe(true); // Replace with actual assertion
  });

  // Additional edge case tests can be added here
});
EOF
      ;;
    pytest)
      local py_error_id
      py_error_id=$(echo "$error_id" | tr '-' '' | tr '[:lower:]' '[:upper:]')
      cat << EOF
"""
Regression Test for ${error_id}: ${title}

Bug: ${symptoms}
Date Fixed: ${date_fixed}
Root Cause: ${root_cause}

This test reproduces the bug scenario to prevent regression.
If this test fails, the bug from ${error_id} may have been reintroduced.

See: ${error_log_path}#${error_id}
"""
import pytest


class TestRegression${py_error_id}:
    """Regression tests for ${error_id}: ${title_short}"""

    @pytest.fixture
    def setup(self):
        """Setup fixture for regression tests"""
        # TODO: Add setup code
        pass

    def test_expected_behavior_when_condition(self, setup):
        """Verify [EXPECTED_BEHAVIOR] when [CONDITION]

        This test would have failed before the fix was applied.
        Root cause: ${root_cause}
        """
        # ===== ARRANGE =====
        # Set up the bug scenario
        # TODO: Add setup code based on reproduction steps

        # ===== ACT =====
        # Execute the action that caused the bug
        # TODO: Add action code

        # ===== ASSERT =====
        # Verify correct behavior (would have failed before fix)
        # TODO: Add specific assertions
        assert True  # Replace with actual assertion

    # Additional edge case tests can be added here
EOF
      ;;
    playwright)
      cat << EOF
/**
 * Regression Test for ${error_id}: ${title}
 *
 * Bug: ${symptoms}
 * Date Fixed: ${date_fixed}
 * Root Cause: ${root_cause}
 *
 * This E2E test reproduces the user flow that triggered the bug.
 *
 * @see ${error_log_path}#${error_id}
 */
import { test, expect } from '@playwright/test';

test.describe('Regression: ${error_id} - ${title_short}', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Navigate to starting point
    // TODO: Add navigation/login steps
  });

  test('should [EXPECTED_BEHAVIOR] when [CONDITION]', async ({ page }) => {
    // ===== ARRANGE =====
    // Set up the bug scenario
    // TODO: Add setup code

    // ===== ACT =====
    // Execute the action that caused the bug
    // TODO: Add user actions using accessible selectors
    // await page.getByRole('button', { name: 'Action' }).click();

    // ===== ASSERT =====
    // Verify correct behavior (would have failed before fix)
    // TODO: Add specific assertions
    // await expect(page.getByTestId('result')).toBeVisible();
  });

  // Additional edge case tests can be added here
});
EOF
      ;;
    *)
      log_error "Unknown framework: $framework"
      exit 1
      ;;
  esac
}

# Generate suggestions from failed tests
generate_suggestions() {
  local failed_tests_file="$1"
  local output_file="$2"

  if [ ! -f "$failed_tests_file" ]; then
    log_error "Failed tests file not found: $failed_tests_file"
    exit 1
  fi

  log_info "Analyzing failed tests..."

  # Extract failed test info
  local failed_count=0
  local suggestions=""

  # Parse test failures (basic patterns for Jest/pytest)
  while IFS= read -r line; do
    if echo "$line" | grep -qE "(FAIL|FAILED|Error|AssertionError)"; then
      ((failed_count++))

      # Extract test name and file
      local test_name=""
      local test_file=""

      if echo "$line" | grep -qE "FAIL.*\.test\.(ts|js|tsx|jsx)"; then
        test_file=$(echo "$line" | grep -oE "[^ ]+\.test\.(ts|js|tsx|jsx)" | head -1)
        test_name=$(echo "$line" | sed 's/.*FAIL//' | xargs)
      elif echo "$line" | grep -qE "FAILED.*test_.*\.py"; then
        test_file=$(echo "$line" | grep -oE "test_[^ ]+\.py" | head -1)
        test_name=$(echo "$line" | sed 's/.*FAILED//' | xargs)
      fi

      if [ -n "$test_file" ]; then
        suggestions="${suggestions}
  - test_file: \"${test_file}\"
    test_name: \"${test_name}\"
    suggested_regression_test: true
    reason: \"Test failure detected during continuous checks\""
      fi
    fi
  done < "$failed_tests_file"

  # Write YAML output
  cat > "$output_file" << EOF
# Regression Test Suggestions
# Generated: $(date -Iseconds)
# Source: ${failed_tests_file}

summary:
  total_failures: ${failed_count}
  suggestions_generated: ${failed_count}

suggestions:${suggestions:-"
  # No test failures detected"}

# To generate regression tests for these suggestions:
# regression-test-generator.sh --error-id "ERR-XXXX" --title "..." --symptoms "..." --root-cause "..."
EOF

  log_success "Suggestions written to: $output_file"
  echo "Found $failed_count test failures"
}

# Main execution
main() {
  # Suggest-only mode (for continuous checks)
  if [ "$SUGGEST_ONLY" = true ]; then
    if [ -z "$FAILED_TESTS" ] || [ -z "$OUTPUT_FILE" ]; then
      log_error "Suggest mode requires --failed-tests and --output"
      exit 1
    fi
    generate_suggestions "$FAILED_TESTS" "$OUTPUT_FILE"
    exit 0
  fi

  # Full generation mode (for /debug)
  if [ -z "$ERROR_ID" ] || [ -z "$TITLE" ]; then
    log_error "Required: --error-id and --title"
    show_help
    exit 1
  fi

  log_info "Generating regression test for ${ERROR_ID}..."

  # Detect framework
  local framework_info
  framework_info=$(detect_framework)
  local framework
  framework=$(echo "$framework_info" | cut -d: -f1)
  log_info "Detected framework: ${framework}"

  # Determine test location
  local error_log_path="${FEATURE_DIR}/error-log.md"
  local test_path
  test_path=$(get_test_location "$framework" "$ERROR_ID" "$TITLE")
  log_info "Test location: ${test_path}"

  # Create directory if needed
  local test_dir
  test_dir=$(dirname "$test_path")
  if [ ! -d "$test_dir" ]; then
    mkdir -p "$test_dir"
    log_info "Created directory: ${test_dir}"
  fi

  # Generate test content
  local test_content
  test_content=$(generate_test_content "$framework" "$ERROR_ID" "$TITLE" "$SYMPTOMS" "$ROOT_CAUSE" "$COMPONENT" "$error_log_path")

  # Display for user review
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo -e "${CYAN}Regression Test Generated${NC}"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo -e "${BLUE}Error:${NC} ${ERROR_ID} - ${TITLE}"
  echo -e "${BLUE}File:${NC}  ${test_path}"
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo -e "${YELLOW}Generated Test Code:${NC}"
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "$test_content"
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo ""
  echo "This test will:"
  echo "  - Capture the bug scenario from ${ERROR_ID}"
  echo "  - Fail before the fix is applied (proves bug exists)"
  echo "  - Pass after the fix (validates the solution)"
  echo "  - Prevent regression of this bug in the future"
  echo ""

  # Output metadata for Claude to use
  echo "---METADATA---"
  echo "TEST_PATH=${test_path}"
  echo "FRAMEWORK=${framework}"
  echo "ERROR_ID=${ERROR_ID}"
  echo "ERROR_LOG_PATH=${error_log_path}"
  echo "---END_METADATA---"

  # Write test file
  echo "$test_content" > "$test_path"
  log_success "Test file written: ${test_path}"

  # Stage for git (don't commit)
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git add "$test_path" 2>/dev/null || true
    log_info "Test file staged for commit"
  fi

  exit 0
}

main "$@"

#!/usr/bin/env bash
# Lightweight continuous quality checks during /implement phase
# Runs after each batch of 3-4 tasks to catch issues early

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BATCH_NUM=1
FEATURE_DIR="."
TIMEOUT=30
SKIP_CONDITIONS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --batch-num)
      BATCH_NUM=$2
      shift 2
      ;;
    --feature-dir)
      FEATURE_DIR=$2
      shift 2
      ;;
    --timeout)
      TIMEOUT=$2
      shift 2
      ;;
    --skip-conditions)
      SKIP_CONDITIONS=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Check skip conditions
check_skip_conditions() {
  if [ "$SKIP_CONDITIONS" = true ]; then
    return 0  # Don't skip
  fi

  # Skip if batch is too small (< 3 tasks)
  # This would need to be passed in or detected somehow
  # For now, we'll always run

  # Skip if in iteration 2+ (focus on gaps only)
  if [ -f "$FEATURE_DIR/state.yaml" ]; then
    local iteration=$(yq eval '.iteration.current' "$FEATURE_DIR/state.yaml" 2>/dev/null || echo "1")
    if [ "$iteration" -gt 1 ]; then
      log_warning "Skipping continuous checks (iteration $iteration - focusing on gap fixes)"
      return 1
    fi
  fi

  return 0
}

# Main execution
main() {
  echo ""
  log_info "🔍 Running continuous quality checks (batch $BATCH_NUM)..."
  echo ""

  # Check skip conditions
  if ! check_skip_conditions; then
    exit 0
  fi

  local start_time=$(date +%s)
  local checks_failed=0
  local checks_passed=0
  local checks_skipped=0

  # Create results directory
  mkdir -p "$FEATURE_DIR/.continuous-checks"
  local result_file="$FEATURE_DIR/.continuous-checks/batch-$BATCH_NUM.log"
  : > "$result_file"

  # 1. Get changed files since last check
  log_info "Detecting changed files..."
  local changed_files=""

  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Get files changed in last commit
    changed_files=$(git diff --name-only HEAD~1 2>/dev/null || echo "")

    if [ -z "$changed_files" ]; then
      # If no changes in last commit, get uncommitted changes
      changed_files=$(git diff --name-only 2>/dev/null || echo "")
    fi

    if [ -n "$changed_files" ]; then
      local file_count=$(echo "$changed_files" | wc -l | tr -d ' ')
      log_info "  Found $file_count changed files"
      echo "$changed_files" | sed 's/^/    /' | head -10
      [ "$file_count" -gt 10 ] && echo "    ... and $((file_count - 10)) more"
    else
      log_warning "  No changed files detected"
    fi
  else
    log_warning "  Not a git repository, skipping file detection"
  fi

  echo "" >> "$result_file"
  echo "=== Continuous Quality Check - Batch $BATCH_NUM ===" >> "$result_file"
  echo "Timestamp: $(date -Iseconds)" >> "$result_file"
  echo "Changed files: $file_count" >> "$result_file"
  echo "" >> "$result_file"

  # 2. Run linting (with auto-fix)
  log_info "Check 1/5: Linting (auto-fix enabled)..."

  local lint_failed=0

  # Frontend linting
  if [ -d "apps" ] && command -v pnpm >/dev/null 2>&1; then
    if pnpm --filter @app lint --fix 2>&1 | tee -a "$result_file"; then
      log_success "  Frontend linting passed"
      ((checks_passed++))
    else
      log_error "  Frontend linting failed"
      ((checks_failed++))
      lint_failed=1
    fi
  else
    log_warning "  Frontend linting skipped (no pnpm or apps/ directory)"
    ((checks_skipped++))
  fi

  # Backend linting
  if [ -d "api" ] && command -v ruff >/dev/null 2>&1; then
    cd api
    if ruff check . --fix 2>&1 | tee -a "$result_file"; then
      log_success "  Backend linting passed"
      ((checks_passed++))
    else
      log_error "  Backend linting failed"
      ((checks_failed++))
      lint_failed=1
    fi
    cd - >/dev/null
  else
    log_warning "  Backend linting skipped (no ruff or api/ directory)"
    ((checks_skipped++))
  fi

  echo "" >> "$result_file"

  # 3. Type checking (quick mode - changed files only)
  log_info "Check 2/5: Type checking (quick mode)..."

  local type_failed=0

  # TypeScript type checking
  if [ -f "tsconfig.json" ] || [ -f "apps/tsconfig.json" ]; then
    if command -v pnpm >/dev/null 2>&1; then
      if pnpm --filter @app type-check 2>&1 | tee -a "$result_file"; then
        log_success "  TypeScript type checking passed"
        ((checks_passed++))
      else
        log_error "  TypeScript type checking failed"
        ((checks_failed++))
        type_failed=1
      fi
    else
      log_warning "  TypeScript type checking skipped (no pnpm)"
      ((checks_skipped++))
    fi
  fi

  # Python type checking
  if [ -d "api" ] && command -v mypy >/dev/null 2>&1; then
    cd api
    if mypy app/ --incremental 2>&1 | tee -a "$result_file"; then
      log_success "  Python type checking passed"
      ((checks_passed++))
    else
      log_error "  Python type checking failed"
      ((checks_failed++))
      type_failed=1
    fi
    cd - >/dev/null
  else
    log_warning "  Python type checking skipped (no mypy or api/ directory)"
    ((checks_skipped++))
  fi

  echo "" >> "$result_file"

  # 4. Run unit tests for changed files
  log_info "Check 3/5: Unit tests (changed files only)..."

  local test_failed=0

  # Frontend tests
  if [ -d "apps" ] && command -v pnpm >/dev/null 2>&1; then
    if [ -n "$changed_files" ]; then
      # Extract frontend files
      local frontend_files=$(echo "$changed_files" | grep "^apps/" || echo "")

      if [ -n "$frontend_files" ]; then
        if pnpm --filter @app test --findRelatedTests $frontend_files 2>&1 | tee -a "$result_file"; then
          log_success "  Frontend tests passed"
          ((checks_passed++))
        else
          log_error "  Frontend tests failed"
          ((checks_failed++))
          test_failed=1
        fi
      else
        log_info "  No frontend files changed, skipping tests"
        ((checks_skipped++))
      fi
    else
      log_warning "  No changed files detected, skipping frontend tests"
      ((checks_skipped++))
    fi
  else
    log_warning "  Frontend tests skipped (no pnpm or apps/ directory)"
    ((checks_skipped++))
  fi

  # Backend tests
  if [ -d "api" ] && command -v pytest >/dev/null 2>&1; then
    cd api
    if [ -n "$changed_files" ]; then
      # Extract backend files
      local backend_files=$(echo "$changed_files" | grep "^api/" || echo "")

      if [ -n "$backend_files" ]; then
        # Map source files to test files
        local test_files=""
        for file in $backend_files; do
          local test_file="${file//app\//tests\/}"
          test_file="${test_file//\.py/_test.py}"
          [ -f "$test_file" ] && test_files="$test_files $test_file"
        done

        if [ -n "$test_files" ]; then
          if pytest $test_files -v 2>&1 | tee -a "$result_file"; then
            log_success "  Backend tests passed"
            ((checks_passed++))
          else
            log_error "  Backend tests failed"
            ((checks_failed++))
            test_failed=1
          fi
        else
          log_info "  No test files found for changed backend files"
          ((checks_skipped++))
        fi
      else
        log_info "  No backend files changed, skipping tests"
        ((checks_skipped++))
      fi
    else
      log_warning "  No changed files detected, skipping backend tests"
      ((checks_skipped++))
    fi
    cd - >/dev/null
  else
    log_warning "  Backend tests skipped (no pytest or api/ directory)"
    ((checks_skipped++))
  fi

  echo "" >> "$result_file"

  # 5. Check coverage delta
  log_info "Check 4/5: Coverage delta check..."

  local baseline_file="$FEATURE_DIR/.baseline-coverage"
  local current_cov=0
  local baseline_cov=0

  # Get current coverage
  if [ -d "apps" ] && command -v pnpm >/dev/null 2>&1; then
    # Frontend coverage
    if pnpm --filter @app test --coverage --silent 2>&1 | tee -a "$result_file"; then
      current_cov=$(grep -oP "All files\s+\|\s+\K\d+" coverage/coverage-summary.txt 2>/dev/null || echo "0")
    fi
  fi

  # Load baseline coverage
  if [ -f "$baseline_file" ]; then
    baseline_cov=$(cat "$baseline_file")
  else
    # First run, save current as baseline
    echo "$current_cov" > "$baseline_file"
    baseline_cov=$current_cov
  fi

  if [ "$current_cov" -lt "$baseline_cov" ]; then
    log_warning "  Coverage dropped: $baseline_cov% → $current_cov%"
    log_warning "  Consider adding tests for new code"
    ((checks_failed++))
  else
    log_success "  Coverage maintained: $baseline_cov% → $current_cov%"
    ((checks_passed++))
    # Update baseline
    echo "$current_cov" > "$baseline_file"
  fi

  echo "Coverage: $current_cov% (baseline: $baseline_cov%)" >> "$result_file"
  echo "" >> "$result_file"

  # 6. Detect potential gaps early (before validation)
  log_info "Check 5/6: Early gap detection..."

  # Check for:
  # - TODO comments added
  # - Edge cases mentioned in code comments
  # - Error handling for new error types
  # - Placeholder implementations

  if command -v python3 >/dev/null 2>&1 && [ -f ".spec-flow/scripts/python/early-gap-detector.py" ]; then
    if [ -n "$changed_files" ]; then
      local gap_output_file="$FEATURE_DIR/.potential-gaps.yaml"

      # Run gap detector
      python3 .spec-flow/scripts/python/early-gap-detector.py \
        --changed-files $changed_files \
        --output "$gap_output_file" \
        --min-confidence 0.7 \
        2>&1 | tee -a "$result_file" || true

      if [ -f "$gap_output_file" ]; then
        local gap_count=$(yq eval '.summary.total_gaps' "$gap_output_file" 2>/dev/null || echo "0")

        if [ "$gap_count" -gt 0 ]; then
          log_warning "  Potential gaps detected: $gap_count"
          log_info "  Review at validation or run /ship-staging --capture-gaps"
          echo "  Details: $gap_output_file"

          # Show high-confidence gaps
          local high_conf=$(yq eval '.summary.high_confidence' "$gap_output_file" 2>/dev/null || echo "0")
          if [ "$high_conf" -gt 0 ]; then
            echo "  High confidence gaps: $high_conf (these likely need fixes)"
          fi

          # Non-blocking, just informational
          ((checks_passed++))
        else
          log_success "  No potential gaps detected"
          ((checks_passed++))
        fi
      else
        log_warning "  Gap detection completed but no output file"
        ((checks_skipped++))
      fi
    else
      log_info "  No changed files to scan for gaps"
      ((checks_skipped++))
    fi
  else
    log_warning "  Python 3 or early-gap-detector.py not available"
    ((checks_skipped++))
  fi

  echo "" >> "$result_file"

  # 6. Dead code detection (new unused exports)
  log_info "Check 6/7: Dead code detection..."

  local dead_code_failed=0

  # TypeScript dead code
  if [ -d "apps" ] && command -v npx >/dev/null 2>&1; then
    if command -v ts-prune >/dev/null 2>&1 || npx ts-prune --version >/dev/null 2>&1; then
      local dead_code=$(npx ts-prune 2>&1 | grep -v "used in module" || echo "")

      if [ -n "$dead_code" ]; then
        local count=$(echo "$dead_code" | wc -l | tr -d ' ')
        log_warning "  Found $count unused exports"
        echo "$dead_code" | head -5 | sed 's/^/    /'
        ((checks_failed++))
        dead_code_failed=1
      else
        log_success "  No unused exports detected"
        ((checks_passed++))
      fi
    else
      log_warning "  ts-prune not available, skipping dead code detection"
      ((checks_skipped++))
    fi
  else
    log_warning "  Dead code detection skipped (no npx or apps/ directory)"
    ((checks_skipped++))
  fi

  echo "" >> "$result_file"

  # 7. Auto-invoke /debug on test failures (generates regression tests)
  log_info "Check 7/7: Auto-debug on test failures..."

  if [ $test_failed -eq 1 ]; then
    log_warning "  Test failures detected - auto-invoking /debug"

    # Determine component type from failed tests
    local component="backend"
    if echo "$changed_files" | grep -q "^apps/\|\.tsx\|\.jsx"; then
      component="frontend"
    fi

    # Extract feature slug from feature dir
    local feature_slug
    feature_slug=$(basename "$FEATURE_DIR" 2>/dev/null || echo "unknown")

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${YELLOW}Auto-invoking /debug to generate regression tests${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Feature: $feature_slug"
    echo "Component: $component"
    echo "Test failures detected in batch $BATCH_NUM"
    echo ""

    # Generate regression test suggestions first
    local regression_script=".spec-flow/scripts/bash/regression-test-generator.sh"

    if [ -f "$regression_script" ]; then
      local suggestions_file="$FEATURE_DIR/.regression-suggestions.yaml"

      # Run suggestion generator
      bash "$regression_script" \
        --suggest-only \
        --failed-tests "$result_file" \
        --output "$suggestions_file" \
        2>&1 | tee -a "$result_file" || true

      if [ -f "$suggestions_file" ]; then
        log_info "  Regression test suggestions saved to: $suggestions_file"
      fi
    fi

    # Signal to parent that /debug should be invoked
    # (The actual /debug invocation happens at the orchestrator level)
    echo ""
    echo "REGRESSION_TEST_TRIGGER=true" >> "$result_file"
    echo "FEATURE_SLUG=$feature_slug" >> "$result_file"
    echo "COMPONENT=$component" >> "$result_file"
    echo ""
    log_info "  /debug will be auto-invoked by orchestrator"
    log_info "  This will generate regression tests for the failures"

    # Non-blocking - orchestrator handles /debug invocation
    ((checks_passed++))
  else
    log_success "  No test failures - auto-debug skipped"
    ((checks_passed++))
  fi

  echo "" >> "$result_file"

  # Summary
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo ""
  echo "─────────────────────────────────────────"
  echo ""
  log_info "Summary for batch $BATCH_NUM:"
  echo "  ✅ Passed: $checks_passed"
  echo "  ❌ Failed: $checks_failed"
  echo "  ⊘ Skipped: $checks_skipped"
  echo "  ⏱️  Duration: ${duration}s (target: <${TIMEOUT}s)"
  echo ""

  # Write summary to result file
  echo "=== Summary ===" >> "$result_file"
  echo "Passed: $checks_passed" >> "$result_file"
  echo "Failed: $checks_failed" >> "$result_file"
  echo "Skipped: $checks_skipped" >> "$result_file"
  echo "Duration: ${duration}s" >> "$result_file"

  if [ $duration -gt $TIMEOUT ]; then
    log_warning "Continuous checks exceeded timeout (${duration}s > ${TIMEOUT}s)"
  fi

  if [ $checks_failed -gt 0 ]; then
    echo ""
    log_error "Continuous checks failed ($checks_failed failures)"
    echo ""
    echo "Options:"
    echo "  1. Fix issues now and continue"
    echo "  2. Continue anyway (not recommended)"
    echo "  3. Abort batch"
    echo ""
    exit 1
  else
    log_success "✅ Continuous checks passed (batch $BATCH_NUM)"
    exit 0
  fi
}

# Run main function
main "$@"

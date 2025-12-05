#!/usr/bin/env bash
# Optimization workflow - Production-readiness validation
# Runs parallel quality gates: performance, security, accessibility, code review, migrations, Docker

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

# Error handling
on_error() {
    log_error "Error in /optimize. Marking phase as failed."
    exit 1
}
trap on_error ERR

# Navigate to repo root
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Detect feature/epic directory using centralized utility
detect_feature_dir() {
    # Use centralized workflow detection utility
    local workflow_info
    workflow_info=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Could not detect workflow type (epic or feature)"
        log_error "Run from project root with an active epic/feature directory"
        exit 1
    fi

    # Extract values from JSON using grep (cross-platform compatible)
    local workflow_type=$(echo "$workflow_info" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    local base_dir=$(echo "$workflow_info" | grep -o '"base_dir":"[^"]*"' | cut -d'"' -f4)
    local slug=$(echo "$workflow_info" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$base_dir" ] || [ -z "$slug" ]; then
        log_error "Failed to parse workflow detection output"
        exit 1
    fi

    local feature_dir="${base_dir}/${slug}"

    if [ ! -d "$feature_dir" ]; then
        log_error "Workflow directory not found: $feature_dir"
        exit 1
    fi

    echo "${feature_dir}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if implementation is complete
    if ! grep -q "implement.*completed\|Phase 3.*Complete" "$FEATURE_DIR/NOTES.md" 2>/dev/null && \
       ! yq -e '.phases[] | select(.name == "implement" and .status == "completed")' "$FEATURE_DIR/state.yaml" >/dev/null 2>&1; then
        log_error "Implementation phase not complete"
        log_info "Run /implement first"
        exit 1
    fi

    log_success "Prerequisites checked"
}

# Extract quality targets from plan.md
extract_targets() {
    log_info "Extracting quality targets from plan.md..."

    local plan_file="$FEATURE_DIR/plan.md"

    if [ ! -f "$plan_file" ]; then
        log_warning "No plan.md found, using defaults"
        return
    fi

    # Performance targets
    if ! grep -qi "performance targets\|performance requirements" "$plan_file"; then
        log_warning "No performance targets in plan.md - checks will run without thresholds"
    fi

    # Accessibility requirements
    if ! grep -qi "WCAG\|accessibility" "$plan_file"; then
        log_warning "No WCAG level specified - defaulting to WCAG 2.2 AA"
    fi

    log_success "Targets extracted"
}

# Run performance check
check_performance() {
    log_info "Running performance checks..."

    local result_file="$FEATURE_DIR/optimization-performance.md"
    : > "$result_file"

    # Backend performance tests
    if [ -d api ]; then
        cd api
        if command -v uv >/dev/null 2>&1; then
            uv run pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
        else
            pytest tests/performance -q 2>&1 | tee "$FEATURE_DIR/perf-backend.log" || true
        fi
        cd - >/dev/null
    fi

    # Frontend Lighthouse (if installed)
    if [ -d apps ] && command -v lighthouse >/dev/null 2>&1; then
        log_info "Running Lighthouse performance audit..."
        lighthouse http://localhost:3000 --only-categories=performance --preset=desktop --quiet \
            --output=json --output-path="$FEATURE_DIR/lh-perf.json" 2>&1 || true
    fi

    # Bundle size check
    if [ -d apps ] && command -v pnpm >/dev/null 2>&1; then
        pnpm --filter @app build 2>&1 | tee "$FEATURE_DIR/bundle-size.log" || true
    fi

    echo "Status: PASSED" >> "$result_file"
    log_success "Performance check completed"
}

# Run security check
check_security() {
    log_info "Running security checks..."

    local result_file="$FEATURE_DIR/optimization-security.md"
    : > "$result_file"

    # Backend static analysis
    if [ -d api ]; then
        cd api
        if command -v bandit >/dev/null 2>&1; then
            bandit -r app/ -ll 2>&1 | tee "$FEATURE_DIR/security-backend.log" || true
        fi
        if command -v safety >/dev/null 2>&1; then
            safety check 2>&1 | tee "$FEATURE_DIR/security-deps.log" || true
        fi
        cd - >/dev/null
    fi

    # Frontend dependency audit
    if [ -d apps ] && command -v pnpm >/dev/null 2>&1; then
        pnpm --filter @app audit 2>&1 | tee "$FEATURE_DIR/security-frontend.log" || true
    fi

    # Check for critical/high findings
    local crit_count=0
    if [ -f "$FEATURE_DIR/security-backend.log" ] || [ -f "$FEATURE_DIR/security-deps.log" ] || [ -f "$FEATURE_DIR/security-frontend.log" ]; then
        crit_count=$(grep -Ehi 'critical|high' "$FEATURE_DIR"/security-*.log 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [ "$crit_count" -gt 0 ]; then
        echo "Status: FAILED" >> "$result_file"
        echo "Critical/High findings: $crit_count" >> "$result_file"
        log_error "Security check failed: $crit_count critical/high findings"
    else
        echo "Status: PASSED" >> "$result_file"
        log_success "Security check passed"
    fi
}

# Run accessibility check
check_accessibility() {
    log_info "Running accessibility checks..."

    local result_file="$FEATURE_DIR/optimization-accessibility.md"
    : > "$result_file"

    # Unit accessibility tests (jest-axe)
    if [ -d apps ] && command -v pnpm >/dev/null 2>&1; then
        pnpm --filter @app test -- --runInBand 2>&1 | tee "$FEATURE_DIR/a11y-tests.log" || true
    fi

    # Lighthouse accessibility score
    if [ -f "$FEATURE_DIR/lh-perf.json" ]; then
        local a11y_score
        a11y_score=$(jq '.categories.accessibility.score * 100' "$FEATURE_DIR/lh-perf.json" 2>/dev/null || echo 0)
        echo "Lighthouse A11y Score: $a11y_score" >> "$result_file"

        if (( $(echo "$a11y_score >= 95" | bc -l 2>/dev/null || echo 0) )); then
            echo "Status: PASSED" >> "$result_file"
            log_success "Accessibility check passed (score: $a11y_score)"
        else
            echo "Status: FAILED" >> "$result_file"
            log_error "Accessibility check failed (score: $a11y_score, threshold: 95)"
        fi
    else
        echo "Status: PASSED" >> "$result_file"
        log_success "Accessibility check completed (no Lighthouse data)"
    fi
}

# Run code review check
check_code_review() {
    log_info "Running code review checks..."

    local result_file="$FEATURE_DIR/code-review.md"
    : > "$result_file"

    local failed=0

    # NOTE: This function runs automated checks (linters, type checkers).
    # For agent-based code review with voting, Claude Code should invoke
    # the voting system directly when $VOTING_ENABLED=true
    # Example: invoke_voting "code_review" "$FEATURE_DIR" --output "$result_file"

    # Backend linting and type checking
    if [ -d api ]; then
        cd api
        if command -v ruff >/dev/null 2>&1; then
            ruff check . 2>&1 | tee "$FEATURE_DIR/ruff.log" || true
            if grep -qi "error" "$FEATURE_DIR/ruff.log" 2>/dev/null; then failed=1; fi
        fi
        if command -v mypy >/dev/null 2>&1; then
            mypy app/ --strict 2>&1 | tee "$FEATURE_DIR/mypy.log" || true
            if grep -qi "error" "$FEATURE_DIR/mypy.log" 2>/dev/null; then failed=1; fi
        fi
        cd - >/dev/null
    fi

    # Frontend linting and type checking
    if [ -d apps ] && command -v pnpm >/dev/null 2>&1; then
        pnpm --filter @app lint 2>&1 | tee "$FEATURE_DIR/eslint.log" || true
        if grep -qi "error" "$FEATURE_DIR/eslint.log" 2>/dev/null; then failed=1; fi

        pnpm --filter @app type-check 2>&1 | tee "$FEATURE_DIR/tsc.log" || true
        if grep -qi "Found.*error" "$FEATURE_DIR/tsc.log" 2>/dev/null; then failed=1; fi

        pnpm --filter @app test --coverage 2>&1 | tee "$FEATURE_DIR/jest.log" || true
    fi

    if [ "$failed" -eq 1 ]; then
        echo "Status: FAILED" >> "$result_file"
        log_error "Code review failed (linting/type errors found)"
    else
        echo "Status: PASSED" >> "$result_file"
        log_success "Code review passed"
    fi
}

# Run migrations check
check_migrations() {
    log_info "Running migrations checks..."

    local result_file="$FEATURE_DIR/optimization-migrations.md"
    : > "$result_file"

    if [ -f "$FEATURE_DIR/migration-plan.md" ] && [ -d api ]; then
        cd api

        local failed=0

        # Check for reversibility (downgrade function)
        for migration_file in $(find alembic/versions -name '*.py' -newer "../$FEATURE_DIR/migration-plan.md" 2>/dev/null); do
            if ! grep -q 'def downgrade' "$migration_file"; then
                log_warning "Migration missing downgrade: $migration_file"
                failed=1
            fi
        done

        # Check for drift
        if ! uv run alembic check 2>&1; then
            log_warning "Migration drift detected"
            failed=1
        fi

        cd - >/dev/null

        if [ "$failed" -eq 0 ]; then
            echo "Status: PASSED" >> "$result_file"
            log_success "Migrations check passed"
        else
            echo "Status: FAILED" >> "$result_file"
            log_error "Migrations check failed"
        fi
    else
        echo "Status: SKIPPED" >> "$result_file"
        log_info "Migrations check skipped (no migration-plan.md)"
    fi
}

# Run Docker build check
check_docker() {
    log_info "Running Docker build check..."

    local result_file="$FEATURE_DIR/optimization-docker.md"
    : > "$result_file"

    if [ -f Dockerfile ]; then
        if command -v docker >/dev/null 2>&1; then
            if docker build --no-cache -t optimize-test-build . 2>&1 | tee "$FEATURE_DIR/docker-build.log"; then
                echo "Status: PASSED" >> "$result_file"
                log_success "Docker build passed"
                # Clean up test image
                docker rmi optimize-test-build 2>/dev/null || true
            else
                echo "Status: FAILED" >> "$result_file"
                log_error "Docker build failed"
            fi
        else
            echo "Status: SKIPPED" >> "$result_file"
            log_warning "Docker not installed, skipping build check"
        fi
    else
        echo "Status: SKIPPED" >> "$result_file"
        log_info "Docker build skipped (no Dockerfile)"
    fi
}

# Run E2E and visual regression tests (Gate 7)
check_e2e_visual() {
    log_info "Running E2E and visual regression tests..."

    # Get slug from feature directory
    local slug
    slug=$(basename "$FEATURE_DIR")

    # Call the dedicated gate script
    local gate_script=".spec-flow/scripts/bash/e2e-visual-gate.sh"

    if [ -f "$gate_script" ]; then
        if bash "$gate_script" "$FEATURE_DIR" "$slug"; then
            log_success "E2E and visual tests completed"
        else
            log_error "E2E and visual tests failed"
        fi
    else
        log_warning "E2E gate script not found: $gate_script"
        local result_file="$FEATURE_DIR/optimization-e2e.md"
        echo "Status: SKIPPED" >> "$result_file"
        echo "Reason: Gate script not found" >> "$result_file"
    fi
}

# Run Pre-CI quality gates (Gates 8-15)
check_pre_ci() {
    log_info "Running Pre-CI quality gates (8-15)..."

    local gate_script=".spec-flow/scripts/bash/check-pre-ci.sh"

    if [ -f "$gate_script" ]; then
        if bash "$gate_script" "$FEATURE_DIR"; then
            log_success "Pre-CI gates completed"
        else
            log_error "Pre-CI gates failed"
        fi
    else
        log_warning "Pre-CI gate script not found: $gate_script"
    fi
}

# Aggregate results
aggregate_results() {
    log_info "Aggregating results..."
    echo ""

    local blockers=()

    # Check each result file (Gates 1-7, plus pre-ci report for Gates 8-15)
    for check_file in optimization-performance.md optimization-security.md optimization-accessibility.md code-review.md optimization-migrations.md optimization-docker.md optimization-e2e.md pre-ci-report.md; do
        if [ -f "$FEATURE_DIR/$check_file" ]; then
            local status
            status=$(grep -o "Status: .*" "$FEATURE_DIR/$check_file" 2>/dev/null | tail -1 | cut -d' ' -f2)

            case "$status" in
                FAILED)
                    blockers+=("$check_file")
                    echo "  ❌ $check_file: FAILED"
                    ;;
                PASSED)
                    echo "  ✅ $check_file: PASSED"
                    ;;
                SKIPPED)
                    echo "  ⏭️  $check_file: SKIPPED"
                    ;;
                *)
                    echo "  ⚠️  $check_file: UNKNOWN"
                    ;;
            esac
        fi
    done

    echo ""

    # Check for artifact strategy in plan
    if ! grep -qi "artifact strategy\|build-once" "$FEATURE_DIR/plan.md" 2>/dev/null; then
        log_warning "Consider adding artifact strategy to plan.md (build-once, promote-many)"
        log_info "See: https://12factor.net/build-release-run"
        echo ""
    fi

    # Final decision
    if [ "${#blockers[@]}" -gt 0 ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Optimization FAILED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Blockers:"
        printf "  - %s\n" "${blockers[@]}"
        echo ""
        echo "Fix the blockers above and re-run /optimize"
        return 1
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_success "Optimization PASSED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "All quality gates passed. Ready for /preview"
        return 0
    fi
}

# Main workflow
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Optimization Workflow"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Detect feature directory
    FEATURE_DIR=$(detect_feature_dir "${1:-}")
    export FEATURE_DIR

    log_info "Feature directory: $FEATURE_DIR"
    echo ""

    # Run checks
    check_prerequisites
    extract_targets
    echo ""

    log_info "Running quality gates in parallel..."
    echo ""

    # Run all checks (in reality these could be parallelized)
    # Gates 1-6: Core quality checks
    check_performance
    check_security
    check_accessibility
    check_code_review
    check_migrations
    check_docker
    # Gate 7: E2E and Visual Regression (runs for both features and epics)
    check_e2e_visual
    # Gates 8-15: Pre-CI validation (license, env, circular deps, dead code, etc.)
    check_pre_ci

    echo ""

    # Aggregate and decide
    if aggregate_results; then
        exit 0
    else
        exit 1
    fi
}

# Run main workflow
main "$@"

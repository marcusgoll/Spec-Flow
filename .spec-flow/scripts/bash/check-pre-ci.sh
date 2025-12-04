#!/usr/bin/env bash
# Pre-CI Quality Gates - Tech Stack Agnostic
# Gates 8-15: Catch issues locally before wasting CI/CD resources
#
# Usage: check-pre-ci.sh [FEATURE_DIR]
#
# Exit codes: 0=pass, 1=fail (blocking), 2=warnings only

set -uo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }
log_skip() { echo -e "${CYAN}[SKIP]${NC} $*"; }

# Configuration
FEATURE_DIR="${1:-.}"
REPORT_FILE="$FEATURE_DIR/pre-ci-report.md"
BLOCKING_FAILURES=0
WARNINGS=0

# Navigate to repo root
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1

# Initialize report
init_report() {
    cat > "$REPORT_FILE" << 'EOF'
# Pre-CI Quality Gates Report

Generated: $(date -Iseconds)

| Gate | Status | Details |
|------|--------|---------|
EOF
    # Replace the date placeholder
    sed -i "s/\$(date -Iseconds)/$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)/" "$REPORT_FILE" 2>/dev/null || true
}

# Append to report
report_gate() {
    local gate="$1"
    local status="$2"
    local details="$3"
    echo "| $gate | $status | $details |" >> "$REPORT_FILE"
}

# Tech stack detection
detect_stack() {
    local stack=""
    [ -f "package.json" ] && stack="$stack node"
    [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] && stack="$stack python"
    [ -f "Dockerfile" ] && stack="$stack docker"
    [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] && stack="$stack frontend"
    [ -f "tsconfig.json" ] && stack="$stack typescript"
    echo "$stack"
}

# Gate 8: License Compliance
check_licenses() {
    log_info "Gate 8: License Compliance..."

    local has_node=false
    local has_python=false
    [ -f "package.json" ] && has_node=true
    { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && has_python=true

    if [ "$has_node" = false ] && [ "$has_python" = false ]; then
        log_skip "No package manifest found"
        report_gate "License Compliance" "SKIPPED" "No package manifest"
        return 0
    fi

    local failed=0

    # Node.js license check
    if [ "$has_node" = true ]; then
        if command -v npx >/dev/null 2>&1; then
            log_info "  Checking npm licenses..."
            local license_output
            if license_output=$(npx --yes license-checker --failOn "GPL;AGPL;Unlicensed" 2>&1); then
                log_success "  npm licenses OK"
            else
                if echo "$license_output" | grep -qi "GPL\|AGPL\|Unlicensed"; then
                    log_error "  Incompatible npm licenses found"
                    echo "$license_output" | grep -i "GPL\|AGPL\|Unlicensed" | head -10
                    failed=1
                fi
            fi
        else
            log_warning "  npx not found, skipping npm license check"
        fi
    fi

    # Python license check
    if [ "$has_python" = true ]; then
        if command -v pip-licenses >/dev/null 2>&1; then
            log_info "  Checking pip licenses..."
            if pip-licenses --fail-on "GPL;AGPL" 2>&1 | grep -qi "GPL\|AGPL"; then
                log_error "  Incompatible pip licenses found"
                failed=1
            else
                log_success "  pip licenses OK"
            fi
        else
            log_warning "  pip-licenses not installed, skipping"
        fi
    fi

    if [ "$failed" -eq 1 ]; then
        report_gate "License Compliance" "FAILED" "Incompatible licenses found (GPL/AGPL)"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    else
        report_gate "License Compliance" "PASSED" "All licenses compatible"
        log_success "Gate 8: License Compliance PASSED"
        return 0
    fi
}

# Gate 9: Environment Validation
check_env_vars() {
    log_info "Gate 9: Environment Validation..."

    if [ ! -f ".env.example" ]; then
        log_skip "No .env.example found"
        report_gate "Environment Validation" "SKIPPED" "No .env.example"
        return 0
    fi

    if [ ! -f ".env" ]; then
        log_error "Missing .env file (required by .env.example)"
        report_gate "Environment Validation" "FAILED" "Missing .env file"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    fi

    # Extract variable names from both files (excluding comments and empty lines)
    local required_vars
    local actual_vars
    required_vars=$(grep -v '^#' .env.example 2>/dev/null | grep -v '^$' | cut -d= -f1 | sort -u)
    actual_vars=$(grep -v '^#' .env 2>/dev/null | grep -v '^$' | cut -d= -f1 | sort -u)

    # Find missing vars (cross-platform compatible)
    local missing=""
    for var in $required_vars; do
        if ! echo "$actual_vars" | grep -q "^${var}$"; then
            missing="$missing $var"
        fi
    done

    if [ -n "$missing" ]; then
        log_error "Missing required env vars:$missing"
        report_gate "Environment Validation" "FAILED" "Missing:$missing"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    else
        log_success "Gate 9: Environment Validation PASSED"
        report_gate "Environment Validation" "PASSED" "All required vars present"
        return 0
    fi
}

# Gate 10: Circular Dependencies
check_circular_deps() {
    log_info "Gate 10: Circular Dependencies..."

    local has_node=false
    local has_python=false
    [ -f "package.json" ] && has_node=true
    { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && has_python=true

    # Determine source directory
    local src_dir=""
    [ -d "src" ] && src_dir="src"
    [ -d "app" ] && src_dir="app"
    [ -d "apps" ] && src_dir="apps"

    if [ -z "$src_dir" ]; then
        log_skip "No src/app/apps directory found"
        report_gate "Circular Dependencies" "SKIPPED" "No source directory"
        return 0
    fi

    local failed=0
    local cycles_found=0

    # Node.js/TypeScript circular dependency check
    if [ "$has_node" = true ]; then
        if command -v npx >/dev/null 2>&1; then
            log_info "  Checking TypeScript/JS circular imports..."
            local madge_output
            if madge_output=$(npx --yes madge --circular --extensions ts,tsx,js,jsx "$src_dir" 2>&1); then
                if echo "$madge_output" | grep -q "No circular dependency found"; then
                    log_success "  No circular dependencies"
                else
                    cycles_found=$(echo "$madge_output" | grep -c "→" || echo "0")
                    if [ "$cycles_found" -gt 0 ]; then
                        log_error "  Found $cycles_found circular dependencies"
                        echo "$madge_output" | head -20
                        failed=1
                    fi
                fi
            fi
        else
            log_warning "  npx not found, skipping madge check"
        fi
    fi

    # Python circular dependency check
    if [ "$has_python" = true ] && [ -d "$src_dir" ]; then
        if command -v pydeps >/dev/null 2>&1; then
            log_info "  Checking Python circular imports..."
            if pydeps "$src_dir" --no-output --no-show 2>&1 | grep -qi "cycle"; then
                log_error "  Python circular imports detected"
                failed=1
            else
                log_success "  No Python circular imports"
            fi
        else
            log_warning "  pydeps not installed, skipping"
        fi
    fi

    if [ "$failed" -eq 1 ]; then
        report_gate "Circular Dependencies" "FAILED" "Import cycles detected"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    else
        log_success "Gate 10: Circular Dependencies PASSED"
        report_gate "Circular Dependencies" "PASSED" "No import cycles"
        return 0
    fi
}

# Gate 11: Dead Code Detection
check_dead_code() {
    log_info "Gate 11: Dead Code Detection..."

    local dead_code_count=0
    local threshold=10  # Block if >10 items found

    # TypeScript dead code check
    if [ -f "tsconfig.json" ]; then
        if command -v npx >/dev/null 2>&1; then
            log_info "  Checking TypeScript dead exports..."
            local ts_prune_output
            if ts_prune_output=$(npx --yes ts-prune 2>&1 | grep -v "used in module" | grep -v "^$"); then
                local ts_dead=$(echo "$ts_prune_output" | wc -l | tr -d ' ')
                dead_code_count=$((dead_code_count + ts_dead))
                if [ "$ts_dead" -gt 0 ]; then
                    log_warning "  Found $ts_dead unused TypeScript exports"
                    echo "$ts_prune_output" | head -10
                fi
            fi
        fi
    fi

    # Python dead code check
    if { [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; } && { [ -d "src" ] || [ -d "app" ]; }; then
        local py_src="src"
        [ -d "app" ] && py_src="app"

        if command -v vulture >/dev/null 2>&1; then
            log_info "  Checking Python dead code..."
            local vulture_output
            if vulture_output=$(vulture "$py_src" --min-confidence 80 2>&1); then
                local py_dead=$(echo "$vulture_output" | grep -c "unused" || echo "0")
                dead_code_count=$((dead_code_count + py_dead))
                if [ "$py_dead" -gt 0 ]; then
                    log_warning "  Found $py_dead unused Python items"
                    echo "$vulture_output" | head -10
                fi
            fi
        else
            log_warning "  vulture not installed, skipping Python check"
        fi
    fi

    if [ "$dead_code_count" -eq 0 ]; then
        log_success "Gate 11: Dead Code Detection PASSED (no dead code)"
        report_gate "Dead Code Detection" "PASSED" "No dead code found"
        return 0
    elif [ "$dead_code_count" -gt "$threshold" ]; then
        log_error "Gate 11: Dead Code Detection FAILED ($dead_code_count items > $threshold threshold)"
        report_gate "Dead Code Detection" "FAILED" "$dead_code_count items (threshold: $threshold)"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    else
        log_warning "Gate 11: Dead Code Detection WARNING ($dead_code_count items)"
        report_gate "Dead Code Detection" "WARNING" "$dead_code_count items (under threshold)"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi
}

# Gate 12: Dockerfile Best Practices
check_dockerfile() {
    log_info "Gate 12: Dockerfile Best Practices..."

    local has_dockerfile=false
    local has_compose=false
    [ -f "Dockerfile" ] && has_dockerfile=true
    [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] && has_compose=true

    if [ "$has_dockerfile" = false ] && [ "$has_compose" = false ]; then
        log_skip "No Dockerfile or docker-compose found"
        report_gate "Dockerfile Best Practices" "SKIPPED" "No Docker files"
        return 0
    fi

    local failed=0

    # Hadolint for Dockerfile
    if [ "$has_dockerfile" = true ]; then
        if command -v hadolint >/dev/null 2>&1; then
            log_info "  Linting Dockerfile with hadolint..."
            local hadolint_output
            if hadolint_output=$(hadolint Dockerfile --failure-threshold warning 2>&1); then
                log_success "  Dockerfile passed hadolint"
            else
                log_error "  Dockerfile has issues:"
                echo "$hadolint_output" | head -10
                failed=1
            fi
        elif command -v docker >/dev/null 2>&1; then
            # Try running hadolint via Docker
            log_info "  Running hadolint via Docker..."
            if docker run --rm -i hadolint/hadolint < Dockerfile 2>&1 | grep -qi "error\|warning"; then
                log_warning "  Dockerfile has warnings (run hadolint for details)"
            else
                log_success "  Dockerfile looks OK"
            fi
        else
            log_warning "  hadolint not installed, skipping Dockerfile lint"
        fi
    fi

    # Docker Compose validation
    if [ "$has_compose" = true ]; then
        if command -v docker-compose >/dev/null 2>&1 || command -v docker >/dev/null 2>&1; then
            log_info "  Validating docker-compose syntax..."
            local compose_file="docker-compose.yml"
            [ -f "docker-compose.yaml" ] && compose_file="docker-compose.yaml"

            if docker compose config -q 2>/dev/null || docker-compose config -q 2>/dev/null; then
                log_success "  docker-compose syntax valid"
            else
                log_error "  docker-compose syntax error"
                failed=1
            fi
        fi
    fi

    if [ "$failed" -eq 1 ]; then
        report_gate "Dockerfile Best Practices" "FAILED" "Docker file issues found"
        BLOCKING_FAILURES=$((BLOCKING_FAILURES + 1))
        return 1
    else
        log_success "Gate 12: Dockerfile Best Practices PASSED"
        report_gate "Dockerfile Best Practices" "PASSED" "Docker files valid"
        return 0
    fi
}

# Gate 13: Dependency Freshness (Warning only)
check_outdated_deps() {
    log_info "Gate 13: Dependency Freshness (informational)..."

    local outdated_count=0

    # Node.js outdated check
    if [ -f "package.json" ]; then
        if command -v npm >/dev/null 2>&1; then
            log_info "  Checking npm outdated packages..."
            local npm_outdated
            npm_outdated=$(npm outdated --json 2>/dev/null | grep -c '"wanted"' || echo "0")
            if [ "$npm_outdated" -gt 0 ]; then
                log_warning "  $npm_outdated npm packages have updates available"
                outdated_count=$((outdated_count + npm_outdated))
            else
                log_success "  npm packages up to date"
            fi
        fi
    fi

    # Python outdated check
    if [ -f "requirements.txt" ]; then
        if command -v pip >/dev/null 2>&1; then
            log_info "  Checking pip outdated packages..."
            local pip_outdated
            pip_outdated=$(pip list --outdated --format=json 2>/dev/null | grep -c '"name"' || echo "0")
            if [ "$pip_outdated" -gt 0 ]; then
                log_warning "  $pip_outdated pip packages have updates available"
                outdated_count=$((outdated_count + pip_outdated))
            else
                log_success "  pip packages up to date"
            fi
        fi
    fi

    # This gate never blocks, just warns
    if [ "$outdated_count" -gt 0 ]; then
        log_warning "Gate 13: $outdated_count outdated dependencies (non-blocking)"
        report_gate "Dependency Freshness" "WARNING" "$outdated_count outdated packages"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Gate 13: Dependencies are fresh"
        report_gate "Dependency Freshness" "PASSED" "All dependencies current"
    fi
    return 0
}

# Gate 14: Bundle Size Analysis (Warning only, Frontend)
check_bundle_size() {
    log_info "Gate 14: Bundle Size Analysis..."

    local is_frontend=false
    [ -f "next.config.js" ] || [ -f "next.config.mjs" ] && is_frontend=true
    [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] && is_frontend=true

    if [ "$is_frontend" = false ]; then
        log_skip "No frontend build config found"
        report_gate "Bundle Size Analysis" "SKIPPED" "Not a frontend project"
        return 0
    fi

    # Check if build already exists
    local build_dir=""
    [ -d ".next/static" ] && build_dir=".next/static"
    [ -d "dist" ] && build_dir="dist"
    [ -d "build" ] && build_dir="build"

    if [ -z "$build_dir" ]; then
        log_warning "  No build output found. Run build first for accurate size."
        report_gate "Bundle Size Analysis" "SKIPPED" "No build output"
        return 0
    fi

    # Calculate JS bundle size
    local total_size=0
    local threshold_kb=500

    log_info "  Analyzing bundle size in $build_dir..."

    # Find all JS files and sum their sizes
    if command -v find >/dev/null 2>&1; then
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                local file_size
                file_size=$(wc -c < "$file" 2>/dev/null || echo "0")
                total_size=$((total_size + file_size))
            fi
        done < <(find "$build_dir" -name "*.js" -type f 2>/dev/null)
    fi

    local size_kb=$((total_size / 1024))

    if [ "$size_kb" -gt "$threshold_kb" ]; then
        log_warning "Gate 14: Bundle size ${size_kb}KB exceeds ${threshold_kb}KB threshold"
        report_gate "Bundle Size Analysis" "WARNING" "${size_kb}KB (threshold: ${threshold_kb}KB)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Gate 14: Bundle size ${size_kb}KB (under ${threshold_kb}KB threshold)"
        report_gate "Bundle Size Analysis" "PASSED" "${size_kb}KB"
    fi
    return 0
}

# Gate 15: Health Check Validation
check_health_endpoint() {
    log_info "Gate 15: Health Check Validation..."

    # Check if this is a deployable app
    local has_start_script=false
    if [ -f "package.json" ]; then
        if grep -q '"start"' package.json 2>/dev/null; then
            has_start_script=true
        fi
    fi

    # Skip if no start script or if this is a library
    if [ "$has_start_script" = false ]; then
        log_skip "No start script found (library or static site)"
        report_gate "Health Check Validation" "SKIPPED" "No start script"
        return 0
    fi

    # Check if health endpoint is defined in code
    local has_health_endpoint=false
    if grep -rq "/health\|/healthz\|/api/health" . --include="*.ts" --include="*.js" --include="*.py" 2>/dev/null; then
        has_health_endpoint=true
    fi

    if [ "$has_health_endpoint" = false ]; then
        log_warning "No health endpoint found in code. Consider adding /health or /healthz"
        report_gate "Health Check Validation" "WARNING" "No health endpoint defined"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi

    # Don't actually start the app - just verify health endpoint exists
    log_success "Gate 15: Health endpoint found in code"
    report_gate "Health Check Validation" "PASSED" "Health endpoint defined"
    return 0
}

# Main execution
main() {
    echo ""
    echo "=============================================="
    echo "  Pre-CI Quality Gates (8-15)"
    echo "  Fail fast, fail local"
    echo "=============================================="
    echo ""

    # Detect stack
    local stack
    stack=$(detect_stack)
    log_info "Detected stack:$stack"
    echo ""

    # Initialize report
    init_report

    # Run all gates
    check_licenses || true
    echo ""
    check_env_vars || true
    echo ""
    check_circular_deps || true
    echo ""
    check_dead_code || true
    echo ""
    check_dockerfile || true
    echo ""
    check_outdated_deps || true
    echo ""
    check_bundle_size || true
    echo ""
    check_health_endpoint || true
    echo ""

    # Summary
    echo "=============================================="
    echo "  Pre-CI Gates Summary"
    echo "=============================================="
    echo ""

    # Add summary status to report for aggregate_results integration
    echo "" >> "$REPORT_FILE"
    echo "## Summary" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ "$BLOCKING_FAILURES" -gt 0 ]; then
        log_error "FAILED: $BLOCKING_FAILURES blocking issues found"
        [ "$WARNINGS" -gt 0 ] && log_warning "Plus $WARNINGS warnings"
        echo ""
        echo "Fix blocking issues and re-run /optimize"
        echo "Report: $REPORT_FILE"
        echo "Status: FAILED" >> "$REPORT_FILE"
        echo "Blocking issues: $BLOCKING_FAILURES" >> "$REPORT_FILE"
        echo "Warnings: $WARNINGS" >> "$REPORT_FILE"
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        log_warning "PASSED with $WARNINGS warnings"
        echo "Report: $REPORT_FILE"
        echo "Status: PASSED" >> "$REPORT_FILE"
        echo "Warnings: $WARNINGS" >> "$REPORT_FILE"
        exit 0
    else
        log_success "All pre-CI gates passed"
        echo "Report: $REPORT_FILE"
        echo "Status: PASSED" >> "$REPORT_FILE"
        exit 0
    fi
}

main "$@"

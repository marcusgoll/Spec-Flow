#!/usr/bin/env bash
# Constitution Check - Engineering Standards Validation
# Validates plan.md against 8 core engineering standards
#
# Usage: check-constitution.sh <plan-file> [--auto-fix]
# Output: JSON report with violations and recommendations
#
# Standards:
#   1. Code Reuse First - Search before creating, cite existing patterns
#   2. Test-Driven Development - Tests before implementation
#   3. API Contract Stability - Versioning, backward compatibility
#   4. Security by Default - Input validation, auth required
#   5. Accessibility First - WCAG 2.2 AA minimum
#   6. Performance Budgets - Explicit targets (p95/p99)
#   7. Observability - Structured logging, metrics, tracing
#   8. Deployment Safety - Blue-green, rollback, health checks

set -uo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# Input validation
PLAN_FILE="${1:-}"
AUTO_FIX=false
if [ "${2:-}" = "--auto-fix" ]; then
    AUTO_FIX=true
fi

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
    echo '{"error": "Plan file not found or not provided"}'
    exit 1
fi

# Read plan content
PLAN_CONTENT=$(cat "$PLAN_FILE")

# Track results
declare -A STANDARD_STATUS  # pass, fail, warn
declare -A STANDARD_DETAILS
VIOLATIONS=0
WARNINGS=0
PASSES=0

# Standard definitions: name|pattern|required|auto-fix-template
declare -a STANDARDS=(
    "Code Reuse First|reuse|existing|leverage|pattern|shared|common|util|helper|base|abstract|inherit|extend|import.from|true|## Code Reuse\n\n- [ ] Search for existing implementations before creating new\n- [ ] Cite specific files/functions to reuse\n- [ ] Document why new code is needed if not reusing"
    "Test-Driven Development|test|spec|coverage|unit.test|integration.test|e2e|jest|pytest|vitest|playwright|true|## Testing Strategy\n\n- [ ] Write failing tests first (Red)\n- [ ] Implement to pass tests (Green)\n- [ ] Refactor with confidence (Refactor)\n- [ ] Target: 80% coverage minimum"
    "API Contract Stability|contract|openapi|swagger|version|backward|breaking|deprecat|migration.path|true|## API Contracts\n\n- [ ] Define contracts before implementation\n- [ ] Version all public APIs\n- [ ] Document breaking changes\n- [ ] Provide migration paths"
    "Security by Default|security|auth|valid|sanitiz|encrypt|https|csrf|xss|sql.injection|owasp|permission|rbac|true|## Security\n\n- [ ] Input validation on all endpoints\n- [ ] Authentication required by default\n- [ ] OWASP Top 10 compliance\n- [ ] Secrets management via env vars"
    "Accessibility First|accessib|wcag|aria|a11y|keyboard|screen.reader|contrast|focus|alt.text|false|## Accessibility\n\n- [ ] WCAG 2.1 AA compliance\n- [ ] Keyboard navigation\n- [ ] Screen reader support\n- [ ] Color contrast validation"
    "Performance Budgets|performance|latency|p95|p99|budget|lighthouse|ttfb|fcp|lcp|cls|cache|optim|true|## Performance\n\n- [ ] API latency targets: <500ms p95\n- [ ] Page load targets: <3s\n- [ ] Lighthouse score: >85\n- [ ] Bundle size limits defined"
    "Observability|observ|log|metric|trace|monitor|alert|dashboard|telemetry|correlation.id|span|true|## Observability\n\n- [ ] Structured JSON logging\n- [ ] Request correlation IDs\n- [ ] Key metrics instrumented\n- [ ] Error tracking configured"
    "Deployment Safety|deploy|rollback|health|blue.green|canary|feature.flag|migration|zero.downtime|true|## Deployment\n\n- [ ] Health check endpoints\n- [ ] Rollback capability\n- [ ] Database migrations reversible\n- [ ] Feature flags for risky changes"
)

# Check if plan mentions a standard
check_standard() {
    local name="$1"
    local pattern="$2"
    local required="$3"
    local auto_fix_template="$4"

    # Convert pipe-separated pattern to regex
    local regex_pattern=$(echo "$pattern" | tr '|' '\n' | grep -v '^$' | paste -sd'|')

    # Count matches
    local match_count
    match_count=$(echo "$PLAN_CONTENT" | grep -ciE "$regex_pattern" || echo "0")

    if [ "$match_count" -ge 2 ]; then
        STANDARD_STATUS["$name"]="pass"
        STANDARD_DETAILS["$name"]="Found $match_count references"
        log_pass "$name: Found $match_count references"
        ((PASSES++))
    elif [ "$match_count" -eq 1 ]; then
        STANDARD_STATUS["$name"]="warn"
        STANDARD_DETAILS["$name"]="Minimal coverage (1 reference)"
        log_warn "$name: Minimal coverage (consider expanding)"
        ((WARNINGS++))
    else
        if [ "$required" = "true" ]; then
            STANDARD_STATUS["$name"]="fail"
            STANDARD_DETAILS["$name"]="No coverage found"
            log_fail "$name: Not addressed in plan"
            ((VIOLATIONS++))

            # Auto-fix if enabled
            if [ "$AUTO_FIX" = true ]; then
                log_info "Auto-adding TODO section for $name"
                echo -e "\n$auto_fix_template" >> "$PLAN_FILE"
            fi
        else
            STANDARD_STATUS["$name"]="warn"
            STANDARD_DETAILS["$name"]="Not addressed (optional)"
            log_warn "$name: Not addressed (optional for this feature type)"
            ((WARNINGS++))
        fi
    fi
}

# Main processing
process_standards() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Constitution Check - 8 Engineering Standards"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Analyzing: $PLAN_FILE"
    echo ""

    for standard_config in "${STANDARDS[@]}"; do
        IFS='|' read -r name pattern required auto_fix_template <<< "$standard_config"
        check_standard "$name" "$pattern" "$required" "$auto_fix_template"
    done
}

# Generate report
generate_report() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Passed:     $PASSES / 8"
    echo "Warnings:   $WARNINGS"
    echo "Violations: $VIOLATIONS"
    echo ""

    if [ "$VIOLATIONS" -gt 0 ]; then
        echo -e "${RED}CONSTITUTION CHECK FAILED${NC}"
        echo ""
        echo "Missing required standards:"
        for name in "${!STANDARD_STATUS[@]}"; do
            if [ "${STANDARD_STATUS[$name]}" = "fail" ]; then
                echo "  - $name"
            fi
        done
        echo ""
        if [ "$AUTO_FIX" = true ]; then
            echo "Auto-fix applied: TODO sections added to plan.md"
            echo "Review and complete the TODO items before proceeding."
        else
            echo "Run with --auto-fix to add TODO sections automatically"
        fi
        return 1
    elif [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}CONSTITUTION CHECK PASSED WITH WARNINGS${NC}"
        echo ""
        echo "Consider improving coverage for:"
        for name in "${!STANDARD_STATUS[@]}"; do
            if [ "${STANDARD_STATUS[$name]}" = "warn" ]; then
                echo "  - $name: ${STANDARD_DETAILS[$name]}"
            fi
        done
        return 0
    else
        echo -e "${GREEN}CONSTITUTION CHECK PASSED${NC}"
        echo ""
        echo "All 8 engineering standards adequately addressed."
        return 0
    fi
}

# JSON output option
generate_json() {
    local standards_json=""
    for name in "${!STANDARD_STATUS[@]}"; do
        [ -n "$standards_json" ] && standards_json+=","
        standards_json+="{\"name\":\"$name\",\"status\":\"${STANDARD_STATUS[$name]}\",\"details\":\"${STANDARD_DETAILS[$name]}\"}"
    done

    cat << EOF
{
  "plan_file": "$PLAN_FILE",
  "passed": $PASSES,
  "warnings": $WARNINGS,
  "violations": $VIOLATIONS,
  "overall": "$([ $VIOLATIONS -gt 0 ] && echo "fail" || echo "pass")",
  "standards": [$standards_json]
}
EOF
}

# Main execution
process_standards

# Output based on mode
if [ "${3:-}" = "--json" ]; then
    generate_json
else
    generate_report
fi

# Exit code based on violations
[ "$VIOLATIONS" -gt 0 ] && exit 1 || exit 0

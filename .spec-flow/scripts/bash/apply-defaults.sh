#!/usr/bin/env bash
# Informed Guess Heuristics Engine
# Applies sensible defaults to spec.md when requirements are missing
#
# Usage: apply-defaults.sh <spec-file> [--dry-run]
# Output: Modified spec.md with applied defaults (or JSON report in dry-run mode)
#
# Default Categories:
#   - Performance: <500ms p95 latency, <3s page load
#   - Authentication: OAuth2/JWT
#   - Error handling: Structured error responses
#   - Rate limiting: 100 req/min per user
#   - Caching: Stale-while-revalidate
#   - Pagination: 20 items default, 100 max

set -uo pipefail

# Color output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_success() { echo -e "${GREEN}[APPLIED]${NC} $*"; }

# Input validation
SPEC_FILE="${1:-}"
DRY_RUN=false
if [ "${2:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
    echo '{"error": "Spec file not found or not provided"}'
    exit 1
fi

# Read spec content
SPEC_CONTENT=$(cat "$SPEC_FILE")

# Track applied defaults
APPLIED_DEFAULTS=()

# Default definitions with detection patterns and values
declare -A DEFAULTS
DEFAULTS["performance"]="pattern:performance|latency|response.time|p95|p99|sla;default:API response time <500ms (p95), page load <3s;section:NFR"
DEFAULTS["auth"]="pattern:auth|login|session|token|oauth|jwt|permission|role;default:OAuth2/JWT with refresh tokens, session timeout 30min;section:NFR"
DEFAULTS["error_handling"]="pattern:error|exception|failure|fault|recover;default:Structured JSON errors {code, message, details}, HTTP status codes;section:NFR"
DEFAULTS["rate_limiting"]="pattern:rate.limit|throttl|quota|burst;default:100 req/min per authenticated user, 20 req/min anonymous;section:NFR"
DEFAULTS["caching"]="pattern:cache|ttl|stale|invalidat|cdn;default:Stale-while-revalidate, 5min TTL for lists, 1hr for static;section:NFR"
DEFAULTS["pagination"]="pattern:pagination|page|limit|offset|cursor;default:Default 20 items, max 100, cursor-based for large sets;section:NFR"
DEFAULTS["validation"]="pattern:validat|sanitiz|input|schema;default:Server-side validation required, client-side for UX only;section:NFR"
DEFAULTS["logging"]="pattern:log|audit|trace|monitor;default:Structured JSON logs, request ID correlation, PII redaction;section:NFR"
DEFAULTS["accessibility"]="pattern:accessib|wcag|aria|screen.reader|keyboard;default:WCAG 2.1 AA compliance, keyboard navigation, screen reader support;section:NFR"
DEFAULTS["mobile"]="pattern:mobile|responsive|touch|viewport;default:Mobile-first responsive design, touch targets >44px;section:NFR"

# Check if spec mentions a topic (returns true/false)
spec_mentions() {
    local pattern="$1"
    if echo "$SPEC_CONTENT" | grep -qiE "$pattern"; then
        return 0  # true - mentioned
    else
        return 1  # false - not mentioned
    fi
}

# Check if spec has explicit requirement for topic
has_explicit_requirement() {
    local pattern="$1"
    # Check NFR section for explicit requirements
    if echo "$SPEC_CONTENT" | grep -A20 "## Non-Functional Requirements\|## NFR\|### NFR" | grep -qiE "$pattern"; then
        return 0
    fi
    return 1
}

# Apply a default to spec.md
apply_default() {
    local category="$1"
    local default_value="$2"
    local section="$3"

    if [ "$DRY_RUN" = true ]; then
        APPLIED_DEFAULTS+=("$category")
        return
    fi

    # Find NFR section and append
    if grep -q "## Non-Functional Requirements\|## NFR" "$SPEC_FILE"; then
        # Add to existing NFR section
        local nfr_marker
        nfr_marker=$(grep -n "## Non-Functional Requirements\|## NFR" "$SPEC_FILE" | head -1 | cut -d: -f1)

        # Find next section or EOF
        local next_section
        next_section=$(tail -n +$((nfr_marker + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

        if [ -n "$next_section" ]; then
            local insert_line=$((nfr_marker + next_section - 1))
        else
            local insert_line=$(wc -l < "$SPEC_FILE")
        fi

        # Generate NFR ID
        local nfr_count
        nfr_count=$(grep -c "^NFR-" "$SPEC_FILE" 2>/dev/null || echo "0")
        local nfr_id="NFR-$(printf "%03d" $((nfr_count + 1)))"

        # Insert the default
        local default_text="- **${nfr_id}**: ${category^} - ${default_value} _[INFORMED GUESS - verify with stakeholders]_"

        sed -i "${insert_line}a\\${default_text}" "$SPEC_FILE"
        APPLIED_DEFAULTS+=("$category")
        log_success "Applied $category default as $nfr_id"
    fi
}

# Main processing
process_defaults() {
    log_info "Analyzing spec.md for missing requirements..."

    for category in "${!DEFAULTS[@]}"; do
        local config="${DEFAULTS[$category]}"
        local pattern=$(echo "$config" | grep -oP 'pattern:\K[^;]+')
        local default_value=$(echo "$config" | grep -oP 'default:\K[^;]+')
        local section=$(echo "$config" | grep -oP 'section:\K[^;]+')

        # Check if topic is mentioned but no explicit requirement
        if spec_mentions "$pattern"; then
            if ! has_explicit_requirement "$pattern"; then
                log_warn "Topic '$category' mentioned but no explicit NFR found"
                apply_default "$category" "$default_value" "$section"
            else
                log_info "Topic '$category' has explicit requirement - skipping"
            fi
        fi
    done
}

# Generate report
generate_report() {
    local count=${#APPLIED_DEFAULTS[@]}

    if [ "$DRY_RUN" = true ]; then
        # JSON output for dry run
        local defaults_json=""
        for d in "${APPLIED_DEFAULTS[@]}"; do
            [ -n "$defaults_json" ] && defaults_json+=","
            defaults_json+="\"$d\""
        done

        cat << EOF
{
  "spec_file": "$SPEC_FILE",
  "dry_run": true,
  "defaults_to_apply": [$defaults_json],
  "count": $count
}
EOF
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Informed Guess Summary"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Applied $count defaults to $SPEC_FILE"
        echo ""
        if [ $count -gt 0 ]; then
            echo "Categories:"
            for d in "${APPLIED_DEFAULTS[@]}"; do
                echo "  - $d"
            done
            echo ""
            echo "Note: All defaults marked with [INFORMED GUESS] for review"
        fi
    fi
}

# Main execution
process_defaults
generate_report

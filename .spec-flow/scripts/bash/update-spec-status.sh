#!/usr/bin/env bash
# Update spec.md Implementation Status section

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: update-spec-status.sh [--type TYPE] [--data DATA] <feature-dir>

Update spec.md Implementation Status section with requirements, deviations, or performance data.

Options:
  --type TYPE     Type of update: requirement | deviation | performance
  --data DATA     JSON string with update data

Arguments:
  feature-dir     Path to feature directory (e.g., specs/001-auth-flow)

Examples:
  # Mark requirement fulfilled
  update-spec-status.sh --type requirement --data '{"id":"FR-001","status":"fulfilled","tasks":"T001-T003"}' specs/001-auth

  # Add deviation
  update-spec-status.sh --type deviation --data '{"id":"FR-004","name":"Email verification","original":"Postmark","actual":"SendGrid","reason":"Cost","impact":"Minor"}' specs/001-auth

  # Add performance actual
  update-spec-status.sh --type performance --data '{"metric":"FCP","target":"<1.5s","actual":"1.2s","status":"pass"}' specs/001-auth
EOF
}

TYPE=""
DATA=""

while (( $# )); do
    case "$1" in
        --type)
            shift
            TYPE="$1"
            ;;
        --data)
            shift
            DATA="$1"
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
    shift
done

if [ $# -eq 0 ]; then
    log_error "Provide a feature directory path."
    show_help
    exit 1
fi

FEATURE_DIR="$1"
SPEC_FILE="$FEATURE_DIR/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
    log_error "No spec.md found in $FEATURE_DIR"
    exit 1
fi

if [ -z "$TYPE" ]; then
    log_error "--type required (requirement|deviation|performance)"
    exit 1
fi

if [ -z "$DATA" ]; then
    log_error "--data required (JSON string)"
    exit 1
fi

# Update timestamp
TIMESTAMP=$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

case "$TYPE" in
    requirement)
        # Extract fields from JSON
        REQ_ID=$(echo "$DATA" | grep -oP '"id"\s*:\s*"\K[^"]+' || echo "")
        STATUS=$(echo "$DATA" | grep -oP '"status"\s*:\s*"\K[^"]+' || echo "fulfilled")
        TASKS=$(echo "$DATA" | grep -oP '"tasks"\s*:\s*"\K[^"]+' || echo "")
        DESCRIPTION=$(echo "$DATA" | grep -oP '"description"\s*:\s*"\K[^"]+' || echo "$REQ_ID")

        # Determine emoji
        case "$STATUS" in
            fulfilled) EMOJI="✅" ;;
            deferred) EMOJI="⚠️" ;;
            descoped) EMOJI="❌" ;;
            *) EMOJI="⚠️" ;;
        esac

        # Append to Requirements Fulfilled section
        ENTRY="- $EMOJI **$REQ_ID**: $DESCRIPTION - Implemented in tasks $TASKS"

        # Find Implementation Status section and append
        if grep -q "### Requirements Fulfilled" "$SPEC_FILE"; then
            # Append after the section header
            sed -i "/### Requirements Fulfilled/a\\
\\
$ENTRY" "$SPEC_FILE"
            log_info "Added requirement $REQ_ID to spec.md"
        else
            log_warn "No 'Requirements Fulfilled' section found in spec.md"
        fi
        ;;

    deviation)
        REQ_ID=$(echo "$DATA" | grep -oP '"id"\s*:\s*"\K[^"]+' || echo "")
        NAME=$(echo "$DATA" | grep -oP '"name"\s*:\s*"\K[^"]+' || echo "")
        ORIGINAL=$(echo "$DATA" | grep -oP '"original"\s*:\s*"\K[^"]+' || echo "")
        ACTUAL=$(echo "$DATA" | grep -oP '"actual"\s*:\s*"\K[^"]+' || echo "")
        REASON=$(echo "$DATA" | grep -oP '"reason"\s*:\s*"\K[^"]+' || echo "")
        IMPACT=$(echo "$DATA" | grep -oP '"impact"\s*:\s*"\K[^"]+' || echo "Minor")

        # Create deviation entry
        ENTRY="- **Requirement $REQ_ID ($NAME)**: Changed from $ORIGINAL to $ACTUAL
  - **Original approach**: $ORIGINAL
  - **Actual implementation**: $ACTUAL
  - **Reason**: $REASON
  - **Impact**: $IMPACT"

        # Find Deviations section and append
        if grep -q "### Deviations from Spec" "$SPEC_FILE"; then
            # Insert after the Format line
            sed -i "/^**Format**: Document when implementation differs/a\\
\\
$ENTRY" "$SPEC_FILE"
            log_info "Added deviation for $REQ_ID to spec.md"
        else
            log_warn "No 'Deviations from Spec' section found in spec.md"
        fi
        ;;

    performance)
        METRIC=$(echo "$DATA" | grep -oP '"metric"\s*:\s*"\K[^"]+' || echo "")
        TARGET=$(echo "$DATA" | grep -oP '"target"\s*:\s*"\K[^"]+' || echo "")
        ACTUAL=$(echo "$DATA" | grep -oP '"actual"\s*:\s*"\K[^"]+' || echo "")
        STATUS_VAL=$(echo "$DATA" | grep -oP '"status"\s*:\s*"\K[^"]+' || echo "pass")
        NOTES=$(echo "$DATA" | grep -oP '"notes"\s*:\s*"\K[^"]+' || echo "-")

        # Determine status emoji
        case "$STATUS_VAL" in
            pass) STATUS_EMOJI="✅ Pass" ;;
            warning) STATUS_EMOJI="⚠️ Warning" ;;
            fail) STATUS_EMOJI="❌ Fail" ;;
            *) STATUS_EMOJI="⚠️ Warning" ;;
        esac

        # Create table row
        ROW="| $METRIC | $TARGET | $ACTUAL | $STATUS_EMOJI | $NOTES |"

        # Find Performance Actuals table and append
        if grep -q "### Performance Actuals vs Targets" "$SPEC_FILE"; then
            # Append to table (after header row)
            sed -i "/^| Metric | Target | Actual | Status | Notes |/a\\
$ROW" "$SPEC_FILE"
            log_info "Added performance metric $METRIC to spec.md"
        else
            log_warn "No 'Performance Actuals vs Targets' section found in spec.md"
        fi
        ;;

    *)
        log_error "Invalid type: $TYPE (must be requirement|deviation|performance)"
        exit 1
        ;;
esac

# Update Last Updated timestamp in Implementation Status section
sed -i "s/^> \*\*Last Updated\*\*:.*/> **Last Updated**: $TIMESTAMP/" "$SPEC_FILE"

log_info "Updated spec.md Implementation Status ($TYPE)"

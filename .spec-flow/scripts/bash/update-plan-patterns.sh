#!/usr/bin/env bash
# Update plan.md Discovered Patterns section

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: update-plan-patterns.sh [--type TYPE] [--data DATA] <feature-dir>

Update plan.md Discovered Patterns section with reuse additions, architecture adjustments, or integration discoveries.

Options:
  --type TYPE     Type of update: reuse | architecture | integration
  --data DATA     JSON string with update data

Arguments:
  feature-dir     Path to feature directory (e.g., specs/001-auth-flow)

Examples:
  # Add reuse pattern
  update-plan-patterns.sh --type reuse --data '{"name":"UserService.create_user()","path":"api/src/services/user.py:42-58","task":"T013","purpose":"User creation with validation","reusable":"Any endpoint creating users","why":"New code in T010"}' specs/001-auth

  # Add architecture adjustment
  update-plan-patterns.sh --type architecture --data '{"change":"Added last_login column","original":"Users table basic fields","actual":"Added last_login timestamp","reason":"Session timeout needs tracking","migration":"api/alembic/versions/005_add_last_login.py","impact":"Minor"}' specs/001-auth

  # Add integration discovery
  update-plan-patterns.sh --type integration --data '{"name":"Email verification webhook","component":"User registration (T013)","dependency":"Clerk webhook","reason":"Clerk handles email verification","resolution":"Added webhook handler (T014)"}' specs/001-auth
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
PLAN_FILE="$FEATURE_DIR/plan.md"

if [ ! -f "$PLAN_FILE" ]; then
    log_error "No plan.md found in $FEATURE_DIR"
    exit 1
fi

if [ -z "$TYPE" ]; then
    log_error "--type required (reuse|architecture|integration)"
    exit 1
fi

if [ -z "$DATA" ]; then
    log_error "--data required (JSON string)"
    exit 1
fi

# Update timestamp
TIMESTAMP=$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')

case "$TYPE" in
    reuse)
        NAME=$(echo "$DATA" | grep -oP '"name"\s*:\s*"\K[^"]+' || echo "")
        PATH=$(echo "$DATA" | grep -oP '"path"\s*:\s*"\K[^"]+' || echo "")
        TASK=$(echo "$DATA" | grep -oP '"task"\s*:\s*"\K[^"]+' || echo "")
        PURPOSE=$(echo "$DATA" | grep -oP '"purpose"\s*:\s*"\K[^"]+' || echo "")
        REUSABLE=$(echo "$DATA" | grep -oP '"reusable"\s*:\s*"\K[^"]+' || echo "")
        WHY=$(echo "$DATA" | grep -oP '"why"\s*:\s*"\K[^"]+' || echo "")

        ENTRY="- ✅ **$NAME** (\`$PATH\`)
  - **Discovered in**: $TASK
  - **Purpose**: $PURPOSE
  - **Reusable for**: $REUSABLE
  - **Why not in Phase 0**: $WHY"

        # Find Reuse Additions section and append
        if grep -q "### Reuse Additions" "$PLAN_FILE"; then
            sed -i "/^**Format**: Document patterns discovered during implementation/a\\
\\
$ENTRY" "$PLAN_FILE"
            log_info "Added reuse pattern $NAME to plan.md"
        else
            log_warn "No 'Reuse Additions' section found in plan.md"
        fi
        ;;

    architecture)
        CHANGE=$(echo "$DATA" | grep -oP '"change"\s*:\s*"\K[^"]+' || echo "")
        ORIGINAL=$(echo "$DATA" | grep -oP '"original"\s*:\s*"\K[^"]+' || echo "")
        ACTUAL=$(echo "$DATA" | grep -oP '"actual"\s*:\s*"\K[^"]+' || echo "")
        REASON=$(echo "$DATA" | grep -oP '"reason"\s*:\s*"\K[^"]+' || echo "")
        MIGRATION=$(echo "$DATA" | grep -oP '"migration"\s*:\s*"\K[^"]+' || echo "")
        IMPACT=$(echo "$DATA" | grep -oP '"impact"\s*:\s*"\K[^"]+' || echo "Minor")

        ENTRY="- **$CHANGE**: Architecture adjustment
  - **Original design**: $ORIGINAL
  - **Actual implementation**: $ACTUAL
  - **Reason**: $REASON"

        if [ -n "$MIGRATION" ]; then
            ENTRY="$ENTRY
  - **Migration**: \`$MIGRATION\`"
        fi

        ENTRY="$ENTRY
  - **Impact**: $IMPACT"

        # Find Architecture Adjustments section and append
        if grep -q "### Architecture Adjustments" "$PLAN_FILE"; then
            sed -i "/^**Format**: Document when actual architecture differs/a\\
\\
$ENTRY" "$PLAN_FILE"
            log_info "Added architecture adjustment to plan.md"
        else
            log_warn "No 'Architecture Adjustments' section found in plan.md"
        fi
        ;;

    integration)
        NAME=$(echo "$DATA" | grep -oP '"name"\s*:\s*"\K[^"]+' || echo "")
        COMPONENT=$(echo "$DATA" | grep -oP '"component"\s*:\s*"\K[^"]+' || echo "")
        DEPENDENCY=$(echo "$DATA" | grep -oP '"dependency"\s*:\s*"\K[^"]+' || echo "")
        REASON=$(echo "$DATA" | grep -oP '"reason"\s*:\s*"\K[^"]+' || echo "")
        RESOLUTION=$(echo "$DATA" | grep -oP '"resolution"\s*:\s*"\K[^"]+' || echo "")

        ENTRY="- **$NAME**: Integration discovery
  - **Component**: $COMPONENT
  - **Dependency**: $DEPENDENCY
  - **Reason**: $REASON
  - **Resolution**: $RESOLUTION"

        # Find Integration Discoveries section and append
        if grep -q "### Integration Discoveries" "$PLAN_FILE"; then
            sed -i "/^**Format**: Document unexpected integrations/a\\
\\
$ENTRY" "$PLAN_FILE"
            log_info "Added integration discovery to plan.md"
        else
            log_warn "No 'Integration Discoveries' section found in plan.md"
        fi
        ;;

    *)
        log_error "Invalid type: $TYPE (must be reuse|architecture|integration)"
        exit 1
        ;;
esac

# Update Last Updated timestamp
sed -i "s/^> \*\*Last Updated\*\*:.*/> **Last Updated**: $TIMESTAMP/" "$PLAN_FILE"

log_info "Updated plan.md Discovered Patterns ($TYPE)"

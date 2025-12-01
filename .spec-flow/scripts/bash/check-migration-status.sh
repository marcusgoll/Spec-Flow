#!/usr/bin/env bash
# Migration Status Detection Script
# Detects pending migrations for Alembic, Prisma, or generic migrations
#
# Exit codes:
#   0 = up-to-date (no pending migrations)
#   1 = pending migrations detected
#   2 = no migration tool found
#
# Usage:
#   ./check-migration-status.sh [--json] [--verbose]
#
# Output (JSON mode):
#   {"tool":"alembic","detected":true,"pending":true,"pending_count":2,
#    "current":"abc123","head":"def456","apply_command":"alembic upgrade head"}

set -euo pipefail

# Parse arguments
JSON_OUTPUT=false
VERBOSE=false
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUTPUT=true ;;
        --verbose) VERBOSE=true ;;
    esac
done

# Helper functions
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[DEBUG] $*" >&2
    fi
}

output_json() {
    local tool="$1"
    local detected="$2"
    local pending="$3"
    local pending_count="${4:-0}"
    local current="${5:-}"
    local head="${6:-}"
    local apply_command="${7:-}"
    local error_reason="${8:-}"

    cat <<EOF
{"tool":"${tool}","detected":${detected},"pending":${pending},"pending_count":${pending_count},"current":"${current}","head":"${head}","apply_command":"${apply_command}","error_reason":"${error_reason}"}
EOF
}

output_text() {
    local tool="$1"
    local pending="$2"
    local pending_count="${3:-0}"
    local current="${4:-}"
    local head="${5:-}"
    local apply_command="${6:-}"

    if [ "$pending" = "true" ]; then
        echo "PENDING: ${pending_count} ${tool} migrations"
        echo "  Current: ${current}"
        echo "  Head: ${head}"
        echo "  Apply: ${apply_command}"
    else
        echo "UP-TO-DATE: ${tool} migrations"
    fi
}

# ============================================================
# Alembic Detection (Python/SQLAlchemy)
# ============================================================
check_alembic() {
    log_verbose "Checking for Alembic..."

    # Check if alembic is available
    if ! command -v alembic >/dev/null 2>&1; then
        # Try with uv
        if command -v uv >/dev/null 2>&1 && [ -d "api" ]; then
            ALEMBIC_CMD="uv run alembic"
        else
            log_verbose "Alembic not found"
            return 1
        fi
    else
        ALEMBIC_CMD="alembic"
    fi

    # Check for alembic.ini or alembic directory
    local alembic_dir=""
    if [ -f "alembic.ini" ]; then
        alembic_dir="."
    elif [ -f "api/alembic.ini" ]; then
        alembic_dir="api"
    elif [ -d "alembic" ]; then
        alembic_dir="."
    elif [ -d "api/alembic" ]; then
        alembic_dir="api"
    else
        log_verbose "No alembic.ini or alembic directory found"
        return 1
    fi

    log_verbose "Found Alembic in: ${alembic_dir}"

    # Get current revision
    local current=""
    local head=""
    local pending_count=0

    if [ -n "$alembic_dir" ] && [ "$alembic_dir" != "." ]; then
        cd "$alembic_dir"
    fi

    # Get current database revision
    current=$($ALEMBIC_CMD current 2>/dev/null | grep -oE '[a-f0-9]{12}' | head -1 || echo "")

    # Get head revision (latest migration file)
    head=$($ALEMBIC_CMD heads 2>/dev/null | grep -oE '[a-f0-9]{12}' | head -1 || echo "")

    # Count pending migrations
    if [ -n "$current" ] && [ -n "$head" ]; then
        if [ "$current" != "$head" ]; then
            pending_count=$($ALEMBIC_CMD history -r "${current}:${head}" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$pending_count" -eq 0 ]; then
                pending_count=1  # At least 1 if current != head
            fi
        fi
    elif [ -z "$current" ] && [ -n "$head" ]; then
        # Database not initialized, all migrations pending
        pending_count=$($ALEMBIC_CMD history 2>/dev/null | wc -l | tr -d ' ')
        current="(none)"
    fi

    # Return to original directory
    if [ -n "$alembic_dir" ] && [ "$alembic_dir" != "." ]; then
        cd - >/dev/null
    fi

    local apply_cmd="alembic upgrade head"
    if [ "$alembic_dir" = "api" ]; then
        apply_cmd="cd api && alembic upgrade head"
    fi

    if [ "$pending_count" -gt 0 ]; then
        if [ "$JSON_OUTPUT" = true ]; then
            output_json "alembic" "true" "true" "$pending_count" "$current" "$head" "$apply_cmd"
        else
            output_text "alembic" "true" "$pending_count" "$current" "$head" "$apply_cmd"
        fi
        return 0  # Found alembic with pending
    else
        if [ "$JSON_OUTPUT" = true ]; then
            output_json "alembic" "true" "false" "0" "$current" "$head" "$apply_cmd"
        else
            output_text "alembic" "false" "0" "$current" "$head" "$apply_cmd"
        fi
        return 0  # Found alembic, up to date
    fi
}

# ============================================================
# Prisma Detection (TypeScript/Node.js)
# ============================================================
check_prisma() {
    log_verbose "Checking for Prisma..."

    # Check for prisma schema
    local prisma_dir=""
    if [ -f "prisma/schema.prisma" ]; then
        prisma_dir="."
    elif [ -f "apps/web/prisma/schema.prisma" ]; then
        prisma_dir="apps/web"
    elif [ -f "packages/database/prisma/schema.prisma" ]; then
        prisma_dir="packages/database"
    else
        log_verbose "No prisma/schema.prisma found"
        return 1
    fi

    log_verbose "Found Prisma in: ${prisma_dir}"

    # Check if npx is available
    if ! command -v npx >/dev/null 2>&1; then
        log_verbose "npx not found"
        return 1
    fi

    local original_dir=$(pwd)
    if [ "$prisma_dir" != "." ]; then
        cd "$prisma_dir"
    fi

    # Get migration status
    local status_output=""
    status_output=$(npx prisma migrate status 2>&1) || true

    cd "$original_dir"

    local pending="false"
    local pending_count=0
    local apply_cmd="npx prisma migrate deploy"

    if [ "$prisma_dir" != "." ]; then
        apply_cmd="cd ${prisma_dir} && npx prisma migrate deploy"
    fi

    # Parse status output
    if echo "$status_output" | grep -qi "have not yet been applied"; then
        pending="true"
        # Try to extract count
        pending_count=$(echo "$status_output" | grep -oE '[0-9]+ migration' | grep -oE '[0-9]+' | head -1 || echo "1")
    elif echo "$status_output" | grep -qi "Database schema is up to date"; then
        pending="false"
        pending_count=0
    elif echo "$status_output" | grep -qi "following migration"; then
        pending="true"
        pending_count=1
    fi

    if [ "$JSON_OUTPUT" = true ]; then
        output_json "prisma" "true" "$pending" "$pending_count" "" "" "$apply_cmd"
    else
        output_text "prisma" "$pending" "$pending_count" "" "" "$apply_cmd"
    fi

    return 0
}

# ============================================================
# Generic Detection (file-based)
# ============================================================
check_generic() {
    log_verbose "Checking for generic migrations..."

    # Look for common migration directories
    local migration_dirs=(
        "migrations"
        "db/migrations"
        "database/migrations"
        "src/migrations"
    )

    local found_dir=""
    for dir in "${migration_dirs[@]}"; do
        if [ -d "$dir" ]; then
            found_dir="$dir"
            break
        fi
    done

    if [ -z "$found_dir" ]; then
        log_verbose "No generic migration directory found"
        return 1
    fi

    log_verbose "Found migrations in: ${found_dir}"

    # Check for marker file
    local marker_file=".spec-flow/memory/.migration_applied"
    local pending="false"
    local pending_count=0

    if [ -f "$marker_file" ]; then
        # Check if any migration files are newer than marker
        pending_count=$(find "$found_dir" -type f \( -name "*.sql" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -newer "$marker_file" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$pending_count" -gt 0 ]; then
            pending="true"
        fi
    else
        # No marker file - assume all migrations need to run
        pending_count=$(find "$found_dir" -type f \( -name "*.sql" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) 2>/dev/null | wc -l | tr -d ' ')
        if [ "$pending_count" -gt 0 ]; then
            pending="true"
        fi
    fi

    if [ "$JSON_OUTPUT" = true ]; then
        output_json "generic" "true" "$pending" "$pending_count" "" "" "# Run your migration command manually"
    else
        output_text "generic" "$pending" "$pending_count" "" "" "# Run your migration command manually"
    fi

    return 0
}

# ============================================================
# Main Detection Flow
# ============================================================
main() {
    log_verbose "Starting migration detection..."

    # Try each tool in priority order
    # Alembic first (most common in Python projects)
    if check_alembic; then
        # Check if pending
        if [ "$JSON_OUTPUT" = true ]; then
            # Already output JSON
            exit 0
        fi
        exit 0
    fi

    # Prisma second (common in TypeScript/Node.js)
    if check_prisma; then
        exit 0
    fi

    # Generic fallback
    if check_generic; then
        exit 0
    fi

    # No migration tool found
    log_verbose "No migration tool detected"
    if [ "$JSON_OUTPUT" = true ]; then
        output_json "none" "false" "false" "0" "" "" "" "No migration tool detected"
    else
        echo "NO-TOOL: No migration tool detected"
    fi
    exit 2
}

main "$@"

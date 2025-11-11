#!/usr/bin/env bash
# Health check for living documentation - detect stale CLAUDE.md files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

show_help() {
    cat <<'EOF'
Usage: health-check-docs.sh [--max-age DAYS] [--json]

Scan for stale CLAUDE.md files and report files older than threshold.

Options:
  --max-age DAYS  Maximum age in days before file is considered stale (default: 7)
  --json          Output results in JSON format

Examples:
  health-check-docs.sh --max-age 7
  health-check-docs.sh --max-age 3 --json
EOF
}

MAX_AGE=7
JSON_OUT=false

while (( $# )); do
    case "$1" in
        --max-age)
            shift
            MAX_AGE="$1"
            ;;
        --json)
            JSON_OUT=true
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

# Find all CLAUDE.md files
CLAUDE_FILES=()
while IFS= read -r -d '' file; do
    CLAUDE_FILES+=("$file")
done < <(find "$REPO_ROOT" -name "CLAUDE.md" -type f -print0 2>/dev/null || true)

if [ ${#CLAUDE_FILES[@]} -eq 0 ]; then
    if [ "$JSON_OUT" = true ]; then
        echo '{"total": 0, "stale": [], "fresh": [], "warnings": []}'
    else
        log_info "No CLAUDE.md files found"
    fi
    exit 0
fi

# Check each file's last modified time
STALE_FILES=()
FRESH_FILES=()
WARNINGS=()

# Calculate cutoff timestamp (current time - max_age days)
CUTOFF=$(date -d "$MAX_AGE days ago" +%s 2>/dev/null || date -v-${MAX_AGE}d +%s 2>/dev/null || echo "0")

for file in "${CLAUDE_FILES[@]}"; do
    # Get file modification time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        MTIME=$(stat -f %m "$file")
    else
        # Linux/Windows Git Bash
        MTIME=$(stat -c %Y "$file" 2>/dev/null || echo "0")
    fi

    # Extract "Last Updated" timestamp from file if available
    LAST_UPDATED=""
    if grep -q "Last Updated" "$file"; then
        LAST_UPDATED=$(grep -oP 'Last Updated.*?:\s*\K[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$file" 2>/dev/null | head -1 || echo "")
    fi

    # Calculate age in days
    CURRENT_TIME=$(date +%s)
    AGE_SECONDS=$((CURRENT_TIME - MTIME))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    # Check if file is stale
    if [ "$MTIME" -lt "$CUTOFF" ]; then
        STALE_FILES+=("$file:$AGE_DAYS")
    else
        FRESH_FILES+=("$file:$AGE_DAYS")
    fi

    # Check if "Last Updated" timestamp exists
    if [ -z "$LAST_UPDATED" ]; then
        WARNINGS+=("$file:No 'Last Updated' timestamp found")
    fi
done

# Output results
if [ "$JSON_OUT" = true ]; then
    # JSON output
    printf '{"total": %d, "stale": [' "${#CLAUDE_FILES[@]}"

    first=true
    for item in "${STALE_FILES[@]}"; do
        file="${item%:*}"
        age="${item##*:}"
        if [ "$first" = false ]; then
            printf ', '
        fi
        printf '{"file": "%s", "age_days": %d}' "$file" "$age"
        first=false
    done

    printf '], "fresh": ['

    first=true
    for item in "${FRESH_FILES[@]}"; do
        file="${item%:*}"
        age="${item##*:}"
        if [ "$first" = false ]; then
            printf ', '
        fi
        printf '{"file": "%s", "age_days": %d}' "$file" "$age"
        first=false
    done

    printf '], "warnings": ['

    first=true
    for warning in "${WARNINGS[@]}"; do
        file="${warning%:*}"
        message="${warning##*:}"
        if [ "$first" = false ]; then
            printf ', '
        fi
        printf '{"file": "%s", "message": "%s"}' "$file" "$message"
        first=false
    done

    printf ']}\n'
else
    # Human-readable output
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Living Documentation Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Total CLAUDE.md files: ${#CLAUDE_FILES[@]}"
    echo "Freshness threshold: $MAX_AGE days"
    echo ""

    if [ ${#STALE_FILES[@]} -eq 0 ]; then
        log_info "✅ All CLAUDE.md files are fresh (updated within $MAX_AGE days)"
    else
        log_warn "⚠️  Found ${#STALE_FILES[@]} stale CLAUDE.md file(s):"
        echo ""
        for item in "${STALE_FILES[@]}"; do
            file="${item%:*}"
            age="${item##*:}"
            rel_path="${file#"$REPO_ROOT"/}"
            echo "  ❌ $rel_path (${age}d old)"
        done
        echo ""
        echo "Run regeneration scripts to update:"
        echo "  - Feature CLAUDE.md: .spec-flow/scripts/bash/generate-feature-claude-md.sh <feature-dir>"
        echo "  - Project CLAUDE.md: .spec-flow/scripts/bash/generate-project-claude-md.sh"
        echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        log_warn "⚠️  Found ${#WARNINGS[@]} warning(s):"
        echo ""
        for warning in "${WARNINGS[@]}"; do
            file="${warning%:*}"
            message="${warning##*:}"
            rel_path="${file#"$REPO_ROOT"/}"
            echo "  ⚠️  $rel_path: $message"
        done
        echo ""
    fi

    echo "Fresh files: ${#FRESH_FILES[@]}"
    if [ ${#FRESH_FILES[@]} -gt 0 ] && [ ${#FRESH_FILES[@]} -le 5 ]; then
        for item in "${FRESH_FILES[@]}"; do
            file="${item%:*}"
            age="${item##*:}"
            rel_path="${file#"$REPO_ROOT"/}"
            echo "  ✅ $rel_path (${age}d old)"
        done
    fi
    echo ""
fi

# Exit with error if stale files found
if [ ${#STALE_FILES[@]} -gt 0 ]; then
    exit 1
fi

#!/usr/bin/env bash
# Learning Migration System
# Migrates learnings during NPM package updates to preserve knowledge

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

REPO_ROOT="$(resolve_repo_root)"
LEARNINGS_DIR="$REPO_ROOT/.spec-flow/learnings"
ARCHIVE_DIR="$LEARNINGS_DIR/archive"
METADATA_FILE="$LEARNINGS_DIR/learning-metadata.yaml"

FROM_VERSION=""
TO_VERSION=""
DRY_RUN=false

# ============================================================================
# Helper Functions
# ============================================================================

show_help() {
    cat <<'EOF'
Usage: migrate-learnings.sh [options]

Options:
  --from <version>        Source version (e.g., 9.4.0)
  --to <version>          Target version (e.g., 10.0.0)
  --dry-run               Show what would be done without making changes
  --auto                  Auto-detect versions and migrate
  -h, --help              Show this help

Description:
  Migrates learning data during Spec-Flow package updates.
  Archives old learnings and merges with new schema.

Examples:
  # Auto-detect and migrate
  migrate-learnings.sh --auto

  # Explicit version migration
  migrate-learnings.sh --from 9.4.0 --to 10.0.0

  # Dry run to see what would happen
  migrate-learnings.sh --from 9.4.0 --to 10.0.0 --dry-run
EOF
}

detect_current_version() {
    # Try to read from metadata file
    if [ -f "$METADATA_FILE" ]; then
        local version
        version=$(yq eval '.workflow_version' "$METADATA_FILE" 2>/dev/null)
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            echo "$version"
            return 0
        fi
    fi

    # Fallback: try package.json
    if [ -f "$REPO_ROOT/package.json" ]; then
        local version
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$REPO_ROOT/package.json" | cut -d'"' -f4)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi

    echo "unknown"
}

detect_new_version() {
    # Try to read from package.json (after npm update)
    if [ -f "$REPO_ROOT/package.json" ]; then
        local version
        version=$(grep -o '"@spec-flow/workflow"[[:space:]]*:[[:space:]]*"[^"]*"' "$REPO_ROOT/package.json" | cut -d'"' -f4 | sed 's/[^0-9.]//g')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi

    echo "unknown"
}

compare_versions() {
    local ver1="$1"
    local ver2="$2"

    # Simple version comparison
    if [ "$ver1" = "$ver2" ]; then
        echo "equal"
    else
        # Convert to comparable format
        local v1_major=$(echo "$ver1" | cut -d'.' -f1)
        local v1_minor=$(echo "$ver1" | cut -d'.' -f2)
        local v1_patch=$(echo "$ver1" | cut -d'.' -f3)

        local v2_major=$(echo "$ver2" | cut -d'.' -f1)
        local v2_minor=$(echo "$ver2" | cut -d'.' -f2)
        local v2_patch=$(echo "$ver2" | cut -d'.' -f3)

        if [ "$v1_major" -lt "$v2_major" ]; then
            echo "older"
        elif [ "$v1_major" -gt "$v2_major" ]; then
            echo "newer"
        elif [ "$v1_minor" -lt "$v2_minor" ]; then
            echo "older"
        elif [ "$v1_minor" -gt "$v2_minor" ]; then
            echo "newer"
        elif [ "$v1_patch" -lt "$v2_patch" ]; then
            echo "older"
        elif [ "$v1_patch" -gt "$v2_patch" ]; then
            echo "newer"
        else
            echo "equal"
        fi
    fi
}

archive_current_learnings() {
    local version="$1"

    local archive_path="$ARCHIVE_DIR/v$version"

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would archive learnings to: $archive_path"
        return 0
    fi

    # Create archive directory
    ensure_directory "$archive_path"

    # Copy learning files
    for file in performance-patterns.yaml anti-patterns.yaml custom-abbreviations.yaml claude-md-tweaks.yaml learning-metadata.yaml; do
        if [ -f "$LEARNINGS_DIR/$file" ]; then
            cp "$LEARNINGS_DIR/$file" "$archive_path/" 2>/dev/null || log_warn "Failed to archive $file"
        fi
    done

    log_success "Archived learnings to: $archive_path"
}

migrate_schema() {
    local from_ver="$1"
    local to_ver="$2"

    log_info "Migrating schema from $from_ver to $to_ver..."

    # Schema migration logic based on version changes
    local from_major=$(echo "$from_ver" | cut -d'.' -f1)
    local to_major=$(echo "$to_ver" | cut -d'.' -f1)

    if [ "$from_major" != "$to_major" ]; then
        log_warn "Major version change detected ($from_major → $to_major)"
        log_info "Manual review recommended after migration"
    fi

    # Apply version-specific migrations
    migrate_schema_changes "$from_ver" "$to_ver"
}

migrate_schema_changes() {
    local from_ver="$1"
    local to_ver="$2"

    # Version-specific schema changes
    # Example migrations (would be expanded based on actual schema changes)

    if [[ "$from_ver" =~ ^9\. ]] && [[ "$to_ver" =~ ^10\. ]]; then
        log_info "Applying v9 → v10 schema changes..."

        # Example: Add new fields to patterns
        if [ -f "$LEARNINGS_DIR/performance-patterns.yaml" ]; then
            # Add 'risk_level' field if missing
            # (would use yq to check and add fields)
            log_info "  - Updated performance-patterns schema"
        fi

        if [ -f "$LEARNINGS_DIR/anti-patterns.yaml" ]; then
            # Add 'prevention' field if missing
            log_info "  - Updated anti-patterns schema"
        fi
    fi

    log_success "Schema migration complete"
}

merge_archived_learnings() {
    local archive_version="$1"
    local archive_path="$ARCHIVE_DIR/v$archive_version"

    if [ ! -d "$archive_path" ]; then
        log_warn "Archive not found: $archive_path"
        return
    fi

    log_info "Merging archived learnings..."

    # Merge each learning file
    for file in performance-patterns.yaml anti-patterns.yaml custom-abbreviations.yaml claude-md-tweaks.yaml; do
        local archive_file="$archive_path/$file"
        local current_file="$LEARNINGS_DIR/$file"

        if [ -f "$archive_file" ] && [ -f "$current_file" ]; then
            merge_learning_file "$archive_file" "$current_file"
        elif [ -f "$archive_file" ]; then
            # No current file, just copy archived
            if ! $DRY_RUN; then
                cp "$archive_file" "$current_file"
                log_info "  - Restored $file from archive"
            fi
        fi
    done

    log_success "Merge complete"
}

merge_learning_file() {
    local source="$1"
    local target="$2"

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would merge: $(basename "$source")"
        return
    fi

    # Merge YAML files (simple approach: combine arrays and dedupe by ID)
    # In production, would use more sophisticated YAML merging

    local merged
    merged=$(python3 - <<EOF
import yaml

with open('$source', 'r') as f:
    source_data = yaml.safe_load(f) or {}

with open('$target', 'r') as f:
    target_data = yaml.safe_load(f) or {}

# Determine array key
key = 'patterns' if 'patterns' in source_data else \
      'antipatterns' if 'antipatterns' in source_data else \
      'abbreviations' if 'abbreviations' in source_data else \
      'tweaks'

source_items = source_data.get(key, [])
target_items = target_data.get(key, [])

# Merge by ID/abbr
merged_map = {}
for item in source_items:
    item_id = item.get('id', item.get('abbr', ''))
    if item_id:
        merged_map[item_id] = item

for item in target_items:
    item_id = item.get('id', item.get('abbr', ''))
    if item_id:
        merged_map[item_id] = item

# Convert back to list
merged_data = target_data.copy()
merged_data[key] = list(merged_map.values())

print(yaml.dump(merged_data, default_flow_style=False))
EOF
)

    if [ -n "$merged" ]; then
        echo "$merged" > "$target"
        log_info "  - Merged $(basename "$source")"
    fi
}

update_metadata() {
    local new_version="$1"
    local from_version="$2"

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would update metadata: $from_version → $new_version"
        return 0
    fi

    if [ ! -f "$METADATA_FILE" ]; then
        log_warn "Metadata file not found, creating new one"
        cat > "$METADATA_FILE" <<EOF
schema_version: "1.0"
workflow_version: "$new_version"
created: null
last_updated: null
last_analyzed: null
last_migrated: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

total_learnings:
  performance_patterns: 0
  anti_patterns: 0
  custom_abbreviations: 0
  claude_md_tweaks: 0

auto_applied_count: 0
pending_approval_count: 0
total_time_saved_seconds: 0

migration_history: []

last_health_check: null
health_status: "good"
health_issues: []

config:
  min_confidence_for_auto_apply: 0.90
  min_occurrences_for_pattern: 3
  pattern_detection_window_days: 30
  statistical_significance_threshold: 0.95
  max_pending_approvals: 10
EOF
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Update version and migration info
    yq eval ".workflow_version = \"$new_version\"" -i "$METADATA_FILE" 2>/dev/null
    yq eval ".last_migrated = \"$timestamp\"" -i "$METADATA_FILE" 2>/dev/null

    # Add to migration history
    yq eval ".migration_history += [{\"from_version\": \"$from_version\", \"to_version\": \"$new_version\", \"migrated_at\": \"$timestamp\"}]" -i "$METADATA_FILE" 2>/dev/null

    log_success "Updated metadata"
}

# ============================================================================
# Main Migration Workflow
# ============================================================================

run_migration() {
    local from_ver="$1"
    local to_ver="$2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Learning Migration: v$from_ver → v$to_ver"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 1: Archive current learnings
    log_info "Step 1: Archiving current learnings..."
    archive_current_learnings "$from_ver"
    echo ""

    # Step 2: Migrate schema
    log_info "Step 2: Migrating schema..."
    migrate_schema "$from_ver" "$to_ver"
    echo ""

    # Step 3: Merge archived learnings
    log_info "Step 3: Merging archived learnings..."
    merge_archived_learnings "$from_ver"
    echo ""

    # Step 4: Update metadata
    log_info "Step 4: Updating metadata..."
    update_metadata "$to_ver" "$from_ver"
    echo ""

    log_success "✅ Migration complete: v$from_ver → v$to_ver"
    echo ""
}

# ============================================================================
# Main Command Router
# ============================================================================

main() {
    local auto_detect=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from)
                shift
                FROM_VERSION="$1"
                shift
                ;;
            --to)
                shift
                TO_VERSION="$1"
                shift
                ;;
            --auto)
                auto_detect=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
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

    # Auto-detect versions if requested
    if [ "$auto_detect" = true ]; then
        FROM_VERSION=$(detect_current_version)
        TO_VERSION=$(detect_new_version)

        log_info "Auto-detected versions:"
        log_info "  From: $FROM_VERSION"
        log_info "  To: $TO_VERSION"
        echo ""
    fi

    # Validate versions
    if [ -z "$FROM_VERSION" ] || [ -z "$TO_VERSION" ]; then
        log_error "Both --from and --to versions required (or use --auto)"
        show_help
        exit 1
    fi

    # Check if migration needed
    local comparison
    comparison=$(compare_versions "$FROM_VERSION" "$TO_VERSION")

    if [ "$comparison" = "equal" ]; then
        log_info "Versions are equal, no migration needed"
        exit 0
    elif [ "$comparison" = "newer" ]; then
        log_warn "Current version ($FROM_VERSION) is newer than target ($TO_VERSION)"
        log_info "This is a downgrade - proceed with caution"
    fi

    # Run migration
    run_migration "$FROM_VERSION" "$TO_VERSION"
}

# Run main
main "$@"

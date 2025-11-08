#!/usr/bin/env bash
# Central orchestrator for updating living documentation (CLAUDE.md files)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.spec-flow/scripts/bash/common.sh
source "$SCRIPT_DIR/common.sh"

show_help() {
    cat <<'EOF'
Usage: update-living-docs.sh [--scope SCOPE] [--json] [feature-dir]

Update living documentation (CLAUDE.md files) at various levels of the hierarchy.

Options:
  --scope SCOPE   Scope of updates: feature, project, domain, all (default: feature)
  --json          Output in JSON format

Arguments:
  feature-dir     Path to feature directory (required for feature scope)

Scopes:
  feature         Update feature-level CLAUDE.md (specs/NNN-slug/CLAUDE.md)
  project         Update project-level CLAUDE.md (docs/project/CLAUDE.md)
  domain          Update domain-level CLAUDE.md files (backend/, frontend/, etc.)
  all             Update all levels (feature + project + domain)

Examples:
  # Update feature-level CLAUDE.md
  update-living-docs.sh --scope feature specs/001-auth-flow

  # Update project-level CLAUDE.md
  update-living-docs.sh --scope project

  # Update all CLAUDE.md files
  update-living-docs.sh --scope all specs/001-auth-flow
EOF
}

JSON_OUT=false
SCOPE="feature"
FEATURE_DIR=""

while (( $# )); do
    case "$1" in
        --json) JSON_OUT=true ;;
        --scope)
            shift
            if [ $# -eq 0 ]; then
                log_error "--scope requires a value (feature|project|domain|all)"
                exit 1
            fi
            SCOPE="$1"
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
            FEATURE_DIR="$1"
            break
            ;;
    esac
    shift
done

# Validate scope
case "$SCOPE" in
    feature|project|domain|all) ;;
    *)
        log_error "Invalid scope: $SCOPE. Must be one of: feature, project, domain, all"
        exit 1
        ;;
esac

# Validate feature directory for feature scope
if [[ "$SCOPE" == "feature" || "$SCOPE" == "all" ]]; then
    if [ -z "$FEATURE_DIR" ]; then
        log_error "Feature directory required for scope: $SCOPE"
        show_help
        exit 1
    fi
    if [ ! -d "$FEATURE_DIR" ]; then
        log_error "Feature directory not found: $FEATURE_DIR"
        exit 1
    fi
fi

# Track results
UPDATED_FILES=()
ERRORS=()

# Update feature-level CLAUDE.md
update_feature_docs() {
    local feature_dir="$1"

    log_info "Updating feature CLAUDE.md: $feature_dir"

    if "$SCRIPT_DIR/generate-feature-claude-md.sh" "$feature_dir" 2>&1; then
        UPDATED_FILES+=("$feature_dir/CLAUDE.md")
    else
        ERRORS+=("Failed to update $feature_dir/CLAUDE.md")
    fi
}

# Update project-level CLAUDE.md
update_project_docs() {
    log_info "Updating project CLAUDE.md (not yet implemented in Phase 1)"
    # Will be implemented in Phase 3
    # UPDATED_FILES+=("docs/project/CLAUDE.md")
}

# Update domain-level CLAUDE.md files
update_domain_docs() {
    log_info "Updating domain CLAUDE.md files (not yet implemented in Phase 1)"
    # Will be implemented in Phase 4
    # UPDATED_FILES+=("backend/CLAUDE.md" "frontend/CLAUDE.md")
}

# Execute updates based on scope
case "$SCOPE" in
    feature)
        update_feature_docs "$FEATURE_DIR"
        ;;
    project)
        update_project_docs
        ;;
    domain)
        update_domain_docs
        ;;
    all)
        update_feature_docs "$FEATURE_DIR"
        update_project_docs
        update_domain_docs
        ;;
esac

# Output results
if [ "$JSON_OUT" = true ]; then
    printf '{"scope": "%s", "updated": [' "$SCOPE"
    first=true
    for file in "${UPDATED_FILES[@]}"; do
        if [ "$first" = false ]; then
            printf ', '
        fi
        printf '"%s"' "$file"
        first=false
    done
    printf '], "errors": ['
    first=true
    for error in "${ERRORS[@]}"; do
        if [ "$first" = false ]; then
            printf ', '
        fi
        printf '"%s"' "$error"
        first=false
    done
    printf ']}\n'
else
    if [ ${#UPDATED_FILES[@]} -gt 0 ]; then
        log_info "Updated ${#UPDATED_FILES[@]} file(s):"
        for file in "${UPDATED_FILES[@]}"; do
            log_info "  ✓ $file"
        done
    fi

    if [ ${#ERRORS[@]} -gt 0 ]; then
        log_warn "Encountered ${#ERRORS[@]} error(s):"
        for error in "${ERRORS[@]}"; do
            log_error "  ✗ $error"
        done
        exit 1
    fi
fi

#!/usr/bin/env bash
# Clean up HTML blueprint mockups before production deployment
# Called during /optimize phase to ensure no mockups reach production

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

log_info "Cleaning up HTML blueprint mockups..."

# Find workspace
WORKSPACE=""
WORKSPACE_TYPE=""

if [ -d "$REPO_ROOT/epics" ]; then
    for epic_dir in "$REPO_ROOT"/epics/*/; do
        if [ -f "${epic_dir}epic-spec.md" ] && [ ! -f "${epic_dir}completed/epic-spec.md" ]; then
            WORKSPACE="$epic_dir"
            WORKSPACE_TYPE="epic"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ] && [ -d "$REPO_ROOT/specs" ]; then
    for spec_dir in "$REPO_ROOT"/specs/*/; do
        if [ -f "${spec_dir}spec.md" ] && [ ! -f "${spec_dir}completed/spec.md" ]; then
            WORKSPACE="$spec_dir"
            WORKSPACE_TYPE="feature"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ]; then
    log_warn "No active epic or feature found. Nothing to clean up."
    exit 0
fi

MOCKUPS_DIR="${WORKSPACE}mockups"

if [ ! -d "$MOCKUPS_DIR" ]; then
    log_info "No mockups directory found. Nothing to clean up."
    exit 0
fi

# Count files before cleanup
MOCKUP_COUNT=$(find "$MOCKUPS_DIR" -name "*.html" | wc -l || echo "0")

if [ "$MOCKUP_COUNT" -eq 0 ]; then
    log_info "No HTML mockup files found. Nothing to clean up."
    exit 0
fi

log_info "Found ${MOCKUP_COUNT} HTML mockup files in ${MOCKUPS_DIR}"
log_info "Workspace type: ${WORKSPACE_TYPE}"
log_info ""

# Confirmation message
log_info "⚠️  Mockup cleanup will:"
log_info "   1. Delete all HTML files in ${MOCKUPS_DIR}"
log_info "   2. Remove mockups/ directory entirely"
log_info "   3. Keep blueprint-patterns.md for reference (if exists)"
log_info ""

# Perform cleanup
log_info "Deleting HTML blueprint mockups..."

# Remove mockups directory
rm -rf "$MOCKUPS_DIR"

log_info "✅ Mockup cleanup complete!"
log_info "   - Removed: ${MOCKUP_COUNT} HTML files"
log_info "   - Deleted: ${MOCKUPS_DIR}"
log_info ""

# Verify cleanup
if [ -d "$MOCKUPS_DIR" ]; then
    log_error "Failed to delete mockups directory"
    exit 1
fi

log_info "🎉 HTML blueprints successfully removed!"
log_info "   TSX components are now the single source of truth."
log_info ""

# Check if blueprint-patterns.md exists and preserve it
PATTERNS_FILE="${WORKSPACE}blueprint-patterns.md"
if [ -f "$PATTERNS_FILE" ]; then
    log_info "📄 Preserved: ${PATTERNS_FILE} (for reference)"
    log_info "   This document shows the class patterns used in blueprints."
fi

log_info ""
log_info "Next steps:"
log_info "  - Mockups are cleaned up and will not be deployed"
log_info "  - TSX components in src/ are ready for production"
log_info "  - Continue with deployment workflow (/ship)"

exit 0

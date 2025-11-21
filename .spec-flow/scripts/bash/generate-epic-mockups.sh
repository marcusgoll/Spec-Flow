#!/usr/bin/env bash
# Generate epic overview HTML blueprint after /plan phase
# Called automatically when Frontend subsystem detected in epic-spec.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

log_info "Generating epic HTML blueprints..."

# Find epic workspace
EPIC_WORKSPACE=""
for epic_dir in "$REPO_ROOT"/epics/*/; do
    if [ -f "${epic_dir}epic-spec.md" ] && [ ! -f "${epic_dir}completed/epic-spec.md" ]; then
        EPIC_WORKSPACE="$epic_dir"
        break
    fi
done

if [ -z "$EPIC_WORKSPACE" ]; then
    log_error "No active epic found. Run /epic first."
    exit 1
fi

EPIC_SPEC="${EPIC_WORKSPACE}epic-spec.md"
PLAN_FILE="${EPIC_WORKSPACE}plan.md"

# Check if Frontend subsystem exists
if ! grep -q -i "frontend\|ui\|react\|next\.js\|web interface" "$EPIC_SPEC"; then
    log_info "No Frontend subsystem detected. Skipping mockup generation."
    exit 0
fi

log_info "Frontend subsystem detected. Generating epic overview blueprint..."

# Create mockups directory
MOCKUPS_DIR="${EPIC_WORKSPACE}mockups"
mkdir -p "$MOCKUPS_DIR"

# Extract epic metadata
EPIC_NAME=$(grep -m 1 "^# " "$EPIC_SPEC" | sed 's/^# //' || echo "Untitled Epic")
EPIC_DESCRIPTION=$(grep -A 5 "## Goal" "$EPIC_SPEC" | tail -n +2 | head -n 1 || echo "Epic description")

# Count sprints from plan.md if exists
SPRINT_COUNT="TBD"
if [ -f "$PLAN_FILE" ]; then
    SPRINT_COUNT=$(grep -c "^### Sprint [0-9]" "$PLAN_FILE" || echo "TBD")
fi

# Extract epic flow from plan.md or epic-spec.md
EPIC_FLOW="Epic flow diagram will be populated during sprint planning"
if [ -f "$PLAN_FILE" ]; then
    # Try to extract user flow section
    if grep -q "## User Flow\|## Epic Flow" "$PLAN_FILE"; then
        EPIC_FLOW=$(sed -n '/## User Flow/,/^##/p' "$PLAN_FILE" | sed '1d;$d' || echo "$EPIC_FLOW")
    fi
fi

# Generate epic-overview.html from template
TEMPLATE="${REPO_ROOT}/.spec-flow/templates/mockups/epic-overview.html"
OVERVIEW_FILE="${MOCKUPS_DIR}/epic-overview.html"

if [ ! -f "$TEMPLATE" ]; then
    log_error "Template not found: $TEMPLATE"
    exit 1
fi

# Copy template and replace placeholders
cp "$TEMPLATE" "$OVERVIEW_FILE"

# Replace placeholders
sed -i "s/\[EPIC_NAME\]/${EPIC_NAME}/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[EPIC_NAME\]/${EPIC_NAME}/g" "$OVERVIEW_FILE"

sed -i "s/\[EPIC_DESCRIPTION\]/${EPIC_DESCRIPTION}/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[EPIC_DESCRIPTION\]/${EPIC_DESCRIPTION}/g" "$OVERVIEW_FILE"

sed -i "s/\[SPRINT_COUNT\]/${SPRINT_COUNT}/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[SPRINT_COUNT\]/${SPRINT_COUNT}/g" "$OVERVIEW_FILE"

sed -i "s/\[SCREEN_COUNT\]/TBD/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[SCREEN_COUNT\]/TBD/g" "$OVERVIEW_FILE"

# Replace flow diagram
EPIC_FLOW_ESCAPED=$(printf '%s\n' "$EPIC_FLOW" | sed 's/[\/&]/\\&/g')
sed -i "s/\[EPIC_FLOW_DIAGRAM\]/${EPIC_FLOW_ESCAPED}/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[EPIC_FLOW_DIAGRAM\]/${EPIC_FLOW_ESCAPED}/g" "$OVERVIEW_FILE"

# Placeholder for sprint sections (will be populated by generate-sprint-mockups.sh)
sed -i "s/\[SPRINT_SECTIONS\]/<!-- Sprint sections will be added during \/tasks phase -->/g" "$OVERVIEW_FILE" 2>/dev/null || \
    sed -i '' "s/\[SPRINT_SECTIONS\]/<!-- Sprint sections will be added during \/tasks phase -->/g" "$OVERVIEW_FILE"

log_info "✅ Epic overview blueprint created: ${MOCKUPS_DIR}/epic-overview.html"
log_info ""
log_info "Next steps:"
log_info "  1. Run /tasks to generate sprint breakdowns and screen mockups"
log_info "  2. Sprint mockups will be added to mockups/sprint-N/ folders"
log_info "  3. Iterate designs by editing HTML files directly (refresh browser to preview)"
log_info "  4. During /implement-epic, you'll be prompted to approve blueprints"
log_info "  5. Approved blueprints will be converted to TSX components"
log_info ""
log_info "💡 Tip: Open ${MOCKUPS_DIR}/epic-overview.html in your browser to start designing"

exit 0

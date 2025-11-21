#!/usr/bin/env bash
# Generate sprint-level HTML blueprints during /tasks phase
# Creates individual screen mockups for each sprint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

log_info "Generating sprint HTML blueprints..."

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

MOCKUPS_DIR="${EPIC_WORKSPACE}mockups"
SPRINT_PLAN="${EPIC_WORKSPACE}sprint-plan.md"
EPIC_SPEC="${EPIC_WORKSPACE}epic-spec.md"
OVERVIEW_FILE="${MOCKUPS_DIR}/epic-overview.html"

# Check if mockups directory exists
if [ ! -d "$MOCKUPS_DIR" ]; then
    log_warn "Mockups directory not found. Run generate-epic-mockups.sh first."
    exit 1
fi

# Check if sprint-plan.md exists
if [ ! -f "$SPRINT_PLAN" ]; then
    log_warn "sprint-plan.md not found. This script should run after /tasks phase."
    exit 1
fi

# Extract epic name
EPIC_NAME=$(grep -m 1 "^# " "$EPIC_SPEC" | sed 's/^# //' || echo "Untitled Epic")

# Parse sprint-plan.md to identify sprints and screens
CURRENT_SPRINT=""
SCREEN_COUNTER=1
SPRINT_SECTIONS_HTML=""

# Template paths
SCREEN_TEMPLATE="${REPO_ROOT}/.spec-flow/templates/mockups/sprint-screen.html"

if [ ! -f "$SCREEN_TEMPLATE" ]; then
    log_error "Screen template not found: $SCREEN_TEMPLATE"
    exit 1
fi

# Parse sprint-plan.md
while IFS= read -r line; do
    # Detect sprint headers (e.g., "### Sprint 1: Authentication")
    if echo "$line" | grep -q "^### Sprint [0-9]"; then
        SPRINT_NUMBER=$(echo "$line" | grep -o "Sprint [0-9]\+" | grep -o "[0-9]\+")
        SPRINT_NAME=$(echo "$line" | sed "s/^### Sprint $SPRINT_NUMBER: //" | sed 's/ *$//')
        CURRENT_SPRINT="$SPRINT_NUMBER"

        # Create sprint directory
        SPRINT_DIR="${MOCKUPS_DIR}/sprint-${SPRINT_NUMBER}"
        mkdir -p "$SPRINT_DIR"

        log_info "Processing Sprint ${SPRINT_NUMBER}: ${SPRINT_NAME}..."

        # Start HTML for this sprint section
        SPRINT_SECTIONS_HTML+="
    <div class=\"sprint-section\" id=\"sprint-${SPRINT_NUMBER}\">
      <div class=\"sprint-header\">
        <h3>Sprint ${SPRINT_NUMBER}: ${SPRINT_NAME}</h3>
        <span class=\"sprint-badge\">Screens: TBD</span>
      </div>
      <div class=\"screens-grid\">
"
        continue
    fi

    # Detect screen/component items (e.g., "- Login screen")
    if [ -n "$CURRENT_SPRINT" ] && echo "$line" | grep -q "^\- .*\(screen\|page\|component\|form\|view\)"; then
        # Extract screen name
        SCREEN_NAME=$(echo "$line" | sed 's/^- //' | sed 's/ *$//')
        SCREEN_SLUG=$(echo "$SCREEN_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
        SCREEN_FILE="screen-$(printf "%02d" $SCREEN_COUNTER)-${SCREEN_SLUG}.html"
        SCREEN_PATH="${MOCKUPS_DIR}/sprint-${CURRENT_SPRINT}/${SCREEN_FILE}"

        # Determine access level (simple heuristic)
        ACCESS_LEVEL="Authenticated"
        ACCESS_CLASS="authenticated"
        if echo "$SCREEN_NAME" | grep -qi "login\|signup\|register\|forgot"; then
            ACCESS_LEVEL="Public"
            ACCESS_CLASS="public"
        fi

        # Generate screen file from template
        cp "$SCREEN_TEMPLATE" "$SCREEN_PATH"

        # Replace placeholders in screen file
        sed -i "s/\[SCREEN_TITLE\]/${SCREEN_NAME}/g" "$SCREEN_PATH" 2>/dev/null || \
            sed -i '' "s/\[SCREEN_TITLE\]/${SCREEN_NAME}/g" "$SCREEN_PATH"

        sed -i "s/\[SPRINT_NUMBER\]/${CURRENT_SPRINT}/g" "$SCREEN_PATH" 2>/dev/null || \
            sed -i '' "s/\[SPRINT_NUMBER\]/${CURRENT_SPRINT}/g" "$SCREEN_PATH"

        sed -i "s/\[EPIC_NAME\]/${EPIC_NAME}/g" "$SCREEN_PATH" 2>/dev/null || \
            sed -i '' "s/\[EPIC_NAME\]/${EPIC_NAME}/g" "$SCREEN_PATH"

        log_info "  ✅ Created: sprint-${CURRENT_SPRINT}/${SCREEN_FILE}"

        # Add to sprint section HTML
        SPRINT_SECTIONS_HTML+="
        <a href=\"sprint-${CURRENT_SPRINT}/${SCREEN_FILE}\" class=\"screen-card\" tabindex=\"0\">
          <h4>$(printf "%02d" $SCREEN_COUNTER). ${SCREEN_NAME}</h4>
          <p>Blueprint for ${SCREEN_NAME} - Edit to match your design requirements</p>
          <div class=\"meta\">
            <span class=\"badge ${ACCESS_CLASS}\">${ACCESS_LEVEL}</span>
            <span>States: Success, Loading, Error, Empty</span>
          </div>
        </a>
"

        SCREEN_COUNTER=$((SCREEN_COUNTER + 1))
    fi

    # Close sprint section when next sprint or end of file
    if [ -n "$CURRENT_SPRINT" ] && echo "$line" | grep -q "^### Sprint [0-9]\|^## "; then
        SPRINT_SECTIONS_HTML+="
      </div>
    </div>
"
    fi

done < "$SPRINT_PLAN"

# Close last sprint section
if [ -n "$CURRENT_SPRINT" ]; then
    SPRINT_SECTIONS_HTML+="
      </div>
    </div>
"
fi

# Update epic-overview.html with generated sprint sections
if [ -f "$OVERVIEW_FILE" ]; then
    # Escape special characters for sed
    SPRINT_SECTIONS_ESCAPED=$(printf '%s\n' "$SPRINT_SECTIONS_HTML" | sed 's/[\/&]/\\&/g')

    sed -i "s/\[SPRINT_SECTIONS\]/${SPRINT_SECTIONS_ESCAPED}/g" "$OVERVIEW_FILE" 2>/dev/null || \
        sed -i '' "s/\[SPRINT_SECTIONS\]/${SPRINT_SECTIONS_ESCAPED}/g" "$OVERVIEW_FILE"

    # Update screen count
    TOTAL_SCREENS=$((SCREEN_COUNTER - 1))
    sed -i "s/\[SCREEN_COUNT\]/${TOTAL_SCREENS}/g" "$OVERVIEW_FILE" 2>/dev/null || \
        sed -i '' "s/\[SCREEN_COUNT\]/${TOTAL_SCREENS}/g" "$OVERVIEW_FILE"

    log_info ""
    log_info "✅ Sprint blueprints generated successfully!"
    log_info "   - Total screens: ${TOTAL_SCREENS}"
    log_info "   - Location: ${MOCKUPS_DIR}/"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Open ${MOCKUPS_DIR}/epic-overview.html in your browser"
    log_info "  2. Review and iterate on screen designs"
    log_info "  3. Edit HTML files directly (use design tokens from tokens.css)"
    log_info "  4. When ready, run /implement-epic to convert blueprints to TSX"
    log_info ""
    log_info "💡 Tip: Press 'S' key when viewing screens to cycle through states"
else
    log_warn "epic-overview.html not found. Sprint sections generated but not linked."
fi

exit 0

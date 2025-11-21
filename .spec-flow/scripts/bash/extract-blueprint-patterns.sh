#!/usr/bin/env bash
# Extract Tailwind class patterns from HTML blueprints
# Helps developers mirror blueprint designs in TSX components

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

# Find epic or feature workspace
WORKSPACE=""
if [ -d "$REPO_ROOT/epics" ]; then
    for epic_dir in "$REPO_ROOT"/epics/*/; do
        if [ -f "${epic_dir}epic-spec.md" ] && [ ! -f "${epic_dir}completed/epic-spec.md" ]; then
            WORKSPACE="$epic_dir"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ] && [ -d "$REPO_ROOT/specs" ]; then
    for spec_dir in "$REPO_ROOT"/specs/*/; do
        if [ -f "${spec_dir}spec.md" ] && [ ! -f "${spec_dir}completed/spec.md" ]; then
            WORKSPACE="$spec_dir"
            break
        fi
    done
fi

if [ -z "$WORKSPACE" ]; then
    log_error "No active epic or feature found."
    exit 1
fi

MOCKUPS_DIR="${WORKSPACE}mockups"

if [ ! -d "$MOCKUPS_DIR" ]; then
    log_error "No mockups directory found at ${MOCKUPS_DIR}"
    exit 1
fi

log_info "Extracting Tailwind class patterns from HTML blueprints..."
log_info "Workspace: ${WORKSPACE}"
log_info ""

# Output file
PATTERNS_FILE="${WORKSPACE}blueprint-patterns.md"

# Start markdown file
cat > "$PATTERNS_FILE" << 'EOF'
# Blueprint Class Patterns

This document lists the Tailwind CSS class patterns used in HTML blueprints.
Use these exact patterns when implementing TSX components to match the approved design.

## Component Patterns

EOF

# Function to extract class patterns from HTML
extract_patterns() {
    local file="$1"
    local component_name="$2"

    echo "### ${component_name}" >> "$PATTERNS_FILE"
    echo "" >> "$PATTERNS_FILE"

    # Extract classes from common patterns
    # Button classes
    if grep -q "class=\"button" "$file"; then
        echo "**Buttons:**" >> "$PATTERNS_FILE"
        grep -o 'class="button[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi

    # Card classes
    if grep -q "class=\"card" "$file"; then
        echo "**Cards:**" >> "$PATTERNS_FILE"
        grep -o 'class="card[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi

    # Form classes
    if grep -q "class=\"form-group" "$file"; then
        echo "**Forms:**" >> "$PATTERNS_FILE"
        grep -o 'class="form-group[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        grep -o '<input[^>]*class="[^"]*"' "$file" | grep -o 'class="[^"]*"' | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- Input: \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi

    # Alert classes
    if grep -q "class=\"alert" "$file"; then
        echo "**Alerts:**" >> "$PATTERNS_FILE"
        grep -o 'class="alert[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi

    # Container classes
    if grep -q "class=\"container" "$file"; then
        echo "**Containers:**" >> "$PATTERNS_FILE"
        grep -o 'class="container[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi

    # Empty state classes
    if grep -q "class=\"empty-state" "$file"; then
        echo "**Empty States:**" >> "$PATTERNS_FILE"
        grep -o 'class="empty-state[^"]*"' "$file" | sort -u | sed 's/class="//;s/"//' | while read -r pattern; do
            echo "- \`${pattern}\`" >> "$PATTERNS_FILE"
        done
        echo "" >> "$PATTERNS_FILE"
    fi
}

# Process all HTML files in mockups directory
SCREEN_COUNT=0

# Process overview file
if [ -f "${MOCKUPS_DIR}/epic-overview.html" ]; then
    extract_patterns "${MOCKUPS_DIR}/epic-overview.html" "Epic Overview"
    ((SCREEN_COUNT++))
elif [ -f "${MOCKUPS_DIR}/index.html" ]; then
    extract_patterns "${MOCKUPS_DIR}/index.html" "Feature Hub"
    ((SCREEN_COUNT++))
fi

# Process sprint screens (for epics)
if [ -d "${MOCKUPS_DIR}/sprint-1" ]; then
    for sprint_dir in "${MOCKUPS_DIR}"/sprint-*/; do
        SPRINT_NUM=$(basename "$sprint_dir" | grep -o "[0-9]\+")
        for screen_file in "${sprint_dir}"*.html; do
            if [ -f "$screen_file" ]; then
                SCREEN_NAME=$(basename "$screen_file" .html)
                extract_patterns "$screen_file" "Sprint ${SPRINT_NUM} - ${SCREEN_NAME}"
                ((SCREEN_COUNT++))
            fi
        done
    done
else
    # Process feature screens
    for screen_file in "${MOCKUPS_DIR}"/*.html; do
        if [ -f "$screen_file" ] && [ "$(basename "$screen_file")" != "index.html" ]; then
            SCREEN_NAME=$(basename "$screen_file" .html)
            extract_patterns "$screen_file" "$SCREEN_NAME"
            ((SCREEN_COUNT++))
        fi
    done
fi

# Add usage guide
cat >> "$PATTERNS_FILE" << 'EOF'

## Usage Guide

When implementing TSX components:

1. **Mirror class patterns exactly**: Use the same Tailwind classes listed above
2. **Convert to JSX syntax**: `class=""` becomes `className=""`
3. **Extract to constants**: For repeated patterns, create component variants
4. **Add TypeScript types**: Define props interfaces for component variants
5. **Preserve accessibility**: Maintain ARIA attributes and semantic HTML structure

### Example Conversion

**HTML Blueprint:**
```html
<button class="button primary">
  Submit
</button>
```

**TSX Component:**
```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = 'primary', children, onClick }: ButtonProps) {
  return (
    <button
      className={`button ${variant}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### Design Token Mapping

All CSS custom properties (e.g., `var(--color-brand-primary)`) are defined in `design/systems/tokens.css`.
Ensure these tokens are imported in your Next.js app's global CSS file.

EOF

log_info "✅ Blueprint patterns extracted successfully!"
log_info "   - Screens processed: ${SCREEN_COUNT}"
log_info "   - Output: ${PATTERNS_FILE}"
log_info ""
log_info "Next steps:"
log_info "  1. Review ${PATTERNS_FILE} for class patterns"
log_info "  2. Use these patterns when implementing TSX components"
log_info "  3. Run validate-tsx-conversion.sh after implementation to verify"
log_info ""

exit 0

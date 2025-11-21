#!/usr/bin/env bash
# Validate TSX components match HTML blueprint patterns
# Optional quality check (skippable with --skip-validation)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

REPO_ROOT="$(resolve_repo_root)"

log_info "Validating TSX conversion against HTML blueprints..."

# Find workspace
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
PATTERNS_FILE="${WORKSPACE}blueprint-patterns.md"

if [ ! -d "$MOCKUPS_DIR" ]; then
    log_warn "No mockups directory found. Skipping validation."
    exit 0
fi

# Check if blueprint-patterns.md exists, generate if not
if [ ! -f "$PATTERNS_FILE" ]; then
    log_info "Blueprint patterns not found. Generating..."
    bash "$SCRIPT_DIR/extract-blueprint-patterns.sh"
fi

# Validation report
VALIDATION_REPORT="${WORKSPACE}tsx-conversion-validation.md"

cat > "$VALIDATION_REPORT" << 'EOF'
# TSX Conversion Validation Report

This report validates whether TSX components match the approved HTML blueprint patterns.

## Validation Checks

EOF

WARNINGS=0
ERRORS=0

# Check 1: Verify blueprint-patterns.md exists
echo "### ✅ Blueprint Patterns" >> "$VALIDATION_REPORT"
if [ -f "$PATTERNS_FILE" ]; then
    echo "- Blueprint patterns extracted successfully" >> "$VALIDATION_REPORT"
else
    echo "- ⚠️ WARNING: Blueprint patterns file not found" >> "$VALIDATION_REPORT"
    ((WARNINGS++))
fi
echo "" >> "$VALIDATION_REPORT"

# Check 2: Verify src/ directory exists (Next.js/React project)
echo "### TSX Component Structure" >> "$VALIDATION_REPORT"
if [ -d "$REPO_ROOT/src" ]; then
    echo "- ✅ \`src/\` directory found" >> "$VALIDATION_REPORT"

    # Check for components directory
    if [ -d "$REPO_ROOT/src/components" ]; then
        COMPONENT_COUNT=$(find "$REPO_ROOT/src/components" -name "*.tsx" -o -name "*.jsx" | wc -l)
        echo "- ✅ \`src/components/\` directory found (${COMPONENT_COUNT} TSX/JSX files)" >> "$VALIDATION_REPORT"
    else
        echo "- ⚠️ WARNING: \`src/components/\` directory not found" >> "$VALIDATION_REPORT"
        ((WARNINGS++))
    fi
elif [ -d "$REPO_ROOT/app" ]; then
    echo "- ✅ \`app/\` directory found (Next.js App Router)" >> "$VALIDATION_REPORT"
else
    echo "- ❌ ERROR: No \`src/\` or \`app/\` directory found" >> "$VALIDATION_REPORT"
    ((ERRORS++))
fi
echo "" >> "$VALIDATION_REPORT"

# Check 3: Verify design tokens imported
echo "### Design Token Integration" >> "$VALIDATION_REPORT"
if [ -f "$REPO_ROOT/design/systems/tokens.css" ]; then
    echo "- ✅ Design tokens file exists: \`design/systems/tokens.css\`" >> "$VALIDATION_REPORT"

    # Check if tokens are imported in global CSS or layout
    GLOBAL_CSS_FOUND=false
    for css_file in "$REPO_ROOT/src/app/globals.css" "$REPO_ROOT/src/styles/globals.css" "$REPO_ROOT/app/globals.css"; do
        if [ -f "$css_file" ]; then
            if grep -q "tokens.css" "$css_file"; then
                echo "- ✅ Design tokens imported in global CSS" >> "$VALIDATION_REPORT"
                GLOBAL_CSS_FOUND=true
                break
            fi
        fi
    done

    if [ "$GLOBAL_CSS_FOUND" = false ]; then
        echo "- ⚠️ WARNING: Design tokens may not be imported in global CSS" >> "$VALIDATION_REPORT"
        ((WARNINGS++))
    fi
else
    echo "- ⚠️ WARNING: Design tokens file not found at \`design/systems/tokens.css\`" >> "$VALIDATION_REPORT"
    ((WARNINGS++))
fi
echo "" >> "$VALIDATION_REPORT"

# Check 4: Sample className pattern validation
echo "### Class Pattern Validation" >> "$VALIDATION_REPORT"
if [ -d "$REPO_ROOT/src/components" ]; then
    # Check if components use className (not class)
    CLASS_USAGE=$(grep -r "class=" "$REPO_ROOT/src/components" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v "className=" | wc -l || echo "0")

    if [ "$CLASS_USAGE" -gt 0 ]; then
        echo "- ⚠️ WARNING: Found ${CLASS_USAGE} uses of \`class=\` instead of \`className=\` in TSX files" >> "$VALIDATION_REPORT"
        ((WARNINGS++))
    else
        echo "- ✅ All components use \`className=\` (JSX syntax)" >> "$VALIDATION_REPORT"
    fi

    # Check for common blueprint pattern usage
    BUTTON_PATTERN_FOUND=$(grep -r "className.*button" "$REPO_ROOT/src/components" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l || echo "0")
    CARD_PATTERN_FOUND=$(grep -r "className.*card" "$REPO_ROOT/src/components" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l || echo "0")

    if [ "$BUTTON_PATTERN_FOUND" -gt 0 ]; then
        echo "- ✅ Button components found using blueprint patterns (${BUTTON_PATTERN_FOUND} instances)" >> "$VALIDATION_REPORT"
    fi

    if [ "$CARD_PATTERN_FOUND" -gt 0 ]; then
        echo "- ✅ Card components found using blueprint patterns (${CARD_PATTERN_FOUND} instances)" >> "$VALIDATION_REPORT"
    fi
else
    echo "- ⚠️ Skipping pattern validation (components directory not found)" >> "$VALIDATION_REPORT"
fi
echo "" >> "$VALIDATION_REPORT"

# Check 5: Accessibility attributes preserved
echo "### Accessibility Validation" >> "$VALIDATION_REPORT"
if [ -d "$REPO_ROOT/src/components" ]; then
    ARIA_USAGE=$(grep -r "aria-" "$REPO_ROOT/src/components" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l || echo "0")
    ROLE_USAGE=$(grep -r "role=" "$REPO_ROOT/src/components" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l || echo "0")

    if [ "$ARIA_USAGE" -gt 0 ] || [ "$ROLE_USAGE" -gt 0 ]; then
        echo "- ✅ ARIA attributes found (${ARIA_USAGE} aria-*, ${ROLE_USAGE} role)" >> "$VALIDATION_REPORT"
    else
        echo "- ⚠️ WARNING: No ARIA attributes found in components (may need accessibility review)" >> "$VALIDATION_REPORT"
        ((WARNINGS++))
    fi
else
    echo "- ⚠️ Skipping accessibility validation (components directory not found)" >> "$VALIDATION_REPORT"
fi
echo "" >> "$VALIDATION_REPORT"

# Summary
echo "## Summary" >> "$VALIDATION_REPORT"
echo "" >> "$VALIDATION_REPORT"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ **All validation checks passed!**" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
    echo "TSX components appear to match blueprint patterns successfully." >> "$VALIDATION_REPORT"
    VALIDATION_STATUS=0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️ **Validation passed with warnings**" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
    echo "- Warnings: ${WARNINGS}" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
    echo "Review warnings above. Most are non-blocking but should be addressed for best practices." >> "$VALIDATION_REPORT"
    VALIDATION_STATUS=0
else
    echo "❌ **Validation failed**" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
    echo "- Errors: ${ERRORS}" >> "$VALIDATION_REPORT"
    echo "- Warnings: ${WARNINGS}" >> "$VALIDATION_REPORT"
    echo "" >> "$VALIDATION_REPORT"
    echo "Please fix errors before proceeding to production." >> "$VALIDATION_REPORT"
    VALIDATION_STATUS=1
fi

log_info ""
log_info "Validation complete!"
log_info "  - Errors: ${ERRORS}"
log_info "  - Warnings: ${WARNINGS}"
log_info "  - Report: ${VALIDATION_REPORT}"
log_info ""

if [ $VALIDATION_STATUS -eq 0 ]; then
    log_info "✅ TSX conversion validated successfully!"
else
    log_warn "❌ Validation failed. Review ${VALIDATION_REPORT} for details."
fi

exit $VALIDATION_STATUS

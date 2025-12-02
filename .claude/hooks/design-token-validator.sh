#!/bin/bash
# Design Token Validator Hook
# Validates Write/Edit operations for hardcoded design values
# Behavior: Block with remediation guidance

set -e

# Read tool input from stdin
INPUT=$(cat)

# Extract file path and content
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | grep -oP '"tool_name"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

# For Write tool, extract content; for Edit tool, extract new_string
if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | grep -oP '"content"\s*:\s*"\K[^"]*' 2>/dev/null | head -1 || echo "")
elif [[ "$TOOL_NAME" == "Edit" ]]; then
    CONTENT=$(echo "$INPUT" | grep -oP '"new_string"\s*:\s*"\K[^"]*' 2>/dev/null | head -1 || echo "")
else
    echo '{"decision": "approve"}'
    exit 0
fi

# Skip if no file path
if [[ -z "$FILE_PATH" ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Only validate style-related files
if [[ ! "$FILE_PATH" =~ \.(css|scss|sass|less|tsx|jsx|ts|js|vue|svelte)$ ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Skip node_modules, dist, build, .next directories
if [[ "$FILE_PATH" =~ (node_modules|dist|build|\.next|\.cache|\.git)/ ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Skip test files
if [[ "$FILE_PATH" =~ \.(test|spec)\.(tsx?|jsx?)$ ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Skip if no content to validate
if [[ -z "$CONTENT" ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Initialize violations array
VIOLATIONS=()
FIXES=()

# Decode common escape sequences for pattern matching
DECODED_CONTENT=$(echo -e "$CONTENT" 2>/dev/null || echo "$CONTENT")

# 1. Detect hardcoded hex colors (excluding oklch which is our token format)
HEX_MATCHES=$(echo "$DECODED_CONTENT" | grep -oE '#[0-9a-fA-F]{3,8}\b' 2>/dev/null || true)
if [[ -n "$HEX_MATCHES" ]]; then
    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            VIOLATIONS+=("Hardcoded hex color: $match")
            FIXES+=("Use token: var(--brand-primary), var(--neutral-900), etc.")
        fi
    done <<< "$HEX_MATCHES"
fi

# 2. Detect rgb/rgba/hsl/hsla colors (not oklch)
COLOR_MATCHES=$(echo "$DECODED_CONTENT" | grep -oE '(rgb|rgba|hsl|hsla)\s*\([^)]+\)' 2>/dev/null || true)
if [[ -n "$COLOR_MATCHES" ]]; then
    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            VIOLATIONS+=("Hardcoded color function: $match")
            FIXES+=("Use token: var(--semantic-success), var(--semantic-error), etc.")
        fi
    done <<< "$COLOR_MATCHES"
fi

# 3. Detect arbitrary Tailwind values
ARB_MATCHES=$(echo "$DECODED_CONTENT" | grep -oE '(bg|text|border|p|m|w|h|gap|space|rounded|shadow)-\[[^\]]+\]' 2>/dev/null || true)
if [[ -n "$ARB_MATCHES" ]]; then
    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            VIOLATIONS+=("Tailwind arbitrary value: $match")
            case "$match" in
                bg-*|text-*|border-*)
                    FIXES+=("Use Tailwind token: bg-brand-primary, text-neutral-900, etc.")
                    ;;
                p-*|m-*|gap-*|space-*|w-*|h-*)
                    FIXES+=("Use spacing class: p-4 (16px), gap-6 (24px), etc.")
                    ;;
                *)
                    FIXES+=("Use design token class instead of arbitrary value")
                    ;;
            esac
        fi
    done <<< "$ARB_MATCHES"
fi

# Build response
if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Limit to first 5 violations for readability
MAX_SHOW=5
TOTAL=${#VIOLATIONS[@]}

VIOLATION_TEXT="Design Token Violations (${TOTAL} found):\\n\\n"

for i in "${!VIOLATIONS[@]}"; do
    if [[ $i -ge $MAX_SHOW ]]; then
        VIOLATION_TEXT+="... and $((TOTAL - MAX_SHOW)) more violations\\n"
        break
    fi
    VIOLATION_TEXT+="$((i + 1)). ${VIOLATIONS[$i]}\\n"
    VIOLATION_TEXT+="   Fix: ${FIXES[$i]}\\n\\n"
done

VIOLATION_TEXT+="\\n**Token Reference:**\\n"
VIOLATION_TEXT+="- Colors: var(--brand-primary), var(--semantic-error), var(--neutral-900)\\n"
VIOLATION_TEXT+="- Spacing: var(--space-1)=4px, var(--space-4)=16px, Tailwind p-4, gap-6\\n"
VIOLATION_TEXT+="- See: design/systems/tokens.css for full list"

# Escape quotes for JSON
VIOLATION_JSON=$(echo "$VIOLATION_TEXT" | sed 's/"/\\"/g')

echo "{\"decision\": \"block\", \"reason\": \"$VIOLATION_JSON\"}"

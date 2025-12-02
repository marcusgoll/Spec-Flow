#!/bin/bash
# Design System Context Injection Hook
# Injects design token reminder at session start
# Behavior: Warn if tokens missing, remind if present

set -e

# Read input from stdin
INPUT=$(cat)

# Extract current working directory
CWD=$(echo "$INPUT" | grep -oP '"cwd"\s*:\s*"\K[^"]+' 2>/dev/null || pwd)

# Check for design tokens
TOKENS_CSS="$CWD/design/systems/tokens.css"
TOKENS_JSON="$CWD/design/systems/tokens.json"

if [[ -f "$TOKENS_JSON" ]] || [[ -f "$TOKENS_CSS" ]]; then
    # Tokens exist - remind about enforcement
    read -r -d '' CONTEXT << 'EOF' || true
## Design System Active

PreToolUse hook enforcing design tokens. When writing styles:

**BLOCKED patterns:**
- Hardcoded hex: #3b82f6, #ffffff
- Color functions: rgb(), hsl()
- Arbitrary Tailwind: bg-[#xxx], p-[15px]

**Required patterns:**
- Colors: var(--brand-primary), var(--neutral-900)
- Spacing: var(--space-4), Tailwind p-4, gap-6
- See: design/systems/tokens.css
EOF
else
    # Tokens missing - warn user
    read -r -d '' CONTEXT << 'EOF' || true
## Design Tokens Not Configured

Run `/init-brand-tokens` before UI work to generate:
- design/systems/tokens.css
- design/systems/tokens.json

This enables design system enforcement hooks.
EOF
fi

# Escape for JSON
CONTEXT_ESCAPED=$(echo "$CONTEXT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Output SessionStart response
echo "{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$CONTEXT_ESCAPED\"}}"

#!/bin/bash
# CLAUDE.md Quality Validator Hook
# Deterministic validation for CLAUDE.md file quality
# Behavior: Warn-only (allows edits to proceed)

set -e

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from the tool input
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

# Only validate CLAUDE.md files
if [[ ! "$FILE_PATH" =~ CLAUDE\.md$ ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Skip if file doesn't exist yet (new file creation)
if [[ ! -f "$FILE_PATH" ]]; then
    echo '{"decision": "approve"}'
    exit 0
fi

# Initialize warnings array
WARNINGS=()

# Count lines
LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")

# Determine file type and threshold
if [[ "$FILE_PATH" =~ specs/.*/CLAUDE\.md$ ]]; then
    FILE_TYPE="feature"
    MAX_LINES=200
    WARN_LINES=100
elif [[ "$FILE_PATH" =~ /CLAUDE\.md$ ]] && [[ ! "$FILE_PATH" =~ (specs|epics)/ ]]; then
    # Check if it's a project-level or root CLAUDE.md
    if [[ "$FILE_PATH" =~ docs/project/ ]] || [[ $(dirname "$FILE_PATH") =~ /[^/]+$ ]]; then
        FILE_TYPE="project"
        MAX_LINES=300
        WARN_LINES=150
    else
        FILE_TYPE="root"
        MAX_LINES=400
        WARN_LINES=300
    fi
else
    FILE_TYPE="project"
    MAX_LINES=300
    WARN_LINES=150
fi

# Check line count
if [[ $LINE_COUNT -gt $MAX_LINES ]]; then
    WARNINGS+=("Line count ($LINE_COUNT) exceeds maximum ($MAX_LINES) for $FILE_TYPE CLAUDE.md")
elif [[ $LINE_COUNT -gt $WARN_LINES ]]; then
    WARNINGS+=("Line count ($LINE_COUNT) approaching limit ($MAX_LINES) for $FILE_TYPE CLAUDE.md")
fi

# Check for prohibited vague patterns
VAGUE_PATTERNS=(
    "should probably"
    "might want to"
    "you could"
    "consider maybe"
    "it's good to"
    "try to"
    "kind of"
    "sort of"
)

for pattern in "${VAGUE_PATTERNS[@]}"; do
    COUNT=$(grep -ic "$pattern" "$FILE_PATH" 2>/dev/null || echo "0")
    if [[ $COUNT -gt 0 ]]; then
        WARNINGS+=("Found vague language: '$pattern' ($COUNT occurrences)")
    fi
done

# Check for required sections based on file type
if [[ "$FILE_TYPE" == "root" ]]; then
    for section in "WHAT" "WHY" "HOW"; do
        if ! grep -q "## $section" "$FILE_PATH" 2>/dev/null; then
            WARNINGS+=("Missing required section: ## $section")
        fi
    done
fi

# Build response
if [[ ${#WARNINGS[@]} -eq 0 ]]; then
    echo '{"decision": "approve"}'
else
    # Join warnings with newlines
    WARNING_TEXT=$(printf '%s\n' "${WARNINGS[@]}")

    # Escape for JSON
    WARNING_JSON=$(echo "$WARNING_TEXT" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    echo "{\"decision\": \"approve\", \"systemMessage\": \"CLAUDE.md Quality Warnings:\\n$WARNING_JSON\"}"
fi

#!/bin/bash
# CLAUDE.md Comprehensive Audit Tool
# Analyzes all CLAUDE.md files for quality and provides actionable recommendations

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_ROOT_LINES=400
WARN_ROOT_LINES=300
MAX_PROJECT_LINES=300
WARN_PROJECT_LINES=150
MAX_FEATURE_LINES=200
WARN_FEATURE_LINES=100

# Prohibited patterns
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

# Strong modals (good)
STRONG_MODALS=(
    "MUST"
    "SHOULD"
    "SHALL"
    "NEVER"
    "ALWAYS"
    "DO NOT"
    "REQUIRED"
)

# Parse arguments
JSON_OUTPUT=false
VERBOSE=false
TARGET_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            TARGET_PATH="$1"
            shift
            ;;
    esac
done

# Find all CLAUDE.md files
if [[ -n "$TARGET_PATH" ]]; then
    if [[ -f "$TARGET_PATH" ]]; then
        FILES=("$TARGET_PATH")
    else
        FILES=($(find "$TARGET_PATH" -name "CLAUDE.md" -type f 2>/dev/null))
    fi
else
    FILES=($(find . -name "CLAUDE.md" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" 2>/dev/null))
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No CLAUDE.md files found."
    exit 0
fi

# Function to determine file type
get_file_type() {
    local path="$1"
    if [[ "$path" =~ specs/.*/CLAUDE\.md$ ]]; then
        echo "feature"
    elif [[ "$path" =~ epics/.*/CLAUDE\.md$ ]]; then
        echo "epic"
    elif [[ "$path" == "./CLAUDE.md" ]] || [[ "$path" == "CLAUDE.md" ]]; then
        echo "root"
    else
        echo "project"
    fi
}

# Function to calculate quality score
calculate_score() {
    local file="$1"
    local score=100
    local issues=()

    # Get file type and thresholds
    local file_type=$(get_file_type "$file")
    local max_lines warn_lines

    case $file_type in
        root)
            max_lines=$MAX_ROOT_LINES
            warn_lines=$WARN_ROOT_LINES
            ;;
        project|epic)
            max_lines=$MAX_PROJECT_LINES
            warn_lines=$WARN_PROJECT_LINES
            ;;
        feature)
            max_lines=$MAX_FEATURE_LINES
            warn_lines=$WARN_FEATURE_LINES
            ;;
    esac

    # Line count analysis (30 points)
    local line_count=$(wc -l < "$file")
    if [[ $line_count -gt $max_lines ]]; then
        score=$((score - 30))
        issues+=("CRITICAL: Line count ($line_count) exceeds maximum ($max_lines)")
    elif [[ $line_count -gt $warn_lines ]]; then
        score=$((score - 15))
        issues+=("WARNING: Line count ($line_count) approaching limit ($max_lines)")
    fi

    # Vague language detection (25 points)
    local vague_count=0
    for pattern in "${VAGUE_PATTERNS[@]}"; do
        local count=$(grep -ic "$pattern" "$file" 2>/dev/null || echo "0")
        vague_count=$((vague_count + count))
    done
    if [[ $vague_count -gt 5 ]]; then
        score=$((score - 25))
        issues+=("CRITICAL: High vague language count ($vague_count instances)")
    elif [[ $vague_count -gt 0 ]]; then
        score=$((score - (vague_count * 3)))
        issues+=("WARNING: Found $vague_count vague language instances")
    fi

    # Strong modals analysis (15 points)
    local modal_count=0
    for modal in "${STRONG_MODALS[@]}"; do
        local count=$(grep -c "$modal" "$file" 2>/dev/null || echo "0")
        modal_count=$((modal_count + count))
    done
    if [[ $modal_count -lt 3 ]]; then
        score=$((score - 10))
        issues+=("INFO: Low strong modal usage ($modal_count) - consider adding clear directives")
    fi

    # Required sections (15 points)
    if [[ "$file_type" == "root" ]]; then
        for section in "WHAT" "WHY" "HOW"; do
            if ! grep -q "## $section" "$file" 2>/dev/null; then
                score=$((score - 5))
                issues+=("WARNING: Missing required section: ## $section")
            fi
        done
    fi

    # External references (10 points) - bonus for good practice
    local ref_count=$(grep -c "\[.*\](docs/" "$file" 2>/dev/null || echo "0")
    if [[ $ref_count -gt 3 ]]; then
        # Bonus for good progressive disclosure
        score=$((score + 5))
        if [[ $score -gt 100 ]]; then score=100; fi
    fi

    # Code block ratio (5 points)
    local code_blocks=$(grep -c '```' "$file" 2>/dev/null || echo "0")
    code_blocks=$((code_blocks / 2))  # Pairs of backticks
    local code_ratio=$((code_blocks * 100 / (line_count + 1)))
    if [[ $code_ratio -gt 40 ]]; then
        score=$((score - 5))
        issues+=("INFO: High code block ratio ($code_ratio%) - may indicate reference material that should be extracted")
    fi

    # Ensure score doesn't go negative
    if [[ $score -lt 0 ]]; then score=0; fi

    echo "SCORE:$score"
    for issue in "${issues[@]}"; do
        echo "ISSUE:$issue"
    done
    echo "LINES:$line_count"
    echo "TYPE:$file_type"
    echo "VAGUE:$vague_count"
    echo "MODALS:$modal_count"
}

# Main audit loop
TOTAL_SCORE=0
FILE_COUNT=0
ALL_RESULTS=()

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    CLAUDE.md Quality Audit                     ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

for file in "${FILES[@]}"; do
    FILE_COUNT=$((FILE_COUNT + 1))

    # Run analysis
    RESULT=$(calculate_score "$file")

    # Parse results
    SCORE=$(echo "$RESULT" | grep "^SCORE:" | cut -d: -f2)
    LINES=$(echo "$RESULT" | grep "^LINES:" | cut -d: -f2)
    TYPE=$(echo "$RESULT" | grep "^TYPE:" | cut -d: -f2)
    VAGUE=$(echo "$RESULT" | grep "^VAGUE:" | cut -d: -f2)
    MODALS=$(echo "$RESULT" | grep "^MODALS:" | cut -d: -f2)
    ISSUES=$(echo "$RESULT" | grep "^ISSUE:" | cut -d: -f2-)

    TOTAL_SCORE=$((TOTAL_SCORE + SCORE))

    # Determine color based on score
    if [[ $SCORE -ge 80 ]]; then
        COLOR=$GREEN
        GRADE="A"
    elif [[ $SCORE -ge 60 ]]; then
        COLOR=$YELLOW
        GRADE="B"
    elif [[ $SCORE -ge 40 ]]; then
        COLOR=$YELLOW
        GRADE="C"
    else
        COLOR=$RED
        GRADE="F"
    fi

    echo -e "${COLOR}[$GRADE] $file${NC}"
    echo -e "    Type: $TYPE | Lines: $LINES | Score: $SCORE/100"
    echo -e "    Vague patterns: $VAGUE | Strong modals: $MODALS"

    if [[ -n "$ISSUES" ]] && [[ "$VERBOSE" == "true" ]]; then
        echo -e "    Issues:"
        echo "$ISSUES" | while read -r issue; do
            if [[ "$issue" =~ ^CRITICAL ]]; then
                echo -e "      ${RED}$issue${NC}"
            elif [[ "$issue" =~ ^WARNING ]]; then
                echo -e "      ${YELLOW}$issue${NC}"
            else
                echo -e "      ${BLUE}$issue${NC}"
            fi
        done
    fi
    echo ""
done

# Summary
AVG_SCORE=$((TOTAL_SCORE / FILE_COUNT))

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                         Summary                                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Files analyzed: $FILE_COUNT"
echo -e "  Average score:  $AVG_SCORE/100"

if [[ $AVG_SCORE -ge 80 ]]; then
    echo -e "  Overall grade:  ${GREEN}A - Excellent${NC}"
elif [[ $AVG_SCORE -ge 60 ]]; then
    echo -e "  Overall grade:  ${YELLOW}B - Good${NC}"
elif [[ $AVG_SCORE -ge 40 ]]; then
    echo -e "  Overall grade:  ${YELLOW}C - Needs Improvement${NC}"
else
    echo -e "  Overall grade:  ${RED}F - Critical Issues${NC}"
fi

echo ""
echo -e "Run with --verbose for detailed issue breakdown"
echo ""

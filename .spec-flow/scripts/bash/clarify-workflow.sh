#!/usr/bin/env bash
# Clarification Workflow - Interactive spec.md ambiguity resolution
#
# Usage:
#   clarify-workflow.sh [feature-slug]
#
# Description:
#   Analyzes spec.md for ambiguities across 10 categories, generates prioritized
#   questions, and updates spec.md atomically with each answer (git checkpoints).
#
# Exit codes:
#   0 - Success (all ambiguities resolved or session complete)
#   1 - Error (missing spec, git conflict, validation failure)
#   2 - Partial (ambiguities remain, recommend continuing)

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common utilities
source "$SCRIPT_DIR/common.sh" 2>/dev/null || true

# ============================================================================
# STEP 1: Run Prerequisite Script (discover paths)
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Discovering feature paths"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get absolute paths
if command -v pwsh &> /dev/null; then
  # Windows/PowerShell
  PREREQ_JSON=$(pwsh -File "$SCRIPT_DIR/../powershell/check-prerequisites.ps1" -Json -PathsOnly)
else
  # macOS/Linux/Git Bash
  PREREQ_JSON=$("$SCRIPT_DIR/check-prerequisites.sh" --json --paths-only)
fi

# Parse JSON for paths
FEATURE_DIR=$(echo "$PREREQ_JSON" | jq -r '.FEATURE_DIR')
FEATURE_SPEC=$(echo "$PREREQ_JSON" | jq -r '.FEATURE_SPEC')

# Validate spec exists
if [ ! -f "$FEATURE_SPEC" ]; then
  echo "❌ Missing: spec.md"
  echo "Run: /specify first"
  echo ""
  echo "Available specs:"
  ls -1 specs/*/spec.md 2>/dev/null | sed 's|specs/||;s|/spec.md||' || echo "  (none)"
  exit 1
fi

# ============================================================================
# STEP 2: Load Spec + Checkpoint
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Loading specification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $(basename "$FEATURE_DIR")"
echo "Spec: $FEATURE_SPEC"
echo ""

# Create minimal, safe checkpoint (no stash of unrelated files)
git add "$FEATURE_SPEC" 2>/dev/null || true
git commit -m "clarify: checkpoint before session" --no-verify 2>/dev/null || true

# ============================================================================
# STEP 3: Fast Coverage Scan (10-Category Taxonomy)
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔬 Scanning spec coverage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CATEGORY_1_STATUS="Clear"   # Functional Scope & Behavior
CATEGORY_2_STATUS="Clear"   # Domain & Data Model
CATEGORY_3_STATUS="Clear"   # Interaction & UX Flow
CATEGORY_4_STATUS="Clear"   # Non-Functional Qualities
CATEGORY_5_STATUS="Clear"   # Integration & Dependencies
CATEGORY_6_STATUS="Clear"   # Edge Cases & Failures
CATEGORY_7_STATUS="Clear"   # Constraints & Tradeoffs
CATEGORY_8_STATUS="Clear"   # Terminology & Consistency
CATEGORY_9_STATUS="Clear"   # Completion Signals
CATEGORY_10_STATUS="Clear"  # Placeholders & Ambiguity

# Check for clear user goals & success criteria
grep -qi "goal\|success\|outcome" "$FEATURE_SPEC" || CATEGORY_1_STATUS="Missing"

# Check for entities, attributes, relationships
grep -qiE "entity|model|table|schema" "$FEATURE_SPEC" || CATEGORY_2_STATUS="Missing"

# Check for user journeys, error states
grep -qiE "user (flow|journey|scenario)" "$FEATURE_SPEC" || CATEGORY_3_STATUS="Missing"

# Check for performance, scalability, reliability metrics
if ! grep -q "^## Non-Functional" "$FEATURE_SPEC"; then
  CATEGORY_4_STATUS="Missing"
elif ! grep -qE "[0-9]+(ms|s|%)|p[0-9]{2}" "$FEATURE_SPEC"; then
  CATEGORY_4_STATUS="Partial"
fi

# Check for external services, APIs, failure modes
if grep -qiE "external|third[- ]party|API|service" "$FEATURE_SPEC"; then
  grep -qiE "timeout|retry|fallback|circuit breaker" "$FEATURE_SPEC" || CATEGORY_5_STATUS="Partial"
fi

# Check for edge cases, negative scenarios
EDGE_CASE_COUNT=$(sed -n '/^## Edge Cases/,/^## /p' "$FEATURE_SPEC" | grep -c "^- " || echo 0)
[ "$EDGE_CASE_COUNT" -eq 0 ] && CATEGORY_6_STATUS="Missing"
[ "$EDGE_CASE_COUNT" -gt 0 ] && [ "$EDGE_CASE_COUNT" -lt 3 ] && CATEGORY_6_STATUS="Partial"

# Check for technical constraints, explicit tradeoffs
grep -qiE "constraint|limitation|tradeoff" "$FEATURE_SPEC" || CATEGORY_7_STATUS="Missing"

# Check for acceptance criteria, Definition of Done
USER_STORY_COUNT=$(grep -c "^\[US[0-9]\]" "$FEATURE_SPEC" || echo 0)
ACCEPTANCE_CRITERIA_COUNT=$(grep -c "Acceptance" "$FEATURE_SPEC" || echo 0)
if [ "$USER_STORY_COUNT" -gt 0 ] && [ "$ACCEPTANCE_CRITERIA_COUNT" -eq 0 ]; then
  CATEGORY_9_STATUS="Missing"
elif [ "$ACCEPTANCE_CRITERIA_COUNT" -lt "$USER_STORY_COUNT" ]; then
  CATEGORY_9_STATUS="Partial"
fi

# Check for TODO, vague adjectives
PLACEHOLDER_COUNT=$(grep -ciE "TODO|TKTK|\?\?\?|<placeholder>|TBD" "$FEATURE_SPEC" || echo 0)
VAGUE_COUNT=$(grep -ciE "fast|slow|easy|simple|intuitive|robust|scalable|user-friendly" "$FEATURE_SPEC" || echo 0)
[ "$PLACEHOLDER_COUNT" -gt 0 ] && CATEGORY_10_STATUS="Missing"
[ "$VAGUE_COUNT" -gt 5 ] && CATEGORY_10_STATUS="Partial"

# ============================================================================
# STEP 4: Build Coverage Map
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Coverage analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count categories by status
CLEAR_COUNT=0; PARTIAL_COUNT=0; MISSING_COUNT=0
for i in {1..10}; do
  VAR_NAME="CATEGORY_${i}_STATUS"
  STATUS="${!VAR_NAME}"

  case "$STATUS" in
    Clear)   ((CLEAR_COUNT++))   ;;
    Partial) ((PARTIAL_COUNT++)) ;;
    Missing) ((MISSING_COUNT++)) ;;
  esac
done

echo "Category Status:"
echo "  Clear: $CLEAR_COUNT/10"
echo "  Partial: $PARTIAL_COUNT/10"
echo "  Missing: $MISSING_COUNT/10"
echo ""

# Early exit if everything is clear
if [ "$PARTIAL_COUNT" -eq 0 ] && [ "$MISSING_COUNT" -eq 0 ]; then
  echo "✅ No critical ambiguities detected"
  echo ""
  echo "Spec is ready for /plan"
  exit 0
fi

# ============================================================================
# STEP 5: Repo-First Precedent Check
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Searching for repo precedents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Search for technical decisions already made
echo "Existing patterns found:"

# Database
if command -v rg &> /dev/null; then
  if rg -q --ignore-case "postgres|postgresql|pg" package.json 2>/dev/null; then
    echo "  - Database: PostgreSQL (package.json)"
  fi

  # Auth
  if rg -q --ignore-case "jwt|oauth|clerk|auth0" specs 2>/dev/null; then
    echo "  - Auth: $(rg --ignore-case "jwt|oauth|clerk|auth0" specs -l | head -1)"
  fi

  # Rate limiting
  if rg -q --ignore-case "rate limit|throttle" specs 2>/dev/null; then
    echo "  - Rate limit: $(rg --ignore-case "rate limit|throttle" specs -n | head -1)"
  fi

  # Performance targets
  if rg -q "p95|p99|<.*ms" specs 2>/dev/null; then
    echo "  - Performance targets: $(rg "p95|p99|<.*ms" specs -n | head -1)"
  fi
else
  echo "  (ripgrep not installed - skipping precedent search)"
fi

echo ""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

update_clarifications() {
  local QUESTION="$1"
  local ANSWER="$2"
  local SESSION_DATE
  SESSION_DATE=$(date +%F)

  # Ensure Clarifications section exists
  if ! grep -q "^## Clarifications" "$FEATURE_SPEC"; then
    # Find insertion point after Overview or Context
    if grep -q "^## Overview" "$FEATURE_SPEC"; then
      sed -i.bak '/^## Overview/a\
\
## Clarifications' "$FEATURE_SPEC"
    elif grep -q "^## Context" "$FEATURE_SPEC"; then
      sed -i.bak '/^## Context/a\
\
## Clarifications' "$FEATURE_SPEC"
    else
      # Insert at beginning if no Overview/Context found
      echo -e "\n## Clarifications\n" | cat - "$FEATURE_SPEC" > "$FEATURE_SPEC.tmp" && mv "$FEATURE_SPEC.tmp" "$FEATURE_SPEC"
    fi
  fi

  # Add session header if not exists for today
  if ! grep -q "^### Session $SESSION_DATE" "$FEATURE_SPEC"; then
    sed -i.bak "/^## Clarifications/a\
\
### Session $SESSION_DATE" "$FEATURE_SPEC"
  fi

  # Append Q&A
  sed -i.bak "/^### Session $SESSION_DATE/a\
- Q: $QUESTION → A: $ANSWER" "$FEATURE_SPEC"

  # Clean up backup files
  rm -f "$FEATURE_SPEC.bak"
}

validate_update() {
  local QUESTION="$1"

  # Check clarification added
  if ! grep -q "Q: $QUESTION" "$FEATURE_SPEC"; then
    echo "❌ Error: Clarification not added"
    rollback_clarify "Validation failed"
    return 1
  fi

  return 0
}

rollback_clarify() {
  local ERROR_MSG="$1"

  echo "⚠️  Clarification failed. Rolling back changes..."
  git checkout "$FEATURE_SPEC"
  echo "✓ Rolled back to pre-clarification state"
  echo "Error: $ERROR_MSG"
  exit 1
}

save_spec() {
  local QUESTION="$1"
  local ANSWER="$2"

  git add "$FEATURE_SPEC"
  git commit -m "clarify: apply Q/A to $(basename "$FEATURE_DIR")

Q: $QUESTION
A: $ANSWER

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify

  # Verify commit succeeded
  COMMIT_HASH=$(git rev-parse --short HEAD)
  echo ""
  echo "✅ Clarification committed: $COMMIT_HASH"
  echo ""
}

# ============================================================================
# STEP 6-8: Generate Questions, Ask, Apply (Interactive - LLM-driven)
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Clarification workflow ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The LLM will now:"
echo "  1. Read spec.md and identify ambiguities"
echo "  2. Generate prioritized questions (max 5 at a time)"
echo "  3. Present questions with options and recommended answers"
echo "  4. Apply each answer atomically to spec.md"
echo "  5. Commit changes after each Q/A"
echo ""
echo "Categories to analyze:"
echo "  - Domain & Data Model: $CATEGORY_2_STATUS"
echo "  - Interaction & UX Flow: $CATEGORY_3_STATUS"
echo "  - Non-Functional Quality: $CATEGORY_4_STATUS"
echo "  - Integration & Dependencies: $CATEGORY_5_STATUS"
echo "  - Edge Cases & Failure Handling: $CATEGORY_6_STATUS"
echo ""
echo "Note: This script provides infrastructure for the clarification workflow."
echo "The LLM (Claude Code) will execute steps 6-10 interactively."
echo ""

# Export variables for LLM to use
export FEATURE_DIR
export FEATURE_SPEC
export CATEGORY_1_STATUS
export CATEGORY_2_STATUS
export CATEGORY_3_STATUS
export CATEGORY_4_STATUS
export CATEGORY_5_STATUS
export CATEGORY_6_STATUS
export CATEGORY_7_STATUS
export CATEGORY_8_STATUS
export CATEGORY_9_STATUS
export CATEGORY_10_STATUS
export CLEAR_COUNT
export PARTIAL_COUNT
export MISSING_COUNT

# ============================================================================
# STEP 9: Coverage Summary (called by LLM after Q/A session)
# ============================================================================

print_coverage_summary() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Coverage Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "| Category | Status | Notes |"
  echo "|----------|--------|-------|"

  CATEGORIES=(
    "Functional Scope & Behavior:$CATEGORY_1_STATUS"
    "Domain & Data Model:$CATEGORY_2_STATUS"
    "Interaction & UX Flow:$CATEGORY_3_STATUS"
    "Non-Functional Quality:$CATEGORY_4_STATUS"
    "Integration & Dependencies:$CATEGORY_5_STATUS"
    "Edge Cases & Failure Handling:$CATEGORY_6_STATUS"
    "Constraints & Tradeoffs:$CATEGORY_7_STATUS"
    "Terminology & Consistency:$CATEGORY_8_STATUS"
    "Completion Signals:$CATEGORY_9_STATUS"
    "Placeholders & Ambiguity:$CATEGORY_10_STATUS"
  )

  for cat_data in "${CATEGORIES[@]}"; do
    CAT_NAME=$(echo "$cat_data" | cut -d':' -f1)
    CAT_STATUS=$(echo "$cat_data" | cut -d':' -f2)

    # Determine status icon and notes
    case "$CAT_STATUS" in
      Clear)
        STATUS_ICON="✅ Resolved"
        NOTES="Sufficient detail"
        ;;
      Partial)
        STATUS_ICON="⚠️ Deferred"
        NOTES="Low impact, clarify later if needed"
        ;;
      Missing)
        STATUS_ICON="❌ Outstanding"
        NOTES="High impact, recommend /clarify again"
        ;;
    esac

    echo "| $CAT_NAME | $STATUS_ICON | $NOTES |"
  done

  echo ""
}

# ============================================================================
# STEP 10: Decision Tree (called by LLM after session complete)
# ============================================================================

print_decision_tree() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ CLARIFICATION SESSION COMPLETE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Extract feature slug
  SLUG=$(basename "$FEATURE_DIR")

  # Count remaining ambiguities
  REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

  # Display session summary
  cat <<EOF
Feature: $SLUG
Spec: $FEATURE_SPEC

**Session Summary:**
- Ambiguities remaining: $REMAINING_COUNT
- Session: $(date +%Y-%m-%d\ %H:%M)

What's next?

EOF

  if [ "$REMAINING_COUNT" -gt 0 ]; then
    # Still have ambiguities - recommend continuing clarification
    cat <<'MENU'
⚠️  AMBIGUITIES REMAINING

1. Continue clarifying (/clarify) [RECOMMENDED]
   Duration: ~5-10 min
   Impact: Prevents rework in planning phase

2. Proceed to planning (/plan)
   ⚠️  Planning with ambiguities may require revisions
   Duration: ~10-15 min

3. Review spec.md manually
   Location: Check all [NEEDS CLARIFICATION] markers

MENU

    # Show first 3 remaining ambiguities for context
    echo ""
    echo "Remaining ambiguities (first 3):"
    grep -n "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" | head -3 | sed 's/^/  /' || echo "  (none found)"
    echo ""
  else
    # All ambiguities resolved - ready for planning
    cat <<'MENU'
✅ ALL AMBIGUITIES RESOLVED

1. Generate implementation plan (/plan) [RECOMMENDED]
   Duration: ~10-15 min
   Output: Architecture decisions, component reuse analysis

2. Continue automated workflow (/feature continue)
   Executes: /plan → /tasks → /implement → /optimize → /ship
   Duration: ~60-90 min (full feature delivery)

3. Review spec.md first
   Location: Verify all clarifications are correct

MENU
  fi
}

# Update NOTES.md
update_notes() {
  local REMAINING_COUNT
  REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

  cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 0.5: Clarify ($(date '+%Y-%m-%d %H:%M'))

**Summary**:
- Ambiguities remaining: $REMAINING_COUNT
- Session: $(date +%Y-%m-%d\ %H:%M)

**Checkpoint**:
- ⚠️ Remaining: $REMAINING_COUNT ambiguities
- 📋 Ready for: $(if [ "$REMAINING_COUNT" -gt 0 ]; then echo "/clarify (resolve remaining)"; else echo "/plan"; fi)

EOF
}

# Make functions available to LLM if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  # Script is being sourced, export functions
  export -f update_clarifications
  export -f validate_update
  export -f rollback_clarify
  export -f save_spec
  export -f print_coverage_summary
  export -f print_decision_tree
  export -f update_notes
fi

# Return exit code 2 to indicate partial completion (ambiguities remain)
if [ "$PARTIAL_COUNT" -gt 0 ] || [ "$MISSING_COUNT" -gt 0 ]; then
  exit 2
else
  exit 0
fi

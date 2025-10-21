---
description: Reduce spec ambiguity via targeted questions (planning is 80% of success)
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

Clarify ambiguities in specification: $ARGUMENTS

<context>
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## MENTAL MODEL

**Workflow**: spec-flow → **clarify** → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**
- Run prerequisite script → Load spec → Scan ambiguities → Build coverage map → Generate questions → Ask sequentially → Update incrementally → Commit → Suggest next

**Auto-suggest:**
- When clarified → `/plan`

**Operating Constraints:**
- **Question Limit**: Maximum 10 total, present max 5 at a time
- **Recommended Answers**: Analyze options and provide best-practice recommendation
- **Incremental Updates**: Save after EACH answer (atomic)
- **Git Safety**: Checkpoint before each update, rollback on failure
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent fabricating ambiguities or solutions.

1. **Never invent ambiguities not present in spec.md**
   - ❌ BAD: "The spec doesn't mention how to handle edge cases" (without reading it)
   - ✅ GOOD: Read spec.md, quote ambiguous sections: "spec.md:45 says 'users can edit' but doesn't specify edit permissions"
   - Only flag ambiguities found in actual spec text

2. **Quote exact text when identifying unclear requirements**
   - When flagging ambiguity: "spec.md:120-125: '[exact quote]' - unclear whether this means X or Y"
   - Don't paraphrase unclear text - show it verbatim
   - Cite line numbers for all ambiguities

3. **Never make up recommended answers**
   - Don't say "Best practice is..." without evidence
   - Source recommendations: "Similar feature in specs/002-auth used JWT per plan.md:45"
   - If no precedent exists, say: "No existing pattern found, recommend researching..."

4. **Verify question relevance before asking user**
   - Before asking technical question, check if answer exists in codebase
   - Use Grep/Glob to search for existing implementations
   - Don't ask "Should we use PostgreSQL?" if package.json already has pg installed

5. **Never assume user's answer without asking**
   - Don't fill in clarifications with guesses
   - Present question, wait for response, use exact answer given
   - If user says "skip", mark as skipped - don't invent answer

**Why this matters**: Fabricated ambiguities create unnecessary work. Invented best practices may conflict with project standards. Accurate clarification based on real spec ambiguities ensures plan addresses actual uncertainties.
</constraints>

<instructions>
## RUN PREREQUISITE SCRIPT

**Execute once from repo root:**

```bash
# Get absolute paths
if command -v pwsh &> /dev/null; then
  # Windows/PowerShell
  PREREQ_JSON=$(pwsh -File scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly)
else
  # macOS/Linux/Git Bash
  PREREQ_JSON=$(scripts/bash/check-prerequisites.sh --json --paths-only)
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
  ls -1 specs/*/spec.md 2>/dev/null | sed 's|specs/||;s|/spec.md||'
  exit 1
fi
```

For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

## LOAD SPEC

**Read specification:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Loading specification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $(basename "$FEATURE_DIR")"
echo "Spec: $FEATURE_SPEC"
echo ""

# Create git checkpoint before any changes
git add "$FEATURE_SPEC" 2>/dev/null || true
git stash push -m "clarify: checkpoint before session" "$FEATURE_SPEC" 2>/dev/null || true
```

## SCAN AMBIGUITIES (Comprehensive Taxonomy)

**Check coverage across 10 categories:**

### 1. Functional Scope & Behavior

```bash
CATEGORY_1_STATUS="Clear"

# Check for clear user goals & success criteria
if ! grep -qi "goal\|success\|outcome" "$FEATURE_SPEC"; then
  CATEGORY_1_STATUS="Missing"
elif ! grep -qi "out of scope\|not included" "$FEATURE_SPEC"; then
  CATEGORY_1_STATUS="Partial"
fi
```

### 2. Domain & Data Model

```bash
CATEGORY_2_STATUS="Clear"

# Check for entities, attributes, relationships
if ! grep -qiE "entity|model|table|schema" "$FEATURE_SPEC"; then
  CATEGORY_2_STATUS="Missing"
elif ! grep -qiE "relationship|FK|foreign key|belongs to|has many" "$FEATURE_SPEC"; then
  CATEGORY_2_STATUS="Partial"
fi
```

### 3. Interaction & UX Flow

```bash
CATEGORY_3_STATUS="Clear"

# Check for user journeys, error states
if ! grep -qiE "user (flow|journey|scenario)" "$FEATURE_SPEC"; then
  CATEGORY_3_STATUS="Missing"
elif ! grep -qiE "error|loading|empty state" "$FEATURE_SPEC"; then
  CATEGORY_3_STATUS="Partial"
fi
```

### 4. Non-Functional Quality Attributes

```bash
CATEGORY_4_STATUS="Clear"

# Check for performance, scalability, reliability metrics
NFR_COUNT=$(grep -c "^## Non-Functional" "$FEATURE_SPEC" || echo 0)

if [ "$NFR_COUNT" -eq 0 ]; then
  CATEGORY_4_STATUS="Missing"
elif ! grep -qE "[0-9]+|<[0-9]|>[0-9]|p[0-9]{2}|%" "$FEATURE_SPEC"; then
  CATEGORY_4_STATUS="Partial"
fi
```

### 5. Integration & External Dependencies

```bash
CATEGORY_5_STATUS="Clear"

# Check for external services, APIs, failure modes
if grep -qiE "external|third-party|API|service" "$FEATURE_SPEC"; then
  # Has external dependencies - check for failure handling
  if ! grep -qiE "timeout|retry|fallback|circuit breaker" "$FEATURE_SPEC"; then
    CATEGORY_5_STATUS="Partial"
  fi
fi
```

### 6. Edge Cases & Failure Handling

```bash
CATEGORY_6_STATUS="Clear"

# Check for edge cases, negative scenarios
EDGE_CASE_COUNT=$(sed -n '/^## Edge Cases/,/^## /p' "$FEATURE_SPEC" | grep -c "^- " || echo 0)

if [ "$EDGE_CASE_COUNT" -eq 0 ]; then
  CATEGORY_6_STATUS="Missing"
elif [ "$EDGE_CASE_COUNT" -lt 3 ]; then
  CATEGORY_6_STATUS="Partial"
fi
```

### 7. Constraints & Tradeoffs

```bash
CATEGORY_7_STATUS="Clear"

# Check for technical constraints, explicit tradeoffs
if ! grep -qiE "constraint|limitation|tradeoff" "$FEATURE_SPEC"; then
  CATEGORY_7_STATUS="Missing"
fi
```

### 8. Terminology & Consistency

```bash
CATEGORY_8_STATUS="Clear"

# Check for glossary, canonical terms
if grep -qi "glossary\|terminology" "$FEATURE_SPEC"; then
  CATEGORY_8_STATUS="Clear"
else
  # Check for inconsistent terminology (same concept, different names)
  CAMEL_CASE_TERMS=$(grep -oE "[A-Z][a-z]+[A-Z][a-z]+" "$FEATURE_SPEC" | sort | uniq)

  TERM_VARIANTS=0
  while IFS= read -r term; do
    [ -z "$term" ] && continue

    # Check for variants (e.g., "UserProfile" vs "User Profile" vs "user-profile")
    VARIANT_COUNT=$(grep -ioE "${term:0:5}[a-z_-]*" "$FEATURE_SPEC" | sort | uniq | wc -l)

    if [ "$VARIANT_COUNT" -gt 1 ]; then
      ((TERM_VARIANTS++))
    fi
  done <<< "$CAMEL_CASE_TERMS"

  if [ "$TERM_VARIANTS" -gt 3 ]; then
    CATEGORY_8_STATUS="Partial"
  fi
fi
```

### 9. Completion Signals

```bash
CATEGORY_9_STATUS="Clear"

# Check for acceptance criteria, Definition of Done
USER_STORY_COUNT=$(grep -c "^\[US[0-9]\]" "$FEATURE_SPEC" || echo 0)
ACCEPTANCE_CRITERIA_COUNT=$(grep -c "Acceptance" "$FEATURE_SPEC" || echo 0)

if [ "$USER_STORY_COUNT" -gt 0 ] && [ "$ACCEPTANCE_CRITERIA_COUNT" -eq 0 ]; then
  CATEGORY_9_STATUS="Missing"
elif [ "$ACCEPTANCE_CRITERIA_COUNT" -lt "$USER_STORY_COUNT" ]; then
  CATEGORY_9_STATUS="Partial"
fi
```

### 10. Placeholders & Ambiguity

```bash
CATEGORY_10_STATUS="Clear"

# Check for TODO, vague adjectives
PLACEHOLDER_COUNT=$(grep -ciE "TODO|TKTK|\?\?\?|<placeholder>|TBD" "$FEATURE_SPEC" || echo 0)
VAGUE_COUNT=$(grep -ciE "fast|slow|easy|simple|intuitive|robust|scalable|user-friendly" "$FEATURE_SPEC" || echo 0)

if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
  CATEGORY_10_STATUS="Missing"
elif [ "$VAGUE_COUNT" -gt 5 ]; then
  CATEGORY_10_STATUS="Partial"
fi
```

## BUILD COVERAGE MAP

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Coverage analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count categories by status
CLEAR_COUNT=0
PARTIAL_COUNT=0
MISSING_COUNT=0

for i in {1..10}; do
  VAR_NAME="CATEGORY_${i}_STATUS"
  STATUS="${!VAR_NAME}"

  case "$STATUS" in
    Clear) ((CLEAR_COUNT++)) ;;
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
```

## GENERATE PRIORITIZED QUESTIONS

**Priority order: Architecture > UX > NFR > Integration > Edge Cases > Constraints > Terminology > Completion > Placeholders**

```bash
QUESTIONS=()

# Category 2: Domain & Data Model (Architecture) - HIGHEST PRIORITY
if [ "$CATEGORY_2_STATUS" = "Missing" ] || [ "$CATEGORY_2_STATUS" = "Partial" ]; then
  QUESTIONS+=("2|ARCHITECTURE|What database schema should be used for core entities?|A) PostgreSQL with normalized tables (RECOMMENDED - ACID compliance, relational integrity)|B) MongoDB document store|C) Hybrid (Postgres + Redis cache)|Short answer")
fi

# Category 3: Interaction & UX Flow - HIGH PRIORITY
if [ "$CATEGORY_3_STATUS" = "Missing" ] || [ "$CATEGORY_3_STATUS" = "Partial" ]; then
  QUESTIONS+=("3|UX|What happens when user action fails (e.g., network error)?|A) Show inline error message (RECOMMENDED - keeps context, reduces cognitive load)|B) Display toast notification|C) Redirect to error page|Short answer")
fi

# Category 4: Non-Functional Requirements - HIGH PRIORITY
if [ "$CATEGORY_4_STATUS" = "Missing" ] || [ "$CATEGORY_4_STATUS" = "Partial" ]; then
  QUESTIONS+=("4|NFR|What is the target response time for API endpoints?|A) <200ms p95 (RECOMMENDED - modern web standards)|B) <500ms p95|C) <1s p95|Numeric (ms)")
fi

# Category 5: Integration & External Dependencies - MEDIUM PRIORITY
if [ "$CATEGORY_5_STATUS" = "Partial" ]; then
  QUESTIONS+=("5|INTEGRATION|How should external API failures be handled?|A) Retry with exponential backoff (RECOMMENDED - resilient, industry standard)|B) Immediate failure notification|C) Queue for later processing|Short answer")
fi

# Category 6: Edge Cases & Failure Handling - MEDIUM PRIORITY
if [ "$CATEGORY_6_STATUS" = "Missing" ] || [ "$CATEGORY_6_STATUS" = "Partial" ]; then
  QUESTIONS+=("6|EDGE|What happens with concurrent edits to same resource?|A) Last write wins (RECOMMENDED - simple, acceptable for most use cases)|B) Optimistic locking with conflict detection|C) Pessimistic locking|Short answer")
fi

# Limit to 5 questions max
if [ ${#QUESTIONS[@]} -gt 5 ]; then
  QUESTIONS=("${QUESTIONS[@]:0:5}")
fi

TOTAL_QUESTIONS=${#QUESTIONS[@]}

if [ "$TOTAL_QUESTIONS" -eq 0 ]; then
  echo "✅ No high-impact ambiguities requiring clarification"
  echo ""
  echo "Spec is ready for /plan"
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤔 Clarification needed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Found $TOTAL_QUESTIONS high-impact ambiguities to resolve"
echo ""
```

## SEQUENTIAL QUESTIONING

**One question at a time with recommended answers:**

```bash
QUESTION_NUM=0
ANSWERED_QUESTIONS=()
SKIPPED_QUESTIONS=()

for question_data in "${QUESTIONS[@]}"; do
  ((QUESTION_NUM++))

  # Parse question data
  CATEGORY_ID=$(echo "$question_data" | cut -d'|' -f1)
  CATEGORY_NAME=$(echo "$question_data" | cut -d'|' -f2)
  QUESTION=$(echo "$question_data" | cut -d'|' -f3)
  OPTION_A=$(echo "$question_data" | cut -d'|' -f4)
  OPTION_B=$(echo "$question_data" | cut -d'|' -f5)
  OPTION_C=$(echo "$question_data" | cut -d'|' -f6)
  OPTION_SHORT=$(echo "$question_data" | cut -d'|' -f7)

  # Display question
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🤔 Question $QUESTION_NUM/$TOTAL_QUESTIONS ($CATEGORY_NAME)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$QUESTION"
  echo ""

  # Extract recommendation (first option with "RECOMMENDED" tag)
  RECOMMENDED_OPTION=""
  if echo "$OPTION_A" | grep -q "RECOMMENDED"; then
    RECOMMENDED_OPTION="A"
    RECOMMENDATION=$(echo "$OPTION_A" | sed 's/ (RECOMMENDED.*//')
    REASONING=$(echo "$OPTION_A" | sed 's/.*RECOMMENDED - //' | sed 's/).*//')
  fi

  # Display recommendation
  if [ -n "$RECOMMENDED_OPTION" ]; then
    echo "**Recommended:** Option $RECOMMENDED_OPTION - $REASONING"
    echo ""
  fi

  # Display options table
  echo "| Option | Description |"
  echo "|--------|-------------|"
  echo "| A | $(echo "$OPTION_A" | sed 's/ (RECOMMENDED[^)]*)//') |"
  echo "| B | $OPTION_B |"
  if [ -n "$OPTION_C" ] && [ "$OPTION_C" != "Short answer" ]; then
    echo "| C | $OPTION_C |"
  fi
  if [ "$OPTION_SHORT" = "Short answer" ] || [ "$OPTION_C" = "Short answer" ]; then
    echo "| Short | Provide different answer (<=5 words) |"
  fi
  echo "| Skip | Defer this question |"
  echo ""

  # Progress bar
  PROGRESS_PCT=$(( QUESTION_NUM * 100 / TOTAL_QUESTIONS ))
  PROGRESS_FILLED=$(( PROGRESS_PCT / 5 ))
  PROGRESS_EMPTY=$(( 20 - PROGRESS_FILLED ))
  PROGRESS_BAR=$(printf '█%.0s' $(seq 1 $PROGRESS_FILLED))$(printf '░%.0s' $(seq 1 $PROGRESS_EMPTY))

  echo "Progress: $PROGRESS_BAR $PROGRESS_PCT% complete ($QUESTION_NUM/$TOTAL_QUESTIONS answered)"
  echo ""

  # Accept user input
  if [ -n "$RECOMMENDED_OPTION" ]; then
    echo "You can reply with the option letter (e.g., \"A\"), accept the recommendation by saying \"yes\" or \"recommended\", or provide your own short answer."
  else
    echo "Reply with option letter, \"Skip\", or provide short answer (<=5 words)."
  fi
  echo ""
  echo -n "Answer: "

  # Wait for user response (in practice, this would be handled by the LLM interaction)
  # For this script, we'll use a placeholder

  # Placeholder: USER_ANSWER would come from user
  # USER_ANSWER="A"  # or "yes" or "recommended" or "skip" or custom answer

  # Validate and process answer
  # ... (validation logic)

  # If user accepts recommendation
  # if [ "$USER_ANSWER" = "yes" ] || [ "$USER_ANSWER" = "recommended" ] || [ "$USER_ANSWER" = "suggested" ]; then
  #   FINAL_ANSWER="$RECOMMENDATION"
  # else
  #   FINAL_ANSWER="$USER_ANSWER"
  # fi

  # If skip, add to skipped list
  # if [ "$USER_ANSWER" = "skip" ] || [ "$USER_ANSWER" = "Skip" ]; then
  #   SKIPPED_QUESTIONS+=("Q${QUESTION_NUM}: $QUESTION")
  #   continue
  # fi

  # Record answered question
  # ANSWERED_QUESTIONS+=("Q${QUESTION_NUM}: $QUESTION → $FINAL_ANSWER")

  # INCREMENTAL UPDATE (after each answer)
  # ... (update spec, validate, save)

done
```

## UPDATE SPEC (Incremental After Each Answer)

**For each accepted answer:**

```bash
# 1. Add to Clarifications section
update_clarifications() {
  local QUESTION="$1"
  local ANSWER="$2"
  local CATEGORY="$3"

  # Ensure Clarifications section exists
  if ! grep -q "^## Clarifications" "$FEATURE_SPEC"; then
    # Add after Overview/Context section
    sed -i '/^## Overview/a \\n## Clarifications' "$FEATURE_SPEC"
  fi

  # Add session header if not exists for today
  SESSION_DATE=$(date +%Y-%m-%d)
  if ! grep -q "^### Session $SESSION_DATE" "$FEATURE_SPEC"; then
    sed -i "/^## Clarifications/a \\n### Session $SESSION_DATE\\n" "$FEATURE_SPEC"
  fi

  # Append Q&A
  sed -i "/^### Session $SESSION_DATE/a \\- Q: $QUESTION → A: $ANSWER" "$FEATURE_SPEC"
}

# 2. Apply clarification to appropriate section
apply_clarification() {
  local CATEGORY="$1"
  local QUESTION="$2"
  local ANSWER="$3"

  case "$CATEGORY" in
    ARCHITECTURE|DOMAIN)
      # Update Data Model section
      # ... (add entity, fields, relationships)
      ;;
    UX|INTERACTION)
      # Update User Scenarios or Functional Requirements
      # ... (add error handling, state transitions)
      ;;
    NFR)
      # Update Non-Functional Requirements with metrics
      # ... (add measurable criteria)
      ;;
    INTEGRATION)
      # Update Dependencies section
      # ... (add failure modes, retry logic)
      ;;
    EDGE)
      # Add to Edge Cases section
      # ... (add edge case handling)
      ;;
    *)
      # Update relevant section
      ;;
  esac
}

# 3. Validate update
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

# 4. Save immediately (atomic)
save_spec() {
  git add "$FEATURE_SPEC"
  # Actual commit happens at end of session
}

# 5. Rollback on error
rollback_clarify() {
  local ERROR_MSG="$1"

  echo "⚠️  Clarification failed. Rolling back changes..."
  git checkout "$FEATURE_SPEC"
  echo "✓ Rolled back to pre-clarification state"
  echo "Error: $ERROR_MSG"
  exit 1
}
```

## CONFLICT DETECTION

```bash
detect_conflict() {
  local ANSWER="$1"
  local EXISTING_VALUE=""

  # Check if answer contradicts existing spec
  # Example: Check if NFR already specifies different value
  EXISTING_VALUE=$(grep -oE "rate limit: [0-9]+" "$FEATURE_SPEC" | head -1)

  if [ -n "$EXISTING_VALUE" ]; then
    echo ""
    echo "⚠️  CONFLICT DETECTED"
    echo ""
    echo "Existing spec: $EXISTING_VALUE"
    echo "Your answer: $ANSWER"
    echo ""
    echo "Which is correct?"
    echo "  A) Keep existing"
    echo "  B) Update to new"
    echo "  C) Let me clarify"
    echo ""
    echo -n "Choice (A/B/C): "

    # Wait for user response
    # USER_CHOICE would come from user input
  fi
}
```

## COVERAGE SUMMARY TABLE

```bash
generate_coverage_summary() {
  echo ""
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
        if grep -q "$CAT_NAME" <<< "${ANSWERED_QUESTIONS[@]}"; then
          STATUS_ICON="✅ Resolved"
          NOTES="Clarified in this session"
        else
          STATUS_ICON="❌ Outstanding"
          NOTES="High impact, recommend /clarify again"
        fi
        ;;
    esac

    echo "| $CAT_NAME | $STATUS_ICON | $NOTES |"
  done

  echo ""
}
```

## GIT COMMIT

```bash
commit_clarifications() {
  RESOLVED_COUNT=${#ANSWERED_QUESTIONS[@]}
  SKIPPED_COUNT=${#SKIPPED_QUESTIONS[@]}

  COMMIT_MSG="clarify: resolve ${RESOLVED_COUNT} ambiguities in $(basename "$FEATURE_DIR")

Clarified:"

  for qa in "${ANSWERED_QUESTIONS[@]}"; do
    COMMIT_MSG="${COMMIT_MSG}
- $qa"
  done

  if [ "$SKIPPED_COUNT" -gt 0 ]; then
    COMMIT_MSG="${COMMIT_MSG}

Deferred (${SKIPPED_COUNT} remaining):"

    for q in "${SKIPPED_QUESTIONS[@]}"; do
      COMMIT_MSG="${COMMIT_MSG}
- $q"
    done
  fi

  COMMIT_MSG="${COMMIT_MSG}

Session: $(date +%Y-%m-%d\ %H:%M)

Next: /plan (or /clarify to resolve remaining)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  git commit -m "$COMMIT_MSG"

  # Verify commit succeeded
  COMMIT_HASH=$(git rev-parse --short HEAD)
  echo ""
  echo "✅ Clarifications committed: $COMMIT_HASH"
  echo ""
  git log -1 --oneline
  echo ""
}

# Execute commit
commit_clarifications
```

## UPDATE NOTES.MD

```bash
update_notes() {
  REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

  # Add Phase 0.5 checkpoint
  cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 0.5: Clarify ($(date '+%Y-%m-%d %H:%M'))

**Summary**:
- Questions answered: ${#ANSWERED_QUESTIONS[@]}
- Questions skipped: ${#SKIPPED_QUESTIONS[@]}
- Ambiguities remaining: $REMAINING_COUNT
- Session: $(date +%Y-%m-%d\ %H:%M)

**Checkpoint**:
- ✅ Clarifications: ${#ANSWERED_QUESTIONS[@]} resolved
- ⚠️ Remaining: $REMAINING_COUNT ambiguities
- 📋 Ready for: $(if [ "$REMAINING_COUNT" -gt 0 ]; then echo "/clarify (resolve remaining)"; else echo "/plan"; fi)

EOF
}
```

## RETURN

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CLARIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $(basename "$FEATURE_DIR")"
echo "Spec: $FEATURE_SPEC"
echo ""
echo "Summary:"
echo "- Questions resolved: ${#ANSWERED_QUESTIONS[@]}/$TOTAL_QUESTIONS"
echo "- Session: $(date +%Y-%m-%d\ %H:%M)"

if [ ${#SKIPPED_QUESTIONS[@]} -gt 0 ]; then
  echo "- Skipped: ${#SKIPPED_QUESTIONS[@]} (deferred)"
fi

echo ""

# Generate coverage summary table
generate_coverage_summary

echo "Updates:"
UPDATED_SECTIONS=$(git diff HEAD~1 "$FEATURE_SPEC" 2>/dev/null | grep "^+## " | sed 's/^+## //' | sort -u)
if [ -n "$UPDATED_SECTIONS" ]; then
  echo "$UPDATED_SECTIONS" | sed 's/^/  - /'
else
  echo "  - Clarifications section"
fi

echo ""
echo "NOTES.md: Phase 0.5 checkpoint added"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

if [ "$REMAINING_COUNT" -gt 0 ]; then
  echo "⚠️  $REMAINING_COUNT ambiguities remaining"
  echo ""
  echo "Options:"
  echo "  1) /clarify (resolve remaining)"
  echo "  2) /plan (proceed, clarify later)"
  echo ""
  echo "Recommend: /clarify (complete clarification first)"
else
  echo "✅ All ambiguities resolved"
  echo ""
  echo "Manual (step-by-step):"
  echo "  → /plan"
  echo ""
  echo "Automated (full workflow):"
  echo "  → /flow continue"
fi
```
</instructions>

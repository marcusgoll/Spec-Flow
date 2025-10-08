---
description: Reduce spec ambiguity via targeted questions (planning is 80% of success)
---

Clarify ambiguities in specification: $ARGUMENTS

## MENTAL MODEL

**Workflow**:\spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Load spec -> Scan ambiguities -> Prioritize -> Choose mode -> Ask questions -> Update spec -> Suggest next

**Auto-suggest:**
- When clarified -> `/plan`

## USAGE

**Arguments:**
```bash
/clarify              # Clarify spec in current branch
/clarify [slug]       # Clarify specific feature by slug
```

**Examples:**
- `/clarify` → Uses current git branch name as slug
- `/clarify csv-export` → Clarifies specs/csv-export/spec.md

## LOAD SPEC

**Get feature from argument or current branch:**

```bash
# Determine slug
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

# Set paths
FEATURE_DIR="specs/$SLUG"
FEATURE_SPEC="$FEATURE_DIR/spec.md"

# Validate spec exists
if [ ! -f "$FEATURE_SPEC" ]; then
  echo "Error: Spec not found at $FEATURE_SPEC"
  echo ""
  echo "Usage: /clarify [feature-slug]"
  echo ""
  echo "Available specs:"
  ls -1 specs/*/spec.md | sed 's|specs/||;s|/spec.md||'
  exit 1
fi

if [ ! -d "$FEATURE_DIR" ]; then
  echo "Error: Feature directory not found: $FEATURE_DIR"
  exit 1
fi
```

**Cross-platform:** Works on Windows (bash/Git Bash), macOS, Linux. No PowerShell dependency.

## SCAN AMBIGUITIES

**Find all marked ambiguities:**

```bash
# Extract all [NEEDS CLARIFICATION] markers
AMBIGUITIES=$(grep -n "\[NEEDS CLARIFICATION" "$FEATURE_SPEC")
AMBIGUITY_COUNT=$(echo "$AMBIGUITIES" | grep -c "NEEDS CLARIFICATION" || echo 0)

if [ "$AMBIGUITY_COUNT" -eq 0 ]; then
  echo "✅ No ambiguities found in $FEATURE_SPEC"
  echo ""
  echo "Spec is ready for /plan"
  exit 0
fi
```

**Classify by impact:**

For each ambiguity, infer category from surrounding context:

- **Architecture/Data Model** (highest priority)
  - Keywords: "database", "schema", "model", "entity", "relationship"
  - Impact: Affects system design, hard to change later

- **UX/Behavior** (high priority)
  - Keywords: "user", "screen", "interaction", "flow", "state"
  - Impact: Affects user experience, moderate to change

- **Non-Functional Requirements** (medium priority)
  - Keywords: "performance", "security", "scalability", "availability"
  - Impact: Quality attributes, can be refined

- **Integration/Dependencies** (medium priority)
  - Keywords: "API", "service", "integration", "external", "third-party"
  - Impact: Affects contracts, moderate risk

- **Edge Cases/Error Handling** (low priority)
  - Keywords: "error", "edge case", "failure", "exception"
  - Impact: Important but can be added later

- **Wording/Clarity** (lowest priority)
  - Keywords: "wording", "terminology", "naming"
  - Impact: Cosmetic, easy to change

**Sort by priority before asking:**

```bash
# Sort ambiguities: Architecture > UX > NFR > Integration > Edge Cases > Wording
# Questions asked in priority order (highest impact first)
```

## ASK QUESTIONS (hybrid: batch or serial)

**Detect ambiguity count and offer mode choice:**

```bash
AMBIGUITY_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC")

if [ "$AMBIGUITY_COUNT" -le 2 ]; then
  MODE="serial"  # 1-2 questions: Serial mode (interactive)
else
  # 3+ questions: Offer choice
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🤔 CLARIFICATION MODE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $AMBIGUITY_COUNT ambiguities to resolve"
  echo ""
  echo "How to proceed?"
  echo "  A) Batch - Answer all at once (faster, ~2 min)"
  echo "  B) Serial - Answer one at a time (thoughtful, ~5-10 min)"
  echo ""
  echo "Recommend: A (batch mode for speed)"
  echo ""
  read -p "Choice (A/B): " mode_choice

  case $mode_choice in
    A|a|batch) MODE="batch" ;;
    B|b|serial) MODE="serial" ;;
    *) MODE="batch" ;;  # Default to batch
  esac
fi
```

---

### BATCH MODE (3+ questions, all at once)

**Present all questions with context:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BATCH CLARIFICATION (8 questions)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Questions sorted by priority (Architecture → UX → NFR → Integration → Edge Cases → Wording)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Q1 (Architecture/Data Model)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What database schema should be used for user preferences?

| Option | Description |
|--------|-------------|
| A      | PostgreSQL table with JSONB column (RECOMMENDED) |
| B      | Separate key-value table |
| C      | MongoDB document |
| Short  | Provide different answer |

Recommendation: A - Flexible, queryable, fits existing stack

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Q2 (UX/Behavior)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What happens when file upload fails?

| Option | Description |
|--------|-------------|
| A      | Show inline error message (RECOMMENDED) |
| B      | Display toast notification |
| C      | Redirect to error page |
| Short  | Provide different answer |

Recommendation: A - Keeps user in context, reduces cognitive load

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Q3 (Non-Functional Requirements)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What is the API rate limit?

| Option | Description |
|--------|-------------|
| A      | 100 req/min (free tier) (RECOMMENDED) |
| B      | 1000 req/min (paid tier) |
| Numeric | Provide specific number |

Recommendation: A - Industry standard for free tier, prevents abuse

... (continue for all questions)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 ANSWER FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Comma-separated answers:
  Example: 1A, 2B, 3:100, 4short-answer, 5skip

OR space-separated:
  Example: 1A 2B 3:100 4short-answer 5skip

Shortcuts:
- "all-A" = Accept all recommendations (A for every question)
- "skip-5,7" = Answer others, skip questions 5 and 7
- "1A rest-skip" = Answer Q1, skip rest

Answer:
```

**Parse batch answers:**

```bash
# Parse format: "1A, 2B, 3:custom, 4skip"
# Extract: Q1=A, Q2=B, Q3=custom, Q4=skip
# Track skipped questions for later
```

---

### SERIAL MODE (1-2 questions OR user preference)

**One question at a time with progress:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤔 Question 3/8 (UX/Behavior)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What happens when file upload fails?

| Option | Description |
|--------|-------------|
| A      | Show inline error message (RECOMMENDED) |
| B      | Display toast notification |
| C      | Redirect to error page |
| Skip   | Defer this question |
| Short  | Provide different answer (<=20 words) |

Recommendation: A - Keeps user in context, reduces cognitive load
Rationale: Inline errors prevent navigation, maintain flow state

Progress: ████████░░░░░░░░ 37% complete (3/8 answered)

Answer (A/B/C/Skip/Short):
```

**Features:**
- Question number and total: `3/8`
- Category tag: `(UX/Behavior)`
- Progress bar: `████████░░░░░░░░`
- Percentage: `37% complete`
- Skip option: Defer unknowns
- Rationale saved: Explains recommendation

**Stop when:**
- All ambiguities resolved OR
- User signals: "done", "proceed", "stop" OR
- All remaining questions skipped

---

## UPDATE SPEC (atomic updates with git)

**Create git checkpoint before updates:**

```bash
# Create checkpoint before any changes
git add "$FEATURE_SPEC"
git stash push -m "clarify: checkpoint before Q${QUESTION_NUM}" "$FEATURE_SPEC"
```

**For each answer:**

1. **Add to ## Clarifications section:**
   ```markdown
   ### Session YYYY-MM-DD HH:MM

   #### Q: [question]
   **Answer**: [answer]
   **Rationale**: [why this recommendation]
   **Category**: [Architecture/UX/NFR/Integration/EdgeCase/Wording]
   **Priority**: [High/Medium/Low]
   ```

2. **Apply clarification to appropriate section:**
   - **Architecture/Data Model** → Update Key Entities, data structures
   - **UX/Behavior** → Update User Scenarios, screen flows
   - **Non-Functional Requirements** → Add/update NFR-XXX with metrics
   - **Integration/Dependencies** → Update Dependencies, API contracts
   - **Edge Cases** → Add to Edge Cases section
   - **Wording/Clarity** → Update terminology, glossary

3. **Remove [NEEDS CLARIFICATION] marker:**
   ```bash
   # Find and remove the specific marker
   sed -i "/\[NEEDS CLARIFICATION.*${QUESTION_KEYWORD}\]/d" "$FEATURE_SPEC"
   ```

4. **Validate update:**
   ```bash
   # Check marker removed
   if grep -q "\[NEEDS CLARIFICATION.*${QUESTION_KEYWORD}\]" "$FEATURE_SPEC"; then
     echo "Error: Marker not removed"
     git checkout "$FEATURE_SPEC"  # Rollback
     exit 1
   fi

   # Check clarification added
   if ! grep -q "#### Q: $QUESTION" "$FEATURE_SPEC"; then
     echo "Error: Clarification not added"
     git checkout "$FEATURE_SPEC"  # Rollback
     exit 1
   fi
   ```

5. **Save and checkpoint:**
   ```bash
   git add "$FEATURE_SPEC"
   # Commit happens at end of all updates
   ```

**Conflict detection:**

If new answer contradicts existing spec:

```
⚠️  CONFLICT DETECTED

Existing spec (NFR-001): "API rate limit: 1000 req/min"
Your answer: "100 req/min"

Which is correct?
  A) Keep existing (1000 req/min)
  B) Update to new (100 req/min)
  C) Let me clarify

Choice (A/B/C):
```

## TRACK SKIPPED QUESTIONS

**Maintain list of deferred questions:**

```bash
SKIPPED_QUESTIONS=()

# When user selects "Skip"
SKIPPED_QUESTIONS+=("Q${QUESTION_NUM}: ${QUESTION_TEXT}")

# After all questions
if [ ${#SKIPPED_QUESTIONS[@]} -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  ${#SKIPPED_QUESTIONS[@]} questions skipped"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Skipped questions remain as [NEEDS CLARIFICATION]:"
  for q in "${SKIPPED_QUESTIONS[@]}"; do
    echo "  - $q"
  done
  echo ""
  echo "Options:"
  echo "  1) Re-run /clarify to resolve remaining"
  echo "  2) Proceed to /plan (clarify later)"
  echo ""
fi
```

## GIT COMMIT

**Commit all clarifications at once:**

```bash
RESOLVED_COUNT=$((AMBIGUITY_COUNT - ${#SKIPPED_QUESTIONS[@]}))

COMMIT_MSG="clarify: resolve ${RESOLVED_COUNT} ambiguities in ${SLUG}

Clarified:
"

# Add each resolved question to commit message
for i in $(seq 1 $RESOLVED_COUNT); do
  COMMIT_MSG="${COMMIT_MSG}
- Q${i}: [question summary] → [answer]"
done

if [ ${#SKIPPED_QUESTIONS[@]} -gt 0 ]; then
  COMMIT_MSG="${COMMIT_MSG}

Deferred (${#SKIPPED_QUESTIONS[@]} remaining):
"
  for q in "${SKIPPED_QUESTIONS[@]}"; do
    COMMIT_MSG="${COMMIT_MSG}
- $q"
  done
fi

COMMIT_MSG="${COMMIT_MSG}

Session: $(date +%Y-%m-%d\ %H:%M)
Mode: ${MODE}

Next: /plan (or /clarify to resolve remaining)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git commit -m "$COMMIT_MSG"
```

## ERROR HANDLING & ROLLBACK

**If any update fails:**

```bash
rollback_clarify() {
  echo "⚠️  Clarification failed. Rolling back changes..."

  # Restore from checkpoint
  git checkout "$FEATURE_SPEC"

  echo "✓ Rolled back to pre-clarification state"
  echo "Error: $1"
  exit 1
}

# Usage: trap errors
# Example: validate_update || rollback_clarify "Validation failed"
```

## AUTO-COMPACTION

**Context management:**

```bash
COMPACT_THRESHOLD=50000  # Tokens (planning quality degrades above this)
```

In `/flow` mode, auto-compaction runs after clarifications:
- ✅ Preserve: Spec decisions, clarification Q&A, updated requirements
- ❌ Remove: Redundant research, initial ambiguity markers, verbose rationale quotes
- Strategy: Aggressive (planning phase)

**Manual compact instruction (standalone mode):**
```bash
/compact "preserve spec decisions and clarifications"
```

**When to compact:**
- Auto: After `/clarify` in `/flow` mode
- Manual: If context >50k tokens before `/plan`
- Rationale: Planning quality degrades above 50k tokens (empirical observation)

## RETURN

**Brief summary with actionable next steps:**

```bash
RESOLVED_COUNT=$((AMBIGUITY_COUNT - ${#SKIPPED_QUESTIONS[@]}))
REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CLARIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: ${SLUG}"
echo "Spec: ${FEATURE_SPEC}"
echo ""
echo "Summary:"
echo "- Questions resolved: ${RESOLVED_COUNT}/${AMBIGUITY_COUNT}"
echo "- Mode: ${MODE}"
echo "- Session: $(date +%Y-%m-%d\ %H:%M)"

if [ ${#SKIPPED_QUESTIONS[@]} -gt 0 ]; then
  echo "- Skipped: ${#SKIPPED_QUESTIONS[@]} (deferred)"
fi

echo ""
echo "Updates:"
# List updated sections
UPDATED_SECTIONS=$(git diff HEAD~1 "$FEATURE_SPEC" | grep "^+" | grep "^## " | sed 's/^+## //' | sort -u)
if [ -n "$UPDATED_SECTIONS" ]; then
  echo "$UPDATED_SECTIONS" | sed 's/^/  - /'
else
  echo "  - Clarifications section"
fi

echo ""

# Update NOTES.md with Phase 0.5 checkpoint
source \spec-flow/templates/notes-update-template.sh

update_notes_checkpoint "$FEATURE_DIR" "0.5" "Clarify" \
  "Questions answered: $RESOLVED_COUNT" \
  "Ambiguities remaining: $REMAINING_COUNT" \
  "Clarification rounds: $ROUND"

update_notes_timestamp "$FEATURE_DIR"

echo "NOTES.md: Phase 0.5 checkpoint added"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$REMAINING_COUNT" -gt 0 ]; then
  echo "⚠️  ${REMAINING_COUNT} ambiguities remaining"
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


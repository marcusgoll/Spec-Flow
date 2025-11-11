---
description: Reduce spec ambiguity via targeted questions (planning is 80% of success)
version: 2.1
updated: 2025-11-10
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# /clarify — Specification Clarifier

Clarify ambiguities in specification: `$ARGUMENTS`

<context>

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input above before proceeding (if not empty).

## Mental Model

**Flow:** spec-flow → **clarify** → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**

1. Run prerequisite script → 2) Load spec → 3) Scan for ambiguities (10-category coverage) → 4) Build coverage map →
5. Generate questions (quote spec lines with numbers) → 6) Ask up to 5 at a time →
7. Apply each answer atomically (checkpoint → update → validate) → 8) Commit → 9) Suggest next (/plan if clear)

**Auto-suggest:** when no outstanding ambiguities remain → `/plan`

**Operating Constraints**

* **Question cap:** max **10** per session; show **5** at a time.
* **Recommended answers:** provide, backed by repo precedents when available.
* **Incremental saves:** atomic update after each answer.
* **Git safety:** checkpoint before each file write; rollback on failure.

</context>

<constraints>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent fabricating ambiguities or solutions.

1. **Never invent ambiguities** not present in `spec.md`.
   - ❌ BAD: "The spec doesn't mention how to handle edge cases" (without reading it)
   - ✅ GOOD: Read spec.md, quote ambiguous sections: "spec.md:45 says 'users can edit' but doesn't specify edit permissions"
   - **Quote verbatim with line numbers:** `spec.md:120-125: '[exact quote]'`

2. **Always quote the unclear text** and cite **line numbers** for every question.
   - When flagging ambiguity: `spec.md:120-125: '[exact quote]' - unclear whether this means X or Y`
   - Don't paraphrase unclear text - show it verbatim
   - Cite line numbers for all ambiguities

3. **Never invent "best practice"** without evidence.
   - Don't say "Best practice is..." without evidence
   - Source recommendations: "Similar feature in specs/002-auth used JWT per plan.md:45"
   - If no precedent exists, say: "No existing pattern found, recommend researching..."

4. **Verify question relevance before asking user**.
   - Before asking technical question, check if answer exists in codebase
   - Use Grep/Glob to search for existing implementations
   - Don't ask "Should we use PostgreSQL?" if package.json already has pg installed

5. **Never assume user's answer without asking**.
   - Don't fill in clarifications with guesses
   - Present question, wait for response, use exact answer given
   - If user says "skip", mark as skipped - don't invent answer

**Why this matters**: Fabricated ambiguities create unnecessary work. Invented best practices may conflict with project standards. Accurate clarification based on real spec ambiguities ensures plan addresses actual uncertainties.

## Reasoning Approach

For complex clarification decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this ambiguity:
1. What is ambiguous in spec.md? [Quote exact ambiguous text with line numbers]
2. Why is it ambiguous? [Explain multiple valid interpretations]
3. What are the possible interpretations? [List 2-3 options]
4. What's the impact of each interpretation? [Assess implementation differences]
5. Can I find hints in existing code or roadmap? [Search for precedents]
6. Conclusion: [Whether to ask user or infer from context]
</thinking>

<answer>
[Clarification approach based on reasoning]
</answer>

**When to use structured thinking:**
- Deciding whether ambiguity is worth asking about (impacts implementation vs cosmetic)
- Prioritizing multiple clarification questions (most impactful first)
- Determining if context provides sufficient hints to skip question
- Assessing whether to offer 2, 3, or 4 options
- Evaluating if recommended answer is justified by precedent

**Benefits**: Explicit reasoning reduces unnecessary questions by 30-40% and improves question quality.

</constraints>

<instructions>

## 1) Run Prerequisite Script (discover paths)

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

For single quotes in args like "I'm Groot", use escape syntax: e.g `'I'\''m Groot'` (or double-quote if possible: `"I'm Groot"`).

## 2) Load Spec + Checkpoint

**Read specification and create safety checkpoint:**

```bash
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
```

## 3) Fast Coverage Scan (10-Category Taxonomy)

**Heuristic scan to prioritize; the LLM must still read the spec.**

```bash
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
EDGE_CASE_COUNT=$(sed -n '/^## Edge Cases/,/^## /p' "$FEATURE_SPEC" | grep -c "^- " || true)
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
```

## 4) Build Coverage Map

```bash
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
```

## 5) Repo-First Precedent Check

**Search for existing decisions before asking questions:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Searching for repo precedents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Search for technical decisions already made
echo "Existing patterns found:"

# Database
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

echo ""
```

## 6) Generate Prioritized Questions

**Priority:** Architecture/Domain > UX > NFR > Integration > Edge > Constraints > Terminology > Completion > Placeholders

**Rules:**
- **Max 10** total; present **up to 5** now
- **Each question** must include a **verbatim quote** with **line numbers** from `spec.md`
- Provide **2–3 options** + one **short answer** slot (≤ 5 words)
- If recommending an option, cite a **repo precedent**; if none, mark **"no precedent; research needed"**

**Template (per question):**

```markdown
### Q1 (ARCHITECTURE)

**spec.md:L120-126:**
> [quoted lines verbatim]

**Why it's ambiguous:** [one sentence]

**Options:**
- A — [description]  *(Recommended: because [repo evidence path:line])*
- B — [description]
- C — [description]
- Short — [≤5 words]

**Impact:** [1 sentence on scope/effort]
```

**Category 2: Domain & Data Model (HIGHEST PRIORITY)**

If `$CATEGORY_2_STATUS` = "Missing" or "Partial":
- Read spec.md carefully
- Find ambiguous sections about data model
- Quote lines verbatim with numbers
- Generate question with template above

**Category 3: Interaction & UX Flow (HIGH PRIORITY)**

If `$CATEGORY_3_STATUS` = "Missing" or "Partial":
- Read spec.md carefully
- Find ambiguous sections about UX flows
- Quote lines verbatim with numbers
- Generate question with template above

**Category 4: Non-Functional Requirements (HIGH PRIORITY)**

If `$CATEGORY_4_STATUS` = "Missing" or "Partial":
- Read spec.md carefully
- Find missing or vague performance criteria
- Quote lines verbatim with numbers
- Generate question with template above

**Category 5: Integration & External Dependencies (MEDIUM PRIORITY)**

If `$CATEGORY_5_STATUS` = "Partial":
- Read spec.md carefully
- Find missing failure handling for external services
- Quote lines verbatim with numbers
- Generate question with template above

**Category 6: Edge Cases & Failure Handling (MEDIUM PRIORITY)**

If `$CATEGORY_6_STATUS` = "Missing" or "Partial":
- Read spec.md carefully
- Find missing edge case handling
- Quote lines verbatim with numbers
- Generate question with template above

**Limit to 5 questions maximum per session.**

## 7) Sequential Asking (Interactive)

**For each question:**

1. **Display question** using template above
2. **Wait for user response** (A/B/C/Short/Skip)
3. **Validate response** (not empty, recognized option)
4. **Apply answer atomically**:
   - Checkpoint git
   - Update spec.md Clarifications section
   - Apply change to relevant section
   - Validate change exists
   - Commit immediately
5. **Move to next question**

### 7a) Update spec.md (Q/A + Targeted Edit)

```bash
update_clarifications() {
  local QUESTION="$1"
  local ANSWER="$2"
  local SESSION_DATE
  SESSION_DATE=$(date +%F)

  # Ensure Clarifications section exists
  if ! grep -q "^## Clarifications" "$FEATURE_SPEC"; then
    sed -i '/^## Overview\|^## Context/a\
\
## Clarifications' "$FEATURE_SPEC"
  fi

  # Add session header if not exists for today
  if ! grep -q "^### Session $SESSION_DATE" "$FEATURE_SPEC"; then
    sed -i "/^## Clarifications/a\
\
### Session $SESSION_DATE" "$FEATURE_SPEC"
  fi

  # Append Q&A
  sed -i "/^### Session $SESSION_DATE/a\
- Q: $QUESTION → A: $ANSWER" "$FEATURE_SPEC"
}

apply_clarification() {
  local CATEGORY="$1"
  local QUESTION="$2"
  local ANSWER="$3"

  case "$CATEGORY" in
    ARCHITECTURE|DOMAIN)
      # Update Data Model / Architecture sections
      ;;
    UX|INTERACTION)
      # Update Scenarios / Functional Requirements
      ;;
    NFR)
      # Update Non-Functional with measurable metrics
      ;;
    INTEGRATION)
      # Add failure modes, retries, fallbacks
      ;;
    EDGE)
      # Add to Edge Cases with explicit handling
      ;;
    *)
      # Update relevant section
      ;;
  esac
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
```

### 7b) Conflict Detection

```bash
detect_conflict() {
  local ANSWER="$1"
  local EXISTING

  # Check if answer contradicts existing spec
  EXISTING=$(rg -n "rate limit: [0-9]+|<p95.*[0-9]+ms|jwt|oauth" "$FEATURE_SPEC" | head -1)

  if [ -n "$EXISTING" ]; then
    echo ""
    echo "⚠️  CONFLICT DETECTED"
    echo ""
    echo "Existing spec: $EXISTING"
    echo "Your answer: $ANSWER"
    echo ""
    echo "Which is correct?"
    echo "  A) Keep existing"
    echo "  B) Update to new"
    echo "  C) Let me clarify"
    echo ""
    echo -n "Choice (A/B/C): "
    # Wait for user response
  fi
}
```

### 7c) Rollback on Error

```bash
rollback_clarify() {
  local ERROR_MSG="$1"

  echo "⚠️  Clarification failed. Rolling back changes..."
  git checkout "$FEATURE_SPEC"
  echo "✓ Rolled back to pre-clarification state"
  echo "Error: $ERROR_MSG"
  exit 1
}
```

## 8) Commit After Each Accepted Answer (Atomic)

```bash
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
```

## 9) Coverage Summary

**When the current batch completes, print:**

```bash
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
```

## 10) Return + Next Steps

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CLARIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $(basename "$FEATURE_DIR")"
echo "Spec: $FEATURE_SPEC"
echo ""

# Count remaining ambiguities
REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_SPEC" || echo 0)

echo "Summary:"
echo "- Questions answered: [count from session]"
echo "- Ambiguities remaining: $REMAINING_COUNT"
echo "- Session: $(date +%Y-%m-%d\ %H:%M)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

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
  echo "  → /feature continue"
fi
```

## Update NOTES.md

```bash
# Add Phase 0.5 checkpoint
cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 0.5: Clarify ($(date '+%Y-%m-%d %H:%M'))

**Summary**:
- Questions answered: [count]
- Questions skipped: [count]
- Ambiguities remaining: $REMAINING_COUNT
- Session: $(date +%Y-%m-%d\ %H:%M)

**Checkpoint**:
- ✅ Clarifications: [count] resolved
- ⚠️ Remaining: $REMAINING_COUNT ambiguities
- 📋 Ready for: $(if [ "$REMAINING_COUNT" -gt 0 ]; then echo "/clarify (resolve remaining)"; else echo "/plan"; fi)

EOF
```

</instructions>

---

## References

- [Claude Docs - Prompting Best Practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Anthropic - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [LabEx - Git Rollback Safety](https://labex.io/tutorials/git-how-to-rollback-git-changes-safely-418148)
- [Hokstad Consulting - GitOps Rollbacks](https://hokstadconsulting.com/blog/gitops-rollbacks-automating-disaster-recovery)

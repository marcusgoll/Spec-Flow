# Vision Alignment Validation

## Step 2: Load Project Documentation Context

### Purpose
Load project vision, scope boundaries, and target users from `docs/project/overview.md` to validate feature alignment before adding to roadmap.

### When to Execute
- Always before ADD/BRAINSTORM actions
- Skip for MOVE/DELETE/SEARCH operations

### Detection Logic

```bash
PROJECT_OVERVIEW="docs/project/overview.md"
HAS_PROJECT_DOCS=false

if [ -f "$PROJECT_OVERVIEW" ]; then
  HAS_PROJECT_DOCS=true
  echo "✅ Project documentation found"
  echo ""

  # Read project context for validation
  # Claude Code: Read docs/project/overview.md

  # Extract key sections (see extraction logic below)
else
  echo "ℹ️  No project documentation found"
  echo "   Run /init-project to create project design docs"
  echo "   (Optional - roadmap works without it)"
  echo ""
fi
```

### Extraction Logic

```bash
# Extract project vision (1 paragraph under "Vision" heading)
VISION=$(sed -n '/^## Vision/,/^##/p' "$PROJECT_OVERVIEW" | sed '1d;$d' | head -10)

# Extract out-of-scope items (bullet list under "Out of Scope")
OUT_OF_SCOPE=$(sed -n '/^### Out of Scope/,/^##/p' "$PROJECT_OVERVIEW" | grep -E '^\s*[-*]' | sed 's/^[[:space:]]*[-*][[:space:]]*//')

# Extract target users (bullet list under "Target Users")
TARGET_USERS=$(sed -n '/^## Target Users/,/^##/p' "$PROJECT_OVERVIEW" | grep -E '^\s*[-*]' | sed 's/^[[:space:]]*[-*][[:space:]]*//')

# Store for validation
export VISION OUT_OF_SCOPE TARGET_USERS
```

### Example Extracted Context

```
Vision:
AKTR helps flight instructors track student progress against ACS standards,
enabling data-driven instruction and transparent competency demonstration.

Out of Scope:
- Flight scheduling or aircraft management
- Payment processing or student billing
- General aviation weather briefings

Target Users:
- Certified Flight Instructors (CFIs)
- Flight students (private, instrument, commercial)
- Flight school administrators
```

---

## Step 4: Vision Alignment Validation

### Validation Workflow

```bash
if [ "$HAS_PROJECT_DOCS" = true ] && [ "$ACTION" = "add" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 VISION ALIGNMENT CHECK"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Project Vision:"
  echo "$VISION"
  echo ""
  echo "Proposed Feature:"
  echo "  $FEATURE_DESCRIPTION"
  echo ""

  # Check 1: Out-of-scope validation
  IS_OUT_OF_SCOPE=false
  while IFS= read -r excluded_item; do
    # Fuzzy match (case-insensitive substring)
    if echo "$FEATURE_DESCRIPTION" | grep -qi "$(echo "$excluded_item" | cut -d' ' -f1-3)"; then
      IS_OUT_OF_SCOPE=true
      MATCHED_EXCLUSION="$excluded_item"
      break
    fi
  done <<< "$OUT_OF_SCOPE"

  if [ "$IS_OUT_OF_SCOPE" = true ]; then
    echo "❌ OUT-OF-SCOPE DETECTED"
    echo ""
    echo "This feature matches an explicit exclusion:"
    echo "  \"$MATCHED_EXCLUSION\" (overview.md:45)"
    echo ""
    echo "Options:"
    echo "  A) Skip (reject out-of-scope feature)"
    echo "  B) Update overview.md (remove exclusion if scope changed)"
    echo "  C) Add anyway (override with justification)"
    read -p "Choice (A/B/C): " alignment_choice

    case $alignment_choice in
      B|b)
        echo "Update overview.md to remove this exclusion, then retry"
        exit 0
        ;;
      C|c)
        echo "Provide justification for override:"
        read -p "> " JUSTIFICATION
        # Add note to issue body
        ALIGNMENT_NOTE="

---

⚠️  **Alignment Note**: Flagged as out-of-scope per overview.md, but added with justification:
> $JUSTIFICATION"
        ;;
      A|a|*)
        echo "Feature rejected (out of scope per overview.md)"
        exit 0
        ;;
    esac
  fi

  # Check 2: Vision alignment (semantic check via Claude)
  # Claude Code: Analyze if feature supports vision
  # Returns: aligned (true/false), concerns (list)

  if [ "$ALIGNED" = false ]; then
    echo "⚠️  Potential misalignment detected"
    echo ""
    echo "Concerns:"
    for concern in "${CONCERNS[@]}"; do
      echo "  - $concern"
    done
    echo ""
    echo "Options:"
    echo "  A) Add anyway (alignment override)"
    echo "  B) Revise feature to align"
    echo "  C) Skip (not aligned with vision)"
    read -p "Choice (A/B/C): " alignment_choice

    case $alignment_choice in
      B|b)
        echo "Describe how to revise:"
        read -p "> " revision
        # Update FEATURE_DESCRIPTION with revised approach
        FEATURE_DESCRIPTION="$revision"
        ;;
      C|c)
        echo "Feature rejected (vision misalignment)"
        exit 0
        ;;
      A|a)
        echo "Proceeding anyway (alignment override)"
        # Add note to issue body
        ALIGNMENT_NOTE="

---

⚠️  **Alignment Note**: Flagged as potentially misaligned with vision, but added per user request."
        ;;
    esac
  else
    echo "✅ Feature aligns with project vision"
  fi

  # Check 3: Target user validation
  # Ensure feature serves at least one documented target user
  echo ""
  echo "Target User Check:"
  echo "Does this feature serve: $TARGET_USERS"
  read -p "Confirm primary user (or 'skip'): " PRIMARY_USER

  if [ "$PRIMARY_USER" != "skip" ]; then
    # Will be stored in issue metadata
    ROLE_LABEL="role:$(echo "$PRIMARY_USER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
  fi

  echo ""
fi
```

---

## Decision Tree

```
Feature proposed
    |
    v
Is overview.md present?
    |-- No --> Skip validation, proceed to ICE scoring
    |
    v (Yes)
Extract: Vision, Out-of-Scope, Target Users
    |
    v
Check 1: Is feature in Out-of-Scope list?
    |-- Yes --> Prompt: Skip / Update overview / Override
    |           |-- Skip --> Exit (rejected)
    |           |-- Update --> Exit (user updates overview.md first)
    |           |-- Override --> Add ALIGNMENT_NOTE, continue
    |
    v (No)
Check 2: Does feature support Vision? (semantic analysis)
    |-- No --> Prompt: Add anyway / Revise / Skip
    |           |-- Skip --> Exit (rejected)
    |           |-- Revise --> Update description, retry Check 2
    |           |-- Add anyway --> Add ALIGNMENT_NOTE, continue
    |
    v (Yes)
Check 3: Does feature serve Target Users?
    |-- Yes --> Extract role label
    |
    v
✅ Validation passed, proceed to ICE scoring
```

---

## Output Examples

### Case 1: Out-of-scope detected

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 VISION ALIGNMENT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Vision:
AKTR helps flight instructors track student progress against ACS standards.

Proposed Feature:
  Add flight scheduling and aircraft booking

❌ OUT-OF-SCOPE DETECTED

This feature matches an explicit exclusion:
  "Flight scheduling or aircraft management" (overview.md:45)

Options:
  A) Skip (reject out-of-scope feature)
  B) Update overview.md (remove exclusion if scope changed)
  C) Add anyway (override with justification)
Choice (A/B/C): A

Feature rejected (out of scope per overview.md)
```

### Case 2: Vision misalignment detected

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 VISION ALIGNMENT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Vision:
AKTR helps flight instructors track student progress against ACS standards.

Proposed Feature:
  Add social media integration for student profiles

⚠️  Potential misalignment detected

Concerns:
  - Feature focuses on social networking, not ACS tracking
  - No clear connection to competency demonstration
  - May distract from core learning objectives

Options:
  A) Add anyway (alignment override)
  B) Revise feature to align
  C) Skip (not aligned with vision)
Choice (A/B/C): B

Describe how to revise:
> Add ACS achievement badges that students can share to social media to demonstrate competency milestones

✅ Revised feature aligns with vision
```

### Case 3: Validation passed

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 VISION ALIGNMENT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Vision:
AKTR helps flight instructors track student progress against ACS standards.

Proposed Feature:
  Add student progress widget showing mastery percentage by ACS area

✅ Feature aligns with project vision

Target User Check:
Does this feature serve: CFIs, Flight students, School admins
Confirm primary user (or 'skip'): Flight students

✅ Vision alignment complete
```

---

## Semantic Vision Analysis

### Claude Analysis Prompt

When checking vision alignment (Check 2), use this prompt:

```
Analyze if this proposed feature aligns with the project vision.

Project Vision:
{VISION}

Proposed Feature:
{FEATURE_DESCRIPTION}

Return:
1. aligned: true/false
2. concerns: list of specific misalignment issues (if any)
3. suggestions: how to revise feature to align better (if misaligned)

Alignment criteria:
- Feature directly supports vision goals
- Feature serves documented target users
- Feature doesn't distract from core objectives
- Feature is within project scope boundaries
```

### Example Analysis

**Input:**
```
Vision: AKTR helps flight instructors track student progress against ACS standards.
Feature: Add dark mode theme toggle
```

**Output:**
```json
{
  "aligned": false,
  "concerns": [
    "Feature is purely cosmetic, doesn't relate to ACS tracking",
    "No connection to student progress or instructor workflows",
    "Theme preference not related to competency demonstration"
  ],
  "suggestions": [
    "If theme is accessibility-related, frame as 'Accessibility: High-contrast mode for visually impaired students tracking ACS progress'",
    "Otherwise, consider this a low-priority polish task, not a core feature"
  ]
}
```

---

## Alignment Note Format

When user overrides validation (out-of-scope or misalignment), add this to GitHub Issue body:

```markdown
---

⚠️  **Alignment Note**: [Validation Warning]

[Justification provided by user]

---
```

**Examples:**

```markdown
---

⚠️  **Alignment Note**: Flagged as out-of-scope per overview.md, but added with justification:
> Scope expanded to include basic scheduling for lesson management. Updated roadmap to reflect new direction.

---
```

```markdown
---

⚠️  **Alignment Note**: Flagged as potentially misaligned with vision, but added per user request.

User believes this feature will indirectly support ACS tracking by improving student engagement.

---
```

---

## Token Budget

**Vision validation per feature:**
- overview.md read: ~5-8K tokens (2-3 page document)
- Vision, Out-of-Scope, Target Users extraction: ~1K tokens
- Semantic alignment analysis: ~2-3K tokens
- **Total: ~8-12K tokens per ADD action with vision validation**

**Without project docs:**
- Skip validation, proceed directly to issue creation: ~2-3K tokens

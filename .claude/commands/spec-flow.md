---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Validate input -> Check git -> Feature classification -> Check roadmap -> Research -> Generate spec -> Update roadmap -> Suggest next

**Roadmap integration:**
- If feature found in roadmap (by slug): Reuses context + moves to "In Progress" + adds branch/spec links
- If not found: Creates fresh spec (can add to roadmap later with `/roadmap add`)

**Auto-suggest:**
- If `[NEEDS CLARIFICATION]` found -> `/clarify`
- If spec clear -> `/plan`

**Naming Convention (v2.0 - Concise)**:
- Format: `short-descriptive-name` (no numbers, no dates)
- Max length: 50 characters
- Removes filler words: "we want to", "get our", "to a", "with", "before moving on to", etc.
- Example: "We want to add student progress dashboard" → `add-student-progress-dashboard`
- Example: "We want to get our vercel and railway app to a healthy state..." → `vercel-railway-app-healthy-state`

## CONTEXT

**Path constants:**
```bash
ROADMAP_FILE=".spec-flow/memory/roadmap.md"
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"
INSPIRATIONS_FILE=".spec-flow/memory/design-inspirations.md"
UI_INVENTORY_FILE="design/systems/ui-inventory.md"
BUDGETS_FILE="design/systems/budgets.md"

SPEC_TEMPLATE=".spec-flow/templates/spec-template.md"
HEART_TEMPLATE=".spec-flow/templates/heart-metrics-template.md"
SCREENS_TEMPLATE=".spec-flow/templates/screens-yaml-template.yaml"
VISUALS_TEMPLATE=".spec-flow/templates/visuals-readme-template.md"
```

**Context management:**
```bash
COMPACT_THRESHOLD=50000  # Planning quality degrades above 50k tokens
                         # Based on: Research shows optimal planning context <50k
```

## INPUT VALIDATION

**Sanitize and validate arguments:**
```bash
# Check arguments provided
if [ -z "$ARGUMENTS" ]; then
  echo "Error: Feature name required"
  echo "Usage: /spec-flow [feature-name]"
  exit 1
fi

# Generate concise slug (max 50 chars, remove filler words)
SLUG=$(echo "$ARGUMENTS" |
  tr '[:upper:]' '[:lower:]' |
  # Remove common filler words
  sed 's/\bwe want to\b//g; s/\bget our\b//g; s/\bto a\b//g; s/\bwith\b//g' |
  sed 's/\bbefore moving on to\b//g; s/\bother features\b//g' |
  sed 's/\bsuccessful builds\b/builds/g; s/\bhealthy state\b/health/g' |
  # Convert to hyphen-separated
  sed 's/[^a-z0-9-]/-/g' |
  sed 's/--*/-/g' |
  sed 's/^-//;s/-$//' |
  # Truncate to 50 chars max
  cut -c1-50 |
  sed 's/-$//')

# Validate slug is not empty after sanitization
if [ -z "$SLUG" ]; then
  echo "Error: Invalid feature name (results in empty slug)"
  echo "Provided: $ARGUMENTS"
  exit 1
fi

# Prevent path traversal
if [[ "$SLUG" == *".."* ]] || [[ "$SLUG" == *"/"* ]]; then
  echo "Error: Invalid characters in feature name"
  exit 1
fi

# Show generated slug
echo "Generated slug: $SLUG"
echo "From: $ARGUMENTS"
```

## GIT VALIDATION (before any changes)

**Check git state before touching anything:**
```bash
# 1. Check working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  Git working directory has uncommitted changes"
  echo ""
  git status --short
  echo ""
  echo "Options:"
  echo "  A) Stash changes (git stash)"
  echo "  B) Commit changes first"
  echo "  C) Abort /spec-flow"
  echo ""
  read -p "Choice (A/B/C): " choice

  case $choice in
    A|a) git stash ;;
    B|b) echo "Commit your changes, then re-run /spec-flow"; exit 1 ;;
    C|c) echo "Aborted"; exit 0 ;;
    *) echo "Invalid choice, aborting"; exit 1 ;;
  esac
fi

# 2. Check not on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "Error: Cannot create spec on main branch"
  echo "Run: git checkout -b feature-branch-name"
  exit 1
fi

# 3. Check branch doesn't already exist
if git show-ref --verify --quiet refs/heads/${SLUG}; then
  echo "Error: Branch '${SLUG}' already exists"
  echo "Run: git checkout ${SLUG} (to switch to it)"
  echo "Or: Choose different feature name"
  exit 1
fi

# 4. Check spec directory doesn't exist
if [ -d "specs/${SLUG}" ]; then
  echo "Error: Spec directory 'specs/${SLUG}/' already exists"
  echo "Run: /spec-flow [different-name]"
  exit 1
fi
```

## TEMPLATE VALIDATION

**Verify required templates exist:**
```bash
REQUIRED_TEMPLATES=(
  "$SPEC_TEMPLATE"
  "$HEART_TEMPLATE"
  "$SCREENS_TEMPLATE"
  "$VISUALS_TEMPLATE"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
  if [ ! -f "$template" ]; then
    echo "Error: Missing required template: $template"
    echo "Run: git checkout main -- .spec-flow/templates/"
    exit 1
  fi
done
```

## INITIALIZE

**Create feature structure:**
```bash
# Set up paths
FEATURE_DIR="specs/${SLUG}"
SPEC_FILE="$FEATURE_DIR/spec.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

# Create branch
git checkout -b ${SLUG}

# Create directory structure
mkdir -p ${FEATURE_DIR}/{visuals,artifacts,design/queries}

# Create NOTES.md stub (created early so research can write to it)
cat > $NOTES_FILE <<EOF
# Feature: $ARGUMENTS

## Overview
[To be filled during spec generation]

## Research Findings
[Populated during research phase]

## System Components Analysis
[Populated during system component check]

## Checkpoints
- Phase 0 (Spec-flow): $(date -I)

## Last Updated
$(date -Iseconds)
EOF
```

## CHECK ROADMAP (auto-detection)

**Auto-detect roadmap features by slug:**

```bash
FROM_ROADMAP=false

if [ -f "$ROADMAP_FILE" ]; then
  # Normalize search (lowercase, exact slug match)
  if grep -qi "^### ${SLUG}" "$ROADMAP_FILE"; then
    FROM_ROADMAP=true

    # Extract requirements, area, role, impact/effort
    # Use as starting point for spec
    # Preserve [CLARIFY: ...] tags

    echo "✓ Found '${SLUG}' in roadmap - reusing context"
  else
    # Offer fuzzy match suggestions (Levenshtein distance < 3 edits)
    # If no close matches, continue with fresh spec
    echo "✓ Creating fresh spec (not found in roadmap)"
  fi
fi
```

**Roadmap slug matching algorithm:**
1. Normalize input: lowercase, hyphenate spaces
2. Check roadmap for exact slug match: `^### ${SLUG}`
3. If no match, offer fuzzy suggestions (edit distance < 3)
4. If still no match, create fresh spec

**If found in roadmap:**
- Reuse context automatically
- Will update roadmap after spec creation (move to "In Progress", add branch/spec links)

**If not found:**
- Continue with research workflow
- Optional: Add to roadmap later with `/roadmap add`

## FEATURE CLASSIFICATION (consolidate skip-if logic)

**Ask user or infer from requirements to determine which artifacts to generate:**

```bash
# Analyze feature requirements to classify
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 FEATURE CLASSIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Analyzing: $ARGUMENTS"
echo ""

# Feature type (determines UI artifacts)
HAS_UI=false
if [[ "$ARGUMENTS" =~ (screen|page|UI|component|dashboard|form|modal) ]]; then
  HAS_UI=true
fi

# Change type (determines hypothesis)
IS_IMPROVEMENT=false
if [[ "$ARGUMENTS" =~ (improve|optimize|reduce|increase|faster) ]]; then
  IS_IMPROVEMENT=true
fi

# Measurable outcomes (determines HEART metrics)
HAS_METRICS=false
if [[ "$ARGUMENTS" =~ (user|engagement|retention|conversion|completion) ]]; then
  HAS_METRICS=true
fi

# Deployment complexity (determines deployment section)
HAS_DEPLOYMENT_IMPACT=false
if [[ "$ARGUMENTS" =~ (migration|env|breaking|platform|infrastructure) ]]; then
  HAS_DEPLOYMENT_IMPACT=true
fi

# Ask user to confirm classification
echo "Detected classification:"
echo "  UI screens: ${HAS_UI} (generates screens.yaml, copy.md, system check)"
echo "  Improvement: ${IS_IMPROVEMENT} (generates hypothesis)"
echo "  Measurable: ${HAS_METRICS} (generates HEART metrics)"
echo "  Deployment impact: ${HAS_DEPLOYMENT_IMPACT} (prompts deployment questions)"
echo ""
echo "Is this correct? (Y/n/customize)"
read -p "Choice: " classification_choice

case $classification_choice in
  n|N)
    # Manual classification
    read -p "Has UI screens? (y/n): " has_ui_input
    [[ "$has_ui_input" =~ ^[Yy]$ ]] && HAS_UI=true || HAS_UI=false

    read -p "Improvement feature? (y/n): " is_improvement_input
    [[ "$is_improvement_input" =~ ^[Yy]$ ]] && IS_IMPROVEMENT=true || IS_IMPROVEMENT=false

    read -p "Has measurable outcomes? (y/n): " has_metrics_input
    [[ "$has_metrics_input" =~ ^[Yy]$ ]] && HAS_METRICS=true || HAS_METRICS=false

    read -p "Deployment impact? (y/n): " has_deployment_input
    [[ "$has_deployment_input" =~ ^[Yy]$ ]] && HAS_DEPLOYMENT_IMPACT=true || HAS_DEPLOYMENT_IMPACT=false
    ;;
  customize|c|C)
    # Let user customize each
    # (same as 'n' flow above)
    ;;
  *)
    # Accept auto-detected classification
    ;;
esac

# Store in NOTES.md for reference
cat >> $NOTES_FILE <<EOF

## Feature Classification
- UI screens: ${HAS_UI}
- Improvement: ${IS_IMPROVEMENT}
- Measurable: ${HAS_METRICS}
- Deployment impact: ${HAS_DEPLOYMENT_IMPACT}
EOF
```

**Result**: Single decision tree evaluated once, determines which artifacts to generate.

## RESEARCH (3-8 tool calls)

**Gather context before writing:**

**Always read** (1-3 tools):
1. `$CONSTITUTION_FILE` → Check compliance with mission/values
2. `$UI_INVENTORY_FILE` → List reusable components (if `$HAS_UI = true`)
3. `$BUDGETS_FILE` → Performance targets (if `$HAS_UI = true`)

**Conditionally read** (0-3 tools):
4. `Glob specs/**/spec.md` → If similar feature exists (search by keyword in $ARGUMENTS)
5. `$INSPIRATIONS_FILE` → If UX pattern needed (`$HAS_UI = true`)
6. `Grep codebase` → If integrating with existing code (infer from $ARGUMENTS keywords)

**External research** (0-2 tools):
7. `WebSearch "UX pattern [feature-type] 2025"` → If `$HAS_UI = true` and no internal pattern found
8. `chrome-devtools [URL]` → If user provided reference site in $ARGUMENTS

**Output**: Document findings in `$NOTES_FILE` before generating spec.

```bash
# Example research output
cat >> $NOTES_FILE <<EOF

## Research Findings
- Finding 1: Similar pattern in specs/012-aktr-results-core/ (inline preview)
  Source: Glob specs/**/spec.md

- Finding 2: Reusable components: Card, Button, Progress, Alert
  Source: design/systems/ui-inventory.md
  Decision: No new components needed

- Finding 3: Performance budget: FCP <1.5s, LCP <2.5s
  Source: design/systems/budgets.md
  Implication: Must use lazy loading for images

- Finding 4: Industry pattern: Drag-and-drop file upload with instant preview
  Source: WebSearch - "file upload UX 2025"
  Reference: Dropbox, Notion
EOF
```

## SYSTEM COMPONENT CHECK (UI Features Only)

**Before designing UI, check what exists:**

**Run if**: `$HAS_UI = true`

**Skip if**: `$HAS_UI = false` (backend-only, API-only)

```bash
if [ "$HAS_UI" = true ]; then
  # Read component catalog
  cat $UI_INVENTORY_FILE

  # Identify which components apply to this feature
  # Document in NOTES.md

  cat >> $NOTES_FILE <<EOF

## System Components Analysis
**Reusable (from ui-inventory.md)**:
- Card (container)
- Button (primary CTA)
- Progress (upload feedback)
- Alert (errors)

**New Components Needed**:
- None (compose existing primitives)
OR
- FileUploadDropZone (proposal needed in design/systems/proposals/)

**Rationale**: System-first approach reduces implementation time and ensures consistency.
EOF
fi
```

## GENERATE HEART METRICS (Measurable Features)

**For features with user outcomes to track:**

**Run if**: `$HAS_METRICS = true`

**Skip if**: `$HAS_METRICS = false` (no measurable user behavior, internal tooling, DB migrations)

Create `${FEATURE_DIR}/design/heart-metrics.md` from `$HEART_TEMPLATE`:

1. **Happiness**: Error rates
   - Target: `<2% error rate` (down from 5%)
   - Measure: `grep '"event":"error"' logs/metrics/*.jsonl`

2. **Engagement**: Usage frequency
   - Target: `2+ uses/user/week` (up from 1.2)
   - Measure: `SELECT COUNT(*) FROM feature_metrics GROUP BY user_id`

3. **Adoption**: New user activation
   - Target: `+20% signups`
   - Measure: `SELECT COUNT(*) FROM users WHERE created_at >= ...`

4. **Retention**: Repeat usage
   - Target: `40% 7-day return rate` (up from 25%)
   - Measure: `SELECT COUNT(DISTINCT user_id) / total_users FROM user_sessions`

5. **Task Success**: Completion rate
   - Target: `85% completion` (up from 65%)
   - Measure: `SELECT COUNT(*) FILTER (WHERE outcome='completed') / COUNT(*)`

**Include measurement sources**: SQL queries, log patterns, Lighthouse thresholds.

## GENERATE SCREENS INVENTORY (UI Features Only)

**For features with UI screens:**

**Run if**: `$HAS_UI = true`

**Skip if**: `$HAS_UI = false` (no UI screens)

Create `${FEATURE_DIR}/design/screens.yaml` from `$SCREENS_TEMPLATE`:

**List screens**:
- upload: Primary action = "Select File", States = [default, uploading, error]
- preview: Primary action = "Confirm", States = [loading, ready, invalid]
- results: Primary action = "Export", States = [processing, complete, empty]

**For each screen**:
- ID, name, route, purpose
- Primary action (CTA)
- States (default, loading, empty, error)
- Components (from ui-inventory.md)
- Copy (real text, not Lorem Ipsum)

Create `${FEATURE_DIR}/design/copy.md`:
```markdown
# Copy: [Feature Name]

## Screen: upload
**Heading**: Upload AKTR Report
**Subheading**: Get ACS-mapped weak areas in seconds
**CTA Primary**: Extract ACS Codes
**Help Text**: Accepts PDF or image files up to 50MB

**Error Messages**:
- FILE_TOO_LARGE: "File exceeds 50MB limit..."
- INVALID_FORMAT: "Only PDF, JPG, PNG supported..."
```

## GENERATE HYPOTHESIS (Improvement Features)

**For features improving existing flows:**

**Run if**: `$IS_IMPROVEMENT = true`

**Skip if**: `$IS_IMPROVEMENT = false` (pure feature addition, no existing baseline to improve)

Document in spec.md:

**Problem**: Upload → redirect → wait causes 25% abandonment
- Evidence: Logs show 25% users never reach results
- Impact: Students miss core value prop

**Solution**: Inline preview (no redirect) with real-time progress
- Change: Upload → preview → extract on same screen
- Mechanism: Reduces cognitive load, provides instant feedback

**Prediction**: Time-to-insight <8s will reduce abandonment to <10%
- Primary metric: Task completion +20% (65% → 85%)
- Expected improvement: -47% time (15s → 8s)
- Confidence: High (similar pattern in design-inspirations.md)

## DEPLOYMENT CONSIDERATIONS (Critical for Planning)

**Prompt for deployment context to inform planning phase:**

**Run if**: `$HAS_DEPLOYMENT_IMPACT = true`

**Skip if**: `$HAS_DEPLOYMENT_IMPACT = false` (cosmetic UI changes, documentation-only)

**Qualifier question first:**
```
Does this feature require deployment changes?
- Platform dependencies (Vercel/Railway config)
- Environment variables (NEXT_PUBLIC_*, secrets)
- Breaking changes (API contracts, auth)
- Database migrations (schema, data)

(Y/n):
```

**If NO**: Skip entire deployment section

**If YES**: Ask 4 detailed questions:

1. **Platform dependencies?**
   - Vercel edge middleware changes?
   - Railway Dockerfile or start command changes?
   - New build steps?

2. **Environment variables?**
   - New `NEXT_PUBLIC_*` variables? (breaking for deployed envs)
   - New secrets/API keys required?
   - Changes to existing env vars?

3. **Breaking changes?**
   - API contract changes requiring version bump?
   - Database schema changes?
   - Auth flow modifications?

4. **Migration required?**
   - New database tables/columns?
   - Data backfill needed?
   - RLS policy changes?

**Document in spec.md** (Deployment Considerations section):
```markdown
## Deployment Considerations

**Platform Dependencies**:
- [None / Vercel: edge middleware for X / Railway: new start command]

**Environment Variables**:
- [None / New: NEXT_PUBLIC_FEATURE_FLAG_X, API_KEY_Y / Changed: NEXT_PUBLIC_API_URL]

**Breaking Changes**:
- [No / Yes: API endpoint /v1/users → /v2/users / Yes: Clerk auth flow change]

**Migration Required**:
- [No / Yes: Add user_preferences table / Yes: Backfill existing users]

**Rollback Considerations**:
- [Standard 3-command rollback / Special: Must downgrade migration / Special: Feature flag required]
```

## GENERATE SPEC

**Create spec artifacts:**

1. **Main spec** (`$SPEC_FILE`):
   - Use `$SPEC_TEMPLATE` as base
   - Fill from roadmap (if `$FROM_ROADMAP = true`) or research
   - User scenarios (Given/When/Then)
   - Requirements (FR-001, FR-002..., NFR-001...)
   - Context Strategy & Signal Design
   - Mark ambiguities: `[NEEDS CLARIFICATION: question]`

2. **NOTES.md** (`$NOTES_FILE`):
   - Already created in INITIALIZE
   - Update with overview and final checkpoint timestamp

3. **Visuals** (if applicable and `$HAS_UI = true`):
   - Create `${FEATURE_DIR}/visuals/README.md` from `$VISUALS_TEMPLATE`
   - Document UX patterns from chrome-devtools
   - Extract layout, colors, interactions, measurements
   - Include reference URLs

## UPDATE ROADMAP (if from roadmap)

**Update roadmap if feature originated there:**

```bash
if [ "$FROM_ROADMAP" = true ]; then
  echo "Updating roadmap: ${SLUG} → In Progress"

  # Find feature in roadmap (by slug heading)
  FEATURE_SECTION=$(grep -n "^### ${SLUG}" "$ROADMAP_FILE" | cut -d: -f1)

  if [ -n "$FEATURE_SECTION" ]; then
    # Extract feature content until next heading or EOF
    # Move feature from current section to "In Progress"
    # Add metadata:
    #   **Branch**: ${SLUG}
    #   **Spec**: specs/${SLUG}/spec.md
    #   **Updated**: $(date +%Y-%m-%d)

    # Implementation:
    # 1. Extract feature entry (from ### to next ### or EOF)
    # 2. Remove from current location
    # 3. Append to "In Progress" section with metadata
    # 4. Update "Updated" timestamp

    # Note: This is pseudocode - actual implementation uses sed/awk
    # or Python script for robust markdown manipulation

    git add $ROADMAP_FILE
    git commit -m "roadmap: move ${SLUG} to In Progress

Branch: ${SLUG}
Spec: specs/${SLUG}/spec.md
Updated after /spec-flow completed"

    echo "✅ Roadmap updated: ${SLUG} now in In Progress"
  else
    echo "⚠️  Feature not found in roadmap (expected heading: ### ${SLUG})"
  fi
fi
```

**Roadmap update flow:**
1. Detect if feature came from roadmap (`FROM_ROADMAP=true`)
2. Find feature heading in roadmap (`### ${SLUG}`)
3. Extract full feature entry (until next heading)
4. Remove from current section (Backlog, Later, Next)
5. Add to "In Progress" section with metadata
6. Commit roadmap change
7. Continue with spec commit

## GIT COMMIT

**Generate commit message dynamically based on artifacts created:**

```bash
# Build commit message based on what exists
COMMIT_MSG="design:spec: add ${SLUG} specification

Phase 0: Spec-flow
- User scenarios (Given/When/Then)
- Requirements documented"

# Add conditional lines based on artifacts
[ -f "${FEATURE_DIR}/design/heart-metrics.md" ] &&
  COMMIT_MSG="${COMMIT_MSG}
- HEART metrics defined (5 dimensions with targets)"

[ -f "${FEATURE_DIR}/design/screens.yaml" ] &&
  COMMIT_MSG="${COMMIT_MSG}
- UI screens inventory ($(grep -c '^  [a-z_]*:' ${FEATURE_DIR}/design/screens.yaml) screens)"

[ -f "${FEATURE_DIR}/design/copy.md" ] &&
  COMMIT_MSG="${COMMIT_MSG}
- Copy documented (real text, no Lorem Ipsum)"

[ "$IS_IMPROVEMENT" = true ] &&
  COMMIT_MSG="${COMMIT_MSG}
- Hypothesis (Problem → Solution → Prediction)"

[ -f "${FEATURE_DIR}/visuals/README.md" ] &&
  COMMIT_MSG="${COMMIT_MSG}
- Visual research documented"

# Count system components if analyzed
if grep -q "System Components Analysis" $NOTES_FILE; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" $NOTES_FILE | grep -c "^-")
  COMMIT_MSG="${COMMIT_MSG}
- System components checked (${REUSABLE_COUNT} reusable)"
fi

# List artifacts
COMMIT_MSG="${COMMIT_MSG}

Artifacts:"

for artifact in spec.md NOTES.md design/*.md design/*.yaml visuals/README.md; do
  [ -f "${FEATURE_DIR}/${artifact}" ] &&
    COMMIT_MSG="${COMMIT_MSG}
- specs/${SLUG}/${artifact}"
done

# Count clarifications
CLARIFICATIONS=$(grep -c "\\[NEEDS CLARIFICATION" $SPEC_FILE || echo 0)

if [ "$CLARIFICATIONS" -gt 0 ]; then
  COMMIT_MSG="${COMMIT_MSG}

Next: /clarify (${CLARIFICATIONS} ambiguities found)"
else
  COMMIT_MSG="${COMMIT_MSG}

Next: /plan"
fi

COMMIT_MSG="${COMMIT_MSG}

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit
git add specs/${SLUG}/
git commit -m "$COMMIT_MSG"
```

## ERROR HANDLING & ROLLBACK

**If any step fails:**

```bash
# Rollback function
rollback_spec_flow() {
  echo "⚠️  Spec generation failed. Rolling back changes..."

  # 1. Return to original branch
  ORIGINAL_BRANCH=$(cat .git/ORIG_HEAD 2>/dev/null || echo "main")
  git checkout $ORIGINAL_BRANCH

  # 2. Delete feature branch
  git branch -D ${SLUG} 2>/dev/null

  # 3. Remove spec directory
  rm -rf specs/${SLUG}

  # 4. Revert roadmap changes (if from roadmap)
  if [ "$FROM_ROADMAP" = true ]; then
    git checkout HEAD -- $ROADMAP_FILE
  fi

  echo "✓ Rolled back all changes"
  echo "Error: $1"
  exit 1
}

# Usage: trap rollback_spec_flow on errors
# Example: [ -f "$SPEC_TEMPLATE" ] || rollback_spec_flow "Missing template"
```

## AUTO-COMPACTION

In `/flow` mode, auto-compaction runs after specification:
- ✅ Preserve: Spec decisions, requirements, UX research, visual insights
- ❌ Remove: Redundant research notes, verbose inspiration quotes
- Strategy: Aggressive (planning phase)

**Manual compact instruction (standalone mode):**
```bash
/compact "preserve spec decisions, requirements, and UX research"
```

**When to compact:**
- Auto: After `/spec-flow` in `/flow` mode
- Manual: If context >`$COMPACT_THRESHOLD` tokens before `/clarify` or `/plan`
- Rationale: Planning quality degrades above 50k tokens (empirical observation)

## AUTO-PROGRESSION

**After spec creation, intelligently suggest next command:**

```bash
# Count clarification markers
CLARIFICATIONS=$(grep -c "\\[NEEDS CLARIFICATION" $SPEC_FILE || echo 0)

if [ "$CLARIFICATIONS" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  AUTO-PROGRESSION: Clarifications needed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $CLARIFICATIONS ambiguities marked [NEEDS CLARIFICATION]"
  echo ""
  echo "Recommended: /clarify"
  echo "Alternative: /plan (proceed with current spec, clarify later)"
  echo ""
  echo "To automate: /flow \"${SLUG}\" (runs full workflow)"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AUTO-PROGRESSION: Spec is clear"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "No ambiguities found - ready for planning"
  echo ""
  echo "Recommended: /plan"
  echo "Alternative: /flow continue (automates plan → tasks → implement → ship)"
fi
```

## RETURN

**Brief summary with actionable next steps:**

```bash
# Count artifacts
ARTIFACT_COUNT=$(find ${FEATURE_DIR} -type f | wc -l)
REQUIREMENT_COUNT=$(grep -c "^- \[FR-\|^- \[NFR-" $SPEC_FILE || echo 0)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SPECIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: ${SLUG}"
echo "Original: ${ARGUMENTS}"
echo "Spec: specs/${SLUG}/spec.md"
echo "Branch: ${SLUG}"
[ "$FROM_ROADMAP" = true ] && echo "Roadmap: Updated to In Progress ✅"
echo ""
echo "Details:"
echo "- Requirements: ${REQUIREMENT_COUNT} documented"

[ "$HAS_METRICS" = true ] && echo "- HEART metrics: 5 dimensions with targets"
[ "$IS_IMPROVEMENT" = true ] && echo "- Hypothesis: Problem → Solution → Prediction"
[ "$HAS_UI" = true ] && echo "- UI screens: $(grep -c '^  [a-z_]*:' ${FEATURE_DIR}/design/screens.yaml 2>/dev/null || echo 0) defined"

if grep -q "System Components Analysis" $NOTES_FILE; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" $NOTES_FILE | grep -c "^-" || echo 0)
  NEW_COUNT=$(grep -A 10 "New Components" $NOTES_FILE | grep -c "^-" || echo 0)
  echo "- System components: ${REUSABLE_COUNT} reusable, ${NEW_COUNT} new needed"
fi

[ -f "${FEATURE_DIR}/visuals/README.md" ] && echo "- Visual research: documented"

echo "- Ambiguities: ${CLARIFICATIONS}"
echo "- Artifacts created: ${ARTIFACT_COUNT}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$CLARIFICATIONS" -gt 0 ]; then
  echo "Manual (step-by-step):"
  echo "  → /clarify (resolve ${CLARIFICATIONS} ambiguities)"
  echo ""
  echo "Automated (full workflow):"
  echo "  → /flow continue"
else
  echo "Manual (step-by-step):"
  echo "  → /plan"
  echo ""
  echo "Automated (full workflow):"
  echo "  → /flow continue"
fi
```

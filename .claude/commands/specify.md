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
  echo "Error: Feature description required"
  echo "Usage: /spec-flow [feature-description]"
  exit 1
fi

# Check if SLUG already provided (from /spec-flow orchestrator)
# If provided, use it; otherwise generate from feature description
if [ -n "$SLUG" ]; then
  echo "✓ Using provided slug: $SLUG"
  echo "  From: $ARGUMENTS"
  echo ""
  SHORT_NAME="$SLUG"
else
  # Standalone mode: Generate concise short-name (2-4 words, action-noun format)
  # Analyze feature description and extract meaningful keywords
  SHORT_NAME=$(echo "$ARGUMENTS" |
    tr '[:upper:]' '[:lower:]' |
    # Remove common filler words and phrases
    sed 's/\bwe want to\b//g; s/\bI want to\b//g; s/\bget our\b//g' |
    sed 's/\bto a\b//g; s/\bwith\b//g; s/\bfor the\b//g' |
    sed 's/\bbefore moving on to\b//g; s/\bother features\b//g' |
    sed 's/\ba\b//g; s/\ban\b//g; s/\bthe\b//g' |
    # Preserve technical terms (OAuth2, API, JWT, etc.) by keeping alphanumeric
    # Extract key action words (add, create, fix, implement, etc.)
    sed 's/\bimplement\b/add/g; s/\bcreate\b/add/g' |
    # Convert to hyphen-separated
    sed 's/[^a-z0-9-]/-/g' |
    sed 's/--*/-/g' |
    sed 's/^-//;s/-$//' |
    # Take first 2-4 meaningful words (approx 20 chars max for short-name)
    cut -c1-20 |
    sed 's/-$//')

  # Validate short-name is not empty after sanitization
  if [ -z "$SHORT_NAME" ]; then
    echo "Error: Invalid feature description (results in empty short-name)"
    echo "Provided: $ARGUMENTS"
    exit 1
  fi

  # Prevent path traversal
  if [[ "$SHORT_NAME" == *".."* ]] || [[ "$SHORT_NAME" == *"/"* ]]; then
    echo "Error: Invalid characters in feature name"
    exit 1
  fi

  # Show generated short-name
  echo "✓ Generated short-name: $SHORT_NAME"
  echo "  From: $ARGUMENTS"
  echo ""

  # Use SHORT_NAME as SLUG for consistency with rest of workflow
  SLUG="$SHORT_NAME"
fi
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

# 2. Get current branch (for conditional logic below)
CURRENT_BRANCH=$(git branch --show-current)

# 3. Check if running in standalone mode (not from /spec-flow orchestrator)
# If FEATURE_NUM is set, we're in orchestrated mode and branch/directory already created
if [ -z "$FEATURE_NUM" ]; then
  # Standalone mode validations
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo "Error: Cannot create spec on main branch"
    echo "Run: git checkout -b feature-branch-name"
    echo "Or: Use /spec-flow command for full workflow"
    exit 1
  fi

  # Check branch doesn't already exist
  if git show-ref --verify --quiet refs/heads/${SLUG}; then
    echo "Error: Branch '${SLUG}' already exists"
    echo "Run: git checkout ${SLUG} (to switch to it)"
    echo "Or: Choose different feature name"
    exit 1
  fi

  # Check spec directory doesn't exist
  if [ -d "specs/${SLUG}" ]; then
    echo "Error: Spec directory 'specs/${SLUG}/' already exists"
    echo "Run: /specify [different-name]"
    exit 1
  fi
else
  # Orchestrated mode: validations already done by /spec-flow
  echo "✓ Running in orchestrated mode (from /spec-flow)"
  echo "  Branch and directory already created"
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
# If FEATURE_NUM is set (orchestrated mode), use numbered directory
if [ -n "$FEATURE_NUM" ]; then
  FEATURE_DIR="specs/${FEATURE_NUM}-${SLUG}"
else
  # Standalone mode: use plain slug
  FEATURE_DIR="specs/${SLUG}"
fi

SPEC_FILE="$FEATURE_DIR/spec.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"

# Create branch and directory (only in standalone mode)
if [ -z "$FEATURE_NUM" ]; then
  # Standalone mode: create branch and directory
  git checkout -b ${SLUG}
  mkdir -p ${FEATURE_DIR}
else
  # Orchestrated mode: directory already created by /spec-flow
  # No directory creation needed
  :
fi

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
# Requires UI-specific keywords to avoid false positives
HAS_UI=false
if [[ "$ARGUMENTS" =~ (screen|page|component|dashboard|form|modal|frontend|interface) ]] &&
   [[ ! "$ARGUMENTS" =~ (API|endpoint|service|backend|database|migration|health.*check|cron|job|worker) ]]; then
  HAS_UI=true
fi

# Change type (determines hypothesis)
# Only true if explicitly about improving/optimizing something
IS_IMPROVEMENT=false
if [[ "$ARGUMENTS" =~ (improve|optimize|enhance|speed.*up|reduce.*time|increase.*performance) ]] &&
   [[ "$ARGUMENTS" =~ (existing|current|slow|faster|better) ]]; then
  IS_IMPROVEMENT=true
fi

# Measurable outcomes (determines HEART metrics)
# Only true if explicitly about user behavior/metrics tracking
HAS_METRICS=false
if [[ "$ARGUMENTS" =~ (track|measure|metric|analytic).*user ]] ||
   [[ "$ARGUMENTS" =~ user.*(engagement|retention|conversion|behavior|journey|adoption) ]] ||
   [[ "$ARGUMENTS" =~ (A/B.*test|experiment|funnel|cohort) ]]; then
  HAS_METRICS=true
fi

# Deployment complexity (determines deployment section)
# Only for actual infrastructure/platform changes
HAS_DEPLOYMENT_IMPACT=false
if [[ "$ARGUMENTS" =~ (migration|alembic|schema.*change|env.*variable|environment.*var) ]] ||
   [[ "$ARGUMENTS" =~ (breaking.*change|platform.*change|infrastructure|docker|deploy.*config) ]]; then
  HAS_DEPLOYMENT_IMPACT=true
fi

# Count flags to determine if classification is clear
FLAG_COUNT=0
[ "$HAS_UI" = true ] && FLAG_COUNT=$((FLAG_COUNT + 1))
[ "$IS_IMPROVEMENT" = true ] && FLAG_COUNT=$((FLAG_COUNT + 1))
[ "$HAS_METRICS" = true ] && FLAG_COUNT=$((FLAG_COUNT + 1))
[ "$HAS_DEPLOYMENT_IMPACT" = true ] && FLAG_COUNT=$((FLAG_COUNT + 1))

# Auto-skip prompt if classification is clear (0-1 flags)
if [ "$FLAG_COUNT" -le 1 ]; then
  # Clear case - auto-proceed without asking
  echo "✓ Auto-classified: Simple feature"
  [ "$HAS_UI" = true ] && echo "  → UI feature detected"
  [ "$IS_IMPROVEMENT" = true ] && echo "  → Improvement feature detected"
  [ "$HAS_METRICS" = true ] && echo "  → Metrics tracking detected"
  [ "$HAS_DEPLOYMENT_IMPACT" = true ] && echo "  → Deployment impact detected"
  [ "$FLAG_COUNT" -eq 0 ] && echo "  → Backend/API feature (no special artifacts)"
  echo ""
else
  # Ambiguous case - ask for confirmation
  echo "Detected classification (multiple signals):"
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
fi

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

## RESEARCH (Scaled: 1-8 tool calls)

**Determine research depth based on feature complexity:**

```bash
# Minimal research for simple backend features (1-2 tools)
if [ "$FLAG_COUNT" -eq 0 ]; then
  RESEARCH_MODE="minimal"
  echo "Research mode: Minimal (backend/API feature)"
# Standard research for single-aspect features (3-5 tools)
elif [ "$FLAG_COUNT" -eq 1 ]; then
  RESEARCH_MODE="standard"
  echo "Research mode: Standard (single-aspect feature)"
# Full research for complex features (5-8 tools)
else
  RESEARCH_MODE="full"
  echo "Research mode: Full (multi-aspect feature)"
fi
echo ""
```

**Minimal research** (1-2 tools):
1. `$CONSTITUTION_FILE` → Check compliance with mission/values
2. `Grep codebase` → If integrating with existing code (infer from $ARGUMENTS keywords)

**Standard research** (3-5 tools):
1-2. Minimal research tools (above)
3. `$UI_INVENTORY_FILE` → List reusable components (if `$HAS_UI = true`)
4. `$BUDGETS_FILE` → Performance targets (if `$HAS_UI = true`)
5. `Glob specs/**/spec.md` → If similar feature exists (search by keyword in $ARGUMENTS)

**Full research** (5-8 tools):
1-5. Standard research tools (above)
6. `$INSPIRATIONS_FILE` → If UX pattern needed (`$HAS_UI = true`)
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

```bash
# Create design directory for UI artifacts
mkdir -p ${FEATURE_DIR}/design
```

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
   - **Success Criteria** (measurable, technology-agnostic, user-focused, verifiable)
   - Mark ambiguities: `[NEEDS CLARIFICATION: question]` (max 3, prioritized by impact)
   - Make informed guesses for non-critical decisions, document assumptions

2. **NOTES.md** (`$NOTES_FILE`):
   - Already created in INITIALIZE
   - Update with overview and final checkpoint timestamp

3. **Visuals** (if applicable and `$HAS_UI = true`):
   ```bash
   # Create visuals directory for UI reference materials
   mkdir -p ${FEATURE_DIR}/visuals
   ```
   - Create `${FEATURE_DIR}/visuals/README.md` from `$VISUALS_TEMPLATE`
   - Document UX patterns from chrome-devtools
   - Extract layout, colors, interactions, measurements
   - Include reference URLs

**Success Criteria Guidelines:**
- Must be **Measurable**: Include specific metrics (time, percentage, count, rate)
- Must be **Technology-agnostic**: No frameworks, languages, databases, or tools
- Must be **User-focused**: Outcomes from user/business perspective, not system internals
- Must be **Verifiable**: Testable without knowing implementation details

**Examples:**
- ✅ Good: "Users can complete checkout in under 3 minutes"
- ✅ Good: "System supports 10,000 concurrent users"
- ✅ Good: "95% of searches return results in under 1 second"
- ❌ Bad: "API response time is under 200ms" (too technical)
- ❌ Bad: "React components render efficiently" (framework-specific)
- ❌ Bad: "Redis cache hit rate above 80%" (technology-specific)

**Informed Guesses Strategy:**
- Make reasonable defaults based on industry standards
- Document assumptions in Assumptions section
- **Only mark [NEEDS CLARIFICATION] for critical decisions** that:
  - Significantly impact feature scope or user experience
  - Have multiple reasonable interpretations with different implications
  - Lack any reasonable default
- **Limit: Maximum 3 [NEEDS CLARIFICATION] markers total**
- **Prioritize clarifications**: scope > security/privacy > user experience > technical details

**Common Reasonable Defaults** (don't ask about these):
- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

## SPECIFICATION QUALITY VALIDATION

**After generating spec, validate quality before proceeding:**

```bash
# Create checklists directory if needed
mkdir -p ${FEATURE_DIR}/checklists

# Create requirements quality checklist
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"

cat > $REQUIREMENTS_CHECKLIST <<'CHECKLIST_EOF'
# Specification Quality Checklist: ${ARGUMENTS}

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: $(date -I)
**Feature**: specs/${SLUG}/spec.md

## Content Quality

- [ ] CHK001 - No implementation details (languages, frameworks, APIs)
- [ ] CHK002 - Focused on user value and business needs
- [ ] CHK003 - Written for non-technical stakeholders
- [ ] CHK004 - All mandatory sections completed

## Requirement Completeness

- [ ] CHK005 - No [NEEDS CLARIFICATION] markers remain (or max 3)
- [ ] CHK006 - Requirements are testable and unambiguous
- [ ] CHK007 - Success criteria are measurable
- [ ] CHK008 - Success criteria are technology-agnostic (no implementation details)
- [ ] CHK009 - All acceptance scenarios are defined
- [ ] CHK010 - Edge cases are identified
- [ ] CHK011 - Scope is clearly bounded
- [ ] CHK012 - Dependencies and assumptions identified

## Feature Readiness

- [ ] CHK013 - All functional requirements have clear acceptance criteria
- [ ] CHK014 - User scenarios cover primary flows
- [ ] CHK015 - Feature meets measurable outcomes defined in Success Criteria
- [ ] CHK016 - No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before `/clarify` or `/plan`
- Maximum 3 [NEEDS CLARIFICATION] markers allowed (prioritize by impact)
CHECKLIST_EOF

echo "✅ Created requirements quality checklist"
```

**Validation Process:**

1. **Run validation check** against spec.md:
   - Review each CHK item
   - Identify failing items (excluding [NEEDS CLARIFICATION] count)

2. **Handle validation failures** (non-clarification issues):
   - List failing items with specific issues
   - Update spec.md to address each issue
   - Re-validate (max 3 iterations)
   - If still failing after 3 iterations: document in checklist notes, warn user

3. **Handle clarification markers**:
   ```bash
   # Count [NEEDS CLARIFICATION] markers
   CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" $SPEC_FILE || echo 0)

   if [ "$CLARIFICATIONS" -gt 3 ]; then
     echo "⚠️  Found $CLARIFICATIONS clarification markers (limit: 3)"
     echo "Keeping 3 most critical (by scope > security > UX > technical)"
     echo "Making informed guesses for remaining items"
     # Claude Code: Reduce to 3 most critical markers
   fi

   if [ "$CLARIFICATIONS" -gt 0 ]; then
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "📋 CLARIFICATION NEEDED ($CLARIFICATIONS items)"
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""

     # Claude Code: Present structured questions with options table
     # Format per question:
     #
     # ## Question [N]: [Topic]
     #
     # **Context**: [Quote relevant spec section]
     #
     # **What we need to know**: [Specific question from NEEDS CLARIFICATION]
     #
     # **Suggested Answers**:
     #
     # | Option | Answer | Implications |
     # |--------|--------|--------------|
     # | A      | [First answer] | [Impact] |
     # | B      | [Second answer] | [Impact] |
     # | C      | [Third answer] | [Impact] |
     # | Custom | Provide your own | [How to provide] |
     #
     # **Your choice**: _[Wait for response]_
     #
     # Wait for user responses (e.g., "Q1: A, Q2: Custom - ..., Q3: B")
     # Update spec with answers
     # Re-validate after all clarifications resolved
   fi
   ```

4. **Update checklist** with final pass/fail status:
   ```bash
   # Mark CHK items as [x] based on validation results
   # Update Notes section with any remaining issues
   ```

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

# Commit specification artifacts
git add specs/${SLUG}/
git commit -m "$COMMIT_MSG"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Specification committed: $COMMIT_HASH"
echo ""
git log -1 --oneline
echo ""
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

# Check requirements checklist status
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"
CHECKLIST_COMPLETE=false

if [ -f "$REQUIREMENTS_CHECKLIST" ]; then
  TOTAL_CHECKS=$(grep -c "^- \[" $REQUIREMENTS_CHECKLIST || echo 0)
  COMPLETE_CHECKS=$(grep -c "^- \[x\]" $REQUIREMENTS_CHECKLIST || echo 0)

  if [ "$TOTAL_CHECKS" -eq "$COMPLETE_CHECKS" ]; then
    CHECKLIST_COMPLETE=true
  fi
fi

# Auto-progression logic based on validation status
if [ "$CLARIFICATIONS" -gt 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  AUTO-PROGRESSION: Clarifications needed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $CLARIFICATIONS ambiguities marked [NEEDS CLARIFICATION]"
  echo ""
  [ "$CHECKLIST_COMPLETE" = false ] && echo "⚠️  Requirements checklist incomplete"
  echo ""
  echo "Recommended: /clarify"
  echo "Alternative: /plan (proceed with current spec, clarify later)"
  echo ""
  echo "To automate: /flow \"${SLUG}\" (runs full workflow)"
elif [ "$CHECKLIST_COMPLETE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  AUTO-PROGRESSION: Quality checks incomplete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Requirements checklist has incomplete items ($COMPLETE_CHECKS/$TOTAL_CHECKS complete)"
  echo ""
  echo "Review: ${REQUIREMENTS_CHECKLIST}"
  echo ""
  echo "Action needed: Address failing checklist items before proceeding"
  echo "After fixes: Re-run spec validation or proceed with /plan"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AUTO-PROGRESSION: Spec is clear and validated"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "No ambiguities found - requirements checklist complete"
  echo "Ready for planning phase"
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

# Show checklist status
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"
if [ -f "$REQUIREMENTS_CHECKLIST" ]; then
  TOTAL_CHECKS=$(grep -c "^- \[" $REQUIREMENTS_CHECKLIST || echo 0)
  COMPLETE_CHECKS=$(grep -c "^- \[x\]" $REQUIREMENTS_CHECKLIST || echo 0)

  if [ "$TOTAL_CHECKS" -eq "$COMPLETE_CHECKS" ]; then
    echo "- Requirements checklist: ✅ Complete ($TOTAL_CHECKS/$TOTAL_CHECKS)"
  else
    echo "- Requirements checklist: ⚠️  Incomplete ($COMPLETE_CHECKS/$TOTAL_CHECKS)"
  fi
fi

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
elif [ "$COMPLETE_CHECKS" -ne "$TOTAL_CHECKS" ] 2>/dev/null; then
  echo "Manual (step-by-step):"
  echo "  → Review and complete requirements checklist"
  echo "  → Then: /plan"
  echo ""
  echo "Automated (full workflow):"
  echo "  → /flow continue (will prompt for checklist completion)"
else
  echo "Manual (step-by-step):"
  echo "  → /plan"
  echo ""
  echo "Automated (full workflow):"
  echo "  → /flow continue"
fi
```

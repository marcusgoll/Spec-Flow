---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

<context>
## MENTAL MODEL

Single-pass, non-interactive pipeline:

`spec-flow → classify → research → artifacts → validate → commit → auto-progress`

- **Deterministic**: slug generation, zero blocking prompts
- **Guardrails**: prevent speculation, cite sources
- **User-value**: success criteria are measurable, tech-agnostic
- **Conditional**: UI/metrics/deployment sections enabled by flags
- **Clarify output**: generate `clarify.md` when ambiguities found (max 3 in spec)

**References**:
- Gherkin for scenarios (Given/When/Then) - Cucumber/Gherkin specification
- HEART metrics (Happiness, Engagement, Adoption, Retention, Task success) - Google Research
- Conventional Commits for commit messages
- Feature flags for risky changes (ship dark, plan removal)
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent making up information when creating specifications.

1. **Never speculate about existing code you have not read**
   - ❌ BAD: "The app probably uses React Router for navigation"
   - ✅ GOOD: "Let me check package.json and src/ to see what's currently used"
   - Use Glob to find files, Read to examine them before making assumptions

2. **Cite sources for technical constraints**
   - When referencing existing architecture, cite files: `package.json:12`, `tsconfig.json:5-8`
   - When referencing similar features, cite: `specs/002-auth-flow/spec.md:45`
   - Don't invent APIs, libraries, or frameworks that might not exist

3. **Admit when research is needed**
   - If uncertain about tech stack, say: "I need to read package.json and check existing code"
   - If unsure about design patterns, say: "Let me search for similar implementations"
   - Never make up database schemas, API endpoints, or component hierarchies

4. **Verify roadmap entries before referencing**
   - Before saying "This builds on feature X", search GitHub Issues for X using `gh issue list`
   - Use exact issue slugs and titles, don't paraphrase
   - If feature not in roadmap, say: "This is a new feature, not extending existing work"

5. **Quote user requirements exactly**
   - When documenting user needs, quote $ARGUMENTS directly
   - Don't add unstated requirements or assumptions
   - Mark clarifications needed with `[NEEDS CLARIFICATION]` explicitly (max 3 in spec, extras go to clarify.md)

**Why this matters**: Hallucinated technical constraints lead to specs that can't be implemented. Specs based on non-existent code create impossible plans. Accurate specifications save 50-60% of implementation time.

## REASONING APPROACH

For complex specification decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this requirement:
1. What is the user actually asking for? [Quote $ARGUMENTS]
2. What are the implied constraints? [Technical, UX, performance]
3. What existing features does this build on? [Check GitHub Issues via gh issue list]
4. What ambiguities need clarification? [List unclear points - max 3 critical, rest go to clarify.md]
5. Conclusion: [Specification approach with justification]
</thinking>

<answer>
[Specification decision based on reasoning]
</answer>

**When to use structured thinking:**
- Classifying feature type (enhancement vs new feature vs bugfix)
- Deciding feature scope (what's in vs out of scope)
- Identifying technical constraints from vague requirements
- Choosing between multiple valid interpretations of user intent
- Determining which roadmap section to place the feature in

**Benefits**: Explicit reasoning reduces scope creep by 30-40% and prevents misaligned specifications.
</constraints>

<instructions>
## PATH CONSTANTS

```bash
ENGINEERING_PRINCIPLES="docs/project/engineering-principles.md"
WORKFLOW_MECHANICS=".spec-flow/memory/workflow-mechanics.md"
INSPIRATIONS_FILE=".spec-flow/memory/design-inspirations.md"
UI_INVENTORY_FILE="design/systems/ui-inventory.md"
BUDGETS_FILE="design/systems/budgets.md"

SPEC_TEMPLATE=".spec-flow/templates/spec-template.md"
HEART_TEMPLATE=".spec-flow/templates/heart-metrics-template.md"
SCREENS_TEMPLATE=".spec-flow/templates/screens-yaml-template.yaml"
VISUALS_TEMPLATE=".spec-flow/templates/visuals-readme-template.md"
ROADMAP_FILE="docs/roadmap.md"

COMPACT_THRESHOLD=50000  # Planning quality degrades above 50k tokens
```

## INPUT VALIDATION

```bash
# Check arguments provided
[ -z "$ARGUMENTS" ] && echo "Error: Feature description required" && echo "Usage: /spec [feature-description]" && exit 1

# Use provided SLUG or generate from ARGUMENTS
if [ -n "$SLUG" ]; then
  SHORT_NAME="$SLUG"
else
  # Generate concise slug (2-4 words, action-noun format)
  SHORT_NAME=$(echo "$ARGUMENTS" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/\b(we|i)\s+want\s+to\b//g; s/\b(get|to|with|for|the|a|an)\b//g' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' \
    | cut -c1-50 \
    | sed 's/-$//')

  [ -z "$SHORT_NAME" ] && echo "Error: Invalid feature name (results in empty slug)" && exit 1

  # Prevent path traversal
  [[ "$SHORT_NAME" == *".."* ]] || [[ "$SHORT_NAME" == *"/"* ]] && echo "Error: Invalid characters in feature name" && exit 1

  SLUG="$SHORT_NAME"
fi

echo "✓ Feature slug: $SLUG"
echo "  From: $ARGUMENTS"
echo ""
```

## GIT PRECONDITIONS

```bash
# 1. Check working directory is clean
[ -n "$(git status --porcelain)" ] && echo "Error: Uncommitted changes in working directory" && git status --short && exit 1

# 2. Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# 3. Validate not on main branch
[ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ] && echo "Error: Cannot create spec on main branch" && echo "Run: git checkout -b feature-branch-name" && exit 1

# 4. Check spec directory doesn't exist
[ -d "specs/${SLUG}" ] && echo "Error: Spec directory 'specs/${SLUG}/' already exists" && exit 1

# 5. Validate templates exist
for t in "$SPEC_TEMPLATE" "$HEART_TEMPLATE" "$SCREENS_TEMPLATE" "$VISUALS_TEMPLATE"; do
  [ ! -f "$t" ] && echo "Error: Missing required template: $t" && exit 1
done
```

## INITIALIZE

```bash
# Set up paths
FEATURE_DIR="specs/${SLUG}"
SPEC_FILE="$FEATURE_DIR/spec.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
CLARIFY_FILE="$FEATURE_DIR/clarify.md"

# Create branch and directory structure
git checkout -b "${SLUG}"
mkdir -p "$FEATURE_DIR" "$FEATURE_DIR/design" "$FEATURE_DIR/visuals" "$FEATURE_DIR/checklists"

# Create NOTES.md stub
cat > "$NOTES_FILE" <<EOF
# Feature: $ARGUMENTS

## Overview
[Filled during spec generation]

## Research Findings
[Filled by research phase]

## System Components Analysis
[UI inventory + reuse analysis]

## Checkpoints
- Phase 0 (Spec): $(date -I)

## Last Updated
$(date -Iseconds)
EOF
```

## CLASSIFICATION (Deterministic, No Prompts)

```bash
# Lowercase for case-insensitive matching
ARG_LOWER=$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]')

# Feature type (determines UI artifacts)
HAS_UI=false
echo "$ARG_LOWER" | grep -Eq "(screen|page|component|dashboard|form|modal|frontend|interface)" && HAS_UI=true

# Change type (determines hypothesis)
IS_IMPROVEMENT=false
echo "$ARG_LOWER" | grep -Eq "(improve|optimi[sz]e|enhance|speed|reduce|increase)" && IS_IMPROVEMENT=true

# Measurable outcomes (determines HEART metrics)
HAS_METRICS=false
echo "$ARG_LOWER" | grep -Eq "(track|measure|metric|analytic|engagement|retention|adoption|funnel|cohort|a/b)" && HAS_METRICS=true

# Deployment complexity (determines deployment section)
HAS_DEPLOYMENT_IMPACT=false
echo "$ARG_LOWER" | grep -Eq "(migration|schema|env|environment|docker|deploy|breaking|infrastructure)" && HAS_DEPLOYMENT_IMPACT=true

# Count flags to determine research depth
FLAG_COUNT=0
$HAS_UI && FLAG_COUNT=$((FLAG_COUNT+1))
$IS_IMPROVEMENT && FLAG_COUNT=$((FLAG_COUNT+1))
$HAS_METRICS && FLAG_COUNT=$((FLAG_COUNT+1))
$HAS_DEPLOYMENT_IMPACT && FLAG_COUNT=$((FLAG_COUNT+1))

# Document classification
cat >> "$NOTES_FILE" <<EOF

## Feature Classification
- UI screens: ${HAS_UI}
- Improvement: ${IS_IMPROVEMENT}
- Measurable: ${HAS_METRICS}
- Deployment impact: ${HAS_DEPLOYMENT_IMPACT}
EOF

echo "✓ Auto-classified: $FLAG_COUNT signals detected"
[ "$HAS_UI" = true ] && echo "  → UI feature"
[ "$IS_IMPROVEMENT" = true ] && echo "  → Improvement feature"
[ "$HAS_METRICS" = true ] && echo "  → Metrics tracking"
[ "$HAS_DEPLOYMENT_IMPACT" = true ] && echo "  → Deployment impact"
[ "$FLAG_COUNT" -eq 0 ] && echo "  → Backend/API feature (no special artifacts)"
echo ""
```

## ROADMAP DETECTION (Optional)

```bash
# Check if feature exists in roadmap
FROM_ROADMAP=false
if [ -f "$ROADMAP_FILE" ] && grep -qi "^### ${SLUG}\b" "$ROADMAP_FILE"; then
  FROM_ROADMAP=true
  echo "✓ Found '${SLUG}' in roadmap - reusing context"
else
  echo "✓ Creating fresh spec (not found in roadmap)"
fi
echo ""
```

## RESEARCH MODE

```bash
# Determine research depth based on feature complexity
if [ "$FLAG_COUNT" -eq 0 ]; then
  RESEARCH_MODE="minimal"
  echo "Research mode: Minimal (backend/API feature)"
elif [ "$FLAG_COUNT" -eq 1 ]; then
  RESEARCH_MODE="standard"
  echo "Research mode: Standard (single-aspect feature)"
else
  RESEARCH_MODE="full"
  echo "Research mode: Full (multi-aspect feature)"
fi
echo ""
```

**Minimal research** (1-2 tools):
1. Read engineering principles (compliance check)
2. Grep codebase (if integrating with existing code)

**Standard research** (3-5 tools):
1-2. Minimal research tools
3. UI inventory (if `$HAS_UI = true`)
4. Performance budgets (if `$HAS_UI = true`)
5. Similar features (search specs/ by keyword)

**Full research** (5-8 tools):
1-5. Standard research tools
6. Design inspirations (if `$HAS_UI = true`)
7. WebSearch for UX patterns (if UI and no internal pattern)
8. Chrome DevTools analysis (if reference URL in $ARGUMENTS)

**Output**: Document findings in `$NOTES_FILE` with citations.

## GENERATE SPEC ARTIFACTS

### 1. Main Spec (`spec.md`)

Always create from `$SPEC_TEMPLATE`:

**Contents**:
- Problem statement (quote user need from $ARGUMENTS)
- Goals and Non-Goals
- User Scenarios (Gherkin Given/When/Then format)
- Functional Requirements (FR-001, FR-002, ...) and Non-Functional (NFR-001, ...)
- Success Criteria (HEART-based when applicable, measurable, tech-agnostic)
- Assumptions
- Dependencies
- Risks & Mitigations (feature flag plan)
- Open Questions (max 3 `[NEEDS CLARIFICATION]`; extras → clarify.md)

**Success Criteria Guidelines**:
- **Measurable**: Include specific metrics (time, percentage, count, rate)
- **Technology-agnostic**: No frameworks, languages, databases, or tools
- **User-focused**: Outcomes from user/business perspective, not system internals
- **Verifiable**: Testable without knowing implementation details

**Examples**:
- ✅ Good: "Users can complete checkout in under 3 minutes"
- ✅ Good: "System supports 10,000 concurrent users"
- ✅ Good: "95% of searches return results in under 1 second"
- ❌ Bad: "API response time is under 200ms" (too technical)
- ❌ Bad: "React components render efficiently" (framework-specific)
- ❌ Bad: "Redis cache hit rate above 80%" (technology-specific)

**Clarification Strategy**:
- Make reasonable defaults based on industry standards
- Document assumptions in Assumptions section
- **Only mark [NEEDS CLARIFICATION] for critical decisions** that:
  - Significantly impact feature scope or user experience
  - Have multiple reasonable interpretations with different implications
  - Lack any reasonable default
- **Limit: Maximum 3 [NEEDS CLARIFICATION] markers in spec.md**
- **Extra clarifications** go to `clarify.md` for async resolution
- **Prioritize clarifications**: scope > security/privacy > user experience > technical details

### 2. HEART Metrics (if `$HAS_METRICS = true`)

Create `${FEATURE_DIR}/design/heart-metrics.md` from `$HEART_TEMPLATE`:

Define 5 HEART dimensions with targets and measurement sources:

1. **Happiness**: Error rates, satisfaction scores
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

### 3. Screens Inventory & Copy (if `$HAS_UI = true`)

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

### 4. Visual Research (if `$HAS_UI = true`)

Create `${FEATURE_DIR}/visuals/README.md` from `$VISUALS_TEMPLATE`:
- Document UX patterns from chrome-devtools
- Extract layout, colors, interactions, measurements
- Include reference URLs

### 5. Hypothesis (if `$IS_IMPROVEMENT = true`)

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

### 6. Deployment Considerations (if `$HAS_DEPLOYMENT_IMPACT = true`)

Document in spec.md (Deployment Considerations section):

**Platform Dependencies**:
- [None / Vercel: edge middleware for X / Railway: new start command]

**Environment Variables**:
- [None / New: NEXT_PUBLIC_FEATURE_FLAG_X, API_KEY_Y / Changed: NEXT_PUBLIC_API_URL]

**Breaking Changes**:
- [No / Yes: API endpoint /v1/users → /v2/users / Yes: Clerk auth flow change]

**Migration Required**:
- [No / Yes: Add user_preferences table / Yes: Backfill existing users]

**Rollback Considerations**:
- Standard: Feature flag off + `git revert <commit-hash>`
- If migration: Must downgrade migration via Alembic downgrade
- Restore working tree: `git restore --staged . && git restore .` (if partial rollback needed)

**Reference**: Git rollback best practices, feature flag lifecycle management

### 7. Clarify File (if > 3 clarifications needed)

Create `${FEATURE_DIR}/clarify.md` if more than 3 `[NEEDS CLARIFICATION]` items found:

```markdown
# Clarifications Needed: ${SLUG}

**Created**: $(date -I)
**Feature**: specs/${SLUG}/spec.md

## Critical Clarifications (in spec.md)

These are blocking and must be resolved before `/plan`:

1. [Question from spec marked [NEEDS CLARIFICATION]]
2. [Question 2]
3. [Question 3]

## Additional Clarifications (async)

These can be resolved during planning or implementation:

4. [Non-critical question 4]
5. [Non-critical question 5]
...

## Resolution Process

Run `/clarify` to interactively resolve critical clarifications (1-3).
Additional clarifications (4+) can be addressed asynchronously or during planning.
```

## SPECIFICATION QUALITY CHECKLIST

```bash
# Create requirements quality checklist
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"

cat > "$REQUIREMENTS_CHECKLIST" <<'CHECKLIST_EOF'
# Specification Quality Checklist

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: $(date -I)
**Feature**: specs/${SLUG}/spec.md

## Content Quality

- [ ] CHK001 - No implementation details (languages, frameworks, APIs)
- [ ] CHK002 - Focused on user value and business needs
- [ ] CHK003 - Written for non-technical stakeholders
- [ ] CHK004 - All mandatory sections completed

## Requirement Completeness

- [ ] CHK005 - No [NEEDS CLARIFICATION] markers remain (or max 3 critical)
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
- Maximum 3 [NEEDS CLARIFICATION] markers allowed in spec.md (extras in clarify.md)
CHECKLIST_EOF

echo "✅ Created requirements quality checklist"
```

**Validation Process**:

1. **Run validation check** against spec.md (Claude Code validates each CHK item)

2. **Handle validation failures**:
   - List failing items with specific issues
   - Update spec.md to address each issue
   - Re-validate (max 3 iterations)
   - If still failing after 3 iterations: document in checklist notes, warn user

3. **Handle clarification markers**:
   ```bash
   # Count [NEEDS CLARIFICATION] markers
   CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" "$SPEC_FILE" || echo 0)

   if [ "$CLARIFICATIONS" -gt 3 ]; then
     echo "⚠️  Found $CLARIFICATIONS clarification markers (limit: 3)"
     echo "Moving extras to clarify.md"
     # Claude Code: Reduce to 3 most critical in spec, move rest to clarify.md
   fi
   ```

4. **Update checklist** with final pass/fail status

## UPDATE ROADMAP (if from roadmap)

```bash
if [ "$FROM_ROADMAP" = true ]; then
  echo "Updating roadmap: ${SLUG} → In Progress"

  # Find feature in roadmap (by slug heading)
  FEATURE_SECTION=$(grep -n "^### ${SLUG}" "$ROADMAP_FILE" | cut -d: -f1)

  if [ -n "$FEATURE_SECTION" ]; then
    # Move feature to "In Progress" section with metadata
    # Add: Branch, Spec, Updated date
    # (Implementation uses sed/awk for robust markdown manipulation)

    git add "$ROADMAP_FILE"
    git commit -m "roadmap: move ${SLUG} to In Progress

Branch: ${SLUG}
Spec: specs/${SLUG}/spec.md
Updated after /spec completed"

    echo "✅ Roadmap updated: ${SLUG} now in In Progress"
  fi
fi
```

## GIT COMMIT (Conventional Commits)

```bash
# Build commit message dynamically based on artifacts created
COMMIT_MSG="design(spec): add ${SLUG} specification

Phase 0: Spec-flow
- User scenarios (Given/When/Then)
- Requirements documented"

# Add conditional lines based on artifacts
[ -f "${FEATURE_DIR}/design/heart-metrics.md" ] && COMMIT_MSG="${COMMIT_MSG}
- HEART metrics defined (5 dimensions with targets)"

[ -f "${FEATURE_DIR}/design/screens.yaml" ] && COMMIT_MSG="${COMMIT_MSG}
- UI screens inventory ($(grep -c '^  [a-z_]*:' ${FEATURE_DIR}/design/screens.yaml 2>/dev/null || echo 0) screens)"

[ -f "${FEATURE_DIR}/design/copy.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Copy documented (real text, no Lorem Ipsum)"

[ "$IS_IMPROVEMENT" = true ] && COMMIT_MSG="${COMMIT_MSG}
- Hypothesis (Problem → Solution → Prediction)"

[ -f "${FEATURE_DIR}/visuals/README.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Visual research documented"

[ -f "${FEATURE_DIR}/clarify.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Clarifications file created (async resolution)"

# Count system components if analyzed
if grep -q "System Components Analysis" "$NOTES_FILE"; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" "$NOTES_FILE" | grep -c "^-" || echo 0)
  COMMIT_MSG="${COMMIT_MSG}
- System components checked (${REUSABLE_COUNT} reusable)"
fi

# List artifacts
COMMIT_MSG="${COMMIT_MSG}

Artifacts:"

for artifact in spec.md NOTES.md design/*.md design/*.yaml visuals/README.md clarify.md; do
  [ -f "${FEATURE_DIR}/${artifact}" ] && COMMIT_MSG="${COMMIT_MSG}
- specs/${SLUG}/${artifact}"
done

# Count clarifications
CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" "$SPEC_FILE" || echo 0)

if [ "$CLARIFICATIONS" -gt 0 ] || [ -f "${FEATURE_DIR}/clarify.md" ]; then
  COMMIT_MSG="${COMMIT_MSG}

Next: /clarify (${CLARIFICATIONS} critical ambiguities in spec)"
else
  COMMIT_MSG="${COMMIT_MSG}

Next: /plan"
fi

COMMIT_MSG="${COMMIT_MSG}

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit specification artifacts
git add "specs/${SLUG}/"
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

```bash
# Rollback function
rollback_spec_flow() {
  echo "⚠️  Spec generation failed. Rolling back changes..."

  # 1. Return to original branch
  ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD@{-1} 2>/dev/null || echo "main")
  git checkout "$ORIGINAL_BRANCH"

  # 2. Delete feature branch
  git branch -D "${SLUG}" 2>/dev/null

  # 3. Remove spec directory
  rm -rf "specs/${SLUG}"

  # 4. Revert roadmap changes (if from roadmap)
  if [ "$FROM_ROADMAP" = true ]; then
    git checkout HEAD -- "$ROADMAP_FILE"
  fi

  echo "✓ Rolled back all changes"
  echo "Error: $1"
  exit 1
}

# Usage: trap rollback_spec_flow on errors
# Example: [ -f "$SPEC_TEMPLATE" ] || rollback_spec_flow "Missing template"
```

## AUTO-PROGRESSION

```bash
# Count clarification markers
CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" "$SPEC_FILE" || echo 0)

# Check requirements checklist status
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"
CHECKLIST_COMPLETE=false

if [ -f "$REQUIREMENTS_CHECKLIST" ]; then
  TOTAL_CHECKS=$(grep -c "^- \[" "$REQUIREMENTS_CHECKLIST" || echo 0)
  COMPLETE_CHECKS=$(grep -c "^- \[x\]" "$REQUIREMENTS_CHECKLIST" || echo 0)

  if [ "$TOTAL_CHECKS" -eq "$COMPLETE_CHECKS" ]; then
    CHECKLIST_COMPLETE=true
  fi
fi

# Auto-progression logic
if [ "$CLARIFICATIONS" -gt 0 ] || [ -f "${FEATURE_DIR}/clarify.md" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  AUTO-PROGRESSION: Clarifications needed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $CLARIFICATIONS critical ambiguities in spec.md"
  [ -f "${FEATURE_DIR}/clarify.md" ] && echo "Additional clarifications in clarify.md (async)"
  echo ""
  echo "Recommended: /clarify"
  echo "Alternative: /plan (proceed with current spec, clarify later)"
elif [ "$CHECKLIST_COMPLETE" = false ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  AUTO-PROGRESSION: Quality checks incomplete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Requirements checklist: $COMPLETE_CHECKS/$TOTAL_CHECKS complete"
  echo ""
  echo "Review: ${REQUIREMENTS_CHECKLIST}"
  echo "After fixes: /plan"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AUTO-PROGRESSION: Spec is clear and validated"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "No ambiguities - requirements checklist complete"
  echo ""
  echo "Recommended: /plan"
  echo "Alternative: /feature continue (automates plan → tasks → implement → ship)"
fi
```

## RETURN

```bash
# Count artifacts
ARTIFACT_COUNT=$(find "${FEATURE_DIR}" -type f 2>/dev/null | wc -l || echo 0)
REQUIREMENT_COUNT=$(grep -c "^- \[FR-\|^- \[NFR-" "$SPEC_FILE" || echo 0)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SPECIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: ${SLUG}"
echo "Spec: specs/${SLUG}/spec.md"
echo "Branch: ${SLUG}"
[ "$FROM_ROADMAP" = true ] && echo "Roadmap: Updated to In Progress ✅"
echo ""
echo "Details:"
echo "- Requirements: ${REQUIREMENT_COUNT} documented"

[ "$HAS_METRICS" = true ] && echo "- HEART metrics: 5 dimensions with targets"
[ "$IS_IMPROVEMENT" = true ] && echo "- Hypothesis: Problem → Solution → Prediction"
[ "$HAS_UI" = true ] && echo "- UI screens: $(grep -c '^  [a-z_]*:' ${FEATURE_DIR}/design/screens.yaml 2>/dev/null || echo 0) defined"

if grep -q "System Components Analysis" "$NOTES_FILE"; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" "$NOTES_FILE" | grep -c "^-" || echo 0)
  NEW_COUNT=$(grep -A 10 "New Components" "$NOTES_FILE" | grep -c "^-" || echo 0)
  echo "- System components: ${REUSABLE_COUNT} reusable, ${NEW_COUNT} new"
fi

[ -f "${FEATURE_DIR}/visuals/README.md" ] && echo "- Visual research: documented"
[ -f "${FEATURE_DIR}/clarify.md" ] && echo "- Clarify file: created (async)"

echo "- Clarifications in spec: ${CLARIFICATIONS}"
echo "- Artifacts: ${ARTIFACT_COUNT}"

# Show checklist status
if [ -f "$REQUIREMENTS_CHECKLIST" ]; then
  if [ "$CHECKLIST_COMPLETE" = true ]; then
    echo "- Checklist: ✅ Complete ($TOTAL_CHECKS/$TOTAL_CHECKS)"
  else
    echo "- Checklist: ⚠️  Incomplete ($COMPLETE_CHECKS/$TOTAL_CHECKS)"
  fi
fi

echo ""
```

</instructions>

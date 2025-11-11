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
</constraints>

<instructions>
## BASH SCRIPT

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap to ensure proper cleanup on failure
on_error() {
  echo "⚠️  Error in /spec. Rolling back changes."

  # Rollback: return to original branch and clean up
  ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD@{-1} 2>/dev/null || echo "main")
  git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
  git branch -D "${SLUG}" 2>/dev/null || true
  rm -rf "specs/${SLUG}" 2>/dev/null || true

  exit 1
}
trap on_error ERR

# Tool preflight checks
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    case "$1" in
      git) echo "   Install: https://git-scm.com/downloads" ;;
      gh) echo "   Install: https://cli.github.com/" ;;
      jq) echo "   Install: brew install jq (macOS) or apt install jq (Linux)" ;;
      *) echo "   Check documentation for installation" ;;
    esac
    exit 1
  }
}

need git
need jq

# Deterministic repo root
cd "$(git rev-parse --show-toplevel)"

# Constants
ENGINEERING_PRINCIPLES="docs/project/engineering-principles.md"
WORKFLOW_MECHANICS=".spec-flow/memory/workflow-mechanics.md"
SPEC_TEMPLATE=".spec-flow/templates/spec-template.md"
HEART_TEMPLATE=".spec-flow/templates/heart-metrics-template.md"
SCREENS_TEMPLATE=".spec-flow/templates/screens-yaml-template.yaml"
VISUALS_TEMPLATE=".spec-flow/templates/visuals-readme-template.md"
ROADMAP_FILE="docs/roadmap.md"

# Validate arguments
if [ -z "$ARGUMENTS" ]; then
  echo "❌ Feature description required"
  echo ""
  echo "Usage: /spec <feature-description>"
  echo ""
  echo "Examples:"
  echo "  /spec \"Add dark mode toggle to settings\""
  echo "  /spec \"Improve upload speed by 50%\""
  echo "  /spec \"Track user engagement with HEART metrics\""
  exit 1
fi

# Generate slug (deterministic, 2-4 words, action-noun format)
if [ -n "$SLUG" ]; then
  SHORT_NAME="$SLUG"
else
  SHORT_NAME=$(echo "$ARGUMENTS" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/\b(we|i)\s+want\s+to\b//g; s/\b(get|to|with|for|the|a|an)\b//g' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' \
    | cut -c1-50 \
    | sed 's/-$//')

  if [ -z "$SHORT_NAME" ]; then
    echo "❌ Invalid feature name (results in empty slug)"
    echo "   Provide a more descriptive feature name"
    exit 1
  fi

  # Prevent path traversal
  if [[ "$SHORT_NAME" == *".."* ]] || [[ "$SHORT_NAME" == *"/"* ]]; then
    echo "❌ Invalid characters in feature name"
    echo "   Avoid: .. / (path traversal characters)"
    exit 1
  fi

  SLUG="$SHORT_NAME"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Spec Flow: $SLUG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $ARGUMENTS"
echo "Slug: $SLUG"
echo ""

# Git preconditions
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Uncommitted changes in working directory"
  echo ""
  git status --short
  echo ""
  echo "Fix: git add . && git commit -m 'message'"
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  echo "❌ Cannot create spec on main branch"
  echo ""
  echo "Fix: git checkout -b feature-branch-name"
  exit 1
fi

if [ -d "specs/${SLUG}" ]; then
  echo "❌ Spec directory 'specs/${SLUG}/' already exists"
  echo ""
  echo "Options:"
  echo "  1. Use different feature name"
  echo "  2. Delete existing: rm -rf specs/${SLUG}"
  echo "  3. Continue existing feature: cd specs/${SLUG}"
  exit 1
fi

# Validate templates exist
for template in "$SPEC_TEMPLATE" "$HEART_TEMPLATE" "$SCREENS_TEMPLATE" "$VISUALS_TEMPLATE"; do
  if [ ! -f "$template" ]; then
    echo "❌ Missing required template: $template"
    echo ""
    echo "Fix: Ensure .spec-flow/templates/ directory is complete"
    echo "     Clone from: https://github.com/anthropics/spec-flow"
    exit 1
  fi
done

# Initialize feature directory
FEATURE_DIR="specs/${SLUG}"
SPEC_FILE="$FEATURE_DIR/spec.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
CLARIFY_FILE="$FEATURE_DIR/clarify.md"

git checkout -b "${SLUG}"
mkdir -p "$FEATURE_DIR" "$FEATURE_DIR/design" "$FEATURE_DIR/visuals" "$FEATURE_DIR/checklists"

echo "✅ Branch created: $SLUG"
echo "✅ Directory created: specs/$SLUG/"
echo ""

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
- Phase 0 (Spec): $(date -I 2>/dev/null || date +%Y-%m-%d)

## Last Updated
$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
EOF

# Auto-classification (deterministic, keyword-based)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Feature Classification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ARG_LOWER=$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]')

HAS_UI=false
echo "$ARG_LOWER" | grep -Eq "(screen|page|component|dashboard|form|modal|frontend|interface)" && HAS_UI=true

IS_IMPROVEMENT=false
echo "$ARG_LOWER" | grep -Eq "(improve|optimi[sz]e|enhance|speed|reduce|increase)" && IS_IMPROVEMENT=true

HAS_METRICS=false
echo "$ARG_LOWER" | grep -Eq "(track|measure|metric|analytic|engagement|retention|adoption|funnel|cohort|a/b)" && HAS_METRICS=true

HAS_DEPLOYMENT_IMPACT=false
echo "$ARG_LOWER" | grep -Eq "(migration|schema|env|environment|docker|deploy|breaking|infrastructure)" && HAS_DEPLOYMENT_IMPACT=true

# Count classification flags
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
- Complexity signals: ${FLAG_COUNT}
EOF

echo "Classification results:"
[ "$HAS_UI" = true ] && echo "  ✓ UI feature detected"
[ "$IS_IMPROVEMENT" = true ] && echo "  ✓ Improvement feature detected"
[ "$HAS_METRICS" = true ] && echo "  ✓ Metrics tracking detected"
[ "$HAS_DEPLOYMENT_IMPACT" = true ] && echo "  ✓ Deployment impact detected"
[ "$FLAG_COUNT" -eq 0 ] && echo "  → Backend/API feature (no special signals)"
echo ""

# Research mode selection
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

# Roadmap detection
FROM_ROADMAP=false
if [ -f "$ROADMAP_FILE" ] && grep -qi "^### ${SLUG}\b" "$ROADMAP_FILE"; then
  FROM_ROADMAP=true
  echo "✅ Found in roadmap - reusing context"
else
  echo "✅ Creating fresh spec (not in roadmap)"
fi
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RESEARCH PHASE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Research Phase ($RESEARCH_MODE mode)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Research steps determined by mode:
# - minimal: engineering principles + codebase grep (if needed)
# - standard: minimal + UI inventory + budgets + similar features
# - full: standard + design inspirations + WebSearch + DevTools

# Claude Code: Execute research based on RESEARCH_MODE
# Document findings in $NOTES_FILE with file citations
# Use Glob/Read/Grep/WebFetch as needed

echo "✅ Research complete"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ARTIFACT GENERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating Specification Artifacts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Main spec.md (always generated from SPEC_TEMPLATE)
echo "Creating spec.md..."
# Claude Code: Generate from SPEC_TEMPLATE with:
# - Problem statement (quote $ARGUMENTS)
# - Goals/Non-Goals
# - User scenarios (Gherkin Given/When/Then)
# - Functional Requirements (FR-001, FR-002, ...)
# - Non-Functional Requirements (NFR-001, ...)
# - Success Criteria (HEART-based when applicable, measurable, tech-agnostic)
# - Assumptions
# - Dependencies
# - Risks & Mitigations
# - Open Questions (max 3 [NEEDS CLARIFICATION]; extras → clarify.md)
echo "  ✓ spec.md created"

# 2. HEART metrics (if $HAS_METRICS = true)
if [ "$HAS_METRICS" = true ]; then
  echo "Creating HEART metrics..."
  # Claude Code: Generate from HEART_TEMPLATE with 5 dimensions:
  # 1. Happiness (error rates, satisfaction)
  # 2. Engagement (usage frequency)
  # 3. Adoption (new user activation)
  # 4. Retention (repeat usage)
  # 5. Task Success (completion rate)
  # Include targets and measurement sources (SQL, logs, Lighthouse)
  echo "  ✓ design/heart-metrics.md created"
fi

# 3. UI artifacts (if $HAS_UI = true)
if [ "$HAS_UI" = true ]; then
  echo "Creating UI artifacts..."
  # Claude Code: Generate from SCREENS_TEMPLATE
  # - screens.yaml: list screens with states, actions, components
  # - copy.md: real UI text (no Lorem Ipsum)
  echo "  ✓ design/screens.yaml created"
  echo "  ✓ design/copy.md created"

  # Visual research (if references provided in $ARGUMENTS)
  # Claude Code: Generate from VISUALS_TEMPLATE if URLs detected
  if echo "$ARGUMENTS" | grep -Eq "https?://"; then
    echo "  ✓ visuals/README.md created"
  fi
fi

# 4. Hypothesis (if $IS_IMPROVEMENT = true)
if [ "$IS_IMPROVEMENT" = true ]; then
  echo "Adding hypothesis section to spec.md..."
  # Claude Code: Add to spec.md:
  # - Problem (with evidence)
  # - Solution (mechanism)
  # - Prediction (measurable outcome)
  echo "  ✓ Hypothesis documented in spec.md"
fi

# 5. Deployment section (if $HAS_DEPLOYMENT_IMPACT = true)
if [ "$HAS_DEPLOYMENT_IMPACT" = true ]; then
  echo "Adding deployment considerations to spec.md..."
  # Claude Code: Add to spec.md:
  # - Platform dependencies
  # - Environment variables
  # - Breaking changes
  # - Migration requirements
  # - Rollback plan
  echo "  ✓ Deployment section added to spec.md"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Quality Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create requirements checklist
REQUIREMENTS_CHECKLIST="${FEATURE_DIR}/checklists/requirements.md"

cat > "$REQUIREMENTS_CHECKLIST" <<'CHECKLIST_EOF'
# Specification Quality Checklist

**Created**: $(date -I 2>/dev/null || date +%Y-%m-%d)
**Feature**: ${SLUG}

## Content Quality

- [ ] CHK001 - No implementation details (languages, frameworks, APIs)
- [ ] CHK002 - Focused on user value and business needs
- [ ] CHK003 - Written for non-technical stakeholders
- [ ] CHK004 - All mandatory sections completed

## Requirement Completeness

- [ ] CHK005 - No more than 3 [NEEDS CLARIFICATION] markers in spec.md
- [ ] CHK006 - Requirements are testable and unambiguous
- [ ] CHK007 - Success criteria are measurable
- [ ] CHK008 - Success criteria are technology-agnostic
- [ ] CHK009 - All acceptance scenarios defined
- [ ] CHK010 - Edge cases identified
- [ ] CHK011 - Scope clearly bounded
- [ ] CHK012 - Dependencies and assumptions identified

## Feature Readiness

- [ ] CHK013 - All functional requirements have clear acceptance criteria
- [ ] CHK014 - User scenarios cover primary flows
- [ ] CHK015 - Feature meets measurable outcomes defined in Success Criteria
- [ ] CHK016 - No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before /clarify or /plan
- Maximum 3 [NEEDS CLARIFICATION] markers allowed in spec.md (extras in clarify.md)
CHECKLIST_EOF

echo "✅ Created requirements checklist"

# Validate spec against checklist
# Claude Code: Validate each CHK item, update checklist with [x] or [ ]
# If failures after 3 iterations, document in notes and warn user

# Count clarification markers
CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" "$SPEC_FILE" 2>/dev/null || echo 0)

if [ "$CLARIFICATIONS" -gt 3 ]; then
  echo "⚠️  Found $CLARIFICATIONS clarification markers (limit: 3)"
  echo "   Moving extras to clarify.md"
  # Claude Code: Keep 3 most critical in spec.md, move rest to clarify.md
fi

# Check checklist completion
TOTAL_CHECKS=$(grep -c "^- \[" "$REQUIREMENTS_CHECKLIST" || echo 0)
COMPLETE_CHECKS=$(grep -c "^- \[x\]" "$REQUIREMENTS_CHECKLIST" || echo 0)

echo "Checklist status: $COMPLETE_CHECKS/$TOTAL_CHECKS complete"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMIT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Committing Specification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build commit message dynamically
COMMIT_MSG="design(spec): add ${SLUG} specification

Phase 0: Spec-flow
- User scenarios (Given/When/Then)
- Requirements documented"

[ -f "${FEATURE_DIR}/design/heart-metrics.md" ] && COMMIT_MSG="${COMMIT_MSG}
- HEART metrics defined (5 dimensions with targets)"

if [ -f "${FEATURE_DIR}/design/screens.yaml" ]; then
  SCREEN_COUNT=$(grep -c '^  [a-z_]*:' "${FEATURE_DIR}/design/screens.yaml" 2>/dev/null || echo 0)
  COMMIT_MSG="${COMMIT_MSG}
- UI screens inventory (${SCREEN_COUNT} screens)"
fi

[ -f "${FEATURE_DIR}/design/copy.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Copy documented (real text, no Lorem Ipsum)"

[ "$IS_IMPROVEMENT" = true ] && COMMIT_MSG="${COMMIT_MSG}
- Hypothesis (Problem → Solution → Prediction)"

[ -f "${FEATURE_DIR}/visuals/README.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Visual research documented"

[ -f "${FEATURE_DIR}/clarify.md" ] && COMMIT_MSG="${COMMIT_MSG}
- Clarifications file created (async resolution)"

# Count reusable components
if grep -q "System Components Analysis" "$NOTES_FILE"; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" "$NOTES_FILE" | grep -c "^-" 2>/dev/null || echo 0)
  [ "$REUSABLE_COUNT" -gt 0 ] && COMMIT_MSG="${COMMIT_MSG}
- System components checked (${REUSABLE_COUNT} reusable)"
fi

# List artifacts
COMMIT_MSG="${COMMIT_MSG}

Artifacts:"

for artifact in spec.md NOTES.md design/*.md design/*.yaml visuals/README.md clarify.md checklists/requirements.md; do
  [ -e "${FEATURE_DIR}/${artifact}" ] && COMMIT_MSG="${COMMIT_MSG}
- specs/${SLUG}/${artifact}"
done

# Add next step
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

# Commit all artifacts
git add "specs/${SLUG}/"
git commit -m "$COMMIT_MSG"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Committed: $COMMIT_HASH"
echo ""

# Update roadmap if feature came from there
if [ "$FROM_ROADMAP" = true ]; then
  # Claude Code: Update roadmap status to "In Progress"
  # Add branch and spec metadata
  git add "$ROADMAP_FILE"
  git commit -m "roadmap: move ${SLUG} to In Progress"
  echo "✅ Roadmap updated"
  echo ""
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AUTO-PROGRESSION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CHECKLIST_COMPLETE=false
[ "$TOTAL_CHECKS" -eq "$COMPLETE_CHECKS" ] && CHECKLIST_COMPLETE=true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CLARIFICATIONS" -gt 0 ] || [ -f "${FEATURE_DIR}/clarify.md" ]; then
  echo "⚠️  Clarifications Needed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Found $CLARIFICATIONS critical ambiguities in spec.md"
  [ -f "${FEATURE_DIR}/clarify.md" ] && echo "Additional clarifications in clarify.md (async)"
  echo ""
  echo "Recommended: /clarify"
  echo "Alternative: /plan (proceed with current spec)"
elif [ "$CHECKLIST_COMPLETE" = false ]; then
  echo "⚠️  Quality Checks Incomplete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Requirements checklist: $COMPLETE_CHECKS/$TOTAL_CHECKS complete"
  echo ""
  echo "Review: ${REQUIREMENTS_CHECKLIST}"
  echo "After fixes: /plan"
else
  echo "✅ Spec Ready for Planning"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "No ambiguities - requirements checklist complete"
  echo ""
  echo "Recommended: /plan"
  echo "Alternative: /feature continue (automates plan → tasks → implement → ship)"
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SUMMARY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ARTIFACT_COUNT=$(find "${FEATURE_DIR}" -type f 2>/dev/null | wc -l || echo 0)
REQUIREMENT_COUNT=$(grep -c "^- \[FR-\|^- \[NFR-" "$SPEC_FILE" 2>/dev/null || echo 0)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Specification Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: ${SLUG}"
echo "Spec: specs/${SLUG}/spec.md"
echo "Branch: ${SLUG}"
[ "$FROM_ROADMAP" = true ] && echo "Roadmap: In Progress ✅"
echo ""
echo "Details:"
echo "- Requirements: ${REQUIREMENT_COUNT} documented"

[ "$HAS_METRICS" = true ] && echo "- HEART metrics: 5 dimensions with targets"
[ "$IS_IMPROVEMENT" = true ] && echo "- Hypothesis: Problem → Solution → Prediction"

if [ "$HAS_UI" = true ]; then
  SCREEN_COUNT=$(grep -c '^  [a-z_]*:' "${FEATURE_DIR}/design/screens.yaml" 2>/dev/null || echo 0)
  echo "- UI screens: ${SCREEN_COUNT} defined"
fi

if grep -q "System Components Analysis" "$NOTES_FILE"; then
  REUSABLE_COUNT=$(grep -A 10 "Reusable" "$NOTES_FILE" | grep -c "^-" 2>/dev/null || echo 0)
  NEW_COUNT=$(grep -A 10 "New Components" "$NOTES_FILE" | grep -c "^-" 2>/dev/null || echo 0)
  echo "- System components: ${REUSABLE_COUNT} reusable, ${NEW_COUNT} new"
fi

[ -f "${FEATURE_DIR}/visuals/README.md" ] && echo "- Visual research: documented"
[ -f "${FEATURE_DIR}/clarify.md" ] && echo "- Clarify file: created"
echo "- Clarifications in spec: ${CLARIFICATIONS}"
echo "- Artifacts: ${ARTIFACT_COUNT}"

if [ "$CHECKLIST_COMPLETE" = true ]; then
  echo "- Checklist: ✅ Complete ($TOTAL_CHECKS/$TOTAL_CHECKS)"
else
  echo "- Checklist: ⚠️  Incomplete ($COMPLETE_CHECKS/$TOTAL_CHECKS)"
fi

echo ""
```

</instructions>

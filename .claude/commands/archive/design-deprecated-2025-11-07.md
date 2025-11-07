# ⚠️ DEPRECATED (2025-11-07)

**This command has been replaced by the comprehensive style guide approach.**

## Why Deprecated

The 3-phase design workflow (variations → functional → polish) has been replaced with a style-guided rapid prototyping approach that's:
- **85-95% faster** (2-4 hours → <30 min per feature)
- **82-88% fewer tokens** (85K → 10-15K per screen)
- **More consistent** (single SST vs manual variant critique)
- **Automated validation** (design lint vs human gates)

## Migration Path

**Old workflow:**
```bash
/design "Feature Name"  # 3-phase workflow
```

**New workflow:**
```bash
/quick "Add [UI feature]"  # Reads docs/project/style-guide.md
```

The new approach uses:
- `docs/project/style-guide.md` - Comprehensive UI/UX design system with core 9 rules
- Automated validation (no manual critique gates)
- Direct implementation (no variant generation)

**See:** `docs/STYLE_GUIDE_MIGRATION.md` for detailed migration guide

---

# /design - Unified Design Orchestrator (ARCHIVED)

**Purpose**: Orchestrate the complete three-phase design workflow (Variations → Functional → Polish) with automated validation and human approval gates.

**Usage**:
- `/design "Feature Name"` - Start new design workflow
- `/design continue` - Resume from last human gate
- `/design status` - Show current phase and progress

**Philosophy**: "Don't make me think" - Intuitive, systematic UI/UX without Figma.

---

## Workflow Overview

```
Phase 1: Variations (Diverge)
  ├─ Generate 3-5 grayscale wireframes per screen
  ├─ Run design lint validation
  ├─ Present variants to user
  └─ [HUMAN GATE] User selects preferred variant
       ↓
Phase 2: Functional (Converge)
  ├─ Merge selected variants → functional prototype
  ├─ Add interactivity (hover, focus, transitions)
  ├─ Add accessibility (ARIA, keyboard nav)
  ├─ Run hierarchy validation (2:1 ratios, F-pattern)
  ├─ Run "Don't Make Me Think" checklist
  └─ [HUMAN GATE] User approves functional prototype
       ↓
Phase 3: Polish (Systemize)
  ├─ Run token compliance scanning (100% required)
  ├─ Apply brand tokens (colors, typography, spacing)
  ├─ Add subtle gradients and elevation
  ├─ Run final design lint (must pass)
  ├─ Generate implementation-spec.md
  └─ [HUMAN GATE] User approves final design → handoff
```

---

## Command Detection

**Determine command intent**:

1. **New workflow**: If user provides feature name → start Phase 1
2. **Resume workflow**: If user says "continue" → load state, resume from last gate
3. **Status check**: If user says "status" → show current phase and progress

---

## State Management

**State File**: `design/[feature-slug]/design-state.yaml`

```yaml
workflow:
  feature: "User Authentication"
  slug: "user-authentication"
  status: "in_progress" # pending, in_progress, completed, blocked
  current_phase: "functional" # variations, functional, polish
  created_at: "2025-10-21T10:00:00Z"
  updated_at: "2025-10-21T11:30:00Z"

phases:
  variations:
    status: "completed"
    variants_generated: 5
    selected_variant: 3
    lint_status: "passed"
    completed_at: "2025-10-21T10:45:00Z"

  functional:
    status: "in_progress"
    hierarchy_validated: true
    accessibility_checked: true
    usability_score: 0 # 0-100, filled after checklist

  polish:
    status: "pending"
    token_compliance: 0 # 0-100
    design_lint_passed: false
    implementation_spec_generated: false

human_gates:
  variant_selection:
    status: "approved"
    timestamp: "2025-10-21T10:45:00Z"
    selected: 3

  functional_approval:
    status: "pending"
    timestamp: null

  polish_approval:
    status: "pending"
    timestamp: null

artifacts:
  variants_dir: "mock/*/variants/"
  functional_dir: "mock/*/functional/"
  polished_dir: "mock/*/polished/"
  implementation_spec: "design/[feature-slug]/implementation-spec.md"
  lint_reports: "design/lint-report.md"
  hierarchy_analysis: "design/hierarchy-analysis.md"
  usability_checklist: "design/dont-make-me-think-checklist.md"
```

**State Functions**:

```bash
# Read current phase
CURRENT_PHASE=$(yq '.workflow.current_phase' design/$FEATURE_SLUG/design-state.yaml)

# Update phase status
yq -i '.phases.variations.status = "completed"' design/$FEATURE_SLUG/design-state.yaml

# Record human gate approval
yq -i '.human_gates.functional_approval.status = "approved"' design/$FEATURE_SLUG/design-state.yaml
yq -i '.human_gates.functional_approval.timestamp = "'$(date -Iseconds)'"' design/$FEATURE_SLUG/design-state.yaml
```

---

## Phase 0: Setup & Prerequisites

**Before starting design workflow, verify**:

1. **Brand Tokens Exist**:
   ```bash
   if [ ! -f "design/design-system/tokens.json" ]; then
     echo "⚠️  Brand tokens not found."
     echo "Run: /init-brand-tokens"
     exit 1
   fi
   ```

2. **Design Inspiration Gathered** (Optional but recommended):
   ```bash
   if [ ! -f "design/inspirations.md" ]; then
     echo "💡 No design inspiration found."
     echo "Recommended: /research-design \"$FEATURE_NAME\""
     echo "Continue anyway? (y/n)"
   fi
   ```

3. **Design Principles Exist**:
   ```bash
   if [ ! -f ".spec-flow/memory/design-principles.md" ]; then
     echo "⚠️  Design principles missing."
     echo "Run: git pull (principles should be in repo)"
     exit 1
   fi
   ```

4. **Create Design Directory**:
   ```bash
   FEATURE_SLUG=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
   mkdir -p design/$FEATURE_SLUG/{variants,functional,polished}
   mkdir -p mock
   ```

5. **Initialize State File**:
   ```bash
   cat > design/$FEATURE_SLUG/design-state.yaml <<EOF
   workflow:
     feature: "$FEATURE_NAME"
     slug: "$FEATURE_SLUG"
     status: "in_progress"
     current_phase: "variations"
     created_at: "$(date -Iseconds)"
   phases:
     variations:
       status: "pending"
     functional:
       status: "pending"
     polish:
       status: "pending"
   human_gates:
     variant_selection:
       status: "pending"
     functional_approval:
       status: "pending"
     polish_approval:
       status: "pending"
   EOF
   ```

---

## Phase 1: Variations (Diverge)

**Goal**: Generate 3-5 distinct grayscale wireframe variants per screen.

**Agent**: `design-variations-agent` (or inline implementation)

### Step 1.1: Identify Screens

**From spec.md or plan.md**:

```bash
# Extract screen list from spec
SCREENS=$(grep -E "^### Screen:" specs/$FEATURE_ID/spec.md | sed 's/### Screen: //')

# Or interactive prompt
echo "How many screens for $FEATURE_NAME?"
read SCREEN_COUNT
```

### Step 1.2: Generate Variants Per Screen

**For each screen, generate 3-5 variants**:

Use **frontend-shipper** agent or inline:

```markdown
**Task**: Generate 5 grayscale wireframe variants for [Screen Name]

**Constraints**:
- Grayscale only (no colors, use gray-50 to gray-900)
- Focus on layout, hierarchy, spacing
- Test different patterns:
  - Variant 1: Tight layout, compact spacing
  - Variant 2: Airy layout, generous spacing
  - Variant 3: Card-based layout
  - Variant 4: List-based layout
  - Variant 5: Split-screen layout
- Use components from ui-inventory.md
- Follow reading hierarchy (F-pattern, 2:1 heading ratios)
- Add placeholder content (Lorem Ipsum acceptable here)

**Output**: `mock/[screen-id]/variants/variant-{1-5}.tsx`
```

### Step 1.3: Run Design Lint

```bash
node .spec-flow/scripts/design-lint.js mock/*/variants/

# Check results
CRITICAL_COUNT=$(grep -c "🔴 CRITICAL" design/lint-report.md || echo 0)
ERROR_COUNT=$(grep -c "🔴 ERROR" design/lint-report.md || echo 0)

if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$ERROR_COUNT" -gt 0 ]; then
  echo "❌ Design lint failed. Fix issues before proceeding."
  exit 1
fi
```

### Step 1.4: Auto-Open Sandbox

```bash
# Start dev server if not running
if ! lsof -i :3000 > /dev/null; then
  npm run dev &
  sleep 5
fi

# Auto-open variant index
VARIANT_INDEX="http://localhost:3000/mock/variant-index"
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$VARIANT_INDEX"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  start "$VARIANT_INDEX"
else
  xdg-open "$VARIANT_INDEX"
fi
```

### Step 1.5: Human Gate - Variant Selection

**Prompt user**:

```
📊 Variant Review

Generated 5 variants per screen. View them at:
http://localhost:3000/mock/variant-index

Evaluate each variant against:
✓ Reading hierarchy (F-pattern, top-left prominence)
✓ Scannability (short paragraphs, clear headings)
✓ Cognitive load (focused, not cluttered)
✓ Conventions (expected patterns)

Which variant do you prefer for each screen?

Screen 1 ([Screen Name]):
  [1] Tight layout (compact, dense)
  [2] Airy layout (spacious, relaxed) ⭐ Recommended
  [3] Card-based (grouped content)
  [4] List-based (linear flow)
  [5] Split-screen (side-by-side)

Selection: _
```

**Record selection**:

```bash
yq -i '.phases.variations.status = "completed"' design/$FEATURE_SLUG/design-state.yaml
yq -i '.phases.variations.selected_variant = '$SELECTED_VARIANT design/$FEATURE_SLUG/design-state.yaml
yq -i '.human_gates.variant_selection.status = "approved"' design/$FEATURE_SLUG/design-state.yaml
yq -i '.human_gates.variant_selection.timestamp = "'$(date -Iseconds)'"' design/$FEATURE_SLUG/design-state.yaml
yq -i '.human_gates.variant_selection.selected = '$SELECTED_VARIANT design/$FEATURE_SLUG/design-state.yaml
```

**Checkpoint**:

```
✅ Phase 1: Variations Complete

Selected Variants:
  - Screen 1: Variant 2 (Airy layout)
  - Screen 2: Variant 3 (Card-based)

Next: Phase 2 (Functional) - Merge variants and add interactivity

Continue to Phase 2? (y/n)
```

---

## Phase 2: Functional (Converge)

**Goal**: Merge selected variants into functional prototype with full interactivity and accessibility.

**Agent**: `design-functional-agent` (or inline implementation)

### Step 2.1: Merge Selected Variants

**For each screen**:

```bash
# Copy selected variant to functional directory
SELECTED=$(yq '.phases.variations.selected_variant' design/$FEATURE_SLUG/design-state.yaml)
cp mock/[screen-id]/variants/variant-$SELECTED.tsx mock/[screen-id]/functional/[screen-name].tsx
```

### Step 2.2: Add Interactivity

**Enhance with**:

- **Hover states**: `hover:shadow-lg`, `hover:bg-gray-100`
- **Focus states**: `focus:ring-2 focus:ring-blue-500`
- **Transitions**: `transition-shadow duration-200`
- **Click handlers**: `onClick`, `onSubmit`
- **Form validation**: Inline validation on blur
- **Loading states**: Skeleton screens, spinners

**Example**:

```typescript
// Before (static variant)
<Button>Save</Button>

// After (functional prototype)
<Button
  onClick={handleSave}
  disabled={isLoading}
  className="hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 transition-colors"
>
  {isLoading ? <Spinner /> : 'Save'}
</Button>
```

### Step 2.3: Add Accessibility

**Implement**:

- **ARIA labels**: `aria-label`, `aria-labelledby`, `aria-describedby`
- **Keyboard navigation**: Proper tab order, focus trap in modals
- **Semantic HTML**: `<header>`, `<main>`, `<nav>`, `<footer>`
- **Screen reader support**: `<span className="sr-only">`, `aria-live`
- **Alt text**: Meaningful descriptions for all images

**Example**:

```typescript
// Before (no accessibility)
<button onClick={onClose}>
  <XIcon />
</button>

// After (full accessibility)
<button
  onClick={onClose}
  aria-label="Close dialog"
  className="focus:ring-2 focus:ring-blue-500"
>
  <XIcon aria-hidden="true" />
</button>
```

### Step 2.4: Run Hierarchy Validation

```bash
node .spec-flow/scripts/design-lint.js mock/*/functional/

# Analyze hierarchy
echo "## Hierarchy Analysis" > design/hierarchy-analysis.md
echo "" >> design/hierarchy-analysis.md

# Check heading ratios
H1_SIZE=$(grep -r "text-" mock/*/functional/ | grep "h1" | head -1 | sed -E 's/.*text-([0-9]+xl).*/\1/')
H2_SIZE=$(grep -r "text-" mock/*/functional/ | grep "h2" | head -1 | sed -E 's/.*text-([0-9]+xl).*/\1/')

echo "H1: text-$H1_SIZE" >> design/hierarchy-analysis.md
echo "H2: text-$H2_SIZE" >> design/hierarchy-analysis.md
echo "Ratio: [Calculate]" >> design/hierarchy-analysis.md

# Check F-pattern (manual review required)
echo "" >> design/hierarchy-analysis.md
echo "F-Pattern Validation:" >> design/hierarchy-analysis.md
echo "- [ ] Most important content is top-left" >> design/hierarchy-analysis.md
echo "- [ ] Secondary content is top-horizontal bar" >> design/hierarchy-analysis.md
echo "- [ ] Supporting content is left-vertical column" >> design/hierarchy-analysis.md
```

### Step 2.5: Run "Don't Make Me Think" Checklist

**Automated checks**:

```bash
# Check for obvious clickable elements
BUTTON_COUNT=$(grep -r "<Button" mock/*/functional/ | wc -l)
LINK_COUNT=$(grep -r "<Link" mock/*/functional/ | wc -l)
echo "Interactive elements: $BUTTON_COUNT buttons, $LINK_COUNT links"

# Check for form validation
VALIDATION_COUNT=$(grep -r "error" mock/*/functional/ | grep -i "message" | wc -l)
echo "Validation messages: $VALIDATION_COUNT"

# Check for loading states
LOADING_COUNT=$(grep -r "isLoading\|loading\|Skeleton" mock/*/functional/ | wc -l)
echo "Loading states: $LOADING_COUNT"
```

**Generate checklist**:

```bash
cp .spec-flow/templates/design-system/dont-make-me-think-checklist.md \
   design/$FEATURE_SLUG/dont-make-me-think-checklist.md

# Pre-fill automated results
sed -i "s/\[ \] Clickable elements look clickable/[x] Clickable elements look clickable ($BUTTON_COUNT buttons)/" \
   design/$FEATURE_SLUG/dont-make-me-think-checklist.md
```

**Present to user**:

```
📋 Usability Checklist

Please review the functional prototype and complete the checklist:
design/$FEATURE_SLUG/dont-make-me-think-checklist.md

Automated checks:
✅ Interactive elements: 15 buttons, 8 links
✅ Validation messages: 5 forms with error handling
✅ Loading states: 3 async operations with feedback

Manual review required:
⏳ Visual clarity (5 critical items)
⏳ Navigation (5 critical items)
⏳ Content scannability (5 critical items)

Complete checklist and return here when ready.
```

### Step 2.6: Human Gate - Functional Approval

**Wait for user to complete checklist and approve**:

```bash
echo "Review functional prototype at: http://localhost:3000/mock/[screen-id]/functional"
echo ""
echo "Complete checklist: design/$FEATURE_SLUG/dont-make-me-think-checklist.md"
echo ""
echo "Approve functional prototype? (y/n/revise)"
read APPROVAL

if [ "$APPROVAL" = "y" ]; then
  yq -i '.phases.functional.status = "completed"' design/$FEATURE_SLUG/design-state.yaml
  yq -i '.human_gates.functional_approval.status = "approved"' design/$FEATURE_SLUG/design-state.yaml
  yq -i '.human_gates.functional_approval.timestamp = "'$(date -Iseconds)'"' design/$FEATURE_SLUG/design-state.yaml
elif [ "$APPROVAL" = "n" ]; then
  echo "What needs to be revised?"
  read REVISIONS
  echo "$REVISIONS" >> design/$FEATURE_SLUG/NOTES.md
  exit 0
else
  echo "Provide revision notes:"
  read REVISIONS
  echo "$REVISIONS" >> design/$FEATURE_SLUG/NOTES.md
  echo "Run: /design continue (after revisions)"
  exit 0
fi
```

**Checkpoint**:

```
✅ Phase 2: Functional Complete

Usability Score: 95% (48/50 critical + important items passed)
Hierarchy: ✅ 2:1 ratios validated
Accessibility: ✅ WCAG AAA (7:1 contrast)
F-Pattern: ✅ Optimized

Next: Phase 3 (Polish) - Apply brand tokens and final polish

Continue to Phase 3? (y/n)
```

---

## Phase 3: Polish (Systemize)

**Goal**: Apply brand tokens, ensure 100% token compliance, generate implementation spec.

**Agent**: `design-polish-agent` (or inline implementation)

### Step 3.1: Token Compliance Pre-Check

**Before applying brand, verify functional prototype is clean**:

```bash
# Run design lint
node .spec-flow/scripts/design-lint.js mock/*/functional/

CRITICAL_COUNT=$(grep -c "🔴 CRITICAL" design/lint-report.md || echo 0)
ERROR_COUNT=$(grep -c "🔴 ERROR" design/lint-report.md || echo 0)

if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$ERROR_COUNT" -gt 0 ]; then
  echo "❌ Token compliance pre-check failed."
  echo "Fix issues in functional prototype before applying brand."
  cat design/lint-report.md
  exit 1
fi

# Check for hardcoded values
HEX_COUNT=$(grep -r "#[0-9a-fA-F]\{6\}" mock/*/functional/ | grep -v "node_modules" | wc -l)
ARBITRARY_COUNT=$(grep -r "\[[0-9]" mock/*/functional/ | grep "className" | wc -l)

if [ "$HEX_COUNT" -gt 0 ] || [ "$ARBITRARY_COUNT" -gt 0 ]; then
  echo "⚠️  Found hardcoded values:"
  echo "  - Hex colors: $HEX_COUNT"
  echo "  - Arbitrary values: $ARBITRARY_COUNT"
  echo "Fix before proceeding."
  exit 1
fi
```

### Step 3.2: Apply Brand Tokens

**Copy functional to polished directory**:

```bash
cp -r mock/*/functional/* mock/*/polished/
```

**Replace placeholders with brand tokens**:

```bash
# Read tokens
PRIMARY_COLOR=$(jq -r '.colors.primary.value' design/design-system/tokens.json)
TEXT_PRIMARY=$(jq -r '.colors.text.primary.value' design/design-system/tokens.json)

# Apply to polished files
find mock/*/polished/ -name "*.tsx" -exec sed -i "s/gray-900/$TEXT_PRIMARY/g" {} \;
find mock/*/polished/ -name "*.tsx" -exec sed -i "s/blue-600/$PRIMARY_COLOR/g" {} \;
```

**Or use design-polish agent**:

Task: Apply brand tokens from `design/design-system/tokens.json` to `mock/*/polished/*.tsx`

### Step 3.3: Add Subtle Gradients

**From gradient rules in tokens.json**:

```json
{
  "gradients": {
    "subtle-vertical": {
      "value": "linear-gradient(to bottom, rgb(59 130 246 / 0.05), transparent)",
      "usage": ["Hero sections", "Feature cards"]
    }
  }
}
```

**Apply strategically**:

```typescript
// Hero section
<section className="bg-gradient-to-b from-blue-50 to-white">

// Feature card accent
<Card className="bg-gradient-to-b from-accent-50 to-white shadow-md">
```

### Step 3.4: Verify Elevation Scale

**Audit shadow usage**:

```bash
echo "## Elevation Audit" > design/elevation-audit.md
echo "" >> design/elevation-audit.md

for LEVEL in "shadow-sm" "shadow-md" "shadow-lg" "shadow-xl" "shadow-2xl"; do
  COUNT=$(grep -r "$LEVEL" mock/*/polished/ | wc -l)
  echo "- $LEVEL (z-$((LEVEL+1))): $COUNT usages" >> design/elevation-audit.md
done

# Check for borders (should be minimal)
BORDER_COUNT=$(grep -r "border-gray\|border-blue" mock/*/polished/ | wc -l)
echo "- Borders (anti-pattern): $BORDER_COUNT usages" >> design/elevation-audit.md

if [ "$BORDER_COUNT" -gt 5 ]; then
  echo "⚠️  High border usage detected ($BORDER_COUNT). Prefer shadows for depth."
fi
```

### Step 3.5: Run Final Design Lint

```bash
node .spec-flow/scripts/design-lint.js mock/*/polished/

CRITICAL_COUNT=$(grep -c "🔴 CRITICAL" design/lint-report.md || echo 0)
ERROR_COUNT=$(grep -c "🔴 ERROR" design/lint-report.md || echo 0)
WARNING_COUNT=$(grep -c "🟡 WARNING" design/lint-report.md || echo 0)

echo "🔍 Final Design Lint Results:"
echo "   Critical: $CRITICAL_COUNT"
echo "   Errors: $ERROR_COUNT"
echo "   Warnings: $WARNING_COUNT"

if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$ERROR_COUNT" -gt 0 ]; then
  echo "❌ Design lint failed. Phase 3 requires 100% compliance."
  cat design/lint-report.md
  exit 1
fi

# Calculate compliance score
TOTAL_CHECKS=5
PASSED_CHECKS=$((TOTAL_CHECKS - (CRITICAL_COUNT + ERROR_COUNT)))
COMPLIANCE_SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "✅ Token Compliance: $COMPLIANCE_SCORE%"

if [ "$COMPLIANCE_SCORE" -lt 100 ]; then
  echo "❌ Compliance below 100%. Fix issues before proceeding."
  exit 1
fi
```

### Step 3.6: Generate Implementation Spec

```bash
# Copy template
cp .spec-flow/templates/design-system/implementation-spec.md \
   design/$FEATURE_SLUG/implementation-spec.md

# Fill in details
sed -i "s/\[Feature Name\]/$FEATURE_NAME/" design/$FEATURE_SLUG/implementation-spec.md
sed -i "s/\[Date\]/$(date -Idate)/" design/$FEATURE_SLUG/implementation-spec.md

# Extract component usage from polished files
echo "## Component Usage" >> design/$FEATURE_SLUG/implementation-spec.md
grep -r "import.*from '@/components/ui" mock/*/polished/ | sort | uniq >> design/$FEATURE_SLUG/implementation-spec.md

# Document token usage
echo "" >> design/$FEATURE_SLUG/implementation-spec.md
echo "## Token Usage Summary" >> design/$FEATURE_SLUG/implementation-spec.md
jq '.colors.primary, .colors.text, .typography, .spacing' design/design-system/tokens.json \
   >> design/$FEATURE_SLUG/implementation-spec.md
```

### Step 3.7: Human Gate - Polish Approval

**Present final design**:

```
🎨 Design Polish Complete

Final polished prototypes: http://localhost:3000/mock/[screen-id]/polished

Validation Results:
✅ Token Compliance: 100%
✅ Design Lint: 0 critical, 0 errors, 2 warnings
✅ Elevation Scale: Correct usage (minimal borders)
✅ Gradient Compliance: Subtle, monochromatic
✅ Hierarchy: 2:1 ratios maintained
✅ Accessibility: WCAG AAA (7:1 contrast)

Implementation Spec: design/$FEATURE_SLUG/implementation-spec.md

Approve final design for implementation? (y/n/revise)
```

**Record approval**:

```bash
read APPROVAL

if [ "$APPROVAL" = "y" ]; then
  yq -i '.phases.polish.status = "completed"' design/$FEATURE_SLUG/design-state.yaml
  yq -i '.human_gates.polish_approval.status = "approved"' design/$FEATURE_SLUG/design-state.yaml
  yq -i '.human_gates.polish_approval.timestamp = "'$(date -Iseconds)'"' design/$FEATURE_SLUG/design-state.yaml
  yq -i '.workflow.status = "completed"' design/$FEATURE_SLUG/design-state.yaml
else
  echo "Provide revision notes:"
  read REVISIONS
  echo "$REVISIONS" >> design/$FEATURE_SLUG/NOTES.md
  echo "Run: /design continue (after revisions)"
  exit 0
fi
```

**Final Checkpoint**:

```
✅ Design Workflow Complete

Phases:
✅ Variations - 5 variants generated, variant 2 selected
✅ Functional - Interactivity and accessibility added
✅ Polish - Brand tokens applied, 100% compliance

Artifacts:
📄 Implementation Spec: design/$FEATURE_SLUG/implementation-spec.md
📄 Don't Make Me Think Checklist: design/$FEATURE_SLUG/dont-make-me-think-checklist.md
📄 Design Lint Report: design/lint-report.md
📄 Hierarchy Analysis: design/hierarchy-analysis.md

Next Steps:
1. Review implementation-spec.md
2. Hand off to frontend-shipper agent
3. Run: /feature (to start implementation with design validation)

Design is ready for implementation! 🚀
```

---

## Resume Capability

**If user runs `/design continue`**:

```bash
# Load current state
CURRENT_PHASE=$(yq '.workflow.current_phase' design/$FEATURE_SLUG/design-state.yaml)
CURRENT_STATUS=$(yq '.workflow.status' design/$FEATURE_SLUG/design-state.yaml)

case "$CURRENT_PHASE" in
  "variations")
    # Check if waiting for human gate
    GATE_STATUS=$(yq '.human_gates.variant_selection.status' design/$FEATURE_SLUG/design-state.yaml)
    if [ "$GATE_STATUS" = "pending" ]; then
      echo "Resuming from Phase 1: Variant Selection"
      # Jump to Step 1.5 (Human Gate)
    fi
    ;;

  "functional")
    GATE_STATUS=$(yq '.human_gates.functional_approval.status' design/$FEATURE_SLUG/design-state.yaml)
    if [ "$GATE_STATUS" = "pending" ]; then
      echo "Resuming from Phase 2: Functional Approval"
      # Jump to Step 2.6 (Human Gate)
    fi
    ;;

  "polish")
    GATE_STATUS=$(yq '.human_gates.polish_approval.status' design/$FEATURE_SLUG/design-state.yaml)
    if [ "$GATE_STATUS" = "pending" ]; then
      echo "Resuming from Phase 3: Polish Approval"
      # Jump to Step 3.7 (Human Gate)
    fi
    ;;

  *)
    echo "Unknown phase: $CURRENT_PHASE"
    exit 1
    ;;
esac
```

---

## Status Display

**If user runs `/design status`**:

```bash
FEATURE=$(yq '.workflow.feature' design/$FEATURE_SLUG/design-state.yaml)
STATUS=$(yq '.workflow.status' design/$FEATURE_SLUG/design-state.yaml)
CURRENT_PHASE=$(yq '.workflow.current_phase' design/$FEATURE_SLUG/design-state.yaml)

echo "📊 Design Workflow Status"
echo ""
echo "Feature: $FEATURE"
echo "Status: $STATUS"
echo "Current Phase: $CURRENT_PHASE"
echo ""
echo "Phases:"
echo "  ✅ Variations: $(yq '.phases.variations.status' design/$FEATURE_SLUG/design-state.yaml)"
echo "  $([ "$CURRENT_PHASE" = "functional" ] && echo "⏳" || echo "⬜") Functional: $(yq '.phases.functional.status' design/$FEATURE_SLUG/design-state.yaml)"
echo "  ⬜ Polish: $(yq '.phases.polish.status' design/$FEATURE_SLUG/design-state.yaml)"
echo ""
echo "Human Gates:"
echo "  Variant Selection: $(yq '.human_gates.variant_selection.status' design/$FEATURE_SLUG/design-state.yaml)"
echo "  Functional Approval: $(yq '.human_gates.functional_approval.status' design/$FEATURE_SLUG/design-state.yaml)"
echo "  Polish Approval: $(yq '.human_gates.polish_approval.status' design/$FEATURE_SLUG/design-state.yaml)"
echo ""
echo "Next Action: $([ "$STATUS" = "in_progress" ] && echo "/design continue" || echo "Design complete")"
```

---

## Integration with /feature Workflow

**When design is complete, integrate with implementation**:

```yaml
# Update workflow-state.yaml
workflow:
  phase: "design_complete"
  design_artifacts:
    implementation_spec: "design/$FEATURE_SLUG/implementation-spec.md"
    polished_prototypes: "mock/*/polished/"
    token_compliance: 100
```

**frontend-shipper agent reads**:

- `design/$FEATURE_SLUG/implementation-spec.md` - Complete component, token, interaction spec
- `design/design-system/tokens.json` - Brand tokens
- `design/design-system/ui-inventory.md` - Component library
- `mock/*/polished/*.tsx` - Visual reference for pixel-perfect implementation

---

## Error Handling

**If any phase fails**:

```bash
yq -i '.workflow.status = "blocked"' design/$FEATURE_SLUG/design-state.yaml
echo "❌ Design workflow blocked. See NOTES.md for details."
echo ""
echo "Run: /design continue (after fixing issues)"
exit 1
```

**Common blockers**:

- **Phase 1**: Design lint fails on variants → fix hardcoded colors, hierarchy issues
- **Phase 2**: Accessibility audit fails → add ARIA labels, keyboard nav
- **Phase 3**: Token compliance < 100% → remove hardcoded values, use tokens

---

## Success Criteria

**Workflow complete when**:

- ✅ All 3 phases completed
- ✅ All human gates approved
- ✅ Design lint passes (0 critical, 0 errors)
- ✅ Token compliance = 100%
- ✅ Implementation spec generated
- ✅ Usability checklist score ≥ 90%

---

## Next Steps After Design

**Hand off to implementation**:

1. **Update workflow-state.yaml** with design artifacts
2. **Run /feature** (if part of feature workflow)
3. **Or run /implement** (standalone design implementation)
4. **frontend-shipper agent** reads implementation-spec.md for pixel-perfect build

---

**End of /design Command Specification**

This orchestrator chains all three design phases with automated validation and human approval gates, ensuring S-tier UI/UX without Figma.

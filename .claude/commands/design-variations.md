---
description: Phase 1 - Generate 3-5 grayscale UI variants per screen (diverge fast)
---

Generate design variations for: $ARGUMENTS

## MENTAL MODEL

**Three-Phase Design Pipeline**: variations (diverge) → functional (converge) → polish (systemize)

**This phase (Phase 1)**: Explore options before committing
- Input: `screens.yaml`, `ui-inventory.md`, real copy
- Output: 3-5 grayscale variants per screen
- Human gate: Pick winner in `crit.md`

**Next**: `/design-functional` (merge selected pieces → functional prototype)

---

## LOAD FEATURE

**Get feature from argument or current branch:**

```bash
if [ -n "$ARGUMENTS" ]; then
  SLUG="$ARGUMENTS"
else
  SLUG=$(git branch --show-current)
fi

FEATURE_DIR="specs/$SLUG"
MOCK_DIR="apps/web/mock/$SLUG"

# Validate feature exists
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  echo "Run \spec-flow first"
  exit 1
fi

# Required files
required_files=(
  "$FEATURE_DIR/design/screens.yaml"
  "$FEATURE_DIR/design/copy.md"
  "design/systems/ui-inventory.md"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing: $file"
    echo "Run \spec-flow to generate required design artifacts"
    exit 1
  fi
done

# Optional files (check existence)
if [ -f "$FEATURE_DIR/design/heart-metrics.md" ]; then
  HEART_METRICS="$FEATURE_DIR/design/heart-metrics.md"
else
  HEART_METRICS=""
fi
```

---

## READ INPUTS

**Extract design constraints:**

```bash
# Read screens inventory
SCREENS_YAML="$FEATURE_DIR/design/screens.yaml"

# Read component catalog
UI_INVENTORY="design/systems/ui-inventory.md"

# Read real copy
COPY_MD="$FEATURE_DIR/design/copy.md"

# Read HEART metrics (optional)
HEART_METRICS="$FEATURE_DIR/design/heart-metrics.md"
```

**Parse screens.yaml to extract screen IDs and states:**

```bash
# Extract screen IDs (lines starting with 2 spaces + letter)
SCREEN_IDS=($(grep "^  [a-z]" "$SCREENS_YAML" | awk '{print $1}' | tr -d ':'))

# For each screen, extract states
for screen_id in "${SCREEN_IDS[@]}"; do
  # Parse states for this screen
  STATES=$(sed -n "/^  $screen_id:/,/^  [a-z]/p" "$SCREENS_YAML" | \
           grep "states:" | \
           sed 's/.*states: \[\(.*\)\]/\1/' | \
           tr ',' ' ')

  # Store for variant generation
  eval "STATES_${screen_id}=($STATES)"
done
```

**Parse ui-inventory.md to extract allowed components:**

```bash
# Extract component names (lines with "##" headers)
ALLOWED_COMPONENTS=($(grep "^## " "$UI_INVENTORY" | sed 's/## //'))
```

---

## JOBS PRINCIPLES CHECKLIST

**Before generating variants, apply Steve Jobs design constraints:**

```bash
# 1. Read Jobs principles
echo "📐 Applying Jobs Principles..."
cat \spec-flow/memory/design-philosophy.md

# 2. Define constraints
PRIMARY_ACTION=$(grep "primary_action:" "$SCREENS_YAML" | head -1 | sed 's/.*: //')
MAX_CLICKS=2
KILL_IF="instructions needed OR >2 clicks OR multiple CTAs"

# 3. Set innovation requirement
echo ""
echo "Innovation Requirements:"
echo "  ✅ At least 2 variants MUST break from conventional patterns"
echo "  ✅ Test opposite approaches (e.g., if competitors use modal, try inline)"
echo "  ✅ Question assumption: Why does this need to work this way?"
echo ""

# 4. Validation checklist
echo "Pre-generation checklist:"
echo "  - [ ] Primary action ≤5 words: \"$PRIMARY_ACTION\""
echo "  - [ ] Max clicks: $MAX_CLICKS"
echo "  - [ ] Kill if: $KILL_IF"
echo "  - [ ] Each variant tests ONE approach (not feature-packed)"
echo "  - [ ] At least 2 variants break from convention"
echo ""
```

**Generate with these constraints:**
- One primary CTA per screen (Jobs principle: Focus)
- Zero tooltips (Jobs principle: Simplicity)
- 8px grid spacing (Jobs principle: Details Matter)
- 250ms transitions (Jobs principle: Smooth Animations)

---

## GENERATE VARIANTS (3-5 per screen)

**For EACH screen in screens.yaml:**

### Determine Variant Count

```bash
# Count components for this screen from screens.yaml
COMPONENT_COUNT=$(sed -n "/^  $screen_id:/,/^  [a-z]/p" "$SCREENS_YAML" | \
                  grep -c "components:")

# Determine variant count based on complexity
if [ "$COMPONENT_COUNT" -le 2 ]; then
  VARIANT_COUNT=3  # Simple screen
elif [ "$COMPONENT_COUNT" -le 5 ]; then
  VARIANT_COUNT=4  # Medium screen
else
  VARIANT_COUNT=5  # Complex screen
fi
```

### Calculate Total Files

```bash
SCREEN_COUNT=${#SCREEN_IDS[@]}
TOTAL_SCREENS=0
TOTAL_FILES=0

for screen_id in "${SCREEN_IDS[@]}"; do
  eval "STATES=(\${STATES_${screen_id}[@]})"
  STATE_COUNT=${#STATES[@]}

  # Files per screen: variants + variant index + compare page
  SCREEN_FILES=$((VARIANT_COUNT + 2))
  TOTAL_SCREENS=$((TOTAL_SCREENS + 1))
  TOTAL_FILES=$((TOTAL_FILES + SCREEN_FILES))
done

# Warn if large
if [ "$TOTAL_FILES" -gt 50 ]; then
  echo "⚠️  This will generate approximately $TOTAL_FILES files"
  echo "    ($SCREEN_COUNT screens × ~$VARIANT_COUNT variants each)"
  echo ""
  echo "Consider:"
  echo "  - Break into smaller features (fewer screens)"
  echo "  - Reduce variant count per screen"
  echo ""
  echo "Proceed? (y/n)"
  read -r response
  if [ "$response" != "y" ]; then
    exit 0
  fi
fi
```

### Variant Generation Strategy

**Generate $VARIANT_COUNT variants exploring:**
1. **Layout variations** (stacked, side-by-side, grid, list)
2. **Interaction patterns** (inline, modal, sheet, redirect)
3. **Copy density** (concise, descriptive, verbose)
4. **Component choices** (different primitives from inventory)
5. **State handling** (inline progress, redirect, optimistic UI)

**Constraints** (MUST enforce):
- ✅ Grayscale only (no brand colors, will apply in Phase 3)
- ✅ System components only (from `ui-inventory.md`, no custom widgets)
- ✅ All states reachable via `?state=` query param
- ✅ Real copy from `copy.md` (no placeholder text)
- ✅ Mobile-first (responsive by default)
- ✅ Small diffs between variants (change one thing at a time)

**Example** (Upload screen variants):

**v1: Stacked Layout + Redirect Flow**
- Drag-drop zone (Card)
- "Upload" button → redirect to results page
- Progress on separate page
- Traditional multi-step flow

**v2: Inline Preview + Same-Page Flow**
- Drag-drop zone (Card)
- Inline preview card after selection
- "Extract" button inside preview
- Progress bar above preview
- All on same screen (HEART hypothesis: faster time-to-insight)

**v3: Compact + Modal Confirmation**
- Small upload button (no drag-drop)
- File picker dialog
- Preview in modal
- "Confirm" → extraction → results on page

**v4: Side-by-Side + Real-Time Preview**
- Left: Upload zone
- Right: Live preview pane
- Extraction starts automatically
- Desktop-first layout

**v5: Minimal + Progressive Disclosure**
- Single "Select File" button
- After selection: Expand to show preview
- "Extract ACS Codes" CTA
- Collapse back after completion

### Implementation per Variant

**Create route structure:**
```bash
for screen_id in "${SCREEN_IDS[@]}"; do
  for i in $(seq 1 $VARIANT_COUNT); do
    mkdir -p "$MOCK_DIR/$screen_id/v$i"
  done
done
```

**Each variant route** (`$MOCK_DIR/$screen_id/v[N]/page.tsx`):

```tsx
'use client';

import { useSearchParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { Skeleton } from '@/components/ui/skeleton';

export default function UploadV1() {
  const searchParams = useSearchParams();
  const state = searchParams?.get('state') || 'default';

  // State-driven rendering (generate from screens.yaml states)
  ${GENERATE_STATE_CASES}  // Dynamic based on parsed states

  // Default state
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Card className="border-dashed border-2">
        <CardHeader>
          <CardTitle className="text-2xl">Upload AKTR Report</CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          {/* Variant-specific layout */}
          <div className="text-center space-y-4">
            <input type="file" id="file-upload" className="sr-only" />
            <label htmlFor="file-upload" className="cursor-pointer block">
              <div className="border-2 border-dashed border-gray-300 rounded-lg p-12 hover:border-gray-400 transition-colors">
                <div className="text-gray-600">
                  Drop your file here or click to browse
                </div>
              </div>
            </label>
            <Button variant="default" size="default">
              Upload Report
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Variant notes (development only) */}
      <div className="mt-8 p-4 bg-gray-50 rounded-lg text-sm">
        <h3 className="font-semibold mb-2">Variant 1 Notes:</h3>
        <ul className="list-disc list-inside space-y-1 text-gray-700">
          <li>Traditional redirect flow (upload → new page)</li>
          <li>Drag-drop zone with visual feedback</li>
          <li>Large touch target (full card clickable)</li>
          <li>States: ?state=default|uploading|error</li>
        </ul>
        <p className="mt-2 font-medium">Tradeoff: More clicks, familiar pattern</p>
      </div>
    </div>
  );
}

// State components (generate dynamically from screens.yaml)
${GENERATE_STATE_COMPONENTS}

function LoadingState() {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Card>
        <CardContent className="pt-6">
          <Skeleton className="h-48 w-full" />
          <Skeleton className="h-4 w-3/4 mt-4" />
        </CardContent>
      </Card>
    </div>
  );
}

function ErrorState() {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Alert variant="destructive">
        <AlertDescription>
          Upload failed. Please check your file and try again.
        </AlertDescription>
      </Alert>
    </div>
  );
}

function UploadingState() {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Card>
        <CardContent className="pt-6 space-y-4">
          <p>Uploading your report...</p>
          <Progress value={65} />
        </CardContent>
      </Card>
    </div>
  );
}
```

### Variant Notes (per variant)

**Create `apps/web/mock/$FEATURE_SLUG/$SCREEN_ID/v[N]/NOTES.md`:**

```markdown
# Variant N: [Brief name]

## Layout
- [Describe structure: stacked, grid, side-by-side]
- [Container: Card, Sheet, Dialog]
- [Spacing: tight, comfortable, spacious]

## Interaction Pattern
- [Flow: inline, redirect, modal]
- [Primary action: button placement, size, label]
- [Feedback: progress, toast, alert]

## Components Used
- Card (container)
- Button (primary CTA)
- Progress (upload feedback)
- Alert (error display)

## States Implemented
- ?state=default (initial)
- ?state=uploading (progress)
- ?state=error (failure)

## Rationale (Why this variant?)
[1-2 sentences on design hypothesis]

## Tradeoffs
**Pros**:
- [Advantage 1]
- [Advantage 2]

**Cons**:
- [Disadvantage 1]
- [Disadvantage 2]

## HEART Alignment
[How does this variant support HEART hypothesis?]
Example: Inline preview reduces time-to-insight (supports task success metric)
```

---

## GENERATE VARIANT INDEX

**Create `apps/web/mock/$FEATURE_SLUG/$SCREEN_ID/page.tsx` (index of all variants):**

```tsx
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

export default function UploadVariantsIndex() {
  const variants = [
    { id: 1, name: 'Redirect Flow', description: 'Traditional multi-step with redirect' },
    { id: 2, name: 'Inline Preview', description: 'Same-page flow with inline preview' },
    { id: 3, name: 'Modal Confirmation', description: 'Compact with modal preview' },
    { id: 4, name: 'Side-by-Side', description: 'Desktop-first split layout' },
    { id: 5, name: 'Progressive Disclosure', description: 'Minimal with expand on demand' },
  ];

  const states = ['default', 'uploading', 'error'];

  return (
    <div className="container mx-auto py-12">
      <h1 className="text-4xl font-bold mb-2">Upload Screen Variants</h1>
      <p className="text-gray-600 mb-8">Compare 5 design approaches for AKTR upload</p>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {variants.map((variant) => (
          <Card key={variant.id}>
            <CardHeader>
              <CardTitle>v{variant.id}: {variant.name}</CardTitle>
              <CardDescription>{variant.description}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <Link href={`/mock/aktr-upload/upload/v${variant.id}`}>
                <Button variant="default" className="w-full">View Variant</Button>
              </Link>
              <div className="text-sm text-gray-600">
                <p className="font-semibold mt-4 mb-1">Test states:</p>
                {states.map((state) => (
                  <Link
                    key={state}
                    href={`/mock/aktr-upload/upload/v${variant.id}?state=${state}`}
                    className="block text-blue-600 hover:underline"
                  >
                    ?state={state}
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="mt-12 p-6 bg-gray-50 rounded-lg">
        <h2 className="text-xl font-semibold mb-4">Next Steps</h2>
        <ol className="list-decimal list-inside space-y-2">
          <li>Review all 5 variants (test each state)</li>
          <li>Fill out <code>design/features/[feat]/crit.md</code> (keep/change/kill)</li>
          <li>Run <code>/design-functional</code> to merge selected pieces → main</li>
        </ol>
      </div>
    </div>
  );
}
```

---

## GENERATE VARIANT COMPARISON PAGE

**Create `$MOCK_DIR/$screen_id/compare/page.tsx`:**

```tsx
'use client';

import { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

export default function CompareVariants() {
  const [state, setState] = useState('default');
  const variants = [${VARIANT_LIST}];  // Generated from variant count
  const states = [${STATE_LIST}];      // Generated from screens.yaml

  return (
    <div className="container mx-auto py-12">
      <div className="mb-8">
        <h1 className="text-4xl font-bold mb-2">Compare: ${screen_id} Variants</h1>
        <p className="text-gray-600">Side-by-side comparison of design approaches</p>

        {/* State selector */}
        <div className="mt-4">
          <label className="text-sm font-medium">View state:</label>
          <Tabs value={state} onValueChange={setState} className="mt-2">
            <TabsList>
              {states.map((s) => (
                <TabsTrigger key={s} value={s}>
                  {s}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
        </div>
      </div>

      {/* Side-by-side iframes */}
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {variants.map((variant) => (
          <Card key={variant.id}>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                v{variant.id}
                <Badge>{variant.name}</Badge>
              </CardTitle>
              <CardDescription>{variant.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <iframe
                src={`/mock/${SLUG}/${screen_id}/v${variant.id}?state=${state}`}
                className="w-full h-96 border rounded-lg"
                title={`Variant ${variant.id}`}
              />
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="mt-8 p-6 bg-gray-50 rounded-lg">
        <h2 className="text-xl font-semibold mb-2">How to Review</h2>
        <ol className="list-decimal list-inside space-y-2">
          <li>Toggle states above to test each variant's behavior</li>
          <li>Look for: layout clarity, copy effectiveness, interaction smoothness</li>
          <li>Note which elements work best from each variant</li>
          <li>Fill design/features/${SLUG}/crit.md with Keep/Change/Kill decisions</li>
        </ol>
      </div>
    </div>
  );
}
```

---

## CREATE CRIT TEMPLATE

**Initialize `$FEATURE_DIR/design/crit.md`:**

```bash
# Check template exists
if [ ! -f "\spec-flow/templates/design-crit-template.md" ]; then
  echo "❌ Missing: \spec-flow/templates/design-crit-template.md"
  exit 1
fi

# Copy template
cp "\spec-flow/templates/design-crit-template.md" "$FEATURE_DIR/design/crit.md"

# Fill with dynamic data from screens.yaml
sed -i "s/{{FEATURE_SLUG}}/$SLUG/g" "$FEATURE_DIR/design/crit.md"
sed -i "s/{{SCREEN_COUNT}}/$SCREEN_COUNT/g" "$FEATURE_DIR/design/crit.md"

# Generate variant matrix for each screen
for screen_id in "${SCREEN_IDS[@]}"; do
  echo "## Screen: $screen_id" >> "$FEATURE_DIR/design/crit.md"
  echo "" >> "$FEATURE_DIR/design/crit.md"
  echo "| Variant | Layout | Interaction | Copy | Verdict | Notes |" >> "$FEATURE_DIR/design/crit.md"
  echo "|---------|--------|-------------|------|---------|-------|" >> "$FEATURE_DIR/design/crit.md"

  for i in $(seq 1 $VARIANT_COUNT); do
    echo "| v$i | | | | [ ] KEEP / [ ] CHANGE / [ ] KILL | |" >> "$FEATURE_DIR/design/crit.md"
  done

  echo "" >> "$FEATURE_DIR/design/crit.md"
done

# Add selected components section
cat >> "$FEATURE_DIR/design/crit.md" <<'EOF'

## Selected Components (for /design-functional)

**After reviewing variants above, list which components to merge:**

### ${screen_id}
- Layout: [v2] - Inline preview, no redirect
- CTA: [v2] - "Extract ACS Codes" inside preview card
- Drag-drop: [v3] - Visual cues for drag target
- Progress: [v2] - Linear bar above preview
- Error: [v2] - Inline alert, not modal

**Changes needed:**
- [ ] Shorten heading per v1 copy
- [ ] Add percentage text to progress bar (v5)
- [ ] Move button inside preview card

EOF
```

---

## GIT COMMIT

```bash
git add $MOCK_DIR/
git add $FEATURE_DIR/design/crit.md
git commit -m "design:variations: generate grayscale variants for $SLUG

Phase 1: Diverge Fast
- 3-5 variants per screen from screens.yaml
- Grayscale only, system components only
- States via ?state= query param
- Variant notes document rationale + tradeoffs

Screens: [list screen IDs]
Components: Card, Button, Progress, Alert (from ui-inventory.md)

Next: Human review → /design-functional

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## OUTPUT (Return to user)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PHASE 1 COMPLETE: Design Variations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: [feature-name]
Screens: N screens, 3-5 variants each
Routes: /apps/web/mock/[feature]/[screen]/v1...v5

Variants generated:
- [Screen 1]: v1 (redirect), v2 (inline), v3 (modal), v4 (side-by-side), v5 (progressive)
- [Screen 2]: v1..v5
- ...

States accessible:
- ?state=default (initial)
- ?state=loading (async operation)
- ?state=error (failure)
- ?state=empty (no data)

Constraints enforced:
✅ Grayscale only (brand tokens in Phase 3)
✅ System components only (from ui-inventory.md)
✅ Real copy (from copy.md)
✅ All states reachable via query param
✅ Mobile-responsive

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 HUMAN CHECKPOINT (Required)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Review variants:
1. Open: http://localhost:3000/mock/[feature]/[screen] (variant index)
2. Test: Each variant + all states (?state=)
3. Critique: Fill design/features/[feat]/crit.md

Decision matrix:
- KEEP: This variant (or elements) for main
- CHANGE: Good idea, needs tweaks (list specific changes)
- KILL: Discard (explain why in crit.md)

Guidance (Jobs Principles):
- Focus on HEART hypothesis (does this move the metric?)
- Consider mobile (50%+ traffic)
- Check system-first (are we reusing or reinventing?)
- One primary CTA per screen (no button soup)
- Jobs checklist (run validation):
  ```bash
  bash \spec-flow/scripts/verify-design-principles.sh
  ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After filling crit.md:
  → /design-functional [feature-slug]

This will:
- Read your critique (keep/change/kill decisions)
- Merge selected components → /mock/[feature]/[screen]/main
- Add keyboard navigation + aria labels
- Create Playwright tests (visual snapshots + a11y)
- Define analytics event names
```

---

## QUALITY GATES

**Before returning, verify:**
- [ ] All screens from screens.yaml have 3-5 variants
- [ ] All variants use ONLY components from ui-inventory.md
- [ ] All states reachable via ?state= query param
- [ ] Variant index page links to all variants + states
- [ ] crit.md template created (empty, ready for human input)
- [ ] No brand colors used (grayscale only)

**Jobs Principles Validation (manual checks, record in crit.md):**
- [ ] Primary action describable in ≤5 words?
- [ ] All variants ≤2 clicks to complete primary action?
- [ ] Zero tooltips needed (design is obvious)?
- [ ] Spacing on 8px grid (run: `bash \spec-flow/scripts/verify-design-principles.sh`)?
- [ ] Transitions 200-300ms?
- [ ] At least 2 variants break from conventional patterns?
- [ ] Real copy from copy.md (no Lorem Ipsum)
- [ ] NOTES.md per variant documents rationale + tradeoffs

**Reject if:**
- ❌ Custom components created (not in ui-inventory.md)
- ❌ Brand colors applied (should be grayscale)
- ❌ States hardcoded (must use ?state= query param)
- ❌ Placeholder copy used (must be real copy from copy.md)

---

## NOTES

**Keep diffs small**: Each variant should change ONE major thing (layout, interaction, copy density, component choice, state handling). Don't change everything at once.

**System-first enforcement**: If screens.yaml requests a component NOT in ui-inventory.md, suggest alternatives or propose new component in `design/systems/proposals/[component].md`.

**Mobile-first**: All variants must be responsive. Use Tailwind's mobile-first breakpoints (`md:`, `lg:`).

**State-driven**: Use query params, not internal state management (keeps variants simple, easy to test).

**Variant count**: 3-5 is ideal. <3 = not enough exploration. >5 = analysis paralysis.

---

**Phase**: 1 of 3 (Variations → Functional → Polish)
**Command Version**: 1.0
**Last Updated**: 2025-10-05


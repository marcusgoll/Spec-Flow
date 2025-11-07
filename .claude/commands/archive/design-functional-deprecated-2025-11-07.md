# ⚠️ DEPRECATED (2025-11-07)

**Phase 2 of 3-phase design workflow replaced by style guide approach.**
**Use `/quick` with `docs/project/style-guide.md` instead.**
**See:** `docs/STYLE_GUIDE_MIGRATION.md`

---

# /design-functional (ARCHIVED)

---
description: Phase 2 - Merge selected variants → functional prototype with a11y + tests
---

Merge design variants for: $ARGUMENTS

## MENTAL MODEL

**Three-Phase Design Pipeline**: variations (diverge) → **functional (converge)** → polish (systemize)

**This phase (Phase 2)**: Make the chosen design work end-to-end
- Input: `crit.md` (keep/change/kill decisions)
- Output: `/mock/[feat]/[screen]/functional` (functional prototype)
- Additions: Keyboard nav, a11y, Playwright tests, analytics event names

**Next**: `/implement` (promote `/mock` → `/app` with brand tokens + instrumentation)

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
CRIT_FILE="$FEATURE_DIR/design/crit.md"

# Validate feature exists
if [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ Feature not found: $FEATURE_DIR"
  exit 1
fi

# Validate design phase complete
if [ ! -f "$CRIT_FILE" ]; then
  echo "❌ Missing: $CRIT_FILE"
  echo "Human checkpoint required:"
  echo "  1. Run /design-variations $SLUG"
  echo "  2. Review variants at http://localhost:3000/mock/$SLUG/[screen]"
  echo "  3. Fill $CRIT_FILE with Keep/Change/Kill decisions"
  exit 1
fi

# Validate variants exist
if [ ! -d "$MOCK_DIR" ]; then
  echo "❌ No variants found: $MOCK_DIR"
  echo "Run /design-variations $SLUG first"
  exit 1
fi

# Check for KEEP decisions
KEEP_COUNT=$(grep -c "KEEP" "$CRIT_FILE" || echo 0)
if [ "$KEEP_COUNT" -eq 0 ]; then
  echo "❌ No KEEP decisions found in crit.md"
  echo ""
  echo "Review variants and mark components to keep:"
  echo "  - Open: http://localhost:3000/mock/$SLUG/[screen]/compare"
  echo "  - Edit: $CRIT_FILE"
  echo "  - Mark: At least one element per screen as KEEP"
  exit 1
fi
```

---

## READ CRITIQUE

**Parse `crit.md` to extract:**
- Which variants to KEEP (per screen)
- Which components to merge from multiple variants
- Changes required before merging
- Rationale for decisions

**Example parsed decisions**:
```yaml
upload:
  layout: v2  # Inline preview, no redirect
  cta: v2  # "Extract ACS Codes" inside preview card
  drag_drop: v3  # Visual cues for drag target
  progress: v2  # Linear bar above preview
  error: v2  # Inline alert, not modal
  changes:
    - "Shorten heading: 'Upload AKTR Report'"
    - "Add percentage text to progress bar"
    - "Move Extract button inside preview card"
```

---

## MERGE VARIANTS → MAIN

**For EACH screen:**

### Create Functional Prototype Route

**File**: `$MOCK_DIR/$SCREEN_ID/functional/page.tsx`

**Merge strategy**:
1. **Base structure**: Use primary KEEP variant as foundation
2. **Component swaps**: Replace elements with KEEP'd components from other variants
3. **Apply changes**: Implement all changes from crit.md
4. **Add a11y**: Keyboard navigation, ARIA labels, focus management
5. **Add instrumentation stubs**: Analytics event names (not implementation yet)

**Example** (merged upload screen):

```tsx
'use client';

import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';

// Analytics stub function (implementation in Phase 3)
function trackEvent(event: string, properties?: Record<string, any>) {
  if (process.env.NODE_ENV === 'development') {
    console.log('[Analytics Stub]', event, properties);
  }
  // TODO: Implement in /implement phase
  // - PostHog: posthog.capture(event, properties)
  // - Logs: logger.info({ event, ...properties })
  // - DB: db.featureMetrics.create({ feature, variant, outcome, value })
}

// Analytics event names (instrumentation in Phase 3)
const ANALYTICS_EVENTS = {
  PAGE_VIEW: 'upload.page_view',
  FILE_SELECTED: 'upload.file_selected',
  PREVIEW_SHOWN: 'upload.preview_shown',
  EXTRACT_CLICKED: 'upload.extract_clicked',
  EXTRACTION_PROGRESS: 'upload.extraction_progress',
  FIRST_CODE_VISIBLE: 'upload.first_code_visible',
  ERROR_OCCURRED: 'upload.error',
} as const;

export default function UploadFunctional() {
  useEffect(() => {
    trackEvent(ANALYTICS_EVENTS.PAGE_VIEW, {
      variant: 'functional_prototype',
      timestamp: Date.now(),
    });
  }, []);
  const searchParams = useSearchParams();
  const state = searchParams?.get('state') || 'default';

  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState(0);

  // State-driven rendering (from variants)
  if (state === 'loading') {
    return <SkeletonState />;
  }

  if (state === 'error') {
    return <ErrorState />;
  }

  if (state === 'extracting' || progress > 0) {
    return <ExtractingState progress={progress} />;
  }

  if (file && state === 'preview') {
    return <PreviewState file={file} onExtract={() => setProgress(10)} />;
  }

  // Default: Upload zone (merged from v2 layout + v3 drag-drop visuals)
  return (
    <div className="container max-w-2xl mx-auto py-12">
      {/* Merged: v2 layout (stacked) + v3 drag-drop visuals */}
      <Card className="border-dashed border-2 border-gray-300 hover:border-gray-400 transition-colors">
        <CardHeader>
          {/* Change applied: Shortened heading (was "Upload Your AKTR Report to Get Started") */}
          <CardTitle className="text-2xl">Upload AKTR Report</CardTitle>
          <p className="text-sm text-gray-600">Get ACS-mapped weak areas in seconds</p>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="text-center space-y-4">
            {/* Keyboard accessible file input */}
            <input
              type="file"
              id="file-upload"
              className="sr-only"
              accept=".pdf,image/jpeg,image/png"
              onChange={(e) => {
                const selected = e.target.files?.[0];
                if (selected) {
                  setFile(selected);
                  trackEvent(ANALYTICS_EVENTS.FILE_SELECTED, {
                    file_size: selected.size,
                    file_type: selected.type,
                  });
                }
              }}
              aria-label="Select AKTR report file"
            />
            <Label htmlFor="file-upload" className="cursor-pointer block">
              {/* Merged: v3 drag-drop visual cues */}
              <div
                className="border-2 border-dashed border-gray-300 rounded-lg p-12 hover:border-gray-400 transition-colors focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-gray-900"
                role="button"
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    document.getElementById('file-upload')?.click();
                  }
                }}
              >
                <div className="text-gray-600">
                  <p className="text-lg font-medium">Drop your file here or click to browse</p>
                  <Badge variant="secondary" className="mt-2">
                    PDF, JPG, PNG (max 50MB)
                  </Badge>
                </div>
              </div>
            </Label>
          </div>
        </CardContent>
      </Card>

      {/* Development notes (auto-stripped in production builds) */}
      {process.env.NODE_ENV === 'development' && (
        <div className="mt-8 p-4 bg-gray-50 rounded-lg text-sm border-l-4 border-blue-500">
          <h3 className="font-semibold mb-2 text-blue-900">🔧 Development Notes</h3>
          <div className="text-gray-700">
            <p className="font-medium mb-1">Merged from variants:</p>
            <ul className="list-disc list-inside space-y-1">
              <li><strong>v2:</strong> Inline preview layout (no redirect)</li>
              <li><strong>v3:</strong> Drag-drop visual cues</li>
              <li><strong>v2:</strong> Progress bar above preview</li>
            </ul>
            <p className="mt-2 font-medium">Changes applied from crit.md:</p>
            <ul className="list-disc list-inside space-y-1">
              <li>Shortened heading (was: "Upload Your AKTR Report...")</li>
              <li>Keyboard accessible (Tab, Enter, Space)</li>
              <li>ARIA labels added (all interactive elements)</li>
              <li>Focus visible (2px ring on upload zone)</li>
            </ul>
          </div>
        </div>
      )}
    </div>
  );
}

// Preview state (merged from v2 + v5)
function PreviewState({ file, onExtract }: { file: File; onExtract: () => void }) {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Card>
        <CardHeader>
          <CardTitle>Preview: {file.name}</CardTitle>
          <p className="text-sm text-gray-600">{(file.size / 1024 / 1024).toFixed(2)} MB</p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-gray-100 rounded-lg p-4">
            <p className="text-sm text-gray-600">File ready for extraction</p>
          </div>
          {/* Change applied: Button INSIDE preview card (was below) */}
          <Button
            variant="default"
            size="default"
            onClick={onExtract}
            className="w-full"
            aria-label="Extract ACS codes from uploaded file"
          >
            Extract ACS Codes
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

// Extracting state with progress (merged from v2)
function ExtractingState({ progress }: { progress: number }) {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Card>
        <CardContent className="pt-6 space-y-4">
          <p className="text-lg font-medium">Extracting ACS codes...</p>
          {/* Change applied: Show percentage text (was visual only) */}
          <div className="space-y-2">
            <Progress value={progress} aria-label={`Extraction progress: ${progress}%`} />
            <p className="text-sm text-gray-600 text-center">{progress}%</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Error state (merged from v2: inline, not modal)
function ErrorState() {
  return (
    <div className="container max-w-2xl mx-auto py-12">
      <Alert variant="destructive">
        <AlertDescription>
          Upload failed. Please check your file size (&lt;50MB) and format (PDF, JPG, PNG) and try again.
        </AlertDescription>
      </Alert>
      <Button
        variant="outline"
        onClick={() => window.location.reload()}
        className="mt-4"
        autoFocus  // Focus on recovery action
      >
        Try Again
      </Button>
    </div>
  );
}

// Skeleton state (loading)
function SkeletonState() {
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
```

---

## ADD ACCESSIBILITY

**For each screen's main implementation:**

### Keyboard Navigation
```tsx
// ✅ All interactive elements focusable
<button>Click me</button>  // Native focusable

// ✅ Custom elements need tabIndex
<div
  role="button"
  tabIndex={0}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      onClick();
    }
  }}
>
  Click me
</div>

// ✅ Skip links (add to layout)
<a href="#main-content" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

### ARIA Labels
```tsx
// ✅ Form inputs have labels
<Label htmlFor="email">Email</Label>
<Input id="email" type="email" />

// ✅ Icon-only buttons have aria-label
<Button variant="ghost" size="icon" aria-label="Close dialog">
  <XIcon />
</Button>

// ✅ Progress announced
<Progress value={progress} aria-label={`Upload progress: ${progress}%`} />

// ✅ Live regions for dynamic updates
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>
```

### Focus Management
```tsx
// ✅ Visible focus indicator (2px ring)
className="focus:ring-2 focus:ring-offset-2 focus:ring-gray-900"

// ✅ Focus returns after modal close
useEffect(() => {
  if (!modalOpen && triggerRef.current) {
    triggerRef.current.focus();
  }
}, [modalOpen]);

// ✅ Error focus on recovery action
<Button autoFocus>Try Again</Button>
```

---

## VALIDATE READING HIERARCHY (S-Tier Principles)

**After merging variants, automatically validate visual hierarchy and reading flow:**

### Hierarchy Validation Script

**Run automated checks** against S-tier design principles:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📐 VALIDATING READING HIERARCHY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run design lint on functional prototype
node .spec-flow/scripts/design-lint.js "$MOCK_DIR/*/functional"

# Check specifically for hierarchy issues
if [ -f "design/lint-report.md" ]; then
  HIERARCHY_ERRORS=$(grep -c "Insufficient heading hierarchy" design/lint-report.md || echo 0)
  WEIGHT_ERRORS=$(grep -c "No font weight variation" design/lint-report.md || echo 0)

  echo "Hierarchy Validation:"
  echo "  - Heading ratio errors: $HIERARCHY_ERRORS"
  echo "  - Weight variation errors: $WEIGHT_ERRORS"
  echo ""

  # Copy to feature directory
  cp design/lint-report.md "$FEATURE_DIR/design/functional-lint-report.md"

  if [ "$HIERARCHY_ERRORS" -gt 0 ]; then
    echo "⚠️  Heading hierarchy issues detected"
    echo "   Common fixes:"
    echo "   - Increase h1 size (e.g., text-3xl → text-4xl)"
    echo "   - Decrease h2 size (e.g., text-2xl → text-xl)"
    echo "   - Ensure 2:1 ratio minimum (e.g., 36px → 18px)"
    echo ""
  fi

  if [ "$WEIGHT_ERRORS" -gt 0 ]; then
    echo "⚠️  Font weight variation needed"
    echo "   Add weight progression: normal → medium → semibold → bold"
    echo ""
  fi
fi
```

### Manual F-Pattern Check

**Provide checklist for human verification:**

```markdown
# Reading Hierarchy Checklist

Based on F-pattern eye-tracking research (Nielsen Norman Group):

## Visual Hierarchy (Automated ✅)
- [ ] Heading size ratios ≥2:1 (verified by design-lint)
- [ ] Font weight progression (normal → medium → semibold → bold)
- [ ] Color contrast WCAG AAA (7:1 for body text)

## F-Pattern Optimization (Manual)
- [ ] **Top-left**: Logo/brand visible (user orientation)
- [ ] **Top-horizontal**: Primary navigation (wayfinding)
- [ ] **Left-vertical**: Section titles scannable (information scent)
- [ ] **Center-focal**: Primary content (main value prop)
- [ ] **Bottom-right**: Primary CTA (natural end point)

## Z-Pattern (for Landing Pages)
- [ ] Hero headline top-left (entry point)
- [ ] Supporting text top-right (secondary info)
- [ ] Visual/benefit left (engagement)
- [ ] CTA bottom-right (conversion)

## Reading Flow
- [ ] Most important info "above the fold" (no scroll needed)
- [ ] Secondary info progressively disclosed (scroll reveals)
- [ ] CTAs visible throughout (sticky header, inline, footer)

## Color Depth & Layering
- [ ] Background layer: neutral-50 or white
- [ ] Content layer: cards with shadow-md (z-1 or z-2)
- [ ] Interactive layer: buttons with shadow-sm on hover
- [ ] Focus layer: ring-2 ring-offset-2 on focus

## Validation
Run this checklist for EACH screen in functional prototype:
1. Open http://localhost:3000/mock/[feature]/[screen]/functional
2. Squint test: Can you still identify hierarchy? (blur vision slightly)
3. 5-second test: What's the main action? (show to colleague for 5s, ask)
4. Mobile test: Resize to 375px, hierarchy still clear?

If any checkbox unchecked → Iterate on functional prototype
```

### Automated Hierarchy Analysis

**Create analysis file**: `$FEATURE_DIR/design/hierarchy-analysis.md`

```bash
# Extract headings and analyze ratios
cat > "$FEATURE_DIR/design/hierarchy-analysis.md" <<EOF
# Reading Hierarchy Analysis - Functional Prototype

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Phase**: Functional (Phase 2)

## Detected Headings

$(grep -r "className.*text-.*xl" "$MOCK_DIR/*/functional" || echo "No headings detected")

## Size Ratios

Analyzing heading progression:
- h1: text-4xl (36px) → h2: text-2xl (24px) = **1.5:1** ⚠️ (should be 2:1)
- h2: text-2xl (24px) → h3: text-xl (20px) = **1.2:1** ⚠️ (should be 2:1)

## Recommendations

### Size Adjustments
- Increase h1: text-4xl → text-5xl (36px → 48px)
- OR decrease h2: text-2xl → text-lg (24px → 18px)
- Result: 48px / 18px = **2.67:1** ✅

### Weight Progression
- h1: font-bold (700)
- h2: font-semibold (600)
- h3: font-medium (500)
- body: font-normal (400)

### Color Contrast (WCAG AAA)
- Headings: text-gray-900 on white (7.8:1) ✅
- Body: text-gray-800 on white (6.2:1) ✅
- Secondary: text-gray-600 on white (4.2:1) ⚠️ (AA only, use gray-700 for AAA)

## F-Pattern Analysis

**Top-left**: Logo/brand ✅
**Top-horizontal**: Navigation ✅
**Left-vertical**: Section titles ⚠️ (increase size for scannability)
**Center-focal**: Primary content ✅
**Bottom-right**: Primary CTA ✅

## Action Items

- [ ] Adjust heading sizes for 2:1 ratios
- [ ] Increase section title sizes (left-vertical F-pattern)
- [ ] Use text-gray-700 for secondary text (WCAG AAA)
- [ ] Verify squint test (hierarchy visible when blurred)
- [ ] Verify 5-second test (main action obvious)

EOF

echo "✅ Created hierarchy analysis: $FEATURE_DIR/design/hierarchy-analysis.md"
echo ""
```

### Shadow Depth Validation

**Check elevation scale compliance:**

```bash
echo "Checking shadow usage (elevation scale)..."

# Count shadow usage
SHADOW_SM=$(grep -r "shadow-sm" "$MOCK_DIR/*/functional" | wc -l)
SHADOW_MD=$(grep -r "shadow-md" "$MOCK_DIR/*/functional" | wc -l)
SHADOW_LG=$(grep -r "shadow-lg" "$MOCK_DIR/*/functional" | wc -l)
SHADOW_XL=$(grep -r "shadow-xl" "$MOCK_DIR/*/functional" | wc -l)

# Count border usage (should be minimal)
BORDER_COUNT=$(grep -r "border-gray\|border-\[" "$MOCK_DIR/*/functional" | grep -v "border-dashed" | wc -l)

echo "Shadow usage:"
echo "  - shadow-sm (z-1): $SHADOW_SM"
echo "  - shadow-md (z-2): $SHADOW_MD"
echo "  - shadow-lg (z-3): $SHADOW_LG"
echo "  - shadow-xl (z-4): $SHADOW_XL"
echo ""

if [ "$BORDER_COUNT" -gt 0 ]; then
  echo "⚠️  Found $BORDER_COUNT borders (prefer shadows for depth)"
  echo "   Review: grep -r 'border-gray' $MOCK_DIR/*/functional"
  echo ""
else
  echo "✅ No borders detected (shadows only)"
  echo ""
fi
```

### Gradient Compliance Check

```bash
echo "Checking gradient usage..."

# Count gradients
GRADIENT_COUNT=$(grep -r "bg-gradient" "$MOCK_DIR/*/functional" | wc -l)

if [ "$GRADIENT_COUNT" -gt 0 ]; then
  echo "Found $GRADIENT_COUNT gradients"

  # Check for multi-stop gradients (via-*)
  MULTI_STOP=$(grep -r "via-" "$MOCK_DIR/*/functional" | wc -l)

  # Check for diagonal gradients (to-br, to-bl, to-tr, to-tl)
  DIAGONAL=$(grep -r "bg-gradient-to-[bt][rl]" "$MOCK_DIR/*/functional" | wc -l)

  if [ "$MULTI_STOP" -gt 0 ]; then
    echo "  ⚠️  $MULTI_STOP multi-stop gradients (max 2 stops)"
  fi

  if [ "$DIAGONAL" -gt 0 ]; then
    echo "  ⚠️  $DIAGONAL diagonal gradients (prefer vertical/horizontal)"
  fi

  if [ "$MULTI_STOP" -eq 0 ] && [ "$DIAGONAL" -eq 0 ]; then
    echo "  ✅ All gradients follow S-tier rules"
  fi
else
  echo "No gradients detected"
fi

echo ""
```

### Output Summary

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 HIERARCHY VALIDATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Reports generated:"
echo "  - $FEATURE_DIR/design/functional-lint-report.md"
echo "  - $FEATURE_DIR/design/hierarchy-analysis.md"
echo ""
echo "Review checklist: design/hierarchy-checklist.md"
echo ""
```

---

## CREATE PLAYWRIGHT TESTS

**File**: `tests/ui/$SLUG/$SCREEN_ID.spec.ts`

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Upload Screen - Functional Prototype', () => {
  test.beforeAll(async () => {
    // Ensure dev server running
    try {
      const response = await fetch('http://localhost:3000/api/health');
      if (!response.ok) {
        throw new Error('Server not healthy');
      }
    } catch (error) {
      throw new Error(
        'Dev server not running. Start with: pnpm dev\n' +
        'Then run tests again.'
      );
    }
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('/mock/${SLUG}/upload/functional');
  });

  // Visual regression (snapshot)
  test('default state matches snapshot', async ({ page }) => {
    await expect(page).toHaveScreenshot('upload-default.png');
  });

  test('uploading state matches snapshot', async ({ page }) => {
    await page.goto('/mock/aktr-upload/upload/main?state=uploading');
    await expect(page).toHaveScreenshot('upload-uploading.png');
  });

  test('error state matches snapshot', async ({ page }) => {
    await page.goto('/mock/aktr-upload/upload/main?state=error');
    await expect(page).toHaveScreenshot('upload-error.png');
  });

  // Accessibility (axe-core)
  test('passes axe accessibility tests (default)', async ({ page }) => {
    const accessibilityScanResults = await new AxeBuilder({ page }).analyze();
    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('passes axe accessibility tests (error)', async ({ page }) => {
    await page.goto('/mock/aktr-upload/upload/main?state=error');
    const accessibilityScanResults = await new AxeBuilder({ page }).analyze();
    expect(accessibilityScanResults.violations).toEqual([]);
  });

  // Keyboard navigation
  test('keyboard navigation works', async ({ page }) => {
    // Tab to upload zone
    await page.keyboard.press('Tab');
    const uploadZone = page.getByRole('button', { name: /drop your file/i });
    await expect(uploadZone).toBeFocused();

    // Enter/Space activates file picker
    await page.keyboard.press('Enter');
    // File picker opens (can't test file selection in Playwright)
  });

  test('focus visible on all interactive elements', async ({ page }) => {
    await page.keyboard.press('Tab');
    const uploadZone = page.getByRole('button');

    // Check focus ring visible (custom assertion)
    const ringClass = await uploadZone.evaluate((el) =>
      window.getComputedStyle(el).outlineWidth
    );
    expect(parseInt(ringClass)).toBeGreaterThan(0);
  });

  // State transitions
  test('file selection shows preview', async ({ page }) => {
    // Mock file selection (requires browser API)
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles({
      name: 'test.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.from('fake pdf content'),
    });

    // Verify preview state
    await expect(page.getByText(/preview:/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /extract acs codes/i })).toBeVisible();
  });

  // Error recovery
  test('error state focuses "Try Again" button', async ({ page }) => {
    await page.goto('/mock/${SLUG}/upload/functional?state=error');

    const tryAgainButton = page.getByRole('button', { name: /try again/i });
    await expect(tryAgainButton).toBeFocused();
  });
});

// Add ARIA validation tests
test.describe('ARIA compliance', () => {
  test('all interactive elements have labels', async ({ page }) => {
    await page.goto('/mock/${SLUG}/upload/functional');

    const interactiveElements = await page.locator(
      'button, [role="button"], a, input, select, textarea'
    ).all();

    for (const element of interactiveElements) {
      const ariaLabel = await element.getAttribute('aria-label');
      const ariaLabelledBy = await element.getAttribute('aria-labelledby');
      const innerText = await element.innerText().catch(() => '');
      const title = await element.getAttribute('title');

      const hasLabel = !!(ariaLabel || ariaLabelledBy || innerText.trim() || title);

      expect(hasLabel,
        'Interactive element missing accessible label'
      ).toBe(true);
    }
  });

  test('form inputs have associated labels', async ({ page }) => {
    await page.goto('/mock/${SLUG}/upload/functional');

    const inputs = await page.locator('input, select, textarea').all();

    for (const input of inputs) {
      const id = await input.getAttribute('id');
      const ariaLabel = await input.getAttribute('aria-label');
      const ariaLabelledBy = await input.getAttribute('aria-labelledby');

      if (id) {
        // Check for associated label
        const label = await page.locator(`label[for="${id}"]`).count();
        expect(
          label > 0 || ariaLabel || ariaLabelledBy,
          `Input with id="${id}" missing label`
        ).toBe(true);
      } else {
        // Must have aria-label if no id
        expect(
          ariaLabel || ariaLabelledBy,
          'Input without id must have aria-label'
        ).toBeTruthy();
      }
    }
  });
});

// Add state transition tests
test.describe('State transitions', () => {
  const states = ['default', 'loading', 'error', 'uploading', 'preview'];

  for (const state of states) {
    test(`${state} state renders without errors`, async ({ page }) => {
      await page.goto(`/mock/${SLUG}/upload/functional?state=${state}`);

      // Check for React errors
      const errors = [];
      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      // Wait for render
      await page.waitForLoadState('networkidle');

      // Should not show error text
      await expect(page.locator('text=/undefined/i')).toHaveCount(0);
      await expect(page.locator('text=/null/i')).toHaveCount(0);

      // Check console for errors
      expect(errors, `Console errors in ${state} state`).toHaveLength(0);
    });
  }
});
```

---

## DOCUMENT ANALYTICS EVENTS

**Create**: `$FEATURE_DIR/design/analytics.md`

```markdown
# Analytics Events: [Feature Name]

**Feature**: [feature-slug]
**Phase**: Functional (event names defined, implementation in Phase 3)

## Event Catalog

| Event Name | Trigger | Properties | HEART Metric |
|------------|---------|------------|--------------|
| `upload.page_view` | Page loaded | `{ variant: string }` | Engagement |
| `upload.file_selected` | File picker closed with file | `{ file_size: number, file_type: string }` | Task Success |
| `upload.preview_shown` | Preview card rendered | `{ preview_time_ms: number }` | Engagement |
| `upload.extract_clicked` | Extract button clicked | `{ file_size: number }` | Task Success |
| `upload.extraction_progress` | Progress update (every 10%) | `{ percent: number }` | - |
| `upload.first_code_visible` | Results rendered | `{ time_to_insight_ms: number }` | Task Success (primary) |
| `upload.error` | Error occurred | `{ error_type: string, error_message: string }` | Happiness (inverse) |
| `upload.abandoned` | User left before completion | `{ duration_before_exit_ms: number }` | Task Success (inverse) |

## Implementation Plan (Phase 3)

**Dual instrumentation**:
1. PostHog (dashboards): `posthog.capture(event_name, properties)`
2. Structured logs (Claude measurement): `logger.info({ event: event_name, ...properties })`
3. Database (A/B tests): `db.featureMetrics.create({ feature, variant, outcome, value })`

**Example** (upload.first_code_visible):
```typescript
// Fire event
const timeToInsight = Date.now() - uploadStartTime;

// PostHog
posthog.capture('upload.first_code_visible', {
  variant: featureFlags.aktr_inline_preview ? 'treatment' : 'control',
  time_to_insight_ms: timeToInsight,
  file_size: file.size,
});

// Structured log
logger.info({
  event: 'upload.first_code_visible',
  variant: featureFlags.aktr_inline_preview ? 'treatment' : 'control',
  time_to_insight_ms: timeToInsight,
  user_id: user?.id || `anon_${sessionId}`,
  timestamp: Date.now(),
});

// Database (for A/B test results)
await db.featureMetrics.create({
  feature: 'aktr_inline_preview',
  variant: featureFlags.aktr_inline_preview ? 'treatment' : 'control',
  user_id: user?.id || `anon_${sessionId}`,
  outcome: 'time_to_insight',
  value: timeToInsight,
});
```

## HEART Mapping

- **Happiness**: Error rate (inverse of `upload.error` count)
- **Engagement**: Repeat uploads (`upload.page_view` per user)
- **Adoption**: New user first upload (`upload.file_selected` WHERE first_time)
- **Retention**: Return within 7 days (`upload.page_view` WHERE returning_user)
- **Task Success**: Upload → results (`upload.first_code_visible` / `upload.page_view`)

## Measurement Queries (for /measure-heart)

```sql
-- Task completion rate
SELECT COUNT(*) FILTER (WHERE outcome = 'first_code_visible') * 100.0 / COUNT(*) as completion_rate
FROM feature_metrics
WHERE feature = 'aktr_inline_preview' AND created_at >= NOW() - INTERVAL '7 days';

-- Time-to-insight (P50, P95)
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY value) as p50_ms,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) as p95_ms
FROM feature_metrics
WHERE feature = 'aktr_inline_preview' AND outcome = 'time_to_insight';
```
```

---

## GIT COMMIT

```bash
git add $MOCK_DIR/*/functional/
git add tests/ui/$SLUG/
git add $FEATURE_DIR/design/analytics.md
git commit -m "design:functional: merge variants → functional prototype for $SLUG

Phase 2: Converge
- Merged selected components from crit.md
- Applied all changes (headings, button placement, progress %)
- Added keyboard navigation (Tab, Enter, Space, ESC)
- Added ARIA labels (inputs, buttons, progress, live regions)
- Created Playwright tests (visual snapshots + axe a11y)
- Documented analytics event names (instrumentation in Phase 3)

Screens: [list]
Tests: Visual regression + a11y (100% pass rate)
A11y: WCAG 2.1 AA compliant (Lighthouse score: 100)

Next: Human review → /implement (promote to production)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## CLEANUP VARIANTS

**Preserve history in git tag, clean working directory:**

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Cleaning Up Variants"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create git tag to preserve variant history
TAG_NAME="design-variants-$SLUG-$(date +%Y%m%d-%H%M%S)"

# Build variant list for tag message
VARIANT_LIST=$(find $MOCK_DIR -type d -name "v[0-9]" 2>/dev/null | sed 's|.*/||' | sort | tr '\n' ', ' | sed 's/,$//' || echo "none")

# Build design decisions summary from crit.md
DESIGN_DECISIONS=""
if [ -f "$CRIT_FILE" ]; then
  DESIGN_DECISIONS=$(grep -A 20 "## Selected Components" "$CRIT_FILE" | head -15 || echo "See crit.md for decisions")
fi

# Create annotated tag
git tag -a "$TAG_NAME" -m "Design variants for $SLUG before cleanup

Variants preserved: $VARIANT_LIST
Merged into: functional/
Review date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Design decisions (from crit.md):
$DESIGN_DECISIONS

To restore variants:
  git checkout $TAG_NAME
  git checkout $TAG_NAME -- apps/web/mock/$SLUG/"

echo "✅ Created git tag: $TAG_NAME"
echo "   Variants preserved: $VARIANT_LIST"
echo ""

# Count screens and variants before deletion
SCREEN_COUNT=0
VARIANT_COUNT=0

for screen_dir in $MOCK_DIR/*/; do
  if [ -d "$screen_dir" ]; then
    SCREEN=$(basename "$screen_dir")
    SCREEN_COUNT=$((SCREEN_COUNT + 1))

    # Count and delete variant folders (v1, v2, v3, v4, v5)
    for variant_dir in $screen_dir/v[0-9]/; do
      if [ -d "$variant_dir" ]; then
        VARIANT=$(basename "$variant_dir")
        VARIANT_COUNT=$((VARIANT_COUNT + 1))
        rm -rf "$variant_dir"
        echo "  🗑️  Deleted: $SCREEN/$VARIANT"
      fi
    done

    # Optional: Delete comparison page (can keep for reference)
    if [ -f "$screen_dir/compare/page.tsx" ]; then
      rm -rf "$screen_dir/compare"
      echo "  🗑️  Deleted: $SCREEN/compare"
    fi

    # Optional: Delete variant index page (can keep for reference)
    # if [ -f "$screen_dir/page.tsx" ]; then
    #   rm -f "$screen_dir/page.tsx"
    #   echo "  🗑️  Deleted: $SCREEN/page.tsx (variant index)"
    # fi
  fi
done

echo ""
echo "✅ Cleanup complete"
echo "   Deleted: $VARIANT_COUNT variant folders from $SCREEN_COUNT screens"
echo "   Kept: functional/ prototypes (production-ready)"
echo ""
echo "To restore variants:"
echo "   git checkout $TAG_NAME -- apps/web/mock/$SLUG/"
echo ""

# Update workflow state
if [ -f "$FEATURE_DIR/workflow-state.yaml" ]; then
  yq eval '.design_workflow.artifacts.variants_tagged = true' -i "$FEATURE_DIR/workflow-state.yaml"
  yq eval '.design_workflow.artifacts.variants_deleted = true' -i "$FEATURE_DIR/workflow-state.yaml"
  yq eval ".design_workflow.artifacts.tag_name = \"$TAG_NAME\"" -i "$FEATURE_DIR/workflow-state.yaml"
  echo "✅ Updated workflow state"
  echo ""
fi

# Commit cleanup
git add $MOCK_DIR/
git commit -m "design:cleanup: archive and remove variants for $SLUG

Variants preserved in git tag: $TAG_NAME
Deleted: $VARIANT_LIST ($VARIANT_COUNT folders)
Kept: functional/ prototypes

Cleanup summary:
- Screens cleaned: $SCREEN_COUNT
- Variants removed: $VARIANT_COUNT
- Tag created: $TAG_NAME

Restore with:
  git checkout $TAG_NAME -- apps/web/mock/$SLUG/

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✅ Cleanup committed to git"
echo ""
```

---

## OUTPUT (Return to user)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PHASE 2 COMPLETE: Functional Prototype
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: [feature-name]
Routes: /apps/web/mock/[feature]/[screen]/functional

Merged from critique:
- [Screen 1]: v2 (layout) + v3 (drag-drop) + v2 (progress)
- [Screen 2]: ...

Changes applied:
✅ Shortened headings per crit.md
✅ Moved Extract button inside preview card
✅ Added percentage text to progress bar
✅ [N more changes]

Accessibility added:
✅ Keyboard navigation (Tab, Enter, Space, ESC)
✅ ARIA labels (inputs, buttons, progress, live regions)
✅ Focus management (visible rings, auto-focus on errors)
✅ Screen reader support (semantic HTML, landmarks)

Hierarchy validated:
✅ Heading size ratios ≥2:1 (design-lint verified)
✅ Font weight progression (normal → medium → semibold → bold)
✅ F-pattern optimization (top-left, horizontal, vertical, focal, CTA)
✅ Color depth & layering (background → content → interactive → focus)
✅ Shadow elevation scale (z-0 to z-5, minimal borders)
✅ Gradient compliance (<20% opacity, max 2 stops, no diagonals)

Tests created:
✅ Visual regression (snapshots per state)
✅ Accessibility (axe-core, 100% pass)
✅ Keyboard navigation (all interactive elements)
✅ State transitions (default → preview → extracting → results)

Analytics events:
📊 N events defined in design/features/[feat]/analytics.md
- upload.page_view, upload.file_selected, upload.first_code_visible, ...
- Mapped to HEART metrics (Task Success, Engagement, Happiness)
- Instrumentation deferred to Phase 3 (dual: PostHog + logs + DB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 HUMAN CHECKPOINT (Required)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Review functional prototype:
1. Open: http://localhost:3000/mock/[feature]/[screen]/functional
2. Test: All states (?state=default|uploading|error|preview)
3. Keyboard: Tab through, Enter/Space to activate, ESC to close
4. Screen reader: NVDA (Windows) or VoiceOver (Mac)
5. Mobile: Resize browser to 375px width

Verify:
- [ ] All KEEP'd components merged correctly
- [ ] All changes from crit.md applied
- [ ] Keyboard navigation works (no traps)
- [ ] Focus visible (2px ring on all interactive)
- [ ] Screen reader announces labels, errors, progress
- [ ] Mobile responsive (no horizontal scroll)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After approval:
  → /implement [feature-slug]

This will (Phase 3):
- Promote /mock/[feature] → /app/[feature]
- Apply brand tokens (colors, fonts, shadows)
- Instrument analytics (PostHog + logs + DB)
- Setup feature flag (A/B test: control vs. treatment)
- Run Lighthouse CI (perf + a11y validation)
- Check budgets (bundle size, FCP, TTI, CLS)

Or iterate:
  → /design-variations [feature-slug] (start over with new variants)
  → Manually edit /mock/[feature]/[screen]/main (quick fixes)
```

---

## QUALITY GATES

**Before returning, verify:**
- [ ] crit.md decisions fully implemented (all KEEP'd + changes)
- [ ] All states accessible via ?state= query param
- [ ] Keyboard navigation complete (Tab, Enter, Space, ESC)
- [ ] ARIA labels on all interactive elements
- [ ] **Hierarchy validated** (design-lint run, reports generated)
- [ ] **Heading ratios ≥2:1** (verified in hierarchy-analysis.md)
- [ ] **Shadow elevation used** (minimal borders, shadows for depth)
- [ ] **Gradients compliant** (if used: <20% opacity, max 2 stops, vertical/horizontal)
- [ ] Playwright tests created (visual + a11y)
- [ ] analytics.md documents all events + HEART mapping
- [ ] No custom components (only from ui-inventory.md)
- [ ] Still grayscale (brand tokens in Phase 3)

**Jobs Perfection Checklist (manual verification required):**
- [ ] Time test: 5 users ALL <10s to complete primary action, 0 questions asked
- [ ] Simplicity: ≤2 clicks to complete primary action, no tooltips needed
- [ ] Details: Spacing audit passes (8px grid, run `bash \spec-flow/scripts/verify-design-principles.sh`)
- [ ] Details: Animation audit passes (200-300ms transitions with easing)
- [ ] Focus: One primary CTA per screen (no button soup)
- [ ] Innovation: Beats control in A/B test (or explain hypothesis in analytics.md)
- [ ] Delight: Smooth transitions (250ms), celebratory success states

**If ANY Jobs checklist unchecked → Return to iteration:**
```bash
# Re-run design-variations with refined constraints
/design-variations [feature-slug]

# Or manually fix in /mock/[feature]/[screen]/main
```

**Reject if:**
- ❌ crit.md decisions ignored or partially implemented
- ❌ Keyboard traps exist (can't ESC from modal)
- ❌ Missing ARIA labels (icon-only buttons, form inputs)
- ❌ Axe tests fail (color contrast, touch targets)
- ❌ Brand colors applied (should wait for Phase 3)

---

## NOTES

**Focus on convergence**: Merge best pieces, not entire variants. Mix-and-match is encouraged.

**A11y is non-negotiable**: All tests must pass before Phase 3. No "we'll fix it later."

**Analytics event NAMES only**: Don't implement firing logic yet (Phase 3). Just document what will fire when.

**Keep it grayscale**: Brand tokens (colors, fonts) apply in Phase 3 when promoting to `/app`.

---

**Phase**: 2 of 3 (Variations → Functional → **Polish**)
**Command Version**: 1.0
**Last Updated**: 2025-10-05


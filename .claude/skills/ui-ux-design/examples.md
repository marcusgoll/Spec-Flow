# UI/UX Design Examples

## Good Example: AKTR Upload Feature

### Phase 1: Variations (Diverge Fast)

**Setup**:
- Feature: AKTR Upload
- Screens: 1 (upload screen)
- Complexity: Medium (3-4 components from screens.yaml)
- Variant count: 3 (appropriate for complexity)

**Variants Created**:
```
v1: Redirect Flow
- Traditional multi-step (upload → new page → results)
- Large drag-drop zone
- Familiar pattern (low risk)

v2: Inline Preview
- Same-page flow (no redirect)
- Inline preview after file selection
- Extract button inside preview card
- Hypothesis: Reduces time-to-insight (HEART metric)

v3: Modal Confirmation
- Compact upload button (no drag-drop)
- Preview in modal
- Progressive disclosure pattern
- Hypothesis: Saves vertical space
```

**Quality Metrics**:
- ✅ Variant count: 3 (within 3-5 range)
- ✅ Each tests ONE hypothesis (flow pattern)
- ✅ Small diffs (only interaction pattern changes)
- ✅ System components only (Card, Button, Progress)
- ✅ Real copy (from copy.md: "Upload AKTR Report")
- ✅ Grayscale (no brand colors yet)

---

### Phase 2: Functional (Converge)

**Critique Decision** (crit.md):
```markdown
## Screen: upload

| Variant | Layout | Interaction | Copy | Verdict | Notes |
|---------|--------|-------------|------|---------|-------|
| v1 | Stacked | Redirect | Clear | CHANGE | Use drag-drop, but not redirect |
| v2 | Inline | Same-page | Good | KEEP | Best time-to-insight |
| v3 | Compact | Modal | Too brief | KILL | Saves space but confusing |

## Selected Components

### upload
- Layout: [v2] - Inline preview, no redirect
- Drag-drop: [v1] - Large visual zone (better than v2's small zone)
- CTA: [v2] - "Extract ACS Codes" inside preview card
- Progress: [v2] - Linear bar above preview
- Error: [v2] - Inline alert, not modal

**Changes needed:**
- [ ] Combine v1 drag-drop size with v2 inline flow
- [ ] Add percentage text to progress bar (not just visual)
- [ ] Shorten heading per v1 copy
```

**Functional Implementation**:
```tsx
// Merged: v1 drag-drop visuals + v2 inline flow
export default function UploadFunctional() {
  // State management
  const [file, setFile] = useState<File | null>(null);
  const [progress, setProgress] = useState(0);

  // Keyboard accessible file input (a11y)
  <input
    type="file"
    id="file-upload"
    className="sr-only"
    onChange={(e) => setFile(e.target.files?.[0])}
    aria-label="Select AKTR report file"  // ✅ ARIA label
  />

  // v1 drag-drop visuals
  <label htmlFor="file-upload" className="cursor-pointer block">
    <div
      className="border-2 border-dashed hover:border-gray-400 transition-colors focus-within:ring-2"  // ✅ Focus ring
      role="button"
      tabIndex={0}  // ✅ Keyboard accessible
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          document.getElementById('file-upload')?.click();
        }
      }}
    >
      Drop your file here or click to browse
    </div>
  </label>

  // v2 inline preview (no redirect)
  {file && (
    <Card>
      <CardHeader>
        <CardTitle>Preview: {file.name}</CardTitle>
      </CardHeader>
      <CardContent>
        {/* Change applied: Button INSIDE card */}
        <Button onClick={() => setProgress(10)} aria-label="Extract ACS codes">
          Extract ACS Codes
        </Button>
      </CardContent>
    </Card>
  )}

  // Progress with percentage (change from crit.md)
  {progress > 0 && (
    <Progress value={progress} aria-label={`Extraction progress: ${progress}%`} />
    <p className="text-sm text-center">{progress}%</p>
  )}
}
```

**Accessibility Added**:
- ✅ ARIA labels on file input, buttons, progress
- ✅ Keyboard navigation (Tab, Enter, Space)
- ✅ Focus indicators (ring-2)
- ✅ Screen reader support (semantic HTML)

**Tests Created**:
```typescript
// tests/ui/aktr-upload/upload.spec.ts
test('keyboard navigation works', async ({ page }) => {
  await page.keyboard.press('Tab');
  const uploadZone = page.getByRole('button', { name: /drop your file/i });
  await expect(uploadZone).toBeFocused();
});

test('passes axe accessibility', async ({ page }) => {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

**Cleanup Executed**:
```bash
# Created tag
TAG_NAME="design-variants-aktr-upload-20250119-143022"
git tag -a "$TAG_NAME" -m "Design variants for aktr-upload before cleanup

Variants preserved: v1, v2, v3
Merged into: functional/

Design decisions:
- Layout: v2 (inline preview)
- Drag-drop: v1 (large visual zone)
- Progress: v2 with percentage text"

# Deleted variants
rm -rf apps/web/mock/aktr-upload/upload/v1
rm -rf apps/web/mock/aktr-upload/upload/v2
rm -rf apps/web/mock/aktr-upload/upload/v3

# Committed cleanup
git add apps/web/mock/aktr-upload/
git commit -m "design:cleanup: archive and remove variants for aktr-upload

Variants preserved in tag: $TAG_NAME
Kept: functional/ prototype"
```

**Results**:
- ✅ Variants cleaned up (git tag created first)
- ✅ Only functional/ remains in repo
- ✅ History preserved (can restore with `git checkout $TAG_NAME`)

---

### Phase 3: Polish (Systemize)

**Brand Tokens Applied**:
```tsx
// BEFORE (functional - grayscale)
<Card className="border-gray-300 shadow-sm">
  <Button className="bg-gray-900 text-white hover:bg-gray-800">
    Upload
  </Button>
</Card>

// AFTER (polished - branded)
<Card className="border-neutral-200 shadow-md">
  <Button className="
    bg-brand-primary
    text-white
    hover:bg-brand-primary-600
    active:scale-95
    transition-all duration-200
    focus:ring-2 focus:ring-brand-primary
  ">
    Upload
  </Button>
</Card>
```

**Performance Optimizations**:
```tsx
// Image optimization
import Image from 'next/image';
<Image src="/preview.jpg" width={800} height={600} loading="lazy" />

// Code splitting
import dynamic from 'next/dynamic';
const HelpDialog = dynamic(() => import('@/components/ui/dialog'));
```

**Compliance Validation**:
```bash
# Zero hardcoded colors
HARDCODED_COLORS=0  # ✅ PASS

# All components from ui-inventory.md
CUSTOM_COMPONENTS=0  # ✅ PASS

# Lighthouse scores
Accessibility: 98  # ✅ PASS (≥95)
Performance: 94    # ✅ PASS (≥90)
```

**Final State**:
```
apps/web/mock/aktr-upload/
  upload/
    polished/page.tsx  # Production-ready
    # v1/, v2/, v3/ deleted (preserved in git tag)
    # functional/ kept for reference (optional)
```

---

## Bad Example: Dashboard Feature

### Phase 1: Variations (Too Many)

**Setup**:
- Feature: Student Progress Dashboard
- Screens: 1 (main dashboard)
- Complexity: High (>5 components)
- Variant count: 7 (TOO MANY)

**Variants Created**:
```
v1: Card Grid Layout
v2: List Layout
v3: Table Layout
v4: Card Grid with Sidebar
v5: Card Grid with Top Filters
v6: List with Inline Filters
v7: Table with Modal Details
```

**Problems**:
- ❌ Too many variants (7 > 5 maximum)
- ❌ Analysis paralysis (user took 2 hours to review)
- ❌ Some variants barely different (v1 vs v4 vs v5)
- ❌ Not testing clear hypotheses (layout exploration only)

**What should have been done**:
```
Limit to 5 variants maximum:
v1: Card Grid (baseline)
v2: List (tests compact hypothesis)
v3: Table (tests data density hypothesis)
v4: Card Grid + Filters (tests discoverability)
v5: Progressive Disclosure (tests focus hypothesis)

Kill v6 and v7 (too similar to v2 and v3)
```

---

### Phase 2: Functional (Incomplete Merge)

**Critique Decision** (crit.md):
```markdown
## Screen: dashboard

| Variant | Layout | Interaction | Copy | Verdict | Notes |
|---------|--------|-------------|------|---------|-------|
| v1 | Grid | Click | Good | CHANGE | Use grid, add filters |
| v2 | List | Inline | Too dense | KILL | Hard to scan |
| v3 | Table | Modal | Good | CHANGE | Use for details view |
| v4 | Grid+Sidebar | Click | Good | KEEP | Best discoverability |
| v5 | Grid+Top | Inline | Cluttered | KILL | Filters too prominent |
| v6 | List+Inline | Inline | Confusing | KILL | - |
| v7 | Table+Modal | Modal | Good | CHANGE | Combine with v3 |

## Selected Components

### dashboard
- Layout: [v4] - Grid with sidebar filters
- Card design: [v1] - Clean, not cluttered
- Filters: [v4] - Sidebar, collapsible
- Details: [v3] - Table view on click
```

**Functional Implementation** (PROBLEM):
```tsx
// Only implemented v4, IGNORED crit.md merge instructions
export default function DashboardFunctional() {
  // Just copied v4 entirely
  // Didn't take card design from v1
  // Didn't add table view from v3
  // Ignored merge instructions
}
```

**Problems**:
- ❌ Ignored crit.md decisions (only used v4, not a merge)
- ❌ Missing accessibility (no ARIA labels)
- ❌ Missing keyboard navigation
- ❌ No Playwright tests created
- ❌ Variants NOT cleaned up (all 7 folders left in repo)

**What should have been done**:
```tsx
// Merge components from multiple variants
export default function DashboardFunctional() {
  // v4 layout (grid + sidebar)
  // v1 card design (clean, not cluttered)
  // v3 table view (for details on click)
  // Added: ARIA labels, keyboard nav, tests
}
```

---

### Phase 3: Polish (Design System Violations)

**Polished Implementation** (PROBLEM):
```tsx
// Found hardcoded colors
<Card className="bg-[#0066FF]">  // ❌ Hardcoded hex
  <div style={{ backgroundColor: 'rgb(200, 200, 200)' }}>  // ❌ Inline RGB
    <p className="font-[Roboto]">Dashboard</p>  // ❌ Arbitrary font
  </div>
</Card>

// Found custom components
import { CustomCard } from '../components/CustomCard';  // ❌ Not in ui-inventory.md
<CustomCard>...</CustomCard>

// Found arbitrary spacing
<div className="p-[17px] m-[23px]">  // ❌ Not on 8px grid
```

**Compliance Validation**:
```bash
# Hardcoded colors found
HARDCODED_COLORS=3  # ❌ FAIL (target: 0)

# Custom components found
CUSTOM_COMPONENTS=1  # ❌ FAIL (target: 0)

# Arbitrary spacing found
ARBITRARY_SPACING=2  # ❌ FAIL (target: 0)

# Lighthouse scores
Accessibility: 87  # ❌ FAIL (<95)
Performance: 72    # ❌ FAIL (<90)
```

**Problems**:
- ❌ Design system compliance FAILED
- ❌ Blocked from /implement phase
- ❌ Must fix all violations before production

**What should have been done**:
```tsx
// Use design tokens only
<Card className="bg-brand-primary">
  <div className="bg-neutral-200">
    <p className="font-sans">Dashboard</p>
  </div>
</Card>

// Use components from ui-inventory.md
import { Card } from '@/components/ui/card';
<Card>...</Card>

// Use system spacing
<div className="p-4 m-6">  // 16px, 24px (on 8px grid)
```

---

## Lessons from Examples

### Good Example Characteristics

1. **Right-sized exploration**: 3 variants (simple screen)
2. **Clear hypotheses**: Each variant tests a different flow
3. **Quality merge**: Combined best components from multiple variants
4. **Accessibility first**: ARIA, keyboard, tests added during functional
5. **Clean repository**: Variants tagged and deleted
6. **Design system compliance**: 100% token usage, zero violations
7. **Performance**: Lighthouse ≥95 a11y, ≥90 performance

### Bad Example Red Flags

1. **Over-exploration**: 7 variants (analysis paralysis)
2. **Incomplete merge**: Only copied v4, ignored crit.md
3. **Skipped accessibility**: No ARIA, keyboard, or tests
4. **Skipped cleanup**: All 7 variant folders left in repo
5. **Design system violations**: Hardcoded colors, custom components
6. **Poor performance**: Lighthouse scores failed gates

### Key Takeaway

**Good design workflow**:
- Diverge with 3-5 variants (not 7+)
- Converge by merging best pieces (not copying one variant)
- Systematize with design tokens (not hardcoded values)
- Clean up variants after functional merge (tag → delete)
- Validate compliance before marking complete

**Bad design workflow**:
- Create too many variants (slows decision-making)
- Ignore merge instructions (defeats variant purpose)
- Skip accessibility and cleanup (technical debt)
- Violate design system (blocks production)

---

_These examples will be expanded as real features flow through the design workflow._

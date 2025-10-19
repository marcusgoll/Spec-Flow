---
name: ui-ux-design
description: "Capture lessons from design workflow (variations → functional → polish). Auto-triggers when: starting /design-variations, too many variants created, design system violations, variants not cleaned up. Updates when: variant count >5, accessibility failures, hardcoded colors found, cleanup skipped."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# UI/UX Design: Lessons Learned

**Capability**: Learn from three-phase design workflow to optimize variant exploration, ensure accessibility compliance, enforce design system usage, and maintain clean repositories.

**When I trigger**:
- `/design-variations` starts → Load lessons to guide variant creation (avoid analysis paralysis)
- `/design-functional` starts → Load lessons for merge quality and cleanup execution
- `/design-polish` starts → Load lessons for design token compliance
- Variants complete → Detect if >5 variants created, cleanup skipped, or a11y failures
- Error: Design system violations, hardcoded colors, missing ARIA labels

**Supporting files**:
- [reference.md](reference.md) - Jobs principles checklist, variant quality guidelines, cleanup patterns
- [examples.md](examples.md) - Good variants (3-5, cleaned) vs bad (>5, left in repo)

---

## Common Pitfalls (Auto-Updated)

### 🚫 Too Many Variants (Analysis Paralysis)

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (slows decision-making, clutters repository)

**Scenario**:
```
Screen: Upload
Variants created: 7 (redirect, inline, modal, side-by-side, progressive, compact, full-page)
Result: User overwhelmed, spent 2 hours reviewing, decision delayed
Recommendation: 3-5 variants maximum
```

**Root cause**: Not constraining variant count based on screen complexity

**Detection**:
```bash
# After variant generation
VARIANT_COUNT=$(find $MOCK_DIR/$SCREEN -type d -name "v[0-9]" | wc -l)
if [ "$VARIANT_COUNT" -gt 5 ]; then
  echo "⚠️  Too many variants: $VARIANT_COUNT (recommended: 3-5)"
  echo "   This may cause analysis paralysis"
fi
```

**Prevention**:
1. Simple screens (≤2 components): 3 variants
2. Medium screens (3-5 components): 4 variants
3. Complex screens (>5 components): 5 variants maximum
4. Each variant should test ONE hypothesis (see [reference.md](reference.md#variant-quality))

**If encountered**:
```bash
# Reduce to top 3-5 variants
# Kill variants that:
# - Don't test unique hypothesis
# - Are minor tweaks of other variants
# - Break Jobs principles (>2 clicks, need tooltips)
```

---

### 🚫 Variants Not Cleaned Up

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (cluttered repo, confused future developers)

**Scenario**:
```
Feature: AKTR Upload
Variants: v1/, v2/, v3/, v4/, v5/ created
Functional: Created from merged variants
Issue: All 5 variant folders left in mock/ directory
Result: 6 folders total (5 variants + functional), unclear which is production
```

**Root cause**: Cleanup step missing from /design-functional

**Detection**:
```bash
# After functional merge
if [ -d "$MOCK_DIR/$SCREEN/v1" ]; then
  echo "⚠️  Variants not cleaned up: $SCREEN"
  echo "   Run cleanup: git tag → delete v*/ folders"
fi
```

**Prevention**:
1. After functional merge, create git tag to preserve history
2. Delete all v1/, v2/, v3/, v4/, v5/ folders
3. Update workflow state: `variants_cleaned_up: true`
4. See [reference.md](reference.md#cleanup-patterns)

**If encountered**:
```bash
# Manual cleanup
TAG_NAME="design-variants-$SLUG-$(date +%Y%m%d-%H%M%S)"
git tag -a "$TAG_NAME" -m "Preserve variants before cleanup"
rm -rf $MOCK_DIR/*/v[0-9]
git add $MOCK_DIR/ && git commit -m "design:cleanup: archive variants"
```

---

### 🚫 Design System Violations

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (blocks production, inconsistent UI)

**Scenario**:
```
Polished screen: apps/web/mock/aktr-upload/upload/polished/page.tsx
Violations found:
- Line 45: className="bg-[#0066FF]" (hardcoded color)
- Line 67: <CustomButton> (not from ui-inventory.md)
- Line 89: className="p-[17px]" (arbitrary spacing)
Result: Design system compliance FAILED, blocked from /implement
```

**Root cause**: Not validating token usage during polish phase

**Detection**:
```bash
# After design-polish
HARDCODED_COLORS=$(grep -nE "#[0-9A-Fa-f]{3,8}|rgb\(|rgba\(|hsl\(|hsla\(" "$POLISHED_FILE" | \
                    grep -v "// Design token:" | wc -l)

if [ "$HARDCODED_COLORS" -gt 0 ]; then
  echo "❌ Found $HARDCODED_COLORS hardcoded color value(s)"
  echo "   Must use design tokens from tokens.json"
fi
```

**Prevention**:
1. Colors: Only use design tokens (bg-brand-primary, text-neutral-600)
2. Components: Only from ui-inventory.md (no custom components)
3. Spacing: System scale only (p-4, m-6, not p-[17px])
4. Typography: System fonts only (font-sans, font-mono)
5. Run compliance audit before committing polish

**If encountered**:
```bash
# Fix violations
# Replace #0066FF → bg-brand-primary
# Replace <CustomButton> → <Button> (from ui-inventory.md)
# Replace p-[17px] → p-4 (nearest system value)
# Re-run design-polish compliance audit
```

---

### 🚫 Accessibility Failures

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Critical (blocks production, legal risk)

**Scenario**:
```
Screen: Upload functional
Lighthouse accessibility score: 87 (target: ≥95)
Violations:
- Missing ARIA labels on file input
- Keyboard trap in modal (can't ESC)
- Color contrast 3.2:1 (WCAG AA requires 4.5:1)
Result: BLOCKED from /implement phase
```

**Root cause**: Not adding accessibility during functional merge

**Detection**:
```bash
# After design-functional
if command -v lighthouse &> /dev/null; then
  A11Y_SCORE=$(lighthouse $URL --only-categories=accessibility --quiet \
               | jq '.categories.accessibility.score * 100')

  if [ "$A11Y_SCORE" -lt 95 ]; then
    echo "❌ Accessibility score: $A11Y_SCORE (target: ≥95)"
  fi
fi
```

**Prevention**:
1. Add ARIA labels to all interactive elements
2. Ensure keyboard navigation (Tab, Enter, Space, ESC)
3. Add focus indicators (ring-2 ring-brand-primary)
4. Test with Playwright + axe-core
5. Run Lighthouse CI before marking functional complete

**If encountered**:
```bash
# Fix violations
# Add aria-label="Upload file" to inputs
# Fix keyboard traps (add onKeyDown for ESC)
# Fix color contrast (use semantic tokens)
# Re-run Playwright a11y tests
```

---

### 🚫 Performance Regressions

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (slower UX, poor Lighthouse scores)

**Scenario**:
```
Polished screen: Upload
Lighthouse performance score: 72 (target: ≥90)
Issues:
- Large images not optimized (using <img> instead of Next Image)
- Heavy components not lazy loaded
- No code splitting for Dialog/Tooltip
Result: FCP 2.8s (target: <1.5s)
```

**Root cause**: Not optimizing during polish phase

**Detection**:
```bash
# After design-polish
PERF_SCORE=$(lighthouse $URL --only-categories=performance --quiet \
             | jq '.categories.performance.score * 100')

if [ "$PERF_SCORE" -lt 90 ]; then
  echo "⚠️  Performance score: $PERF_SCORE (target: ≥90)"
fi
```

**Prevention**:
1. Replace <img> with Next.js <Image> component
2. Add lazy loading: loading="lazy"
3. Code split heavy components: dynamic(() => import())
4. Use Suspense for below-fold content
5. Run Lighthouse CI during polish phase

---

## Successful Patterns (Auto-Updated)

### ✅ 3-5 Variants Strategy

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (optimal exploration without paralysis)

**Approach**:
```bash
# Determine variant count based on screen complexity
COMPONENT_COUNT=$(grep -c "components:" $FEATURE_DIR/design/screens.yaml)

if [ "$COMPONENT_COUNT" -le 2 ]; then
  VARIANT_COUNT=3  # Simple screen
elif [ "$COMPONENT_COUNT" -le 5 ]; then
  VARIANT_COUNT=4  # Medium screen
else
  VARIANT_COUNT=5  # Complex screen
fi
```

**Results**:
- Decision time: ~30 minutes (vs 2 hours with 7+ variants)
- Merge quality: Higher (clear best-of-breed selection)
- Repo cleanliness: Better (fewer folders to clean)

**Reuse conditions**:
- ✓ Use when: Any UI screen needs variant exploration
- ✓ Use when: Testing interaction patterns or layouts
- ✗ Don't use when: Screen is trivial (use single design)

---

### ✅ Git Tag Before Cleanup

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (preserves history, keeps repo clean)

**Approach**:
```bash
# Create tag to preserve variant history
TAG_NAME="design-variants-$SLUG-$(date +%Y%m%d-%H%M%S)"
VARIANT_LIST=$(find $MOCK_DIR -type d -name "v[0-9]" | sed 's|.*/||' | sort | tr '\n' ', ')

git tag -a "$TAG_NAME" -m "Design variants for $SLUG before cleanup

Variants preserved: $VARIANT_LIST
Merged into: functional/
Review date: $(date -u +'%Y-%m-%d %H:%M:%S UTC')

To restore variants:
  git checkout $TAG_NAME -- apps/web/mock/$SLUG/"

# Then delete variant folders
rm -rf $MOCK_DIR/*/v[0-9]
```

**Results**:
- History preserved: Can restore any variant from git tag
- Repo clean: Only functional/ remains
- Easy restoration: One command restores all variants

**Reuse conditions**:
- ✓ Use when: Merging variants into functional/
- ✓ Use when: Multiple variants created (3-5)
- ✗ Don't use when: Only one variant created

---

### ✅ Design Token Compliance (100%)

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: Critical (enforces consistency, enables theming)

**Approach**:
```bash
# Validate all colors from tokens.json
HARDCODED_COLORS=$(grep -nE "#[0-9A-Fa-f]{3,8}|rgb\(|rgba\(|hsl\(|hsla\(" "$POLISHED_FILE" | \
                   grep -v "// Design token:" | wc -l)

if [ "$HARDCODED_COLORS" -gt 0 ]; then
  echo "❌ BLOCKING: Found $HARDCODED_COLORS hardcoded colors"
  exit 1
fi
```

**Results**:
- Consistency: All screens use same color palette
- Theming: Can change brand.primary in one place
- Quality: No production deployment with hardcoded colors

**Reuse conditions**:
- ✓ Use when: Polishing any screen
- ✓ Use when: Brand tokens exist in tokens.json
- ✗ Don't use when: Grayscale prototype (functional phase)

---

### ✅ Jobs Perfection Checklist

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (delightful UX, competitive advantage)

**Approach**:
```
Jobs Principles Validation:
- [ ] Focus: One primary CTA per screen
- [ ] Simplicity: ≤2 clicks to complete primary action
- [ ] Simplicity: Zero tooltips needed (design is obvious)
- [ ] Details: Spacing on 8px grid (verified with script)
- [ ] Details: Transitions 200-300ms with easing
- [ ] Innovation: Beats control in hypothesis
```

**Results**:
- User testing: 5/5 users complete task <10s, 0 questions
- Simplicity: No instructions needed
- Delight: Smooth animations, celebratory success states

**Reuse conditions**:
- ✓ Use when: Creating any UI feature
- ✓ Use when: Hypothesis predicts improvement
- ✗ Don't use when: Backend-only features

---

## Phase Checklist (Auto-Updated)

**Pre-variations**:
- [ ] screens.yaml exists (from /specify HAS_UI=true)
- [ ] ui-inventory.md complete (system components defined)
- [ ] copy.md has real copy (no Lorem Ipsum)

**During variations**:
- [ ] Variant count 3-5 (avoid analysis paralysis)
- [ ] Each variant tests ONE hypothesis
- [ ] All variants grayscale (no brand colors)
- [ ] System components only (from ui-inventory.md)

**During functional**:
- [ ] crit.md filled with Keep/Change/Kill decisions
- [ ] All KEEP'd components merged correctly
- [ ] Keyboard navigation added (Tab, Enter, Space, ESC)
- [ ] ARIA labels on all interactive elements
- [ ] Playwright tests created (visual + a11y)
- [ ] Variants cleaned up (git tag → delete v*/)

**During polish**:
- [ ] Design tokens applied (colors, typography, spacing)
- [ ] No hardcoded values (compliance audit passes)
- [ ] Lighthouse accessibility ≥95
- [ ] Lighthouse performance ≥90
- [ ] Micro-interactions added (hover, focus, active)

**Post-polish**:
- [ ] All compliance gates passed
- [ ] Polished prototypes ready for /implement
- [ ] workflow-state.yaml updated

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg variants per screen | 3-5 | Not tracked | - |
| Cleanup compliance | 100% | Not tracked | - |
| Design token violations | 0 | Not tracked | - |
| Lighthouse accessibility | ≥95 | Not tracked | - |
| Lighthouse performance | ≥90 | Not tracked | - |
| Jobs checklist pass rate | 100% | Not tracked | - |

**Updated**: Not yet tracked
**Last feature**: None yet

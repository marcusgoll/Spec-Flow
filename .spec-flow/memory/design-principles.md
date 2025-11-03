# S-Tier Design Principles

**Philosophy**: Master craftsmanship through systematic excellence. Every pixel serves a purpose. Every interaction feels inevitable. Original ideas are overrated—steal from the best, then make it yours.

**Target**: High-end UI/UX that competes with Stripe, Linear, Vercel, and Figma-level polish—without Figma.

---

## Core Tenets

### 1. Don't Make the User Think

**Principle**: Design should be self-explanatory. Every element's purpose must be immediately obvious.

**Rules**:
- Labels beat icons (use both when space allows)
- Primary actions visually dominant (size, color, position)
- Feedback immediate and unambiguous
- Error recovery always one click away
- No dead ends (always provide next step)

**Validation**:
```
✅ Button labeled "Save changes" with checkmark icon
❌ Unlabeled disk icon

✅ "Email sent successfully. View in inbox →"
❌ "Success!"

✅ Form error shows inline, highlights field, suggests fix
❌ Toast notification with generic error code
```

**Automated Checks**:
- All interactive elements have aria-label or visible text
- Primary action has largest size or strongest color
- Error states include actionable recovery text
- Success states include next-step link

---

### 2. Depth Through Elevation, Not Lines

**Principle**: Use box shadows to create visual hierarchy through depth. Borders flatten UI.

**Why**:
- Shadows create 3D space (cards float above page)
- Borders create 2D planes (everything feels flat)
- Elevation scale provides semantic hierarchy (z-0 to z-5)
- Shadows soften edges, borders harden them

**Elevation Scale** (0-5):
```css
/* z-0: Base layer (background, page) */
shadow: none

/* z-1: Slightly raised (cards on page, input fields) */
shadow: 0 1px 2px rgba(0, 0, 0, 0.05)

/* z-2: Raised (hover states, active cards) */
shadow: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)

/* z-3: Floating (dropdowns, popovers) */
shadow: 0 10px 15px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.08)

/* z-4: Modal backdrop content */
shadow: 0 20px 25px rgba(0, 0, 0, 0.12), 0 10px 10px rgba(0, 0, 0, 0.08)

/* z-5: Tooltips, top-level modals */
shadow: 0 25px 50px rgba(0, 0, 0, 0.15), 0 12px 20px rgba(0, 0, 0, 0.12)
```

**When Borders Are OK**:
- Dividers (1px horizontal lines between list items)
- Input focus rings (accessibility requirement)
- Tabs (active indicator)
- Avatars (1px subtle outline for contrast)

**Never Use Borders For**:
- Cards (use shadow instead)
- Buttons (use shadow for depth, solid bg for flat)
- Modals (use shadow)
- Dropdowns (use shadow)

**Validation**:
```
✅ Card with shadow-md (z-2), hover shadow-lg (z-3)
❌ Card with border-gray-200

✅ Dropdown with shadow-xl (z-4)
❌ Dropdown with border-gray-300

✅ Button with shadow-sm on hover
❌ Button with border-blue-500
```

**Automated Checks**:
- Flag `border-*` on Card, Dialog, Popover, DropdownMenu components
- Suggest shadow-{sm|md|lg|xl|2xl} based on element type
- Allow borders only on: Separator, Input (focus), Tabs, Avatar

---

### 3. Subtle Gradients, Not Rainbows

**Principle**: Gradients should whisper, not shout. Use for depth and texture, not decoration.

**Good Gradients**:
- Subtle background wash (5-10% opacity difference)
- Directional lighting (top lighter, bottom darker)
- Glass effects (layered semi-transparent gradients)
- Hero section depth (dark to darker, light to lighter)

**Bad Gradients**:
- Multi-color (red → yellow → blue)
- High contrast (black → white)
- Diagonal gradients >45° (vertical/horizontal only)
- Gradient text (use solid colors for readability)

**Opacity Rules**:
- Max 20% opacity difference between stops
- Max 2 stops (start and end)
- Prefer linear gradients (no radial unless glass effect)

**Validation**:
```
✅ bg-gradient-to-b from-gray-50 to-gray-100 (subtle depth)
✅ bg-gradient-to-t from-blue-500/5 to-blue-500/15 (accent wash)

❌ bg-gradient-to-r from-purple-500 to-pink-500 (too vibrant)
❌ bg-gradient-to-br from-black to-white (too harsh, bad angle)
❌ bg-gradient-to-r from-red-500 via-yellow-500 to-blue-500 (rainbow)
```

**Automated Checks**:
- Flag gradients with >2 stops
- Flag gradients with >45° angle (diagonal)
- Calculate opacity difference between stops (warn if >20%)
- Suggest monochromatic alternatives for multi-color gradients

---

### 4. Reading Hierarchy: Size, Weight, Contrast

**Principle**: Users scan in F-pattern (titles → body → CTAs). Visual hierarchy must guide this flow.

**Hierarchy Layers** (6 levels):
```
Level 1: Hero headline (text-5xl/6xl, font-bold, high contrast)
Level 2: Section titles (text-3xl/4xl, font-semibold)
Level 3: Subsection headings (text-xl/2xl, font-semibold)
Level 4: Body text (text-base, font-normal)
Level 5: Secondary text (text-sm, text-gray-600)
Level 6: Captions/labels (text-xs, text-gray-500)
```

**Contrast Requirements**:
- Adjacent levels: 2:1 size ratio minimum
- Weight difference: At least one step (normal → semibold → bold)
- Color contrast: WCAG AAA preferred (7:1), AA minimum (4.5:1)

**F-Pattern Optimization**:
- Top-left: Logo/brand (orientation)
- Top-horizontal: Primary navigation (wayfinding)
- Left-vertical: Section titles (scanning)
- Center-focal: Primary content (consumption)
- Bottom-right: CTAs (action)

**Validation**:
```
✅ h1: text-4xl font-bold, h2: text-2xl font-semibold (2:1 ratio)
❌ h1: text-2xl font-semibold, h2: text-xl font-medium (1.2:1 ratio)

✅ Headline text-gray-900, body text-gray-700, caption text-gray-500
❌ Everything text-gray-800 (no hierarchy)

✅ Primary CTA bottom-right, large button
❌ Three equal CTAs in a row (confusion)
```

**Automated Checks**:
- Measure heading size ratios (flag if <1.5:1)
- Check weight progression (flag if skipping steps)
- Validate color contrast (WCAG AAA scorer)
- Heatmap simulation (ensure F-pattern coverage)

---

### 5. Steal Like an Artist

**Principle**: Original design is hard and slow. Proven patterns exist—use them.

**Inspiration Sources** (in order of quality):
1. **Production apps** (Stripe, Linear, Vercel, Figma, Notion)
2. **Design showcases** (Dribbble Top Shots, Awwwards SOTD, Behance Featured)
3. **Component galleries** (shadcn themes, Tailwind UI, Radix themes)
4. **Academic research** (Nielsen Norman Group, Baymard Institute)

**How to Steal Well**:
- Study, don't copy pixel-perfect (understand *why* it works)
- Adapt to context (Stripe checkout ≠ Notion editor)
- Combine patterns (Linear sidebar + Vercel dashboard = hybrid)
- Credit inspiration in design notes (transparency)

**Pattern Library**:
- **Forms**: Stripe-style inline validation, Linear multi-step
- **Tables**: Notion sortable headers, Airtable frozen columns
- **Dashboards**: Vercel metrics cards, Linear status board
- **Modals**: Figma command palette, Linear issue detail
- **Empty states**: Linear onboarding, Notion template gallery

**Validation**:
```
✅ "Login form inspired by Stripe (inline validation, single-field focus)"
✅ "Dashboard cards adapt Vercel metrics pattern with our brand tokens"

❌ "We invented a new form pattern" (high risk, test first)
❌ Pixel-perfect Stripe clone with no adaptation
```

**Automated Checks**:
- Require design-inspirations.md reference for each variant
- Link variant notes to specific inspiration (URL or screenshot)
- Flag custom patterns not in patterns.md library

---

### 6. Color Depth: Layering and Shading

**Principle**: Depth comes from layered colors, not flat fills. Use shadows + transparency for richness.

**Layering Technique**:
```
Background layer: neutral-50
↓
Content layer: white with shadow-md
↓
Accent layer: primary-500/10 (10% opacity wash)
↓
Interactive layer: primary-500 with shadow-sm on hover
↓
Focus layer: primary-500 with ring-2 ring-offset-2
```

**Shading Rules**:
- Use neutral palette (11 steps: 50, 100, 200...900, 950)
- Light mode: 50-200 backgrounds, 700-900 text
- Dark mode: 800-950 backgrounds, 50-200 text
- Interactive elements: Shift 100 points on hover (500 → 600)

**Transparency for Depth**:
- Overlays: black/10 or white/10 for subtle effects
- Accent washes: primary/5 for backgrounds, primary/10 for highlights
- Glass effects: white/80 backdrop-blur-lg for cards

**Color Contrast Ratios** (WCAG AAA):
- Body text: 7:1 minimum (gray-900 on white)
- Large text (18pt+): 4.5:1 minimum
- Interactive elements: 3:1 minimum (buttons, inputs)
- Non-text: 3:1 minimum (icons, charts)

**Validation**:
```
✅ Card: bg-white shadow-lg with accent bg-blue-500/5 stripe
✅ Button hover: bg-blue-500 → bg-blue-600 with shadow-md
✅ Text: text-gray-900 (7.8:1 contrast on white)

❌ Card: bg-blue-100 flat fill (no depth)
❌ Button hover: bg-blue-500 → bg-blue-500 (no feedback)
❌ Text: text-gray-600 (3.2:1 contrast, fails AAA)
```

**Automated Checks**:
- Validate contrast ratios (block if <4.5:1 for text)
- Check hover state shifts (warn if same color)
- Flag flat colors on large surfaces (suggest shadow or transparency)
- Measure layering (cards should have 2+ visual layers)

---

## Anti-Patterns: Never Do This

### Visual
- ❌ Rainbow gradients (multi-color gradients)
- ❌ Borders on cards (use shadows)
- ❌ Centered paragraphs (left-align body text)
- ❌ Decorative animations (animation must serve purpose)
- ❌ Auto-playing videos (user control required)
- ❌ Tiny fonts (<14px body text)
- ❌ Low contrast text (gray-400 on white)

### Interaction
- ❌ Disabled buttons without explanation (tell user why)
- ❌ Navigation that disappears (sticky headers preferred)
- ❌ Modals without close button (always provide escape)
- ❌ Forms without inline validation (validate on blur)
- ❌ Ambiguous icons (icon + label required)
- ❌ Pagination without keyboard shortcuts (arrow keys)

### Content
- ❌ Lorem Ipsum (use real copy from copy.md)
- ❌ Stock photos (use illustrations, screenshots, or nothing)
- ❌ Generic error messages ("Something went wrong")
- ❌ Jargon without tooltips (explain technical terms)
- ❌ Empty states without action (always provide next step)

---

## Validation Checklist

**Before Phase 1 (Variations)**:
- [ ] Design inspirations documented (3+ references)
- [ ] Brand tokens initialized (tokens.json exists)
- [ ] Screens inventory complete (screens.yaml)
- [ ] Real copy written (copy.md, no Lorem Ipsum)

**After Phase 1 (Variations)**:
- [ ] 0 hardcoded colors (all use tokens)
- [ ] 0 borders on cards/modals/dropdowns (shadows only)
- [ ] All gradients subtle (<20% opacity delta, max 2 stops)
- [ ] Reading hierarchy validated (2:1 heading ratios, F-pattern)
- [ ] All interactive elements labeled (text or aria-label)
- [ ] Color contrast AAA where possible, AA minimum (4.5:1)
- [ ] Design lint warnings < 5 per screen

**After Phase 2 (Functional)**:
- [ ] Keyboard navigation logical (tab order matches visual order)
- [ ] Focus states visible (ring-2 on all interactive elements)
- [ ] Error recovery paths clear (every error has fix suggestion)
- [ ] Empty states actionable (next step provided)
- [ ] Loading states obvious (skeleton or spinner)
- [ ] Success feedback immediate (toast or inline confirmation)

**After Phase 3 (Polish)**:
- [ ] All components from ui-inventory.md (0 custom components)
- [ ] All spacing on 8px grid (4px min, 8/16/24/32/48/64)
- [ ] All shadows on elevation scale (z-0 to z-5)
- [ ] Lighthouse Accessibility ≥95 (blocks if <95)
- [ ] Lighthouse Performance ≥85
- [ ] Visual regression tests pass (Playwright snapshots)
- [ ] Implementation spec generated (handoff document)

---

## Design Lint Rules

**Critical** (blocks variant generation):
- Hardcoded colors (not from tokens)
- WCAG AA contrast failures (<4.5:1 for text)
- Touch targets <44×44px
- Missing labels on interactive elements

**Error** (requires fix before functional):
- Borders on cards/modals/dropdowns
- Gradients with >20% opacity delta or >2 stops
- Heading hierarchy violations (<2:1 size ratio)
- Multiple primary CTAs (confusing)

**Warning** (suggest fix, allow override):
- Subtle gradient violations (angle >45°, multi-color)
- Custom components (not in ui-inventory.md)
- Spacing not on 8px grid
- Icons without labels

**Info** (informational):
- Shadow usage opportunities (borders → shadows)
- Color depth suggestions (layering tips)
- Pattern recommendations (steal from X)

---

## Success Metrics

**Quantitative**:
- Design lint: <5 warnings per screen
- WCAG AAA: ≥80% of text elements (7:1 contrast)
- Performance: LCP <2.5s, CLS <0.1
- Test coverage: ≥90% component coverage
- Rework rate: <5% (implementation matches polish)

**Qualitative**:
- User testing: "I knew what to do immediately"
- Stakeholder feedback: "Looks professional"
- Developer handoff: "Spec was crystal clear"
- Design critique: "Follows proven patterns"

---

## References

**Reading**:
- *Don't Make Me Think* by Steve Krug (usability bible)
- *Refactoring UI* by Adam Wathan & Steve Schoger (visual design)
- *Steal Like an Artist* by Austin Kleon (creative process)
- Nielsen Norman Group articles (evidence-based UX)

**Tools**:
- Coolors.co (palette generation with AAA contrast)
- Realtime Colors (preview palettes on UI)
- Color Contrast Analyzer (WCAG validation)
- PageSpeed Insights (Lighthouse audits)

**Inspiration Archives**:
- design-inspirations.md (project-specific)
- design/references/ (screenshots)
- patterns.md (proven pattern library)

---

**Last Updated**: 2025-11-03
**Version**: 1.0.0
**Owner**: Design System Team

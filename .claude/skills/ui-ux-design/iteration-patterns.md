# Design Workflow Iteration Patterns

This guide covers common scenarios for iterating on UI designs during and after the three-phase design workflow (variations → functional → polish).

---

## Scenario 1: Iterate on Specific Component

**Situation**: You've completed the design workflow but want to explore more options for the "upload" screen while keeping other screens unchanged.

**Solution**:

1. **Run design-variations for that screen only**:
   ```bash
   /design-variations aktr-upload upload
   ```
   - This regenerates only the upload screen variants (v1-v5)
   - Other screens remain untouched
   - If existing variants found, choose [b]ackup to preserve current versions

2. **Review and critique new variants**:
   - Open: `http://localhost:3000/mock/aktr-upload/upload/v1`
   - Test all states with `?state=loading`, `?state=error`, etc.
   - Update `specs/NNN-aktr-upload/design/crit.md` with new decisions
   - Mark Keep/Change/Kill for each variant

3. **Re-run design-functional to merge**:
   ```bash
   /design-functional aktr-upload
   ```
   - Merges selected components from new variants
   - Updates functional/ prototype with new upload screen
   - Re-runs cleanup (creates new git tag, deletes variants)

**Notes**:
- Screen parameter works for any screen in screens.yaml
- Can iterate multiple times on same screen
- Each iteration creates a new backup git tag if requested

---

## Scenario 2: Initially Skipped, Now Want Design Workflow

**Situation**: You said "no" to design workflow in `/spec-flow`, but now want to add it.

**Option A: Manual Commands**

Run the design commands manually:

```bash
# Phase 2a: Generate variants
/design-variations aktr-upload

# Review variants, fill crit.md

# Phase 2b: Merge to functional
/design-functional aktr-upload

# Review functional prototype

# Phase 2c: Apply branding and polish
/design-polish aktr-upload
```

**Option B: Re-enable in Spec-Flow**

1. **Enable design workflow in state**:
   ```bash
   yq eval '.design_workflow.enabled = true' -i specs/003-aktr-upload/workflow-state.yaml
   ```

2. **Resume spec-flow**:
   ```bash
   /spec-flow continue
   ```
   - Detects design workflow was previously skipped
   - Shows re-enable prompt: "⚠️ Design workflow was previously skipped for this feature."
   - Runs design phases if you select "yes"

**When to use each option**:
- Use **Option A** if you're late in the workflow (already implementing)
- Use **Option B** if you're early (just finished /tasks or /analyze)

---

## Scenario 3: Refine After Initial Exploration

**Situation**: You created 3 variants, but want to try 2 more approaches for comparison.

**Solution**:

1. **Backup existing variants**:
   ```bash
   git tag design-variants-backup-aktr-upload-$(date +%Y%m%d-%H%M%S)
   ```

2. **Re-run design-variations with backup option**:
   ```bash
   /design-variations aktr-upload
   ```
   - When prompted about existing variants, select **[b] Backup**
   - Creates another git tag before overwriting
   - Generates new v1-v5 variants

3. **Compare with previous versions**:
   ```bash
   # List all backup tags
   git tag -l "design-variants-*aktr-upload*"

   # Restore specific variant from previous iteration
   TAG_NAME="design-variants-backup-aktr-upload-20250119-143022"
   git show $TAG_NAME:apps/web/mock/aktr-upload/upload/v2/page.tsx
   ```

4. **Merge best ideas from both iterations**:
   - Review current variants + restored previous variants
   - Note best components from each in crit.md
   - Merge into functional/ prototype

**Variant Naming**:
- Current iteration: v1, v2, v3, v4, v5
- Previous iterations: Accessible via git tags
- Functional merge: functional/page.tsx

---

## Scenario 4: A/B Test Alternative Design

**Situation**: You shipped functional/ but want to test a completely different approach as an alternative.

**Solution**:

1. **Create alternative branch**:
   ```bash
   git checkout -b feature/aktr-upload-alternative
   ```

2. **Re-run design-variations for specific screen**:
   ```bash
   /design-variations aktr-upload upload
   ```
   - Try completely different layout approaches
   - Example: If control uses modal, test inline expansion
   - Generate 3-5 radically different variants

3. **Merge into alternative functional prototype**:
   ```bash
   # Manually create functional-alt/ instead of functional/
   mkdir -p apps/web/mock/aktr-upload/upload/functional-alt

   # Copy and merge selected components
   # (design-functional will use functional/ by default)
   ```

4. **Set up A/B test**:
   ```tsx
   // In apps/web/mock/aktr-upload/upload/page.tsx
   const variant = useSearchParams()?.get('variant') || 'control';

   if (variant === 'control') {
     return <FunctionalControl />; // Original functional/
   } else {
     return <FunctionalAlt />; // Alternative design
   }
   ```

5. **Compare metrics**:
   - Track HEART metrics for each variant
   - Compare: Task success, error rate, time-to-complete, satisfaction
   - Document results in specs/NNN-aktr-upload/design/heart-metrics.md

**Notes**:
- Use different branches for each alternative
- Merge winner back to main after validation
- Delete losing alternatives to avoid clutter

---

## Scenario 5: Iterate on Specific State

**Situation**: The "error" state needs more exploration, but other states are good.

**Solution**:

Since variants are state-aware (use `?state=` parameter), you can:

1. **Generate new variants focused on error handling**:
   ```bash
   /design-variations aktr-upload upload
   ```

2. **In variant generation, focus hypothesis on error state**:
   - v1: Inline alert (current approach)
   - v2: Toast notification
   - v3: Modal with recovery actions
   - v4: Persistent banner with retry button
   - v5: Graceful degradation (show partial results)

3. **Test only error state during review**:
   ```
   http://localhost:3000/mock/aktr-upload/upload/v1?state=error
   http://localhost:3000/mock/aktr-upload/upload/v2?state=error
   http://localhost:3000/mock/aktr-upload/upload/v3?state=error
   ```

4. **Merge best error handling into functional**:
   - Keep default/loading/success states from previous iteration
   - Only update error state component
   - Document in crit.md: "Only error state changed in this iteration"

---

## Tips for Effective Iteration

### When to Iterate

**Good reasons to iterate**:
- User testing revealed confusion (>2 users asked "what do I do?")
- Hypothesis failed (A/B test showed worse metrics)
- Accessibility issues found (Lighthouse score <95)
- Design system violations detected (hardcoded colors, custom components)
- New requirement emerged mid-development

**Bad reasons to iterate**:
- Personal preference without data
- Boredom with current design
- "It could be better" (without specific goal)
- Team member disagrees (without user data)

### Keep vs. Iterate Decision

Use this checklist to decide:

- [ ] **Jobs Test**: Can 5 users complete primary action in <10 seconds without asking questions?
- [ ] **Accessibility**: Lighthouse score ≥95?
- [ ] **Design System**: Zero hardcoded colors, spacing, or fonts?
- [ ] **Performance**: Lighthouse performance ≥90?
- [ ] **HEART**: Meeting targets for Happiness, Engagement, Adoption, Retention, Task success?

If all ✓ → **Keep current design**

If any ✗ → **Iterate with specific hypothesis**

### Iteration Tracking

Document each iteration in `specs/NNN-slug/design/iteration-log.md`:

```markdown
## Iteration 1 (2025-01-19)

**Trigger**: User testing showed 3/5 users confused by upload button placement
**Hypothesis**: Moving CTA above fold will reduce confusion
**Variants generated**: 3 (top-aligned, sticky, inline)
**Winner**: v2 (sticky CTA)
**Outcome**: 5/5 users completed task <8 seconds

## Iteration 2 (2025-01-22)

**Trigger**: Lighthouse accessibility score 87 (target: ≥95)
**Hypothesis**: Adding ARIA labels + focus indicators will improve score
**Changes**: aria-label on file input, ring-2 focus states
**Outcome**: Score improved to 98 ✓
```

---

## Recovery Patterns

### Restore Deleted Variants

If you deleted variants but need to review them:

```bash
# Find the cleanup tag
git tag -l "design-variants-*aktr-upload*"

# Restore all variants from tag
TAG_NAME="design-variants-aktr-upload-20250119-143022"
git checkout $TAG_NAME -- apps/web/mock/aktr-upload/

# Or restore single variant
git checkout $TAG_NAME -- apps/web/mock/aktr-upload/upload/v2/
```

### Undo Functional Merge

If you merged the wrong variants into functional:

```bash
# Find the pre-functional git tag
git tag -l "design-variants-*aktr-upload*"

# Restore variants
TAG_NAME="design-variants-aktr-upload-20250119-143022"
git checkout $TAG_NAME -- apps/web/mock/aktr-upload/

# Re-fill crit.md with correct decisions
# Re-run /design-functional aktr-upload
```

---

## Reference

**Related files**:
- [SKILL.md](SKILL.md) - Auto-learning system for design workflow
- [reference.md](reference.md) - Jobs principles, design system compliance
- [examples.md](examples.md) - Good vs bad design workflow examples

**Commands**:
- `/design-variations $SLUG [$SCREEN]` - Generate variants (optional screen targeting)
- `/design-functional $SLUG` - Merge variants to functional prototype
- `/design-polish $SLUG` - Apply brand tokens and optimize
- `/spec-flow continue` - Resume after human checkpoints

**State files**:
- `specs/NNN-slug/workflow-state.yaml` - Design workflow progress tracking
- `specs/NNN-slug/design/crit.md` - Variant critique decisions
- `apps/web/mock/$SLUG/` - Variant prototypes

---

_This guide will be expanded with real iteration examples as features flow through the design workflow._

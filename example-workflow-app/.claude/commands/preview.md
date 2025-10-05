---
description: Manual UI/UX testing on local dev server before shipping
---

Preview feature: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Detect feature  Start dev server  Show checklist  Capture notes  Update NOTES  Suggest next

**Auto-suggest:**
- If issues found  `/debug`
- If tests pass  `/phase-1-ship`

## DETECT FEATURE

```bash
# Auto-detect from current branch
CURRENT_BRANCH=$(git branch --show-current)
FEATURE=$(echo "$CURRENT_BRANCH" | sed 's/^[0-9]*-//')

# Or use argument
if [ -n "$ARGUMENTS" ]; then
  FEATURE="$ARGUMENTS"
fi

# Find spec directory
SPEC_DIR=$(find specs/ -maxdepth 1 -name "*${FEATURE}*" -type d | head -n 1)
```

## LOAD TESTING CHECKLIST

Read from `specs/NNN-feature/spec.md`:
- Extract user scenarios (Given/When/Then)
- Extract acceptance criteria
- Extract visual requirements (from visuals/README.md if exists)

## START DEV SERVER

### Detect Target

```bash
# Check which apps are affected
grep -l "$FEATURE" apps/marketing/**/*.{ts,tsx} && APPS="marketing"
grep -l "$FEATURE" apps/app/**/*.{ts,tsx} && APPS="$APPS app"
```

### Launch Server

**Marketing** (port 3000):
```bash
cd apps/marketing
npx kill-port 3000
pnpm install
pnpm dev
```

**App** (port 3001):
```bash
cd apps/app
npx kill-port 3001
pnpm install
pnpm dev
```

**Both**:
```bash
# Start both in background (parallel)
cd apps/marketing && npx kill-port 3000 && pnpm dev &
cd apps/app && npx kill-port 3001 && pnpm dev &
```

## DISPLAY TESTING CHECKLIST

Create checklist from spec.md:

```markdown
## Manual Testing Checklist

**Feature**: [NNN-feature-name]
**Dev Server**: [URLs]

### User Scenarios

From spec.md, test each scenario:

#### Scenario 1: [Name]
- [ ] **Given**: [precondition]
- [ ] **When**: [action]
- [ ] **Then**: [expected result]

#### Scenario 2: [Name]
- [ ] **Given**: [precondition]
- [ ] **When**: [action]
- [ ] **Then**: [expected result]

### Visual Validation (if applicable)

From visuals/README.md:

- [ ] Layout matches design (spacing, alignment)
- [ ] Colors match spec (primary, secondary, accents)
- [ ] Typography correct (font families, sizes, weights)
- [ ] Responsive design works (mobile, tablet, desktop)
- [ ] Interactions smooth (hover, focus, transitions)
- [ ] Accessibility (keyboard nav, screen reader, contrast)

### Browser Testing

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile (iOS Safari, Android Chrome)

### Performance

- [ ] No console errors
- [ ] No console warnings
- [ ] Fast initial load (<3s)
- [ ] Smooth interactions (no janks)
- [ ] Images load properly (no 404s)
```

## OPTIONAL: PLAYWRIGHT UI MODE

```bash
cd apps/app  # or apps/marketing
pnpm exec playwright test --ui

# Launch specific test file
pnpm exec playwright test [test-file].spec.ts --ui
```

**Use for**:
- Interactive debugging
- Visual regression testing
- Recording new tests

## CAPTURE NOTES

Prompt user:
```
Testing checklist displayed above.

Test each scenario in your browser at:
- Marketing: http://localhost:3000
- App: http://localhost:3001

Did you find any issues? (yes/no/skip)
```

**If yes**:
```
Please describe the issues found:
[User input]

Capturing to specs/$FEATURE/artifacts/preview-notes.md...

Next: /debug to fix issues, then re-run /preview
```

**If no**:
```
 All tests passed!

Next: /phase-1-ship to deploy to staging
```

**If skip**:
```
  Preview skipped. Proceeding to ship without manual validation.

Note: This may result in UI/UX bugs on staging.

Next: /phase-1-ship (at your own risk)
```

## UPDATE NOTES.MD

```bash
cat >> specs/$FEATURE/NOTES.md << 'EOF'

## Checkpoints
-  Phase 6 (Preview): [date]
  - Manual testing: [passed/skipped/issues found]
  - Issues: [N] OR None
  - Browser coverage: [browsers tested]

## Context Budget
- Phase 6: N tokens

## Last Updated
[ISO timestamp]
EOF
```

## CREATE PREVIEW NOTES (if issues found)

```bash
mkdir -p specs/$FEATURE/artifacts

cat > specs/$FEATURE/artifacts/preview-notes.md << 'EOF'
# Preview Testing Notes

**Date**: $(date +%Y-%m-%d\ %H:%M)
**Feature**: $FEATURE

## Issues Found

### Issue 1: [Title]
- **Severity**: [Critical/High/Medium/Low]
- **Location**: [URL or component]
- **Description**: [What's wrong]
- **Expected**: [What should happen]
- **Actual**: [What actually happens]
- **Browser**: [Which browsers affected]

[Repeat for each issue]

## Browser Coverage

- Chrome: [//]
- Firefox: [//]
- Safari: [//]
- Edge: [//]
- Mobile: [//]

## Screenshots

[If user provides screenshots, reference them here]

## Next Steps

- [ ] Fix Issue 1 via /debug
- [ ] Fix Issue 2 via /debug
- [ ] Re-run /preview to verify fixes
EOF
```

## GIT COMMIT (if notes created)

```bash
git add specs/$FEATURE/NOTES.md specs/$FEATURE/artifacts/preview-notes.md
git commit -m "design:preview: manual UI/UX testing complete

Tested scenarios: [N]
Issues found: [N] OR None
Browser coverage: [browsers]

 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## RETURN

Brief summary:
```
Preview testing for: $FEATURE

Dev server:
- Marketing: http://localhost:3000 (if applicable)
- App: http://localhost:3001 (if applicable)

Testing results:
- Scenarios tested: N
- Issues found: N OR 0
- Browser coverage: [browsers]

Next:
- Issues found  /debug to fix, then re-run /preview
- All passed  /phase-1-ship to deploy to staging
```



---
description: Quick implementation for small changes (skip spec/plan/tasks - KISS principle)
---

Implement small features, bug fixes, or refactors without full workflow.

## MENTAL MODEL

**Use when**: Bug fixes, small enhancements, refactors, <100 LOC changes, single-file updates

**Skip**: Full spec/plan/tasks workflow for speed

**Keep**: Tests, quality standards, commit hygiene

**Workflow**: Describe → Implement → Test → Commit (Goal: <30 minutes)

**Pattern**: Direct implementation with minimal ceremony

## WHEN TO USE /quick

✅ **Good candidates:**
- Bug fixes (UI glitches, logic errors)
- Small refactors (rename variable, extract function)
- Internal improvements (logging, error messages)
- Documentation updates
- Style/formatting fixes
- Config tweaks

❌ **Do NOT use for:**
- New features with UI components (use `/feature`)
- Database schema changes (use `/feature`)
- API contract changes (use `/feature`)
- Security-sensitive code (use `/feature`)
- Changes affecting >5 files (use `/feature`)
- Multi-step features requiring coordination

## PARSE ARGUMENTS

**Get description:**

If `$ARGUMENTS` is empty, show usage:
```
Usage: /quick "description"

Examples:
  /quick "Fix login button alignment on mobile"
  /quick "Add email validation to signup form"
  /quick "Refactor user service to use async/await"
  /quick "Update README with new API endpoint"

Guidelines:
  • Keep changes small (<100 LOC)
  • Single concern/purpose
  • No breaking changes
  • Tests required if logic changes
```

Otherwise, set `DESCRIPTION = $ARGUMENTS`

## CHECK IF UI CHANGE (Load Style Guide)

**Detect UI/design-related changes and load style guide:**

```bash
# Check if description mentions UI-related terms
if [[ "$DESCRIPTION" =~ (UI|component|button|form|card|layout|design|style|CSS|Tailwind|color|spacing|font|typography) ]]; then
  STYLE_GUIDE_MODE=true

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 UI CHANGE DETECTED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Loading style guide for consistency enforcement..."
  echo ""

  # Required files
  STYLE_GUIDE="docs/project/style-guide.md"
  TOKENS="design/systems/tokens.json"
  UI_INVENTORY="design/systems/ui-inventory.md"

  # Validate style guide exists
  if [ ! -f "$STYLE_GUIDE" ]; then
    echo "❌ Style guide not found: $STYLE_GUIDE"
    echo ""
    echo "Run /init-project first to generate project documentation."
    echo "Or create style-guide.md manually."
    echo ""
    exit 1
  fi

  # Validate tokens exist (non-blocking)
  if [ ! -f "$TOKENS" ]; then
    echo "⚠️  Design tokens not found: $TOKENS"
    echo "   Using style guide rules without token values."
    echo ""
  fi

  # UI inventory is optional
  if [ ! -f "$UI_INVENTORY" ]; then
    echo "ℹ️  UI inventory not found (optional): $UI_INVENTORY"
    echo ""
  fi

  echo "✅ Style guide loaded"
  echo ""
else
  STYLE_GUIDE_MODE=false
  echo "ℹ️  Non-UI change detected - skipping style guide"
  echo ""
fi
```

## CREATE LIGHTWEIGHT BRANCH

**Generate simple branch name:**

```bash
# Slugify description
SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-50)
BRANCH="quick/$SLUG"

# Check if branch exists
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "⚠️  Branch already exists: $BRANCH"
  echo "Checking out existing branch..."
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
  echo "✅ Created branch: $BRANCH"
fi

echo ""
```

## IMPLEMENT DIRECTLY (NO SPEC)

**Use `/route-agent` to delegate implementation:**

Determine agent based on description:
- Backend/API changes → `backend-dev`
- Frontend/UI changes → `frontend-shipper`
- Test-only changes → `qa-test`
- Documentation → `general-purpose` (use Task tool directly)

**Prompt for agent:**

```
You are implementing a quick change (no spec required).

## Description
{DESCRIPTION}

{IF STYLE_GUIDE_MODE=true, INCLUDE:}

## Style Guide Context (UI CHANGE)

Read and follow ALL rules from: docs/project/style-guide.md

**Core 9 Rules** (always enforce):
1. Text line length: 50-75 chars (600-700px max-width)
2. Use bullet points with icons when listing
3. 8pt grid spacing (all values divisible by 4/8)
4. Layout rules: baseline value, double spacing between groups
5. Letter-spacing: Display -1px, Body 0px, CTAs +1px
6. Font superfamilies (matching character sizes)
7. OKLCH colors (never hex)
8. Subtle design elements (gradients <20% opacity, soft shadows)
9. Squint test hierarchy (CTAs/headlines must stand out)

**Context-Aware Token Mapping:**
- CTAs/interactive → bg-brand-primary
- Headings/structure → text-neutral-900
- Body text → text-neutral-700
- Feedback → semantic-success/error/warning/info
- Backgrounds → neutral-50/100

**Component Strategy:**
1. Check ui-inventory.md first (if exists)
2. Use shadcn/ui components (don't create custom)
3. Compose primitives (don't build from scratch)
4. Follow lightweight guidelines in style guide Section 6

**Validation Checklist:**
- [ ] All colors from tokens.json (no hex/rgb/hsl)
- [ ] All spacing on 8pt grid (no arbitrary [Npx])
- [ ] Components from ui-inventory.md (no custom primitives)
- [ ] Shadows for depth (borders only for dividers)
- [ ] Typography hierarchy (2:1 ratio, correct letter-spacing)
- [ ] Text line length 50-75 chars (max-w-[700px])
- [ ] Keyboard navigation (focus:ring-2)
- [ ] WCAG AA contrast (4.5:1 minimum)

{END IF}

## Implementation Rules
1. **KISS Principle**: Make minimal changes to achieve the goal
2. **Follow Existing Patterns**: Match surrounding code style and architecture
3. **Add/Update Tests**: If logic changes, update relevant tests
4. **Update Comments/Docstrings**: Keep documentation accurate
5. **No Breaking Changes**: Maintain backward compatibility
6. **Single Concern**: Fix/implement only what's described

## Process
1. Identify files to modify
2. Make changes following existing patterns
3. Run relevant tests
4. Verify changes work as expected

## Output Format
After implementation, provide:
- **Files changed**: List of modified files
- **Summary**: 2-3 sentences describing what was done
- **Tests**: Status of test runs (pass/fail)
{IF STYLE_GUIDE_MODE: - **Style guide adherence**: Which rules followed, any violations}

## Constraints
- No new dependencies unless absolutely necessary
- No architectural changes
- Keep diff small and focused
{IF STYLE_GUIDE_MODE: - Follow style guide rules (non-negotiable)}
```

Execute agent delegation via `/route-agent` with appropriate agent selection.

## VERIFY CHANGES

**Run tests if applicable:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running tests..."
echo ""

# Detect test framework and run tests
TEST_FAILED=0

# Backend tests (Python)
if [ -d "api" ] || [ -d "backend" ] || [ -f "pytest.ini" ]; then
  if command -v pytest &> /dev/null; then
    echo "Running pytest..."
    pytest tests/ -v --tb=short || TEST_FAILED=1
  fi
fi

# Frontend tests (Node)
if [ -d "apps" ] || [ -d "frontend" ] || [ -f "package.json" ]; then
  if command -v npm &> /dev/null; then
    echo "Running npm tests..."
    npm test -- --run || TEST_FAILED=1
  fi
fi

if [ $TEST_FAILED -eq 1 ]; then
  echo ""
  echo "⚠️  Some tests failed - review output above"
  echo "Fix tests before committing, or skip if intentional (document why)"
fi

echo ""
```

## VALIDATE STYLE GUIDE (UI Changes Only)

**Run style guide validation if UI change:**

```bash
if [ "$STYLE_GUIDE_MODE" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Validating style guide compliance..."
  echo ""

  # Basic validation checks (automated)
  VALIDATION_WARNINGS=0

  # Check for hardcoded colors (hex, rgb, hsl)
  echo "Checking for hardcoded colors..."
  HARDCODED_COLORS=$(grep -rE "#[0-9a-fA-F]{3,6}|rgb\(|hsl\(" apps/ --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | grep -v "node_modules\|.next\|oklch" | wc -l)

  if [ "$HARDCODED_COLORS" -gt 0 ]; then
    echo "⚠️  Found $HARDCODED_COLORS hardcoded color(s)"
    echo "   Replace with design tokens from tokens.json"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
  else
    echo "✅ No hardcoded colors detected"
  fi

  # Check for arbitrary spacing (not on 8pt grid)
  echo "Checking spacing (8pt grid)..."
  ARBITRARY_SPACING=$(grep -rE "\[[0-9]+px\]" apps/ --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | grep -v "node_modules\|.next\|max-w-\[700px\]\|max-w-\[600px\]" | wc -l)

  if [ "$ARBITRARY_SPACING" -gt 0 ]; then
    echo "⚠️  Found $ARBITRARY_SPACING arbitrary spacing value(s)"
    echo "   Use 8pt grid system (space-1, space-2, space-4, etc.)"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
  else
    echo "✅ Spacing on 8pt grid"
  fi

  # Check for focus states on interactive elements
  echo "Checking focus states..."
  MISSING_FOCUS=$(grep -rE "onClick|onPress|button|Button" apps/ --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v "focus:" | grep -v "node_modules" | wc -l)

  if [ "$MISSING_FOCUS" -gt 5 ]; then
    echo "⚠️  Some interactive elements may be missing focus states"
    echo "   Add focus:ring-2 focus:ring-brand-primary to buttons"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
  else
    echo "✅ Focus states present"
  fi

  echo ""

  if [ $VALIDATION_WARNINGS -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  $VALIDATION_WARNINGS style guide warning(s)"
    echo ""
    echo "Warnings are non-blocking but should be addressed."
    echo "Review style guide: docs/project/style-guide.md"
    echo ""
  else
    echo "✅ All style guide checks passed"
    echo ""
  fi
fi
```

## COMMIT CHANGES

**Stage and commit:**

```bash
echo "Creating commit..."
echo ""

# Stage all changes
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
  echo "⚠️  No changes to commit"
  exit 0
fi

# Generate commit message
COMMIT_MSG="quick: ${DESCRIPTION}

Implemented via /quick command.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create commit
git commit -m "$COMMIT_MSG"

echo "✅ Changes committed"
echo ""
```

## SHOW SUMMARY

**Display completion info:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Quick change complete!"
echo ""
echo "Branch: $BRANCH"
echo "Files changed: $(git diff --name-only HEAD~1 | wc -l)"
echo "Commit: $(git rev-parse --short HEAD)"
echo ""
echo "Changes:"
git diff --stat HEAD~1
echo ""
echo "Next steps:"
echo "  • Review changes: git show"
echo "  • Run app locally to verify: npm run dev / pytest"
echo "  • Merge to main: git checkout main && git merge $BRANCH"
echo "  • Push (if remote): git push origin main"
echo "  • Delete branch: git branch -d $BRANCH"
echo ""
```

## LIMITATIONS & GUARDRAILS

**This command is NOT suitable for:**

1. **Multi-file features** - Use `/feature` for coordinated changes across many files
2. **Database migrations** - Schema changes need full spec/plan/review
3. **API contract changes** - Breaking changes need stakeholder review
4. **Security features** - Auth, permissions, crypto need thorough review
5. **Performance-critical code** - Needs benchmarking in `/optimize` phase
6. **UI redesigns** - Visual changes need design review via `/design-variations`

**If you're unsure, use `/feature` instead.** The full workflow ensures quality gates for complex changes.

## COMPARISON WITH /feature

| Aspect | /quick | /feature |
|--------|--------|-------|
| **Duration** | <30 min | 2-8 hours |
| **Artifacts** | Commit only | spec.md, plan.md, tasks.md, reports |
| **Review** | Self-review | Multi-phase review (/analyze, /optimize) |
| **Scope** | <100 LOC, <5 files | Unlimited |
| **Planning** | None | Full spec/plan/tasks |
| **Testing** | Existing tests | New tests required |
| **Deployment** | Manual | Automated (staging → prod) |

**Rule of thumb**: If you can implement it in one sitting without pausing to think about architecture, use `/quick`. Otherwise, use `/feature`.

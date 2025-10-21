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

## Constraints
- No new dependencies unless absolutely necessary
- No architectural changes
- Keep diff small and focused
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

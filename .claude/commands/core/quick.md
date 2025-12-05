---
name: quick
description: Implement small bug fixes and features (<100 LOC) without full workflow. Use for single-file changes, bug fixes, refactors, and minor enhancements that can be completed in under 30 minutes.
argument-hint: <description>
allowed-tools:
  [
    Read,
    Grep,
    Glob,
    Bash(git *),
    Bash(pytest *),
    Bash(npm *),
    Bash(npx *),
    Task,
    AskUserQuestion,
  ]
---

<objective>
Execute quick implementations for small changes (bug fixes, refactors, minor enhancements) bypassing the full spec/plan/tasks workflow. Maintain quality standards (tests, commits) while prioritizing speed and simplicity. Target completion time: <30 minutes.
</objective>

<context>
Current git status:
!`git status --short`

Current branch:
!`git branch --show-current`

Recent commits (last 3):
!`git log -3 --oneline`
</context>

<when_to_use>

## ✅ Good Candidates (Use /quick)

- **Bug fixes**: UI glitches, logic errors, null checks
- **Small refactors**: Rename variables, extract functions, simplify logic
- **Internal improvements**: Logging, error messages, constants
- **Documentation**: README updates, code comments, docstrings
- **Style/formatting**: Whitespace, naming conventions, linting fixes
- **Config tweaks**: Environment variables, build settings, tool configs

**Characteristics**: <100 LOC, <5 files, single concern, no breaking changes, can implement in one sitting

## ❌ Do NOT Use (Use /feature Instead)

- **New features with UI components** - Needs design review and mockup approval
- **Database schema changes** - Requires migration planning and zero-downtime strategy
- **API contract changes** - Breaking changes need stakeholder review
- **Security-sensitive code** - Auth, permissions, crypto need thorough review
- **Changes affecting >5 files** - Coordination across modules needs planning
- **Multi-step features** - Complex workflows need task breakdown

**Rule of thumb**: If you need to pause and think about architecture, use `/feature`.
</when_to_use>

<process>
## 1. Validate Scope and Get Description

**If $ARGUMENTS is empty:**

- Use AskUserQuestion to request:
  - **Question**: "What change would you like to implement?"
  - **Options**: Provide examples (bug fix, refactor, doc update, config change)
  - **Header**: "Quick Change"

**Store description in DESCRIPTION variable.**

**Verify scope is appropriate:**

- Check if description mentions database, schema, migration, API contract, auth, security
- If YES: Recommend using `/feature` instead and explain why
- If NO: Proceed with implementation

## 2. Detect UI Changes and Load Style Guide (Conditional)

**Check if DESCRIPTION contains UI-related keywords:**

- Keywords: UI, component, button, form, card, layout, design, style, CSS, Tailwind, color, spacing, font, typography, gradient, shadow, border

**If UI change detected:**

1. Read `docs/project/style-guide.md` (if exists)
2. Read `design/systems/tokens.json` (if exists)
3. Note: "UI change detected - enforcing style guide compliance"
4. Set STYLE_GUIDE_MODE = true

**If files not found:**

- Warn: "Style guide not found. Consider running `/init-project --with-design` for UI consistency rules."
- Continue without style guide (note this in output)

**If non-UI change:**

- Set STYLE_GUIDE_MODE = false
- Skip style guide loading

## 3. Create Lightweight Branch

**Generate branch name:**

- Slugify DESCRIPTION to create branch name: `quick/[slug]`
- Use only lowercase, numbers, hyphens
- Truncate to 50 characters

**Create or checkout branch:**

- Run: `git checkout -b quick/[slug]`
- If branch already exists: `git checkout quick/[slug]` and note "Using existing branch"

## 4. Implement Changes

**Determine implementation agent using detection algorithm:**

```javascript
function detectAgent(description, modifiedFiles = []) {
  const desc = description.toLowerCase();
  const files = modifiedFiles.map(f => f.toLowerCase());

  // 1. Check file extensions first (highest confidence)
  const filePatterns = {
    backend: ['.py', '.go', '.rs', '.java', '.rb', '.php'],
    frontend: ['.tsx', '.jsx', '.vue', '.svelte', '.css', '.scss'],
    test: ['test.', 'spec.', '_test.', '.test.', '.spec.']
  };

  for (const file of files) {
    if (filePatterns.test.some(p => file.includes(p))) return 'qa-test';
    if (filePatterns.frontend.some(p => file.endsWith(p))) return 'frontend-dev';
    if (filePatterns.backend.some(p => file.endsWith(p))) return 'backend-dev';
  }

  // 2. Check keywords in description (medium confidence)
  const keywords = {
    'qa-test': ['test', 'spec', 'coverage', 'fixture', 'mock', 'assert'],
    'frontend-dev': ['component', 'ui', 'button', 'form', 'style', 'css',
                     'react', 'vue', 'svelte', 'tailwind', 'layout', 'page'],
    'backend-dev': ['api', 'endpoint', 'model', 'service', 'database', 'query',
                    'migration', 'route', 'controller', 'repository', 'fastapi']
  };

  for (const [agent, words] of Object.entries(keywords)) {
    if (words.some(w => desc.includes(w))) return agent;
  }

  // 3. Check for documentation-only (no agent needed)
  const docKeywords = ['readme', 'documentation', 'comment', 'docstring', 'changelog'];
  if (docKeywords.some(w => desc.includes(w))) return null; // Direct implementation

  // 4. Fallback: Ask user
  return 'ask_user';
}
```

**Agent routing rules:**

| Detection | Agent | Reason |
|-----------|-------|--------|
| `.py`, `.go`, `.rs`, `.java`, `.rb` files | `backend-dev` | Backend language detected |
| `.tsx`, `.jsx`, `.vue`, `.svelte` files | `frontend-dev` | Frontend framework detected |
| `test.`, `spec.`, `_test.` in filename | `qa-test` | Test file pattern detected |
| Keywords: api, endpoint, model, service | `backend-dev` | Backend concept mentioned |
| Keywords: component, ui, button, style | `frontend-dev` | UI concept mentioned |
| Keywords: test, coverage, mock, assert | `qa-test` | Testing concept mentioned |
| Keywords: readme, documentation, comment | None | Direct implementation |
| No match | Ask user | Ambiguous - clarify before proceeding |

**If agent detection returns 'ask_user':**

Use AskUserQuestion:
```
Question: "What type of change is this?"
Header: "Domain"
Options:
  - Backend (API, database, services)
  - Frontend (UI, components, styles)
  - Tests (test coverage, specs)
  - Documentation (README, comments)
```

**Agent prompt format:**

```
Implement quick change without full workflow (no spec required).

## Description
{DESCRIPTION}

{IF STYLE_GUIDE_MODE = true:}
## Style Guide Requirements (UI CHANGE)

Read and enforce ALL rules from docs/project/style-guide.md:

**Core 9 Rules** (non-negotiable):
1. Text line length: 50-75 chars (max-w-[600px] or max-w-[700px])
2. Use bullet points with icons for lists
3. 8pt grid spacing (all values divisible by 4/8 - no arbitrary px values)
4. Layout spacing: baseline value + double between groups
5. Letter-spacing: Display -1px, Body 0px, CTAs +1px
6. Font superfamilies (matching character sizes)
7. OKLCH colors only (never hex/rgb/hsl)
8. Subtle design (gradients <20% opacity, soft shadows)
9. Squint test hierarchy (CTAs and headlines must stand out)

**Token Usage:**
- CTAs/interactive → bg-brand-primary
- Headings → text-neutral-900
- Body text → text-neutral-700
- Feedback → semantic-success/error/warning/info
- Backgrounds → neutral-50/100

**Component Strategy:**
1. Check design/systems/ui-inventory.md first (reuse existing)
2. Use shadcn/ui components (no custom primitives)
3. Compose from existing patterns

**Validation Checklist:**
- [ ] All colors from tokens.json (no hardcoded hex/rgb/hsl)
- [ ] All spacing on 8pt grid (space-4, space-8, etc.)
- [ ] Components from ui-inventory.md (no new custom components)
- [ ] Shadows for depth (avoid borders except dividers)
- [ ] Typography hierarchy with correct letter-spacing
- [ ] Text line length 50-75 chars
- [ ] Keyboard navigation (focus:ring-2)
- [ ] WCAG AA contrast (4.5:1 minimum)

{END IF}

## Implementation Rules
1. **KISS Principle**: Minimal changes to achieve goal
2. **Follow Existing Patterns**: Match surrounding code style
3. **Add/Update Tests**: If logic changes, update tests
4. **No Breaking Changes**: Maintain backward compatibility
5. **Single Concern**: Only implement what's described
6. **Quality Standards**: Maintain existing code quality

## Process
1. Identify files to modify (read existing code first)
2. Make targeted changes following existing patterns
3. Run relevant tests to verify changes
4. Ensure no regressions introduced

## Output Required
After implementation, provide:
- **Files changed**: List of modified files with line counts
- **Summary**: 2-3 sentences describing changes
- **Test results**: Pass/fail status with command output
{IF STYLE_GUIDE_MODE: - **Style guide compliance**: Rules followed, any violations}

## Constraints
- No new dependencies unless absolutely necessary
- No architectural changes
- Keep diff small and focused (<100 LOC)
{IF STYLE_GUIDE_MODE: - Style guide rules are non-negotiable}
```

**Execute agent delegation** via Task tool with appropriate subagent_type.

## 5. Run Tests (If Applicable)

**Detect test framework using project indicators:**

```javascript
function detectTestFramework(projectRoot) {
  // Python
  if (exists('pytest.ini') || exists('conftest.py') || exists('pyproject.toml')) {
    return { framework: 'pytest', command: 'pytest -v --tb=short' };
  }

  // Node (check package.json for specific runner)
  if (exists('package.json')) {
    const pkg = readJSON('package.json');
    if (pkg.devDependencies?.vitest || pkg.dependencies?.vitest) {
      return { framework: 'vitest', command: 'npm test -- --run' };
    }
    if (pkg.devDependencies?.jest || pkg.dependencies?.jest) {
      return { framework: 'jest', command: 'npm test' };
    }
    if (pkg.scripts?.test) {
      return { framework: 'npm', command: 'npm test' };
    }
  }

  // Go
  if (exists('go.mod')) {
    return { framework: 'go', command: 'go test ./... -v' };
  }

  // Rust
  if (exists('Cargo.toml')) {
    return { framework: 'cargo', command: 'cargo test' };
  }

  // Java (Maven)
  if (exists('pom.xml')) {
    return { framework: 'maven', command: 'mvn test -B' };
  }

  // Java/Kotlin (Gradle)
  if (exists('build.gradle') || exists('build.gradle.kts')) {
    return { framework: 'gradle', command: 'gradle test' };
  }

  // Ruby (RSpec)
  if (exists('Gemfile') && readFile('Gemfile').includes('rspec')) {
    return { framework: 'rspec', command: 'bundle exec rspec' };
  }

  // Ruby (Minitest)
  if (exists('Gemfile') && exists('test/')) {
    return { framework: 'minitest', command: 'bundle exec rake test' };
  }

  return { framework: null, command: null };
}
```

**Test framework reference:**

| Indicator | Framework | Command |
|-----------|-----------|---------|
| `pytest.ini`, `conftest.py` | pytest (Python) | `pytest -v --tb=short` |
| `package.json` + vitest | Vitest (Node) | `npm test -- --run` |
| `package.json` + jest | Jest (Node) | `npm test` |
| `go.mod` | Go testing | `go test ./... -v` |
| `Cargo.toml` | Cargo (Rust) | `cargo test` |
| `pom.xml` | Maven (Java) | `mvn test -B` |
| `build.gradle` | Gradle (Java/Kotlin) | `gradle test` |
| `Gemfile` + rspec | RSpec (Ruby) | `bundle exec rspec` |
| `Gemfile` + test/ | Minitest (Ruby) | `bundle exec rake test` |
| None detected | Skip tests | Warn user |

**Execute test command based on detected framework.**

**Handle test failures:**

- If tests fail: Display output, ask user if they want to:
  1. Fix failing tests before committing
  2. Skip tests (document why in commit message)
  3. Abort and investigate failures

**If no test framework detected:**

- Warn: "No test framework detected - consider adding tests"
- Skip test execution (don't fail)

## 6. Validate Style Guide Compliance (UI Changes Only)

**If STYLE_GUIDE_MODE = true:**

Run automated validation checks:

**1. Check for hardcoded colors:**

- Grep for: `#[0-9a-fA-F]{3,6}`, `rgb(`, `hsl(` in modified files
- Exclude: node_modules, .next, build directories
- Exclude: oklch() declarations (these are valid)
- If found: List violations with file:line references

**2. Check for arbitrary spacing:**

- Grep for: `[Npx]` patterns in modified files (e.g., `[17px]`, `[23px]`)
- Exclude: max-w-[600px] and max-w-[700px] (these are allowed for text line length)
- If found: List violations, suggest 8pt grid alternatives

**3. Check for focus states:**

- Grep for: `onClick`, `onPress`, `button`, `Button` without `focus:` in same file
- If many missing: Warn about potential accessibility issues

**Report validation results:**

- ✅ All checks passed
- ⚠️ N warning(s) found (non-blocking but should be addressed)
- List specific violations with remediation steps

## 7. Commit Changes

**Stage all changes:**

- Run: `git add .`

**Check if there are changes to commit:**

- Run: `git diff --staged --quiet`
- If no changes: Display "No changes to commit" and exit
- If changes exist: Proceed with commit

**Generate commit message:**

```
quick: {DESCRIPTION}

Implemented via /quick command.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Create commit:**

- Run: `git commit -m "[commit message]"`
- Display commit SHA and summary

## 8. Show Summary

**Display completion information:**

- Branch name: `quick/[slug]`
- Files changed: Count from `git diff --name-only HEAD~1`
- Commit SHA: Short SHA from `git rev-parse --short HEAD`
- Changes summary: `git diff --stat HEAD~1`

**Next steps:**

```
✅ Quick change complete!

Branch: quick/[slug]
Files changed: N
Commit: [sha]

Next steps:
  • Review changes: git show
  • Run app locally: npm run dev (or pytest)
  • Merge to main: git checkout main && git merge quick/[slug]
  • Push (if remote): git push origin main
  • Delete branch: git branch -d quick/[slug]
```

</process>

<success_criteria>
Quick implementation is complete when:

- Changes implemented in <30 minutes
- All relevant tests pass (or failures documented)
- Changes committed to `quick/[slug]` branch
- Summary displayed with files changed and next steps
- If UI change: Style guide validation results shown
- No breaking changes introduced
- Code follows existing patterns and conventions
- Single concern addressed (no scope creep)
  </success_criteria>

<comparison_table>

## /quick vs /feature

Use this table to decide which command to use:

| Aspect            | /quick                       | /feature                                             |
| ----------------- | ---------------------------- | ---------------------------------------------------- |
| **Duration**      | <30 min                      | 2-8 hours                                            |
| **Scope**         | <100 LOC, <5 files           | Unlimited scope                                      |
| **Planning**      | None                         | Full spec/plan/tasks                                 |
| **Artifacts**     | Commit only                  | spec.md, plan.md, tasks.md, reports                  |
| **Review**        | Self-review                  | Multi-phase (/analyze, /optimize)                    |
| **Testing**       | Run existing tests           | Create new test coverage                             |
| **Deployment**    | Manual merge                 | Automated (staging → prod)                           |
| **Quality gates** | Basic (tests pass)           | Comprehensive (security, performance, accessibility) |
| **Best for**      | Bug fixes, refactors, tweaks | New features, API changes, migrations                |

**Decision rule**: If you can implement it in one sitting without pausing to think about architecture, use `/quick`. If you need to plan, coordinate, or consider impacts, use `/feature`.
</comparison_table>

<examples>
**Example 1: Bug Fix**
```
/quick "Fix login button alignment on mobile - button is cut off on screens <375px width"
```
- Agent identifies CSS issue in login component
- Adds responsive media query or Flexbox fix
- Tests on mobile viewport sizes
- Commits to `quick/fix-login-button-alignment-on-mobile`

**Example 2: Refactor**

```
/quick "Refactor user service to use async/await instead of promises"
```

- Agent converts `.then()` chains to `async/await`
- Updates error handling to use try/catch
- Runs existing tests to verify behavior unchanged
- Commits to `quick/refactor-user-service-to-use-async-await`

**Example 3: Documentation**

```
/quick "Update README with new /quick command usage and examples"
```

- No agent needed (direct implementation)
- Adds section to README with command syntax
- Includes examples and comparison table
- Commits to `quick/update-readme-with-new-quick-command`

**Example 4: UI Change with Style Guide**

```
/quick "Add success message toast after user signup with proper design tokens"
```

- UI change detected → loads style guide
- Agent uses semantic-success color from tokens.json
- Ensures 8pt grid spacing and proper typography
- Validates WCAG AA contrast
- Style guide validation checks pass
- Commits to `quick/add-success-message-toast-after-user-signup`
  </examples>

<error_handling>
**If description is too complex for /quick:**

- Recommend using `/feature` instead
- Explain why (e.g., "Database migrations require full workflow for zero-downtime planning")
- Provide command to start: `/feature "[description]"`

**If tests fail:**

- Display test output with failures highlighted
- Ask user: Fix now, skip with justification, or abort?
- If skip: Require justification in commit message

**If style guide files missing (UI change):**

- Warn user: "Style guide not found - consider running `/init-project --with-design`"
- Continue without style guide enforcement
- Note in summary: "Style guide validation skipped (files not found)"

**If no changes to commit:**

- Display: "No changes detected - verify implementation completed successfully"
- Show `git status` output
- Do not create empty commit

**If branch already exists:**

- Checkout existing branch
- Warn: "Using existing branch quick/[slug] - previous work may exist"
- Show existing commits on branch: `git log main..HEAD --oneline`

**If git not initialized:**

- Error: "Git repository not found - initialize with `git init` first"
- Abort command execution
  </error_handling>

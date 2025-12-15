---
name: quick
description: Implement small bug fixes and features (<100 LOC) without full workflow. Use for single-file changes, bug fixes, refactors, and minor enhancements that can be completed in under 30 minutes.
argument-hint: "<description> [--deep]"
version: 2.1
updated: 2025-12-14
allowed-tools:
  [
    Read,
    Grep,
    Glob,
    Bash(git *),
    Task,
    AskUserQuestion,
    Skill,
  ]
---

<objective>
Execute quick implementations for small changes (bug fixes, refactors, minor enhancements) bypassing the full spec/plan/tasks workflow. Uses Task() isolation for implementation with full Q&A support.

**CRITICAL ARCHITECTURE** (v2.0 - Task() Orchestrator Pattern):

This orchestrator is **lightweight**. You MUST:
1. Parse arguments and validate scope (inline)
2. Create branch (inline)
3. Spawn isolated quick-worker agent via **Task tool**
4. Handle Q&A when agent returns `---NEEDS_INPUT---`
5. Display summary from agent result

**Benefits**: Implementation is isolated, Q&A flows naturally, consistent with /feature and /epic patterns.
</objective>

<context>
Current git status:
!`git status --short`

Current branch:
!`git branch --show-current`

Recent commits (last 3):
!`git log -3 --oneline`

Studio context (multi-agent isolation):
!`bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo ""`

Worktree context:
!`bash .spec-flow/scripts/bash/worktree-context.sh info 2>/dev/null || echo '{"is_worktree": false}'`
</context>

<when_to_use>

## Good Candidates (Use /quick)

- **Bug fixes**: UI glitches, logic errors, null checks
- **Small refactors**: Rename variables, extract functions, simplify logic
- **Internal improvements**: Logging, error messages, constants
- **Documentation**: README updates, code comments, docstrings
- **Style/formatting**: Whitespace, naming conventions, linting fixes
- **Config tweaks**: Environment variables, build settings, tool configs

**Characteristics**: <100 LOC, <5 files, single concern, no breaking changes, can implement in one sitting

## Do NOT Use (Use /feature Instead)

- **New features with UI components** - Needs design review and mockup approval
- **Database schema changes** - Requires migration planning and zero-downtime strategy
- **API contract changes** - Breaking changes need stakeholder review
- **Security-sensitive code** - Auth, permissions, crypto need thorough review
- **Changes affecting >5 files** - Coordination across modules needs planning
- **Multi-step features** - Complex workflows need task breakdown

**Rule of thumb**: If you need to pause and think about architecture, use `/feature`.
</when_to_use>

<planning_depth>
## Deep Mode for Quick Changes (--deep)

**When to use --deep with /quick**:
- Complex refactor that touches architectural patterns
- Bug fix that reveals deeper design issues
- Quick change that might benefit from assumption questioning

**What --deep does for /quick**:
1. Loads ultrathink skill before implementation
2. Applies simplified craftsman checklist:
   - What assumptions am I making about this "quick" fix?
   - Is there a simpler solution?
   - Does this align with codebase patterns?
3. Does NOT generate full craftsman-decision.md (overkill for quick)

**Typical /quick stays fast**:
- No --deep flag → Standard implementation
- Skips assumption inventory
- Skips codebase soul analysis
- Just implements the change

**Example**:
```bash
/quick "fix null check in UserService"           # Standard quick fix
/quick "refactor auth validation" --deep         # Deep thinking for complex refactor
```
</planning_depth>

<studio_mode>
## Studio Mode (Multi-Agent Isolation) (v11.8)

When running in a studio worktree (`worktrees/studio/agent-N/`), the quick workflow automatically:

1. **Detects studio context** - Auto-detected from working directory
2. **Namespaces branches** - `studio/agent-N/quick/fix-button` instead of `quick/fix-button`
3. **Creates PRs for merging** - Studio agents create PRs (like a real dev team)
4. **Prevents git conflicts** - Each agent has isolated branches

**Detection (automatic, no user action needed):**
```bash
STUDIO_AGENT=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo "")
IS_STUDIO_MODE=$([[ -n "$STUDIO_AGENT" ]] && echo "true" || echo "false")
```

**Branch naming in studio mode:**
```bash
# Get namespaced branch (handles studio detection automatically)
BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "quick" "$SLUG" 2>/dev/null)
# Returns: "studio/agent-1/quick/fix-button" in studio mode
# Returns: "quick/fix-button" in normal mode
```
</studio_mode>

<process>

## PHASE 0.5: Worktree Safety Check (v11.8)

**Before any work, verify we're in a safe location.**

Quick changes follow a simpler safety model:
- If in a worktree → proceed (working in isolated space)
- If in root with active worktrees → warn but allow (quick changes are low-risk)
- Quick changes get their own lightweight branches, not full worktrees

```bash
SAFETY_CHECK=$(bash .spec-flow/scripts/bash/worktree-context.sh check-safety 2>/dev/null || echo '{"safe": true}')
IS_SAFE=$(echo "$SAFETY_CHECK" | jq -r '.safe')
IN_WORKTREE=$(echo "$SAFETY_CHECK" | jq -r '.in_worktree')
ACTIVE_COUNT=$(echo "$SAFETY_CHECK" | jq -r '.active_worktrees | length // 0')
```

**If IN_WORKTREE is true:**
- Proceed normally (isolated environment)

**If IN_WORKTREE is false AND ACTIVE_COUNT > 0:**
- Output warning:
```
⚠️  Note: Active worktrees detected. Quick changes from root will be on a separate branch.
    Active worktrees: ${ACTIVE_COUNT}
    Proceeding with quick change...
```
- Proceed with quick change (creates its own branch)

**If IS_SAFE is true:**
- Proceed normally

---

## PHASE 1: Parse Arguments and Validate Scope (INLINE)

**User Input:**
```text
$ARGUMENTS
```

### Step 1.1: Get Description

**If $ARGUMENTS is empty:**

Use AskUserQuestion to request:
```
Question: "What change would you like to implement?"
Header: "Quick Change"
Options:
  - label: "Bug fix"
    description: "Fix an existing bug or issue"
  - label: "Refactor"
    description: "Improve code structure without changing behavior"
  - label: "Documentation"
    description: "Update README, comments, or docstrings"
  - label: "Config change"
    description: "Update environment variables or settings"
```

**Store the description in DESCRIPTION variable.**

### Step 1.2: Validate Scope

**Check if DESCRIPTION mentions complex keywords:**
- database, schema, migration
- API contract, breaking change
- auth, authentication, authorization, security, permissions
- crypto, encryption

**If complex keywords detected:**

Output:
```
⚠️  This change appears to require full workflow planning.

Detected scope indicators: [list keywords found]

Recommendation: Use /feature instead for proper planning and review.

Command: /feature "{DESCRIPTION}"
```

Then EXIT - do not proceed.

**If scope is appropriate:** Proceed to Phase 2.

---

## PHASE 2: Detect UI Mode, Studio Context, and Setup Branch (INLINE)

### Step 2.1: Detect UI Changes

**Check if DESCRIPTION contains UI-related keywords:**
- UI, component, button, form, card, layout, design
- style, CSS, Tailwind, color, spacing, font, typography
- gradient, shadow, border

**If UI change detected:**
- Set STYLE_GUIDE_MODE = true
- Output: "UI change detected - style guide compliance will be enforced"

**If non-UI change:**
- Set STYLE_GUIDE_MODE = false

### Step 2.2: Detect Studio Context (v11.8)

**Check for studio mode (automatic):**
```bash
STUDIO_AGENT=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-detect 2>/dev/null || echo "")
IS_STUDIO_MODE="false"
if [[ -n "$STUDIO_AGENT" ]]; then
  IS_STUDIO_MODE="true"
  echo "Studio mode: $STUDIO_AGENT"
fi
```

### Step 2.3: Create Branch (Studio-Aware)

**Generate branch name (studio-aware):**
- Slugify DESCRIPTION: lowercase, replace spaces with hyphens, remove special chars
- Truncate slug to 50 characters
- Use studio-branch helper for proper namespacing:

```bash
# Get namespaced branch (handles studio detection automatically)
BRANCH=$(bash .spec-flow/scripts/bash/worktree-context.sh studio-branch "quick" "[slug]" 2>/dev/null)
# Returns: "studio/agent-1/quick/fix-button" in studio mode
# Returns: "quick/fix-button" in normal mode
```

**Create branch:**
```bash
git checkout -b $BRANCH
```

**If branch exists:**
```bash
git checkout $BRANCH
```
Output: "Using existing branch $BRANCH"

---

## PHASE 3: Execute Quick Worker (ISOLATED via Task)

**YOU MUST spawn an isolated agent via Task tool.**

Use the Task tool with these EXACT parameters:

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Execute quick change: {first 50 chars of DESCRIPTION}"
  prompt: |
    Execute quick change atomically. You are a quick-worker agent.

    Read the quick-worker agent brief at: .claude/agents/quick/quick-worker.md

    ## Context
    Description: {DESCRIPTION}
    Style Guide Mode: {STYLE_GUIDE_MODE}
    Branch: {BRANCH}
    Studio Mode: {IS_STUDIO_MODE}
    Studio Agent: {STUDIO_AGENT or "N/A"}

    ## Your Task
    1. Read the agent brief for detailed instructions
    2. Detect implementation domain (backend/frontend/test/docs)
    3. Implement changes following KISS principle (<100 LOC)
    4. Run tests if test framework detected
    5. Validate style guide if Style Guide Mode is true
    6. Commit changes with conventional message
    7. Return structured result

    ## Output Format (CRITICAL - follow exactly)

    If successful, return:
    ---COMPLETED---
    files_changed: N
    commit_sha: abc123
    summary: "Brief description of changes made"
    tests: "passed|failed|skipped|no_framework"
    style_guide: "compliant|warnings|N/A"

    If blocked and need user input, return:
    ---NEEDS_INPUT---
    questions:
      - id: "Q001"
        question: "The question to ask"
        header: "Short header"
        multi_select: false
        options:
          - label: "Option 1"
            description: "What this option does"
          - label: "Option 2"
            description: "What this option does"

    If failed, return:
    ---FAILED---
    reason: "Description of what went wrong"
    recovery: "Suggested next steps"
```

---

## PHASE 4: Handle Agent Result (INLINE)

**Parse the delimiter from agent response:**

### If `---COMPLETED---`

Extract the result fields and display completion banner (with studio info if active):

```
════════════════════════════════════════════════════════════════════════════════
✅ Quick change complete!
════════════════════════════════════════════════════════════════════════════════

Branch: {BRANCH}
Files changed: {files_changed}
Commit: {commit_sha}
Tests: {tests}
Style guide: {style_guide}
${IS_STUDIO_MODE == "true" ? "Studio Agent: {STUDIO_AGENT}" : ""}

Summary: {summary}

Next steps:
${IS_STUDIO_MODE == "true" ? "
  • Review changes: git show
  • Create PR: gh pr create --base main
  • PR will auto-merge when CI passes
" : "
  • Review changes: git show
  • Run app locally: npm run dev (or pytest)
  • Merge to main: git checkout main && git merge {BRANCH}
  • Push (if remote): git push origin main
  • Delete branch: git branch -d {BRANCH}
"}
```

### If `---NEEDS_INPUT---`

**LOOP: Handle Q&A until COMPLETED or FAILED**

1. Parse questions from the response
2. Use AskUserQuestion to ask the user
3. Re-spawn agent with the answers:

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Continue quick change with user answers"
  prompt: |
    Continue executing quick change with user's answers. You are a quick-worker agent.

    Read the quick-worker agent brief at: .claude/agents/quick/quick-worker.md

    ## Original Context
    Description: {DESCRIPTION}
    Style Guide Mode: {STYLE_GUIDE_MODE}
    Branch: quick/{slug}

    ## User Answers
    {FOR EACH QUESTION}
    Q: {question}
    A: {user's answer}
    {END FOR}

    ## Resume Task
    Continue from where you left off using the user's answers.
    Return structured result using the same delimiter format (---COMPLETED---, ---NEEDS_INPUT---, or ---FAILED---).
```

4. Parse new response and repeat loop if still `---NEEDS_INPUT---`

### If `---FAILED---`

Display error and recovery:

```
════════════════════════════════════════════════════════════════════════════════
❌ Quick change failed
════════════════════════════════════════════════════════════════════════════════

Reason: {reason}

Recovery: {recovery}

Options:
  • Try again with modified scope
  • Use /feature for complex changes
  • Checkout main and delete branch: git checkout main && git branch -D quick/{slug}
```

</process>

<success_criteria>
Quick implementation is complete when:

- Agent returns `---COMPLETED---` with valid fields
- Changes committed to `quick/[slug]` branch
- Summary displayed with files changed and next steps
- If UI change: Style guide compliance reported
- No breaking changes introduced
- Single concern addressed (no scope creep)
</success_criteria>

<comparison_table>

## /quick vs /feature

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
/quick "Fix login button alignment on mobile"
```
- Orchestrator creates branch `quick/fix-login-button-alignment`
- Task(quick-worker) identifies CSS issue, fixes, tests, commits
- Returns `---COMPLETED---` with summary
- User sees completion banner with next steps

**Example 2: Test Failure Handling**
```
/quick "Update error message text in signup form"
```
- Task(quick-worker) makes change, runs tests, tests fail
- Returns `---NEEDS_INPUT---` asking how to proceed
- Orchestrator asks user via AskUserQuestion
- User chooses "Update snapshots"
- Task(quick-worker) continues with answer, commits
- Returns `---COMPLETED---`

**Example 3: Scope Escalation**
```
/quick "Add user authentication with OAuth"
```
- Task(quick-worker) analyzes scope, detects complexity
- Returns `---FAILED---` with recovery suggesting /feature
- Orchestrator displays error and recovery steps

**Example 4: UI Change with Style Guide**
```
/quick "Add success toast after user signup"
```
- Orchestrator detects UI keywords, sets STYLE_GUIDE_MODE=true
- Task(quick-worker) implements with token compliance
- Validates style guide, reports compliance status
- Returns `---COMPLETED---` with style_guide: "compliant"
</examples>

<error_handling>
**If git not initialized:**
- Error: "Git repository not found - initialize with `git init` first"
- Abort command execution

**If branch creation fails:**
- Show git error
- Suggest checking current branch status

**If agent times out:**
- Display partial progress if available
- Suggest re-running with `/quick continue` (future enhancement)

**If delimiter not found in response:**
- Treat as unexpected error
- Display raw agent output
- Suggest re-running command
</error_handling>

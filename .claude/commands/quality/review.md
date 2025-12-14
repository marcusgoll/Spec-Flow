---
name: review
description: Run on-demand code review during development (voting-enabled)
argument-hint: [--voting | --single | --scope all|changes]
allowed-tools: [Bash, Read, Write, Edit, Task, Grep, Glob, AskUserQuestion]
---

# /review — On-Demand Code Review

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Uncommitted Changes**: !`git diff --name-only HEAD 2>/dev/null | head -10`

**Staged Changes**: !`git diff --cached --name-only 2>/dev/null | head -10`

**Active Feature**: @specs/*/state.yaml (find most recent by mtime)

**Voting Config**: @.spec-flow/config/voting.yaml
</context>

<objective>
Run code review at any point during development.

**Review Modes:**
| Mode | Flag | Speed | Use Case |
|------|------|-------|----------|
| Single-agent | `--single` (default) | ~2 min | Quick sanity check |
| Multi-agent voting | `--voting` | ~6 min | Critical decisions, pre-merge |

**Scope Options:**
| Scope | Flag | What's Reviewed |
|-------|------|-----------------|
| Changes | `--scope changes` (default) | Uncommitted + staged changes |
| All | `--scope all` | Entire feature directory |

**Risk Level**: LOW — Read-only analysis, no code modifications
</objective>

<process>

## Step 1: Parse Arguments

Extract flags from `$ARGUMENTS`:

| Flag | Variable | Default |
|------|----------|---------|
| `--voting` | USE_VOTING | false |
| `--single` | USE_VOTING | false |
| `--scope changes` | SCOPE | "changes" |
| `--scope all` | SCOPE | "changes" |

## Step 2: Detect Review Scope

**If SCOPE = "changes":**

1. Get list of changed files:
   ```bash
   git diff --name-only HEAD
   git diff --cached --name-only
   ```

2. If no changes found:
   - Inform user: "No uncommitted changes detected"
   - Ask: Switch to `--scope all` or exit?

3. Display changed files (max 15, then "and N more...")

**If SCOPE = "all":**

1. Detect active feature directory from:
   - Current branch name matching `specs/*/` pattern
   - Most recent `specs/*/state.yaml` by modification time
   - Fall back to current working directory

2. Display: "Reviewing entire feature: {feature_dir}"

## Step 3: Gather Review Context

**Do NOT create temp files.** Gather context in memory:

1. **For scope=changes**: Read each changed file using Read tool
2. **For scope=all**: Read key files:
   - `spec.md` — Feature specification
   - `plan.md` — Implementation plan
   - `tasks.md` — Task breakdown
   - Source files in feature directory

3. **Get git diff for changes**:
   ```bash
   git diff HEAD
   ```

## Step 4: Execute Review

### Option A: Single-Agent Review (default)

Use the Task tool to invoke code-reviewer:

```
Task({
  subagent_type: "code-reviewer",
  description: "Code review for {feature_name}",
  prompt: "Review the following code changes for quality issues.

## Review Focus Areas

1. **Code Quality**: KISS, DRY, clear naming, appropriate abstractions
2. **Security**: Input validation, injection risks, secrets exposure
3. **Performance**: N+1 queries, inefficient algorithms, memory leaks
4. **Testing**: Coverage for new code, edge cases, mock appropriateness
5. **Architecture**: Separation of concerns, API design, error handling

## Context

Feature: {feature_name}
Scope: {scope}
Files: {file_list}

## Changes

{git_diff or file_contents}

## Output Format

Generate a review report with:
1. **Executive Summary** — 2-3 sentence overview
2. **Issues** — Categorized as CRITICAL / MAJOR / MINOR with file:line references
3. **Recommendations** — Priority-ordered action items
4. **Score** — Code quality score 0-100

Save report to: {feature_dir}/artifacts/review-{timestamp}.md"
})
```

### Option B: Multi-Agent Voting Review (--voting)

**Pre-check**: Verify voting is available:
```bash
test -f .spec-flow/config/voting.yaml && echo "available" || echo "unavailable"
```

**If unavailable**: Fall back to single-agent with warning:
> "Voting system not configured. Running single-agent review instead."

**If available**: Launch 3 parallel review agents:

```
# Launch 3 agents in parallel with temperature variation
Task({
  subagent_type: "code-reviewer",
  description: "Voting review agent 1 (t=0.5)",
  model: "sonnet",  # Lower temperature via model hints
  prompt: "{same prompt as above}",
  run_in_background: true
})

Task({
  subagent_type: "code-reviewer",
  description: "Voting review agent 2 (t=0.7)",
  prompt: "{same prompt as above}",
  run_in_background: true
})

Task({
  subagent_type: "code-reviewer",
  description: "Voting review agent 3 (t=0.9)",
  prompt: "{same prompt as above}",
  run_in_background: true
})
```

**Aggregate results** using k=2 voting:
- Issue is confirmed if 2+ agents report it
- Score is median of 3 scores
- Recommendations merged and deduplicated

## Step 5: Display Results

**Summary format:**
```
══════════════════════════════════════════
 Code Review Results
══════════════════════════════════════════

Review type: {Single-agent | Multi-agent voting (3 agents, k=2)}
Scope: {changes | all}
Files reviewed: {count}

CRITICAL: {count}  MAJOR: {count}  MINOR: {count}

Code Quality Score: {score}/100

Full report: {report_path}
══════════════════════════════════════════
```

**If CRITICAL or MAJOR issues found**, use AskUserQuestion:

```json
{
  "questions": [{
    "question": "Issues found. What would you like to do?",
    "header": "Next Step",
    "multiSelect": false,
    "options": [
      {"label": "View full report", "description": "Read the detailed review report"},
      {"label": "Auto-fix linting", "description": "Run lint --fix on affected files"},
      {"label": "Show file:line refs", "description": "List all issue locations for navigation"},
      {"label": "Continue", "description": "Acknowledge issues, address later"}
    ]
  }]
}
```

**Handle responses:**

- **View full report**: Use Read tool on report file
- **Auto-fix linting**: Run appropriate linter with --fix flag based on file types
- **Show file:line refs**: Extract and display all `file:line` patterns from report
- **Continue**: Display acknowledgment and exit

## Step 6: Cleanup

No temp files to clean. Report persists in `{feature_dir}/artifacts/`.

</process>

<anti-hallucination>
## Rules to Prevent Fabricated Results

1. **Never invent issues** — Only report issues found by actual code analysis
2. **Quote real code** — Include actual file:line references, not placeholders
3. **Verify file existence** — Use Glob before claiming to review files
4. **Honest scores** — Score reflects actual quality, not optimistic guessing
5. **No phantom delegation** — If invoking Task(), actually invoke it
</anti-hallucination>

<examples>

## Example 1: Quick Review of Changes

```
> /review

Detecting changes...
Found 3 changed files:
  - src/components/UserCard.tsx
  - src/lib/api.ts
  - tests/api.test.ts

Invoking code-reviewer agent...

══════════════════════════════════════════
 Code Review Results
══════════════════════════════════════════

Review type: Single-agent
Scope: changes
Files reviewed: 3

CRITICAL: 0  MAJOR: 1  MINOR: 3

Code Quality Score: 84/100

Full report: specs/042-user-profile/artifacts/review-1702583921.md
══════════════════════════════════════════
```

## Example 2: Voting Review Before Merge

```
> /review --voting --scope all

Review scope: Entire feature (specs/042-user-profile)

Launching 3-agent voting review...
  Agent 1: ████████░░ analyzing...
  Agent 2: ██████████ complete
  Agent 3: █████████░ analyzing...

Aggregating votes (k=2 consensus)...

══════════════════════════════════════════
 Code Review Results
══════════════════════════════════════════

Review type: Multi-agent voting (3 agents, k=2)
Scope: all
Files reviewed: 12

CRITICAL: 0  MAJOR: 2  MINOR: 5

Code Quality Score: 78/100

Voting consensus: 2/3 agents agree on all MAJOR issues

Full report: specs/042-user-profile/artifacts/review-voting-1702583921.md
══════════════════════════════════════════
```

</examples>

<notes>

## When to Use Each Mode

| Situation | Recommended Mode |
|-----------|------------------|
| Quick check before commit | `/review` (default) |
| Before creating PR | `/review --scope all` |
| Critical feature (auth, payments) | `/review --voting` |
| Before merge to main | `/review --voting --scope all` |
| During implementation | `/review` after each task batch |

## Token Cost

| Mode | Approximate Cost |
|------|------------------|
| Single-agent, changes | ~2k tokens |
| Single-agent, all | ~5k tokens |
| Voting, changes | ~6k tokens |
| Voting, all | ~15k tokens |

## Output Location

Reports saved to: `{feature_dir}/artifacts/review-{timestamp}.md`

Voting reports: `{feature_dir}/artifacts/review-voting-{timestamp}.md`

</notes>

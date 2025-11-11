---
description: Orchestrate full feature workflow with isolated phase contexts (optimized)
---

# /feature — Phase-Isolated Feature Orchestration

**Purpose**
Deterministically deliver a feature through isolated phase agents with strict state tracking, explicit gates, and zero assumption drift.

**Command**
`/feature [feature description | slug | continue | next]`

**When to use**
From idea selection through deployment. Pauses only at manual gates or blocking failures.

---

## Mental model

**Architecture: Orchestrator + Phase Agents**
- **Orchestrator** (`/feature`): moves one phase at a time, updates `workflow-state.yaml`, never invents state.
- **Phase Agents**: run with fresh context pulled from disk; they return structured JSON.
- **Implementation**: `implement-phase-agent` batches independent tasks in parallel, then sequences dependent batches.

**Benefits**
- Smaller token budgets per phase; faster execution; quality preserved by the same slash-commands and gates.

---

## Workflow tracking

> All steps read/write `specs/<NNN-slug>/workflow-state.yaml`.

**Initialize todos (example, staging-prod model)**

```javascript
TodoWrite({
  todos: [
    {content:"Parse args, initialize state",status:"pending",activeForm:"Init"},
    {content:"Phase 0: Specification",status:"pending",activeForm:"Creating spec"},
    {content:"Phase 0.5: Clarification (conditional)",status:"pending",activeForm:"Resolving clarifications"},
    {content:"Phase 1: Planning",status:"pending",activeForm:"Creating plan"},
    {content:"Phase 2: Task breakdown",status:"pending",activeForm:"Generating tasks"},
    {content:"Phase 2a–2c: Design workflow (UI only)",status:"pending",activeForm:"Running design workflow"},
    {content:"Phase 3: Cross-artifact analysis",status:"pending",activeForm:"Validating artifacts"},
    {content:"Phase 4: Implementation",status:"pending",activeForm:"Implementing tasks"},
    {content:"Phase 5: Optimization",status:"pending",activeForm:"Optimizing code"},
    {content:"Manual gate: Preview",status:"pending",activeForm:"Awaiting preview"},
    {content:"Phase 6: Ship to staging",status:"pending",activeForm:"Deploying to staging"},
    {content:"Manual gate: Staging validation",status:"pending",activeForm:"Awaiting staging approval"},
    {content:"Phase 7: Ship to production",status:"pending",activeForm:"Deploying to production"},
    {content:"Phase 7.5: Finalize docs",status:"pending",activeForm:"Finalizing documentation"}
  ]
})
```

**Rules**

* Exactly one phase is `in_progress`.
* Manual gates remain `pending` until explicitly continued.
* Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`.

---

## Anti-hallucination rules

1. **Never claim phase completion without quoting `workflow-state.yaml`**
   Always `Read` the file and print the actual recorded status.

2. **Cite agent outputs**
   When a phase finishes, paste the returned `{status, summary, stats}` keys.

3. **Do not skip phases unless state marks them disabled**
   Follow the recorded sequence; if required, run it.

4. **Detect the deployment model from the repo**
   Show evidence: `git branch -a`, presence of staging workflow files.

5. **No fabricated summaries**
   If an agent errors, show the error; don't invent success.

**Why**
This prevents silent quality gaps and makes the workflow auditable against real artifacts.

---

## Reasoning template (use when making orchestration decisions)

```text
<thinking>
1) Current phase/status: [quote from workflow-state.yaml]
2) Artifacts produced: [list with paths]
3) Prerequisites for next phase: [check files/flags]
4) Failures present: [list count + locations]
5) Decision: [retry | proceed | abort] with justification
</thinking>
<answer>
[One clear instruction for next action]
</answer>
```

Use this template for: skipping clarify, choosing deployment path, retry logic, handling partial failures, continuing after gates.

---

## Parse arguments

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ -z "$ARGUMENTS" ]; then
  echo "Usage: /feature [slug | \"feature description\" | continue | next]"
  exit 1
fi

MODE=""
SEARCH_TERM=""
CONTINUE_MODE=false
NEXT_MODE=false

case "$ARGUMENTS" in
  continue) CONTINUE_MODE=true ; MODE="continue" ;;
  next)     NEXT_MODE=true     ; MODE="next" ;;
  *)        SEARCH_TERM="$ARGUMENTS" ; MODE="lookup" ;;
esac
```

---

## Fetch next feature (when `MODE=next`)

Select highest-priority issue in `status:next` (fallback to `status:backlog`), claim it immediately, and extract `slug` from frontmatter or synthesize from title.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ "$NEXT_MODE" = true ]; then
  gh auth status >/dev/null || { echo "❌ gh not authenticated. Run: gh auth login"; exit 1; }
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "❌ Not in a GitHub repo"; exit 1; }

  JSON=$(gh issue list --repo "$REPO" --label "status:next,type:feature" --json number,title,body,labels --limit 50)
  if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
    JSON=$(gh issue list --repo "$REPO" --label "status:backlog,type:feature" --json number,title,body,labels --limit 50)
  fi
  [ -z "$JSON" ] && { echo "❌ No next/backlog items"; exit 1; }

  # Sort by priority label and pick first
  ISSUE=$(echo "$JSON" | jq -r '
    map(select(.labels | any(.name | startswith("priority:")))) |
    sort_by(
      .labels[] | select(.name | startswith("priority:")) | .name |
      if .=="priority:high" then 1 elif .=="priority:medium" then 2 elif .=="priority:low" then 3 else 4 end
    ) | first')

  ISSUE_NUMBER=$(echo "$ISSUE" | jq -r .number)
  ISSUE_TITLE=$(echo "$ISSUE" | jq -r .title)
  ISSUE_BODY=$(echo "$ISSUE" | jq -r '.body // ""')

  # Claim immediately to avoid race conditions
  gh issue edit "$ISSUE_NUMBER" --remove-label "status:next" --remove-label "status:backlog" --add-label "status:in-progress" --repo "$REPO" >/dev/null || true

  SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)
  if [ -z "$SLUG" ]; then
    SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-20)
  fi

  FEATURE_DESCRIPTION="$ISSUE_TITLE"
fi
```

> Uses GitHub CLI official flows; see `gh` manual for commands and auth.

---

## Lookup feature (when `MODE=lookup`)

Search roadmap by exact `slug:` in frontmatter or fuzzy title match. If not found, offer to create a non-roadmap feature.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ "$MODE" = "lookup" ] && [ -n "$SEARCH_TERM" ]; then
  gh auth status >/dev/null || { echo "❌ gh not authenticated"; exit 1; }
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || { echo "❌ Not in a GitHub repo"; exit 1; }

  MATCH=$(gh issue list --repo "$REPO" --label "type:feature" --json number,title,body,labels --limit 100 |
    jq -r --arg term "$SEARCH_TERM" '
      map(select((.body | test("slug:\\s*\"" + $term + "\"")) or (.title | ascii_downcase | contains($term | ascii_downcase)))) | first')

  if [ -n "$MATCH" ] && [ "$MATCH" != "null" ]; then
    ISSUE_NUMBER=$(echo "$MATCH" | jq -r .number)
    ISSUE_TITLE=$(echo "$MATCH" | jq -r .title)
    ISSUE_BODY=$(echo "$MATCH" | jq -r '.body // ""')
    gh issue edit "$ISSUE_NUMBER" --remove-label "status:next" --remove-label "status:backlog" --add-label "status:in-progress" --repo "$REPO" >/dev/null || true
    SLUG=$(echo "$ISSUE_BODY" | grep -oP '^slug:\s*"\K[^"]+' | head -1)
    [ -z "$SLUG" ] && SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-30)
    FEATURE_DESCRIPTION="$ISSUE_TITLE"
  else
    echo "No roadmap item found for: \"$SEARCH_TERM\". Create now or add to roadmap first."
    exit 1
  fi
fi
```

---

## Generate feature slug (if not provided)

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ -z "$SLUG" ]; then
  [ -z "$FEATURE_DESCRIPTION" ] && { echo "❌ Provide a description or use /feature next"; exit 1; }
  SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(we want to\|i want to\|with\|for the\|to a\)\b//g' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-20)
fi

[[ "$SLUG" == *".."* || "$SLUG" == *"/"* ]] && { echo "❌ Invalid slug"; exit 1; }
```

---

## Detect project type

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if command -v bash >/dev/null 2>&1; then
  PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
else
  PROJECT_TYPE=$(pwsh -File .spec-flow/scripts/powershell/detect-project-type.ps1)
fi

echo "Project type: $PROJECT_TYPE"
```

---

## Branch management

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH_NAME="local"
  MAX_NUM=$(find specs -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed -n 's#specs/\([0-9]\{3\}\)-.*#\1#p' | sort -n | tail -1)
  FEATURE_NUM=$(printf '%03d' $((10#${MAX_NUM:-0} + 1)))
else
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Dirty worktree. Commit/stash or reset before proceeding."
    exit 1
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  MAX_NUM=$(find specs -maxdepth 1 -mindepth 1 -type d | sed -n 's#specs/\([0-9]\{3\}\)-.*#\1#p' | sort -n | tail -1)
  FEATURE_NUM=$(printf '%03d' $((10#${MAX_NUM:-0} + 1)))

  if [[ "$CURRENT_BRANCH" =~ ^(main|master)$ ]]; then
    BASE="feature/$FEATURE_NUM-$SLUG"
    BRANCH_NAME="$BASE"
    i=2; while git rev-parse --verify --quiet "$BRANCH_NAME" >/dev/null 2>&1; do BRANCH_NAME="$BASE-$i"; i=$((i+1)); done
    git checkout -b "$BRANCH_NAME"
  else
    BRANCH_NAME="$CURRENT_BRANCH"
  fi
fi
```

---

## Initialize workflow state

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

FEATURE_DIR="specs/$FEATURE_NUM-$SLUG"
mkdir -p "$FEATURE_DIR"

# Source helpers (bash or PowerShell variant)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .spec-flow/scripts/bash/workflow-state.sh 2>/dev/null || true
else
  source .spec-flow/scripts/bash/workflow-state.sh
fi

initialize_workflow_state "$FEATURE_DIR" "$SLUG" "${FEATURE_DESCRIPTION:-$SLUG}" "$BRANCH_NAME"
start_phase_timing "$FEATURE_DIR" "spec-flow"

[ -n "$ISSUE_NUMBER" ] && yq -i ".feature.github_issue = $ISSUE_NUMBER" "$FEATURE_DIR/workflow-state.yaml" || true

# Optional: generate feature CLAUDE.md
.spec-flow/scripts/bash/generate-feature-claude-md.sh "$FEATURE_DIR" 2>/dev/null || true
```

---

## Phase 0: Specification

Invoke `phase/spec` agent; store results; set next phase based on clarifications.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

Task subagent_type="phase/spec" description="Phase 0: Specification" prompt="$(
  cat <<PROMPT
Execute Phase 0 in isolated context.

Feature: $SLUG
Number: $FEATURE_NUM
Branch: $BRANCH_NAME
ProjectType: $PROJECT_TYPE

1) export SLUG="$SLUG"
2) export FEATURE_NUM="$FEATURE_NUM"
3) Call /specify
4) Return JSON: {status, summary, needs_clarification, key_decisions}
PROMPT
)"

# Validate, then:
complete_phase_timing "$FEATURE_DIR" "spec-flow"
update_workflow_phase "$FEATURE_DIR" "spec-flow" "completed"

# Choose next:
if jq -e '.needs_clarification==true' /tmp/phase-spec.json >/dev/null 2>&1; then
  update_workflow_phase "$FEATURE_DIR" "clarify" "in_progress"
else
  update_workflow_phase "$FEATURE_DIR" "plan" "in_progress"
fi
```

---

## Phase 0.5: Clarification (conditional)

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

if [ "$(yq '.workflow.phases.clarify.status' "$FEATURE_DIR/workflow-state.yaml")" = "in_progress" ]; then
  Task subagent_type="phase/clarify" description="Phase 0.5: Clarify" prompt="Call /clarify and return JSON {status, summary, answers}"
  update_workflow_phase "$FEATURE_DIR" "clarify" "completed"
  update_workflow_phase "$FEATURE_DIR" "plan" "in_progress"
fi
```

---

## Phase 1: Planning

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

Task subagent_type="phase/plan" description="Phase 1: Plan" prompt="Call /plan; return {status, summary, reuse, decisions}"
update_workflow_phase "$FEATURE_DIR" "plan" "completed"
update_workflow_phase "$FEATURE_DIR" "tasks" "in_progress"
```

---

## Phase 2: Task breakdown

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

Task subagent_type="phase/tasks" description="Phase 2: Tasks" prompt="Call /tasks; return {status, summary, task_count, groups}"
update_workflow_phase "$FEATURE_DIR" "tasks" "completed"
```

### Phase 2a–2c: Design workflow (UI only)

* 2a `/design-variations` → grayscale variants
* 2b `/design-functional` → merged functional prototype + a11y/tests
* 2c `/design-polish` → brand tokens + perf polish

Resume with `/feature continue` after each human checkpoint.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

HAS_UI=$(grep -E "^- UI screens:\s*(true|false)" "$FEATURE_DIR/NOTES.md" | awk '{print $4}')
if [ "$HAS_UI" = "true" ]; then
  yq -i '.design_workflow.enabled = true' "$FEATURE_DIR/workflow-state.yaml"
  /design-variations "$SLUG";  yq -i '.design_workflow.phases.variations="completed"' "$FEATURE_DIR/workflow-state.yaml"; exit 0
  # After continue:
  /design-functional "$SLUG";  yq -i '.design_workflow.phases.functional="completed"' "$FEATURE_DIR/workflow-state.yaml"; exit 0
  # After continue:
  /design-polish "$SLUG";      yq -i '.design_workflow.phases.polish="completed"' "$FEATURE_DIR/workflow-state.yaml"
fi
```

---

## Phase 3: Cross-artifact analysis

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

Task subagent_type="phase/validate" description="Phase 3: Validate" prompt="Call /analyze; return {status, summary, issues}"
# If status != completed → mark failed and stop
```

---

## Phase 4: Implementation

Use `implement-phase-agent` for dependency analysis and batched parallel execution.

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

Task subagent_type="implement-phase-agent" description="Phase 4: Implement" prompt="$(
  cat <<PROMPT
Execute implementation with intelligent batching.

Context directory: $FEATURE_DIR
Must: read NOTES.md, tasks.md, workflow-state.yaml
Return:
{
  "status": "...",
  "summary": "...",
  "stats": {"total_tasks":N,"completed_tasks":N,"files_changed":N,"error_count":N,"batches_executed":N},
  "blockers":[],
  "key_decisions":[]
}
PROMPT
)"

# If incomplete or blocked → mark failed and stop
# Else mark completed and persist stats
```

---

## Auto-continue to Phase 5 (Optimization)

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

echo "→ Running /optimize"
/optimize || { echo "❌ Optimization failed"; exit 1; }

# Optional: count criticals in code-review.md and stop if any
```

---

## Auto-continue to Phase 6–7 (Ship)

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

echo "→ Running /ship"
/ship || { echo "❌ Ship failed"; exit 1; }

# On success, display timing summary and artifacts
```

> Prefer short-lived branches and frequent integration; this aligns with trunk-based development guidance and generally supports better outcomes on DORA's throughput and stability metrics. (https://dora.dev/research/2018/dora-report/2018-dora-accelerate-state-of-devops-report.pdf)

---

## Resume semantics

`/feature continue`

* Loads most recent `specs/*/workflow-state.yaml`
* Finds the first `in_progress` or last `failed` phase
* Resumes that phase; if a manual gate was pending, proceeds past it

---

## Error handling

* Any phase with `status=blocked|failed` is written to state with summary and blockers.
* No reproduction: record "attempted steps" and exit.
* Verification failures: record partial results; do not proceed.
* Git conflicts: abort commit and instruct to resolve; never auto-resolve.

---

## References

* GitHub CLI manual (commands, auth, issues): https://cli.github.com/manual
* Trunk-Based Development: short-lived branches, frequent merges: https://trunkbaseddevelopment.com
* DORA research on throughput and stability (four key metrics): https://dora.dev/research/2018/dora-report/2018-dora-accelerate-state-of-devops-report.pdf
* OpenTelemetry signals (traces, metrics, logs) for lightweight phase breadcrumbs: https://opentelemetry.io/docs/concepts/signals

---

## Philosophy

**State truth lives in `workflow-state.yaml`**
Never guess; always read, quote, and update atomically.

**Phases are isolated**
Each agent reads context from disk (NOTES.md, tasks.md, spec.md) and returns structured JSON. No hidden handoffs.

**Manual gates are explicit**
Preview and staging validation pause the workflow until `/feature continue` is called with explicit approval.

**Auto-continue when safe**
After implementation completes, automatically chain to `/optimize` → `/ship` unless blocked by critical issues.

**Deployment model adapts**
Detect `staging-prod`, `direct-prod`, or `local-only` from actual repo structure; adjust phases accordingly.

**Fail fast, fail loud**
Record failures in state; never pretend success. Exit with meaningful codes: 0 (success), 1 (error), 2 (verification failed).

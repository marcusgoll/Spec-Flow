---
description: Orchestrate full feature workflow with isolated phase contexts (optimized)
version: 2.0
updated: 2025-11-17
---

# /feature — Phase-Isolated Feature Orchestration

**Purpose**: Deterministically deliver a feature through isolated phase agents with strict state tracking, explicit gates, and zero assumption drift.

**Command**: `/feature [feature description | slug | continue | next | epic:<name> | epic:<name>:sprint:<num> | sprint:<num>]`

**When to use**: From idea selection through deployment. Pauses only at manual gates or blocking failures.

---

## Mental model

**Architecture: Orchestrator + Phase Commands + Specialist Agents**
- **Orchestrator** (`/feature`): moves one phase at a time, updates `workflow-state.yaml`, never invents state
- **Phase Commands**: `/spec`, `/plan`, `/tasks`, `/implement`, `/optimize`, `/ship` execute phases
- **Specialist Agents**: `/implement` directly launches backend-dev, frontend-shipper, database-architect in parallel (no wrapper)

**Benefits**: Smaller token budgets per phase; faster execution; quality preserved by the same slash-commands and gates.

---

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Feature Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py feature "$ARGUMENTS"
```

**What the script does:**

1. **Parse arguments** — Determines mode: next, continue, lookup, epic, sprint
2. **GitHub issue selection** (if applicable):
   - `next` mode: Selects highest-priority issue from status:next or status:backlog
   - `epic:name` mode: Auto-detects incomplete sprint and selects next issue
   - `epic:name:sprint:num` mode: Selects next issue from specific epic+sprint
   - `sprint:num` mode: Selects next issue from any sprint
   - `lookup` mode: Searches by slug or title
3. **Feature slug generation** — Auto-generates from issue title or description
4. **Project type detection** — Identifies project technology (fullstack, backend, frontend, etc.)
5. **Branch management** — Creates feature branch or uses existing branch
6. **Initialize workflow state** — Creates specs/NNN-slug/ directory and workflow-state.yaml
7. **Generate feature CLAUDE.md** — Creates AI context navigation file

**After script completes, you (LLM) must:**

## 1) Verify Feature Initialization

**Read initialization results:**
- Feature number and slug
- Branch name
- Feature directory path
- GitHub issue number (if applicable)

## 2) Execute Workflow Phases

**Follow the phase sequence based on workflow state:**

**Phase 0: Specification**
```bash
/spec
```

**Phase 0.5: Clarification** (conditional):
```bash
/clarify
```

**Phase 1: Planning**:
```bash
/plan
```

**Phase 2: Task Breakdown**:
```bash
/tasks
```

**Phase 2a-2c: Design Workflow** (UI features only):
```bash
/design-variations
/design-functional
/design-polish
```

**Phase 3: Cross-Artifact Analysis**:
```bash
/analyze
```

**Phase 4: Implementation**:
```bash
/implement
```

**Phase 5: Optimization**:
```bash
/optimize
```

**Phase 6-8: Deployment & Finalization**:
```bash
/ship
```
(Automatically runs /finalize after deployment)

## 3) Handle Continue Mode

**When resuming with `/feature continue`:**
- Read `workflow-state.yaml` to find current phase
- Find first phase with status `in_progress` or `failed`
- Resume from that phase
- If manual gate was pending, proceed past it

## 4) Handle Manual Gates

**Preview gate:**
- Dev server starts
- User tests UI/UX, accessibility, performance
- Run `/ship continue` when approved

**Staging validation gate** (staging-prod model only):
- Staging deployment complete
- User tests in staging environment
- Run `/ship continue` when approved

## 5) Error Handling

**If any phase fails:**
- Read error details from workflow-state.yaml
- Check relevant log files in specs/NNN-slug/
- Present clear error message with file paths
- Suggest fixes based on error type
- Tell user to fix and run `/feature continue`

**Common failure modes:**
- Spec ambiguity → run `/clarify`
- Planning failures → check plan.md for missing context
- Implementation errors → check error-log.md
- Quality gate failures → check optimization-*.md reports
- Deployment failures → check deployment logs

</instructions>

---

## Workflow Tracking

All steps read/write `specs/<NNN-slug>/workflow-state.yaml`.

**Todo list example (staging-prod model):**

```javascript
TodoWrite({
  todos: [
    {content:"Parse args, initialize state",status:"completed",activeForm:"Initialized"},
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
    {content:"Phase 8: Finalize documentation (automatic)",status:"pending",activeForm:"Finalizing documentation"}
  ]
})
```

**Rules**:
- Exactly one phase is `in_progress`
- Manual gates remain `pending` until explicitly continued
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`

---

## Anti-Hallucination Rules

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

**Why**: This prevents silent quality gaps and makes the workflow auditable against real artifacts.

---

## Reasoning Template

Use when making orchestration decisions:

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

## Usage Examples

**Start next priority feature:**
```bash
/feature next
```

**Start feature from epic:**
```bash
/feature epic:aktr
```

**Start specific sprint in epic:**
```bash
/feature epic:aktr:sprint:S02
```

**Resume interrupted feature:**
```bash
/feature continue
```

**Lookup specific feature:**
```bash
/feature "user authentication"
```

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

---

## References

- [GitHub CLI manual](https://cli.github.com/manual) - Commands, auth, issues
- [Trunk-Based Development](https://trunkbaseddevelopment.com) - Short-lived branches, frequent merges
- [DORA Metrics](https://dora.dev/research/2018/dora-report/2018-dora-accelerate-state-of-devops-report.pdf) - Throughput and stability metrics
- [OpenTelemetry Signals](https://opentelemetry.io/docs/concepts/signals) - Traces, metrics, logs

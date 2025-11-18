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

### Manual Approval Gates

**Phase 0: Specification** (Manual Gate #1)
```bash
/spec
```
**PAUSE**: Review spec.md for completeness and accuracy. If approved, continue to planning.

**Phase 0.5: Clarification** (conditional):
```bash
/clarify
```

**Phase 1: Planning** (Manual Gate #2)
```bash
/plan
```
**PAUSE**: Review plan.md and research.md for technical approach. If approved, workflow proceeds automatically through implementation and optimization.

### Automatic Execution After Plan Approval

Once planning is approved, the following phases execute automatically without manual gates:

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

### Deployment & Testing (Fully Automated)

**Phase 6: Deploy to Staging** (automatic):
```bash
/ship-staging
```

**Automated Validation**: Staging validation auto-generates report with E2E tests, Lighthouse scores, rollback test, and health checks. All testing happens in staging environment - no manual gates.

**Phase 7: Deploy to Production** (automatic after validation):
```bash
/ship-prod
```

**Phase 8: Finalization** (automatic):
```bash
/finalize
```

## 3) Handle Continue Mode

**When resuming with `/feature continue`:**
- Read `workflow-state.yaml` to find current phase
- Find first phase with status `in_progress` or `failed`
- Resume from that phase
- If manual gate was pending, proceed past it

## 4) Handle Manual Gates

**Specification gate** (after /spec):
- Review spec.md for completeness
- Verify all requirements captured
- Run `/feature continue` when approved

**Planning gate** (after /plan):
- Review plan.md and research.md
- Verify technical approach
- Check for code reuse opportunities
- Run `/feature continue` when approved
- **Workflow then proceeds automatically through implementation**

**Staging validation gate** (after /ship-staging):
- Staging deployment complete
- Test all functionality in staging environment:
  - UI/UX across browsers and devices
  - Accessibility (keyboard nav, screen readers)
  - Performance (load times, responsiveness)
  - Integration with existing features
  - Error handling and edge cases
- Run `/feature continue` when approved to promote to production

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
    {content:"Manual gate: Spec review",status:"pending",activeForm:"Awaiting spec approval"},
    {content:"Phase 0.5: Clarification (conditional)",status:"pending",activeForm:"Resolving clarifications"},
    {content:"Phase 1: Planning",status:"pending",activeForm:"Creating plan"},
    {content:"Manual gate: Plan review",status:"pending",activeForm:"Awaiting plan approval"},
    {content:"Phase 2: Task breakdown (auto)",status:"pending",activeForm:"Generating tasks"},
    {content:"Phase 2a–2c: Design workflow (UI only, auto)",status:"pending",activeForm:"Running design workflow"},
    {content:"Phase 3: Cross-artifact analysis (auto)",status:"pending",activeForm:"Validating artifacts"},
    {content:"Phase 4: Implementation (auto)",status:"pending",activeForm:"Implementing tasks"},
    {content:"Phase 5: Optimization (auto)",status:"pending",activeForm:"Optimizing code"},
    {content:"Phase 6: Ship to staging (auto)",status:"pending",activeForm:"Deploying to staging"},
    {content:"Manual gate: Staging validation",status:"pending",activeForm:"Awaiting staging approval"},
    {content:"Phase 7: Ship to production",status:"pending",activeForm:"Deploying to production"},
    {content:"Phase 8: Finalize documentation (auto)",status:"pending",activeForm:"Finalizing documentation"}
  ]
})
```

**Rules**:
- Exactly one phase is `in_progress`
- **Manual gates**: Spec review (gate #1), Plan review (gate #2), Staging validation (gate #3)
- **Auto-progression**: After plan approval, phases 2-6 execute automatically
- Deployment phases adapt to model: `staging-prod`, `direct-prod`, or `local-only`
- Any blocker (test failure, build error, quality gate) pauses workflow for user review

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
Three manual gates pause workflow for human review:
1. Spec review — Verify requirements before planning
2. Plan review — Verify technical approach before implementation
3. Staging validation — Test complete feature before production

**Auto-progression after plan approval**
After plan is approved, automatically execute: tasks → validate → implement → optimize → ship-staging

**Test in staging, not locally**
All UI/UX, accessibility, performance, and integration testing happens in staging environment. No local preview gate.

**Deployment model adapts**
Detect `staging-prod`, `direct-prod`, or `local-only` from actual repo structure; adjust phases accordingly.

**Fail fast, fail loud**
Record failures in state; never pretend success. Any blocker (test failure, build error, quality gate) pauses workflow and requires `/feature continue` after fix.

---

## References

- [GitHub CLI manual](https://cli.github.com/manual) - Commands, auth, issues
- [Trunk-Based Development](https://trunkbaseddevelopment.com) - Short-lived branches, frequent merges
- [DORA Metrics](https://dora.dev/research/2018/dora-report/2018-dora-accelerate-state-of-devops-report.pdf) - Throughput and stability metrics
- [OpenTelemetry Signals](https://opentelemetry.io/docs/concepts/signals) - Traces, metrics, logs

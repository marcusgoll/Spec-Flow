---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

<context>
## MODEL OPS

<default_to_action>
- Implement changes by default; do not ask permission unless destructive or ambiguous. If something is unclear, pick the most reasonable assumption, proceed, and log the assumption in NOTES.md, then surface a single batched /clarify at the end.
</default_to_action>

<investigate_before_answering>
- Never speculate about code or docs you haven’t opened. Read the relevant files, roadmap, and templates before asserting constraints or proposing APIs.
</investigate_before_answering>

<tool_preambles>
- State a brief plan, then act. Summarize what you changed after tool use.
</tool_preambles>

<context_awareness_and_memory>
- Sonnet 4.5 tracks remaining context. Persist working state (progress, decisions, open questions) to NOTES.md and small JSON/YAML files as needed. Use the Memory tool if available for durable state between windows. Don’t stop early due to token anxiety; persist and continue next window.
</context_awareness_and_memory>
</context>

<constraints>
## ANTI-HALLUCINATION RULES
1) Don’t invent stack details. Cite files you opened (e.g., `package.json`, `docs/project/system-architecture.md`).
2) Quote $ARGUMENTS verbatim for user needs; mark only critical unknowns with `[NEEDS CLARIFICATION]` (max 3).
3) Verify roadmap references by exact slug before claiming relationships.
</constraints>

<instructions>
## STATE MACHINE (non-blocking)
1) Validate input → 2) Generate slug → 3) Git safety → 4) Roadmap lookup → 5) Research → 6) Generate spec → 7) Validate spec → 8) Commit → 9) Auto-progress

### 1) Input & Slug
- If `$SLUG` provided, use it. Else derive `short-descriptive-name` (lowercase, hyphenated, ≤50 chars; drop filler).
- Reject path traversal or empty slugs.

### 2) Git Safety (no prompts)
- If dirty tree: auto-stash; proceed. If branch is `main|master`, create `feature/${SLUG}` and continue.
- Create `specs/${SLUG}/` (or `${FEATURE_NUM}-${SLUG}` if orchestrated). Create `NOTES.md` immediately.

### 3) Roadmap Integration
- If `ROADMAP_FILE` exists and `### ${SLUG}` exact match found, mark `FROM_ROADMAP=true` and reuse context; otherwise treat as new. Fuzzy suggestions may be logged but never block.

### 4) Feature Classification (signal-based, non-interactive)
- Signals:
  - UI if `$ARGUMENTS` mentions: screen|page|component|dashboard|form|modal.
  - Improvement if mentions: improve|optimize|speed up|reduce time AND existing/current.
  - Metrics if mentions: track|measure|metric|engagement|retention|funnel.
  - Deployment if mentions: migration|schema|env var|infrastructure|docker|CI/CD.
- Store booleans in NOTES.md. Don’t ask; proceed with artifacts gated by signals.

### 5) Research Mode & Parallelism
- Mode: minimal (0 flags), standard (1 flag), full (≥2 flags).
- Read only what’s necessary. Independent file reads/searches may run in parallel; dependent steps remain sequential.
- Sources to consult (as applicable):
  - `docs/project/*` for stack/architecture/deploy
  - UI inventory & budgets if UI=true
  - Similar `specs/**/spec.md` by keyword
- Log findings and decisions in NOTES.md.

### 6) Artifacts
- Main spec: `specs/${SLUG}/spec.md` from `$SPEC_TEMPLATE`
  - Include: scope, Given/When/Then scenarios, FR/NFR, **Success Criteria** (measurable, user-focused, tech-agnostic), Assumptions, Dependencies, Open Questions (≤3, `[NEEDS CLARIFICATION]`).
- If Metrics=true: `design/heart-metrics.md` from `$HEART_TEMPLATE`.
- If UI=true: `design/screens.yaml` from `$SCREENS_TEMPLATE` and `design/copy.md` with real copy.
- If UI research helpful: `visuals/README.md` from `$VISUALS_TEMPLATE`.
- If Improvement=true: add Hypothesis (Problem → Solution → Prediction) inside `spec.md`.
- If Deployment=true: add “Deployment Considerations” (platform deps, env vars, breaking changes, migration, rollback).

### 7) Quality Validation (non-interactive)
- Generate `checklists/requirements.md` and autopopulate pass/fail for:
  - No implementation details in spec, testable requirements, measurable and tech-agnostic success criteria, edge cases, bounded scope.
- If >3 `[NEEDS CLARIFICATION]`, reduce to top 3 by impact; make reasonable defaults for the rest and document.
- Emit one batched `/clarify` block in the chat with options tables if any remain.

### 8) Roadmap Update (if FROM_ROADMAP)
- Move item to “In Progress”; attach Branch and Spec paths; commit.

### 9) Commit & Next Step
- Commit all created artifacts with a dynamic message. If clarifications remain, recommend `/clarify`; otherwise `/plan`.

## TOOLING RULES
- Prefer clear bash + `apply_patch` style edits and small, auditable commits. Summarize after actions.
- Use parallel reads/search only when arguments are independent; otherwise keep sequential to avoid parameter hazards.
</instructions>

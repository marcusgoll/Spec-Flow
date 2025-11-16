---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

<context>
## MENTAL MODEL

Single-pass, non-interactive pipeline:

`spec-flow → classify → research → artifacts → validate → commit → auto-progress`

- **Deterministic**: slug generation, zero blocking prompts
- **Guardrails**: prevent speculation, cite sources
- **User-value**: success criteria are measurable, tech-agnostic
- **Conditional**: UI/metrics/deployment sections enabled by flags
- **Clarify output**: use `[NEEDS CLARIFICATION]` only for **blocking** questions in `spec.md` (max 3); all other questions go into `clarify.md`

Clarification behavior:

- Treat `[NEEDS CLARIFICATION]` as **blocking**: these are questions that make it unsafe to fully define requirements or acceptance criteria.
- Hard cap of **3 blocking items** in `spec.md`:
  - Keep the 3 most critical blockers inline.
  - Move additional or non-blocking questions into `clarify.md`.
- If blocking questions remain, the spec is **allowed to block further phases**; prefer resolving them via `/clarify` before `/plan` or implementation.

**References**:

- Gherkin for scenarios (Given/When/Then) - Cucumber/Gherkin specification
- HEART metrics (Happiness, Engagement, Adoption, Retention, Task success) - Google Research
- Conventional Commits for commit messages
- Feature flags for risky changes (ship dark, plan removal)
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent making up information when creating specifications.

1. **Never speculate about existing code you have not read**

   - ❌ BAD: "The app probably uses React Router for navigation"
   - ✅ GOOD: "Let me check package.json and src/ to see what's currently used"
   - Use Glob to find files, Read to examine them before making assumptions

2. **Cite sources for technical constraints**

   - When referencing existing architecture, cite files: `package.json:12`, `tsconfig.json:5-8`
   - When referencing similar features, cite: `specs/002-auth-flow/spec.md:45`
   - Don't invent APIs, libraries, or frameworks that might not exist

3. **Admit when research is needed**

   - If uncertain about tech stack, say: "I need to read package.json and check existing code"
   - If unsure about design patterns, say: "Let me search for similar implementations"
   - Never make up database schemas, API endpoints, or component hierarchies

4. **Verify roadmap entries before referencing**

   - Before saying "This builds on feature X", search GitHub Issues or `docs/roadmap.md` for X
   - Use exact issue slugs and titles, don't paraphrase
   - If feature not in roadmap, say: "This is a new feature, not extending existing work"

5. **Quote user requirements exactly & handle clarifications correctly**

   - When documenting user needs, quote $ARGUMENTS directly
   - Don't add unstated requirements or assumptions
   - Use `[NEEDS CLARIFICATION]` **only for blocking questions** in `spec.md` (max 3)
   - All additional or non-blocking questions go into `clarify.md`
   - If blocking clarifications remain, the spec should **not** be treated as fully ready for planning or implementation until they are resolved

**Why this matters**: Hallucinated technical constraints lead to specs that can't be implemented. Specs based on non-existent code create impossible plans. Accurate specifications save 50–60% of implementation time and prevent wasting cycles on bad assumptions.
</constraints>

<instructions>
## IMPLEMENTATION

The specification workflow is implemented as a Python CLI script that **must be invoked for every `/spec` run** so behavior is deterministic and repeatable.

**Script Location**: `.spec-flow/scripts/python/spec-cli.py`

---

### 1. Mandatory execution flow

When this command runs, follow this exact sequence:

1. **Determine execution context**

   - Use the repo root as working directory.
   - Treat `$ARGUMENTS` as the single source of truth for the feature description.
   - You do **not** guess slugs yourself; the CLI owns slug generation.

2. **Always invoke the spec CLI first**

   From the repo root, use the Terminal tool to run:

   ```bash
   python .spec-flow/scripts/python/spec-cli.py "$ARGUMENTS"
````

Behavior:

* **First run (no existing spec directory)**:

  * CLI will:

    * Run preflight checks (tools, git state).
    * Generate a deterministic slug.
    * Create a new branch named after the slug.
    * Create `specs/<slug>/` with:

      * `spec.md` stub
      * `NOTES.md`
      * `design/` stubs (heart-metrics, screens, copy as needed)
      * `visuals/` stub when URLs are present
      * `checklists/requirements.md`
    * Detect roadmap entry (if any).
    * Commit the initial stubs.

* **If CLI fails because `specs/<slug>/` already exists**:

  * Treat this as “spec already initialized.”
  * Do **not** try to regenerate the directory.
  * Continue using the existing `specs/<slug>/` for reading and updating artifacts.

* **If CLI fails for any other reason** (not a git repo, missing templates, dirty working tree, etc.):

  * Stop. Surface the error.
  * Do **not** attempt to improvise spec creation without the CLI.

3. **Discover the feature slug**

   After the CLI call:

   * Parse the Terminal output to identify the slug (e.g. from the `Spec Flow: <slug>` line), or
   * Infer it from the created folder under `specs/` if needed.

   You do **not** invent a new slug; you always use the one produced by the CLI.

4. **Operate only inside the CLI-created feature directory**

   Once you know `<slug>`, all spec work must happen inside:

   * `specs/<slug>/spec.md`
   * `specs/<slug>/NOTES.md`
   * `specs/<slug>/design/...`
   * `specs/<slug>/visuals/...`
   * `specs/<slug>/clarify.md`
   * `specs/<slug>/checklists/requirements.md`

   You never create an alternative feature directory by hand. The CLI is the single source of truth for feature layout.

---

### 2. Responsibilities split: CLI vs spec agent

**CLI responsibilities (enforced by this command)**

The CLI is responsible for:

1. **Preflight Checks**

   * Validate required tools (e.g., git, jq).
   * Ensure you are inside a git repository and not on `main` / `master` for new specs.
   * Ensure working directory is clean before creating a spec.

2. **Slug Generation**

   * Deterministic slug from feature description (2–4 words, action–noun style).
   * Guard against path traversal and empty slugs.

3. **Feature Classification**

   * Auto-detect flags based on `$ARGUMENTS`:

     * `HAS_UI` (UI screens, pages, components)
     * `IS_IMPROVEMENT` (optimize/improve/enhance, etc.)
     * `HAS_METRICS` (tracking/metrics/analytics)
     * `HAS_DEPLOYMENT_IMPACT` (migration/schema/deploy/infra)
   * Derive a `flag_count` to signal complexity.

4. **Research Mode Selection**

   * Choose `minimal`, `standard`, or `full` based on `flag_count`.
   * Record the chosen research mode in `NOTES.md`.

5. **Directory Initialization & Stubs**

   * Create a feature branch named after the slug.
   * Initialize `specs/<slug>/` with:

     * `spec.md` stub (placeholder to be filled by spec agent)
     * `NOTES.md` with:

       * Overview stub
       * Research mode
       * Research findings section
       * System components analysis stub
       * Checkpoints / timestamps
       * Feature classification summary
     * `design/heart-metrics.md` stub when `HAS_METRICS` is true.
     * `design/screens.yaml` and `design/copy.md` stubs when `HAS_UI` is true.
     * `visuals/README.md` stub when URLs are present in `$ARGUMENTS`.
     * `checklists/requirements.md` with the full quality checklist.

6. **Initial Validation & Summary**

   * Count `[NEEDS CLARIFICATION]` markers in `spec.md` (on later runs when the spec is filled).
   * Summarize checklist completion (total vs completed).
   * Emit a human-readable summary of:

     * Requirements count
     * Metrics presence
     * UI screens count
     * Reusable vs new components (if present)
     * Visual research presence
     * Clarifications count
     * Artifact count

7. **Commit**

   * Stage `specs/<slug>/` and create a commit with a detailed spec-focused commit message.
   * For roadmap-linked features, update `docs/roadmap.md` and commit that change.

**Spec agent responsibilities (this prompt)**

You are responsible for turning the CLI’s **stubs** into a production-grade spec:

* Execute research based on `RESEARCH_MODE` using tools (Glob/Read/Grep/WebFetch, etc.) and document findings in `NOTES.md` with file citations.
* Generate `spec.md` from `SPEC_TEMPLATE` with all required sections:

  * Problem statement (quoting $ARGUMENTS)
  * Goals / Non-Goals
  * User scenarios (Gherkin Given/When/Then)
  * Functional Requirements (FR-001, FR-002, …)
  * Non-Functional Requirements (NFR-001, …)
  * Success Criteria (measurable, tech-agnostic; HEART-based when applicable)
  * Assumptions & Dependencies
  * Risks & Mitigations
  * Open Questions:

    * Up to 3 **blocking** items in `spec.md` with `[NEEDS CLARIFICATION]`
    * Additional questions in `clarify.md`
* Fill `design/heart-metrics.md` when `HAS_METRICS` is true:

  * One HEART section per dimension: Happiness, Engagement, Adoption, Retention, Task Success.
  * Each with definition, metric, target, and measurement source.
* Fill `design/screens.yaml` and `design/copy.md` when `HAS_UI` is true:

  * Screens, states, actions, and components (no lorem ipsum in copy).
* Fill `visuals/README.md` when it exists:

  * Summarize visual references, patterns, and relevant notes.
* Add a hypothesis section to `spec.md` when `IS_IMPROVEMENT` is true:

  * Problem (with evidence / baseline)
  * Proposed solution
  * Expected measurable impact + timeframe
* Add a deployment section to `spec.md` when `HAS_DEPLOYMENT_IMPACT` is true:

  * Platform dependencies
  * Environment variables / secrets
  * Migration steps and rollback plan
  * Downtime / compatibility considerations
* Update `checklists/requirements.md`:

  * Change each checklist item to `[x]` or `[ ]` based on reality.
  * Ensure at most 3 blocking `[NEEDS CLARIFICATION]` markers remain in `spec.md`.
  * Move any additional clarifications to `clarify.md`.

You do **not** bypass the CLI step. All your file reads and writes assume the directory structure and stubs created by `.spec-flow/scripts/python/spec-cli.py`.

---

### 3. Readiness & next steps (contract with later commands)

Based on the final spec state:

* If **any** blocking `[NEEDS CLARIFICATION]` markers remain in `spec.md`:

  * Explicitly mark the feature as **not ready for planning**.
  * Next recommended step: `/clarify` to resolve blockers before `/plan`.

* If there are **no blocking clarifications**, but the checklist is **incomplete**:

  * State that `/plan` is **not allowed** until checklist items are addressed.
  * The spec may exist, but it is not yet considered “ready.”

* Only when:

  * `spec.md` has **0 blocking clarifications**, and
  * `checklists/requirements.md` is fully checked (`[x]` everywhere that matters)

  you mark the spec as **ready for planning** and recommend:

  * Next: `/plan`
  * Optional: `/feature continue` for automated plan → tasks → implement → ship.

This enforcement makes the `/spec` command repeatable and predictable: every run calls the same CLI, uses the same directory structure, obeys the same gating rules, and refuses to proceed when the spec is still fuzzy. </instructions>

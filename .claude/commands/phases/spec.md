---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

**Flags:**
- `--interactive` : Force wait for user confirmation (no auto-proceed timeout)
- `--yes` : Skip all HITL gates (clarification + confirmation) and auto-commit (full automation)
- `--skip-clarify` : Skip upfront clarification gate only (still show confirmation before commit)
- Environment: `SPEC_FLOW_INTERACTIVE=true` for global interactive mode

<context>
## MENTAL MODEL

Pipeline with human-in-the-loop gates:

`[CLARIFICATION GATE] → spec-flow → classify → research → artifacts → [CONFIRMATION GATE] → commit → [DECISION TREE]`

- **Deterministic**: slug generation, predictable workflows
- **Guardrails**: prevent speculation, cite sources, human confirmation before commit
- **User-value**: success criteria are measurable, tech-agnostic
- **Conditional**: UI/metrics/deployment sections enabled by flags
- **HITL gates (3 total)**:
  1. **Clarification** (upfront): Detects ambiguous input, asks targeted questions (max 3)
  2. **Confirmation** (before commit): Shows quality summary, 10s timeout
  3. **Decision tree** (after commit): Executable next-step commands
- **Automation-friendly**: `--yes` skips all gates, `--skip-clarify` skips only gate #1, `/feature continue` skips all
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

### 0.5. Clarification Gate (Upfront - HITL)

**Before invoking the CLI**, analyze `$ARGUMENTS` for ambiguity and ask targeted questions if needed.

**Check for --skip-clarify flag:**

```python
skip_clarify = "--skip-clarify" in args or "--no-clarify" in args
auto_yes = "--yes" in args

if skip_clarify or auto_yes:
    print("Skipping clarification gate (--skip-clarify or --yes flag)")
    # Proceed directly to CLI invocation
```

**Analyze user input for ambiguity:**

```python
# Extract $ARGUMENTS
user_input = "$ARGUMENTS"

# Ambiguity detection (Claude Code implements with reasoning)
ambiguities = []

# 1. Check for vague scope
if matches_pattern(user_input, ["dashboard", "feature", "system", "tool", "app"]):
    if not has_specificity(user_input):
        ambiguities.append({
            "category": "SCOPE",
            "question": "What specific type of [X] are you building?",
            "why": "Generic terms like 'dashboard' can mean many things",
            "examples": ["Admin dashboard vs user-facing analytics", "Internal tool vs customer feature"]
        })

# 2. Check for missing target user
if not contains(user_input, ["user", "admin", "developer", "customer", "for"]):
    ambiguities.append({
        "category": "TARGET_USER",
        "question": "Who is the primary user of this feature?",
        "why": "User type affects requirements and success criteria",
        "examples": ["End users", "Administrators", "Developers", "External customers"]
    })

# 3. Check for missing success criteria
if not contains(user_input, ["so that", "in order to", "goal", "improve", "enable", "reduce"]):
    ambiguities.append({
        "category": "SUCCESS",
        "question": "What's the measurable outcome you want to achieve?",
        "why": "Success criteria define when the feature is complete",
        "examples": ["Reduce support tickets by 30%", "Enable users to self-serve", "Improve conversion by 15%"]
    })

# 4. Check for missing context (only if not greenfield)
if has_existing_codebase() and not contains(user_input, ["like", "similar to", "extends", "integrates with"]):
    ambiguities.append({
        "category": "CONTEXT",
        "question": "Does this extend an existing feature or integrate with existing code?",
        "why": "Understanding integration points prevents architectural conflicts",
        "examples": ["Extends user profiles", "Integrates with billing system", "New standalone feature"]
    })

# 5. Check for vague adjectives without metrics
vague_terms = ["fast", "slow", "easy", "simple", "robust", "scalable", "performant"]
if any(term in user_input.lower() for term in vague_terms):
    ambiguities.append({
        "category": "METRICS",
        "question": "What specific metrics define 'fast' / 'scalable' / 'robust' for this feature?",
        "why": "Vague quality terms need measurable targets",
        "examples": ["Response time <500ms", "Handle 10k concurrent users", "99.9% uptime"]
    })
```

**Present clarification questions if detected:**

```
<if len(ambiguities) >= 2>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Clarification Needed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I'll create a specification for: "$ARGUMENTS"

Before proceeding, let me clarify a few things to ensure a high-quality spec:

<for each ambiguity in ambiguities[:3]>
### Q{index}: {ambiguity.category}

**Why I'm asking:** {ambiguity.why}

**Question:** {ambiguity.question}

**Examples:** {', '.join(ambiguity.examples)}

**Your answer:** [type here or say 'skip']

</for>

You can answer any/all, or type 'continue' to proceed with current description.
```

**Handle clarification responses:**

```python
# Use AskUserQuestion tool for interactive clarification
responses = []

for ambiguity in ambiguities[:3]:  # Max 3 questions
    answer = AskUserQuestion(
        questions=[{
            "question": ambiguity["question"],
            "header": ambiguity["category"],
            "multiSelect": False,
            "options": [
                {"label": ex, "description": f"This feature targets {ex}"}
                for ex in ambiguity["examples"]
            ]
        }]
    )

    if answer != "skip" and answer != "":
        responses.append(answer)

# Enrich $ARGUMENTS with clarifications
if len(responses) > 0:
    enriched_input = f"{user_input}\n\n[CLARIFICATIONS]:\n"
    for i, response in enumerate(responses):
        enriched_input += f"- {ambiguities[i]['category']}: {response}\n"

    print(f"\n✅ Enriched description with {len(responses)} clarifications")
    print(f"\nProceeding with: {enriched_input}")

    # Use enriched input for CLI invocation
    ARGUMENTS_ENRICHED = enriched_input
else:
    print("\n→ Proceeding with original description")
    ARGUMENTS_ENRICHED = user_input
```

**Automation mode:** When invoked by `/feature continue` or with `--skip-clarify` flag, skip this gate entirely.

---

### 1. Mandatory execution flow

When this command runs, follow this exact sequence:

1. **Determine execution context**

   - Use the repo root as working directory.
   - Treat `$ARGUMENTS` (or `$ARGUMENTS_ENRICHED` if clarifications added) as the single source of truth for the feature description.
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

### 2.5. Confirmation Gate (HITL - Before Commit)

After filling all artifacts but **before committing**, show a summary and request confirmation.

**Extract spec metrics:**

```python
# Read generated artifacts
spec_content = read_file(f"specs/{slug}/spec.md")
checklist_content = read_file(f"specs/{slug}/checklists/requirements.md")

# Count elements
fr_count = count_matches(r"^FR-\d+:", spec_content)
nfr_count = count_matches(r"^NFR-\d+:", spec_content)
scenario_count = count_matches(r"^Scenario:", spec_content)
blocking_count = count_matches(r"\[NEEDS CLARIFICATION\]", spec_content)

# Checklist completion
total_items = count_matches(r"^- \[[ x]\]", checklist_content)
completed_items = count_matches(r"^- \[x\]", checklist_content)
completion_pct = (completed_items / total_items * 100) if total_items > 0 else 0

# Determine readiness
ready_for_planning = (blocking_count == 0 and completion_pct == 100)
```

**Display confirmation prompt:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Specification Generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: <slug>
Location: specs/<slug>/

**Generated Artifacts:**
✓ spec.md (<line_count> lines)
✓ NOTES.md (research findings)
<if HAS_UI>
✓ design/screens.yaml (<screen_count> screens)
✓ design/copy.md
</if>
<if HAS_METRICS>
✓ design/heart-metrics.md
</if>
<if visuals exist>
✓ visuals/README.md
</if>
✓ checklists/requirements.md

**Specification Quality:**
- Functional requirements: <fr_count>
- Non-functional requirements: <nfr_count>
- User scenarios: <scenario_count>
- Blocking clarifications: <blocking_count>
- Checklist completion: <completed_items>/<total_items> (<completion_pct>%)
- Ready for planning: <Yes | No>

Should I commit this specification?

1. Commit and continue [RECOMMENDED]
   Proceeds to decision tree for next steps

2. Let me review first
   Pauses to allow manual review of generated files

3. Adjust specification
   Allows edits before committing

4. Cancel
   Exits without committing

<if not --interactive flag>
Auto-proceeding in 10 seconds... (press any key to choose manually)
</if>

Choose (1-4):
```

**Handle user choice:**

```python
# Check for flags
interactive_mode = "--interactive" in args or os.getenv("SPEC_FLOW_INTERACTIVE") == "true"
auto_yes = "--yes" in args or "--no-confirm" in args

if auto_yes:
    choice = "1"
    print("Auto-confirming (--yes flag detected)")
elif not interactive_mode:
    # Show 10s countdown, allow interrupt
    choice = wait_with_timeout(10, default="1")
else:
    # Force wait for user input
    choice = input("Your choice: ")

if choice == "1":
    # Proceed to commit
    print("Committing specification...")
    # Continue to commit step below

elif choice == "2":
    print(f"\n📂 Review these files:")
    print(f"  - specs/{slug}/spec.md")
    print(f"  - specs/{slug}/NOTES.md")
    if HAS_UI:
        print(f"  - specs/{slug}/design/screens.yaml")
        print(f"  - specs/{slug}/design/copy.md")
    print(f"  - specs/{slug}/checklists/requirements.md")
    print(f"\nWhen ready, type 'commit' to proceed:")

    confirm = input().strip().lower()
    if confirm == "commit":
        print("Committing specification...")
        # Continue to commit step below
    else:
        print("Cancelled. Run /spec again when ready.")
        exit(0)

elif choice == "3":
    adjustment = AskUserQuestion(
        questions=[{
            "question": "What would you like to adjust?",
            "header": "Adjustment",
            "multiSelect": False,
            "options": [
                {
                    "label": "Problem scope",
                    "description": "Refine the problem statement or goals"
                },
                {
                    "label": "Requirements",
                    "description": "Add/remove/modify functional or non-functional requirements"
                },
                {
                    "label": "Success criteria",
                    "description": "Adjust measurable outcomes or HEART metrics"
                },
                {
                    "label": "UI design",
                    "description": "Modify screens, states, or copy"
                }
            ]
        }]
    )

    # Apply adjustment (re-run specific spec generation section)
    print(f"Please edit the files manually, then run /spec again to regenerate.")
    exit(0)

elif choice == "4":
    print("Cancelled. Specification not committed.")
    print("Files remain in: specs/{slug}/ (uncommitted)")
    exit(0)
```

**Commit artifacts after confirmation:**

```bash
# Stage all spec artifacts
git add specs/<slug>/

# Create detailed commit message
COMMIT_MSG="spec: complete specification for <slug>

[SPECIFICATION SUMMARY]
- Functional requirements: <fr_count>
- Non-functional requirements: <nfr_count>
- User scenarios: <scenario_count>
- Blocking clarifications: <blocking_count>
- Checklist completion: <completion_pct>%

[ARTIFACTS]
- spec.md (<line_count> lines)
- NOTES.md (research findings)
<list other artifacts>

<if blocking_count > 0>
⚠️  <blocking_count> ambiguities remain - recommend /clarify before /plan
</if>

<if ready_for_planning>
✓ Ready for /plan
</if>

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit
git commit -m "$COMMIT_MSG"

# Verify commit succeeded
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "✅ Specification committed: $COMMIT_HASH"
```

**Automation mode:** When invoked by `/feature continue` or with `--yes` flag, skip confirmation gate and auto-commit.

---

### 3. Readiness & Decision Tree (HITL Gate)

After committing the specification, present an **executable decision tree** based on the spec state.

**Determine spec readiness:**

```python
# Count blocking clarifications
blocking_count = count("[NEEDS CLARIFICATION]" in spec.md)

# Check checklist completion
checklist_complete = all items in checklists/requirements.md are [x]

# Determine readiness state
if blocking_count > 0:
    state = "BLOCKED_CLARIFICATIONS"
elif not checklist_complete:
    state = "BLOCKED_CHECKLIST"
else:
    state = "READY"
```

**Present decision tree:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Specification Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: <slug>
Spec: specs/<slug>/spec.md

**Status:**
- Functional requirements: <count>
- User scenarios: <count>
- Blocking clarifications: <blocking_count>
- Checklist completion: <completed>/<total>
- Ready for planning: <Yes | No>

What's next?

<if state == "BLOCKED_CLARIFICATIONS">
**⚠️  Spec has ambiguities that need resolution**

1. Resolve ambiguities first (/clarify) [RECOMMENDED]
   Duration: ~5-10 min
   Impact: Prevents rework in planning phase

2. Proceed to planning anyway (/plan)
   ⚠️  May require plan revisions when ambiguities clarified

3. Review spec.md manually
   Location: specs/<slug>/spec.md

4. Continue automated workflow (/feature continue)
   Will attempt /clarify → /plan → /tasks → /implement

Choose (1-4):
</if>

<if state == "BLOCKED_CHECKLIST">
**⚠️  Quality checklist incomplete**

1. Review checklist and complete items
   Location: specs/<slug>/checklists/requirements.md

2. Proceed to planning anyway (/plan)
   ⚠️  May not meet quality standards

3. Continue automated workflow (/feature continue)

Choose (1-3):
</if>

<if state == "READY">
**✅ Spec is ready for planning**

1. Generate implementation plan (/plan) [RECOMMENDED]
   Duration: ~10-15 min
   Output: Architecture decisions, component reuse analysis

2. Continue automated workflow (/feature continue)
   Executes: /plan → /tasks → /implement → /optimize → /ship
   Duration: ~60-90 min (full feature delivery)

3. Review spec.md first
   Location: specs/<slug>/spec.md

Choose (1-3):
</if>
```

**Execute user choice via SlashCommand tool:**

```python
if choice == 1:
    if state == "BLOCKED_CLARIFICATIONS":
        SlashCommand(f"/clarify {slug}")
    elif state == "BLOCKED_CHECKLIST":
        # Open checklist for review, then wait
        print(f"Review and update: specs/{slug}/checklists/requirements.md")
        print("Run /plan when ready")
    else:  # READY
        SlashCommand(f"/plan {slug}")

elif choice == 2:
    if state in ["BLOCKED_CLARIFICATIONS", "BLOCKED_CHECKLIST"]:
        confirm = AskUserQuestion(
            "⚠️  Proceeding with blockers may require rework. Continue? (yes/no)"
        )
        if confirm == "yes":
            SlashCommand(f"/plan {slug}")
    else:  # READY
        SlashCommand(f"/feature continue {slug}")

elif choice == 3:
    if state in ["BLOCKED_CLARIFICATIONS", "BLOCKED_CHECKLIST"]:
        print(f"Review complete. Run /clarify or /plan when ready.")
    else:  # READY
        print(f"Review complete. Run /plan when ready.")

elif choice == 4 and state == "BLOCKED_CLARIFICATIONS":
    SlashCommand(f"/feature continue {slug}")
```

**Automation mode:** When invoked by `/feature continue`, skip decision tree and auto-proceed based on state:
- `BLOCKED_CLARIFICATIONS` → auto-run `/clarify`
- `BLOCKED_CHECKLIST` → auto-run `/plan` (log warning)
- `READY` → auto-run `/plan`

This enforcement makes the `/spec` command repeatable and predictable: every run calls the same CLI, uses the same directory structure, obeys the same gating rules, presents clear next steps, and executes commands on user request. </instructions>

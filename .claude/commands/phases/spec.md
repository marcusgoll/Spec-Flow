---
name: spec
description: Generate complete feature specification with research, requirements analysis, and quality gates
argument-hint: <feature-description> [--interactive] [--yes] [--skip-clarify]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash(git *), Bash(python .spec-flow/scripts/*), AskUserQuestion, SlashCommand]
---

# /spec — Feature Specification Generator

<context>
**User Input**: $ARGUMENTS

**Current Git Status**: !`git status --short 2>$null || echo "clean"`

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Existing Specs**: !`dir /b /ad specs 2>$null | head -10 || echo "none"`

**Project Documentation**: !`dir /b docs\project\*.md 2>$null | head -5 || echo "none"`

**Roadmap**: !`gh issue list --label roadmap --limit 5 2>$null || echo "none"`

**Specification Artifacts** (after execution):
- @specs/NNN-slug/spec.md
- @specs/NNN-slug/NOTES.md
- @specs/NNN-slug/checklists/requirements.md
- @specs/NNN-slug/workflow-state.yaml
</context>

<objective>
Generate a production-grade feature specification from natural language input.

Specification workflow:
1. Analyze user input for ambiguity (clarification gate)
2. Invoke Python CLI for deterministic slug generation and artifact creation
3. Classify feature type and research mode
4. Generate requirements (functional + non-functional) with FR-XXX/NFR-XXX identifiers
5. Create user scenarios using Gherkin format (Given/When/Then)
6. Validate quality with automated checklist
7. Present confirmation gate before committing
8. Commit to git with detailed summary
9. Show decision tree for next steps

**Mental Model - Pipeline with HITL Gates**:

```
[CLARIFICATION GATE] → spec-flow → classify → research → artifacts → [CONFIRMATION GATE] → commit → [DECISION TREE]
```

**Key principles**:
- **Deterministic**: Slug generation and directory structure are predictable
- **Guardrails**: Prevent speculation, cite sources, require human confirmation before commit
- **User-value**: Success criteria are measurable and tech-agnostic
- **Conditional**: UI/metrics/deployment sections enabled by classification flags
- **HITL gates (3 total)**:
  1. **Clarification** (upfront): Detects ambiguous input, asks targeted questions (max 3)
  2. **Confirmation** (before commit): Shows quality summary with 10s timeout
  3. **Decision tree** (after commit): Executable next-step commands
- **Automation-friendly**: `--yes` skips all gates, `--skip-clarify` skips only gate #1

**Clarification Behavior**:
- Use `[NEEDS CLARIFICATION]` **only for blocking questions** in spec.md (max 3)
- Blocking = questions that make it unsafe to define requirements or acceptance criteria
- Additional or non-blocking questions go into `clarify.md`
- If blocking questions remain, spec is allowed to block further phases

**Flags**:
- `--interactive`: Force wait for user confirmation (no auto-proceed timeout)
- `--yes`: Skip all HITL gates (clarification + confirmation) and auto-commit (full automation)
- `--skip-clarify`: Skip upfront clarification gate only (still show confirmation before commit)
- Environment: `SPEC_FLOW_INTERACTIVE=true` for global interactive mode

**References**:
- Gherkin for scenarios (Given/When/Then)
- HEART metrics (Happiness, Engagement, Adoption, Retention, Task success)
- Conventional Commits for commit messages
- Feature flags for risky changes

**Workflow position**: `spec → clarify? → plan → tasks → implement → optimize → preview → ship`
</objective>

## Anti-Hallucination Rules

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
   - Use `[NEEDS CLARIFICATION]` **only for blocking questions** in spec.md (max 3)
   - All additional or non-blocking questions go into `clarify.md`
   - If blocking clarifications remain, the spec should **not** be treated as fully ready for planning or implementation until they are resolved

**Why this matters**: Hallucinated technical constraints lead to specs that can't be implemented. Specs based on non-existent code create impossible plans. Accurate specifications save 50–60% of implementation time and prevent wasting cycles on bad assumptions.

---

<process>

### Step 0: Clarification Gate (Upfront HITL)

**Before invoking the CLI**, analyze `$ARGUMENTS` for ambiguity and ask targeted questions if needed.

**Check for --skip-clarify flag:**
```bash
if [[ "$ARGUMENTS" == *"--skip-clarify"* ]]; then
  echo "Skipping clarification gate per --skip-clarify flag"
  SKIP_CLARIFY=true
fi
```

**If not skipped, analyze for ambiguity:**

```python
# Parse user input
user_input = extract_feature_description_from($ARGUMENTS)

# Detect ambiguity signals
ambiguity_signals = [
    "vague verbs": ["improve", "enhance", "optimize", "better"],
    "missing actors": no "user", "admin", "system" mentioned,
    "unclear scope": ["everything", "all", "comprehensive"],
    "missing constraints": no time/performance/scale mentioned
]

# Count ambiguity score
ambiguity_count = sum([1 for signal in ambiguity_signals if detected(user_input)])

# Decision
if ambiguity_count >= 2:
    clarification_needed = True
else:
    clarification_needed = False
```

**If clarification needed:**

Use AskUserQuestion tool to ask **max 3 targeted questions**:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Who is the primary user for this feature?",
      header: "User",
      multiSelect: false,
      options: [
        {label: "End user", description: "Direct application user"},
        {label: "Admin", description: "System administrator"},
        {label: "Developer", description: "API consumer or integrator"}
      ]
    },
    {
      question: "What's the expected scale?",
      header: "Scale",
      multiSelect: false,
      options: [
        {label: "< 1K users", description: "Small scale"},
        {label: "1K-10K users", description: "Medium scale"},
        {label: "10K+ users", description: "Large scale"}
      ]
    },
    {
      question: "Are there performance requirements?",
      header: "Performance",
      multiSelect: false,
      options: [
        {label: "Standard (< 2s)", description: "Normal web response"},
        {label: "Fast (< 500ms)", description: "Real-time feel"},
        {label: "No requirement", description: "Best effort"}
      ]
    }
  ]
});
```

**Enrich $ARGUMENTS with clarification answers:**

```python
# After receiving answers
enriched_input = f"{user_input} [Primary user: {user_answer}] [Scale: {scale_answer}] [Performance: {perf_answer}]"

# Use enriched_input when calling CLI
```

### Step 1: Invoke Python CLI

**Execute centralized spec-cli script:**

```bash
python .spec-flow/scripts/spec-cli.py "$ARGUMENTS"
```

**What the CLI does** (deterministic behavior):

1. **Generate slug**: Convert feature description to kebab-case slug (e.g., "user-profile-editing")
2. **Create directory structure**:
   ```
   specs/<NNN-slug>/
     ├── spec.md
     ├── NOTES.md
     ├── checklists/
     │   └── requirements.md
     ├── visuals/
     │   └── README.md
     └── workflow-state.yaml
   ```
3. **Classify feature type**:
   - UI feature (has screens/components)
   - Backend feature (API/data processing)
   - Infrastructure (deployment/monitoring)
   - Mixed (multiple subsystems)
4. **Determine research mode**:
   - Greenfield (new capability)
   - Brownfield (extends existing code)
   - Refactoring (improves existing)
5. **Generate artifacts**:
   - spec.md with templates
   - requirements checklist
   - workflow state initialization
6. **Return metadata**: slug, paths, classification, research mode

### Step 2: Fill Specification Artifacts

**Read generated spec.md template and fill sections:**

**a) Problem Statement**:
- Quote user input from $ARGUMENTS
- Explain pain point or opportunity
- Cite existing issues if applicable (GitHub issue numbers)

**b) Goals & Success Criteria**:
- Define measurable outcomes
- Use HEART metrics if user-facing feature
- Tech-agnostic success definition

**c) User Scenarios** (Gherkin format):
```gherkin
Scenario: User edits profile information
  Given the user is logged in
  And they navigate to the profile page
  When they update their email address
  And click "Save Changes"
  Then the system validates the email format
  And saves the updated profile
  And displays a success confirmation
```

**d) Functional Requirements** (FR-XXX):
```markdown
- **FR-001**: System SHALL allow users to edit profile information
- **FR-002**: System SHALL validate email format before saving
- **FR-003**: System SHALL display confirmation after successful save
```

**e) Non-Functional Requirements** (NFR-XXX):
```markdown
- **NFR-001**: Profile update SHALL complete within 2 seconds (p95)
- **NFR-002**: System SHALL handle concurrent profile edits gracefully
- **NFR-003**: Profile data SHALL be persisted atomically (no partial updates)
```

**f) Out of Scope**:
- Explicitly document what this feature does NOT include
- Prevents scope creep during implementation

**g) Risks & Assumptions**:
- Technical risks (dependencies, complexity)
- Assumptions about users, environment, constraints

**h) Open Questions** (if any):
- Use `[NEEDS CLARIFICATION]` for **blocking questions only** (max 3)
- Move non-blocking questions to `clarify.md`

### Step 3: Generate Quality Checklist

**Update checklists/requirements.md:**

```markdown
# Requirements Quality Checklist

## Completeness
- [ ] All functional requirements have FR-XXX identifiers
- [ ] All non-functional requirements have NFR-XXX identifiers
- [ ] Success criteria are measurable
- [ ] User scenarios cover happy path and error cases
- [ ] Out of scope is explicitly documented

## Clarity
- [ ] Requirements use SHALL/SHOULD/MAY consistently
- [ ] No ambiguous terms (improve, enhance, better)
- [ ] Actors are clearly identified (user, system, admin)
- [ ] No implementation details in requirements

## Testability
- [ ] Each requirement can be verified with test
- [ ] Acceptance criteria include pass/fail conditions
- [ ] Performance targets are quantified (if applicable)

## Feasibility
- [ ] Technical risks are documented
- [ ] Dependencies are identified
- [ ] Assumptions are stated explicitly
```

### Step 4: Confirmation Gate (Before Commit HITL)

**Calculate quality metrics:**

```python
# Count requirements
fr_count = count("FR-" in spec.md)
nfr_count = count("NFR-" in spec.md)
scenario_count = count("Scenario:" in spec.md)

# Count blocking clarifications
blocking_count = count("[NEEDS CLARIFICATION]" in spec.md)

# Calculate checklist completion
checklist_items = count("- [ ]" in checklists/requirements.md)
checklist_completed = count("- [x]" in checklists/requirements.md)
checklist_pct = (checklist_completed / checklist_items) * 100

# Determine readiness
ready = (blocking_count == 0 and checklist_pct >= 80)
```

**Show confirmation summary:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Specification Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: <slug>
Location: specs/<NNN-slug>/

**Content:**
- Functional requirements: {fr_count}
- Non-functional requirements: {nfr_count}
- User scenarios: {scenario_count}
- Blocking clarifications: {blocking_count}

**Quality:**
- Checklist completion: {checklist_pct}%
- Ready for planning: {ready ? "Yes" : "No"}

**Files:**
- spec.md
- NOTES.md
- checklists/requirements.md
- workflow-state.yaml

Commit this specification? [Y/n] (auto-proceed in 10s)
```

**Handle user response:**

```python
# Check for --yes flag (skip confirmation)
if "--yes" in $ARGUMENTS:
    confirmation = "yes"
else:
    # Show timeout if not --interactive
    if "--interactive" in $ARGUMENTS or SPEC_FLOW_INTERACTIVE == "true":
        confirmation = AskUserQuestion("Commit specification?", ["Yes", "No", "Review first"])
    else:
        # 10-second timeout, default to Yes
        confirmation = wait_for_input(timeout=10, default="yes")
```

**If No or Review first:**
- Exit without committing
- Show file locations for manual review
- Tell user to run `/spec continue` when ready

**If Yes (or timeout):**
- Proceed to git commit

### Step 5: Commit Specification

**Create feature branch and commit:**

```bash
# Create branch
git checkout -b feature/<NNN-slug>

# Stage files
git add specs/<NNN-slug>/

# Create commit
git commit -m "spec: add specification for <feature-title>

Feature: <slug>
Type: <classification>
Research mode: <research-mode>

Content:
- Functional requirements: {fr_count}
- Non-functional requirements: {nfr_count}
- User scenarios: {scenario_count}

Quality:
- Checklist completion: {checklist_pct}%
- Blocking clarifications: {blocking_count}

Next: /clarify (if blockers) or /plan

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Step 6: Decision Tree (Post-Commit HITL)

**Determine spec state and present decision tree:**

```python
# Determine state
if blocking_count > 0:
    state = "BLOCKED_CLARIFICATIONS"
elif checklist_pct < 80:
    state = "BLOCKED_CHECKLIST"
else:
    state = "READY"
```

**Present executable options:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Specification Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: <slug>
Spec: specs/<slug>/spec.md

**Status:**
- Functional requirements: {fr_count}
- User scenarios: {scenario_count}
- Blocking clarifications: {blocking_count}
- Checklist completion: {checklist_pct}%
- Ready for planning: {state == "READY" ? "Yes" : "No"}

What's next?

<if state == "BLOCKED_CLARIFICATIONS">
⚠️ Spec has ambiguities that need resolution

1. Resolve ambiguities first (/clarify) [RECOMMENDED]
   Duration: ~5-10 min
   Impact: Prevents rework in planning phase

2. Proceed to planning anyway (/plan)
   ⚠️ May require plan revisions when ambiguities clarified

3. Review spec.md manually
   Location: specs/<slug>/spec.md

4. Continue automated workflow (/feature continue)
   Will attempt /clarify → /plan → /tasks → /implement

Choose (1-4):
</if>

<if state == "BLOCKED_CHECKLIST">
⚠️ Quality checklist incomplete

1. Review checklist and complete items
   Location: specs/<slug>/checklists/requirements.md

2. Proceed to planning anyway (/plan)
   ⚠️ May not meet quality standards

3. Continue automated workflow (/feature continue)

Choose (1-3):
</if>

<if state == "READY">
✅ Spec is ready for planning

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
        print(f"Review and update: specs/{slug}/checklists/requirements.md")
        print("Run /plan when ready")
    else:  # READY
        SlashCommand(f"/plan {slug}")

elif choice == 2:
    if state in ["BLOCKED_CLARIFICATIONS", "BLOCKED_CHECKLIST"]:
        confirm = AskUserQuestion("⚠️ Proceeding with blockers may require rework. Continue?", ["Yes", "No"])
        if confirm == "Yes":
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

**Automation mode**: When invoked by `/feature continue`, skip decision tree and auto-proceed:
- `BLOCKED_CLARIFICATIONS` → auto-run `/clarify`
- `BLOCKED_CHECKLIST` → auto-run `/plan` (log warning)
- `READY` → auto-run `/plan`

</process>

<success_criteria>
**Specification successfully created when:**

1. **Artifacts generated**:
   - spec.md exists with all required sections
   - NOTES.md initialized
   - checklists/requirements.md created
   - workflow-state.yaml initialized

2. **Requirements documented**:
   - All functional requirements have FR-XXX identifiers (unique, sequential)
   - All non-functional requirements have NFR-XXX identifiers (unique, sequential)
   - User scenarios use Gherkin format (Given/When/Then)
   - Success criteria are measurable

3. **Quality validated**:
   - No more than 3 `[NEEDS CLARIFICATION]` markers in spec.md
   - Checklist completion ≥80% OR explicit decision to proceed
   - All technical constraints have source citations (file:line)

4. **Git committed**:
   - Feature branch created: feature/<NNN-slug>
   - All artifacts committed with detailed commit message
   - Commit follows Conventional Commits format

5. **Next steps presented**:
   - User receives decision tree with executable options
   - State-appropriate recommendations provided (clarify, plan, or continue)
   - SlashCommand tool invoked for user's choice
</success_criteria>

<verification>
**Before committing specification, verify:**

1. **Check spec.md completeness**:
   ```bash
   grep -c "^## Problem" specs/*/spec.md  # Should be 1
   grep -c "^## Goals" specs/*/spec.md    # Should be 1
   grep -c "^## User Scenarios" specs/*/spec.md  # Should be 1
   ```

2. **Verify requirement identifiers are unique**:
   ```bash
   grep "^- \*\*FR-" specs/*/spec.md | sort | uniq -d  # Should be empty
   grep "^- \*\*NFR-" specs/*/spec.md | sort | uniq -d  # Should be empty
   ```

3. **Count blocking clarifications**:
   ```bash
   grep -c "\[NEEDS CLARIFICATION\]" specs/*/spec.md  # Should be ≤3
   ```

4. **Validate checklist completion**:
   ```bash
   grep -c "\- \[x\]" specs/*/checklists/requirements.md
   grep -c "\- \[ \]" specs/*/checklists/requirements.md
   # Calculate percentage: completed / (completed + incomplete)
   ```

5. **Confirm all citations have file:line references**:
   ```bash
   grep "package.json" specs/*/spec.md | grep -v ":[0-9]"  # Should be empty
   ```

6. **Check git branch created**:
   ```bash
   git branch --show-current  # Should be "feature/<slug>"
   ```

**Never claim specification is complete without running these verification checks.**
</verification>

<output>
**Files created/modified by this command:**

**Specification artifacts** (specs/NNN-slug/):
- spec.md — Complete feature specification with requirements, scenarios, success criteria
- NOTES.md — Implementation notes, decisions, and context
- checklists/requirements.md — Quality checklist for requirement validation
- visuals/README.md — Placeholder for mockups, diagrams, screenshots
- workflow-state.yaml — Workflow tracking (phase status, gates, metadata)

**Git operations**:
- Branch: feature/NNN-slug created
- Commit: Specification files committed with detailed message

**Console output**:
- Specification summary (requirements count, quality metrics)
- Decision tree with next-step options
- Executable command suggestions based on state
</output>

---

## Quick Reference

### Automation Flags

- `--interactive`: Force manual confirmation (no auto-proceed)
- `--yes`: Skip all HITL gates and auto-commit (CI-friendly)
- `--skip-clarify`: Skip clarification gate only
- `SPEC_FLOW_INTERACTIVE=true`: Global interactive mode (environment variable)

### Clarification Behavior

- **Blocking questions**: Max 3 in spec.md using `[NEEDS CLARIFICATION]`
- **Non-blocking questions**: Unlimited in `clarify.md`
- **Threshold**: If ≥2 ambiguity signals detected, ask max 3 questions upfront

### Decision Tree States

- **BLOCKED_CLARIFICATIONS**: Has `[NEEDS CLARIFICATION]` markers → recommend `/clarify`
- **BLOCKED_CHECKLIST**: Quality checklist <80% complete → recommend review
- **READY**: No blockers, checklist ≥80% → recommend `/plan`

### Common Patterns

**Skip all gates for automation:**
```bash
/spec "user profile editing" --yes
```

**Interactive mode with upfront clarification:**
```bash
/spec "payment processing" --interactive
```

**Skip clarification but keep confirmation:**
```bash
/spec "dashboard widgets" --skip-clarify
```

### File Structure

```
specs/001-user-profile-editing/
├── spec.md                      # Main specification
├── NOTES.md                     # Implementation notes
├── checklists/
│   └── requirements.md          # Quality checklist
├── visuals/
│   └── README.md                # Mockups placeholder
└── workflow-state.yaml          # Workflow tracking
```

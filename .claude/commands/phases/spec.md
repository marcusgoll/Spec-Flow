---
name: spec
description: Generate complete feature specification with research, requirements analysis, and quality validation
argument-hint: <feature-description> [--skip-clarify]
allowed-tools: [Read, Bash, Task, AskUserQuestion]
version: 11.0
updated: 2025-12-09
---

# /spec — Feature Specification Generator (Thin Wrapper)

> **v11.0 Architecture**: This command is now a thin wrapper that spawns the isolated `spec-phase-agent` via Task(). All specification logic runs in an isolated context with question batching for user interaction.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated spec-phase-agent to generate production-grade feature specification.

**Architecture (v11.0 - Full Phase Isolation):**

```
/spec command (this file)
    │
    ▼
┌──────────────────────────────────────────────────────┐
│ 1. Detect feature directory                          │
│ 2. Initialize interaction-state.yaml if needed       │
│ 3. Check for pending answers from previous session   │
│ 4. Spawn Task(spec-phase-agent)                      │
│ 5. Handle agent result:                              │
│    - needs_input → AskUserQuestion → re-spawn        │
│    - completed → update state.yaml                   │
│    - failed → log error, pause workflow              │
└──────────────────────────────────────────────────────┘
```

**Benefits:**
- Main context stays lightweight (no spec details in memory)
- Unlimited specification complexity
- Resumable at any point
- Observable Q&A history in interaction-state.yaml

**Workflow position**: `spec → clarify? → plan → tasks → implement → optimize → ship`
</objective>

<process>

## Step 0: Ultrathink Checkpoint — Think Different

> **Philosophy**: "Is this solving the real problem or a symptom?"

Before generating any specification, pause to question assumptions.

**Display thinking prompt:**

```
┌─────────────────────────────────────────────────────────────┐
│ 💭 ULTRATHINK CHECKPOINT: Think Different                   │
├─────────────────────────────────────────────────────────────┤
│ Before specifying, consider:                                │
│                                                             │
│ • Is this the REAL problem or just a symptom?               │
│ • What assumptions are we making about users?               │
│ • What would the simplest solution look like?               │
│ • Is this a feature, or a symptom of a missing feature?     │
└─────────────────────────────────────────────────────────────┘
```

**Create assumption inventory** (inline in spec.md):

```markdown
## Assumption Inventory

| # | Assumption | Source | Challenge | Status |
|---|------------|--------|-----------|--------|
| 1 | [assumption from user input] | User request | [challenge question] | [validated/changed/removed] |
```

**Complexity check** - determine thinking depth:

```bash
# Check ultrathink config
ULTRATHINK_CONFIG=".spec-flow/config/ultrathink-integration.yaml"

# For spec phase, checkpoint always triggers (lightweight)
# but assumption inventory depth varies:
# - Trivial: Skip inventory, just proceed
# - Standard: Inline inventory in spec.md
# - Complex/Epic: Separate assumption-inventory.md artifact
```

**Quick assumption questions** (ask if ambiguity detected):

```json
{
  "question": "Before we specify, let's validate the core assumption. What problem is this REALLY solving?",
  "header": "Real Problem",
  "multiSelect": false,
  "options": [
    {"label": "As stated", "description": "The user's description captures the real problem"},
    {"label": "Symptom of larger issue", "description": "This is a symptom - we should address the root cause"},
    {"label": "Needs reframing", "description": "The problem statement needs to be reframed"}
  ]
}
```

**If "Symptom" or "Needs reframing" selected**, prompt for clarification before proceeding.

---

## Step 1: Detect Feature Directory

```bash
FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
STATE_FILE="$FEATURE_DIR/state.yaml"
INTERACTION_FILE="$FEATURE_DIR/interaction-state.yaml"

# For new features, FEATURE_DIR may not exist yet
# The spec-phase-agent will create it
if [ -z "$FEATURE_DIR" ]; then
    echo "📋 Creating new feature specification..."
    FEATURE_DIR="specs/NEW"  # Placeholder, agent will create actual directory
fi
```

## Step 2: Initialize Interaction State

```bash
# Initialize interaction state if feature exists but no interaction file
if [ -d "$FEATURE_DIR" ] && [ ! -f "$INTERACTION_FILE" ]; then
    bash .spec-flow/scripts/bash/interaction-manager.sh init "$FEATURE_DIR"
fi
```

## Step 3: Check for Pending Answers

```bash
# Check for pending questions from previous session
PENDING=$(bash .spec-flow/scripts/bash/interaction-manager.sh get-pending "$FEATURE_DIR" 2>/dev/null)
if [ -n "$PENDING" ] && [ "$PENDING" != "null" ]; then
    echo "📋 Resuming with pending answers from previous session"
    HAS_ANSWERS=true
else
    HAS_ANSWERS=false
fi
```

## Step 4: Spawn Spec Phase Agent

```javascript
// Spawn isolated spec-phase-agent via Task()
const agentResult = await Task({
  subagent_type: "spec-phase-agent",
  prompt: `
    Execute SPEC phase for feature:

    User input: $ARGUMENTS
    Feature directory: ${FEATURE_DIR}
    ${HAS_ANSWERS ? `
    Resume from: ${pendingAnswers.resume_from}
    Answers provided: ${JSON.stringify(pendingAnswers.answers)}
    ` : ''}

    Generate complete feature specification with requirements and quality validation.
    Return structured phase_result with status, artifacts, and any questions.
  `
});

const result = agentResult.phase_result;
```

## Step 5: Handle Agent Result

```javascript
// === CASE 1: Agent needs user input ===
if (result.status === "needs_input") {
  console.log(`\n📋 Specification needs user input`);

  // Save questions to interaction-state.yaml
  await Bash(`bash .spec-flow/scripts/bash/interaction-manager.sh save-questions "${FEATURE_DIR}" "spec" '${JSON.stringify(result)}'`);

  // Ask user via AskUserQuestion
  const userAnswers = await AskUserQuestion({
    questions: result.questions.map(q => ({
      question: q.question,
      header: q.header,
      multiSelect: q.multi_select,
      options: q.options
    }))
  });

  // Save answers
  await Bash(`bash .spec-flow/scripts/bash/interaction-manager.sh save-answers "${FEATURE_DIR}" '${JSON.stringify(userAnswers)}'`);

  // Re-spawn agent with answers
  // (In practice, user runs /spec again or /feature continue)
  console.log(`\n✅ Answers saved. Run /spec again to continue.`);
}

// === CASE 2: Agent completed successfully ===
if (result.status === "completed") {
  console.log(`✅ Specification phase completed`);

  // Log artifacts created
  if (result.artifacts_created) {
    result.artifacts_created.forEach(a => console.log(`   📄 ${a.path}`));
  }

  // Display summary
  if (result.summary) {
    console.log(`\n${result.summary}`);
  }

  // Mark phase complete
  await Bash(`bash .spec-flow/scripts/bash/interaction-manager.sh mark-phase-complete "${FEATURE_DIR}" "spec"`);
  await Bash(`yq eval '.phases.spec = "completed"' -i "${STATE_FILE}"`);
  await Bash(`yq eval '.phase = "clarify"' -i "${STATE_FILE}"`);

  // Auto-proceed based on blocking clarifications
  if (result.blocking_clarifications > 0) {
    console.log(`\n🔄 Auto-proceeding to /clarify (${result.blocking_clarifications} blocking questions)`);
    // Orchestrator will handle this
  } else {
    console.log(`\n🔄 Auto-proceeding to /plan`);
  }
}

// === CASE 3: Agent failed ===
if (result.status === "failed") {
  console.log(`\n❌ Specification phase FAILED`);
  console.log(`   Error: ${result.error?.message || 'Unknown error'}`);

  await Bash(`yq eval '.phases.spec = "failed"' -i "${STATE_FILE}"`);
  await Bash(`yq eval '.status = "failed"' -i "${STATE_FILE}"`);

  console.log(`\n   Fix issues and run: /spec again or /feature continue`);
}
```

</process>

<agent_reference>

## Spec Phase Agent

The actual specification logic lives in `.claude/agents/phase/spec-agent.md`.

**Agent responsibilities:**
- Parse user input for ambiguity
- Create feature directory structure
- Generate spec.md with FR/NFR identifiers
- Create user scenarios (Gherkin format)
- Validate quality with checklist
- Return questions if clarification needed

**Agent return format:**
```yaml
phase_result:
  status: "completed" | "needs_input" | "failed"
  artifacts_created:
    - path: "specs/001-slug/spec.md"
    - path: "specs/001-slug/state.yaml"
  summary: "Created spec with 8 FRs, 4 NFRs, 3 scenarios"
  metrics:
    fr_count: 8
    nfr_count: 4
    scenario_count: 3
    blocking_clarifications: 0
  # If needs_input:
  questions:
    - id: "Q001"
      question: "Who is the primary user?"
      header: "User"
      options: [...]
  resume_from: "requirements_gathering"
```

</agent_reference>

## Legacy Reference

The full specification logic (for reference) is documented in the spec-phase-agent.
Key patterns preserved:

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
        { label: "End user", description: "Direct application user" },
        { label: "Admin", description: "System administrator" },
        { label: "Developer", description: "API consumer or integrator" },
      ],
    },
    {
      question: "What's the expected scale?",
      header: "Scale",
      multiSelect: false,
      options: [
        { label: "< 1K users", description: "Small scale" },
        { label: "1K-10K users", description: "Medium scale" },
        { label: "10K+ users", description: "Large scale" },
      ],
    },
    {
      question: "Are there performance requirements?",
      header: "Performance",
      multiSelect: false,
      options: [
        { label: "Standard (< 2s)", description: "Normal web response" },
        { label: "Fast (< 500ms)", description: "Real-time feel" },
        { label: "No requirement", description: "Best effort" },
      ],
    },
  ],
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
     └── state.yaml
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

### Step 2.5: Apply Informed Guess Heuristics

**After filling spec.md, check for missing common requirements and apply sensible defaults:**

Run the informed guess script to detect gaps and apply defaults:

```bash
bash .spec-flow/scripts/bash/apply-defaults.sh "$FEATURE_DIR/spec.md"
```

**Default Categories Applied:**
| Category | Default Value | When Applied |
|----------|---------------|--------------|
| Performance | <500ms p95, <3s page load | If perf mentioned but no target |
| Authentication | OAuth2/JWT, 30min session | If auth mentioned but no method |
| Error Handling | Structured JSON errors | If errors mentioned but no format |
| Rate Limiting | 100 req/min authenticated | If rate limit mentioned but no value |
| Caching | Stale-while-revalidate, 5min TTL | If caching mentioned but no strategy |
| Pagination | 20 default, 100 max, cursor-based | If pagination mentioned but no limits |

**All applied defaults are marked with `[INFORMED GUESS]` for stakeholder review.**

### Step 2.6: Clarification Deduplication (Max 3 Rule)

**If spec.md has more than 3 `[NEEDS CLARIFICATION]` markers:**

1. **Prioritize by impact:**
   - P1: Security implications (auth, permissions, data exposure)
   - P2: Data model ambiguity (relationships, constraints, types)
   - P3: User-facing behavior (flows, error states, edge cases)
   - P4: Technical implementation (lower priority - can make informed guess)

2. **Keep top 3 blocking questions in spec.md**

3. **Move remainder to clarify.md with informed guess applied:**
   ```markdown
   ## Deferred Clarifications

   The following questions were auto-resolved with informed guesses:

   - Q: What auth method should we use?
     - [INFORMED GUESS]: OAuth2/JWT (standard for web apps)
     - Review with stakeholders if different method needed
   ```

4. **Log deferred count:**
   ```
   ⚠️ Clarifications reduced: 7 → 3 (4 resolved with informed guesses)
   ```

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

### Step 4: Quality Summary and Auto-Commit

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

**Display summary (no confirmation needed):**

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
- state.yaml
```

**Auto-proceed to git commit** (no confirmation required).

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

### Step 6: Auto-Proceed to Next Phase

**Determine spec state:**

```python
# Determine state
if blocking_count > 0:
    state = "BLOCKED_CLARIFICATIONS"
elif checklist_pct < 80:
    state = "BLOCKED_CHECKLIST"
else:
    state = "READY"
```

**Display completion and auto-proceed:**

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
```

**Auto-proceed based on state:**

- `BLOCKED_CLARIFICATIONS` → auto-run `/clarify`
- `BLOCKED_CHECKLIST` → auto-run `/plan` (log warning about quality)
- `READY` → auto-run `/plan`

No user confirmation required - workflow continues automatically.

</process>

<success_criteria>
**Specification successfully created when:**

1. **Artifacts generated**:

   - spec.md exists with all required sections
   - NOTES.md initialized
   - checklists/requirements.md created
   - state.yaml initialized

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
- state.yaml — Workflow tracking (phase status, gates, metadata)

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

### Clarification Behavior

- **Blocking questions**: Max 3 in spec.md using `[NEEDS CLARIFICATION]`
- **Non-blocking questions**: Unlimited in `clarify.md`
- **Threshold**: If ≥2 ambiguity signals detected, ask max 3 questions upfront

### Autopilot States

- **BLOCKED_CLARIFICATIONS**: Has `[NEEDS CLARIFICATION]` markers → auto-runs `/clarify`
- **BLOCKED_CHECKLIST**: Quality checklist <80% complete → proceeds with warning
- **READY**: No blockers, checklist ≥80% → auto-runs `/plan`

### Common Patterns

**Standard feature specification:**

```bash
/spec "user profile editing"
```

**Skip upfront clarification questions:**

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
└── state.yaml          # Workflow tracking
```

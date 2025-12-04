---
name: spec
description: Generate complete feature specification with research, requirements analysis, and quality validation
argument-hint: <feature-description> [--skip-clarify]
allowed-tools:
  [
    Read,
    Write,
    Edit,
    Grep,
    Glob,
    Bash(git *),
    Bash(python .spec-flow/scripts/*),
    AskUserQuestion,
    SlashCommand,
  ]
---

# /spec — Feature Specification Generator

<context>
**User Input**: $ARGUMENTS

**Feature Classification**: !`bash .spec-flow/scripts/bash/classify-feature.sh "$ARGUMENTS" 2>/dev/null || echo '{"error": "classification unavailable"}'`

**Current Git Status**: !`git status --short 2>$null || echo "clean"`

**Current Branch**: !`git branch --show-current 2>$null || echo "none"`

**Existing Specs**: !`dir /b /ad specs 2>$null | head -10 || echo "none"`

**Project Documentation**: !`dir /b docs\project\*.md 2>$null | head -5 || echo "none"`

**Tech Stack Context** (if available):
!`head -50 docs/project/tech-stack.md 2>/dev/null || echo "No tech-stack.md found"`

**API Strategy Context** (if available):
!`head -30 docs/project/api-strategy.md 2>/dev/null || echo "No api-strategy.md found"`

**Data Architecture Context** (if available):
!`head -30 docs/project/data-architecture.md 2>/dev/null || echo "No data-architecture.md found"`

**Roadmap (Similar Features)**: !`gh issue list --label roadmap --limit 5 2>$null || echo "none"`

**Specification Artifacts** (after execution):

- @specs/NNN-slug/spec.md
- @specs/NNN-slug/NOTES.md
- @specs/NNN-slug/checklists/requirements.md
- @specs/NNN-slug/state.yaml
</context>

<objective>
Generate a production-grade feature specification from natural language input.

Specification workflow:

1. Analyze user input for ambiguity (clarification if needed)
2. Invoke Python CLI for deterministic slug generation and artifact creation
3. Classify feature type and research mode
4. Generate requirements (functional + non-functional) with FR-XXX/NFR-XXX identifiers
5. Create user scenarios using Gherkin format (Given/When/Then)
6. Validate quality with automated checklist
7. Auto-commit to git with detailed summary
8. Auto-proceed to next phase

**Mental Model - Autopilot Pipeline**:

```
[clarify if needed] → spec-flow → classify → research → artifacts → commit → [auto-proceed]
```

**Key principles**:

- **Deterministic**: Slug generation and directory structure are predictable
- **Guardrails**: Prevent speculation, cite sources, validate quality automatically
- **User-value**: Success criteria are measurable and tech-agnostic
- **Conditional**: UI/metrics/deployment sections enabled by classification flags
- **Autopilot**: Auto-proceeds through phases, only blocks on errors

**Clarification Behavior**:

- Use `[NEEDS CLARIFICATION]` **only for blocking questions** in spec.md (max 3)
- Blocking = questions that make it unsafe to define requirements or acceptance criteria
- Additional or non-blocking questions go into `clarify.md`
- If blocking questions remain, auto-runs /clarify before proceeding

**References**:

- Gherkin for scenarios (Given/When/Then)
- HEART metrics (Happiness, Engagement, Adoption, Retention, Task success)
- Conventional Commits for commit messages

**Workflow position**: `spec → clarify? → plan → tasks → implement → optimize → ship`
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

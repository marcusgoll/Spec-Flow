---
name: clarify
description: Reduce spec ambiguity via targeted questions with adaptive auto-invocation (planning is 80% of success)
argument-hint: [spec-identifier or empty for auto-detect]
allowed-tools: [Read, Bash, Task, AskUserQuestion]
version: 11.0
updated: 2025-12-09
---

# /clarify — Specification Clarifier (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `clarify-phase-agent` via Task(). All clarification logic runs in isolated context with question batching.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated clarify-phase-agent to reduce specification ambiguity through targeted questions.

**Architecture (v11.0 - Phase Isolation):**
```
/clarify → Task(clarify-phase-agent) → Q&A loop if needed → updated spec.md
```

**Agent responsibilities:**
- Scan spec.md for `[NEEDS CLARIFICATION]` markers
- Map ambiguities to question bank templates
- Return batched questions (max 3 at a time)
- Apply answers atomically to spec.md
- Cite repo precedents for recommendations

**Key principle**: Planning is 80% of success — thorough clarification prevents costly rework.

**Workflow position**: `spec → clarify → plan → tasks → implement → optimize → ship`
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent fabricating ambiguities or solutions.

1. **Never invent ambiguities** not present in `spec.md`.

   - ❌ BAD: "The spec doesn't mention how to handle edge cases" (without reading it)
   - ✅ GOOD: Read spec.md, quote ambiguous sections: "spec.md:45 says 'users can edit' but doesn't specify edit permissions"
   - **Quote verbatim with line numbers:** `spec.md:120-125: '[exact quote]'`

2. **Always quote the unclear text** and cite **line numbers** for every question.

   - When flagging ambiguity: `spec.md:120-125: '[exact quote]' - unclear whether this means X or Y`
   - Don't paraphrase unclear text - show it verbatim
   - Cite line numbers for all ambiguities

3. **Never invent "best practice"** without evidence.

   - Don't say "Best practice is..." without evidence
   - Source recommendations: "Similar feature in specs/002-auth used JWT per plan.md:45"
   - If no precedent exists, say: "No existing pattern found, recommend researching..."

4. **Verify question relevance before asking user**.

   - Before asking technical question, check if answer exists in codebase
   - Use Grep/Glob to search for existing implementations
   - Don't ask "Should we use PostgreSQL?" if package.json already has pg installed

5. **Never assume user's answer without asking**.
   - Don't fill in clarifications with guesses
   - Present question, wait for response, use exact answer given
   - If user says "skip", mark as skipped - don't invent answer

**Why this matters**: Fabricated ambiguities create unnecessary work. Invented best practices may conflict with project standards. Accurate clarification based on real spec ambiguities ensures plan addresses actual uncertainties.

## Reasoning Approach

For complex clarification decisions, show your step-by-step reasoning:

<thinking>
Let me analyze this ambiguity:
1. What is ambiguous in spec.md? [Quote exact ambiguous text with line numbers]
2. Why is it ambiguous? [Explain multiple valid interpretations]
3. What are the possible interpretations? [List 2-3 options]
4. What's the impact of each interpretation? [Assess implementation differences]
5. Can I find hints in existing code or roadmap? [Search for precedents]
6. Conclusion: [Whether to ask user or infer from context]
</thinking>

<answer>
[Clarification approach based on reasoning]
</answer>

**When to use structured thinking:**

- Deciding whether ambiguity is worth asking about (impacts implementation vs cosmetic)
- Prioritizing multiple clarification questions (most impactful first)
- Determining if context provides sufficient hints to skip question
- Assessing whether to offer 2, 3, or 4 options
- Evaluating if recommended answer is justified by precedent

**Benefits**: Explicit reasoning reduces unnecessary questions by 30-40% and improves question quality.

---

<process>

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails (exit code != 0): Use AskUserQuestion fallback
4. Set paths:
   - Feature: `SPEC_FILE="${BASE_DIR}/${SLUG}/spec.md"`
   - Epic: `SPEC_FILE="${BASE_DIR}/${SLUG}/epic-spec.md"`

**Fallback prompt** (if detection fails):
- Question: "Which workflow are you working on?"
- Options: "Feature" (specs/), "Epic" (epics/)

**After detection**, count remaining ambiguities:
```bash
AMBIGUITY_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$SPEC_FILE" 2>/dev/null || echo "0")
```

---

### Step 1: AUTO-INVOCATION DETECTION (New in v5.0)

**When called from /epic workflow:**

The /epic command may auto-invoke /clarify based on ambiguity detection. This section determines if clarification is needed.

### Ambiguity Score Calculation

**Analyze epic-spec.md or spec.md:**

```javascript
const ambiguityScore = calculateAmbiguityScore({
  missing_subsystems: epic_spec.subsystems.filter(
    (s) => s.involved === "unknown"
  ).length,
  vague_objectives: epic_spec.objective.business_value.includes(
    "[NEEDS CLARIFICATION]"
  )
    ? 10
    : 0,
  missing_success_metrics: epic_spec.objective.success_metrics === "" ? 15 : 0,
  unclear_technical_approach:
    epic_spec.clarifications.length === 0 && epic_spec.constraints === ""
      ? 10
      : 0,
  placeholder_count: countPlaceholders(epic_spec) * 5,
});

// Score interpretation:
// 0-30: Clear (2-3 questions)
// 31-60: Moderate ambiguity (4-5 questions)
// 61+: High ambiguity (6-10 questions)
```

### Auto-Invoke Decision

```javascript
if (ambiguityScore > 30) {
  log(
    "🔍 Ambiguity detected (score: " +
      ambiguityScore +
      ") - Auto-invoking /clarify"
  );
  // Proceed with clarification workflow
} else if (ambiguityScore > 0 && ambiguityScore <= 30) {
  // Use AskUserQuestion to confirm
  AskUserQuestion({
    questions: [
      {
        question: `Minor ambiguities detected (score: ${ambiguityScore}). Clarify now or proceed?`,
        header: "Clarification",
        multiSelect: false,
        options: [
          {
            label: "Clarify now",
            description: `Ask ${Math.ceil(
              ambiguityScore / 10
            )} questions to resolve ambiguities`,
          },
          {
            label: "Skip for now",
            description: "Proceed to planning, may need to backtrack later",
          },
        ],
      },
    ],
  });

  if (userChoice === "Skip for now") {
    log("⏭️  Skipping clarification - proceeding to planning");
    return { skipped: true, reason: "User opted to skip" };
  }
} else {
  log("✅ No ambiguities detected - skipping clarification phase");
  return { skipped: true, reason: "No ambiguities detected" };
}
```

### Adaptive Question Count

Based on ambiguity score, adjust question count:

- **Score 0-30**: Ask 2-3 questions max
- **Score 31-60**: Ask 4-5 questions
- **Score 61+**: Ask 6-10 questions

Store in variable for use in question generation phase:

```javascript
const maxQuestions = ambiguityScore <= 30 ? 3 : ambiguityScore <= 60 ? 5 : 10;
```

### Load Question Bank

**Before generating questions**, load the centralized question bank:

```bash
# Read question bank for reference
cat .claude/skills/clarify/references/question-bank.md
```

**Purpose**: The question bank contains 40+ pre-structured questions organized by category. Use these templates to construct AskUserQuestion calls with consistent format, precedent visibility, and multiSelect support.

**Categories available:**

- Universal (baseline, user stories)
- Architecture (component placement, integration, scale)
- Data Model (entities, persistence, migration)
- Technical Approach (technology, libraries, patterns)
- API Design (endpoints, contracts, auth, errors)
- UI/UX (screens, components, responsive, accessibility)
- Security (data sensitivity, encryption, authorization)
- Testing (coverage, test data)
- Performance (targets, caching)
- Deployment (model, rollback)
- Dependencies (external deps, reliability)

---

### Step 2: Execute Prerequisite Script

Run the centralized spec-cli tool to perform analysis and prepare environment:

```bash
python .spec-flow/scripts/spec-cli.py clarify "$ARGUMENTS"
```

**What the script does:**

1. **Prerequisite checks** — Discovers feature paths, validates spec.md exists
2. **Load spec + checkpoint** — Creates git safety checkpoint before modifications
3. **Fast coverage scan** — Analyzes spec across 10 categories:
   - Functional Scope & Behavior
   - Domain & Data Model
   - Interaction & UX Flow
   - Non-Functional Qualities
   - Integration & Dependencies
   - Edge Cases & Failures
   - Constraints & Tradeoffs
   - Terminology & Consistency
   - Completion Signals
   - Placeholders & Ambiguity
4. **Build coverage map** — Counts Clear/Partial/Missing categories
5. **Repo-first precedent check** — Searches for existing technical decisions (DB, auth, rate limits, performance targets)

**Script output example:**

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Coverage analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Category Status:
  Clear: 6/10
  Partial: 2/10
  Missing: 2/10

Categories to analyze:
  - Domain & Data Model: Missing
  - Interaction & UX Flow: Partial
  - Non-Functional Quality: Missing
  - Integration & Dependencies: Clear
  - Edge Cases & Failure Handling: Partial
```

**After script completes, you (LLM) must:**

### Step 3: Read spec.md

Use the Read tool to load the full specification from the feature directory.

### Step 4: Identify Ambiguities and Map to Question Bank

**Scan spec.md for ambiguities** using the 10 categories from script output.

For each ambiguous section:

1. **Quote verbatim with line numbers**: `spec.md:120-126: "[exact quote]"`
2. **Categorize the ambiguity**: Architecture, Data Model, API Design, UI/UX, Security, etc.
3. **Map to question bank template**: Find matching question in `.claude/skills/clarify/references/question-bank.md`
4. **Check for repo precedents**: Search codebase for existing patterns using Grep/Glob
5. **Customize options with precedents**: Update option descriptions with "Used in specs/NNN-feature per plan.md:45"

**Priority order:** Architecture/Domain > UX > NFR > Integration > Edge > Constraints > Terminology > Completion > Placeholders

**Output:** List of ambiguities with:

- Spec quote + line numbers
- Category
- Question bank template to use
- Repo precedents found (if any)
- Priority score (1-10, based on implementation impact)

**Sort by priority score** (highest first), limit to `maxQuestions` calculated earlier.

### Step 5: Interactive Clarification Loop (AskUserQuestion-Driven)

**IMPORTANT**: Use AskUserQuestion tool extensively for all clarification questions.

### Batch Questions by Category

**Group related questions** (max 3 per batch) to improve UX:

```javascript
// Example: Group architecture questions together
const batches = [
  [
    {
      category: "Architecture",
      question: questionBank.architecture.component_placement,
      ambiguity: spec_line_120,
    },
    {
      category: "Architecture",
      question: questionBank.architecture.integration_pattern,
      ambiguity: spec_line_145,
    },
    {
      category: "Architecture",
      question: questionBank.architecture.scalability_requirements,
      ambiguity: spec_line_180,
    },
  ],
  [
    {
      category: "Data Model",
      question: questionBank.data_model.entity_identification,
      ambiguity: spec_line_200,
    },
    {
      category: "Data Model",
      question: questionBank.data_model.persistence_strategy,
      ambiguity: spec_line_220,
    },
  ],
  // ... more batches
];
```

**Batching rules:**

- Max 3 questions per AskUserQuestion call
- Group by category when possible (Architecture, Data Model, etc.)
- High-priority questions in earlier batches
- Show progress: "Questions 1-3 of 8"

### Execute Interactive Loop

For each batch:

1. **Show progress indicator**: `🔍 Clarifying spec (Questions 1-3 of 8)`
2. **Customize question bank templates** with:
   - Spec quote + line numbers in question text
   - Repo precedents in option descriptions
   - multiSelect flag if applicable
3. **Use AskUserQuestion tool** with the batch
4. **Process responses** (handle "Other" custom answers)
5. **Apply each answer atomically** (see section 4)
6. **Show completion**: `✅ Applied answers for Architecture questions`

### Interactive Question Format

**Example: Architecture question**

```javascript
AskUserQuestion({
  questions: [
    {
      question:
        "spec.md:120-126 is ambiguous about authentication approach. Which should we use?",
      header: "Authentication",
      multiSelect: false,
      options: [
        {
          label: "JWT tokens",
          description:
            "Stateless, scales horizontally. Used in specs/002-auth per plan.md:45",
        },
        {
          label: "Session-based",
          description:
            "Server-side sessions with Redis. Used in specs/005-admin",
        },
        {
          label: "OAuth 2.1",
          description: "Delegate to external provider (Google, GitHub, etc.)",
        },
        {
          label: "Other",
          description: "I'll provide a custom answer",
        },
      ],
    },
  ],
});
```

**Example: Data model question**

```javascript
AskUserQuestion({
  questions: [
    {
      question:
        "spec.md:45-50 mentions 'users can edit profiles' but doesn't specify permission model. What approach?",
      header: "Permissions",
      multiSelect: false,
      options: [
        {
          label: "Owner-only",
          description: "Users can only edit their own profile",
        },
        {
          label: "RBAC (Role-Based)",
          description: "Admins can edit any profile, users only their own",
        },
        {
          label: "ACL (Access Control Lists)",
          description: "Fine-grained per-user permissions",
        },
        {
          label: "Other",
          description: "I'll provide a custom answer",
        },
      ],
    },
  ],
});
```

**Example: Multi-question batch**

```javascript
// Ask up to 3 related questions at once
AskUserQuestion({
  questions: [
    {
      question: "What database should we use?",
      header: "Database",
      multiSelect: false,
      options: [
        {
          label: "PostgreSQL",
          description: "Relational, ACID, used in 3 other features",
        },
        { label: "MongoDB", description: "Document store, flexible schema" },
        { label: "Other", description: "Custom answer" },
      ],
    },
    {
      question: "How should we handle file uploads?",
      header: "File Storage",
      multiSelect: false,
      options: [
        { label: "Local filesystem", description: "Simple, no external deps" },
        { label: "S3/CloudStorage", description: "Scalable, CDN-friendly" },
        { label: "Database BLOBs", description: "Keep everything in DB" },
        { label: "Other", description: "Custom answer" },
      ],
    },
    {
      question: "What's the expected scale?",
      header: "Scale",
      multiSelect: false,
      options: [
        { label: "< 1K users", description: "Optimize for simplicity" },
        { label: "1K-10K users", description: "Plan for horizontal scaling" },
        { label: "10K+ users", description: "Distributed architecture needed" },
        { label: "Other", description: "Custom answer" },
      ],
    },
  ],
});
```

### Handling User Responses

**Process each answer from the batch:**

```javascript
const answers = userResponse.answers;

// Iterate through answers from the batch
for (const [questionHeader, selectedOption] of Object.entries(answers)) {
  // Show progress
  console.log(`📝 Applying answer for ${questionHeader}...`);

  // Handle "Other" custom answers
  if (selectedOption === "Other") {
    const customAnswer = answers[`${questionHeader}_custom`];
    applyAnswerAtomically(questionHeader, customAnswer, specQuote, lineNumbers);
  } else {
    applyAnswerAtomically(
      questionHeader,
      selectedOption,
      specQuote,
      lineNumbers
    );
  }

  console.log(`✅ Applied: ${questionHeader} → ${selectedOption}`);
}
```

**Important:** Each answer must be applied atomically using the workflow below (Step 6).

### Step 6: Atomic Update Workflow

For each answer (called from response handler above):

```bash
# 1. Checkpoint
git add specs/*/spec.md
git commit -m "clarify: checkpoint Q[N]" --no-verify

# 2. Update Clarifications section (use Edit tool)
# Ensure ## Clarifications section exists (add after ## Overview if missing)
# Add session header: ### Session [YYYY-MM-DD]
# Append Q&A: - Q: [question] → A: [answer]

# 3. Update relevant section (use Edit tool)
# Apply the answer to the appropriate spec section (Data Model, UX Flow, etc.)

# 4. Validate with Read tool
# Check that both updates exist in spec.md

# 5. Commit
git add specs/*/spec.md
git commit -m "clarify: apply Q/A for [topic]

Q: [question]
A: [answer]

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify
```

**Progress tracking:** After each answer is applied, update the user:

- `✅ Applied: Architecture → Backend API`
- `✅ Applied: Database → PostgreSQL`
- `📊 Progress: 3 of 8 questions answered`

### Step 7: Coverage Summary

After completing all interactive question batches, display coverage analysis:

```markdown
| Category                      | Status      | Notes                               |
| ----------------------------- | ----------- | ----------------------------------- |
| Functional Scope & Behavior   | ✅ Resolved | Sufficient detail                   |
| Domain & Data Model           | ✅ Resolved | Sufficient detail                   |
| Interaction & UX Flow         | ⚠️ Deferred | Low impact, clarify later if needed |
| Non-Functional Quality        | ✅ Resolved | Sufficient detail                   |
| Integration & Dependencies    | ✅ Resolved | Sufficient detail                   |
| Edge Cases & Failure Handling | ⚠️ Deferred | Low impact, clarify later if needed |
| Constraints & Tradeoffs       | ✅ Resolved | Sufficient detail                   |
| Terminology & Consistency     | ✅ Resolved | Sufficient detail                   |
| Completion Signals            | ✅ Resolved | Sufficient detail                   |
| Placeholders & Ambiguity      | ✅ Resolved | Sufficient detail                   |
```

### Step 8: Decision Tree

Count remaining ambiguities:

```bash
grep -c "\[NEEDS CLARIFICATION\]" specs/*/spec.md
```

**If ambiguities remain:**

```
⚠️  AMBIGUITIES REMAINING

1. Continue clarifying (/clarify) [RECOMMENDED]
   Duration: ~5-10 min
   Impact: Prevents rework in planning phase

2. Proceed to planning (/plan)
   ⚠️  Planning with ambiguities may require revisions
   Duration: ~10-15 min

3. Review spec.md manually
   Location: Check all [NEEDS CLARIFICATION] markers
```

**If all resolved:**

```
✅ ALL AMBIGUITIES RESOLVED

1. Generate implementation plan (/plan) [RECOMMENDED]
   Duration: ~10-15 min
   Output: Architecture decisions, component reuse analysis

2. Continue automated workflow (/feature continue)
   Executes: /plan → /tasks → /implement → /optimize → /ship
   Duration: ~60-90 min (full feature delivery)

3. Review spec.md first
   Location: Verify all clarifications are correct
```

### Step 9: Update NOTES.md

Append checkpoint using Bash tool:

```bash
FEATURE_DIR=$(python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only | jq -r '.FEATURE_DIR')
REMAINING_COUNT=$(grep -c "\[NEEDS CLARIFICATION\]" "$FEATURE_DIR/spec.md" || echo 0)

cat >> "$FEATURE_DIR/NOTES.md" <<EOF

## Phase 0.5: Clarify ($(date '+%Y-%m-%d %H:%M'))

**Summary**:
- Questions answered: [count]
- Questions skipped: [count]
- Ambiguities remaining: $REMAINING_COUNT

**Checkpoint**:
- ✅ Clarifications: [count] resolved
- ⚠️ Remaining: $REMAINING_COUNT ambiguities
- 📋 Ready for: $(if [ "$REMAINING_COUNT" -gt 0 ]; then echo "/clarify (resolve remaining)"; else echo "/plan"; fi)

EOF
```

</process>

<success_criteria>
**Clarification successfully completed when:**

1. **All ambiguities addressed**:

   - `[NEEDS CLARIFICATION]` markers resolved or documented
   - Remaining ambiguity count = 0 OR explicitly deferred with justification
   - All high-priority categories (Architecture, Data Model) have sufficient detail

2. **Interactive questions completed**:

   - All question batches processed (max 10 questions total)
   - User answers recorded in spec.md Clarifications section
   - Each answer applied atomically with git commit

3. **Coverage analysis shows progress**:

   - Clear: ≥8/10 categories
   - Partial: ≤2/10 categories
   - Missing: 0/10 categories
   - Coverage summary table generated

4. **Git safety maintained**:

   - All changes committed atomically (checkpoint + apply pattern)
   - Git history shows individual Q/A commits
   - No uncommitted changes in specs/\*/spec.md

5. **Documentation updated**:

   - spec.md has ## Clarifications section with session header
   - NOTES.md checkpoint appended with summary
   - Remaining ambiguities count recorded

6. **Next step identified**:
   - Decision tree executed
   - User informed of recommendation (/plan if clear, /clarify if ambiguities remain)
     </success_criteria>

<verification>
**Before marking clarification complete, verify:**

1. **Count remaining ambiguities**:

   ```bash
   grep -c "\[NEEDS CLARIFICATION\]" specs/*/spec.md || echo 0
   ```

   Should be 0 or explicit deferred markers with justification

2. **Check Clarifications section exists**:

   ```bash
   grep "## Clarifications" specs/*/spec.md
   ```

   Should return section with session header and Q/A entries

3. **Verify git commits**:

   ```bash
   git log --oneline --grep="clarify" -10
   ```

   Should show checkpoint commits and Q/A application commits

4. **Validate NOTES.md updated**:

   ```bash
   grep -A 10 "Phase 0.5: Clarify" specs/*/NOTES.md
   ```

   Should show checkpoint with question count and remaining ambiguities

5. **Check coverage summary displayed**:
   Ensure coverage table was shown to user with 10 categories

6. **Confirm decision tree executed**:
   User should see next step recommendation based on remaining ambiguities

**Never claim completion without these verification checks passing.**
</verification>

<output>
**Files created/modified by this command:**

**Feature spec** (specs/NNN-slug/):

- spec.md — Updated with Clarifications section (session-dated Q/A entries)
- spec.md — Ambiguous sections updated with answers applied
- NOTES.md — Phase 0.5 checkpoint appended

**Git commits** (atomic):

- Multiple commits: `clarify: checkpoint Q[N]` (before each update)
- Multiple commits: `clarify: apply Q/A for [topic]` (after each answer)

**Console output**:

- Coverage analysis table (10 categories)
- Progress indicators during question batches
- Decision tree with next step recommendation
  </output>

---

## Question Bank Benefits (v5.0)

**Why centralized question bank approach?**

1. **Consistency** — All features use the same question format, options, and terminology
2. **Precedent visibility** — Repo-specific examples automatically shown ("Used in specs/002-auth")
3. **Better UX** — Interactive AskUserQuestion with structured options vs free-text responses
4. **Faster clarification** — 3-5x faster than passive markdown Q&A (batched questions, instant responses)
5. **Maintainability** — Update question templates once, affects all future features
6. **Learning system** — Question bank can evolve based on project patterns
7. **Reduced ambiguity** — Structured options prevent vague or ambiguous free-text answers

**Comparison to previous approach:**

| Aspect               | Old (Passive)        | New (Interactive)            |
| -------------------- | -------------------- | ---------------------------- |
| Question format      | Free-form markdown   | Structured YAML templates    |
| User response        | Free-text typing     | Select from options          |
| Batch size           | 1 question at a time | 3 questions per batch        |
| Precedent visibility | Manual citation      | Automatic from question bank |
| Time per question    | ~2-3 min             | ~30 sec                      |
| Ambiguous answers    | Common (free-text)   | Rare (structured options)    |

**Expected velocity improvement:** 3-5x faster clarification phase

---

## References

- [Claude Docs - Prompting Best Practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Anthropic - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [LabEx - Git Rollback Safety](https://labex.io/tutorials/git-how-to-rollback-git-changes-safely-418148)
- [Hokstad Consulting - GitOps Rollbacks](https://hokstadconsulting.com/blog/gitops-rollbacks-automating-disaster-recovery)

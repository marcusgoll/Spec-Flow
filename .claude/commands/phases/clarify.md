---
description: Reduce spec ambiguity via targeted questions (planning is 80% of success)
version: 3.0
updated: 2025-11-17
---

# /clarify — Specification Clarifier

Clarify ambiguities in specification: `$ARGUMENTS`

<context>

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input above before proceeding (if not empty).

## Mental Model

**Flow:** spec-flow → **clarify** → plan → tasks → analyze → implement → optimize → debug → preview → phase-1-ship → validate-staging → phase-2-ship

**State machine:**

1. Run prerequisite script → 2) Load spec → 3) Scan for ambiguities (10-category coverage) → 4) Build coverage map →
5. Generate questions (quote spec lines with numbers) → 6) Ask up to 5 at a time →
7. Apply each answer atomically (checkpoint → update → validate) → 8) Commit → 9) Suggest next (/plan if clear)

**Auto-suggest:** when no outstanding ambiguities remain → `/plan`

**Operating Constraints**

* **Question cap:** max **10** per session; show **5** at a time.
* **Recommended answers:** provide, backed by repo precedents when available.
* **Incremental saves:** atomic update after each answer.
* **Git safety:** checkpoint before each file write; rollback on failure.

</context>

<constraints>

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

</constraints>

<instructions>

## Execute Clarification Workflow

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

## 1) Read spec.md

Use the Read tool to load the full specification from the feature directory.

## 2) Generate Prioritized Questions

**Priority:** Architecture/Domain > UX > NFR > Integration > Edge > Constraints > Terminology > Completion > Placeholders

**Rules:**
- **Max 10** total; present **up to 5** now
- **Each question** must include a **verbatim quote** with **line numbers** from `spec.md`
- Provide **2–3 options** + one **short answer** slot (≤ 5 words)
- If recommending an option, cite a **repo precedent**; if none, mark **"no precedent; research needed"**

**Template (per question):**

```markdown
### Q1 (ARCHITECTURE)

**spec.md:L120-126:**
> [quoted lines verbatim]

**Why it's ambiguous:** [one sentence]

**Options:**
- A — [description]  *(Recommended: because [repo evidence path:line])*
- B — [description]
- C — [description]
- Short — [≤5 words]

**Impact:** [1 sentence on scope/effort]
```

## 3) Ask Questions Sequentially

For each question:

1. **Display question** using template above
2. **Use AskUserQuestion tool** to get response (A/B/C/Short/Skip)
3. **Validate response** (not empty, recognized option)
4. **Apply answer atomically** using the workflow below
5. **Move to next question**

### Atomic Update Workflow

For each answer:

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

## 4) Coverage Summary

After completing all questions, display:

```markdown
| Category | Status | Notes |
|----------|--------|-------|
| Functional Scope & Behavior | ✅ Resolved | Sufficient detail |
| Domain & Data Model | ✅ Resolved | Sufficient detail |
| Interaction & UX Flow | ⚠️ Deferred | Low impact, clarify later if needed |
| Non-Functional Quality | ✅ Resolved | Sufficient detail |
| Integration & Dependencies | ✅ Resolved | Sufficient detail |
| Edge Cases & Failure Handling | ⚠️ Deferred | Low impact, clarify later if needed |
| Constraints & Tradeoffs | ✅ Resolved | Sufficient detail |
| Terminology & Consistency | ✅ Resolved | Sufficient detail |
| Completion Signals | ✅ Resolved | Sufficient detail |
| Placeholders & Ambiguity | ✅ Resolved | Sufficient detail |
```

## 5) Decision Tree

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

## 6) Update NOTES.md

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

</instructions>

---

## References

- [Claude Docs - Prompting Best Practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Anthropic - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [LabEx - Git Rollback Safety](https://labex.io/tutorials/git-how-to-rollback-git-changes-safely-418148)
- [Hokstad Consulting - GitOps Rollbacks](https://hokstadconsulting.com/blog/gitops-rollbacks-automating-disaster-recovery)

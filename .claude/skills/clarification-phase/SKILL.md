---
name: clarification-phase
description: "Capture lessons from /clarify phase. Auto-triggers when: starting /clarify, consolidating questions, prioritizing by impact, integrating responses. Updates when: >3 questions generated, unclear question wording, missing integration back to spec."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Clarification Phase: Lessons Learned

**Capability**: Learn from clarification question generation and response integration to reduce question count, improve question quality, and ensure responses update spec.md correctly.

**When I trigger**:
- `/clarify` starts → Load lessons to guide question generation and prioritization
- Clarification complete → Detect if questions >3, unclear wording, or missing spec integration
- Error: Poor question quality → Capture for future improvement

**Supporting files**:
- [reference.md](reference.md) - Question generation strategies, prioritization matrix, integration patterns
- [examples.md](examples.md) - Good questions (specific, scope-defining) vs bad questions (vague, with reasonable defaults)
- [templates/clarification-template.md](templates/clarification-template.md) - Template for structured clarification questions

---

## Common Pitfalls (Auto-Updated)

### 🚫 Too Many Clarification Questions (>3)

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (delays workflow, frustrates users)

**Scenario**:
```
/clarify generated 7 questions for a simple feature:
1. What format for export? (CSV/JSON)
2. Which fields to include?
3. Should we email notification?
4. Rate limiting strategy?
5. Maximum file size?
6. Retention period?
7. Should we compress files?
```

**Root cause**: Not using prioritization matrix (questions 1, 4, 5, 6, 7 have reasonable defaults)

**Detection**:
```bash
# After clarification generation
QUESTION_COUNT=$(grep -c "^## Question" specs/$SLUG/clarifications.md)
if [ $QUESTION_COUNT -gt 3 ]; then
  echo "⚠️  Too many clarifications: $QUESTION_COUNT (limit: 3)" >&2
  echo "Review: Are all questions scope/security critical?" >&2
fi
```

**Prevention**:
1. Apply prioritization matrix (see [reference.md](reference.md#question-prioritization-matrix))
2. Keep only Critical + High priority questions
3. Convert Medium/Low priority to informed guesses
4. Document removed questions as assumptions in spec.md

**If encountered**:
```bash
# Reduce to top 3 most critical
# Keep: Scope-defining, security/privacy critical
# Remove: Technical details with reasonable defaults
# Add to spec.md: Assumptions section with removed questions
```

---

### 🚫 Vague or Compound Questions

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: Medium (unclear answers, requires follow-up)

**Scenario**:
```
BAD: "What features should the dashboard have and how should it look?"
(Compound question - mixes functionality and design)

BAD: "What should we do about errors?"
(Too vague - no context, no options)

BAD: "Do you want this to be good?"
(Subjective, not actionable)
```

**Root cause**: Not following structured question template (see templates/clarification-template.md)

**Detection**:
```bash
# After clarification generation
# Flag questions with compound indicators
grep -E "(and |or )" specs/$SLUG/clarifications.md | while read -r line; do
  echo "⚠️  Possible compound question: $line" >&2
done

# Flag questions without options
if ! grep -q "Option A" specs/$SLUG/clarifications.md; then
  echo "⚠️  Questions may lack concrete options" >&2
fi
```

**Prevention**:
1. Use structured template: Context → Options (A/B/C) → Impact of each
2. One question = One decision
3. Provide 2-3 concrete options with tradeoffs
4. Avoid subjective words ("good", "better", "nice")

**Example fix**:
```markdown
## Question 1: Dashboard Feature Scope

**Context**: User story mentions "student progress tracking" but doesn't specify metrics.

**Options**:
A. Completion rate only (% of lessons finished)
B. Completion + time spent (lessons finished + hours logged)
C. Full analytics (completion + time + quiz scores + engagement)

**Impact**:
- Option A: Fastest to implement (~2 days), limited insights
- Option B: Moderate complexity (~4 days), useful for identifying struggling students
- Option C: Most comprehensive (~7 days), requires analytics infrastructure

**Recommendation**: Option B (balances insight with implementation cost)
```

---

### 🚫 Missing Spec Integration

**Frequency**: ★☆☆☆☆ (0/5 - not yet seen)
**Last seen**: Never
**Impact**: High (clarifications not reflected in spec, planning phase lacks context)

**Scenario**:
```
User answered 3 clarifications but spec.md not updated:
- spec.md still says "[NEEDS CLARIFICATION: Dashboard scope]"
- plan.md cannot proceed without knowing dashboard scope
- Implementation phase guesses requirements
```

**Root cause**: Clarification responses not integrated back into spec.md

**Detection**:
```bash
# After /clarify completes
# Check if spec.md still has [NEEDS CLARIFICATION] markers
REMAINING=$(grep -c "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md)
if [ $REMAINING -gt 0 ]; then
  echo "⚠️  Spec still has $REMAINING unresolved clarifications" >&2
  grep -n "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md >&2
fi
```

**Prevention**:
1. For each answered question, update corresponding spec.md section
2. Replace `[NEEDS CLARIFICATION: ...]` with concrete decision
3. Add "Clarifications" section to spec.md summarizing all answers
4. Run detection check before returning from /clarify

**If encountered**:
```bash
# Manual integration checklist:
# 1. Read clarifications.md responses
# 2. Update spec.md Requirements section
# 3. Remove [NEEDS CLARIFICATION] markers
# 4. Add ## Clarifications section with Q&A summary
# 5. Verify grep "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md returns nothing
```

---

## Successful Patterns (Auto-Updated)

### ✅ Structured Question Format

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (clear answers, faster decisions)

**Scenario**:
```markdown
## Question 1: User Access Control

**Context**: Spec mentions "users" and "admins" but doesn't define access boundaries.

**Options**:
A. Users: View own data only | Admins: View all data
B. Users: View + Edit own data | Admins: View + Edit all data + User management
C. Role-based: Teachers (view assigned classes), Admins (full access), Students (view own progress)

**Impact**:
- Option A: Simple permissions (~1 day), limited flexibility
- Option B: Standard CRUD permissions (~2 days), covers most use cases
- Option C: Full RBAC (~4 days), future-proof but complex

**Recommendation**: Option B (standard pattern, sufficient for MVP)
```

**Approach**:
- Context: Explain ambiguity in spec
- Options: Provide 2-3 concrete choices with clear differences
- Impact: Quantify implementation cost and user value
- Recommendation: Suggest option with reasoning

**Results**:
- Clear answers: User picks option A/B/C (not vague descriptions)
- Faster decisions: Impact analysis helps prioritization
- Better spec: Concrete options transfer directly to spec.md

**Reuse conditions**:
- ✓ Use when: Question has multiple valid answers
- ✓ Use when: Tradeoffs exist between options
- ✓ Use when: Implementation cost varies by option
- ✗ Don't use when: Yes/no question is sufficient

---

### ✅ Prioritized Question List

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (focuses on critical decisions first)

**Scenario**:
```markdown
# Clarifications for Feature: Student Progress Dashboard

**Critical (Must answer before planning)**:
1. Dashboard scope: Which metrics to display?
2. User access: Who can view which student data?

**High (Impacts design decisions)**:
3. Real-time vs batch updates?

**Deferred (Has reasonable defaults)**:
- Export format: CSV (standard)
- Refresh rate: 5 minutes (standard)
- Cache duration: 10 minutes (standard)
```

**Approach**:
1. Categorize questions by priority (Critical, High, Medium, Low)
2. Ask only Critical + High priority questions
3. Document deferred questions as assumptions
4. Focus user attention on scope-defining decisions

**Results**:
- Reduced clarification count: From 6 potential to 3 asked
- Faster user responses: Clear prioritization
- Better defaults: Deferred questions use informed guesses

**Reuse conditions**:
- ✓ Use when: Multiple potential questions exist
- ✓ Use when: Some questions have reasonable defaults
- ✓ Use when: User time is limited
- ✗ Don't use when: All questions are equally critical

---

### ✅ Clarification Response Integration

**Success rate**: Not yet tracked
**First used**: Not yet used
**Impact**: High (ensures downstream phases have complete context)

**Scenario**:
```markdown
# Before /clarify
## Requirements
- Dashboard displays student progress [NEEDS CLARIFICATION: Which metrics?]

# After /clarify (User chose Option B: Completion + time spent)
## Requirements
- Dashboard displays:
  - Lesson completion rate (% of assigned lessons finished)
  - Time spent per lesson (hours logged)
  - Last activity date

## Clarifications (Resolved)

### Q1: Dashboard Metrics
**Asked**: Which metrics should the dashboard display?
**Options**: A) Completion only, B) Completion + time, C) Full analytics
**Decision**: Option B - Completion rate + time spent
**Rationale**: Balances insights with implementation cost (4 days vs 7 days for Option C)
```

**Approach**:
1. Update spec.md Requirements section with concrete details
2. Remove all `[NEEDS CLARIFICATION]` markers
3. Add "Clarifications (Resolved)" section summarizing decisions
4. Include rationale for context in future phases

**Results**:
- Complete spec: Planning phase has all needed context
- Audit trail: Decisions documented with rationale
- No ambiguity: Implementation knows exact requirements

**Reuse conditions**:
- ✓ Use always: After every clarification phase
- ✓ Use when: User provided answers to questions
- ✗ Don't use when: Questions remain unanswered (re-run /clarify)

---

## Phase Checklist (Auto-Updated)

**Pre-phase checks**:
- [ ] spec.md has `[NEEDS CLARIFICATION]` markers (otherwise skip /clarify)
- [ ] Clarification count ≤3 (if >3, consolidate first)
- [ ] Each clarification is scope or security critical

**During phase**:
- [ ] Questions follow structured format (Context → Options → Impact → Recommendation)
- [ ] Questions prioritized (Critical, High, Medium, Low)
- [ ] Only Critical + High questions asked
- [ ] Medium/Low questions converted to assumptions

**Post-phase checks**:
- [ ] User provided answers to all questions
- [ ] spec.md Requirements updated with concrete details
- [ ] All `[NEEDS CLARIFICATION]` markers removed from spec.md
- [ ] Clarifications section added to spec.md with Q&A summary
- [ ] Clarifications committed with message: "docs(spec): resolve clarifications for [feature-name]"

---

## Metrics Tracking

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg questions per feature | ≤3 | Not tracked | - |
| Question clarity score | ≥4/5 | Not tracked | - |
| Response integration rate | 100% | Not tracked | - |
| Time to resolution | ≤2 hours | Not tracked | - |
| Follow-up questions needed | <10% | Not tracked | - |

**Updated**: Not yet tracked
**Last feature**: None yet

---

## Auto-Update Trigger Points

The clarification-phase Skill auto-updates when:

1. **Question count >3**: Increment "Too Many Questions" frequency, capture context
2. **Compound question detected**: Increment "Vague Questions" frequency, save example
3. **Missing integration**: Increment "Missing Integration" frequency, note which markers remained
4. **Successful resolution**: Increment success pattern counters, update metrics
5. **User feedback**: Capture explicit user feedback about question quality

**Update command** (run at end of /clarify):
```bash
# Check metrics
QUESTION_COUNT=$(grep -c "^## Question" specs/$SLUG/clarifications.md)
REMAINING_MARKERS=$(grep -c "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md)

# Update skill if thresholds exceeded
if [ $QUESTION_COUNT -gt 3 ] || [ $REMAINING_MARKERS -gt 0 ]; then
  # Increment frequency counters
  # Update last seen dates
  # Add example to skill file
fi
```

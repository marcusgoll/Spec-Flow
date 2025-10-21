---
name: clarification-phase
description: "Standard Operating Procedure for /clarify phase. Covers question generation, prioritization, structured formats, and spec integration."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Clarification Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/clarify` command to resolve ambiguities efficiently.

**Supporting references**:
- [reference.md](reference.md) - Question generation strategies, prioritization matrix, integration patterns
- [examples.md](examples.md) - Good questions (specific, scope-defining) vs bad questions (vague, with defaults)
- [templates/clarification-template.md](templates/clarification-template.md) - Structured question template

---

## Phase Overview

**Purpose**: Resolve critical ambiguities in spec.md through structured questions, then integrate answers back into specification.

**Inputs**:
- `specs/NNN-slug/spec.md` with `[NEEDS CLARIFICATION]` markers

**Outputs**:
- `specs/NNN-slug/clarifications.md` - Structured questions with user answers
- Updated `specs/NNN-slug/spec.md` - Resolved requirements, removed markers
- Updated `workflow-state.yaml`

**Expected duration**: 5-15 minutes (question generation) + user response time

---

## Prerequisites

**Environment checks**:
- [ ] Spec phase completed (`spec.md` exists)
- [ ] spec.md contains `[NEEDS CLARIFICATION]` markers (if none, skip /clarify)
- [ ] Git working tree clean

**Knowledge requirements**:
- Question prioritization matrix (Critical > High > Medium > Low)
- Structured question format (Context → Options → Impact)
- Spec integration patterns

---

## Execution Steps

### Step 1: Extract Clarification Needs

**Actions**:
1. Read `spec.md` to find all `[NEEDS CLARIFICATION: ...]` markers
2. Extract ambiguity context for each marker
3. Count clarifications found

**Example**:
```bash
# Count clarifications
CLARIFICATION_COUNT=$(grep -c "\[NEEDS CLARIFICATION" specs/NNN-slug/spec.md)
echo "Found $CLARIFICATION_COUNT clarifications"

# List them
grep -n "\[NEEDS CLARIFICATION" specs/NNN-slug/spec.md
```

**Quality check**: If count = 0, skip /clarify phase. If count >5, review spec phase (too many clarifications).

---

### Step 2: Prioritize Questions

**Actions**:
1. Categorize each clarification by priority using matrix (see [reference.md](reference.md)):
   - **Critical**: Scope boundary, security/privacy, breaking changes
   - **High**: User experience decisions, functionality tradeoffs
   - **Medium**: Performance SLAs, technical stack choices
   - **Low**: Error messages, rate limits

2. Keep only Critical + High priority questions
3. Convert Medium/Low to informed guesses (document as assumptions)

**Prioritization matrix quick reference**:
| Category | Priority | Ask? | Example |
|----------|----------|------|---------|
| Scope boundary | Critical | ✅ Always | "Does this include admin features?" |
| Security/Privacy | Critical | ✅ Always | "Should PII be encrypted at rest?" |
| Breaking changes | Critical | ✅ Always | "Can we change API response format?" |
| User experience | High | ✅ If ambiguous | "Modal or new page?" |
| Performance SLA | Medium | ❌ Use defaults | "Response time target?" → Assume <500ms |
| Technical stack | Medium | ❌ Defer to plan | "Which database?" → Plan phase decision |
| Error messages | Low | ❌ Use standard | "Error message wording?" → Standard pattern |
| Rate limits | Low | ❌ Use defaults | "Requests per minute?" → Assume 100/min |

**Target**: ≤3 questions total after prioritization.

**Quality check**: Are all remaining questions scope/security critical?

---

### Step 3: Generate Structured Questions

**Actions**:
For each Critical/High priority clarification, generate structured question using template:

**Structured question format**:
```markdown
## Question N: [Short Title]

**Context**: [Explain ambiguity in spec with specific reference]

**Options**:
A. [Option 1 description]
B. [Option 2 description]
C. [Option 3 description]

**Impact**:
- Option A: [Implementation cost + user value + tradeoffs]
- Option B: [Implementation cost + user value + tradeoffs]
- Option C: [Implementation cost + user value + tradeoffs]

**Recommendation**: [Suggested option with rationale]

**References**: [Link to spec.md line with [NEEDS CLARIFICATION] marker]
```

**Example**:
```markdown
## Question 1: Dashboard Metrics Scope

**Context**: spec.md line 45 mentions "student progress tracking" but doesn't specify which metrics to display.

**Options**:
A. Completion rate only (% of lessons finished)
B. Completion + time spent (lessons finished + hours logged)
C. Full analytics (completion + time + quiz scores + engagement metrics)

**Impact**:
- Option A: Fastest (~2 days), basic insights, may require expansion later
- Option B: Moderate (~4 days), actionable insights for identifying struggling students
- Option C: Comprehensive (~7 days), requires analytics infrastructure, future-proof

**Recommendation**: Option B (balances insight with implementation cost)

**References**: specs/042-student-progress-dashboard/spec.md:45
```

**Quality standards for questions**:
- **Specific**: References exact spec location
- **Concrete**: 2-3 specific options (not open-ended)
- **Quantified**: Implementation costs in days/hours
- **Actionable**: User picks A/B/C (not vague descriptions)
- **Focused**: One question = One decision (no compounds)

**Quality check**: Does each question follow structured format with clear options?

---

### Step 4: Document Deferred Questions as Assumptions

**Actions**:
1. For Medium/Low priority questions that were not asked, document as assumptions in clarifications.md
2. Explain why defaults were used instead of asking

**Example**:
```markdown
## Deferred Questions (Using Informed Guesses)

### Export Format
**Not asked** (Low priority - standard default exists)
**Assumption**: CSV format (most compatible, industry standard)
**Rationale**: Users can request JSON/Excel in future if needed
**Override**: If requirements differ, specify in spec.md

### Rate Limiting
**Not asked** (Low priority - reasonable default exists)
**Assumption**: 100 requests/minute per user
**Rationale**: Conservative limit prevents abuse, can increase based on usage
**Override**: If higher limits needed, document in spec.md

### Cache Duration
**Not asked** (Medium priority - standard default exists)
**Assumption**: 10-minute cache for dashboard data
**Rationale**: Balances freshness with performance
**Override**: Specify in spec.md if real-time updates required
```

**Quality check**: All deferred questions documented with rationale.

---

### Step 5: Create clarifications.md

**Actions**:
1. Render `clarifications.md` from template with:
   - Question count and priority breakdown
   - Structured questions (Critical + High only)
   - Deferred questions section (Medium + Low)
   - Instructions for user

2. Add user instructions:
   ```markdown
   ## Instructions

   Please answer the questions below by:
   1. Selecting an option (A/B/C) or providing custom answer
   2. Adding any additional context or constraints
   3. Reviewing deferred assumptions (override if needed)

   Once complete, run `/clarify continue` to integrate answers into spec.
   ```

**Quality check**: clarifications.md is clear and ready for user review.

---

### Step 6: Wait for User Answers

**Actions**:
1. Present clarifications.md to user
2. User reviews questions
3. User provides answers (selects options A/B/C or custom)
4. User signals completion

**Example user responses**:
```markdown
## Question 1: Dashboard Metrics Scope
**Selected**: Option B (Completion + time spent)
**Additional context**: Also include "last activity date" for staleness detection

## Question 2: User Access Control
**Selected**: Option C (Role-based access)
**Additional context**: Need to add "Parent" role with view-only access to their children's data

## Deferred Assumptions - Overrides
**Rate Limiting**: Use 200 requests/minute instead of 100 (we have power users)
```

**Quality check**: User provided clear answers to all questions.

---

### Step 7: Integrate Answers into spec.md

**Actions**:
1. For each answered question, update spec.md:
   - Locate corresponding `[NEEDS CLARIFICATION]` marker
   - Replace with concrete requirement based on answer
   - Add details from "additional context"

2. Remove all `[NEEDS CLARIFICATION]` markers

3. Add "Clarifications (Resolved)" section to spec.md

**Example integration**:

**Before** (spec.md):
```markdown
## Requirements
- Dashboard displays student progress [NEEDS CLARIFICATION: Which metrics?]
- Users can access dashboard [NEEDS CLARIFICATION: Access control model?]
```

**After** (spec.md):
```markdown
## Requirements
- Dashboard displays:
  - Lesson completion rate (% of assigned lessons finished)
  - Time spent per lesson (hours logged)
  - Last activity date (to detect stale/inactive students)
- User access control (role-based):
  - Teachers: View assigned students only
  - Admins: View all students
  - Parents: View own children only (read-only)
  - Students: View own progress only

## Clarifications (Resolved)

### Q1: Dashboard Metrics Scope
**Asked**: Which metrics should the dashboard display?
**Options**: A) Completion only, B) Completion + time, C) Full analytics
**Decision**: Option B - Completion rate + time spent + last activity date
**Rationale**: Balances insights with implementation cost (4 days vs 7 for full analytics)
**Additional**: Last activity date added for staleness detection

### Q2: User Access Control
**Asked**: What access control model should be used?
**Options**: A) Simple (users/admins), B) Standard CRUD, C) Role-based
**Decision**: Option C - Role-based access control
**Rationale**: Future-proof for additional roles (e.g., counselors, district admins)
**Additional**: Parent role added with read-only access to children's data

### Deferred Assumptions - Overrides
**Rate Limiting**: Changed from 100/min to 200/min (power users on platform)
```

**Quality check**: All `[NEEDS CLARIFICATION]` markers removed, decisions documented.

---

### Step 8: Validate Integration

**Actions**:
1. Run checks:
   ```bash
   # Verify no markers remain
   REMAINING=$(grep -c "\[NEEDS CLARIFICATION" specs/NNN-slug/spec.md)
   if [ $REMAINING -gt 0 ]; then
     echo "⚠️  Still has $REMAINING unresolved clarifications"
     grep -n "\[NEEDS CLARIFICATION" specs/NNN-slug/spec.md
     exit 1
   fi

   # Verify clarifications section added
   if ! grep -q "## Clarifications (Resolved)" specs/NNN-slug/spec.md; then
     echo "⚠️  Missing Clarifications section in spec.md"
     exit 1
   fi
   ```

2. Review spec.md for completeness:
   - All requirements now concrete (no ambiguities)
   - Decisions documented with rationale
   - Ready for planning phase

**Quality check**: spec.md is complete and unambiguous.

---

### Step 9: Commit Clarifications

**Actions**:
```bash
git add specs/NNN-slug/clarifications.md specs/NNN-slug/spec.md
git commit -m "docs: resolve clarifications for <feature-name>

Answered 2 critical questions:
- Dashboard metrics scope: Completion + time + last activity (Option B)
- User access control: Role-based (Option C) + Parent role

Deferred assumptions:
- Export format: CSV (standard)
- Rate limiting: 200/min (override: power users)
- Cache duration: 10 min (standard)

All [NEEDS CLARIFICATION] markers removed from spec.md
Ready for planning phase
"
```

**Quality check**: Clarifications committed, workflow-state.yaml updated.

---

## Common Mistakes to Avoid

### 🚫 Too Many Clarification Questions (>3)

**Impact**: Delays workflow, frustrates users, analysis paralysis

**Scenario**:
```
Generated 7 questions for simple feature:
1. What format for export? (CSV/JSON) → Has default (CSV)
2. Which fields to include? → Critical, should ask
3. Email notification? → Has default (optional)
4. Rate limiting? → Has default (100/min)
5. Max file size? → Has default (50MB)
6. Retention period? → Has default (90 days)
7. Compress files? → Has default (yes for >10MB)
```

**Prevention**:
- Apply prioritization matrix strictly
- Keep only Critical + High priority
- Convert Medium/Low to informed guesses
- Target: ≤3 questions

---

### 🚫 Vague or Compound Questions

**Impact**: Unclear answers, requires follow-up, wastes time

**Bad examples**:
```markdown
❌ "What features should the dashboard have and how should it look?"
   (Compound: mixes functionality + design)

❌ "What should we do about errors?"
   (Too vague: no context, no options)

❌ "Do you want this to be good?"
   (Subjective, not actionable)
```

**Good examples**:
```markdown
✅ Question 1: Dashboard Metrics Scope
   Context: spec mentions "progress" but not which metrics
   Options: A) Completion only, B) Completion + time, C) Full analytics
   Impact: [quantified costs]
   Recommendation: Option B

✅ Question 2: Error Handling Strategy
   Context: Spec doesn't specify how to handle API failures
   Options: A) Retry 3x then fail, B) Retry indefinitely, C) Circuit breaker
   Impact: [quantified costs + user experience]
   Recommendation: Option A
```

**Prevention**: Use structured template (Context → Options → Impact → Recommendation)

---

### 🚫 Missing Spec Integration

**Impact**: Clarifications not reflected in spec, planning phase lacks context

**Scenario**:
```
User answered 3 clarifications but:
- spec.md still says "[NEEDS CLARIFICATION: Dashboard scope]"
- plan.md can't proceed without knowing scope
- Implementation phase guesses requirements
```

**Prevention**:
1. Update spec.md Requirements section with concrete details
2. Remove all `[NEEDS CLARIFICATION]` markers
3. Add "Clarifications (Resolved)" section
4. Run validation check before completing phase

**Validation**:
```bash
# Must return 0
grep -c "\[NEEDS CLARIFICATION" specs/NNN-slug/spec.md
```

---

### 🚫 No Deferred Assumptions Documented

**Impact**: User doesn't know what defaults were applied

**Prevention**: Document all Medium/Low priority questions as assumptions with rationale

---

### 🚫 Questions Without Options

**Impact**: Open-ended answers, hard to integrate into spec

**Bad example**:
```markdown
❌ Question 1: What should the dashboard show?
   (No options, completely open-ended)
```

**Good example**:
```markdown
✅ Question 1: Dashboard Metrics Scope
   Options: A, B, C (concrete choices with costs)
```

**Prevention**: Always provide 2-3 concrete options with quantified impacts

---

## Best Practices

### ✅ Structured Question Format

**Template**:
```markdown
## Question N: [Short Title]

**Context**: [Explain ambiguity + spec reference]

**Options**:
A. [Concrete option 1]
B. [Concrete option 2]
C. [Concrete option 3]

**Impact**:
- Option A: [Cost + value + tradeoffs]
- Option B: [Cost + value + tradeoffs]
- Option C: [Cost + value + tradeoffs]

**Recommendation**: [Suggested option + rationale]

**References**: [spec.md line number]
```

**Result**: Clear answers, faster decisions, easy spec integration

---

### ✅ Prioritized Question List

**Approach**:
1. Categorize: Critical, High, Medium, Low
2. Ask: Critical + High only
3. Document: Medium + Low as assumptions

**Example**:
```markdown
## Questions (Critical + High Priority)
1. Dashboard scope (Critical)
2. Access control model (High)

## Deferred Assumptions (Medium + Low Priority)
- Export format: CSV (Low - standard default)
- Rate limit: 100/min (Low - reasonable default)
- Refresh rate: 5 min (Medium - standard default)
```

**Result**: Focused user attention, faster responses, reasonable defaults

---

### ✅ Clarification Response Integration Checklist

**After receiving answers**:
- [ ] Update spec.md Requirements with concrete details
- [ ] Remove all `[NEEDS CLARIFICATION]` markers
- [ ] Add "Clarifications (Resolved)" section
- [ ] Document rationale for each decision
- [ ] Include additional context from user
- [ ] Verify `grep "\[NEEDS CLARIFICATION" spec.md` returns nothing
- [ ] Commit with descriptive message

---

## Phase Checklist

**Pre-phase checks**:
- [ ] spec.md has `[NEEDS CLARIFICATION]` markers (otherwise skip)
- [ ] Clarification count ≤5 (if >5, review spec phase)
- [ ] Git working tree clean

**During phase**:
- [ ] Questions prioritized (Critical, High, Medium, Low)
- [ ] Only Critical + High questions asked (target: ≤3)
- [ ] Questions follow structured format (Context → Options → Impact)
- [ ] Deferred questions documented as assumptions
- [ ] User provided answers to all questions

**Post-phase validation**:
- [ ] spec.md Requirements updated with concrete details
- [ ] All `[NEEDS CLARIFICATION]` markers removed
- [ ] "Clarifications (Resolved)" section added to spec.md
- [ ] Deferred assumptions documented
- [ ] Clarifications committed
- [ ] workflow-state.yaml updated

---

## Quality Standards

**Clarification quality targets**:
- Question count: ≤3 per feature
- Question clarity: All follow structured format
- Response integration: 100% (no remaining markers)
- Time to resolution: ≤2 hours (user response time varies)
- Follow-up questions: <10%

**What makes good clarifications**:
- ≤3 questions (prioritized rigorously)
- Structured format (Context → Options → Impact)
- Concrete options (2-3 specific choices, not open-ended)
- Quantified impacts (implementation costs + user value)
- Clear recommendations (suggested option with rationale)
- Complete integration (all markers removed from spec)

**What makes bad clarifications**:
- >5 questions (didn't prioritize)
- Vague questions ("What should we do?")
- Compound questions (mixing multiple decisions)
- No options (open-ended)
- Missing integration (markers remain in spec)

---

## Completion Criteria

**Phase is complete when**:
- [ ] All pre-phase checks passed
- [ ] All questions answered by user
- [ ] spec.md updated with concrete requirements
- [ ] All `[NEEDS CLARIFICATION]` markers removed
- [ ] Clarifications committed
- [ ] workflow-state.yaml shows `currentPhase: clarification` and `status: completed`

**Ready to proceed to next phase** (`/plan`):
- [ ] spec.md is complete and unambiguous
- [ ] All decisions documented with rationale
- [ ] No remaining ambiguities

---

## Troubleshooting

**Issue**: Too many questions (>3)
**Solution**: Apply prioritization matrix more strictly, convert Medium/Low to assumptions

**Issue**: Questions are vague
**Solution**: Use structured template (Context → Options → Impact), provide 2-3 concrete options

**Issue**: User can't choose between options
**Solution**: Add more context about tradeoffs, strengthen recommendation with rationale

**Issue**: `[NEEDS CLARIFICATION]` markers remain after integration
**Solution**: Review each marker, update spec.md with concrete details, run validation check

**Issue**: Planning phase blocked due to ambiguity
**Solution**: spec integration was incomplete, return to /clarify and complete integration

---

_This SOP guides the clarification phase. Refer to reference.md for prioritization details and examples.md for question patterns._

# Clarification Phase Reference Guide

## Question Generation Strategy

### When to Generate Clarifications

```
Does spec have [NEEDS CLARIFICATION] markers?
├─ Yes → Extract each marker's context
│  ├─ Priority = Critical/High → Generate structured question
│  └─ Priority = Medium/Low → Convert to assumption
└─ No → Skip /clarify phase entirely
```

### Extraction Process

```bash
# Find all clarification markers in spec.md
grep -n "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md | while IFS=: read -r lineno text; do
  # Extract context (surrounding 3 lines)
  CONTEXT=$(sed -n "$((lineno-3)),$((lineno+3))p" specs/$SLUG/spec.md)

  # Extract question text
  QUESTION=$(echo "$text" | sed 's/.*\[NEEDS CLARIFICATION: \(.*\)\].*/\1/')

  # Generate structured clarification
  echo "## Question: $QUESTION"
  echo ""
  echo "**Context**: $CONTEXT"
  echo ""
  # Generate options...
done
```

---

## Question Prioritization Matrix

**Use this matrix to decide which questions to ask:**

| Category | Priority | Ask? | Example |
|----------|----------|------|---------|
| **Scope boundary** | Critical | ✅ Always | "Should dashboard show all students or only assigned classes?" |
| **User access control** | Critical | ✅ Always | "Can users edit their own data or view-only?" |
| **Security/Privacy** | Critical | ✅ Always | "Should PII be encrypted at rest or in transit only?" |
| **Breaking changes** | Critical | ✅ Always | "Is it okay to change the API response format?" |
| **Feature inclusion** | High | ✅ If ambiguous | "Should export include archived records?" |
| **User experience** | High | ✅ If ambiguous | "Should validation errors show inline or in modal?" |
| **Data model** | High | ✅ If impacts schema | "Should user-to-project be one-to-many or many-to-many?" |
| **Integration points** | Medium | ❌ Defer to plan | "Should we use REST or GraphQL?" |
| **Performance SLA** | Medium | ❌ Use defaults | "What's the target response time?" → Assume <500ms |
| **Technical stack** | Medium | ❌ Defer to plan | "Which database?" → Plan phase decision |
| **UI details** | Low | ❌ Defer to design | "What color for the button?" → Design phase |
| **Error messages** | Low | ❌ Use standard | "What error message?" → Standard pattern |
| **Rate limits** | Low | ❌ Use defaults | "How many requests?" → 100/min default |

**Limit: Maximum 3 clarifications total per feature**

### Priority Decision Tree

```
Is this question about WHAT the feature does?
├─ Yes → Critical/High (ask)
│  ├─ Defines scope boundary → Critical
│  ├─ Affects user stories → Critical
│  └─ Clarifies feature inclusion → High
└─ No → Is it about HOW to build it?
   ├─ Yes → Medium/Low (defer)
   │  ├─ Technical stack choice → Defer to plan
   │  ├─ Implementation pattern → Defer to plan
   │  └─ UI polish → Defer to design
   └─ No → Is it about WHO can do what?
      ├─ Yes → Critical (ask)
      │  ├─ User access control → Critical
      │  └─ Security/privacy → Critical
      └─ No → Use defaults
```

---

## Structured Question Template

### Template Structure

```markdown
## Question N: [Short, specific title]

**Context**: [2-3 sentences explaining the ambiguity]
- Current spec says: "[Quote relevant spec section]"
- Ambiguity: [What's unclear or missing]

**Options**:

### Option A: [Descriptive name]
- **Description**: [2-3 sentences explaining this choice]
- **Implementation cost**: [Time estimate or complexity: Low/Medium/High]
- **User value**: [Benefit to end users]
- **Tradeoffs**: [What you give up with this choice]

### Option B: [Descriptive name]
- **Description**: [2-3 sentences]
- **Implementation cost**: [Estimate]
- **User value**: [Benefit]
- **Tradeoffs**: [Tradeoffs]

### Option C (Optional): [Descriptive name]
- **Description**: [2-3 sentences]
- **Implementation cost**: [Estimate]
- **User value**: [Benefit]
- **Tradeoffs**: [Tradeoffs]

**Recommendation**: Option X
**Rationale**: [1-2 sentences why this option is recommended]
```

### Example: Good Question

```markdown
## Question 1: Student Data Access Scope

**Context**: Spec mentions "teachers can view student progress" but doesn't specify boundaries.
- Current spec says: "Teachers can view student progress dashboard"
- Ambiguity: Can teachers view all students or only their assigned classes?

**Options**:

### Option A: All Students
- **Description**: Teachers can view progress for any student in the system
- **Implementation cost**: Low (no filtering needed)
- **User value**: Maximum flexibility for cross-class comparisons
- **Tradeoffs**: Privacy concern - teachers see unrelated students, may violate school policy

### Option B: Assigned Classes Only
- **Description**: Teachers can only view students in classes they teach
- **Implementation cost**: Medium (requires class assignment filtering)
- **User value**: Privacy-respecting, aligns with typical school policies
- **Tradeoffs**: Teachers cannot compare across classes they don't teach

### Option C: Configurable by Admin
- **Description**: School admin configures per-teacher access (all vs assigned)
- **Implementation cost**: High (requires admin UI + role config)
- **User value**: Maximum flexibility per school policy
- **Tradeoffs**: Added complexity, longer implementation (3-4 extra days)

**Recommendation**: Option B (Assigned classes only)
**Rationale**: Aligns with typical school privacy policies, medium implementation cost is justified by user trust and compliance.
```

### Example: Bad Question (Don't do this)

```markdown
## Question 1: Dashboard stuff

What do you want the dashboard to look like and what features should it have?

A. Good
B. Better
C. Best
```

**Problems**:
- Compound question (appearance AND features)
- No context explaining ambiguity
- Options are subjective and vague
- No implementation cost or tradeoffs
- No recommendation

---

## Question Types and Patterns

### Type 1: Scope Definition

**When to use**: Feature boundaries unclear

**Template**:
```markdown
## Question: [Feature] Scope

**Context**: Spec mentions [broad concept] but doesn't define boundaries.

**Options**:
A. Minimal scope: [Core feature only] (~X days)
B. Standard scope: [Core + common extensions] (~Y days)
C. Full scope: [Everything user mentioned] (~Z days)

**Recommendation**: Option B
**Rationale**: Balances user needs with reasonable timeline.
```

**Example scenarios**:
- "Export user data" → Which data? (profile only, activity logs, analytics, everything)
- "Search functionality" → What to search? (users, content, both)
- "Notifications" → Which events trigger? (all, critical only, user-configurable)

---

### Type 2: User Access Control

**When to use**: Permissions or roles unclear

**Template**:
```markdown
## Question: User Access Control for [Feature]

**Context**: Spec mentions [user type] but doesn't specify permissions.

**Options**:
A. View only: [User type] can read but not modify
B. View + Edit: [User type] can read and modify their own data
C. Full access: [User type] can read and modify all data

**Recommendation**: Option B
**Rationale**: Standard CRUD pattern with row-level security.
```

**Example scenarios**:
- "Users manage projects" → Can they edit all projects or only their own?
- "Admins configure settings" → Which settings? (all, security only, UI preferences only)
- "Teachers view students" → All students or assigned classes only?

---

### Type 3: Data Model Relationship

**When to use**: Entity relationships unclear

**Template**:
```markdown
## Question: [Entity A] to [Entity B] Relationship

**Context**: Spec implies relationship but doesn't specify cardinality.

**Options**:
A. One-to-many: Each [A] has multiple [B], but each [B] has one [A]
B. Many-to-many: Each [A] can have multiple [B], and each [B] can have multiple [A]
C. One-to-one: Each [A] has exactly one [B]

**Recommendation**: Option A
**Rationale**: Simpler model, sufficient for stated requirements.
```

**Example scenarios**:
- "Users create projects" → Can multiple users own one project? (many-to-many vs one-to-many)
- "Classes have teachers" → One teacher per class or multiple? (one-to-many vs many-to-many)
- "Products have categories" → One category or multiple? (one-to-many vs many-to-many)

---

### Type 4: Breaking Change Approval

**When to use**: Change impacts existing functionality

**Template**:
```markdown
## Question: [Feature] Breaking Change Approval

**Context**: Implementing this feature requires changing [existing behavior].

**Options**:
A. Breaking change: [New behavior] (may break existing integrations)
B. Backward compatible: [New behavior] with fallback to old behavior (more complexity)
C. New endpoint/feature: Keep old behavior, add new alternative (duplicates code)

**Recommendation**: Option B
**Rationale**: Protects existing users while delivering new functionality.
```

**Example scenarios**:
- "Add field to API response" → Break existing clients or version API?
- "Change authentication method" → Migrate all users or support both?
- "Rename database table" → Migration path or alias?

---

## Response Integration Patterns

### Pattern 1: Direct Requirement Update

**When to use**: Question directly clarifies a requirement

**Before clarification**:
```markdown
## Requirements

- Users can export data [NEEDS CLARIFICATION: Which format?]
```

**After clarification** (User chose CSV):
```markdown
## Requirements

- Users can export data in CSV format
  - Includes headers with field names
  - UTF-8 encoding with BOM for Excel compatibility
  - Maximum 100,000 rows per export
  - Download link expires after 24 hours
```

**Integration steps**:
1. Remove `[NEEDS CLARIFICATION]` marker
2. Replace with concrete requirement from chosen option
3. Add relevant implementation details from option description
4. Include any constraints mentioned in option tradeoffs

---

### Pattern 2: New Section Addition

**When to use**: Clarification adds entirely new context

**Before clarification**:
```markdown
## Requirements

- Dashboard displays student progress
```

**After clarification** (User chose Option B: Assigned classes only):
```markdown
## Requirements

- Dashboard displays student progress

## Access Control

**Teacher permissions**:
- View: Students in assigned classes only
- Filter: By class, date range, completion status
- Export: CSV of visible students only
- Restrictions: Cannot view students in other teachers' classes

**Implementation notes**:
- Class assignment table: `teacher_classes (teacher_id, class_id)`
- Dashboard query filters by: `WHERE class_id IN (SELECT class_id FROM teacher_classes WHERE teacher_id = current_user.id)`
```

**Integration steps**:
1. Add new section (e.g., "Access Control", "Data Model", "Security")
2. Document decision in detail with implementation notes
3. Cross-reference in Requirements section if needed

---

### Pattern 3: Assumption Documentation

**When to use**: Question was Medium/Low priority and not asked

**Before clarification**:
```markdown
## Requirements

- Users can export data [NEEDS CLARIFICATION: Which format?]
- Export has rate limiting [NEEDS CLARIFICATION: How many per day?]
```

**After clarification** (Format asked, rate limit assumed):
```markdown
## Requirements

- Users can export data in CSV format (see Question 1 response)

## Assumptions

### Export Rate Limiting (Not Clarified)
**Assumption**: 10 exports per day per user (standard rate limit)
**Rationale**: Prevents abuse while allowing normal usage. Based on industry standard for resource-intensive operations.
**Validation**: If users frequently hit limit, can increase to 20/day.
```

**Integration steps**:
1. Remove low-priority `[NEEDS CLARIFICATION]` markers
2. Create "Assumptions" section if not exists
3. Document each assumption with rationale and validation criteria

---

### Pattern 4: Clarifications Summary Section

**When to use**: Always, after any clarification phase

**Template**:
```markdown
## Clarifications (Resolved)

**Date**: YYYY-MM-DD
**Phase**: Clarification
**Questions asked**: N

### Q1: [Question title]
**Asked**: [Short version of question]
**Options**: A) [...], B) [...], C) [...]
**Decision**: Option B - [Option name]
**Rationale**: [Why this option was chosen]
**Impact**: [What this means for implementation]

### Q2: [Question title]
**Asked**: [Short version of question]
**Options**: A) [...], B) [...]
**Decision**: Option A - [Option name]
**Rationale**: [Why this option was chosen]
**Impact**: [What this means for implementation]

---

_All clarifications have been integrated into the spec above._
```

**Integration steps**:
1. Add section after all spec updates complete
2. Summarize each question and decision
3. Include rationale for audit trail
4. Note implementation impact for downstream phases

---

## Common Mistakes to Avoid

### ❌ Asking "How" Instead of "What"

**Bad**:
```markdown
## Question: How should we implement caching?
Options: Redis, Memcached, In-memory
```

**Why bad**: Technical implementation detail, not a spec-level decision

**Good**:
```markdown
## Question: Should dashboard data refresh in real-time or use cached data?

**Options**:
A. Real-time: Query database on every page load (<1s response time required)
B. Cached: Update every 5 minutes (faster page loads, slightly stale data)

**Recommendation**: Option B (cached with 5-minute refresh)
```

**Fix**: Focus on user-facing behavior, let planning phase choose caching tech

---

### ❌ Compound Questions

**Bad**:
```markdown
## Question: What features and design for dashboard?
```

**Why bad**: Mixes feature scope with UI design, forces user to answer multiple things at once

**Good**:
```markdown
## Question 1: Dashboard Feature Scope
[Focus on WHAT features to include]

## Question 2: Dashboard Layout Priority
[Focus on HOW to organize features]
```

**Fix**: Split into separate questions, ask feature scope first (Critical), defer layout to design phase (Low priority)

---

### ❌ Missing Options

**Bad**:
```markdown
## Question: Should we add notifications?

**Context**: Spec mentions users need to know about updates.

[No options provided]
```

**Why bad**: User doesn't know what answering "yes" or "no" means (email? push? in-app?)

**Good**:
```markdown
## Question: Notification Delivery Channels

**Context**: Spec mentions "users need to know about updates" but doesn't specify how.

**Options**:
A. Email only: Notifications sent to user email (simple, low cost)
B. Email + In-app: Email + notification bell icon (better UX, more dev time)
C. Multi-channel: Email + In-app + Push (optional) (most flexible, highest complexity)

**Recommendation**: Option B (Email + In-app)
```

**Fix**: Provide 2-3 concrete options with implementation implications

---

### ❌ No Context

**Bad**:
```markdown
## Question: Which format?

A. CSV
B. JSON
```

**Why bad**: User doesn't know what this is for or why it matters

**Good**:
```markdown
## Question: Export Data Format

**Context**: Spec mentions "users can export their activity data" but doesn't specify format.
- Current spec says: "Users can export data"
- Ambiguity: No format specified for downloads

**Options**:
A. CSV: Spreadsheet-friendly, opens in Excel (best for non-technical users)
B. JSON: API-friendly, structured data (best for technical users, integrations)
C. Both: User chooses on download (most flexible, adds UI complexity)

**Recommendation**: Option A (CSV) for MVP, add JSON if API integration needed
```

**Fix**: Always explain what's ambiguous and why options differ

---

## Validation Checklist

Before completing /clarify phase, validate:

**Question quality**:
- [ ] Each question has clear context (explains ambiguity)
- [ ] Each question has 2-3 concrete options
- [ ] Each option has implementation cost estimate
- [ ] Each option has user value and tradeoffs
- [ ] No compound questions (each asks one thing)
- [ ] No "how" questions (implementation details)
- [ ] Total questions ≤3

**Response integration**:
- [ ] All questions have user answers
- [ ] spec.md Requirements updated with concrete details
- [ ] All `[NEEDS CLARIFICATION]` markers removed
- [ ] Assumptions section added for deferred questions
- [ ] Clarifications summary section added
- [ ] Changes committed: `docs(spec): resolve clarifications for [feature]`

**Downstream readiness**:
- [ ] Planning phase can proceed with clear requirements
- [ ] No ambiguity remains in user-facing behavior
- [ ] Security/privacy decisions documented
- [ ] Scope boundaries clearly defined

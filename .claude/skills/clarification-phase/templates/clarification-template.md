# Clarification Question Template

Copy-paste template for generating structured clarification questions.

## Basic Template

```markdown
## Question N: [Specific, descriptive title]

**Context**: [2-3 sentences explaining the ambiguity]
- Current spec says: "[Quote relevant section]"
- Ambiguity: [What's unclear or missing?]
- Impact: [How does this affect implementation?]

**Options**:

### Option A: [Descriptive name]
- **Description**: [2-3 sentences explaining this choice]
- **Implementation cost**: [Time estimate: ~N days or Low/Medium/High]
- **User value**: [Benefit to end users]
- **Tradeoffs**: [What you give up or risks]

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

---

## Filled Example

```markdown
## Question 1: Student Data Access Scope

**Context**: Spec states "teachers can view student progress dashboard" but doesn't define access boundaries.
- Current spec says: "Teachers view student progress including completion rates and time spent"
- Ambiguity: Can teachers view all students or only students in their assigned classes?
- Impact: Affects authorization logic, database queries, and compliance with education privacy regulations (FERPA)

**Options**:

### Option A: All Students Visible
- **Description**: Teachers can view progress for any student in the system
- **Implementation cost**: Low (~1 day) - no authorization filtering needed
- **User value**: Maximum flexibility for department heads to compare across classes
- **Tradeoffs**: Privacy risk - teachers see students they don't teach; may violate school policy or FERPA

### Option B: Assigned Classes Only
- **Description**: Teachers only view students in classes they teach, filtered by class_assignments table
- **Implementation cost**: Medium (~2 days) - requires class assignment filtering in queries and UI
- **User value**: Privacy-respecting, aligns with standard education privacy practices
- **Tradeoffs**: Teachers cannot cross-compare classes they don't teach; requires class assignment management

**Recommendation**: Option B (Assigned Classes Only)
**Rationale**: Aligns with FERPA and typical school privacy policies. Medium implementation cost is justified by regulatory compliance and user trust.
```

---

## Template for Different Question Types

### Type: Scope Definition

```markdown
## Question: [Feature] Scope Definition

**Context**: Spec mentions [broad feature] but doesn't define boundaries.
- Current spec says: "[Quote]"
- Ambiguity: Which parts of [feature] are in scope vs out of scope?
- Impact: Affects timeline, complexity, and success criteria

**Options**:

### Option A: Minimal Scope
- **Description**: [Core functionality only]
- **Implementation cost**: [Estimate] (~X days)
- **User value**: [Core benefit delivered quickly]
- **Tradeoffs**: [Missing advanced features, may need future extension]

### Option B: Standard Scope
- **Description**: [Core + commonly expected extensions]
- **Implementation cost**: [Estimate] (~Y days, Y > X)
- **User value**: [Complete feature set for typical use case]
- **Tradeoffs**: [Longer timeline, but avoids immediate follow-up work]

### Option C: Full Scope
- **Description**: [Everything mentioned in spec]
- **Implementation cost**: [Estimate] (~Z days, Z > Y)
- **User value**: [Comprehensive solution]
- **Tradeoffs**: [Longest timeline, risk of over-engineering]

**Recommendation**: Option B
**Rationale**: Balances user needs with reasonable timeline.
```

---

### Type: Access Control

```markdown
## Question: User Access Control for [Feature]

**Context**: Spec mentions [user role] using [feature] but doesn't specify permissions.
- Current spec says: "[Quote]"
- Ambiguity: What can [user role] do? (View, Edit, Delete, Admin)
- Impact: Affects authorization model and security posture

**Options**:

### Option A: Read-Only Access
- **Description**: [User role] can view data but not modify
- **Implementation cost**: Low (~1 day) - simple role check
- **User value**: [Safe exploration without risk of accidental changes]
- **Tradeoffs**: [Limited functionality, may frustrate power users]

### Option B: Read + Edit Own Data
- **Description**: [User role] can view all data but only modify their own records
- **Implementation cost**: Medium (~2 days) - row-level security filtering
- **User value**: [Standard CRUD permissions, user can manage their content]
- **Tradeoffs**: [Cannot modify others' data, may need escalation for cross-user operations]

### Option C: Full Access
- **Description**: [User role] can view and modify all data
- **Implementation cost**: Low (~1 day) - role check only
- **User value**: [Maximum flexibility, no restrictions]
- **Tradeoffs**: [Security risk if role is broadly assigned, audit requirements]

**Recommendation**: Option B
**Rationale**: Standard permission model with row-level security.
```

---

### Type: Data Model Relationship

```markdown
## Question: [Entity A] to [Entity B] Relationship

**Context**: Spec implies relationship between [A] and [B] but doesn't specify cardinality.
- Current spec says: "[Quote]"
- Ambiguity: Can one [A] have multiple [B]? Can one [B] have multiple [A]?
- Impact: Affects database schema, migration strategy, and UI design

**Options**:

### Option A: One-to-Many ([A] → [B])
- **Description**: Each [A] has multiple [B], but each [B] belongs to exactly one [A]
- **Implementation cost**: Low (~1 day) - simple foreign key
- **User value**: [Clear ownership, simple to understand]
- **Tradeoffs**: [Cannot share [B] across multiple [A], may limit flexibility]

### Option B: Many-to-Many ([A] ↔ [B])
- **Description**: Each [A] can have multiple [B], and each [B] can belong to multiple [A]
- **Implementation cost**: Medium (~2-3 days) - junction table, UI for management
- **User value**: [Maximum flexibility, supports sharing and collaboration]
- **Tradeoffs**: [More complex queries, UI for managing associations]

**Recommendation**: Option A for MVP
**Rationale**: Simpler model sufficient for stated requirements. Can migrate to many-to-many later if sharing needed.
```

---

### Type: Breaking Change Decision

```markdown
## Question: [Feature] Breaking Change Approval

**Context**: Implementing [feature] requires changing [existing behavior].
- Current behavior: [Describe current state]
- Required change: [Describe new state]
- Ambiguity: Is breaking change acceptable or must we maintain backward compatibility?
- Impact: Affects existing users/integrations, migration strategy, timeline

**Options**:

### Option A: Breaking Change
- **Description**: Change [existing behavior] immediately. Existing users/integrations must adapt.
- **Implementation cost**: Low (~X days) - direct implementation
- **User value**: [Clean solution, no technical debt]
- **Tradeoffs**: [BREAKS existing users, requires coordinated deployment, potential downtime]

### Option B: Backward Compatible
- **Description**: Add new behavior while preserving old behavior (versioning, feature flags, or fallback)
- **Implementation cost**: Medium (~Y days, Y > X) - dual implementation + migration path
- **User value**: [Zero downtime, users migrate at their own pace]
- **Tradeoffs**: [Technical debt, maintenance burden of two code paths]

### Option C: Deprecation Path
- **Description**: Add new behavior, deprecate old behavior with 3-6 month sunset timeline
- **Implementation cost**: High (~Z days, Z > Y) - new implementation + deprecation warnings + docs
- **User value**: [Time to migrate without rush, clear sunset date]
- **Tradeoffs**: [Longest timeline, still requires eventual migration work]

**Recommendation**: Option [X]
**Rationale**: [Justify based on user impact, active user count, migration complexity]
```

---

## Question Checklist

Before finalizing clarification questions, verify:

**Context**:
- [ ] Explains what's ambiguous in spec
- [ ] Quotes relevant spec section
- [ ] Describes impact on implementation

**Options**:
- [ ] Provides 2-3 concrete options
- [ ] Each option has clear description
- [ ] Implementation cost estimated
- [ ] User value stated
- [ ] Tradeoffs explicitly listed

**Recommendation**:
- [ ] Suggests specific option (A/B/C)
- [ ] Includes rationale (1-2 sentences)

**Priority**:
- [ ] Question is Critical or High priority (scope/security/access control)
- [ ] NOT a "how to build" question (technical implementation)
- [ ] NOT a question with obvious industry-standard default

---

## Response Integration Template

After user answers clarification questions, use this template to integrate into spec.md:

```markdown
## Clarifications (Resolved)

**Date**: YYYY-MM-DD
**Phase**: Clarification
**Questions asked**: N

### Q1: [Question title]
**Asked**: [Short version: "Which metrics should dashboard display?"]
**Options**: A) Completion only, B) Completion + Time, C) Full analytics
**Decision**: Option B - Completion + Time
**Rationale**: Balances insight with implementation cost (~3 days vs ~6 days for Option C)
**Impact**:
- Dashboard displays: lesson completion rate + time spent per lesson
- Database queries: JOIN lessons + time_logs tables
- Performance target: <1s load time for 500 students

[Update Requirements section above with concrete details from chosen option]

### Q2: [Question title]
**Asked**: [Short version]
**Options**: A) [...], B) [...], C) [...]
**Decision**: Option X - [Option name]
**Rationale**: [Why chosen]
**Impact**: [Implementation implications]

---

_All clarifications have been integrated into Requirements section above._
_Any [NEEDS CLARIFICATION] markers have been removed._
```

---

## Common Pitfalls

### ❌ Asking multiple things in one question

**Bad**: "What features and design should the dashboard have?"

**Good**:
- Question 1 (Critical): "Which metrics should dashboard display?" (Scope decision)
- Defer to design phase: Dashboard layout and visual design

### ❌ Asking "how" instead of "what"

**Bad**: "Should we use Redis or Memcached for caching?"

**Good**: "Should dashboard data refresh in real-time or use 5-minute cached data?" (User-facing behavior)

### ❌ Missing implementation cost

**Bad**:
```
Option A: All features
Option B: Some features
```

**Good**:
```
Option A: Core features (~3 days)
Option B: Core + Advanced features (~7 days)
```

### ❌ Vague options

**Bad**: "Make it good, Make it better, Make it best"

**Good**: "Completion rate only (2 days), Completion + Time (3 days), Full analytics (6 days)"

---

_Use this template to maintain consistent clarification quality across all features._

# Clarification Phase Examples

Examples of good and bad clarification questions with analysis.

## Good Clarification Examples

### Example 1: Dashboard Access Scope (Critical Priority)

```markdown
## Question 1: Student Data Access Scope

**Context**: Spec states "teachers can view student progress dashboard" but doesn't define access boundaries.
- Current spec says: "Teachers view student progress including completion rates and time spent"
- Ambiguity: Can teachers view all students in the system or only students in their assigned classes?
- Impact: Affects data model, authorization logic, and user privacy

**Options**:

### Option A: All Students Visible
- **Description**: Teachers can view progress for any student in the system, filtered by class or search
- **Implementation cost**: Low (~1 day) - no authorization filtering needed beyond teacher role
- **User value**: Maximum flexibility for cross-class comparisons, useful for department heads
- **Tradeoffs**: Privacy concern - teachers see students they don't teach; may violate FERPA or school policy

### Option B: Assigned Classes Only
- **Description**: Teachers only view students in classes they currently teach, based on class_assignments table
- **Implementation cost**: Medium (~2 days) - requires class assignment filtering in all queries
- **User value**: Privacy-respecting, aligns with typical school policies and teacher-student relationships
- **Tradeoffs**: Teachers cannot compare across classes they don't teach; requires class assignment management

### Option C: Hierarchical Access
- **Description**: Teachers see assigned classes; department heads see department; admins see all
- **Implementation cost**: High (~4 days) - requires role hierarchy, organizational structure modeling
- **User value**: Most flexible, accommodates different staff roles and organizational needs
- **Tradeoffs**: Complex authorization logic, requires organizational structure definition upfront

**Recommendation**: Option B (Assigned Classes Only)
**Rationale**: Aligns with standard education privacy practices (FERPA), medium implementation cost justified by user trust and regulatory compliance. Can upgrade to Option C in future if organizational hierarchy needed.
```

**Why this is good**:
- ✅ Critical scope decision (who sees what data)
- ✅ Clear context explaining privacy implications
- ✅ Three distinct options with concrete differences
- ✅ Implementation cost quantified (1 day, 2 days, 4 days)
- ✅ Tradeoffs explicit (privacy vs flexibility)
- ✅ Recommendation with rationale

---

### Example 2: Data Model Relationship (High Priority)

```markdown
## Question 2: Project-to-User Ownership Model

**Context**: Spec mentions "users create projects" but doesn't specify ownership model.
- Current spec says: "Users can create, edit, and delete projects"
- Ambiguity: Can a project have multiple owners, or is it always one user per project?
- Impact: Affects database schema, permission model, and collaboration features

**Options**:

### Option A: Single Owner
- **Description**: Each project has exactly one owner (creator). Owner can transfer ownership but only one owner at a time.
- **Implementation cost**: Low (~1 day) - simple foreign key: projects.owner_id → users.id
- **User value**: Clear ownership, simple permission model (owner = full control, others = none or collaborator)
- **Tradeoffs**: No co-ownership; if owner leaves, project must be transferred or orphaned

### Option B: Multiple Owners
- **Description**: Projects can have multiple owners with equal privileges. Uses join table: project_owners(project_id, user_id).
- **Implementation cost**: Medium (~2-3 days) - many-to-many relationship, UI for owner management
- **User value**: Team ownership, no single point of failure, multiple people can manage project
- **Tradeoffs**: More complex permission logic; requires UI for adding/removing owners

**Recommendation**: Option A (Single Owner) for MVP
**Rationale**: Simpler implementation, sufficient for stated use case ("users create projects"). Can add collaborators without full ownership in future. Option B adds complexity without clear requirement for co-ownership in spec.
```

**Why this is good**:
- ✅ High priority (affects schema design)
- ✅ Clear impact statement (database + permissions)
- ✅ Two focused options (not over-engineered)
- ✅ Recommendation suggests MVP path with future option

---

### Example 3: Breaking Change Decision (Critical Priority)

```markdown
## Question 3: API Response Format Change

**Context**: New feature requires adding "assignedClasses" array to User API response, but existing mobile app expects flat structure.
- Current API: `GET /api/v1/users/{id}` returns `{ id, name, email, role }`
- New requirement: Include assigned classes for teachers
- Ambiguity: Should we modify existing endpoint (breaking) or create new version?

**Options**:

### Option A: Breaking Change (Add to v1)
- **Description**: Add "assignedClasses": [] to existing /api/v1/users/{id} response. Mobile app must update.
- **Implementation cost**: Low (~1 day backend) + mobile app update required
- **User value**: Single source of truth, no API version fragmentation
- **Tradeoffs**: BREAKS existing mobile app (v2.1.0 and below); requires coordinated deploy

### Option B: New API Version (v2)
- **Description**: Create /api/v2/users/{id} with new field. Keep v1 unchanged for backward compatibility.
- **Implementation cost**: Medium (~3 days) - duplicate endpoint logic, version routing, deprecation plan
- **User value**: Zero downtime, mobile app updates at its own pace
- **Tradeoffs**: API version sprawl, maintenance burden for two versions

### Option C: Optional Field
- **Description**: Add "assignedClasses" only when query param ?include=classes is provided. Default behavior unchanged.
- **Implementation cost**: Medium (~2 days) - sparse fieldset implementation
- **User value**: Backward compatible, opt-in for new clients
- **Tradeoffs**: Inconsistent API patterns if not used across all endpoints

**Recommendation**: Option B (New API version v2)
**Rationale**: Mobile app has 10k+ active users on v2.1.0. Breaking change risks bad user experience. Cost of v2 endpoint (~3 days) is justified by zero-downtime migration. Deprecate v1 after 6 months.
```

**Why this is good**:
- ✅ Critical decision (breaking vs non-breaking)
- ✅ Real-world context (existing mobile app impact)
- ✅ Quantifies blast radius (10k users)
- ✅ Includes migration timeline (6 month deprecation)

---

## Bad Clarification Examples

### Example 1: Vague Question (Too Broad)

```markdown
## Question: What should the dashboard do?

**Context**: User wants a dashboard.

**Options**:
A. Make it good
B. Make it better
C. Make it the best

**Recommendation**: Option C
```

**Why this is bad**:
- ❌ No specific context about ambiguity
- ❌ Options are subjective and vague
- ❌ No implementation cost or tradeoffs
- ❌ Doesn't actually clarify anything
- ❌ User cannot make informed decision

**How to fix**:
```markdown
## Question: Dashboard Metric Scope

**Context**: Spec mentions "student progress dashboard" but doesn't define which metrics to display.
- Current spec says: "Display student progress"
- Ambiguity: Which metrics? (completion rate, time spent, quiz scores, engagement)

**Options**:
A. Completion only: % of lessons finished (~2 days implementation)
B. Completion + Time: Lessons finished + hours logged (~3 days)
C. Full analytics: Completion + Time + Scores + Engagement (~6 days, requires analytics infrastructure)

**Recommendation**: Option B
**Rationale**: Balances insight with implementation cost.
```

---

### Example 2: Compound Question (Multiple Decisions)

```markdown
## Question: Dashboard features and design

What features should the dashboard have and what should it look like and how should it work?

A. All the features
B. Some features
```

**Why this is bad**:
- ❌ Three questions in one (features + design + behavior)
- ❌ Forces user to answer everything at once
- ❌ Options don't address the compound nature
- ❌ No clear path to answering

**How to fix**: Split into separate questions

```markdown
## Question 1: Dashboard Feature Scope (Critical - ask now)

**Context**: Spec mentions dashboard but doesn't define feature set.

**Options**:
A. View only: Display metrics, no interactions (~2 days)
B. View + Filter: Display + filter by date/class (~4 days)
C. View + Filter + Export: Full analytics with CSV export (~6 days)

**Recommendation**: Option B

---

## Question 2: Dashboard Layout (Low priority - defer to design phase)

[Don't ask this in clarification phase - let design phase handle it]
```

---

### Example 3: Technical "How" Question (Wrong Phase)

```markdown
## Question: Which database should we use?

**Context**: We need to store data.

**Options**:
A. PostgreSQL
B. MySQL
C. MongoDB

**Recommendation**: PostgreSQL
```

**Why this is bad**:
- ❌ Technical implementation detail, not spec-level decision
- ❌ No user-facing impact mentioned
- ❌ Belongs in planning phase, not clarification
- ❌ User shouldn't have to know database internals

**How to fix**: Convert to user-facing question or defer

```markdown
## NOT a clarification question - Defer to planning phase

**Decision needed**: Database choice
**Current thinking**: PostgreSQL (supports JSON, full-text search, strong ACID guarantees)
**Deferred to**: Planning phase will evaluate based on query patterns and scale requirements
```

---

### Example 4: Missing Context (No Explanation)

```markdown
## Question: Format?

A. CSV
B. JSON

**Recommendation**: CSV
```

**Why this is bad**:
- ❌ No context (format for what?)
- ❌ No explanation of ambiguity
- ❌ No tradeoffs between options
- ❌ User doesn't know implications

**How to fix**: Add context and tradeoffs

```markdown
## Question: Export Data Format

**Context**: Spec states "users can export their activity data" but doesn't specify file format.
- Current spec: "Users can download their data"
- Ambiguity: No format specified for exported files
- Impact: Affects file generation, user workflow (Excel vs API consumption)

**Options**:

### Option A: CSV
- **Description**: Comma-separated values file, opens directly in Excel/Google Sheets
- **Implementation cost**: Low (~1 day) - simple serialization
- **User value**: Non-technical users can analyze in familiar tools
- **Tradeoffs**: Limited structure (flat rows), no nested data

### Option B: JSON
- **Description**: Structured JSON file, suitable for API consumers and developers
- **Implementation cost**: Low (~1 day) - native serialization
- **User value**: Full structure preserved, good for technical users
- **Tradeoffs**: Non-technical users may not know how to open

### Option C: Both Formats
- **Description**: User chooses CSV or JSON at export time via dropdown
- **Implementation cost**: Medium (~2 days) - UI for selection + both serializers
- **User value**: Serves both technical and non-technical users
- **Tradeoffs**: More complex UI, maintenance for two formats

**Recommendation**: Option A (CSV) for MVP
**Rationale**: Target users are teachers (non-technical). Add JSON later if API integration requested.
```

---

### Example 5: Non-Critical Detail (Has Reasonable Default)

```markdown
## Question: Cache duration?

How long should we cache dashboard data?

A. 5 minutes
B. 10 minutes
C. 15 minutes

**Recommendation**: ???
```

**Why this is bad**:
- ❌ Low priority technical detail
- ❌ All options are reasonable defaults
- ❌ User cannot make informed choice (no context on tradeoffs)
- ❌ Wastes limited clarification budget (max 3 questions)

**How to fix**: Remove question, use informed guess

```markdown
## NOT a clarification question - Use informed guess

**Decision**: Cache duration for dashboard data
**Assumption**: 5-minute TTL (balance between freshness and performance)
**Rationale**: Industry standard for dashboard-style data. Fresh enough for teachers checking student progress, cached enough to reduce database load.
**Validation**: Monitor cache hit rate and user complaints about staleness. Adjust if needed.

[Document this in spec.md Assumptions section, don't ask user]
```

---

## Side-by-Side Comparison

| Aspect | Good Clarification | Bad Clarification |
|--------|-------------------|-------------------|
| **Priority** | Critical/High scope decisions | Low-priority technical details |
| **Context** | Explains ambiguity + impact | Missing or vague context |
| **Options** | 2-3 concrete, distinct choices | Vague or subjective options |
| **Cost** | Implementation time estimated | No cost information |
| **Tradeoffs** | Explicit pros/cons per option | Missing tradeoff analysis |
| **Recommendation** | Suggested option with rationale | No recommendation or unclear reasoning |
| **Question count** | ≤3 questions total | >5 questions (over budget) |
| **Focus** | WHAT feature does (user-facing) | HOW to build (technical impl) |

---

## Real-World Feature Examples

*This section will be populated as real features go through /clarify:*

### Feature: [Feature Name]

**Date**: YYYY-MM-DD
**Questions asked**: N
**Response time**: N hours
**Integration quality**: ✅ Complete | ⚠️ Partial | ❌ Incomplete

**Questions**:
1. [Question title] - Priority: Critical/High/Medium
2. [Question title] - Priority: Critical/High/Medium

**Lessons learned**:
- [What worked well]
- [What could improve]
- [Pattern to reuse]

---

_Examples updated as features complete clarification phase._

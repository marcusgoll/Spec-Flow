# Roadmap Integration — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-17

This document provides comprehensive reference material for the `/roadmap` command, including data models, state machines, validation rules, and integration workflows.

---

## Table of Contents

1. [GitHub Data Model](#github-data-model)
2. [Label System](#label-system)
3. [State Machine](#state-machine)
4. [Vision Alignment Validation](#vision-alignment-validation)
5. [Milestone Management](#milestone-management)
6. [Epic Management](#epic-management)
7. [Sprint Management](#sprint-management)
8. [Quality Gates](#quality-gates)
9. [Error Handling](#error-handling)
10. [Script Functions](#script-functions)

---

## GitHub Data Model

GitHub Issues serve as the **single source of truth** for the product roadmap.

### Label Namespaces

Use **namespaced labels** with colon separators for predictable state management:

#### Status Labels (exactly one required)

- `status:backlog` - New ideas waiting to be worked on
- `status:next` - Promoted from backlog, ready to start soon
- `status:later` - Deprioritized, future consideration
- `status:in-progress` - Actively being worked on
- `status:shipped` - Completed and deployed (issue closed)
- `status:blocked` - Cannot proceed, waiting on dependency

#### Type Labels (exactly one required)

- `type:feature` - New functionality
- `type:enhancement` - Improvement to existing feature
- `type:bug` - Bug fix
- `type:task` - Non-feature work (refactoring, cleanup, etc.)

#### Area Labels (at least one required)

- `area:backend` - Backend/API work
- `area:frontend` - Frontend/UI work
- `area:api` - API contracts and integration
- `area:infra` - Infrastructure, deployment, DevOps
- `area:design` - Design system, UX, visual design
- `area:marketing` - Marketing, content, growth

#### Role Labels (zero or one)

- `role:all` - Affects all user types
- `role:free` - Free tier users
- `role:student` - Student pilots
- `role:cfi` - Certified Flight Instructors
- `role:school` - Flight school administrators

#### Sprint Labels (zero or one, 2-week cadence)

- `sprint:S01` through `sprint:S12` - 12 sprints per cycle
- Example: `sprint:S03` = Week 5-6
- Sprints are for execution planning, NOT releases

#### Epic Labels (zero or one, dynamic)

- `epic:auth-system`, `epic:dashboard-v2`, `epic:reporting-engine`, etc.
- Created dynamically when features define epics
- Groups related features for coordinated delivery

#### Size Labels (optional)

- `size:small` - < 4 hours
- `size:medium` - 4-16 hours
- `size:large` - 16-40 hours
- `size:xl` - > 40 hours (consider splitting)

#### Priority Labels (optional manual override)

- `priority:high` - Override creation order, work this first
- `priority:medium` - Normal priority
- `priority:low` - Nice-to-have, low urgency
- **Default**: Sort by creation order (first created = highest priority)
- **Use**: Manual overrides for urgent bugs or strategic features

#### Special Labels

- `blocked` - Waiting on external dependency
- `good-first-issue` - Beginner-friendly task
- `help-wanted` - Seeking contributors
- `wont-fix` - Rejected/deleted feature
- `duplicate` - Duplicate of another issue
- `needs-clarification` - Requires more detail

### Label Invariants

**Strict rules enforced by scripts:**

- **Exactly one** `status:*` label per issue (scripts remove old before adding new)
- **Exactly one** `type:*` label per issue
- **At least one** `area:*` label per issue (can have multiple)
- **At most one** `role:*` label per issue
- **At most one** `sprint:*` label per issue
- **At most one** `epic:*` label per issue
- **Zero or more** `priority:*`, `size:*`, special labels

**Violation handling**: Scripts automatically remove conflicting labels before adding new ones.

### Milestones

Milestones represent **release buckets**, NOT sprints.

**Purpose**: Release planning and forecasting ("what ships in v1.0?")

**Examples**:
- `v1.0 MVP` - Minimum viable product release
- `v2.0 Platform` - Major platform upgrade
- `2026-Q1` - Quarterly release
- `Pilot Schools Alpha` - Customer pilot program

**Rules**:
- Issues in `status:next` or `status:in-progress` **should** have a milestone (recommended)
- New issues can be created without milestone (default to Backlog)
- Milestones provide release forecasting and "what ships in v1.0" answers
- Shipped issues remain in their milestone for release history

**Milestone vs Sprint**:
- **Sprints** (labels: `sprint:S01-S12`) = 2-week execution cycles
- **Milestones** (GitHub Milestones) = Release buckets (v1.0, v2.0, Q1)
- A milestone may span multiple sprints
- Example: v1.0 includes work from sprint:S01, sprint:S02, sprint:S03

### Issue Metadata (Frontmatter)

All roadmap issues include YAML frontmatter with metadata:

```markdown
---
metadata:
  area: app
  role: student
  type: feature
  status: backlog
  size: m
  slug: student-progress-widget
  epic: dashboard-v2
  sprint: S04
  alignment_note: ""
---

## Problem

Students struggle to visualize their mastery progress...

## Proposed Solution

Add a dashboard widget showing mastery percentage...

## Requirements

- [ ] Display mastery percentage for each ACS area
- [ ] Color-coded progress bars
...
```

**Frontmatter mirrors labels**: Labels are set on GitHub Issue to match metadata fields.

---

## Label System

### Label Creation

**Epic labels** are created dynamically when referenced:

```bash
create_epic_label "auth-system" "Authentication and authorization epic"
```

**Sprint labels** should be created during project setup:

```bash
# Create all 12 sprint labels
for i in {01..12}; do
  create_sprint_label "S$i"
done
```

**Area, type, status, role labels** are created during GitHub repo setup.

### Label Color Conventions

- **Status labels**: Blue tones (0EA5E9, 3B82F6, 6366F1)
- **Type labels**: Green/Yellow/Red (10B981, F59E0B, EF4444)
- **Area labels**: Purple tones (8B5CF6, A855F7, C084FC)
- **Epic labels**: Purple (8B5CF6) — consistent color
- **Sprint labels**: Gray tones (6B7280)
- **Priority labels**: Red scale (F87171, EF4444, DC2626)
- **Size labels**: Teal scale (14B8A6, 0D9488, 0F766E)

---

## State Machine

Roadmap issues flow through a **fixed state lifecycle** with enforced transitions.

### State Definitions

| State | Label | Description | Issue Open/Closed |
|-------|-------|-------------|-------------------|
| **Backlog** | `status:backlog` | New ideas waiting to be worked on | Open |
| **Next** | `status:next` | Promoted from backlog, ready to start soon | Open |
| **Later** | `status:later` | Deprioritized, future consideration | Open |
| **In Progress** | `status:in-progress` | Actively being worked on | Open |
| **Blocked** | `status:blocked` | Cannot proceed, waiting on dependency | Open |
| **Shipped** | `status:shipped` | Completed and deployed to production | **Closed** |

### Valid State Transitions

```
Backlog ──┐
          ├──> Next ──> In Progress ──> Shipped (issue closed)
          │       │
          │       └──> Blocked ──> In Progress
          │
          └──> Later
```

**Allowed transitions**:

From `status:backlog`:
- → `status:next` (promoted for upcoming work)
- → `status:later` (deprioritized)
- → `status:in-progress` (started immediately, rare)

From `status:next`:
- → `status:in-progress` (work started)
- → `status:backlog` (deprioritized back to backlog)
- → `status:blocked` (dependencies discovered before starting)

From `status:in-progress`:
- → `status:shipped` (completed and deployed, **issue closes**)
- → `status:blocked` (dependency blocks progress)

From `status:blocked`:
- → `status:in-progress` (dependency resolved, resume work)
- → `status:backlog` (blocker requires rethinking, reset to backlog)

From `status:later`:
- → `status:backlog` (re-prioritized)
- → `status:next` (directly promoted if needed)

### Transition Rules

**When moving to `status:in-progress`**:
1. **MUST have milestone assigned** (enforced by `move_issue_to_section()`)
   - Script prompts user to select milestone if missing
   - Milestones represent release buckets (v1.0, v2.0, Q1-2026)
   - Ensures all work is tied to a release target

**When moving to `status:shipped`**:
1. **Issue automatically closes** (state = closed, reason = completed)
2. **Label `status:shipped` added** for filtering shipped features
3. **Milestone remains assigned** (provides release history)

**When creating new issue**:
1. **Default state**: `status:backlog`
2. **Required labels**: `type:*`, `area:*`, `status:backlog`
3. **Optional labels**: `role:*`, `sprint:*`, `epic:*`, `size:*`, `priority:*`

### Automated Actions

**On state transition** (`move_issue_to_section()` enforces):

1. **Remove ALL existing `status:*` labels** (enforce exactly-one invariant)
2. **Add new `status:*` label**
3. **If target = `in-progress` AND no milestone assigned**:
   - Display available milestones
   - Prompt user to assign milestone (required)
4. **If target = `shipped`**:
   - Close issue with reason "completed"
   - Keep `status:shipped` label for filtering

**On issue creation** (`create_roadmap_issue()` enforces):

1. **Epic label auto-creation**: If epic parameter provided:
   - Check if `epic:$name` label exists
   - Create label if missing (purple color, description)
   - Add `epic:$name` to issue

2. **Sprint label**: If sprint parameter provided (S01-S12):
   - Add `sprint:$sprint` to issue
   - Sprint labels must already exist (created via setup script)

3. **Milestone assignment**:
   - New issues default to no milestone (Backlog state)
   - Milestone required when moving to In Progress

### State Machine Invariants

**Enforced by scripts**:

1. **Exactly one `status:*` label per issue** — Script removes all before adding new
2. **status:shipped ⟷ issue closed** — Shipped state always means issue is closed
3. **status:in-progress → milestone required** — Can't start work without release target
4. **Label creation order = priority** — Oldest issues in Backlog have highest priority

**NOT enforced** (manual management):

1. Epic/sprint labels can change freely (user manages)
2. Multiple `area:*` labels allowed (cross-cutting features)
3. Priority labels (`priority:high`) override creation order manually

---

## Vision Alignment Validation

Vision alignment validation runs **only for ADD and BRAINSTORM actions** when `docs/project/overview.md` exists.

### Validation Workflow

```
1. Read overview.md and extract:
   - Vision (1 paragraph)
   - Out-of-Scope exclusions (bullet list)
   - Target Users (bullet list)

2. For each proposed feature:
   a. Check if feature is in Out-of-Scope list
      → If YES: Prompt user (Skip / Update overview / Override)

   b. Check if feature supports Vision
      → If NO: Prompt user (Add anyway / Revise / Skip)

   c. Confirm primary target user
      → Store as role label

3. Only create GitHub Issue after validation passes or user overrides
```

### Validation Output Example

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 VISION ALIGNMENT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Vision:
AKTR helps flight instructors track student progress against ACS standards.

Proposed Feature:
  Add student progress widget showing mastery by ACS area

✅ Feature aligns with project vision

Target User Check:
Primary user: Flight students

✅ Vision alignment complete
```

### Out-of-Scope Detection

If a proposed feature matches an explicit exclusion from `overview.md`:

```
❌ OUT-OF-SCOPE DETECTED

This feature matches an explicit exclusion:
  "Flight scheduling or aircraft management" (overview.md:45)

Options:
  A) Skip (reject out-of-scope feature)
  B) Update overview.md (remove exclusion if scope changed)
  C) Add anyway (override with justification)
```

**If user selects C (Override)**:
- Add `alignment_note` to issue frontmatter
- Document justification for future reference

### Vision Misalignment

If feature doesn't clearly support the vision:

```
⚠️  Potential misalignment detected

Concerns:
  - Feature focuses on social networking, not ACS tracking
  - No clear connection to competency demonstration

Options:
  A) Add anyway (alignment override)
  B) Revise feature to align
  C) Skip (not aligned with vision)
```

**If user selects A (Override)**:
- Add `alignment_note` to issue frontmatter
- Tag with `needs-clarification` label

### Missing Project Docs Warning

If `docs/project/overview.md` doesn't exist:

```
⚠️  Missing Project Documentation

Vision alignment validation skipped (no overview.md found).

Recommendation: Run /init-project for vision-aligned roadmap

Creating issue in Backlog without validation...
```

---

## Milestone Management

### Milestone Naming Conventions

- **Version releases**: `v1.0 MVP`, `v2.0 Platform`, `v3.0 Enterprise`
- **Quarterly releases**: `2026-Q1`, `2026-Q2`, `2026-Q3`, `2026-Q4`
- **Customer pilots**: `Pilot Schools Alpha`, `Enterprise Beta`
- **Feature releases**: `Dashboard Refresh`, `Mobile App Launch`

### Milestone Planning Workflow

1. **List existing milestones** to avoid duplicates:
   ```bash
   list_milestones
   ```

2. **Create milestone** with due date and description:
   ```bash
   create_milestone "v1.0 MVP" "2025-12-31" "Initial production release with core features"
   ```

3. **Plan milestone** by assigning backlog issues:
   ```bash
   plan_milestone "v1.0 MVP"
   ```
   - Shows backlog issues sorted by creation order (priority)
   - Interactively select issues to assign
   - Issues assigned to milestone are ready for `/feature` workflow

### Milestone Assignment Rules

- **Issues in `status:backlog` or `status:later`**: No milestone required
- **Issues moving to `status:in-progress`**: **Milestone REQUIRED** (script enforces)
- **Issues moving to `status:shipped`**: Milestone preserved for release history

### Example Planning Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 MILESTONE PLANNING: v1.0 MVP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Backlog issues (creation order = priority):

1. #98 cfi-batch-export (Created: 2025-11-01)
2. #87 study-plan-generator (Created: 2025-11-05)
3. #123 student-progress-widget (Created: 2025-11-13)
4. #145 endorsement-generator (Created: 2025-11-15)

Enter issue numbers to assign to 'v1.0 MVP' (space-separated, or 'done'):
> 98 87 123

  ✅ Assigned #98 to v1.0 MVP
  ✅ Assigned #87 to v1.0 MVP
  ✅ Assigned #123 to v1.0 MVP

✅ Milestone planning complete
```

---

## Epic Management

### When to Use Epics

Epics group **related features** for coordinated delivery across multiple sprints.

### Epic Naming Conventions (kebab-case)

- `auth-system` — Authentication and authorization
- `dashboard-v2` — Dashboard redesign
- `reporting-engine` — Reporting infrastructure
- `mobile-app` — Mobile application
- `api-v2` — API version 2 migration

### Epic Creation Workflow

1. **List existing epics** to see what's active:
   ```bash
   list_epic_labels
   ```

2. **Create epic label** (if new epic discovered):
   ```bash
   create_epic_label "auth-system" "Authentication and authorization epic"
   ```

3. **Add epic to issue** when creating:
   ```bash
   create_roadmap_issue "$TITLE" "$BODY" "$AREA" "$ROLE" "$SLUG" "type:feature,status:backlog" "auth-system"
   ```

### Epic Label Properties

- **Namespace**: `epic:$name` (e.g., `epic:auth-system`)
- **Color**: Purple (8B5CF6) — consistent epic color
- **Dynamic creation**: Epic labels auto-created when referenced in issue creation
- **Description**: "Epic: $name" (auto-generated if not provided)

### Epic Assignment Rules

- **At most one epic per issue** (label invariant)
- **Epics can span multiple milestones** (epics ≠ releases)
- **Issues can be in epic without milestone** (epic is coordination, milestone is release target)

### Example Output

```
Epic Labels:

  epic:auth-system - Authentication and authorization epic
  epic:dashboard-v2 - Dashboard redesign epic
  epic:reporting-engine - Reporting infrastructure

✅ Created epic label: epic:mobile-app
```

---

## Sprint Management

### When to Use Sprints

Sprints are **2-week execution cycles** (12 sprints per development cycle).

### Sprint Label Schema

- `sprint:S01` — Week 1-2
- `sprint:S02` — Week 3-4
- `sprint:S03` — Week 5-6
- ...
- `sprint:S12` — Week 23-24

### Sprint vs Milestone

- **Sprints** (`sprint:*` labels) = Execution cadence (2-week iterations)
- **Milestones** (GitHub Milestones) = Release targets (v1.0, v2.0, Q1-2026)
- **Example**: Milestone "v1.0 MVP" may span sprint:S01, sprint:S02, sprint:S03

### Sprint Assignment

Sprints are assigned during feature creation or updated manually:

```bash
create_roadmap_issue "$TITLE" "$BODY" "$AREA" "$ROLE" "$SLUG" "type:feature,status:backlog" "$EPIC" "S03"
```

### Sprint Assignment Rules

- **At most one sprint label per issue** (label invariant)
- **Sprint labels are planning hints**, not hard constraints
- **Sprint can change** as work progresses (user manages manually)
- **Sprints are NOT milestones** — an issue in sprint:S03 may target milestone v1.0 or v2.0

### Sprint Workflow Integration

1. **Plan sprint**: Assign `sprint:S03` to issues in `status:next`
2. **Execute sprint**: Move issues to `status:in-progress` (milestone enforced)
3. **Ship sprint**: Move completed issues to `status:shipped`
4. **Next sprint**: Clear `sprint:S03`, assign `sprint:S04` to next batch

---

## Quality Gates

### Blocking Validations (ADD/BRAINSTORM only)

1. **Out-of-Scope Gate** — Feature not in explicit exclusion list
   - Override: User provides justification, adds ALIGNMENT_NOTE

2. **Vision Alignment Gate** — Feature supports project vision
   - Override: User revises feature or adds ALIGNMENT_NOTE

### Non-Blocking Warnings

1. **Missing Project Docs** — overview.md not found
   - Warning: "Run /init-project for vision-aligned roadmap"
   - Impact: Vision validation skipped

2. **Large Feature** — >30 requirements
   - Warning: "Consider splitting before /feature"
   - Impact: `size:xl` label added

---

## Error Handling

### GitHub Authentication Missing

```
❌ GitHub authentication required

Options:
  A) GitHub CLI: gh auth login
  B) API Token: export GITHUB_TOKEN=ghp_your_token

See: docs/github-roadmap-migration.md
```

### Feature Out of Scope

```
❌ OUT-OF-SCOPE DETECTED

This feature matches an explicit exclusion:
  "Flight scheduling or aircraft management" (overview.md:45)

Options:
  A) Skip (reject out-of-scope feature)
  B) Update overview.md (remove exclusion if scope changed)
  C) Add anyway (override with justification)
```

### Vision Misalignment

```
⚠️  Potential misalignment detected

Concerns:
  - Feature focuses on social networking, not ACS tracking
  - No clear connection to competency demonstration

Options:
  A) Add anyway (alignment override)
  B) Revise feature to align
  C) Skip (not aligned with vision)
```

---

## Script Functions

### Bash Script Functions

Located in `.spec-flow/scripts/bash/github-roadmap-manager.sh`:

#### Authentication

- `check_github_auth()` — Returns "gh-cli", "api-token", or "none"
- `get_repo_info()` — Returns "owner/repo" from git remote

#### Issue Management

- `create_roadmap_issue(title, body, area, role, slug, labels, epic, sprint)` — Create GitHub Issue
- `move_issue_to_section(slug, target)` — Change issue status (enforces milestone requirement)
- `delete_roadmap_issue(slug)` — Close and mark as wont-fix
- `search_roadmap(query)` — Search issues by keyword/area/role
- `show_roadmap_summary()` — Display count by status

#### Milestone Functions

- `list_milestones()` — List all milestones with due dates
- `create_milestone(title, due_date, description)` — Create new milestone
- `plan_milestone(milestone_name)` — Interactively assign backlog issues

#### Epic Functions

- `list_epic_labels()` — List all epic:* labels
- `create_epic_label(name, description)` — Create epic label (purple, auto-namespaced)

#### Sprint Functions

- `create_sprint_label(number)` — Create sprint:S## label
- `list_sprint_labels()` — List all sprint:* labels

### PowerShell Script Functions

Located in `.spec-flow/scripts/powershell/github-roadmap-manager.ps1`:

Functions mirror Bash implementation with PowerShell conventions:

- `Test-GitHubAuth` — Check authentication method
- `Get-RepositoryInfo` — Get owner/repo from git remote
- `New-RoadmapIssue` — Create GitHub Issue
- `Move-IssueToSection` — Change issue status
- `Remove-RoadmapIssue` — Close and mark as wont-fix
- `Search-Roadmap` — Search issues
- `Show-RoadmapSummary` — Display status summary
- `Get-Milestones` — List milestones
- `New-Milestone` — Create milestone
- `Set-MilestonePlan` — Assign issues to milestone
- `Get-EpicLabels` — List epic labels
- `New-EpicLabel` — Create epic label
- `New-SprintLabel` — Create sprint label
- `Get-SprintLabels` — List sprint labels

---

## Workflow Integration

```
/roadmap add "feature name" → creates issue in Backlog
/feature next → claims oldest "Next" issue
/feature [slug] → claims specific issue
/ship → marks issue as Shipped
```

**State transitions during feature workflow**:

1. `/roadmap add` → Creates issue with `status:backlog`
2. `/roadmap move [slug] next` → Changes to `status:next`
3. `/feature [slug]` → Changes to `status:in-progress` (milestone enforced)
4. `/ship` → Changes to `status:shipped` (closes issue)

---

## Notes

**Prioritization:**
- Features prioritized by **creation order** (first created = highest priority)
- No manual priority scoring (removed ICE framework)
- Move features to "Next" to promote them

**Vision validation:**
- Only runs if `docs/project/overview.md` exists
- Can be overridden by user with justification
- Adds ALIGNMENT_NOTE to issue body if overridden

**Integration:**
- Roadmap is the **source** for feature workflows
- `/feature` command reads from roadmap to select next work
- `/ship` command updates roadmap to mark completion
- Milestones provide release planning and forecasting

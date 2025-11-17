---
description: "Standard Operating Procedure for /roadmap usage. Manage product roadmap via GitHub Issues (brainstorm, prioritize, track). Auto-validates features against project vision (from overview.md) before adding to roadmap. Triggers when user runs /roadmap or mentions 'roadmap', 'add feature', 'brainstorm ideas', or 'prioritize features'. (project)"
version: 2.0
updated: 2025-11-17
---

# /roadmap — Product Feature Management

**Purpose**: Brainstorm features, validate against project vision, track shipped features (prioritized by creation order).

**When to use**: Add features to roadmap, brainstorm ideas, move features between states, search roadmap.

**Workflow integration**: Roadmap → `/feature` → spec → plan → implement → ship

---

## Mental Model

You are managing a **product roadmap** via GitHub Issues with **vision alignment validation**.

**Key concepts**:
- **GitHub Issues** = roadmap backend (label-based state management)
- **Vision validation** = automatic check against `docs/project/overview.md`
- **Creation order** = priority (first created = first worked on)
- **State management** = Backlog → Next → In Progress → Shipped

---

## GitHub Data Model

GitHub is the **single source of truth** for the roadmap.

### Labels (Colon Namespace Convention)

Use **namespaced labels** with colon separators for predictable state management:

**Status** (exactly one required):
- `status:backlog` - New ideas waiting to be worked on
- `status:next` - Promoted from backlog, ready to start soon
- `status:later` - Deprioritized, future consideration
- `status:in-progress` - Actively being worked on
- `status:shipped` - Completed and deployed (issue closed)
- `status:blocked` - Cannot proceed, waiting on dependency

**Type** (exactly one required):
- `type:feature` - New functionality
- `type:enhancement` - Improvement to existing feature
- `type:bug` - Bug fix
- `type:task` - Non-feature work (refactoring, cleanup, etc.)

**Area** (at least one required):
- `area:backend` - Backend/API work
- `area:frontend` - Frontend/UI work
- `area:api` - API contracts and integration
- `area:infra` - Infrastructure, deployment, DevOps
- `area:design` - Design system, UX, visual design
- `area:marketing` - Marketing, content, growth

**Role** (zero or one):
- `role:all` - Affects all user types
- `role:free` - Free tier users
- `role:student` - Student pilots
- `role:cfi` - Certified Flight Instructors
- `role:school` - Flight school administrators

**Sprint** (zero or one, 2-week cadence):
- `sprint:S01` through `sprint:S12` - 12 sprints per cycle
- Example: `sprint:S03` = Week 5-6
- Sprints are for execution planning, NOT releases

**Epic** (zero or one, dynamic):
- `epic:auth-system`, `epic:dashboard-v2`, `epic:reporting-engine`, etc.
- Created dynamically when features define epics
- Groups related features for coordinated delivery

**Size** (optional):
- `size:small` - < 4 hours
- `size:medium` - 4-16 hours
- `size:large` - 16-40 hours
- `size:xl` - > 40 hours (consider splitting)

**Priority** (optional manual override):
- `priority:high` - Override creation order, work this first
- `priority:medium` - Normal priority
- `priority:low` - Nice-to-have, low urgency
- **Default**: Sort by creation order (first created = highest priority)
- **Use**: Manual overrides for urgent bugs or strategic features

**Special Labels**:
- `blocked` - Waiting on external dependency
- `good-first-issue` - Beginner-friendly task
- `help-wanted` - Seeking contributors
- `wont-fix` - Rejected/deleted feature
- `duplicate` - Duplicate of another issue
- `needs-clarification` - Requires more detail

### Label Invariants (Enforced by Scripts)

**Strict rules**:
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

## Execution

### Step 1: Parse User Intent

**Identify action type from natural language:**

```bash
INTENT="${ARGUMENTS:-}"

# Parse action
case "$INTENT" in
  add|create|new*)
    ACTION="add"
    DESCRIPTION="${INTENT#add }"
    ;;
  brainstorm|ideas|suggest*)
    ACTION="brainstorm"
    TOPIC="${INTENT#brainstorm }"
    ;;
  move|update*)
    ACTION="move"
    SLUG=$(echo "$INTENT" | awk '{print $2}')
    TARGET=$(echo "$INTENT" | awk '{print $4}')
    ;;
  delete|remove*)
    ACTION="delete"
    SLUG=$(echo "$INTENT" | awk '{print $2}')
    ;;
  search|find*)
    ACTION="search"
    QUERY="${INTENT#search }"
    ;;
  prioritize|list*)
    ACTION="list"
    ;;
  milestone*)
    # Parse milestone sub-action: "milestone list", "milestone create v1.0", "milestone plan v1.0"
    ACTION="milestone"
    MILESTONE_ACTION=$(echo "$INTENT" | awk '{print $2}')
    MILESTONE_ARG=$(echo "$INTENT" | awk '{print $3}')
    ;;
  epic*)
    # Parse epic sub-action: "epic list", "epic create auth-system"
    ACTION="epic"
    EPIC_ACTION=$(echo "$INTENT" | awk '{print $2}')
    EPIC_ARG=$(echo "$INTENT" | awk '{print $3}')
    ;;
  *)
    ACTION="list"
    ;;
esac
```

**Action types**:
- `add` — Add new feature with vision validation
- `brainstorm` — Generate feature ideas via web research
- `move` — Change feature status (Backlog → Next → In Progress)
- `delete` — Remove feature from roadmap
- `search` — Find features by keyword/area/role
- `list` — Show roadmap summary
- `milestone` — Manage milestones (list, create, plan)
- `epic` — Manage epic labels (list, create)

---

### Step 2: Execute Action via Scripts

**Use existing roadmap management scripts:**

**Bash (macOS/Linux):**
```bash
# Source roadmap manager
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Check GitHub authentication
AUTH_METHOD=$(check_github_auth)

if [ "$AUTH_METHOD" = "none" ]; then
  echo "❌ GitHub authentication required"
  echo ""
  echo "Options:"
  echo "  A) GitHub CLI: gh auth login"
  echo "  B) API Token: export GITHUB_TOKEN=ghp_your_token"
  exit 1
fi

REPO=$(get_repo_info)

echo "✅ GitHub authenticated ($AUTH_METHOD)"
echo "✅ Repository: $REPO"
echo ""

# Execute action
case "$ACTION" in
  add)
    # Load project docs for vision validation (if exists)
    if [ -f "docs/project/overview.md" ]; then
      HAS_PROJECT_DOCS=true
      # Claude Code: Read docs/project/overview.md
      # Extract: Vision, Out-of-Scope, Target Users
    fi

    # Vision alignment validation
    if [ "$HAS_PROJECT_DOCS" = true ]; then
      # Claude Code: Validate feature against vision
      # Check 1: Out-of-scope exclusions
      # Check 2: Vision alignment (semantic)
      # Check 3: Target user validation
    fi

    # Create GitHub Issue
    create_roadmap_issue "$TITLE" "$BODY" "$AREA" "$ROLE" "$SLUG" "type:feature,status:backlog"
    ;;

  brainstorm)
    # Claude Code: Web research for feature ideas related to $TOPIC
    # Generate 5-10 feature proposals
    # For each: validate vision alignment, create issue
    ;;

  move)
    move_issue_to_section "$SLUG" "$TARGET"
    ;;

  delete)
    delete_roadmap_issue "$SLUG"
    ;;

  search)
    search_roadmap "$QUERY"
    ;;

  list)
    show_roadmap_summary
    ;;

  milestone)
    case "$MILESTONE_ACTION" in
      list)
        list_milestones
        ;;
      create)
        # Example: /roadmap milestone create "v1.0 MVP" "2025-12-31" "Initial release"
        read -r -p "Milestone title: " MILESTONE_TITLE
        read -r -p "Due date (YYYY-MM-DD, or blank): " DUE_DATE
        read -r -p "Description (or blank): " DESCRIPTION
        create_milestone "$MILESTONE_TITLE" "$DUE_DATE" "$DESCRIPTION"
        ;;
      plan)
        # Example: /roadmap milestone plan "v1.0 MVP"
        plan_milestone "$MILESTONE_ARG"
        ;;
      *)
        list_milestones
        ;;
    esac
    ;;

  epic)
    case "$EPIC_ACTION" in
      list)
        list_epic_labels
        ;;
      create)
        # Example: /roadmap epic create "auth-system" "Authentication and authorization epic"
        read -r -p "Epic name (kebab-case): " EPIC_NAME
        read -r -p "Description (or blank): " EPIC_DESCRIPTION
        create_epic_label "$EPIC_NAME" "$EPIC_DESCRIPTION"
        ;;
      *)
        list_epic_labels
        ;;
    esac
    ;;
esac
```

**PowerShell (Windows):**
```powershell
# Import roadmap manager
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Check authentication
$authMethod = Test-GitHubAuth

if ($authMethod -eq "none") {
  Write-Host "❌ GitHub authentication required" -ForegroundColor Red
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  A) GitHub CLI: gh auth login"
  Write-Host "  B) API Token: `$env:GITHUB_TOKEN = 'ghp_your_token'"
  exit 1
}

$repo = Get-RepositoryInfo

Write-Host "✅ GitHub authenticated ($authMethod)" -ForegroundColor Green
Write-Host "✅ Repository: $repo" -ForegroundColor Green
Write-Host ""

# Execute action
switch ($ACTION) {
  "add" {
    # Load project docs
    if (Test-Path "docs/project/overview.md") {
      $hasProjectDocs = $true
      # Claude Code: Read docs/project/overview.md
    }

    # Vision validation
    if ($hasProjectDocs) {
      # Claude Code: Validate feature alignment
    }

    # Create issue
    New-RoadmapIssue -Title $title -Body $body -Area $area -Role $role -Slug $slug -Labels "type:feature,status:backlog"
  }

  "brainstorm" {
    # Claude Code: Generate feature ideas
  }

  "move" {
    Move-IssueToSection -Slug $slug -Target $target
  }

  "delete" {
    Remove-RoadmapIssue -Slug $slug
  }

  "search" {
    Search-Roadmap -Query $query
  }

  "list" {
    Show-RoadmapSummary
  }

  "milestone" {
    switch ($MILESTONE_ACTION) {
      "list" {
        Get-Milestones
      }
      "create" {
        $title = Read-Host "Milestone title"
        $dueDate = Read-Host "Due date (YYYY-MM-DD, or blank)"
        $description = Read-Host "Description (or blank)"
        New-Milestone -Title $title -DueDate $dueDate -Description $description
      }
      "plan" {
        Set-MilestonePlan -MilestoneName $MILESTONE_ARG
      }
      default {
        Get-Milestones
      }
    }
  }

  "epic" {
    switch ($EPIC_ACTION) {
      "list" {
        Get-EpicLabels
      }
      "create" {
        $epicName = Read-Host "Epic name (kebab-case)"
        $description = Read-Host "Description (or blank)"
        New-EpicLabel -Name $epicName -Description $description
      }
      default {
        Get-EpicLabels
      }
    }
  }
}
```

---

## State Machine

**Roadmap issues flow through a fixed state lifecycle with enforced transitions:**

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

## After Script Completes, You (LLM) Must:

### 1) Vision Alignment Validation (ADD/BRAINSTORM actions)

**If `docs/project/overview.md` exists:**

```
Read overview.md and extract:
- Vision (1 paragraph)
- Out-of-Scope exclusions (bullet list)
- Target Users (bullet list)

For each proposed feature:
1. Check if feature is in Out-of-Scope list
   → If YES: Prompt user (Skip / Update overview / Override)

2. Check if feature supports Vision
   → If NO: Prompt user (Add anyway / Revise / Skip)

3. Confirm primary target user
   → Store as role label

Only create GitHub Issue after validation passes or user overrides
```

**Example validation output:**

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

---

### 2) GitHub Issue Creation

**Format issue with metadata:**

```markdown
---
metadata:
  area: app
  role: student
  slug: student-progress-widget
---

## Problem

Students struggle to visualize their mastery progress across different ACS areas.

## Proposed Solution

Add a dashboard widget showing mastery percentage grouped by ACS area (e.g., Preflight, Maneuvers, Navigation).

## Requirements

- [ ] Display mastery percentage for each ACS area
- [ ] Color-coded progress bars (red <50%, yellow 50-80%, green >80%)
- [ ] Click area to drill down into specific tasks
- [ ] Mobile-responsive design
```

**Labels auto-applied:**
- `area:app` (or backend, frontend, api, infra, design, marketing)
- `role:student` (or all, free, cfi, school)
- `type:feature`
- `status:backlog`

---

### 3) Return Roadmap Summary

**Show current state:**

```
✅ Created issue #123: student-progress-widget in Backlog
   Area: app | Role: student

📊 Roadmap Summary:
   Backlog: 12 | Next: 3 | In Progress: 2 | Shipped: 45

Top 3 in Backlog (oldest/highest priority):
1. #98 cfi-batch-export (Created: 2025-11-01)
2. #87 study-plan-generator (Created: 2025-11-05)
3. #123 student-progress-widget (Created: 2025-11-13)

💡 Next: /feature cfi-batch-export
```

---

### 4) Handle Brainstorm Action

**For brainstorming:**

1. **Web research** — Search for feature ideas related to topic
2. **Generate proposals** — Create 5-10 feature ideas
3. **Vision validation** — Check each against project vision
4. **Create issues** — Add aligned features to roadmap
5. **Summary** — Show added features and rejection reasons

**Example brainstorm output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 BRAINSTORM: CFI Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generated 8 feature ideas from research:

✅ Added to roadmap (6):
1. #124 cfi-batch-export — Export multiple student reports
2. #125 lesson-plan-templates — Reusable lesson structures
3. #126 endorsement-generator — Auto-fill logbook endorsements
4. #127 student-analytics — Progress trends and insights
5. #128 flight-debrief-forms — Post-flight feedback templates
6. #129 currency-tracker — Track instructor currency requirements

❌ Rejected (2):
- Flight scheduling system — Out of scope (overview.md:45)
- Social media integration — Doesn't support vision

📊 Roadmap Summary:
   Backlog: 18 | Next: 3 | In Progress: 2 | Shipped: 45

💡 Next: /roadmap prioritize backlog
```

---

### 5) Milestone Management

**When creating/planning milestones:**

**Milestone Naming Conventions**:
- **Version releases**: `v1.0 MVP`, `v2.0 Platform`, `v3.0 Enterprise`
- **Quarterly releases**: `2026-Q1`, `2026-Q2`, `2026-Q3`, `2026-Q4`
- **Customer pilots**: `Pilot Schools Alpha`, `Enterprise Beta`
- **Feature releases**: `Dashboard Refresh`, `Mobile App Launch`

**Milestone Planning Workflow**:

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

**Milestone Assignment Rules**:
- **Issues in `status:backlog` or `status:later`**: No milestone required
- **Issues moving to `status:in-progress`**: **Milestone REQUIRED** (script enforces)
- **Issues moving to `status:shipped`**: Milestone preserved for release history

**Example output**:

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

### 6) Epic Management

**When to use epics:**

Epics group related features for coordinated delivery across multiple sprints.

**Epic Naming Conventions** (kebab-case):
- `auth-system` — Authentication and authorization
- `dashboard-v2` — Dashboard redesign
- `reporting-engine` — Reporting infrastructure
- `mobile-app` — Mobile application
- `api-v2` — API version 2 migration

**Epic Creation Workflow**:

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

**Epic Label Properties**:
- **Namespace**: `epic:$name` (e.g., `epic:auth-system`)
- **Color**: Purple (8B5CF6) — consistent epic color
- **Dynamic creation**: Epic labels auto-created when referenced in issue creation
- **Description**: "Epic: $name" (auto-generated if not provided)

**Epic Assignment Rules**:
- **At most one epic per issue** (label invariant)
- **Epics can span multiple milestones** (epics ≠ releases)
- **Issues can be in epic without milestone** (epic is coordination, milestone is release target)

**Example output**:

```
Epic Labels:

  epic:auth-system - Authentication and authorization epic
  epic:dashboard-v2 - Dashboard redesign epic
  epic:reporting-engine - Reporting infrastructure

✅ Created epic label: epic:mobile-app
```

---

### 7) Sprint Management

**When to use sprints:**

Sprints are **2-week execution cycles** (12 sprints per development cycle).

**Sprint Label Schema**:
- `sprint:S01` — Week 1-2
- `sprint:S02` — Week 3-4
- `sprint:S03` — Week 5-6
- ...
- `sprint:S12` — Week 23-24

**Sprint vs Milestone**:
- **Sprints** (`sprint:*` labels) = Execution cadence (2-week iterations)
- **Milestones** (GitHub Milestones) = Release targets (v1.0, v2.0, Q1-2026)
- **Example**: Milestone "v1.0 MVP" may span sprint:S01, sprint:S02, sprint:S03

**Sprint Assignment**:

Sprints are assigned during feature creation or updated manually:

```bash
create_roadmap_issue "$TITLE" "$BODY" "$AREA" "$ROLE" "$SLUG" "type:feature,status:backlog" "$EPIC" "S03"
```

**Sprint Assignment Rules**:
- **At most one sprint label per issue** (label invariant)
- **Sprint labels are planning hints**, not hard constraints
- **Sprint can change** as work progresses (user manages manually)
- **Sprints are NOT milestones** — an issue in sprint:S03 may target milestone v1.0 or v2.0

**Sprint Workflow Integration**:

1. **Plan sprint**: Assign `sprint:S03` to issues in `status:next`
2. **Execute sprint**: Move issues to `status:in-progress` (milestone enforced)
3. **Ship sprint**: Move completed issues to `status:shipped`
4. **Next sprint**: Clear `sprint:S03`, assign `sprint:S04` to next batch

---

## Quality Gates

**Blocking validations (ADD/BRAINSTORM only):**

1. **Out-of-Scope Gate** — Feature not in explicit exclusion list
   - Override: User provides justification, adds ALIGNMENT_NOTE

2. **Vision Alignment Gate** — Feature supports project vision
   - Override: User revises feature or adds ALIGNMENT_NOTE

**Non-blocking warnings:**

1. **Missing Project Docs** — overview.md not found
   - Warning: "Run /init-project for vision-aligned roadmap"
   - Impact: Vision validation skipped

2. **Large Feature** — >30 requirements
   - Warning: "Consider splitting before /feature"
   - Impact: `size:xl` label added

---

## Error Handling

**GitHub authentication missing:**
```
❌ GitHub authentication required

Options:
  A) GitHub CLI: gh auth login
  B) API Token: export GITHUB_TOKEN=ghp_your_token

See: docs/github-roadmap-migration.md
```

**Feature out of scope:**
```
❌ OUT-OF-SCOPE DETECTED

This feature matches an explicit exclusion:
  "Flight scheduling or aircraft management" (overview.md:45)

Options:
  A) Skip (reject out-of-scope feature)
  B) Update overview.md (remove exclusion if scope changed)
  C) Add anyway (override with justification)
```

**Vision misalignment:**
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

## Notes

**Prioritization:**
- Features prioritized by **creation order** (first created = highest priority)
- No manual priority scoring (removed ICE framework)
- Move features to "Next" to promote them

**Roadmap states:**
- **Backlog** — Ideas waiting to be worked on
- **Next** — Up next (promoted from Backlog)
- **In Progress** — Currently being implemented
- **Shipped** — Completed and deployed

**Vision validation:**
- Only runs if `docs/project/overview.md` exists
- Can be overridden by user with justification
- Adds ALIGNMENT_NOTE to issue body if overridden

**Integration:**
- `/roadmap add` → creates issue in Backlog
- `/feature next` → claims oldest "Next" issue
- `/feature [slug]` → claims specific issue
- `/ship` → marks issue as Shipped

---

## References

- **Skill**: `.claude/skills/roadmap-integration/SKILL.md` (full SOP)
- **Scripts**:
  - `.spec-flow/scripts/bash/github-roadmap-manager.sh`
  - `.spec-flow/scripts/powershell/github-roadmap-manager.ps1`
- **Project docs**: `docs/project/overview.md` (vision, scope, users)

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
}
```

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

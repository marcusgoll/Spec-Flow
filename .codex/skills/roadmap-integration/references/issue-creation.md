# GitHub Issue Creation

## Step 5: GitHub Issue Creation

### Actions
1. Generate URL-friendly slug from title
2. Check for duplicate slugs
3. Extract area and role
4. Create GitHub Issue with YAML frontmatter metadata
5. Auto-apply labels
6. Features prioritized by creation order (oldest first)

---

## Bash Implementation

```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Generate slug from title (max 30 chars)
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | cut -c1-30)

# Check for duplicates
EXISTING_ISSUE=$(get_issue_by_slug "$SLUG")
if [ -n "$EXISTING_ISSUE" ]; then
  echo "⚠️  Slug '$SLUG' already exists (Issue #$EXISTING_ISSUE)"
  SLUG="${SLUG}-v2"  # Append version suffix
fi

# Format requirements as markdown body
BODY="## Problem

$PROBLEM_STATEMENT

## Proposed Solution

$SOLUTION_DESCRIPTION

## Requirements

$REQUIREMENTS_LIST${ALIGNMENT_NOTE:-}"

# Create issue (no ICE parameters - prioritized by creation order)
create_roadmap_issue \
  "$TITLE" \
  "$BODY" \
  "$AREA" \
  "$ROLE" \
  "$SLUG" \
  "type:feature,status:backlog"

# Output: Created issue #123
```

---

## PowerShell Implementation

```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Generate slug (max 30 chars)
$slug = $title.ToLower() -replace '[^a-z0-9-]', '-' -replace '--+', '-' |
        Select-Object -First 1 | ForEach-Object { $_.Substring(0, [Math]::Min(30, $_.Length)) }

# Check for duplicates
$existingIssue = Get-IssueBySlug -Slug $slug
if ($existingIssue) {
  Write-Host "⚠️  Slug '$slug' already exists (Issue #$($existingIssue.number))" -ForegroundColor Yellow
  $slug = "$slug-v2"  # Append version suffix
}

# Format body
$body = @"
## Problem

$problemStatement

## Proposed Solution

$solutionDescription

## Requirements

$requirementsList$(if ($alignmentNote) { $alignmentNote } else { '' })
"@

# Create issue (no ICE parameters - prioritized by creation order)
New-RoadmapIssue `
  -Title $title `
  -Body $body `
  -Area $area `
  -Role $role `
  -Slug $slug `
  -Labels "type:feature,status:backlog"
```

---

## Issue Structure

### YAML Frontmatter (Auto-added)

```yaml
---
metadata:
  area: app
  role: student
  slug: student-progress-widget
---
```

**Fields:**
- `area`: System area (backend, frontend, api, infra, design, marketing)
- `role`: Target user role (all, free, student, cfi, school)
- `slug`: URL-friendly identifier (max 30 chars, unique)

### Body Format

```markdown
## Problem
Students struggle to track mastery percentage across different ACS areas, making it difficult to identify weak spots.

## Proposed Solution
Add a progress widget to the student dashboard showing mastery percentage grouped by ACS area (e.g., Preflight Procedures, Airport Operations, etc.). Color-code by proficiency level.

## Requirements
- [ ] Display mastery % per ACS area
- [ ] Color-code by proficiency level (red <50%, yellow 50-79%, green 80%+)
- [ ] Export progress report as PDF
- [ ] Update in real-time when lesson completed

---

⚠️  **Alignment Note**: Validated against project vision (overview.md)
```

---

## Labels Auto-Applied

### Area Labels
- `area:backend` - API, database, server logic
- `area:frontend` - UI components, client-side
- `area:api` - API contracts, endpoints
- `area:infra` - Infrastructure, deployment, CI/CD
- `area:design` - Design system, brand, UX
- `area:marketing` - Marketing site, landing pages

### Role Labels
- `role:all` - All users
- `role:free` - Free tier users
- `role:student` - Flight students
- `role:cfi` - Certified Flight Instructors
- `role:school` - Flight school administrators

### Type and Status
- `type:feature` - New feature (default)
- `type:bug` - Bug fix
- `type:chore` - Maintenance task
- `status:backlog` - Initial status
- `status:next` - Queued for planning
- `status:in-progress` - Actively implementing
- `status:shipped` - Deployed to production

---

## Prioritization Strategy

### Creation-Order Prioritization

**Rule:** Oldest issue in Backlog = highest priority

**Rationale:**
- Simplicity: No complex scoring needed
- Fairness: First-in-first-out approach
- Stability: Priorities don't shift arbitrarily
- Speed: No time spent debating scores

**How it works:**
1. Issues added to Backlog (status:backlog)
2. Listed by creation date (oldest first)
3. Top of list = next feature to implement
4. Move to "Next" when ready to plan (3-5 item queue)
5. Move to "In Progress" when actively implementing
6. Close with "Shipped" label when deployed

**Example Backlog:**
```
Top 3 in Backlog (oldest/highest priority):
1. #98 cfi-batch-export (Created: 2025-11-01)  ← Work on this first
2. #87 study-plan-generator (Created: 2025-11-05)
3. #123 student-progress-widget (Created: 2025-11-13)
```

### Moving Between Statuses

```bash
# Mark ready for planning (move to Next queue)
mark_issue_next "cfi-batch-export"
# Updates label: status:backlog → status:next

# Mark in progress (implementation started)
mark_issue_in_progress "cfi-batch-export"
# Updates label: status:next → status:in-progress

# Mark shipped (deployed to production)
mark_issue_shipped "cfi-batch-export"
# Updates label: status:in-progress → status:shipped
# Closes issue
```

---

## Metadata Extraction

### Area Detection

Extract from feature description keywords:

```bash
extract_area() {
  DESCRIPTION="$1"

  if echo "$DESCRIPTION" | grep -qiE 'api|endpoint|graphql|rest'; then
    echo "api"
  elif echo "$DESCRIPTION" | grep -qiE 'ui|component|screen|page|dashboard'; then
    echo "frontend"
  elif echo "$DESCRIPTION" | grep -qiE 'database|migration|query|schema'; then
    echo "backend"
  elif echo "$DESCRIPTION" | grep -qiE 'deploy|ci|cd|pipeline|docker'; then
    echo "infra"
  elif echo "$DESCRIPTION" | grep -qiE 'design|brand|style|theme'; then
    echo "design"
  elif echo "$DESCRIPTION" | grep -qiE 'marketing|landing|seo|analytics'; then
    echo "marketing"
  else
    echo "app"  # Default catchall
  fi
}
```

### Role Detection

Extract from vision validation (target user check):

```bash
extract_role() {
  PRIMARY_USER="$1"

  # Normalize to slug format
  ROLE=$(echo "$PRIMARY_USER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

  # Map variations
  case "$ROLE" in
    *student*|*pilot*)
      echo "student"
      ;;
    *instructor*|*cfi*)
      echo "cfi"
      ;;
    *school*|*admin*)
      echo "school"
      ;;
    *free*|*trial*)
      echo "free"
      ;;
    *)
      echo "all"
      ;;
  esac
}
```

### Slug Generation

```bash
generate_slug() {
  TITLE="$1"

  # Convert to lowercase
  SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')

  # Replace non-alphanumeric with hyphens
  SLUG=$(echo "$SLUG" | sed 's/[^a-z0-9-]/-/g')

  # Collapse multiple hyphens
  SLUG=$(echo "$SLUG" | sed 's/--*/-/g')

  # Trim leading/trailing hyphens
  SLUG=$(echo "$SLUG" | sed 's/^-//;s/-$//')

  # Limit to 30 characters
  SLUG=$(echo "$SLUG" | cut -c1-30)

  # Trim trailing hyphen (if cut mid-word)
  SLUG=$(echo "$SLUG" | sed 's/-$//')

  echo "$SLUG"
}
```

**Examples:**
- "Student Progress Widget" → `student-progress-widget`
- "CFI Batch Export (PDF/CSV)" → `cfi-batch-export-pdf-csv`
- "Add dark mode theme toggle!!!" → `add-dark-mode-theme-toggle`

---

## Duplicate Slug Handling

```bash
check_duplicate_slug() {
  SLUG="$1"
  REPO=$(get_repo_info)

  # Search for issue with this slug in metadata
  EXISTING=$(gh issue list --repo "$REPO" --state all --json number,body --jq ".[] | select(.body | contains(\"slug: $SLUG\")) | .number")

  if [ -n "$EXISTING" ]; then
    echo "$EXISTING"  # Return issue number
  else
    echo ""  # No duplicate
  fi
}
```

**Conflict resolution:**
```bash
SLUG="user-auth"
EXISTING_ISSUE=$(check_duplicate_slug "$SLUG")

if [ -n "$EXISTING_ISSUE" ]; then
  echo "⚠️  Slug '$SLUG' already exists (Issue #$EXISTING_ISSUE)"

  # Strategy 1: Append version suffix
  SLUG="${SLUG}-v2"

  # Strategy 2: Append area
  SLUG="${SLUG}-${AREA}"

  # Strategy 3: Append role
  SLUG="${SLUG}-${ROLE}"

  # Re-check
  EXISTING_ISSUE=$(check_duplicate_slug "$SLUG")
fi
```

---

## Example Issue Creation

**Input:**
```bash
TITLE="Student progress widget"
PROBLEM="Students can't see mastery percentage by ACS area"
SOLUTION="Add progress widget to dashboard"
REQUIREMENTS="
- [ ] Display mastery % per area
- [ ] Color-code by level
- [ ] Export as PDF"
AREA="frontend"
ROLE="student"
```

**Generated Issue:**

```
Issue #123: Student progress widget

---
metadata:
  area: frontend
  role: student
  slug: student-progress-widget
---

## Problem
Students can't see mastery percentage by ACS area

## Proposed Solution
Add progress widget to dashboard

## Requirements
- [ ] Display mastery % per area
- [ ] Color-code by level
- [ ] Export as PDF

---

⚠️  **Alignment Note**: Validated against project vision (overview.md)

Labels: area:frontend, role:student, type:feature, status:backlog
Created: 2025-11-13
```

---

## Integration with /feature Command

When `/feature` is invoked:

```bash
# /feature student-progress-widget

# Step 1: Fetch GitHub Issue by slug
ISSUE=$(get_issue_by_slug "student-progress-widget")

# Step 2: Extract metadata
AREA=$(echo "$ISSUE" | jq -r '.body' | grep 'area:' | awk '{print $2}')
ROLE=$(echo "$ISSUE" | jq -r '.body' | grep 'role:' | awk '{print $2}')

# Step 3: Extract requirements from issue body
REQUIREMENTS=$(echo "$ISSUE" | jq -r '.body' | sed -n '/## Requirements/,/---/p' | grep '^\- \[ \]')

# Step 4: Update issue status to in-progress
mark_issue_in_progress "student-progress-widget"

# Step 5: Create spec with metadata from issue
# (Feature spec inherits area, role, requirements from GitHub Issue)
```

This ensures roadmap → feature workflow maintains metadata consistency.

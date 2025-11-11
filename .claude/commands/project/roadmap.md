---
description: Manage product roadmap (brainstorm, prioritize, track shipped features)
---

Manage the product roadmap via GitHub Issues: $ARGUMENTS

## MENTAL MODEL

**Workflow**: roadmap -> /feature -> clarify -> plan -> tasks -> implement -> optimize -> ship

**State machine:**
- Parse intent -> Execute GitHub API action -> Auto-label -> Return summary

**Auto-actions:**
- Add/update -> Auto-calculate ICE score and apply priority labels
- Large feature detected (>30 req OR effort >4) -> Suggest auto-split with scores
- Clarifications found -> Offer manual/recommend/skip (default: recommend)
- Brainstorm -> Generate ideas -> Offer to add as GitHub issues

## INITIALIZE

Check GitHub authentication and verify repository access:

**Bash (macOS/Linux):**
```bash
# Source GitHub roadmap manager
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Check authentication
AUTH_METHOD=$(check_github_auth)

if [ "$AUTH_METHOD" = "none" ]; then
  echo "❌ GitHub authentication required"
  echo ""
  echo "Choose one option:"
  echo "  A) GitHub CLI: gh auth login"
  echo "  B) API Token: export GITHUB_TOKEN=ghp_your_token"
  echo ""
  echo "See: docs/github-roadmap-migration.md"
  exit 1
fi

# Verify repository
REPO=$(get_repo_info)

if [ -z "$REPO" ]; then
  echo "❌ Could not determine repository"
  echo "Ensure you're in a git repository with a GitHub remote"
  exit 1
fi

echo "✅ GitHub authenticated ($AUTH_METHOD)"
echo "✅ Repository: $REPO"
```

**PowerShell (Windows):**
```powershell
# Import GitHub roadmap manager
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Check authentication
$authMethod = Test-GitHubAuth

if ($authMethod -eq "none") {
  Write-Host "❌ GitHub authentication required" -ForegroundColor Red
  Write-Host ""
  Write-Host "Choose one option:"
  Write-Host "  A) GitHub CLI: gh auth login"
  Write-Host "  B) API Token: `$env:GITHUB_TOKEN = 'ghp_your_token'"
  Write-Host ""
  Write-Host "See: docs/github-roadmap-migration.md"
  exit 1
}

# Verify repository
$repo = Get-RepositoryInfo

if ([string]::IsNullOrEmpty($repo)) {
  Write-Host "❌ Could not determine repository" -ForegroundColor Red
  Write-Host "Ensure you're in a git repository with a GitHub remote"
  exit 1
}

Write-Host "✅ GitHub authenticated ($authMethod)" -ForegroundColor Green
Write-Host "✅ Repository: $repo" -ForegroundColor Green
```

## PROJECT CONTEXT (Optional)

**Check for project documentation** (if `/init-project` was run):

```bash
PROJECT_OVERVIEW="docs/project/overview.md"
PROJECT_TECH_STACK="docs/project/tech-stack.md"
PROJECT_CAPACITY="docs/project/capacity-planning.md"
HAS_PROJECT_DOCS=false
HAS_TECH_STACK=false
HAS_CAPACITY=false

if [ -f "$PROJECT_OVERVIEW" ]; then
  HAS_PROJECT_DOCS=true
  echo "✅ Project documentation found"
  echo ""

  # Read project overview for validation
  # Claude Code: Read docs/project/overview.md
  # Extract:
  # - Vision (what problem we're solving)
  # - Out of scope (explicit exclusions)
  # - Target users (who we're building for)

  # Will use for:
  # 1. Vision alignment check when adding features
  # 2. Out-of-scope validation
  # 3. ICE scoring context
fi

if [ -f "$PROJECT_TECH_STACK" ]; then
  HAS_TECH_STACK=true
  echo "✅ Tech stack documentation found"
  echo ""

  # Read tech stack for brainstorming constraints
  # Claude Code: Read docs/project/tech-stack.md
  # Extract:
  # - Frontend tech (Next.js, React, etc.)
  # - Backend tech (FastAPI, Node.js, etc.)
  # - Database (PostgreSQL, MongoDB, etc.)
  # - Deployment platform (Vercel, Railway, AWS, etc.)
  # - Auth provider (Clerk, Auth0, custom, etc.)
  # - API style (REST, GraphQL, tRPC, gRPC)

  # Will use for:
  # 1. Brainstorm only features compatible with existing tech stack
  # 2. Flag features requiring new technology additions
  # 3. Leverage existing infrastructure (piggyback opportunities)
fi

if [ -f "$PROJECT_CAPACITY" ]; then
  HAS_CAPACITY=true
  echo "✅ Capacity planning documentation found"
  echo ""

  # Read capacity planning for effort estimation
  # Claude Code: Read docs/project/capacity-planning.md
  # Extract:
  # - Scale tier (micro/small/medium/large)
  # - Target users count (100/1k/10k/100k+)
  # - Cost constraints
  # - Performance targets

  # Will use for:
  # 1. Adjust effort estimates based on scale tier
  #    - micro: 1-2 (simple CRUD, minimal infra)
  #    - small: 2-3 (basic features, some optimization)
  #    - medium: 3-5 (complex features, scaling considerations)
  #    - large: 5-8 (distributed systems, high performance)
  # 2. Flag features exceeding cost/performance budgets
fi

if [ "$HAS_PROJECT_DOCS" = false ]; then
  echo "ℹ️  No project documentation found"
  echo "   Run /init-project to create project design docs"
  echo "   (Optional - roadmap works without it)"
  echo ""
fi
```

## CONTEXT

**Backend**: GitHub Issues with label-based state management

**Status Labels** (roadmap sections):
- `status:backlog` - Backlog (ideas, not prioritized)
- `status:later` - Later (planned for future)
- `status:next` - Next (queued for implementation)
- `status:in-progress` - In Progress (actively being worked on)
- `status:shipped` - Shipped (closed, deployed to production)

**Priority Labels** (auto-applied by ICE score):
- `priority:high` - ICE >= 1.5
- `priority:medium` - 0.8 <= ICE < 1.5
- `priority:low` - ICE < 0.8

**Type Labels:**
- `type:feature` - New feature or functionality
- `type:enhancement` - Enhancement to existing feature
- `type:bug` - Bug or defect
- `type:task` - Task or chore

**Area Labels:**
- `area:marketing`, `area:app`, `area:api`, `area:infra`, `area:design`

**Role Labels:**
- `role:free`, `role:student`, `role:cfi`, `role:school`, `role:all`

**Size Labels** (auto-applied by effort):
- `size:small` - Effort 1-2
- `size:medium` - Effort 3
- `size:large` - Effort 4
- `size:xl` - Effort 5

**Issue Frontmatter** (ICE scoring in YAML):
```yaml
---
ice:
  impact: 4
  effort: 2
  confidence: 0.9
  score: 1.8
metadata:
  area: app
  role: student
  slug: student-progress-widget
---

## Problem
Students struggle to track mastery...

## Proposed Solution
Add a progress widget...

## Requirements
- [ ] Display mastery percentage
- [ ] Group by ACS area
```

**Sorting**: GitHub Issues sorted by ICE score via priority labels + custom queries

## SCORING

**ICE Formula**: (Impact × Confidence) / Effort

**Defaults** (use when unclear):
- Impact: 3 (medium value)
- Effort: 3 (medium complexity)
- Confidence: 0.7 (medium certainty)

**Tie-breaker**: If scores match, preserve created date order

**Examples:**
- High-value quick win: Impact 4, Effort 2, Confidence 1.0 → Score 2.0
- Strategic bet: Impact 5, Effort 4, Confidence 0.8 → Score 1.0
- Small experiment: Impact 2, Effort 1, Confidence 0.6 → Score 1.2

## ACTIONS

### 1. ADD FEATURE

**Parse natural language:**
- Extract: title, area, role, requirements
- Infer: Impact (1-5), Effort (1-5), Confidence (0-1)
- Generate: URL-friendly slug (lowercase-with-hyphens, max 30 chars)
- Calculate: ICE score (use SCORING defaults if unclear)

**Deduplicate:**
- Check if slug exists in GitHub Issues via `get_issue_by_slug()`
- Check if `specs/[slug]/` directory exists
- If duplicate: Ask "Merge with existing issue #N?"

**Vision alignment validation** (if project docs exist):

```bash
if [ "$HAS_PROJECT_DOCS" = true ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 VISION ALIGNMENT CHECK"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Read project overview for validation
  # Claude Code: Read docs/project/overview.md
  # Extract:
  # - Vision statement (1 paragraph)
  # - Out of scope (explicit exclusions)
  # - Target users (primary personas)

  # Validate feature against project context:
  # 1. Does it align with vision?
  # 2. Is it explicitly out of scope?
  # 3. Does it serve target users?

  # If misaligned:
  echo "⚠️  Potential misalignment detected"
  echo ""
  echo "Project vision: [Vision from overview.md]"
  echo "This feature: $TITLE"
  echo ""
  echo "Concerns:"
  echo "  - [List specific misalignment issues]"
  echo ""
  echo "Options:"
  echo "  A) Add anyway (ignore alignment)"
  echo "  B) Revise feature to align"
  echo "  C) Skip (out of scope)"
  read -p "Choice (A/B/C): " alignment_choice

  case $alignment_choice in
    B|b)
      echo "Describe how to revise:"
      read -p "> " revision
      # Update TITLE and BODY with revised approach
      ;;
    C|c)
      echo "Feature rejected (out of scope per overview.md)"
      exit 0
      ;;
    A|a)
      echo "Proceeding anyway (alignment override)"
      # Add note to issue body
      BODY="$BODY

---

⚠️  **Alignment Note**: Flagged as potentially out of scope, but added per user request."
      ;;
  esac

  echo ""
fi
```

**Size validation with auto-split:**

**Trigger:** >30 requirements OR effort >4

**If triggered:**
1. Analyze requirements for natural boundaries:
   - **Phase split**: Look for "MVP", "core", "essential" vs "enhanced", "advanced"
   - **Layer split**: Look for "UI", "frontend" vs "API", "backend" vs "database", "schema"
   - **Tier split**: Look for "free", "anonymous" vs "authenticated", "paid", "premium"

2. Suggest specific split strategy with calculated scores:
```
⚠️  Large feature detected: [slug]
- Requirements: N components
- Effort: N weeks (recommended max: 4)

Suggested split (by [phase|layer|tier]):

A) [slug]-basic (I:N, E:2, C:0.9) → Score: N.NN
   - [MVP requirements extracted]

B) [slug]-enhanced (I:N, E:2, C:0.8) → Score: N.NN
   - [BLOCKED: [slug]-basic]
   - [Enhanced requirements extracted]

Create split features? (Y/n)
```

3. If "Y": Auto-create child issues
   - Add `[BLOCKED: parent-slug]` to dependent issue bodies
   - Recalculate ICE scores for each
   - Create with `status:backlog` label
   - Add `blocked` label to dependent issues

4. If "n": Add original feature as-is with warning
   - Add `size:xl` label
   - Add comment: "⚠️  Large feature - consider splitting before /feature"

**Create GitHub Issue:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | cut -c1-30)

# Format requirements as markdown body
BODY="## Problem

$PROBLEM_STATEMENT

## Proposed Solution

$SOLUTION_DESCRIPTION

## Requirements

$REQUIREMENTS_LIST"

# Create issue
create_roadmap_issue \
  "$TITLE" \
  "$BODY" \
  "$IMPACT" \
  "$EFFORT" \
  "$CONFIDENCE" \
  "$AREA" \
  "$ROLE" \
  "$SLUG" \
  "type:feature,status:backlog"
```

**PowerShell:**
```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Generate slug
$slug = $title.ToLower() -replace '[^a-z0-9-]', '-' -replace '--+', '-' |
        Select-Object -First 1 | ForEach-Object { $_.Substring(0, [Math]::Min(30, $_.Length)) }

# Format body
$body = @"
## Problem

$problemStatement

## Proposed Solution

$solutionDescription

## Requirements

$requirementsList
"@

# Create issue
New-RoadmapIssue `
  -Title $title `
  -Body $body `
  -Impact $impact `
  -Effort $effort `
  -Confidence $confidence `
  -Area $area `
  -Role $role `
  -Slug $slug `
  -Labels "type:feature,status:backlog"
```

**Auto-clarification (if `[CLARIFY]` found in requirements):**
Present 3 options:
```
🤔 Found N clarifications needed:
1. [First question]
2. [Second question]
...

Options:
A) Answer now (interactive)
B) Let Claude recommend (uses context)
C) Skip (clarify later)

Default: B
```

**If "A" (Manual)**: Interactive Q&A like `/clarify`
**If "B" (Recommend)** [DEFAULT]:
- Use CLAUDE.md, constitution, similar features from GitHub Issues
- Generate answers with rationale
- Update issue body with answers
- Remove `[CLARIFY]` tags

**If "C" (Skip)**: Continue to summary, add `needs-clarification` label

### 2. BRAINSTORM (research → plan → present)

**Trigger**: `/roadmap brainstorm [quick|deep] [area|role|topic]`

**Tiers:**
- `quick` (default): 2-3 searches, 5 ideas, ~30 seconds
- `deep`: 8-12 searches, 10 ideas, full industry research

---

**QUICK BRAINSTORM** (2-3 tool calls):

**Step 1 - Current Context:**
- Read `.spec-flow/memory/constitution.md` (mission)
- **If `HAS_TECH_STACK=true`:** Read `docs/project/tech-stack.md` for technical constraints
- **If `HAS_CAPACITY=true`:** Read `docs/project/capacity-planning.md` for scale tier
- **Fetch existing features from GitHub:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Get all roadmap features (any status)
EXISTING_FEATURES=$(gh issue list \
  --repo "$(get_repo_info)" \
  --label "type:feature" \
  --json number,title,body,labels \
  --limit 100)

# Parse slugs to avoid duplicates
EXISTING_SLUGS=$(echo "$EXISTING_FEATURES" | jq -r '.[].body' | grep -oP 'slug:\s*\K\S+' | sort -u)
```

**PowerShell:**
```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

$repo = Get-RepositoryInfo

# Get all roadmap features
$existingFeatures = gh issue list `
  --repo $repo `
  --label "type:feature" `
  --json number,title,body,labels `
  --limit 100 | ConvertFrom-Json

# Parse slugs
$existingSlugs = $existingFeatures |
  ForEach-Object { $_.body } |
  Select-String -Pattern 'slug:\s*(\S+)' |
  ForEach-Object { $_.Matches.Groups[1].Value } |
  Sort-Object -Unique
```

**Step 2 - Focused Research:**
- WebSearch: "[user-specified topic] features 2025" (if args provided)
- OR WebSearch: "aviation education platform [area]" (if area specified)

**Step 3 - Generate 5 Ideas:**
- **Extension** (piggyback existing): Build on current features
- **Gap-fill** (address missing): Solve unmet user needs
- **Quick Wins** (Impact 3-4, Effort 1-2): Ship in 1-2 weeks

**Technical Constraints** (if tech stack docs available):
- **ONLY suggest features compatible with documented tech stack**
- Flag any feature requiring new technology: `[NEW TECH: GraphQL]`
- Adjust effort estimates based on scale tier from capacity-planning.md:
  - micro tier: Effort 1-2 (simple CRUD, minimal infrastructure)
  - small tier: Effort 2-3 (basic features, some optimization)
  - medium tier: Effort 3-5 (complex features, scaling needed)
  - large tier: Effort 5-8 (distributed systems, high performance)
- Prefer features leveraging existing infrastructure (lower effort)

**Present** (simplified selection):
```
💡 Brainstormed Ideas (sorted by score):

1. student-progress-widget (Score: 1.5) [PIGGYBACK: aktr-results-core]
   Impact: 3 | Effort: 2 | Confidence: 1.0
   "Show mastery % on results page. Uses existing ACS data."

2. cfi-batch-csv-export (Score: 1.4) [PIGGYBACK: csv-export]
   Impact: 4 | Effort: 3 | Confidence: 0.9
   "Export all students in cohort. Reuses export modal."

...

Which to add? (1,2,3, all, skip)
```

---

**DEEP BRAINSTORM** (8-12 tool calls):

**Phase 1: RESEARCH**

**Step 1 - Current Context:**
- Read `.spec-flow/memory/constitution.md` (mission)
- **If `HAS_TECH_STACK=true`:** Read `docs/project/tech-stack.md` for technical constraints
- **If `HAS_CAPACITY=true`:** Read `docs/project/capacity-planning.md` for scale tier
- Fetch existing features from GitHub Issues (same as quick brainstorm)
- Glob `specs/*/spec.md` (patterns, user flows, reusable infra)

**Step 2 - Industry Research:**
- WebSearch: "aviation education platform features 2025"
- WebSearch: "flight instructor tools student tracking"
- WebSearch: "edtech personalization study plans"
- WebSearch: "[user-specified topic]" (if args provided)

**Step 3 - Gap Analysis:**
- Compare current features vs industry leaders
- Identify role gaps: free, student, CFI, school
- Find piggybacking opportunities (leverage existing features)

**Phase 2: PLAN**

**Step 1 - Generate 10 Ideas:**
- **Extension** (piggyback existing): Build on current features
- **Gap-fill** (address missing): Solve unmet user needs
- **Innovation** (differentiation): New value propositions

**Technical Constraints** (if tech stack docs available):
- **ONLY suggest features compatible with documented tech stack**
- Flag any feature requiring new technology: `[NEW TECH: GraphQL]`
- Adjust effort estimates based on scale tier from capacity-planning.md:
  - micro tier: Effort 1-2 (simple CRUD, minimal infrastructure)
  - small tier: Effort 2-3 (basic features, some optimization)
  - medium tier: Effort 3-5 (complex features, scaling needed)
  - large tier: Effort 5-8 (distributed systems, high performance)
- Prefer features leveraging existing infrastructure (lower effort)
- Consider cost constraints from capacity planning when estimating feasibility

**Step 2 - Group by Strategy:**
- **Quick Wins** (Impact 3-4, Effort 1-2): Ship in 1-2 weeks
- **Strategic** (Impact 4-5, Effort 3-4): Long-term competitive advantage
- **Experimental** (Impact 2-3, Effort 1-2): Test hypotheses

**Step 3 - Identify Dependencies:**
- Tag piggybacking: `[PIGGYBACK: feature-slug]`
- Tag blockers: `[BLOCKED: missing-infra]`

**Phase 3: PRESENT**

```
🔬 Research Summary:
- Analyzed: N existing features, M industry trends
- Found: X gaps, Y piggybacking opportunities

💡 Brainstormed Ideas (sorted by category):

**Quick Wins** (ship in 1-2 weeks):
1. student-progress-widget (Score: 1.5) [PIGGYBACK: aktr-results-core]
   Impact: 3 | Effort: 2 | Confidence: 1.0
   "Show mastery % on results page. Uses existing ACS data."
   Source: WebSearch - "edtech student dashboards 2025"

**Strategic** (competitive advantage):
2. ai-study-plan-generator (Score: 1.2)
   Impact: 5 | Effort: 4 | Confidence: 0.8
   "GPT-4 generates personalized plans from ACS gaps. Foreflight lacks this."
   Source: WebSearch - "AI study plan generation edtech"

**Experimental** (test & learn):
3. social-study-groups (Score: 0.8)
   Impact: 3 | Effort: 4 | Confidence: 0.6
   "Students form study groups. Hypothesis: social = retention."
   Source: Industry trend - Duolingo social features

Which to add? (1,2,3, all, skip)
```

---

**Selection** (both tiers):
- `1,2,3...` - Add specific ideas by number (creates GitHub issues)
- `all` - Add everything
- `skip` - Cancel

**If selected**:
- Create GitHub issues with full metadata using `create_roadmap_issue()`
- Preserve `[PIGGYBACK]` and `[BLOCKED]` tags in issue bodies
- Apply `status:backlog` label
- Show updated roadmap summary with issue numbers

### 3. MOVE FEATURE

**Parse**: "move [slug] to [section]"

**Valid moves:**
- Backlog → Later → Next → In Progress → Shipped
- Downgrade: Next → Later → Backlog (if deprioritized)

**Execute:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Get issue by slug
ISSUE=$(get_issue_by_slug "$SLUG")

if [ -z "$ISSUE" ] || [ "$ISSUE" = "null" ]; then
  echo "❌ Issue with slug '$SLUG' not found"
  exit 1
fi

ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')

# Map section to status label
case "$TARGET_SECTION" in
  "backlog")     NEW_STATUS="status:backlog" ;;
  "later")       NEW_STATUS="status:later" ;;
  "next")        NEW_STATUS="status:next" ;;
  "in progress") NEW_STATUS="status:in-progress" ;;
  "shipped")     echo "Use '/roadmap ship $SLUG' instead"; exit 1 ;;
  *)             echo "Invalid section: $TARGET_SECTION"; exit 1 ;;
esac

# Update labels
gh issue edit "$ISSUE_NUMBER" \
  --repo "$(get_repo_info)" \
  --remove-label "status:backlog,status:later,status:next,status:in-progress" \
  --add-label "$NEW_STATUS"

echo "✅ Moved issue #$ISSUE_NUMBER to $TARGET_SECTION"
```

**PowerShell:**
```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

$issue = Get-IssueBySlug -Slug $slug

if (-not $issue) {
  Write-Host "❌ Issue with slug '$slug' not found" -ForegroundColor Red
  exit 1
}

$issueNumber = $issue.number
$repo = Get-RepositoryInfo

# Map section to label
$newStatus = switch ($targetSection.ToLower()) {
  "backlog"     { "status:backlog" }
  "later"       { "status:later" }
  "next"        { "status:next" }
  "in progress" { "status:in-progress" }
  "shipped"     { Write-Host "Use '/roadmap ship $slug' instead"; exit 1 }
  default       { Write-Host "Invalid section: $targetSection"; exit 1 }
}

# Update labels
gh issue edit $issueNumber `
  --repo $repo `
  --remove-label "status:backlog,status:later,status:next,status:in-progress" `
  --add-label $newStatus

Write-Host "✅ Moved issue #$issueNumber to $targetSection" -ForegroundColor Green
```

### 4. DELETE FEATURE

**Parse**: "delete [slug]" or "remove [slug]"

**Confirm:**
```
⚠️  Delete [slug] from roadmap?

This will close the GitHub issue with 'wont-fix' label:
- Issue: #123
- Title: [title]
- Status: [current status]
- Requirements: [count] items

Note: If specs/[slug]/ exists, it will NOT be deleted.

Confirm? (yes/no)
```

**Execute:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

ISSUE=$(get_issue_by_slug "$SLUG")

if [ -z "$ISSUE" ] || [ "$ISSUE" = "null" ]; then
  echo "❌ Issue with slug '$SLUG' not found"
  exit 1
fi

ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')

# Close with wont-fix label
gh issue close "$ISSUE_NUMBER" \
  --repo "$(get_repo_info)" \
  --reason "not planned" \
  --comment "Removed from roadmap (not planned for implementation)"

gh issue edit "$ISSUE_NUMBER" \
  --repo "$(get_repo_info)" \
  --add-label "wont-fix"

echo "✅ Closed issue #$ISSUE_NUMBER (wont-fix)"
```

**PowerShell:**
```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

$issue = Get-IssueBySlug -Slug $slug

if (-not $issue) {
  Write-Host "❌ Issue with slug '$slug' not found" -ForegroundColor Red
  exit 1
}

$issueNumber = $issue.number
$repo = Get-RepositoryInfo

# Close with wont-fix
gh issue close $issueNumber `
  --repo $repo `
  --reason "not planned" `
  --comment "Removed from roadmap (not planned for implementation)"

gh issue edit $issueNumber `
  --repo $repo `
  --add-label "wont-fix"

Write-Host "✅ Closed issue #$issueNumber (wont-fix)" -ForegroundColor Green
```

### 5. PRIORITIZE

**Parse**: "prioritize [section]" or "sort [section]"

**Execute:**

Show sorted list of issues in the specified section, ordered by ICE score (via priority labels):

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Map section to status label
case "$SECTION" in
  "backlog") STATUS="backlog" ;;
  "later")   STATUS="later" ;;
  "next")    STATUS="next" ;;
  *)         echo "Invalid section: $SECTION"; exit 1 ;;
esac

# Get issues sorted by priority (high → medium → low)
echo "📊 $SECTION (sorted by ICE score):"
echo ""

# High priority
gh issue list --repo "$(get_repo_info)" \
  --label "status:$STATUS,priority:high" \
  --json number,title,body \
  --limit 50 | jq -r '.[] | "  \(.number). \(.title) (HIGH)"'

# Medium priority
gh issue list --repo "$(get_repo_info)" \
  --label "status:$STATUS,priority:medium" \
  --json number,title,body \
  --limit 50 | jq -r '.[] | "  \(.number). \(.title) (MEDIUM)"'

# Low priority
gh issue list --repo "$(get_repo_info)" \
  --label "status:$STATUS,priority:low" \
  --json number,title,body \
  --limit 50 | jq -r '.[] | "  \(.number). \(.title) (LOW)"'
```

### 6. /feature HANDOFF

**Parse**: "/feature [slug]" or "create spec for [slug]"

**Execute:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Get issue by slug
ISSUE=$(get_issue_by_slug "$SLUG")

if [ -z "$ISSUE" ] || [ "$ISSUE" = "null" ]; then
  echo "❌ Issue with slug '$SLUG' not found in roadmap"
  echo "   Create it first with: /roadmap add \"[description]\""
  exit 1
fi

ISSUE_NUMBER=$(echo "$ISSUE" | jq -r '.number')

# Check for clarifications
BODY=$(echo "$ISSUE" | jq -r '.body')
CLARIFY_COUNT=$(echo "$BODY" | grep -c '\[CLARIFY:' || true)

if [ "$CLARIFY_COUNT" -gt 0 ]; then
  echo "⚠️  Found $CLARIFY_COUNT clarifications needed"
  echo "   Suggested: /roadmap clarify $SLUG"
  echo ""
  read -p "Continue to /feature anyway? (y/N): " RESPONSE
  if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

# Show handoff message
echo "✅ Found roadmap issue: #$ISSUE_NUMBER"
echo ""
echo "Run: /feature $SLUG"
echo ""
echo "/feature will:"
echo "  1. Create specs/$SLUG/ directory"
echo "  2. Extract requirements from issue #$ISSUE_NUMBER"
echo "  3. Generate spec.md"
echo "  4. Mark issue as 'status:in-progress'"
echo "  5. Link issue to workflow-state.yaml"
```

### 7. SHIP FEATURE

**Parse**: "ship [slug]" or "shipped [slug] [version]"

**Execute:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

# Get version and URL from user or workflow-state.yaml
VERSION="${VERSION:-1.0.0}"
DATE=$(date +%Y-%m-%d)
PROD_URL="${PROD_URL:-}"

# Mark as shipped
mark_issue_shipped "$SLUG" "$VERSION" "$DATE" "$PROD_URL"

# Output: ✅ Marked issue #123 as Shipped (v1.0.0) in roadmap
```

**PowerShell:**
```powershell
. .\.spec-flow\scripts\powershell\github-roadmap-manager.ps1

# Get version and URL
$version = if ($version) { $version } else { "1.0.0" }
$date = Get-Date -Format "yyyy-MM-dd"
$prodUrl = if ($prodUrl) { $prodUrl } else { "" }

# Mark as shipped
Set-IssueShipped -Slug $slug -Version $version -Date $date -ProductionUrl $prodUrl

# Output: ✅ Marked issue #123 as Shipped (v1.0.0) in roadmap
```

**Note**: This action:
- Adds `status:shipped` label
- Removes all other status labels
- Closes the issue with "completed" reason
- Adds comment with version, date, and production URL

### 8. SEARCH

**Parse**: Keywords, area filter, role filter

**Execute:**

**Bash:**
```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

REPO=$(get_repo_info)

# Build search query
QUERY="repo:$REPO type:feature $KEYWORDS"

# Add filters if provided
[ -n "$AREA" ] && QUERY="$QUERY label:area:$AREA"
[ -n "$ROLE" ] && QUERY="$QUERY label:role:$ROLE"

# Search
RESULTS=$(gh issue list \
  --repo "$REPO" \
  --search "$QUERY" \
  --json number,title,labels,state \
  --limit 50)

# Display results
echo "🔍 Search Results:"
echo ""
echo "$RESULTS" | jq -r '.[] | "  #\(.number) - \(.title) [\(.state)]"'
echo ""

# Count by status
echo "📊 By Status:"
echo "$RESULTS" | jq -r '
  group_by(.labels[] | select(.name | startswith("status:")) | .name) |
  map({status: .[0].labels[] | select(.name | startswith("status:")) | .name, count: length}) |
  .[] | "  \(.status): \(.count)"
'
```

## AUTO-SORT LOGIC

**GitHub Issues Sorting Model:**

Unlike the old markdown roadmap, GitHub Issues don't have explicit "sort order" within sections. Instead, sorting happens dynamically via queries:

**Priority-based Sorting:**
- Issues auto-labeled with `priority:high|medium|low` based on ICE score
- Queries fetch issues in priority order: high → medium → low
- Within same priority: Sort by created date (oldest first) or ICE score

**ICE Score Calculation:**
- Calculated when issue is created via `create_roadmap_issue()`
- Stored in YAML frontmatter in issue body
- Priority labels auto-applied based on score thresholds

**Re-prioritization:**
- Update ICE scores → Use `update_issue_ice()` from github-roadmap-manager
- Script recalculates score and updates priority labels
- Next query will reflect new priority

**Example Query** (high priority backlog items):
```bash
gh issue list \
  --repo "owner/repo" \
  --label "status:backlog,priority:high" \
  --json number,title,body \
  --limit 10
```

**Manual Sorting:**
- GitHub Projects can provide drag-and-drop manual ordering
- Use custom "Priority" field in Projects for manual overrides
- Roadmap command shows ICE-based priority by default

**Implementation Note:**
- No need to "rewrite" files like markdown roadmap
- Label updates are instant and automatically reflected in queries
- Use GitHub Projects for visual roadmap with custom ordering

## RETURN

**Concise summary:**

**After ADD:**
```
✅ Created issue #123: [slug] in Backlog
   Impact: N | Effort: N | Confidence: N.N | Score: N.NN
   Priority: high | Area: app | Role: student

📊 Roadmap Summary:
   Backlog: 12 | Next: 3 | In Progress: 2 | Shipped: 45

Top 3 in Backlog (by priority):
1. #123 [slug] (Score: 1.8) - [title]
2. #98 other-slug (Score: 1.5) - [title]
3. #87 another-slug (Score: 1.2) - [title]

💡 Next: /feature [slug]
```

**After BRAINSTORM:**
```
✅ Created N GitHub issues from brainstormed ideas

📊 Roadmap Summary:
   Backlog: 15 (+N) | Next: 3 | In Progress: 2

New Issues:
- #124 student-progress-widget (Score: 1.5)
- #125 cfi-batch-export (Score: 1.4)
- #126 study-plan-generator (Score: 1.2)

💡 Next: /feature [highest-priority-slug]
```

**After MOVE:**
```
✅ Moved issue #123 from Backlog to Next

📊 Roadmap Summary:
   Backlog: 11 | Next: 4 (+1) | In Progress: 2

Next Queue:
1. #123 [slug] (Score: 1.8) - [title]
2. #98 other-slug (Score: 1.5) - [title]
3. #87 another-slug (Score: 1.2) - [title]
4. #76 final-slug (Score: 1.0) - [title]

💡 Next: /feature [slug]
```

**After DELETE:**
```
✅ Closed issue #123 (wont-fix)

📊 Roadmap Summary:
   Backlog: 11 (-1) | Next: 3 | In Progress: 2

Note: specs/[slug]/ directory preserved (if exists)
```

**After SHIP:**
```
✅ Shipped issue #123: [slug] (v1.2.0)
   Date: 2025-10-20
   Production: https://app.example.com

📊 Roadmap Summary:
   Backlog: 11 | Next: 3 | In Progress: 1 (-1) | Shipped: 46 (+1)

Recent Shipments:
1. #123 [slug] - v1.2.0 (2025-10-20)
2. #120 other-feature - v1.1.9 (2025-10-18)
3. #118 another-feature - v1.1.8 (2025-10-15)
```

**After SEARCH:**
```
🔍 Search Results for "$KEYWORDS":

Found N issues:
- #123 student-progress-widget [OPEN]
- #98 progress-tracking [CLOSED]
- #87 mastery-dashboard [OPEN]

📊 By Status:
   status:backlog: 2
   status:shipped: 1

💡 Open issue: gh issue view 123
```

# Project Integration

## Integration with Project Documentation

### Project Docs Consulted

#### 1. `docs/project/overview.md` (CRITICAL)

**Sections read:**

- **Vision** (## Vision) - 1 paragraph describing project purpose
- **Out of Scope** (### Out of Scope) - Bullet list of explicit exclusions
- **Target Users** (## Target Users) - Bullet list of intended users

**Usage:**

- Vision alignment validation (Step 4)
- Out-of-scope detection
- Target user role extraction

**Example:**

```markdown
## Vision

AKTR helps flight instructors track student progress against ACS standards,
enabling data-driven instruction and transparent competency demonstration.

### Out of Scope

- Flight scheduling or aircraft management
- Payment processing or student billing
- General aviation weather briefings

## Target Users

- Certified Flight Instructors (CFIs)
- Flight students (private, instrument, commercial)
- Flight school administrators
```

---

## When Project Docs Don't Exist

### Behavior Without overview.md

```bash
if [ ! -f "docs/project/overview.md" ]; then
  echo "ℹ️  No project documentation found"
  echo "   Run /init-project to create project design docs"
  echo "   (Optional - roadmap works without it)"
  echo ""

  # Skip vision validation
  HAS_PROJECT_DOCS=false

  # Proceed with issue creation (no alignment check)
  create_roadmap_issue "$TITLE" "$BODY" "$AREA" "$ROLE" "$SLUG" "type:feature,status:backlog"

  # Add informational note to issue
  echo ""
  echo "ℹ️  Note: Run /init-project for vision-aligned roadmap management"
fi
```

**Impact:**

- Vision alignment validation skipped
- All features added without alignment check
- No out-of-scope detection
- Manual role selection (not validated against target users)

**Recommendation:**

- Run `/init-project` to create project docs before scaling roadmap
- For small projects (<10 features), docs optional
- For medium/large projects (>10 features), docs strongly recommended

---

## When Project Docs Are Outdated

### Detecting Outdated Docs

**Symptoms:**

- Features frequently flagged as out-of-scope
- Vision statements don't match current direction
- Target users list incomplete

**Solutions:**

1. **Update overview.md when scope changes:**

```bash
# Edit docs/project/overview.md
# - Update Vision section
# - Add/remove Out-of-Scope items
# - Update Target Users list

# Then retry feature add
/roadmap add "feature name"
```

2. **Version project docs:**

```markdown
<!-- docs/project/overview.md -->

<!-- Version: 2.0 (Updated: 2025-11-01) -->
<!-- Changes: Added enterprise users, removed scheduling exclusion -->
```

3. **Periodic review:**

- Review overview.md quarterly
- Update after major pivots or scope expansions
- Sync with product strategy changes

---

## Integration with Workflow Commands

### /init-project → /roadmap

**Flow:**

```
/init-project
    ↓
Creates: docs/project/overview.md (with Vision, Scope, Users)
    ↓
/roadmap add "feature"
    ↓
Reads: overview.md for vision validation
    ↓
Validates: Feature against vision/scope/users
    ↓
Creates: GitHub Issue with metadata
```

**Example:**

```bash
# Initialize project
/init-project

# (Interactive questionnaire creates overview.md)

# Add feature with vision validation
/roadmap add "student progress widget"

# Vision check uses overview.md:
# - Vision: "AKTR helps instructors track student progress..."
# - Out-of-Scope: Check if widget is excluded
# - Target Users: Validate serves CFIs or students
```

---

### /roadmap → /feature

**Flow:**

```
/roadmap add "student progress widget"
    ↓
Creates: GitHub Issue #123 with metadata
    ↓
/feature student-progress-widget
    ↓
Reads: GitHub Issue #123 body (area, role, requirements)
    ↓
Creates: specs/001-student-progress-widget/spec.md
    ↓
Updates: Issue label (status:backlog → status:in-progress)
```

**Metadata inheritance:**

```bash
# Roadmap creates issue with metadata
create_roadmap_issue \
  "Student progress widget" \
  "$BODY" \
  "frontend" \
  "student" \
  "student-progress-widget" \
  "type:feature,status:backlog"

# /feature reads metadata from issue
ISSUE=$(get_issue_by_slug "student-progress-widget")
AREA=$(extract_area_from_issue "$ISSUE")  # "frontend"
ROLE=$(extract_role_from_issue "$ISSUE")  # "student"
REQUIREMENTS=$(extract_requirements_from_issue "$ISSUE")

# Spec inherits metadata
cat > specs/001-student-progress-widget/spec.md <<EOF
---
metadata:
  area: $AREA
  role: $ROLE
  slug: $SLUG
---

$REQUIREMENTS
EOF
```

---

### /feature → /ship-prod → /roadmap

**Flow:**

```
/feature student-progress-widget
    ↓
Creates: spec, plan, tasks
Updates: Issue label (status:backlog → status:in-progress)
    ↓
/implement
    ↓
Implements tasks
    ↓
/ship-prod
    ↓
Deploys to production
Marks: Issue as shipped
    ↓
/roadmap summary
    ↓
Shows: Issue #123 moved to Shipped (closed with status:shipped label)
```

**Issue state transitions:**

```bash
# Step 1: Feature added
/roadmap add "widget"
# Issue #123: status:backlog

# Step 2: Spec created
/feature widget
mark_issue_in_progress "widget"
# Issue #123: status:in-progress

# Step 3: Deployed
/ship-prod
mark_issue_shipped "widget"
# Issue #123: status:shipped (closed)

# Step 4: Roadmap summary
/roadmap summary
# Shipped: 1 (Issue #123)
```

---

## State Synchronization

### GitHub Issue ↔ Workflow State

**Problem:** GitHub Issues and state.yaml can diverge

**Solution:** Hook workflow commands to update issue labels

#### Hook Points

1. **/feature invocation:**

```bash
# In /feature command
SLUG="$1"
mark_issue_in_progress "$SLUG"
# Updates: status:backlog → status:in-progress
```

2. **/ship-staging completion:**

```bash
# In /ship-staging command (after successful deploy)
mark_issue_next "$SLUG")  # Optional: staged for production
```

3. **/ship-prod completion:**

```bash
# In /ship-prod command (after successful deploy)
mark_issue_shipped "$SLUG"
# Updates: status:in-progress → status:shipped
# Closes issue
```

#### State Sync Functions

```bash
# Update issue to in-progress
mark_issue_in_progress() {
  SLUG="$1"
  ISSUE_NUMBER=$(get_issue_by_slug "$SLUG" | jq -r '.number')

  gh issue edit "$ISSUE_NUMBER" \
    --remove-label "status:backlog" \
    --remove-label "status:next" \
    --add-label "status:in-progress"

  echo "✅ Issue #$ISSUE_NUMBER marked as in-progress"
}

# Mark issue as shipped
mark_issue_shipped() {
  SLUG="$1"
  ISSUE_NUMBER=$(get_issue_by_slug "$SLUG" | jq -r '.number')

  gh issue close "$ISSUE_NUMBER" \
    --reason completed \
    --comment "✅ Shipped to production"

  gh issue edit "$ISSUE_NUMBER" \
    --remove-label "status:in-progress" \
    --add-label "status:shipped"

  echo "✅ Issue #$ISSUE_NUMBER shipped and closed"
}
```

---

## Roadmap Summary Integration

### Fetching Roadmap State

```bash
source .spec-flow/scripts/bash/github-roadmap-manager.sh

REPO=$(get_repo_info)

# Count by status
BACKLOG_COUNT=$(gh issue list --repo "$REPO" --label "status:backlog" --json number --jq 'length')
NEXT_COUNT=$(gh issue list --repo "$REPO" --label "status:next" --json number --jq 'length')
IN_PROGRESS_COUNT=$(gh issue list --repo "$REPO" --label "status:in-progress" --json number --jq 'length')
SHIPPED_COUNT=$(gh issue list --repo "$REPO" --label "status:shipped" --state closed --json number --jq 'length')

echo "📊 Roadmap Summary:"
echo "   Backlog: $BACKLOG_COUNT | Next: $NEXT_COUNT | In Progress: $IN_PROGRESS_COUNT | Shipped: $SHIPPED_COUNT"
```

### Displaying Top 3 Backlog Items

```bash
# Show oldest 3 items (creation-order prioritization)
echo "Top 3 in Backlog (oldest/highest priority):"
gh issue list --repo "$REPO" --label "status:backlog" --json number,title,createdAt --limit 3 | \
  jq -r '.[] | "\(.number). \(.title) (Created: \(.createdAt | split("T")[0]))"'
```

**Output:**

```
Top 3 in Backlog (oldest/highest priority):
1. #98 cfi-batch-export (Created: 2025-11-01)
2. #87 study-plan-generator (Created: 2025-11-05)
3. #123 student-progress-widget (Created: 2025-11-13)
```

### Suggesting Next Action

```bash
# Get oldest backlog item slug
NEXT_SLUG=$(gh issue list --repo "$REPO" --label "status:backlog" --json number,body --limit 1 | \
  jq -r '.[0].body' | grep 'slug:' | awk '{print $2}')

if [ -n "$NEXT_SLUG" ]; then
  echo ""
  echo "💡 Next: /feature $NEXT_SLUG"
else
  echo ""
  echo "✅ Backlog empty! All features in progress or shipped."
fi
```

---

## Migration Considerations

### From Legacy Roadmap Format

**If you have existing roadmap.md or features.md:**

1. **Extract features:**

```bash
# Read legacy roadmap
grep -E '^##' roadmap.md | sed 's/^## //' > features.txt

# Create GitHub Issues
while IFS= read -r feature; do
  /roadmap add "$feature"
done < features.txt
```

2. **Preserve priority:**

- Add features in priority order (oldest first)
- Creation order determines priority

3. **Add metadata manually:**

- Edit each GitHub Issue
- Add YAML frontmatter with area, role, slug

---

## Performance Expectations

### Token Budget by Integration

**With /init-project integration:**

```
/init-project (first time): ~40-60K tokens
  ↓
overview.md created (~5-8K tokens when read)
  ↓
/roadmap add (with vision check): ~8-12K tokens per feature
```

**Without /init-project:**

```
/roadmap add (no vision check): ~2-3K tokens per feature
```

**Recommendation:**

- Run /init-project once upfront (~40-60K tokens)
- Saves 5-10K tokens per feature added (vision validation)
- Break-even at ~6-10 features

---

## Troubleshooting Integration Issues

### Issue: Vision validation always failing

**Cause:** overview.md Vision section poorly defined

**Solution:**

```bash
# Improve Vision statement clarity
# Bad: "Make a great product"
# Good: "AKTR helps flight instructors track student progress against ACS standards"
```

### Issue: Features not appearing in /feature command

**Cause:** Slug mismatch between GitHub Issue and /feature argument

**Solution:**

```bash
# Check slug in GitHub Issue metadata
gh issue view 123 --json body --jq '.body' | grep 'slug:'

# Use exact slug
/feature student-progress-widget  # Not "student progress widget"
```

### Issue: Roadmap summary counts wrong

**Cause:** GitHub Issue labels not updated when feature progresses

**Solution:**

```bash
# Add hooks to workflow commands
# In .claude/commands/feature.md:
mark_issue_in_progress "$SLUG"

# In .claude/commands/ship-prod.md:
mark_issue_shipped "$SLUG"
```

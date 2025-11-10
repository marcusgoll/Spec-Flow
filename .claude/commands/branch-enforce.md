# /branch.enforce - Branch Age Enforcement

**Purpose**: Audit all branches for age violations and enforce trunk-based development practices (24h max branch lifetime).

**Usage**:
```bash
/branch.enforce [--fix] [--verbose]
```

**Parameters**:
- `--fix`: Auto-create feature flags for branches >24h old (prevents blocking)
- `--verbose`: Show detailed branch information

**Prerequisites**:
- Git repository
- Feature flag registry (`.spec-flow/memory/feature-flags.yaml`)

**Outputs**:
- Branch health report
- Age violations
- Recommendations

---

## What This Enforces

**Trunk-Based Development Rule**: Max 24h branch lifetime

**Thresholds**:
- **<18h**: ✅ Green (healthy)
- **18-24h**: ⚠️ Yellow (warning - merge soon)
- **>24h**: ❌ Red (violation - blocks push)

**Exception**: Branches with feature flags can exceed 24h

**References**:
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [DORA Research](https://dora.dev/research/) - Small batch size improves flow

---

## Workflow Steps

### 1. Discover All Branches

List all local and remote branches:

```bash
git branch -a | grep -v HEAD
```

**Exclude**:
- `main` / `master` (protected branches)
- Remote tracking branches (remotes/origin/*)

### 2. Calculate Branch Ages

For each branch, find first commit timestamp:

```bash
# Get first commit on branch (not on main)
git log --reverse --format=%ct $BRANCH --not main | head -1

# Calculate age in hours
NOW=$(date +%s)
AGE_HOURS=$(( (NOW - FIRST_COMMIT_TIME) / 3600 ))
```

### 3. Classify Branches

**Healthy** (<18h):
- No action needed
- Continue development

**Warning** (18-24h):
- Alert owner
- Recommend merge or feature flag

**Violation** (>24h):
- Check for feature flag
- If no flag: recommend immediate action
- If flag exists: allow (but track flag debt)

### 4. Generate Report

**Summary**:
```
Branch Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Healthy: 5 branches (<18h)
⚠️  Warning: 2 branches (18-24h)
❌ Violation: 1 branch (>24h)

Total: 8 active branches
```

**Details per branch**:
```
feature/user-auth
  Age: 12h
  Status: ✅ Healthy
  Last commit: 2025-11-10 08:00

feature/dashboard-ui
  Age: 20h
  Status: ⚠️  Warning (merge within 4h)
  Last commit: 2025-11-09 18:00
  Recommendation: Merge or add feature flag

feature/complex-refactor
  Age: 36h
  Status: ❌ Violation (12h over limit)
  Last commit: 2025-11-09 02:00
  Feature flag: refactor_complex_enabled ✅
  Recommendation: Complete work and remove flag
```

### 5. Recommendations

**For warnings** (18-24h):
```
Options:
  1. Merge now (recommended)
  2. Add feature flag: /flag.add <name>
  3. Split into smaller slice
```

**For violations** (>24h):
```
Required Action:
  1. Add feature flag immediately:
     /flag.add refactor_complex --reason "Large refactor in progress"

  2. Or split work:
     - Commit shippable piece
     - Merge to main
     - Create new branch for remainder
```

### 6. Auto-Fix Mode

With `--fix` flag, automatically create feature flags for violations:

```bash
/branch.enforce --fix

# Behavior:
# - Detects branches >24h old without flags
# - Creates feature flag for each
# - Updates feature-flags.yaml
# - Outputs flag names for developer to implement
```

**Example auto-fix**:

```
❌ Violation: feature/complex-refactor (36h old)

Auto-fix: Creating feature flag...
✅ Flag created: refactor_complex_enabled

Next steps:
  1. Wrap incomplete code with flag:
     if (featureFlags.refactor_complex_enabled) { ... }

  2. Merge to main (push no longer blocked)

  3. Complete work in new commits

  4. Remove flag when done: /flag.cleanup refactor_complex_enabled
```

---

## Implementation Details

### Script Location

**Bash**: `.spec-flow/scripts/bash/branch-enforce.sh`

### Functions Required

```bash
# Get all non-main branches
get_all_branches() {
  git branch --format='%(refname:short)' | grep -v '^main$' | grep -v '^master$'
}

# Get branch age in hours
get_branch_age() {
  local branch=$1

  # First commit on branch (not on main)
  local first_commit
  first_commit=$(git log --reverse --format=%ct "$branch" --not main 2>/dev/null | head -1)

  if [[ -z "$first_commit" ]]; then
    echo "0"
    return
  fi

  local now=$(date +%s)
  local age_hours=$(( (now - first_commit) / 3600 ))
  echo "$age_hours"
}

# Check if branch has feature flag
has_feature_flag() {
  local branch=$1
  local registry=".spec-flow/memory/feature-flags.yaml"

  if [[ ! -f "$registry" ]]; then
    return 1
  fi

  grep -q "branch: $branch" "$registry"
}

# Classify branch health
classify_branch() {
  local age=$1
  local has_flag=$2

  if [[ $age -lt 18 ]]; then
    echo "healthy"
  elif [[ $age -lt 24 ]]; then
    echo "warning"
  else
    if [[ "$has_flag" == "true" ]]; then
      echo "violation_flagged"
    else
      echo "violation"
    fi
  fi
}

# Auto-create feature flag
create_flag_for_branch() {
  local branch=$1

  # Generate flag name from branch
  local flag_name=$(echo "$branch" | sed 's/feature\///' | sed 's/[^a-zA-Z0-9]/_/g')
  flag_name="${flag_name}_enabled"

  # Call /flag.add
  .spec-flow/scripts/bash/flag-add.sh "$flag_name" \
    --branch "$branch" \
    --reason "Auto-generated: Branch age >24h"

  echo "$flag_name"
}

# Format branch report
format_branch_report() {
  local branch=$1
  local age=$2
  local status=$3
  local has_flag=$4

  echo "$branch"
  echo "  Age: ${age}h"

  case "$status" in
    healthy)
      echo "  Status: ✅ Healthy"
      ;;
    warning)
      local remaining=$((24 - age))
      echo "  Status: ⚠️  Warning (merge within ${remaining}h)"
      echo "  Recommendation: Merge or add feature flag"
      ;;
    violation)
      local overtime=$((age - 24))
      echo "  Status: ❌ Violation (${overtime}h over limit)"
      echo "  Recommendation: Add feature flag immediately"
      ;;
    violation_flagged)
      local overtime=$((age - 24))
      echo "  Status: ❌ Violation (${overtime}h over limit)"
      if [[ "$has_flag" == "true" ]]; then
        echo "  Feature flag: ✅ Exists (push allowed)"
        echo "  Recommendation: Complete work and remove flag"
      fi
      ;;
  esac

  echo ""
}
```

---

## Examples

### Example 1: Standard Audit

```bash
/branch.enforce

# Output:
Branch Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Healthy: 5 branches
⚠️  Warning: 2 branches
❌ Violation: 1 branch

Healthy branches:
  - feature/user-auth (12h)
  - feature/api-v2 (6h)
  - feature/tests (3h)
  - feature/docs (8h)
  - feature/bugfix (14h)

Warning branches:
  - feature/dashboard-ui (20h) → Merge within 4h
  - feature/notifications (22h) → Merge within 2h

Violation branches:
  - feature/complex-refactor (36h) → 12h over limit
    Action required: /flag.add refactor_complex

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommendations:
  - Merge warning branches today
  - Add flag for violation branch
  - Consider splitting large features

References:
  - https://trunkbaseddevelopment.com/
  - docs/trunk-based-development.md
```

### Example 2: Verbose Output

```bash
/branch.enforce --verbose

# Output includes:
# - Last commit timestamp
# - Committer name
# - Commit message
# - File change stats
```

### Example 3: Auto-Fix Mode

```bash
/branch.enforce --fix

# Output:
Scanning for violations...

❌ feature/complex-refactor (36h old, no flag)
   Creating feature flag: refactor_complex_enabled
   ✅ Flag created

1 flag auto-created
```

---

## Integration with Workflow

### Git Hook Integration

The `pre-push` hook calls branch enforcement:

```bash
# .git/hooks/pre-push
.spec-flow/scripts/bash/branch-enforce.sh --current-branch-only
```

**Behavior**:
- Only checks current branch
- Warns at 18h
- Blocks at 24h (unless flag exists)

### CI Integration

**GitHub Actions**: `.github/workflows/branch-health.yml`

```yaml
name: Branch Health Check

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  check-branches:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check branch health
        run: |
          .spec-flow/scripts/bash/branch-enforce.sh

      - name: Create issue if violations
        if: failure()
        run: |
          gh issue create \
            --title "Branch age violations detected" \
            --body "Run /branch.enforce for details" \
            --label "branch-health"
```

### DORA Metrics Integration

Branch ages feed into DORA metrics:

```bash
/metrics.dora

# Includes:
# - Average branch lifetime: 14h
# - Branches >24h: 1 (violation)
# - Deployment frequency: Correlated with small batches
```

---

## Error Handling

### No Violations

```
✅ Branch health check passed

All branches within age limits:
  - 8 healthy branches (<18h)
  - 0 warning branches
  - 0 violations

Keep up the good work with small batches!
```

### Git Repository Issues

```
❌ Error: Not a git repository

Run this command from repository root.
```

### Feature Flag Registry Missing

```
⚠️ Feature flag registry not found

Creating .spec-flow/memory/feature-flags.yaml...
✅ Registry created (empty)
```

---

## Best Practices

### 1. Run Daily

Check branch health every morning:

```bash
/branch.enforce
```

### 2. Merge Warning Branches Same Day

Don't let branches reach 24h. Merge at warning threshold (18h).

### 3. Use Flags for Large Work

If feature takes >24h:
- Add flag on day 1
- Merge daily with flag wrapping incomplete code
- Remove flag when done

### 4. Split Large Features

If feature consistently takes >24h, it's too large. Split into smaller vertical slices (epics).

### 5. Monitor Flag Debt

Flags should be temporary. Track and clean up:

```bash
/flag.list --expired
```

---

## References

- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [DORA Metrics](https://dora.dev/research/)
- [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
- `docs/trunk-based-development.md` - Full guide
- `/flag.add` - Create feature flags
- `/flag.cleanup` - Remove feature flags

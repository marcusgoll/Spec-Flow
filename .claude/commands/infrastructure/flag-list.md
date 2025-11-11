# /flag.list - List Feature Flags

**Purpose**: Display all feature flags with status, age, and expiry warnings. Track flag debt.

**Usage**:
```bash
/flag.list [--expired] [--epic EPIC] [--status STATUS]
```

**Parameters**:
- `--expired`: Show only expired flags (>expiry date)
- `--epic EPIC`: Filter by epic
- `--status STATUS`: Filter by status (active|retired)

**Output**: Table of flags with health indicators

---

## Output Format

### Default View (All Active Flags)

```
Feature Flags
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

acs_sync_enabled
  Status: ✅ Active
  Age: 3d (created 2025-11-07)
  Expires: 2025-11-24 (in 14d)
  Epic: acs-epic-a
  Branch: feature/acs-sync
  Reason: Large feature - merging daily

dashboard_redesign_enabled
  Status: ⚠️  Active (near expiry)
  Age: 12d (created 2025-10-29)
  Expires: 2025-11-10 (in 0d) ← EXPIRES TODAY
  Epic: None
  Branch: feature/dashboard-ui
  Reason: UI overhaul

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  Total: 2 active flags
  Expiring soon (<3d): 1
  Expired: 0

Recommendations:
  - Remove dashboard_redesign_enabled (expires today)
  - Run: /flag.cleanup dashboard_redesign_enabled
```

### Expired Flags View

```bash
/flag.list --expired
```

```
Expired Feature Flags
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

experiment_v2_enabled
  Status: ❌ EXPIRED (7d ago)
  Age: 21d (created 2025-10-20)
  Expired: 2025-11-03
  Epic: None
  Branch: feature/experiment
  Reason: A/B test

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ Action Required:
  1 flag expired >7 days ago

Clean up immediately:
  /flag.cleanup experiment_v2_enabled
```

---

## Color Coding

**Status indicators**:
- ✅ Active (healthy, not expiring soon)
- ⚠️  Active (expires <3 days)
- ❌ Expired (past expiry date)
- ✔️  Retired (cleaned up)

**Expiry warnings**:
- **Green** (>7d until expiry): Normal
- **Yellow** (<3d until expiry): Warning
- **Red** (expired): Critical

---

## Filter Options

### By Epic

```bash
/flag.list --epic acs-epic-a
```

Shows only flags for ACS Sync epic (Epic A).

### By Status

```bash
/flag.list --status retired
```

Shows cleaned-up flags (historical record).

---

## Implementation

### Script Location

**Bash**: `.spec-flow/scripts/bash/flag-list.sh`

### Algorithm

```bash
# 1. Parse feature-flags.yaml
flags=$(yq eval '.flags[]' feature-flags.yaml)

# 2. Apply filters
if [[ -n "$EPIC" ]]; then
  flags=$(echo "$flags" | yq eval "select(.epic == \"$EPIC\")")
fi

# 3. Calculate ages and expiry status
for flag in $flags; do
  created=$(echo "$flag" | yq eval '.created')
  expires=$(echo "$flag" | yq eval '.expires')

  age_days=$(days_between "$created" now)
  days_until_expiry=$(days_between now "$expires")

  if [[ $days_until_expiry -lt 0 ]]; then
    status="expired"
  elif [[ $days_until_expiry -lt 3 ]]; then
    status="expiring_soon"
  else
    status="active"
  fi
done

# 4. Sort by expiry (soonest first)
sort_by_expiry

# 5. Format output
format_flag_list
```

---

## Examples

### Example 1: List All Flags

```bash
/flag.list

# Output:
Feature Flags
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

acs_sync_enabled (✅ Active, expires in 14d)
dashboard_redesign_enabled (⚠️ Expiring soon, expires in 2d)
payment_stripe_enabled (✅ Active, expires in 20d)

Summary: 3 active flags, 1 expiring soon
```

### Example 2: Check Expired Flags

```bash
/flag.list --expired

# Output (if none):
✅ No expired flags

All flags within expiry limits.
```

### Example 3: Epic Filter

```bash
/flag.list --epic acs-epic-b

# Output:
Feature Flags for Epic: acs-epic-b
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

acs_parser_enabled (✅ Active, expires in 12d)
acs_ocr_enabled (✅ Active, expires in 12d)

Summary: 2 flags for acs-epic-b
```

---

## Integration with DORA Metrics

Flag metrics feed into DORA dashboard:

```bash
/metrics.dora

# Includes:
Feature Flag Health:
  - Active flags: 3
  - Expired flags: 0
  - Average flag lifetime: 4.2 days
  - Flags >14 days old: 0 (target: 0)
```

---

## CI Integration

**GitHub Actions**: `.github/workflows/flag-linter.yml`

```yaml
name: Flag Expiry Linter

on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9am

jobs:
  check-flags:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for expired flags
        run: |
          .spec-flow/scripts/bash/flag-list.sh --expired

      - name: Fail if expired >7 days
        run: |
          # Script exits 1 if any flag expired >7d
          .spec-flow/scripts/bash/flag-check-expired.sh --max-age 7
```

**Alert**: Creates GitHub issue if flags expired >7 days

---

## Best Practices

### 1. Check Daily

Review flags every morning:

```bash
/flag.list
```

### 2. Clean Up Expiring Flags

Remove flags expiring <3 days:

```bash
/flag.list

# See warning → clean up
/flag.cleanup dashboard_redesign_enabled
```

### 3. Monitor Epic Flags

Check epic progress via flags:

```bash
/flag.list --epic acs-epic-a

# Many flags = slow progress or large epic
# Consider splitting epic
```

---

## References

- `/flag.add` - Create flags
- `/flag.cleanup` - Remove flags
- `/branch.enforce` - Branch health (flags exempt from 24h limit)
- `/metrics.dora` - DORA metrics including flag debt

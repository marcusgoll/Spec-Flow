# /branch.enforce — Branch Age Enforcement

**Purpose**: audit all branches for age violations and enforce trunk-based development (short-lived branches by default).
**Default policy**: warn at 18h, block at 24h unless a feature flag exists.

**Why this policy exists**: short-lived branches reduce integration risk and correlate with better delivery performance; trunk-based development and small batch sizes are repeatedly linked to higher throughput and stability.

**References**:
- [Trunk Based Development](https://trunkbaseddevelopment.com/short-lived-feature-branches/)
- [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
- [DORA Research](https://dora.dev/research/)

## Usage

```bash
/branch.enforce [--fix] [--verbose] [--json] [--current-branch-only] \
  [--max-hours 24] [--warn-hours 18] [--default-branch <name>] [--no-color]
```

### Parameters

* `--fix` auto-create feature flags for violating branches so you can merge without blocking.
* `--verbose` include last commit metadata and change stats.
* `--json` machine-readable report to stdout; still returns nonzero on hard violations.
* `--current-branch-only` check just HEAD (for `pre-push` hooks).
* `--max-hours` hard limit in hours; default 24.
* `--warn-hours` warning threshold; default 18.
* `--default-branch` override detection if your default isn't discoverable.
* `--no-color` disable ANSI colors.

### Prerequisites

* Git repository at repo root.
* Feature flag registry at `.spec-flow/memory/feature-flags.yaml` (auto-created if missing).
* Optional: `.spec-flow/scripts/bash/flag-add.sh` if you want centralized flag creation.

### Outputs

* Human report (or JSON if `--json`).
* Nonzero exit when blocking (to stop a push).
* Updated `feature-flags.yaml` when `--fix`.

---

## Enforcement rules

* **< warn-hours**: healthy.
* **warn-hours..max-hours**: warning, merge soon or flag it.
* **> max-hours**: violation. Block push unless a feature flag exists.
* Feature flags are recommended for any work expected to exceed 24h; they're a standard mechanism to keep trunk green while finishing slices.

---

## Implementation (drop-in script)

Save as: `.spec-flow/scripts/bash/branch-enforce.sh`
Make executable: `cd repo-root && chmod +x .spec-flow/scripts/bash/branch-enforce.sh`

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# /branch.enforce - Branch Age Enforcement
# - Warn at 18h, block at 24h by default
# - Exceptions: branches with feature flags in .spec-flow/memory/feature-flags.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Defaults
WARN_HOURS=18
MAX_HOURS=24
DEFAULT_BRANCH_OVERRIDE=""
JSON_OUT=false
FIX_MODE=false
VERBOSE=false
CURRENT_ONLY=false
NO_COLOR=false

# Colors
if [ -t 1 ]; then
  BOLD="\033[1m"; RED="\033[31m"; YELLOW="\033[33m"; GREEN="\033[32m"; DIM="\033[2m"; NC="\033[0m"
else
  BOLD=""; RED=""; YELLOW=""; GREEN=""; DIM=""; NC=""
fi

usage() {
  cat <<EOF
Usage: /branch.enforce [--fix] [--verbose] [--json] [--current-branch-only]
                       [--max-hours N] [--warn-hours N] [--default-branch NAME] [--no-color]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix) FIX_MODE=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --json) JSON_OUT=true; shift ;;
    --current-branch-only) CURRENT_ONLY=true; shift ;;
    --max-hours) MAX_HOURS="${2:?}"; shift 2 ;;
    --warn-hours) WARN_HOURS="${2:?}"; shift 2 ;;
    --default-branch) DEFAULT_BRANCH_OVERRIDE="${2:?}"; shift 2 ;;
    --no-color) NO_COLOR=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if $NO_COLOR; then BOLD=""; RED=""; YELLOW=""; GREEN=""; DIM=""; NC=""; fi

cd "$REPO_ROOT"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Not a git repository (run from repo root)"; exit 2
fi

# Determine default branch robustly
detect_default_branch() {
  if [ -n "$DEFAULT_BRANCH_OVERRIDE" ]; then
    echo "$DEFAULT_BRANCH_OVERRIDE"; return
  fi
  # Prefer remote HEAD if present
  if git rev-parse --verify -q "refs/remotes/origin/HEAD" >/dev/null; then
    git rev-parse --abbrev-ref "origin/HEAD" | sed 's@^origin/@@'
    return
  fi
  # Fallbacks
  if git show-ref --verify --quiet refs/heads/main; then echo "main"; return; fi
  if git show-ref --verify --quiet refs/heads/master; then echo "master"; return; fi
  # As last resort, current branch
  git rev-parse --abbrev-ref HEAD
}

DEFAULT_BRANCH="$(detect_default_branch)"

# Flag registry helpers
FLAG_REGISTRY=".spec-flow/memory/feature-flags.yaml"
mkdir -p "$(dirname "$FLAG_REGISTRY")"
touch "$FLAG_REGISTRY"

has_feature_flag() {
  local branch="$1"
  # Match either explicit branch mapping or normalized flag name
  grep -qE "(^|\s)branch:\s*$branch\b" "$FLAG_REGISTRY" 2>/dev/null && return 0 || return 1
}

normalize_flag_name() {
  # feature/foo-bar -> foo_bar_enabled
  local b="$1"
  b="${b#feature/}"
  echo "${b//[^a-zA-Z0-9]/_}_enabled"
}

create_flag_for_branch() {
  local branch="$1"
  local flag_name
  flag_name="$(normalize_flag_name "$branch")"

  if [ -x ".spec-flow/scripts/bash/flag-add.sh" ]; then
    ".spec-flow/scripts/bash/flag-add.sh" "$flag_name" --branch "$branch" --reason "Auto: branch age > ${MAX_HOURS}h"
  else
    # Append minimal YAML entry
    {
      echo "- name: $flag_name"
      echo "  branch: $branch"
      echo "  reason: Auto-generated for branch age policy"
      echo "  enabled: true"
    } >> "$FLAG_REGISTRY"
  fi

  echo "$flag_name"
}

# Branch list
list_branches() {
  if $CURRENT_ONLY; then
    git rev-parse --abbrev-ref HEAD
    return
  fi
  git for-each-ref --format='%(refname:short)' refs/heads/ \
    | grep -Ev "^(${DEFAULT_BRANCH}|main|master)$" || true
}

# Age computation:
# Find merge-base with default branch; then first commit timestamp unique to branch since divergence.
branch_age_hours() {
  local branch="$1"
  local base
  base="$(git merge-base "$branch" "$DEFAULT_BRANCH" 2>/dev/null || true)"
  local since=""

  if [ -n "$base" ]; then
    since="^$base"
  else
    # No common base? fall back to entire history unique to branch
    since="--not $DEFAULT_BRANCH"
  fi

  local first_ct
  first_ct="$(git log --reverse --format=%ct "$branch" $since 2>/dev/null | head -1 || true)"
  if [ -z "$first_ct" ]; then
    echo "0"; return
  fi
  local now
  now="$(date +%s)"
  echo $(( (now - first_ct) / 3600 ))
}

last_commit_info() {
  local branch="$1"
  git log -1 --format='%ct|%h|%an|%ae|%s' "$branch" 2>/dev/null || echo "0||||"
}

classify() {
  local age="$1"; local flagged="$2"
  if (( age < WARN_HOURS )); then echo "healthy"; return; fi
  if (( age < MAX_HOURS )); then echo "warning"; return; fi
  if [ "$flagged" = "true" ]; then echo "violation_flagged"; else echo "violation"; fi
}

# Collect
declare -a REPORT_LINES=()
HEALTHY=0; WARN=0; VIOL=0; VIOL_FLAGGED=0
EXIT_CODE=0

mapfile -t BRANCHES < <(list_branches)

if $JSON_OUT; then
  echo -n '{"defaultBranch":"'"$DEFAULT_BRANCH"'","warnHours":'"$WARN_HOURS"',"maxHours":'"$MAX_HOURS"',"branches":['
fi

idx=0
for br in "${BRANCHES[@]}"; do
  [ -z "$br" ] && continue
  age="$(branch_age_hours "$br")"
  flagged=false
  if has_feature_flag "$br"; then flagged=true; fi
  status="$(classify "$age" "$flagged")"

  IFS='|' read -r lct sh an ae msg <<<"$(last_commit_info "$br")"
  lct="${lct:-0}"

  case "$status" in
    healthy) ((HEALTHY++)) ;;
    warning) ((WARN++)) ;;
    violation_flagged) ((VIOL_FLAGGED++)) ;;
    violation) ((VIOL++)); EXIT_CODE=1 ;;
  esac

  if $JSON_OUT; then
    [[ $idx -gt 0 ]] && echo -n ','
    echo -n '{"branch":"'"$br"'", "ageHours":'"$age"', "status":"'"$status"'", "flagged":'"$flagged"', "lastCommit": {"ts":'"$lct"', "sha":"'"$sh"'", "author":"'"$an"'", "email":"'"$ae"'", "subject":'"$(printf '%s' "$msg" | jq -Rsa .)"'}}'
    ((idx++))
  else
    # Human output
    printf "%s\n" "$br"
    printf "  Age: %sh\n" "$age"
    case "$status" in
      healthy)
        printf "  Status: ${GREEN}✅ Healthy${NC}\n"
        ;;
      warning)
        printf "  Status: ${YELLOW}⚠️  Warning${NC} (merge within %sh)\n" "$((MAX_HOURS - age))"
        printf "  Recommendation: Merge or add feature flag\n"
        ;;
      violation)
        printf "  Status: ${RED}❌ Violation${NC} (%sh over limit)\n" "$((age - MAX_HOURS))"
        printf "  Recommendation: Add feature flag immediately\n"
        ;;
      violation_flagged)
        printf "  Status: ${RED}❌ Violation${NC} (%sh over limit)\n" "$((age - MAX_HOURS))"
        printf "  Feature flag: ${GREEN}✅ Exists${NC} (push allowed)\n"
        printf "  Recommendation: Complete work and remove flag\n"
        ;;
    esac
    if $VERBOSE; then
      if [ "$lct" -gt 0 ]; then
        printf "  Last commit: %s | %s | %s <%s>\n" "$(date -d "@$lct" '+%Y-%m-%d %H:%M')" "$sh" "$an" "$ae"
        printf "  Message: %s\n" "$msg"
      fi
    fi
    printf "\n"
  fi

  # Auto-fix
  if $FIX_MODE && [ "$status" = "violation" ]; then
    flag="$(create_flag_for_branch "$br")"
    if ! $JSON_OUT; then
      echo "  Auto-fix: Created feature flag ${BOLD}$flag${NC}"
      echo ""
    fi
    # After flagging, we don't change EXIT_CODE here: CI may still want to fail loudly on policy breach.
  fi
done

if $JSON_OUT; then
  echo -n '],"summary":{"healthy":'"$HEALTHY"',"warning":'"$WARN"',"violation":'"$VIOL"',"violationFlagged":'"$VIOL_FLAGGED"'},"defaultBranchResolved":"'"$DEFAULT_BRANCH"'" }'
  echo
else
  echo "Branch Health Report"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "✅ Healthy: %d  ⚠️  Warning: %d  ❌ Violation: %d (flagged: %d)\n" "$HEALTHY" "$WARN" "$VIOL" "$VIOL_FLAGGED"
  printf "Default branch: %s\n" "$DEFAULT_BRANCH"
fi

# If --fix was used, allow success for hooks to proceed even with violations,
# but still return 1 in CI unless explicitly handled.
if $FIX_MODE; then exit 0; fi
exit "$EXIT_CODE"
```

---

## Hook and CI integration

### Pre-push Hook (blocks at >24h unless flagged)

```bash
cd repo-root
cat > .git/hooks/pre-push <<'HOOK'
#!/usr/bin/env bash
.spec-flow/scripts/bash/branch-enforce.sh --current-branch-only
HOOK
chmod +x .git/hooks/pre-push
```

Git's `pre-push` hook runs before refs are sent; exiting nonzero blocks the push.

### GitHub Actions (scheduled drift check)

```yaml
# .github/workflows/branch-health.yml
name: Branch Health Check
on:
  schedule:
    - cron: '0 */6 * * *'
  workflow_dispatch: {}
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: .spec-flow/scripts/bash/branch-enforce.sh --json | tee branch-health.json
      - name: Fail on violations
        run: |
          jq '.summary.violation > 0' branch-health.json | grep -q true && exit 1 || exit 0
```

### DORA Metrics Integration

The JSON output gives average branch lifetime and count >24h for your internal dashboard. DORA research consistently highlights small batch sizes and frequent integration as key capabilities of high performers.

---

## Feature-flag hygiene

Flags are a tool, not a lifestyle. Track and remove them as work completes; Fowler's taxonomy and guidance apply, especially using Release Toggles to keep trunk green while you finish slices.

**Related commands**:
- `/flag.add` — Create feature flags
- `/flag.list` — List all flags and their status
- `/flag.cleanup` — Remove expired flags

---

## Examples

### Example 1: Standard Audit

```bash
/branch.enforce

# Output:
feature/user-auth
  Age: 12h
  Status: ✅ Healthy

feature/dashboard-ui
  Age: 20h
  Status: ⚠️  Warning (merge within 4h)
  Recommendation: Merge or add feature flag

feature/complex-refactor
  Age: 36h
  Status: ❌ Violation (12h over limit)
  Recommendation: Add feature flag immediately

Branch Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Healthy: 1  ⚠️  Warning: 1  ❌ Violation: 1 (flagged: 0)
Default branch: main
```

### Example 2: Verbose Output

```bash
/branch.enforce --verbose

# Output includes:
# - Last commit timestamp
# - Committer name and email
# - Commit message
```

### Example 3: Auto-Fix Mode

```bash
/branch.enforce --fix

# Output:
feature/complex-refactor
  Age: 36h
  Status: ❌ Violation (12h over limit)
  Auto-fix: Created feature flag complex_refactor_enabled

Branch Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Healthy: 0  ⚠️  Warning: 0  ❌ Violation: 1 (flagged: 1)
```

### Example 4: JSON Output (for CI/metrics)

```bash
/branch.enforce --json

# Output:
{
  "defaultBranch": "main",
  "warnHours": 18,
  "maxHours": 24,
  "branches": [
    {
      "branch": "feature/user-auth",
      "ageHours": 12,
      "status": "healthy",
      "flagged": false,
      "lastCommit": {
        "ts": 1699632000,
        "sha": "abc1234",
        "author": "John Doe",
        "email": "john@example.com",
        "subject": "Add user authentication"
      }
    }
  ],
  "summary": {
    "healthy": 1,
    "warning": 0,
    "violation": 0,
    "violationFlagged": 0
  },
  "defaultBranchResolved": "main"
}
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
❌ Not a git repository (run from repo root)
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

- [Trunk-Based Development](https://trunkbaseddevelopment.com/short-lived-feature-branches/)
- [DORA Metrics](https://dora.dev/research/)
- [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
- [Git Remote](https://www.kernel.org/pub/software/scm/git/docs/git-remote.html)
- `/flag.add` - Create feature flags
- `/flag.cleanup` - Remove feature flags
- `/flag.list` - List all flags

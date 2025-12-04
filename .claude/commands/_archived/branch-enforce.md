---
name: branch-enforce
description: Audit branches for age violations and enforce trunk-based development (warn 18h, block 24h unless feature-flagged)
argument-hint: [--fix] [--verbose] [--json] [--current-branch-only] [--max-hours N] [--warn-hours N] [--default-branch NAME] [--no-color]
allowed-tools: [Bash(.spec-flow/scripts/bash/branch-enforce.sh), Bash(git *), Read, Grep]
---

# /branch-enforce — Branch Age Enforcement

<context>
**Arguments**: $ARGUMENTS

**Current Branch**: !`git rev-parse --abbrev-ref HEAD 2>$null || echo "unknown"`

**All Branches (with age)**: !`git branch -a --format='%(refname:short) | Last commit: %(committerdate:relative)' | head -10 || echo "no branches"`

**Default Branch**: !`git symbolic-ref refs/remotes/origin/HEAD 2>$null | sed 's@^refs/remotes/origin/@@' || echo "main"`

**Feature Flags Registry**: !`test -f .spec-flow/memory/feature-flags.yaml && echo "exists" || echo "missing"`

**Branch Enforcement Script**: !`test -f .spec-flow/scripts/bash/branch-enforce.sh && echo "exists" || echo "missing (script needs installation)"`

**Git Repository**: !`git rev-parse --is-inside-work-tree 2>$null && echo "yes" || echo "no"`
</context>

<objective>
Audit all branches for age violations and enforce trunk-based development policy to reduce integration risk and improve delivery performance.

**Purpose**: Short-lived branches correlate with better throughput and stability. This command enforces a default policy to keep branches small and merges frequent.

**Default Policy**:
- **< 18h**: Healthy (✅)
- **18h-24h**: Warning (⚠️) - merge soon or create feature flag
- **> 24h**: Violation (❌) - blocks push unless feature flag exists

**Why This Policy Exists**:
- Short-lived branches reduce integration risk
- Trunk-based development linked to higher delivery performance
- Small batch sizes improve stability (DORA research)

**Feature Flags as Exception Mechanism**:
- For work expected to exceed 24h, create a feature flag
- Keeps trunk green while finishing larger slices
- Standard mechanism for managing long-running work

**Arguments**:
- `--fix`: Auto-create feature flags for violating branches (allows merge without blocking)
- `--verbose`: Include last commit metadata and change stats
- `--json`: Machine-readable JSON output (still returns nonzero on violations)
- `--current-branch-only`: Check just HEAD (useful for pre-push hooks)
- `--max-hours N`: Override hard limit (default: 24)
- `--warn-hours N`: Override warning threshold (default: 18)
- `--default-branch NAME`: Override default branch detection
- `--no-color`: Disable ANSI colors in output

**Prerequisites**:
- Git repository at repo root
- Feature flag registry at `.spec-flow/memory/feature-flags.yaml` (auto-created if missing)
- Branch enforcement script at `.spec-flow/scripts/bash/branch-enforce.sh`

**Timing**: < 1 second for most repos (scans all branches)
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent false enforcement results.

1. **Never claim script succeeded without actual exit code**
   - Check actual bash exit code from branch-enforce.sh
   - Exit code 0 = all branches healthy or flagged
   - Exit code 1 = violations found (blocking)
   - Don't claim "all branches healthy" without verification

2. **Quote actual violation output from script**
   - Report actual branch names, ages, violation types
   - Don't invent branch names or ages
   - Include actual "⚠️" or "❌" indicators from script output

3. **Verify script exists before running**
   - Check `.spec-flow/scripts/bash/branch-enforce.sh` exists
   - If missing, report: "Branch enforcement script not found. Run: npx spec-flow init"
   - Don't proceed without script

4. **Read actual feature flags file if --fix used**
   - After --fix mode, read `.spec-flow/memory/feature-flags.yaml`
   - Quote actual feature flags created
   - Don't claim flags created without verifying file update

5. **Report actual branch count and ages**
   - Parse actual script output for branch statistics
   - Quote actual counts: healthy/warning/violation
   - Don't estimate or round numbers

**Why this matters**: False branch health claims allow violating branches to be pushed, breaking trunk-based development discipline. Accurate enforcement maintains code quality and delivery performance.

---

<process>

### Step 1: Verify Prerequisites

**Check script exists**:
```bash
test -f .spec-flow/scripts/bash/branch-enforce.sh
```

If script doesn't exist:
```
❌ Branch enforcement script not found

Expected: .spec-flow/scripts/bash/branch-enforce.sh

This script should be installed during project initialization.

Installation options:
1. Run: npx spec-flow init
2. Create manually from the branch-enforce documentation
3. Copy from spec-flow package: node_modules/spec-flow/.spec-flow/scripts/bash/branch-enforce.sh

Cannot proceed with enforcement without script.
```
EXIT immediately

**Check git repository**:
```bash
git rev-parse --is-inside-work-tree
```

If not in git repo:
```
❌ Not in a git repository

Branch enforcement requires a git repository.
Run: git init
```
EXIT immediately

### Step 2: Execute Branch Enforcement Script

**Run script with user-provided arguments**:

```bash
.spec-flow/scripts/bash/branch-enforce.sh $ARGUMENTS
```

**What the script does**:

1. **Detects default branch**:
   - Tries `git symbolic-ref refs/remotes/origin/HEAD`
   - Falls back to common names (main, master, develop)
   - Can be overridden with `--default-branch NAME`

2. **Lists all branches** (or just current if `--current-branch-only`):
   - Gets branch list from `git branch -a`
   - Filters out default branch and remote HEAD references
   - Calculates age from last commit date

3. **Categorizes branches by age**:
   - **Healthy**: < warn-hours (default 18h)
   - **Warning**: warn-hours to max-hours (default 18h-24h)
   - **Violation**: > max-hours (default 24h)

4. **Checks for feature flags**:
   - Reads `.spec-flow/memory/feature-flags.yaml`
   - Branches with matching feature flags are allowed (exempt from blocking)
   - Violations without flags cause exit code 1 (blocking)

5. **Generates report**:
   - Human-readable format (default) with colors
   - JSON format if `--json` flag provided
   - Lists each branch with age, status, and flag status

6. **Creates feature flags if --fix**:
   - For each violating branch without a flag
   - Adds entry to `feature-flags.yaml`
   - Allows push to proceed

**Script output format** (human-readable):
```
Branch Health Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

feature/long-running-work (36 hours old)
  ❌ Violation (>24h) - No feature flag found
  Last commit: 36 hours ago by user@example.com
  Recommendation: Create feature flag or merge ASAP

feature/quick-fix (8 hours old)
  ✅ Healthy (<18h)

feature/needs-review (20 hours old)
  ⚠️  Warning (>18h) - Merge soon or create feature flag

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary:
✅ Healthy: 5  ⚠️  Warning: 3  ❌ Violation: 1 (flagged: 0)
Default branch: main

VIOLATION: Cannot push until violations are resolved.
Create feature flag with: --fix
```

**Script output format** (JSON):
```json
{
  "default_branch": "main",
  "branches": [
    {
      "name": "feature/long-running-work",
      "age_hours": 36,
      "status": "violation",
      "feature_flagged": false,
      "last_commit_author": "user@example.com",
      "last_commit_date": "2025-11-19T10:00:00Z"
    }
  ],
  "summary": {
    "healthy": 5,
    "warning": 3,
    "violation": 1,
    "violation_flagged": 0
  },
  "exit_code": 1
}
```

### Step 3: Check Script Exit Code

**Interpret exit code**:
- Exit code 0: All branches healthy OR all violations have feature flags
- Exit code 1: Violations found without feature flags (blocking)

**If exit code 1 (violations)**:

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ BRANCH POLICY VIOLATIONS FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Quote actual violation details from script output}

Violations block deployment. Options:

1. Merge violating branches immediately
2. Create feature flags: re-run with --fix
3. Delete stale branches if no longer needed

After resolving, re-run branch enforcement to verify.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If exit code 0 (all healthy or flagged)**:

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ BRANCH POLICY COMPLIANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Quote actual summary from script output}

All branches comply with trunk-based development policy:
- Healthy branches: {count}
- Warning branches: {count} (merge soon recommended)
- Violations with feature flags: {count}

{If warnings exist}
⚠️  Recommendation: Merge warning-level branches within 6 hours to avoid violations

Trunk-based development benefits:
- Reduced integration risk
- Faster feedback loops
- Higher delivery performance (DORA research)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Verify Feature Flag Updates (If --fix Used)

**If $ARGUMENTS contains --fix**:

**Read feature flags file**:
```bash
Read(.spec-flow/memory/feature-flags.yaml)
```

**Verify flags were created**:
- Check file was updated (compare timestamp or content)
- Quote actual feature flags added
- Confirm each violating branch now has a flag

Display:
```
✅ Feature flags created for violating branches

Updated: .spec-flow/memory/feature-flags.yaml

Flags created:
{List actual flags from file}

These branches can now be pushed. Remember to:
1. Complete and merge work as soon as possible
2. Remove feature flags after merging
3. Keep flags documented and reviewed
```

</process>

<success_criteria>
**Branch enforcement successfully completed when:**

1. **Prerequisites verified**:
   - Branch enforcement script exists at `.spec-flow/scripts/bash/branch-enforce.sh`
   - Git repository detected
   - Feature flags registry exists or auto-created

2. **Script executed successfully**:
   - Script ran without crashing
   - Exit code captured (0 or 1)
   - Output generated (human or JSON format)

3. **Branches analyzed**:
   - All branches scanned (or just current if `--current-branch-only`)
   - Age calculated from last commit date
   - Each branch categorized: healthy/warning/violation

4. **Policy enforcement applied**:
   - Violations identified correctly
   - Feature flag exceptions checked
   - Exit code reflects policy compliance (0=pass, 1=violations)

5. **Report generated**:
   - Clear status indicators (✅/⚠️/❌)
   - Actual branch names and ages from script output
   - Summary counts: healthy/warning/violation
   - Recommendations provided based on status

6. **Feature flags updated** (if --fix mode):
   - `.spec-flow/memory/feature-flags.yaml` updated
   - Flags created for violating branches without flags
   - File timestamp changed after script execution

7. **User informed**:
   - Violations clearly listed (if any)
   - Remediation options provided
   - Next steps guidance based on compliance status
   - DORA research benefits reinforced
</success_criteria>

<verification>
**Before marking branch-enforce complete, verify:**

1. **Check script exit code**:
   - Actual bash exit code from branch-enforce.sh
   - 0 = compliance (healthy or flagged), 1 = violations
   - Don't claim compliance without exit code 0

2. **Verify branch counts from actual output**:
   ```bash
   # Extract counts from script output
   grep "Healthy:" script-output.log
   grep "Warning:" script-output.log
   grep "Violation:" script-output.log
   # Counts should match reported summary
   ```

3. **Check violations are real**:
   - Branch names from actual script output (not invented)
   - Ages calculated from actual git log (not estimated)
   - Feature flag status from actual file content (not assumed)

4. **Verify feature flags created** (if --fix mode):
   ```bash
   cat .spec-flow/memory/feature-flags.yaml
   # Should show newly created flags with branch names matching violations
   ```

5. **Check script actually ran**:
   ```bash
   test -f .spec-flow/scripts/bash/branch-enforce.sh
   # Should exist before claiming script executed
   ```

**Never claim enforcement passed without:**
- Actual script exit code 0
- Actual branch data from script output (not fabricated)
- Actual feature flags file update (if --fix mode)
- Actual violation details quoted from script
</verification>

<output>
**Files created/modified by this command:**

**Feature flags** (if --fix mode used):
- `.spec-flow/memory/feature-flags.yaml` - Updated with feature flags for violating branches
  - Each violating branch gets entry: `branch-name: { enabled: true, description: "Auto-created by branch-enforce" }`

**Console output**:
- Branch health report (human-readable or JSON format)
- Status indicators for each branch (✅ Healthy, ⚠️ Warning, ❌ Violation)
- Branch name, age, last commit author
- Feature flag status (flagged/not flagged)
- Summary counts (healthy/warning/violation totals)
- Recommendations based on violations found
- Exit code: 0 (compliance) or 1 (violations)

**Exit codes**:
- `0`: All branches comply (healthy or have feature flags)
- `1`: Violations found without feature flags (blocks push in CI/hooks)

**Script log** (if verbose mode):
- Last commit metadata for each branch
- Change statistics (files changed, insertions, deletions)
- Detailed timing calculations

**No files modified** (unless --fix mode):
- Default mode only reports, doesn't change state
- --fix mode explicitly required to create feature flags
</output>

---

## Notes

**Trunk-Based Development Philosophy**:
- Mainline (trunk/main) is always shippable
- Feature branches are short-lived (< 24h default)
- Continuous integration to trunk reduces risk
- Small batch sizes improve delivery performance

**References**:
- [Trunk Based Development](https://trunkbaseddevelopment.com/short-lived-feature-branches/)
- [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
- [DORA Research](https://dora.dev/research/) - Links trunk-based development to higher throughput and stability

**Feature Flags as Escape Hatch**:
- Not a replacement for merging frequently
- Intended for genuinely long-running work (>24h)
- Should be temporary - remove after merge
- Document why flag is needed

**Integration Points**:

**Pre-push Hook** (blocks at >24h unless flagged):
```bash
cat > .git/hooks/pre-push <<'HOOK'
#!/usr/bin/env bash
.spec-flow/scripts/bash/branch-enforce.sh --current-branch-only
HOOK
chmod +x .git/hooks/pre-push
```

**GitHub Actions** (scheduled drift check):
```yaml
name: Branch Age Audit
on:
  schedule:
    - cron: "0 9 * * *" # Daily at 9am
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: .spec-flow/scripts/bash/branch-enforce.sh --json
```

**Common Patterns**:

1. **Daily audit**: Run on schedule to find stale branches
2. **Pre-push enforcement**: Block pushes for violating branches
3. **Auto-fix mode**: Create flags automatically for violating branches
4. **JSON output**: Integrate with dashboards or reports

**Policy Customization**:
- Adjust thresholds: `--warn-hours 12 --max-hours 18` for stricter policy
- Relax for specific project: `--max-hours 48` for slower-paced teams
- Per-branch exceptions: Use feature flags in `.spec-flow/memory/feature-flags.yaml`

**Troubleshooting**:

**Script not found**:
```bash
# Install via spec-flow package
npx spec-flow init

# Or copy manually
cp node_modules/spec-flow/.spec-flow/scripts/bash/branch-enforce.sh .spec-flow/scripts/bash/
chmod +x .spec-flow/scripts/bash/branch-enforce.sh
```

**Feature flags not working**:
```bash
# Check file format
cat .spec-flow/memory/feature-flags.yaml

# Should be YAML format:
# branch-name:
#   enabled: true
#   description: "Reason for long-running branch"
```

**Default branch not detected**:
```bash
# Override detection
.spec-flow/scripts/bash/branch-enforce.sh --default-branch main
```

**Colors not showing**:
- Colors auto-disable when output is piped
- Force disable: `--no-color`
- Force enable: Run in terminal (TTY detected)

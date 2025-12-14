---
description: Initialize and manage parallel AI developer worktrees (Dev Studio). Creates persistent worktrees for concurrent Claude Code agents.
allowed-tools: [Read, Write, Bash(.spec-flow/scripts/bash/worktree-manager.sh:*), Bash(gh:*), Bash(git:*), Bash(mkdir:*), Bash(test:*), Bash(ls:*), Bash(yq:*), Glob, AskUserQuestion]
argument-hint: init <N> | setup | status | stop
---

<context>
Git repository: !`git rev-parse --is-inside-work-tree 2>/dev/null && echo "Yes" || echo "No"`

GitHub auth: !`gh auth status >/dev/null 2>&1 && echo "Authenticated" || echo "Not authenticated"`

Repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "Unknown"`

Existing worktrees: !`git worktree list --porcelain 2>/dev/null | grep -c "^worktree" || echo "0"`

Studio state: !`test -f .spec-flow/studio/state.yaml && echo "Active" || echo "Not initialized"`

Roadmap status (next): !`gh issue list --label "status:next,type:feature" --json number --jq 'length' 2>/dev/null || echo "0"`

Roadmap status (backlog): !`gh issue list --label "status:backlog,type:feature" --json number --jq 'length' 2>/dev/null || echo "0"`
</context>

<objective>
Manage the Dev Studio - a parallel AI development workflow where multiple git worktrees act as persistent AI developer stations.

**Commands:**
- **init N** - Create N persistent worktrees (1-10) for parallel development
- **setup** - Configure GitHub branch protection for auto-merge CI flow
- **status** - Show all agent worktrees and their current work
- **stop** - Guidance for graceful shutdown

**Target workflow:**
```
/studio setup         → Configure GitHub for auto-merge
/studio init 3        → Create 3 agent worktrees
(open terminals, cd into each, run claude)
Each agent: /feature next → work → /ship-staging → /finalize → repeat
```

**Prerequisites:**
- Git repository with remote
- GitHub CLI authenticated
- Worktree manager script available
</objective>

<process>

## Step 0: Parse Command

Extract subcommand from $ARGUMENTS:
- `init N` → Create N worktrees
- `setup` → Configure GitHub branch protection
- `status` → Show studio status
- `stop` → Shutdown guidance

If no arguments or help requested, display usage and exit.

---

## Command: init N

### 1.1 Validate Prerequisites

```bash
# Check git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not inside a git repository"
  exit 1
fi

# Check GitHub auth
if ! gh auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI not authenticated. Run: gh auth login"
  exit 1
fi
```

### 1.2 Parse and Validate Agent Count

Extract N from arguments. Validate:
- N must be a positive integer
- N must be between 1 and 10
- Default to 3 if not specified

### 1.3 Create Studio Directory Structure

```bash
# Create studio directory
mkdir -p worktrees/studio

# Create studio state directory
mkdir -p .spec-flow/studio
```

### 1.4 Create Worktrees

For i in 1 to N:

```bash
AGENT_ID="agent-$i"
BRANCH_NAME="studio/$AGENT_ID"
WORKTREE_PATH="worktrees/studio/$AGENT_ID"

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
  echo "Worktree $AGENT_ID already exists, skipping..."
  continue
fi

# Create branch if it doesn't exist
if ! git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git branch "$BRANCH_NAME" main
fi

# Create worktree
git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"

# Link shared memory
bash .spec-flow/scripts/bash/worktree-manager.sh link-memory "$AGENT_ID" 2>/dev/null || true

echo "Created: $WORKTREE_PATH"
```

### 1.5 Initialize Studio State File

Create `.spec-flow/studio/state.yaml`:

```yaml
version: "1.0"
created_at: {TIMESTAMP}
studio:
  status: active
  agent_count: {N}

agents:
  - id: agent-1
    worktree_path: worktrees/studio/agent-1
    branch: studio/agent-1
  - id: agent-2
    worktree_path: worktrees/studio/agent-2
    branch: studio/agent-2
  # ... for each agent
```

### 1.6 Display Success and Instructions

Output:
```
Dev Studio Initialized!

Created {N} agent worktrees:
  - worktrees/studio/agent-1/
  - worktrees/studio/agent-2/
  - worktrees/studio/agent-3/

Next steps:
1. Run '/studio setup' to configure GitHub auto-merge (one-time)
2. Open {N} terminal windows
3. In each terminal:
   cd worktrees/studio/agent-{N}
   claude
4. In Claude Code, run: /feature next

Roadmap: {X} issues in next, {Y} in backlog

Each agent will:
- Claim issues automatically (no duplicates via GitHub labels)
- Create PRs with auto-merge enabled
- Continue to next issue after /finalize
- Stop when roadmap is empty
```

---

## Command: setup

### 2.1 Detect Repository

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
if [ -z "$REPO" ]; then
  echo "Error: Could not detect GitHub repository"
  exit 1
fi
```

### 2.2 Check Current Branch Protection

```bash
PROTECTION=$(gh api repos/$REPO/branches/main/protection 2>/dev/null || echo "{}")
```

### 2.3 Configure Branch Protection

Use AskUserQuestion to confirm before applying:
- Question: "Configure GitHub branch protection for auto-merge on main?"
- Options: "Yes" / "No, show manual steps"

If Yes:

```bash
# Enable auto-merge on repository
gh api repos/$REPO -X PATCH -f allow_auto_merge=true

# Configure branch protection
gh api repos/$REPO/branches/main/protection -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["test", "build", "lint", "typecheck"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

Note: `required_pull_request_reviews: null` means no review required - CI gates are sufficient.

### 2.4 Display Confirmation

```
GitHub Setup Complete!

Repository: {REPO}
Branch: main

Configured:
- Auto-merge enabled on repository
- Required status checks: test, build, lint, typecheck
- No required reviewers (CI gates are sufficient)
- Force pushes disabled

PRs will auto-merge when all CI checks pass.
```

---

## Command: status

### 3.1 Check Studio State

```bash
if [ ! -f .spec-flow/studio/state.yaml ]; then
  echo "Dev Studio not initialized. Run: /studio init N"
  exit 0
fi
```

### 3.2 Gather Agent Status

For each agent in state.yaml:

```bash
WORKTREE_PATH=$(yq eval ".agents[$i].worktree_path" .spec-flow/studio/state.yaml)

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  STATUS="Missing"
  FEATURE="N/A"
  PHASE="N/A"
else
  # Get current branch
  BRANCH=$(cd "$WORKTREE_PATH" && git rev-parse --abbrev-ref HEAD)

  # Check for active feature
  FEATURE_STATE=$(find "$WORKTREE_PATH/specs" -name "state.yaml" -type f 2>/dev/null | head -1)
  if [ -n "$FEATURE_STATE" ]; then
    FEATURE=$(yq eval '.feature.slug // "unknown"' "$FEATURE_STATE" 2>/dev/null || echo "unknown")
    PHASE=$(yq eval '.phase // "unknown"' "$FEATURE_STATE" 2>/dev/null || echo "unknown")
    STATUS="Working"
  else
    FEATURE="None"
    PHASE="Idle"
    STATUS="Idle"
  fi
fi
```

### 3.3 Query Roadmap Status

```bash
NEXT_COUNT=$(gh issue list --label "status:next,type:feature" --json number --jq 'length' 2>/dev/null || echo "0")
BACKLOG_COUNT=$(gh issue list --label "status:backlog,type:feature" --json number --jq 'length' 2>/dev/null || echo "0")
IN_PROGRESS=$(gh issue list --label "status:in-progress" --json number --jq 'length' 2>/dev/null || echo "0")
```

### 3.4 Display Status Table

```
╔══════════════════════════════════════════════════════════════════╗
║                       DEV STUDIO STATUS                          ║
╠══════════════════════════════════════════════════════════════════╣
║ Status: ACTIVE                                                   ║
║ Agents: {N} configured                                           ║
╠══════════════════════════════════════════════════════════════════╣

┌─────────┬──────────┬─────────────────┬────────────┐
│ Agent   │ Status   │ Feature         │ Phase      │
├─────────┼──────────┼─────────────────┼────────────┤
│ agent-1 │ Working  │ user-auth       │ implement  │
│ agent-2 │ Working  │ dashboard       │ optimize   │
│ agent-3 │ Idle     │ None            │ -          │
└─────────┴──────────┴─────────────────┴────────────┘

Roadmap:
  Next:        {X} issues
  Backlog:     {Y} issues
  In Progress: {Z} issues

Run '/feature next' in idle agents to claim work.
```

---

## Command: stop

### 4.1 Display Shutdown Guidance

```
Dev Studio Shutdown Guide

Current agents will complete their current feature before stopping.

To gracefully stop:
1. Let each agent finish its current feature (/ship-staging → /finalize)
2. When prompted "Pick up next issue?", select "No"
3. Agents will return to idle

To clean up worktrees after all agents stop:
  git worktree remove worktrees/studio/agent-1
  git worktree remove worktrees/studio/agent-2
  git worktree remove worktrees/studio/agent-3

Or remove all at once:
  rm -rf worktrees/studio/
  git worktree prune

To remove studio state:
  rm -rf .spec-flow/studio/

Note: Do not force-remove worktrees with uncommitted changes.
```

</process>

<validation>
- Studio initialized: `.spec-flow/studio/state.yaml` exists
- Worktrees created: All directories in `worktrees/studio/` exist
- GitHub configured: Auto-merge enabled, branch protection set
- Agents can claim work: `/feature next` succeeds without duplicate claims
</validation>

<version>1.0.0</version>

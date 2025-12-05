---
name: context
description: Manage workflow context (handoffs, todos, session status)
argument-hint: <action> [args...] where action is: next | todos | add | status | audit
allowed-tools: [SlashCommand, Read, Bash, AskUserQuestion]
---

# /context — Consolidated Context Management

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for context management operations:

- `/context next` → Create handoff doc for fresh context (integrates with session-manager)
- `/context todos` → View and select from backlog
- `/context add <desc>` → Add item to backlog
- `/context status` → Show current session and workflow status
- `/context audit` → Audit CLAUDE.md quality

Helps maintain continuity across sessions and manage work backlog.
</objective>

<process>

## Step 1: Parse Action and Route

**Extract first argument as action:**

```
$action = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**Route based on action:**

| Action | Routes To | Purpose |
|--------|-----------|---------|
| `next` | /_archived/whats-next | Create handoff document |
| `todos` | /_archived/check-todos | View/select from backlog |
| `add` | /_archived/add-to-todos | Add to backlog |
| `status` | Direct bash call | Show session status |
| `audit` | /_archived/audit-claude-md | Audit CLAUDE.md |

**If no action provided:**
Use AskUserQuestion to ask:
```
Question: "What context operation do you need?"
Options:
  - next: Create handoff for fresh context
  - status: Show current session status
  - todos: View outstanding items
  - add: Add something to backlog
  - audit: Audit CLAUDE.md quality
```

## Step 2: Execute Action

**For `status` action:**
Run directly via Bash:
```bash
bash .spec-flow/scripts/bash/session-manager.sh status
```

**For other actions:**
Use SlashCommand tool to invoke the appropriate archived command:
```
SlashCommand: /_archived/{mapped-command} $remaining
```

## Step 3: Session Integration (for `next` action)

After generating handoff with whats-next command:

1. Check if Spec-Flow workflow is active
2. If active, also run session-manager.sh handoff to update state.yaml
3. Display continuation instructions

</process>

<success_criteria>
- Action correctly identified from arguments
- Appropriate command invoked
- Session state properly tracked for workflow-aware actions
- Remaining arguments passed through
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/context next` | Create handoff document |
| `/context status` | Show session and workflow status |
| `/context todos` | List outstanding items |
| `/context add <desc>` | Add item to backlog |
| `/context audit [path]` | Audit CLAUDE.md |

## Common Workflows

**End of session:**
```bash
/context next
```

**Check current state (after context compaction or session resume):**
```bash
/context status
```

**Start of session:**
```bash
/context todos
```

**Capture idea for later:**
```bash
/context add "refactor auth module"
```

## Session Management

The `/context` command integrates with the Spec-Flow session management system:

- **SessionStart hook**: Auto-displays workflow status on session resume/compact
- **PreCompact hook**: Auto-generates handoff before context compaction
- **Stop hook**: Auto-checkpoints state on session end

For direct session control:
```bash
bash .spec-flow/scripts/bash/session-manager.sh start --autopilot
bash .spec-flow/scripts/bash/session-manager.sh decision "Using Redis for caching"
bash .spec-flow/scripts/bash/session-manager.sh end --summary "Completed auth implementation"
```

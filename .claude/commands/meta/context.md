---
name: context
description: Manage workflow context (handoffs, todos, audits)
argument-hint: <action> [args...] where action is: next | todos | add | audit
allowed-tools: [SlashCommand, Read, AskUserQuestion]
---

# /context — Consolidated Context Management

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for context management operations:

- `/context next` → Create handoff doc for fresh context
- `/context todos` → View and select from backlog
- `/context add <desc>` → Add item to backlog
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
| `audit` | /_archived/audit-claude-md | Audit CLAUDE.md |

**If no action provided:**
Use AskUserQuestion to ask:
```
Question: "What context operation do you need?"
Options:
  - next: Create handoff for fresh context
  - todos: View outstanding items
  - add: Add something to backlog
  - audit: Audit CLAUDE.md quality
```

## Step 2: Execute Routed Command

Use SlashCommand tool to invoke the appropriate archived command:

```
SlashCommand: /_archived/{mapped-command} $remaining
```

</process>

<success_criteria>
- Action correctly identified from arguments
- Appropriate archived command invoked
- Remaining arguments passed through
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/context next` | Create handoff document |
| `/context todos` | List outstanding items |
| `/context add <desc>` | Add item to backlog |
| `/context audit [path]` | Audit CLAUDE.md |

## Common Workflows

**End of session:**
```bash
/context next
```

**Start of session:**
```bash
/context todos
```

**Capture idea for later:**
```bash
/context add "refactor auth module"
```

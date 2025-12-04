---
name: create
description: Create Claude Code extensions (prompts, commands, agents, skills, hooks)
argument-hint: <type> [args...] where type is: prompt | command | agent | skill | hook
allowed-tools: [SlashCommand, Read, AskUserQuestion]
---

# /create — Consolidated Creation Command

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for creating Claude Code extensions. Routes to specialized creation commands:

- `/create prompt` → Generate optimized Claude prompts
- `/create command` → Create new slash command
- `/create agent` → Create specialized subagent
- `/create skill` → Create agent skill with progressive disclosure
- `/create hook` → Create event-driven hook

All additional arguments are passed through to the underlying commands.
</objective>

<process>

## Step 1: Parse Type and Route

**Extract first argument as type:**

```
$type = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**Route based on type:**

| Type | Routes To |
|------|-----------|
| `prompt` | /_archived/create-prompt |
| `command` | /_archived/create-slash-command |
| `agent` | /_archived/create-subagent |
| `skill` | /_archived/create-agent-skill |
| `hook` | /_archived/create-hook |

**If no type provided:**
Use AskUserQuestion to ask:
```
Question: "What would you like to create?"
Options:
  - prompt: Optimized Claude prompt
  - command: New slash command
  - agent: Specialized subagent
  - skill: Agent skill file
  - hook: Event-driven hook
```

## Step 2: Execute Routed Command

Use SlashCommand tool to invoke the appropriate archived command:

```
SlashCommand: /_archived/create-{type} $remaining
```

</process>

<success_criteria>
- Type correctly identified from arguments
- Appropriate archived command invoked
- All remaining arguments passed through
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/create prompt <desc>` | Generate Claude prompt |
| `/create command <desc>` | Create slash command |
| `/create agent <desc>` | Create subagent config |
| `/create skill <desc>` | Create skill file |
| `/create hook` | Create hook config |

## Examples

```bash
/create prompt "analyze code quality"
/create command "deploy to staging"
/create agent "database migration specialist"
/create skill "TDD workflow"
/create hook
```

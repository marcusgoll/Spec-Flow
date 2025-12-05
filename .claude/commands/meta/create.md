---
name: create
description: Create Claude Code extensions (prompts, commands, agents, skills, hooks)
argument-hint: <type> [args...] where type is: prompt | command | agent | skill | hook
allowed-tools: [Skill, Read, Write, AskUserQuestion]
---

# /create — Consolidated Creation Command

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for creating Claude Code extensions with expert guidance:

- `/create prompt <desc>` → Generate optimized Claude prompts
- `/create command <desc>` → Create new slash command with best practices
- `/create agent <desc>` → Create specialized subagent configuration
- `/create skill <desc>` → Create agent skill with progressive disclosure
- `/create hook` → Create event-driven hook

All creation commands provide expert guidance on structure, best practices, and validation.
</objective>

<process>

## Step 1: Parse Type Argument

**Extract first argument as type:**

```
$type = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**If no type provided:**
Use AskUserQuestion to ask:
```json
{
  "question": "What would you like to create?",
  "header": "Extension Type",
  "multiSelect": false,
  "options": [
    {
      "label": "prompt",
      "description": "Optimized Claude prompt with XML structure"
    },
    {
      "label": "command",
      "description": "New slash command following best practices"
    },
    {
      "label": "agent",
      "description": "Specialized subagent configuration"
    },
    {
      "label": "skill",
      "description": "Agent skill file with progressive disclosure"
    },
    {
      "label": "hook",
      "description": "Event-driven hook for tool/session events"
    }
  ]
}
```

## Step 2: Invoke Appropriate Skill

<when_argument_is value="prompt">

### Create Prompt

**Purpose**: Generate optimized, XML-structured prompts with intelligent depth selection.

**Invoke skill**:
```
Skill: create-meta-prompts
```

Pass remaining arguments to skill for prompt generation.

**What the skill provides**:
- XML-structured prompt templates
- Intelligent depth selection (quick/standard/comprehensive)
- Context engineering best practices
- Progressive disclosure patterns
- Example outputs and validation

</when_argument_is>

<when_argument_is value="command">

### Create Slash Command

**Purpose**: Create new slash command following Claude Code best practices.

**Invoke skill**:
```
Skill: create-slash-commands
```

Pass remaining arguments for slash command creation.

**What the skill provides**:
- YAML frontmatter structure
- Argument parsing patterns
- Tool restrictions and allowed-tools configuration
- Dynamic context integration
- Progressive disclosure via skills
- Validation and testing guidance

</when_argument_is>

<when_argument_is value="agent">

### Create Subagent

**Purpose**: Create specialized subagent configuration with role definition and tool selection.

**Invoke skill**:
```
Skill: create-subagents
```

Pass remaining arguments for subagent creation.

**What the skill provides**:
- Subagent configuration structure
- Role and objective definition
- Tool selection guidance
- Prompt engineering for agent prompts
- XML structure compliance
- Integration with Task tool

</when_argument_is>

<when_argument_is value="skill">

### Create Agent Skill

**Purpose**: Create agent skill file with progressive disclosure and best practices.

**Invoke skill**:
```
Skill: create-agent-skills
```

Pass remaining arguments for skill creation.

**What the skill provides**:
- SKILL.md structure and organization
- Progressive disclosure patterns
- Reference documentation separation
- Example patterns and anti-patterns
- Validation rules
- Testing and quality guidance

</when_argument_is>

<when_argument_is value="hook">

### Create Hook

**Purpose**: Create event-driven hook for tool use, session events, or user prompts.

**Invoke skill**:
```
Skill: create-hooks
```

Pass remaining arguments for hook creation.

**What the skill provides**:
- Hook types (PreToolUse, PostToolUse, Stop, SessionStart, etc.)
- Configuration structure
- Matcher patterns
- Command vs inline hooks
- Error handling
- Testing and debugging guidance

</when_argument_is>

</process>

<success_criteria>
- Type correctly identified from arguments
- Appropriate skill invoked
- All remaining arguments passed through
- Expert guidance provided by skill
- Created extension follows best practices
- Validation rules met
</success_criteria>

---

## Quick Reference

| Command | Purpose | Skill Used |
|---------|---------|------------|
| `/create prompt <desc>` | Generate Claude prompt | create-meta-prompts |
| `/create command <desc>` | Create slash command | create-slash-commands |
| `/create agent <desc>` | Create subagent config | create-subagents |
| `/create skill <desc>` | Create skill file | create-agent-skills |
| `/create hook` | Create hook config | create-hooks |

## Examples

```bash
# Create optimized prompt
/create prompt "analyze code quality and suggest improvements"

# Create new slash command
/create command "deploy to staging environment"

# Create specialized subagent
/create agent "database migration specialist with rollback capability"

# Create agent skill
/create skill "TDD workflow with red-green-refactor cycle"

# Create event hook
/create hook
# (Will prompt for hook type and configuration)
```

## What Each Extension Type Provides

**Prompt** (create-meta-prompts):
- XML-structured templates
- Intelligent depth selection
- Context engineering patterns
- Progressive disclosure
- Research → Plan → Implement workflows

**Command** (create-slash-commands):
- YAML frontmatter configuration
- Argument hint and description
- Tool restrictions (allowed-tools)
- Dynamic context integration
- Skill integration for complex logic

**Agent** (create-subagents):
- Role and objective definition
- Tool selection for agent capabilities
- Prompt engineering for agent instructions
- Integration with Task tool
- XML structure compliance

**Skill** (create-agent-skills):
- Progressive disclosure structure
- Main SKILL.md with essential info
- Reference docs for deep dives
- Example patterns and anti-patterns
- Quality validation rules

**Hook** (create-hooks):
- Event-driven automation
- PreToolUse/PostToolUse hooks
- SessionStart/Stop hooks
- Matcher patterns for tool filtering
- Command execution or inline logic

## Best Practices

1. **Start with purpose**: Clearly define what the extension should do
2. **Follow patterns**: Use existing extensions as templates
3. **Progressive disclosure**: Don't overload main files, use reference docs
4. **Validation**: Test extensions before committing
5. **Documentation**: Include examples and usage patterns
6. **Tool restrictions**: Only allow necessary tools for security

## Skill Documentation

Each creation skill has comprehensive documentation:
- `.claude/skills/create-meta-prompts/SKILL.md`
- `.claude/skills/create-slash-commands/SKILL.md`
- `.claude/skills/create-subagents/SKILL.md`
- `.claude/skills/create-agent-skills/SKILL.md`
- `.claude/skills/create-hooks/SKILL.md`

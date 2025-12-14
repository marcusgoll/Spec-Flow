---
name: context
description: Manage workflow context (handoffs, todos, session status)
argument-hint: <action> [args...] where action is: next | todos | add | status
allowed-tools: [Read, Write, Edit, Bash, Glob, WebSearch, WebFetch, AskUserQuestion]
---

# /context — Consolidated Context Management

<context>
**Arguments**: $ARGUMENTS

**Current Directory**: !`pwd`

**TO-DOS File**: !`test -f TO-DOS.md && echo "exists" || echo "missing"`

**Active Features**: !`ls -d specs/*/state.yaml 2>/dev/null | wc -l || echo "0"`

**Session Manager**: !`test -f .spec-flow/scripts/bash/session-manager.sh && echo "available" || echo "missing"`
</context>

<objective>
Unified entry point for context management operations:

- `/context next` → Create handoff document for continuing work in fresh context
- `/context todos` → View and select from backlog
- `/context add <desc>` → Add item to backlog
- `/context status` → Show current session and workflow status

Helps maintain continuity across sessions and manage work backlog.
</objective>

<process>

## Step 1: Parse Action Argument

**Extract first argument as action:**

```
$action = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**If no action provided:**
Use AskUserQuestion to ask:
```json
{
  "question": "What context operation do you need?",
  "header": "Context Action",
  "multiSelect": false,
  "options": [
    {
      "label": "next",
      "description": "Create handoff document for fresh context"
    },
    {
      "label": "status",
      "description": "Show current session and workflow status"
    },
    {
      "label": "todos",
      "description": "View and select from outstanding items"
    },
    {
      "label": "add",
      "description": "Add something to backlog"
    }
  ]
}
```

## Step 2: Execute Action Based on Type

<when_argument_is value="next">

### Create Handoff Document

**Purpose**: Analyze current conversation and create handoff document for continuing work in a fresh context.

**Implementation Steps**:

1. **Analyze current conversation**:
   - Review conversation history
   - Identify incomplete tasks
   - Extract key decisions and context
   - Note any blockers or dependencies

2. **Create handoff document**:
   - File: `HANDOFF-{timestamp}.md`
   - Sections:
     - **Current State**: What was being worked on
     - **Completed**: What was finished
     - **In Progress**: What needs continuation
     - **Context**: Important decisions and rationale
     - **Next Steps**: Actionable items for next session
     - **Files Modified**: List of changed files
     - **Commands Used**: Workflow commands executed

3. **Check Spec-Flow workflow**:
   - If active workflow exists (check `specs/*/state.yaml` or `epics/*/state.yaml`), include workflow state
   - Extract current phase, feature slug, quality gates status
   - Include deployment metadata if available

4. **Integrate with session manager** (if available):
   ```bash
   if [ -f ".spec-flow/scripts/bash/session-manager.sh" ]; then
     bash .spec-flow/scripts/bash/session-manager.sh handoff
   fi
   ```

5. **Display handoff summary**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Handoff Document Created
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   File: HANDOFF-{timestamp}.md

   Summary:
   - {N} completed items
   - {N} in-progress items
   - {N} files modified

   To continue in new session:
     1. Read handoff document
     2. Review context and decisions
     3. Execute next steps

   Workflow state preserved in specs/{slug}/ or epics/{slug}/
   ```

</when_argument_is>

<when_argument_is value="todos">

### Check Todos

**Purpose**: List outstanding todos from TO-DOS.md and allow selection of item to work on.

**Implementation Steps**:

1. **Check if TO-DOS.md exists**:
   ```bash
   if [ ! -f "TO-DOS.md" ]; then
     echo "No TO-DOS.md file found. Create one or use /context add."
     exit 0
   fi
   ```

2. **Read and parse TO-DOS.md**:
   - Extract all list items (lines starting with `- [ ]` or `- `)
   - Number each item
   - Count total items

3. **Display todos**:
   ```
   Outstanding To-Dos:

   1. [ ] First todo item
   2. [ ] Second todo item
   3. [x] Completed item (show but gray out)
   ...

   Total: {N} items ({completed} done, {remaining} pending)
   ```

4. **Prompt for selection**:
   Use AskUserQuestion to let user select which item to work on:
   ```json
   {
     "question": "Which todo would you like to work on?",
     "header": "Select Todo",
     "multiSelect": false,
     "options": [
       {"label": "1", "description": "First todo description"},
       {"label": "2", "description": "Second todo description"},
       ...
     ]
   }
   ```

5. **Mark as in progress** (optional):
   - Update TO-DOS.md to show `- [~]` for in-progress
   - Or just display the selected item for focus

6. **Display selected todo**:
   ```
   Working on:
   {Selected todo description}

   Next steps:
   - Break down into subtasks if needed
   - Update TO-DOS.md when complete
   - Use /context add for new discoveries
   ```

</when_argument_is>

<when_argument_is value="add">

### Add To-Do Item

**Purpose**: Add new item to TO-DOS.md backlog with context from current conversation.

**Implementation Steps**:

1. **Get todo description**:
   - If provided in $remaining, use that
   - Otherwise, infer from recent conversation:
     - Look for unfinished tasks
     - Look for "TODO" or "FIXME" comments
     - Look for user requests not yet completed

2. **Ensure TO-DOS.md exists**:
   ```bash
   if [ ! -f "TO-DOS.md" ]; then
     echo "# To-Do List" > TO-DOS.md
     echo "" >> TO-DOS.md
   fi
   ```

3. **Add todo item**:
   - Use Edit tool to append to TO-DOS.md
   - Format: `- [ ] {description}`
   - Include context if relevant:
     ```markdown
     - [ ] {description}
       - Context: {why this is needed}
       - Related: {related files or features}
       - Priority: {high/medium/low}
     ```

4. **Confirm addition**:
   ```
   ✅ Added to TO-DOS.md:

   - [ ] {description}

   View all todos: /context todos
   ```

</when_argument_is>

<when_argument_is value="status">

### Show Session Status

**Purpose**: Display current session and workflow status.

**Implementation Steps**:

1. **Check for session manager**:
   ```bash
   if [ -f ".spec-flow/scripts/bash/session-manager.sh" ]; then
     bash .spec-flow/scripts/bash/session-manager.sh status
   else
     echo "Session manager not available"
   fi
   ```

2. **If session manager not available, show basic status**:
   ```
   Session Status
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Directory: {pwd}
   Branch: {git branch --show-current}
   Uncommitted changes: {git status --short | wc -l}

   Active Features:
   {ls -d specs/*/}

   Recent Commands:
   {Show recent slash commands if logged}

   To-Dos:
   {Count pending items from TO-DOS.md}
   ```

3. **Check workflow state** (if Spec-Flow active):
   - Read active workflow's `state.yaml` (in `specs/{slug}/` or `epics/{slug}/`)
   - Display current phase, feature, quality gates
   - Show deployment status if applicable

</when_argument_is>

</process>

<verification>
Before completing, verify:
- Action type correctly identified
- Appropriate operation executed
- Files created/updated successfully
- User presented with clear results
- TO-DOS.md maintained properly (for todos/add actions)
- Handoff document created with complete context (for next action)
</verification>

<success_criteria>
**Next action:**
- Handoff document created at HANDOFF-{timestamp}.md
- Contains current state, completed items, in-progress, context, next steps
- Workflow state preserved if Spec-Flow active
- Session manager updated if available

**Todos action:**
- TO-DOS.md read successfully
- All items displayed with numbering
- User can select item to focus on
- Clear indication of completed vs pending items

**Add action:**
- Todo description captured (from args or inferred)
- TO-DOS.md updated with new item
- Item formatted properly with checkbox
- Confirmation displayed to user

**Status action:**
- Session manager status shown (if available)
- Basic status shown (directory, branch, features, todos)
- Workflow state displayed if active
- Clear, actionable information provided
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/context next` | Create handoff document |
| `/context status` | Show session status |
| `/context todos` | View/select from backlog |
| `/context add "task"` | Add item to backlog |
| `/context add` | Infer todo from conversation |

## Examples

```bash
# Create handoff for new session
/context next

# Check current status
/context status

# View and select todo
/context todos

# Add explicit todo
/context add "Implement user authentication"

# Add inferred todo (from conversation)
/context add
```

## Integration with Spec-Flow

**Handoff Integration**:
- Captures workflow state from active workflow's `state.yaml` (in `specs/{slug}/` or `epics/{slug}/`)
- Includes current feature, phase, quality gates
- Preserves deployment metadata
- Enables seamless continuation in fresh context

**Session Manager Integration**:
- If `.spec-flow/scripts/bash/session-manager.sh` exists, integrates with it
- Updates session state on handoff creation
- Provides workflow-aware status reporting

## TO-DOS.md Format

```markdown
# To-Do List

## High Priority

- [ ] Critical task 1
  - Context: Why this matters
  - Related: file1.ts, file2.ts

- [ ] Critical task 2

## Medium Priority

- [ ] Regular task 1
- [~] In-progress task
- [x] Completed task

## Low Priority

- [ ] Nice-to-have task
```

**Checkbox states**:
- `[ ]` = Pending
- `[~]` = In Progress (optional)
- `[x]` = Completed

---
description: Enforce atomic task status updates through task-tracker (prevent manual edits to NOTES.md/tasks.md)
argument-hint: [optional task operation, e.g., "mark T001 complete"]
allowed-tools: Skill(task-status-sync)
---

<objective>
Delegate task status synchronization enforcement to the task-status-sync skill for: $ARGUMENTS

This routes to a specialized skill that:
- Intercepts manual Edit/Write attempts to tasks.md and NOTES.md
- Auto-converts manual edits to atomic task-tracker commands
- Validates task-tracker usage and auto-fixes common mistakes
- Maintains synchronization between tasks.md checkboxes and NOTES.md markers
- Prevents data inconsistencies from manual file edits
</objective>

<process>
1. Use Skill tool to invoke task-status-sync skill
2. Pass user's task operation request: $ARGUMENTS
3. Let skill handle:
   - Detection of manual edit attempts
   - Conversion to task-tracker commands
   - Validation of TaskId, status transitions, TDD compliance
   - Auto-fixes for common mistakes
   - Atomic execution updating both files
</process>

<success_criteria>
- Skill successfully invoked
- Arguments passed correctly to skill
- Manual edits blocked and converted to task-tracker commands
- tasks.md and NOTES.md stay synchronized
- Task status updates complete atomically
</success_criteria>

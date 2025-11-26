---
description: Enforce git commits after phases/tasks with auto-commit and safety checks
argument-hint: [optional: phase/task context]
allowed-tools: Skill(git-workflow-enforcer), Bash
---

<objective>
Delegate git workflow enforcement to the git-workflow-enforcer skill for: $ARGUMENTS

This routes to a specialized skill that:
- Auto-commits uncommitted changes with Conventional Commits format
- Validates branch safety (blocks main/master commits)
- Checks for merge conflicts
- Enforces clean working tree between phases
- Provides rollback points for every task/phase
</objective>

<process>
1. Use Skill tool to invoke git-workflow-enforcer skill
2. Pass context (phase completion, task completion, file changes): $ARGUMENTS
3. Let skill handle:
   - Uncommitted change detection
   - Context classification (phase/task/file)
   - Commit message generation
   - Safety validations (branch, conflicts, format)
   - Auto-commit execution
   - Verification and feedback
</process>

<success_criteria>
- Skill successfully invoked
- Uncommitted changes detected and committed
- Commit message follows Conventional Commits format
- Branch safety checks passed
- Working tree clean after commit
- Rollback point available
</success_criteria>

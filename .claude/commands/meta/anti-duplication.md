---
description: Search codebase for existing patterns before implementing new code to prevent duplication
argument-hint: [optional: what you want to implement]
allowed-tools: Skill(anti-duplication), Grep, Glob, Read
---

<objective>
Delegate anti-duplication search and analysis to the anti-duplication skill for: $ARGUMENTS

Before writing any new code (endpoints, components, services, models), this skill proactively searches the codebase for existing similar implementations to reuse, extend, or learn from.
</objective>

<process>
1. Use Skill tool to invoke anti-duplication skill
2. Pass user's implementation request: $ARGUMENTS
3. Let skill execute comprehensive search
4. Present reuse options (reuse, extend, extract pattern, follow pattern, or justify new)
5. Implement chosen approach
</process>

<success_criteria>
- Skill successfully invoked
- Codebase searched for similar patterns
- Reuse options presented to user
- Implementation follows DRY principle
- Code consistency maintained
</success_criteria>

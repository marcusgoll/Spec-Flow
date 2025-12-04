---
description: Detect breaking API/schema/interface changes before implementation and suggest safe migration paths
argument-hint: [optional: change description]
allowed-tools: Skill(breaking-change-detector), Grep, Glob, Read
---

<objective>
Delegate breaking change detection and migration planning to the breaking-change-detector skill for: $ARGUMENTS

Before modifying APIs, database schemas, or public interfaces, this skill detects breaking changes, assesses impact, and provides safe migration strategies to prevent production incidents.
</objective>

<process>
1. Use Skill tool to invoke breaking-change-detector skill
2. Pass change description: $ARGUMENTS
3. Let skill detect breaking changes
4. Review impact assessment and severity
5. Choose from suggested migration paths
6. Implement safe migration strategy
</process>

<success_criteria>
- Skill successfully invoked
- Breaking changes detected before implementation
- Impact scope assessed (clients affected, data at risk)
- Safe migration path provided
- CRITICAL changes blocked until migration plan exists
- Zero production breaking changes
</success_criteria>

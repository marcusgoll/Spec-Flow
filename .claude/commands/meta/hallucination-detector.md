---
description: Detect and prevent hallucinated technical decisions by validating against project's documented tech stack
argument-hint: [optional: technical suggestion to validate]
allowed-tools: Skill(hallucination-detector), Read, Grep, Glob
---

<objective>
Delegate hallucination detection to the hallucination-detector skill for: $ARGUMENTS

This skill validates all technical suggestions (frameworks, libraries, APIs, schemas, services) against docs/project/tech-stack.md and existing codebase to prevent hallucinated decisions that don't match project architecture.
</objective>

<process>
1. Use Skill tool to invoke hallucination-detector skill
2. Pass technical suggestion: $ARGUMENTS
3. Let skill load tech-stack.md (single source of truth)
4. Validate suggestion against documented choices
5. Verify entities/APIs exist in codebase
6. Require evidence for all technical claims
7. Block CRITICAL violations, correct suggestions
</process>

<success_criteria>
- Skill successfully invoked
- Tech stack loaded from docs/project/tech-stack.md
- Suggestion validated against documented choices
- Evidence provided (file path, docs URL, or verification)
- Hallucinations blocked (wrong framework, fake API, duplicate entity)
- Correct alternatives suggested
- Zero wrong tech in implementation
</success_criteria>

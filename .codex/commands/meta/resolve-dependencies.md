---
description: Detect and resolve package dependency conflicts before installation (npm, pip, cargo, composer)
argument-hint: [package manager command, e.g., "npm install react@18"]
allowed-tools: Skill(dependency-conflict-resolver)
---

<objective>
Delegate dependency conflict detection and resolution to the dependency-conflict-resolver skill for: $ARGUMENTS

This routes to a specialized skill that:
- Detects dependency conflicts before installation
- Validates peer dependencies and version compatibility
- Scans for security vulnerabilities
- Auto-resolves safe conflicts (patches, dev dependencies)
- Suggests manual review for breaking changes
- Blocks critical security vulnerabilities with alternatives
</objective>

<process>
1. Use Skill tool to invoke dependency-conflict-resolver skill
2. Pass user's installation command or package request: $ARGUMENTS
3. Let skill handle:
   - Package manager detection
   - Conflict analysis (peer deps, transitive deps, version constraints)
   - Security audit (npm audit, pip-audit, cargo-audit, composer audit)
   - Resolution strategy (auto-fix, suggest, or block)
   - Execution with resolved dependencies
</process>

<success_criteria>
- Skill successfully invoked
- Arguments passed correctly to skill
- Dependency conflicts identified and resolved
- Security vulnerabilities addressed
- Installation completes successfully or user receives actionable guidance
</success_criteria>

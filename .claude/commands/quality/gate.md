---
name: gate
description: Run quality gates (CI checks or security scanning)
argument-hint: <type> [args...] where type is: ci | sec
allowed-tools: [SlashCommand, Read, AskUserQuestion]
---

# /gate — Consolidated Quality Gates

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for quality gate validation:

- `/gate ci` → Run CI quality checks (tests, linters, type checks, coverage)
- `/gate sec` → Run security gate (SAST, secrets detection, dependency scanning)

These gates ensure code quality before deployment.
</objective>

<process>

## Step 1: Parse Type and Route

**Extract first argument as type:**

```
$type = first word of $ARGUMENTS
$remaining = rest of $ARGUMENTS
```

**Route based on type:**

| Type | Routes To | Purpose |
|------|-----------|---------|
| `ci` | /_archived/gate-ci | CI quality checks |
| `sec` | /_archived/gate-sec | Security scanning |

**If no type provided:**
Use AskUserQuestion to ask:
```
Question: "Which quality gate do you want to run?"
Options:
  - ci: CI checks (tests, linters, types, coverage ≥80%)
  - sec: Security (SAST, secrets, dependencies)
```

## Step 2: Execute Routed Command

Use SlashCommand tool to invoke the appropriate archived command:

```
SlashCommand: /_archived/gate-{type} $remaining
```

</process>

<success_criteria>
- Gate type correctly identified
- Appropriate archived command invoked
- All flags passed through
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/gate ci` | Run CI quality checks |
| `/gate ci --epic <name>` | CI gate for epic |
| `/gate sec` | Run security scanning |

## What Each Gate Checks

**CI Gate (`/gate ci`):**
- Unit/integration tests pass
- Linter checks pass
- Type checks pass
- Coverage ≥80%

**Security Gate (`/gate sec`):**
- No HIGH/CRITICAL SAST findings
- No secrets in code
- No vulnerable dependencies

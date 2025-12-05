---
name: init
description: Initialize project documentation, preferences, or design tokens
argument-hint: [--preferences | --tokens | project args...]
allowed-tools: [SlashCommand, Read]
---

# /init — Consolidated Project Initialization

<context>
**Arguments**: $ARGUMENTS
</context>

<objective>
Unified entry point for project initialization. Routes to specialized commands:

- `/init` → Project documentation (8 docs via interactive questionnaire)
- `/init --preferences` → User preference configuration
- `/init --tokens` → Design token generation (OKLCH + WCAG)

All flags are passed through to the underlying commands.
</objective>

<process>

## Step 1: Parse Arguments and Route

**Check $ARGUMENTS for routing:**

1. **If `--preferences` flag present:**
   ```
   Extract: Remove --preferences from arguments
   Route to: /project/init-preferences $remaining_args
   ```

2. **If `--tokens` flag present:**
   ```
   Extract: Remove --tokens from arguments
   Route to: /project/init-tokens $remaining_args
   ```

3. **Otherwise (default):**
   ```
   Route to: /project/init-project $ARGUMENTS
   ```

## Step 2: Execute Routed Command

Use SlashCommand tool to invoke the appropriate active command with all arguments passed through.

**For preferences:**
```
SlashCommand: /project/init-preferences [remaining args]
```

**For tokens:**
```
SlashCommand: /project/init-tokens [remaining args]
```

**For project (default):**
```
SlashCommand: /project/init-project [all args]
```

</process>

<success_criteria>
- Correct command identified from flags
- All arguments passed through properly
- Underlying command executes successfully
</success_criteria>

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/init` | Generate 8 project docs (interactive) |
| `/init --preferences` | Configure command defaults |
| `/init --tokens` | Generate OKLCH design tokens |
| `/init --with-design` | Project docs + design system |
| `/init --ci` | Non-interactive mode for CI/CD |

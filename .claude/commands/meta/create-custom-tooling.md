---
name: create-custom-tooling
description: Generate project-specific skills, commands, or hooks based on detected patterns from workflow audits
argument-hint: [skill|command|hook] [pattern-name] [--from-audit <epic-slug>]
allowed-tools: [Read, Write, Edit, Grep, Glob, AskUserQuestion, Task]
version: 1.0
created: 2025-12-04
---

# /create-custom-tooling — Pattern-Based Tooling Generation

**Purpose**: Transform recurring code patterns detected during `/audit-workflow` into reusable project-specific skills, slash commands, or hooks.

**Command**: `/create-custom-tooling [skill|command|hook] [pattern-name] [--from-audit <epic-slug>]`

**When to use**:
- After `/audit-workflow` identifies recurring patterns (3+ occurrences)
- When you notice repetitive code structures across features
- To codify project-specific conventions into reusable tools

---

<context>
**User Input**: $ARGUMENTS

**Check for audit reports:**
!`ls -la epics/*/audit-report.xml 2>/dev/null | head -5`

**Existing custom tooling:**
- Skills: !`ls .claude/skills/project-custom/ 2>/dev/null || echo "none"`
- Commands: !`ls .claude/commands/project-custom/ 2>/dev/null || echo "none"`
- Hooks: !`cat .claude/settings.json 2>/dev/null | grep -A5 '"hooks"' || echo "none"`
</context>

<objective>
Generate project-specific tooling (skill, command, or hook) based on detected patterns. This enables the workflow to self-improve by codifying recurring patterns into reusable automation.

**Tooling Types**:
- **Skill**: Reusable knowledge/templates that Claude loads on-demand (e.g., service boilerplate, CRUD patterns)
- **Command**: Executable slash command for specific actions (e.g., /generate-crud, /create-migration)
- **Hook**: Automated triggers on tool events (e.g., auto-format on file save, validate on commit)
</objective>

<process>

## Step 1: Parse Arguments and Determine Mode

**Parse $ARGUMENTS:**

```javascript
const args = "$ARGUMENTS".trim().split(/\s+/);
const toolingType = args[0]; // skill, command, or hook
const patternName = args[1]; // e.g., "service-boilerplate"
const fromAuditFlag = args.includes('--from-audit');
const epicSlug = fromAuditFlag ? args[args.indexOf('--from-audit') + 1] : null;
```

**If no arguments provided, enter discovery mode:**

```json
{
  "question": "What type of tooling do you want to create?",
  "header": "Tooling Type",
  "multiSelect": false,
  "options": [
    {"label": "Skill", "description": "Reusable knowledge/templates (e.g., service boilerplate)"},
    {"label": "Command", "description": "Executable slash command (e.g., /generate-crud)"},
    {"label": "Hook", "description": "Automated trigger on tool events (e.g., auto-lint)"}
  ]
}
```

## Step 2: Load Pattern Detection Data

**If --from-audit specified:**

```bash
# Read audit report for pattern suggestions
cat epics/${epicSlug}/audit-report.xml | grep -A20 "<pattern_detection>"
```

**If no audit specified, scan for patterns:**

```bash
# Find most recent audit with pattern suggestions
LATEST_AUDIT=$(ls -t epics/*/audit-report.xml 2>/dev/null | head -1)
if [ -n "$LATEST_AUDIT" ]; then
    cat "$LATEST_AUDIT" | grep -A20 "<pattern_detection>"
fi
```

**Display detected patterns:**

```
Detected Patterns from Workflow Audits
══════════════════════════════════════════════════════════════════════════════

Pattern: service-boilerplate
  Frequency: 5 occurrences
  Files: AuthService.ts, UserService.ts, OrderService.ts, ProductService.ts, PaymentService.ts
  Structure: DI + Repository pattern with standard CRUD methods
  Suggested: Skill (code generation template)

Pattern: api-crud-endpoints
  Frequency: 8 occurrences
  Files: Multiple route files
  Structure: OpenAPI contract → Router → Controller → Service
  Suggested: Command (/generate-crud)

Pattern: pre-commit-validation
  Frequency: Every commit
  Trigger: git commit
  Action: Run type check + lint + tests
  Suggested: Hook (PreToolUse on Bash git commit)

══════════════════════════════════════════════════════════════════════════════
```

## Step 3: Gather Pattern Details

**If pattern not specified, ask user to select:**

```json
{
  "question": "Which pattern do you want to codify?",
  "header": "Pattern",
  "multiSelect": false,
  "options": [
    {"label": "service-boilerplate", "description": "DI + Repository service structure (5 occurrences)"},
    {"label": "api-crud-endpoints", "description": "OpenAPI → Router → Controller flow (8 occurrences)"},
    {"label": "pre-commit-validation", "description": "Type check + lint before commits"},
    {"label": "Other", "description": "Describe a custom pattern"}
  ]
}
```

**Analyze pattern in codebase:**

```bash
# Find example files matching pattern
grep -r "class.*Service" src/ --include="*.ts" | head -5

# Extract common structure
cat src/auth/AuthService.ts | head -50
```

## Step 4: Generate Tooling Based on Type

### 4A: Generate Skill

**Create skill directory:**

```bash
mkdir -p .claude/skills/project-custom/${PATTERN_NAME}
```

**Generate SKILL.md:**

```markdown
# ${PATTERN_NAME_TITLE} Skill

${DESCRIPTION}

## Purpose

${PURPOSE_FROM_PATTERN}

## When to Invoke

- When creating a new ${ENTITY_TYPE}
- During /implement phase for ${ENTITY_TYPE}-related tasks
- Manual invocation: `Skill("${PATTERN_NAME}")`

## Template

\`\`\`${LANGUAGE}
${EXTRACTED_TEMPLATE}
\`\`\`

## Customization Points

${CUSTOMIZATION_POINTS}

## Usage Example

\`\`\`
User: "Create a new ProductService"
Claude: [Invokes ${PATTERN_NAME} skill, generates ProductService.ts]
\`\`\`

## Validation

After generation, verify:
- [ ] TypeScript compiles without errors
- [ ] Follows existing naming conventions
- [ ] Includes required dependencies
- [ ] Has corresponding test file
```

**Generate template file:**

```bash
# Extract template from example files
# Write to .claude/skills/project-custom/${PATTERN_NAME}/template.${EXT}
```

### 4B: Generate Command

**Create command file:**

```markdown
---
name: ${COMMAND_NAME}
description: ${DESCRIPTION}
argument-hint: <entity-name> [--options]
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash]
---

# /${COMMAND_NAME} — ${TITLE}

**Purpose**: ${PURPOSE}

**Command**: \`/${COMMAND_NAME} <entity-name> [--options]\`

<process>

## Step 1: Parse Arguments

Parse entity name and options from $ARGUMENTS.

## Step 2: Load Template

Read template from skill or inline template.

## Step 3: Generate Files

Create files based on template with entity name substituted.

## Step 4: Update Registrations

Add to DI container, route registrations, etc.

## Step 5: Generate Tests

Create test file scaffold.

</process>

<output>
Files created:
- src/${ENTITY_PATH}/${EntityName}Service.ts
- src/${ENTITY_PATH}/${EntityName}Controller.ts
- tests/${ENTITY_PATH}/${EntityName}.test.ts
</output>
```

### 4C: Generate Hook

**Update .claude/settings.json:**

```json
{
  "hooks": {
    "${HOOK_EVENT}": [
      {
        "matcher": "${MATCHER_PATTERN}",
        "command": "${HOOK_COMMAND}",
        "description": "${DESCRIPTION}"
      }
    ]
  }
}
```

**Hook event types:**
- `PreToolUse`: Before a tool executes (e.g., validate before Write)
- `PostToolUse`: After a tool completes (e.g., format after Edit)
- `Stop`: Before session ends (e.g., remind to commit)

## Step 5: Validate Generated Tooling

**For Skills:**

```bash
# Check skill structure
test -f ".claude/skills/project-custom/${PATTERN_NAME}/SKILL.md" && echo "SKILL.md exists"
test -f ".claude/skills/project-custom/${PATTERN_NAME}/template.*" && echo "Template exists"
```

**For Commands:**

```bash
# Check command structure
test -f ".claude/commands/project-custom/${COMMAND_NAME}.md" && echo "Command exists"
# Validate YAML frontmatter
head -10 ".claude/commands/project-custom/${COMMAND_NAME}.md"
```

**For Hooks:**

```bash
# Validate settings.json
cat .claude/settings.json | jq '.hooks'
```

## Step 6: Display Summary

```
Custom Tooling Created Successfully!
══════════════════════════════════════════════════════════════════════════════

Type: ${TOOLING_TYPE}
Name: ${TOOLING_NAME}
Location: ${LOCATION}

Based on pattern: ${PATTERN_NAME}
  Occurrences: ${FREQUENCY}
  Example files: ${EXAMPLE_FILES}

Files created:
  ${FILE_LIST}

Usage:
  ${USAGE_INSTRUCTIONS}

Test the tooling:
  ${TEST_COMMAND}

══════════════════════════════════════════════════════════════════════════════
```

</process>

<success_criteria>
- Pattern analyzed from audit report or codebase scan
- Tooling type selected (skill, command, or hook)
- Template extracted from example files
- Tooling files generated in correct location
- Validation checks pass
- Usage instructions provided
</success_criteria>

<anti_hallucination>
1. **Always analyze real code examples**
   Extract templates from actual files in the codebase, don't invent patterns.

2. **Verify pattern frequency**
   Only generate tooling for patterns with 3+ occurrences.

3. **Test generated tooling**
   Run validation checks before declaring success.

4. **Quote file paths**
   Show exact paths where tooling was created.

5. **Reference audit reports**
   Link to audit-report.xml that suggested the pattern.
</anti_hallucination>

<examples>

## Example 1: Create Service Boilerplate Skill

```bash
/create-custom-tooling skill service-boilerplate --from-audit 001-auth-epic
```

**Result:**
- Created: `.claude/skills/project-custom/service-boilerplate/SKILL.md`
- Created: `.claude/skills/project-custom/service-boilerplate/template.ts`
- Usage: `Skill("service-boilerplate")` or auto-invoked during /implement

## Example 2: Create CRUD Generator Command

```bash
/create-custom-tooling command generate-crud
```

**Result:**
- Created: `.claude/commands/project-custom/generate-crud.md`
- Usage: `/generate-crud User` creates UserService, UserController, UserRouter, User.test.ts

## Example 3: Create Pre-Commit Hook

```bash
/create-custom-tooling hook pre-commit-validation
```

**Result:**
- Updated: `.claude/settings.json` with PreToolUse hook
- Trigger: Before `git commit` commands
- Action: Run `npm run typecheck && npm run lint`

</examples>

<integration>
**Triggered by:**
- `/audit-workflow` (suggests patterns for tooling)
- `/heal-workflow` (applies approved tooling generation)
- Manual invocation

**Outputs used by:**
- Generated skills: Available via `Skill()` tool
- Generated commands: Available via `/${command-name}`
- Generated hooks: Auto-triggered on matching events
</integration>

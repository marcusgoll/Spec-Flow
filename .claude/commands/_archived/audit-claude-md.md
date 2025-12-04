---
description: Audit and refactor CLAUDE.md files to eliminate bloat, enforce best practices, and create folder-level CLAUDE.md files
arguments:
  - name: path
    description: Optional path to a specific CLAUDE.md file or directory
    required: false
---

# /audit-claude-md Command

Audit CLAUDE.md files for quality issues including bloat, vague language, missing sections, and poor progressive disclosure.

## Input

- **path** (optional): Path to specific CLAUDE.md file or directory to audit
  - If omitted, audits all CLAUDE.md files in repository

## Process

### Step 1: Invoke Skill

Load the audit-claude-md skill for comprehensive guidance:

```
skill: audit-claude-md
```

### Step 2: Run Audit Script

Execute the deterministic audit script:

```bash
bash .spec-flow/scripts/bash/audit-claude-md.sh --verbose $path
```

### Step 3: Analyze Results

For each CLAUDE.md file, report:
- **Grade** (A/B/C/F based on score)
- **Line count** vs. threshold
- **Vague language instances**
- **Strong modal usage**
- **Missing required sections**

### Step 4: Generate Recommendations

For files with grade B or lower, provide specific recommendations:

1. **If line count exceeds threshold**:
   - Identify sections to extract to `docs/references/`
   - Suggest progressive disclosure refactoring

2. **If vague language detected**:
   - List each instance with file:line reference
   - Suggest replacement with strong modals

3. **If missing WHAT/WHY/HOW sections**:
   - Provide template to add

### Step 5: Offer Actions

Present options to the user:
- **Auto-fix**: Apply safe automated fixes (vague language replacement)
- **Refactor plan**: Generate detailed refactoring plan for manual review
- **Create folder CLAUDE.md**: Split domain-specific content into folder-level files

## Output

Summary report with:
- Files analyzed
- Average quality score
- Overall grade
- Action items prioritized by impact

## Example Usage

```bash
# Audit all CLAUDE.md files
/audit-claude-md

# Audit specific file
/audit-claude-md ./CLAUDE.md

# Audit feature directory
/audit-claude-md specs/001-auth/
```

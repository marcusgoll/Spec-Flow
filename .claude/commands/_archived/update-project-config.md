---
name: update-project-config
description: Update project configuration settings (deployment model, scale tier, quick changes policy) with atomic commits
argument-hint: <configuration change description>
allowed-tools: [Read, Edit, Write, Grep, Bash(git add:*), Bash(git commit:*), Bash(date:*)]
---

# /update-project-config — Update Project Configuration

<context>
**User Input**: $ARGUMENTS

**Current Git Branch**: !`git branch --show-current 2>$null || echo "none"`

**Configuration File Exists**: !`test -f docs/project/project-configuration.md && echo "Yes" || echo "No"`

**Configuration File**: @docs/project/project-configuration.md

**Capacity Planning File**: @docs/project/capacity-planning.md

**Current Deployment Model**: !`grep -A1 "^\*\*Current\*\*:" docs/project/project-configuration.md 2>$null | grep -v "Current" | sed 's/.*\`//' | sed 's/\`.*//' || echo "Not set"`
</context>

<objective>
Update project-specific configuration settings (deployment model, scale tier, quick changes policy) in `docs/project/project-configuration.md` with atomic commits and metadata updates.

**Purpose**: Customize workflow behavior for your project by overriding auto-detected settings.

**When to use**: When changing deployment model, adjusting scale tier, or updating project-level configuration.

**Workflow position**: Project setup command (updates user's project configuration)

**Philosophy**: Project configuration is auto-detected but can be overridden by users. This command helps users customize workflow behavior for their project.
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent configuration errors.

1. **Never modify config file without reading it first**
   - Always Read docs/project/project-configuration.md before making changes
   - Verify file structure matches expected format
   - Quote current values when analyzing changes

2. **Verify file existence before proceeding**
   - Check if docs/project/project-configuration.md exists
   - If not found, instruct user to run /init-project first
   - Don't assume file structure - read and verify

3. **Parse arguments precisely**
   - Extract intent from $ARGUMENTS (deployment model change, scale tier update, policy change)
   - If unclear, ask user for clarification using AskUserQuestion
   - Never guess at configuration values

4. **Validate configuration values**
   - Deployment model must be: staging-prod, direct-prod, or local-only
   - Scale tier must be valid tier from capacity planning
   - Confirm changes with user before applying

5. **Verify git operations succeeded**
   - Check git commit with git log after committing
   - Confirm file staged with git status
   - Quote actual commit message in output

**Why this matters**: Configuration file governs workflow behavior. Incorrect changes break automation and deployment processes.

---

<process>

### Step 1: Verify Prerequisites

**Check that configuration file exists:**
1. Read docs/project/project-configuration.md
2. If not found, display error:
   ```
   ❌ Project configuration not found: docs/project/project-configuration.md

   Run /init-project first to create project documentation.
   ```
3. If found, confirm:
   ```
   ✅ Project configuration found
   ```

### Step 2: Display Current Configuration

**Show current settings to user:**
1. Extract current deployment model from configuration file
2. Extract scale tier from capacity-planning.md if it exists
3. Display:
   ```
   Current configuration:
     Deployment Model: {current value}
     Scale Tier: {current value from capacity-planning.md}
   ```

### Step 3: Parse Arguments

**Understand what user wants to change:**

**If $ARGUMENTS is empty**, display usage:
```
Usage: /update-project-config <configuration change description>

Examples:
  /update-project-config Set deployment model to staging-prod
  /update-project-config Change to direct-prod model
  /update-project-config Enable quick changes for all bug fixes
```

**If $ARGUMENTS provided**, analyze the request:
1. Parse change description from $ARGUMENTS
2. Detect intent:
   - Deployment model change? (keywords: deploy, staging, production, local)
   - Scale tier change? (keywords: scale, tier, capacity)
   - Quick changes policy? (keywords: quick, policy, bug)
3. Display:
   ```
   Configuration change requested:
     {$ARGUMENTS}
   ```

### Step 4: Guide User Through Update

**Interactive configuration update using AskUserQuestion:**

**If deployment model change detected**:
1. Use AskUserQuestion to present options:
   - Question: "Which deployment model would you like to use?"
   - Options:
     - staging-prod: "Full staging validation before production (recommended)"
     - direct-prod: "Direct production deployment without staging"
     - local-only: "Local builds only, no remote deployment"
2. Get user's choice
3. Display:
   ```
   Updating deployment model to: {choice}
   ```

**If scale tier change detected**:
1. Read capacity-planning.md to get available tiers
2. Use AskUserQuestion to present tier options
3. Get user's choice

**If quick changes policy detected**:
1. Use AskUserQuestion to ask about policy preference
2. Get user's choice

### Step 5: Apply Configuration Changes

**Update the configuration file using Edit tool:**

**For deployment model change**:
1. Locate the line with pattern: `**Current**: [deployment-model]`
2. Use Edit tool to replace with new value
3. Verify edit succeeded

**For scale tier change**:
1. Update docs/project/capacity-planning.md
2. Use Edit tool to replace scale tier value
3. Verify edit succeeded

**For quick changes policy**:
1. Locate quick changes policy section
2. Update policy description
3. Verify edit succeeded

### Step 6: Update Metadata

**Update last modified timestamp:**
1. Get current date in ISO format (YYYY-MM-DD)
2. Locate "Last Updated" line in configuration file
3. Use Edit tool to update date
4. Display:
   ```
   ✅ Metadata updated: {current date}
   ```

### Step 7: Commit Changes

**Create atomic commit:**

1. Stage the updated file:
   ```bash
   git add docs/project/project-configuration.md
   ```

2. If capacity-planning.md was updated, stage it too:
   ```bash
   git add docs/project/capacity-planning.md
   ```

3. Commit with descriptive message:
   ```bash
   git commit -m "config: $ARGUMENTS

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

4. Verify commit succeeded:
   ```bash
   git log -1 --oneline
   ```

5. Display commit confirmation:
   ```
   ✅ Configuration committed: {commit hash}
   ```

### Step 8: Display Summary and Next Steps

**Output summary to user:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONFIGURATION UPDATE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated: docs/project/project-configuration.md
Change: {$ARGUMENTS}
Commit: {hash}

### 💾 Next Steps

1. Review changes: Read docs/project/project-configuration.md
2. Future features will use updated configuration
3. {If deployment model changed} Next /ship will use {new model} workflow
```

</process>

<success_criteria>
**Configuration update successfully completed when:**

1. **Configuration file modified correctly**:
   - File read before modifications
   - Changes applied according to user's intent
   - File structure remains valid after changes
   - No syntax errors in markdown

2. **Metadata updated**:
   - Last Updated field shows current date
   - All modified sections properly updated

3. **Git operations successful**:
   - Configuration file(s) committed
   - Commit hash retrieved and displayed
   - Working tree clean after commit

4. **Validation passed**:
   - Deployment model is valid value (staging-prod, direct-prod, or local-only)
   - Scale tier matches available tiers (if updated)
   - File structure remains valid

5. **User informed**:
   - Summary displayed with file path, change description, commit hash
   - Next steps provided
   - No errors or warnings
</success_criteria>

<verification>
**Before marking configuration update complete, verify:**

1. **Read updated configuration file**:
   ```bash
   cat docs/project/project-configuration.md
   ```
   Should show applied changes

2. **Check deployment model is valid**:
   ```bash
   grep "**Current**:" docs/project/project-configuration.md
   ```
   Should show one of: staging-prod, direct-prod, local-only

3. **Verify git commit**:
   ```bash
   git log -1 --oneline
   ```
   Should show "config:" commit

4. **Check commit hash**:
   ```bash
   git rev-parse --short HEAD
   ```
   Should return valid hash

5. **Validate working tree**:
   ```bash
   git status
   ```
   Should show clean working tree

**Never claim completion without reading the updated file and verifying commit hash.**
</verification>

<output>
**Files created/modified by this command:**

**Configuration files**:
- docs/project/project-configuration.md — Updated with configuration changes
- docs/project/capacity-planning.md — Updated if scale tier changed

**Git commits**:
- Atomic commit: "config: {$ARGUMENTS}"

**Console output**:
- Current configuration display
- Change confirmation
- Commit hash confirmation
- Next steps recommendation
</output>

---

## Notes

**Configuration vs Principles:**
- `project-configuration.md` - Deployment model, scale tier (this command)
- `engineering-principles.md` - 8 core engineering standards (`/constitution` command)

**Auto-Detection**: Deployment model is auto-detected on first `/feature` run, but can be overridden here.

**Scale Tier**: Set in `capacity-planning.md`, referenced here for convenience.

**Quick Changes**: Policy for when to use `/quick` vs `/feature` workflow.

**Available Deployment Models**:
- **staging-prod**: Full staging validation before production (recommended)
  - Git remote + staging branch + `.github/workflows/deploy-staging.yml`
  - Workflow: /ship-staging → validate → /ship-prod
- **direct-prod**: Direct production deployment without staging
  - Git remote + no staging branch
  - Workflow: /deploy-prod
- **local-only**: Local builds only, no remote deployment
  - No git remote
  - Workflow: /build-local

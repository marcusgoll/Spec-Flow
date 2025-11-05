# Update Project Configuration

**Command**: `/update-project-config`

**Purpose**: Update project-specific configuration settings (deployment model, scale tier, quick changes policy).

**When to use**: When changing deployment model, adjusting scale tier, or updating project-level configuration.

**Workflow position**: Project setup command (updates user's project configuration)

---

## MENTAL MODEL

You are updating **project configuration** - user-editable settings that control workflow behavior.

**Philosophy**: Project configuration is auto-detected but can be overridden by users. This command helps users customize workflow behavior for their project.

---

## EXECUTION

### Check Project Documentation

**Verify project documentation exists:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "UPDATE PROJECT CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CONFIG_FILE="docs/project/project-configuration.md"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Project configuration not found: $CONFIG_FILE"
  echo ""
  echo "Run /init-project first to create project documentation."
  exit 1
fi

echo "✅ Project configuration found"
echo ""
```

---

### Display Current Configuration

**Show current settings:**

```bash
echo "Current configuration:"
echo ""

# Extract current deployment model
DEPLOY_MODEL=$(grep -A1 "^\*\*Current\*\*:" "$CONFIG_FILE" | grep -v "Current" | sed 's/.*`//' | sed 's/`.*//' || echo "Not set")

echo "  Deployment Model: $DEPLOY_MODEL"

# Extract scale tier from capacity-planning.md if it exists
if [ -f "docs/project/capacity-planning.md" ]; then
  SCALE=$(grep -A1 "Scale Tier" "docs/project/capacity-planning.md" | tail -1 || echo "Not set")
  echo "  Scale Tier: $SCALE"
fi

echo ""
```

---

### Parse Arguments

**Get configuration change from arguments:**

```bash
if [ -z "$ARGUMENTS" ]; then
  echo "Usage: /update-project-config [changes description]"
  echo ""
  echo "Examples:"
  echo "  /update-project-config Set deployment model to staging-prod"
  echo "  /update-project-config Change to direct-prod model"
  echo "  /update-project-config Enable quick changes for all bug fixes"
  echo ""
  exit 1
fi

CHANGE_DESCRIPTION="$ARGUMENTS"

echo "Configuration change requested:"
echo "  $CHANGE_DESCRIPTION"
echo ""
```

---

### Interactive Update

**Guide user through configuration update:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONFIGURATION UPDATE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect if user wants to change deployment model
if [[ "$CHANGE_DESCRIPTION" =~ deploy|staging|production|local ]]; then
  echo "Deployment model change detected."
  echo ""
  echo "Select new deployment model:"
  echo "  1. staging-prod - Full staging validation before production (recommended)"
  echo "  2. direct-prod - Direct production deployment without staging"
  echo "  3. local-only - Local builds only, no remote deployment"
  echo ""
  read -p "Choice (1-3): " DEPLOY_CHOICE

  case "$DEPLOY_CHOICE" in
    1) NEW_DEPLOY_MODEL="staging-prod" ;;
    2) NEW_DEPLOY_MODEL="direct-prod" ;;
    3) NEW_DEPLOY_MODEL="local-only" ;;
    *)
      echo "❌ Invalid choice"
      exit 1
      ;;
  esac

  echo ""
  echo "Updating deployment model to: $NEW_DEPLOY_MODEL"
  echo ""

  # Update the file
  # Claude Code: Edit docs/project/project-configuration.md
  # Find the line: **Current**: [DEPLOY_MODEL]
  # Replace with: **Current**: $NEW_DEPLOY_MODEL
fi

# Open file for manual editing if needed
echo "Opening configuration file for editing..."
echo ""

if command -v code &> /dev/null; then
  code --wait "$CONFIG_FILE"
else
  echo "Edit manually: $CONFIG_FILE"
  read -p "Press Enter when done..."
fi

echo ""
echo "✅ Configuration updated"
echo ""
```

---

### Update Metadata

**Update last modified date:**

```bash
TODAY=$(date +%Y-%m-%d)

# Claude Code: Edit docs/project/project-configuration.md
# Update the "Last Updated" line with today's date

echo "✅ Metadata updated: $TODAY"
echo ""
```

---

### Summary

**Display changes and next steps:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONFIGURATION UPDATE COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Updated: $CONFIG_FILE"
echo "Change: $CHANGE_DESCRIPTION"
echo ""

echo "### 💾 Next Steps"
echo ""
echo "1. Review changes: cat $CONFIG_FILE"
echo "2. Commit changes: git add $CONFIG_FILE && git commit -m \"config: $CHANGE_DESCRIPTION\""
echo "3. Future features will use updated configuration"
echo ""
```

---

## NOTES

**Configuration vs Principles:**
- `project-configuration.md` - Deployment model, scale tier (this command)
- `engineering-principles.md` - 8 core engineering standards (different file)

**Auto-Detection**: Deployment model is auto-detected on first `/feature` run, but can be overridden here.

**Scale Tier**: Set in `capacity-planning.md`, referenced here for convenience.

**Quick Changes**: Policy for when to use `/quick` vs `/feature` workflow.

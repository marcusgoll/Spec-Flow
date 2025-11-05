# Constitution: Update Engineering Principles

**Command**: `/constitution`

**Purpose**: Update project engineering principles (the 8 core standards that govern feature development).

**When to use**: When evolving engineering standards, adding/removing principles, or clarifying quality requirements.

**Workflow position**: Project setup command (updates engineering standards)

---

## MENTAL MODEL

You are updating **engineering principles** - the 8 core standards that all features must follow.

**Philosophy**: Engineering principles are your team's quality standards. They evolve with the project as you learn what works.

---

## EXECUTION

### Check Project Documentation

**Verify engineering principles file exists:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "UPDATE ENGINEERING PRINCIPLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PRINCIPLES_FILE="docs/project/engineering-principles.md"

if [ ! -f "$PRINCIPLES_FILE" ]; then
  echo "❌ Engineering principles not found: $PRINCIPLES_FILE"
  echo ""
  echo "Run /init-project first to create project documentation."
  exit 1
fi

echo "✅ Engineering principles found"
echo ""
```

---

### Parse Arguments

**Get change description from arguments:**

```bash
if [ -z "$ARGUMENTS" ]; then
  echo "Usage: /constitution [changes description]"
  echo ""
  echo "Examples:"
  echo "  /constitution Add principle: Always use TypeScript"
  echo "  /constitution Update test coverage requirement to 85%"
  echo "  /constitution Remove outdated performance threshold"
  echo ""
  exit 1
fi

CHANGE_DESCRIPTION="$ARGUMENTS"

echo "Engineering principles change requested:"
echo "  $CHANGE_DESCRIPTION"
echo ""
```

---

### Interactive Update

**Open file for editing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "EDITING ENGINEERING PRINCIPLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Change: $CHANGE_DESCRIPTION"
echo ""
echo "Opening principles file for editing..."
echo ""

# Open in editor
if command -v code &> /dev/null; then
  code --wait "$PRINCIPLES_FILE"
else
  echo "Edit manually: $PRINCIPLES_FILE"
  read -p "Press Enter when done..."
fi

echo ""
echo "✅ Principles updated"
echo ""
```

---

### Update Metadata

**Update version and date:**

```bash
TODAY=$(date +%Y-%m-%d)

# Claude Code: Edit docs/project/engineering-principles.md
# Update the "Last Updated" line with today's date
# Optionally bump version if this is a major change

echo "✅ Metadata updated: $TODAY"
echo ""
```

---

### Summary

**Display changes and next steps:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ENGINEERING PRINCIPLES UPDATE COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Updated: $PRINCIPLES_FILE"
echo "Change: $CHANGE_DESCRIPTION"
echo ""

echo "### 💾 Next Steps"
echo ""
echo "1. Review changes: cat $PRINCIPLES_FILE"
echo "2. Commit changes: git add $PRINCIPLES_FILE && git commit -m \"docs: $CHANGE_DESCRIPTION\""
echo "3. Future features will follow updated principles"
echo ""
```

---

## NOTES

**The 8 Core Principles:**
1. Specification First
2. Testing Standards
3. Performance Requirements
4. Accessibility (a11y)
5. Security Practices
6. Code Quality
7. Documentation Standards
8. Do Not Overengineer

**Principles vs Configuration:**
- `engineering-principles.md` - Quality standards (this command)
- `project-configuration.md` - Deployment model, scale tier (`/update-project-config`)

**Principles Guide Quality Gates:**
- `/optimize` enforces these principles
- `/validate` checks violations
- Code review uses these as criteria


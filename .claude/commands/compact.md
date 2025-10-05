---
description: Compact feature context to reduce token usage
---

Compact context for: ${ARGUMENTS:-current feature}

## MENTAL MODEL

**Purpose**: Reduce token usage by summarizing verbose artifacts while preserving critical information

**When to use**:
- After `/plan` - Before generating tasks
- After `/implement` - Before optimization
- When context feels heavy or you're approaching token limits
- As an optional optimization step between any phases

**What it preserves**:
- Architecture decisions and rationale
- Error logs and lessons learned
- Recent task checkpoints
- Code review findings (in optimization phase)

**What it compacts**:
- Verbose research notes → headings only
- Detailed task descriptions → summary
- Redundant discussion → key decisions

## DETECT FEATURE DIRECTORY

Auto-detect most recent feature:

```bash
# Find most recent feature directory
FEATURE_DIR=$(find specs -maxdepth 1 -type d -name "[0-9]*-*" 2>/dev/null | sort -n | tail -1)

if [ -z "$FEATURE_DIR" ]; then
  echo " Error: No feature directory found in specs/"
  echo ""
  echo "Create a feature first:"
  echo "  /spec-flow \"your feature name\""
  exit 1
fi

echo " Feature: $FEATURE_DIR"
```

## DETERMINE PHASE

Parse phase from arguments or auto-detect:

```bash
# Extract phase from arguments (if provided)
PHASE_ARG="$ARGUMENTS"

if [ -n "$PHASE_ARG" ]; then
  # User specified phase
  case "$PHASE_ARG" in
    planning|plan)
      PHASE="planning"
      ;;
    implementation|implement|impl)
      PHASE="implementation"
      ;;
    optimization|optimize|opt)
      PHASE="optimization"
      ;;
    *)
      echo " Invalid phase: $PHASE_ARG"
      echo ""
      echo "Valid phases: planning | implementation | optimization"
      echo "Or omit to auto-detect from NOTES.md"
      exit 1
      ;;
  esac
else
  # Auto-detect from NOTES.md (script will determine)
  PHASE="auto"
fi

echo " Phase: $PHASE"
```

## RUN COMPACTION

Execute platform-specific script:

```bash
# Determine platform and run appropriate script
# Windows: Use PowerShell
# macOS/Linux: Use Bash

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
  # Windows
  SCRIPT=".spec-flow/scripts/powershell/compact-context.ps1"

  echo ""
  echo "Compacting context..."
  echo ""

  pwsh -NoProfile -File "$SCRIPT" -FeatureDir "$FEATURE_DIR" -Phase "$PHASE"

else
  # macOS/Linux
  SCRIPT=".spec-flow/scripts/bash/compact-context.sh"

  # Make executable if needed
  chmod +x "$SCRIPT" 2>/dev/null || true

  echo ""
  echo "Compacting context..."
  echo ""

  "$SCRIPT" --feature-dir "$FEATURE_DIR" --phase "$PHASE"
fi
```

## RETURN

Show summary and next steps:

```bash
echo ""
echo " Compaction complete"
echo ""
echo "Output: $FEATURE_DIR/context-delta.md"
echo ""
echo "What was compacted:"
echo "  Research notes → headings only"
echo "  Task descriptions → checkpoints"
echo "  Preserved: Decisions, architecture, errors"
echo ""
echo "Next: Continue with your workflow"
echo "  • /tasks (if after /plan)"
echo "  • /optimize (if after /implement)"
echo "  • /flow continue (if in automated workflow)"
```

## USAGE EXAMPLES

### Example 1: Auto-detect phase
```bash
/compact

# Output:
#  Feature: specs/015-student-dashboard
#  Phase: auto (detected: planning)
#
# Compacting context...
# Before: 68,234 tokens
# After: 12,456 tokens (81.7% reduction)
#
#  Compaction complete
```

### Example 2: Specify phase
```bash
/compact planning

# Output:
#  Feature: specs/015-student-dashboard
#  Phase: planning
#
# Compacting context...
# Before: 68,234 tokens
# After: 12,456 tokens (81.7% reduction, aggressive strategy)
```

### Example 3: Different phases
```bash
# After /plan - aggressive compaction (90% reduction)
/compact planning

# After /implement - moderate compaction (60% reduction, keep 20 checkpoints)
/compact implementation

# After /optimize - minimal compaction (30% reduction, preserve code review)
/compact optimization
```

## CONSTRAINTS

- Requires existing feature directory in specs/
- Creates context-delta.md (backup of compacted content)
- Modifies: NOTES.md, research.md, plan.md, tasks.md
- Irreversible (but saves backup to context-delta.md)

## ERROR HANDLING

### No feature directory
```
 Error: No feature directory found in specs/

Create a feature first:
  /spec-flow "your feature name"
```

### Invalid phase argument
```
 Invalid phase: wrong-phase

Valid phases: planning | implementation | optimization
Or omit to auto-detect from NOTES.md
```

## TIPS

- **Planning phase**: Most aggressive compaction (90%), use after /plan
- **Implementation phase**: Moderate compaction (60%), preserves last 20 task checkpoints
- **Optimization phase**: Minimal compaction (30%), preserves full code review
- **When in doubt**: Omit phase argument to auto-detect from workflow state
- **Safety**: Backup is always saved to context-delta.md


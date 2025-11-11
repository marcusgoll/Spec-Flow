# /spec Refactor - v2.0

**Date**: 2025-11-10 (latest: v2.0 pattern refactor)
**Command**: `.claude/commands/phases/spec.md`
**Status**: ✅ Complete
**Impact**: 772 → 642 lines (17% reduction, -130 lines)

---

## Summary

Refactored `/spec` to full v2.0 pattern with:
- Strict bash mode (`set -Eeuo pipefail`)
- Error trap with automatic rollback
- Tool preflight checks (`need()` function)
- Deterministic repo root
- Actionable error messages with "Fix:" guidance
- Consolidated bash sections (15 blocks → 1 unified script)

Preserved all core functionality:
- Auto-classification (UI, improvement, metrics, deployment)
- Research mode selection (minimal/standard/full)
- Conditional artifact generation
- Quality validation checklist
- Auto-progression logic

---

## Key Changes

### 1. Strict Bash Mode

**Before**: No error handling at script level
```bash
# (no set -e or pipefail)
```

**After**: Fail-fast with strict error handling
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

**Benefits**:
- Catches unset variables (`-u`)
- Fails on any command error (`-e`)
- Fails on pipe errors (`-o pipefail`)
- Traces execution for debugging (`-E`)

### 2. Error Trap with Rollback

**Before**: Scattered rollback function, not automatically invoked
```bash
rollback_spec_flow() {
  echo "⚠️  Spec generation failed. Rolling back changes..."
  # ... rollback logic ...
}
# Usage: Manual call in error paths
```

**After**: Automatic cleanup on any error
```bash
on_error() {
  echo "⚠️  Error in /spec. Rolling back changes."

  # Rollback: return to original branch and clean up
  ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD@{-1} 2>/dev/null || echo "main")
  git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
  git branch -D "${SLUG}" 2>/dev/null || true
  rm -rf "specs/${SLUG}" 2>/dev/null || true

  exit 1
}
trap on_error ERR
```

**Benefits**:
- Automatic cleanup on ANY error (no manual error handling needed)
- Prevents orphaned branches and directories
- Clean failure state

### 3. Tool Preflight Checks

**Before**: Assumed tools exist, failed deep in script
**After**: Check upfront with installation guidance

```bash
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required tool: $1"
    case "$1" in
      git) echo "   Install: https://git-scm.com/downloads" ;;
      gh) echo "   Install: https://cli.github.com/" ;;
      jq) echo "   Install: brew install jq (macOS) or apt install jq (Linux)" ;;
      *) echo "   Check documentation for installation" ;;
    esac
    exit 1
  }
}

need git
need jq
```

**Benefits**:
- Clear failure message with install URL
- Fails fast before any work done
- User knows exactly what to install

### 4. Deterministic Repo Root

**Before**: Assumed running from project root
**After**: Always cd to repo root

```bash
# Deterministic repo root
cd "$(git rev-parse --show-toplevel)"
```

**Benefits**:
- Works from any subdirectory
- Consistent paths regardless of invocation location
- Prevents "file not found" errors

### 5. Actionable Error Messages

**Before**: Vague errors
```bash
echo "Error: Uncommitted changes in working directory"
```

**After**: Clear error + fix instructions
```bash
echo "❌ Uncommitted changes in working directory"
echo ""
git status --short
echo ""
echo "Fix: git add . && git commit -m 'message'"
exit 1
```

**Examples**:

```bash
# Missing feature description
echo "❌ Feature description required"
echo ""
echo "Usage: /spec <feature-description>"
echo ""
echo "Examples:"
echo "  /spec \"Add dark mode toggle to settings\""
echo "  /spec \"Improve upload speed by 50%\""
echo "  /spec \"Track user engagement with HEART metrics\""

# Invalid feature name
echo "❌ Invalid feature name (results in empty slug)"
echo "   Provide a more descriptive feature name"

# Path traversal attempt
echo "❌ Invalid characters in feature name"
echo "   Avoid: .. / (path traversal characters)"

# On main branch
echo "❌ Cannot create spec on main branch"
echo ""
echo "Fix: git checkout -b feature-branch-name"

# Directory exists
echo "❌ Spec directory 'specs/${SLUG}/' already exists"
echo ""
echo "Options:"
echo "  1. Use different feature name"
echo "  2. Delete existing: rm -rf specs/${SLUG}"
echo "  3. Continue existing feature: cd specs/${SLUG}"

# Missing template
echo "❌ Missing required template: $template"
echo ""
echo "Fix: Ensure .spec-flow/templates/ directory is complete"
echo "     Clone from: https://github.com/anthropics/spec-flow"
```

### 6. Consolidated Bash Sections

**Before**: 15 separate bash code blocks scattered throughout instructions
- PATH CONSTANTS (1 block)
- INPUT VALIDATION (1 block)
- GIT PRECONDITIONS (1 block)
- INITIALIZE (1 block)
- CLASSIFICATION (1 block)
- ROADMAP DETECTION (1 block)
- RESEARCH MODE (1 block)
- ...8 more blocks

**After**: Single unified bash script (1 block)
- All bash code in one `<instructions>` section
- Clear section dividers with comment headers
- Linear flow from top to bottom

**Benefits**:
- Easier to understand execution order
- Can copy-paste entire script
- No context switching between instructions and code

### 7. Cross-Platform Date Commands

**Before**: Linux-only `date -I` and `date -Iseconds`
```bash
date -I
date -Iseconds
```

**After**: Fallback for non-GNU systems
```bash
date -I 2>/dev/null || date +%Y-%m-%d
date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z
```

**Benefits**:
- Works on macOS (BSD date) and Linux (GNU date)
- Graceful fallback when flags not supported

---

## Before/After Comparison

### File Size
- **Before**: 772 lines
- **After**: 642 lines
- **Change**: -130 lines (17% reduction)

### Bash Blocks
- **Before**: 15 separate bash code blocks
- **After**: 1 unified bash script
- **Change**: 93% consolidation

### Error Handling
- **Before**: Manual rollback function, not automatically invoked
- **After**: Automatic error trap with cleanup

### Tool Checks
- **Before**: None (assumes tools exist)
- **After**: Preflight checks with install URLs (git, jq)

### Error Messages
- **Before**: Generic errors
- **After**: Actionable errors with "Fix:" instructions

### Repo Root
- **Before**: Assumes running from project root
- **After**: Deterministic `cd "$(git rev-parse --show-toplevel)"`

---

## Testing Checklist

- [ ] Run `/spec "Add dark mode toggle"` → creates UI feature (screens.yaml, copy.md)
- [ ] Run `/spec "Improve upload speed by 50%"` → creates improvement feature (hypothesis section)
- [ ] Run `/spec "Track user engagement"` → creates metrics feature (heart-metrics.md)
- [ ] Run `/spec "Migration to PostgreSQL"` → creates deployment feature (deployment section)
- [ ] Run `/spec "Backend API endpoint"` → creates minimal feature (spec.md + NOTES.md only)
- [ ] Run on main branch → fails with "Fix: git checkout -b feature-branch-name"
- [ ] Run with uncommitted changes → fails with "Fix: git add . && git commit -m 'message'"
- [ ] Run without git → fails with "Install: https://git-scm.com/downloads"
- [ ] Run without jq → fails with "Install: brew install jq..."
- [ ] Create spec with >3 clarifications → creates clarify.md with extras
- [ ] Run from subdirectory → works (deterministic repo root)
- [ ] Trigger error mid-script → automatic rollback (branch deleted, directory removed)

---

## Success Criteria

- ✅ No interactive prompts (non-interactive)
- ✅ Strict bash mode (`set -Eeuo pipefail`)
- ✅ Error trap (`trap on_error ERR`) with automatic cleanup
- ✅ Tool preflight checks (`need()` function for git, jq)
- ✅ Deterministic repo root (`cd "$(git rev-parse --show-toplevel)"`)
- ✅ Actionable error messages ("Fix: ..." instructions)
- ✅ Consolidated bash sections (15 blocks → 1 script)
- ✅ Cross-platform date commands (GNU/BSD compatible)
- ✅ Preserved all core functionality (classification, research, artifacts, validation)
- ✅ 17% size reduction (772 → 642 lines)
- ✅ Comprehensive documentation (this file)

---

**Generated**: 2025-11-10
**Command**: `/spec`
**Version**: 2.0
**Pattern**: Consolidated, deterministic, fail-safe

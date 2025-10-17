#!/bin/bash
# migrate-task-status.sh - Sync task status from tasks.md to NOTES.md for existing features
#
# Purpose: Migration utility for existing Spec-Flow features that may have
#          manual NOTES.md updates. Ensures tasks.md and NOTES.md are in sync.
#
# Usage:
#   ./migrate-task-status.sh              # Interactive mode
#   ./migrate-task-status.sh --dry-run    # Preview changes without applying
#   ./migrate-task-status.sh --all        # Auto-sync all features
#
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
DRY_RUN=false
AUTO_SYNC=false

for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --all)
      AUTO_SYNC=true
      shift
      ;;
    *)
      ;;
  esac
done

# Find all feature directories
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Spec-Flow Task Status Migration Utility${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
  echo ""
fi

SPECS_DIR="specs"
TASK_TRACKER=".spec-flow/scripts/powershell/task-tracker.ps1"

if [ ! -d "$SPECS_DIR" ]; then
  echo -e "${RED}❌ Error: specs/ directory not found${NC}"
  echo "   Run this script from the project root"
  exit 1
fi

if [ ! -f "$TASK_TRACKER" ]; then
  echo -e "${RED}❌ Error: task-tracker not found at $TASK_TRACKER${NC}"
  exit 1
fi

# Count feature directories
mapfile -t FEATURE_DIRS < <(find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
TOTAL_FEATURES=${#FEATURE_DIRS[@]}

if [ "$TOTAL_FEATURES" -eq 0 ]; then
  echo -e "${YELLOW}⚠️  No feature directories found in $SPECS_DIR/${NC}"
  exit 0
fi

echo "Found $TOTAL_FEATURES feature(s) in $SPECS_DIR/"
echo ""

# Process each feature
SYNCED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

for feature_dir in "${FEATURE_DIRS[@]}"; do
  FEATURE_NAME=$(basename "$feature_dir")
  TASKS_FILE="$feature_dir/tasks.md"

  echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
  echo "Feature: $FEATURE_NAME"

  # Skip if no tasks.md
  if [ ! -f "$TASKS_FILE" ]; then
    echo -e "${YELLOW}  ⊘ No tasks.md - skipping${NC}"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    echo ""
    continue
  fi

  # Run sync-status via task-tracker
  if [ "$DRY_RUN" = true ]; then
    # Just check status without syncing
    SYNC_RESULT=$(pwsh -File "$TASK_TRACKER" sync-status \
      -FeatureDir "$feature_dir" -Json 2>/dev/null || echo '{"Success":false}')

    SUCCESS=$(echo "$SYNC_RESULT" | jq -r '.Success' 2>/dev/null || echo "false")
    SYNCED=$(echo "$SYNC_RESULT" | jq -r '.SyncedCount' 2>/dev/null || echo "0")

    if [ "$SUCCESS" = "true" ]; then
      if [ "$SYNCED" -gt 0 ]; then
        echo -e "${GREEN}  ✓ Would sync $SYNCED task(s)${NC}"
        echo "    $(echo "$SYNC_RESULT" | jq -r '.SyncedTasks | join(", ")' 2>/dev/null)"
      else
        echo -e "  ✓ Already in sync"
      fi
    else
      echo -e "${RED}  ✗ Error during sync check${NC}"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  else
    # Actually perform sync
    if [ "$AUTO_SYNC" = false ]; then
      # Interactive mode - ask user
      echo "  Sync task status? (y/n): "
      read -r RESPONSE
      if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  ⊘ Skipped by user${NC}"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        echo ""
        continue
      fi
    fi

    # Perform sync
    SYNC_RESULT=$(pwsh -File "$TASK_TRACKER" sync-status \
      -FeatureDir "$feature_dir" -Json 2>/dev/null || echo '{"Success":false}')

    SUCCESS=$(echo "$SYNC_RESULT" | jq -r '.Success' 2>/dev/null || echo "false")
    SYNCED=$(echo "$SYNC_RESULT" | jq -r '.SyncedCount' 2>/dev/null || echo "0")

    if [ "$SUCCESS" = "true" ]; then
      if [ "$SYNCED" -gt 0 ]; then
        echo -e "${GREEN}  ✓ Synced $SYNCED task(s)${NC}"
        echo "    $(echo "$SYNC_RESULT" | jq -r '.SyncedTasks | join(", ")' 2>/dev/null)"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
      else
        echo -e "  ✓ Already in sync"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
      fi
    else
      echo -e "${RED}  ✗ Error during sync${NC}"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  fi

  echo ""
done

# Summary
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo "Migration Summary"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Total features scanned: $TOTAL_FEATURES"
if [ "$DRY_RUN" = false ]; then
  echo -e "${GREEN}Features synced: $SYNCED_COUNT${NC}"
fi
echo "Features skipped: $SKIPPED_COUNT"
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}Errors encountered: $ERROR_COUNT${NC}"
fi
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "To apply these changes, run without --dry-run:"
  echo "  ./migrate-task-status.sh --all"
elif [ "$SYNCED_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Migration complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Review synced NOTES.md files"
  echo "  2. Commit changes: git add specs/*/NOTES.md && git commit"
  echo "  3. Future tasks will use task-tracker automatically"
else
  echo "All features already in sync - no changes needed"
fi

echo ""

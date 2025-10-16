#!/bin/bash

# migrate-state-to-yaml.sh - Migrate workflow-state.json files to YAML format
#
# This utility script migrates all existing workflow-state.json files in the
# specs/ directory to the new YAML format (workflow-state.yaml).
#
# Features:
# - Batch conversion of all features
# - Preserves original JSON files as backups
# - Validates YAML output
# - Reports progress and errors
# - Dry-run mode for testing
#
# Usage:
#   ./migrate-state-to-yaml.sh [options]
#
# Options:
#   --dry-run        Show what would be migrated without making changes
#   --force          Overwrite existing YAML files
#   --backup-dir     Specify backup directory (default: .spec-flow/backups)
#   --help           Show this help message
#
# Version: 1.0.0
# Requires: yq >= 4.0

set -e

# Default options
DRY_RUN=false
FORCE=false
BACKUP_DIR=".spec-flow/backups/json-migration-$(date +%Y%m%d-%H%M%S)"
SPECS_DIR="specs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --backup-dir)
      BACKUP_DIR="$2"
      shift 2
      ;;
    --help)
      grep "^#" "$0" | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check for yq
if ! command -v yq &> /dev/null; then
  echo -e "${RED}Error: yq is required for migration${NC}" >&2
  echo "Install instructions:" >&2
  echo "  macOS: brew install yq" >&2
  echo "  Linux: https://github.com/mikefarah/yq#install" >&2
  echo "  Windows: choco install yq" >&2
  exit 1
fi

# Check yq version
YQ_VERSION=$(yq --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
YQ_MAJOR=$(echo "$YQ_VERSION" | cut -d. -f1)

if [ "$YQ_MAJOR" -lt 4 ]; then
  echo -e "${RED}Error: yq version 4.0 or higher required (found: $YQ_VERSION)${NC}" >&2
  exit 1
fi

# Print banner
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Workflow State Migration: JSON → YAML${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be modified${NC}"
  echo ""
fi

# Find all workflow-state.json files
echo -e "${BLUE}🔎 Scanning for workflow-state.json files...${NC}"
echo ""

JSON_FILES=()
while IFS= read -r -d '' file; do
  JSON_FILES+=("$file")
done < <(find "$SPECS_DIR" -name "workflow-state.json" -type f -print0 2>/dev/null)

if [ ${#JSON_FILES[@]} -eq 0 ]; then
  echo -e "${YELLOW}✓ No JSON files found to migrate${NC}"
  echo ""
  echo "All features are already using YAML format or no features exist yet."
  exit 0
fi

echo -e "${GREEN}Found ${#JSON_FILES[@]} file(s) to migrate${NC}"
echo ""

# Statistics
MIGRATED=0
SKIPPED=0
FAILED=0

# Create backup directory
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$BACKUP_DIR"
  echo -e "${BLUE}📁 Backup directory: $BACKUP_DIR${NC}"
  echo ""
fi

# Migrate each file
for json_file in "${JSON_FILES[@]}"; do
  feature_dir=$(dirname "$json_file")
  yaml_file="$feature_dir/workflow-state.yaml"

  # Extract feature slug
  slug=$(basename "$feature_dir")

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Feature: $slug${NC}"
  echo ""
  echo "  Source: $json_file"
  echo "  Target: $yaml_file"

  # Check if YAML already exists
  if [ -f "$yaml_file" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}⏭️  SKIPPED - YAML file already exists (use --force to overwrite)${NC}"
    echo ""
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${GREEN}✓ Would migrate${NC}"
    echo ""
    MIGRATED=$((MIGRATED + 1))
    continue
  fi

  # Perform migration
  if yq eval -P "$json_file" > "$yaml_file" 2>/dev/null; then
    # Validate YAML
    if yq eval '.' "$yaml_file" >/dev/null 2>&1; then
      # Copy JSON to backup
      backup_file="$BACKUP_DIR/$slug-workflow-state.json"
      cp "$json_file" "$backup_file"

      echo -e "  ${GREEN}✅ MIGRATED${NC}"
      echo "  Backup: $backup_file"
      echo ""

      MIGRATED=$((MIGRATED + 1))
    else
      # Validation failed, remove invalid YAML
      rm -f "$yaml_file"
      echo -e "  ${RED}❌ FAILED - Invalid YAML generated${NC}"
      echo ""
      FAILED=$((FAILED + 1))
    fi
  else
    echo -e "  ${RED}❌ FAILED - Conversion error${NC}"
    echo ""
    FAILED=$((FAILED + 1))
  fi
done

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Migration Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Migrated: $MIGRATED${NC}"
echo -e "${YELLOW}⏭️  Skipped:  $SKIPPED${NC}"
echo -e "${RED}❌ Failed:   $FAILED${NC}"
echo ""

if [ "$DRY_RUN" = false ] && [ $MIGRATED -gt 0 ]; then
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✓ Migration complete!${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Original JSON files have been preserved in:"
  echo "  $BACKUP_DIR"
  echo ""
  echo "You can safely delete them after verifying the YAML files work correctly."
  echo ""
  echo "To verify, run your workflow commands and check that state is read/written correctly."
fi

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}Dry run complete - no changes made${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Run without --dry-run to perform actual migration."
fi

echo ""

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
  exit 1
fi

exit 0

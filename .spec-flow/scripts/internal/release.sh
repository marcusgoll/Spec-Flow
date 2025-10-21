#!/usr/bin/env bash
#
# Internal Release Script
# DO NOT SHIP: This is for workflow development only
#
# Usage:
#   bash .spec-flow/scripts/internal/release.sh [patch|minor|major] [--dry-run] [--skip-npm]
#
# Examples:
#   bash .spec-flow/scripts/internal/release.sh patch
#   bash .spec-flow/scripts/internal/release.sh minor --dry-run
#   bash .spec-flow/scripts/internal/release.sh major --skip-npm

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUMP_TYPE="${1:-patch}"
DRY_RUN=false
SKIP_NPM=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-npm)
      SKIP_NPM=true
      shift
      ;;
  esac
done

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
  echo -e "${RED}Error: Invalid bump type '$BUMP_TYPE'. Use: patch, minor, or major${NC}"
  exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Spec-Flow Workflow Release Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Bump type: ${GREEN}$BUMP_TYPE${NC}"
echo -e "Dry run:   ${GREEN}$DRY_RUN${NC}"
echo -e "Skip npm:  ${GREEN}$SKIP_NPM${NC}"
echo ""

# Step 1: Verify clean working tree
echo -e "${BLUE}[1/9]${NC} Checking git working tree..."
if [[ -n $(git status --porcelain) ]]; then
  echo -e "${YELLOW}Warning: Working tree has uncommitted changes${NC}"
  echo ""
  git status --short
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted${NC}"
    exit 1
  fi
fi
echo -e "${GREEN}✓${NC} Working tree checked"

# Step 2: Get current version
echo -e "${BLUE}[2/9]${NC} Reading current version..."
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo -e "${GREEN}✓${NC} Current version: ${CURRENT_VERSION}"

# Step 3: Calculate new version
echo -e "${BLUE}[3/9]${NC} Calculating new version..."
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case $BUMP_TYPE in
  major)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
    ;;
  patch)
    NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
    ;;
esac

echo -e "${GREEN}✓${NC} New version: ${NEW_VERSION} (${CURRENT_VERSION} → ${NEW_VERSION})"

# Step 4: Update package.json
echo -e "${BLUE}[4/9]${NC} Updating package.json..."
if [ "$DRY_RUN" = false ]; then
  # Use node to update version (preserves JSON formatting)
  node -e "
    const fs = require('fs');
    const pkg = require('./package.json');
    pkg.version = '$NEW_VERSION';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
  "
  echo -e "${GREEN}✓${NC} package.json updated to ${NEW_VERSION}"
else
  echo -e "${YELLOW}[DRY RUN]${NC} Would update package.json to ${NEW_VERSION}"
fi

# Step 5: Update CHANGELOG.md
echo -e "${BLUE}[5/9]${NC} Updating CHANGELOG.md..."
RELEASE_DATE=$(date +"%Y-%m-%d")

if [ "$DRY_RUN" = false ]; then
  # Create changelog entry
  CHANGELOG_ENTRY="## [${NEW_VERSION}] - ${RELEASE_DATE}

### Changed
- Version bump to ${NEW_VERSION}

<!-- Add release notes here -->

"

  # Insert after first line (# Changelog)
  if [ -f "CHANGELOG.md" ]; then
    # Create temp file with new entry
    {
      head -n 1 CHANGELOG.md
      echo ""
      echo "$CHANGELOG_ENTRY"
      tail -n +2 CHANGELOG.md
    } > CHANGELOG.md.tmp
    mv CHANGELOG.md.tmp CHANGELOG.md
    echo -e "${GREEN}✓${NC} CHANGELOG.md updated"
  else
    echo -e "${YELLOW}Warning: CHANGELOG.md not found, creating new one${NC}"
    echo "# Changelog

$CHANGELOG_ENTRY" > CHANGELOG.md
    echo -e "${GREEN}✓${NC} CHANGELOG.md created"
  fi
else
  echo -e "${YELLOW}[DRY RUN]${NC} Would add entry to CHANGELOG.md for ${NEW_VERSION}"
fi

# Step 6: Update README.md (version badge if exists)
echo -e "${BLUE}[6/9]${NC} Checking README.md for version references..."
if [ -f "README.md" ]; then
  if grep -q "version-.*-blue" README.md; then
    if [ "$DRY_RUN" = false ]; then
      # Update version badge
      sed -i.bak "s/version-[0-9.]*-blue/version-${NEW_VERSION}-blue/" README.md
      rm -f README.md.bak
      echo -e "${GREEN}✓${NC} README.md version badge updated"
    else
      echo -e "${YELLOW}[DRY RUN]${NC} Would update README.md version badge"
    fi
  else
    echo -e "${YELLOW}ℹ${NC}  No version badge found in README.md"
  fi
else
  echo -e "${YELLOW}Warning: README.md not found${NC}"
fi

# Step 7: Git add and commit
echo -e "${BLUE}[7/9]${NC} Staging changes..."
if [ "$DRY_RUN" = false ]; then
  git add package.json CHANGELOG.md README.md 2>/dev/null || true

  # Create commit
  git commit -m "chore: release v${NEW_VERSION}

- Bump version to ${NEW_VERSION}
- Update CHANGELOG.md with release notes
- Update version references

Release: v${NEW_VERSION}
"
  echo -e "${GREEN}✓${NC} Changes committed"
else
  echo -e "${YELLOW}[DRY RUN]${NC} Would commit: package.json, CHANGELOG.md, README.md"
fi

# Step 8: Create git tag
echo -e "${BLUE}[8/9]${NC} Creating git tag..."
if [ "$DRY_RUN" = false ]; then
  git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}

$(grep -A 10 "\[${NEW_VERSION}\]" CHANGELOG.md | tail -n +3 | head -n -1 || echo "Release v${NEW_VERSION}")
"
  echo -e "${GREEN}✓${NC} Tag v${NEW_VERSION} created"
else
  echo -e "${YELLOW}[DRY RUN]${NC} Would create tag v${NEW_VERSION}"
fi

# Step 9: NPM package (optional)
echo -e "${BLUE}[9/9]${NC} NPM package..."
if [ "$SKIP_NPM" = true ]; then
  echo -e "${YELLOW}ℹ${NC}  Skipping npm publish (--skip-npm)"
elif [ "$DRY_RUN" = false ]; then
  echo ""
  echo -e "${YELLOW}Ready to publish to npm registry?${NC}"
  echo "  npm publish"
  echo ""
  read -p "Publish now? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm publish
    echo -e "${GREEN}✓${NC} Published to npm registry"
  else
    echo -e "${YELLOW}ℹ${NC}  Skipped npm publish"
    echo ""
    echo -e "${BLUE}To publish later, run:${NC}"
    echo "  npm publish"
  fi
else
  echo -e "${YELLOW}[DRY RUN]${NC} Would prompt for npm publish"
fi

# Summary
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Release Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Version:  ${GREEN}${CURRENT_VERSION} → ${NEW_VERSION}${NC}"
echo -e "Tag:      ${GREEN}v${NEW_VERSION}${NC}"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo -e "${BLUE}Next steps:${NC}"
  echo "  1. Review CHANGELOG.md and add detailed release notes"
  echo "  2. Push to remote:"
  echo "     git push origin main"
  echo "     git push origin v${NEW_VERSION}"
  if [ "$SKIP_NPM" = true ]; then
    echo "  3. Publish to npm:"
    echo "     npm publish"
  fi
else
  echo -e "${YELLOW}This was a dry run - no changes made${NC}"
  echo ""
  echo -e "${BLUE}To actually release, run:${NC}"
  echo "  bash .spec-flow/scripts/internal/release.sh $BUMP_TYPE"
fi

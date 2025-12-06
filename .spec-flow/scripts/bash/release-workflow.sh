#!/bin/bash

# release-workflow.sh - Automate project release process
# Usage: ./release-workflow.sh <version_type> [tag_name]
# version_type: patch, minor, major, or specific version (x.y.z)

set -e

VERSION_TYPE=$1
TAG_NAME=$2

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting Release Workflow${NC}"

# 1. Pre-flight Checks
echo "Checking environment..."

if [ -z "$VERSION_TYPE" ]; then
  echo -e "${RED}Error: Version type required (patch, minor, major)${NC}"
  exit 1
fi

# Check git status
if [[ -n $(git status --porcelain) ]]; then
  echo -e "${RED}Error: Git working directory not clean. Commit changes first.${NC}"
  exit 1
fi

# Check branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
  echo -e "${YELLOW}Warning: Not on main/master branch ($CURRENT_BRANCH). Continue? (y/n)${NC}"
  read -r response
  if [[ "$response" != "y" ]]; then exit 1; fi
fi

# Check gh cli
if ! command -v gh &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) not found.${NC}"
  exit 1
fi

# 2. Version Bump
echo "Bumping version ($VERSION_TYPE)..."
# Use npm version to update package.json and package-lock.json
# --no-git-tag-version because we want to commit multiple files later
NEW_VERSION=$(npm version "$VERSION_TYPE" --no-git-tag-version)
# npm version returns 'v1.2.3', strip 'v'
VERSION_NUM="${NEW_VERSION#v}"

echo -e "${GREEN}New version: $VERSION_NUM${NC}"

# 3. Generate Changelog
echo "Generating changelog..."
if npx --no-install conventional-changelog-cli --help > /dev/null 2>&1; then
  npx conventional-changelog-cli -p angular -i CHANGELOG.md -s
  echo -e "${GREEN}Changelog updated${NC}"
else
  echo -e "${YELLOW}conventional-changelog-cli not found. Skipping auto-changelog.${NC}"
  # Create placeholder if not exists
  touch CHANGELOG.md
fi

# 4. Update README (optional manual steps or regex)
# Example: Update version references in README if they exist
# sed -i "s/version: [0-9]\+\.[0-9]\+\.[0-9]\+/version: $VERSION_NUM/g" README.md || true

# 5. Commit Changes
echo "Committing changes..."
git add package.json package-lock.json CHANGELOG.md README.md
git commit -m "chore(release): $NEW_VERSION"

# 6. Tag
echo "Tagging release..."
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

# 7. Push
echo "Pushing to remote..."
git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"

# 8. Create GitHub Release
echo "Creating GitHub release..."
# Use gh to create release with auto-generated notes
gh release create "$NEW_VERSION" --generate-notes --verify-tag

# 9. Publish to NPM
echo "Publishing to npm..."
# Check for OTP requirement or dry-run
# npm publish --access public
echo -e "${YELLOW}Ready to publish to npm. Run 'npm publish' manually to verify first, or press 'y' to publish now.${NC}"
read -r response
if [[ "$response" == "y" ]]; then
  npm publish
  echo -e "${GREEN}Published to npm!${NC}"
else
  echo -e "${YELLOW}Skipped npm publish.${NC}"
fi

echo -e "${GREEN}✨ Release $NEW_VERSION completed successfully!${NC}"

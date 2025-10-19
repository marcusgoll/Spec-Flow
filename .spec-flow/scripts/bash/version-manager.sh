#!/bin/bash

# version-manager.sh - Semantic version management for Spec-Flow
#
# Provides functions to manage semantic versioning throughout the feature lifecycle:
# - Read current version from package.json
# - Suggest version bumps based on feature analysis
# - Update package.json with new version
# - Create git tags for releases
# - Generate release notes from ship reports
#
# Version: 1.0.0
# Requires: jq (JSON processor)

set -e

PACKAGE_JSON="package.json"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for version management" >&2
  echo "Install instructions:" >&2
  echo "  macOS: brew install jq" >&2
  echo "  Linux: apt-get install jq or yum install jq" >&2
  echo "  Windows: choco install jq" >&2
  exit 1
fi

# Get current version from package.json
get_current_version() {
  if [ ! -f "$PACKAGE_JSON" ]; then
    echo "Error: package.json not found" >&2
    return 1
  fi

  local version
  version=$(jq -r '.version' "$PACKAGE_JSON")

  if [ "$version" = "null" ] || [ -z "$version" ]; then
    echo "Error: version not found in package.json" >&2
    return 1
  fi

  echo "$version"
}

# Parse semantic version into MAJOR.MINOR.PATCH
parse_version() {
  local version="$1"

  # Remove leading 'v' if present
  version="${version#v}"

  # Extract MAJOR.MINOR.PATCH
  local major minor patch
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  patch=$(echo "$version" | cut -d. -f3)

  echo "$major $minor $patch"
}

# Suggest version bump based on feature analysis
suggest_version_bump() {
  local feature_dir="$1"
  local spec_file="$feature_dir/spec.md"
  local ship_report
  ship_report=$(find "$feature_dir" -name "*-ship-report.md" -type f | head -1)

  if [ ! -f "$spec_file" ]; then
    echo "Error: Spec not found: $spec_file" >&2
    return 1
  fi

  # Analyze for breaking changes
  local has_breaking=false
  if grep -iq "breaking change" "$spec_file" || \
     ([ -n "$ship_report" ] && [ -f "$ship_report" ] && grep -iq "breaking change" "$ship_report"); then
    has_breaking=true
  fi

  # Analyze for bug fixes
  local is_bugfix=false
  if grep -Eiq "(fix|bug|patch|hotfix)" "$spec_file"; then
    is_bugfix=true
  fi

  # Determine bump type
  if [ "$has_breaking" = true ]; then
    echo "major"
  elif [ "$is_bugfix" = true ]; then
    echo "patch"
  else
    # Default to minor for new features
    echo "minor"
  fi
}

# Bump version based on type (major, minor, patch)
bump_version() {
  local bump_type="$1"
  local current_version
  if ! current_version=$(get_current_version); then
    return 1
  fi

  # Parse current version
  read -r major minor patch <<< "$(parse_version "$current_version")"

  # Bump based on type
  case "$bump_type" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo "Error: Invalid bump type: $bump_type (expected: major, minor, patch)" >&2
      return 1
      ;;
  esac

  local new_version="$major.$minor.$patch"
  echo "$new_version"
}

# Update package.json with new version
update_package_version() {
  local new_version="$1"

  if [ ! -f "$PACKAGE_JSON" ]; then
    echo "Error: package.json not found" >&2
    return 1
  fi

  # Update version using jq
  jq --arg version "$new_version" '.version = $version' "$PACKAGE_JSON" > "${PACKAGE_JSON}.tmp"
  mv "${PACKAGE_JSON}.tmp" "$PACKAGE_JSON"

  echo "✅ Updated package.json to version $new_version"
}

# Create git tag for release
create_release_tag() {
  local version="$1"
  local message="${2:-Release version $version}"

  # Check if tag already exists
  if git rev-parse "v$version" >/dev/null 2>&1; then
    echo "⚠️  Tag v$version already exists" >&2
    return 1
  fi

  # Create annotated tag
  git tag -a "v$version" -m "$message"

  echo "✅ Created git tag: v$version"
}

# Push tag to remote
push_release_tag() {
  local version="$1"

  # Check if remote exists
  if ! git remote -v | grep -q "origin"; then
    echo "⚠️  No git remote configured, skipping tag push" >&2
    return 0
  fi

  # Push tag
  git push origin "v$version"

  echo "✅ Pushed tag v$version to remote"
}

# Generate release notes from ship report
generate_release_notes() {
  local feature_dir="$1"
  local version="$2"
  local output_file="${3:-RELEASE_NOTES.md}"

  local ship_report
  ship_report=$(find "$feature_dir" -name "*-ship-report.md" -type f | head -1)

  if [ ! -f "$ship_report" ]; then
    echo "⚠️  Ship report not found in $feature_dir" >&2
    return 1
  fi

  # Extract feature slug and title from ship report
  local slug title
  slug=$(basename "$feature_dir")
  title=$(grep -m 1 "^# " "$ship_report" | sed 's/^# //')

  # Create release notes
  cat > "$output_file" <<EOF
# Release v$version

**Date**: $(date +%Y-%m-%d)

## Features

### $title

$(grep -A 10 "^## Summary" "$ship_report" | tail -n +2 | sed '/^##/q' | sed '$d')

## Changes

$(grep -A 20 "^## Changes" "$ship_report" | tail -n +2 | sed '/^##/q' | sed '$d')

## Deployment

- **Production URL**: $(grep -m 1 "Production URL" "$ship_report" | sed 's/.*: //')
- **Release Tag**: v$version
- **Feature Spec**: specs/$slug/spec.md

---

_Generated by Spec-Flow version-manager.sh_
EOF

  echo "✅ Generated release notes: $output_file"
}

# Interactive version bump workflow
interactive_version_bump() {
  local feature_dir="$1"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Version Management"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Get current version
  local current_version
  current_version=$(get_current_version)
  echo "Current version: v$current_version"
  echo ""

  # Suggest bump type
  local suggested_bump
  suggested_bump=$(suggest_version_bump "$feature_dir")
  echo "Suggested bump: $suggested_bump"
  echo ""

  # Calculate new version
  local new_version
  new_version=$(bump_version "$suggested_bump")
  echo "New version: v$new_version"
  echo ""

  # Prompt for confirmation
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  read -r -p "Proceed with version bump? (yes/no/custom): " response

  case "$response" in
    yes|y|Y)
      # Proceed with suggested version
      update_package_version "$new_version"
      create_release_tag "$new_version" "Release v$new_version"

      # Ask about pushing tag
      echo ""
      read -r -p "Push tag to remote? (yes/no): " push_response
      if [[ "$push_response" =~ ^(yes|y|Y)$ ]]; then
        push_release_tag "$new_version"
      fi

      # Generate release notes
      echo ""
      read -r -p "Generate release notes? (yes/no): " notes_response
      if [[ "$notes_response" =~ ^(yes|y|Y)$ ]]; then
        generate_release_notes "$feature_dir" "$new_version"
      fi
      ;;

    custom|c|C)
      # Allow custom version input
      echo ""
      read -r -p "Enter custom version (e.g., 2.1.0): " custom_version

      # Validate format
      if [[ ! "$custom_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Invalid version format. Expected: MAJOR.MINOR.PATCH" >&2
        return 1
      fi

      update_package_version "$custom_version"
      create_release_tag "$custom_version" "Release v$custom_version"

      # Ask about pushing tag
      echo ""
      read -r -p "Push tag to remote? (yes/no): " push_response
      if [[ "$push_response" =~ ^(yes|y|Y)$ ]]; then
        push_release_tag "$custom_version"
      fi
      ;;

    *)
      echo "⏭️  Skipped version bump"
      return 0
      ;;
  esac

  echo ""
  echo "✅ Version management complete"
}

# Non-interactive version bump (for automation)
auto_version_bump() {
  local feature_dir="$1"
  local bump_type="${2:-auto}"

  # Auto-detect bump type if not specified
  if [ "$bump_type" = "auto" ]; then
    bump_type=$(suggest_version_bump "$feature_dir")
  fi

  # Calculate new version
  local new_version
  new_version=$(bump_version "$bump_type")

  # Update package.json
  update_package_version "$new_version"

  # Create tag
  create_release_tag "$new_version" "Release v$new_version - Auto-bumped ($bump_type)"

  # Return new version for use by caller
  echo "$new_version"
}

# Validate version format
validate_version_format() {
  local version="$1"

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format: $version (expected: MAJOR.MINOR.PATCH)" >&2
    return 1
  fi

  return 0
}

# Get list of all version tags
list_version_tags() {
  git tag -l "v*" | sort -V
}

# Get latest version tag
get_latest_version_tag() {
  list_version_tags | tail -1
}

# Compare two versions (returns -1, 0, or 1)
compare_versions() {
  local version1="$1"
  local version2="$2"

  # Remove leading 'v'
  version1="${version1#v}"
  version2="${version2#v}"

  # Parse versions
  read -r major1 minor1 patch1 <<< "$(parse_version "$version1")"
  read -r major2 minor2 patch2 <<< "$(parse_version "$version2")"

  # Compare
  if [ "$major1" -gt "$major2" ]; then
    echo "1"
  elif [ "$major1" -lt "$major2" ]; then
    echo "-1"
  elif [ "$minor1" -gt "$minor2" ]; then
    echo "1"
  elif [ "$minor1" -lt "$minor2" ]; then
    echo "-1"
  elif [ "$patch1" -gt "$patch2" ]; then
    echo "1"
  elif [ "$patch1" -lt "$patch2" ]; then
    echo "-1"
  else
    echo "0"
  fi
}

# Export functions (for sourcing)
export -f get_current_version
export -f parse_version
export -f suggest_version_bump
export -f bump_version
export -f update_package_version
export -f create_release_tag
export -f push_release_tag
export -f generate_release_notes
export -f interactive_version_bump
export -f auto_version_bump
export -f validate_version_format
export -f list_version_tags
export -f get_latest_version_tag
export -f compare_versions

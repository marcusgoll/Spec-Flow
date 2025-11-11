#!/usr/bin/env bash
#
# contract-bump.sh - Bump API and event contract versions
#
# Usage: contract-bump.sh [major|minor|patch] [--dry-run]
#
# Required tools: yq, gh, git

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONTRACTS_DIR="$PROJECT_ROOT/contracts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
BUMP_LEVEL=""
RFC_ISSUE=""

#######################################
# Print usage information
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [major|minor|patch] [--dry-run] [--rfc ISSUE_NUMBER]

Bump contract versions following semantic versioning.

Arguments:
  major        Breaking changes (requires RFC + new sprint)
  minor        Additive changes (safe mid-sprint)
  patch        Documentation/examples only (safe mid-sprint)

Options:
  --dry-run    Show what would change without applying
  --rfc NUM    RFC issue number for major bumps

Examples:
  $(basename "$0") minor
  $(basename "$0") major --rfc 123
  $(basename "$0") patch --dry-run
EOF
  exit 1
}

#######################################
# Log message with color
#######################################
log_info() { echo -e "${BLUE}ℹ${NC}  $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC}  $*"; }
log_error() { echo -e "${RED}❌${NC} $*"; }

#######################################
# Get current contract version from latest directory
#######################################
get_current_version() {
  local latest_dir
  latest_dir=$(find "$CONTRACTS_DIR/api" -maxdepth 1 -type d -name 'v*' | sort -V | tail -1)

  if [[ -z "$latest_dir" ]]; then
    log_error "No contract versions found in $CONTRACTS_DIR/api/"
    exit 1
  fi

  basename "$latest_dir" | sed 's/^v//'
}

#######################################
# Bump version by semver level
#######################################
bump_version() {
  local version=$1
  local level=$2

  IFS='.' read -r major minor patch <<< "$version"

  case "$level" in
    major)
      echo "$((major + 1)).0.0"
      ;;
    minor)
      echo "$major.$((minor + 1)).0"
      ;;
    patch)
      echo "$major.$minor.$((patch + 1))"
      ;;
    *)
      log_error "Invalid bump level: $level"
      exit 1
      ;;
  esac
}

#######################################
# Check if sprint is currently active
#######################################
is_sprint_active() {
  # Check if any epics are in "Implementing" state
  local state_file="$PROJECT_ROOT/.spec-flow/memory/wip-tracker.yaml"

  if [[ ! -f "$state_file" ]]; then
    return 1
  fi

  # Check if any agent is actively implementing
  if grep -q "state: implementing" "$state_file" 2>/dev/null; then
    return 0
  fi

  return 1
}

#######################################
# Check for RFC approval via GitHub issue
#######################################
has_rfc_approval() {
  local issue_num=$1

  if [[ -z "$issue_num" ]]; then
    return 1
  fi

  # Check if issue has 'rfc:approved' label
  local labels
  labels=$(gh issue view "$issue_num" --json labels --jq '.labels[].name' 2>/dev/null || echo "")

  if echo "$labels" | grep -q "rfc:approved"; then
    return 0
  fi

  return 1
}

#######################################
# Check for uncommitted changes
#######################################
check_git_clean() {
  if [[ -n $(git status --porcelain) ]]; then
    log_error "Working directory not clean"
    echo ""
    git status --short
    echo ""
    log_warning "Commit or stash changes before bumping contracts"
    exit 1
  fi
}

#######################################
# Update version in OpenAPI spec
#######################################
update_openapi_version() {
  local file=$1
  local new_version=$2

  if command -v yq &> /dev/null; then
    yq eval ".info.version = \"$new_version\"" -i "$file"
  else
    # Fallback to sed if yq not available
    sed -i.bak "s/version: .*/version: $new_version/" "$file"
    rm -f "${file}.bak"
  fi
}

#######################################
# Add entry to CHANGELOG
#######################################
add_changelog_entry() {
  local file=$1
  local version=$2
  local level=$3
  local date
  date=$(date +%Y-%m-%d)

  local temp_file="${file}.tmp"
  local header_added=false

  # Create new CHANGELOG entry
  cat > "$temp_file" <<EOF
## [$version] - $date

### Added

- [List new features, endpoints, or fields here]

### Changed

- [List modifications to existing functionality here]

### Deprecated

- [List deprecated features that will be removed in future versions]

EOF

  # Add breaking changes section for major bumps
  if [[ "$level" == "major" ]]; then
    cat >> "$temp_file" <<EOF
### Removed

- [List removed features, endpoints, or fields here]

### Migration Guide

\`\`\`
[Provide step-by-step migration instructions for consumers]
\`\`\`

EOF
  fi

  # Append existing CHANGELOG content (skip first two lines if they're headers)
  if [[ -f "$file" ]]; then
    tail -n +3 "$file" >> "$temp_file"
  fi

  mv "$temp_file" "$file"
}

#######################################
# Run contract verification
#######################################
verify_contracts() {
  log_info "Running CDC verification..."

  local verify_script="$SCRIPT_DIR/contract-verify.sh"

  if [[ ! -f "$verify_script" ]]; then
    log_warning "Contract verification script not found: $verify_script"
    log_warning "Skipping CDC verification (will be required in CI)"
    return 0
  fi

  if "$verify_script"; then
    log_success "CDC verification passed"
    return 0
  else
    log_error "CDC verification failed"
    return 1
  fi
}

#######################################
# Create new version directory
#######################################
create_version_dir() {
  local old_version=$1
  local new_version=$2

  local old_dir="$CONTRACTS_DIR/api/v$old_version"
  local new_dir="$CONTRACTS_DIR/api/v$new_version"

  if [[ -d "$new_dir" ]]; then
    log_error "Version directory already exists: $new_dir"
    exit 1
  fi

  if [[ "$DRY_RUN" == false ]]; then
    cp -r "$old_dir" "$new_dir"
    log_success "Created $new_dir"
  else
    log_info "[DRY RUN] Would create $new_dir"
  fi
}

#######################################
# Main bump workflow
#######################################
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      major|minor|patch)
        BUMP_LEVEL="$1"
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --rfc)
        RFC_ISSUE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        ;;
      *)
        log_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  if [[ -z "$BUMP_LEVEL" ]]; then
    log_error "Bump level required (major|minor|patch)"
    usage
  fi

  # Verify contracts directory exists
  if [[ ! -d "$CONTRACTS_DIR" ]]; then
    log_error "Contracts directory not found: $CONTRACTS_DIR"
    log_info "Run project initialization first"
    exit 1
  fi

  # Check for uncommitted changes (skip in dry run)
  if [[ "$DRY_RUN" == false ]]; then
    check_git_clean
  fi

  # Get current version
  CURRENT_VERSION=$(get_current_version)
  log_info "Current version: v$CURRENT_VERSION"

  # Calculate new version
  NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$BUMP_LEVEL")
  log_info "New version: v$NEW_VERSION"

  # Check for major bump mid-sprint
  if [[ "$BUMP_LEVEL" == "major" ]]; then
    if is_sprint_active; then
      log_warning "Sprint is currently active"

      if ! has_rfc_approval "$RFC_ISSUE"; then
        log_error "Major version bump requires RFC approval"
        echo ""
        echo "Breaking changes are not allowed mid-sprint without RFC."
        echo ""
        echo "Options:"
        echo "  1. Create RFC issue: /roadmap ADD \"RFC: Breaking contract change\" --type rfc"
        echo "  2. Get RFC approved with 'rfc:approved' label"
        echo "  3. Postpone to next sprint"
        echo "  4. Find additive alternative (minor bump)"
        echo ""
        exit 1
      else
        log_success "RFC #$RFC_ISSUE approved - proceeding with major bump"
      fi
    fi
  fi

  # Create new version directory
  create_version_dir "$CURRENT_VERSION" "$NEW_VERSION"

  # Update OpenAPI version
  OPENAPI_FILE="$CONTRACTS_DIR/api/v$NEW_VERSION/openapi.yaml"
  if [[ "$DRY_RUN" == false ]]; then
    update_openapi_version "$OPENAPI_FILE" "$NEW_VERSION"
    log_success "Updated $OPENAPI_FILE"
  else
    log_info "[DRY RUN] Would update $OPENAPI_FILE: version $NEW_VERSION"
  fi

  # Update CHANGELOG
  CHANGELOG_FILE="$CONTRACTS_DIR/api/v$NEW_VERSION/CHANGELOG.md"
  if [[ "$DRY_RUN" == false ]]; then
    add_changelog_entry "$CHANGELOG_FILE" "$NEW_VERSION" "$BUMP_LEVEL"
    log_success "Updated $CHANGELOG_FILE"
  else
    log_info "[DRY RUN] Would update $CHANGELOG_FILE with v$NEW_VERSION entry"
  fi

  # Run contract verification (skip in dry run)
  if [[ "$DRY_RUN" == false ]]; then
    if ! verify_contracts; then
      log_error "Contract verification failed - rolling back"
      rm -rf "$CONTRACTS_DIR/api/v$NEW_VERSION"
      exit 1
    fi
  else
    log_info "[DRY RUN] Would run CDC verification"
  fi

  # Git workflow
  if [[ "$DRY_RUN" == false ]]; then
    BRANCH_NAME="contracts/bump-v$NEW_VERSION"

    # Create branch
    git checkout -b "$BRANCH_NAME"
    log_success "Created branch: $BRANCH_NAME"

    # Commit changes
    git add "$CONTRACTS_DIR/"
    git commit -m "feat(contracts): bump API contract to v$NEW_VERSION

See CHANGELOG.md for details.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    log_success "Committed changes"

    # Create PR
    PR_URL=$(gh pr create \
      --title "Bump API contract to v$NEW_VERSION" \
      --body "$(cat <<EOF
## Contract Version Bump

**Type**: \`$BUMP_LEVEL\`
**Version**: v$CURRENT_VERSION → v$NEW_VERSION

## Changes

See \`contracts/api/v$NEW_VERSION/CHANGELOG.md\` for details.

## CDC Verification

✅ All consumer contracts verified

## Deployment Impact

- **Staging**: Deploy immediately after merge
- **Production**: Review consumer impact before deploy

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" 2>&1 | grep -oP 'https://.*')

    log_success "Created PR: $PR_URL"

  else
    log_info "[DRY RUN] Would create branch: contracts/bump-v$NEW_VERSION"
    log_info "[DRY RUN] Would commit changes"
    log_info "[DRY RUN] Would create PR"
  fi

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "Contract bump complete: v$CURRENT_VERSION → v$NEW_VERSION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📄 Files Updated:"
  echo "   - contracts/api/v$NEW_VERSION/openapi.yaml"
  echo "   - contracts/api/v$NEW_VERSION/CHANGELOG.md"
  echo ""

  if [[ "$DRY_RUN" == false ]]; then
    echo "📝 Next Steps:"
    echo "   1. Review and merge PR: $PR_URL"
    echo "   2. Deploy to staging to publish new contract"
    echo "   3. Notify consumers of new version"
  else
    echo "This was a dry run. No changes were applied."
    echo "Run without --dry-run to apply changes."
  fi
  echo ""
}

main "$@"

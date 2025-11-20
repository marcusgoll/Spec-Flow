# Release — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-20

This document provides comprehensive reference material for the `/release` command, including detailed workflows, version bump detection, file updates, error recovery, and best practices.

---

## Table of Contents

1. [Pre-Flight Checks](#pre-flight-checks)
2. [Version Bump Detection](#version-bump-detection)
3. [Build System](#build-system)
4. [File Updates](#file-updates)
5. [Git Operations](#git-operations)
6. [GitHub Release Creation](#github-release-creation)
7. [npm Publishing](#npm-publishing)
8. [X Announcement](#x-announcement)
9. [Error Recovery](#error-recovery)
10. [Example Run](#example-run)

---

## Pre-Flight Checks

Before proceeding with release, the command validates that the environment is ready.

### Check 1: Git Remote Configured

**Command:**
```bash
git remote get-url origin
```

**Purpose**: Ensure git remote is configured for pushing

**Failure message:**
```
❌ No git remote configured. Add remote: `git remote add origin <url>`
```

### Check 2: On Main Branch

**Command:**
```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ Not on main branch (currently on: $CURRENT_BRANCH)"
  echo "Switch to main: git checkout main"
  exit 1
fi
```

**Purpose**: Ensure releases only happen from main branch

**Failure message:**
```
❌ Not on main branch (currently on: {BRANCH})
Switch to main: git checkout main
```

### Check 3: Clean Working Tree

**Command:**
```bash
git status --porcelain
```

**Purpose**: Verify no uncommitted changes

**Failure behavior**: Ask user if they want to continue with uncommitted changes. Show `git status` output.

### Check 4: npm Authentication

**Command:**
```bash
npm whoami
```

**Purpose**: Verify user is logged into npm

**Failure message:**
```
❌ Not logged into npm. Run: `npm login`
```

### Check 5: CI Status

**Command:**
```bash
CI_STATUS=$(gh run list --workflow=ci.yml --branch=main --limit=1 --json conclusion --jq '.[0].conclusion')

if [ "$CI_STATUS" != "success" ]; then
  echo "❌ CI checks are not passing on main branch"
  echo "Current status: $CI_STATUS"
  echo ""
  echo "View CI: https://github.com/marcusgoll/Spec-Flow/actions/workflows/ci.yml"
  echo ""
  echo "Options:"
  echo "1. Fix CI failures and run /release again"
  echo "2. Wait for CI to complete"
  echo "3. Override (not recommended): Continue anyway"
  echo ""
  read -p "Continue anyway? (yes/no): " OVERRIDE
  if [ "$OVERRIDE" != "yes" ]; then
    echo "Release cancelled. Fix CI and try again."
    exit 1
  fi
  echo "⚠️  Proceeding despite CI failures (user override)"
else
  echo "✅ CI checks passing"
fi
```

**Purpose**: Ensure CI is passing before release

**Failure behavior**: User can override, but warned about risk

---

## Version Bump Detection

The release command automatically detects the appropriate version bump based on conventional commit messages.

### Get Current Version

```bash
CURRENT_VERSION=$(node -p "require('./package.json').version")
```

### Get Last Release Tag

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
```

### Get Commits Since Last Release

```bash
COMMITS=$(git log ${LAST_TAG}..HEAD --pretty=format:"%s")
```

### Conventional Commit Patterns

**MAJOR bump** (breaking changes):
- Match: `/BREAKING CHANGE:/i` in commit body
- Match: `/^[a-z]+(\(.*\))?!:/i` (e.g., `feat!:`, `fix!:`)

**MINOR bump** (new features):
- Match: `/^feat(\(.*\))?:/i`
- Match: `/^feature(\(.*\))?:/i`

**PATCH bump** (fixes and maintenance):
- Match: `/^fix(\(.*\))?:/i`
- Match: `/^patch(\(.*\))?:/i`
- Match: `/^(chore|docs|refactor|test|style|perf)(\(.*\))?:/i`

**Default**: If no clear indicators found → **PATCH**

### Version Bump Priority

Priority order (highest to lowest):
1. **MAJOR** if any breaking changes found
2. **MINOR** if any features found (and no breaking changes)
3. **PATCH** otherwise

### Calculate New Version

```bash
# Parse current version
IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"

# Apply bump
if [ "$BUMP_TYPE" = "major" ]; then
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
elif [ "$BUMP_TYPE" = "minor" ]; then
  MINOR=$((MINOR + 1))
  PATCH=0
else
  PATCH=$((PATCH + 1))
fi

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
```

### Release Analysis Display

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Release Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Version: v{CURRENT_VERSION}
New Version:     v{NEW_VERSION}
Bump Type:       {BUMP_TYPE}

Recent Commits ({COUNT}):
{list commits with bullet points}

Detected Changes:
- {X} breaking changes
- {X} features
- {X} fixes
- {X} other
```

---

## Build System

**NEW in v6.12.0**: Build clean dist/ folder for npm distribution.

### Build Process

Execute the build script to create the dist/ package:

```bash
echo "🔨 Building distribution package..."
npm run build
```

**The build script will**:
1. Clean existing dist/ folder
2. Copy essential files (.claude/, .spec-flow/, package files)
3. Validate exclusions (no beta files in dist)
4. Validate essentials (all core files present)
5. Check package size (< 4MB target)
6. Generate BUILD_REPORT.md

### Verify Build

```bash
if [ ! -f "dist/BUILD_REPORT.md" ]; then
  echo "❌ Build failed - BUILD_REPORT.md not found in dist/"
  echo "Check build output above for errors"
  exit 1
fi

echo "✅ Distribution package built successfully"
```

### Build Summary

```bash
# Extract key metrics from BUILD_REPORT.md
echo ""
echo "📊 Build Summary:"
grep -E "Files copied:|Total files in dist:|Package size:" dist/BUILD_REPORT.md | sed 's/^/  /'
echo ""
```

### Build Failure Handling

```
❌ Distribution build failed!

The build system detected issues:
- Check console output above for specific errors
- Review dist/BUILD_REPORT.md if it exists
- Common issues:
  * Beta files found in dist (exclusion validation failed)
  * Missing essential files (core workflow files not copied)
  * Package size exceeded 4MB limit

Fix the issues and run /release again.
```

**CRITICAL**: Do not proceed to version updates if build fails.

---

## File Updates

### Update package.json

```bash
# Read, update version, write back
node -e "
const pkg = require('./package.json');
pkg.version = '${NEW_VERSION}';
require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

### Update CHANGELOG.md

Insert new release entry at the top:

```bash
TODAY=$(date +%Y-%m-%d)
TEMP_FILE=$(mktemp)

# Read until we hit the first existing release section
awk -v version="$NEW_VERSION" -v date="$TODAY" '
  !inserted && /^## \[/ {
    print "## [" version "] - " date
    print ""
    print "### Changed"
    print "- Version bump to " version
    print ""
    print "<!-- Add detailed release notes here -->"
    print ""
    print "---"
    print ""
    inserted=1
  }
  { print }
' CHANGELOG.md > "$TEMP_FILE"

mv "$TEMP_FILE" CHANGELOG.md
```

### Update README.md

Insert new version entry at top of "Recent Updates" section:

```bash
# Get month name for README format
MONTH_NAME=$(date +"%B")  # January, February, etc.
YEAR=$(date +%Y)

# Extract release notes from CHANGELOG
RELEASE_NOTES=$(awk "/## \[$NEW_VERSION\]/,/^## \[/" CHANGELOG.md | \
  sed '1d;$d' | \
  sed '/^---$/d' | \
  sed 's/^### /\*\*/' | \
  sed 's/$/\*\*/' | \
  head -20)

# Create README update
TEMP_README=$(mktemp)
awk -v version="$NEW_VERSION" -v month="$MONTH_NAME" -v year="$YEAR" -v notes="$RELEASE_NOTES" '
  /^## 🆕 Recent Updates/ {
    print
    print ""
    print "### v" version " (" month " " year ")"
    print notes
    print ""
    inserted=1
    next
  }
  # Skip old first entry header to avoid duplication
  /^### v[0-9]/ && !skipped && inserted {
    skipped=1
    next
  }
  { print }
' README.md > "$TEMP_README"

mv "$TEMP_README" README.md
```

---

## Git Operations

### Create Commit

```bash
git add package.json CHANGELOG.md README.md

git commit -m "$(cat <<EOF
chore: release v${NEW_VERSION}

- Bump version to ${NEW_VERSION}
- Update CHANGELOG.md with release notes
- Update README.md with new version
- Update version references

Release: v${NEW_VERSION}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Create Git Tag

```bash
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
```

### Push to GitHub

```bash
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "v${NEW_VERSION}"
```

**Error handling:**
```
❌ Push to GitHub failed!

The commit and tag exist locally but were not pushed.

Options:
1. Fix the issue and run: git push origin main && git push origin v{NEW_VERSION}
2. Delete local tag and retry: git tag -d v{NEW_VERSION} && git reset --hard HEAD~1
```

**CRITICAL**: Do not proceed to npm publish if push fails.

---

## GitHub Release Creation

Create GitHub Release with release notes extracted from CHANGELOG:

```bash
echo "📦 Creating GitHub Release..."

# Extract release notes from CHANGELOG
RELEASE_BODY=$(awk "/## \[$NEW_VERSION\]/,/^## \[/" CHANGELOG.md | \
  sed '1d;$d' | \
  sed '/^---$/d' | \
  sed '/^$/N;/^\n$/D')  # Remove multiple blank lines

# Add footer to release notes
RELEASE_BODY="${RELEASE_BODY}

---

📦 **Install**: \`npm install spec-flow@${NEW_VERSION}\`
📚 **Docs**: https://github.com/marcusgoll/Spec-Flow
🐛 **Issues**: https://github.com/marcusgoll/Spec-Flow/issues

🤖 Released with [Claude Code](https://claude.com/claude-code)"

# Create GitHub Release using gh CLI
gh release create "v${NEW_VERSION}" \
  --title "v${NEW_VERSION}" \
  --notes "$RELEASE_BODY" \
  --verify-tag

if [ $? -eq 0 ]; then
  echo "✅ GitHub Release created: https://github.com/marcusgoll/Spec-Flow/releases/tag/v${NEW_VERSION}"
else
  echo "⚠️  GitHub Release creation failed (non-blocking)"
  echo "Create manually: https://github.com/marcusgoll/Spec-Flow/releases/new?tag=v${NEW_VERSION}"
fi
```

**Error Handling**: If GitHub Release fails, workflow continues (release still valid via tag + npm)

---

## npm Publishing

### Publish to npm

```bash
echo "📦 Publishing to npm..."
npm publish
```

### Verify Publication

```bash
PUBLISHED_VERSION=$(npm view spec-flow version 2>/dev/null)
if [ "$PUBLISHED_VERSION" = "$NEW_VERSION" ]; then
  echo "✅ Published to npm successfully"
else
  echo "⚠️  Published but version mismatch (expected: $NEW_VERSION, got: $PUBLISHED_VERSION)"
fi
```

### npm Publish Error Handling

```
❌ npm publish failed!

The commit and tag are pushed to GitHub, but npm package was not published.

Common causes:
- Not logged in: Run `npm login`
- Version already exists: Check npm for existing v{NEW_VERSION}
- Network issue: Retry with `npm publish`
- Permission denied: Verify npm account has publish rights to "spec-flow"

To retry publish manually:
npm publish
```

**Note**: Release is still valid on GitHub even if npm fails.

---

## X Announcement

**Optional**: Announce the release on X (Twitter).

### Invoke X Announce Command

```bash
if [ -f ".claude/commands/x-announce.md" ]; then
  echo "📱 Posting release announcement to X..."
  /x-announce "v${NEW_VERSION}"
else
  echo "ℹ️  X announcement command not available (optional - skipping)"
fi
```

**What this does**:
- Invokes the `/x-announce` slash command with the version number
- Command provides 5 options: post now, schedule, draft, edit, skip
- If "post now" selected: Posts immediately and creates threaded reply with GitHub link
- If "schedule" selected: Schedules post for specified datetime
- If "draft" selected: Saves post without publishing
- Non-blocking: Errors or skips don't stop the release workflow

---

## Error Recovery

### Scenario 1: Pre-flight Checks Fail

**Issue**: Git remote, branch, npm auth, or CI status check fails

**Recovery**:
1. Fix the issue (e.g., `npm login`, `git checkout main`)
2. Run `/release` again

### Scenario 2: Build Fails (NEW in v6.12.0)

**Issue**: Distribution package build fails

**Recovery**:
1. Check build output for specific errors
2. Review `dist/BUILD_REPORT.md` if it exists
3. Common issues:
   * Beta files found in dist → Check exclusion patterns in build-dist.js
   * Missing essential files → Check include patterns in build-dist.js
   * Package size exceeded 4MB → Remove large files or optimize
4. Fix the issue
5. Run `/release` again

### Scenario 3: Files Updated but Commit Failed

**Issue**: package.json/CHANGELOG.md updated but commit failed

**Recovery**:
1. Check git status: `git status`
2. Fix any issues
3. Manually commit: `git add . && git commit -m "chore: release vX.Y.Z"`
4. Continue manually or run `/release` again

### Scenario 4: Commit Created but Push Failed

**Issue**: Commit and tag created locally but push to GitHub failed

**Recovery**:
1. Fix network/auth issues
2. Manually push: `git push origin main && git push origin vX.Y.Z`
3. Then manually publish: `npm publish`

### Scenario 5: Pushed but npm Publish Failed

**Issue**: Changes pushed to GitHub but npm publish failed

**Recovery**:
1. Fix npm auth: `npm login`
2. Manually publish: `npm publish`
3. Note: Release is still valid on GitHub

### Scenario 6: Everything Published but Want to Undo

**Issue**: Released but need to rollback

**Important**:
- **Cannot unpublish from npm** (npm policy after 24 hours)
- Can delete GitHub tag: `git push origin --delete vX.Y.Z`
- Can delete local tag: `git tag -d vX.Y.Z`
- Must publish new patch version to fix issues

---

## Example Run

```
/release

🔍 Pre-flight checks...
✅ Git remote configured
✅ On main branch
✅ Working tree clean
✅ npm authenticated
✅ CI checks passing

📊 Analyzing commits since v2.1.3...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Release Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Version: v2.1.3
New Version:     v2.2.0
Bump Type:       minor

Recent Commits (5):
- feat: add automatic version detection to /release
- fix: correct error message in pre-flight checks
- docs: update CLAUDE.md with new release flow
- chore: update dependencies
- test: add unit tests for version detection

Detected Changes:
- 0 breaking changes
- 1 feature
- 1 fix
- 3 other

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to release v2.2.0. This will:
✅ Build distribution package (dist/)
✅ Validate package (exclusions, essentials, size)
✅ Update package.json version field
✅ Add CHANGELOG.md entry for v2.2.0
✅ Update README.md Recent Updates section
✅ Commit changes with message: "chore: release v2.2.0"
✅ Create git tag: v2.2.0
✅ Push to GitHub (origin/main + tag)
✅ Create GitHub Release with release notes
✅ Publish to npm

Proceed with release? yes

🔨 Building distribution package...
✅ Distribution package built successfully

📊 Build Summary:
  Files copied: 287
  Total files in dist: 287
  Package size: 2.8 MB (< 4MB target)

📝 Updating files...
✅ package.json updated
✅ CHANGELOG.md updated
✅ README.md updated

📝 Committing changes...
✅ Commit created: a1b2c3d chore: release v2.2.0

🏷️  Creating git tag...
✅ Tag created: v2.2.0

📤 Pushing to GitHub...
✅ Pushed to origin/main
✅ Pushed tag v2.2.0

📦 Creating GitHub Release...
✅ GitHub Release created: https://github.com/marcusgoll/Spec-Flow/releases/tag/v2.2.0

📦 Publishing to npm...
✅ Published to npm successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Release v2.2.0 Published!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Successfully released Spec-Flow v2.2.0

📦 Package:
   npm: https://www.npmjs.com/package/spec-flow/v/2.2.0
   Install: npm install spec-flow@2.2.0

🏷️  GitHub Release:
   URL: https://github.com/marcusgoll/Spec-Flow/releases/tag/v2.2.0
   Tag: v2.2.0
   Commit: a1b2c3d

📝 Documentation:
   README.md: ✅ Updated with v2.2.0
   CHANGELOG.md: ✅ Updated with release notes
   Release Notes: ✅ Published to GitHub

📦 Distribution:
   Build Report: dist/BUILD_REPORT.md
   Package Size: 2.8 MB (< 4MB target)
   Files in dist: 287

📊 CI Status: ✅ All checks passing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Release Complete! No manual steps required.

Optional Next Steps:
1. **Announce**: Share release on social media
2. **Verify**: Test installation with npx spec-flow@2.2.0 --version

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Important Notes

- **Build System (v6.12.0+)**: The release command now builds a clean dist/ package before publishing. This ensures only essential files are included (no beta commands, dev scripts, or redundant templates).

- **Conventional Commits Required**: This command relies on conventional commit messages. If your commits don't follow the convention, it defaults to PATCH.

- **No Rollback After Publish**: Once published to npm, you cannot unpublish (npm policy). Make sure you're ready before confirming.

- **CHANGELOG Edits**: The command creates a minimal CHANGELOG entry. Add detailed notes before announcing the release.

- **GitHub Release**: The command creates a GitHub Release automatically with release notes from CHANGELOG.

- **Credentials Required**: You must be logged into npm (`npm login`) before running this command.

- **Build Validation**: The build system validates exclusions (no beta files), essentials (core files present), and size (< 4MB). If validation fails, the release stops.

---

## Workflow Position

This command is **internal only** and runs **outside** the normal feature workflow:

```
Normal Feature Workflow:
/feature → ... → /ship-prod → /finalize

Workflow Development:
[Complete feature] → [Merge to main] → /release → [npm published]
```

**Use this command when:**
- You've completed work on a workflow improvement
- All changes are committed to main branch
- You're ready to publish a new version of the spec-flow package
- You want to automate the entire release process

**Do NOT use this for:**
- User project releases (users manage their own versioning)
- Feature branches (only release from main)
- Experimental changes (publish stable releases only)

---
description: "Release new version of Spec-Flow package (INTERNAL - workflow development only)"
---

# Internal Release Command

**DO NOT SHIP**: This command is for Spec-Flow workflow development only. Use it to release new versions of the workflow package itself.

You are now in release mode. Follow this workflow to automatically release a new version of the Spec-Flow package with smart version detection.

---

## Overview

This command automates the entire release process:
- ✅ Auto-detects version bump from commit messages (conventional commits)
- ✅ Updates package.json and CHANGELOG.md
- ✅ Creates commit and git tag
- ✅ Pushes to GitHub automatically
- ✅ Publishes to npm automatically
- ✅ Verifies success and shows release URLs

**Philosophy**: Manual trigger, but fully automated execution. One command to go from commits → published npm package.

---

## Step 1: Pre-Flight Checks

Run these checks before proceeding. If any fail, abort and show error message.

### Check 1: Git Remote Configured
```bash
git remote get-url origin
```
**If fails**: "❌ No git remote configured. Add remote: `git remote add origin <url>`"

### Check 2: On Main Branch
```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ Not on main branch (currently on: $CURRENT_BRANCH)"
  echo "Switch to main: git checkout main"
  exit 1
fi
```

### Check 3: Clean Working Tree
```bash
git status --porcelain
```
**If has output**: Ask user if they want to continue with uncommitted changes. Show `git status` output.

### Check 4: npm Authentication
```bash
npm whoami
```
**If fails**: "❌ Not logged into npm. Run: `npm login`"

**If all checks pass**: Display "✅ Pre-flight checks passed" and continue.

---

## Step 2: Analyze Commits for Version Bump

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

### Analyze Commit Messages

Scan commits for conventional commit patterns:

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

### Determine Version Bump

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

### Display Analysis

Show this summary to the user:

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

## Step 3: Confirm Release

Ask user for final confirmation:

```
Ready to release v{NEW_VERSION}. This will:
✅ Update package.json version field
✅ Add CHANGELOG.md entry for v{NEW_VERSION}
✅ Commit changes with message: "chore: release v{NEW_VERSION}"
✅ Create git tag: v{NEW_VERSION}
✅ Push to GitHub (origin/main + tag)
✅ Publish to npm

Proceed with release? (yes/no)
```

**If user says no**: Exit gracefully with "Release cancelled."

**If user says yes**: Continue to Step 4.

---

## Step 4: Update Files

### 4.1: Update package.json

```bash
# Read, update version, write back
node -e "
const pkg = require('./package.json');
pkg.version = '${NEW_VERSION}';
require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

### 4.2: Update CHANGELOG.md

Insert new release entry at the top, right after the header:

```markdown
## [{NEW_VERSION}] - {YYYY-MM-DD}

### Changed
- Version bump to {NEW_VERSION}

<!-- Add detailed release notes here before publishing -->

---
```

Use this bash snippet to insert:
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

**Show diff** to user before committing:
```bash
git diff package.json CHANGELOG.md
```

---

## Step 5: Commit Changes

Create commit with conventional commit format:

```bash
git add package.json CHANGELOG.md

git commit -m "$(cat <<EOF
chore: release v${NEW_VERSION}

- Bump version to ${NEW_VERSION}
- Update CHANGELOG.md with release notes
- Update version references

Release: v${NEW_VERSION}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Verify commit created**:
```bash
git log -1 --format="%H %s"
```

---

## Step 6: Create Git Tag

Create annotated git tag:

```bash
git tag -a "v${NEW_VERSION}" -m "Release v${NEW_VERSION}"
```

**Verify tag created**:
```bash
git tag -l "v${NEW_VERSION}"
```

---

## Step 7: Push to GitHub

Push both the commit and the tag to remote:

```bash
echo "📤 Pushing to GitHub..."
git push origin main
git push origin "v${NEW_VERSION}"
```

**Error Handling**:
- If push fails → Show error message and rollback instructions:
  ```
  ❌ Push to GitHub failed!

  The commit and tag exist locally but were not pushed.

  Options:
  1. Fix the issue and run: git push origin main && git push origin v{NEW_VERSION}
  2. Delete local tag and retry: git tag -d v{NEW_VERSION} && git reset --hard HEAD~1
  ```
  **STOP** - Do not proceed to npm publish if push fails.

**If push succeeds**: Display "✅ Pushed to GitHub"

---

## Step 8: Publish to npm

Publish the package to npm registry:

```bash
echo "📦 Publishing to npm..."
npm publish
```

**Wait for publish to complete** (shows progress output).

**Verify publication**:
```bash
PUBLISHED_VERSION=$(npm view spec-flow version 2>/dev/null)
if [ "$PUBLISHED_VERSION" = "$NEW_VERSION" ]; then
  echo "✅ Published to npm successfully"
else
  echo "⚠️  Published but version mismatch (expected: $NEW_VERSION, got: $PUBLISHED_VERSION)"
fi
```

**Error Handling**:
- If npm publish fails → Show error and troubleshooting steps:
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
  **Continue** - Release is still valid on GitHub even if npm fails.

**If publish succeeds**: Continue to Step 9.

---

## Step 9: Show Success Summary

Display comprehensive success message:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Release v{NEW_VERSION} Published!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Successfully released Spec-Flow v{NEW_VERSION}

📦 Package:
   npm: https://www.npmjs.com/package/spec-flow/v/{NEW_VERSION}
   Install: npm install spec-flow@{NEW_VERSION}

🏷️  Git Tag:
   Tag: v{NEW_VERSION}
   Commit: {COMMIT_SHA}
   URL: https://github.com/marcusgoll/Spec-Flow/releases/tag/v{NEW_VERSION}

📝 Repository:
   Commit: https://github.com/marcusgoll/Spec-Flow/commit/{COMMIT_SHA}
   Compare: https://github.com/marcusgoll/Spec-Flow/compare/v{LAST_TAG}...v{NEW_VERSION}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Next Steps:

1. **Update CHANGELOG.md** (recommended):
   - Open CHANGELOG.md
   - Replace "<!-- Add detailed release notes here -->" with actual changes
   - Examples: new features, bug fixes, breaking changes
   - Commit: git add CHANGELOG.md && git commit --amend --no-edit && git push -f

2. **Create GitHub Release** (optional):
   - Go to: https://github.com/marcusgoll/Spec-Flow/releases/new?tag=v{NEW_VERSION}
   - Copy release notes from CHANGELOG.md
   - Add any additional context or screenshots
   - Publish release

3. **Announce** (optional):
   - Share on social media
   - Update documentation sites
   - Notify users of new features

4. **Verify Installation**:
   - Test: npx spec-flow@{NEW_VERSION} --version
   - Should output: {NEW_VERSION}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Error Recovery Guide

### If Something Goes Wrong

**Scenario 1: Pre-flight checks fail**
- Fix the issue (e.g., `npm login`, `git checkout main`)
- Run `/release` again

**Scenario 2: Files updated but commit failed**
- Check git status: `git status`
- Fix any issues
- Manually commit: `git add . && git commit -m "chore: release vX.Y.Z"`
- Continue manually or run `/release` again

**Scenario 3: Commit created but push failed**
- Fix network/auth issues
- Manually push: `git push origin main && git push origin vX.Y.Z`
- Then manually publish: `npm publish`

**Scenario 4: Pushed but npm publish failed**
- Fix npm auth: `npm login`
- Manually publish: `npm publish`
- Release is still valid on GitHub

**Scenario 5: Everything published but want to undo**
- **Cannot unpublish from npm** (after 24 hours)
- Can delete GitHub tag: `git push origin --delete vX.Y.Z`
- Can delete local tag: `git tag -d vX.Y.Z`
- Must publish new patch version to fix issues

---

## Important Notes

- **Conventional Commits Required**: This command relies on conventional commit messages. If your commits don't follow the convention, it defaults to PATCH.
- **No Rollback After Publish**: Once published to npm, you cannot unpublish (npm policy). Make sure you're ready before confirming.
- **CHANGELOG Edits**: The command creates a minimal CHANGELOG entry. Add detailed notes before announcing the release.
- **GitHub Release**: The command creates a git tag but not a GitHub Release. Create one manually for better visibility.
- **Credentials Required**: You must be logged into npm (`npm login`) before running this command.

---

## Example Run

```
/release

🔍 Pre-flight checks...
✅ Git remote configured
✅ On main branch
✅ Working tree clean
✅ npm authenticated

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
✅ Update package.json version field
✅ Add CHANGELOG.md entry for v2.2.0
✅ Commit changes with message: "chore: release v2.2.0"
✅ Create git tag: v2.2.0
✅ Push to GitHub (origin/main + tag)
✅ Publish to npm

Proceed with release? yes

📝 Updating files...
✅ package.json updated
✅ CHANGELOG.md updated

📝 Committing changes...
✅ Commit created: a1b2c3d chore: release v2.2.0

🏷️  Creating git tag...
✅ Tag created: v2.2.0

📤 Pushing to GitHub...
✅ Pushed to origin/main
✅ Pushed tag v2.2.0

📦 Publishing to npm...
✅ Published to npm successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Release v2.2.0 Published!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... success message as shown above ...]
```

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

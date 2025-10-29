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

### Check 5: CI Status
```bash
echo "🔍 Checking CI status..."
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
**If fails**: User can override, but warned about risk

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
✅ Verify CI checks are passing
✅ Update package.json version field
✅ Update CHANGELOG.md with release notes
✅ Update README.md Recent Updates section
✅ Commit changes with message: "chore: release v{NEW_VERSION}"
✅ Create git tag: v{NEW_VERSION}
✅ Push to GitHub (origin/main + tag)
✅ Create GitHub Release with release notes
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

### 4.3: Update README.md

Insert new version entry at top of "Recent Updates" section:

```bash
# Get month name for README format
MONTH_NAME=$(date +"%B")  # January, February, etc.
YEAR=$(date +%Y)

# Extract release notes from CHANGELOG (between new version and next version heading)
RELEASE_NOTES=$(awk "/## \[$NEW_VERSION\]/,/^## \[/" CHANGELOG.md | \
  sed '1d;$d' | \
  sed '/^---$/d' | \
  sed 's/^### /\*\*/' | \
  sed 's/$/\*\*/' | \
  head -20)

# Create README update (insert after "## 🆕 Recent Updates")
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
echo "✅ README.md updated"
```

**Show updated diff**:
```bash
git diff package.json CHANGELOG.md README.md
```

---

## Step 5: Commit Changes

Create commit with conventional commit format:

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


## Step 7.5: Create GitHub Release

Create GitHub Release with release notes extracted from CHANGELOG:

```bash
echo "📦 Creating GitHub Release..."

# Extract release notes from CHANGELOG (everything between new version and next version heading)
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

## Step 9: Post X Announcement (Optional)

Announce the release on X (Twitter) using the x-announcement skill.

**Note**: This step uses an internal X Poster API. The skill file is in `.gitignore` and should not be committed to the repository.

### Load Skill

Load the x-announcement skill if it exists (it's gitignored, so may not be available in all environments):

```bash
if [ -f ".claude/skills/x-announcement.md" ]; then
  echo "📱 Preparing X announcement..."
else
  echo "ℹ️  X announcement skill not available (optional - skipping)"
  # Skip to Step 10
  exit 0
fi
```

### Generate Post Content

Extract key features from CHANGELOG for this version:

```bash
# Get release notes for this version
CHANGELOG_SECTION=$(awk "/^## \[${NEW_VERSION}\]/,/^## \[/" CHANGELOG.md | sed '1d;$d' | sed '/^---$/d')

# Extract features (under ### Added, ### Fixed, ### Changed)
FEATURES=$(echo "$CHANGELOG_SECTION" | grep -A 10 "^### Added" | grep "^- " | head -3)
FIXES=$(echo "$CHANGELOG_SECTION" | grep -A 10 "^### Fixed" | grep "^- " | head -2)
```

### Draft Suggested Post

Generate an engaging X post (follow guidelines from x-announcement.md):

```
🚀 Spec-Flow v{NEW_VERSION} is here!

{Top 2-3 features from CHANGELOG with emojis}

Ship features faster with less manual work.
```

**Character limit**: ≤ 280 characters

### Show Preview and Get Confirmation

Display the generated post to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 X Announcement Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Generated post text}

Characters: XXX/280
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
1. ✅ Post as-is
2. ✏️  Edit post text
3. ❌ Skip X announcement

Enter choice (1-3):
```

**If user chooses "Edit"**:
- Prompt for edited text
- Validate character count (≤280)
- Show updated preview
- Re-confirm

**If user chooses "Skip"**:
- Continue to Step 10 (Success Summary)

### Post to X API

Once confirmed, post using the X Poster API:

```bash
# Post main announcement
RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$POST_CONTENT\", \"scheduled_at\": null}")

POST_ID=$(echo "$RESPONSE" | jq -r '.id')
echo "📤 Posting to X... (ID: $POST_ID)"
```

### Wait for Publish

Poll for tweet_id (max 60 seconds):

```bash
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  STATUS_RESPONSE=$(curl -s "http://5.161.75.135:8080/api/v1/posts/$POST_ID")
  POST_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
  TWEET_ID=$(echo "$STATUS_RESPONSE" | jq -r '.tweet_id // empty')

  if [ "$POST_STATUS" = "posted" ] && [ -n "$TWEET_ID" ]; then
    echo "✅ Posted to X!"
    break
  elif [ "$POST_STATUS" = "failed" ]; then
    ERROR_REASON=$(echo "$STATUS_RESPONSE" | jq -r '.error_reason')
    echo "❌ Post failed: $ERROR_REASON"
    echo "Continuing with release..."
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done
```

### Reply with GitHub Link

If main post succeeded, reply with the release link as a threaded reply:

```bash
if [ -n "$TWEET_ID" ]; then
  GITHUB_RELEASE_URL="https://github.com/marcusgoll/Spec-Flow/releases/tag/v${NEW_VERSION}"
  REPLY_CONTENT="🔗 Release notes: ${GITHUB_RELEASE_URL}"

  # Post reply as thread (using in_reply_to_tweet_id)
  REPLY_RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"$REPLY_CONTENT\", \"scheduled_at\": null, \"in_reply_to_tweet_id\": \"$TWEET_ID\"}")

  REPLY_POST_ID=$(echo "$REPLY_RESPONSE" | jq -r '.id')

  # Wait for reply to post
  ATTEMPT=0
  while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    REPLY_STATUS_RESPONSE=$(curl -s "http://5.161.75.135:8080/api/v1/posts/$REPLY_POST_ID")
    REPLY_STATUS=$(echo "$REPLY_STATUS_RESPONSE" | jq -r '.status')
    REPLY_TWEET_ID=$(echo "$REPLY_STATUS_RESPONSE" | jq -r '.tweet_id // empty')

    if [ "$REPLY_STATUS" = "posted" ] && [ -n "$REPLY_TWEET_ID" ]; then
      echo "✅ GitHub link posted!"
      break
    fi

    ATTEMPT=$((ATTEMPT + 1))
    sleep 3
  done
fi
```

### Store Tweet URLs

Store the tweet URLs for display in Step 10:

```bash
if [ -n "$TWEET_ID" ]; then
  X_MAIN_POST_URL="https://x.com/username/status/${TWEET_ID}"
fi

if [ -n "$REPLY_TWEET_ID" ]; then
  X_REPLY_POST_URL="https://x.com/username/status/${REPLY_TWEET_ID}"
fi
```

### Error Handling

**If API is unreachable**:
```
⚠️  X Poster API is unavailable

Release completed successfully, but X announcement could not be posted.

Manual posting option:
1. Copy the post text above
2. Post to X: https://x.com/compose
3. Reply with: 🔗 Release notes: {GITHUB_RELEASE_URL}

Continuing with release...
```

---

## Step 10: Show Success Summary

Display comprehensive success message:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Release v{NEW_VERSION} Published!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Successfully released Spec-Flow v{NEW_VERSION}

📦 Package:
   npm: https://www.npmjs.com/package/spec-flow/v/{NEW_VERSION}
   Install: npm install spec-flow@{NEW_VERSION}

🏷️  GitHub Release:
   URL: https://github.com/marcusgoll/Spec-Flow/releases/tag/v{NEW_VERSION}
   Tag: v{NEW_VERSION}
   Commit: {COMMIT_SHA}

📝 Documentation:
   README.md: ✅ Updated with v{NEW_VERSION}
   CHANGELOG.md: ✅ Updated with release notes
   Release Notes: ✅ Published to GitHub

📊 CI Status: ✅ All checks passing

{If X announcement was posted:}
📱 X Announcement:
   Main Post: {X_MAIN_POST_URL}
   Reply: {X_REPLY_POST_URL}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Release Complete! {If X posted: "Posted to X!" else: "No manual steps required."}

Optional Next Steps:
1. {If X not posted: "**Announce**: Share release on social media" else: "**Engage**: Monitor X for feedback and questions"}
2. **Verify**: Test installation with npx spec-flow@{NEW_VERSION} --version

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

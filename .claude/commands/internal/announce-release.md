---
name: announce-release
description: Post release announcement to X (Twitter) with GitHub link reply
argument-hint: [optional: version number]
allowed-tools: [Skill, Bash(git:*), Bash(grep:*)]
version: 1.0
updated: 2025-12-14
---

<objective>
Manually invoke X (Twitter) release announcement for the specified version (or latest release).

This command delegates to the x-announcement skill which:
- Generates engaging post from CHANGELOG
- Gets user confirmation before posting
- Posts main announcement via API
- Replies with GitHub release link in thread
- Handles errors gracefully without blocking
</objective>

<process>
1. Determine version to announce:
   - If $ARGUMENTS provided: Use specified version
   - Else: Extract latest version from CHANGELOG.md or git tags

2. Invoke x-announcement skill via Skill tool:
   - Pass version number
   - Let skill handle entire workflow (generate → confirm → post → reply)

3. Skill workflow will:
   - Extract highlights from CHANGELOG for version
   - Show preview with character count
   - Get user confirmation (post/edit/skip)
   - Post to X API if approved
   - Poll for tweet ID
   - Reply with GitHub link
   - Display both tweet URLs

4. Handle skill completion:
   - Success: Display tweet URLs
   - Failure: Show manual posting fallback
   - Skip: Continue without announcement
</process>

<version_detection>
**If version argument provided:**
```bash
VERSION="$ARGUMENTS"  # e.g., "2.7.0"
```

**If no argument (detect latest):**
```bash
# Try git tag first
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')

# Fallback to CHANGELOG
if [ -z "$VERSION" ]; then
  VERSION=$(grep -m 1 "^## \[" CHANGELOG.md | grep -oP '\[\K[^\]]+')
fi

# Validate version found
if [ -z "$VERSION" ]; then
  echo "❌ Could not detect version. Specify manually:"
  echo "   /announce-release 2.7.0"
  exit 1
fi
```
</version_detection>

<success_criteria>
- Version number detected or validated
- x-announcement skill invoked successfully
- User confirmation obtained before posting
- X announcement posted (or gracefully skipped)
- GitHub link reply posted in thread (or manual fallback provided)
- Tweet URLs displayed to user
- Release workflow unblocked on any X announcement failure
</success_criteria>

<examples>
**Example 1: Announce latest release**
```bash
/announce-release
```
Output:
```
Detecting latest release... v2.7.0

📱 Generating X announcement for v2.7.0...

[Preview shown, user confirms]

📤 Posting to X...
✅ Posted!

Main Post:
   https://x.com/username/status/1234567890

GitHub Link Reply:
   https://x.com/username/status/1234567891
```

**Example 2: Announce specific version**
```bash
/announce-release 2.6.0
```

**Example 3: User skips announcement**
```
[Preview shown]
Options:
1. ✅ Post as-is
2. ✏️  Edit post text
3. ❌ Skip X announcement

[User selects 3]

X Announcement Skipped

Generated post text (for reference):
...

To post manually later: https://x.com/compose
```

**Example 4: API unreachable**
```
⚠️  X Poster API Unavailable

Generated post text:
...

Manual posting option:
1. Copy the post text above
2. Post manually to X: https://x.com/compose
3. Reply with: 🔗 Release notes: https://...
```
</examples>

<anti_patterns>
**Avoid:**
- ❌ Blocking on X announcement failures
- ❌ Posting without user confirmation
- ❌ Exceeding 280 character limit
- ❌ Failing silently without fallback
- ❌ Exposing API credentials or URLs publicly

**Correct:**
- ✅ Always get user confirmation before posting
- ✅ Validate character count before submission
- ✅ Provide manual posting fallback on errors
- ✅ Continue gracefully on any failure
- ✅ Keep API details internal-only
</anti_patterns>

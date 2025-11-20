---
skill: x-announcement
description: Post release announcements to X (Twitter) with automated GitHub link reply
location: managed
triggers:
  - /release command completion
  - Manual invocation after release
---

# X Release Announcement Skill

**Purpose**: Automatically announce new Spec-Flow releases on X (Twitter) with engaging posts and GitHub release links.

**Triggers**:
- Automatically at the end of `/release` command
- Can be invoked manually for any release

**Philosophy**: "One release, one announcement" - Every release gets social visibility with minimal friction.

---

## Skill Context

When this skill is invoked, you will have access to:
- `NEW_VERSION` - The version number being released (e.g., "2.7.0")
- `CHANGELOG.md` - Release notes for this version
- `README.md` - Feature highlights
- `COMMIT_SHA` - Git commit hash for the release

**X Poster API**: Available at `http://5.161.75.135:8080/`
- No authentication required (network-isolated)
- See API reference below for endpoints

---

## Step 1: Generate Suggested Post

Create an engaging X post based on the release notes.

### Guidelines

**Format**:
- Start with emoji and hook (🚀, 📦, ✨, etc.)
- Include version number
- Highlight 1-3 key features/improvements
- Keep under 280 characters (leave room for editing)
- Use engaging language (not just bullet points)
- End with call-to-action or benefit statement

**Examples**:

```
🚀 Spec-Flow v2.7.0 is here!

✨ One-command releases with CI validation
🔄 Auto-close GitHub issues when features ship
🧹 Essential cleanup for all deployment models

Ship features faster with less manual work.
```

```
📦 Just released Spec-Flow v2.7.0!

New: Full /release automation (CI checks, CHANGELOG, tags, npm publishing)
Fixed: ShellCheck warnings for clean CI
Added: Issue auto-closing on deploy

5x faster releases. Try it now!
```

### Generation Process

1. **Read CHANGELOG**: Extract highlights from `## [NEW_VERSION]` section
2. **Identify Top Features**: Pick 2-3 most impactful changes (Added > Fixed > Changed)
3. **Draft Post**: Format with emojis and engaging tone
4. **Show Preview**: Display to user with character count

---

## Step 2: Get User Confirmation

Display the generated post and allow editing.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 X Announcement Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Generated post text here]

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
- Ask for confirmation again

**If user chooses "Skip"**:
- Exit gracefully
- Continue with release summary

---

## Step 3: Post to X API

Once user confirms, send the post via API.

### API Call: Create Post

```bash
# Prepare JSON payload
POST_CONTENT="<user-confirmed text>"

# Send to API
RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$POST_CONTENT\", \"scheduled_at\": null}")

# Extract post ID
POST_ID=$(echo "$RESPONSE" | jq -r '.id')

echo "📤 Posting to X... (ID: $POST_ID)"
```

### Error Handling

**If API is unreachable**:
```
⚠️  X Poster API is unavailable (http://5.161.75.135:8080/)

Release completed successfully, but X announcement could not be posted.

Manual posting option:
1. Copy the post text above
2. Post manually to X: https://x.com/compose
3. Reply with: 🔗 Release notes: https://github.com/marcusgoll/Spec-Flow/releases/tag/vNEW_VERSION

Release will continue...
```

**If POST fails**:
```
❌ Failed to create X post

Error: [error message from API]

Manual posting option: [same as above]
```

---

## Step 4: Poll for Tweet ID

Wait for the post to be published and retrieve the tweet ID.

### Polling Logic

```bash
MAX_ATTEMPTS=20  # 60 seconds total (20 × 3s)
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  # Get post status
  STATUS_RESPONSE=$(curl -s "http://5.161.75.135:8080/api/v1/posts/$POST_ID")

  POST_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
  TWEET_ID=$(echo "$STATUS_RESPONSE" | jq -r '.tweet_id // empty')

  if [ "$POST_STATUS" = "posted" ] && [ -n "$TWEET_ID" ]; then
    echo "✅ Posted to X!"
    break
  elif [ "$POST_STATUS" = "failed" ]; then
    ERROR_REASON=$(echo "$STATUS_RESPONSE" | jq -r '.error_reason')
    echo "❌ Post failed: $ERROR_REASON"
    exit 1
  fi

  # Still queued/posting/scheduled - wait and retry
  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done

if [ -z "$TWEET_ID" ]; then
  echo "⏱️  Timeout waiting for post to publish"
  echo "Check status manually: http://5.161.75.135:8080/api/v1/posts/$POST_ID"
  exit 1
fi
```

### Display Progress

```
📤 Posting to X... (ID: 12345)
⏳ Waiting for publish... (3s)
⏳ Waiting for publish... (6s)
⏳ Waiting for publish... (9s)
✅ Posted to X!
```

---

## Step 5: Reply with GitHub Link

Once the main post is live, reply with the GitHub release link.

### Generate Reply Content

```bash
GITHUB_RELEASE_URL="https://github.com/marcusgoll/Spec-Flow/releases/tag/v${NEW_VERSION}"

REPLY_CONTENT="🔗 Release notes: ${GITHUB_RELEASE_URL}"
```

### API Call: Create Threaded Reply

Use the `in_reply_to_tweet_id` parameter to create a proper threaded reply.

```bash
# Post reply as thread (using in_reply_to_tweet_id)
REPLY_RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$REPLY_CONTENT\", \"scheduled_at\": null, \"in_reply_to_tweet_id\": \"$TWEET_ID\"}")

REPLY_POST_ID=$(echo "$REPLY_RESPONSE" | jq -r '.id')

echo "📤 Posting GitHub link as threaded reply... (ID: $REPLY_POST_ID)"
```

### Poll for Reply Tweet ID

Use same polling logic as Step 4 to wait for reply to be posted.

```bash
# Wait for reply to post
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  REPLY_STATUS_RESPONSE=$(curl -s "http://5.161.75.135:8080/api/v1/posts/$REPLY_POST_ID")

  REPLY_STATUS=$(echo "$REPLY_STATUS_RESPONSE" | jq -r '.status')
  REPLY_TWEET_ID=$(echo "$REPLY_STATUS_RESPONSE" | jq -r '.tweet_id // empty')

  if [ "$REPLY_STATUS" = "posted" ] && [ -n "$REPLY_TWEET_ID" ]; then
    echo "✅ GitHub link posted!"
    break
  elif [ "$REPLY_STATUS" = "failed" ]; then
    echo "⚠️  Reply post failed (main post succeeded)"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done
```

---

## Step 6: Display Success Summary

Show URLs for both posts.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 X Announcement Posted!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Main Post:
   https://x.com/username/status/{TWEET_ID}

GitHub Link Reply:
   https://x.com/username/status/{REPLY_TWEET_ID}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## API Reference

### Base URL
```
http://5.161.75.135:8080/
```

**IMPORTANT**: Never expose this URL in public documentation, logs, or error messages visible to end users.

### Endpoints

#### POST /api/v1/posts/
Create a new post (immediate or scheduled), or create a threaded reply.

**Request**:
```json
{
  "content": "Tweet text (max 280 chars)",
  "scheduled_at": "2025-10-29T12:00:00Z" | null,
  "in_reply_to_tweet_id": "1234567890123456789" | null
}
```

**Parameters**:
- `content` (required): Tweet text, max 280 characters
- `scheduled_at` (optional): UTC ISO-8601 timestamp for scheduled posting, or null for immediate
- `in_reply_to_tweet_id` (optional): Tweet ID to reply to, creates a threaded reply

**Response**:
```json
{
  "id": 12345,
  "content": "Tweet text",
  "media_urls": [],
  "scheduled_at": null,
  "status": "queued",
  "tweet_id": null,
  "in_reply_to_tweet_id": "1234567890123456789",
  "error_reason": null,
  "created_at": "2025-10-29T11:00:00Z",
  "updated_at": "2025-10-29T11:00:00Z"
}
```

**Status Values**:
- `queued` - Waiting to post
- `posting` - Currently posting
- `posted` - Successfully posted (tweet_id available)
- `failed` - Failed to post (error_reason available)
- `scheduled` - Scheduled for future
- `cancelled` - User cancelled

#### GET /api/v1/posts/{id}
Get post status and tweet_id.

**Response**:
```json
{
  "id": 12345,
  "status": "posted",
  "tweet_id": "1234567890123456789",
  ...
}
```

#### GET /api/v1/posts/
List recent posts (latest 200).

**Response**:
```json
[
  { "id": 12345, ... },
  { "id": 12344, ... }
]
```

#### POST /api/v1/posts/{id}/cancel
Cancel a queued/scheduled post.

**Response**:
```json
{
  "id": 12345,
  "status": "cancelled",
  ...
}
```

---

## Error Scenarios

### Scenario 1: API Unreachable
**Symptoms**: Connection refused, timeout
**Action**: Warn user, provide manual posting instructions, continue release
**User Impact**: Low - release succeeds, just no automated X post

### Scenario 2: Post Created but Timeout Waiting for Publish
**Symptoms**: Poll loop exceeds 60 seconds
**Action**: Provide POST_ID for manual status check
**User Impact**: Medium - post may still succeed in background

### Scenario 3: Post Failed with Error
**Symptoms**: API returns status="failed" with error_reason
**Action**: Display error, provide manual posting fallback
**User Impact**: Medium - user must post manually

### Scenario 4: Main Post Succeeds but Reply Fails
**Symptoms**: First tweet posted, second fails
**Action**: Show main tweet URL, prompt user to reply manually
**User Impact**: Low - main announcement visible, just missing automated reply

---

## Integration Points

### Used By
- `.claude/commands/release.md` - Final step after npm publish

### Dependencies
- `jq` - JSON parsing (required)
- `curl` - HTTP requests (required)
- Network access to `http://5.161.75.135:8080/`

### Environment Variables
None required (API has no auth).

---

## Testing

**Manual Test**:
```bash
# Test API connectivity
curl -s http://5.161.75.135:8080/api/v1/posts/ | jq

# Test post creation (use test content)
curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test post from Spec-Flow skill", "scheduled_at": null}' | jq

# Test threaded reply (replace TWEET_ID with actual ID from previous post)
curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test reply", "scheduled_at": null, "in_reply_to_tweet_id": "TWEET_ID"}' | jq

# Get post status
curl -s http://5.161.75.135:8080/api/v1/posts/12345 | jq
```

---

## Notes

- **Character Limit**: Always validate ≤280 characters before posting
- **Emojis Count**: Emojis count as 2 characters in Twitter's system
- **Links**: X auto-shortens links to 23 characters (t.co)
- **Threaded Replies**: Use `in_reply_to_tweet_id` to create proper tweet threads
- **Trailing Slash**: Always include trailing slash on collection endpoints to avoid redirects
- **Polling Interval**: 3 seconds is respectful; don't poll faster
- **Network Isolation**: API base URL should never be committed to public repos or exposed in docs

---

## Future Enhancements

- [ ] Support for media uploads (images/GIFs)
- [ ] Thread support (multiple connected tweets)
- [ ] Hashtag suggestions based on release type
- [ ] Analytics tracking (impressions, engagement)
- [ ] Integration with /finalize for post-release announcements

# X Poster API Reference

## Base URL
```
http://5.161.75.135:8080/
```

**Network**: Internal VPS only (no public DNS)
**Protocol**: HTTP (internal network, no TLS required)
**Authentication**: None (IP-restricted)

---

## Endpoints

### POST /api/v1/posts/

Create a new post (tweet) or threaded reply.

**Request:**
```http
POST /api/v1/posts/ HTTP/1.1
Host: 5.161.75.135:8080
Content-Type: application/json

{
  "content": "Tweet text (max 280 chars)",
  "scheduled_at": null,
  "in_reply_to_tweet_id": "1234567890" | null
}
```

**Request Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | string | Yes | Tweet text, max 280 characters |
| `scheduled_at` | string\|null | Yes | ISO 8601 timestamp or null for immediate |
| `in_reply_to_tweet_id` | string\|null | No | Tweet ID to reply to (for threading) |

**Response (Success):**
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 12345,
  "content": "Tweet text",
  "status": "queued",
  "tweet_id": null,
  "error_reason": null,
  "created_at": "2025-01-15T10:30:00Z",
  "scheduled_at": null,
  "posted_at": null,
  "in_reply_to_tweet_id": null
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Internal post ID (used for polling) |
| `content` | string | Submitted tweet text |
| `status` | string | Current status (see status values below) |
| `tweet_id` | string\|null | X tweet ID (available when status=posted) |
| `error_reason` | string\|null | Error message if status=failed |
| `created_at` | string | ISO 8601 timestamp |
| `scheduled_at` | string\|null | Scheduled time if applicable |
| `posted_at` | string\|null | Actual post time when live |
| `in_reply_to_tweet_id` | string\|null | Parent tweet ID if threaded |

**Response (Error):**
```http
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Content exceeds 280 characters",
  "field": "content",
  "value_length": 312
}
```

---

### GET /api/v1/posts/{id}

Get post status and tweet_id after submission.

**Request:**
```http
GET /api/v1/posts/12345 HTTP/1.1
Host: 5.161.75.135:8080
```

**Response (Queued):**
```json
{
  "id": 12345,
  "content": "Tweet text",
  "status": "queued",
  "tweet_id": null,
  "error_reason": null,
  "created_at": "2025-01-15T10:30:00Z",
  "posted_at": null
}
```

**Response (Posted):**
```json
{
  "id": 12345,
  "content": "Tweet text",
  "status": "posted",
  "tweet_id": "1234567890123456789",
  "error_reason": null,
  "created_at": "2025-01-15T10:30:00Z",
  "posted_at": "2025-01-15T10:30:05Z"
}
```

**Response (Failed):**
```json
{
  "id": 12345,
  "content": "Tweet text",
  "status": "failed",
  "tweet_id": null,
  "error_reason": "Rate limit exceeded (retry after 15min)",
  "created_at": "2025-01-15T10:30:00Z",
  "posted_at": null
}
```

---

### POST /api/v1/posts/{id}/cancel

Cancel a queued post before it posts.

**Request:**
```http
POST /api/v1/posts/12345/cancel HTTP/1.1
Host: 5.161.75.135:8080
```

**Response (Success):**
```json
{
  "id": 12345,
  "status": "cancelled",
  "message": "Post cancelled successfully"
}
```

**Response (Error - Already Posted):**
```http
HTTP/1.1 400 Bad Request

{
  "error": "Cannot cancel post with status 'posted'"
}
```

---

## Status Values

| Status | Description | tweet_id Available | Actions |
|--------|-------------|--------------------|---------|
| `queued` | Waiting in queue to post | No | Poll, Cancel |
| `posting` | Currently being posted | No | Poll |
| `posted` | Successfully posted to X | Yes | View tweet |
| `failed` | Post failed (see error_reason) | No | Retry, Debug |
| `cancelled` | Manually cancelled before posting | No | Recreate |

---

## Polling Strategy

### Recommended Approach
```bash
MAX_ATTEMPTS=20  # 60 seconds total (20 × 3s)
ATTEMPT=0
POLL_INTERVAL=3  # seconds

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  STATUS_RESPONSE=$(curl -s "http://5.161.75.135:8080/api/v1/posts/$POST_ID")

  POST_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
  TWEET_ID=$(echo "$STATUS_RESPONSE" | jq -r '.tweet_id // empty')

  if [ "$POST_STATUS" = "posted" ] && [ -n "$TWEET_ID" ]; then
    echo "✅ Posted successfully: $TWEET_ID"
    break
  elif [ "$POST_STATUS" = "failed" ]; then
    ERROR_REASON=$(echo "$STATUS_RESPONSE" | jq -r '.error_reason')
    echo "❌ Post failed: $ERROR_REASON"
    exit 1
  fi

  echo "⏳ Status: $POST_STATUS (attempt $((ATTEMPT + 1))/$MAX_ATTEMPTS)"
  ATTEMPT=$((ATTEMPT + 1))
  sleep $POLL_INTERVAL
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
  echo "⏱️ Timeout: Post did not complete within 60s"
  echo "Check status manually: http://5.161.75.135:8080/api/v1/posts/$POST_ID"
  exit 1
fi
```

### Polling Parameters
- **Interval**: 3 seconds (avoid hammering API)
- **Max Attempts**: 20 (60 seconds total)
- **Timeout Handling**: Provide manual check URL
- **Exponential Backoff**: Not needed (fixed 3s works well)

---

## Threaded Replies

### Creating a Reply Thread

**Step 1**: Post main tweet
```bash
MAIN_RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d '{"content": "Main tweet text", "scheduled_at": null}')

MAIN_POST_ID=$(echo "$MAIN_RESPONSE" | jq -r '.id')
```

**Step 2**: Poll for main tweet_id
```bash
# (Use polling logic above)
MAIN_TWEET_ID="1234567890123456789"  # Retrieved after polling
```

**Step 3**: Post reply with in_reply_to_tweet_id
```bash
REPLY_RESPONSE=$(curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"🔗 Release notes: https://github.com/marcusgoll/Spec-Flow/releases/tag/v2.7.0\",
    \"scheduled_at\": null,
    \"in_reply_to_tweet_id\": \"$MAIN_TWEET_ID\"
  }")

REPLY_POST_ID=$(echo "$REPLY_RESPONSE" | jq -r '.id')
```

**Step 4**: Poll for reply tweet_id
```bash
# (Use polling logic above)
REPLY_TWEET_ID="1234567890123456790"  # Retrieved after polling
```

### Thread Display

**X Thread Structure:**
```
┌─────────────────────────────────────┐
│ Main Tweet (tweet_id: 123...789)   │
│ 🚀 Spec-Flow v2.7.0 is here!        │
│ ✨ Features...                      │
└─────────────────────────────────────┘
           ↓ (threaded reply)
┌─────────────────────────────────────┐
│ Reply (tweet_id: 123...790)         │
│ 🔗 Release notes: https://...       │
└─────────────────────────────────────┘
```

**URLs:**
- Main: `https://x.com/username/status/{MAIN_TWEET_ID}`
- Reply: `https://x.com/username/status/{REPLY_TWEET_ID}`

---

## UTF-8 Encoding for Emojis

### Problem: Emojis Display as ??

When posting content with emojis using direct bash variable interpolation, emojis may render as `??` in the actual tweet:

**Broken approach:**
```bash
# ❌ This FAILS - emojis become ??
POST_CONTENT="🚀 Spec-Flow v2.7.0 is here!"
curl -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$POST_CONTENT\", \"scheduled_at\": null}"
```

**Root cause:** Direct bash variable interpolation with quoted strings doesn't preserve UTF-8 character encoding through the curl pipeline.

### Solution: Temp File + jq -Rs

Use a temporary file with `jq -Rs` for proper UTF-8 encoding:

**Working approach:**
```bash
# ✅ This WORKS - emojis preserved correctly
cat > /tmp/x-post.txt << 'EOF'
🚀 Spec-Flow v2.7.0 is here!
✨ One-command releases
🔄 Auto-close GitHub issues
EOF
POST_CONTENT=$(cat /tmp/x-post.txt | jq -Rs .)

# No quotes around $POST_CONTENT variable
curl -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": $POST_CONTENT, \"scheduled_at\": null}"
```

**Key details:**
1. Write emoji content to temp file (`/tmp/x-post.txt`)
2. Use `jq -Rs` flags:
   - `-R` (raw input): Treat input as raw text, not JSON
   - `-s` (slurp): Read entire input into single string
3. **No quotes** around `$POST_CONTENT` in curl `-d` parameter
4. `jq` handles JSON escaping and UTF-8 encoding automatically

### Example: Threaded Reply with Emojis

```bash
GITHUB_URL="https://github.com/marcusgoll/Spec-Flow/releases/tag/v${NEW_VERSION}"

# Write reply with emoji to temp file
cat > /tmp/reply.txt << EOF
🔗 Release notes: ${GITHUB_URL}
EOF
REPLY_CONTENT=$(cat /tmp/reply.txt | jq -Rs .)

# Post threaded reply
REPLY_RESPONSE=$(curl -s -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{\"content\": $REPLY_CONTENT, \"scheduled_at\": null, \"in_reply_to_tweet_id\": \"$TWEET_ID\"}")
```

**Note:** You can use single quotes in heredoc (`<< 'EOF'`) to prevent variable expansion, or regular heredoc (`<< EOF`) to allow variable substitution (like `${GITHUB_URL}` above).

---

## Error Codes

### HTTP Status Codes
| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | OK | GET successful |
| 201 | Created | POST successful |
| 400 | Bad Request | Invalid content length, malformed JSON |
| 404 | Not Found | Invalid post ID |
| 500 | Internal Server Error | API backend error |
| 503 | Service Unavailable | API down for maintenance |

### Application Error Reasons
| error_reason | Cause | Solution |
|--------------|-------|----------|
| "Rate limit exceeded (retry after Xmin)" | X API rate limit hit | Wait X minutes, retry |
| "Authentication failed" | X credentials expired | Refresh token (manual) |
| "Content exceeds 280 characters" | Tweet too long | Trim content |
| "Duplicate content detected" | Posting same text twice | Modify content slightly |
| "Parent tweet not found" | in_reply_to_tweet_id invalid | Verify parent tweet exists |
| "Network timeout" | X API unreachable | Check X status, retry |

---

## Rate Limits

### X API Limits (as of 2025)
- **Posts per 3h window**: 300 tweets
- **Posts per day**: 2400 tweets
- **Typical release usage**: 2 posts (main + reply)

**Impact**: Negligible for release announcements (2 posts << 300 limit)

### API Poster Limits
- **No explicit limit**: Internal tool, no throttling
- **Queue capacity**: ~1000 posts
- **Processing speed**: 1 post every ~2-3 seconds

---

## Dependencies

### Required Tools
```bash
# curl (HTTP requests)
curl --version  # Required: 7.0+

# jq (JSON parsing)
jq --version    # Required: 1.5+
```

### Network Requirements
- **Access**: VPS internal network (5.161.75.135)
- **Firewall**: Port 8080 must be accessible
- **DNS**: No DNS required (IP address)

### Verify Connectivity
```bash
# Test API reachability
curl -s http://5.161.75.135:8080/api/v1/posts/ \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"content": "test", "scheduled_at": null}' \
  | jq .

# Expected: 201 Created with post ID
```

---

## Complete Example Workflow

```bash
#!/bin/bash
set -e

API_BASE="http://5.161.75.135:8080"
NEW_VERSION="2.7.0"

# Step 1: Create main post
echo "📤 Posting main announcement..."
MAIN_POST=$(curl -s -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"🚀 Spec-Flow v${NEW_VERSION} is here!\n\n✨ One-command releases\n🔄 Auto-close GitHub issues\n🧹 Essential cleanup\n\nShip features faster.\",
    \"scheduled_at\": null
  }")

MAIN_POST_ID=$(echo "$MAIN_POST" | jq -r '.id')
echo "Main post ID: $MAIN_POST_ID"

# Step 2: Poll for main tweet ID
echo "⏳ Waiting for main post to publish..."
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  STATUS=$(curl -s "$API_BASE/api/v1/posts/$MAIN_POST_ID")

  POST_STATUS=$(echo "$STATUS" | jq -r '.status')
  MAIN_TWEET_ID=$(echo "$STATUS" | jq -r '.tweet_id // empty')

  if [ "$POST_STATUS" = "posted" ] && [ -n "$MAIN_TWEET_ID" ]; then
    echo "✅ Main post published!"
    break
  elif [ "$POST_STATUS" = "failed" ]; then
    ERROR=$(echo "$STATUS" | jq -r '.error_reason')
    echo "❌ Main post failed: $ERROR"
    exit 1
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done

# Step 3: Create GitHub link reply
echo "📤 Posting GitHub link as reply..."
GITHUB_URL="https://github.com/marcusgoll/Spec-Flow/releases/tag/v${NEW_VERSION}"
REPLY_POST=$(curl -s -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": \"🔗 Release notes: ${GITHUB_URL}\",
    \"scheduled_at\": null,
    \"in_reply_to_tweet_id\": \"$MAIN_TWEET_ID\"
  }")

REPLY_POST_ID=$(echo "$REPLY_POST" | jq -r '.id')
echo "Reply post ID: $REPLY_POST_ID"

# Step 4: Poll for reply tweet ID
echo "⏳ Waiting for reply to publish..."
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  STATUS=$(curl -s "$API_BASE/api/v1/posts/$REPLY_POST_ID")

  POST_STATUS=$(echo "$STATUS" | jq -r '.status')
  REPLY_TWEET_ID=$(echo "$STATUS" | jq -r '.tweet_id // empty')

  if [ "$POST_STATUS" = "posted" ] && [ -n "$REPLY_TWEET_ID" ]; then
    echo "✅ Reply published!"
    break
  elif [ "$POST_STATUS" = "failed" ]; then
    ERROR=$(echo "$STATUS" | jq -r '.error_reason')
    echo "⚠️ Reply failed: $ERROR"
    echo "Main post still visible"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done

# Step 5: Display results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 X Announcement Posted!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Main Post:"
echo "   https://x.com/username/status/$MAIN_TWEET_ID"
echo ""
if [ -n "$REPLY_TWEET_ID" ]; then
  echo "GitHub Link Reply:"
  echo "   https://x.com/username/status/$REPLY_TWEET_ID"
else
  echo "⚠️ Reply failed - manually post GitHub link"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

## Security Considerations

### IP Restriction
- API only accessible from VPS internal network
- No public internet exposure
- No authentication needed (network-level security)

### Content Sanitization
- **No user input**: Content generated from CHANGELOG only
- **Character validation**: 280-char limit enforced
- **No injection risk**: JSON properly escaped by curl

### Credential Storage
- X API credentials stored on API server (not in Spec-Flow)
- No credential exposure in Spec-Flow codebase
- API acts as proxy to X with managed credentials

---

## Troubleshooting

### Connection Refused
```bash
curl: (7) Failed to connect to 5.161.75.135 port 8080: Connection refused
```

**Cause**: API server down or firewall blocking
**Solution**:
1. Check API status: `ssh hetzner systemctl status x-poster`
2. Verify firewall: `ssh hetzner ufw status | grep 8080`
3. Restart if needed: `ssh hetzner systemctl restart x-poster`

### Timeout Waiting for tweet_id
```bash
⏱️ Timeout: Post did not complete within 60s
```

**Cause**: X API slow or API processing backlog
**Solution**:
1. Check status manually: `curl http://5.161.75.135:8080/api/v1/posts/{POST_ID}`
2. If status=posted, extract tweet_id
3. If status=queued, wait longer or retry

### Rate Limit Error
```json
{
  "status": "failed",
  "error_reason": "Rate limit exceeded (retry after 15min)"
}
```

**Cause**: Posted too many tweets in 3h window
**Solution**: Wait 15 minutes, retry. For releases, this is unlikely (only 2 posts).

### Duplicate Content Detected
```json
{
  "status": "failed",
  "error_reason": "Duplicate content detected"
}
```

**Cause**: X blocks identical content posted twice
**Solution**: Modify post slightly (add timestamp, emoji variation, etc.)

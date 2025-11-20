# Error Scenarios and Handling Strategies

## Scenario 1: API Unreachable

### Symptoms
```bash
curl: (7) Failed to connect to 5.161.75.135 port 8080: Connection refused
```

### Root Causes
- API service stopped on VPS
- Firewall blocking port 8080
- Network routing issue
- VPS powered off

### Detection
```bash
# Test connectivity
if ! curl -s --connect-timeout 5 http://5.161.75.135:8080/api/v1/posts/ &>/dev/null; then
  echo "⚠️ API unreachable"
fi
```

### Handling Strategy

**Do NOT block release process**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  X Poster API Unavailable"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Release completed successfully, but X announcement could not be posted."
echo ""
echo "Generated post text:"
echo "─────────────────────────────────────────"
echo "$POST_CONTENT"
echo "─────────────────────────────────────────"
echo ""
echo "Manual posting option:"
echo "1. Copy the post text above"
echo "2. Post manually to X: https://x.com/compose"
echo "3. Reply with: 🔗 Release notes: https://github.com/marcusgoll/Spec-Flow/releases/tag/v${VERSION}"
echo ""
echo "Or debug API:"
echo "  ssh hetzner systemctl status x-poster"
echo "  ssh hetzner systemctl restart x-poster"
echo ""
echo "Release will continue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue with release summary (do not exit)
```

### User Actions
1. **Manual post**: Copy text, post via X web interface
2. **Debug API**: SSH to VPS, check service status
3. **Retry later**: Run `/announce-release` again after fix
4. **Skip**: Continue release without announcement

---

## Scenario 2: Post Creation Fails (400 Bad Request)

### Symptoms
```json
{
  "error": "Content exceeds 280 characters",
  "field": "content",
  "value_length": 312
}
```

### Root Causes
- Generated post text >280 characters
- Invalid JSON format
- Missing required fields
- Malformed content (invalid characters)

### Detection
```bash
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/api/v1/posts/" \
  -H "Content-Type: application/json" \
  -d "$POST_JSON")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" != "201" ]; then
  echo "❌ POST failed with HTTP $HTTP_CODE"
  echo "$BODY" | jq .
fi
```

### Handling Strategy

**Attempt auto-fix, fallback to manual**

```bash
# Validate content length before posting
CONTENT="$POST_CONTENT"
CONTENT_LENGTH=${#CONTENT}

if [ $CONTENT_LENGTH -gt 280 ]; then
  echo "⚠️ Content too long ($CONTENT_LENGTH chars), trimming..."

  # Strategy 1: Remove benefit statement
  CONTENT=$(echo "$CONTENT" | sed '$d')  # Remove last line
  CONTENT_LENGTH=${#CONTENT}

  if [ $CONTENT_LENGTH -gt 280 ]; then
    # Strategy 2: Remove 3rd feature
    CONTENT=$(echo "$CONTENT" | head -4)  # Keep only 2 features
    CONTENT_LENGTH=${#CONTENT}
  fi

  if [ $CONTENT_LENGTH -gt 280 ]; then
    # Strategy 3: Manual intervention required
    echo "❌ Cannot auto-trim to 280 chars"
    echo "Please edit manually:"
    echo "$CONTENT"
    exit 1
  fi

  echo "✅ Trimmed to $CONTENT_LENGTH chars"
fi

# Now attempt post with validated content
```

### User Actions
1. **Review generated post**: Check character count in preview
2. **Edit manually**: Use AskUserQuestion to get revised text
3. **Simplify features**: Reduce bullet points or shorten wording

---

## Scenario 3: Post Timeout (Tweet ID Never Received)

### Symptoms
```bash
⏱️ Timeout: Post did not complete within 60s (status: posting)
```

### Root Causes
- X API responding slowly
- API queue backlog
- Network latency spike
- API backend hung

### Detection
```bash
MAX_ATTEMPTS=20
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  # ... polling logic ...

  ATTEMPT=$((ATTEMPT + 1))
  sleep 3
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
  echo "⏱️ Timeout exceeded (60s)"
fi
```

### Handling Strategy

**Provide status check URL, continue release**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏱️  Post Timeout (60s exceeded)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Post may still succeed in background."
echo ""
echo "Check status manually:"
echo "  curl http://5.161.75.135:8080/api/v1/posts/$POST_ID | jq ."
echo ""
echo "If status='posted', retrieve tweet_id:"
echo "  TWEET_ID=\$(curl -s http://5.161.75.135:8080/api/v1/posts/$POST_ID | jq -r '.tweet_id')"
echo "  echo \"https://x.com/username/status/\$TWEET_ID\""
echo ""
echo "Release will continue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue with release (do not block)
```

### User Actions
1. **Wait longer**: Check status in 2-3 minutes
2. **Manual check**: Run curl command to get status
3. **Retry**: If status=failed, retry post
4. **Skip**: Continue without announcement if unresolved

---

## Scenario 4: Main Post Succeeds, Reply Fails

### Symptoms
```bash
✅ Main post successful!
❌ Reply post failed: Rate limit exceeded
```

### Root Causes
- Hit X API rate limit after main post
- Reply timeout (slower than main)
- Parent tweet ID invalid
- Network issue during reply

### Detection
```bash
# Main post succeeded
MAIN_TWEET_ID="1234567890"

# Reply post attempt
REPLY_RESPONSE=$(curl -s -X POST "$API_BASE/api/v1/posts/" \
  -d "{..., \"in_reply_to_tweet_id\": \"$MAIN_TWEET_ID\"}")

REPLY_STATUS=$(echo "$REPLY_RESPONSE" | jq -r '.status')

if [ "$REPLY_STATUS" = "failed" ]; then
  ERROR=$(echo "$REPLY_RESPONSE" | jq -r '.error_reason')
  echo "⚠️ Reply failed: $ERROR"
fi
```

### Handling Strategy

**Main announcement visible, provide manual reply instructions**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Main Post Successful!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Main announcement posted:"
echo "   https://x.com/username/status/$MAIN_TWEET_ID"
echo ""
echo "⚠️  Reply post failed: $ERROR_REASON"
echo ""
echo "Manually reply to the main post with:"
echo "─────────────────────────────────────────"
echo "🔗 Release notes: https://github.com/marcusgoll/Spec-Flow/releases/tag/v${VERSION}"
echo "─────────────────────────────────────────"
echo ""
echo "1. Open: https://x.com/username/status/$MAIN_TWEET_ID"
echo "2. Click 'Reply'"
echo "3. Paste the text above"
echo "4. Tweet"
echo ""
echo "Release will continue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue (main post is sufficient)
```

### Impact Assessment
- **Severity**: LOW (main announcement visible)
- **User impact**: Minimal (one extra click to find release notes)
- **Mitigation**: Manual reply takes ~10 seconds

---

## Scenario 5: Duplicate Content Detected

### Symptoms
```json
{
  "status": "failed",
  "error_reason": "Duplicate content detected"
}
```

### Root Causes
- Retrying same release announcement twice
- Testing with same content
- X API deduplication triggered

### Detection
```bash
RESPONSE=$(curl -s "$API_BASE/api/v1/posts/$POST_ID")
ERROR=$(echo "$RESPONSE" | jq -r '.error_reason')

if [[ "$ERROR" == *"Duplicate"* ]]; then
  echo "❌ Duplicate content detected"
fi
```

### Handling Strategy

**Offer content variation or skip**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ Duplicate Content Detected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "X API rejected this post as duplicate content."
echo ""
echo "This usually happens when:"
echo "- Retrying same release announcement"
echo "- Testing with identical text"
echo ""
echo "Options:"
echo "1. Skip X announcement (release already announced)"
echo "2. Modify post slightly (add timestamp, emoji variation)"
echo "3. Check if previous post succeeded:"
echo "   https://x.com/username"
echo ""

# Prompt user for action
read -p "Continue? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ]; then
  echo "Skipping X announcement..."
fi
```

### User Actions
1. **Check X feed**: Verify if post already exists
2. **Skip**: Release already announced, no action needed
3. **Modify**: Add timestamp or emoji to make content unique

---

## Scenario 6: Rate Limit Exceeded

### Symptoms
```json
{
  "status": "failed",
  "error_reason": "Rate limit exceeded (retry after 15min)"
}
```

### Root Causes
- Posted 300+ tweets in 3h window
- Testing API extensively before release
- Multiple releases in short timeframe

### Detection
```bash
ERROR=$(echo "$RESPONSE" | jq -r '.error_reason')

if [[ "$ERROR" =~ "Rate limit" ]]; then
  # Extract retry time
  RETRY_AFTER=$(echo "$ERROR" | grep -oP '\d+(?=min)')
  echo "⏳ Rate limit hit, retry after ${RETRY_AFTER}min"
fi
```

### Handling Strategy

**Wait and retry, or manual fallback**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ X API Rate Limit Exceeded"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "X API rate limit reached (300 posts per 3h)."
echo ""
echo "Retry after: ${RETRY_AFTER} minutes"
echo ""
echo "Options:"
echo "1. Wait ${RETRY_AFTER}min, then retry:"
echo "   sleep $((RETRY_AFTER * 60)) && /announce-release"
echo ""
echo "2. Post manually now:"
echo "   https://x.com/compose"
echo ""
echo "Generated post text:"
echo "─────────────────────────────────────────"
echo "$POST_CONTENT"
echo "─────────────────────────────────────────"
echo ""
echo "Release will continue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### Prevention
- **Limit testing**: Use dry-run mode for testing
- **Batch releases**: Space out releases by >15min
- **Monitor usage**: Track daily post count

---

## Scenario 7: Network Timeout During Polling

### Symptoms
```bash
curl: (28) Connection timed out after 5000 milliseconds
```

### Root Causes
- VPS network congestion
- Firewall intermittent blocking
- DNS resolution delay
- API server overloaded

### Detection
```bash
STATUS_RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 \
  "$API_BASE/api/v1/posts/$POST_ID")

if [ -z "$STATUS_RESPONSE" ]; then
  echo "❌ Network timeout during polling"
fi
```

### Handling Strategy

**Retry with backoff, provide manual check**

```bash
RETRY_COUNT=0
MAX_RETRIES=3

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  STATUS_RESPONSE=$(curl -s --connect-timeout 5 "$API_BASE/api/v1/posts/$POST_ID")

  if [ -n "$STATUS_RESPONSE" ]; then
    break  # Success
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "⚠️ Network timeout, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
  sleep $((RETRY_COUNT * 2))  # Exponential backoff: 2s, 4s, 6s
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
  echo "❌ Network timeouts exceeded"
  echo "Manual check: curl http://5.161.75.135:8080/api/v1/posts/$POST_ID"
  echo "Release will continue..."
fi
```

---

## Scenario 8: Invalid Parent Tweet (Reply Fails)

### Symptoms
```json
{
  "status": "failed",
  "error_reason": "Parent tweet not found"
}
```

### Root Causes
- Main tweet was deleted before reply
- Wrong tweet_id passed to in_reply_to_tweet_id
- Main tweet posting failed silently
- Tweet ID extracted incorrectly

### Detection
```bash
REPLY_RESPONSE=$(curl -s -X POST "$API_BASE/api/v1/posts/" \
  -d "{..., \"in_reply_to_tweet_id\": \"$MAIN_TWEET_ID\"}")

ERROR=$(echo "$REPLY_RESPONSE" | jq -r '.error_reason')

if [[ "$ERROR" == *"Parent tweet not found"* ]]; then
  echo "❌ Parent tweet invalid: $MAIN_TWEET_ID"
fi
```

### Handling Strategy

**Verify main tweet, post reply standalone if needed**

```bash
echo "⚠️ Reply failed: Parent tweet not found"
echo ""
echo "Verifying main tweet..."

# Check if main tweet exists via API
MAIN_STATUS=$(curl -s "$API_BASE/api/v1/posts/$MAIN_POST_ID" | jq -r '.status')

if [ "$MAIN_STATUS" != "posted" ]; then
  echo "❌ Main tweet never posted (status: $MAIN_STATUS)"
  echo "Cannot create reply. Manual posting required."
else
  echo "✅ Main tweet exists: https://x.com/username/status/$MAIN_TWEET_ID"
  echo ""
  echo "Reply failed for unknown reason. Options:"
  echo "1. Post GitHub link as standalone tweet:"
  echo "   🔗 Release notes for Spec-Flow v${VERSION}: ${GITHUB_URL}"
  echo ""
  echo "2. Manually reply to main tweet"
fi
```

---

## Scenario 9: User Cancels During Confirmation

### Symptoms
User selects "Skip X announcement" during preview confirmation

### Handling Strategy

**Gracefully exit, continue release**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "X Announcement Skipped"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "No post created on X."
echo ""
echo "Generated post text (for reference):"
echo "─────────────────────────────────────────"
echo "$POST_CONTENT"
echo "─────────────────────────────────────────"
echo ""
echo "To post manually later:"
echo "1. https://x.com/compose"
echo "2. Paste text above"
echo "3. Reply with: 🔗 Release notes: $GITHUB_URL"
echo ""
echo "Release will continue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue without error
exit 0
```

---

## Scenario 10: API Returns Malformed JSON

### Symptoms
```bash
jq: parse error: Invalid numeric literal at line 1, column 10
```

### Root Causes
- API server returning HTML error page
- API backend crashed mid-response
- Network truncating response

### Detection
```bash
RESPONSE=$(curl -s "$API_BASE/api/v1/posts/$POST_ID")

if ! echo "$RESPONSE" | jq . &>/dev/null; then
  echo "❌ Malformed JSON response"
  echo "Raw response:"
  echo "$RESPONSE"
fi
```

### Handling Strategy

**Log raw response, retry, fallback**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  API Response Error"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "API returned malformed JSON. Raw response:"
echo "─────────────────────────────────────────"
echo "$RESPONSE"
echo "─────────────────────────────────────────"
echo ""
echo "Possible causes:"
echo "- API server error (check logs: ssh hetzner journalctl -u x-poster)"
echo "- Network issue (retry)"
echo ""
echo "Release will continue without X announcement."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Continue (do not block release)
```

---

## Error Handling Decision Tree

```
Error detected
│
├─ API unreachable (connection refused)?
│  └─ Show manual post instructions → Continue release
│
├─ Bad request (400)?
│  ├─ Content too long?
│  │  └─ Auto-trim → Retry → If fails: Manual edit
│  └─ Other validation error?
│     └─ Show error → Manual fix required
│
├─ Timeout (60s exceeded)?
│  └─ Provide status check URL → Continue release
│
├─ Main post OK, reply failed?
│  └─ Show main URL + manual reply instructions → Continue
│
├─ Duplicate content?
│  └─ Prompt: Skip or modify → Continue
│
├─ Rate limit?
│  └─ Show retry time OR manual post → Continue
│
├─ Network timeout during polling?
│  └─ Retry 3x with backoff → If fails: Manual check → Continue
│
├─ Invalid parent tweet (reply)?
│  └─ Verify main tweet → Suggest standalone or manual reply
│
├─ Malformed JSON?
│  └─ Log raw response → Manual investigation → Continue
│
└─ Unknown error?
   └─ Log full context → Provide debug commands → Continue
```

---

## Non-Blocking Principle

**Critical Rule**: X announcement failures MUST NOT block release process.

### Rationale
- Release artifacts (GitHub release, git tag, npm publish) already complete
- X announcement is promotional enhancement, not core deliverable
- Manual posting fallback always available
- User can retry `/announce-release` later

### Implementation
```bash
# ✅ GOOD: Warning + continue
if ! post_to_x; then
  echo "⚠️ X announcement failed, but release succeeded"
  echo "Manual post option: ..."
  # Continue with release summary
fi

# ❌ BAD: Error + exit
if ! post_to_x; then
  echo "❌ X announcement failed"
  exit 1  # BLOCKS RELEASE
fi
```

### Exception Handling Pattern
```bash
set +e  # Do not exit on error for X announcement section

# Attempt X announcement
if post_to_x; then
  echo "✅ X announcement successful"
else
  echo "⚠️ X announcement failed (release still succeeded)"
  show_manual_fallback
fi

set -e  # Re-enable exit on error for subsequent steps
```

---

## Testing Error Scenarios

### Simulate API Unreachable
```bash
# Temporarily block API port
ssh hetzner sudo ufw deny 8080

# Run release, verify graceful handling
/release

# Restore access
ssh hetzner sudo ufw allow 8080
```

### Simulate Rate Limit
```bash
# Post 300 times rapidly (hit limit)
for i in {1..300}; do
  curl -s -X POST "http://5.161.75.135:8080/api/v1/posts/" \
    -d "{\"content\": \"Test $i\", \"scheduled_at\": null}"
done

# Now attempt release announcement
/release  # Should handle rate limit gracefully
```

### Simulate Timeout
```bash
# Add artificial delay to API (backend)
# POST /api/v1/posts/ → sleep 120s before responding

# Run release
/release  # Should timeout, provide check URL, continue
```

### Simulate Malformed JSON
```bash
# Return invalid JSON from API
# Modify API to return: {"status": "posted", "tweet_id":}  # Invalid

# Run release
/release  # Should detect malformed JSON, log, continue
```

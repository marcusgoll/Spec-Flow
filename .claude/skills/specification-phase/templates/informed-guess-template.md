# Informed Guess Template

Copy-paste ready markdown templates for documenting assumptions in spec.md files.

## When to Use

Use informed guesses instead of `[NEEDS CLARIFICATION]` when:
- ✓ Industry-standard default exists
- ✓ Decision is non-critical (doesn't impact scope or security)
- ✓ Wrong guess is easily correctable later
- ✗ DON'T use for scope-defining decisions
- ✗ DON'T use for security/privacy critical choices
- ✗ DON'T use when no reasonable default exists

---

## Template: Performance Targets

```markdown
## Performance Targets (Assumed)

- API endpoints: <500ms response time (95th percentile)
- Frontend First Contentful Paint (FCP): <1.5s
- Frontend Time to Interactive (TTI): <3.0s
- Database queries: <100ms average
- Lighthouse Performance Score: ≥85
- Lighthouse Accessibility Score: ≥95

**Assumption**: Standard web application performance expectations applied. If specific requirements differ, specify in requirements section.
```

**Customize for**:
- Backend services: Focus on API response times and database query performance
- Frontend apps: Include Core Web Vitals (FCP, LCP, CLS, TTI)
- Mobile apps: Add app launch time, frame rate targets
- Data processing: Include throughput (records/second) and batch completion time

---

## Template: Data Retention

```markdown
## Data Retention (Assumed)

- User profiles: Indefinite (user can delete anytime via account settings)
- Application logs: 90 days rolling retention
- Analytics data: 365 days aggregated, then archived
- Temporary uploads: 24 hours, then auto-deleted
- Session data: 30 days inactive, then purged
- Error traces: 30 days, then archived

**Assumption**: GDPR-compliant data retention applied. Users control their own data. Logs retained for operational needs only.
```

**Customize for**:
- Financial data: May require 7+ years retention
- Healthcare: HIPAA compliance may require different timelines
- Temporary data: Adjust based on use case (uploads, tokens, cache)
- Audit logs: May require longer retention for compliance

---

## Template: Error Handling

```markdown
## Error Handling (Assumed)

- **User sees**: Friendly error message + Error ID (ERR-XXXX) for support reference
- **System logs**: Full error details + stack trace to error-log.md
- **Retry logic**: 3 attempts with exponential backoff (1s, 2s, 4s) for transient failures
- **Alerting**: Critical errors trigger monitoring alerts (Sentry, Datadog, etc.)
- **Graceful degradation**: Feature degrades to read-only or cached data when possible

**Assumption**: Standard error handling patterns applied. No sensitive data in user-facing error messages.
```

**Customize for**:
- User-facing errors: Specify exact error message text
- Critical failures: Define escalation path (page on-call, alert Slack)
- Retry behavior: Adjust for idempotent vs non-idempotent operations
- Offline support: Define offline behavior if applicable

---

## Template: Authentication Method

```markdown
## Authentication (Assumed)

- **User login**: OAuth2 (Google, GitHub) for external users
- **API access**: JWT bearer tokens (RS256 signature)
- **Sessions**: Secure cookies with HttpOnly, SameSite=Strict, 30-day expiry
- **MFA**: Optional for users, required for admin accounts
- **Password requirements**: 12+ characters, complexity enforced

**Assumption**: Standard OAuth2 flow for user authentication. API tokens follow JWT best practices.
```

**Customize for**:
- SSO integration: Replace OAuth2 with SAML or OIDC
- API-only apps: Remove user login section
- Internal tools: May use session-based auth only
- High-security: Require MFA for all users, not just admins

---

## Template: Rate Limiting

```markdown
## Rate Limits (Assumed)

- **User actions**: 100 requests/minute per authenticated user
- **Anonymous actions**: 20 requests/minute per IP address
- **Bulk operations**: 10 operations/hour per user (exports, batch updates)
- **API endpoints**: 1000 requests/minute per API key
- **Email sends**: 50 emails/hour per user

**Assumption**: Conservative rate limits to prevent abuse while allowing normal usage. Exceeded limits return HTTP 429 with Retry-After header.
```

**Customize for**:
- Public APIs: Define per-tier limits (free/pro/enterprise)
- Real-time features: Higher limits for WebSocket/polling
- Batch operations: Adjust based on resource intensity
- Email/SMS: Align with provider limits (SendGrid, Twilio)

---

## Template: Integration Patterns

```markdown
## Integration Patterns (Assumed)

- **API style**: RESTful (HTTP/JSON) unless GraphQL explicitly needed
- **Data format**: JSON for APIs, CSV for exports
- **Pagination**: Offset/limit with max 100 items per page
- **Versioning**: URL-based versioning (/api/v1/...)
- **CORS**: Allowed from same domain + configured allowlist
- **Compression**: Gzip enabled for responses >1KB

**Assumption**: Standard REST API conventions applied. GraphQL only if requirements specifically need it.
```

**Customize for**:
- GraphQL APIs: Replace REST section with GraphQL schema approach
- Webhooks: Add webhook retry logic and signature validation
- Batch APIs: Define bulk operation endpoints
- Real-time: Add WebSocket or Server-Sent Events section

---

## Template: File Upload Constraints

```markdown
## File Upload Constraints (Assumed)

- **Max file size**: 50MB per upload
- **Allowed types**: Images (PNG, JPG, GIF), Documents (PDF, DOCX), Data (CSV, JSON)
- **Validation**: File type validated by MIME type + file signature (magic bytes)
- **Storage**: Cloud storage (S3, GCS, Azure Blob) with CDN for public files
- **Virus scanning**: All uploads scanned before processing
- **Retention**: Temporary uploads deleted after 24 hours, permanent files retained per data retention policy

**Assumption**: Standard file upload security applied. MIME type + magic byte validation prevents malicious uploads.
```

**Customize for**:
- Large files: Adjust max size (video uploads may need 500MB+)
- Restricted types: Limit to specific formats (images only, PDFs only)
- Processing: Add image resizing, thumbnail generation
- Security: Add watermarking, DRM for sensitive content

---

## Template: Notification Preferences

```markdown
## Notification Preferences (Assumed)

- **Delivery channels**: Email (primary), SMS (optional), push (optional)
- **Default state**: Email notifications enabled, SMS/push disabled
- **Unsubscribe**: Users can disable any notification type via settings
- **Frequency**: Real-time for critical alerts, daily digest for updates
- **Templates**: HTML + plain text for email, character limits for SMS

**Assumption**: Email notifications enabled by default. Users opt-in for SMS/push to reduce costs.
```

**Customize for**:
- B2B apps: May default all notifications on
- High-volume apps: Offer frequency controls (real-time, hourly, daily)
- Multi-channel: Define routing rules (critical → SMS, updates → email)
- Compliance: Add consent tracking for GDPR/CAN-SPAM

---

## Template: Accessibility Standards

```markdown
## Accessibility (Assumed)

- **Standard**: WCAG 2.1 Level AA compliance
- **Screen readers**: Full keyboard navigation, ARIA labels on interactive elements
- **Color contrast**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Focus indicators**: Visible focus states on all interactive elements
- **Form validation**: Error messages announced to screen readers
- **Lighthouse score**: Accessibility score ≥95

**Assumption**: WCAG 2.1 AA applied as baseline. Exceptions documented explicitly if needed.
```

**Customize for**:
- Public sector: May require WCAG 2.1 AAA or Section 508
- Multimedia: Add caption and transcript requirements
- Forms: Define specific error message patterns
- Testing: Define screen reader testing scope (NVDA, JAWS, VoiceOver)

---

## Template: Internationalization (i18n)

```markdown
## Internationalization (Assumed)

- **Default language**: English (US)
- **Supported languages**: English (US) only in initial release
- **Date/time**: ISO 8601 format, user's timezone detected from browser
- **Currency**: USD only in initial release
- **Number formatting**: Locale-specific (commas vs periods for thousands)
- **Text direction**: LTR (left-to-right) only initially

**Assumption**: Single-language initial release. i18n infrastructure built to support future languages.
```

**Customize for**:
- Multi-language apps: List all supported languages and translation approach
- Global apps: Define currency conversion and date/time handling
- RTL support: Add right-to-left layout for Arabic, Hebrew
- Content translation: Define translation workflow (human vs machine)

---

## Template: Caching Strategy

```markdown
## Caching Strategy (Assumed)

- **Browser cache**: Static assets cached for 1 year (immutable)
- **API responses**: 5-minute TTL for frequently accessed data
- **Database cache**: Redis for session data and hot queries
- **CDN**: CloudFront/Cloudflare for static assets and public content
- **Invalidation**: Cache invalidation on data updates via event bus

**Assumption**: Aggressive caching for static assets, conservative for dynamic data. Cache invalidation prevents stale data.
```

**Customize for**:
- Real-time apps: Reduce or eliminate caching for dynamic data
- High-traffic: Add application-level cache (Memcached, Redis)
- Offline support: Define service worker caching strategy
- API: Add cache headers (ETag, Last-Modified) for conditional requests

---

## Template: Search Functionality

```markdown
## Search Functionality (Assumed)

- **Search type**: Full-text search with fuzzy matching
- **Results**: Paginated (20 per page), relevance-ranked
- **Filters**: Support for common filters (date range, category, status)
- **Performance**: Results returned in <1 second for 95th percentile
- **Highlighting**: Search terms highlighted in results
- **Autocomplete**: Suggestions shown after 3 characters typed

**Assumption**: Full-text search using database capabilities (PostgreSQL full-text) or search service (Elasticsearch, Algolia) if needed.
```

**Customize for**:
- Simple search: Use exact match or LIKE queries for small datasets
- Advanced search: Add faceted search, boolean operators, field-specific queries
- Performance: Define indexing strategy and reindexing frequency
- Autocomplete: Define suggestion source (static list vs dynamic queries)

---

## How to Apply Templates

1. **Copy relevant template** sections to your spec.md
2. **Customize values** to match your specific requirements
3. **Remove irrelevant sections** (e.g., remove i18n if single-language app)
4. **Add to spec.md** under appropriate heading (e.g., "## Technical Assumptions")
5. **Reference in success criteria** if testable (e.g., "Lighthouse score ≥95")

## Template Usage Example

**Bad** (no assumptions documented):
```markdown
## Requirements

- Users can upload files
- System sends notifications
- Search returns results
```

**Good** (assumptions documented):
```markdown
## Requirements

- Users can upload files (see File Upload Constraints below)
- System sends notifications (see Notification Preferences below)
- Search returns results (see Search Functionality below)

## File Upload Constraints (Assumed)

- Max file size: 50MB per upload
- Allowed types: Images (PNG, JPG), Documents (PDF)
- Validation: MIME type + magic byte validation

**Assumption**: Standard file upload security applied. Users notified of file size limits before upload.

## Notification Preferences (Assumed)

- Delivery channels: Email (primary)
- Default state: Email enabled
- Unsubscribe: Users can disable via settings

**Assumption**: Email notifications enabled by default. Users opt-in for additional channels.

## Search Functionality (Assumed)

- Search type: Full-text with fuzzy matching
- Results: 20 per page, relevance-ranked
- Performance: <1 second for 95th percentile

**Assumption**: Full-text search using PostgreSQL capabilities. Elasticsearch if performance requirements not met.
```

---

_Template usage increases spec completeness while reducing unnecessary clarifications._

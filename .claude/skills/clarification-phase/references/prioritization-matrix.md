<prioritization_matrix>

<table_of_contents>
**Quick Navigation**:
- [Priority Levels](#priority_levels) - Critical/High/Medium/Low definitions
- [Categorization Rules](#categorization_rules) - How to categorize each clarification
- [Decision Matrix](#decision_matrix) - Quick reference table
- [Examples by Category](#examples) - Real-world categorization examples
</table_of_contents>

<priority_levels>

<level priority="critical">
**Critical Priority** (Always Ask)

**Definition**: Questions that fundamentally affect scope, security, or introduce breaking changes

**Characteristics**:
- Changes feature boundary (what's included vs excluded)
- Affects security/privacy model (data handling, access control, encryption)
- Introduces breaking changes to existing systems (API changes, schema changes)
- Determines fundamental architecture (monolith vs microservices, SQL vs NoSQL)

**Target audience impact**: Product owners, stakeholders, compliance teams

**Ask threshold**: Always ask, no matter how many Critical questions exist

**Examples**:
- "Does this feature include admin dashboard?" (scope boundary)
- "Should PII be encrypted at rest?" (security/privacy)
- "Can we change API response format from XML to JSON?" (breaking change)
- "Should we support real-time updates or batch processing?" (fundamental architecture)
</level>

<level priority="high">
**High Priority** (Ask if Ambiguous)

**Definition**: Questions that significantly affect user experience or functionality tradeoffs, but have no obvious default

**Characteristics**:
- User-facing decisions (UI/UX patterns, interaction models)
- Functionality tradeoffs (feature richness vs implementation cost)
- Integration patterns (sync vs async, REST vs GraphQL)
- Multi-option scenarios with no clear winner

**Target audience impact**: Product managers, designers, power users

**Ask threshold**: Ask if >2 viable options with different UX implications, defer if reasonable default exists

**Examples**:
- "Should profile editing use modal dialog or new page?" (UX decision)
- "Export format: One-click CSV or multi-format selection?" (functionality tradeoff)
- "Notification delivery: Email only or email + in-app + push?" (integration complexity)
</level>

<level priority="medium">
**Medium Priority** (Document as Assumption)

**Definition**: Questions with industry-standard defaults or can be deferred to planning/implementation phase

**Characteristics**:
- Performance targets with standard benchmarks (response time, throughput)
- Technical stack choices (library selection, framework versions)
- Configuration defaults (cache duration, retry logic)
- Has reasonable industry standard

**Target audience impact**: Engineering team, ops team

**Ask threshold**: Never ask during /clarify (defer to /plan or document assumption)

**Examples**:
- "What response time target?" → Assume <500ms (industry standard)
- "Which date library?" → Defer to /plan (technical decision)
- "Cache duration?" → Assume 10 minutes (reasonable default)
- "Database connection pool size?" → Defer to /plan (can tune later)
</level>

<level priority="low">
**Low Priority** (Document as Assumption)

**Definition**: Questions with trivial impact or obvious standards

**Characteristics**:
- Error message wording (use standard patterns)
- Rate limiting values (use conservative defaults)
- Field validation rules (use standard patterns)
- Cosmetic decisions with minimal user impact

**Target audience impact**: Individual developers

**Ask threshold**: Never ask (always use standard/default)

**Examples**:
- "Error message: 'Invalid input' or 'Please check your input'?" → Standard pattern
- "Rate limit: 100/min or 200/min?" → Conservative default (100/min)
- "Email validation: RFC 5322 strict or permissive?" → Standard (permissive)
- "Max filename length?" → Standard (255 characters)
</level>

</priority_levels>

<categorization_rules>

<rule category="scope_boundary">
**Scope Boundary Questions**

Priority: **Critical**

Indicators:
- Mentions "include", "exclude", "scope", "MVP"
- Defines what's in vs out of feature
- Affects roadmap or future iterations

How to identify:
- Ask: "Does the answer change what we're building vs what we're NOT building?"
- If yes → Critical

Examples:
- "Does student dashboard include parent access?" → Critical (expands scope)
- "Should we support bulk operations?" → Critical (scope expansion)
- "Is offline mode required for MVP?" → Critical (scope decision)
</rule>

<rule category="security_privacy">
**Security/Privacy Questions**

Priority: **Critical**

Indicators:
- Mentions "security", "privacy", "encryption", "PII", "compliance", "GDPR", "HIPAA"
- Affects data handling or access control
- Legal/regulatory implications

How to identify:
- Ask: "Does this affect data security or privacy compliance?"
- If yes → Critical

Examples:
- "Should user emails be encrypted at rest?" → Critical (privacy)
- "Who can view deleted user data?" → Critical (access control)
- "Is GDPR compliance required?" → Critical (regulatory)
</rule>

<rule category="breaking_changes">
**Breaking Change Questions**

Priority: **Critical**

Indicators:
- Affects existing APIs, schemas, contracts
- Requires migration or version bump
- Mentions "change", "modify", "replace" for existing systems

How to identify:
- Ask: "Will this break existing integrations or require migration?"
- If yes → Critical

Examples:
- "Can we change POST /users API response schema?" → Critical (breaking change)
- "Should we rename 'userId' to 'id' in database?" → Critical (migration required)
- "Replace JWT auth with OAuth?" → Critical (auth change)
</rule>

<rule category="user_experience">
**User Experience Questions**

Priority: **High**

Indicators:
- Affects UI/UX patterns (modal vs page, tabs vs dropdown)
- User workflow decisions (steps in process, required vs optional)
- Visual/interaction design choices

How to identify:
- Ask: "Will users notice different UX between options?"
- If yes → High
- Ask: "Is there an obvious industry standard?"
- If no standard → High, if standard exists → Medium/Low

Examples:
- "Modal or new page for profile editing?" → High (no clear standard, different UX)
- "Tabs or accordion for settings sections?" → Medium (both standard, minor UX diff)
- "Confirm delete with dialog or inline?" → High (safety implications)
</rule>

<rule category="functionality_tradeoffs">
**Functionality Tradeoff Questions**

Priority: **High**

Indicators:
- Multiple options with different feature richness
- Cost vs value tradeoffs (basic vs advanced features)
- Time-to-market implications

How to identify:
- Ask: "Do options have significantly different implementation costs?"
- If yes + no clear default → High

Examples:
- "Export: CSV only (2d) or CSV+JSON+Excel (5d)?" → High (cost tradeoff)
- "Search: Exact match (1d) or fuzzy search (4d)?" → High (functionality vs cost)
- "Pagination: Simple (1d) or infinite scroll (3d)?" → High (UX + cost)
</rule>

<rule category="performance_targets">
**Performance Target Questions**

Priority: **Medium**

Indicators:
- Mentions "response time", "latency", "throughput", "concurrent users"
- Has industry standard benchmarks

How to identify:
- Ask: "Is there a standard performance target for this use case?"
- If yes → Medium (document standard)
- If critical business requirement (e.g., trading system) → High

Examples:
- "API response time target?" → Medium (assume <500ms industry standard)
- "Dashboard load time?" → Medium (assume <3s web standard)
- "High-frequency trading latency?" → High (critical business requirement, no standard)
</rule>

<rule category="technical_stack">
**Technical Stack Questions**

Priority: **Medium**

Indicators:
- Library/framework selection
- Database choice (when multiple options viable)
- Infrastructure decisions

How to identify:
- Ask: "Can this decision be deferred to /plan or /implement phase?"
- If yes → Medium
- Ask: "Does this fundamentally change architecture?"
- If yes → Critical

Examples:
- "React or Vue?" → Medium (defer to /plan if both viable)
- "PostgreSQL or MongoDB?" → Critical if affects data model, Medium if similar
- "Winston or Bunyan for logging?" → Low (defer to /implement)
</rule>

<rule category="defaults_and_standards">
**Default Values/Standards Questions**

Priority: **Low**

Indicators:
- Configuration values (timeout, retry count, pool size)
- Format standards (date format, number format)
- Error messages, validation rules

How to identify:
- Ask: "Is there an obvious standard or conservative default?"
- If yes → Low

Examples:
- "Date format: ISO 8601 or MM/DD/YYYY?" → Low (use ISO 8601 standard)
- "Retry count: 3 or 5?" → Low (use 3, conservative default)
- "Error message wording?" → Low (use standard pattern)
- "Rate limit?" → Low (use 100/min conservative default)
</rule>

</categorization_rules>

<decision_matrix>

| Question Type | Priority | Ask? | Rationale | Default/Assumption |
|---------------|----------|------|-----------|-------------------|
| Scope boundary | Critical | ✅ Always | Affects feature roadmap | N/A - must ask |
| Security/Privacy | Critical | ✅ Always | Legal/compliance risk | N/A - must ask |
| Breaking changes | Critical | ✅ Always | Migration/versioning required | N/A - must ask |
| User experience | High | ✅ If no standard | Significant UX impact | Use industry standard if exists |
| Functionality tradeoffs | High | ✅ If ambiguous | Cost vs value decision | Use minimal viable if unclear |
| Integration patterns | High | ✅ If multiple viable | Architecture implications | Defer to /plan if standard |
| Performance targets | Medium | ❌ Document | Industry standards exist | <500ms API, <3s page load |
| Technical stack | Medium | ❌ Defer /plan | Engineering decision | Defer to /plan phase |
| Configuration values | Low | ❌ Document | Conservative defaults | Retry=3, timeout=30s, pool=10 |
| Error messages | Low | ❌ Document | Standard patterns exist | Use standard wording |
| Rate limits | Low | ❌ Document | Conservative defaults | 100 req/min per user |
| Format standards | Low | ❌ Document | Industry standards | ISO 8601 dates, UTF-8 encoding |

</decision_matrix>

<examples>

<example scenario="user_dashboard">
**Scenario**: Student progress dashboard feature

**Clarifications found**: 7 items

**Categorization**:

1. "Does dashboard include parent access?" → **Critical** (scope boundary)
   - Decision: Ask (changes feature scope significantly)

2. "Which metrics to display?" → **High** (functionality tradeoff)
   - Options: A) Completion only, B) Completion + time, C) Full analytics
   - Decision: Ask (no clear default, significant cost difference)

3. "Modal or new page for editing?" → **High** (UX decision)
   - Decision: Ask (different UX implications, no standard for this context)

4. "Dashboard refresh rate?" → **Medium** (performance target)
   - Decision: Document assumption (assume 5-minute auto-refresh, standard)

5. "Export format?" → **Low** (standard exists)
   - Decision: Document assumption (CSV, industry standard for tabular data)

6. "Rate limiting?" → **Low** (conservative default)
   - Decision: Document assumption (100 requests/min, conservative)

7. "Error message for no data?" → **Low** (standard pattern)
   - Decision: Document assumption ("No data available", standard wording)

**Result**:
- **Ask**: 3 questions (Critical: 1, High: 2)
- **Document**: 4 assumptions (Medium: 1, Low: 3)
</example>

<example scenario="api_export">
**Scenario**: Data export API endpoint

**Clarifications found**: 5 items

**Categorization**:

1. "Which fields to export?" → **Critical** (scope boundary)
   - No reasonable default (PII concerns, user expectations vary)
   - Decision: Ask with options (All fields, Public only, Custom selection)

2. "API rate limiting?" → **Low** (conservative default)
   - Decision: Document assumption (50 exports/hour, conservative to prevent abuse)

3. "Export file size limit?" → **Low** (standard default)
   - Decision: Document assumption (50MB max, standard)

4. "Background job or sync?" → **High** (UX + architecture)
   - Options affect user experience (wait vs poll) and infrastructure
   - Decision: Ask (different implications, no clear default)

5. "Email notification when ready?" → **Low** (optional feature)
   - Decision: Document assumption (optional, user can enable in settings)

**Result**:
- **Ask**: 2 questions (Critical: 1, High: 1)
- **Document**: 3 assumptions (Low: 3)
</example>

<example scenario="authentication">
**Scenario**: User authentication system

**Clarifications found**: 6 items

**Categorization**:

1. "OAuth or custom auth?" → **Critical** (security/architecture)
   - Different security models, user experience, compliance implications
   - Decision: Ask

2. "Support MFA?" → **Critical** (security)
   - Security requirement, compliance implications
   - Decision: Ask

3. "Session duration?" → **Medium** (security default)
   - Industry standard: 30 minutes activity timeout, 24-hour absolute
   - Decision: Document assumption

4. "Password strength requirements?" → **Medium** (security standard)
   - Industry standard: min 8 chars, 1 uppercase, 1 number, 1 special
   - Decision: Document assumption (standard NIST guidelines)

5. "Failed login lockout?" → **Medium** (security default)
   - Industry standard: 5 failed attempts, 15-minute lockout
   - Decision: Document assumption

6. "Remember me checkbox?" → **Low** (optional UX feature)
   - Decision: Document assumption (yes, standard practice)

**Result**:
- **Ask**: 2 questions (Critical: 2)
- **Document**: 4 assumptions (Medium: 3, Low: 1)
</example>

</examples>

<quick_reference>

**When in doubt, use this flow**:

1. **Ask**: "Will this affect feature scope, security, or break existing systems?"
   - Yes → **Critical** (ask always)

2. **Ask**: "Are there multiple viable options with different UX/cost implications?"
   - Yes + no clear default → **High** (ask if ambiguous)
   - Yes + clear default exists → **Medium** (document default)

3. **Ask**: "Is there an industry standard or conservative default?"
   - Yes → **Low** (document assumption)
   - No but can defer to /plan → **Medium** (defer decision)

4. **Target**: ≤3 questions per feature (Critical + High only)

</quick_reference>

</prioritization_matrix>

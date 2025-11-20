<overview>
Contextual clarification questions for feature specifications, organized by ambiguity category.
Use AskUserQuestion tool with these templates to resolve specification gaps.

**Converting YAML to AskUserQuestion format**:
```javascript
// YAML template:
header: "Metrics"
question: "What should we display?"
options:
  - "Completion only" - Basic insights (2 days)
  - "Completion + time" - Actionable insights (4 days)

// Converts to:
AskUserQuestion({
  questions: [{
    question: "spec.md:LINE mentions X. What should we display?",
    header: "Metrics",
    multiSelect: false,
    options: [
      { label: "Completion only", description: "Basic insights (2 days)" },
      { label: "Completion + time", description: "Actionable insights (4 days)" }
    ]
  }]
})
```

Add spec.md reference to question text, set multiSelect based on context, include costs in description.
</overview>

<universal_questions>

<baseline_understanding>
When spec has fundamental gaps:
```yaml
header: "Baseline"
question: "What's the core purpose of this feature?"
options:
  - "New capability" - Adding net-new functionality
  - "Enhancement" - Improving existing feature
  - "Fix/refactor" - Addressing technical debt or bugs
  - "Integration" - Connecting to external system
```
</baseline_understanding>

<user_story_validation>
When user stories lack clarity:
```yaml
header: "User Story"
question: "Who is the primary user for this feature?"
options:
  - "End users" - Customer-facing functionality
  - "Internal team" - Admin/ops tools
  - "Developers" - API/SDK/tooling
  - "System/automated" - Background jobs, cron tasks
```
</user_story_validation>

</universal_questions>

<architecture_questions>

<component_placement>
When architecture unclear:
```yaml
header: "Architecture"
question: "Where does this functionality live?"
options:
  - "Backend API" - Server-side logic, new endpoints
  - "Frontend UI" - User interface components
  - "Shared library" - Reusable across services
  - "Background worker" - Async processing, jobs
```
</component_placement>

<integration_pattern>
When system boundaries unclear:
```yaml
header: "Integration"
question: "How does this integrate with existing systems?"
options:
  - "REST API" - HTTP endpoints (GET/POST/PUT/DELETE)
  - "GraphQL" - Query/mutation via GraphQL layer
  - "Event-driven" - Pub/sub, message queues
  - "Direct DB access" - Shared database integration
```
</integration_pattern>

<scalability_requirements>
When scale unclear:
```yaml
header: "Scale"
question: "What scale requirements should we plan for?"
options:
  - "Low (<100 users)" - Prototype, internal tool
  - "Medium (100-10k users)" - Growing product
  - "High (10k-100k users)" - Established product
  - "Very high (100k+ users)" - Large-scale, needs sharding
```
</scalability_requirements>

</architecture_questions>

<data_model_questions>

<entity_identification>
When data model unclear:
```yaml
header: "Data Model"
question: "What new data entities are needed?"
options:
  - "New tables" - Creating new database tables
  - "New columns" - Extending existing tables
  - "Relationships" - Foreign keys, associations
  - "No schema changes" - Using existing data only
multiSelect: true
```
</entity_identification>

<persistence_strategy>
When storage unclear:
```yaml
header: "Storage"
question: "How should data be persisted?"
options:
  - "PostgreSQL" - Relational database (ACID transactions)
  - "MongoDB" - Document database (flexible schema)
  - "Redis" - In-memory cache/session store
  - "File storage" - S3/blob storage for uploads
```
</persistence_strategy>

<migration_requirements>
When existing data affected:
```yaml
header: "Migration"
question: "Will this require data migration?"
options:
  - "No migration" - Additive changes only
  - "Schema migration" - ALTER TABLE, new indexes
  - "Data backfill" - Populate new columns with values
  - "Breaking change" - Requires downtime/coordination
```
</migration_requirements>

</data_model_questions>

<technical_approach_questions>

<technology_choice>
When tech stack unclear:
```yaml
header: "Technology"
question: "What technology should be used?"
options:
  - "Match existing" - Use current stack (from tech-stack.md)
  - "Introduce new" - New library/framework needed
  - "Multiple options" - Need to evaluate alternatives
```
</technology_choice>

<library_selection>
When dependencies unclear:
```yaml
header: "Dependencies"
question: "Are new libraries needed?"
options:
  - "Use existing" - Current dependencies sufficient
  - "Add specific library" - I know what's needed (specify via Other)
  - "Research needed" - Evaluate options first
```
</library_selection>

<implementation_patterns>
When coding approach unclear:
```yaml
header: "Patterns"
question: "What implementation pattern should be followed?"
options:
  - "Repository pattern" - Data access abstraction
  - "Service layer" - Business logic separation
  - "MVC" - Model-View-Controller
  - "Event sourcing" - Event-driven state management
  - "Follow existing patterns" - Match current codebase (from system-architecture.md)
```
</implementation_patterns>

</technical_approach_questions>

<api_design_questions>

<endpoint_design>
When API unclear:
```yaml
header: "API Design"
question: "How many API endpoints will be added?"
options:
  - "1-2 endpoints" - Simple CRUD or single action
  - "3-5 endpoints" - Standard resource with CRUD
  - "6+ endpoints" - Complex domain, multiple resources
```
</endpoint_design>

<api_contract>
When API shape unclear:
```yaml
header: "Contract"
question: "What's the API contract style?"
options:
  - "RESTful" - Resource-based (GET /users, POST /users/:id)
  - "RPC-style" - Action-based (POST /createUser, POST /updateUser)
  - "GraphQL" - Query/mutation with schema
  - "Follow api-strategy.md" - Match existing patterns
```
</api_contract>

<authentication>
When auth unclear:
```yaml
header: "Auth"
question: "What authentication is required?"
options:
  - "Public" - No authentication needed
  - "API key" - Simple API key validation
  - "JWT" - Token-based authentication
  - "OAuth 2.0" - Third-party OAuth flow
  - "Session-based" - Cookie-based sessions
```
</authentication>

<error_handling>
When error responses unclear:
```yaml
header: "Errors"
question: "How should errors be handled?"
options:
  - "RFC 7807" - Problem Details standard (recommended)
  - "Custom format" - Project-specific error schema
  - "Simple messages" - HTTP status + message string
  - "Follow api-strategy.md" - Match existing error format
```
</error_handling>

</api_design_questions>

<ui_ux_questions>

<screen_count>
When UI scope unclear:
```yaml
header: "UI Scope"
question: "How many screens/views are needed?"
options:
  - "Single screen" - One page/component
  - "2-3 screens" - Simple flow (login → dashboard)
  - "4-7 screens" - Medium complexity (onboarding wizard)
  - "8+ screens" - Large feature, consider breaking down
```
</screen_count>

<component_reuse>
When design system usage unclear:
```yaml
header: "Components"
question: "Should this use existing design system components?"
options:
  - "Reuse existing" - Use components from ui-inventory.md
  - "Create new" - New components needed (justify in plan)
  - "Mix" - Some reuse, some new components
```
</component_reuse>

<responsive_requirements>
When responsive design unclear:
```yaml
header: "Responsive"
question: "What responsive requirements?"
options:
  - "Desktop only" - No mobile support needed
  - "Responsive" - Works on mobile, tablet, desktop
  - "Mobile-first" - Optimized for mobile primarily
```
</responsive_requirements>

<accessibility_requirements>
When accessibility unclear:
```yaml
header: "Accessibility"
question: "What accessibility level is required?"
options:
  - "WCAG 2.1 AA" - Industry standard (recommended)
  - "WCAG 2.1 AAA" - Highest standard
  - "Basic" - Keyboard navigation and screen readers
  - "Follow accessibility-standards.md" - Match project standards
```
</accessibility_requirements>

</ui_ux_questions>

<security_questions>

<data_sensitivity>
When data classification unclear:
```yaml
header: "Data Sensitivity"
question: "What type of data is handled?"
options:
  - "Public" - No sensitive data
  - "Internal" - Company confidential
  - "PII" - Personally identifiable information
  - "PCI/PHI" - Payment/health data (compliance required)
multiSelect: true
```
</data_sensitivity>

<encryption_requirements>
When encryption unclear:
```yaml
header: "Encryption"
question: "What encryption is needed?"
options:
  - "At rest" - Database encryption, encrypted backups
  - "In transit" - HTTPS, TLS for all communication
  - "Both" - End-to-end encryption
  - "None" - Public data, no encryption needed
```
</encryption_requirements>

<authorization>
When permissions unclear:
```yaml
header: "Authorization"
question: "What authorization model?"
options:
  - "None" - All authenticated users have access
  - "Role-based" - Admin, user, guest roles
  - "Permission-based" - Granular permissions
  - "Resource-based" - Ownership (users can only edit their own data)
```
</authorization>

</security_questions>

<testing_questions>

<test_coverage>
When testing scope unclear:
```yaml
header: "Testing"
question: "What test coverage is required?"
options:
  - "Unit tests" - Individual functions/methods
  - "Integration tests" - API endpoints, database queries
  - "E2E tests" - Full user flows
  - "All" - Comprehensive coverage
multiSelect: true
```
</test_coverage>

<test_data>
When test fixtures unclear:
```yaml
header: "Test Data"
question: "How should test data be managed?"
options:
  - "Mock data" - In-memory, no real DB
  - "Test database" - Isolated test DB with fixtures
  - "Factories" - Generate test data programmatically
```
</test_data>

</testing_questions>

<performance_questions>

<performance_targets>
When performance unclear:
```yaml
header: "Performance"
question: "What performance targets?"
options:
  - "Best effort" - No specific requirements
  - "Sub-second" - < 1s response time
  - "Sub-100ms" - < 100ms response time
  - "Specific SLA" - I have exact requirements (specify via Other)
```
</performance_targets>

<caching_strategy>
When caching unclear:
```yaml
header: "Caching"
question: "Should data be cached?"
options:
  - "No caching" - Always fetch fresh data
  - "Client-side" - Browser cache, localStorage
  - "Server-side" - Redis, in-memory cache
  - "CDN" - Edge caching for static assets
```
</caching_strategy>

</performance_questions>

<deployment_questions>

<deployment_model>
When deployment unclear:
```yaml
header: "Deployment"
question: "How will this be deployed?"
options:
  - "Staging → Production" - Full staging validation
  - "Direct to production" - No staging environment
  - "Feature flag" - Deploy behind flag, enable later
  - "Follow deployment-strategy.md" - Match project deployment model
```
</deployment_model>

<rollback_strategy>
When rollback unclear:
```yaml
header: "Rollback"
question: "What's the rollback plan?"
options:
  - "Git revert" - Code rollback only
  - "Database rollback" - Reversible migrations required
  - "Feature flag toggle" - Instant disable via flag
  - "No rollback needed" - Additive changes only
```
</rollback_strategy>

</deployment_questions>

<dependencies_questions>

<external_dependencies>
When external systems involved:
```yaml
header: "External Deps"
question: "Does this depend on external systems?"
options:
  - "None" - Fully self-contained
  - "Third-party API" - Stripe, Twilio, SendGrid, etc.
  - "Internal service" - Other microservices
  - "Database" - Shared database dependency
multiSelect: true
```
</external_dependencies>

<dependency_reliability>
When external deps critical:
```yaml
header: "Reliability"
question: "What if external dependency fails?"
options:
  - "Fail gracefully" - Show error, don't break feature
  - "Retry with backoff" - Automatic retry logic
  - "Fallback" - Use cached/default data
  - "Circuit breaker" - Stop calling after N failures
```
</dependency_reliability>

</dependencies_questions>

<question_rules>
- Prioritize by ambiguity score - highest score categories first
- Ask 2-10 questions based on score (0-30: 2-3, 31-60: 4-5, 61+: 6-10)
- Batch related questions - max 3 per AskUserQuestion call
- Show precedent in descriptions - "Used in specs/002-auth"
- Always allow "Other" - user can provide custom answer
- Apply answers atomically - git checkpoint → update → commit
- Stop when ambiguity resolved - don't over-clarify
</question_rules>

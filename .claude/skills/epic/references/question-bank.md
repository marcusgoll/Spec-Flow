<overview>
Epic scoping questions for multi-sprint complex features.
Use AskUserQuestion tool with these templates for progressive refinement (8-9 questions total).
Flow: Initial scoping (2Q) → Scope refinement (2-3Q based on subsystems) → Success metrics (2Q) → Dependencies (2Q)
</overview>

<initial_scoping>

<business_goal>
First question - establish high-level intent:
```yaml
header: "Business Goal"
question: "What's the primary business goal for this epic?"
multiSelect: false
options:
  - label: "New capability"
    description: "Add net-new functionality not currently available"
  - label: "Major enhancement"
    description: "Significantly improve or expand existing feature"
  - label: "Technical foundation"
    description: "Infrastructure/platform work enabling future features"
  - label: "Integration"
    description: "Connect to external system or third-party service"
  - label: "Migration/modernization"
    description: "Replace legacy system or update tech stack"
```
</business_goal>

<subsystem_selection>
Second question - identify scope breadth:
```yaml
header: "Subsystems"
question: "Which subsystems are involved in this epic?"
multiSelect: true
options:
  - label: "Backend API"
    description: "Server-side logic, new endpoints, business rules"
  - label: "Frontend UI"
    description: "User-facing screens, components, interactions"
  - label: "Database"
    description: "Schema changes, migrations, data model evolution"
  - label: "Background jobs"
    description: "Async processing, scheduled tasks, workers"
  - label: "External integrations"
    description: "Third-party APIs, webhooks, OAuth providers"
  - label: "Infrastructure"
    description: "Deployment, monitoring, CI/CD, infrastructure as code"
```
</subsystem_selection>

</initial_scoping>

<scope_refinement>

<backend_scope>
If "Backend API" selected, ask:
```yaml
header: "Backend Scope"
question: "What backend work is required?"
multiSelect: true
options:
  - label: "New API endpoints"
    description: "RESTful/GraphQL routes for new functionality"
  - label: "Business logic"
    description: "Core domain logic, validation, calculations"
  - label: "Service layer"
    description: "New services, repositories, domain models"
  - label: "Authentication/authorization"
    description: "Auth flows, permissions, role management"
  - label: "Background processing"
    description: "Jobs, queues, async tasks"
```
</backend_scope>

<frontend_scope>
If "Frontend UI" selected, ask:
```yaml
header: "Frontend Scope"
question: "What frontend work is required?"
multiSelect: true
options:
  - label: "New screens/pages"
    description: "Full page routes with navigation"
  - label: "New components"
    description: "Reusable UI components (buttons, forms, cards)"
  - label: "State management"
    description: "Global state, context, data fetching"
  - label: "Form handling"
    description: "Complex forms with validation, multi-step wizards"
  - label: "Real-time updates"
    description: "WebSockets, polling, live data"
  - label: "Responsive design"
    description: "Mobile, tablet, desktop layouts"
```
</frontend_scope>

<database_scope>
If "Database" selected, ask:
```yaml
header: "Database Scope"
question: "What database work is required?"
multiSelect: true
options:
  - label: "New tables"
    description: "Create new entities/tables"
  - label: "Schema changes"
    description: "Alter existing tables (add/modify columns)"
  - label: "Relationships"
    description: "Foreign keys, joins, associations"
  - label: "Indexes"
    description: "Performance indexes for queries"
  - label: "Data migration"
    description: "Backfill, transform, or clean existing data"
  - label: "Performance tuning"
    description: "Query optimization, caching strategy"
```
</database_scope>

<integration_scope>
If "External integrations" selected, ask:
```yaml
header: "Integration Scope"
question: "Which external systems need integration?"
multiSelect: true
options:
  - label: "Payment processing"
    description: "Stripe, PayPal, payment gateway"
  - label: "Authentication provider"
    description: "Auth0, Clerk, Google OAuth, GitHub"
  - label: "Email/SMS"
    description: "SendGrid, Twilio, notification services"
  - label: "Cloud storage"
    description: "S3, Cloudinary, file upload services"
  - label: "Analytics"
    description: "Google Analytics, Mixpanel, telemetry"
  - label: "Other API"
    description: "Custom third-party REST/GraphQL API (specify in Other)"
```
</integration_scope>

</scope_refinement>

<success_metrics>

<measurement_approach>
How will success be measured?
```yaml
header: "Measurement"
question: "How should we measure success for this epic?"
multiSelect: true
options:
  - label: "User metrics"
    description: "Adoption rate, DAU/MAU, engagement"
  - label: "Business metrics"
    description: "Revenue, conversions, retention"
  - label: "Performance metrics"
    description: "Latency, throughput, error rates"
  - label: "Quality metrics"
    description: "Test coverage, code quality, tech debt reduction"
  - label: "Delivery metrics"
    description: "Velocity, cycle time, deployment frequency"
```
</measurement_approach>

<target_values>
What are the target values?
```yaml
header: "Targets"
question: "What are the target success values?"
multiSelect: false
options:
  - label: "Specific targets"
    description: "I have exact targets (e.g., <200ms latency, 80% adoption)"
  - label: "Directional goals"
    description: "Improve over baseline (e.g., faster than current, higher engagement)"
  - label: "Parity with competition"
    description: "Match or exceed competitor benchmarks"
  - label: "No specific targets"
    description: "Qualitative assessment only (works, doesn't crash)"
```

# If "Specific targets" selected, follow-up with text input:
# "Please specify your targets (e.g., 'API <200ms p95, 80% user adoption within 30 days')"
```
</target_values>

</success_metrics>

<dependencies_and_constraints>

<external_dependencies>
What external dependencies exist?
```yaml
header: "Dependencies"
question: "Does this epic depend on external factors?"
multiSelect: true
options:
  - label: "Other epics"
    description: "Blocked by or depends on other in-flight epics"
  - label: "Third-party APIs"
    description: "External service availability, API keys, vendor setup"
  - label: "Team availability"
    description: "Specific expertise needed, team member schedules"
  - label: "Infrastructure"
    description: "New servers, database provisioning, deployment slots"
  - label: "Legal/compliance"
    description: "Privacy review, legal approval, compliance audit"
  - label: "None"
    description: "Fully self-contained, no blockers"
```
</external_dependencies>

<constraints>
What constraints must be honored?
```yaml
header: "Constraints"
question: "What constraints must this epic respect?"
multiSelect: true
options:
  - label: "Time constraint"
    description: "Hard deadline (product launch, event, compliance)"
  - label: "Budget constraint"
    description: "Limited budget for infrastructure, third-party services"
  - label: "Team size constraint"
    description: "Limited developers available (solo, small team)"
  - label: "Technology constraint"
    description: "Must use specific tech stack, can't introduce new dependencies"
  - label: "Backward compatibility"
    description: "Cannot break existing features, APIs, or data"
  - label: "Performance constraint"
    description: "Strict latency, throughput, or resource usage limits"
  - label: "None"
    description: "No significant constraints"
```
</constraints>

</dependencies_and_constraints>

<complexity_assessment>

<technical_complexity>
Assess technical complexity after scoping:
```yaml
header: "Complexity"
question: "Based on the scope, what's the technical complexity?"
multiSelect: false
options:
  - label: "Low"
    description: "Straightforward implementation, well-understood patterns"
  - label: "Medium"
    description: "Some technical challenges, requires research or prototyping"
  - label: "High"
    description: "Novel technical work, architectural decisions, multiple unknowns"
  - label: "Very high"
    description: "Cutting-edge tech, major architectural changes, high uncertainty"
```

# This determines sprint breakdown strategy:
# Low: 1-2 sprints, minimal parallelization
# Medium: 2-3 sprints, some parallel work
# High: 3-5 sprints, significant parallelization
# Very high: 5+ sprints, extensive parallelization + research sprint
</technical_complexity>

<sprint_estimate>
Rough sprint estimate based on complexity:
```yaml
header: "Sprint Estimate"
question: "How many sprints (2-week iterations) do you estimate?"
multiSelect: false
options:
  - label: "1-2 sprints"
    description: "Small epic, can be completed quickly"
  - label: "3-4 sprints"
    description: "Medium epic, standard multi-sprint work"
  - label: "5-6 sprints"
    description: "Large epic, significant scope"
  - label: "7+ sprints"
    description: "Very large epic, consider breaking down further"
```

# If 7+ sprints selected, warn:
# "Consider breaking this into multiple smaller epics for better parallelization and faster feedback."
</sprint_estimate>

</complexity_assessment>

<question_flow>

## Progressive Refinement Flow (8-9 Questions Total)

**Round 1: Initial Scoping (2 questions)**
- business_goal
- subsystem_selection

**Round 2: Scope Refinement (2-4 questions, conditional)**
- IF "Backend API" selected → backend_scope
- IF "Frontend UI" selected → frontend_scope
- IF "Database" selected → database_scope
- IF "External integrations" selected → integration_scope

**Round 3: Success Metrics (2 questions)**
- measurement_approach
- target_values
- (Optional follow-up if "Specific targets" selected)

**Round 4: Dependencies & Constraints (2 questions)**
- external_dependencies
- constraints

**Round 5: Complexity Assessment (2 questions)**
- technical_complexity
- sprint_estimate

**Total: 8-9 questions** (varies based on subsystem selection)

**Batching Strategy:**
- Round 1: 2 questions together (initial scoping)
- Round 2: All conditional questions together (max 4, min 0)
- Round 3: 2 questions together (metrics)
- Round 4: 2 questions together (dependencies)
- Round 5: 2 questions together (complexity)

**Benefits:**
- Progressive refinement (broad → specific)
- Conditional questions (only ask relevant follow-ups)
- Structured responses (no ambiguous free-text)
- 5-10 minute scoping session vs 30+ minute unstructured discussion

</question_flow>

<integration_with_epic_command>

## How /epic Uses This Question Bank

**Location in /epic.md:** After line 177 (epic specification generation)

**Workflow:**
1. User runs: `/epic "User authentication with OAuth 2.1"`
2. Epic spec generated with placeholders
3. Ambiguity score calculated (lines 106-128 in epic.md)
4. If score > 30 → Auto-invoke interactive scoping
5. Load question bank from this file
6. Execute 5 rounds of questions (8-9 total)
7. Apply answers to epic-spec.xml atomically
8. Proceed to /plan with fully-scoped epic

**Expected outcome:**
- Epic spec with zero placeholders
- All subsystems identified
- Success metrics defined
- Dependencies/constraints documented
- Sprint estimate for breakdown

</integration_with_epic_command>

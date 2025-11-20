# Spec-Flow Use Cases

Spec-Flow adapts to different project types and team structures. This guide shows how to apply Spec-Driven Development across various scenarios.

## Table of Contents

- [Web Applications](#web-applications)
- [API & Backend Services](#api--backend-services)
- [CLI Tools](#cli-tools)
- [Mobile Applications](#mobile-applications)
- [Design Systems](#design-systems)
- [Infrastructure & DevOps](#infrastructure--devops)
- [Documentation Sites](#documentation-sites)
- [Machine Learning Projects](#machine-learning-projects)
- [Team Structures](#team-structures)

---

## Web Applications

### Full-Stack Web App (React + Node.js)

**Example**: Building a SaaS dashboard with authentication, data visualization, and CRUD operations.

**Workflow Adaptations**:

1. **Specification Phase** (`/spec-flow`):

   - Define user flows (login, dashboard, settings)
     -\spec-flow API contracts between frontend and backend
   - Document data models and relationships
   - Include responsive design requirements (mobile, tablet, desktop)

2. **Planning Phase** (`/plan`):

   - Architecture: Frontend (React), Backend (Express), Database (PostgreSQL)
   - API endpoint design (RESTful or GraphQL)
   - State management strategy (Redux, Context, Zustand)
   - Authentication approach (JWT, sessions, OAuth)

3. **Task Breakdown** (`/tasks`):

   - Separate frontend and backend tasks
   - Example:
     - T001-T010: Backend API endpoints
     - T011-T020: Frontend components
     - T021-T025: Integration tests
     - T026-T028: E2E tests

4. **Implementation** (`/implement`):
   - Route backend tasks to `backend-dev` agent
   - Route frontend tasks to `frontend-dev` agent
   - Parallel development of API and UI

**Agent Configuration**:

```markdown
# .claude/agents/project-backend-dev.md

Specializes in:

- Express.js API development
- PostgreSQL schema design
- JWT authentication
- API testing with Jest/Supertest
```

```markdown
# .claude/agents/project-frontend-dev.md

Specializes in:

- React component development
- State management (Redux/Context)
- CSS-in-JS styling (styled-components)
- Frontend testing (React Testing Library, Cypress)
```

**Example Feature**: "User Dashboard with Activity Charts"

- **Spec**: User scenarios, chart types, data refresh frequency
- **Plan**: Backend endpoints for activity data, frontend charting library (Chart.js/Recharts)
- **Tasks**: 15 backend tasks, 18 frontend tasks, 5 integration tasks
- **Timeline**: 1 week (spec + plan), 2 weeks (implementation), 3 days (QA + ship)

---

## API & Backend Services

### RESTful API Service

**Example**: Building a public API for flight school scheduling with rate limiting, authentication, and webhooks.

**Workflow Adaptations**:

1. **Specification Phase**:

   - **API Contract First**: Define OpenAPI/Swagger spec
   - Document endpoints, request/response schemas, error codes
     -\spec-flow rate limits, authentication requirements
   - Define SLAs (uptime, response time)

2. **Planning Phase**:

   - Database schema design (normalized, indexed)
   - Caching strategy (Redis for rate limiting)
   - Message queue for webhooks (RabbitMQ, SQS)
   - Monitoring and logging (Prometheus, ELK)

3. **Testing Focus**:
   - API contract testing (Pact, Dredd)
   - Load testing (Artillery, k6)
   - Security testing (OWASP Top 10)

**Constitution Customization**:

```markdown
## API-Specific Principles

### Performance Requirements

- P95 response time: <200ms for read operations
- P95 response time: <500ms for write operations
- Rate limiting: 1000 req/hour (free), 10000 req/hour (paid)

### API Versioning

- Semantic versioning in URL (v1, v2)
- Deprecation notices 90 days before removal
- Maintain backward compatibility within major versions
```

**Example Feature**: "Flight Booking API with Conflict Detection"

- **Spec**: Endpoint definitions, conflict resolution logic, webhook payloads
- **Plan**: PostgreSQL schema with row-level locking, webhook queue with retry
- **Tasks**: 12 endpoint tasks, 8 database tasks, 6 webhook tasks, 8 testing tasks
- **Success Metrics**: <200ms P95 response time, 99.9% uptime, zero booking conflicts

---

## CLI Tools

### Command-Line Utility

**Example**: Building a CLI tool for database migrations and backups.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define command structure (`migrate up`, `migrate down`, `backup create`)
     -\spec-flow flags and options (`--verbose`, `--dry-run`, `--config`)
   - Document exit codes and error messages
   - Define configuration file format (YAML, JSON)

2. **Planning Phase**:

   - Framework choice (Click, Typer, Commander, Cobra)
   - Configuration management (dotenv, config files)
   - Error handling and logging
   - Distribution (npm, pip, Homebrew)

3. **Testing Focus**:
   - Unit tests for command logic
   - Integration tests with mock databases
   - E2E tests with real database containers (Docker)

**Template Customization**:

```markdown
# .spec-flow/templates/cli-spec-template.md

## Command Structure

### Primary Commands

- `tool migrate` - Database migration operations
- `tool backup` - Backup operations
- `tool restore` - Restore operations

### Flags

- `--verbose, -v` - Verbose output
- `--dry-run` - Preview without executing
- `--config, -c` - Config file path
- `--help, -h` - Show help

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Database connection error
```

**Example Feature**: "Interactive Migration Wizard"

- **Spec**: Interactive prompts, validation, confirmation steps
- **Plan**: Use inquirer.js for prompts, rollback on failure
- **Tasks**: 10 CLI tasks, 6 validation tasks, 4 testing tasks
- **Timeline**: 1 week

---

## Mobile Applications

### React Native Mobile App

**Example**: Building a cross-platform mobile app for flight logging.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define platform-specific behaviors (iOS vs Android)
     -\spec-flow offline-first architecture (data sync strategy)
   - Document push notification scenarios
   - Include native module requirements (camera, GPS, biometrics)

2. **Planning Phase**:

   - State management for offline (Redux Persist, WatermelonDB)
   - API sync strategy (optimistic updates, conflict resolution)
   - Native modules needed (custom or third-party)
   - App store submission requirements

3. **Visual References**:
   - Platform-specific design patterns (iOS HIG, Material Design)
   - Navigation patterns (tab bar vs drawer)
   - Gesture handling specifications

**Testing Strategy**:

```markdown
## Mobile Testing Requirements

### Unit Tests

- Redux logic (actions, reducers, selectors)
- Utility functions
- Data transformations

### Integration Tests

- API sync logic
- Offline queue processing
- Conflict resolution

### E2E Tests (Detox/Appium)

- Critical user flows (login, log flight, sync)
- iOS and Android separately
- Offline mode scenarios
```

**Example Feature**: "Offline Flight Logging with Auto-Sync"

- **Spec**: Offline form entry, queue management, sync on reconnect, conflict handling
- **Plan**: WatermelonDB for local storage, queue system, background sync
- **Tasks**: 15 offline logic tasks, 12 UI tasks, 8 sync tasks, 6 testing tasks
- **Timeline**: 2-3 weeks

---

## Design Systems

### Component Library

**Example**: Building a React component library for consistent UI across products.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define design tokens (colors, spacing, typography)
     -\spec-flow component API (props, events, slots)
   - Document accessibility requirements (ARIA, keyboard nav)
   - Define browser support matrix

2. **Planning Phase**:

   - Build tooling (Rollup, Vite, Webpack)
   - Documentation site (Storybook, Docusaurus)
   - Testing strategy (visual regression, a11y)
   - Versioning and release process (semantic versioning)

3. **Visual References**:
   - Figma links for each component
   - Interaction states (hover, focus, active, disabled)
   - Responsive behavior
   - Dark mode variants

**Deliverables**:

- Component source code
- Storybook stories with all variants
- TypeScript type definitions
- Accessibility audit report
- Usage documentation

**Example Feature**: "Button Component with Variants"

- **Spec**: Primary, secondary, ghost, danger variants; sizes (sm, md, lg); loading state
- **Plan**: Base Button component, variant system, icon support
- **Tasks**: 8 component tasks, 12 Storybook tasks, 6 a11y tasks, 4 testing tasks
- **Timeline**: 1 week

---

## Infrastructure & DevOps

### Infrastructure as Code (Terraform)

**Example**: Provisioning AWS infrastructure for a multi-region deployment.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define infrastructure components (VPC, EC2, RDS, S3)
     -\spec-flow regions and availability zones
   - Document security requirements (IAM, security groups)
   - Define cost constraints

2. **Planning Phase**:

   - Module structure (network, compute, database, storage)
   - State management (remote backend, locking)
   - Secrets management (AWS Secrets Manager, Vault)
   - Disaster recovery plan

3. **Testing Strategy**:
   - Terraform plan validation
   - Cost estimation (Infracost)
   - Security scanning (Checkov, tfsec)
   - Integration tests (Terratest)

**Example Feature**: "Multi-Region RDS with Read Replicas"

- **Spec**: Primary region (us-east-1), replica region (us-west-2), failover requirements
- **Plan**: RDS module, cross-region replication, Route53 failover
- **Tasks**: 6 Terraform module tasks, 4 security tasks, 3 testing tasks
- **Timeline**: 1 week

---

## Documentation Sites

### Static Documentation Site (Docusaurus, VitePress)

**Example**: Building developer documentation for an API platform.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define information architecture (guides, API reference, tutorials)
     -\spec-flow search functionality
   - Document versioning strategy (docs for each API version)
   - Define contribution workflow (external contributors)

2. **Planning Phase**:

   - Static site generator choice (Docusaurus, VitePress, Nextra)
   - Content management (MDX, Markdown)
   - Search integration (Algolia DocSearch)
   - CI/CD for auto-deployment

3. **Content Structure**:
   ```
   docs/
   ├── getting-started/
   ├── guides/
   ├── api-reference/
   ├── tutorials/
   └── migration/
   ```

**Example Feature**: "Interactive API Explorer"

- **Spec**: Live API playground, auto-populated examples, authentication
- **Plan**: OpenAPI spec integration, Swagger UI embed, auth token management
- **Tasks**: 8 integration tasks, 6 UI tasks, 4 content tasks
- **Timeline**: 1 week

---

## Machine Learning Projects

### ML Model Training & Deployment

**Example**: Building an image classification model for aviation documents.

**Workflow Adaptations**:

1. **Specification Phase**:

   - Define model requirements (accuracy, latency, input/output)
     -\spec-flow training data requirements (size, labels, format)
   - Document evaluation metrics (precision, recall, F1)
   - Define inference environment (GPU, batch vs real-time)

2. **Planning Phase**:

   - Model architecture (CNN, Transformer)
   - Training pipeline (PyTorch, TensorFlow)
   - Data versioning (DVC, MLflow)
   - Deployment strategy (TorchServe, TensorFlow Serving)

3. **Experiment Tracking**:
   - Log hyperparameters and metrics
   - Version datasets and models
   - Compare experiment runs

**Example Feature**: "AKTR Document Classifier"

- **Spec**: 95% accuracy, <500ms inference, supports PDF/images
- **Plan**: ResNet-50 base, fine-tuning pipeline, TorchServe deployment
- **Tasks**: 10 data prep tasks, 8 training tasks, 6 deployment tasks, 4 evaluation tasks
- **Timeline**: 3-4 weeks (including experimentation)

---

## Team Structures

### Solo Developer

**Workflow**: Use `/feature` for full automation with manual gates at preview and staging.

**Customizations**:

- Skip code review phase (or self-review)
- Simplify agent briefs (one agent does all work)
- Faster iteration cycles

**Example**:

```bash
/feature "Dark mode toggle"
# Automated: spec → plan → tasks → implement → optimize
# Manual gate: preview (test locally)
# Automated: ship to staging
# Manual gate: validate staging
# Automated: ship to production
```

---

### Small Team (2-5 developers)

**Workflow**: Spec-first collaboration, one person writes spec, team reviews, then parallel implementation.

**Process**:

1. **Product lead** writes spec (`/spec-flow`)
2. **Team reviews** spec asynchronously (GitHub PR)
3. **Lead generates plan** (`/plan`) and tasks (`/tasks`)
4. **Developers pick tasks** from tasks.md
5. **Parallel implementation**, track progress in NOTES.md
6. **Code review** before merging

**Customizations**:

- Add CODEOWNERS for automatic review assignment
- Use GitHub Projects for task tracking
- Daily standup reviews NOTES.md checkpoints

---

### Large Team (6+ developers, multiple squads)

**Workflow**: Squad-based features, dedicated spec writers, specialized agents.

**Structure**:

- **Product squad**: Writes specs and manages roadmap
- **Backend squad**: Implements backend features
- **Frontend squad**: Implements frontend features
- **QA squad**: Validates and tests

**Process**:

1. **Product squad** creates multiple specs in parallel
2. **Specs reviewed** by all squads (feasibility, effort)
3. **Backend and frontend squads** work in parallel on same feature
4. **Integration testing** by QA squad
5. **Coordinated deployment** to staging and production

**Customizations**:

- Multiple agent briefs per squad
- Separate repos for backend/frontend with shared spec repo
- Advanced CI/CD with deployment pipelines
- Feature flags for gradual rollout

---

## Choosing the Right Approach

### Decision Matrix

| Project Type       | Spec Complexity           | Agent Specialization  | Timeline  | Testing Focus     |
| ------------------ | ------------------------- | --------------------- | --------- | ----------------- |
| **Web App**        | High (frontend + backend) | High (2+ agents)      | 2-4 weeks | E2E, integration  |
| **API**            | Medium (contracts)        | Medium (backend only) | 1-3 weeks | Contract, load    |
| **CLI**            | Low (commands)            | Low (single agent)    | 1-2 weeks | Unit, integration |
| **Mobile**         | High (offline, native)    | High (2+ agents)      | 3-6 weeks | E2E, device       |
| **Design System**  | Medium (components)       | Medium (frontend)     | 2-4 weeks | Visual, a11y      |
| **Infrastructure** | Medium (IaC)              | Low (single agent)    | 1-2 weeks | Security, cost    |
| **Docs**           | Low (content)             | Low (single agent)    | 1 week    | Link checking     |
| **ML**             | High (data + model)       | High (2+ agents)      | 4-8 weeks | Evaluation        |

---

## Customization Tips

### Adapting Templates

1. **Copy and customize templates**:

   ```bash
   cp .spec-flow/templates/spec-template.md .spec-flow/templates/cli-spec-template.md
   # Edit to add CLI-specific sections
   ```

2. **Update command definitions** to use custom templates:
   ```markdown
   # .claude/commands/spec-flow.md

   Use template: .spec-flow/templates/cli-spec-template.md
   ```

### Custom Agent Briefs

Create project-specific agents:

```bash
# Backend specialist for your stack
cp .claude/agents/backend-dev.md .claude/agents/project-api-dev.md

# Edit to\spec-flow:
# - Your stack (FastAPI, PostgreSQL, Redis)
# - Your patterns (repository pattern, service layer)
# - Your testing tools (pytest, pytest-asyncio)
```

### Constitution Alignment

Tailor principles to your domain:

```markdown
# .spec-flow/memory/constitution.md

## Domain-Specific Principles

### Aviation Compliance (for flight school app)

- All features MUST comply with FAA Part 61/141 regulations
- Student records MUST be retained for 3 years minimum
- Instructor signatures MUST be verified electronically

### Healthcare Compliance (for medical app)

- All features MUST be HIPAA compliant
- PHI MUST be encrypted at rest and in transit
- Audit logs MUST be immutable and retained for 7 years
```

---

## Next Steps

1. **Choose your use case** from the examples above
2. **Review the example feature** in `specs/001-example-feature/`
3. **Customize templates** for your project type
4. **Set up agents** for your tech stack
5. **Define your constitution** with domain-specific principles
6. **Start building!** with `/spec-flow "Your first feature"`

For more guidance:

- [Getting Started](getting-started.md) - Step-by-step tutorial
- [Architecture](architecture.md) - System design
- [Contributing](../CONTRIBUTING.md) - Customization guidelines

Happy building! 🚀

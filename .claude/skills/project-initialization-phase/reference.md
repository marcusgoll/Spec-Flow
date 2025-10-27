# Project Initialization Phase: Reference Material

## 15 Questions Mapping

### Q1-Q3: Project Basics

**Q1. Project Name**
- **Maps to**: `overview.md` (title), all docs (project name references)
- **Format**: CamelCase or Title Case (e.g., "FlightPro", "TaskMaster Pro")
- **Validation**: 2-50 characters, no special chars except spaces/hyphens
- **Example**: "FlightPro"

**Q2. Vision Statement**
- **Maps to**: `overview.md` § Vision Statement
- **Format**: 1-2 sentences, problem + solution
- **Template**: "[Project] helps [users] [do what] because [current problem]"
- **Example**: "FlightPro helps CFIs manage students efficiently because current tools are too expensive or lack ACS tracking"

**Q3. Primary Users**
- **Maps to**: `overview.md` § Target Users
- **Format**: Role + context (e.g., "CFIs teaching 5-20 students")
- **Validation**: At least one primary persona
- **Example**: "Certified Flight Instructors (CFIs)"

---

### Q4-Q6: Scale & Team

**Q4. Scale Tier**
- **Maps to**: `capacity-planning.md` § Current Scale
- **Options**:
  - Micro: 100 users, $40/mo, 10K API requests/day
  - Small: 1K users, $95/mo, 100K requests/day
  - Medium: 10K users, $415/mo, 1M requests/day
  - Large: 100K+ users, $2K+/mo, 10M+ requests/day
- **Decision logic**: Solo dev → micro, small team → small, growing team → medium

**Q5. Team Size**
- **Maps to**: `development-workflow.md` § Team Structure
- **Options**:
  - Solo: 1 developer
  - Small: 2-5 developers
  - Medium: 6-20 developers
  - Large: 20+ developers
- **Impacts**: Git workflow (solo = simple, large = complex), PR reviews (solo = optional, large = required)

**Q6. Architecture Style**
- **Maps to**: `system-architecture.md` § Architecture Pattern
- **Options**:
  - Monolith: Single codebase, single deploy (recommended for solo/small teams)
  - Microservices: Multiple services, independent deploys (for medium/large teams)
  - Serverless: FaaS-based, event-driven (for specific use cases)
- **Decision logic**: Solo/small + simple app → monolith, medium/large + complex app → microservices

---

### Q7-Q10: Tech Stack

**Q7. Database**
- **Maps to**: `tech-stack.md` § Database, `data-architecture.md` § Storage Strategy
- **Options**: PostgreSQL, MySQL, MongoDB, SQLite, Supabase, PlanetScale, etc.
- **Decision factors**:
  - Relational data (user-student-lesson) → PostgreSQL/MySQL
  - Flexible schema → MongoDB
  - Serverless → Supabase/PlanetScale
- **Default**: PostgreSQL (most common, ACID compliant)

**Q8. Deployment Platform**
- **Maps to**: `deployment-strategy.md` § Platform, `capacity-planning.md` § Cost Model
- **Options**: Vercel, Railway, AWS, GCP, Azure, Heroku, Render, Fly.io
- **Decision factors**:
  - Next.js → Vercel
  - Full-stack monolith → Railway/Render
  - Enterprise → AWS/GCP/Azure
- **Default**: Vercel (frontend) + Railway (backend) for small projects

**Q9. API Style**
- **Maps to**: `api-strategy.md` § API Style
- **Options**: REST, GraphQL, tRPC, gRPC
- **Decision factors**:
  - Simple CRUD → REST
  - Complex data fetching → GraphQL
  - Type-safe client-server → tRPC
  - High-performance RPC → gRPC
- **Default**: REST (simplest, most familiar)

**Q10. Auth Provider**
- **Maps to**: `api-strategy.md` § Authentication, `system-architecture.md` § External Systems
- **Options**: Clerk, Auth0, Supabase Auth, Firebase Auth, custom, none
- **Decision factors**:
  - Fast setup → Clerk
  - Enterprise → Auth0
  - Supabase stack → Supabase Auth
  - Full control → custom
- **Default**: Clerk (fastest setup, generous free tier)

---

### Q11-Q13: Constraints

**Q11. Budget (Monthly MVP Cost)**
- **Maps to**: `capacity-planning.md` § Cost Model
- **Format**: USD amount (e.g., "$50", "$0" for free tier only)
- **Typical ranges**:
  - $0-10: Free tiers only (Vercel Hobby, Railway Free)
  - $10-50: Starter plans (Vercel Pro, Railway Starter)
  - $50-200: Growth plans
  - $200+: Enterprise
- **Example**: "$50"

**Q12. Privacy Requirements**
- **Maps to**: `data-architecture.md` § Privacy & Compliance
- **Options**:
  - Public: No sensitive data
  - PII: Personal Identifiable Information (names, emails)
  - GDPR: EU privacy compliance required
  - HIPAA: Healthcare data compliance
  - SOC2: Enterprise security/privacy audit
- **Impacts**: Encryption requirements, data retention policies, audit trails

**Q13. Git Workflow**
- **Maps to**: `development-workflow.md` § Git Workflow
- **Options**:
  - GitHub Flow: Simple (main + feature branches)
  - Git Flow: Complex (main + develop + feature/release/hotfix)
  - Trunk-Based: Continuous (main only, feature flags)
- **Decision logic**: Solo/small → GitHub Flow, medium/large → Git Flow

---

### Q14-Q15: Deployment & Frontend

**Q14. Deployment Model**
- **Maps to**: `deployment-strategy.md` § Deployment Model, `.spec-flow/memory/constitution.md`
- **Options**:
  - staging-prod: Two-stage (staging → production, recommended)
  - direct-prod: One-stage (main → production, risky)
  - local-only: No deployment (local development only)
- **Decision logic**: Team project → staging-prod, solo prototype → direct-prod

**Q15. Frontend Framework**
- **Maps to**: `tech-stack.md` § Frontend
- **Options**: Next.js, React, Vue, Svelte, Angular, none (backend-only)
- **Decision factors**:
  - Full-stack React → Next.js
  - SPA → React/Vue/Svelte
  - Enterprise → Angular
  - API-only → none
- **Default**: Next.js (most popular, best DX)

---

## Brownfield Codebase Scanning Strategies

### Tech Stack Detection Patterns

**Node.js / JavaScript / TypeScript**:
```bash
# Check for package.json
if [ -f "package.json" ]; then
  # Detect frontend framework
  FRAMEWORK=$(jq -r '.dependencies | keys[]' package.json | grep -E 'next|react|vue|svelte|angular' | head -1)

  # Detect versions
  if [ "$FRAMEWORK" = "next" ]; then
    NEXT_VERSION=$(jq -r '.dependencies.next // .devDependencies.next' package.json)
  fi

  # Detect TypeScript
  if jq -e '.devDependencies.typescript' package.json >/dev/null; then
    USES_TYPESCRIPT=true
  fi

  # Detect backend (if Node.js server)
  if jq -e '.dependencies.express' package.json >/dev/null; then
    BACKEND="Express"
  fi
fi
```

**Python**:
```bash
# Check for requirements.txt
if [ -f "requirements.txt" ]; then
  # Detect FastAPI
  if grep -qi 'fastapi' requirements.txt; then
    BACKEND="FastAPI"
    BACKEND_VERSION=$(grep -i 'fastapi' requirements.txt | grep -oP '[\d.]+' | head -1)
  fi

  # Detect Django
  if grep -qi 'django' requirements.txt; then
    BACKEND="Django"
  fi

  # Detect Flask
  if grep -qi 'flask' requirements.txt; then
    BACKEND="Flask"
  fi
fi

# Check for pyproject.toml (modern Python)
if [ -f "pyproject.toml" ]; then
  # Parse TOML for dependencies
  # Similar logic as requirements.txt
fi
```

**Database Detection**:
```bash
# From Node.js dependencies
if grep -q '"pg":' package.json; then
  DATABASE="PostgreSQL"
elif grep -q '"mysql2":' package.json; then
  DATABASE="MySQL"
elif grep -q '"mongoose":' package.json; then
  DATABASE="MongoDB"
fi

# From Python dependencies
if grep -qi 'psycopg2\|asyncpg' requirements.txt; then
  DATABASE="PostgreSQL"
elif grep -qi 'mysql\|pymysql' requirements.txt; then
  DATABASE="MySQL"
elif grep -qi 'pymongo' requirements.txt; then
  DATABASE="MongoDB"
fi

# From migration files
if [ -d "alembic/versions" ]; then
  DATABASE_MIGRATION_TOOL="Alembic"
  # Implies SQLAlchemy + relational DB (likely PostgreSQL)
  [ -z "$DATABASE" ] && DATABASE="PostgreSQL"
elif [ -d "migrations" ]; then
  # Django migrations or other tools
  DATABASE_MIGRATION_TOOL="Django Migrations"
fi
```

**Architecture Pattern Detection**:
```bash
# Monolith indicators
if [ -d "app" ] || [ -d "src" ]; then
  # Single app directory
  ARCHITECTURE="monolith"
fi

# Microservices indicators
if [ -d "services" ] || [ -d "microservices" ]; then
  SERVICE_COUNT=$(find services -maxdepth 1 -type d | wc -l)
  if [ "$SERVICE_COUNT" -gt 1 ]; then
    ARCHITECTURE="microservices"
  fi
fi

# Monorepo detection
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ]; then
  # Monorepo structure (could be monolith or microservices)
  if [ -d "apps" ] && [ -d "packages" ]; then
    ARCHITECTURE="monolith" # Likely monolith with shared packages
  fi
fi

# Docker Compose multi-service detection
if [ -f "docker-compose.yml" ]; then
  SERVICE_COUNT=$(grep -c '^  [a-zA-Z]' docker-compose.yml)
  if [ "$SERVICE_COUNT" -gt 2 ]; then
    ARCHITECTURE="microservices"
  fi
fi
```

**Deployment Platform Detection**:
```bash
# Vercel
if [ -f "vercel.json" ] || [ -f ".vercelignore" ]; then
  DEPLOYMENT_PLATFORM="Vercel"
fi

# Railway
if [ -f "railway.json" ] || [ -f "railway.toml" ]; then
  DEPLOYMENT_PLATFORM="Railway"
fi

# Heroku
if [ -f "Procfile" ] || [ -f "app.json" ]; then
  DEPLOYMENT_PLATFORM="Heroku"
fi

# AWS (various indicators)
if [ -f ".elasticbeanstalk/config.yml" ]; then
  DEPLOYMENT_PLATFORM="AWS Elastic Beanstalk"
elif [ -f "serverless.yml" ]; then
  DEPLOYMENT_PLATFORM="AWS (Serverless Framework)"
elif [ -d ".github/workflows" ]; then
  # Check workflow for AWS deployment
  if grep -q 'aws-actions' .github/workflows/*.yml 2>/dev/null; then
    DEPLOYMENT_PLATFORM="AWS (GitHub Actions)"
  fi
fi

# Render
if [ -f "render.yaml" ]; then
  DEPLOYMENT_PLATFORM="Render"
fi
```

---

## ERD Generation from Migrations

### Alembic (Python/SQLAlchemy) Migration Parsing

**Strategy**: Parse `alembic/versions/*.py` files for `create_table()` calls

**Example Migration File**:
```python
# alembic/versions/abc123_create_users_table.py
def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email')
    )
```

**Parsing Logic**:
```bash
# Extract table names
ENTITIES=()
for migration in alembic/versions/*.py; do
  TABLE_NAME=$(grep -oP "create_table\(['\"]\\K[^'\"']+" "$migration")
  if [ -n "$TABLE_NAME" ]; then
    ENTITIES+=("$TABLE_NAME")
  fi
done

# Extract columns
declare -A ENTITY_COLUMNS
for migration in alembic/versions/*.py; do
  TABLE_NAME=$(grep -oP "create_table\(['\"]\\K[^'\"']+" "$migration")

  # Extract columns (simplified - real parsing would be more robust)
  COLUMNS=$(grep -oP "sa\.Column\(['\"]\\K[^'\"']+" "$migration")
  ENTITY_COLUMNS["$TABLE_NAME"]="$COLUMNS"
done

# Extract foreign keys
declare -A ENTITY_FKS
for migration in alembic/versions/*.py; do
  # Look for ForeignKeyConstraint
  FK=$(grep -oP "sa\.ForeignKeyConstraint\(\[['\"]\K[^'\"']+['\"], \['\"\\K[^'\"']+" "$migration")
  if [ -n "$FK" ]; then
    ENTITY_FKS["$TABLE_NAME"]+="$FK "
  fi
done
```

**Mermaid ERD Generation**:
```bash
# Generate Mermaid syntax from parsed entities
cat > data-architecture.md <<EOF
## Entity Relationship Diagram

\`\`\`mermaid
erDiagram
$(for entity in "${ENTITIES[@]}"; do
  UPPER_ENTITY=$(echo "$entity" | tr '[:lower:]' '[:upper:]')
  echo "    $UPPER_ENTITY {"

  # Add columns
  for col in ${ENTITY_COLUMNS["$entity"]}; do
    echo "        string $col"
  done

  echo "    }"
done)

$(# Add relationships from foreign keys
for entity in "${!ENTITY_FKS[@]}"; do
  for fk in ${ENTITY_FKS["$entity"]}; do
    # Parse FK to get referenced table
    REFERENCED_TABLE=$(echo "$fk" | cut -d' ' -f2)
    echo "    $REFERENCED_TABLE ||--o{ $entity : has"
  done
done)
\`\`\`
EOF
```

---

## Default Values & Reasonable Assumptions

### When to Use Defaults

**Allowed Defaults**:
- Architecture: Monolith (for solo dev)
- Database: PostgreSQL (most common relational DB)
- API Style: REST (simplest, most familiar)
- Git Workflow: GitHub Flow (simplest)
- Deployment Model: staging-prod (safest)

**Not Allowed to Assume**:
- Business logic or specific features
- User metrics or KPIs
- Competitor names
- Specific entity field names (must come from scan or mark [NEEDS CLARIFICATION])

### Reasonable Inference Examples

**Frontend Stack** (if package.json detected):
- Next.js detected → "Frontend framework: Next.js (detected from package.json)"
- React but not Next.js → "Frontend: React SPA (inferred from package.json)"
- No frontend deps → "Frontend: None (backend-only API)"

**Backend Stack** (if requirements.txt detected):
- FastAPI detected → "Backend: FastAPI (detected from requirements.txt)"
- Django detected → "Backend: Django (detected from requirements.txt)"
- No obvious framework → "Backend: [NEEDS CLARIFICATION: Python detected but no framework found]"

**Architecture** (if no clear indicators):
- Solo dev + simple structure → "Architecture: Monolith (inferred from team size)"
- Multiple /services/ dirs → "Architecture: Microservices (inferred from directory structure)"
- Unclear → "Architecture: [NEEDS CLARIFICATION: Unable to detect from codebase]"

---

## Cross-Document Consistency Rules

### Validation Checklist

**Tech Stack Consistency**:
- [ ] Database in `tech-stack.md` matches `data-architecture.md`
- [ ] API style in `api-strategy.md` matches `system-architecture.md` communication patterns
- [ ] Deployment platform in `deployment-strategy.md` matches `capacity-planning.md` infrastructure costs

**Architecture Consistency**:
- [ ] Architecture style in `system-architecture.md` matches `tech-stack.md` rationale
- [ ] Components in `system-architecture.md` match `deployment-strategy.md` services
- [ ] ERD entities in `data-architecture.md` referenced in `api-strategy.md` endpoints

**Team & Workflow Consistency**:
- [ ] Team size in `overview.md` matches `development-workflow.md` team structure
- [ ] Budget in `capacity-planning.md` aligns with `deployment-strategy.md` platform choice
- [ ] Privacy requirements in `overview.md` match `data-architecture.md` compliance section

---

## [NEEDS CLARIFICATION] Marker Standards

### When to Use

**Use [NEEDS CLARIFICATION] for**:
- Information not provided in questionnaire
- Information not detectable from codebase scan
- Ambiguous or conflicting information
- User-specific business logic

**Examples**:
```markdown
## Competitors
[NEEDS CLARIFICATION: Who are your main competitors? What features do they lack?]

## Performance Targets
- API response time: [NEEDS CLARIFICATION: p95 < 500ms? 1s? 2s?]

## Data Retention
- User data retention: [NEEDS CLARIFICATION: How long to keep inactive user data?]
```

### What NOT to Mark

**DON'T use [NEEDS CLARIFICATION] for**:
- Information you can infer from context (use reasonable defaults)
- Standard industry practices (e.g., "HTTPS for API communication")
- Template boilerplate (e.g., "Last Updated: [DATE]" → fill with actual date)

---

## Performance Benchmarks

### Expected Token Usage

**Greenfield** (minimal codebase scanning):
- Reading 8 templates: ~20K tokens
- Filling templates: ~10K tokens
- Generating Mermaid diagrams: ~5K tokens
- **Total**: ~35K tokens

**Brownfield** (with codebase scanning):
- Reading 8 templates: ~20K tokens
- Scanning codebase: ~10K tokens (package.json, migrations, etc.)
- Filling templates: ~10K tokens
- Generating Mermaid diagrams + ERD: ~10K tokens
- **Total**: ~50K tokens

### Expected Duration

**Greenfield**:
- Interactive questionnaire: ~10 minutes
- Document generation: ~5 minutes
- **Total**: ~15 minutes

**Brownfield**:
- Interactive questionnaire: ~10 minutes
- Codebase scanning: ~5 minutes
- Document generation: ~5 minutes
- **Total**: ~20 minutes

---

## References

- **Mermaid Syntax**: https://mermaid.js.org/syntax/entityRelationshipDiagram.html
- **C4 Model**: https://c4model.com/
- **SQLAlchemy Docs**: https://docs.sqlalchemy.org/en/20/
- **Semantic Versioning**: https://semver.org/

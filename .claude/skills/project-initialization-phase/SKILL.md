---
name: project-initialization-phase
description: "Standard Operating Procedure for /init-project phase. Guide one-time project setup with interactive questionnaire, brownfield codebase scanning, 8-document generation (overview, architecture, tech-stack, data, API, capacity, deployment, workflow), and cross-document consistency validation. Auto-trigger when user runs /init-project or mentions 'project setup', 'architecture documentation', or 'greenfield/brownfield initialization'."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Project Initialization Phase: Standard Operating Procedure

> **Training Guide**: Step-by-step procedures for executing the `/init-project` command to generate comprehensive project-level design documentation.

**Supporting references**:
- [reference.md](reference.md) - 15 questions mapping, codebase scanning strategies, brownfield detection patterns
- [examples.md](examples.md) - Greenfield vs brownfield examples, filled vs unfilled templates
- [templates/questionnaire-template.md](templates/questionnaire-template.md) - Interactive question flow
- [templates/scanning-checklist-template.md](templates/scanning-checklist-template.md) - Brownfield codebase scanning checklist
- [scripts/validate-project-docs.sh](scripts/validate-project-docs.sh) - Verify all 8 docs generated correctly

---

## Phase Overview

**Purpose**: Generate comprehensive project-level design documentation before building features. Embodies "Planning is 80% of the project, 20% code."

**Inputs**:
- User answers to 15 interactive questions
- Existing codebase (if brownfield project)
- Project templates from `.spec-flow/templates/project/`

**Outputs**:
- `docs/project/overview.md` - Vision, users, scope, success metrics
- `docs/project/system-architecture.md` - C4 diagrams, components, data flows
- `docs/project/tech-stack.md` - Technology choices with rationale
- `docs/project/data-architecture.md` - ERD, entity schemas, migrations
- `docs/project/api-strategy.md` - REST/GraphQL patterns, auth, versioning
- `docs/project/capacity-planning.md` - Scaling tiers (micro → 1000x)
- `docs/project/deployment-strategy.md` - CI/CD, environments, rollback
- `docs/project/development-workflow.md` - Git flow, PR process, testing

**Expected duration**: 15-20 minutes (10 min questions + 5-10 min generation/review)

---

## Prerequisites

**Environment checks**:
- [ ] Templates exist in `.spec-flow/templates/project/` (8 files)
- [ ] `docs/` directory exists or can be created
- [ ] Project-architect agent available (`.claude/agents/phase/project-architect.md`)

**Knowledge requirements**:
- Understanding of greenfield vs brownfield projects
- Familiarity with tech stack detection strategies
- ERD generation from database migrations
- Cross-document consistency validation

**Before running**:
- ⚠️ **WARNING**: /init-project generates 8 files. If `docs/project/` already exists, offer to:
  - A) Backup existing docs to `docs/project-backup-{timestamp}/`
  - B) Append to existing docs
  - C) Abort (user will manually update)

---

## Execution Steps

### Step 1: Detect Project Type (Greenfield vs Brownfield)

**Actions**:
1. Check for existing codebase indicators:
   ```bash
   # Check for package.json (Node.js)
   if [ -f "package.json" ]; then
     PROJECT_TYPE="brownfield"
     TECH_DETECTED="Node.js"
   fi

   # Check for requirements.txt (Python)
   if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
     PROJECT_TYPE="brownfield"
     TECH_DETECTED="Python"
   fi

   # Check for Cargo.toml (Rust), go.mod (Go), Gemfile (Ruby)
   # ...

   # If no indicators found
   if [ -z "$PROJECT_TYPE" ]; then
     PROJECT_TYPE="greenfield"
   fi
   ```

2. Inform user of detection:
   ```bash
   if [ "$PROJECT_TYPE" = "brownfield" ]; then
     echo "✅ Detected existing codebase ($TECH_DETECTED)"
     echo "   Will scan codebase to auto-fill project docs"
   else
     echo "ℹ️  No existing codebase detected (greenfield project)"
     echo "   Will generate templates with [NEEDS CLARIFICATION] markers"
   fi
   ```

**Quality check**: Correct project type detected? If unclear, ask user.

---

### Step 2: Interactive Questionnaire (15 Questions)

**Purpose**: Gather essential project context to fill templates

**Question Flow** (see [templates/questionnaire-template.md](templates/questionnaire-template.md)):

```bash
# Q1: Project name
read -p "Q1. Project name (e.g., FlightPro): " PROJECT_NAME

# Q2: Vision (1 sentence)
read -p "Q2. Vision - What problem does this solve? (1 sentence): " VISION

# Q3: Primary users
read -p "Q3. Primary users (e.g., CFIs, students): " PRIMARY_USERS

# Q4: Scale tier
echo "Q4. Scale tier:"
echo "   1) Micro (100 users)"
echo "   2) Small (1K users)"
echo "   3) Medium (10K users)"
echo "   4) Large (100K+ users)"
read -p "   Choice (1-4): " SCALE_CHOICE
case $SCALE_CHOICE in
  1) SCALE="micro" ;;
  2) SCALE="small" ;;
  3) SCALE="medium" ;;
  4) SCALE="large" ;;
esac

# Q5-Q15: Similar format for:
# - Team size (solo/small/medium/large)
# - Architecture style (monolith/microservices/serverless)
# - Database (PostgreSQL/MySQL/MongoDB/etc.)
# - Deployment platform (Vercel/Railway/AWS/etc.)
# - API style (REST/GraphQL/tRPC/gRPC)
# - Auth provider (Clerk/Auth0/custom/none)
# - Budget (monthly MVP cost)
# - Privacy requirements (public/PII/GDPR/HIPAA)
# - Git workflow (GitHub Flow/Git Flow/Trunk-Based)
# - Deployment model (staging-prod/direct-prod/local-only)
# - Frontend framework (Next.js/React/Vue/etc.)
```

**Validation**:
- Required: PROJECT_NAME, VISION, PRIMARY_USERS
- Optional (can be "unknown" or "TBD"): Budget, specific versions

**Store answers**:
```bash
# Save to temporary file for project-architect agent
cat > /tmp/project-init-answers.json <<EOF
{
  "project_name": "$PROJECT_NAME",
  "vision": "$VISION",
  "primary_users": "$PRIMARY_USERS",
  "scale": "$SCALE",
  "team_size": "$TEAM_SIZE",
  "architecture": "$ARCHITECTURE",
  "database": "$DATABASE",
  "deployment_platform": "$DEPLOYMENT_PLATFORM",
  "api_style": "$API_STYLE",
  "auth_provider": "$AUTH_PROVIDER",
  "budget_monthly": "$BUDGET",
  "privacy_reqs": "$PRIVACY",
  "git_workflow": "$GIT_WORKFLOW",
  "deployment_model": "$DEPLOYMENT_MODEL",
  "frontend_framework": "$FRONTEND"
}
EOF
```

**Quality check**: All required fields filled? User satisfied with answers?

---

### Step 3: Brownfield Codebase Scanning (If Applicable)

**Skip if greenfield**. For brownfield, auto-detect:

**Tech Stack Scanning** (see [templates/scanning-checklist-template.md](templates/scanning-checklist-template.md)):

```bash
# Frontend detection
if [ -f "package.json" ]; then
  # Detect Next.js
  if grep -q '"next":' package.json; then
    FRONTEND_FRAMEWORK=$(jq -r '.dependencies.next // .devDependencies.next' package.json)
    FRONTEND_VERSION=$(echo "$FRONTEND_FRAMEWORK" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
  fi

  # Detect React
  if grep -q '"react":' package.json; then
    REACT_VERSION=$(jq -r '.dependencies.react' package.json)
  fi

  # Detect TypeScript
  if grep -q '"typescript":' package.json; then
    TS_DETECTED=true
  fi
fi

# Backend detection
if [ -f "requirements.txt" ]; then
  # Detect FastAPI
  if grep -q 'fastapi' requirements.txt; then
    BACKEND_FRAMEWORK="FastAPI"
    BACKEND_VERSION=$(grep 'fastapi' requirements.txt | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
  fi

  # Detect Django
  if grep -q 'django' requirements.txt; then
    BACKEND_FRAMEWORK="Django"
  fi
fi

# Database detection (from dependencies)
if grep -q '"pg":' package.json || grep -q 'psycopg2' requirements.txt; then
  DATABASE="PostgreSQL"
fi

# Database detection (from migrations)
if [ -d "alembic/versions" ]; then
  DATABASE_MIGRATION_TOOL="Alembic"
  # Count migration files
  MIGRATION_COUNT=$(ls alembic/versions/*.py 2>/dev/null | wc -l)
fi
```

**Architecture Pattern Detection**:
```bash
# Detect microservices
if [ -d "services" ] || [ -d "microservices" ]; then
  ARCHITECTURE="microservices"
elif [ -f "docker-compose.yml" ]; then
  # Check for multiple services in docker-compose
  SERVICE_COUNT=$(grep -c 'image:' docker-compose.yml)
  if [ "$SERVICE_COUNT" -gt 2 ]; then
    ARCHITECTURE="microservices"
  fi
else
  ARCHITECTURE="monolith"
fi
```

**Deployment Platform Detection**:
```bash
if [ -f "vercel.json" ]; then
  DEPLOYMENT_PLATFORM="Vercel"
elif [ -f "railway.json" ] || [ -f "railway.toml" ]; then
  DEPLOYMENT_PLATFORM="Railway"
elif [ -d ".github/workflows" ]; then
  # Inspect deploy workflow for platform
  WORKFLOW_FILE=$(find .github/workflows -name "*deploy*" -type f | head -1)
  if grep -q 'vercel' "$WORKFLOW_FILE"; then
    DEPLOYMENT_PLATFORM="Vercel"
  elif grep -q 'railway' "$WORKFLOW_FILE"; then
    DEPLOYMENT_PLATFORM="Railway"
  fi
fi
```

**ERD Generation from Migrations**:
```bash
# If Alembic migrations exist, generate ERD
if [ -d "alembic/versions" ]; then
  # Scan migration files for create_table statements
  # Extract entity names, fields, foreign keys
  # Generate Mermaid ERD syntax

  # Example: Parse migration file
  ENTITIES=()
  for migration in alembic/versions/*.py; do
    # Extract table names
    TABLE_NAME=$(grep -oP "create_table\('\K[^']+" "$migration")
    if [ -n "$TABLE_NAME" ]; then
      ENTITIES+=("$TABLE_NAME")
    fi
  done

  # Result: ENTITIES=("users" "students" "lessons" "progress")
fi
```

**Quality check**: Tech stack accurately detected? ERD entities match database?

---

### Step 4: Launch Project-Architect Agent

**Actions**:
1. Pass answers + scan results to agent:
   ```bash
   # Invoke project-architect agent (see .claude/agents/phase/project-architect.md)
   # Agent will:
   # - Read 8 templates from .spec-flow/templates/project/
   # - Fill templates with questionnaire answers
   # - Inject scan results (if brownfield)
   # - Mark unknowns with [NEEDS CLARIFICATION]
   # - Generate Mermaid diagrams (C4, ERD)
   # - Validate cross-document consistency
   # - Write 8 files to docs/project/
   ```

2. Monitor agent progress:
   ```bash
   echo "🤖 Project-architect agent generating documentation..."
   echo "   - Reading 8 templates"
   echo "   - Filling with questionnaire answers"
   echo "   - Injecting scan results (brownfield)"
   echo "   - Generating Mermaid diagrams"
   echo "   - Validating cross-document consistency"
   ```

**Quality check**: Agent completed successfully? No errors in generation?

---

### Step 5: Validate Generated Documentation

**Run validation script** (see [scripts/validate-project-docs.sh](scripts/validate-project-docs.sh)):

```bash
# Check all 8 files exist
DOCS_DIR="docs/project"
REQUIRED_FILES=(
  "overview.md"
  "system-architecture.md"
  "tech-stack.md"
  "data-architecture.md"
  "api-strategy.md"
  "capacity-planning.md"
  "deployment-strategy.md"
  "development-workflow.md"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$DOCS_DIR/$file" ]; then
    echo "❌ Missing file: $DOCS_DIR/$file"
    exit 1
  fi
done

echo "✅ All 8 documentation files generated"

# Count [NEEDS CLARIFICATION] markers
CLARIFICATION_COUNT=$(grep -r "NEEDS CLARIFICATION" "$DOCS_DIR" | wc -l)
echo "ℹ️  Found $CLARIFICATION_COUNT [NEEDS CLARIFICATION] sections"

# Validate Mermaid diagrams
if grep -q '```mermaid' "$DOCS_DIR/system-architecture.md"; then
  echo "✅ Mermaid diagrams present in system-architecture.md"
else
  echo "⚠️  Warning: No Mermaid diagrams in system-architecture.md"
fi

# Cross-document consistency check
# - Tech stack in tech-stack.md matches system-architecture.md
# - Database in tech-stack.md matches data-architecture.md
# - Deployment model in deployment-strategy.md matches capacity-planning.md
```

**Quality metrics**:
- All 8 files generated: ✅
- [NEEDS CLARIFICATION] count < 20: ✅ (good coverage)
- Mermaid diagrams present: ✅
- Cross-document consistency: ✅

---

### Step 6: Summary Report

**Display summary to user**:

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PROJECT DOCUMENTATION GENERATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Coverage:"
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo "   - Filled from questionnaire: 70%"
  echo "   - Inferred from defaults: 10%"
  echo "   - Needs clarification: 20%"
else
  echo "   - Filled from questionnaire: 50%"
  echo "   - Inferred from codebase: 30%"
  echo "   - Needs clarification: 20%"
fi
echo ""
echo "📍 [NEEDS CLARIFICATION] Sections: $CLARIFICATION_COUNT"
if [ "$CLARIFICATION_COUNT" -gt 0 ]; then
  echo "   Review and fill these sections:"
  grep -r "NEEDS CLARIFICATION" docs/project/ --with-filename | head -5
  echo "   ..."
fi
echo ""
echo "✅ Generated Files:"
for file in "${REQUIRED_FILES[@]}"; do
  echo "   - docs/project/$file"
done
echo ""
echo "💡 Next Steps:"
echo "   1. Review docs/project/ files"
echo "   2. Fill [NEEDS CLARIFICATION] sections"
echo "   3. Commit: git add docs/project/ && git commit -m 'docs: add project architecture'"
echo "   4. Start building: /roadmap or /feature"
echo ""
```

**Quality check**: User understands next steps? Documentation looks complete?

---

## Anti-Hallucination Rules

**CRITICAL**: Prevent making up information during documentation generation.

**Allowed**:
- ✅ Use questionnaire answers verbatim
- ✅ Use detected tech from codebase scans
- ✅ Use reasonable defaults (e.g., "monolith for solo dev")
- ✅ Mark unknowns with [NEEDS CLARIFICATION: specific question]

**Not Allowed**:
- ❌ Making up business logic or features
- ❌ Inventing competitor names (unless user provided)
- ❌ Creating fake user metrics
- ❌ Hallucinating tech stack choices (must be from answers or scan)
- ❌ Fabricating entity relationships (must be from migrations or marked for clarification)

**Cite Sources**:
- "From questionnaire Q7: PostgreSQL"
- "Detected from package.json: Next.js 14.2.3"
- "Inferred from alembic migrations: User, Student, Lesson entities"
- "Common pairing for Next.js: FastAPI backend [NEEDS CLARIFICATION if wrong]"

---

## Error Handling

**Missing Templates**:
```bash
if [ ! -f ".spec-flow/templates/project/overview-template.md" ]; then
  echo "❌ ERROR: Missing template files in .spec-flow/templates/project/"
  echo "   Run: git pull origin main"
  echo "   Or: Ensure workflow package is properly installed"
  exit 1
fi
```

**Codebase Scan Failures** (brownfield):
```bash
# If package.json malformed
if ! jq . package.json >/dev/null 2>&1; then
  echo "⚠️  Warning: package.json is malformed (invalid JSON)"
  echo "   Skipping Node.js dependency detection"
  # Continue with generation, mark as [NEEDS CLARIFICATION]
fi
```

**Write Failures**:
```bash
if ! mkdir -p docs/project/ 2>/dev/null; then
  echo "❌ ERROR: Cannot create docs/project/ directory"
  echo "   Check file permissions"
  exit 1
fi
```

**Agent Failures**:
```bash
# If project-architect agent fails
if [ $AGENT_EXIT_CODE -ne 0 ]; then
  echo "❌ ERROR: Project-architect agent failed"
  echo "   Check logs for details"
  echo "   Common causes:"
  echo "   - Template files missing or malformed"
  echo "   - Out of memory (8 docs is token-heavy)"
  exit 1
fi
```

---

## Performance Considerations

**Token Budget**: ~50K tokens
- Reading templates: ~20K
- Codebase scanning (brownfield): ~10K
- Generating 8 docs: ~15K
- Buffer: ~5K

**Optimization**:
- Read templates once, cache in memory
- Scan only necessary files (don't read entire codebase)
- Generate docs sequentially (not parallel) to avoid memory issues
- Use Mermaid for diagrams (not images) to save tokens

**Expected Duration**:
- Greenfield: 15 minutes (10 min questions + 5 min generation)
- Brownfield: 20 minutes (10 min questions + 5 min scan + 5 min generation)

---

## Post-Generation Integration

**Update Constitution** (`.spec-flow/memory/constitution.md`):
```bash
# Add reference to project docs
if ! grep -q "docs/project/" .spec-flow/memory/constitution.md; then
  cat >> .spec-flow/memory/constitution.md <<EOF

## Project Documentation

**Location**: \`docs/project/\`

All features MUST align with project architecture documented in:
- overview.md (vision, users, scope)
- tech-stack.md (technology choices)
- data-architecture.md (entity relationships)
- api-strategy.md (API patterns)

See \`docs/project-design-guide.md\` for usage.
EOF
fi
```

**Git Commit**:
```bash
git add docs/project/
git add .spec-flow/memory/constitution.md
git commit -m "docs: add project architecture documentation

Generated via /init-project:
- 8 comprehensive project docs in docs/project/
- Vision, tech stack, data model, API strategy
- Deployment and development workflow

Next: Review [NEEDS CLARIFICATION] sections and fill details"
```

---

## Quality Checklist

Before marking phase complete:

- [ ] All 8 files generated in `docs/project/`
- [ ] No Lorem Ipsum or generic "TODO" placeholders (use [NEEDS CLARIFICATION] instead)
- [ ] Realistic examples provided (or [NEEDS CLARIFICATION])
- [ ] Mermaid diagrams present and valid syntax
- [ ] Cross-document consistency validated
- [ ] Brownfield scan (if applicable) successfully detected tech stack
- [ ] ERD generated from migrations (if applicable)
- [ ] [NEEDS CLARIFICATION] count < 20 (good coverage)
- [ ] User informed of next steps (review, fill clarifications, commit)

---

## Common Issues & Troubleshooting

**Issue**: "Too many [NEEDS CLARIFICATION] markers (>30)"
- **Cause**: Greenfield project + incomplete questionnaire answers
- **Fix**: Re-run /init-project with more detailed answers, OR manually fill clarifications post-generation

**Issue**: "Brownfield scan detected wrong tech stack"
- **Cause**: Multiple tech stacks in monorepo, or scan logic error
- **Fix**: Manually edit `docs/project/tech-stack.md` after generation

**Issue**: "ERD generation failed (no entities)"
- **Cause**: Migration files not in expected format, or custom migration tool
- **Fix**: Manually create ERD in `data-architecture.md` using Mermaid syntax

**Issue**: "Cross-document inconsistencies detected"
- **Cause**: Questionnaire answers conflict (e.g., said "PostgreSQL" but scan found "MongoDB")
- **Fix**: Review validation output, manually resolve conflicts in generated docs

---

## References

- **Claude Code Skills Docs**: https://docs.claude.com/en/docs/claude-code/skills
- **Project Design Guide**: `docs/project-design-guide.md`
- **Project Templates**: `.spec-flow/templates/project/`
- **Project-Architect Agent**: `.claude/agents/phase/project-architect.md`

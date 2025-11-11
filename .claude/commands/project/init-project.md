---
description: Initialize project design documentation (one-time setup for new projects)
---

Initialize project-level system design: $ARGUMENTS

<context>
## PURPOSE

Create comprehensive project documentation that answers:
- **What**: Vision, users, scope (overview.md)
- **How**: System architecture, tech stack (system-architecture.md, tech-stack.md)
- **Data**: Data architecture, API strategy (data-architecture.md, api-strategy.md)
- **Scale**: Capacity planning (capacity-planning.md)
- **Deploy**: Deployment strategy (deployment-strategy.md)
- **Team**: Development workflow (development-workflow.md)

These docs are the foundation for all features. Run ONCE per project.

## WORKFLOW INTEGRATION

```
/init-project (once) → /roadmap (ongoing) → /feature (per-feature)
```

## USER INPUT

Project name or description (optional): `$ARGUMENTS`

If empty, will prompt interactively.
</context>

## CHECK IF ALREADY INITIALIZED

```bash
# Check if project docs already exist
if [ -d "docs/project" ]; then
  echo "⚠️  Project documentation already exists at docs/project/"
  echo ""
  echo "Options:"
  echo "  1. Skip initialization (docs already complete)"
  echo "  2. Re-initialize (WARNING: will overwrite existing docs)"
  echo "  3. Update specific doc (choose which file to regenerate)"
  echo ""
  read -p "Choice (1/2/3): " choice

  case $choice in
    1)
      echo "Skipping initialization. Existing docs preserved."
      exit 0
      ;;
    2)
      echo "⚠️  WARNING: This will overwrite all files in docs/project/"
      read -p "Are you sure? (yes/NO): " confirm
      if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
      fi
      ;;
    3)
      echo "Interactive update not yet implemented."
      echo "Manually edit files in docs/project/ or re-initialize."
      exit 0
      ;;
    *)
      echo "Invalid choice. Aborting."
      exit 1
      ;;
  esac
fi
```

## GREENFIELD VS BROWNFIELD DETECTION

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  PROJECT TYPE DETECTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect if greenfield (new project) or brownfield (existing codebase)
PROJECT_TYPE="greenfield"

# Check for existing code indicators
if [ -f "package.json" ] || [ -f "requirements.txt" ] || [ -f "Cargo.toml" ] || [ -f "go.mod" ]; then
  PROJECT_TYPE="brownfield"
  echo "✓ Detected: Brownfield project (existing codebase found)"
  echo ""
  echo "Will scan codebase to infer:"
  echo "  - Tech stack (from dependencies)"
  echo "  - Project structure"
  echo "  - Existing patterns"
  echo ""
else
  echo "✓ Detected: Greenfield project (no existing code)"
  echo ""
  echo "Will guide you through technology choices."
  echo ""
fi
```

## INTERACTIVE QUESTIONS (15 TOTAL)

**Goal**: Gather enough info to populate 8 template files

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 PROJECT INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Answer 15 questions (~10 minutes)."
echo "You can always update docs/project/*.md later."
echo ""

# Q1: Project Name
if [ -z "$ARGUMENTS" ]; then
  read -p "Q1. Project name (e.g., 'FlightPro', 'AcmeApp'): " PROJECT_NAME
else
  PROJECT_NAME="$ARGUMENTS"
  echo "Q1. Project name: $PROJECT_NAME (from command)"
fi

# Q2: Vision (one sentence)
read -p "Q2. What does this project do? (1 sentence): " VISION

# Q3: Target Users
read -p "Q3. Who are the primary users? (e.g., 'Flight instructors'): " PRIMARY_USERS

# Q4: Expected Scale (initial)
echo ""
echo "Q4. Expected initial scale?"
echo "  1. Micro (< 100 users)"
echo "  2. Small (100-1K users)"
echo "  3. Medium (1K-10K users)"
echo "  4. Large (10K+ users)"
read -p "Choice (1-4): " SCALE_CHOICE

case $SCALE_CHOICE in
  1) SCALE="micro"; MAX_USERS=100;;
  2) SCALE="small"; MAX_USERS=1000;;
  3) SCALE="medium"; MAX_USERS=10000;;
  4) SCALE="large"; MAX_USERS=100000;;
  *) SCALE="micro"; MAX_USERS=100;;
esac

# Q5: Team Size
echo ""
echo "Q5. Current team size?"
echo "  1. Solo (1 developer)"
echo "  2. Small (2-5 developers)"
echo "  3. Medium (5-15 developers)"
echo "  4. Large (15+ developers)"
read -p "Choice (1-4): " TEAM_CHOICE

case $TEAM_CHOICE in
  1) TEAM_SIZE="solo";;
  2) TEAM_SIZE="small";;
  3) TEAM_SIZE="medium";;
  4) TEAM_SIZE="large";;
  *) TEAM_SIZE="solo";;
esac

# Q6: Architecture Style (if greenfield)
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo ""
  echo "Q6. Architecture preference?"
  echo "  1. Monolith (recommended for < 10K users)"
  echo "  2. Microservices (complex, high scale)"
  echo "  3. Serverless (AWS Lambda, Vercel Functions)"
  read -p "Choice (1-3): " ARCH_CHOICE

  case $ARCH_CHOICE in
    1) ARCHITECTURE="monolith";;
    2) ARCHITECTURE="microservices";;
    3) ARCHITECTURE="serverless";;
    *) ARCHITECTURE="monolith";;
  esac
else
  # Brownfield: Infer from codebase
  echo ""
  echo "Q6. Architecture (auto-detected from codebase)..."
  # Claude Code: Scan codebase to infer architecture
  # - Check for /services/, /lambdas/, /api/ patterns
  # - Look for docker-compose.yml (microservices indicator)
  # - Infer from project structure
  ARCHITECTURE="monolith"  # Default, will be overridden by scan
fi

# Q7: Database (if greenfield)
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo ""
  echo "Q7. Primary database?"
  echo "  1. PostgreSQL (recommended for relational data)"
  echo "  2. MySQL/MariaDB"
  echo "  3. MongoDB (document store)"
  echo "  4. SQLite (local/small projects)"
  echo "  5. Other / None yet"
  read -p "Choice (1-5): " DB_CHOICE

  case $DB_CHOICE in
    1) DATABASE="PostgreSQL";;
    2) DATABASE="MySQL";;
    3) DATABASE="MongoDB";;
    4) DATABASE="SQLite";;
    5) read -p "Specify database: " DATABASE;;
    *) DATABASE="PostgreSQL";;
  esac
else
  # Brownfield: Detect from code
  echo ""
  echo "Q7. Database (auto-detected)..."
  # Claude Code: Scan for database usage
  # - Check package.json / requirements.txt for pg, mysql, mongoose
  # - Look for connection strings in env.example
  DATABASE="[NEEDS CLARIFICATION]"
fi

# Q8: Deployment Platform (if greenfield)
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo ""
  echo "Q8. Deployment platform?"
  echo "  1. Vercel (Next.js, frontend)"
  echo "  2. Railway (full-stack, Docker)"
  echo "  3. AWS (flexible, complex)"
  echo "  4. Render"
  echo "  5. Self-hosted / Other"
  read -p "Choice (1-5): " DEPLOY_CHOICE

  case $DEPLOY_CHOICE in
    1) DEPLOY_PLATFORM="Vercel";;
    2) DEPLOY_PLATFORM="Railway";;
    3) DEPLOY_PLATFORM="AWS";;
    4) DEPLOY_PLATFORM="Render";;
    5) read -p "Specify platform: " DEPLOY_PLATFORM;;
    *) DEPLOY_PLATFORM="Vercel";;
  esac
else
  # Brownfield: Check for vercel.json, railway.json, etc.
  echo ""
  echo "Q8. Deployment platform (auto-detected)..."
  DEPLOY_PLATFORM="[NEEDS CLARIFICATION]"
fi

# Q9: API Style
echo ""
echo "Q9. API style?"
echo "  1. REST (recommended for most projects)"
echo "  2. GraphQL"
echo "  3. tRPC (TypeScript end-to-end)"
echo "  4. gRPC"
echo "  5. Other / None"
read -p "Choice (1-5): " API_CHOICE

case $API_CHOICE in
  1) API_STYLE="REST";;
  2) API_STYLE="GraphQL";;
  3) API_STYLE="tRPC";;
  4) API_STYLE="gRPC";;
  5) read -p "Specify API style: " API_STYLE;;
  *) API_STYLE="REST";;
esac

# Q10: Authentication
echo ""
echo "Q10. Authentication provider?"
echo "  1. Clerk (recommended for SaaS)"
echo "  2. Auth0"
echo "  3. Supabase Auth"
echo "  4. Roll-your-own (JWT, sessions)"
echo "  5. None / Public app"
read -p "Choice (1-5): " AUTH_CHOICE

case $AUTH_CHOICE in
  1) AUTH_PROVIDER="Clerk";;
  2) AUTH_PROVIDER="Auth0";;
  3) AUTH_PROVIDER="Supabase Auth";;
  4) AUTH_PROVIDER="Custom (JWT)";;
  5) AUTH_PROVIDER="None (public app)";;
  *) AUTH_PROVIDER="Clerk";;
esac

# Q11: Monthly Budget (MVP)
echo ""
read -p "Q11. Monthly infrastructure budget (USD) for MVP? (e.g., 50): $" BUDGET_MVP

# Q12: Data Privacy Requirements
echo ""
echo "Q12. Data privacy requirements?"
echo "  1. Public data (no sensitive info)"
echo "  2. PII (names, emails)"
echo "  3. GDPR compliance required"
echo "  4. HIPAA compliance required"
echo "  5. Other / Unsure"
read -p "Choice (1-5): " PRIVACY_CHOICE

case $PRIVACY_CHOICE in
  1) PRIVACY="public";;
  2) PRIVACY="PII";;
  3) PRIVACY="GDPR";;
  4) PRIVACY="HIPAA";;
  5) read -p "Specify privacy requirements: " PRIVACY;;
  *) PRIVACY="PII";;
esac

# Q13: Git Workflow
echo ""
echo "Q13. Git workflow preference?"
echo "  1. GitHub Flow (simple, recommended for small teams)"
echo "  2. Git Flow (feature/develop/main branches)"
echo "  3. Trunk-Based Development"
read -p "Choice (1-3): " GIT_WORKFLOW_CHOICE

case $GIT_WORKFLOW_CHOICE in
  1) GIT_WORKFLOW="GitHub Flow";;
  2) GIT_WORKFLOW="Git Flow";;
  3) GIT_WORKFLOW="Trunk-Based";;
  *) GIT_WORKFLOW="GitHub Flow";;
esac

# Q14: Deployment Model
echo ""
echo "Q14. Deployment model?"
echo "  1. staging-prod (recommended: staging validation before production)"
echo "  2. direct-prod (deploy directly to production)"
echo "  3. local-only (no remote deployment)"
read -p "Choice (1-3): " DEPLOY_MODEL_CHOICE

case $DEPLOY_MODEL_CHOICE in
  1) DEPLOY_MODEL="staging-prod";;
  2) DEPLOY_MODEL="direct-prod";;
  3) DEPLOY_MODEL="local-only";;
  *) DEPLOY_MODEL="staging-prod";;
esac

# Q15: Frontend Framework (if greenfield and has frontend)
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo ""
  echo "Q15. Frontend framework?"
  echo "  1. Next.js (React, SSR)"
  echo "  2. Vite + React (SPA)"
  echo "  3. Vue/Nuxt"
  echo "  4. Svelte/SvelteKit"
  echo "  5. No frontend (API only)"
  echo "  6. Other"
  read -p "Choice (1-6): " FRONTEND_CHOICE

  case $FRONTEND_CHOICE in
    1) FRONTEND="Next.js";;
    2) FRONTEND="Vite + React";;
    3) FRONTEND="Vue/Nuxt";;
    4) FRONTEND="Svelte";;
    5) FRONTEND="None (API only)";;
    6) read -p "Specify frontend: " FRONTEND;;
    *) FRONTEND="Next.js";;
  esac
else
  echo ""
  echo "Q15. Frontend framework (auto-detected)..."
  # Claude Code: Detect from package.json
  FRONTEND="[NEEDS CLARIFICATION]"
fi

echo ""
echo "✅ Questionnaire complete!"
echo ""
```

## GENERATE PROJECT DOCS (Use Project-Architect Agent)

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 GENERATING PROJECT DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create docs/project directory
mkdir -p docs/project

# Launch project-architect agent to generate all 8 docs
# Agent will:
# 1. Read templates from .spec-flow/templates/project/
# 2. Fill templates with answers from questionnaire
# 3. If brownfield: Scan codebase to fill tech stack, architecture
# 4. Generate realistic examples
# 5. Mark [NEEDS CLARIFICATION] where info missing
# 6. Write 11 files to docs/project/

echo "Generating 11 project documentation files..."
echo "  1. overview.md"
echo "  2. system-architecture.md"
echo "  3. tech-stack.md"
echo "  4. data-architecture.md"
echo "  5. api-strategy.md"
echo "  6. capacity-planning.md"
echo "  7. deployment-strategy.md"
echo "  8. development-workflow.md"
echo "  9. engineering-principles.md"
echo "  10. project-configuration.md"
echo "  11. style-guide.md"
echo ""

# Agent context:
# - PROJECT_TYPE (greenfield | brownfield)
# - All questionnaire answers
# - Template locations
# - Output directory: docs/project/

# Claude Code: Launch project-architect agent
# Provide all questionnaire answers and context
# Agent generates 11 files
```

**Agent Task**: Generate docs/project/*.md

**Agent Prompt**:
You are the project-architect agent. Generate 11 comprehensive project documentation files.

**Input**:
- Project type: $PROJECT_TYPE
- Answers:
  - Name: $PROJECT_NAME
  - Vision: $VISION
  - Users: $PRIMARY_USERS
  - Scale: $SCALE ($MAX_USERS users)
  - Team: $TEAM_SIZE
  - Architecture: $ARCHITECTURE
  - Database: $DATABASE
  - Deployment: $DEPLOY_PLATFORM
  - API: $API_STYLE
  - Auth: $AUTH_PROVIDER
  - Budget: $BUDGET_MVP/mo
  - Privacy: $PRIVACY
  - Git workflow: $GIT_WORKFLOW
  - Deploy model: $DEPLOY_MODEL
  - Frontend: $FRONTEND

**Templates**: `.spec-flow/templates/project/*.md` and `.spec-flow/templates/style-guide.md`

**Output**: 11 files in `docs/project/`

**Instructions**:
1. Read each template
2. Replace placeholders with answers
3. Generate realistic examples (not Lorem Ipsum)
4. If brownfield: Scan codebase (package.json, requirements.txt, src/) to infer tech stack, patterns
5. Mark [NEEDS CLARIFICATION] for missing info (user can fill later)
6. Use Mermaid diagrams for architecture, ERDs
7. Be technology-agnostic where possible (focus on concepts, not specific frameworks)

**Quality**: Docs should be ready for a new developer to read and understand the entire project.

---

## UPDATE CONSTITUTION

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📜 UPDATING CONSTITUTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Add reference to project docs in constitution.md
CONSTITUTION_FILE=".spec-flow/memory/constitution.md"

if [ -f "$CONSTITUTION_FILE" ]; then
  # Check if project docs section already exists
  if grep -q "## Project Documentation" "$CONSTITUTION_FILE"; then
    echo "✓ Constitution already references project docs"
  else
    # Append project documentation section
    cat >> "$CONSTITUTION_FILE" <<'EOF'

---

## Project Documentation

**Location**: `docs/project/`

Comprehensive project-level design documentation:
- `overview.md` - Vision, users, scope, success metrics
- `system-architecture.md` - Components, integrations, Mermaid diagrams
- `tech-stack.md` - Technology choices with rationale
- `data-architecture.md` - ERD, storage strategy, data lifecycle
- `api-strategy.md` - REST patterns, auth, versioning
- `capacity-planning.md` - Micro → scale tiers
- `deployment-strategy.md` - CI/CD, environments, rollback
- `development-workflow.md` - Git flow, PR process, DoD
- `engineering-principles.md` - 8 core engineering standards
- `project-configuration.md` - Deployment model, scale tier, quick changes
- `style-guide.md` - Comprehensive UI/UX design system SST with core 9 rules

**Created**: [DATE] via `/init-project`

**Maintenance**: Update docs when:
- Adding new service/component (system-architecture.md)
- Changing tech stack (tech-stack.md)
- Scaling to next tier (capacity-planning.md)
- Adjusting deployment strategy (deployment-strategy.md)
- Engineering standards evolve (engineering-principles.md)
- Deployment model changes (project-configuration.md)
- Design system changes (style-guide.md - colors, spacing, components)

**Workflow Integration**:
All features MUST align with project architecture:
- `/roadmap` - Checks overview.md for vision alignment, tech-stack.md for feasibility
- `/spec` - References project docs during research
- `/plan` - Heavily integrates with all 11 docs
- `/tasks` - Follows patterns from tech-stack.md, api-strategy.md
- `/quick` - Loads style-guide.md for all UI changes (enforces core 9 rules)
- `/optimize` - Enforces engineering-principles.md quality standards
EOF

    echo "✓ Constitution updated with project docs reference"
  fi
else
  echo "⚠️  Constitution file not found at $CONSTITUTION_FILE"
  echo "   Skipping constitution update."
fi

echo ""
```

## GENERATE PROJECT CLAUDE.MD

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 GENERATING PROJECT CLAUDE.MD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate project-level CLAUDE.md for context navigation
echo "Generating project CLAUDE.md for AI context navigation..."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  pwsh -NoProfile -File .spec-flow/scripts/powershell/generate-project-claude-md.ps1
else
  .spec-flow/scripts/bash/generate-project-claude-md.sh
fi

echo ""
echo "✓ Project CLAUDE.md generated"
echo ""
echo "Benefits:"
echo "  - Token cost: ~2,000 tokens (vs 12,000 for reading all project docs)"
echo "  - Quick navigation to active features and detailed docs"
echo "  - Auto-updated as features progress"
echo ""
```

## GIT COMMIT

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 COMMITTING PROJECT DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Commit all generated docs
git add docs/project/
git add .spec-flow/memory/constitution.md
git add CLAUDE.md

git commit -m "docs: initialize project design documentation

Project: $PROJECT_NAME
Type: $PROJECT_TYPE
Architecture: $ARCHITECTURE
Database: $DATABASE
Deployment: $DEPLOY_PLATFORM ($DEPLOY_MODEL)
Team: $TEAM_SIZE
Scale: $SCALE ($MAX_USERS users initially)

Generated 11 comprehensive docs:
- overview.md (vision, users, scope)
- system-architecture.md (components, Mermaid diagrams)
- tech-stack.md (technology choices)
- data-architecture.md (ERD, storage strategy)
- api-strategy.md (REST, auth, versioning)
- capacity-planning.md (micro → scale path)
- deployment-strategy.md (CI/CD, environments)
- development-workflow.md (git flow, PR process)
- engineering-principles.md (8 core standards)
- project-configuration.md (deployment model, scale tier)
- style-guide.md (comprehensive UI/UX SST with core 9 rules)

Updated:
- constitution.md (references project docs)
- CLAUDE.md (project-level AI context navigation - 2k tokens vs 12k)

Next: Review docs/project/*.md, fill [NEEDS CLARIFICATION] sections

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "✅ Project documentation committed: $COMMIT_HASH"
echo ""
```

## CREATE FOUNDATION ISSUE (Greenfield Only)

**For greenfield projects, auto-create a GitHub Issue for project foundation setup:**

```bash
if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 CREATING FOUNDATION ROADMAP ISSUE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check GitHub authentication
  if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    # Source GitHub roadmap manager
    source .spec-flow/scripts/bash/github-roadmap-manager.sh

    # Generate foundation feature body from tech-stack variables
    FOUNDATION_BODY=$(cat <<EOF
## Problem

New greenfield project needs initial project scaffolding based on documented tech stack.

## Proposed Solution

Create foundational project structure with:

### Frontend ($FRONTEND)
- Initialize $FRONTEND project with TypeScript
- Install core dependencies and UI libraries
- Setup linting (ESLint), formatting (Prettier), type checking
- Create base directory structure (components, pages, utils)
- Configure build and dev scripts

### Backend & Database
- Initialize backend framework
- Setup $DATABASE database connection
- Configure migrations and schema management
- Install dependencies and dev tools
- Create base API structure

### Infrastructure
- Setup deployment platform: $DEPLOY_PLATFORM
- Configure authentication: $AUTH_PROVIDER
- Initialize CI/CD pipeline configuration
- Setup environment variables template

### Development Environment
- Create .env.example with all required variables
- Setup development scripts (dev, build, test, lint)
- Configure Docker (if applicable)
- Initialize git hooks (pre-commit, commit-msg)
- Write comprehensive README with setup instructions

## Acceptance Criteria

- [ ] Frontend dev server runs successfully
- [ ] Backend API server runs successfully (if applicable)
- [ ] Database connection verified (if applicable)
- [ ] All linters and formatters configured and passing
- [ ] README with clear setup instructions created
- [ ] .env.example with all required variables documented
- [ ] First successful build completes without errors
- [ ] Initial deployment configuration validated

## References

- Tech Stack: docs/project/tech-stack.md
- Architecture: docs/project/system-architecture.md
- Deployment: docs/project/deployment-strategy.md
- Data: docs/project/data-architecture.md

## Technical Notes

- Follow tech stack exactly as documented
- Use documented API style: $API_STYLE
- Scale tier: $SCALE (affects infrastructure choices)
- Authentication provider: $AUTH_PROVIDER
EOF
)

    # Create issue with high priority (foundation is critical)
    # Impact: 5 (blocks all other features)
    # Effort: 3 (moderate complexity, well-defined)
    # Confidence: 0.9 (high certainty, clear requirements)
    # Score: (5 × 0.9) / 3 = 1.5 (high priority)
    create_roadmap_issue \
      "Project Foundation Setup" \
      "$FOUNDATION_BODY" \
      5 \
      3 \
      0.9 \
      "infra" \
      "all" \
      "project-foundation"

    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ Created roadmap issue: project-foundation"
      echo "   Priority: HIGH (Score: 1.5)"
      echo "   View: gh issue view project-foundation"
      echo "   When ready: /feature \"project-foundation\""
      echo ""
    else
      echo ""
      echo "⚠️  Failed to create foundation issue"
      echo "   You can create it manually with: /roadmap add \"Project foundation\""
      echo ""
    fi
  else
    echo "ℹ️  GitHub authentication not detected"
    echo "   To auto-create foundation issue, authenticate with: gh auth login"
    echo "   Or manually create later with: /roadmap add \"Project foundation\""
    echo ""
  fi
else
  echo "ℹ️  Brownfield project detected - skipping foundation issue"
  echo "   Existing codebase structure preserved"
  echo ""
fi
```

## RETURN

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PROJECT INITIALIZATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Project: $PROJECT_NAME"
echo "Type: $PROJECT_TYPE"
echo "Architecture: $ARCHITECTURE"
echo "Scale: $SCALE ($MAX_USERS users initially)"
echo "Team: $TEAM_SIZE"
echo "Budget: $BUDGET_MVP/mo (MVP)"
echo ""
echo "📁 Generated Documentation:"
echo "   docs/project/overview.md"
echo "   docs/project/system-architecture.md"
echo "   docs/project/tech-stack.md"
echo "   docs/project/data-architecture.md"
echo "   docs/project/api-strategy.md"
echo "   docs/project/capacity-planning.md"
echo "   docs/project/deployment-strategy.md"
echo "   docs/project/development-workflow.md"
echo "   docs/project/engineering-principles.md"
echo "   docs/project/project-configuration.md"
echo "   docs/project/style-guide.md"
echo ""

# Show foundation issue if created
if [ "$PROJECT_TYPE" = "greenfield" ] && command -v gh &> /dev/null && gh auth status &> /dev/null; then
  echo "🎯 Created Roadmap Issue:"
  echo "   #1 project-foundation (HIGH priority)"
  echo "   View: gh issue view project-foundation"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$PROJECT_TYPE" = "greenfield" ]; then
  echo "🚀 Greenfield Project - Start with foundation:"
  echo ""
  echo "1. Review generated docs:"
  echo "   open docs/project/"
  echo ""
  echo "2. Build project foundation (CRITICAL FIRST STEP):"
  echo "   /feature \"project-foundation\""
  echo "   This will scaffold your $FRONTEND + $DATABASE project"
  echo ""
  echo "3. After foundation is built, add features:"
  echo "   /roadmap"
  echo "   /feature \"your-feature\""
  echo ""
else
  echo "📦 Brownfield Project - Existing codebase detected:"
  echo ""
  echo "1. Review generated docs:"
  echo "   open docs/project/"
  echo ""
  echo "2. Fill [NEEDS CLARIFICATION] sections (if any):"
  echo "   grep -r 'NEEDS CLARIFICATION' docs/project/"
  echo ""
  echo "3. Customize for your project:"
  echo "   - Add specific technologies"
  echo "   - Update Mermaid diagrams"
  echo "   - Refine capacity estimates"
  echo ""
  echo "4. Start building features:"
  echo "   /roadmap"
  echo "   /feature \"your-first-feature\""
  echo ""
fi

echo "💡 Tip: Update project docs as your project evolves."
echo "    They're living documents, not one-time artifacts."
echo ""
```

---
description: Initialize project design documentation with idempotent operation modes
---

Initialize project-level system design: $ARGUMENTS

<context>
## PURPOSE

Create comprehensive project documentation that answers:
- **What**: Vision, users, scope (overview.md)
- **How**: System architecture (C4 model), tech stack (system-architecture.md, tech-stack.md)
- **Data**: Data architecture (ERD), API strategy (data-architecture.md, api-strategy.md)
- **Scale**: Capacity planning (capacity-planning.md)
- **Deploy**: Deployment strategy (deployment-strategy.md)
- **Team**: Development workflow (development-workflow.md)
- **Standards**: Engineering principles, ADRs (docs/adr/0001-baseline.md)

These docs are the foundation for all features. Can be run multiple times with different modes.

## WORKFLOW INTEGRATION

```
/init-project (once or multiple times) → /roadmap (ongoing) → /feature (per-feature)
```

## OPERATION MODES

**First-time setup** (default):
```bash
/init-project "ProjectName"
```

**Update mode** (only fix [NEEDS CLARIFICATION] sections):
```bash
/init-project --update
```

**Force overwrite** (destructive, regenerate all docs):
```bash
/init-project --force
```

**Write missing only** (preserve existing files):
```bash
/init-project --write-missing-only
```

**CI/CD mode** (non-interactive, fail on missing answers):
```bash
INIT_NAME="MyProject" INIT_VISION="..." /init-project --ci
```

**Config file mode** (load from YAML/JSON):
```bash
/init-project --config project-config.json --non-interactive
```

## USER INPUT

**Interactive mode** (default):
- Project name: `$ARGUMENTS` or prompted
- 15 questions about project vision, tech stack, scale, team

**Non-interactive mode**:
- Environment variables: `INIT_NAME`, `INIT_VISION`, `INIT_USERS`, etc.
- Config file: JSON or YAML with all answers
</context>

## IDEMPOTENT OPERATION

The `/init-project` command is now **idempotent** - safe to run multiple times with different modes:

**Modes**:
- `default`: First-time setup (asks before overwriting)
- `--force`: Overwrite all existing docs (destructive)
- `--update`: Only update `[NEEDS CLARIFICATION]` sections (safe)
- `--write-missing-only`: Only create missing files, preserve existing

**Environment Variables** (for non-interactive/CI mode):
```bash
# Required (CI mode only)
INIT_NAME              # Project name
INIT_VISION            # One-sentence vision
INIT_USERS             # Primary users

# Optional (defaults provided)
INIT_SCALE             # micro | small | medium | large
INIT_TEAM_SIZE         # solo | small | medium | large
INIT_ARCHITECTURE      # monolith | microservices | serverless
INIT_DATABASE          # PostgreSQL | MySQL | MongoDB | SQLite
INIT_DEPLOY_PLATFORM   # Vercel | Railway | AWS | Render
INIT_API_STYLE         # REST | GraphQL | tRPC | gRPC
INIT_AUTH_PROVIDER     # Clerk | Auth0 | Supabase | Custom | None
INIT_BUDGET_MVP        # Monthly budget USD (e.g., "50")
INIT_PRIVACY           # public | PII | GDPR | HIPAA
INIT_GIT_WORKFLOW      # GitHub Flow | Git Flow | Trunk-Based
INIT_DEPLOY_MODEL      # staging-prod | direct-prod | local-only
INIT_FRONTEND          # Next.js | Vite + React | Vue | Svelte
```

**Config File Format** (JSON):
```json
{
  "project": {
    "name": "FlightPro",
    "vision": "Student pilot progress tracking for flight instructors",
    "users": "Flight instructors and student pilots",
    "scale": "small",
    "team_size": "solo",
    "architecture": "monolith",
    "database": "PostgreSQL",
    "deploy_platform": "Vercel",
    "api_style": "REST",
    "auth_provider": "Clerk",
    "budget_mvp": "50",
    "privacy": "PII",
    "git_workflow": "GitHub Flow",
    "deploy_model": "staging-prod",
    "frontend": "Next.js"
  }
}
```

**Config File Format** (YAML):
```yaml
project:
  name: FlightPro
  vision: Student pilot progress tracking for flight instructors
  users: Flight instructors and student pilots
  scale: small
  team_size: solo
  architecture: monolith
  database: PostgreSQL
  deploy_platform: Vercel
  api_style: REST
  auth_provider: Clerk
  budget_mvp: "50"
  privacy: PII
  git_workflow: GitHub Flow
  deploy_model: staging-prod
  frontend: Next.js
```

## QUALITY GATES

**Automated checks before commit**:

1. **[NEEDS CLARIFICATION] detection**: Warns if unanswered questions remain
   - **CI mode**: Fails (exit code 2)
   - **Interactive mode**: Warning only

2. **Markdown linting** (if `markdownlint` installed):
   - Checks formatting, structure
   - **Non-blocking** in all modes

3. **Link checking** (if `lychee` installed):
   - Validates all internal/external links
   - **Non-blocking** in all modes

4. **C4 model validation**:
   - Ensures Context/Container/Component sections exist in `system-architecture.md`
   - **CI mode**: Fails if missing
   - **Interactive mode**: Warning only

**Exit codes**:
- `0`: Success
- `1`: Missing required input (CI mode)
- `2`: Quality gate failure (CI mode)

## EXECUTION

**Call the appropriate script** based on your operating system:

### Windows (PowerShell):
```powershell
# Default mode (interactive)
pwsh -File .spec-flow/scripts/powershell/init-project.ps1 "ProjectName"

# Update mode
pwsh -File .spec-flow/scripts/powershell/init-project.ps1 -Update

# Force overwrite
pwsh -File .spec-flow/scripts/powershell/init-project.ps1 -Force

# CI mode with environment variables
$env:INIT_NAME="MyProject"; $env:INIT_VISION="..."; pwsh -File .spec-flow/scripts/powershell/init-project.ps1 -CI

# Config file mode
pwsh -File .spec-flow/scripts/powershell/init-project.ps1 -ConfigFile project-config.json -NonInteractive
```

### macOS/Linux (Bash):
```bash
# Default mode (interactive)
.spec-flow/scripts/bash/init-project.sh "ProjectName"

# Update mode
.spec-flow/scripts/bash/init-project.sh --update

# Force overwrite
.spec-flow/scripts/bash/init-project.sh --force

# CI mode with environment variables
INIT_NAME="MyProject" INIT_VISION="..." .spec-flow/scripts/bash/init-project.sh --ci

# Config file mode
.spec-flow/scripts/bash/init-project.sh --config project-config.json --non-interactive
```

## BROWNFIELD SCANNING

**Auto-detection** when existing codebase found:

**Detected indicators**:
- `package.json` → Node.js project
- `requirements.txt` / `pyproject.toml` → Python project
- `Cargo.toml` → Rust project
- `go.mod` → Go project

**Auto-inferred values**:
- **Database**: Scanned from dependencies (`pg`, `mysql2`, `mongoose`, `psycopg2`)
- **Frontend**: Detected from `package.json` (`next`, `vite`, `vue`, etc.)
- **Deployment**: Detected from config files (`vercel.json`, `railway.json`, etc.)
- **Architecture**: Inferred from `docker-compose.yml` service count and directory structure

**Result**: 20-30% fewer `[NEEDS CLARIFICATION]` tokens in generated docs

## QUESTIONNAIRE (15 QUESTIONS)

**Interactive mode** (~10 minutes):

1. **Project name** - e.g., "FlightPro", "AcmeApp"
2. **Vision** - One sentence: "What does this project do?"
3. **Primary users** - e.g., "Flight instructors"
4. **Expected scale** - Micro (<100) | Small (100-1K) | Medium (1K-10K) | Large (10K+)
5. **Team size** - Solo | Small (2-5) | Medium (5-15) | Large (15+)
6. **Architecture** - Monolith | Microservices | Serverless (auto-detected for brownfield)
7. **Database** - PostgreSQL | MySQL | MongoDB | SQLite (auto-detected for brownfield)
8. **Deployment platform** - Vercel | Railway | AWS | Render (auto-detected for brownfield)
9. **API style** - REST | GraphQL | tRPC | gRPC
10. **Authentication** - Clerk | Auth0 | Supabase | Custom | None
11. **Monthly budget** - USD for MVP (e.g., $50)
12. **Privacy** - Public | PII | GDPR | HIPAA
13. **Git workflow** - GitHub Flow | Git Flow | Trunk-Based
14. **Deployment model** - staging-prod | direct-prod | local-only
15. **Frontend framework** - Next.js | Vite+React | Vue | Svelte (auto-detected for brownfield)

**Greenfield** (new project): Answer all questions
**Brownfield** (existing code): Questions 6-8, 15 auto-detected, fewer manual answers

## GENERATED OUTPUTS

The scripts generate the following outputs:

### Project Documentation (8 files in `docs/project/`)

1. **overview.md** - Vision, target users, scope, success metrics, competitive landscape
2. **system-architecture.md** - C4 diagrams (Context/Container/Component), data flows, security architecture
3. **tech-stack.md** - All technology choices with rationale and alternatives rejected
4. **data-architecture.md** - ERD (Mermaid), entity schemas, storage strategy, migrations
5. **api-strategy.md** - REST/GraphQL patterns, auth, versioning, error handling (RFC 7807)
6. **capacity-planning.md** - Scaling from micro (100 users) to 1000x growth with cost model
7. **deployment-strategy.md** - CI/CD pipeline, environments (dev/staging/prod), rollback
8. **development-workflow.md** - Git flow, PR process, testing strategy, Definition of Done

### Architecture Decision Records (`docs/adr/`)

- **0001-project-architecture-baseline.md** - Baseline ADR documenting initial tech stack choices, architectural style, and rationale

### Optional Meta Files (Project Root)

If enabled (not created by default, can be generated with `--meta-files` flag):

- **CONTRIBUTING.md** - Contribution guidelines, branch naming, commit conventions, PR process
- **SECURITY.md** - Security policy, vulnerability reporting, security best practices
- **CODEOWNERS** - GitHub code ownership for automatic PR review assignment

### Project CLAUDE.md

- **CLAUDE.md** (project root) - AI context navigation file
  - Token cost: ~2,000 tokens (vs 12,000 for all project docs)
  - Auto-updated as features progress
  - Quick reference to active features and tech stack

### Git Commit

All generated files committed with comprehensive message:
- Lists all generated docs
- Records project type (greenfield/brownfield)
- Documents tech stack choices
- Includes mode used (default/force/update)

## FOUNDATION ISSUE (Greenfield Projects Only)

**Auto-created for greenfield projects** (if GitHub authenticated):

- **Issue title**: "Project Foundation Setup"
- **Priority**: HIGH (blocks all other features)
- **Content**:
  - Frontend scaffolding ({{FRONTEND}})
  - Backend setup
  - Database connection ({{DATABASE}})
  - Deployment config ({{DEPLOY_PLATFORM}})
  - Authentication ({{AUTH_PROVIDER}})
  - Linting, formatting, TypeScript
  - .env.example template
  - CI/CD pipeline init
  - README with setup instructions

**Created via**: GitHub CLI (`gh issue create`)
**View**: `gh issue view project-foundation`
**Start**: `/feature "project-foundation"`

**Skipped if**:
- Brownfield project (existing codebase detected)
- GitHub CLI not installed
- Not authenticated (`gh auth login`)

## FINAL OUTPUT

The scripts display a summary with:

**Project Details**:
- Name, type (greenfield/brownfield)
- Architecture, database, deployment platform
- Scale tier, team size, budget

**Generated Files**:
- List of all 8 project docs
- ADR-0001 baseline
- Optional meta files (if enabled)
- Project CLAUDE.md

**Foundation Issue** (greenfield only):
- GitHub issue number and priority
- Command to start: `/feature "project-foundation"`

**Next Steps**:
- **Greenfield**: Build foundation first, then add features
- **Brownfield**: Review docs, fill `[NEEDS CLARIFICATION]`, start features

**Important**: All documentation files support `{{VARIABLE}}` placeholders that get replaced during rendering.

# Project Initialization Phase - Reference Documentation

## Operation Modes

### Default Mode (First-Time Setup)

**Usage:**
```bash
/init-project "ProjectName"
```

**Behavior:**
- Interactive questionnaire (15 core questions)
- Asks before overwriting existing files
- Auto-detects brownfield project state
- Creates all 8 core documentation files
- Creates ADR-0001 baseline
- Commits all generated files
- Creates foundation GitHub issue (greenfield only)

---

### Update Mode

**Usage:**
```bash
/init-project --update
```

**Behavior:**
- Only updates `[NEEDS CLARIFICATION]` sections
- Preserves all other existing content
- Non-destructive (safe to run multiple times)
- Scans all docs for `[NEEDS CLARIFICATION]` tokens
- Prompts for missing information only
- Re-commits with "docs: fill clarifications" message

**Use case**: After reviewing generated docs, fill in sections that need manual input

---

### Force Overwrite Mode

**Usage:**
```bash
/init-project --force
```

**Behavior:**
- **DESTRUCTIVE**: Overwrites all existing docs
- Re-runs full questionnaire
- Replaces all 8 project docs + ADR
- Use when project fundamentals have changed (e.g., switched from monolith to microservices)

**Warning**: This will lose any manual edits to generated docs

---

### Write Missing Only Mode

**Usage:**
```bash
/init-project --write-missing-only
```

**Behavior:**
- Only creates files that don't exist
- Preserves all existing files completely
- Safe for partial initialization
- Useful when manually creating some docs

---

### CI/CD Mode

**Usage:**
```bash
INIT_NAME="MyProject" INIT_VISION="..." /init-project --ci
```

**Behavior:**
- Non-interactive (fails if answers missing)
- Reads all values from environment variables
- Fails with exit code 1 if required vars missing
- Fails with exit code 2 if quality gates fail
- Suitable for automated pipelines

**Required environment variables:**
- `INIT_NAME` - Project name
- `INIT_VISION` - One-sentence vision
- `INIT_USERS` - Primary users

**Optional environment variables:**
```bash
INIT_SCALE              # micro | small | medium | large
INIT_TEAM_SIZE          # solo | small | medium | large
INIT_ARCHITECTURE       # monolith | microservices | serverless
INIT_DATABASE           # PostgreSQL | MySQL | MongoDB | SQLite
INIT_DEPLOY_PLATFORM    # Vercel | Railway | AWS | Render
INIT_API_STYLE          # REST | GraphQL | tRPC | gRPC
INIT_AUTH_PROVIDER      # Clerk | Auth0 | Supabase | Custom | None
INIT_BUDGET_MVP         # Monthly budget USD (e.g., "50")
INIT_PRIVACY            # public | PII | GDPR | HIPAA
INIT_GIT_WORKFLOW       # GitHub Flow | Git Flow | Trunk-Based
INIT_DEPLOY_MODEL       # staging-prod | direct-prod | local-only
INIT_FRONTEND           # Next.js | Vite + React | Vue | Svelte
```

---

### Config File Mode

**Usage:**
```bash
/init-project --config project-config.json --non-interactive
```

**Behavior:**
- Loads all answers from JSON or YAML file
- Non-interactive (no prompts)
- Supports partial configs (prompts for missing values unless --non-interactive)
- Validates config structure

**JSON format:**
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

**YAML format:**
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

---

### Design System Mode

**Usage:**
```bash
/init-project --with-design "ProjectName"
```

**Behavior:**
- Runs all 15 core questions PLUS 33 design questions
- Total: 48 questions (~20-30 minutes)
- Generates 8 project docs + 4 design docs + tokens
- Auto-generates design/systems/tokens.css
- Auto-generates design/systems/tokens.json
- WCAG AA compliant (4.5:1 contrast auto-fixed)
- Uses OKLCH color space for perceptual uniformity

**Additional outputs:**
1. `docs/design/brand-guidelines.md`
2. `docs/design/visual-language.md`
3. `docs/design/accessibility-standards.md`
4. `docs/design/component-governance.md`
5. `design/systems/tokens.css`
6. `design/systems/tokens.json`

---

## Questionnaire

### Core Questions (15 - Required)

**Interactive mode (~10 minutes):**

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

---

### Design System Questions (33 - Only with --with-design flag)

#### Brand Personality (8 questions, ~3 minutes)

16. **Brand personality** - Playful/Serious, Minimal/Rich, Bold/Subtle?
17. **Target emotional response** - How should users feel? (e.g., "Confident and empowered")
18. **Brand keywords** - 3-5 words that describe your brand (e.g., "Fast, Secure, Friendly")
19. **Competitive differentiation** - How does your brand differ from competitors?
20. **Primary color preference** - Hex code or name (e.g., "#3b82f6" or "Blue")
21. **Visual style** - Modern/Classic, Geometric/Organic, Tech/Human?
22. **Typography style** - Geometric/Humanist/Monospace for primary font?
23. **Density preference** - Compact/Comfortable/Spacious UI spacing?

#### Visual Language (12 questions, ~4 minutes)

24. **Color palette size** - Minimal (3-4 colors) | Standard (5-7 colors) | Rich (8+ colors)
25. **Neutrals approach** - True grays | Warm grays | Cool grays | Brand-tinted?
26. **Semantic color needs** - Success/Warning/Error only, or also Info/Notice/Help?
27. **Surface colors** - How many background levels? (1 = white only, 3 = primary/secondary/tertiary)
28. **Type scale** - Conservative (6 sizes) | Standard (8 sizes) | Expressive (10+ sizes)
29. **Font weights needed** - Normal/Bold only | Normal/Medium/Semibold/Bold | Full range (100-900)
30. **Line-height system** - Fixed (1.5 everywhere) | Responsive (tight for headings, relaxed for body)
31. **Heading style** - Uppercase/Sentence-case/Title-case?
32. **Border radius** - Sharp (0-2px) | Rounded (4-8px) | Very rounded (12-16px) | Pill-shaped?
33. **Shadow style** - None/Minimal | Subtle elevation | Bold depth | Neumorphic?
34. **Icon style** - Outline | Solid | Duotone | Auto (match brand personality)?
35. **Illustration style** - None | Abstract | Pictorial | Photography?

#### Accessibility (6 questions, ~2 minutes)

36. **WCAG compliance level** - AA (standard) | AAA (high contrast) | A (minimum)
37. **Motion preferences** - Full animations | Respect prefers-reduced-motion | Minimal motion
38. **Contrast requirements** - Text ≥4.5:1 (AA) | ≥7:1 (AAA) | ≥3:1 (large text only)
39. **Focus indicators** - Outline | Ring | Underline | Glow?
40. **Screen reader priority** - Standard support | Enhanced ARIA | Optimized landmarks?
41. **Keyboard navigation** - Standard tab order | Custom shortcuts | Skip links?

#### Layout & Interaction (7 questions, ~3 minutes)

42. **Spacing scale** - Tailwind-style (0-96) | Custom (define base unit) | t-shirt sizes (xs-3xl)
43. **Breakpoint strategy** - Mobile-first | Desktop-first | Mobile/Tablet/Desktop | All devices (5+ breakpoints)
44. **Grid system** - 12-column | 16-column | Flexbox-only | CSS Grid-only | Hybrid?
45. **Component states** - Hover/Active only | Add Disabled/Loading | Add Error/Success | All states (8+)
46. **Animation defaults** - Duration: 150ms/300ms/500ms? Easing: ease-in-out/cubic-bezier?
47. **Hover intent** - Instant | Delayed (200ms) | Touch-friendly (no hover states)?
48. **Loading patterns** - Spinner | Skeleton | Progress bar | Shimmer effect?

**Total with --with-design**: 48 questions (~20-30 minutes)

---

## Brownfield Scanning

**Auto-detection when existing codebase found:**

### Detected Indicators

- `package.json` → Node.js project
- `requirements.txt` / `pyproject.toml` → Python project
- `Cargo.toml` → Rust project
- `go.mod` → Go project
- `docker-compose.yml` → Microservices architecture hint
- `vercel.json` / `railway.json` → Deployment platform
- `.github/workflows/*.yml` → CI/CD setup

### Auto-Inferred Values

**Database**: Scanned from dependencies
- `pg`, `postgres` → PostgreSQL
- `mysql2`, `mysql` → MySQL
- `mongoose`, `mongodb` → MongoDB
- `sqlite3` → SQLite

**Frontend**: Detected from `package.json`
- `next` → Next.js
- `vite` → Vite + React
- `vue` → Vue
- `svelte` → Svelte

**Deployment**: Detected from config files
- `vercel.json` → Vercel
- `railway.json` / `railway.toml` → Railway
- `app.yaml` → Google App Engine
- `Procfile` → Heroku

**Architecture**: Inferred from structure
- `docker-compose.yml` with >3 services → Microservices
- `functions/` or `lambda/` directory → Serverless
- Single `app/` or `src/` directory → Monolith

**Result**: 20-30% fewer `[NEEDS CLARIFICATION]` tokens in generated docs

---

## Quality Gates

**Automated checks before commit:**

### 1. [NEEDS CLARIFICATION] Detection

**Trigger**: Scans all generated docs for `[NEEDS CLARIFICATION]` tokens

**Behavior:**
- **CI mode**: Fails (exit code 2) if any found
- **Interactive mode**: Warning only, lists files and line numbers

**Example output:**
```
⚠️  Found 3 [NEEDS CLARIFICATION] sections:
  - overview.md:45 - Success metrics
  - api-strategy.md:120 - Error response format
  - capacity-planning.md:80 - Scale tier 2 costs
```

### 2. Markdown Linting

**Tool**: `markdownlint` (if installed)

**Checks**:
- Heading structure (no skipped levels)
- List formatting consistency
- Code block language hints
- No bare URLs (must use link syntax)

**Behavior**: Non-blocking in all modes (warnings only)

### 3. Link Checking

**Tool**: `lychee` (if installed)

**Checks**:
- All internal links (`./`, `../`, absolute paths)
- All external links (HTTP/HTTPS)
- Anchors within documents

**Behavior**: Non-blocking in all modes (warnings only)

### 4. C4 Model Validation

**Checks**:
- `system-architecture.md` contains Context, Container, Component sections
- Each section has Mermaid diagram
- Diagram syntax validates

**Behavior:**
- **CI mode**: Fails if missing sections
- **Interactive mode**: Warning only

### Exit Codes

- `0`: Success
- `1`: Missing required input (CI mode)
- `2`: Quality gate failure (CI mode)

---

## Generated Outputs

### Project Documentation (8 files in `docs/project/`)

1. **overview.md** - Vision, target users, scope, success metrics, competitive landscape
2. **system-architecture.md** - C4 diagrams (Context/Container/Component), data flows, security architecture
3. **tech-stack.md** - All technology choices with rationale and alternatives rejected
4. **data-architecture.md** - ERD (Mermaid), entity schemas, storage strategy, migrations
5. **api-strategy.md** - REST/GraphQL patterns, auth, versioning, error handling (RFC 7807)
6. **capacity-planning.md** - Scaling from micro (100 users) to 1000x growth with cost model
7. **deployment-strategy.md** - CI/CD pipeline, environments (dev/staging/prod), rollback
8. **development-workflow.md** - Git flow, PR process, testing strategy, Definition of Done

### Design System Documentation (4 files in `docs/design/` - Only with --with-design)

1. **brand-guidelines.md** - Brand personality, voice, emotional goals, competitive differentiation, brand keywords
2. **visual-language.md** - Color system, typography, spacing, border radius, shadows, icons, illustrations
3. **accessibility-standards.md** - WCAG compliance level, contrast requirements, motion preferences, keyboard navigation, ARIA patterns
4. **component-governance.md** - Component state requirements, animation defaults, loading patterns, interaction standards

### Design Tokens (Auto-generated with --with-design)

**design/systems/tokens.css** - Complete design token system:
- Color scales (primary, neutral, semantic colors)
- Spacing scale (based on density preference)
- Typography (font families, sizes, weights, line-heights)
- Border radius, shadows
- Multi-surface tokens (UI, emails, PDFs, CLI, charts, docs)
- **WCAG AA compliant** (4.5:1 contrast ratios auto-fixed)
- **OKLCH color space** (perceptually uniform adjustments)

**design/systems/tokens.json** - JSON reference for programmatic access

### Architecture Decision Records (`docs/adr/`)

**0001-project-architecture-baseline.md** - Baseline ADR documenting:
- Initial tech stack choices
- Architectural style decision
- Rationale for each choice
- Alternatives considered
- Consequences and trade-offs

### Project CLAUDE.md

**CLAUDE.md** (project root) - AI context navigation file:
- Token cost: ~2,000 tokens (vs 12,000 for all project docs)
- Auto-updated as features progress
- Quick reference to active features and tech stack
- Links to relevant documentation sections

### Git Commit

All generated files committed with comprehensive message:
- Lists all generated docs
- Records project type (greenfield/brownfield)
- Documents tech stack choices
- Includes mode used (default/force/update)

**Example commit:**
```
docs: initialize project design documentation

Generated 8 project docs:
- overview.md (vision, users, scope)
- system-architecture.md (C4 diagrams)
- tech-stack.md (Next.js, PostgreSQL, Vercel)
- data-architecture.md (ERD)
- api-strategy.md (REST, RFC 7807)
- capacity-planning.md (small scale tier)
- deployment-strategy.md (staging-prod model)
- development-workflow.md (GitHub Flow)

ADR: 0001-project-architecture-baseline.md

Project type: greenfield
Tech stack: Next.js + PostgreSQL + Vercel
Mode: default (interactive)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Foundation Issue (Greenfield Projects Only)

**Auto-created for greenfield projects** (if GitHub authenticated):

### Issue Content

**Title**: "Project Foundation Setup"

**Priority**: HIGH (blocks all other features)

**Description**:
```markdown
Initial project scaffolding and infrastructure setup.

**Checklist**:
- [ ] Frontend scaffolding ({{FRONTEND}})
- [ ] Backend setup
- [ ] Database connection ({{DATABASE}})
- [ ] Deployment config ({{DEPLOY_PLATFORM}})
- [ ] Authentication ({{AUTH_PROVIDER}})
- [ ] Linting, formatting, TypeScript
- [ ] .env.example template
- [ ] CI/CD pipeline init
- [ ] README with setup instructions

**Priority**: HIGH - Blocks all other features
```

### Creation

**Created via**: GitHub CLI (`gh issue create`)

**View**: `gh issue view project-foundation`

**Start**: `/feature "project-foundation"`

### Skipped If

- Brownfield project (existing codebase detected)
- GitHub CLI not installed
- Not authenticated (`gh auth login`)

---

## Prerequisites

### Required Tools

- `git` — Version control
- `jq` — JSON parsing (for config file mode)
- `yq` — YAML parsing (for config file mode with YAML)

**Check command**:
```bash
for tool in git jq yq; do
  command -v "$tool" >/dev/null || echo "Missing: $tool"
done
```

### Optional Tools

- `markdownlint` — Markdown linting (quality gate)
- `lychee` — Link checking (quality gate)
- `gh` — GitHub CLI (for foundation issue creation)

### Required State

- Git repository initialized (`.git/` exists)
- No required state for greenfield (creates from scratch)
- For brownfield: Existing codebase with package.json or equivalent

---

## Version History

**v2.0** (2025-11-17):
- Added design system mode (--with-design)
- Added 33 design questions
- Auto-generated design tokens (tokens.css, tokens.json)
- WCAG AA compliance auto-fixing
- OKLCH color space support

**v1.5** (2025-10-01):
- Added brownfield scanning
- Auto-detection of tech stack from codebase
- 20-30% fewer clarifications for brownfield

**v1.0** (2025-08-15):
- Initial release with 8 project docs
- Interactive questionnaire (15 questions)
- ADR-0001 baseline creation
- Foundation issue generation

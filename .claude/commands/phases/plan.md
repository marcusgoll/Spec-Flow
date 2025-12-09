---
description: Generate implementation plan from spec using research-driven design (meta-prompting for epics)
allowed-tools: [Read, Bash, Task, AskUserQuestion]
argument-hint: [feature-name or epic-slug]
version: 11.0
updated: 2025-12-09
---

# /plan — Implementation Plan Generator (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `plan-phase-agent` via Task(). All planning logic runs in isolated context with question batching.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated plan-phase-agent to generate implementation plan from spec.

**Architecture (v11.0 - Phase Isolation):**
```
/plan → Task(plan-phase-agent) → Q&A loop if needed → plan.md + research.md
```

**Agent responsibilities:**
- Read spec.md and project documentation
- Search codebase for reuse opportunities
- Generate architectural decisions
- Return questions for major design choices
- Create plan.md with components and estimates

**Workflow position**: `spec → clarify → plan → tasks → implement → optimize → ship`
</objective>

## Legacy Context (for agent reference)

<legacy_context>
**Feature Classification** (from state.yaml if exists):
!`cat specs/*/state.yaml 2>/dev/null | grep -E "HAS_UI|IS_IMPROVEMENT|recommended_workflow" | head -5 || echo "No classification available"`

**Tech Stack Context** (prevents hallucination):
!`head -30 docs/project/tech-stack.md 2>/dev/null || echo "Not available - will analyze codebase"`

**Data Architecture Context** (prevents duplicate entities):
!`head -20 docs/project/data-architecture.md 2>/dev/null || echo "Not available - will analyze codebase"`
</legacy_context>

<research_instructions>
## REQUIRED RESEARCH STEPS (Claude Code Must Execute)

**Before generating plan.md, you MUST perform this research:**

### Step R1: Read Feature Spec
```
Read the spec.md file completely. Extract:
- All functional requirements (FR-XXX)
- All non-functional requirements (NFR-XXX)
- Success criteria (measurable outcomes)
- Classification flags (HAS_UI, IS_IMPROVEMENT, etc.)
```

### Step R2: Search for Reusable Components

**PRIMARY: Semantic search (mgrep) for pattern discovery:**
```bash
# Use mgrep to find similar implementations by meaning
mgrep "services that handle user authentication"
mgrep "API endpoints for data retrieval"
mgrep "form components with validation"
mgrep "database models with timestamps"
```

mgrep finds similar code even when naming conventions differ (e.g., finds UserService, AuthenticationHandler, LoginManager when searching for "authentication services").

**SECONDARY: Literal searches (when mgrep insufficient):**

**Backend patterns** (execute these Grep/Glob searches):
```bash
# Find existing service patterns
Glob("api/src/services/*.py")       # or api/app/services/
Glob("api/src/modules/*/service.py")

# Find existing repository patterns
Grep("class.*Repository", path="api/", type="py")

# Find existing schemas/validators
Glob("api/src/**/schemas.py")
```

**Frontend patterns** (execute these Grep/Glob searches):
```bash
# Find existing UI components
Glob("apps/*/components/**/*.tsx")
Glob("src/components/**/*.tsx")

# Find existing hooks
Grep("export function use", path="apps/", glob="*.ts*")
Grep("export const use", path="apps/", glob="*.ts*")

# Find existing layouts
Glob("apps/*/app/**/layout.tsx")
```

**Database patterns** (if HAS_MIGRATIONS detected):
```bash
# Find existing migrations to understand naming/style
Glob("api/migrations/versions/*.py")   # Alembic
Glob("prisma/migrations/**/*.sql")     # Prisma

# Find existing models
Grep("class.*Model|Table\\(", path="api/", type="py")
```

### Step R3: Analyze Similar Implementations

For each major component needed:
1. Search codebase for similar functionality
2. Read the found file(s) to understand patterns
3. Document as "reusable" or "new needed"

**Example workflow**:
```
If spec requires "user preferences storage":
  1. Grep("preferences|settings|user.*config", path="api/")
  2. Read matching files
  3. If found: REUSABLE_COMPONENTS+=("api/src/services/preferences.py")
  4. If not found: NEW_COMPONENTS+=("api/src/services/preferences.py: New service needed")
```

### Step R4: Verify Dependencies

Before recommending any library:
```bash
# Check package.json for existing dependencies
Grep("library-name", path="package.json")

# Check requirements.txt / pyproject.toml
Grep("library-name", path="requirements.txt")
Grep("library-name", path="pyproject.toml")
```

**Never recommend a library without checking if it's already installed!**

### Step R5: Document Research Decisions

For each architectural decision, provide:
- **Decision**: What was decided
- **Source**: Where you found the pattern (file:line)
- **Rationale**: Why this approach

**Example**:
```markdown
## Research Decisions

1. **State Management**: Use SWR for data fetching
   - Source: `apps/app/lib/swr/config.ts:12-30`
   - Rationale: Already configured with refresh intervals and error handling

2. **API Pattern**: Follow existing FastAPI router structure
   - Source: `api/src/modules/users/controller.py:5-50`
   - Rationale: Consistent with existing codebase conventions
```

### Step R6: Anti-Hallucination Checklist

Before finalizing plan.md, verify:
- [ ] Every "reuse" recommendation cites a specific file path
- [ ] Every "new" component explains why existing code doesn't suffice
- [ ] Every library recommendation was verified in package.json/requirements.txt
- [ ] No speculative statements ("probably", "might", "usually")
- [ ] All tech stack choices match docs/project/tech-stack.md (if exists)

</research_instructions>

<objective>
Generate implementation plan for $ARGUMENTS using research-driven design.

For **epics**: Uses meta-prompting workflow to generate research.md → plan.md via isolated sub-agents
For **features**: Uses traditional planning workflow with project docs integration

This ensures architecture decisions are grounded in existing codebase patterns and project documentation.

**Dependencies**:

- Git repository initialized
- Feature spec completed (spec.md exists)
- Required tools: git, jq, yq (xmllint for epics)

**Autopilot**: Auto-proceeds to next phase after completion. Only blocks on errors.
</objective>

<process>

### Step 0: WORKFLOW TYPE DETECTION

**Detect whether this is an epic or feature workflow:**

```bash
# Run detection utility (cross-platform: tries .sh first, falls back to .ps1)
if command -v bash >/dev/null 2>&1; then
    WORKFLOW_INFO=$(bash .spec-flow/scripts/utils/detect-workflow-paths.sh 2>/dev/null)
    DETECTION_EXIT=$?
else
    WORKFLOW_INFO=$(pwsh -File .spec-flow/scripts/utils/detect-workflow-paths.ps1 2>/dev/null)
    DETECTION_EXIT=$?
fi

# Parse detection result
if [ $DETECTION_EXIT -eq 0 ]; then
    WORKFLOW_TYPE=$(echo "$WORKFLOW_INFO" | jq -r '.type')
    BASE_DIR=$(echo "$WORKFLOW_INFO" | jq -r '.base_dir')
    SLUG=$(echo "$WORKFLOW_INFO" | jq -r '.slug')
    DETECTION_SOURCE=$(echo "$WORKFLOW_INFO" | jq -r '.source')

    echo "✓ Detected $WORKFLOW_TYPE workflow (source: $DETECTION_SOURCE)"
    echo "  Base directory: $BASE_DIR/$SLUG"
else
    # Detection failed - prompt user
    echo "⚠ Could not auto-detect workflow type"
fi
```

**If detection fails**, use AskUserQuestion to prompt user:

```javascript
AskUserQuestion({
  questions: [{
    question: "Which workflow are you working on?",
    header: "Workflow Type",
    multiSelect: false,
    options: [
      {
        label: "Feature",
        description: "Single-sprint feature (specs/ directory)"
      },
      {
        label: "Epic",
        description: "Multi-sprint epic (epics/ directory)"
      }
    ]
  }]
});

// Set variables based on user selection
if (userChoice === "Feature") {
    WORKFLOW_TYPE="feature";
    BASE_DIR="specs";
} else {
    WORKFLOW_TYPE="epic";
    BASE_DIR="epics";
}

// Find the slug by scanning directory
SLUG=$(ls -1 ${BASE_DIR} | head -1)
```

**Set spec file path based on workflow type:**

```bash
if [ "$WORKFLOW_TYPE" = "epic" ]; then
    SPEC_FILE="${BASE_DIR}/${SLUG}/epic-spec.md"
else
    SPEC_FILE="${BASE_DIR}/${SLUG}/spec.md"
fi

echo "📄 Using spec: $SPEC_FILE"
```

---

### Step 0.5: MIGRATION DETECTION (v10.5)

**Detect if this feature requires database schema changes:**

```bash
# Check for schema change indicators in spec
SPEC_CONTENT=$(cat "$SPEC_FILE")

# Pattern matching for database keywords
SCHEMA_INDICATORS=$(echo "$SPEC_CONTENT" | grep -ciE 'store|persist|save|table|column|database|schema|migration|foreign key|relationship|has many|belongs to' || echo "0")

if [ "$SCHEMA_INDICATORS" -ge 3 ]; then
    echo "🗄️  Migration Detection: Schema changes likely detected"
    echo "   Indicators found: $SCHEMA_INDICATORS"
    HAS_MIGRATIONS=true
else
    echo "   No schema change indicators detected"
    HAS_MIGRATIONS=false
fi
```

**If migrations detected, generate migration-plan.md:**

When `HAS_MIGRATIONS=true`:

1. **Load existing schema** from `docs/project/data-architecture.md` (if exists)
2. **Detect migration framework** from `package.json` / `requirements.txt` (Alembic vs Prisma)
3. **Analyze spec** for entity names, relationships, data types
4. **Generate `migration-plan.md`** using template:
   ```bash
   # Generate migration plan artifact
   MIGRATION_PLAN="${BASE_DIR}/${SLUG}/migration-plan.md"
   cp .spec-flow/templates/migration-plan-template.md "$MIGRATION_PLAN"
   echo "📄 Generated: $MIGRATION_PLAN"
   ```
5. **Update state.yaml** with `has_migrations: true` flag
6. **Log detection** for /tasks phase to consume

**Migration-plan.md contains:**

- Change classification (additive/breaking)
- New tables with columns, relationships, indexes
- Modified tables with change details
- Breaking change analysis and zero-downtime strategy
- Migration sequence with SQL
- Generated tasks for Phase 1.5

**Reference**: See `.claude/skills/planning-phase/resources/migration-detection.md` for detection patterns.

---

### Step 1: Execute Planning Workflow

1. **Execute planning workflow** via spec-cli.py:

   ```bash
   python .spec-flow/scripts/spec-cli.py plan "$ARGUMENTS" [flags]
   ```

   The plan-workflow.sh script performs:

   a. **Detect workspace type**: Epic vs Feature

   - Epic: If `epics/*/epic-spec.md` exists
   - Feature: Otherwise

   b. **Epic workflows only** (Meta-prompting pipeline):

   - Generate research prompt via `/create-prompt`
   - Execute research via `/run-prompt` → research.md
   - Generate plan prompt via `/create-prompt`
   - Execute plan via `/run-prompt` → plan.md
   - Copy markdown outputs to epic workspace
   - Validate markdown structure

   c. **Feature workflows** (Traditional planning):

   - Load all 8 project docs (if available)
   - Check ambiguity (auto-run /clarify if score > 30%)
   - Run constitution check (validate against 8 core standards)
   - Phase 0.5: Design system research (UI features only)
   - Phase 1: Generate design artifacts (plan.md, data-model.md, contracts/, quickstart.md, error-log.md)
   - Git commit with architecture summary
   - Auto-proceed to next phase

   d. **All workflows**:

   - Apply anti-hallucination rules (cite existing code, verify dependencies)
   - Use structured reasoning for complex decisions
   - Auto-proceed to next phase after commit
   - Auto-suggest next step based on feature type

2. **Quality checks**:

   - **Ambiguity check**: If spec ambiguity > 30%, auto-run /clarify first
   - **Auto-proceed**: Commits and continues to next phase automatically
   - **Next step**: Auto-suggests /tasks (or /tasks --ui-first for UI features)

3. **Review generated artifacts**:

   - Epic: `research.md`, `plan.md`
   - Feature: `research.md` (if epic), `plan.md`, `data-model.md`, `contracts/api.yaml`, `quickstart.md`, `error-log.md`

4. **Verify constitution compliance** (8 core standards):

   - Code Reuse First
   - Test-Driven Development
   - API Contract Stability
   - Security by Default
   - Accessibility First (WCAG 2.2 AA)
   - Performance Budgets
   - Observability
   - Deployment Safety

5. **Present next steps** based on feature type

---

### Step 2: Generate Epic Frontend Blueprints (Epic Workflows Only)

**For epic workflows with Frontend subsystem detected**, automatically generate HTML blueprints:

```bash
# Check if epic and Frontend subsystem exists
if [ "$WORKFLOW_TYPE" = "epic" ]; then
    bash .spec-flow/scripts/bash/generate-epic-mockups.sh
fi
```

The generate-epic-mockups.sh script:

1. Detects Frontend subsystem in epic-spec.md (keywords: frontend, ui, react, next.js, web interface)
2. Creates `epics/NNN-slug/mockups/` directory
3. Generates `epic-overview.html` from template with:
   - Epic name, description, sprint count
   - Epic-level user flow diagram
   - Placeholder for sprint sections (populated during /tasks)
4. Outputs guidance for next steps

**Blueprint characteristics**:

- Pure HTML + Tailwind CSS classes
- Design token integration (tokens.css)
- State switching (success, loading, error, empty)
- Keyboard navigation support
- WCAG 2.1 AA accessibility baseline

**When generated**:

- After /plan completes successfully
- Only for epics with Frontend subsystem
- Skipped for backend-only epics

**Next phase**: Sprint-level mockups generated during /tasks phase

</process>

<verification>
Before completing, verify:
- Workspace type correctly detected (epic vs feature)
- All required artifacts generated (research.md/plan.md for epics, or plan.md/data-model.md/etc for features)
- Markdown validation passed (epic workflows only)
- **Epic frontend blueprints generated** (if Frontend subsystem detected in epic-spec.md)
- Constitution check passed (all 8 standards considered)
- Git commit successful
- Auto-proceeding to /tasks
</verification>

<success_criteria>
**Epic workflows**:

- research.md exists and validates
- plan.md exists and validates
- Markdown files contain required sections (Findings, Recommendations, Phases, Constraints)
- Files copied to epic workspace
- **Epic frontend blueprints generated** (mockups/epic-overview.html exists if Frontend subsystem detected)

**Feature workflows**:

- plan.md has all 13 sections completed
- data-model.md includes ERD and schemas
- contracts/api.yaml is valid OpenAPI 3.0 (if endpoints exist)
- quickstart.md has runnable setup steps
- error-log.md initialized

**All workflows**:

- Anti-hallucination rules followed (citations to existing code)
- Constitution check passed or auto-remediated
- Git commit created
- Auto-proceeding to next phase
</success_criteria>

<mental_model>
**Workflow state machine (Autopilot)**:

```
Setup
  ↓
Ambiguity check (auto-run /clarify if score > 30%)
  ↓
Constitution Check (8 standards)
  ↓
{IF epic}
  Phase 0: Meta-prompting (research → plan via sub-agents)
{ELSE}
  Phase 0: Load project docs
{ENDIF}
  ↓
Phase 0.5: Design System Research (UI only)
  ↓
Phase 1: Design & Contracts
  ↓
Git Commit (auto)
  ↓
Auto-proceed to /tasks
```

**Autopilot behavior**: All phases execute automatically without manual confirmation. Only blocks on errors.
</mental_model>

<anti_hallucination_rules>
**CRITICAL**: Follow these rules to prevent invented architecture:

1. **Never speculate** about existing patterns you haven't read

   - ❌ BAD: "The app probably follows a services pattern"
   - ✅ GOOD: "Let me search for existing service files"

2. **Cite existing code** when recommending reuse

   - Example: "Use UserService at api/app/services/user.py:20-45"

3. **Admit when exploration needed**

   - "I need to read package.json and search for imports"

4. **Quote spec.md exactly** - don't paraphrase requirements

5. **Verify dependencies exist** before recommending
   - Check package.json before suggesting libraries

**Why**: Hallucinated architecture leads to 40-50% implementation rework.

See `.claude/skills/planning-phase/reference.md` for full details.
</anti_hallucination_rules>

<constitution_check>
**8 Core Standards** (validate plan against these):

1. **Code Reuse First** - Search before creating, cite existing patterns
2. **Test-Driven Development** - Tests before implementation
3. **API Contract Stability** - Versioning, backward compatibility
4. **Security by Default** - Input validation, auth required, OWASP compliance
5. **Accessibility First** - WCAG 2.2 AA minimum
6. **Performance Budgets** - Explicit targets (p95/p99 latency, bundle size)
7. **Observability** - Structured logging, metrics, tracing
8. **Deployment Safety** - Blue-green, rollback capability, health checks

**Auto-remediation**: If standard missing, add boilerplate section to plan.md with TODO.

See `.claude/skills/planning-phase/reference.md` for implementation details.
</constitution_check>

<meta_prompting_workflow>
**Epic workflows only** (v5.0+):

When plan detects `epics/*/epic-spec.md`, it uses meta-prompting to generate research and plan via isolated sub-agents.

### Workflow

1. **Generate research prompt** via `/create-prompt "Research technical approach for: $EPIC_OBJECTIVE"`
2. **Execute research** via `/run-prompt 001-$EPIC_SLUG-research` → research.md
3. **Generate plan prompt** via `/create-prompt "Create implementation plan based on research findings"`
4. **Execute plan** via `/run-prompt 002-$EPIC_SLUG-plan` → plan.md
5. **Validate markdown** structure and required sections
6. **Copy to epic workspace** and cleanup prompt artifacts

### Output Structure

**research.md**:

```markdown
---
epic_slug: { { EPIC_SLUG } }
generated: { { TIMESTAMP } }
---

# Research Findings

## Findings

### {{CATEGORY}}

{{FINDINGS}}

## Recommendations

**Confidence**: high|medium|low

{{RECOMMENDATIONS}}

## Metadata

- **Confidence Level**: {{LEVEL}}
- **Dependencies**: {{DEPS}}
- **Open Questions**: {{QUESTIONS}}
```

**plan.md**:

```markdown
---
epic_slug: { { EPIC_SLUG } }
generated: { { TIMESTAMP } }
---

# Implementation Plan

## Architecture Decisions

{{DECISIONS}}

## Phases

{{PHASES}}

## Risks

**Severity**: {{SEVERITY}}
**Probability**: {{PROBABILITY}}

{{RISKS}}

## Constraints

{{CONSTRAINTS}}
```

See `.claude/skills/planning-phase/reference.md` for full meta-prompting workflow details.
</meta_prompting_workflow>

<standards>
**Industry Standards**:
- **Meta-Prompting**: [Anthropic Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/meta-prompting)
- **XML Structure**: [Anthropic XML Tags](https://docs.anthropic.com/en/docs/test-and-evaluate/strengthen-guardrails/xml-tags)
- **Constitutional AI**: [Anthropic Research](https://www.anthropic.com/news/constitutional-ai-harmlessness-from-ai-feedback)

**Workflow Standards**:

- All architecture decisions cite existing code or project docs
- Complex decisions show explicit reasoning (reduces rework by 30-40%)
- HITL gates ensure human oversight at critical checkpoints
- Idempotent execution (safe to re-run)
  </standards>

<notes>
**Script location**: The bash implementation is at `.spec-flow/scripts/bash/plan-workflow.sh`. It is invoked via spec-cli.py for cross-platform compatibility.

**Reference documentation**: Anti-hallucination rules, meta-prompting workflow, HITL gates, constitution check, and all detailed procedures are in `.claude/skills/planning-phase/reference.md`.

**Version**: v5.0 (2025-11-19) - Added meta-prompting for epics, Phase 0.5 design system research, enhanced constitution check with auto-remediation.

**Next steps after planning**:

- UI features: `/tasks --ui-first` (creates mockups before implementation)
- Backend features: `/tasks`
- Auto-proceed: `/feature continue`
  </notes>

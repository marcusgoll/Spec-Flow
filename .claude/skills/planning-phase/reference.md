# Planning Phase - Reference Documentation

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent making up architectural decisions.

### 1. Never speculate about existing patterns you have not read

- ❌ BAD: "The app probably follows a services pattern"
- ✅ GOOD: "Let me search for existing service files to understand current patterns"
- Use Grep to find patterns: `class.*Service`, `interface.*Repository`

### 2. Cite existing code when recommending reuse

- When suggesting to reuse UserService, cite: `api/app/services/user.py:20-45`
- When referencing patterns, cite: `api/app/core/database.py:12-18 shows our DB session pattern`
- Don't invent reusable components that don't exist

### 3. Admit when codebase exploration is needed

- If unsure about tech stack, say: "I need to read package.json and search for imports"
- If uncertain about patterns, say: "Let me search the codebase for similar implementations"
- Never make up directory structures, module names, or import paths

### 4. Quote from spec.md exactly when planning

- Don't paraphrase requirements - quote user stories verbatim
- Example: "According to spec.md:45-48: '[exact quote]', therefore we need..."
- If spec is ambiguous, flag it rather than assuming intent

### 5. Verify dependencies exist before recommending

- Before suggesting "use axios for HTTP", check package.json
- Before recommending libraries, search existing imports
- Don't suggest packages that aren't installed

**Why this matters**: Hallucinated architecture leads to plans that can't be implemented. Plans based on non-existent patterns create unnecessary refactoring. Accurate planning grounded in actual code saves 40-50% of implementation rework.

---

## Reasoning Approach

For complex architecture decisions, show your step-by-step reasoning.

### When to use structured thinking

- Choosing architectural patterns (e.g., REST vs GraphQL, monolith vs microservices)
- Selecting libraries or frameworks (e.g., Redux vs Context API)
- Designing database schemas (normalization vs denormalization)
- Planning file/folder structure for new features
- Deciding on code reuse vs new implementation

**Benefits**: Explicit reasoning reduces architectural rework by 30-40% and improves maintainability.

---

## Meta-Prompting Workflow (v5.0)

**For epic workflows**, use meta-prompting to generate research → plan pipeline via isolated sub-agents.

### Step 1: Detect Epic vs Feature

**Check workspace type:**
```bash
if [ -f "epics/*/epic-spec.xml" ]; then
  WORKSPACE_TYPE="epic"
  EPIC_DIR=$(dirname "epics/*/epic-spec.xml")
else
  WORKSPACE_TYPE="feature"
  FEATURE_DIR=$(python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only | jq -r '.FEATURE_DIR')
fi
```

**Decision**:
- If feature: Use traditional planning (skip to "Execute Planning Workflow")
- If epic: Proceed with meta-prompting pipeline

### Step 2: Generate Research Prompt (Epic Only)

**Extract epic objective:**
```bash
EPIC_OBJECTIVE=$(xmllint --xpath "//epic/objective/business_value/text()" "$EPIC_DIR/epic-spec.xml")
```

**Invoke /create-prompt:**
```bash
/create-prompt "Research technical approach for: $EPIC_OBJECTIVE"
```

**The create-prompt skill will:**
- Detect purpose: Research
- Ask contextual questions via AskUserQuestion:
  - Research depth? (Quick / Standard / Deep)
  - What sources? (Project docs / Web / Both)
  - Output format? (Structured findings / Recommendations / Both)
- Generate research prompt in `.prompts/001-$EPIC_SLUG-research/`
- Reference project docs: `@docs/project/tech-stack.md`, `@docs/project/system-architecture.md`, `@docs/project/api-strategy.md`
- Specify XML output: `research.xml` with metadata

**Research prompt structure:**
```xml
<objective>
Research technical approaches for implementing: [epic objective]
Output structured findings with confidence levels and recommendations.
</objective>

<context>
Epic specification: @epics/$EPIC_SLUG/epic-spec.xml
Project tech stack: @docs/project/tech-stack.md
System architecture: @docs/project/system-architecture.md
API strategy: @docs/project/api-strategy.md
</context>

<requirements>
- Explore multiple technical approaches
- Assess feasibility based on existing tech stack
- Identify risks and dependencies
- Provide confidence levels for recommendations
- Flag open questions requiring clarification
</requirements>

<output_specification>
Save to: .prompts/001-$EPIC_SLUG-research/research.xml

Structure:
<research>
  <findings>
    <finding category="...">...</finding>
  </findings>
  <recommendations>
    <recommendation confidence="high|medium|low">...</recommendation>
  </recommendations>
  <metadata>
    <confidence level="...">...</confidence>
    <dependencies>...</dependencies>
    <open_questions>...</open_questions>
    <assumptions>...</assumptions>
  </metadata>
</research>
</output_specification>
```

### Step 3: Execute Research Prompt

**Run prompt in isolated sub-agent:**
```bash
/run-prompt 001-$EPIC_SLUG-research
```

**Output location:** `.prompts/001-$EPIC_SLUG-research/research.xml`

**Validate output:**
```bash
# Check file exists
test -f ".prompts/001-$EPIC_SLUG-research/research.xml" || error "Research output missing"

# Validate XML structure
xmllint --noout ".prompts/001-$EPIC_SLUG-research/research.xml" || error "Invalid XML"

# Check required tags
grep -q "<confidence" ".prompts/001-$EPIC_SLUG-research/research.xml" || warn "Missing confidence metadata"
```

### Step 4: Generate Plan Prompt (Epic Only)

**Invoke /create-prompt with research reference:**
```bash
/create-prompt "Create implementation plan based on research findings for: $EPIC_OBJECTIVE"
```

**The create-prompt skill will:**
- Detect purpose: Plan
- Reference research.xml from Step 3
- Ask contextual questions via AskUserQuestion:
  - Plan format? (High-level phases / Detailed tasks / Both)
  - Include ADRs? (Yes / No)
  - Risk assessment? (Light / Standard / Comprehensive)
- Generate plan prompt in `.prompts/002-$EPIC_SLUG-plan/`
- Specify plan.xml output with phases, dependencies, constraints

**Plan prompt structure:**
```xml
<objective>
Create implementation plan for: [epic objective]
Based on research findings, design architecture and phases.
</objective>

<context>
Epic specification: @epics/$EPIC_SLUG/epic-spec.xml
Research findings: @.prompts/001-$EPIC_SLUG-research/research.xml
Project architecture: @docs/project/system-architecture.md
Data architecture: @docs/project/data-architecture.md
</context>

<requirements>
- Define implementation phases
- Identify dependencies between phases
- Specify technical constraints
- Create ADRs for key decisions
- Assess risks and mitigation strategies
</requirements>

<output_specification>
Save to: .prompts/002-$EPIC_SLUG-plan/plan.xml

Structure:
<plan>
  <architecture_decisions>
    <decision id="...">...</decision>
  </architecture_decisions>
  <phases>
    <phase id="..." name="...">
      <description>...</description>
      <dependencies>...</dependencies>
      <estimated_hours>...</estimated_hours>
    </phase>
  </phases>
  <risks>
    <risk severity="..." probability="...">...</risk>
  </risks>
  <constraints>...</constraints>
</plan>
</output_specification>
```

### Step 5: Execute Plan Prompt

**Run prompt in isolated sub-agent:**
```bash
/run-prompt 002-$EPIC_SLUG-plan
```

**Output location:** `.prompts/002-$EPIC_SLUG-plan/plan.xml`

**Validate output:**
```bash
# Check file exists
test -f ".prompts/002-$EPIC_SLUG-plan/plan.xml" || error "Plan output missing"

# Validate XML structure
xmllint --noout ".prompts/002-$EPIC_SLUG-plan/plan.xml" || error "Invalid XML"

# Check required tags
grep -q "<phases" ".prompts/002-$EPIC_SLUG-plan/plan.xml" || error "Missing phases"
```

### Step 6: Copy to Epic Workspace

**Move XML outputs to epic workspace:**
```bash
cp ".prompts/001-$EPIC_SLUG-research/research.xml" "$EPIC_DIR/research.xml"
cp ".prompts/002-$EPIC_SLUG-plan/plan.xml" "$EPIC_DIR/plan.xml"

# Cleanup prompt artifacts
rm -rf ".prompts/001-$EPIC_SLUG-research"
rm -rf ".prompts/002-$EPIC_SLUG-plan"
```

**Result**: Epic workspace now contains research.xml and plan.xml generated via meta-prompting.

---

## HITL Gates

**Human-in-the-loop checkpoints** (3 total):

### 1. Ambiguity Gate (Blocking)

**Purpose**: Detect spec ambiguities, require /clarify or explicit proceed

**Trigger**: After constitution check, before research phase

**Detection logic**:
```bash
AMBIGUITY_SCORE=$(analyze_spec_ambiguity "$SPEC_FILE")
if [ "$AMBIGUITY_SCORE" -gt 30 ]; then
  echo "⚠️  Spec ambiguity detected: $AMBIGUITY_SCORE%"
  echo "Recommend running /clarify to reduce ambiguity"
  # Pause for user decision unless --yes or --skip-clarify
fi
```

**Auto-skip conditions**:
- `--yes` flag
- `--skip-clarify` flag
- `/feature continue` mode

### 2. Confirmation Gate (Before Commit)

**Purpose**: Show architecture summary, 10s timeout

**Trigger**: After all design artifacts generated, before git commit

**Display**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Architecture Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generated artifacts:
- research.md (epic only)
- plan.md
- data-model.md
- contracts/api.yaml
- quickstart.md
- error-log.md

Key decisions:
- [List of architecture decisions from plan.md]

Proceed with commit? (auto-proceed in 10s, Ctrl+C to cancel)
```

**Auto-skip conditions**:
- `--yes` flag
- `/feature continue` mode
- `SPEC_FLOW_INTERACTIVE=false`

### 3. Decision Tree (After Commit)

**Purpose**: Executable next-step commands via SlashCommand tool

**Trigger**: After successful git commit

**Options presented**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Planning Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:

{IF UI feature}
  1. /tasks --ui-first — Generate tasks with mockup-first workflow
  2. /feature continue — Auto-proceed through workflow
{ELSE}
  1. /tasks — Generate concrete TDD tasks
  2. /feature continue — Auto-proceed through workflow
{ENDIF}

Choose an option or continue manually.
```

**Auto-skip conditions**:
- `/feature continue` mode (auto-proceeds to /tasks)
- `--yes` flag (auto-proceeds to /tasks)

---

## Constitution Check

**Purpose**: Validate plan against project engineering principles

**8 Core Standards**:
1. **Code Reuse First** - Search before creating, cite existing patterns
2. **Test-Driven Development** - Tests before implementation
3. **API Contract Stability** - Versioning, backward compatibility
4. **Security by Default** - Input validation, auth required, OWASP compliance
5. **Accessibility First** - WCAG 2.2 AA minimum
6. **Performance Budgets** - Explicit targets (p95/p99 latency, bundle size)
7. **Observability** - Structured logging, metrics, tracing
8. **Deployment Safety** - Blue-green, rollback capability, health checks

**Check process**:
```bash
# Read constitution
CONSTITUTION="docs/project/constitution.md"

# Validate plan against each standard
for standard in "${STANDARDS[@]}"; do
  if ! grep -qi "$standard" "$PLAN_FILE"; then
    warn "Plan missing consideration for: $standard"
  fi
done

# Fail if critical standards missing
MISSING_CRITICAL=$(check_critical_standards "$PLAN_FILE")
if [ -n "$MISSING_CRITICAL" ]; then
  error "Plan violates critical standards: $MISSING_CRITICAL"
  exit 1
fi
```

**Auto-remediation**:
- If standard missing, add boilerplate section to plan.md
- Example: Missing "Performance Budgets" → Add "## Performance Targets" section with TODO

---

## Workflow State Machine

```
Setup
  ↓
[AMBIGUITY GATE] (blocking)
  ↓
Constitution Check
  ↓
Phase 0: Research (epics) or skip (features)
  ↓
Phase 0.5: Design System Research (UI features only)
  ↓
Phase 1: Design & Contracts
  ↓
[CONFIRMATION GATE] (10s timeout)
  ↓
Git Commit
  ↓
[DECISION TREE] (next step options)
```

**State transitions**:
- Setup → Ambiguity Gate: Always
- Ambiguity Gate → Constitution: If passed or skipped
- Constitution → Phase 0: Epic only
- Constitution → Phase 1: Feature only
- Phase 0 → Phase 0.5: UI epic only
- Phase 0 → Phase 1: Non-UI epic
- Phase 1 → Confirmation: Always
- Confirmation → Commit: If approved or timeout
- Commit → Decision Tree: Always

---

## Auto-Suggest Logic

**After planning complete, suggest next step based on feature type:**

### UI Features

**Detection**:
```bash
HAS_UI=$(grep -qi "ui\|frontend\|component\|screen\|page" "$SPEC_FILE" && echo true || echo false)
```

**Suggestions**:
1. `/tasks --ui-first` — Generate tasks with mockup-first workflow (recommended)
2. `/tasks` — Skip mockups, go directly to task generation
3. `/feature continue` — Auto-proceed through workflow

### Backend Features

**Detection**:
```bash
HAS_BACKEND=$(grep -qi "api\|endpoint\|database\|backend\|service" "$SPEC_FILE" && echo true || echo false)
```

**Suggestions**:
1. `/tasks` — Generate concrete TDD tasks
2. `/feature continue` — Auto-proceed through workflow

---

## Prerequisites

### Required Tools

- `git` — Version control
- `jq` — JSON parsing
- `yq` — YAML parsing
- `xmllint` — XML validation (epic workflows only)

**Check command**:
```bash
for tool in git jq yq xmllint; do
  command -v "$tool" >/dev/null || error "Missing required tool: $tool"
done
```

### Required Files

- `spec.md` — Feature specification (must exist)
- `docs/project/*.md` — Project documentation (8 files recommended)
- `.git/` — Git repository (must be initialized)

**Check command**:
```bash
test -f "specs/*/spec.md" || error "Missing spec.md"
test -d ".git" || error "Not a git repository"
```

### Working Directory State

- **Clean working tree**: Not required (uncommitted changes allowed)
- **Current branch**: Any (feature branch recommended)
- **Remote**: Optional (local-only workflow supported)

---

## Flags and Environment Variables

### Command-Line Flags

- `--interactive` : Force wait for user confirmation (no auto-proceed timeout)
- `--yes` : Skip all HITL gates (ambiguity + confirmation) and auto-commit (full automation)
- `--skip-clarify` : Skip spec ambiguity gate only (still show confirmation before commit)

**Usage**:
```bash
/plan --yes                    # Full automation
/plan --interactive            # Manual approval at each gate
/plan --skip-clarify           # Skip ambiguity check only
```

### Environment Variables

- `SPEC_FLOW_INTERACTIVE=true` : Global interactive mode (overrides `--yes`)
- `SPEC_FLOW_AUTO_COMMIT=true` : Auto-commit without confirmation
- `SPEC_FLOW_SKIP_CLARIFY=true` : Global skip ambiguity gate

**Priority**:
1. Command-line flags (highest)
2. Environment variables
3. Defaults (lowest)

---

## Version History

**v5.0** (2025-11-19):
- Added meta-prompting workflow for epics
- Introduced /create-prompt and /run-prompt integration
- Added Phase 0.5 design system research for UI features
- Enhanced constitution check with auto-remediation

**v4.0** (2025-10-15):
- Added HITL gates (ambiguity, confirmation, decision tree)
- Introduced `--yes`, `--interactive`, `--skip-clarify` flags
- Added anti-hallucination rules and reasoning approach

**v3.0** (2025-08-20):
- Split epic and feature workflows
- Added constitution check
- Introduced project documentation integration

---

## References

- [Meta-Prompting Guide](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/meta-prompting)
- [XML Prompt Structure](https://docs.anthropic.com/en/docs/test-and-evaluate/strengthen-guardrails/xml-tags)
- [Constitutional AI](https://www.anthropic.com/news/constitutional-ai-harmlessness-from-ai-feedback)

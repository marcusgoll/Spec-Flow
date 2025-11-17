---
description: Generate design artifacts from feature spec (research + design + context plan)
version: 3.0
updated: 2025-11-17
---

# /plan — Implementation Plan Generator

Design implementation for: $ARGUMENTS

**Flags:**
- `--interactive` : Force wait for user confirmation (no auto-proceed timeout)
- `--yes` : Skip all HITL gates (ambiguity + confirmation) and auto-commit (full automation)
- `--skip-clarify` : Skip spec ambiguity gate only (still show confirmation before commit)
- Environment: `SPEC_FLOW_INTERACTIVE=true` for global interactive mode

<context>
## MENTAL MODEL

**Workflow**: spec → clarify → plan → tasks → implement → optimize → preview → ship

**Phases:**
- Phase 0: Research & Discovery → research.md
- Phase 0.5: Design System Research (UI features) → design-scout agent generates Design System Constraints
- Phase 1: Design & Contracts → data-model.md, contracts/, quickstart.md, plan.md

**State machine:**
- Setup → [AMBIGUITY GATE] → Constitution check → Phase 0 (Research) → Phase 0.5 (Design System - UI only) → Phase 1 (Design) → [CONFIRMATION GATE] → Commit → [DECISION TREE]

**HITL Gates (3 total):**
1. **Ambiguity gate** (blocking): Detects spec ambiguities, requires /clarify or explicit proceed
2. **Confirmation** (before commit): Shows architecture summary, 10s timeout
3. **Decision tree** (after commit): Executable next-step commands via SlashCommand tool
- **Auto-skipped when**: `--yes` flag skips all, `--skip-clarify` skips gate #1, `/feature continue` skips all

**Auto-suggest:**
- UI features → `/design-variations` or `/tasks`
- Backend features → `/tasks`

**Prerequisites:**
- Git repository
- jq installed (JSON parsing)
- Feature spec completed (spec.md exists)
- Working directory clean (uncommitted changes allowed)
</context>

<constraints>
## ANTI-HALLUCINATION RULES

**CRITICAL**: Follow these rules to prevent making up architectural decisions.

1. **Never speculate about existing patterns you have not read**
   - ❌ BAD: "The app probably follows a services pattern"
   - ✅ GOOD: "Let me search for existing service files to understand current patterns"
   - Use Grep to find patterns: `class.*Service`, `interface.*Repository`

2. **Cite existing code when recommending reuse**
   - When suggesting to reuse UserService, cite: `api/app/services/user.py:20-45`
   - When referencing patterns, cite: `api/app/core/database.py:12-18 shows our DB session pattern`
   - Don't invent reusable components that don't exist

3. **Admit when codebase exploration is needed**
   - If unsure about tech stack, say: "I need to read package.json and search for imports"
   - If uncertain about patterns, say: "Let me search the codebase for similar implementations"
   - Never make up directory structures, module names, or import paths

4. **Quote from spec.md exactly when planning**
   - Don't paraphrase requirements - quote user stories verbatim
   - Example: "According to spec.md:45-48: '[exact quote]', therefore we need..."
   - If spec is ambiguous, flag it rather than assuming intent

5. **Verify dependencies exist before recommending**
   - Before suggesting "use axios for HTTP", check package.json
   - Before recommending libraries, search existing imports
   - Don't suggest packages that aren't installed

**Why this matters**: Hallucinated architecture leads to plans that can't be implemented. Plans based on non-existent patterns create unnecessary refactoring. Accurate planning grounded in actual code saves 40-50% of implementation rework.

## REASONING APPROACH

For complex architecture decisions, show your step-by-step reasoning.

**When to use structured thinking:**
- Choosing architectural patterns (e.g., REST vs GraphQL, monolith vs microservices)
- Selecting libraries or frameworks (e.g., Redux vs Context API)
- Designing database schemas (normalization vs denormalization)
- Planning file/folder structure for new features
- Deciding on code reuse vs new implementation

**Benefits**: Explicit reasoning reduces architectural rework by 30-40% and improves maintainability.
</constraints>

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Planning Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py plan "$ARGUMENTS"
```

**What the script does:**

1. **Tool preflight checks** — Validates git, jq installed
2. **Setup** — Discovers feature paths via check-prerequisites
3. **Ambiguity gate (HITL)** — Detects `[NEEDS CLARIFICATION]` markers, offers /clarify or proceed
4. **Constitution check** — Validates feature against constitution.md principles
5. **Template validation** — Ensures required templates exist
6. **Feature type detection** — Counts screens to classify UI-heavy vs backend features
7. **Phase 0: Research & Discovery** — Determines research depth based on feature classification
8. **Project documentation integration** — Reads docs/project/*.md (tech-stack, data-architecture, api-strategy, capacity-planning, etc.)
9. **Phase 1: Design & Contracts** — Generates artifact templates
10. **Validation** — Checks for unresolved questions
11. **Confirmation gate (HITL)** — Shows plan summary, requests confirmation
12. **Git commit** — Commits all generated artifacts
13. **Decision tree (HITL)** — Presents next steps based on feature type

**Script output provides context for LLM:**

The script generates template files and displays a summary. The LLM must then populate these templates with actual content.

**After script completes, you (LLM) must:**

## 1) Read Generated Artifacts & Perform Research

### Phase 0: Project Documentation Research

**Read:**
- `specs/*/spec.md` (feature specification)
- `specs/*/research.md` (template to populate)
- `specs/*/plan.md` (template to populate)
- `docs/project/*.md` (if project docs exist - tech stack, data arch, API strategy)

**Research Depth:**
- **Minimal** (simple features): 2-3 tools (Read spec, Grep keywords, optional Glob)
- **Full** (complex features): 5-15 tools (or 2-5 if project docs exist)

**Populate RESEARCH_DECISIONS, REUSABLE_COMPONENTS, NEW_COMPONENTS, UNKNOWNS arrays**

### Phase 0.5: Design System Research (UI Features Only)

**For UI-heavy features (3+ screens), use the design-scout agent:**

Launch the design-scout agent to analyze the existing design system and generate component reuse strategies:

```bash
# design-scout agent will:
# 1. Read design/systems/ui-inventory.md, tokens.css, style-guide.md
# 2. Scan specs/*/mockups/*.html for approved patterns
# 3. Match feature requirements to existing components
# 4. Identify new components needed (with justification)
# 5. Flag consistency deviations from established patterns
# 6. Generate "Design System Constraints" section for plan.md
```

**Use Task tool to launch design-scout agent:**

```
Task tool with subagent_type="design-scout"
Prompt: "Analyze design system for [feature name] and generate Design System Constraints section.

Requirements from spec.md:
- [List UI requirements: forms, tables, navigation, etc.]

Generate:
1. Available component reuse suggestions (exact matches, extensions, new)
2. Approved patterns from previous features
3. New components with justification
4. Token compliance checklist
5. Accessibility baseline
6. Consistency warnings (deviations from established patterns)

Output format: Complete 'Design System Constraints' section ready to insert into plan.md"
```

**Skip this phase if:**
- Feature has <3 screens (minimal UI)
- Feature is backend-only (no UI components)
- Design system files don't exist (ui-inventory.md, tokens.css, style-guide.md missing)

## 2) Generate Planning Artifacts

Use Edit tool to populate templates with actual content:

**research.md** — Research decisions, component reuse analysis, unknowns
**data-model.md** — Entity definitions, ERD, API schemas, state shape
**contracts/api.yaml** — OpenAPI 3.0 specifications
**quickstart.md** — Initial setup, validation, manual testing scenarios
**plan.md** — Complete architecture document (13 sections including Design System Constraints)
**error-log.md** — Initialized error tracking template

### plan.md Section Order (for UI Features)

When populating plan.md, include the Design System Constraints section between Project Context and Technical Approach:

```markdown
# Implementation Plan: [Feature Name]

## 1. Overview
[Feature summary, goals, success criteria]

## 2. Project Context
[Existing content from Phase 0 - tech stack, patterns, dependencies]

## 3. Design System Constraints
[NEW - Output from design-scout agent for UI features]
[Skip this section for backend-only features]

## 4. Technical Approach
[Architecture decisions, patterns, data flow]

## 5. Data Model
[Database schema, API contracts, state shape]

## 6. API Design
[Endpoint specifications, request/response formats]

## 7. Implementation Plan
[Task breakdown, dependencies, sequencing]

## 8. Testing Strategy
[Unit tests, integration tests, E2E scenarios]

## 9. Risks & Mitigations
[Potential blockers, complexity areas, contingency plans]

## 10. Performance Considerations
[Optimization strategies, scalability concerns]

## 11. Security Considerations
[Auth, validation, data protection]

## 12. Monitoring & Observability
[Logging, metrics, error tracking]

## 13. Rollout Plan
[Deployment strategy, feature flags, rollback]
```

## 3) Handle HITL Gates

### Gate 1: Spec Ambiguity
If script detects `[NEEDS CLARIFICATION]` markers, use AskUserQuestion:
- Option A: Resolve ambiguities first (/clarify) [RECOMMENDED]
- Option B: Proceed anyway
- Option C: Cancel

### Gate 2: Confirmation
Script shows plan summary. Present to user if not in `--yes` mode:
1. Commit and continue
2. Review first
3. Adjust decisions
4. Cancel

### Gate 3: Decision Tree
Based on feature type (UI-heavy vs backend), present appropriate next steps using AskUserQuestion + SlashCommand

## 4) Git Commit

```bash
git add specs/*/
git commit -m "design:plan: complete architecture with reuse analysis

[ARCHITECTURE DECISIONS]
- Stack: [from plan.md]
- Patterns: [from plan.md]

[EXISTING - REUSE] ({count} components)
- [from REUSABLE_COMPONENTS]

[NEW - CREATE] ({count} components)
- [from NEW_COMPONENTS]

Artifacts: research.md, data-model.md, quickstart.md, plan.md, contracts/api.yaml, error-log.md

Next: /tasks

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## 5) Update NOTES.md

Append Phase 1 checkpoint with metrics (research decisions count, reusable components, new components, migration requirement).

## 6) Present Next Steps

Display decision tree based on feature type:
- **UI-Heavy**: /design-variations or /tasks
- **Backend**: /tasks or /feature continue

</instructions>

---

## CONTEXT MANAGEMENT

**Before proceeding to /tasks:**

If context feels large, run compaction:
```bash
/compact "preserve architecture decisions, reuse analysis, and schema"
```

Otherwise proceed directly to `/tasks`. No automatic tracking.

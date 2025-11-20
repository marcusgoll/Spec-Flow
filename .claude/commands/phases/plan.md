---
description: Generate implementation plan from spec using research-driven design (meta-prompting for epics)
allowed-tools: [Read, Grep, Glob, Bash(python *spec-cli.py*), Bash(git *), Task, AskUserQuestion, SlashCommand]
argument-hint: [feature-name or epic-slug]
---

<context>
Current git status: !`git status --short | head -10`

Current branch: !`git branch --show-current`

Feature workspace: !`python .spec-flow/scripts/spec-cli.py check-prereqs --json --paths-only 2>/dev/null | jq -r '.FEATURE_DIR // "Not initialized"'`

Project docs: !`ls -1 docs/project/*.md 2>/dev/null | wc -l` files available

Spec exists: !`test -f specs/*/spec.md && echo "✅ Found" || echo "❌ Missing"`
</context>

<objective>
Generate implementation plan for $ARGUMENTS using research-driven design.

For **epics**: Uses meta-prompting workflow to generate research.xml → plan.xml via isolated sub-agents
For **features**: Uses traditional planning workflow with project docs integration

This ensures architecture decisions are grounded in existing codebase patterns and project documentation.

**Dependencies**:
- Git repository initialized
- Feature spec completed (spec.md exists)
- Required tools: git, jq, yq (xmllint for epics)

**Flags**:
- `--interactive` : Force wait for user confirmation (no auto-proceed timeout)
- `--yes` : Skip all HITL gates (ambiguity + confirmation) and auto-commit
- `--skip-clarify` : Skip spec ambiguity gate only
- Environment: `SPEC_FLOW_INTERACTIVE=true` for global interactive mode
</objective>

<process>
1. **Execute planning workflow** via spec-cli.py:
   ```bash
   python .spec-flow/scripts/spec-cli.py plan "$ARGUMENTS" [flags]
   ```

   The plan-workflow.sh script performs:

   a. **Detect workspace type**: Epic vs Feature
      - Epic: If `epics/*/epic-spec.xml` exists
      - Feature: Otherwise

   b. **Epic workflows only** (Meta-prompting pipeline):
      - Generate research prompt via `/create-prompt`
      - Execute research via `/run-prompt` → research.xml
      - Generate plan prompt via `/create-prompt`
      - Execute plan via `/run-prompt` → plan.xml
      - Copy XML outputs to epic workspace
      - Validate XML structure

   c. **Feature workflows** (Traditional planning):
      - Load all 8 project docs (if available)
      - Run ambiguity gate (blocking if score > 30%)
      - Run constitution check (validate against 8 core standards)
      - Phase 0.5: Design system research (UI features only)
      - Phase 1: Generate design artifacts (plan.md, data-model.md, contracts/, quickstart.md, error-log.md)
      - Confirmation gate (10s timeout before commit)
      - Git commit with architecture summary
      - Decision tree (suggest next steps)

   d. **All workflows**:
      - Apply anti-hallucination rules (cite existing code, verify dependencies)
      - Use structured reasoning for complex decisions
      - Follow HITL gates (ambiguity, confirmation, decision tree)
      - Auto-suggest next step based on feature type

2. **HITL Gates** (3 checkpoints):
   - **Ambiguity gate** (blocking): If spec ambiguity > 30%, recommend /clarify
   - **Confirmation** (10s timeout): Show architecture summary before commit
   - **Decision tree**: Present next-step options (UI: /design-variations or /tasks, Backend: /tasks)

3. **Review generated artifacts**:
   - Epic: `research.xml`, `plan.xml`
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
</process>

<verification>
Before completing, verify:
- Workspace type correctly detected (epic vs feature)
- All required artifacts generated (research.xml/plan.xml for epics, or plan.md/data-model.md/etc for features)
- XML validation passed (epic workflows only)
- Constitution check passed (all 8 standards considered)
- HITL gates respected (unless --yes or --skip-clarify)
- Git commit successful (if auto-commit enabled)
- Next-step suggestions presented
</verification>

<success_criteria>
**Epic workflows**:
- research.xml exists and validates
- plan.xml exists and validates
- XML files contain required tags (<findings>, <recommendations>, <phases>, <constraints>)
- Files copied to epic workspace

**Feature workflows**:
- plan.md has all 13 sections completed
- data-model.md includes ERD and schemas
- contracts/api.yaml is valid OpenAPI 3.0 (if endpoints exist)
- quickstart.md has runnable setup steps
- error-log.md initialized

**All workflows**:
- Anti-hallucination rules followed (citations to existing code)
- Constitution check passed or auto-remediated
- HITL gates handled appropriately
- Git commit created (unless skipped)
- User knows next action
</success_criteria>

<mental_model>
**Workflow state machine**:
```
Setup
  ↓
[AMBIGUITY GATE] (blocking if score > 30%)
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
[CONFIRMATION GATE] (10s timeout)
  ↓
Git Commit
  ↓
[DECISION TREE] (suggest next steps)
```

**Auto-skip HITL gates when**:
- `--yes` flag: Skip all gates
- `--skip-clarify` flag: Skip ambiguity gate only
- `/feature continue` mode: Skip all gates
- `SPEC_FLOW_INTERACTIVE=false`: No timeouts
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

When plan detects `epics/*/epic-spec.xml`, it uses meta-prompting to generate research and plan via isolated sub-agents.

### Workflow

1. **Generate research prompt** via `/create-prompt "Research technical approach for: $EPIC_OBJECTIVE"`
2. **Execute research** via `/run-prompt 001-$EPIC_SLUG-research` → research.xml
3. **Generate plan prompt** via `/create-prompt "Create implementation plan based on research findings"`
4. **Execute plan** via `/run-prompt 002-$EPIC_SLUG-plan` → plan.xml
5. **Validate XML** structure and required tags
6. **Copy to epic workspace** and cleanup prompt artifacts

### Output Structure

**research.xml**:
```xml
<research>
  <findings category="...">...</findings>
  <recommendations confidence="high|medium|low">...</recommendations>
  <metadata>
    <confidence level="...">...</confidence>
    <dependencies>...</dependencies>
    <open_questions>...</open_questions>
  </metadata>
</research>
```

**plan.xml**:
```xml
<plan>
  <architecture_decisions>...</architecture_decisions>
  <phases>...</phases>
  <risks severity="..." probability="...">...</risks>
  <constraints>...</constraints>
</plan>
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
- UI features: `/design-variations` or `/tasks`
- Backend features: `/tasks`
- Auto-proceed: `/feature continue`
</notes>

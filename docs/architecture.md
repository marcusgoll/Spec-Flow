# Spec-Flow Architecture

## Workflow Overview
Spec-Flow orchestrates feature work through a fixed series of Claude commands. Each command focuses on a deliverable (specification, plan, tasks, review) and hands contextual artifacts to the next step.

## Workflow State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SPEC-FLOW WORKFLOW STATE MACHINE                    │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌───────────┐
    │   START   │
    │   IDEA    │
    └─────┬─────┘
          │
          ▼
   ┌──────────────┐
   │ /spec-flow   │ Phase 0: SPECIFICATION
   │ Create Spec  │ Output: spec.md, NOTES.md, visuals/README.md
   └──────┬───────┘
          │
          ▼
    ┌─────────────────────┐
    │ Needs clarification?│──Yes──┐
    └─────────┬───────────┘       │
              │ No                │
              │            ┌──────▼─────────┐
              │            │   /clarify     │ Phase 0.5: CLARIFICATION
              │            │ Resolve Ambig. │ Output: Updated spec.md
              │            └──────┬─────────┘
              │                   │
              └◄──────────────────┘
          │
          ▼
   ┌──────────────┐
   │   /plan      │ Phase 1: PLANNING
   │ Impl. Plan   │ Output: plan.md, research.md
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │   /tasks     │ Phase 2: TASK BREAKDOWN
   │  20-30 Tasks │ Output: tasks.md (acceptance criteria)
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │  /analyze    │ Phase 3: ANALYSIS
   │ Consistency  │ Output: analysis-report.md
   └──────┬───────┘
          │
          ▼
    ┌─────────────────────┐
    │ Critical issues?    │──Yes──┐
    └─────────┬───────────┘       │
              │ No                │
              │            ┌──────▼─────────┐
              │            │   PAUSE        │ Manual Fix Required
              │            │ User resolves  │ Then: /flow continue
              │            └──────┬─────────┘
              │                   │
              └◄──────────────────┘
          │
          ▼
   ┌──────────────┐
   │ /implement   │ Phase 4: IMPLEMENTATION
   │  Execute All │ Output: Code, tests, docs
   │    Tasks     │ (Auto-compact if >80k tokens)
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │  /optimize   │ Phase 5: OPTIMIZATION
   │ Code Review  │ Output: optimization-report.md
   │ Performance  │         code-review-report.md
   └──────┬───────┘
          │
          ▼
    ┌─────────────────────┐
    │ Blockers found?     │──Yes──┐
    └─────────┬───────────┘       │
              │ No                │
              │            ┌──────▼─────────┐
              │            │   PAUSE        │ Auto-fix or Manual
              │            │ Resolve issues │ Then: /flow continue
              │            └──────┬─────────┘
              │                   │
              └◄──────────────────┘
          │
          ▼
   ╔══════════════╗
   ║   /preview   ║ MANUAL GATE 1: UI/UX VALIDATION
   ║ User Validates║ Test locally, verify against spec
   ╚══════┬═══════╝
          │ User approves
          ▼
   ┌──────────────┐
   │/phase-1-ship │ Phase 7: SHIP TO STAGING
   │ PR → Staging │ Output: PR, auto-merge, deployment
   └──────┬───────┘
          │
          ▼
   ╔══════════════╗
   ║  /validate   ║ MANUAL GATE 2: STAGING VALIDATION
   ║   -staging   ║ E2E tests, Lighthouse, acceptance
   ╚══════┬═══════╝
          │ User approves
          ▼
   ┌──────────────┐
   │/phase-2-ship │ Phase 9: SHIP TO PRODUCTION
   │ PR → Main    │ Output: PR, release, roadmap update
   └──────┬───────┘
          │
          ▼
    ┌───────────┐
    │  SHIPPED  │ 🚀
    │   DONE    │
    └───────────┘
```

**Key**:
- `┌─────┐` = Automated phase
- `╔═════╗` = Manual gate (requires user action)
- `→ PAUSE` = Workflow stops, awaiting fixes

Automation scripts in `.spec-flow/scripts/powershell/` prepare directories, calculate token budgets, and synchronize shared memory so agents stay aligned.

## Directory Structure

```
spec-flow-workflow-kit/
│
├── .claude/                          # Claude Code configuration
│   ├── agents/                       # Agent persona briefs
│   │   ├── spec-flow-backend-dev.md
│   │   ├── spec-flow-frontend-shipper.md
│   │   ├── spec-flow-qa-test.md
│   │   ├── spec-flow-senior-code-reviewer.md
│   │   ├── spec-flow-debugger.md
│   │   └── spec-flow-ci-cd-release.md
│   │
│   ├── commands/                     # Slash command definitions
│   │   ├── spec-flow.md              # Phase 0: Create specification
│   │   ├── clarify.md                # Phase 0.5: Resolve ambiguities
│   │   ├── plan.md                   # Phase 1: Implementation plan
│   │   ├── tasks.md                  # Phase 2: Task breakdown
│   │   ├── analyze.md                # Phase 3: Consistency analysis
│   │   ├── implement.md              # Phase 4: Execute tasks
│   │   ├── optimize.md               # Phase 5: Code review
│   │   ├── debug.md                  # Triage errors
│   │   ├── preview.md                # Manual gate: Preview
│   │   ├── phase-1-ship.md           # Phase 7: Ship to staging
│   │   ├── validate-staging.md       # Manual gate: Validate staging
│   │   ├── phase-2-ship.md           # Phase 9: Ship to production
│   │   ├── flow.md                   # Orchestrator (auto-progression)
│   │   ├── checks.md                 # Fix CI/deployment blockers
│   │   └── route-agent.md            # Internal routing helper
│   │
│   └── settings.example.json         # Permissions template
│
├── .spec-flow/                       # Workflow automation
│   ├── scripts/
│   │   ├── powershell/               # Windows/cross-platform scripts
│   │   │   ├── check-prerequisites.ps1
│   │   │   ├── create-new-feature.ps1
│   │   │   ├── calculate-tokens.ps1
│   │   │   ├── compact-context.ps1
│   │   │   ├── roadmap-init.ps1
│   │   │   └── ...
│   │   │
│   │   └── bash/                     # macOS/Linux scripts
│   │       ├── check-prerequisites.sh
│   │       ├── create-new-feature.sh
│   │       ├── calculate-tokens.sh
│   │       ├── compact-context.sh
│   │       └── ...
│   │
│   ├── templates/                    # Markdown scaffolds
│   │   ├── spec-template.md
│   │   ├── plan-template.md
│   │   ├── tasks-template.md
│   │   ├── analysis-report-template.md
│   │   ├── optimization-report-template.md
│   │   ├── release-notes-template.md
│   │   └── ...
│   │
│   └── memory/                       # Long-term references
│       ├── constitution.md           # Engineering principles
│       ├── roadmap.md                # Feature roadmap
│       └── design-inspirations.md    # Design patterns
│
├── specs/                            # Feature specifications
│   ├── 001-example-feature/
│   │   ├── spec.md                   # Feature specification
│   │   ├── NOTES.md                  # Progress tracking, decisions
│   │   ├── artifacts/                # Generated artifacts
│   │   │   ├── plan.md
│   │   │   ├── tasks.md
│   │   │   ├── analysis-report.md
│   │   │   ├── optimization-report.md
│   │   │   └── release-notes.md
│   │   │
│   │   └── visuals/                  # Design references
│   │       └── README.md
│   │
│   └── 002-next-feature/
│       └── ...
│
├── docs/                             # Documentation
│   ├── architecture.md               # This file
│   ├── commands.md                   # Command reference
│   ├── getting-started.md            # Tutorial
│   ├── installation.md               # Platform-specific setup
│   ├── troubleshooting.md            # Common issues
│   └── use-cases.md                  # Project-type examples
│
├── .github/                          # GitHub configuration
│   ├── workflows/
│   │   └── ci.yml                    # CI validation
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── enhancement.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── labels.yml                    # Issue labels
│
├── README.md                         # Project overview
├── CLAUDE.md                         # AI agent guidance
├── CONTRIBUTING.md                   # Contribution guide
├── CODE_OF_CONDUCT.md                # Community standards
├── SECURITY.md                       # Security policy
├── LICENSE                           # MIT License
├── CHANGELOG.md                      # Version history
└── .gitignore                        # Git exclusions
```

## Token Strategy
The workflow keeps artifacts concise by:
- Pre-calculating budgets per phase (75k/100k/125k tokens) inside `/flow`.
- Running `compact-context.ps1` automatically when budgets exceed 80%.
- Encouraging teams to move long research to reference docs and link instead of inlining.

## Adapting the Workflow
1. Update `.spec-flow/templates/` to reflect your organizations spec formats.
2. Edit `.spec-flow/memory/constitution.md` to encode your engineering principles.
3. Adjust `check-prerequisites.ps1` if your repo structure differs (for example, storing specs outside `specs/`).
4. Customize agent briefs in `.claude/agents/` to mirror the roles on your team.

For more detailed usage instructions, see `README.md` and `CONTRIBUTING.md`.


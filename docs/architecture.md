# Spec-Flow Architecture

## Workflow Overview

Spec-Flow orchestrates feature work through a fixed series of Claude commands. Each command focuses on a deliverable (specification, plan, tasks, review) and hands contextual artifacts to the next step.

## Source Repo vs Consumer Project

This repository is the Spec-Flow source and distribution repo. It owns the
shared workflow canon, installer surfaces, adapter surfaces, and documentation.

Paths such as `epics/`, `specs/`, and `state.yaml` describe the installed
consumer-project model after Spec-Flow is applied to another repository. They
are not current top-level source-repo directories in this checkout.

## Repo map & domain guides

- `.spec-flow/repo-map.yaml` enumerates the active source-repo surfaces plus
  explicitly labeled consumer-project or planned surfaces. Each entry documents
  its role, responsibilities, boundaries, preferred locations, and new-code
  rules so every agent shares the same constitution.
- `.spec-flow/domains/*.yaml` adds deeper context for specific surfaces:
  - `epics.yaml` describes `epics/<slug>/` layout, sprint folders, and how specs → plan → tasks → implementation flow at the epic level.
  - `workflow-engine.yaml` governs `.spec-flow/` automation, hooks, and learnings.
  - `examples.yaml` outlines how the sample apps showcase the workflow without diverging from production rules.
- Always read the repo map plus relevant domain map before writing code or docs; new assets must live beside their peers and reuse existing templates.

## Tool-specific integrations

- `.claude/` contains Claude-first commands and skills; other tools may read but never edit this tree.
- `.codex/` houses Codex CLI prompts/adapters. Codex mirrors Claude behavior by reading `.claude/**` and the shared docs, then writing only inside `.codex/` plus normal repo areas.
- Future tool integrations should follow the same adapter pattern and must be
  labeled explicitly until their source-repo surfaces actually exist.
- AGENTS.md at the repo root summarizes these responsibilities so every tool stays aligned.

## Installed Consumer-Project State Model

- In consumer projects, every epic owns `epics/<epic-slug>/state.yaml`,
  seeded from `.spec-flow/templates/epic-state.template.yaml`. It tracks the
  epic slug, overall status, ordered phase statuses, sprint snapshots, linked
  feature slugs, and `last_updated`.
- Features under `specs/<feature>/` may have optional `state.yaml` files
  seeded from `.spec-flow/templates/feature-state.template.yaml`, but the epic
  file is the source of truth.
- The shared execution engine and tool adapters must read and update consumer
  project state consistently when advancing a phase.
- Auto mode (`spec-flow-epic-auto`) consults the epic state, runs at most the next phase or the next two early phases (spec + clarify or clarify + plan), writes the updated state, and stops for human review before tasks or implementation.

## Workflow State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SPEC-FLOW WORKFLOW STATE MACHINE                    │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌───────────┐
    │   START   │
    │ NEW PROJECT│
    └─────┬─────┘
          │
          ▼
    ┌─────────────────────┐
    │Has project docs?    │──Yes──┐
    │(docs/project/)      │       │
    └─────────┬───────────┘       │
              │ No                │
              │                   │
              ▼                   │
   ┌──────────────────┐           │
   │ /init-project    │ Phase -2: PROJECT DESIGN
   │ 8 Docs Generated │ Output: docs/project/*.md (8 files)
   │ Architecture Set │ - overview, architecture, tech-stack,
   └──────┬───────────┘   data, api, capacity, deployment, workflow
          │               ← Optional but recommended
          │
          └◄──────────────┘
          │
          ▼
   ┌──────────────┐
   │  /roadmap    │ Phase -1: ROADMAP PLANNING
   │ Add Features │ Output: GitHub Issues roadmap with prioritized features
   │ Prioritize   │ (ICE scoring: Impact × Confidence / Effort)
   └──────┬───────┘ ← Validates features against overview.md vision
          │
          ▼
    ┌─────────────────────┐
    │ Select feature from │
    │  roadmap to build   │
    └─────────┬───────────┘
          │
          ▼
   ┌──────────────┐
   │   /spec      │ Phase 0: SPECIFICATION
   │ Create Spec  │ Output: spec.md, NOTES.md, visuals/README.md
   │ from Roadmap │ Links back to roadmap entry
   └──────┬───────┘ ← Reads tech-stack, api-strategy, data-architecture,
          │           system-architecture from docs/project/
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
   │ Impl. Plan   │ Output: plan.md, research.md (with project context)
   └──────┬───────┘ ← Reads ALL 8 docs from docs/project/
          │
          ▼
   ┌──────────────┐
   │   /tasks     │ Phase 2: TASK BREAKDOWN
   │  20-30 Tasks │ Output: tasks.md (acceptance criteria)
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │  /validate   │ Phase 3: ANALYSIS
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
              │            │ User resolves  │ Then: /feature continue
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
              │            │ Resolve issues │ Then: /feature continue
              │            └──────┬─────────┘
              │                   │
              └◄──────────────────┘
          │
          ▼
   ╔══════════════╗
   ║ Local Preview║ OPTIONAL: UI/UX VALIDATION
   ║ User Validates║ Test locally, verify against spec
   ╚══════┬═══════╝
          │ User approves
          ▼
   ┌──────────────┐
   │/ship-staging │ Phase 7: SHIP TO STAGING
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
   │  /ship-prod  │ Phase 9: SHIP TO PRODUCTION
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

## Installed Consumer-Project Directory Structure

The following tree illustrates what a downstream project may contain after
Spec-Flow is installed. It is not the current source-repo layout of
`Spec-Flow` itself.

```
<consumer-project-root>/
│
├── .claude/                          # Claude Code configuration
│   ├── agents/                       # Agent persona briefs
│   │   ├── backend-dev.md
│   │   ├── frontend-dev.md
│   │   ├── qa-test.md
│   │   ├── senior-code-reviewer.md
│   │   ├── debugger.md
│   │   └── ci-cd-release.md
│   │
│   ├── commands/                     # Installed workflow command adapters
│   │   ├── core/
│   │   │   ├── feature.md            # Orchestrator (auto-progression)
│   │   │   └── epic.md               # Epic orchestration adapter
│   │   ├── phases/
│   │   │   ├── spec.md               # Phase 0: Create specification
│   │   │   ├── clarify.md            # Phase 0.5: Resolve ambiguities
│   │   │   ├── plan.md               # Phase 1: Implementation plan
│   │   │   ├── tasks.md              # Phase 2: Task breakdown
│   │   │   ├── validate.md           # Phase 3: Consistency analysis
│   │   │   ├── implement.md          # Phase 4: Execute tasks
│   │   │   ├── optimize.md           # Phase 5: Code review
│   │   │   └── debug.md              # Triage errors
│   │   ├── deployment/
│   │   │   ├── ship-staging.md       # Ship to staging
│   │   │   ├── validate-staging.md   # Manual gate: Validate staging
│   │   │   └── ship-prod.md          # Ship to production
│   │   └── README.md                 # Installed command inventory
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
│       ├── roadmap.md                # Optional legacy markdown roadmap seed
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

- Pre-calculating budgets per phase (75k/100k/125k tokens) inside `/feature`.
- Running `compact-context.ps1` automatically when budgets exceed 80%.
- Encouraging teams to move long research to reference docs and link instead of inlining.

## Adapting the Workflow

1. Update `.spec-flow/templates/` to reflect your organizations spec formats.
2. Edit `.spec-flow/memory/constitution.md` to encode your engineering principles.
3. Adjust `check-prerequisites.ps1` if your repo structure differs (for example, storing specs outside `specs/`).
4. Customize agent briefs in `.claude/agents/` to mirror the roles on your team.

For more detailed usage instructions, see `README.md` and `CONTRIBUTING.md`.

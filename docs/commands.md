# Command Catalog

| Command | Purpose | Key Artifacts |
|---------|---------|---------------|
| `/spec-flow` | Drafts feature specification, NOTES.md, and visuals scaffold. | `spec.md`, `NOTES.md`, `visuals/README.md` |
| `/clarify` | Resolves ambiguities marked in the spec. | Clarification log inline within `spec.md` |
| `/plan` | Produces implementation plan and research summary. | `plan.md`, `research.md` |
| `/tasks` | Builds the execution backlog with acceptance criteria. | `tasks.md` |
| `/analyze` | Audits cross-artifact consistency and risk. | `analysis-report.md` |
| `/implement` | Guides coding, testing, and documentation updates. | Implementation checklist |
| `/optimize` | Performs agent-driven code review and optimization passes. | Optimization report |
| `/debug` | Triage error logs and failing tests. | `error-log.md` updates |
| `/preview` | Prepares release notes and feature preview summary. | `release-notes.md`, preview checklist |
| `/phase-1-ship` | Executes staging deployment ritual. | Staging validation record |
| `/validate-staging` | Confirms staging acceptance. | Sign-off summary |
| `/phase-2-ship` | Drives production launch and follow-up. | Launch checklist |

Use `/flow` to orchestrate automated progression through the steps above. See `.claude/commands/flow.md` for the full state machine.

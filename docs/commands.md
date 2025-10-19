# Command Catalog

| Command | Purpose | Key Artifacts |
|---------|---------|---------------|
| `/roadmap` | Add features to roadmap, prioritize with ICE scoring, organize into stages. | `roadmap.md` with Backlog/Next/In Progress/Shipped |
| `/feature` | Orchestrates full feature workflow with isolated phase contexts (optimized). | `spec.md`, `NOTES.md`, `visuals/README.md`, `workflow-state.yaml` |
| `/clarify` | Resolves ambiguities marked in the spec. | Clarification log inline within `spec.md` |
| `/plan` | Produces implementation plan and research summary. | `plan.md`, `research.md` |
| `/tasks` | Builds the execution backlog with acceptance criteria. | `tasks.md` |
| `/validate` | Audits cross-artifact consistency and risk. | `analysis-report.md` |
| `/implement` | Guides coding, testing, and documentation updates. | Implementation checklist |
| `/optimize` | Performs agent-driven code review and optimization passes. | Optimization report |
| `/debug` | Triage error logs and failing tests. | `error-log.md` updates |
| `/preview` | Prepares release notes and feature preview summary. | `release-notes.md`, preview checklist |
| `/ship-staging` | Executes staging deployment ritual. | Staging validation record |
| `/validate-staging` | Confirms staging acceptance. | Sign-off summary |
| `/ship-prod` | Drives production launch and follow-up. | Launch checklist |

Use `/feature` to orchestrate automated progression through the steps above. See `.claude/commands/feature.md` for the full workflow.

# Epic Workflow Overview

Spec-Flow is epic-first. Every epic lives in `epics/<epic-slug>/` and owns the canonical artifacts:

- `state.yaml` — phase + sprint + feature status (see `state-epic.yaml`).
- `spec.md` — epic goals, constraints, and acceptance criteria.
- `plan.md` — architecture choices, sequencing, risk management.
- `tasks.md` — sprint-scope breakdown with dependencies and owners.
- `sprints/<id>/...` — optional sprint plans, retros, or reports.

## Phase machine

| Phase      | Output                                         | Notes                                          |
| ---------- | ---------------------------------------------- | ---------------------------------------------- |
| spec       | `spec.md`, supporting research                 | Seeds epic backlog + roadmap links             |
| clarify    | updated `spec.md`                              | Resolve ambiguities before planning            |
| plan       | `plan.md`, research notes                      | Defines architecture, sequencing, dependencies |
| tasks      | `tasks.md`, sprint entries                     | Taskizes plan into sprint-ready slices         |
| implement  | code, docs, tests per tasks                    | Updates happen across mapped repo areas        |
| optimize   | review + QA reports                            | Validates implementation quality               |
| preview    | manual UX gate (optional)                      | Stop if approvals pending                      |
| ship       | staging/prod deploy artifacts                  | Logs releases + metrics                        |
| finalize   | retros, learning capture                       | Archive + inform roadmap                       |

Each phase advances only when prerequisites are satisfied in `state.yaml`. Auto-mode helpers may chain **at most** spec → clarify → plan; all later phases require manual invocation.

## State handling

1. Seed new epics from `.spec-flow/templates/epic-state.template.yaml`.
2. Update `state.yaml` after every phase, keeping `phases.*`, `sprints`, `features`, and `last_updated` accurate.
3. Feature folders (`specs/<feature>/`) may own their own state file, but the epic `state.yaml` remains authoritative and must reference every active feature.

When in doubt, read `.spec-flow/repo-map.yaml` plus `.spec-flow/domains/epics.yaml` to decide where a document or script belongs.

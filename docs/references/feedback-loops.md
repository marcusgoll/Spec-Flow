# Feedback Loops (v10.0+)

Discovered implementation gaps during preview/validation can be addressed without creating new epics.

## When to Use

During staging validation, you discover a missing endpoint or feature that was in the original scope but not implemented.

## Workflow

```
/ship-staging → discover gap → /validate-staging --capture-gaps → scope validation →
supplemental tasks generated → /epic continue (iteration 2) → /optimize → /ship
```

## Process

1. **Gap Discovery**: During `/validate-staging`, identify missing implementations
2. **Capture Gaps**: Run `/validate-staging --capture-gaps` to launch interactive wizard
3. **Scope Validation**: System auto-validates against epic-spec.md/spec.md
   - IN SCOPE: Generates supplemental tasks
   - OUT OF SCOPE: Blocks as feature creep (create new epic)
   - AMBIGUOUS: Requires user decision
4. **Loop Back**: Workflow returns to `/implement` for iteration 2
5. **Execute**: `/epic continue` or `/feature continue` runs only supplemental tasks
6. **Re-validate**: Quality gates re-run, deploy to staging again
7. **Converge**: Max 3 iterations to prevent infinite loops

## Example

```bash
# Iteration 1 complete, deployed to staging
/ship-staging

# During testing, discover missing /v1/auth/me endpoint
/validate-staging --capture-gaps
# → System validates: IN SCOPE
# → Generates 3 supplemental tasks (T031, T032, T033)
# → Returns to /implement phase (iteration 2)

# Execute iteration 2 (only 3 tasks, not full re-implementation)
/epic continue
# → Runs T031-T033
# → Re-runs /optimize
# → Deploys to staging again

# No more gaps found
/ship-prod
```

## Artifacts

- `gaps.md` — Documented gaps with scope validation results
- `scope-validation-report.md` — Evidence for IN/OUT of scope decisions
- `tasks.md` — Appended supplemental tasks (marked with iteration number)
- `state.yaml` — Iteration tracking and gap statistics

## Scope Validation Algorithm

1. Check if gap mentioned in Objective/Requirements
2. Check if gap excluded in "Out of Scope" section
3. Check if gap aligns with involved subsystems
4. Check if gap relates to acceptance criteria

## Iteration Limits

- Max iterations: 3 (prevents infinite loops and scope creep)
- After 3 iterations, remaining gaps → new epic
- Iteration tracking in state.yaml

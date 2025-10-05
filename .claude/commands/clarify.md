---
description: Reduce spec ambiguity via targeted questions (planning is 80% of success)
---

Clarify ambiguities in specification: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Load spec -> Scan ambiguities -> Ask questions -> Update spec -> Suggest next

**Auto-suggest:**
- When clarified -> `/plan`

## LOAD SPEC

Use the helper script to get feature paths:
```bash
pwsh -NoProfile -File .spec-flow/scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
# or
.spec-flow/scripts/bash/check-prerequisites.sh --json --paths-only
```

Parse: `FEATURE_DIR` and `FEATURE_SPEC`

## SCAN AMBIGUITIES

Scan for `[NEEDS CLARIFICATION]` markers and vague requirements:

**Categories (inferred dynamically):**
- Functional scope & behavior gaps
- Domain & data model uncertainties
- Non-functional quality attributes (vague adjectives)
- Integration dependencies & failure modes
- Edge cases & error handling
- Context strategy unclear

**Prioritize by impact:**
- Architecture/data model changes (highest)
- Testing/UX behavior
- Performance/security targets
- Minor wording improvements (lowest)

## ASK QUESTIONS (unlimited, one at a time)

**No limit on questions** - continue until all ambiguities resolved or user signals done.

**Format:**
- **Multiple choice**: 2-5 mutually exclusive options OR
- **Short answer**: <=5 words

**One question at a time:**
```
Q: [Clear, specific question]

| Option | Description |
|--------|-------------|
| A      | [Option A (YOUR RECOMMENDATION)] |
| B      | [Option B] |
| Short  | Provide different answer (<=5 words) |

[short reason why your recommendation]
```

**Stop when:**
- All ambiguities resolved OR
- User signals: "done", "proceed", "stop"

## UPDATE SPEC (after each answer)

1. Add to `## Clarifications` section:
   ```markdown
   ### Session YYYY-MM-DD
   - Q: [question] -> A: [answer]
   ```

2. Apply clarification to appropriate section:
   - Functional -> Update Functional Requirements
   - User interaction -> Update User Scenarios
   - Data -> Update Key Entities
   - Non-functional -> Update NFR with metrics
   - Edge case -> Add to Edge Cases section
   - Context -> Update Context Strategy

3. Remove `[NEEDS CLARIFICATION]` marker
4. Save spec file after each update

## VALIDATION

After each update:
- No contradictions with existing spec
- Terminology consistent
- Clarification applied to all relevant sections
- Markdown structure valid

## RETURN

Brief summary:
```
Summary:
- Clarifications complete (N questions resolved)

Details:
- Updated sections: [list]
- Removed: All [NEEDS CLARIFICATION] markers
- Session log: Added to spec.md

Next: /plan
Optional: /compact planning (if context feels heavy)
```

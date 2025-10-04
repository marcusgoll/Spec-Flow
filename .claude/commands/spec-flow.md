---
description: Create feature specification from natural language (planning is 80% of success)
---

Create specification for: $ARGUMENTS

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Check roadmap -> Research -> Generate spec -> Update roadmap -> Suggest next

**Auto-suggest:**
- If `[NEEDS CLARIFICATION]` found -> `/clarify`
- If spec clear -> `/plan`

## INITIALIZE

1. Create feature branch:
   ```bash
   NEXT_NUM=$(ls -d specs/*/ 2>/dev/null | wc -l | awk '{print $1 + 1}')
   SLUG=$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
   git checkout -b ${NEXT_NUM}-${SLUG}
   ```

2. Create feature directory:
   ```bash
   mkdir -p specs/${NEXT_NUM}-${SLUG}/{visuals,artifacts}
   ```

## CHECK ROADMAP (auto-detection)

**Auto-detect roadmap features by slug:**
- Check `.spec-flow/memory/roadmap.md` for matching slug
- Extract: requirements, area, role, phase, impact/effort
- Use as starting point for spec
- Preserve `[CLARIFY: ...]` tags

**If found in roadmap:**
- Reuse context automatically
- Will update roadmap after spec creation (move to "In Progress", add branch/spec links)

**If not found:**
- Continue with research workflow
- Optional: Add to roadmap later with `/roadmap add`

**Usage examples:**
- `/spec-flow csv-export`  Auto-detects csv-export from roadmap
- `/spec-flow "new feature name [feature description]"`  Creates fresh spec, no roadmap context

## RESEARCH (5-10 tool calls)

**Gather context before writing:**
- Glob existing specs for similar patterns
- Read constitution.md for compliance
- Read .spec-flow/memory/design-inspirations.md for global style preferences
- WebSearch for UX patterns (if user-facing)
- Use chrome-devtools for visual research (extract insights to text)
- Grep codebase for related functionality

## GENERATE SPEC

**Create `specs/NNN-feature/spec.md`:**
- Use `.spec-flow/templates/spec-template.md` as base
- Fill from roadmap (if available) or research
- User scenarios (Given/When/Then)
- Requirements (FR-001, FR-002..., NFR-001...)
- Context Strategy & Signal Design
- Mark ambiguities: `[NEEDS CLARIFICATION: question]`

**Create `specs/NNN-feature/NOTES.md`:**
```markdown
# Feature: [Name]

## Overview
[1-paragraph description]

## Research Findings
- Finding 1: [what + source]
- Finding 2: [decision + rationale]

## Checkpoints
- Phase 0 (spec-flow): [date]

## Context Budget
- Phase 0: N tokens

## Last Updated
[ISO timestamp]
```

**Create `specs/NNN-feature/visuals/README.md` (if applicable):**
- Use `.spec-flow/templates/visuals-readme-template.md`
- Document UX patterns from chrome-devtools
- Extract layout, colors, interactions, measurements
- Include reference URLs

## GIT VALIDATION

Before creating branch, check:
1. `git status --porcelain` (empty = clean)
2. `git branch --show-current` != "main"
3. Branch doesn't exist: `git show-ref --verify refs/heads/${NEXT_NUM}-${SLUG}` (exit code 1 = doesn't exist)
4. If dirty: Offer "stash", "commit", or "abort"

## UPDATE ROADMAP (if from roadmap)

If feature came from roadmap:
1. Move to "In Progress" section
2. Add: `**Branch**: ${NEXT_NUM}-${SLUG}`
3. Add: `**Spec**: specs/${NEXT_NUM}-${SLUG}/spec.md`
4. Add: `**Updated**: $(date +%Y-%m-%d)`
5. Commit roadmap update

## GIT COMMIT

```bash
git add specs/${NEXT_NUM}-${SLUG}/
git commit -m "design:spec: add [feature name] specification

- User scenarios for [flows]
- Requirements (FR-001 to FR-NNN)
- Context strategy documented

# Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## AUTO-PROGRESSION

After spec creation, intelligently suggest next command:

```bash
# Count clarification markers
CLARIFICATIONS=$(grep -c "\\[NEEDS CLARIFICATION" specs/NNN-*/spec.md || echo 0)

if [ "$CLARIFICATIONS" -gt 0 ]; then
  echo ""
  echo "  AUTO-PROGRESSION: Clarifications needed"
  echo ""
  echo ""
  echo "Found $CLARIFICATIONS ambiguities marked [NEEDS CLARIFICATION]"
  echo ""
  echo "Recommended: /clarify"
  echo "Alternative: /plan (proceed with current spec, clarify later)"
  echo ""
  echo "To automate: /flow \"[feature-name]\" (runs full workflow)"
else
  echo ""
  echo " AUTO-PROGRESSION: Spec is clear"
  echo ""
  echo ""
  echo "No ambiguities found - ready for planning"
  echo ""
  echo "Recommended: /plan"
  echo "Alternative: /flow continue (automates plan  tasks  implement  ship)"
fi
```

## RETURN

Brief summary with actionable next steps:
```

 SPECIFICATION COMPLETE


Feature: [feature-name]
Spec: specs/NNN-feature-slug/spec.md
Branch: NNN-feature-slug

Details:
- Requirements: N functional, N non-functional
- Visual research: N sites analyzed (if applicable)
- Ambiguities: N found OR 0
- Context budget: N,NNN tokens
- NOTES.md: Phase 0 checkpoint


 NEXT STEPS


Manual (step-by-step):
   /clarify (if N > 0 ambiguities)
   /plan (if N = 0 ambiguities)

Automated (full workflow):
   /flow continue

[Auto-progression guidance shown above]
```


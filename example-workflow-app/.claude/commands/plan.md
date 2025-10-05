---
description: Generate design artifacts from feature spec (research + design + context plan)
---

Design implementation for: specs/$FEATURE/spec.md

## MENTAL MODEL

**Workflow**: spec-flow -> clarify -> plan -> tasks -> analyze -> implement -> optimize -> debug -> preview -> phase-1-ship -> validate-staging -> phase-2-ship

**State machine:**
- Research codebase -> Design artifacts -> Document context plan -> Suggest next

**Auto-suggest:**
- When complete -> `/tasks`

**Context budget:**
- Planning phase (0-2): 75k tokens
- Auto-compact at 80% (60k tokens)
- Aggressive compression (90% reduction)

## RESEARCH CODEBASE (10-20 tool calls)

**Prevent duplication - scan before designing:**

1. **Glob modules**: Backend (`api/src/modules/*`, `api/src/services/*`) + Frontend (`apps/*/components/**`, `apps/*/lib/**`)
2. **Grep for patterns**: Search similar functionality by keywords
3. **Read similar domains**: Find closest existing module, identify reusable components
4. **Research unknowns**: For each spec ambiguity, WebSearch best practices, read .spec-flow/memory/design-inspirations.md for global style preferences, read visuals/README.md for UX patterns

**Output to `research.md`:**
```markdown
## Decision: [Technology/Pattern Choice]
- Decision: [what chosen]
- Rationale: [why]
- Alternatives: [what rejected]
- Source: [link/file]
```

## DESIGN ARTIFACTS

**Generate `plan.md` with sections:**

- **[ARCHITECTURE DECISIONS]**: Stack, patterns, state management, deployment
- **[STRUCTURE]**: Directory layout, module organization (follow existing patterns)
- **[SCHEMA]**: Database tables (Mermaid ERD), API schemas, state shape
- **[PERFORMANCE TARGETS]**: API <500ms, Frontend FCP <1.5s/TTI <3s, DB <100ms
- **[SECURITY]**: Auth strategy, authorization model, input validation, rate limiting
- **[EXISTING INFRASTRUCTURE - REUSE]**: List services/modules to reuse
- **[NEW INFRASTRUCTURE - CREATE]**: List new capabilities needed
- **[CONTEXT ENGINEERING PLAN]**: Token budget, retrieval strategy, memory artifacts, compaction

**Generate `data-model.md`:**
- Entity diagrams, field definitions, relationships, state machines

**Generate `contracts/*.yaml`:**
- OpenAPI specs for each API, request/response schemas, error responses

**Generate `quickstart.md`:**
- Integration test scenarios, setup commands, validation steps

**Initialize `error-log.md`:**
- Use `.spec-flow/templates/error-log-template.md`
- Pre-implementation entry for failure tracking

## CONTEXT BUDGET TRACKING

**Planning Phase Budget (Phase 0-2):**
- **Budget**: 75k tokens
- **Compact at**: 60k tokens (80% threshold)
- **Strategy**: Aggressive (90% reduction - keep decisions only)

**After completing design artifacts:**

```bash
# Calculate current context (auto-detects planning phase)
# POSIX: replace 'pwsh -File' with matching .spec-flow/scripts/bash/*.sh helper
FEATURE_DIR=$(find specs -maxdepth 1 -type d -name "*-*" | sort -n | tail -1)
CONTEXT_CHECK=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
  -FeatureDir "$FEATURE_DIR" -Phase "planning" -Json)

CONTEXT_TOKENS=$(echo "$CONTEXT_CHECK" | jq -r '.totalTokens')
SHOULD_COMPACT=$(echo "$CONTEXT_CHECK" | jq -r '.shouldCompact')
BUDGET=$(echo "$CONTEXT_CHECK" | jq -r '.budget')
THRESHOLD=$(echo "$CONTEXT_CHECK" | jq -r '.threshold')

echo "Context: ${CONTEXT_TOKENS}/${BUDGET} tokens (planning phase)"

if [ "$SHOULD_COMPACT" = "true" ]; then
  echo "  Exceeds threshold (${THRESHOLD} tokens)"
  echo "Auto-compacting with aggressive strategy (90% reduction)..."

  pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 \
    -FeatureDir "$FEATURE_DIR" \
    -Phase "planning"

  # Verify compaction
  NEW_TOKENS=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
    -FeatureDir "$FEATURE_DIR" -Phase "planning" -Json | jq -r '.totalTokens')
  echo " Compacted: ${CONTEXT_TOKENS}  ${NEW_TOKENS} tokens"

  # Update NOTES.md checkpoint
  echo "-  Context compacted (planning): ${CONTEXT_TOKENS}  ${NEW_TOKENS} tokens" >> "$FEATURE_DIR/NOTES.md"
fi
```

**If budget still exceeded after compaction:**
- Feature may be too large for single spec
- Suggest breaking into smaller features by domain/area
- Example: "Dashboard"  "Dashboard Layout" + "Dashboard Widgets" + "Dashboard Analytics"

## GIT COMMIT

```bash
git add specs/${FEATURE}/
git commit -m "design:plan: complete architecture with reuse analysis

[ARCHITECTURE DECISIONS]
- Stack: [choices]
- Patterns: [decisions]

[EXISTING - REUSE]
- N modules/services identified

[NEW - CREATE]
- N new capabilities needed

# Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

## RETURN

Brief summary:
```
Summary:
- Design complete: plan.md, research.md, data-model.md, contracts/, quickstart.md

Details:
- Research: N decisions, N alternatives
- Existing: N modules/services to REUSE
- New: N capabilities to CREATE
- Context: NN,NNN tokens (compacted: Y/N)
- error-log.md: Initialized
- NOTES.md: Phase 1 checkpoint

Next: /tasks
```


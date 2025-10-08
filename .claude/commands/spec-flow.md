---
description: Orchestrate full feature workflow with isolated phase contexts (optimized)
---

Orchestrate feature delivery through isolated phase agents for maximum efficiency.

## MENTAL MODEL

**Architecture**: Orchestrator-Workers with Phase Isolation
- **Orchestrator** (`/spec-flow`): Lightweight state tracking, phase progression
- **Phase Agents**: Isolated contexts, call slash commands, return summaries
- **Worker Agents**: Called by implement-phase-agent (backend-dev, frontend-shipper, etc.)

**Benefits**:
- 67% token reduction (240k → 80k per feature)
- 2-3x faster (isolated contexts, no /compact overhead)
- Same quality (slash commands unchanged)

**Backup**: `/flow` command remains unchanged as fallback

## PARSE ARGUMENTS

**Get feature description or continue mode:**

If `$ARGUMENTS` is empty, show usage:
```
Usage: /spec-flow [feature description]
   or: /spec-flow continue

Examples:
  /spec-flow "Student progress tracking dashboard"
  /spec-flow continue

Note: Use /flow for original workflow (backup)
```

If `$ARGUMENTS` is "continue":
- Set `CONTINUE_MODE = true`
- Load workflow state from `.spec-flow/workflow-state.json`
- Resume from last completed phase

Else:
- Set `CONTINUE_MODE = false`
- Set `FEATURE_DESCRIPTION = $ARGUMENTS`
- Initialize new workflow

## DETECT PROJECT TYPE

**Run project type detection:**

```bash
# Use detection script (bash or PowerShell based on OS)
if command -v bash &> /dev/null; then
  PROJECT_TYPE=$(bash .spec-flow/scripts/bash/detect-project-type.sh)
else
  PROJECT_TYPE=$(pwsh -File .spec-flow/scripts/powershell/detect-project-type.ps1)
fi

echo "📦 Project type: $PROJECT_TYPE"
echo ""
```

**Project types:**
- `local-only` - No remote repo, workflow ends at `/optimize`
- `remote-staging-prod` - Full staging → production workflow
- `remote-direct` - Remote repo, direct to main (no staging)

## INITIALIZE WORKFLOW STATE

**Create or load workflow state file:**

State file location: `.spec-flow/workflow-state.json`

**For new workflows:**
Create state file with:
```json
{
  "feature": "[feature-slug]",
  "feature_description": "[original user input]",
  "project_type": "[local-only|remote-staging-prod|remote-direct]",
  "current_phase": 0,
  "phases_completed": [],
  "phase_summaries": {},
  "started_at": "[ISO timestamp]",
  "last_updated": "[ISO timestamp]",
  "status": "in_progress",
  "manual_gates": {
    "preview": false,
    "validate_staging": false
  },
  "timings": {}
}
```

**For continue mode:**
Read existing state file to determine next phase and project type.

## EXECUTION STRATEGY

### Phase 0: Specification (DESIGN)

**Invoke phase agent with minimal context:**

Use Task tool:
```
Task(
  subagent_type="spec-phase-agent",
  description="Phase 0: Create Specification",
  prompt=f"""
Execute Phase 0: Specification in isolated context.

Feature Description: {FEATURE_DESCRIPTION}
Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /specify slash command with feature description
2. Extract key information from resulting spec.md
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)
```

**Validate phase completion:**

```bash
# Parse result JSON
if [ "$STATUS" != "completed" ]; then
  echo "❌ Phase 0 blocked: $SUMMARY"
  echo "Blockers:"
  # Print blockers from result
  exit 1
fi

# Store phase summary in workflow-state.json
# Update phases_completed array
# Log progress
echo "✅ Phase 0 complete: $SUMMARY"
echo "Key decisions:"
# Print key_decisions from result
echo ""

# Check if clarification needed
if [ "$NEEDS_CLARIFICATION" = "true" ]; then
  NEXT_PHASE="clarify"
else
  NEXT_PHASE="plan"
fi
```

### Phase 0.5: Clarification (CONDITIONAL)

**Only execute if Phase 0 identified clarifications needed:**

```
if needs_clarification:
  Task(
    subagent_type="clarify-phase-agent",
    description="Phase 0.5: Resolve Clarifications",
    prompt=f"""
Execute Phase 0.5: Clarification in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {SPEC_SUMMARY}

Your task:
1. Call /clarify slash command
2. Extract clarification results
3. Return structured JSON summary

Refer to your agent brief for full instructions.
    """
  )

  # Validate, store summary, log progress
```

### Phase 1: Planning (DESIGN)

**Invoke phase agent:**

```
Task(
  subagent_type="plan-phase-agent",
  description="Phase 1: Create Plan",
  prompt=f"""
Execute Phase 1: Planning in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {SPEC_SUMMARY}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /plan slash command
2. Extract architecture decisions and reuse opportunities
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress
```

### Phase 2: Task Breakdown (DESIGN)

**Invoke phase agent:**

```
Task(
  subagent_type="tasks-phase-agent",
  description="Phase 2: Create Tasks",
  prompt=f"""
Execute Phase 2: Task Breakdown in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {PLAN_SUMMARY}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /tasks slash command
2. Extract task statistics and breakdown
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress
```

### Phase 3: Analysis (VALIDATION)

**Invoke phase agent:**

```
Task(
  subagent_type="analyze-phase-agent",
  description="Phase 3: Cross-Artifact Analysis",
  prompt=f"""
Execute Phase 3: Analysis in isolated context.

Feature Slug: {SLUG}
Previous Phase Summaries:
- Spec: {SPEC_SUMMARY}
- Plan: {PLAN_SUMMARY}
- Tasks: {TASKS_SUMMARY}

Your task:
1. Call /analyze slash command
2. Extract critical issues and validation results
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Check for critical issues (block if found)
# Validate, store summary, log progress
```

### Phase 4: Implementation (EXECUTION)

**Invoke phase agent:**

```
Task(
  subagent_type="implement-phase-agent",
  description="Phase 4: Execute Implementation",
  prompt=f"""
Execute Phase 4: Implementation in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {TASKS_SUMMARY}

Your task:
1. Call /implement slash command (handles parallel worker agents internally)
2. Extract implementation statistics
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Check for incomplete tasks (block if found)
# Validate, store summary, log progress with stats
```

### Phase 5: Optimization (QUALITY)

**Invoke phase agent:**

```
Task(
  subagent_type="optimize-phase-agent",
  description="Phase 5: Code Review & Optimization",
  prompt=f"""
Execute Phase 5: Optimization in isolated context.

Feature Slug: {SLUG}
Previous Phase Summary: {IMPLEMENT_SUMMARY}

Your task:
1. Call /optimize slash command
2. Extract quality metrics and critical findings
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Check for critical issues (block if found)
# Validate, store summary, log progress with metrics
```

### MANUAL GATE 1: Preview (USER VALIDATION)

**Pause for user validation:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 MANUAL GATE: PREVIEW"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: /preview"
echo ""
echo "Action required:"
echo "1. Run /preview to start local dev server"
echo "2. Test UI/UX flows manually"
echo "3. Verify acceptance criteria from spec"
echo "4. When satisfied, continue: /spec-flow continue"
echo ""

# Update workflow-state.json status to "awaiting_preview"
# Save and exit (user will run /spec-flow continue after testing)
```

### Phase 6: Ship to Staging (DEPLOYMENT)

**Check project type (skip for local-only):**

```bash
PROJECT_TYPE=$(grep -o '"project_type":\s*"[^"]*"' .spec-flow/workflow-state.json | cut -d'"' -f4)

if [ "$PROJECT_TYPE" = "local-only" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Local-only project detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Skipping staging deployment (no remote repository configured)."
  echo ""
  echo "✅ Feature implementation complete!"
  echo ""
  echo "Next steps (manual deployment):"
  echo "  1. Review changes: git diff main"
  echo "  2. Merge to main: git checkout main && git merge \$FEATURE_BRANCH"
  echo "  3. Tag release: git tag v1.0.0"
  echo "  4. Deploy manually to your environment"
  echo ""

  # Mark workflow complete and exit
  exit 0
fi
```

**For remote projects, invoke phase agent:**

```
Task(
  subagent_type="ship-staging-phase-agent",
  description="Phase 6: Deploy to Staging",
  prompt=f"""
Execute Phase 6: Ship to Staging in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /phase-1-ship slash command
2. Extract deployment status and PR info
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress with PR/URL info
```

### MANUAL GATE 2: Validate Staging (USER VALIDATION)

**Pause for staging validation:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 MANUAL GATE: STAGING VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next: /validate-staging"
echo ""
echo "Action required:"
echo "1. Test feature on staging environment"
echo "2. Verify E2E tests passed (GitHub Actions)"
echo "3. Check Lighthouse CI scores"
echo "4. When approved, continue: /spec-flow continue"
echo ""

# Update workflow-state.json status to "awaiting_staging_validation"
# Save and exit
```

### Phase 7: Ship to Production (DEPLOYMENT)

**Invoke phase agent:**

```
Task(
  subagent_type="ship-prod-phase-agent",
  description="Phase 7: Deploy to Production",
  prompt=f"""
Execute Phase 7: Ship to Production in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /phase-2-ship slash command
2. Extract deployment status and release version
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, log progress with release/URL info
```

### Phase 7.5: Finalize (DOCUMENTATION)

**Invoke phase agent:**

```
Task(
  subagent_type="finalize-phase-agent",
  description="Phase 7.5: Finalize Documentation",
  prompt=f"""
Execute Phase 7.5: Finalization in isolated context.

Feature Slug: {SLUG}
Project Type: {PROJECT_TYPE}

Your task:
1. Call /finalize slash command
2. Extract documentation updates
3. Return structured JSON summary

Refer to your agent brief for full instructions.
  """
)

# Validate, store summary, mark workflow complete
```

### Completion

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Feature Workflow Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature: $SLUG"
echo "Status: Shipped to Production"
echo ""
echo "Summary:"
# Print phase summaries from workflow-state.json
echo ""
echo "Workflow state saved to .spec-flow/workflow-state.json"
```

## ERROR HANDLING

**If any phase fails:**

```bash
if [ "$STATUS" = "blocked" ]; then
  echo "❌ Phase $PHASE_NUM blocked"
  echo "Summary: $SUMMARY"
  echo ""
  echo "Blockers:"
  # Print blockers from result
  echo ""
  echo "Fix blockers and continue: /spec-flow continue"

  # Save state with blocker info
  exit 1
fi
```

## BENEFITS SUMMARY

**Token Efficiency:**
- Old `/flow`: ~240k tokens (cumulative context)
- New `/spec-flow`: ~80k tokens (isolated contexts)
- **Savings: 67%**

**Speed:**
- Isolated contexts start fresh (faster Claude response)
- No /compact overhead between phases
- **Improvement: 2-3x faster**

**Quality:**
- Slash commands unchanged (proven workflow)
- Phase agents add thin orchestration layer
- **Maintained: Same quality gates**

## FALLBACK

**If issues with `/spec-flow`:**

Use original `/flow` command (unchanged, available as backup)

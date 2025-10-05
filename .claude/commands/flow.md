---
description: Orchestrate full feature workflow from idea to staging (with manual gates)
---

Orchestrate full feature workflow: $ARGUMENTS

## MENTAL MODEL

**Workflow**: Feature idea -> Staging deployment (automated with manual checkpoints)

**Pattern**: Orchestrator-Workers (from Anthropic best practices)
- **Orchestrator**: /flow tracks progress, manages context, handles errors
- **Workers**: Individual slash commands are specialists
- **Checkpoints**: Manual gates at critical decision points

**Context management**:
- Adaptive phase-based budgets (75k/100k/125k tokens)
- Auto-compact at 80% threshold (60k/80k/100k)
- Just-in-time loading of artifacts
> Platform note: On macOS/Linux replace `pwsh -File` calls with the matching `.spec-flow/scripts/bash/*.sh` helper.
- Phase-aware compression strategies (90%/60%/30% reduction)

## STATE MACHINE

```
IDEA/DESCRIPTION
  
PHASE 0: spec-flow -> spec.md created
   [auto-check for clarifications]
   If [NEEDS CLARIFICATION] -> PHASE 0.5: CLARIFY
   Else -> PHASE 1: PLAN
  
PHASE 1: PLAN -> plan.md, research.md created
  
PHASE 2: TASKS -> tasks.md (20-30 tasks) created
  
PHASE 3: ANALYZE -> analysis-report.md
   [check for CRITICAL issues]
   If CRITICAL -> PAUSE: User must fix
   Else -> PHASE 4: IMPLEMENT
  
PHASE 4: IMPLEMENT -> All tasks completed
   [context check: >80k tokens? (implementation phase)]
   If >80k -> Auto-compact (60% reduction to context-delta.md)
   Continue
  
PHASE 5: OPTIMIZE -> optimization-report.md
   [auto-fix enabled?]
   If critical issues -> Auto-fix loop (max 3 iterations)
   If blockers remain -> PAUSE: User must fix
  
MANUAL GATE 1: PREVIEW -> User validates UI/UX
   User confirms quality
  
PHASE 6: PHASE-1-SHIP -> PR to staging, auto-merge
   [wait for CI, auto-merge when green]
  
MANUAL GATE 2: VALIDATE-STAGING -> User validates staging deployment
   User approves for production
  
PHASE 7: PHASE-2-SHIP -> PR to main, auto-merge, release
  
DONE: Feature shipped to production
```

## EXECUTION STRATEGY

### Phase 0: Specification (DESIGN)
```bash
# 1. Create feature specification
/spec-flow "$ARGUMENTS"

# 2. Check for clarification needs
if grep -q "\\[NEEDS CLARIFICATION" specs/NNN-*/spec.md; then
  echo " Clarifications needed"
  /clarify
  # After clarify, continue to plan
fi

# 3. Continue to planning
echo " Spec clear, proceeding to plan"
```

### Phase 1: Planning (DESIGN)
```bash
# Generate implementation plan
/plan

# Auto-compact after planning if needed
FEATURE_DIR=$(find specs -maxdepth 1 -type d -name "*-*" | sort -n | tail -1)
CONTEXT_CHECK=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
  -FeatureDir "$FEATURE_DIR" -Phase "planning" -Json)

SHOULD_COMPACT=$(echo "$CONTEXT_CHECK" | jq -r '.shouldCompact')

if [ "$SHOULD_COMPACT" = "true" ]; then
  pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 \
    -FeatureDir "$FEATURE_DIR" \
    -Phase "planning"
fi
```

### Phase 2: Task Breakdown (DESIGN)
```bash
# Generate task list (20-30 tasks)
/tasks

# Auto-trigger analysis
echo " Tasks generated, proceeding to analyze"
```

### Phase 3: Analysis (VALIDATION)
```bash
# Cross-artifact consistency check
/analyze

# Check for blockers
if grep -q "Critical: [1-9]" specs/NNN-*/artifacts/analysis-report.md; then
  echo " CRITICAL ISSUES FOUND"
  echo "Review: specs/NNN-*/artifacts/analysis-report.md"
  echo ""
  echo "Fix critical issues, then run: /flow continue"
  exit 1
fi

echo " Analysis passed, proceeding to implement"
```

### Phase 4: Implementation (EXECUTION)
```bash
# Execute all tasks with agent routing
/implement

# Auto-compact after implementation if needed
FEATURE_DIR=$(find specs -maxdepth 1 -type d -name "*-*" | sort -n | tail -1)
CONTEXT_CHECK=$(pwsh -File .spec-flow/scripts/powershell/calculate-tokens.ps1 \
  -FeatureDir "$FEATURE_DIR" -Phase "implementation" -Json)

SHOULD_COMPACT=$(echo "$CONTEXT_CHECK" | jq -r '.shouldCompact')

if [ "$SHOULD_COMPACT" = "true" ]; then
  pwsh -File .spec-flow/scripts/powershell/compact-context.ps1 \
    -FeatureDir "$FEATURE_DIR" \
    -Phase "implementation"
fi

echo " Implementation complete, proceeding to optimize"
```

### Phase 5: Optimization (VALIDATION)
```bash
# Production readiness validation
/optimize

# Check for blockers
if grep -q "Blockers: [1-9]" specs/NNN-*/artifacts/optimization-report.md; then
  echo "  Blockers found in optimization"
  echo "Review: specs/NNN-*/artifacts/optimization-report.md"
  echo ""
  echo "Auto-fix available? Check code-review-report.md"

  # Offer auto-fix if critical issues found
  if grep -q "Severity: CRITICAL" specs/NNN-*/artifacts/code-review-report.md; then
    read -p "Auto-fix critical issues? (y/n): " AUTOFIX
    if [ "$AUTOFIX" = "y" ]; then
      # Auto-fix loop (handled by /optimize internally)
      echo "Running auto-fix..."
      # /optimize already includes auto-fix loop
    else
      echo "Manual fixes required. Fix blockers, then run: /flow continue"
      exit 1
    fi
  fi
fi

echo " Optimization complete, ready for preview"
```

### MANUAL GATE 1: Preview (USER VALIDATION)
```bash
echo ""
echo ""
echo " MANUAL GATE: UI/UX PREVIEW"
echo ""
echo ""
echo "Next: /preview"
echo ""
echo "Action required:"
echo "1. Run local dev server"
echo "2. Test UI/UX manually"
echo "3. Verify against spec.md requirements"
echo "4. Check visuals/README.md patterns followed"
echo ""
read -p "Preview complete and validated? (y/n): " PREVIEW_OK

if [ "$PREVIEW_OK" != "y" ]; then
  echo "Continue with /preview, then run: /flow continue"
  exit 0
fi

echo " Preview validated, proceeding to ship"
```

### Phase 6: Ship to Staging (DEPLOYMENT)
```bash
# Create PR to staging with auto-merge
/phase-1-ship

# Wait for CI (handled by phase-1-ship internally)
echo " Waiting for CI checks and auto-merge..."

# After auto-merge, deployment to staging happens automatically
echo " Deployed to staging"
echo ""
echo "Staging URLs:"
echo "  - Marketing: ${STAGING_MARKETING_URL:-<staging marketing url>}"
echo "  - App: ${STAGING_APP_URL:-<staging app url>}"
echo "  - API: ${STAGING_API_URL:-<staging api url>}"
```

### MANUAL GATE 2: Validate Staging (USER VALIDATION)
```bash
echo ""
echo ""
echo " MANUAL GATE: STAGING VALIDATION"
echo ""
echo ""
echo "Next: /validate-staging"
echo ""
echo "Action required:"
echo "1. Test feature on staging environment"
echo "2. Verify E2E tests passed (GitHub Actions)"
echo "3. Check Lighthouse CI scores (Performance >90, A11y >95)"
echo "4. Confirm no regressions"
echo ""
read -p "Staging validated and approved for production? (y/n): " STAGING_OK

if [ "$STAGING_OK" != "y" ]; then
  echo "Continue with /validate-staging, then run: /flow continue"
  exit 0
fi

echo " Staging validated, ready for production"
```

### Phase 7: Ship to Production (DEPLOYMENT)
```bash
# Switch to staging branch (required for phase-2-ship)
git checkout staging
git pull origin staging

# Create PR to main with auto-merge
/phase-2-ship

# Wait for CI (handled by phase-2-ship internally)
echo " Waiting for CI checks and auto-merge..."

# After auto-merge, deployment to production happens automatically
echo " SHIPPED TO PRODUCTION "
echo ""
echo "Production URLs:"
echo "  - Marketing: ${PROD_MARKETING_URL:-<production marketing url>}"
echo "  - App: ${PROD_APP_URL:-<production app url>}"
echo "  - API: ${PROD_API_URL:-<production api url>}"
echo ""
echo "Release created with version tag"
echo "Roadmap updated (moved to 'Shipped')"
```

## PAUSE POINTS (Manual Intervention)

### Critical Issues After /analyze
```
 PAUSE: Critical issues found in analysis

Review: specs/NNN-*/artifacts/analysis-report.md

Fix critical issues:
- [Issue 1 description]
- [Issue 2 description]

Then continue: /flow continue
```

### Blockers After /optimize
```
  PAUSE: Optimization blockers found

Review: specs/NNN-*/artifacts/optimization-report.md

Auto-fix available? (y/n)

If yes: Auto-fix will run (max 3 iterations)
If no: Fix manually, then: /flow continue
```

### Preview Gate
```
 MANUAL GATE: UI/UX Preview

Run: /preview

Validate:
- [ ] UI matches spec requirements
- [ ] UX follows visuals/README.md patterns
- [ ] No visual regressions
- [ ] Responsive design works

Then continue: /flow continue
```

### Staging Validation Gate
```
 MANUAL GATE: Staging Validation

Run: /validate-staging

Check:
- [ ] Feature works on staging
- [ ] E2E tests passed (GitHub Actions)
- [ ] Lighthouse CI scores met (>90 Performance, >95 A11y)
- [ ] No production-breaking changes

Then continue: /flow continue
```

## CONTINUE MODE

Resume workflow after manual intervention:

```bash
/flow continue

# Detects last completed phase from NOTES.md
# Resumes from next phase
```

### Resume Logic
```bash
# Read last checkpoint from NOTES.md
LAST_PHASE=$(grep "Phase [0-9]: Completed" specs/NNN-*/NOTES.md | tail -n 1)

case "$LAST_PHASE" in
  *"Phase 0"*) NEXT="/plan" ;;
  *"Phase 1"*) NEXT="/tasks" ;;
  *"Phase 2"*) NEXT="/analyze" ;;
  *"Phase 3"*) NEXT="/implement" ;;
  *"Phase 4"*) NEXT="/optimize" ;;
  *"Phase 5"*) NEXT="/preview (manual gate)" ;;
  *"Phase 6"*) NEXT="/validate-staging (manual gate)" ;;
  *"Phase 7"*) NEXT="DONE - Feature shipped" ;;
  *) NEXT="Unknown - check NOTES.md" ;;
esac

echo "Resuming from: $NEXT"
```

## ERROR HANDLING

### Command Failure
```
 Error in Phase N: [command]

Error: [error message]

Options:
  A) Debug with /debug
  B) Skip phase (with warning)
  C) Abort workflow

Choose (A/B/C):
```

### Agent Timeout
```
  Agent timeout in Phase N

Agent: [agent-name]
Task: [task-description]

Options:
  A) Retry with extended timeout
  B) Manual implementation
  C) Skip task

Choose (A/B/C):
```

### CI Failure
```
 CI checks failed in Phase N: [phase-1-ship | phase-2-ship]

Failed checks: [list]

Auto-fix available: /checks pr [number]

Options:
  A) Run /checks to auto-fix
  B) Fix manually
  C) Abort

Choose (A/B/C):
```

## CONSTRAINTS

- **One feature at a time**: Workflow tracks single feature directory
- **Sequential phases**: Cannot skip phases (analysis before implementation)
- **Manual gates are mandatory**: Preview and staging validation required
- **Rollback capability**: Git commits at each phase for safety

## USAGE EXAMPLES

### Example 1: New Feature (Full Flow)
```bash
/flow "Student progress tracking dashboard"

# Output:
#  Phase 0: Spec created (specs/015-student-progress-dashboard)
#  Phase 0.5: Clarifications resolved
#  Phase 1: Plan generated (research + architecture)
#  Phase 2: Tasks created (28 tasks)
#  Phase 3: Analysis passed (0 critical issues)
#  Phase 4: Implementation complete (28/28 tasks)
#  Phase 5: Optimization passed (0 blockers)
#  MANUAL GATE: Run /preview
```

### Example 2: Resume After Preview
```bash
# After /preview completed
/flow continue

# Output:
# Resuming from: Phase 6 (Ship to Staging)
#  PR created: #123
#  Waiting for CI...
#  Auto-merged to staging
#  MANUAL GATE: Run /validate-staging
```

### Example 3: Resume After Fixes
```bash
# After fixing critical issues from /analyze
/flow continue

# Output:
# Resuming from: Phase 4 (Implementation)
#  Tasks completed: 28/28
#  Optimization complete
#  MANUAL GATE: Run /preview
```

## RETURN

### On Complete
```

 WORKFLOW COMPLETE


Feature: [feature-name]
Shipped:  Production

Timeline:
- Spec created: [date]
- Implementation: [N days]
- Staging: [date]
- Production: [date]

Metrics:
- Tasks completed: N/N
- Auto-fixes applied: N

Deployments:
- Staging: [staging marketing URL]
- Production: [production marketing URL]

Release: v[version] ([GitHub release URL])
Roadmap: Updated (moved to 'Shipped')
```

### On Pause (Manual Gate)
```

  WORKFLOW PAUSED


Phase: [phase-name] (Manual Gate)

Action required:
- [specific validation steps]

Next: /flow continue (after validation complete)
```

### On Error
```
 WORKFLOW ERROR

Phase: [phase-name]
Error: [error-description]

Options:
  A) Debug: /debug
  B) Fix: [specific fix instructions]
  C) Skip: /flow continue --skip-phase
  D) Abort: Exit workflow

Logs: specs/NNN-*/NOTES.md
```





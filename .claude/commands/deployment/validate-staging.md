---
description: Validate staging deployment before production through automated test review, rollback capability testing, guided manual validation, and optional gap capture for feedback loops
allowed-tools: [Read, Bash, Task, AskUserQuestion]
argument-hint: [--capture-gaps] (optional flag to launch gap capture wizard)
version: 11.0
updated: 2025-12-09
---

# /validate-staging — Staging Validation (Thin Wrapper)

> **v11.0 Architecture**: This command spawns the isolated `validate-phase-agent` via Task(). Validation checks run in isolated context with question batching for manual verification.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Interaction State**: !`cat specs/*/interaction-state.yaml 2>/dev/null | head -10 || echo "none"`
</context>

<objective>
Spawn isolated validate-phase-agent to validate staging deployment before production.

**Architecture (v11.0 - Phase Isolation):**
```
/validate-staging → Task(validate-phase-agent) → Q&A for manual checks → validation-report.md
```

**Agent responsibilities:**
- Review E2E test results from GitHub Actions
- Review Lighthouse CI performance results
- Test rollback capability
- Generate manual testing checklist from spec.md
- Return questions for user to manually verify in browser
- Create staging-validation-report.md

**Operating constraints:**
- **Manual Gate** — Agent returns questions for human validation
- **Staging Environment** — Validates staging URLs
- **Blocking Conditions** — E2E failures or manual failures block production

**Workflow position**: `implement → optimize → validate → ship → finalize`
</objective>

## Legacy Context (for agent reference)

<legacy_context>
Latest staging deployment: !`gh run list --workflow=deploy-staging.yml --branch=main --limit=1 --json databaseId,headSha,conclusion,status,createdAt,displayTitle 2>/dev/null || echo "[]"`

Vercel CLI installed: !`command -v vercel >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No"`

GitHub CLI authenticated: !`gh auth status >/dev/null 2>&1 && echo "✅ Yes" || echo "❌ No"`
</legacy_context>

<process>
1. **Detect feature from recent deployment**:
   - Get latest staging deployment from deploy-staging.yml workflow
   - Extract commit SHA, run ID, status, conclusion
   - Parse feature slug from commit message
   - Locate feature directory at specs/$SLUG
   - Verify spec.md exists

2. **Verify deployment status**:

   - Check if deployment is still running (in_progress/queued)
   - If running: Display workflow URL and exit with message to wait
   - Check if deployment failed
   - If failed: Extract failed jobs, display errors, exit with fix message
   - If succeeded: Continue to health checks

3. **Check staging health endpoints**:

   - Test marketing health: `curl https://staging.{domain}.com/health`
   - Test app health: `curl https://app.staging.{domain}.com/health`
   - Test API health: `curl https://api.staging.{domain}.com/api/v1/health/healthz`
   - Expect HTTP 200 for all endpoints
   - If any fail: Prompt user to continue or cancel

4. **Test rollback capability** (CRITICAL):

   - Load current and previous deployment IDs from deployment-metadata.json
   - If first deployment (no previous): Skip test (not a blocker)
   - If previous exists:
     a. Verify Vercel CLI installed
     b. Roll back to previous deployment: `vercel alias set $PREV_ID $STAGING_APP`
     c. Wait 15s for DNS propagation
     d. Verify rollback succeeded (check live URL headers)
     e. Roll forward to current deployment: `vercel alias set $CURRENT_ID $STAGING_APP`
     f. Wait 10s for DNS
     g. Update state.yaml quality gate
   - If rollback fails: BLOCK production deployment

5. **Review E2E test results**:

   - Find E2E job in workflow run
   - Extract conclusion (success/failure)
   - If passed: ✅ Continue
   - If failed:
     a. Extract failure details from logs
     b. Display failure summary
     c. BLOCK production deployment
   - If not run: ⚠️ Warning

6. **Review Lighthouse CI results**:

   - Find Lighthouse job in workflow run
   - Extract conclusion and performance scores
   - If passed: ✅ Continue
   - If failed:
     a. Extract performance warnings
     b. Display targets (Performance >85, Accessibility >95)
     c. Prompt user to continue or cancel (warning, not blocker)
   - If not run: ⚠️ Warning

7. **Generate manual testing checklist**:

   - Read spec.md
   - Extract Acceptance Criteria section (list items)
   - Extract User Flows section (list items)
   - Create checklist at /tmp/staging-validation-checklist-$SLUG.md with:
     - Staging URLs
     - Acceptance criteria checkboxes
     - User flow checkboxes
     - Edge case checks (error states, empty states, loading)
     - Visual validation (design, responsive, animations)
     - Accessibility quick checks
     - Cross-browser testing (optional)
     - Issues section for notes

8. **Guide interactive manual testing**:

   - Display checklist
   - Open checklist in editor (VS Code, vim, nano, or manual)
   - Prompt: "Have you completed manual testing? (y/N)"
   - If N: Save checklist, exit with message to resume later
   - If Y: Continue to issue check
   - Prompt: "Were any issues found? (y/N)"
   - If Y: Capture issue description, set MANUAL_STATUS=failed
   - If N: Set MANUAL_STATUS=passed

9. **Capture discovered gaps** (NEW in v3.0 - Feedback Loop Support):

   - Prompt: "Discover any missing features or endpoints during testing? (y/N)"
   - If Y OR --capture-gaps flag provided:
     a. Launch gap capture wizard (Invoke-GapCaptureWizard.ps1)
     b. For each gap:
     - Collect gap description, source, priority, subsystems
     - Run scope validation algorithm (Invoke-ScopeValidation.ps1)
     - Display validation result (IN_SCOPE ✅ | OUT_OF_SCOPE ❌ | AMBIGUOUS ⚠️)
       c. Generate gaps.md with all discoveries
       d. Generate scope-validation-report.md with validation evidence
       e. For in-scope gaps:
     - Generate supplemental tasks (New-SupplementalTasks.ps1)
     - Append to tasks.md with iteration marker
     - Update state.yaml:
       _ Set phase to "implement"
       _ Increment iteration.current
       _ Populate gaps section
       _ Add supplemental_tasks entry
       f. For out-of-scope gaps:
     - Recommend creating new epic/feature
     - Block from current workflow (prevent feature creep)
       g. Display gap summary:
     - Total gaps: N
     - In scope: N ✅ (will loop back to /implement)
     - Out of scope: N ❌ (deferred to new epic)
     - Ambiguous: N ⚠️ (user decision required)
   - If N: Continue to overall status determination

10. **Determine overall status**:

- If E2E failed OR manual failed: OVERALL_STATUS="❌ Blocked", READY_FOR_PROD=false
- If Lighthouse failed: OVERALL_STATUS="⚠️ Review Required", READY_FOR_PROD=warning
- Otherwise: OVERALL_STATUS="✅ Ready for Production", READY_FOR_PROD=true

11. **Generate validation report**:

    - Create staging-validation-report.md at specs/$SLUG/
    - Sections:
      - Deployment Info (workflow URL, commit, branch, timestamp)
      - Staging URLs (marketing, app, API)
      - Automated Tests (E2E status, Lighthouse status with URLs)
      - Manual Validation (status, tested by, issues found, checklist)
      - Deployment Readiness (overall status, blockers/warnings, next steps)
    - Copy checklist to feature directory for archival

12. **Update workflow state**:

    - Update manual_gates.staging_validation.status to "approved"
    - Update quality_gates.rollback_capability with test results
    - Commit changes to state.yaml

13. **Display final results**:
    - **If blocked**:
      - Display "❌ Staging Validation Failed"
      - List blockers (E2E failures, manual failures)
      - Show next steps: Fix issues, redeploy, re-validate
      - Exit with error code
    - **If warning**:
      - Display "⚠️ Staging Validation Complete (With Warnings)"
      - List warnings (Lighthouse performance)
      - Show next steps: Review warnings, fix or proceed
      - Mention /ship-prod as optional next step
    - **If ready**:
      - Display "✅ Staging Validation Passed"
      - Show validation summary (all checks ✅)
      - Show staging URLs tested
      - Show next step: /ship-prod

See `.claude/skills/staging-validation-phase/references/reference.md` for detailed feature detection logic, health check procedures, rollback testing steps, E2E/Lighthouse parsing, checklist generation templates, manual testing workflow, and validation report structure.
</process>

<verification>
Before completing, verify:
- Latest staging deployment detected successfully
- Deployment status verified (not running, not failed)
- Health checks completed for all endpoints
- Rollback capability tested (or skipped if first deployment)
- E2E test results reviewed
- Lighthouse CI results reviewed
- Manual testing checklist generated from spec.md
- User completed manual testing
- Overall status determined correctly
- Validation report created at specs/$SLUG/staging-validation-report.md
- Workflow state updated with validation status
- Final results displayed with next steps
</verification>

<success_criteria>
**Feature detection:**

- Latest staging deployment found via gh run list
- Feature slug extracted from commit message
- Feature directory exists at specs/$SLUG
- spec.md exists in feature directory

**Deployment verification:**

- Deployment status is "completed" (not in_progress/queued)
- Deployment conclusion is "success" (not failure)
- All jobs succeeded (deploy-marketing, deploy-app, deploy-api)
- Smoke tests passed (if present)

**Health checks:**

- Marketing endpoint returns HTTP 200
- App endpoint returns HTTP 200
- API endpoint returns HTTP 200
- Or user confirms to continue with unhealthy endpoints

**Rollback testing:**

- If first deployment: Skipped (not a blocker)
- If previous deployment exists:
  - Vercel CLI available
  - Rollback command succeeds
  - Previous deployment goes live (verified via headers)
  - Roll-forward command succeeds
  - Quality gate updated in state.yaml

**Automated tests:**

- E2E test results extracted from workflow
- E2E passed: ✅ Continue
- E2E failed: 🚫 BLOCK production
- Lighthouse results extracted from workflow
- Lighthouse passed: ✅ Continue
- Lighthouse failed: ⚠️ Warning (user can continue)

**Manual testing:**

- Checklist generated with acceptance criteria from spec.md
- Checklist includes user flows, edge cases, visual validation, accessibility
- User completes testing
- Manual status captured (passed/failed)
- Issues documented if found

**Validation report:**

- Created at specs/$SLUG/staging-validation-report.md
- Contains deployment info, staging URLs, test results
- Contains manual validation results and checklist
- Contains overall status and next steps
- Checklist copied to feature directory

**Overall status:**

```
Blocked (READY_FOR_PROD=false):
  - E2E tests failed OR manual validation failed

Review Required (READY_FOR_PROD=warning):
  - Lighthouse performance below targets

Ready for Production (READY_FOR_PROD=true):
  - All checks passed
```

**Final output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VALIDATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## {Status with emoji}

**Feature**: {slug}
**Status**: {Ready/Blocked/Review Required}

### Validation Summary
- {Deployment status}
- {Health checks}
- {E2E tests}
- {Lighthouse}
- {Manual validation}

### Staging URLs Tested
- Marketing: {url}
- App: {url}
- API: {url}

### Report
Validation report: {path}

### Next Steps
{Context-aware next steps based on status}

---
**Workflow**: `... → ship-staging → validate-staging {status} → ship-prod`
```

</success_criteria>

<standards>
**Industry Standards:**
- **Lighthouse Performance Targets**: [Web Vitals](https://web.dev/vitals/) - Performance >85, Accessibility >95, LCP <2.5s, FCP <1.5s, TTI <3s
- **Health Check Format**: [RFC Health Check](https://inadarei.github.io/rfc-healthcheck/) for API health endpoints
- **Rollback Best Practices**: [Site Reliability Engineering](https://sre.google/sre-book/table-of-contents/) - Test rollback before production

**Workflow Standards:**

- Manual gate pauses workflow for human validation
- Automated tests validate functionality
- Manual tests validate UX quality
- Rollback testing ensures incident recovery capability
- E2E failures are blocking (must fix before production)
- Lighthouse failures are warnings (can proceed with caution)
- Staging environment uses production builds with separate infrastructure
  </standards>

<notes>
**Command location**: `.claude/commands/deployment/validate-staging.md`

**Reference documentation**: Feature detection logic, deployment status verification, health check procedures (3 endpoints), rollback capability testing (4 steps), E2E/Lighthouse result parsing, manual testing checklist generation templates, interactive validation workflow, validation report structure, and production readiness decision matrix are in `.claude/skills/staging-validation-phase/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Workflow position**:

```
/feature → /clarify → /plan → /tasks → /validate → /implement →
/optimize → /preview → /ship-staging → **/validate-staging** → /ship-prod
```

**Manual gate behavior**:

- Pauses workflow for human input
- User completes manual testing checklist
- User reports results (passed/failed)
- Gate approves or blocks based on results

**Blocking conditions** (prevent production):

- E2E tests failed
- Manual validation failed
- Deployment failed
- Rollback capability test failed

**Warning conditions** (can proceed):

- Lighthouse performance below targets
- E2E tests not run
- Lighthouse not run

**Rollback testing importance**:
Rollback capability is tested in staging BEFORE production deployment. This ensures that if a production incident occurs, the team can quickly revert to the previous stable version. Without this test, production rollback may fail when needed most.

**Manual validation philosophy**:
Automated tests validate functionality, but manual testing ensures UX quality. This gate prevents shipping features that work technically but feel wrong to users.

**Staging environment characteristics**:

- Uses production builds (optimized bundles)
- Separate databases and infrastructure
- Production-like environment
- Safe to test breaking changes
- Validates build performance without affecting real users

**Iteration expectation**:
Normal to iterate 2-3 times on staging validation. The workflow supports:

1. Find issues in staging
2. Fix issues in code
3. Redeploy via /ship-staging
4. Re-validate via /validate-staging
5. Repeat until all checks pass

**Related commands:**

- `/ship-staging` - Deploy to staging environment (run before this command)
- `/ship-prod` - Deploy to production (run after validation passes)
- `/preview` - Local testing (recommended before staging)
- `/optimize` - Quality gates (recommended before shipping)

**Integration with /ship-prod:**
The `/ship-prod` command should verify staging validation passed:

```bash
VALIDATION_REPORT="$FEATURE_DIR/staging-validation-report.md"

if [ ! -f "$VALIDATION_REPORT" ]; then
  echo "❌ No staging validation report found"
  echo "Run /validate-staging first"
  exit 1
fi

if grep -q "❌ Blocked" "$VALIDATION_REPORT"; then
  echo "❌ Staging validation failed"
  echo "Fix blockers before shipping to production"
  exit 1
fi
```

**Branch model alignment**:

- Main branch → Deployed to staging environment
- Staging environment → Promoted to production environment
- NO staging branch (trunk-based development)
- Command can run from any branch, but validates main deployment

**Error handling:**

- **No deployment**: "No staging deployments found. Did you run /ship-staging?"
- **Deployment running**: "Deployment still running. Wait for completion."
- **Deployment failed**: "Deployment failed. Fix failures before validating."
- **Feature not found**: "Feature directory not found. Available specs: ..."
- **Vercel CLI missing**: "Cannot verify rollback capability. Install Vercel CLI."
- **Rollback failed**: "BLOCKER: Rollback capability broken. Fix before production."

**Performance targets:**

- **Performance**: ≥85
- **Accessibility**: ≥95 (WCAG 2.1 AA)
- **First Contentful Paint (FCP)**: <1500ms
- **Time to Interactive (TTI)**: <3000ms
- **Largest Contentful Paint (LCP)**: <2500ms

**Checklist generation:**

- Extracts acceptance criteria from spec.md
- Extracts user flows from spec.md
- Adds standard edge case checks
- Adds visual validation checks
- Adds accessibility quick checks
- Adds cross-browser testing (optional)
- Creates interactive markdown checklist

**Best practices:**

- Always validate after staging deployment
- Complete all checklist items (don't skip manual testing)
- Document issues thoroughly for debugging
- Test rollback capability (critical for incident recovery)
- Review automated test failures (don't ignore warnings)
- Iterate 2-3 times if needed (normal to find issues)
- Save completed checklist for records
  </notes>

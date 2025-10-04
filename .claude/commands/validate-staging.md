# Validate Staging: Manual Validation Gate

**Command**: `/validate-staging`

**Purpose**: Manual validation of staging deployment before production. Checks E2E tests, Lighthouse metrics, and guides manual testing on staging URLs.

**When to use**: After `/phase-1-ship` completes and PR is merged to staging branch. This is the quality gate before `/phase-2-ship` to production.

**Workflow position**: `spec-flow  clarify  plan  tasks  analyze  implement  optimize  debug  preview  phase-1-ship  **validate-staging**  phase-2-ship`

---

## MENTAL MODEL

You are a **staging validation orchestrator**. Your job:

1. **Detect feature** from staging branch or recent merge
2. **Check deployment status** (marketing, app, API on staging)
3. **Review automated tests** (E2E, Lighthouse CI from GitHub Actions)
4. **Guide manual testing** (display checklist from spec.md)
5. **Capture validation results** (create staging-validation-report.md)
6. **Gate production** (block /phase-2-ship if validation fails)

**Philosophy**: Staging is the final checkpoint before production. This command combines automated test results with manual validation to ensure features work correctly in a production-like environment.

**Manual gates**: E2E tests and Lighthouse are automated, but manual testing is required for:
- Visual validation (design matches mockups)
- User flows (UX feels right)
- Edge cases (error states, empty states)
- Cross-browser compatibility (if needed)

---

## INPUTS

**Required context:**
- Staging branch exists with recent merge from feature branch
- Staging deployment completed successfully
- E2E tests ran in GitHub Actions
- Lighthouse CI ran in GitHub Actions

**Auto-detected:**
- Feature name from staging commit history
- Feature number (NNN) from specs/ directory
- Latest staging deployment URLs
- GitHub Actions workflow run IDs

---

## EXECUTION PHASES

### Phase V.1: Detect Feature and Deployment

**Find latest staging merge:**
```bash
git log staging --oneline -10 --grep="Production:\|Staging:"
```
- Look for merge commits from feature branches
- Extract feature name from commit message
- Identify feature number (NNN)

**Detect feature directory:**
```bash
ls specs/ | grep "^[0-9]\{3\}-"
```
- Match feature number to directory
- Verify spec.md exists
- If not found: Error with instructions to run from correct branch

**Check staging deployment status:**

Use GitHub MCP to get latest deployment:
```bash
gh run list --workflow=deploy-staging.yml --limit 1 --json conclusion,status,databaseId,createdAt
```

**Expected deployment checks:**
-  deploy-marketing (Vercel)
-  deploy-app (Vercel)
-  deploy-api (Railway)
-  smoke-tests
-  e2e-staging (optional, may be pending)
-  lighthouse-staging (optional, may be pending)

**If deployment failed:**
- Report failed job names
- Link to workflow run
- Suggest: "Fix failures before validating staging"
- Exit with error

### Phase V.2: Review Automated Test Results

**Check E2E test results:**

Get latest e2e-staging job from deploy-staging.yml:
```bash
gh run view [RUN_ID] --json jobs
```

Filter for `e2e-staging` job:
- Extract conclusion (success/failure)
- Get artifact URL (playwright-report-staging)
- Display summary

**E2E summary template:**
```markdown
## E2E Tests

**Status**: [ Passed /  Failed]
**Workflow**: https://github.com/[org]/[repo]/actions/runs/[run-id]

**Tests executed:**
- Multi-domain auth flow
- [Other E2E tests from spec.md]

[If failed]:
**Failures:**
- [Test name]: [Error summary]

**Report**: [Link to Playwright report artifact]
```

**Check Lighthouse CI results:**

Get lighthouse-staging job from same workflow run:
```bash
gh run view [RUN_ID] --json jobs
```

Filter for `lighthouse-staging` job:
- Extract conclusion
- Get artifact URLs (lighthouse-reports-staging)
- Parse Lighthouse scores if possible

**Lighthouse summary template:**
```markdown
## Lighthouse CI

**Status**: [ Passed /  Failed]
**Workflow**: https://github.com/[org]/[repo]/actions/runs/[run-id]

**Marketing** ([staging marketing URL]):
- Performance: [score]/100 (target: >90)
- Accessibility: [score]/100 (target: >95)
- FCP: [value]ms (target: <1500ms)
- TTI: [value]ms (target: <3000ms)
- LCP: [value]ms (target: <2500ms)

**App** ([staging app URL]):
- Performance: [score]/100 (target: >90)
- Accessibility: [score]/100 (target: >95)
- FCP: [value]ms (target: <1500ms)
- TTI: [value]ms (target: <3000ms)
- LCP: [value]ms (target: <2500ms)

**Report**: [Link to Lighthouse artifacts]
```

**If automated tests failed:**
- Display which tests failed
- Block validation (cannot proceed to production)
- Suggest fixes or reruns

### Phase V.3: Manual Testing Checklist

**Load testing checklist from spec.md:**

Read `specs/NNN-feature/spec.md` and extract:
- Acceptance criteria section
- User flows section
- Edge cases section

**Generate manual testing checklist:**

Display to user with staging URLs:

```markdown
## Manual Validation Checklist

**Staging URLs:**
- Marketing: [staging marketing URL]
- App: [staging app URL]
- API: [staging API docs URL]

**Test the following on staging:**

### Acceptance Criteria
- [ ] [Criterion 1 from spec.md]
- [ ] [Criterion 2 from spec.md]
- [ ] [Criterion 3 from spec.md]

### User Flows
- [ ] [Flow 1 from spec.md]
- [ ] [Flow 2 from spec.md]

### Edge Cases
- [ ] Error states display correctly
- [ ] Empty states display correctly
- [ ] Loading states display correctly

### Visual Validation
- [ ] Design matches mockups/visuals
- [ ] Responsive on mobile (if applicable)
- [ ] Animations smooth (if applicable)
- [ ] Dark mode works (if applicable)

### Cross-Browser (optional)
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari (if accessible)

---

**Instructions:**
1. Open staging URLs above
2. Test each item in the checklist
3. Note any issues found
4. Return to this command when done
```

**Prompt user:**
```
Have you completed manual testing on staging? (yes/no)
```

**If user says "no":**
- Save partial validation report
- Exit with message: "Complete manual testing, then run `/validate-staging` again"

**If user says "yes":**
- Prompt: "Were there any issues found? (yes/no)"

**If issues found:**
- Prompt: "Describe the issues:"
- Capture user input
- Mark validation as failed
- Create staging-validation-report.md with issues
- Suggest: "Fix issues, redeploy staging, then run `/validate-staging` again"
- Exit with error

**If no issues:**
- Continue to Phase V.4

### Phase V.4: Create Validation Report

**Generate staging-validation-report.md** in `specs/NNN-feature/artifacts/`:

**Template:**
```markdown
# Staging Validation Report

**Date**: [YYYY-MM-DD HH:MM]
**Feature**: [NNN-feature-name]
**Staging Deployment**: [YYYY-MM-DD HH:MM]

## Deployment Status

**PR**: #[NUMBER] (merged to staging)
**Commit SHA**: [SHA]
**Workflow**: https://github.com/[org]/[repo]/actions/runs/[run-id]

## Staging URLs

- **Marketing**: [staging marketing URL]
- **App**: [staging app URL]
- **API**: [staging API URL]

## Automated Tests

### E2E Tests
**Status**: [ Passed /  Failed]
- Multi-domain auth flow: [/]
- [Other tests]: [/]

**Report**: [Playwright report artifact link]

### Lighthouse CI
**Status**: [ Passed /  Failed]

**Marketing**:
- Performance: [score]/100 [/]
- Accessibility: [score]/100 [/]
- FCP: [value]ms [/]
- TTI: [value]ms [/]
- LCP: [value]ms [/]

**App**:
- Performance: [score]/100 [/]
- Accessibility: [score]/100 [/]
- FCP: [value]ms [/]
- TTI: [value]ms [/]
- LCP: [value]ms [/]

**Report**: [Lighthouse artifacts link]

## Manual Validation

**Status**: [ Passed /  Failed]
**Tested by**: [User]
**Tested on**: [YYYY-MM-DD HH:MM]

### Acceptance Criteria
[Checklist from spec.md with results]
- [/] [Criterion 1]
- [/] [Criterion 2]

### User Flows
[Checklist from spec.md with results]
- [/] [Flow 1]
- [/] [Flow 2]

### Visual Validation
- [/] Design matches mockups
- [/] Responsive on mobile
- [/] Animations smooth

### Issues Found
[If any issues]:
- [Issue 1 description]
- [Issue 2 description]

[If no issues]:
None - all checks passed 

## Deployment Readiness

**Status**: [ Ready for Production /  Blocked]

[If ready]:
All staging checks passed:
-  E2E tests passing
-  Lighthouse performance > 90
-  Manual validation complete
-  No critical errors in logs

**Next step**: Run `/phase-2-ship` to deploy to production

[If blocked]:
**Blockers:**
- [ Blocker 1]
- [ Blocker 2]

**Action required**: Fix blockers, redeploy staging, validate again

---
*Generated by `/validate-staging` command*
```

**Write report:**
```bash
cat > specs/[NNN-feature]/artifacts/staging-validation-report.md
```

### Phase V.5: Final Output

**If validation passed:**
```markdown
##  Staging Validation Complete

**Feature**: [NNN-feature-name]
**Status**: Ready for Production

### Validation Results

-  E2E tests passing
-  Lighthouse performance > 90
-  Manual validation complete
-  No critical errors

### Staging URLs Tested

- Marketing: [staging marketing URL]
- App: [staging app URL]
- API: [staging API URL]

### Report

Validation report: specs/[NNN-feature]/artifacts/staging-validation-report.md

### Next Steps

1. Checkout staging branch: `git checkout staging`
2. Run `/phase-2-ship` to deploy to production

---
**Workflow**: `...  phase-1-ship  validate-staging   phase-2-ship (next)`
```

**If validation failed:**
```markdown
##  Staging Validation Failed

**Feature**: [NNN-feature-name]
**Status**: Blocked

### Issues Found

[List issues from report]

### Next Steps

1. Fix issues identified above
2. Redeploy to staging (may need to update code and re-run `/phase-1-ship`)
3. Run `/validate-staging` again

### Report

Validation report: specs/[NNN-feature]/artifacts/staging-validation-report.md

---
**Workflow**: `...  phase-1-ship  validate-staging  (fix issues, retry)`
```

---

## ERROR HANDLING

**If not on staging branch:**
```markdown
 Error: Must run from staging branch

Current branch: [branch-name]

Please run:
```bash
git checkout staging
git pull origin staging
/validate-staging
```
```

**If no recent staging deployment:**
```markdown
 Error: No staging deployment found

Run `/phase-1-ship` first to deploy feature to staging.

Expected workflow:
1. Feature branch  run `/phase-1-ship`
2. PR merged to staging  deployment triggered
3. Run `/validate-staging` (you are here)
```

**If deployment still running:**
```markdown
 Warning: Staging deployment in progress

**Current status:**
- deploy-marketing: [status]
- deploy-app: [status]
- deploy-api: [status]
- smoke-tests: [status]
- e2e-staging: [status]
- lighthouse-staging: [status]

Wait for deployment to complete, then run `/validate-staging` again.

**Workflow**: https://github.com/[org]/[repo]/actions/runs/[run-id]
```

---

## NOTES

**Manual validation importance**: Automated tests validate functionality, but manual testing ensures the UX feels right. This gate prevents shipping features that work technically but feel wrong to users.

**Staging environment**: Staging uses production builds (optimized bundles) but separate databases and infrastructure. This validates production build performance without affecting real users.

**Blocking production**: If validation fails, `/phase-2-ship` will refuse to run until a new staging-validation-report.md shows all checks passed.

**Iteration**: It's normal to iterate 2-3 times on staging validation. Fix issues, redeploy via `/phase-1-ship`, validate again.

**Next command**: `/phase-2-ship` (only if validation passed)




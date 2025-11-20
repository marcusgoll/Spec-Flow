---
name: ship-prod
description: Automated staging→production promotion via git tag creation, triggering GitHub Actions deployment, and creating GitHub release
internal: true
argument-hint: [--version major|minor|patch]
allowed-tools: [Bash(python .spec-flow/*), Bash(git tag:*), Bash(git push:*), Bash(git log:*), Bash(git status:*), Read, Grep]
---

> **⚠️ INTERNAL COMMAND**: This command is automatically called by `/ship` after automated staging validation passes.
> Most users should use `/ship` instead of calling this directly.

# /ship-prod — Production Deployment (Tagged Promotion)

<context>
**Arguments**: $ARGUMENTS

**Current Feature Directory**: !`find specs/ -maxdepth 1 -type d -name "[0-9]*" | sort -n | tail -1 2>$null || echo "none"`

**Workflow State**: @specs/*/workflow-state.yaml

**Staging Validation Report**: @specs/*/staging-validation-report.md

**Current Version in CHANGELOG**: !`grep "^## \[" CHANGELOG.md | head -1 | grep -oP '\[\K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown"`

**Git Status**: !`git status --short 2>$null || echo "clean"`

**Recent Git Tags**: !`git tag -l "v*" | sort -V | tail -5 || echo "none"`

**GitHub CLI Status**: !`gh auth status 2>$null | head -1 || echo "not authenticated"`

**Production Workflow**: !`test -f .github/workflows/deploy-production.yml && echo "exists" || echo "missing"`

**Staging Validation Status**: !`grep -E "✅|❌" specs/*/staging-validation-report.md 2>$null | head -5 || echo "unknown"`
</context>

<objective>
Automated staging→production promotion via git tag creation for projects using the `staging-prod` deployment model.

**Purpose**: Create semantic version tag, push to trigger GitHub Actions deployment, monitor completion, and create GitHub release.

**Tagged Promotion Flow**:
1. Automated staging validation completes (`/validate-staging --auto`)
2. `/ship-prod` triggered automatically (or with `--version` override)
3. Extract version from CHANGELOG.md, default to patch bump
4. Create annotated git tag (e.g., `v1.2.3`)
5. Push tag to origin
6. GitHub Actions workflow triggers on tag push
7. Workflow deploys to production, runs smoke tests
8. Workflow creates GitHub Release with changelog excerpt
9. Poll workflow status until complete
10. Update workflow-state.yaml with version/tag/URLs

**Philosophy**: Fully automated from staging environment → production environment. Zero manual gates - defaults to patch versioning (most common for bug fixes and minor improvements). Once tag is pushed, GitHub Actions handles deployment, testing, and release creation.

**Branch Model**: No staging branch exists. Main branch is deployed to staging environment. Production deployment is triggered by tag push (not branch merge).

**Arguments**:
- (empty): Default to patch version bump (1.2.3 → 1.2.4)
- `--version major`: Major version bump for breaking changes (1.2.3 → 2.0.0)
- `--version minor`: Minor version bump for new features (1.2.3 → 1.3.0)
- `--version patch`: Explicit patch bump (same as default)

**Prerequisites**:
- Staging validation passed (all checks in staging-validation-report.md)
- CHANGELOG.md contains unreleased version entry
- GitHub Actions production workflow exists (`.github/workflows/deploy-production.yml`)
- Production workflow configured with tag trigger: `on: push: tags: - 'v*.*.*'`

**Timing**: 5-10 minutes (depends on deployment platform build time)
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent production deployment failures.

1. **Never invent production URLs**
   - Extract actual URLs from workflow-state.yaml or deployment logs
   - If URL unknown, say: "Production URL not captured (check deployment platform)"
   - Don't guess at domain names or subdomains

2. **Quote workflow-state.yaml exactly for version info**
   - Don't paraphrase deployment metadata
   - If field missing, report: "Version not recorded in workflow-state.yaml"
   - Read actual file content after deployment

3. **Cite GitHub Actions logs for deployment status**
   - Link to actual workflow run (extract from script output)
   - Don't fabricate deployment IDs or timestamps
   - Verify actual workflow conclusion (success/failure)

4. **Never claim deployment success without verifying exit code**
   - Script exit 0 = success
   - Script exit 1 = failure (even if tag was created)
   - Check actual bash exit code before reporting success

5. **Don't invent version numbers**
   - Extract version from CHANGELOG.md or script output
   - If version selection fails, report error (don't make up version)
   - Never guess at next version number

**Why this matters**: False success claims for production deployments cause confusion and potential outages. Accurate reporting of actual deployment status prevents production incidents.

---

<process>

### Step 1: Validate Staging Readiness

**Verify staging validation passed**:

Check that staging-validation-report.md exists and all checks passed:
```bash
test -f "$FEATURE_DIR/staging-validation-report.md"
```

If file doesn't exist:
```
❌ Staging validation not complete

Cannot proceed to production without staging validation.
Run: /ship to complete the full deployment workflow
```
EXIT immediately

**Verify all validation checks passed**:
```bash
grep -E "❌" "$FEATURE_DIR/staging-validation-report.md"
```

If any ❌ found:
```
❌ Staging validation failed

Review failures in: $FEATURE_DIR/staging-validation-report.md
Fix issues and re-deploy to staging before production
```
EXIT immediately

### Step 2: Execute Production Deployment Script

**Run centralized spec-cli tool with arguments**:

```bash
python .spec-flow/scripts/spec-cli.py ship-prod "$FEATURE_DIR" $ARGUMENTS
```

**What the script does**:

1. **Version selection** (automatic with override):
   - Extracts current version from CHANGELOG.md
   - Defaults to patch bump: 1.2.3 → 1.2.4 (most common - bug fixes, minor improvements)
   - Respects `--version major|minor|patch` flag if provided in $ARGUMENTS
   - Validates semantic versioning format (vMAJOR.MINOR.PATCH)
   - No interactive prompt - fully automated

2. **Create git tag**:
   - Checks if tag already exists (fail if duplicate)
   - Ensures clean working directory
   - Creates annotated tag: `git tag -a v1.2.3 -m "Release v1.2.3"`

3. **Push tag to trigger deployment**:
   - Pushes tag to origin: `git push origin v1.2.3`
   - GitHub Actions workflow (`.github/workflows/deploy-production.yml`) triggers on tag push
   - Tag push is atomic - deployment starts immediately

4. **Monitor deployment** (if gh CLI available):
   - Finds workflow run ID for the tag
   - Polls GitHub Actions status every 30 seconds
   - Streams deployment logs to console
   - Waits for deployment completion
   - Exits with error if deployment fails

5. **Update workflow state**:
   - Writes version, tag, timestamp to workflow-state.yaml
   - Records GitHub release URL
   - Updates `deployment.production` section

**Script output format**:
```
Version: v1.2.3
Tag Created: v1.2.3
GitHub Release: https://github.com/user/repo/releases/tag/v1.2.3
Workflow Run: https://github.com/user/repo/actions/runs/12345
Deployment Time: 2025-11-20T10:30:00Z
```

### Step 3: Verify Deployment Success

**Check script exit code**:
- Exit 0: Deployment succeeded
- Exit 1: Deployment failed

**If script exited with code 1**:

Display failure message:
```
❌ Production Deployment Failed

Error: <error-message-from-script-output>

GitHub Actions logs: <workflow-run-url-from-script>

Common failures:
  1. Build errors (npm run build failed)
  2. Test failures (production smoke tests)
  3. Deployment platform errors (Vercel/Railway/Netlify)
  4. Missing secrets in GitHub

After fixing, retry production deployment:
  1. Delete tag locally: git tag -d v<version>
  2. Delete tag remotely: git push origin :refs/tags/v<version>
  3. Fix the issue (build errors, secrets, etc.)
  4. Run /ship-prod again
```

Update workflow phase to failed and EXIT

**If script exited with code 0**:

Proceed to Step 4

### Step 4: Read Deployment Metadata

**Load workflow-state.yaml**:
```bash
Read(specs/$FEATURE_DIR/workflow-state.yaml)
```

**Extract production deployment info** from workflow-state.yaml:
- `deployment.production.version` - Deployed version (e.g., "1.2.3")
- `deployment.production.tag` - Git tag (e.g., "v1.2.3")
- `deployment.production.tag_created_at` - Tag creation timestamp
- `deployment.production.deployed_at` - Deployment completion timestamp
- `deployment.production.github_release_url` - GitHub release URL
- `deployment.production.production_urls` - Array of production URLs (if available)

**If any required field is missing**:

Report exactly which field is missing:
```
⚠️  Deployment metadata incomplete

Missing field: deployment.production.<field-name>

Deployment may have succeeded, but metadata not recorded.
Check GitHub Actions logs and deployment platform manually.
```

### Step 5: Present Deployment Summary

**Format deployment summary** using actual metadata from workflow-state.yaml:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Production Deployment Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {feature-slug}
Version: v{version}
Tag: {tag}

{If production_urls available}
Production URLs:
  - {url-1}
  - {url-2}
  ...

{If production_urls not available}
Production URL: See deployment platform dashboard

GitHub Release: {github_release_url}
Deployed At: {deployed_at}

Next: Full documentation finalization will run automatically via /finalize
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**All values must come from actual workflow-state.yaml content**. Do not invent URLs, versions, or timestamps.

</process>

<success_criteria>
**Production deployment successfully completed when:**

1. **Staging validation verified**:
   - staging-validation-report.md exists
   - All validation checks passed (no ❌ in report)

2. **Deployment script executed successfully**:
   - `python .spec-flow/scripts/spec-cli.py ship-prod` exited with code 0
   - No error messages in script output

3. **Git tag created and pushed**:
   - Tag exists in `git tag -l` output
   - Tag pushed to remote (visible in GitHub repository)
   - Tag follows semantic versioning: v{MAJOR}.{MINOR}.{PATCH}

4. **GitHub Actions workflow completed**:
   - Workflow triggered by tag push
   - Workflow run completed successfully (not failed or cancelled)
   - Workflow run URL accessible

5. **Deployment metadata recorded**:
   - workflow-state.yaml updated with production deployment info
   - Version, tag, timestamps recorded
   - GitHub release URL recorded

6. **GitHub release created**:
   - Release exists at recorded URL
   - Release contains changelog excerpt
   - Release tagged with correct version

7. **User informed**:
   - Deployment summary displayed with actual metadata
   - Production URLs displayed (or warning if unavailable)
   - GitHub release URL displayed
   - Next steps indicated (/finalize)
</success_criteria>

<verification>
**Before marking ship-prod complete, verify:**

1. **Check git tag exists locally and remotely**:
   ```bash
   git tag -l "v*" | grep "v{version}"
   # Should show the new tag

   git ls-remote --tags origin | grep "v{version}"
   # Should show tag exists on remote
   ```

2. **Verify workflow-state.yaml updated**:
   ```bash
   yq eval '.deployment.production.version' "$FEATURE_DIR/workflow-state.yaml"
   # Should show actual version number (e.g., "1.2.3")

   yq eval '.deployment.production.tag' "$FEATURE_DIR/workflow-state.yaml"
   # Should show tag with v prefix (e.g., "v1.2.3")

   yq eval '.deployment.production.github_release_url' "$FEATURE_DIR/workflow-state.yaml"
   # Should show actual GitHub release URL
   ```

3. **Verify GitHub release exists**:
   ```bash
   gh release view "v{version}"
   # Should display release details without error
   ```

4. **Verify deployment script success**:
   - Script exit code was 0 (not 1)
   - No error messages in script output
   - Deployment completion message displayed

5. **Verify no metadata fabrication**:
   - Production URLs from actual workflow-state.yaml (not guessed)
   - Version number from actual CHANGELOG.md or script output (not invented)
   - GitHub release URL from actual workflow output (not constructed)
   - Timestamps from actual workflow-state.yaml (not current time)

**Never claim deployment complete without:**
- Actual script exit code 0
- Actual git tag created and pushed
- Actual GitHub release URL from workflow-state.yaml
- Actual version number from CHANGELOG.md or script
</verification>

<output>
**Files created/modified by this command:**

**Git artifacts**:
- Git tag created: `v{version}` (annotated tag with release message)
- Tag pushed to remote: `origin/v{version}`

**GitHub artifacts**:
- GitHub Release created at: `https://github.com/{owner}/{repo}/releases/tag/v{version}`
- Workflow run triggered: `https://github.com/{owner}/{repo}/actions/runs/{run-id}`

**Workflow state**:
- `specs/{feature-slug}/workflow-state.yaml` - Updated with:
  - `deployment.production.version` = "{version}"
  - `deployment.production.tag` = "v{version}"
  - `deployment.production.tag_created_at` = ISO 8601 timestamp
  - `deployment.production.deployed_at` = ISO 8601 timestamp
  - `deployment.production.github_release_url` = Release URL
  - `deployment.production.workflow_run_id` = GitHub Actions run ID
  - `deployment.production.production_urls` = Array of URLs (if available)

**Console output**:
- Version selection (patch/minor/major)
- Tag creation confirmation
- Tag push confirmation
- Deployment monitoring progress (from GitHub Actions)
- Deployment completion status
- GitHub release URL
- Production deployment summary with metadata
</output>

---

## Notes

**Rollback Procedure**:

If production deployment has issues, redeploy previous version:

```bash
# Find previous version tag
git tag -l "v*" | sort -V | tail -5

# Redeploy previous version (triggers new GitHub Actions run)
git push origin v1.2.2

# Or delete bad version and recreate
git tag -d v1.2.3
git push origin :refs/tags/v1.2.3
# Fix CHANGELOG, then run /ship-prod again
```

**Required GitHub Secrets** (configured in repository settings):

- Platform-specific secrets:
  - Vercel: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
  - Railway: `RAILWAY_TOKEN`, `RAILWAY_SERVICE`
  - Netlify: `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`
- Testing: `PRODUCTION_URL` (for smoke tests)

**Workflow File**: `.github/workflows/deploy-production.yml`

Must include tag trigger:
```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

Workflow should:
1. Build production artifacts
2. Deploy to platform (Vercel/Railway/Netlify)
3. Run smoke tests against production URL
4. Create GitHub Release with changelog excerpt

**Tagged Promotion Benefits**:
- Clear version history in git tags (audit trail)
- Easy rollback (redeploy previous tag)
- GitHub releases auto-created with changelogs
- Auditability (git log shows all production releases)
- No manual workflow dispatch API calls needed

---
description: Automated staging→production promotion with versioning and tagged deployment
version: 3.0
updated: 2025-11-17
internal: true
---

> **⚠️  INTERNAL COMMAND**: This command is called automatically by `/ship`.
> Most users should use `/ship` instead of calling this directly.

# /ship-prod — Production Deployment (Tagged Promotion)

**Purpose**: Automated staging→production promotion via git tag creation. Creates semantic version tag, pushes to trigger GitHub Actions deployment, waits for completion, creates GitHub release.

**When to use**: After `/validate-staging` passes with all checks green. This is the final step to ship features to production.

**Workflow position**: `spec-flow → clarify → plan → tasks → analyze → implement → optimize → preview → ship-staging → validate-staging → **ship-prod**`

---

<context>
## MENTAL MODEL

**Tagged Promotion Flow**:
1. User validates staging manually (`/validate-staging`)
2. LLM triggers `/ship-prod`
3. Script extracts version from CHANGELOG.md
4. User chooses version bump (patch/minor/major)
5. Script creates annotated git tag (v1.2.3)
6. Script pushes tag to origin
7. GitHub Actions workflow triggers on tag push
8. Workflow deploys to production, runs smoke tests
9. Workflow creates GitHub Release with changelog excerpt
10. Script polls workflow status until complete
11. Script updates workflow-state.yaml with version/tag/URLs

**Philosophy**: Fully automated from staging environment → production environment. The only manual decision is version selection. Once tag is pushed, GitHub Actions handles deployment, testing, and release creation.

**Token efficiency**: Bash script handles version selection, tag creation, and GitHub Actions polling. LLM only processes results.

**Branch model**: No staging branch exists. Main branch is deployed to staging environment. Production deployment is triggered by tag push (not branch).

</context>

---

<instructions>
## USER INPUT

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execute Production Deployment Workflow

Run the centralized spec-cli tool:

```bash
python .spec-flow/scripts/spec-cli.py ship-prod "$FEATURE_DIR"
```

**What the script does:**

1. **Validate staging readiness**:
   - Checks for staging-validation-report.md
   - Confirms all checks passed

2. **Version selection** (interactive):
   - Extracts current version from CHANGELOG.md
   - Calculates patch/minor/major bump options
   - Prompts user to select version
   - Validates semantic versioning format (vMAJOR.MINOR.PATCH)

3. **Create git tag**:
   - Checks if tag already exists
   - Ensures clean working directory (commits changes if needed)
   - Creates annotated tag with release message
   - Example: `git tag -a v1.2.3 -m "Release v1.2.3..."`

4. **Push tag to trigger deployment**:
   - Pushes tag to origin: `git push origin v1.2.3`
   - GitHub Actions workflow (`deploy-production.yml`) triggers on tag push
   - Tag push is atomic - deployment starts immediately

5. **Monitor deployment** (if gh CLI available):
   - Finds workflow run ID for the tag
   - Polls GitHub Actions status every 30 seconds
   - Streams deployment logs
   - Waits for deployment completion
   - Exits with error if deployment fails

6. **Update workflow state**:
   - Writes version, tag, timestamp to workflow-state.yaml
   - Records GitHub release URL
   - Updates deployment.production section

**Script output provides context for LLM:**

```
Version: v1.2.3
GitHub Release: https://github.com/user/repo/releases/tag/v1.2.3
Workflow Run: https://github.com/user/repo/actions/runs/12345
```

**After script completes, you (LLM) must:**

## 1) Verify Deployment Success

**Check script exit code:**
- Exit 0: Deployment succeeded
- Exit 1: Deployment failed

**If failed:**
- Read error messages from script output
- Check GitHub Actions logs (URL provided in output)
- Common failures:
  - Build errors (npm run build failed)
  - Test failures (production smoke tests)
  - Deployment platform errors (Vercel/Railway/Netlify)
  - Missing secrets in GitHub

## 2) Read Deployment Metadata

**Load workflow-state.yaml:**

```bash
Read(specs/$SLUG/workflow-state.yaml)
```

**Extract production deployment info:**
- `deployment.production.version` - Deployed version (e.g., "1.2.3")
- `deployment.production.tag` - Git tag (e.g., "v1.2.3")
- `deployment.production.tag_created_at` - Tag creation timestamp
- `deployment.production.deployed_at` - Deployment completion timestamp
- `deployment.production.github_release_url` - GitHub release URL

## 3) Present Deployment Summary

**Format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Production Deployment Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: <feature-slug>
Version: v<version>
Tag: v<version>

Production URLs:
  - Marketing: https://example.com
  - App: https://app.example.com
  - API: https://api.example.com

GitHub Release: <github-release-url>
Deployment Time: <timestamp>

Next: Full documentation finalization will run automatically.
```

## 4) Handle Errors

**If deployment fails:**

```
❌ Production Deployment Failed

Error: <error-message-from-script>

GitHub Actions logs: <workflow-run-url>

Common fixes:
  1. Check build errors in workflow logs
  2. Verify all secrets are configured in GitHub
  3. Check deployment platform (Vercel/Railway) status
  4. Validate production environment variables

After fixing, you can retry:
  - Delete tag locally: git tag -d v<version>
  - Delete tag remotely: git push origin :refs/tags/v<version>
  - Re-run /ship-prod
```

</instructions>

---

<constraints>
## ANTI-HALLUCINATION RULES

1. **Never invent production URLs**
   - Extract actual URLs from workflow-state.yaml or deployment logs
   - If URL unknown, say: "Production URL not captured (check deployment platform)"

2. **Quote workflow-state.yaml exactly for version info**
   - Don't paraphrase deployment metadata
   - If field missing, report: "Version not recorded in workflow-state.yaml"

3. **Cite GitHub Actions logs for deployment status**
   - Link to actual workflow run (extract from script output)
   - Don't fabricate deployment IDs or timestamps

4. **Never claim deployment success without verifying exit code**
   - Script exit 0 = success
   - Script exit 1 = failure (even if tag was created)

5. **Don't skip version selection prompt**
   - Script is interactive by design (HITL gate for version choice)
   - User must choose patch/minor/major or enter custom version

</constraints>

---

## NOTES

**Tagged Promotion vs Workflow Dispatch:**
- **Old approach**: Manually trigger `promote.yml` workflow via workflow_dispatch API
- **New approach**: Push semantic version tag, workflow triggers automatically
- **Benefits**:
  - Clear version history in git tags
  - Easy rollback (redeploy previous tag)
  - GitHub releases auto-created with changelogs
  - Auditability (git log shows all production releases)

**Rollback procedure:**
```bash
# Find previous version tag
git tag -l "v*" | sort -V | tail -5

# Deploy previous version
git push origin v1.2.2  # GitHub Actions deploys old version

# Or delete bad version and recreate
git tag -d v1.2.3
git push origin :refs/tags/v1.2.3
# Then run /ship-prod again with corrected CHANGELOG
```

**Deployment platform configuration:**
- Set `DEPLOY_PLATFORM` env var in `.github/workflows/deploy-production.yml`
- Options: `vercel`, `railway`, `netlify`, `custom`
- Add platform-specific secrets to GitHub repo settings

**Required GitHub Secrets:**
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` (if Vercel)
- `RAILWAY_TOKEN`, `RAILWAY_SERVICE` (if Railway)
- `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID` (if Netlify)
- `PRODUCTION_URL` (for smoke tests)

**Workflow file**: `.github/workflows/deploy-production.yml`
- Triggers on: `push: tags: - 'v*.*.*'`
- Builds production artifacts
- Deploys to platform
- Runs smoke tests
- Creates GitHub Release with changelog excerpt

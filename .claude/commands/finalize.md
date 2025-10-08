# /finalize - Complete documentation housekeeping after production deployment

You are executing the `/finalize` command to complete documentation housekeeping after production deployment.

## Context

This command runs AFTER `/phase-2-ship` has successfully deployed to production and created:
- Version tag (e.g., v1.2.3)
- GitHub release
- Updated roadmap

## Your Task

Execute the finalization script to update all documentation:

```bash
bash \spec-flow/scripts/bash/finalize.sh
```

## What the Script Does

**Phase F.1: Load Context**
- Find latest ship-report.md
- Extract version number
- Get commit range

**Phase F.2: Update CHANGELOG.md**
- Extract changes from commits (feat:, fix:, refactor:, security:)
- Categorize into Added/Changed/Fixed/Security
- Insert new version section at top

**Phase F.3: Update README.md**
- Update version badge
- Add new feature to features list

**Phase F.4: Generate User Documentation**
- Create help article: docs/help/features/[slug].md
- Extract user stories from spec.md
- Update help index: docs/help/README.md

**Phase F.5: Update API Docs**
- Detect changed API endpoints
- Flag API_ENDPOINTS.md for manual review if needed

**Phase F.6: Manage GitHub Milestones**
- Close current milestone (matching version pattern)
- Link release to milestone
- Create next milestone (+1 minor version, 2 weeks out)

**Phase F.7: Commit Documentation**
- Stage CHANGELOG.md, README.md, help docs
- Commit: "docs: update documentation for vX.Y.Z"
- Push to main

**Phase F.8: Output Summary**
- List updated files
- Show GitHub milestone updates
- Suggest next steps

## Expected Output

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Documentation Updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Version**: v1.2.3
**Feature**: aktr-inline-preview

### Files Updated

- ✅ CHANGELOG.md (Added v1.2.3 section)
- ✅ README.md (Updated features, badges)
- ✅ docs/help/features/aktr-inline-preview.md (New help article)
- ✅ docs/API_ENDPOINTS.md (No changes needed)

### GitHub

- ✅ Closed milestone: #12
- ✅ Created next milestone: v1.3.0

### Commits

- docs: update documentation for v1.2.3

### Next Steps

1. Review documentation accuracy
2. Update marketing site copy (if needed)
3. Announce release on social media
4. Monitor user feedback

---
**Workflow complete**: ... → phase-2-ship → finalize ✅
```

## Error Handling

**If ship-report.md not found:**
- Error message with instructions to run /phase-2-ship first
- Exit with error code 1

**If version tag missing:**
- Error message indicating /phase-2-ship should have created tag
- Show git tag command to verify

**If git working tree dirty:**
- Error message indicating uncommitted changes
- Request to commit or stash before running

**If GitHub API calls fail:**
- Warning (not error) indicating permission issues
- Continue with local documentation updates

## Success Criteria

- ✅ CHANGELOG.md has new version section
- ✅ README.md has updated features and version badge
- ✅ Help article created at docs/help/features/[slug].md
- ✅ Help index updated with new feature
- ✅ GitHub milestone closed (if found)
- ✅ Next milestone created
- ✅ All changes committed and pushed to main

## Time Estimate

5-10 minutes (fully automated)

## Dependencies

- bash
- git
- gh (GitHub CLI) - optional, for milestone management
- Standard Unix tools (sed, awk, grep, find)

## Workflow Position

```
... → /phase-1-ship → /validate-staging → /phase-2-ship → **/finalize** → Done
```

## Notes

- Fully automated (no manual gates)
- Idempotent (can run multiple times safely)
- Documentation-only (no deployment risk)
- Can skip for internal features if documentation not needed
- Errors in milestone management don't block documentation updates


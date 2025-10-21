---
description: "Release new version of Spec-Flow package (INTERNAL - workflow development only)"
---

# Internal Release Command

**DO NOT SHIP**: This command is for Spec-Flow workflow development only. Use it to release new versions of the workflow package itself.

You are now in release mode. Follow this workflow to release a new version of the Spec-Flow package:

## Step 1: Determine Version Bump

Ask the user which type of version bump:
- **patch** (2.1.3 → 2.1.4): Bug fixes, minor updates
- **minor** (2.1.3 → 2.2.0): New features, backward compatible
- **major** (2.1.3 → 3.0.0): Breaking changes

Read current version from package.json and calculate new version.

## Step 2: Verify Clean Working Tree

Check git status. If there are uncommitted changes, ask user if they want to continue.

## Step 3: Update Files

1. **package.json**: Update version field to new version
2. **CHANGELOG.md**: Add new release entry at top:
   ```markdown
   ## [NEW_VERSION] - YYYY-MM-DD

   ### Changed
   - Version bump to NEW_VERSION

   <!-- User should add release notes here -->
   ```

3. **README.md**: Update version badge if it exists (search for `version-X.X.X-blue`)

## Step 4: Commit Changes

Create commit with message:
```
chore: release vNEW_VERSION

- Bump version to NEW_VERSION
- Update CHANGELOG.md with release notes
- Update version references

Release: vNEW_VERSION
```

## Step 5: Create Git Tag

Create annotated tag:
```bash
git tag -a "vNEW_VERSION" -m "Release vNEW_VERSION"
```

## Step 6: Show Next Steps

Display to user:
```
✅ Release v{NEW_VERSION} prepared!

Next steps:
1. Review CHANGELOG.md and add detailed release notes
2. Amend commit if needed:
   git add CHANGELOG.md
   git commit --amend --no-edit
3. Push to remote:
   git push origin main
   git push origin v{NEW_VERSION}
4. Publish to npm:
   npm publish
```

## Important Notes

- Ask user to confirm before each major step
- Show diffs before committing
- Verify all changes look correct
- Remind user to update CHANGELOG.md with detailed notes
- Do NOT automatically push or publish - require manual user action

## Workflow

1. Ask for version bump type (patch/minor/major)
2. Calculate new version
3. Show summary of changes to be made
4. Ask for confirmation
5. Update all files
6. Create commit and tag
7. Display next steps for user

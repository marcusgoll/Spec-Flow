# Internal Scripts

**DO NOT SHIP**: These scripts are for Spec-Flow workflow development only. They are not included in the npm package.

## Release Script

Automates the release workflow for the Spec-Flow package itself.

### Usage

**Bash (macOS/Linux)**:
```bash
# Patch release (2.1.3 → 2.1.4)
bash .spec-flow/scripts/internal/release.sh patch

# Minor release (2.1.3 → 2.2.0)
bash .spec-flow/scripts/internal/release.sh minor

# Major release (2.1.3 → 3.0.0)
bash .spec-flow/scripts/internal/release.sh major

# Dry run (preview changes)
bash .spec-flow/scripts/internal/release.sh patch --dry-run

# Skip npm publish
bash .spec-flow/scripts/internal/release.sh patch --skip-npm
```

**PowerShell (Windows)**:
```powershell
# Patch release
pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType patch

# Minor release
pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType minor

# Major release
pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType major

# Dry run
pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType patch -DryRun

# Skip npm publish
pwsh -File .spec-flow/scripts/internal/release.ps1 -BumpType patch -SkipNpm
```

### What It Does

1. **Validates working tree**: Ensures git working tree is clean
2. **Calculates new version**: Based on bump type (patch/minor/major)
3. **Updates package.json**: Bumps version number
4. **Updates CHANGELOG.md**: Adds new release entry with date
5. **Updates README.md**: Updates version badge (if exists)
6. **Commits changes**: Creates conventional commit with release message
7. **Creates git tag**: Annotated tag with changelog notes
8. **Publishes to npm** (optional): Prompts for npm publish confirmation

### Version Bump Types

- **patch** (2.1.3 → 2.1.4): Bug fixes, minor updates, no breaking changes
- **minor** (2.1.3 → 2.2.0): New features, backward compatible
- **major** (2.1.3 → 3.0.0): Breaking changes, API changes

### After Release

1. Review CHANGELOG.md and add detailed release notes
2. Push to remote:
   ```bash
   git push origin main
   git push origin v2.1.4
   ```
3. If skipped npm publish, run manually:
   ```bash
   npm publish
   ```

### Example Workflow

```bash
# 1. Make changes to the workflow
git add .
git commit -m "feat: add new feature"

# 2. Run release script
bash .spec-flow/scripts/internal/release.sh minor

# 3. Edit CHANGELOG.md to add detailed notes
vim CHANGELOG.md

# 4. Amend commit with updated changelog
git add CHANGELOG.md
git commit --amend --no-edit

# 5. Push to remote
git push origin main
git push origin v2.2.0

# 6. Publish to npm (if not done by script)
npm publish
```

## Notes

- These scripts are marked `DO NOT SHIP` and are excluded from the npm package via `.npmignore`
- Always run with `--dry-run` first to preview changes
- Ensure working tree is clean before releasing
- The script follows [Conventional Commits](https://www.conventionalcommits.org/) and [Semantic Versioning](https://semver.org/)

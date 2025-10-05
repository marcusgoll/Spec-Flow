# Publishing Spec-Flow to NPM

This guide explains how to publish the Spec-Flow toolkit to npm so users can install it with `npx spec-flow`.

## Prerequisites

- npm account (create at https://www.npmjs.com/signup)
- npm CLI authenticated (`npm login`)
- Version updated in `package.json`
- **Important**: Check package name availability first:
  ```bash
  npm search spec-flow
  # If "spec-flow" is taken, update package.json to use:
  # - spec-flow-toolkit
  # - specflow-ai
  # - @marcusgoll/spec-flow (scoped package)
  ```

## Pre-Publish Checklist

1. **Test locally**:
   ```bash
   # From the repo root
   npm install
   npm link

   # Test in a different directory
   cd ~/test-project
   spec-flow init --non-interactive
   ```

2. **Update version** in `package.json`:
   - MAJOR: Breaking changes (1.0.0 -> 2.0.0)
   - MINOR: New features, backward compatible (1.0.0 -> 1.1.0)
   - PATCH: Bug fixes (1.0.0 -> 1.0.1)

3. **Update CHANGELOG.md** with release notes

4. **Commit changes**:
   ```bash
   git add .
   git commit -m "chore: bump version to X.Y.Z"
   git push
   ```

## Publishing Steps

### First Time (Initial Publish)

1. **Login to npm**:
   ```bash
   npm login
   # Enter username, password, and email
   ```

2. **Check package name availability**:
   ```bash
   npm search spec-flow
   # If taken, consider: spec-flow-toolkit, specflow-ai, etc.
   ```

3. **Publish (dry run)**:
   ```bash
   npm publish --dry-run
   # Review what will be included
   ```

4. **Publish to npm**:
   ```bash
   npm publish --access public
   ```

5. **Create git tag**:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

### Updates (Version Bumps)

1. **Bump version**:
   ```bash
   npm version patch  # or minor, major
   ```

2. **Publish**:
   ```bash
   npm publish
   ```

3. **Push tags**:
   ```bash
   git push --tags
   ```

## Package Contents

The package includes:
- `.claude/` - Agents, commands, settings templates
- `.spec-flow/` - Scripts, templates, memory templates
- `CLAUDE.md` - Workflow documentation
- `bin/` - CLI entry point and scripts
- `LICENSE` - MIT license
- `README.md` - Main documentation
- `QUICKSTART.md` - Quick start guide

Files excluded (via `.npmignore` or package.json `files`):
- `example-workflow-app/` - Example app
- `specs/` - Example specs
- `docs/` - Extended documentation
- `.git/` - Git metadata
- `node_modules/` - Dependencies

## Usage After Publishing

Users can install and use with:

```bash
# Initialize in current directory
npx spec-flow init

# Initialize in specific directory
npx spec-flow init --target ./my-project

# Update existing installation
npx spec-flow update

# Show help
npx spec-flow help
```

## Testing Published Package

After publishing, test the actual npm package:

```bash
mkdir ~/test-spec-flow
cd ~/test-spec-flow
npx spec-flow@latest init --non-interactive

# Verify files installed
ls -la .claude .spec-flow

# Verify commands work
cat .claude/commands/constitution.md
```

## Troubleshooting

### "Package not found"
- Wait 5-10 minutes for npm to propagate
- Check package name is correct: `spec-flow`
- Verify published: `npm view spec-flow`

### "Permission denied"
- Make sure `bin/cli.js` has shebang: `#!/usr/bin/env node`
- Scripts should be executable (git should preserve this)

### "Module not found"
- Ensure all dependencies are in `dependencies`, not `devDependencies`
- Run `npm install` before publishing

### "Scripts not working on Windows"
- PowerShell scripts (.ps1) are included
- CLI detects platform and uses appropriate scripts
- Ensure PowerShell 7+ is installed

## Best Practices

1. **Semantic Versioning**: Follow semver strictly
2. **Changelog**: Document all changes
3. **Testing**: Always test locally before publishing
4. **Tags**: Create git tags for all releases
5. **Deprecation**: Use `npm deprecate` for old versions if needed

## Unpublishing

If you need to unpublish (within 72 hours):

```bash
npm unpublish spec-flow@1.0.0
```

**Note**: Unpublishing is permanent and discouraged. Prefer deprecation:

```bash
npm deprecate spec-flow@1.0.0 "Please upgrade to 1.0.1"
```

## Resources

- npm Docs: https://docs.npmjs.com/
- npm Scoped Packages: https://docs.npmjs.com/cli/v8/using-npm/scope
- Semantic Versioning: https://semver.org/

## Current Status

✅ **Published**: spec-flow@1.1.0 is live on npm
📦 **Package**: https://www.npmjs.com/package/spec-flow
🔗 **Repository**: https://github.com/marcusgoll/Spec-Flow

## Version History

- **1.1.0** (2025-10-04) - Added interactive configuration wizard (`spec-flow configure`)
- **1.0.0** (2025-10-03) - Initial release with complete Spec-Flow workflow

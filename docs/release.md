# Release Management

Spec-Flow provides a slash command to automate the project release process.

## `/release`

Automates versioning, changelog generation, and distribution.

### Usage

```bash
/release <version_type> [tag_name]
```

- **version_type**: `patch`, `minor`, `major`, or explicit version `1.2.3`.
- **tag_name**: Optional custom tag (defaults to `vX.Y.Z`).

### Workflow

1. **Pre-flight**: Checks for clean git status and `main` branch.
2. **Bump**: Updates `package.json` version.
3. **Changelog**: Generates `CHANGELOG.md` from conventional commits.
4. **Commit**: Commits version bump and changelog.
5. **Tag**: Creates git tag.
6. **Push**: Pushes commits and tags to remote.
7. **GitHub Release**: Creates a release on GitHub with auto-generated notes.
8. **NPM Publish**: Prompts to publish package to npm registry.

### Requirements

- `gh` (GitHub CLI) installed and authenticated.
- `npm` authenticated (if publishing).
- `conventional-changelog-cli` (optional, for changelog generation).

### Configuration

The command uses standard `npm version` behavior and `gh release create`. Ensure your repository is configured for these tools.

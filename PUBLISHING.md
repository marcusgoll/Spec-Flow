# Publishing Guide

This project distributes the Spec-Flow CLI to both npm and GitHub Packages so the repository no longer shows "No packages published".

## Prerequisites

1. **Version bump** – update `package.json` (and `CHANGELOG.md` if applicable) before creating a release.
2. **NPM token** – add a repository secret named `NPM_TOKEN` that has `publish` rights for the npm package.
3. **GitHub permissions** – the default `GITHUB_TOKEN` already has `packages:write` permission, so no extra secret is required.

## Automated release (recommended)

1. Push the version bump to `main`.
2. Create a Git tag and GitHub release (or run the *Publish Packages* workflow manually).
3. The workflow:
   - Publishes `spec-flow` to npm when `NPM_TOKEN` is present and the version is new.
   - Generates a scoped copy of the package (`@marcusgoll/spec-flow`) in `dist/github-package/` and publishes it to GitHub Packages, which populates the repository's **Packages** tab.
   - Runs under the `npm-publish` environment so you can manage approvals or secrets centrally.
4. Verify the release:
   - https://www.npmjs.com/package/spec-flow
   - https://github.com/marcusgoll/Spec-Flow/pkgs/npm/spec-flow

## Manual publishing (fallback)

If you ever need to publish outside of the workflow:

```bash
# npm (requires an npm token configured locally)
npm publish --access public

# GitHub Packages
GITHUB_REPOSITORY_OWNER=marcusgoll node scripts/prepare-github-package.cjs
cd dist/github-package
npm publish --access public --registry https://npm.pkg.github.com
```

Remember to avoid republishing an existing version. Increment `package.json` if a release fails midway.

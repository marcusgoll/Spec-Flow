---
description: Automate complete release workflow for Spec-Flow package (version bump, CHANGELOG, git tag, GitHub release, npm publish)
allowed-tools: [Read, Write, Edit, Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git describe:*), Bash(git add:*), Bash(git commit:*), Bash(git tag:*), Bash(git push:*), Bash(git remote:*), Bash(npm whoami:*), Bash(npm run build:*), Bash(npm publish:*), Bash(gh auth:*), Bash(gh release:*), Bash(gh run:*), Bash(node -p:*), Bash(node -e:*), Bash(date:*), Bash(awk:*), Bash(sed:*), Bash(grep:*), Bash(wc:*), Bash(test:*), Bash(cat:*), Bash(ls:*)]
argument-hint: [--skip-build] [--skip-npm] [--skip-github] [--announce]
---

<context>
Current git status: !`git status --short | head -5`

Current branch: !`git branch --show-current`

Current version: !`node -p "require('./package.json').version" 2>/dev/null || echo "unknown"`

Last git tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "none"`

npm authentication: !`npm whoami 2>/dev/null && echo "✅ Authenticated" || echo "❌ Not authenticated"`

GitHub authentication: !`gh auth status >/dev/null 2>&1 && echo "✅ Authenticated" || echo "❌ Not authenticated"`

Git remote configured: !`git remote -v | grep -q origin && echo "✅ Configured" || echo "❌ Not configured"`

Recent commits (for version bump): !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo "--all")..HEAD --pretty=format:"%s" 2>/dev/null | head -10`
</context>

<objective>
Automate the complete release workflow for the Spec-Flow package, ensuring consistency and reducing manual errors.

**What it does:**
1. Pre-flight checks (git, npm, CI status)
2. Version bump detection (conventional commits → MAJOR, MINOR, PATCH)
3. Build validation (dist/ directory with BUILD_REPORT.md)
4. File updates (package.json, CHANGELOG.md, README.md)
5. Git operations (commit, tag, push)
6. GitHub Release creation with CHANGELOG notes
7. npm package publishing
8. Optional X (Twitter) announcement

**Operating constraints:**
- **INTERNAL USE ONLY** — For Spec-Flow workflow development only
- **Pre-flight Blockers** — 5 checks must pass (git remote, main branch, clean tree, npm auth, CI status)
- **Build Validation** — dist/BUILD_REPORT.md must exist (v6.12.0+)
- **Conventional Commits** — Version bump follows semantic versioning rules
- **Git Safety** — Never force push, always verify remote before push

**Dependencies:**
- Git repository with remote configured
- On main branch with clean working tree
- npm authentication configured (npm whoami)
- GitHub CLI authenticated (gh auth status)
- CI passing on latest commit
- Build system configured (npm run build)
</objective>

<process>
1. **Execute pre-flight checks** (5 checks):
   - Git remote configured
   - On main branch
   - Working tree clean (no uncommitted changes)
   - npm authenticated (npm whoami)
   - CI passing on latest commit (gh run list)

   **If any check fails**: Display specific error and exit. User must fix issue before releasing.

2. **Detect version bump** using conventional commits:
   - Get current version from package.json
   - Get last git tag (or v0.0.0 if none)
   - Analyze commits since last tag:
     - **MAJOR**: Any commit with "BREAKING CHANGE:" or "!" after type
     - **MINOR**: Any commit with "feat:" prefix
     - **PATCH**: Any commit with "fix:", "docs:", "chore:", "refactor:", "test:"
   - Calculate new version (e.g., 6.11.0 → 6.12.0 for MINOR bump)

3. **Run build system**:
   ```bash
   npm run build
   ```
   - Validate dist/ directory created
   - Verify BUILD_REPORT.md exists in dist/
   - **If build fails**: Display error and exit

4. **Update package.json**:
   - Load current package.json
   - Update version field to new version
   - Write back with proper formatting (2-space indent + newline)

5. **Update CHANGELOG.md**:
   - Read current CHANGELOG.md
   - Extract commits since last tag grouped by type (Features, Fixes, Docs, Chores)
   - Insert new version section under ## [Unreleased]:
     ```markdown
     ## [X.Y.Z] - YYYY-MM-DD

     ### Features
     - feat: description (commit hash)

     ### Fixes
     - fix: description (commit hash)
     ```
   - Write updated CHANGELOG.md

6. **Update README.md badges** (if version changed from 6.x.x to 7.x.x):
   - Update npm version badge URLs
   - Update any version-specific documentation links

7. **Git commit and tag**:
   ```bash
   git add package.json CHANGELOG.md README.md dist/
   git commit -m "chore: release vX.Y.Z"
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   ```

8. **Push to remote**:
   ```bash
   git push origin main
   git push origin vX.Y.Z
   ```
   - Verify remote is origin before pushing
   - Use separate commands for branch and tag (safer than --tags)

9. **Create GitHub Release**:
   ```bash
   gh release create vX.Y.Z \
     --title "Release vX.Y.Z" \
     --notes "{CHANGELOG section for this version}" \
     --latest
   ```
   - Extract CHANGELOG section for this version
   - Mark as latest release

10. **Publish to npm** (if --skip-npm not specified):
    ```bash
    npm publish
    ```
    - Verify npm authentication before publishing
    - Display success message with npm package URL

11. **Optional X announcement** (if --announce flag specified):
    - Invoke /announce-release command
    - Posts release to X (Twitter) with GitHub link

See `.claude/skills/release/references/reference.md` for detailed procedures, error recovery, and example execution run.
</process>

<verification>
Before completing, verify:
- Pre-flight checks all passed (5/5)
- Version bump calculated correctly (conventional commits analyzed)
- Build succeeded (dist/BUILD_REPORT.md exists)
- package.json version updated
- CHANGELOG.md new section added
- Git commit created with "chore: release vX.Y.Z" message
- Git tag created (vX.Y.Z)
- Remote push succeeded (both branch and tag)
- GitHub Release created
- npm publish succeeded (if not --skip-npm)
- Success summary displayed with all URLs
</verification>

<success_criteria>
**Pre-flight validation:**
- All 5 checks pass before any modifications
- Clear error messages for each failed check
- Blocks release if CI not passing

**Version bump accuracy:**
- MAJOR: Breaking changes detected correctly
- MINOR: New features detected correctly
- PATCH: Bug fixes and other commits detected correctly
- Version follows semantic versioning (X.Y.Z)

**File updates:**
- package.json version field updated
- CHANGELOG.md new section inserted under ## [Unreleased]
- Commits grouped by type (Features, Fixes, Docs, Chores)
- README.md badges updated if major version change

**Git operations:**
- Commit message: "chore: release vX.Y.Z"
- Tag format: vX.Y.Z (with v prefix)
- Both branch and tag pushed to origin
- No force push used

**GitHub Release:**
- Title: "Release vX.Y.Z"
- Body contains CHANGELOG section for this version
- Marked as latest release

**npm publishing:**
- Package published to npm registry
- Success URL displayed: https://www.npmjs.com/package/spec-flow

**User presentation:**
```
Release Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: vX.Y.Z (MINOR bump)
Build: ✅ Passed
Git: ✅ Committed and tagged
GitHub: ✅ Release created
npm: ✅ Published

URLs:
  📦 npm: https://www.npmjs.com/package/spec-flow
  🔖 GitHub: https://github.com/owner/repo/releases/tag/vX.Y.Z

Next: Users can install with npm install -g spec-flow@X.Y.Z
```
</success_criteria>

<standards>
**Industry Standards:**
- **Semantic Versioning**: [semver.org](https://semver.org/) for version numbers
- **Conventional Commits**: [conventionalcommits.org](https://www.conventionalcommits.org/) for version bump detection
- **Keep a Changelog**: [keepachangelog.com](https://keepachangelog.com/) for CHANGELOG.md format

**Workflow Standards:**
- Pre-flight checks block release if any fail
- Version bump automated from conventional commits
- Build validation required (dist/ must exist)
- Git operations atomic (commit, tag, push separately)
- GitHub Release body contains CHANGELOG section
- npm publish only if authenticated
- Success summary with all URLs
</standards>

<notes>
**Command location**: `.claude/commands/internal/release.md`

**Reference documentation**: Pre-flight checks, version bump detection, build validation, file update procedures, git operations, GitHub release creation, npm publishing, X announcement integration, error recovery strategies, and complete example execution run are in `.claude/skills/release/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Arguments:**
- `--skip-build`: Skip npm run build step (use existing dist/)
- `--skip-npm`: Skip npm publish step (GitHub Release only)
- `--skip-github`: Skip GitHub Release creation (npm only)
- `--announce`: Post release announcement to X (Twitter) after publishing

**Version bump examples:**
```
Commits since v6.11.0:
  feat: add new workflow command    → MINOR (6.11.0 → 6.12.0)
  fix: resolve template bug         → MINOR (feat takes precedence)
  docs: update README               → MINOR (feat takes precedence)

Commits since v6.12.0:
  fix: resolve auth issue           → PATCH (6.12.0 → 6.12.1)
  docs: update changelog            → PATCH (fix takes precedence)

Commits since v6.12.1:
  feat!: remove deprecated commands → MAJOR (6.12.1 → 7.0.0)
  BREAKING CHANGE: removed /old-cmd → MAJOR (detected in commit body)
```

**Build system (v6.12.0+):**
- Requires dist/ directory with BUILD_REPORT.md
- Validates build before any git operations
- Blocks release if build fails

**Error recovery:**
- Pre-flight failure: Fix issue and re-run /release
- Build failure: Fix build and re-run /release
- Git push failure: Manually push or delete tag and re-run
- GitHub Release failure: Manually create or re-run with --skip-npm
- npm publish failure: Fix authentication and run npm publish manually

**Related commands:**
- `/announce-release`: Post release to X (automatically invoked with --announce)
- `/init-project`: Initialize project docs (must exist for roadmap integration)
- `/roadmap`: Manage features (can reference releases in milestones)

**Internal use disclaimer:**
This command is for Spec-Flow workflow development only. Not intended for end-user projects. End users should use their own release workflows.
</notes>

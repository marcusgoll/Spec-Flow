---
name: release
description: Automate project release (version bump, changelog, git tag, GitHub release, npm publish)
argument-hint: <version_type> [tag_name]
allowed-tools: [Bash]
---

# /release — Project Release Automation

<context>
**Arguments**: $ARGUMENTS
**Current Version**: !`jq -r .version package.json`
**Git Status**: !`git status --short`
</context>

<objective>
Automate the software release process:
1. Bump version (npm/package.json)
2. Generate changelog
3. Commit and tag
4. Push to remote
5. Create GitHub Release
6. Publish to npm
</objective>

<process>
## Step 1: Validation & Execution

Execute the release workflow script with provided arguments.

```bash
bash .spec-flow/scripts/bash/release-workflow.sh $ARGUMENTS
```

**Script Actions:**
- Validates git status (must be clean)
- Bumps version in `package.json`
- Updates `CHANGELOG.md` (via conventional-changelog)
- Commits changes: `chore(release): vX.Y.Z`
- Creates git tag: `vX.Y.Z`
- Pushes commits and tags
- Creates GitHub Release (with auto-notes)
- Prompts to publish to npm
</process>

<success_criteria>
- `package.json` version updated
- `CHANGELOG.md` updated
- Git tag created and pushed
- GitHub Release created
- (Optional) Package published to npm
</success_criteria>

<usage>
**Bump patch version (1.0.0 -> 1.0.1):**
`/release patch`

**Bump minor version (1.0.0 -> 1.1.0):**
`/release minor`

**Bump major version (1.0.0 -> 2.0.0):**
`/release major`
</usage>

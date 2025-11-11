# /contract.bump - Contract Version Bumping

**Purpose**: Bump API and event contract versions following semantic versioning, update changelogs, and verify no consumer contracts are broken.

**Usage**:
```bash
/contract.bump [major|minor|patch] [--dry-run]
```

**Parameters**:
- `major`: Breaking changes (remove fields, change types, rename endpoints) - **Requires RFC + new sprint**
- `minor`: Additive changes (new endpoints, optional fields) - **Safe mid-sprint**
- `patch`: Documentation/examples only - **Safe mid-sprint**
- `--dry-run`: Show what would change without applying

**Prerequisites**:
- Contracts directory exists (`contracts/`)
- Current version directories present (`contracts/api/vX.Y.Z/`)
- Platform agent has write access

**Blocks**:
- **Major bumps mid-sprint**: Requires RFC approval + sprint planning
- **CDC verification failures**: Contract changes break consumer pacts
- **Uncommitted changes**: Working directory must be clean

---

## Workflow Steps

### 1. Parse Current Version

Read current version from latest `contracts/api/vX.Y.Z/` directory.

```bash
# Example: contracts/api/v1.0.0/ exists
CURRENT_VERSION="1.0.0"
```

### 2. Calculate New Version

Apply semver bump:

```bash
# major: 1.0.0 → 2.0.0
# minor: 1.0.0 → 1.1.0
# patch: 1.0.0 → 1.0.1
```

### 3. Check Mid-Sprint Breaking Change Gate

**If major bump**:
- Check if sprint is active (query workflow-state.yaml)
- **Block** if sprint in progress without RFC approval
- Prompt for RFC issue number

**Rule**: Breaking changes require RFC + new sprint planning.

### 4. Create New Version Directory

Copy current version to new version:

```bash
cp -r contracts/api/v1.0.0 contracts/api/v1.1.0
```

### 5. Update Version References

**Update `contracts/api/vX.Y.Z/openapi.yaml`**:

```yaml
info:
  version: 1.1.0  # Bumped
```

**Update `contracts/api/vX.Y.Z/CHANGELOG.md`**:

Add new version entry at top:

```markdown
## [1.1.0] - 2025-11-10

### Added

- [Summarize changes here]

### Changed

- [List modifications]

### Deprecated

- [List deprecations]

### Removed (major only)

- [List removals]
```

### 6. Run Contract Verification

Execute `/contract.verify` to ensure no consumer pacts are broken.

**If verification fails**:
- Display violated pacts
- **Block merge**
- Suggest fixing contract or coordinating with consumers

**If verification passes**:
- Proceed to commit

### 7. Git Workflow

**Create feature branch**:

```bash
git checkout -b contracts/bump-v1.1.0
```

**Commit changes**:

```bash
git add contracts/
git commit -m "feat(contracts): bump API contract to v1.1.0

- [List changes from CHANGELOG]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Create PR**:

```bash
gh pr create \
  --title "Bump API contract to v1.1.0" \
  --body "$(cat <<'EOF'
## Contract Version Bump

**Type**: [major|minor|patch]
**Version**: v1.0.0 → v1.1.0

## Changes

[Extracted from CHANGELOG.md]

## CDC Verification

✅ All pacts verified (X consumers)
- frontend-backend: ✅ passed
- webhook-consumer: ✅ passed

## Breaking Changes (major only)

[List breaking changes and migration path]

## Deployment Impact

- **Staging**: Deploy immediately after merge
- **Production**: Requires consumer migration (if major)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 8. Output Summary

Display summary to user:

```
✅ Contract bumped: v1.0.0 → v1.1.0

📄 Files Updated:
   - contracts/api/v1.1.0/openapi.yaml
   - contracts/api/v1.1.0/CHANGELOG.md

✅ CDC Verification: Passed (3 pacts verified)
   - frontend-backend: ✅
   - webhook-consumer: ✅
   - epic-a-epic-b: ✅

📝 Next Steps:
   1. Review PR: https://github.com/org/repo/pull/123
   2. Merge after approval
   3. Deploy to staging to publish new contract
   4. Notify consumers of new version
```

---

## Error Handling

### Major Bump Mid-Sprint (No RFC)

```
❌ Blocked: Major version bump requires RFC

Breaking changes are not allowed mid-sprint without RFC approval.

Options:
  1. Create RFC issue: /roadmap ADD "RFC: Breaking contract change"
  2. Postpone to next sprint
  3. Find additive alternative (minor bump)

See: docs/contract-governance.md
```

### CDC Verification Failed

```
❌ Contract verification failed

The following consumer pacts were violated:

1. frontend-backend
   Expected: GET /api/users/:id returns { email: string }
   Actual:   Field 'email' missing from response

   Fix: Add 'email' field back OR coordinate with frontend team

2. webhook-consumer
   Expected: webhook payload includes 'epic' field
   Actual:   Field 'epic' not in schema

   Fix: Add 'epic' as optional field

---

Options:
  1. Fix contract to satisfy pacts
  2. Coordinate with consumers to update pacts
  3. Cancel bump: git checkout main && git branch -D contracts/bump-v1.1.0

Run '/contract.verify' to recheck after fixes.
```

### Uncommitted Changes

```
❌ Working directory not clean

Commit or stash changes before bumping contracts.

Modified files:
  - src/api/users.ts
  - src/api/features.ts

Options:
  1. git add . && git commit -m "..."
  2. git stash
  3. Cancel changes
```

---

## Implementation Details

### Script Location

**Bash**: `.spec-flow/scripts/bash/contract-bump.sh`
**PowerShell**: `.spec-flow/scripts/powershell/contract-bump.ps1`

### Functions Required

```bash
# Parse current version from contracts/api/vX.Y.Z/
get_current_contract_version() {
  ls -d contracts/api/v* | tail -1 | grep -oP 'v\K[\d.]+'
}

# Bump version by semver level
bump_version() {
  local version=$1
  local level=$2  # major|minor|patch
  # Use semver CLI or awk
}

# Update openapi.yaml version field
update_openapi_version() {
  local file=$1
  local new_version=$2
  # Use yq or sed
}

# Add CHANGELOG entry
add_changelog_entry() {
  local file=$1
  local version=$2
  local date=$(date +%Y-%m-%d)
  # Prepend new version section
}

# Run CDC verification
verify_contracts() {
  # Call /contract.verify
  # Return exit code
}

# Check if sprint is active
is_sprint_active() {
  # Query workflow-state.yaml
  # Check if any epic in "Implementing" state
}

# Check for RFC approval
has_rfc_approval() {
  local rfc_issue=$1
  # Query GitHub issue via gh CLI
  # Check if labeled 'rfc:approved'
}
```

### Dependencies

- **yq** or **jq**: YAML/JSON parsing
- **gh CLI**: GitHub PR creation
- **semver**: Version bumping (or awk alternative)
- **git**: Version control

---

## Integration with Workflow

### Epic State Machine

Epics can only transition to `Contracts-Locked` state after:
1. Contracts defined (OpenAPI + JSON Schema)
2. **Contract version bumped** (if updating existing)
3. `/contract.verify` passes

### Platform Agent Responsibility

The **platform agent** owns:
- Executing `/contract.bump` when contract changes needed
- Reviewing contract bump PRs
- Coordinating with consumers on breaking changes
- Publishing new contract versions to contract registry

### Continuous Integration

**GitHub Actions**: `.github/workflows/contract-verification.yml`

```yaml
name: Contract Verification

on:
  pull_request:
    paths:
      - 'contracts/**'

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify contracts
        run: |
          .spec-flow/scripts/bash/contract-verify.sh
      - name: Block merge if failed
        if: failure()
        run: exit 1
```

**Branch Protection**: Require "Contract Verification" check to pass before merge.

---

## Examples

### Example 1: Minor Bump (Add Optional Field)

```bash
# Add optional 'epic' field to Feature schema in openapi.yaml
# Bump version
/contract.bump minor

# Output:
✅ Contract bumped: v1.0.0 → v1.1.0
✅ CDC Verification: Passed (3 pacts)
📝 PR created: #456
```

### Example 2: Major Bump (Remove Required Field) - Mid-Sprint

```bash
# Remove 'email' field from User schema
/contract.bump major

# Output:
❌ Blocked: Major version bump requires RFC

Create RFC issue first:
  /roadmap ADD "RFC: Remove email field from User schema" --type rfc
```

### Example 3: Patch Bump (Fix Documentation)

```bash
# Fix typo in API description
/contract.bump patch

# Output:
✅ Contract bumped: v1.0.0 → v1.0.1
✅ CDC Verification: Passed (3 pacts)
📝 PR created: #457
```

### Example 4: Dry Run

```bash
/contract.bump minor --dry-run

# Output:
📋 Dry Run: Contract Bump v1.0.0 → v1.1.0

Changes that would be applied:
  - Create contracts/api/v1.1.0/
  - Update openapi.yaml: version 1.1.0
  - Add CHANGELOG entry for 1.1.0
  - Commit: "feat(contracts): bump API contract to v1.1.0"
  - Create PR: "Bump API contract to v1.1.0"

CDC Verification: Would run /contract.verify

Run without --dry-run to apply.
```

---

## References

- [Semantic Versioning](https://semver.org/)
- [OpenAPI Versioning Best Practices](https://swagger.io/specification/#version-string)
- [Consumer-Driven Contracts](https://martinfowler.com/articles/consumerDrivenContracts.html)
- `/contract.verify` - Contract verification command
- `/contract.refresh` - Fixture regeneration command
- `contracts/README.md` - Contract governance guide

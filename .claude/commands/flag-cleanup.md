# /flag.cleanup - Remove Feature Flag

**Purpose**: Retire feature flag when work is complete. Prevents flag debt accumulation.

**Usage**:
```bash
/flag.cleanup <flag-name> [--verify] [--force]
```

**Parameters**:
- `flag-name`: Flag to remove
- `--verify`: Check for flag references in code before removing
- `--force`: Skip verification (not recommended)

**Output**: Flag marked as retired in registry

---

## When to Clean Up

**Clean up flags when**:
- Feature complete and deployed to production
- Flag wrapping complete code (no incomplete work)
- Sprint ends (all sprint flags should be cleaned)

**Don't clean up if**:
- Work still incomplete
- Code still references flag
- A/B test still running (use longer expiry instead)

---

## Workflow

### 1. Check Flag Status

```bash
/flag.list

# Output:
acs_sync_enabled (✅ Active, expires in 2d)
```

### 2. Verify Feature Complete

Ensure all code paths functional without flag:

```bash
# Backend: Remove flag check
# Before:
if (!featureFlags.acs_sync_enabled) {
  return res.status(404).json({ error: 'Not available' });
}

# After:
// Flag removed - feature always enabled
```

### 3. Remove Flag References

**Automated scan**:

```bash
/flag.cleanup acs_sync_enabled --verify

# Scans codebase for references:
Found 2 references:
  - src/api/sync.ts:12
  - src/ui/SyncButton.tsx:34

❌ Cannot cleanup - code still references flag

Remove references first:
  1. Delete flag checks from code
  2. Re-run: /flag.cleanup acs_sync_enabled --verify
```

**Manual removal**:

```typescript
// src/api/sync.ts
// Before:
if (!featureFlags.acs_sync_enabled) {
  return res.status(404).json({ error: 'Feature not available' });
}

// After (remove if-statement):
// Feature always available
```

### 4. Cleanup Flag

```bash
/flag.cleanup acs_sync_enabled --verify

# Output:
✅ No code references found
✅ Flag retired: acs_sync_enabled

Registry updated:
  - Status: active → retired
  - Retired: 2025-11-10T16:00:00Z

Flag removed from active registry.
Historical record kept in feature-flags.yaml.
```

### 5. Commit Changes

```bash
git add .
git commit -m "refactor: remove acs_sync_enabled flag

Feature complete and deployed. Flag no longer needed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

git push
```

---

## Implementation

### Script Location

**Bash**: `.spec-flow/scripts/bash/flag-cleanup.sh`

### Algorithm

```bash
# 1. Check flag exists
if ! flag_exists "$name"; then
  error "Flag not found: $name"
fi

# 2. Verify no code references (unless --force)
if [[ "$VERIFY" == true ]]; then
  references=$(grep -r "$name" src/ 2>/dev/null || true)

  if [[ -n "$references" ]]; then
    echo "Found references:"
    echo "$references"
    error "Remove code references before cleanup"
  fi
fi

# 3. Mark as retired
yq eval "(.flags[] | select(.name == \"$name\") | .status) = \"retired\"" -i feature-flags.yaml
yq eval "(.flags[] | select(.name == \"$name\") | .retired) = \"$(date -Iseconds)\"" -i feature-flags.yaml

# 4. Success message
echo "✅ Flag retired: $name"
```

---

## Verification Mode

**Automatic code scanning**:

```bash
/flag.cleanup feature_enabled --verify
```

**Scan locations**:
- `src/**/*.ts`
- `src/**/*.tsx`
- `src/**/*.js`
- `src/**/*.jsx`
- `api/**/*`
- `config/**/*`

**Ignore**:
- `node_modules/`
- `.git/`
- `dist/`
- `build/`

**Patterns**:
- `featureFlags.feature_enabled`
- `feature_enabled: true`
- `'feature_enabled'`
- `"feature_enabled"`

---

## Examples

### Example 1: Clean Cleanup

```bash
/flag.cleanup acs_sync_enabled --verify

# Output:
Scanning codebase for references...
✅ No references found

Flag retired: acs_sync_enabled
  Created: 2025-11-07
  Retired: 2025-11-10
  Lifetime: 3 days

Registry updated.
```

### Example 2: References Found

```bash
/flag.cleanup dashboard_redesign_enabled --verify

# Output:
Scanning codebase...
❌ Found 4 references:

  src/ui/Dashboard.tsx:23
    if (featureFlags.dashboard_redesign_enabled) {

  src/ui/DashboardNav.tsx:45
    const enabled = featureFlags.dashboard_redesign_enabled;

  src/config/flags.ts:12
    dashboard_redesign_enabled: true,

  tests/dashboard.test.ts:67
    mockFlags.dashboard_redesign_enabled = true;

Remove references and re-run cleanup.
```

### Example 3: Force Cleanup

```bash
/flag.cleanup temp_flag --force

# Output:
⚠️ Skipping verification (--force)

Flag retired: temp_flag

Note: Code may still reference this flag.
Search for references: grep -r "temp_flag" src/
```

### Example 4: Already Retired

```bash
/flag.cleanup old_feature_enabled

# Output:
ℹ️ Flag already retired: old_feature_enabled

Retired: 2025-10-15 (26 days ago)

No action needed.
```

---

## Flag Retirement vs Deletion

**Retired** (recommended):
- Flag status = `retired`
- Kept in registry for historical record
- Can see when feature went live
- Audit trail

**Deleted** (not recommended):
- Flag removed from registry entirely
- No historical record
- Can't track when feature shipped

**Convention**: Retire, don't delete.

---

## Sprint End Cleanup

At sprint end, clean up all sprint flags:

```bash
# List active flags
/flag.list

# Clean up each
/flag.cleanup acs_sync_enabled --verify
/flag.cleanup parser_ocr_enabled --verify
/flag.cleanup diff_engine_enabled --verify

# Verify all cleaned
/flag.list

# Output:
✅ No active flags

All sprint flags cleaned up.
```

---

## Integration

### PR Template

Add flag cleanup checklist:

```markdown
## Feature Flags

- [ ] No new flags added OR flags registered
- [ ] Expired flags cleaned up (`/flag.list --expired`)
- [ ] Code references removed before cleanup
```

### CI Linter

Block merges with expired flags >7 days:

```yaml
# .github/workflows/flag-linter.yml
- name: Check for old expired flags
  run: |
    .spec-flow/scripts/bash/flag-check-expired.sh --max-age 7

    if [ $? -ne 0 ]; then
      echo "❌ Expired flags found - run /flag.cleanup"
      exit 1
    fi
```

### Platform Agent Monitoring

Platform agent tracks flag debt:

```bash
# Weekly cleanup reminder
/flag.list

# If expired flags found:
⚠️ 2 expired flags detected

Clean up immediately:
  /flag.cleanup feature1_enabled
  /flag.cleanup feature2_enabled
```

---

## Best Practices

### 1. Verify Before Cleanup

Always use `--verify`:

```bash
/flag.cleanup flag_name --verify
```

### 2. Remove Code References First

Don't use `--force`:

```bash
# Bad:
/flag.cleanup flag --force

# Good:
# 1. Remove flag from code
# 2. /flag.cleanup flag --verify
```

### 3. Clean Up Daily

Remove flags as features complete:

```bash
# Don't wait for sprint end
/flag.cleanup completed_feature
```

### 4. Commit Separately

Commit flag cleanup separately from feature work:

```bash
git commit -m "refactor: remove feature_flag

Feature complete and deployed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

## Error Handling

### Flag Not Found

```
❌ Flag not found: unknown_flag

List active flags:
  /flag.list
```

### Code References Found

```
❌ Cannot cleanup - code still references flag

Found 3 references in:
  - src/api/feature.ts:23
  - src/ui/FeatureToggle.tsx:45
  - config/flags.ts:12

Steps:
  1. Remove flag checks from code
  2. Test without flag
  3. Re-run: /flag.cleanup feature_flag --verify
```

---

## References

- [Feature Toggles - Retire Toggles](https://martinfowler.com/articles/feature-toggles.html#RetireToggles)
- `/flag.add` - Create flags
- `/flag.list` - List active/expired flags
- `/branch.enforce` - Branch health monitoring

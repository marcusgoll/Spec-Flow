# /flag.add - Add Feature Flag

**Purpose**: Create feature flag to enable merging incomplete work within 24h branch limit. Prevents trunk-based dev violations.

**Usage**:
```bash
/flag.add <flag-name> [--branch BRANCH] [--epic EPIC] [--reason TEXT] [--expires DATE]
```

**Parameters**:
- `flag-name`: Unique flag identifier (e.g., `acs_sync_enabled`)
- `--branch`: Git branch name (default: current branch)
- `--epic`: Epic this flag belongs to (optional)
- `--reason`: Why this flag exists (required)
- `--expires`: Expiry date (default: current sprint end)

**Output**: Flag registered in `.spec-flow/memory/feature-flags.yaml`

---

## When to Use

**Use feature flags when**:
- Work incomplete at 18h (warning threshold)
- Feature too large for 24h completion
- Need to merge daily but work not shippable

**Don't use flags for**:
- Complete, shippable work (just merge)
- Bug fixes (should be small, ship quickly)
- Documentation changes (no runtime impact)

---

## Workflow

### 1. Detect Need for Flag

Branch age approaching 24h limit:

```bash
/branch.enforce

# Output:
⚠️ feature/acs-sync (20h old) - merge within 4h
```

**Decision**: Add flag and merge incomplete work

### 2. Add Flag

```bash
/flag.add acs_sync_enabled \
  --branch feature/acs-sync \
  --epic acs-epic-a \
  --reason "Large feature - merging daily with incomplete work"
```

**Registry update**:

```yaml
flags:
  - name: acs_sync_enabled
    owner: backend-dev
    epic: acs-epic-a
    branch: feature/acs-sync
    created: 2025-11-10T14:30:00Z
    expires: 2025-11-24T23:59:59Z  # Sprint end
    status: active
    reason: "Large feature - merging daily with incomplete work"
    code_locations: []
```

### 3. Wrap Code with Flag

**Backend example** (Node.js):

```typescript
// src/api/sync.ts
import { featureFlags } from './config/flags';

export async function syncDocuments(req, res) {
  if (!featureFlags.acs_sync_enabled) {
    return res.status(404).json({ error: 'Feature not available' });
  }

  // Incomplete implementation
  const result = await performSync();
  res.json(result);
}
```

**Frontend example** (React):

```tsx
// src/components/SyncButton.tsx
import { useFeatureFlag } from './hooks/useFeatureFlag';

export function SyncButton() {
  const acsSync Enabled = useFeatureFlag('acs_sync_enabled');

  if (!acsSyncEnabled) {
    return null;  // Hide incomplete feature
  }

  return <button onClick={handleSync}>Sync Documents</button>;
}
```

### 4. Merge to Main

```bash
git add .
git commit -m "feat(acs): add document sync (behind flag)

Work in progress - flag: acs_sync_enabled

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

git push  # No longer blocked by 24h limit
```

### 5. Complete Work

Continue development with daily merges:

```bash
# Day 2: More progress
git commit -m "feat(acs): improve sync error handling (flag: acs_sync_enabled)"
git push

# Day 3: Feature complete
git commit -m "feat(acs): finalize sync feature"
git push
```

### 6. Remove Flag

When feature complete:

```bash
/flag.cleanup acs_sync_enabled
```

---

## Implementation

### Script Location

**Bash**: `.spec-flow/scripts/bash/flag-add.sh`

### Algorithm

```bash
# 1. Validate flag name (snake_case, ends with _enabled)
validate_flag_name() {
  if [[ ! "$name" =~ ^[a-z0-9_]+_enabled$ ]]; then
    error "Flag name must be snake_case ending with _enabled"
  fi
}

# 2. Check for duplicates
if flag_exists "$name"; then
  error "Flag already exists: $name"
fi

# 3. Detect current sprint end date
get_sprint_end_date() {
  # Check workflow-state.yaml for active sprint
  # Or default to 2 weeks from now
}

# 4. Add to registry
add_to_registry() {
  yq eval ".flags += [{
    \"name\": \"$name\",
    \"owner\": \"$owner\",
    \"epic\": \"$epic\",
    \"branch\": \"$branch\",
    \"created\": \"$(date -Iseconds)\",
    \"expires\": \"$expires\",
    \"status\": \"active\",
    \"reason\": \"$reason\",
    \"code_locations\": []
  }]" -i feature-flags.yaml
}

# 5. Output usage instructions
echo "Flag created: $name"
echo ""
echo "Wrap code with flag:"
echo "  if (featureFlags.${name}) { ... }"
echo ""
echo "Remove when done:"
echo "  /flag.cleanup $name"
```

---

## Examples

### Example 1: Basic Flag

```bash
/flag.add dashboard_redesign_enabled \
  --reason "UI overhaul - merging incrementally"

# Output:
✅ Flag created: dashboard_redesign_enabled

Wrap incomplete code:
  if (featureFlags.dashboard_redesign_enabled) {
    // New dashboard UI
  }

Expires: 2025-11-24 (sprint end)

Remove when complete: /flag.cleanup dashboard_redesign_enabled
```

### Example 2: Epic-Scoped Flag

```bash
/flag.add acs_parser_enabled \
  --epic acs-epic-b \
  --branch feature/acs-ocr-parser \
  --reason "OCR integration requires multiple days"

# Output:
✅ Flag created: acs_parser_enabled

Epic: acs-epic-b
Branch: feature/acs-ocr-parser
Expires: 2025-11-24

This flag is tracked as part of epic acs-epic-b.
Platform agent will monitor flag cleanup as epic completes.
```

### Example 3: Custom Expiry

```bash
/flag.add experimental_feature_enabled \
  --expires 2025-12-15 \
  --reason "Long-running experiment"

# Output:
⚠️ Warning: Expiry beyond current sprint (2025-11-24)

Flag created with extended expiry: 2025-12-15

Note: Flags should be temporary. Consider:
  - Splitting feature into smaller slices
  - Permanent configuration instead of flag
```

---

## Flag Naming Convention

**Pattern**: `<feature>_<component>_enabled`

**Good names**:
- `acs_sync_enabled`
- `dashboard_redesign_enabled`
- `payment_stripe_enabled`
- `notification_email_enabled`

**Bad names**:
- `feature1` (not descriptive)
- `acsSyncEnabled` (use snake_case)
- `acs_sync` (missing _enabled suffix)
- `temp_flag` (not feature-specific)

---

## Integration

### Git Hook Integration

Pre-push hook checks for flag before blocking:

```bash
# .git/hooks/pre-push
if branch_age > 24h; then
  if has_feature_flag; then
    allow_push  # Flag exempts from block
  else
    block_push  # Suggest adding flag
  fi
fi
```

### Platform Agent Monitoring

Platform agent tracks flag debt:

```bash
/metrics.dora

# Includes:
Active flags: 3
Expired flags: 0
Average flag lifetime: 4.2 days
```

**Alert** if flag >7 days past expiry

---

## Best Practices

### 1. Add Flag Early

Add at 18h (warning), not 24h (block):

```bash
# At 18h warning
/flag.add feature_enabled --reason "Need 2 more days"
```

### 2. Keep Flags Temporary

Remove within sprint (14 days max):

```bash
# Sprint end: remove all flags
/flag.list
/flag.cleanup feature_enabled
```

### 3. One Flag Per Feature

Don't create multiple flags for same feature:

```bash
# Bad: multiple flags
acs_sync_part1_enabled
acs_sync_part2_enabled

# Good: one flag
acs_sync_enabled
```

### 4. Track Code Locations

Update flag when wrapping code:

```bash
# Auto-detect (future)
/flag.scan acs_sync_enabled

# Manual update
yq eval '.flags[] | select(.name == "acs_sync_enabled") | .code_locations += ["src/api/sync.ts:12"]' -i feature-flags.yaml
```

---

## Error Handling

### Duplicate Flag

```
❌ Flag already exists: acs_sync_enabled

Use different name or cleanup existing:
  /flag.cleanup acs_sync_enabled
```

### Invalid Name

```
❌ Invalid flag name: acsSyncEnabled

Flag names must:
  - Use snake_case
  - End with _enabled
  - Example: acs_sync_enabled
```

### Missing Reason

```
❌ Flag reason required

Example:
  /flag.add feature_enabled --reason "Work incomplete - merging daily"
```

---

## References

- [Feature Toggles (Martin Fowler)](https://martinfowler.com/articles/feature-toggles.html)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- `/flag.list` - List active and expired flags
- `/flag.cleanup` - Remove flags
- `/branch.enforce` - Check branch health

# Infrastructure Command Integration

**Status**: ✅ Implemented (2025-11-12)

**Purpose**: Automatically prompt users to run infrastructure commands at the right moments in the workflow.

---

## Overview

Infrastructure commands (`/flag-add`, `/contract-verify`, `/contract-bump`, `/flag-cleanup`, `/fixture-refresh`) are now integrated into the main workflow via contextual prompts. A centralized detection script identifies when each command is needed.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│ Centralized Detection Script                │
│ .spec-flow/scripts/bash/                   │
│   detect-infrastructure-needs.sh            │
│                                             │
│ Returns JSON with all detected needs       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Phase Commands (call detection script)     │
│ ├─ /implement → Branch age, API changes    │
│ ├─ /optimize  → Contract verification      │
│ ├─ /plan      → API changes planned        │
│ └─ /ship      → Flag cleanup                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ User sees contextual prompt with command    │
│ Example: "/flag-add auth_enabled"          │
└─────────────────────────────────────────────┘
```

---

## Detection Script

**Location**: `.spec-flow/scripts/bash/detect-infrastructure-needs.sh`

**Usage**:
```bash
# Get all detections
.spec-flow/scripts/bash/detect-infrastructure-needs.sh all

# Get specific detection
.spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-needed
.spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-bump
.spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-verify
.spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-cleanup
.spec-flow/scripts/bash/detect-infrastructure-needs.sh fixture-refresh
.spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-summary
.spec-flow/scripts/bash/detect-infrastructure-needs.sh api-changes-planned
```

**Output**: JSON with detection results

**Example**:
```json
{
  "flag_needed": {
    "needed": true,
    "reason": "Branch is 20h old (24h limit approaching)",
    "branch_age_hours": 20,
    "slug": "user-auth"
  },
  "contract_bump": {
    "needed": true,
    "reason": "3 API-related files modified",
    "changed_files": ["routes/users.ts", "openapi.yaml", "schema.graphql"]
  },
  "contract_verify": {
    "needed": true,
    "reason": "5 consumer contracts found",
    "pact_count": 5
  },
  "flag_cleanup": {
    "needed": true,
    "reason": "2 active feature flags found",
    "active_flags": ["auth_enabled", "dashboard_redesign_enabled"]
  },
  "fixture_refresh": {
    "needed": true,
    "reason": "2 database migration files modified",
    "migration_files": ["migrations/0005_add_users.sql", "migrations/0006_add_roles.sql"]
  },
  "api_changes_planned": {
    "planned": true,
    "reason": "Feature spec mentions API modifications"
  }
}
```

---

## Integration Points

### 1. `/implement` - Implementation Phase

**File**: `.claude/commands/phases/implement.md:390-460`

**Prompts**:
- ⚠️ **Branch age warning** (18h threshold) → Suggests `/flag-add`
- 🔌 **API changes detected** → Suggests `/contract-bump` and `/contract-verify`
- 🗄️ **Migrations detected** → Suggests `/fixture-refresh`

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  BRANCH AGE WARNING: 20h (24h limit)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Consider adding a feature flag to merge daily:
  /flag-add user_auth_enabled --reason "Large feature - daily merges"

This allows merging incomplete work behind a flag.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 2. `/optimize` - Optimization Phase

**File**: `.claude/commands/phases/optimize.md:356-393`

**Prompts**:
- 🔍 **Auto-run contract verification** (if pacts exist) → Runs `/contract-verify` automatically

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 RUNNING CONTRACT VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found 5 consumer contracts - verifying compatibility...

✅ All consumer contracts verified
```

**Blocking**: If `/contract-verify` fails, `/optimize` fails and deployment is blocked.

---

### 3. `/plan` - Planning Phase

**File**: `.claude/commands/phases/plan.md:1310-1334`

**Prompts**:
- ℹ️ **API changes planned** (detected from spec.md) → Reminds about `/contract-bump` and `/contract-verify`

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️  API CHANGES PLANNED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This feature modifies APIs. After implementation:

  1. Bump contract version:
     /contract-bump [major|minor|patch] --reason "Change description"

  2. Verify consumers:
     /contract-verify

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 4. `/ship` - Deployment Phase

**File**: `.claude/commands/deployment/ship.md:332-368`

**Prompts**:
- 🚩 **Active flags detected** → Suggests `/flag-cleanup` for each flag

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚩 ACTIVE FEATURE FLAGS DETECTED (2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remove flags that are no longer needed:

  /flag-cleanup auth_enabled
  /flag-cleanup dashboard_redesign_enabled

Keeping flags increases tech debt. Clean up before next sprint.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Detection Logic

### Branch Age Detection
- **Threshold**: 18 hours (warns at 18h, blocks at 24h)
- **Method**: `git log` timestamp comparison
- **Returns**: `branch_age_hours`, `slug`

### API Changes Detection
- **Patterns**: `openapi.yaml`, `schema.graphql`, `*.proto`, `routes/`, `controllers/`, `api/`, `handlers/`
- **Method**: `git diff --name-only main...`
- **Returns**: List of changed files

### Contract Verification Detection
- **Check**: Existence of `contracts/pacts/*.json` files
- **Method**: `find contracts/pacts -name '*.json'`
- **Returns**: `pact_count`

### Flag Cleanup Detection
- **Check**: Active flags in `.spec-flow/memory/feature-flags.yaml`
- **Method**: `yq eval '.flags[] | select(.status == "active")'`
- **Returns**: List of active flag names

### Fixture Refresh Detection
- **Patterns**: `migrations/`, `alembic/versions/`, `prisma/migrations/`, `db/migrate/`
- **Method**: `git diff --name-only main...`
- **Returns**: List of migration files

### API Changes Planned Detection
- **Check**: Grep for API keywords in `specs/*/spec.md`
- **Keywords**: "API endpoint", "GraphQL", "REST", "gRPC", "webhook", "HTTP"
- **Returns**: Boolean

---

## Testing

### Manual Testing

1. **Test branch age detection**:
   ```bash
   # Create old branch
   git checkout -b test-old-branch
   git commit --allow-empty -m "test" --date="2 days ago"

   # Run detection
   .spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-needed
   ```

2. **Test API changes detection**:
   ```bash
   # Modify API file
   touch openapi.yaml
   git add openapi.yaml
   git commit -m "Update API"

   # Run detection
   .spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-bump
   ```

3. **Test contract verification detection**:
   ```bash
   # Create pact files
   mkdir -p contracts/pacts
   echo '{}' > contracts/pacts/test.json

   # Run detection
   .spec-flow/scripts/bash/detect-infrastructure-needs.sh contract-verify
   ```

4. **Test flag cleanup detection**:
   ```bash
   # Create feature flag
   echo 'flags:
     - name: test_enabled
       status: active' > .spec-flow/memory/feature-flags.yaml

   # Run detection
   .spec-flow/scripts/bash/detect-infrastructure-needs.sh flag-cleanup
   ```

5. **Test full integration**:
   ```bash
   # Run full feature workflow
   /feature "Test feature"
   # Watch for prompts at each phase
   ```

---

## Maintenance

### Adding New Infrastructure Commands

To add a new infrastructure command integration:

1. **Add detection function** to `detect-infrastructure-needs.sh`:
   ```bash
   detect_new_command_needed() {
     local result='{"needed": false, "reason": ""}'

     # Detection logic here
     if [ condition ]; then
       result=$(jq -n \
         --arg reason "Reason string" \
         '{needed: true, reason: $reason}')
     fi

     echo "$result"
   }
   ```

2. **Add to main() function**:
   ```bash
   case "$phase" in
     new-command)
       detect_new_command_needed
       ;;
     all)
       # Add to all detections
       local new_command=$(detect_new_command_needed)
       # Include in jq output
       ;;
   esac
   ```

3. **Add prompt to phase command**:
   ```bash
   if [ -f .spec-flow/scripts/bash/detect-infrastructure-needs.sh ]; then
     NEW_COMMAND_NEEDED=$(.spec-flow/scripts/bash/detect-infrastructure-needs.sh new-command 2>/dev/null | jq -r '.needed // false')

     if [ "$NEW_COMMAND_NEEDED" = "true" ]; then
       echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
       echo "Prompt message here"
       echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     fi
   fi
   ```

4. **Document** in this file.

---

## Known Issues

### Issue: roadmap.md corrupted

**Status**: 🐛 Open

**Description**: `.claude/commands/project/roadmap.md` contains JavaScript code instead of markdown command definition.

**Impact**: Cannot add flag summary prompt to roadmap command.

**Workaround**: Skip roadmap integration for now.

**Fix**: Restore roadmap.md from backup or regenerate.

---

## Future Enhancements

1. **Auto-fix mode**: Option to automatically run infrastructure commands instead of just prompting
2. **Silent mode**: Suppress prompts with `--no-prompts` flag
3. **Custom thresholds**: Allow configuring detection thresholds (e.g., branch age)
4. **GitHub Actions integration**: Run detection in CI and comment on PRs
5. **Dashboard**: Visual display of all infrastructure needs

---

## References

- Detection script: `.spec-flow/scripts/bash/detect-infrastructure-needs.sh`
- Infrastructure commands: `.claude/commands/infrastructure/`
- Phase commands: `.claude/commands/phases/`
- Deployment commands: `.claude/commands/deployment/`

---

**Last Updated**: 2025-11-12
**Version**: 1.0.0
**Status**: ✅ Production Ready

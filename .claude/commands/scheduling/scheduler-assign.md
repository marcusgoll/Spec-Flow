# /scheduler.assign

**Purpose**: Assign epic to agent with WIP enforcement (max 1 epic per agent).

**Phase**: Implementation (parallel mode)

**Inputs**:
- Epic name (required) - Must be in `ContractsLocked` state
- Agent name (optional) - Defaults to current user

**Outputs**:
- Updated `wip-tracker.yaml` with epic assignment
- Updated `workflow-state.yaml` with epic state transition
- Assignment confirmation or queue notification

## Command Specification

### Synopsis

```bash
/scheduler.assign <epic-name> [--agent AGENT]
```

### Description

Assigns an epic to an agent for implementation, enforcing WIP limits (one epic per agent). If the agent's WIP slot is occupied, the epic is queued and will auto-assign when the slot becomes available.

**WIP Enforcement**:
- Each agent can work on max 1 epic at a time
- Prevents context switching and reduces coordination tax
- Automatic queuing when all slots occupied
- Queue operates FIFO (first in, first out)

### Prerequisites

- Epic must be in `ContractsLocked` state
- Contracts verified with `/contract.verify`
- Golden fixtures refreshed with `/fixture.refresh`

### Arguments

| Argument    | Required | Description                                    |
| ----------- | -------- | ---------------------------------------------- |
| `epic-name` | Yes      | Epic identifier (e.g., `epic-auth-api`)        |
| `--agent`   | No       | Agent name (defaults to current user)          |

### Examples

**Assign epic to current user**:
```bash
/scheduler.assign epic-auth-api
```

**Assign epic to specific agent**:
```bash
/scheduler.assign epic-search-api --agent backend-agent
```

**Output (success)**:
```
✅ Assigned epic-auth-api to backend-agent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic assigned successfully

  Epic: epic-auth-api
  Agent: backend-agent
  State: ContractsLocked → Implementing

  WIP Slots: 1/2 occupied

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next steps:
  1. Register feature flag: /flag.add epic_auth_api_enabled --reason "Epic in progress"
  2. Start implementing tasks (max 24h branch lifetime)
  3. Merge daily to main behind feature flag
```

**Output (slot occupied - queued)**:
```
⚠️ WIP slot occupied

  Agent: backend-agent
  Current epic: epic-user-profile
  Max epics per agent: 1

ℹ️  Queued epic-auth-api (waiting for backend-agent to finish current epic)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic queued. Will auto-assign when backend-agent completes epic-user-profile.

Alternatives:
  • Park current epic: /scheduler.park epic-user-profile --reason "Switching priorities"
  • Assign to different agent: /scheduler.assign epic-auth-api --agent frontend-agent
```

## State Transitions

### Success Path

```
ContractsLocked → Implementing
```

**Effects**:
1. Epic state updated to `Implementing` in `workflow-state.yaml`
2. Agent record created/updated in `wip-tracker.yaml`
3. WIP slot marked as occupied

### Queued Path

```
ContractsLocked → ContractsLocked (queued)
```

**Effects**:
1. Epic added to `queued_epics` in `wip-tracker.yaml`
2. Notification set for when slot becomes available
3. Epic remains in `ContractsLocked` state

## Error Conditions

| Error                        | Cause                                   | Resolution                              |
| ---------------------------- | --------------------------------------- | --------------------------------------- |
| Epic not found               | Epic not in `workflow-state.yaml`       | Run `/plan` to generate epic breakdown  |
| Epic not in ContractsLocked  | State is Planned or Implementing        | Run `/contract.verify` to lock contracts|
| yq not installed             | yq CLI missing                          | Install: https://github.com/mikefarah/yq|

## Integration with Workflow

### Called by `/implement --parallel`

When parallel implementation mode is enabled:

```bash
/implement --parallel
```

**Workflow**:
1. Parse `plan.md` for epic breakdowns
2. Lock contracts for all epics: `/contract.verify`
3. For each epic in dependency order:
   - Call `/scheduler.assign <epic-name> --agent <specialist>`
   - Launch specialist agent (backend, frontend, etc.)
4. Monitor progress in `wip-tracker.yaml`

### Related Commands

- **`/scheduler.park`**: Park current epic, release WIP slot
- **`/scheduler.list`**: Show all epics with WIP status
- **`/scheduler.dashboard`**: Real-time WIP dashboard
- **`/contract.verify`**: Lock contracts before assignment

## Files Modified

- `.spec-flow/memory/wip-tracker.yaml` - Agent assignments and WIP tracking
- `.spec-flow/memory/workflow-state.yaml` - Epic state transitions

## WIP Tracker Format

```yaml
agents:
  - name: backend-agent
    current_epic: epic-auth-api
    state: Implementing
    started: 2025-11-10T14:30:00Z

queued_epics:
  - name: epic-search-api
    queued_at: 2025-11-10T16:00:00Z
    waiting_for_agent: backend-agent

limits:
  max_epics_per_agent: 1
  auto_park_after_hours: 4
```

## Best Practices

1. **Check state first**: Ensure epic is `ContractsLocked` before assignment
2. **One epic per agent**: Respect WIP limits to avoid context switching
3. **Use feature flags**: Register flag immediately after assignment
4. **Daily merges**: Keep branch age <24h with trunk-based development
5. **Park if blocked**: Use `/scheduler.park` if waiting >4h on external dependency

## Troubleshooting

**Epic not found**:
```bash
# Check workflow-state.yaml for epic
cat .spec-flow/memory/workflow-state.yaml

# If missing, regenerate plan
/plan
```

**WIP slot always occupied**:
```bash
# Check current assignments
/scheduler.list

# Park stale epic if needed
/scheduler.park <epic-name> --reason "No progress in 4h"
```

**yq not installed**:
```bash
# macOS
brew install yq

# Linux
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Windows
choco install yq
```

## References

- Epic State Machine: `.spec-flow/memory/epic-states.md`
- WIP Tracker Schema: `.spec-flow/memory/wip-tracker.yaml`
- Team Topologies (WIP Limits): https://teamtopologies.com/
- Trunk-Based Development: https://trunkbaseddevelopment.com/

---

**Implementation**: `.spec-flow/scripts/bash/scheduler-assign.sh`

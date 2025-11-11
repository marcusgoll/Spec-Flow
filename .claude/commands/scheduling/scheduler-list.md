# /scheduler.list

**Purpose**: List all epics with current state and WIP status.

**Phase**: Implementation (parallel mode)

**Inputs**:
- State filter (optional) - Show only epics in specific state

**Outputs**:
- Summary of all epics grouped by state
- WIP slot utilization
- Queue status

## Command Specification

### Synopsis

```bash
/scheduler.list [--state STATE]
```

### Description

Displays a summary of all epics in the workflow, grouped by state (Implementing, ContractsLocked, Parked, Review, etc.). Shows agent assignments, progress, and WIP slot utilization.

**Use Cases**:
- Check what epics are currently active
- Find available epics to work on
- Monitor parked epics awaiting resolution
- See WIP slot utilization

### Arguments

| Argument  | Required | Description                                    |
| --------- | -------- | ---------------------------------------------- |
| `--state` | No       | Filter by state (Implementing, Parked, etc.)   |

### Examples

**List all epics**:
```bash
/scheduler.list
```

**Output**:
```
Epic State Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Implementing (2):
  • epic-auth-api (backend-agent)
    Progress: 6/8 tasks (75%)
    Time: 3h 15m

  • epic-auth-ui (frontend-agent)
    Progress: 3/6 tasks (50%)
    Time: 2h 45m

Contracts Locked (1):
  • epic-search-api (Queued)
    Waiting: 1h 30m

Parked (1):
  • epic-payment-integration
    Reason: Waiting for Stripe API keys from DevOps
    Blocked by: devops-team
    Parked: 18h

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WIP Status: 2/2 slots occupied
Queued: 1 epics waiting for slots
```

**Filter by state**:
```bash
/scheduler.list --state Parked
```

**Output**:
```
Epic State Summary (Filter: Parked)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Parked (1):
  • epic-payment-integration
    Reason: Waiting for Stripe API keys from DevOps
    Blocked by: devops-team
    Parked: 18h

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WIP Status: 1/2 slots occupied
```

## Epic States

| State             | Description                                       |
| ----------------- | ------------------------------------------------- |
| `Planned`         | Epic defined, contracts not yet designed          |
| `ContractsLocked` | Contracts locked, ready for implementation        |
| `Implementing`    | Active development with agent assigned            |
| `Parked`          | Blocked by external dependency                    |
| `Review`          | Code complete, quality gates running              |
| `Integrated`      | Merged to main, feature flag enabled              |
| `Released`        | Feature flag retired, fully deployed              |

## WIP Status

**Slot Utilization**:
- Shows how many agents are currently working on epics
- Max 1 epic per agent (WIP limit)
- Helps identify capacity for new epics

**Queue Status**:
- Number of epics waiting for WIP slots
- Queue operates FIFO (first in, first out)

## Integration with Workflow

### Daily Stand-up

```bash
# Quick status check
/scheduler.list

# Focus on blocked work
/scheduler.list --state Parked
```

**Output helps answer**:
- What did I work on yesterday? (Implementing epics)
- What am I working on today? (My assigned epic)
- What's blocking me? (Parked epics)

### Sprint Planning

```bash
# Check available capacity
/scheduler.list

# If WIP slots occupied:
#   → Plan smaller epics
#   → Wait for current epics to complete

# If WIP slots available:
#   → Assign more epics from ContractsLocked
```

### Related Commands

- **`/scheduler.assign`**: Assign epic to agent
- **`/scheduler.park`**: Park epic when blocked
- **`/scheduler.dashboard`**: Real-time dashboard with refresh

## Files Read

- `.spec-flow/memory/workflow-state.yaml` - Epic states and progress
- `.spec-flow/memory/wip-tracker.yaml` - Agent assignments and WIP tracking

## Error Conditions

| Error          | Cause                          | Resolution              |
| -------------- | ------------------------------ | ----------------------- |
| No epics found | workflow-state.yaml missing    | Run `/plan` first       |
| yq not found   | yq CLI not installed           | Install yq              |

## Best Practices

1. **Check daily**: Run at start of day to see current state
2. **Monitor parked**: Review parked epics for resolution opportunities
3. **Track progress**: Compare time elapsed vs estimated time
4. **Identify bottlenecks**: High parking time indicates blockers

## Troubleshooting

**No epics shown**:
```bash
# Check workflow-state.yaml exists
ls .spec-flow/memory/workflow-state.yaml

# If missing, generate plan
/plan
```

**WIP status inaccurate**:
```bash
# Verify wip-tracker.yaml
cat .spec-flow/memory/wip-tracker.yaml

# Resync if needed (remove stale agents)
yq eval 'del(.agents[] | select(.current_epic == null))' -i .spec-flow/memory/wip-tracker.yaml
```

**Time calculations wrong**:
```bash
# Check system timezone
date
timedatectl status

# Timestamps in YAML should be ISO 8601 with timezone
# Example: 2025-11-10T14:30:00Z
```

## References

- Epic State Machine: `.spec-flow/memory/epic-states.md`
- WIP Tracker Schema: `.spec-flow/memory/wip-tracker.yaml`
- Workflow State Schema: `.spec-flow/memory/workflow-state.yaml`

---

**Implementation**: `.spec-flow/scripts/bash/scheduler-list.sh`

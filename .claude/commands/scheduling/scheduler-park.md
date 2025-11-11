# /scheduler.park

**Purpose**: Park epic due to blocker, release WIP slot for other work.

**Phase**: Implementation (parallel mode)

**Inputs**:
- Epic name (required) - Must be in `Implementing` state
- Reason (required) - Why epic is blocked
- Blocked by (optional) - Who/what is causing the blocker

**Outputs**:
- Updated `wip-tracker.yaml` with parked epic
- Updated `workflow-state.yaml` with state transition
- WIP slot released
- Next queued epic auto-assigned (if any)

## Command Specification

### Synopsis

```bash
/scheduler.park <epic-name> --reason <text> [--blocked-by ENTITY]
```

### Description

Parks an epic that is blocked by an external dependency, releasing the agent's WIP slot for other work. Parked epics can be resumed when the blocker is resolved.

**Automatic Parking**:
- Triggered if no commits detected for >4h during business hours
- CI repeatedly failing (>3 attempts in 2h)
- Agent manually requests parking

**Benefits**:
- Prevents agents from being idle while waiting on blockers
- Maintains team velocity by enabling work on unblocked epics
- Tracks blocker reasons for bottleneck analysis

### Prerequisites

- Epic must be in `Implementing` state
- Epic must be assigned to an agent

### Arguments

| Argument       | Required | Description                                      |
| -------------- | -------- | ------------------------------------------------ |
| `epic-name`    | Yes      | Epic identifier to park                          |
| `--reason`     | Yes      | Why epic is blocked (free text)                  |
| `--blocked-by` | No       | Entity causing blocker (team, service, approval) |

### Examples

**Park due to external API**:
```bash
/scheduler.park epic-payment-integration --reason "Waiting for Stripe API keys from DevOps"
```

**Park due to approval**:
```bash
/scheduler.park epic-auth-api --reason "DBA approval needed for RLS policies" --blocked-by dba-team
```

**Output**:
```
⚠️ Parked epic-payment-integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic parked

  Epic: epic-payment-integration
  Agent: backend-agent (WIP slot released)
  Reason: Waiting for Stripe API keys from DevOps
  Blocked by: devops-team
  State: Implementing → Parked

  WIP Slots: 0/2 occupied

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Auto-assigning next queued epic: epic-search-api

✅ Assigned epic-search-api to backend-agent
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

When blocker resolved:
  /scheduler.assign epic-payment-integration

Or work on different epic:
  /scheduler.list  # View available epics
```

## State Transitions

### Success Path

```
Implementing → Parked
```

**Effects**:
1. Epic state updated to `Parked` in `workflow-state.yaml`
2. Epic added to `parked_epics` in `wip-tracker.yaml`
3. Agent's WIP slot marked as available
4. Next queued epic auto-assigned (if queue not empty)

## Automatic Parking (Future Enhancement)

**Trigger Conditions**:
1. **No commits for >4h**: During business hours (9am-6pm)
2. **CI failing repeatedly**: >3 failures in 2h with no fixes
3. **Manual request**: Agent explicitly calls `/scheduler.park`

**Implementation**:
```bash
# Background job (runs hourly via cron)
.spec-flow/scripts/bash/auto-park-checker.sh
```

**Check Logic**:
```bash
# For each epic in Implementing state:
1. Check last commit timestamp
2. If >4h ago during business hours → park
3. Notify agent via Slack/email
4. Log parking reason: "Auto-parked: no progress detected"
```

## Error Conditions

| Error                    | Cause                             | Resolution                        |
| ------------------------ | --------------------------------- | --------------------------------- |
| Epic not found           | Not in `workflow-state.yaml`      | Check epic name spelling          |
| Epic not in Implementing | State is Parked or ContractsLocked| Only active epics can be parked   |
| Reason missing           | `--reason` argument not provided  | Add reason explaining blocker     |
| yq not installed         | yq CLI missing                    | Install yq                        |

## Integration with Workflow

### Called by Automatic Parking Job

```bash
# Cron job: every hour during business hours
0 9-18 * * * cd /project && .spec-flow/scripts/bash/auto-park-checker.sh
```

**auto-park-checker.sh**:
```bash
#!/usr/bin/env bash
# Check all Implementing epics for stale progress

for epic in $(get_implementing_epics); do
  agent=$(get_epic_agent "$epic")
  last_commit=$(git log -1 --format=%ct "$agent"/* 2>/dev/null || echo 0)
  now=$(date +%s)
  hours_idle=$(( (now - last_commit) / 3600 ))

  if [[ $hours_idle -gt 4 ]]; then
    /scheduler.park "$epic" \
      --reason "Auto-parked: no commits for ${hours_idle}h" \
      --blocked-by "unknown"

    notify_agent "$agent" "Epic $epic auto-parked due to inactivity"
  fi
done
```

### Related Commands

- **`/scheduler.assign`**: Resume parked epic when blocker resolved
- **`/scheduler.list`**: Show all parked epics
- **`/scheduler.dashboard`**: Real-time view of parked/blocked work

## Files Modified

- `.spec-flow/memory/wip-tracker.yaml` - Adds epic to `parked_epics`
- `.spec-flow/memory/workflow-state.yaml` - Updates epic state to `Parked`

## WIP Tracker Format (After Parking)

```yaml
agents:
  - name: backend-agent
    current_epic: null
    state: Idle
    last_parked: 2025-11-10T16:30:00Z

parked_epics:
  - name: epic-payment-integration
    reason: "Waiting for Stripe API keys from DevOps"
    parked_at: 2025-11-10T16:30:00Z
    blocked_by: devops-team
    notify_when_resolved: backend-agent

queued_epics:
  - name: epic-search-api
    queued_at: 2025-11-10T16:00:00Z
    waiting_for_agent: backend-agent
```

## Resuming Parked Epics

**When blocker resolved**:

```bash
# 1. Verify blocker is resolved
# 2. Resume epic via scheduler
/scheduler.assign epic-payment-integration

# Output:
# ✅ Assigned epic-payment-integration to backend-agent
# State: Parked → Implementing
```

**Blocker resolution tracking**:
- Manual: Developer confirms blocker resolved
- Automated (future): Webhook from blocking service (e.g., Stripe API key provisioned)

## DORA Metrics Impact

**Parking Time Tracking**:
- Epic-level metric: Time in `Parked` state
- Aggregated metric: Average parking time per sprint
- Bottleneck detection: Most common blockers

**Dashboard**:
```bash
/metrics.dora --parking
```

**Output**:
```
Parking Time Analysis (Last Sprint)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Parked Epics: 3
Average Parking Time: 18h

Top Blockers:
  1. devops-team (2 epics, 36h total)
  2. dba-team (1 epic, 12h)

Impact on Lead Time:
  • Without parking: 48h average lead time
  • With parking overhead: 66h (+37%)

Recommendations:
  • Reduce DevOps blockers (2x occurrences)
  • Pre-provision API keys before sprint starts
```

## Best Practices

1. **Park early**: Don't wait >4h if blocker is known
2. **Specific reasons**: Help identify patterns ("Waiting for API keys" better than "Blocked")
3. **Track blocker entity**: Enables bottleneck analysis
4. **Resume quickly**: Check parked epics daily for resolution
5. **Pre-plan**: Identify potential blockers during planning to minimize parking

## Troubleshooting

**Epic not found**:
```bash
# Check workflow-state.yaml
cat .spec-flow/memory/workflow-state.yaml | grep epic-name

# If missing, epic may not be assigned yet
/scheduler.list
```

**Parked epic not auto-resuming**:
```bash
# Check parked list
/scheduler.list

# Manually resume
/scheduler.assign epic-name
```

**Auto-parking too aggressive**:
```bash
# Adjust threshold in wip-tracker.yaml
yq eval '.limits.auto_park_after_hours = 8' -i .spec-flow/memory/wip-tracker.yaml
```

## References

- Epic State Machine: `.spec-flow/memory/epic-states.md`
- WIP Tracker Schema: `.spec-flow/memory/wip-tracker.yaml`
- DORA Metrics (Lead Time): https://dora.dev/
- Kanban WIP Limits: https://www.atlassian.com/agile/kanban/wip-limits

---

**Implementation**: `.spec-flow/scripts/bash/scheduler-park.sh`

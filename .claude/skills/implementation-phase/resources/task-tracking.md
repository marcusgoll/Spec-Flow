# Task Tracking

## Update NOTES.md After Each Task

**Format**:
```markdown
## Implementation Progress

✅ T001: Create database schema (2025-11-10 10:30)
✅ T002: Create API routes (2025-11-10 11:45)
⏳ T003: Create UI components (in progress)
⏸️ T004: Implement business logic (blocked: waiting for T001)
```

---

## Velocity Tracking

**Automatic** (if using task-tracker script):
```bash
.spec-flow/scripts/bash/calculate-task-velocity.sh
```

**Output**:
```
Progress Summary:
- Total Tasks: 28
- Completed: 12 (43%)
- Average Time: 45 min/task
- Completion Rate: 3.5 tasks/day
- ETA: 2025-11-12 16:00
```

**See [../reference.md](../reference.md#task-tracking) for complete tracking guide**

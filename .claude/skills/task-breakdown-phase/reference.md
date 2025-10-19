# Task Breakdown Phase Reference Guide

## Task Sizing Guidelines

**Ideal task size**: 0.5-1 day (4-8 hours)

**Too large** (>1 day):
- Break into subtasks
- Each subtask should be independently testable

**Too small** (<0.5 day):
- Consider grouping related small tasks

## Acceptance Criteria Template

```markdown
**Acceptance Criteria**:
- ✓ [Testable condition 1]
- ✓ [Testable condition 2]
- ✓ [Performance/quality metric if applicable]
```

## Sequencing Patterns

1. **Infrastructure first**: Models, schemas, migrations
2. **Core logic**: Business logic, services
3. **API/Interfaces**: Controllers, routes
4. **UI**: Frontend components
5. **Integration**: Connect all layers
6. **Polish**: Error handling, validation

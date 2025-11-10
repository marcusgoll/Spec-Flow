# Complexity Estimation

**Purpose**: Predict task count based on feature scope (target: 20-30 tasks).

---

## Estimation Formula

**Task count = Components × Layers × 3 (TDD triplet)**

**Example**:
```
Feature: User authentication
- Components: 2 (User model, Auth service)
- Layers: 3 (Database, API, Frontend)
- TDD multiplier: 3 (Write test, Implement, Refactor)

Total: 2 × 3 × 3 = 18 tasks (within range)
```

---

## Complexity Tiers

**Simple** (15-20 tasks):
- Single entity CRUD
- No external integrations
- Basic UI

**Medium** (20-25 tasks):
- 2-3 entities with relationships
- 1-2 external APIs
- Standard UI components

**Complex** (25-30 tasks):
- 3+ entities with many-to-many
- Multiple external integrations
- Custom UI components

---

## Adjustment Factors

Add tasks for:
- **Database migrations**: +2 tasks per migration
- **External API integration**: +3 tasks per integration
- **Authentication/Authorization**: +5 tasks
- **File uploads**: +3 tasks
- **Real-time features (WebSocket)**: +5 tasks

**See [../reference.md](../reference.md#estimation) for detailed examples**

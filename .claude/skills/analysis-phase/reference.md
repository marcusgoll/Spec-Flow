# Analysis Phase Reference Guide

## Cross-Artifact Consistency Matrix

**Check alignment across**:
| Artifact | Check Against | What to Validate |
|----------|---------------|------------------|
| Spec requirements | Plan components | Each requirement has implementation plan |
| Plan components | Tasks | Each component broken into tasks |
| Tasks acceptance criteria | Spec success criteria | Criteria align with requirements |

## Breaking Change Detection

**Patterns indicating breaking changes**:
- API endpoint signature changes
- Database schema modifications
- Required field additions
- Authentication/authorization changes

## Impact Assessment Rubric

| Change Type | Impact Level | Examples |
|-------------|--------------|----------|
| New feature (no dependencies) | Low | Standalone component |
| Feature with integrations | Medium | Connects to existing systems |
| Breaking API/schema change | High | Requires migration, versioning |

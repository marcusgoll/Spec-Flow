# Roadmap Integration Reference Guide

## Roadmap Structure

**Sections**:
1. **Backlog** - Brainstormed, not prioritized
2. **Prioritized** - Ready for spec work
3. **In Progress** - Spec exists, work started
4. **Shipped** - Production deployed

## State Transition Rules

| From | To | Trigger |
|------|-----|---------|
| Backlog | Prioritized | Manual prioritization |
| Prioritized | In Progress | `/specify` creates spec |
| In Progress | Shipped | `/phase-2-ship` completes |
| Any | Backlog | Manual deprioritization |

## Linking Conventions

**In Progress entries**:
```markdown
### feature-slug
[Description]
**Branch**: `feature/NNN-feature-slug`
**Spec**: `specs/NNN-feature-slug/spec.md`
```

**Shipped entries**:
```markdown
### feature-slug
[Description]
**Production**: https://app.example.com/feature
**Ship Report**: `specs/NNN-feature-slug/ship-report.md`
**Shipped**: YYYY-MM-DD
```

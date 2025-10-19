# Planning Phase Reference Guide

## Reuse Detection Strategy

**Before designing new code**:
1. Search for similar features: `grep -r "pattern" codebase/`
2. Review base classes and utilities
3. Check design patterns in use

**Reuse checklist**:
- [ ] Base model classes
- [ ] Controller/handler patterns
- [ ] Validation utilities
- [ ] Common UI components

## Research Depth Matrix

| Feature Complexity | Research Tools | Focus Areas |
|-------------------|----------------|-------------|
| Simple (CRUD) | 3-5 tools | Existing models, controllers |
| Standard (with logic) | 5-8 tools | Patterns, utilities, similar features |
| Complex (multi-system) | 8-12 tools | Architecture, integrations, patterns |

## Design Pattern Catalog

**Common patterns to reuse**:
- Repository pattern for data access
- Service layer for business logic
- Factory pattern for object creation
- Observer pattern for events
- Strategy pattern for algorithms

_Expand with actual patterns as features are implemented._

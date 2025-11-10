# Architecture Planning

**Purpose**: Design component structure, layers, and patterns for the feature.

---

## Component Design

### Identify Components

**Backend**:
- Models (data layer)
- Services (business logic)
- Controllers (API layer)
- Middleware (cross-cutting concerns)

**Frontend**:
- Pages (routes)
- Components (UI building blocks)
- Hooks (reusable logic)
- Services (API client)

---

## Layered Architecture

```
┌─────────────────────┐
│   Presentation      │ (Controllers, API routes)
├─────────────────────┤
│   Business Logic    │ (Services, use cases)
├─────────────────────┤
│   Data Access       │ (Models, repositories)
└─────────────────────┘
```

**Key principle**: Each layer only depends on layer below

**See [../reference.md](../reference.md#architecture) for complete patterns**

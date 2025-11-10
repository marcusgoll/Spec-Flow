# Code Reuse Analysis

**Purpose**: Search existing codebase for similar functionality before designing new components (anti-duplication).

---

## Search Patterns

### Pattern 1: Similar Feature Names
```bash
# Search for existing similar features
grep -r "authentication\|login\|auth" src/
grep -r "payment\|checkout\|order" src/
```

### Pattern 2: Utility Functions
```bash
# Search for utility functions
grep -r "function.*format\|function.*validate" src/
grep -r "class.*Helper\|class.*Util" src/
```

### Pattern 3: Data Models
```bash
# Search for existing entities
grep -r "class.*User\|interface.*User" src/
grep -r "model.*Student\|schema.*Student" src/
```

---

## Reuse Checklist

Before designing any component, search for:
- [ ] Similar features or modules
- [ ] Reusable utility functions
- [ ] Existing data models to extend
- [ ] Common UI components
- [ ] API endpoint patterns

**Expected**: 5-15 reuse opportunities per feature

**See [../reference.md](../reference.md#code-reuse) for complete search patterns**

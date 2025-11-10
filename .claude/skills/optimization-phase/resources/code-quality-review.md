# Code Quality Review

**Purpose**: Check for DRY violations, test coverage, and code smells.

---

## Test Coverage

**Check coverage**:
```bash
npm test -- --coverage
# Required: ≥80% (lines, branches, functions)
```

**Results**:
```
Statements   : 85.2% ✅ (target: 80%)
Branches     : 78.5% ❌ (target: 80%)
Functions    : 92.1% ✅
Lines        : 84.8% ✅
```

---

## DRY Violations (Code Duplication)

**Search for duplicate code**:
```bash
# Find similar function patterns
grep -r "function.*calculate" src/ | wc -l
# If >3 similar functions, potential duplication
```

**Max allowed**: 3 instances of similar code

---

## Code Smells

- [ ] Long functions (>50 lines)
- [ ] Deep nesting (>3 levels)
- [ ] Magic numbers (no constants)
- [ ] Commented-out code
- [ ] TODOs without tickets

**See [../reference.md](../reference.md#code-quality) for complete checklist**

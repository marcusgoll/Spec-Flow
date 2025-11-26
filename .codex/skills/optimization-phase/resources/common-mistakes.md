# Common Mistakes

## 🚫 Performance Target Missed

**Problem**: Not testing performance before claiming done

**Bad**:
```
Assumed API is fast enough (no testing)
Deploy to production
Users complain about slow API ❌
```

**Good**:
```bash
# Test API performance
for i in {1..10}; do curl -w "%{time_total}\n" -o /dev/null -s API_URL; done
# Result: p50=180ms, p95=420ms ✅ (meets targets)
```

---

## 🚫 Accessibility Failures

**Problem**: Skipping accessibility audit for UI features

**Bad**:
```
Feature has UI
No accessibility testing ❌
Fails WCAG 2.1 AA compliance
```

**Good**:
```bash
# Run Lighthouse CI
lhci autorun --url=http://localhost:3000
# Accessibility score: 94/100 ✅
```

---

## 🚫 Security Vulnerabilities

**Problem**: Not running npm audit before deployment

**Bad**:
```
npm install new-library
No security check ❌
Deploy with 3 critical vulnerabilities
```

**Good**:
```bash
npm audit --production
# 0 vulnerabilities ✅
```

---

## 🚫 Low Test Coverage

**Problem**: Claiming 80% coverage without proof

**Bad**:
```
"I think we have enough tests" ❌
(Actual coverage: 45%)
```

**Good**:
```bash
npm test -- --coverage
# Statements: 85% ✅
# Branches: 82% ✅
```

**See [../reference.md](../reference.md#common-mistakes) for complete list**

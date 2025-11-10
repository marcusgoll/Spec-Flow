# Security Review

**Purpose**: Scan for vulnerabilities in dependencies and code.

---

## Dependency Scanning

**npm audit**:
```bash
npm audit --production
# Required: 0 critical, 0 high vulnerabilities
```

**Fix vulnerabilities**:
```bash
npm audit fix
# Or manually update package.json
```

---

## Code Security Checks

**SQL Injection**:
- [ ] Use parameterized queries
- [ ] Never concatenate user input into SQL

**XSS Prevention**:
- [ ] Sanitize user input before rendering
- [ ] Use framework escaping (React auto-escapes)

**Authentication**:
- [ ] Passwords hashed (bcrypt, argon2)
- [ ] JWT tokens signed securely
- [ ] Session tokens have expiration

**Authorization**:
- [ ] Check permissions before actions
- [ ] No client-side authorization only

---

## Results Format

```markdown
## Security Results

### Dependency Scan
- npm audit: 0 critical, 1 moderate ⚠️
  - lodash@4.17.15 (Prototype Pollution) - Upgrade to 4.17.21

### Code Review
- SQL injection: ✅ All queries parameterized
- XSS: ✅ React auto-escapes
- Auth: ✅ bcrypt used, JWT signed
- Authorization: ✅ Server-side checks present
```

**See [../reference.md](../reference.md#security) for OWASP Top 10 checklist**

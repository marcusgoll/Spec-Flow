# Commit Strategy

## Small, Frequent Commits

**Frequency**: After each task triplet (RED-GREEN-REFACTOR)

**Format**:
```bash
git add .
git commit -m "feat: add student progress calculation (T008-T010)

- Write tests for progress calculation (T008)
- Implement StudentProgressService (T009)
- Refactor with validation and rounding (T010)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Commit Message Template

```
<type>: <subject> (T###-T###)

<body - what changed and why>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

**See [../reference.md](../reference.md#commit-strategy) for complete guide**

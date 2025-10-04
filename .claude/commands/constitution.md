---
description: Update project constitution and sync dependent templates (maintain DONT_DO.md with failures)
---

Update constitution: $ARGUMENTS

## WORKFLOW

1. **Load** `.spec-flow/memory/constitution.md`
2. **Parse** version (default 1.0.0 if missing)
3. **Apply changes** + semantic versioning:
   - MAJOR: Removed principle, added mandatory requirement
   - MINOR: Added principle, expanded guidance
   - PATCH: Fixed typo, updated date
4. **Smart template sync** (load only affected files):
   - Planning changes  plan-template.md
   - Testing changes  tasks-template.md
   - Spec requirements  spec-template.md
   - Update references: "See constitution.md Principle_Name"
5. **Validate**:
   - No unexplained placeholders
   - Version matches semver
   - Dates in ISO format (YYYY-MM-DD)
   - Principles declarative and testable
   - Cross-references valid
6. **Idempotency**: Hash content, skip if unchanged

## OUTPUT

Write to `.spec-flow/memory/constitution.md` with Sync Impact Report as HTML comment.

**Summary:**
```
 Constitution: v[X.Y.Z] (MAJOR/MINOR/PATCH)
 Amended: [YYYY-MM-DD]

 Sync Impact:
- plan-template.md: Updated Quality Gates reference
- tasks-template.md: Added coverage from Testing Principle

 Next: Review changes, commit
```

## CONSTRAINTS

- Constitution is SSOT (never duplicate rules in templates)
- Keep file <100 lines
- Update DONT_DO.md with discovered anti-patterns
- Operate on existing constitution.md only (never create new)


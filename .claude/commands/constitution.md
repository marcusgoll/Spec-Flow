---
description: Configure or update project constitution with interactive setup wizard
---

## MODE DETECTION

**If $ARGUMENTS is empty AND constitution has default values (80%, 200ms, 2s):**
- Launch interactive Q&A wizard (see INTERACTIVE SETUP below)

**If $ARGUMENTS provided:**
- Apply update: $ARGUMENTS (see UPDATE WORKFLOW below)

**If constitution already customized:**
- Ask: "Constitution already configured. Update it? (describe changes)"

---

## INTERACTIVE SETUP

**Purpose**: First-time configuration of engineering standards.

**Workflow**:

1. **Welcome message**:
   ```
   Let's customize your engineering constitution!

   I'll ask about key standards for your project.
   Current defaults: 80% test coverage, <200ms API, <2s page load
   ```

2. **Project type confirmation**:
   - "What type of project is this?"
   - Options: Web App, API/Backend, Mobile App, CLI Tool, Library/Package, Other
   - Auto-detect from project structure if possible

3. **Testing standards** (if applicable):
   - "What's your minimum test coverage requirement? (current: 80%)"
   - Validate: 0-100, suggest 70-90 for most projects
   - "What types of tests are required?"
     - Unit tests (always recommended)
     - Integration tests (API/Backend)
     - E2E tests (Web/Mobile)

4. **Performance targets** (if applicable):
   - For API/Backend: "API response time target? (current: <200ms p50, <500ms p95)"
   - For Web: "Page load target? (current: <2s First Contentful Paint, <3s LCP)"
   - For CLI: "Command execution time target? (suggest: <1s for interactive commands)"

5. **Accessibility** (for Web/Mobile):
   - "WCAG compliance level? (AA recommended, AAA strict, A minimum)"
   - Default to Level AA

6. **Additional principles**:
   - "Any project-specific principles to add? (e.g., 'Mobile-first design', 'Offline-first architecture')"
   - Add as custom principle if provided

7. **Apply changes**:
   - Show summary of all changes
   - Update constitution.md
   - Bump version to 1.1.0 (MINOR: expanded guidance)
   - Update last modified date

---

## UPDATE WORKFLOW

1. **Load** `.spec-flow/memory/constitution.md`
2. **Parse** version (default 1.0.0 if missing)
3. **Apply changes** + semantic versioning:
   - MAJOR: Removed principle, added mandatory requirement
   - MINOR: Added principle, expanded guidance
   - PATCH: Fixed typo, updated date
4. **Smart template sync** (load only affected files):
   - Planning changes -> plan-template.md
   - Testing changes -> tasks-template.md
   - Spec requirements -> spec-template.md
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
✓ Constitution: v[X.Y.Z] (MAJOR/MINOR/PATCH)
✓ Amended: [YYYY-MM-DD]

✓ Sync Impact:
- plan-template.md: Updated Quality Gates reference
- tasks-template.md: Added coverage from Testing Principle

→ Next: Review changes, commit
```

## CONSTRAINTS

- Constitution is SSOT (never duplicate rules in templates)
- Keep file <100 lines
- Update DONT_DO.md with discovered anti-patterns
- Operate on existing constitution.md only (never create new)

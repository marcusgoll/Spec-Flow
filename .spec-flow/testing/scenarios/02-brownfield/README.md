# Scenario 2: Brownfield Project

## Purpose

Test workflow on existing codebase with auto-scan capabilities for technology detection.

## Tests

### 1. Directory Structure Validation

- Verifies scenario directory exists
- **Expected**: Directory present

### 2. Fixture Files Present

- Checks for package.json
- Checks for docker-compose.yml
- **Expected**: Mock existing project files present

### 3. Anti-Duplication Skill Validation

- Validates anti-duplication skill exists
- **Expected**: Skill file properly structured

## Expected Artifacts

Fixture files (simulating existing project):

```
fixtures/
├── package.json          # Mock Node.js project
├── docker-compose.yml    # Mock Docker setup
└── migrations/           # Mock database migrations
    └── 001_create_users.sql
```

After running `/init-project`:

```
02-brownfield/
├── docs/
│   └── project/
│       ├── overview.md (with detected tech)
│       ├── system-architecture.md
│       ├── tech-stack.md (populated from package.json)
│       ├── data-architecture.md (ERD from migrations)
│       └── ...
└── .spec-flow/
    └── memory/
        └── state.yaml
```

After running `/feature "Add password reset"`:

```
specs/001-password-reset/
├── spec.md (with reuse analysis)
├── plan.md (referencing existing auth code)
├── tasks.md
└── NOTES.md
```

## Manual Test Steps

1. Copy fixtures to this directory
2. Run `/init-project` (simulated)
3. Verify technology auto-detection from package.json
4. Run `/feature "Add password reset"` (simulated)
5. Verify anti-duplication finds existing auth patterns
6. Verify deployment model detection (staging-prod or direct-prod)

## Success Criteria

- ✓ Fixture files exist and are accessible
- ✓ Anti-duplication skill properly configured
- ✓ Technology detection would work correctly
- ✓ Reuse analysis would identify existing patterns
- ✓ No errors during validation

## Notes

This scenario simulates a brownfield project where:

- Existing `package.json` indicates tech stack
- Existing `migrations/` indicate database schema
- Existing `docker-compose.yml` indicates deployment setup
- Anti-duplication prevents code duplication

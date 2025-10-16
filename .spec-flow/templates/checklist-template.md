# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [Brief description of what this checklist covers]
**Created**: [DATE]
**Feature**: [Link to spec.md or relevant documentation]
**Status**: [Not Started | In Progress | Complete]

---

## Pre-flight

- [ ] CHK001 Feature branch created from main (`[NNN-feature-slug]`)
- [ ] CHK002 All dependencies installed and up to date
- [ ] CHK003 Development environment configured correctly
- [ ] CHK004 Required environment variables set (see `spec.md` Deployment Considerations)

---

## Implementation

- [ ] CHK005 All tasks from `tasks.md` marked complete
- [ ] CHK006 Code follows repository conventions (see `CLAUDE.md`)
- [ ] CHK007 No hardcoded values (use config/env vars)
- [ ] CHK008 Error handling implemented for all user-facing operations
- [ ] CHK009 Logging added for key operations and errors

---

## Testing

- [ ] CHK010 All unit tests passing
- [ ] CHK011 Integration tests passing (if applicable)
- [ ] CHK012 Manual testing completed for all user stories
- [ ] CHK013 Edge cases tested (see `spec.md` Edge Cases)
- [ ] CHK014 Error states tested (validation, network, auth failures)

---

## Quality

- [ ] CHK015 Linting passes with no errors
- [ ] CHK016 Type checking passes (TypeScript/Python type hints)
- [ ] CHK017 Code coverage meets target (80% minimum per `tasks.md`)
- [ ] CHK018 No security vulnerabilities introduced
- [ ] CHK019 Performance targets met (see `spec.md` NFR requirements)

---

## Documentation

- [ ] CHK020 Code comments added for complex logic
- [ ] CHK021 API documentation updated (if applicable)
- [ ] CHK022 README updated with new features/changes
- [ ] CHK023 Migration guide written (if breaking changes)
- [ ] CHK024 Release notes drafted in `release-notes.md`

---

## Deployment Readiness

- [ ] CHK025 Environment variables documented in `spec.md`
- [ ] CHK026 Database migrations tested (upgrade and downgrade)
- [ ] CHK027 Rollback plan documented (see `spec.md` Rollback Considerations)
- [ ] CHK028 Feature flags configured (if applicable)
- [ ] CHK029 Monitoring/alerts configured for new features

---

## Staging Validation

- [ ] CHK030 Deployed to staging environment successfully
- [ ] CHK031 Smoke tests passing on staging
- [ ] CHK032 User acceptance testing completed (if applicable)
- [ ] CHK033 Performance validated on staging
- [ ] CHK034 No errors in staging logs for 24+ hours

---

## Production Release

- [ ] CHK035 Production deployment checklist reviewed
- [ ] CHK036 Stakeholders notified of release schedule
- [ ] CHK037 Rollback plan confirmed and tested
- [ ] CHK038 Monitoring dashboards prepared
- [ ] CHK039 On-call rotation notified

---

## Post-Release

- [ ] CHK040 Production smoke tests passing
- [ ] CHK041 Key metrics trending as expected (see `spec.md` HEART metrics)
- [ ] CHK042 No critical errors in production logs
- [ ] CHK043 User feedback monitored (first 48 hours)
- [ ] CHK044 Performance within acceptable ranges

---

## Custom Checks (Feature-Specific)

*Add feature-specific validation items here*

- [ ] CHK045 [Custom check relevant to this feature]
- [ ] CHK046 [Custom check relevant to this feature]
- [ ] CHK047 [Custom check relevant to this feature]

---

## Notes

*Add any relevant notes, blockers, or context here*


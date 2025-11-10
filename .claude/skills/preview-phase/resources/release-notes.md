# Release Notes

**Purpose**: Create user-facing documentation for the feature.

---

## Format

```markdown
# Release Notes - v1.3.0

## New Features

### Student Progress Dashboard
Teachers can now view individual student progress with visual charts showing completion percentages across all courses.

**Key capabilities**:
- View progress for any student
- Filter by course or date range
- Export progress reports as PDF

## Improvements

### Performance
- Dashboard loads 40% faster
- Reduced API response time to <200ms

## Bug Fixes

### Authentication
- Fixed session timeout not refreshing correctly
- Improved error messages for invalid credentials

## Technical Details

**API Changes**:
- New endpoint: `GET /api/v1/students/{id}/progress`
- Response includes `completionPercentage` field

**Breaking Changes**:
None
```

---

## Tone

- **User-focused**: Describe benefits, not implementation
- **Clear**: Avoid technical jargon
- **Actionable**: What can users do now?

**See [../reference.md](../reference.md#release-notes) for complete examples**

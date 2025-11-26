<breaking_change_detection>

<table_of_contents>
**Quick Navigation**:
- [Patterns](#patterns) - API, Database, UI, Auth breaking change indicators
- [Impact Rubric](#impact_rubric) - High/Medium/Low impact assessment
- [Detection Checklist](#detection_checklist) - Validation checklist
</table_of_contents>

<patterns>

<pattern category="api">
**API Breaking Changes**

Indicators:
- Endpoint path modifications (e.g., `/users` → `/v2/users`)
- HTTP method changes (e.g., GET → POST)
- Required parameter additions (e.g., `userId` now required)
- Response schema changes (e.g., `{ id, name }` → `{ userId, fullName }`)
- Authentication requirement additions (e.g., public → authenticated)
- Rate limit reductions (e.g., 1000/hour → 100/hour)

**Detection**:
```bash
# Scan plan.md and tasks.md for API keywords
grep -i "endpoint\|route\|api\|parameter\|response" specs/NNN-slug/plan.md
```

Look for:
- "Change endpoint..."
- "Modify response format..."
- "Add required parameter..."
- "Require authentication for..."
</pattern>

<pattern category="database">
**Database Breaking Changes**

Indicators:
- Schema modifications (add/remove/rename columns)
- Required field additions (nullable=false)
- Data type changes (e.g., VARCHAR → INT)
- Constraint additions (e.g., UNIQUE, FK)
- Index removals affecting queries
- Migration affecting existing data

**Detection**:
```bash
# Scan for migration keywords
grep -i "migration\|schema\|column\|table\|constraint" specs/NNN-slug/plan.md
```

Look for:
- "Add migration to..."
- "Modify schema..."
- "Add required field..."
- "Change column type..."
</pattern>

<pattern category="ui">
**UI Breaking Changes**

Indicators:
- Component interface changes (prop additions/removals)
- Required prop additions
- Event handler signature changes
- Global state structure modifications
- CSS token removals/renames
- Route path changes

**Detection**:
```bash
# Scan for UI component keywords
grep -i "component\|prop\|interface\|route" specs/NNN-slug/plan.md
```

Look for:
- "Modify component interface..."
- "Add required prop..."
- "Change route from..."
- "Update global state..."
</pattern>

<pattern category="auth">
**Authentication/Authorization Breaking Changes**

Indicators:
- Permission model changes (e.g., role-based → attribute-based)
- Authentication flow modifications
- Token format changes
- Required scope additions
- Authorization check additions to existing endpoints

**Detection**:
```bash
# Scan for auth keywords
grep -i "auth\|permission\|role\|scope\|token" specs/NNN-slug/plan.md
```

Look for:
- "Modify permission model..."
- "Add authorization check to..."
- "Change token format..."
- "Require new scope..."
</pattern>

</patterns>

<impact_rubric>

<impact_level level="high">
**High Impact** - Requires migration, versioning, or major client changes

Examples:
- API endpoint removal or signature change
- Database schema change affecting existing data
- Authentication flow change requiring re-authentication
- Required field addition to existing API
- Response format change breaking existing clients

**Mitigation**:
- API versioning (/v1, /v2)
- Database migration with rollback plan
- Backward compatibility period
- Client SDK updates
- Documentation and migration guides
</impact_level>

<impact_level level="medium">
**Medium Impact** - Affects integrations but manageable

Examples:
- New feature with external integrations
- Optional parameter additions
- New endpoint affecting rate limits
- Soft deprecation (warnings, not removals)
- Schema additions (nullable columns)

**Mitigation**:
- Integration testing
- Staged rollout
- Deprecation warnings
- Client communication
</impact_level>

<impact_level level="low">
**Low Impact** - Isolated changes with no dependencies

Examples:
- New standalone feature
- Internal refactoring
- Performance improvements
- Bug fixes
- UI enhancements (no interface changes)

**Mitigation**:
- Standard testing
- Normal deployment
</impact_level>

</impact_rubric>

<detection_checklist>
When scanning artifacts, check:

- [ ] API endpoints: signature changes, new required params, response format
- [ ] Database: schema modifications, required fields, migrations
- [ ] UI components: interface changes, required props, route changes
- [ ] Authentication: permission model, auth flow, token format
- [ ] Dependencies: version bumps, breaking dependency changes
- [ ] Configuration: required env vars, config schema changes

For each breaking change found:
1. Document exact change (before → after)
2. Assess impact level (High/Medium/Low)
3. Identify affected consumers/integrations
4. Recommend mitigation strategy
</detection_checklist>

</breaking_change_detection>

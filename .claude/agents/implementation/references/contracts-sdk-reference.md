# Contracts SDK Agent - Reference Documentation

Complete reference for contract-first API development, OpenAPI/GraphQL/protobuf schema management, SDK generation, drift detection, semantic versioning, and producer-consumer alignment.

## Table of Contents

1. [Contract-First Workflow](#contract-first-workflow)
2. [Contract Update Procedure](#contract-update-procedure)
3. [Semantic Versioning Rules](#semantic-versioning-rules)
4. [SDK Generation](#sdk-generation)
5. [Drift Detection](#drift-detection)
6. [Breaking Change Management](#breaking-change-management)
7. [Backward Compatibility](#backward-compatibility)
8. [Multi-Language SDK Coordination](#multi-language-sdk-coordination)
9. [CI Integration](#ci-integration)
10. [Consumer Migration Guides](#consumer-migration-guides)
11. [Error Handling](#error-handling)

---

## Contract-First Workflow

**Philosophy**: The contract (OpenAPI, GraphQL schema, protobuf definition) is the single source of truth. Code follows contracts, not the reverse.

### Workflow Order

```
1. Update contract definition (OpenAPI/GraphQL/protobuf)
2. Validate contract syntax
3. Detect breaking changes
4. Bump version semantically
5. Document changes in changelog
6. Regenerate SDKs for all consumers
7. Run drift detection against implementation
8. Publish contracts and SDKs
9. Create integration guide for consumers
```

### Why Contract-First?

- **Single source of truth**: Contract defines behavior, not implementation
- **Consumer safety**: Breaking changes discovered before shipping
- **Cross-team alignment**: Frontend, mobile, backend all reference same spec
- **Auto-generated SDKs**: Type-safe clients for all platforms
- **Drift prevention**: CI catches implementation deviations

---

## Contract Update Procedure

### For OpenAPI (REST APIs)

**File locations**: `contracts/openapi.yaml` or `contracts/v{N}/openapi.yaml`

**Update process**:

1. **Read current spec**:
   ```bash
   cat contracts/openapi.yaml
   ```

2. **Apply changes** (example: add endpoint):
   ```yaml
   paths:
     /users/{id}/profile:
       get:
         summary: Get user profile
         parameters:
           - name: id
             in: path
             required: true
             schema:
               type: string
         responses:
           200:
             description: User profile
             content:
               application/json:
                 schema:
                   $ref: '#/components/schemas/UserProfile'
   ```

3. **Validate syntax**:
   ```bash
   openapi-cli validate contracts/openapi.yaml
   ```

4. **Check for breaking changes**:
   ```bash
   openapi-diff contracts/openapi.yaml.old contracts/openapi.yaml
   ```

### For GraphQL

**File locations**: `contracts/schema.graphql`

**Update process**:

1. **Read current schema**:
   ```bash
   cat contracts/schema.graphql
   ```

2. **Apply changes** (example: add field):
   ```graphql
   type User {
     id: ID!
     name: String!
     email: String!
     profile: UserProfile  # New field
   }

   type UserProfile {
     bio: String
     avatar: String
     location: String
   }
   ```

3. **Validate syntax**:
   ```bash
   graphql-schema-linter contracts/schema.graphql
   ```

4. **Check for breaking changes**:
   ```bash
   graphql-inspector diff contracts/schema.graphql.old contracts/schema.graphql
   ```

### For Protobuf (gRPC)

**File locations**: `contracts/api.proto`

**Update process**:

1. **Read current proto**:
   ```bash
   cat contracts/api.proto
   ```

2. **Apply changes** (example: add RPC method):
   ```protobuf
   service UserService {
     rpc GetUser (GetUserRequest) returns (User);
     rpc GetUserProfile (GetUserProfileRequest) returns (UserProfile);  // New RPC
   }

   message GetUserProfileRequest {
     string user_id = 1;
   }

   message UserProfile {
     string bio = 1;
     string avatar = 2;
     string location = 3;
   }
   ```

3. **Validate syntax**:
   ```bash
   buf lint
   ```

4. **Check for breaking changes**:
   ```bash
   buf breaking --against '.git#branch=main'
   ```

---

## Semantic Versioning Rules

Follow [semver.org](https://semver.org/) specification: MAJOR.MINOR.PATCH

### Version Bump Decision Tree

**MAJOR version** (3.0.0) - Breaking changes:
- Removed endpoint or field
- Renamed field or parameter
- Changed field type (string → number)
- Removed enum value
- Made optional field required
- Changed response structure

**MINOR version** (2.1.0) - Backward-compatible additions:
- Added new endpoint
- Added new optional field
- Added new enum value
- Added new query parameter (optional)
- Deprecated field (but not removed)

**PATCH version** (2.0.1) - Bug fixes:
- Fixed typos in descriptions
- Corrected example values
- Updated documentation
- Fixed implementation bugs (no contract change)

### Breaking Change Examples

**Breaking** (MAJOR bump required):
```yaml
# Before (v2.0.0)
/users/{id}:
  get:
    parameters:
      - name: id
        type: string

# After (v3.0.0) - changed type
/users/{id}:
  get:
    parameters:
      - name: id
        type: integer  # BREAKING: type changed
```

**Non-breaking** (MINOR bump):
```yaml
# Before (v2.0.0)
/users/{id}:
  get:
    parameters:
      - name: id
        type: string

# After (v2.1.0) - added optional parameter
/users/{id}:
  get:
    parameters:
      - name: id
        type: string
      - name: include_profile  # NEW: optional parameter
        type: boolean
        required: false
```

---

## SDK Generation

### Multi-Language SDK Targets

Generate SDKs for all consumer platforms:

**TypeScript/JavaScript**:
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g typescript-axios \
  -o sdks/typescript
```

**Python**:
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g python \
  -o sdks/python
```

**Java**:
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g java \
  -o sdks/java
```

**Go**:
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g go \
  -o sdks/go
```

**Swift** (iOS):
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g swift5 \
  -o sdks/swift
```

**Kotlin** (Android):
```bash
openapi-generator-cli generate \
  -i contracts/openapi.yaml \
  -g kotlin \
  -o sdks/kotlin
```

### GraphQL SDL Generation

```bash
# Generate TypeScript types from GraphQL schema
graphql-codegen --config codegen.yml
```

**codegen.yml**:
```yaml
schema: contracts/schema.graphql
generates:
  sdks/typescript/types.ts:
    plugins:
      - typescript
      - typescript-operations
      - typescript-react-apollo
```

### Protobuf Code Generation

```bash
# Generate for multiple languages
buf generate
```

**buf.gen.yaml**:
```yaml
version: v1
plugins:
  - name: go
    out: sdks/go
  - name: python
    out: sdks/python
  - name: java
    out: sdks/java
```

### SDK Versioning

**Version alignment**: SDK version MUST match contract version

Example package.json for TypeScript SDK:
```json
{
  "name": "@myapp/api-client",
  "version": "2.1.0",
  "description": "Auto-generated API client from OpenAPI v2.1.0"
}
```

---

## Drift Detection

**Goal**: Ensure implementation matches contract definition.

### OpenAPI Drift Detection

**Using Prism**:
```bash
# Start mock server from contract
prism mock contracts/openapi.yaml

# Run implementation against mock
npm test -- --integration

# Compare responses
```

**Using Schemathesis**:
```bash
# Test implementation against OpenAPI spec
schemathesis run contracts/openapi.yaml \
  --base-url http://localhost:3000 \
  --checks all
```

### GraphQL Schema Drift

**Using GraphQL Inspector**:
```bash
# Compare schema from introspection against source
graphql-inspector introspect http://localhost:4000/graphql \
  | graphql-inspector diff contracts/schema.graphql -
```

### Protobuf Drift Detection

**Using Buf**:
```bash
# Check for breaking changes against implementation
buf breaking --against '.git#branch=main'
```

### Drift Report Format

```markdown
# Drift Detection Report

**Contract**: OpenAPI v2.1.0
**Implementation**: API Server v2.1.3
**Status**: ⚠️  Drift detected

## Differences Found

### 1. Missing endpoint implementation
- **Contract**: GET /users/{id}/profile
- **Implementation**: 404 Not Found
- **Fix**: Implement endpoint or remove from contract

### 2. Response schema mismatch
- **Contract**: UserProfile.avatar (string)
- **Implementation**: UserProfile.avatar (object with url, size)
- **Fix**: Update contract to match implementation or fix implementation

### 3. Extra field in response
- **Implementation**: User.created_at (timestamp)
- **Contract**: Not defined
- **Fix**: Add to contract as optional field if intentional
```

---

## Breaking Change Management

### Breaking Change Detection

**Automated tools**:
- OpenAPI: `openapi-diff`
- GraphQL: `graphql-inspector diff`
- Protobuf: `buf breaking`

**Manual review checklist**:
- [ ] Removed any endpoints, fields, or methods?
- [ ] Renamed any fields or parameters?
- [ ] Changed any field types?
- [ ] Made optional fields required?
- [ ] Removed enum values?
- [ ] Changed response structure?

### Breaking Change Documentation

**CHANGELOG.md template**:
```markdown
# Changelog

## [3.0.0] - 2025-11-20

### Breaking Changes

#### Renamed field: `user_id` → `userId`
- **Affected endpoints**: GET /users, POST /users
- **Migration**: Replace `user_id` with `userId` in all requests
- **Reason**: Standardize naming convention to camelCase

#### Removed endpoint: DELETE /users/{id}/force
- **Alternative**: Use DELETE /users/{id} with `?force=true` query parameter
- **Migration**: Update DELETE calls to include query parameter
- **Reason**: Consolidate deletion logic

### Added
- New endpoint: GET /users/{id}/profile
- New optional field: User.profile_url

### Fixed
- Corrected typo in User.email description
```

### Migration Guide Template

```markdown
# Migration Guide: v2.x → v3.0.0

## Breaking Changes

### 1. Field Rename: `user_id` → `userId`

**Before (v2.x)**:
```json
{
  "user_id": "123",
  "name": "John"
}
```

**After (v3.0.0)**:
```json
{
  "userId": "123",
  "name": "John"
}
```

**Code change required**:
```typescript
// Before
const user = await api.getUser({ user_id: "123" });

// After
const user = await api.getUser({ userId: "123" });
```

### 2. Endpoint Removal: DELETE /users/{id}/force

**Before (v2.x)**:
```typescript
await api.deleteUserForce("123");
```

**After (v3.0.0)**:
```typescript
await api.deleteUser("123", { force: true });
```

## Timeline

- **v2.x support**: Maintained until 2026-01-20 (90 days)
- **v3.0.0 release**: 2025-11-20
- **Recommended migration**: Complete by 2025-12-20 (30 days)
```

---

## Backward Compatibility

### Deprecation Strategy

**Phase 1: Deprecate** (MINOR version bump):
```yaml
# OpenAPI v2.1.0
components:
  schemas:
    User:
      properties:
        user_id:
          type: string
          deprecated: true
          description: "DEPRECATED: Use userId instead. Will be removed in v3.0.0"
        userId:
          type: string
          description: "Replaces user_id"
```

**Phase 2: Remove** (MAJOR version bump):
```yaml
# OpenAPI v3.0.0
components:
  schemas:
    User:
      properties:
        userId:
          type: string
          description: "Unique user identifier"
        # user_id removed
```

### Compatibility Window

**Recommended timeline**:
- Deprecation announcement: v2.1.0 (2025-09-01)
- Deprecation warning period: 90 days minimum
- Removal: v3.0.0 (2025-12-01)

**Support policy**:
- **Current major version**: Full support
- **Previous major version**: Security fixes only (12 months)
- **Older versions**: Unsupported

---

## Multi-Language SDK Coordination

### SDK Publication Checklist

For each SDK target:

**TypeScript**:
- [ ] Generate SDK: `openapi-generator-cli generate -g typescript-axios`
- [ ] Run tests: `npm test`
- [ ] Build: `npm run build`
- [ ] Publish: `npm publish` (to npm registry)
- [ ] Version tag: `git tag typescript-sdk-v2.1.0`

**Python**:
- [ ] Generate SDK: `openapi-generator-cli generate -g python`
- [ ] Run tests: `pytest`
- [ ] Build: `python setup.py sdist bdist_wheel`
- [ ] Publish: `twine upload dist/*` (to PyPI)
- [ ] Version tag: `git tag python-sdk-v2.1.0`

**Java**:
- [ ] Generate SDK: `openapi-generator-cli generate -g java`
- [ ] Run tests: `mvn test`
- [ ] Build: `mvn package`
- [ ] Publish: `mvn deploy` (to Maven Central)
- [ ] Version tag: `git tag java-sdk-v2.1.0`

### Version Consistency Validation

**Verify all SDKs match contract version**:
```bash
# Check TypeScript SDK version
cat sdks/typescript/package.json | grep version

# Check Python SDK version
cat sdks/python/setup.py | grep version

# Check Java SDK version
cat sdks/java/pom.xml | grep -A1 "<version>"

# All should match contract version (e.g., 2.1.0)
```

---

## CI Integration

### Contract Validation in CI

**GitHub Actions example** (`.github/workflows/contract-validation.yml`):

```yaml
name: Contract Validation

on:
  pull_request:
    paths:
      - 'contracts/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate OpenAPI Syntax
        run: |
          npm install -g @openapitools/openapi-generator-cli
          openapi-generator-cli validate -i contracts/openapi.yaml

      - name: Check Breaking Changes
        run: |
          git fetch origin main
          git show origin/main:contracts/openapi.yaml > openapi.old.yaml
          npx openapi-diff openapi.old.yaml contracts/openapi.yaml

      - name: Drift Detection
        run: |
          npm install -g @stoplight/prism-cli
          prism mock contracts/openapi.yaml &
          sleep 5
          npm run test:integration

      - name: Generate SDKs
        run: |
          ./scripts/generate-all-sdks.sh

      - name: SDK Tests
        run: |
          cd sdks/typescript && npm test
          cd sdks/python && pytest
```

### Drift Detection in CI

**Continuous monitoring**:
```yaml
name: Drift Detection

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  drift-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Schemathesis
        run: |
          schemathesis run contracts/openapi.yaml \
            --base-url ${{ secrets.STAGING_API_URL }} \
            --checks all \
            --report

      - name: Report Drift
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "⚠️  API drift detected between contract and staging implementation"
            }
```

---

## Consumer Migration Guides

### Integration Guide Template

**For new endpoints** (MINOR version):
```markdown
# Integration Guide: v2.1.0

## New Features

### GET /users/{id}/profile

Retrieve detailed user profile information.

**Request**:
```http
GET /users/123/profile
Authorization: Bearer {token}
```

**Response**:
```json
{
  "bio": "Software engineer",
  "avatar": "https://example.com/avatar.jpg",
  "location": "San Francisco, CA"
}
```

**TypeScript SDK**:
```typescript
import { ApiClient } from '@myapp/api-client';

const client = new ApiClient({ token: 'your-token' });
const profile = await client.getUserProfile('123');
```

**Python SDK**:
```python
from myapp_client import ApiClient

client = ApiClient(token='your-token')
profile = client.get_user_profile('123')
```

## Action Required

None - this is a backward-compatible addition.
```

**For breaking changes** (MAJOR version):
```markdown
# Migration Guide: v2.x → v3.0.0

## ⚠️  Action Required

This is a MAJOR version with breaking changes. Review all changes before upgrading.

## Breaking Changes

### 1. Field Rename: `user_id` → `userId`

**Impact**: All endpoints returning User objects

**Migration steps**:
1. Update all code that reads `user_id` to `userId`
2. Update database queries if applicable
3. Run tests to verify changes

**Automated migration**:
```bash
# Find and replace in TypeScript
find . -name "*.ts" -exec sed -i 's/user_id/userId/g' {} +
```

**Timeline**:
- Deprecation notice: v2.1.0 (2025-09-01)
- v2.x support ends: 2026-01-20
- Migrate by: 2025-12-20 (recommended)
```

---

## Error Handling

### Contract Validation Failures

**Scenario**: OpenAPI syntax error

**Error**:
```
Error: /contracts/openapi.yaml is not valid
  - Line 45: Missing required field 'schema' in response definition
```

**Resolution**:
1. Review error message and line number
2. Check OpenAPI specification for required fields
3. Fix syntax error in contract file
4. Re-run validation
5. Do NOT proceed with SDK generation until validation passes

### SDK Generation Failures

**Scenario**: Code generation fails for Python SDK

**Error**:
```
Error: Failed to generate Python SDK
  - Invalid model name 'User-Profile' (contains hyphen)
```

**Resolution**:
1. Identify problematic schema definition
2. Fix naming (use `UserProfile` instead of `User-Profile`)
3. Re-run SDK generation
4. Verify all SDKs regenerate successfully

### Drift Detection Failures

**Scenario**: Implementation doesn't match contract

**Drift report**:
```
⚠️  Drift detected:
  - Endpoint /users/{id}/profile returns 404 (expected 200)
  - Missing field: UserProfile.location
```

**Resolution options**:

**Option 1: Update implementation**
- Implement missing endpoint
- Add missing fields
- Deploy implementation
- Re-run drift check

**Option 2: Update contract**
- Remove endpoint from contract if not implemented
- Remove field if not available
- Bump version (MAJOR if breaking)
- Regenerate SDKs

**DO NOT auto-fix** - requires manual decision about which side to update.

### Breaking Change Conflicts

**Scenario**: Attempting to publish breaking change without major version bump

**Error**:
```
❌ Breaking changes detected but version bump is MINOR (2.0.0 → 2.1.0)

Breaking changes:
  - Removed field: User.user_id
  - Renamed parameter: id → userId

Required: MAJOR version bump (2.0.0 → 3.0.0)
```

**Resolution**:
1. Review breaking changes list
2. Decide: revert changes OR bump to MAJOR version
3. If MAJOR bump: create migration guide
4. Update version in contract
5. Proceed with SDK generation

---

## Best Practices

1. **Always update contracts first** - Never implement before updating contract
2. **Validate before committing** - Run syntax validation in pre-commit hooks
3. **Detect breaking changes early** - Use automated tools in CI
4. **Document all breaking changes** - Include migration guide
5. **Regenerate all SDKs** - Don't forget mobile, frontend, backend clients
6. **Test drift continuously** - Run drift detection on every deployment
7. **Version SDKs consistently** - SDK version must match contract version
8. **Maintain deprecation window** - 90 days minimum before removal
9. **Coordinate with consumers** - Alert frontend/mobile teams of changes
10. **Automate in CI** - Validation, generation, and drift checks in pipeline

---

## Tooling Reference

### OpenAPI Tools

- **Validation**: `openapi-cli validate`, `swagger-cli validate`
- **Breaking changes**: `openapi-diff`, `oasdiff`
- **SDK generation**: `openapi-generator-cli`, `swagger-codegen`
- **Drift detection**: `prism`, `schemathesis`
- **Documentation**: `redoc-cli`, `swagger-ui`

### GraphQL Tools

- **Validation**: `graphql-schema-linter`
- **Breaking changes**: `graphql-inspector diff`
- **Code generation**: `graphql-codegen`
- **Introspection**: `graphql-inspector introspect`

### Protobuf Tools

- **Validation**: `buf lint`
- **Breaking changes**: `buf breaking`
- **Code generation**: `buf generate`, `protoc`
- **Documentation**: `buf generate --template buf.gen.yaml`

### Version Management

- **Semantic versioning**: Follow [semver.org](https://semver.org/)
- **Changelog**: Keep [CHANGELOG.md](https://keepachangelog.com/) updated
- **Git tags**: Tag each contract version (`git tag contract-v2.1.0`)

---

## Examples

### Example 1: Add New Endpoint (MINOR)

**Change**: Add GET /users/{id}/settings

**Steps**:
1. Update OpenAPI contract with new endpoint
2. Validate: `openapi-cli validate contracts/openapi.yaml`
3. Bump version: 2.0.0 → 2.1.0
4. Update CHANGELOG.md: Document new endpoint
5. Regenerate SDKs: TypeScript, Python, Java
6. Run drift check: Verify implementation exists
7. Publish SDKs: npm, PyPI, Maven
8. Create integration guide: How to use new endpoint

**Result**: v2.1.0 published, backward compatible

### Example 2: Breaking Change - Rename Field (MAJOR)

**Change**: Rename User.user_id → User.userId

**Steps**:
1. Update OpenAPI contract with new field name
2. Detect breaking change: `openapi-diff`
3. Bump version: 2.1.0 → 3.0.0
4. Update CHANGELOG.md: Document breaking change
5. Create migration guide: Find/replace instructions
6. Regenerate SDKs: All languages
7. Alert consumers: Frontend, mobile, partners
8. Publish SDKs with v3.0.0
9. Maintain v2.x for 90 days

**Result**: v3.0.0 published, migration guide provided

### Example 3: Drift Detection and Fix

**Problem**: GET /users/{id} returns extra field `internal_id` not in contract

**Steps**:
1. Run drift detection: `schemathesis run`
2. Review drift report: Extra field detected
3. Decision: Add to contract (it's intentional)
4. Update contract: Add `internal_id` as optional field
5. Bump version: 2.1.0 → 2.2.0 (MINOR, new field)
6. Regenerate SDKs
7. Re-run drift check: PASS

**Result**: Contract and implementation aligned

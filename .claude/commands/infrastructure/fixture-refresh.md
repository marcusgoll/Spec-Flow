# /fixture.refresh - Regenerate Golden Fixtures

**Purpose**: Regenerate golden JSON fixtures from OpenAPI and JSON Schema contracts, then replay through CDC tests to ensure parity between schemas and examples.

**Usage**:
```bash
/fixture.refresh [--verify] [--path contracts/api/vX.Y.Z]
```

**Parameters**:
- `--verify`: Run CDC tests after regeneration to validate fixtures
- `--path PATH`: Regenerate fixtures for specific contract version only

**Prerequisites**:
- Contracts directory with schemas (`contracts/api/*/openapi.yaml`)
- JSON Schema definitions for events (`contracts/events/`)

**Outputs**:
- Updated golden fixtures in `contracts/api/vX.Y.Z/examples/`
- Updated event examples in `contracts/events/*/examples/`
- Verification report if `--verify` flag used

---

## Why Golden Fixtures?

**Purpose**: Golden fixtures serve as:
1. **Documentation**: Show real request/response examples
2. **CDC Test Data**: Used as test inputs for contract verification
3. **Schema Validation**: Ensure schemas are complete and realistic

**Problem Without Fixtures**:
- Consumers don't know what real requests/responses look like
- CDC tests have no test data
- Schema drift goes unnoticed (schemas valid but not practical)

**Solution**:
- Generate realistic examples from schemas
- Validate examples against schemas
- Use examples in CDC tests

---

## Workflow Steps

### 1. Discover Contract Versions

Scan `contracts/api/` for all version directories:

```bash
contracts/api/
├── v1.0.0/
├── v1.1.0/
└── v1.2.0/
```

If `--path` specified, process only that version.

### 2. Parse OpenAPI Schemas

For each version, extract schemas from `openapi.yaml`:

```yaml
components:
  schemas:
    LoginRequest:
      type: object
      required: [email, password]
      properties:
        email:
          type: string
          format: email
          example: user@example.com
        password:
          type: string
          format: password
          minLength: 8
```

### 3. Generate Fixtures from Schemas

Use schema examples or generate realistic data:

**Strategy A: Use Inline Examples** (preferred)

Extract `example` fields from schema properties.

**Strategy B: Generate from Schema** (fallback)

Use JSON Schema Faker or similar to generate realistic data:

```bash
# Using JSON Schema Faker (if available)
echo '{"type": "string", "format": "email"}' | json-schema-faker
# Output: "user_123@example.com"
```

**Strategy C: Templates** (simple fallback)

Use hardcoded templates for common patterns:

```json
{
  "string": "example-string",
  "integer": 42,
  "boolean": true,
  "email": "user@example.com",
  "uuid": "123e4567-e89b-12d3-a456-426614174000",
  "date-time": "2025-11-10T14:30:00Z"
}
```

### 4. Write Fixtures to Files

Create one fixture file per endpoint/operation:

**Naming convention**: `{operation}-{type}.json`

Examples:
- `auth-login-request.json`
- `auth-login-response.json`
- `user-create-request.json`
- `user-create-response.json`
- `feature-list-response.json`

### 5. Generate Event Fixtures

For JSON Schema event definitions:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Feature Shipped Event",
  "properties": {
    "event_type": { "const": "feature.shipped" },
    "data": {
      "type": "object",
      "properties": {
        "slug": { "type": "string", "example": "user-auth" }
      }
    }
  }
}
```

Generate:
- `contracts/events/webhook-schemas/examples/feature-shipped.json`

### 6. Validate Fixtures Against Schemas

Use JSON Schema validators to ensure fixtures comply:

```bash
# Validate fixture against schema
ajv validate \
  -s contracts/api/v1.0.0/openapi.yaml#/components/schemas/LoginRequest \
  -d contracts/api/v1.0.0/examples/auth-login-request.json
```

If validation fails, regenerate fixture or fix schema.

### 7. Run CDC Verification (if --verify)

Run `/contract.verify` to ensure fixtures work in CDC tests:

```bash
/contract.verify
```

This validates that:
- Fixtures are realistic
- Schemas are accurate
- CDC tests pass with new fixtures

---

## Implementation Details

### Script Location

**Bash**: `.spec-flow/scripts/bash/fixture-refresh.sh`
**PowerShell**: `.spec-flow/scripts/powershell/fixture-refresh.ps1`

### Functions Required

```bash
# Discover all contract versions
discover_contract_versions() {
  find contracts/api -maxdepth 1 -type d -name 'v*' | sort -V
}

# Parse OpenAPI spec
parse_openapi_schemas() {
  local openapi_file=$1
  # Use yq or jq to extract schemas
  yq eval '.components.schemas' "$openapi_file"
}

# Generate fixture from schema
generate_fixture_from_schema() {
  local schema_name=$1
  local schema_def=$2

  # Strategy 1: Extract inline examples
  local example=$(echo "$schema_def" | yq eval '.example')

  if [[ "$example" != "null" ]]; then
    echo "$example"
    return
  fi

  # Strategy 2: Build from properties
  generate_fixture_from_properties "$schema_def"
}

# Build fixture from property definitions
generate_fixture_from_properties() {
  local schema=$1

  local properties=$(echo "$schema" | yq eval '.properties')

  # Iterate properties and generate values
  # Based on type, format, and constraints
}

# Get example value for type/format
get_example_value() {
  local type=$1
  local format=$2

  case "$type:$format" in
    string:email)
      echo "user@example.com"
      ;;
    string:uuid)
      echo "123e4567-e89b-12d3-a456-426614174000"
      ;;
    string:date-time)
      date -Iseconds
      ;;
    integer:*)
      echo 42
      ;;
    boolean:*)
      echo true
      ;;
    *)
      echo "example-value"
      ;;
  esac
}

# Write fixture to file
write_fixture() {
  local file=$1
  local content=$2

  echo "$content" | jq '.' > "$file"
  log_success "Generated $file"
}

# Validate fixture against schema
validate_fixture() {
  local fixture_file=$1
  local schema_file=$2
  local schema_path=$3

  # Use ajv, jsonschema, or similar
  if command -v ajv &> /dev/null; then
    ajv validate -s "$schema_file#$schema_path" -d "$fixture_file"
  else
    log_warning "No JSON Schema validator found - skipping validation"
    return 0
  fi
}
```

### Dependencies

**Required**:
- **jq** or **yq**: YAML/JSON parsing

**Optional** (enhanced generation):
- **json-schema-faker**: Generate realistic data from schemas
- **ajv-cli**: JSON Schema validation

**Fallback**: Template-based generation if tools unavailable

---

## Examples

### Example 1: Refresh All Fixtures

```bash
/fixture.refresh

# Output:
ℹ Discovering contract versions...
ℹ Found 3 versions: v1.0.0, v1.1.0, v1.2.0

ℹ Processing v1.0.0...
✅ Generated auth-login-request.json
✅ Generated auth-login-response.json
✅ Generated user-create-request.json
✅ Generated user-create-response.json

ℹ Processing v1.1.0...
✅ Generated feature-list-response.json

ℹ Processing v1.2.0...
✅ Generated contract-verify-response.json

✅ Fixture refresh complete
   Generated 6 fixtures across 3 versions
```

### Example 2: Refresh Specific Version

```bash
/fixture.refresh --path contracts/api/v1.2.0

# Output:
ℹ Processing v1.2.0...
✅ Generated contract-verify-response.json

✅ Fixture refresh complete
   Generated 1 fixture
```

### Example 3: Refresh with Verification

```bash
/fixture.refresh --verify

# Output:
[... fixture generation ...]

ℹ Running CDC verification with new fixtures...

✅ Contract verification passed
   Verified 3 pacts
   Total: 10 interactions tested, 0 failures

✅ Fixture refresh and verification complete
```

### Example 4: Validation Failure

```bash
/fixture.refresh

# Output:
ℹ Processing v1.0.0...
✅ Generated auth-login-request.json
❌ Validation failed: auth-login-response.json

Error: Property 'email' is required but missing

Schema: contracts/api/v1.0.0/openapi.yaml#/components/schemas/LoginResponse
Fixture: contracts/api/v1.0.0/examples/auth-login-response.json

Fix: Update schema to include 'email' property or mark as optional
```

---

## Integration with Workflow

### When to Run

**Automatically**:
- After `/contract.bump` (new version created)
- After schema changes (OpenAPI or JSON Schema updates)

**Manually**:
- When examples become stale
- After adding new endpoints
- When CDC tests fail due to outdated fixtures

### Integration with /contract.bump

```bash
/contract.bump minor
  → Create new version directory
  → Copy schemas
  → /fixture.refresh --path contracts/api/v1.1.0  ← Automatic
  → /contract.verify  ← Validates with new fixtures
```

### Platform Agent Responsibility

The **platform agent** owns:
- Running `/fixture.refresh` after schema changes
- Validating generated fixtures
- Ensuring fixtures match schemas
- Updating fixtures when schemas evolve

---

## Advanced: Schema-Driven Fixture Generation

### Using JSON Schema Faker

If `json-schema-faker` available:

```bash
# Install
npm install -g json-schema-faker

# Generate fixture
echo '{
  "type": "object",
  "properties": {
    "email": { "type": "string", "format": "email" },
    "age": { "type": "integer", "minimum": 18, "maximum": 120 }
  },
  "required": ["email"]
}' | json-schema-faker

# Output:
{
  "email": "john.doe@example.com",
  "age": 42
}
```

**Benefit**: Realistic, varied data without hardcoded templates.

### Faker Libraries

Language-specific faker libraries can be invoked:

**JavaScript**: `@faker-js/faker`
**Python**: `Faker`
**Ruby**: `FFaker`

Example:

```javascript
const { faker } = require('@faker-js/faker');

function generateUser() {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    role: faker.helpers.arrayElement(['admin', 'developer', 'viewer'])
  };
}
```

---

## Fixture Aging Detection

**Problem**: Fixtures become stale when schemas evolve but fixtures aren't updated.

**Solution**: Track fixture age and schema modification time.

```bash
# Check if fixture is older than schema
SCHEMA_MTIME=$(stat -c %Y contracts/api/v1.0.0/openapi.yaml)
FIXTURE_MTIME=$(stat -c %Y contracts/api/v1.0.0/examples/auth-login-response.json)

if [[ $FIXTURE_MTIME -lt $SCHEMA_MTIME ]]; then
  log_warning "Fixture older than schema - run /fixture.refresh"
fi
```

**Auto-alert**: Add to CI pipeline to warn when fixtures stale.

---

## Error Handling

### Schema Missing Examples

```
⚠️ Schema has no inline examples: LoginRequest

Generated generic fixture from property types.

Recommendation: Add 'example' fields to schema properties for realistic fixtures.
```

### Validation Failure

```
❌ Generated fixture failed validation

Fixture: auth-login-response.json
Schema: openapi.yaml#/components/schemas/LoginResponse

Error: Missing required property 'token'

Fix:
  1. Check schema for required fields
  2. Ensure generator includes all required properties
  3. Add inline examples to schema
```

### No Validator Available

```
⚠️ JSON Schema validator not found

Generated fixtures saved, but validation skipped.

Install ajv-cli for validation:
  npm install -g ajv-cli
```

---

## References

- [JSON Schema](https://json-schema.org/)
- [OpenAPI Examples](https://spec.openapis.org/oas/v3.1.0#example-object)
- [JSON Schema Faker](https://github.com/json-schema-faker/json-schema-faker)
- [AJV JSON Schema Validator](https://ajv.js.org/)
- `/contract.bump` - Version bumping with automatic fixture refresh
- `/contract.verify` - CDC verification using fixtures

# API Contracts (OpenAPI)

HTTP API contracts using OpenAPI 3.1 specification.

## Structure

Each version is a directory containing:

- `openapi.yaml` - OpenAPI 3.1 specification
- `CHANGELOG.md` - Semantic versioning changelog
- `examples/` - Golden request/response fixtures

## Example Version: v1.0.0

```
v1.0.0/
├── openapi.yaml       # Full API specification
├── CHANGELOG.md       # Version history
└── examples/
    ├── auth-login-request.json
    ├── auth-login-response.json
    ├── user-create-request.json
    └── user-create-response.json
```

## Versioning

Follow [semantic versioning](https://semver.org/):

- **MAJOR**: Breaking changes (remove endpoint, change response structure)
- **MINOR**: Additive changes (new endpoint, optional field)
- **PATCH**: Bug fixes (typo in description, example updates)

## Mid-Sprint Rule

**Only minor/patch bumps allowed mid-sprint.** Breaking changes require RFC and new sprint.

## Golden Fixtures

Fixtures in `examples/` serve two purposes:

1. **Documentation**: Show real request/response examples
2. **CDC Testing**: Used as test data for contract verification

Regenerate with `/fixture.refresh` when schema changes.

## Platform Agent Responsibility

The **platform agent** owns:
- Contract versioning
- OpenAPI schema updates
- Breaking change detection
- CDC verification before merge

## Commands

```bash
# Bump version
/contract.bump minor  # v1.0.0 → v1.1.0

# Verify all contracts
/contract.verify

# Refresh golden fixtures
/fixture.refresh
```

## References

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [OpenAPI Generator](https://openapi-generator.tech/)

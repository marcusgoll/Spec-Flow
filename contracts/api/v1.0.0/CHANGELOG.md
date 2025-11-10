# API Contract Changelog

All notable changes to this API contract will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-10

### Added

- Initial API contract definition
- Authentication endpoints (`/auth/login`, `/auth/logout`)
- User management endpoints (`/users/*`)
- Feature management endpoints (`/features/*`)

### Security

- All endpoints require JWT authentication
- Rate limiting: 100 requests/minute per user
- CORS enabled for allowed origins only

## Version Guidelines

### MAJOR (Breaking Changes)

- Remove endpoints
- Remove required fields from responses
- Change field types
- Rename fields or endpoints
- Change authentication mechanism

**Action Required**: RFC + new sprint + consumer migration plan

### MINOR (Additive Changes - Safe Mid-Sprint)

- Add new endpoints
- Add optional fields to requests/responses
- Add new query parameters (optional)
- Deprecate (but don't remove) endpoints

**Action Required**: `/contract.bump minor` + CDC verification

### PATCH (Documentation/Examples)

- Fix typos in descriptions
- Update examples
- Clarify documentation
- Add response code examples

**Action Required**: `/contract.bump patch`

## Deprecation Policy

Deprecated endpoints remain functional for **2 major versions** before removal.

**Example**: Endpoint deprecated in v1.0.0 → removed in v3.0.0

**Migration**: Provide migration guide in CHANGELOG when deprecating.

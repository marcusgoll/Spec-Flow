# Contract Validation Report

**Generated**: {TIMESTAMP}

**Epic**: {EPIC_SLUG}

**Status**: {PASSED|FAILED}

---

## Executive Summary

**Total Contracts**: {TOTAL_CONTRACTS}

**Compliant Contracts**: {COMPLIANT_COUNT}

**Contracts with Issues**: {ISSUES_COUNT}

**Breaking Changes Detected**: {BREAKING_CHANGES_COUNT}

**Contract Drift Detected**: {DRIFT_COUNT}

**CDC Tests Status**: {CDC_PASSED}/{CDC_TOTAL} passed

---

## Contract Compliance Matrix

| Contract | Status | Endpoint | Implementation | Schema Match | CDC Tests | Issues |
|----------|--------|----------|----------------|--------------|-----------|--------|
| {contract_name} | ✅ PASS | {endpoint} | Found | ✅ Match | ✅ 3/3 | None |
| {contract_name} | ❌ FAIL | {endpoint} | Missing | ❌ Mismatch | ❌ 0/2 | Breaking change |
| {contract_name} | ⚠️ WARN | {endpoint} | Found | ⚠️ Drift | ✅ 1/1 | Minor drift |

---

## Detailed Findings

### Contract 1: {CONTRACT_NAME}

**File**: `contracts/api/{contract-file}.yaml`

**Status**: {PASSED|FAILED|WARNING}

**OpenAPI Version**: 3.0.3

**Base Path**: `/api/v1`

#### Endpoints

##### GET /api/v1/users

**Implementation Status**: ✅ Found

**Location**: `backend/src/routes/users.ts:45`

**Schema Validation**:
- Request parameters: ✅ Match
- Response schema (200): ✅ Match
- Response schema (404): ✅ Match
- Response schema (500): ✅ Match

**CDC Tests** (Pact):
- Provider: `user-service`
- Consumer: `frontend-app`
- Test status: ✅ PASSED
- Test file: `tests/contract/user-api.pact.spec.ts`
- Interactions tested: 3/3

##### POST /api/v1/users

**Implementation Status**: ❌ Missing

**Expected Location**: `backend/src/routes/users.ts` (not found)

**Schema Validation**: N/A (endpoint not implemented)

**CDC Tests**: N/A (skipped due to missing implementation)

**Issue**: CRITICAL - Contract endpoint not implemented

**Recommendation**: Implement POST /api/v1/users endpoint per OpenAPI spec

---

### Contract 2: {CONTRACT_NAME}

**File**: `contracts/api/{contract-file}.yaml`

**Status**: {PASSED|FAILED|WARNING}

...

---

## Breaking Changes Detected

### 1. {BREAKING_CHANGE_DESCRIPTION}

**Contract**: {contract_name}

**Endpoint**: {method} {path}

**Severity**: CRITICAL

**Type**: {type} (e.g., "Required field removed", "Response type changed", "Endpoint removed")

**Details**:
- **Contract Expected**: {expected_schema}
- **Implementation Found**: {actual_schema}
- **Impact**: Consumers expecting {old_behavior} will break

**Migration Path**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

**API Versioning Recommendation**: Create `/api/v2` endpoint with new schema, deprecate `/api/v1`

---

### 2. {BREAKING_CHANGE_DESCRIPTION}

...

---

## Contract Drift (Non-Breaking)

### 1. {DRIFT_DESCRIPTION}

**Contract**: {contract_name}

**Endpoint**: {method} {path}

**Severity**: MEDIUM

**Type**: {type} (e.g., "Optional field added", "Response includes extra fields", "Query parameter renamed")

**Details**:
- **Contract Specifies**: {contract_schema}
- **Implementation Returns**: {actual_schema}
- **Difference**: Implementation includes additional field `{field_name}` not in contract

**Impact**: Low - Consumers ignore unknown fields

**Recommendation**: Update OpenAPI spec to reflect actual implementation

---

### 2. {DRIFT_DESCRIPTION}

...

---

## CDC Test Results (Pact)

**Provider**: {provider_service_name}

**Consumers**: {consumer_count} consumers

| Consumer | Interactions | Status | Failures |
|----------|-------------|--------|----------|
| {consumer_name} | 5 | ✅ PASSED | 0 |
| {consumer_name} | 3 | ❌ FAILED | 2 |
| {consumer_name} | 8 | ✅ PASSED | 0 |

### Failed Interactions

#### Consumer: {consumer_name}

**Interaction**: "GET /api/v1/products returns product list"

**Expected** (from contract):
```json
{
  "products": [
    {
      "id": "number",
      "name": "string",
      "price": "number"
    }
  ]
}
```

**Actual** (from provider):
```json
{
  "products": [
    {
      "id": "string",  // ❌ Type mismatch: expected number, got string
      "name": "string",
      "price": "number"
    }
  ]
}
```

**Reason**: Type mismatch for `id` field

**Recommendation**: Update provider to return `id` as number, or update contract to accept string

---

## Contract Coverage

**Endpoints Defined in Contracts**: {total_endpoints}

**Endpoints Implemented**: {implemented_endpoints}

**Endpoints Missing**: {missing_endpoints}

**Coverage**: {coverage_percentage}%

### Missing Implementations

1. `POST /api/v1/orders` - Defined in `contracts/api/orders.yaml` (line 45)
2. `DELETE /api/v1/users/{id}` - Defined in `contracts/api/users.yaml` (line 120)
3. `PATCH /api/v1/products/{id}` - Defined in `contracts/api/products.yaml` (line 78)

**Recommendation**: Implement missing endpoints or remove from contract if not required

---

## Auto-Retry Summary

{IF auto_retry_used}
**Retry Attempts**: {retry_count}

**Strategies Used**:
1. `regenerate-schemas`: ✅ Succeeded (attempt 1)
2. `sync-contracts`: ❌ Failed (attempt 2)
3. `re-run-contract-tests`: ✅ Succeeded (attempt 1)

**Final Status**: {PASSED|FAILED} (after {total_attempts} retries)
{ELSE}
No auto-retry needed - all checks passed on first attempt
{ENDIF}

---

## Recommendations

### Immediate Actions (CRITICAL)

1. **Implement missing endpoints**:
   - `POST /api/v1/users`
   - `DELETE /api/v1/orders/{id}`

2. **Fix breaking changes**:
   - Revert type change for `User.id` (string → number)
   - Restore required field `Order.status`

3. **Update CDC tests**:
   - Fix failing interaction: "GET /api/v1/products"
   - Add missing test for `POST /api/v1/orders`

### Before Next Sprint

1. **Sync contract drift**:
   - Update OpenAPI specs to match implementation
   - Document additional fields in response schemas

2. **Improve contract coverage**:
   - Add contracts for uncovered endpoints
   - Achieve 100% endpoint coverage

### Best Practices

1. **Contract-first development**:
   - Define OpenAPI spec before implementation
   - Use code generation tools (openapi-generator)
   - Lock contracts before parallel sprint execution

2. **CDC testing**:
   - Run Pact tests in CI/CD pipeline
   - Publish Pact contracts to broker
   - Verify provider compatibility before deployment

3. **API versioning**:
   - Use semantic versioning for breaking changes
   - Maintain backward compatibility for minor versions
   - Deprecate old versions gracefully (6-month notice)

---

## Appendix: Contract Files Validated

1. `contracts/api/users.yaml` - 5 endpoints
2. `contracts/api/orders.yaml` - 3 endpoints
3. `contracts/api/products.yaml` - 7 endpoints
4. `contracts/api/auth.yaml` - 2 endpoints
5. `contracts/api/payments.yaml` - 4 endpoints

**Total**: 21 endpoints across 5 contracts

---

## Exit Status

**Exit Code**: {0 if passed else 1}

**Blockers**: {blocker_count}

**Next Action**:
{IF passed}
✅ All contracts compliant - proceed to next quality gate
{ELSE}
❌ Contract validation failed - fix {blocker_count} critical issues before deployment
{ENDIF}

---

**Report Generated by**: Gate 8 (Contract Validation) - /optimize phase

**Template Version**: 1.0

**Generated**: {ISO_TIMESTAMP}

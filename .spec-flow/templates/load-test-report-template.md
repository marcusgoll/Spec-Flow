# Load Test Report

**Generated**: {TIMESTAMP}

**Epic**: {EPIC_SLUG}

**Status**: {PASSED|FAILED|SKIPPED}

---

## Executive Summary

**Test Tool**: {k6|artillery|locust}

**Test Duration**: {duration} seconds

**Virtual Users (VUs)**: {vu_count}

**Total Requests**: {total_requests}

**Successful Requests**: {successful_requests} ({success_rate}%)

**Failed Requests**: {failed_requests} ({error_rate}%)

**Status**: {PASSED|FAILED based on targets}

---

## Performance Metrics

### Response Times

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| **p50 (median)** | {p50_ms} ms | {target_p50_ms} ms | {✅ PASS / ❌ FAIL} |
| **p90** | {p90_ms} ms | {target_p90_ms} ms | {✅ PASS / ❌ FAIL} |
| **p95** | {p95_ms} ms | {target_p95_ms} ms | {✅ PASS / ❌ FAIL} |
| **p99** | {p99_ms} ms | {target_p99_ms} ms | {✅ PASS / ❌ FAIL} |
| **p99.9** | {p999_ms} ms | - | ℹ️ INFO |
| **min** | {min_ms} ms | - | ℹ️ INFO |
| **max** | {max_ms} ms | {max_acceptable_ms} ms | {✅ PASS / ❌ FAIL} |
| **avg** | {avg_ms} ms | {target_avg_ms} ms | {✅ PASS / ❌ FAIL} |

### Throughput

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| **Requests/sec (RPS)** | {rps} | {target_rps} | {✅ PASS / ❌ FAIL} |
| **Data Received** | {data_received_mb} MB | - | ℹ️ INFO |
| **Data Sent** | {data_sent_mb} MB | - | ℹ️ INFO |

### Error Rate

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| **Error Rate** | {error_rate}% | < 1% | {✅ PASS / ❌ FAIL} |
| **HTTP Errors** | {http_error_count} | 0 | {✅ PASS / ❌ FAIL} |
| **Timeouts** | {timeout_count} | 0 | {✅ PASS / ❌ FAIL} |
| **Connection Errors** | {connection_error_count} | 0 | {✅ PASS / ❌ FAIL} |

---

## Load Test Scenario

**Test Configuration**:
```javascript
// k6 configuration
export let options = {
  vus: {vu_count},
  duration: '{duration}s',
  thresholds: {
    'http_req_duration': ['p(95)<{target_p95_ms}'],
    'http_req_failed': ['rate<0.01'],  // Less than 1% errors
  },
};
```

**Test Script**: `{test_script_path}`

**Target Endpoints**:
1. `GET /api/v1/users` - {users_requests} requests
2. `POST /api/v1/orders` - {orders_requests} requests
3. `GET /api/v1/products` - {products_requests} requests
4. `GET /api/v1/dashboard` - {dashboard_requests} requests

**Request Distribution**:
- 60% read operations (GET requests)
- 30% write operations (POST/PUT requests)
- 10% delete operations (DELETE requests)

---

## Performance Targets

**Source**: {capacity-planning.md | plan.md | default}

| Metric | Target Value | Actual Value | Status |
|--------|--------------|--------------|--------|
| **p95 Latency** | < {target_p95} ms | {actual_p95} ms | {✅|❌} |
| **Error Rate** | < 1% | {actual_error_rate}% | {✅|❌} |
| **Throughput** | > {target_rps} RPS | {actual_rps} RPS | {✅|❌} |
| **Concurrent Users** | {target_vu_count} VUs | {actual_vu_count} VUs | ℹ️ |

{IF targets_missed}
⚠️ **Performance targets not met**:
- p95 latency: {actual_p95}ms (target: <{target_p95}ms) - **{delta}ms over target**
- Error rate: {actual_error_rate}% (target: <1%) - **{delta}% over target**
{ENDIF}

---

## Detailed Results by Endpoint

### Endpoint 1: GET /api/v1/users

**Total Requests**: {requests_count}

**Response Times**:
- p50: {p50_ms} ms
- p95: {p95_ms} ms
- p99: {p99_ms} ms

**Success Rate**: {success_rate}% ({success_count}/{total_count})

**Errors**:
- 500 Internal Server Error: {count_500}
- 503 Service Unavailable: {count_503}
- Timeouts: {count_timeout}

**Bottleneck Analysis**:
{IF slow}
⚠️ **Slow endpoint detected**:
- p95 latency ({p95_ms}ms) exceeds endpoint target ({target_ms}ms)
- Likely cause: {database_query_slow | external_api_call | CPU_intensive_operation}
- Recommendation: {add_caching | optimize_query | add_index | scale_horizontally}
{ELSE}
✅ Performance within acceptable range
{ENDIF}

---

### Endpoint 2: POST /api/v1/orders

**Total Requests**: {requests_count}

**Response Times**:
- p50: {p50_ms} ms
- p95: {p95_ms} ms
- p99: {p99_ms} ms

**Success Rate**: {success_rate}% ({success_count}/{total_count})

**Errors**:
- 400 Bad Request: {count_400}
- 422 Unprocessable Entity: {count_422}
- 500 Internal Server Error: {count_500}

**Bottleneck Analysis**:
...

---

## System Resource Utilization

### Backend API Server

| Metric | Peak Value | Average | Status |
|--------|-----------|---------|--------|
| **CPU Usage** | {peak_cpu}% | {avg_cpu}% | {✅ <80% / ⚠️ >80% / ❌ >90%} |
| **Memory Usage** | {peak_mem_mb} MB | {avg_mem_mb} MB | {✅ <80% / ⚠️ >80% / ❌ >90%} |
| **Disk I/O** | {peak_disk_iops} IOPS | {avg_disk_iops} IOPS | ℹ️ |
| **Network I/O** | {peak_network_mbps} Mbps | {avg_network_mbps} Mbps | ℹ️ |

### Database Server

| Metric | Peak Value | Average | Status |
|--------|-----------|---------|--------|
| **CPU Usage** | {peak_cpu}% | {avg_cpu}% | {✅ <80% / ⚠️ >80% / ❌ >90%} |
| **Memory Usage** | {peak_mem_mb} MB | {avg_mem_mb} MB | {✅ <80% / ⚠️ >80% / ❌ >90%} |
| **Active Connections** | {peak_connections} | {avg_connections} | {✅|⚠️|❌} |
| **Query Latency (avg)** | {peak_query_ms} ms | {avg_query_ms} ms | {✅|⚠️|❌} |
| **Slow Queries** | {slow_query_count} | - | {✅ 0 / ❌ >0} |

{IF resource_bottleneck}
⚠️ **Resource bottleneck detected**:
- {CPU|Memory|Disk|Network} utilization exceeded 80% during test
- Peak occurred at: {timestamp}
- Recommendation: {vertical_scaling | horizontal_scaling | optimization}
{ENDIF}

---

## Error Analysis

### Error Breakdown

| Error Type | Count | Percentage | Impact |
|------------|-------|------------|--------|
| **500 Internal Server Error** | {count_500} | {pct_500}% | HIGH |
| **503 Service Unavailable** | {count_503} | {pct_503}% | HIGH |
| **504 Gateway Timeout** | {count_504} | {pct_504}% | HIGH |
| **429 Too Many Requests** | {count_429} | {pct_429}% | MEDIUM |
| **400 Bad Request** | {count_400} | {pct_400}% | LOW |
| **Connection Refused** | {count_connection} | {pct_connection}% | HIGH |

### Top 3 Errors

#### 1. {ERROR_TYPE} ({ERROR_COUNT} occurrences)

**Endpoint**: {endpoint}

**Sample Error**:
```
{error_message}
{stack_trace}
```

**Root Cause**: {database_connection_pool_exhausted | external_api_timeout | memory_leak}

**Recommendation**: {increase_connection_pool | add_timeout_handling | fix_memory_leak}

---

#### 2. {ERROR_TYPE} ({ERROR_COUNT} occurrences)

...

---

#### 3. {ERROR_TYPE} ({ERROR_COUNT} occurrences)

...

---

## Bottleneck Analysis

### Identified Bottlenecks

#### 1. {BOTTLENECK_DESCRIPTION}

**Severity**: {CRITICAL|HIGH|MEDIUM}

**Component**: {Database|API Server|External Service|Network}

**Evidence**:
- {Metric 1}: {value} (threshold: {threshold})
- {Metric 2}: {value} (threshold: {threshold})

**Impact**:
- Slows down {affected_endpoints}
- Causes {error_type} errors under load
- Reduces throughput by {percentage}%

**Recommendation**:
1. {Short-term fix - e.g., "Add database index on user_id column"}
2. {Medium-term fix - e.g., "Implement Redis caching for frequently accessed data"}
3. {Long-term fix - e.g., "Migrate to microservices architecture"}

---

#### 2. {BOTTLENECK_DESCRIPTION}

...

---

## Auto-Retry Summary

{IF auto_retry_used}
**Retry Attempts**: {retry_count}

**Strategies Used**:
1. `warm-up-services`: ✅ Succeeded (attempt 1)
   - Ran 30s warm-up period with 10 VUs
   - Services reached steady state before full load test
2. `scale-up-resources`: ❌ Failed (attempt 2)
   - Attempted to increase Docker container CPU limit
   - Still hitting resource constraints
3. `optimize-db-connections`: ✅ Succeeded (attempt 3)
   - Increased PostgreSQL connection pool from 20 to 50
   - p95 latency reduced from 850ms to 420ms

**Final Status**: {PASSED|FAILED} (after {total_attempts} retries)
{ELSE}
No auto-retry needed - all targets met on first attempt
{ENDIF}

---

## Comparison with Previous Tests

{IF previous_test_exists}
| Metric | Previous Test | Current Test | Change |
|--------|--------------|--------------|--------|
| **p95 Latency** | {prev_p95} ms | {curr_p95} ms | {delta_pct}% {⬆️|⬇️} |
| **Error Rate** | {prev_error}% | {curr_error}% | {delta_pct}% {⬆️|⬇️} |
| **Throughput** | {prev_rps} RPS | {curr_rps} RPS | {delta_pct}% {⬆️|⬇️} |

{IF regression}
⚠️ **Performance regression detected**:
- p95 latency increased by {delta_pct}%
- Possible causes: {new_feature_added | database_migration | dependency_update}
- Investigate: {commit_range} for performance-impacting changes
{ENDIF}
{ENDIF}

---

## Recommendations

### Immediate Actions (Before Deployment)

{IF critical_issues}
1. **Fix critical bottlenecks**:
   - {Bottleneck 1}: {Recommendation}
   - {Bottleneck 2}: {Recommendation}

2. **Reduce error rate**:
   - Fix {error_type_1} errors (accounting for {pct}% of failures)
   - Add retry logic for {error_type_2}

3. **Scale resources**:
   - Increase {CPU|Memory|Database connections}
   - Add horizontal replicas for {service_name}
{ELSE}
✅ No critical issues - system ready for production load
{ENDIF}

### Performance Optimizations

1. **Caching**:
   - Add Redis cache for `GET /api/v1/users` (reduces DB load by 60%)
   - Implement HTTP cache headers for static resources

2. **Database**:
   - Add index on `orders.user_id` column
   - Optimize slow query: `SELECT * FROM products WHERE...`

3. **Code**:
   - Reduce N+1 queries in `GET /api/v1/dashboard`
   - Use database connection pooling

4. **Infrastructure**:
   - Enable CDN for static assets
   - Add load balancer for API servers
   - Consider read replicas for database

---

## Test Environment

**Infrastructure**:
- API Server: {instance_type} ({cpu_count} vCPUs, {memory_gb} GB RAM)
- Database: {db_instance_type} ({db_cpu_count} vCPUs, {db_memory_gb} GB RAM)
- Load Generator: {load_gen_instance_type}

**Software Versions**:
- Node.js: {node_version}
- PostgreSQL: {postgres_version}
- k6: {k6_version}

**Network**:
- Region: {aws_region | azure_region}
- Latency: {network_latency_ms} ms (load generator to API)

---

## Raw Data

**Full Results**: `{test_results_json_path}`

**Grafana Dashboard**: `{grafana_url}` (if available)

**Logs**: `{log_file_path}`

---

## Exit Status

**Exit Code**: {0 if passed else 1}

**Blockers**: {blocker_count}

**Next Action**:
{IF passed}
✅ Load test passed - system can handle {vu_count} concurrent users
{ELSE IF skipped}
⚠️ Load test skipped - not required for this epic
{ELSE}
❌ Load test failed - fix {blocker_count} performance issues before deployment
{ENDIF}

---

**Report Generated by**: Gate 9 (Load Testing) - /optimize phase

**Template Version**: 1.0

**Generated**: {ISO_TIMESTAMP}

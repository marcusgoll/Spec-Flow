#!/usr/bin/env node
/**
 * Circuit Breaker Test Suite
 * Tests all circuit breaker functionality to prevent infinite loops
 */

import { checkCircuitBreaker, recordAgentCall, resetCircuit, getStatus } from './utils/circuit-breaker.mjs';

// ANSI colors for output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function assert(condition, message) {
  if (condition) {
    log('green', `✓ ${message}`);
    return true;
  } else {
    log('red', `✗ ${message}`);
    return false;
  }
}

// ===== Test Suite =====

async function runTests() {
  log('cyan', '\n════════════════════════════════════════');
  log('cyan', '  Circuit Breaker Test Suite');
  log('cyan', '════════════════════════════════════════\n');

  let passedTests = 0;
  let failedTests = 0;

  // Test 1: Normal Operation
  log('yellow', 'Test 1: Normal operation (first call allowed)');
  resetCircuit('Test1');
  const check1 = checkCircuitBreaker('Test1', null);
  if (assert(check1.allowed === true, 'First call should be allowed')) {
    passedTests++;
  } else {
    failedTests++;
  }
  recordAgentCall('Test1', null);

  // Test 2: Recursion Depth Limit
  log('yellow', '\nTest 2: Recursion depth limit (should block after 5)');
  resetCircuit('Test2');

  // Simulate 6 nested calls
  for (let i = 0; i < 6; i++) {
    recordAgentCall('Test2', 'Parent');
  }

  const check2 = checkCircuitBreaker('Test2', 'Parent');
  if (assert(check2.allowed === false, 'Should block after max depth (5)')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(check2.reason?.includes('recursion') || check2.reason?.includes('depth'), 'Error message should mention recursion depth')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Test 3: Call Frequency Limit
  log('yellow', '\nTest 3: Call frequency limit (should block after 10/min)');
  resetCircuit('Test3');

  // Simulate 11 rapid calls
  for (let i = 0; i < 11; i++) {
    recordAgentCall('Test3', null);
  }

  const check3 = checkCircuitBreaker('Test3', null);
  if (assert(check3.allowed === false, 'Should block after max frequency (10/min)')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(check3.reason?.includes('frequency'), 'Error message should mention call frequency')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Test 4: Circuit Reset
  log('yellow', '\nTest 4: Circuit reset functionality');
  resetCircuit('Test3');
  const check4 = checkCircuitBreaker('Test3', null);
  if (assert(check4.allowed === true, 'Circuit should be closed after reset')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Test 5: Multiple Agent Types
  log('yellow', '\nTest 5: Multiple agent types tracked independently');
  resetCircuit();

  for (let i = 0; i < 5; i++) {
    recordAgentCall('AgentA', null);
  }
  for (let i = 0; i < 3; i++) {
    recordAgentCall('AgentB', null);
  }

  const checkA = checkCircuitBreaker('AgentA', null);
  const checkB = checkCircuitBreaker('AgentB', null);

  if (assert(checkA.allowed === true, 'AgentA should still be allowed (5 < 10)')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(checkB.allowed === true, 'AgentB should be tracked independently')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Test 6: Status Reporting
  log('yellow', '\nTest 6: Status reporting');
  const status = getStatus();

  if (assert(status.config !== undefined, 'Status should include config')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(status.stats !== undefined, 'Status should include stats')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(Object.keys(status.stats).length > 0, 'Status should track agent types')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Test 7: Parent Agent Tracking
  log('yellow', '\nTest 7: Parent agent tracking');
  resetCircuit('Test7');

  recordAgentCall('Test7', 'ParentAgent');
  recordAgentCall('Test7', 'ParentAgent');

  const statusWithParent = getStatus();
  const test7Stats = statusWithParent.stats['Test7'];

  if (assert(test7Stats !== undefined, 'Should track agent with parent')) {
    passedTests++;
  } else {
    failedTests++;
  }

  if (assert(test7Stats.totalCalls === 2, 'Should count calls with parent')) {
    passedTests++;
  } else {
    failedTests++;
  }

  // Final Summary
  log('cyan', '\n════════════════════════════════════════');
  log('cyan', '  Test Results');
  log('cyan', '════════════════════════════════════════\n');

  const totalTests = passedTests + failedTests;
  const passRate = ((passedTests / totalTests) * 100).toFixed(1);

  log('green', `Passed: ${passedTests}/${totalTests}`);
  if (failedTests > 0) {
    log('red', `Failed: ${failedTests}/${totalTests}`);
  }
  log('cyan', `Pass Rate: ${passRate}%\n`);

  // Cleanup
  log('yellow', 'Cleaning up test data...');
  resetCircuit();
  log('green', 'Cleanup complete!\n');

  // Exit with appropriate code
  if (failedTests > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

// Run tests
runTests().catch(error => {
  log('red', `\nTest suite error: ${error.message}`);
  log('red', error.stack);
  process.exit(1);
});

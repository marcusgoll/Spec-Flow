#!/usr/bin/env node
/**
 * Circuit Breaker for Agent Spawning
 * Prevents infinite loops by tracking agent invocations and implementing safety limits
 *
 * Usage:
 *   import { checkCircuitBreaker, recordAgentCall, resetCircuit } from './circuit-breaker.mjs';
 *
 * Features:
 *   - Max recursion depth (prevents agent → agent → agent loops)
 *   - Time window limits (prevents rapid repeated calls)
 *   - Call frequency tracking
 *   - Automatic circuit reset after cooldown period
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ===== Configuration =====
const CONFIG = {
  maxRecursionDepth: 5,           // Max agent call chain depth
  maxCallsPerMinute: 10,          // Max calls per agent per minute
  cooldownPeriod: 300000,         // 5 minutes in ms
  cacheDir: path.join(process.cwd(), '.spec-flow', 'cache'),
  cacheFile: 'agent-circuit-breaker.json',
  cleanupInterval: 3600000,       // 1 hour - cleanup old entries
};

// ===== Type Definitions =====

/**
 * @typedef {Object} AgentCallRecord
 * @property {string} agentType - Type of agent (e.g., 'Plan', 'Explore', 'backend-dev')
 * @property {number} timestamp - Unix timestamp of call
 * @property {number} depth - Recursion depth
 * @property {string} parentAgent - Parent agent type (if any)
 */

/**
 * @typedef {Object} CircuitState
 * @property {AgentCallRecord[]} calls - Array of recent agent calls
 * @property {Object.<string, number>} openCircuits - Agents with open circuits (agentType -> timestamp)
 * @property {number} lastCleanup - Last cleanup timestamp
 */

// ===== Cache Management =====

function getCachePath() {
  const cacheDir = CONFIG.cacheDir;
  if (!fs.existsSync(cacheDir)) {
    fs.mkdirSync(cacheDir, { recursive: true });
  }
  return path.join(cacheDir, CONFIG.cacheFile);
}

/**
 * Load circuit breaker state from cache
 * @returns {CircuitState}
 */
function loadState() {
  const cachePath = getCachePath();

  if (!fs.existsSync(cachePath)) {
    return {
      calls: [],
      openCircuits: {},
      lastCleanup: Date.now(),
    };
  }

  try {
    const data = fs.readFileSync(cachePath, 'utf-8');
    return JSON.parse(data);
  } catch (error) {
    console.error('[Circuit Breaker] Failed to load state:', error.message);
    return {
      calls: [],
      openCircuits: {},
      lastCleanup: Date.now(),
    };
  }
}

/**
 * Save circuit breaker state to cache
 * @param {CircuitState} state
 */
function saveState(state) {
  const cachePath = getCachePath();

  try {
    fs.writeFileSync(cachePath, JSON.stringify(state, null, 2), 'utf-8');
  } catch (error) {
    console.error('[Circuit Breaker] Failed to save state:', error.message);
  }
}

/**
 * Clean up old call records
 * @param {CircuitState} state
 * @returns {CircuitState}
 */
function cleanupOldRecords(state) {
  const now = Date.now();

  // Only cleanup if enough time has passed
  if (now - state.lastCleanup < CONFIG.cleanupInterval) {
    return state;
  }

  // Remove calls older than cooldown period
  const cutoff = now - CONFIG.cooldownPeriod;
  state.calls = state.calls.filter(call => call.timestamp > cutoff);

  // Remove expired open circuits
  for (const [agentType, timestamp] of Object.entries(state.openCircuits)) {
    if (now - timestamp > CONFIG.cooldownPeriod) {
      delete state.openCircuits[agentType];
    }
  }

  state.lastCleanup = now;
  return state;
}

// ===== Circuit Breaker Logic =====

/**
 * Get current recursion depth for an agent chain
 * @param {AgentCallRecord[]} calls
 * @param {string} agentType
 * @returns {number}
 */
function getRecursionDepth(calls, agentType) {
  // Find the most recent call chain
  const recentCalls = calls
    .filter(c => Date.now() - c.timestamp < 60000) // Last minute
    .reverse();

  let depth = 0;
  let currentAgent = agentType;

  for (const call of recentCalls) {
    if (call.agentType === currentAgent) {
      depth = Math.max(depth, call.depth + 1);
      currentAgent = call.parentAgent;
    }
  }

  return depth;
}

/**
 * Get call frequency for an agent type
 * @param {AgentCallRecord[]} calls
 * @param {string} agentType
 * @returns {number}
 */
function getCallFrequency(calls, agentType) {
  const now = Date.now();
  const oneMinuteAgo = now - 60000;

  return calls.filter(
    call => call.agentType === agentType && call.timestamp > oneMinuteAgo
  ).length;
}

/**
 * Check if circuit breaker allows agent call
 * @param {string} agentType - Type of agent to call
 * @param {string} [parentAgent] - Parent agent type (if nested call)
 * @returns {{allowed: boolean, reason?: string}}
 */
export function checkCircuitBreaker(agentType, parentAgent = null) {
  let state = loadState();
  state = cleanupOldRecords(state);

  // Check if circuit is already open for this agent
  if (state.openCircuits[agentType]) {
    const openTime = state.openCircuits[agentType];
    const elapsed = Date.now() - openTime;

    if (elapsed < CONFIG.cooldownPeriod) {
      return {
        allowed: false,
        reason: `Circuit open for ${agentType} (cooldown: ${Math.round((CONFIG.cooldownPeriod - elapsed) / 1000)}s remaining)`,
      };
    } else {
      // Cooldown expired, close circuit
      delete state.openCircuits[agentType];
      saveState(state);
    }
  }

  // Check recursion depth
  const depth = getRecursionDepth(state.calls, agentType);
  if (depth >= CONFIG.maxRecursionDepth) {
    state.openCircuits[agentType] = Date.now();
    saveState(state);

    return {
      allowed: false,
      reason: `Max recursion depth exceeded for ${agentType} (depth: ${depth}, max: ${CONFIG.maxRecursionDepth})`,
    };
  }

  // Check call frequency
  const frequency = getCallFrequency(state.calls, agentType);
  if (frequency >= CONFIG.maxCallsPerMinute) {
    state.openCircuits[agentType] = Date.now();
    saveState(state);

    return {
      allowed: false,
      reason: `Max call frequency exceeded for ${agentType} (${frequency} calls/min, max: ${CONFIG.maxCallsPerMinute})`,
    };
  }

  return { allowed: true };
}

/**
 * Record an agent call
 * @param {string} agentType
 * @param {string} [parentAgent]
 */
export function recordAgentCall(agentType, parentAgent = null) {
  let state = loadState();
  state = cleanupOldRecords(state);

  const depth = getRecursionDepth(state.calls, agentType);

  state.calls.push({
    agentType,
    timestamp: Date.now(),
    depth,
    parentAgent: parentAgent || null,
  });

  saveState(state);
}

/**
 * Reset circuit breaker for a specific agent or all agents
 * @param {string} [agentType] - Agent to reset (omit to reset all)
 */
export function resetCircuit(agentType = null) {
  let state = loadState();

  if (agentType) {
    // Reset specific agent
    delete state.openCircuits[agentType];
    state.calls = state.calls.filter(call => call.agentType !== agentType);
  } else {
    // Reset all
    state = {
      calls: [],
      openCircuits: {},
      lastCleanup: Date.now(),
    };
  }

  saveState(state);
}

/**
 * Get current circuit breaker status
 * @returns {Object}
 */
export function getStatus() {
  let state = loadState();
  state = cleanupOldRecords(state);

  const stats = {};

  // Calculate stats per agent type
  const agentTypes = [...new Set(state.calls.map(c => c.agentType))];

  for (const agentType of agentTypes) {
    const calls = state.calls.filter(c => c.agentType === agentType);
    const frequency = getCallFrequency(state.calls, agentType);
    const depth = getRecursionDepth(state.calls, agentType);
    const isOpen = !!state.openCircuits[agentType];

    stats[agentType] = {
      totalCalls: calls.length,
      recentCalls: frequency,
      currentDepth: depth,
      circuitOpen: isOpen,
      cooldownRemaining: isOpen
        ? Math.max(0, Math.round((CONFIG.cooldownPeriod - (Date.now() - state.openCircuits[agentType])) / 1000))
        : 0,
    };
  }

  return {
    config: CONFIG,
    stats,
    openCircuits: Object.keys(state.openCircuits),
  };
}

// ===== CLI Interface =====

if (import.meta.url === `file://${process.argv[1]}`) {
  const command = process.argv[2];

  switch (command) {
    case 'status':
      console.log(JSON.stringify(getStatus(), null, 2));
      break;

    case 'reset':
      const agentType = process.argv[3];
      resetCircuit(agentType);
      console.log(agentType ? `Reset circuit for ${agentType}` : 'Reset all circuits');
      break;

    case 'check':
      const agent = process.argv[3];
      if (!agent) {
        console.error('Usage: circuit-breaker.mjs check <agent-type>');
        process.exit(1);
      }
      const result = checkCircuitBreaker(agent);
      console.log(JSON.stringify(result, null, 2));
      break;

    default:
      console.log('Circuit Breaker CLI');
      console.log('Usage:');
      console.log('  node circuit-breaker.mjs status                 - Show current status');
      console.log('  node circuit-breaker.mjs check <agent-type>     - Check if agent call allowed');
      console.log('  node circuit-breaker.mjs reset [agent-type]     - Reset circuit(s)');
      break;
  }
}

/**
 * State Validator
 *
 * Validates workflow-state.yaml structure and state transitions.
 */

import { existsSync, readFileSync } from 'fs';
import { load } from 'js-yaml';

/**
 * Validation result
 */
class ValidationResult {
  constructor(valid, errors = []) {
    this.valid = valid;
    this.errors = errors;
  }

  static success() {
    return new ValidationResult(true, []);
  }

  static failure(errors) {
    return new ValidationResult(false, Array.isArray(errors) ? errors : [errors]);
  }
}

/**
 * Valid workflow phases
 */
const VALID_PHASES = [
  'initialization',
  'specification',
  'clarification',
  'planning',
  'task_breakdown',
  'validation',
  'implementation',
  'optimization',
  'ship_staging',
  'validate_staging',
  'ship_prod',
  'deploy_prod',
  'build_local',
  'finalization',
  'completed'
];

/**
 * Valid phase statuses
 */
const VALID_STATUSES = [
  'pending',
  'in_progress',
  'blocked',
  'completed',
  'failed',
  'skipped'
];

/**
 * Valid epic states
 */
const VALID_EPIC_STATES = [
  'Planned',
  'ContractsLocked',
  'Implementing',
  'Review',
  'Integrated',
  'Released'
];

/**
 * Validate workflow state YAML structure
 */
export function validateWorkflowState(statePath) {
  const errors = [];

  if (!existsSync(statePath)) {
    return ValidationResult.failure('workflow-state.yaml not found');
  }

  let state;
  try {
    const content = readFileSync(statePath, 'utf-8');
    state = load(content);
  } catch (error) {
    return ValidationResult.failure(`Invalid YAML: ${error.message}`);
  }

  // Check required fields
  const requiredFields = ['version', 'feature_slug', 'phase', 'status'];
  for (const field of requiredFields) {
    if (!(field in state)) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Validate version
  if (state.version && !state.version.match(/^\d+\.\d+\.\d+$/)) {
    errors.push(`Invalid version format: ${state.version}`);
  }

  // Validate phase
  if (state.phase && !VALID_PHASES.includes(state.phase)) {
    errors.push(`Invalid phase: ${state.phase}`);
  }

  // Validate status
  if (state.status && !VALID_STATUSES.includes(state.status)) {
    errors.push(`Invalid status: ${state.status}`);
  }

  // Validate epic mode
  if (state.epic_mode === true) {
    if (!state.epics || !Array.isArray(state.epics)) {
      errors.push('Epic mode enabled but epics array missing');
    }
  }

  // Validate deployment model
  if (state.deployment && state.deployment.model) {
    const validModels = ['staging-prod', 'direct-prod', 'local-only'];
    if (!validModels.includes(state.deployment.model)) {
      errors.push(`Invalid deployment model: ${state.deployment.model}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate epic state within workflow state
 */
export function validateEpicState(epicState) {
  const errors = [];

  // Check required epic fields
  const requiredFields = ['name', 'slug', 'state'];
  for (const field of requiredFields) {
    if (!(field in epicState)) {
      errors.push(`Missing required epic field: ${field}`);
    }
  }

  // Validate epic state
  if (epicState.state && !VALID_EPIC_STATES.includes(epicState.state)) {
    errors.push(`Invalid epic state: ${epicState.state}`);
  }

  // Validate sprints if present
  if (epicState.sprints) {
    if (!Array.isArray(epicState.sprints)) {
      errors.push('Epic sprints must be an array');
    } else {
      for (const sprint of epicState.sprints) {
        if (!sprint.id || !sprint.status) {
          errors.push(`Invalid sprint structure in epic: ${epicState.slug}`);
        }
      }
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate phase transition
 */
export function validatePhaseTransition(currentPhase, nextPhase) {
  const errors = [];

  if (!VALID_PHASES.includes(currentPhase)) {
    errors.push(`Invalid current phase: ${currentPhase}`);
  }

  if (!VALID_PHASES.includes(nextPhase)) {
    errors.push(`Invalid next phase: ${nextPhase}`);
  }

  // Check transition validity (basic sequential check)
  const currentIndex = VALID_PHASES.indexOf(currentPhase);
  const nextIndex = VALID_PHASES.indexOf(nextPhase);

  if (currentIndex === -1 || nextIndex === -1) {
    errors.push('Phase not found in valid phases list');
  } else if (nextIndex < currentIndex) {
    errors.push(`Invalid backward transition: ${currentPhase} -> ${nextPhase}`);
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate manual gates
 */
export function validateManualGates(state) {
  const errors = [];

  if (!state.manual_gates) {
    return ValidationResult.success(); // Optional section
  }

  // Validate mockup approval gate
  if (state.manual_gates.mockup_approval) {
    const gate = state.manual_gates.mockup_approval;
    const validStatuses = ['pending', 'approved', 'rejected', 'not_required'];

    if (!validStatuses.includes(gate.status)) {
      errors.push(`Invalid mockup approval status: ${gate.status}`);
    }

    if (gate.status === 'approved' && !gate.approved_at) {
      errors.push('Mockup approval approved but missing approved_at timestamp');
    }
  }

  // Validate staging validation gate
  if (state.manual_gates.staging_validation) {
    const gate = state.manual_gates.staging_validation;
    const validStatuses = ['pending', 'validated', 'failed', 'not_required'];

    if (!validStatuses.includes(gate.status)) {
      errors.push(`Invalid staging validation status: ${gate.status}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate quality gates
 */
export function validateQualityGates(state) {
  const errors = [];

  if (!state.quality_gates) {
    return ValidationResult.success(); // Optional section
  }

  const validGateStatuses = ['pending', 'passed', 'failed', 'skipped'];

  // Check common gates
  const commonGates = ['pre_flight', 'code_review', 'rollback_test'];
  for (const gateName of commonGates) {
    if (state.quality_gates[gateName]) {
      const gate = state.quality_gates[gateName];
      if (!validGateStatuses.includes(gate.status)) {
        errors.push(`Invalid ${gateName} gate status: ${gate.status}`);
      }
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate deployment info
 */
export function validateDeploymentInfo(state) {
  const errors = [];

  if (!state.deployment) {
    return ValidationResult.success(); // Optional until deployment phase
  }

  // Validate staging deployment
  if (state.deployment.staging) {
    const staging = state.deployment.staging;

    if (staging.status && !['pending', 'deployed', 'failed'].includes(staging.status)) {
      errors.push(`Invalid staging deployment status: ${staging.status}`);
    }

    if (staging.status === 'deployed' && !staging.url) {
      errors.push('Staging deployed but missing URL');
    }
  }

  // Validate production deployment
  if (state.deployment.production) {
    const production = state.deployment.production;

    if (production.status && !['pending', 'deployed', 'failed'].includes(production.status)) {
      errors.push(`Invalid production deployment status: ${production.status}`);
    }

    if (production.status === 'deployed' && !production.url) {
      errors.push('Production deployed but missing URL');
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Comprehensive workflow state validation
 */
export function validateCompleteState(statePath) {
  const errors = [];

  // First validate basic structure
  const structureResult = validateWorkflowState(statePath);
  if (!structureResult.valid) {
    return structureResult;
  }

  // Load state for deeper validation
  const content = readFileSync(statePath, 'utf-8');
  const state = load(content);

  // Validate epic states if present
  if (state.epic_mode && state.epics) {
    for (const epic of state.epics) {
      const epicResult = validateEpicState(epic);
      if (!epicResult.valid) {
        errors.push(...epicResult.errors);
      }
    }
  }

  // Validate manual gates
  const gatesResult = validateManualGates(state);
  if (!gatesResult.valid) {
    errors.push(...gatesResult.errors);
  }

  // Validate quality gates
  const qualityResult = validateQualityGates(state);
  if (!qualityResult.valid) {
    errors.push(...qualityResult.errors);
  }

  // Validate deployment info
  const deploymentResult = validateDeploymentInfo(state);
  if (!deploymentResult.valid) {
    errors.push(...deploymentResult.errors);
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

export default {
  validateWorkflowState,
  validateEpicState,
  validatePhaseTransition,
  validateManualGates,
  validateQualityGates,
  validateDeploymentInfo,
  validateCompleteState,
  ValidationResult,
  VALID_PHASES,
  VALID_STATUSES,
  VALID_EPIC_STATES
};

/**
 * Artifact Validator
 *
 * Validates that generated artifacts match expected templates and structure.
 */

import { existsSync, readFileSync, statSync } from 'fs';
import { join } from 'path';

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
 * Validate spec.md artifact
 */
export function validateSpec(specPath) {
  const errors = [];

  if (!existsSync(specPath)) {
    return ValidationResult.failure('spec.md not found');
  }

  const content = readFileSync(specPath, 'utf-8');

  // Check required sections
  const requiredSections = [
    '# Feature:',
    '## User Stories',
    '## Acceptance Criteria'
  ];

  for (const section of requiredSections) {
    if (!content.includes(section)) {
      errors.push(`Missing required section: ${section}`);
    }
  }

  // Check minimum length
  if (content.length < 500) {
    errors.push('Spec appears too short (< 500 characters)');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate plan.md artifact
 */
export function validatePlan(planPath) {
  const errors = [];

  if (!existsSync(planPath)) {
    return ValidationResult.failure('plan.md not found');
  }

  const content = readFileSync(planPath, 'utf-8');

  // Check required sections
  const requiredSections = [
    '# Implementation Plan',
    '## Architecture',
    '## Code Reuse Analysis'
  ];

  for (const section of requiredSections) {
    if (!content.includes(section)) {
      errors.push(`Missing required section: ${section}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate tasks.md artifact
 */
export function validateTasks(tasksPath) {
  const errors = [];

  if (!existsSync(tasksPath)) {
    return ValidationResult.failure('tasks.md not found');
  }

  const content = readFileSync(tasksPath, 'utf-8');

  // Count tasks (T001, T002, etc.)
  const taskMatches = content.match(/T\d{3}/g);
  const taskCount = taskMatches ? taskMatches.length : 0;

  if (taskCount < 5) {
    errors.push(`Too few tasks: ${taskCount} (expected 5-15)`);
  }

  if (taskCount > 30) {
    errors.push(`Too many tasks: ${taskCount} (expected 5-15 for features, max 30 for epics)`);
  }

  // Check TDD structure
  if (!content.includes('RED') && !content.includes('Test')) {
    errors.push('Missing TDD indicators (RED/GREEN/REFACTOR or Test mentions)');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate NOTES.md artifact
 */
export function validateNotes(notesPath) {
  const errors = [];

  if (!existsSync(notesPath)) {
    return ValidationResult.failure('NOTES.md not found');
  }

  const content = readFileSync(notesPath, 'utf-8');

  // Check basic structure
  if (!content.includes('# Implementation Notes')) {
    errors.push('Missing header: # Implementation Notes');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate project docs (8 files)
 */
export function validateProjectDocs(docsDir) {
  const errors = [];

  const requiredDocs = [
    'overview.md',
    'system-architecture.md',
    'tech-stack.md',
    'data-architecture.md',
    'api-strategy.md',
    'capacity-planning.md',
    'deployment-strategy.md',
    'development-workflow.md'
  ];

  for (const doc of requiredDocs) {
    const docPath = join(docsDir, doc);
    if (!existsSync(docPath)) {
      errors.push(`Missing project doc: ${doc}`);
    } else {
      const content = readFileSync(docPath, 'utf-8');
      if (content.length < 200) {
        errors.push(`Project doc too short: ${doc}`);
      }
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate design docs (4 files)
 */
export function validateDesignDocs(designDir) {
  const errors = [];

  const requiredDocs = [
    'brand-guidelines.md',
    'visual-language.md',
    'accessibility-standards.md',
    'component-governance.md'
  ];

  for (const doc of requiredDocs) {
    const docPath = join(designDir, doc);
    if (!existsSync(docPath)) {
      errors.push(`Missing design doc: ${doc}`);
    } else {
      const content = readFileSync(docPath, 'utf-8');
      if (content.length < 200) {
        errors.push(`Design doc too short: ${doc}`);
      }
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate epic-spec.md
 */
export function validateEpicSpec(epicSpecPath) {
  const errors = [];

  if (!existsSync(epicSpecPath)) {
    return ValidationResult.failure('epic-spec.md not found');
  }

  const content = readFileSync(epicSpecPath, 'utf-8');

  // Check Markdown structure
  if (!content.includes('# Epic:') && !content.includes('## Overview')) {
    errors.push('Missing epic title or overview section');
  }

  if (!content.includes('## Objective') && !content.includes('## Goal')) {
    errors.push('Missing objective/goal section');
  }

  if (!content.includes('## Subsystems') || !content.includes('## Components')) {
    errors.push('Missing subsystems/components section');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate sprint-plan.md
 */
export function validateSprintPlan(sprintPlanPath) {
  const errors = [];

  if (!existsSync(sprintPlanPath)) {
    return ValidationResult.failure('sprint-plan.md not found');
  }

  const content = readFileSync(sprintPlanPath, 'utf-8');

  // Check Markdown structure
  if (!content.includes('# Sprint Plan') && !content.includes('## Sprint Plan')) {
    errors.push('Missing sprint plan title');
  }

  if (!content.includes('## Sprint') && !content.includes('### Sprint')) {
    errors.push('Missing sprint sections');
  }

  if (!content.includes('Dependencies') && !content.includes('dependencies')) {
    errors.push('Missing dependencies section');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate mockup files
 */
export function validateMockups(mockupsDir) {
  const errors = [];

  if (!existsSync(mockupsDir)) {
    return ValidationResult.failure('mockups/ directory not found');
  }

  // Check for mockup-approval-checklist.md
  const checklistPath = join(mockupsDir, 'mockup-approval-checklist.md');
  if (!existsSync(checklistPath)) {
    errors.push('Missing mockup-approval-checklist.md');
  }

  // Check for HTML files
  const fs = await import('fs');
  const files = fs.readdirSync(mockupsDir);
  const htmlFiles = files.filter(f => f.endsWith('.html'));

  if (htmlFiles.length === 0) {
    errors.push('No HTML mockup files found');
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate artifact set based on workflow phase
 */
export function validateWorkflowArtifacts(featureDir, phase) {
  const errors = [];

  switch (phase) {
    case 'spec':
      const specResult = validateSpec(join(featureDir, 'spec.md'));
      if (!specResult.valid) {
        errors.push(...specResult.errors);
      }
      break;

    case 'plan':
      const planResult = validatePlan(join(featureDir, 'plan.md'));
      if (!planResult.valid) {
        errors.push(...planResult.errors);
      }
      break;

    case 'tasks':
      const tasksResult = validateTasks(join(featureDir, 'tasks.md'));
      if (!tasksResult.valid) {
        errors.push(...tasksResult.errors);
      }
      break;

    case 'implement':
      const notesResult = validateNotes(join(featureDir, 'NOTES.md'));
      if (!notesResult.valid) {
        errors.push(...notesResult.errors);
      }
      break;

    default:
      errors.push(`Unknown phase: ${phase}`);
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

export default {
  validateSpec,
  validatePlan,
  validateTasks,
  validateNotes,
  validateProjectDocs,
  validateDesignDocs,
  validateEpicSpec,
  validateSprintPlan,
  validateMockups,
  validateWorkflowArtifacts,
  ValidationResult
};

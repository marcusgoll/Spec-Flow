/**
 * Structure Validator
 *
 * Validates directory structure and file organization.
 */

import { existsSync, statSync, readdirSync } from "fs";
import { join } from "path";

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
    return new ValidationResult(
      false,
      Array.isArray(errors) ? errors : [errors]
    );
  }
}

/**
 * Check if path exists and is a directory
 */
function isDirectory(path) {
  return existsSync(path) && statSync(path).isDirectory();
}

/**
 * Check if path exists and is a file
 */
function isFile(path) {
  return existsSync(path) && statSync(path).isFile();
}

/**
 * Validate feature workspace structure
 */
export function validateFeatureStructure(featureDir) {
  const errors = [];

  if (!isDirectory(featureDir)) {
    return ValidationResult.failure(
      `Feature directory not found: ${featureDir}`
    );
  }

  // Required files
  const requiredFiles = ["spec.md", "NOTES.md", "state.yaml"];

  for (const file of requiredFiles) {
    if (!isFile(join(featureDir, file))) {
      errors.push(`Missing required file: ${file}`);
    }
  }

  // Required directories
  const requiredDirs = ["visuals"];

  for (const dir of requiredDirs) {
    if (!isDirectory(join(featureDir, dir))) {
      errors.push(`Missing required directory: ${dir}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate epic workspace structure
 */
export function validateEpicStructure(epicDir) {
  const errors = [];

  if (!isDirectory(epicDir)) {
    return ValidationResult.failure(`Epic directory not found: ${epicDir}`);
  }

  // Required files
  const requiredFiles = ["epic-spec.md", "state.yaml"];

  for (const file of requiredFiles) {
    if (!isFile(join(epicDir, file))) {
      errors.push(`Missing required file: ${file}`);
    }
  }

  // Check for sprints directory
  if (!isDirectory(join(epicDir, "sprints"))) {
    errors.push("Missing sprints/ directory");
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate project structure (minimal)
 */
export function validateProjectStructure(projectDir) {
  const errors = [];

  if (!isDirectory(projectDir)) {
    return ValidationResult.failure(
      `Project directory not found: ${projectDir}`
    );
  }

  // Required directories
  const requiredDirs = [".claude", ".spec-flow", "specs"];

  for (const dir of requiredDirs) {
    if (!isDirectory(join(projectDir, dir))) {
      errors.push(`Missing required directory: ${dir}`);
    }
  }

  // Check .claude subdirectories
  const claudeDirs = ["commands", "agents", "skills"];
  for (const dir of claudeDirs) {
    if (!isDirectory(join(projectDir, ".claude", dir))) {
      errors.push(`Missing .claude/${dir} directory`);
    }
  }

  // Check .spec-flow subdirectories
  const specFlowDirs = ["memory", "templates", "scripts"];
  for (const dir of specFlowDirs) {
    if (!isDirectory(join(projectDir, ".spec-flow", dir))) {
      errors.push(`Missing .spec-flow/${dir} directory`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate project docs structure (after /init-project)
 */
export function validateProjectDocsStructure(projectDir) {
  const errors = [];

  const docsDir = join(projectDir, "docs", "project");

  if (!isDirectory(docsDir)) {
    return ValidationResult.failure("docs/project/ directory not found");
  }

  // Required docs (8 files)
  const requiredDocs = [
    "overview.md",
    "system-architecture.md",
    "tech-stack.md",
    "data-architecture.md",
    "api-strategy.md",
    "capacity-planning.md",
    "deployment-strategy.md",
    "development-workflow.md",
  ];

  for (const doc of requiredDocs) {
    if (!isFile(join(docsDir, doc))) {
      errors.push(`Missing project doc: ${doc}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate design system structure (after /init-project --with-design)
 */
export function validateDesignSystemStructure(projectDir) {
  const errors = [];

  const designDocsDir = join(projectDir, "docs", "design");
  const tokensDir = join(projectDir, "design", "systems");

  // Check design docs
  if (!isDirectory(designDocsDir)) {
    errors.push("docs/design/ directory not found");
  } else {
    const requiredDocs = [
      "brand-guidelines.md",
      "visual-language.md",
      "accessibility-standards.md",
      "component-governance.md",
    ];

    for (const doc of requiredDocs) {
      if (!isFile(join(designDocsDir, doc))) {
        errors.push(`Missing design doc: ${doc}`);
      }
    }
  }

  // Check tokens
  if (!isDirectory(tokensDir)) {
    errors.push("design/systems/ directory not found");
  } else {
    const requiredTokens = ["tokens.css", "tokens.json"];
    for (const token of requiredTokens) {
      if (!isFile(join(tokensDir, token))) {
        errors.push(`Missing token file: ${token}`);
      }
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate UI-first mockup structure
 */
export function validateMockupStructure(featureDir, screenCount) {
  const errors = [];

  const mockupsDir = join(featureDir, "mockups");

  if (!isDirectory(mockupsDir)) {
    return ValidationResult.failure("mockups/ directory not found");
  }

  // Check for mockup-approval-checklist.md
  if (!isFile(join(mockupsDir, "mockup-approval-checklist.md"))) {
    errors.push("Missing mockup-approval-checklist.md");
  }

  // Check for HTML mockups
  const files = readdirSync(mockupsDir);
  const htmlFiles = files.filter((f) => f.endsWith(".html"));

  if (htmlFiles.length === 0) {
    errors.push("No HTML mockup files found");
  }

  // If 3+ screens, check for navigation hub
  if (screenCount >= 3) {
    if (!htmlFiles.includes("index.html")) {
      errors.push("Multi-screen mockup missing index.html navigation hub");
    }

    // Check for screen-XX-*.html pattern
    const screenPattern = /^screen-\d{2}-/;
    const screenFiles = htmlFiles.filter((f) => screenPattern.test(f));

    if (screenFiles.length < 3) {
      errors.push(
        `Expected at least 3 screen-XX-*.html files, found ${screenFiles.length}`
      );
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate contracts directory structure (epic mode)
 */
export function validateContractsStructure(projectDir) {
  const errors = [];

  const contractsDir = join(projectDir, "contracts");

  if (!isDirectory(contractsDir)) {
    return ValidationResult.failure("contracts/ directory not found");
  }

  // Check for api/ subdirectory
  if (!isDirectory(join(contractsDir, "api"))) {
    errors.push("contracts/api/ directory not found");
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate git repository structure
 */
export function validateGitStructure(projectDir) {
  const errors = [];

  const gitDir = join(projectDir, ".git");

  if (!isDirectory(gitDir)) {
    return ValidationResult.failure("Not a git repository");
  }

  // Check for basic git files
  const gitFiles = ["config", "HEAD"];
  for (const file of gitFiles) {
    if (!isFile(join(gitDir, file))) {
      errors.push(`Missing git file: ${file}`);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Validate GitHub Actions structure (for deployment)
 */
export function validateGitHubActionsStructure(projectDir) {
  const errors = [];

  const workflowsDir = join(projectDir, ".github", "workflows");

  if (!isDirectory(workflowsDir)) {
    return ValidationResult.failure(".github/workflows/ directory not found");
  }

  // Check for deployment workflows
  const files = readdirSync(workflowsDir);
  const workflowFiles = files.filter(
    (f) => f.endsWith(".yml") || f.endsWith(".yaml")
  );

  if (workflowFiles.length === 0) {
    errors.push("No workflow files found in .github/workflows/");
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

/**
 * Comprehensive structure validation
 */
export function validateCompleteStructure(projectDir, options = {}) {
  const errors = [];

  // Always validate base project structure
  const baseResult = validateProjectStructure(projectDir);
  if (!baseResult.valid) {
    errors.push(...baseResult.errors);
  }

  // Optionally validate project docs
  if (options.projectDocs) {
    const docsResult = validateProjectDocsStructure(projectDir);
    if (!docsResult.valid) {
      errors.push(...docsResult.errors);
    }
  }

  // Optionally validate design system
  if (options.designSystem) {
    const designResult = validateDesignSystemStructure(projectDir);
    if (!designResult.valid) {
      errors.push(...designResult.errors);
    }
  }

  // Optionally validate git
  if (options.git) {
    const gitResult = validateGitStructure(projectDir);
    if (!gitResult.valid) {
      errors.push(...gitResult.errors);
    }
  }

  // Optionally validate GitHub Actions
  if (options.githubActions) {
    const actionsResult = validateGitHubActionsStructure(projectDir);
    if (!actionsResult.valid) {
      errors.push(...actionsResult.errors);
    }
  }

  return errors.length > 0
    ? ValidationResult.failure(errors)
    : ValidationResult.success();
}

export default {
  validateFeatureStructure,
  validateEpicStructure,
  validateProjectStructure,
  validateProjectDocsStructure,
  validateDesignSystemStructure,
  validateMockupStructure,
  validateContractsStructure,
  validateGitStructure,
  validateGitHubActionsStructure,
  validateCompleteStructure,
  ValidationResult,
};

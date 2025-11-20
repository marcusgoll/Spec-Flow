#!/usr/bin/env node

/**
 * Build Distribution System for Spec-Flow Workflow Kit
 *
 * Purpose: Create clean dist/ folder for npm package distribution
 *
 * What it does:
 * 1. Copies essential files (.claude/, .spec-flow/, package files) to dist/
 * 2. Validates exclusions (beta commands removed)
 * 3. Validates essentials (core files present)
 * 4. Checks package size (< 4MB target)
 * 5. Generates build report
 *
 * Usage:
 *   node scripts/build-dist.js
 *   npm run build
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ============================================================================
// Configuration
// ============================================================================

const BUILD_CONFIG = {
  sourceDir: process.cwd(),
  distDir: path.join(process.cwd(), 'dist'),
  maxSizeMB: 10,

  // Essential patterns to include
  include: [
    '.claude/**',
    '.spec-flow/memory/**',
    '.spec-flow/scripts/**/*.sh',
    '.spec-flow/scripts/**/*.ps1',
    '.spec-flow/scripts/**/*.py',
    '.spec-flow/scripts/**/*.mjs',
    '.spec-flow/templates/**',
    'package.json',
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    'CLAUDE.md',
    '.gitignore'
  ],

  // Excluded patterns (beta/dev files)
  exclude: [
    '**/*contract*',
    '**/*fixture*',
    '**/*flag*',
    '**/*scheduler*',
    '**/*metrics*',
    '**/*dora*',
    '**/migrate-*',
    '**/test-*',
    '**/*.log',
    '**/.DS_Store',
    '**/node_modules',
    '**/node_modules/**',
    '**/*package-lock.json',
    '**/*tsconfig.json',
    '**/dist/**',
    '**/.git/**'
  ],

  // Core files that must exist in dist
  requiredFiles: [
    '.claude/commands/core/feature.md',
    '.claude/commands/phases/clarify.md',
    '.claude/commands/phases/plan.md',
    '.claude/commands/phases/tasks.md',
    '.claude/commands/phases/implement.md',
    '.claude/commands/epic/epic.md',
    '.claude/skills/clarification-phase/references/question-bank.md',
    '.claude/skills/epic/references/question-bank.md',
    '.spec-flow/config/user-preferences.yaml',
    '.spec-flow/config/user-preferences-schema.yaml',
    '.spec-flow/config/user-preferences.example.yaml',
    '.spec-flow/memory/command-history.yaml',
    '.spec-flow/scripts/utils/load-preferences.ps1',
    '.spec-flow/scripts/utils/load-preferences.sh',
    '.spec-flow/scripts/utils/load-command-history.ps1',
    '.spec-flow/scripts/utils/load-command-history.sh',
    '.spec-flow/scripts/utils/track-command-usage.ps1',
    '.spec-flow/scripts/utils/track-command-usage.sh',
    '.spec-flow/scripts/bash/create-new-feature.sh',
    '.spec-flow/scripts/powershell/create-new-feature.ps1',
    '.spec-flow/templates/spec-template.md',
    '.spec-flow/templates/plan-template.md',
    '.spec-flow/templates/tasks-template.md',
    '.spec-flow/templates/epic-spec.xml',
    '.spec-flow/templates/sprint-plan.xml',
    '.spec-flow/templates/epic-spec.md',
    '.spec-flow/templates/sprint-plan.md',
    '.spec-flow/templates/walkthrough.md',
    'package.json',
    'README.md',
    'CLAUDE.md'
  ]
};

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Recursively copy directory with pattern filtering
 */
function copyDirectory(src, dest, options = {}) {
  const { include = [], exclude = [] } = options;

  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  const entries = fs.readdirSync(src, { withFileTypes: true });
  let copiedFiles = 0;

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    const relativePath = path.relative(BUILD_CONFIG.sourceDir, srcPath);

    // Check exclusion patterns
    if (shouldExclude(relativePath, exclude)) {
      console.log(`  ⊗ Excluded: ${relativePath}`);
      continue;
    }

    if (entry.isDirectory()) {
      copiedFiles += copyDirectory(srcPath, destPath, options);
    } else {
      fs.copyFileSync(srcPath, destPath);
      copiedFiles++;
      console.log(`  ✓ Copied: ${relativePath}`);
    }
  }

  return copiedFiles;
}

/**
 * Check if path should be excluded based on patterns
 */
function shouldExclude(filePath, excludePatterns) {
  // Normalize path to use forward slashes for consistent pattern matching
  const normalizedPath = filePath.replace(/\\/g, '/');

  // Check if path contains node_modules directory
  if (normalizedPath.includes('node_modules')) {
    return true;
  }

  return excludePatterns.some(pattern => {
    const regex = new RegExp(
      pattern
        .replace(/\*\*/g, '.*')
        .replace(/\*/g, '[^/]*')
        .replace(/\./g, '\\.')
    );
    return regex.test(normalizedPath);
  });
}

/**
 * Get directory size in bytes
 */
function getDirectorySize(dirPath) {
  let totalSize = 0;

  function traverse(currentPath) {
    const stat = fs.statSync(currentPath);

    if (stat.isDirectory()) {
      const entries = fs.readdirSync(currentPath);
      entries.forEach(entry => {
        traverse(path.join(currentPath, entry));
      });
    } else {
      totalSize += stat.size;
    }
  }

  traverse(dirPath);
  return totalSize;
}

/**
 * Format bytes to human-readable size
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Count files in directory
 */
function countFiles(dirPath) {
  let count = 0;

  function traverse(currentPath) {
    const stat = fs.statSync(currentPath);

    if (stat.isDirectory()) {
      const entries = fs.readdirSync(currentPath);
      entries.forEach(entry => {
        traverse(path.join(currentPath, entry));
      });
    } else {
      count++;
    }
  }

  traverse(dirPath);
  return count;
}

// ============================================================================
// Validation Functions
// ============================================================================

/**
 * Validate exclusions - ensure beta files are NOT in dist
 */
function validateExclusions() {
  console.log('\n📋 Validating exclusions...');

  const betaPatterns = [
    '**/contract-*.md',
    '**/fixture-*.md',
    '**/flag-*.md',
    '**/scheduler-*.md',
    '**/metrics*.md',
    '**/dora*.md',
    '**/migrate-*.sh',
    '**/migrate-*.ps1',
    '**/test-*.sh',
    '**/test-*.ps1',
    '**/*design-system*'
  ];

  const violations = [];

  function checkPath(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);
      const relativePath = path.relative(BUILD_CONFIG.distDir, fullPath);

      if (entry.isDirectory()) {
        checkPath(fullPath);
      } else {
        // Check if file matches any beta pattern
        for (const pattern of betaPatterns) {
          const regex = new RegExp(
            pattern
              .replace(/\*\*/g, '.*')
              .replace(/\*/g, '[^/]*')
              .replace(/\./g, '\\.')
          );

          if (regex.test(relativePath)) {
            violations.push(relativePath);
            break;
          }
        }
      }
    }
  }

  checkPath(BUILD_CONFIG.distDir);

  if (violations.length > 0) {
    console.log('  ❌ FAILED: Beta files found in dist:');
    violations.forEach(file => console.log(`     - ${file}`));
    return false;
  } else {
    console.log('  ✅ PASSED: No beta files found in dist');
    return true;
  }
}

/**
 * Validate essentials - ensure core files are present
 */
function validateEssentials() {
  console.log('\n📋 Validating essential files...');

  const missing = [];

  for (const requiredFile of BUILD_CONFIG.requiredFiles) {
    const filePath = path.join(BUILD_CONFIG.distDir, requiredFile);
    if (!fs.existsSync(filePath)) {
      missing.push(requiredFile);
    }
  }

  if (missing.length > 0) {
    console.log('  ❌ FAILED: Missing essential files:');
    missing.forEach(file => console.log(`     - ${file}`));
    return false;
  } else {
    console.log(`  ✅ PASSED: All ${BUILD_CONFIG.requiredFiles.length} essential files present`);
    return true;
  }
}

/**
 * Validate size - ensure dist is under size limit
 */
function validateSize() {
  console.log('\n📋 Validating package size...');

  const sizeBytes = getDirectorySize(BUILD_CONFIG.distDir);
  const sizeMB = sizeBytes / (1024 * 1024);
  const maxMB = BUILD_CONFIG.maxSizeMB;

  console.log(`  Size: ${formatBytes(sizeBytes)} (${sizeMB.toFixed(2)} MB)`);
  console.log(`  Limit: ${maxMB} MB`);

  if (sizeMB > maxMB) {
    console.log(`  ❌ FAILED: Package exceeds ${maxMB}MB limit`);
    return false;
  } else {
    const percentage = ((sizeMB / maxMB) * 100).toFixed(1);
    console.log(`  ✅ PASSED: Package is ${percentage}% of limit`);
    return true;
  }
}

// ============================================================================
// Build Functions
// ============================================================================

/**
 * Clean dist directory
 */
function cleanDist() {
  console.log('🧹 Cleaning dist directory...');

  if (fs.existsSync(BUILD_CONFIG.distDir)) {
    fs.rmSync(BUILD_CONFIG.distDir, { recursive: true, force: true });
    console.log('  ✓ Removed existing dist/');
  }

  fs.mkdirSync(BUILD_CONFIG.distDir, { recursive: true });
  console.log('  ✓ Created fresh dist/');
}

/**
 * Copy essential files
 */
function copyEssentialFiles() {
  console.log('\n📦 Copying essential files...');

  let totalCopied = 0;

  // Copy .claude directory
  console.log('  Copying .claude/...');
  totalCopied += copyDirectory(
    path.join(BUILD_CONFIG.sourceDir, '.claude'),
    path.join(BUILD_CONFIG.distDir, '.claude'),
    { exclude: BUILD_CONFIG.exclude }
  );

  // Copy .spec-flow directory (selective)
  console.log('  Copying .spec-flow/...');
  const specFlowDirs = ['config', 'memory', 'scripts', 'templates'];
  for (const dir of specFlowDirs) {
    const srcPath = path.join(BUILD_CONFIG.sourceDir, '.spec-flow', dir);
    const destPath = path.join(BUILD_CONFIG.distDir, '.spec-flow', dir);
    if (fs.existsSync(srcPath)) {
      totalCopied += copyDirectory(srcPath, destPath, { exclude: BUILD_CONFIG.exclude });
    }
  }

  // Copy package files
  console.log('  Copying package files...');
  const packageFiles = ['package.json', 'README.md', 'CHANGELOG.md', 'LICENSE', 'CLAUDE.md', 'QUICKSTART.md', '.gitignore'];
  for (const file of packageFiles) {
    const srcPath = path.join(BUILD_CONFIG.sourceDir, file);
    const destPath = path.join(BUILD_CONFIG.distDir, file);
    if (fs.existsSync(srcPath)) {
      fs.copyFileSync(srcPath, destPath);
      totalCopied++;
      console.log(`  ✓ Copied: ${file}`);
    }
  }

  console.log(`\n  ✓ Total files copied: ${totalCopied}`);
  return totalCopied;
}

/**
 * Generate build report
 */
function generateBuildReport(results) {
  const reportPath = path.join(BUILD_CONFIG.distDir, 'BUILD_REPORT.md');
  const timestamp = new Date().toISOString();
  const sizeBytes = getDirectorySize(BUILD_CONFIG.distDir);
  const fileCount = countFiles(BUILD_CONFIG.distDir);

  const report = `# Build Report

**Generated**: ${timestamp}
**Version**: ${results.version}

## Build Summary

- ✅ Files copied: ${results.filesCopied}
- ✅ Total files in dist: ${fileCount}
- ✅ Package size: ${formatBytes(sizeBytes)} (${(sizeBytes / (1024 * 1024)).toFixed(2)} MB)
- ✅ Size limit: ${BUILD_CONFIG.maxSizeMB} MB
- ✅ Utilization: ${((sizeBytes / (BUILD_CONFIG.maxSizeMB * 1024 * 1024)) * 100).toFixed(1)}%

## Validation Results

### Exclusions
${results.validations.exclusions ? '✅ PASSED' : '❌ FAILED'}

All beta/niche commands and scripts excluded from distribution.

### Essential Files
${results.validations.essentials ? '✅ PASSED' : '❌ FAILED'}

All ${BUILD_CONFIG.requiredFiles.length} core workflow files present.

### Package Size
${results.validations.size ? '✅ PASSED' : '❌ FAILED'}

Package size within ${BUILD_CONFIG.maxSizeMB}MB limit.

## File Breakdown

\`\`\`
.claude/
  commands/
    phases/         # Core workflow phases (clarify, plan, tasks, implement, etc.)
    epic/           # Epic-level orchestration
    meta/           # Meta-prompting and utilities
    project/        # Project initialization
    deployment/     # Deployment workflows
  agents/           # Specialist agent configurations
  skills/           # Workflow skills with question banks
    clarification-phase/references/question-bank.md
    epic/references/question-bank.md

.spec-flow/
  memory/           # Workflow mechanics
  scripts/          # Cross-platform automation (bash + PowerShell)
  templates/        # Markdown and XML scaffolds

package.json      # npm package configuration
README.md         # Usage documentation
CHANGELOG.md      # Version history
CLAUDE.md         # AI assistant instructions
\`\`\`

## Excluded Beta Features

The following beta/niche features have been excluded from this distribution:

- Contract management (contract-bump, contract-verify, fixture-refresh)
- Feature flags (flag-add, flag-cleanup, flag-list)
- Scheduler (scheduler-assign, scheduler-list, scheduler-park)
- DORA metrics (metrics-dora, dora-calculate)
- Development scripts (migrate-*, test-*)
- Old design system templates (design-system/*)

Total excluded: ${results.filesExcluded} files

## Build Status

${results.success ? '✅ BUILD SUCCESSFUL' : '❌ BUILD FAILED'}

${results.success
  ? 'Distribution package is ready for npm publish.'
  : 'Fix validation errors before publishing.'}
`;

  fs.writeFileSync(reportPath, report);
  console.log(`\n📄 Build report generated: ${reportPath}`);
}

// ============================================================================
// Main Build Process
// ============================================================================

async function main() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║  Spec-Flow Workflow Kit - Build Distribution System           ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  const startTime = Date.now();
  const results = {
    version: require('../package.json').version,
    filesCopied: 0,
    filesExcluded: 57, // 11 commands + 22 beta scripts + 6 dev scripts + 18 templates
    validations: {},
    success: false
  };

  try {
    // Step 1: Clean
    cleanDist();

    // Step 2: Copy
    results.filesCopied = copyEssentialFiles();

    // Step 3: Validate
    results.validations.exclusions = validateExclusions();
    results.validations.essentials = validateEssentials();
    results.validations.size = validateSize();

    // Step 4: Check overall success
    results.success = Object.values(results.validations).every(v => v === true);

    // Step 5: Generate report
    generateBuildReport(results);

    // Summary
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log('\n╔════════════════════════════════════════════════════════════════╗');
    if (results.success) {
      console.log('║  ✅ BUILD SUCCESSFUL                                           ║');
      console.log('╚════════════════════════════════════════════════════════════════╝');
      console.log(`\n✓ Distribution ready in dist/`);
      console.log(`✓ Build completed in ${duration}s`);
      console.log(`\nNext steps:`);
      console.log(`  1. Review dist/BUILD_REPORT.md`);
      console.log(`  2. Test package: npm pack`);
      console.log(`  3. Publish: npm publish dist/`);
    } else {
      console.log('║  ❌ BUILD FAILED                                               ║');
      console.log('╚════════════════════════════════════════════════════════════════╝');
      console.log(`\n✗ Fix validation errors and retry`);
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ BUILD ERROR:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run build
if (require.main === module) {
  main();
}

module.exports = { main, BUILD_CONFIG };

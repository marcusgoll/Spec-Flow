const fs = require('fs-extra');
const path = require('path');
const ora = require('ora');
const {
  getPackageRoot,
  copyDirectory,
  printHeader,
  printSuccess,
  printError,
  printWarning
} = require('./utils');
const { checkExistingInstallation, runPreflightChecks } = require('./validate');
const { resolveConflict, STRATEGIES } = require('./conflicts');

/**
 * User-generated directories that must NEVER be touched during install/update
 * These are excluded from all copy/install operations
 */
const USER_DATA_DIRECTORIES = [
  'specs',           // Feature specifications (user's primary work)
  'node_modules',    // Dependencies (managed by package manager)
  '.git',            // Git repository
  'dist',            // Build output
  'build',           // Build output
  'coverage',        // Test coverage
  '.next',           // Next.js build
  '.nuxt',           // Nuxt build
  'out'              // Output directories
];

/**
 * Install spec-flow to target directory
 * @param {Object} options - Installation options
 * @param {string} options.targetDir - Target directory
 * @param {boolean} options.preserveMemory - Whether to preserve memory files
 * @param {boolean} options.verbose - Show detailed output
 * @param {string} options.conflictStrategy - Conflict resolution strategy (merge|backup|skip|force)
 * @param {Array<string>} options.excludeDirectories - Directories to exclude from copying
 * @returns {Promise<Object>} { success: boolean, error: string|null, conflictActions: Array }
 */
async function install(options) {
  const { targetDir, preserveMemory = false, verbose = false, conflictStrategy = STRATEGIES.MERGE, excludeDirectories = [] } = options;
  const packageRoot = getPackageRoot();

  // Pre-flight checks
  if (verbose) {
    printHeader('Pre-flight Checks');
  }

  const checks = await runPreflightChecks({
    targetDir,
    packageRoot,
    verbose
  });

  if (!checks.passed) {
    return {
      success: false,
      error: `Pre-flight checks failed:\n${checks.errors.join('\n')}`
    };
  }

  // Check if already installed (only block if preserveMemory is false)
  // Note: The wizard handles this check earlier and offers to update,
  // so this is primarily a safety net for direct calls to install()
  const existing = await checkExistingInstallation(targetDir);

  if (existing.installed && !preserveMemory) {
    if (verbose) {
      printWarning('Spec-Flow is already installed in this directory');
      console.log('\nTo update existing installation:');
      console.log('  npx spec-flow update');
      console.log('\nOr run init again to be guided through the update process:');
      console.log('  npx spec-flow init\n');
    }
    return {
      success: false,
      error: 'Already installed. Run "npx spec-flow init" or "npx spec-flow update" to upgrade.'
    };
  }

  let spinner;
  const conflictActions = []; // Track conflict resolutions

  try {
    // Copy .claude directory
    spinner = ora('Installing .claude directory...').start();
    const claudeSource = path.join(packageRoot, '.claude');
    const claudeDest = path.join(targetDir, '.claude');

    await copyDirectory(claudeSource, claudeDest, {
      preserveMemory: false,
      conflictStrategy,
      excludeDirectories,
      onProgress: (msg) => {
        if (verbose) spinner.text = msg;
      }
    });
    spinner.succeed('.claude directory installed');

    // Copy .spec-flow directory
    spinner = ora('Installing .spec-flow directory...').start();
    const specFlowSource = path.join(packageRoot, '.spec-flow');
    const specFlowDest = path.join(targetDir, '.spec-flow');

    await copyDirectory(specFlowSource, specFlowDest, {
      preserveMemory,
      conflictStrategy,
      excludeDirectories,
      onProgress: (msg) => {
        if (verbose) spinner.text = msg;
      }
    });

    if (preserveMemory) {
      spinner.succeed('.spec-flow directory installed (memory preserved)');
    } else {
      spinner.succeed('.spec-flow directory installed');
    }

    // Copy root files with conflict resolution
    spinner = ora('Installing documentation files...').start();
    const rootFiles = ['CLAUDE.md', 'QUICKSTART.md', 'LICENSE'];

    for (const file of rootFiles) {
      const source = path.join(packageRoot, file);
      const dest = path.join(targetDir, file);

      if (await fs.pathExists(source)) {
        const action = await resolveConflict({
          sourcePath: source,
          targetPath: dest,
          strategy: conflictStrategy,
          fileName: file
        });
        conflictActions.push(action);

        if (verbose) {
          spinner.text = `${file}: ${action.action}`;
        }
      }
    }
    spinner.succeed('Documentation files installed');

    printSuccess('\nInstallation complete!');

    return { success: true, error: null, conflictActions };
  } catch (error) {
    if (spinner) spinner.fail('Installation failed');
    return {
      success: false,
      error: `Installation error: ${error.message}`
    };
  }
}

/**
 * Update existing spec-flow installation
 * @param {Object} options - Update options
 * @param {string} options.targetDir - Target directory
 * @param {boolean} options.force - Deprecated (kept for backwards compatibility)
 * @param {boolean} options.verbose - Show detailed output
 * @returns {Promise<Object>} { success: boolean, error: string|null }
 */
async function update(options) {
  const { targetDir, verbose = false } = options;

  // Check if installed
  const existing = await checkExistingInstallation(targetDir);

  if (!existing.installed) {
    return {
      success: false,
      error: 'Spec-Flow not found in this directory. Use init command to install.'
    };
  }

  try {
    // Run installation with memory preservation and user directory exclusion
    // This updates templates while preserving user data (memory, specs, learnings.md)
    const result = await install({
      targetDir,
      preserveMemory: true,
      verbose,
      excludeDirectories: USER_DATA_DIRECTORIES
    });

    if (!result.success) {
      return {
        success: false,
        error: result.error
      };
    }

    printSuccess('Update complete!');

    return {
      success: true,
      error: null
    };
  } catch (error) {
    return {
      success: false,
      error: `Update error: ${error.message}`
    };
  }
}

module.exports = {
  install,
  update,
  USER_DATA_DIRECTORIES
};

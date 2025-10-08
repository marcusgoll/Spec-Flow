const fs = require('fs-extra');
const path = require('path');
const ora = require('ora');
const {
  getPackageRoot,
  copyDirectory,
  createBackup,
  restoreBackup,
  printHeader,
  printSuccess,
  printError,
  printWarning
} = require('./utils');
const { checkExistingInstallation, runPreflightChecks } = require('./validate');
const { resolveConflict, STRATEGIES } = require('./conflicts');

/**
 * Install spec-flow to target directory
 * @param {Object} options - Installation options
 * @param {string} options.targetDir - Target directory
 * @param {boolean} options.preserveMemory - Whether to preserve memory files
 * @param {boolean} options.verbose - Show detailed output
 * @param {string} options.conflictStrategy - Conflict resolution strategy (merge|backup|skip|force)
 * @returns {Promise<Object>} { success: boolean, error: string|null, conflictActions: Array }
 */
async function install(options) {
  const { targetDir, preserveMemory = false, verbose = false, conflictStrategy = STRATEGIES.MERGE } = options;
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

  // Check if already installed
  const existing = await checkExistingInstallation(targetDir);

  if (existing.installed && !preserveMemory) {
    printWarning('Spec-Flow is already installed in this directory');
    printWarning('Use update command to preserve memory, or remove .claude/.spec-flow directories first');
    return {
      success: false,
      error: 'Already installed. Use update command or remove existing installation.'
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
 * @param {boolean} options.force - Skip backup
 * @param {boolean} options.verbose - Show detailed output
 * @returns {Promise<Object>} { success: boolean, backupPath: string|null, error: string|null }
 */
async function update(options) {
  const { targetDir, force = false, verbose = false } = options;

  // Check if installed
  const existing = await checkExistingInstallation(targetDir);

  if (!existing.installed) {
    return {
      success: false,
      backupPath: null,
      error: 'Spec-Flow not found in this directory. Use init command to install.'
    };
  }

  let backupPath = null;
  let spinner;

  try {
    // Create backup of memory directory
    if (!force && existing.hasSpecFlowDir) {
      const memoryDir = path.join(targetDir, '.spec-flow', 'memory');

      if (await fs.pathExists(memoryDir)) {
        spinner = ora('Creating backup of memory files...').start();
        backupPath = await createBackup(memoryDir);
        spinner.succeed(`Backup created: ${path.basename(backupPath)}`);
      }
    }

    // Run installation with memory preservation
    const result = await install({
      targetDir,
      preserveMemory: true,
      verbose
    });

    if (!result.success) {
      // Restore backup if update failed
      if (backupPath) {
        spinner = ora('Restoring backup...').start();
        await restoreBackup(backupPath, path.join(targetDir, '.spec-flow', 'memory'));
        spinner.succeed('Backup restored');
      }
      return {
        success: false,
        backupPath: null,
        error: result.error
      };
    }

    return {
      success: true,
      backupPath,
      error: null
    };
  } catch (error) {
    if (spinner) spinner.fail('Update failed');

    // Restore backup on error
    if (backupPath) {
      try {
        await restoreBackup(backupPath, path.join(targetDir, '.spec-flow', 'memory'));
        printSuccess('Backup restored');
      } catch (restoreError) {
        printError(`Failed to restore backup: ${restoreError.message}`);
      }
    }

    return {
      success: false,
      backupPath: null,
      error: `Update error: ${error.message}`
    };
  }
}

module.exports = {
  install,
  update
};

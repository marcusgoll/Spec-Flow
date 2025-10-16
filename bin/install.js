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
 * Directories containing valuable user data that should be backed up during updates
 * Only includes directories that spec-flow manages and users customize
 */
const BACKUP_DIRECTORIES = [
  'specs'            // Feature specifications and user's work
  // Note: .spec-flow/memory is backed up separately
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
 * @param {boolean} options.force - Skip backup
 * @param {boolean} options.verbose - Show detailed output
 * @returns {Promise<Object>} { success: boolean, backupPaths: Object, error: string|null }
 */
async function update(options) {
  const { targetDir, force = false, verbose = false } = options;

  // Check if installed
  const existing = await checkExistingInstallation(targetDir);

  if (!existing.installed) {
    return {
      success: false,
      backupPaths: {},
      error: 'Spec-Flow not found in this directory. Use init command to install.'
    };
  }

  const backupPaths = {};
  let spinner;

  try {
    // Create backup of valuable user content (memory and specs only)
    if (!force) {
      spinner = ora('Creating backup of user data...').start();

      // Backup memory directory (roadmap, constitution, design inspirations)
      if (existing.hasSpecFlowDir) {
        const memoryDir = path.join(targetDir, '.spec-flow', 'memory');
        if (await fs.pathExists(memoryDir)) {
          backupPaths.memory = await createBackup(memoryDir);
          if (verbose) spinner.text = `Backed up memory: ${path.basename(backupPaths.memory)}`;
        }
      }

      // Backup ONLY valuable user-generated directories (not node_modules, build artifacts, etc.)
      // CRITICAL: Only backup spec-flow managed content to prevent EPERM errors on Windows
      for (const userDir of BACKUP_DIRECTORIES) {
        const dirPath = path.join(targetDir, userDir);
        if (await fs.pathExists(dirPath)) {
          backupPaths[userDir] = await createBackup(dirPath);
          if (verbose) spinner.text = `Backed up ${userDir}: ${path.basename(backupPaths[userDir])}`;
        }
      }

      const backupCount = Object.keys(backupPaths).length;
      if (backupCount > 0) {
        spinner.succeed(`Created ${backupCount} backup(s) of user data`);
      } else {
        spinner.info('No user data to backup');
      }
    }

    // Run installation with memory preservation and user directory exclusion
    const result = await install({
      targetDir,
      preserveMemory: true,
      verbose,
      excludeDirectories: USER_DATA_DIRECTORIES
    });

    if (!result.success) {
      // Restore backups if update failed
      if (Object.keys(backupPaths).length > 0) {
        spinner = ora('Restoring backups...').start();

        // Restore memory
        if (backupPaths.memory) {
          await restoreBackup(backupPaths.memory, path.join(targetDir, '.spec-flow', 'memory'));
        }

        // Restore user directories (only those we backed up)
        for (const userDir of BACKUP_DIRECTORIES) {
          if (backupPaths[userDir]) {
            await restoreBackup(backupPaths[userDir], path.join(targetDir, userDir));
          }
        }

        spinner.succeed('All backups restored');
      }

      return {
        success: false,
        backupPaths: {},
        error: result.error
      };
    }

    // Clean up backups after successful update
    if (Object.keys(backupPaths).length > 0 && verbose) {
      printSuccess('Update complete! Backups preserved in case of issues.');
    }

    return {
      success: true,
      backupPaths,
      error: null
    };
  } catch (error) {
    if (spinner) spinner.fail('Update failed');

    // Restore backups on error
    if (Object.keys(backupPaths).length > 0) {
      try {
        spinner = ora('Restoring backups...').start();

        // Restore memory
        if (backupPaths.memory) {
          await restoreBackup(backupPaths.memory, path.join(targetDir, '.spec-flow', 'memory'));
        }

        // Restore user directories (only those we backed up)
        for (const userDir of BACKUP_DIRECTORIES) {
          if (backupPaths[userDir]) {
            await restoreBackup(backupPaths[userDir], path.join(targetDir, userDir));
          }
        }

        spinner.succeed('All backups restored');
      } catch (restoreError) {
        printError(`Failed to restore backups: ${restoreError.message}`);
        printWarning('Your data may be in backup directories. Check for *-backup-* folders.');
      }
    }

    return {
      success: false,
      backupPaths: {},
      error: `Update error: ${error.message}`
    };
  }
}

module.exports = {
  install,
  update,
  USER_DATA_DIRECTORIES,
  BACKUP_DIRECTORIES
};

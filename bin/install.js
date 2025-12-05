// install.js (refactored)
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
 * User-owned directories that must NEVER be touched during install/update.
 * These are excluded from all copy/install operations.
 */
const USER_DATA_DIRECTORIES = [
  'specs',        // feature specs
  'node_modules', // deps
  '.git',         // repo
  'dist', 'build', 'coverage',
  '.next', '.nuxt', 'out'
];

/** Root-level docs we ship */
const ROOT_DOC_FILES = ['CLAUDE.md', 'QUICKSTART.md', 'LICENSE'];

/** Merge and normalize an exclude list */
function buildExcludeList(extra = []) {
  const set = new Set([...USER_DATA_DIRECTORIES, ...(extra || [])]);
  return Array.from(set);
}

/** Guard + normalize options */
function normalizeOptions(opts = {}) {
  const {
    targetDir,
    preserveMemory = false,
    verbose = false,
    conflictStrategy = STRATEGIES.MERGE,
    excludeDirectories = []
  } = opts;

  if (!targetDir || typeof targetDir !== 'string') {
    throw new Error('options.targetDir is required');
  }

  const resolvedTarget = path.resolve(targetDir); // official behavior: resolves to absolute path.

  return {
    targetDir: resolvedTarget,
    preserveMemory,
    verbose,
    conflictStrategy,
    excludeDirectories: buildExcludeList(excludeDirectories)
  };
}

/** Spinner helper with guaranteed cleanup */
async function withSpinner(label, fn, { enabled = true } = {}) {
  const spinner = enabled ? ora(label).start() : null;
  try {
    const result = await fn((text) => spinner && (spinner.text = text));
    spinner && spinner.succeed(label);
    return result;
  } catch (err) {
    spinner && spinner.fail(label);
    throw err;
  }
}

/** Install a directory from packageRoot into targetDir */
async function installDir({ source, dest, label, preserveMemory, conflictStrategy, excludeDirectories, verbose }) {
  return withSpinner(label, async (setText) => {
    await copyDirectory(source, dest, {
      preserveMemory,
      conflictStrategy,
      excludeDirectories,
      onProgress: (msg) => {
        if (verbose && msg) setText(`${label} · ${msg}`);
      }
    });
  }, { enabled: process.env.CI !== 'true' }); // keep logs cleaner in CI
}

/** Copy doc files with conflict resolution; collect actions */
async function installDocs({ packageRoot, targetDir, conflictStrategy, verbose }) {
  const actions = [];
  await withSpinner('Installing documentation files...', async (setText) => {
    for (const file of ROOT_DOC_FILES) {
      const source = path.join(packageRoot, file);
      const dest = path.join(targetDir, file);
      if (await fs.pathExists(source)) { // fs-extra pathExists is a boolean promise. :contentReference[oaicite:1]{index=1}
        const action = await resolveConflict({
          sourcePath: source,
          targetPath: dest,
          strategy: conflictStrategy,
          fileName: file
        });
        actions.push(action);
        if (verbose) setText(`${file}: ${action.action}`);
      }
    }
  }, { enabled: process.env.CI !== 'true' });
  return actions;
}

/** Copy GitHub workflows with conflict resolution; collect actions */
async function installWorkflows({ packageRoot, targetDir, conflictStrategy, verbose }) {
  const actions = [];
  const sourceWorkflowsDir = path.join(packageRoot, '.github', 'workflows');
  const targetWorkflowsDir = path.join(targetDir, '.github', 'workflows');

  // Check if source workflows exist
  if (!await fs.pathExists(sourceWorkflowsDir)) {
    return actions; // No workflows to install
  }

  await withSpinner('Installing GitHub workflows...', async (setText) => {
    // Ensure target directory exists
    await fs.ensureDir(targetWorkflowsDir);

    // Get all workflow files
    const files = await fs.readdir(sourceWorkflowsDir);
    const workflowFiles = files.filter(f => f.endsWith('.yml') || f.endsWith('.yaml'));

    for (const file of workflowFiles) {
      const source = path.join(sourceWorkflowsDir, file);
      const dest = path.join(targetWorkflowsDir, file);

      const action = await resolveConflict({
        sourcePath: source,
        targetPath: dest,
        strategy: conflictStrategy,
        fileName: file
      });
      actions.push(action);
      if (verbose) setText(`.github/workflows/${file}: ${action.action}`);
    }
  }, { enabled: process.env.CI !== 'true' });

  return actions;
}

/**
 * Install spec-flow to target directory
 * @param {Object} options
 * @param {string} options.targetDir
 * @param {boolean} [options.preserveMemory=false]
 * @param {boolean} [options.verbose=false]
 * @param {string} [options.conflictStrategy='merge'] STRATEGIES.{MERGE|BACKUP|SKIP|FORCE}
 * @param {Array<string>} [options.excludeDirectories=[]]
 * @returns {Promise<{ success: boolean, error: string|null, conflictActions: Array }>}
 */
async function install(options) {
  let settings;
  try {
    settings = normalizeOptions(options);
  } catch (e) {
    return { success: false, error: e.message, conflictActions: [] };
  }

  const {
    targetDir,
    preserveMemory,
    verbose,
    conflictStrategy,
    excludeDirectories
  } = settings;

  const packageRoot = getPackageRoot();

  if (verbose) printHeader('Pre-flight Checks');

  const checks = await runPreflightChecks({ targetDir, packageRoot, verbose });
  if (!checks.passed) {
    return {
      success: false,
      error: `Pre-flight checks failed:\n${checks.errors.join('\n')}`,
      conflictActions: []
    };
  }

  // Safety net: block blind overwrite unless explicitly preserving memory or caller opted into update flow
  const existing = await checkExistingInstallation(targetDir);
  if (existing.installed && !preserveMemory) {
    if (verbose) {
      printWarning('Spec-Flow already installed in this directory');
      console.log('\nTo update existing installation:');
      console.log('  npx spec-flow update');
      console.log('\nOr re-run init to be guided through an update:');
      console.log('  npx spec-flow init\n');
    }
    return {
      success: false,
      error: 'Already installed. Run "npx spec-flow init" or "npx spec-flow update" to upgrade.',
      conflictActions: []
    };
  }

  const conflictActions = [];
  try {
    // 1) .claude (memory=false to ensure templates refresh)
    await installDir({
      source: path.join(packageRoot, '.claude'),
      dest: path.join(targetDir, '.claude'),
      label: 'Installing .claude directory...',
      preserveMemory: false,
      conflictStrategy,
      excludeDirectories,
      verbose
    });

    // 2) .spec-flow (respect preserveMemory)
    await installDir({
      source: path.join(packageRoot, '.spec-flow'),
      dest: path.join(targetDir, '.spec-flow'),
      label: preserveMemory
        ? 'Installing .spec-flow directory (memory preserved)...'
        : 'Installing .spec-flow directory...',
      preserveMemory,
      conflictStrategy,
      excludeDirectories,
      verbose
    });

    // 3) root docs
    const docActions = await installDocs({ packageRoot, targetDir, conflictStrategy, verbose });
    conflictActions.push(...docActions);

    // 4) GitHub workflows
    const workflowActions = await installWorkflows({ packageRoot, targetDir, conflictStrategy, verbose });
    conflictActions.push(...workflowActions);

    printSuccess('\nInstallation complete!');
    return { success: true, error: null, conflictActions };
  } catch (error) {
    printError('Installation failed');
    return { success: false, error: `Installation error: ${error.message}`, conflictActions };
  }
}

/**
 * Update existing spec-flow installation
 * Preserves memory and excludes user data directories by default.
 * @param {Object} options
 * @param {string} options.targetDir
 * @param {boolean} [options.verbose=false]
 * @param {boolean|null} [options.updateHooks=null] - null=prompt, true=force, false=skip
 * @param {boolean} [options.nonInteractive=false] - Non-interactive mode (auto-update hooks)
 * @returns {Promise<{ success: boolean, error: string|null, hooksStatus?: string, hooksMessage?: string }>}
 */
async function update(options) {
  let { targetDir, verbose = false, updateHooks = null, nonInteractive = false } = options || {};
  if (!targetDir) {
    return { success: false, error: 'options.targetDir is required' };
  }
  targetDir = path.resolve(targetDir);

  const existing = await checkExistingInstallation(targetDir);
  if (!existing.installed) {
    return {
      success: false,
      error: 'Spec-Flow not found in this directory. Use init command to install.'
    };
  }

  try {
    const result = await install({
      targetDir,
      preserveMemory: true,
      verbose,
      excludeDirectories: USER_DATA_DIRECTORIES
    });

    if (!result.success) {
      return { success: false, error: result.error || 'Unknown update error' };
    }

    // Handle hook updates
    const { updateHooksIfInstalled } = require('./install-hooks');

    // Check if hooks exist
    const hooksExist = await fs.pathExists(
      path.join(targetDir, '.claude', 'hooks', 'design-token-validator.sh')
    );

    let hooksStatus = 'not_checked';
    let hooksMessage = '';

    if (hooksExist) {
      // Determine action: prompt, force, or skip
      if (updateHooks === false) {
        // Explicit skip
        hooksStatus = 'skipped';
      } else if (updateHooks === true || nonInteractive) {
        // Force update or non-interactive mode
        if (verbose) console.log('\nUpdating design token hooks...');
        const hookResult = await updateHooksIfInstalled(targetDir, {
          silent: false
        });
        hooksStatus = hookResult.updated ? 'updated' : 'failed';
        if (!hookResult.updated && hookResult.error) {
          hooksMessage = hookResult.error;
        }
      } else {
        // Interactive prompt (default)
        let inquirer;
        try {
          const m = await import('inquirer');
          inquirer = m.default || m;
        } catch {
          try {
            inquirer = require('inquirer');
          } catch {
            // If inquirer not available, skip prompt
            hooksStatus = 'skipped';
            return {
              success: true,
              error: null,
              conflictActions: result.conflictActions || [],
              backupPaths: {},
              hooksStatus,
              hooksMessage
            };
          }
        }

        console.log('');
        const { shouldUpdate } = await inquirer.prompt([{
          type: 'confirm',
          name: 'shouldUpdate',
          message: 'Update design token hooks to latest version?',
          default: true
        }]);

        if (shouldUpdate) {
          console.log('');
          const hookResult = await updateHooksIfInstalled(targetDir, {
            silent: false
          });
          hooksStatus = hookResult.updated ? 'updated' : 'failed';
          if (!hookResult.updated && hookResult.error) {
            hooksMessage = hookResult.error;
          }
        } else {
          hooksStatus = 'skipped_by_user';
        }
      }
    } else {
      hooksStatus = 'not_installed';
      hooksMessage = 'Design token hooks not detected. Run `npx spec-flow install-hooks` to enable.';
    }

    // Return success with conflictActions for cli.js to display
    return {
      success: true,
      error: null,
      conflictActions: result.conflictActions || [],
      backupPaths: {}, // No backups created during update (templates only)
      hooksStatus,
      hooksMessage
    };
  } catch (error) {
    return { success: false, error: `Update error: ${error.message}` };
  }
}

module.exports = {
  install,
  update,
  USER_DATA_DIRECTORIES
};

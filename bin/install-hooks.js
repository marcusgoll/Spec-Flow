#!/usr/bin/env node

/**
 * Design Token Enforcement Hooks Installer
 * Installs hooks to .claude/hooks/ and updates settings.json
 */

const path = require('path');
const fs = require('fs');

/**
 * Check if design token hooks are already installed
 * @param {string} targetDir - Target directory to check
 * @returns {boolean}
 */
function checkHooksInstalled(targetDir) {
  const hooksDir = path.join(targetDir, '.claude', 'hooks');
  const validatorPath = path.join(hooksDir, 'design-token-validator.sh');
  return fs.existsSync(validatorPath);
}

/**
 * Get the source directory for hooks (from npm package)
 * @returns {string}
 */
function getSourceHooksDir() {
  // When installed as npm package, hooks are in dist/.claude/hooks/
  const distPath = path.join(__dirname, '..', 'dist', '.claude', 'hooks');
  if (fs.existsSync(distPath)) {
    return distPath;
  }
  // Fallback to local development path
  return path.join(__dirname, '..', '.claude', 'hooks');
}

/**
 * Install design token hooks to target directory
 * @param {string} targetDir - Target directory
 * @param {object} options - Installation options
 * @param {boolean} options.force - Overwrite existing hooks
 * @param {boolean} options.silent - Suppress output
 * @returns {Promise<{success: boolean, installed: string[], skipped: string[], error?: string}>}
 */
async function installHooks(targetDir, options = {}) {
  const { force = false, silent = false } = options;
  const log = silent ? () => {} : console.log;

  const result = {
    success: true,
    installed: [],
    skipped: []
  };

  try {
    const sourceDir = getSourceHooksDir();
    const targetHooksDir = path.join(targetDir, '.claude', 'hooks');

    // Check if source hooks exist
    if (!fs.existsSync(sourceDir)) {
      result.success = false;
      result.error = 'Source hooks not found. Package may be corrupted.';
      return result;
    }

    // Create target hooks directory
    if (!fs.existsSync(targetHooksDir)) {
      fs.mkdirSync(targetHooksDir, { recursive: true });
      log('  Created .claude/hooks/ directory');
    }

    // List of hooks to install
    const hookFiles = [
      'design-token-validator.sh',
      'design-token-validator.ps1',
      'design-system-context.sh',
      'design-system-context.ps1'
    ];

    // Copy hook files
    for (const file of hookFiles) {
      const sourcePath = path.join(sourceDir, file);
      const targetPath = path.join(targetHooksDir, file);

      if (!fs.existsSync(sourcePath)) {
        // Source file doesn't exist, skip
        continue;
      }

      if (fs.existsSync(targetPath) && !force) {
        result.skipped.push(file);
        log(`  Skipped ${file} (already exists)`);
      } else {
        fs.copyFileSync(sourcePath, targetPath);
        result.installed.push(file);
        log(`  Installed ${file}`);

        // Make shell scripts executable on Unix
        if (file.endsWith('.sh') && process.platform !== 'win32') {
          try {
            fs.chmodSync(targetPath, 0o755);
          } catch (e) {
            // Ignore chmod errors on Windows or restricted environments
          }
        }
      }
    }

    // Update settings.json with hook configuration
    await updateSettings(targetDir, { silent });

    return result;
  } catch (error) {
    result.success = false;
    result.error = error.message;
    return result;
  }
}

/**
 * Update .claude/settings.json with hook configuration
 * @param {string} targetDir - Target directory
 * @param {object} options - Options
 */
async function updateSettings(targetDir, options = {}) {
  const { silent = false } = options;
  const log = silent ? () => {} : console.log;

  const settingsPath = path.join(targetDir, '.claude', 'settings.json');
  let settings = {};

  // Load existing settings if present
  if (fs.existsSync(settingsPath)) {
    try {
      const content = fs.readFileSync(settingsPath, 'utf8');
      settings = JSON.parse(content);
    } catch (e) {
      // If settings.json is invalid, start fresh
      settings = {};
    }
  }

  // Initialize hooks structure if not present
  if (!settings.hooks) {
    settings.hooks = {};
  }

  // Determine hook command based on platform
  const isWindows = process.platform === 'win32';
  const validatorCmd = isWindows
    ? 'powershell -ExecutionPolicy Bypass -File .claude/hooks/design-token-validator.ps1'
    : '.claude/hooks/design-token-validator.sh';
  const contextCmd = isWindows
    ? 'powershell -ExecutionPolicy Bypass -File .claude/hooks/design-system-context.ps1'
    : '.claude/hooks/design-system-context.sh';

  // Add SessionStart hook
  const sessionStartHook = {
    hooks: [{
      type: 'command',
      command: contextCmd,
      timeout: 5000
    }]
  };

  // Add PreToolUse hook
  const preToolUseHook = {
    matcher: 'Write|Edit',
    hooks: [{
      type: 'command',
      command: validatorCmd,
      timeout: 10000
    }]
  };

  // Check if hooks already exist
  let sessionStartExists = false;
  let preToolUseExists = false;

  if (settings.hooks.SessionStart) {
    sessionStartExists = settings.hooks.SessionStart.some(h =>
      h.hooks && h.hooks.some(hh =>
        hh.command && hh.command.includes('design-system-context')
      )
    );
  }

  if (settings.hooks.PreToolUse) {
    preToolUseExists = settings.hooks.PreToolUse.some(h =>
      h.hooks && h.hooks.some(hh =>
        hh.command && hh.command.includes('design-token-validator')
      )
    );
  }

  // Add hooks if they don't exist
  let updated = false;

  if (!sessionStartExists) {
    if (!settings.hooks.SessionStart) {
      settings.hooks.SessionStart = [];
    }
    settings.hooks.SessionStart.push(sessionStartHook);
    updated = true;
  }

  if (!preToolUseExists) {
    if (!settings.hooks.PreToolUse) {
      settings.hooks.PreToolUse = [];
    }
    settings.hooks.PreToolUse.push(preToolUseHook);
    updated = true;
  }

  // Write settings if updated
  if (updated) {
    // Ensure .claude directory exists
    const claudeDir = path.join(targetDir, '.claude');
    if (!fs.existsSync(claudeDir)) {
      fs.mkdirSync(claudeDir, { recursive: true });
    }

    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
    log('  Updated .claude/settings.json with hook configuration');
  } else {
    log('  Hooks already configured in settings.json');
  }
}

/**
 * Uninstall design token hooks
 * @param {string} targetDir - Target directory
 * @param {object} options - Options
 * @returns {Promise<{success: boolean, removed: string[], error?: string}>}
 */
async function uninstallHooks(targetDir, options = {}) {
  const { silent = false } = options;
  const log = silent ? () => {} : console.log;

  const result = {
    success: true,
    removed: []
  };

  try {
    const hooksDir = path.join(targetDir, '.claude', 'hooks');

    // Hook files to remove
    const hookFiles = [
      'design-token-validator.sh',
      'design-token-validator.ps1',
      'design-system-context.sh',
      'design-system-context.ps1'
    ];

    // Remove hook files
    for (const file of hookFiles) {
      const filePath = path.join(hooksDir, file);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        result.removed.push(file);
        log(`  Removed ${file}`);
      }
    }

    // Clean up settings.json
    await cleanSettings(targetDir, { silent });

    return result;
  } catch (error) {
    result.success = false;
    result.error = error.message;
    return result;
  }
}

/**
 * Remove hook configuration from settings.json
 * @param {string} targetDir - Target directory
 * @param {object} options - Options
 */
async function cleanSettings(targetDir, options = {}) {
  const { silent = false } = options;
  const log = silent ? () => {} : console.log;

  const settingsPath = path.join(targetDir, '.claude', 'settings.json');

  if (!fs.existsSync(settingsPath)) {
    return;
  }

  try {
    const content = fs.readFileSync(settingsPath, 'utf8');
    const settings = JSON.parse(content);

    let updated = false;

    // Remove SessionStart hooks
    if (settings.hooks && settings.hooks.SessionStart) {
      const before = settings.hooks.SessionStart.length;
      settings.hooks.SessionStart = settings.hooks.SessionStart.filter(h =>
        !(h.hooks && h.hooks.some(hh =>
          hh.command && hh.command.includes('design-system-context')
        ))
      );
      if (settings.hooks.SessionStart.length !== before) {
        updated = true;
      }
      if (settings.hooks.SessionStart.length === 0) {
        delete settings.hooks.SessionStart;
      }
    }

    // Remove PreToolUse hooks
    if (settings.hooks && settings.hooks.PreToolUse) {
      const before = settings.hooks.PreToolUse.length;
      settings.hooks.PreToolUse = settings.hooks.PreToolUse.filter(h =>
        !(h.hooks && h.hooks.some(hh =>
          hh.command && hh.command.includes('design-token-validator')
        ))
      );
      if (settings.hooks.PreToolUse.length !== before) {
        updated = true;
      }
      if (settings.hooks.PreToolUse.length === 0) {
        delete settings.hooks.PreToolUse;
      }
    }

    // Remove empty hooks object
    if (settings.hooks && Object.keys(settings.hooks).length === 0) {
      delete settings.hooks;
    }

    if (updated) {
      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
      log('  Cleaned settings.json');
    }
  } catch (e) {
    // Ignore errors cleaning settings
  }
}

/**
 * Update hooks if already installed (for use during update)
 * Overwrites existing hooks without backup
 * @param {string} targetDir - Target directory
 * @param {object} options - Options
 * @param {boolean} options.force - Force update even if installed
 * @param {boolean} options.silent - Suppress output
 * @returns {Promise<{updated: boolean, reason?: string, installed?: string[], error?: string}>}
 */
async function updateHooksIfInstalled(targetDir, options = {}) {
  const { force = false, silent = false } = options;
  const log = silent ? () => {} : console.log;

  // Check if hooks already installed
  const hooksDir = path.join(targetDir, '.claude', 'hooks');
  if (!fs.existsSync(hooksDir)) {
    return { updated: false, reason: 'not_installed' };
  }

  // Install updated hooks (no backup - just overwrite)
  const result = await installHooks(targetDir, { silent, force: true });

  if (result.success) {
    return {
      updated: true,
      installed: result.installed
    };
  } else {
    return {
      updated: false,
      error: result.error
    };
  }
}

/**
 * Prompt user to install hooks (for use during init/update)
 * @param {string} targetDir - Target directory
 * @param {object} chalk - Chalk instance for colors
 * @returns {Promise<boolean>} - Whether hooks were installed
 */
async function promptInstallHooks(targetDir, chalk) {
  // Skip in CI or non-interactive mode
  if (process.env.CI || process.env.SPEC_FLOW_SILENT || !process.stdin.isTTY) {
    return false;
  }

  // Check if already installed
  if (checkHooksInstalled(targetDir)) {
    console.log(chalk.gray('  Design token hooks already installed'));
    return true;
  }

  console.log('');
  console.log(chalk.yellow('Design Token Enforcement Hooks'));
  console.log(chalk.gray('These hooks prevent AI from hardcoding colors and spacing values.'));
  console.log(chalk.gray('They block edits that use #hex, rgb(), or arbitrary Tailwind values.'));
  console.log('');

  // Try to load inquirer for interactive prompt
  let inquirer;
  try {
    const m = await import('inquirer');
    inquirer = m.default || m;
  } catch {
    try {
      inquirer = require('inquirer');
    } catch {
      console.log(chalk.gray('Install manually later: npx spec-flow install-hooks'));
      return false;
    }
  }

  const { install } = await inquirer.prompt([{
    type: 'confirm',
    name: 'install',
    message: 'Install design token enforcement hooks?',
    default: true
  }]);

  if (install) {
    console.log('');
    console.log(chalk.cyan('Installing hooks...'));

    const result = await installHooks(targetDir, { silent: false });

    if (result.success) {
      console.log('');
      console.log(chalk.green('Hooks installed! AI will now be blocked from hardcoding design values.'));
      return true;
    } else {
      console.log(chalk.red(`Hook installation failed: ${result.error}`));
      return false;
    }
  } else {
    console.log(chalk.gray('Skipped. Install later with: npx spec-flow install-hooks'));
    return false;
  }
}

module.exports = {
  checkHooksInstalled,
  installHooks,
  uninstallHooks,
  updateHooksIfInstalled,
  promptInstallHooks,
  updateSettings,
  cleanSettings
};

#!/usr/bin/env node

const { program } = require('commander');
const path = require('path');
const chalk = require('chalk');
const { runWizard } = require('./install-wizard');
const { update } = require('./install');
const { healthCheck, checkLatestVersion, CURRENT_VERSION } = require('./validate');
const { setupRoadmap } = require('./setup-roadmap');
const { printHeader, printSuccess, printError, printWarning } = require('./utils');
const { installCodexPrompts } = require('./install-codex-prompts');
const { STRATEGIES } = require('./conflicts');
const { installHooks, uninstallHooks, checkHooksInstalled } = require('./install-hooks');

const VERSION = require('../package.json').version;

program
  .name('spec-flow')
  .description('Spec-Driven Development workflow toolkit for Claude Code')
  .version(VERSION, '-v, --version', 'output the version number');

// Init command - run installation wizard
program
  .command('init')
  .description('Initialize Spec-Flow in current directory')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .option('--non-interactive', 'Skip interactive prompts, use defaults')
  .option('-s, --strategy <mode>', 'Conflict resolution strategy: merge|backup|skip|force (default: merge)')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    // Validate strategy if provided
    if (options.strategy) {
      const validStrategies = Object.values(STRATEGIES);
      if (!validStrategies.includes(options.strategy)) {
        printError(`Invalid strategy: ${options.strategy}`);
        console.log(chalk.white('Valid strategies:'));
        console.log(chalk.gray(`  ${validStrategies.join(', ')}\n`));
        process.exit(1);
      }
    }

    try {
      const result = await runWizard({
        targetDir,
        nonInteractive: options.nonInteractive,
        conflictStrategy: options.strategy
      });

      if (!result.success) {
        printError(result.error);
        process.exit(1);
      }
    } catch (error) {
      printError(`Installation failed: ${error.message}`);
      if (error.stack && process.env.DEBUG) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  });

// Update command - update existing installation (or install if not present)
program
  .command('update')
  .description('Update Spec-Flow (or install if not present)')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .option('--update-hooks', 'Force update hooks without prompting')
  .option('--skip-hooks', 'Skip hook updates')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    try {
      const result = await update({
        targetDir,
        verbose: true,
        updateHooks: options.updateHooks ? true : options.skipHooks ? false : null,
        nonInteractive: !process.stdin.isTTY
      });

      if (!result.success) {
        printError(result.error);
        process.exit(1);
      }

      // Show appropriate message based on whether it was fresh install or update
      if (result.wasInstall) {
        printSuccess('\nInstallation complete!');
        console.log(chalk.cyan(`\nSpec-Flow version: ${chalk.bold(VERSION)}`));
        console.log('');
        console.log(chalk.white('Next steps:'));
        console.log(chalk.green('  1. Open project in Claude Code'));
        console.log(chalk.green('  2. Run /help') + chalk.gray(' for guidance'));
        console.log(chalk.green('  3. Run /feature "name"') + chalk.gray(' to start building\n'));
      } else {
        printSuccess('\nUpdate complete!');
        console.log(chalk.cyan(`\nSpec-Flow version: ${chalk.bold(VERSION)}`));
        console.log(chalk.gray('Templates updated, user data preserved (memory, specs, learnings.md)'));

        // Show hook status
        if (result.hooksStatus) {
          console.log('');
          if (result.hooksStatus === 'updated') {
            console.log(chalk.green('✓ Design token hooks updated to latest version'));
          } else if (result.hooksStatus === 'not_installed') {
            console.log(chalk.yellow(`⚠️  ${result.hooksMessage}`));
          } else if (result.hooksStatus === 'skipped_by_user') {
            console.log(chalk.gray('  Hooks update skipped by user'));
          } else if (result.hooksStatus === 'skipped') {
            console.log(chalk.gray('  Hooks update skipped'));
          } else if (result.hooksStatus === 'failed') {
            console.log(chalk.red(`✗ Hooks update failed: ${result.hooksMessage || 'Unknown error'}`));
          }
        }
      }

      // Show conflict resolutions if any
      const { formatActions } = require('./conflicts');
      if (result.conflictActions && result.conflictActions.length > 0) {
        console.log('');
        console.log(chalk.white('Files updated:'));
        console.log(formatActions(result.conflictActions));

        // Check for Gemini extension updates
        const geminiUpdated = result.conflictActions.some(action =>
          (action.path.endsWith('GEMINI.md') || action.path.endsWith('gemini-extension.json')) &&
          action.action === 'backed-up'
        );

        if (geminiUpdated) {
          console.log('');
          console.log(chalk.yellow('⚠️  Gemini Extension Updated'));
          console.log(chalk.white('   The Gemini CLI extension definition files have been updated.'));
          console.log(chalk.white('   Please restart your Gemini CLI session to load the changes.'));
        }
      }

      console.log('');
    } catch (error) {
      printError(`Update failed: ${error.message}`);
      if (error.stack && process.env.DEBUG) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  });

// Status command - check installation health
program
  .command('status')
  .description('Check Spec-Flow installation status and version')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .option('--check', 'Exit with code 1 if update available (for CI/CD)')
  .option('--skip-version-check', 'Skip checking npm registry for latest version')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    printHeader('Spec-Flow Status');

    try {
      // Version info
      console.log(chalk.cyan(`  Installed: ${chalk.bold('v' + CURRENT_VERSION)}`));

      // Check for updates (unless skipped)
      let versionInfo = null;
      if (!options.skipVersionCheck) {
        versionInfo = await checkLatestVersion();

        if (versionInfo.error) {
          console.log(chalk.gray(`  Latest:    ${chalk.italic('(unable to check: ' + versionInfo.error + ')')}`));
        } else if (versionInfo.updateAvailable) {
          console.log(chalk.yellow(`  Latest:    ${chalk.bold('v' + versionInfo.latest)} `) + chalk.yellow.bold('← update available'));
        } else {
          console.log(chalk.green(`  Latest:    v${versionInfo.latest} `) + chalk.green('(up to date)'));
        }
      }

      console.log('');

      // Health check
      const health = await healthCheck(targetDir);

      if (health.healthy) {
        printSuccess('Installation is healthy');
      } else {
        printWarning('Installation has issues');
      }

      if (health.issues.length > 0) {
        console.log(chalk.red('\nIssues:'));
        health.issues.forEach(issue => console.log(chalk.red(`  ✗ ${issue}`)));
      }

      if (health.warnings.length > 0) {
        console.log(chalk.yellow('\nWarnings:'));
        health.warnings.forEach(warning => console.log(chalk.yellow(`  ⚠ ${warning}`)));
      }

      console.log('');

      // Show update command if update available
      if (versionInfo && versionInfo.updateAvailable) {
        console.log(chalk.white('To update:'));
        console.log(chalk.green('  npx spec-flow update\n'));
      }

      // Exit codes
      if (!health.healthy) {
        console.log(chalk.white('To fix installation issues:'));
        console.log(chalk.green('  npx spec-flow update') + chalk.gray('  # Re-install missing files\n'));
        process.exit(1);
      }

      // --check flag: exit 1 if update available (for CI/CD)
      if (options.check && versionInfo && versionInfo.updateAvailable) {
        process.exit(1);
      }
    } catch (error) {
      printError(`Status check failed: ${error.message}`);
      process.exit(1);
    }
  });

// Setup Roadmap command - configure GitHub Issues roadmap
program
  .command('setup-roadmap')
  .description('Set up GitHub Issues for roadmap management')
  .action(async () => {
    try {
      await setupRoadmap();
    } catch (error) {
      printError(`Roadmap setup failed: ${error.message}`);
      if (error.stack && process.env.DEBUG) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  });

// Install Codex prompts command
program
  .command('install-codex-prompts')
  .description('Copy .codex/commands/*.md into your Codex prompts directory')
  .option('-f, --force', 'Overwrite existing prompts without confirmation')
  .option('--dry-run', 'Show what would change without copying files')
  .action(async (options) => {
    try {
      await installCodexPrompts({
        force: Boolean(options.force),
        dryRun: Boolean(options.dryRun),
      });
    } catch (error) {
      printError(`Prompt installation failed: ${error.message}`);
      if (error.stack && process.env.DEBUG) {
        console.error(error.stack);
      }
      process.exit(1);
    }
  });

// Install design token hooks command
program
  .command('install-hooks')
  .description('Install design token enforcement hooks')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .option('-f, --force', 'Overwrite existing hooks')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    printHeader('Installing Design Token Hooks');

    if (checkHooksInstalled(targetDir) && !options.force) {
      console.log(chalk.yellow('\nHooks already installed.'));
      console.log(chalk.gray('Use --force to reinstall.\n'));
      return;
    }

    console.log(chalk.gray('\nThese hooks prevent AI from hardcoding colors and spacing values.'));
    console.log(chalk.gray('They block edits that use #hex, rgb(), or arbitrary Tailwind values.\n'));

    try {
      const result = await installHooks(targetDir, { force: options.force });

      if (result.success) {
        if (result.installed.length > 0) {
          printSuccess('\nHooks installed successfully!');
          console.log(chalk.gray(`  ${result.installed.length} hook(s) installed`));
          if (result.skipped.length > 0) {
            console.log(chalk.gray(`  ${result.skipped.length} hook(s) skipped (already exist)`));
          }
        }
        console.log(chalk.green('\nAI will now be blocked from hardcoding design values.\n'));
      } else {
        printError(`Installation failed: ${result.error}`);
        process.exit(1);
      }
    } catch (error) {
      printError(`Installation failed: ${error.message}`);
      process.exit(1);
    }
  });

// Uninstall design token hooks command
program
  .command('uninstall-hooks')
  .description('Remove design token enforcement hooks')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    printHeader('Removing Design Token Hooks');

    if (!checkHooksInstalled(targetDir)) {
      console.log(chalk.yellow('\nHooks not installed.\n'));
      return;
    }

    try {
      const result = await uninstallHooks(targetDir);

      if (result.success) {
        printSuccess('\nHooks removed successfully!');
        console.log(chalk.gray(`  ${result.removed.length} hook(s) removed\n`));
      } else {
        printError(`Removal failed: ${result.error}`);
        process.exit(1);
      }
    } catch (error) {
      printError(`Removal failed: ${error.message}`);
      process.exit(1);
    }
  });

// Install Gemini extension command
program
  .command('install-gemini-extension')
  .description('Install Spec-Flow as a Gemini CLI extension in the current project')
  .action(() => {
    const { execSync } = require('child_process');
    printHeader('Installing Gemini CLI Extension');
    try {
      console.log(chalk.gray('Running: gemini extensions install .'));
      execSync('gemini extensions install .', { stdio: 'inherit' });
      printSuccess('Extension installed successfully!');
    } catch (error) {
      printError(`Failed to install extension: ${error.message}`);
      console.log(chalk.yellow('Make sure Gemini CLI is installed and available in your PATH.'));
    }
  });

// Help command
program
  .command('help')
  .description('Show help information')
  .action(() => {
    console.log(chalk.cyan.bold('\nSpec-Flow - Spec-Driven Development Toolkit\n'));
    console.log(chalk.white('Usage:'));
    console.log(chalk.gray('  npx spec-flow <command> [options]\n'));

    console.log(chalk.white('Commands:'));
    console.log(chalk.green('  init') + chalk.gray('                   Initialize or update Spec-Flow (interactive)'));
    console.log(chalk.green('  update') + chalk.gray('                 Install or update Spec-Flow (non-interactive)'));
    console.log(chalk.green('  status') + chalk.gray('                 Check installation health and version'));
    console.log(chalk.green('  setup-roadmap') + chalk.gray('          Set up GitHub Issues for roadmap'));
    console.log(chalk.green('  install-hooks') + chalk.gray('          Install design token enforcement hooks'));
    console.log(chalk.green('  uninstall-hooks') + chalk.gray('        Remove design token enforcement hooks'));
    console.log(chalk.green('  install-codex-prompts') + chalk.gray('  Copy Codex prompt templates to ~/.codex/prompts'));
    console.log(chalk.green('  help') + chalk.gray('                   Show this help message\n'));

    console.log(chalk.white('Options:'));
    console.log(chalk.gray('  -t, --target <path>        Target directory (default: current directory)'));
    console.log(chalk.gray('  --non-interactive          Skip prompts, use defaults (init only)'));
    console.log(chalk.gray('  -s, --strategy <mode>      Conflict resolution: merge|backup|skip|force (init only)'));
    console.log(chalk.gray('  --check                    Exit code 1 if update available (status only, for CI)'));
    console.log(chalk.gray('  --skip-version-check       Skip npm registry check (status only)'));
    console.log(chalk.gray('  -v, --version              Output version number\n'));

    console.log(chalk.white('Examples:'));
    console.log(chalk.gray('  # Initialize in current directory'));
    console.log(chalk.green('  npx spec-flow init\n'));
    console.log(chalk.gray('  # Initialize in specific directory'));
    console.log(chalk.green('  npx spec-flow init --target ./my-project\n'));
    console.log(chalk.gray('  # Update existing installation'));
    console.log(chalk.green('  npx spec-flow update\n'));
    console.log(chalk.gray('  # Check for updates'));
    console.log(chalk.green('  npx spec-flow status\n'));
    console.log(chalk.gray('  # CI/CD: fail if not on latest version'));
    console.log(chalk.green('  npx spec-flow status --check\n'));

    console.log(chalk.white('Documentation:'));
    console.log(chalk.gray('  https://github.com/marcusgoll/Spec-Flow\n'));
  });

// Parse arguments
program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}

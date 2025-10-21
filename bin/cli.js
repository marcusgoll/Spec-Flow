#!/usr/bin/env node

const { program } = require('commander');
const path = require('path');
const chalk = require('chalk');
const { runWizard } = require('./install-wizard');
const { update } = require('./install');
const { healthCheck } = require('./validate');
const { setupRoadmap } = require('./setup-roadmap');
const { printHeader, printSuccess, printError, printWarning } = require('./utils');
const { STRATEGIES } = require('./conflicts');

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

// Update command - update existing installation
program
  .command('update')
  .description('Update Spec-Flow to latest version')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    printHeader('Updating Spec-Flow');

    try {
      const result = await update({
        targetDir,
        verbose: true
      });

      if (!result.success) {
        printError(result.error);
        process.exit(1);
      }

      printSuccess('\nUpdate complete!');
      console.log(chalk.cyan(`\nSpec-Flow version: ${chalk.bold(VERSION)}`));
      console.log(chalk.gray('Templates updated, user data preserved (memory, specs, learnings.md)'));
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
  .description('Check Spec-Flow installation status')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    printHeader('Spec-Flow Status');

    try {
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

      if (!health.healthy) {
        console.log(chalk.white('To fix:'));
        console.log(chalk.green('  npx spec-flow update') + chalk.gray('  # Re-install missing files\n'));
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

// Help command
program
  .command('help')
  .description('Show help information')
  .action(() => {
    console.log(chalk.cyan.bold('\nSpec-Flow - Spec-Driven Development Toolkit\n'));
    console.log(chalk.white('Usage:'));
    console.log(chalk.gray('  npx spec-flow <command> [options]\n'));

    console.log(chalk.white('Commands:'));
    console.log(chalk.green('  init') + chalk.gray('           Initialize Spec-Flow in current directory'));
    console.log(chalk.green('  update') + chalk.gray('         Update existing Spec-Flow installation'));
    console.log(chalk.green('  status') + chalk.gray('         Check installation health'));
    console.log(chalk.green('  setup-roadmap') + chalk.gray('  Set up GitHub Issues for roadmap'));
    console.log(chalk.green('  help') + chalk.gray('           Show this help message\n'));

    console.log(chalk.white('Options:'));
    console.log(chalk.gray('  -t, --target <path>        Target directory (default: current directory)'));
    console.log(chalk.gray('  --non-interactive          Skip prompts, use defaults (init only)'));
    console.log(chalk.gray('  -s, --strategy <mode>      Conflict resolution: merge|backup|skip|force (init only)'));
    console.log(chalk.gray('  -v, --version              Output version number\n'));

    console.log(chalk.white('Examples:'));
    console.log(chalk.gray('  # Initialize in current directory'));
    console.log(chalk.green('  npx spec-flow init\n'));
    console.log(chalk.gray('  # Initialize in specific directory'));
    console.log(chalk.green('  npx spec-flow init --target ./my-project\n'));
    console.log(chalk.gray('  # Initialize with conflict resolution strategy'));
    console.log(chalk.green('  npx spec-flow init --strategy merge --non-interactive\n'));
    console.log(chalk.gray('  # Update existing installation'));
    console.log(chalk.green('  npx spec-flow update\n'));
    console.log(chalk.gray('  # Check installation status'));
    console.log(chalk.green('  npx spec-flow status\n'));

    console.log(chalk.white('Documentation:'));
    console.log(chalk.gray('  https://github.com/marcusgoll/Spec-Flow\n'));
  });

// Parse arguments
program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}

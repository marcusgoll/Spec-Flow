#!/usr/bin/env node

const { program } = require('commander');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const chalk = require('chalk');

const PACKAGE_ROOT = path.resolve(__dirname, '..');
const VERSION = require('../package.json').version;

program
  .name('spec-flow')
  .description('Spec-Driven Development workflow toolkit for Claude Code')
  .version(VERSION);

// Install command - copies Spec-Flow to current directory
program
  .command('init')
  .description('Initialize Spec-Flow in current directory')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .option('--non-interactive', 'Skip interactive prompts, use defaults')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
    console.log(chalk.cyan.bold(' Spec-Flow Installation Wizard'));
    console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

    // Determine which installer to use based on platform
    const isWindows = process.platform === 'win32';
    const installerScript = isWindows
      ? path.join(PACKAGE_ROOT, '.spec-flow', 'scripts', 'powershell', 'install-wizard.ps1')
      : path.join(PACKAGE_ROOT, '.spec-flow', 'scripts', 'bash', 'install-wizard.sh');

    try {
      let command;
      if (isWindows) {
        // Windows: Use PowerShell
        const args = [
          '-TargetDir', `"${targetDir}"`
        ];
        if (options.nonInteractive) {
          args.push('-NonInteractive');
        }
        command = `powershell -NoLogo -NoProfile -File "${installerScript}" ${args.join(' ')}`;
      } else {
        // macOS/Linux: Use bash
        const args = [
          '--target-dir', targetDir
        ];
        if (options.nonInteractive) {
          args.push('--non-interactive');
        }
        // Make script executable
        fs.chmodSync(installerScript, '755');
        command = `"${installerScript}" ${args.join(' ')}`;
      }

      execSync(command, { stdio: 'inherit' });

      console.log(chalk.green('\n✓ Installation complete!\n'));
      console.log(chalk.white('Next steps:'));
      console.log(chalk.gray('  1. cd ' + targetDir));
      console.log(chalk.gray('  2. Open in Claude Code'));
      console.log(chalk.green('  3. Run /constitution') + chalk.gray(' to customize your standards'));
      console.log(chalk.green('  4. Run /roadmap') + chalk.gray(' to plan your first features\n'));
    } catch (error) {
      console.error(chalk.red('\n✗ Installation failed:'), error.message);
      process.exit(1);
    }
  });

// Update command - updates existing Spec-Flow installation
program
  .command('update')
  .description('Update Spec-Flow to latest version')
  .option('-t, --target <path>', 'Target directory (defaults to current directory)')
  .action(async (options) => {
    const targetDir = options.target ? path.resolve(options.target) : process.cwd();

    console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
    console.log(chalk.cyan.bold(' Updating Spec-Flow'));
    console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

    // Check if Spec-Flow is installed
    const claudeDir = path.join(targetDir, '.claude');
    const specFlowDir = path.join(targetDir, '.spec-flow');

    if (!fs.existsSync(claudeDir) && !fs.existsSync(specFlowDir)) {
      console.error(chalk.red('✗ Spec-Flow not found in this directory.'));
      console.log(chalk.gray('  Run ' + chalk.green('spec-flow init') + ' to install.\n'));
      process.exit(1);
    }

    // Backup existing memory files
    const memoryDir = path.join(specFlowDir, 'memory');
    const backupDir = path.join(specFlowDir, 'memory-backup-' + Date.now());

    if (fs.existsSync(memoryDir)) {
      console.log(chalk.yellow('  Backing up memory files...'));
      fs.cpSync(memoryDir, backupDir, { recursive: true });
      console.log(chalk.green('  ✓ Backup created: ' + path.basename(backupDir)));
    }

    // Run installation (will overwrite files but preserve memory)
    const isWindows = process.platform === 'win32';
    const installerScript = isWindows
      ? path.join(PACKAGE_ROOT, '.spec-flow', 'scripts', 'powershell', 'install-spec-flow.ps1')
      : path.join(PACKAGE_ROOT, '.spec-flow', 'scripts', 'bash', 'install-spec-flow.sh');

    try {
      let command;
      if (isWindows) {
        command = `powershell -NoLogo -NoProfile -File "${installerScript}" -TargetDir "${targetDir}"`;
      } else {
        fs.chmodSync(installerScript, '755');
        command = `"${installerScript}" --target-dir "${targetDir}"`;
      }

      execSync(command, { stdio: 'inherit' });

      console.log(chalk.green('\n✓ Update complete!'));
      console.log(chalk.gray('\n  Memory files were preserved.'));
      console.log(chalk.gray('  Backup available at: ' + backupDir + '\n'));
    } catch (error) {
      console.error(chalk.red('\n✗ Update failed:'), error.message);

      // Restore backup if update failed
      if (fs.existsSync(backupDir)) {
        console.log(chalk.yellow('  Restoring backup...'));
        fs.rmSync(memoryDir, { recursive: true, force: true });
        fs.cpSync(backupDir, memoryDir, { recursive: true });
        console.log(chalk.green('  ✓ Backup restored'));
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
    console.log(chalk.green('  init') + chalk.gray('        Initialize Spec-Flow in current directory'));
    console.log(chalk.green('  update') + chalk.gray('      Update existing Spec-Flow installation'));
    console.log(chalk.green('  help') + chalk.gray('        Show this help message\n'));

    console.log(chalk.white('Options:'));
    console.log(chalk.gray('  -t, --target <path>        Target directory (default: current directory)'));
    console.log(chalk.gray('  --non-interactive          Skip prompts, use defaults (init only)'));
    console.log(chalk.gray('  -V, --version              Output version number\n'));

    console.log(chalk.white('Examples:'));
    console.log(chalk.gray('  # Initialize in current directory'));
    console.log(chalk.green('  npx spec-flow init\n'));
    console.log(chalk.gray('  # Initialize in specific directory'));
    console.log(chalk.green('  npx spec-flow init --target ./my-project\n'));
    console.log(chalk.gray('  # Update existing installation'));
    console.log(chalk.green('  npx spec-flow update\n'));

    console.log(chalk.white('Documentation:'));
    console.log(chalk.gray('  https://github.com/marcusgoll/Spec-Flow\n'));
  });

// Parse arguments
program.parse(process.argv);

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}

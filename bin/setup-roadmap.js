#!/usr/bin/env node

/**
 * setup-roadmap.js - Interactive GitHub Issues roadmap setup
 *
 * Guides users through:
 * 1. GitHub authentication
 * 2. Label creation
 * 3. Optional migration from markdown roadmap
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const inquirer = require('inquirer');
const ora = require('ora');

// Determine OS and script paths
const isWindows = process.platform === 'win32';
const isMac = process.platform === 'darwin';
const isLinux = process.platform === 'linux';

// Find spec-flow scripts
function getScriptPath(scriptName) {
  // Check if running from installed package
  const installedPath = path.join(__dirname, '..', '.spec-flow', 'scripts');

  // Check if in development
  const devPath = path.join(process.cwd(), '.spec-flow', 'scripts');

  const scriptPath = fs.existsSync(installedPath) ? installedPath : devPath;

  if (isWindows) {
    return path.join(scriptPath, 'powershell', `${scriptName}.ps1`);
  } else {
    return path.join(scriptPath, 'bash', `${scriptName}.sh`);
  }
}

// Run a script and return promise
function runScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    let command, scriptArgs;

    if (isWindows) {
      command = 'pwsh';
      scriptArgs = ['-File', scriptPath, ...args];
    } else {
      command = 'bash';
      scriptArgs = [scriptPath, ...args];
    }

    const proc = spawn(command, scriptArgs, {
      stdio: 'inherit',
      shell: true
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Script exited with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

// Check if gh CLI is available
function checkGhCli() {
  return new Promise((resolve) => {
    const proc = spawn('gh', ['auth', 'status'], {
      stdio: 'ignore'
    });

    proc.on('close', (code) => {
      resolve(code === 0);
    });

    proc.on('error', () => {
      resolve(false);
    });
  });
}

// Main setup function
async function setupRoadmap() {
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' 🗺️  GitHub Issues Roadmap Setup'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.white('This wizard will help you set up GitHub Issues for roadmap management.\n'));

  // Step 1: Check GitHub authentication
  console.log(chalk.yellow('Step 1: GitHub Authentication'));
  console.log(chalk.gray('─────────────────────────────\n'));

  const hasGhCli = await checkGhCli();
  const hasToken = !!process.env.GITHUB_TOKEN;

  if (hasGhCli) {
    console.log(chalk.green('✓ GitHub CLI authenticated\n'));
  } else if (hasToken) {
    console.log(chalk.green('✓ GITHUB_TOKEN environment variable found\n'));
  } else {
    console.log(chalk.yellow('⚠  No GitHub authentication found\n'));

    const { authMethod } = await inquirer.prompt([{
      type: 'list',
      name: 'authMethod',
      message: 'How would you like to authenticate?',
      choices: [
        { name: 'GitHub CLI (Recommended) - Run: gh auth login', value: 'gh' },
        { name: 'Personal Access Token - Set GITHUB_TOKEN env var', value: 'token' },
        { name: 'Skip for now', value: 'skip' }
      ]
    }]);

    if (authMethod === 'skip') {
      console.log(chalk.gray('\nSkipping authentication. You can set it up later.\n'));
      console.log(chalk.white('To authenticate later:'));
      console.log(chalk.gray('  Option 1: gh auth login'));
      console.log(chalk.gray('  Option 2: export GITHUB_TOKEN=your_token\n'));
      process.exit(0);
    }

    if (authMethod === 'gh') {
      console.log(chalk.white('\nPlease run:'));
      console.log(chalk.cyan('  gh auth login\n'));
      console.log(chalk.gray('Then run this setup again: npx spec-flow setup-roadmap\n'));
      process.exit(0);
    }

    if (authMethod === 'token') {
      console.log(chalk.white('\nTo create a Personal Access Token:'));
      console.log(chalk.gray('  1. Go to: https://github.com/settings/tokens'));
      console.log(chalk.gray('  2. Click "Generate new token (classic)"'));
      console.log(chalk.gray('  3. Select scopes: repo, write:discussion'));
      console.log(chalk.gray('  4. Set environment variable:'));
      console.log(chalk.cyan('     export GITHUB_TOKEN=ghp_your_token\n'));
      console.log(chalk.gray('Then run this setup again: npx spec-flow setup-roadmap\n'));
      process.exit(0);
    }
  }

  // Step 2: Create labels
  console.log(chalk.yellow('Step 2: Create GitHub Labels'));
  console.log(chalk.gray('────────────────────────────\n'));

  const { createLabels } = await inquirer.prompt([{
    type: 'confirm',
    name: 'createLabels',
    message: 'Create labels for roadmap management? (priority, type, area, role, status, size)',
    default: true
  }]);

  if (createLabels) {
    const spinner = ora('Creating labels...').start();

    try {
      const scriptPath = getScriptPath('setup-github-labels');
      await runScript(scriptPath);
      spinner.succeed('Labels created successfully');
    } catch (error) {
      spinner.fail('Failed to create labels');
      console.log(chalk.red(`\nError: ${error.message}\n`));
      process.exit(1);
    }
  } else {
    console.log(chalk.gray('Skipping label creation\n'));
  }

  // Step 3: Check for existing markdown roadmap
  console.log(chalk.yellow('\nStep 3: Markdown Roadmap Migration'));
  console.log(chalk.gray('───────────────────────────────────\n'));

  const oldRoadmapPath = path.join(process.cwd(), '.spec-flow', 'memory', 'roadmap.md');
  const hasOldRoadmap = fs.existsSync(oldRoadmapPath);

  if (hasOldRoadmap) {
    console.log(chalk.yellow('⚠  Found existing markdown roadmap\n'));

    const { migrateRoadmap } = await inquirer.prompt([{
      type: 'confirm',
      name: 'migrateRoadmap',
      message: 'Migrate markdown roadmap to GitHub Issues?',
      default: false
    }]);

    if (migrateRoadmap) {
      const { dryRun } = await inquirer.prompt([{
        type: 'confirm',
        name: 'dryRun',
        message: 'Run migration in dry-run mode first? (recommended)',
        default: true
      }]);

      const spinner = ora(dryRun ? 'Running migration preview...' : 'Migrating roadmap...').start();

      try {
        const scriptPath = getScriptPath('migrate-roadmap-to-github');
        const args = dryRun ? ['--dry-run'] : [];
        await runScript(scriptPath, args);
        spinner.succeed(dryRun ? 'Migration preview complete' : 'Roadmap migrated successfully');

        if (dryRun) {
          const { runActual } = await inquirer.prompt([{
            type: 'confirm',
            name: 'runActual',
            message: 'Preview looks good. Run actual migration?',
            default: true
          }]);

          if (runActual) {
            const actualSpinner = ora('Migrating roadmap...').start();
            await runScript(scriptPath, ['--archive']);
            actualSpinner.succeed('Roadmap migrated and archived');
          }
        }
      } catch (error) {
        spinner.fail('Migration failed');
        console.log(chalk.red(`\nError: ${error.message}\n`));
        process.exit(1);
      }
    } else {
      console.log(chalk.gray('Skipping migration. You can migrate later with:'));
      console.log(chalk.cyan('  npm run setup:roadmap\n'));
    }
  } else {
    console.log(chalk.gray('No existing markdown roadmap found\n'));
  }

  // Step 4: Summary
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(' ✓ Roadmap Setup Complete'));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

  console.log(chalk.white('Your roadmap is now managed via GitHub Issues!\n'));

  console.log(chalk.white('Quick Start:'));
  console.log(chalk.green('  gh issue list --label type:feature') + chalk.gray('  # View roadmap'));
  console.log(chalk.green('  gh issue create --template feature.yml') + chalk.gray('  # Add feature\n'));

  console.log(chalk.white('Using /roadmap command:'));
  console.log(chalk.gray('  /roadmap add "Feature description"'));
  console.log(chalk.gray('  /roadmap brainstorm deep backend'));
  console.log(chalk.gray('  /roadmap move feature-slug to next\n'));

  console.log(chalk.white('Documentation:'));
  console.log(chalk.gray('  See: docs/github-roadmap-migration.md'));
  console.log(chalk.gray('  Or: https://github.com/marcusgoll/Spec-Flow#roadmap\n'));
}

// Run if called directly
if (require.main === module) {
  setupRoadmap().catch((error) => {
    console.error(chalk.red('\nSetup failed:'), error.message);
    if (process.env.DEBUG) {
      console.error(error.stack);
    }
    process.exit(1);
  });
}

module.exports = { setupRoadmap };

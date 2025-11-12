#!/usr/bin/env node
/**
 * setup-roadmap.js — Interactive GitHub Issues roadmap setup (refactored)
 *
 * Goals:
 * - No shell injection footguns (avoid shell:true)
 * - Cross-platform script runner (bash / pwsh)
 * - Clear non-interactive flags for CI
 * - Smaller surface area, better errors
 */

const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const chalk = require('chalk');
const inquirer = require('inquirer');
const ora = require('ora');

// -------------------------------
// Args / constants
// -------------------------------
const argv = new Set(process.argv.slice(2));
const FLAG_YES = argv.has('--yes');
const FLAG_NO_LABELS = argv.has('--no-labels');
const FLAG_MIGRATE = argv.has('--migrate');
const FLAG_DRY_RUN = argv.has('--dry-run');
const FLAG_NONINTERACTIVE = argv.has('--non-interactive') || process.env.CI === 'true';

const isWindows = process.platform === 'win32';
const SCRIPT_ROOTS = [
  // local dev repo
  path.join(process.cwd(), '.spec-flow', 'scripts'),
  // installed package layout (node_modules/spec-flow/dist/../.spec-flow/scripts)
  path.join(__dirname, '..', '.spec-flow', 'scripts'),
];

// -------------------------------
// Utilities
// -------------------------------
function logTitle(title) {
  console.log(chalk.cyan.bold('\n' + '═'.repeat(67)));
  console.log(chalk.cyan.bold(' ' + title));
  console.log(chalk.cyan.bold(' ' + '═'.repeat(65) + '\n'));
}

function commandExists(cmd) {
  const whichCmd = isWindows ? 'where' : 'which';
  const res = spawnSync(whichCmd, [cmd], { stdio: 'ignore' });
  return res.status === 0;
}

function getScriptPath(name) {
  for (const root of SCRIPT_ROOTS) {
    const p = path.join(root, isWindows ? 'powershell' : 'bash', `${name}${isWindows ? '.ps1' : '.sh'}`);
    if (fs.existsSync(p)) return p;
  }
  throw new Error(`Script not found: ${name} (searched: ${SCRIPT_ROOTS.join(', ')})`);
}

function runScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const runner = isWindows
      ? (commandExists('pwsh') ? 'pwsh' : 'powershell') // prefer PowerShell Core if present
      : 'bash';

    const proc = spawn(runner, isWindows ? ['-NoProfile', '-File', scriptPath, ...args] : [scriptPath, ...args], {
      stdio: 'inherit', // stream through for better UX
      windowsHide: true,
    });

    proc.on('error', reject);
    proc.on('close', code => (code === 0 ? resolve() : reject(new Error(`${path.basename(scriptPath)} exited with ${code}`))));
  });
}

async function ghAuthStatus() {
  // Prefer GH CLI; fall back to PAT
  if (commandExists('gh')) {
    return new Promise(resolve => {
      const p = spawn('gh', ['auth', 'status'], { stdio: 'ignore' });
      p.on('close', code => resolve(code === 0 ? 'gh' : (process.env.GITHUB_TOKEN ? 'token' : 'none')));
      p.on('error', () => resolve(process.env.GITHUB_TOKEN ? 'token' : 'none'));
    });
  }
  return process.env.GITHUB_TOKEN ? 'token' : 'none';
}

function ensureGitRepo() {
  const r1 = spawnSync('git', ['rev-parse', '--is-inside-work-tree'], { stdio: 'ignore' });
  if (r1.status !== 0) {
    console.error(chalk.red('❌ Not a git repository'));
    process.exit(1);
  }
  const r2 = spawnSync('git', ['config', '--get', 'remote.origin.url'], { stdio: 'ignore' });
  if (r2.status !== 0) {
    console.error(chalk.red('❌ No GitHub remote found (missing origin)'));
    process.exit(1);
  }
}

// -------------------------------
// Main
// -------------------------------
async function setupRoadmap() {
  logTitle('🗺️  GitHub Issues Roadmap Setup');

  console.log(chalk.white('This wizard sets up labels and optionally migrates your Markdown roadmap to GitHub Issues.\n'));

  // Step 0: repo check
  ensureGitRepo();

  // Step 1: Authentication
  console.log(chalk.yellow('Step 1: GitHub Authentication'));
  console.log(chalk.gray('─────────────────────────────\n'));

  const authMethod = await ghAuthStatus();

  if (authMethod === 'gh') {
    console.log(chalk.green('✓ GitHub CLI authenticated\n'));
  } else if (authMethod === 'token') {
    console.log(chalk.green('✓ GITHUB_TOKEN detected (classic/fine-grained)\n'));
  } else {
    console.log(chalk.yellow('⚠  No GitHub authentication found\n'));

    if (FLAG_NONINTERACTIVE) {
      console.error(chalk.red('❌ Authentication required in non-interactive mode'));
      console.error(chalk.gray('   Use: gh auth login  OR  export GITHUB_TOKEN=...'));
      process.exit(1);
    }

    const { method } = await inquirer.prompt([
      {
        type: 'list',
        name: 'method',
        message: 'How would you like to authenticate?',
        choices: [
          { name: 'GitHub CLI (recommended): gh auth login', value: 'gh' },
          { name: 'Personal Access Token: set GITHUB_TOKEN', value: 'token' },
          { name: 'Exit and do it later', value: 'skip' },
        ],
      },
    ]);

    if (method === 'skip') {
      console.log(chalk.gray('\nSkipping auth. Re-run after configuring auth:\n  gh auth login\n  # or\n  export GITHUB_TOKEN=...'));
      process.exit(0);
    }
    if (method === 'gh') {
      console.log(chalk.white('\nRun:'), chalk.cyan('gh auth login'));
      console.log(chalk.gray('Then re-run:'), chalk.cyan('npx spec-flow setup-roadmap\n'));
      process.exit(0);
    }
    if (method === 'token') {
      console.log(chalk.white('\nMinimal scopes to create/manage issues:'));
      console.log(chalk.gray('  • public repos:  public_repo'));
      console.log(chalk.gray('  • private repos: repo\n'));
      console.log(chalk.white('Export token and re-run:'));
      console.log(chalk.cyan('  export GITHUB_TOKEN=ghp_xxx\n'));
      process.exit(0);
    }
  }

  // Step 2: Labels
  console.log(chalk.yellow('Step 2: Create GitHub Labels'));
  console.log(chalk.gray('────────────────────────────\n'));

  const shouldCreateLabels =
    FLAG_NO_LABELS ? false : (FLAG_YES || FLAG_NONINTERACTIVE ? true : (await inquirer.prompt([
      {
        type: 'confirm',
        name: 'createLabels',
        message: 'Create labels for roadmap (priority, type, area, role, status, size)?',
        default: true,
      },
    ])).createLabels);

  if (shouldCreateLabels) {
    const spinner = ora('Creating labels...').start();
    try {
      await runScript(getScriptPath('setup-github-labels'));
      spinner.succeed('Labels created');
    } catch (e) {
      spinner.fail('Failed to create labels');
      console.error(chalk.red(e.message));
      process.exit(1);
    }
  } else {
    console.log(chalk.gray('Skipping label creation\n'));
  }

  // Step 3: Migration (optional)
  console.log(chalk.yellow('Step 3: Markdown Roadmap Migration'));
  console.log(chalk.gray('───────────────────────────────────\n'));

  const oldRoadmapPath = path.join(process.cwd(), '.spec-flow', 'memory', 'roadmap.md');
  const hasOldRoadmap = fs.existsSync(oldRoadmapPath);

  if (!hasOldRoadmap) {
    console.log(chalk.gray('No existing markdown roadmap found\n'));
  } else {
    console.log(chalk.yellow('⚠  Found existing markdown roadmap\n'));

    const doMigrate = FLAG_MIGRATE
      ? true
      : (FLAG_NONINTERACTIVE
          ? false
          : (await inquirer.prompt([{ type: 'confirm', name: 'migrateRoadmap', message: 'Migrate to GitHub Issues?', default: false }])).migrateRoadmap);

    if (doMigrate) {
      const doDryRun = FLAG_DRY_RUN || (!FLAG_NONINTERACTIVE && (await inquirer.prompt([
        { type: 'confirm', name: 'dryRun', message: 'Run migration preview (dry-run)?', default: true },
      ])).dryRun);

      const spinner = ora(doDryRun ? 'Running migration preview...' : 'Migrating roadmap...').start();
      try {
        const args = doDryRun ? ['--dry-run'] : [];
        await runScript(getScriptPath('migrate-roadmap-to-github'), args);
        spinner.succeed(doDryRun ? 'Migration preview complete' : 'Roadmap migrated');

        if (doDryRun && !FLAG_NONINTERACTIVE) {
          const { runActual } = await inquirer.prompt([
            { type: 'confirm', name: 'runActual', message: 'Preview looks good. Run actual migration?', default: true },
          ]);
          if (runActual) {
            const s2 = ora('Migrating roadmap...').start();
            await runScript(getScriptPath('migrate-roadmap-to-github'), ['--archive']);
            s2.succeed('Roadmap migrated and archived');
          }
        }
      } catch (e) {
        spinner.fail('Migration failed');
        console.error(chalk.red(e.message));
        process.exit(1);
      }
    } else {
      console.log(chalk.gray('Skipping migration. Later:'), chalk.cyan('npm run setup:roadmap\n'));
    }
  }

  // Step 4: Summary
  logTitle('✓ Roadmap Setup Complete');

  console.log(chalk.white('Your roadmap is now managed in GitHub Issues.\n'));

  console.log(chalk.white('Quick start:'));
  console.log(chalk.green('  gh issue list --label type:feature') + chalk.gray('   # view roadmap'));
  console.log(chalk.green('  gh issue create --template feature.yml') + chalk.gray('  # add feature\n'));

  console.log(chalk.white('Spec-Flow commands:'));
  console.log(chalk.gray('  /roadmap add "Feature description"'));
  console.log(chalk.gray('  /roadmap brainstorm deep backend'));
  console.log(chalk.gray('  /roadmap move feature-slug to next\n'));

  console.log(chalk.white('Docs:'));
  console.log(chalk.gray('  docs/github-roadmap-migration.md'));
  console.log(chalk.gray('  https://github.com/marcusgoll/Spec-Flow#roadmap\n'));
}

// Run if called directly
if (require.main === module) {
  setupRoadmap().catch(err => {
    console.error(chalk.red('\nSetup failed:'), err.message);
    if (process.env.DEBUG) console.error(err.stack);
    process.exit(1);
  });
}

module.exports = { setupRoadmap };

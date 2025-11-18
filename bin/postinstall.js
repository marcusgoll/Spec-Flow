#!/usr/bin/env node

/* Post-install banner with resilient color + layout
 * - Works with Chalk v4 (CJS) and v5+ (ESM-only)
 * - Skips noise in CI
 * - Fallbacks cleanly if chalk/boxen aren't present
 * - Copies GitHub workflows to user's .github/workflows/ (if applicable)
 */

const tty = require('tty');
const path = require('path');
const fs = require('fs');

(async function main() {
  if (shouldSilence()) return;

  const chalk = await loadChalk();         // color, or noop if unavailable
  const boxen = await loadBoxen();         // nice border if present
  const width = Math.min(getTermWidth(), 100);

  const header = chalk.cyan.bold(' ✓ Spec-Flow Package Installed');
  const line   = chalk.cyan.bold(''.padEnd(Math.max(header.length + 2, 67), '═'));

  const pm = detectPackageManager();
  const dlx = pm === 'pnpm' ? 'pnpm dlx' : pm === 'yarn' ? 'yarn dlx' : pm === 'bun' ? 'bunx' : 'npx';

  const body = [
    chalk.white('Quick Start:'),
    `${chalk.green(`  ${dlx} spec-flow init`)}${chalk.gray('        # Initialize in current directory')}`,
    `${chalk.green(`  ${dlx} spec-flow init --target ./my-project`)}${chalk.gray(' # Or specify target directory')}`,
    '',
    chalk.white('After installation:'),
    chalk.gray('  1. Read QUICKSTART.md (copied to your project)'),
    chalk.gray('  2. Set up GitHub roadmap: ') + chalk.green(`${dlx} spec-flow setup-roadmap`) + chalk.gray(' (recommended)'),
    chalk.gray('  3. Open in your editor (e.g., Claude Code)'),
    chalk.gray('  4. Run /constitution, /design-inspiration (optional)'),
    chalk.gray('  5. Start building: /feature "feature-name"'),
    '',
    chalk.white('Documentation:'),
    chalk.gray('  https://github.com/marcusgoll/Spec-Flow')
  ].join('\n');

  const banner = [
    '',
    line,
    header,
    line,
    ''
  ].join('\n');

  if (boxen) {
    // pretty box; degrade gracefully if not available
    const boxed = boxen(body, {
      padding: 1,
      margin: 1,
      borderStyle: 'round',
      borderColor: 'cyan',
      width
    });
    console.log(banner);
    console.log(boxed);
    console.log();
  } else {
    console.log(banner);
    console.log(body + '\n');
  }

  // Install GitHub workflows (interactive, skip in CI)
  await installWorkflows(chalk);
})().catch(() => { /* never explode a postinstall message */ });

/* ---------------- helpers ---------------- */

async function installWorkflows(chalk) {
  // Skip workflow installation in CI, tests, or when not in a project directory
  if (process.env.CI || process.env.TEST || process.env.SPEC_FLOW_SILENT) return;
  if (!tty.isatty(1)) return; // Non-interactive terminal

  try {
    // Find the user's project root (where spec-flow is being installed)
    // This script runs from node_modules/spec-flow/bin/postinstall.js
    const packageRoot = path.resolve(__dirname, '..');  // node_modules/spec-flow/
    const userProjectRoot = path.resolve(packageRoot, '..', '..'); // User's project root

    // Check if we're being installed as a local dependency (not global)
    const userPackageJson = path.join(userProjectRoot, 'package.json');
    if (!fs.existsSync(userPackageJson)) {
      // Global install or not in a project - skip workflow installation
      return;
    }

    const sourceWorkflowsDir = path.join(packageRoot, '.github', 'workflows');
    const targetWorkflowsDir = path.join(userProjectRoot, '.github', 'workflows');

    // Check if source workflows exist
    if (!fs.existsSync(sourceWorkflowsDir)) return;

    const workflowFiles = fs.readdirSync(sourceWorkflowsDir).filter(f => f.endsWith('.yml'));
    if (workflowFiles.length === 0) return;

    // Check if user already has .github/workflows directory
    const hasWorkflowsDir = fs.existsSync(targetWorkflowsDir);

    if (hasWorkflowsDir) {
      // Directory exists - install workflows automatically
      console.log(chalk.cyan('\n📋 Installing GitHub Actions workflows...\n'));

      let copiedCount = 0;
      let skippedCount = 0;

      for (const file of workflowFiles) {
        const sourcePath = path.join(sourceWorkflowsDir, file);
        const targetPath = path.join(targetWorkflowsDir, file);

        if (fs.existsSync(targetPath)) {
          // File already exists - skip to avoid overwriting user customizations
          console.log(chalk.gray(`  ⊝ Skipped ${file} (already exists)`));
          skippedCount++;
        } else {
          // Copy workflow file
          fs.copyFileSync(sourcePath, targetPath);
          console.log(chalk.green(`  ✓ Installed ${file}`));
          copiedCount++;
        }
      }

      if (copiedCount > 0) {
        console.log(chalk.green(`\n✓ Installed ${copiedCount} workflow(s) to .github/workflows/`));
      }
      if (skippedCount > 0) {
        console.log(chalk.gray(`  ${skippedCount} workflow(s) already exist (not overwritten)`));
      }
    } else {
      // Directory doesn't exist - ask user if they want to create it
      console.log(chalk.yellow('\n⚠ GitHub Actions workflows are available but .github/workflows/ directory not found.'));

      // Use inquirer if available, otherwise skip
      const inquirer = await loadInquirer();
      if (!inquirer) {
        console.log(chalk.gray('  Run manually: mkdir -p .github/workflows && cp node_modules/spec-flow/.github/workflows/*.yml .github/workflows/\n'));
        return;
      }

      const { install } = await inquirer.prompt([
        {
          type: 'confirm',
          name: 'install',
          message: 'Create .github/workflows/ and install GitHub Actions workflows?',
          default: true
        }
      ]);

      if (install) {
        // Create directory and copy workflows
        fs.mkdirSync(targetWorkflowsDir, { recursive: true });
        console.log(chalk.green('\n✓ Created .github/workflows/'));

        let copiedCount = 0;
        for (const file of workflowFiles) {
          const sourcePath = path.join(sourceWorkflowsDir, file);
          const targetPath = path.join(targetWorkflowsDir, file);
          fs.copyFileSync(sourcePath, targetPath);
          console.log(chalk.green(`  ✓ Installed ${file}`));
          copiedCount++;
        }

        console.log(chalk.green(`\n✓ Installed ${copiedCount} workflow(s)\n`));
      } else {
        console.log(chalk.gray('\nSkipped workflow installation. Install manually later if needed.\n'));
      }
    }
  } catch (err) {
    // Silent failure - don't break installation
    // console.error('Workflow installation error:', err);
  }
}

function shouldSilence() {
  // Don’t spam CI logs or non-interactive environments
  if (process.env.CI || process.env.TEST || process.env.SPEC_FLOW_SILENT) return true;
  if (!tty.isatty(1)) return true;
  return false;
}

function getTermWidth() {
  return (process.stdout && process.stdout.columns) || 80;
}

function detectPackageManager() {
  const ua = process.env.npm_config_user_agent || '';
  if (ua.includes('pnpm')) return 'pnpm';
  if (ua.includes('yarn')) return 'yarn';
  if (ua.includes('bun'))  return 'bun';
  return 'npm';
}

async function loadChalk() {
  // Support both Chalk v5+ (ESM) and v4 (CJS). If neither, return a noop “chalk”.
  try {
    const m = await import('chalk');                 // ESM path (v5+)
    return m.default || m;
  } catch {
    try {
      // eslint-disable-next-line global-require, import/no-commonjs
      return require('chalk');                       // CJS path (v4)
    } catch {
      return makeNoopChalk();
    }
  }
}

async function loadBoxen() {
  try {
    const m = await import('boxen');                 // ESM first
    return m.default || m;
  } catch {
    try {
      // eslint-disable-next-line global-require, import/no-commonjs
      return require('boxen');                       // CJS fallback
    } catch {
      return null;
    }
  }
}

async function loadInquirer() {
  try {
    const m = await import('inquirer');              // ESM first
    return m.default || m;
  } catch {
    try {
      // eslint-disable-next-line global-require, import/no-commonjs
      return require('inquirer');                    // CJS fallback (v8.x)
    } catch {
      return null;
    }
  }
}

function makeNoopChalk() {
  // minimal shim so chalk.cyan.bold(...) won’t crash
  const id = s => String(s);
  const chain = new Proxy(id, {
    get: () => chain,
    apply: (_t, _this, args) => id(...args)
  });
  return new Proxy({}, { get: () => chain });
}

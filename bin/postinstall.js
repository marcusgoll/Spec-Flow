#!/usr/bin/env node

/* Post-install banner with resilient color + layout
 * - Works with Chalk v4 (CJS) and v5+ (ESM-only)
 * - Skips noise in CI
 * - Fallbacks cleanly if chalk/boxen aren't present
 */

const tty = require('tty');

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
})().catch(() => { /* never explode a postinstall message */ });

/* ---------------- helpers ---------------- */

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

function makeNoopChalk() {
  // minimal shim so chalk.cyan.bold(...) won’t crash
  const id = s => String(s);
  const chain = new Proxy(id, {
    get: () => chain,
    apply: (_t, _this, args) => id(...args)
  });
  return new Proxy({}, { get: () => chain });
}

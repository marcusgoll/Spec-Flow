#!/usr/bin/env node

const chalk = require('chalk');

console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
console.log(chalk.cyan.bold(' ✓ Spec-Flow Package Installed'));
console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

console.log(chalk.white('Quick Start:'));
console.log(chalk.green('  npx spec-flow init') + chalk.gray('        # Initialize in current directory'));
console.log(chalk.green('  npx spec-flow init --target ./my-project') + chalk.gray(' # Or spec-flow directory\n'));

console.log(chalk.white('After installation:'));
console.log(chalk.gray('  1. Read QUICKSTART.md (copied to your project)'));
console.log(chalk.gray('  2. Set up GitHub roadmap: npx spec-flow setup-roadmap (recommended)'));
console.log(chalk.gray('  3. Open in Claude Code'));
console.log(chalk.gray('  4. Run /constitution, /design-inspiration (optional)'));
console.log(chalk.gray('  5. Start building: /feature "feature-name"\n'));

console.log(chalk.white('Documentation:'));
console.log(chalk.gray('  https://github.com/marcusgoll/Spec-Flow\n'));


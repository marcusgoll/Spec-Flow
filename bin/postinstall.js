#!/usr/bin/env node

const chalk = require('chalk');

console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
console.log(chalk.cyan.bold(' Spec-Flow Installed Successfully!'));
console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));

console.log(chalk.white('Get started:'));
console.log(chalk.gray('  1. Initialize Spec-Flow in your project:'));
console.log(chalk.green('     npx spec-flow init\n'));

console.log(chalk.gray('  2. Or initialize in a specific directory:'));
console.log(chalk.green('     npx spec-flow init --target ./my-project\n'));

console.log(chalk.gray('  3. Update existing installation:'));
console.log(chalk.green('     npx spec-flow update\n'));

console.log(chalk.white('Documentation:'));
console.log(chalk.gray('  • Quick Start: https://github.com/marcusgoll/Spec-Flow/blob/main/QUICKSTART.md'));
console.log(chalk.gray('  • Full Guide: https://github.com/marcusgoll/Spec-Flow#readme\n'));

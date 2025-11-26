#!/usr/bin/env node

const path = require('path');
const os = require('os');
const fs = require('fs');
const fse = require('fs-extra');
const readline = require('readline');
const chalk = require('chalk');
const { printHeader, printSuccess, printWarning, printError } = require('./utils');

const REPO_PROMPT_DIR = path.resolve(process.cwd(), '.codex', 'commands');

function resolveCodexHome() {
  const envPath = process.env.CODEX_HOME;
  if (envPath && envPath.trim().length > 0) {
    return path.resolve(envPath);
  }
  return path.join(os.homedir(), '.codex');
}

function createInterface() {
  return readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
}

function ask(question) {
  const rl = createInterface();
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

async function shouldOverwrite(file, options) {
  if (options.force) {
    return true;
  }

  if (options.dryRun) {
    return false;
  }

  const answer = await ask(`File ${file} exists. Overwrite? (y/N) `);
  return answer === 'y' || answer === 'yes';
}

async function copyPrompts(options = {}) {
  const codexHome = resolveCodexHome();
  const targetDir = path.join(codexHome, 'prompts');

  if (!fs.existsSync(REPO_PROMPT_DIR)) {
    throw new Error('Codex prompt templates not found at .codex/commands/');
  }

  const promptFiles = fs.readdirSync(REPO_PROMPT_DIR).filter((file) => file.endsWith('.md'));
  if (promptFiles.length === 0) {
    throw new Error('No prompt templates found in .codex/commands/');
  }

  if (!options.dryRun) {
    await fse.ensureDir(targetDir);
  }

  const results = [];

  for (const file of promptFiles) {
    const src = path.join(REPO_PROMPT_DIR, file);
    const dest = path.join(targetDir, file);
    const exists = fs.existsSync(dest);

    if (exists) {
      const overwrite = await shouldOverwrite(file, options);
      if (!overwrite) {
        results.push({ file, action: 'skipped' });
        continue;
      }
    }

    if (options.dryRun) {
      results.push({ file, action: exists ? 'would-overwrite' : 'would-copy' });
      continue;
    }

    await fse.copy(src, dest);
    results.push({ file, action: exists ? 'overwritten' : 'copied' });
  }

  return { targetDir, results, codexHome };
}

async function installCodexPrompts(options = {}) {
  printHeader('Installing Codex Prompts');

  try {
    const { targetDir, results, codexHome } = await copyPrompts(options);

    if (options.dryRun) {
      printSuccess('Dry run complete. No files were copied.');
    } else {
      printSuccess(`Installed prompts to ${targetDir}`);
    }

    console.log('');
    results.forEach(({ file, action }) => {
      switch (action) {
        case 'copied':
          console.log(chalk.green(`  ✓ ${file} (copied)`));
          break;
        case 'overwritten':
          console.log(chalk.yellow(`  ↻ ${file} (overwritten)`));
          break;
        case 'skipped':
          printWarning(`  ↷ ${file} (skipped)`);
          break;
        case 'would-copy':
          console.log(chalk.gray(`  ○ ${file} (would copy)`));
          break;
        case 'would-overwrite':
          console.log(chalk.gray(`  ○ ${file} (would overwrite)`));
          break;
        default:
          break;
      }
    });

    console.log('');
    console.log(chalk.white('Next steps:'));
    console.log(chalk.gray(`  - Use prompts from ${path.join(codexHome, 'prompts')} via Codex CLI.`));
    console.log(chalk.gray('  - Keep .codex/commands/ updated alongside .claude/ commands.'));
  } catch (error) {
    printError(`Failed to install prompts: ${error.message}`);
    if (error.stack && process.env.DEBUG) {
      console.error(error.stack);
    }
    process.exitCode = 1;
  }
}

if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {
    force: args.includes('--force') || args.includes('-f'),
    dryRun: args.includes('--dry-run'),
  };

  installCodexPrompts(options);
}

module.exports = {
  installCodexPrompts,
};

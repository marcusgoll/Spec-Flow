const fs = require('fs-extra');
const path = require('path');
const inquirer = require('inquirer');
const chalk = require('chalk');
const { install } = require('./install');
const { printHeader, printSuccess, printStep, printWarning } = require('./utils');
const { detectConflicts, formatConflicts, formatActions, STRATEGIES } = require('./conflicts');

/**
 * Run interactive installation wizard
 * @param {Object} options - Wizard options
 * @param {string} options.targetDir - Target directory
 * @param {boolean} options.nonInteractive - Skip prompts, use defaults
 * @param {string} options.conflictStrategy - Conflict resolution strategy (optional)
 * @returns {Promise<Object>} { success: boolean, error: string|null }
 */
async function runWizard(options) {
  const { targetDir, nonInteractive = false, conflictStrategy: providedStrategy } = options;

  printHeader('Spec-Flow Installation Wizard');

  if (nonInteractive) {
    printStep('Running in non-interactive mode (using defaults)');
    console.log('');

    // Run installation with defaults (merge strategy or provided strategy)
    return await install({
      targetDir,
      preserveMemory: false,
      verbose: true,
      conflictStrategy: providedStrategy || STRATEGIES.MERGE
    });
  }

  // Interactive mode
  console.log(chalk.white('This wizard will help you set up Spec-Flow for your project.\n'));

  // Step 1: Confirm target directory
  printStep('Step 1: Target Directory');
  console.log(chalk.gray(`  Installing to: ${targetDir}\n`));

  const { confirmDir } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'confirmDir',
      message: 'Is this the correct directory?',
      default: true
    }
  ]);

  if (!confirmDir) {
    return {
      success: false,
      error: 'Installation cancelled by user'
    };
  }

  // Step 2: Check for conflicts
  printStep('Step 2: Conflict Detection');
  const filesToCheck = ['CLAUDE.md', 'QUICKSTART.md', 'LICENSE', '.claude', '.spec-flow'];
  const { conflicts, hasConflicts } = await detectConflicts(targetDir, filesToCheck);

  let conflictStrategy = providedStrategy || STRATEGIES.MERGE; // Use provided strategy or default

  if (hasConflicts) {
    if (providedStrategy) {
      // Strategy provided via CLI
      console.log(chalk.yellow('\n⚠ Conflicts detected:\n'));
      console.log(formatConflicts(conflicts));
      console.log('');
      console.log(chalk.cyan(`Using conflict strategy: ${providedStrategy}\n`));
    } else {
      // Interactive mode - prompt for strategy
      console.log(chalk.yellow('\n⚠ Conflicts detected:\n'));
      console.log(formatConflicts(conflicts));
      console.log('');

      const { strategy } = await inquirer.prompt([
        {
          type: 'list',
          name: 'strategy',
          message: 'How to handle conflicts?',
          default: STRATEGIES.MERGE,
          choices: [
            {
              name: 'Smart merge (recommended) - Append to CLAUDE.md, rename others',
              value: STRATEGIES.MERGE
            },
            {
              name: 'Backup & overwrite - Create backups, then install',
              value: STRATEGIES.BACKUP
            },
            {
              name: 'Skip conflicts - Only install new files',
              value: STRATEGIES.SKIP
            },
            {
              name: 'Force overwrite - Replace everything',
              value: STRATEGIES.FORCE
            }
          ]
        }
      ]);

      conflictStrategy = strategy;

      // Confirm destructive actions
      if (strategy === STRATEGIES.FORCE) {
        const { confirmForce } = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'confirmForce',
            message: 'This will permanently overwrite existing files. Continue?',
            default: false
          }
        ]);

        if (!confirmForce) {
          return {
            success: false,
            error: 'Installation cancelled to prevent data loss'
          };
        }
      }
    }
  } else {
    printSuccess('No conflicts detected\n');
  }

  // Step 3: Project setup questions
  console.log('');
  printStep('Step 3: Project Configuration (Optional)');
  console.log(chalk.gray('  These will be saved to .spec-flow/memory/constitution.md\n'));

  const config = await inquirer.prompt([
    {
      type: 'input',
      name: 'projectName',
      message: 'Project name:',
      default: path.basename(targetDir)
    },
    {
      type: 'input',
      name: 'description',
      message: 'Project description (optional):',
      default: ''
    },
    {
      type: 'checkbox',
      name: 'stack',
      message: 'Select your tech stack:',
      choices: [
        { name: 'Next.js (React)', value: 'nextjs' },
        { name: 'FastAPI (Python)', value: 'fastapi' },
        { name: 'Express (Node.js)', value: 'express' },
        { name: 'Django (Python)', value: 'django' },
        { name: 'PostgreSQL', value: 'postgresql' },
        { name: 'MongoDB', value: 'mongodb' },
        { name: 'TypeScript', value: 'typescript' },
        { name: 'Other', value: 'other' }
      ]
    },
    {
      type: 'confirm',
      name: 'setupMemory',
      message: 'Initialize memory files (roadmap, constitution, design inspirations)?',
      default: true
    }
  ]);

  // Step 4: Run installation
  console.log('');
  printStep('Step 4: Installing Spec-Flow');
  console.log('');

  const result = await install({
    targetDir,
    preserveMemory: false,
    verbose: true,
    conflictStrategy
  });

  if (!result.success) {
    return result;
  }

  // Step 5: Initialize memory files if requested
  if (config.setupMemory) {
    console.log('');
    printStep('Step 5: Initializing memory files');
    await initializeMemory(targetDir, config);
    printSuccess('Memory files initialized');
  }

  // Success!
  console.log('');
  printSuccess('Installation complete!');

  // Show conflict resolutions if any
  if (result.conflictActions && result.conflictActions.length > 0) {
    console.log('');
    console.log(chalk.white('Conflict resolutions:'));
    console.log(formatActions(result.conflictActions));
  }
  console.log('');
  console.log(chalk.white('Next steps:'));
  console.log(chalk.gray('  1. cd ' + targetDir));
  console.log(chalk.gray('  2. Open in Claude Code'));

  if (config.setupMemory) {
    console.log(chalk.green('  3. Review .spec-flow/memory/ files'));
    console.log(chalk.green('  4. Run /roadmap') + chalk.gray(' to plan your first features'));
  } else {
    console.log(chalk.green('  3. Run /constitution') + chalk.gray(' to customize your standards'));
    console.log(chalk.green('  4. Run /roadmap') + chalk.gray(' to plan your first features'));
  }

  console.log(chalk.green('  5. Run /spec-flow "feature-name"') + chalk.gray(' to start building\n'));

  return { success: true, error: null };
}

/**
 * Initialize memory files with user configuration
 * @param {string} targetDir - Target directory
 * @param {Object} config - Configuration from wizard
 */
async function initializeMemory(targetDir, config) {
  const memoryDir = path.join(targetDir, '.spec-flow', 'memory');

  // Update constitution.md with project info
  const constitutionPath = path.join(memoryDir, 'constitution.md');

  if (await fs.pathExists(constitutionPath)) {
    let constitution = await fs.readFile(constitutionPath, 'utf8');

    // Replace placeholders
    constitution = constitution.replace('[Your Project Name]', config.projectName);

    if (config.description) {
      constitution = constitution.replace(
        '[Brief description of your project]',
        config.description
      );
    }

    if (config.stack && config.stack.length > 0) {
      const stackList = config.stack.map(s => `- ${s}`).join('\n');
      constitution = constitution.replace(
        '- [Your primary tech stack]',
        stackList
      );
    }

    await fs.writeFile(constitutionPath, constitution, 'utf8');
  }

  // Initialize empty roadmap
  const roadmapPath = path.join(memoryDir, 'roadmap.md');

  if (await fs.pathExists(roadmapPath)) {
    const roadmapContent = `# Product Roadmap: ${config.projectName}

## Vision
${config.description || '[Add your product vision here]'}

## Now (In Progress)

## Next (Validated & Ready)

## Later (Backlog)

## Shipped (Completed)

---
Last updated: ${new Date().toISOString().split('T')[0]}
`;
    await fs.writeFile(roadmapPath, roadmapContent, 'utf8');
  }
}

module.exports = {
  runWizard
};

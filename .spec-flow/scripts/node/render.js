#!/usr/bin/env node

/**
 * Template Renderer for /init-project
 *
 * Renders project documentation templates with variable substitution.
 * Supports idempotent operations with multiple modes.
 *
 * Usage:
 *   node render.js --template <path> --output <path> --answers <json-file> [--mode update]
 *
 * Modes:
 *   - default: Replace all placeholders
 *   - update: Only replace [NEEDS CLARIFICATION] tokens
 */

const fs = require('fs');
const path = require('path');

// Parse command-line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    template: null,
    output: null,
    answers: null,
    mode: 'default' // default | update
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--template':
        options.template = args[++i];
        break;
      case '--output':
        options.output = args[++i];
        break;
      case '--answers':
        options.answers = args[++i];
        break;
      case '--mode':
        options.mode = args[++i];
        break;
      case '--help':
        printHelp();
        process.exit(0);
      default:
        if (args[i].startsWith('--')) {
          console.error(`Unknown option: ${args[i]}`);
          process.exit(1);
        }
    }
  }

  // Validate required arguments
  if (!options.template || !options.output || !options.answers) {
    console.error('Error: Missing required arguments');
    printHelp();
    process.exit(1);
  }

  return options;
}

function printHelp() {
  console.log(`
Template Renderer for /init-project

Usage:
  node render.js --template <path> --output <path> --answers <json-file> [--mode <mode>]

Arguments:
  --template <path>    Path to template markdown file
  --output <path>      Path to output file
  --answers <json>     Path to JSON file with variable values
  --mode <mode>        Rendering mode (default | update)

Modes:
  default              Replace all {{VARIABLE}} placeholders (default)
  update               Only replace [NEEDS CLARIFICATION] tokens

Examples:
  # First-time generation
  node render.js --template templates/overview.md --output docs/project/overview.md --answers answers.json

  # Update existing doc (only fix NEEDS CLARIFICATION)
  node render.js --template templates/overview.md --output docs/project/overview.md --answers answers.json --mode update
`);
}

// Load template file
function loadTemplate(templatePath) {
  try {
    return fs.readFileSync(templatePath, 'utf8');
  } catch (error) {
    console.error(`Error loading template: ${templatePath}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Load answers JSON
function loadAnswers(answersPath) {
  try {
    const content = fs.readFileSync(answersPath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error loading answers: ${answersPath}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Load existing output file (for update mode)
function loadExisting(outputPath) {
  try {
    if (fs.existsSync(outputPath)) {
      return fs.readFileSync(outputPath, 'utf8');
    }
    return null;
  } catch (error) {
    console.error(`Error loading existing file: ${outputPath}`);
    console.error(error.message);
    return null;
  }
}

// Replace placeholders in template
function renderTemplate(template, answers, mode, existingContent) {
  let output = template;

  if (mode === 'update') {
    // Update mode: Only replace [NEEDS CLARIFICATION] tokens
    // Strategy: Use existing content as base, only fill missing values
    if (!existingContent) {
      // No existing file, fall back to default mode
      return renderTemplate(template, answers, 'default', null);
    }

    output = existingContent;

    // Replace [NEEDS CLARIFICATION] with actual values if available
    // Match patterns like:
    // - Database: [NEEDS CLARIFICATION]
    // - **Database**: [NEEDS CLARIFICATION]
    // - Tech stack: [NEEDS CLARIFICATION]

    for (const [key, value] of Object.entries(answers)) {
      if (!value || value === '[NEEDS CLARIFICATION]') {
        continue; // Skip empty or undefined values
      }

      // Pattern 1: "Key: [NEEDS CLARIFICATION]"
      const pattern1 = new RegExp(
        `(${key}:\\s*)\\[NEEDS CLARIFICATION\\]`,
        'gi'
      );
      output = output.replace(pattern1, `$1${value}`);

      // Pattern 2: "**Key**: [NEEDS CLARIFICATION]"
      const pattern2 = new RegExp(
        `(\\*\\*${key}\\*\\*:\\s*)\\[NEEDS CLARIFICATION\\]`,
        'gi'
      );
      output = output.replace(pattern2, `$1${value}`);

      // Pattern 3: "- Key: [NEEDS CLARIFICATION]"
      const pattern3 = new RegExp(
        `(-\\s*${key}:\\s*)\\[NEEDS CLARIFICATION\\]`,
        'gi'
      );
      output = output.replace(pattern3, `$1${value}`);
    }

    return output;
  }

  // Default mode: Replace all {{VARIABLE}} placeholders
  for (const [key, value] of Object.entries(answers)) {
    const placeholder = `{{${key}}}`;
    const regex = new RegExp(placeholder.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');

    // Use value or fallback to [NEEDS CLARIFICATION]
    const replacement = value || '[NEEDS CLARIFICATION]';
    output = output.replace(regex, replacement);
  }

  // Replace any remaining placeholders with [NEEDS CLARIFICATION]
  output = output.replace(/\{\{[A-Z_]+\}\}/g, '[NEEDS CLARIFICATION]');

  return output;
}

// Write output file
function writeOutput(outputPath, content) {
  try {
    // Ensure output directory exists
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(outputPath, content, 'utf8');
    console.log(`✓ Generated: ${outputPath}`);
  } catch (error) {
    console.error(`Error writing output: ${outputPath}`);
    console.error(error.message);
    process.exit(1);
  }
}

// Main execution
function main() {
  const options = parseArgs();

  // Load inputs
  const template = loadTemplate(options.template);
  const answers = loadAnswers(options.answers);
  const existing = options.mode === 'update' ? loadExisting(options.output) : null;

  // Render template
  const output = renderTemplate(template, answers, options.mode, existing);

  // Write output
  writeOutput(options.output, output);

  // Success
  process.exit(0);
}

// Run if executed directly
if (require.main === module) {
  main();
}

module.exports = { renderTemplate, loadTemplate, loadAnswers };

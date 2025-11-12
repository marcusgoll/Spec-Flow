// utils/index.js
const fs = require('fs-extra');
const path = require('path');

/**
 * Try to use Chalk if available; otherwise no-op styling.
 * Note: Chalk v5 is ESM-only. If you're on CJS, either pin chalk@4
 * or let these no-ops keep your output readable instead of crashing.
 */
let _chalk;
try {
  // Works if using chalk@4 or a CJS-friendly wrapper
  _chalk = require('chalk');
} catch {
  _chalk = null;
}
const style = (chain) => {
  if (!_chalk) return (s) => s;
  return chain.split('.').reduce((acc, k) => (acc && acc[k]) ? acc[k] : (x) => x, _chalk);
};

const sHeader = style('cyan.bold');
const sStep = style('yellow');
const sSuccess = style('green');
const sError = style('red');
const sWarn = style('yellow');

/**
 * Get package root directory
 */
function getPackageRoot() {
  return path.resolve(__dirname, '..');
}

/**
 * Create ISO timestamp for backups
 */
function getISOTimestamp() {
  const now = new Date();
  return now.toISOString().replace(/:/g, '-').replace(/\..+/, '');
}

/**
 * Should a path be excluded based on directory basenames anywhere in the path.
 * Example: excludeDirectories = ['node_modules', '.git', 'memory']
 */
function shouldExclude(srcPath, excludeDirectories = [], preserveMemory = false) {
  const parts = srcPath.split(path.sep);
  for (const name of excludeDirectories) {
    if (parts.includes(name)) return { exclude: true, reason: `${name} (user data - excluded)` };
  }
  if (preserveMemory && parts.includes('memory')) {
    return { exclude: true, reason: 'memory (preserved)' };
  }
  return { exclude: false, reason: '' };
}

/**
 * Copy directory recursively with progress and conflict strategy
 * Strategies:
 *  - 'force'  : overwrite everything
 *  - 'skip'   : never overwrite existing files
 *  - 'merge'  : create new files, do not overwrite existing files
 *
 * Notes:
 *  - 'merge' and 'skip' behave the same for files (don’t overwrite),
 *    but both will still descend into subdirectories so new files appear.
 *
 * @param {string} src
 * @param {string} dest
 * @param {Object} options
 * @param {boolean} options.preserveMemory
 * @param {string}  options.conflictStrategy
 * @param {Array<string>} options.excludeDirectories
 * @param {Function} options.onProgress
 */
async function copyDirectory(src, dest, options = {}) {
  const {
    preserveMemory = false,
    conflictStrategy = 'force',
    excludeDirectories = [],
    onProgress
  } = options;

  await fs.ensureDir(dest);
  const entries = await fs.readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    // Skip excludes and preserved memory anywhere in the path
    const { exclude, reason } = shouldExclude(srcPath, excludeDirectories, preserveMemory);
    if (exclude) {
      if (onProgress) onProgress(`Skipping ${entry.name} (${reason})`);
      continue;
    }

    if (entry.isDirectory()) {
      await copyDirectory(srcPath, destPath, options);
      continue;
    }

    // Files: decide overwrite behavior
    const exists = await fs.pathExists(destPath);
    const overwrite = conflictStrategy === 'force' ? true : false;

    if ((conflictStrategy === 'skip' || conflictStrategy === 'merge') && exists) {
      if (onProgress) onProgress(`Skipped ${entry.name} (already exists)`);
      continue;
    }

    await fs.copy(srcPath, destPath, {
      overwrite,
      errorOnExist: !overwrite,
      preserveTimestamps: true
    });

    if (onProgress) onProgress(`Copied ${entry.name}`);
  }
}

/**
 * Create backup of directory with ISO timestamp
 * @param {string} dir
 * @returns {string|null} backup path or null
 */
async function createBackup(dir) {
  if (!(await fs.pathExists(dir))) return null;

  const parent = path.dirname(dir);
  const basename = path.basename(dir);
  const timestamp = getISOTimestamp();
  const backupDir = path.join(parent, `${basename}-backup-${timestamp}`);

  // fs-extra's copy options; 'recursive' is NOT a valid option here.
  await fs.copy(dir, backupDir, { overwrite: true, preserveTimestamps: true });
  return backupDir;
}

/**
 * Restore from backup directory to target directory
 * @param {string} backupDir
 * @param {string} targetDir
 */
async function restoreBackup(backupDir, targetDir) {
  if (!(await fs.pathExists(backupDir))) {
    throw new Error(`Backup not found: ${backupDir}`);
  }
  await fs.remove(targetDir);
  await fs.copy(backupDir, targetDir, { overwrite: true, preserveTimestamps: true });
}

/**
 * Check if directory is writable
 * @param {string} dir
 * @returns {Promise<boolean>}
 */
async function isWritable(dir) {
  try {
    await fs.access(dir, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

/**
 * Format file size for display
 * @param {number} bytes
 * @returns {string}
 */
function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}

/**
 * Print styled header
 * @param {string} text
 */
function printHeader(text) {
  console.log(sHeader('\n═══════════════════════════════════════════════════════════════════'));
  console.log(sHeader(` ${text}`));
  console.log(sHeader('═══════════════════════════════════════════════════════════════════\n'));
}

/**
 * Print step message
 * @param {string} text
 */
function printStep(text) {
  console.log(sStep(`  ${text}`));
}

/**
 * Print success message
 * @param {string} text
 */
function printSuccess(text) {
  console.log(sSuccess(`✓ ${text}`));
}

/**
 * Print error message
 * @param {string} text
 */
function printError(text) {
  console.error(sError(`✗ ${text}`));
}

/**
 * Print warning message
 * @param {string} text
 */
function printWarning(text) {
  console.log(sWarn(`⚠ ${text}`));
}

module.exports = {
  getPackageRoot,
  getISOTimestamp,
  copyDirectory,
  createBackup,
  restoreBackup,
  isWritable,
  formatSize,
  printHeader,
  printStep,
  printSuccess,
  printError,
  printWarning
};

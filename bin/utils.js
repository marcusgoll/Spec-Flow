const fs = require('fs-extra');
const path = require('path');
const chalk = require('chalk');

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
 * Copy directory recursively with progress
 * @param {string} src - Source directory
 * @param {string} dest - Destination directory
 * @param {Object} options - Options
 * @param {boolean} options.preserveMemory - Whether to preserve memory files
 * @param {string} options.conflictStrategy - Conflict resolution strategy
 * @param {Array<string>} options.excludeDirectories - Directories to exclude from copying
 * @param {Function} options.onProgress - Progress callback
 */
async function copyDirectory(src, dest, options = {}) {
  const { preserveMemory = false, conflictStrategy = 'force', excludeDirectories = [], onProgress } = options;

  await fs.ensureDir(dest);
  const entries = await fs.readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    // Skip excluded directories (CRITICAL: prevents data loss)
    if (entry.isDirectory() && excludeDirectories.includes(entry.name)) {
      if (onProgress) onProgress(`Skipping ${entry.name} (user data - excluded)`);
      continue;
    }

    // Skip memory directory if preserving
    if (preserveMemory && entry.name === 'memory' && entry.isDirectory()) {
      if (onProgress) onProgress(`Skipping ${entry.name} (preserved)`);
      continue;
    }

    if (entry.isDirectory()) {
      await copyDirectory(srcPath, destPath, options);
    } else {
      // Handle file conflicts based on strategy
      const shouldCopy = conflictStrategy !== 'skip' || !await fs.pathExists(destPath);

      if (shouldCopy) {
        await fs.copy(srcPath, destPath, { overwrite: true });
        if (onProgress) onProgress(`Copied ${entry.name}`);
      } else {
        if (onProgress) onProgress(`Skipped ${entry.name} (already exists)`);
      }
    }
  }
}

/**
 * Create backup of directory with ISO timestamp
 * @param {string} dir - Directory to backup
 * @returns {string|null} Backup directory path or null if directory doesn't exist
 */
async function createBackup(dir) {
  if (!await fs.pathExists(dir)) {
    return null;
  }

  const parent = path.dirname(dir);
  const basename = path.basename(dir);
  const timestamp = getISOTimestamp();
  const backupDir = path.join(parent, `${basename}-backup-${timestamp}`);

  await fs.copy(dir, backupDir, { recursive: true });
  return backupDir;
}

/**
 * Restore from backup
 * @param {string} backupDir - Backup directory
 * @param {string} targetDir - Target directory to restore to
 */
async function restoreBackup(backupDir, targetDir) {
  if (!await fs.pathExists(backupDir)) {
    throw new Error(`Backup not found: ${backupDir}`);
  }

  await fs.remove(targetDir);
  await fs.copy(backupDir, targetDir, { recursive: true });
}

/**
 * Check if directory is writable
 * @param {string} dir - Directory path
 * @returns {boolean} True if writable
 */
async function isWritable(dir) {
  try {
    const testFile = path.join(dir, `.write-test-${Date.now()}`);
    await fs.writeFile(testFile, '');
    await fs.remove(testFile);
    return true;
  } catch {
    return false;
  }
}

/**
 * Format file size for display
 * @param {number} bytes - Size in bytes
 * @returns {string} Formatted size
 */
function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  return (bytes / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
}

/**
 * Print styled header
 * @param {string} text - Header text
 */
function printHeader(text) {
  console.log(chalk.cyan.bold('\n═══════════════════════════════════════════════════════════════════'));
  console.log(chalk.cyan.bold(` ${text}`));
  console.log(chalk.cyan.bold('═══════════════════════════════════════════════════════════════════\n'));
}

/**
 * Print step message
 * @param {string} text - Step text
 */
function printStep(text) {
  console.log(chalk.yellow(`  ${text}`));
}

/**
 * Print success message
 * @param {string} text - Success text
 */
function printSuccess(text) {
  console.log(chalk.green(`✓ ${text}`));
}

/**
 * Print error message
 * @param {string} text - Error text
 */
function printError(text) {
  console.error(chalk.red(`✗ ${text}`));
}

/**
 * Print warning message
 * @param {string} text - Warning text
 */
function printWarning(text) {
  console.log(chalk.yellow(`⚠ ${text}`));
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

const fs = require('fs-extra');
const path = require('path');
const { getISOTimestamp } = require('./utils');

/**
 * Conflict resolution strategies
 */
const STRATEGIES = {
  MERGE: 'merge',      // Smart merge for CLAUDE.md, rename others
  BACKUP: 'backup',    // Backup existing files, then overwrite
  SKIP: 'skip',        // Skip existing files, only install new
  FORCE: 'force'       // Overwrite everything (current behavior)
};

/**
 * Detect file conflicts in target directory
 * @param {string} targetDir - Target installation directory
 * @param {string[]} files - Files to check for conflicts
 * @returns {Promise<Object>} { conflicts: Array, hasConflicts: boolean }
 */
async function detectConflicts(targetDir, files) {
  const conflicts = [];

  for (const file of files) {
    const fullPath = path.join(targetDir, file);
    if (await fs.pathExists(fullPath)) {
      const stats = await fs.stat(fullPath);
      conflicts.push({
        file,
        path: fullPath,
        isDirectory: stats.isDirectory(),
        size: stats.size,
        modified: stats.mtime
      });
    }
  }

  return {
    conflicts,
    hasConflicts: conflicts.length > 0
  };
}

/**
 * Smart merge CLAUDE.md files
 * Replaces spec-flow content section if it exists, otherwise appends it
 * @param {string} existingPath - Path to existing CLAUDE.md
 * @param {string} newContent - New spec-flow CLAUDE.md content
 * @returns {Promise<string>} Merged content
 */
async function mergeCLAUDEmd(existingPath, newContent) {
  const existing = await fs.readFile(existingPath, 'utf8');

  // Markers to identify spec-flow managed content
  const startMarker = '<!-- SPEC-FLOW-START -->';
  const endMarker = '<!-- SPEC-FLOW-END -->';

  // Wrap new content with markers for future updates
  const wrappedNewContent = `${startMarker}\n## Spec-Flow Workflow\n\n${newContent.trim()}\n${endMarker}`;

  // Check if markers exist (clean update path)
  if (existing.includes(startMarker) && existing.includes(endMarker)) {
    // Replace content between markers
    const regex = new RegExp(`${startMarker}[\\s\\S]*?${endMarker}`, 'g');
    return existing.replace(regex, wrappedNewContent);
  }

  // Check for legacy spec-flow section (without markers)
  // Look for "## Spec-Flow Workflow" section and replace it
  const legacySectionRegex = /\n---\n\n## Spec-Flow Workflow\n\n[\s\S]*$/;
  if (legacySectionRegex.test(existing)) {
    // Replace legacy section with new marked content
    return existing.replace(legacySectionRegex, `\n\n---\n\n${wrappedNewContent}\n`);
  }

  // Also check for inline spec-flow content (older format)
  // This includes CLAUDE.md files that mention spec-flow but don't have the section header
  if (existing.includes('Spec-Flow') && existing.includes('/feature') && existing.includes('/epic')) {
    // This appears to be a full spec-flow CLAUDE.md (not a user file with spec-flow added)
    // Replace entirely with new content, wrapped in markers
    return wrappedNewContent;
  }

  // No existing spec-flow content, append as new section
  const separator = '\n\n---\n\n';
  const merged = existing.trimEnd() + separator + wrappedNewContent + '\n';

  return merged;
}

/**
 * Create timestamped backup of file
 * @param {string} filePath - Path to file to backup
 * @returns {Promise<string>} Path to backup file
 */
async function backupFile(filePath) {
  if (!await fs.pathExists(filePath)) {
    return null;
  }

  const dir = path.dirname(filePath);
  const ext = path.extname(filePath);
  const basename = path.basename(filePath, ext);
  const timestamp = getISOTimestamp();
  const backupPath = path.join(dir, `${basename}.backup-${timestamp}${ext}`);

  await fs.copy(filePath, backupPath);
  return backupPath;
}

/**
 * Rename file with suffix to avoid conflict
 * @param {string} sourcePath - Source file path
 * @param {string} targetPath - Original target path
 * @param {string} suffix - Suffix to add (e.g., '-spec-flow')
 * @returns {Promise<string>} New target path
 */
async function renameWithSuffix(sourcePath, targetPath, suffix = '-spec-flow') {
  const dir = path.dirname(targetPath);
  const ext = path.extname(targetPath);
  const basename = path.basename(targetPath, ext);
  const newPath = path.join(dir, `${basename}${suffix}${ext}`);

  await fs.copy(sourcePath, newPath);
  return newPath;
}

/**
 * Resolve file conflict based on strategy
 * @param {Object} options - Resolution options
 * @param {string} options.sourcePath - Source file to install
 * @param {string} options.targetPath - Target installation path
 * @param {string} options.strategy - Resolution strategy
 * @param {string} options.fileName - File name for special handling
 * @returns {Promise<Object>} { action: string, path: string, backupPath?: string }
 */
async function resolveConflict(options) {
  const { sourcePath, targetPath, strategy, fileName } = options;
  const exists = await fs.pathExists(targetPath);

  // No conflict, just copy
  if (!exists) {
    await fs.copy(sourcePath, targetPath, { overwrite: false });
    return { action: 'installed', path: targetPath };
  }

  switch (strategy) {
    case STRATEGIES.MERGE:
      // Special handling for CLAUDE.md
      if (fileName === 'CLAUDE.md') {
        const newContent = await fs.readFile(sourcePath, 'utf8');
        const merged = await mergeCLAUDEmd(targetPath, newContent);
        await fs.writeFile(targetPath, merged, 'utf8');
        return { action: 'merged', path: targetPath };
      }

      // Special handling for Gemini files - always backup and overwrite to ensure extension compatibility
      if (fileName === 'GEMINI.md' || fileName === 'gemini-extension.json') {
        const backupPath = await backupFile(targetPath);
        await fs.copy(sourcePath, targetPath, { overwrite: true });
        return { action: 'backed-up', path: targetPath, backupPath };
      }

      // For other files, rename to avoid conflict
      const renamedPath = await renameWithSuffix(sourcePath, targetPath);
      return { action: 'renamed', path: renamedPath, originalName: fileName };

    case STRATEGIES.BACKUP:
      const backupPath = await backupFile(targetPath);
      await fs.copy(sourcePath, targetPath, { overwrite: true });
      return { action: 'backed-up', path: targetPath, backupPath };

    case STRATEGIES.SKIP:
      return { action: 'skipped', path: targetPath };

    case STRATEGIES.FORCE:
      await fs.copy(sourcePath, targetPath, { overwrite: true });
      return { action: 'overwritten', path: targetPath };

    default:
      throw new Error(`Unknown conflict strategy: ${strategy}`);
  }
}

/**
 * Format conflict list for display
 * @param {Array} conflicts - Array of conflict objects
 * @returns {string} Formatted string
 */
function formatConflicts(conflicts) {
  return conflicts.map(c => {
    const type = c.isDirectory ? 'directory' : 'file';
    let desc = c.file;

    // Add context for known files
    if (c.file === 'CLAUDE.md') desc += ' (project instructions)';
    if (c.file === 'LICENSE') desc += ' (project license)';
    if (c.file === '.claude') desc += ' (existing configuration)';

    return `  • ${desc} (${type})`;
  }).join('\n');
}

/**
 * Format resolution actions for display
 * @param {Array} actions - Array of resolution action objects
 * @returns {string} Formatted string
 */
function formatActions(actions) {
  const lines = [];

  for (const action of actions) {
    switch (action.action) {
      case 'merged':
        lines.push(`  • ${path.basename(action.path)} - Appended spec-flow section`);
        break;
      case 'renamed':
        lines.push(`  • ${action.originalName} - Installed as ${path.basename(action.path)}`);
        break;
      case 'backed-up':
        lines.push(`  • ${path.basename(action.path)} - Backed up to ${path.basename(action.backupPath)}`);
        break;
      case 'skipped':
        lines.push(`  • ${path.basename(action.path)} - Skipped (already exists)`);
        break;
      case 'overwritten':
        lines.push(`  • ${path.basename(action.path)} - Overwritten`);
        break;
      case 'installed':
        lines.push(`  • ${path.basename(action.path)} - Installed`);
        break;
    }
  }

  return lines.join('\n');
}

module.exports = {
  STRATEGIES,
  detectConflicts,
  mergeCLAUDEmd,
  backupFile,
  renameWithSuffix,
  resolveConflict,
  formatConflicts,
  formatActions
};

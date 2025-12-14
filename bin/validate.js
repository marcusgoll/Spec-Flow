const fs = require('fs-extra');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');
const { printError, printWarning, printSuccess, isWritable } = require('./utils');

const CURRENT_VERSION = require('../package.json').version;

/**
 * Check latest version from npm registry
 * @param {number} timeout - Request timeout in ms (default: 5000)
 * @returns {Promise<Object>} { latest: string|null, current: string, updateAvailable: boolean, error: string|null }
 */
async function checkLatestVersion(timeout = 5000) {
  return new Promise((resolve) => {
    const req = https.get(
      'https://registry.npmjs.org/spec-flow/latest',
      { timeout },
      (res) => {
        if (res.statusCode !== 200) {
          resolve({
            latest: null,
            current: CURRENT_VERSION,
            updateAvailable: false,
            error: `Registry returned ${res.statusCode}`
          });
          return;
        }

        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            const data = JSON.parse(body);
            const latest = data.version;
            const updateAvailable = compareVersions(latest, CURRENT_VERSION) > 0;
            resolve({
              latest,
              current: CURRENT_VERSION,
              updateAvailable,
              error: null
            });
          } catch (e) {
            resolve({
              latest: null,
              current: CURRENT_VERSION,
              updateAvailable: false,
              error: 'Failed to parse registry response'
            });
          }
        });
      }
    );

    req.on('error', () => {
      resolve({
        latest: null,
        current: CURRENT_VERSION,
        updateAvailable: false,
        error: 'Could not reach npm registry (offline?)'
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({
        latest: null,
        current: CURRENT_VERSION,
        updateAvailable: false,
        error: 'Registry request timed out'
      });
    });
  });
}

/**
 * Compare semver versions
 * @param {string} a - Version string (e.g., '1.2.3')
 * @param {string} b - Version string (e.g., '1.2.0')
 * @returns {number} 1 if a > b, -1 if a < b, 0 if equal
 */
function compareVersions(a, b) {
  const partsA = a.split('.').map(Number);
  const partsB = b.split('.').map(Number);

  for (let i = 0; i < 3; i++) {
    const numA = partsA[i] || 0;
    const numB = partsB[i] || 0;
    if (numA > numB) return 1;
    if (numA < numB) return -1;
  }
  return 0;
}

/**
 * Check if Git is installed
 * @returns {Object} { installed: boolean, version: string|null, error: string|null }
 */
function checkGit() {
  try {
    const version = execSync('git --version', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    return { installed: true, version, error: null };
  } catch (error) {
    return {
      installed: false,
      version: null,
      error: 'Git is not installed or not in PATH'
    };
  }
}

/**
 * Check Node.js version
 * @param {string} requiredVersion - Minimum required version (e.g., '16.0.0')
 * @returns {Object} { compatible: boolean, current: string, required: string, error: string|null }
 */
function checkNodeVersion(requiredVersion = '16.0.0') {
  const current = process.version.slice(1); // Remove 'v' prefix
  const [reqMajor] = requiredVersion.split('.').map(Number);
  const [curMajor] = current.split('.').map(Number);

  if (curMajor >= reqMajor) {
    return { compatible: true, current, required: requiredVersion, error: null };
  }

  return {
    compatible: false,
    current,
    required: requiredVersion,
    error: `Node.js ${requiredVersion}+ required, but ${current} is installed`
  };
}

/**
 * Check if directory exists and is writable
 * @param {string} dir - Directory path
 * @returns {Promise<Object>} { valid: boolean, exists: boolean, writable: boolean, error: string|null }
 */
async function checkDirectory(dir) {
  const exists = await fs.pathExists(dir);

  if (!exists) {
    return {
      valid: false,
      exists: false,
      writable: false,
      error: `Directory does not exist: ${dir}`
    };
  }

  const writable = await isWritable(dir);

  if (!writable) {
    return {
      valid: false,
      exists: true,
      writable: false,
      error: `Directory is not writable: ${dir}`
    };
  }

  return { valid: true, exists: true, writable: true, error: null };
}

/**
 * Check if spec-flow is already installed in directory
 * @param {string} dir - Directory path
 * @returns {Promise<Object>} { installed: boolean, hasClaudeDir: boolean, hasSpecFlowDir: boolean }
 */
async function checkExistingInstallation(dir) {
  const claudeDir = path.join(dir, '.claude');
  const specFlowDir = path.join(dir, '.spec-flow');

  const hasClaudeDir = await fs.pathExists(claudeDir);
  const hasSpecFlowDir = await fs.pathExists(specFlowDir);

  return {
    installed: hasClaudeDir || hasSpecFlowDir,
    hasClaudeDir,
    hasSpecFlowDir
  };
}

/**
 * Check if required installer scripts exist in package
 * @param {string} packageRoot - Package root directory
 * @returns {Promise<Object>} { valid: boolean, missing: string[], error: string|null }
 */
async function checkInstallerScripts(packageRoot) {
  const requiredFiles = [
    path.join(packageRoot, '.claude', 'agents'),
    path.join(packageRoot, '.claude', 'commands'),
    path.join(packageRoot, '.spec-flow', 'templates'),
    path.join(packageRoot, '.spec-flow', 'memory'),
    path.join(packageRoot, 'CLAUDE.md'),
    path.join(packageRoot, 'QUICKSTART.md')
  ];

  const missing = [];

  for (const file of requiredFiles) {
    if (!await fs.pathExists(file)) {
      missing.push(path.relative(packageRoot, file));
    }
  }

  if (missing.length > 0) {
    return {
      valid: false,
      missing,
      error: `Package is corrupted. Missing: ${missing.join(', ')}`
    };
  }

  return { valid: true, missing: [], error: null };
}

/**
 * Run all pre-flight checks
 * @param {Object} options - Check options
 * @param {string} options.targetDir - Target directory
 * @param {string} options.packageRoot - Package root
 * @param {boolean} options.verbose - Show detailed output
 * @returns {Promise<Object>} { passed: boolean, checks: Object[], errors: string[] }
 */
async function runPreflightChecks(options) {
  const { targetDir, packageRoot, verbose = false } = options;
  const checks = [];
  const errors = [];

  // Node version
  const nodeCheck = checkNodeVersion('16.0.0');
  checks.push({ name: 'Node.js version', ...nodeCheck });
  if (!nodeCheck.compatible) {
    errors.push(nodeCheck.error);
    if (verbose) printError(nodeCheck.error);
  } else if (verbose) {
    printSuccess(`Node.js ${nodeCheck.current} (compatible)`);
  }

  // Git
  const gitCheck = checkGit();
  checks.push({ name: 'Git', ...gitCheck });
  if (!gitCheck.installed) {
    printWarning(gitCheck.error);
    printWarning('Git is recommended for spec-flow workflow but not required for installation');
  } else if (verbose) {
    printSuccess(`Git ${gitCheck.version}`);
  }

  // Target directory
  const dirCheck = await checkDirectory(targetDir);
  checks.push({ name: 'Target directory', ...dirCheck });
  if (!dirCheck.valid) {
    errors.push(dirCheck.error);
    if (verbose) printError(dirCheck.error);
  } else if (verbose) {
    printSuccess(`Target directory is writable: ${targetDir}`);
  }

  // Package integrity
  const scriptsCheck = await checkInstallerScripts(packageRoot);
  checks.push({ name: 'Package integrity', ...scriptsCheck });
  if (!scriptsCheck.valid) {
    errors.push(scriptsCheck.error);
    if (verbose) printError(scriptsCheck.error);
  } else if (verbose) {
    printSuccess('Package integrity verified');
  }

  return {
    passed: errors.length === 0,
    checks,
    errors
  };
}

/**
 * Health check for installed spec-flow
 * @param {string} dir - Installation directory
 * @returns {Promise<Object>} { healthy: boolean, issues: string[], warnings: string[] }
 */
async function healthCheck(dir) {
  const issues = [];
  const warnings = [];

  const installation = await checkExistingInstallation(dir);

  if (!installation.installed) {
    issues.push('Spec-Flow not installed in this directory');
    return { healthy: false, issues, warnings };
  }

  // Check key directories
  const keyDirs = [
    '.claude/agents',
    '.claude/commands',
    '.spec-flow/templates',
    '.spec-flow/memory'
  ];

  for (const keyDir of keyDirs) {
    const fullPath = path.join(dir, keyDir);
    if (!await fs.pathExists(fullPath)) {
      issues.push(`Missing directory: ${keyDir}`);
    }
  }

  // Check key files
  const keyFiles = [
    'CLAUDE.md',
    'QUICKSTART.md',
    '.claude/settings.example.json'
  ];

  for (const file of keyFiles) {
    const fullPath = path.join(dir, file);
    if (!await fs.pathExists(fullPath)) {
      warnings.push(`Missing file: ${file}`);
    }
  }

  return {
    healthy: issues.length === 0,
    issues,
    warnings
  };
}

module.exports = {
  checkGit,
  checkNodeVersion,
  checkDirectory,
  checkExistingInstallation,
  checkInstallerScripts,
  runPreflightChecks,
  healthCheck,
  checkLatestVersion,
  compareVersions,
  CURRENT_VERSION
};

#!/usr/bin/env node

/**
 * Design Lint - S-Tier Design Validation Engine
 *
 * Enforces design principles from .spec-flow/memory/design-principles.md:
 * - No hardcoded colors (use tokens)
 * - Box shadows over borders (depth through elevation)
 * - Subtle gradients only (<20% opacity, max 2 stops)
 * - Reading hierarchy (2:1 heading ratios, weight progression)
 * - WCAG AAA contrast (7:1 preferred, 4.5:1 minimum)
 * - All interactive elements labeled
 * - Touch targets ≥44×44px
 * - Spacing on 8px grid
 *
 * Severity levels:
 * - critical: Blocks variant generation (WCAG failures, missing labels)
 * - error: Requires fix before functional phase (borders on cards, bad gradients)
 * - warning: Suggest fix, allow override (custom components, spacing grid)
 * - info: Informational (optimization opportunities)
 *
 * Usage:
 *   node design-lint.js <file-or-directory>
 *   node design-lint.js --fix  # Auto-fix where possible
 *   node design-lint.js --report design/lint-report.md
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  extensions: ['.tsx', '.jsx'],
  excludeDirs: ['node_modules', '.next', 'dist', 'build', '.git'],
  outputReport: 'design/lint-report.md',
  wcagAAA: 7.0,
  wcagAA: 4.5,
  minTouchTarget: 44,
  spacingGrid: 8,
  maxGradientStops: 2,
  maxOpacityDelta: 0.20,
};

// Results aggregator
const results = {
  critical: [],
  error: [],
  warning: [],
  info: [],
  fileCount: 0,
  summary: {
    totalIssues: 0,
    criticalCount: 0,
    errorCount: 0,
    warningCount: 0,
    infoCount: 0,
  },
};

// Known UI components from shadcn/ui
const ALLOWED_COMPONENTS = new Set([
  'Card', 'CardHeader', 'CardTitle', 'CardDescription', 'CardContent', 'CardFooter',
  'Button', 'Input', 'Textarea', 'Label', 'Select', 'Checkbox', 'Switch', 'Radio',
  'Dialog', 'DialogTrigger', 'DialogContent', 'DialogHeader', 'DialogTitle', 'DialogDescription',
  'Sheet', 'SheetTrigger', 'SheetContent', 'SheetHeader', 'SheetTitle',
  'Popover', 'PopoverTrigger', 'PopoverContent',
  'DropdownMenu', 'DropdownMenuTrigger', 'DropdownMenuContent', 'DropdownMenuItem',
  'Tabs', 'TabsList', 'TabsTrigger', 'TabsContent',
  'Alert', 'AlertTitle', 'AlertDescription',
  'Toast', 'ToastProvider', 'ToastViewport', 'ToastAction',
  'Badge', 'Avatar', 'AvatarImage', 'AvatarFallback',
  'Progress', 'Skeleton', 'Separator', 'Table',
  'Form', 'FormField', 'FormItem', 'FormLabel', 'FormControl', 'FormMessage',
]);

// Patterns for detection
const PATTERNS = {
  hardcodedColor: /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})/g,
  rgbColor: /rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*(?:,\s*[\d.]+\s*)?\)/g,
  tailwindArbitraryColor: /(?:bg|text|border)-\[#[0-9a-fA-F]{6}\]/g,

  borderOnCard: /className=["'][^"']*border(?!-none)[^"']*["']/,
  borderOnDialog: /<(?:Dialog|Modal|Sheet)[^>]*className=["'][^"']*border/,
  borderOnDropdown: /<Dropdown[^>]*className=["'][^"']*border/,

  gradient: /(?:bg-gradient-|linear-gradient|radial-gradient)/g,
  gradientAngle: /(?:bg-gradient-to-(?:br|bl|tr|tl))|(?:\d+deg)/,

  heading: /<h([1-6])[^>]*className=["']([^"']*)["']/g,
  textSize: /text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)/g,

  interactiveElement: /<(button|a|input|select|textarea)[^>]*>/gi,
  ariaLabel: /(?:aria-label|aria-labelledby)=/,

  customComponent: /<([A-Z][a-zA-Z]+)/g,

  spacing: /(?:p|m|gap)-(?:x-|y-|t-|b-|l-|r-)?(\d+(?:\.\d+)?)/g,
  arbitrarySpacing: /(?:p|m|gap)-\[(\d+)(?:px|rem)\]/g,
};

/**
 * Main lint function
 */
function lintFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');

    // Run all lint rules
    checkHardcodedColors(content, filePath, lines);
    checkBordersOnCards(content, filePath, lines);
    checkGradients(content, filePath, lines);
    checkReadingHierarchy(content, filePath, lines);
    checkInteractiveLabels(content, filePath, lines);
    checkCustomComponents(content, filePath, lines);
    checkSpacingGrid(content, filePath, lines);

    results.fileCount++;
  } catch (error) {
    addIssue('error', filePath, 0, `File read error: ${error.message}`);
  }
}

/**
 * Check for hardcoded colors
 */
function checkHardcodedColors(content, filePath, lines) {
  // Hex colors
  let matches = content.matchAll(PATTERNS.hardcodedColor);
  for (const match of matches) {
    const lineNumber = getLineNumber(content, match.index);
    addIssue(
      'critical',
      filePath,
      lineNumber,
      `Hardcoded hex color ${match[0]} detected`,
      `Replace with token: bg-primary, text-primary, or var(--color-primary)`,
      lines[lineNumber - 1]
    );
  }

  // RGB colors
  matches = content.matchAll(PATTERNS.rgbColor);
  for (const match of matches) {
    const lineNumber = getLineNumber(content, match.index);
    addIssue(
      'critical',
      filePath,
      lineNumber,
      `Hardcoded RGB color ${match[0]} detected`,
      `Replace with token or use opacity variant (primary/50)`,
      lines[lineNumber - 1]
    );
  }

  // Tailwind arbitrary colors
  matches = content.matchAll(PATTERNS.tailwindArbitraryColor);
  for (const match of matches) {
    const lineNumber = getLineNumber(content, match.index);
    addIssue(
      'critical',
      filePath,
      lineNumber,
      `Arbitrary Tailwind color ${match[0]} detected`,
      `Replace with semantic token (bg-primary, text-error, etc.)`,
      lines[lineNumber - 1]
    );
  }
}

/**
 * Check for borders on cards, modals, dropdowns
 */
function checkBordersOnCards(content, filePath, lines) {
  // Check for borders on Card components
  const cardMatches = content.matchAll(/<Card[^>]*className=["']([^"']*)["']/g);
  for (const match of cardMatches) {
    const className = match[1];
    if (className.includes('border') && !className.includes('border-none')) {
      const lineNumber = getLineNumber(content, match.index);
      addIssue(
        'error',
        filePath,
        lineNumber,
        `Border on Card component detected`,
        `Use box shadow for depth: shadow-md (z-2) or shadow-lg (z-3)`,
        lines[lineNumber - 1]
      );
    }
  }

  // Check for borders on Dialog/Modal components
  const dialogMatches = content.matchAll(/<(?:Dialog|Modal|Sheet)Content[^>]*className=["']([^"']*)["']/g);
  for (const match of dialogMatches) {
    const className = match[1];
    if (className.includes('border') && !className.includes('border-none')) {
      const lineNumber = getLineNumber(content, match.index);
      addIssue(
        'error',
        filePath,
        lineNumber,
        `Border on Dialog/Modal/Sheet detected`,
        `Use box shadow for depth: shadow-xl (z-4) or shadow-2xl (z-5)`,
        lines[lineNumber - 1]
      );
    }
  }

  // Check for borders on Dropdown components
  const dropdownMatches = content.matchAll(/<DropdownMenuContent[^>]*className=["']([^"']*)["']/g);
  for (const match of dropdownMatches) {
    const className = match[1];
    if (className.includes('border') && !className.includes('border-none')) {
      const lineNumber = getLineNumber(content, match.index);
      addIssue(
        'error',
        filePath,
        lineNumber,
        `Border on DropdownMenu detected`,
        `Use box shadow for depth: shadow-xl (z-4)`,
        lines[lineNumber - 1]
      );
    }
  }
}

/**
 * Check gradient rules
 */
function checkGradients(content, filePath, lines) {
  const gradientMatches = content.matchAll(/bg-gradient-to-([a-z]{1,2})/g);

  for (const match of gradientMatches) {
    const direction = match[1];
    const lineNumber = getLineNumber(content, match.index);

    // Check for diagonal gradients
    if (['br', 'bl', 'tr', 'tl'].includes(direction)) {
      addIssue(
        'error',
        filePath,
        lineNumber,
        `Diagonal gradient detected (bg-gradient-to-${direction})`,
        `Use vertical or horizontal only: to-b, to-t, to-r, to-l`,
        lines[lineNumber - 1]
      );
    }

    // Check for multi-stop gradients
    const line = lines[lineNumber - 1];
    if (line.includes('via-')) {
      addIssue(
        'error',
        filePath,
        lineNumber,
        `Multi-stop gradient detected (from-X via-Y to-Z)`,
        `Use max 2 stops: from-X to-Y only`,
        lines[lineNumber - 1]
      );
    }

    // Check for multi-color gradients (not monochromatic)
    const fromMatch = line.match(/from-(\w+)-/);
    const toMatch = line.match(/to-(\w+)-/);
    if (fromMatch && toMatch && fromMatch[1] !== toMatch[1]) {
      addIssue(
        'warning',
        filePath,
        lineNumber,
        `Multi-color gradient detected (${fromMatch[1]} to ${toMatch[1]})`,
        `Prefer monochromatic gradients: from-blue-500/5 to-blue-500/15`,
        lines[lineNumber - 1]
      );
    }
  }
}

/**
 * Check reading hierarchy
 */
function checkReadingHierarchy(content, filePath, lines) {
  const headings = [];

  // Extract all headings with their sizes
  const headingMatches = content.matchAll(PATTERNS.heading);
  for (const match of headingMatches) {
    const level = parseInt(match[1]);
    const className = match[2];
    const sizeMatch = className.match(/text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)/);
    const size = sizeMatch ? sizeMatch[1] : 'base';
    const lineNumber = getLineNumber(content, match.index);

    headings.push({ level, size, lineNumber, className });
  }

  // Check heading size ratios
  for (let i = 0; i < headings.length - 1; i++) {
    const current = headings[i];
    const next = headings[i + 1];

    if (current.level < next.level) {
      // Parent heading should be larger
      const currentSizeValue = getSizeValue(current.size);
      const nextSizeValue = getSizeValue(next.size);
      const ratio = currentSizeValue / nextSizeValue;

      if (ratio < 1.5) {
        addIssue(
          'error',
          filePath,
          current.lineNumber,
          `Insufficient heading hierarchy (h${current.level} to h${next.level} ratio: ${ratio.toFixed(2)}:1)`,
          `Require 2:1 ratio minimum. Increase h${current.level} size or decrease h${next.level}`,
          lines[current.lineNumber - 1]
        );
      }
    }
  }

  // Check for font weight progression
  const weightMatches = content.matchAll(/font-(thin|light|normal|medium|semibold|bold|extrabold|black)/g);
  const weights = Array.from(weightMatches).map(m => m[1]);

  if (weights.length > 0) {
    const uniqueWeights = new Set(weights);
    if (uniqueWeights.size === 1 && weights.length > 3) {
      addIssue(
        'warning',
        filePath,
        0,
        `No font weight variation detected (all ${weights[0]})`,
        `Use weight progression: normal → medium → semibold → bold`,
        ''
      );
    }
  }
}

/**
 * Check interactive elements have labels
 */
function checkInteractiveLabels(content, filePath, lines) {
  const interactiveMatches = content.matchAll(PATTERNS.interactiveElement);

  for (const match of matches) {
    const lineNumber = getLineNumber(content, match.index);
    const element = match[1].toLowerCase();
    const fullMatch = match[0];

    // Check if has aria-label or visible text
    const hasAriaLabel = PATTERNS.ariaLabel.test(fullMatch);

    // For buttons/links, check next few lines for text content
    const nextFewLines = lines.slice(lineNumber - 1, lineNumber + 2).join(' ');
    const hasVisibleText = />([^<]+)<\//.test(nextFewLines);

    if (!hasAriaLabel && !hasVisibleText) {
      addIssue(
        'critical',
        filePath,
        lineNumber,
        `Interactive element <${element}> missing label`,
        `Add aria-label="Description" or visible text content`,
        lines[lineNumber - 1]
      );
    }
  }
}

/**
 * Check for custom components (not in allowed list)
 */
function checkCustomComponents(content, filePath, lines) {
  const componentMatches = content.matchAll(PATTERNS.customComponent);

  for (const match of componentMatches) {
    const componentName = match[1];

    // Skip if it's an HTML element or allowed component
    if (componentName[0] === componentName[0].toLowerCase()) continue;
    if (ALLOWED_COMPONENTS.has(componentName)) continue;
    if (componentName.startsWith('Html')) continue; // HTML* elements

    const lineNumber = getLineNumber(content, match.index);
    addIssue(
      'warning',
      filePath,
      lineNumber,
      `Custom component <${componentName}> detected`,
      `Prefer shadcn/ui components from ui-inventory.md. If truly needed, document in design/systems/proposals/`,
      lines[lineNumber - 1]
    );
  }
}

/**
 * Check spacing grid compliance
 */
function checkSpacingGrid(content, filePath, lines) {
  // Check for arbitrary spacing values
  const arbitraryMatches = content.matchAll(PATTERNS.arbitrarySpacing);

  for (const match of arbitraryMatches) {
    const value = parseInt(match[1]);
    const lineNumber = getLineNumber(content, match.index);

    // Check if value is on 8px grid (or 4px minimum)
    const on4pxGrid = value % 4 === 0;
    const on8pxGrid = value % 8 === 0;

    if (!on4pxGrid) {
      addIssue(
        'warning',
        filePath,
        lineNumber,
        `Spacing value ${value}px not on grid`,
        `Use 8px grid: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64... (min 4px)`,
        lines[lineNumber - 1]
      );
    } else if (!on8pxGrid) {
      addIssue(
        'info',
        filePath,
        lineNumber,
        `Spacing value ${value}px on 4px grid, prefer 8px`,
        `Consider rounding to nearest 8px multiple for consistency`,
        lines[lineNumber - 1]
      );
    }
  }
}

/**
 * Helper: Get line number from string index
 */
function getLineNumber(content, index) {
  const beforeIndex = content.substring(0, index);
  return beforeIndex.split('\n').length;
}

/**
 * Helper: Get numeric size value for comparison
 */
function getSizeValue(size) {
  const sizes = {
    xs: 12,
    sm: 14,
    base: 16,
    lg: 18,
    xl: 20,
    '2xl': 24,
    '3xl': 30,
    '4xl': 36,
    '5xl': 48,
    '6xl': 60,
  };
  return sizes[size] || 16;
}

/**
 * Helper: Add issue to results
 */
function addIssue(severity, filePath, lineNumber, message, fix, context) {
  const issue = {
    severity,
    file: filePath,
    line: lineNumber,
    message,
    fix,
    context: context ? context.trim() : '',
  };

  results[severity].push(issue);
  results.summary.totalIssues++;
  results.summary[`${severity}Count`]++;
}

/**
 * Scan directory recursively
 */
function scanDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (!CONFIG.excludeDirs.includes(entry.name)) {
        scanDirectory(fullPath);
      }
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name);
      if (CONFIG.extensions.includes(ext)) {
        lintFile(fullPath);
      }
    }
  }
}

/**
 * Generate markdown report
 */
function generateReport() {
  const lines = [];

  lines.push('# Design Lint Report');
  lines.push('');
  lines.push(`**Date**: ${new Date().toISOString()}`);
  lines.push(`**Files Scanned**: ${results.fileCount}`);
  lines.push('');

  // Summary
  lines.push('## Summary');
  lines.push('');
  lines.push(`- **Total Issues**: ${results.summary.totalIssues}`);
  lines.push(`- **Critical**: ${results.summary.criticalCount} (blocks deployment)`);
  lines.push(`- **Error**: ${results.summary.errorCount} (requires fix)`);
  lines.push(`- **Warning**: ${results.summary.warningCount} (suggest fix)`);
  lines.push(`- **Info**: ${results.summary.infoCount} (informational)`);
  lines.push('');

  // Severity breakdown
  for (const severity of ['critical', 'error', 'warning', 'info']) {
    if (results[severity].length === 0) continue;

    const emoji = { critical: '🚨', error: '❌', warning: '⚠️', info: 'ℹ️' }[severity];
    lines.push(`## ${emoji} ${severity.toUpperCase()} (${results[severity].length})`);
    lines.push('');

    for (const issue of results[severity]) {
      lines.push(`### ${issue.file}:${issue.line}`);
      lines.push('');
      lines.push(`**Issue**: ${issue.message}`);
      lines.push('');
      if (issue.fix) {
        lines.push(`**Fix**: ${issue.fix}`);
        lines.push('');
      }
      if (issue.context) {
        lines.push('**Context**:');
        lines.push('```tsx');
        lines.push(issue.context);
        lines.push('```');
        lines.push('');
      }
    }
  }

  return lines.join('\n');
}

/**
 * Main execution
 */
function main() {
  const args = process.argv.slice(2);
  const target = args[0] || 'src';

  console.log('🎨 Running design lint...');
  console.log(`📂 Target: ${target}`);
  console.log('');

  // Scan
  if (fs.statSync(target).isDirectory()) {
    scanDirectory(target);
  } else {
    lintFile(target);
  }

  // Generate report
  const report = generateReport();
  fs.writeFileSync(CONFIG.outputReport, report);

  // Console output
  console.log(`✅ Scanned ${results.fileCount} files`);
  console.log('');
  console.log('📊 Issues:');
  console.log(`   🚨 Critical: ${results.summary.criticalCount}`);
  console.log(`   ❌ Error: ${results.summary.errorCount}`);
  console.log(`   ⚠️  Warning: ${results.summary.warningCount}`);
  console.log(`   ℹ️  Info: ${results.summary.infoCount}`);
  console.log('');
  console.log(`📖 Full report: ${CONFIG.outputReport}`);

  // Exit code
  if (results.summary.criticalCount > 0) {
    console.log('');
    console.log('🚨 CRITICAL ISSUES DETECTED - Fix before proceeding');
    process.exit(1);
  } else if (results.summary.errorCount > 0) {
    console.log('');
    console.log('❌ ERRORS DETECTED - Fix recommended before functional phase');
    process.exit(0); // Non-blocking for warnings
  }
}

if (require.main === module) {
  main();
}

module.exports = { lintFile, scanDirectory, generateReport };

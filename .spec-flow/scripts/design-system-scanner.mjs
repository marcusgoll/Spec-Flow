#!/usr/bin/env node

/**
 * Design System Scanner - Brownfield Mode
 *
 * Scans existing tokens.css to extract:
 *   - Color palettes (primary, neutral, semantic)
 *   - Spacing scale
 *   - Typography (font families, sizes, weights)
 *   - Border radius values
 *   - Shadows
 *   - Breakpoints
 *
 * Generates consolidation report:
 *   - What matches user answers
 *   - What conflicts (WCAG violations, inconsistencies)
 *   - Migration recommendations
 *
 * Usage:
 *   node design-system-scanner.mjs --scan design/systems/tokens.css --answers brand-answers.json
 */

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { hexToOKLCH, getContrastRatio } from './init-brand-tokens.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================================
// CSS Parsing Utilities
// ============================================================================

/**
 * Parse CSS custom properties from tokens.css
 * @param {string} cssContent - tokens.css file content
 * @returns {Object} Parsed tokens organized by category
 */
function parseTokensCSS(cssContent) {
  const tokens = {
    colors: {},
    spacing: {},
    typography: {
      fontFamily: {},
      fontSize: {},
      fontWeight: {},
      lineHeight: {},
    },
    borderRadius: {},
    shadows: {},
    breakpoints: {},
  };

  // Match all CSS custom properties
  const propertyRegex = /--([a-z0-9-]+):\s*([^;]+);/g;
  let match;

  while ((match = propertyRegex.exec(cssContent)) !== null) {
    const [, name, value] = match;

    // Parse colors
    if (name.startsWith('color-')) {
      parseColorToken(name, value, tokens.colors);
    }
    // Parse spacing
    else if (name.startsWith('space-')) {
      tokens.spacing[name.replace('space-', '')] = value.trim();
    }
    // Parse typography - font families
    else if (name.startsWith('font-')) {
      const key = name.replace('font-', '');
      if (['sans', 'mono', 'serif'].includes(key)) {
        tokens.typography.fontFamily[key] = value.trim();
      } else {
        tokens.typography.fontWeight[key] = value.trim();
      }
    }
    // Parse typography - font sizes
    else if (name.startsWith('text-')) {
      tokens.typography.fontSize[name.replace('text-', '')] = value.trim();
    }
    // Parse typography - line heights
    else if (name.startsWith('leading-')) {
      tokens.typography.lineHeight[name.replace('leading-', '')] = value.trim();
    }
    // Parse border radius
    else if (name.startsWith('rounded')) {
      const key = name.replace('rounded-', '') || 'DEFAULT';
      tokens.borderRadius[key] = value.trim();
    }
    // Parse shadows
    else if (name.startsWith('shadow')) {
      const key = name.replace('shadow-', '') || 'DEFAULT';
      tokens.shadows[key] = value.trim();
    }
  }

  // Parse breakpoints from media queries
  const breakpointRegex = /@media\s*\(min-width:\s*(\d+(?:px|rem|em))\)/g;
  while ((match = breakpointRegex.exec(cssContent)) !== null) {
    const value = match[1];
    // Common breakpoint names based on size
    const px = parseFloat(value);
    if (px >= 1536) tokens.breakpoints.xxl = value;
    else if (px >= 1280) tokens.breakpoints.xl = value;
    else if (px >= 1024) tokens.breakpoints.lg = value;
    else if (px >= 768) tokens.breakpoints.md = value;
    else if (px >= 640) tokens.breakpoints.sm = value;
  }

  return tokens;
}

/**
 * Parse a color token name/value into structured format
 * @param {string} name - CSS var name (e.g., "color-primary-500")
 * @param {string} value - CSS var value (e.g., "#3b82f6")
 * @param {Object} colors - Colors object to populate
 */
function parseColorToken(name, value, colors) {
  const parts = name.split('-');
  parts.shift(); // Remove 'color'

  if (parts.length === 2) {
    // Numbered scale (e.g., primary-500)
    const [palette, level] = parts;
    if (!colors[palette]) colors[palette] = {};
    colors[palette][level] = value.trim();
  } else if (parts.length === 3) {
    // Named colors (e.g., background-primary, text-secondary)
    const [category, subcategory] = [parts[0], parts.slice(1).join('-')];
    if (!colors[category]) colors[category] = {};
    colors[category][subcategory] = value.trim();
  }
}

// ============================================================================
// Analysis Functions
// ============================================================================

/**
 * Analyze color palette for WCAG compliance
 * @param {Object} colors - Parsed colors from tokens.css
 * @returns {Object} Analysis report with violations
 */
function analyzeColorCompliance(colors) {
  const violations = [];
  const passes = [];

  // Check text colors against background
  if (colors.text && colors.background) {
    const textPrimary = colors.text.primary;
    const bgPrimary = colors.background.primary || '#ffffff';

    if (textPrimary) {
      const ratio = getContrastRatio(textPrimary, bgPrimary);
      const result = {
        color: 'text-primary',
        hex: textPrimary,
        background: bgPrimary,
        ratio: ratio.toFixed(2),
        wcagAA: ratio >= 4.5,
        wcagAAA: ratio >= 7.0,
      };

      if (ratio < 4.5) {
        violations.push(result);
      } else {
        passes.push(result);
      }
    }
  }

  // Check primary color scales for common violations
  if (colors.primary) {
    // Check if primary-500 has enough contrast on white for text use
    if (colors.primary['500']) {
      const ratio = getContrastRatio(colors.primary['500'], '#ffffff');
      const result = {
        color: 'primary-500',
        hex: colors.primary['500'],
        background: '#ffffff',
        ratio: ratio.toFixed(2),
        wcagAA: ratio >= 4.5,
        wcagAAA: ratio >= 7.0,
      };

      if (ratio < 4.5) {
        violations.push(result);
      } else {
        passes.push(result);
      }
    }
  }

  return { violations, passes };
}

/**
 * Detect spacing system pattern
 * @param {Object} spacing - Parsed spacing tokens
 * @returns {Object} Spacing analysis
 */
function analyzeSpacingSystem(spacing) {
  if (Object.keys(spacing).length === 0) {
    return { pattern: 'none', baseUnit: null };
  }

  // Extract numeric values
  const values = Object.entries(spacing)
    .filter(([key]) => !isNaN(key))
    .map(([key, value]) => ({ key: parseInt(key), value: parseFloat(value) }))
    .sort((a, b) => a.key - b.key);

  if (values.length === 0) {
    return { pattern: 'custom', baseUnit: null, values: spacing };
  }

  // Detect base unit (usually space-1)
  const baseValue = values.find(v => v.key === 1);
  const baseUnit = baseValue ? baseValue.value : null;

  // Check if it's a consistent multiplier system
  const isConsistent = values.every(v => {
    if (!baseUnit) return false;
    const expected = baseUnit * v.key;
    return Math.abs(v.value - expected) < 1; // Allow 1px tolerance
  });

  return {
    pattern: isConsistent ? 'multiplier' : 'custom',
    baseUnit,
    scale: values.map(v => ({ level: v.key, value: v.value })),
  };
}

/**
 * Analyze typography system
 * @param {Object} typography - Parsed typography tokens
 * @returns {Object} Typography analysis
 */
function analyzeTypography(typography) {
  const analysis = {
    fonts: Object.keys(typography.fontFamily),
    typeScale: Object.keys(typography.fontSize).length,
    weights: Object.keys(typography.fontWeight).length,
    lineHeights: Object.keys(typography.lineHeight).length,
  };

  // Detect type scale pattern
  const sizes = Object.entries(typography.fontSize)
    .map(([key, value]) => ({ key, value: parseFloat(value) }))
    .sort((a, b) => a.value - b.value);

  analysis.sizeRange = sizes.length > 0 ? {
    min: sizes[0],
    max: sizes[sizes.length - 1],
  } : null;

  // Detect if it follows a scale (e.g., modular scale)
  if (sizes.length >= 3) {
    const ratios = [];
    for (let i = 1; i < sizes.length; i++) {
      ratios.push(sizes[i].value / sizes[i - 1].value);
    }
    const avgRatio = ratios.reduce((a, b) => a + b, 0) / ratios.length;
    const isModular = ratios.every(r => Math.abs(r - avgRatio) < 0.1);

    analysis.scaleType = isModular ? 'modular' : 'custom';
    analysis.scaleRatio = isModular ? avgRatio.toFixed(2) : null;
  }

  return analysis;
}

/**
 * Compare scanned tokens with user answers
 * @param {Object} scanned - Scanned tokens from existing tokens.css
 * @param {Object} answers - User answers from questionnaire
 * @returns {Object} Consolidation report
 */
function consolidate(scanned, answers) {
  const report = {
    matches: [],
    conflicts: [],
    suggestions: [],
  };

  // Compare primary color
  if (answers.primaryColor && scanned.colors.primary) {
    const scannedPrimary = scanned.colors.primary['500'] || Object.values(scanned.colors.primary)[0];
    if (scannedPrimary !== answers.primaryColor) {
      report.conflicts.push({
        category: 'Color',
        field: 'Primary Color',
        existing: scannedPrimary,
        requested: answers.primaryColor,
        recommendation: 'Keep existing or migrate to new primary color (breaking change)',
      });
    } else {
      report.matches.push({
        category: 'Color',
        field: 'Primary Color',
        value: scannedPrimary,
      });
    }
  }

  // Compare spacing system
  const spacingAnalysis = analyzeSpacingSystem(scanned.spacing);
  if (answers.densityPreference && spacingAnalysis.baseUnit) {
    const expectedBase = answers.densityPreference === 'compact' ? 4 :
                         answers.densityPreference === 'spacious' ? 8 : 6;

    if (Math.abs(spacingAnalysis.baseUnit - expectedBase) > 1) {
      report.conflicts.push({
        category: 'Spacing',
        field: 'Base Unit',
        existing: `${spacingAnalysis.baseUnit}px`,
        requested: `${expectedBase}px`,
        recommendation: 'Adjust spacing scale or update density preference',
      });
    } else {
      report.matches.push({
        category: 'Spacing',
        field: 'Base Unit',
        value: `${spacingAnalysis.baseUnit}px`,
      });
    }
  }

  // Typography comparison
  if (answers.typographyStyle && scanned.typography.fontFamily.sans) {
    const existingFont = scanned.typography.fontFamily.sans.split(',')[0].replace(/['"]/g, '').trim();
    const expectedFonts = {
      geometric: ['Inter', 'SF Pro', 'Montserrat'],
      humanist: ['Open Sans', 'Nunito', 'Lato'],
      monospace: ['Fira Code', 'Consolas', 'JetBrains Mono'],
    };

    const matches = expectedFonts[answers.typographyStyle]?.some(font =>
      existingFont.includes(font)
    );

    if (!matches) {
      report.conflicts.push({
        category: 'Typography',
        field: 'Font Family',
        existing: existingFont,
        requested: expectedFonts[answers.typographyStyle]?.[0] || 'Unknown',
        recommendation: 'Keep existing font or migrate (requires font loading changes)',
      });
    } else {
      report.matches.push({
        category: 'Typography',
        field: 'Font Family',
        value: existingFont,
      });
    }
  }

  return report;
}

// ============================================================================
// Report Generation
// ============================================================================

/**
 * Generate human-readable consolidation report
 * @param {Object} scanned - Scanned tokens
 * @param {Object} answers - User answers
 * @param {Object} analysis - Color compliance analysis
 * @returns {string} Markdown report
 */
function generateReport(scanned, answers, analysis) {
  const consolidation = consolidate(scanned, answers);

  let report = `# Design System Scan Report\n\n`;
  report += `**Generated**: ${new Date().toISOString()}\n\n`;
  report += `---\n\n`;

  // Summary
  report += `## Summary\n\n`;
  report += `- **Tokens Found**: ${countTokens(scanned)}\n`;
  report += `- **WCAG Violations**: ${analysis.violations.length}\n`;
  report += `- **Matches with Answers**: ${consolidation.matches.length}\n`;
  report += `- **Conflicts with Answers**: ${consolidation.conflicts.length}\n\n`;

  // Color Palettes
  report += `## Color Palettes\n\n`;
  for (const [name, colors] of Object.entries(scanned.colors)) {
    if (typeof colors === 'object' && Object.keys(colors).length > 0) {
      report += `### ${name.charAt(0).toUpperCase() + name.slice(1)}\n\n`;
      for (const [level, hex] of Object.entries(colors)) {
        report += `- \`${level}\`: ${hex}\n`;
      }
      report += `\n`;
    }
  }

  // WCAG Compliance
  if (analysis.violations.length > 0) {
    report += `## ⚠️  WCAG Violations\n\n`;
    analysis.violations.forEach(v => {
      report += `- **${v.color}**: ${v.hex} on ${v.background} = ${v.ratio}:1 ❌ (needs ≥4.5:1)\n`;
    });
    report += `\n`;
  }

  if (analysis.passes.length > 0) {
    report += `## ✅ WCAG Passes\n\n`;
    analysis.passes.forEach(p => {
      report += `- **${p.color}**: ${p.hex} on ${p.background} = ${p.ratio}:1\n`;
    });
    report += `\n`;
  }

  // Spacing System
  const spacingAnalysis = analyzeSpacingSystem(scanned.spacing);
  report += `## Spacing System\n\n`;
  report += `- **Pattern**: ${spacingAnalysis.pattern}\n`;
  if (spacingAnalysis.baseUnit) {
    report += `- **Base Unit**: ${spacingAnalysis.baseUnit}px\n`;
  }
  if (spacingAnalysis.scale) {
    report += `- **Scale**: ${spacingAnalysis.scale.map(s => `${s.level}=${s.value}px`).join(', ')}\n`;
  }
  report += `\n`;

  // Typography
  const typoAnalysis = analyzeTypography(scanned.typography);
  report += `## Typography\n\n`;
  report += `- **Font Families**: ${typoAnalysis.fonts.join(', ')}\n`;
  report += `- **Type Scale**: ${typoAnalysis.typeScale} sizes\n`;
  if (typoAnalysis.scaleType) {
    report += `- **Scale Type**: ${typoAnalysis.scaleType}\n`;
    if (typoAnalysis.scaleRatio) {
      report += `- **Scale Ratio**: ${typoAnalysis.scaleRatio}\n`;
    }
  }
  report += `\n`;

  // Consolidation Report
  if (consolidation.matches.length > 0) {
    report += `## ✅ Matches with User Answers\n\n`;
    consolidation.matches.forEach(m => {
      report += `- **${m.category} / ${m.field}**: ${m.value}\n`;
    });
    report += `\n`;
  }

  if (consolidation.conflicts.length > 0) {
    report += `## ⚠️  Conflicts with User Answers\n\n`;
    consolidation.conflicts.forEach(c => {
      report += `### ${c.category}: ${c.field}\n\n`;
      report += `- **Existing**: ${c.existing}\n`;
      report += `- **Requested**: ${c.requested}\n`;
      report += `- **Recommendation**: ${c.recommendation}\n\n`;
    });
  }

  // Suggestions
  report += `## 💡 Suggestions\n\n`;
  if (analysis.violations.length > 0) {
    report += `- **WCAG Fixes**: Run \`init-brand-tokens.mjs\` with \`--auto-fix-contrast\` to automatically adjust colors.\n`;
  }
  if (consolidation.conflicts.length > 0) {
    report += `- **Resolve Conflicts**: Review conflicts above and decide whether to keep existing or migrate to new values.\n`;
  }
  report += `- **Migration Plan**: If redesigning, create a migration plan in \`docs/design/migration-plan.md\`.\n`;

  return report;
}

/**
 * Count total tokens across all categories
 * @param {Object} scanned - Scanned tokens
 * @returns {number} Total count
 */
function countTokens(scanned) {
  let count = 0;

  for (const category of Object.values(scanned)) {
    if (typeof category === 'object') {
      for (const value of Object.values(category)) {
        if (typeof value === 'object') {
          count += Object.keys(value).length;
        } else {
          count++;
        }
      }
    }
  }

  return count;
}

// ============================================================================
// Main Orchestrator
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  const scanPath = args.includes('--scan') ? args[args.indexOf('--scan') + 1] : 'design/systems/tokens.css';
  const answersPath = args.includes('--answers') ? args[args.indexOf('--answers') + 1] : null;

  console.log('🔍 Design System Scanner (Brownfield Mode)');
  console.log(`Scanning: ${scanPath}\n`);

  // Read existing tokens.css
  let cssContent;
  try {
    cssContent = await fs.readFile(scanPath, 'utf-8');
  } catch (error) {
    console.error(`❌ Failed to read tokens.css: ${error.message}`);
    process.exit(1);
  }

  // Parse tokens
  const scanned = parseTokensCSS(cssContent);

  // Analyze WCAG compliance
  const analysis = analyzeColorCompliance(scanned.colors);

  // Load user answers if provided
  let answers = {};
  if (answersPath) {
    try {
      const answersContent = await fs.readFile(answersPath, 'utf-8');
      answers = JSON.parse(answersContent);
      console.log(`✅ Loaded answers from: ${answersPath}\n`);
    } catch (error) {
      console.log(`⚠️  No answers file provided, skipping consolidation\n`);
    }
  }

  // Generate report
  const report = generateReport(scanned, answers, analysis);

  // Write report
  const reportPath = path.join(process.cwd(), 'design', 'scan-report.md');
  await fs.mkdir(path.dirname(reportPath), { recursive: true });
  await fs.writeFile(reportPath, report);

  console.log(`✅ Scan complete: ${reportPath}\n`);

  // Summary
  console.log('📊 Summary:');
  console.log(`  Tokens: ${countTokens(scanned)}`);
  console.log(`  WCAG Violations: ${analysis.violations.length}`);
  console.log(`  WCAG Passes: ${analysis.passes.length}`);

  if (answersPath) {
    const consolidation = consolidate(scanned, answers);
    console.log(`  Matches: ${consolidation.matches.length}`);
    console.log(`  Conflicts: ${consolidation.conflicts.length}`);
  }

  // Exit with error if violations found
  if (analysis.violations.length > 0) {
    console.log('\n⚠️  WCAG violations detected. Review scan-report.md for details.');
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { parseTokensCSS, analyzeColorCompliance, analyzeSpacingSystem, analyzeTypography, consolidate };

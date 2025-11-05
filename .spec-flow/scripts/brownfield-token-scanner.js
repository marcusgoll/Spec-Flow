#!/usr/bin/env node

/**
 * Brownfield Token Scanner
 *
 * Scans an existing codebase to detect color, typography, and spacing patterns.
 * Generates a report with:
 * - Frequency analysis of all detected values
 * - Consolidation suggestions (reduce 47 colors → 12 tokens)
 * - Proposed token structure based on detected patterns
 *
 * Usage:
 *   node brownfield-token-scanner.js [projectRoot]
 *   node brownfield-token-scanner.js --output detected-tokens.json
 */

const fs = require('fs');
const path = require('path');
const Color = require('colorjs.io').default;

// Configuration
const CONFIG = {
  extensions: ['.tsx', '.jsx', '.ts', '.js', '.css', '.scss', '.sass'],
  excludeDirs: ['node_modules', '.next', 'dist', 'build', '.git', 'coverage'],
  outputFile: 'design/systems/detected-tokens.json',
  reportFile: 'design/systems/token-analysis-report.md',
};

// Regex patterns for detection
const PATTERNS = {
  // Colors
  hex: /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/g,
  rgb: /rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)/g,
  hsl: /hsla?\(\s*([\d.]+)\s*,\s*([\d.]+)%?\s*,\s*([\d.]+)%?\s*(?:,\s*([\d.]+)\s*)?\)/g,
  tailwindColor: /(?:bg|text|border|ring|from|to|via)-(\w+)-(\d{2,3})/g,

  // Typography
  fontFamily: /font-family:\s*([^;}"]+)/g,
  fontSize: /(?:font-size|text-)(\d+(?:px|rem|em|pt))/g,
  fontWeight: /(?:font-weight|font-)(\d{3}|(?:thin|light|normal|medium|semibold|bold|extrabold|black))/g,
  lineHeight: /line-height:\s*([\d.]+(?:px|rem|em)?)/g,

  // Spacing
  spacing: /(?:padding|margin|gap|space)-(?:x-|y-|t-|b-|l-|r-)?(\d+(?:px|rem|em)?)/g,
  tailwindSpacing: /(?:p|m|gap|space)-(?:x-|y-|t-|b-|l-|r-)?(\d+(?:\.\d+)?)/g,
};

// OKLCH Conversion Functions

/**
 * Convert hex color to OKLCH with sRGB fallback
 * @param {string} hex - Hex color code (e.g., "#3b82f6")
 * @returns {Object|null} { oklch, fallback, l, c, h }
 */
function hexToOklch(hex) {
  try {
    const color = new Color(hex);
    const oklch = color.to('oklch');

    // Handle out-of-gamut colors by clamping chroma
    const { l, c, h } = clampToSrgb(oklch.l, oklch.c, oklch.h);

    return {
      oklch: `oklch(${l.toFixed(2)}% ${c.toFixed(3)} ${h.toFixed(2)})`,
      fallback: hex.toUpperCase(),
      l: parseFloat(l.toFixed(2)),
      c: parseFloat(c.toFixed(3)),
      h: parseFloat(h.toFixed(2))
    };
  } catch (error) {
    console.error(`Error converting ${hex} to OKLCH:`, error.message);
    return null;
  }
}

/**
 * Convert RGB color to OKLCH with sRGB fallback
 * @param {number} r - Red (0-255)
 * @param {number} g - Green (0-255)
 * @param {number} b - Blue (0-255)
 * @param {number} a - Alpha (0-1, optional)
 * @returns {Object|null} { oklch, fallback, l, c, h, alpha }
 */
function rgbToOklch(r, g, b, a = 1) {
  try {
    const hex = rgbToHex(r, g, b);
    const result = hexToOklch(hex);

    if (!result) return null;

    return {
      ...result,
      alpha: a,
      oklch: a < 1
        ? `oklch(${result.l.toFixed(2)}% ${result.c.toFixed(3)} ${result.h.toFixed(2)} / ${a})`
        : result.oklch
    };
  } catch (error) {
    console.error(`Error converting rgb(${r}, ${g}, ${b}) to OKLCH:`, error.message);
    return null;
  }
}

/**
 * Convert RGB values to hex
 * @param {number} r - Red (0-255)
 * @param {number} g - Green (0-255)
 * @param {number} b - Blue (0-255)
 * @returns {string} Hex color code
 */
function rgbToHex(r, g, b) {
  return '#' + [r, g, b].map(x => {
    const hex = x.toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  }).join('');
}

/**
 * Calculate WCAG contrast ratio between two colors
 * @param {string} color1 - First color (hex, rgb, or oklch)
 * @param {string} color2 - Second color (hex, rgb, or oklch)
 * @returns {Object|null} { ratio, passAA, passAAA, level }
 */
function calculateContrast(color1, color2) {
  try {
    const c1 = new Color(color1);
    const c2 = new Color(color2);
    const ratio = Math.abs(c1.contrast(c2, 'WCAG21'));

    return {
      ratio: parseFloat(ratio.toFixed(2)),
      passAA: ratio >= 4.5,
      passAAA: ratio >= 7.0,
      level: ratio >= 7.0 ? 'AAA' : ratio >= 4.5 ? 'AA' : 'FAIL'
    };
  } catch (error) {
    console.error(`Error calculating contrast between ${color1} and ${color2}:`, error.message);
    return null;
  }
}

/**
 * Check if OKLCH color is within sRGB gamut
 * @param {Object} oklch - OKLCH color object from colorjs.io
 * @returns {boolean} True if in sRGB gamut
 */
function isInSrgbGamut(oklch) {
  try {
    const color = new Color('oklch', [oklch.l, oklch.c, oklch.h]);
    return color.inGamut('srgb');
  } catch (error) {
    return false;
  }
}

/**
 * Clamp OKLCH color to sRGB gamut by reducing chroma
 * @param {number} l - Lightness (0-100)
 * @param {number} c - Chroma (0-0.4+)
 * @param {number} h - Hue (0-360)
 * @returns {Object} { l, c, h } - Clamped values
 */
function clampToSrgb(l, c, h) {
  let color = new Color('oklch', [l, c, h]);

  // If already in gamut, return as-is
  if (color.inGamut('srgb')) {
    return { l, c, h };
  }

  // Reduce chroma until in gamut (max 100 iterations)
  let iterations = 0;
  while (!color.inGamut('srgb') && c > 0 && iterations < 100) {
    c -= 0.001;
    color = new Color('oklch', [l, c, h]);
    iterations++;
  }

  return { l, c: Math.max(0, c), h };
}

/**
 * Normalize hex color (handle 3-digit shorthand)
 * @param {string} hex - Hex color code
 * @returns {string} Normalized 6-digit hex code
 */
function normalizeHex(hex) {
  // Remove # if present
  hex = hex.replace('#', '');

  // Expand 3-digit hex to 6-digit
  if (hex.length === 3) {
    hex = hex.split('').map(char => char + char).join('');
  }

  return '#' + hex.toUpperCase();
}

// Scan results
const results = {
  colors: {},
  typography: {
    families: {},
    sizes: {},
    weights: {},
    lineHeights: {},
  },
  spacing: {},
  fileCount: 0,
  errors: [],
};

/**
 * Scan a directory recursively
 */
function scanDirectory(dir, rootDir) {
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        // Skip excluded directories
        if (!CONFIG.excludeDirs.includes(entry.name)) {
          scanDirectory(fullPath, rootDir);
        }
      } else if (entry.isFile()) {
        // Check if file has valid extension
        const ext = path.extname(entry.name);
        if (CONFIG.extensions.includes(ext)) {
          scanFile(fullPath, rootDir);
        }
      }
    }
  } catch (error) {
    results.errors.push(`Error scanning ${dir}: ${error.message}`);
  }
}

/**
 * Scan a single file for design tokens
 */
function scanFile(filePath, rootDir) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const relativePath = path.relative(rootDir, filePath);

    // Detect colors
    detectColors(content, relativePath);

    // Detect typography
    detectTypography(content, relativePath);

    // Detect spacing
    detectSpacing(content, relativePath);

    results.fileCount++;
  } catch (error) {
    results.errors.push(`Error reading ${filePath}: ${error.message}`);
  }
}

/**
 * Detect colors in content
 */
function detectColors(content, filePath) {
  // Hex colors
  let matches = content.matchAll(PATTERNS.hex);
  for (const match of matches) {
    const color = match[0].toLowerCase();
    incrementCount(results.colors, color, filePath);
  }

  // RGB/RGBA colors
  matches = content.matchAll(PATTERNS.rgb);
  for (const match of matches) {
    const [, r, g, b, a] = match;
    const color = a ? `rgba(${r}, ${g}, ${b}, ${a})` : `rgb(${r}, ${g}, ${b})`;
    incrementCount(results.colors, color, filePath);
  }

  // HSL/HSLA colors
  matches = content.matchAll(PATTERNS.hsl);
  for (const match of matches) {
    const [, h, s, l, a] = match;
    const color = a ? `hsla(${h}, ${s}%, ${l}%, ${a})` : `hsl(${h}, ${s}%, ${l}%)`;
    incrementCount(results.colors, color, filePath);
  }

  // Tailwind colors
  matches = content.matchAll(PATTERNS.tailwindColor);
  for (const match of matches) {
    const [, colorName, shade] = match;
    const color = `${colorName}-${shade}`;
    incrementCount(results.colors, color, filePath);
  }
}

/**
 * Detect typography patterns
 */
function detectTypography(content, filePath) {
  // Font families
  let matches = content.matchAll(PATTERNS.fontFamily);
  for (const match of matches) {
    const family = match[1].trim().replace(/['"]/g, '');
    incrementCount(results.typography.families, family, filePath);
  }

  // Font sizes
  matches = content.matchAll(PATTERNS.fontSize);
  for (const match of matches) {
    const size = match[1];
    incrementCount(results.typography.sizes, size, filePath);
  }

  // Font weights
  matches = content.matchAll(PATTERNS.fontWeight);
  for (const match of matches) {
    const weight = match[1];
    incrementCount(results.typography.weights, weight, filePath);
  }

  // Line heights
  matches = content.matchAll(PATTERNS.lineHeight);
  for (const match of matches) {
    const lineHeight = match[1];
    incrementCount(results.typography.lineHeights, lineHeight, filePath);
  }
}

/**
 * Detect spacing patterns
 */
function detectSpacing(content, filePath) {
  // CSS spacing
  let matches = content.matchAll(PATTERNS.spacing);
  for (const match of matches) {
    const value = match[1];
    incrementCount(results.spacing, value, filePath);
  }

  // Tailwind spacing
  matches = content.matchAll(PATTERNS.tailwindSpacing);
  for (const match of matches) {
    const value = match[1];
    incrementCount(results.spacing, value, filePath);
  }
}

/**
 * Increment count for a detected value
 */
function incrementCount(collection, value, filePath) {
  if (!collection[value]) {
    collection[value] = {
      count: 0,
      files: [],
    };
  }

  collection[value].count++;

  // Only store first 3 file references to save memory
  if (collection[value].files.length < 3) {
    if (!collection[value].files.includes(filePath)) {
      collection[value].files.push(filePath);
    }
  }
}

/**
 * Analyze results and generate consolidation suggestions
 */
function analyzeResults() {
  const analysis = {
    summary: {
      totalFiles: results.fileCount,
      uniqueColors: Object.keys(results.colors).length,
      uniqueFontSizes: Object.keys(results.typography.sizes).length,
      uniqueSpacingValues: Object.keys(results.spacing).length,
    },
    colors: analyzeColors(),
    typography: analyzeTypography(),
    spacing: analyzeSpacing(),
    suggestions: generateSuggestions(),
  };

  return analysis;
}

/**
 * Analyze color patterns and convert to OKLCH
 */
function analyzeColors() {
  const sortedColors = Object.entries(results.colors)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 30); // Top 30 colors

  return sortedColors.map(([color, data]) => {
    // Normalize hex colors
    const normalizedColor = color.startsWith('#') ? normalizeHex(color) : color;

    // Convert to OKLCH
    let oklchData = null;
    if (normalizedColor.startsWith('#')) {
      oklchData = hexToOklch(normalizedColor);
    }

    return {
      value: color,
      normalized: normalizedColor,
      count: data.count,
      files: data.files,
      ...(oklchData && {
        oklch: oklchData.oklch,
        fallback: oklchData.fallback,
        l: oklchData.l,
        c: oklchData.c,
        h: oklchData.h
      })
    };
  });
}

/**
 * Analyze typography patterns
 */
function analyzeTypography() {
  return {
    families: sortByCount(results.typography.families).slice(0, 10),
    sizes: sortByCount(results.typography.sizes).slice(0, 20),
    weights: sortByCount(results.typography.weights).slice(0, 10),
    lineHeights: sortByCount(results.typography.lineHeights).slice(0, 15),
  };
}

/**
 * Analyze spacing patterns
 */
function analyzeSpacing() {
  return sortByCount(results.spacing).slice(0, 30);
}

/**
 * Sort object by count
 */
function sortByCount(obj) {
  return Object.entries(obj)
    .sort((a, b) => b[1].count - a[1].count)
    .map(([value, data]) => ({
      value,
      count: data.count,
      files: data.files,
    }));
}

/**
 * Generate consolidation suggestions
 */
function generateSuggestions() {
  const suggestions = [];

  // Color consolidation
  const colorCount = Object.keys(results.colors).length;
  if (colorCount > 12) {
    suggestions.push({
      type: 'colors',
      message: `Found ${colorCount} unique colors. Recommend consolidating to 12 tokens:`,
      details: [
        '- 5 semantic colors (primary, secondary, accent, success, error, warning, info)',
        '- 7 neutral shades (50, 100, 200, 400, 600, 800, 950)',
        '- Use opacity variants (primary/10, primary/50) instead of separate colors',
      ],
    });
  }

  // Font size consolidation
  const sizeCount = Object.keys(results.typography.sizes).length;
  if (sizeCount > 10) {
    suggestions.push({
      type: 'typography',
      message: `Found ${sizeCount} unique font sizes. Recommend type scale (6-8 sizes):`,
      details: [
        '- xs: 12px, sm: 14px, base: 16px, lg: 18px, xl: 20px, 2xl: 24px, 3xl: 30px, 4xl: 36px',
        '- Use system scale (1.25x multiplier)',
      ],
    });
  }

  // Spacing consolidation
  const spacingCount = Object.keys(results.spacing).length;
  if (spacingCount > 15) {
    suggestions.push({
      type: 'spacing',
      message: `Found ${spacingCount} unique spacing values. Recommend 8px grid:`,
      details: [
        '- Base: 0, 1 (4px), 2 (8px), 3 (12px), 4 (16px), 5 (20px), 6 (24px)',
        '- Extended: 8 (32px), 10 (40px), 12 (48px), 16 (64px), 20 (80px), 24 (96px)',
      ],
    });
  }

  return suggestions;
}

/**
 * Generate markdown report
 */
function generateMarkdownReport(analysis) {
  const lines = [];

  lines.push('# Token Analysis Report');
  lines.push('');
  lines.push(`**Scan Date**: ${new Date().toISOString()}`);
  lines.push(`**Files Scanned**: ${analysis.summary.totalFiles}`);
  lines.push('');

  // Summary
  lines.push('## Summary');
  lines.push('');
  lines.push(`- **Unique Colors**: ${analysis.summary.uniqueColors}`);
  lines.push(`- **Unique Font Sizes**: ${analysis.summary.uniqueFontSizes}`);
  lines.push(`- **Unique Spacing Values**: ${analysis.summary.uniqueSpacingValues}`);
  lines.push('');

  // Suggestions
  if (analysis.suggestions.length > 0) {
    lines.push('## Consolidation Suggestions');
    lines.push('');
    for (const suggestion of analysis.suggestions) {
      lines.push(`### ${suggestion.type}`);
      lines.push('');
      lines.push(suggestion.message);
      lines.push('');
      for (const detail of suggestion.details) {
        lines.push(detail);
      }
      lines.push('');
    }
  }

  // Colors
  lines.push('## Detected Colors (Top 30)');
  lines.push('');
  lines.push('| Color | Count | Example Files |');
  lines.push('|-------|-------|--------------|');
  for (const color of analysis.colors) {
    const files = color.files.slice(0, 2).join(', ');
    lines.push(`| \`${color.value}\` | ${color.count} | ${files} |`);
  }
  lines.push('');

  // Typography
  lines.push('## Typography Patterns');
  lines.push('');

  lines.push('### Font Families');
  lines.push('');
  lines.push('| Family | Count |');
  lines.push('|--------|-------|');
  for (const family of analysis.typography.families) {
    lines.push(`| ${family.value} | ${family.count} |`);
  }
  lines.push('');

  lines.push('### Font Sizes');
  lines.push('');
  lines.push('| Size | Count |');
  lines.push('|------|-------|');
  for (const size of analysis.typography.sizes) {
    lines.push(`| ${size.value} | ${size.count} |`);
  }
  lines.push('');

  lines.push('### Font Weights');
  lines.push('');
  lines.push('| Weight | Count |');
  lines.push('|--------|-------|');
  for (const weight of analysis.typography.weights) {
    lines.push(`| ${weight.value} | ${weight.count} |`);
  }
  lines.push('');

  // Spacing
  lines.push('## Spacing Patterns (Top 30)');
  lines.push('');
  lines.push('| Value | Count |');
  lines.push('|-------|-------|');
  for (const spacing of analysis.spacing) {
    lines.push(`| ${spacing.value} | ${spacing.count} |`);
  }
  lines.push('');

  // Errors
  if (results.errors.length > 0) {
    lines.push('## Errors');
    lines.push('');
    for (const error of results.errors) {
      lines.push(`- ${error}`);
    }
    lines.push('');
  }

  return lines.join('\n');
}

/**
 * Generate proposed token structure with OKLCH colors
 */
function generateProposedTokens(analysis) {
  // Extract most common colors and suggest semantic mapping
  const topColors = analysis.colors.slice(0, 12);

  // Helper function to create OKLCH token
  const createColorToken = (hex, description) => {
    const oklchData = hexToOklch(hex);
    return oklchData ? {
      oklch: oklchData.oklch,
      fallback: oklchData.fallback,
      description
    } : {
      oklch: `oklch(59.69% 0.156 261.45)`, // Default blue
      fallback: hex,
      description
    };
  };

  return {
    meta: {
      name: "Detected Tokens",
      version: "2.0.0",
      description: "Auto-detected tokens from codebase scan - OKLCH format",
      generated: new Date().toISOString(),
      colorSpace: "oklch",
      fallbackSpace: "srgb"
    },
    colors: {
      brand: {
        primary: topColors[0]?.oklch ? {
          oklch: topColors[0].oklch,
          fallback: topColors[0].fallback,
          description: "Most common color in codebase"
        } : createColorToken('#3b82f6', 'Default primary'),
        secondary: topColors[1]?.oklch ? {
          oklch: topColors[1].oklch,
          fallback: topColors[1].fallback,
          description: "Second most common color"
        } : createColorToken('#8b5cf6', 'Default secondary'),
        accent: topColors[2]?.oklch ? {
          oklch: topColors[2].oklch,
          fallback: topColors[2].fallback,
          description: "Third most common color"
        } : createColorToken('#10b981', 'Default accent'),
      },
      semantic: {
        success: createColorToken('#10b981', 'Success state'),
        error: createColorToken('#ef4444', 'Error state'),
        warning: createColorToken('#f59e0b', 'Warning state'),
        info: createColorToken('#3b82f6', 'Info state'),
      },
      neutral: {
        50: createColorToken('#fafafa', 'Lightest neutral'),
        100: createColorToken('#f5f5f5', 'Light neutral'),
        200: createColorToken('#e5e5e5', 'Light neutral'),
        400: createColorToken('#a3a3a3', 'Medium neutral'),
        600: createColorToken('#525252', 'Dark neutral'),
        800: createColorToken('#262626', 'Darker neutral'),
        950: createColorToken('#0a0a0a', 'Darkest neutral'),
      },
    },
    typography: {
      families: {
        sans: analysis.typography.families[0]?.value || 'Inter, system-ui, sans-serif',
        mono: 'Fira Code, Consolas, monospace',
      },
      sizes: {
        xs: '0.75rem',   // 12px
        sm: '0.875rem',  // 14px
        base: '1rem',    // 16px
        lg: '1.125rem',  // 18px
        xl: '1.25rem',   // 20px
        '2xl': '1.5rem', // 24px
        '3xl': '1.875rem', // 30px
        '4xl': '2.25rem',  // 36px
      },
      weights: {
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
      },
    },
    spacing: {
      0: '0',
      1: '0.25rem',  // 4px
      2: '0.5rem',   // 8px
      3: '0.75rem',  // 12px
      4: '1rem',     // 16px
      5: '1.25rem',  // 20px
      6: '1.5rem',   // 24px
      8: '2rem',     // 32px
      10: '2.5rem',  // 40px
      12: '3rem',    // 48px
      16: '4rem',    // 64px
      20: '5rem',    // 80px
      24: '6rem',    // 96px
    },
    shadows: {
      sm: '0 1px 2px rgba(0, 0, 0, 0.05)',
      md: '0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)',
      lg: '0 10px 15px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.08)',
      xl: '0 20px 25px rgba(0, 0, 0, 0.12), 0 10px 10px rgba(0, 0, 0, 0.08)',
      '2xl': '0 25px 50px rgba(0, 0, 0, 0.15), 0 12px 20px rgba(0, 0, 0, 0.12)',
    },
  };
}

/**
 * Main execution
 */
function main() {
  const args = process.argv.slice(2);
  const projectRoot = args[0] || process.cwd();

  console.log('🔍 Scanning codebase for design tokens...');
  console.log(`📂 Project root: ${projectRoot}`);
  console.log('');

  // Scan the project
  scanDirectory(projectRoot, projectRoot);

  console.log(`✅ Scanned ${results.fileCount} files`);
  console.log('');

  // Analyze results
  console.log('📊 Analyzing patterns...');
  const analysis = analyzeResults();

  // Generate outputs
  const proposedTokens = generateProposedTokens(analysis);
  const report = generateMarkdownReport(analysis);

  // Ensure output directory exists
  const designDir = path.join(projectRoot, 'design', 'systems');
  if (!fs.existsSync(designDir)) {
    fs.mkdirSync(designDir, { recursive: true });
  }

  // Write detected tokens
  const tokensPath = path.join(projectRoot, CONFIG.outputFile);
  fs.writeFileSync(tokensPath, JSON.stringify(proposedTokens, null, 2));
  console.log(`✅ Generated: ${CONFIG.outputFile}`);

  // Write analysis report
  const reportPath = path.join(projectRoot, CONFIG.reportFile);
  fs.writeFileSync(reportPath, report);
  console.log(`✅ Generated: ${CONFIG.reportFile}`);

  // Print summary
  console.log('');
  console.log('📈 Summary:');
  console.log(`   - Unique colors: ${analysis.summary.uniqueColors}`);
  console.log(`   - Unique font sizes: ${analysis.summary.uniqueFontSizes}`);
  console.log(`   - Unique spacing values: ${analysis.summary.uniqueSpacingValues}`);

  if (analysis.suggestions.length > 0) {
    console.log('');
    console.log('💡 Recommendations:');
    for (const suggestion of analysis.suggestions) {
      console.log(`   - ${suggestion.message}`);
    }
  }

  console.log('');
  console.log('📖 Next steps:');
  console.log('   1. Review design/systems/token-analysis-report.md');
  console.log('   2. Adjust design/systems/detected-tokens.json as needed');
  console.log('   3. Run /init-brand-tokens to finalize token structure');
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { scanDirectory, analyzeResults, generateProposedTokens };

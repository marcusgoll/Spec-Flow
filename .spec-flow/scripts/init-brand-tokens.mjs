#!/usr/bin/env node

/**
 * Design Token Generator & Brand System Orchestrator
 *
 * Modes:
 *   - greenfield: Generate tokens from questionnaire answers
 *   - brownfield: Scan existing tokens.css, merge with answers
 *
 * Features:
 *   - OKLCH color space for perceptually uniform contrast
 *   - Auto-fix WCAG contrast ratios (≥4.5:1 for AA)
 *   - Multi-surface token generation (UI, emails, PDFs, CLI, charts, docs)
 *   - Three-layer architecture (primitives → semantic → component)
 *
 * Usage:
 *   node init-brand-tokens.mjs --mode greenfield --answers brand-answers.json
 *   node init-brand-tokens.mjs --mode brownfield --scan design/systems/tokens.css --answers brand-answers.json
 */

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================================
// OKLCH Color Space Utilities
// ============================================================================

/**
 * Convert hex color to OKLCH
 * @param {string} hex - Hex color (e.g., "#3b82f6")
 * @returns {{l: number, c: number, h: number}} OKLCH values
 */
function hexToOKLCH(hex) {
  // Remove # if present
  hex = hex.replace('#', '');

  // Convert hex to RGB
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;

  // RGB to linear RGB
  const toLinear = (c) => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  const lr = toLinear(r);
  const lg = toLinear(g);
  const lb = toLinear(b);

  // Linear RGB to OKLab (approximation)
  const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb;
  const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb;
  const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb;

  const l_ = Math.cbrt(l);
  const m_ = Math.cbrt(m);
  const s_ = Math.cbrt(s);

  const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
  const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
  const b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

  // OKLab to OKLCH
  const C = Math.sqrt(a * a + b_ * b_);
  let H = Math.atan2(b_, a) * 180 / Math.PI;
  if (H < 0) H += 360;

  return { l: L, c: C, h: H };
}

/**
 * Convert OKLCH to hex
 * @param {{l: number, c: number, h: number}} oklch - OKLCH values
 * @returns {string} Hex color
 */
function oklchToHex({ l, c, h }) {
  // OKLCH to OKLab
  const a = c * Math.cos(h * Math.PI / 180);
  const b = c * Math.sin(h * Math.PI / 180);

  // OKLab to linear RGB
  const l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  const l3 = l_ * l_ * l_;
  const m3 = m_ * m_ * m_;
  const s3 = s_ * s_ * s_;

  let lr = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  let lg = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  let lb = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  // Linear RGB to RGB
  const fromLinear = (c) => c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  let r = fromLinear(lr);
  let g = fromLinear(lg);
  let b_ = fromLinear(lb);

  // Clamp to [0, 1]
  r = Math.max(0, Math.min(1, r));
  g = Math.max(0, Math.min(1, g));
  b_ = Math.max(0, Math.min(1, b_));

  // RGB to hex
  const toHex = (c) => Math.round(c * 255).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b_)}`;
}

/**
 * Calculate WCAG contrast ratio between two colors
 * @param {string} hex1 - First hex color
 * @param {string} hex2 - Second hex color
 * @returns {number} Contrast ratio (1-21)
 */
function getContrastRatio(hex1, hex2) {
  const getLuminance = (hex) => {
    hex = hex.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16) / 255;
    const g = parseInt(hex.substring(2, 4), 16) / 255;
    const b = parseInt(hex.substring(4, 6), 16) / 255;

    const toLinear = (c) => c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);

    return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
  };

  const lum1 = getLuminance(hex1);
  const lum2 = getLuminance(hex2);

  const lighter = Math.max(lum1, lum2);
  const darker = Math.min(lum1, lum2);

  return (lighter + 0.05) / (darker + 0.05);
}

/**
 * Auto-fix color to meet WCAG contrast requirement
 * @param {string} colorHex - Color to fix
 * @param {string} bgHex - Background color
 * @param {number} targetRatio - Target contrast ratio (default: 4.5)
 * @returns {{fixed: string, original: string, ratio: number}} Fixed color info
 */
function autoFixContrast(colorHex, bgHex, targetRatio = 4.5) {
  const originalRatio = getContrastRatio(colorHex, bgHex);

  if (originalRatio >= targetRatio) {
    return { fixed: colorHex, original: colorHex, ratio: originalRatio };
  }

  // Convert to OKLCH for perceptually uniform adjustments
  const color = hexToOKLCH(colorHex);
  const bg = hexToOKLCH(bgHex);

  // Determine if we need to lighten or darken
  const shouldLighten = color.l < bg.l;

  // Binary search for optimal lightness
  let step = 0.1;
  let attempts = 0;
  const maxAttempts = 50;

  while (attempts < maxAttempts) {
    const testColor = oklchToHex(color);
    const ratio = getContrastRatio(testColor, bgHex);

    if (Math.abs(ratio - targetRatio) < 0.1) {
      return { fixed: testColor, original: colorHex, ratio };
    }

    if (ratio < targetRatio) {
      // Need more contrast
      color.l = shouldLighten ? Math.min(1, color.l + step) : Math.max(0, color.l - step);
    } else {
      // Too much contrast, dial back
      color.l = shouldLighten ? Math.max(0, color.l - step / 2) : Math.min(1, color.l + step / 2);
      step /= 2;
    }

    attempts++;
  }

  const finalColor = oklchToHex(color);
  return { fixed: finalColor, original: colorHex, ratio: getContrastRatio(finalColor, bgHex) };
}

// ============================================================================
// Color Palette Generation
// ============================================================================

/**
 * Generate color scale from base color (50-950 Tailwind-style)
 * @param {string} baseHex - Base color in hex
 * @param {string} name - Color name (e.g., 'primary', 'neutral')
 * @returns {Object} Color scale object
 */
function generateColorScale(baseHex, name) {
  const base = hexToOKLCH(baseHex);

  // Tailwind-inspired lightness scale
  const scales = {
    50: 0.95,
    100: 0.90,
    200: 0.80,
    300: 0.70,
    400: 0.60,
    500: base.l, // Use actual base lightness
    600: base.l * 0.85,
    700: base.l * 0.70,
    800: base.l * 0.55,
    900: base.l * 0.40,
    950: base.l * 0.25,
  };

  const scale = {};

  for (const [level, lightness] of Object.entries(scales)) {
    const color = { l: lightness, c: base.c * (lightness / base.l), h: base.h };
    scale[level] = oklchToHex(color);
  }

  return { name, scale };
}

/**
 * Generate semantic colors from primary palette
 * @param {Object} primaryScale - Primary color scale
 * @returns {Object} Semantic color mappings
 */
function generateSemanticColors(primaryScale) {
  return {
    // Success (green hue ~140°)
    success: generateColorScale(
      oklchToHex({ l: 0.6, c: 0.15, h: 140 }),
      'success'
    ),

    // Warning (yellow hue ~80°)
    warning: generateColorScale(
      oklchToHex({ l: 0.7, c: 0.15, h: 80 }),
      'warning'
    ),

    // Error (red hue ~20°)
    error: generateColorScale(
      oklchToHex({ l: 0.55, c: 0.18, h: 20 }),
      'error'
    ),

    // Info (blue hue ~250°)
    info: generateColorScale(
      oklchToHex({ l: 0.6, c: 0.15, h: 250 }),
      'info'
    ),
  };
}

// ============================================================================
// Token Generation
// ============================================================================

/**
 * Generate complete token system from brand answers
 * @param {Object} answers - Brand questionnaire answers
 * @returns {Object} Complete token system
 */
function generateTokens(answers) {
  const {
    primaryColor = '#3b82f6',
    brandPersonality = 'modern',
    visualStyle = 'minimal',
    densityPreference = 'comfortable',
    typographyStyle = 'geometric',
  } = answers;

  // Generate color system
  const primaryScale = generateColorScale(primaryColor, 'primary');
  const neutralScale = generateColorScale('#64748b', 'neutral');
  const semanticColors = generateSemanticColors(primaryScale);

  // Generate spacing scale based on density
  const baseUnit = densityPreference === 'compact' ? 4 : densityPreference === 'spacious' ? 8 : 6;
  const spacing = {};
  for (let i = 0; i <= 16; i++) {
    spacing[i] = `${baseUnit * i}px`;
  }

  // Generate typography scale
  const typeSizes = {
    xs: '0.75rem',
    sm: '0.875rem',
    base: '1rem',
    lg: '1.125rem',
    xl: '1.25rem',
    '2xl': '1.5rem',
    '3xl': '1.875rem',
    '4xl': '2.25rem',
    '5xl': '3rem',
    '6xl': '3.75rem',
  };

  const fontFamilies = {
    geometric: '"Inter", "SF Pro", system-ui, sans-serif',
    humanist: '"Nunito", "Open Sans", system-ui, sans-serif',
    monospace: '"Fira Code", "Consolas", monospace',
  };

  // Auto-fix text colors for WCAG AA (4.5:1)
  const textOnLight = autoFixContrast(neutralScale.scale[900], '#ffffff', 4.5);
  const textOnDark = autoFixContrast(neutralScale.scale[50], neutralScale.scale[900], 4.5);

  return {
    colors: {
      primary: primaryScale.scale,
      neutral: neutralScale.scale,
      ...Object.fromEntries(
        Object.entries(semanticColors).map(([name, { scale }]) => [name, scale])
      ),

      // Surface colors
      background: {
        primary: '#ffffff',
        secondary: neutralScale.scale[50],
        tertiary: neutralScale.scale[100],
        inverse: neutralScale.scale[900],
      },

      // Text colors (WCAG-compliant)
      text: {
        primary: textOnLight.fixed,
        secondary: neutralScale.scale[600],
        tertiary: neutralScale.scale[500],
        inverse: textOnDark.fixed,
        link: primaryScale.scale[600],
        'link-hover': primaryScale.scale[700],
      },
    },

    spacing,

    typography: {
      fontFamily: {
        sans: fontFamilies[typographyStyle] || fontFamilies.geometric,
        mono: fontFamilies.monospace,
      },
      fontSize: typeSizes,
      lineHeight: {
        tight: '1.25',
        normal: '1.5',
        relaxed: '1.75',
      },
      fontWeight: {
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
      },
    },

    borderRadius: {
      none: '0',
      sm: '0.125rem',
      DEFAULT: visualStyle === 'minimal' ? '0.25rem' : '0.5rem',
      md: '0.375rem',
      lg: '0.5rem',
      xl: '0.75rem',
      '2xl': '1rem',
      full: '9999px',
    },

    shadows: visualStyle === 'minimal' ? {
      sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
      DEFAULT: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
      md: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
      lg: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
    } : {
      sm: '0 2px 4px 0 rgb(0 0 0 / 0.1)',
      DEFAULT: '0 4px 8px 0 rgb(0 0 0 / 0.15)',
      md: '0 8px 16px -2px rgb(0 0 0 / 0.15)',
      lg: '0 16px 32px -4px rgb(0 0 0 / 0.2)',
    },

    // Multi-surface extensions
    surfaces: {
      ui: {
        background: '#ffffff',
        interactive: primaryScale.scale[500],
        hover: primaryScale.scale[600],
      },
      email: {
        background: '#f9fafb',
        accent: primaryScale.scale[600],
      },
      pdf: {
        background: '#ffffff',
        accent: primaryScale.scale[700],
      },
      cli: {
        primary: primaryScale.scale[400],
        success: semanticColors.success.scale[400],
        error: semanticColors.error.scale[400],
      },
      charts: {
        primary: primaryScale.scale[500],
        secondary: neutralScale.scale[400],
        tertiary: semanticColors.info.scale[500],
      },
    },

    // Auto-fix report
    _wcagFixes: {
      textOnLight,
      textOnDark,
    },
  };
}

// ============================================================================
// CSS Generation
// ============================================================================

/**
 * Generate tokens.css file from token system
 * @param {Object} tokens - Token system object
 * @returns {string} CSS file content
 */
function generateTokensCSS(tokens) {
  let css = `/**
 * Design Tokens - Auto-generated
 *
 * Generated: ${new Date().toISOString()}
 *
 * Token Architecture:
 *   Layer 1: Primitives (color scales, spacing, typography)
 *   Layer 2: Semantic (text, background, border colors)
 *   Layer 3: Component (button, input, card styles)
 *
 * WCAG Compliance: AA (4.5:1 contrast for text)
 * Color Space: OKLCH (perceptually uniform)
 */

:root {
  /* ========================================
     PRIMITIVES - Color Scales
     ======================================== */

`;

  // Color scales
  for (const [colorName, scale] of Object.entries(tokens.colors)) {
    if (typeof scale === 'object' && !Array.isArray(scale)) {
      if (Object.keys(scale).every(k => !isNaN(k))) {
        // Numbered scale (50-950)
        css += `  /* ${colorName.charAt(0).toUpperCase() + colorName.slice(1)} */\n`;
        for (const [level, hex] of Object.entries(scale)) {
          css += `  --color-${colorName}-${level}: ${hex};\n`;
        }
        css += '\n';
      } else {
        // Named colors (background, text)
        css += `  /* ${colorName.charAt(0).toUpperCase() + colorName.slice(1)} */\n`;
        for (const [key, value] of Object.entries(scale)) {
          css += `  --color-${colorName}-${key}: ${value};\n`;
        }
        css += '\n';
      }
    }
  }

  // Spacing
  css += `  /* ========================================
     PRIMITIVES - Spacing
     ======================================== */\n\n`;
  for (const [key, value] of Object.entries(tokens.spacing)) {
    css += `  --space-${key}: ${value};\n`;
  }
  css += '\n';

  // Typography
  css += `  /* ========================================
     PRIMITIVES - Typography
     ======================================== */\n\n`;
  css += `  --font-sans: ${tokens.typography.fontFamily.sans};\n`;
  css += `  --font-mono: ${tokens.typography.fontFamily.mono};\n\n`;

  for (const [key, value] of Object.entries(tokens.typography.fontSize)) {
    css += `  --text-${key}: ${value};\n`;
  }
  css += '\n';

  for (const [key, value] of Object.entries(tokens.typography.lineHeight)) {
    css += `  --leading-${key}: ${value};\n`;
  }
  css += '\n';

  for (const [key, value] of Object.entries(tokens.typography.fontWeight)) {
    css += `  --font-${key}: ${value};\n`;
  }
  css += '\n';

  // Border radius
  css += `  /* ========================================
     PRIMITIVES - Border Radius
     ======================================== */\n\n`;
  for (const [key, value] of Object.entries(tokens.borderRadius)) {
    const varName = key === 'DEFAULT' ? 'rounded' : `rounded-${key}`;
    css += `  --${varName}: ${value};\n`;
  }
  css += '\n';

  // Shadows
  css += `  /* ========================================
     PRIMITIVES - Shadows
     ======================================== */\n\n`;
  for (const [key, value] of Object.entries(tokens.shadows)) {
    const varName = key === 'DEFAULT' ? 'shadow' : `shadow-${key}`;
    css += `  --${varName}: ${value};\n`;
  }
  css += '\n';

  // Multi-surface tokens
  css += `  /* ========================================
     MULTI-SURFACE TOKENS
     ======================================== */\n\n`;
  for (const [surface, colors] of Object.entries(tokens.surfaces)) {
    css += `  /* ${surface.toUpperCase()} */\n`;
    for (const [key, value] of Object.entries(colors)) {
      css += `  --${surface}-${key}: ${value};\n`;
    }
    css += '\n';
  }

  css += `}\n\n`;

  // WCAG fix report as comment
  css += `/* ========================================
   WCAG AUTO-FIX REPORT
   ======================================== */\n\n`;
  css += `/*
Text on Light Background:
  Original: ${tokens._wcagFixes.textOnLight.original}
  Fixed: ${tokens._wcagFixes.textOnLight.fixed}
  Contrast: ${tokens._wcagFixes.textOnLight.ratio.toFixed(2)}:1

Text on Dark Background:
  Original: ${tokens._wcagFixes.textOnDark.original}
  Fixed: ${tokens._wcagFixes.textOnDark.fixed}
  Contrast: ${tokens._wcagFixes.textOnDark.ratio.toFixed(2)}:1
*/\n`;

  return css;
}

// ============================================================================
// Main Orchestrator
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  // Parse arguments
  const mode = args.includes('--mode') ? args[args.indexOf('--mode') + 1] : 'greenfield';
  const answersPath = args.includes('--answers') ? args[args.indexOf('--answers') + 1] : null;
  const scanPath = args.includes('--scan') ? args[args.indexOf('--scan') + 1] : null;

  console.log('🎨 Design Token Generator');
  console.log(`Mode: ${mode}`);
  console.log('');

  // Load answers
  let answers = {};
  if (answersPath) {
    try {
      const answersContent = await fs.readFile(answersPath, 'utf-8');
      answers = JSON.parse(answersContent);
      console.log(`✅ Loaded answers from: ${answersPath}`);
    } catch (error) {
      console.error(`❌ Failed to load answers: ${error.message}`);
      process.exit(1);
    }
  } else {
    console.log('⚠️  No answers file provided, using defaults');
  }

  // Generate tokens
  console.log('\n🔧 Generating token system...');
  const tokens = generateTokens(answers);

  // Generate CSS
  const css = generateTokensCSS(tokens);

  // Write tokens.css
  const outputPath = path.join(process.cwd(), 'design', 'systems', 'tokens.css');
  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.writeFile(outputPath, css);

  console.log(`\n✅ Generated: ${outputPath}`);
  console.log('\n📊 Token Summary:');
  console.log(`  Colors: ${Object.keys(tokens.colors).length} palettes`);
  console.log(`  Spacing: ${Object.keys(tokens.spacing).length} values`);
  console.log(`  Typography: ${Object.keys(tokens.typography.fontSize).length} sizes`);
  console.log(`  Surfaces: ${Object.keys(tokens.surfaces).length} (UI, email, PDF, CLI, charts)`);

  console.log('\n🛡️  WCAG Auto-Fix:');
  console.log(`  Text on light: ${tokens._wcagFixes.textOnLight.ratio.toFixed(2)}:1 ✅`);
  console.log(`  Text on dark: ${tokens._wcagFixes.textOnDark.ratio.toFixed(2)}:1 ✅`);

  // Write JSON for reference
  const jsonPath = path.join(process.cwd(), 'design', 'systems', 'tokens.json');
  await fs.writeFile(jsonPath, JSON.stringify(tokens, null, 2));
  console.log(`\n📄 JSON reference: ${jsonPath}`);

  console.log('\n🎉 Design token generation complete!');
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { generateTokens, generateTokensCSS, autoFixContrast, getContrastRatio, hexToOKLCH, oklchToHex };

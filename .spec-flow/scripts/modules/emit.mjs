#!/usr/bin/env node

/**
 * Emit Module - Generate tokens.json and tokens.css
 *
 * Transforms consolidated token data into:
 * 1. tokens.json - Machine-readable source of truth
 * 2. tokens.css - Browser-consumable CSS variables
 *
 * Ensures complete parity between JSON and CSS output.
 */

import fs from 'fs/promises';
import path from 'path';

/**
 * Emit tokens.json file
 * @param {Object} options
 * @param {Object} options.tokens - Consolidated token object
 * @param {string} options.out - Output file path
 */
export async function emitJSON({ tokens, out }) {
  await fs.mkdir(path.dirname(out), { recursive: true });
  await fs.writeFile(out, JSON.stringify(tokens, null, 2), 'utf8');
  return out;
}

/**
 * Emit tokens.css file with complete coverage
 * @param {Object} options
 * @param {Object} options.tokens - Consolidated token object
 * @param {string} options.out - Output file path
 */
export async function emitCSS({ tokens, out }) {
  const lines = [];

  lines.push(':root {');

  // Brand colors
  if (tokens.colors?.brand) {
    lines.push('  /* Brand colors (OKLCH with sRGB fallback) */');
    for (const [key, value] of Object.entries(tokens.colors.brand)) {
      lines.push(`  --color-${key}: ${value.oklch};`);
      lines.push(`  --color-${key}-fallback: ${value.fallback};`);
    }
    lines.push('');
  }

  // Semantic colors (all 4: success, error, warning, info)
  if (tokens.colors?.semantic) {
    lines.push('  /* Semantic colors (bg/fg/border/icon structure) */');
    for (const [semantic, states] of Object.entries(tokens.colors.semantic)) {
      for (const [state, value] of Object.entries(states)) {
        lines.push(`  --color-${semantic}-${state}: ${value.oklch};`);
      }
      lines.push('');
    }
  }

  // Neutral palette
  if (tokens.colors?.neutral) {
    lines.push('  /* Neutral palette */');
    for (const [shade, value] of Object.entries(tokens.colors.neutral)) {
      lines.push(`  --color-neutral-${shade}: ${value.oklch};`);
    }
    lines.push('');
  }

  // Typography - Families
  if (tokens.typography?.families) {
    lines.push('  /* Typography - Families */');
    for (const [key, value] of Object.entries(tokens.typography.families)) {
      lines.push(`  --font-${key}: ${value};`);
    }
    lines.push('');
  }

  // Typography - Sizes
  if (tokens.typography?.sizes) {
    lines.push('  /* Typography - Sizes */');
    for (const [key, value] of Object.entries(tokens.typography.sizes)) {
      lines.push(`  --font-size-${key}: ${value};`);
    }
    lines.push('');
  }

  // Typography - Weights
  if (tokens.typography?.weights) {
    lines.push('  /* Typography - Weights */');
    for (const [key, value] of Object.entries(tokens.typography.weights)) {
      lines.push(`  --font-weight-${key}: ${value};`);
    }
    lines.push('');
  }

  // Typography - Line Heights
  if (tokens.typography?.lineHeights) {
    lines.push('  /* Typography - Line Heights */');
    for (const [key, value] of Object.entries(tokens.typography.lineHeights)) {
      lines.push(`  --line-height-${key}: ${value};`);
    }
    lines.push('');
  }

  // Typography - Letter Spacing
  if (tokens.typography?.letterSpacing) {
    lines.push('  /* Typography - Letter Spacing */');
    for (const [key, value] of Object.entries(tokens.typography.letterSpacing)) {
      lines.push(`  --letter-spacing-${key}: ${value};`);
    }
    lines.push('');
  }

  // Spacing scale
  if (tokens.spacing) {
    lines.push('  /* Spacing scale (4px grid) */');
    for (const [key, value] of Object.entries(tokens.spacing)) {
      lines.push(`  --spacing-${key}: ${value};`);
    }
    lines.push('');
  }

  // Shadows - Light mode
  if (tokens.shadows?.light) {
    lines.push('  /* Shadows - Light mode */');
    for (const [key, value] of Object.entries(tokens.shadows.light)) {
      const shadowValue = value.value || value;
      lines.push(`  --shadow-${key}: ${shadowValue};`);
    }
    lines.push('');
  }

  // Motion - Duration
  if (tokens.motion?.duration) {
    lines.push('  /* Motion - Duration */');
    for (const [key, value] of Object.entries(tokens.motion.duration)) {
      lines.push(`  --motion-duration-${key}: ${value};`);
    }
    lines.push('');
  }

  // Motion - Easing
  if (tokens.motion?.easing) {
    lines.push('  /* Motion - Easing */');
    for (const [key, value] of Object.entries(tokens.motion.easing)) {
      lines.push(`  --motion-easing-${key}: ${value};`);
    }
    lines.push('');
  }

  // Data visualization - Okabe-Ito
  if (tokens.dataViz?.categorical?.['okabe-ito']) {
    lines.push('  /* Data visualization - Okabe-Ito (color-blind-safe) */');
    for (const [key, value] of Object.entries(tokens.dataViz.categorical['okabe-ito'])) {
      const varName = key.replace(/([A-Z])/g, '-$1').toLowerCase();
      lines.push(`  --dataviz-okabe-ito-${varName}: ${value.oklch};`);
    }
    lines.push('');
  }

  // Data visualization - Sequential scales
  if (tokens.dataViz?.sequential) {
    lines.push('  /* Data visualization - Sequential scales */');
    for (const [palette, colors] of Object.entries(tokens.dataViz.sequential)) {
      colors.forEach((color, index) => {
        lines.push(`  --dataviz-sequential-${palette}-${index + 1}: ${color};`);
      });
      lines.push('');
    }
  }

  // Data visualization - Diverging scales
  if (tokens.dataViz?.diverging) {
    lines.push('  /* Data visualization - Diverging scales */');
    for (const [palette, colors] of Object.entries(tokens.dataViz.diverging)) {
      colors.forEach((color, index) => {
        lines.push(`  --dataviz-diverging-${palette}-${index + 1}: ${color};`);
      });
      lines.push('');
    }
  }

  lines.push('}');
  lines.push('');

  // Dark mode shadows
  if (tokens.shadows?.dark) {
    lines.push('/* Dark mode shadows (4-6x opacity increase) */');
    lines.push('@media (prefers-color-scheme: dark) {');
    lines.push('  :root {');
    for (const [key, value] of Object.entries(tokens.shadows.dark)) {
      const shadowValue = value.value || value;
      lines.push(`    --shadow-${key}: ${shadowValue};`);
    }
    lines.push('  }');
    lines.push('}');
    lines.push('');
  }

  // Reduced motion (accessibility)
  if (tokens.motion) {
    lines.push('/* Reduced motion (accessibility) */');
    lines.push('@media (prefers-reduced-motion: reduce) {');
    lines.push('  :root {');

    if (tokens.motion.duration) {
      for (const key of Object.keys(tokens.motion.duration)) {
        lines.push(`    --motion-duration-${key}: 0ms;`);
      }
    }

    if (tokens.motion.easing) {
      for (const key of Object.keys(tokens.motion.easing)) {
        lines.push(`    --motion-easing-${key}: linear;`);
      }
    }

    lines.push('  }');
    lines.push('}');
    lines.push('');
  }

  // OKLCH fallback for legacy browsers
  if (tokens.colors?.brand) {
    lines.push('/* OKLCH fallback for legacy browsers (~8%) */');
    lines.push('@supports not (color: oklch(0% 0 0)) {');
    lines.push('  :root {');
    for (const key of Object.keys(tokens.colors.brand)) {
      lines.push(`    --color-${key}: var(--color-${key}-fallback);`);
    }
    lines.push('  }');
    lines.push('}');
  }

  const css = lines.join('\n');
  await fs.mkdir(path.dirname(out), { recursive: true });
  await fs.writeFile(out, css, 'utf8');
  return out;
}

/**
 * Emit both JSON and CSS files
 * @param {Object} options
 * @param {Object} options.tokens - Consolidated token object
 * @param {string} options.jsonOut - Path for tokens.json
 * @param {string} options.cssOut - Path for tokens.css
 */
export async function emitAll({ tokens, jsonOut, cssOut }) {
  const [jsonPath, cssPath] = await Promise.all([
    emitJSON({ tokens, out: jsonOut }),
    emitCSS({ tokens, out: cssOut })
  ]);

  return { jsonPath, cssPath };
}

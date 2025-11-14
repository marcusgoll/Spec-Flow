#!/usr/bin/env node

/**
 * Test emit.mjs to verify CSS contains all tokens from JSON
 */

import { emitJSON, emitCSS } from './emit.mjs';
import fs from 'fs/promises';
import path from 'path';

// Sample token structure matching the spec
const sampleTokens = {
  meta: {
    colorSpace: 'oklch',
    fallbackSpace: 'srgb',
    version: '2.0.0',
    generated: new Date().toISOString()
  },
  colors: {
    brand: {
      primary: {
        oklch: 'oklch(59.69% 0.156 261.45)',
        fallback: '#3b82f6',
        description: 'Primary brand color'
      },
      secondary: {
        oklch: 'oklch(58.23% 0.167 271.45)',
        fallback: '#6366f1'
      },
      accent: {
        oklch: 'oklch(67.89% 0.152 164.57)',
        fallback: '#10b981'
      }
    },
    semantic: {
      success: {
        bg: { oklch: 'oklch(95% 0.02 145)', fallback: '#D1FAE5' },
        fg: { oklch: 'oklch(25% 0.12 145)', fallback: '#047857' },
        border: { oklch: 'oklch(85% 0.05 145)', fallback: '#A7F3D0' },
        icon: { oklch: 'oklch(35% 0.13 145)', fallback: '#059669' }
      },
      error: {
        bg: { oklch: 'oklch(95% 0.02 27)', fallback: '#FEE2E2' },
        fg: { oklch: 'oklch(30% 0.18 27)', fallback: '#991B1B' },
        border: { oklch: 'oklch(85% 0.08 27)', fallback: '#FECACA' },
        icon: { oklch: 'oklch(40% 0.20 27)', fallback: '#DC2626' }
      },
      warning: {
        bg: { oklch: 'oklch(95% 0.02 90)', fallback: '#FEF3C7' },
        fg: { oklch: 'oklch(35% 0.15 90)', fallback: '#92400E' },
        border: { oklch: 'oklch(85% 0.08 90)', fallback: '#FDE68A' },
        icon: { oklch: 'oklch(45% 0.16 90)', fallback: '#D97706' }
      },
      info: {
        bg: { oklch: 'oklch(95% 0.02 240)', fallback: '#DBEAFE' },
        fg: { oklch: 'oklch(30% 0.12 240)', fallback: '#1E40AF' },
        border: { oklch: 'oklch(85% 0.05 240)', fallback: '#BFDBFE' },
        icon: { oklch: 'oklch(40% 0.14 240)', fallback: '#3B82F6' }
      }
    },
    neutral: {
      '50': { oklch: 'oklch(98% 0 0)', fallback: '#fafafa' },
      '100': { oklch: 'oklch(96% 0 0)', fallback: '#f5f5f5' },
      '200': { oklch: 'oklch(90% 0 0)', fallback: '#e5e5e5' },
      '300': { oklch: 'oklch(82% 0 0)', fallback: '#d4d4d4' },
      '400': { oklch: 'oklch(64% 0 0)', fallback: '#a3a3a3' },
      '500': { oklch: 'oklch(54% 0 0)', fallback: '#737373' },
      '600': { oklch: 'oklch(42% 0 0)', fallback: '#525252' },
      '700': { oklch: 'oklch(32% 0 0)', fallback: '#404040' },
      '800': { oklch: 'oklch(23% 0 0)', fallback: '#262626' },
      '900': { oklch: 'oklch(15% 0 0)', fallback: '#171717' },
      '950': { oklch: 'oklch(11% 0 0)', fallback: '#0a0a0a' }
    }
  },
  typography: {
    families: {
      sans: 'Inter, system-ui, -apple-system, BlinkMacSystemFont, sans-serif',
      mono: 'Fira Code, Menlo, Monaco, Consolas, monospace',
      serif: 'Georgia, Cambria, \'Times New Roman\', Times, serif'
    },
    sizes: {
      xs: '0.75rem',
      sm: '0.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem',
      '4xl': '2.25rem'
    },
    weights: {
      normal: '400',
      medium: '500',
      semibold: '600',
      bold: '700'
    },
    lineHeights: {
      tight: '1.25',
      normal: '1.5',
      relaxed: '1.75'
    },
    letterSpacing: {
      display: '-0.025em',
      body: '0em',
      cta: '0.025em'
    }
  },
  spacing: {
    '0': '0px',
    '1': '4px',
    '2': '8px',
    '3': '12px',
    '4': '16px',
    '5': '20px',
    '6': '24px',
    '8': '32px',
    '10': '40px',
    '12': '48px',
    '16': '64px',
    '20': '80px',
    '24': '96px'
  },
  shadows: {
    light: {
      sm: { value: '0 1px 2px oklch(0% 0 0 / 0.05)', fallback: '0 1px 2px rgba(0, 0, 0, 0.05)' },
      md: { value: '0 4px 6px oklch(0% 0 0 / 0.07), 0 2px 4px oklch(0% 0 0 / 0.06)', fallback: '0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06)' },
      lg: { value: '0 10px 15px oklch(0% 0 0 / 0.10), 0 4px 6px oklch(0% 0 0 / 0.05)', fallback: '0 10px 15px rgba(0, 0, 0, 0.10), 0 4px 6px rgba(0, 0, 0, 0.05)' }
    },
    dark: {
      sm: { value: '0 1px 2px oklch(0% 0 0 / 0.30)', fallback: '0 1px 2px rgba(0, 0, 0, 0.30)' },
      md: { value: '0 4px 6px oklch(0% 0 0 / 0.35), 0 2px 4px oklch(0% 0 0 / 0.30)', fallback: '0 4px 6px rgba(0, 0, 0, 0.35), 0 2px 4px rgba(0, 0, 0, 0.30)' },
      lg: { value: '0 10px 15px oklch(0% 0 0 / 0.40), 0 4px 6px oklch(0% 0 0 / 0.35)', fallback: '0 10px 15px rgba(0, 0, 0, 0.40), 0 4px 6px rgba(0, 0, 0, 0.35)' }
    }
  },
  motion: {
    duration: {
      fast: '150ms',
      base: '200ms',
      slow: '300ms',
      slower: '500ms'
    },
    easing: {
      standard: 'cubic-bezier(0.4, 0.0, 0.2, 1)',
      decelerate: 'cubic-bezier(0.0, 0.0, 0.2, 1)',
      accelerate: 'cubic-bezier(0.4, 0.0, 1.0, 1.0)'
    }
  },
  dataViz: {
    categorical: {
      'okabe-ito': {
        orange: { oklch: 'oklch(68.29% 0.151 58.43)', fallback: '#E69F00', description: 'Orange - warm accent' },
        skyBlue: { oklch: 'oklch(70.17% 0.099 232.66)', fallback: '#56B4E9', description: 'Sky blue - cool primary' },
        bluishGreen: { oklch: 'oklch(59.78% 0.108 164.04)', fallback: '#009E73', description: 'Bluish green - success' },
        yellow: { oklch: 'oklch(89.87% 0.162 99.57)', fallback: '#F0E442', description: 'Yellow - warning' },
        blue: { oklch: 'oklch(46.86% 0.131 264.05)', fallback: '#0072B2', description: 'Blue - information' },
        vermillion: { oklch: 'oklch(57.50% 0.199 37.70)', fallback: '#D55E00', description: 'Vermillion - error' },
        reddishPurple: { oklch: 'oklch(50.27% 0.159 328.36)', fallback: '#CC79A7', description: 'Reddish purple - accent' },
        black: { oklch: 'oklch(0% 0 0)', fallback: '#000000', description: 'Black - text' }
      }
    },
    sequential: {
      blue: ['oklch(95% 0.02 240)', 'oklch(75% 0.08 240)', 'oklch(55% 0.12 240)', 'oklch(35% 0.14 240)', 'oklch(25% 0.16 240)'],
      green: ['oklch(95% 0.02 145)', 'oklch(75% 0.08 145)', 'oklch(55% 0.12 145)', 'oklch(35% 0.14 145)', 'oklch(25% 0.16 145)']
    },
    diverging: {
      'red-blue': ['oklch(95% 0.02 27)', 'oklch(75% 0.08 27)', 'oklch(90% 0 0)', 'oklch(75% 0.08 240)', 'oklch(95% 0.02 240)']
    }
  }
};

async function test() {
  const tmpDir = path.join('/tmp', 'token-test');
  await fs.mkdir(tmpDir, { recursive: true });

  const jsonPath = path.join(tmpDir, 'tokens.json');
  const cssPath = path.join(tmpDir, 'tokens.css');

  console.log('🧪 Testing emit.mjs...\n');

  // Generate files
  await emitJSON({ tokens: sampleTokens, out: jsonPath });
  await emitCSS({ tokens: sampleTokens, out: cssPath });

  console.log('✅ Generated tokens.json');
  console.log('✅ Generated tokens.css\n');

  // Read generated CSS
  const css = await fs.readFile(cssPath, 'utf8');

  // Verify all expected tokens are present in CSS
  const expectedTokens = [
    // Brand colors
    '--color-primary',
    '--color-secondary',
    '--color-accent',

    // Semantic colors (all 4 types)
    '--color-success-bg',
    '--color-success-fg',
    '--color-error-bg',
    '--color-warning-bg', // Was missing in original spec
    '--color-warning-fg',
    '--color-info-bg',    // Was missing in original spec
    '--color-info-fg',

    // Neutral shades
    '--color-neutral-50',
    '--color-neutral-950',

    // Typography - Families
    '--font-sans',
    '--font-mono',

    // Typography - Sizes (was missing in original spec)
    '--font-size-xs',
    '--font-size-base',
    '--font-size-4xl',

    // Typography - Weights (was missing in original spec)
    '--font-weight-normal',
    '--font-weight-bold',

    // Typography - Line Heights (was missing in original spec)
    '--line-height-tight',
    '--line-height-relaxed',

    // Typography - Letter Spacing (was missing in original spec)
    '--letter-spacing-display',
    '--letter-spacing-cta',

    // Spacing (was completely missing in original spec)
    '--spacing-0',
    '--spacing-4',
    '--spacing-24',

    // Shadows
    '--shadow-sm',
    '--shadow-lg',

    // Motion - Duration
    '--motion-duration-fast',
    '--motion-duration-slower', // Was missing in original spec

    // Motion - Easing
    '--motion-easing-standard',
    '--motion-easing-accelerate', // Was missing in original spec

    // Data viz - Okabe-Ito
    '--dataviz-okabe-ito-orange',
    '--dataviz-okabe-ito-black',

    // Data viz - Sequential (was missing in original spec)
    '--dataviz-sequential-blue-1',
    '--dataviz-sequential-green-5',

    // Data viz - Diverging (was missing in original spec)
    '--dataviz-diverging-red-blue-1',
    '--dataviz-diverging-red-blue-5'
  ];

  console.log('🔍 Verifying CSS completeness...\n');

  const missing = [];
  const found = [];

  for (const token of expectedTokens) {
    if (css.includes(token)) {
      found.push(token);
    } else {
      missing.push(token);
    }
  }

  console.log(`✅ Found ${found.length}/${expectedTokens.length} expected tokens\n`);

  if (missing.length > 0) {
    console.error('❌ Missing tokens in CSS:');
    missing.forEach(t => console.error(`   - ${t}`));
    process.exit(1);
  }

  // Verify media queries present
  const mediaQueries = [
    '@media (prefers-color-scheme: dark)',
    '@media (prefers-reduced-motion: reduce)',
    '@supports not (color: oklch(0% 0 0))'
  ];

  console.log('🔍 Verifying media queries...\n');

  for (const query of mediaQueries) {
    if (css.includes(query)) {
      console.log(`✅ ${query}`);
    } else {
      console.error(`❌ Missing: ${query}`);
      process.exit(1);
    }
  }

  console.log('\n✅ All tests passed!');
  console.log(`\n📄 Test files generated in: ${tmpDir}`);
  console.log('   - tokens.json');
  console.log('   - tokens.css');
}

test().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

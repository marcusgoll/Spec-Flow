#!/usr/bin/env node

/**
 * shadcn/ui Token Bridge Generator
 *
 * Generates shadcn-compatible CSS variables and components.json from OKLCH tokens.
 * Preserves OKLCH as source of truth while enabling seamless shadcn component usage.
 *
 * Usage:
 *   node generate-shadcn-tokens.js --config shadcn-answers.json
 *   node generate-shadcn-tokens.js --brownfield --scan-dir ./app
 *
 * Features:
 *   - 8 customization options (Style, Base Color, Theme, Icons, Font, Radius, Menu Color, Menu Accent)
 *   - OKLCH → shadcn CSS variable mapping
 *   - Brownfield scanning and merge
 *   - components.json generation
 *   - Menu-specific tokens
 */

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================================
// Configuration Constants
// ============================================================================

const HUE_MAP = {
  blue: 250,
  purple: 285,
  green: 150,
  orange: 50,
  red: 25,
};

const RADIUS_MAP = {
  none: '0',
  small: '0.25rem',
  medium: '0.5rem',
  large: '0.75rem',
  full: '9999px',
};

const STYLE_PRESETS = {
  default: { style: 'default', density: 1 },
  'new-york': { style: 'new-york', density: 1 },
  minimal: { style: 'default', density: 1.25 },
  bold: { style: 'new-york', density: 0.85 },
};

const ICON_PACKAGES = {
  lucide: { package: 'lucide-react', config: 'lucide' },
  heroicons: { package: '@heroicons/react', config: 'heroicons' },
  phosphor: { package: '@phosphor-icons/react', config: 'phosphor' },
};

const FONT_CONFIG = {
  inter: { name: 'Inter', import: "import { Inter } from 'next/font/google'" },
  geist: { name: 'Geist', import: "import { GeistSans, GeistMono } from 'geist/font'" },
  'plus-jakarta': { name: 'Plus_Jakarta_Sans', import: "import { Plus_Jakarta_Sans } from 'next/font/google'" },
  system: { name: 'system-ui', import: null },
};

// ============================================================================
// OKLCH Color Utilities (imported from parent module)
// ============================================================================

function hexToOKLCH(hex) {
  hex = hex.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;

  const toLinear = (c) => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  const lr = toLinear(r);
  const lg = toLinear(g);
  const lb = toLinear(b);

  const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb;
  const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb;
  const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb;

  const l_ = Math.cbrt(l);
  const m_ = Math.cbrt(m);
  const s_ = Math.cbrt(s);

  const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
  const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
  const b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

  const C = Math.sqrt(a * a + b_ * b_);
  let H = Math.atan2(b_, a) * 180 / Math.PI;
  if (H < 0) H += 360;

  return { l: L, c: C, h: H };
}

function oklchToHex({ l, c, h }) {
  const a = c * Math.cos(h * Math.PI / 180);
  const b = c * Math.sin(h * Math.PI / 180);

  const l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  const l3 = l_ * l_ * l_;
  const m3 = m_ * m_ * m_;
  const s3 = s_ * s_ * s_;

  let lr = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  let lg = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  let lb = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  const fromLinear = (c) => c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  let r = Math.max(0, Math.min(1, fromLinear(lr)));
  let g = Math.max(0, Math.min(1, fromLinear(lg)));
  let b_ = Math.max(0, Math.min(1, fromLinear(lb)));

  const toHex = (c) => Math.round(c * 255).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b_)}`;
}

function formatOKLCH({ l, c, h }) {
  return `oklch(${(l * 100).toFixed(1)}% ${c.toFixed(3)} ${h.toFixed(1)})`;
}

// ============================================================================
// Primary Scale Generation
// ============================================================================

/**
 * Generate 11-shade OKLCH scale from base hue
 */
function generateOKLCHScale(hue, chroma = 0.15) {
  const lightnesses = {
    50: 0.98,
    100: 0.94,
    200: 0.88,
    300: 0.78,
    400: 0.65,
    500: 0.55,
    600: 0.48,
    700: 0.40,
    800: 0.32,
    900: 0.22,
    950: 0.14,
  };

  const scale = {};
  for (const [name, lightness] of Object.entries(lightnesses)) {
    // Reduce chroma at extreme lightnesses for better contrast
    const adjustedChroma = lightness > 0.9 || lightness < 0.2
      ? chroma * 0.3
      : chroma;

    const oklch = { l: lightness, c: adjustedChroma, h: hue };
    scale[name] = {
      oklch: formatOKLCH(oklch),
      hex: oklchToHex(oklch),
    };
  }
  return scale;
}

/**
 * Generate neutral scale (achromatic)
 */
function generateNeutralScale() {
  const lightnesses = {
    50: 0.98,
    100: 0.96,
    200: 0.90,
    300: 0.82,
    400: 0.64,
    500: 0.54,
    600: 0.42,
    700: 0.32,
    800: 0.23,
    900: 0.15,
    950: 0.11,
  };

  const scale = {};
  for (const [name, lightness] of Object.entries(lightnesses)) {
    const oklch = { l: lightness, c: 0, h: 0 };
    scale[name] = {
      oklch: formatOKLCH(oklch),
      hex: oklchToHex(oklch),
    };
  }
  return scale;
}

// ============================================================================
// Menu Token Generation
// ============================================================================

/**
 * Generate menu-specific tokens based on user choices
 */
function generateMenuTokens(menuColor, menuAccent, primaryScale, neutralScale) {
  const tokens = {
    menu: {},
    menuAccent: {},
  };

  // Menu color tokens
  switch (menuColor) {
    case 'background':
      tokens.menu = {
        background: 'var(--background)',
        hover: 'var(--color-neutral-100)',
        shadow: 'none',
        backdrop: 'none',
      };
      break;
    case 'surface':
      tokens.menu = {
        background: 'var(--card)',
        hover: 'var(--color-neutral-100)',
        shadow: 'var(--shadow-sm)',
        backdrop: 'none',
      };
      break;
    case 'primaryTint':
      tokens.menu = {
        background: `oklch(from var(--color-primary) l c h / 0.05)`,
        hover: `oklch(from var(--color-primary) l c h / 0.1)`,
        shadow: 'none',
        backdrop: 'none',
      };
      break;
    case 'glass':
      tokens.menu = {
        background: 'oklch(from var(--background) l c h / 0.8)',
        hover: 'var(--color-neutral-100)',
        shadow: 'var(--shadow-sm)',
        backdrop: 'blur(8px)',
      };
      break;
    default:
      tokens.menu = {
        background: 'var(--background)',
        hover: 'var(--color-neutral-100)',
        shadow: 'none',
        backdrop: 'none',
      };
  }

  // Menu accent tokens
  switch (menuAccent) {
    case 'border':
      tokens.menuAccent = {
        border: '3px solid var(--primary)',
        background: 'transparent',
        icon: 'currentColor',
      };
      break;
    case 'background':
      tokens.menuAccent = {
        border: 'none',
        background: 'oklch(from var(--color-primary) l c h / 0.1)',
        icon: 'currentColor',
      };
      break;
    case 'iconTint':
      tokens.menuAccent = {
        border: 'none',
        background: 'transparent',
        icon: 'var(--primary)',
      };
      break;
    case 'combined':
      tokens.menuAccent = {
        border: '3px solid var(--primary)',
        background: 'oklch(from var(--color-primary) l c h / 0.05)',
        icon: 'var(--primary)',
      };
      break;
    default:
      tokens.menuAccent = {
        border: '3px solid var(--primary)',
        background: 'transparent',
        icon: 'currentColor',
      };
  }

  return tokens;
}

// ============================================================================
// shadcn CSS Variables Generation
// ============================================================================

/**
 * Generate shadcn-compatible CSS variables
 */
function generateShadcnCSS(config) {
  const {
    primaryScale,
    neutralScale,
    radius,
    menuTokens,
    themeMode,
  } = config;

  let css = `/**
 * shadcn/ui CSS Variable Aliases
 * Generated by Spec-Flow Token Bridge
 *
 * These map OKLCH tokens (source of truth) to shadcn expected variables.
 * DO NOT edit manually - regenerate via /init --tokens --shadcn
 *
 * Generated: ${new Date().toISOString()}
 */

/* ========================================
   OKLCH TOKEN PRIMITIVES
   ======================================== */

:root {
  /* Primary Color Scale (OKLCH) */
${Object.entries(primaryScale).map(([key, val]) => `  --color-primary-${key}: ${val.oklch};`).join('\n')}

  /* Neutral Color Scale (OKLCH) */
${Object.entries(neutralScale).map(([key, val]) => `  --color-neutral-${key}: ${val.oklch};`).join('\n')}

  /* Semantic Colors */
  --color-error: oklch(55% 0.2 25);
  --color-error-fg: oklch(30% 0.18 27);
  --color-warning: oklch(70% 0.15 80);
  --color-warning-fg: oklch(35% 0.15 90);
  --color-success: oklch(60% 0.15 150);
  --color-success-fg: oklch(25% 0.12 145);
  --color-info: oklch(60% 0.15 250);
  --color-info-fg: oklch(30% 0.12 240);
}

/* ========================================
   SHADCN/UI VARIABLE ALIASES
   ======================================== */

:root {
  /* Core Colors */
  --background: var(--color-neutral-50);
  --foreground: var(--color-neutral-900);

  /* Cards & Popovers */
  --card: var(--color-neutral-50);
  --card-foreground: var(--color-neutral-900);
  --popover: var(--color-neutral-50);
  --popover-foreground: var(--color-neutral-900);

  /* Primary */
  --primary: var(--color-primary-600);
  --primary-foreground: var(--color-neutral-50);

  /* Secondary */
  --secondary: var(--color-neutral-100);
  --secondary-foreground: var(--color-neutral-900);

  /* Muted */
  --muted: var(--color-neutral-100);
  --muted-foreground: var(--color-neutral-500);

  /* Accent */
  --accent: var(--color-neutral-100);
  --accent-foreground: var(--color-neutral-900);

  /* Destructive */
  --destructive: var(--color-error);
  --destructive-foreground: var(--color-neutral-50);

  /* Borders & Inputs */
  --border: var(--color-neutral-200);
  --input: var(--color-neutral-200);
  --ring: var(--color-primary-600);

  /* Border Radius */
  --radius: ${radius};

  /* Menu Theming */
  --menu: ${menuTokens.menu.background};
  --menu-hover: ${menuTokens.menu.hover};
  --menu-shadow: ${menuTokens.menu.shadow};
  --menu-backdrop: ${menuTokens.menu.backdrop};
  --menu-accent-border: ${menuTokens.menuAccent.border};
  --menu-accent-bg: ${menuTokens.menuAccent.background};
  --menu-accent-icon: ${menuTokens.menuAccent.icon};
  --menu-radius: calc(var(--radius) - 2px);
}

/* ========================================
   DARK MODE
   ======================================== */

${themeMode === 'light' ? '/* Dark mode disabled by user preference */' : `.dark {
  --background: var(--color-neutral-950);
  --foreground: var(--color-neutral-50);
  --card: var(--color-neutral-900);
  --card-foreground: var(--color-neutral-50);
  --popover: var(--color-neutral-900);
  --popover-foreground: var(--color-neutral-50);
  --primary: var(--color-primary-500);
  --primary-foreground: var(--color-neutral-950);
  --secondary: var(--color-neutral-800);
  --secondary-foreground: var(--color-neutral-50);
  --muted: var(--color-neutral-800);
  --muted-foreground: var(--color-neutral-400);
  --accent: var(--color-neutral-800);
  --accent-foreground: var(--color-neutral-50);
  --destructive: oklch(55% 0.2 27);
  --destructive-foreground: var(--color-neutral-50);
  --border: var(--color-neutral-800);
  --input: var(--color-neutral-800);
  --ring: var(--color-primary-500);

  /* Menu Dark Mode */
  --menu: var(--color-neutral-900);
  --menu-hover: var(--color-neutral-800);
}`}

/* ========================================
   THEME MODE MEDIA QUERIES
   ======================================== */

${themeMode === 'system' ? `@media (prefers-color-scheme: dark) {
  :root:not(.light) {
    --background: var(--color-neutral-950);
    --foreground: var(--color-neutral-50);
    --card: var(--color-neutral-900);
    --card-foreground: var(--color-neutral-50);
    --popover: var(--color-neutral-900);
    --popover-foreground: var(--color-neutral-50);
    --primary: var(--color-primary-500);
    --primary-foreground: var(--color-neutral-950);
    --secondary: var(--color-neutral-800);
    --secondary-foreground: var(--color-neutral-50);
    --muted: var(--color-neutral-800);
    --muted-foreground: var(--color-neutral-400);
    --accent: var(--color-neutral-800);
    --accent-foreground: var(--color-neutral-50);
    --destructive: oklch(55% 0.2 27);
    --destructive-foreground: var(--color-neutral-50);
    --border: var(--color-neutral-800);
    --input: var(--color-neutral-800);
    --ring: var(--color-primary-500);
    --menu: var(--color-neutral-900);
    --menu-hover: var(--color-neutral-800);
  }
}` : '/* System preference disabled - using class-based dark mode */'}

/* ========================================
   ACCESSIBILITY
   ======================================== */

@media (prefers-reduced-motion: reduce) {
  :root {
    --transition-all: none;
  }
}

/* OKLCH fallback for legacy browsers (~8%) */
@supports not (color: oklch(0% 0 0)) {
  :root {
    --color-primary-600: ${primaryScale[600].hex};
    --color-neutral-50: ${neutralScale[50].hex};
    --color-neutral-900: ${neutralScale[900].hex};
  }
}
`;

  return css;
}

// ============================================================================
// components.json Generation
// ============================================================================

/**
 * Generate shadcn/ui components.json configuration
 */
function generateComponentsJson(config) {
  const { stylePreset, iconLibrary } = config;
  const preset = STYLE_PRESETS[stylePreset] || STYLE_PRESETS.default;
  const iconConfig = ICON_PACKAGES[iconLibrary] || ICON_PACKAGES.lucide;

  return {
    $schema: 'https://ui.shadcn.com/schema.json',
    style: preset.style,
    rsc: true,
    tsx: true,
    tailwind: {
      config: 'tailwind.config.ts',
      css: 'app/globals.css',
      baseColor: 'neutral',
      cssVariables: true,
    },
    aliases: {
      components: '@/components',
      utils: '@/lib/utils',
      ui: '@/components/ui',
      lib: '@/lib',
      hooks: '@/hooks',
    },
    iconLibrary: iconConfig.config,
  };
}

// ============================================================================
// Menu Variants Generation
// ============================================================================

/**
 * Generate tailwind-variants menu styling
 */
function generateMenuVariants(config) {
  const { menuColor, menuAccent } = config;

  return `// Menu Style Variants
// Generated by Spec-Flow Token Bridge
// User choices: menuColor=${menuColor}, menuAccent=${menuAccent}

import { tv } from 'tailwind-variants';

export const menuStyles = tv({
  slots: {
    root: 'flex flex-col',
    item: 'flex items-center gap-3 px-3 py-2 rounded-[var(--menu-radius)] transition-colors',
    icon: 'h-5 w-5 shrink-0',
    label: 'flex-1 truncate',
    badge: 'ml-auto text-xs',
  },
  variants: {
    menuColor: {
      background: { root: 'bg-[var(--menu)]' },
      surface: { root: 'bg-card shadow-[var(--menu-shadow)]' },
      primaryTint: { root: 'bg-primary/5' },
      glass: { root: 'bg-background/80 backdrop-blur-[var(--menu-backdrop)]' },
    },
    menuAccent: {
      border: {
        item: 'data-[active=true]:border-l-[var(--menu-accent-border)] data-[active=true]:pl-[calc(0.75rem-3px)]',
      },
      background: {
        item: 'data-[active=true]:bg-[var(--menu-accent-bg)]',
      },
      iconTint: {
        item: '[&[data-active=true]_svg]:text-[var(--menu-accent-icon)]',
      },
      combined: {
        item: 'data-[active=true]:border-l-[var(--menu-accent-border)] data-[active=true]:bg-[var(--menu-accent-bg)] data-[active=true]:pl-[calc(0.75rem-3px)]',
      },
    },
    state: {
      default: { item: 'text-foreground' },
      hover: { item: 'bg-[var(--menu-hover)]' },
      active: { item: 'font-medium' },
      disabled: { item: 'opacity-50 cursor-not-allowed pointer-events-none' },
    },
  },
  defaultVariants: {
    menuColor: '${menuColor}',
    menuAccent: '${menuAccent}',
    state: 'default',
  },
});

// Type exports for component props
export type MenuColorVariant = 'background' | 'surface' | 'primaryTint' | 'glass';
export type MenuAccentVariant = 'border' | 'background' | 'iconTint' | 'combined';
export type MenuStateVariant = 'default' | 'hover' | 'active' | 'disabled';
`;
}

// ============================================================================
// Brownfield Scanning
// ============================================================================

/**
 * Scan existing codebase for tokens to merge
 */
async function scanExistingTokens(scanDir) {
  const results = {
    colors: [],
    existing: {
      tailwindConfig: null,
      globalsCSS: null,
      tokensJSON: null,
    },
  };

  const filesToCheck = [
    'tailwind.config.ts',
    'tailwind.config.js',
    'app/globals.css',
    'styles/globals.css',
    'design/systems/tokens.json',
    'design/systems/tokens.css',
  ];

  for (const file of filesToCheck) {
    const fullPath = path.join(scanDir, file);
    try {
      const content = await fs.readFile(fullPath, 'utf-8');

      if (file.includes('tailwind.config')) {
        results.existing.tailwindConfig = { path: fullPath, content };
      } else if (file.includes('globals.css')) {
        results.existing.globalsCSS = { path: fullPath, content };

        // Extract hex colors
        const hexMatches = content.match(/#[0-9a-fA-F]{6}/g) || [];
        results.colors.push(...hexMatches);
      } else if (file.includes('tokens.json')) {
        results.existing.tokensJSON = { path: fullPath, content: JSON.parse(content) };
      }
    } catch {
      // File doesn't exist, skip
    }
  }

  // Dedupe colors and count
  const colorCounts = {};
  for (const color of results.colors) {
    const normalized = color.toLowerCase();
    colorCounts[normalized] = (colorCounts[normalized] || 0) + 1;
  }
  results.colorSummary = colorCounts;

  return results;
}

// ============================================================================
// Main Generator Function
// ============================================================================

/**
 * Generate all shadcn token artifacts from configuration
 */
export async function generateShadcnTokens(config) {
  const {
    stylePreset = 'default',
    baseColor = 'blue',
    customHue = null,
    themeMode = 'system',
    iconLibrary = 'lucide',
    fontFamily = 'inter',
    borderRadius = 'medium',
    menuColor = 'background',
    menuAccent = 'border',
    outputDir = process.cwd(),
    brownfieldScan = null,
  } = config;

  // Determine primary hue
  const primaryHue = customHue || HUE_MAP[baseColor] || 250;
  const radius = RADIUS_MAP[borderRadius] || '0.5rem';

  // Generate color scales
  const primaryScale = generateOKLCHScale(primaryHue);
  const neutralScale = generateNeutralScale();

  // Generate menu tokens
  const menuTokens = generateMenuTokens(menuColor, menuAccent, primaryScale, neutralScale);

  // Handle brownfield merge
  let brownfieldResults = null;
  if (brownfieldScan) {
    brownfieldResults = await scanExistingTokens(brownfieldScan);
  }

  // Generate artifacts
  const shadcnCSS = generateShadcnCSS({
    primaryScale,
    neutralScale,
    radius,
    menuTokens,
    themeMode,
  });

  const componentsJson = generateComponentsJson({
    stylePreset,
    iconLibrary,
  });

  const menuVariants = generateMenuVariants({
    menuColor,
    menuAccent,
  });

  // Write files
  const designDir = path.join(outputDir, 'design', 'systems');
  const componentsDir = path.join(outputDir, 'components', 'ui');

  await fs.mkdir(designDir, { recursive: true });
  await fs.mkdir(componentsDir, { recursive: true });

  // Write shadcn-variables.css
  const cssPath = path.join(designDir, 'shadcn-variables.css');
  await fs.writeFile(cssPath, shadcnCSS);

  // Write components.json to project root
  const componentsJsonPath = path.join(outputDir, 'components.json');
  await fs.writeFile(componentsJsonPath, JSON.stringify(componentsJson, null, 2));

  // Write menu-variants.ts
  const menuVariantsPath = path.join(componentsDir, 'menu-variants.ts');
  await fs.writeFile(menuVariantsPath, menuVariants);

  // Write tokens.json with full structure
  const tokensJson = {
    meta: {
      generator: 'spec-flow-shadcn-bridge',
      version: '1.0.0',
      generated: new Date().toISOString(),
      config: {
        stylePreset,
        baseColor,
        primaryHue,
        themeMode,
        iconLibrary,
        fontFamily,
        borderRadius,
        menuColor,
        menuAccent,
      },
    },
    colors: {
      primary: primaryScale,
      neutral: neutralScale,
    },
    menu: menuTokens,
    shadcn: {
      style: STYLE_PRESETS[stylePreset]?.style || 'default',
      radius,
      iconLibrary: ICON_PACKAGES[iconLibrary]?.config || 'lucide',
    },
  };

  const tokensJsonPath = path.join(designDir, 'tokens.json');
  await fs.writeFile(tokensJsonPath, JSON.stringify(tokensJson, null, 2));

  return {
    files: {
      shadcnCSS: cssPath,
      componentsJson: componentsJsonPath,
      menuVariants: menuVariantsPath,
      tokensJson: tokensJsonPath,
    },
    config: {
      stylePreset,
      baseColor,
      primaryHue,
      radius,
      themeMode,
      iconLibrary: ICON_PACKAGES[iconLibrary],
      fontFamily: FONT_CONFIG[fontFamily],
      menuColor,
      menuAccent,
    },
    brownfield: brownfieldResults,
  };
}

// ============================================================================
// CLI Entry Point
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  // Parse arguments
  const configPath = args.includes('--config') ? args[args.indexOf('--config') + 1] : null;
  const brownfieldDir = args.includes('--brownfield') ? args[args.indexOf('--brownfield') + 1] : null;
  const outputDir = args.includes('--output') ? args[args.indexOf('--output') + 1] : process.cwd();

  console.log('🎨 shadcn/ui Token Bridge Generator');
  console.log('');

  let config = {};

  // Load config file if provided
  if (configPath) {
    try {
      const configContent = await fs.readFile(configPath, 'utf-8');
      config = JSON.parse(configContent);
      console.log(`✅ Loaded config from: ${configPath}`);
    } catch (error) {
      console.error(`❌ Failed to load config: ${error.message}`);
      process.exit(1);
    }
  }

  // Add brownfield scan path
  if (brownfieldDir) {
    config.brownfieldScan = brownfieldDir;
    console.log(`🔍 Brownfield scan: ${brownfieldDir}`);
  }

  config.outputDir = outputDir;

  // Generate tokens
  console.log('\n🔧 Generating shadcn tokens...');
  const result = await generateShadcnTokens(config);

  // Report results
  console.log('\n✅ Generated files:');
  for (const [name, path] of Object.entries(result.files)) {
    console.log(`   ${name}: ${path}`);
  }

  console.log('\n📊 Configuration:');
  console.log(`   Style:   ${result.config.stylePreset}`);
  console.log(`   Color:   ${result.config.baseColor} (hue: ${result.config.primaryHue})`);
  console.log(`   Radius:  ${result.config.radius}`);
  console.log(`   Theme:   ${result.config.themeMode}`);
  console.log(`   Icons:   ${result.config.iconLibrary?.package || 'lucide-react'}`);
  console.log(`   Menu:    ${result.config.menuColor} bg, ${result.config.menuAccent} accent`);

  if (result.brownfield) {
    console.log('\n🔍 Brownfield scan results:');
    const colorCount = Object.keys(result.brownfield.colorSummary || {}).length;
    console.log(`   Found ${colorCount} unique colors`);
    if (result.brownfield.existing.tailwindConfig) {
      console.log(`   ✓ tailwind.config found`);
    }
    if (result.brownfield.existing.tokensJSON) {
      console.log(`   ✓ existing tokens.json found`);
    }
  }

  console.log('\n🎉 shadcn token generation complete!');
  console.log('\n📋 Next steps:');
  console.log('   1. Import shadcn-variables.css in globals.css');
  console.log('   2. Install icon library: pnpm add ' + (result.config.iconLibrary?.package || 'lucide-react'));
  console.log('   3. Add components: npx shadcn@latest add button');
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { generateOKLCHScale, generateNeutralScale, generateMenuTokens, hexToOKLCH, oklchToHex };

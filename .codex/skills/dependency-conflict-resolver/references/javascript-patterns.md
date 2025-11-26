# JavaScript Dependency Conflict Patterns (npm/yarn/pnpm)

## Common Conflict Scenarios

### 1. React Version Mismatch

**Problem:**
```bash
npm install react@18.0.0
# Peer dependency conflict: react-dom@17.0.2 requires react ^17.0.0
```

**Diagnosis:**
```bash
npm ls react
npm ls react-dom
```

**Resolution:**
```bash
# Option 1: Upgrade react-dom (recommended)
npm install react@18.0.0 react-dom@18.0.0

# Option 2: Downgrade react
npm install react@17.0.2

# Option 3: Use overrides (npm 8.3+)
# Add to package.json:
{
  "overrides": {
    "react": "18.0.0",
    "react-dom": "18.0.0"
  }
}
```

### 2. Plugin Peer Dependency Conflicts (ESLint, Babel, Webpack)

**Problem:**
```bash
npm install eslint-plugin-react@latest
# Peer dependency warning: requires eslint ^8.0.0, found 7.32.0
```

**Diagnosis:**
```bash
npm ls eslint
npm why eslint
```

**Resolution:**
```bash
# Check if upgrade is safe
npm outdated eslint

# Upgrade ESLint if compatible
npm install eslint@^8.0.0

# If breaking changes, use legacy peer deps temporarily
npm install eslint-plugin-react --legacy-peer-deps
# Then plan ESLint upgrade separately
```

### 3. Duplicate Dependencies at Different Major Versions

**Problem:**
```bash
npm ls lodash
# Shows:
# ├─┬ package-a@1.0.0
# │ └── lodash@4.17.21
# └─┬ package-b@2.0.0
#   └── lodash@3.10.1
```

**Impact:**
- Increased bundle size (two versions of lodash)
- Potential runtime conflicts if global state is involved

**Resolution:**
```bash
# Option 1: Use overrides to force single version
{
  "overrides": {
    "lodash": "4.17.21"
  }
}

# Option 2: Update package-b to use lodash@4
# (Check package-b repository for updates)

# Option 3: Use npm dedupe
npm dedupe
```

### 4. Monorepo Workspace Conflicts

**Problem:**
```bash
# In pnpm workspace
# packages/app/package.json requires shared-lib@^1.0.0
# packages/admin/package.json requires shared-lib@^2.0.0
```

**Diagnosis:**
```bash
pnpm why shared-lib
pnpm list shared-lib --depth=Infinity
```

**Resolution:**
```bash
# Align workspace packages to same version
# In root package.json:
{
  "pnpm": {
    "overrides": {
      "shared-lib": "^2.0.0"
    }
  }
}

# Or use workspace protocol
# In packages/app/package.json:
{
  "dependencies": {
    "shared-lib": "workspace:*"
  }
}
```

## Security Vulnerability Patterns

### 1. Critical Vulnerability with No Patch

**Scenario:**
```bash
npm audit
# Found critical vulnerability in package@1.2.3
# No patch available
```

**Resolution Process:**
1. **Assess exploitability:**
   ```bash
   npm audit --json | grep -A 10 "critical"
   # Check CVE details, affected versions, exploit conditions
   ```

2. **Check for alternatives:**
   - Search npm for similar packages
   - Check GitHub for forks with patches
   - Consider vendor code temporarily

3. **Temporary mitigation:**
   ```bash
   # Use npm overrides to force a specific version
   # Or add to .npmrc:
   audit-level=moderate
   # (Only if vulnerability is not exploitable in your context)
   ```

### 2. Transitive Vulnerability (Deep Dependency)

**Scenario:**
```bash
# Your app doesn't use vulnerable-package directly
# app → express → body-parser → vulnerable-package@1.0.0
```

**Resolution:**
```bash
# Option 1: Use overrides to patch deep dependency
{
  "overrides": {
    "vulnerable-package": "1.0.1"
  }
}

# Option 2: Wait for upstream update
# Check express/body-parser for updates

# Option 3: Submit PR to upstream dependency
# Or use a patched fork temporarily
```

### 3. Dev Dependency Vulnerability (Low Risk)

**Scenario:**
```bash
npm audit
# Found high vulnerability in webpack-dev-server
# (Only used in development, not production)
```

**Assessment:**
- **Risk:** Low (dev-only, not in production bundle)
- **Action:** Update when convenient, not urgent
- **CI/CD:** May want to suppress dev-only audit warnings in production builds

**Resolution:**
```bash
# Update dev dependency
npm install --save-dev webpack-dev-server@latest

# Or add audit exception in CI
npm audit --production
```

## Version Constraint Best Practices

### Semver Range Selection

```json
{
  "dependencies": {
    // Recommended for libraries (strict)
    "stable-lib": "~1.2.3",  // Patch updates only (1.2.x)

    // Recommended for applications (flexible)
    "framework": "^1.2.3",   // Minor updates (1.x.x)

    // Pin exact version (rare, for critical packages)
    "security-critical": "1.2.3",

    // Avoid wildcards in production
    "bad-practice": "*"      // ❌ Don't do this
  }
}
```

### Using npm Overrides (npm 8.3+)

```json
{
  "overrides": {
    // Force specific version globally
    "lodash": "4.17.21",

    // Force version for specific package only
    "package-a": {
      "lodash": "4.17.21"
    },

    // Nested override
    "package-b": {
      "package-c": {
        "lodash": "4.17.21"
      }
    }
  }
}
```

### Using Yarn Resolutions

```json
{
  "resolutions": {
    "lodash": "4.17.21",
    "package-a/lodash": "4.17.21",
    "**/lodash": "4.17.21"  // All instances
  }
}
```

### Using pnpm Overrides

```json
{
  "pnpm": {
    "overrides": {
      "lodash": "4.17.21",
      "package-a>lodash": "4.17.21"
    }
  }
}
```

## Diagnostic Commands Reference

```bash
# Show dependency tree
npm ls
npm ls <package>
npm ls --depth=0  # Only top-level

# Explain why package is installed
npm why <package>
npm explain <package>

# Check for outdated packages
npm outdated
npm outdated --json

# Security audit
npm audit
npm audit --json
npm audit fix          # Auto-fix vulnerabilities
npm audit fix --force  # May introduce breaking changes

# Deduplicate dependencies
npm dedupe

# Validate package.json
npm install --dry-run

# Clean install (use in CI/CD)
npm ci

# Check for missing/extraneous packages
npm prune
```

## Troubleshooting Flowchart

```
Peer dependency conflict?
├─ Yes → Check if versions are semver compatible
│        ├─ Compatible → Use overrides
│        └─ Incompatible → Upgrade peer dependency or downgrade package
│
├─ Duplicate dependencies?
│  └─ Run `npm dedupe` → Check if reduces duplicates
│     └─ Still duplicates? → Use overrides to force version
│
├─ Security vulnerability?
│  ├─ Patch available? → Run `npm audit fix`
│  └─ No patch? → Check for alternative package or use override
│
└─ Version constraint violation?
   └─ Adjust version range in package.json or use overrides
```

## Real-World Examples

### Example 1: Next.js + React 18 Upgrade

**Before:**
```json
{
  "dependencies": {
    "next": "12.1.0",
    "react": "17.0.2",
    "react-dom": "17.0.2"
  }
}
```

**Conflict:**
```bash
npm install react@18.0.0 react-dom@18.0.0
# Error: next@12.1.0 has peer dependency react ^17.0.0
```

**Resolution:**
```bash
# Check Next.js compatibility
npm view next versions --json | grep 18

# Upgrade Next.js to version that supports React 18
npm install next@12.2.0 react@18.0.0 react-dom@18.0.0
```

### Example 2: TypeScript Version Conflict

**Problem:**
```bash
npm install @types/node@latest
# Conflict: typescript@4.5.0 incompatible with @types/node@18.x
```

**Resolution:**
```bash
# Check TypeScript version
npm ls typescript

# Upgrade TypeScript
npm install typescript@latest

# Or downgrade @types/node
npm install @types/node@17
```

### Example 3: Webpack Plugin Ecosystem

**Problem:**
Multiple webpack plugins requiring different webpack major versions

**Resolution:**
```bash
# Identify webpack version requirement
npm why webpack
npm ls webpack

# Upgrade all plugins to latest compatible with webpack 5
npm install webpack@5 \
  html-webpack-plugin@latest \
  css-loader@latest \
  babel-loader@latest

# Check peer dependencies
npm ls --all | grep UNMET
```

---
name: dependency-conflict-resolver
description: "Detect and resolve package dependency conflicts before installation. Auto-trigger when installing/upgrading packages (npm install, pip install, etc.). Validates peer dependencies, version compatibility, security vulnerabilities. Suggests conflict resolution (upgrade, downgrade, alternative package). Prevents: conflicting versions, security vulnerabilities, broken builds from incompatible dependencies."
allowed-tools: Read, Bash
---

# Dependency Conflict Resolver: Package Compatibility Validator

**Purpose**: Prevent dependency conflicts and security vulnerabilities before they break the build.

**Philosophy**: "Dependencies conflict silently. Detect conflicts early, resolve systematically, keep builds stable."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### Package Installation
- "npm install [package]"
- "pnpm add [package]"
- "yarn add [package]"
- "pip install [package]"
- "uv add [package]"

### Package Upgrades
- "npm update"
- "upgrade [package]"
- "update dependencies"
- "bump version"

### Dependency Changes
- "add dependency"
- "install [library]"
- "require [package]"

---

## Conflict Detection Rules

### 1. Peer Dependency Conflicts (Node.js)

**Check before installing**:
```bash
# Example: Installing react-router-dom
PACKAGE="react-router-dom"
VERSION="6.20.0"

# 1. Read package.json peer dependencies
PEER_DEPS=$(npm info "$PACKAGE@$VERSION" peerDependencies --json 2>/dev/null)

# 2. Check if peer deps are satisfied
if [ -n "$PEER_DEPS" ]; then
  echo "📋 Peer dependencies required:"
  echo "$PEER_DEPS" | jq .

  # Example: react-router-dom requires react ^18.0.0
  REQUIRED_REACT=$(echo "$PEER_DEPS" | jq -r '.react // empty')

  if [ -n "$REQUIRED_REACT" ]; then
    # Check current react version
    CURRENT_REACT=$(jq -r '.dependencies.react // .devDependencies.react' package.json)

    echo ""
    echo "Checking compatibility:"
    echo "  Required: react $REQUIRED_REACT"
    echo "  Current:  react $CURRENT_REACT"

    # Use npm semver to check compatibility
    if ! npx semver "$CURRENT_REACT" -r "$REQUIRED_REACT" >/dev/null 2>&1; then
      echo ""
      echo "❌ CONFLICT DETECTED: Peer dependency mismatch"
      echo ""
      echo "   Package: $PACKAGE requires react $REQUIRED_REACT"
      echo "   Current: react $CURRENT_REACT"
      echo ""
      echo "   Options:"
      echo "   A) Upgrade react to $REQUIRED_REACT"
      echo "   B) Use older $PACKAGE version compatible with react $CURRENT_REACT"
      echo "   C) Override peer dependency (risky - may cause runtime errors)"
      echo ""
      return 1
    fi
  fi
fi

echo "✅ Peer dependencies satisfied"
```

---

### 2. Version Range Conflicts (Python)

**Check before pip install**:
```bash
# Example: Installing sqlalchemy
PACKAGE="sqlalchemy"
VERSION="2.0.0"

# 1. Check if package already in requirements.txt with different version
EXISTING_VERSION=$(grep "^$PACKAGE==" requirements.txt | cut -d'=' -f3)

if [ -n "$EXISTING_VERSION" ]; then
  if [ "$EXISTING_VERSION" != "$VERSION" ]; then
    echo "❌ CONFLICT DETECTED: Version mismatch"
    echo ""
    echo "   Package: $PACKAGE"
    echo "   Existing: $EXISTING_VERSION (requirements.txt)"
    echo "   Proposed: $VERSION"
    echo ""
    echo "   Options:"
    echo "   A) Upgrade to $VERSION (check breaking changes)"
    echo "   B) Keep $EXISTING_VERSION (use existing version)"
    echo "   C) Pin compatible range (e.g., sqlalchemy>=1.4,<3.0)"
    echo ""
    return 1
  fi
fi

# 2. Check for conflicting transitive dependencies
pip install --dry-run "$PACKAGE==$VERSION" 2>&1 | grep -i conflict
if [ $? -eq 0 ]; then
  echo "❌ CONFLICT DETECTED: Transitive dependency conflict"
  echo ""
  echo "   Run: pip install --dry-run $PACKAGE==$VERSION"
  echo "   Review conflicts and resolve manually"
  echo ""
  return 1
fi

echo "✅ No version conflicts detected"
```

---

### 3. Security Vulnerabilities

**Check for known vulnerabilities**:
```bash
# Node.js: npm audit
if [ -f "package.json" ]; then
  echo "🔍 Running security audit..."
  AUDIT_OUTPUT=$(npm audit --json 2>/dev/null)
  CRITICAL_COUNT=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.critical // 0')
  HIGH_COUNT=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.high // 0')

  if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
    echo "❌ SECURITY VULNERABILITIES DETECTED"
    echo ""
    echo "   Critical: $CRITICAL_COUNT"
    echo "   High: $HIGH_COUNT"
    echo ""
    npm audit
    echo ""
    echo "   Options:"
    echo "   A) Run: npm audit fix (auto-fix compatible updates)"
    echo "   B) Run: npm audit fix --force (may cause breaking changes)"
    echo "   C) Review manually: npm audit"
    echo ""
    return 1
  fi

  echo "✅ No critical security vulnerabilities"
fi

# Python: pip-audit or safety
if [ -f "requirements.txt" ]; then
  if command -v pip-audit >/dev/null 2>&1; then
    echo "🔍 Running pip-audit..."
    if ! pip-audit -r requirements.txt >/dev/null 2>&1; then
      echo "❌ SECURITY VULNERABILITIES DETECTED"
      echo ""
      pip-audit -r requirements.txt
      echo ""
      echo "   Fix: Upgrade vulnerable packages to patched versions"
      echo ""
      return 1
    fi
    echo "✅ No security vulnerabilities (pip-audit)"
  fi
fi
```

---

### 4. Conflicting Transitive Dependencies

**Detect transitive conflicts**:
```bash
# Example: Package A requires lib@^1.0, Package B requires lib@^2.0
# npm/pnpm will error, but detect early

PACKAGE_A="react-query"
PACKAGE_B="@tanstack/react-query" # Renamed package, conflict!

# Check if both are in package.json
if jq -e ".dependencies[\"$PACKAGE_A\"] or .dependencies[\"$PACKAGE_B\"]" package.json >/dev/null 2>&1; then
  if jq -e ".dependencies[\"$PACKAGE_A\"] and .dependencies[\"$PACKAGE_B\"]" package.json >/dev/null 2>&1; then
    echo "❌ CONFLICT DETECTED: Duplicate/renamed packages"
    echo ""
    echo "   Package A: $PACKAGE_A"
    echo "   Package B: $PACKAGE_B"
    echo ""
    echo "   Note: @tanstack/react-query is the new name for react-query"
    echo "   Having both will cause conflicts."
    echo ""
    echo "   Fix: Remove old package, use new one"
    echo "   npm uninstall react-query"
    echo ""
    return 1
  fi
fi
```

---

## Resolution Strategies

### Strategy 1: Upgrade Conflicting Package

**When**: Minor version conflict, backward compatible
```bash
# Conflict: Current react@17.0.2, need react@^18.0.0
# Resolution: Upgrade react

echo "📋 Resolution: Upgrade react"
echo ""
echo "Steps:"
echo "1. npm install react@18"
echo "2. Test for breaking changes"
echo "3. Update related packages (react-dom@18)"
echo "4. Commit: 'chore: upgrade react 17→18 for compatibility'"
```

---

### Strategy 2: Downgrade New Package

**When**: New package requires newer dependency, but upgrade is risky
```bash
# Conflict: Installing new-lib@2.0 requires react@^18, but project on react@17
# Resolution: Use older new-lib version

echo "📋 Resolution: Use older new-lib version"
echo ""
echo "Find compatible version:"
echo "  npm info new-lib versions --json | jq '.[] | select(. | test(\"^1\"))'"
echo ""
echo "Install compatible version:"
echo "  npm install new-lib@1.9.0"
```

---

### Strategy 3: Use Alternative Package

**When**: Fundamental incompatibility, no resolution possible
```bash
# Conflict: Package X requires Python 3.11, but project locked to Python 3.9
# Resolution: Find alternative package

echo "📋 Resolution: Use alternative package"
echo ""
echo "Alternatives to $PACKAGE:"
echo "  - Alternative A (Python 3.9 compatible)"
echo "  - Alternative B (different approach)"
echo ""
echo "Research: Search GitHub, PyPI, npm for alternatives"
```

---

### Strategy 4: Override (Risky)

**When**: Absolutely necessary, understand the risks
```bash
# pnpm: Use overrides in package.json
cat <<EOF
Add to package.json:

{
  "pnpm": {
    "overrides": {
      "react": "^18.0.0"
    }
  }
}

⚠️  WARNING: Overrides bypass peer dependency checks
  - May cause runtime errors
  - Test thoroughly
  - Document why override is needed
EOF

# npm: Use --legacy-peer-deps (temporary)
echo "npm install --legacy-peer-deps $PACKAGE"
echo ""
echo "⚠️  WARNING: This ignores peer dependencies"
echo "   Only use temporarily until proper resolution"
```

---

## Integration with tech-stack.md

**Validate against documented versions**:
```bash
if [ -f "docs/project/tech-stack.md" ]; then
  # Extract documented versions
  DOCUMENTED_REACT=$(grep -A 1 "| React" docs/project/tech-stack.md | tail -1 | awk '{print $4}')

  # Compare with proposed installation
  PROPOSED_VERSION="18.2.0"

  if [ -n "$DOCUMENTED_REACT" ]; then
    MAJOR_DOCUMENTED=$(echo "$DOCUMENTED_REACT" | cut -d. -f1)
    MAJOR_PROPOSED=$(echo "$PROPOSED_VERSION" | cut -d. -f1)

    if [ "$MAJOR_DOCUMENTED" != "$MAJOR_PROPOSED" ]; then
      echo "⚠️  WARNING: Version mismatch with tech-stack.md"
      echo ""
      echo "   Documented: React $DOCUMENTED_REACT (tech-stack.md:12)"
      echo "   Proposed:   React $PROPOSED_VERSION"
      echo ""
      echo "   If upgrading, update tech-stack.md first"
    fi
  fi
fi
```

---

## Lock File Management

### Node.js (package-lock.json / pnpm-lock.yaml)

**Always commit lock files**:
```bash
# After resolving dependency conflict
echo "✅ Dependencies resolved"
echo ""
echo "Next steps:"
echo "1. Install: npm install (or pnpm install)"
echo "2. Test: npm test"
echo "3. Commit lock file:"
echo "   git add package.json package-lock.json"
echo "   git commit -m 'chore: resolve dependency conflict - upgrade react 17→18'"
```

**Lock file conflicts (git merge)**:
```bash
# If merge conflict in package-lock.json
echo "⚠️  Lock file merge conflict detected"
echo ""
echo "Resolution:"
echo "1. Delete package-lock.json"
echo "2. Run: npm install"
echo "3. Verify: npm test"
echo "4. Commit: git add package-lock.json && git commit"
```

---

### Python (requirements.txt / uv.lock)

**Pin exact versions** (recommended):
```bash
# Good: Exact versions
cat requirements.txt
# fastapi==0.110.0
# sqlalchemy==2.0.27
# pydantic==2.6.1

# Bad: Loose versions (can cause conflicts)
# fastapi>=0.100
# sqlalchemy~=2.0
```

**Generate lock file** (uv):
```bash
# Create uv.lock with exact versions
uv lock

# Commit both files
git add requirements.txt uv.lock
git commit -m "chore: lock dependencies to prevent conflicts"
```

---

## Pre-Installation Checklist

**Before installing any package**:

- [ ] Check peer dependencies (npm info [package] peerDependencies)
- [ ] Check existing version (grep package.json / requirements.txt)
- [ ] Run dry-run (npm install --dry-run / pip install --dry-run)
- [ ] Run security audit (npm audit / pip-audit)
- [ ] Check compatibility with documented tech stack (tech-stack.md)
- [ ] Review package homepage/README for breaking changes
- [ ] Test in isolated environment (before committing)

---

## Auto-Resolution Logic

**Attempt auto-resolution before prompting user**:

```bash
resolve_conflict() {
  local PACKAGE=$1
  local REQUIRED_VERSION=$2
  local CURRENT_VERSION=$3

  # Check if minor version upgrade
  MAJOR_REQUIRED=$(echo "$REQUIRED_VERSION" | cut -d. -f1)
  MAJOR_CURRENT=$(echo "$CURRENT_VERSION" | cut -d. -f1)

  if [ "$MAJOR_REQUIRED" = "$MAJOR_CURRENT" ]; then
    # Same major version - minor upgrade, likely safe
    echo "✅ Auto-resolving: Minor version upgrade"
    echo "   Upgrading $PACKAGE $CURRENT_VERSION → $REQUIRED_VERSION"
    npm install "$PACKAGE@$REQUIRED_VERSION"
    return 0
  else
    # Major version change - requires manual review
    echo "⚠️  Manual resolution required: Major version change"
    return 1
  fi
}
```

---

## Conflict Patterns & Solutions

### Pattern 1: React 17 vs 18 Ecosystem

**Common conflict**:
- New packages require React 18
- Project still on React 17

**Solution**:
```bash
# Upgrade React ecosystem together
npm install react@18 react-dom@18
npm install @types/react@18 @types/react-dom@18

# Update tech-stack.md
# Test thoroughly (React 18 has breaking changes)
```

---

### Pattern 2: ESLint Plugin Conflicts

**Common conflict**:
- ESLint plugins require specific ESLint version
- Multiple plugins require different ESLint versions

**Solution**:
```bash
# Find compatible ESLint version for all plugins
npm info eslint-plugin-A peerDependencies
npm info eslint-plugin-B peerDependencies

# Install ESLint version that satisfies both
npm install eslint@8.50.0
```

---

### Pattern 3: Python Type Hints (Pydantic v1 vs v2)

**Common conflict**:
- Pydantic v2 has breaking changes
- Some packages still require Pydantic v1

**Solution**:
```bash
# Check if packages support Pydantic v2
pip show [package] | grep Requires

# Option A: Stay on Pydantic v1 (if packages not ready)
pip install "pydantic<2.0"

# Option B: Upgrade and fix breaking changes
pip install pydantic@2
# Update code to new syntax
```

---

## Performance Impact

**Token Overhead**: ~500-1K tokens per dependency check

**Optimization**:
- Cache npm info results (avoid repeated API calls)
- Only check when actually installing (not on every task mention)
- Use --dry-run for validation (no actual install)

**Expected Duration**: < 15 seconds per check

---

## Quality Checklist

Before allowing package installation:

- [ ] Peer dependencies satisfied
- [ ] No version conflicts with existing packages
- [ ] Security audit passed (no critical/high vulnerabilities)
- [ ] Compatible with documented tech stack (tech-stack.md)
- [ ] Lock file will be updated
- [ ] Breaking changes reviewed (if major version upgrade)
- [ ] Alternative packages considered (if conflict unresolvable)

---

## Error Handling

**npm/pnpm errors**:
```bash
# If npm install fails
if ! npm install "$PACKAGE" 2>/dev/null; then
  echo "❌ Installation failed"
  echo ""
  echo "Troubleshooting:"
  echo "1. Check npm logs: npm install --verbose"
  echo "2. Clear cache: npm cache clean --force"
  echo "3. Delete node_modules: rm -rf node_modules && npm install"
  echo "4. Check for conflicting global packages"
fi
```

**pip errors**:
```bash
# If pip install fails
if ! pip install "$PACKAGE" 2>/dev/null; then
  echo "❌ Installation failed"
  echo ""
  echo "Troubleshooting:"
  echo "1. Check pip logs: pip install --verbose"
  echo "2. Upgrade pip: pip install --upgrade pip"
  echo "3. Check Python version compatibility"
  echo "4. Try with --no-cache-dir flag"
fi
```

---

## References

- **npm Peer Dependencies**: https://docs.npmjs.com/cli/v9/configuring-npm/package-json#peerdependencies
- **pnpm Overrides**: https://pnpm.io/package_json#pnpmoverrides
- **pip Dependency Resolution**: https://pip.pypa.io/en/stable/topics/dependency-resolution/
- **Semantic Versioning**: https://semver.org/

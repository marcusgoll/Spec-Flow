# Advanced Dependency Conflict Resolution

## Monorepo and Workspace Scenarios

### JavaScript Monorepo with Workspaces

**Structure:**
```
my-monorepo/
├── package.json (root)
├── packages/
│   ├── app/
│   │   └── package.json
│   ├── lib/
│   │   └── package.json
│   └── shared/
│       └── package.json
```

**Common Conflicts:**

**1. Different versions of shared dependency across workspaces**

```json
// packages/app/package.json
{
  "dependencies": {
    "lodash": "^4.17.21"
  }
}

// packages/lib/package.json
{
  "dependencies": {
    "lodash": "^3.10.1"  // ⚠️ Different major version
  }
}
```

**Resolution with pnpm:**
```yaml
# pnpm-workspace.yaml
packages:
  - 'packages/*'

# Root package.json - enforce consistent versions
{
  "pnpm": {
    "overrides": {
      "lodash": "^4.17.21"
    }
  }
}
```

**Resolution with npm/yarn workspaces:**
```json
// Root package.json
{
  "workspaces": ["packages/*"],
  "dependencies": {
    "lodash": "^4.17.21"  // Hoist to root
  }
}

// Remove lodash from individual workspace package.json files
```

**2. Workspace protocol for internal packages**

```json
// packages/app/package.json
{
  "dependencies": {
    "@my-org/lib": "workspace:*",        // Any version from workspace
    "@my-org/shared": "workspace:^1.0.0" // Semver range from workspace
  }
}
```

### Python Monorepo with Poetry

**Structure:**
```
my-monorepo/
├── pyproject.toml (root workspace)
├── services/
│   ├── api/
│   │   └── pyproject.toml
│   └── worker/
│       └── pyproject.toml
```

**Workspace Dependencies:**
```toml
# Root pyproject.toml
[tool.poetry]
name = "my-monorepo"

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.31.0"  # Shared dependency

# services/api/pyproject.toml
[tool.poetry.dependencies]
python = "^3.11"
requests = { version = "^2.31.0" }  # Must match root
django = "^4.2"

# services/worker/pyproject.toml
[tool.poetry.dependencies]
python = "^3.11"
requests = { version = "^2.31.0" }  # Must match root
celery = "^5.3"
```

**Enforcing Consistency:**
```bash
# Use constraints file
poetry export -f requirements.txt -o constraints.txt --without-hashes

# Install in each service
cd services/api
poetry install --with-constraints ../../constraints.txt
```

### Rust Workspace

**Cargo.toml (root):**
```toml
[workspace]
members = ["app", "lib", "utils"]
resolver = "2"

# Workspace-wide dependencies (Cargo 1.64+)
[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.35", features = ["full"] }
anyhow = "1.0"
```

**Member Usage:**
```toml
# app/Cargo.toml
[dependencies]
serde = { workspace = true }
tokio = { workspace = true }
lib = { path = "../lib" }
```

**Conflict Resolution:**
```bash
# Check for duplicates across workspace
cargo tree -d --workspace

# Update specific package across workspace
cargo update -p serde --workspace

# Build entire workspace
cargo build --workspace
```

## Feature Flag and Optional Dependency Conflicts

### Rust Feature Conflicts

**Problem:**
```toml
# app/Cargo.toml
[dependencies]
package-a = { version = "1.0", features = ["async"] }
package-b = { version = "1.0", features = ["sync"] }

# Both depend on shared-runtime with mutually exclusive features
```

**Resolution:**
```toml
# Explicitly enable both features on shared dependency
[dependencies]
shared-runtime = { version = "1.0", features = ["async", "sync"] }
package-a = { version = "1.0", features = ["async"] }
package-b = { version = "1.0", features = ["sync"] }
```

**Advanced: Feature Unification**
```toml
# If features truly conflict, use different crates
[dependencies]
package-a = { version = "1.0", features = ["async"], package = "package-runtime-async" }
package-b = { version = "1.0", features = ["sync"], package = "package-runtime-sync" }
```

### Python Extras Conflicts

**Problem:**
```bash
pip install package[extra1,extra2]
# extra1 requires dep-a>=2.0
# extra2 requires dep-a<2.0
```

**Resolution:**
```txt
# requirements.txt - install compatible extras only
package[extra1]

# Or create separate environments
# env1: package[extra1]
# env2: package[extra2]
```

## Platform-Specific Dependency Resolution

### Cross-Platform Node.js Packages

**package.json with platform-specific dependencies:**
```json
{
  "dependencies": {
    "cross-platform-lib": "^1.0.0"
  },
  "optionalDependencies": {
    "fsevents": "^2.3.2"  // macOS only, gracefully fails elsewhere
  }
}
```

**Using platform-specific installs:**
```bash
# Install only production deps on Linux server
npm ci --production --platform=linux

# Install with macOS-specific packages locally
npm install --platform=darwin
```

### Python Platform Wheels

**Problem:**
```bash
pip install package-with-c-extension
# No wheel for linux-aarch64 + Python 3.11
```

**Resolution:**
```bash
# Option 1: Install build dependencies
apt-get install python3-dev gcc
pip install package-with-c-extension

# Option 2: Use manylinux wheels
pip install --prefer-binary package-with-c-extension

# Option 3: Use conda (has prebuilt binaries)
conda install -c conda-forge package-with-c-extension

# Option 4: Specify platform in requirements
# requirements.txt
package-with-c-extension==1.0.0 ; platform_system == "Linux"
alternative-package==1.0.0 ; platform_system != "Linux"
```

### Rust Platform-Specific Dependencies

**Cargo.toml:**
```toml
[target.'cfg(windows)'.dependencies]
winapi = { version = "0.3", features = ["winuser"] }

[target.'cfg(unix)'.dependencies]
nix = "0.27"

[target.'cfg(target_os = "macos")'.dependencies]
core-foundation = "0.9"

# Cross-compilation
[target.x86_64-unknown-linux-gnu.dependencies]
openssl = { version = "0.10", features = ["vendored"] }
```

## Transitive Dependency Deep Conflicts

### Identifying Deep Conflicts

**JavaScript:**
```bash
# Find all versions of a package
npm ls package-name --all

# Find why a package is installed
npm why package-name

# Example output:
# app@1.0.0
# └─┬ express@4.18.0
#   └─┬ body-parser@1.20.0
#     └── deep-dep@1.5.0
#
# app@1.0.0
# └─┬ morgan@1.10.0
#   └── deep-dep@2.0.0
```

**Python:**
```bash
# Install pipdeptree
pip install pipdeptree

# Show dependency tree
pipdeptree
pipdeptree -p package-name
pipdeptree --reverse

# Find conflicts
pipdeptree --warn fail
```

**Rust:**
```bash
# Show dependency path
cargo tree -i conflicting-package

# Show all versions
cargo tree -d

# Example: Find why old version is pulled in
cargo tree -i old-package@1.0
```

### Resolving Deep Conflicts

**Strategy 1: Override at Root**

```json
// package.json (npm)
{
  "overrides": {
    "deep-dep": "^2.0.0"
  }
}
```

```toml
# Cargo.toml (Rust)
[patch.crates-io]
deep-dep = { version = "2.0.0" }
```

**Strategy 2: Update Intermediate Dependency**

```bash
# npm - update the package that pulls in old version
npm update express body-parser

# pip - upgrade transitive dependency explicitly
pip install --upgrade deep-dep
```

**Strategy 3: Submit Upstream PR**

If intermediate dependency is outdated:
1. Check repository for existing PR/issue
2. Test with newer version locally
3. Submit PR to update dependency
4. Use fork temporarily:

```json
{
  "dependencies": {
    "express": "github:your-fork/express#updated-deps"
  }
}
```

## Circular Dependency Resolution

### Detecting Circular Dependencies

**JavaScript:**
```bash
npm ls --all | grep "deduped"
# Circular dependencies show as "deduped"

# Or use madge
npx madge --circular src/
```

**Python:**
```bash
pipdeptree --graph-output png > dependencies.png
# Visual inspection for cycles

# Or use pydeps
pip install pydeps
pydeps mypackage --show-cycles
```

**Breaking Circular Dependencies:**

**Strategy 1: Extract Common Interface**
```
Before:
package-a → package-b → package-a (circular!)

After:
package-a → interface
package-b → interface
```

**Strategy 2: Lazy Import (Python)**
```python
# Instead of top-level import
from package_b import function  # Causes circular import

# Use lazy import
def my_function():
    from package_b import function  # Import when called
    return function()
```

**Strategy 3: Dependency Injection**
```javascript
// Instead of hardcoded dependency
import { ServiceB } from './service-b';

class ServiceA {
  constructor() {
    this.serviceB = new ServiceB();  // Circular!
  }
}

// Use injection
class ServiceA {
  constructor(serviceB) {
    this.serviceB = serviceB;  // Injected, breaks cycle
  }
}
```

## Version Pinning Strategies

### Development vs Production

**Development (flexible):**
```json
// package.json
{
  "dependencies": {
    "framework": "^1.2.3"  // Allow minor updates
  }
}
```

**Production (strict):**
```json
// package.json + package-lock.json (commit both)
{
  "dependencies": {
    "framework": "1.2.3"  // Exact version
  }
}

// Use npm ci in CI/CD (respects lock file exactly)
```

### Security vs Stability Tradeoff

**Aggressive updates (prioritize security):**
```bash
# Update weekly, test thoroughly
npm update
npm audit fix
```

**Conservative (prioritize stability):**
```bash
# Only update for critical vulnerabilities
npm audit --audit-level=critical
npm audit fix --force  # Only if critical found
```

**Balanced approach:**
```bash
# Update dev dependencies frequently
npm update --dev

# Update production dependencies cautiously
npm outdated --prod
# Review each, test individually
npm update --save package-name
```

## Multi-Language Project Conflicts

### Docker-Based Isolation

**Dockerfile:**
```dockerfile
# Backend (Python)
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# Frontend (Node.js)
FROM node:18 as frontend
WORKDIR /app
COPY package*.json .
RUN npm ci

# Combine
FROM python:3.11
COPY --from=frontend /app/dist /app/static
WORKDIR /app
COPY --from=0 /app .
```

**docker-compose.yml:**
```yaml
services:
  backend:
    build: ./backend
    environment:
      - DATABASE_URL=postgresql://db/app

  frontend:
    build: ./frontend
    environment:
      - API_URL=http://backend:8000

  db:
    image: postgres:15
```

This isolates dependency resolution per service.

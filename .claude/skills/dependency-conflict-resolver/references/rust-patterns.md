# Rust Dependency Conflict Patterns (Cargo)

## Common Conflict Scenarios

### 1. Feature Flag Conflicts

**Problem:**
```toml
# Cargo.toml
[dependencies]
package-a = { version = "1.0", features = ["feature-x"] }
package-b = { version = "2.0", features = ["feature-y"] }

# Both depend on shared-lib with incompatible features
```

**Diagnosis:**
```bash
cargo tree -e features
cargo tree -i shared-lib
```

**Resolution:**
```toml
# Add shared-lib explicitly with combined features
[dependencies]
shared-lib = { version = "1.0", features = ["feature-x", "feature-y"] }
package-a = "1.0"
package-b = "2.0"
```

### 2. Duplicate Dependencies with Different Versions

**Problem:**
```bash
cargo tree -d
# Shows:
# serde v1.0.150
# └── package-a v1.0.0
# serde v1.0.193
# └── package-b v2.0.0
```

**Resolution:**
```bash
# Update Cargo.lock
cargo update

# Or explicitly unify versions in Cargo.toml
[dependencies]
serde = "1.0.193"
package-a = "1.0"
package-b = "2.0"
```

### 3. Git Dependency Version Conflicts

**Problem:**
```toml
[dependencies]
package-a = { git = "https://github.com/user/repo", branch = "main" }
package-b = { git = "https://github.com/user/repo", tag = "v1.0.0" }
# ERROR: Cannot have same git dependency with different revisions
```

**Resolution:**
```toml
# Use consistent revision specifier
[dependencies]
package-a = { git = "https://github.com/user/repo", tag = "v1.0.0" }
package-b = { git = "https://github.com/user/repo", tag = "v1.0.0" }

# Or use cargo patches
[patch."https://github.com/user/repo"]
repo = { git = "https://github.com/user/repo", branch = "main" }
```

### 4. Workspace Member Version Conflicts

**Problem:**
```toml
# workspace Cargo.toml
[workspace]
members = ["app", "lib"]

# app/Cargo.toml
[dependencies]
lib = { path = "../lib", version = "1.0" }
external = "2.0"

# lib/Cargo.toml
[dependencies]
external = "1.5"
# Conflict: different versions of 'external'
```

**Resolution:**
```toml
# Root Cargo.toml - define workspace dependencies
[workspace.dependencies]
external = "2.0"

# app/Cargo.toml
[dependencies]
lib = { workspace = true }
external = { workspace = true }

# lib/Cargo.toml
[dependencies]
external = { workspace = true }
```

## Security Vulnerability Patterns

### 1. Using cargo-audit

**Installation:**
```bash
cargo install cargo-audit
```

**Basic Scan:**
```bash
cargo audit
# Fetches RustSec Advisory Database
# Reports vulnerabilities with RUSTSEC IDs
```

**Example Output:**
```
Crate:     time
Version:   0.1.45
Warning:   potential segfault in time
Title:     Potential segfault in the time crate
Date:      2020-11-18
ID:        RUSTSEC-2020-0071
Solution:  Upgrade to >=0.2.23
```

**Resolution:**
```bash
# Auto-fix (requires fix feature)
cargo install cargo-audit --features=fix
cargo audit fix

# Manual fix
cargo update -p time

# Or update Cargo.toml
[dependencies]
time = "0.3"  # Upgrade to non-vulnerable version
```

### 2. Yanked Crate Versions

**Problem:**
```bash
cargo build
# Warning: package `old-crate v1.0.0` has been yanked
```

**Resolution:**
```bash
# Update to non-yanked version
cargo update -p old-crate

# Check available versions
cargo search old-crate --limit 1

# Update Cargo.toml
[dependencies]
old-crate = "1.1"  # Use newer version
```

## Version Management Best Practices

### Cargo.toml Version Constraints

```toml
[dependencies]
# Caret (compatible updates - default)
package = "^1.2.3"  # >=1.2.3 <2.0.0
package = "1.2.3"   # Same as ^1.2.3

# Tilde (patch updates only)
package = "~1.2.3"  # >=1.2.3 <1.3.0

# Exact version
package = "=1.2.3"

# Comparison operators
package = ">=1.2.3"
package = ">=1.2.3, <2.0.0"

# Wildcard
package = "1.2.*"   # >=1.2.0 <1.3.0

# Git dependency
package = { git = "https://github.com/user/repo" }
package = { git = "https://github.com/user/repo", branch = "dev" }
package = { git = "https://github.com/user/repo", tag = "v1.0.0" }
package = { git = "https://github.com/user/repo", rev = "abc123" }

# Path dependency
package = { path = "../local-crate" }

# Optional dependency (feature flag)
optional-package = { version = "1.0", optional = true }

# Platform-specific dependency
[target.'cfg(windows)'.dependencies]
winapi = "0.3"

[target.'cfg(unix)'.dependencies]
nix = "0.27"
```

### Workspace Dependency Management

```toml
# Root Cargo.toml
[workspace]
members = ["crate-a", "crate-b"]
resolver = "2"

# Workspace-wide dependencies (Cargo 1.64+)
[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.35", features = ["full"] }

# Member crates inherit workspace dependencies
# crate-a/Cargo.toml
[dependencies]
serde = { workspace = true }
tokio = { workspace = true }
```

## Diagnostic Commands Reference

```bash
# Show dependency tree
cargo tree
cargo tree -p package-name
cargo tree -i package-name  # Inverse (what depends on package)
cargo tree -e features     # Show features
cargo tree -d              # Show duplicates only

# Update dependencies
cargo update
cargo update -p package-name
cargo update --dry-run
cargo update --workspace

# Check for outdated packages
cargo install cargo-outdated
cargo outdated
cargo outdated --workspace

# Security audit
cargo audit
cargo audit --json
cargo audit -D warnings  # Fail on warnings

# Verify lockfile
cargo verify-project

# Generate lockfile without building
cargo generate-lockfile

# Check for yanked dependencies
cargo tree --depth 1 | grep YANKED

# Check metadata
cargo metadata --format-version 1
```

## Troubleshooting Flowchart

```
Cargo dependency conflict?
│
├─ Duplicate versions?
│  ├─ Run `cargo update` → Unifies to compatible version
│  ├─ Add explicit dependency → Force specific version
│  └─ Use workspace dependencies → Share versions across members
│
├─ Feature flag conflict?
│  ├─ Add combined features → Explicitly enable all needed features
│  └─ Check feature compatibility → May need different version
│
├─ Git dependency conflict?
│  ├─ Unify revision specifier → Use same branch/tag/rev
│  └─ Use cargo patches → Override git dependencies
│
├─ Workspace version mismatch?
│  └─ Use workspace.dependencies → Share versions across workspace
│
└─ Security vulnerability?
   ├─ Run `cargo audit fix` → Auto-upgrade vulnerable crates
   └─ Manual update → Check RustSec advisory for fix version
```

## Real-World Examples

### Example 1: Tokio Version Conflict

**Problem:**
```toml
[dependencies]
axum = "0.6"  # Requires tokio ^1.25
tokio = "1.35"
old-library = "0.1"  # Requires tokio ^1.0
```

**Diagnosis:**
```bash
cargo tree -i tokio
```

**Resolution:**
```bash
# Update old-library if available
cargo update -p old-library

# Or add explicit tokio version that satisfies both
[dependencies]
tokio = { version = "1.35", features = ["full"] }
```

### Example 2: Serde Feature Conflicts

**Problem:**
```bash
cargo build
# error: feature `derive` is required by package `my-crate`
```

**Resolution:**
```toml
# Add derive feature explicitly
[dependencies]
serde = { version = "1.0", features = ["derive"] }
```

### Example 3: Workspace with Conflicting Dependencies

**Before:**
```toml
# app/Cargo.toml
[dependencies]
reqwest = "0.11"

# lib/Cargo.toml
[dependencies]
reqwest = "0.10"
```

**Resolution:**
```toml
# Root Cargo.toml
[workspace.dependencies]
reqwest = "0.11"

# app/Cargo.toml
[dependencies]
reqwest = { workspace = true }

# lib/Cargo.toml - update to use workspace version
[dependencies]
reqwest = { workspace = true }
```

### Example 4: RUSTSEC Vulnerability

**Problem:**
```bash
cargo audit
# ID:       RUSTSEC-2024-0042
# Crate:    hyper
# Version:  0.14.25
# Solution: Upgrade to >=0.14.26
```

**Resolution:**
```bash
# Update to patched version
cargo update -p hyper

# Verify fix
cargo audit
```

## Advanced Patterns

### Using cargo-patch

```toml
# Override dependencies from git
[patch.crates-io]
package-name = { git = "https://github.com/user/fork", branch = "bugfix" }

# Or use local path for development
[patch.crates-io]
package-name = { path = "../local-package" }
```

### Cargo Deny for Policy Enforcement

```bash
# Install cargo-deny
cargo install cargo-deny

# Initialize config
cargo deny init

# Check for vulnerabilities, licenses, sources
cargo deny check

# Example cargo-deny.toml
[advisories]
vulnerability = "deny"
unmaintained = "warn"

[licenses]
unlicensed = "deny"
allow = ["MIT", "Apache-2.0"]
```

### Using Alternative Registries

```toml
# .cargo/config.toml
[source.crates-io]
replace-with = "my-registry"

[source.my-registry]
registry = "https://my-registry.com/index"

# Or mirror crates.io
[source.crates-io]
replace-with = "mirror"

[source.mirror]
registry = "https://mirror.example.com/crates.io-index"
```

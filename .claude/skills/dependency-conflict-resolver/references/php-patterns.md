# PHP Dependency Conflict Patterns (Composer)

## Common Conflict Scenarios

### 1. Version Constraint Conflicts

**Problem:**
```bash
composer require package-a package-b
# Your requirements could not be resolved
# package-a requires symfony/console ^5.0
# package-b requires symfony/console ^6.0
```

**Diagnosis:**
```bash
composer show symfony/console
composer why symfony/console
composer why-not symfony/console ^6.0
```

**Resolution:**
```bash
# Option 1: Update package-a
composer require package-a:^2.0 package-b

# Option 2: Check if both can use symfony/console ^5.4 || ^6.0
# Update package.json manually, then:
composer update

# Option 3: Find alternative package
composer search "alternative to package-a"
```

### 2. PHP Version Incompatibility

**Problem:**
```bash
composer require modern-package
# modern-package requires php >=8.1 but your php version (8.0.30) does not satisfy that requirement
```

**Diagnosis:**
```bash
composer show --platform
php -v
```

**Resolution:**
```bash
# Option 1: Upgrade PHP version
# (Use system package manager or Docker)

# Option 2: Install compatible version of package
composer require "modern-package:<2.0"

# Option 3: Use --ignore-platform-reqs (development only)
composer require modern-package --ignore-platform-reqs
# Add to composer.json for permanent effect (not recommended):
{
  "config": {
    "platform-check": false
  }
}
```

### 3. Extension Requirements

**Problem:**
```bash
composer install
# package-name requires ext-gd * but it is not installed
```

**Resolution:**
```bash
# On Ubuntu/Debian
sudo apt-get install php8.1-gd

# On macOS (Homebrew)
brew install php@8.1-gd

# On Windows
# Enable in php.ini:
extension=gd

# Verify installation
php -m | grep gd

# If extension can't be installed, ignore (dev only)
composer install --ignore-platform-reqs
```

### 4. Symfony Component Version Mismatches

**Problem:**
```bash
# Common in Symfony projects
composer require symfony/mailer
# Conflict: Different Symfony components require different versions
```

**Diagnosis:**
```bash
composer show "symfony/*"
composer why symfony/http-kernel
composer depends symfony/http-kernel
```

**Resolution:**
```bash
# Update all Symfony components together
composer update "symfony/*"

# Or use Symfony Flex to manage versions
composer require symfony/flex
composer recipes
```

## Security Vulnerability Patterns

### 1. Using composer audit

**Basic Scan:**
```bash
composer audit
# Checks against PHP Security Advisories Database
# Reports vulnerabilities with CVE/GHSA IDs
```

**Example Output:**
```
Found 2 security vulnerability advisories affecting 1 package:
symfony/http-kernel (v5.4.20)
  - CVE-2023-XXXXX: HTTP Header Injection
    Fix: Upgrade to >=5.4.21
```

**Resolution:**
```bash
# Update vulnerable package
composer update symfony/http-kernel

# Update all packages
composer update

# Check again
composer audit
```

### 2. Security Advisories Blocking Installation (Composer 2.9+)

**Problem:**
```bash
composer require old-package
# Installation blocked: old-package has known security vulnerabilities
```

**Resolution:**
```bash
# Option 1: Install patched version
composer require old-package:^2.0

# Option 2: Disable security blocking (not recommended)
composer config audit.block-insecure false
composer require old-package

# Option 3: Find alternative package
composer search "alternative to old-package"
```

### 3. Conflicting Security Advisories

**Problem:**
```bash
# symfony/process has vulnerability in <5.4.46
# but another package conflicts with >=5.4.40
```

**Diagnosis:**
```bash
composer why-not symfony/process 5.4.46
```

**Resolution:**
```bash
# Update conflicting package
composer update conflicting-package symfony/process

# If no update available, temporarily use:
composer config audit.block-insecure false
# And create issue/PR for conflicting package
```

## Version Management Best Practices

### composer.json Version Constraints

```json
{
  "require": {
    "php": "^8.1",

    // Caret (compatible updates)
    "vendor/package": "^1.2.3",  // >=1.2.3 <2.0.0

    // Tilde (patch updates only)
    "vendor/package": "~1.2.3",  // >=1.2.3 <1.3.0

    // Exact version
    "vendor/package": "1.2.3",

    // Comparison operators
    "vendor/package": ">=1.2.3",
    "vendor/package": ">=1.2.3 <2.0.0",

    // Wildcard
    "vendor/package": "1.2.*",  // >=1.2.0 <1.3.0

    // Stability flags
    "vendor/package": "1.2.3@stable",
    "vendor/dev-package": "dev-main",

    // Inline alias
    "vendor/package": "dev-main as 1.0.0",

    // VCS repository
    "vendor/custom": "dev-feature-branch"
  },

  "require-dev": {
    "phpunit/phpunit": "^10.0",
    "phpstan/phpstan": "^1.10"
  },

  "repositories": [
    {
      "type": "vcs",
      "url": "https://github.com/user/fork.git"
    },
    {
      "type": "path",
      "url": "../local-package"
    }
  ]
}
```

### Using composer.lock for Reproducible Builds

```bash
# Generate/update composer.lock
composer install  # Uses existing lock file
composer update   # Updates dependencies and lock file

# Install exact versions from lock file (CI/CD)
composer install --no-dev

# Validate composer.json and composer.lock
composer validate

# Check if lock file is up to date
composer validate --with-dependencies

# Update specific package only
composer update vendor/package --with-dependencies
```

### Composer Config Best Practices

```json
{
  "config": {
    "sort-packages": true,
    "optimize-autoloader": true,
    "preferred-install": "dist",
    "platform": {
      "php": "8.1.0"
    },
    "audit": {
      "block-insecure": true
    }
  },

  "scripts": {
    "post-install-cmd": [
      "@php vendor/bin/security-checker security:check"
    ],
    "post-update-cmd": [
      "@composer audit"
    ]
  }
}
```

## Diagnostic Commands Reference

```bash
# Show package information
composer show
composer show vendor/package
composer show --installed
composer show --platform

# Dependency analysis
composer depends vendor/package     # What depends on package
composer why vendor/package         # Alias for depends
composer prohibits vendor/package   # What prevents installation
composer why-not vendor/package     # Alias for prohibits

# Update checks
composer outdated
composer outdated --direct
composer outdated --minor-only

# Validation
composer validate
composer validate --strict
composer validate --with-dependencies

# Security audit
composer audit
composer audit --format=json
composer audit --locked

# Diagnosis
composer diagnose

# Lockfile management
composer update --lock
composer update vendor/package --with-dependencies

# Dry-run (simulate without making changes)
composer update --dry-run
composer require vendor/package --dry-run
```

## Troubleshooting Flowchart

```
Composer dependency conflict?
│
├─ Version constraint conflict?
│  ├─ Run `composer why-not package version` → Identify blocker
│  ├─ Update conflicting package → Or find compatible versions
│  └─ Use alternative package → If no resolution available
│
├─ PHP version incompatibility?
│  ├─ Upgrade PHP → Use system package manager
│  ├─ Install compatible version → Use older package version
│  └─ Ignore platform reqs (dev only) → --ignore-platform-reqs
│
├─ Missing extension?
│  ├─ Install extension → apt-get/brew install php-ext
│  ├─ Enable in php.ini → Uncomment extension line
│  └─ Ignore platform reqs (dev only) → --ignore-platform-reqs
│
├─ Symfony component mismatch?
│  └─ Update all together → composer update "symfony/*"
│
└─ Security advisory blocking?
   ├─ Update to patched version → composer update package
   ├─ Find alternative package → Search for replacement
   └─ Disable blocking (last resort) → config audit.block-insecure false
```

## Real-World Examples

### Example 1: Laravel Upgrade with Package Conflicts

**Before:**
```json
{
  "require": {
    "laravel/framework": "^9.0",
    "spatie/laravel-permission": "^5.0",
    "league/flysystem-aws-s3-v3": "^2.0"
  }
}
```

**Problem:**
```bash
composer require laravel/framework:^10.0
# Conflict: spatie/laravel-permission requires illuminate/support ^9.0
```

**Resolution:**
```bash
# Check spatie package compatibility
composer show spatie/laravel-permission --all

# Update both together
composer require laravel/framework:^10.0 spatie/laravel-permission:^5.10

# Or if not compatible
composer require laravel/framework:^10.0 spatie/laravel-permission:^6.0
```

### Example 2: Symfony Console Conflict

**Problem:**
```bash
composer require symfony/console:^6.0
# Conflict: doctrine/orm requires symfony/console ^5.4
```

**Diagnosis:**
```bash
composer why-not symfony/console ^6.0
# Shows: doctrine/orm v2.13.0 conflicts
```

**Resolution:**
```bash
# Update doctrine/orm
composer require doctrine/orm:^2.14

# Or allow both versions
composer require symfony/console:"^5.4 || ^6.0"
```

### Example 3: Monolithic Package Update

**Problem:**
Multiple packages need coordinated update (e.g., Symfony ecosystem)

**Resolution:**
```bash
# Update all Symfony packages together
composer update "symfony/*" --with-all-dependencies

# Check for issues
composer audit
composer validate

# Test application
./vendor/bin/phpunit
```

### Example 4: Private Package Repository

**Setup:**
```json
{
  "repositories": [
    {
      "type": "composer",
      "url": "https://repo.packagist.com/my-org/"
    }
  ],
  "config": {
    "gitlab-domains": ["gitlab.company.com"],
    "github-protocols": ["https"]
  }
}
```

**Authentication:**
```bash
# Store credentials
composer config --global --auth http-basic.repo.packagist.com username token

# Or use environment variables
export COMPOSER_AUTH='{"http-basic":{"repo.packagist.com":{"username":"user","password":"token"}}}'
```

## Advanced Patterns

### Using composer-require-checker

```bash
# Install
composer require --dev maglnet/composer-require-checker

# Check for missing dependencies
./vendor/bin/composer-require-checker check

# Example output identifies packages used but not declared
```

### Using composer-unused

```bash
# Install
composer require --dev icanhazstring/composer-unused

# Find unused dependencies
./vendor/bin/composer-unused

# Remove unused packages
composer remove vendor/unused-package
```

### Using composer-normalize

```bash
# Install
composer require --dev ergebnis/composer-normalize

# Normalize composer.json
./vendor/bin/composer-normalize

# Add to CI
./vendor/bin/composer-normalize --dry-run
```

### Composer Scripts for Automation

```json
{
  "scripts": {
    "test": "phpunit",
    "check": [
      "@composer validate --strict",
      "@composer audit",
      "@test"
    ],
    "fix": [
      "@composer normalize",
      "@composer update --lock"
    ]
  }
}
```

Then run:
```bash
composer check
composer fix
```

### Using Prestissimo for Faster Downloads (Legacy)

```bash
# For Composer 1.x (parallel downloads)
composer global require hirak/prestissimo

# Composer 2.x has parallel downloads built-in
composer config --list | grep process-timeout
```

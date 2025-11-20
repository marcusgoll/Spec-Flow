# Security Vulnerability Assessment and Remediation Guide

## Vulnerability Severity Classification

### CVSS Scoring System

**Critical (9.0-10.0)**
- Remote code execution without authentication
- Complete system compromise
- Data breach affecting all users
- **Action**: Immediate remediation required, block deployment

**High (7.0-8.9)**
- Privilege escalation
- Authentication bypass
- Significant data exposure
- **Action**: Remediate within 24-48 hours, review deployment

**Medium (4.0-6.9)**
- Information disclosure (limited scope)
- Denial of service (limited impact)
- CSRF vulnerabilities
- **Action**: Remediate within 1-2 weeks, log and monitor

**Low (0.1-3.9)**
- Minor information disclosure
- Low-impact XSS in non-critical contexts
- Configuration weaknesses
- **Action**: Remediate during next maintenance cycle

### Contextual Risk Assessment

**Exploitability Factors:**
- Is the vulnerable code path reachable in production?
- Are there mitigating controls (WAF, rate limiting)?
- Is authentication required to exploit?
- Is the vulnerability in dev dependencies only?

**Example Decision Matrix:**

| Severity | Production Code | Dev Only | Mitigated | Priority |
|----------|----------------|----------|-----------|----------|
| Critical | ✓ | | | P0 (immediate) |
| Critical | ✓ | | ✓ | P1 (24-48h) |
| Critical | | ✓ | | P2 (next sprint) |
| High | ✓ | | | P1 (24-48h) |
| High | ✓ | | ✓ | P2 (1-2 weeks) |
| Medium | ✓ | | | P2 (1-2 weeks) |
| Low | ✓ | | | P3 (backlog) |

## Ecosystem-Specific Security Auditing

### JavaScript (npm/yarn/pnpm)

**Audit Commands:**
```bash
# Basic audit
npm audit

# JSON output for parsing
npm audit --json

# Only show vulnerabilities at or above level
npm audit --audit-level=moderate
npm audit --audit-level=high

# Production dependencies only
npm audit --production

# Attempt automatic fix
npm audit fix

# Aggressive fix (may introduce breaking changes)
npm audit fix --force
```

**Advanced: Using Snyk**
```bash
# Install Snyk
npm install -g snyk

# Authenticate
snyk auth

# Test for vulnerabilities
snyk test

# Monitor project (sends results to Snyk dashboard)
snyk monitor

# Get detailed remediation advice
snyk wizard
```

**Interpreting npm audit Output:**
```bash
npm audit --json | jq '
  .vulnerabilities |
  to_entries |
  map({
    package: .key,
    severity: .value.severity,
    via: .value.via
  })
'
```

**Creating Audit Exceptions:**
```json
// .npmrc
audit-level=moderate

// Or in package.json scripts
{
  "scripts": {
    "audit:prod": "npm audit --production --audit-level=high"
  }
}
```

### Python (pip/poetry)

**Using pip-audit:**
```bash
# Install
python -m pip install pip-audit

# Basic scan
pip-audit

# Scan requirements file
pip-audit -r requirements.txt

# JSON output
pip-audit --format json

# Auto-fix vulnerabilities
pip-audit --fix

# Ignore specific vulnerabilities (document why!)
pip-audit --ignore-vuln GHSA-xxxx-xxxx-xxxx

# Scan with different vulnerability sources
pip-audit --vulnerability-service osv
pip-audit --vulnerability-service pypi
```

**Using Safety:**
```bash
# Install
pip install safety

# Basic scan
safety check

# Scan requirements file
safety check -r requirements.txt

# JSON output
safety check --json

# Ignore vulnerabilities
safety check --ignore 12345 --ignore 67890

# Detailed report
safety check --full-report
```

**Poetry Audit (requires plugin):**
```bash
# Install audit plugin
poetry self add poetry-audit-plugin

# Run audit
poetry audit

# JSON output
poetry audit --json
```

### Rust (cargo-audit)

**Installation and Usage:**
```bash
# Install
cargo install cargo-audit

# Basic scan
cargo audit

# JSON output
cargo audit --json

# Deny warnings (fail CI on any vulnerability)
cargo audit -D warnings

# Deny specific advisory types
cargo audit -D unmaintained -D unsound

# Ignore specific advisories (document why!)
cargo audit --ignore RUSTSEC-2020-0071

# Check binary for vulnerabilities (requires fix feature)
cargo audit bin /path/to/binary
```

**Configuration (audit.toml):**
```toml
[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
ignore = [
    "RUSTSEC-2020-0071",  # Reason: Using non-vulnerable code path
]

[yanked]
enabled = true
```

**RustSec Advisory Format:**
```
RUSTSEC-YYYY-NNNN
- YYYY: Year
- NNNN: Sequential number

Example: RUSTSEC-2024-0042
```

### PHP (Composer)

**Using composer audit:**
```bash
# Basic scan (Composer 2.4+)
composer audit

# JSON output
composer audit --format=json

# Locked dependencies only
composer audit --locked

# Disable automatic security blocking
composer config audit.block-insecure false
```

**Using Local PHP Security Checker:**
```bash
# Install
composer require --dev enlightn/security-checker

# Run check
./vendor/bin/security-checker security:check

# Check specific lock file
./vendor/bin/security-checker security:check /path/to/composer.lock
```

**Configuration:**
```json
// composer.json
{
  "config": {
    "audit": {
      "block-insecure": true
    }
  },
  "scripts": {
    "post-install-cmd": [
      "@composer audit"
    ],
    "post-update-cmd": [
      "@composer audit"
    ]
  }
}
```

## Remediation Strategies

### 1. Direct Dependency Vulnerability

**Scenario:**
```bash
Package: express@4.17.0
Vulnerability: CVE-2024-XXXXX (HIGH)
Description: Prototype pollution vulnerability
Fixed in: express@4.18.2
```

**Remediation:**
```bash
# Check for breaking changes
npm view express versions
npm view express@4.18.2

# Update to patched version
npm install express@4.18.2

# Test application
npm test

# Verify fix
npm audit
```

### 2. Transitive Dependency Vulnerability

**Scenario:**
```bash
Your app doesn't use vulnerable-package directly
app → dependency-a → dependency-b → vulnerable-package@1.0.0
```

**Remediation Options:**

**Option 1: Update parent dependency**
```bash
# Check if dependency-a has update that fixes it
npm outdated dependency-a
npm update dependency-a
```

**Option 2: Use overrides**
```json
{
  "overrides": {
    "vulnerable-package": "1.0.1"
  }
}
```

**Option 3: Wait and monitor**
```bash
# If low severity and dev-only
# Create issue tracking the vulnerability
# Set reminder to check monthly
```

### 3. No Patch Available

**Scenario:**
```bash
Package: unmaintained-lib@1.0.0
Vulnerability: CVE-2024-XXXXX (CRITICAL)
Status: No fix available, package abandoned
```

**Remediation Options:**

**Option 1: Find actively maintained fork**
```bash
# Search GitHub for forks
# Check for community-maintained alternatives
npm search "alternative to unmaintained-lib"
```

**Option 2: Find alternative package**
```bash
# Research alternatives with similar functionality
# Evaluate maturity, maintenance, security track record
```

**Option 3: Vendor the code**
```bash
# Copy source into your project
# Apply security patch manually
# Document the vendoring and patch
```

**Option 4: Temporary mitigation**
```javascript
// Add input validation before calling vulnerable function
// Limit exposure through network segmentation
// Add monitoring/alerting for exploit attempts
```

### 4. False Positive / Inapplicable Vulnerability

**Scenario:**
```bash
Vulnerability reported but:
- Affects unused code path
- Requires conditions that don't exist in your app
- Is development-only dependency
```

**Assessment Process:**
1. **Read full advisory**: Understand exploit requirements
2. **Trace code path**: Confirm vulnerable code is unreachable
3. **Document decision**: Explain why it's safe to defer
4. **Add exception**: Prevent repeated alerts

**Example Documentation:**
```markdown
## Audit Exception: GHSA-xxxx-xxxx-xxxx

**Package**: lodash@4.17.20
**Vulnerability**: Prototype pollution
**Severity**: High
**Status**: Accepted Risk

**Justification**:
- Vulnerable function `merge()` is never called in our codebase
- All user input is sanitized before passing to lodash
- Upgrading would require major refactor of 15+ files
- Mitigating controls: Input validation, CSP headers

**Mitigation**:
- Added ESLint rule to prevent usage of `merge()`
- Scheduled upgrade for Q2 2025 during refactor sprint

**Reviewed by**: Security Team
**Date**: 2024-12-15
**Next review**: 2025-03-15
```

## Integrating Security Audits into CI/CD

### GitHub Actions (JavaScript)

```yaml
name: Security Audit

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=moderate

      - name: Run Snyk test
        run: npx snyk test --severity-threshold=high
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### GitLab CI (Python)

```yaml
security-audit:
  stage: test
  image: python:3.11
  before_script:
    - pip install pip-audit
  script:
    - pip-audit --format json > audit-report.json
    - pip-audit --format cyclonedx-json > sbom.json
  artifacts:
    reports:
      cyclonedx: sbom.json
    paths:
      - audit-report.json
  allow_failure: false
```

### GitLab CI (Rust)

```yaml
cargo-audit:
  stage: security
  image: rust:latest
  before_script:
    - cargo install cargo-audit
  script:
    - cargo audit -D warnings --json > cargo-audit.json
  artifacts:
    paths:
      - cargo-audit.json
    expire_in: 1 week
  allow_failure: false
```

### Jenkins (PHP)

```groovy
pipeline {
  agent any
  stages {
    stage('Security Audit') {
      steps {
        sh 'composer install'
        sh 'composer audit --format=json > audit-report.json'
        archiveArtifacts artifacts: 'audit-report.json'
      }
    }
  }
  post {
    failure {
      mail to: 'security@example.com',
           subject: "Security vulnerabilities detected: ${env.JOB_NAME}",
           body: "Check console output at ${env.BUILD_URL}"
    }
  }
}
```

## Automated Dependency Updates

### Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    groups:
      security-updates:
        dependency-type: "production"
        update-types:
          - "patch"
          - "minor"
    labels:
      - "dependencies"
      - "security"
    assignees:
      - "security-team"
    reviewers:
      - "security-team"
```

### Renovate Configuration

```json
// renovate.json
{
  "extends": ["config:base"],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"],
    "assignees": ["@security-team"]
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "matchDepTypes": ["dependencies"],
      "automerge": true,
      "automergeType": "pr",
      "requiredStatusChecks": ["test", "security-scan"]
    },
    {
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "dev dependencies"
    }
  ]
}
```

## Vulnerability Disclosure and Response

### Creating a Security Policy

**SECURITY.md:**
```markdown
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| 1.9.x   | :white_check_mark: |
| < 1.9   | :x:                |

## Reporting a Vulnerability

**DO NOT** open a public issue for security vulnerabilities.

Email: security@example.com
PGP Key: [link to public key]

Expected response time: 48 hours
Expected fix timeline: 7-14 days for high/critical

## Disclosure Policy

- Coordinated disclosure with 90-day embargo
- Credit given to reporters (unless anonymity requested)
- Security advisories published on GitHub
```

### Incident Response Checklist

When vulnerability is discovered:

1. **Assess Impact** (30 minutes)
   - [ ] Determine severity (CVSS score)
   - [ ] Identify affected versions
   - [ ] Check if exploited in wild

2. **Contain** (1-2 hours)
   - [ ] Disable vulnerable feature if possible
   - [ ] Apply WAF rules to block exploits
   - [ ] Notify incident response team

3. **Remediate** (varies by severity)
   - [ ] Develop fix
   - [ ] Test fix thoroughly
   - [ ] Prepare security advisory

4. **Deploy** (coordinated)
   - [ ] Deploy to staging
   - [ ] Validate fix
   - [ ] Deploy to production
   - [ ] Monitor for issues

5. **Communicate** (within 24 hours of fix)
   - [ ] Publish security advisory
   - [ ] Notify users via email/blog
   - [ ] Update CHANGELOG
   - [ ] Credit reporter (if applicable)

6. **Post-Mortem** (within 1 week)
   - [ ] Document timeline
   - [ ] Identify root cause
   - [ ] Implement process improvements
   - [ ] Update security training

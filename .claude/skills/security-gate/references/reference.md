# Security Gate — Reference Documentation

**Version**: 2.0
**Updated**: 2025-11-20

This document provides comprehensive reference material for the `/gate-sec` command, including security tool configurations, installation instructions, severity thresholds, and integration workflows.

---

## Table of Contents

1. [Security Tools](#security-tools)
2. [Tool Installation](#tool-installation)
3. [Severity Thresholds](#severity-thresholds)
4. [State Transitions](#state-transitions)
5. [Epic Integration](#epic-integration)
6. [Error Conditions](#error-conditions)
7. [Best Practices](#best-practices)
8. [Workflow State Schema](#workflow-state-schema)

---

## Security Tools

The security gate runs three types of security checks to ensure code meets security standards before deployment.

### SAST (Static Application Security Testing)

**Purpose**: Detect security vulnerabilities in source code without executing it.

**Tool**: Semgrep (recommended)

**What it detects:**

- SQL injection vulnerabilities
- Cross-Site Scripting (XSS)
- Path traversal
- Command injection
- Insecure deserialization
- Hardcoded secrets (basic detection)
- Authentication bypass
- Authorization issues

**Command:**

```bash
semgrep --config=auto --json .
```

**Output format**: JSON with findings including:

- Rule ID
- Severity (ERROR, WARNING, INFO)
- File path and line number
- Code snippet
- Fix suggestions

**Severity mapping:**

- **CRITICAL**: Semgrep doesn't use this level (treat ERROR as CRITICAL)
- **ERROR/HIGH**: Must fix before deployment
- **WARNING**: Should fix but not blocking
- **INFO**: Nice to fix, informational

**Blocking criteria**: Only ERROR (HIGH/CRITICAL equivalent) findings block deployment

### Secrets Detection

**Purpose**: Prevent hardcoded credentials from being committed to the repository.

**Tool 1**: git-secrets (preferred)

**What it detects:**

- AWS credentials (AKIA..., aws_secret_access_key)
- API keys in common formats
- Private keys (RSA, SSH)
- OAuth tokens
- Database passwords
- Custom patterns via configuration

**Command:**

```bash
git-secrets --scan
```

**Tool 2**: Fallback regex patterns (if git-secrets not installed)

**Patterns:**

```regex
# API keys
api_key\s*=\s*["'][^"']+["']
apiKey\s*:\s*["'][^"']+["']

# Passwords
password\s*=\s*["'][^"']+["']
PASSWORD\s*=\s*["'][^"']+["']

# AWS credentials
AKIA[0-9A-Z]{16}
aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}

# Private keys
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN OPENSSH PRIVATE KEY-----
-----BEGIN EC PRIVATE KEY-----
```

**Blocking criteria**: ANY secret detection blocks deployment (severity always CRITICAL)

### Dependency Scanning

**Purpose**: Identify known vulnerabilities in third-party dependencies.

**Node.js**: npm audit

**Command:**

```bash
npm audit --json
```

**Output**: JSON with CVE information, severity, vulnerable versions, patched versions

**Python**: pip-audit or safety

**Command:**

```bash
# pip-audit (recommended)
pip-audit --format json

# safety (alternative)
safety check --json
```

**Severity levels:**

- **CRITICAL**: CVE with CVSS score >= 9.0
- **HIGH**: CVE with CVSS score >= 7.0
- **MEDIUM**: CVE with CVSS score >= 4.0
- **LOW**: CVE with CVSS score < 4.0

**Blocking criteria**: Only CRITICAL and HIGH vulnerabilities block deployment

---

## Tool Installation

### Semgrep (SAST)

**All platforms:**

```bash
pip install semgrep
```

**Docker (alternative):**

```bash
docker pull semgrep/semgrep
```

**Verification:**

```bash
semgrep --version
```

**Configuration:**

- Default config: `--config=auto` (curated rulesets)
- Custom config: `.semgrep.yml` in repo root
- Language-specific: `--config=p/javascript`, `--config=p/python`

### git-secrets (Secrets Detection)

**macOS:**

```bash
brew install git-secrets
```

**Linux:**

```bash
git clone https://github.com/awslabs/git-secrets
cd git-secrets
sudo make install
```

**Windows (Git Bash):**

```bash
# Download git-secrets manually
# Add to PATH
```

**Setup for repository:**

```bash
cd /path/to/repo
git secrets --install
git secrets --register-aws  # Add AWS patterns
```

**Verification:**

```bash
git-secrets --version
git secrets --list
```

### npm audit (Node.js Dependencies)

**Built-in**: Comes with npm 6+

**Verification:**

```bash
npm audit --version
```

**Usage:**

```bash
npm audit                    # Human-readable output
npm audit --json             # JSON output
npm audit fix                # Auto-fix vulnerabilities
npm audit fix --force        # Apply breaking changes
```

### pip-audit (Python Dependencies)

**Installation:**

```bash
pip install pip-audit
```

**Verification:**

```bash
pip-audit --version
```

**Usage:**

```bash
pip-audit                    # Human-readable output
pip-audit --format json      # JSON output
pip-audit --fix              # Auto-fix (pip-audit 2.0+)
```

### safety (Python Dependencies - Alternative)

**Installation:**

```bash
pip install safety
```

**Verification:**

```bash
safety --version
```

**Usage:**

```bash
safety check                 # Human-readable output
safety check --json          # JSON output
```

---

## Severity Thresholds

### SAST Severity Mapping

| Semgrep Level | Gate Severity | Action               |
| ------------- | ------------- | -------------------- |
| ERROR         | CRITICAL/HIGH | **Block deployment** |
| WARNING       | MEDIUM        | Warn only            |
| INFO          | LOW           | Informational        |

**Pass criteria**: Zero ERROR-level findings

### Secrets Detection Severity

| Detection           | Gate Severity | Action               |
| ------------------- | ------------- | -------------------- |
| Any secret detected | CRITICAL      | **Block deployment** |
| No secrets          | N/A           | Pass                 |

**Pass criteria**: Zero secrets detected

### Dependency Scan Severity

| CVE CVSS Score | npm audit | pip-audit | Gate Severity | Action               |
| -------------- | --------- | --------- | ------------- | -------------------- |
| >= 9.0         | critical  | critical  | CRITICAL      | **Block deployment** |
| >= 7.0         | high      | high      | HIGH          | **Block deployment** |
| >= 4.0         | moderate  | medium    | MEDIUM        | Warn only            |
| < 4.0          | low       | low       | LOW           | Informational        |

**Pass criteria**: Zero CRITICAL and HIGH vulnerabilities

---

## State Transitions

### Success Path

```
Review → (Security gate passes) → Integrated
```

**Conditions for success:**

- SAST: 0 ERROR findings
- Secrets: 0 secrets detected
- Dependencies: 0 CRITICAL/HIGH vulnerabilities

**Automated action:**

- Update `state.yaml` with `quality_gates.security.status = passed`
- Epic state can transition from Review → Integrated

### Failure Path

```
Review → (Security gate fails) → Review (blocked)
```

**Conditions for failure:**

- SAST: 1+ ERROR findings
- Secrets: 1+ secrets detected
- Dependencies: 1+ CRITICAL/HIGH vulnerabilities

**Automated action:**

- Update `state.yaml` with `quality_gates.security.status = failed`
- Epic state remains in Review
- Display remediation instructions

**Remediation workflow:**

1. Fix security issues based on gate output
2. Re-run `/gate-sec`
3. Verify all checks pass
4. Proceed to Integrated state

---

## Epic Integration

### Parallel Gates

Security gate runs in parallel with CI gate during the Review phase:

```
Review Phase
├─ /gate-sec (Security)
└─ /gate-ci (Build/Test)
```

**Both gates must pass** to transition Review → Integrated

### Epic State Machine

```
Planning → Development → Review → Integrated → Deployed
                            ↑
                      (gate-sec blocks here if failed)
```

**Gate timing:**

- Runs after: Code complete and merged to main
- Runs before: Epic transitions to Integrated state
- Re-run: Anytime during Review phase

### state.yaml Integration

**Location**: `.spec-flow/memory/state.yaml`

**Schema:**

```yaml
quality_gates:
  security:
    status: passed # passed | failed
    timestamp: 2025-11-20T14:30:00Z
    checks:
      sast: true # true = passed, false = failed
      secrets: true
      dependencies: true
    findings:
      sast_errors: 0
      secrets_detected: 0
      critical_deps: 0
      high_deps: 0
```

**Status values:**

- `passed`: All checks passed, epic can proceed
- `failed`: One or more checks failed, epic blocked

---

## Error Conditions

### SAST HIGH/CRITICAL Issues

**Cause**: Security vulnerabilities detected in source code

**Example findings:**

- SQL injection in database query
- XSS in template rendering
- Command injection in subprocess call
- Path traversal in file operations

**Resolution:**

1. Review Semgrep output: `semgrep --config=auto .`
2. Understand the vulnerability (read Semgrep explanation)
3. Apply recommended fix
4. Re-run SAST to verify fix
5. Re-run `/gate-sec`

**Prevention:**

- Use parameterized queries (SQL injection)
- Escape user input (XSS)
- Avoid `eval()`, `exec()`, `subprocess.shell=True`
- Validate file paths against whitelist

### Secrets Detected

**Cause**: Hardcoded credentials found in code

**Example findings:**

- API keys in source files
- Database passwords in config files
- AWS credentials in scripts
- OAuth tokens in constants

**Resolution:**

1. Move secrets to environment variables (`.env`)
2. Add `.env` to `.gitignore`
3. Update code to read from `process.env` (Node.js) or `os.environ` (Python)
4. Remove secrets from git history: `git filter-branch` or `BFG Repo-Cleaner`
5. Rotate compromised credentials
6. Re-run `/gate-sec`

**Prevention:**

- Never commit `.env` files
- Use secret management (AWS Secrets Manager, HashiCorp Vault)
- Review code before commit
- Set up git pre-commit hooks with git-secrets

### Vulnerable Dependencies

**Cause**: Third-party packages with known security vulnerabilities (CVEs)

**Example findings:**

- lodash < 4.17.21 (prototype pollution)
- axios < 0.21.2 (SSRF)
- Django < 3.2.4 (SQL injection)
- requests < 2.31.0 (proxy-authorization header leak)

**Resolution:**

1. Review vulnerability details: `npm audit` or `pip-audit`
2. Update package to patched version: `npm update` or `pip install --upgrade`
3. If no patch available:
   - Check if vulnerability applies to your usage
   - Use alternative package
   - Apply manual workaround
4. Re-run dependency scan to verify fix
5. Re-run `/gate-sec`

**Prevention:**

- Update dependencies regularly (monthly)
- Use `npm audit fix` or `pip-audit --fix`
- Monitor security advisories (GitHub Dependabot, Snyk)
- Pin major versions, allow minor/patch updates

---

## Best Practices

### 1. Run Locally Before Push

**Why**: Catch issues early in development, before CI/CD

**How:**

```bash
# Before committing code
semgrep --config=auto .
git-secrets --scan
npm audit  # or pip-audit
```

**Benefit**: Faster feedback loop, avoid failed CI builds

### 2. Use Environment Variables

**Why**: Prevent hardcoded secrets from being committed

**Pattern:**

```javascript
// ❌ BAD
const apiKey = "sk-1234567890abcdef";

// ✅ GOOD
const apiKey = process.env.API_KEY;
```

**Python:**

```python
# ❌ BAD
API_KEY = "sk-1234567890abcdef"

# ✅ GOOD
import os
API_KEY = os.environ.get("API_KEY")
```

**Management:**

- Development: `.env` file (gitignored)
- Staging/Production: Cloud secret management (AWS Secrets Manager, Azure Key Vault)

### 3. Update Dependencies Regularly

**Why**: Don't accumulate security debt

**Schedule:**

- **Monthly**: Review and update dependencies
- **Immediately**: Update CRITICAL vulnerabilities
- **Quarterly**: Major version updates (with testing)

**Commands:**

```bash
# Node.js
npm outdated
npm update
npm audit fix

# Python
pip list --outdated
pip install --upgrade <package>
pip-audit --fix  # (pip-audit 2.0+)
```

### 4. Review SAST Findings

**Why**: Understand why rules triggered, avoid false positives

**Process:**

1. Read Semgrep explanation for the rule
2. Examine the code context
3. Determine if it's a true positive:
   - **True positive**: Fix the vulnerability
   - **False positive**: Add `// nosemgrep: rule-id` comment with justification
4. Document decision in code or security log

**Example:**

```javascript
// nosemgrep: javascript.lang.security.audit.eval-detected
// Safe usage: evaluating trusted mathematical expression from config file
const result = eval(trustedExpression);
```

### 5. Set Up Pre-Commit Hooks

**Why**: Prevent secrets from ever being committed

**Setup:**

```bash
# Install git-secrets
git secrets --install

# Register AWS patterns
git secrets --register-aws

# Add custom patterns
git secrets --add 'api_key\s*=\s*["'][^"']+'
git secrets --add 'password\s*=\s*["'][^"']+'
```

**Verification:**

```bash
# Test patterns
git secrets --scan
```

**Benefit**: Automatic secret detection before commit, blocks accidental commits

---

## Workflow State Schema

### Full Schema

```yaml
quality_gates:
  security:
    # Gate status
    status: passed # passed | failed
    timestamp: 2025-11-20T14:30:00Z # ISO 8601 timestamp

    # Individual check results
    checks:
      sast: true # true = passed, false = failed
      secrets: true
      dependencies: true

    # Finding counts
    findings:
      sast_errors: 0 # ERROR-level findings
      sast_warnings: 5 # WARNING-level (non-blocking)
      secrets_detected: 0 # Any secret = CRITICAL
      critical_deps: 0 # CVSS >= 9.0
      high_deps: 0 # CVSS >= 7.0
      medium_deps: 3 # CVSS >= 4.0 (non-blocking)

    # Tool versions (for audit trail)
    tools:
      semgrep_version: "1.45.0"
      git_secrets_installed: true
      npm_audit_version: "10.2.3"
```

### Status Determination Logic

```python
def determine_gate_status(checks, findings):
    """
    Determine if security gate passed or failed

    Pass criteria:
    - SAST: 0 ERROR findings
    - Secrets: 0 secrets detected
    - Dependencies: 0 CRITICAL/HIGH vulnerabilities
    """
    if not checks['sast']:
        return 'failed'  # SAST errors detected

    if not checks['secrets']:
        return 'failed'  # Secrets detected

    if not checks['dependencies']:
        return 'failed'  # Critical/High deps detected

    return 'passed'
```

### Example States

**Passing state:**

```yaml
quality_gates:
  security:
    status: passed
    timestamp: 2025-11-20T14:30:00Z
    checks:
      sast: true
      secrets: true
      dependencies: true
    findings:
      sast_errors: 0
      sast_warnings: 2
      secrets_detected: 0
      critical_deps: 0
      high_deps: 0
      medium_deps: 1
```

**Failing state (SAST errors):**

```yaml
quality_gates:
  security:
    status: failed
    timestamp: 2025-11-20T14:30:00Z
    checks:
      sast: false # Failed
      secrets: true
      dependencies: true
    findings:
      sast_errors: 3 # Blocking
      sast_warnings: 7
      secrets_detected: 0
      critical_deps: 0
      high_deps: 0
      medium_deps: 0
```

**Failing state (vulnerable dependencies):**

```yaml
quality_gates:
  security:
    status: failed
    timestamp: 2025-11-20T14:30:00Z
    checks:
      sast: true
      secrets: true
      dependencies: false # Failed
    findings:
      sast_errors: 0
      sast_warnings: 0
      secrets_detected: 0
      critical_deps: 2 # Blocking
      high_deps: 1 # Blocking
      medium_deps: 5
```

---

## References

### Official Documentation

- **Semgrep**: https://semgrep.dev/docs/
- **git-secrets**: https://github.com/awslabs/git-secrets
- **npm audit**: https://docs.npmjs.com/cli/audit
- **pip-audit**: https://pypi.org/project/pip-audit/
- **safety**: https://pyup.io/safety/

### Security Standards

- **OWASP Top 10**: https://owasp.org/Top10/
- **OWASP ASVS**: https://owasp.org/www-project-application-security-verification-standard/
- **CWE**: https://cwe.mitre.org/
- **CVSS**: https://www.first.org/cvss/

### Related Tools

- **Snyk**: https://snyk.io/ (alternative dependency scanner)
- **Bandit**: https://bandit.readthedocs.io/ (Python SAST)
- **Brakeman**: https://brakemanscanner.org/ (Ruby/Rails SAST)
- **CodeQL**: https://codeql.github.com/ (advanced SAST)

---

## Script Implementation

**Location**: `.spec-flow/scripts/bash/gate-sec.sh`

**Responsibilities:**

1. Detect project type (Node.js, Python, etc.)
2. Check if security tools are installed
3. Run SAST with Semgrep
4. Run secrets detection with git-secrets or fallback regex
5. Run dependency scanning with npm audit or pip-audit
6. Aggregate results and determine pass/fail
7. Update state.yaml with gate results
8. Display formatted output with remediation instructions

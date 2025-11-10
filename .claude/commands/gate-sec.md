# /gate.sec

**Purpose**: Security quality gate - SAST, secrets detection, dependency scanning.

**Phase**: Review

**Inputs**:
- Epic name (optional) - Track gate per-epic
- Verbose flag (optional) - Show detailed output

**Outputs**:
- Gate pass/fail status
- Updated `workflow-state.yaml` with gate results
- Detailed security findings if failed

## Command Specification

### Synopsis

```bash
/gate.sec [--epic EPIC] [--verbose]
```

### Description

Runs security checks as a blocking gate before epics can transition from Review → Integrated state. Ensures code meets security standards before deployment.

**Checks**:
1. **SAST**: Static Application Security Testing (Semgrep, CodeQL)
2. **Secrets Detection**: No hardcoded credentials (git-secrets)
3. **Dependency Scan**: No HIGH/CRITICAL vulnerabilities (npm audit, pip-audit)

**Pass Criteria**: No HIGH or CRITICAL severity issues

### Prerequisites

- Code complete and merged to main
- Epic in `Review` state

### Arguments

| Argument    | Required | Description                            |
| ----------- | -------- | -------------------------------------- |
| `--epic`    | No       | Epic name for per-epic tracking        |
| `--verbose` | No       | Show detailed security findings        |

### Examples

**Run security gate**:
```bash
/gate.sec
```

**Output (passing)**:
```
Security Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Project type: node

✅ SAST passed (no HIGH/CRITICAL issues)
✅ No secrets detected
✅ Dependencies secure

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Security gate PASSED

Epic can transition: Review → Integrated
```

**Output (failing)**:
```
Security Quality Gate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Project type: node

❌ SAST failed
✅ No secrets detected
❌ Vulnerable dependencies found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Security gate FAILED

Fix security issues before proceeding:
  • Review SAST findings: semgrep --config=auto .
  • Update vulnerable dependencies: npm audit fix

Installation:
  • Semgrep: pip install semgrep
  • git-secrets: brew install git-secrets (macOS)
  • pip-audit: pip install pip-audit (Python)
```

## Security Tools

### SAST (Static Analysis)

**Tool**: Semgrep (recommended)

**Installation**:
```bash
pip install semgrep
```

**Usage**:
```bash
semgrep --config=auto --json .
```

**Severity Levels**:
- CRITICAL: Must fix
- ERROR/HIGH: Must fix
- WARNING: Should fix
- INFO: Nice to fix

**Blocking**: Only CRITICAL/HIGH block deployment

### Secrets Detection

**Tool 1**: git-secrets (preferred)

**Installation**:
```bash
# macOS
brew install git-secrets

# Linux
git clone https://github.com/awslabs/git-secrets
cd git-secrets && make install
```

**Tool 2**: Fallback regex patterns

**Detects**:
- API keys (api_key=, apiKey=)
- Passwords (password=)
- AWS credentials (AKIA...)
- Private keys (-----BEGIN RSA PRIVATE KEY-----)

### Dependency Scanning

**Node.js**: npm audit

**Python**: pip-audit or safety

**Installation**:
```bash
# Python
pip install pip-audit safety
```

**Severity Thresholds**:
- Block on: HIGH, CRITICAL
- Warn on: MEDIUM
- Allow: LOW

## State Transitions

### Success Path

```
Review → (Security gate passes) → Integrated
```

### Failure Path

```
Review → (Security gate fails) → Review (blocked)
```

**Remediation**:
1. Fix security issues
2. Re-run `/gate.sec`
3. Proceed when passed

## Integration with Epic State Machine

**Runs parallel with**: `/gate.ci`

**Both gates must pass** to transition Review → Integrated

## Error Conditions

| Error                      | Cause                            | Resolution                           |
| -------------------------- | -------------------------------- | ------------------------------------ |
| SAST HIGH/CRITICAL issues  | Security vulnerabilities in code | Fix code issues, review Semgrep output|
| Secrets detected           | Hardcoded credentials            | Move to environment variables, .gitignore|
| Vulnerable dependencies    | Outdated packages with CVEs      | Update dependencies, apply patches    |

## Best Practices

1. **Run locally before push**: Catch issues early
2. **Use environment variables**: Never hardcode secrets
3. **Update dependencies regularly**: Don't accumulate security debt
4. **Review SAST findings**: Understand why rules triggered

## Files Modified

- `.spec-flow/memory/workflow-state.yaml` - Gate results

**Schema**:
```yaml
quality_gates:
  security:
    status: passed
    timestamp: 2025-11-10T18:30:00Z
    sast: true
    secrets: true
    dependencies: true
```

## References

- Semgrep: https://semgrep.dev/
- git-secrets: https://github.com/awslabs/git-secrets
- npm audit: https://docs.npmjs.com/cli/audit
- OWASP Top 10: https://owasp.org/Top10/

---

**Implementation**: `.spec-flow/scripts/bash/gate-sec.sh`

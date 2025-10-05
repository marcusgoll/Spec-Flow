# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

**Note**: This project is currently in active development. Once we reach v1.0.0, we will maintain security updates for the latest major version.

## Reporting a Vulnerability

We take the security of Spec-Flow seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **GitHub Security Advisories** (Preferred)
   - Navigate to the [Security tab](../../security/advisories/new)
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Direct Contact**
   - Contact the maintainer [@marcusgoll](https://github.com/marcusgoll) directly via GitHub
   - Use the subject line: `[SECURITY] Vulnerability Report`

### What to Include

Please include the following information in your report:

- **Type of vulnerability** (e.g., script injection, command injection, path traversal)
- **Affected component(s)** (e.g., specific script, template, command)
- **Step-by-step instructions to reproduce** the issue
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)

### Example Report Template

```
**Vulnerability Type**: [e.g., Command Injection]

**Affected Component**: [e.g., .spec-flow/scripts/powershell/create-new-feature.ps1]

**Description**:
[Detailed description of the vulnerability]

**Steps to Reproduce**:
1. [First step]
2. [Second step]
3. [etc.]

**Impact**:
[What could an attacker achieve? What data could be compromised?]

**Suggested Fix** (optional):
[Your proposed solution]

**Environment**:
- OS: [e.g., Windows 11]
- PowerShell Version: [e.g., 7.4.0]
- Repository Version: [e.g., commit hash or tag]
```

## Response Timeline

- **Initial Response**: Within 48 hours of your report
- **Status Update**: Within 7 days with our assessment and planned fix timeline
- **Fix & Disclosure**: Coordinated disclosure after patch is ready (typically 30-90 days)

## Security Update Process

1. **Triage**: We'll investigate and confirm the vulnerability
2. **Fix Development**: We'll develop a patch in a private repository
3. **Testing**: We'll thoroughly test the fix
4. **Coordinated Disclosure**: We'll notify you before public disclosure
5. **Release**: We'll release the patch and publish a security advisory
6. **Credit**: We'll acknowledge your contribution (if you wish)

## Scope

### In Scope

Security issues in:
- PowerShell scripts (`.spec-flow/scripts/powershell/`)
- Bash scripts (`.spec-flow/scripts/bash/`)
- Template files that could lead to code execution
- Command definitions that process user input
- Documentation that could mislead users into insecure practices

Common vulnerability types:
- Command injection
- Path traversal
- Arbitrary code execution
- Insecure file permissions
- Credential exposure
- Dependency vulnerabilities (if any are added)

### Out of Scope

The following are **not** considered security vulnerabilities:
- Issues in third-party tools (Claude Code, Cursor, Windsurf, etc.)
- Vulnerabilities requiring physical access to the machine
- Social engineering attacks
- Issues in user-generated specs or custom scripts
- Denial of service via resource exhaustion (this is a local tool)

## Security Best Practices for Users

When using Spec-Flow, we recommend:

1. **Review scripts before running** - Especially if cloning from a fork or untrusted source
2. **Use settings.local.json** - Keep your allow/deny rules in the local settings file (not tracked in git)
3. **Limit Claude Code permissions** - Only grant access to directories you want Claude to modify
4. **Keep PowerShell/Bash updated** - Use the latest stable versions
5. **Avoid storing secrets** - Never commit API keys, tokens, or credentials to specs
6. **Review PRs carefully** - Check for malicious changes in scripts and templates

## Known Security Considerations

### Script Execution
- PowerShell and Bash scripts execute with the permissions of the user running them
- Always review scripts before execution, especially when obtained from untrusted sources
- Use `-WhatIf` flags (where available) to preview changes before applying them

### User Input
- Feature names and spec content are user-provided
- Scripts sanitize inputs to prevent command injection
- Validate that sanitization is working in your environment

### File Operations
- Scripts create and modify files in your working directory
- Ensure you have backups before running destructive operations
- Use version control (git) to track all changes

## Responsible Disclosure

We ask that you:
- Give us reasonable time to fix the issue before public disclosure
- Avoid exploiting the vulnerability beyond what's necessary to demonstrate it
- Act in good faith to avoid privacy violations, data destruction, or service interruption

We commit to:
- Respond promptly to your report
- Keep you informed of our progress
- Credit you for the discovery (unless you prefer anonymity)
- Fix the issue as quickly as possible

## Security Hall of Fame

We'll acknowledge security researchers who responsibly disclose vulnerabilities here:

<!--
Example entry:
- **[Researcher Name](https://github.com/username)** - Reported command injection in create-new-feature.ps1 (Fixed in v1.1.0)
-->

*No vulnerabilities reported yet. Be the first!*

## Questions?

If you have questions about this security policy or the project's security posture, please open a [public discussion](../../discussions) (for non-sensitive questions) or contact the maintainer directly.

---

**Last Updated**: 2025-10-03
**Version**: 1.0

# Security Policy

## Supported Versions

We release security updates for the following versions of {{PROJECT_NAME}}:

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < latest | :x:                |

**Note**: We only support the latest release. Please update to the newest version to receive security patches.

## Reporting a Vulnerability

**We take security seriously.** If you discover a security vulnerability, please follow responsible disclosure:

### DO NOT

- **Do NOT** open a public GitHub issue
- **Do NOT** disclose the vulnerability publicly before it's fixed
- **Do NOT** exploit the vulnerability beyond proof-of-concept

### DO

1. **Email us privately**:
   - Email: `security@[DOMAIN]` (or maintainer's email)
   - Subject: `[SECURITY] Brief description`
   - Include:
     - Description of vulnerability
     - Steps to reproduce
     - Potential impact
     - Suggested fix (if any)
     - Your contact information

2. **Use encrypted communication** (if possible):
   - PGP key: [If applicable, link to PGP key]
   - ProtonMail: [If applicable]

3. **Allow time for fix**:
   - We aim to acknowledge within **48 hours**
   - We aim to provide initial assessment within **7 days**
   - We aim to release fix within **30 days** (depending on severity)

### What to Expect

1. **Acknowledgment**: We'll confirm receipt of your report within 48 hours
2. **Assessment**: We'll investigate and determine severity (Critical/High/Medium/Low)
3. **Updates**: We'll keep you informed of progress (at least weekly)
4. **Fix**: We'll develop, test, and deploy a fix
5. **Disclosure**: We'll coordinate public disclosure with you
6. **Credit**: We'll credit you in release notes (unless you prefer anonymity)

### Severity Levels

**Critical** (CVSS 9.0-10.0):
- Remote code execution
- Authentication bypass
- Data breach affecting all users
- **Response time**: 24-48 hours

**High** (CVSS 7.0-8.9):
- Privilege escalation
- SQL injection
- Cross-site scripting (stored)
- **Response time**: 7 days

**Medium** (CVSS 4.0-6.9):
- Cross-site scripting (reflected)
- Cross-site request forgery
- Information disclosure (limited)
- **Response time**: 14 days

**Low** (CVSS 0.1-3.9):
- Minor information leaks
- Non-exploitable edge cases
- **Response time**: 30 days

## Security Measures

### Infrastructure

**Hosting**: {{DEPLOY_PLATFORM}}
- **Encryption at rest**: All databases encrypted (AES-256)
- **Encryption in transit**: TLS 1.3 minimum
- **Backups**: Daily encrypted backups, 30-day retention
- **Access control**: MFA required for production access

**Database**: {{DATABASE}}
- **Row-Level Security**: Enabled
- **SQL injection protection**: Parameterized queries only
- **Connection encryption**: SSL/TLS required

**Authentication**: {{AUTH_PROVIDER}}
- **Password policy**: [Describe policy]
- **MFA**: [Available/Required for admins]
- **Session management**: [Session duration, invalidation]

### Application Security

**Input Validation**:
- All user input validated and sanitized
- Content Security Policy (CSP) headers enforced
- CORS configured with explicit origins

**Output Encoding**:
- All dynamic content escaped
- XSS protection via framework defaults

**Secrets Management**:
- No hardcoded secrets
- Environment variables for configuration
- Secrets rotation policy: [Describe if applicable]

**Dependency Management**:
- Automated dependency scanning (Dependabot/Snyk)
- Monthly dependency updates
- Critical vulnerabilities patched within 48 hours

**API Security** ({{API_STYLE}}):
- Authentication required for all endpoints
- Rate limiting: [Describe limits]
- Request validation: JSON schema / OpenAPI
- Error messages: Generic (no stack traces in production)

### Data Privacy

**Compliance**: [GDPR | HIPAA | None]

**Data Collection**:
- We collect: [List what data is collected]
- We do NOT collect: [List what is not collected]

**Data Retention**:
- User data: Retained while account active + 30 days after deletion
- Logs: 30 days
- Backups: 30 days

**Data Access**:
- Users can export data: [How to export]
- Users can delete data: [How to delete]
- Data breach notification: Within 72 hours

### Third-Party Services

We integrate with the following third-party services:

| Service | Purpose | Data Shared | Security |
|---------|---------|-------------|----------|
| {{AUTH_PROVIDER}} | Authentication | Email, user_id | SOC 2 compliant |
| [Add others] | [Purpose] | [Data] | [Compliance] |

Each service is vetted for security compliance before integration.

## Security Features

### For Users

- **HTTPS Everywhere**: All connections encrypted
- **Secure Authentication**: OAuth2 / JWT with {{AUTH_PROVIDER}}
- **Data Export**: Download your data anytime
- **Account Deletion**: Permanent data removal upon request
- **Audit Logs**: [If applicable] View your account activity

### For Developers

- **Content Security Policy**: Prevents XSS attacks
- **CSRF Protection**: All state-changing requests protected
- **Rate Limiting**: Prevents abuse and DDoS
- **Secure Headers**: HSTS, X-Frame-Options, X-Content-Type-Options
- **Dependency Scanning**: Automated vulnerability checks

## Security Audits

**Last Security Audit**: [DATE] (or "Not yet performed")
**Next Scheduled Audit**: [DATE] (or "TBD")

**Audit Scope**:
- Code review
- Dependency analysis
- Infrastructure review
- Penetration testing (if applicable)

**Audit Results**: [Link to summary or "Available upon request"]

## Security Changelog

Track security-related changes here:

### [DATE] - v[VERSION]

- **Fixed**: [Brief description of vulnerability fixed]
- **Severity**: [Critical/High/Medium/Low]
- **CVE**: [CVE-XXXX-XXXXX] (if applicable)
- **Credit**: [Reporter name] (if permission granted)

---

## Bug Bounty Program

**Status**: Not currently active

We may launch a bug bounty program in the future. Check back for updates.

## Security Contact

**Primary Contact**: `security@[DOMAIN]`
**Backup Contact**: [Maintainer email]
**Response Time**: 48 hours maximum

**PGP Key**: [If applicable, link to public key]

---

## Security Best Practices for Contributors

If you're contributing to {{PROJECT_NAME}}, follow these guidelines:

1. **Never commit secrets**: Use environment variables
2. **Validate all inputs**: Trust nothing from users
3. **Use parameterized queries**: Prevent SQL injection
4. **Escape outputs**: Prevent XSS
5. **Update dependencies**: Keep packages current
6. **Review code**: Check PRs for security issues
7. **Test security**: Include security test cases

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

---

**Thank you for helping keep {{PROJECT_NAME}} secure!**

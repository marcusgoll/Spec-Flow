# Security Guidelines: Preventing Secret Exposure in Documentation

**Version**: 1.0.0
**Last Updated**: 2025-10-28
**Audience**: Workflow contributors, command authors, agent developers

---

## Overview

This document provides security guidelines for preventing secret exposure in Spec-Flow documentation, reports, and artifacts. Following these guidelines ensures that sensitive information never makes it into version control or public documentation.

## What Constitutes a Secret?

### High-Risk Secrets (Never expose)

1. **API Keys**
   - `OPENAI_API_KEY=sk-...`
   - `api_key=abc123xyz`
   - Any key for external services (Stripe, SendGrid, etc.)

2. **Authentication Tokens**
   - Bearer tokens
   - JWT tokens (`eyJ...`)
   - OAuth tokens
   - Session tokens

3. **Passwords**
   - Database passwords
   - Admin passwords
   - Service account passwords
   - `SECRET_KEY` values

4. **Database Connection Strings**
   - `postgresql://user:password@host/db`
   - `mysql://admin:secret@db.example.com`
   - Any URL with embedded credentials

5. **Deployment Tokens**
   - `VERCEL_TOKEN`
   - `RAILWAY_TOKEN`
   - `GITHUB_TOKEN`
   - `DOPPLER_TOKEN`

6. **Private Keys**
   - SSH private keys
   - TLS/SSL private keys
   - PGP private keys
   - Signing keys

7. **Cloud Provider Credentials**
   - AWS access keys (`AKIA...`)
   - AWS secret keys
   - GCP service account keys
   - Azure credentials

### Medium-Risk Information (Context-dependent)

1. **Deploy IDs**
   - Vercel deployment IDs (publicly accessible but can be sensitive)
   - Railway deployment IDs
   - Internal deployment identifiers

2. **URLs with Query Params**
   - `https://api.com/endpoint?key=abc123` (key might be sensitive)
   - URLs with embedded tokens or session IDs

3. **Environment-Specific URLs**
   - Internal API endpoints
   - Staging/development URLs (if not public)

### Safe Information (OK to document)

1. **Environment Variable Names**
   - `DATABASE_URL` (name only, not value)
   - `OPENAI_API_KEY` (name only)
   - `NEXT_PUBLIC_API_URL` (name only)

2. **Public URLs**
   - `https://example.com`
   - `https://api.example.com/docs`
   - Production URLs (without embedded secrets)

3. **Code Structure**
   - File paths (`src/services/auth.ts`)
   - Function names (`authenticate()`)
   - Line numbers (`:42`)

4. **Metrics**
   - Performance scores (Lighthouse: 95)
   - Test coverage (89%)
   - Response times (145ms)

---

## Sanitization Strategies

### 1. Use Placeholders

Replace actual values with clear placeholders:

```markdown
❌ BAD:
DATABASE_URL=postgresql://admin:MyP@ssw0rd@db.railway.app/prod

✅ GOOD:
DATABASE_URL=***REDACTED***
or
DATABASE_URL=[from environment - see Doppler]
```

### 2. Extract Domains Only

For URLs, show domain without credentials:

```markdown
❌ BAD:
API_URL: https://user:token123@api.internal.com/v1

✅ GOOD:
API_URL domain: api.internal.com (full URL in Doppler)
or
API_URL: https://***:***@api.internal.com/v1
```

### 3. Use Environment Variables

Reference env vars by name, not value:

```bash
❌ BAD:
export VERCEL_TOKEN=abc123xyz789

✅ GOOD:
export VERCEL_TOKEN=$(doppler secrets get VERCEL_TOKEN --plain)
# or
# VERCEL_TOKEN should be set in environment
```

### 4. Sanitize Command Output

Before writing to reports, sanitize output:

```bash
# Source sanitization utility
source .spec-flow/scripts/bash/sanitize-secrets.sh

# Generate report
REPORT_CONTENT=$(generate_report)

# Sanitize before writing
CLEAN_CONTENT=$(sanitize_secrets <<< "$REPORT_CONTENT")

# Write to file
echo "$CLEAN_CONTENT" > "$FEATURE_DIR/report.md"
```

---

## Using Sanitization Tools

### Bash Sanitization

**Script**: `.spec-flow/scripts/bash/sanitize-secrets.sh`

**Usage**:

```bash
# Sanitize stdin
echo "API_KEY=abc123" | .spec-flow/scripts/bash/sanitize-secrets.sh

# Sanitize file
.spec-flow/scripts/bash/sanitize-secrets.sh < input.md > output.md

# Source in scripts
source .spec-flow/scripts/bash/sanitize-secrets.sh
CLEAN=$(sanitize_secrets <<< "$DIRTY_CONTENT")
```

**Patterns detected**:

- API keys (`api_key`, `apikey`, `api-key`)
- Tokens (`token`, `bearer`, `auth_token`)
- Passwords (`password`, `pwd`, `passwd`)
- Database URLs (`postgresql://`, `mysql://`, `mongodb://`)
- URLs with credentials (`https://user:pass@host`)
- JWT tokens (`eyJ...`)
- AWS keys (`AKIA...`)
- GitHub tokens (`ghp_`, `gho_`)
- Deployment tokens (`vercel_token`, `railway_token`)
- Private keys (`-----BEGIN PRIVATE KEY-----`)

### PowerShell Sanitization

**Script**: `.spec-flow/scripts/powershell/Sanitize-Secrets.ps1`

**Usage**:

```powershell
# Sanitize string
Sanitize-Secrets -InputText "API_KEY=abc123"

# Sanitize file
Sanitize-Secrets -Path "report.md"

# Pipeline
Get-Content "input.md" | Sanitize-Secrets | Set-Content "output.md"

# In scripts
$cleanContent = $dirtyContent | Sanitize-Secrets
```

---

## Secret Detection Testing

### Automated Scanning

**Script**: `.spec-flow/scripts/bash/test-secret-detection.sh`

**Usage**:

```bash
# Scan all reports
bash .spec-flow/scripts/bash/test-secret-detection.sh

# Scan specific feature
bash .spec-flow/scripts/bash/test-secret-detection.sh specs/001-feature

# Pre-commit hook (recommended)
# Add to .git/hooks/pre-commit:
bash .spec-flow/scripts/bash/test-secret-detection.sh
```

**Exit codes**:

- `0` - No secrets detected (safe)
- `1` - Secrets detected (blocked)
- `2` - Error running scan

**Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Secret Detection Scanner
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found 15 files to scan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Secrets detected in: specs/001-feature/ship-report.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pattern: TOKEN
Line 45: vercel_token=[***REDACTED***]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scan Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files scanned: 15
Files with secrets: 1
Total secrets found: 1

❌ SECRETS DETECTED!

Action required:
1. Review the files listed above
2. Replace exposed secrets with placeholders
3. Re-run scan to verify fixes
```

---

## Guidelines for Command Authors

### When Writing Commands

1. **Never echo secret values**:

   ```bash
   ❌ echo "Token: $VERCEL_TOKEN"
   ✅ echo "Token: [set in environment]"
   ```

2. **Sanitize before writing to files**:

   ```bash
   ❌ echo "$OUTPUT" > report.md
   ✅ echo "$(sanitize_secrets <<< "$OUTPUT")" > report.md
   ```

3. **Extract domains from URLs**:

   ```bash
   ❌ echo "API URL: $FULL_URL"
   ✅ URL_DOMAIN=$(echo "$FULL_URL" | sed -E 's|https?://([^/?]+).*|\1|')
   ✅ echo "API domain: $URL_DOMAIN"
   ```

4. **Use redirection carefully**:

   ```bash
   # Avoid redirecting sensitive command output
   ❌ doppler secrets get DATABASE_URL --plain >> report.md

   # Check presence, not value
   ✅ if doppler secrets get DATABASE_URL --plain >/dev/null 2>&1; then
   ✅   echo "✅ DATABASE_URL configured"
   ✅ fi
   ```

### When Creating Reports

1. **Use templates with placeholders**:

   ```markdown
   ❌ Deployed to: https://abc123.vercel.app?token=xyz789
   ✅ Deployed to: [deployment-url]
   ```

2. **Reference configuration locations**:

   ```markdown
   ❌ OPENAI_API_KEY=sk-abc123xyz789
   ✅ OPENAI_API_KEY=[configured in Doppler: cfipros/production_api]
   ```

3. **Document commands, not values**:

   ```markdown
   ❌ export DATABASE_URL=postgresql://user:pass@host/db
   ✅ export DATABASE_URL=$(doppler secrets get DATABASE_URL --plain)
   ```

---

## Guidelines for Agent Developers

### Security Section Template

Add this section to all agent briefs that create reports:

```markdown
## SECURITY: SECRET SANITIZATION

**CRITICAL**: Before writing ANY content to report files or summaries:

**Never expose:**
- Environment variable VALUES (API keys, tokens, passwords)
- Database URLs with embedded credentials
- Deployment tokens (VERCEL_TOKEN, RAILWAY_TOKEN, GITHUB_TOKEN)
- URLs with secrets in query params
- Private keys or certificates

**Safe to include:**
- Environment variable NAMES
- URL domains without credentials
- Public deployment URLs (without embedded tokens)
- Status indicators (✅/❌)

**Use placeholders:**
- Replace actual values with `***REDACTED***`
- Use `[VARIABLE from environment]` for env vars
- Extract domains only: `https://user:pass@api.com` → `https://***:***@api.com`

**When in doubt:** Redact the value. Better to be overly cautious than expose secrets.
```

### Agent Checklist

Before finalizing an agent brief:

- [ ] Added SECURITY section
- [ ] Reviewed all examples for hardcoded secrets
- [ ] Verified report templates use placeholders
- [ ] Documented safe alternatives to exposing values
- [ ] Tested agent output with secret detection script

---

## Common Mistakes to Avoid

### 1. Echoing Doppler Output

```bash
❌ WRONG:
API_KEY=$(doppler secrets get API_KEY --plain)
echo "API Key: $API_KEY"  # Exposes secret!

✅ RIGHT:
if doppler secrets get API_KEY --plain >/dev/null 2>&1; then
  echo "✅ API_KEY configured"
else
  echo "❌ API_KEY missing"
fi
```

### 2. Including Secrets in Error Messages

```bash
❌ WRONG:
if ! verify_connection "$DATABASE_URL"; then
  echo "Failed to connect: $DATABASE_URL"  # Exposes password!
fi

✅ RIGHT:
if ! verify_connection "$DATABASE_URL"; then
  DB_HOST=$(echo "$DATABASE_URL" | sed -E 's|.*@([^/]+).*|\1|')
  echo "Failed to connect to: $DB_HOST"
fi
```

### 3. Hardcoding URLs in Templates

```markdown
❌ WRONG (ship-report-template.md):
Deployed to: https://app.cfipros.com

✅ RIGHT:
Deployed to: [production-app-url]
```

### 4. Logging Full curl Commands

```bash
❌ WRONG:
echo "Running: curl -H 'Authorization: Bearer $TOKEN' $URL"  # Exposes token!

✅ RIGHT:
echo "Running: curl -H 'Authorization: Bearer [REDACTED]' $URL"
```

---

## Testing Your Changes

### Before Committing

1. **Run secret detection**:

   ```bash
   bash .spec-flow/scripts/bash/test-secret-detection.sh
   ```

2. **Review reports manually**:

   ```bash
   grep -r "api_key\|token\|password" specs/*/artifacts/
   ```

3. **Test sanitization**:

   ```bash
   # Create test input with fake secrets
   echo "API_KEY=abc123" | .spec-flow/scripts/bash/sanitize-secrets.sh
   # Verify output: API_KEY=***REDACTED***
   ```

### Pre-Commit Hook (Recommended)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "Running secret detection scan..."
if ! bash .spec-flow/scripts/bash/test-secret-detection.sh; then
  echo ""
  echo "❌ Commit blocked: Secrets detected in files"
  echo "Fix issues and try again"
  exit 1
fi

echo "✅ No secrets detected - safe to commit"
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Incident Response

### If Secrets Are Exposed

**Immediate actions**:

1. **Rotate compromised secrets**:

   ```bash
   # Revoke old token
   # Generate new token
   # Update in Doppler
   doppler secrets set EXPOSED_TOKEN=new_value
   ```

2. **Remove from git history**:

   ```bash
   # Use git-filter-repo or BFG Repo-Cleaner
   git filter-repo --path-glob '**/report.md' --invert-paths
   ```

3. **Force push (if not public)**:

   ```bash
   git push --force origin main
   ```

4. **Document in security log**:
   - What was exposed
   - How it was exposed
   - When it was discovered
   - Actions taken
   - Prevention measures added

**Prevention**:

- Run secret detection scan before every commit
- Review all new commands and agents for secret exposure
- Test report generation with sanitization
- Update this document with lessons learned

---

## Resources

**Scripts**:

- Bash sanitization: `.spec-flow/scripts/bash/sanitize-secrets.sh`
- PowerShell sanitization: `.spec-flow/scripts/powershell/Sanitize-Secrets.ps1`
- Secret detection: `.spec-flow/scripts/bash/test-secret-detection.sh`

**Templates**:

- Report templates: `.spec-flow/templates/*-template.md`
- Agent briefs: `.claude/agents/phase/*.md`

**Documentation**:

- Architecture: `docs/architecture.md`
- Commands: `docs/commands.md`
- Contributing: `CONTRIBUTING.md`

**External Resources**:

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [Doppler Best Practices](https://docs.doppler.com/docs/best-practices)

---

## Questions?

For security concerns or questions about this guide:

1. Review this document thoroughly
2. Check existing command/agent implementations
3. Test with sanitization tools before committing
4. Open an issue: https://github.com/anthropics/claude-code/issues

**Remember**: When in doubt, redact. It's better to be overly cautious with secrets than to expose sensitive information.

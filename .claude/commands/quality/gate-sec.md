---
description: Run security quality gate (SAST, secrets detection, dependency scanning) to ensure no HIGH/CRITICAL security issues before deployment
allowed-tools: [Read, Write, Bash(.spec-flow/scripts/bash/gate-sec.sh:*), Bash(semgrep *), Bash(git-secrets *), Bash(git secrets:*), Bash(npm audit:*), Bash(pip-audit *), Bash(safety *), Bash(which:*), Bash(command -v:*), Bash(test:*), Bash(cat:*), Bash(grep:*), Bash(jq:*), Bash(yq:*)]
argument-hint: (no arguments - self-contained gate)
---

<context>
Project type: !`[ -f package.json ] && echo "node" || ([ -f requirements.txt ] && echo "python" || ([ -f Cargo.toml ] && echo "rust" || ([ -f go.mod ] && echo "go" || echo "unknown")))`

Security tools installed: !`for tool in semgrep git-secrets npm pip-audit safety; do command -v $tool >/dev/null 2>&1 && echo "$tool: yes" || echo "$tool: no"; done`

Current workflow state: !`cat .spec-flow/memory/workflow-state.yaml 2>/dev/null | grep -A10 quality_gates || echo "No workflow state found"`

Epic state: !`cat .spec-flow/memory/workflow-state.yaml 2>/dev/null | grep -A3 current_state | grep state || echo "Unknown state"`
</context>

<objective>
Security quality gate - blocking gate that runs before epics transition from Review → Integrated state.

**Checks performed:**
1. **SAST** - Static Application Security Testing (Semgrep)
2. **Secrets Detection** - No hardcoded credentials (git-secrets or regex fallback)
3. **Dependency Scan** - No HIGH/CRITICAL vulnerabilities (npm audit, pip-audit, safety)

**Pass criteria:**
- SAST: Zero ERROR-level findings
- Secrets: Zero secrets detected
- Dependencies: Zero CRITICAL/HIGH vulnerabilities

**Outputs:**
- Gate status (passed/failed)
- Updated workflow-state.yaml with security gate results
- Detailed findings and remediation instructions (if failed)

**Dependencies:**
- Git repository initialized
- Code complete and merged to main branch
- Epic in Review state (recommended timing)
- At least one security tool installed (Semgrep preferred)
</objective>

<process>
1. **Execute security gate script**:
   ```bash
   bash .spec-flow/scripts/bash/gate-sec.sh
   ```

   The gate-sec.sh script performs:
   a. **Detect project type** — Node.js (package.json), Python (requirements.txt), Rust, Go, or unknown
   b. **Check tool availability** — Verify Semgrep, git-secrets, npm audit, pip-audit installed
   c. **Run SAST** — Execute `semgrep --config=auto --json .` for static analysis
   d. **Run secrets detection**:
      - If git-secrets installed: `git-secrets --scan`
      - Fallback: Regex patterns for API keys, passwords, AWS credentials, private keys
   e. **Run dependency scan**:
      - Node.js: `npm audit --json`
      - Python: `pip-audit --format json` or `safety check --json`
   f. **Aggregate results** — Count ERROR/CRITICAL/HIGH findings across all checks
   g. **Determine pass/fail**:
      - PASS: 0 ERROR (SAST), 0 secrets, 0 CRITICAL/HIGH deps
      - FAIL: Any ERROR, secret, or CRITICAL/HIGH dep detected
   h. **Update workflow-state.yaml** — Write gate results to quality_gates.security section
   i. **Display results** — Formatted output with pass/fail status and remediation

2. **Read gate results**:
   - Load updated `.spec-flow/memory/workflow-state.yaml`
   - Extract `quality_gates.security.status` (passed or failed)
   - Extract `quality_gates.security.findings` (counts by severity)

3. **Present results to user**:

   **If PASSED:**
   ```
   Security Quality Gate
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ℹ️  Project type: {node|python|rust|go}

   ✅ SAST passed (no HIGH/CRITICAL issues)
   ✅ No secrets detected
   ✅ Dependencies secure

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ✅ Security gate PASSED

   Epic can transition: Review → Integrated
   ```

   **If FAILED:**
   ```
   Security Quality Gate
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ℹ️  Project type: {node|python|rust|go}

   ❌ SAST failed ({N} ERROR findings)
   ✅ No secrets detected
   ❌ Vulnerable dependencies found ({N} HIGH, {N} CRITICAL)

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ❌ Security gate FAILED

   Fix security issues before proceeding:
     • Review SAST findings: semgrep --config=auto .
     • Update vulnerable dependencies: npm audit fix

   Installation (if tools missing):
     • Semgrep: pip install semgrep
     • git-secrets: brew install git-secrets (macOS)
     • pip-audit: pip install pip-audit (Python)
   ```

4. **Suggest next action** based on gate status:

   **If PASSED:**
   - Epic can proceed to Integrated state
   - Both gates (security + CI) must pass for transition
   - Next: Verify CI gate also passed, then transition epic state

   **If FAILED:**
   - Epic remains in Review state (blocked)
   - Developer must fix security issues
   - Re-run `/gate-sec` after fixes
   - Provide specific remediation steps based on failure type
</process>

<verification>
Before completing, verify:
- Security gate script executed successfully
- workflow-state.yaml updated with quality_gates.security section
- Gate status matches actual scan results (passed/failed)
- Findings counts are accurate
- User presented with clear pass/fail status
- Remediation instructions provided (if failed)
</verification>

<success_criteria>
**Gate execution:**
- All security checks completed (SAST, secrets, dependencies)
- Results aggregated correctly
- Pass/fail determination matches criteria

**workflow-state.yaml update:**
- quality_gates.security.status = passed or failed
- quality_gates.security.timestamp = current ISO 8601 timestamp
- quality_gates.security.checks contains sast, secrets, dependencies booleans
- quality_gates.security.findings contains accurate counts

**User presentation:**
- Clear visual distinction between pass and fail
- Specific check results shown (✅/❌ per check)
- Remediation instructions provided for failed checks
- Tool installation commands shown if tools missing

**Epic integration:**
- Gate result enables/blocks Review → Integrated transition
- Status persists in workflow-state.yaml for epic tracking
- Both security and CI gates must pass for epic to proceed
</success_criteria>

<standards>
**Industry Standards:**
- **OWASP Top 10**: [Web Application Security Risks](https://owasp.org/Top10/)
- **CVSS**: [Common Vulnerability Scoring System](https://www.first.org/cvss/) for dependency severity
- **CWE**: [Common Weakness Enumeration](https://cwe.mitre.org/) for vulnerability categorization

**Security Tools:**
- **Semgrep**: [semgrep.dev](https://semgrep.dev/)
- **git-secrets**: [GitHub](https://github.com/awslabs/git-secrets)
- **npm audit**: [npm docs](https://docs.npmjs.com/cli/audit)
- **pip-audit**: [PyPI](https://pypi.org/project/pip-audit/)

**Workflow Standards:**
- SAST: ERROR-level findings block deployment
- Secrets: ANY detection blocks deployment (severity always CRITICAL)
- Dependencies: CRITICAL/HIGH vulnerabilities block deployment
- MEDIUM/LOW findings are warnings only (non-blocking)
- Gate results persist in workflow-state.yaml
- Re-runnable: Can execute multiple times during Review phase
</standards>

<notes>
**Script location**: `.spec-flow/scripts/bash/gate-sec.sh`

**Reference documentation**: Tool installation instructions, severity thresholds, state transitions, epic integration, error conditions, best practices, and workflow state schema are in `.claude/skills/security-gate/references/reference.md`.

**Version**: v2.0 (2025-11-20) — Refactored to XML structure, added dynamic context, tool restrictions

**Tool requirements:**
- **Minimum**: At least one security tool must be installed (Semgrep recommended)
- **Recommended**: All tools installed (Semgrep, git-secrets, npm audit or pip-audit)
- **Fallback**: Script uses regex patterns if git-secrets not available

**Parallel gates:**
- `/gate-sec` (Security) runs parallel with `/gate-ci` (Build/Test)
- Both must pass for epic to transition Review → Integrated

**State machine integration:**
```
Planning → Development → Review → Integrated → Deployed
                            ↑
                     (gate-sec blocks here if failed)
```

**Remediation workflow:**
1. Fix security issues based on gate output
2. Re-run `/gate-sec` to verify fixes
3. Verify both gates passed (security + CI)
4. Transition epic to Integrated state
</notes>

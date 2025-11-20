# Optimization Phase - Reference Documentation

## Quality Gate Criteria

### Performance

**Backend**:
- Compare actuals vs `plan.md` targets (p95, p99)
- If no targets specified: Warn, don't fail

**Frontend**:
- Bundle size within limits
- Lighthouse performance ≥ 90 (if measured)

**References**:
- [Lighthouse Scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring/)

---

### Security

**Criteria**:
- No Critical/High findings in dependency/static analysis
- API security tests not failing

**Tools**:
- **Backend**: Bandit (Python static analysis), Safety (Python dependency audit)
- **Frontend**: pnpm audit (Node dependency audit)

**References**:
- [OWASP ASVS Level 2](https://owasp.org/www-project-application-security-verification-standard/)

---

### Accessibility

**Criteria**:
- WCAG level stated in `plan.md` met (default: WCAG 2.2 AA)
- Lighthouse A11y ≥ 95 (if measured)
- Contrast requirements:
  - Text: 4.5:1 minimum
  - UI components: 3:1 minimum
- Unit tests: jest-axe passes

**References**:
- [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/)
- [Understanding Conformance Levels](https://www.w3.org/WAI/WCAG22/Understanding/conformance#levels)

---

### Code Quality

**Criteria**:
- Linters pass: ESLint (frontend), Ruff (backend)
- Type checks pass: TypeScript, mypy --strict
- Tests green: Jest (frontend), pytest (backend)
- Coverage: As reported by coverage tools

**References**:
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [pnpm Commands](https://pnpm.io/cli/patch-remove)

---

### Migrations

**Criteria**:
- All migrations have `downgrade()` function (reversible)
- `alembic check` passes (drift-free)

**References**:
- [Alembic Best Practices](https://alembic.sqlalchemy.org/en/latest/tutorial.html#create-a-migration-script)

---

### Docker Build

**Criteria**:
- `docker build` completes without errors
- Skipped if no Dockerfile present

**Validates**:
- Base image validity
- Dependencies installation
- COPY instructions
- Build arguments

**Tools**:
- Docker CLI (docker build --no-cache)

---

### Deploy Hygiene

**Criteria**:
- Artifact strategy documented (build-once, promote-many)
- Follows Twelve-Factor App principles (build/release/run)

**Note**: Advisory, not blocking

**References**:
- [The Twelve-Factor App: Build, Release, Run](https://12factor.net/build-release-run)

---

## Error Recovery

### Common Failures

#### 1. Security High/Critical Findings

**Error**: Critical or High severity findings in security scan

**Fix**:
```bash
# View security logs
cat specs/{slug}/security-backend.log
cat specs/{slug}/security-deps.log
cat specs/{slug}/security-frontend.log

# Update dependencies
cd api && uv pip install --upgrade safety
pnpm --filter @app update

# Re-run optimize
/optimize
```

---

#### 2. Type Check Failures

**Error**: TypeScript or mypy errors found

**Fix**:
```bash
# View type errors
cat specs/{slug}/tsc.log
cat specs/{slug}/mypy.log

# Fix types in code
# Re-run optimize
/optimize
```

---

#### 3. Accessibility Score < 95

**Error**: Lighthouse accessibility score below threshold

**Fix**:
```bash
# View Lighthouse report
cat specs/{slug}/lh-perf.json | jq '.categories.accessibility'

# Check specific failures
cat specs/{slug}/lh-perf.json | jq '.audits | to_entries | .[] | select(.value.score < 1) | {key, title: .value.title, score: .value.score}'

# Fix accessibility issues
# Re-run optimize
/optimize
```

---

#### 4. Migration Not Reversible

**Error**: Migration missing `downgrade()` function

**Fix**:
```bash
# Find migrations without downgrade
cd api
grep -L "def downgrade" alembic/versions/*.py

# Add downgrade() function to migrations
# Re-run optimize
/optimize
```

---

#### 5. Docker Build Failure

**Error**: Docker build fails

**Fix**:
```bash
# View build errors
cat specs/{slug}/docker-build.log

# Common fixes:
# - Check base image is valid
# - Verify all COPY sources exist
# - Ensure all dependencies are listed
# - Check build args are defined

# Test build manually
docker build --no-cache -t test-build .

# Re-run optimize
/optimize
```

---

## Tools and Thresholds

### Lighthouse

**Categories and Scoring**:
- Performance threshold: ≥ 90
- Accessibility threshold: ≥ 95
- Scores documented in [Google's docs](https://developer.chrome.com/docs/lighthouse/)

**Usage**:
```bash
lighthouse http://localhost:3000 --only-categories=performance,accessibility --preset=desktop --output=json
```

---

### Playwright Smoke Tests

**Tag Filtering**:
```bash
# Filter by tag/title
pnpm playwright test --grep @smoke
```

**References**:
- [Playwright Global Setup](https://playwright.dev/docs/test-global-setup-teardown)
- [Currents Playwright Tags](https://docs.currents.dev/guides/playwright-tags)

---

### Unit Accessibility (jest-axe)

**Automated WCAG checks in tests**:
```bash
# Included in standard test run
pnpm test
```

---

## Alternative Modes

### Lite Mode (CI-Fast)

**Use case**: PR checks to cut CI time

**Run only**:
- Security
- Code review
- Migrations

**Gate perf/a11y in staging** with Lighthouse CI artifacts

```bash
# Lite mode example
/optimize --lite
# Runs only security, code-review, migrations checks
```

---

### Strict Mode (Release Branch)

**Use case**: Enforce explicit performance targets

**Behavior**:
- Fail if `plan.md` missing performance targets
- Enforce explicit p95, p99, LCP, TTI, bundle size

```bash
# Strict mode example
/optimize --strict
# Fails if plan.md missing performance targets
```

---

### Frontend-Only Lane

**Use case**: Skip backend checks if only frontend modified

**Detection**:
```bash
# Auto-detect changed files
CHANGED_FILES=$(git diff --name-only origin/main...HEAD)

if echo "$CHANGED_FILES" | grep -q "^api/"; then
  # Run backend checks
fi

if echo "$CHANGED_FILES" | grep -q "^apps/app/"; then
  # Run frontend checks
fi
```

---

## Integration Examples

### CI Integration

```yaml
# .github/workflows/optimize.yml
name: Optimize
on: [pull_request]
jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run optimize
        run: python .spec-flow/scripts/spec-cli.py optimize
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: optimization-reports
          path: |
            specs/*/security-*.log
            specs/*/optimization-*.md
            specs/*/lh-perf.json
```

---

### Performance Targets in plan.md

```markdown
## [PERFORMANCE TARGETS]

- API p95 latency: < 200ms
- API p99 latency: < 500ms
- Bundle size (gzip): < 150kB
- Lighthouse performance: ≥ 90
- Lighthouse accessibility: ≥ 95
```

---

### Artifact Strategy in plan.md

```markdown
## [ARTIFACT STRATEGY]

**Build**: Single Docker image tagged with commit SHA
**Release**: Promote same image to staging, then production
**Run**: Environment-specific config via env vars

See: https://12factor.net/build-release-run
```

---

## Notes

**Why This Approach Works**:
1. **No duplication** - One parallel dispatch, one aggregator
2. **No fake metrics** - Everything writes a file or didn't happen
3. **No tool cargo-culting** - Check if tools exist, don't assume
4. **Hard blockers are crisp** - Security High/Critical, A11y fail, types/lints fail, unreversible migrations

**What Was Removed**:
- Elaborate CLI ceremony
- Feature flags complexity (belongs in specs)
- Analytics tracking (not optimization concern)
- Repetitive UI route scanning
- Vibes-based thresholds (replaced with citations to standards)

---

**Version**: 2.0
**Last Updated**: 2025-11-19

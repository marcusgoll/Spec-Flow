# /metrics.dora

**Purpose**: Display real-time DORA metrics dashboard.

**Phase**: Monitoring

**Inputs**:
- Days to analyze (optional, default: 30)
- Output format (optional, default: text)

**Outputs**:
- DORA metrics (Deployment Frequency, Lead Time, CFR, MTTR)
- Performance tier (Elite, High, Medium, Low)
- Trend analysis

## Command Specification

### Synopsis

```bash
/metrics.dora [--days DAYS] [--format FORMAT]
```

### Description

Calculates and displays DORA (DevOps Research and Assessment) metrics from git history and GitHub API. Provides real-time visibility into team velocity, quality, and incident response.

**Four Key Metrics**:
1. **Deployment Frequency**: How often code deploys to production
2. **Lead Time for Changes**: Time from commit to production
3. **Change Failure Rate**: % of deployments causing incidents
4. **Mean Time to Restore** (MTTR): Time to recover from incidents

### Prerequisites

- Git repository with history
- GitHub CLI (`gh`) installed and authenticated (for CFR and MTTR)
- GitHub issues labeled "incident" or "P0" (for MTTR tracking)

### Arguments

| Argument   | Required | Description                           |
| ---------- | -------- | ------------------------------------- |
| `--days`   | No       | Days to analyze (default: 30)         |
| `--format` | No       | Output format (text, json, yaml)      |

### Examples

**View DORA metrics**:
```bash
/metrics.dora
```

**Output**:
```
DORA Metrics (Last 30 Days)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Deployment Frequency: 1.2/day
Lead Time for Changes: 18h
Change Failure Rate: 8%
Mean Time to Restore: 2h

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DORA Performance Tier: High

Tier Thresholds:
  Elite:  >1 deploy/day, <24h lead time, <15% CFR, <1h MTTR
  High:   >1 deploy/week, <1 week lead time, <15% CFR, <24h MTTR
  Medium: >1 deploy/month, <1 month lead time, <15% CFR, <1 week MTTR
  Low:    Below medium thresholds
```

**Last 7 days**:
```bash
/metrics.dora --days 7
```

**JSON output**:
```bash
/metrics.dora --format json
```

```json
{
  "period_days": 30,
  "deployment_frequency": 1.2,
  "lead_time_hours": 18,
  "change_failure_rate": 8,
  "mttr_hours": 2,
  "tier": "High"
}
```

## DORA Metrics Explained

### 1. Deployment Frequency

**Definition**: How often code deploys to production

**Measurement**:
- Count git tags (releases)
- Count commits with "deploy" or "release" in message
- Expressed as deploys/day

**Elite**: >1 deploy/day
**High**: 1 deploy/week to 1 deploy/month
**Medium**: 1 deploy/month to 1 deploy/6months
**Low**: <1 deploy/6 months

**Improvement Tips**:
- Adopt trunk-based development
- Use feature flags for incomplete work
- Automate deployment pipeline

### 2. Lead Time for Changes

**Definition**: Time from commit to production deployment

**Measurement**:
- Track commit timestamp → deployment timestamp
- Average across all commits
- Expressed in hours

**Elite**: <24 hours
**High**: 1 day to 1 week
**Medium**: 1 week to 1 month
**Low**: >1 month

**Improvement Tips**:
- Reduce batch size (smaller changes)
- Parallelize epic development
- Optimize CI/CD pipeline

### 3. Change Failure Rate

**Definition**: % of deployments causing production incidents

**Measurement**:
- Count failed CI/CD workflow runs
- Percentage of total runs
- Expressed as percentage

**Elite/High/Medium**: <15%
**Low**: ≥15%

**Improvement Tips**:
- Improve test coverage (≥80%)
- Add integration tests
- Use quality gates (CI + Security)

### 4. Mean Time to Restore (MTTR)

**Definition**: Time to recover from production incidents

**Measurement**:
- Track GitHub issues labeled "incident" or "P0"
- Time from creation → closed
- Average across all incidents

**Elite**: <1 hour
**High**: <24 hours
**Medium**: <1 week
**Low**: >1 week

**Improvement Tips**:
- Implement rollback capability
- Use feature flags for instant rollback
- Monitor production with alerts

## DORA Tiers

### Elite Performers

- Deploy freq: Multiple deploys per day
- Lead time: <24 hours
- CFR: <15%
- MTTR: <1 hour

**Characteristics**:
- Full CI/CD automation
- Trunk-based development
- Comprehensive monitoring
- Fast rollback capability

### High Performers

- Deploy freq: Weekly to daily
- Lead time: 1 day to 1 week
- CFR: <15%
- MTTR: <24 hours

**Path to Elite**:
- Increase deployment frequency
- Reduce lead time via parallelization
- Improve rollback speed

### Medium Performers

- Deploy freq: Monthly to weekly
- Lead time: 1 week to 1 month
- CFR: <15%
- MTTR: <1 week

**Path to High**:
- Adopt feature flags
- Implement trunk-based development
- Add quality gates

### Low Performers

- Deploy freq: <1 per 6 months
- Lead time: >1 month
- CFR: ≥15%
- MTTR: >1 week

**Path to Medium**:
- Start with CI/CD basics
- Increase test coverage
- Reduce batch sizes

## Integration with Workflow

### Daily Review

```bash
# Check metrics in stand-up
/metrics.dora --days 7
```

### Sprint Retrospective

```bash
# Analyze sprint performance
/metrics.dora --days 14
```

### Bottleneck Detection

Low deployment frequency → Check:
- Branch age violations
- Parking time (blocked epics)
- Quality gate failures

High CFR → Check:
- Test coverage <80%
- Security gate failures
- Missing integration tests

High MTTR → Check:
- Rollback capability missing
- Feature flag adoption low
- Monitoring gaps

## Prerequisites Installation

**GitHub CLI**:
```bash
# macOS
brew install gh
gh auth login

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update
sudo apt install gh
gh auth login

# Windows
winget install GitHub.cli
gh auth login
```

**bc (for calculations)**:
```bash
# macOS (pre-installed)
# Linux
sudo apt install bc
```

## References

- DORA Research: https://dora.dev/
- State of DevOps Report: https://cloud.google.com/devops/state-of-devops/
- Accelerate Book: https://www.amazon.com/Accelerate-Software-Performing-Technology-Organizations/dp/1942788339

---

**Implementation**: `.spec-flow/scripts/bash/dora-calculate.sh`

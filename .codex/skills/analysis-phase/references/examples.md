<analysis_examples>

<bash_commands>
**Useful commands for cross-artifact validation**

```bash
# Load spec requirements (look for ## headings)
grep "##" specs/NNN-slug/spec.md

# Extract plan components (look for ### headings)
grep "###" specs/NNN-slug/plan.md

# List all tasks
grep "^T[0-9]" specs/NNN-slug/tasks.md

# Search for breaking change keywords
grep -i "migration\|schema\|endpoint\|route\|required" specs/NNN-slug/plan.md

# Cross-reference dependencies
grep -i "import\|integration\|external" specs/NNN-slug/plan.md
```
</bash_commands>

<example type="good">
**Good Analysis - Catches Issues Early**

<scenario>
Feature: User profile editing
Analyzed artifacts: spec.md, plan.md, tasks.md
</scenario>

<findings>
**Consistency Issues**:
1. **Spec → Plan gap**: Spec requirement "Users can upload profile photos" has no corresponding plan component
   - Location: spec.md:45
   - Fix: Add "Photo Upload Service" to plan.md

2. **Plan → Tasks gap**: Plan component "Email Notification Service" has no tasks
   - Location: plan.md:78
   - Fix: Add tasks T012-T014 for email notification implementation

**Breaking Changes**:
3. **API change (High Impact)**: Plan modifies `/api/user/profile` response format
   - Before: `{ name, email }`
   - After: `{ firstName, lastName, emailAddress }`
   - Impact: Breaks existing mobile app
   - Mitigation: API versioning (/v1, /v2)

4. **Database change (Medium Impact)**: Migration adds required field `phoneNumber` to users table
   - Impact: Existing users have NULL phone numbers
   - Mitigation: Make field nullable initially, add UI prompt for updates
</findings>

<outcome>
**Result**: Issues fixed before implementation
- Added Photo Upload Service to plan
- Added email notification tasks
- Implemented API versioning strategy
- Made phoneNumber nullable with migration plan

**Time Saved**: 8 hours (avoided rework during implementation)
</outcome>
</example>

<example type="bad">
**Bad Analysis - Missed Critical Issues**

<scenario>
Feature: Payment processing
Analyzed artifacts: spec.md, plan.md, tasks.md
Analyst: Rushed analysis (5 minutes, no checklist)
</scenario>

<findings_missed>
**Consistency Issues Missed**:
1. Spec requirement "Support refunds" → No plan component (discovered during code review)
2. Plan component "Webhook Handler" → No tasks (discovered during implementation)

**Breaking Changes Missed**:
3. Database migration drops `legacy_payment_id` column
   - Impact: Broke reporting system relying on this field
   - Discovery: Production incident after deployment
   - Cost: 4 hours downtime, data recovery effort

4. API endpoint `/api/checkout` now requires authentication
   - Impact: Broke public checkout flow
   - Discovery: QA testing
   - Cost: 2 days rollback and re-implementation
</findings_missed>

<outcome>
**Result**: Major rework during implementation and post-deployment incidents
- Refund feature added in separate sprint (2 weeks delay)
- Webhook tasks added mid-implementation (context switching)
- Database rollback and schema redesign (1 week)
- API authentication made optional with deprecation plan (3 days)

**Time Lost**: 3+ weeks across team
**Lesson**: Thorough analysis saves exponentially more time than it costs
</outcome>
</example>

<example type="complex">
**Complex Analysis - Multi-System Integration**

<scenario>
Feature: Real-time analytics dashboard
Analyzed artifacts: spec.md, plan.md, tasks.md
Complexity: High (touches API, database, UI, background jobs)
</scenario>

<findings>
**Consistency Check**:
- Spec → Plan: ✓ All requirements mapped (7/7)
- Plan → Tasks: ✓ All components have tasks (12/12 components, 45 tasks)
- Tasks → Spec criteria: ✓ Acceptance criteria aligned

**Breaking Changes**:
1. **Database (High Impact)**: New `analytics_events` table with 10M+ inserts/day
   - Impact: Database load increase, index strategy needed
   - Mitigation: Partitioning strategy, separate read replica

2. **API (Medium Impact)**: New WebSocket endpoint for real-time updates
   - Impact: Infrastructure needs WebSocket support
   - Mitigation: Deploy to WebSocket-capable servers, fallback to polling

3. **Background Jobs (Medium Impact)**: New aggregation job runs every 5 minutes
   - Impact: CPU/memory increase
   - Mitigation: Resource allocation, monitoring

**Dependencies Identified**:
- External: Redis for real-time data caching
- Internal: Depends on specs/002-event-tracking (must deploy first)
- Infrastructure: WebSocket support, increased database capacity

**Cross-References**:
- Checked specs/002-event-tracking/plan.md for integration points ✓
- Verified Redis already in tech-stack.md ✓
- Flagged WebSocket infrastructure requirement for DevOps
</findings>

<analysis_report>
Generated comprehensive analysis-report.md with:
- 8-section structure (consistency, breaking changes, dependencies, risks, mitigations, deployment order, testing strategy, rollback plan)
- Deployment order: specs/002 → database migration → API → background jobs → UI
- Testing strategy: Load testing (10M events/day simulation), WebSocket failover testing
- Rollback plan: Feature flag for real-time mode, fallback to batch updates
</analysis_report>

<outcome>
**Result**: Proactive risk mitigation, smooth deployment
- Infrastructure provisioned before implementation
- Deployment order enforced via dependency graph
- Load testing completed before production
- Zero incidents post-deployment

**Complexity Handled**: Analysis scaled to feature complexity
</outcome>
</example>

</analysis_examples>

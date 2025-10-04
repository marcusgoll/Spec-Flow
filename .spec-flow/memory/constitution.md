<!-- Sync Impact Report
Version change: 1.1.0  1.2.0 (minor - anonymous extraction, ephemeral results, export policies)
Modified principles: III (Minimal Data Retention), V (Tiered Visibility), VIII (Do Not Overengineer)
Added principles: XIII (Single Codepath), XIV (Progressive Rollout)
Modified sections: Extraction Pipeline, Roles & Entitlements, Aggregation & Privacy
Added sections: Rate Limiting & Abuse Controls
Removed sections: None
Templates requiring updates:
-  constitution.md (completed)
-  spec-template.md (pending - anonymous extraction acceptance surfaces)
-  tasks-template.md (pending - ephemeral result handling patterns)
Follow-up TODOs: Update F1/F2/F3 fixture patterns in test templates
-->

# Spec-Flow Constitution  AKTRACS Extractor & ACS Database (MVP)

**Scope**: Turn FAA AKTR reports into trustworthy ACS-mapped insights. ACS Database is
the SSOT for codemetadata. Govern the MVP that ships value in days, not months.

## Core Principles

### I. Extractor-First Delivery
A useful result MUST be delivered in seconds; everything else is secondary. This ensures
the primary value proposition is met without delays or unnecessary complexity.

### II. Hybrid Extraction
Use regex/text path for digital PDFs; vision LLM fallback for photos and PDF edge cases.
No classical OCR engines. This approach balances speed with versatility for different
input formats.

### III. Minimal Data Retention
NEVER store original uploads post-extraction; persist only normalized results and
aggregates required for analytics. Anonymous extractions MUST use ephemeral results with
TTL 24h. Authenticated users may save results indefinitely. This protects user privacy
and reduces storage costs while enabling trial-before-commit UX.

### IV. Transparent Mapping
AKTR codes (e.g., AA.I.A.K2) MUST resolve against the ACS DB; the DB is authoritative.
The ACS Database is the single source of truth (SSOT) for codemetadata mappings.

### V. Tiered Visibility That Matches Value
 Anonymous: show only the description for each matched code; sign-in required to
  save/export/share; results expire 24h
 Free (Authenticated): description + limited save (5 reports/month); CSV export only
 Subscriber (Individual/CFI/School): show full metadata (area, task, page, source,
  edition, links) + unlimited exports (CSV only at launch; PDF/XLSX deferred) + batching
This aligns revenue model with value delivery and enables frictionless trial experience.

### VI. Rolling National Stats
Maintain de-identified, rolling miss counts per code; surface weekly/monthly aggregates.
This provides industry-wide learning insights without compromising individual privacy.

### VII. Accuracy Loop
MUST allow "Suggest a correction", queue for QA, version mappings by ACS edition, and
publish change log. This ensures continuous improvement and trust building.

### VIII. Do Not Overengineer
Exclude SSO, coupons/proration, complex seat provisioning, heavy analytics at MVP.
Defer PDF/XLSX exports; launch with CSV only. Ship value first, then iterate. Focus on
core functionality that delivers immediate value. Use feature flags for gradual rollout,
not parallel codepaths.

### IX. Code Quality Standards
All code MUST be readable, maintainable, and follow established patterns:
 Type safety enforced (TypeScript for frontend, type hints for Python backend)
 Linting and formatting automated (ESLint/Prettier for JS/TS, Black/Ruff for Python)
 No duplicated logic; DRY principle enforced through code reviews
 Clear naming conventions: descriptive variable/function names, no abbreviations
This ensures long-term maintainability and reduces technical debt.

### X. Testing Standards
Testing MUST be comprehensive and automated:
 Unit tests required for all business logic (minimum 80% coverage)
 Integration tests for all API endpoints and database operations
 End-to-end tests for critical user flows (upload, extract, export)
 Performance tests for extraction pipeline (<10s P95 requirement)
 All tests MUST pass before merge; no exceptions
This ensures reliability and prevents regressions.

### XI. User Experience Consistency
UX MUST be predictable and accessible across all touchpoints:
 Consistent visual language (typography, spacing, colors per design system)
 Loading states for all async operations with progress indicators where feasible
 Error messages MUST be actionable (what went wrong + how to fix it)
 Mobile-responsive design for all public pages
 WCAG 2.1 AA compliance for accessibility
This ensures a professional, trustworthy user experience.

### XII. Performance Requirements
System performance MUST meet defined thresholds:
 Extraction: <10s for 95th percentile of AKTR reports (up to 50 pages)
 API response: <500ms for database queries, <2s for extraction initiation
 Frontend: First Contentful Paint <1.5s, Time to Interactive <3s
 Database: Indexed queries return in <100ms
 Batch processing: Linear scaling up to 30 concurrent documents
This ensures the system remains responsive under expected load.

### XIII. Single Codepath Principle
NEVER maintain parallel logic for different user tiers or feature states. Use database
flags, configuration, or feature toggles to control behavior. A single extraction pipeline
serves anonymous, free, and paid users; entitlements filter visibility. This reduces bugs,
simplifies testing, and ensures consistent UX across tiers.

### XIV. Progressive Rollout with Feature Flags
New features MUST use feature flags for gradual exposure. Launch to 5%  25%  100% over
days/weeks. Kill switches MUST exist for instant rollback. This enables safe iteration,
A/B testing, and rapid response to production issues without redeployment.

## Audiences & Outcomes

### Students
Upload AKTR  matched codes  study what matters before checkride
 Anonymous = description-only, ephemeral (24h), sign-in to save
 Free (Authenticated) = description + limited saves (5/month) + CSV export
 Paid = full metadata + unlimited saves + CSV export + printable study plan

### CFIs
Batch up to a class (30 at launch)  cohort dashboard with top missed codes and
per-student drilldown; CSV export (white-label PDF deferred to post-MVP)

### Schools
Seat bundles + organization-level aggregates (month-over-month drift by ACS area/task)

## ACS Database (Canonical Fields)

 `code` (string) - The AKTR code identifier
 `type` ("knowledge" | "skill") - Classification of the code
 `description` (string) - Human-readable description
 `area_of_operation` - Area categorization
 `area_number` - Numeric area identifier
 `area_title` - Area title text
 `task` - Task identifier
 `task_letter` - Task letter designation
 `task_title` - Task title text
 `page_number` (int) - Page reference in source document
 `source_pdf` (string) - Source PDF identifier
 `source_filename` (string) - Source filename
 `acs_edition` (string) - Edition identifier for versioning
 `links` (optional array) - PHAK/IFH/Advisory Circular references

**Key**: (code, acs_edition) is unique

## Visibility Rules

### Anonymous User Payload
Code + description only; sign-in prompt to save/export/share; results expire 24h

### Free User Payload (Authenticated)
Code + description + limited saves (5 reports/month) + CSV export; teaser to upgrade
for full metadata (area/task/page/source)

### Subscriber Payload
Full metadata + edition + CSV export (PDF/XLSX deferred) + unlimited saved report history

### Public Page
"National Missed Codes (Rolling)" table with top codes and 7/30-day trends (no PII);
drilldowns require authentication (free tier minimum)

## Extraction Pipeline (MVP)

1. **Ingest**: PDF or image
2. **Detect**: If digital text  regex parser; else  vision LLM path
3. **Normalize**: Extract codes; de-dupe; associate with acs_edition
4. **Enrich**: Join with ACS DB; apply visibility rules by entitlement
5. **Persist**: Save report (no file blob), report_items (code, edition, matched_at),
   increment aggregate counters. Anonymous reports get TTL 24h; authenticated reports
   persist indefinitely (subject to tier limits).
6. **Telemetry**: Minimal, de-identified metrics (counts per code per day, role bucket)

## Rate Limiting & Abuse Controls

 **Anonymous**: 3 extractions/IP/day; 1 concurrent extraction/IP; CAPTCHA after 2 failures
 **Free (Authenticated)**: 10 extractions/day; 5 saves/month; 2 concurrent extractions
 **Subscriber (Individual)**: 100 extractions/day; unlimited saves; 5 concurrent extractions
 **CFI/School**: Custom limits based on seat count; batch uploads count as 1 extraction
 **Global**: 429 responses with Retry-After header; exponential backoff required
 **File Validation**: Max 50MB per file; PDF/JPG/PNG only; virus scanning via ClamAV
 **Cost Protection**: Kill switch for LLM calls if daily spend >$100; alerts at $50

All limits enforced via Redis counters with sliding windows. Rate limit headers returned
on all extraction endpoints (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset).

## Roles & Entitlements (Launch)

 **Anonymous**: 3 extracts/day (IP-limited); description view only; results expire 24h;
  sign-in required to save/export/share
 **Student (Free)**: 10 extracts/day; 5 saved reports/month; description + CSV export
 **Student (Pro)**: 100 extracts/day; unlimited saves; full metadata; CSV export;
  printable study plan
 **CFI**: Batch up to 30 docs/run; full metadata; CSV export; cohort dashboard
  (white-label PDF deferred)
 **School (Starter)**: 5 seats; batch 300/month; org dashboard; CSV exports

Caps exist for abuse control, cost predictability, and tier differentiation.

## Aggregation & Privacy

 **Storage**: miss_counts table keyed by (code, acs_edition, yyyy_mm_dd) with integer count
 **Privacy**: No PII in aggregates; users may opt out (default opt-in with clear notice);
  anonymous extractions contribute to aggregates but contain no user identifiers
 **TTL Enforcement**: Anonymous report_items auto-deleted after 24h via PostgreSQL TTL
  triggers; no manual cleanup jobs
 **Refresh**: Public aggregates refresh daily

## Non-Goals (MVP)

SSO, LMS/LTI/SCORM, complex seat billing, per-student longitudinal analytics,
partner API, mobile apps, internationalization, PDF/XLSX exports (CSV only at launch),
white-label PDF reports (deferred to post-MVP).

## Done Criteria (MVP)

 Upload AKTR  matched codes visible in <10s for 95th percentile
 Anonymous users can extract without sign-in; results show description-only with
  sign-in prompt; results expire 24h
 Free tier (authenticated) shows description + limited saves (5/month) + CSV export
 Subscribers see full metadata + unlimited saves + CSV export
 Batch upload for CFIs (up to 30 docs) returns cohort view with progress
 National Missed Codes page updates daily and exposes no PII
 Correction workflow exists (submit  admin QA  publish fix with edition note)
 Rate limiting enforced: 3/day anonymous, 10/day free, 100/day paid, with headers
 All code passes quality gates (linting, type checking, test coverage)
 Performance benchmarks met for all critical paths
 Acceptance surfaces validated: F1 (anonymous trial), F2 (free tier limits),
  F3 (subscriber full access)

## Governance

This constitution supersedes all development practices for the Spec-Flow MVP.

### Amendment Procedure
1. Document proposed changes with clear rationale
2. Perform impact analysis on existing features and roadmap
3. Version increment following semantic versioning
4. Update all dependent templates and documentation

### Compliance
 All PRs/reviews MUST verify compliance with these principles
 Complexity additions MUST be justified against Principle VIII
 Code quality violations (IX) block merge until resolved
 Testing gaps (X) prevent deployment to production
 UX inconsistencies (XI) require design review before implementation
 Performance regressions (XII) trigger immediate rollback
 Single codepath violations (XIII) require refactoring before merge
 Feature flag requirements (XIV) enforced for all new user-facing features
 Use CLAUDE.md or AGENTS.md for runtime development guidance

**Version**: 1.2.0 | **Ratified**: 2025-09-22 | **Last Amended**: 2025-10-02


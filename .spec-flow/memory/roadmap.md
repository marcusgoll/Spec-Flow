# Spec-Flow Product Roadmap

**Last updated**: 2025-10-02

> This roadmap tracks features from brainstorm -> shipped. Use `/roadmap` to manage.

## Shipped

<!-- Features that have been released to production -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Date**: YYYY-MM-DD
- **Release**: vX.Y.Z - One-line release notes
-->

## In Progress

<!-- Features currently being implemented (linked to active branches) -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api|infra|design
- **Role**: free|student|cfi|school|all
- **Phase**: 0-12 (optional)
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**:
  - Requirement 1
  - Requirement 2
- **Branch**: NNN-feature-name
- **Owner**: @username (optional)
-->

### clerk-multi-domain-auth
- **Title**: Clerk Multi-Domain Authentication
- **Area**: infra
- **Role**: all
- **Phase**: 0
- **Impact**: 5 | **Effort**: 4 | **Confidence**: 0.8 | **Score**: 1.00
- **Spec**: specs/008-clerk-multi-domain-auth/spec.md
- **Branch**: 008-clerk-multi-domain-auth
- **Requirements**:
  - Configure Clerk satellites for marketing and app domains (see staging/prod URLs)
  - Share session cookies across allowed subdomains with explicit allowlist
  - Deep-link preservation with allowlist validation
  - Cross-domain logout (clears session on both domains)
  - Staging and local development environment support
  - Anonymous access to /app/aktr/upload and /app/aktr/results/:id only

## Next

<!-- Top 5-10 features prioritized for next sprint (sorted by score) -->
<!-- Same format as In Progress, no Branch/Owner -->

## Later

<!-- Features planned for future (10-20 items, sorted by score) -->
<!-- Same format as Next -->

## Backlog

<!-- All other feature ideas (unlimited, sorted by score) -->
<!-- Minimal format:
### slug-name
- **Title**: Feature name
- **Area**: marketing|app|api
- **Role**: student|cfi|school|all
- **Impact**: 1-5 | **Effort**: 1-5 | **Confidence**: 0-1 | **Score**: X.XX
- **Requirements**: [CLARIFY: questions] or brief bullets
-->

### org-console-seats-roles
- **Title**: Organization Console - Seats & Roles Management
- **Area**: app
- **Role**: school
- **Impact**: 4 | **Effort**: 3 | **Confidence**: 0.7 | **Score**: 0.93
- **Requirements**:
  - **Seat management**: View total seats, assigned seats, available seats with add/remove seat actions
  - **Role assignment**: Assign users to roles (student, cfi, admin) with permission levels
  - **User list**: Display all organization members with name, email, role, join date, last active
  - **Invite system**: Generate invite links with pre-assigned roles, track pending invitations
  - **Accounting CSV export**: Download billing report with columns: user, role, join_date, seat_cost, total_monthly_cost (manual reconciliation for MVP)
  - **Bulk operations**: Batch role changes, bulk seat removal for inactive users
  - **Permissions**: Only school admins can access console, audit log for all seat/role changes
  - **Seat limit enforcement**: Soft limits with warnings (allow 10% overage for 7 days, then block new signups until seats added) - better UX than hard blocks
  - **Stripe integration**: Manual CSV reconciliation for MVP, defer automatic billing sync to v2 (keeps effort at 3 weeks)

### cfi-cohort-heatmap
- **Title**: CFI Cohort Performance Heatmap
- **Area**: app
- **Role**: cfi
- **Impact**: 5 | **Effort**: 3 | **Confidence**: 0.8 | **Score**: 1.33
- **Requirements**:
  - **Heatmap visualization**: Matrix of students (rows)  ACS areas (columns), color-coded by mastery level (red=weak, yellow=moderate, green=strong)
  - **Top misses panel**: Display most commonly missed ACS codes across all students in cohort with frequency count
  - **Aggregation**: Combine multiple student extraction results into cohort-level insights
  - **Interactivity**: Click heatmap cell to drill down into specific student + area details
  - **Export**: Download heatmap as PNG/PDF for reporting to flight schools
  - **Filtering**: By date range, student subset, ACS area subset
  - **Cohort definition**: Manual grouping by CFI (select students to include), auto-group by school for school tier (all students in organization)
  - **Time-series**: Snapshot only for MVP (single point-in-time heatmap), defer time-series tracking to v2 to keep effort at 3 weeks

### aktr-extraction-history
- **Title**: AKTR Extraction History
- **Area**: app
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.9 | **Score**: 1.80
- **Requirements**:
  - List view: Display all past extractions with metadata (date, filename, ACS count, status)
  - Detail view: Click to view full results for any past extraction
  - "Recreate" route: Re-run extraction on same file (use cached file if available, or prompt re-upload)
  - Sorting: By date (newest first), filename (alphabetical), ACS count (descending)
  - Filtering: By date range, filename search, ACS count threshold
  - Pagination: 20 results per page for performance
  - **Tiered access**: Free users get last extraction (30-day retention), authenticated users get unlimited (unlimited retention if account is active)
  - **Retention policy**: 30 days (free), Unlimited (student), Unlimited (cfi/school)
  - Authentication required for persistence beyond 24 hours (anonymous extractions auto-purge after 24h)

### csv-export
- **Title**: CSV Export and Sharing
- **Area**: app
- **Role**: student
- **Impact**: 3 | **Effort**: 2 | **Confidence**: 0.9 | **Score**: 1.35
- **Requirements**:
  - Export modal with CSV download (all metadata: code, description, type, area, task, page, source)
  - CSV format: One row per ACS code, all metadata columns (no column configuration for MVP)
  - CSS print styles for browser print/PDF export
  - Shareable token generation (authenticated users only)
  - Token expiration: 7 days (free), 30 days (student), 90 days (cfi/school)
  - Token revocation UI: "Manage Shared Links" page with list view + revoke button
  - Share link format: /app/aktr/results/:resultId?token=:shareToken

### aktr-results-core
- **Title**: AKTR Results Core Flow
- **Area**: app
- **Role**: free
- **Impact**: 5 | **Effort**: 4 | **Confidence**: 0.9 | **Score**: 5.13
- **Requirements**:
  - Upload page: File drop zone, validation, progress indicator
  - Processing page: Simple spinner/loading state (no real-time updates needed - processing is <1s typically, max 5s for images)
  - Results page: Display extracted ACS codes with full metadata
  - **Metadata display**: code, description, type (knowledge/risk/skill), area_title, task_title, page_number, source_pdf
  - **URL filters**: Persist in URL query params for shareable links (e.g., ?type=knowledge&area=I&task=A)
  - **Filter options**: By type, area_number, task_letter, source_pdf
  - Print styles: CSS print media queries for clean printing/PDF export
  - Responsive design: Mobile-first, tablet, desktop breakpoints
  - **UX**: Skip dedicated processing page if <2s, show inline spinner on upload page, redirect to results when ready

### anonymous-extraction
- **Title**: Anonymous ACS Extraction
- **Area**: app
- **Role**: free
- **Impact**: 4 | **Effort**: 3 | **Confidence**: 0.8 | **Score**: 1.07
- **Requirements**:
  - No-auth upload for /app/aktr/upload endpoint
  - Authentication required to save results permanently
  - Authentication required to export results (PDF/CSV)
  - Authentication required to share results with others
  - Anonymous session masking (no PII collection)
  - Rate limiting for anonymous uploads (prevent abuse)
  - **Retention**: 24 hours for anonymous results (auto-purge via cron job)
  - **Storage**: Results-only ephemeral access (no session storage, just result ID in URL)
  - **Rate limits**: 10 uploads/hour per IP + 50 uploads/day per IP (Redis-backed with exponential backoff)
  - **Abuse prevention**: CAPTCHA after 3 uploads/hour, block after 5 failed CAPTCHA attempts
  - **Result ID**: Cryptographically secure random token (32 chars) to prevent enumeration

### study-plan-pro
- **Title**: AI Study Plan Generator
- **Area**: app
- **Role**: student
- **Impact**: 5 | **Effort**: 4 | **Confidence**: 0.8 | **Score**: 1.00
- **Requirements**:
  - Generate personalized study plan from AKTR results (identified ACS codes)
  - AI-powered prioritization based on knowledge/risk/skill type and ACS hierarchy
  - Progress indicators: mastery percentage per area/task, overall completion
  - Study session tracking: mark codes as "studying", "mastered", or "needs review"
  - **Progress storage**: Local storage for free users, cloud sync for authenticated users (tiered approach aligns with freemium model)
  - **Export integration**: Reuse csv-export modal/infrastructure for sharing study plans (DRY principle, consistent UX)
  - Export study plan as PDF or shareable link with same token expiration rules as csv-export (7/30/90 days)

### cookie-consent-minimal
- **Title**: Cookie Consent Minimal
- **Area**: marketing
- **Role**: all
- **Impact**: 3 | **Effort**: 1 | **Confidence**: 0.95 | **Score**: 2.85
- **Requirements**:
  - Consent banner (GDPR/CCPA compliant)
  - Preferences modal (analytics, functional, marketing toggles)
  - Cookie policy page link
  - localStorage persistence for user choices
  - PostHog integration respect (disable if rejected)

### press-kit-page
- **Title**: Press Kit Page
- **Area**: marketing
- **Role**: all
- **Impact**: 3 | **Effort**: 1 | **Confidence**: 0.95 | **Score**: 2.85
- **Requirements**:
  - Brand assets (logos, colors, fonts) download
  - Boilerplate company description
  - Founder bios and headshots
  - Media contact information

### testimonial-strip-v1
- **Title**: Testimonial Strip v1
- **Area**: marketing
- **Role**: all
- **Impact**: 3 | **Effort**: 1 | **Confidence**: 0.9 | **Score**: 2.70
- **Requirements**:
  - Reusable component with quotes/logos
  - Rotating carousel or static grid layout
  - Role-based filtering (student vs CFI testimonials)
  - Integrate on homepage, pricing, role landing pages

### homepage-hero
- **Title**: Homepage Hero
- **Area**: marketing
- **Role**: all
- **Impact**: 5 | **Effort**: 2 | **Confidence**: 0.8 | **Score**: 2.00
- **Requirements**:
  - Focused value proposition with clear messaging (AKTR  ACS extraction benefit)
  - Single primary CTA (reduce choice paralysis)
  - Trust badges (FAA-compliant, student testimonials, security)
  - Mobile-first responsive design
  - Hero image/animation showcasing product value

### pricing-clarity-toggle
- **Title**: Pricing Clarity Toggle
- **Area**: marketing
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.9 | **Score**: 1.80
- **Requirements**:
  - Monthly/annual pricing toggle with savings highlight
  - Sticky CTA (scroll persistence)
  - Clear feature comparison table
  - Free tier vs paid tier visibility

### og-schema-seo-pass
- **Title**: OG & Schema SEO Pass
- **Area**: marketing
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.9 | **Score**: 1.80
- **Requirements**:
  - Open Graph tags (title, description, image) for social sharing
  - JSON-LD schema markup (Organization, FAQ, Product)
  - Sitemap.xml generation with priority/frequency
  - Robots.txt optimization for crawler guidance

### faq-searchable-mdx
- **Title**: FAQ Searchable MDX
- **Area**: marketing
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.85 | **Score**: 1.70
- **Requirements**:
  - Searchable FAQ with real-time filtering
  - Accordion components with expand/collapse
  - Anchor links for direct FAQ sharing
  - MDX content format for easy maintenance

### docs-quickstart
- **Title**: Docs Quickstart
- **Area**: marketing
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.85 | **Score**: 1.70
- **Requirements**:
  - 10-minute onboarding path with step-by-step screenshots
  - "Getting Started" section with AKTR upload tutorial
  - Code examples and API reference (if needed)
  - Search functionality within docs

### compare-pages
- **Title**: Compare Pages
- **Area**: marketing
- **Role**: all
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.8 | **Score**: 1.60
- **Requirements**:
  - "vs Spreadsheets" comparison page (manual vs automated)
  - "vs Generic OCR" comparison page (aviation-specific vs generic)
  - Feature comparison tables with checkmarks
  - Social proof (testimonials from switchers)

### role-landing-cfi
- **Title**: Role Landing - CFI Page
- **Area**: marketing
- **Role**: cfi
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.8 | **Score**: 1.60
- **Requirements**:
  - CFI-specific benefits (cohort tracking, batch processing)
  - Use cases and testimonials from CFIs
  - CTA for CFI tier signup
  - Feature highlights (heatmap, top misses)

### role-landing-school
- **Title**: Role Landing - School Page
- **Area**: marketing
- **Role**: school
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.75 | **Score**: 1.50
- **Requirements**:
  - School-specific benefits (seat management, policies, records)
  - Demo request form for flight schools
  - Enterprise features highlight
  - Compliance and security messaging

### lead-magnets
- **Title**: Lead Magnets
- **Area**: marketing
- **Role**: student
- **Impact**: 4 | **Effort**: 2 | **Confidence**: 0.75 | **Score**: 1.50
- **Requirements**:
  - AKTRACS checklist PDF download (email capture)
  - Pre-checkride pack (study tips, common mistakes)
  - Email automation sequence for nurturing
  - Landing pages for each lead magnet

### release-notes-changelog
- **Title**: Release Notes / Changelog
- **Area**: marketing
- **Role**: all
- **Impact**: 3 | **Effort**: 2 | **Confidence**: 0.85 | **Score**: 1.28
- **Requirements**:
  - Public changelog page with version history
  - RSS feed for updates
  - Categorized changes (features, fixes, improvements)
  - Link from footer and docs

### status-page-cleanup
- **Title**: Status Page Cleanup
- **Area**: marketing
- **Role**: all
- **Impact**: 3 | **Effort**: 2 | **Confidence**: 0.85 | **Score**: 1.28
- **Requirements**:
  - Tighter layout with component status grid
  - Incident history with timestamps
  - Subscribe to updates (email/RSS)
  - Uptime percentage display

### acs-code-directory-hubs
- **Title**: ACS Code Directory Hubs
- **Area**: marketing
- **Role**: all
- **Impact**: 5 | **Effort**: 3 | **Confidence**: 0.7 | **Score**: 1.17
- **Requirements**:
  - Area hub pages (e.g., /acs/area-i, /acs/area-ii) linking to individual ACS code pages
  - SEO-optimized content for each hub (descriptions, metadata)
  - Internal linking structure for discovery
  - Dynamic generation from ACS database

### cost-compass-teaser
- **Title**: Cost Compass Teaser Widget
- **Area**: marketing
- **Role**: student
- **Impact**: 4 | **Effort**: 3 | **Confidence**: 0.7 | **Score**: 0.93
- **Requirements**:
  - Simple P50/P90 cost preview widget on marketing site
  - Interactive calculator with basic inputs
  - CTA to signup for full Cost Compass feature
  - Data from aggregated analytics

### checkride-readiness-quiz-teaser
- **Title**: Checkride Readiness Quiz Teaser
- **Area**: marketing
- **Role**: student
- **Impact**: 4 | **Effort**: 3 | **Confidence**: 0.7 | **Score**: 0.93
- **Requirements**:
  - 6-question checkride readiness quiz
  - Instant results with personalized feedback
  - Signup CTA to unlock full features
  - Email capture for results delivery

### digital-logbook-v1
- **Title**: Digital Logbook v1
- **Area**: app
- **Role**: free
- **Impact**: 4 | **Effort**: 3 | **Confidence**: 0.7 | **Score**: 0.93
- **Requirements**:
  - **Field set**: FAA Part 61 requirements only (date, aircraft make/model/ident, departure/arrival, flight time, conditions, landings, remarks)
  - **Time categories**: Total, PIC, SIC, dual received, solo, cross-country, night, actual instrument, simulated instrument, ground training
  - Add/edit flights form with validation (date format, numeric hours, required fields)
  - Flight list view with sortable columns and basic filtering (date range, aircraft, flight type)
  - Basic totals calculation (auto-sum time categories, update on add/edit/delete)
  - CSV import for bulk flight data (column mapping wizard, validation preview before import)
  - CSV export for backup and external use (all fields, filterable date range)
  - Mobile-responsive table with horizontal scroll
  - **CFI endorsements**: Defer to v2 (adds complexity: endorsement types, CFI signatures, expiration tracking - would push effort beyond 3 weeks)
  - **No charts**: Defer visualizations to v2 (keeps scope minimal for MVP)

## Archive

<!-- Deprecated features or ideas that won't be implemented -->
<!-- Format:
### slug-name
- **Title**: Feature name
- **Reason**: Why archived (e.g., "superseded by X", "no longer needed", "out of scope")
- **Date**: YYYY-MM-DD
-->

---

## Scoring Guide

**ICE Score** = (Impact * Confidence) / Effort

- **Impact** (1-5): User value
  - 1 = Nice-to-have polish
  - 3 = Useful improvement
  - 5 = Critical for user success
- **Effort** (1-5): Implementation complexity
  - 1 = Trivial (< 1 day)
  - 3 = Medium (1-2 weeks)
  - 5 = Epic (4+ weeks)
- **Confidence** (0-1): Estimate certainty
  - 0.5 = Very uncertain
  - 0.7 = Some unknowns
  - 0.9 = High confidence
  - 1.0 = Certain

Higher score = higher priority

## Status Flow

```
Backlog -> Later -> Next -> In Progress -> Shipped
                               \
                          Archive (if deprecated)
```

## Feature Sizing

Keep features **/spec-flow-sized**:
- <= 30 implementation tasks
- One screen/flow/API surface
- 1-2 weeks implementation time

If larger: Break into multiple features by area (marketing/app/api) or domain.



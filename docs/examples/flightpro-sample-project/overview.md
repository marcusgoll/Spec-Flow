# Project Overview

**Last Updated**: 2025-10-24
**Status**: Active (MVP in development)

---

## Vision Statement

FlightPro is a SaaS platform that helps certified flight instructors (CFIs) manage their students, track progress, and maintain compliance with FAA regulations. We exist because current solutions are either too expensive ($200+/mo for small flight schools) or lack critical features like ACS-mapped progress tracking and automated FAA record-keeping.

**Core problem solved**: CFIs spend 5-10 hours/week on administrative work (spreadsheets, paper logbooks, manual progress tracking). FlightPro automates this down to <1 hour/week, letting instructors focus on teaching.

---

## Target Users

### Primary Persona: Independent CFI

**Who**: Independent certified flight instructor (CFI)

- 25-55 years old
- Teaches 5-20 students concurrently
- Works at small flight schools or independently
- Tech-savvy but not developers
- Budget-conscious ($50-100/mo acceptable)

**Goals**:

- Track student progress toward certificates (Private, Instrument, Commercial)
- Log lessons with FAA-compliant records
- Identify weak areas requiring additional practice
- Automate administrative work (reports, student records)
- Stay organized across multiple students

**Pain Points**:

- **Current tools too expensive**: ForeFlight Logbook ($99/year/student), MyFlightBook ($free but no CFI features), CloudAhoy ($200/year)
- **No ACS mapping**: Hard to track which Airman Certification Standards (ACS) tasks are complete
- **Manual progress reports**: Copy-paste student progress into emails/PDFs weekly
- **Paper logbooks**: Students forget them, lose them, or fill them incorrectly
- **No reminders**: Forget to check medical certificate expirations, written test dates

**Success scenario**: "I open FlightPro, see my schedule for the day, check that Student A needs more work on short-field landings (ACS task flagged), log today's lesson in 2 minutes, and auto-generate a progress report for the student's parents — all in <5 minutes."

---

### Secondary Persona: Student Pilot

**Who**: Aviation student working toward certificate

- 18-65 years old
- Training for Private Pilot, Instrument, or Commercial certificate
- Flies 1-4 times/month (cost-dependent)
- Wants to track own progress

**Goals**:

- View progress toward certificate completion
- See weak areas requiring practice
- Access lesson history and notes
- Track total flight hours
- Receive reminders (medical renewal, written test expiration)

**Pain Points**:

- **No visibility**: CFI has all records, student doesn't know where they stand
- **Manual tracking**: Keep separate spreadsheet of hours by type (dual, PIC, night, XC)
- **Lost logbooks**: Paper logbooks lost/damaged = lost records
- **Unclear progress**: "How many more lessons until checkride?" is guesswork

**Success scenario**: "I log into FlightPro, see I'm 85% complete toward my Private Pilot certificate, see that I need 3 more hours of night flying, and book my next lesson with my CFI — all in one place."

---

## Core Value Proposition

**For** independent CFIs and student pilots
**Who** need efficient student management and progress tracking
**The** FlightPro
**Is a** web application
**That** automates administrative work and tracks ACS-aligned progress
**Unlike** ForeFlight Logbook, MyFlightBook, CloudAhoy
**Our product** costs <$50/mo, has ACS-mapped progress tracking, and auto-generates FAA-compliant reports

**Key differentiators**:

1. **ACS-Mapped Progress** — Industry-first visual tracking of Airman Certification Standards tasks
2. **Affordable** — $10/mo per CFI (10x cheaper than competitors)
3. **Auto Reports** — Generate student progress reports in 1 click (competitors require manual copy-paste)
4. **Dual Access** — Both CFI and student see progress (competitors are CFI-only or student-only)

---

## Success Metrics

### North Star Metric

**Active CFIs logging lessons weekly**

**Target**: 100 CFIs within 6 months of launch

**Why this metric**: Revenue follows engagement. If CFIs log lessons, they pay. If they don't, they churn.

---

### Key Performance Indicators (KPIs)

**Acquisition** (How we grow):

- Monthly new CFI sign-ups: Target 20/mo
- Conversion rate (free trial → paid): Target 40%
- CAC (Customer Acquisition Cost): Target <$50/CFI

**Engagement** (How users use the product):

- Weekly active CFIs: Target 80% of paid users
- Average lessons logged per CFI per week: Target 5-10
- Time to first lesson logged: Target <24 hours after sign-up

**Retention** (How we keep users):

- Monthly churn rate: Target <5%
- NPS (Net Promoter Score): Target >50
- Feature adoption rate (ACS progress tracking): Target >60%

**Revenue** (How we make money):

- MRR (Monthly Recurring Revenue): Target $1K within 6 months ($10/mo × 100 CFIs)
- ARPU (Average Revenue Per User): $10/mo
- LTV (Lifetime Value): Target $240 (24 months × $10/mo)

---

## Scope Boundaries

### In Scope (What we're building)

**MVP (Phase 1 — First 3 months)**:

- ✅ User authentication (CFI + student roles)
- ✅ Student management (add/edit/archive students)
- ✅ Lesson logging (date, hours, aircraft, notes)
- ✅ Basic progress tracking (total hours, lessons completed)
- ✅ ACS task checklist (Private Pilot only)
- ✅ Student dashboard (view own progress)

**Post-MVP (Phase 2 — Months 4-6)**:

- ⏭️ Automated progress reports (PDF generation)
- ⏭️ Reminders (medical expiration, written test expiration)
- ⏭️ Multi-certificate support (Instrument, Commercial)
- ⏭️ Billing & subscriptions (Stripe integration)

**Future (Phase 3 — Months 7+)**:

- 💡 Flight school management (multi-CFI view, aircraft scheduling)
- 💡 Mobile app (iOS/Android for in-flight logging)
- 💡 Integrations (ForeFlight, Garmin Pilot, CloudAhoy import)

---

### Out of Scope (What we're NOT building)

**Explicitly excluded**:

- ❌ **Flight planning** (use ForeFlight, Garmin Pilot — we integrate, don't replace)
- ❌ **Aircraft maintenance tracking** (different market, different buyer)
- ❌ **Flight school ERP** (scheduling, billing, payroll — too complex for MVP)
- ❌ **Logbook for Part 121/135 pilots** (airline/charter market has different needs)
- ❌ **FAA written test prep** (Sporty's, King Schools own this market)

**Rationale**: Focus on CFI administrative work automation. Don't compete with established products (ForeFlight for planning, Sporty's for test prep). Integrate, don't duplicate.

---

## Competitive Landscape

### Direct Competitors

**1. ForeFlight Logbook**

- **Price**: $99/year per user
- **Strengths**: Market leader, pilot trust, integrates with flight planning
- **Weaknesses**: No CFI-specific features, no ACS mapping, no student view
- **Our advantage**: 10x cheaper, CFI-first design, ACS progress tracking

**2. MyFlightBook**

- **Price**: Free (ad-supported)
- **Strengths**: Free, comprehensive features, cloud-based
- **Weaknesses**: Dated UI, no CFI dashboard, no progress tracking, ads
- **Our advantage**: Modern UI, CFI-student dual access, ACS mapping

**3. CloudAhoy**

- **Price**: $200/year
- **Strengths**: Flight debriefing, 3D playback, detailed analytics
- **Weaknesses**: Expensive, complex, overkill for basic student tracking
- **Our advantage**: Simpler, cheaper, focused on progress not analytics

---

### Indirect Competitors (Partial overlap)

**4. Google Sheets / Excel**

- **Price**: Free
- **Strengths**: Flexible, familiar, free
- **Weaknesses**: Manual, no reminders, error-prone, not FAA-compliant format
- **Our advantage**: Automated, structured, FAA-compliant, progress visualizations

**5. Paper Logbooks**

- **Price**: $10-30 (one-time)
- **Strengths**: Traditional, tactile, FAA-accepted
- **Weaknesses**: Easily lost/damaged, no analytics, manual totaling, no digital backup
- **Our advantage**: Cloud backup, auto-totaling, analytics, never lose records

---

### Market Positioning

**Market**: Flight training software (subset of aviation software market)

**Total Addressable Market (TAM)**:

- ~100K active CFIs in USA
- ~500K student pilots annually in USA
- Avg CFI teaches 10 students → 1M relationships

**Serviceable Addressable Market (SAM)**:

- Independent CFIs + small flight schools: ~50K CFIs
- Tech-savvy, budget-conscious segment: ~20K CFIs

**Serviceable Obtainable Market (SOM)** (realistic first year):

- Target: 100-500 CFIs (0.5-2.5% of SAM)
- Revenue: $1K-5K MRR

**Positioning statement**: "ForeFlight for CFIs — the affordable, ACS-first student management platform."

---

## Timeline & Milestones

### MVP Development (Months 1-3)

**Month 1**: Core Infrastructure

- ✅ Next.js app setup (Vercel)
- ✅ FastAPI backend (Railway)
- ✅ PostgreSQL database + Alembic migrations
- ✅ Clerk authentication (CFI + student roles)
- ✅ Basic student CRUD

**Month 2**: Lesson Logging & Progress

- ⏭️ Lesson logging form (date, aircraft, hours, notes)
- ⏭️ ACS task checklist (Private Pilot)
- ⏭️ Progress dashboard (total hours, completion %)
- ⏭️ Student view (read-only progress)

**Month 3**: Polish & Launch

- ⏭️ UI/UX refinement (Tailwind CSS)
- ⏭️ Performance optimization (lazy loading, caching)
- ⏭️ Beta testing (5-10 CFIs)
- ⏭️ Public launch (ProductHunt, r/flying)

---

### Post-MVP Roadmap (Months 4-12)

**Q2 2025** (Months 4-6): Growth Features

- Automated PDF progress reports
- Email reminders (medical, written test expiration)
- Instrument & Commercial certificate support
- Stripe billing integration

**Q3 2025** (Months 7-9): Retention Features

- Flight school multi-CFI dashboard
- Aircraft scheduling (basic)
- Mobile-responsive improvements

**Q4 2025** (Months 10-12): Enterprise Features

- Flight school plan ($50/mo for 5+ CFIs)
- ForeFlight import (CSV)
- White-label options

---

## Constraints & Assumptions

### Technical Constraints

- **Budget**: $50/mo for MVP hosting (Vercel Hobby + Railway Starter)
- **Team**: Solo developer (20 hrs/week)
- **Timeline**: 3 months to MVP (60 hrs/month × 3 = 180 hours total)

### Business Constraints

- **Pricing**: Must be <$50/mo to compete with free tools (target $10/mo)
- **Compliance**: Must maintain FAA-compliant records (backup, audit trail)
- **Privacy**: Student data is PII (FERPA-adjacent, not HIPAA)

### Assumptions (Risks if wrong)

- **Assumption 1**: CFIs will pay $10/mo for time savings
  - **Risk**: If not, revenue = 0
  - **Mitigation**: Beta test pricing with 5 CFIs before launch
- **Assumption 2**: ACS-mapped progress is valuable differentiation
  - **Risk**: If CFIs don't care, no competitive advantage
  - **Mitigation**: Validate with user interviews (5+ CFIs)
- **Assumption 3**: Students want to see their own progress
  - **Risk**: If CFIs prefer to control all data, dual access is wasted effort
  - **Mitigation**: Test student view with 10 students during beta

---

## Change Log

| Date | Change | Reason | Impact |
|------|--------|--------|--------|
| 2025-10-24 | Initial version | MVP planning | Baseline |

---

## References

- **FAA ACS**: [FAA.gov Private Pilot ACS](https://www.faa.gov/training_testing/testing/acs/)
- **Market Research**: [AOPA Flight Training Survey 2024](https://www.aopa.org/)
- **Competitor Analysis**: ForeFlight, MyFlightBook, CloudAhoy feature comparison

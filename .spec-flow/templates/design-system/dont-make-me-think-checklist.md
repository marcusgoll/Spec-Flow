# Don't Make Me Think — Ship Gate Checklist

**Feature**: [Feature Name]
**Phase**: [Variations | Functional | Polish]
**Evaluator**: [Name]
**Date**: [YYYY-MM-DD]
**Scope**: [UI | API | CLI | Mixed]

---

## How scoring works

* Every item has a priority: Critical = 2 pts, Important = 1 pt, Nice-to-have = 0.5 pt.
* Section score = sum of passed items.
* Phase must meet all "Phase Gate" rules at the bottom.

**Targets**

* Critical: 100% pass
* Important: ≥90% pass
* Nice-to-have: ≥80% pass

> Rationale for thresholds and key rules draws from WCAG 2.2 AA/AAA and established research patterns.

---

## 0) Scope Guard

Before you waste time testing the wrong thing, pick the path:

* [ ] **UI present** → run Sections 1–10 + "Non-UI (if applicable)"
* [ ] **No UI (API/CLI only)** → run "Non-UI UX" section first, then only UI-relevant items (skip visual-only)

---

## 1) Visual Clarity

**Critical (2 pts each)**

* [ ] Clickables look clickable; non-clickables don't.
* [ ] One primary action clearly dominates the page.
* [ ] Destructive actions are visually distinct and require confirmation.
* [ ] Disabled looks disabled (reduced contrast/opacity; no hover/focus).
* [ ] Labels/inputs have obvious association.

**Important (1 pt each)**

* [ ] Heading hierarchy is visually obvious (size/weight/spacing).
* [ ] Primary vs secondary body text are distinct.
* [ ] Images actually support content, not decorate emptiness.
* [ ] Icons reinforce text, never replace it.

**Nice-to-have (0.5 pt each)**

* [ ] Hover gives clear affordance.
* [ ] Focus states are highly visible.
* [ ] Loading states show structure (skeletons) or progress.

---

## 2) Navigation & Orientation

**Critical**

* [ ] "Where am I?" visible via title/active-nav/breadcrumb.
* [ ] "Where can I go?" obvious; nav stable across pages.
* [ ] Home = logo in top-left; works.

**Important**

* [ ] Search is easy to find on all relevant screens.
* [ ] Nav labels use plain language (destination > clever).
* [ ] Active page clearly highlighted.
* [ ] Footer has expected links (About, Contact, Privacy, Terms).

**Nice-to-have**

* [ ] "Skip to content" link appears on focus.

---

## 3) Content Scannability

**Critical**

* [ ] Key info is placed for F-pattern scanning (top row, then left column).
* [ ] Headings are descriptive, not cute.
* [ ] Paragraphs are short; no walls of text.
* [ ] Key info visually stands out.

**Important**

* [ ] Lists use bullets for scannability.
* [ ] Clear typographic hierarchy (approx 2:1 heading ratios).
* [ ] Links are descriptive ("View pricing," not "Click here").

**Nice-to-have**

* [ ] Callouts for critical info.
* [ ] Purposeful whitespace aids reading.

---

## 4) Interactions & Affordances

**Critical**

* [ ] Users know outcome before click (verb labels).
* [ ] One obvious primary CTA per screen.
* [ ] Destructive actions confirm.
* [ ] Required fields are marked; errors appear inline immediately.

**Important**

* [ ] Related actions are grouped.
* [ ] Secondary action visually de-emphasized.
* [ ] Long operations show feedback and progress.

**Nice-to-have**

* [ ] Keyboard shortcuts documented for power users.

---

## 5) Feedback & System Status

**Critical**

* [ ] Success, error, loading states exist and are visible.
* [ ] Errors explain the problem in plain language and where it occurred.

**Important**

* [ ] Errors say how to fix.
* [ ] Success toasts auto-dismiss but can be read.
* [ ] Long tasks show progress/remaining work.

**Nice-to-have**

* [ ] Optimistic UI where safe; reverts on failure.
* [ ] Helpful empty states with CTA.

---

## 6) Cognitive Load

**Critical**

* [ ] Each screen has one primary goal.
* [ ] Remove non-essential elements.
* [ ] Don't make users remember context (persist selections, show defaults).

**Important**

* [ ] Group related info; progressive disclosure for advanced options.
* [ ] Smart defaults applied.

**Nice-to-have**

* [ ] First-time onboarding hints; power-user shortcuts later.

**Note**: Limit choices. Hick's Law is real; fewer options = faster decisions.

---

## 7) Conventions & Patterns

**Critical**

* [ ] Logo → Home.
* [ ] Form order follows expectations (name→email→password).
* [ ] Confirm on right; cancel on left; no surprises.

**Important**

* [ ] Common icons (search, menu, close) are standard.
* [ ] Correct control types (radio for single, checkbox for multi).

**Nice-to-have**

* [ ] Conventional coloring (red=danger, green=success, blue=info).

---

## 8) Error Prevention & Recovery

**Critical**

* [ ] Early validation (on blur) prevents junk submissions.
* [ ] Undo or confirmation for destructive operations.
* [ ] Errors are recoverable without losing work.

**Important**

* [ ] Constraints shown before input (e.g., password rules).
* [ ] Auto-save drafts for multi-step forms.

**Nice-to-have**

* [ ] Suggestions help fix errors (e.g., email typos).

---

## 9) Mobile & Responsive

**Critical**

* [ ] Touch targets meet **WCAG 2.2 AA** minimum: **≥24×24 CSS px** (or spacing alternative).
* [ ] Body text readable at 16px without zoom.
* [ ] No horizontal scroll; layouts adapt.

**Important**

* [ ] Important content is above the fold.
* [ ] Full-width buttons where appropriate.
* [ ] Modals fit and behave on small screens.

**Nice-to-have**

* [ ] Common mobile patterns supported (e.g., pull-to-refresh where expected).

**Stretch goal**

* [ ] **AAA** target size parity (≈ **44×44** CSS px) when feasible for high-risk controls.

---

## 10) Accessibility (WCAG 2.2 aligned)

**Critical**

* [ ] **Contrast (AA)**: normal text ≥ **4.5:1**; large text (≥18pt/24px or 14pt/18.66px bold) ≥ **3:1**.
* [ ] **Keyboard**: all interactions are operable via keyboard (no traps). ([W3C][1])
* [ ] **Focus visible** on every interactive element.
* [ ] **Labels**: every field has a programmatic label; icon-only buttons have `aria-label`.
* [ ] **Images** have meaningful `alt` text (or `alt=""` when decorative).

**Important**

* [ ] Focus indicator has strong contrast and sufficient size.
* [ ] Color isn't the only signal (add text/icon).
* [ ] Headings are semantic and ordered (h1→h2→h3).
* [ ] Error messages are announced (`aria-live="polite"`).

**Nice-to-have**

* [ ] Skip links; ARIA landmarks for regions.
* [ ] Respects reduced motion preferences.

**Stretch goal**

* [ ] **Contrast (AAA)**: normal text ≥ **7:1** when feasible.

---

## 11) Non-UI UX (API / CLI features)

Run this when the "feature" has no screens or ships mostly as backend.

**Critical**

* [ ] **Contract**: documented schema (OpenAPI/JSON Schema), versioned, and published.
* [ ] **HTTP semantics**: correct verbs, status codes, and idempotency where needed (e.g., POST+idempotency-key).
* [ ] **Errors**: human message + machine code; consistent envelope.
* [ ] **Pagination/limits** documented; safe defaults.
* [ ] **Auth**: clear flows, scopes, and token lifetimes.
* [ ] **Time**: explicit timezones and ISO-8601 everywhere.

**Important**

* [ ] **Rate limits** and headers documented.
* [ ] **Retries / backoff** guidance documented; timeouts set server-side.
* [ ] **Webhooks**: signatures, replay protection, retry policy.
* [ ] **Deprecation policy**: semver, sunsetting dates, and migration steps.

**Nice-to-have**

* [ ] **SDKs** generated from contract; examples per language.
* [ ] **CLI** has `--help` with concise examples; returns non-zero on failure.

---

## Scoring Summary

| Category             | Critical (Pass/Total) | Important (Pass/Total) | Nice-to-have (Pass/Total) |
| -------------------- | --------------------: | ---------------------: | ------------------------: |
| 1. Visual            |                  __/5 |                   __/4 |                      __/3 |
| 2. Navigation        |                  __/3 |                   __/4 |                      __/1 |
| 3. Content           |                  __/4 |                   __/3 |                      __/2 |
| 4. Interactions      |                  __/4 |                   __/3 |                      __/1 |
| 5. Feedback          |                  __/3 |                   __/3 |                      __/2 |
| 6. Cognitive Load    |                  __/3 |                   __/2 |                      __/2 |
| 7. Conventions       |                  __/3 |                   __/2 |                      __/1 |
| 8. Error Prevention  |                  __/3 |                   __/2 |                      __/2 |
| 9. Mobile            |                  __/3 |                   __/3 |                      __/1 |
| 10. Accessibility    |                  __/5 |                   __/4 |                      __/2 |
| 11. Non-UI (if used) |                  __/6 |                   __/4 |                      __/2 |
| **TOTAL**            |                **__** |                 **__** |                    **__** |

**Computed**

* Critical pass rate: ___% (target 100%)
* Important pass rate: ___% (target ≥90%)
* Nice-to-have pass rate: ___% (target ≥80%)

---

## Blockers (Critical failures)

1. [Item]

* Issue:
* Fix:
* Owner:
* Target date:

---

## Improvements (Important failures)

1. [Item]

* Issue:
* Fix:
* Priority:

---

## Future Enhancements (Nice-to-have)

1. [Item]

* Enhancement:
* Benefit:
* Effort:

---

## Phase Gates

**Variations → Functional**

* [ ] 100% Critical pass
* [ ] ≥80% Important pass
* [ ] Variant chosen via quick test or team consensus (document why)

**Functional → Polish**

* [ ] 100% Critical pass
* [ ] ≥90% Important pass
* [ ] All interactions behave correctly
* [ ] Accessibility audit shows zero critical violations

**Polish → Implementation**

* [ ] 100% Critical pass
* [ ] 100% Important pass
* [ ] ≥80% Nice-to-have pass
* [ ] Design lint: 0 critical errors
* [ ] Final sign-off recorded

**Decision**: [ ] PASS | [ ] FAIL | [ ] CONDITIONAL PASS (list conditions)

---

## Tester Notes

**What worked well**

* …

**What caused confusion**

* …

**Suggestions**

* …

**Overall impression**

* …

---

## Reference notes (why these rules exist)

* **Contrast AA/AAA thresholds** and **large text definitions** are from WCAG 2.x. AA minimums are Critical; AAA is a stretch target.
* **Focus visible** is required at AA; don't ship without it.
* **Touch target sizing**: WCAG 2.2 added **2.5.8 Target Size (Minimum)** at AA (≥24×24 or spacing alternative). 44×44 remains a solid AAA/industry goal.
* **F-pattern scanning** and scanning-first layout priorities are well-documented by NNG.
* **Fewer choices reduce decision time** (Hick's Law). Don't dump option soup on users.

---

## What changed in this refactor

1. **Aligned Accessibility to WCAG 2.2**
   Criticals now use AA minimums (contrast, focus, target size). AAA stays as stretch. Your old checklist incorrectly treated 7:1 and 44×44 as must-haves everywhere.

2. **Added Non-UI UX**
   Backend features now have a first-class audit: contracts, errors, idempotency, pagination, rate limits, versioning, and deprecation. This prevents "invisible" features from bypassing usability scrutiny.

3. **Deterministic Phase Gates**
   No more hand-wavy "feels good." You either hit the thresholds or you don't.

4. **Points System**
   Priority-weighted scoring lets you see exactly where risk lives without letting nice-to-haves block release.

5. **Scope Guard**
   Forces the reviewer to pick UI vs non-UI up front. Fewer wasted cycles.

---

## Apply it now (no ceremony)

* Drop this file into `design/checklists/dont-make-me-think.md`.
* In `/preview`, load and render section counts for fast pass/fail, and block Phase-1 ship on Critical misses.
* For API-only features, require the **Non-UI UX** section plus Accessibility AA for docs and examples.

---

**End of checklist**

Complete at the end of each design phase (Variations, Functional, Polish) to ensure the interface is intuitive before progressing.

[1]: https://www.w3.org/TR/2012/NOTE-UNDERSTANDING-WCAG20-20120103/navigation-mechanisms-focus-visible.html "Understanding Success Criterion 2.4.7"

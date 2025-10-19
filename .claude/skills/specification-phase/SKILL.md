---
name: specification-phase
description: "Capture lessons from /specify phase. Auto-triggers when: starting /specify, >3 clarifications found, classification ambiguity detected, roadmap slug mismatch. Updates when: clarification count >3, wrong classification, missing roadmap entry."
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Specification Phase: Lessons Learned

> **Dynamic data**: Frequencies, metrics, and usage statistics are tracked in [learnings.md](learnings.md) (preserved across npm updates).

**Capability**: Learn from spec generation to reduce clarifications, improve classification accuracy, and ensure roadmap integration.

**When I trigger**:
- `/specify` starts → Load lessons to guide classification and research
- Spec complete → Detect if clarifications >3, classification issues, or roadmap mismatches
- Error: Wrong classification → Capture for future prevention

**Supporting files**:
- [reference.md](reference.md) - Classification decision tree, informed guess heuristics
- [examples.md](examples.md) - Good specs (0-2 clarifications) vs bad specs (>5 clarifications)
- [templates/informed-guess-template.md](templates/informed-guess-template.md) - Template for making reasonable assumptions

---

## Common Pitfalls (Auto-Updated)

### 🚫 Over-Clarification (Too Many [NEEDS CLARIFICATION] Markers)

> **Current frequency**: See [learnings.md](learnings.md#over-clarification)

**Impact**: High (delays planning phase, frustrates users)

**Scenario**:
```
Spec generated with 7 [NEEDS CLARIFICATION] markers:
- [NEEDS CLARIFICATION: What format? CSV or JSON?]
- [NEEDS CLARIFICATION: Which fields to export?]
- [NEEDS CLARIFICATION: Email notification on completion?]
- [NEEDS CLARIFICATION: Rate limiting strategy?]
```

**Root cause**: Not using informed guesses for non-critical decisions

**Detection**:
```bash
# Count clarifications after spec generation
CLARIFICATIONS=$(grep -c "\[NEEDS CLARIFICATION" specs/$SLUG/spec.md)
if [ $CLARIFICATIONS -gt 3 ]; then
  echo "⚠️  Too many clarifications: $CLARIFICATIONS (limit: 3)"
fi
```

**Prevention**:
1. Use industry-standard defaults (see [reference.md](reference.md#informed-guess-heuristics))
2. Only mark critical scope/security decisions as NEEDS CLARIFICATION
3. Document assumptions in spec.md "Assumptions" section
4. Prioritize by impact: scope > security > UX > technical

**If encountered**:
```bash
# Reduce clarifications to 3 most critical
# Keep: Scope impacting, security/privacy critical
# Remove: Technical details with reasonable defaults
# Document removed items as assumptions
```

---

### 🚫 Wrong Classification (HAS_UI=true but no UI)

> **Current frequency**: See [learnings.md](learnings.md#wrong-classification)

**Impact**: Medium (creates unnecessary UI artifacts)

**Scenario**:
```
Feature: "Add background worker to process uploads"
Classified: HAS_UI=true (wrong - keyword "process" triggered false positive)
Result: Generated screens.yaml for a backend-only feature
```

**Root cause**: Overly broad keyword matching

**Detection**:
```bash
# After classification
if [ "$HAS_UI" = true ]; then
  # Verify UI keywords exist AND no backend-only keywords
  if [[ "$ARGUMENTS" =~ (worker|cron|job|background|migration|health.*check) ]]; then
    echo "⚠️  Possible classification error: UI + backend-only keywords"
  fi
fi
```

**Prevention**:
1. Check for backend-only keywords: worker, cron, job, migration, health check
2. Require BOTH UI keyword AND absence of backend-only keywords
3. See [reference.md](reference.md#classification-decision-tree)

---

### 🚫 Roadmap Slug Mismatch

> **Current frequency**: See [learnings.md](learnings.md#roadmap-slug-mismatch)

**Impact**: Low (manual roadmap update needed)

**Scenario**:
```
User input: "We want to add Student Progress Dashboard"
Generated slug: "add-student-progress-dashboard"
Roadmap entry: "### student-dashboard"
Result: No match found, created fresh spec
```

**Root cause**: Slug generation includes filler words

**Detection**:
```bash
# After slug generation
if [ -f ".spec-flow/memory/roadmap.md" ]; then
  FUZZY_MATCHES=$(grep -i "$SLUG" .spec-flow/memory/roadmap.md | head -3)
  if [ -n "$FUZZY_MATCHES" ]; then
    echo "⚠️  Possible roadmap matches (manual verification needed):"
    echo "$FUZZY_MATCHES"
  fi
fi
```

**Prevention**:
1. Remove filler words: "add", "create", "we want to", "get our"
2. Normalize to lowercase and kebab-case
3. Offer fuzzy matches (Levenshtein distance <3) for manual selection

---

## Successful Patterns (Auto-Updated)

### ✅ Informed Guess Strategy

> **Current usage**: See [learnings.md](learnings.md#informed-guess-strategy)

**Impact**: High (reduces clarifications)

**Scenario**:
```
When to make informed guesses instead of clarifying:
- Performance targets with reasonable defaults
- Data retention following industry standards
- Error handling with standard patterns
- Rate limiting with conservative defaults
```

**Approach**:
```bash
# Instead of [NEEDS CLARIFICATION: Performance target?]
# Use informed guess:
**Performance Targets** (Assumed):
- API response time: <500ms (95th percentile)
- Frontend FCP: <1.5s
- Database queries: <100ms

**Assumptions**:
- Standard web app performance expectations applied
- If requirements differ, specify in "Performance Requirements" section
```

**Results**:
- Clarifications: Reduced from 5-7 to 0-2
- Time to planning: Reduced by ~10 minutes
- Accuracy: 90%+ (assumptions align with actual needs)

**Reuse conditions**:
- ✓ Use when: Non-critical technical decision
- ✓ Use when: Industry standard exists
- ✓ Use when: Default won't impact scope or security
- ✗ Don't use when: Scope-defining decision
- ✗ Don't use when: Security/privacy critical
- ✗ Don't use when: No reasonable default exists

---

### ✅ Roadmap Integration

> **Current usage**: See [learnings.md](learnings.md#roadmap-integration)

**Impact**: High (seamless context reuse)

**Scenario**:
```
User: "/specify add student progress dashboard"
Generated slug: "student-progress-dashboard"
Roadmap match: Found "### student-progress-dashboard" in roadmap.md
Result: Reused context, moved to In Progress automatically
```

**Approach**:
```bash
# Normalize and match
SLUG=$(echo "$ARGUMENTS" |
  tr '[:upper:]' '[:lower:]' |
  sed 's/\bwe want to\b//g; s/\badd\b//g; s/\bcreate\b//g' |
  sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

if grep -qi "^### ${SLUG}" .spec-flow/memory/roadmap.md; then
  FROM_ROADMAP=true
  # Extract and reuse: requirements, area, role, impact/effort
  # Move to "In Progress" section
  # Add branch and spec links
fi
```

**Results**:
- Time saved: ~10 minutes (no context re-entry)
- Accuracy: Requirements already vetted
- Tracking: Automatic status updates

**Reuse conditions**:
- ✓ Use when: Feature name matches roadmap entry
- ✓ Use when: Roadmap uses consistent slug format
- ✗ Don't use when: Fresh feature not in roadmap

---

## Phase Checklist (Auto-Updated)

**Pre-phase checks**:
- [ ] Git working tree clean
- [ ] Not on main branch
- [ ] Required templates exist (.spec-flow/templates/)

**During phase**:
- [ ] Classification validates (no conflicting keywords)
- [ ] Roadmap slug normalized and checked
- [ ] Clarifications ≤3 (use informed guesses)
- [ ] Research depth appropriate for complexity

**Post-phase checks**:
- [ ] Requirements checklist complete (if exists)
- [ ] spec.md committed with proper message
- [ ] NOTES.md initialized
- [ ] Roadmap updated (if FROM_ROADMAP=true)
- [ ] visuals/ created (if HAS_UI=true)

---

## Metrics Tracking

> **Current metrics**: See [learnings.md](learnings.md#metrics)

**Targets**:
- Avg clarifications: ≤2
- Classification accuracy: ≥90%
- Roadmap match rate: ≥80%
- Time to spec: ≤15 min
- Specs without rework: ≥95%

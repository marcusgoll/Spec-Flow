# X Post Templates and Generation Guidelines

## Post Format Requirements

### Character Limits
- **Maximum**: 280 characters (enforced by X API)
- **Target**: 250-270 characters (leaves room for user edits)
- **Minimum**: 100 characters (avoid too brief announcements)

### Structure Pattern
```
{Product} v{version} {announcement-verb}!

- {feature-1}
- {feature-2}
- {feature-3}

{benefit-statement}
```

## Post Format Guidelines

**IMPORTANT: Do NOT use emojis in post content due to UTF-8 encoding issues with the X Poster API.**

Use plain text with clear formatting:
- Use bullet points (-) for feature lists
- Use descriptive prefixes: "NEW:", "FIXED:", "IMPROVED:"
- Keep language engaging and benefit-focused

## Template Examples

### Example 1: Feature Release
```
Spec-Flow v2.7.0 is here!

- One-command releases with CI validation
- Auto-close GitHub issues when features ship
- Essential cleanup for all deployment models

Ship features faster with less manual work.

Characters: 187/280
```

**CHANGELOG extraction:**
```markdown
## [2.7.0]
### Added
- One-command release workflow with CI validation
- Automatic GitHub issue closure on feature deployment
- Essential cleanup tasks for local/staging/production
```

**Generation logic:**
1. Start: "Spec-Flow v2.7.0 is here!"
2. Pick top 3 Added features
3. Format with bullet points (-)
4. End: Benefit statement "Ship features faster..."

---

### Example 2: Bug Fix Release
```
Spec-Flow v2.6.1 fixes critical issues

- Deploy validation now catches errors before quota usage
- Secret detection prevents accidental API key commits
- 40% faster task breakdown generation

More reliable, secure, and faster workflows.

Characters: 214/280
```

**CHANGELOG extraction:**
```markdown
## [2.6.1]
### Fixed
- Deploy validation failing silently
- API keys exposed in git commits
- Task generation performance regression
```

---

### Example 3: Performance Update
```
Spec-Flow v2.5.0 - Faster workflows!

- 3x faster parallel task execution
- Real-time progress tracking in terminal
- Auto-cleanup reduces context bloat by 80%

Build features in half the time.

Characters: 189/280
```

---

### Example 4: Security Release
```
Spec-Flow v2.4.2 security update

- Patch for dependency vulnerability (CVE-2024-XXXX)
- All dependencies updated to secure versions
- Enhanced secret detection patterns

Update immediately to stay secure.

Characters: 197/280
```

---

## Content Extraction Algorithm

### 1. Read CHANGELOG Section
```bash
# Extract version section from CHANGELOG
SECTION=$(sed -n "/## \[${NEW_VERSION}\]/,/## \[/p" CHANGELOG.md | head -n -1)
```

### 2. Prioritize Changes by Type
1. **Added** (new features) — Most engaging
2. **Fixed** (bug fixes) — User pain points resolved
3. **Changed** (improvements) — Enhancements to existing
4. **Security** (vulnerabilities) — Critical updates
5. **Deprecated** (removals) — Awareness
6. **Performance** (speed) — Tangible benefits

### 3. Extract Top Features
```bash
# Get Added features (limit 3)
ADDED=$(echo "$SECTION" | grep -A 10 "### Added" | grep "^-" | head -3)

# If <3 Added, supplement with Fixed
if [ $(echo "$ADDED" | wc -l) -lt 3 ]; then
  FIXED=$(echo "$SECTION" | grep -A 10 "### Fixed" | grep "^-" | head -2)
fi
```

### 4. Format with Bullet Points
```bash
# Format features as plain text bullet points
# No emojis due to UTF-8 encoding issues with X API
echo "- $FEATURE"
```

### 5. Generate Benefit Statement
**Templates:**
- "Ship features faster with less manual work."
- "Build features in half the time."
- "More reliable, secure, and faster workflows."
- "Update immediately to stay secure."
- "Simplify your workflow with one command."
- "Deploy with confidence, every time."

**Selection logic:**
- Security release → "Update immediately to stay secure."
- Performance release → "Build features in half the time."
- Automation features → "Ship features faster..."
- Bug fixes → "More reliable, secure, and faster workflows."

---

## Validation Checklist

Before posting, validate:
- [ ] Character count ≤280
- [ ] Version number matches `NEW_VERSION` variable
- [ ] At least 2 features highlighted
- [ ] No emojis used (UTF-8 encoding issues)
- [ ] Ends with benefit statement or call-to-action
- [ ] No broken formatting (line breaks preserved)
- [ ] Engaging tone (not just bullet points)

---

## Tone Guidelines

### DO
- Use active voice: "Ship features faster"
- Emphasize benefits: "less manual work"
- Keep concise: 1-2 words per feature
- Show impact: "80% faster", "3x improvement"
- End with action: "Try it now", "Update today"

### DON'T
- Passive voice: "Features can be shipped"
- Technical jargon: "AST-based context compaction"
- Verbose descriptions: Full sentences per feature
- Vague claims: "Better performance"
- End abruptly: No closing statement

---

## Edge Cases

### Too Many Features (>5 in CHANGELOG)
**Solution**: Pick top 3 by impact
- Prioritize user-facing over internal
- Breaking changes > new features > fixes
- Group related features

### Too Few Features (<2 in CHANGELOG)
**Solution**: Supplement with context
```
Spec-Flow v2.3.0 is here!

- Enhanced task breakdown with dependency graphs

More precise task ordering for complex features.
```

### Breaking Changes
**Solution**: Highlight prominently
```
Spec-Flow v3.0.0 - Breaking changes!

- New workflow state format (auto-migrated)
- Updated slash command syntax
- Migration guide included

Upgrade guide: https://...
```

### Patch Release (Minor Fixes Only)
**Solution**: Focus on reliability
```
Spec-Flow v2.2.1 patch release

- Fixed task status sync edge case
- Improved error messages for failed deployments

Small fixes, big stability gains.
```

---

## Character Optimization Strategies

### 1. Abbreviate Common Terms
- "v" instead of "version"
- "w/" instead of "with"
- "3x" instead of "three times"
- "auto-" instead of "automatic"

### 2. Remove Filler Words
- ❌ "We are excited to announce"
- ✅ "Spec-Flow v2.7.0 is here!"

### 3. Compress Feature Descriptions
- ❌ "Automatically close GitHub issues when features are deployed"
- ✅ "Auto-close GitHub issues when features ship"

### 4. Use Symbols
- "→" for transformation/result
- "+" for additions
- "↑" for improvements
- "↓" for reductions

---

## Multi-Language Support (Future)

If targeting non-English audiences, maintain format:
```
Spec-Flow v2.7.0 est disponible!

- Releases en une commande avec validation CI
- Fermeture auto des issues GitHub
- Nettoyage essentiel pour tous les modèles

Livrez des fonctionnalités plus rapidement.
```

**Note**: Current implementation English-only, validate character limits work for other languages. Do not use emojis due to UTF-8 encoding issues.

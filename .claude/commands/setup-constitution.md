# Setup Constitution: Configure Project Constitution

**Command**: `/setup-constitution`

**Purpose**: Update project constitution and sync dependent templates. Maintains constitution as single source of truth (SSOT) for all project principles and requirements.

**When to use**: When adding/removing/clarifying principles, changing quality gates, updating testing requirements, or fixing constitution errors.

**Workflow position**: Meta-command (updates rules that govern other commands)

---

## MENTAL MODEL

You are a **constitution maintainer**. Your job:

1. **Parse changes** from arguments
2. **Apply updates** to constitution.md
3. **Version semantically** (MAJOR/MINOR/PATCH)
4. **Sync templates** that reference constitution
5. **Validate consistency** (no placeholders, valid references)
6. **Capture anti-patterns** in DONT_DO.md

**Philosophy**: Constitution is the SSOT for all project rules. Templates reference constitution principles, never duplicate them. This ensures consistency across all workflow commands.

---

## EXECUTION

### Phase C.0: Parse Arguments

**Get constitution change description from arguments:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.0: PARSE ARGUMENTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -z "$ARGUMENTS" ]; then
  echo "Usage: /setup-constitution [changes description]"
  echo ""
  echo "Examples:"
  echo "  /setup-constitution Add principle: Always use TypeScript for type safety"
  echo "  /setup-constitution Remove outdated testing requirement"
  echo "  /setup-constitution Fix typo in Quality Gates section"
  echo "  /setup-constitution Update test coverage threshold from 80% to 85%"
  echo ""
  exit 1
fi

CHANGE_DESCRIPTION="$ARGUMENTS"

echo "Constitution change requested:"
echo "  $CHANGE_DESCRIPTION"
echo ""
```

---

### Phase C.1: Load Constitution

**Read existing constitution file:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.1: LOAD CONSTITUTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CONSTITUTION_FILE="\spec-flow/memory/setup-constitution.md"

if [ ! -f "$CONSTITUTION_FILE" ]; then
  echo "❌ Constitution not found: $CONSTITUTION_FILE"
  echo ""
  echo "Cannot create new constitution - must operate on existing file only"
  exit 1
fi

# Backup current version
cp "$CONSTITUTION_FILE" /tmp/setup-constitution-backup.md

echo "✅ Constitution loaded"
echo ""

# Check file size (should be <100 lines)
LINE_COUNT=$(wc -l < "$CONSTITUTION_FILE")
echo "Current size: $LINE_COUNT lines (target: <100)"

if [ "$LINE_COUNT" -gt 100 ]; then
  echo "⚠️  Constitution exceeds 100 lines"
  echo "   Consider consolidating or moving content to templates"
fi

echo ""
```

---

### Phase C.2: Parse Current Version

**Extract semantic version from constitution:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.2: PARSE VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Look for version in constitution (various formats)
CURRENT_VERSION=$(grep -E "Version:|version:|v[0-9]" "$CONSTITUTION_FILE" | \
                  head -1 | \
                  grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | \
                  head -1)

if [ -z "$CURRENT_VERSION" ]; then
  echo "⚠️  No version found, defaulting to 1.0.0"
  CURRENT_VERSION="1.0.0"
fi

# Parse semantic version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

echo "Current version: v$MAJOR.$MINOR.$PATCH"
echo ""
```

---

### Phase C.3: Determine Version Bump

**Analyze change type for semantic versioning:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.3: SEMANTIC VERSIONING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Analyzing change type..."
echo ""

# Keywords for detecting change type
CHANGE_LOWER=$(echo "$CHANGE_DESCRIPTION" | tr '[:upper:]' '[:lower:]')

# Detect MAJOR changes (breaking)
if [[ "$CHANGE_LOWER" =~ remove.*principle|remove.*requirement|breaking|delete.*principle ]]; then
  BUMP_TYPE="MAJOR"
  NEW_MAJOR=$((MAJOR + 1))
  NEW_MINOR=0
  NEW_PATCH=0

  echo "🔴 MAJOR change detected (breaking)"
  echo "   Triggers: Removed principle or mandatory requirement"

# Detect MINOR changes (additive)
elif [[ "$CHANGE_LOWER" =~ add.*principle|new.*principle|expand|enhance|add.*requirement ]]; then
  BUMP_TYPE="MINOR"
  NEW_MAJOR=$MAJOR
  NEW_MINOR=$((MINOR + 1))
  NEW_PATCH=0

  echo "🟡 MINOR change detected (additive)"
  echo "   Triggers: New principle or expanded guidance"

# Default to PATCH (fixes)
else
  BUMP_TYPE="PATCH"
  NEW_MAJOR=$MAJOR
  NEW_MINOR=$MINOR
  NEW_PATCH=$((PATCH + 1))

  echo "🟢 PATCH change detected (fix)"
  echo "   Triggers: Typo fix, date update, clarification"
fi

NEW_VERSION="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"

echo ""
echo "Version bump: v$CURRENT_VERSION → v$NEW_VERSION ($BUMP_TYPE)"
echo ""

# Confirm with user
read -p "Is this version bump correct? (y/N): " CONFIRM_VERSION

if [ "$CONFIRM_VERSION" != "y" ]; then
  echo ""
  echo "Manual version selection:"
  echo "  1. MAJOR ($((MAJOR + 1)).0.0) - Breaking change"
  echo "  2. MINOR ($MAJOR.$((MINOR + 1)).0) - New feature"
  echo "  3. PATCH ($MAJOR.$MINOR.$((PATCH + 1))) - Bug fix"
  echo ""
  read -p "Select (1-3): " VERSION_CHOICE

  case "$VERSION_CHOICE" in
    1)
      BUMP_TYPE="MAJOR"
      NEW_VERSION="$((MAJOR + 1)).0.0"
      ;;
    2)
      BUMP_TYPE="MINOR"
      NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
      ;;
    3)
      BUMP_TYPE="PATCH"
      NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
      ;;
    *)
      echo "❌ Invalid selection"
      exit 1
      ;;
  esac
fi

echo "Final version: v$NEW_VERSION"
echo ""
```

---

### Phase C.4: Apply Constitutional Changes

**Open constitution for interactive editing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.4: APPLY CHANGES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Change requested: $CHANGE_DESCRIPTION"
echo ""
echo "Opening constitution for editing..."
echo ""

# Open in editor
if command -v code &> /dev/null; then
  code --wait "$CONSTITUTION_FILE"
elif command -v vim &> /dev/null; then
  vim "$CONSTITUTION_FILE"
elif command -v nano &> /dev/null; then
  nano "$CONSTITUTION_FILE"
else
  echo "No editor found. Edit manually: $CONSTITUTION_FILE"
  echo ""
  read -p "Press Enter when editing is complete..."
fi

echo ""
echo "Checking for changes..."

# Check if file actually changed
if diff -q "$CONSTITUTION_FILE" /tmp/setup-constitution-backup.md > /dev/null; then
  echo "⚠️  No changes detected"
  echo ""
  read -p "Skip update? (y/N): " SKIP_UPDATE
  if [ "$SKIP_UPDATE" = "y" ]; then
    echo "Constitution update cancelled"
    exit 0
  fi
fi

echo "✅ Changes detected"
echo ""
```

---

### Phase C.5: Check Idempotency

**Hash content to detect actual changes:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.5: IDEMPOTENCY CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create hash of normalized content (ignore whitespace, comments)
OLD_HASH=$(grep -v "^<!--" /tmp/setup-constitution-backup.md | \
           grep -v "^#" | \
           grep -v "^$" | \
           md5sum | \
           cut -d' ' -f1)

NEW_HASH=$(grep -v "^<!--" "$CONSTITUTION_FILE" | \
           grep -v "^#" | \
           grep -v "^$" | \
           md5sum | \
           cut -d' ' -f1)

if [ "$OLD_HASH" = "$NEW_HASH" ]; then
  echo "⚠️  Content unchanged (identical hash)"
  echo ""
  echo "Only metadata or comments were modified."
  echo "Skip version bump? (y/N)"
  read -p "> " SKIP_BUMP

  if [ "$SKIP_BUMP" = "y" ]; then
    echo "Keeping version: v$CURRENT_VERSION"
    NEW_VERSION="$CURRENT_VERSION"
  fi
else
  echo "✅ Content modified (hash changed)"
fi

echo ""
```

---

### Phase C.6: Smart Template Sync

**Identify and update affected templates:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.6: TEMPLATE SYNCHRONIZATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect affected areas from change description
declare -A AFFECTED_TEMPLATES

# Auto-detect based on keywords
if [[ "$CHANGE_DESCRIPTION" =~ [Pp]lan|[Qq]uality|[Gg]ate ]]; then
  AFFECTED_TEMPLATES["plan-template.md"]="\spec-flow/templates/plan-template.md"
fi

if [[ "$CHANGE_DESCRIPTION" =~ [Tt]est|[Cc]overage|[Tt]ask ]]; then
  AFFECTED_TEMPLATES["tasks-template.md"]="\spec-flow/templates/tasks-template.md"
fi

if [[ "$CHANGE_DESCRIPTION" =~ [Ss]pec|[Rr]equirement|[Aa]cceptance ]]; then
  AFFECTED_TEMPLATES["spec-template.md"]="\spec-flow/templates/spec-template.md"
fi

if [[ "$CHANGE_DESCRIPTION" =~ [Oo]ptimize|[Pp]erformance|[Ss]ecurity ]]; then
  AFFECTED_TEMPLATES["optimization-report-template.md"]="\spec-flow/templates/optimization-report-template.md"
fi

# If no specific match, prompt user
if [ ${#AFFECTED_TEMPLATES[@]} -eq 0 ]; then
  echo "Which templates need updates?"
  echo "  1. plan-template.md (planning/quality gates)"
  echo "  2. tasks-template.md (testing/coverage)"
  echo "  3. spec-template.md (requirements/acceptance)"
  echo "  4. optimization-report-template.md (performance/security)"
  echo "  5. None"
  echo ""
  read -p "Select (1-5, comma-separated): " TEMPLATE_CHOICE

  if [[ "$TEMPLATE_CHOICE" =~ 1 ]]; then
    AFFECTED_TEMPLATES["plan-template.md"]="\spec-flow/templates/plan-template.md"
  fi
  if [[ "$TEMPLATE_CHOICE" =~ 2 ]]; then
    AFFECTED_TEMPLATES["tasks-template.md"]="\spec-flow/templates/tasks-template.md"
  fi
  if [[ "$TEMPLATE_CHOICE" =~ 3 ]]; then
    AFFECTED_TEMPLATES["spec-template.md"]="\spec-flow/templates/spec-template.md"
  fi
  if [[ "$TEMPLATE_CHOICE" =~ 4 ]]; then
    AFFECTED_TEMPLATES["optimization-report-template.md"]="\spec-flow/templates/optimization-report-template.md"
  fi
fi

if [ ${#AFFECTED_TEMPLATES[@]} -eq 0 ]; then
  echo "✅ No templates require updates"
  SYNC_IMPACT=""
else
  echo "Templates to sync: ${!AFFECTED_TEMPLATES[@]}"
  echo ""

  SYNC_IMPACT="Sync Impact:\n"

  # Update each template
  for template_name in "${!AFFECTED_TEMPLATES[@]}"; do
    template_path="${AFFECTED_TEMPLATES[$template_name]}"

    if [ ! -f "$template_path" ]; then
      echo "⚠️  Template not found: $template_path"
      continue
    fi

    echo "Updating: $template_name"

    # Update version reference in template
    sed -i "s/Constitution v[0-9]*\.[0-9]*\.[0-9]*/Constitution v$NEW_VERSION/g" "$template_path" 2>/dev/null || \
    sed -i '' "s/Constitution v[0-9]*\.[0-9]*\.[0-9]*/Constitution v$NEW_VERSION/g" "$template_path"

    # Update date
    TODAY=$(date +%Y-%m-%d)
    sed -i "s/Last Updated: [0-9-]*/Last Updated: $TODAY/g" "$template_path" 2>/dev/null || \
    sed -i '' "s/Last Updated: [0-9-]*/Last Updated: $TODAY/g" "$template_path"

    echo "  ✅ Version updated to v$NEW_VERSION"
    echo "  ✅ Date updated to $TODAY"

    SYNC_IMPACT+="- $template_name: Updated constitution reference to v$NEW_VERSION\n"

    echo ""
  done

  echo "✅ Template sync complete"
  echo ""
fi
```

---

### Phase C.7: Validate Constitution

**Run validation checks on updated constitution:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.7: VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VALIDATION_PASSED=true

# Check 1: No unexplained placeholders
echo "Checking for placeholders..."
PLACEHOLDERS=$(grep -E "\[.*\]|\{.*\}|TODO|FIXME|XXX" "$CONSTITUTION_FILE" | grep -v "^#" | grep -v "^<!--" || true)

if [ -n "$PLACEHOLDERS" ]; then
  echo "  ⚠️  Found placeholders:"
  echo "$PLACEHOLDERS" | head -3 | sed 's/^/     /'
  VALIDATION_PASSED=false
else
  echo "  ✅ No placeholders"
fi

# Check 2: Version format
echo "Checking version format..."
if [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "  ✅ Version format valid: v$NEW_VERSION"
else
  echo "  ❌ Invalid version format: $NEW_VERSION"
  VALIDATION_PASSED=false
fi

# Check 3: Date format (ISO 8601)
echo "Checking date format..."
DATES=$(grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" "$CONSTITUTION_FILE" || true)

if echo "$DATES" | grep -qvE "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"; then
  echo "  ✅ Dates found in ISO format"
else
  echo "  ⚠️  No dates found or invalid format"
fi

# Check 4: File size
echo "Checking file size..."
NEW_LINE_COUNT=$(wc -l < "$CONSTITUTION_FILE")

if [ "$NEW_LINE_COUNT" -gt 100 ]; then
  echo "  ⚠️  Constitution exceeds 100 lines ($NEW_LINE_COUNT lines)"
  echo "     Consider consolidating content"
  VALIDATION_PASSED=false
else
  echo "  ✅ File size within limit ($NEW_LINE_COUNT / 100 lines)"
fi

# Check 5: Principles are declarative
echo "Checking principle format..."
PRINCIPLES=$(grep -E "^- \*\*|^### " "$CONSTITUTION_FILE" | head -5)

if [ -n "$PRINCIPLES" ]; then
  echo "  ✅ Principles found"
else
  echo "  ⚠️  No clear principles detected"
fi

# Check 6: Cross-references valid
echo "Checking cross-references..."

# Find all §References in constitution
REFS=$(grep -o "§[A-Za-z_]*" "$CONSTITUTION_FILE" | sort -u || true)

if [ -n "$REFS" ]; then
  INVALID_REFS=0

  # Validate each reference
  while IFS= read -r ref; do
    section_name=$(echo "$ref" | sed 's/§//')

    # Check if section exists (as header or bold text)
    if ! grep -qi "$section_name" "$CONSTITUTION_FILE"; then
      echo "  ⚠️  Invalid reference: $ref (section not found)"
      INVALID_REFS=$((INVALID_REFS + 1))
    fi
  done <<< "$REFS"

  if [ "$INVALID_REFS" -eq 0 ]; then
    echo "  ✅ All $(echo "$REFS" | wc -l) cross-references valid"
  else
    VALIDATION_PASSED=false
  fi
else
  echo "  ✅ No cross-references to validate"
fi

echo ""

if [ "$VALIDATION_PASSED" = false ]; then
  echo "⚠️  Validation warnings found"
  echo ""
  read -p "Continue anyway? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    echo "Constitution update cancelled"
    # Restore backup
    cp /tmp/setup-constitution-backup.md "$CONSTITUTION_FILE"
    exit 1
  fi
else
  echo "✅ All validation checks passed"
fi

echo ""
```

---

### Phase C.8: Update Constitution Metadata

**Update version and date in constitution file:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.8: UPDATE METADATA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TODAY=$(date +%Y-%m-%d)

# Update version line
if grep -q "Version:" "$CONSTITUTION_FILE"; then
  sed -i "s/Version: .*/Version: v$NEW_VERSION/" "$CONSTITUTION_FILE" 2>/dev/null || \
  sed -i '' "s/Version: .*/Version: v$NEW_VERSION/" "$CONSTITUTION_FILE"
  echo "  ✅ Version updated: v$NEW_VERSION"
else
  # Add version if missing
  sed -i "1i **Version**: v$NEW_VERSION" "$CONSTITUTION_FILE" 2>/dev/null || \
  sed -i '' "1i\\
**Version**: v$NEW_VERSION" "$CONSTITUTION_FILE"
  echo "  ✅ Version added: v$NEW_VERSION"
fi

# Update amended date
if grep -q "Amended:" "$CONSTITUTION_FILE"; then
  sed -i "s/Amended: .*/Amended: $TODAY/" "$CONSTITUTION_FILE" 2>/dev/null || \
  sed -i '' "s/Amended: .*/Amended: $TODAY/" "$CONSTITUTION_FILE"
  echo "  ✅ Date updated: $TODAY"
else
  # Add date if missing
  sed -i "2i **Amended**: $TODAY" "$CONSTITUTION_FILE" 2>/dev/null || \
  sed -i '' "2i\\
**Amended**: $TODAY" "$CONSTITUTION_FILE"
  echo "  ✅ Date added: $TODAY"
fi

echo ""
```

---

### Phase C.9: Add Sync Impact Report

**Append sync impact as HTML comment:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.9: SYNC IMPACT REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$SYNC_IMPACT" ]; then
  # Remove old sync impact if exists
  sed -i '/<!-- SYNC IMPACT/,/-->/d' "$CONSTITUTION_FILE" 2>/dev/null || \
  sed -i '' '/<!-- SYNC IMPACT/,/-->/d' "$CONSTITUTION_FILE"

  # Add new sync impact at end
  cat >> "$CONSTITUTION_FILE" <<EOF

<!-- SYNC IMPACT: v$NEW_VERSION
$(echo -e "$SYNC_IMPACT")Last updated: $TODAY
-->
EOF

  echo "  ✅ Sync impact report added"
else
  echo "  ⚠️  No sync impact to report"
fi

echo ""
```

---

### Phase C.10: Update DONT_DO.md

**Capture anti-patterns from constitution changes:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.10: ANTI-PATTERN DETECTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$CHANGE_DESCRIPTION" =~ [Nn]ever|[Dd]on.t|[Aa]void|anti-pattern|[Ff]ail ]]; then
  echo "Change mentions anti-patterns or restrictions."
  echo ""

  DONT_DO_FILE="\spec-flow/memory/DONT_DO.md"

  read -p "Add to DONT_DO.md? (y/N): " ADD_DONT_DO

  if [ "$ADD_DONT_DO" = "y" ]; then
    read -p "Enter anti-pattern description: " ANTI_PATTERN

    if [ ! -f "$DONT_DO_FILE" ]; then
      cat > "$DONT_DO_FILE" <<'EOF'
# Don't Do This

Anti-patterns and failures discovered during development.

---

EOF
    fi

    cat >> "$DONT_DO_FILE" <<EOF

## $(date +%Y-%m-%d): $ANTI_PATTERN

**Context**: Constitution v$NEW_VERSION
**Reason**: $CHANGE_DESCRIPTION

EOF

    echo "  ✅ Added to DONT_DO.md"
    echo ""
  fi
else
  echo "No anti-pattern keywords detected"
  echo ""
fi
```

---

### Phase C.11: Update Changelog

**Record change in constitution history:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.11: CHANGELOG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CHANGELOG_FILE="\spec-flow/memory/CONSTITUTION_CHANGELOG.md"

if [ ! -f "$CHANGELOG_FILE" ]; then
  cat > "$CHANGELOG_FILE" <<'EOF'
# Constitution Change Log

All notable changes to the project constitution.

---

EOF
fi

# Prepend new entry
{
  echo ""
  echo "## v$NEW_VERSION - $TODAY"
  echo ""
  echo "**Type**: $BUMP_TYPE"
  echo ""
  echo "**Changes**: $CHANGE_DESCRIPTION"
  echo ""
  if [ -n "$SYNC_IMPACT" ]; then
    echo "**Template Impact**:"
    echo -e "$SYNC_IMPACT"
  fi
  echo ""
  cat "$CHANGELOG_FILE"
} > /tmp/changelog-new.md

mv /tmp/changelog-new.md "$CHANGELOG_FILE"

echo "✅ Changelog updated: $CHANGELOG_FILE"
echo ""
```

---

### Phase C.12: Display Changes

**Show what changed in constitution:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.12: CHANGES SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show diff
echo "Diff:"
diff -u /tmp/setup-constitution-backup.md "$CONSTITUTION_FILE" | head -30 | sed 's/^/  /'

echo ""
echo "Stats:"
echo "  Lines changed: $(diff /tmp/setup-constitution-backup.md "$CONSTITUTION_FILE" | wc -l)"
echo "  New size: $NEW_LINE_COUNT lines"
echo ""
```

---

### Phase C.13: Confirm Changes

**Review and confirm before finalizing:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHASE C.13: REVIEW CHANGES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Version: v$CURRENT_VERSION → v$NEW_VERSION ($BUMP_TYPE)"
echo "Change: $CHANGE_DESCRIPTION"
echo "Templates synced: ${#AFFECTED_TEMPLATES[@]}"
echo ""

read -p "Apply these changes? (y/N): " APPLY_CHANGES

if [ "$APPLY_CHANGES" != "y" ]; then
  echo ""
  echo "Rolling back changes..."
  cp /tmp/setup-constitution-backup.md "$CONSTITUTION_FILE"
  echo "✅ Changes reverted"
  exit 0
fi

echo ""
echo "✅ Changes applied"
echo ""
```

---

### Phase C.14: Final Output

**Display summary and next steps:**

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONSTITUTION UPDATE COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "## ✅ Constitution Updated"
echo ""
echo "**Version**: v$NEW_VERSION ($BUMP_TYPE)"
echo "**Amended**: $TODAY"
echo ""

if [ -n "$SYNC_IMPACT" ]; then
  echo "### 📊 Sync Impact"
  echo ""
  echo -e "$SYNC_IMPACT"
fi

echo "### 📝 Files Modified"
echo ""
echo "- $CONSTITUTION_FILE"

if [ ${#AFFECTED_TEMPLATES[@]} -gt 0 ]; then
  for template_name in "${!AFFECTED_TEMPLATES[@]}"; do
    echo "- ${AFFECTED_TEMPLATES[$template_name]}"
  done
fi

if [ -f "$CHANGELOG_FILE" ]; then
  echo "- $CHANGELOG_FILE"
fi

echo ""
echo "### 💾 Next Steps"
echo ""
echo "1. Review changes: git diff \spec-flow/"
echo "2. Commit changes: git add \spec-flow/ && git commit"
echo "3. Update dependent specs if needed"
echo ""

echo "---"
echo ""
echo "Constitution is SSOT - templates now reference v$NEW_VERSION"
echo ""
```

---

## ERROR HANDLING

**If constitution file missing:**

Already handled in Phase C.1 - will exit with error.

**If version format invalid:**

Already handled in Phase C.7 - validation will warn and prompt for continuation.

**If no changes made:**

Already handled in Phase C.4 - will prompt to skip update.

**If validation fails:**

Already handled in Phase C.7 - will prompt for confirmation or rollback.

---

## NOTES

**Constitution as SSOT**: Templates should reference constitution principles, never duplicate them. This ensures consistency across all workflow commands.

**Semantic Versioning**:
- MAJOR: Breaking changes (removed principle, mandatory requirement)
- MINOR: Additive changes (new principle, expanded guidance)
- PATCH: Fixes (typos, clarifications, date updates)

**Template Sync**: Only affected templates are updated. This prevents unnecessary changes and keeps diffs small.

**Idempotency**: Content hashing ensures only meaningful changes bump version. Metadata-only changes can skip versioning.

**File Size Constraint**: Keep constitution <100 lines. Detailed guidance belongs in templates, not constitution.

**Anti-Pattern Tracking**: DONT_DO.md captures failures and anti-patterns for future reference.

---

## INTEGRATION WITH OTHER COMMANDS

Other commands should reference constitution principles:

```bash
# Example: In /plan command, reference quality gates
echo "Quality gates defined in constitution.md §Quality_Gates"
echo "See: \spec-flow/memory/setup-constitution.md"
```

**Cross-references**: Use §Section_Name format for linking to constitution sections.

**Version Awareness**: Templates show which constitution version they were last synced with.


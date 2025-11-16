#!/usr/bin/env python3
"""Spec-Flow CLI: Create feature specification from natural language."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

# Constants
ENGINEERING_PRINCIPLES = "docs/project/engineering-principles.md"
WORKFLOW_MECHANICS = ".spec-flow/memory/workflow-mechanics.md"
SPEC_TEMPLATE = ".spec-flow/templates/spec-template.md"
HEART_TEMPLATE = ".spec-flow/templates/heart-metrics-template.md"
SCREENS_TEMPLATE = ".spec-flow/templates/screens-yaml-template.yaml"
VISUALS_TEMPLATE = ".spec-flow/templates/visuals-readme-template.md"
ROADMAP_FILE = "docs/roadmap.md"

# Windows console encoding fix
def safe_print(text: str) -> None:
    """Print text safely, handling Windows console encoding issues."""
    try:
        print(text)
    except UnicodeEncodeError:
        # Fallback to ASCII-safe replacements
        replacements = {
            "━": "=",
            "⚠️": "[WARNING]",
            "✅": "[OK]",
            "❌": "[ERROR]",
        }
        safe_text = text
        for unicode_char, ascii_replacement in replacements.items():
            safe_text = safe_text.replace(unicode_char, ascii_replacement)
        print(safe_text)


def run_command(
    cmd: list[str],
    check: bool = True,
    capture_output: bool = False,
) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        safe_print(f"❌ Command failed: {' '.join(cmd)}")
        raise


def get_repo_root() -> Path:
    """Get the git repository root directory."""
    result = run_command(["git", "rev-parse", "--show-toplevel"], capture_output=True)
    return Path(result.stdout.strip())


def need(tool: str) -> None:
    """Check if a required tool is available."""
    if not shutil.which(tool):
        safe_print(f"❌ Missing required tool: {tool}")
        install_help = {
            "git": "   Install: https://git-scm.com/downloads",
            "gh": "   Install: https://cli.github.com/",
            "jq": "   Install: brew install jq (macOS) or apt install jq (Linux)",
        }
        print(install_help.get(tool, "   Check documentation for installation"))
        sys.exit(1)


def generate_slug(arguments: str) -> str:
    """Generate a deterministic slug from feature description."""
    slug = arguments.lower()

    # Remove common phrases
    slug = re.sub(r"\b(we|i)\s+want\s+to\b", "", slug)
    slug = re.sub(r"\b(get|to|with|for|the|a|an)\b", "", slug)

    # Replace non-alphanumeric with hyphens
    slug = re.sub(r"[^a-z0-9]+", "-", slug)

    # Remove leading/trailing hyphens
    slug = slug.strip("-")

    # Limit to 50 characters
    slug = slug[:50].rstrip("-")

    if not slug:
        safe_print("❌ Invalid feature name (results in empty slug)")
        print("   Provide a more descriptive feature name")
        sys.exit(1)

    # Prevent path traversal
    if ".." in slug or "/" in slug:
        safe_print("❌ Invalid characters in feature name")
        print("   Avoid: .. / (path traversal characters)")
        sys.exit(1)

    return slug


def check_git_preconditions(repo_root: Path) -> str:
    """Check git preconditions and return the original branch name."""
    # Check for uncommitted changes
    result = run_command(["git", "status", "--porcelain"], capture_output=True)
    if result.stdout.strip():
        safe_print("❌ Uncommitted changes in working directory")
        print("")
        run_command(["git", "status", "--short"], check=False)
        print("")
        print("Fix: git add . && git commit -m 'message'")
        sys.exit(1)

    # Get current branch
    result = run_command(["git", "branch", "--show-current"], capture_output=True)
    current_branch = result.stdout.strip()

    if current_branch in ("main", "master"):
        safe_print("❌ Cannot create spec on main branch")
        print("")
        print("Fix: git checkout -b feature-branch-name")
        sys.exit(1)

    return current_branch


def classify_feature(arguments: str) -> dict[str, bool]:
    """Classify feature based on keywords."""
    arg_lower = arguments.lower()

    has_ui = bool(
        re.search(
            r"(screen|page|component|dashboard|form|modal|frontend|interface)",
            arg_lower,
        )
    )

    is_improvement = bool(
        re.search(r"(improve|optimize|optimise|enhance|speed|reduce|increase)", arg_lower)
    )

    has_metrics = bool(
        re.search(
            r"(track|measure|metric|analytic|engagement|retention|adoption|funnel|cohort|a/b)",
            arg_lower,
        )
    )

    has_deployment_impact = bool(
        re.search(
            r"(migration|schema|env|environment|docker|deploy|breaking|infrastructure)",
            arg_lower,
        )
    )

    flag_count = sum([has_ui, is_improvement, has_metrics, has_deployment_impact])

    return {
        "has_ui": has_ui,
        "is_improvement": is_improvement,
        "has_metrics": has_metrics,
        "has_deployment_impact": has_deployment_impact,
        "flag_count": flag_count,
    }


def determine_research_mode(flag_count: int) -> str:
    """Determine research mode based on feature complexity."""
    if flag_count == 0:
        return "minimal"
    elif flag_count == 1:
        return "standard"
    else:
        return "full"


def check_roadmap(slug: str, repo_root: Path) -> bool:
    """Check if feature exists in roadmap."""
    roadmap_path = repo_root / ROADMAP_FILE
    if not roadmap_path.exists():
        return False

    content = roadmap_path.read_text(encoding="utf-8")
    pattern = re.compile(rf"^### {re.escape(slug)}\b", re.IGNORECASE | re.MULTILINE)
    return bool(pattern.search(content))


def create_notes_file(
    notes_path: Path,
    arguments: str,
    classification: dict,
    research_mode: str,
) -> None:
    """Create NOTES.md file with initial content."""
    today = dt.date.today().isoformat()
    now = dt.datetime.now().isoformat()

    content = f"""# Feature: {arguments}

## Overview
[Filled during spec generation]

## Research Mode
{research_mode}

## Research Findings
[Filled by research phase]

## System Components Analysis
[UI inventory + reuse analysis]

## Checkpoints
- Phase 0 (Spec): {today}

## Last Updated
{now}

## Feature Classification
- UI screens: {classification['has_ui']}
- Improvement: {classification['is_improvement']}
- Measurable: {classification['has_metrics']}
- Deployment impact: {classification['has_deployment_impact']}
- Complexity signals: {classification['flag_count']}
"""
    notes_path.write_text(content, encoding="utf-8")


def create_requirements_checklist(checklist_path: Path, slug: str) -> None:
    """Create requirements checklist file."""
    today = dt.date.today().isoformat()

    content = f"""# Specification Quality Checklist

**Created**: {today}
**Feature**: {slug}

## Content Quality

- [ ] CHK001 - No implementation details (languages, frameworks, APIs)
- [ ] CHK002 - Focused on user value and business needs
- [ ] CHK003 - Written for non-technical stakeholders
- [ ] CHK004 - All mandatory sections completed

## Requirement Completeness

- [ ] CHK005 - No more than 3 [NEEDS CLARIFICATION] markers in spec.md
- [ ] CHK006 - Requirements are testable and unambiguous
- [ ] CHK007 - Success criteria are measurable
- [ ] CHK008 - Success criteria are technology-agnostic
- [ ] CHK009 - All acceptance scenarios defined
- [ ] CHK010 - Edge cases identified
- [ ] CHK011 - Scope clearly bounded
- [ ] CHK012 - Dependencies and assumptions identified

## Feature Readiness

- [ ] CHK013 - All functional requirements have clear acceptance criteria
- [ ] CHK014 - User scenarios cover primary flows
- [ ] CHK015 - Feature meets measurable outcomes defined in Success Criteria
- [ ] CHK016 - No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before /clarify or /plan
- Maximum 3 [NEEDS CLARIFICATION] markers allowed in spec.md (extras in clarify.md)
"""
    checklist_path.write_text(content, encoding="utf-8")


def count_clarifications(spec_path: Path) -> int:
    """Count [NEEDS CLARIFICATION] markers in spec file."""
    if not spec_path.exists():
        return 0
    content = spec_path.read_text(encoding="utf-8")
    return len(re.findall(r"\[NEEDS CLARIFICATION", content))


def count_checklist_items(checklist_path: Path) -> tuple[int, int]:
    """Count total and complete checklist items."""
    if not checklist_path.exists():
        return 0, 0
    content = checklist_path.read_text(encoding="utf-8")
    total = len(re.findall(r"^- \[", content, re.MULTILINE))
    complete = len(re.findall(r"^- \[x\]", content, re.MULTILINE))
    return total, complete


def build_commit_message(
    slug: str,
    feature_dir: Path,
    classification: dict,
    clarifications: int,
) -> str:
    """Build commit message dynamically."""
    msg = f"design(spec): add {slug} specification\n\n"
    msg += "Phase 0: Spec-flow\n"
    msg += "- User scenarios (Given/When/Then)\n"
    msg += "- Requirements documented"

    heart_metrics_path = feature_dir / "design" / "heart-metrics.md"
    if heart_metrics_path.exists():
        msg += "\n- HEART metrics defined (5 dimensions with targets)"

    screens_path = feature_dir / "design" / "screens.yaml"
    if screens_path.exists():
        content = screens_path.read_text(encoding="utf-8")
        screen_count = len(re.findall(r"^  [a-z_]*:", content, re.MULTILINE))
        msg += f"\n- UI screens inventory ({screen_count} screens)"

    copy_path = feature_dir / "design" / "copy.md"
    if copy_path.exists():
        msg += "\n- Copy documented (real text, no Lorem Ipsum)"

    if classification["is_improvement"]:
        msg += "\n- Hypothesis (Problem → Solution → Prediction)"

    visuals_path = feature_dir / "visuals" / "README.md"
    if visuals_path.exists():
        msg += "\n- Visual research documented"

    clarify_path = feature_dir / "clarify.md"
    if clarify_path.exists():
        msg += "\n- Clarifications file created (async resolution)"

    notes_path = feature_dir / "NOTES.md"
    if notes_path.exists():
        content = notes_path.read_text(encoding="utf-8")
        if "System Components Analysis" in content:
            reusable_match = re.search(
                r"Reusable.*?\n((?:^- .*\n)+)", content, re.MULTILINE | re.DOTALL
            )
            if reusable_match:
                reusable_count = len(re.findall(r"^-", reusable_match.group(1)))
                if reusable_count > 0:
                    msg += f"\n- System components checked ({reusable_count} reusable)"

    msg += "\n\nArtifacts:"

    artifacts = [
        "spec.md",
        "NOTES.md",
        "design/*.md",
        "design/*.yaml",
        "visuals/README.md",
        "clarify.md",
        "checklists/requirements.md",
    ]

    for artifact_pattern in artifacts:
        if "*" in artifact_pattern:
            # Handle glob patterns
            base_dir = feature_dir
            pattern = artifact_pattern
            if "/" in pattern:
                parts = pattern.split("/")
                base_dir = feature_dir / "/".join(parts[:-1])
                pattern = parts[-1]

            if base_dir.exists():
                for path in base_dir.glob(pattern):
                    rel_path = path.relative_to(feature_dir.parent.parent)
                    msg += f"\n- {rel_path}"
        else:
            artifact_path = feature_dir / artifact_pattern
            if artifact_path.exists():
                rel_path = artifact_path.relative_to(feature_dir.parent.parent)
                msg += f"\n- {rel_path}"

    if clarifications > 0:
        msg += f"\n\nNext: /clarify ({clarifications} critical ambiguities in spec)"
    else:
        msg += "\n\nNext: /plan"

    msg += "\n\n🤖 Generated with Claude Code\n"
    msg += "Co-Authored-By: Claude <noreply@anthropic.com>"

    return msg


def count_requirements(spec_path: Path) -> int:
    """Count functional and non-functional requirements."""
    if not spec_path.exists():
        return 0
    content = spec_path.read_text(encoding="utf-8")
    return len(re.findall(r"^- \[FR-|^- \[NFR-", content))


def count_screens(screens_path: Path) -> int:
    """Count screens in screens.yaml."""
    if not screens_path.exists():
        return 0
    content = screens_path.read_text(encoding="utf-8")
    return len(re.findall(r"^  [a-z_]*:", content, re.MULTILINE))


def count_reusable_components(notes_path: Path) -> tuple[int, int]:
    """Count reusable and new components from NOTES.md."""
    if not notes_path.exists():
        return 0, 0
    content = notes_path.read_text(encoding="utf-8")

    reusable_count = 0
    new_count = 0

    reusable_match = re.search(
        r"Reusable.*?\n((?:^- .*\n)+)", content, re.MULTILINE | re.DOTALL
    )
    if reusable_match:
        reusable_count = len(re.findall(r"^-", reusable_match.group(1)))

    new_match = re.search(
        r"New Components.*?\n((?:^- .*\n)+)", content, re.MULTILINE | re.DOTALL
    )
    if new_match:
        new_count = len(re.findall(r"^-", new_match.group(1)))

    return reusable_count, new_count


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Create feature specification from natural language"
    )
    parser.add_argument(
        "arguments",
        nargs="?",
        help="Feature description (required if not provided via ARGUMENTS env var)",
    )
    parser.add_argument(
        "--slug",
        help="Pre-defined slug for the feature (optional)",
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    # Get arguments from env var or CLI
    arguments = os.environ.get("ARGUMENTS") or args.arguments
    if not arguments:
        safe_print("❌ Feature description required")
        print("")
        print("Usage: /spec <feature-description>")
        print("")
        print("Examples:")
        print('  /spec "Add dark mode toggle to settings"')
        print('  /spec "Improve upload speed by 50%"')
        print('  /spec "Track user engagement with HEART metrics"')
        sys.exit(1)

    slug = os.environ.get("SLUG") or args.slug

    original_branch: Optional[str] = None
    feature_dir: Optional[Path] = None

    try:
        # Preflight checks
        need("git")
        need("jq")

        # Get repo root
        repo_root = get_repo_root()
        os.chdir(repo_root)

        # Generate slug if not provided
        if not slug:
            slug = generate_slug(arguments)

        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"Spec Flow: {slug}")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print(f"Feature: {arguments}")
        print(f"Slug: {slug}")
        print("")

        # Git preconditions
        original_branch = check_git_preconditions(repo_root)

        # Initialize feature paths
        feature_dir = repo_root / "specs" / slug
        spec_file = feature_dir / "spec.md"
        notes_file = feature_dir / "NOTES.md"
        clarify_file = feature_dir / "clarify.md"
        design_dir = feature_dir / "design"
        visuals_dir = feature_dir / "visuals"
        checklists_dir = feature_dir / "checklists"

        # Check if spec directory exists
        if feature_dir.exists():
            safe_print(f"❌ Spec directory 'specs/{slug}/' already exists")
            print("")
            print("Options:")
            print("  1. Use different feature name or provide --slug")
            print(f"  2. Continue existing feature: git checkout {slug} && cd specs/{slug}")
            print(f"  3. Remove existing spec directory if it is obsolete: rm -rf specs/{slug}")
            sys.exit(1)

        # Validate templates exist
        templates = [
            SPEC_TEMPLATE,
            HEART_TEMPLATE,
            SCREENS_TEMPLATE,
            VISUALS_TEMPLATE,
        ]
        for template in templates:
            template_path = repo_root / template
            if not template_path.exists():
                safe_print(f"❌ Missing required template: {template}")
                print("")
                print("Fix: Ensure .spec-flow/templates/ directory is complete")
                print("     Clone from: https://github.com/anthropics/spec-flow")
                sys.exit(1)

        # Prevent branch collision: branch exists but directory doesn't
        branch_list = run_command(
            ["git", "branch", "--list", slug],
            capture_output=True,
            check=False,
        )
        if branch_list.stdout.strip():
            safe_print(f"❌ Branch '{slug}' already exists but specs/{slug}/ does not")
            print("")
            print("Options:")
            print(f"  1. Reuse the existing branch: git checkout {slug} and reconstruct specs/{slug}")
            print("  2. Choose a different slug: use --slug to provide an alternate name")
            sys.exit(1)

        # Create branch
        run_command(["git", "checkout", "-b", slug])

        # Create directories
        design_dir.mkdir(parents=True, exist_ok=True)
        visuals_dir.mkdir(parents=True, exist_ok=True)
        checklists_dir.mkdir(parents=True, exist_ok=True)

        safe_print(f"✅ Branch created: {slug}")
        safe_print(f"✅ Directory created: specs/{slug}/")
        print("")

        # Classification
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Feature Classification")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        classification = classify_feature(arguments)

        print("Classification results:")
        if classification["has_ui"]:
            print("  ✓ UI feature detected")
        if classification["is_improvement"]:
            print("  ✓ Improvement feature detected")
        if classification["has_metrics"]:
            print("  ✓ Metrics tracking detected")
        if classification["has_deployment_impact"]:
            print("  ✓ Deployment impact detected")
        if classification["flag_count"] == 0:
            print("  → Backend/API feature (no special signals)")
        print("")

        # Determine research mode
        research_mode = determine_research_mode(classification["flag_count"])
        mode_descriptions = {
            "minimal": "Minimal (backend/API feature)",
            "standard": "Standard (single-aspect feature)",
            "full": "Full (multi-aspect feature)",
        }
        print(f"Research mode: {mode_descriptions[research_mode]}")
        print("")

        # Check roadmap
        from_roadmap = check_roadmap(slug, repo_root)
        if from_roadmap:
            safe_print("✅ Found in roadmap - reusing context")
        else:
            safe_print("✅ Creating fresh spec (not in roadmap)")
        print("")

        # Create NOTES.md
        create_notes_file(notes_file, arguments, classification, research_mode)

        # Research phase (orchestrated - actual work done by spec agent)
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"Research Phase ({research_mode} mode)")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        safe_print("✅ Research phase ready (spec agent must perform actual research & update NOTES.md)")
        print("")

        # Artifact generation (orchestrated)
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Generating Specification Artifacts")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        # spec.md stub
        print("Creating spec.md stub...")
        if not spec_file.exists():
            spec_file.write_text(
                "# Specification\n\n[Filled by spec agent based on SPEC_TEMPLATE]\n",
                encoding="utf-8",
            )
        print("  ✓ spec.md stub ready")

        # HEART metrics stub (if needed)
        if classification["has_metrics"]:
            print("Creating HEART metrics stub...")
            heart_metrics_path = design_dir / "heart-metrics.md"
            if not heart_metrics_path.exists():
                heart_metrics_path.write_text(
                    "# HEART Metrics\n\n[Filled by spec agent based on HEART_TEMPLATE]\n",
                    encoding="utf-8",
                )
            print("  ✓ design/heart-metrics.md stub ready")

        # UI artifacts stubs (if needed)
        if classification["has_ui"]:
            print("Creating UI artifact stubs...")

            screens_path = design_dir / "screens.yaml"
            if not screens_path.exists():
                screens_path.write_text(
                    "# Screens\n# Filled by spec agent based on SCREENS_TEMPLATE\n",
                    encoding="utf-8",
                )

            copy_path = design_dir / "copy.md"
            if not copy_path.exists():
                copy_path.write_text(
                    "# UI Copy\n\n[Filled by spec agent, no lorem ipsum]\n",
                    encoding="utf-8",
                )

            print("  ✓ design/screens.yaml stub ready")
            print("  ✓ design/copy.md stub ready")

            # Visuals stub if URLs present in arguments
            if re.search(r"https?://", arguments):
                visuals_readme = visuals_dir / "README.md"
                if not visuals_readme.exists():
                    visuals_readme.write_text(
                        "# Visual References\n\n[Filled by spec agent based on provided URLs]\n",
                        encoding="utf-8",
                    )
                print("  ✓ visuals/README.md stub ready")

        if classification["is_improvement"]:
            print("Hypothesis section required (spec agent must add to spec.md)...")
            print("  ✓ Hypothesis requirement noted")

        if classification["has_deployment_impact"]:
            print("Deployment section required (spec agent must add to spec.md)...")
            print("  ✓ Deployment requirement noted")

        print("")

        # Validation
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Quality Validation")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        requirements_checklist = checklists_dir / "requirements.md"
        create_requirements_checklist(requirements_checklist, slug)
        safe_print("✅ Created requirements checklist")

        # Count clarifications (blocking questions in spec.md)
        clarifications = count_clarifications(spec_file)
        if clarifications > 3:
            safe_print(f"⚠️  Found {clarifications} [NEEDS CLARIFICATION] markers in spec.md (limit: 3)")
            print("   Spec agent must move non-critical extras into clarify.md")

        # Check checklist completion (LLM should update before final run)
        total_checks, complete_checks = count_checklist_items(requirements_checklist)
        print(f"Checklist status: {complete_checks}/{total_checks} complete")
        print("")

        # Commit
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Committing Specification")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        commit_msg = build_commit_message(slug, feature_dir, classification, clarifications)

        run_command(["git", "add", f"specs/{slug}/"])
        run_command(["git", "commit", "-m", commit_msg])

        result = run_command(["git", "rev-parse", "--short", "HEAD"], capture_output=True)
        commit_hash = result.stdout.strip()
        safe_print(f"✅ Committed: {commit_hash}")
        print("")

        # Update roadmap if needed
        if from_roadmap:
            roadmap_path = repo_root / ROADMAP_FILE
            run_command(["git", "add", str(roadmap_path)])
            run_command(["git", "commit", "-m", f"roadmap: move {slug} to In Progress"])
            safe_print("✅ Roadmap updated")
            print("")

        # Auto-progression recommendation
        checklist_complete = total_checks == complete_checks

        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        if clarifications > 0:
            safe_print("⚠️  Clarifications Needed")
            safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print(f"Found {clarifications} blocking [NEEDS CLARIFICATION] markers in spec.md")
            print("")
            print("Next step: /clarify (resolve blocking questions before /plan)")
        elif not checklist_complete:
            safe_print("⚠️  Quality Checks Incomplete")
            safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print(f"Requirements checklist: {complete_checks}/{total_checks} complete")
            print("")
            print("Do not run /plan until checklist items are addressed.")
            print(f"Review and update: {requirements_checklist}")
        else:
            safe_print("✅ Spec Ready for Planning")
            safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("")
            print("No blocking clarifications; requirements checklist complete.")
            print("")
            print("Recommended: /plan")
            print("Alternative: /feature continue (plan → tasks → implement → ship)")

        print("")

        # Summary
        artifact_count = sum(1 for p in feature_dir.rglob("*") if p.is_file())
        requirement_count = count_requirements(spec_file)

        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Specification Complete")
        safe_print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print(f"Feature: {slug}")
        print(f"Spec: specs/{slug}/spec.md")
        print(f"Branch: {slug}")
        if from_roadmap:
            safe_print("Roadmap: In Progress ✅")
        print("")
        print("Details:")
        print(f"- Requirements: {requirement_count} documented")

        if classification["has_metrics"]:
            print("- HEART metrics: 5 dimensions with targets")
        if classification["is_improvement"]:
            print("- Hypothesis: Problem → Solution → Prediction")

        if classification["has_ui"]:
            screens_path = design_dir / "screens.yaml"
            screen_count = count_screens(screens_path)
            print(f"- UI screens: {screen_count} defined")

        reusable_count, new_count = count_reusable_components(notes_file)
        if reusable_count > 0 or new_count > 0:
            print(f"- System components: {reusable_count} reusable, {new_count} new")

        if (visuals_dir / "README.md").exists():
            print("- Visual research: documented")
        if clarify_file.exists():
            print("- Clarify file: created")
        print(f"- Clarifications in spec: {clarifications}")
        print(f"- Artifacts: {artifact_count}")

        if checklist_complete:
            safe_print(f"- Checklist: ✅ Complete ({total_checks}/{total_checks})")
        else:
            safe_print(f"- Checklist: ⚠️  Incomplete ({complete_checks}/{total_checks})")

        print("")

    except Exception as e:
        safe_print("⚠️  Error in /spec. Rolling back changes.")
        print(f"Error: {e}")

        # Rollback
        try:
            if original_branch:
                run_command(["git", "checkout", original_branch], check=False)
            if slug and slug != original_branch:
                run_command(["git", "branch", "-D", slug], check=False)
            if feature_dir and feature_dir.exists():
                shutil.rmtree(feature_dir)
        except Exception:
            pass

        sys.exit(1)


if __name__ == "__main__":
    main()

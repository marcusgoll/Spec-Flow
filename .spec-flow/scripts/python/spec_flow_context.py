#!/usr/bin/env python3
"""Utilities to compact Spec-Flow feature context."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
from pathlib import Path
from typing import Iterable, List

STRATEGIES = {
    "planning": {
        "description": "Aggressive reduction (decisions only, keep 10 checkpoints)",
        "checkpoints": 10,
        "reduction_target": 0.9,
        "keep_code_review": False,
    },
    "implementation": {
        "description": "Moderate reduction (retain top headings and 20 checkpoints)",
        "checkpoints": 20,
        "reduction_target": 0.6,
        "keep_code_review": False,
    },
    "optimization": {
        "description": "Minimal reduction (preserve review context)",
        "checkpoints": 30,
        "reduction_target": 0.3,
        "keep_code_review": True,
    },
}


def estimate_tokens(text: str) -> int:
    if not text:
        return 0
    return math.ceil(len(text) / 4)


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def detect_phase(feature_dir: Path) -> str:
    notes = read_text(feature_dir / "NOTES.md")
    lowered = notes.lower()
    if "phase 5" in lowered or "phase 6" in lowered or "phase 7" in lowered:
        return "optimization"
    if "phase 3" in lowered or "phase 4" in lowered:
        return "implementation"
    return "planning"


def decisions_only(path: Path) -> str:
    lines = [line for line in read_text(path).splitlines() if "decision" in line.lower()]
    return "\n".join(lines)


def headings_only(path: Path) -> str:
    lines = [line for line in read_text(path).splitlines() if line.strip().startswith("#")]
    return "\n".join(lines)


def recent_checkpoints(path: Path, count: int) -> str:
    checkpoints = [
        line
        for line in read_text(path).splitlines()
        if line.lstrip().startswith("-") or "checkpoint" in line.lower()
    ]
    return "\n".join(checkpoints[-count:])


def build_summary(
    feature_dir: Path,
    phase: str,
    strategy: dict,
    research_path: Path,
    notes_path: Path,
    tasks_path: Path,
    error_log_path: Path,
    plan_path: Path,
    code_review_path: Path,
    before_tokens: int,
) -> str:
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    decisions = decisions_only(research_path) or "_No explicit decisions documented._"
    headings = headings_only(plan_path) or "_No headings captured in plan.md._"
    checkpoints = recent_checkpoints(notes_path, strategy["checkpoints"]) or "_No checkpoints recorded._"
    error_log = read_text(error_log_path) or "_No errors logged._"
    code_review = ""
    if strategy["keep_code_review"] and code_review_path.exists():
        code_review = (
            "\n---\n\n## Code Review Report (Preserved)\n\n"
            f"{read_text(code_review_path)}\n"
        )
    preserved_review = "- kept Code review report (optimization phase)\n" if code_review else ""

    summary = f"""# Context Delta (Compacted - {phase.title()} Phase)

**Generated**: {now}
**Feature**: {feature_dir.name}
**Phase**: {phase}
**Strategy**: {strategy['description']}
**Original context**: {before_tokens} tokens

---

## Research Summary (Decisions Only)

{decisions}

---

## Architecture Headings

{headings}

---

## Recent Task Checkpoints (Last {strategy['checkpoints']})

{checkpoints}

---

## Error Log (Full - preserved)

{error_log}

{code_review}
---

## What Was Compacted ({phase.title()} Phase)

**Strategy**: {strategy['description']}
**Reduction target**: {int(strategy['reduction_target'] * 100)}%

**Removed:**
- removed Detailed research notes (kept decisions only)
- removed Full task descriptions (kept recent checkpoints)
- removed Intermediate implementation notes

**Preserved:**
- kept All decisions and rationale
- kept Architecture headings
- kept Recent task progress (last {strategy['checkpoints']})
- kept Full error log (all failures learned)
{preserved_review}

**Original files remain unchanged**  this is a summary for context efficiency.
"""
    return summary


def calculate_before_tokens(paths: Iterable[Path]) -> int:
    return sum(estimate_tokens(read_text(p)) for p in paths)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compact Spec-Flow context")
    parser.add_argument("--feature-dir", required=True, help="Feature directory path")
    parser.add_argument(
        "--phase",
        choices=["planning", "implementation", "optimization", "auto"],
        default="auto",
        help="Workflow phase (auto-detected if omitted)",
    )
    parser.add_argument(
        "--output",
        help="Output file for context delta (defaults to <feature>/context-delta.md)",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON summary")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    feature_dir = Path(args.feature_dir).expanduser().resolve()
    if not feature_dir.is_dir():
        raise SystemExit(f"Feature directory not found: {feature_dir}")

    phase = args.phase
    if phase == "auto":
        phase = detect_phase(feature_dir)

    strategy = STRATEGIES[phase]
    research_path = feature_dir / "research.md"
    notes_path = feature_dir / "NOTES.md"
    tasks_path = feature_dir / "tasks.md"
    error_log_path = feature_dir / "error-log.md"
    plan_path = feature_dir / "plan.md"
    code_review_path = feature_dir / "artifacts" / "code-review-report.md"

    before_tokens = calculate_before_tokens([research_path, notes_path, tasks_path])
    summary = build_summary(
        feature_dir,
        phase,
        strategy,
        research_path,
        notes_path,
        tasks_path,
        error_log_path,
        plan_path,
        code_review_path,
        before_tokens,
    )
    after_tokens = estimate_tokens(summary)

    output_path = Path(args.output) if args.output else feature_dir / "context-delta.md"
    output_path.write_text(summary, encoding="utf-8")

    notes_text = read_text(notes_path)
    timestamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    checkpoint_line = (
        f"\n- kept Context compacted ({phase} phase): "
        f"{before_tokens} -> {after_tokens} tokens ({timestamp})"
    )
    if notes_text:
        notes_path.write_text(notes_text + checkpoint_line, encoding="utf-8")

    reduction_pct = 0 if before_tokens == 0 else round((1 - (after_tokens / before_tokens)) * 100, 1)

    payload = {
        "success": True,
        "featureDir": str(feature_dir),
        "outputFile": str(output_path),
        "tokensBefore": before_tokens,
        "tokensAfter": after_tokens,
        "reductionPercent": reduction_pct,
        "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(),
    }

    if args.json:
        print(json.dumps(payload))
    else:
        print("Context compaction complete")
        print(f"Feature: {feature_dir.name}")
        print(f"Output: {output_path}")
        print(f"Before: {before_tokens} tokens")
        print(f"After:  {after_tokens} tokens")
        print(f"Saved:  {before_tokens - after_tokens} tokens ({reduction_pct}% reduction)")


if __name__ == "__main__":
    main()


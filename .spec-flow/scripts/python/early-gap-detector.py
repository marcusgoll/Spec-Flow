#!/usr/bin/env python3
"""
Early Gap Detection - Scans code for signals of missing implementations

Runs during continuous quality checks to detect potential gaps before validation.
Looks for:
- TODO comments with gap indicators
- Placeholder implementations (NotImplementedError, "Not implemented")
- Edge cases mentioned in comments
- Error handling for new error types
- Missing test coverage indicators

Usage:
    python early-gap-detector.py --changed-files file1.py file2.ts --output gaps.yaml
"""

import argparse
import re
import sys
import yaml
from pathlib import Path
from typing import List, Dict, Set
from dataclasses import dataclass, asdict


@dataclass
class Gap:
    """Represents a potential gap in implementation"""
    type: str
    file: str
    line: int
    description: str
    confidence: float
    code_snippet: str = ""


class EarlyGapDetector:
    """Detects potential gaps in code before staging validation"""

    # Gap detection patterns
    TODO_GAP_PATTERN = re.compile(
        r'#?\s*TODO:?\s+.*?(?:missing|add|implement|edge case|fix|handle|test)',
        re.IGNORECASE
    )

    PLACEHOLDER_PATTERNS = [
        re.compile(r'raise\s+NotImplementedError', re.IGNORECASE),
        re.compile(r'throw\s+new\s+Error\(["\']Not implemented', re.IGNORECASE),
        re.compile(r'console\.(log|warn)\(["\']TODO:', re.IGNORECASE),
        re.compile(r'print\(["\']TODO:', re.IGNORECASE),
    ]

    EDGE_CASE_PATTERN = re.compile(
        r'#?\s*.*?(?:edge case|boundary|corner case|special case):?\s+',
        re.IGNORECASE
    )

    ERROR_HANDLING_PATTERN = re.compile(
        r'#?\s*TODO:?\s+.*?(?:error handling|exception|catch|handle error)',
        re.IGNORECASE
    )

    MISSING_TEST_PATTERN = re.compile(
        r'#?\s*TODO:?\s+.*?(?:test|coverage|untested)',
        re.IGNORECASE
    )

    FIXME_PATTERN = re.compile(
        r'#?\s*FIXME:?\s+',
        re.IGNORECASE
    )

    HACK_PATTERN = re.compile(
        r'#?\s*HACK:?\s+',
        re.IGNORECASE
    )

    def __init__(self, changed_files: List[str]):
        """
        Initialize gap detector

        Args:
            changed_files: List of file paths to scan
        """
        self.changed_files = [Path(f) for f in changed_files if Path(f).exists()]
        self.gaps: List[Gap] = []

    def detect_gaps(self) -> List[Gap]:
        """
        Detect all potential gaps in changed files

        Returns:
            List of detected gaps
        """
        for file_path in self.changed_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()

                self._scan_file(file_path, lines)

            except UnicodeDecodeError:
                # Skip binary files
                continue
            except Exception as e:
                print(f"Warning: Could not scan {file_path}: {e}", file=sys.stderr)
                continue

        return self.gaps

    def _scan_file(self, file_path: Path, lines: List[str]):
        """Scan a single file for gaps"""

        for i, line in enumerate(lines, start=1):
            # Pattern 1: TODO comments with gap indicators
            if self.TODO_GAP_PATTERN.search(line):
                self._add_gap(
                    type="todo_comment",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.7,
                    code_snippet=self._get_snippet(lines, i)
                )

            # Pattern 2: Placeholder implementations
            for pattern in self.PLACEHOLDER_PATTERNS:
                if pattern.search(line):
                    self._add_gap(
                        type="placeholder",
                        file=str(file_path),
                        line=i,
                        description="Placeholder implementation detected",
                        confidence=0.9,
                        code_snippet=self._get_snippet(lines, i)
                    )
                    break  # Don't duplicate for multiple patterns

            # Pattern 3: Edge case comments
            if self.EDGE_CASE_PATTERN.search(line):
                self._add_gap(
                    type="edge_case",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.6,
                    code_snippet=self._get_snippet(lines, i)
                )

            # Pattern 4: Error handling TODOs
            if self.ERROR_HANDLING_PATTERN.search(line):
                self._add_gap(
                    type="error_handling",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.75,
                    code_snippet=self._get_snippet(lines, i)
                )

            # Pattern 5: Missing test indicators
            if self.MISSING_TEST_PATTERN.search(line):
                self._add_gap(
                    type="missing_test",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.65,
                    code_snippet=self._get_snippet(lines, i)
                )

            # Pattern 6: FIXME comments
            if self.FIXME_PATTERN.search(line):
                self._add_gap(
                    type="fixme",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.8,
                    code_snippet=self._get_snippet(lines, i)
                )

            # Pattern 7: HACK comments
            if self.HACK_PATTERN.search(line):
                self._add_gap(
                    type="hack",
                    file=str(file_path),
                    line=i,
                    description=line.strip(),
                    confidence=0.7,
                    code_snippet=self._get_snippet(lines, i)
                )

    def _add_gap(self, **kwargs):
        """Add a gap to the list"""
        self.gaps.append(Gap(**kwargs))

    def _get_snippet(self, lines: List[str], line_num: int, context=2) -> str:
        """
        Get code snippet around a line

        Args:
            lines: All lines in the file
            line_num: Line number (1-indexed)
            context: Number of lines before/after to include

        Returns:
            Code snippet with context
        """
        start = max(0, line_num - context - 1)
        end = min(len(lines), line_num + context)
        snippet_lines = lines[start:end]

        # Add line numbers
        numbered = []
        for i, line in enumerate(snippet_lines, start=start + 1):
            marker = "→" if i == line_num else " "
            numbered.append(f"{marker} {i:3d} | {line.rstrip()}")

        return "\n".join(numbered)

    def generate_report(self) -> Dict:
        """
        Generate gap report

        Returns:
            Dict with gap statistics and details
        """
        gaps_by_type = {}
        for gap in self.gaps:
            if gap.type not in gaps_by_type:
                gaps_by_type[gap.type] = []
            gaps_by_type[gap.type].append(asdict(gap))

        return {
            "total_gaps": len(self.gaps),
            "gaps_by_type": gaps_by_type,
            "high_confidence": len([g for g in self.gaps if g.confidence >= 0.8]),
            "medium_confidence": len([g for g in self.gaps if 0.6 <= g.confidence < 0.8]),
            "low_confidence": len([g for g in self.gaps if g.confidence < 0.6]),
        }


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Detect potential gaps in code before validation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Detect gaps in changed files
  python early-gap-detector.py --changed-files src/auth.py src/api.ts

  # Save gaps to YAML file
  python early-gap-detector.py --changed-files src/*.py --output gaps.yaml

  # Only show high-confidence gaps
  python early-gap-detector.py --changed-files src/*.py --min-confidence 0.8
        """
    )

    parser.add_argument("--changed-files", nargs="+", required=True,
                        help="Files to scan for gaps")
    parser.add_argument("--output", help="Output file for gap report (YAML)")
    parser.add_argument("--min-confidence", type=float, default=0.0,
                        help="Minimum confidence threshold (default: 0.0)")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Verbose output")

    args = parser.parse_args()

    # Create detector
    detector = EarlyGapDetector(args.changed_files)

    # Detect gaps
    gaps = detector.detect_gaps()

    # Filter by confidence
    filtered_gaps = [g for g in gaps if g.confidence >= args.min_confidence]

    # Generate report
    report = detector.generate_report()

    # Output results
    if args.output:
        output_data = {
            "gaps": [asdict(g) for g in filtered_gaps],
            "summary": report
        }
        with open(args.output, 'w') as f:
            yaml.dump(output_data, f, default_flow_style=False, sort_keys=False)

        print(f"Gap report saved to {args.output}")

    # Console output
    if args.verbose or not args.output:
        print(f"\n{'='*60}")
        print(f"Early Gap Detection Report")
        print(f"{'='*60}\n")
        print(f"Total gaps detected: {report['total_gaps']}")
        print(f"  High confidence (≥0.8): {report['high_confidence']}")
        print(f"  Medium confidence (0.6-0.8): {report['medium_confidence']}")
        print(f"  Low confidence (<0.6): {report['low_confidence']}")
        print()

        if filtered_gaps:
            print("Gaps by type:")
            for gap_type, gaps_list in report['gaps_by_type'].items():
                count = len(gaps_list)
                print(f"  {gap_type}: {count}")

            print()
            print("Details:")
            for gap in filtered_gaps[:10]:  # Show first 10
                print(f"\n{gap.file}:{gap.line}")
                print(f"  Type: {gap.type}")
                print(f"  Confidence: {gap.confidence:.2f}")
                print(f"  {gap.description}")

            if len(filtered_gaps) > 10:
                print(f"\n... and {len(filtered_gaps) - 10} more")

    # Exit code
    sys.exit(0 if report['high_confidence'] == 0 else 1)


if __name__ == "__main__":
    main()

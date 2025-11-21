#!/usr/bin/env python3
"""
Pattern Detection and Risk Classification Algorithm
Analyzes collected observations to detect patterns and classify by risk level
"""

import yaml
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Any, Tuple
from collections import defaultdict, Counter
import statistics

class PatternDetector:
    """Detects patterns from collected observations"""

    def __init__(self, learnings_dir: Path):
        self.learnings_dir = learnings_dir
        self.observations_dir = learnings_dir / 'observations'
        self.metadata_file = learnings_dir / 'learning-metadata.yaml'

        # Load configuration
        self.config = self._load_config()

        # Thresholds
        self.min_occurrences = self.config.get('min_occurrences_for_pattern', 3)
        self.min_confidence = self.config.get('min_confidence_for_auto_apply', 0.90)
        self.significance_threshold = self.config.get('statistical_significance_threshold', 0.95)
        self.window_days = self.config.get('pattern_detection_window_days', 30)

    def _load_config(self) -> Dict:
        """Load configuration from metadata file"""
        if self.metadata_file.exists():
            with open(self.metadata_file, 'r') as f:
                data = yaml.safe_load(f)
                return data.get('config', {})
        return {}

    def _load_observations(self, pattern: str) -> List[Dict]:
        """Load all observation files matching pattern"""
        observations = []
        for file in self.observations_dir.glob(pattern):
            with open(file, 'r') as f:
                data = yaml.safe_load(f)
                if data:
                    observations.extend(data)
        return observations

    def _filter_by_window(self, observations: List[Dict]) -> List[Dict]:
        """Filter observations by time window"""
        cutoff = datetime.utcnow() - timedelta(days=self.window_days)
        filtered = []

        for obs in observations:
            timestamp_str = obs.get('timestamp', '')
            try:
                timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                if timestamp >= cutoff:
                    filtered.append(obs)
            except (ValueError, AttributeError):
                continue

        return filtered

    def detect_performance_patterns(self) -> List[Dict]:
        """Detect performance improvement patterns"""
        patterns = []

        # Load tool observations
        tool_obs = self._load_observations('tool-observations-*.yaml')
        tool_obs = self._filter_by_window(tool_obs)

        if not tool_obs:
            return patterns

        # Group by tool and context
        grouped = defaultdict(list)
        for obs in tool_obs:
            key = (obs.get('tool', ''), obs.get('context', ''))
            grouped[key].append(obs)

        # Detect patterns
        for (tool, context), observations in grouped.items():
            if len(observations) < self.min_occurrences:
                continue

            # Calculate success rate and average duration
            successes = sum(1 for obs in observations if obs.get('success', False))
            success_rate = successes / len(observations)

            if success_rate >= self.min_confidence:
                durations = [obs.get('duration_ms', 0) for obs in observations]
                avg_duration = statistics.mean(durations)
                time_saved = self._calculate_time_saved(durations, context)

                if time_saved > 0:
                    pattern = {
                        'id': f"{tool.lower()}-{context.replace(' ', '-')}-001",
                        'name': f"Use {tool} for {context}",
                        'description': f"Using {tool} for {context} operations shows {success_rate:.0%} success rate",
                        'confidence': success_rate,
                        'occurrences': len(observations),
                        'time_saved_avg': time_saved / 1000,  # Convert ms to seconds
                        'last_observed': observations[-1].get('timestamp'),
                        'context': context,
                        'recommendation': f"Prefer {tool} when working with {context}",
                        'auto_applied': success_rate >= self.min_confidence
                    }
                    patterns.append(pattern)

        return patterns

    def detect_anti_patterns(self) -> List[Dict]:
        """Detect failure patterns that should be avoided"""
        antipatterns = []

        # Load failure observations
        failure_obs = self._load_observations('failure-observations-*.yaml')
        failure_obs = self._filter_by_window(failure_obs)

        if not failure_obs:
            return antipatterns

        # Group by failure type
        grouped = defaultdict(list)
        for obs in failure_obs:
            failure_type = obs.get('failure_type', 'unknown')
            grouped[failure_type].append(obs)

        # Detect anti-patterns
        for failure_type, observations in grouped.items():
            if len(observations) < 2:  # Lower threshold for failures
                continue

            # Calculate severity
            severities = [obs.get('severity', 'medium') for obs in observations]
            max_severity = self._get_max_severity(severities)

            # All observations are failures, so failure_rate = 1.0
            antipattern = {
                'id': f"{failure_type.replace('_', '-')}-001",
                'name': f"Avoid {failure_type.replace('_', ' ')}",
                'description': observations[-1].get('description', ''),
                'severity': max_severity,
                'occurrences': len(observations),
                'failure_rate': 1.0,
                'last_observed': observations[-1].get('timestamp'),
                'context': observations[-1].get('context', 'general'),
                'warning_message': f"⚠️  {observations[-1].get('description', 'Pattern detected')}",
                'prevention': self._generate_prevention_advice(failure_type, observations),
                'auto_warn': True
            }
            antipatterns.append(antipattern)

        return antipatterns

    def detect_abbreviations(self) -> List[Dict]:
        """Detect custom abbreviation patterns"""
        abbreviations = []

        # Load abbreviation observations
        abbr_obs = self._load_observations('abbreviation-observations-*.yaml')
        abbr_obs = self._filter_by_window(abbr_obs)

        if not abbr_obs:
            return abbreviations

        # Group by abbreviation
        grouped = defaultdict(list)
        for obs in abbr_obs:
            abbr = obs.get('abbr', '')
            grouped[abbr].append(obs)

        # Detect abbreviations
        for abbr, observations in grouped.items():
            if len(observations) < 5:  # Need more data for abbreviations
                continue

            # Check consistency of expansion
            expansions = [obs.get('expansion', '') for obs in observations]
            most_common_expansion = Counter(expansions).most_common(1)[0]
            expansion_text, expansion_count = most_common_expansion

            confidence = expansion_count / len(observations)

            if confidence >= 0.80:  # Lower threshold for abbreviations
                abbreviation = {
                    'abbr': abbr,
                    'expansion': expansion_text,
                    'description': f"User consistently uses '{abbr}' to mean: {expansion_text}",
                    'confidence': confidence,
                    'usage_count': len(observations),
                    'last_used': observations[-1].get('timestamp'),
                    'context': observations[-1].get('context', 'general'),
                    'examples': [obs.get('context', '') for obs in observations[:3]],
                    'auto_expand': confidence >= self.min_confidence
                }
                abbreviations.append(abbreviation)

        return abbreviations

    def detect_claude_md_tweaks(self) -> List[Dict]:
        """Detect potential CLAUDE.md optimization opportunities"""
        tweaks = []

        # Load agent observations
        agent_obs = self._load_observations('agent-observations-*.yaml')
        agent_obs = self._filter_by_window(agent_obs)

        if not agent_obs:
            return tweaks

        # Group by agent type and task type
        grouped = defaultdict(list)
        for obs in agent_obs:
            key = (obs.get('agent_type', ''), obs.get('task_type', ''))
            grouped[key].append(obs)

        # Detect agent preferences
        for (agent_type, task_type), observations in grouped.items():
            if len(observations) < 5:  # Need more data for tweaks
                continue

            # Calculate success rate and average duration
            successes = [obs for obs in observations if obs.get('success', False)]
            success_rate = len(successes) / len(observations)

            if success_rate >= 0.85:
                durations = [obs.get('duration_seconds', 0) for obs in successes]
                avg_duration = statistics.mean(durations)

                # Compare with general-purpose agent (if data exists)
                # For now, just record good performers
                if success_rate >= 0.92:
                    tweak = {
                        'id': f"prefer-{agent_type.lower()}-{task_type.lower()}-001",
                        'category': 'agent_preference',
                        'name': f"Prefer {agent_type} agent for {task_type} tasks",
                        'description': f"Using {agent_type} agent for {task_type} tasks shows {success_rate:.0%} success rate",
                        'rationale': f"{agent_type} agent has specialized context and workflows for {task_type}",
                        'confidence': success_rate,
                        'evidence': [
                            f"Success rate: {success_rate:.0%} across {len(observations)} tasks",
                            f"Average duration: {avg_duration:.1f}s per task"
                        ],
                        'impact': self._calculate_impact(success_rate, len(observations)),
                        'status': 'pending',
                        'created': datetime.utcnow().isoformat() + 'Z',
                        'applied': None,
                        'content': self._generate_tweak_content(agent_type, task_type, success_rate),
                        'approval_required': True
                    }
                    tweaks.append(tweak)

        return tweaks

    def _calculate_time_saved(self, durations: List[float], context: str) -> float:
        """Calculate estimated time saved vs alternative approach"""
        if len(durations) < 2:
            return 0.0

        # Heuristic: Assume alternative is 20% slower for inefficient operations
        avg_duration = statistics.mean(durations)
        if 'large file' in context.lower():
            # Assume alternative (reading full file) is 2x slower
            return avg_duration  # Time saved = current duration (alternative would be 2x)
        elif 'search' in context.lower():
            # Assume alternative (linear scan) is 50% slower
            return avg_duration * 0.5

        return 0.0

    def _get_max_severity(self, severities: List[str]) -> str:
        """Get maximum severity from list"""
        severity_order = ['low', 'medium', 'high', 'critical']
        max_idx = max(severity_order.index(s) for s in severities if s in severity_order)
        return severity_order[max_idx]

    def _generate_prevention_advice(self, failure_type: str, observations: List[Dict]) -> str:
        """Generate prevention advice for anti-pattern"""
        # Extract common prevention strategies
        contexts = [obs.get('context', '') for obs in observations]
        if 'schema' in failure_type.lower():
            return "Always create migrations before modifying schema files"
        elif 'test' in failure_type.lower():
            return "Run tests before committing changes"
        elif 'migration' in failure_type.lower():
            return "Test migrations locally before deploying"
        else:
            return "Follow project best practices to avoid this issue"

    def _calculate_impact(self, success_rate: float, sample_size: int) -> str:
        """Calculate impact level based on success rate and sample size"""
        if success_rate >= 0.95 and sample_size >= 10:
            return 'high'
        elif success_rate >= 0.90 and sample_size >= 5:
            return 'medium'
        else:
            return 'low'

    def _generate_tweak_content(self, agent_type: str, task_type: str, success_rate: float) -> str:
        """Generate CLAUDE.md content for tweak"""
        return f"""### Agent Selection
- For {task_type} features, prefer {agent_type} agent
- {agent_type} agent has specialized context and workflows for {task_type}
- Success rate: {success_rate:.0%} in this project
"""

    def classify_risk(self, pattern_type: str, confidence: float, impact: str) -> str:
        """Classify pattern risk level for auto-application"""
        if pattern_type == 'performance_pattern':
            # Low risk if confidence is high
            return 'low' if confidence >= self.min_confidence else 'medium'
        elif pattern_type == 'anti_pattern':
            # Low risk (just warns, doesn't block)
            return 'low'
        elif pattern_type == 'abbreviation':
            # Low risk (just expands text)
            return 'low' if confidence >= 0.90 else 'medium'
        elif pattern_type == 'claude_md_tweak':
            # Always high risk (modifies system prompt)
            return 'high'
        else:
            return 'medium'

    def analyze_all(self) -> Dict[str, List[Dict]]:
        """Analyze all observations and detect patterns"""
        results = {
            'performance_patterns': self.detect_performance_patterns(),
            'anti_patterns': self.detect_anti_patterns(),
            'abbreviations': self.detect_abbreviations(),
            'claude_md_tweaks': self.detect_claude_md_tweaks()
        }

        # Classify risk for each pattern
        for pattern_type, patterns in results.items():
            for pattern in patterns:
                confidence = pattern.get('confidence', 0.0)
                impact = pattern.get('impact', 'low')
                risk = self.classify_risk(pattern_type, confidence, impact)
                pattern['risk_level'] = risk

        return results


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: pattern-detector.py <learnings_dir> [--json]", file=sys.stderr)
        sys.exit(1)

    learnings_dir = Path(sys.argv[1])
    json_output = '--json' in sys.argv

    if not learnings_dir.exists():
        print(f"Error: Learnings directory not found: {learnings_dir}", file=sys.stderr)
        sys.exit(1)

    # Run detection
    detector = PatternDetector(learnings_dir)
    results = detector.analyze_all()

    # Output results
    if json_output:
        print(json.dumps(results, indent=2))
    else:
        # Human-readable output
        print("Pattern Detection Results")
        print("=" * 80)
        print()

        for pattern_type, patterns in results.items():
            print(f"{pattern_type.replace('_', ' ').title()}: {len(patterns)} detected")
            for pattern in patterns:
                name = pattern.get('name', pattern.get('abbr', 'Unknown'))
                confidence = pattern.get('confidence', 0.0)
                risk = pattern.get('risk_level', 'unknown')
                print(f"  • {name} (confidence: {confidence:.0%}, risk: {risk})")
            print()

    sys.exit(0)


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
Multi-agent vote aggregation script.
Implements MAKER paper's first-to-ahead-by-k algorithm and other voting strategies.
"""

import argparse
import json
import sys
from typing import List, Dict, Tuple
from collections import Counter


class VoteAggregator:
    """Aggregates votes from multiple agents using various strategies."""

    VALID_STRATEGIES = ["first_to_ahead_by_k", "unanimous", "majority", "weighted"]
    VALID_DECISIONS = ["approve", "reject", "abstain"]

    def __init__(self, votes: List[str], strategy: str, k: int = 2, weights: List[float] = None):
        """
        Initialize vote aggregator.

        Args:
            votes: List of vote decisions (approve, reject, abstain)
            strategy: Voting strategy to use
            k: k value for first-to-ahead-by-k strategy
            weights: Optional weights for weighted voting
        """
        self.votes = [v.lower() for v in votes]
        self.strategy = strategy.lower()
        self.k = k
        self.weights = weights or [1.0] * len(votes)

        self._validate_inputs()

    def _validate_inputs(self):
        """Validate input parameters."""
        if not self.votes:
            raise ValueError("No votes provided")

        if self.strategy not in self.VALID_STRATEGIES:
            raise ValueError(f"Invalid strategy: {self.strategy}. Must be one of {self.VALID_STRATEGIES}")

        for vote in self.votes:
            if vote not in self.VALID_DECISIONS:
                raise ValueError(f"Invalid vote: {vote}. Must be one of {self.VALID_DECISIONS}")

        if len(self.weights) != len(self.votes):
            raise ValueError("Number of weights must match number of votes")

    def aggregate(self) -> Tuple[str, Dict]:
        """
        Aggregate votes using the specified strategy.

        Returns:
            Tuple of (decision, metadata)
            decision: "approve" or "reject"
            metadata: Dict with details about the voting process
        """
        if self.strategy == "first_to_ahead_by_k":
            return self._first_to_ahead_by_k()
        elif self.strategy == "unanimous":
            return self._unanimous()
        elif self.strategy == "majority":
            return self._majority()
        elif self.strategy == "weighted":
            return self._weighted()
        else:
            raise ValueError(f"Unimplemented strategy: {self.strategy}")

    def _first_to_ahead_by_k(self) -> Tuple[str, Dict]:
        """
        MAKER algorithm: first option to get k votes ahead wins.

        This provides error decorrelation through early stopping.
        Inspired by: "Improving Language Model Reasoning with Self-Verification" (MAKER paper)
        """
        approve_count = 0
        reject_count = 0
        votes_used = 0

        for vote in self.votes:
            votes_used += 1

            if vote == "approve":
                approve_count += 1
            elif vote == "reject":
                reject_count += 1
            # abstain votes don't count toward either side

            # Check if one side is ahead by k
            if approve_count - reject_count >= self.k:
                decision = "approve"
                metadata = {
                    "votes_used": votes_used,
                    "total_votes": len(self.votes),
                    "approve_count": approve_count,
                    "reject_count": reject_count,
                    "k_threshold": self.k,
                    "margin": approve_count - reject_count,
                    "early_stop": votes_used < len(self.votes)
                }
                return decision, metadata

            if reject_count - approve_count >= self.k:
                decision = "reject"
                metadata = {
                    "votes_used": votes_used,
                    "total_votes": len(self.votes),
                    "approve_count": approve_count,
                    "reject_count": reject_count,
                    "k_threshold": self.k,
                    "margin": reject_count - approve_count,
                    "early_stop": votes_used < len(self.votes)
                }
                return decision, metadata

        # All votes counted, no side ahead by k
        # Fall back to simple majority
        if approve_count > reject_count:
            decision = "approve"
        elif reject_count > approve_count:
            decision = "reject"
        else:
            # Tie - default to reject (safety first)
            decision = "reject"

        metadata = {
            "votes_used": votes_used,
            "total_votes": len(self.votes),
            "approve_count": approve_count,
            "reject_count": reject_count,
            "k_threshold": self.k,
            "margin": abs(approve_count - reject_count),
            "early_stop": False,
            "tie_broken": approve_count == reject_count
        }

        return decision, metadata

    def _unanimous(self) -> Tuple[str, Dict]:
        """All non-abstain votes must agree."""
        counter = Counter(self.votes)
        approve_count = counter.get("approve", 0)
        reject_count = counter.get("reject", 0)
        abstain_count = counter.get("abstain", 0)

        # If any vote is reject, decision is reject
        if reject_count > 0:
            decision = "reject"
        # If all non-abstain votes are approve
        elif approve_count > 0 and reject_count == 0:
            decision = "approve"
        # If all votes are abstain (shouldn't happen, but handle it)
        else:
            decision = "reject"  # Default to reject for safety

        metadata = {
            "votes_used": len(self.votes),
            "total_votes": len(self.votes),
            "approve_count": approve_count,
            "reject_count": reject_count,
            "abstain_count": abstain_count,
            "unanimous": reject_count == 0 and approve_count > 0
        }

        return decision, metadata

    def _majority(self) -> Tuple[str, Dict]:
        """Simple majority wins (>50% of non-abstain votes)."""
        counter = Counter(self.votes)
        approve_count = counter.get("approve", 0)
        reject_count = counter.get("reject", 0)
        abstain_count = counter.get("abstain", 0)

        non_abstain = approve_count + reject_count

        if non_abstain == 0:
            # All abstain - default to reject
            decision = "reject"
        elif approve_count > reject_count:
            decision = "approve"
        elif reject_count > approve_count:
            decision = "reject"
        else:
            # Tie - default to reject
            decision = "reject"

        metadata = {
            "votes_used": len(self.votes),
            "total_votes": len(self.votes),
            "approve_count": approve_count,
            "reject_count": reject_count,
            "abstain_count": abstain_count,
            "percentage": (approve_count / non_abstain * 100) if non_abstain > 0 else 0,
            "tie": approve_count == reject_count and non_abstain > 0
        }

        return decision, metadata

    def _weighted(self) -> Tuple[str, Dict]:
        """Weighted voting where each vote has a weight."""
        approve_weight = 0.0
        reject_weight = 0.0
        abstain_weight = 0.0

        for vote, weight in zip(self.votes, self.weights):
            if vote == "approve":
                approve_weight += weight
            elif vote == "reject":
                reject_weight += weight
            else:
                abstain_weight += weight

        total_weight = approve_weight + reject_weight

        if total_weight == 0:
            decision = "reject"
        elif approve_weight > reject_weight:
            decision = "approve"
        elif reject_weight > approve_weight:
            decision = "reject"
        else:
            decision = "reject"

        metadata = {
            "votes_used": len(self.votes),
            "total_votes": len(self.votes),
            "approve_weight": approve_weight,
            "reject_weight": reject_weight,
            "abstain_weight": abstain_weight,
            "total_weight": total_weight,
            "percentage": (approve_weight / total_weight * 100) if total_weight > 0 else 0
        }

        return decision, metadata


def main():
    """Main entry point for CLI usage."""
    parser = argparse.ArgumentParser(
        description="Aggregate votes from multiple agents",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # MAKER algorithm (first to k=2 ahead wins)
  python vote-aggregator.py --votes '["approve","approve","reject"]' --strategy first_to_ahead_by_k --k 2

  # Unanimous voting (all must agree)
  python vote-aggregator.py --votes '["approve","approve","approve"]' --strategy unanimous

  # Simple majority
  python vote-aggregator.py --votes '["approve","reject","approve"]' --strategy majority

  # Weighted voting
  python vote-aggregator.py --votes '["approve","reject","approve"]' --strategy weighted --weights '[1.5,1.0,1.2]'
        """
    )

    parser.add_argument("--votes", required=True, help="JSON array of votes: [\"approve\",\"reject\",...]")
    parser.add_argument("--strategy", required=True, choices=VoteAggregator.VALID_STRATEGIES,
                        help="Voting strategy to use")
    parser.add_argument("--k", type=int, default=2, help="k value for first-to-ahead-by-k (default: 2)")
    parser.add_argument("--weights", help="JSON array of weights for weighted voting")
    parser.add_argument("--output", help="Output file for detailed results (JSON)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    try:
        # Parse votes
        votes = json.loads(args.votes)
        if not isinstance(votes, list):
            raise ValueError("--votes must be a JSON array")

        # Parse weights if provided
        weights = None
        if args.weights:
            weights = json.loads(args.weights)
            if not isinstance(weights, list):
                raise ValueError("--weights must be a JSON array")

        # Create aggregator and run
        aggregator = VoteAggregator(votes, args.strategy, args.k, weights)
        decision, metadata = aggregator.aggregate()

        # Prepare output
        result = {
            "decision": decision,
            "strategy": args.strategy,
            "votes": votes,
            "metadata": metadata
        }

        # Write to output file if specified
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(result, f, indent=2)

        # Print results
        if args.verbose:
            print(json.dumps(result, indent=2))
        else:
            print(f"Decision: {decision}")
            if metadata.get("early_stop"):
                print(f"  Early stop at {metadata['votes_used']}/{metadata['total_votes']} votes")
            if args.strategy == "first_to_ahead_by_k":
                print(f"  Approve: {metadata['approve_count']}, Reject: {metadata['reject_count']}, Margin: {metadata['margin']}")

        # Exit with appropriate code
        sys.exit(0 if decision == "approve" else 1)

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

from __future__ import annotations
from dataclasses import dataclass
from typing import Dict


@dataclass
class InvariantScores:
    """
    Component scores contributing to ΣC:

    Example fields:
    - truthfulness: [0,1]
    - safety: [0,1]
    - privacy: [0,1]
    - coherence: [0,1]
    """
    truthfulness: float = 1.0
    safety: float = 1.0
    privacy: float = 1.0
    coherence: float = 1.0

    def as_dict(self) -> Dict[str, float]:
        return {
            "truthfulness": self.truthfulness,
            "safety": self.safety,
            "privacy": self.privacy,
            "coherence": self.coherence,
        }


class InvariantAggregator:
    """
    ΣC kernel: weighted sum over invariants with a minimum threshold C_min.
    """

    def __init__(self, weights: Dict[str, float], c_min: float):
        self.weights = weights
        self.c_min = c_min

    def compute_sigma_c(self, scores: InvariantScores) -> float:
        values = scores.as_dict()
        total = 0.0
        for key, value in values.items():
            w = self.weights.get(key, 0.0)
            total += w * value
        return total

    def is_allowed(self, scores: InvariantScores) -> bool:
        return self.compute_sigma_c(scores) >= self.c_min
from __future__ import annotations
from abc import ABC, abstractmethod
from typing import Any, Dict
from .invariants import InvariantScores
from .state_vector import StateVector


class Daemon(ABC):
    """
    Minimal daemon contract.

    Daemon can:
    - inspect StateVector
    - inspect proposed action
    - return partial InvariantScores contribution
    """

    name: str = "daemon"

    @abstractmethod
    def evaluate(self, state: StateVector, action: Dict[str, Any]) -> InvariantScores:
        ...


class MirrorDaemon(Daemon):
    """
    Example: d_mirror — checks coherence & truthfulness heuristically.
    For now it's synthetic, but the interface is real.
    """

    name = "d_mirror"

    def evaluate(self, state: StateVector, action: Dict[str, Any]) -> InvariantScores:
        # Placeholder logic; real version could use a model call
        description = action.get("description", "")
        looks_hallucinatory = "??? " in description
        coherence = 0.3 if looks_hallucinatory else 1.0
        truthfulness = 0.5 if looks_hallucinatory else 1.0
        return InvariantScores(
            truthfulness=truthfulness,
            coherence=coherence,
            safety=1.0,
            privacy=1.0,
        )


class HoundDaemon(Daemon):
    """
    Example: d_hound — anomaly/risk detector.
    """

    name = "d_hound"

    def evaluate(self, state: StateVector, action: Dict[str, Any]) -> InvariantScores:
        risk_label = action.get("risk", "low")
        if risk_label == "high":
            safety = 0.2
        elif risk_label == "medium":
            safety = 0.7
        else:
            safety = 1.0

        return InvariantScores(
            truthfulness=1.0,
            safety=safety,
            privacy=1.0,
            coherence=1.0,
        )
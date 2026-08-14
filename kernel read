from __future__ import annotations
from typing import Any, Dict, List, Optional
import time
from .state_vector import StateVector
from .thought_object import ThoughtObject
from .invariants import InvariantAggregator, InvariantScores
from .daemons import Daemon


class PantheonKernel:
    """
    Minimal PantheonOS kernel v0.1:

    - Maintains StateVector (hash-chained)
    - Emits ThoughtObjects (hash-chained)
    - Aggregates daemon scores via ΣC
    - Blocks or allows actions based on ΣC >= C_min
    """

    def __init__(
        self,
        daemons: List[Daemon],
        aggregator: InvariantAggregator,
        origin_model: str = "pantheon-kernel-v0.1",
    ):
        self.daemons = daemons
        self.aggregator = aggregator
        self.origin_model = origin_model

        self.state = StateVector(data={})
        self._thought_chain: List[ThoughtObject] = []

    @property
    def last_thought_hash(self) -> Optional[str]:
        if not self._thought_chain:
            return None
        return self._thought_chain[-1].thought_hash

    def emit_thought(
        self,
        daemon_name: str,
        kind: str,
        payload: Dict[str, Any],
        tags: Optional[List[str]] = None,
    ) -> ThoughtObject:
        t_id = f"{int(time.time() * 1000)}-{len(self._thought_chain)}"
        thought = ThoughtObject(
            id=t_id,
            origin_model=self.origin_model,
            daemon=daemon_name,
            kind=kind,
            payload=payload,
            state_hash=self.state.state_hash,
            prev_thought_hash=self.last_thought_hash,
            tags=tags or [],
        )
        self._thought_chain.append(thought)
        return thought

    def propose_action(self, action: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run ΣC across all daemons, decide whether action is allowed,
        and if so, update StateVector and log ThoughtObjects.
        """
        combined_scores = InvariantScores(
            truthfulness=1.0,
            safety=1.0,
            privacy=1.0,
            coherence=1.0,
        )

        daemon_contributions = {}

        # Each daemon contributes a partial score; we take the min per dimension
        for d in self.daemons:
            scores = d.evaluate(self.state, action)
            daemon_contributions[d.name] = scores.as_dict()

            # Combine conservatively: take min across daemons for each dimension
            for dim, value in scores.as_dict().items():
                current = getattr(combined_scores, dim)
                setattr(combined_scores, dim, min(current, value))

        sigma_c = self.aggregator.compute_sigma_c(combined_scores)
        allowed = self.aggregator.is_allowed(combined_scores)

        # Log a ThoughtObject summarizing the gate decision
        self.emit_thought(
            daemon_name="kernel",
            kind="invariant_evaluation",
            payload={
                "action": action,
                "combined_scores": combined_scores.as_dict(),
                "daemon_contributions": daemon_contributions,
                "sigma_c": sigma_c,
                "allowed": allowed,
            },
            tags=["sigma_c", "gate"],
        )

        if allowed:
            # Apply action as patch to StateVector (simplest semantics)
            patch = action.get("state_patch", {})
            self.state = self.state.next(patch=patch)

            self.emit_thought(
                daemon_name="kernel",
                kind="action_applied",
                payload={"patch": patch, "new_state_hash": self.state.state_hash},
                tags=["action", "state_update"],
            )

        return {
            "allowed": allowed,
            "sigma_c": sigma_c,
            "scores": combined_scores.as_dict(),
            "daemon_contributions": daemon_contributions,
            "state_hash": self.state.state_hash,
        }

    def get_thought_chain(self) -> List[ThoughtObject]:
        return list(self._thought_chain)
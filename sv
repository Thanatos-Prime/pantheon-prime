from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, Optional
import hashlib
import json
import time


def _sha256_str(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


@dataclass
class StateVector:
    """
    Hash-chained global state (the Golden Thread).

    Each StateVector:
      - carries arbitrary `data`
      - points back to `prev_hash`
      - computes its own `state_hash` over (data, prev_hash, version, timestamp)
    """
    data: Dict[str, Any] = field(default_factory=dict)
    version: int = 1
    prev_hash: Optional[str] = None
    timestamp: float = field(default_factory=time.time)
    state_hash: str = field(init=False)

    def __post_init__(self) -> None:
        self.state_hash = self.compute_hash()

    def compute_hash(self) -> str:
        payload = {
            "version": self.version,
            "data": self.data,
            "prev_hash": self.prev_hash,
            "timestamp": self.timestamp,
        }
        serialized = json.dumps(payload, sort_keys=True, default=str)
        return _sha256_str(serialized)

    def next(self, patch: Dict[str, Any]) -> "StateVector":
        """
        Return a NEW StateVector with updated data and updated hash-chain.
        Functional + append-only semantics.
        """
        new_data = dict(self.data)
        new_data.update(patch)
        return StateVector(
            data=new_data,
            version=self.version,
            prev_hash=self.state_hash,
        )
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from typing import Any, Dict


@dataclass(frozen=True)
class StateVector:
    """Immutable state payload with deterministic content hash."""

    data: Dict[str, Any]

    @property
    def state_hash(self) -> str:
        payload = json.dumps(self.data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def next(self, patch: Dict[str, Any]) -> "StateVector":
        merged = dict(self.data)
        merged.update(patch)
        return StateVector(data=merged)

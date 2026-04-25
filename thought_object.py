from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import time
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class ThoughtObject:
    id: str
    origin_model: str
    daemon: str
    kind: str
    payload: Dict[str, Any]
    state_hash: str
    prev_thought_hash: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    timestamp: float = field(default_factory=time.time)

    @property
    def thought_hash(self) -> str:
        normalized = {
            "id": self.id,
            "origin_model": self.origin_model,
            "daemon": self.daemon,
            "kind": self.kind,
            "payload": self.payload,
            "state_hash": self.state_hash,
            "prev_thought_hash": self.prev_thought_hash,
            "tags": self.tags,
            "timestamp": self.timestamp,
        }
        raw = json.dumps(normalized, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

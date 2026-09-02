#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Tuple

TEXT_EXTENSIONS = {".md", ".txt", ".py", ".json", ".yaml", ".yml", ".toml", ".csv"}
SKIP_DIRS = {".git", "__pycache__", ".venv", "venv", "node_modules", ".mypy_cache", ".pytest_cache"}

CATEGORY_PATTERNS: Dict[str, List[str]] = {
    "runtime": [
        r"\b(import|from)\b", r"\bclass\b", r"\bdef\b", r"\bstreamlit\b", r"\bsubprocess\b",
        r"\bkernel\b", r"\bdaemon\b", r"\binvariant\b", r"\bstatevector\b", r"\bthoughtobject\b",
    ],
    "governance": [
        r"\binvariant\b", r"\bethic", r"\bthreshold\b", r"\bsafety\b", r"\bprivacy\b", r"\bcoherence\b", r"\bsigma\b",
    ],
    "demo": [
        r"\bdemo\b", r"\bscenario\b", r"\bwalk-through\b", r"\bhow to use this demo\b", r"\boutput:\b",
    ],
    "use_case": [
        r"\buse case\b", r"\bgetting started\b", r"\bwhat you can do\b", r"\bpractical\b", r"\bappl",
    ],
    "pseudocode": [
        r"\bpseudo-?code\b", r"\bblueprint\b", r"\bprotocol\b", r"\barchitecture\b", r"\boperating system\b",
        r"\bmodule\b", r"\bdaemon\b", r"\bstate\b", r"\blayer\b", r"\bcontinuity\b",
    ],
    "narrative": [
        r"\bmyth\b", r"\bsymbol\b", r"\bstory\b", r"\barc\b", r"\bawak\w+\b", r"\bgrimoire\b",
        r"\bbook\b", r"\bmeaning\b", r"\bmetaphor\b", r"\bcathedral\b", r"\bgarden\b",
    ],
    "frontdoor": [
        r"\bfront door\b", r"\bquickstart\b", r"\bhow to read\b", r"\bwelcome\b", r"\bglossary\b",
    ],
}

FILENAME_HINTS: Dict[str, List[str]] = {
    "runtime": [".py", "kernel", "daemon", "invariant", "streamlit", "app"],
    "governance": ["guardrail", "ethic", "invariant", "safety", "license", "legal"],
    "demo": ["demo", "scenario"],
    "use_case": ["usecase", "usecases", "productivity", "strategy", "education", "startup"],
    "pseudocode": ["protocol", "architecture", "engine", "diagram", "whitepaper", "spec"],
    "narrative": ["story", "myth", "meaning", "tarot", "resonant", "alive", "awakening"],
    "frontdoor": ["frontdoor", "quickstart", "welcome", "how to read", "for ai", "for humans"],
}

@dataclass
class FileEntry:
    path: str
    size_bytes: int
    sha256: str
    extension: str
    category: str
    confidence: float
    tags: List[str]
    first_line: str


def is_probably_text(path: Path) -> bool:
    if path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    try:
        with path.open("rb") as f:
            chunk = f.read(4096)
        if b"\x00" in chunk:
            return False
        chunk.decode("utf-8")
        return True
    except Exception:
        return False


def read_text_head(path: Path, max_chars: int = 14000) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")[:max_chars]
    except Exception:
        return ""


def score_categories(path: Path, text: str) -> Tuple[str, float, Dict[str, int]]:
    lowered = text.lower()
    name = path.name.lower()
    parent = str(path.parent).lower()

    scores = defaultdict(int)

    for category, pats in CATEGORY_PATTERNS.items():
        for pat in pats:
            scores[category] += len(re.findall(pat, lowered))

    for category, hints in FILENAME_HINTS.items():
        for hint in hints:
            if hint in name or hint in parent or (hint.startswith(".") and path.suffix.lower() == hint):
                scores[category] += 2

    # prioritize hard runtime signals
    if path.suffix.lower() == ".py":
        scores["runtime"] += 8

    if "frontdoor" in parent:
        scores["frontdoor"] += 4

    if not scores:
        return "misc", 0.2, {}

    ranked = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
    top_category, top_score = ranked[0]
    second_score = ranked[1][1] if len(ranked) > 1 else 0

    confidence = 0.5 if top_score == 0 else min(0.99, 0.55 + (top_score - second_score) / max(1, top_score + second_score + 1))
    return top_category, round(confidence, 3), dict(scores)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_tags(text: str) -> List[str]:
    text_l = text.lower()
    tag_map = {
        "statevector": ["statevector", "state vector"],
        "thoughtobjects": ["thoughtobject", "thought object"],
        "daemons": ["daemon", "d_mirror", "d_hound", "d_spider"],
        "invariants": ["invariant", "sigma", "σc", "ethical"],
        "continuity": ["continuity", "golden thread", "memory mesh"],
        "narrative": ["narrative", "story", "myth", "symbol"],
        "prosthetics": ["prosthetic", "cleos", "kintsugi", "kairos", "accelerant"],
        "multi_model": ["gpt", "claude", "gemini", "grok", "multi-model"],
    }
    tags = []
    for tag, needles in tag_map.items():
        if any(n in text_l for n in needles):
            tags.append(tag)
    return tags


def index_repo(root: Path) -> Dict[str, object]:
    entries: List[FileEntry] = []
    category_counts = Counter()
    ext_counts = Counter()

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for filename in filenames:
            path = Path(dirpath) / filename
            rel = path.relative_to(root)
            if any(part in SKIP_DIRS for part in rel.parts):
                continue
            if rel.name == "machine_index.json":
                continue

            size = path.stat().st_size
            ext = path.suffix.lower() if path.suffix else "<no_ext>"
            ext_counts[ext] += 1

            text = read_text_head(path) if is_probably_text(path) else ""
            category, confidence, _scores = score_categories(path, text)
            tags = extract_tags(text)

            first_line = ""
            if text:
                for line in text.splitlines():
                    line = line.strip()
                    if line:
                        first_line = line[:180]
                        break

            entry = FileEntry(
                path=str(rel),
                size_bytes=size,
                sha256=sha256_file(path),
                extension=ext,
                category=category,
                confidence=confidence,
                tags=tags,
                first_line=first_line,
            )
            entries.append(entry)
            category_counts[category] += 1

    entries.sort(key=lambda e: e.path)

    return {
        "schema_version": "1.0",
        "repo": root.name,
        "generated_by": "scripts/build_machine_index.py",
        "total_files": len(entries),
        "category_counts": dict(category_counts.most_common()),
        "extension_counts": dict(ext_counts.most_common()),
        "entries": [asdict(e) for e in entries],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Build machine-readable repository index")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--out", default="machine_index.json", help="Output JSON path")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    payload = index_repo(root)
    out = (root / args.out).resolve()
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Wrote {out} with {payload['total_files']} entries")


if __name__ == "__main__":
    main()

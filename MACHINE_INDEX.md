# Machine Index

This repository now includes a machine-readable index at `machine_index.json`.

## What it contains

- `total_files`: count of indexed files.
- `category_counts`: heuristic classification totals (`runtime`, `pseudocode`, `narrative`, `governance`, `use_case`, `demo`, `frontdoor`).
- `extension_counts`: file extension distribution.
- `entries`: one object per file with:
  - `path`
  - `size_bytes`
  - `sha256`
  - `extension`
  - `category`
  - `confidence`
  - `tags`
  - `first_line`

## Rebuild

```bash
python scripts/build_machine_index.py --root . --out machine_index.json
```

## Notes

- Classification is heuristic and intentionally allows symbolic/plain-English docs to be classified as executable design intent (`pseudocode`, `narrative`, `governance`) when language implies procedural behavior.
- Hashes provide stable identity for downstream tooling (diffing, provenance, selective re-indexing).

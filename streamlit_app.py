"""
PantheonOS Streamlit Entrypoint (Universal Adapter)
---------------------------------------------------
Goal: Provide ONE Streamlit script that can run the whole Pantheon without
restructuring the repo.

It tries, in order:
1) Import-based entrypoints (wrapper/run/boot/main/demo)
2) Module execution: python -m pantheon [submodule]
3) Repo runner files (demo_run.py, run.py, main.py, app.py, etc.)

It captures stdout/stderr and displays them in Streamlit.
If an entrypoint returns a Python object, we render it as JSON-ish.
"""

from __future__ import annotations

import importlib
import inspect
import json
import os
import subprocess
import sys
import time
from dataclasses import asdict, is_dataclass
from pathlib import Path
from typing import Any, Callable, Optional, Tuple, List, Dict

import streamlit as st


REPO_ROOT = Path(__file__).resolve().parent


# ----------------------------
# Utilities
# ----------------------------

def _render_obj(obj: Any) -> None:
    """Render an arbitrary object nicely in Streamlit."""
    if obj is None:
        st.info("No return object (None). See logs for details.")
        return

    # Dataclass -> dict
    if is_dataclass(obj):
        st.json(asdict(obj))
        return

    # Pydantic v1/v2
    for attr in ("model_dump", "dict"):
        if hasattr(obj, attr) and callable(getattr(obj, attr)):
            try:
                st.json(getattr(obj, attr)())
                return
            except Exception:
                pass

    # Dict / List / JSON-able
    if isinstance(obj, (dict, list, tuple)):
        try:
            st.json(obj)
        except Exception:
            st.write(obj)
        return

    # String
    if isinstance(obj, str):
        # Try JSON pretty-print if it looks like JSON
        s = obj.strip()
        if (s.startswith("{") and s.endswith("}")) or (s.startswith("[") and s.endswith("]")):
            try:
                st.json(json.loads(s))
                return
            except Exception:
                pass
        st.text(obj)
        return

    # Fallback
    st.write(obj)


def _run_callable(fn: Callable[..., Any], kwargs: Dict[str, Any]) -> Tuple[bool, str, Any]:
    """Call an entrypoint function with best-effort signature matching."""
    try:
        sig = inspect.signature(fn)
        accepted = {}
        for k, v in kwargs.items():
            if k in sig.parameters:
                accepted[k] = v

        # If it has **kwargs, pass everything
        for p in sig.parameters.values():
            if p.kind == inspect.Parameter.VAR_KEYWORD:
                accepted = kwargs
                break

        result = fn(**accepted)
        return True, f"Called {fn.__module__}.{fn.__name__}({', '.join(accepted.keys())})", result
    except Exception as e:
        return False, f"Callable failed: {e!r}", None


def _try_import_call(module_name: str, attr_names: List[str], kwargs: Dict[str, Any]) -> Tuple[bool, str, Any]:
    """Try importing a module and calling one of the named attributes if callable."""
    try:
        mod = importlib.import_module(module_name)
    except Exception as e:
        return False, f"Import failed for {module_name}: {e!r}", None

    for attr in attr_names:
        if hasattr(mod, attr):
            obj = getattr(mod, attr)
            if callable(obj):
                ok, msg, result = _run_callable(obj, kwargs)
                if ok:
                    return True, f"Import-run success: {module_name}.{attr} — {msg}", result
                # keep trying other attrs
    return False, f"No working callable found in {module_name} among {attr_names}", None


def _run_subprocess(cmd: List[str], cwd: Path) -> Tuple[bool, str]:
    """Run a subprocess and return combined output."""
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            env={**os.environ},
        )
        out = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
        ok = proc.returncode == 0
        header = f"$ {' '.join(cmd)}\n(returncode={proc.returncode})\n"
        return ok, header + out
    except Exception as e:
        return False, f"Subprocess failed for {cmd}: {e!r}"


def _candidate_runner_files(repo_root: Path) -> List[Path]:
    """Common filenames people use to run a repo."""
    names = [
        "demo_run.py",
        "run.py",
        "main.py",
        "app.py",
        "bootstrap.py",
        "pantheon_demo.py",
        "demo.py",
    ]
    hits = []
    for n in names:
        p = repo_root / n
        if p.exists() and p.is_file():
            hits.append(p)
    return hits


# ----------------------------
# Streamlit UI
# ----------------------------

st.set_page_config(page_title="PantheonOS — Universal Runner", layout="wide")
st.title("PantheonOS — Universal Runner (Odin’s Eye Doorway)")

with st.sidebar:
    st.header("Run Controls")

    target = st.text_area(
        "Target / Prompt",
        value="Rearticulate the periodic table via Odin’s Eye lens cycling; extract invariants and deltas.",
        height=140,
    )

    mode = st.selectbox(
        "Mode",
        [
            "odins_eye",
            "lens_cycle",
            "demo",
            "full_run",
            "governed_run",
        ],
        index=0,
    )

    lens_set = st.text_input("Lens set (comma-separated)", value="behavioral,structural,network,compression,governance,time,adversarial,mythic")
    max_steps = st.slider("Max steps (if supported)", 1, 200, 50)

    run_btn = st.button("Run Pantheon", type="primary")
    st.caption("This adapter tries import-first, then module/CLI fallback, then runner scripts.")


kwargs = {
    "target": target,
    "prompt": target,           # some wrappers use 'prompt'
    "query": target,            # some wrappers use 'query'
    "mode": mode,
    "lens_set": [x.strip() for x in lens_set.split(",") if x.strip()],
    "max_steps": max_steps,
    "steps": max_steps,
}


# ----------------------------
# Execution plan
# ----------------------------

IMPORT_PLAN = [
    # Most likely "wrapper" modules
    ("pantheon.wrapper", ["run", "main", "boot", "execute", "demo", "run_all"]),
    ("pantheon.core.wrapper", ["run", "main", "boot", "execute", "demo", "run_all"]),
    ("pantheon.core.orchestrator", ["run", "main", "boot", "execute", "demo", "orchestrate"]),
    ("pantheon.demo", ["run", "main", "boot", "demo", "run_demo"]),
    ("pantheon", ["run", "main", "boot", "demo", "execute"]),

    # Governance + daemon routing possibilities
    ("pantheon.governance", ["run", "gate_and_run", "main"]),
    ("pantheon.daemons", ["run", "main"]),
]

MODULE_PLAN = [
    # Module execution fallbacks
    ["-m", "pantheon"],
    ["-m", "pantheon.demo"],
    ["-m", "pantheon.wrapper"],
    ["-m", "pantheon.core.wrapper"],
]


def run_pantheon() -> None:
    st.subheader("Run Log")
    log_box = st.empty()
    logs: List[str] = []

    def log(line: str) -> None:
        logs.append(line)
        log_box.code("\n\n".join(logs)[-12000:], language="text")

    # Ensure repo root is on sys.path so local package imports work on Streamlit Cloud too
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
        log(f"Added REPO_ROOT to sys.path: {REPO_ROOT}")

    # 1) Import-first attempts
    log("=== Phase 1: Import-based entrypoint discovery ===")
    for module_name, attrs in IMPORT_PLAN:
        ok, msg, result = _try_import_call(module_name, attrs, kwargs)
        log(msg)
        if ok:
            st.success(f"Pantheon ran via import: {module_name}")
            st.subheader("Return Object")
            _render_obj(result)
            return

    # 2) Module execution fallback
    log("=== Phase 2: python -m <module> fallbacks ===")
    for mod_cmd in MODULE_PLAN:
        cmd = [sys.executable] + mod_cmd
        # Pass minimal args in a generic way (wrappers may ignore unknown args)
        cmd += ["--mode", mode, "--max_steps", str(max_steps)]
        ok, out = _run_subprocess(cmd, REPO_ROOT)
        log(out)
        if ok:
            st.success(f"Pantheon ran via module execution: {' '.join(mod_cmd)}")
            st.subheader("Process Output")
            st.code(out, language="text")
            return

    # 3) Runner script fallback
    log("=== Phase 3: Repo runner script fallbacks ===")
    runners = _candidate_runner_files(REPO_ROOT)
    if not runners:
        st.error(
            "Could not find an importable entrypoint or a runnable module, and no common runner files were found.\n\n"
            "Fix: create a small wrapper function (e.g., pantheon/wrapper.py with run()), or tell this app what file runs your repo."
        )
        return

    for runner in runners:
        cmd = [sys.executable, str(runner)]
        ok, out = _run_subprocess(cmd, REPO_ROOT)
        log(out)
        if ok:
            st.success(f"Pantheon ran via runner file: {runner.name}")
            st.subheader("Process Output")
            st.code(out, language="text")
            return

    st.error("All strategies failed. See logs above for the last errors.")


if run_btn:
    start = time.time()
    with st.spinner("Invoking the Pantheon..."):
        run_pantheon()
    st.caption(f"Elapsed: {time.time() - start:.2f}s")
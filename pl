#!/usr/bin/env python3
"""PANTHEON LOOM-001: multiscale, multimodal adaptation under regime change.

Standard-library-only, controlled toy experiment. Not a combat simulator.

Six agents receive separate binary sensor readings of an unobserved binary fact.
They can exchange one-hop readings along a communication graph. At an
unannounced regime change, visual sensors become *anticorrelated* with the
fact, while audio and thermal sensors become more dependable. Agents choose
the fact using equal votes, frozen pre-shift calibration, or adaptive
reliability calibration. Ground truth is revealed after each decision so the
adaptive policy can learn; this feedback is identical for all conditions.

Test object: SENSOR reliability x COGNITIVE plasticity x NETWORK topology.
The oversight observer evaluates local/team-level disparity and oracle ceiling.
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import random
from collections import defaultdict
from statistics import mean, stdev
from pathlib import Path

SENSORS = ("visual", "visual", "acoustic", "acoustic", "thermal", "thermal")
PRE = {"visual": .84, "acoustic": .66, "thermal": .67}
POST = {"visual": .22, "acoustic": .71, "thermal": .86}
TOPOLOGIES = {
    "isolated": (),
    "chain": ((0, 1), (1, 2), (2, 3), (3, 4), (4, 5)),
    "hub": ((2, 0), (2, 1), (2, 3), (2, 4), (2, 5)),
    "split": ((0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5)),
    "complete": tuple((i, j) for i in range(6) for j in range(i + 1, 6)),
}
POLICIES = ("equal", "fixed", "adaptive", "oracle")
STEPS = 240
CHANGE = 120
LR = .07


def neighbors(topology: str):
    out = [set([i]) for i in range(6)]
    for a, b in TOPOLOGIES[topology]:
        out[a].add(b)
        out[b].add(a)
    return tuple(tuple(sorted(group)) for group in out)


def logit(p):
    p = max(.025, min(.975, p))
    return math.log(p / (1 - p))


def probability_from_log_odds(x):
    if x >= 0:
        return 1 / (1 + math.exp(-x))
    expx = math.exp(x)
    return expx / (1 + expx)


def make_world(seed: int):
    rng = random.Random(seed)
    world = []
    for t in range(STEPS):
        truth = rng.choice((-1, 1))
        reliability = PRE if t < CHANGE else POST
        readings = tuple(truth if rng.random() < reliability[kind] else -truth for kind in SENSORS)
        world.append((truth, readings))
    return world


def simulate(seed: int, topology: str, policy: str, with_trace: bool = False):
    seen = neighbors(topology)
    world = make_world(seed)
    calibration = [{k: .65 for k in PRE} for _ in range(6)]
    output = []
    trace = []
    for t, (truth, observations) in enumerate(world):
        scores = []
        correct = []
        for i in range(6):
            s = 0.0
            for j in seen[i]:
                kind = SENSORS[j]
                if policy == "equal":
                    w = 1.0
                elif policy == "oracle":
                    w = logit((PRE if t < CHANGE else POST)[kind])
                else:
                    w = logit(calibration[i][kind])
                s += observations[j] * w
            prediction = 1 if s > 0 else -1 if s < 0 else 0
            # Tie has exactly half credit; avoids random tie-breaking confounds.
            c = .5 if prediction == 0 else float(prediction == truth)
            scores.append(s)
            correct.append(c)
        accuracy = mean(correct)
        disagreement = sum(1 for x in scores if x > 0) / 6
        disagreement = min(disagreement, 1 - disagreement) * 2
        output.append((t, accuracy, disagreement))
        if with_trace:
            trace.append({"step": t, "regime": "before" if t < CHANGE else "after",
                          "truth": truth, "readings": list(observations),
                          "agent_scores": [round(v, 4) for v in scores],
                          "accuracy": accuracy, "disagreement": disagreement,
                          "visual_estimate_agent_0": round(calibration[0]["visual"], 4)})
        # Delayed supervised feedback, AFTER all agents have decided.
        if policy == "adaptive" or (policy == "fixed" and t < CHANGE):
            for i in range(6):
                grouped = defaultdict(list)
                for j in seen[i]:
                    grouped[SENSORS[j]].append(float(observations[j] == truth))
                for kind, matches in grouped.items():
                    p = calibration[i][kind]
                    calibration[i][kind] = max(.025, min(.975, (1 - LR) * p + LR * mean(matches)))
    result = {
        "seed": seed, "topology": topology, "policy": policy,
        "early": mean(v[1] for v in output[CHANGE:CHANGE+20]),
        "late": mean(v[1] for v in output[CHANGE+60:STEPS]),
        "pre": mean(v[1] for v in output[CHANGE-60:CHANGE]),
        "all_post": mean(v[1] for v in output[CHANGE:STEPS]),
        "late_disagreement": mean(v[2] for v in output[CHANGE+60:STEPS]),
        "edge_count": len(TOPOLOGIES[topology]),
        "messages_per_step": len(TOPOLOGIES[topology]) * 2,
    }
    return result, trace


def run(replicates: int, outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)
    rows = []
    for seed in range(replicates):
        for topo in TOPOLOGIES:
            for policy in POLICIES:
                result, _ = simulate(seed, topo, policy)
                rows.append(result)
    with (outdir / "loom_001_runs.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0])
        writer.writeheader()
        writer.writerows(rows)

    summary = []
    for topo in TOPOLOGIES:
        for policy in POLICIES:
            subset = [r for r in rows if r["topology"] == topo and r["policy"] == policy]
            def avg(k): return mean(r[k] for r in subset)
            def ci95(k):
                # Descriptive normal-approximate interval of across-seed means.
                return 1.96 * stdev(r[k] for r in subset) / math.sqrt(len(subset)) if len(subset) > 1 else None
            summary.append({"topology": topo, "policy": policy,
                            "pre": round(avg("pre"), 4),
                            "early": round(avg("early"), 4),
                            "late": round(avg("late"), 4),
                            "late_ci_halfwidth": round(ci95("late"), 4) if len(subset)>1 else None,
                            "post": round(avg("all_post"), 4),
                            "late_disagreement": round(avg("late_disagreement"), 4),
                            "messages_per_step": int(avg("messages_per_step"))})
    _, trace = simulate(0, "chain", "adaptive", with_trace=True)
    results = {
        "status": "toy-model simulation; no real-world or tactical validation",
        "experiment": "LOOM-001",
        "seeds": replicates, "steps": STEPS, "change_step": CHANGE,
        "modalities": list(SENSORS), "pre_reliability": PRE, "post_reliability": POST,
        "method": "same paired worlds per policy and topology; ground truth revealed only after predictions",
        "summary": summary,
    }
    with (outdir / "loom_001_summary.json").open("w") as f:
        json.dump(results, f, indent=2)
    with (outdir / "loom_001_trace.json").open("w") as f:
        json.dump(trace, f, indent=2)
    print(f"Generated {len(rows)} trial rows at {outdir}")
    for r in summary:
        if r["topology"] in ("isolated", "chain", "complete") and r["policy"] in ("equal", "fixed", "adaptive", "oracle"):
            print(f"{r['topology']:9s} {r['policy']:8s} pre={r['pre']:.3f} early={r['early']:.3f} late={r['late']:.3f} +/-{r['late_ci_halfwidth']:.3f}")


def selftest():
    assert len(TOPOLOGIES["complete"]) == 15
    assert neighbors("isolated")[0] == (0,)
    assert all(len(n) == 6 for n in neighbors("complete"))
    assert make_world(42) == make_world(42)
    a, trace = simulate(1, "chain", "adaptive", with_trace=True)
    assert len(trace) == STEPS
    assert all(0 <= x["accuracy"] <= 1 for x in trace)
    assert trace[CHANGE]["regime"] == "after"
    b, _ = simulate(1, "chain", "adaptive")
    assert a == b
    # Complete graph produces identical observations to all agents; predictions agree.
    _, t = simulate(1, "complete", "adaptive", with_trace=True)
    assert all(x["disagreement"] == 0 for x in t)
    print("Self-tests passed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trials", type=int, default=200)
    parser.add_argument("--out", type=Path, default=Path("."))
    parser.add_argument("--selftest", action="store_true")
    args = parser.parse_args()
    if args.selftest:
        selftest()
    else:
        run(args.trials, args.out)

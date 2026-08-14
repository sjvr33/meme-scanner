#!/usr/bin/env python3
"""Replay named tokens through INTEGRITY gates. Exit 1 on mismatch."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from core.scoring.integrity import classify  # noqa: E402

FIXTURE = ROOT / "core/scoring/fixtures/integrity_aug14.json"


def main() -> int:
    payload = json.loads(FIXTURE.read_text())
    src = payload["source"]
    print(f"Integrity replay — {src['date']}")
    print(f"  RH flow {src['rh_flow']}")
    print(f"  RH reflex {src['rh_reflex']}")
    print(f"  SOL flow {src['sol_flow']}")
    print()
    print(f"{'TOKEN':<14} {'LABEL':<8} {'PLAY':<5} {'HC':<5} {'MES':<4} {'VERDICT':<6}  WHY")
    print("-" * 100)

    failures: list[str] = []
    for row in payload["tokens"]:
        result = classify(row)
        play = "Y" if result["can_play"] else "N"
        hc = "Y" if result["can_flash_hc"] else "N"
        why = "; ".join(result["reasons"])
        print(
            f"{row['symbol']:<14} {result['label']:<8} {play:<5} {hc:<5} "
            f"{result['mes_cap']:<4} {result['verdict']:<6}  {why}"
        )
        if row.get("expected_label") and row["expected_label"] != result["label"]:
            failures.append(
                f"{row['symbol']}: label {result['label']} != {row['expected_label']}"
            )
        if "expected_can_play" in row and bool(row["expected_can_play"]) != result["can_play"]:
            failures.append(
                f"{row['symbol']}: can_play {result['can_play']} != {row['expected_can_play']}"
            )

    print()
    if failures:
        print("FAIL")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("PASS — HOOPLA/COBRA/DOGO/MOW vetoed; CASHCAT/XST/STONKBROKER/FRONG not false-vetoed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

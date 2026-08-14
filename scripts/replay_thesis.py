#!/usr/bin/env python3
"""Print English thesis cards. Exit 1 if a token fails its expected verdict."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from core.scoring.thesis import card  # noqa: E402

FIXTURE = ROOT / "core/scoring/fixtures/thesis_aug14.json"


def main() -> int:
    payload = json.loads(FIXTURE.read_text())
    print(f"Thesis replay — {payload['as_of']}")
    print("English first. Scores are evidence, not the sentence.")
    print()
    failures: list[str] = []
    for row in payload["tokens"]:
        result = card(row)
        n = int(result["conviction"].split("/")[0])
        print(
            f"• {result['chain'].upper()} {result['symbol']} — {result['verdict']} "
            f"· {result['clock']} {result['seat']} · conviction {result['conviction']}"
        )
        print(f"  Thesis: {result['thesis']}")
        print(f"  Tape: {result['tape']} (integrity {result['integrity']})")
        print(f"  Public: {result['public']}")
        print(f"  Seat: {result['seat']} at {result['clock']}")
        print(f"  Retail next: {result['retail_next']}")
        print(f"  Opponent: {result['opponent']}")
        print(f"  Kill: {result['kill']}")
        print(f"  Legs: {', '.join(result['legs']) or 'none'}")
        print(f"  `{result['address']}`")
        print()
        expected = row.get("expected_verdict")
        if expected and expected != result["verdict"]:
            failures.append(f"{row['symbol']}: {result['verdict']} != {expected}")
        max_c = row.get("expected_max_conviction")
        if max_c is not None and n > int(max_c):
            failures.append(f"{row['symbol']}: conviction {n} > max {max_c}")
        min_c = row.get("expected_min_conviction")
        if min_c is not None and n < int(min_c):
            failures.append(f"{row['symbol']}: conviction {n} < min {min_c}")
        expected_clock = row.get("expected_clock")
        if expected_clock and expected_clock != result["clock"]:
            failures.append(f"{row['symbol']}: clock {result['clock']} != {expected_clock}")

    if failures:
        print("FAIL")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("PASS — fades OOP; CASHCAT T+2 / XST T+1 capped; FRONG T-1 IN can TAKE.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

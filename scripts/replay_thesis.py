#!/usr/bin/env python3
"""Print human trader rundowns. Exit 1 on verdict mismatch or cryptic Slack."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from core.scoring.thesis import card, rundown, slack_is_cryptic  # noqa: E402

FIXTURE = ROOT / "core/scoring/fixtures/thesis_aug14.json"


def main() -> int:
    payload = json.loads(FIXTURE.read_text())
    print(f"Rundown — {payload['as_of']}")
    print("How an expert would say it. No scoreboard.")
    print()
    failures: list[str] = []
    for row in payload["tokens"]:
        result = card(row)
        text = rundown(result=result)
        print(text)
        print("---")
        print()
        n = int(result["conviction"].split("/")[0])
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
        cryptic = slack_is_cryptic(text)
        if cryptic:
            failures.append(f"{row['symbol']}: cryptic Slack {cryptic}")

    if failures:
        print("FAIL")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("PASS — rundowns read as a trader, not a scoreboard.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

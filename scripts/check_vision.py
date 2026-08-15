#!/usr/bin/env python3
"""Fail if the repo drifts off the operating doctrine."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from core.scoring.book import is_hold, load_book  # noqa: E402
from core.scoring.thesis import card, rundown  # noqa: E402

CASHCAT = "0x020bfc650a365f8bb26819deaabf3e21291018b4"
FORBIDDEN_DOCS = (
    "Net sell >$500k on vol spike day post-listing",
    "TRIM / not a new TAKE",
)
REQUIRED_SNIPPETS = {
    "prompts/orchestrator-multichain.md": ("The book first", "I'd hold this — I'm not hopping"),
    "automation/scanner-multichain-prefill.json": ("The book is CASHCAT", "not hopping"),
}


def fail(msg: str) -> None:
    print(f"FAIL — {msg}")
    raise SystemExit(1)


def main() -> int:
    holds = load_book("robinhood")
    if not any((h.get("symbol") or "").upper() == "CASHCAT" for h in holds):
        fail("book.json missing CASHCAT")
    addr = (holds[0].get("address") or "").lower()
    if addr != CASHCAT:
        fail(f"book CASHCAT address {addr} != {CASHCAT}")

    row = {
        "symbol": "CASHCAT",
        "chain": "robinhood",
        "address": CASHCAT,
        "repeat_buyer_pct": 35.5,
        "net_buy_wallet_pct": 84.5,
        "mid_buy_usd": 5_000_000,
        "mid_sell_usd": 6_000_000,
        "absorption_ratio": 2.9,
        "addon_rate": 0.20,
        "age_days": 40,
        "public_label": "FLAGSHIP",
        "horizon": "hold",
        "thesis": "This is the book.",
        "kill": "I only sell if this starts printing like a farm or the pool dies.",
    }
    if not is_hold(row):
        fail("is_hold(CASHCAT) is false")
    result = card(row)
    if result["verdict"] != "HOLD":
        fail(f"CASHCAT verdict {result['verdict']} != HOLD")
    text = rundown(result=result)
    if "I'd hold this" not in text:
        fail("CASHCAT rundown missing I'd hold this")
    if "I'm out if another heavy net-sell" in text:
        fail("CASHCAT rundown still kills on a red day")

    for rel, needles in REQUIRED_SNIPPETS.items():
        body = (ROOT / rel).read_text()
        for needle in needles:
            if needle not in body:
                fail(f"{rel} missing {needle!r}")

    for rel in (
        "chains/robinhood/signals.md",
        "core/scoring/EDGE.md",
        "docs/AUTOMATION.md",
        "prompts/orchestrator-multichain.md",
    ):
        body = (ROOT / rel).read_text()
        for phrase in FORBIDDEN_DOCS:
            if phrase in body:
                fail(f"{rel} still contains {phrase!r}")

    for script in ("scripts/replay_integrity.py", "scripts/replay_thesis.py"):
        proc = subprocess.run([sys.executable, str(ROOT / script)], cwd=ROOT, capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr)
            fail(f"{script} exit {proc.returncode}")

    print("PASS — book is CASHCAT, HOLD not a hop, farms still die, daily prompts agree.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

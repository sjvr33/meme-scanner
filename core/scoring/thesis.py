"""Thesis / conviction helpers. Thresholds match core/scoring/THESIS.md."""

from __future__ import annotations

from typing import Any

from core.scoring.ahead import clock_and_seat
from core.scoring.integrity import classify as classify_integrity

ABSORP_LADDER_LO = 1.2
ABSORP_LADDER_HI = 8.0
STORY_LEGS = frozenset({"EARLY", "PRODUCT"})

STANCE = {
    "TAKE": "I'd take a small look",
    "WATCH": "I'm watching — not pressing",
    "FADE": "I'd pass",
}


def decode_tape(row: dict[str, Any], integrity: dict[str, Any]) -> str:
    label = integrity["label"]
    if label == "BUNDLE":
        return (
            "Almost every wallet is a net buyer — sellers are hidden or bundled, "
            "not a crowd showing up."
        )
    if label == "WASH":
        return "Mid-size buys and sells print the same dollars; almost nobody trades twice. Wash."
    if label == "SUSPECT":
        return "The 'floor' is one-way inventory (huge absorp, no add-ons), not a ladder."

    addon = row.get("addon_rate")
    absorp = row.get("absorption_ratio")
    parts: list[str] = []
    if addon is not None and float(addon) > 0:
        parts.append("yesterday's buyers are still adding")
    if absorp is not None and ABSORP_LADDER_LO <= float(absorp) <= ABSORP_LADDER_HI:
        parts.append("small bids are eating real offers")
    if not parts:
        parts.append("flow is two-sided and not a farm print")
    return "The flow looks real: " + ", ".join(parts) + "."


def conviction_legs(row: dict[str, Any], integrity: dict[str, Any]) -> list[str]:
    legs: list[str] = []
    if integrity["label"] == "CLEAN":
        legs.append("integrity")

    addon = row.get("addon_rate")
    absorp = row.get("absorption_ratio")
    ladder = (
        addon is not None
        and float(addon) > 0
        and absorp is not None
        and ABSORP_LADDER_LO <= float(absorp) <= ABSORP_LADDER_HI
    )
    if integrity["label"] == "CLEAN" and (
        ladder or row.get("still_on_flash") is True
    ):
        legs.append("ladder")

    public = (row.get("public_label") or "").upper()
    if public in STORY_LEGS:
        legs.append("story")

    opponent = (row.get("opponent_class") or "").lower()
    if opponent and opponent != "retail_only_bid":
        legs.append("opponent")
    return legs


def slack_verdict(
    row: dict[str, Any],
    integrity: dict[str, Any],
    legs: list[str],
    ahead: dict[str, Any],
) -> str:
    public = (row.get("public_label") or "").upper()
    if integrity["verdict"] == "FADE" or integrity["label"] in {"BUNDLE", "WASH"}:
        return "FADE"
    n = len(legs)
    take_ok = (
        integrity["can_play"]
        and n >= 3
        and public in STORY_LEGS
        and row.get("mes_ok", True)
        and ahead["in_position"]
    )
    if take_ok:
        return "TAKE"
    if n >= 2 or public in {"CLIMAX", "WARNING", "PRODUCT", "EARLY"}:
        return "WATCH"
    return "FADE"


def card(row: dict[str, Any]) -> dict[str, Any]:
    integrity = classify_integrity(row)
    legs = conviction_legs(row, integrity)
    ahead = clock_and_seat(row, integrity["label"])
    n = len(legs)
    return {
        "symbol": row.get("symbol"),
        "chain": row.get("chain"),
        "address": row.get("address"),
        "integrity": integrity["label"],
        "tape": decode_tape(row, integrity),
        "thesis": row.get("thesis") or "",
        "public": row.get("public") or "",
        "public_label": (row.get("public_label") or "").upper(),
        "opponent": row.get("opponent") or "",
        "kill": row.get("kill") or "",
        "legs": legs,
        "conviction": f"{n}/4",
        "clock": ahead["clock"],
        "seat": ahead["seat"],
        "retail_next": ahead["retail_next"],
        "in_position": ahead["in_position"],
        "verdict": slack_verdict(row, integrity, legs, ahead),
        "can_play": integrity["can_play"],
        "stance": STANCE[slack_verdict(row, integrity, legs, ahead)],
    }


FORBIDDEN_IN_SLACK = (
    "T-2",
    "T-1",
    "T+1",
    "T+2",
    " T0",
    "OOP",
    "BLINDS",
    "MES ",
    "RX ",
    "FLASH_IGNITION",
    "HIGH CONVICTION",
    "n/4",
    "integrity BUNDLE",
    "integrity WASH",
    "integrity CLEAN",
)


def _exit_line(kill: str) -> str:
    text = (kill or "").strip()
    if not text:
        return "I'm out if the next session flips against the idea."
    lower = text.lower()
    if lower.startswith("already") or lower.startswith("i'm out") or lower.startswith("i would"):
        return text
    if lower.startswith("integrity"):
        return "I wouldn't put risk on this."
    if lower.startswith("any take"):
        return text
    return "I'm out if " + text[0].lower() + text[1:]


def rundown(row: dict[str, Any] | None = None, result: dict[str, Any] | None = None) -> str:
    """Human trader note. No clock codes, no score names."""
    result = result or card(row or {})
    chain = (result.get("chain") or "").upper()
    symbol = result.get("symbol") or "?"
    return (
        f"{chain} {symbol} — {result['stance']}\n\n"
        f"{result['thesis'].rstrip()}\n\n"
        f"{result['tape']} {result['public']}\n\n"
        f"{result['retail_next']} {result['opponent']}\n\n"
        f"{_exit_line(result.get('kill') or '')}\n\n"
        f"`{result.get('address') or ''}`\n"
    )


def slack_is_cryptic(text: str) -> list[str]:
    import re

    hits: list[str] = []
    for token in FORBIDDEN_IN_SLACK:
        if re.search(rf"(?<![A-Za-z0-9]){re.escape(token.strip())}(?![A-Za-z0-9])", text):
            hits.append(token.strip())
    return hits

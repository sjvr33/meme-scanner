"""Thesis / conviction helpers. Thresholds match core/scoring/THESIS.md."""

from __future__ import annotations

from typing import Any

from core.scoring.integrity import classify as classify_integrity

ABSORP_LADDER_LO = 1.2
ABSORP_LADDER_HI = 8.0
STORY_LEGS = frozenset({"EARLY", "PRODUCT"})


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
    return "Organic tape: " + ", ".join(parts) + "."


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


def slack_verdict(row: dict[str, Any], integrity: dict[str, Any], legs: list[str]) -> str:
    public = (row.get("public_label") or "").upper()
    if integrity["verdict"] == "FADE" or integrity["label"] in {"BUNDLE", "WASH"}:
        return "FADE"
    n = len(legs)
    take_ok = (
        integrity["can_play"]
        and n >= 3
        and public in STORY_LEGS
        and row.get("mes_ok", True)
    )
    if take_ok:
        return "TAKE"
    if n >= 2 or public in {"CLIMAX", "WARNING", "PRODUCT", "EARLY"}:
        return "WATCH"
    return "FADE"


def card(row: dict[str, Any]) -> dict[str, Any]:
    integrity = classify_integrity(row)
    legs = conviction_legs(row, integrity)
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
        "verdict": slack_verdict(row, integrity, legs),
        "can_play": integrity["can_play"],
    }

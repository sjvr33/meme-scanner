"""Information clock + seat. Thresholds match core/scoring/AHEAD.md."""

from __future__ import annotations

from typing import Any

RETAIL_NEXT = {
    "T-2": "Retail has not seen this ticker yet. If it prints green on DexScreener they will chase — we want that bid later, not as tonight's exit.",
    "T-1": "Smart wallets are already here. Retail follows the leftovers in 12–24h.",
    "T0": "Retail will ape the first FLASH candle this session. Wait for the second show or fold.",
    "T+1": "Retail is the bid right now. Someone is exiting into them.",
    "T+2": "Retail thinks the listing or headline is the start. It is the end.",
}

IN_POSITION = frozenset({"T-2", "T-1"})


def clock_and_seat(row: dict[str, Any], integrity_label: str) -> dict[str, Any]:
    public = (row.get("public_label") or "").upper()
    flash = row.get("flash_band") or ""
    age = row.get("age_days")
    still = row.get("still_on_flash")
    age_n = float(age) if age is not None and age != "" else None
    first_flash = (
        age_n is not None
        and age_n <= 1
        and "FLASH_IGNITION" in flash
        and still is not True
    )
    flash_died = still is False and "FLASH" in flash

    if integrity_label in {"BUNDLE", "WASH"}:
        if public == "CLIMAX":
            clock = "T+2"
        elif flash_died or not first_flash:
            clock = "T+1"
        else:
            clock = "T0"
        seat = "OOP"
    elif public == "CLIMAX":
        clock, seat = "T+2", "OOP"
    elif public == "WARNING":
        clock, seat = "T+1", "OOP"
    elif first_flash:
        clock, seat = "T0", "BLINDS"
    elif public == "SILENCE" and integrity_label == "CLEAN":
        clock, seat = "T-2", "IN"
    elif still is True or public in {"EARLY", "PRODUCT"} or row.get("cohort_hot"):
        clock, seat = "T-1", "IN"
    elif integrity_label == "CLEAN":
        clock, seat = "T-2", "IN"
    else:
        clock, seat = "T0", "BLINDS"

    return {
        "clock": clock,
        "seat": seat,
        "in_position": clock in IN_POSITION and seat == "IN",
        "retail_next": row.get("retail_next") or RETAIL_NEXT[clock],
    }

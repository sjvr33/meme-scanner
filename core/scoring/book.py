"""The book — names we hold. Not a watchlist of flips."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]


def _norm(value: str | None) -> str:
    return (value or "").strip().lower()


def load_book(chain: str = "robinhood") -> list[dict[str, Any]]:
    path = ROOT / "chains" / chain / "config" / "book.json"
    if not path.exists():
        return []
    return list((json.loads(path.read_text()) or {}).get("holds") or [])


def book_entry(row: dict[str, Any]) -> dict[str, Any] | None:
    symbol = (row.get("symbol") or "").upper()
    address = _norm(str(row.get("address") or row.get("token_address") or row.get("mint") or ""))
    chain = (row.get("chain") or "robinhood").lower()
    for item in load_book(chain):
        if symbol and symbol == (item.get("symbol") or "").upper():
            return item
        if address and address == _norm(item.get("address") or item.get("contract")):
            return item
    return None


def is_hold(row: dict[str, Any]) -> bool:
    if (row.get("horizon") or "").lower() == "hold":
        return True
    if (row.get("public_label") or "").upper() == "FLAGSHIP":
        return True
    return book_entry(row) is not None

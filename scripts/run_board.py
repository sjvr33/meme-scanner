#!/usr/bin/env python3
"""Live board: Dune quality rows + DexScreener → human rundowns.

  python3 scripts/run_board.py core/scoring/fixtures/live_flow.json
"""

from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from core.scoring.thesis import card, rundown, slack_is_cryptic  # noqa: E402

SKIP_SYMBOLS = frozenset(
    {"USDE", "USDC", "USDT", "WETH", "ETH", "USDG", "WBTC", "WSOL", "SOL", "DAI", "USD1", "CBBTC"}
)
OVERRIDES = ROOT / "core/scoring/fixtures/public_overrides.json"


def _num(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def dexscreener(address: str) -> dict:
    url = f"https://api.dexscreener.com/latest/dex/tokens/{address}"
    req = urllib.request.Request(url, headers={"User-Agent": "meme-scanner/2.6"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        payload = json.loads(resp.read().decode())
    pairs = payload.get("pairs") or []
    if not pairs:
        return {"websites": [], "socials": [], "liquidity_usd": 0, "market_cap": 0, "change_24h": None, "url": url}
    pairs = sorted(pairs, key=lambda p: float((p.get("liquidity") or {}).get("usd") or 0), reverse=True)
    top = pairs[0]
    info = top.get("info") or {}
    return {
        "name": (top.get("baseToken") or {}).get("name"),
        "symbol": (top.get("baseToken") or {}).get("symbol"),
        "websites": [w.get("url") for w in (info.get("websites") or []) if w.get("url")],
        "socials": [s.get("url") for s in (info.get("socials") or []) if s.get("url")],
        "liquidity_usd": float((top.get("liquidity") or {}).get("usd") or 0),
        "market_cap": float(top.get("marketCap") or 0),
        "change_24h": (top.get("priceChange") or {}).get("h24"),
        "url": top.get("url") or url,
    }


def dex_facts(dex: dict) -> str:
    bits: list[str] = []
    if dex.get("market_cap"):
        bits.append(f"MC ~${dex['market_cap']:,.0f}")
    if dex.get("liquidity_usd") is not None:
        bits.append(f"LP ~${dex['liquidity_usd']:,.0f}")
    chg = dex.get("change_24h")
    if chg is not None:
        bits.append(f"24h {float(chg):+.1f}%")
    sites = dex.get("websites") or []
    socials = dex.get("socials") or []
    bits.extend(sites[:1])
    bits.extend(socials[:1])
    if dex.get("url"):
        bits.append(str(dex["url"]))
    return " · ".join(bits)


def infer_public(dex: dict, override: dict | None) -> tuple[str, str]:
    facts = dex_facts(dex)
    if override and override.get("public_label"):
        note = (override.get("public") or "").strip()
        if facts:
            note = f"{note} {facts}".strip() if note else facts
        return override["public_label"], note
    sites = dex.get("websites") or []
    socials = dex.get("socials") or []
    chg = dex.get("change_24h")
    if not sites and not socials:
        label = "SILENCE"
        note = f"No website or socials on DexScreener. {facts}".strip()
    else:
        label = "PRODUCT"
        note = facts
    if chg is not None and float(chg) <= -80:
        note += f" Pair is {chg}% on the day."
    return label, note


def row_from_flow(raw: dict, dex: dict, override: dict | None, reflex: dict | None) -> dict:
    symbol = raw.get("symbol") or dex.get("symbol") or "?"
    address = raw.get("token_address") or raw.get("mint") or raw.get("address")
    public_label, public = infer_public(dex, override)
    rx = reflex or {}
    thesis = (override or {}).get("thesis")
    if not thesis:
        if public_label == "SILENCE":
            thesis = f"{symbol} has no public page for this contract. Treat the tape as the only story."
        elif public_label == "WARNING":
            thesis = f"{symbol} has a public concentration or scam warning. Flow can look fine while the float is not."
        elif public_label == "CLIMAX":
            thesis = f"{symbol} already had the headline. The crowd thinks that is the start."
        else:
            thesis = f"{symbol} has a public page. Check whether the tape is a ladder or a farm."
    return {
        "symbol": symbol,
        "chain": raw.get("chain") or "robinhood",
        "address": address,
        "repeat_buyer_pct": _num(raw.get("repeat_buyer_pct")),
        "net_buy_wallet_pct": _num(raw.get("net_buy_wallet_pct")),
        "mid_buy_usd": _num(raw.get("mid_buy_usd")),
        "mid_sell_usd": _num(raw.get("mid_sell_usd")),
        "absorption_ratio": _num(rx.get("absorption_ratio") or raw.get("absorption_ratio")),
        "addon_rate": _num(rx.get("addon_rate") or raw.get("addon_rate")),
        "first_time_buyers": _num(rx.get("first_time_buyers") or raw.get("first_time_buyers")),
        "age_days": _num((override or {}).get("age_days") or raw.get("age_days")),
        "flash_band": raw.get("flash_band") or (override or {}).get("flash_band") or "",
        "still_on_flash": raw["still_on_flash"]
        if "still_on_flash" in raw
        else (override or {}).get("still_on_flash"),
        "latest_net": _num(raw.get("latest_net")),
        "session_net": _num(raw.get("net_usd_48h") or raw.get("session_net") or raw.get("net_12h")),
        "public_label": public_label,
        "public": public,
        "thesis": thesis,
        "opponent": (override or {}).get("opponent")
        or ("Retail is the only bid." if public_label in {"SILENCE", "CLIMAX", "WARNING"} else "Two-sided book — not obviously a farm."),
        "opponent_class": (override or {}).get("opponent_class")
        or ("retail_only_bid" if public_label in {"SILENCE", "CLIMAX"} else "mixed"),
        "kill": (override or {}).get("kill") or "the next session flips against the idea.",
        "mes_ok": (override or {}).get("mes_ok", False),
    }


def _index(rows: list[dict]) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for row in rows:
        symbol = (row.get("symbol") or "").upper()
        addr = str(row.get("token_address") or row.get("mint") or "").lower()
        if symbol:
            out[symbol] = row
        if addr:
            out[addr] = row
    return out


def _still_on_flash(flash: dict) -> bool:
    latest = (flash.get("latest_label") or "").upper()
    return latest in {"FLASH_HOT", "FLASH_WARM"}


def merge_live(raw: dict, reflex_idx: dict[str, dict], flash_idx: dict[str, dict]) -> dict:
    symbol = (raw.get("symbol") or "").upper()
    addr = str(raw.get("token_address") or raw.get("mint") or "").lower()
    rx = reflex_idx.get(symbol) or reflex_idx.get(addr) or {}
    fl = flash_idx.get(symbol) or flash_idx.get(addr) or {}
    merged = dict(raw)
    for key in ("absorption_ratio", "addon_rate", "first_time_buyers"):
        if rx.get(key) is not None:
            merged[key] = rx[key]
    if fl:
        if fl.get("flash_band"):
            merged["flash_band"] = fl["flash_band"]
        if fl.get("latest_net") is not None:
            merged["latest_net"] = fl["latest_net"]
        if fl.get("net_12h") is not None:
            merged["net_12h"] = fl["net_12h"]
        merged["still_on_flash"] = _still_on_flash(fl)
    return merged


def load_flow(path: Path) -> list[dict]:
    payload = json.loads(path.read_text())
    rows = payload.get("tokens") or payload.get("rows") or payload
    if isinstance(rows, dict) and "data" in rows:
        rows = (rows["data"] or {}).get("rows") or []
    reflex_idx = _index(payload.get("reflex") or [])
    flash_idx = _index(payload.get("flash") or [])
    out = []
    for raw in rows:
        if raw.get("section") and raw.get("section") != "quality":
            continue
        symbol = (raw.get("symbol") or "").upper()
        if symbol in SKIP_SYMBOLS:
            continue
        out.append(merge_live(raw, reflex_idx, flash_idx))
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: python3 scripts/run_board.py <flow.json>", file=sys.stderr)
        return 2
    flow_path = Path(sys.argv[1])
    overrides = {}
    if OVERRIDES.exists():
        blob = json.loads(OVERRIDES.read_text())
        overrides = {k.upper(): v for k, v in blob.items()}

    print("Live board — Dune quality + DexScreener. Research only.")
    print()
    failures = 0
    for raw in load_flow(flow_path):
        address = raw.get("token_address") or raw.get("mint") or raw.get("address")
        symbol = (raw.get("symbol") or "?").upper()
        try:
            dex = dexscreener(str(address))
        except Exception as exc:
            print(f"{symbol}: DexScreener failed ({exc})")
            print()
            failures += 1
            continue
        override = overrides.get(symbol) or overrides.get(str(address).lower())
        row = row_from_flow(raw, dex, override, None)
        result = card(row)
        text = rundown(result=result)
        cryptic = slack_is_cryptic(text)
        print(text)
        print("---")
        print()
        if cryptic:
            print(f"FAIL cryptic: {cryptic}", file=sys.stderr)
            failures += 1
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

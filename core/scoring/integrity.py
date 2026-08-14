"""Bundle / wash integrity classifier. Thresholds match core/scoring/INTEGRITY.md."""

from __future__ import annotations

from typing import Any

BUNDLE_NET_BUY_WALLET_PCT = 95.0
SUSPECT_NET_BUY_WALLET_PCT = 90.0
SUSPECT_REPEAT_PCT = 70.0
WASH_REPEAT_PCT = 2.0
WASH_MID_IMBALANCE_PCT = 5.0
WASH_MID_VOL_USD = 1_000_000.0
SUSPECT_ABSORP = 20.0
SUSPECT_FTB = 1500
MES_CAP_FAIL = 45
ORGANIC_NET_BUY_FLOOR = 40.0

HARD_FADE = frozenset({"WASH", "BUNDLE"})


def mid_imbalance_pct(mid_buy_usd: float | None, mid_sell_usd: float | None) -> float | None:
    buy = float(mid_buy_usd or 0)
    sell = float(mid_sell_usd or 0)
    peak = max(buy, sell)
    if peak <= 0:
        return None
    return 100.0 * abs(buy - sell) / peak


def classify(row: dict[str, Any]) -> dict[str, Any]:
    """Label a Q-FLOW (+ optional RX/FLASH) row.

    Expected keys (missing = None):
      repeat_buyer_pct, net_buy_wallet_pct, mid_buy_usd, mid_sell_usd,
      absorption_ratio, addon_rate, first_time_buyers, age_days,
      flash_band, latest_net, session_net, still_on_flash
    """
    repeat = _num(row.get("repeat_buyer_pct"))
    net_buy = _num(row.get("net_buy_wallet_pct"))
    mid_buy = _num(row.get("mid_buy_usd"))
    mid_sell = _num(row.get("mid_sell_usd"))
    absorp = _num(row.get("absorption_ratio"))
    addon = _num(row.get("addon_rate"))
    ftb = _num(row.get("first_time_buyers"))
    age = _num(row.get("age_days"))
    flash = (row.get("flash_band") or "") or ""
    latest_net = _num(row.get("latest_net"))
    session_net = _num(row.get("session_net"))
    still_on_flash = row.get("still_on_flash")

    imb = mid_imbalance_pct(mid_buy, mid_sell)
    mid_vol = (mid_buy or 0) + (mid_sell or 0)
    reasons: list[str] = []

    wash = (
        repeat is not None
        and repeat < WASH_REPEAT_PCT
        and imb is not None
        and imb < WASH_MID_IMBALANCE_PCT
        and mid_vol >= WASH_MID_VOL_USD
    )
    bundle = net_buy is not None and net_buy >= BUNDLE_NET_BUY_WALLET_PCT
    suspect_flow = (
        net_buy is not None
        and repeat is not None
        and net_buy >= SUSPECT_NET_BUY_WALLET_PCT
        and repeat >= SUSPECT_REPEAT_PCT
    )
    suspect_rx = (
        absorp is not None
        and absorp >= SUSPECT_ABSORP
        and (addon is None or addon <= 0)
        and ftb is not None
        and ftb >= SUSPECT_FTB
    )

    if wash:
        label = "WASH"
        reasons.append(
            f"repeat {repeat:.2f}% + mid imbalance {imb:.2f}% on ${mid_vol:,.0f} mid vol"
        )
    elif bundle:
        label = "BUNDLE"
        reasons.append(f"net-buy wallets {net_buy:.2f}% ≥ {BUNDLE_NET_BUY_WALLET_PCT:g}%")
        if suspect_rx:
            reasons.append(f"absorp {absorp:.1f} with addon {addon or 0:g} (one-way inventory)")
    elif suspect_flow or suspect_rx:
        label = "SUSPECT"
        if suspect_flow:
            reasons.append(f"net-buy {net_buy:.2f}% + repeat {repeat:.2f}%")
        if suspect_rx:
            reasons.append(f"absorp {absorp:.1f} addon {addon or 0:g} FTB {ftb:g}")
    else:
        label = "CLEAN"
        reasons.append("inside organic band")

    same_day = age is not None and age <= 1
    first_session_flash = (
        same_day
        and "FLASH_IGNITION" in flash
        and still_on_flash is not True
    )
    # Q-FLASH can stamp FLASH_IGNITION on a crowded board. A COLD last hour
    # is only a dump tell on a same-day print — not on a week-old product.
    flash_died = same_day and still_on_flash is False and "FLASH" in flash
    price_up_net_red = same_day and session_net is not None and session_net < 0

    hard_fade = label in HARD_FADE or (
        label == "SUSPECT" and (age is None or age <= 2 or "FLASH" in flash)
    )
    if first_session_flash:
        reasons.append("age ≤1d FLASH_IGNITION needs a second session")
    if flash_died or price_up_net_red:
        hard_fade = True
        reasons.append("same-day FLASH faded or session net flipped red")

    can_play = label == "CLEAN" and not first_session_flash and not hard_fade
    can_flash_hc = can_play and (age is None or age > 1 or still_on_flash is True)
    mes_cap = MES_CAP_FAIL if label in HARD_FADE else (55 if label == "SUSPECT" else 100)

    award_repeat = (
        repeat is not None
        and 25 < repeat < SUSPECT_REPEAT_PCT
        and label == "CLEAN"
        and not (age is not None and age <= 2 and repeat >= SUSPECT_REPEAT_PCT)
    )
    award_net_buy = (
        net_buy is not None
        and ORGANIC_NET_BUY_FLOOR < net_buy < SUSPECT_NET_BUY_WALLET_PCT
        and label == "CLEAN"
    )

    return {
        "label": label,
        "reasons": reasons,
        "mid_imbalance_pct": None if imb is None else round(imb, 4),
        "mes_cap": mes_cap,
        "can_play": can_play,
        "can_flash_hc": can_flash_hc,
        "second_session_required": bool(first_session_flash),
        "award_repeat_points": award_repeat,
        "award_net_buy_wallet_points": award_net_buy,
        "verdict": "FADE" if hard_fade or label in HARD_FADE else ("WATCH" if not can_play else "GATE"),
    }


def _num(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None

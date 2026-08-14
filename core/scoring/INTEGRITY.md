# INTEGRITY — Bundle / wash veto

Research framework. Not financial advice.

MES and RX have **floors** (repeat > 25%, net-buy wallets > 40%, absorp ≥ 1.2). They had **no ceilings**. That is how HOOPLA printed MES 85 / RX 65 / FLASH_IGNITION on a same-day bundle dump.

This layer is a **hard veto**. It runs after Q-FLOW (+ Q-REFLEX fields when present) and **before** PLAY / HIGH CONVICTION. Narrative cannot override it.

## What the tape showed (Aug 14 2026, live Q-FLOW `01M00PRAJXF2VY10PCW073YVD8` + Q-REFLEX `01M00PRAK27TZSHJ1CG3T9P3BT`)

| Token | Repeat % | Net-buy wallet % | Mid $1k–10k buy / sell | Absorp | Addon | Verdict |
|-------|----------|------------------|------------------------|--------|-------|---------|
| **HOOPLA** | **80.95** | **99.45** | $0.39M / **$3.49M** | **121.6** | **0** | Bundle dump |
| **COBRA** | 60.08 | **99.85** | $1.87M / $1.52M | 2.59 | **0** | Farm pack |
| **DOGO** | **0.49** | 50.06 | $8.70M / $8.70M | 0.009 | — | Wash |
| **MOW** | **0.89** | 49.85 | $5.25M / $5.24M | — | — | Wash |
| CASHCAT | 35.52 | 84.55 | $4.94M / $6.17M | 2.90 | 20% | Organic (distributing) |
| STONKBROKER | 46.22 | 81.29 | $5.83M / $5.31M | 2.48 | 21% | Organic bid |
| XST (SOL) | 50.8 | 63.3 | — | — | — | Organic reload |

Organic band to **keep scoring**: repeat **25–50%** (reload), net-buy wallets **40–85%**, addon **> 0**, absorp **~1.2–8**.

## Labels (priority: WASH → BUNDLE → SUSPECT → CLEAN)

| Label | Rule | Slack |
|-------|------|-------|
| **WASH** | `repeat_buyer_pct < 2` **and** mid-bucket imbalance `< 5%` **and** mid vol ≥ $1M | **FADE** — never PLAY |
| **BUNDLE** | `net_buy_wallet_pct ≥ 95` | **FADE** — never PLAY |
| **SUSPECT** | (`net_buy_wallet_pct ≥ 90` **and** `repeat_buyer_pct ≥ 70`) **or** (`absorption_ratio ≥ 20` **and** `addon_rate = 0` **and** first-time buyers ≥ 1500) | **FADE** if age ≤ 2d; else max WATCH — never PLAY / HC |
| **CLEAN** | else | Normal MES × RX × FLASH gates |

Mid imbalance = `|mid_buy − mid_sell| / max(mid_buy, mid_sell) × 100`. DOGO/MOW print ~0%. HOOPLA mid is **not** symmetric (dump, not wash) — caught by BUNDLE + absorp/addon.

## MES ceilings (do not award the +15s)

| Signal | Floor (existing) | Ceiling (new) |
|--------|------------------|---------------|
| Repeat buyers | > 25% → +15 | Do **not** award if `repeat_buyer_pct ≥ 70` on NEW (age ≤ 2d) or label ≠ CLEAN |
| Net-buy wallets | > 40% → +15 | Do **not** award if `net_buy_wallet_pct ≥ 90` |
| Absorption (RX) | ≥ 1.2 → points | Do **not** treat absorp ≥ 20 with addon = 0 as a ladder — that is one-way inventory, not a floor |

If label is **BUNDLE** or **WASH**: **MES cap 45**. Cannot reach HIGH CONVICTION by any path.

## FLASH second-session (age ≤ 1d)

Same-day FLASH_IGNITION is how HOOPLA got a morning WATCH that died by evening (price up, day net red, off the FLASH board).

| Rule | Action |
|------|--------|
| Age ≤ 1d **and** FLASH_IGNITION **and** first session today | **WATCH only** if CLEAN; **never TAKE / flash HC** |
| Still FLASH_IGNITION **and** still net-green 6–12h later (second session) | Flash path may upgrade |
| Morning FLASH_IGNITION, evening off-board **or** day net flipped red while price up | **FADE** — climax / dump |

## Hard veto (any path)

These **cannot** be PLAY, TAKE, or HIGH CONVICTION:

1. integrity_label ∈ {WASH, BUNDLE}
2. integrity_label = SUSPECT **and** (age ≤ 2d **or** FLASH path)
3. Age ≤ 1d FLASH_IGNITION without a second session
4. FLASH_IGNITION morning + gone by evening, or price up + session net red

## Queries / code

- Flags on Q-FLOW quality rows: `chains/robinhood/dune/q-flow.sql` (**8269897**), `chains/solana/dune/q-flow.sql` (**8271228**)
- Classifier: `core/scoring/integrity.py`
- Replay: `python3 scripts/replay_integrity.py`

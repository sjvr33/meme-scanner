# Reflex Score (RX) — Microstructure Alpha Layer

Research framework. Not financial advice.

## Purpose

MES answers: *is attention/demand rising?*  
**RX answers: is a reflexive buyer ladder forming before a parabolic?**

Validated on CASHCAT Aug 1–8 2026 (see `docs/BACKTESTS.md`).

## The five signals

| # | Signal | Definition | Why it predicts parabolic |
|---|--------|------------|---------------------------|
| 1 | **Absorption ratio** | retail_buy_usd (<$1k) / whale_sell_usd (≥$10k) | Many small buys eating large sells = floor |
| 2 | **First-time buyers** | Wallets whose first trade on token is today | Network expansion / FOMO ladder |
| 3 | **Add-on rate** | Share of today's buyers who also bought yesterday and remain net long | Sticky demand, not one-shot bots |
| 4 | **Buy burst share** | Max consecutive 2h buy USD / day buy USD | Ignition — concentrated buy pressure |
| 5 | **Net flow** | buy − sell (soft gate) | Without net demand, vol spike = distribution |

## Scoring (0–100)

| Signal | Points | Thresholds |
|--------|--------|------------|
| Absorption | +25 / +15 | ≥1.2 / ≥0.8 |
| First-time buyers | +20 / +12 | ≥1500 / ≥800 (RH); SOL uses ≥3000 / ≥1500 |
| Add-on rate | +20 / +10 | ≥15% / ≥8% |
| Buy burst | +15 / +8 | ≥35% / ≥25% of day buys in best 2h |
| Net positive | +20 / +8 | net > 0 / net > −$500k |

## Alert bands

| RX | Label | Action |
|----|-------|--------|
| ≥ 80 | **IGNITION** | Highest priority — reflexive ladder forming |
| 65–79 | **WARMING** | Watch closely; often 1–2 days before IGNITION |
| 50–64 | **MIXED** | Noise or digest — do not chase |
| < 50 | **COLD / DISTRIBUTION** | Skip even if volume is huge |

## Hard rule (anti-TOAD)

**Volume without RX ≥ 65 is not a setup.**  
TOAD-style dumps can print $40M vol with weak absorption + negative net → RX stays subdued or fails the net gate.

**Absorption without addon is not a floor.** Absorp ≥ 20 with addon = 0 and a huge first-time-buyer print (HOOPLA 121.6 / 0% / 2800) is one-way inventory, not a ladder. INTEGRITY marks that SUSPECT / BUNDLE — do not treat it as RX alpha.

## How RX combines with MES

```
Final conviction = MES (macro) × RX gate

- MES ≥ 60 AND RX ≥ 80 → HIGH CONVICTION (IGNITION)
- MES ≥ 60 AND RX 65–79 → WATCHLIST (WARMING)
- MES ≥ 75 AND RX < 65 → DOWNRANK to MIXED (likely distribution into hype)
- RX ≥ 80 alone → still require MES ≥ 50 (attention must be real)
```

## CASHCAT fingerprint (ground truth)

| Day | RX | Outcome next |
|-----|-----|--------------|
| Aug 1 | 33 | Dead |
| Aug 2 | 65 | Warming starts |
| Aug 3 | **82** | Reload day 1 |
| Aug 4 | **83** | Reload day 2 |
| Aug 5 | **100** | Peak pre-listing |
| Aug 6 | 70 | Listing climax / distribution (−$1.18M net) |
| Aug 7 | 65 | Digest |
| Aug 8 | 77 | Second leg green |

**Edge:** RX ≥ 80 on Aug 3–5 — *before* the Aug 6 blowup. Aggregate volume alone would have been loudest on Aug 6 (the dump).

## Query

- RH: `chains/robinhood/dune/q-reflex.sql` → Q-REFLEX
- SOL: `chains/solana/dune/q-reflex.sql` → Q-REFLEX

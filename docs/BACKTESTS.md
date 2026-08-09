# Reflex Score Backtests

Empirical validation of Q-REFLEX. Research only — not financial advice.

## Ground truth: CASHCAT Aug 1–8 2026 (RH)

Contract: `0x020bfC650A365f8BB26819deAAbF3E21291018b4`

| Day | Vol | Net | Absorp | 1st buyers | Addon | Burst | **RX** | Label | What happened next |
|-----|-----|-----|--------|------------|-------|-------|--------|-------|-------------------|
| Aug 1 | $2.7M | −$104k | 4.64 | 654 | 0% | 16% | **33** | COLD | Dead tape |
| Aug 2 | $2.8M | +$410k | 24.7 | 590 | 18% | 16% | **65** | WARMING | Reload starts |
| Aug 3 | $13.4M | +$1.14M | 2.76 | 1140 | 11% | **50%** | **82** | **IGNITION** | Day 1 reload |
| Aug 4 | $15.9M | +$882k | 3.10 | 1693 | 14% | 33% | **83** | **IGNITION** | Day 2 reload |
| Aug 5 | $37.6M | +$1.19M | 1.86 | 2126 | 18% | 35% | **100** | **IGNITION** | Peak pre-listing |
| Aug 6 | $107M | −$1.18M | 1.52 | 5590 | 12% | 43% | **70** | WARMING | Listing climax / dump |
| Aug 7 | $18.5M | −$362k | 3.04 | 1095 | 39% | 16% | **65** | WARMING | Digest |
| Aug 8 | $16.6M | +$1.47M | 2.95 | 1035 | 22% | 22% | **77** | WARMING | Second leg green |

### Edge claim

- **RX ≥ 80 on Aug 3–5** — before Aug 6 blowup
- **Aug 6 loudest volume** scored only 70 (net gate + weaker relative absorption)
- Pure volume scanners would have been loudest on the dump day
- Query: temp backtest `8271334`

## Negative control: Solana dumps (Aug 8)

| Token | Vol | Net | RX | Label |
|-------|-----|-----|-----|-------|
| TOAD | $37.7M | −$13.4M | **60** | MIXED |
| Jimothy | $14.3M | −$4.8M | **63** | MIXED |

Huge volume + many first-time buyers, but **negative net** and weak sticky addon → RX refuses IGNITION.

## Live production scan (yesterday = Aug 8)

### Robinhood Q-REFLEX `8271348`

| Symbol | RX | Label | Note |
|--------|-----|-------|------|
| SPCX | 80 | IGNITION | Strong absorption + burst + net |
| CASHCAT | 77 | WARMING | Matches Aug 8 second-leg table |
| STONKBROKER | 65 | WARMING | Constructive |

### Solana Q-REFLEX `8271349`

| Symbol | RX | Label | Note |
|--------|-----|-------|------|
| CASH | 73 | WARMING | High first-timers + addon; slight net red |
| CATE | 65 | WARMING | High vol but −$3.3M net — not IGNITION |
| Jimothy | 63 | MIXED | Confirms dump control |

## Interpretation rule used in automation

```
HIGH CONVICTION only if MES ≥ 60 AND RX ≥ 80
WATCHLIST if MES ≥ 60 AND RX 65–79
DOWNRANK if MES high but RX < 65  → treat as distribution risk
```

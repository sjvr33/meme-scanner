# Meme Early Score (MES)

Research framework for the daily scanner. Not financial advice.

**Pair with Reflex Score (RX)** — see `core/scoring/REFLEX.md`.  
MES = macro attention/demand. RX = microstructure ladder before parabolic.

## Two modes

| Mode | Age | Pattern |
|------|-----|---------|
| **NEW** | < chain threshold | Early deploy, first LP, holder velocity |
| **REACTIVATION** | ≥ 14d RH / ≥ 7d SOL | CASHCAT Aug 3–5 template — old coin reloading |

## REACTIVATION scoring (0–100)

| Signal | Points | Rule |
|--------|--------|------|
| Vol acceleration | +15 | `vol_yesterday / vol_7d_avg_prior ≥ 3` |
| Net-buy streak | +15 | 2+ consecutive net-buy days |
| New holder slope | +15 | 3-day new receivers rising |
| Chain share | +15 | Top-5 share OR share rising 2 days |
| Repeat buyers | +15 | `repeat_buyer_pct > 25%` (from Q-FLOW) |
| Net-buy wallets | +15 | `net_buy_wallet_pct > 40%` (from Q-FLOW) |
| Compression → spike | +10 | Prior 5d low vol then 3×+ spike |

## NEW scoring (0–100)

| Signal | Points | Rule |
|--------|--------|------|
| Age window | +10 | 6h–14d (sweet spot) |
| 24h volume | +15 | > $100k |
| Unique traders | +15 | > 200 / 24h |
| New holders/day | +15 | Accelerating vs prior 2 days |
| Net flow | +15 | Net positive 24h |
| Dispersion proxy | +15 | Not dominated by top-1 wallet in flow |
| LP exists | +15 | Has DEX trades (implicit) |

## Verdict thresholds (MES × RX gate)

| MES | RX | Final label | Action |
|-----|-----|-------------|--------|
| ≥ 60 | ≥ 80 | **HIGH CONVICTION (IGNITION)** | Top section |
| ≥ 60 | 65–79 | **WATCHLIST (WARMING)** | Monitor |
| ≥ 75 | < 65 | **MIXED / DISTRIBUTION RISK** | Downrank — do not chase vol |
| < 60 | any | SKIP (unless watched) | Omit |

Never alert IGNITION on volume alone. RX is the alpha gate.

## Watchlist verdicts (Q-WATCH)

| Verdict | Criteria |
|---------|----------|
| ACCUMULATE | Net-green 48h + vol holding + retail absorbing |
| HOLD | Mixed flow, thesis intact |
| TRIM | Large net sell day + whale distribution |
| ABORT | Kill switch: 3-day net sell + vol collapse |

## Kill signals (any watched token)

- Daily net sell > $500k with rising sell volume
- 24h close below prior compression floor by >15%
- Holder growth stalls 3 days while price rises (distribution)

## CASHCAT reference pattern (Aug 3–5)

Validated reactivation before Aug 6 listing blowup:

- Vol 4.7× vs prior week
- 3-day net buy streak
- New holders 2.6k → 7k
- Chain share 1% → 7.5%

Scanner must score **REACTIVATION** mode, not only new deploys.

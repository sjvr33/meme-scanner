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

---

## Expanded sample — other runners (Jul–Aug 2026)

Queries: RH multi `8271384` · SOL multi `8271387`  
Window: 5 days before peak → 1 day after. Peak = max daily vol day.

### Robinhood — would RX have caught it?

| Token | Peak day | Peak vol | Best RX **before** peak | Verdict |
|-------|----------|----------|-------------------------|---------|
| **FRONG** | Aug 5 | $24M | **81 IGNITION** on Jul 31 (−5d), **92** on Aug 4 (−1d) | ✅ **Caught early** |
| **CASHCAT** | Aug 6 | $107M | **100 IGNITION** on Aug 5 (−1d); WARMING Aug 2–4 | ✅ **Caught** (best signal day-before) |
| **VLAD** | Jul 23 | $28M | No pre-history in window; **80** on peak day | ⚠️ Flash — only same-day |
| **VIRTUAL** | Jul 17 | $38M | Max **73 WARMING** (−3d); never IGNITION | 🟡 Watchlist only (sticky, no FOMO ladder) |
| **GME** | Jul 23 | $31M | Max **60 MIXED** day-before; IGNITION day-after | ❌ Missed pre-peak (sudden Jul 22 launch) |
| **PIPEDOG** | Jul 29 | $59M | Max **68 WARMING** on peak; absorption 0.16–0.43 | ❌ No IGNITION — whales dominating buys |

**RH catch rate (IGNITION before peak):** 2/6 strong early (FRONG, CASHCAT).  
**Useful non-catch:** PIPEDOG — RX refused IGNITION because absorption was broken (whale-led). That’s *correct* microstructure skepticism.

### Solana — mostly distribution into volume

| Token | Peak day | Peak vol | Best RX before/on peak | Verdict |
|-------|----------|----------|------------------------|---------|
| **CATE** | Aug 3 | $79M | 63 MIXED → 70 WARMING on peak; net −$24M peak day | ✅ Correctly refused IGNITION |
| **ANSEM** | Jul 10 | $59M | Stuck 35–65; continuous net sell | ✅ Refused |
| **Jimothy** | Jul 23 | $39M | 55 MIXED → 65 WARMING; net −$9M peak | ✅ Refused |
| **Doom** | Aug 4 | $15M | 60 MIXED → 45 COLD on peak | ✅ Refused |
| **HOUSEM** | Jul 17 | $14M | 36 COLD flash | ✅ Refused |
| **bulltom** | Jul 28 | $17M | 28–35 COLD | ✅ Refused |

**SOL insight:** Last month’s loud Solana “runs” in this sample were **volume with persistent net selling**. RX’s job is to *not* alert those. Edge here is **false-positive rejection**, not early catch of SOL blowups.

### What this means for the scanner

1. **Best fit:** RH multi-day reloads with retail absorbing (FRONG, CASHCAT) — RX lights **1–5 days early**.
2. **Hard miss for daily RX:** Same-day flash launches (GME, VLAD) — fixed by **Q-FLASH** (below).
3. **Correct skip:** Whale-dominated pumps (PIPEDOG) and Solana distribution spikes — RX stays MIXED/COLD.
4. **Operational rule:** Treat IGNITION as rare. Prefer 1–3 true setups over chasing every vol spike.

---

## Alternative lenses (v2.2) — looking at the chain differently

We were over-indexing on **daily DEX aggregates**. These lenses use time resolution and wallet graph instead.

### Q-FLASH — hourly (fixes GME miss)

| Token | Daily RX | Hourly FLASH | Verdict |
|-------|----------|--------------|---------|
| **GME** | Missed pre-peak (max 60 day-before) | **FLASH_HOT Jul 22 21:00** ($2.77M, absorp 13.8, 175 buyers) — day before peak | ✅ Flash path catches it |
| **VLAD** | Only peak-day RX 80 | FLASH_HOT Jul 23 17:00 (peak day) | ⚠️ Same-day only, but intraday usable |
| **CASHCAT / FRONG** | Already caught by daily RX | Many FLASH_HOT hours during reload | Confirms; RX remains primary for reloads |

Queries: backtest `8271448` / `8271460` · production RH **8271470** · SOL **8271473**

### Q-COHORT — winner wallets (FRONG → CASHCAT forward)

Cohort = net-long FRONG Jul 30–31. Measured on CASHCAT Aug 1–6 vs VIRTUAL-active control:

| Day | FRONG-winner buy % of CASHCAT | VIRTUAL control trader % |
|-----|-------------------------------|--------------------------|
| Aug 2 | **16.8%** | 11.7% |
| Aug 3 | 12.3% | 6.8% |
| Aug 4 | **16.4%** | 5.0% |
| Aug 5 | **16.9%** | 3.8% |

FRONG winners punched ~2× trader share in buy USD into the reload; control collapsed. Production RH **8271471**.

### INTEGRITY — bundle / wash (v2.4, Aug 14 2026)

Floors without ceilings scored **HOOPLA** MES 85 / RX 65 / FLASH_IGNITION. Live Q-FLOW that evening: repeat **80.95%**, net-buy wallets **99.45%**, mid $0.39M buy / $3.49M sell, absorp **121.6**, addon **0**. Token dumped. **DOGO/MOW** mid buy ≈ mid sell with repeat < 1% (wash). **CASHCAT** 35/85 + addon 20% and **XST** 51/63 stayed in the organic band.

Replay: `python3 scripts/replay_integrity.py` · spec: `core/scoring/INTEGRITY.md`

### Explored, not shipped

- **Inverted low-vol FOMO** — too much launch spam (99% first-buyer days)
- **Sell-A→buy-B rotation** — real overlap (169 CASHCAT→FRONG wallets) but USD math double-counts; needs cleaner graph
- **pump.fun migrate** — next SOL-specific layer (`pump_call_migrate*`)

### Caveat on first-time buyer counts

Multi-token backtests compute “first trade” inside a long lookback, so reload days show fewer first-timers than a short window. Production Q-REFLEX uses a 3-day lookback (closer to the original CASHCAT suite). Prefer production query IDs for live scoring.

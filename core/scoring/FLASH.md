# FLASH + COHORT — Alternative Alpha Layers

Research framework. Not financial advice.

Daily RX looks at *yesterday’s closed tape*. That misses **same-day flash launches** and underuses **wallet graph** information. These layers fix both.

## 1) Q-FLASH — hourly microstructure

### Why

Daily RX missed **GME** (peak Jul 23) because the launch tape was Jul 22 evening. Hourly FLASH labeled **FLASH_HOT at Jul 22 21:00 UTC** ($2.77M vol, net +, absorp 13.8, 175 buyers) — a full day before the peak-vol day.

**VLAD** only printed FLASH_HOT on peak day (Jul 23 17:00) — still useful for intraday, not a multi-day early signal.

### Hour labels

| Label | Rule |
|-------|------|
| **FLASH_HOT** | net > 0 AND absorp ≥ 1.5 (or no whale sells) AND buyers ≥ 20 (RH) / 40 (SOL) AND hour vol ≥ $50k (RH) / $100k (SOL) |
| **FLASH_WARM** | net > 0 AND buyers ≥ 15/25 AND hour vol ≥ $25k/$50k |
| **COLD** | else |

### Token bands (12h aggregate)

| Band | Rule | Action |
|------|------|--------|
| **FLASH_IGNITION** | ≥2 hot hours, or ≥1 hot + latest still hot | Surface immediately; pair with MES/RX if available |
| **FLASH_WATCH** | hot+warm ≥ 2 or latest warm/hot | Watchlist — early flash |
| **FLASH_COLD** | otherwise | Ignore |

Also emit `flash_score` 0–100 (hot hours × 30 + warm × 10 + latest boost + size boost).

### Hard rules

- FLASH does **not** replace RX for multi-day reloads (CASHCAT/FRONG). Use both.
- Prefer FLASH when token age / prior tape is thin (NEW / flash path).
- SOL Q-FLASH applies `net_12h > −$500k` soft dump filter.
- High FLASH + negative latest_net → treat as climax risk (same anti-TOAD spirit as RX).

### Queries

- RH: `chains/robinhood/dune/q-flash.sql` → **8271470**
- SOL: `chains/solana/dune/q-flash.sql` → **8271473**

---

## 2) Q-COHORT — winner-wallet overlap

### Why (forward test)

Cohort = wallets net-long **FRONG** Jul 30–31 ($50–$25k buy size).  
Target = **CASHCAT** Aug 1–6.

| Day | FRONG-winner traders | Buy USD from cohort | VIRTUAL control traders |
|-----|----------------------|---------------------|-------------------------|
| Aug 1 | 6.1% | **15.6%** | 13.7% |
| Aug 2 | 6.1% | **16.8%** | 11.7% |
| Aug 3 | **7.9%** | 12.3% | 6.8% |
| Aug 4 | **8.9%** | **16.4%** | 5.0% |
| Aug 5 | 8.0% | **16.9%** | 3.8% |

FRONG winners punched ~2× their trader share in buy USD into the CASHCAT reload, while a VIRTUAL-active control cohort collapsed. This is **wallet-graph alpha**, not volume.

### Production labels

Seed = top-5 RH memes by vol in days `[−14, −2]`.  
Winners = net-long $50–$25k on any seed.  
Score yesterday’s candidates:

| Label | Rule |
|-------|------|
| **COHORT_HOT** | winner_buy_pct ≥ 12 **and** winner_trader_pct ≥ 6 |
| **COHORT_WARM** | winner_buy_pct ≥ 8 |
| **COHORT_COLD** | else |

### Queries

- RH: `chains/robinhood/dune/q-cohort.sql` → **8271471**

---

## 3) Angles explored but not shipped (yet)

| Angle | Result |
|-------|--------|
| Inverted low-vol FOMO discovery | Too noisy — brand-new spam tokens dominate 99% first-buyer days |
| Cross-token capital rotation (sell A → buy B in 48h) | Real wallet overlap exists (CASHCAT→FRONG 169 wallets) but USD aggregates double-count; needs cleaner graph before production |
| pump.fun migrate/graduation | Tables available (`pump_call_migrate*`) — next SOL-specific layer |

---

## How layers combine

```
Path A — Reload (multi-day):  MES × RX          → primary
Path B — Flash (same-day):    FLASH band        → primary; RX may be empty/MIXED
Path C — Confirmation:        COHORT_HOT/WARM   → boosts Path A conviction

HIGH CONVICTION if:
  (MES≥60 AND RX≥80)                           -- classic
  OR (FLASH_IGNITION AND latest_net>0 AND MES≥50) -- flash path
  OR (MES≥60 AND RX≥65 AND COHORT_HOT)         -- cohort-boosted warming
```

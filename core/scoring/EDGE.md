# Edge Thesis — Why This Scanner Can Win

Research framework. Not financial advice.

## The core insight (from CASHCAT)

**Reactivation beats novelty.** The Aug 6 listing blowup was visible Aug 3–5 on-chain — vol 4.7×, net-buy streak, holder acceleration — while the token was already 4 weeks old. Most scanners only watch new deploys and miss the highest-conviction leg.

This scanner is built around that asymmetry.

## Edge layers

### Layer 1 — Reflexivity microstructure (Dune, live) ★ PRIMARY (reloads)

**Q-REFLEX** scores the transaction ladder that precedes parabolic runs:

| Signal | Why it matters |
|--------|----------------|
| Absorption ratio | Retail buys / whale sells — floor construction |
| First-time buyers | Fresh wallets entering (FOMO ladder) |
| Add-on rate | Yesterday's buyers buying again, still net long |
| Buy-burst share | Best 2h buys / day buys — ignition window |
| Net flow gate | Without net demand, vol = distribution |

**Validated:** CASHCAT scored RX 82→83→100 on Aug 3–5 *before* the Aug 6 blowup. Aug 6 ($107M vol dump) scored only 70. TOAD ($37M dump) scored 60 MIXED. See `docs/BACKTESTS.md` and `core/scoring/REFLEX.md`.

### Layer 1b — Hourly FLASH (Dune, live) ★ PRIMARY (flashes)

Daily RX is too slow for same-day launches. **Q-FLASH** scores the last 12h hourly.

**Validated:** GME printed **FLASH_HOT at Jul 22 21:00** — day before peak Jul 23 — which daily RX missed. See `core/scoring/FLASH.md`.

### Layer 1c — Winner COHORT (Dune, live) ★ CONFIRMATION

**Q-COHORT** measures whether wallets that won recent RH memes are buying today's candidates.

**Validated:** FRONG Jul 30–31 winners supplied **~15–17% of CASHCAT buy USD** on Aug 2–5 while a VIRTUAL control cohort collapsed. See `core/scoring/FLASH.md`.

### Layer 1d — Flow quality (Q-FLOW)

| Signal | Why it matters |
|--------|----------------|
| Repeat buyer % | Organic interest vs one-shot bots |
| Net-buy wallet % | Breadth of demand |
| Size buckets | Retail vs whale composition |

### Layer 2 — Reactivation mode (Dune, live)

Explicit MES mode for tokens ≥14 days old with:

- Vol acceleration >3× vs 7d avg
- 2+ consecutive net-buy days
- Rising new holders / traders
- Chain share climbing

**Edge:** CASHCAT template codified. Catches "old coin reloading" before listing/catalyst.

### Layer 3 — Cross-chain regime rotation (Dune, live)

Daily digest includes **regime read**: SOL vs RH chain vol, # reactivations per chain, where attention is rotating.

**Edge:** Meme liquidity is finite. Being early on the *chain* that is heating up matters as much as the token.

### Layer 4 — Memory + watchlist graduation (Cursor Memories)

Carry forward tokens that scored 60+ MES. Graduate out after 3 days <45. Track kill signals on watched names.

**Edge:** Continuity across runs — you don't re-discover CASHCAT every day from scratch.

### Layer 5 — Connector boost (future: Coinglass, etc.)

When a connector is enabled, it adds **modifier points** to MES — never replaces on-chain:

| Connector | Modifier use |
|-----------|--------------|
| Coinglass | Perp OI rising + spot net-buy = squeeze setup (+10 MES) |
| Coinglass | Extreme negative funding + absorption = crowded short (+10) |
| Social (future) | Narrative confirmation only — never primary signal |

Connectors plug in via `core/connectors/*.json` — see README there.

## What we deliberately ignore

- Raw "new token" alerts without volume/trader filters (noise)
- Single-day parabolic without absorption (distribution trap)
- Social sentiment as primary signal (lagging, gamed)
- Financial advice or sizing — data-driven watchlist only

## Solana-specific edge

- Use `dex_solana.trades` (Jupiter, Raydium, Pump routes unified)
- Prefer tokens with `pump` mint suffix + rising vol (pump.fun pipeline)
- Higher min volume threshold ($250k vs $50k RH) — Solana is noisier
- Exclude stables/wrapped (WSOL, USDC, cbBTC, USD1, WETH)

## Success metrics ( tune weekly )

| Metric | Target |
|--------|--------|
| False positive rate (MES≥75, flat 7d) | <40% |
| Reactivation catches before 2× move | >50% |
| Digest delivery reliability | 100% Slack posts |

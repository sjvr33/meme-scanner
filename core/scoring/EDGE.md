# Edge Thesis — Why This Scanner Can Win

Research framework. Not financial advice.

## The core insight (from CASHCAT)

**Reactivation beats novelty.** The Aug 6 listing blowup was visible Aug 3–5 on-chain — vol 4.7×, net-buy streak, holder acceleration — while the token was already 4 weeks old. Most scanners only watch new deploys and miss the highest-conviction leg.

This scanner is built around that asymmetry.

## Five edge layers

### Layer 1 — Behavioral absorption (Dune, live)

Score *who* is buying, not just that price went up:

| Signal | Why it matters |
|--------|----------------|
| Repeat buyer % | Organic interest vs one-shot bots |
| Net-buy wallet % | Breadth of demand |
| Size buckets | Retail absorbing whale sells = floor |
| Net-buy streak | Conviction before narrative |

**Edge:** Most free tools show price/vol. Few score absorption quality daily.

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

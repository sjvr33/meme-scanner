# Edge Thesis — Why This Scanner Can Win

Research framework. Not financial advice.

## How we make money

1. **Hold the book.** On Robinhood that is CASHCAT (`chains/robinhood/config/book.json`). The Aug 3–5 reload was the add. The Aug 6 listing was a day not to chase size. Neither is a day to sell. We make money by still being in the only name that matters when hoppers have rotated three times.
2. **Don't get farmed.** Bundle / wash / same-day fireworks we just met are passes. HOOPLA-shaped tape is how accounts die.
3. **Satellite looks only.** A FRONG-style look is extra. It never replaces the book. Selling CASHCAT to chase FLASH is how this stack loses.
4. **Sit in front of retail on *new* names.** Dune is hole cards. DexScreener/web is the board. We look when the crowd is not yet the bid. We do not clock the book as "listing = over."

If a daily Slack fades CASHCAT because a day went red, the run failed — even if every farm was correctly passed.

## The core insight (from CASHCAT)

**Reactivation beats novelty.** The Aug 6 listing blowup was visible Aug 3–5 on-chain — vol 4.7×, net-buy streak, holder acceleration — while the token was already 4 weeks old. Most scanners only watch new deploys and miss the highest-conviction leg.

**Holding beats hopping.** Catching Aug 3–5 and then selling the retrace is the same as never catching it.

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
| Repeat buyer % | Organic interest vs one-shot bots — **ceiling 70% on NEW** |
| Net-buy wallet % | Breadth of demand — **ceiling 90%** (99% is a bundle, not breadth) |
| Size buckets | Retail vs whale composition; mid buy ≈ mid sell = wash |

### Layer 1e — Integrity veto (Q-FLOW + RX) ★ HARD GATE

Floors without ceilings scored HOOPLA as ignition. **BUNDLE** (net-buy wallets ≥ 95%), **WASH** (repeat < 2% + mid symmetry), and **SUSPECT** (high absorp + addon 0) cannot be PLAY / HIGH CONVICTION. Age ≤1d FLASH needs a second session. See `core/scoring/INTEGRITY.md`.

**Validated (Aug 14):** HOOPLA 99.45% net-buy / absorp 121 / addon 0 → dump. DOGO/MOW mid buy = mid sell → wash. CASHCAT 35/85 + addon 20% and XST 51/63 stayed CLEAN.

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

Connectors plug in via `core/connectors/*.json` — see README there.

### Layer 6 — Thesis / public congruence (required in digest)

After scores, **translate then argue with the internet** (`THESIS.md`).

- Conviction is 0–4 independent legs (integrity, ladder, story, opponent) — **not** the RX number
- DexScreener + web search the **contract**. Silence / climax / rug-warning are findings
- **FLAGSHIP** (the book) is HOLD if CLEAN — not CLIMAX
- Narrative **confirms or downgrades** — never upgrades a failed gate to TAKE
- Slack is a trader rundown: hold / look / watch / pass — not a scoreboard

### Layer 7 — AHEAD (forward seat) ★ WHY WE BEAT RETAIL

Dune = hole cards. Public = board. **AHEAD** is the seat: T-2…T+2 clock + level-k + "Retail next".

Retail is level 0 (green candle / headline / first FLASH). L1 fades all volume and misses CASHCAT Aug 3–5. L2 sits at T-2/T-1 on *new* names and does not chase T+1/T+2 fireworks. L3 farms fake T-2 — INTEGRITY catches them.

TAKE (a look) requires IN POSITION. HOLD (the book) does not get clocked as T+2 just because a listing already printed. Chasing CASHCAT's listing hour and chasing HOOPLA's morning FLASH are the same *add* mistake. Selling the book afterward is a second, dumber mistake. See `core/scoring/AHEAD.md`.

## What we deliberately ignore

- Raw "new token" alerts without volume/trader filters (noise)
- Single-day parabolic without absorption (distribution trap)
- Social sentiment as **primary** signal (lagging, gamed) — secondary congruence only
- Financial advice or sizing — research watchlist only
- Spreadsheet digests with no thesis

## Solana-specific edge

- Use `dex_solana.trades` (Jupiter, Raydium, Pump routes unified)
- Prefer tokens with `pump` mint suffix + rising vol (pump.fun pipeline)
- Higher min volume threshold ($250k vs $50k RH) — Solana is noisier
- Exclude stables/wrapped (WSOL, USDC, cbBTC, USD1, WETH)

## Success metrics

| Metric | Target |
|--------|--------|
| Still in the book | CASHCAT is HOLD every clean day — never faded for a red tape or a listing retrace |
| Farm rejection | HOOPLA / wash / 99% net-buy prints are FADE the same day they appear |
| No hop | Slack never sells the book to fund a look |
| Looks | ≤3, only CLEAN + early/product + crowd not yet the bid |
| Digest | 100% Slack posts, English rundown, `python3 scripts/check_vision.py` PASS |

Gate: `python3 scripts/check_vision.py`

# THESIS — Translate the tape, then argue with the internet

Research framework. Not financial advice.

RX / MES / FLASH are a **language**, not a verdict. Humans (and tired agents) stare at "RX 65" and feel nothing. This layer forces three things before Slack:

1. **Translate** every number into a sentence a non-quant can argue with.
2. **Check the world** — DexScreener + web + social for *this contract*, not the ticker.
3. **Conviction** = how many *independent* legs agree. It is **not** the RX score.

Integrity can veto. Narrative can only confirm, downgrade, or explain. Narrative never upgrades a failed gate to TAKE.

## Why this exists

HOOPLA printed MES 85 / RX 65 / FLASH_IGNITION and still dumped. The scores were grammatical English for "lots of first-time buys." They were not a thesis. A thesis would have said: *no website, no socials, 99% of wallets are net buyers, nobody who bought yesterday is still buying, DexScreener LP is a few dollars.* That sentence does not need an RX number.

## Score decoder (say this, not the number)

| You see | It means in English | Unless… |
|---------|---------------------|---------|
| Repeat 25–50% | People who already traded came back. That is interest, not a bot spray. | Day-0 repeat ≥ 70% → wallets recycling the same inventory (bundle). |
| Repeat < 2% + mid buy ≈ mid sell | The same size is bought and sold. That is wash, not a crowd. | Brand-new holders who only bought (mid buy >> sell) can have low repeat honestly. |
| Net-buy wallets 40–85% | A real mix of buyers and sellers. Breadth. | ≥ 95% "buyers" → sellers are hidden / bundled. That is not demand. |
| Absorp 1.2–8 + addon > 0 | Small bids are eating large offers *and* yesterday's buyers are still long. A floor. | Absorp ≥ 20 with addon 0 → sells never hit the tape. Fake floor (HOOPLA 121). |
| Addon ≥ 15% | Sticky money. The ladder is climbing. | Addon 0 on a "hot" NEW print → one-shot inventory. |
| FLASH_IGNITION, age ≤ 1d | Fireworks on day one. Wait for the second show. | Still on FLASH *and* still net-green 6–12h later → flash path may upgrade. |
| FLASH gone + price up + day net red | Morning crowd paid the exit. | — |
| MES ≥ 75 + RX < 65 | Loud attention, weak ladder. Distribution into hype. | — |
| High vol + negative net | Someone is cashing chips while the table cheers (TOAD). | — |
| COHORT_HOT | Wallets that already won a recent meme are buying this one. | Cohort into a BUNDLE name is just the farm rotating. |

**Forbidden Slack:** `RH HOOPLA — MES 85 · RX 65 · FLASH 100`. That is a scoreboard.

**Required Slack:** English first. Scores may appear in parentheses as evidence, never as the sentence.

## Public-source protocol (mandatory, every Slack name)

Search **the contract / mint**, not the ticker alone. Ticker collisions are the default (HOOPLA has a dead Base namesake; XST has Stealth / SORA / other Solana mints).

Do these in order. Cite URLs. If a step fails, say so — do not invent a story.

| Step | Where | Extract |
|------|-------|---------|
| 1 | DexScreener `latest/dex/tokens/<address>` | Name, MC, LP USD, 24h %, `websites[]`, `socials[]` |
| 2 | Web search `{ticker} {chain} {address_8} memecoin` | Catalyst, listing, scam/rug article, silence |
| 3 | Official site / X if DexScreener listed one | Is the story early, climax, or marketing? |
| 4 | Explorer / CoinGecko / Bubblemaps if the name is loud | Holder concentration, lock, impersonation |

### Public labels (pick one)

| Label | When | Effect on conviction |
|-------|------|----------------------|
| **EARLY** | Fresh Schelling, thin chatter, product/lore exists, not on every timeline yet | +1 story leg |
| **FLAGSHIP** | The chain's book — pinned in `chains/<id>/config/book.json` | +1 story leg. Stance is **HOLD** if CLEAN. A listing spike is "don't chase," not "sell." |
| **CLIMAX** | Same-day fireworks / a one-off headline on a *flip*, not the book | 0 — story is priced. Do **not** put the book here. |
| **SILENCE** | No website, no socials, no news for *this* contract | 0 — no coordination object |
| **WARNING** | Rug / bundle / 70%+ clustered supply / impersonation articles | 0 — and downgrade WATCH→FADE if integrity was the only green leg |
| **PRODUCT** | Real site + docs (not just a meme jpg) | +1 story leg if tape is CLEAN |

Silence is a finding. "Could not find a story" is a valid Public line.

## Conviction (0–4) — independent of RX

Count **legs**. A leg is a yes/no from a *different* evidence class.

| # | Leg | Yes when |
|---|-----|----------|
| 1 | **Integrity** | Q-FLOW label CLEAN |
| 2 | **Ladder** | Addon > 0 and absorp in ~1.2–8 (or FLASH still net-green on session 2) |
| 3 | **Story** | Public label EARLY, PRODUCT, or FLAGSHIP |
| 4 | **Opponent** | You can name who is selling to whom, and it is *not* "retail is the only bid" |

| Legs | Max Slack | Meaning |
|------|-----------|---------|
| 0–1 | **FADE** | One print agreeing with itself is not a hand |
| 2 | **WATCH** | Missing a piece. Do not chase. |
| 3–4 | **TAKE** allowed | Only if INTEGRITY + FLASH.md gates also pass |

RX 100 with 1 leg is still a fade. FRONG-style TAKE is 3–4 legs (clean tape + Uniswap frog lore + early cohort + opponent = hot wallets rotating, not a bundle).

## Slack rundown (required shape)

Write like an expert who trades these markets — not a labeled form. Fail the run if any PLAY is a scoreboard or uses internal codes (MES, RX, T-2, OOP, conviction n/4).

```
RH FRONG — I'd take a small look

[what it is, in two sentences]

[what the tape is doing, plus what the internet says about this contract]

[what retail does next, and who is on the other side]

I'm out if [concrete abort].
`address`
```

Calls in English only: **I'd hold this — I'm not hopping** / **I'd take a small look** / **I'm watching — not pressing** / **I'd pass**.

The book (`book.json`) is named first. A look is a satellite. Selling the book to chase a look is a failure mode.

## Worked examples (Aug 14 2026 — cited)

**HOOPLA** `0x6713fdee…1c7a` — FADE, conviction 0/4  
Thesis: A same-day ticker with no site and no socials. The book was almost all "buyers" because the sell side was bundled; by evening DexScreener LP was ~$4 and the main pair was −99.96% on the day.  
Public: DexScreener `websites: []` `socials: []`. Web search hits a *different* dead Base HOOPLA, not this RH contract.  
Tape: 99.45% net-buy wallets, addon 0, absorp 121 = fake floor.  
https://dexscreener.com/robinhood/0xb4d0eb61e1602593e5aa230a3a0eedbdb9ac4b02

**CASHCAT** `0x020bfc65…18b4` — **HOLD**, the book  
Thesis: This is the chain's cat. The Aug 6 listing was a day not to chase size. It is not a reason to sell. Organic tape + a real site. I hold it. I do not hop to FRONG or the next FLASH print.  
Kill: farm print or the pool dies — not "another red day."  
https://coinsprobe.com/robinhood-lists-cashcat-memecoin-jumps-sharply-on-official-announcement/

**STONKBROKER** `0xe934e36a…bf50` — WATCH, conviction 3/4 (integrity + ladder + product). MES gate not met → not TAKE.  
Thesis: This is not a naked ticker. Clutch Markets shipped 4,444 ERC-6551 "broker" NFTs that hold stock tokens; the ERC-20 is the activation / AMM chip. Tape looks like real two-way flow and DexScreener still has ~$4.2M LP.  
Public: https://www.stonkbrokers.cash · DexScreener lists the site + @ClutchMarkets.

**XST** `XSTuo1fV…YZqP` — WATCH at most, conviction 1–2/4. Do not TAKE.  
Thesis: Flow can look organic (repeat ~51%, net-buy wallets ~63%) while the *float* is not. DexScreener LP is thin vs a ~$35M MC, the book is −46% on the day, and Bubblemaps (Aug 13) flagged ~74% supply in a tight cluster plus TikTok clips. Ticker collisions (Stealth / SORA / other mints) are the other trap.  
Public: https://xsolut.ai · https://www.cryptopolitan.com/bubblemaps-xst-warning-on-tiktok/

**FRONG** `0x6245e67a…0c47` — template TAKE (Aug 13), conviction 3–4/4  
Thesis: A Uniswap designer minted the pools.trade teaser frog on July 30; Uniswap launched the launchpad Aug 5 and disclaimed the token. That is a real Schelling object, not a random ticker, and the tape was a ladder not a bundle.  
Public: https://thedefiant.io/news/defi/uniswap-pools-trade-launchpad-live-frong-memecoin

**DOGO / MOW** — FADE, conviction 0/4  
Thesis: Mid-size buys and sells print the same dollar amount; almost nobody trades twice. CoinGecko can still list DogBull with a market cap — a listing is not a ladder.  
Tape: WASH.

**COBRA** — FADE, conviction 0/4  
Thesis: Farm-pack sibling of HOOPLA. 99.85% net-buy wallets, addon 0. No credible RH story for this contract in public search.

## Queries / code

- Classifier helpers: `core/scoring/thesis.py`
- Replay: `python3 scripts/replay_thesis.py`
- Slack / automation: Phase 4.5 in `prompts/orchestrator-multichain.md`

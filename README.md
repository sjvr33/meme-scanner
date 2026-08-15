# meme-scanner

Research scanner for Robinhood L2 + Solana memes. **Not financial advice.**

**How we make money:** hold the book (CASHCAT), don't get farmed, take satellite looks only. Hopping names is how this stack loses.

**Delivery:** one Cursor Automation → Dune → Slack at 08:00 SAST  
**Stack:** INTEGRITY → RX / FLASH / COHORT → THESIS / AHEAD → HOLD / look / watch / pass  
**Future:** Coinglass modifiers · pump.fun graduation

Doctrine: [core/scoring/EDGE.md](core/scoring/EDGE.md) · book: [chains/robinhood/config/book.json](chains/robinhood/config/book.json)

```bash
python3 scripts/check_vision.py
python3 scripts/run_board.py core/scoring/fixtures/live_flow.json
```

## Quick start

```bash
git clone https://github.com/sjvr33/meme-scanner.git
cd meme-scanner
# See docs/AUTOMATION.md for Cursor Automation setup
```

## Structure

```
core/           Manifest, scoring, operating doctrine (EDGE.md)
chains/         Dune SQL + query IDs + book.json + watchlist
prompts/        Daily automation instructions
automation/     Cursor Automation prefill
docs/           Architecture + setup
```

## Dune queries

| Chain | Discover | Reactivate | Flow | **Reflex** | **Flash ★** | Cohort | Watch |
|-------|----------|------------|------|------------|-------------|--------|-------|
| Robinhood | [8269896](https://dune.com/queries/8269896) | [8269903](https://dune.com/queries/8269903) | [8269897](https://dune.com/queries/8269897) | [8271348](https://dune.com/queries/8271348) | [8271470](https://dune.com/queries/8271470) | [8271471](https://dune.com/queries/8271471) | [8269904](https://dune.com/queries/8269904) |
| Solana | [8271224](https://dune.com/queries/8271224) | [8271226](https://dune.com/queries/8271226) | [8271228](https://dune.com/queries/8271228) | [8271349](https://dune.com/queries/8271349) | [8271473](https://dune.com/queries/8271473) | — | [8271229](https://dune.com/queries/8271229) |

## Schedule

**One** daily automation: **06:00 UTC** (08:00 SAST) — multi-chain Reflex + Flash + Cohort digest.  
Setup: [docs/AUTOMATION.md](docs/AUTOMATION.md) · Prefill: `automation/scanner-multichain-prefill.json`

## Adding Coinglass (future)

1. Set `enabled: true` in `core/connectors/coinglass.stub.json`
2. Wire MCP/API
3. Orchestrator Phase 2.5 auto-applies MES modifiers

## Disclaimer

Research tooling only. Not financial advice.

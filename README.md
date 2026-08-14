# meme-scanner

Multi-chain meme scanner with **Reflex Score (RX)** + **FLASH** (hourly) + **COHORT** (winner wallets) — plus pluggable connectors.

**Chains:** Robinhood L2 · Solana  
**Delivery:** Cursor Automation → Dune MCP → Slack digest  
**Alpha:** Dune hole cards · public board · AHEAD (sit in front of retail, not next to them)  
**Future:** Coinglass (perp OI/funding modifiers) · pump.fun graduation

## Why this exists

Volume scanners scream loudest on dump days. CASHCAT's Aug 6 listing climax was $107M vol / net−$1.18M. The **real setup** was Aug 3–5 — when Reflex Score hit 82→83→100 *before* the blowup. Daily RX still missed flash launches like GME — **Q-FLASH** catches those hourly. **Q-COHORT** confirms when prior meme winners rotate into the next name.

See [core/scoring/AHEAD.md](core/scoring/AHEAD.md) · [core/scoring/THESIS.md](core/scoring/THESIS.md) · [core/scoring/INTEGRITY.md](core/scoring/INTEGRITY.md) · [docs/BACKTESTS.md](docs/BACKTESTS.md).

```bash
python3 scripts/replay_integrity.py
python3 scripts/replay_thesis.py
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
core/           Manifest, MES scoring, connector registry
chains/         Per-chain Dune SQL + config (robinhood, solana)
prompts/        Automation agent instructions
automation/     Cursor Automation prefill JSON
docs/           Architecture + setup guides
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

# meme-scanner

Multi-chain meme scanner with **Reflex Score (RX)** — microstructure alpha that detects pre-parabolic buyer ladders — plus pluggable connectors.

**Chains:** Robinhood L2 · Solana  
**Delivery:** Cursor Automation → Dune MCP → Slack digest  
**Alpha:** Q-REFLEX (absorption · first-timers · add-ons · buy-burst · net gate)  
**Future:** Coinglass (perp OI/funding modifiers)

## Why this exists

Volume scanners scream loudest on dump days. CASHCAT's Aug 6 listing climax was $107M vol / net−$1.18M. The **real setup** was Aug 3–5 — when Reflex Score hit 82→83→100 *before* the blowup. TOAD's $37M Solana dump scored RX 60 (MIXED) and is correctly rejected.

See [core/scoring/REFLEX.md](core/scoring/REFLEX.md) · [docs/BACKTESTS.md](docs/BACKTESTS.md) · [core/scoring/EDGE.md](core/scoring/EDGE.md).

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

| Chain | Discover | Reactivate | Flow | **Reflex ★** | Watch |
|-------|----------|------------|------|-------------|-------|
| Robinhood | [8269896](https://dune.com/queries/8269896) | [8269903](https://dune.com/queries/8269903) | [8269897](https://dune.com/queries/8269897) | [8271348](https://dune.com/queries/8271348) | [8269904](https://dune.com/queries/8269904) |
| Solana | [8271224](https://dune.com/queries/8271224) | [8271226](https://dune.com/queries/8271226) | [8271228](https://dune.com/queries/8271228) | [8271349](https://dune.com/queries/8271349) | [8271229](https://dune.com/queries/8271229) |

## Schedule

Daily **06:00 UTC** (08:00 SAST) — multi-chain digest  
Optional **06:30 UTC** — deep analyst pass

## Adding Coinglass (future)

1. Set `enabled: true` in `core/connectors/coinglass.stub.json`
2. Wire MCP/API
3. Orchestrator Phase 2.5 auto-applies MES modifiers

## Disclaimer

Research tooling only. Not financial advice.

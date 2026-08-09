# meme-scanner

Multi-chain on-chain meme scanner with **pluggable connectors** — built for edge in reactivation detection, absorption quality, and cross-chain regime rotation.

**Chains:** Robinhood L2 · Solana  
**Delivery:** Cursor Automation → Dune MCP → Slack digest  
**Future:** Coinglass (perp OI/funding modifiers)

## Why this exists

Most scanners alert on new deploys. The highest-conviction moves — like CASHCAT Aug 3–5 before the Aug 6 listing blowup — are **reactivations** of older tokens. This system codifies that pattern across chains.

See [core/scoring/EDGE.md](core/scoring/EDGE.md) for the full edge thesis.

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

| Chain | Discover | Reactivate | Flow | Watch |
|-------|----------|------------|------|-------|
| Robinhood | [8269896](https://dune.com/queries/8269896) | [8269903](https://dune.com/queries/8269903) | [8269897](https://dune.com/queries/8269897) | [8269904](https://dune.com/queries/8269904) |
| Solana | see `chains/solana/config/query-ids.json` | | | |

## Schedule

Daily **06:00 UTC** (08:00 SAST) — multi-chain digest  
Optional **06:30 UTC** — deep analyst pass

## Adding Coinglass (future)

1. Set `enabled: true` in `core/connectors/coinglass.stub.json`
2. Wire MCP/API
3. Orchestrator Phase 2.5 auto-applies MES modifiers

## Disclaimer

Research tooling only. Not financial advice.

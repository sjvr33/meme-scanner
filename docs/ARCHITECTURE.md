# Architecture

Multi-chain meme scanner with pluggable connectors. **One** daily Cursor Automation.

```
                    ┌─────────────────────────────────────┐
                    │   Cursor Automation (daily 08:00)   │
                    │   prompts/orchestrator-multichain.md │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │           core/manifest.json         │
                    │  MES × RX × FLASH × COHORT           │
                    └──────────────┬──────────────────────┘
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
    ┌──────▼──────┐         ┌──────▼──────┐         ┌──────▼──────┐
    │  chains/    │         │  chains/    │         │ connectors/ │
    │  robinhood  │         │  solana     │         │ dune ✅     │
    │  7 queries  │         │  6 queries  │         │ coinglass 🔜│
    └──────┬──────┘         └──────┬──────┘         └─────────────┘
           │                       │
           └───────────┬───────────┘
                       ▼
              Dune MCP (executeQueryById)
                       ▼
                 Slack digest + Memories
```

## Directory layout

| Path | Purpose |
|------|---------|
| `core/manifest.json` | Registry: chains, connectors, **one** automation |
| `core/scoring/` | MES, REFLEX, FLASH, EDGE |
| `core/connectors/` | Pluggable data source configs |
| `chains/<id>/dune/` | Chain-specific SQL |
| `chains/<id>/config/` | Query IDs, watchlist |
| `prompts/orchestrator-multichain.md` | Daily automation prompt (only prompt) |
| `automation/scanner-multichain-prefill.json` | Cursor Automation prefill (only prefill) |

## Scoring pipeline

1. **Discover** — top tokens by 24h vol per chain
2. **Reactivate + Flow** — MES macro
3. **Reflex (RX)** — microstructure (reload path)
4. **Flash** — hourly (same-day launch path)
5. **Cohort** — winner-wallet overlap (RH confirmation)
6. **Watch** — pinned + carry-forward
7. **Regime** — cross-chain rotation
8. **Deliver** — Slack + Memories

## Adding a new chain

1. Copy `chains/solana/` → `chains/<new>/`
2. Add Dune queries + `query-ids.json`
3. Register in `core/manifest.json`
4. Orchestrator picks up via manifest

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
                    │  MES × RX × FLASH × COHORT × INTEGRITY│
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
| `core/scoring/` | MES, REFLEX, FLASH, INTEGRITY, THESIS, EDGE, TABLE |
| `core/connectors/` | Pluggable data source configs |
| `chains/<id>/dune/` | Chain-specific SQL |
| `chains/<id>/config/` | Query IDs, watchlist |
| `prompts/orchestrator-multichain.md` | Daily automation prompt (only prompt) |
| `automation/scanner-multichain-prefill.json` | Cursor Automation prefill (only prefill) |

## Scoring pipeline

1. **Discover** — top tokens by 24h vol per chain
2. **Reactivate + Flow** — MES macro + integrity_label (bundle/wash)
3. **Reflex (RX)** — microstructure (reload path); absorp+addon=0 is a SUSPECT tell
4. **Flash** — hourly (same-day launch path)
5. **Cohort** — winner-wallet overlap (RH confirmation)
6. **Watch** — pinned + carry-forward
7. **Thesis + public sources** — DexScreener/web by contract; English decoder; conviction 0–4 (THESIS.md)
8. **Table read** — cross-chain regime in prose
9. **Deliver** — Slack TAKE/WATCH/FADE + Memories

## Adding a new chain

1. Copy `chains/solana/` → `chains/<new>/`
2. Add Dune queries + `query-ids.json`
3. Register in `core/manifest.json`
4. Orchestrator picks up via manifest

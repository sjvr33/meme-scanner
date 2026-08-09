# Architecture

Multi-chain meme scanner with pluggable connectors.

```
                    ┌─────────────────────────────────────┐
                    │         Cursor Automation           │
                    │   (orchestrator-multichain.md)      │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │           core/manifest.json         │
                    │  scoring (MES) · connector registry  │
                    └──────────────┬──────────────────────┘
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
    ┌──────▼──────┐         ┌──────▼──────┐         ┌──────▼──────┐
    │  chains/    │         │  chains/    │         │ connectors/ │
    │  robinhood  │         │  solana     │         │ dune ✅     │
    │  4 queries  │         │  4 queries  │         │ coinglass 🔜│
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
| `core/manifest.json` | Registry: chains, connectors, automations |
| `core/scoring/MES.md` | Meme Early Score rules (shared) |
| `core/scoring/EDGE.md` | Why this system has edge |
| `core/connectors/` | Pluggable data source configs |
| `chains/<id>/dune/` | Chain-specific SQL |
| `chains/<id>/config/` | Query IDs, watchlist |
| `chains/<id>/chain.json` | Chain metadata + thresholds |
| `prompts/` | Automation agent instructions |

## Adding a new chain

1. Copy `chains/solana/` structure → `chains/<new>/`
2. Write 4 Dune queries (discover, reactivate, flow, watch)
3. Add `chain.json` with thresholds
4. Register in `core/manifest.json`
5. Orchestrator auto-picks up via manifest (no prompt rewrite needed)

## Adding a connector (e.g. Coinglass)

1. Implement `core/connectors/coinglass.json` (copy stub, set `enabled: true`)
2. Wire MCP/API
3. Orchestrator Phase 2.5 applies MES modifiers per connector rules
4. Connectors never trigger alerts alone

## Scoring pipeline

1. **Discover** — top tokens by 24h vol per chain
2. **Reactivate** — old-token reload candidates
3. **Flow** — absorption quality (repeat buyers, size buckets)
4. **Score** — MES 0–100 per `core/scoring/MES.md`
5. **Connector boost** — optional modifiers (Coinglass etc.)
6. **Watch** — deep dive on pinned + carry-forward
7. **Regime** — cross-chain rotation read
8. **Deliver** — Slack + Memories update

# Connectors

Pluggable data sources that ** augment** on-chain MES scoring — never replace it.

## Interface contract

Each connector is a JSON file in this directory:

```json
{
  "id": "coinglass",
  "enabled": false,
  "mcp_server_name": null,
  "signals": [
    {
      "id": "perp_oi_change_24h",
      "mes_modifier": 10,
      "rule": "OI up >20% AND spot net-buy positive → +10 MES"
    }
  ],
  "tokens_supported": "symbols_with_perps_only"
}
```

## Rules for orchestrator

1. Run **Dune chain queries first** (always)
2. If connector `enabled: true` in manifest, fetch its signals for top candidates only
3. Apply `mes_modifier` from connector rules — cap total connector boost at +20 MES
4. Never alert on connector data alone

## Adding a connector

1. Create `core/connectors/<name>.json`
2. Add entry to `core/manifest.json` → `connectors`
3. Document signals in connector file
4. Update orchestrator prompt Phase 2.5 (connector boost)
5. Wire MCP/API when available

## Current connectors

| ID | Status | File |
|----|--------|------|
| dune | ✅ Live | `dune.json` |
| coinglass | 🔜 Stub | `coinglass.stub.json` |

# Solana — Signal Notes

- **Primary venue:** `dex_solana.trades` (Jupiter, Raydium, Pump routes)
- **Faster cycle:** Reactivation mode uses age ≥7d (vs 14d on RH)
- **Pump.fun pipeline:** Mints ending in `pump` — flag `is_pump_mint=1` in queries
- **Min vol:** $250k/24h (noisier chain, higher bar)
- **Exclude:** WSOL, stables, cbBTC, WETH, JupUSD

## Solana-specific edge

- High trader count + negative net on huge vol = distribution (e.g. TOAD pattern)
- Positive net + rising traders + pump mint = early reactivation candidate
- Cross-check: if RH chain token same ticker heating up, narrative may be cross-chain

## Kill signals (SOL-specific)

- Whale bucket >60% of buy vol + net negative 48h
- Vol collapse >70% from peak with no holder growth

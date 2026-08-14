# Cursor Automation Setup (single path)

There is **one** production automation. Old RH-only / deep-analyst prefills were removed.

| Name | Cron (UTC) | SAST | Prefill |
|------|------------|------|---------|
| **Meme Scanner — Multi-Chain Reflex Digest** | `0 6 * * *` | 08:00 | `automation/scanner-multichain-prefill.json` |

Prompt: `prompts/orchestrator-multichain.md`  
Repo: `sjvr33/meme-scanner` @ `main`

## One-time save checklist

Do this once in Cursor Automations UI (prefill opens via agent or paste JSON):

1. **Repo** = `sjvr33/meme-scanner`, branch `main`
2. **MCP** = Dune (`dune`) authenticated
3. **Slack** = your DM or `#meme-scanner` (required — prefill cannot pick the channel)
4. **Memories** = on
5. **Cron** = `0 6 * * *` (08:00 SAST)
6. **Save** → **Run once** manually → confirm Slack is a **Table Read** (TABLE / PLAYS / PASSES), not a score spreadsheet
7. Enable Slack mobile notifications if you want push

Quality bar for a good run: each PLAY has On-chain + Narrative + Opponent + Kill + TAKE|WATCH. See `core/scoring/TABLE.md`.

If an old automation named `RH Meme Scanner — Daily Digest` or `RH Meme Scanner — Deep Analyst` still exists in Cursor, **delete it** — those point at the retired `rh-meme-scanner` repo / old prompts.

## Query IDs (production)

| Chain | Discover | Reactivate | Flow | Reflex | Flash | Cohort | Watch |
|-------|----------|------------|------|--------|-------|--------|-------|
| Robinhood | 8269896 | 8269903 | 8269897 | 8271348 | 8271470 | 8271471 | 8269904 |
| Solana | 8271224 | 8271226 | 8271228 | 8271349 | 8271473 | — | 8271229 |

Config source of truth: `chains/<chain>/config/query-ids.json`

## Alpha layers (v2.4)

- **INTEGRITY** — bundle / wash veto on Q-FLOW (`core/scoring/INTEGRITY.md`)
- **Q-REFLEX** — multi-day reloads (`core/scoring/REFLEX.md`)
- **Q-FLASH** — same-day launches (`core/scoring/FLASH.md`); age ≤1d needs a second session
- **Q-COHORT** — winner-wallet confirmation (RH)
- **TABLE** — narrative/web congruence + TAKE/WATCH/FADE voice (`core/scoring/TABLE.md`)
- **THESIS** — English decoder + DexScreener/web + conviction 0–4 (`core/scoring/THESIS.md`)
- **AHEAD** — information clock + seat + Retail next (`core/scoring/AHEAD.md`)

HIGH CONVICTION paths in `core/scoring/FLASH.md`. Narrative never upgrades a failed on-chain gate.

## Optional: deep dive

No separate cron. Use Cursor Task agent `analyst` (`.cursor/agents/analyst.md`) ad hoc after the morning digest if you want a top-3 deep dive.

## Future: Coinglass

Set `enabled: true` in `core/connectors/coinglass.stub.json` when MCP is wired.

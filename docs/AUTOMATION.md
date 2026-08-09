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
6. **Save** → **Run once** manually → confirm Slack message has both RH + SOL sections
7. Enable Slack mobile notifications if you want push

If an old automation named `RH Meme Scanner — Daily Digest` or `RH Meme Scanner — Deep Analyst` still exists in Cursor, **delete it** — those point at the retired `rh-meme-scanner` repo / old prompts.

## Query IDs (production)

| Chain | Discover | Reactivate | Flow | Reflex | Flash | Cohort | Watch |
|-------|----------|------------|------|--------|-------|--------|-------|
| Robinhood | 8269896 | 8269903 | 8269897 | 8271348 | 8271470 | 8271471 | 8269904 |
| Solana | 8271224 | 8271226 | 8271228 | 8271349 | 8271473 | — | 8271229 |

Config source of truth: `chains/<chain>/config/query-ids.json`

## Alpha layers (v2.2)

- **Q-REFLEX** — multi-day reloads (`core/scoring/REFLEX.md`)
- **Q-FLASH** — same-day launches (`core/scoring/FLASH.md`)
- **Q-COHORT** — winner-wallet confirmation (RH)

HIGH CONVICTION paths in `core/scoring/FLASH.md`.

## Optional: deep dive

No separate cron. Use Cursor Task agent `analyst` (`.cursor/agents/analyst.md`) ad hoc after the morning digest if you want a top-3 deep dive.

## Future: Coinglass

Set `enabled: true` in `core/connectors/coinglass.stub.json` when MCP is wired.

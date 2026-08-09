# Cursor Automation Setup

## Automations

| Name | Cron (UTC) | SAST | Prompt |
|------|------------|------|--------|
| Multi-Chain Daily Digest | `0 6 * * *` | 08:00 | `prompts/orchestrator-multichain.md` |
| Deep Analyst (optional) | `30 6 * * *` | 08:30 | `prompts/analyst.md` |

Prefill JSON: `automation/scanner-multichain-prefill.json`

## Prerequisites

1. Cursor paid plan + Cloud Agents
2. Slack at [cursor.com/dashboard/integrations](https://cursor.com/dashboard/integrations)
3. Dune MCP at [cursor.com/agents](https://cursor.com/agents) — server name: `dune`
4. Repo: `sjvr33/meme-scanner` (main branch)

## Query IDs

| Chain | Discover | Reactivate | Flow | Watch |
|-------|----------|------------|------|-------|
| Robinhood | 8269896 | 8269903 | 8269897 | 8269904 |
| Solana | 8271224 | 8271226 | 8271228 | 8271229 |
| Robinhood Reflex ★ | 8271348 | — | — | — |
| Solana Reflex ★ | 8271349 | — | — | — |

Full config: `chains/<chain>/config/query-ids.json`

## After save

1. Pin Slack DM or `#meme-scanner` channel
2. Run manually once — verify both chains return data
3. Enable mobile notifications for Slack

## Future: Coinglass

Set `enabled: true` in `core/connectors/coinglass.stub.json` when MCP wired.
Orchestrator Phase 2.5 applies modifiers automatically.


## Reflex Score (v2.1)

Primary alpha: execute **Q-REFLEX** (RH `8271348`, SOL `8271349`) every run. HIGH CONVICTION requires RX ≥ 80. See `core/scoring/REFLEX.md`.

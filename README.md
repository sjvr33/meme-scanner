# RH Meme Scanner

Daily on-chain scanner for **Robinhood Chain** memecoins — discovery, reactivation scoring, and Slack digest via Cursor Automation + Dune.

## What it does

1. **Discover** top tokens by 24h DEX volume (Q-DISCOVER)
2. **Score** new coins and **reactivations** (CASHCAT Aug 3–5 pattern) (Q-REACTIVATE, Q-FLOW)
3. **Watch** pinned tokens like CASHCAT (Q-WATCH)
4. **Deliver** daily digest to Slack via Cursor Cloud Agent

## Quick start

```bash
# 1. Clone
git clone https://github.com/sjvr33/rh-meme-scanner.git
cd rh-meme-scanner

# 2. Verify Dune query IDs in config/query-ids.json

# 3. Set up Cursor Automation — see docs/AUTOMATION.md
```

## Structure

```
dune/           SQL for 4 saved Dune queries
config/         Query IDs + watchlist
docs/           Scoring rules + automation setup
prompts/        Cursor Automation agent prompts
.cursor/agents/ Optional custom subagents (when using repo checkout)
```

## Scoring

See [docs/SCORING.md](docs/SCORING.md) for Meme Early Score (MES) — NEW vs REACTIVATION modes.

## Automation

See [docs/AUTOMATION.md](docs/AUTOMATION.md) for Cursor Automation setup (cron, MCP, Slack).

**Schedule:** Daily 06:00 UTC (08:00 SAST)

## Disclaimer

Research tooling only. Not financial advice.

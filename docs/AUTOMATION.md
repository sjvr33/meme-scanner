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
6. **Save** → **Run once** manually → confirm Slack is a **trader rundown** (I'd hold / I'd look / I'd pass), not a score spreadsheet
7. After pulling `main`, re-save this prefill so the live automation matches the repo
8. Enable Slack mobile notifications if you want push

Quality bar for a good run:
- CASHCAT is **I'd hold this — I'm not hopping** if the tape is still CLEAN
- Farms / washes are **I'd pass**
- Looks are satellites — the book is not sold to fund them
- English only. See `core/scoring/EDGE.md` + `core/scoring/TABLE.md`.

Gate: `python3 scripts/check_vision.py`

If an old automation named `RH Meme Scanner — Daily Digest` or `RH Meme Scanner — Deep Analyst` still exists in Cursor, **delete it** — those point at the retired `rh-meme-scanner` repo / old prompts.

## Query IDs (production)

| Chain | Discover | Reactivate | Flow | Reflex | Flash | Cohort | Watch |
|-------|----------|------------|------|--------|-------|--------|-------|
| Robinhood | 8269896 | 8269903 | 8269897 | 8271348 | 8271470 | 8271471 | 8269904 |
| Solana | 8271224 | 8271226 | 8271228 | 8271349 | 8271473 | — | 8271229 |

Config source of truth: `chains/<chain>/config/query-ids.json`

## Alpha layers (v2.7)

- **BOOK** — CASHCAT is the hold (`chains/robinhood/config/book.json`)
- **INTEGRITY** — bundle / wash veto (`core/scoring/INTEGRITY.md`)
- **Q-REFLEX** — multi-day reloads (`core/scoring/REFLEX.md`)
- **Q-FLASH** — same-day launches (`core/scoring/FLASH.md`); age ≤1d needs a second session (not a book-sell)
- **Q-COHORT** — winner-wallet confirmation (RH)
- **THESIS + AHEAD + TABLE** — English rundown, seat, hold / look / watch / pass

Narrative never upgrades a failed on-chain gate. A red day never sells the book.

## Optional: deep dive

No separate cron. Use Cursor Task agent `analyst` (`.cursor/agents/analyst.md`) ad hoc after the morning digest if you want a top-3 deep dive.

## Future: Coinglass

Set `enabled: true` in `core/connectors/coinglass.stub.json` when MCP is wired.

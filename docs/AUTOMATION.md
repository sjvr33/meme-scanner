# Cursor Automation Setup

Daily RH Chain meme scanner delivered via Slack.

## Prerequisites

1. **Cursor paid plan** with Cloud Agents
2. **Slack** connected at [cursor.com/dashboard/integrations](https://cursor.com/dashboard/integrations)
3. **Dune MCP** connected in [cursor.com/agents](https://cursor.com/agents) → MCP → add **Dune** → authenticate
   - Cloud automations use **dashboard MCP**, not local IDE `mcp.json`
   - Server name in automation: `dune`

## Automations (2 recommended)

### 1. Scanner — Daily Digest (primary)

| Setting | Value |
|---------|-------|
| Name | RH Meme Scanner — Daily Digest |
| Trigger | Cron `0 6 * * *` (08:00 SAST) |
| Repository | `sjvr33/rh-meme-scanner` (main) |
| Tools | MCP (dune), Send to Slack, Memories |
| Prompt | `prompts/orchestrator.md` |

### 2. Analyst — Deep Dive (optional, v2)

| Setting | Value |
|---------|-------|
| Name | RH Meme Scanner — Deep Analyst |
| Trigger | Cron `30 6 * * *` (08:30 SAST) |
| Repository | Same repo |
| Tools | MCP (dune), Send to Slack, Memories |
| Prompt | `prompts/analyst.md` |

## After first save

1. Pin Slack destination (DM or `#meme-scanner` channel)
2. Run manually once; verify Dune queries execute
3. Check run history for `mcp_auth_error`
4. Enable mobile notifications for Slack delivery

## Query IDs

See `config/query-ids.json` — update after Dune queries are saved.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| MCP auth error | Re-auth Dune in cursor.com dashboard |
| Empty digest | Check query IDs; run queries manually on Dune |
| Wrong timezone | Cron is UTC; 06:00 UTC = 08:00 SAST |
| No Slack message | Pin channel in automation settings |

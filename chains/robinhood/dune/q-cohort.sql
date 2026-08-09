-- Q-COHORT: Winner-wallet overlap — do recent meme winners show up early in new candidates?
-- Validated: FRONG Jul 30-31 winners → ~15-17% of CASHCAT buy USD on Aug 2-5 reload
-- Control (VIRTUAL traders) collapsed from 13% → 2% of CASHCAT traders over same window
-- See core/scoring/FLASH.md (cohort section)

WITH excluded AS (
    SELECT contract_address FROM tokens.erc20
    WHERE blockchain = 'robinhood'
      AND symbol IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
),
-- Seed tokens: top 5 by vol in days [-14, -2] (completed, no lookahead into target day)
seed_tokens AS (
    SELECT token_address FROM (
        SELECT
            CASE
                WHEN token_bought_address NOT IN (SELECT contract_address FROM excluded)
                 AND token_bought_address != 0x0000000000000000000000000000000000000000
                THEN token_bought_address ELSE token_sold_address
            END AS token_address,
            SUM(amount_usd) AS vol
        FROM dex.trades
        WHERE blockchain = 'robinhood'
          AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '20' DAY)
          AND block_time >= CURRENT_DATE - INTERVAL '14' DAY
          AND block_time < CURRENT_DATE - INTERVAL '2' DAY
          AND amount_usd > 0
        GROUP BY 1
        HAVING SUM(amount_usd) >= 2000000
        ORDER BY 2 DESC
        LIMIT 5
    ) s
    WHERE token_address NOT IN (SELECT contract_address FROM excluded)
),
-- Winner cohort: net-long retail/mid on any seed token in that window
winners AS (
    SELECT taker
    FROM (
        SELECT
            t.taker,
            SUM(CASE WHEN t.token_bought_address IN (SELECT token_address FROM seed_tokens) THEN t.amount_usd ELSE 0 END) AS buy_usd,
            SUM(CASE WHEN t.token_sold_address IN (SELECT token_address FROM seed_tokens) THEN t.amount_usd ELSE 0 END) AS sell_usd
        FROM dex.trades t
        WHERE t.blockchain = 'robinhood'
          AND t.block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '20' DAY)
          AND t.block_time >= CURRENT_DATE - INTERVAL '14' DAY
          AND t.block_time < CURRENT_DATE - INTERVAL '2' DAY
          AND t.amount_usd > 0 AND t.taker IS NOT NULL
          AND (
              t.token_bought_address IN (SELECT token_address FROM seed_tokens)
              OR t.token_sold_address IN (SELECT token_address FROM seed_tokens)
          )
        GROUP BY 1
    ) x
    WHERE buy_usd > sell_usd
      AND buy_usd BETWEEN 50 AND 25000
),
-- Target candidates: yesterday's active memes (vol >= $100k)
candidates AS (
    SELECT token_address FROM (
        SELECT
            CASE
                WHEN token_bought_address NOT IN (SELECT contract_address FROM excluded)
                 AND token_bought_address != 0x0000000000000000000000000000000000000000
                THEN token_bought_address ELSE token_sold_address
            END AS token_address,
            SUM(amount_usd) AS vol
        FROM dex.trades
        WHERE blockchain = 'robinhood'
          AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3' DAY)
          AND block_time >= CURRENT_DATE - INTERVAL '1' DAY
          AND block_time < CURRENT_DATE
          AND amount_usd > 0
        GROUP BY 1
        HAVING SUM(amount_usd) >= 100000
        ORDER BY 2 DESC
        LIMIT 20
    ) c
    WHERE token_address NOT IN (SELECT contract_address FROM excluded)
      AND token_address NOT IN (SELECT token_address FROM seed_tokens)
),
target_trades AS (
    SELECT
        CASE
            WHEN t.token_bought_address IN (SELECT token_address FROM candidates) THEN t.token_bought_address
            ELSE t.token_sold_address
        END AS token_address,
        t.taker,
        t.amount_usd,
        CASE
            WHEN t.token_bought_address IN (SELECT token_address FROM candidates) THEN 'buy'
            ELSE 'sell'
        END AS side
    FROM dex.trades t
    WHERE t.blockchain = 'robinhood'
      AND t.block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3' DAY)
      AND t.block_time >= CURRENT_DATE - INTERVAL '1' DAY
      AND t.block_time < CURRENT_DATE
      AND t.amount_usd > 0 AND t.taker IS NOT NULL
      AND (
          t.token_bought_address IN (SELECT token_address FROM candidates)
          OR t.token_sold_address IN (SELECT token_address FROM candidates)
      )
)
SELECT
    COALESCE(tk.symbol, CAST(tt.token_address AS varchar)) AS symbol,
    tt.token_address,
    COUNT(DISTINCT tt.taker) AS all_traders,
    COUNT(DISTINCT CASE WHEN w.taker IS NOT NULL THEN tt.taker END) AS winner_traders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN w.taker IS NOT NULL THEN tt.taker END)
        / NULLIF(COUNT(DISTINCT tt.taker), 0), 2) AS winner_trader_pct,
    ROUND(SUM(CASE WHEN tt.side = 'buy' THEN tt.amount_usd ELSE 0 END), 0) AS buy_usd,
    ROUND(SUM(CASE WHEN tt.side = 'buy' AND w.taker IS NOT NULL THEN tt.amount_usd ELSE 0 END), 0) AS winner_buy_usd,
    ROUND(100.0 * SUM(CASE WHEN tt.side = 'buy' AND w.taker IS NOT NULL THEN tt.amount_usd ELSE 0 END)
        / NULLIF(SUM(CASE WHEN tt.side = 'buy' THEN tt.amount_usd ELSE 0 END), 0), 2) AS winner_buy_pct,
    ROUND(SUM(CASE WHEN tt.side = 'buy' THEN tt.amount_usd ELSE 0 END)
        - SUM(CASE WHEN tt.side = 'sell' THEN tt.amount_usd ELSE 0 END), 0) AS net_usd,
    (SELECT COUNT(*) FROM winners) AS cohort_size,
    CASE
        WHEN ROUND(100.0 * SUM(CASE WHEN tt.side = 'buy' AND w.taker IS NOT NULL THEN tt.amount_usd ELSE 0 END)
            / NULLIF(SUM(CASE WHEN tt.side = 'buy' THEN tt.amount_usd ELSE 0 END), 0), 2) >= 12
         AND ROUND(100.0 * COUNT(DISTINCT CASE WHEN w.taker IS NOT NULL THEN tt.taker END)
            / NULLIF(COUNT(DISTINCT tt.taker), 0), 2) >= 6
        THEN 'COHORT_HOT'
        WHEN ROUND(100.0 * SUM(CASE WHEN tt.side = 'buy' AND w.taker IS NOT NULL THEN tt.amount_usd ELSE 0 END)
            / NULLIF(SUM(CASE WHEN tt.side = 'buy' THEN tt.amount_usd ELSE 0 END), 0), 2) >= 8
        THEN 'COHORT_WARM'
        ELSE 'COHORT_COLD'
    END AS cohort_label
FROM target_trades tt
LEFT JOIN winners w ON tt.taker = w.taker
LEFT JOIN tokens.erc20 tk
  ON tk.blockchain = 'robinhood' AND tk.contract_address = tt.token_address
GROUP BY 1, 2
ORDER BY winner_buy_pct DESC NULLS LAST
LIMIT 20

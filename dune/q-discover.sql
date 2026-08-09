-- Q-DISCOVER: Top Robinhood Chain tokens by 24h DEX volume + age
-- Used by: daily scanner Phase 1 (discovery)
-- Partition: block_month on dex.trades

WITH excluded AS (
    SELECT addr FROM (VALUES
        (0x0000000000000000000000000000000000000000),
        (0x4200000000000000000000000000000000000006)  -- WETH
    ) AS t(addr)
),
trades AS (
    SELECT
        block_time,
        taker,
        amount_usd,
        token_bought_address,
        token_sold_address
    FROM dex.trades
    WHERE blockchain = 'robinhood'
      AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '90' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '30' DAY
      AND amount_usd > 0
      AND taker IS NOT NULL
),
token_side AS (
    SELECT block_time, taker, amount_usd, token_bought_address AS token_address, 'buy' AS side
    FROM trades
    WHERE token_bought_address IS NOT NULL
    UNION ALL
    SELECT block_time, taker, amount_usd, token_sold_address AS token_address, 'sell' AS side
    FROM trades
    WHERE token_sold_address IS NOT NULL
),
meta AS (
    SELECT contract_address, MAX(symbol) AS symbol, MAX(name) AS name
    FROM tokens.erc20
    WHERE blockchain = 'robinhood'
    GROUP BY 1
),
filtered AS (
    SELECT ts.*
    FROM token_side ts
    LEFT JOIN meta m ON ts.token_address = m.contract_address
    WHERE COALESCE(m.symbol, '') NOT IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
      AND COALESCE(LOWER(m.name), '') NOT LIKE '%wrapped ether%'
      AND ts.token_address NOT IN (SELECT addr FROM excluded)
),
daily AS (
    SELECT
        token_address,
        DATE_TRUNC('day', block_time) AS day,
        SUM(amount_usd) AS vol_usd,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        COUNT(DISTINCT taker) AS traders
    FROM filtered
    GROUP BY 1, 2
),
agg AS (
    SELECT
        token_address,
        MIN(day) AS first_trade_day,
        DATE_DIFF('day', MIN(day), CURRENT_DATE) AS token_age_days,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN vol_usd ELSE 0 END) AS vol_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '7' DAY THEN vol_usd ELSE 0 END) AS vol_7d,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN traders ELSE 0 END) AS traders_24h
    FROM daily
    GROUP BY 1
)
SELECT
    a.token_address,
    m.symbol,
    m.name,
    a.token_age_days,
    a.first_trade_day,
    a.vol_24h,
    a.vol_7d,
    a.net_24h,
    a.traders_24h,
    RANK() OVER (ORDER BY a.vol_24h DESC) AS vol_rank_24h
FROM agg a
LEFT JOIN meta m ON a.token_address = m.contract_address
WHERE a.vol_24h >= 50000
ORDER BY a.vol_24h DESC
LIMIT 30

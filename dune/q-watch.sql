-- Q-WATCH: Deep dive for watchlist tokens (default: CASHCAT)
-- Parameter: watchlist addresses (comma-separated 0x... in {{watchlist}})

WITH watchlist AS (
    SELECT DISTINCT CAST(TRIM(addr) AS varbinary) AS token_address
    FROM UNNEST(SPLIT({{watchlist}}, ',')) AS t(addr)
    WHERE TRIM(addr) != ''
),
trades AS (
    SELECT
        block_time,
        taker,
        amount_usd,
        CASE
            WHEN token_bought_address IN (SELECT token_address FROM watchlist) THEN token_bought_address
            ELSE token_sold_address
        END AS token_address,
        CASE
            WHEN token_bought_address IN (SELECT token_address FROM watchlist) THEN 'buy'
            ELSE 'sell'
        END AS side,
        CASE
            WHEN token_bought_address IN (SELECT token_address FROM watchlist) THEN token_bought_amount
            ELSE token_sold_amount
        END AS token_amt
    FROM dex.trades
    WHERE blockchain = 'robinhood'
      AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '90' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
      AND amount_usd > 0
      AND taker IS NOT NULL
      AND (
          token_bought_address IN (SELECT token_address FROM watchlist)
          OR token_sold_address IN (SELECT token_address FROM watchlist)
      )
),
daily AS (
    SELECT
        token_address,
        DATE_TRUNC('day', block_time) AS day,
        SUM(amount_usd) AS vol_usd,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        COUNT(DISTINCT taker) AS traders,
        approx_percentile(amount_usd / NULLIF(token_amt, 0), 0.5) AS median_price
    FROM trades
    GROUP BY 1, 2
),
summary AS (
    SELECT
        token_address,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN vol_usd ELSE 0 END) AS vol_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '2' DAY THEN vol_usd ELSE 0 END) AS vol_48h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '2' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_48h,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '1' DAY THEN median_price END) AS median_price_24h
    FROM daily
    GROUP BY 1
),
holders AS (
    SELECT
        contract_address AS token_address,
        COUNT(DISTINCT "to") AS receivers_7d
    FROM tokens.transfers
    WHERE blockchain = 'robinhood'
      AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
      AND contract_address IN (SELECT token_address FROM watchlist)
      AND "to" IS NOT NULL
    GROUP BY 1
),
meta AS (
    SELECT contract_address, MAX(symbol) AS symbol, MAX(name) AS name
    FROM tokens.erc20 WHERE blockchain = 'robinhood'
    GROUP BY 1
)
SELECT
    'daily' AS section,
    d.token_address,
    m.symbol,
    CAST(d.day AS varchar) AS k,
    d.vol_usd,
    d.buy_usd,
    d.sell_usd,
    d.buy_usd - d.sell_usd AS net_usd,
    d.traders,
    d.median_price,
    NULL AS vol_24h,
    NULL AS net_24h
FROM daily d
LEFT JOIN meta m ON d.token_address = m.contract_address
UNION ALL
SELECT
    'summary' AS section,
    s.token_address,
    m.symbol,
    'summary' AS k,
    NULL, NULL, NULL,
    s.net_48h AS net_usd,
    h.receivers_7d AS traders,
    s.median_price_24h AS median_price,
    s.vol_24h,
    s.net_24h
FROM summary s
LEFT JOIN meta m ON s.token_address = m.contract_address
LEFT JOIN holders h ON s.token_address = h.token_address
ORDER BY section, token_address, k

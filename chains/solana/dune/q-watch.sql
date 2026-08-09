-- Q-WATCH: Solana watchlist deep dive (parameter: {{watchlist}} comma-separated mints)
WITH watchlist AS (
    -- Base58 mints must be string-quoted; CAST({{watchlist}} AS varchar) is treated as an identifier
    SELECT DISTINCT trim(addr) AS mint
    FROM UNNEST(SPLIT('{{watchlist}}', ',')) AS t(addr)
    WHERE trim(addr) != ''
),
trades AS (
    SELECT block_time, trader_id, amount_usd,
        CASE WHEN token_bought_mint_address IN (SELECT mint FROM watchlist) THEN token_bought_mint_address ELSE token_sold_mint_address END AS mint,
        CASE WHEN token_bought_mint_address IN (SELECT mint FROM watchlist) THEN 'buy' ELSE 'sell' END AS side,
        CASE WHEN token_bought_mint_address IN (SELECT mint FROM watchlist) THEN token_bought_amount ELSE token_sold_amount END AS token_amt
    FROM dex_solana.trades
    WHERE block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND block_date >= CURRENT_DATE - INTERVAL '7' DAY
      AND amount_usd > 0 AND trader_id IS NOT NULL
      AND (token_bought_mint_address IN (SELECT mint FROM watchlist) OR token_sold_mint_address IN (SELECT mint FROM watchlist))
),
daily AS (
    SELECT mint, DATE_TRUNC('day', block_time) AS day,
        SUM(amount_usd) AS vol_usd,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        COUNT(DISTINCT trader_id) AS traders,
        approx_percentile(amount_usd / NULLIF(token_amt, 0), 0.5) AS median_price
    FROM trades GROUP BY 1, 2
),
summary AS (
    SELECT mint,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN vol_usd ELSE 0 END) AS vol_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '2' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_48h,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '1' DAY THEN median_price END) AS median_price_24h
    FROM daily GROUP BY 1
)
SELECT 'daily' AS section, d.mint, CAST(d.day AS varchar) AS k,
    d.vol_usd, d.buy_usd, d.sell_usd, d.buy_usd - d.sell_usd AS net_usd, d.traders, d.median_price,
    NULL AS vol_24h, NULL AS net_24h
FROM daily d
UNION ALL
SELECT 'summary', s.mint, 'summary', NULL, NULL, NULL, s.net_48h, NULL, s.median_price_24h, s.vol_24h, s.net_24h
FROM summary s
ORDER BY section, mint, k

-- Q-DISCOVER: Top Solana tokens by 24h DEX volume (dex_solana.trades)
WITH excluded AS (
    SELECT mint FROM (VALUES
        ('So11111111111111111111111111111111111111112'),
        ('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'),
        ('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
    ) AS t(mint)
),
trades AS (
    SELECT block_time, trader_id, amount_usd,
        token_bought_mint_address, token_sold_mint_address,
        token_bought_symbol, token_sold_symbol, project
    FROM dex_solana.trades
    WHERE block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND block_date >= CURRENT_DATE - INTERVAL '14' DAY
      AND amount_usd > 0 AND trader_id IS NOT NULL
),
token_side AS (
    SELECT block_time, trader_id, amount_usd,
        token_bought_mint_address AS mint, token_bought_symbol AS symbol, 'buy' AS side, project
    FROM trades WHERE token_bought_mint_address IS NOT NULL
    UNION ALL
    SELECT block_time, trader_id, amount_usd,
        token_sold_mint_address, token_sold_symbol, 'sell', project
    FROM trades WHERE token_sold_mint_address IS NOT NULL
),
filtered AS (
    SELECT * FROM token_side
    WHERE mint NOT IN (SELECT mint FROM excluded)
      AND COALESCE(symbol, '') NOT IN ('SOL','WSOL','USDC','USDT','USD1','USDG','JupUSD','WETH','cbBTC','mSOL','JitoSOL','PUMP')
      AND COALESCE(symbol, '') NOT LIKE 'USD%'
),
daily AS (
    SELECT mint, MAX(symbol) AS symbol, DATE_TRUNC('day', block_time) AS day,
        SUM(amount_usd) AS vol_usd,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        COUNT(DISTINCT trader_id) AS traders
    FROM filtered GROUP BY 1, 3
),
agg AS (
    SELECT mint, MAX(symbol) AS symbol,
        MIN(day) AS first_trade_day,
        DATE_DIFF('day', MIN(day), CURRENT_DATE) AS token_age_days,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN vol_usd ELSE 0 END) AS vol_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '7' DAY THEN vol_usd ELSE 0 END) AS vol_7d,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN buy_usd - sell_usd ELSE 0 END) AS net_24h,
        SUM(CASE WHEN day >= CURRENT_DATE - INTERVAL '1' DAY THEN traders ELSE 0 END) AS traders_24h,
        MAX(CASE WHEN mint LIKE '%pump' THEN 1 ELSE 0 END) AS is_pump_mint
    FROM daily GROUP BY 1
)
SELECT mint, symbol, token_age_days, first_trade_day, vol_24h, vol_7d, net_24h, traders_24h,
    is_pump_mint, RANK() OVER (ORDER BY vol_24h DESC) AS vol_rank_24h
FROM agg
WHERE vol_24h >= 250000
ORDER BY vol_24h DESC
LIMIT 30

-- Q-REACTIVATE: Solana old-token reactivation (age >= 7d on SOL — faster cycle than RH)
WITH excluded AS (
    SELECT mint FROM (VALUES
        ('So11111111111111111111111111111111111111112'),
        ('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'),
        ('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
    ) AS t(mint)
),
trades AS (
    SELECT block_time, trader_id, amount_usd, token_bought_mint_address, token_sold_mint_address,
        token_bought_symbol, token_sold_symbol
    FROM dex_solana.trades
    WHERE block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND block_date >= CURRENT_DATE - INTERVAL '14' DAY
      AND amount_usd > 0 AND trader_id IS NOT NULL
),
token_side AS (
    SELECT block_time, trader_id, amount_usd, token_bought_mint_address AS mint, token_bought_symbol AS symbol, 'buy' AS side
    FROM trades WHERE token_bought_mint_address IS NOT NULL
    UNION ALL
    SELECT block_time, trader_id, amount_usd, token_sold_mint_address, token_sold_symbol, 'sell'
    FROM trades WHERE token_sold_mint_address IS NOT NULL
),
filtered AS (
    SELECT * FROM token_side
    WHERE mint NOT IN (SELECT mint FROM excluded)
      AND COALESCE(symbol, '') NOT IN ('SOL','WSOL','USDC','USDT','USD1','USDG','JupUSD','WETH','cbBTC','mSOL','PUMP')
),
daily AS (
    SELECT mint, MAX(symbol) AS symbol, DATE_TRUNC('day', block_time) AS day,
        SUM(amount_usd) AS vol_usd,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        COUNT(DISTINCT trader_id) AS traders
    FROM filtered GROUP BY 1, 3
),
first_seen AS (SELECT mint, MIN(day) AS first_day FROM daily GROUP BY 1),
metrics AS (
    SELECT d.mint, MAX(d.symbol) AS symbol,
        DATE_DIFF('day', f.first_day, CURRENT_DATE) AS token_age_days,
        MAX(CASE WHEN d.day = CURRENT_DATE - INTERVAL '1' DAY THEN d.vol_usd END) AS vol_yesterday,
        AVG(CASE WHEN d.day BETWEEN CURRENT_DATE - INTERVAL '8' DAY AND CURRENT_DATE - INTERVAL '2' DAY THEN d.vol_usd END) AS vol_7d_avg_prior,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '1' DAY THEN d.buy_usd - d.sell_usd END) AS net_yesterday,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '2' DAY THEN d.buy_usd - d.sell_usd END) AS net_2d_ago,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '3' DAY THEN d.buy_usd - d.sell_usd END) AS net_3d_ago,
        MAX(CASE WHEN d.day = CURRENT_DATE - INTERVAL '1' DAY THEN d.traders END) AS traders_yesterday
    FROM daily d JOIN first_seen f ON d.mint = f.mint GROUP BY d.mint, f.first_day
),
chain_vol AS (SELECT day, SUM(vol_usd) AS chain_vol FROM daily GROUP BY 1),
token_share AS (
    SELECT d.mint, d.day, d.vol_usd / NULLIF(cv.chain_vol, 0) AS chain_share
    FROM daily d JOIN chain_vol cv ON d.day = cv.day
),
share_trend AS (
    SELECT mint,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '1' DAY THEN chain_share END) AS share_yesterday,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '2' DAY THEN chain_share END) AS share_2d_ago
    FROM token_share GROUP BY 1
)
SELECT m.mint, m.symbol, m.token_age_days, m.vol_yesterday, m.vol_7d_avg_prior,
    CASE WHEN m.vol_7d_avg_prior > 0 THEN m.vol_yesterday / m.vol_7d_avg_prior END AS vol_accel,
    m.net_yesterday, m.net_2d_ago, m.net_3d_ago, m.traders_yesterday,
    st.share_yesterday, st.share_2d_ago,
    CASE WHEN m.mint LIKE '%pump' THEN 1 ELSE 0 END AS is_pump_mint,
    CASE WHEN m.token_age_days >= 7 AND m.vol_7d_avg_prior > 0
          AND m.vol_yesterday / m.vol_7d_avg_prior >= 3
          AND m.net_yesterday > 0 AND m.net_2d_ago > 0 THEN 1 ELSE 0 END AS reactivation_core
FROM metrics m
LEFT JOIN share_trend st ON m.mint = st.mint
WHERE m.token_age_days >= 7 AND m.vol_yesterday >= 250000
ORDER BY vol_accel DESC NULLS LAST
LIMIT 25

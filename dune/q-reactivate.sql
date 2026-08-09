-- Q-REACTIVATE: Old-token reactivation signals (CASHCAT Aug 3-5 pattern)
-- Tokens age >= 14d with vol acceleration, net-buy streak, holder growth

WITH excluded AS (
    SELECT contract_address FROM tokens.erc20
    WHERE blockchain = 'robinhood'
      AND symbol IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
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
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '14' DAY
      AND amount_usd > 0
      AND taker IS NOT NULL
),
token_side AS (
    SELECT block_time, taker, amount_usd, token_bought_address AS token_address, 'buy' AS side
    FROM trades WHERE token_bought_address IS NOT NULL
    UNION ALL
    SELECT block_time, taker, amount_usd, token_sold_address AS token_address, 'sell' AS side
    FROM trades WHERE token_sold_address IS NOT NULL
),
filtered AS (
    SELECT * FROM token_side
    WHERE token_address NOT IN (SELECT contract_address FROM excluded)
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
first_seen AS (
    SELECT token_address, MIN(day) AS first_day
    FROM daily
    GROUP BY 1
),
metrics AS (
    SELECT
        d.token_address,
        DATE_DIFF('day', f.first_day, CURRENT_DATE) AS token_age_days,
        MAX(CASE WHEN d.day = CURRENT_DATE - INTERVAL '1' DAY THEN d.vol_usd END) AS vol_yesterday,
        AVG(CASE WHEN d.day BETWEEN CURRENT_DATE - INTERVAL '8' DAY AND CURRENT_DATE - INTERVAL '2' DAY
            THEN d.vol_usd END) AS vol_7d_avg_prior,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '1' DAY THEN d.buy_usd - d.sell_usd END) AS net_yesterday,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '2' DAY THEN d.buy_usd - d.sell_usd END) AS net_2d_ago,
        SUM(CASE WHEN d.day = CURRENT_DATE - INTERVAL '3' DAY THEN d.buy_usd - d.sell_usd END) AS net_3d_ago,
        SUM(CASE WHEN d.day >= CURRENT_DATE - INTERVAL '3' DAY THEN d.vol_usd END) AS vol_3d,
        SUM(CASE WHEN d.day BETWEEN CURRENT_DATE - INTERVAL '6' DAY AND CURRENT_DATE - INTERVAL '4' DAY
            THEN d.vol_usd END) AS vol_prior_3d
    FROM daily d
    JOIN first_seen f ON d.token_address = f.token_address
    GROUP BY 1, f.first_day
),
holders AS (
    SELECT
        contract_address AS token_address,
        DATE_TRUNC('day', block_time) AS day,
        COUNT(DISTINCT "to") AS new_receivers
    FROM tokens.transfers
    WHERE blockchain = 'robinhood'
      AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '90' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '7' DAY
      AND "to" IS NOT NULL
    GROUP BY 1, 2
),
holder_slope AS (
    SELECT
        token_address,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '1' DAY THEN new_receivers END) AS holders_d1,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '2' DAY THEN new_receivers END) AS holders_d2,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '3' DAY THEN new_receivers END) AS holders_d3
    FROM holders
    GROUP BY 1
),
chain_vol AS (
    SELECT day, SUM(vol_usd) AS chain_vol
    FROM daily
    GROUP BY 1
),
token_share AS (
    SELECT
        d.token_address,
        d.day,
        d.vol_usd / NULLIF(cv.chain_vol, 0) AS chain_share
    FROM daily d
    JOIN chain_vol cv ON d.day = cv.day
),
share_trend AS (
    SELECT
        token_address,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '1' DAY THEN chain_share END) AS share_yesterday,
        MAX(CASE WHEN day = CURRENT_DATE - INTERVAL '2' DAY THEN chain_share END) AS share_2d_ago
    FROM token_share
    GROUP BY 1
),
meta AS (
    SELECT contract_address, MAX(symbol) AS symbol
    FROM tokens.erc20 WHERE blockchain = 'robinhood'
    GROUP BY 1
)
SELECT
    m.token_address,
    meta.symbol,
    m.token_age_days,
    m.vol_yesterday,
    m.vol_7d_avg_prior,
    CASE WHEN m.vol_7d_avg_prior > 0 THEN m.vol_yesterday / m.vol_7d_avg_prior ELSE NULL END AS vol_accel,
    m.net_yesterday,
    m.net_2d_ago,
    m.net_3d_ago,
    h.holders_d1,
    h.holders_d2,
    h.holders_d3,
    st.share_yesterday,
    st.share_2d_ago,
    CASE WHEN m.vol_prior_3d > 0 THEN m.vol_3d / m.vol_prior_3d ELSE NULL END AS vol_3d_vs_prior,
    CASE WHEN m.token_age_days >= 14
          AND m.vol_7d_avg_prior > 0
          AND m.vol_yesterday / m.vol_7d_avg_prior >= 3
          AND m.net_yesterday > 0 AND m.net_2d_ago > 0
        THEN 1 ELSE 0 END AS reactivation_core
FROM metrics m
LEFT JOIN holder_slope h ON m.token_address = h.token_address
LEFT JOIN share_trend st ON m.token_address = st.token_address
LEFT JOIN meta ON m.token_address = meta.contract_address
WHERE m.token_age_days >= 14
  AND m.vol_yesterday >= 100000
ORDER BY vol_accel DESC NULLS LAST
LIMIT 25

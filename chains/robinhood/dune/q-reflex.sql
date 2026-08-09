-- Q-REFLEX: Microstructure reflexivity score for top RH Chain tokens (yesterday)
-- Signals: absorption, first-time buyers, add-on rate, buy-burst, net flow
-- See core/scoring/REFLEX.md

WITH excluded AS (
    SELECT contract_address FROM tokens.erc20
    WHERE blockchain = 'robinhood'
      AND symbol IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
),
top_tokens AS (
    SELECT token_address FROM (
        SELECT
            CASE WHEN token_bought_address IS NOT NULL THEN token_bought_address ELSE token_sold_address END AS token_address,
            SUM(amount_usd) AS vol
        FROM dex.trades
        WHERE blockchain = 'robinhood'
          AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
          AND block_time >= CURRENT_DATE - INTERVAL '1' DAY
          AND block_time < CURRENT_DATE
          AND amount_usd > 0
        GROUP BY 1
        HAVING SUM(amount_usd) >= 100000
        ORDER BY 2 DESC
        LIMIT 20
    ) t
    WHERE token_address NOT IN (SELECT contract_address FROM excluded)
      AND token_address != 0x0000000000000000000000000000000000000000
),
trades AS (
    SELECT
        t.block_time,
        t.taker,
        t.amount_usd,
        CASE
            WHEN t.token_bought_address IN (SELECT token_address FROM top_tokens) THEN t.token_bought_address
            ELSE t.token_sold_address
        END AS token_address,
        CASE
            WHEN t.token_bought_address IN (SELECT token_address FROM top_tokens) THEN 'buy'
            ELSE 'sell'
        END AS side
    FROM dex.trades t
    WHERE t.blockchain = 'robinhood'
      AND t.block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND t.block_time >= CURRENT_DATE - INTERVAL '3' DAY
      AND t.block_time < CURRENT_DATE
      AND t.amount_usd > 0
      AND t.taker IS NOT NULL
      AND (
          t.token_bought_address IN (SELECT token_address FROM top_tokens)
          OR t.token_sold_address IN (SELECT token_address FROM top_tokens)
      )
),
labeled AS (
    SELECT
        block_time, taker, amount_usd, token_address, side,
        DATE_TRUNC('day', block_time) AS day,
        DATE_TRUNC('hour', block_time) AS hour,
        CASE
            WHEN amount_usd < 1000 THEN 'retail'
            WHEN amount_usd < 10000 THEN 'mid'
            ELSE 'whale'
        END AS bucket
    FROM trades
),
target_day AS (
    SELECT CAST(CURRENT_DATE - INTERVAL '1' DAY AS timestamp) AS day
),
hourly_buys AS (
    SELECT token_address, day, hour,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd
    FROM labeled
    WHERE day = (SELECT day FROM target_day)
    GROUP BY 1, 2, 3
),
daily_buy_tot AS (
    SELECT token_address, day, SUM(buy_usd) AS day_buy
    FROM hourly_buys GROUP BY 1, 2
),
burst AS (
    SELECT h.token_address, h.day,
        MAX(h.buy_usd / NULLIF(d.day_buy, 0)) AS max_2h_buy_share
    FROM (
        SELECT a.token_address, a.day, a.hour,
            a.buy_usd + COALESCE(b.buy_usd, 0) AS buy_usd
        FROM hourly_buys a
        LEFT JOIN hourly_buys b
          ON a.token_address = b.token_address
         AND a.day = b.day
         AND b.hour = a.hour + INTERVAL '1' HOUR
    ) h
    JOIN daily_buy_tot d ON h.token_address = d.token_address AND h.day = d.day
    GROUP BY 1, 2
),
first_trade AS (
    SELECT token_address, taker, MIN(block_time) AS first_t
    FROM labeled
    GROUP BY 1, 2
),
daily AS (
    SELECT
        l.token_address,
        l.day,
        SUM(l.amount_usd) AS vol,
        SUM(CASE WHEN l.side = 'buy' THEN l.amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN l.side = 'sell' THEN l.amount_usd ELSE 0 END) AS sell_usd,
        SUM(CASE WHEN l.side = 'buy' AND l.bucket = 'retail' THEN l.amount_usd ELSE 0 END) AS retail_buy,
        SUM(CASE WHEN l.side = 'sell' AND l.bucket = 'whale' THEN l.amount_usd ELSE 0 END) AS whale_sell,
        COUNT(DISTINCT l.taker) AS traders,
        COUNT(DISTINCT CASE
            WHEN l.side = 'buy'
             AND ft.first_t >= l.day
             AND ft.first_t < l.day + INTERVAL '1' DAY
            THEN l.taker END) AS first_time_buyers,
        approx_percentile(CASE
            WHEN l.side = 'buy'
             AND ft.first_t >= l.day
             AND ft.first_t < l.day + INTERVAL '1' DAY
            THEN l.amount_usd END, 0.5) AS median_first_buy
    FROM labeled l
    LEFT JOIN first_trade ft
      ON l.token_address = ft.token_address AND l.taker = ft.taker
    WHERE l.day = (SELECT day FROM target_day)
    GROUP BY 1, 2
),
wallet_day AS (
    SELECT token_address, day, taker,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd
    FROM labeled
    WHERE day >= (SELECT day FROM target_day) - INTERVAL '1' DAY
    GROUP BY 1, 2, 3
),
addon AS (
    SELECT
        w1.token_address,
        w1.day,
        COUNT(DISTINCT CASE
            WHEN w1.buy_usd > 0 AND w0.buy_usd > 0 AND w1.buy_usd > w1.sell_usd
            THEN w1.taker END) * 1.0
          / NULLIF(COUNT(DISTINCT CASE WHEN w1.buy_usd > 0 THEN w1.taker END), 0) AS addon_rate
    FROM wallet_day w1
    LEFT JOIN wallet_day w0
      ON w1.token_address = w0.token_address
     AND w1.taker = w0.taker
     AND w0.day = w1.day - INTERVAL '1' DAY
    WHERE w1.day = (SELECT day FROM target_day)
    GROUP BY 1, 2
),
meta AS (
    SELECT contract_address, MAX(symbol) AS symbol
    FROM tokens.erc20 WHERE blockchain = 'robinhood'
    GROUP BY 1
),
scored AS (
    SELECT
        d.token_address,
        m.symbol,
        d.day,
        d.vol,
        d.buy_usd - d.sell_usd AS net_usd,
        d.retail_buy / NULLIF(d.whale_sell, 0) AS absorption_ratio,
        d.first_time_buyers,
        d.median_first_buy,
        a.addon_rate,
        b.max_2h_buy_share AS buy_burst_share,
        d.retail_buy / NULLIF(d.buy_usd, 0) AS retail_buy_share,
        d.traders,
        (CASE WHEN d.retail_buy / NULLIF(d.whale_sell, 0) >= 1.2 THEN 25
              WHEN d.retail_buy / NULLIF(d.whale_sell, 0) >= 0.8 THEN 15 ELSE 0 END)
      + (CASE WHEN d.first_time_buyers >= 1500 THEN 20
              WHEN d.first_time_buyers >= 800 THEN 12 ELSE 0 END)
      + (CASE WHEN a.addon_rate >= 0.15 THEN 20
              WHEN a.addon_rate >= 0.08 THEN 10 ELSE 0 END)
      + (CASE WHEN b.max_2h_buy_share >= 0.35 THEN 15
              WHEN b.max_2h_buy_share >= 0.25 THEN 8 ELSE 0 END)
      + (CASE WHEN (d.buy_usd - d.sell_usd) > 0 THEN 20
              WHEN (d.buy_usd - d.sell_usd) > -500000 THEN 8 ELSE 0 END)
        AS reflex_score
    FROM daily d
    LEFT JOIN addon a ON d.token_address = a.token_address AND d.day = a.day
    LEFT JOIN burst b ON d.token_address = b.token_address AND d.day = b.day
    LEFT JOIN meta m ON d.token_address = m.contract_address
)
SELECT
    token_address,
    symbol,
    CAST(day AS varchar) AS day,
    vol,
    net_usd,
    absorption_ratio,
    first_time_buyers,
    median_first_buy,
    addon_rate,
    buy_burst_share,
    retail_buy_share,
    traders,
    reflex_score,
    CASE
        WHEN reflex_score >= 80 THEN 'IGNITION'
        WHEN reflex_score >= 65 THEN 'WARMING'
        WHEN reflex_score >= 50 THEN 'MIXED'
        ELSE 'COLD'
    END AS reflex_label
FROM scored
ORDER BY reflex_score DESC, vol DESC
LIMIT 25

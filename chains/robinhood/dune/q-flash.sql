-- Q-FLASH: Hourly microstructure for sudden launches (fixes daily-RX flash misses)
-- Validated: GME FLASH_HOT at Jul 22 21:00 — day before peak Jul 23
-- See core/scoring/FLASH.md

WITH excluded AS (
    SELECT contract_address FROM tokens.erc20
    WHERE blockchain = 'robinhood'
      AND symbol IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
),
windowed AS (
    SELECT
        CASE
            WHEN t.token_bought_address NOT IN (SELECT contract_address FROM excluded)
             AND t.token_bought_address != 0x0000000000000000000000000000000000000000
            THEN t.token_bought_address
            ELSE t.token_sold_address
        END AS token_address,
        DATE_TRUNC('hour', t.block_time) AS hour,
        t.taker,
        t.amount_usd,
        CASE
            WHEN t.token_bought_address NOT IN (SELECT contract_address FROM excluded)
             AND t.token_bought_address != 0x0000000000000000000000000000000000000000
            THEN 'buy' ELSE 'sell'
        END AS side,
        CASE
            WHEN t.amount_usd < 1000 THEN 'retail'
            WHEN t.amount_usd < 10000 THEN 'mid'
            ELSE 'whale'
        END AS bucket
    FROM dex.trades t
    WHERE t.blockchain = 'robinhood'
      AND t.block_month >= DATE_TRUNC('month', CURRENT_TIMESTAMP - INTERVAL '2' DAY)
      AND t.block_time >= CURRENT_TIMESTAMP - INTERVAL '12' HOUR
      AND t.amount_usd > 0
      AND t.taker IS NOT NULL
),
hourly AS (
    SELECT
        token_address,
        hour,
        SUM(amount_usd) AS vol,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        SUM(CASE WHEN side = 'buy' AND bucket = 'retail' THEN amount_usd ELSE 0 END) AS retail_buy,
        SUM(CASE WHEN side = 'sell' AND bucket = 'whale' THEN amount_usd ELSE 0 END) AS whale_sell,
        COUNT(DISTINCT CASE WHEN side = 'buy' THEN taker END) AS buyers
    FROM windowed
    WHERE token_address NOT IN (SELECT contract_address FROM excluded)
      AND token_address != 0x0000000000000000000000000000000000000000
    GROUP BY 1, 2
),
labeled AS (
    SELECT
        h.*,
        h.buy_usd - h.sell_usd AS net,
        h.retail_buy / NULLIF(h.whale_sell, 0) AS absorp,
        CASE
            WHEN (h.buy_usd - h.sell_usd) > 0
             AND COALESCE(h.retail_buy / NULLIF(h.whale_sell, 0), 99) >= 1.5
             AND h.buyers >= 20
             AND h.vol >= 50000
            THEN 'FLASH_HOT'
            WHEN (h.buy_usd - h.sell_usd) > 0
             AND h.buyers >= 15
             AND h.vol >= 25000
            THEN 'FLASH_WARM'
            ELSE 'COLD'
        END AS flash_label
    FROM hourly h
    WHERE h.vol >= 10000
),
agg AS (
    SELECT
        token_address,
        COUNT(*) AS active_hours,
        COUNT(CASE WHEN flash_label = 'FLASH_HOT' THEN 1 END) AS hot_hours,
        COUNT(CASE WHEN flash_label = 'FLASH_WARM' THEN 1 END) AS warm_hours,
        MAX(vol) AS max_hour_vol,
        SUM(vol) AS vol_12h,
        SUM(net) AS net_12h,
        MAX_BY(flash_label, hour) AS latest_label,
        MAX_BY(net, hour) AS latest_net,
        MAX_BY(absorp, hour) AS latest_absorp,
        MAX_BY(buyers, hour) AS latest_buyers,
        MAX(hour) AS latest_hour
    FROM labeled
    GROUP BY 1
)
SELECT
    COALESCE(tk.symbol, CAST(a.token_address AS varchar)) AS symbol,
    a.token_address,
    a.active_hours,
    a.hot_hours,
    a.warm_hours,
    ROUND(a.max_hour_vol, 0) AS max_hour_vol,
    ROUND(a.vol_12h, 0) AS vol_12h,
    ROUND(a.net_12h, 0) AS net_12h,
    a.latest_label,
    ROUND(a.latest_net, 0) AS latest_net,
    ROUND(a.latest_absorp, 2) AS latest_absorp,
    a.latest_buyers,
    a.latest_hour,
    CASE
        WHEN a.hot_hours >= 2 OR (a.hot_hours >= 1 AND a.latest_label = 'FLASH_HOT') THEN 'FLASH_IGNITION'
        WHEN a.hot_hours + a.warm_hours >= 2 OR a.latest_label IN ('FLASH_HOT', 'FLASH_WARM') THEN 'FLASH_WATCH'
        ELSE 'FLASH_COLD'
    END AS flash_band,
    -- score: prioritize sustained hot hours + recent hot + size
    LEAST(100,
        a.hot_hours * 30
        + a.warm_hours * 10
        + CASE WHEN a.latest_label = 'FLASH_HOT' THEN 25 WHEN a.latest_label = 'FLASH_WARM' THEN 10 ELSE 0 END
        + CASE WHEN a.max_hour_vol >= 1000000 THEN 15 WHEN a.max_hour_vol >= 250000 THEN 8 ELSE 0 END
    ) AS flash_score
FROM agg a
LEFT JOIN tokens.erc20 tk
  ON tk.blockchain = 'robinhood' AND tk.contract_address = a.token_address
WHERE a.vol_12h >= 100000
ORDER BY flash_score DESC, hot_hours DESC, vol_12h DESC
LIMIT 25

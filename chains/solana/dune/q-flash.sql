-- Q-FLASH (Solana): Hourly microstructure for sudden launches
-- Uses buy/sell UNION like q-discover (quote tokens beyond SOL/USDC break CASE logic)
-- See core/scoring/FLASH.md

WITH excluded AS (
    SELECT mint FROM (VALUES
        ('So11111111111111111111111111111111111111112'),
        ('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'),
        ('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
    ) AS t(mint)
),
raw AS (
    SELECT block_time, trader_id, amount_usd,
        token_bought_mint_address AS mint, token_bought_symbol AS symbol, 'buy' AS side
    FROM dex_solana.trades
    WHERE block_month >= DATE_TRUNC('month', CURRENT_TIMESTAMP - INTERVAL '2' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '12' HOUR
      AND amount_usd > 0 AND trader_id IS NOT NULL
      AND token_bought_mint_address IS NOT NULL
    UNION ALL
    SELECT block_time, trader_id, amount_usd,
        token_sold_mint_address, token_sold_symbol, 'sell'
    FROM dex_solana.trades
    WHERE block_month >= DATE_TRUNC('month', CURRENT_TIMESTAMP - INTERVAL '2' DAY)
      AND block_time >= CURRENT_TIMESTAMP - INTERVAL '12' HOUR
      AND amount_usd > 0 AND trader_id IS NOT NULL
      AND token_sold_mint_address IS NOT NULL
),
windowed AS (
    SELECT
        mint,
        DATE_TRUNC('hour', block_time) AS hour,
        trader_id AS taker,
        amount_usd,
        side,
        CASE
            WHEN amount_usd < 1000 THEN 'retail'
            WHEN amount_usd < 10000 THEN 'mid'
            ELSE 'whale'
        END AS bucket,
        symbol
    FROM raw
    WHERE mint NOT IN (SELECT mint FROM excluded)
      AND COALESCE(symbol, '') NOT IN ('SOL','WSOL','USDC','USDT','USD1','USDG','JupUSD','WETH','cbBTC','mSOL','JitoSOL','PUMP')
      AND COALESCE(symbol, '') NOT LIKE 'USD%'
),
hourly AS (
    SELECT
        mint,
        MAX(symbol) AS symbol,
        hour,
        SUM(amount_usd) AS vol,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd,
        SUM(CASE WHEN side = 'buy' AND bucket = 'retail' THEN amount_usd ELSE 0 END) AS retail_buy,
        SUM(CASE WHEN side = 'sell' AND bucket = 'whale' THEN amount_usd ELSE 0 END) AS whale_sell,
        COUNT(DISTINCT CASE WHEN side = 'buy' THEN taker END) AS buyers
    FROM windowed
    GROUP BY 1, 3
),
labeled AS (
    SELECT
        h.*,
        h.buy_usd - h.sell_usd AS net,
        h.retail_buy / NULLIF(h.whale_sell, 0) AS absorp,
        CASE
            WHEN (h.buy_usd - h.sell_usd) > 0
             AND COALESCE(h.retail_buy / NULLIF(h.whale_sell, 0), 99) >= 1.5
             AND h.buyers >= 40
             AND h.vol >= 100000
            THEN 'FLASH_HOT'
            WHEN (h.buy_usd - h.sell_usd) > 0
             AND h.buyers >= 25
             AND h.vol >= 50000
            THEN 'FLASH_WARM'
            ELSE 'COLD'
        END AS flash_label
    FROM hourly h
    WHERE h.vol >= 25000
),
agg AS (
    SELECT
        mint,
        MAX(symbol) AS symbol,
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
    a.symbol,
    a.mint,
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
    LEAST(100,
        a.hot_hours * 30
        + a.warm_hours * 10
        + CASE WHEN a.latest_label = 'FLASH_HOT' THEN 25 WHEN a.latest_label = 'FLASH_WARM' THEN 10 ELSE 0 END
        + CASE WHEN a.max_hour_vol >= 2000000 THEN 15 WHEN a.max_hour_vol >= 500000 THEN 8 ELSE 0 END
    ) AS flash_score
FROM agg a
WHERE a.vol_12h >= 250000
  AND a.net_12h > -500000
ORDER BY flash_score DESC, hot_hours DESC, vol_12h DESC
LIMIT 25

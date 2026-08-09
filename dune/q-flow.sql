-- Q-FLOW: Size-bucket flow + repeat buyer quality for top RH chain tokens (last 48h)
-- Focuses on tokens with meaningful 24h volume

WITH excluded AS (
    SELECT contract_address FROM tokens.erc20
    WHERE blockchain = 'robinhood'
      AND symbol IN ('WETH', 'ETH', 'USDG', 'USDC', 'USDT', 'DAI', 'WBTC')
),
top_tokens AS (
    SELECT token_address FROM (
        SELECT
            CASE
                WHEN token_bought_address IS NOT NULL THEN token_bought_address
                ELSE token_sold_address
            END AS token_address,
            SUM(amount_usd) AS vol_24h
        FROM dex.trades
        WHERE blockchain = 'robinhood'
          AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
          AND block_time >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
          AND amount_usd > 0
        GROUP BY 1
        HAVING SUM(amount_usd) >= 100000
        ORDER BY 2 DESC
        LIMIT 15
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
      AND block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND t.block_time >= CURRENT_TIMESTAMP - INTERVAL '2' DAY
      AND t.amount_usd > 0
      AND t.taker IS NOT NULL
      AND (
          t.token_bought_address IN (SELECT token_address FROM top_tokens)
          OR t.token_sold_address IN (SELECT token_address FROM top_tokens)
      )
),
bucketed AS (
    SELECT
        token_address,
        taker,
        side,
        amount_usd,
        CASE
            WHEN amount_usd < 100 THEN 'micro_<100'
            WHEN amount_usd < 1000 THEN 'retail_100-1k'
            WHEN amount_usd < 10000 THEN 'mid_1k-10k'
            ELSE 'whale_10k+'
        END AS size_bucket
    FROM trades
),
bucket_agg AS (
    SELECT
        token_address,
        size_bucket,
        side,
        SUM(amount_usd) AS usd,
        COUNT(*) AS n_trades
    FROM bucketed
    GROUP BY 1, 2, 3
),
trader_stats AS (
    SELECT
        token_address,
        taker,
        COUNT(*) AS n_trades,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd
    FROM bucketed
    GROUP BY 1, 2
),
quality AS (
    SELECT
        token_address,
        COUNT(*) AS unique_traders,
        COUNT_IF(n_trades >= 2) AS repeat_traders,
        100.0 * COUNT_IF(n_trades >= 2) / NULLIF(COUNT(*), 0) AS repeat_buyer_pct,
        COUNT_IF(buy_usd > sell_usd) AS net_buy_wallets,
        100.0 * COUNT_IF(buy_usd > sell_usd) / NULLIF(COUNT(*), 0) AS net_buy_wallet_pct,
        SUM(buy_usd) - SUM(sell_usd) AS net_usd_48h
    FROM trader_stats
    GROUP BY 1
),
meta AS (
    SELECT contract_address, MAX(symbol) AS symbol
    FROM tokens.erc20 WHERE blockchain = 'robinhood'
    GROUP BY 1
)
SELECT
    'bucket' AS section,
    b.token_address,
    m.symbol,
    b.size_bucket AS metric,
    b.side,
    b.usd AS value_usd,
    b.n_trades,
    NULL AS repeat_buyer_pct,
    NULL AS net_buy_wallet_pct,
    NULL AS net_usd_48h
FROM bucket_agg b
LEFT JOIN meta m ON b.token_address = m.contract_address
UNION ALL
SELECT
    'quality' AS section,
    q.token_address,
    m.symbol,
    'summary' AS metric,
    NULL AS side,
    NULL AS value_usd,
    q.unique_traders AS n_trades,
    q.repeat_buyer_pct,
    q.net_buy_wallet_pct,
    q.net_usd_48h
FROM quality q
LEFT JOIN meta m ON q.token_address = m.contract_address
ORDER BY section, token_address, metric, side

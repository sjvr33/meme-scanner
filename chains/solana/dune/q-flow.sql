-- Q-FLOW: Solana size-bucket flow + repeat buyer quality + integrity flags (48h)
WITH excluded AS (
    SELECT mint FROM (VALUES
        ('So11111111111111111111111111111111111111112'),
        ('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'),
        ('Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB')
    ) AS t(mint)
),
top_mints AS (
    SELECT mint FROM (
        SELECT token_bought_mint_address AS mint, SUM(amount_usd) AS vol
        FROM dex_solana.trades
        WHERE block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
          AND block_date >= CURRENT_DATE - INTERVAL '1' DAY AND amount_usd > 0
        GROUP BY 1
        HAVING SUM(amount_usd) >= 250000
        ORDER BY 2 DESC LIMIT 15
    ) t
    WHERE mint NOT IN (SELECT mint FROM excluded)
),
trades AS (
    SELECT t.block_time, t.trader_id, t.amount_usd,
        CASE WHEN t.token_bought_mint_address IN (SELECT mint FROM top_mints) THEN t.token_bought_mint_address ELSE t.token_sold_mint_address END AS mint,
        CASE WHEN t.token_bought_mint_address IN (SELECT mint FROM top_mints) THEN 'buy' ELSE 'sell' END AS side
    FROM dex_solana.trades t
    WHERE t.block_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '30' DAY)
      AND t.block_date >= CURRENT_DATE - INTERVAL '2' DAY
      AND t.amount_usd > 0 AND t.trader_id IS NOT NULL
      AND (t.token_bought_mint_address IN (SELECT mint FROM top_mints) OR t.token_sold_mint_address IN (SELECT mint FROM top_mints))
),
bucketed AS (
    SELECT mint, trader_id, side, amount_usd,
        CASE WHEN amount_usd < 100 THEN 'micro_<100'
             WHEN amount_usd < 1000 THEN 'retail_100-1k'
             WHEN amount_usd < 10000 THEN 'mid_1k-10k'
             ELSE 'whale_10k+' END AS size_bucket
    FROM trades
),
bucket_agg AS (
    SELECT mint, size_bucket, side, SUM(amount_usd) AS usd, COUNT(*) AS n_trades
    FROM bucketed GROUP BY 1, 2, 3
),
trader_stats AS (
    SELECT mint, trader_id, COUNT(*) AS n_trades,
        SUM(CASE WHEN side = 'buy' THEN amount_usd ELSE 0 END) AS buy_usd,
        SUM(CASE WHEN side = 'sell' THEN amount_usd ELSE 0 END) AS sell_usd
    FROM bucketed GROUP BY 1, 2
),
quality AS (
    SELECT mint, COUNT(*) AS unique_traders,
        COUNT_IF(n_trades >= 2) AS repeat_traders,
        100.0 * COUNT_IF(n_trades >= 2) / NULLIF(COUNT(*), 0) AS repeat_buyer_pct,
        COUNT_IF(buy_usd > sell_usd) AS net_buy_wallets,
        100.0 * COUNT_IF(buy_usd > sell_usd) / NULLIF(COUNT(*), 0) AS net_buy_wallet_pct,
        SUM(buy_usd) - SUM(sell_usd) AS net_usd_48h
    FROM trader_stats GROUP BY 1
),
mid_flow AS (
    SELECT mint,
        SUM(CASE WHEN side = 'buy' THEN usd ELSE 0 END) AS mid_buy_usd,
        SUM(CASE WHEN side = 'sell' THEN usd ELSE 0 END) AS mid_sell_usd
    FROM bucket_agg
    WHERE size_bucket = 'mid_1k-10k'
    GROUP BY 1
),
scored AS (
    SELECT
        q.*,
        mf.mid_buy_usd,
        mf.mid_sell_usd,
        100.0 * ABS(COALESCE(mf.mid_buy_usd, 0) - COALESCE(mf.mid_sell_usd, 0))
            / NULLIF(GREATEST(COALESCE(mf.mid_buy_usd, 0), COALESCE(mf.mid_sell_usd, 0)), 0)
            AS mid_imbalance_pct,
        CASE
            WHEN q.repeat_buyer_pct < 2
                 AND (COALESCE(mf.mid_buy_usd, 0) + COALESCE(mf.mid_sell_usd, 0)) >= 1000000
                 AND 100.0 * ABS(COALESCE(mf.mid_buy_usd, 0) - COALESCE(mf.mid_sell_usd, 0))
                     / NULLIF(GREATEST(COALESCE(mf.mid_buy_usd, 0), COALESCE(mf.mid_sell_usd, 0)), 0) < 5
                THEN 'WASH'
            WHEN q.net_buy_wallet_pct >= 95 THEN 'BUNDLE'
            WHEN q.net_buy_wallet_pct >= 90 AND q.repeat_buyer_pct >= 70 THEN 'SUSPECT'
            ELSE 'CLEAN'
        END AS integrity_label
    FROM quality q
    LEFT JOIN mid_flow mf ON q.mint = mf.mint
)
SELECT 'bucket' AS section, b.mint, b.size_bucket AS metric, b.side, b.usd AS value_usd, b.n_trades,
    NULL AS repeat_buyer_pct, NULL AS net_buy_wallet_pct, NULL AS net_usd_48h,
    CAST(NULL AS VARCHAR) AS integrity_label,
    CAST(NULL AS DOUBLE) AS mid_buy_usd,
    CAST(NULL AS DOUBLE) AS mid_sell_usd,
    CAST(NULL AS DOUBLE) AS mid_imbalance_pct
FROM bucket_agg b
UNION ALL
SELECT 'quality', s.mint, 'summary', NULL, NULL, s.unique_traders,
    s.repeat_buyer_pct, s.net_buy_wallet_pct, s.net_usd_48h,
    s.integrity_label, s.mid_buy_usd, s.mid_sell_usd, s.mid_imbalance_pct
FROM scored s
ORDER BY section, mint, metric, side

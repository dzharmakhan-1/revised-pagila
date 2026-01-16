-- =========================================================
-- 06_time_analytics.sql
-- Time-based analytics views (works with surrogate-key model)
-- =========================================================

SET search_path TO analytics, public;

DROP VIEW IF EXISTS analytics.v_revenue_daily;
DROP VIEW IF EXISTS analytics.v_revenue_rolling;

-- ----------------------------
-- Daily Revenue (by date_id)
-- ----------------------------
CREATE VIEW analytics.v_revenue_daily AS
SELECT
    date_id,
    SUM(revenue_amount) AS total_revenue,
    COUNT(*) AS payments_count
FROM analytics.fact_revenue
GROUP BY date_id
ORDER BY date_id;


-- ----------------------------
-- Rolling Revenue Metrics
-- ----------------------------
CREATE VIEW analytics.v_revenue_rolling AS
SELECT
    date_id,
    total_revenue,
    payments_count,

    SUM(total_revenue) OVER (
        ORDER BY date_id
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_7d,

    SUM(total_revenue) OVER (
        ORDER BY date_id
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS revenue_30d
FROM analytics.v_revenue_daily
ORDER BY date_id;

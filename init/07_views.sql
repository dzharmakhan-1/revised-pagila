-- =========================================================
-- 07_views.sql
-- Friendly reporting views (star schema)
-- =========================================================

SET search_path TO analytics, public;

DROP VIEW IF EXISTS analytics.v_revenue_star_daily;
CREATE VIEW analytics.v_revenue_star_daily AS
SELECT
    dd.date_id,
    dd.year,
    dd.quarter,
    dd.month,
    dd.month_name,
    dd.week,
    dc.category_name,
    ds.store_id,
    ds.manager_staff_id,
    ds.city,
    ds.country,
    SUM(fr.revenue_amount) AS revenue
FROM analytics.fact_revenue fr
JOIN analytics.dim_date dd       ON dd.date_id = fr.date_id
JOIN analytics.dim_category dc   ON dc.category_sk = fr.category_sk
JOIN analytics.dim_store ds      ON ds.store_sk = fr.store_sk
GROUP BY
    dd.date_id, dd.year, dd.quarter, dd.month, dd.month_name, dd.week,
    dc.category_name,
    ds.store_id, ds.manager_staff_id, ds.city, ds.country
ORDER BY dd.date_id;

DROP VIEW IF EXISTS analytics.v_revenue_monthly_category;
CREATE VIEW analytics.v_revenue_monthly_category AS
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    dc.category_name,
    SUM(fr.revenue_amount) AS revenue
FROM analytics.fact_revenue fr
JOIN analytics.dim_date dd     ON dd.date_id = fr.date_id
JOIN analytics.dim_category dc ON dc.category_sk = fr.category_sk
GROUP BY dd.year, dd.month, dd.month_name, dc.category_name
ORDER BY dd.year, dd.month, dc.category_name;

DROP VIEW IF EXISTS analytics.v_top_categories_by_city;
CREATE VIEW analytics.v_top_categories_by_city AS
SELECT
    ds.country,
    ds.city,
    dc.category_name,
    SUM(fr.revenue_amount) AS revenue,
    DENSE_RANK() OVER (
        PARTITION BY ds.country, ds.city
        ORDER BY SUM(fr.revenue_amount) DESC
    ) AS rnk
FROM analytics.fact_revenue fr
JOIN analytics.dim_category dc ON dc.category_sk = fr.category_sk
JOIN analytics.dim_store ds    ON ds.store_sk = fr.store_sk
GROUP BY ds.country, ds.city, dc.category_name;

-- optional: filter top 3 with:
-- SELECT * FROM analytics.v_top_categories_by_city WHERE rnk <= 3;

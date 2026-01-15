-- =========================================================
-- 09_analytics_views.sql
-- User-friendly analytics views (star schema)
-- =========================================================

SET search_path TO analytics, public;

-- -----------------------------
-- Revenue by day
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_daily AS
SELECT
  f.date_id,
  d.year,
  d.quarter,
  d.month,
  d.month_name,
  d.week,
  d.day_name,
  SUM(f.revenue_amount) AS total_revenue,
  COUNT(*)              AS fact_rows
FROM analytics.fact_revenue f
JOIN analytics.dim_date d
  ON d.date_id = f.date_id
GROUP BY
  f.date_id, d.year, d.quarter, d.month, d.month_name, d.week, d.day_name
ORDER BY
  f.date_id;


-- -----------------------------
-- Revenue by month
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_monthly AS
SELECT
  d.year,
  d.month,
  d.month_name,
  SUM(f.revenue_amount) AS total_revenue
FROM analytics.fact_revenue f
JOIN analytics.dim_date d
  ON d.date_id = f.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;


-- -----------------------------
-- Revenue by category (overall)
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_by_category AS
SELECT
  c.category_id,
  c.category_name,
  SUM(f.revenue_amount) AS total_revenue,
  COUNT(*)              AS fact_rows
FROM analytics.fact_revenue f
JOIN analytics.dim_category c
  ON c.category_sk = f.category_sk
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;


-- -----------------------------
-- Revenue by store (overall)
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_by_store AS
SELECT
  s.store_id,
  SUM(f.revenue_amount) AS total_revenue,
  COUNT(*)              AS fact_rows
FROM analytics.fact_revenue f
JOIN analytics.dim_store s
  ON s.store_sk = f.store_sk
GROUP BY s.store_id
ORDER BY s.store_id;


-- -----------------------------
-- Revenue by store + category
-- (common BI matrix)
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_store_category AS
SELECT
  s.store_id,
  c.category_name,
  SUM(f.revenue_amount) AS total_revenue
FROM analytics.fact_revenue f
JOIN analytics.dim_store s
  ON s.store_sk = f.store_sk
JOIN analytics.dim_category c
  ON c.category_sk = f.category_sk
GROUP BY s.store_id, c.category_name
ORDER BY s.store_id, total_revenue DESC;


-- -----------------------------
-- Revenue by city/country (overall)
-- (works even if you removed snowflake constraints)
-- we derive geography via store -> address -> city -> country
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_by_geography AS
SELECT
  co.country,
  ci.city,
  SUM(f.revenue_amount) AS total_revenue
FROM analytics.fact_revenue f
JOIN analytics.dim_store ds
  ON ds.store_sk = f.store_sk
JOIN public.store s
  ON s.store_id = ds.store_id
JOIN public.address a
  ON a.address_id = s.address_id
JOIN public.city ci
  ON ci.city_id = a.city_id
JOIN public.country co
  ON co.country_id = ci.country_id
GROUP BY co.country, ci.city
ORDER BY total_revenue DESC;


-- -----------------------------
-- Category trend by month
-- (nice for line charts)
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_category_monthly AS
SELECT
  d.year,
  d.month,
  d.month_name,
  c.category_name,
  SUM(f.revenue_amount) AS total_revenue
FROM analytics.fact_revenue f
JOIN analytics.dim_date d
  ON d.date_id = f.date_id
JOIN analytics.dim_category c
  ON c.category_sk = f.category_sk
GROUP BY d.year, d.month, d.month_name, c.category_name
ORDER BY d.year, d.month, c.category_name;


-- -----------------------------
-- Rolling 7-day revenue (time analytics)
-- -----------------------------
CREATE OR REPLACE VIEW analytics.v_revenue_rolling_7d AS
SELECT
  date_id,
  total_revenue,
  SUM(total_revenue) OVER (
    ORDER BY date_id
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS rolling_7d_revenue
FROM analytics.v_revenue_daily
ORDER BY date_id;

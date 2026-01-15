-- =========================================================
-- 08_quality_checks.sql
-- Sanity checks for the star schema
-- (will error if something is seriously wrong)
-- =========================================================

SET search_path TO analytics, public;

-- 1) Fact should not be empty
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM analytics.fact_revenue) = 0 THEN
    RAISE EXCEPTION 'fact_revenue is empty';
  END IF;
END $$;

-- 2) FK integrity checks (should all be 0)
DO $$
DECLARE
  bad_cnt bigint;
BEGIN
  SELECT COUNT(*) INTO bad_cnt
  FROM analytics.fact_revenue f
  LEFT JOIN analytics.dim_date d ON d.date_id = f.date_id
  WHERE d.date_id IS NULL;
  IF bad_cnt > 0 THEN
    RAISE EXCEPTION 'FK fail: % rows in fact_revenue missing dim_date', bad_cnt;
  END IF;

  SELECT COUNT(*) INTO bad_cnt
  FROM analytics.fact_revenue f
  LEFT JOIN analytics.dim_category c ON c.category_sk = f.category_sk
  WHERE c.category_sk IS NULL;
  IF bad_cnt > 0 THEN
    RAISE EXCEPTION 'FK fail: % rows in fact_revenue missing dim_category', bad_cnt;
  END IF;

  SELECT COUNT(*) INTO bad_cnt
  FROM analytics.fact_revenue f
  LEFT JOIN analytics.dim_store s ON s.store_sk = f.store_sk
  WHERE s.store_sk IS NULL;
  IF bad_cnt > 0 THEN
    RAISE EXCEPTION 'FK fail: % rows in fact_revenue missing dim_store', bad_cnt;
  END IF;
END $$;

-- 3) Reconciliation check:
-- Total revenue in fact should match total revenue in public.payment
DO $$
DECLARE
  pay_total numeric(18,2);
  fact_total numeric(18,2);
BEGIN
  SELECT COALESCE(SUM(amount),0)::numeric(18,2) INTO pay_total FROM public.payment;
  SELECT COALESCE(SUM(revenue_amount),0)::numeric(18,2) INTO fact_total FROM analytics.fact_revenue;

  -- allow tiny rounding drift
  IF abs(pay_total - fact_total) > 0.01 THEN
    RAISE EXCEPTION 'Revenue mismatch: payment_total=%, fact_total=%', pay_total, fact_total;
  END IF;
END $$;

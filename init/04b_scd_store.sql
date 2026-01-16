WITH src AS (
  SELECT
    s.store_id,
    s.manager_staff_id,
    s.address_id,
    c.city_id,
    c.city,
    co.country_id,
    co.country,
    md5(concat_ws('|', s.manager_staff_id, s.address_id, c.city, co.country)) AS record_hash
  FROM public.store s
  JOIN public.address a ON s.address_id = a.address_id
  JOIN public.city c ON a.city_id = c.city_id
  JOIN public.country co ON c.country_id = co.country_id
)
UPDATE analytics.dim_store d
SET effective_to = CURRENT_DATE - 1,
    is_current = FALSE
FROM src
WHERE d.store_id = src.store_id
  AND d.is_current = TRUE
  AND d.record_hash <> src.record_hash;

INSERT INTO analytics.dim_store (
  store_id, manager_staff_id, address_id,
  city_id, city, country_id, country,
  effective_from, effective_to, is_current, record_hash
)
SELECT
  src.store_id, src.manager_staff_id, src.address_id,
  src.city_id, src.city, src.country_id, src.country,
  CURRENT_DATE, DATE '9999-12-31', TRUE, src.record_hash
FROM src
LEFT JOIN analytics.dim_store d
  ON d.store_id = src.store_id AND d.is_current = TRUE
WHERE d.store_id IS NULL OR d.record_hash <> src.record_hash;

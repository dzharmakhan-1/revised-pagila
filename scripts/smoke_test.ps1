# scripts/smoke_test.ps1
$container = "pagila_postgres"

Write-Host "Waiting for Postgres..." -ForegroundColor Cyan
for ($i=0; $i -lt 30; $i++) {
  $ok = docker exec $container pg_isready -U postgres -d pagila 2>$null
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep -Seconds 1
}
if ($LASTEXITCODE -ne 0) { throw "Postgres is not ready" }

Write-Host "Checking tables..." -ForegroundColor Cyan
docker exec -it $container psql -U postgres -d pagila -c "SELECT COUNT(*) AS fact_cnt FROM analytics.fact_revenue;"
docker exec -it $container psql -U postgres -d pagila -c "SELECT COUNT(*) AS dim_date_cnt FROM analytics.dim_date;"
docker exec -it $container psql -U postgres -d pagila -c "SELECT COUNT(*) AS dim_category_cnt FROM analytics.dim_category;"
docker exec -it $container psql -U postgres -d pagila -c "SELECT COUNT(*) AS dim_store_cnt FROM analytics.dim_store;"

Write-Host "Checking views..." -ForegroundColor Cyan
docker exec -it $container psql -U postgres -d pagila -c "\dv analytics.*"

Write-Host "Sample queries..." -ForegroundColor Cyan
docker exec -it $container psql -U postgres -d pagila -c "SELECT * FROM analytics.v_revenue_star_daily ORDER BY date_id LIMIT 5;"
docker exec -it $container psql -U postgres -d pagila -c "SELECT category_name, SUM(revenue) AS revenue FROM analytics.v_revenue_star_daily GROUP BY 1 ORDER BY revenue DESC LIMIT 5;"
docker exec -it $container psql -U postgres -d pagila -c "SELECT country, SUM(revenue) AS revenue FROM analytics.v_revenue_star_daily GROUP BY 1 ORDER BY revenue DESC LIMIT 5;"

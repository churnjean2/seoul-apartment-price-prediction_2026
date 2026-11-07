-- Purpose : Rows, typical price and missing-value rates per contract year,
--           before choosing the time split and the feature list.
-- Result: Trades per contract year: 665 (2023), 45,311 (2024),
--         63,907 (2025), 44,001 (2026, partial year).
--         Median price per m2 (10k KRW): 1,267 / 1,389 / 1,472 / 1,362.
--         Households are null for under 1% of rows. Energy and green
--         grades are null for 85-90% of rows (no certification).
-- Decision: Encode missing energy/green grades as 'none' instead of
--           imputing, because an uncertified building is a real category.
--           Use a time-based split (train up to 2025, test on 2026)
--           since prices shift from year to year.
-- SQL     : AVG(CASE WHEN col IS NULL ...) gives a null rate per group.

select
    year(contract_date)                                                    as contract_year,
    count(*)                                                               as n,
    round(median(price_per_m2_10k), 0)                                     as median_price_per_m2,
    round(100.0 * avg(case when households is null then 1 else 0 end), 1)  as households_null_pct,
    round(100.0 * avg(case when energy_grade is null then 1 else 0 end), 1) as energy_null_pct,
    round(100.0 * avg(case when green_building_grade is null then 1 else 0 end), 1) as green_null_pct,
    min(building_age)                                                      as min_age
from {{ ref('mart_training_trades') }}
group by all
order by all
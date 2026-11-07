-- Purpose : Rows, typical price and missing-value rates per contract year,
--           before choosing the time split and the feature list.
-- Result  :
-- Decision:
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
-- One row per apartment trade usable for modelling.
-- Scope: trades matched to exactly one multi-building complex, excluding
-- cancelled trades, presale rights and direct (non-broker) deals.
-- Only deterministic features are built here. Anything fitted on data
-- (imputation, scaling, outlier thresholds) happens after the train/test split.

with trades as (
    select * from {{ ref('int_apartment_trades_matched') }}
    where match_status = 'matched'
      and is_cancelled     is not true
      and is_presale_right is not true
      and is_direct_deal   is not true   -- direct deals often include below-market family transfers
),

buildings as (
    select * from {{ ref('int_building_register_coded') }}
)

select
    -- identifiers and split key (not model features)
    t.trade_id,
    t.register_id,
    t.contract_date,
    strftime(t.contract_date, '%Y-%m')                     as contract_month,

    -- target
    t.price_10k_krw,
    round(t.price_10k_krw / t.floor_area_m2, 2)            as price_per_m2_10k,

    -- trade-level features
    t.district_name,
    t.bjd_code,
    t.floor_area_m2,
    t.floor,
    t.built_year,
    year(t.contract_date) - t.built_year                   as building_age,

    -- building-level features
    b.households,
    b.parking_spaces,
    round(b.parking_spaces / nullif(b.households, 0), 2)   as parking_per_household,
    b.passenger_elevators,
    b.floor_area_ratio,
    b.building_coverage_ratio,
    b.energy_grade,
    b.green_building_grade,
    b.green_building_score,
    b.x_coord,
    b.y_coord
from trades as t
join buildings as b using (register_id)
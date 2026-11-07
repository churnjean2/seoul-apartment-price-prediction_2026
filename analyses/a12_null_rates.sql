-- Purpose: How often are building features missing in the training mart?
--          Found while testing the API: a real trade had null coordinates.
-- Result: Missing rates in the training mart: coordinates 8.3%,
--         parking 11.9%, floor area ratio 10.9%, elevators 96.4%,
--         households 0.6%.
-- Decision: Make coordinates optional in the API. Follow-ups after
--           deployment: let XGBoost handle missing numerics natively
--           instead of median imputation, drop the elevator feature,
--           and consider geocoding the missing coordinates.
select
    count(*) as n,
    round(100.0 * avg(case when x_coord is null then 1 else 0 end), 1)               as coord_null_pct,
    round(100.0 * avg(case when parking_per_household is null then 1 else 0 end), 1) as parking_null_pct,
    round(100.0 * avg(case when passenger_elevators is null then 1 else 0 end), 1)   as elevator_null_pct,
    round(100.0 * avg(case when floor_area_ratio is null then 1 else 0 end), 1)      as far_null_pct,
    round(100.0 * avg(case when households is null then 1 else 0 end), 1)            as households_null_pct
from {{ ref('mart_training_trades') }}
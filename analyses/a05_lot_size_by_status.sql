-- Purpose : Are unmatched parcels a different kind of building?
-- Result  : 2026-11-06 22:07 — 6.4 trades per parcel (unmatched) vs 61.7 (matched).
-- Decision: Unmatched are mostly single-building apartments; exclude and state the scope.
-- SQL     : COUNT(DISTINCT ...); MEDIAN().

select
    match_status,
    count(distinct bjd_code || main_lot_no || sub_lot_no) as lots,
    round(count(*) / count(distinct bjd_code || main_lot_no || sub_lot_no), 1) as trades_per_lot,
    median(built_year) as median_built_year
from {{ ref('int_apartment_trades_matched') }}
group by all
order by lots desc
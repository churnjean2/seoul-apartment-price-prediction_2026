-- Purpose : Does the name -> code lookup find the right code where the true code is known?
-- Result  : 2026-11-06 21:28 — 11,892 of 11,911 agree (99.8%).
-- Decision: Trust the lookup for missing codes; document the 0.2% as a limitation.
-- SQL     : JOIN ... USING (...); COUNT(*) FILTER (WHERE ...).

select
    count(*)                                         as n,
    count(*) filter (where b.bjd_code = l.bjd_code)  as agree
from {{ ref('stg_building_register') }} as b
join {{ ref('int_dong_code_lookup') }} as l using (district_name, dong_name)
where b.bjd_code is not null
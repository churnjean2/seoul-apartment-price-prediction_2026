-- Purpose : Which building register records are missing their dong code?
-- Result  : 2026-11-06 21:24 — 7,234 of 19,196 (38%) missing; names present on almost all.
-- Decision: Rebuild codes from district + dong names (int_dong_code_lookup).
-- SQL     : GROUP BY ALL; a condition used as a column (x IS NULL AS missing_code).

select
    main_use,
    bjd_code is null       as missing_code,
    district_name is null  as missing_name,
    count(*)               as n
from {{ ref('stg_building_register') }}
group by all
order by n desc
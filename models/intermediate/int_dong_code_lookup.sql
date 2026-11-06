-- District + dong name -> 10-digit legal dong code, derived from transactions.
-- Used to fill building register rows whose dong code is missing.

select distinct
    district_name || ' ' || dong_name  as name_key,
    district_name,
    dong_name,
    bjd_code
from {{ ref('stg_transactions') }}
where district_name is not null
  and dong_name is not null